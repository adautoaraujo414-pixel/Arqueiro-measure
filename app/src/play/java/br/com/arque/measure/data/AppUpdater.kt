package br.com.arque.measure.data

import android.content.Context
import java.io.File

/**
 * Versão do Google Play: o app NÃO se atualiza sozinho (regra da Google Play: só a loja atualiza o app).
 * Mesma "cara" do atualizador do APK do site, mas sem fazer nada.
 */
object AppUpdater {
    data class Release(val number: Int, val url: String)

    fun installedNumber(ctx: Context): Long = 0L
    fun latest(): Release? = null
    fun download(ctx: Context, r: Release, progress: (Int) -> Unit): File = throw UnsupportedOperationException()
    fun canInstall(ctx: Context): Boolean = false
    fun askInstallPermission(ctx: Context) {}
    fun install(ctx: Context, apk: File) {}
}
