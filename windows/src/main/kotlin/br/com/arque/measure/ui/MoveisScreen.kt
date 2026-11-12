package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.awt.SwingPanel
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.desktop.Browser
import br.com.arque.measure.desktop.DesktopActions
import br.com.arque.measure.i18n.I18n
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import javax.swing.JPanel
import javax.swing.SwingUtilities

/**
 * Editor de móveis no Windows: o mesmo editor.html do celular rodando no Chromium embutido,
 * com a mesma ponte (notas, orçamento, clientes, arquivos de segurança dos projetos).
 */
@Composable
fun MoveisScreen(vm: AppViewModel) {
    val files = remember { File(br.com.arque.measure.desktop.DesktopApp.context.filesDir, "moveis").apply { mkdirs() } }
    var ready by remember { mutableStateOf(Browser.ready) }
    var err by remember { mutableStateOf<String?>(null) }
    var prog by remember { mutableStateOf(0) }
    var showShare by remember { mutableStateOf(false) }

    val bridge = remember {
        MoveisBridge(
            dir = files,
            onClose = { vm.returnProjectId = vm.lastProjectId; vm.screen = Screen.Library },
            onTrena = { vm.toast = tr("No Windows a trena Bosch por Bluetooth ainda não conecta: toque na medida e digite.") },
            onShare = { showShare = true },
            viewing = { vm.moveisView },
            onCurrent = { id -> vm.onEditorProject(id) },
            onQuote = { json -> vm.quoteFromMoveis(json) },
            notes = { vm.notesJson() },
            ctxNote = { vm.contextNoteJson() },
            onLink = { nid, pid -> vm.linkProject(nid, pid) },
            onOpenNote = { pid -> vm.openNoteOf(pid) },
            company = { vm.company.name },
            onShareCut = { code, name, title -> shareCutInvite(vm.cutInvite(code, name, title)) },
            onShareClient = { code, name, room -> shareCutInvite(vm.clientInvite(code, name, room)) },
        )
    }

    // prepara o navegador (na primeira vez descompacta o Chromium: pode levar uns segundos)
    LaunchedEffect(Unit) {
        if (!Browser.ready) {
            val job = launch(Dispatchers.Main) { while (true) { prog = Browser.progress.coerceAtLeast(0); delay(250) } }
            val r = withContext(Dispatchers.IO) { runCatching { Browser.init() } }
            job.cancel()
            r.onFailure { err = it.message ?: it.toString() }
        }
        if (err == null) ready = true
    }

    DisposableEffect(ready) {
        if (!ready) return@DisposableEffect onDispose {}
        Browser.bridge = { m, a -> bridge.call(m, a) }
        Browser.onLoaded = {
            SwingUtilities.invokeLater {
                if (vm.pendingNewProject && !vm.moveisView) {
                    vm.pendingNewProject = false
                    val nm = vm.pendingNewName; vm.pendingNewName = null
                    Browser.js("window.arqueNewProject&&window.arqueNewProject(${if (nm.isNullOrBlank()) "" else org.json.JSONObject.quote(nm)})")
                }
                vm.pendingProject?.let { id ->
                    vm.pendingProject = null
                    Browser.js("window.arqueOpenClient&&window.arqueOpenClient('${id.replace("'", "")}')")
                }
                vm.pendingCut?.let { c ->
                    vm.pendingCut = null
                    Browser.js("window.arqueCutOpen&&window.arqueCutOpen('${c.filter { it.isLetterOrDigit() || it == '-' || it == '_' }}')")
                }
                loadedFlag = true
            }
        }
        loadedFlag = false
        Browser.load("${Browser.ORIGIN}/editor.html?lang=${I18n.lang}&cur=${java.net.URLEncoder.encode(I18n.currencySymbol(), "UTF-8")}&win=1")
        vm.moveisSink = { mm -> SwingUtilities.invokeLater { Browser.js("window.arqueLaser&&window.arqueLaser(${String.format(java.util.Locale.US, "%.1f", mm)})") } }
        onDispose {
            vm.moveisSink = null
            Browser.onLoaded = null
            Browser.bridge = null
            vm.projVersion++
        }
    }

    // link do plano de corte chegou com o editor já aberto
    LaunchedEffect(vm.pendingCut, ready) {
        val c = vm.pendingCut ?: return@LaunchedEffect
        if (!ready || !loadedFlag) return@LaunchedEffect
        vm.pendingCut = null
        Browser.js("window.arqueCutOpen&&window.arqueCutOpen('${c.filter { it.isLetterOrDigit() || it == '-' || it == '_' }}')")
    }

    BackHandler {
        if (!ready) { vm.screen = Screen.Library; return@BackHandler }
        Browser.js("if(!(window.arqueBack&&window.arqueBack()))window.ArqueApp.close()")
    }

    Box(Modifier.fillMaxSize().background(Color.White)) {
        when {
            err != null -> Column(Modifier.align(Alignment.Center).width(460.dp), verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Text(tr("Não consegui abrir o editor de móveis neste computador."), color = Color(0xFF1B1F27))
                if (br.com.arque.measure.data.AppUpdater.oldWindows && !br.com.arque.measure.data.AppUpdater.win7Build) {
                    // Windows 7/8: o Chromium novo não roda · tem o instalador próprio com o Chromium 109
                    Text(tr("Este computador está com Windows 7 ou 8. O editor precisa da versão do Arquemestre feita para Windows 7/8 (seus dados continuam)."), color = Color(0xFF1B1F27))
                    Button(onClick = { vm.installWin7() }) { Text(tr("Baixar e instalar a versão para Windows 7/8")) }
                    vm.updateState?.let { Text(it, color = Color(0xFF666666)) }
                } else Text(err ?: "", color = Color(0xFF666666))
                Button(onClick = { vm.screen = Screen.Library }) { Text(tr("Voltar")) }
            }
            !ready -> Column(Modifier.align(Alignment.Center).width(420.dp), verticalArrangement = Arrangement.spacedBy(12.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                CircularProgressIndicator()
                Text(tr("Preparando o editor de móveis…"), color = Color(0xFF1B1F27))
                if (prog in 1..99) LinearProgressIndicator(progress = { prog / 100f }, modifier = Modifier.padding(top = 4.dp))
                Text(tr("Só na primeira vez demora um pouco."), color = Color(0xFF666666))
            }
            !showShare -> SwingPanel(
                background = Color.White,
                modifier = Modifier.fillMaxSize(),
                factory = { JPanel(java.awt.BorderLayout()).apply { add(Browser.component(), java.awt.BorderLayout.CENTER) } },
            )
        }
    }
    if (showShare) ShareHostDialog(company = vm.company.name, onPush = {}) { showShare = false }
}

private var loadedFlag = false

/** Ponte que o editor (JavaScript) usa pra falar com o app: mesmos nomes do Android. */
class MoveisBridge(
    private val dir: File,
    private val onClose: () -> Unit,
    private val onTrena: () -> Unit = {},
    private val onShare: () -> Unit = {},
    private val viewing: () -> Boolean = { false },
    private val onCurrent: (String) -> Unit = {},
    private val onQuote: (String) -> Unit = {},
    private val notes: () -> String = { "[]" },
    private val ctxNote: () -> String = { "" },
    private val onLink: (String, String) -> Unit = { _, _ -> },
    private val onOpenNote: (String) -> Unit = {},
    private val company: () -> String = { "" },
    private val onShareCut: (String, String, String) -> Unit = { _, _, _ -> },
    private val onShareClient: (String, String, String) -> Unit = { _, _, _ -> },
) {
    private fun safe(name: String) = name.replace(Regex("[^A-Za-z0-9_.-]"), "_")
    private fun ui(f: () -> Unit) = SwingUtilities.invokeLater { runCatching(f) }

    /** Atende uma chamada do editor (roda fora da tela: o que mexe na tela vai pra fila da interface). */
    fun call(m: String, a: List<String>): String {
        fun arg(i: Int) = a.getOrElse(i) { "" }
        return when (m) {
            "companyName" -> runCatching { company() }.getOrDefault("")
            "listNotes" -> runCatching { notes() }.getOrDefault("[]")
            "contextNote" -> runCatching { ctxNote() }.getOrDefault("")
            "linkNote" -> { ui { onLink(arg(0), arg(1)) }; "" }
            "openNoteOf" -> { ui { onOpenNote(arg(0)) }; "" }
            "makeQuote" -> { ui { onQuote(arg(0)) }; "" }
            "setCurrent" -> { ui { onCurrent(arg(0)) }; "" }
            "openTrena" -> { ui(onTrena); "" }
            "shareStart" -> { ui(onShare); "" }
            "isSharing" -> "false"
            "isViewer" -> viewing().toString()
            "shareCut" -> { ui { onShareCut(arg(0), arg(1), arg(2)) }; "" }
            "shareClient" -> { ui { onShareClient(arg(0), arg(1), arg(2)) }; "" }
            "close" -> { ui(onClose); "" }
            "putFile" -> { runCatching { File(dir, safe(arg(0))).writeBytes(android.util.Base64.decode(arg(1), android.util.Base64.DEFAULT)) }; "" }
            "getFile" -> runCatching {
                val f = File(dir, safe(arg(0)))
                if (f.exists()) android.util.Base64.encodeToString(f.readBytes(), android.util.Base64.NO_WRAP) else ""
            }.getOrDefault("")
            "delFile" -> { runCatching { File(dir, safe(arg(0))).delete() }; "" }
            "pageReady" -> { br.com.arque.measure.desktop.Browser.pageReady = true; "" }
            "tourResult" -> { br.com.arque.measure.desktop.Tour.editorResult = arg(0); "" }
            "listFiles" -> (dir.list() ?: emptyArray()).joinToString(prefix = "[", postfix = "]", separator = ",") { "\"$it\"" }
            else -> ""
        }
    }
}

/** Convite do plano de corte: no Windows abre a janela de compartilhar (WhatsApp Web, e-mail ou copiar). */
fun shareCutInvite(text: String) {
    DesktopActions.share = DesktopActions.Share(tr("Enviar plano de corte"), text, null)
}
