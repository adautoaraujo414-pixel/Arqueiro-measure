package br.com.arque.measure.data

import br.com.arque.measure.model.Index
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.Sheet
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream

/**
 * Persistência em arquivos. Escrita atômica (.tmp -> rename) com cópia de segurança (.bak),
 * para que fechar o app ou faltar bateria no meio do salvamento não perca a folha.
 * As fotos são copiadas byte a byte (sem recompressão) para preservar a resolução original.
 */
class Store(val root: File) {
    private val imagesDir = File(root, "images")
    private val sheetsDir = File(root, "sheets")
    private val indexFile = File(root, "index.json")
    private val readingsFile = File(root, "readings.json")
    private val lock = Any()

    init {
        imagesDir.mkdirs()
        sheetsDir.mkdirs()
    }

    fun imageFile(name: String): File = File(imagesDir, name)

    // ---- escrita/leitura segura ----

    private fun writeAtomic(file: File, text: String) = synchronized(lock) {
        file.parentFile?.mkdirs()
        val tmp = File(file.path + ".tmp")
        tmp.outputStream().use { it.write(text.toByteArray(Charsets.UTF_8)); it.flush(); it.fd.sync() }
        if (file.exists()) {
            val bak = File(file.path + ".bak")
            file.copyTo(bak, overwrite = true)
        }
        if (!tmp.renameTo(file)) {
            tmp.copyTo(file, overwrite = true)
            tmp.delete()
        }
    }

    /** Lê o arquivo; se estiver corrompido tenta o .bak (recuperação). */
    private fun <T> readWithRecovery(file: File, parse: (String) -> T): T? = synchronized(lock) {
        for (candidate in listOf(file, File(file.path + ".bak"), File(file.path + ".tmp"))) {
            if (!candidate.exists()) continue
            try {
                return@synchronized parse(candidate.readText(Charsets.UTF_8))
            } catch (_: Exception) {
                // tenta o próximo candidato
            }
        }
        null
    }

    // ---- índice ----

    fun loadIndex(): Index = readWithRecovery(indexFile, Json::indexFromJson) ?: Index()

    fun saveIndex(index: Index) = writeAtomic(indexFile, Json.indexToJson(index))

    // ---- folhas ----

    private fun sheetFile(id: String) = File(sheetsDir, "$id.json")

    fun loadSheet(id: String): Sheet? = readWithRecovery(sheetFile(id), Json::sheetFromJson)

    fun saveSheet(sheet: Sheet) = writeAtomic(sheetFile(sheet.id), Json.sheetToJson(sheet))

    fun deleteSheet(id: String) = synchronized(lock) {
        val f = sheetFile(id)
        f.delete(); File(f.path + ".bak").delete(); File(f.path + ".tmp").delete()
    }

    // ---- leituras Bluetooth ainda não vinculadas ----

    fun loadReadings(): List<Reading> = readWithRecovery(readingsFile, Json::readingsFromJson) ?: emptyList()

    fun saveReadings(list: List<Reading>) = writeAtomic(readingsFile, Json.readingsToJson(list))

    // ---- fotos ----

    /** Copia a foto original sem recompressão. Retorna o nome do arquivo guardado. */
    fun importImage(input: InputStream, ext: String): String {
        val name = "${br.com.arque.measure.model.newId()}.${ext.ifBlank { "img" }}"
        input.use { src -> imageFile(name).outputStream().use { dst -> src.copyTo(dst) } }
        return name
    }

    /** Fotos que nenhuma folha referencia mais podem ser limpas por aqui. */
    fun referencedImages(): Set<String> = synchronized(lock) {
        sheetsDir.listFiles { f -> f.name.endsWith(".json") }.orEmpty().mapNotNull { f ->
            runCatching { Json.sheetFromJson(f.readText()) }.getOrNull()
        }.flatMap { s -> s.objs.filterIsInstance<br.com.arque.measure.model.PhotoObj>().map { it.file } }.toSet()
    }

    // ---- backup / restauração ----

    fun backupTo(out: OutputStream) = synchronized(lock) {
        ZipOutputStream(out.buffered()).use { zip ->
            root.walkTopDown().filter { it.isFile && !it.name.endsWith(".tmp") }.forEach { f ->
                val rel = f.relativeTo(root).path.replace(File.separatorChar, '/')
                zip.putNextEntry(ZipEntry(rel))
                f.inputStream().use { it.copyTo(zip) }
                zip.closeEntry()
            }
        }
    }

    /** Restaura um backup ZIP. Valida os caminhos (anti zip-slip) e exige um index.json válido. */
    fun restoreFrom(input: InputStream): Boolean = synchronized(lock) {
        val staging = File(root.parentFile, root.name + "_restore")
        staging.deleteRecursively()
        staging.mkdirs()
        val stagingCanon = staging.canonicalPath + File.separator
        try {
            ZipInputStream(input.buffered()).use { zip ->
                var e = zip.nextEntry
                while (e != null) {
                    val target = File(staging, e.name)
                    if (!target.canonicalPath.startsWith(stagingCanon)) {
                        throw SecurityException("entrada inválida no backup: ${e.name}")
                    }
                    if (e.isDirectory) target.mkdirs() else {
                        target.parentFile?.mkdirs()
                        target.outputStream().use { zip.copyTo(it) }
                    }
                    e = zip.nextEntry
                }
            }
            val idx = File(staging, "index.json")
            if (!idx.exists()) throw IllegalStateException("backup sem index.json")
            Json.indexFromJson(idx.readText())

            root.listFiles()?.forEach { it.deleteRecursively() }
            staging.listFiles()?.forEach { it.copyRecursively(File(root, it.name), overwrite = true) }
            imagesDir.mkdirs(); sheetsDir.mkdirs()
            true
        } catch (_: Exception) {
            false
        } finally {
            staging.deleteRecursively()
        }
    }
}
