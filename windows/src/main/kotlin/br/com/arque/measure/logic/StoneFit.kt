package br.com.arque.measure.logic

import br.com.arque.measure.model.Pt
import kotlin.math.abs
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Pedra: o desenho segue as medidas. Cada lado medido fica do tamanho proporcional à medida
 * (medida maior = lado maior, na mesma escala), os ângulos do desenho ficam como estão e,
 * no contorno fechado, os lados ainda sem medida esticam ou encolhem pra fechar a pedra.
 * Também confere se as medidas fecham (precisão) e calcula os lados que faltam.
 * Lógica pura (sem Android), testável na JVM. Unidades: unidades de folha e mm.
 */
object StoneFit {
    data class Check(
        /** Quanto as medidas deixam de fechar (mm) na direção de cada eixo do desenho; null se ainda faltam lados. */
        val gapX: Double?,
        val gapY: Double?,
        /** Lado sem medida → quanto ele dá pelas outras medidas (mm), só quando dá pra saber com certeza. */
        val derived: Map<Int, Double>,
        val missing: Int,
    )

    private fun dirs(pts: List<Pt>, closed: Boolean): List<DoubleArray> {
        val n = if (closed) pts.size else pts.size - 1
        return (0 until n).map { k ->
            val a = pts[k]
            val b = pts[(k + 1) % pts.size]
            val dx = (b.x - a.x).toDouble()
            val dy = (b.y - a.y).toDouble()
            val l = hypot(dx, dy)
            if (l < 1e-6) doubleArrayOf(1.0, 0.0, 0.0) else doubleArrayOf(dx / l, dy / l, l)
        }
    }

    /**
     * Ajusta [w] (comprimentos) dos lados [free] pra soma Σ w·d fechar (contorno fechado).
     * Mínima mudança relativa: cada lado muda na proporção do tamanho dele.
     */
    private fun close(d: List<DoubleArray>, w: DoubleArray, free: List<Int>) {
        if (free.isEmpty()) return
        var ex = 0.0
        var ey = 0.0
        for (k in d.indices) { ex += w[k] * d[k][0]; ey += w[k] * d[k][1] }
        var a = 0.0
        var b = 0.0
        var c = 0.0
        for (k in free) {
            val q = max(w[k], 1e-3).let { it * it }
            a += q * d[k][0] * d[k][0]; b += q * d[k][0] * d[k][1]; c += q * d[k][1] * d[k][1]
        }
        val det = a * c - b * b
        if (abs(det) > 1e-9 * max(1.0, a * c)) {
            val lx = (-ex * c + ey * b) / det
            val ly = (ex * b - ey * a) / det
            for (k in free) {
                val q = max(w[k], 1e-3).let { it * it }
                w[k] += q * (d[k][0] * lx + d[k][1] * ly)
            }
        } else {
            // todos os lados livres na mesma direção: fecha só nessa direção
            val ux = d[free[0]][0]
            val uy = d[free[0]][1]
            var den = 0.0
            for (k in free) { val q = max(w[k], 1e-3).let { it * it }; val s = d[k][0] * ux + d[k][1] * uy; den += q * s * s }
            if (den > 1e-12) {
                val lam = -(ex * ux + ey * uy) / den
                for (k in free) { val q = max(w[k], 1e-3).let { it * it }; w[k] += q * (d[k][0] * ux + d[k][1] * uy) * lam }
            }
        }
    }

