package br.com.arque.measure.ui

import android.view.MotionEvent

/**
 * Rejeição de palma: a Activity mostra cada toque aqui antes da tela. Contato grande (mão, punho)
 * ou marcado pelo sistema como palma fica guardado, e a tela do caderno ignora qualquer toque
 * que caia em cima dele. Caneta nunca é palma.
 */
object PalmGuard {
    private class Pt(var x: Float, var y: Float, var palm: Boolean)
    private val live = HashMap<Int, Pt>()
    /** px por mm da tela (definido pela Activity). */
    @Volatile var pxPerMm = 6.3f

    /** Contato maior que isso (mm) é mão/punho. Dedo fica entre 6 e 12 mm. */
    private const val PALM_MM = 17f
    private const val TOOL_TYPE_PALM = 5

    @Synchronized
    fun record(ev: MotionEvent) {
        val a = ev.actionMasked
        if (a == MotionEvent.ACTION_CANCEL) { live.clear(); return }
        for (i in 0 until ev.pointerCount) {
            val id = ev.getPointerId(i)
            val tt = ev.getToolType(i)
            if (tt == MotionEvent.TOOL_TYPE_STYLUS || tt == MotionEvent.TOOL_TYPE_ERASER) { live.remove(id); continue }
            val big = tt == TOOL_TYPE_PALM || ev.getTouchMajor(i) > PALM_MM * pxPerMm ||
                (ev.getSize(i) > 0.55f && ev.getTouchMajor(i) <= 0f)
            val p = live.getOrPut(id) { Pt(ev.getX(i), ev.getY(i), false) }
            p.x = ev.getX(i); p.y = ev.getY(i)
            if (big) p.palm = true
        }
        if (a == MotionEvent.ACTION_UP) live.clear()
        else if (a == MotionEvent.ACTION_POINTER_UP) live.remove(ev.getPointerId(ev.actionIndex))
    }

    /** O toque nesse ponto (coordenadas da janela) é mão apoiada? */
    @Synchronized
    fun isPalm(x: Float, y: Float): Boolean {
        val tol = 6f * pxPerMm
        return live.values.any { it.palm && kotlin.math.hypot(it.x - x, it.y - y) <= tol }
    }
}
