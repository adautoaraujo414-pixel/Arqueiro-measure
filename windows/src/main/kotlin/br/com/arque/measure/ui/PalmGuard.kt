package br.com.arque.measure.ui

/** No computador não há palma apoiada na tela: nada é ignorado. */
object PalmGuard {
    @Volatile var pxPerMm = 3.78f
    @Suppress("UNUSED_PARAMETER")
    fun isPalm(x: Float, y: Float): Boolean = false
}
