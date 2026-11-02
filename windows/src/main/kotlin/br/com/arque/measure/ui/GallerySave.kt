package br.com.arque.measure.ui

import android.content.Context
import br.com.arque.measure.desktop.Paths
import java.io.File

/** Guarda uma cópia em Imagens\Arquemestre (a "galeria" do Windows). */
object GallerySave {
    fun save(@Suppress("UNUSED_PARAMETER") ctx: Context, f: File, @Suppress("UNUSED_PARAMETER") video: Boolean): Boolean {
        if (!f.exists() || f.length() == 0L) return false
        return runCatching { Paths.pictures.mkdirs(); f.copyTo(File(Paths.pictures, f.name), overwrite = true); true }.getOrDefault(false)
    }
}
