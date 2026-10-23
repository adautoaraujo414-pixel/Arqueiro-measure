package br.com.arque.measure.data

import android.content.Context
import org.json.JSONArray
import java.io.File

/** Projetos do editor de móveis (arquivo moveis/projects.json, o mesmo que o editor usa). */
object MoveisProjects {
    data class P(val id: String, val name: String, val created: Long, val updated: Long, val mods: Int, val auto: Boolean)

    private fun file(ctx: Context) = File(ctx.filesDir, "moveis/projects.json")

    fun list(ctx: Context): List<P> = runCatching {
        val f = file(ctx)
        if (!f.exists()) return emptyList()
        val a = JSONArray(f.readText())
        (0 until a.length()).map { k ->
            val p = a.getJSONObject(k)
            val nome = p.optJSONObject("client")?.optString("nome")?.trim().orEmpty()
            val mods = p.optJSONObject("current")?.optJSONArray("mods")?.length() ?: 0
            P(p.optString("id"), nome.ifBlank { "Projeto sem nome" }, p.optLong("created"), p.optLong("updated", p.optLong("created")), mods, p.optBoolean("auto"))
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
}
