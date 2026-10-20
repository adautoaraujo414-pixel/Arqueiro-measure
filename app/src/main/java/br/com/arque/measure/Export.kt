package br.com.arque.measure

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfDocument
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.ui.SheetRenderer
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/** Exportação da folha. Usa o mesmo renderizador da tela. */
object Export {
    /** 1 unidade de folha = 1/96 pol; 1 ponto de PDF = 1/72 pol. */
    private const val PT_PER_UNIT = 0.75f

    fun pdf(sheet: Sheet, renderer: SheetRenderer, out: OutputStream) {
        val doc = PdfDocument()
        try {
            val w = (sheet.width * PT_PER_UNIT).roundToInt()
            val h = (sheet.height * PT_PER_UNIT).roundToInt()
            val page = doc.startPage(PdfDocument.PageInfo.Builder(w, h, 1).create())
            val c = page.canvas
            c.drawColor(Color.WHITE)
            c.scale(PT_PER_UNIT, PT_PER_UNIT)
            renderer.draw(c, sheet, null, 1f, withPaper = false)
            doc.finishPage(page)
            doc.writeTo(out)
        } finally {
            doc.close()
        }
    }

    fun png(sheet: Sheet, renderer: SheetRenderer, out: OutputStream, scale: Float = 2f) {
        val bmp = Bitmap.createBitmap(
            (sheet.width * scale).roundToInt(), (sheet.height * scale).roundToInt(), Bitmap.Config.ARGB_8888,
        )
        try {
            val c = android.graphics.Canvas(bmp)
            c.drawColor(Color.WHITE)
            c.scale(scale, scale)
            renderer.draw(c, sheet, null, 1f, withPaper = false)
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        } finally {
            bmp.recycle()
        }
    }

    private fun csv(s: String) = "\"" + s.replace("\"", "\"\"") + "\""

    fun csv(client: String, room: String, sheet: Sheet): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        val sb = StringBuilder()
        sb.append("cliente;ambiente;folha;cota;valor_mm;valor_exibido;origem;ultima_leitura\n")
        sheet.objs.filterIsInstance<DimObj>().forEachIndexed { i, d ->
            val last = d.history.lastOrNull()
            sb.append(
                listOf(
                    csv(client), csv(room), csv(sheet.name), (i + 1).toString(),
                    d.valueMm?.let { "%.1f".format(Locale.US, it) } ?: "",
                    csv(Units.label(d, sheet.unit)),
                    when (d.source) {
                        br.com.arque.measure.model.MeasureSource.BLUETOOTH -> "bluetooth"
                        br.com.arque.measure.model.MeasureSource.MANUAL -> "manual"
                        null -> ""
                    },
                    last?.let { fmt.format(Date(it.timeMs)) } ?: "",
                ).joinToString(";"),
            ).append('\n')
        }
        return sb.toString()
    }
}
