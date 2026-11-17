import android.content.Context
import br.com.arque.measure.data.DataBackup
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Restauração de backup (Android/Windows) com arquivo ruim e falhas simuladas. Só em pastas temporárias.
 * P0-02 (auditoria de 16/11): antes, falha no meio = projetos trocados e notas sumidas; backup só com a marca apagava tudo.
 */
class RestauracaoTest {
    private val ATUAL = """[{"id":"A"},{"id":"B"},{"id":"C"}]"""
    private fun aparelho(): Pair<Context, File> {
        val root = Files.createTempDirectory("arque-aparelho").toFile()
        File(root, "files/moveis").mkdirs()
        File(root, "files/moveis/projects.json").writeText(ATUAL)
        File(root, "files/notas.json").writeText("""["nota importante"]""")
        File(root, "shared_prefs").mkdirs(); File(root, "shared_prefs/arque.prefs.xml").writeText("<map/>")
        File(root, "shared_prefs/arque.lic.x.xml").writeText("<licenca/>")
        File(root, "app_webview").mkdirs(); File(root, "app_webview/Local Storage").writeText("ls")
        return Context(root) to root
    }
    private fun zip(vararg itens: Pair<String, ByteArray?>, marca: Boolean = true): ByteArray {
        val bo = ByteArrayOutputStream()
        ZipOutputStream(bo).use { z ->
            if (marca) { z.putNextEntry(ZipEntry(DataBackup.MARK)); z.write("backup".toByteArray()); z.closeEntry() }
            itens.forEach { (n, b) -> z.putNextEntry(ZipEntry(n)); if (b != null) z.write(b); z.closeEntry() }
        }
        return bo.toByteArray()
    }
    private fun estado(root: File): String {
        val p = File(root, "files/moveis/projects.json"); val n = File(root, "files/notas.json"); val l = File(root, "shared_prefs/arque.lic.x.xml")
        return "projects=" + (if (p.exists()) p.readText() else "SUMIU") + " · notas=" + (if (n.exists()) n.readText() else "SUMIU") + " · licença=" + l.exists()
    }
    private fun anteriores(root: File) = root.listFiles { f -> f.name.startsWith("restore_previous_") }?.size ?: 0
    private fun restaura(bytes: ByteArray): Triple<Boolean, String, File> {
        val (ctx, root) = aparelho()
        val aceitou = DataBackup.stage(ctx, ByteArrayInputStream(bytes))
        if (aceitou) DataBackup.applyPending(ctx)
        val msg = (DataBackup.lastReject ?: DataBackup.takeResult(ctx) ?: "-")
        println("CASO aceitou=$aceitou · ${estado(root)} · anteriores=${anteriores(root)} · aviso: $msg")
        return Triple(aceitou, estado(root), root)
    }
    private val INTACTO = "projects=$ATUAL · notas=[\"nota importante\"] · licença=true"
    private val grande = ByteArray(200_000) { (it * 31 % 251).toByte() }
    private val bom get() = zip("files/moveis/projects.json" to """[{"id":"VELHO"}]""".toByteArray(), "files/fotos/f1.jpg" to grande, "files/notas.json" to """["nota velha"]""".toByteArray())

