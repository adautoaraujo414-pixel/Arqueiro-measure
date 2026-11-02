@file:Suppress("unused")

package androidx.exifinterface.media

import java.io.File
import java.io.RandomAccessFile

/** Só o que o app usa do EXIF: a orientação da foto (JPEG). */
class ExifInterface(path: String) {
    private val orientation: Int = runCatching { readOrientation(File(path)) }.getOrDefault(ORIENTATION_NORMAL)

    fun getAttributeInt(tag: String, def: Int): Int = if (tag == TAG_ORIENTATION) orientation else def

    companion object {
        const val TAG_ORIENTATION = "Orientation"
        const val ORIENTATION_UNDEFINED = 0
        const val ORIENTATION_NORMAL = 1
        const val ORIENTATION_FLIP_HORIZONTAL = 2
        const val ORIENTATION_ROTATE_180 = 3
        const val ORIENTATION_FLIP_VERTICAL = 4
        const val ORIENTATION_TRANSPOSE = 5
        const val ORIENTATION_ROTATE_90 = 6
        const val ORIENTATION_TRANSVERSE = 7
        const val ORIENTATION_ROTATE_270 = 8

        private fun readOrientation(f: File): Int {
            RandomAccessFile(f, "r").use { r ->
                val n = minOf(r.length(), 256 * 1024L).toInt()
                val b = ByteArray(n)
                r.readFully(b)
                if (n < 4 || (b[0].toInt() and 0xFF) != 0xFF || (b[1].toInt() and 0xFF) != 0xD8) return ORIENTATION_NORMAL
                var i = 2
                while (i + 4 < n) {
                    if ((b[i].toInt() and 0xFF) != 0xFF) return ORIENTATION_NORMAL
                    val marker = b[i + 1].toInt() and 0xFF
                    val len = ((b[i + 2].toInt() and 0xFF) shl 8) or (b[i + 3].toInt() and 0xFF)
                    if (marker == 0xE1 && i + 10 < n && String(b, i + 4, 4, Charsets.ISO_8859_1) == "Exif") {
                        val t = i + 10
                        val le = b[t] == 'I'.code.toByte()
                        fun u16(p: Int) = if (le) (b[p].toInt() and 0xFF) or ((b[p + 1].toInt() and 0xFF) shl 8) else ((b[p].toInt() and 0xFF) shl 8) or (b[p + 1].toInt() and 0xFF)
                        fun u32(p: Int) = if (le) u16(p) or (u16(p + 2) shl 16) else (u16(p) shl 16) or u16(p + 2)
                        val ifd = t + u32(t + 4)
                        if (ifd + 2 > n) return ORIENTATION_NORMAL
                        val cnt = u16(ifd)
                        for (k in 0 until cnt) {
                            val e = ifd + 2 + k * 12
                            if (e + 12 > n) break
                            if (u16(e) == 0x0112) return u16(e + 8).takeIf { it in 1..8 } ?: ORIENTATION_NORMAL
                        }
                        return ORIENTATION_NORMAL
                    }
                    if (marker == 0xDA) return ORIENTATION_NORMAL
                    i += 2 + len
                }
            }
            return ORIENTATION_NORMAL
        }
    }
}
