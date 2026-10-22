package br.com.arque.measure.ui

import android.content.Intent
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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

private val dateFmt = SimpleDateFormat("dd/MM/yyyy", Locale("pt", "BR")).apply { isLenient = false }

@Composable
fun QuotesScreen(vm: AppViewModel) {
    var editingId by remember { mutableStateOf<String?>(null) }
    var companyDlg by remember { mutableStateOf(false) }
    var confirmDel by remember { mutableStateOf<Quote?>(null) }
    BackHandler(enabled = editingId != null) { editingId = null }

    Box(Modifier.fillMaxSize().background(Ui.bg).statusBarsPadding().navigationBarsPadding()) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { if (editingId != null) editingId = null else vm.screen = Screen.Library }) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar", tint = Ui.text)
            }
            Text(if (editingId == null) "Orçamentos" else "Orçamento", color = Ui.text, fontSize = 20.sp, modifier = Modifier.weight(1f))
            TextButton(onClick = { companyDlg = true }) { Text("Dados da empresa") }
        }
        val q = vm.quotes.firstOrNull { it.id == editingId }
        if (q != null) {
            QuoteEditor(vm, q)
        } else {
            Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Button(onClick = {
                    val n = Quote(city = vm.company.city)
                    vm.saveQuote(n); editingId = n.id
                }, modifier = Modifier.fillMaxWidth()) { Text("+ Novo orçamento") }
                if (vm.company.name.isBlank()) {
                    Text("Dica: preencha os “Dados da empresa” uma vez e eles saem em todos os orçamentos.", color = Ui.dim, fontSize = 13.sp)
                }
                vm.quotes.forEach { it ->
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel)
                            .clickable { editingId = it.id }.padding(14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Column(Modifier.weight(1f)) {
                            Text(it.clientName.ifBlank { "(sem cliente)" }, color = Ui.text, fontSize = 16.sp)
                            Text(dateFmt.format(Date(it.dateMs)) + (if (it.city.isNotBlank()) " · ${it.city}" else ""), color = Ui.dim, fontSize = 12.sp)
                        }
                        Text(QuoteMath.brl(QuoteMath.finalValue(it)), color = Ui.text, fontSize = 15.sp)
                        IconButton(onClick = { confirmDel = it }) { Icon(Icons.Filled.Delete, "Apagar", tint = Ui.dim) }
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
        ConfirmDialog("Apagar orçamento", "Apagar o orçamento de ${d.clientName.ifBlank { "(sem cliente)" }}?", "Apagar", { confirmDel = null }) {
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
        title = { Text("Dados da empresa") },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState()), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("Logo (sai no topo do orçamento)", color = Ui.dim, fontSize = 13.sp)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    val lb = vm.logoBmp
                    Box(Modifier.width(96.dp).height(64.dp).clip(RoundedCornerShape(8.dp)).background(Color.White), contentAlignment = Alignment.Center) {
                        if (lb != null) androidx.compose.foundation.Image(lb.asImageBitmap(), "Logo", Modifier.fillMaxSize().padding(4.dp), contentScale = androidx.compose.ui.layout.ContentScale.Fit)
                        else Text("sem logo", color = Color.Gray, fontSize = 12.sp)
                    }
                    Column {
                        TextButton(onClick = { pick.launch("image/*") }) { Text(if (lb == null) "Carregar logo" else "Trocar logo") }
                        if (lb != null) TextButton(onClick = { vm.clearLogo() }) { Text("Remover") }
                    }
                }
                Field(name, "Nome da empresa") { name = it }
                Field(cnpj, "CNPJ") { cnpj = it }
                Field(addr, "Endereço") { addr = it }
                Field(city, "Cidade") { city = it }
                Field(phone, "Telefone / WhatsApp") { phone = it }
            }
        },
        confirmButton = { TextButton(onClick = { onOk(Company(name.trim(), cnpj.trim(), addr.trim(), city.trim(), phone.trim())) }) { Text("Salvar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
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
    Field(t, label, modifier, number = true) { s ->
        t = s
        onValue(QuoteMath.parseNum(s) ?: 0.0)
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
        Field(q.clientName, "Nome do cliente") { upd(q.copy(clientName = it)) }
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Field(q.city, "Cidade", Modifier.weight(1f)) { upd(q.copy(city = it)) }
            Field(dateText, "Data (dd/mm/aaaa)", Modifier.weight(1f)) { s ->
                dateText = s
                if (s.length == 10) runCatching { dateFmt.parse(s) }.getOrNull()?.let { upd(q.copy(dateMs = it.time)) }
            }
        }
        Text("Itens", color = Ui.text, fontSize = 16.sp)
        q.items.forEachIndexed { idx, it ->
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(10.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Field(it.desc, "Descrição do item ${idx + 1}", Modifier.weight(1f)) { s -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(desc = s) else x })) }
                    IconButton(onClick = { upd(q.copy(items = q.items.filter { x -> x.id != it.id }.ifEmpty { listOf(QuoteItem()) })) }) {
                        Icon(Icons.Filled.Delete, "Remover item", tint = Ui.dim)
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    NumField(it.id + "q", it.qty, "Qtd", Modifier.weight(1f)) { v -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(qty = v) else x })) }
                    Field(it.unit, "Un.", Modifier.weight(1f)) { s -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(unit = s) else x })) }
                    NumField(it.id + "v", it.unitValue, "Valor unit. (R$)", Modifier.weight(1.6f)) { v -> upd(q.copy(items = q.items.map { x -> if (x.id == it.id) x.copy(unitValue = v) else x })) }
                }
                Text("Subtotal: " + QuoteMath.brl(QuoteMath.lineTotal(it)), color = Ui.dim, fontSize = 13.sp)
            }
        }
        OutlinedButton(onClick = { upd(q.copy(items = q.items + QuoteItem())) }, modifier = Modifier.fillMaxWidth()) { Text("+ Adicionar item") }

        NumField(q.id + "d", q.discountPct, "Desconto (%)", Modifier.fillMaxWidth()) { v -> upd(q.copy(discountPct = v.coerceIn(0.0, 100.0))) }
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Ui.panel).padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Valor original: " + QuoteMath.brl(QuoteMath.original(q)), color = Ui.text, fontSize = 15.sp)
            if (q.discountPct > 0.0) {
                Text("Desconto: − " + QuoteMath.brl(QuoteMath.discountValue(q)), color = Ui.dim, fontSize = 14.sp)
                Text("Valor com desconto: " + QuoteMath.brl(QuoteMath.finalValue(q)), color = Ui.text, fontSize = 17.sp)
            }
            Text("Validade da proposta: ${q.validityDays} dias", color = Ui.dim, fontSize = 13.sp)
        }

        Field(q.notes, "Observações (opcional)", Modifier.fillMaxWidth()) { upd(q.copy(notes = it)) }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Incluir o desenho (nota) no PDF", color = Ui.text, fontSize = 15.sp, modifier = Modifier.weight(1f))
            Switch(checked = q.includeDrawing, onCheckedChange = { upd(q.copy(includeDrawing = it)) })
        }
        if (q.includeDrawing) {
            Box {
                OutlinedButton(onClick = { noteMenu = true }, modifier = Modifier.fillMaxWidth()) {
                    Text(notes.firstOrNull { it.id == q.noteId }?.name ?: "Escolher a nota do desenho")
                }
                DropdownMenu(expanded = noteMenu, onDismissRequest = { noteMenu = false }) {
                    notes.forEach { n -> DropdownMenuItem(text = { Text(n.name) }, onClick = { noteMenu = false; upd(q.copy(noteId = n.id)) }) }
                }
            }
        }

        Button(
            onClick = {
                if (q.includeDrawing && q.noteId == null) { vm.toast = "Escolha a nota do desenho"; return@Button }
                vm.buildQuotePdf(q) { uri ->
                    val send = Intent(Intent.ACTION_SEND).apply {
                        type = "application/pdf"
                        putExtra(Intent.EXTRA_STREAM, uri)
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    ctx.startActivity(Intent.createChooser(send, "Enviar orçamento").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                }
            },
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Gerar PDF e enviar") }
        Spacer(Modifier.height(32.dp))
    }
}