    @Test fun backupValidoRestauraEGuardaOAnterior() {
        val (ok, st, root) = restaura(bom)
        assertTrue(ok); assertEquals("projects=[{\"id\":\"VELHO\"}] · notas=[\"nota velha\"] · licença=true", st)
        assertEquals(1, anteriores(root), "o estado de antes fica guardado")
        val prev = root.listFiles { f -> f.name.startsWith("restore_previous_") }!!.first()
        assertEquals(ATUAL, File(prev, "files/moveis/projects.json").readText(), "a cópia do anterior tem os projetos de antes")
        root.deleteRecursively()
    }
    @Test fun truncadoNoMeio() { val b = bom; val (ok, st, r) = restaura(b.copyOf(b.size * 6 / 10)); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun truncadoNoComeco() { val b = bom; val (ok, st, r) = restaura(b.copyOf(b.size * 15 / 100)); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun truncadoNoFimDeUmItem() {
        // corta logo depois de um item inteiro (sem o índice do ZIP): a leitura em sequência não acusa nada sozinha
        val b = bom; val corte = b.size - 200
        val (ok, st, r) = restaura(b.copyOf(corte)); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively()
    }
    @Test fun bytesTrocados() { val b = bom.copyOf(); for (i in b.size / 2 until b.size / 2 + 64) b[i] = (b[i].toInt() xor 0x5a).toByte(); val (ok, st, r) = restaura(b); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun soAMarca() { val (ok, st, r) = restaura(zip()); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun listaDeProjetosVaziaESemNotas() { val (ok, st, r) = restaura(zip("files/moveis/projects.json" to "[]".toByteArray())); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun listaDeProjetosIlegivel() { val (ok, st, r) = restaura(zip("files/moveis/projects.json" to "[{\"id\":".toByteArray(), "files/notas.json" to "[]".toByteArray())); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun caminhoQueSaiDaPasta() { val (ok, st, r) = restaura(zip("files/../../fora.txt" to "x".toByteArray(), "files/notas.json" to "[]".toByteArray())); assertEquals(false, ok); assertEquals(INTACTO, st); r.deleteRecursively() }
    @Test fun falhaDeEscritaNoMeioDaExtracao() {
        val (ok, st, r) = restaura(zip("files/moveis/projects.json" to """[{"id":"VELHO"}]""".toByteArray(), "files/fotos" to "x".toByteArray(), "files/fotos/x.jpg" to grande, "files/notas.json" to """["nota velha"]""".toByteArray()))
        // passa na conferência (o ZIP é íntegro), mas a extração falha: nada muda
        assertEquals(INTACTO, st); assertEquals(0, anteriores(r)); r.deleteRecursively()
    }
    @Test fun falhaNaTrocaVoltaTudo() {
        val (_, root) = aparelho()
        val staging = File(root, "restore_staging"); File(staging, "files/moveis").mkdirs(); File(staging, "files/moveis/projects.json").writeText("[{\"id\":\"NOVO\"}]")
        File(staging, "shared_prefs").mkdirs(); File(staging, "app_webview").mkdirs()
        var n = 0
        val r = runCatching { DataBackup.swapIn(root, staging) { a, b -> n++; if (n == 5) false else a.renameTo(b) } }
        println("CASO troca que falha no 5º passo · erro=${r.isFailure} · ${estado(root)} · anteriores=${anteriores(root)}")
        assertTrue(r.isFailure); assertEquals(INTACTO, estado(root)); assertEquals(0, anteriores(root))
        root.deleteRecursively()
    }
    @Test fun appFechadoNoMeioDaTrocaVoltaOAnterior() {
        val (ctx, root) = aparelho()
        // simula: o atual foi guardado em restore_previous_1 e o app morreu antes de pôr o novo
        val prev = File(root, "restore_previous_1"); prev.mkdirs()
        listOf("files", "shared_prefs", "app_webview").forEach { File(root, it).renameTo(File(prev, it)) }
        File(root, "restore_swap.txt").writeText(prev.name)
        DataBackup.applyPending(ctx)
        println("CASO app fechado no meio da troca · ${estado(root)}")
        assertEquals(INTACTO, estado(root)); assertTrue(!File(root, "restore_swap.txt").exists())
        root.deleteRecursively()
    }
    @Test fun backupNaoLevaAsCopiasDeRestauracao() {
        val (ctx, root) = aparelho()
        File(root, "restore_previous_9/files").mkdirs(); File(root, "restore_previous_9/files/x.json").writeText("antigo")
        val bo = ByteArrayOutputStream(); DataBackup.fullBackup(ctx, bo)
        val nomes = mutableListOf<String>(); java.util.zip.ZipInputStream(ByteArrayInputStream(bo.toByteArray())).use { z -> var e = z.nextEntry; while (e != null) { nomes += e.name; e = z.nextEntry } }
        assertTrue(nomes.none { it.startsWith("restore_") }, "cópias de restauração não entram no backup: $nomes")
        root.deleteRecursively()
    }

    // BKP-PONTOS (17/11): nome de arquivo com pontos é válido; só um pedaço do caminho igual a ".." é travessia.
    // Antes: n.contains("..") recusava o backup inteiro por causa de "foto..jpg".
    @Test fun nomesComPontosRestauram() {
        val (ok, st, root) = restaura(zip("files/moveis/projects.json" to """[{"id":"VELHO"}]""".toByteArray(), "files/fotos/foto..jpg" to grande,
            "files/notas...txt" to "n".toByteArray(), "files/a..b/c.json" to "{}".toByteArray(), "files/..oculto" to "o".toByteArray(), "files/notas.json" to """["nota velha"]""".toByteArray()))
        assertTrue(ok); assertEquals("projects=[{\"id\":\"VELHO\"}] · notas=[\"nota velha\"] · licença=true", st)
        assertTrue(grande.contentEquals(File(root, "files/fotos/foto..jpg").readBytes()))
        assertEquals("n", File(root, "files/notas...txt").readText()); assertEquals("{}", File(root, "files/a..b/c.json").readText()); assertEquals("o", File(root, "files/..oculto").readText())
        root.deleteRecursively()
    }
    @Test fun projetoAntigoComFotoDePontosRestauraIgual() {
        val antigo = """[{"id":"p1","client":{"nome":"Maria"},"created":1,"updated":2,"current":{"W":3600,"H":2700,"mods":[{"n":"Balcão 2 portas","w":900,"div":[0.5],"v":[{"k":"door","n":1},{"k":"drawers","n":2},{"k":"free","n":1}]}]}}]"""
        val (ok, st, root) = restaura(zip("files/moveis/projects.json" to antigo.toByteArray(), "files/moveis/fotos/cozinha..maria.jpg" to grande))
        assertTrue(ok); assertEquals("projects=$antigo · notas=SUMIU · licença=true", st)
        assertTrue(grande.contentEquals(File(root, "files/moveis/fotos/cozinha..maria.jpg").readBytes()))
        root.deleteRecursively()
    }
    @Test fun travessiasContinuamRecusadas() {
        for (n in listOf("../fora.txt", "files/../../fora.txt", "files\\..\\fora.txt", "..", "files/..", "files/../notas.json", "/abs.txt", "\\abs.txt", "C:/fora.txt")) {
            val (ok, st, r) = restaura(zip(n to "x".toByteArray(), "files/notas.json" to """["nota velha"]""".toByteArray()))
            assertEquals(false, ok, "aceitou $n"); assertEquals(INTACTO, st, "mudou com $n"); assertTrue(!File(r.parentFile, "fora.txt").exists(), "escreveu fora com $n"); r.deleteRecursively()
        }
    }
}
