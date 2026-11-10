package br.com.arque.measure

import br.com.arque.measure.model.Holidays
import br.com.arque.measure.model.Holidays.Kind
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class HolidaysTest {
    private fun date(y: Int, name: String) = Holidays.of(y).filter { it.name == name }.map { "%02d/%02d".format(it.day, it.month) }

    @Test fun `pascoa e os feriados que dependem dela`() {
        assertEquals(4 to 5, Holidays.easter(2026))
        assertEquals(3 to 28, Holidays.easter(2027))
        assertEquals(4 to 20, Holidays.easter(2025))
        assertEquals(listOf("03/04"), date(2026, "Sexta-feira Santa"))
        assertEquals(listOf("26/03"), date(2027, "Sexta-feira Santa"))
        assertEquals(listOf("08/02", "09/02"), date(2027, "Carnaval"))
        assertEquals(listOf("10/02"), date(2027, "Quarta-feira de Cinzas"))
        assertEquals(listOf("27/05"), date(2027, "Corpus Christi"))
        assertEquals(listOf("04/06"), date(2026, "Corpus Christi"))
    }

    @Test fun `os 10 feriados nacionais de 2027`() {
        val f = Holidays.of(2027).filter { it.kind == Kind.FERIADO }.map { "%02d/%02d".format(it.day, it.month) }
        assertEquals(listOf("01/01", "26/03", "21/04", "01/05", "07/09", "12/10", "02/11", "15/11", "20/11", "25/12"), f)
    }

    @Test fun `dia das maes e dos pais no segundo domingo`() {
        assertEquals(listOf("10/05"), date(2026, "Dia das Mães"))
        assertEquals(listOf("09/08"), date(2026, "Dia dos Pais"))
        assertEquals(listOf("09/05"), date(2027, "Dia das Mães"))
    }

    @Test fun `novembro igual ao google agenda e filtro das comemorativas`() {
        val nov = Holidays.of(2026).filter { it.month == 11 && it.kind == Kind.FERIADO }.map { it.day to it.name }
        assertEquals(listOf(2 to "Finados", 15 to "Proclamação da República", 20 to "Dia da Consciência Negra"), nov)
        assertEquals(Kind.COMEMORATIVA, Holidays.on(2023, 11, 20).first().kind)
        assertTrue(Holidays.on(2026, 10, 12).size == 2)
        assertTrue(Holidays.on(2026, 10, 12, comemorativas = false).single().name == "Nossa Senhora Aparecida")
        assertTrue(Holidays.on(2026, 6, 12, comemorativas = false).isEmpty())
    }
}
