package br.com.arque.measure

import br.com.arque.measure.data.EditorVideo
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/** N13 (auditoria de 17/11): vídeo do editor gravado em arquivo com a mesma regra do iOS; o script é o mesmo nas plataformas. */
class EditorVideoTest {
    @get:Rule val tmp = TemporaryFolder()
    private fun rec(id: String, kind: String = "video", data: String = "data:video/mp4;base64,AQID") =
        "{\"id\":\"$id\",\"pid\":\"p1\",\"kind\":\"$kind\",\"nome\":\"obra.mp4\",\"videoData\":\"$data\",\"marks\":[],\"created\":1}"

    @Test fun videoValidoVaiProArquivo() {
        val d = tmp.newFolder()
        assertTrue(EditorVideo.save(rec("v123"), d))
        assertTrue(File(d, "video_v123.json").readText().contains("videoData"))
    }

    @Test fun registroInvalidoNaoGravaNada() {
        val d = tmp.newFolder()
        assertFalse("id que sobe pasta", EditorVideo.save(rec("../x"), d))
        assertFalse("id com barra", EditorVideo.save(rec("a/b"), d))
        assertFalse("não é vídeo", EditorVideo.save(rec("v1", kind = "obra"), d))
        assertFalse("sem base64", EditorVideo.save(rec("v2", data = "data:video/mp4,AQID"), d))
        assertFalse("base64 quebrado", EditorVideo.save(rec("v3", data = "data:video/mp4;base64,???"), d))
        assertFalse("texto que não é JSON", EditorVideo.save("nada", d))
        assertTrue("nada gravado", (d.list() ?: emptyArray()).isEmpty())
    }

    @Test fun scriptDosVideosIgualAoDoIPhone() {
        val app = File("src/main/assets/EditorMediaBackup.js"); val ios = File("../ios/Arquemestre/Resources/EditorMediaBackup.js")
        assertTrue("script do editor existe", app.isFile)
        assertTrue("script do iPhone existe", ios.isFile)
        assertArrayEquals("as duas cópias do script são iguais", ios.readBytes(), app.readBytes())
    }
}
