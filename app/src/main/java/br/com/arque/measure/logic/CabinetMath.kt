package br.com.arque.measure.logic

import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.Part
import br.com.arque.measure.model.PartKind
import br.com.arque.measure.model.Vao
import br.com.arque.measure.model.VaoKind
import kotlin.math.max

/** Geometria do módulo: peças, vãos, gavetas. Lógica pura (sem Android), testável na JVM. */
object CabinetMath {
    /** Altura do corpo (sem rodapé). */
    fun bodyH(c: Cabinet) = (c.hMm - c.rodapeMm).coerceAtLeast(c.espMm * 2)

    fun innerW(c: Cabinet) = (c.wMm - 2 * c.espMm).coerceAtLeast(10.0)

    /** Altura livre dos vãos (entre a travessa e a base). */
    fun vaoH(c: Cabinet) = (bodyH(c) - c.travessaMm - c.espMm).coerceAtLeast(10.0)

    /** Menor distância permitida entre divisórias, para não se sobreporem. */
    private fun minGap(c: Cabinet) = c.espMm * 2 + 20.0

    /** X (mm, canto esquerdo) de cada divisória, já sem sobreposição. */
    fun dividerX(c: Cabinet): List<Double> {
        val iw = innerW(c)
        val out = ArrayList<Double>()
        var prevRight = c.espMm
        c.dividers.sorted().forEachIndexed { i, r ->
            var x = c.espMm + r * iw - c.espMm / 2
            x = x.coerceAtLeast(prevRight + 10.0).coerceAtMost(c.wMm - c.espMm - 10.0 - c.espMm)
            out += x
            prevRight = x + c.espMm
        }
        return out
    }

    /** Faixas [x0, x1] de cada vão (entre laterais/divisórias). */
    fun vaoRanges(c: Cabinet): List<Pair<Double, Double>> {
        val dx = dividerX(c)
        val res = ArrayList<Pair<Double, Double>>()
        var left = c.espMm
        for (x in dx) { res += left to x; left = x + c.espMm }
        res += left to (c.wMm - c.espMm)
        return res
    }

    /** Altura de cada frente de gaveta: (vão − bordas − folgas entre frentes) ÷ quantidade. */
    fun drawerFrontH(c: Cabinet, n: Int): Double {
        val k = max(1, n)
        return (vaoH(c) - c.bordaSupMm - c.bordaInfMm - c.folgaGavetaMm * (k - 1)) / k
    }

    /** Garante que há exatamente (divisórias + 1) vãos, preenchendo ou cortando. */
    fun normalized(c: Cabinet): Cabinet {
        val need = c.dividers.size + 1
        val vaos = when {
            c.vaos.size == need -> c.vaos
            c.vaos.size > need -> c.vaos.take(need)
            else -> c.vaos + List(need - c.vaos.size) { Vao() }
        }
        return c.copy(dividers = c.dividers.sorted(), vaos = vaos)
    }

    /** Todas as peças, na ordem de desenho (de trás para frente). */
    fun parts(c0: Cabinet): List<Part> {
        val c = normalized(c0)
        val e = c.espMm
        val bh = bodyH(c)
        val iw = innerW(c)
        val dep = c.dMm - c.recuoFundoMm
        val out = ArrayList<Part>()
        out += Part(PartKind.LATERAL, 0.0, 0.0, e, bh, bh, dep, e)
        out += Part(PartKind.LATERAL, c.wMm - e, 0.0, e, bh, bh, dep, e)
        out += Part(PartKind.TRAVESSA, e, 0.0, iw, c.travessaMm, iw, c.travessaMm, e)
        out += Part(PartKind.BASE, e, bh - e, iw, e, iw, dep, e)
        val dx = dividerX(c)
        val vh = vaoH(c)
        dx.forEachIndexed { i, x ->
            out += Part(PartKind.DIVISORIA, x, c.travessaMm, e, vh, vh, dep, e, divider = i)
        }
        val ranges = vaoRanges(c)
        ranges.forEachIndexed { i, (x0, x1) ->
            val vw = x1 - x0
            val v = c.vaos[i]
            if (v.kind == VaoKind.SHELVES) {
                for (k in 1..v.shelves) {
                    val y = c.travessaMm + vh * k / (v.shelves + 1) - e / 2
                    out += Part(PartKind.PRATELEIRA, x0, y, vw, e, vw, dep - 20.0, e, vao = i)
                }
            }
        }
        out += Part(PartKind.RODAPE, e, bh, iw, c.rodapeMm, iw, c.rodapeMm, e)
        ranges.forEachIndexed { i, (x0, x1) ->
            val vw = x1 - x0
            val v = c.vaos[i]
            when (v.kind) {
                VaoKind.DRAWERS -> {
                    val fh = drawerFrontH(c, v.drawers)
                    val fw = vw - c.folgaMm
                    for (k in 0 until v.drawers) {
                        val y = c.travessaMm + c.bordaSupMm + k * (fh + c.folgaGavetaMm)
                        out += Part(PartKind.FRENTE_GAVETA, x0 + c.folgaMm / 2, y, fw, fh, fw, fh, e, vao = i)
                    }
                }
                VaoKind.DOOR -> {
                    val n = if (v.doors >= 2) 2 else 1
                    val dw = (vw - c.folgaMm * n) / n
                    val dh = vh - c.folgaMm
                    for (k in 0 until n) {
                        val x = x0 + c.folgaMm / 2 + k * (dw + c.folgaMm)
                        out += Part(PartKind.PORTA, x, c.travessaMm + c.folgaMm / 2, dw, dh, dw, dh, e, vao = i)
                    }
                }
                else -> {}
            }
        }
        return out
    }

    /** Peça de fundo (não desenhada na vista de frente): entra só na lista. */
    fun backPart(c: Cabinet): Part? {
        if (!c.hasBack) return null
        val bh = bodyH(c)
        return Part(PartKind.FUNDO, 0.0, 0.0, 0.0, 0.0, innerW(c), bh - c.espMm, 3.0)
    }

    data class Line(val kind: PartKind, val qty: Int, val cutL: Double, val cutW: Double, val esp: Double)

    /** Lista de peças agrupada (mesma peça e mesma medida = quantidade). */
    fun cutList(c: Cabinet): List<Line> {
        val all = parts(c) + listOfNotNull(backPart(c))
        val order = PartKind.values().toList()
        return all.groupBy { Triple(it.kind, Math.round(it.cutL * 10), Math.round(it.cutW * 10) * 1000L + Math.round(it.esp)) }
            .map { (_, g) -> Line(g[0].kind, g.size, g[0].cutL, g[0].cutW, g[0].esp) }
            .sortedBy { order.indexOf(it.kind) }
    }
}
