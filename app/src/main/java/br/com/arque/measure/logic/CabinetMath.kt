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

    /** Porta de 2 folhas: soma de 12 mm na largura do vão (÷ 2) e 30 mm na altura. */
    const val PORTA_SOBRE_L_MM = 12.0
    const val PORTA_SOBRE_H_MM = 30.0
    private fun cavaNote(v: Vao) = if (v.cava) " · cava: corte a 30° na peça" else ""

    /** Folga por lado até a pedra: 20 mm sem tamponamento, 35 mm com (20 + 15 da chapa). */
    fun descontoPedra(c: Cabinet) = (if (c.tampEsq) 35.0 else 20.0) + (if (c.tampDir) 35.0 else 20.0)

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
    fun drawerFrontH(c: Cabinet, n: Int, areaH: Double = vaoH(c), v: Vao? = null): Double {
        val k = max(1, n)
        // com cava: (área − (n−1) batentes) ÷ n, sem bordas nem folga entre frentes
        if (v != null && v.cava) return (areaH - v.batenteMm * (k - 1)) / k
        return (areaH - c.bordaSupMm - c.bordaInfMm - c.folgaGavetaMm * (k - 1)) / k
    }

    /** Altura da área das gavetas do vão: o vão todo, ou o gaveteiro (padrão 300) quando há prateleiras em cima. */
    fun gaveteiroH(c: Cabinet, v: Vao): Double =
        if (v.shelvesAbove > 0) (if (v.gaveteiroMm > 0) v.gaveteiroMm else 300.0).coerceIn(50.0, vaoH(c) - 50.0) else vaoH(c)

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
            } else if (v.kind == VaoKind.DRAWERS && v.shelvesAbove > 0) {
                val area = vh - gaveteiroH(c, v)
                for (k in 1..v.shelvesAbove) {
                    val y = vTop + area * k / (v.shelvesAbove + 1) - e / 2
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
                    val gh = gaveteiroH(c, v)
                    val fh = drawerFrontH(c, v.drawers, gh, v)
                    val gap = if (v.cava) v.batenteMm else c.folgaGavetaMm
                    val top0 = if (v.cava) 0.0 else c.bordaSupMm
                    if (v.cava) for (k in 0 until v.drawers - 1) {
                        out += Part(PartKind.BATENTE, x0, y0 + (k + 1) * fh + k * gap, vw, gap, vw, gap, e, vao = i, note = "cor do móvel · ${v.drawers - 1} batente(s) entre ${v.drawers} gavetas")
                    }
                    val y0 = vTop + vh - gh
                    val fw = vw - c.folgaMm
                    val caixaW = vw - c.corredicaMm
                    for (k in 0 until v.drawers) {
                        val y = y0 + top0 + k * (fh + gap)
                        out += Part(PartKind.FRENTE_GAVETA, x0 + c.folgaMm / 2, y, fw, fh, fw, fh, e, vao = i, note = "caixa: largura ${fmt(caixaW)} (vão − ${fmt(c.corredicaMm)} das corrediças)" + cavaNote(v))
                    }
                }
                VaoKind.DOOR -> {
                    if (v.doors >= 2) {
                        // duas folhas sobrepostas: (vão + 12) ÷ 2 de largura e vão + 30 de altura
                        val dw = (vw + PORTA_SOBRE_L_MM) / 2
                        val dh = vh + PORTA_SOBRE_H_MM
                        for (k in 0 until 2) {
                            val x = x0 - PORTA_SOBRE_L_MM / 2 + k * dw
                            out += Part(PartKind.PORTA, x, vTop - PORTA_SOBRE_H_MM / 2, dw, dh, dw, dh, e, vao = i,
                                note = "(vão + ${fmt(PORTA_SOBRE_L_MM)}) ÷ 2 · altura do vão + ${fmt(PORTA_SOBRE_H_MM)}" + cavaNote(v))
                        }
                    } else {
                        val dw = vw - c.folgaMm
                        val dh = vh - c.folgaMm
                        out += Part(PartKind.PORTA, x0 + c.folgaMm / 2, vTop + c.folgaMm / 2, dw, dh, dw, dh, e, vao = i, note = cavaNote(v).removePrefix(" · "))
                    }
                }
                else -> {}
            }
        }
        // tamponamento: encostado por fora, do fundo da pedra até a base (cobre lateral + base + folga)
        val tampH = latH + c.tampAltExtraMm
        val tampD = c.dMm + c.tampProfExtraMm
        val tn = "por fora; +${fmt(c.tampProfExtraMm)} na profundidade e +${fmt(c.tampAltExtraMm)} na altura"
        if (c.tampEsq) out += Part(PartKind.TAMPONAMENTO, -e, top, e, tampH, tampH, tampD, e, note = tn)
        if (c.tampDir) out += Part(PartKind.TAMPONAMENTO, c.wMm, top, e, tampH, tampH, tampD, e, note = tn)
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
