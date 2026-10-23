package br.com.arque.measure.data

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.MediaStore
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Backup COMPLETO do app: notas, agenda, orçamentos, preços, projetos do editor de móveis
 * (inclusive o que o editor guarda no WebView). Tudo o que fica na pasta de dados do app.
 *
 * A restauração não mexe nos arquivos com o app rodando: o ZIP é guardado como "pendente"
 * e aplicado no próximo início, antes de abrir qualquer tela (o WebView fica intacto).
 */
object DataBackup {
    const val MARK = "arque-full-backup.txt"
    private const val AUTO_NAME = "ArqueMeasure-backup-automatico.zip"
    private val SKIP_TOP = setOf("cache", "code_cache", "lib", "no_backup")

    private fun skip(rel: String): Boolean {
        val top = rel.substringBefore('/')
        if (top in SKIP_TOP) return true
        val low = rel.lowercase()
        return low.endsWith(".tmp") || low.endsWith("/lock") || low.endsWith("lockfile") ||
            low.contains("/cache/") || low.contains("gpucache") || low.contains("code cache") ||
            low.contains("shader") || low.endsWith("singletonlock")
    }

    private fun dataDir(ctx: Context): File = ctx.filesDir.parentFile!!

    fun fullBackup(ctx: Context, out: OutputStream) {
        val root = dataDir(ctx)
        ZipOutputStream(out.buffered()).use { zip ->
            zip.putNextEntry(ZipEntry(MARK))
            zip.write("Arque Measure · backup completo · ${System.currentTimeMillis()}".toByteArray())
            zip.closeEntry()
            root.walkTopDown().filter { it.isFile }.forEach { f ->
                val rel = f.relativeTo(root).path.replace(File.separatorChar, '/')
                if (skip(rel)) return@forEach
                runCatching {
                    f.inputStream().use { inp ->
                        // fotos já são comprimidas: guardar sem recomprimir é muito mais rápido
                        val ext = rel.substringAfterLast('.', "").lowercase()
                        zip.setLevel(if (ext in setOf("jpg", "jpeg", "png", "webp", "heic", "apk", "zip")) java.util.zip.Deflater.NO_COMPRESSION else java.util.zip.Deflater.DEFAULT_COMPRESSION)
                        zip.putNextEntry(ZipEntry(rel))
                        inp.copyTo(zip)
                        zip.closeEntry()
                    }
                }
            }
        }
    }

    /** true se o ZIP é um backup completo (formato novo). */
    fun isFull(file: File): Boolean = runCatching {
        ZipInputStream(file.inputStream().buffered()).use { z ->
            var e = z.nextEntry
            while (e != null) { if (e.name == MARK) return@runCatching true; e = z.nextEntry }
            false
        }
    }.getOrDefault(false)

    private fun pending(ctx: Context) = File(ctx.noBackupFilesDir, "restaurar.zip")

    /** Copia o ZIP escolhido e deixa marcado pra aplicar no próximo início. */
    fun stage(ctx: Context, input: InputStream): Boolean {
        val f = pending(ctx)
        f.parentFile?.mkdirs()
        input.use { i -> f.outputStream().use { i.copyTo(it) } }
        if (!isFull(f)) { f.delete(); return false }
        return true
    }

    /** Chamado no onCreate, antes de qualquer tela. Aplica uma restauração pendente. */
    fun applyPending(ctx: Context) {
        val f = pending(ctx)
        if (!f.exists()) return
        val root = dataDir(ctx)
        val canon = root.canonicalPath + File.separator
        try {
            // valida antes de apagar qualquer coisa
            ZipInputStream(f.inputStream().buffered()).use { z ->
                var e = z.nextEntry
                while (e != null) {
                    if (!File(root, e.name).canonicalPath.startsWith(canon)) throw SecurityException(e.name)
                    e = z.nextEntry
                }
            }
            listOf("files", "app_webview", "shared_prefs", "databases").forEach { File(root, it).deleteRecursively() }
            ZipInputStream(f.inputStream().buffered()).use { z ->
                var e = z.nextEntry
                while (e != null) {
                    if (e.name != MARK && !skip(e.name)) {
                        val t = File(root, e.name)
                        if (e.isDirectory) t.mkdirs() else {
                            t.parentFile?.mkdirs()
                            t.outputStream().use { z.copyTo(it) }
                        }
                    }
                    e = z.nextEntry
                }
            }
        } catch (_: Exception) {
        } finally {
            f.delete()
        }
    }

    /** Reinicia o app (usado depois de marcar uma restauração). */
    fun restart(ctx: Context) {
        val i = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName) ?: return
        ctx.startActivity(Intent.makeRestartActivityTask(i.component))
        Runtime.getRuntime().exit(0)
    }

    /**
     * Cópia automática em Downloads/ArqueMeasure (fica no celular mesmo se o app for desinstalado).
     * No máximo a cada 12 horas, sempre sobrescrevendo o mesmo arquivo.
     */
    fun autoBackup(ctx: Context, force: Boolean = false): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val sp = ctx.getSharedPreferences("arque.backup", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        if (!force && now - sp.getLong("last", 0) < 12 * 3600_000L) return false
        val cr = ctx.contentResolver
        val coll = MediaStore.Downloads.EXTERNAL_CONTENT_URI
        return runCatching {
            var uri = cr.query(
                coll, arrayOf(MediaStore.Downloads._ID),
                "${MediaStore.Downloads.DISPLAY_NAME}=?", arrayOf(AUTO_NAME), null,
            )?.use { c -> if (c.moveToFirst()) android.content.ContentUris.withAppendedId(coll, c.getLong(0)) else null }
            if (uri == null) {
                val cv = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, AUTO_NAME)
                    put(MediaStore.Downloads.MIME_TYPE, "application/zip")
                    put(MediaStore.Downloads.RELATIVE_PATH, "Download/ArqueMeasure")
                }
                uri = cr.insert(coll, cv)
            }
            cr.openOutputStream(uri!!, "wt")!!.use { fullBackup(ctx, it) }
            sp.edit().putLong("last", now).apply()
            true
        }.getOrDefault(false)
    }
}
