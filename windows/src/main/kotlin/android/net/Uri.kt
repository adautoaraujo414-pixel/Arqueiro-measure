package android.net

import java.io.File
import java.net.URI
import java.net.URLDecoder
import java.net.URLEncoder

/** Uri do Android: no Windows quase sempre é um arquivo escolhido pelo usuário (file:) ou um link. */
class Uri private constructor(private val s: String) {
    private val u: URI? = runCatching { URI(s) }.getOrNull()

    val scheme: String? get() = u?.scheme ?: if (s.contains(':')) s.substringBefore(':') else null
    val host: String? get() = u?.host
    val path: String? get() = u?.path
    val query: String? get() = u?.rawQuery
    val lastPathSegment: String? get() = path?.trimEnd('/')?.substringAfterLast('/')
    val schemeSpecificPart: String? get() = u?.schemeSpecificPart ?: s.substringAfter(':', "")

    fun getQueryParameter(name: String): String? {
        val q = u?.rawQuery ?: return null
        for (kv in q.split('&')) {
            val k = kv.substringBefore('=')
            if (URLDecoder.decode(k, "UTF-8") == name) return URLDecoder.decode(kv.substringAfter('=', ""), "UTF-8")
        }
        return null
    }

    /** O arquivo por trás do Uri (file:), se houver. */
    fun file(): File? = if (scheme == "file") runCatching { File(URI(s)) }.getOrNull() else null

    override fun toString() = s
    override fun equals(other: Any?) = other is Uri && other.s == s
    override fun hashCode() = s.hashCode()

    companion object {
        @JvmField val EMPTY = Uri("")
        @JvmStatic fun parse(s: String): Uri = Uri(s)
        @JvmStatic fun fromFile(f: File): Uri = Uri(f.absoluteFile.toURI().toString())
        @JvmStatic fun encode(s: String?): String? = s?.let { URLEncoder.encode(it, "UTF-8").replace("+", "%20") }
        @JvmStatic fun decode(s: String?): String? = s?.let { URLDecoder.decode(it, "UTF-8") }
    }
}
