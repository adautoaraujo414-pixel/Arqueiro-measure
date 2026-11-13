package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import android.content.Intent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.logic.QuoteMath
import br.com.arque.measure.model.Company
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

private val dateFmt get() = br.com.arque.measure.i18n.I18n.dateFormat().apply { isLenient = false }

@Composable
fun QuotesScreen(vm: AppViewModel) {
    var editingId by remember { mutableStateOf(vm.pendingQuoteId) }
    androidx.compose.runtime.LaunchedEffect(Unit) { vm.pendingQuoteId = null }
    var companyDlg by remember { mutableStateOf(false) }
    var confirmDel by remember { mutableStateOf<Quote?>(null) }
    BackHandler(enabled = editingId != null) { editingId = null }

    Box(Modifier.fillMaxSize().background(Ui.bg).statusBarsPadding().navigationBarsPadding()) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { if (editingId != null) editingId = null else vm.leaveQuotes() }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, tr("Voltar"), tint = Ui.text)
            }
            Text(if (editingId == null) tr("Orçamentos") else tr("Orçamento"), color = Ui.text, fontSize = 20.sp, modifier = Modifier.weight(1f))
            TextButton(onClick = { companyDlg = true }) { Text(tr("Dados da empresa")) }
        }
        val q = vm.quotes.firstOrNull { it.id == editingId }
        if (q != null) {
            QuoteEditor(vm, q)
        } else {
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = {
                    val n = Quote(city = vm.company.city)
                    vm.saveQuote(n); editingId = n.id
                }, modifier = Modifier.fillMaxWidth()) { Text(tr("+ Novo orçamento")) }
                if (vm.company.name.isBlank()) {
                    Text(tr("Dica: preencha os “Dados da empresa” uma vez e eles saem em todos os orçamentos."), color = Ui.dim, fontSize = 13.sp)
                }
                vm.quotes.forEach { it ->
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel)
                            .clickable { editingId = it.id }.padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(it.clientName.ifBlank { tr("(sem cliente)") }, color = Ui.text, fontSize = 16.sp)
                            Text(dateFmt.format(Date(it.dateMs)) + (if (it.city.isNotBlank()) " · ${it.city}" else ""), color = Ui.dim, fontSize = 12.sp)
                        }
                        Text(QuoteMath.brl(QuoteMath.grandTotal(it)), color = Ui.text, fontSize = 15.sp)
                        IconButton(onClick = { confirmDel = it }) { Icon(Icons.Filled.Delete, tr("Apagar"), tint = Ui.dim) }
                    }
                }
                Spacer(Modifier.height(24.dp))
            }
        }
    }
    FloatingCalculator()
    }
    if (companyDlg) CompanyDialog(vm, vm.company, { companyDlg = false }) { vm.saveCompany(it); companyDlg = false }
    confirmDel?.let { d ->
        ConfirmDialog(tr("Apagar orçamento"), tr("Apagar o orçamento de {0}?", d.clientName.ifBlank { tr("(sem cliente)") }), tr("Apagar"), { confirmDel = null }) {
            vm.deleteQuote(d.id); confirmDel = null
        }
    }
}

@Composable
private fun CompanyDialog(vm: AppViewModel, c: Company, onDismiss: () -> Unit, onOk: (Company) -> Unit) {
    var name by remember { mutableStateOf(c.name) }
    var cnpj by remember { mutableStateOf(c.cnpj) }
    var addr by remember { mutableStateOf(c.address) }
    var city by remember { mutableStateOf(c.city) }
    var phone by remember { mutableStateOf(c.phone) }
    val pick = androidx.activity.compose.rememberLauncherForActivityResult(
        androidx.activity.result.contract.ActivityResultContracts.GetContent(),
    ) { uri -> if (uri != null) vm.setLogo(uri) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Dados da empresa")) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(tr("Logo (sai no topo do orçamento)"), color = Ui.dim, fontSize = 13.sp)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    val lb = vm.logoBmp
                    Box(Modifier.width(96.dp).height(64.dp).clip(RoundedCornerShape(8.dp)).background(Color.White), contentAlignment = Alignment.Center) {
                        if (lb != null) androidx.compose.foundation.Image(lb.asImageBitmap(), tr("Logo"), Modifier.fillMaxSize().padding(4.dp), contentScale = androidx.compose.ui.layout.ContentScale.Fit)
                        else Text(tr("sem logo"), color = Color.Gray, fontSize = 12.sp)
                    }
                    Column {
                        TextButton(onClick = { pick.launch("image/*") }) { Text(if (lb == null) tr("Carregar logo") else tr("Trocar logo")) }
                        if (lb != null) TextButton(onClick = { vm.clearLogo() }) { Text(tr("Remover")) }
                    }
                }
                Field(name, tr("Nome da empresa")) { name = it }
                Field(cnpj, tr("CNPJ")) { cnpj = it }
                Field(addr, tr("Endereço")) { addr = it }
                Field(city, tr("Cidade")) { city = it }
                Field(phone, tr("Telefone / WhatsApp")) { phone = it }
            }
        },
        confirmButton = { TextButton(onClick = { onOk(Company(name.trim(), cnpj.trim(), addr.trim(), city.trim(), phone.trim())) }) { Text(tr("Salvar")) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tr("Cancelar")) } },
    )
}

