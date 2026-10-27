package br.com.arque.measure

import br.com.arque.measure.i18n.tr

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import br.com.arque.measure.logic.QuoteMath
import br.com.arque.measure.model.Company
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.ui.SheetRenderer
import java.io.OutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlin.math.roundToInt

/** Orçamento em PDF (texto digitado, A4). Se [note] vier, as folhas do desenho entram depois do orçamento. */
object QuotePdf {
    private const val W = 595
    private const val H = 842
    private const val M = 40f
    private val GOLD = 0xFFB8903A.toInt()
    private val INK = 0xFF1B1B1B.toInt()
    private val GRAY = 0xFF666666.toInt()

    private fun paint(size: Float, bold: Boolean = false, color: Int = INK, align: Paint.Align = Paint.Align.LEFT) =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size; this.color = color; textAlign = align
            typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }

    private fun wrap(text: String, p: Paint, width: Float): List<String> {
        val out = ArrayList<String>()
        for (para in text.split('\n')) {
            var line = ""
            for (word in para.split(' ')) {
                val t = if (line.isEmpty()) word else "$line $word"
                if (p.measureText(t) <= width) line = t else {
                    if (line.isNotEmpty()) out += line
                    var w = word
                    while (p.measureText(w) > width && w.length > 1) {
                        val n = p.breakText(w, true, width, null).coerceAtLeast(1)
                        out += w.substring(0, n); w = w.substring(n)
                    }
                    line = w
                }
            }
            out += line
        }
        return out
    }

    private class Pager(val doc: PdfDocument) {
        var no = 0
        lateinit var page: PdfDocument.Page
        lateinit var c: Canvas
        var y = M
        fun next() {
            if (no > 0) doc.finishPage(page)
            no++
            page = doc.startPage(PdfDocument.PageInfo.Builder(W, H, no).create())
            c = page.canvas
            c.drawColor(Color.WHITE)
            y = M
        }
        fun ensure(h: Float, onNew: () -> Unit) { if (y + h > H - M) { next(); onNew() } }
        fun finish() { if (no > 0) doc.finishPage(page) }
    }

    fun write(company: Company, q: Quote, note: Note?, renderer: SheetRenderer?, out: OutputStream, logo: android.graphics.Bitmap? = null) {
        val doc = PdfDocument()
        try {
            val pg = Pager(doc)
            pg.next()
            val c0 = pg.c
            val dateFmt = br.com.arque.measure.i18n.I18n.dateFormat()

            // cabeçalho com os dados da empresa
            val top = pg.y
            var tx = M
            var logoH = 0f
            if (logo != null && logo.width > 0 && logo.height > 0) {
                val k = minOf(64f / logo.height, 150f / logo.width)
                val lw = logo.width * k; logoH = logo.height * k
                c0.drawBitmap(logo, null, android.graphics.RectF(M, top, M + lw, top + logoH), Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))
                tx = M + lw + 14f
            }
            c0.drawText(company.name.ifBlank { tr("Minha empresa") }.uppercase(), tx, pg.y + 18f, paint(18f, true))
            pg.y += 26f
            val sub = listOfNotNull(
                company.cnpj.takeIf { it.isNotBlank() }?.let { tr("CNPJ {0}", it) },
                company.phone.takeIf { it.isNotBlank() },
            ).joinToString("  ·  ")
            if (sub.isNotEmpty()) { c0.drawText(sub, tx, pg.y + 10f, paint(10f, color = GRAY)); pg.y += 14f }
            val addr = listOf(company.address, company.city).filter { it.isNotBlank() }.joinToString(" - ")
            if (addr.isNotEmpty()) { c0.drawText(addr, tx, pg.y + 10f, paint(10f, color = GRAY)); pg.y += 14f }
            if (pg.y < top + logoH) pg.y = top + logoH
            pg.y += 6f
            val gold = Paint().apply { color = GOLD; strokeWidth = 2f }
            c0.drawLine(M, pg.y, W - M, pg.y, gold)
            pg.y += 22f

            c0.drawText(tr("ORÇAMENTO"), M, pg.y, paint(20f, true))
            c0.drawText(dateFmt.format(Date(q.dateMs)), W - M, pg.y, paint(11f, color = GRAY, align = Paint.Align.RIGHT))
            pg.y += 22f
            val lab = paint(10f, color = GRAY)
            val valp = paint(12f, true)
            c0.drawText(tr("CLIENTE"), M, pg.y, lab); c0.drawText(tr("CIDADE"), 330f, pg.y, lab)
            pg.y += 15f
            c0.drawText(q.clientName.ifBlank { "—" }, M, pg.y, valp); c0.drawText(q.city.ifBlank { "—" }, 330f, pg.y, valp)
            pg.y += 26f

            val right1 = 300f   // quantidade
            val unitX = 308f
            val right2 = 440f   // valor unitário
            val right3 = W - M  // subtotal
            val descW = right1 - 52f - M

            fun tableHead() {
                val hp = paint(9.5f, true, Color.WHITE)
                val bg = Paint().apply { color = INK }
                pg.c.drawRect(M, pg.y, W - M, pg.y + 20f, bg)
                pg.c.drawText(tr("DESCRIÇÃO"), M + 6f, pg.y + 13.5f, hp)
                pg.c.drawText(tr("QTD"), right1, pg.y + 13.5f, paint(9.5f, true, Color.WHITE, Paint.Align.RIGHT))
                pg.c.drawText(tr("UN"), unitX, pg.y + 13.5f, hp)
                pg.c.drawText(tr("VALOR UNIT."), right2, pg.y + 13.5f, paint(9.5f, true, Color.WHITE, Paint.Align.RIGHT))
                pg.c.drawText(tr("SUBTOTAL"), right3 - 6f, pg.y + 13.5f, paint(9.5f, true, Color.WHITE, Paint.Align.RIGHT))
                pg.y += 20f
            }
            tableHead()
            val tp = paint(11f)
            val line = Paint().apply { color = 0xFFDDDDDD.toInt(); strokeWidth = 0.7f }
            q.items.filter { it.desc.isNotBlank() || it.unitValue != 0.0 }.forEachIndexed { idx, it ->
                val lines = wrap(it.desc.ifBlank { "—" }, tp, descW)
                val rowH = lines.size * 14f + 10f
                pg.ensure(rowH + 4f) { tableHead() }
                if (idx % 2 == 1) pg.c.drawRect(M, pg.y, W - M, pg.y + rowH, Paint().apply { color = 0xFFF6F3EC.toInt() })
                var ty = pg.y + 15f
                lines.forEach { l -> pg.c.drawText(l, M + 6f, ty, tp); ty += 14f }
                val y1 = pg.y + 15f
                pg.c.drawText(QuoteMath.numStr(it.qty), right1, y1, paint(11f, align = Paint.Align.RIGHT))
                pg.c.drawText(it.unit, unitX, y1, tp)
                pg.c.drawText(QuoteMath.brl(it.unitValue), right2, y1, paint(11f, align = Paint.Align.RIGHT))
                pg.c.drawText(QuoteMath.brl(QuoteMath.lineTotal(it)), right3 - 6f, y1, paint(11f, true, align = Paint.Align.RIGHT))
                pg.y += rowH
                pg.c.drawLine(M, pg.y, W - M, pg.y, line)
            }
            pg.y += 14f

            // totais
            val orig = QuoteMath.original(q)
            val hasDisc = q.discountPct > 0.0
            pg.ensure(if (hasDisc) 90f else 50f) {}
            val rp = paint(11f, color = GRAY, align = Paint.Align.RIGHT)
            if (hasDisc) {
                pg.c.drawText(tr("Valor original"), right2, pg.y + 12f, rp)
                pg.c.drawText(QuoteMath.brl(orig), right3 - 6f, pg.y + 12f, paint(11f, align = Paint.Align.RIGHT))
                pg.y += 18f
                pg.c.drawText(tr("Desconto ({0}%)", QuoteMath.numStr(q.discountPct)), right2, pg.y + 12f, rp)
                pg.c.drawText("− " + QuoteMath.brl(QuoteMath.discountValue(q)), right3 - 6f, pg.y + 12f, paint(11f, align = Paint.Align.RIGHT))
                pg.y += 22f
            }
            pg.c.drawRect(300f, pg.y, W - M, pg.y + 28f, Paint().apply { color = GOLD })
            pg.c.drawText(if (hasDisc) tr("VALOR COM DESCONTO") else tr("TOTAL"), 308f, pg.y + 18.5f, paint(10.5f, true, Color.WHITE))
            pg.c.drawText(QuoteMath.brl(QuoteMath.finalValue(q)), right3 - 8f, pg.y + 19f, paint(14f, true, Color.WHITE, Paint.Align.RIGHT))
            pg.y += 46f

            // validade e observações
            val until = Date(q.dateMs + q.validityDays * 86_400_000L)
            val vp = paint(11f)
            val extra = ArrayList<String>()
            extra += tr("Validade desta proposta: {0} dias (até {1}).", q.validityDays, dateFmt.format(until))
            if (q.notes.isNotBlank()) extra += tr("Observações: ") + q.notes.trim()
            val wrapped = extra.flatMap { wrap(it, vp, W - 2 * M) + "" }
            wrapped.forEach { l ->
                pg.ensure(16f) {}
                pg.c.drawText(l, M, pg.y + 11f, vp); pg.y += if (l.isEmpty()) 6f else 15f
            }

            // desenho (folhas da nota), uma página cada
            if (q.includeDrawing && note != null && renderer != null) {
                val k = W / Sheet.W
                note.pages.forEach { sheet ->
                    pg.next()
                    pg.c.scale(k, k)
                    renderer.draw(pg.c, sheet, note.unit, null, 1f, withPaper = false)
                }
            }
            pg.finish()
            doc.writeTo(out)
        } finally {
            doc.close()
        }
    }
}
