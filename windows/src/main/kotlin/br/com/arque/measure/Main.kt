package br.com.arque.measure

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.key.Key
import androidx.compose.ui.input.key.KeyEventType
import androidx.compose.ui.input.key.key
import androidx.compose.ui.input.key.type
import androidx.compose.ui.platform.Configuration
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogWindow
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.WindowPlacement
import androidx.compose.ui.window.WindowPosition
import androidx.compose.ui.window.application
import androidx.compose.ui.window.rememberDialogState
import androidx.compose.ui.window.rememberWindowState
import br.com.arque.measure.desktop.BackDispatcher
import br.com.arque.measure.desktop.Browser
import br.com.arque.measure.desktop.DesktopActions
import br.com.arque.measure.desktop.DesktopApp
import br.com.arque.measure.desktop.Notifier
import br.com.arque.measure.desktop.SingleInstance
import br.com.arque.measure.i18n.I18n
import br.com.arque.measure.i18n.tr
import br.com.arque.measure.ui.App
import br.com.arque.measure.ui.ArqueTheme
import java.awt.event.WindowAdapter
import java.awt.event.WindowEvent

/**
 * Arquemestre para Windows: o mesmo app do celular numa janela do computador.
 * Dados em %LOCALAPPDATA%\Arquemestre; backups automáticos em Documentos\Arquemestre\Backups.
 */
fun main(args: Array<String>) {
    // link do plano de corte (arquemestre://corte?d=...) passado ao abrir
    val link = args.firstOrNull { AppViewModel.cutCodeOf(it) != null }
    if (!SingleInstance.claim(link)) return

    val ctx = DesktopApp.context
    // restauração de backup pendente: aplica antes de abrir qualquer tela
    br.com.arque.measure.data.DataBackup.applyPending(ctx)
    I18n.init(ctx)
    val vm = AppViewModel(ctx)
    link?.let { vm.openCutLink(it) }
    SingleInstance.onLink = { l -> java.awt.EventQueue.invokeLater { vm.openCutLink(l); DesktopApp.bringToFront?.invoke() } }
    DesktopApp.openAppointment = { id -> java.awt.EventQueue.invokeLater { vm.openAppointment(id) } }
    vm.checkLicense()
    vm.startStore()
    vm.autoCheckUpdate()
    br.com.arque.measure.agenda.AgendaReminders.scheduleAll(ctx, vm.appointments)

    application {
        val state = rememberWindowState(
            placement = WindowPlacement.Maximized,
            position = WindowPosition.PlatformDefault,
            size = DpSize(1366.dp, 860.dp),
        )
        var closing by remember { mutableStateOf(false) }
        fun quit() {
            if (closing) return
            closing = true
            vm.flush()
            runCatching { br.com.arque.measure.data.DataBackup.autoBackup(ctx) }
            runCatching { Browser.shutdown() }
            Notifier.dispose()
            vm.clear()
            SingleInstance.release()
            exitApplication()
        }
        DesktopApp.requestExit = { java.awt.EventQueue.invokeLater { quit() } }
        Window(
            onCloseRequest = { quit() },
            state = state,
            title = "Arquemestre",
            icon = painterResource("arquemestre.png"),
            onKeyEvent = { e ->
                if (e.type == KeyEventType.KeyDown && e.key == Key.Escape) BackDispatcher.dispatch() else false
            },
        ) {
            LaunchedEffect(Unit) {
                window.minimumSize = java.awt.Dimension(900, 600)
                DesktopApp.frame = window
                DesktopApp.bringToFront = {
                    java.awt.EventQueue.invokeLater {
                        if (window.extendedState == java.awt.Frame.ICONIFIED) window.extendedState = java.awt.Frame.MAXIMIZED_BOTH
                        window.toFront(); window.requestFocus()
                    }
                }
                // voltar pro app (como o onResume do Android): confere licença, versão nova e link copiado
                window.addWindowFocusListener(object : WindowAdapter() {
                    override fun windowGainedFocus(e: WindowEvent?) {
                        vm.checkLicense()
                        vm.autoCheckUpdate()
                        clipboardCutLink(vm)
                    }
                })
            }
            // teste de ponta a ponta do app instalado (GitHub Actions)
            LaunchedEffect(Unit) { System.getenv("ARQUE_TOUR")?.takeIf { it.isNotBlank() }?.let { br.com.arque.measure.desktop.Tour.run(vm, java.io.File(it)) } }
            // bateria do editor no motor do Windows (GitHub Actions, ARQUE_BATERIA=1): abre direto no editor de móveis e fica
            // esperando; os testes entram pela porta de depuração (ARQUE_CDP_PORT) com tools/bateria_editor.py
            LaunchedEffect(Unit) {
                if (System.getenv("ARQUE_BATERIA") == "1") { kotlinx.coroutines.delay(2500); vm.showWelcome = false; vm.newMoveisProject() }
            }
            // avisos que vêm de fora das telas (abrir link, salvar arquivo...)
            val dt = DesktopApp.toast
            LaunchedEffect(dt) { if (dt != null) { vm.toast = dt; DesktopApp.toast = null } }
            val conf = Configuration((state.size.width.value).toInt(), (state.size.height.value).toInt())
            CompositionLocalProvider(LocalConfiguration provides conf) {
                ArqueTheme {
                    key(I18n.lang) { App(vm) }
                    ShareWindow()
                }
            }
        }
    }
}

