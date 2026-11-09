package br.com.arque.measure.sync

import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest

/**
 * Sincronizar com outro aparelho (Wi-Fi): o que cada aparelho tem, o que falta e o que mudou.
 * Trabalha direto nos arquivos do app ("files/", a mesma estrutura no Android, iPhone e Windows):
 *  - notas: projects/index.json (lista) + projects/notes/<id>.json + fotos em projects/images/
 *  - orçamentos: projects/quotes.json · agenda: projects/agenda.json · projetos de móveis: moveis/projects.json
 * Cada item tem uma identidade (id) e uma "impressão digital" (hash do conteúdo em JSON canônico, igual em
 * todos os aparelhos), assim o mesmo item nunca é copiado duas vezes e dá pra saber se está igual ou diferente.
 * Este arquivo é igual no Android e no Windows (e o iPhone tem a mesma regra em Swift).
 */
object SyncCore {
    const val VERSION = 1
    val KINDS = listOf("note", "proj", "quote", "agenda")

    data class Item(val k: String, val id: String, val title: String, val sub: String, val hash: String, val mod: Long) {
        fun key() = "$k|$id"
        fun toJson(): JSONObject = JSONObject().put("k", k).put("id", id).put("t", title).put("s", sub).put("h", hash).put("m", mod)
        companion object {
            fun from(j: JSONObject) = Item(j.getString("k"), j.getString("id"), j.optString("t"), j.optString("s"), j.optString("h"), j.optLong("m"))
        }
    }

    /** Como o item está nos dois aparelhos. */
    enum class State { SAME, ONLY_HERE, ONLY_THERE, DIFF }
    data class Row(val k: String, val id: String, val here: Item?, val there: Item?) {
        val state: State get() = when {
            here != null && there != null -> if (here.hash == there.hash) State.SAME else State.DIFF
            here != null -> State.ONLY_HERE
            else -> State.ONLY_THERE
        }
        val title: String get() = (here ?: there)!!.title
    }

    fun compare(here: List<Item>, there: List<Item>): List<Row> {
        val h = here.associateBy { it.key() }
        val t = there.associateBy { it.key() }
        val keys = (h.keys + t.keys).toSortedSet()
        return keys.map { k -> val a = h[k]; val b = t[k]; Row((a ?: b)!!.k, (a ?: b)!!.id, a, b) }
            .sortedWith(compareBy({ KINDS.indexOf(it.k) }, { it.title.lowercase() }))
    }

    // ---------- JSON canônico (mesma saída em Kotlin e Swift) ----------

    /** Chaves em ordem, números sem ".0" e com no máximo 6 casas, texto escapado igual em todo aparelho. */
    fun canon(v: Any?): String = StringBuilder().also { canonTo(it, v) }.toString()

    private fun canonTo(sb: StringBuilder, v: Any?) {
        when (v) {
            null, JSONObject.NULL -> sb.append("null")
            is Boolean -> sb.append(if (v) "true" else "false")
            is Number -> sb.append(num(v.toDouble()))
            is String -> str(sb, v)
            is JSONObject -> {
                sb.append('{')
                v.keys().asSequence().toList().sorted().forEachIndexed { i, k ->
                    if (i > 0) sb.append(',')
                    str(sb, k); sb.append(':'); canonTo(sb, v.opt(k))
                }
                sb.append('}')
            }
            is JSONArray -> {
                sb.append('[')
                for (i in 0 until v.length()) { if (i > 0) sb.append(','); canonTo(sb, v.opt(i)) }
                sb.append(']')
            }
            else -> str(sb, v.toString())
        }
    }

    fun num(d: Double): String {
        if (d.isNaN() || d.isInfinite()) return "null"
        if (Math.abs(d) >= 1e15) return String.format(java.util.Locale.ROOT, "%.0f", d)
        // até 1 bilhão: 6 casas; acima disso (ex.: datas em ms) número inteiro
        val r = if (Math.abs(d) < 1e9) Math.round(d * 1_000_000.0) / 1_000_000.0 else Math.rint(d)
        if (Math.abs(r - Math.rint(r)) < 1e-9) return if (r == 0.0) "0" else Math.rint(r).toLong().toString()
        var s = String.format(java.util.Locale.ROOT, "%.6f", r)
        s = s.trimEnd('0').trimEnd('.')
        return if (s == "-0") "0" else s
    }

    private fun str(sb: StringBuilder, s: String) {
        sb.append('"')
        for (c in s) {
            when {
                c == '"' -> sb.append("\\\"")
                c == '\\' -> sb.append("\\\\")
                c.code < 0x20 -> sb.append(String.format(java.util.Locale.ROOT, "\\u%04x", c.code))
                else -> sb.append(c)
            }
        }
        sb.append('"')
    }

