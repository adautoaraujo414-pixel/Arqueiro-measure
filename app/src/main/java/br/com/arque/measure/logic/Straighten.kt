package br.com.arque.measure.logic

import br.com.arque.measure.model.Pt
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.hypot

/**
 * Endireita um traço feito à mão em segmentos retos (paredes), alinhando na horizontal/vertical
 * quando está quase assim e fechando o contorno se o fim encosta no começo.
 * Lógica pura (sem Android), testável na JVM. Unidades: unidades de folha.
 */
object Straighten {
    data class Result(val pts: List<Pt>, val closed: Boolean)

    private enum class Axis { H, V }

    private fun dist(a: Pt, b: Pt) = hypot(b.x - a.x, b.y - a.y)

    private fun perpDist(p: Pt, a: Pt, b: Pt): Float = Geo.distToSegment(p, a, b)

    /** Douglas-Peucker: devolve os índices mantidos entre [lo] e [hi] (inclusive). */
    private fun dp(pts: List<Pt>, lo: Int, hi: Int, eps: Float, keep: MutableSet<Int>) {
        if (hi <= lo + 1) return
        var maxD = -1f
        var idx = -1
        for (i in lo + 1 until hi) {
            val d = perpDist(pts[i], pts[lo], pts[hi])
            if (d > maxD) { maxD = d; idx = i }
        }
        if (maxD > eps && idx > 0) {
            keep += idx
            dp(pts, lo, idx, eps, keep)
            dp(pts, idx, hi, eps, keep)
        }
    }

    private fun axisOf(a: Pt, b: Pt, snapDeg: Float): Axis? {
        val dx = b.x - a.x
        val dy = b.y - a.y
        if (hypot(dx, dy) < 1f) return null
        val ang = Math.toDegrees(atan2(abs(dy), abs(dx)).toDouble()).toFloat()
        return when {
            ang < snapDeg -> Axis.H
            ang > 90f - snapDeg -> Axis.V
            else -> null
        }
    }

    /** Resultado, ou null se o traço é curto demais para virar parede. */
    fun run(
        raw: List<Pt>,
        closeTol: Float = 40f,
        eps: Float = 12f,
        snapDeg: Float = 12f,
        minSeg: Float = 24f,
    ): Result? {
        if (raw.size < 2) return null
        val pathLen = raw.zipWithNext().sumOf { (a, b) -> dist(a, b).toDouble() }.toFloat()
        if (pathLen < minSeg) return null
        val closed = raw.size >= 4 && dist(raw.first(), raw.last()) <= closeTol && pathLen > closeTol * 4f

        // 1) simplifica (Douglas-Peucker)
        var pts: MutableList<Pt>
        if (closed) {
            val ring = raw + raw.first()
            var far = 0
            var fd = -1f
            for (i in 1 until ring.size - 1) {
                val d = dist(ring[i], ring[0])
                if (d > fd) { fd = d; far = i }
            }
            val keep = sortedSetOf(0, far, ring.lastIndex)
            dp(ring, 0, far, eps, keep)
            dp(ring, far, ring.lastIndex, eps, keep)
            pts = keep.map { ring[it] }.toMutableList()
            pts.removeAt(pts.lastIndex) // último == primeiro
        } else {
            val keep = sortedSetOf(0, raw.lastIndex)
            dp(raw, 0, raw.lastIndex, eps, keep)
            pts = keep.map { raw[it] }.toMutableList()
        }

        // 2) remove segmentos minúsculos
        var changed = true
        while (changed && pts.size > 2) {
            changed = false
            val n = pts.size
            val last = if (closed) n else n - 1
            for (i in 0 until last) {
                val j = (i + 1) % n
                if (dist(pts[i], pts[j]) < minSeg && pts.size > (if (closed) 3 else 2)) {
                    // remove o vértice j (preserva o primeiro e o último em traço aberto)
                    val drop = if (!closed && j == n - 1) i else j
                    if (!closed && drop == 0) continue
                    pts.removeAt(drop)
                    changed = true
                    break
                }
            }
        }
        if (closed && pts.size < 3) return null
        if (!closed && pts.size < 2) return null

        // 3) alinha na horizontal/vertical, na sequência dos vértices
        val n = pts.size
        val axes = arrayOfNulls<Axis>(n)
        for (i in 0 until n - 1) {
            val a = pts[i]
            val b = pts[i + 1]
            val ax = axisOf(a, b, snapDeg)
            axes[i] = ax
            when (ax) {
                Axis.H -> pts[i + 1] = Pt(b.x, a.y)
                Axis.V -> pts[i + 1] = Pt(a.x, b.y)
                null -> {}
            }
        }
        if (closed) {
            val a = pts[n - 1]
            val b = pts[0]
            val cAxis = axisOf(a, b, snapDeg)
            val prev = axes[n - 2]
            if (cAxis != null) {
                when {
                    prev == null -> pts[n - 1] = if (cAxis == Axis.H) Pt(a.x, b.y) else Pt(b.x, a.y)
                    prev != cAxis -> {
                        val p = pts[n - 2]
                        pts[n - 1] = if (prev == Axis.H) Pt(b.x, p.y) else Pt(p.x, b.y)
                    }
                    else -> {}
                }
            }
        }
        return Result(pts.toList(), closed)
    }
}
