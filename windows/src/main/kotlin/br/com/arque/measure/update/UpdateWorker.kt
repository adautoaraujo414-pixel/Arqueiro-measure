package br.com.arque.measure.update

import android.content.Context

/** No Windows a procura de versão nova acontece ao abrir o app (AppViewModel.autoCheckUpdate). */
object UpdateWorker {
    const val CHANNEL = "updates"
    const val EXTRA_UPDATE = "arque.update"
    fun schedule(@Suppress("UNUSED_PARAMETER") ctx: Context) {}
}
