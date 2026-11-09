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
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.PhotoCamera
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AttachMoney
import androidx.compose.material.icons.filled.Backup
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.FilterAlt
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Layers
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.Security
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.SystemUpdate
import androidx.compose.material.icons.filled.Timer
import androidx.compose.material.icons.filled.ViewInAr
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
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

/** Abas da tela inicial. */
private enum class HomeTab { CLIENTES, PROJETOS }

/** O que a aba Projetos mostra: tudo, só notas (atalho "Notas") ou só projetos 3D (barra de baixo). */
private enum class ProjMode { ALL, NOTES, PROJ3D }

private const val DAY_MS = 24L * 3600_000L

// ---------------------------------------------------------------- Tela inicial (escura, dourada)

@Composable
fun LibraryScreen(vm: AppViewModel) {
    var query by remember { mutableStateOf("") }
    var tab by remember { mutableStateOf(HomeTab.CLIENTES) }
    var mode by remember { mutableStateOf(ProjMode.ALL) }
    var statusF by remember { mutableStateOf<String?>(null) }
    var statusMenu by remember { mutableStateOf(false) }
    var settingsOpen by remember { mutableStateOf(false) }
    var toolsOpen by remember { mutableStateOf(false) }
    var newClient by remember { mutableStateOf(false) }
    var trialOpen by remember { mutableStateOf(false) }
    var clientKey by remember { mutableStateOf<String?>(null) }
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
    val trash = filter == LibFilter.Trash
    val searching = query.isNotBlank()
    val q = query.trim()
    // quem está numa pasta sai de "Todas as notas" (fica só na pasta); na busca aparece tudo
    val notes = vm.index.notes
        .filter {
            when (filter) {
                LibFilter.All -> !it.trash && (searching || vm.liveFolder(it.folderId) == null)
                LibFilter.Trash -> it.trash
                is LibFilter.InFolder -> !it.trash && it.folderId == filter.id
            }
        }
        .sortedWith(compareByDescending<NoteMeta> { it.pinned }.thenByDescending { it.createdMs })

    // nota e projeto ligados ao mesmo cliente ficam com o mesmo nome
    LaunchedEffect(vm.projVersion, vm.index) { vm.syncLinkedNames() }
    val projAll = remember(vm.projVersion, vm.screen) { vm.moveisProjects() }
    // o projeto fica na mesma pasta que a nota do cliente
    val projFolder = remember(projAll, vm.index) { vm.projectFolders(projAll) }
    val projList = projAll.filter { p ->
        when (filter) {
            LibFilter.All -> searching || projFolder[p.id] == null
            is LibFilter.InFolder -> projFolder[p.id] == filter.id
            LibFilter.Trash -> false
        }
    }
    val folders = vm.index.folders.sortedWith(compareBy<br.com.arque.measure.model.Folder, String>(NameOrder) { it.name })
    val clients = homeClients(vm, projList, notes)

    // o que aparece na lista
    val shownClients = if (trash || tab != HomeTab.CLIENTES) emptyList()
    else clients.filter { c -> (q.isBlank() || c.matches(q)) && (statusF == null || c.latest?.status == statusF) }
    val shownEntries: List<HomeEntry> = when {
        trash -> notes.map { HomeEntry.Nt(it) }
        tab != HomeTab.PROJETOS -> emptyList()
        else -> {
            val ps = if (mode == ProjMode.NOTES) emptyList()
            else projList.filter { (q.isBlank() || projMatches(it, q)) && (statusF == null || it.status == statusF) }
            // nota não tem status: com o filtro de status ligado, só projetos
            val ns = if (mode == ProjMode.PROJ3D || statusF != null) emptyList()
            else notes.filter { q.isBlank() || it.name.contains(q, ignoreCase = true) }
            (ps.map { HomeEntry.Pj(it) } + ns.map { HomeEntry.Nt(it) })
                .sortedWith(compareByDescending<HomeEntry> { it.pinned }.thenByDescending { it.time })
        }
    }
    val showFolders = filter == LibFilter.All && !searching && !trash && folders.isNotEmpty() && (tab == HomeTab.CLIENTES || mode == ProjMode.ALL)

    val showTrial = !br.com.arque.measure.BuildConfig.PLAY && ((!vm.licUnlocked && vm.trialLeft.isNotEmpty()) || vm.payLeft.isNotEmpty())
    val showLicItem = !br.com.arque.measure.BuildConfig.PLAY && (showTrial || vm.licMonthly)
    val now = System.currentTimeMillis()
    // sininho com ponto dourado: tem compromisso nas próximas 24 h
    val bellDot = vm.appointments.any { !it.done && it.startMs >= now && it.startMs <= now + DAY_MS }
    val goHome: () -> Unit = { tab = HomeTab.CLIENTES; mode = ProjMode.ALL; vm.filter = LibFilter.All }
    // voltar (Android) dentro de Projetos / Notas / pasta: volta pro início antes de sair do app
    BackHandler(enabled = tab != HomeTab.CLIENTES || mode != ProjMode.ALL || filter != LibFilter.All) { goHome() }

    BoxWithConstraints(Modifier.fillMaxSize().statusBarsPadding()) {
        val wide = maxWidth >= 700.dp
        Row(Modifier.fillMaxSize()) {
            if (wide) {
                Column(Modifier.width(230.dp).fillMaxHeight().background(Ui.panel).verticalScroll(rememberScrollState()).padding(12.dp)) {
                    Text(tr("Pastas"), color = Ui.dim, fontSize = 12.sp, modifier = Modifier.padding(start = 8.dp, top = 12.dp, bottom = 4.dp))
                    SideItem(tr("Todas as notas"), Icons.Filled.AllInbox, filter == LibFilter.All) { vm.filter = LibFilter.All }
                    folders.forEach { f ->
                        SideItem(f.name, Icons.Filled.Folder, filter == LibFilter.InFolder(f.id)) { vm.filter = LibFilter.InFolder(f.id) }
                    }
                    SideItem(tr("Nova pasta"), Icons.Filled.CreateNewFolder, false) { newFolder = true }
                    Spacer(Modifier.height(12.dp))
                    SideItem(tr("Novo Projetor 3D"), Icons.Filled.ViewInAr, false) { vm.newMoveisProject() }
                    SideItem(tr("Agenda"), Icons.Filled.Event, false) { vm.screen = Screen.Agenda }
                    SideItem(tr("Orçamentos"), Icons.Filled.Description, false) { vm.screen = Screen.Quotes }
                    SideItem(tr("Lixo"), Icons.Filled.Delete, filter == LibFilter.Trash) { vm.filter = LibFilter.Trash }
                    SideItem(langMenuLabel(), Icons.Filled.Language, false) { langOpen = true }
                }
            }
            Column(Modifier.weight(1f).fillMaxHeight()) {
                HomeHeader(bellDot, onBell = { vm.screen = Screen.Agenda }, onProfile = { settingsOpen = true })
                HomeSegments(tab) { t -> tab = t; mode = ProjMode.ALL }
                // busca + filtro por status
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Row(
                        Modifier.weight(1f).height(48.dp).clip(RoundedCornerShape(14.dp)).background(Ui.panel)
                            .border(1.dp, Ui.line, RoundedCornerShape(14.dp)).padding(horizontal = 14.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(Icons.Filled.Search, null, tint = Ui.dim, modifier = Modifier.size(20.dp))
                        Spacer(Modifier.width(10.dp))
                        androidx.compose.foundation.text.BasicTextField(
                            value = query, onValueChange = { query = it }, singleLine = true,
                            textStyle = androidx.compose.ui.text.TextStyle(color = Ui.text, fontSize = 15.sp),
                            cursorBrush = androidx.compose.ui.graphics.SolidColor(Color.White),
                            decorationBox = { inner ->
                                if (query.isEmpty()) Text(
                                    if (tab == HomeTab.CLIENTES) tr("Buscar cliente...") else tr("Buscar projeto..."),
                                    color = Ui.dim, fontSize = 15.sp, maxLines = 1,
                                )
                                inner()
                            },
                            modifier = Modifier.weight(1f),
                        )
                        if (query.isNotEmpty()) Icon(
                            Icons.Filled.Close, tr("Limpar"), tint = Ui.dim,
                            modifier = Modifier.size(20.dp).clip(CircleShape).clickable { query = "" },
                        )
                    }
                    Spacer(Modifier.width(10.dp))
                    Box {
                        val on = statusF != null
                        Box(
                            Modifier.size(48.dp).clip(RoundedCornerShape(14.dp)).background(if (on) Color.White.copy(alpha = 0.18f) else Ui.panel)
                                .border(1.dp, if (on) Color.White else Ui.line, RoundedCornerShape(14.dp)).clickable { statusMenu = true },
                            contentAlignment = Alignment.Center,
                        ) { Icon(Icons.Filled.FilterAlt, tr("Filtrar por status"), tint = if (on) Color.White else Ui.text, modifier = Modifier.size(22.dp)) }
                        DropdownMenu(expanded = statusMenu, onDismissRequest = { statusMenu = false }) {
                            DropdownMenuItem(
                                text = { Text(tr("Todos")) },
                                trailingIcon = { if (statusF == null) Icon(Icons.Filled.Check, null, tint = Color.White) },
                                onClick = { statusMenu = false; statusF = null },
                            )
                            br.com.arque.measure.data.MoveisProjects.STATUS.forEach { s ->
                                DropdownMenuItem(
                                    text = { StatusChip(s) },
                                    trailingIcon = { if (statusF == s) Icon(Icons.Filled.Check, null, tint = Color.White) },
                                    onClick = { statusMenu = false; statusF = s },
                                )
                            }
                        }
                    }
                }
                // pasta / lixo aberto: etiqueta pra voltar pra tudo
                if (filter != LibFilter.All) {
                    val fname = when (filter) {
                        LibFilter.Trash -> tr("Lixo")
                        is LibFilter.InFolder -> folders.firstOrNull { it.id == filter.id }?.name ?: tr("Pasta")
                        LibFilter.All -> ""
                    }
                    Row(
                        Modifier.padding(horizontal = 16.dp, vertical = 2.dp).clip(RoundedCornerShape(50)).background(Color.White.copy(alpha = 0.15f))
                            .clickable { vm.filter = LibFilter.All }.padding(horizontal = 12.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Icon(if (trash) Icons.Filled.Delete else Icons.Filled.Folder, null, tint = Color.White, modifier = Modifier.size(16.dp))
                        Spacer(Modifier.width(6.dp))
                        Text(fname, color = Ui.text, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                        Spacer(Modifier.width(6.dp))
                        Icon(Icons.Filled.Close, tr("Voltar para tudo"), tint = Ui.dim, modifier = Modifier.size(16.dp))
                    }
                }
                LazyVerticalGrid(
                    columns = GridCells.Adaptive(340.dp),
                    modifier = Modifier.weight(1f).fillMaxWidth(),
                    contentPadding = PaddingValues(16.dp, 6.dp, 16.dp, 12.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    if (!trash) {
                        when {
                            tab == HomeTab.PROJETOS && mode == ProjMode.NOTES -> item(key = "acoes-nota", span = { GridItemSpan(maxLineSpan) }) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    SmallAction(tr("Nova nota"), Icons.Filled.Add, true, Modifier.weight(1.2f)) { vm.noteAsk = AppViewModel.NoteAsk("") }
                                    SmallAction(tr("Importar imagem"), Icons.Filled.Image, false, Modifier.weight(1.4f)) { vm.noteAsk = AppViewModel.NoteAsk("gallery") }
                                    SmallAction(tr("Foto"), Icons.Filled.PhotoCamera, false, Modifier.weight(1f)) { vm.noteAsk = AppViewModel.NoteAsk("camera") }
                                }
                            }
                            tab == HomeTab.PROJETOS && mode == ProjMode.PROJ3D -> item(key = "novo-3d", span = { GridItemSpan(maxLineSpan) }) {
                                GoldButton(tr("Novo Projetor 3D")) { vm.newMoveisProject() }
                            }
                            else -> item(key = "novo-cliente", span = { GridItemSpan(maxLineSpan) }) {
                                GoldButton(tr("Novo cliente")) { newClient = true }
                            }
                        }
                    }
                    // as pastas aparecem em cima, com quantos itens têm (o que entrou numa pasta sai daqui)
                    if (showFolders) {
                        folders.forEach { f ->
                            val cnt = vm.index.notes.count { !it.trash && it.folderId == f.id } + projFolder.values.count { it == f.id }
                            item(key = "pasta-" + f.id) { FolderTile(f.name, cnt) { vm.filter = LibFilter.InFolder(f.id) } }
                        }
                    }
                    items(shownClients, key = { "cli-" + it.key }) { c -> HomeClientCard(c) { clientKey = c.key } }
                    items(shownEntries, key = { it.key }) { e ->
                        when (e) {
                            is HomeEntry.Pj -> ProjRow(vm, e.p)
                            is HomeEntry.Nt -> NoteRow(vm, e.n)
                        }
                    }
                    if (shownClients.isEmpty() && shownEntries.isEmpty()) {
                        item(key = "vazio", span = { GridItemSpan(maxLineSpan) }) {
                            Text(
                                when {
                                    searching || statusF != null -> tr("Nada encontrado.")
                                    trash -> tr("O lixo está vazio.")
                                    tab == HomeTab.CLIENTES -> tr("Nenhum cliente ainda. Toque em \"Novo cliente\".")
                                    else -> tr("Nada por aqui ainda.")
                                },
                                color = Ui.dim, fontSize = 14.sp, modifier = Modifier.fillMaxWidth().padding(vertical = 24.dp), textAlign = TextAlign.Center,
                            )
                        }
                    }
                }
                HomeShortcuts(
                    onProj = { vm.newMoveisProject() },
                    onNotes = { tab = HomeTab.PROJETOS; mode = ProjMode.NOTES; statusF = null; if (trash) vm.filter = LibFilter.All },
                    onQuotes = { vm.screen = Screen.Quotes },
                )
                if (showTrial) TrialBar(if (vm.payLeft.isNotEmpty()) tr("Mensalidade · vence em {0}", vm.payLeft) else tr("Teste grátis · falta {0}", vm.trialLeft)) { trialOpen = true }
                HomeBottomNav(
                    selected = if (tab == HomeTab.PROJETOS && mode == ProjMode.PROJ3D) 1 else 0,
                    onHome = goHome,
                    onProj = { tab = HomeTab.PROJETOS; mode = ProjMode.PROJ3D; if (trash) vm.filter = LibFilter.All },
                    onTools = { toolsOpen = true },
                    onSettings = { settingsOpen = true },
                )
            }
        }
    }

    // ---- cliente aberto: projetos 3D e notas dele
    val openClient = clientKey?.let { k -> clients.firstOrNull { it.key == k } }
    if (openClient != null) ClientDetail(vm, openClient) { clientKey = null }

    // ---- Ajustes (tudo o que ficava no menu "⋮")
    if (settingsOpen) HomeSheet(tr("Ajustes"), { settingsOpen = false }, buildList {
        add(SheetItem(tr("Projetor 3D"), Icons.Filled.ViewInAr) { vm.newMoveisProject() })
        add(SheetItem(tr("Agenda"), Icons.Filled.Event) { vm.screen = Screen.Agenda })
        add(SheetItem(tr("Orçamentos"), Icons.Filled.AttachMoney) { vm.screen = Screen.Quotes })
        add(SheetItem(tr("Fazer backup completo (ZIP)"), Icons.Filled.Backup) { backupLauncher.launch("arque-measure-backup.zip") })
        add(SheetItem(tr("Restaurar backup"), Icons.Filled.Restore) { restoreLauncher.launch(arrayOf("application/zip", "application/octet-stream")) })
        if (!br.com.arque.measure.BuildConfig.PLAY) add(SheetItem(tr("Atualizar o app (sem perder dados)"), Icons.Filled.SystemUpdate) { vm.checkUpdate() })
        add(SheetItem(tr("Ver projeto por Bluetooth"), Icons.Filled.Bluetooth) { btView = true })
        add(SheetItem(langMenuLabel() + " (" + currentLangName() + ")", Icons.Filled.Language) { langOpen = true })
        if (showLicItem) add(SheetItem(tr("Licença / senha do mês"), Icons.Filled.Lock) { trialOpen = true })
        if (br.com.arque.measure.BuildConfig.PLAY) add(SheetItem(tr("Gerenciar assinatura"), Icons.Filled.ShoppingCart) { vm.manageStore() })
        add(SheetItem(tr("Guia passo a passo"), Icons.Filled.Info) { vm.openGuide() })
        add(SheetItem(tr("Ajuda e suporte"), Icons.Filled.Email) { SiteLinks.open(ctxN2, SiteLinks.support()) })
        add(SheetItem(tr("Privacidade"), Icons.Filled.Security) { SiteLinks.open(ctxN2, SiteLinks.privacy()) })
    })

    // ---- Ferramentas: agenda, orçamentos, bluetooth, pastas e lixo
    if (toolsOpen) HomeSheet(tr("Ferramentas"), { toolsOpen = false }, buildList {
        add(SheetItem(tr("Agenda"), Icons.Filled.Event) { vm.screen = Screen.Agenda })
        add(SheetItem(tr("Orçamentos"), Icons.Filled.AttachMoney) { vm.screen = Screen.Quotes })
        add(SheetItem(tr("Ver projeto por Bluetooth"), Icons.Filled.Bluetooth) { btView = true })
        add(SheetItem(tr("Todas as notas"), Icons.Filled.AllInbox, filter == LibFilter.All) { vm.filter = LibFilter.All })
        folders.forEach { f -> add(SheetItem(f.name, Icons.Filled.Folder, filter == LibFilter.InFolder(f.id)) { vm.filter = LibFilter.InFolder(f.id) }) }
        add(SheetItem(tr("Nova pasta"), Icons.Filled.CreateNewFolder) { newFolder = true })
        add(SheetItem(tr("Lixo"), Icons.Filled.Delete, trash) { vm.filter = LibFilter.Trash })
    })

    if (trialOpen) TrialDialog(vm) { trialOpen = false }
    if (newClient) NameDialog(tr("Novo cliente"), tr("Nome do cliente"), "", { newClient = false }) { name ->
        newClient = false
        vm.newProjectForClient(name, null)
    }
    if (newFolder) NameDialog(tr("Nova pasta"), tr("Nome da pasta"), "", { newFolder = false }) { newFolder = false; vm.addFolder(it) }
    // nota nova: pergunta o nome antes de criar (cada nota com o seu nome)
    vm.noteAsk?.let { a ->
        NameDialog(tr("Nova nota"), tr("Nome da nota"), vm.suggestedNoteName(a.project), { vm.noteAsk = null }) { name ->
            vm.noteAsk = null
            val id = vm.createNamedNote(name, a.project)
            if (a.kind.isNotEmpty()) vm.pendingImport = a.kind
            vm.openNote(id)
        }
    }
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

/** Topo: quadrado dourado com "A", ARQUEMESTRE, sininho da agenda e o perfil (ajustes). */
@Composable
private fun HomeHeader(bellDot: Boolean, onBell: () -> Unit, onProfile: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        androidx.compose.foundation.Image(painter = androidx.compose.ui.res.painterResource("logo_arque.png"), contentDescription = "Arquemestre",
            modifier = Modifier.size(48.dp).clip(RoundedCornerShape(12.dp)), contentScale = androidx.compose.ui.layout.ContentScale.Crop)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text("ARQUEMESTRE", color = Ui.text, fontSize = 19.sp, fontWeight = FontWeight.Bold, letterSpacing = 1.sp, maxLines = 1)
            Text(tr("Gestão de Projetos para Marcenaria"), color = Ui.dim, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        RoundIconButton(Icons.Outlined.Notifications, tr("Agenda"), dot = bellDot, onClick = onBell)
        Spacer(Modifier.width(8.dp))
        RoundIconButton(Icons.Filled.Person, tr("Ajustes"), onClick = onProfile)
    }
}

@Composable
private fun RoundIconButton(icon: ImageVector, desc: String, dot: Boolean = false, onClick: () -> Unit) {
    Box(
        Modifier.size(44.dp).clip(CircleShape).background(Ui.panel).border(1.dp, Ui.line, CircleShape).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, desc, tint = Ui.text, modifier = Modifier.size(22.dp))
        if (dot) Box(
            Modifier.align(Alignment.TopEnd).padding(top = 9.dp, end = 10.dp).size(10.dp).clip(CircleShape).background(Color.White)
                .border(2.dp, Ui.panel, CircleShape),
        )
    }
}

/** Clientes | Projetos: a escolhida fica dourada, com um filete dourado embaixo. */
@Composable
private fun HomeSegments(tab: HomeTab, onTab: (HomeTab) -> Unit) {
    Column(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp)) {
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Ui.panel).padding(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp),
        ) {
            SegPill(tr("Clientes"), Icons.Filled.Person, tab == HomeTab.CLIENTES, Modifier.weight(1f)) { onTab(HomeTab.CLIENTES) }
            SegPill(tr("Projetos"), Icons.Filled.Layers, tab == HomeTab.PROJETOS, Modifier.weight(1f)) { onTab(HomeTab.PROJETOS) }
        }
        Box(Modifier.padding(top = 8.dp).fillMaxWidth().height(1.dp).background(Color.White.copy(alpha = 0.55f)))
    }
}

