package br.com.arque.measure

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfDocument
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.ui.SheetRenderer
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/** Exportação da nota. Usa o mesmo renderizador da tela. */
object Export {
    /** 1 unidade de folha = 1/96 pol; 1 ponto de PDF = 1/72 pol. */
    private const val PT_PER_UNIT = 0.75f

    /** PDF com uma página por folha. */
    fun pdf(note: Note, renderer: SheetRenderer, out: OutputStream) {
        val doc = PdfDocument()
        try {
            note.pages.forEachIndexed { i, sheet ->
                val w = (Sheet.W * PT_PER_UNIT).roundToInt()
                val h = (Sheet.H * PT_PER_UNIT).roundToInt()
                val page = doc.startPage(PdfDocument.PageInfo.Builder(w, h, i + 1).create())
                val c = page.canvas
                c.drawColor(Color.WHITE)
                c.scale(PT_PER_UNIT, PT_PER_UNIT)
                renderer.draw(c, sheet, note.unit, null, 1f, withPaper = false)
                doc.finishPage(page)
            }
            doc.writeTo(out)
        } finally {
            doc.close()
        }
    }

    /** PNG de uma folha. */
    fun png(note: Note, pageIdx: Int, renderer: SheetRenderer, out: OutputStream, scale: Float = 2f) {
        val sheet = note.pages[pageIdx.coerceIn(0, note.pages.lastIndex)]
        val bmp = Bitmap.createBitmap(
            (Sheet.W * scale).roundToInt(), (Sheet.H * scale).roundToInt(), Bitmap.Config.ARGB_8888,
        )
        try {
            val c = android.graphics.Canvas(bmp)
            c.drawColor(Color.WHITE)
            c.scale(scale, scale)
            renderer.draw(c, sheet, note.unit, null, 1f, withPaper = false)
            bmp.compress(Bitmap.CompressFormat.PNG, 100, out)
        } finally {
            bmp.recycle()
        }
    }

    private fun csv(s: String) = "\"" + s.replace("\"", "\"\"") + "\""

    fun csv(note: Note): String {
        val fmt = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        val sb = StringBuilder()
        sb.append("nota;folha;cota;valor_mm;valor_exibido;origem;ultima_leitura\n")
        note.pages.forEachIndexed { pi, sheet ->
            sheet.objs.filterIsInstance<DimObj>().forEachIndexed { i, d ->
                val last = d.history.lastOrNull()
                sb.append(
                    listOf(
                        csv(note.name), (pi + 1).toString(), (i + 1).toString(),
                        d.valueMm?.let { "%.1f".format(Locale.US, it) } ?: "",
                        csv(Units.label(d, note.unit)),
                        when (d.source) {
                            MeasureSource.BLUETOOTH -> "bluetooth"
                            MeasureSource.MANUAL -> "manual"
                            null -> ""
                        },
                        last?.let { fmt.format(Date(it.timeMs)) } ?: "",
                    ).joinToString(";"),
                ).append('\n')
            }
            sheet.objs.filterIsInstance<br.com.arque.measure.model.CabObj>().forEach { cb ->
                br.com.arque.measure.logic.CabinetMath.cutList(cb.cab).forEach { ln ->
                    sb.append(
                        listOf(
                            csv(note.name), (pi + 1).toString(), csv("${cb.name} · ${ln.kind.label}"),
                            "", csv("${ln.qty} × ${Units.formatNumber(ln.cutL, br.com.arque.measure.model.LengthUnit.MM)} × ${Units.formatNumber(ln.cutW, br.com.arque.measure.model.LengthUnit.MM)} × ${Units.formatNumber(ln.esp, br.com.arque.measure.model.LengthUnit.MM)} mm"),
                            "peca", "",
                        ).joinToString(";"),
                    ).append('\n')
                }
            }
            sheet.objs.filterIsInstance<br.com.arque.measure.model.DoorObj>().forEachIndexed { i, d ->
                sb.append(
                    listOf(
                        csv(note.name), (pi + 1).toString(), "porta-${i + 1}",
                        d.valueMm?.let { "%.1f".format(Locale.US, it) } ?: "",
                        csv(br.com.arque.measure.logic.Geo.doorLabel(d, note.unit) + (if (d.slide) " (de correr)" else "")),
                        when (d.source) { MeasureSource.BLUETOOTH -> "bluetooth"; MeasureSource.MANUAL -> "manual"; null -> "" },
                        d.history.lastOrNull()?.let { h -> fmt.format(Date(h.timeMs)) } ?: "",
                    ).joinToString(";"),
                ).append('\n')
            }
            sheet.objs.filterIsInstance<br.com.arque.measure.model.RoomObj>().forEach { o ->
                o.segs.forEachIndexed { k, sg ->
                    sb.append(
                        listOf(
                            csv(note.name), (pi + 1).toString(), "comodo-${k + 1}",
                            sg.valueMm?.let { "%.1f".format(Locale.US, it) } ?: "",
                            csv(sg.kind.label + " " + Units.labelSeg(sg, note.unit)),
                            when (sg.source) {
                                MeasureSource.BLUETOOTH -> "bluetooth"
                                MeasureSource.MANUAL -> "manual"
                                null -> ""
                            },
                            sg.history.lastOrNull()?.let { h -> fmt.format(Date(h.timeMs)) } ?: "",
                        ).joinToString(";"),
                    ).append('\n')
                }
            }
        }
        return sb.toString()
    }
}
