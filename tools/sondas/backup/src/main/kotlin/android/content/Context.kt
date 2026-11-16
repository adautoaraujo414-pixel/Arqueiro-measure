package android.content
import java.io.File
interface SharedPreferences { fun getLong(k: String, d: Long): Long; fun edit(): Editor
  interface Editor { fun putLong(k: String, v: Long): Editor; fun apply() } }
open class Context(val root: File) {
  companion object { const val MODE_PRIVATE = 0 }
  open val filesDir: File get() = File(root, "files").apply { mkdirs() }
  open val noBackupFilesDir: File get() = File(root, "no_backup").apply { mkdirs() }
  open fun getSharedPreferences(n: String, m: Int): SharedPreferences = object : SharedPreferences {
    override fun getLong(k: String, d: Long) = d
    override fun edit() = object : SharedPreferences.Editor { override fun putLong(k: String, v: Long) = this; override fun apply() {} } }
}
