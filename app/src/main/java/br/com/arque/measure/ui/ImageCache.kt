package br.com.arque.measure.ui

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.util.LruCache
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.exifinterface.media.ExifInterface
import br.com.arque.measure.data.Store
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import kotlin.math.max

/**
 * Decodifica fotos para exibição sem tocar no arquivo original (que fica intacto em disco).
 * A tela usa uma versão reduzida para caber na memória; a exportação lê em resolução maior.
 */
class ImageCache(private val store: Store, private val scope: CoroutineScope) {
    /** Incrementa quando uma foto termina de carregar, para redesenhar o canvas. */
    var version by mutableIntStateOf(0)
        private set

    private val cache = object : LruCache<String, Bitmap>(
        (Runtime.getRuntime().maxMemory() / 5).toInt().coerceAtLeast(32 * 1024 * 1024),
    ) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }
    private val loading = HashSet<String>()
    private val failed = HashSet<String>()

    /** Retorna a imagem já carregada, ou null (e agenda o carregamento em segundo plano). */
    fun get(file: String, maxSide: Int = DISPLAY_MAX_SIDE): Bitmap? {
        val key = "$file@$maxSide"
        cache.get(key)?.let { return it }
        if (key in failed) return null
        if (loading.add(key)) {
            scope.launch(Dispatchers.IO) {
                val bmp = decode(store.imageFile(file), maxSide)
                withContext(Dispatchers.Main) {
                    if (bmp != null) cache.put(key, bmp) else failed.add(key)
                    loading.remove(key)
                    version++
                }
            }
        }
        return null
    }

    /** Leitura síncrona em alta resolução para exportação (não entra no cache). */
    fun getBlocking(file: String, maxSide: Int = EXPORT_MAX_SIDE): Bitmap? =
        decode(store.imageFile(file), maxSide)

    companion object {
        const val DISPLAY_MAX_SIDE = 2560
        const val EXPORT_MAX_SIDE = 3500

        private fun orientation(f: File): Int = try {
            ExifInterface(f.absolutePath).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }

        fun decode(f: File, maxSide: Int): Bitmap? {
            if (!f.exists()) return null
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(f.absolutePath, bounds)
                var sample = 1
                while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
                val opts = BitmapFactory.Options().apply { inSampleSize = sample }
                val bmp = BitmapFactory.decodeFile(f.absolutePath, opts) ?: return null
                val m = Matrix()
                when (orientation(f)) {
                    ExifInterface.ORIENTATION_ROTATE_90 -> m.postRotate(90f)
                    ExifInterface.ORIENTATION_ROTATE_180 -> m.postRotate(180f)
                    ExifInterface.ORIENTATION_ROTATE_270 -> m.postRotate(270f)
                    ExifInterface.ORIENTATION_FLIP_HORIZONTAL -> m.postScale(-1f, 1f)
                    ExifInterface.ORIENTATION_FLIP_VERTICAL -> m.postScale(1f, -1f)
                    ExifInterface.ORIENTATION_TRANSPOSE -> { m.postRotate(90f); m.postScale(-1f, 1f) }
                    ExifInterface.ORIENTATION_TRANSVERSE -> { m.postRotate(270f); m.postScale(-1f, 1f) }
                }
                if (m.isIdentity) bmp else Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
            } catch (_: Throwable) {
                null
            }
        }

        /** Tamanho em pixels da foto original já considerando a orientação EXIF. */
        fun orientedSize(f: File): Pair<Int, Int>? {
            val o = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(f.absolutePath, o)
            if (o.outWidth <= 0 || o.outHeight <= 0) return null
            return when (orientation(f)) {
                ExifInterface.ORIENTATION_ROTATE_90, ExifInterface.ORIENTATION_ROTATE_270,
                ExifInterface.ORIENTATION_TRANSPOSE, ExifInterface.ORIENTATION_TRANSVERSE,
                -> o.outHeight to o.outWidth
                else -> o.outWidth to o.outHeight
            }
        }
    }
}
