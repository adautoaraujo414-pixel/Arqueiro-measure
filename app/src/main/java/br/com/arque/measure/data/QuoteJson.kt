package br.com.arque.measure.data

import br.com.arque.measure.model.Company
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteAddendum
import br.com.arque.measure.model.QuoteItem
import br.com.arque.measure.model.QuoteSection
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
            .put("addenda", JSONArray(q.addenda.map { a -> JSONObject().put("id", a.id).put("desc", a.desc).put("value", a.value).put("date", a.dateMs) }))
            .put("photos", JSONArray(q.photos))
            .put("pid", q.projId ?: JSONObject.NULL)
            // ORC-AMB: só grava as chaves novas quando o orçamento tem ambientes (o orçamento de sempre sai igual ao de antes)
            .also { o ->
                if (q.sections.isNotEmpty()) o.put("sections", JSONArray(q.sections.map { sectionToJson(it) }))
                if (q.clientKey != null) o.put("clientKey", q.clientKey)
                if (q.onlyTotal) o.put("onlyTotal", true)
            }
    }).toString()

    fun sectionToJson(s: QuoteSection): JSONObject = JSONObject().put("id", s.id).put("pid", s.pid).put("title", s.title).put("desc", s.desc)
        .put("finish", s.finish).put("mat", s.mat).put("labor", s.labor).put("sug", s.sug).put("manual", s.manual ?: JSONObject.NULL)
        .put("discount", s.discountPct).put("at", s.at)

    /** ORC-AMB: ambientes que vêm do editor; o mesmo projeto (pid) nunca entra duas vezes (fica o primeiro). */
    fun sectionsFromPayload(arr: JSONArray?): List<QuoteSection> = if (arr == null) emptyList() else
        (0 until arr.length()).map { sectionFromJson(arr.getJSONObject(it)) }.distinctBy { it.pid.ifBlank { it.id } }

    fun sectionFromJson(j: JSONObject): QuoteSection = QuoteSection(
        id = j.optString("id").ifBlank { br.com.arque.measure.model.newId() }, pid = j.optString("pid"), title = j.optString("title"),
        desc = j.optString("desc"), finish = j.optString("finish"), mat = j.optDouble("mat", 0.0).let { if (it.isNaN()) 0.0 else it },
        labor = j.optDouble("labor", 0.0).let { if (it.isNaN()) 0.0 else it }, sug = j.optDouble("sug", 0.0).let { if (it.isNaN()) 0.0 else it },
        manual = if (j.isNull("manual")) null else j.optDouble("manual", 0.0).takeIf { !it.isNaN() && it > 0.0 },
        discountPct = j.optDouble("discount", 0.0).let { if (it.isNaN()) 0.0 else it.coerceIn(0.0, 100.0) }, at = j.optLong("at", 0L),
    )

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
                addenda = (j.optJSONArray("addenda") ?: JSONArray()).let { ad ->
                    (0 until ad.length()).map { n -> val a = ad.getJSONObject(n); QuoteAddendum(a.getString("id"), a.optString("desc"), a.optDouble("value", 0.0), a.optLong("date", System.currentTimeMillis())) }
                },
                photos = (j.optJSONArray("photos") ?: JSONArray()).let { ph -> (0 until ph.length()).map { n -> ph.getString(n) } },
                projId = if (j.isNull("pid")) null else j.optString("pid").ifBlank { null },
                sections = (j.optJSONArray("sections") ?: JSONArray()).let { sc -> (0 until sc.length()).map { n -> sectionFromJson(sc.getJSONObject(n)) } },
                clientKey = if (j.has("clientKey") && !j.isNull("clientKey")) j.optString("clientKey").ifBlank { null } else null,
                onlyTotal = j.optBoolean("onlyTotal", false),
            )
        }
    }
}
