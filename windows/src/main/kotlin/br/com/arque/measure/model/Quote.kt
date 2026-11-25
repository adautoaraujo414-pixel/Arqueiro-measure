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

/**
 * ORC-AMB (Adauto 25/11): um ambiente (projeto do editor) dentro do orçamento de vários ambientes do mesmo cliente.
 * Guarda uma CÓPIA dos valores do projeto no momento em que entrou (mudar o projeto depois não muda o orçamento).
 * [mat] e [labor] são custo interno: aparecem só na tela do editor; nunca saem no PDF nem no link do cliente.
 * Valor do ambiente = [manual] (se houver) ou [sug]; o desconto individual vem antes do subtotal (ver QuoteMath).
 */
data class QuoteSection(
    val id: String = newId(),
    val pid: String = "",
    val title: String = "",
    val desc: String = "",
    val finish: String = "",
    val mat: Double = 0.0,
    val labor: Double = 0.0,
    val sug: Double = 0.0,
    val manual: Double? = null,
    val discountPct: Double = 0.0,
    val at: Long = 0L,
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
    /** ORC-AMB: ambientes do orçamento de vários ambientes (vazio = orçamento de sempre, pelos itens). */
    val sections: List<QuoteSection> = emptyList(),
    /** ORC-AMB: cliente do orçamento de vários ambientes (o nome normalizado, a mesma chave da lista de clientes do editor). */
    val clientKey: String? = null,
    /** ORC-AMB: PDF só com o total geral (as descrições continuam por ambiente). */
    val onlyTotal: Boolean = false,
)
