package br.com.arque.measure

import br.com.arque.measure.license.License
import org.junit.Assert.assertEquals
import org.junit.Test

/** Final da senha do mês: "9", "10"… em 2026; mês e ano com 2 dígitos de 2027 em diante. */
class LicenseTest {
    @Test
    fun finalDaSenhaDoMes() {
        assertEquals("9", License.monthKey(2026, 9))
        assertEquals("10", License.monthKey(2026, 10))
        assertEquals("12", License.monthKey(2026, 12))
        assertEquals("0127", License.monthKey(2027, 1))
        assertEquals("0227", License.monthKey(2027, 2))
        assertEquals("1227", License.monthKey(2027, 12))
        assertEquals("0128", License.monthKey(2028, 1))
        assertEquals("R$ 29,90", License.PRICE)
        assertEquals(30, License.PERIOD_DAYS)
    }
}
