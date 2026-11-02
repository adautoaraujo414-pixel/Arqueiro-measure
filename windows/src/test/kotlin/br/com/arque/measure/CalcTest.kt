package br.com.arque.measure

import br.com.arque.measure.logic.Calc
import org.junit.Assert.*
import org.junit.Test

class CalcTest {
    @Test fun precedenceAndComma() {
        assertEquals(14.0, Calc.eval("2+3×4")!!, 1e-9)
        assertEquals(1.54 + 0.98, Calc.eval("1,54+0,98")!!, 1e-9)
        assertEquals(20.0, Calc.eval("(2+3)×4")!!, 1e-9)
        assertEquals(50.0, Calc.eval("100×50%")!!, 1e-9)
        assertEquals(-3.0, Calc.eval("-5+2")!!, 1e-9)
    }
    @Test fun invalid() {
        assertNull(Calc.eval("5÷0"))
        assertNull(Calc.eval("2+"))
        assertNull(Calc.eval("(2"))
        assertNull(Calc.eval(""))
    }
    @Test fun formats() {
        assertEquals("2,52", Calc.format(2.52))
        assertEquals("14", Calc.format(14.0))
    }
}
