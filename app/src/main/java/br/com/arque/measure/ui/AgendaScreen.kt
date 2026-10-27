@file:OptIn(androidx.compose.material3.ExperimentalMaterial3Api::class, androidx.compose.foundation.layout.ExperimentalLayoutApi::class)

package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronLeft
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.agenda.AgendaReminders
import br.com.arque.measure.model.Appointment
import br.com.arque.measure.model.ApptKind
import br.com.arque.measure.model.REMIND_OPTIONS
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

private val ptBR get() = br.com.arque.measure.i18n.I18n.locale
private val fmtDay get() = br.com.arque.measure.i18n.I18n.dayFormat()
private val fmtHour get() = br.com.arque.measure.i18n.I18n.hourFormat()
private val fmtDate get() = br.com.arque.measure.i18n.I18n.dateFormat()
private val fmtMonth get() = br.com.arque.measure.i18n.I18n.monthFormat()

private fun dayStart(ms: Long): Long = Calendar.getInstance().apply {
    timeInMillis = ms; set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
}.timeInMillis

private fun whenLabel(startMs: Long, now: Long = System.currentTimeMillis()): String {
    val d = (dayStart(startMs) - dayStart(now)) / 86_400_000L
    return when {
        d == 0L -> tr("Hoje")
        d == 1L -> tr("Amanhã")
        d == -1L -> tr("Ontem")
        else -> fmtDay.format(Date(startMs)).replaceFirstChar { it.uppercase() }
    }
}

