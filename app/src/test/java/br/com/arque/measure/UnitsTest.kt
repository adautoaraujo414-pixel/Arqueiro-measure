package br.com.arque.measure

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
}
