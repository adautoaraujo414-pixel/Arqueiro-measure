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

    @Test fun addendaAddAfterTheDiscountAndDoNotChangeTheOriginal() {
        val a = q.copy(addenda = listOf(
            br.com.arque.measure.model.QuoteAddendum(desc = "Nicho a mais", value = 450.0, dateMs = 1_700_000_000_000L),
            br.com.arque.measure.model.QuoteAddendum(desc = "Troca de puxador", value = 120.55, dateMs = 1_700_100_000_000L),
        ))
        assertEquals(3301.0, QuoteMath.original(a), 0.001)
        assertEquals(2970.9, QuoteMath.finalValue(a), 0.001)   // o orçamento original não muda
        assertEquals(570.55, QuoteMath.addendaTotal(a), 0.001)
        assertEquals(3541.45, QuoteMath.grandTotal(a), 0.001)
        assertEquals(QuoteMath.finalValue(q), QuoteMath.grandTotal(q), 0.001)   // sem aditivo: total geral = orçamento
    }

    @Test fun jsonKeepsAddendaAndPhotosAndReadsOldFiles() {
        val a = q.copy(
            addenda = listOf(br.com.arque.measure.model.QuoteAddendum(desc = "Nicho a mais", value = 450.0, dateMs = 1_700_000_000_000L)),
            photos = listOf("orc-1.jpg", "orc-2.jpg"),
        )
        val json = br.com.arque.measure.data.QuoteJson.quotesToJson(listOf(a))
        assertEquals(a, br.com.arque.measure.data.QuoteJson.quotesFromJson(json)[0])
        // arquivo antigo (sem aditivos nem fotos) continua abrindo, com as listas vazias
        val old = """[{"id":"x1","client":"Maria","city":"","date":1700000000000,"discount":0,"validity":15,"drawing":false,"noteId":null,"notes":"","items":[{"id":"i1","desc":"Cozinha","qty":1,"unit":"un","value":1000}]}]"""
        val o = br.com.arque.measure.data.QuoteJson.quotesFromJson(old)[0]
        assertEquals(0, o.addenda.size)
        assertEquals(0, o.photos.size)
        assertEquals(1000.0, QuoteMath.grandTotal(o), 0.001)
    }
}
