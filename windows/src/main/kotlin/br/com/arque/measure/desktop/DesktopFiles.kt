package br.com.arque.measure.desktop

import android.net.Uri
import br.com.arque.measure.i18n.tr
import java.awt.FileDialog
import java.io.File
import java.io.FilenameFilter

/** Janelas de abrir/salvar arquivo do Windows (no lugar da galeria e do "salvar em" do Android). */
object DesktopFiles {
    @Volatile private var lastDir: String? = null

    /** Para testes automáticos: em vez de abrir a janela, usa estes arquivos. */
    @Volatile var testOpen: List<File>? = null
    @Volatile var testSaveDir: File? = null

    private fun exts(mime: String): List<String> = when {
        mime.startsWith("image/") -> listOf("jpg", "jpeg", "png", "webp", "bmp", "gif", "heic")
        mime.startsWith("video/") -> listOf("mp4", "mov", "m4v", "webm")
        mime == "application/pdf" -> listOf("pdf")
        mime == "application/zip" -> listOf("zip")
        mime == "text/csv" -> listOf("csv")
        else -> emptyList()
    }

    private fun title(mime: String, save: Boolean): String = when {
        save -> tr("Salvar")
        mime.startsWith("image/") -> tr("Escolher foto")
        mime.startsWith("video/") -> tr("Escolher vídeo")
        mime.contains("zip") -> tr("Escolher o backup")
        else -> tr("Escolher arquivo")
    }

    private fun <T> onUi(f: () -> T): T {
        if (java.awt.EventQueue.isDispatchThread()) return f()
        var r: Result<T>? = null
        java.awt.EventQueue.invokeAndWait { r = runCatching(f) }
        return r!!.getOrThrow()
    }

    fun open(mime: String, multiple: Boolean): List<File> {
        testOpen?.let { testOpen = null; return it }
        return onUi {
            val d = FileDialog(DesktopApp.frame, title(mime, false), FileDialog.LOAD)
            d.isMultipleMode = multiple
            val ex = exts(mime)
            if (ex.isNotEmpty()) {
                d.file = ex.joinToString(";") { "*.$it" }
                d.filenameFilter = FilenameFilter { _, n -> ex.any { n.lowercase().endsWith(".$it") } }
            }
            lastDir?.let { d.directory = it }
            d.isVisible = true
            val files = d.files?.toList().orEmpty().filter { it.isFile }
            files.firstOrNull()?.parent?.let { lastDir = it }
            d.dispose()
            files
        }
    }

    fun save(suggested: String, mime: String): File? {
        val clean = suggested.replace(Regex("[\\\\/:*?\"<>|]"), "_").ifBlank { "arquivo" }
        testSaveDir?.let { return File(it, clean) }
        return onUi {
            val d = FileDialog(DesktopApp.frame, title(mime, true), FileDialog.SAVE)
            d.directory = lastDir ?: Paths.documents.apply { mkdirs() }.path
            d.file = clean
            d.isVisible = true
            val dir = d.directory
            val name = d.file
            d.dispose()
            if (dir == null || name == null) return@onUi null
            lastDir = dir
            var f = File(dir, name)
            val ext = exts(mime).firstOrNull()
            if (ext != null && f.extension.isEmpty()) f = File(dir, "$name.$ext")
            f
        }
    }

    /** "Tirar foto" no computador: escolhe uma foto já existente e copia no lugar pedido. */
    fun pickPhotoInto(target: Uri): Boolean {
        val src = open("image/*", multiple = false).firstOrNull() ?: return false
        val dst = target.file() ?: return false
        return runCatching { dst.parentFile?.mkdirs(); src.copyTo(dst, overwrite = true); true }.getOrDefault(false)
    }
}
