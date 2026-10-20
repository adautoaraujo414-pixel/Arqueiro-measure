package br.com.arque.measure.model

/** O que vai dentro de um vão do móvel. */
enum class VaoKind(val label: String) {
    FREE("Livre"), SHELVES("Prateleiras"), DRAWERS("Gavetas"), DOOR("Porta"),
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
    /** Folga de montagem entre o topo do móvel e a pedra. */
    val folgaTopoMm: Double = 15.0,
    val molduraMm: Double = 30.0,
    val hasMoldura: Boolean = true,
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
    LATERAL("Lateral"), BASE("Base"), TRAVESSA("Travessa frontal"), DIVISORIA("Divisória"),
    PRATELEIRA("Prateleira"), FRENTE_GAVETA("Frente de gaveta"), PORTA("Porta"), RODAPE("Rodapé / pedestal"), FUNDO("Fundo"), MOLDURA("Moldura (acabamento)"), TAMPONAMENTO("Tamponamento"), BATENTE("Batente de cava"),
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

/** Módulo colocado numa folha. [at] = canto superior esquerdo; [scaleDen] = escala (10 → 1:10). */
data class CabObj(
    override val id: String = newId(),
    override val photoId: String? = null,
    val at: Pt,
    val cab: Cabinet = Cabinet(),
    val name: String = "Armário base",
    val scaleDen: Int = 10,
    override val locked: Boolean = false,
) : Ann() {
    /** Unidades de folha por mm real, na escala da folha (1 unidade = 1/96 pol). */
    val unitsPerMm: Double get() = 3.7795277 / scaleDen
    fun widthUnits(): Float = (cab.wMm * unitsPerMm).toFloat()
    fun heightUnits(): Float = (cab.hMm * unitsPerMm).toFloat()
}
