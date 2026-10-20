package br.com.arque.measure

import br.com.arque.measure.data.Json
import br.com.arque.measure.data.Store
import br.com.arque.measure.model.Folder
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.NoteMeta
import br.com.arque.measure.model.Template
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeKind
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

class StoreTest {
    @get:Rule val tmp = TemporaryFolder()

    private fun fullNote(): Note {
        val r = Reading(id = "r1", mm = 2345.0, source = MeasureSource.BLUETOOTH, timeMs = 99L, device = "GLM 50 C", rawHex = "C0 55 02")
        val objs = listOf(
                PhotoObj(id = "p", file = "p.jpg", pxW = 4000, pxH = 3000, cx = 1f, cy = 2f, w = 300f, h = 200f, rot = 15f, locked = true),
                StrokeObj(id = "st", photoId = "p", pts = listOf(Pt(0.1f, 0.2f), Pt(0.3f, 0.4f)), color = 0xFF112233.toInt(), width = 4f, kind = StrokeKind.HIGHLIGHTER),
                ShapeObj(id = "sh", photoId = null, kind = ShapeKind.ELLIPSE, a = Pt(1f, 2f), b = Pt(3f, 4f), color = 5, width = 2f),
                TextObj(id = "t", photoId = "p", at = Pt(0.5f, 0.5f), text = "Tomada\nbaixa", size = 18f, color = 7),
                DimObj(id = "d", photoId = "p", a = Pt(0.1f, 0.5f), b = Pt(0.9f, 0.5f), valueMm = 2345.0, source = MeasureSource.BLUETOOTH, history = listOf(r), color = 9, width = 3f),
                DimObj(id = "d2", photoId = null, a = Pt(1f, 1f), b = Pt(2f, 2f), color = 9, width = 3f),
        )
        return Note(
            id = "s1", name = "Parede norte", folderId = "f1", createdMs = 5L, pinned = true, locked = false, unit = LengthUnit.CM,
            pages = listOf(Sheet(id = "pg1", tpl = Template.LINES, objs = objs), Sheet(id = "pg2", tpl = Template.BLANK)),
        )
    }

    @Test fun `folha completa sobrevive ao ciclo JSON sem perder nada`() {
        val s = fullNote()
        assertEquals(s, Json.noteFromJson(Json.noteToJson(s)))
    }

    @Test fun `indice e leituras sobrevivem ao ciclo JSON`() {
        val idx = Index(
            folders = listOf(Folder("f", "clientes")),
            notes = listOf(NoteMeta("n", "Nota 1", "f", 7L, true, false, false, 3, 12)),
        )
        assertEquals(idx, Json.indexFromJson(Json.indexToJson(idx)))
        val reads = listOf(Reading(id = "x", mm = 10.0, source = MeasureSource.MANUAL, timeMs = 1L))
        assertEquals(reads, Json.readingsFromJson(Json.readingsToJson(reads)))
    }

    @Test fun `salvar e carregar folha do disco`() {
        val store = Store(tmp.newFolder("p"))
        store.saveNote(fullNote())
        assertEquals(fullNote(), store.loadNote("s1"))
    }

    @Test fun `recupera a folha pelo backup quando o arquivo principal corrompe`() {
        val root = tmp.newFolder("p")
        val store = Store(root)
        store.saveNote(fullNote())
        store.saveNote(fullNote().copy(name = "Segunda versão")) // cria o .bak com a primeira
        java.io.File(root, "notes/s1.json").writeText("{ corrompido")
        val rec = store.loadNote("s1")
        assertNotNull(rec)
        assertEquals("Parede norte", rec!!.name)
    }

    @Test fun `folha inexistente retorna null`() {
        assertNull(Store(tmp.newFolder("p")).loadNote("nao-existe"))
    }

    @Test fun `importar foto copia os bytes originais sem alterar`() {
        val store = Store(tmp.newFolder("p"))
        val bytes = ByteArray(5000) { (it * 7).toByte() }
        val name = store.importImage(ByteArrayInputStream(bytes), "jpg")
        assertTrue(name.endsWith(".jpg"))
        assertTrue(bytes.contentEquals(store.imageFile(name).readBytes()))
    }

    @Test fun `backup e restauracao devolvem os mesmos dados`() {
        val src = Store(tmp.newFolder("a"))
        src.saveIndex(Index(folders = listOf(Folder("c", "Maria"))))
        src.saveNote(fullNote())
        val img = src.importImage(ByteArrayInputStream(byteArrayOf(1, 2, 3)), "jpg")
        val zip = ByteArrayOutputStream().also { src.backupTo(it) }.toByteArray()

        val dst = Store(tmp.newFolder("b"))
        assertTrue(dst.restoreFrom(ByteArrayInputStream(zip)))
        assertEquals("Maria", dst.loadIndex().folders.single().name)
        assertEquals(fullNote(), dst.loadNote("s1"))
        assertTrue(byteArrayOf(1, 2, 3).contentEquals(dst.imageFile(img).readBytes()))
    }

    @Test fun `restauracao rejeita zip malicioso e zip sem indice sem apagar nada`() {
        val store = Store(tmp.newFolder("p"))
        store.saveNote(fullNote())

        val evil = ByteArrayOutputStream().also { out ->
            ZipOutputStream(out).use { z ->
                z.putNextEntry(ZipEntry("../fora.txt")); z.write(1); z.closeEntry()
                z.putNextEntry(ZipEntry("index.json")); z.write("{}".toByteArray()); z.closeEntry()
            }
        }.toByteArray()
        assertFalse(store.restoreFrom(ByteArrayInputStream(evil)))

        val noIndex = ByteArrayOutputStream().also { out ->
            ZipOutputStream(out).use { z -> z.putNextEntry(ZipEntry("x.txt")); z.write(1); z.closeEntry() }
        }.toByteArray()
        assertFalse(store.restoreFrom(ByteArrayInputStream(noIndex)))

        assertNotNull(store.loadNote("s1")) // dados originais intactos
        assertFalse(java.io.File(tmp.root, "fora.txt").exists())
    }
}
