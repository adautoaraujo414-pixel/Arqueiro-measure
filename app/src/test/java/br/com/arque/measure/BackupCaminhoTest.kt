package br.com.arque.measure

import br.com.arque.measure.data.DataBackup
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

/**
 * BKP-PONTOS (pedido do Adauto, 17/11): a conferência do backup completo recusa só caminho que atravessa pastas
 * (um pedaço igual a ".."), começa na raiz ou tem unidade (":"). Nome de arquivo com pontos ("foto..jpg") é válido.
 * Antes: n.contains("..") recusava o backup inteiro por causa de um arquivo "foto..jpg".
 */
class BackupCaminhoTest {
    @get:Rule val tmp = TemporaryFolder()

    private fun backup(nome: String): File {
        val f = tmp.newFile()
        ZipOutputStream(f.outputStream()).use { z ->
            z.putNextEntry(ZipEntry(DataBackup.MARK)); z.write("backup".toByteArray()); z.closeEntry()
            z.putNextEntry(ZipEntry("files/moveis/projects.json")); z.write("""[{"id":"p1"}]""".toByteArray()); z.closeEntry()
            z.putNextEntry(ZipEntry(nome)); z.write("x".toByteArray()); z.closeEntry()
        }
        return f
    }

    @Test fun nomesComPontosSaoAceitos() {
        for (n in listOf("files/fotos/foto..jpg", "files/notas...txt", "files/a..b/c.json", "files/..oculto", "files/moveis/fotos/cozinha..maria.jpg", "moveis-teste/.._fora.txt"))
            assertTrue("recusou $n", DataBackup.check(backup(n)).ok)
    }

    @Test fun travessiaRaizEUnidadeContinuamRecusadas() {
        for (n in listOf("../fora.txt", "files/../../fora.txt", "files\\..\\fora.txt", "..", "files/..", "files/../notas.json", "/abs.txt", "\\abs.txt", "C:/fora.txt"))
            assertFalse("aceitou $n", DataBackup.check(backup(n)).ok)
    }
}
