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
    private const val API = "https://api.github.com/repos/adautoaraujo414-pixel/Arqueiro-measure/releases?per_page=20"
    const val ASSET = "Arquemestre-Windows-Instalador.exe"

    data class Release(val number: Int, val url: String)

    /** Número desta versão (o mesmo do release win-N que gerou o instalador). */
    fun installedNumber(@Suppress("UNUSED_PARAMETER") ctx: Context): Long =
        (System.getProperty("arque.build") ?: AppUpdater::class.java.getResourceAsStream("/build-number.txt")?.bufferedReader()?.use { it.readText().trim() })
            ?.toLongOrNull() ?: 0L

    fun latest(): Release? {
        val c = URL(API).openConnection() as HttpURLConnection
        c.setRequestProperty("Accept", "application/vnd.github+json")
        c.connectTimeout = 15000; c.readTimeout = 20000
        val arr = JSONArray(c.inputStream.bufferedReader().use { it.readText() })
        for (i in 0 until arr.length()) {
            val r = arr.getJSONObject(i)
            val n = r.optString("tag_name").removePrefix("win-").toIntOrNull() ?: continue
            val assets = r.optJSONArray("assets") ?: continue
            for (k in 0 until assets.length()) {
                val a = assets.getJSONObject(k)
                if (a.optString("name") == ASSET) return Release(n, a.optString("browser_download_url"))
            }
        }
        return null
    }

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
