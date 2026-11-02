package br.com.arque.measure.logic

import br.com.arque.measure.i18n.tr

import kotlin.math.max

/**
 * Plano de corte para esquadrejadeira: só cortes retos que atravessam o retângulo inteiro (guilhotina),
 * descontando a espessura da serra. Sem CNC, sem furação. Lógica pura (JVM), medidas em mm.
 */
object CutOptimizer {
    data class Piece(val label: String, val w: Double, val h: Double)

    data class Placed(val label: String, val x: Double, val y: Double, val w: Double, val h: Double, val rotated: Boolean)

    /** Um corte da serra: [vertical] = linha vertical na vista da chapa, [pos] a partir da origem do retângulo cortado. */
    data class Cut(val step: Int, val vertical: Boolean, val pos: Double, val rectW: Double, val rectH: Double)

    class Sheet(val w: Double, val h: Double) {
        val placed = ArrayList<Placed>()
        val cuts = ArrayList<Cut>()
        internal val free = ArrayList<R>()
        init { free += R(0.0, 0.0, w, h) }
        val usedArea: Double get() = placed.sumOf { it.w * it.h }
        val usage: Double get() = if (w * h <= 0.0) 0.0 else usedArea / (w * h)
    }

    internal data class R(val x: Double, val y: Double, val w: Double, val h: Double) {
        val area get() = w * h
    }

    data class Result(val sheets: List<Sheet>, val tooBig: List<Piece>)

    /**
     * [pieces] já expandidas (uma entrada por peça). [kerf] = espessura da serra.
     * [rotate] permite girar 90° (desligue se o veio da chapa importa).
     */
    fun run(pieces: List<Piece>, sheetW: Double, sheetH: Double, kerf: Double, rotate: Boolean): Result {
        val sheets = ArrayList<Sheet>()
        val tooBig = ArrayList<Piece>()
        val sorted = pieces.filter { it.w > 0.0 && it.h > 0.0 }
            .sortedWith(compareByDescending<Piece> { max(it.w, it.h) }.thenByDescending { it.w * it.h })
        for (p in sorted) {
            val fitsSheet = (p.w <= sheetW && p.h <= sheetH) || (rotate && p.h <= sheetW && p.w <= sheetH)
            if (!fitsSheet) { tooBig += p; continue }
            var best: Triple<Sheet, Int, Boolean>? = null
            var bestScore = Double.MAX_VALUE
            for (s in sheets) {
                for ((i, f) in s.free.withIndex()) {
                    for (rot in if (rotate) listOf(false, true) else listOf(false)) {
                        val pw = if (rot) p.h else p.w
                        val ph = if (rot) p.w else p.h
                        if (pw <= f.w + 1e-6 && ph <= f.h + 1e-6) {
                            val score = f.area - pw * ph
                            if (score < bestScore) { bestScore = score; best = Triple(s, i, rot) }
                        }
                    }
                }
            }
            if (best == null) {
                val s = Sheet(sheetW, sheetH)
                sheets += s
                val rot = !(p.w <= sheetW && p.h <= sheetH)
                best = Triple(s, 0, rot)
            }
            place(best.first, best.second, p, best.third, kerf)
        }
        return Result(sheets, tooBig)
    }

    private fun place(s: Sheet, idx: Int, p: Piece, rot: Boolean, kerf: Double) {
        val f = s.free.removeAt(idx)
        val pw = if (rot) p.h else p.w
        val ph = if (rot) p.w else p.h
        s.placed += Placed(p.label, f.x, f.y, pw, ph, rot)
        val dw = f.w - pw
        val dh = f.h - ph
        // opção A: corta na vertical primeiro (faixa da largura da peça); opção B: na horizontal primeiro
        val aRight = R(f.x + pw + kerf, f.y, f.w - pw - kerf, f.h)
        val aBottom = R(f.x, f.y + ph + kerf, pw, f.h - ph - kerf)
        val bBottom = R(f.x, f.y + ph + kerf, f.w, f.h - ph - kerf)
        val bRight = R(f.x + pw + kerf, f.y, f.w - pw - kerf, ph)
        fun big(vararg r: R) = r.filter { it.w > 0.5 && it.h > 0.5 }.maxOfOrNull { it.area } ?: 0.0
        val useA = big(aRight, aBottom) >= big(bBottom, bRight)
        val rects: List<R>
        if (useA) {
            if (dw > 1e-6) s.cuts += Cut(s.cuts.size + 1, true, pw, f.w, f.h)
            if (dh > 1e-6) s.cuts += Cut(s.cuts.size + 1, false, ph, pw, f.h)
            rects = listOf(aRight, aBottom)
        } else {
            if (dh > 1e-6) s.cuts += Cut(s.cuts.size + 1, false, ph, f.w, f.h)
            if (dw > 1e-6) s.cuts += Cut(s.cuts.size + 1, true, pw, f.w, ph)
            rects = listOf(bBottom, bRight)
        }
        // só guarda sobra utilizável (maior que a serra e ≥ 30 mm nos dois lados)
        for (r in rects) if (r.w >= 30.0 && r.h >= 30.0) s.free += r
    }

    /** Aproveitamento total, de 0 a 1. */
    fun totalUsage(r: Result): Double {
        val area = r.sheets.sumOf { it.w * it.h }
        return if (area <= 0.0) 0.0 else r.sheets.sumOf { it.usedArea } / area
    }

    /** Texto de cada corte, na ordem em que a serra deve passar. */
    fun describeCut(c: Cut, fmt: (Double) -> String): String {
        val dir = if (c.vertical) tr("vertical (mede {0} a partir da esquerda)", fmt(c.pos)) else tr("horizontal (mede {0} a partir de cima)", fmt(c.pos))
        return tr("{0}. Corte {1} na faixa {2} × {3}", c.step, dir, fmt(c.rectW), fmt(c.rectH))
    }
}
