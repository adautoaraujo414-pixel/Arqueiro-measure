package br.com.arque.measure.license

import android.app.Activity
import android.content.Context

/** APK do site: não há compra pela loja (desbloqueio é por senha). */
object StoreBilling {
    const val AVAILABLE = false
    fun start(ctx: Context, onChange: () -> Unit) {}
    fun price(): String? = null
    fun buy(activity: Activity, onMsg: (String) -> Unit) {}
    fun restore(ctx: Context, onMsg: (String) -> Unit) {}
}
