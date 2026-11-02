@file:Suppress("unused", "UNUSED_PARAMETER")

package android.content

/*
 * Camada de compatibilidade (Windows): Context, preferências, arquivos e "intents" do Android
 * implementados com o que o Windows oferece (pastas do usuário, navegador, área de transferência).
 */

import android.net.Uri
import br.com.arque.measure.desktop.DesktopActions
import br.com.arque.measure.desktop.Paths
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream

open class Context {
    open val filesDir: File get() = File(Paths.data, "files").apply { mkdirs() }
    open val cacheDir: File get() = File(Paths.data, "cache").apply { mkdirs() }
    open val noBackupFilesDir: File get() = File(Paths.data, "no_backup").apply { mkdirs() }
    open val applicationContext: Context get() = this
    open val packageName: String get() = "br.com.arque.measure"
    open val contentResolver: ContentResolver get() = ContentResolver
    open val assets: AssetManager get() = AssetManager
    open val packageManager: android.content.pm.PackageManager get() = android.content.pm.PackageManager

    fun getSharedPreferences(name: String, mode: Int): SharedPreferences = Prefs.get(name)

    open fun startActivity(i: Intent) { DesktopActions.start(i) }

    fun getExternalFilesDir(type: String?): File? = File(Paths.data, "external" + (type?.let { "/$it" } ?: "")).apply { mkdirs() }

    companion object {
        const val MODE_PRIVATE = 0
    }
}

open class ContextWrapper(val baseContext: Context) : Context()

class ActivityNotFoundException(msg: String? = null) : RuntimeException(msg)

/** Os arquivos de dentro do app (editor de móveis, traduções). */
object AssetManager {
    fun open(path: String): InputStream =
        AssetManager::class.java.classLoader.getResourceAsStream("assets/$path") ?: throw java.io.FileNotFoundException(path)
    fun list(path: String): Array<String> = emptyArray()
}

interface SharedPreferences {
    fun getString(key: String, def: String?): String?
    fun getInt(key: String, def: Int): Int
    fun getLong(key: String, def: Long): Long
    fun getFloat(key: String, def: Float): Float
    fun getBoolean(key: String, def: Boolean): Boolean
    fun getStringSet(key: String, def: Set<String>?): Set<String>?
    fun contains(key: String): Boolean
    val all: Map<String, *>
    fun edit(): Editor

    interface Editor {
        fun putString(key: String, v: String?): Editor
        fun putInt(key: String, v: Int): Editor
        fun putLong(key: String, v: Long): Editor
        fun putFloat(key: String, v: Float): Editor
        fun putBoolean(key: String, v: Boolean): Editor
        fun putStringSet(key: String, v: Set<String>?): Editor
        fun remove(key: String): Editor
        fun clear(): Editor
        fun apply()
        fun commit(): Boolean
    }
}

/** Preferências gravadas em JSON na pasta de dados (shared_prefs/<nome>.json), como no Android. */
internal class FilePrefs(private val file: File) : SharedPreferences {
    private val map = LinkedHashMap<String, Any?>()

    init {
        runCatching {
            val xml = File(file.parentFile, file.nameWithoutExtension + ".xml")
            if (!file.exists() && xml.exists()) readAndroidXml(xml)
            if (file.exists()) {
                val o = JSONObject(file.readText(Charsets.UTF_8))
                for (k in o.keys()) {
                    val e = o.optJSONObject(k) ?: continue
                    map[k] = when (e.optString("t")) {
                        "s" -> e.optString("v")
                        "i" -> e.optInt("v")
                        "l" -> e.optLong("v")
                        "f" -> e.optDouble("v").toFloat()
                        "b" -> e.optBoolean("v")
                        "set" -> e.optJSONArray("v")?.let { a -> (0 until a.length()).map { a.optString(it) }.toSet() } ?: emptySet<String>()
                        else -> null
                    }
                }
            }
        }
    }

    /** Preferências vindas de um backup do celular (formato XML do Android). */
    private fun readAndroidXml(f: File) {
        val doc = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(f)
        val nodes = doc.documentElement.childNodes
        for (i in 0 until nodes.length) {
            val e = nodes.item(i) as? org.w3c.dom.Element ?: continue
            val k = e.getAttribute("name")
            val v = e.getAttribute("value")
            map[k] = when (e.tagName) {
                "string" -> e.textContent
                "int" -> v.toIntOrNull()
                "long" -> v.toLongOrNull()
                "float" -> v.toFloatOrNull()
                "boolean" -> v == "true"
                "set" -> (0 until e.childNodes.length).mapNotNull { (e.childNodes.item(it) as? org.w3c.dom.Element)?.textContent }.toSet()
                else -> null
            }
        }
        runCatching { save() }
    }