@Composable
private fun SegPill(label: String, icon: ImageVector, selected: Boolean, mod: Modifier, onClick: () -> Unit) {
    Row(
        mod.height(46.dp).clip(RoundedCornerShape(12.dp)).background(if (selected) Color.White else Color.Transparent).clickable(onClick = onClick),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (selected) Ui.bg else Ui.dim, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, color = if (selected) Ui.bg else Ui.text, fontSize = 16.sp, fontWeight = FontWeight.SemiBold, maxLines = 1)
    }
}

/** Botão dourado de largura total ("+ Novo cliente", "+ Novo Projetor 3D"…). */
@Composable
private fun GoldButton(label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(14.dp)).background(Color.White).clickable(onClick = onClick),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Add, null, tint = Ui.bg, modifier = Modifier.size(22.dp))
        Spacer(Modifier.width(6.dp))
        Text(label, color = Ui.bg, fontSize = 16.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/** Botão menor (dourado ou escuro) das ações de nota e do cliente. */
@Composable
private fun SmallAction(label: String, icon: ImageVector, gold: Boolean, mod: Modifier, onClick: () -> Unit) {
    Row(
        mod.height(48.dp).clip(RoundedCornerShape(14.dp)).background(if (gold) Color.White else Ui.panel)
            .border(1.dp, if (gold) Color.White else Ui.line, RoundedCornerShape(14.dp)).clickable(onClick = onClick).padding(horizontal = 8.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (gold) Ui.bg else Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(6.dp))
        Text(label, color = if (gold) Ui.bg else Ui.text, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/** Cliente: os projetos 3D com o mesmo nome de cliente e as notas ligadas a eles. */
private class HomeClient(val key: String, val name: String, val projs: List<br.com.arque.measure.data.MoveisProjects.P>, val notes: List<NoteMeta>) {
    /** Projeto 3D mais recente (o status dele aparece no cartão). */
    val latest: br.com.arque.measure.data.MoveisProjects.P? = projs.maxByOrNull { it.updated }
    val updated: Long = maxOf(latest?.updated ?: 0L, notes.maxOfOrNull { it.createdMs } ?: 0L)
    fun matches(q: String): Boolean = name.contains(q, ignoreCase = true) || projs.any { projMatches(it, q) } || notes.any { it.name.contains(q, ignoreCase = true) }
}

/** Item da aba Projetos: projeto 3D ou nota (mais recente primeiro; notas fixadas em cima). */
private sealed class HomeEntry(val key: String, val time: Long, val pinned: Boolean) {
    class Pj(val p: br.com.arque.measure.data.MoveisProjects.P) : HomeEntry("proj-" + p.id, p.updated, false)
    class Nt(val n: NoteMeta) : HomeEntry(n.id, n.createdMs, n.pinned)
}

/** Agrupa os projetos 3D por cliente (projeto sem nome de cliente fica só na aba Projetos). */
private fun homeClients(vm: AppViewModel, projs: List<br.com.arque.measure.data.MoveisProjects.P>, notes: List<NoteMeta>): List<HomeClient> {
    fun k(s: String) = s.trim().lowercase()
    val pk = HashMap<String, String>()   // projeto -> cliente
    projs.forEach { p -> if (p.name.isNotBlank() && !vm.isDefaultProj(p)) pk[p.id] = if (soloProj(p)) "id:" + p.id else k(p.name) }
    val byKey = LinkedHashMap<String, Pair<MutableList<br.com.arque.measure.data.MoveisProjects.P>, MutableList<NoteMeta>>>()
    projs.forEach { p -> pk[p.id]?.let { key -> byKey.getOrPut(key) { mutableListOf<br.com.arque.measure.data.MoveisProjects.P>() to mutableListOf() }.first.add(p) } }
    notes.forEach { n ->
        if (n.trash) return@forEach
        val key = vm.linkedProject(n.id)?.let { pk[it] } ?: if (vm.isDefaultNote(n.name)) null else k(n.name)
        if (key != null) byKey[key]?.second?.add(n)
    }
    return byKey.map { (key, v) ->
        val (ps, ns) = v
        HomeClient(key, ps.first().name, ps.sortedByDescending { it.updated }, ns.sortedByDescending { it.createdMs })
    }.sortedByDescending { it.updated }
}

@Composable
private fun ClientAvatar(name: String, size: Int = 48) {
    Box(
        Modifier.size(size.dp).clip(RoundedCornerShape((size / 4).dp)).background(Color(0xFF2A2E35))
            .border(1.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape((size / 4).dp)),
        contentAlignment = Alignment.Center,
    ) {
        Text(name.trim().firstOrNull()?.uppercaseChar()?.toString() ?: "?", color = Color.White, fontSize = (size * 0.46f).sp, fontWeight = FontWeight.Bold)
    }
}

/** Cartão do cliente: inicial, nome, quantos projetos, data e o status do projeto mais recente. */
@Composable
private fun HomeClientCard(c: HomeClient, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Ui.panel).border(1.dp, Ui.line, RoundedCornerShape(16.dp))
            .clickable(onClick = onClick).padding(12.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        ClientAvatar(c.name)
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(c.name, color = Ui.text, fontSize = 16.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(tr(if (c.projs.size == 1) "{0} projeto" else "{0} projetos", c.projs.size), color = Ui.dim, fontSize = 13.sp, maxLines = 1)
            Row(Modifier.padding(top = 3.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(dateFmt.format(Date(c.updated)), color = Ui.dim, fontSize = 12.sp, maxLines = 1)
                c.latest?.let { StatusChip(it.status, Modifier.padding(start = 8.dp)) }
            }
            c.latest?.let { p -> deliveryInfo(p) }?.let { (t, late) ->
                Text(t, color = if (late) Color(0xFFE53935) else Ui.dim, fontSize = 12.sp, maxLines = 1, fontWeight = if (late) FontWeight.Bold else FontWeight.Normal)
            }
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Ui.dim)
    }
}

/** Cliente aberto (tela cheia): os projetos 3D dele e as notas ligadas. */
@Composable
private fun ClientDetail(vm: AppViewModel, c: HomeClient, onClose: () -> Unit) {
    Dialog(onDismissRequest = onClose, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Surface(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding(), color = Ui.bg) {
            Column(Modifier.fillMaxSize()) {
                Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
                    IconButton(onClick = onClose) { Icon(Icons.AutoMirrored.Filled.ArrowBack, tr("Fechar"), tint = Ui.text) }
                    ClientAvatar(c.name, 40)
                    Spacer(Modifier.width(12.dp))
                    Column(Modifier.weight(1f)) {
                        Text(c.name, color = Ui.text, fontSize = 18.sp, fontWeight = FontWeight.Bold, maxLines = 1, overflow = TextOverflow.Ellipsis)
                        Text(
                            tr(if (c.projs.size == 1) "{0} projeto" else "{0} projetos", c.projs.size) +
                                tr(if (c.notes.size == 1) " · {0} nota" else " · {0} notas", c.notes.size),
                            color = Ui.dim, fontSize = 13.sp, maxLines = 1,
                        )
                    }
                }
                LazyColumn(
                    Modifier.weight(1f).fillMaxWidth(),
                    contentPadding = PaddingValues(16.dp, 4.dp, 16.dp, 16.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    item(key = "t-proj") { SectionTitle(tr("Projetor 3D"), Icons.Filled.ViewInAr) }
                    items(c.projs, key = { "p-" + it.id }) { p -> ProjRow(vm, p) }
                    item(key = "novo-proj") {
                        GoldButton(tr("Projetor 3D deste cliente")) { onClose(); vm.newProjectForClient(c.name, c.notes.firstOrNull()?.id) }
                    }
                    item(key = "t-notas") { SectionTitle(tr("Notas"), Icons.Filled.Edit) }
                    if (c.notes.isEmpty()) item(key = "sem-nota") { Text(tr("Nenhuma nota ligada a este cliente."), color = Ui.dim, fontSize = 13.sp) }
                    items(c.notes, key = { "n-" + it.id }) { n -> NoteRow(vm, n) }
                    item(key = "nova-nota") {
                        SmallAction(tr("Nota"), Icons.Filled.Add, false, Modifier.fillMaxWidth()) {
                            onClose(); vm.noteAsk = AppViewModel.NoteAsk("", c.latest?.id)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionTitle(label: String, icon: ImageVector) {
    Row(Modifier.fillMaxWidth().padding(top = 8.dp, bottom = 2.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, color = Ui.text, fontSize = 15.sp, fontWeight = FontWeight.Bold)
    }
}

/** Três atalhos escuros: Projetor 3D, Notas e Orçamentos. */
@Composable
private fun HomeShortcuts(onProj: () -> Unit, onNotes: () -> Unit, onQuotes: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        ShortcutCard(tr("Projetor 3D"), Icons.Filled.ViewInAr, Modifier.weight(1f), onProj)
        ShortcutCard(tr("Notas"), Icons.Filled.Edit, Modifier.weight(1f), onNotes)
        ShortcutCard(tr("Orçamentos"), Icons.Filled.AttachMoney, Modifier.weight(1f), onQuotes)
    }
}

@Composable
private fun ShortcutCard(label: String, icon: ImageVector, mod: Modifier, onClick: () -> Unit) {
    Column(
        mod.height(76.dp).clip(RoundedCornerShape(14.dp)).background(Ui.panel).border(1.dp, Ui.line, RoundedCornerShape(14.dp))
            .clickable(onClick = onClick).padding(6.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Box(Modifier.size(34.dp).clip(CircleShape).background(Color(0xFF2A2E35)), contentAlignment = Alignment.Center) {
            Icon(icon, null, tint = Color.White, modifier = Modifier.size(20.dp))
        }
        Spacer(Modifier.height(5.dp))
        Text(label, color = Ui.text, fontSize = 13.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

/** Barra "⏱ Teste grátis · falta X" (abre a licença / senha). */
@Composable
private fun TrialBar(label: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp).clip(RoundedCornerShape(14.dp))
            .border(1.dp, Color.White, RoundedCornerShape(14.dp)).clickable(onClick = onClick).padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Timer, null, tint = Color.White, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(8.dp))
        Text(label, color = Color.White, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Color.White)
    }
}

/** Barra de baixo: Início, Projetor 3D, Ferramentas e Ajustes. */
@Composable
private fun HomeBottomNav(selected: Int, onHome: () -> Unit, onProj: () -> Unit, onTools: () -> Unit, onSettings: () -> Unit) {
    Column(Modifier.fillMaxWidth().padding(top = 6.dp).background(Ui.panel)) {
        Box(Modifier.fillMaxWidth().height(1.dp).background(Ui.line))
        Row(Modifier.fillMaxWidth().navigationBarsPadding().height(64.dp)) {
            NavItem(tr("Início"), Icons.Filled.Home, selected == 0, Modifier.weight(1f), onHome)
            NavItem(tr("Projetor 3D"), Icons.Filled.ViewInAr, selected == 1, Modifier.weight(1f), onProj)
            NavItem(tr("Ferramentas"), Icons.Filled.Build, false, Modifier.weight(1f), onTools)
            NavItem(tr("Ajustes"), Icons.Filled.Settings, false, Modifier.weight(1f), onSettings)
        }
    }
}

@Composable
private fun NavItem(label: String, icon: ImageVector, selected: Boolean, mod: Modifier, onClick: () -> Unit) {
    Column(
        mod.fillMaxHeight().clickable(onClick = onClick),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(icon, label, tint = if (selected) Color.White else Ui.dim, modifier = Modifier.size(24.dp))
        Text(label, color = if (selected) Color.White else Ui.dim, fontSize = 11.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
        Box(Modifier.padding(top = 3.dp).size(width = 22.dp, height = 3.dp).clip(RoundedCornerShape(2.dp)).background(if (selected) Color.White else Color.Transparent))
    }
}

/** Item de folha (Ajustes / Ferramentas): ao tocar fecha a folha e faz a ação. */
private class SheetItem(val label: String, val icon: ImageVector, val selected: Boolean = false, val onClick: () -> Unit)

/** Folha que sobe de baixo, com a lista de itens. */
@Composable
private fun HomeSheet(title: String, onDismiss: () -> Unit, items: List<SheetItem>) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(
            Modifier.fillMaxSize().clickable(interactionSource = remember { MutableInteractionSource() }, indication = null, onClick = onDismiss),
            contentAlignment = Alignment.BottomCenter,
        ) {
            Column(
                Modifier.widthIn(max = 560.dp).fillMaxWidth().heightIn(max = 620.dp)
                    .clip(RoundedCornerShape(topStart = 22.dp, topEnd = 22.dp)).background(Ui.panel)
                    .clickable(interactionSource = remember { MutableInteractionSource() }, indication = null) { }
                    .navigationBarsPadding().padding(bottom = 10.dp),
            ) {
                Box(Modifier.padding(top = 10.dp).align(Alignment.CenterHorizontally).size(width = 40.dp, height = 4.dp).clip(RoundedCornerShape(2.dp)).background(Ui.line))
                Row(Modifier.fillMaxWidth().padding(start = 20.dp, end = 8.dp, top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                    Text(title, color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
                    IconButton(onClick = onDismiss) { Icon(Icons.Filled.Close, tr("Fechar"), tint = Ui.dim) }
                }
                Column(Modifier.verticalScroll(rememberScrollState()).padding(horizontal = 10.dp)) {
                    items.forEach { it2 ->
                        Row(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(if (it2.selected) Ui.panel2 else Color.Transparent)
                                .clickable { onDismiss(); it2.onClick() }.padding(horizontal = 12.dp, vertical = 13.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(it2.icon, null, tint = if (it2.selected) Color.White else Ui.dim, modifier = Modifier.size(22.dp))
                            Spacer(Modifier.width(14.dp))
                            Text(it2.label, color = Ui.text, fontSize = 15.sp, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f))
                            if (it2.selected) Icon(Icons.Filled.Check, null, tint = Color.White, modifier = Modifier.size(18.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SideItem(label: String, icon: ImageVector, selected: Boolean, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(if (selected) Ui.panel2 else Color.Transparent)
            .clickable(onClick = onClick).padding(horizontal = 10.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = if (selected) Color.White else Ui.dim, modifier = Modifier.size(18.dp))
        Spacer(Modifier.width(10.dp))
        Text(label, color = Ui.text, fontSize = 14.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
    }
}

@Composable
private fun ProjRow(vm: AppViewModel, p: br.com.arque.measure.data.MoveisProjects.P, mod: Modifier = Modifier.fillMaxWidth(), bare: Boolean = false) {
    var menu by remember { mutableStateOf(false) }
    var rename by remember { mutableStateOf(false) }
    var del by remember { mutableStateOf(false) }
    var stDlg by remember { mutableStateOf(false) }
    var titleDlg by remember { mutableStateOf(false) }
    var move by remember { mutableStateOf(false) }
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
            Text(
                if (p.corte) tr("✂ Plano de corte recebido") + (if (p.from.isNotEmpty()) " · " + p.from else "")
                else (if (bare) "" else "🪚 " + p.label + " · ") + dateFmt.format(Date(p.updated)),
                color = if (p.corte) Color(0xFF2F6BE0) else Ui.dim, fontSize = 12.sp, maxLines = 1,
            )
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
                DropdownMenuItem(text = { Text(tr("Nova nota ligada a este projeto")) }, onClick = { menu = false; vm.noteAsk = AppViewModel.NoteAsk("", p.id) })
                DropdownMenuItem(text = { Text(tr("📁 Mover para pasta (vai junto com a nota)")) }, onClick = { menu = false; move = true })
                DropdownMenuItem(text = { Text(tr("Apagar projeto")) }, onClick = { menu = false; del = true })
            }
        }
    }
    if (rename) NameDialog(tr("Nome do projeto"), tr("Cliente / projeto"), if (p.auto) "" else p.name, { rename = false }) { rename = false; vm.renameMoveisProject(p.id, it) }
    if (titleDlg) NameDialog(tr("Nome do projeto (ex.: Cozinha, Suíte)"), tr("Nome do projeto"), p.title, { titleDlg = false }) { titleDlg = false; vm.setProjectTitle(p.id, it) }
    if (move) FolderPicker(vm, { move = false }) { f -> move = false; vm.moveClient(null, p.id, f) }
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
/** Ordem alfabética do jeito que a gente lê: sem diferença de maiúscula/acento e com número na ordem certa (Nota 2 antes de Nota 10). */
internal object NameOrder : Comparator<String> {
    private val col = java.text.Collator.getInstance(Locale("pt", "BR")).apply { strength = java.text.Collator.PRIMARY }
    private val part = Regex("\\d+|\\D+")
    override fun compare(a: String, b: String): Int {
        val x = part.findAll(a.trim()).map { it.value }.toList()
        val y = part.findAll(b.trim()).map { it.value }.toList()
        for (i in 0 until minOf(x.size, y.size)) {
            val p = x[i]; val q = y[i]
            val c = if (p[0].isDigit() && q[0].isDigit()) p.trimStart('0').length.compareTo(q.trimStart('0').length).let { if (it != 0) it else p.trimStart('0').compareTo(q.trimStart('0')) }
            else synchronized(col) { col.compare(p, q) }
            if (c != 0) return c
        }
        return x.size.compareTo(y.size)
    }
}

/** Busca no projeto: cliente, nome do projeto, ambiente, cidade e status. */
private fun projMatches(p: br.com.arque.measure.data.MoveisProjects.P, q: String): Boolean =
    listOf(p.name, p.label, br.com.arque.measure.data.MoveisProjects.roomLabel(p.room), p.city, br.com.arque.measure.data.MoveisProjects.statusLabel(p.status))
        .any { it.contains(q, ignoreCase = true) }

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
    if (move) FolderPicker(vm, { move = false }) { f -> move = false; vm.moveClient(n.id, null, f) }
}

/** Escolher a pasta: o cliente vai inteiro (nota e projetos) e sai de onde estava. */
@Composable
private fun FolderPicker(vm: AppViewModel, onDismiss: () -> Unit, onPick: (String?) -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tr("Mover para")) },
        text = {
            Column(Modifier.verticalScroll(rememberScrollState())) {
                Text(tr("A nota e o projeto do cliente vão juntos."), color = Ui.dim, fontSize = 13.sp, modifier = Modifier.padding(bottom = 4.dp))
                TextButton(onClick = { onPick(null) }) { Text(tr("Sem pasta")) }
                vm.index.folders.sortedWith(compareBy<br.com.arque.measure.model.Folder, String>(NameOrder) { it.name }).forEach { f ->
                    TextButton(onClick = { onPick(f.id) }) { Text("📁 " + f.name) }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text(tr("Cancelar")) } },
    )
}

/** Pasta na tela "Todas as notas": toque abre a pasta. */
@Composable
private fun FolderTile(name: String, count: Int, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(64.dp).clip(RoundedCornerShape(14.dp)).background(Ui.panel).clickable(onClick = onClick).padding(horizontal = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(Icons.Filled.Folder, null, tint = Ui.accent, modifier = Modifier.size(26.dp))
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(name, color = Ui.text, fontSize = 16.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(tr(if (count == 1) "{0} item" else "{0} itens", count), color = Ui.dim, fontSize = 12.sp)
        }
        Icon(Icons.AutoMirrored.Filled.KeyboardArrowRight, null, tint = Ui.dim)
    }
}

/** Prazo de entrega do projeto: a versão Windows ainda não tem o campo de entrega. */
@Suppress("UNUSED_PARAMETER")
private fun deliveryInfo(p: br.com.arque.measure.data.MoveisProjects.P): Pair<String, Boolean>? = null

/** Projeto que fica sozinho (não junta com outros do mesmo nome): plano de corte recebido. */
private fun soloProj(p: br.com.arque.measure.data.MoveisProjects.P): Boolean = p.corte
