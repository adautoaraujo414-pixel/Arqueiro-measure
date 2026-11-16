import android.content.Context
import br.com.arque.measure.data.DataBackup
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.test.Test

/** Sonda (não é teste do app): restauração com arquivo ruim. Só em pastas temporárias. */
class RestauracaoTest {
    private fun aparelho(): Pair<Context, File> {
        val root = Files.createTempDirectory("arque-aparelho").toFile()
        // dados atuais do "aparelho": 3 projetos e uma nota
        File(root, "files/moveis").mkdirs()
        File(root, "files/moveis/projects.json").writeText("""[{"id":"A"},{"id":"B"},{"id":"C"}]""")
        File(root, "files/notas.json").writeText("""["nota importante"]""")
        File(root, "shared_prefs").mkdirs(); File(root, "shared_prefs/arque.prefs.xml").writeText("<map/>")
        return Context(root) to root
    }
    private fun zip(vararg itens: Pair<String, ByteArray?>): ByteArray {
        val bo = ByteArrayOutputStream()
        ZipOutputStream(bo).use { z ->
            z.putNextEntry(ZipEntry(DataBackup.MARK)); z.write("backup".toByteArray()); z.closeEntry()
            itens.forEach { (n, b) -> z.putNextEntry(ZipEntry(n)); if (b != null) z.write(b); z.closeEntry() }
        }
        return bo.toByteArray()
    }
    private fun estado(root: File): String {
        val p = File(root, "files/moveis/projects.json"); val n = File(root, "files/notas.json")
        return "projects=" + (if (p.exists()) p.readText() else "SUMIU") + " · notas=" + (if (n.exists()) n.readText() else "SUMIU")
    }
    private fun caso(nome: String, bytes: ByteArray) {
        val (ctx, root) = aparelho()
        val antes = estado(root)
        val aceitou = DataBackup.stage(ctx, ByteArrayInputStream(bytes))
        if (aceitou) DataBackup.applyPending(ctx)
        println("CASO $nome · stage aceitou=$aceitou · antes: $antes · depois: ${estado(root)}")
        root.deleteRecursively()
    }
    // grande o bastante pra não caber nos primeiros bytes
    private val grande = ByteArray(200_000) { (it * 31 % 251).toByte() }
    private val bom get() = zip("files/moveis/projects.json" to """[{"id":"VELHO"}]""".toByteArray(), "files/fotos/f1.jpg" to grande, "files/notas.json" to """["nota velha"]""".toByteArray())

    @Test fun backupValido() = caso("valido (controle)", bom)
    @Test fun backupTruncadoNoMeio() { val b = bom; caso("truncado em 60%", b.copyOf(b.size * 6 / 10)) }
    @Test fun backupTruncadoLogoDepoisDoPrimeiroItem() { val b = bom; caso("truncado em 15%", b.copyOf(b.size * 15 / 100)) }
    @Test fun backupComBytesTrocados() { val b = bom.copyOf(); for (i in b.size / 2 until b.size / 2 + 64) b[i] = (b[i].toInt() xor 0x5a).toByte(); caso("bytes trocados no meio", b) }
    @Test fun falhaNoMeioDaExtracao() {
        // "files/fotos" vira arquivo e depois vem "files/fotos/x.jpg": a extração falha no meio (como disco cheio ou erro de escrita)
        caso("falha de escrita no meio", zip("files/moveis/projects.json" to """[{"id":"VELHO"}]""".toByteArray(), "files/fotos" to "x".toByteArray(), "files/fotos/x.jpg" to grande, "files/notas.json" to """["nota velha"]""".toByteArray()))
    }
    @Test fun backupSoComAMarca() = caso("só a marca, sem projetos", zip())
}
