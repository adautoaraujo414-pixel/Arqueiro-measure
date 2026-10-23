package br.com.arque.measure.data

import br.com.arque.measure.model.Appointment
import br.com.arque.measure.model.ApptKind
import br.com.arque.measure.model.ClientRef
import org.json.JSONArray
import org.json.JSONObject

object AgendaJson {
    fun toJson(list: List<Appointment>): String = JSONArray(list.map { a ->
        JSONObject().put("id", a.id).put("kind", a.kind.name).put("title", a.title).put("start", a.startMs)
            .put("address", a.address).put("notes", a.notes).put("client", a.clientName).put("phone", a.clientPhone)
            .put("projectId", a.projectId ?: JSONObject.NULL).put("noteId", a.noteId ?: JSONObject.NULL)
            .put("quoteId", a.quoteId ?: JSONObject.NULL).put("done", a.done)
            .put("remind", JSONArray(a.remindMin))
    }).toString()

    fun fromJson(s: String): List<Appointment> {
        val a = JSONArray(s)
        return (0 until a.length()).map { k ->
            val j = a.getJSONObject(k)
            val r = j.optJSONArray("remind") ?: JSONArray()
            fun opt(n: String): String? = if (j.isNull(n) || !j.has(n)) null else j.optString(n).ifBlank { null }
            Appointment(
                id = j.getString("id"),
                kind = runCatching { ApptKind.valueOf(j.optString("kind")) }.getOrDefault(ApptKind.OUTRO),
                title = j.optString("title"), startMs = j.optLong("start"), address = j.optString("address"),
                notes = j.optString("notes"), clientName = j.optString("client"), clientPhone = j.optString("phone"),
                projectId = opt("projectId"), noteId = opt("noteId"), quoteId = opt("quoteId"),
                remindMin = (0 until r.length()).map { r.getInt(it) }, done = j.optBoolean("done", false),
            )
        }
    }

    /** Lê os clientes salvos no editor de móveis (arquivo espelho moveis/projects.json). */
    fun clientsFromProjects(json: String): List<ClientRef> = runCatching {
        val a = JSONArray(json)
        (0 until a.length()).mapNotNull { k ->
            val p = a.getJSONObject(k)
            val c = p.optJSONObject("client") ?: return@mapNotNull null
            val nome = c.optString("nome").trim()
            if (nome.isBlank()) null else ClientRef(nome, c.optString("tel"), p.optString("id"),
                listOf(c.optString("end"), c.optString("cidade")).filter { it.isNotBlank() }.joinToString(" · "))
        }
    }.getOrDefault(emptyList())
}