    @Synchronized private fun save() {
        val o = JSONObject()
        for ((k, v) in map) {
            val e = JSONObject()
            when (v) {
                is String -> { e.put("t", "s"); e.put("v", v) }
                is Int -> { e.put("t", "i"); e.put("v", v) }
                is Long -> { e.put("t", "l"); e.put("v", v) }
                is Float -> { e.put("t", "f"); e.put("v", v.toDouble()) }
                is Boolean -> { e.put("t", "b"); e.put("v", v) }
                is Set<*> -> { e.put("t", "set"); e.put("v", org.json.JSONArray(v.map { it.toString() })) }
                else -> continue
            }
            o.put(k, e)
        }
        file.parentFile?.mkdirs()
        val tmp = File(file.parentFile, file.name + ".tmp")
        tmp.writeText(o.toString(), Charsets.UTF_8)
        if (!tmp.renameTo(file)) { file.delete(); tmp.renameTo(file) }
    }

    @Synchronized override fun getString(key: String, def: String?): String? = (map[key] as? String) ?: def
    @Synchronized override fun getInt(key: String, def: Int): Int = (map[key] as? Number)?.toInt() ?: def
    @Synchronized override fun getLong(key: String, def: Long): Long = (map[key] as? Number)?.toLong() ?: def
    @Synchronized override fun getFloat(key: String, def: Float): Float = (map[key] as? Number)?.toFloat() ?: def
    @Synchronized override fun getBoolean(key: String, def: Boolean): Boolean = (map[key] as? Boolean) ?: def
    @Suppress("UNCHECKED_CAST")
    @Synchronized override fun getStringSet(key: String, def: Set<String>?): Set<String>? = (map[key] as? Set<String>) ?: def
    @Synchronized override fun contains(key: String): Boolean = map.containsKey(key)
    override val all: Map<String, *> @Synchronized get() = LinkedHashMap(map)

    override fun edit(): SharedPreferences.Editor = object : SharedPreferences.Editor {
        private val ch = LinkedHashMap<String, Any?>()
        private val rm = HashSet<String>()
        private var clr = false
        override fun putString(key: String, v: String?): SharedPreferences.Editor { if (v == null) rm += key else ch[key] = v; return this }
        override fun putInt(key: String, v: Int): SharedPreferences.Editor { ch[key] = v; return this }
        override fun putLong(key: String, v: Long): SharedPreferences.Editor { ch[key] = v; return this }
        override fun putFloat(key: String, v: Float): SharedPreferences.Editor { ch[key] = v; return this }
        override fun putBoolean(key: String, v: Boolean): SharedPreferences.Editor { ch[key] = v; return this }
        override fun putStringSet(key: String, v: Set<String>?): SharedPreferences.Editor { if (v == null) rm += key else ch[key] = HashSet(v); return this }
        override fun remove(key: String): SharedPreferences.Editor { rm += key; return this }
        override fun clear(): SharedPreferences.Editor { clr = true; return this }
        override fun apply() { commit() }
        override fun commit(): Boolean = synchronized(this@FilePrefs) {
            if (clr) map.clear()
            rm.forEach { map.remove(it) }
            map.putAll(ch)
            runCatching { save() }.isSuccess
        }
    }
}

object Prefs {
    private val open = HashMap<String, FilePrefs>()
    fun get(name: String): SharedPreferences = synchronized(open) {
        open.getOrPut(name) { FilePrefs(File(Paths.data, "shared_prefs/$name.json")) }
    }
    /** Esquece o que está em memória (depois de restaurar um backup). */
    fun reset() = synchronized(open) { open.clear() }
}

class ContentValues {
    private val m = LinkedHashMap<String, Any?>()
    fun put(k: String, v: String?) { m[k] = v }
    fun put(k: String, v: Int?) { m[k] = v }
    fun put(k: String, v: Long?) { m[k] = v }
    fun getAsString(k: String): String? = m[k]?.toString()
}

/** Arquivos escolhidos pelo usuário (Uri de arquivo) ou pastas da galeria/downloads do Windows. */
object ContentResolver {
    fun openInputStream(uri: Uri): InputStream? = uri.file()?.takeIf { it.exists() }?.let { FileInputStream(it) }
    fun openOutputStream(uri: Uri): OutputStream? = uri.file()?.let { it.parentFile?.mkdirs(); FileOutputStream(it) }
    fun openOutputStream(uri: Uri, mode: String): OutputStream? = openOutputStream(uri)
    fun getType(uri: Uri): String? = uri.file()?.let { android.webkit.MimeTypeMap.mimeOf(it.name) }

