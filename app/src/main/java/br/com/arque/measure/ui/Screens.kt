package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

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
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.AllInbox
import androidx.compose.material.icons.filled.Language
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
    BackHandler(enabled = vm.screen == Screen.Quotes) { vm.leaveQuotes() }

    LaunchedEffect(vm.toast) {
        if (vm.toast != null) {
            delay(2800)
            vm.toast = null
        }
    }

    // pede permissão de notificação uma vez (avisos da agenda e de versão nova do app)
    val ctxN = androidx.compose.ui.platform.LocalContext.current
    val notifPermApp = androidx.activity.compose.rememberLauncherForActivityResult(androidx.activity.result.contract.ActivityResultContracts.RequestPermission()) { }
    LaunchedEffect(Unit) {
        if (android.os.Build.VERSION.SDK_INT >= 33 &&
            androidx.core.content.ContextCompat.checkSelfPermission(ctxN, android.Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) notifPermApp.launch(android.Manifest.permission.POST_NOTIFICATIONS)
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
        confirmButton = { TextButton(onClick = { if (text.isNotBlank()) onOk(text) }) { Text(tr("Salvar")) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tr("Cancelar")) } },
    )
}

@Composable
fun ConfirmDialog(title: String, message: String, confirm: String, onDismiss: () -> Unit, onOk: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(title) },
        text = { Text(message) },
        confirmButton = { TextButton(onClick = onOk) { Text(confirm) } },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tr("Cancelar")) } },
    )
}

private val dateFmt get() = br.com.arque.measure.i18n.I18n.dateFormat()