    fun sha(text: String): String = MessageDigest.getInstance("SHA-256").digest(text.toByteArray(Charsets.UTF_8)).joinToString("") { "%02x".format(it) }

    fun hashOf(v: Any?): String = sha(canon(v))

    // ---------- leitura dos arquivos ----------

    private fun readText(f: File): String? {
        for (c in listOf(f, File(f.path + ".bak"))) { if (c.isFile) runCatching { return c.readText() } }
        return null
    }
    private fun arr(f: File): JSONArray = readText(f)?.let { runCatching { JSONArray(it) }.getOrNull() } ?: JSONArray()
    private fun obj(f: File): JSONObject? = readText(f)?.let { runCatching { JSONObject(it) }.getOrNull() }

    private fun projectsDir(files: File) = File(files, "projects")
    private fun indexFile(files: File) = File(projectsDir(files), "index.json")
    private fun noteFile(files: File, id: String) = File(projectsDir(files), "notes/$id.json")
    private fun listFile(files: File, k: String): File = when (k) {
        "quote" -> File(projectsDir(files), "quotes.json")
        "agenda" -> File(projectsDir(files), "agenda.json")
        else -> File(files, "moveis/projects.json")
    }

    private fun safeId(id: String) = id.isNotBlank() && id.length <= 80 && id.all { it.isLetterOrDigit() || it == '-' || it == '_' || it == '.' } && !id.contains("..")
    private fun safeName(n: String) = n.isNotBlank() && n.length <= 120 && !n.contains("/") && !n.contains("\\") && !n.contains("..")

    private fun dateLabel(ms: Long): String = if (ms <= 0) "" else runCatching {
        java.text.SimpleDateFormat("dd/MM/yyyy", java.util.Locale.ROOT).format(java.util.Date(ms))
    }.getOrDefault("")

    /** O que este aparelho tem (notas na lixeira ficam de fora). */
    fun manifest(files: File): List<Item> {
        val out = ArrayList<Item>()
        val idx = obj(indexFile(files))
        val notes = idx?.optJSONArray("notes") ?: JSONArray()
        for (i in 0 until notes.length()) {
            val m = notes.optJSONObject(i) ?: continue
            val id = m.optString("id"); if (!safeId(id) || m.optBoolean("trash")) continue
            val f = noteFile(files, id)
            val n = obj(f) ?: continue
            if (n.optBoolean("trash")) continue
            val pages = n.optJSONArray("pages")?.length() ?: 0
            out += Item("note", id, n.optString("name", m.optString("name")), "$pages folha(s)", hashOf(n), f.lastModified())
        }
        for (k in listOf("proj", "quote", "agenda")) {
            val a = arr(listFile(files, k))
            for (i in 0 until a.length()) {
                val o = a.optJSONObject(i) ?: continue
                val id = o.optString("id"); if (!safeId(id)) continue
                val (t, s, m) = when (k) {
                    "proj" -> {
                        val cl = o.optJSONObject("cliente")?.optString("nome").orEmpty()
                        val tt = o.optString("titulo").ifBlank { o.optString("nome") }
                        Triple(listOf(cl, tt).filter { it.isNotBlank() }.joinToString(" · ").ifBlank { "Projeto" }, dateLabel(o.optLong("updated")), o.optLong("updated", o.optLong("created")))
                    }
                    "quote" -> Triple(o.optString("client").ifBlank { "Orçamento" }, listOf(o.optString("city"), dateLabel(o.optLong("date"))).filter { it.isNotBlank() }.joinToString(" · "), o.optLong("date"))
                    else -> Triple(o.optString("title").ifBlank { "Compromisso" }, dateLabel(o.optLong("start")), o.optLong("start"))
                }
                out += Item(k, id, t, s, hashOf(o), m)
            }
        }
        return out
    }

    /** Tudo que o outro aparelho precisa pra ter o item igual (nota leva as fotos e a pasta). */
    fun export(files: File, k: String, id: String): JSONObject? {
        if (!safeId(id)) return null
        val p = JSONObject().put("k", k).put("id", id).put("v", VERSION)
        if (k == "note") {
            val n = obj(noteFile(files, id)) ?: return null
            p.put("obj", n)
            val idx = obj(indexFile(files))
            val notes = idx?.optJSONArray("notes") ?: JSONArray()
            for (i in 0 until notes.length()) { val m = notes.optJSONObject(i); if (m?.optString("id") == id) { p.put("meta", m); break } }
            val fid = n.optString("folderId", "").takeIf { it.isNotBlank() && it != "null" }
            if (fid != null) {
                val fs = idx?.optJSONArray("folders") ?: JSONArray()
                for (i in 0 until fs.length()) { val f = fs.optJSONObject(i); if (f?.optString("id") == fid) { p.put("folder", f); break } }
            }
            val imgs = JSONObject()
            for (name in photos(n)) {
                val f = File(projectsDir(files), "images/$name")
                if (safeName(name) && f.isFile) imgs.put(name, java.util.Base64.getEncoder().encodeToString(f.readBytes()))
            }
            p.put("images", imgs)
            return p
        }
        if (k !in KINDS) return null
        val a = arr(listFile(files, k))
        for (i in 0 until a.length()) { val o = a.optJSONObject(i); if (o?.optString("id") == id) return p.put("obj", o) }
        return null
    }

