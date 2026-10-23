package br.com.arque.measure.ui

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AllInbox
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Event
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.NoteAdd
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.LibFilter
import br.com.arque.measure.Screen
import br.com.arque.measure.model.NoteMeta
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun App(vm: AppViewModel) {
    BackHandler(enabled = vm.screen == Screen.Editor) { vm.closeEditor() }
    BackHandler(enabled = vm.screen == Screen.Quotes) { vm.screen = Screen.Library }

    LaunchedEffect(vm.toast) {
        if (vm.toast != null) {
            delay(2800)
            vm.toast = null
        }
    }

    if (vm.licLocked) {
        LockScreen(vm)
        return
    }
    Box(Modifier.fillMaxSize().background(Ui.bg)) {
        when (vm.screen) {
            Screen.Library -> LibraryScreen(vm)
            Screen.Editor -> vm.session?.let { EditorScreen(vm, it) }
            Screen.Quotes -> QuotesScreen(vm)
            Screen.Agenda -> AgendaScreen(vm)
            Screen.Moveis -> MoveisScreen(vm)
        }
        if (!vm.licUnlocked && vm.trialLeft.isNotEmpty() && vm.screen == Screen.Library) {
            TrialChip(vm, Modifier.align(Alignment.BottomStart).navigationBarsPadding().padding(10.dp))
        }
        if (vm.showWelcome) WelcomeDialog(vm)
        UpdateOfferDialog(vm)
        vm.toast?.let { msg ->
            Surface(
                modifier = Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 64.dp, start = 16.dp, end = 16.dp),
                shape = RoundedCornerShape(20.dp),
                color = Color(0xEE000000),
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

private val dateFmt = SimpleDateFormat("dd/MM/yyyy", Locale("pt", "BR"))

private enum class LibTab(val label: String) { ALL("TUDO"), NOTE("NOTA"), PDF("PDF") }

// ---------------------------------------------------------------- Biblioteca (estilo Star Note, escura)

@Composable
fun LibraryScreen(vm: AppViewModel) {
    var query by remember { mutableStateOf("") }
    var tab by remember { mutableStateOf(LibTab.ALL) }
    var fabMenu by remember { mutableStateOf(false) }
    var topMenu by remember { mutableStateOf(false) }
    var newFolder by remember { mutableStateOf(false) }
    var confirmRestore by remember { mutableStateOf<Uri?>(null) }
    var btView by remember { mutableStateOf(false) }

    val backupLauncher = rememberLauncherForActivityResult(ActivityResultContracts.CreateDocument("application/zip")) { uri ->
        if (uri != null) vm.backup(uri)
    }
    val restoreLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) confirmRestore = uri
    }

    val filter = vm.filter
    val notes = vm.index.notes
        .filter {
            when (filter) {
                LibFilter.All -> !it.trash
                LibFilter.Trash -> it.trash
                is LibFilter.InFolder -> !it.trash && it.folderId == filter.id
            }
        }
        .filter { query.isBlank() || it.name.contains(query, ignoreCase = true) }
        .filter { tab != LibTab.PDF }
        .sortedWith(compareByDescending<NoteMeta> { it.pinned }.thenByDescending { it.createdMs })

    BoxWithConstraints(Modifier.fillMaxSize().statusBarsPadding()) {
        val wide = maxWidth >= 700.dp
        Row(Modifier.fillMaxSize()) {
            if (wide) {
                Column(Modifier.width(230.dp).fillMaxHeight().background(Ui.panel).verticalScroll(rememberScrollState()).padding(12.dp)) {
                    Text("ARQUEMESTRE", color = Ui.text, fontSize = 15.sp, modifier = Modifier.padding(8.dp))
                    SideItem("Todas as notas", Icons.Filled.AllInbox, filter == LibFilter.All) { vm.filter = LibFilter.All }
                    Text("Pastas", color = Ui.dim, fontSize = 12.sp, modifier = Modifier.padding(start = 8.dp, top = 12.dp, bottom = 4.dp))
                    vm.index.folders.forEach { f ->
                        SideItem(f.name, Icons.Filled.Folder, filter == LibFilter.InFolder(f.id)) { vm.filter = LibFilter.InFolder(f.id) }
                    }
                    SideItem("Nova pasta", Icons.Filled.CreateNewFolder, false) { newFolder = true }
                    Spacer(Modifier.height(12.dp))
                    SideItem("Editor de móveis", Icons.Filled.Build, false) { vm.screen = Screen.Moveis }
                    SideItem("Agenda", Icons.Filled.Event, false) { vm.screen = Screen.Agenda }
                    SideItem("Orçamentos", Icons.Filled.Description, false) { vm.screen = Screen.Quotes }
                    SideItem("Lixo", Icons.Filled.Delete, filter == LibFilter.Trash) { vm.filter = LibFilter.Trash }
                }
            }
            Column(Modifier.weight(1f).fillMaxHeight()) {
                Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Row(
                        Modifier.weight(1f).clip(RoundedCornerShape(12.dp)).background(Ui.panel2).padding(horizontal = 12.dp, vertical = 10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Search, null, tint = Ui.dim, modifier = Modifier.size(18.dp))
                        Spacer(Modifier.width(8.dp))
                        androidx.compose.foundation.text.BasicTextField(
                            value = query, onValueChange = { query = it }, singleLine = true,
                            textStyle = androidx.compose.ui.text.TextStyle(color = Ui.text, fontSize = 15.sp),
                            cursorBrush = androidx.compose.ui.graphics.SolidColor(Ui.accent),
                            decorationBox = { inner ->
                                if (query.isEmpty()) Text("Pesquisar", color = Ui.dim, fontSize = 15.sp)
                                inner()
                            },
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                    Box {
                        IconButton(onClick = { topMenu = true }) { Icon(Icons.Filled.MoreVert, "Menu", tint = Ui.text) }
                        DropdownMenu(expanded = topMenu, onDismissRequest = { topMenu = false }) {
                            DropdownMenuItem(text = { Text("Editor de móveis") }, onClick = {
                                topMenu = false; vm.screen = Screen.Moveis
                            })
                            DropdownMenuItem(text = { Text("Agenda") }, onClick = {
                                topMenu = false; vm.screen = Screen.Agenda
                            })
                            DropdownMenuItem(text = { Text("Orçamentos") }, onClick = {
                                topMenu = false; vm.screen = Screen.Quotes
                            })
                            DropdownMenuItem(text = { Text("Fazer backup completo (ZIP)") }, onClick = {
                                topMenu = false; backupLauncher.launch("arque-measure-backup.zip")
                            })
                            DropdownMenuItem(text = { Text("Restaurar backup") }, onClick = {
                                topMenu = false; restoreLauncher.launch(arrayOf("application/zip", "application/octet-stream"))
                            })
                            DropdownMenuItem(text = { Text("Atualizar o app (sem perder dados)") }, onClick = {
                                topMenu = false; vm.checkUpdate()
                            })
                            DropdownMenuItem(text = { Text("Ver projeto por Bluetooth") }, onClick = {
                                topMenu = false; btView = true
                            })
                        }
                    }
                }
                if (!wide) {
                    Row(
                        Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        FilterChip(selected = false, onClick = { vm.screen = Screen.Agenda }, label = { Text("📅 Agenda") })
                        FilterChip(selected = false, onClick = { vm.screen = Screen.Moveis }, label = { Text("Editor de móveis") })
                        FilterChip(selected = filter == LibFilter.All, onClick = { vm.filter = LibFilter.All }, label = { Text("Todas as notas") })
                        vm.index.folders.forEach { f ->
                            FilterChip(selected = filter == LibFilter.InFolder(f.id), onClick = { vm.filter = LibFilter.InFolder(f.id) }, label = { Text(f.name) })
                        }
                        FilterChip(selected = filter == LibFilter.Trash, onClick = { vm.filter = LibFilter.Trash }, label = { Text("Lixo") })
                        FilterChip(selected = false, onClick = { vm.screen = Screen.Quotes }, label = { Text("Orçamentos") })
                    }
                }
                Row(Modifier.padding(horizontal = 12.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                    LibTab.entries.forEach { t ->
                        Column(Modifier.clickable { tab = t }, horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(t.label, color = if (tab == t) Ui.text else Ui.dim, fontSize = 13.sp)
                            Box(Modifier.padding(top = 4.dp).height(2.dp).width(28.dp).background(if (tab == t) Ui.accent else Color.Transparent))
                        }
                    }
                }
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(300.dp),
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = androidx.compose.foundation.layout.PaddingValues(12.dp, 4.dp, 12.dp, 110.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    if (filter != LibFilter.Trash && tab != LibTab.PDF && query.isBlank()) {
                        item(key = "criar") { CreateTile { vm.openNote(vm.createNote()) } }
                    }
                    items(notes, key = { it.id }) { n -> NoteRow(vm, n) }
                }
            }
        }

        if (filter != LibFilter.Trash) {
            Box(Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(20.dp)) {
                Box(
                    Modifier.size(58.dp).clip(CircleShape).background(Ui.accent).clickable { fabMenu = true },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Filled.Add, "Novo", tint = Color.White, modifier = Modifier.size(30.dp)) }
                DropdownMenu(expanded = fabMenu, onDismissRequest = { fabMenu = false }) {
                    DropdownMenuItem(text = { Text("Criar nota") }, leadingIcon = { Icon(Icons.Filled.NoteAdd, null) }, onClick = {
                        fabMenu = false; vm.openNote(vm.createNote())
                    })
                    DropdownMenuItem(text = { Text("Anotação infinita (em breve)") }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text("Importar ficheiros (em breve)") }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text("Importar imagem") }, leadingIcon = { Icon(Icons.Filled.Image, null) }, onClick = {
                        fabMenu = false
                        val id = vm.createNote(); vm.pendingImport = "gallery"; vm.openNote(id)
                    })
                    DropdownMenuItem(text = { Text("Tirar fotografia") }, leadingIcon = { Icon(Icons.Filled.PhotoCamera, null) }, onClick = {
                        fabMenu = false
                        val id = vm.createNote(); vm.pendingImport = "camera"; vm.openNote(id)
                    })
                    DropdownMenuItem(text = { Text("Criar nova pasta") }, leadingIcon = { Icon(Icons.Filled.CreateNewFolder, null) }, onClick = {
                        fabMenu = false; newFolder = true
                    })
                }
            }
        }
    }

    if (newFolder) NameDialog("Nova pasta", "Nome da pasta", "", { newFolder = false }) { newFolder = false; vm.addFolder(it) }
    if (btView) ShareViewPicker(vm) { btView = false }
    vm.updateState?.let { msg ->
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { vm.updateState = null },
            title = { Text("Atualizar o app") },
            text = { Text(msg) },
            confirmButton = {
                if (vm.updateReady != null) androidx.compose.material3.TextButton(onClick = { vm.installUpdate() }) { Text("Instalar") }
            },
            dismissButton = { androidx.compose.material3.TextButton(onClick = { vm.updateState = null }) { Text("Fechar") } },
        )
    }
    confirmRestore?.let { uri ->
        ConfirmDialog(
            title = "Restaurar backup?",
            message = "Isto substitui os dados atuais (notas, agenda, orçamentos, móveis) pelos do backup. O app reinicia.",
            confirm = "Restaurar",
            onDismiss = { confirmRestore = null },
            onOk = { confirmRestore = null; vm.restore(uri) },
        )
    }
}

