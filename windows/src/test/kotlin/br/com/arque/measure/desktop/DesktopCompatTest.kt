package br.com.arque.measure.desktop

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.pdf.PdfDocument
import android.net.Uri
import br.com.arque.measure.Export
import br.com.arque.measure.QuotePdf
import br.com.arque.measure.data.DataBackup
import br.com.arque.measure.model.Company
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.QuoteItem
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.TextObj
import br.com.arque.measure.ui.MoveisBridge
import br.com.arque.measure.ui.SheetRenderer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.io.File
import javax.imageio.ImageIO

/** O que é só do Windows: camada de compatibilidade, arquivos, PDF/PNG, backup e a ponte do editor de móveis. */
class DesktopCompatTest {
    private val ctx = DesktopApp.context

    @Test fun preferenciasGravamEVoltam() {
        val p = ctx.getSharedPreferences("teste_prefs", 0)
        p.edit().putString("a", "olá").putInt("n", 7).putBoolean("b", true).putFloat("f", 0.8f).putLong("l", 123456789012L).apply()
        android.content.Prefs.reset()
        val q = ctx.getSharedPreferences("teste_prefs", 0)
        assertEquals("olá", q.getString("a", null)); assertEquals(7, q.getInt("n", 0)); assertTrue(q.getBoolean("b", false))
        assertEquals(0.8f, q.getFloat("f", 0f), 0.0001f); assertEquals(123456789012L, q.getLong("l", 0))
    }

    @Test fun preferenciasDoCelularNoBackupSaoLidas() {
        val dir = File(Paths.data, "shared_prefs").apply { mkdirs() }
        File(dir, "arque.lic.xml").writeText("""<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map><boolean name="ok" value="true" /><long name="start" value="1700000000000" /><string name="x">abc</string></map>""")
        android.content.Prefs.reset()
        val p = ctx.getSharedPreferences("arque.lic", 0)
        assertTrue(p.getBoolean("ok", false)); assertEquals(1700000000000L, p.getLong("start", 0)); assertEquals("abc", p.getString("x", null))
    }

    @Test fun uriDeArquivoELink() {
        val f = File(Paths.data, "a b.txt").apply { writeText("x") }
        val u = Uri.fromFile(f)
        assertEquals("file", u.scheme); assertEquals(f.canonicalFile, u.file()!!.canonicalFile)
        val w = Uri.parse("arquemestre://corte?d=AbC123-xyz")
        assertEquals("corte", w.host); assertEquals("AbC123-xyz", w.getQueryParameter("d"))
        assertEquals("a%20b%C3%A7", Uri.encode("a bç"))
    }

