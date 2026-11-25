package br.com.arque.measure.demo

import android.app.Application
import android.content.Context
import android.content.ContextWrapper
import android.content.SharedPreferences
import java.io.File

/** A demonstração usa outra origem Web e outros arquivos; nunca libera a licença normal. */
object DemoSpace {
    const val DIRECTORY = "arquemestre_demo"
    const val PREF_PREFIX = "arquemestre_demo_"
    const val WEB_DOMAIN = "demo.arquemestre.invalid"

    fun isDemo(context: Context) = context.applicationContext is DemoApplication
    fun root(context: Context): File = File(context.filesDir, DIRECTORY)
    fun application(context: Context) = DemoApplication(context.applicationContext)
    fun wrap(context: Context): Context = if (isDemo(context)) context else DemoContext(context, application(context))
}

class DemoApplication(base: Context) : Application() {
    private val original = base.applicationContext
    private val root = DemoSpace.root(original)
    init { attachBaseContext(original) }
    private fun directory(name: String) = File(root, name).apply { mkdirs() }
    override fun getApplicationContext(): Context = this
    override fun getFilesDir(): File = directory("files")
    override fun getCacheDir(): File = File(original.cacheDir, DemoSpace.DIRECTORY).apply { mkdirs() }
    override fun getNoBackupFilesDir(): File = directory("no_backup")
    override fun getDataDir(): File = root
    override fun getDir(name: String, mode: Int): File {
        require('/' !in name && '\\' !in name && name != "..")
        return directory("app_$name")
    }
    override fun getSharedPreferences(name: String, mode: Int): SharedPreferences =
        original.getSharedPreferences(DemoSpace.PREF_PREFIX + name, mode)
    override fun deleteSharedPreferences(name: String): Boolean =
        original.deleteSharedPreferences(DemoSpace.PREF_PREFIX + name)
}

/** Mantém o vínculo com a Activity para câmera/permissões, mas encaminha dados ao espaço de demonstração. */
class DemoContext(base: Context, private val app: DemoApplication) : ContextWrapper(base) {
    override fun getApplicationContext(): Context = app
    override fun getFilesDir(): File = app.filesDir
    override fun getCacheDir(): File = app.cacheDir
    override fun getNoBackupFilesDir(): File = app.noBackupFilesDir
    override fun getDataDir(): File = app.dataDir
    override fun getDir(name: String, mode: Int): File = app.getDir(name, mode)
    override fun getSharedPreferences(name: String, mode: Int): SharedPreferences = app.getSharedPreferences(name, mode)
    override fun deleteSharedPreferences(name: String): Boolean = app.deleteSharedPreferences(name)
}
