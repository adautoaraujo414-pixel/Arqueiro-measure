package br.com.arque.measure.desktop

import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.awt.Desktop
import java.awt.Toolkit
import java.awt.datatransfer.StringSelection
import java.io.File
import java.net.URI

/**
 * O que no Android abre outro app (navegador, WhatsApp, "compartilhar") e no Windows vira:
 * abrir no navegador padrão, copiar texto ou salvar/abrir o arquivo.
 */
object DesktopActions {
    /** Pedido de "compartilhar" esperando o usuário escolher o que fazer (janela própria). */
    class Share(val title: String, val text: String?, val file: File?)

    var share by mutableStateOf<Share?>(null)

    /** Para os testes: o que teria sido aberto. */
    val opened = ArrayList<String>()

    fun start(i: Intent) {
        when (i.action) {
            Intent.ACTION_CHOOSER -> i.target?.let { t -> startShare(t, i.chooserTitle) }
            Intent.ACTION_SEND -> startShare(i, null)
            Intent.ACTION_VIEW, Intent.ACTION_DIAL, Intent.ACTION_SENDTO -> i.data?.let { open(it) }
            else -> {}
        }
    }

    private fun startShare(i: Intent, title: String?) {
        val text = i.extras[Intent.EXTRA_TEXT] as? String
        val file = (i.extras[Intent.EXTRA_STREAM] as? Uri)?.file()
        share = Share(title ?: br.com.arque.measure.i18n.tr("Compartilhar"), text, file)
    }

    fun open(u: Uri) = browse(u.toString())

    fun browse(url: String) {
        synchronized(opened) { opened += url }
        if (System.getProperty("arque.test") != null) return
        val s = url.trim()
        when {
            s.startsWith("tel:") -> { copy(s.removePrefix("tel:")); DesktopApp.toast(br.com.arque.measure.i18n.tr("Número copiado: {0}", s.removePrefix("tel:"))) }
            else -> runCatching {
                if (Desktop.isDesktopSupported() && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) Desktop.getDesktop().browse(URI(s))
                else if (System.getProperty("os.name").lowercase().contains("win")) ProcessBuilder("rundll32", "url.dll,FileProtocolHandler", s).start()
                else ProcessBuilder("xdg-open", s).start()
            }.onFailure { DesktopApp.toast(br.com.arque.measure.i18n.tr("Nenhum app encontrado pra abrir isso")) }
        }
    }

    fun openFile(f: File) {
        synchronized(opened) { opened += f.toURI().toString() }
        if (System.getProperty("arque.test") != null) return
        runCatching { Desktop.getDesktop().open(f) }.onFailure { browse(f.toURI().toString()) }
    }

    fun showInFolder(f: File) {
        if (System.getProperty("arque.test") != null) return
        runCatching {
            if (System.getProperty("os.name").lowercase().contains("win")) ProcessBuilder("explorer.exe", "/select,", f.absolutePath).start()
            else Desktop.getDesktop().open(f.parentFile)
        }
    }

    fun copy(text: String) {
        runCatching { Toolkit.getDefaultToolkit().systemClipboard.setContents(StringSelection(text), null) }
    }

    fun clipboardText(): String? = runCatching {
        Toolkit.getDefaultToolkit().systemClipboard.getData(java.awt.datatransfer.DataFlavor.stringFlavor) as? String
    }.getOrNull()
}