@Composable
private fun SideItem(label: String, icon: ImageVector, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(if (selected) Ui.panel2 else Color.Transparent)
            .clickable(onClick = onClick).padding(horizontal = 10.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (selected) Ui.accent else Ui.dim, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(10.dp))
        Text(label, color = Ui.text, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun CreateTile(onClick: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(96.dp).clip(RoundedCornerShape(14.dp)).clickable(onClick = onClick).drawBehind {
            drawRoundRect(
                color = Color(0xFF6B7078), cornerRadius = CornerRadius(14.dp.toPx()),
                style = Stroke(width = 2.dp.toPx(), pathEffect = PathEffect.dashPathEffect(floatArrayOf(18f, 12f))),
            )
        },
        contentAlignment = Alignment.Center,
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Filled.Add, null, tint = Ui.dim)
            Spacer(Modifier.width(6.dp))
            Text("Criar", color = Ui.dim, fontSize = 16.sp)
        }
    }
}

@Composable
private fun NoteRow(vm: AppViewModel, n: NoteMeta) {
    var menu by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf(false) }
    var move by remember { mutableStateOf(false) }
    val trash = n.trash
    Row(
        Modifier.fillMaxWidth().height(96.dp).clip(RoundedCornerShape(14.dp)).background(Ui.panel)
            .clickable(enabled = !trash) { vm.openNote(n.id) }.padding(10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val thumb = remember(n.id, vm.thumbVersion, n.pageCount, n.dimCount) { vm.loadThumb(n.id) }
        Box(
            Modifier.size(width = 56.dp, height = 76.dp).clip(RoundedCornerShape(4.dp)).background(Color.White)
                .border(BorderStroke(1.dp, Ui.line), RoundedCornerShape(4.dp)),
        ) {
            if (thumb != null) {
                androidx.compose.foundation.Image(thumb, null, Modifier.fillMaxSize(), contentScale = androidx.compose.ui.layout.ContentScale.Crop)
            }
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(n.name, color = Ui.text, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                if (n.pinned) Icon(Icons.Filled.PushPin, null, tint = Ui.accent, modifier = Modifier.padding(start = 6.dp).size(14.dp))
                if (n.locked) Icon(Icons.Filled.Lock, null, tint = Ui.dim, modifier = Modifier.padding(start = 6.dp).size(14.dp))
            }
            Text(dateFmt.format(Date(n.createdMs)), color = Ui.dim, fontSize = 12.sp)
            Text(
                "${n.pageCount} ${if (n.pageCount == 1) "folha" else "folhas"} · ${n.dimCount} ${if (n.dimCount == 1) "cota" else "cotas"}",
                color = Ui.dim, fontSize = 12.sp,
            )
        }
        Box {
            IconButton(onClick = { menu = true }) { Icon(Icons.Filled.KeyboardArrowDown, "Menu da nota", tint = Ui.text) }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                if (trash) {
                    DropdownMenuItem(text = { Text("Restaurar") }, onClick = { menu = false; vm.trashNote(n.id, false) })
                } else {
                    DropdownMenuItem(text = { Text("Editar") }, onClick = { menu = false; rename = true })
                    DropdownMenuItem(text = { Text("Copiar") }, onClick = { menu = false; vm.copyNote(n.id) })
                    DropdownMenuItem(
                        text = { Text(if (n.pinned) "Desafixar nota" else "Fixar nota") },
                        onClick = { menu = false; vm.pinNote(n.id, !n.pinned) },
                    )
                    DropdownMenuItem(text = { Text("Alterar a capa (em breve)") }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text("Exportar e partilhar (em breve)") }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text("Editar etiquetas (em breve)") }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text("Mover para") }, onClick = { menu = false; move = true })
                    DropdownMenuItem(
                        text = { Text(if (n.locked) "Remover bloqueio" else "Adicionar bloqueio") },
                        onClick = { menu = false; vm.lockNote(n.id, !n.locked) },
                    )
                    DropdownMenuItem(text = { Text("Sincronização em nuvem (em breve)") }, enabled = false, onClick = {})
                    HorizontalDivider()
                    DropdownMenuItem(text = { Text("Mover para o lixo") }, onClick = { menu = false; vm.trashNote(n.id, true) })
                }
            }
        }
    }
    if (rename) NameDialog("Editar nota", "Nome", n.name, { rename = false }) { rename = false; vm.renameNote(n.id, it) }
    if (move) {
        AlertDialog(
            onDismissRequest = { move = false },
            title = { Text("Mover para") },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    TextButton(onClick = { move = false; vm.moveNote(n.id, null) }) { Text("Sem pasta") }
                    vm.index.folders.forEach { f ->
                        TextButton(onClick = { move = false; vm.moveNote(n.id, f.id) }) { Text(f.name) }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { move = false }) { Text("Cancelar") } },
        )
    }
}
