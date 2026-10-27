package br.com.arque.measure.logic

import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import java.util.Locale
import kotlin.math.roundToLong

/** Contas do orçamento e formatação em reais (lógica pura). */
object QuoteMath {
    private fun cents(v: Double) = (v * 100.0).roundToLong() / 100.0

    fun lineTotal(i: QuoteItem): Double = cents(i.qty * i.unitValue)
    fun original(q: Quote): Double = cents(q.items.sumOf { lineTotal(it) })
    fun discountValue(q: Quote): Double = cents(original(q) * q.discountPct.coerceIn(0.0, 100.0) / 100.0)
    fun finalValue(q: Quote): Double = cents(original(q) - discountValue(q))

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
