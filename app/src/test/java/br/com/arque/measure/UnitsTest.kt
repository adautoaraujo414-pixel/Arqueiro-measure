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
        assertEquals("1,54 m", Units.format(1540.0, LengthUnit.M))
    }

    @Test fun `medida da trena nao arredonda os milimetros`() {
        val mm = br.com.arque.measure.ble.BoschProtocol.metersToMm(0.2458f)
        assertEquals(245.8, mm, 1e-9)
        assertEquals("245,8 mm", Units.format(mm, LengthUnit.MM))
        assertEquals("24,58 cm", Units.format(mm, LengthUnit.CM))
        assertEquals("0,2458 m", Units.format(mm, LengthUnit.M))
        assertEquals("2458 mm", Units.format(2458.0, LengthUnit.MM))
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
