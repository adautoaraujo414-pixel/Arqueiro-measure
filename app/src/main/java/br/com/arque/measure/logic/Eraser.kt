package br.com.arque.measure.logic

import br.com.arque.measure.model.Pt
import kotlin.math.ceil
import kotlin.math.hypot

/** Borracha de pixels: tira o pedaço do traço sob o círculo e divide o resto em pedaços. */
object Eraser {
    /** Insere pontos intermediários para que nenhum passo seja maior que [step]. */
    fun densify(pts: List<Pt>, step: Float): List<Pt> {
        if (pts.size < 2) return pts
        val out = ArrayList<Pt>(pts.size)
        out += pts[0]
        for (i in 1 until pts.size) {
            val a = pts[i - 1]; val b = pts[i]
            val d = hypot(b.x - a.x, b.y - a.y)
            val n = ceil(d / step).toInt().coerceAtLeast(1)
            for (k in 1..n) {
                val t = k / n.toFloat()
                out += Pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
            }
        }
        return out
    }

    /**
     * Pedaços do traço que sobram depois de apagar o círculo (centro [c], raio [r]).
     * Retorna null se o traço não foi tocado (nada a mudar); lista vazia se sumiu inteiro.
     */
    fun erasePieces(pts: List<Pt>, c: Pt, r: Float): List<List<Pt>>? {
        val touched = if (pts.size == 1) hypot(pts[0].x - c.x, pts[0].y - c.y) <= r
        else pts.zipWithNext().any { (a, b) -> Geo.distToSegment(c, a, b) <= r }
        if (!touched) return null
        val dense = densify(pts, (r / 3f).coerceAtLeast(1.5f))
        val pieces = mutableListOf<List<Pt>>()
        var cur = ArrayList<Pt>()
        for (p in dense) {
            if (hypot(p.x - c.x, p.y - c.y) <= r) {
                if (cur.size >= 2) pieces += cur
                cur = ArrayList()
            } else cur += p
        }
        if (cur.size >= 2) pieces += cur
        return pieces
    }
}
