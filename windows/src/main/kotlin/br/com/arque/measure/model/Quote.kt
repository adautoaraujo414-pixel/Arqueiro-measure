package br.com.arque.measure.model

/** Dados da empresa (preenchidos uma vez e usados em todo orçamento). */
data class Company(
    val name: String = "",
    val cnpj: String = "",
    val address: String = "",
    val city: String = "",
    val phone: String = "",
)

data class QuoteItem(
    val id: String = newId(),
    val desc: String = "",
    val qty: Double = 1.0,
    val unit: String = "un",
    val unitValue: Double = 0.0,
)

data class Quote(
    val id: String = newId(),
    val clientName: String = "",
    val city: String = "",
    val dateMs: Long = System.currentTimeMillis(),
    val items: List<QuoteItem> = listOf(QuoteItem()),
    val discountPct: Double = 0.0,
    /** Regra fixa: a proposta vale 15 dias. */
    val validityDays: Int = 15,
    val includeDrawing: Boolean = false,
    val noteId: String? = null,
    val notes: String = "",
)
