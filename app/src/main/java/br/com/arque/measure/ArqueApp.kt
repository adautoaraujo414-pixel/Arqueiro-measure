package br.com.arque.measure

import android.app.Application
import br.com.arque.measure.i18n.I18n

/** Carrega o idioma antes de qualquer tela, aviso ou serviço do app. */
class ArqueApp : Application() {
    override fun onCreate() {
        super.onCreate()
        I18n.init(this)
    }
}
