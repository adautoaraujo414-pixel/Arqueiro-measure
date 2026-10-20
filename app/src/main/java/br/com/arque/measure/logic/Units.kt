package br.com.arque.measure.logic

import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import java.math.RoundingMode
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToLong

/** Conversões e formatação. Internamente tudo é milímetro. */
object Units {
    private val symbols = DecimalFormatSymbols(Locale.forLanguageTag("pt-BR"))

    const val PENDING_LABEL = "···"

    fun fromMm(mm: Double, u: LengthUnit): Double = when (u) {
        LengthUnit.MM -> mm
        LengthUnit.CM -> mm / 10.0
        LengthUnit.M -> mm / 1000.0
    }

    fun toMm(v: Double, u: LengthUnit): Double = when (u) {
        LengthUnit.MM -> v
        LengthUnit.CM -> v * 10.0
        LengthUnit.M -> v * 1000.0
    }

    /** Número sem sufixo, no formato do app (vírgula decimal). */
    fun formatNumber(mm: Double, u: LengthUnit): String {
        val pattern = when (u) {
            LengthUnit.MM -> if (abs(mm - mm.roundToLong()) < 0.05) "0" else "0.0"
            LengthUnit.CM -> "0.0"
            LengthUnit.M -> "0.00"
        }
        val df = DecimalFormat(pattern, symbols)
        df.roundingMode = RoundingMode.HALF_UP
        return df.format(fromMm(mm, u))
    }

    fun format(mm: Double, u: LengthUnit): String = formatNumber(mm, u) + " " + u.label

    /** Texto da cota. Vazio enquanto a cota aguarda medida (nada é mostrado na seta). */
    fun label(dim: DimObj, u: LengthUnit): String =
        dim.valueMm?.let { format(it, u) } ?: ""

    /**
     * Interpreta o que o usuário digitou. Aceita vírgula ou ponto e um sufixo opcional
     * (mm, cm, m) que prevalece sobre a unidade atual. Retorna milímetros, ou null se inválido.
     */
    fun parseToMm(text: String, current: LengthUnit): Double? {
        var t = text.trim().lowercase(Locale.ROOT)
        var unit = current
        when {
            t.endsWith("mm") -> { unit = LengthUnit.MM; t = t.removeSuffix("mm") }
            t.endsWith("cm") -> { unit = LengthUnit.CM; t = t.removeSuffix("cm") }
            t.endsWith("m") -> { unit = LengthUnit.M; t = t.removeSuffix("m") }
        }
        t = t.trim().replace(',', '.')
        val v = t.toDoubleOrNull() ?: return null
        if (!v.isFinite() || v <= 0.0) return null
        return toMm(v, unit)
    }
}
