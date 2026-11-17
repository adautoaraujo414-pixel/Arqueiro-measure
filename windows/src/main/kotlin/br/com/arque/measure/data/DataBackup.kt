package br.com.arque.measure.data

import android.content.Context
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
    private const val AUTO_NAME = "Arquemestre-backup-automatico.zip"
    private val SKIP_TOP = setOf("cache", "code_cache", "lib", "no_backup", "jcef", "logs")

    private fun skip(rel: String): Boolean {
        val top = rel.substringBefore('/')
        if (top in SKIP_TOP) return true
        // área da restauração e cópias do estado anterior: ficam no aparelho, não entram no backup
        if (top == STAGING || top.startsWith(PREV_PREFIX) || rel == SWAP_MARK) return true
        val low = rel.lowercase()
        // licença (teste de 3 dias, senha, mensalidade) é do aparelho: não vai no backup nem vem de um backup de outro
        if (low.startsWith("shared_prefs/arque.lic.")) return true
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

    // ---- restauração segura (P0-02, auditoria de 16/11) ----
    // Antes: applyPending apagava files/app_webview/shared_prefs/databases ANTES de extrair, sem cópia do estado atual,
    // e um erro no meio caía num catch vazio (projetos trocados, notas sumidas). stage só conferia a marca (backup vazio apagava tudo).
    // Agora: confere o ZIP inteiro → extrai numa área separada → guarda o estado atual inteiro (não é apagado sozinho) →
    // troca → se qualquer passo falhar, volta tudo como estava. App fechado no meio da troca: volta o anterior no próximo início.
    private const val STAGING = "restore_staging"
    private const val PREV_PREFIX = "restore_previous_"
    private const val SWAP_MARK = "restore_swap.txt"
    private const val RESULT = "restaurar.resultado.txt"
    private val TOPS = listOf("files", "app_webview", "shared_prefs", "databases")

    /** Motivo da última recusa de um backup completo (o app mostra e não tenta restaurar de outro jeito). */
    @Volatile var lastReject: String? = null

    /** Resultado da conferência de um backup completo. */
    class Check(val ok: Boolean, val reason: String, val files: Int, val projects: Int?)

    /**
     * Confere o backup de ponta a ponta sem mexer em nada: tem a marca, o índice do ZIP existe (arquivo cortado não tem),
     * cada item é lido até o fim (bytes trocados dão erro de CRC), nenhum caminho sai da pasta, a lista de projetos abre,
     * e o backup tem projetos ou notas (backup vazio é recusado).
     */
    fun check(file: File): Check {
        var mark = false; var files = 0; var projects: Int? = null; var notes = 0; var streamed = 0
        val total = try { java.util.zip.ZipFile(file).use { it.size() } } catch (_: Exception) { return Check(false, "o arquivo de backup está incompleto ou danificado", 0, null) }
        try {
            ZipInputStream(file.inputStream().buffered()).use { z ->
                val buf = ByteArray(64 * 1024)
                var e = z.nextEntry
                while (e != null) {
                    streamed++
                    val n = e.name
                    /* BKP-PONTOS (17/11): só um pedaço do caminho igual a ".." é travessia; "foto..jpg" é nome válido */
                    if (n.split('/', '\\').any { it == ".." } || n.startsWith("/") || n.startsWith("\\") || n.contains(':')) return Check(false, "o backup tem um caminho inválido", files, projects)
                    val keep = n == "files/moveis/projects.json"
                    val bo = if (keep) java.io.ByteArrayOutputStream() else null
                    while (true) { val r = z.read(buf); if (r < 0) break; bo?.write(buf, 0, r) }
                    if (n == MARK) mark = true
                    else if (!e.isDirectory && !skip(n)) {
                        files++
                        if (keep) {
                            projects = try { org.json.JSONArray(String(bo!!.toByteArray(), Charsets.UTF_8)).length() } catch (_: Exception) { return Check(false, "a lista de projetos do backup está ilegível", files, null) }
                        } else if (n.startsWith("files/")) notes++
                    }
                    e = z.nextEntry
                }
            }
        } catch (_: Exception) { return Check(false, "o arquivo de backup está incompleto ou danificado", files, projects) }
        if (streamed != total) return Check(false, "o arquivo de backup está incompleto ou danificado", files, projects)
        if (!mark) return Check(false, "não é um backup completo do Arquemestre", files, projects)
        if (files == 0 || ((projects ?: 0) == 0 && notes == 0)) return Check(false, "o backup está vazio (sem projetos e sem notas)", files, projects)
        return Check(true, "", files, projects)
    }

    /** Copia o ZIP escolhido e deixa marcado pra aplicar no próximo início, só se ele passar na conferência inteira. */
    fun stage(ctx: Context, input: InputStream): Boolean {
        lastReject = null
        val f = pending(ctx)
        f.parentFile?.mkdirs()
        input.use { i -> f.outputStream().use { i.copyTo(it) } }
        if (!isFull(f)) { f.delete(); return false }
        val c = check(f)
        if (!c.ok) { f.delete(); lastReject = "Backup não restaurado: " + c.reason + ". Nada foi alterado."; return false }
        return true
    }

    /** Mensagem da última restauração (aplicada no início do app), uma vez só. */
    fun takeResult(ctx: Context): String? = runCatching {
        val r = File(ctx.noBackupFilesDir, RESULT)
        if (!r.exists()) return@runCatching null
        val t = r.readText(); r.delete(); t.ifBlank { null }
    }.getOrNull()

    private fun result(ctx: Context, msg: String) { runCatching { File(ctx.noBackupFilesDir, RESULT).writeText(msg) } }

    /** Chamado no onCreate, antes de qualquer tela. Aplica uma restauração pendente. */
    fun applyPending(ctx: Context) {
        val root = dataDir(ctx)
        runCatching { recoverSwap(root) }
        val f = pending(ctx)
        if (!f.exists()) return
        val staging = File(root, STAGING)
        try {
            val c = check(f)
            if (!c.ok) { result(ctx, "Backup não restaurado: " + c.reason + ". Nada foi alterado."); return }
            staging.deleteRecursively(); staging.mkdirs()
            val canon = staging.canonicalPath + File.separator
            ZipInputStream(f.inputStream().buffered()).use { z ->
                var e = z.nextEntry
                while (e != null) {
                    if (e.name != MARK && !skip(e.name)) {
                        val t = File(staging, e.name)
                        if (!t.canonicalPath.startsWith(canon)) throw SecurityException(e.name)
                        if (e.isDirectory) t.mkdirs() else {
                            t.parentFile?.mkdirs()
                            t.outputStream().use { z.copyTo(it) }
                        }
                    }
                    e = z.nextEntry
                }
            }
            // a licença deste aparelho fica como está (restaurar backup não zera nem copia o teste/senha)
            File(root, "shared_prefs").listFiles { x -> x.name.startsWith("arque.lic.") }?.forEach { lf ->
                File(staging, "shared_prefs").mkdirs(); lf.copyTo(File(File(staging, "shared_prefs"), lf.name), overwrite = true)
            }
            swapIn(root, staging)
            result(ctx, "Backup restaurado" + (c.projects?.let { " · $it projeto(s)" } ?: "") + ". O que estava antes ficou guardado no aparelho.")
        } catch (_: Exception) {
            result(ctx, "Backup não restaurado: falha ao preparar os arquivos. Nada foi alterado.")
        } finally {
            staging.deleteRecursively()
            f.delete()
        }
    }

    /** Troca com volta: o estado atual vai inteiro pra restore_previous_<hora> (fica guardado), o preparado entra no lugar. */
    internal fun swapIn(root: File, staging: File, move: (File, File) -> Boolean = { a, b -> a.renameTo(b) }) {
        val prev = File(root, PREV_PREFIX + System.currentTimeMillis())
        prev.mkdirs()
        val mark = File(root, SWAP_MARK)
        mark.writeText(prev.name)
        val moved = mutableListOf<String>(); val placed = mutableListOf<String>()
        try {
            for (t in TOPS) { val cur = File(root, t); if (cur.exists()) { if (!move(cur, File(prev, t))) throw java.io.IOException("não guardou $t"); moved += t } }
            for (t in TOPS) { val s = File(staging, t); if (s.exists()) { if (!move(s, File(root, t))) throw java.io.IOException("não pôs $t"); placed += t } }
        } catch (x: Exception) {
            placed.forEach { File(root, it).deleteRecursively() }
            moved.forEach { File(prev, it).renameTo(File(root, it)) }
            if (prev.list().isNullOrEmpty()) prev.delete()
            mark.delete()
            throw x
        }
        mark.delete()
    }

    /** App fechado no meio da troca: devolve o estado que estava antes. */
    private fun recoverSwap(root: File) {
        val mark = File(root, SWAP_MARK)
        if (!mark.exists()) return
        val prev = File(root, mark.readText().trim())
        if (prev.isDirectory) TOPS.forEach { t -> val p = File(prev, t); if (p.exists()) { File(root, t).deleteRecursively(); p.renameTo(File(root, t)) } }
        mark.delete()
    }

    /** Reinicia o app (usado depois de marcar uma restauração): abre de novo e fecha este. */
    fun restart(@Suppress("UNUSED_PARAMETER") ctx: Context) {
        if (System.getProperty("arque.test") != null) return
        val exe = System.getProperty("jpackage.app-path")
        if (exe != null) runCatching { ProcessBuilder(exe).start() }
        br.com.arque.measure.desktop.DesktopApp.requestExit?.invoke() ?: Runtime.getRuntime().exit(0)
    }

    /** Pasta das cópias automáticas (Documentos\Arquemestre\Backups). */
    fun autoDir(): File = File(br.com.arque.measure.desktop.Paths.documents, "Backups")

    /**
     * Cópia automática em Documentos\Arquemestre\Backups (fica mesmo se o app for desinstalado).
     * No máximo a cada 12 horas, sempre sobrescrevendo o mesmo arquivo.
     */
    /** Só os dados dos projetos (texto, sem fotos): fica pequeno, dá pra guardar um por dia sem nunca apagar. */
    private fun projectsZip(ctx: Context, out: OutputStream) {
        val root = dataDir(ctx)
        ZipOutputStream(out.buffered()).use { zip ->
            zip.putNextEntry(ZipEntry("arque-projetos.txt"))
            zip.write("Arquemestre · cópia dos projetos · ${System.currentTimeMillis()}".toByteArray())
            zip.closeEntry()
            listOf("files/moveis", "files/projects").forEach { d ->
                File(root, d).walkTopDown().filter { it.isFile && it.extension.lowercase() == "json" }.forEach { f ->
                    runCatching {
                        val rel = f.relativeTo(root).path.replace(File.separatorChar, '/')
                        f.inputStream().use { inp -> zip.putNextEntry(ZipEntry(rel)); inp.copyTo(zip); zip.closeEntry() }
                    }
                }
            }
        }
    }

    /**
     * Cópia datada dos projetos em Documentos\Arquemestre\Backups\Projetos: uma por dia (na primeira abertura do dia,
     * ou seja, como os projetos estavam ANTES do trabalho do dia). Nunca grava por cima de uma cópia que já existe
     * e nunca apaga cópia antiga.
     */
    fun datedProjects(ctx: Context, tag: String): Boolean = runCatching {
        if (!File(ctx.filesDir, "moveis/projects.json").exists() && !File(ctx.filesDir, "projects").exists()) return@runCatching false
        val dir = File(autoDir(), "Projetos").apply { mkdirs() }
        val dst = File(dir, "Arquemestre-projetos-$tag.zip")
        if (dst.exists()) return@runCatching false
        val tmp = File(dir, dst.name + ".tmp")
        tmp.outputStream().use { projectsZip(ctx, it) }
        tmp.renameTo(dst)
    }.getOrDefault(false)

    fun autoBackup(ctx: Context, force: Boolean = false): Boolean {
        runCatching { datedProjects(ctx, java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())) }
        val sp = ctx.getSharedPreferences("arque.backup", Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        if (!force && now - sp.getLong("last", 0) < 12 * 3600_000L) return false
        return runCatching {
            val dir = autoDir().apply { mkdirs() }
            val tmp = File(dir, AUTO_NAME + ".tmp")
            tmp.outputStream().use { fullBackup(ctx, it) }
            val dst = File(dir, AUTO_NAME)
            if (!tmp.renameTo(dst)) { dst.delete(); tmp.renameTo(dst) }
            sp.edit().putLong("last", now).apply()
            true
        }.getOrDefault(false)
    }
}
