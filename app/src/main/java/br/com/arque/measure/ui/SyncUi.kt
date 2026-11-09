package br.com.arque.measure.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.i18n.tr
import br.com.arque.measure.sync.SyncCore
import br.com.arque.measure.sync.SyncNet
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * Ajustes › Sincronizar com outro aparelho (Wi-Fi): um aparelho "Recebe" (mostra o código) e o outro "Conecta"
 * (digita o código, vê o que já tem nos dois, o que falta e o que mudou, e escolhe o que passa).
 */
@Composable
fun SyncDialog(vm: AppViewModel, deviceName: String, onDismiss: () -> Unit) {
    var mode by remember { mutableStateOf("") }
    when (mode) {
        "host" -> SyncHost(vm, deviceName) { mode = ""; onDismiss() }
        "client" -> SyncClient(vm) { mode = ""; onDismiss() }
        else -> AlertDialog(
            onDismissRequest = onDismiss,
            title = { Text(tr("Sincronizar com outro aparelho")) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Text(tr("Passa notas, medidas, projetos de móveis, orçamentos e agenda entre este aparelho e outro (iPhone, Android ou Windows) pelo mesmo Wi-Fi ou pelo roteador do celular. Não precisa de internet."), fontSize = 14.sp)
                    Text(tr("Antes de mostrar a lista ele compara os dois: o que já tem igual não passa de novo (nada fica duplicado)."), fontSize = 13.sp, color = Color(0xFF555555))
                    Button(onClick = { mode = "host" }, modifier = Modifier.fillMaxWidth()) { Text(tr("📥 Receber neste aparelho (mostra o código)")) }
                    OutlinedButton(onClick = { mode = "client" }, modifier = Modifier.fillMaxWidth()) { Text(tr("📤 Conectar no outro (digitar o código)")) }
                    Text(tr("Antes de gravar qualquer coisa, os dois aparelhos fazem uma cópia de segurança automática."), fontSize = 12.sp, color = Color(0xFF666666))
                }
            },
            confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Fechar")) } },
        )
    }
}

@Composable
private fun SyncHost(vm: AppViewModel, deviceName: String, onDismiss: () -> Unit) {
    var host by remember { mutableStateOf<SyncNet.Host?>(null) }
    var err by remember { mutableStateOf("") }
    var status by remember { mutableStateOf(tr("Esperando o outro aparelho…")) }
    var received by remember { mutableIntStateOf(0) }
    var sent by remember { mutableIntStateOf(0) }
    var finished by remember { mutableIntStateOf(0) }
    val ips = remember { SyncNet.localIps() }
    LaunchedEffect(Unit) {
        vm.syncPrepare()
        val h = SyncNet.Host(vm.syncFiles(), deviceName, { vm.syncBackup() }) { ev ->
            when (ev) {
                "conectou" -> status = tr("Conectado: o outro aparelho está comparando…")
                "recebeu" -> { received++; status = tr("Recebendo…") }
                "enviou" -> { sent++; status = tr("Enviando…") }
                "fim" -> finished++
            }
        }
        if (withContext(Dispatchers.IO) { h.start() }) host = h else err = tr("Não consegui abrir a conexão neste aparelho.")
    }
    LaunchedEffect(finished) {
        if (finished > 0) { if (received > 0) vm.syncReload(); status = tr("Pronto: recebeu {0}, enviou {1}.", received, sent) }
    }
    DisposableEffect(Unit) { onDispose { host?.stop(); if (received > 0 && finished == 0) vm.syncReload() } }
    AlertDialog(
        onDismissRequest = {},
        title = { Text(tr("Receber neste aparelho")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (err.isNotEmpty()) Text(err, color = Color(0xFFE5484D))
                else if (ips.isEmpty()) Text(tr("Este aparelho não está em nenhum Wi-Fi. Ligue o Wi-Fi (ou o roteador do celular) nos dois aparelhos."), color = Color(0xFFE5484D))
                else host?.let { h ->
                    Text(tr("No outro aparelho: Ajustes › Sincronizar com outro aparelho › Conectar, e digite:"), fontSize = 14.sp)
                    Text(
                        SyncNet.code(ips.first(), h.pin, h.port), fontSize = 40.sp, fontWeight = FontWeight.Bold, color = Color(0xFF1F3A63),
                        modifier = Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color(0xFFEFF4FB)).padding(12.dp),
                    )
                    if (ips.size > 1) Text(tr("Se não achar, tente: {0}", ips.drop(1).joinToString(" · ") { SyncNet.code(it, h.pin, h.port) }), fontSize = 12.sp)
                    Text(tr("Endereço: {0}", ips.first() + ":" + h.port), fontSize = 12.sp, color = Color(0xFF666666))
                    Text(status, fontWeight = FontWeight.SemiBold)
                    if (received + sent > 0) Text(tr("Recebidos: {0} · Enviados: {1}", received, sent), fontSize = 13.sp)
                    Text(tr("Deixe esta tela aberta até o outro aparelho terminar. Os dois precisam estar no mesmo Wi-Fi."), fontSize = 12.sp, color = Color(0xFF666666))
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(if (finished > 0) tr("Fechar") else tr("Parar")) } },
    )
}

