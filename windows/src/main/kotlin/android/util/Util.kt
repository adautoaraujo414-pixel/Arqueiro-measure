@file:Suppress("unused")

package android.util

/** LruCache do Android (mesma regra: tamanho total, tira o menos usado). */
open class LruCache<K : Any, V : Any>(private var maxSize: Int) {
    private val map = LinkedHashMap<K, V>(0, 0.75f, true)
    private var size = 0

    protected open fun sizeOf(key: K, value: V): Int = 1
    protected open fun entryRemoved(evicted: Boolean, key: K, oldValue: V, newValue: V?) {}

    @Synchronized fun get(key: K): V? = map[key]

    fun put(key: K, value: V): V? {
        val prev: V?
        synchronized(this) {
            size += sizeOf(key, value)
            prev = map.put(key, value)
            if (prev != null) size -= sizeOf(key, prev)
        }
        if (prev != null) entryRemoved(false, key, prev, value)
        trimToSize(maxSize)
        return prev
    }

    fun remove(key: K): V? {
        val prev = synchronized(this) { map.remove(key)?.also { size -= sizeOf(key, it) } }
        if (prev != null) entryRemoved(false, key, prev, null)
        return prev
    }

    fun trimToSize(max: Int) {
        while (true) {
            val e: Map.Entry<K, V>
            synchronized(this) {
                if (size <= max || map.isEmpty()) return
                e = map.entries.iterator().next()
                map.remove(e.key)
                size -= sizeOf(e.key, e.value)
            }
            entryRemoved(true, e.key, e.value, null)
        }
    }

    fun evictAll() = trimToSize(-1)
    @Synchronized fun size(): Int = size
    @Synchronized fun maxSize(): Int = maxSize
    @Synchronized fun snapshot(): Map<K, V> = LinkedHashMap(map)
}

object Base64 {
    const val DEFAULT = 0
    const val NO_WRAP = 2
    const val URL_SAFE = 8
    const val NO_PADDING = 1
    @JvmStatic fun decode(s: String, flags: Int): ByteArray =
        if (flags and URL_SAFE != 0) java.util.Base64.getUrlDecoder().decode(s.trim()) else java.util.Base64.getMimeDecoder().decode(s.trim())
    @JvmStatic fun decode(b: ByteArray, flags: Int): ByteArray = decode(String(b, Charsets.ISO_8859_1), flags)
    @JvmStatic fun encodeToString(b: ByteArray, flags: Int): String {
        var e = if (flags and URL_SAFE != 0) java.util.Base64.getUrlEncoder() else java.util.Base64.getEncoder()
        if (flags and NO_PADDING != 0) e = e.withoutPadding()
        return e.encodeToString(b)
    }
}

object Log {
    @JvmStatic fun d(tag: String?, msg: String?): Int { if (System.getProperty("arque.debug") != null) println("D/$tag: $msg"); return 0 }
    @JvmStatic fun i(tag: String?, msg: String?): Int = d(tag, msg)
    @JvmStatic fun w(tag: String?, msg: String?): Int { System.err.println("W/$tag: $msg"); return 0 }
    @JvmStatic fun e(tag: String?, msg: String?): Int { System.err.println("E/$tag: $msg"); return 0 }
    @JvmStatic fun e(tag: String?, msg: String?, t: Throwable?): Int { System.err.println("E/$tag: $msg $t"); return 0 }
}