/** Agenda do app: entregas, visitas, medições e instalações, com aviso (notificação) e vínculo ao cliente. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AgendaScreen(vm: AppViewModel) {
    val ctx = LocalContext.current
    var editing by remember { mutableStateOf<Appointment?>(null) }
    var isNew by remember { mutableStateOf(false) }
    var monthMs by remember { mutableStateOf(dayStart(System.currentTimeMillis())) }
    var selDay by remember { mutableStateOf<Long?>(null) }
    var mode by remember { mutableIntStateOf(0) } // 0 próximos, 1 passados/concluídos
    var exactOk by remember { mutableStateOf(AgendaReminders.canExact(ctx)) }
    BackHandler { if (editing != null) editing = null else vm.screen = Screen.Library }

    val notifPerm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { }
    LaunchedEffect(Unit) {
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) notifPerm.launch(Manifest.permission.POST_NOTIFICATIONS)
        exactOk = AgendaReminders.canExact(ctx)
    }
    LaunchedEffect(vm.agendaOpenId) {
        val id = vm.agendaOpenId ?: return@LaunchedEffect
        vm.appointments.firstOrNull { it.id == id }?.let { isNew = false; editing = it }
        vm.agendaOpenId = null
    }

    val now = System.currentTimeMillis()
    val all = vm.appointments
    val shown = when {
        selDay != null -> all.filter { dayStart(it.startMs) == selDay }
        mode == 0 -> all.filter { !it.done && it.startMs >= dayStart(now) }
        else -> all.filter { it.done || it.startMs < dayStart(now) }.sortedByDescending { it.startMs }
    }

    Box(Modifier.fillMaxSize().background(Ui.bg).statusBarsPadding().navigationBarsPadding()) {
        Column(Modifier.fillMaxSize()) {
            Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                IconButton(onClick = { vm.screen = Screen.Library }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, tr("Voltar"), tint = Ui.text) }
                Text(tr("Agenda"), color = Ui.text, fontSize = 20.sp, modifier = Modifier.weight(1f))
                Button(onClick = {
                    val base = selDay?.let { it + 9 * 3600_000L } ?: (now + 3600_000L)
                    isNew = true; editing = Appointment(startMs = base)
                }) { Text(tr("+ Novo")) }
            }
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                if (!exactOk) {
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color(0xFF3A2E12)).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(tr("Pra o aviso tocar na hora certa, libere “Alarmes e lembretes”."), color = Color(0xFFF5D68A), fontSize = 13.sp, modifier = Modifier.weight(1f))
                        TextButton(onClick = {
                            if (Build.VERSION.SDK_INT >= 31) runCatching {
                                ctx.startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:${ctx.packageName}")))
                            }
                        }) { Text(tr("Liberar")) }
                    }
                }
                MonthGrid(monthMs, all, selDay, { monthMs = it }) { d -> selDay = if (selDay == d) null else d }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    FilterChip(selected = selDay == null && mode == 0, onClick = { selDay = null; mode = 0 }, label = { Text(tr("Próximos")) })
                    FilterChip(selected = selDay == null && mode == 1, onClick = { selDay = null; mode = 1 }, label = { Text(tr("Concluídos / passados")) })
                    if (selDay != null) FilterChip(selected = true, onClick = { selDay = null }, label = { Text(fmtDate.format(Date(selDay!!)) + "  ✕") })
                }
                if (selDay != null) {
                    DayHours(vm, selDay!!, shown, onNew = { ms -> isNew = true; editing = Appointment(startMs = ms) }, onEdit = { isNew = false; editing = it })
                } else if (shown.isEmpty()) {
                    Text(
                        if (selDay != null) tr("Nada marcado nesse dia.") else if (mode == 0) tr("Nenhum compromisso por vir. Toque em “+ Novo” pra marcar uma entrega ou visita.") else tr("Nada por aqui ainda."),
                        color = Ui.dim, fontSize = 14.sp, modifier = Modifier.padding(vertical = 12.dp),
                    )
                }
                var lastDay = -1L
                if (selDay == null) shown.forEach { a ->
                    val ds = dayStart(a.startMs)
                    if (ds != lastDay) {
                        lastDay = ds
                        Text(whenLabel(a.startMs, now), color = Ui.dim, fontSize = 13.sp, fontWeight = FontWeight.Bold, modifier = Modifier.padding(top = 6.dp))
                    }
                    ApptCard(vm, a, onEdit = { isNew = false; editing = a })
                }
                Spacer(Modifier.height(24.dp))
            }
        }
    }
    editing?.let { cur ->
        ApptEditor(vm, cur, isNew, onClose = { editing = null })
    }
}

/** Dia em horas: 06h às 22h (ou mais, se houver compromisso fora disso). Toque numa hora livre pra marcar. */
@Composable
private fun DayHours(vm: AppViewModel, day: Long, list: List<Appointment>, onNew: (Long) -> Unit, onEdit: (Appointment) -> Unit) {
    val hourOf = { a: Appointment -> Calendar.getInstance().apply { timeInMillis = a.startMs }.get(Calendar.HOUR_OF_DAY) }
    val first = minOf(6, list.minOfOrNull(hourOf) ?: 6)
    val last = maxOf(22, list.maxOfOrNull(hourOf) ?: 22)
    val nowCal = Calendar.getInstance()
    val isToday = dayStart(nowCal.timeInMillis) == day
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        for (h in first..last) {
            val inHour = list.filter { hourOf(it) == h }.sortedBy { it.startMs }
            val current = isToday && nowCal.get(Calendar.HOUR_OF_DAY) == h
            Row(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp))
                    .background(if (current) Color(0x223B82F6) else Color(0x0FFFFFFF))
                    .clickable { onNew(day + h * 3600_000L) }
                    .padding(horizontal = 8.dp, vertical = 6.dp),
                verticalAlignment = Alignment.Top,
            ) {
                Text("%02d:00".format(h), color = if (current) Color(0xFF7FB2FF) else Ui.dim, fontSize = 13.sp, fontWeight = FontWeight.Bold, modifier = Modifier.width(52.dp).padding(top = 2.dp))
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    if (inHour.isEmpty()) Text(tr("livre · toque pra marcar"), color = Color(0x55FFFFFF), fontSize = 12.sp, modifier = Modifier.padding(top = 2.dp))
                    inHour.forEach { a -> ApptCard(vm, a, onEdit = { onEdit(a) }) }
                }
            }
        }
    }
}

