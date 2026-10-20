package br.com.arque.measure.ui

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.model.Client
import br.com.arque.measure.model.Paper
import kotlinx.coroutines.delay

@Composable
fun App(vm: AppViewModel) {
    val screen = vm.screen

    BackHandler(enabled = screen !is Screen.Home) {
        when (screen) {
            is Screen.ClientDetail -> vm.screen = Screen.Home
            is Screen.RoomDetail -> {
                val room = vm.index.rooms.firstOrNull { it.id == screen.roomId }
                vm.screen = if (room != null) Screen.ClientDetail(room.clientId) else Screen.Home
            }
            is Screen.Editor -> vm.closeEditor()
            Screen.Home -> {}
        }
    }

    LaunchedEffect(vm.toast) {
        if (vm.toast != null) {
            delay(2800)
            vm.toast = null
        }
    }

    Box(Modifier.fillMaxSize()) {
        when (screen) {
            Screen.Home -> HomeScreen(vm)
            is Screen.ClientDetail -> ClientScreen(vm, screen.clientId)
            is Screen.RoomDetail -> RoomScreen(vm, screen.roomId)
            is Screen.Editor -> vm.session?.let { EditorScreen(vm, it) }
        }
        vm.toast?.let { msg ->
            Surface(
                modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 64.dp, start = 16.dp, end = 16.dp),
                shape = RoundedCornerShape(20.dp),
                color = Color(0xEE222222),
            ) {
                Text(msg, color = Color.White, modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp))
            }
        }
    }
}

