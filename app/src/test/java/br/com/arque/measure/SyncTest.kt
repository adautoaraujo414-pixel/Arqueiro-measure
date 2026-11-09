package br.com.arque.measure

import br.com.arque.measure.sync.SyncCore
import br.com.arque.measure.sync.SyncNet
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/** Sincronizar pelo Wi-Fi: dois aparelhos (duas pastas) conversando de verdade pela rede local deste computador. */
class SyncTest {
    private val falhas = ArrayList<String>()
    private fun t(n: String, c: Boolean, d: Any? = null) { if (!c) falhas += n + (if (d != null) " · $d" else "") }
    fun note(id: String, name: String, folder: String?, photo: String?, extra: Int = 0): JSONObject {
        val objs = JSONArray().put(JSONObject().put("id", "o1").put("type", "dim").put("x1", 10.5).put("y1", 20).put("value", 1234.0 + extra))
        if (photo != null) objs.put(JSONObject().put("id", "o2").put("type", "photo").put("file", photo).put("pxW", 100).put("pxH", 80))
        return JSONObject().put("v", 3).put("id", id).put("name", name).put("folderId", folder ?: JSONObject.NULL).put("createdMs", 1700000000000L).put("pinned", false).put("locked", false).put("trash", false).put("unit", "M")
            .put("pages", JSONArray().put(JSONObject().put("id", "p1").put("tpl", "ARAUJO").put("objs", objs)))
    }
    fun setup(dir: File, notes: List<Pair<JSONObject, String?>>, folders: List<Pair<String, String>>, quotes: JSONArray, agenda: JSONArray, projs: JSONArray) {
        dir.deleteRecursively(); val pj = File(dir, "projects"); File(pj, "notes").mkdirs(); File(pj, "images").mkdirs(); File(dir, "moveis").mkdirs()
        val idx = JSONObject().put("v", 3).put("folders", JSONArray(folders.map { JSONObject().put("id", it.first).put("name", it.second) }))
            .put("notes", JSONArray(notes.map { (n, _) -> JSONObject().put("id", n.getString("id")).put("name", n.getString("name")).put("folderId", n.opt("folderId")).put("createdMs", 1).put("pinned", false).put("locked", false).put("trash", n.optBoolean("trash")).put("pageCount", 1).put("dimCount", 1) }))
        File(pj, "index.json").writeText(idx.toString(2))
        for ((n, img) in notes) { File(pj, "notes/${n.getString("id")}.json").writeText(n.toString()); if (img != null) File(pj, "images/$img").writeBytes(ByteArray(5000) { (it % 251).toByte() }) }
        File(pj, "quotes.json").writeText(quotes.toString()); File(pj, "agenda.json").writeText(agenda.toString()); File(dir, "moveis/projects.json").writeText(projs.toString())
    }