@Composable
private fun Field(value: String, label: String, modifier: Modifier = Modifier.fillMaxWidth(), number: Boolean = false, onChange: (String) -> Unit) {
    OutlinedTextField(
        value = value, onValueChange = onChange, label = { Text(label) }, singleLine = true, modifier = modifier,
        keyboardOptions = if (number) KeyboardOptions(keyboardType = KeyboardType.Decimal) else KeyboardOptions.Default,
    )
}

/** Campo numérico: guarda o texto digitado (para não brigar com a vírgula) e avisa o valor. */
@Composable
private fun NumField(key: String, init: Double, label: String, modifier: Modifier, onValue: (Double) -> Unit) {
    var t by remember(key) { mutableStateOf(if (init == 0.0) "" else QuoteMath.numStr(init)) }
    NumPadField(t, label, modifier) { v ->
        t = QuoteMath.numStr(v)
        onValue(v)
    }
}

@Composable
private fun QuoteEditor(vm: AppViewModel, q: Quote) {
    val ctx = LocalContext.current
    var dateText by remember(q.id) { mutableStateOf(dateFmt.format(Date(q.dateMs))) }
    var noteMenu by remember { mutableStateOf(false) }
    val notes = vm.index.notes.filter { !it.trash }
    fun upd(n: Quote) = vm.saveQuote(n)

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Field(q.clientName, tr("Nome do cliente")) { upd(q.copy(clientName = it)) }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Field(q.city, tr("Cidade"), Modifier.weight(1f)) { upd(q.copy(city = it)) }
            Field(dateText, tr("Data (dd/mm/aaaa)"), Modifier.weight(1f)) { s ->
                dateText = s
                if (s.length == 10) runCatching { dateFmt.parse(s) }.getOrNull()?.let { upd(q.copy(dateMs = it.time)) }
            }
        }
        Text(tr("Itens"), color = Ui.text, fontSize = 16.sp)
        q.items.forEachIndexed { idx, it ->
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Field(it.desc, tr("Descrição do item {0}", idx + 1), Modifier.weight(1f)) { s -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(desc = s) else x })) }
                    IconButton(onClick = { upd(q.copy(items = q.items.filter { x -> x.id != it.id }.ifEmpty { listOf(QuoteItem()) })) }) {
                        Icon(Icons.Filled.Delete, tr("Remover item"), tint = Ui.dim)
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    NumField(it.id + "q", it.qty, tr("Qtd"), Modifier.weight(1f)) { v -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(qty = v) else x })) }
                    Field(it.unit, tr("Un."), Modifier.weight(1f)) { s -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(unit = s) else x })) }
                    NumField(it.id + "v", it.unitValue, tr("Valor unit. ({0})", br.com.arque.measure.i18n.I18n.currencySymbol()), Modifier.weight(1.6f)) { v -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(unitValue = v) else x })) }
                }
                Text(tr("Subtotal: ") + QuoteMath.brl(QuoteMath.lineTotal(it)), color = Ui.dim, fontSize = 13.sp)
            }
        }
        OutlinedButton(onClick = { upd(q.copy(items = q.items + QuoteItem())) }, modifier = Modifier.fillMaxWidth()) { Text(tr("+ Adicionar item")) }

        NumField(q.id + "d", q.discountPct, tr("Desconto (%)"), Modifier.fillMaxWidth()) { v -> upd(q.copy(discountPct = v.coerceIn(0.0, 100.0))) }
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(tr("Valor original: ") + QuoteMath.brl(QuoteMath.original(q)), color = Ui.text, fontSize = 15.sp)
            if (q.discountPct > 0.0) {
                Text(tr("Desconto: − ") + QuoteMath.brl(QuoteMath.discountValue(q)), color = Ui.dim, fontSize = 14.sp)
                Text(tr("Valor com desconto: ") + QuoteMath.brl(QuoteMath.finalValue(q)), color = Ui.text, fontSize = 17.sp)
            }
            Text(tr("Validade da proposta: {0} dias", q.validityDays), color = Ui.dim, fontSize = 13.sp)
        }

        Field(q.notes, tr("Observações (opcional)"), Modifier.fillMaxWidth()) { upd(q.copy(notes = it)) }

        // fotos do projeto: tiradas no 3D do projeto, saem no PDF
        Text(tr("Fotos do projeto"), color = Ui.text, fontSize = 16.sp)
        if (q.photos.isNotEmpty()) {
            Row(Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                q.photos.forEach { name ->
                    val bmp = remember(name) { runCatching { android.graphics.BitmapFactory.decodeFile(vm.quotePhotoFile(name).path) }.getOrNull() }
                    Box(Modifier.width(150.dp).height(100.dp).clip(RoundedCornerShape(10.dp)).background(Ui.panel)) {
                        if (bmp != null) androidx.compose.foundation.Image(bmp.asImageBitmap(), tr("Foto do projeto"), Modifier.fillMaxSize(), contentScale = androidx.compose.ui.layout.ContentScale.Crop)
                        Box(Modifier.align(Alignment.TopEnd).padding(4.dp).clip(RoundedCornerShape(50)).background(Color(0xCC000000)).clickable { vm.removeQuotePhoto(q, name) }.padding(horizontal = 9.dp, vertical = 3.dp)) {
                            Text("✕", color = Color.White, fontSize = 14.sp)
                        }
                    }
                }
            }
        }
        var projMenu by remember { mutableStateOf(false) }
        Box {
            OutlinedButton(onClick = {
                val pid = q.projId
                if (pid != null && vm.moveisProjects().any { it.id == pid }) vm.addQuotePhotos(q, pid) else projMenu = true
            }, modifier = Modifier.fillMaxWidth()) { Text(tr("📷 Adicionar fotos do projeto")) }
            DropdownMenu(expanded = projMenu, onDismissRequest = { projMenu = false }) {
                val ps = vm.moveisProjects()
                if (ps.isEmpty()) DropdownMenuItem(text = { Text(tr("Nenhum projeto de móveis ainda")) }, onClick = { projMenu = false })
                ps.forEach { p -> DropdownMenuItem(text = { Text(p.name.ifBlank { tr("(sem cliente)") } + " · " + p.label) }, onClick = { projMenu = false; vm.addQuotePhotos(q, p.id) }) }
            }
        }
        Text(tr("Abre o projeto no 3D com o botão da câmera. Tire as fotos, toque em OK e elas voltam pra cá. O ✕ tira a foto do orçamento."), color = Ui.dim, fontSize = 12.sp)

        // aditivos: itens que entram depois do orçamento fechado, sem mexer no original
        Text(tr("Aditivos"), color = Ui.text, fontSize = 16.sp)
        Text(tr("Item a mais combinado depois do orçamento fechado. O orçamento original não muda; o aditivo sai separado no PDF, com a data."), color = Ui.dim, fontSize = 12.sp)
        q.addenda.forEachIndexed { idx, a ->
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Field(a.desc, tr("Descrição do aditivo {0}", idx + 1), Modifier.weight(1f)) { s -> upd(q.copy(addenda = q.addenda.map { x -> if (x.id == a.id) x.copy(desc = s) else x })) }
                    IconButton(onClick = { upd(q.copy(addenda = q.addenda.filter { x -> x.id != a.id })) }) {
                        Icon(Icons.Filled.Delete, tr("Remover aditivo"), tint = Ui.dim)
                    }
                }
                NumField(a.id + "av", a.value, tr("Valor do aditivo ({0})", br.com.arque.measure.i18n.I18n.currencySymbol()), Modifier.fillMaxWidth()) { v -> upd(q.copy(addenda = q.addenda.map { x -> if (x.id == a.id) x.copy(value = v) else x })) }
                Text(tr("Data do aditivo: ") + dateFmt.format(Date(a.dateMs)), color = Ui.dim, fontSize = 13.sp)
            }
        }
        OutlinedButton(onClick = { upd(q.copy(addenda = q.addenda + br.com.arque.measure.model.QuoteAddendum())) }, modifier = Modifier.fillMaxWidth()) { Text(tr("+ Adicionar aditivo")) }
        if (q.addenda.isNotEmpty()) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(tr("Orçamento: ") + QuoteMath.brl(QuoteMath.finalValue(q)), color = Ui.dim, fontSize = 14.sp)
                Text(tr("Aditivos: ") + QuoteMath.brl(QuoteMath.addendaTotal(q)), color = Ui.dim, fontSize = 14.sp)
                Text(tr("Total com aditivos: ") + QuoteMath.brl(QuoteMath.grandTotal(q)), color = Ui.text, fontSize = 17.sp)
            }
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(tr("Incluir o desenho (nota) no PDF"), color = Ui.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            Switch(checked = q.includeDrawing, onCheckedChange = { upd(q.copy(includeDrawing = it)) })
        }
        if (q.includeDrawing) {
            Box {
                OutlinedButton(onClick = { noteMenu = true }, modifier = Modifier.fillMaxWidth()) {
                    Text(notes.firstOrNull { it.id == q.noteId }?.name ?: tr("Escolher a nota do desenho"))
                }
                DropdownMenu(expanded = noteMenu, onDismissRequest = { noteMenu = false }) {
                    notes.forEach { n -> DropdownMenuItem(text = { Text(n.name) }, onClick = { noteMenu = false; upd(q.copy(noteId = n.id)) }) }
                }
            }
        }

        Button(
            onClick = {
                if (q.includeDrawing && q.noteId == null) { vm.toast = tr("Escolha a nota do desenho"); return@Button }
                vm.buildQuotePdf(q) { uri ->
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    ctx.startActivity(Intent.createChooser(send, tr("Enviar orçamento")).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) { Text(tr("Gerar PDF e enviar")) }
        Spacer(Modifier.height(32.dp))
    }
}
