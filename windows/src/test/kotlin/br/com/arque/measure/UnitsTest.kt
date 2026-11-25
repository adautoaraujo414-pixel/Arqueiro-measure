package br.com.arque.measure

import br.com.arque.measure.logic.UnitPref
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.LengthUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class UnitsTest {
    @Test fun `converte entre unidades sem perder o valor em mm`() {
        assertEquals(2345.0, Units.toMm(234.5, LengthUnit.CM), 1e-9)
        assertEquals(2345.0, Units.toMm(2.345, LengthUnit.M), 1e-9)
        assertEquals(2.345, Units.fromMm(2345.0, LengthUnit.M), 1e-9)
    }

    @Test fun `formata com virgula decimal e sufixo`() {
        assertEquals("2345 mm", Units.format(2345.0, LengthUnit.MM))
        assertEquals("234,5 cm", Units.format(2345.0, LengthUnit.CM))
        assertEquals("2,345 m", Units.format(2345.0, LengthUnit.M))
        assertEquals("1,540 m", Units.format(1540.0, LengthUnit.M))
    }

    @Test fun `medida da trena sai igual ao visor`() {
        val P = br.com.arque.measure.ble.BoschProtocol
        assertEquals(548.0, P.metersToMm(0.5477f), 1e-9)
        assertEquals("0,548 m", Units.format(P.metersToMm(0.5477f), LengthUnit.M))
        assertEquals("2,829 m", Units.format(P.metersToMm(2.8291f), LengthUnit.M))
        assertEquals("1,142 m", Units.format(P.metersToMm(1.1418f), LengthUnit.M))
        assertEquals("802 mm", Units.format(P.metersToMm(0.802f), LengthUnit.MM))
        assertEquals("54,8 cm", Units.format(P.metersToMm(0.5477f), LengthUnit.CM))
        // digitado à mão continua com décimo
        assertEquals("245,8 mm", Units.format(245.8, LengthUnit.MM))
        assertEquals("0,246 m", Units.format(245.8, LengthUnit.M))
        assertEquals("0,548 m", Units.format(547.7, LengthUnit.M)) // medida antiga salva com décimo
    }

    @Test fun `interpreta texto digitado`() {
        assertEquals(2345.0, Units.parseToMm("2345", LengthUnit.MM)!!, 1e-9)
        assertEquals(2345.0, Units.parseToMm("234,5", LengthUnit.CM)!!, 1e-9)
        assertEquals(2345.0, Units.parseToMm("2.345 m", LengthUnit.MM)!!, 1e-9)
        assertEquals(1200.0, Units.parseToMm("120cm", LengthUnit.M)!!, 1e-9)
    }

    @Test fun `rejeita texto invalido ou nao positivo`() {
        assertNull(Units.parseToMm("", LengthUnit.MM))
        assertNull(Units.parseToMm("abc", LengthUnit.MM))
        assertNull(Units.parseToMm("0", LengthUnit.MM))
        assertNull(Units.parseToMm("-5", LengthUnit.MM))
    }

    @Test
    fun digitadoEmMmComTelaEmMetroOuCm() {
        assertEquals(1950.0, Units.typedToMm(1950.0, LengthUnit.M), 1e-9)
        assertEquals(1968.0, Units.typedToMm(1968.0, LengthUnit.CM), 1e-9)
        assertEquals("195,0", Units.formatNumber(Units.typedToMm(1950.0, LengthUnit.M), LengthUnit.CM))
        assertEquals(1955.0, Units.typedToMm(195.5, LengthUnit.CM), 1e-9)
        assertEquals(1950.0, Units.typedToMm(1.95, LengthUnit.M), 1e-9)
        assertEquals(600.0, Units.typedToMm(60.0, LengthUnit.M), 1e-9)
        assertEquals(2750.0, Units.typedToMm(2750.0, LengthUnit.MM), 1e-9)
        assertEquals("1000,9 cm", Units.format(10009.0, LengthUnit.CM))
        assertEquals("189,8 cm", Units.format(1898.0, LengthUnit.CM))
        assertEquals("200,0 cm", Units.format(2000.0, LengthUnit.CM))
    }

    // UNIDADE (Adauto 25/11): unidade de tela mm/cm dos Ajustes. Internamente tudo em mm; só muda o que aparece e a leitura do digitado.
    @Test fun `unidade cm mostra o mm exato sem inventar fracao`() {
        assertEquals("69,5", UnitPref.show(695L, LengthUnit.CM))
        assertEquals("1,5", UnitPref.show(15L, LengthUnit.CM))
        assertEquals("3,5", UnitPref.show(35L, LengthUnit.CM))
        assertEquals("69", UnitPref.show(690L, LengthUnit.CM))
        assertEquals("0,5", UnitPref.show(5L, LengthUnit.CM))
        assertEquals("0", UnitPref.show(0L, LengthUnit.CM))
        assertEquals("695", UnitPref.show(695L, LengthUnit.MM))
        assertEquals("63,45", UnitPref.show(java.math.BigDecimal("634.5"), LengthUnit.CM))
    }

    @Test fun `unidade cm le virgula ou ponto e grava mm`() {
        assertEquals(java.math.BigDecimal("695"), UnitPref.read("69,5", LengthUnit.CM))
        assertEquals(java.math.BigDecimal("695"), UnitPref.read("69.5", LengthUnit.CM))
        assertEquals(java.math.BigDecimal("15"), UnitPref.read("1,5", LengthUnit.CM))
        assertEquals(java.math.BigDecimal("35"), UnitPref.read(" 3.5 ", LengthUnit.CM))
        assertEquals(java.math.BigDecimal("600"), UnitPref.read("60", LengthUnit.CM))
        assertEquals(java.math.BigDecimal("695"), UnitPref.read("695", LengthUnit.MM))
        assertNull(UnitPref.read("abc", LengthUnit.CM))
        assertNull(UnitPref.read("", LengthUnit.CM))
        assertNull(UnitPref.read("6,9,5", LengthUnit.CM))
    }

    @Test fun `ida e volta mm cm sem perda e alternar 20 vezes nao muda nada`() {
        for (mm in 0L..100000L) {
            val cm = UnitPref.show(mm, LengthUnit.CM)
            assertEquals("mm $mm", java.math.BigDecimal.valueOf(mm), UnitPref.read(cm, LengthUnit.CM))
            assertEquals("mm $mm", java.math.BigDecimal.valueOf(mm), UnitPref.read(cm.replace(',', '.'), LengthUnit.CM))
        }
        var v = java.math.BigDecimal("2750")
        repeat(20) { v = UnitPref.read(UnitPref.show(v, LengthUnit.CM), LengthUnit.CM)!!; v = UnitPref.read(UnitPref.show(v, LengthUnit.MM), LengthUnit.MM)!! }
        assertEquals(java.math.BigDecimal("2750"), v)
    }

    @Test fun `preferencia salva le e grava no mesmo formato e sem escolha fica como antes`() {
        assertEquals("{\"v\":1,\"unidade\":\"cm\"}", UnitPref.json(LengthUnit.CM))
        assertEquals(LengthUnit.CM, UnitPref.parse(UnitPref.json(LengthUnit.CM)))
        assertEquals(LengthUnit.MM, UnitPref.parse(UnitPref.json(LengthUnit.MM)))
        assertNull(UnitPref.parse(null))
        assertNull(UnitPref.parse(""))
        assertNull(UnitPref.parse("{lixo"))
        // sem escolha = mm em tudo, inclusive a nota nova (decisão do Adauto 25/11; antes nascia em cm); com escolha, os dois seguem os Ajustes
        assertEquals("mm", UnitPref.editor(null))
        assertEquals(LengthUnit.MM, UnitPref.newNote(null))
        assertEquals("cm", UnitPref.editor(LengthUnit.CM))
        assertEquals(LengthUnit.CM, UnitPref.newNote(LengthUnit.CM))
        assertEquals("mm", UnitPref.editor(LengthUnit.MM))
        assertEquals(LengthUnit.MM, UnitPref.newNote(LengthUnit.MM))
        // a nota antiga continua com a unidade dela (o caderno guarda por nota; M continua existindo)
        assertEquals(3, LengthUnit.values().size)
    }
}
