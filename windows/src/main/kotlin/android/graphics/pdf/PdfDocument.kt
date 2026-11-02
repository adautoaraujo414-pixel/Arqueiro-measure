package android.graphics.pdf

import android.graphics.Canvas
import org.apache.pdfbox.pdmodel.PDDocument
import org.apache.pdfbox.pdmodel.PDPage
import org.apache.pdfbox.pdmodel.PDPageContentStream
import org.apache.pdfbox.pdmodel.common.PDRectangle
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.Surface
import java.io.OutputStream

/**
 * PdfDocument do Android no Windows: cada página é desenhada pelo mesmo código do celular
 * (em alta resolução) e vira uma página de PDF do tamanho certo (pontos de 1/72 pol).
 */
class PdfDocument {
    class PageInfo private constructor(val pageWidth: Int, val pageHeight: Int, val pageNumber: Int) {
        class Builder(private val w: Int, private val h: Int, private val n: Int) {
            fun create() = PageInfo(w, h, n)
        }
    }

    inner class Page internal constructor(val info: PageInfo) {
        internal val surface: Surface = Surface.makeRasterN32Premul(info.pageWidth * SCALE, info.pageHeight * SCALE)
        val canvas: Canvas = Canvas(surface.canvas).also { surface.canvas.scale(SCALE.toFloat(), SCALE.toFloat()) }
    }

    private val doc = PDDocument()
    private var closed = false

    fun startPage(info: PageInfo): Page = Page(info)

    fun finishPage(page: Page) {
        val img = page.surface.makeImageSnapshot()
        val png = img.encodeToData(EncodedImageFormat.PNG)?.bytes ?: return
        img.close()
        page.surface.close()
        val w = page.info.pageWidth.toFloat()
        val h = page.info.pageHeight.toFloat()
        val p = PDPage(PDRectangle(w, h))
        doc.addPage(p)
        val x = PDImageXObject.createFromByteArray(doc, png, "pagina${page.info.pageNumber}")
        PDPageContentStream(doc, p).use { cs -> cs.drawImage(x, 0f, 0f, w, h) }
    }

    fun writeTo(out: OutputStream) { doc.save(out) }

    fun close() { if (!closed) { closed = true; doc.close() } }

    companion object {
        /** 3× = 216 dpi: texto e traços nítidos na impressão. */
        const val SCALE = 3
    }
}
