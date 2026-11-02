package br.com.arque.measure.logic

import br.com.arque.measure.i18n.tr

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
    /** Porta de 1 folha: vão + 14 de largura (7 por lado). */
    const val PORTA1_SOBRE_L_MM = 14.0
    /** Frente de gaveta passa 7,5 em cada lado (vão + 15). */
    const val GAVETA_SOBRE_L_MM = 15.0
    private fun cavaNote(v: Vao) = if (v.cava) tr(" · cava: corte a 30° na peça") else ""

    /** Folga por lado até a pedra: 20 mm sem tamponamento, 35 mm com (20 + 15 da chapa). */
    fun descontoPedra(c: Cabinet) = (if (c.tampEsq) 35.0 else 0.0) + (if (c.tampDir) 35.0 else 0.0)

    /** y da face de baixo da base (onde começa o pedestal). */
    /** Altura efetiva do pedestal e espessura efetiva da chapa da base (0 quando tirados). */
    fun rodapeH(c: Cabinet) = if (c.hasRodape) c.rodapeMm else 0.0
    fun baseT(c: Cabinet) = if (c.hasBase) c.espMm else 0.0

    /** Altura ocupada em cima: a travessa frontal ou, sem ela, o tampo (chapa igual à base) por cima das laterais. */
    fun topoH(c: Cabinet) = if (c.hasTravessa) c.travessaMm else c.espMm

    fun baseBottom(c: Cabinet) = (c.hMm - rodapeH(c)).coerceAtLeast(c.folgaTopoMm + topoH(c) + c.espMm * 2 + 10.0)

    /** Altura de cada lateral: apoiada em cima da base, começa depois da folga do topo. */
    fun lateralH(c: Cabinet) = baseBottom(c) - baseT(c) - c.folgaTopoMm - (if (c.hasTravessa) 0.0 else c.espMm)

    fun innerW(c: Cabinet) = (c.wMm - 2 * c.espMm).coerceAtLeast(10.0)

    /** Onde começam e terminam, na vertical, os vãos (abaixo da travessa frontal, acima da base). */
    fun vaoTop(c: Cabinet) = c.folgaTopoMm + topoH(c)
    fun vaoBottom(c: Cabinet) = baseBottom(c) - baseT(c)

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

    /** Coloca uma divisória na posição x (mm) dentro do vão que a contém; o vão da esquerda mantém o conteúdo. */
    fun addDividerAt(c0: Cabinet, x: Double): Cabinet {
        val c = normalized(c0)
        val e = c.espMm
        val rg = vaoRanges(c)
        val i = rg.indexOfFirst { x >= it.first && x <= it.second }
        if (i < 0) return c
        val (x0, x1) = rg[i]
        if (x1 - x0 < e + 60.0) return c
        val left = Math.round(x - e / 2).toDouble().coerceIn(x0 + 30.0, x1 - 30.0 - e)
        val ratio = ((left + e / 2 - e) / innerW(c)).toFloat()
        val ds = c.dividers.sorted()
        return c.copy(dividers = ds.take(i) + ratio + ds.drop(i), vaos = c.vaos.take(i + 1) + Vao() + c.vaos.drop(i + 1))
    }

    /** Divide o vão [i] em [n] partes iguais (cada parte herda o conteúdo do vão). */
    fun splitVao(c0: Cabinet, i: Int, n: Int): Cabinet {
        val c = normalized(c0)
        if (n < 2 || i !in c.vaos.indices) return c
        val e = c.espMm
        val (x0, x1) = vaoRanges(c)[i]
        val w = (x1 - x0 - (n - 1) * e) / n
        if (w < 30.0) return c
        val iw = innerW(c)
        val novos = (1 until n).map { k -> ((x0 + k * w + (k - 1) * e + e / 2 - e) / iw).toFloat() }
        val ds = c.dividers.sorted()
        return c.copy(dividers = ds.take(i) + novos + ds.drop(i), vaos = c.vaos.take(i) + List(n) { c.vaos[i] } + c.vaos.drop(i + 1))
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
        val reb = tr("rebaixo {0} × {1} na frente, em cima", fmt(e), fmt(c.travessaMm))
        val out = ArrayList<Part>()
        if (c.hasBase) out += Part(PartKind.BASE, 0.0, bb - e, c.wMm, e, c.wMm, dep, e, note = tr("inteiriça, sob as laterais"))
        if (c.hasTravessa) {
            out += Part(PartKind.LATERAL, 0.0, top, e, latH, latH, dep, e, note = reb)
            out += Part(PartKind.LATERAL, c.wMm - e, top, e, latH, latH, dep, e, note = reb)
            out += Part(PartKind.TRAVESSA, 0.0, top, c.wMm, c.travessaMm, c.wMm, c.travessaMm, e, note = tr("embute {0} no rebaixo das laterais", fmt(e)))
        } else {
            out += Part(PartKind.LATERAL, 0.0, top + e, e, latH, latH, dep, e)
            out += Part(PartKind.LATERAL, c.wMm - e, top + e, e, latH, latH, dep, e)
            out += Part(PartKind.TOPO, 0.0, top, c.wMm, e, c.wMm, dep, e, note = tr("igual à base, parafusada por cima das laterais"))
        }
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
                    out += Part(PartKind.PRATELEIRA, x0, y, vw, e, vw, dep - c.prateleiraMenorMm, e, vao = i)
                }
            } else if (v.kind == VaoKind.DRAWERS && v.shelvesAbove > 0) {
                val area = vh - gaveteiroH(c, v)
                for (k in 1..v.shelvesAbove) {
                    val y = vTop + area * k / (v.shelvesAbove + 1) - e / 2
                    out += Part(PartKind.PRATELEIRA, x0, y, vw, e, vw, dep - c.prateleiraMenorMm, e, vao = i)
                }
            }
        }
        ranges.forEachIndexed { i, (x0, x1) ->
            c.vaos[i].shelfYs.sorted().filter { it > vTop + e && it < vaoBottom(c) - e }.forEach { y ->
                out += Part(PartKind.PRATELEIRA, x0, y - e / 2, x1 - x0, e, x1 - x0, dep - c.prateleiraMenorMm, e, vao = i, note = tr("na posição escolhida ({0} abaixo da travessa)", fmt(y - vTop)))
            }
        }
        if (c.hasRodape && c.rodapeMm > 0) out += Part(PartKind.RODAPE, e, bb, iw, c.rodapeMm, iw, c.rodapeMm, e)
        ranges.forEachIndexed { i, (x0, x1) ->
            val vw = x1 - x0
            val v = c.vaos[i]
            when (v.kind) {
                VaoKind.DRAWERS -> {
                    val gh = gaveteiroH(c, v)
                    val fh = drawerFrontH(c, v.drawers, gh, v)
                    val y0 = vTop + vh - gh
                    val gap = if (v.cava) v.batenteMm else c.folgaGavetaMm
                    val top0 = if (v.cava) 0.0 else c.bordaSupMm
                    if (v.cava) for (k in 0 until v.drawers - 1) {
                        out += Part(PartKind.BATENTE, x0, y0 + (k + 1) * fh + k * gap, vw, gap, vw, gap, e, vao = i, note = tr("cor do móvel · {0} batente(s) entre {1} gavetas", v.drawers - 1, v.drawers))
                    }
                    val fw = vw + GAVETA_SOBRE_L_MM
                    val caixaW = vw - c.corredicaMm
                    for (k in 0 until v.drawers) {
                        val y = y0 + top0 + k * (fh + gap)
                        out += Part(PartKind.FRENTE_GAVETA, x0 - GAVETA_SOBRE_L_MM / 2, y, fw, fh, fw, fh, e, vao = i, note = tr("frente = vão + {0} (7,5 por lado) · caixa: largura {1} (vão − {2} das corrediças)", fmt(GAVETA_SOBRE_L_MM), fmt(caixaW), fmt(c.corredicaMm)) + cavaNote(v))
                    }
                }
                VaoKind.OVEN -> {
                    val ow = v.ovenW.coerceIn(50.0, vw)
                    val oh = v.ovenH.coerceIn(50.0, vh - e)
                    val ox0 = x0 + (vw - ow) / 2 // centralizado no vão
                    val oy = vTop + v.ovenTop.coerceIn(0.0, vh - oh - e)
                    out += Part(PartKind.FORNO, ox0, oy, ow, oh, ow, oh, 0.0, vao = i, note = tr("corte centralizado · sobra {0} de cada lado", fmt((vw - ow) / 2)))
                    if (oy > vTop + 0.5) out += Part(PartKind.PRATELEIRA, x0, oy - e, vw, e, vw, dep - c.prateleiraMenorMm, e, vao = i, note = tr("acima do forno"))
                    out += Part(PartKind.PRATELEIRA, x0, oy + oh, vw, e, vw, dep - c.prateleiraMenorMm, e, vao = i, note = tr("apoio do forno"))
                    if ((vw - ow) / 2 > 0.5) for (side in 0..1) {
                        val fx = if (side == 0) x0 else ox0 + ow
                        out += Part(PartKind.DIVISORIA, fx, oy, (vw - ow) / 2, oh, oh, (vw - ow) / 2, e, vao = i, note = tr("fechamento ao lado do forno (peça em pé, {0} de largura)", fmt((vw - ow) / 2)))
                    }
                }
                VaoKind.DOOR -> {
                    if (v.doors >= 2) {
                        // duas folhas sobrepostas: (vão + 12) ÷ 2 de largura e vão + 30 de altura
                        val nd = v.doors.coerceIn(2, 6)
                        val dw = (vw + PORTA_SOBRE_L_MM) / nd
                        val dh = vh + PORTA_SOBRE_H_MM
                        for (k in 0 until nd) {
                            val x = x0 - PORTA_SOBRE_L_MM / 2 + k * dw
                            out += Part(PartKind.PORTA, x, vTop - PORTA_SOBRE_H_MM / 2, dw, dh, dw, dh, e, vao = i,
                                note = tr("(vão + {0}) ÷ {1} · altura do vão + {2}", fmt(PORTA_SOBRE_L_MM), nd, fmt(PORTA_SOBRE_H_MM)) + cavaNote(v))
                        }
                    } else {
                        val dw = vw + PORTA1_SOBRE_L_MM
                        val dh = vh + PORTA_SOBRE_H_MM
                        out += Part(PartKind.PORTA, x0 - PORTA1_SOBRE_L_MM / 2, vTop - PORTA_SOBRE_H_MM / 2, dw, dh, dw, dh, e, vao = i,
                            note = tr("vão + {0} · altura do vão + {1}", fmt(PORTA1_SOBRE_L_MM), fmt(PORTA_SOBRE_H_MM)) + cavaNote(v))
                    }
                }
                else -> {}
            }
        }
        // tamponamento: encostado por fora, do fundo da pedra até a base (cobre lateral + base + folga)
        // com tamponamento de baixo: lateral = todas as peças somadas (até o fim da base) + 30 mm do batente, ou só até a base se o de baixo passa reto
        val tampH = if (c.tampBaixo) bb + (if (c.tampBaixoPassa) 0.0 else c.tampBaixoMm) else latH + c.tampAltExtraMm
        val tampD = c.dMm + c.tampProfExtraMm
        val tn = tr("por fora; +{0} na profundidade e +{1} na altura", fmt(c.tampProfExtraMm), fmt(c.tampAltExtraMm))
        // alinhado em cima com a moldura (y = 0), sem "dente"; engrossa a lateral (lateral + tamponamento = 2 × espessura)
        if (c.tampEsq) out += Part(PartKind.TAMPONAMENTO, -e, 0.0, e, tampH, tampH, tampD, e, note = tr("{0} · engrossa a lateral ({1} + {2})", tn, fmt(e), fmt(e)))
        if (c.tampDir) out += Part(PartKind.TAMPONAMENTO, c.wMm, 0.0, e, tampH, tampH, tampD, e, note = tr("{0} · engrossa a lateral ({1} + {2})", tn, fmt(e), fmt(e)))
        if (c.tampBaixo && !c.tampBaixoJunto) {
            val sx = if (c.tampBaixoPassa && c.tampEsq) -e else 0.0
            val sw = c.wMm + (if (c.tampBaixoPassa && c.tampEsq) e else 0.0) + (if (c.tampBaixoPassa && c.tampDir) e else 0.0)
            out += Part(
                PartKind.TAMP_BAIXO, sx, bb, sw, c.tampBaixoMm, sw, c.tampBaixoMm, e,
                note = if (c.tampBaixoPassa) tr("passa reto por baixo; as laterais morrem nele") else tr("abaixo da base, do tamanho da base (batente da cava)"),
            )
        }
        if (c.hasMoldura) {
            out += Part(PartKind.MOLDURA, 0.0, 0.0, c.wMm, c.molduraMm, c.wMm, c.molduraMm, e, note = tr("acabamento, cobre a folga do topo"))
        }
        return out
    }

    private fun fmt(v: Double) = Units.formatNumber(v, br.com.arque.measure.model.LengthUnit.MM)

    /** Peça de fundo (não desenhada na vista de frente): entra só na lista. */
    fun backPart(c: Cabinet): Part? {
        if (!c.hasBack) return null
        return Part(PartKind.FUNDO, 0.0, 0.0, 0.0, 0.0, innerW(c), lateralH(c), 3.0)
    }

    /** Peças que não aparecem na vista de frente (só na lista): as réguas que engrossam a base e o tampo. */
    fun extraParts(c: Cabinet): List<Part> {
        if (!c.reguas) return emptyList()
        val painel = (if (c.hasBase) 1 else 0) + (if (!c.hasTravessa) 1 else 0)
        return List(painel * 2) {
            Part(PartKind.REGUA, 0.0, 0.0, 0.0, 0.0, c.wMm, c.reguaMm, c.espMm, note = tr("colada na borda da frente / de trás da base e do tampo"))
        }
    }

    data class Line(val kind: PartKind, val qty: Int, val cutL: Double, val cutW: Double, val esp: Double, val note: String = "")

    /** Lista de peças agrupada (mesma peça e mesma medida = quantidade). */
    fun cutList(c: Cabinet): List<Line> {
        val all = parts(c).filter { it.kind != PartKind.FORNO } + listOfNotNull(backPart(c)) + extraParts(c)
        val order = PartKind.values().toList()
        return all.groupBy { Triple(it.kind, Math.round(it.cutL * 10), Math.round(it.cutW * 10) * 1000L + Math.round(it.esp)) }
            .map { (_, g) -> Line(g[0].kind, g.size, g[0].cutL, g[0].cutW, g[0].esp, g[0].note) }
            .sortedBy { order.indexOf(it.kind) }
    }

    /** Medidas "reais" mostradas em tempo real: largura, largura interna e vãos. */
    fun summary(c: Cabinet): String {
        val r = vaoRanges(normalized(c))
        return tr("Largura {0} · interna {1} · vãos {2} mm", fmt(c.wMm), fmt(innerW(c)), r.joinToString(" | ") { fmt(it.second - it.first) })
    }
}
