package br.com.arque.measure

import br.com.arque.measure.logic.QuoteMath
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import org.junit.Assert.assertEquals
import org.junit.Test

class QuoteMathTest {
    private val q = Quote(
        items = listOf(QuoteItem(qty = 2.0, unitValue = 1500.5), QuoteItem(qty = 3.0, unitValue = 100.0)),
        discountPct = 10.0,
    )

    @Test fun totalsAndDiscount() {
        assertEquals(3301.0, QuoteMath.original(q), 0.001)
        assertEquals(330.1, QuoteMath.discountValue(q), 0.001)
        assertEquals(2970.9, QuoteMath.finalValue(q), 0.001)
    }

    @Test fun formatsAndParsesBrazilianNumbers() {
        assertEquals("R$ 1.234,50", QuoteMath.brl(1234.5))
        assertEquals(1234.56, QuoteMath.parseNum("1.234,56")!!, 0.0001)
        assertEquals(12.5, QuoteMath.parseNum("12,5")!!, 0.0001)
        assertEquals(12.5, QuoteMath.parseNum("12.5")!!, 0.0001)
        assertEquals("3", QuoteMath.numStr(3.0))
        assertEquals("2,5", QuoteMath.numStr(2.5))
    }

    @Test fun jsonRoundTrip() {
        val back = br.com.arque.measure.data.QuoteJson.quotesFromJson(br.com.arque.measure.data.QuoteJson.quotesToJson(listOf(q)))
        assertEquals(q, back[0])
    }
}