    /**
     * Novo desenho da pedra pelas medidas. [mm] tem um item por lado (null = ainda sem medida).
     * Devolve null quando não há nada pra ajustar (nenhum lado medido).
     */
    fun fit(pts: List<Pt>, closed: Boolean, mm: List<Double?>): List<Pt>? {
        val d = dirs(pts, closed)
        val n = d.size
        if (n < 1 || mm.size < n) return null
        val meas = (0 until n).filter { mm[it] != null && mm[it]!! > 0.0 }
        if (meas.isEmpty()) return null
        val cur = meas.sumOf { d[it][2] }
        val tot = meas.sumOf { mm[it]!! }
        if (cur <= 1e-6 || tot <= 1e-6) return null
        val s = cur / tot // unidades de folha por mm (o tamanho da pedra na folha fica parecido)
        val w = DoubleArray(n) { k -> if (k in meas) mm[k]!! * s else d[k][2] }
        if (closed) {
            val free = (0 until n).filter { it !in meas }
            close(d, w, free)
            for (k in free) if (w[k] < 1.0) w[k] = 1.0
            // medidas que não fecham (ex.: 11 mm a mais em cima): reparte em todos os lados, sem mexer nos ângulos
            close(d, w, (0 until n).toList())
        }
        // monta os pontos a partir do primeiro canto
        val out = ArrayList<Pt>(pts.size)
        var x = pts[0].x.toDouble()
        var y = pts[0].y.toDouble()
        out += Pt(x.toFloat(), y.toFloat())
        val last = if (closed) n - 1 else n
        for (k in 0 until last) {
            x += w[k] * d[k][0]; y += w[k] * d[k][1]
            out += Pt(x.toFloat(), y.toFloat())
        }
        if (closed) {
            // o que sobrar (medidas que não fecham) vai repartido nos cantos, sem abrir a pedra
            val ex = x + w[n - 1] * d[n - 1][0] - pts[0].x
            val ey = y + w[n - 1] * d[n - 1][1] - pts[0].y
            if (abs(ex) > 1e-6 || abs(ey) > 1e-6) {
                val tl = w.sum().coerceAtLeast(1e-6)
                var acc = 0.0
                for (i in 1 until out.size) {
                    acc += w[i - 1]
                    val f = acc / tl
                    out[i] = Pt((out[i].x - ex * f).toFloat(), (out[i].y - ey * f).toFloat())
                }
            }
        }
        // mantém a pedra no mesmo lugar da folha (centro do contorno)
        fun ctr(p: List<Pt>): Pair<Double, Double> {
            var x0 = Double.MAX_VALUE; var x1 = -Double.MAX_VALUE; var y0 = Double.MAX_VALUE; var y1 = -Double.MAX_VALUE
            p.forEach { q -> x0 = minOf(x0, q.x.toDouble()); x1 = maxOf(x1, q.x.toDouble()); y0 = minOf(y0, q.y.toDouble()); y1 = maxOf(y1, q.y.toDouble()) }
            return ((x0 + x1) / 2) to ((y0 + y1) / 2)
        }
        val (ax, ay) = ctr(pts)
        val (bx, by) = ctr(out)
        return out.map { Pt((it.x + (ax - bx)).toFloat(), (it.y + (ay - by)).toFloat()) }
    }

    /**
     * Conferência das medidas (precisão): no contorno fechado, quanto falta pra fechar em cada direção
     * e, quando só falta um lado numa direção, quanto ele tem que dar.
     */
    fun check(pts: List<Pt>, closed: Boolean, mm: List<Double?>): Check {
        val d = dirs(pts, closed)
        val n = d.size
        val missing = (0 until n).count { k -> mm.getOrNull(k)?.let { it > 0.0 } != true }
        if (!closed || n < 3) return Check(null, null, emptyMap(), missing)
        // eixo de cada lado: H (deitado), V (em pé) ou inclinado
        fun axis(k: Int): Int = when {
            abs(d[k][1]) < 0.17 -> 0
            abs(d[k][0]) < 0.17 -> 1
            else -> -1
        }
        val derived = HashMap<Int, Double>()
        var gx: Double? = null
        var gy: Double? = null
        for (ax in 0..1) {
            val ks = (0 until n).filter { axis(it) == ax }
            if (ks.isEmpty() || (0 until n).any { axis(it) == -1 }) continue
            val sign = { k: Int -> if (d[k][ax] >= 0) 1.0 else -1.0 }
            val open = ks.filter { mm.getOrNull(it)?.let { v -> v > 0.0 } != true }
            val sum = ks.filter { it !in open }.sumOf { sign(it) * mm[it]!! }
            when (open.size) {
                0 -> { if (ax == 0) gx = abs(sum) else gy = abs(sum) }
                1 -> { val k = open[0]; val v = -sum * sign(k); if (v > 0.0) derived[k] = v }
            }
        }
        return Check(gx, gy, derived, missing)
    }

    /** Texto curto da conferência, pro painel. */
    fun summary(c: Check, fmt: (Double) -> String): String? {
        val parts = ArrayList<String>()
        val gx = c.gapX
        val gy = c.gapY
        if (gx != null || gy != null) {
            val bad = listOfNotNull(gx?.takeIf { it >= 1.0 }?.let { "${it.roundToInt()} mm " + br.com.arque.measure.i18n.tr("deitado") }, gy?.takeIf { it >= 1.0 }?.let { "${it.roundToInt()} mm " + br.com.arque.measure.i18n.tr("em pé") })
            parts += if (bad.isEmpty()) br.com.arque.measure.i18n.tr("✓ As medidas fecham certinho") else br.com.arque.measure.i18n.tr("⚠ As medidas não fecham: sobra {0}. Confira antes de cortar.", bad.joinToString(" e "))
        }
        c.derived.toSortedMap().forEach { (k, v) -> parts += br.com.arque.measure.i18n.tr("Lado {0} dá {1} pelas outras medidas", k + 1, fmt(v)) }
        return if (parts.isEmpty()) null else parts.joinToString("\n")
    }
}
