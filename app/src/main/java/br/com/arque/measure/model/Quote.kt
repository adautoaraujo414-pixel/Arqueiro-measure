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

/** Aditivo: item acrescentado depois do orçamento fechado, com descrição, valor e data próprios. Não mexe no orçamento original. */
data class QuoteAddendum(
    val id: String = newId(),
    val desc: String = "",
    val value: Double = 0.0,
    val dateMs: Long = System.currentTimeMillis(),
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
    /** Aditivos (entram depois do orçamento fechado; somam no total geral, separados do original). */
    val addenda: List<QuoteAddendum> = emptyList(),
    /** Fotos do projeto (arquivos em projects/images/), tiradas no 3D. */
    val photos: List<String> = emptyList(),
    /** Projeto do editor de móveis ligado a este orçamento (de onde saem as fotos). */
    val projId: String? = null,
)