/** Quem copiou o link do plano de corte (WhatsApp Web, e-mail): ao voltar pro app ele já abre. */
private fun clipboardCutLink(vm: AppViewModel) {
    val sp = DesktopApp.context.getSharedPreferences("arque.cutclip", 0)
    val txt = DesktopActions.clipboardText()?.trim().orEmpty()
    if (txt.isEmpty() || txt == sp.getString("last", null)) return
    if (AppViewModel.cutCodeOf(txt) != null) {
        sp.edit().putString("last", txt).apply()
        vm.openCutLink(txt)
    }
}

/** "Compartilhar" no Windows: copiar o texto, abrir no WhatsApp/e-mail ou salvar o arquivo. */
@androidx.compose.runtime.Composable
private fun ShareWindow() {
    val sh = DesktopActions.share ?: return
    DialogWindow(
        onCloseRequest = { DesktopActions.share = null },
        state = rememberDialogState(size = DpSize(460.dp, if (sh.file != null) 360.dp else 330.dp)),
        title = sh.title,
        icon = painterResource("arquemestre.png"),
        resizable = false,
        alwaysOnTop = true,
    ) {
        ArqueTheme {
            Surface(color = MaterialTheme.colorScheme.surface) {
                Column(Modifier.fillMaxWidth().padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    val text = sh.text
                    val file = sh.file
                    if (file != null) {
                        Text(file.name, style = MaterialTheme.typography.titleMedium)
                        Button(onClick = {
                            val dst = br.com.arque.measure.desktop.DesktopFiles.save(file.name, android.webkit.MimeTypeMap.mimeOf(file.name) ?: "")
                            if (dst != null) {
                                runCatching { file.copyTo(dst, overwrite = true) }
                                    .onSuccess { DesktopApp.toast(tr("Salvo em {0}", dst.path)); DesktopActions.showInFolder(dst) }
                                    .onFailure { DesktopApp.toast(tr("Não consegui salvar: {0}", it.message ?: "")) }
                                DesktopActions.share = null
                            }
                        }, modifier = Modifier.fillMaxWidth()) { Text(tr("Salvar uma cópia…")) }
                        OutlinedButton(onClick = { DesktopActions.openFile(file); DesktopActions.share = null }, modifier = Modifier.fillMaxWidth()) { Text(tr("Abrir o arquivo")) }
                        OutlinedButton(onClick = {
                            DesktopActions.showInFolder(file)
                            DesktopActions.browse("https://web.whatsapp.com/")
                            DesktopApp.toast(tr("No WhatsApp, anexe o arquivo {0} (a pasta já está aberta).", file.name))
                            DesktopActions.share = null
                        }, modifier = Modifier.fillMaxWidth()) { Text(tr("Enviar pelo WhatsApp")) }
                    }
                    if (text != null) {
                        Text(text.take(220) + if (text.length > 220) "…" else "", style = MaterialTheme.typography.bodySmall)
                        Button(onClick = { DesktopActions.copy(text); DesktopApp.toast(tr("Texto copiado")); DesktopActions.share = null }, modifier = Modifier.fillMaxWidth()) { Text(tr("Copiar o texto")) }
                        OutlinedButton(onClick = {
                            DesktopActions.browse("https://wa.me/?text=" + java.net.URLEncoder.encode(text, "UTF-8").replace("+", "%20"))
                            DesktopActions.share = null
                        }, modifier = Modifier.fillMaxWidth()) { Text(tr("Enviar pelo WhatsApp")) }
                        OutlinedButton(onClick = {
                            DesktopActions.browse("mailto:?body=" + java.net.URLEncoder.encode(text, "UTF-8").replace("+", "%20"))
                            DesktopActions.share = null
                        }, modifier = Modifier.fillMaxWidth()) { Text(tr("Enviar por e-mail")) }
                    }
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                        androidx.compose.material3.TextButton(onClick = { DesktopActions.share = null }) { Text(tr("Cancelar")) }
                    }
                }
            }
        }
    }
}
