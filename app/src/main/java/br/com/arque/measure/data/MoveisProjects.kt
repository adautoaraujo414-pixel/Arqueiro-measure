package br.com.arque.measure.data

import br.com.arque.measure.i18n.tr

import android.content.Context
import org.json.JSONArray
import java.io.File

/** Projetos do editor de móveis (arquivo moveis/projects.json, o mesmo que o editor usa). */
object MoveisProjects {
    data class P(val id: String, val name: String, val created: Long, val updated: Long, val mods: Int, val auto: Boolean, val status: String = "orc", val title: String = "", val room: String = "cozinha", val city: String = "", val corte: Boolean = false, val from: String = "") {
        /** Nome do projeto: o que a pessoa deu (ex.: "Suíte") ou o ambiente do editor (Cozinha, Banheiro…). */
        val label: String get() = title.ifBlank { roomLabel(room) }
    }

    fun roomLabel(r: String): String = when (r) {
        "banho" -> tr("Banheiro")
        "sala" -> tr("Sala")
        "quarto" -> tr("Quarto")
        "escr" -> tr("Escritório")
        "livre" -> tr("Livre (tudo)")
        else -> tr("Cozinha")
    }

    /** Status do projeto escolhido pela pessoa: orçamento, fechado (cliente fechou), produção, finalizado. */
    val STATUS = listOf("orc", "fech", "prod", "fin")
    fun statusLabel(s: String): String = when (s) {
        "fech" -> tr("Fechado")
        "prod" -> tr("Produção")
        "fin" -> tr("Finalizado")
        else -> tr("Orçamento")
    }
    fun statusColor(s: String): Long = when (s) {
        "fech" -> 0xFF1F9D55
        "prod" -> 0xFFD9822B
        "fin" -> 0xFF2F6BE0
        else -> 0xFF6B7280
    }

    private fun file(ctx: Context) = File(ctx.filesDir, "moveis/projects.json")

    fun list(ctx: Context): List<P> = runCatching {
        val f = file(ctx)
        if (!f.exists()) return emptyList()
        val a = JSONArray(f.readText())
        (0 until a.length()).map { k ->
            val p = a.getJSONObject(k)
            val nome = p.optJSONObject("client")?.optString("nome")?.trim().orEmpty()
            val cur = p.optJSONObject("current")
            val mods = cur?.optJSONArray("mods")?.length() ?: 0
            val room = cur?.optString("room").orEmpty().ifBlank { if (cur?.optString("env") == "livre") "livre" else "cozinha" }
            P(
                p.optString("id"), nome.ifBlank { tr("Projeto sem nome") }, p.optLong("created"), p.optLong("updated", p.optLong("created")), mods, p.optBoolean("auto"),
                p.optString("status").ifBlank { "orc" }, p.optString("titulo").trim(), room, p.optJSONObject("client")?.optString("cidade")?.trim().orEmpty(),
                p.has("corte"), p.optJSONObject("corte")?.optString("fr")?.trim().orEmpty(),
            )
        }.filter { it.id.isNotBlank() }.sortedByDescending { it.updated }
    }.getOrDefault(emptyList())

    private fun edit(ctx: Context, f: (JSONArray) -> JSONArray) {
        runCatching {
            val fl = file(ctx)
            if (!fl.exists()) return
            val out = f(JSONArray(fl.readText()))
            val tmp = File(fl.parentFile, fl.name + ".tmp")
            tmp.writeText(out.toString())
            tmp.renameTo(fl)
        }
    }

    fun delete(ctx: Context, id: String) = edit(ctx) { a ->
        val n = JSONArray()
        for (k in 0 until a.length()) { val p = a.getJSONObject(k); if (p.optString("id") != id) n.put(p) }
        n
    }

    fun setStatus(ctx: Context, id: String, status: String) = edit(ctx) { a ->
        for (k in 0 until a.length()) {
            val p = a.getJSONObject(k)
            if (p.optString("id") == id) { p.put("status", status); p.put("updated", System.currentTimeMillis()) }
        }
        a
    }

    fun rename(ctx: Context, id: String, name: String) = edit(ctx) { a ->
        for (k in 0 until a.length()) {
            val p = a.getJSONObject(k)
            if (p.optString("id") == id) {
                val c = p.optJSONObject("client") ?: org.json.JSONObject().also { p.put("client", it) }
                c.put("nome", name.trim()); p.put("auto", false); p.put("updated", System.currentTimeMillis())
            }
        }
        a
    }

    /** Nome do projeto (ex.: "Cozinha", "Suíte"); o nome do cliente continua o mesmo. */
    fun setTitle(ctx: Context, id: String, title: String) = edit(ctx) { a ->
        for (k in 0 until a.length()) {
            val p = a.getJSONObject(k)
            if (p.optString("id") == id) { p.put("titulo", title.trim()); p.put("updated", System.currentTimeMillis()) }
        }
        a
    }
}
