package br.com.arque.measure.data

import br.com.arque.measure.i18n.tr

import android.content.Context
import org.json.JSONArray
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * Atualização da versão Windows pelo próprio app: busca o instalador mais novo (releases "win-N")
 * no GitHub, baixa e abre. O instalador atualiza por cima e os dados ficam (pasta do usuário).
 */
object AppUpdater {
    private const val API = "https://api.github.com/repos/adautoaraujo414-pixel/Arqueiro-measure/releases?per_page=40"
    const val ASSET = "Arquemestre-Windows-Instalador.exe"
    /** Instalador com o Chromium 109 (o último que roda no Windows 7, 8 e 8.1). */
    const val ASSET7 = "Arquemestre-Windows7-Instalador.exe"

    /** Este app é o instalador do Windows 7/8 (Chromium 109). */
    val win7Build: Boolean by lazy {
        runCatching { AppUpdater::class.java.getResourceAsStream("/variant.txt")?.bufferedReader()?.use { it.readText().trim() } }.getOrNull() == "win7"
    }

    /** Windows 7, 8 ou 8.1 (o Java diz 6.1, 6.2 ou 6.3): o Chromium novo não abre neles. */
    val oldWindows: Boolean by lazy {
        System.getProperty("os.name").orEmpty().lowercase().contains("win") &&
            (System.getProperty("os.version").orEmpty().substringBefore('.').toIntOrNull() ?: 10) < 10
    }

    /** Qual instalador baixar pra atualizar: o mesmo tipo deste (e sempre o do Windows 7/8 num Windows antigo). */
    fun asset(): String = if (win7Build || oldWindows) ASSET7 else ASSET

    /** notes = "Novidades desta versão" (novidades.txt do release), mostradas no aviso antes de atualizar. */
    data class Release(val number: Int, val url: String, val notes: String = "")

    /** Número desta versão (o mesmo do release win-N que gerou o instalador). */
    fun installedNumber(@Suppress("UNUSED_PARAMETER") ctx: Context): Long =
        (System.getProperty("arque.build") ?: AppUpdater::class.java.getResourceAsStream("/build-number.txt")?.bufferedReader()?.use { it.readText().trim() })
            ?.toLongOrNull() ?: 0L

    /** Lista de versões pelo feed do GitHub (não tem o limite de 60 consultas/hora da API, que estoura em rede de celular). */
    private const val FEED = "https://github.com/adautoaraujo414-pixel/Arqueiro-measure/releases.atom"
    private const val DL = "https://github.com/adautoaraujo414-pixel/Arqueiro-measure/releases/download/"

    private fun get(u: String, json: Boolean): String {
        val c = URL(u).openConnection() as HttpURLConnection
        c.setRequestProperty("User-Agent", "Arquemestre-app")
        if (json) c.setRequestProperty("Accept", "application/vnd.github+json")
        c.connectTimeout = 15000; c.readTimeout = 20000
        if (c.responseCode != 200) error("HTTP " + c.responseCode)
        return c.inputStream.bufferedReader().use { it.readText() }
    }

    /** O arquivo existe no release (o envio pode ter falhado nesse número): pergunta sem baixar. */
    private fun exists(u: String): Boolean = runCatching {
        val c = URL(u).openConnection() as HttpURLConnection
        c.instanceFollowRedirects = false
        c.requestMethod = "HEAD"
        c.setRequestProperty("User-Agent", "Arquemestre-app")
        c.connectTimeout = 15000; c.readTimeout = 20000
        val code = c.responseCode
        c.disconnect()
        code == 200 || code in 300..399
    }.getOrDefault(true)