private enum class LibTab(private val ptLabel: String) { ALL("TUDO"), NOTE("NOTA"), MOVEIS("MÓVEIS"), PDF("PDF");
    val label: String get() = tr(ptLabel)
}

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
    var langOpen by remember { mutableStateOf(false) }
    if (langOpen) LanguageDialog { langOpen = false }
    val ctxN2 = androidx.compose.ui.platform.LocalContext.current

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
        .filter { tab != LibTab.PDF && tab != LibTab.MOVEIS }
        .sortedWith(compareByDescending<NoteMeta> { it.pinned }.thenByDescending { it.createdMs })

    // nota e projeto ligados ao mesmo cliente ficam com o mesmo nome
    LaunchedEffect(vm.projVersion, vm.index) { vm.syncLinkedNames() }
    val projList = remember(vm.projVersion, vm.screen) { vm.moveisProjects() }
    BoxWithConstraints(Modifier.fillMaxSize().statusBarsPadding()) {
        val wide = maxWidth >= 700.dp
        Row(Modifier.fillMaxSize()) {
            if (wide) {
                Column(Modifier.width(230.dp).fillMaxHeight().background(Ui.panel).verticalScroll(rememberScrollState()).padding(12.dp)) {
                    Text("ARQUEMESTRE", color = Ui.text, fontSize = 15.sp, modifier = Modifier.padding(8.dp))
                    SideItem(tr("Todas as notas"), Icons.Filled.AllInbox, filter == LibFilter.All) { vm.filter = LibFilter.All }
                    Text(tr("Pastas"), color = Ui.dim, fontSize = 12.sp, modifier = Modifier.padding(start = 8.dp, top = 12.dp, bottom = 4.dp))
                    vm.index.folders.forEach { f ->
                        SideItem(f.name, Icons.Filled.Folder, filter == LibFilter.InFolder(f.id)) { vm.filter = LibFilter.InFolder(f.id) }
                    }
                    SideItem(tr("Nova pasta"), Icons.Filled.CreateNewFolder, false) { newFolder = true }
                    Spacer(Modifier.height(12.dp))
                    SideItem(tr("Novo projeto de móveis"), Icons.Filled.Build, false) { vm.newMoveisProject() }
                    SideItem(tr("Agenda"), Icons.Filled.Event, false) { vm.screen = Screen.Agenda }
                    SideItem(tr("Orçamentos"), Icons.Filled.Description, false) { vm.screen = Screen.Quotes }
                    SideItem(tr("Lixo"), Icons.Filled.Delete, filter == LibFilter.Trash) { vm.filter = LibFilter.Trash }
                    SideItem(langMenuLabel(), Icons.Filled.Language, false) { langOpen = true }
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
                                if (query.isEmpty()) Text(tr("Pesquisar"), color = Ui.dim, fontSize = 15.sp)
                                inner()
                            },
                            modifier = Modifier.fillMaxWidth(),
                        )
                    }
                    Box {
                        IconButton(onClick = { topMenu = true }) { Icon(Icons.Filled.MoreVert, tr("Menu"), tint = Ui.text) }
                        DropdownMenu(expanded = topMenu, onDismissRequest = { topMenu = false }) {
                            DropdownMenuItem(text = { Text(tr("Editor de móveis")) }, onClick = {
                                topMenu = false; vm.newMoveisProject()
                            })
                            DropdownMenuItem(text = { Text(tr("Agenda")) }, onClick = {
                                topMenu = false; vm.screen = Screen.Agenda
                            })
                            DropdownMenuItem(text = { Text(tr("Orçamentos")) }, onClick = {
                                topMenu = false; vm.screen = Screen.Quotes
                            })
                            DropdownMenuItem(text = { Text(tr("Fazer backup completo (ZIP)")) }, onClick = {
                                topMenu = false; backupLauncher.launch("arque-measure-backup.zip")
                            })
                            DropdownMenuItem(text = { Text(tr("Restaurar backup")) }, onClick = {
                                topMenu = false; restoreLauncher.launch(arrayOf("application/zip", "application/octet-stream"))
                            })
                            if (!br.com.arque.measure.BuildConfig.PLAY) DropdownMenuItem(text = { Text(tr("Atualizar o app (sem perder dados)")) }, onClick = {
                                topMenu = false; vm.checkUpdate()
                            })
                            DropdownMenuItem(text = { Text(tr("Ver projeto por Bluetooth")) }, onClick = {
                                topMenu = false; btView = true
                            })
                            DropdownMenuItem(text = { Text(langMenuLabel() + " (" + currentLangName() + ")") }, onClick = {
                                topMenu = false; langOpen = true
                            })
                            if (br.com.arque.measure.BuildConfig.PLAY) DropdownMenuItem(text = { Text(tr("Gerenciar assinatura")) }, onClick = {
                                topMenu = false; vm.manageStore()
                            })
                            DropdownMenuItem(text = { Text(tr("Guia passo a passo")) }, onClick = {
                                topMenu = false; vm.openGuide()
                            })
                            DropdownMenuItem(text = { Text(tr("Ajuda e suporte")) }, onClick = {
                                topMenu = false; SiteLinks.open(ctxN2, SiteLinks.support())
                            })
                            DropdownMenuItem(text = { Text(tr("Privacidade")) }, onClick = {
                                topMenu = false; SiteLinks.open(ctxN2, SiteLinks.privacy())
                            })
                        }
                    }
                }
                if (!wide) {
                    Row(
                        Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        FilterChip(selected = false, onClick = { vm.screen = Screen.Agenda }, label = { Text(tr("📅 Agenda")) })
                        FilterChip(selected = false, onClick = { vm.newMoveisProject() }, label = { Text(tr("+ Projeto de móveis")) })
                        FilterChip(selected = filter == LibFilter.All, onClick = { vm.filter = LibFilter.All }, label = { Text(tr("Todas as notas")) })
                        vm.index.folders.forEach { f ->
                            FilterChip(selected = filter == LibFilter.InFolder(f.id), onClick = { vm.filter = LibFilter.InFolder(f.id) }, label = { Text(f.name) })
                        }
                        FilterChip(selected = filter == LibFilter.Trash, onClick = { vm.filter = LibFilter.Trash }, label = { Text(tr("Lixo")) })
                        FilterChip(selected = false, onClick = { vm.screen = Screen.Quotes }, label = { Text(tr("Orçamentos")) })
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
                    // um quadro por cliente: notas de um lado, os projetos dele do outro (dá pra ter vários projetos por cliente)
                    val showProj = filter == LibFilter.All && (tab == LibTab.ALL || tab == LibTab.MOVEIS)
                    val groups = if (showProj) clientGroups(vm, projList, if (tab == LibTab.ALL) notes else emptyList()) else emptyList()
                    val q = query.trim()
                    val shown = groups.filter { g -> q.isBlank() || g.matches(q) }
                    val inGroupP = groups.flatMap { g -> g.projs.map { it.id } }.toSet()
                    val inGroupN = groups.flatMap { g -> g.notes.map { it.id } }.toSet()
                    if (tab == LibTab.MOVEIS && filter == LibFilter.All && q.isBlank()) item(key = "novo-proj") { CreateTile(label = tr("Novo projeto de móveis")) { vm.newMoveisProject() } }
                    items(shown, key = { "cli-" + it.key }, span = { GridItemSpan(minOf(2, maxLineSpan)) }) { g -> ClientCard(vm, g) }
                    if (showProj) {
                        val projs = projList.filter { it.id !in inGroupP && (q.isBlank() || projMatches(it, q)) }
                        items(projs, key = { "proj-" + it.id }) { pj -> ProjRow(vm, pj) }
                    }
                    items(notes.filter { it.id !in inGroupN && (q.isBlank() || it.name.contains(q, ignoreCase = true)) }, key = { it.id }) { n -> NoteRow(vm, n) }
                }
            }
        }

        if (filter != LibFilter.Trash) {
            Box(Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(20.dp)) {
                Box(
                    Modifier.size(58.dp).clip(CircleShape).background(Ui.accent).clickable { fabMenu = true },
                    contentAlignment = Alignment.Center,
                ) { Icon(Icons.Filled.Add, tr("Novo"), tint = Color.White, modifier = Modifier.size(30.dp)) }
                DropdownMenu(expanded = fabMenu, onDismissRequest = { fabMenu = false }) {
                    DropdownMenuItem(text = { Text(tr("Criar nota")) }, leadingIcon = { Icon(Icons.Filled.NoteAdd, null) }, onClick = {
                        fabMenu = false; vm.openNote(vm.createNote())
                    })
                    DropdownMenuItem(text = { Text(tr("Anotação infinita (em breve)")) }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text(tr("Importar ficheiros (em breve)")) }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text(tr("Importar imagem")) }, leadingIcon = { Icon(Icons.Filled.Image, null) }, onClick = {
                        fabMenu = false
                        val id = vm.createNote(); vm.pendingImport = "gallery"; vm.openNote(id)
                    })
                    DropdownMenuItem(text = { Text(tr("Tirar fotografia")) }, leadingIcon = { Icon(Icons.Filled.PhotoCamera, null) }, onClick = {
                        fabMenu = false
                        val id = vm.createNote(); vm.pendingImport = "camera"; vm.openNote(id)
                    })
                    DropdownMenuItem(text = { Text(tr("Criar nova pasta")) }, leadingIcon = { Icon(Icons.Filled.CreateNewFolder, null) }, onClick = {
                        fabMenu = false; newFolder = true
                    })
                }
            }
        }
    }

    if (newFolder) NameDialog(tr("Nova pasta"), tr("Nome da pasta"), "", { newFolder = false }) { newFolder = false; vm.addFolder(it) }
    if (btView) ShareViewPicker(vm) { btView = false }
    vm.updateState?.let { msg ->
        androidx.compose.material3.AlertDialog(
            onDismissRequest = { vm.updateState = null },
            title = { Text(tr("Atualizar o app")) },
            text = { Text(msg) },
            confirmButton = {
                if (vm.updateReady != null) androidx.compose.material3.TextButton(onClick = { vm.installUpdate() }) { Text(tr("Instalar")) }
            },
            dismissButton = { androidx.compose.material3.TextButton(onClick = { vm.updateState = null }) { Text(tr("Fechar")) } },
        )
    }
    confirmRestore?.let { uri ->
        ConfirmDialog(
            title = tr("Restaurar backup?"),
            message = tr("Isto substitui os dados atuais (notas, agenda, orçamentos, móveis) pelos do backup. O app reinicia."),
            confirm = tr("Restaurar"),
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
private fun CreateTile(label: String = tr("Criar"), onClick: () -> Unit) {
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
            Text(label, color = Ui.dim, fontSize = 16.sp)
        }
    }
}

