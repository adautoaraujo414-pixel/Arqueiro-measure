package br.com.arque.measure.data

import br.com.arque.measure.model.Company
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import org.json.JSONArray
import org.json.JSONObject

object QuoteJson {
    fun companyToJson(c: Company): String = JSONObject()
        .put("name", c.name).put("cnpj", c.cnpj).put("address", c.address).put("city", c.city).put("phone", c.phone)
        .toString()

    fun companyFromJson(s: String): Company = JSONObject(s).let {
        Company(it.optString("name"), it.optString("cnpj"), it.optString("address"), it.optString("city"), it.optString("phone"))
    }

    fun quotesToJson(list: List<Quote>): String = JSONArray(list.map { q ->
        JSONObject().put("id", q.id).put("client", q.clientName).put("city", q.city).put("date", q.dateMs)
            .put("discount", q.discountPct).put("validity", q.validityDays).put("drawing", q.includeDrawing)
            .put("noteId", q.noteId ?: JSONObject.NULL).put("notes", q.notes)
            .put("items", JSONArray(q.items.map { i ->
                JSONObject().put("id", i.id).put("desc", i.desc).put("qty", i.qty).put("unit", i.unit).put("value", i.unitValue)
            }))
    }).toString()

    fun quotesFromJson(s: String): List<Quote> {
        val a = JSONArray(s)
        return (0 until a.length()).map { k ->
            val j = a.getJSONObject(k)
            val its = j.optJSONArray("items") ?: JSONArray()
            Quote(
                id = j.getString("id"), clientName = j.optString("client"), city = j.optString("city"),
                dateMs = j.optLong("date", System.currentTimeMillis()),
                items = (0 until its.length()).map { n ->
                    val i = its.getJSONObject(n)
                    QuoteItem(i.getString("id"), i.optString("desc"), i.optDouble("qty", 1.0), i.optString("unit", "un"), i.optDouble("value", 0.0))
                },
                discountPct = j.optDouble("discount", 0.0), validityDays = j.optInt("validity", 15),
                includeDrawing = j.optBoolean("drawing", false),
                noteId = if (j.isNull("noteId")) null else j.optString("noteId"), notes = j.optString("notes"),
            )
        }
    }
}
