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

    /**
     * Medida digitada à mão no teclado do app. Quem trabalha com marcenaria digita em mm
     * (ex.: 1950 ou 2750−4) mesmo com a tela em cm ou m: número grande demais pra unidade
     * da tela é lido como mm (1950 em m vira 1950 mm = 195,0 cm, e não 1950 metros).
     */
    fun typedToMm(v: Double, u: LengthUnit): Double = when (u) {
        LengthUnit.MM -> v
        LengthUnit.CM -> if (v >= 1000.0) v else v * 10.0
        LengthUnit.M -> when {
            v >= 100.0 -> v           // 1950 → 1950 mm
            v > 15.0 -> v * 10.0      // 60 → 60 cm
            else -> v * 1000.0        // 1,95 → 1,95 m
        }
    }

    fun toMm(v: Double, u: LengthUnit): Double = when (u) {
        LengthUnit.MM -> v
        LengthUnit.CM -> v * 10.0
        LengthUnit.M -> v * 1000.0
    }

    /** Número sem sufixo, no formato do app (vírgula decimal). */
    fun formatNumber(mm: Double, u: LengthUnit): String {
        val pattern = when (u) {
            // nunca esconde os milímetros (nem décimos): 245,8 mm continua 245,8
            LengthUnit.MM -> "0.#"
            LengthUnit.CM -> "0.0" // sempre 1 casa: 189,8 · 345,8 · 1000,9 (10 m), sem ponto de milhar
            LengthUnit.M -> "0.000" // 3 casas igual ao visor da trena (0,548 m · 1,540 m)
        }
        val df = DecimalFormat(pattern, symbols)
        df.roundingMode = RoundingMode.HALF_UP
        return df.format(fromMm(mm, u))
    }

    fun format(mm: Double, u: LengthUnit): String = formatNumber(mm, u) + " " + u.label

    /** Texto da cota. Vazio enquanto a cota aguarda medida (nada é mostrado na seta). */
    fun labelSeg(seg: br.com.arque.measure.model.Seg, u: LengthUnit): String =
        seg.valueMm?.let { format(it, u) } ?: PENDING_LABEL

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