    /** MediaStore: a "galeria" é Imagens\Arquemestre e os "downloads" são Documentos\Arquemestre. */
    fun insert(collection: Uri, cv: ContentValues): Uri? {
        val name = cv.getAsString(android.provider.MediaStore.MediaColumns.DISPLAY_NAME) ?: ("arque_" + System.currentTimeMillis())
        val dir = if (collection == android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI) Paths.documents else Paths.pictures
        dir.mkdirs()
        var f = File(dir, name)
        var n = 1
        while (f.exists()) { f = File(dir, name.substringBeforeLast('.') + " ($n)." + name.substringAfterLast('.', "jpg")); n++ }
        return Uri.fromFile(f)
    }
}

class ClipData private constructor(val text: String) {
    companion object { fun newPlainText(label: CharSequence?, text: CharSequence?) = ClipData(text?.toString().orEmpty()) }
}

class Intent() {
    var action: String? = null
    var data: Uri? = null
    var type: String? = null
    var pkg: String? = null
    val extras = HashMap<String, Any?>()
    var chooserTitle: String? = null
    var target: Intent? = null

    constructor(action: String?) : this() { this.action = action }
    constructor(action: String?, uri: Uri?) : this() { this.action = action; this.data = uri }
    constructor(ctx: Context?, cls: Class<*>?) : this()
    constructor(o: Intent) : this() { action = o.action; data = o.data; type = o.type; pkg = o.pkg; extras.putAll(o.extras) }

    fun putExtra(k: String, v: String?): Intent = apply { extras[k] = v }
    fun putExtra(k: String, v: Boolean): Intent = apply { extras[k] = v }
    fun putExtra(k: String, v: Int): Intent = apply { extras[k] = v }
    fun putExtra(k: String, v: Long): Intent = apply { extras[k] = v }
    fun putExtra(k: String, v: Uri?): Intent = apply { extras[k] = v }
    fun putExtra(k: String, v: Array<*>?): Intent = apply { extras[k] = v }
    fun getStringExtra(k: String): String? = extras[k] as? String
    fun getBooleanExtra(k: String, def: Boolean): Boolean = (extras[k] as? Boolean) ?: def
    fun getIntExtra(k: String, def: Int): Int = (extras[k] as? Int) ?: def
    fun removeExtra(k: String) { extras.remove(k) }
    fun addFlags(f: Int): Intent = this
    fun setFlags(f: Int): Intent = this
    fun addCategory(c: String): Intent = this
    fun setType(t: String?): Intent = apply { type = t }
    fun setPackage(p: String?): Intent = apply { pkg = p }
    fun setAction(a: String?): Intent = apply { action = a }
    fun setDataAndType(u: Uri?, t: String?): Intent = apply { data = u; type = t }

    companion object {
        const val ACTION_VIEW = "android.intent.action.VIEW"
        const val ACTION_SEND = "android.intent.action.SEND"
        const val ACTION_GET_CONTENT = "android.intent.action.GET_CONTENT"
        const val ACTION_DIAL = "android.intent.action.DIAL"
        const val ACTION_SENDTO = "android.intent.action.SENDTO"
        const val ACTION_CHOOSER = "android.intent.action.CHOOSER"
        const val EXTRA_TEXT = "android.intent.extra.TEXT"
        const val EXTRA_SUBJECT = "android.intent.extra.SUBJECT"
        const val EXTRA_STREAM = "android.intent.extra.STREAM"
        const val EXTRA_TITLE = "android.intent.extra.TITLE"
        const val EXTRA_ALLOW_MULTIPLE = "android.intent.extra.ALLOW_MULTIPLE"
        const val EXTRA_INITIAL_INTENTS = "android.intent.extra.INITIAL_INTENTS"
        const val CATEGORY_OPENABLE = "android.intent.category.OPENABLE"
        const val FLAG_ACTIVITY_NEW_TASK = 0x10000000
        const val FLAG_ACTIVITY_SINGLE_TOP = 0x20000000
        const val FLAG_ACTIVITY_CLEAR_TOP = 0x04000000
        const val FLAG_GRANT_READ_URI_PERMISSION = 1
        const val FLAG_GRANT_WRITE_URI_PERMISSION = 2

        fun createChooser(target: Intent, title: CharSequence?): Intent =
            Intent(ACTION_CHOOSER).also { it.target = target; it.chooserTitle = title?.toString() }
    }
}
