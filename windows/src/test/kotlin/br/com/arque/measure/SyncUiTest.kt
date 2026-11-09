package br.com.arque.measure

import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import br.com.arque.measure.desktop.DesktopApp
import br.com.arque.measure.sync.SyncCore
import br.com.arque.measure.sync.SyncNet
import br.com.arque.measure.ui.SyncDialog
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import java.io.File

/**
 * Tela "Sincronizar com outro aparelho" de verdade: toca nos botões, digita o código no teclado do app,
 * vê a lista e passa. O "outro aparelho" é um servidor real na rede deste computador (outra pasta de dados).
 */
class SyncUiTest {
    @get:Rule val rule = createComposeRule()

    private fun seed(dir: File, notes: List<JSONObject>, quotes: JSONArray) {
        val pj = File(dir, "projects"); File(pj, "notes").mkdirs(); File(pj, "images").mkdirs(); File(dir, "moveis").mkdirs()
        File(pj, "index.json").writeText(JSONObject().put("v", 3).put("folders", JSONArray())
            .put("notes", JSONArray(notes.map { JSONObject().put("id", it.getString("id")).put("name", it.getString("name")).put("folderId", JSONObject.NULL).put("createdMs", 1).put("pinned", false).put("locked", false).put("trash", false).put("pageCount", 1).put("dimCount", 0) })).toString())
        notes.forEach { File(pj, "notes/${it.getString("id")}.json").writeText(it.toString()) }
        File(pj, "quotes.json").writeText(quotes.toString())
    }
    private fun note(id: String, name: String) = JSONObject().put("v", 3).put("id", id).put("name", name).put("folderId", JSONObject.NULL).put("createdMs", 1700000000000L)
        .put("pinned", false).put("locked", false).put("trash", false).put("unit", "M")
        .put("pages", JSONArray().put(JSONObject().put("id", "p1").put("tpl", "ARAUJO").put("objs", JSONArray().put(JSONObject().put("id", "d1").put("type", "dim").put("x1", 0).put("y1", 0).put("x2", 100).put("y2", 0).put("value", 2450)))))

    private fun type(s: String) { for (c in s) rule.onAllNodesWithText(c.toString())[0].performClick() }

    @Test
    fun conectaPelaTelaVeOQueFaltaEPassaNosDoisSentidos() {
        val ctx = DesktopApp.context
        val mine = ctx.filesDir
        File(mine, "projects").deleteRecursively()
        seed(mine, listOf(note("n-pc", "Medição do PC"), note("n-igual", "Igual nos dois")), JSONArray())
        val vm = AppViewModel(ctx)
        val other = File(System.getProperty("java.io.tmpdir"), "arq-outro-" + System.nanoTime()).apply { mkdirs() }
        seed(other, listOf(note("n-igual", "Igual nos dois"), note("n-rua", "Medição da rua")), JSONArray().put(JSONObject().put("id", "q9").put("client", "Cliente da rua").put("date", 1700000000000L).put("items", JSONArray())))
        val host = SyncNet.Host(other, "iPhone de teste", {}, {})
        assertTrue(host.start())
        try {
            var closed = false
            rule.setContent { SyncDialog(vm, "PC") { closed = true } }
            rule.onNodeWithText("📤 Conectar no outro (digitar o código)").performClick()
            type("127.0.0.1-" + host.pin + (if (host.port != SyncNet.PORT) "-" + (host.port - SyncNet.PORT) else ""))
            rule.onNodeWithText("Conectar").performClick()
            rule.waitUntil(15_000) { rule.onAllNodes(hasText("Com iPhone de teste")).fetchSemanticsNodes().isNotEmpty() }
            rule.onNodeWithText("✅ Iguais nos dois: 1 (não passa nada)").assertExists()
            rule.onNodeWithText("Nota · Medição do PC").assertExists()
            rule.onNodeWithText("Nota · Medição da rua").assertExists()
            rule.onNodeWithText("Orçamento · Cliente da rua").assertExists()
            rule.onNodeWithText("Passar (3)").performClick()
            rule.waitUntil(15_000) { rule.onAllNodes(hasText("Pronto", substring = true)).fetchSemanticsNodes().isNotEmpty() }
            rule.onNodeWithText("Pronto: 3 item(ns) passado(s). Enviados 1, recebidos 2.").assertExists()
            // os dois aparelhos ficaram com tudo igual
            val rows = SyncCore.compare(SyncCore.manifest(mine), SyncCore.manifest(other))
            assertTrue(rows.joinToString { it.id + it.state }, rows.all { it.state == SyncCore.State.SAME })
            assertEquals(4, rows.size)
            // a biblioteca deste aparelho já mostra o que veio (sem reabrir o app)
            rule.waitForIdle()
            assertTrue(vm.index.notes.any { it.id == "n-rua" })
            assertTrue(vm.quotes.any { it.id == "q9" })
            rule.onNodeWithText("Fechar").performClick()
            assertTrue(closed)
        } finally { host.stop() }
    }

    @Test
    fun recebeMostraOCodigoEOOutroMandaPelaRede() {
        val ctx = DesktopApp.context
        val mine = ctx.filesDir
        File(mine, "projects").deleteRecursively()
        seed(mine, listOf(note("n-pc", "Medição do PC")), JSONArray())
        val vm = AppViewModel(ctx)
        val other = File(System.getProperty("java.io.tmpdir"), "arq-celular-" + System.nanoTime()).apply { mkdirs() }
        seed(other, listOf(note("n-cel", "Medição no celular")), JSONArray())
        System.setProperty("arque.syncIps", "127.0.0.1") // container de teste sem Wi-Fi: usa o próprio computador
        rule.setContent { SyncDialog(vm, "PC do escritório") {} }
        rule.onNodeWithText("📥 Receber neste aparelho (mostra o código)").performClick()
        rule.waitUntil(10_000) { rule.onAllNodes(hasText("Endereço:", substring = true)).fetchSemanticsNodes().isNotEmpty() }
        val addr = rule.onAllNodes(hasText("Endereço:", substring = true)).fetchSemanticsNodes()[0].config.let { c ->
            c[androidx.compose.ui.semantics.SemanticsProperties.Text].joinToString { it.text } }
        val port = addr.substringAfterLast(':').trim().toInt()
        // a senha é o número de 4 dígitos do código grande ("final-senha")
        val codeTxt = rule.onAllNodes(hasText("-", substring = true)).fetchSemanticsNodes().map { n -> n.config[androidx.compose.ui.semantics.SemanticsProperties.Text].joinToString { it.text } }
            .first { Regex("^\\d{1,3}-\\d{4}(-\\d)?$").matches(it) }
        val pin = codeTxt.split('-')[1]
        val c = SyncNet.Client("http://127.0.0.1:$port", pin)
        assertEquals("PC do escritório", c.hello().optString("name"))
        val rows = SyncCore.compare(SyncCore.manifest(other), c.manifest())
        val (ok, fail) = SyncNet.transfer(other, c, rows.filter { it.state == SyncCore.State.ONLY_HERE }, rows.filter { it.state == SyncCore.State.ONLY_THERE }, {}, { _, _ -> })
        assertEquals(2 to 0, ok to fail)
        rule.waitUntil(10_000) { rule.onAllNodes(hasText("Pronto: recebeu 1, enviou 1.")).fetchSemanticsNodes().isNotEmpty() }
        rule.waitForIdle()
        assertTrue(vm.index.notes.any { it.id == "n-cel" })
        assertTrue(File(other, "projects/notes/n-pc.json").isFile)
        rule.onNodeWithText("Fechar").performClick()
        System.clearProperty("arque.syncIps")
    }
}
