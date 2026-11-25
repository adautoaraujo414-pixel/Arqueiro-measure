package br.com.arque.measure

import br.com.arque.measure.data.QuoteJson
import br.com.arque.measure.logic.QuoteMath
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import br.com.arque.measure.model.QuoteSection
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * ORC-AMB (Adauto 25/11): orçamento de vários ambientes do mesmo cliente.
 * Os números são os mesmos do teste do editor (testOrcamentoAmbientes…): tela = PDF, ao centavo.
 * Ordem do desconto: individual (em cada ambiente) → subtotal → geral.
 */
class QuoteAmbientesTest {
    private fun sec(pid: String, title: String, sug: Double, manual: Double? = null, d: Double = 0.0) = QuoteSection(
        id = "s-$pid", pid = pid, title = title, desc = "Móveis de $title", finish = "MDF 15 mm · caixa Branco",
        mat = 4321.09, labor = 1234.56, sug = sug, manual = manual, discountPct = d, at = 1_764_000_000_000L,
    )
    private val q = Quote(
        id = "orc1", items = emptyList(), clientName = "Cliente Ambientes", clientKey = "cliente ambientes", discountPct = 5.0,
        sections = listOf(sec("p1", "Cozinha", 1112.04), sec("p2", "Quarto", 3064.51, manual = 9000.0), sec("p3", "Sala", 830.55, d = 10.0)),
    )

    @Test fun descontoIndividualDepoisSubtotalDepoisGeralAoCentavo() {
        assertEquals(1112.04, QuoteMath.sectionFinal(q.sections[0]), 0.0)
        assertEquals(9000.0, QuoteMath.sectionFinal(q.sections[1]), 0.0)      // valor de venda digitado vale no lugar do sugerido
        assertEquals(83.06, QuoteMath.sectionDiscount(q.sections[2]), 0.0)
        assertEquals(747.49, QuoteMath.sectionFinal(q.sections[2]), 0.0)
        assertEquals(10859.53, QuoteMath.original(q), 0.0)                    // subtotal (já com o desconto de cada ambiente)
        assertEquals(83.06, QuoteMath.sectionsDiscount(q), 0.0)
        assertEquals(542.98, QuoteMath.discountValue(q), 0.0)                 // geral, sobre o subtotal
        assertEquals(10316.55, QuoteMath.finalValue(q), 0.0)
        assertEquals(10316.55, QuoteMath.grandTotal(q), 0.0)
    }

    @Test fun pdfCadaAmbienteComOValorEOsTotaisNoFim() {
        val a = QuotePdf.ambSections(q)
        assertEquals(listOf("1. Cozinha", "2. Quarto", "3. Sala"), a.map { it.title })
        assertEquals(listOf("Móveis de Cozinha", "Móveis de Quarto", "Móveis de Sala"), a.map { it.desc })
        assertTrue(a.all { it.finish == "Acabamentos: MDF 15 mm · caixa Branco" })
        assertEquals(listOf("R$ 1.112,04"), a[0].values)
        assertEquals(listOf("R$ 9.000,00"), a[1].values)
        assertEquals(listOf("R$ 830,55", "Desconto (10%) − R$ 83,06", "R$ 747,49"), a[2].values)
        val (rows, total) = QuotePdf.ambTotalRows(q)
        assertEquals(listOf("Soma dos ambientes" to "R$ 10.942,59", "Descontos dos ambientes" to "− R$ 83,06", "Subtotal" to "R$ 10.859,53", "Desconto geral (5%)" to "− R$ 542,98"), rows)
        assertEquals("R$ 10.316,55", total)
    }

    @Test fun pdfSoComOTotalMantemAsDescricoesPorAmbiente() {
        val t = q.copy(onlyTotal = true)
        val a = QuotePdf.ambSections(t)
        assertEquals(3, a.size)
        assertTrue(a.all { it.values.isEmpty() && it.desc.isNotBlank() && it.finish.isNotBlank() })
        val (rows, total) = QuotePdf.ambTotalRows(t)
        assertTrue(rows.isEmpty())
        assertEquals("R$ 10.316,55", total)
    }

    @Test fun custoInternoNuncaSaiNoPdf() {
        for (x in listOf(q, q.copy(onlyTotal = true))) {
            val txt = (QuotePdf.ambSections(x).flatMap { listOf(it.title, it.desc, it.finish) + it.values } +
                QuotePdf.ambTotalRows(x).first.flatMap { listOf(it.first, it.second) } + QuotePdf.ambTotalRows(x).second).joinToString("\n")
            assertFalse(txt.contains(QuoteMath.brl(4321.09)))
            assertFalse(txt.contains(QuoteMath.brl(1234.56)))
            assertFalse(txt.contains("Material"))
            assertFalse(txt.contains("Mão de obra"))
        }
    }

    @Test fun oMesmoProjetoNuncaEntraDuasVezes() {
        val arr = JSONArray(listOf(sec("p1", "Cozinha", 100.0), sec("p2", "Quarto", 200.0), sec("p1", "Cozinha de novo", 300.0)).map { QuoteJson.sectionToJson(it) })
        val s = QuoteJson.sectionsFromPayload(arr)
        assertEquals(listOf("p1", "p2"), s.map { it.pid })
        assertEquals("Cozinha", s[0].title)                                    // fica o que já estava
    }

    @Test fun orcamentoComAmbientesSalvaEReabreIgual() {
        val back = QuoteJson.quotesFromJson(QuoteJson.quotesToJson(listOf(q, q.copy(id = "orc2", onlyTotal = true))))
        assertEquals(q, back[0])
        assertTrue(back[1].onlyTotal)
        assertEquals(10316.55, QuoteMath.finalValue(back[0]), 0.0)
    }

    @Test fun orcamentoAntigoSemAmbientesAbreCalculaEGravaIgual() {
        val old = """[{"id":"x1","client":"Maria","city":"","date":1700000000000,"discount":10,"validity":15,"drawing":false,"noteId":null,"notes":"","items":[{"id":"i1","desc":"Cozinha","qty":2,"unit":"un","value":1500.5},{"id":"i2","desc":"Aéreo","qty":3,"unit":"un","value":100}],"addenda":[],"photos":[],"pid":null}]"""
        val o = QuoteJson.quotesFromJson(old)[0]
        assertTrue(o.sections.isEmpty())
        assertEquals(null, o.clientKey)
        assertFalse(o.onlyTotal)
        assertEquals(3301.0, QuoteMath.original(o), 0.0)
        assertEquals(2970.9, QuoteMath.finalValue(o), 0.0)
        // grava com as mesmas chaves de antes (nenhuma chave nova no orçamento de sempre)
        val j = JSONArray(QuoteJson.quotesToJson(listOf(o))).getJSONObject(0)
        assertEquals(setOf("id", "client", "city", "date", "discount", "validity", "drawing", "noteId", "notes", "items", "addenda", "photos", "pid"), j.keys().asSequence().toSet())
        // e o orçamento de itens novo continua igual (o mesmo do QuoteMathTest)
        val q0 = Quote(items = listOf(QuoteItem(qty = 2.0, unitValue = 1500.5), QuoteItem(qty = 3.0, unitValue = 100.0)), discountPct = 10.0)
        assertEquals(2970.9, QuoteMath.finalValue(q0), 0.0)
        assertFalse(JSONObject(JSONArray(QuoteJson.quotesToJson(listOf(q0))).getJSONObject(0).toString()).has("sections"))
    }
}