@Composable
fun NameDialog(title: String, label: String, initial: String = "", onDismiss: () -> Unit, onOk: (String) -> Unit) {
    var text by remember { mutableStateOf(initial) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { OutlinedTextField(value = text, onValueChange = { text = it }, label = { Text(label) }, singleLine = true) },
        confirmButton = { TextButton(onClick = { if (text.isNotBlank()) onOk(text) }) { Text("Salvar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

@Composable
fun ConfirmDialog(title: String, message: String, confirm: String, onDismiss: () -> Unit, onOk: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = { TextButton(onClick = onOk) { Text(confirm) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

// ---------------------------------------------------------------- Início

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(vm: AppViewModel) {
    var showNew by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    var confirmRestore by remember { mutableStateOf<Uri?>(null) }

    val backupLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri ->
        if (uri != null) vm.backup(uri)
    }
    val restoreLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) confirmRestore = uri
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("ARQUE MEASURE") },
                actions = {
                    IconButton(onClick = { menu = true }) { Icon(Icons.Filled.MoreVert, "Menu") }
                    DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                        DropdownMenuItem(text = { Text("Fazer backup (ZIP)") }, onClick = {
                            menu = false
                            backupLauncher.launch("arque-measure-backup.zip")
                        })
                        DropdownMenuItem(text = { Text("Restaurar backup") }, onClick = {
                            menu = false
                            restoreLauncher.launch(arrayOf("application/zip", "application/octet-stream"))
                        })
                    }
                },
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { showNew = true },
                icon = { Icon(Icons.Filled.Add, null) },
                text = { Text("Novo cliente") },
            )
        },
    ) { pad ->
        if (vm.index.clients.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(pad), contentAlignment = Alignment.Center) {
                Text("Nenhum cliente ainda.\nToque em “Novo cliente” para começar.", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else {
            LazyColumn(Modifier.fillMaxSize().padding(pad)) {
                items(vm.index.clients, key = { it.id }) { c ->
                    ListItem(
                        headlineContent = { Text(c.name) },
                        supportingContent = { Text(listOf(c.city, c.address).filter { it.isNotBlank() }.joinToString(" • ")) },
                        modifier = Modifier.clickable { vm.screen = Screen.ClientDetail(c.id) },
                    )
                    HorizontalDivider()
                }
            }
        }
    }

    if (showNew) NewClientDialog(
        onDismiss = { showNew = false },
        onOk = { n, c, a ->
            showNew = false
            vm.addClient(n, c, a)?.let { vm.screen = Screen.ClientDetail(it) }
        },
    )

    confirmRestore?.let { uri ->
        ConfirmDialog(
            title = "Restaurar backup?",
            message = "Isto substitui todos os clientes, ambientes e folhas atuais pelos do backup.",
            confirm = "Restaurar",
            onDismiss = { confirmRestore = null },
            onOk = { confirmRestore = null; vm.restore(uri) },
        )
    }
}

@Composable
fun NewClientDialog(onDismiss: () -> Unit, onOk: (String, String, String) -> Unit) {
    var name by remember { mutableStateOf("") }
    var city by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Novo cliente") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("Nome do cliente") }, singleLine = true)
                OutlinedTextField(city, { city = it }, label = { Text("Cidade") }, singleLine = true)
                OutlinedTextField(address, { address = it }, label = { Text("Endereço (opcional)") }, singleLine = true)
            }
        },
        confirmButton = { TextButton(onClick = { if (name.isNotBlank()) onOk(name, city, address) }) { Text("Salvar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

// ---------------------------------------------------------------- Cliente

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ClientScreen(vm: AppViewModel, clientId: String) {
    val client = vm.index.clients.firstOrNull { it.id == clientId }
    if (client == null) {
        LaunchedEffect(Unit) { vm.screen = Screen.Home }
        return
    }
    var newRoom by remember { mutableStateOf(false) }
    var edit by remember { mutableStateOf(false) }
    var del by remember { mutableStateOf(false) }
    val rooms = vm.index.rooms.filter { it.clientId == clientId }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(client.name) },
                navigationIcon = { IconButton(onClick = { vm.screen = Screen.Home }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar") } },
                actions = {
                    IconButton(onClick = { edit = true }) { Icon(Icons.Filled.Edit, "Editar dados") }
                    IconButton(onClick = { del = true }) { Icon(Icons.Filled.Delete, "Excluir cliente") }
                },
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(onClick = { newRoom = true }, icon = { Icon(Icons.Filled.Add, null) }, text = { Text("Novo ambiente") })
        },
    ) { pad ->
        LazyColumn(Modifier.fillMaxSize().padding(pad)) {
            item {
                Column(Modifier.padding(16.dp)) {
                    Text(client.city, style = MaterialTheme.typography.titleMedium)
                    listOf(client.address, client.phone, client.notes).filter { it.isNotBlank() }.forEach {
                        Text(it, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
                HorizontalDivider()
            }
            if (rooms.isEmpty()) {
                item { Text("Nenhum ambiente. Toque em “Novo ambiente”.", Modifier.padding(16.dp), color = MaterialTheme.colorScheme.onSurfaceVariant) }
            }
            items(rooms, key = { it.id }) { r ->
                val count = vm.sheetsOfRoom(r.id).size
                ListItem(
                    headlineContent = { Text(r.name) },
                    supportingContent = { Text(if (count == 1) "1 folha" else "$count folhas") },
                    modifier = Modifier.clickable { vm.screen = Screen.RoomDetail(r.id) },
                )
                HorizontalDivider()
            }
        }
    }

    if (newRoom) NewRoomDialog(onDismiss = { newRoom = false }, onOk = { name ->
        newRoom = false
        vm.addRoom(clientId, name)
    })
    if (edit) EditClientDialog(client, onDismiss = { edit = false }, onOk = { edit = false; vm.updateClient(it) })
    if (del) ConfirmDialog(
        title = "Excluir cliente?",
        message = "Apaga “${client.name}” com todos os ambientes, folhas e fotos. Não dá para desfazer (faça backup antes).",
        confirm = "Excluir",
        onDismiss = { del = false },
        onOk = { del = false; vm.screen = Screen.Home; vm.deleteClient(clientId) },
    )
}

@Composable
fun NewRoomDialog(onDismiss: () -> Unit, onOk: (String) -> Unit) {
    var name by remember { mutableStateOf("") }
    val suggestions = listOf("Cozinha", "Quarto", "Sala", "Banheiro", "Área gourmet")
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Novo ambiente") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    suggestions.forEach { s ->
                        FilterChip(selected = name == s, onClick = { name = s }, label = { Text(s) })
                    }
                }
                OutlinedTextField(name, { name = it }, label = { Text("Nome do ambiente") }, singleLine = true)
            }
        },
        confirmButton = { TextButton(onClick = { if (name.isNotBlank()) onOk(name) }) { Text("Salvar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

@Composable
fun EditClientDialog(c: Client, onDismiss: () -> Unit, onOk: (Client) -> Unit) {
    var name by remember { mutableStateOf(c.name) }
    var city by remember { mutableStateOf(c.city) }
    var address by remember { mutableStateOf(c.address) }
    var phone by remember { mutableStateOf(c.phone) }
    var notes by remember { mutableStateOf(c.notes) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Dados do cliente") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("Nome") }, singleLine = true)
                OutlinedTextField(city, { city = it }, label = { Text("Cidade") }, singleLine = true)
                OutlinedTextField(address, { address = it }, label = { Text("Endereço") }, singleLine = true)
                OutlinedTextField(phone, { phone = it }, label = { Text("Telefone") }, singleLine = true)
                OutlinedTextField(notes, { notes = it }, label = { Text("Observações") })
            }
        },
        confirmButton = {
            TextButton(onClick = {
                if (name.isNotBlank()) onOk(c.copy(name = name.trim(), city = city.trim(), address = address.trim(), phone = phone.trim(), notes = notes.trim()))
            }) { Text("Salvar") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

// ---------------------------------------------------------------- Ambiente

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RoomScreen(vm: AppViewModel, roomId: String) {
    val room = vm.index.rooms.firstOrNull { it.id == roomId }
    if (room == null) {
        LaunchedEffect(Unit) { vm.screen = Screen.Home }
        return
    }
    val sheets = vm.sheetsOfRoom(roomId)
    var newSheet by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf<String?>(null) }
    var delete by remember { mutableStateOf<String?>(null) }
    var delRoom by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(room.name) },
                navigationIcon = { IconButton(onClick = { vm.screen = Screen.ClientDetail(room.clientId) }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Voltar") } },
                actions = { IconButton(onClick = { delRoom = true }) { Icon(Icons.Filled.Delete, "Excluir ambiente") } },
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(onClick = { newSheet = true }, icon = { Icon(Icons.Filled.Add, null) }, text = { Text("Nova folha") })
        },
    ) { pad ->
        if (sheets.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(pad), contentAlignment = Alignment.Center) {
                Text("Nenhuma folha neste ambiente.\nToque em “Nova folha”.", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        } else {
            LazyColumn(Modifier.fillMaxSize().padding(pad)) {
                items(sheets, key = { it.id }) { s ->
                    ListItem(
                        headlineContent = { Text(s.name) },
                        trailingContent = {
                            Row {
                                IconButton(onClick = { rename = s.id }) { Icon(Icons.Filled.Edit, "Renomear") }
                                IconButton(onClick = { delete = s.id }) { Icon(Icons.Filled.Delete, "Excluir") }
                            }
                        },
                        modifier = Modifier.clickable { vm.openSheet(s.id) },
                    )
                    HorizontalDivider()
                }
            }
        }
    }

    if (newSheet) NewSheetDialog(
        suggested = "Folha ${sheets.size + 1}",
        onDismiss = { newSheet = false },
        onOk = { name, paper, land ->
            newSheet = false
            val s = vm.addSheet(roomId, name, paper, land)
            vm.openSheet(s.id)
        },
    )
    rename?.let { id ->
        NameDialog("Renomear folha", "Nome", sheets.firstOrNull { it.id == id }?.name ?: "", { rename = null }) {
            rename = null
            vm.renameSheet(id, it)
        }
    }
    delete?.let { id ->
        ConfirmDialog("Excluir folha?", "A folha e suas fotos/medidas serão apagadas.", "Excluir", { delete = null }) {
            delete = null
            vm.deleteSheet(id)
        }
    }
    if (delRoom) ConfirmDialog(
        "Excluir ambiente?", "Apaga “${room.name}” com todas as folhas.", "Excluir",
        { delRoom = false },
    ) {
        delRoom = false
        vm.screen = Screen.ClientDetail(room.clientId)
        vm.deleteRoom(roomId)
    }
}

@Composable
fun NewSheetDialog(suggested: String, onDismiss: () -> Unit, onOk: (String, Paper, Boolean) -> Unit) {
    var name by remember { mutableStateOf(suggested) }
    var paper by remember { mutableStateOf(Paper.A4) }
    var landscape by remember { mutableStateOf(false) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Nova folha") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(name, { name = it }, label = { Text("Nome") }, singleLine = true)
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Paper.entries.forEach { p -> FilterChip(selected = paper == p, onClick = { paper = p }, label = { Text(p.label) }) }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    FilterChip(selected = !landscape, onClick = { landscape = false }, label = { Text("Retrato") })
                    FilterChip(selected = landscape, onClick = { landscape = true }, label = { Text("Paisagem") })
                }
            }
        },
        confirmButton = { TextButton(onClick = { onOk(name, paper, landscape) }) { Text("Criar") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}
