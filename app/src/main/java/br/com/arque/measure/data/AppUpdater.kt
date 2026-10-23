package br.com.arque.measure.data

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import org.json.JSONArray
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/** Atualiza o app pelo próprio app: busca o APK mais novo no GitHub e abre o instalador. */
object AppUpdater {
    private const val API = "https://api.github.com/repos/adautoaraujo414-pixel/Arqueiro-measure/releases?per_page=5"

    data class Release(val number: Int, val url: String)

    fun installedNumber(ctx: Context): Long {
        val pi = ctx.packageManager.getPackageInfo(ctx.packageName, 0)
        return if (Build.VERSION.SDK_INT >= 28) pi.longVersionCode else @Suppress("DEPRECATION") pi.versionCode.toLong()
    }

    /** Release mais nova com APK (rede: chamar fora da thread principal). */
    fun latest(): Release? {
        val c = URL(API).openConnection() as HttpURLConnection
        c.setRequestProperty("Accept", "application/vnd.github+json")
        c.connectTimeout = 15000; c.readTimeout = 20000
        val arr = JSONArray(c.inputStream.bufferedReader().use { it.readText() })
        for (i in 0 until arr.length()) {
            val r = arr.getJSONObject(i)
            val n = r.optString("tag_name").removePrefix("apk-").toIntOrNull() ?: continue
            val assets = r.optJSONArray("assets") ?: continue
            for (k in 0 until assets.length()) {
                val a = assets.getJSONObject(k)
                if (a.optString("name") == "ArqueMeasure-debug.apk") return Release(n, a.optString("browser_download_url"))
            }
        }
        return null
    }

    /** Baixa o APK para o cache e devolve o arquivo. */
    fun download(ctx: Context, r: Release, progress: (Int) -> Unit): File {
        val dir = File(ctx.cacheDir, "update").apply { mkdirs() }
        dir.listFiles()?.forEach { it.delete() }
        val out = File(dir, "ArqueMeasure-${r.number}.apk")
        var url = URL(r.url)
        var c: HttpURLConnection
        var hops = 0
        while (true) {
            c = url.openConnection() as HttpURLConnection
            c.instanceFollowRedirects = false
            c.connectTimeout = 15000; c.readTimeout = 60000
            val code = c.responseCode
            if (code in 300..399 && hops++ < 5) { url = URL(url, c.getHeaderField("Location")); c.disconnect(); continue }
            if (code != 200) error("download falhou ($code)")
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

    fun canInstall(ctx: Context): Boolean =
        Build.VERSION.SDK_INT < 26 || ctx.packageManager.canRequestPackageInstalls()

    fun askInstallPermission(ctx: Context) {
        ctx.startActivity(
            Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, Uri.parse("package:" + ctx.packageName))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    fun install(ctx: Context, apk: File) {
        val uri = FileProvider.getUriForFile(ctx, ctx.packageName + ".fileprovider", apk)
        ctx.startActivity(
            Intent(Intent.ACTION_VIEW).setDataAndType(uri, "application/vnd.android.package-archive")
                .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }
}
