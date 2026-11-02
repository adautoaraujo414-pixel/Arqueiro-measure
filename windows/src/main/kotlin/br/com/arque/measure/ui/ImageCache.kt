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
import kotlinx.coroutines.asCoroutineDispatcher
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
        (Runtime.getRuntime().maxMemory() / 4).toInt().coerceAtLeast(48 * 1024 * 1024),
    ) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }
    private val loading = HashSet<String>()
    /** Falhas: chave -> (tentativas, hora da última). Tenta de novo depois de um tempo. */
    private val failed = HashMap<String, Pair<Int, Long>>()

    /** No máximo 2 fotos decodificando ao mesmo tempo: não trava o resto do app. */
    private val decoder = java.util.concurrent.Executors.newFixedThreadPool(2).asCoroutineDispatcher()

    /** Retorna a imagem já carregada, ou null (e agenda o carregamento em segundo plano). */
    fun get(file: String, maxSide: Int = DISPLAY_MAX_SIDE): Bitmap? {
        val key = "$file@$maxSide"
        cache.get(key)?.let { return it }
        failed[key]?.let { (n, t) ->
            if (n >= 3 || android.os.SystemClock.uptimeMillis() - t < 2000L) return null
        }
        if (loading.add(key)) {
            scope.launch(decoder) {
                val bmp = decode(store.imageFile(file), maxSide)
                withContext(Dispatchers.Main) {
                    if (bmp != null) { cache.put(key, bmp); failed.remove(key) }
                    else { val n = (failed[key]?.first ?: 0) + 1; failed[key] = n to android.os.SystemClock.uptimeMillis() }
                    loading.remove(key)
                    version++
                }
            }
        }
        return null
    }

    /** Só o que já está na memória (sem carregar): seguro fora da thread principal. */
    fun peek(file: String, maxSide: Int = DISPLAY_MAX_SIDE): Bitmap? = cache.get("$file@$maxSide")

    /** Leitura síncrona em alta resolução para exportação (não entra no cache). */
    fun getBlocking(file: String, maxSide: Int = EXPORT_MAX_SIDE): Bitmap? =
        decode(store.imageFile(file), maxSide, forDisplay = false)

    companion object {
        /** Na tela basta 1600 px: leve na memória e rápido de desenhar (o arquivo original fica intacto). */
        const val DISPLAY_MAX_SIDE = 1600
        const val EXPORT_MAX_SIDE = 3500

        private fun orientation(f: File): Int = try {
            ExifInterface(f.absolutePath).getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL)
        } catch (_: Exception) {
            ExifInterface.ORIENTATION_NORMAL
        }

        fun decode(f: File, maxSide: Int, forDisplay: Boolean = true): Bitmap? {
            if (!f.exists()) return null
            return try {
                val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                BitmapFactory.decodeFile(f.absolutePath, bounds)
                if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null
                var sample = 1
                while (max(bounds.outWidth, bounds.outHeight) / (sample * 2) >= maxSide) sample *= 2
                val png = bounds.outMimeType == "image/png" || bounds.outMimeType == "image/webp"
                val opts = BitmapFactory.Options().apply {
                    inSampleSize = sample
                    // foto sem transparência na tela: metade da memória
                    if (forDisplay && !png) inPreferredConfig = Bitmap.Config.RGB_565
                }
                var bmp = BitmapFactory.decodeFile(f.absolutePath, opts) ?: return null
                val big = max(bmp.width, bmp.height)
                if (big > maxSide) {
                    val k = maxSide.toFloat() / big
                    val sc = Bitmap.createScaledBitmap(bmp, (bmp.width * k).toInt().coerceAtLeast(1), (bmp.height * k).toInt().coerceAtLeast(1), true)
                    if (sc != bmp) bmp.recycle()
                    bmp = sc
                }
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
                if (m.isIdentity) bmp else Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true).also { if (it != bmp) bmp.recycle() }
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