    @Test
    fun doisAparelhosComparamEPassamSemDuplicar() {
    val root = File(System.getProperty("java.io.tmpdir"), "arqsync-" + System.nanoTime()); val A = File(root, "A"); val B = File(root, "B")
    // canônico
    t("canon: chaves em ordem, 1.0 vira 1, 0.1+0.2 fica 0.3", SyncCore.canon(JSONObject("{\"b\":1.0,\"a\":[0.30000000000000004,\"x\\\"y\",null,true]}")) == "{\"a\":[0.3,\"x\\\"y\",null,true],\"b\":1}", SyncCore.canon(JSONObject("{\"b\":1.0,\"a\":[0.30000000000000004,\"x\\\"y\",null,true]}")))
    t("canon: mesma coisa formatada diferente = mesmo hash", SyncCore.hashOf(JSONObject("{\"a\": 1, \"b\": \"ç\"}")) == SyncCore.hashOf(JSONObject("{\"b\":\"ç\",\"a\":1.0}")))
    t("canon: números", listOf(SyncCore.num(-0.0), SyncCore.num(12.3456789), SyncCore.num(1.7e12), SyncCore.num(-5.5)) == listOf("0", "12.345679", "1700000000000", "-5.5"), listOf(SyncCore.num(-0.0), SyncCore.num(12.3456789), SyncCore.num(1.7e12), SyncCore.num(-5.5)))

    // A: iPhone da rua — nota nova com foto em pasta, nota igual, nota alterada, orçamento, projeto
    val same = note("n-same", "Cozinha Maria", null, null)
    setup(A, listOf(note("n-rua", "Medição rua", "f1", "foto1.jpg") to "foto1.jpg", same to null, note("n-dif", "Sala João", null, null, 7) to null, note("n-lixo", "Lixo", null, null).put("trash", true) to null),
        listOf("f1" to "Obras 2026"),
        JSONArray().put(JSONObject().put("id", "q1").put("client", "Maria").put("city", "Frutal").put("date", 1700000000000L).put("items", JSONArray())),
        JSONArray(), JSONArray().put(JSONObject().put("id", "p1").put("titulo", "Cozinha").put("cliente", JSONObject().put("nome", "Maria")).put("updated", 1700000000000L).put("estado", JSONObject().put("W", 3200))))
    // B: Windows de casa — nota igual (formatada diferente), mesma nota alterada, compromisso que A não tem
    setup(B, listOf(JSONObject(same.toString(4)) to null, note("n-dif", "Sala João", null, null, 0) to null), listOf(),
        JSONArray(), JSONArray().put(JSONObject().put("id", "a1").put("kind", "VISITA").put("title", "Medir sala").put("start", 1700000500000L)), JSONArray())

    val events = mutableListOf<String>(); var backups = 0
    val host = SyncNet.Host(B, "Windows · Teste", { backups++ }, { events += it })
    t("host abre a porta", host.start(), host.port)
    val code = SyncNet.code("127.0.0.1", host.pin, host.port)
    val target = SyncNet.parse(code, listOf("127.0.0.5"))!!
    t("código 'final do IP-senha' aponta pro aparelho", target.hosts == listOf("127.0.0.1") && target.pin == host.pin, code)
    t("parse: IP completo e porta extra", SyncNet.parse("192.168.0.10-1234-2", emptyList()) == SyncNet.Target(listOf("192.168.0.10"), "1234", SyncNet.PORT + 2))
    t("parse: código errado é recusado", SyncNet.parse("10-12", listOf("192.168.0.2")) == null && SyncNet.parse("300-1234", listOf("192.168.0.2")) == null)
    val badPin = runCatching { SyncNet.Client.find(SyncNet.Target(listOf("127.0.0.1"), if (host.pin == "1111") "2222" else "1111", host.port)) }
    t("senha errada: avisa e não conecta", badPin.exceptionOrNull()?.message?.startsWith("Senha") == true, badPin.exceptionOrNull()?.message)
    val (cli, name) = SyncNet.Client.find(target)!!
    t("acha o outro aparelho e o nome dele", name == "Windows · Teste", name)
    val rows = SyncCore.compare(SyncCore.manifest(A), cli.manifest())
    val st = rows.associate { it.k + "|" + it.id to it.state }
    t("nota formatada diferente mas igual = IGUAL (não duplica)", st["note|n-same"] == SyncCore.State.SAME, st)
    t("nota alterada = DIFERENTE", st["note|n-dif"] == SyncCore.State.DIFF)
    t("só aqui: nota nova, orçamento, projeto", st["note|n-rua"] == SyncCore.State.ONLY_HERE && st["quote|q1"] == SyncCore.State.ONLY_HERE && st["proj|p1"] == SyncCore.State.ONLY_HERE)
    t("só lá: compromisso", st["agenda|a1"] == SyncCore.State.ONLY_THERE)
    t("lixeira não vai", st.keys.none { it.contains("n-lixo") })
    val send = rows.filter { it.state == SyncCore.State.ONLY_HERE }; val pull = rows.filter { it.state == SyncCore.State.ONLY_THERE || it.id == "n-dif" }
    var prog = 0; var localBk = 0
    val (okN, fail) = SyncNet.transfer(A, cli, send, pull, { localBk++ }, { n, _ -> prog = n })
    t("passou tudo sem erro", okN == send.size + pull.size && fail == 0, "$okN/$fail")
    t("cópia de segurança antes de gravar (nos dois)", backups == 1 && localBk == 1, "$backups/$localBk")
    // conferência: os dois ficam iguais nos itens passados
    val rows2 = SyncCore.compare(SyncCore.manifest(A), cli.manifest())
    t("depois: tudo IGUAL nos dois", rows2.all { it.state == SyncCore.State.SAME }, rows2.filter { it.state != SyncCore.State.SAME }.map { it.k + it.id + it.state })
    t("foto foi junto e é a mesma", File(B, "projects/images/foto1.jpg").readBytes().contentEquals(File(A, "projects/images/foto1.jpg").readBytes()))
    val idxB = JSONObject(File(B, "projects/index.json").readText())
    t("pasta da nota criada no outro", (0 until idxB.getJSONArray("folders").length()).any { idxB.getJSONArray("folders").getJSONObject(it).getString("name") == "Obras 2026" })
    t("nota aparece na lista do outro (index)", (0 until idxB.getJSONArray("notes").length()).count { idxB.getJSONArray("notes").getJSONObject(it).getString("id") == "n-rua" } == 1)
    t("nota diferente: veio a do outro (escolhida)", JSONObject(File(A, "projects/notes/n-dif.json").readText()).getJSONArray("pages").getJSONObject(0).getJSONArray("objs").getJSONObject(0).getDouble("value") == 1234.0)
    t("versão anterior guardada (.bak)", File(A, "projects/notes/n-dif.json.bak").isFile)
    t("projeto de móveis completo no outro", JSONArray(File(B, "moveis/projects.json").readText()).getJSONObject(0).getJSONObject("estado").getInt("W") == 3200)
    // passar de novo não duplica
    SyncNet.transfer(A, cli, send, pull, {}, { _, _ -> })
    t("passar de novo não duplica", JSONArray(File(B, "projects/quotes.json").readText()).length() == 1 && JSONObject(File(B, "projects/index.json").readText()).getJSONArray("notes").length() == 3)
    // pacote malicioso
    t("pacote com caminho perigoso é recusado", !SyncCore.apply(B, JSONObject().put("k", "note").put("id", "../x").put("obj", JSONObject().put("id", "../x").put("pages", JSONArray()))))
    t("foto com nome perigoso é ignorada", SyncCore.apply(B, JSONObject().put("k", "note").put("id", "n-z").put("obj", note("n-z", "z", null, null)).put("images", JSONObject().put("../../evil", "AAAA"))) && !File(B, "evil").exists() && !File(root, "evil").exists())
    t("eventos no host", events.containsAll(listOf("conectou", "recebeu", "enviou", "fim")), events.distinct())
    host.stop()
        assertTrue(falhas.joinToString("\n"), falhas.isEmpty())
    }
}
