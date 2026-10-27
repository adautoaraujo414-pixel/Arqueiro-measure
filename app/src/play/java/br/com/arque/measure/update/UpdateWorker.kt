package br.com.arque.measure.update

import android.content.Context

/** Versão do Google Play: sem verificação de versão nova (quem atualiza é a loja). */
class UpdateWorker private constructor() {
    companion object {
        const val CHANNEL = "updates"
        const val EXTRA_UPDATE = "arque.update"
        fun schedule(ctx: Context) {}
        fun notify(ctx: Context, number: Int) {}
    }
}