    @Test fun desenhoComTextoEFormas() {
        val bmp = Bitmap.createBitmap(200, 100, Bitmap.Config.ARGB_8888)
        val c = Canvas(bmp)
        c.drawColor(Color.WHITE)
        val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.BLACK; textSize = 30f; textAlign = Paint.Align.CENTER }
        assertTrue(p.measureText("Arquemestre 2450 mm") > 100f)
        assertTrue(p.measureText("✓ 📐") > 10f)
        c.drawText("Teste ç ã", 100f, 60f, p)
        p.style = Paint.Style.STROKE; p.strokeWidth = 4f
        c.drawLine(10f, 90f, 190f, 90f, p)
        val out = ByteArrayOutputStream()
        assertTrue(bmp.compress(Bitmap.CompressFormat.PNG, 100, out))
        val img = ImageIO.read(out.toByteArray().inputStream())
        assertEquals(200, img.width)
        var dark = 0
        for (x in 0 until 200) for (y in 0 until 100) if ((img.getRGB(x, y) and 0xFF) < 100) dark++
        assertTrue("texto e linha desenhados ($dark)", dark > 300)
        val back = BitmapFactory.decodeByteArray(out.toByteArray(), 0, out.size())!!
        assertEquals(100, back.height)
    }

    @Test fun matrizGiraAFoto() {
        val b = Bitmap.createBitmap(40, 10, Bitmap.Config.ARGB_8888)
        val m = Matrix().apply { postRotate(90f) }
        val r = Bitmap.createBitmap(b, 0, 0, 40, 10, m, true)
        assertEquals(10, r.width); assertEquals(40, r.height)
    }

    @Test fun pdfDaNotaEDoOrcamento() {
        val n = Note(name = "Teste", pages = listOf(Sheet(objs = listOf(
            DimObj(photoId = null, a = Pt(100f, 200f), b = Pt(500f, 200f), valueMm = 1234.0, color = 0xFFE53935.toInt(), width = 4f),
            TextObj(photoId = null, at = Pt(100f, 120f), text = "Cozinha", size = 30f, color = Color.BLACK),
        ))))
        val r = SheetRenderer { null }
        val pdf = ByteArrayOutputStream(); Export.pdf(n, r, pdf)
        org.apache.pdfbox.Loader.loadPDF(pdf.toByteArray()).use { assertEquals(1, it.numberOfPages) }
        val png = ByteArrayOutputStream(); Export.png(n, 0, r, png)
        assertTrue(ImageIO.read(png.toByteArray().inputStream()).width > 500)
        assertTrue(Export.csv(n).contains("1234.0"))
        val q = ByteArrayOutputStream()
        QuotePdf.write(Company(name = "Marcenaria Teste"), Quote(clientName = "Fulano", items = listOf(QuoteItem(desc = "Armário", qty = 2.0, unitValue = 1500.0))), null, null, q)
        org.apache.pdfbox.Loader.loadPDF(q.toByteArray()).use { assertTrue(it.numberOfPages >= 1) }
    }

    @Test fun pdfDocumentDoAndroid() {
        val d = PdfDocument()
        val pg = d.startPage(PdfDocument.PageInfo.Builder(595, 842, 1).create())
        pg.canvas.drawColor(Color.WHITE); pg.canvas.drawText("Olá", 50f, 50f, Paint().apply { textSize = 20f })
        d.finishPage(pg)
        val o = ByteArrayOutputStream(); d.writeTo(o); d.close()
        org.apache.pdfbox.Loader.loadPDF(o.toByteArray()).use { doc ->
            assertEquals(1, doc.numberOfPages); assertEquals(595f, doc.getPage(0).mediaBox.width, 0.5f)
        }
    }

    @Test fun backupCompletoERestauracao() {
        val f = File(ctx.filesDir, "projects/nota-teste.json").apply { parentFile.mkdirs(); writeText("{\"id\":\"1\"}") }
        val zip = File(Paths.data, "../backup-teste.zip")
        zip.outputStream().use { DataBackup.fullBackup(ctx, it) }
        assertTrue(DataBackup.isFull(zip))
        f.delete(); assertFalse(f.exists())
        assertTrue(DataBackup.stage(ctx, zip.inputStream()))
        DataBackup.applyPending(ctx)
        assertTrue("restaurou o arquivo", File(ctx.filesDir, "projects/nota-teste.json").exists())
        assertTrue(DataBackup.autoBackup(ctx, force = true))
        assertTrue(File(DataBackup.autoDir(), "Arquemestre-backup-automatico.zip").length() > 100)
    }

    @Test fun ponteDoEditorDeMoveis() {
        val dir = File(Paths.data, "moveis-teste").apply { mkdirs() }
        var closed = false
        val b = MoveisBridge(dir, onClose = { closed = true }, notes = { "[{\"id\":\"n1\"}]" }, company = { "Marcenaria" })
        assertEquals("Marcenaria", b.call("companyName", emptyList()))
        assertEquals("[{\"id\":\"n1\"}]", b.call("listNotes", emptyList()))
        b.call("putFile", listOf("projects.json", java.util.Base64.getEncoder().encodeToString("[1,2]".toByteArray())))
        assertEquals("[1,2]", String(java.util.Base64.getDecoder().decode(b.call("getFile", listOf("projects.json")))))
        assertTrue(b.call("listFiles", emptyList()).contains("projects.json"))
        b.call("delFile", listOf("projects.json"))
        assertEquals("", b.call("getFile", listOf("projects.json")))
        assertEquals("false", b.call("isSharing", emptyList()))
        // nome perigoso não sai da pasta
        b.call("putFile", listOf("../fora.txt", java.util.Base64.getEncoder().encodeToString("x".toByteArray())))
        assertFalse(File(dir.parentFile, "fora.txt").exists())
    }

    @Test fun numeroDaVersaoNoApp() {
        assertTrue(br.com.arque.measure.data.AppUpdater.installedNumber(ctx) >= 0L)
    }
}