@Composable
private fun SyncClient(vm: AppViewModel, onDismiss: () -> Unit) {
    val scope = rememberCoroutineScope()
    var code by remember { mutableStateOf("") }
    var err by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var client by remember { mutableStateOf<SyncNet.Client?>(null) }
    var other by remember { mutableStateOf("") }
    var rows by remember { mutableStateOf<List<SyncCore.Row>>(emptyList()) }
    // escolha por item: "send" (vai daqui pro outro), "pull" (vem de lá pra cá) ou "" (não mexe)
    val choice = remember { mutableStateMapOf<String, String>() }
    var progress by remember { mutableStateOf(0f) }
    var result by remember { mutableStateOf("") }

    fun key(r: SyncCore.Row) = r.k + "|" + r.id
    fun connect() {
        val t = SyncNet.parse(code) ?: run { err = tr("Código inválido. Ex.: 10-4821 (o que aparece no outro aparelho)."); return }
        busy = true; err = ""
        scope.launch {
            val r = withContext(Dispatchers.IO) {
                runCatching {
                    val (c, name) = SyncNet.Client.find(t) ?: error(tr("Não achei o outro aparelho. Confira se os dois estão no mesmo Wi-Fi e se a tela “Receber” está aberta."))
                    vm.syncPrepare()
                    Triple(c, name, SyncCore.compare(SyncCore.manifest(vm.syncFiles()), c.manifest()))
                }
            }
            busy = false
            r.onSuccess { (c, name, rs) ->
                client = c; other = name; rows = rs
                choice.clear()
                rs.forEach { when (it.state) { SyncCore.State.ONLY_HERE -> choice[key(it)] = "send"; SyncCore.State.ONLY_THERE -> choice[key(it)] = "pull"; else -> {} } }
            }.onFailure { err = it.message ?: tr("Não consegui conectar.") }
        }
    }
    fun go() {
        val c = client ?: return
        val send = rows.filter { choice[key(it)] == "send" }
        val pull = rows.filter { choice[key(it)] == "pull" }
        if (send.isEmpty() && pull.isEmpty()) { err = tr("Marque pelo menos um item."); return }
        busy = true; err = ""
        scope.launch {
            val (ok, fail) = withContext(Dispatchers.IO) {
                SyncNet.transfer(vm.syncFiles(), c, send, pull, { vm.syncBackup() }) { n, tot -> progress = n.toFloat() / tot }
            }
            if (pull.isNotEmpty()) vm.syncReload()
            busy = false
            result = if (fail == 0) tr("Pronto: {0} item(ns) passado(s). Enviados {1}, recebidos {2}.", ok, send.size, pull.size)
            else tr("Passou {0}, falhou {1}. Confira o Wi-Fi e tente de novo (o que já passou não duplica).", ok, fail)
        }
    }

    AlertDialog(
        onDismissRequest = { if (!busy) onDismiss() },
        title = { Text(if (client == null) tr("Conectar no outro aparelho") else tr("Com {0}", other)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (err.isNotEmpty()) Text(err, color = Color(0xFFE5484D), fontSize = 13.sp)
                if (client == null) {
                    Text(tr("Digite o código que aparece no outro aparelho (em Receber):"), fontSize = 14.sp)
                    Text(code.ifEmpty { "–" }, fontSize = 30.sp, fontWeight = FontWeight.Bold)
                    AppNumPad(code, { t ->
                        code = when {
                            t.isEmpty() -> ""
                            t.length < code.length -> code.dropLast(1)
                            else -> (code + t.last().takeIf { it.isDigit() || it == '-' || it == '.' }.let { it?.toString() ?: "" }).take(24)
                        }
                        err = ""
                    }, allowOps = false, dash = true)
                    if (busy) LinearProgressIndicator(modifier = Modifier.fillMaxWidth())
                } else if (result.isNotEmpty()) {
                    Text(result, fontWeight = FontWeight.SemiBold)
                } else {
                    val same = rows.count { it.state == SyncCore.State.SAME }
                    Text(tr("✅ Iguais nos dois: {0} (não passa nada)", same), fontSize = 13.sp, color = Color(0xFF1F7A3D))
                    if (busy) LinearProgressIndicator(progress = { progress }, modifier = Modifier.fillMaxWidth())
                    LazyColumn(Modifier.heightIn(max = 380.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        for ((st, head) in listOf(
                            SyncCore.State.ONLY_HERE to tr("➕ Só neste aparelho (vai pro outro)"),
                            SyncCore.State.ONLY_THERE to tr("⬅️ Só no outro (vem pra cá)"),
                            SyncCore.State.DIFF to tr("🔄 Nos dois, mas diferente (escolha qual fica)"),
                        )) {
                            val list = rows.filter { it.state == st }
                            if (list.isEmpty()) continue
                            item(key = "h$st") { Text(head, fontWeight = FontWeight.Bold, fontSize = 14.sp, modifier = Modifier.padding(top = 8.dp)) }
                            items(list, key = { key(it) }) { r -> SyncRow(r, choice[key(r)] ?: "") { choice[key(r)] = it } }
                        }
                    }
                }
            }
        },
        confirmButton = {
            when {
                client == null -> Button(onClick = { connect() }, enabled = !busy && code.length >= 6) { Text(tr("Conectar")) }
                result.isNotEmpty() -> Button(onClick = onDismiss) { Text(tr("Fechar")) }
                else -> Button(onClick = { go() }, enabled = !busy) { Text(tr("Passar ({0})", choice.values.count { it.isNotEmpty() })) }
            }
        },
        dismissButton = { if (!busy && result.isEmpty()) TextButton(onClick = onDismiss) { Text(tr("Cancelar")) } },
    )
}

@Composable
private fun SyncRow(r: SyncCore.Row, ch: String, onCh: (String) -> Unit) {
    val it0 = r.here ?: r.there!!
    val df = java.text.SimpleDateFormat("dd/MM HH:mm", java.util.Locale.ROOT)
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(Color(0xFFF6F7F9)).padding(horizontal = 8.dp, vertical = 4.dp)) {
        if (r.state == SyncCore.State.DIFF) {
            Text(tr(SyncCore.kindLabel(r.k)) + " · " + it0.title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
            val newer = if ((r.here?.mod ?: 0) >= (r.there?.mod ?: 0)) tr("a daqui é a mais nova") else tr("a de lá é a mais nova")
            Text(tr("Aqui: {0} · Lá: {1} · {2}", df.format(java.util.Date(r.here?.mod ?: 0)), df.format(java.util.Date(r.there?.mod ?: 0)), newer), fontSize = 11.sp, color = Color(0xFF666666))
            Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                for ((v, l) in listOf("" to tr("Não mexer"), "send" to tr("Mandar a daqui"), "pull" to tr("Trazer a de lá"))) {
                    val sel = ch == v
                    Text(l, fontSize = 12.sp, color = if (sel) Color.White else Color(0xFF1F3A63),
                        modifier = Modifier.clip(RoundedCornerShape(8.dp)).background(if (sel) Color(0xFF2F6BE0) else Color(0xFFE3EAF5)).clickable { onCh(v) }.padding(horizontal = 8.dp, vertical = 6.dp))
                }
            }
        } else {
            val want = if (r.state == SyncCore.State.ONLY_HERE) "send" else "pull"
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth().clickable { onCh(if (ch == want) "" else want) }) {
                Checkbox(checked = ch == want, onCheckedChange = { onCh(if (it) want else "") })
                Column {
                    Text(tr(SyncCore.kindLabel(r.k)) + " · " + it0.title, fontSize = 14.sp)
                    if (it0.sub.isNotBlank()) Text(it0.sub, fontSize = 11.sp, color = Color(0xFF666666))
                }
            }
        }
    }
}
