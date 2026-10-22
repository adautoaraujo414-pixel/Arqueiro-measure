package br.com.arque.measure.model

/** O que vai dentro de um vão do móvel. */
enum class VaoKind(val label: String) {
    FREE("Livre"), SHELVES("Prateleiras"), DRAWERS("Gavetas"), DOOR("Porta"), OVEN("Forno"),
}

/** Um vão (espaço entre laterais/divisórias). Só os campos do tipo escolhido valem. */
data class Vao(
    val kind: VaoKind = VaoKind.FREE,
    val shelves: Int = 1,
    val drawers: Int = 3,
    val doors: Int = 1,
    /** Prateleiras acima do gaveteiro (só vale com gavetas). */
    val shelvesAbove: Int = 0,
    /** Altura do gaveteiro quando há prateleiras em cima (0 = 300 mm). */
    val gaveteiroMm: Double = 0.0,
    /** Cava (puxador cortado a 30° na própria peça) nas frentes/portas deste vão. */
    val cava: Boolean = false,
    /** Altura de cada batente de cava entre as gavetas (cor do móvel, largura do vão). */
    val batenteMm: Double = 50.0,
    /** Prateleiras soltas em posições escolhidas (y em mm, medido da parte de baixo da pedra). */
    val shelfYs: List<Double> = emptyList(),
    /** Forno embutido: largura e altura do corte (centralizado no vão) e a distância da travessa até o topo do corte. */
    val ovenW: Double = 560.0,
    val ovenH: Double = 595.0,
    val ovenTop: Double = 0.0,
)

/**
 * Módulo (armário) paramétrico, em mm, visto de frente. Tudo é calculado a partir destes números:
 * mudou a largura, as divisórias reposicionam e as frentes das gavetas recalculam.
 * [dividers] são as posições das divisórias como fração (0..1) da largura interna.
 */
data class Cabinet(
    val wMm: Double = 800.0,
    /** Altura livre: do chão até a parte de baixo da pedra. */
    val hMm: Double = 850.0,
    val dMm: Double = 560.0,
    val espMm: Double = 15.0,
    /** Pedestal (base de 10 cm) no chão. */
    val rodapeMm: Double = 100.0,
    /** Travessa frontal (barra de fora a fora, com o puxador cava), embutida no rebaixo das laterais. */
    val travessaMm: Double = 70.0,
    /** Travessa frontal (régua de 7). Desligada: entra um tampo igual à base, parafusado por cima das laterais. */
    val hasTravessa: Boolean = true,
    /** Armário superior ("caixote"): fica na fileira de cima da parede. */
    val superior: Boolean = false,
    /** A prateleira é sempre menor que a base: tanto a menos na profundidade (3 cm). */
    val prateleiraMenorMm: Double = 30.0,
    /** Réguas que engrossam as bordas da frente e de trás da base e do tampo (7 cm × comprimento da base). */
    val reguas: Boolean = false,
    val reguaMm: Double = 70.0,
    /** Tamponamento de baixo (batente da cava): tira abaixo da base, do tamanho da base. */
    val tampBaixo: Boolean = false,
    val tampBaixoMm: Double = 30.0,
    /** Tamponamento de baixo passa reto (por baixo das laterais); as laterais morrem nele, 30 mm mais curtas. */
    val tampBaixoPassa: Boolean = false,
    /** O tamponamento de baixo deste módulo é uma peça só com o do módulo do lado (corta-se junto na parede). */
    val tampBaixoJunto: Boolean = false,
    /** Folga de montagem entre o topo do móvel e a pedra. */
    val folgaTopoMm: Double = 15.0,
    val molduraMm: Double = 30.0,
    val hasMoldura: Boolean = true,
    /** Pedestal (rodapé) no chão e chapa da base: cada um pode ser tirado. */
    val hasRodape: Boolean = true,
    val hasBase: Boolean = true,
    /** Tamponamento (chapa de fora de cada lado): 15 de espessura, 25 a mais na profundidade e 30 a mais na altura. */
    val tampEsq: Boolean = false,
    val tampDir: Boolean = false,
    val tampProfExtraMm: Double = 25.0,
    val tampAltExtraMm: Double = 30.0,
    /** Desconto da largura da caixa da gaveta pelas corrediças (os dois lados juntos). */
    val corredicaMm: Double = 26.0,
    /** Medidas da pedra (opcionais): largura e profundidade do módulo saem delas menos [DESCONTO_PEDRA_MM]. */
    val pedraWMm: Double? = null,
    val pedraDMm: Double? = null,
    val folgaMm: Double = 2.0,
    val folgaGavetaMm: Double = 3.0,
    val bordaSupMm: Double = 2.0,
    val bordaInfMm: Double = 2.0,
    val recuoFundoMm: Double = 20.0,
    val hasBack: Boolean = true,
    val dividers: List<Float> = emptyList(),
    val vaos: List<Vao> = listOf(Vao()),
)

/** Tipos de peça (nomes mostrados na lista). */
enum class PartKind(val label: String) {
    LATERAL("Lateral"), BASE("Base"), TRAVESSA("Travessa frontal"), TOPO("Tampo superior"), REGUA("Régua (engrossa a borda)"), TAMP_BAIXO("Tamponamento de baixo"), DIVISORIA("Divisória"),
    PRATELEIRA("Prateleira"), FRENTE_GAVETA("Frente de gaveta"), PORTA("Porta"), RODAPE("Rodapé / pedestal"), FUNDO("Fundo"), MOLDURA("Moldura (acabamento)"), TAMPONAMENTO("Tamponamento"), BATENTE("Batente de cava"), FORNO("Forno (corte)"),
}