@Composable
private fun MonthGrid(monthMs: Long, all: List<Appointment>, selDay: Long?, onMonth: (Long) -> Unit, onDay: (Long) -> Unit) {
    val cal = Calendar.getInstance().apply { timeInMillis = monthMs; set(Calendar.DAY_OF_MONTH, 1) }
    val first = dayStart(cal.timeInMillis)
    val offset = (cal.get(Calendar.DAY_OF_WEEK) - Calendar.SUNDAY)
    val days = cal.getActualMaximum(Calendar.DAY_OF_MONTH)
    val today = dayStart(System.currentTimeMillis())
    val byDay = all.groupBy { dayStart(it.startMs) }
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Ui.panel).padding(10.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { onMonth(Calendar.getInstance().apply { timeInMillis = first; add(Calendar.MONTH, -1) }.timeInMillis) }) {
                Icon(Icons.Filled.ChevronLeft, tr("Mês anterior"), tint = Ui.text)
            }
            Text(fmtMonth.format(Date(first)).replaceFirstChar { it.uppercase() }, color = Ui.text, fontSize = 16.sp, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            IconButton(onClick = { onMonth(Calendar.getInstance().apply { timeInMillis = first; add(Calendar.MONTH, 1) }.timeInMillis) }) {
                Icon(Icons.Filled.ChevronRight, tr("Próximo mês"), tint = Ui.text)
            }
        }
        Row(Modifier.fillMaxWidth()) {
            tr("D S T Q Q S S").split(" ").forEach { Text(it, color = Ui.dim, fontSize = 12.sp, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center) }
        }
        val rows = (offset + days + 6) / 7
        for (r in 0 until rows) {
            Row(Modifier.fillMaxWidth()) {
                for (c in 0 until 7) {
                    val n = r * 7 + c - offset + 1
                    if (n < 1 || n > days) { Spacer(Modifier.weight(1f).aspectRatio(1.25f)); continue }
                    val d = Calendar.getInstance().apply { timeInMillis = first; add(Calendar.DAY_OF_MONTH, n - 1) }.timeInMillis
                    val list = byDay[d].orEmpty()
                    Column(
                        Modifier.weight(1f).aspectRatio(1.25f).padding(1.dp).clip(RoundedCornerShape(8.dp))
                            .background(if (selDay == d) Ui.accent else if (d == today) Ui.panel2 else Color.Transparent)
                            .clickable { onDay(d) },
                        horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center,
                    ) {
                        Text("$n", color = if (selDay == d) Color.White else Ui.text, fontSize = 14.sp)
                        Row(horizontalArrangement = Arrangement.spacedBy(2.dp), modifier = Modifier.height(6.dp)) {
                            list.take(3).forEach { Box(Modifier.size(5.dp).clip(CircleShape).background(Color(it.kind.argb))) }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ApptCard(vm: AppViewModel, a: Appointment, onEdit: () -> Unit) {
    val ctx = LocalContext.current
    val noteMeta = a.noteId?.let { id -> vm.index.notes.firstOrNull { it.id == id } }
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).clickable(onClick = onEdit).padding(14.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.width(4.dp).height(38.dp).clip(RoundedCornerShape(2.dp)).background(Color(a.kind.argb)))
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                Text("${a.kind.icon} ${a.title.ifBlank { a.kind.label }}", color = if (a.done) Ui.dim else Ui.text, fontSize = 16.sp, fontWeight = FontWeight.Medium)
                val sub = listOf(a.clientName, a.address).filter { it.isNotBlank() }.joinToString(" · ")
                if (sub.isNotBlank()) Text(sub, color = Ui.dim, fontSize = 13.sp)
            }
            Text(fmtHour.format(Date(a.startMs)), color = Ui.text, fontSize = 18.sp)
        }
        FlowRow(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            if (a.projectId != null) AssistChipLike(tr("📐 Abrir projeto")) { vm.openProject(a.projectId) }
            if (noteMeta != null) AssistChipLike(tr("📝 Abrir nota")) { vm.openNote(noteMeta.id) }
            if (a.quoteId != null) AssistChipLike(tr("💲 Orçamento")) { vm.screen = Screen.Quotes }
            if (a.clientPhone.isNotBlank()) AssistChipLike(tr("💬 Avisar cliente")) { openWhatsApp(ctx, vm, a) }
            AssistChipLike(if (a.done) tr("↩ Reabrir") else tr("✔ Concluir")) { vm.saveAppt(a.copy(done = !a.done)) }
        }
    }
}

@Composable
private fun AssistChipLike(text: String, onClick: () -> Unit) {
    Box(Modifier.clip(RoundedCornerShape(16.dp)).background(Ui.panel2).clickable(onClick = onClick).padding(horizontal = 12.dp, vertical = 7.dp)) {
        Text(text, color = Ui.text, fontSize = 13.sp)
    }
}

private fun openWhatsApp(ctx: android.content.Context, vm: AppViewModel, a: Appointment) {
    var d = a.clientPhone.filter { it.isDigit() }
    if (d.length in 10..11) d = "55$d"
    val who = a.clientName.substringBefore(' ').ifBlank { tr("tudo bem") }
    val msg = tr("Olá, {0}! Passando pra confirmar {1} {2} ({3}) às {4}", who, a.kind.label.lowercase(), whenLabel(a.startMs).lowercase(),
        fmtDate.format(Date(a.startMs)), fmtHour.format(Date(a.startMs))) +
        (if (a.address.isNotBlank()) tr(", em {0}", a.address) else "") + "." +
        (if (vm.company.name.isNotBlank()) " — ${vm.company.name}" else "")
    runCatching {
        ctx.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse("https://wa.me/$d?text=${Uri.encode(msg)}")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
    }.onFailure { vm.toast = tr("Não consegui abrir o WhatsApp") }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ApptEditor(vm: AppViewModel, initial: Appointment, isNew: Boolean, onClose: () -> Unit) {
    var a by remember(initial.id) { mutableStateOf(initial) }
    var pickDate by remember { mutableStateOf(false) }
    var pickTime by remember { mutableStateOf(false) }
    var confirmDel by remember { mutableStateOf(false) }
    var showSug by remember { mutableStateOf(false) }
    var noteMenu by remember { mutableStateOf(false) }
    val clients = remember { vm.knownClients() }
    val sugg = clients.filter { a.clientName.isNotBlank() && it.name.contains(a.clientName, ignoreCase = true) && !it.name.equals(a.clientName, true) }.take(5)
    val cal = Calendar.getInstance().apply { timeInMillis = a.startMs }
    val quotesOfClient = vm.quotes.filter { a.clientName.isNotBlank() && it.clientName.equals(a.clientName, true) }
    val notes = vm.index.notes.filter { !it.trash }

    fun pickClient(c: br.com.arque.measure.model.ClientRef) {
        a = a.copy(
            clientName = c.name, clientPhone = c.phone.ifBlank { a.clientPhone }, projectId = c.projectId ?: a.projectId,
            address = a.address.ifBlank { c.address },
            quoteId = vm.quotes.firstOrNull { it.clientName.equals(c.name, true) }?.id ?: a.quoteId,
        )
        showSug = false
    }

    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding(), color = Ui.bg) {
            Column(Modifier.fillMaxSize()) {
                Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onClose) { Icon(Icons.AutoMirrored.Filled.ArrowBack, tr("Fechar"), tint = Ui.text) }
                    Text(if (isNew) tr("Novo compromisso") else tr("Compromisso"), color = Ui.text, fontSize = 20.sp, modifier = Modifier.weight(1f))
                    Button(onClick = { vm.saveAppt(a.copy(title = a.title.trim())); onClose() }) { Text(tr("Salvar")) }
                }
                Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        ApptKind.entries.forEach { k ->
                            FilterChip(selected = a.kind == k, onClick = { a = a.copy(kind = k) }, label = { Text("${k.icon} ${k.label}") })
                        }
                    }
                    OutlinedTextField(a.title, { a = a.copy(title = it) }, label = { Text(tr("Título (ex.: Entrega da cozinha)")) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        OutlinedButton(onClick = { pickDate = true }, modifier = Modifier.weight(1f)) { Text("📅 ${fmtDate.format(Date(a.startMs))}") }
                        OutlinedButton(onClick = { pickTime = true }, modifier = Modifier.weight(1f)) { Text("🕒 ${fmtHour.format(Date(a.startMs))}") }
                    }
                    Text(tr("Cliente"), color = Ui.dim, fontSize = 13.sp)
                    OutlinedTextField(
                        a.clientName, { a = a.copy(clientName = it); showSug = true },
                        label = { Text(tr("Nome do cliente (digite pra buscar)")) }, modifier = Modifier.fillMaxWidth(), singleLine = true,
                    )
                    if (showSug && sugg.isNotEmpty()) {
                        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Ui.panel)) {
                            sugg.forEach { c ->
                                Column(Modifier.fillMaxWidth().clickable { pickClient(c) }.padding(12.dp)) {
                                    Text((if (c.projectId != null) "📐 " else "💲 ") + c.name, color = Ui.text, fontSize = 15.sp)
                                    if (c.address.isNotBlank()) Text(c.address, color = Ui.dim, fontSize = 12.sp)
                                }
                            }
                        }
                    }
                    if (a.clientName.isBlank() && clients.isNotEmpty()) {
                        Text(tr("Clientes salvos (toque pra puxar telefone, endereço e projeto):"), color = Ui.dim, fontSize = 12.sp)
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                            clients.take(12).forEach { c -> AssistChipLike((if (c.projectId != null) "📐 " else "💲 ") + c.name) { pickClient(c) } }
                        }
                    }
                    OutlinedTextField(a.clientPhone, { a = a.copy(clientPhone = it) }, label = { Text(tr("Telefone / WhatsApp do cliente")) }, modifier = Modifier.fillMaxWidth(), singleLine = true)
                    OutlinedTextField(a.address, { a = a.copy(address = it) }, label = { Text(tr("Endereço do compromisso")) }, modifier = Modifier.fillMaxWidth())

                    Text(tr("Vínculos"), color = Ui.dim, fontSize = 13.sp)
                    Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Ui.panel).padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(tr("📐 Projeto do cliente"), color = Ui.text, fontSize = 15.sp)
                            Text(if (a.projectId != null) tr("Vinculado — abre direto no editor de móveis") else tr("Escolha o cliente salvo pra vincular o projeto"), color = Ui.dim, fontSize = 12.sp)
                        }
                        if (a.projectId != null) {
                            TextButton(onClick = { vm.saveAppt(a); onClose(); vm.openProject(a.projectId!!) }) { Text(tr("Abrir")) }
                            TextButton(onClick = { a = a.copy(projectId = null) }) { Text(tr("Tirar")) }
                        }
                    }
                    Box {
                        Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Ui.panel).clickable { noteMenu = true }.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Column(Modifier.weight(1f)) {
                                Text(tr("📝 Nota"), color = Ui.text, fontSize = 15.sp)
                                Text(notes.firstOrNull { it.id == a.noteId }?.name ?: tr("Toque pra vincular uma nota (medidas, fotos)"), color = Ui.dim, fontSize = 12.sp)
                            }
                            if (a.noteId != null) TextButton(onClick = { val id = a.noteId!!; vm.saveAppt(a); onClose(); vm.openNote(id) }) { Text(tr("Abrir")) }
                        }
                        DropdownMenu(expanded = noteMenu, onDismissRequest = { noteMenu = false }) {
                            DropdownMenuItem(text = { Text(tr("Nenhuma")) }, onClick = { a = a.copy(noteId = null); noteMenu = false })
                            notes.forEach { n -> DropdownMenuItem(text = { Text(n.name) }, onClick = { a = a.copy(noteId = n.id); noteMenu = false }) }
                        }
                    }
                    if (quotesOfClient.isNotEmpty()) {
                        Text(tr("💲 Orçamento do cliente"), color = Ui.dim, fontSize = 13.sp)
                        FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            quotesOfClient.forEach { q ->
                                FilterChip(selected = a.quoteId == q.id, onClick = { a = a.copy(quoteId = if (a.quoteId == q.id) null else q.id) },
                                    label = { Text(fmtDate.format(Date(q.dateMs))) })
                            }
                        }
                    }

                    Text(tr("Avisar (notificação neste aparelho)"), color = Ui.dim, fontSize = 13.sp)
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        REMIND_OPTIONS.forEach { (min, label) ->
                            FilterChip(selected = min in a.remindMin, onClick = {
                                a = a.copy(remindMin = if (min in a.remindMin) a.remindMin - min else (a.remindMin + min).sorted())
                            }, label = { Text(label) })
                        }
                    }
                    OutlinedTextField(a.notes, { a = a.copy(notes = it) }, label = { Text(tr("Observações")) }, modifier = Modifier.fillMaxWidth().height(110.dp))
                    if (!isNew) TextButton(onClick = { confirmDel = true }) { Text(tr("Apagar compromisso"), color = Color(0xFFEF6A6A)) }
                    Spacer(Modifier.height(24.dp))
                }
            }
        }
    }

    if (pickDate) {
        val st = rememberDatePickerState(initialSelectedDateMillis = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
            set(cal.get(Calendar.YEAR), cal.get(Calendar.MONTH), cal.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
        }.timeInMillis)
        androidx.compose.material3.DatePickerDialog(
            onDismissRequest = { pickDate = false },
            confirmButton = {
                TextButton(onClick = {
                    st.selectedDateMillis?.let { ms ->
                        val u = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = ms }
                        val n = Calendar.getInstance().apply {
                            timeInMillis = a.startMs; set(u.get(Calendar.YEAR), u.get(Calendar.MONTH), u.get(Calendar.DAY_OF_MONTH))
                        }
                        a = a.copy(startMs = n.timeInMillis)
                    }
                    pickDate = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickDate = false }) { Text(tr("Cancelar")) } },
        ) { DatePicker(st) }
    }
    if (pickTime) {
        val st = rememberTimePickerState(cal.get(Calendar.HOUR_OF_DAY), cal.get(Calendar.MINUTE), true)
        AlertDialog(
            onDismissRequest = { pickTime = false },
            confirmButton = {
                TextButton(onClick = {
                    a = a.copy(startMs = Calendar.getInstance().apply {
                        timeInMillis = a.startMs; set(Calendar.HOUR_OF_DAY, st.hour); set(Calendar.MINUTE, st.minute); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
                    }.timeInMillis)
                    pickTime = false
                }) { Text("OK") }
            },
            dismissButton = { TextButton(onClick = { pickTime = false }) { Text(tr("Cancelar")) } },
            text = { TimePicker(st) },
        )
    }
    if (confirmDel) {
        ConfirmDialog(tr("Apagar compromisso"), tr("Apagar “{0}”?", a.title.ifBlank { a.kind.label }), tr("Apagar"), { confirmDel = false }) {
            vm.deleteAppt(a.id); confirmDel = false; onClose()
        }
    }
}