@Composable
private fun ProjRow(vm: AppViewModel, p: br.com.arque.measure.data.MoveisProjects.P, mod: Modifier = Modifier.fillMaxWidth(), bare: Boolean = false) {
    var menu by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf(false) }
    var del by remember { mutableStateOf(false) }
    var stDlg by remember { mutableStateOf(false) }
    var titleDlg by remember { mutableStateOf(false) }
    val linked = remember(vm.projVersion, p.id) { vm.notesOfProject(p.id).size }
    Row(
        mod.height(96.dp).clip(RoundedCornerShape(14.dp)).background(if (bare) Color.Transparent else Ui.panel)
            .clickable { vm.openProject(p.id) }.padding(if (bare) 8.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(width = if (bare) 44.dp else 56.dp, height = if (bare) 64.dp else 76.dp).clip(RoundedCornerShape(4.dp)).background(Color(0xFF2B2416)), contentAlignment = Alignment.Center) {
            Text("🪚", fontSize = if (bare) 20.sp else 26.sp)
        }
        Spacer(Modifier.width(if (bare) 8.dp else 12.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(if (bare) p.label else p.name, color = Ui.text, fontSize = if (bare) 14.sp else 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                StatusChip(p.status, Modifier.padding(start = 6.dp).clickable { stDlg = true })
            }
            Text((if (bare) "" else "🪚 " + p.label + " · ") + dateFmt.format(Date(p.updated)), color = Ui.dim, fontSize = 12.sp, maxLines = 1)
            Text(tr(if (p.mods == 1) "{0} módulo" else "{0} módulos", p.mods) + (if (linked > 0 && !bare) tr(if (linked == 1) " · {0} nota" else " · {0} notas", linked) else ""), color = Ui.dim, fontSize = 12.sp, maxLines = 1)
        }
        Box {
            IconButton(onClick = { menu = true }) { Icon(Icons.Filled.KeyboardArrowDown, tr("Menu do projeto"), tint = Ui.text) }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                // projeto, ambiente e a nota do cliente ligada
                Column(Modifier.padding(horizontal = 16.dp, vertical = 6.dp)) {
                    Text(tr("Cliente: {0}", p.name), fontSize = 13.sp, color = Ui.dim)
                    Text(tr("Projeto: {0}", p.label), fontSize = 13.sp, color = Ui.dim)
                    Text(tr("Ambiente: {0}", br.com.arque.measure.data.MoveisProjects.roomLabel(p.room)), fontSize = 13.sp, color = Ui.dim)
                    val nn = remember(vm.projVersion, p.id) { vm.notesOfProject(p.id).mapNotNull { id -> vm.index.notes.firstOrNull { it.id == id && !it.trash }?.name } }
                    Text(if (nn.isEmpty()) tr("Nota: nenhuma ligada") else tr("Nota: {0}", nn.joinToString()), fontSize = 13.sp, color = Ui.dim)
                }
                HorizontalDivider()
                DropdownMenuItem(text = { Text(tr("Abrir")) }, onClick = { menu = false; vm.openProject(p.id) })
                DropdownMenuItem(text = { Text(tr("📝 Abrir a nota do cliente")) }, onClick = { menu = false; vm.openNoteOf(p.id) })
                DropdownMenuItem(text = { Text(tr("Nome do projeto (ex.: Cozinha, Suíte)")) }, onClick = { menu = false; titleDlg = true })
                DropdownMenuItem(text = { Text(tr("＋ Novo projeto deste cliente")) }, onClick = { menu = false; vm.newProjectForClient(p.name, vm.notesOfProject(p.id).firstOrNull()) })
                DropdownMenuItem(text = { Text(tr("Renomear (nome do cliente)")) }, onClick = { menu = false; rename = true })
                DropdownMenuItem(text = { Text(tr("Status do projeto") + ": " + br.com.arque.measure.data.MoveisProjects.statusLabel(p.status)) }, onClick = { menu = false; stDlg = true })
                DropdownMenuItem(text = { Text(tr("Nova nota ligada a este projeto")) }, onClick = { menu = false; vm.lastProjectId = p.id; vm.openNote(vm.createNote()) })
                DropdownMenuItem(text = { Text(tr("Apagar projeto")) }, onClick = { menu = false; del = true })
            }
        }
    }
    if (rename) NameDialog(tr("Nome do projeto"), tr("Cliente / projeto"), if (p.auto) "" else p.name, { rename = false }) { rename = false; vm.renameMoveisProject(p.id, it) }
    if (titleDlg) NameDialog(tr("Nome do projeto (ex.: Cozinha, Suíte)"), tr("Nome do projeto"), p.title, { titleDlg = false }) { titleDlg = false; vm.setProjectTitle(p.id, it) }
    if (stDlg) AlertDialog(
        onDismissRequest = { stDlg = false },
        title = { Text(tr("Status do projeto")) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                br.com.arque.measure.data.MoveisProjects.STATUS.forEach { s ->
                    Row(
                        Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(if (s == p.status) Color(br.com.arque.measure.data.MoveisProjects.statusColor(s)).copy(alpha = 0.15f) else Color.Transparent)
                            .clickable { stDlg = false; vm.setProjectStatus(p.id, s) }.padding(10.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        StatusChip(s)
                        if (s == p.status) Text("  ✓", color = Ui.text)
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = { stDlg = false }) { Text(tr("Fechar")) } },
    )
    if (del) ConfirmDialog(
        title = tr("Apagar este projeto?"), message = tr("\"{0}\" sai da lista de projetos de móveis. Isso não pode ser desfeito.", p.name),
        confirm = tr("Apagar"), onDismiss = { del = false }, onOk = { del = false; vm.deleteMoveisProject(p.id) },
    )
}

/** Etiqueta pequena do status do projeto (orçamento, fechado, produção, finalizado). */
@Composable
private fun StatusChip(status: String, mod: Modifier = Modifier) {
    Text(
        br.com.arque.measure.data.MoveisProjects.statusLabel(status), color = Color.White, fontSize = 10.sp, maxLines = 1,
        modifier = mod.clip(RoundedCornerShape(8.dp)).background(Color(br.com.arque.measure.data.MoveisProjects.statusColor(status))).padding(horizontal = 6.dp, vertical = 1.dp),
    )
}

/** Cliente com suas notas e projetos (nota e projeto ligados ficam com o mesmo nome, no mesmo quadro). */
private class ClientGroup(val key: String, val name: String, val projs: List<br.com.arque.measure.data.MoveisProjects.P>, val notes: List<NoteMeta>) {
    fun matches(q: String): Boolean = name.contains(q, ignoreCase = true) || projs.any { projMatches(it, q) } || notes.any { it.name.contains(q, ignoreCase = true) }
}

/** Busca no projeto: cliente, nome do projeto, ambiente, cidade e status. */
private fun projMatches(p: br.com.arque.measure.data.MoveisProjects.P, q: String): Boolean =
    listOf(p.name, p.label, br.com.arque.measure.data.MoveisProjects.roomLabel(p.room), p.city, br.com.arque.measure.data.MoveisProjects.statusLabel(p.status))
        .any { it.contains(q, ignoreCase = true) }

private fun clientGroups(vm: AppViewModel, projs: List<br.com.arque.measure.data.MoveisProjects.P>, notes: List<NoteMeta>): List<ClientGroup> {
    fun k(s: String) = s.trim().lowercase()
    val pk = HashMap<String, String>()   // projeto -> cliente
    projs.forEach { p -> pk[p.id] = if (vm.isDefaultProj(p)) "id:" + p.id else k(p.name) }
    val byKey = LinkedHashMap<String, Pair<MutableList<br.com.arque.measure.data.MoveisProjects.P>, MutableList<NoteMeta>>>()
    projs.forEach { p -> byKey.getOrPut(pk.getValue(p.id)) { mutableListOf<br.com.arque.measure.data.MoveisProjects.P>() to mutableListOf() }.first.add(p) }
    notes.forEach { n ->
        val key = vm.linkedProject(n.id)?.let { pk[it] } ?: if (vm.isDefaultNote(n.name)) null else k(n.name)
        if (key != null) byKey[key]?.second?.add(n)
    }
    return byKey.mapNotNull { (key, v) ->
        val (ps, ns) = v
        if (ps.isEmpty() || ps.size + ns.size < 2) null
        else ClientGroup(key, ps.firstOrNull { !vm.isDefaultProj(it) }?.name ?: ns.firstOrNull()?.name ?: ps.first().name, ps.sortedByDescending { it.updated }, ns)
    }
}

/** Quadro do cliente: nome em cima, nota(s) à esquerda, os projetos dele à direita e "＋ Novo projeto deste cliente". */
@Composable
private fun ClientCard(vm: AppViewModel, g: ClientGroup) {
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(14.dp)).background(Ui.panel).padding(top = 8.dp)) {
        Row(Modifier.padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
            Text("👤 " + g.name, color = Ui.text, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
            if (g.projs.size > 1) Text("  " + tr("{0} projetos", g.projs.size), color = Ui.dim, fontSize = 12.sp, maxLines = 1)
        }
        Row(Modifier.fillMaxWidth().height(androidx.compose.foundation.layout.IntrinsicSize.Min)) {
            if (g.notes.isNotEmpty()) {
                Column(Modifier.weight(1f)) { g.notes.forEach { n -> NoteRow(vm, n, Modifier.fillMaxWidth(), bare = true) } }
                Box(Modifier.padding(vertical = 10.dp).width(1.dp).fillMaxHeight().background(Ui.line))
            }
            Column(Modifier.weight(1f)) { g.projs.forEach { p -> ProjRow(vm, p, Modifier.fillMaxWidth(), bare = true) } }
        }
        TextButton(onClick = { vm.newProjectForClient(g.name, g.notes.firstOrNull()?.id) }, modifier = Modifier.padding(start = 4.dp)) { Text(tr("＋ Novo projeto deste cliente")) }
    }
}

