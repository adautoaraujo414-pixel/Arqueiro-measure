package br.com.arque.measure

import android.app.Application
import br.com.arque.measure.i18n.I18n

/** Carrega o idioma antes de qualquer tela, aviso ou serviço do app. */
class ArqueApp : Application() {
    override fun onCreate() {
        super.onCreate()
        I18n.init(this)
        // se o app foi fechado no meio de um compartilhamento, o Bluetooth volta a ter o nome original
        br.com.arque.measure.share.BtShare.restoreName(this)
    }
}