    /** Versão mais nova publicada (a de número maior, não a primeira da lista). Rede: chamar fora da thread principal. */
    fun latest(asset: String = asset()): Release? {
        val ASSET = asset
        var best: Release? = null
        // 1) ponteiro fixo win-latest/latest.txt (download direto: não depende do feed de 10 itens nem do limite da API)
        runCatching {
            val n = get(DL + "win-latest/latest.txt", false).trim().toInt()
            if (n > 0) best = Release(n, DL + "win-" + n + "/" + ASSET)
        }
        // o instalador desse número não subiu (ex.: o do Windows 7/8): procura o mais novo que tem ele
        if (best != null && !exists(best!!.url)) best = null
        if (best == null) runCatching {
            val xml = get(FEED, false)
            Regex("releases/tag/win-(\\d+)").findAll(xml).map { it.groupValues[1].toInt() }.distinct().sortedDescending().take(6)
                .firstOrNull { exists(DL + "win-" + it + "/" + ASSET) }?.let { best = Release(it, DL + "win-" + it + "/" + ASSET) }
        }
        if (best == null) runCatching {
            val arr = JSONArray(get(API, true))
            for (i in 0 until arr.length()) {
                val r = arr.getJSONObject(i)
                val n = r.optString("tag_name").removePrefix("win-").toIntOrNull() ?: continue
                if (!r.optString("tag_name").startsWith("win-")) continue
                val assets = r.optJSONArray("assets") ?: continue
                for (k in 0 until assets.length()) {
                    val a = assets.getJSONObject(k)
                    if (a.optString("name") == ASSET && (best == null || n > best!!.number)) best = Release(n, a.optString("browser_download_url"))
                }
            }
        }
        best?.let { b -> best = b.copy(notes = notesOf("win-" + b.number)) }
        return best
    }

    /** Novidades da versão (novidades.txt do release, download direto, sem limite da API). Sem internet/sem arquivo: vazio. */
    fun notesOf(tag: String): String = runCatching { get(DL + tag + "/novidades.txt", false).trim().take(4000) }.getOrDefault("")

    /** Novidades de todas as versões que a pessoa pulou (da mais nova pra mais velha, até 8 versões). */
    fun notesSince(installed: Long, latest: Int): String = (latest downTo (installed + 1).toInt().coerceAtLeast(latest - 7)).mapNotNull { n ->
        notesOf("win-" + n).removePrefix("Novidades desta versão:").trim().takeIf { it.isNotBlank() }?.let { "Versão win-" + n + ":\n" + it }
    }.joinToString("\n\n").take(6000)

    fun download(ctx: Context, r: Release, progress: (Int) -> Unit): File {
        val dir = File(ctx.cacheDir, "update").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val out = File(dir, "Arquemestre-${r.number}-Instalador.exe")
        var url = URL(r.url)
        var c: HttpURLConnection
        var hops = 0
        while (true) {
            c = url.openConnection() as HttpURLConnection
            c.instanceFollowRedirects = false
            c.connectTimeout = 15000; c.readTimeout = 60000
            val code = c.responseCode
            if (code in 300..399 && hops++ < 5) { url = URL(url, c.getHeaderField("Location")); c.disconnect(); continue }
            if (code != 200) error(tr("download falhou ({0})", code))
            break
        }
        val total = c.contentLengthLong
        c.inputStream.use { inp ->
            out.outputStream().use { o ->
                val buf = ByteArray(64 * 1024); var done = 0L; var last = -1
                while (true) {
                    val n = inp.read(buf); if (n < 0) break
                    o.write(buf, 0, n); done += n
                    if (total > 0) { val p = (done * 100 / total).toInt(); if (p != last) { last = p; progress(p) } }
                }
            }
        }
        return out
    }

    fun canInstall(@Suppress("UNUSED_PARAMETER") ctx: Context): Boolean = true

    fun askInstallPermission(@Suppress("UNUSED_PARAMETER") ctx: Context) {}

    /** Abre o instalador e fecha o app (o instalador precisa do app fechado pra trocar os arquivos). */
    fun install(@Suppress("UNUSED_PARAMETER") ctx: Context, exe: File) {
        if (System.getProperty("arque.test") != null) return
        runCatching { ProcessBuilder(exe.absolutePath).start() }.onSuccess {
            br.com.arque.measure.desktop.DesktopApp.requestExit?.invoke()
        }
    }
}
