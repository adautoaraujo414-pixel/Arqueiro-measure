package br.com.arque.measure.logic

import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.Part
import br.com.arque.measure.model.PartKind
import br.com.arque.measure.model.Vao
import br.com.arque.measure.model.VaoKind
import kotlin.math.max

/**
 * Geometria do módulo (vista frontal, mm). Origem no canto superior esquerdo, y = 0 na parte de baixo da pedra.
 * Do alto para baixo: folga de montagem → laterais com a travessa frontal embutida → base inteiriça (de fora a fora,
 * sob as laterais) → pedestal de 10 cm no chão. A moldura de acabamento cobre a folga e o topo da travessa.
 * Lógica pura (sem Android), testável na JVM.
 */
object CabinetMath {
    /** A largura e a profundidade do módulo são as da pedra menos 4 cm. */
    const val DESCONTO_PEDRA_MM = 40.0

    /** y da face de baixo da base (onde começa o pedestal). */
    fun baseBottom(c: Cabinet) = (c.hMm - c.rodapeMm).coerceAtLeast(c.folgaTopoMm + c.travessaMm + c.espMm * 2 + 10.0)

    /** Altura de cada lateral: apoiada em cima da base, começa depois da folga do topo. */
    fun lateralH(c: Cabinet) = baseBottom(c) - c.espMm - c.folgaTopoMm

    fun innerW(c: Cabinet) = (c.wMm - 2 * c.espMm).coerceAtLeast(10.0)

    /** Onde começam e terminam, na vertical, os vãos (abaixo da travessa frontal, acima da base). */
    fun vaoTop(c: Cabinet) = c.folgaTopoMm + c.travessaMm
    fun vaoBottom(c: Cabinet) = baseBottom(c) - c.espMm

    /** Altura livre dos vãos. */
    fun vaoH(c: Cabinet) = (vaoBottom(c) - vaoTop(c)).coerceAtLeast(10.0)

    /** Menor distância permitida entre divisórias, para não se sobreporem. */
    fun minGap(c: Cabinet) = c.espMm * 2 + 20.0

    /** X (mm, canto esquerdo) de cada divisória, já sem sobreposição. */
    fun dividerX(c: Cabinet): List<Double> {
        val iw = innerW(c)
        val out = ArrayList<Double>()
        var prevRight = c.espMm
        c.dividers.sorted().forEachIndexed { _, r ->
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
        val top = c.folgaTopoMm
        val bb = baseBottom(c)
        val iw = innerW(c)
        val dep = c.dMm - c.recuoFundoMm
        val latH = lateralH(c)
        val vTop = vaoTop(c)
        val vh = vaoH(c)
        val reb = "rebaixo ${fmt(e)} × ${fmt(c.travessaMm)} na frente, em cima"
        val out = ArrayList<Part>()
        out += Part(PartKind.BASE, 0.0, bb - e, c.wMm, e, c.wMm, dep, e, note = "inteiriça, sob as laterais")
        out += Part(PartKind.LATERAL, 0.0, top, e, latH, latH, dep, e, note = reb)
        out += Part(PartKind.LATERAL, c.wMm - e, top, e, latH, latH, dep, e, note = reb)
        out += Part(PartKind.TRAVESSA, 0.0, top, c.wMm, c.travessaMm, c.wMm, c.travessaMm, e, note = "embute ${fmt(e)} no rebaixo das laterais")
        val dx = dividerX(c)
        dx.forEachIndexed { i, x ->
            out += Part(PartKind.DIVISORIA, x, vTop, e, vh, vh, dep, e, divider = i)
        }
        val ranges = vaoRanges(c)
        ranges.forEachIndexed { i, (x0, x1) ->
            val vw = x1 - x0
            val v = c.vaos[i]
            if (v.kind == VaoKind.SHELVES) {
                for (k in 1..v.shelves) {
                    val y = vTop + vh * k / (v.shelves + 1) - e / 2
                    out += Part(PartKind.PRATELEIRA, x0, y, vw, e, vw, dep - 20.0, e, vao = i)
                }
            }
        }
        out += Part(PartKind.RODAPE, e, bb, iw, c.rodapeMm, iw, c.rodapeMm, e)
        ranges.forEachIndexed { i, (x0, x1) ->
            val vw = x1 - x0
            val v = c.vaos[i]
            when (v.kind) {
                VaoKind.DRAWERS -> {
                    val fh = drawerFrontH(c, v.drawers)
                    val fw = vw - c.folgaMm
                    for (k in 0 until v.drawers) {
                        val y = vTop + c.bordaSupMm + k * (fh + c.folgaGavetaMm)
                        out += Part(PartKind.FRENTE_GAVETA, x0 + c.folgaMm / 2, y, fw, fh, fw, fh, e, vao = i)
                    }
                }
                VaoKind.DOOR -> {
                    val n = if (v.doors >= 2) 2 else 1
                    val dw = (vw - c.folgaMm * n) / n
                    val dh = vh - c.folgaMm
                    for (k in 0 until n) {
                        val x = x0 + c.folgaMm / 2 + k * (dw + c.folgaMm)
                        out += Part(PartKind.PORTA, x, vTop + c.folgaMm / 2, dw, dh, dw, dh, e, vao = i)
                    }
                }
                else -> {}
            }
        }
        if (c.hasMoldura) {
            out += Part(PartKind.MOLDURA, 0.0, 0.0, c.wMm, c.molduraMm, c.wMm, c.molduraMm, e, note = "acabamento, cobre a folga do topo")
        }
        return out
    }

    private fun fmt(v: Double) = Units.formatNumber(v, br.com.arque.measure.model.LengthUnit.MM)

    /** Peça de fundo (não desenhada na vista de frente): entra só na lista. */
    fun backPart(c: Cabinet): Part? {
        if (!c.hasBack) return null
        return Part(PartKind.FUNDO, 0.0, 0.0, 0.0, 0.0, innerW(c), lateralH(c), 3.0)
    }

    data class Line(val kind: PartKind, val qty: Int, val cutL: Double, val cutW: Double, val esp: Double, val note: String = "")

    /** Lista de peças agrupada (mesma peça e mesma medida = quantidade). */
    fun cutList(c: Cabinet): List<Line> {
        val all = parts(c) + listOfNotNull(backPart(c))
        val order = PartKind.values().toList()
        return all.groupBy { Triple(it.kind, Math.round(it.cutL * 10), Math.round(it.cutW * 10) * 1000L + Math.round(it.esp)) }
            .map { (_, g) -> Line(g[0].kind, g.size, g[0].cutL, g[0].cutW, g[0].esp, g[0].note) }
            .sortedBy { order.indexOf(it.kind) }
    }

    /** Medidas "reais" mostradas em tempo real: largura, largura interna e vãos. */
    fun summary(c: Cabinet): String {
        val r = vaoRanges(normalized(c))
        return "Largura ${fmt(c.wMm)} · interna ${fmt(innerW(c))} · vãos ${r.joinToString(" | ") { fmt(it.second - it.first) }} mm"
    }
}
