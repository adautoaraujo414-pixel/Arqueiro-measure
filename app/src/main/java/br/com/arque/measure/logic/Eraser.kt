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

    /** Contorno de uma forma como linha de pontos (fechada quando é forma fechada). Folha. */
    fun shapeOutline(kind: br.com.arque.measure.model.ShapeKind, a: Pt, b: Pt): List<Pt> {
        val K = br.com.arque.measure.model.ShapeKind
        val l = kotlin.math.min(a.x, b.x); val r = kotlin.math.max(a.x, b.x)
        val t = kotlin.math.min(a.y, b.y); val bt = kotlin.math.max(a.y, b.y)
        fun closed(c: List<Pt>) = c + c.first()
        return when (kind) {
            K.LINE, K.DASHED, K.ARROW, K.DARROW -> listOf(a, b)
            K.CURVE -> Geo.curvePoints(a, b)
            K.ELBOW -> Geo.polyPoints(kind, a, b)!!
            K.RTRI, K.DIAMOND, K.TRAP -> closed(Geo.polyPoints(kind, a, b)!!)
            K.TRIANGLE -> closed(listOf(Pt((l + r) / 2f, t), Pt(r, bt), Pt(l, bt)))
            K.RECT, K.RRECT -> closed(listOf(Pt(l, t), Pt(r, t), Pt(r, bt), Pt(l, bt)))
            K.ELLIPSE -> {
                val cx = (a.x + b.x) / 2f; val cy = (a.y + b.y) / 2f
                val rx = kotlin.math.abs(b.x - a.x) / 2f; val ry = kotlin.math.abs(b.y - a.y) / 2f
                (0..64).map { val q = it / 64.0 * 2 * Math.PI; Pt(cx + rx * kotlin.math.cos(q).toFloat(), cy + ry * kotlin.math.sin(q).toFloat()) }
            }
        }
    }

    /**
     * Contorno de cômodo depois de passar a borracha: tira os trechos (paredes) tocados e devolve o resto
     * como contornos abertos, cada um com as suas medidas. null = não tocou. Pontos [pts] na folha.
     */
    fun roomPieces(o: br.com.arque.measure.model.RoomObj, pts: List<Pt>, c: Pt, r: Float): List<Pair<List<Int>, List<Int>>>? {
        val n = o.segCount()
        if (n <= 0) return null
        val hit = (0 until n).map { k -> Geo.distToSegment(c, pts[k], pts[(k + 1) % pts.size]) <= r }
        if (hit.none { it }) return null
        // ordem dos trechos: num contorno fechado começa logo depois de um trecho apagado
        val order = if (o.closed) { val f = hit.indexOfFirst { it }; (1..n).map { (f + it) % n } } else (0 until n).toList()
        val out = mutableListOf<Pair<List<Int>, List<Int>>>()
        var segs = mutableListOf<Int>()
        fun flush() {
            if (segs.isNotEmpty()) {
                val verts = segs.map { it } + ((segs.last() + 1) % pts.size)
                out += verts to segs.toList()
            }
            segs = mutableListOf()
        }
        for (k in order) { if (hit[k]) flush() else segs += k }
        flush()
        return out
    }
}
