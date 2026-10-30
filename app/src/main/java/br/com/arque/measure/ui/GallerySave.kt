package br.com.arque.measure.ui

import android.content.ContentValues
import android.content.Context
import android.os.Build
import android.provider.MediaStore
import java.io.File

/** Guarda a foto/vídeo da câmera também na galeria do celular (Imagens/ArqueMeasure e Filmes/ArqueMeasure). */
object GallerySave {
    fun save(ctx: Context, f: File, video: Boolean): Boolean {
        if (Build.VERSION.SDK_INT < 29 || !f.exists() || f.length() == 0L) return false
        return runCatching {
            val cr = ctx.contentResolver
            val cv = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, f.name)
                put(MediaStore.MediaColumns.MIME_TYPE, if (video) "video/mp4" else "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, if (video) "Movies/ArqueMeasure" else "Pictures/ArqueMeasure")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val coll = if (video) MediaStore.Video.Media.EXTERNAL_CONTENT_URI else MediaStore.Images.Media.EXTERNAL_CONTENT_URI
            val uri = cr.insert(coll, cv) ?: return false
            cr.openOutputStream(uri)?.use { o -> f.inputStream().use { it.copyTo(o) } }
            cr.update(uri, ContentValues().apply { put(MediaStore.MediaColumns.IS_PENDING, 0) }, null, null)
            true
        }.getOrDefault(false)
    }
}