    private fun photos(n: JSONObject): List<String> {
        val out = ArrayList<String>()
        val pages = n.optJSONArray("pages") ?: return out
        for (i in 0 until pages.length()) {
            val objs = pages.optJSONObject(i)?.optJSONArray("objs") ?: continue
            for (j in 0 until objs.length()) { val o = objs.optJSONObject(j) ?: continue; if (o.optString("type") == "photo") o.optString("file").takeIf { it.isNotBlank() }?.let { out += it } }
        }
        return out
    }

    /** Escrita segura: .tmp e troca, guardando a anterior em .bak (igual ao resto do app). */
    private fun writeAtomic(f: File, text: String) {
        f.parentFile?.mkdirs()
        val tmp = File(f.path + ".tmp")
        tmp.writeText(text)
        if (f.exists()) { val bak = File(f.path + ".bak"); bak.delete(); f.copyTo(bak, overwrite = true) }
        if (!tmp.renameTo(f)) { f.writeText(text); tmp.delete() }
    }

    /** Grava o item recebido (cria ou troca pelo do outro aparelho). Retorna false se o pacote não presta (nada é gravado). */
    fun apply(files: File, p: JSONObject): Boolean {
        val k = p.optString("k"); val id = p.optString("id")
        if (!safeId(id) || k !in KINDS) return false
        val o = p.optJSONObject("obj") ?: return false
        if (o.optString("id") != id) return false
        if (k == "note") {
            if (!o.has("pages") || o.optJSONArray("pages") == null) return false
            val imgs = p.optJSONObject("images") ?: JSONObject()
            // fotos primeiro (a nota só aparece quando tudo dela já está gravado)
            for (name in imgs.keys().asSequence().toList()) {
                if (!safeName(name)) continue
                val bytes = runCatching { java.util.Base64.getDecoder().decode(imgs.getString(name)) }.getOrNull() ?: continue
                val f = File(projectsDir(files), "images/$name"); f.parentFile?.mkdirs()
                val tmp = File(f.path + ".tmp"); tmp.writeBytes(bytes); if (!tmp.renameTo(f)) { f.writeBytes(bytes); tmp.delete() }
            }
            writeAtomic(noteFile(files, id), o.toString())
            val idx = obj(indexFile(files)) ?: JSONObject().put("v", 1).put("folders", JSONArray()).put("notes", JSONArray())
            val folders = idx.optJSONArray("folders") ?: JSONArray().also { idx.put("folders", it) }
            p.optJSONObject("folder")?.let { f ->
                val fid = f.optString("id")
                if (safeId(fid) && (0 until folders.length()).none { folders.optJSONObject(it)?.optString("id") == fid }) folders.put(JSONObject().put("id", fid).put("name", f.optString("name", "Pasta")))
            }
            val meta = p.optJSONObject("meta") ?: JSONObject()
            val pages = o.optJSONArray("pages")?.length() ?: 1
            val m = JSONObject().put("id", id).put("name", o.optString("name", meta.optString("name", "Nota")))
                .put("folderId", o.opt("folderId") ?: JSONObject.NULL).put("createdMs", o.optLong("createdMs", meta.optLong("createdMs")))
                .put("pinned", o.optBoolean("pinned")).put("locked", o.optBoolean("locked")).put("trash", o.optBoolean("trash"))
                .put("pageCount", pages).put("dimCount", meta.optInt("dimCount", 0))
            val notes = idx.optJSONArray("notes") ?: JSONArray().also { idx.put("notes", it) }
            var found = false
            for (i in 0 until notes.length()) { if (notes.optJSONObject(i)?.optString("id") == id) { notes.put(i, m); found = true; break } }
            if (!found) notes.put(m)
            writeAtomic(indexFile(files), idx.toString())
            return true
        }
        val f = listFile(files, k)
        val a = arr(f)
        var found = false
        for (i in 0 until a.length()) { if (a.optJSONObject(i)?.optString("id") == id) { a.put(i, o); found = true; break } }
        if (!found) a.put(o)
        writeAtomic(f, a.toString())
        return true
    }

    fun kindLabel(k: String): String = when (k) {
        "note" -> "Nota"
        "proj" -> "Projeto de móveis"
        "quote" -> "Orçamento"
        else -> "Agenda"
    }
}
