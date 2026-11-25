package br.com.arque.measure.logic

import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import br.com.arque.measure.model.QuoteSection
import java.util.Locale
import kotlin.math.roundToLong

/** Contas do orçamento e formatação em reais (lógica pura). */
object QuoteMath {
    private fun cents(v: Double) = (v * 100.0).roundToLong() / 100.0

    fun lineTotal(i: QuoteItem): Double = cents(i.qty * i.unitValue)
    /**
     * Valor antes do desconto geral. Orçamento de sempre: a soma dos itens.
     * ORC-AMB (vários ambientes): o subtotal = soma dos ambientes, cada um já com o desconto individual dele.
     * Ordem do desconto: individual (em cada ambiente, centavos) → subtotal → geral (discountPct, centavos), igual à tela do editor.
     */
    fun original(q: Quote): Double = if (q.sections.isNotEmpty()) cents(q.sections.sumOf { sectionFinal(it) }) else cents(q.items.sumOf { lineTotal(it) })

    /** Valor do ambiente antes do desconto dele: o valor de venda digitado ou o sugerido. */
    fun sectionBase(s: QuoteSection): Double = cents(s.manual?.takeIf { it > 0.0 } ?: s.sug)
    fun sectionDiscount(s: QuoteSection): Double = cents(sectionBase(s) * s.discountPct.coerceIn(0.0, 100.0) / 100.0)
    fun sectionFinal(s: QuoteSection): Double = cents(sectionBase(s) - sectionDiscount(s))
    /** Soma dos ambientes antes dos descontos individuais e a soma desses descontos (pro PDF: soma, descontos, subtotal). */
    fun sectionsGross(q: Quote): Double = cents(q.sections.sumOf { sectionBase(it) })
    fun sectionsDiscount(q: Quote): Double = cents(q.sections.sumOf { sectionDiscount(it) })
    fun discountValue(q: Quote): Double = cents(original(q) * q.discountPct.coerceIn(0.0, 100.0) / 100.0)
    fun finalValue(q: Quote): Double = cents(original(q) - discountValue(q))

    /** Soma dos aditivos (não entra no desconto: o desconto é só do orçamento original). */
    fun addendaTotal(q: Quote): Double = cents(q.addenda.sumOf { cents(it.value) })
    /** Total geral: orçamento (já com o desconto) + aditivos. */
    fun grandTotal(q: Quote): Double = cents(finalValue(q) + addendaTotal(q))

    /** 1234.5 → "R$ 1.234,50" (no Brasil; fora, na moeda do país do telefone). */
    fun brl(v: Double): String = br.com.arque.measure.i18n.I18n.money(cents(v))

    /** Aceita "12,5", "12.5" e "1.234,56". */
    fun parseNum(s: String): Double? {
        val t = s.trim().replace(" ", "")
        if (t.isEmpty()) return null
        val norm = if (t.contains(',')) t.replace(".", "").replace(',', '.') else t
        return norm.toDoubleOrNull()
    }

    fun numStr(d: Double): String =
        if (d == d.toLong().toDouble()) d.toLong().toString() else d.toString().replace('.', ',')
}