@Composable
private fun NoteRow(vm: AppViewModel, n: NoteMeta, mod: Modifier = Modifier.fillMaxWidth(), bare: Boolean = false) {
    var menu by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf(false) }
    var move by remember { mutableStateOf(false) }
    val trash = n.trash
    Row(
        mod.height(96.dp).clip(RoundedCornerShape(14.dp)).background(if (bare) Color.Transparent else Ui.panel)
            .clickable(enabled = !trash) { vm.openNote(n.id) }.padding(if (bare) 8.dp else 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        val thumb = androidx.compose.runtime.produceState(vm.cachedThumb(n.id), n.id, vm.thumbVersion, n.pageCount, n.dimCount) {
            value = vm.loadThumbAsync(n.id) ?: value
        }.value
        Box(
            Modifier.size(width = if (bare) 44.dp else 56.dp, height = if (bare) 64.dp else 76.dp).clip(RoundedCornerShape(4.dp)).background(Color.White)
                .border(BorderStroke(1.dp, Ui.line), RoundedCornerShape(4.dp)),
        ) {
            if (thumb != null) {
                androidx.compose.foundation.Image(thumb, null, Modifier.fillMaxSize(), contentScale = androidx.compose.ui.layout.ContentScale.Crop)
            }
        }
        Spacer(Modifier.width(if (bare) 8.dp else 12.dp))
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(n.name, color = Ui.text, fontSize = if (bare) 14.sp else 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                if (n.pinned) Icon(Icons.Filled.PushPin, null, tint = Ui.accent, modifier = Modifier.padding(start = 6.dp).size(14.dp))
                if (n.locked) Icon(Icons.Filled.Lock, null, tint = Ui.dim, modifier = Modifier.padding(start = 6.dp).size(14.dp))
            }
            Text(dateFmt.format(Date(n.createdMs)), color = Ui.dim, fontSize = 12.sp)
            Text(
                tr(if (n.pageCount == 1) "{0} folha" else "{0} folhas", n.pageCount) + " · " + tr(if (n.dimCount == 1) "{0} cota" else "{0} cotas", n.dimCount),
                color = Ui.dim, fontSize = 12.sp, maxLines = 1,
            )
        }
        Box {
            IconButton(onClick = { menu = true }) { Icon(Icons.Filled.KeyboardArrowDown, tr("Menu da nota"), tint = Ui.text) }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                if (trash) {
                    DropdownMenuItem(text = { Text(tr("Restaurar")) }, onClick = { menu = false; vm.trashNote(n.id, false) })
                } else {
                    DropdownMenuItem(text = { Text(tr("🪚 Abrir o projeto deste cliente")) }, onClick = { menu = false; if (!vm.openProjectOfNote(n.id)) vm.newProjectForNote(n.id) })
                    DropdownMenuItem(text = { Text(tr("＋ Novo projeto para este cliente")) }, onClick = { menu = false; vm.newProjectForNote(n.id) })
                    DropdownMenuItem(text = { Text(tr("Editar")) }, onClick = { menu = false; rename = true })
                    DropdownMenuItem(text = { Text(tr("Copiar")) }, onClick = { menu = false; vm.copyNote(n.id) })
                    DropdownMenuItem(
                        text = { Text(if (n.pinned) tr("Desafixar nota") else tr("Fixar nota")) },
                        onClick = { menu = false; vm.pinNote(n.id, !n.pinned) },
                    )
                    DropdownMenuItem(text = { Text(tr("Alterar a capa (em breve)")) }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text(tr("Exportar e partilhar (em breve)")) }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text(tr("Editar etiquetas (em breve)")) }, enabled = false, onClick = {})
                    DropdownMenuItem(text = { Text(tr("Mover para")) }, onClick = { menu = false; move = true })
                    DropdownMenuItem(
                        text = { Text(if (n.locked) tr("Remover bloqueio") else tr("Adicionar bloqueio")) },
                        onClick = { menu = false; vm.lockNote(n.id, !n.locked) },
                    )
                    DropdownMenuItem(text = { Text(tr("Sincronização em nuvem (em breve)")) }, enabled = false, onClick = {})
                    HorizontalDivider()
                    DropdownMenuItem(text = { Text(tr("Mover para o lixo")) }, onClick = { menu = false; vm.trashNote(n.id, true) })
                }
            }
        }
    }
    if (rename) NameDialog(tr("Editar nota"), tr("Nome"), n.name, { rename = false }) { rename = false; vm.renameNote(n.id, it) }
    if (move) {
        AlertDialog(
            onDismissRequest = { move = false },
            title = { Text(tr("Mover para")) },
            text = {
                Column(Modifier.verticalScroll(rememberScrollState())) {
                    TextButton(onClick = { move = false; vm.moveNote(n.id, null) }) { Text(tr("Sem pasta")) }
                    vm.index.folders.forEach { f ->
                        TextButton(onClick = { move = false; vm.moveNote(n.id, f.id) }) { Text(f.name) }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { move = false }) { Text(tr("Cancelar")) } },
        )
    }
}