/**
 * Uma peça na vista frontal: retângulo (x, y, w, h em mm, origem no canto superior esquerdo do módulo)
 * e as medidas de corte (comprimento × largura × espessura). [vao] e [divider] dizem a quem pertence (-1 = ninguém).
 */
data class Part(
    val kind: PartKind,
    val x: Double, val y: Double, val w: Double, val h: Double,
    val cutL: Double, val cutW: Double, val esp: Double,
    val vao: Int = -1,
    val divider: Int = -1,
    val note: String = "",
)

/**
 * Móvel encaixado numa parede da planta: [ax],[ay] = início da parede (folha), [ux],[uy] = direção unitária da parede,
 * [nx],[ny] = normal para dentro do cômodo, [upm] = unidades de folha por mm real (escala medida),
 * [lenMm] = medida da parede, [offMm] = distância do início da parede até o móvel.
 */
data class WallFit(
    val roomId: String, val seg: Int,
    val ax: Float, val ay: Float, val ux: Float, val uy: Float, val nx: Float, val ny: Float,
    val upm: Double, val lenMm: Double, val offMm: Double,
)

/** Módulo colocado numa folha. [at] = canto superior esquerdo; [scaleDen] = escala (10 → 1:10). */
data class CabObj(
    override val id: String = newId(),
    override val photoId: String? = null,
    val at: Pt,
    val cab: Cabinet = Cabinet(),
    val name: String = "Armário base",
    val scaleDen: Int = 10,
    override val locked: Boolean = false,
    val wall: WallFit? = null,
    val layout: LayoutFit? = null,
) : Ann() {
    /** Unidades de folha por mm real, na escala da folha (1 unidade = 1/96 pol). */
    val unitsPerMm: Double get() = wall?.upm ?: (3.7795277 / scaleDen)

    /** Cantos da planta (vista de cima) quando encaixado na parede: início/fim na parede e fundo do móvel. */
    fun corners(): List<Pt> {
        val w = wall ?: return emptyList()
        val k = w.upm.toFloat()
        val x0 = w.ax + w.ux * (w.offMm.toFloat() * k)
        val y0 = w.ay + w.uy * (w.offMm.toFloat() * k)
        val lw = cab.wMm.toFloat() * k
        val dd = cab.dMm.toFloat() * k
        return listOf(
            Pt(x0, y0), Pt(x0 + w.ux * lw, y0 + w.uy * lw),
            Pt(x0 + w.ux * lw + w.nx * dd, y0 + w.uy * lw + w.ny * dd), Pt(x0 + w.nx * dd, y0 + w.ny * dd),
        )
    }

    /** Canto superior esquerdo da caixa que envolve o móvel. */
    fun origin(): Pt {
        if (wall == null) return at
        val c = corners()
        return Pt(c.minOf { it.x }, c.minOf { it.y })
    }
    fun widthUnits(): Float {
        if (wall == null) return (cab.wMm * unitsPerMm).toFloat()
        val c = corners(); return c.maxOf { it.x } - c.minOf { it.x }
    }
    fun heightUnits(): Float {
        if (wall == null) return (cab.hMm * unitsPerMm).toFloat()
        val c = corners(); return c.maxOf { it.y } - c.minOf { it.y }
    }
    /** Passa do comprimento da parede? */
    fun overflowsWall(): Boolean = wall != null && wall.offMm + cab.wMm > wall.lenMm + 0.5

    /** Desliza ao longo da parede (ímã): [dxu],[dyu] = deslocamento na folha. */
    fun slide(dxu: Float, dyu: Float): CabObj {
        val w = wall ?: return copy(at = Pt(at.x + dxu, at.y + dyu))
        val dMm = (dxu * w.ux + dyu * w.uy) / w.upm
        val maxOff = maxOf(0.0, w.lenMm - cab.wMm)
        return copy(wall = w.copy(offMm = (w.offMm + dMm).coerceIn(0.0, maxOff)))
    }
}

/** Módulo preso a uma parede da folha: [order] = posição na fileira (de baixo ou de cima, conforme [Cabinet.superior]). */
data class LayoutFit(val wallId: String, val order: Int, val anchorTop: Boolean = false, val topMm: Double = 0.0)

/**
 * Parede do projeto: linha do topo (largura máxima) e linha da altura, na escala [scaleDen].
 * Os módulos presos a ela (CabObj com layout) ficam um ao lado do outro: os de baixo no chão,
 * os superiores a [upperBottomMm] do chão.
 */
data class WallObj(
    override val id: String = newId(),
    override val photoId: String? = null,
    val at: Pt,
    val wMm: Double = 3000.0,
    val hMm: Double = 2600.0,
    val upperBottomMm: Double = 1400.0,
    /** Folga total (mm) na largura da parede para encaixar os armários sem erro; tamponamentos já entram na medida final. */
    val folgaMm: Double = 10.0,
    /** Onde fica a sobra da fileira: 0 esquerda, 1 repartida nos dois lados, 2 direita. */
    val alignRow: Int = 1,
    val scaleDen: Int = 20,
    override val locked: Boolean = false,
) : Ann() {
    val upm: Double get() = 3.7795277 / scaleDen
    fun widthUnits(): Float = (wMm * upm).toFloat()
    fun heightUnits(): Float = (hMm * upm).toFloat()
    /** Largura aproveitável pelos módulos. */
    val usableMm: Double get() = (wMm - folgaMm).coerceAtLeast(0.0)
}
