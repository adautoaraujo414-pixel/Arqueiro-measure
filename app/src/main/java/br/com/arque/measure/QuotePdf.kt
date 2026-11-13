package br.com.arque.measure

import br.com.arque.measure.i18n.tr

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import br.com.arque.measure.logic.QuoteMath
import br.com.arque.measure.model.Company
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Quote
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.ui.SheetRenderer
import java.io.OutputStream
import java.util.Date

/**
 * Orçamento em PDF (A4). Cabeçalho com os dados da empresa e o selo ORÇAMENTO, cartão do cliente, tabela dos itens,
 * totais, aditivos, detalhes da proposta, fotos do projeto, especificações técnicas e observações; rodapé com a página.
 * Só entra o que existe no orçamento: nada é inventado. Se [note] vier, as folhas do desenho entram depois.
 * O mesmo desenho (medidas e textos) está em ios/Arquemestre/Render/Export.swift: mexeu aqui, mexa lá.
 */
object QuotePdf {
    private const val W = 595
    private const val H = 842
    private const val M = 20f
    /** Onde o conteúdo começa (depois do cabeçalho) e onde tem que parar (antes do rodapé). */
    private const val TOP = 106f
    private const val BOTTOM = 786f

    private val YEL = 0xFFFFC20E.toInt()
    private val YEL2 = 0xFFF2A900.toInt()
    private val DARK = 0xFF1C1D21.toInt()
    private val INK = 0xFF17181B.toInt()
    private val GRAY = 0xFF5F6368.toInt()
    private val CARD = 0xFFF1F2F4.toInt()
    private val SOFT = 0xFFF8F8FA.toInt()
    private val EDGE = 0xFFD8DADF.toInt()

    private fun paint(size: Float, bold: Boolean = false, color: Int = INK, align: Paint.Align = Paint.Align.LEFT) =
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = size; this.color = color; textAlign = align
            typeface = if (bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }

    private fun fill(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color; style = Paint.Style.FILL }

    private fun line(color: Int, w: Float) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.color = color; style = Paint.Style.STROKE; strokeWidth = w
        strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
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

    /** Encolhe a letra até caber na largura; se nem no tamanho mínimo couber, corta com reticências. */
    private fun fit(text: String, p: Paint, width: Float, min: Float): String {
        while (p.measureText(text) > width && p.textSize > min) p.textSize -= 0.5f
        if (p.measureText(text) <= width) return text
        var t = text
        while (t.length > 1 && p.measureText("$t…") > width) t = t.dropLast(1)
        return "$t…"
    }

    /** Retângulo com o raio de cada canto: cima-esquerda, cima-direita, baixo-direita, baixo-esquerda. */
    private fun rr(l: Float, t: Float, r: Float, b: Float, c1: Float, c2: Float, c3: Float, c4: Float) = Path().apply {
        moveTo(l + c1, t)
        lineTo(r - c2, t); if (c2 > 0f) quadTo(r, t, r, t + c2)
        lineTo(r, b - c3); if (c3 > 0f) quadTo(r, b, r - c3, b)
        lineTo(l + c4, b); if (c4 > 0f) quadTo(l, b, l, b - c4)
        lineTo(l, t + c1); if (c1 > 0f) quadTo(l, t, l + c1, t)
        close()
    }

    /** Ícones de traço em caixa 24×24: M = começa, L = reta, C = curva, O = círculo (centro e raio), Z = fecha. */
    private val ICONS: Map<String, String> = mapOf(
        "user" to "O 12 8 4 M 4 21 C 4 16.6 7.6 14.5 12 14.5 C 16.4 14.5 20 16.6 20 21",
        "pin" to "M 12 22 C 9.5 19.4 5 14.6 5 10 C 5 6.1 8.1 3 12 3 C 15.9 3 19 6.1 19 10 C 19 14.6 14.5 19.4 12 22 Z O 12 10 2.6",
        "cal" to "M 5.2 5 L 18.8 5 C 20.02 5 21 5.98 21 7.2 L 21 18.8 C 21 20.02 20.02 21 18.8 21 L 5.2 21 C 3.98 21 3 20.02 3 18.8 L 3 7.2 C 3 5.98 3.98 5 5.2 5 Z M 3 10 L 21 10 M 8 3 L 8 7 M 16 3 L 16 7 M 7.6 14 L 8.6 14 M 11.5 14 L 12.5 14 M 15.4 14 L 16.4 14 M 7.6 17.5 L 8.6 17.5 M 11.5 17.5 L 12.5 17.5",
        "doc" to "M 7 3 L 14 3 L 19 8 L 19 19 C 19 20.1 18.1 21 17 21 L 7 21 C 5.9 21 5 20.1 5 19 L 5 5 C 5 3.9 5.9 3 7 3 Z M 14 3 L 14 8 L 19 8 M 8.5 12.5 L 15.5 12.5 M 8.5 16.5 L 15.5 16.5",
        "box" to "M 12 2.5 L 20.5 7 L 20.5 17 L 12 21.5 L 3.5 17 L 3.5 7 Z M 3.5 7 L 12 11.5 L 20.5 7 M 12 11.5 L 12 21.5",
        "roller" to "M 4.7 3.5 L 15.8 3.5 C 16.46 3.5 17 4.04 17 4.7 L 17 7.8 C 17 8.46 16.46 9 15.8 9 L 4.7 9 C 4.04 9 3.5 8.46 3.5 7.8 L 3.5 4.7 C 3.5 4.04 4.04 3.5 4.7 3.5 Z M 17 6.2 L 20.5 6.2 L 20.5 12.4 L 11.6 12.4 L 11.6 15 M 10.8 15 L 12.4 15 C 12.95 15 13.4 15.45 13.4 16 L 13.4 20.5 C 13.4 21.05 12.95 21.5 12.4 21.5 L 10.8 21.5 C 10.25 21.5 9.8 21.05 9.8 20.5 L 9.8 16 C 9.8 15.45 10.25 15 10.8 15 Z",
        "camera" to "M 4 7.5 L 7.4 7.5 L 9 5 L 15 5 L 16.6 7.5 L 20 7.5 C 21.1 7.5 22 8.4 22 9.5 L 22 18 C 22 19.1 21.1 20 20 20 L 4 20 C 2.9 20 2 19.1 2 18 L 2 9.5 C 2 8.4 2.9 7.5 4 7.5 Z O 12 13.5 3.6",
        "list" to "M 6 3.5 L 18 3.5 C 19.1 3.5 20 4.4 20 5.5 L 20 18.5 C 20 19.6 19.1 20.5 18 20.5 L 6 20.5 C 4.9 20.5 4 19.6 4 18.5 L 4 5.5 C 4 4.4 4.9 3.5 6 3.5 Z M 8 8.5 L 16 8.5 M 8 12 L 16 12 M 8 15.5 L 13 15.5",
        "note" to "M 6 4.5 L 18 4.5 C 19.1 4.5 20 5.4 20 6.5 L 20 19 C 20 20.1 19.1 21 18 21 L 6 21 C 4.9 21 4 20.1 4 19 L 4 6.5 C 4 5.4 4.9 4.5 6 4.5 Z M 8 2.8 L 8 6.2 M 12 2.8 L 12 6.2 M 16 2.8 L 16 6.2 M 8 11 L 16 11 M 8 14.2 L 16 14.2 M 8 17.4 L 13 17.4",
        "check" to "O 12 12 9 M 8 12.3 L 11 15.2 L 16.2 9.2",
        "plus" to "O 12 12 9 M 12 8 L 12 16 M 8 12 L 16 12",
        "info" to "O 12 12 9 M 12 11 L 12 16.5 M 12 7.6 L 12 7.9",
        "quote" to "M 11 21.5 L 6 21.5 C 4.9 21.5 4 20.6 4 19.5 L 4 4.5 C 4 3.4 4.9 2.5 6 2.5 L 13 2.5 L 17.5 7 L 17.5 10.2 M 13 2.5 L 13 7 L 17.5 7 M 7 10 L 11 10 M 7 13.5 L 9.6 13.5 M 7 17 L 9.6 17 M 13.6 12.4 L 20.2 12.4 C 20.97 12.4 21.6 13.03 21.6 13.8 L 21.6 20.8 C 21.6 21.57 20.97 22.2 20.2 22.2 L 13.6 22.2 C 12.83 22.2 12.2 21.57 12.2 20.8 L 12.2 13.8 C 12.2 13.03 12.83 12.4 13.6 12.4 Z M 14.6 15 L 19.2 15 M 14.7 17.7 L 14.9 17.7 M 16.8 17.7 L 17 17.7 M 18.9 17.7 L 19.1 17.7 M 14.7 19.9 L 14.9 19.9 M 16.8 19.9 L 17 19.9 M 18.9 19.9 L 19.1 19.9",
        "tools" to "M 20.98 7.93 C 21.14 9.78 20.34 11.59 18.85 12.71 C 17.37 13.83 15.41 14.11 13.67 13.44 L 7.82 19.29 C 6.96 20.15 5.57 20.15 4.71 19.29 C 3.85 18.43 3.85 17.04 4.71 16.18 L 10.56 10.33 C 9.89 8.59 10.17 6.63 11.29 5.15 C 12.41 3.66 14.22 2.86 16.07 3.02 L 12.86 6.23 L 17.77 11.14 Z",
    )

    private fun icon(c: Canvas, name: String, x: Float, y: Float, size: Float, color: Int) {
        val d = ICONS[name] ?: return
        val k = size / 24f
        val t = d.split(' ')
        val p = Path()
        var i = 0
        while (i < t.size) {
            when (t[i]) {
                "M" -> { p.moveTo(x + t[i + 1].toFloat() * k, y + t[i + 2].toFloat() * k); i += 3 }
                "L" -> { p.lineTo(x + t[i + 1].toFloat() * k, y + t[i + 2].toFloat() * k); i += 3 }
                "C" -> {
                    p.cubicTo(x + t[i + 1].toFloat() * k, y + t[i + 2].toFloat() * k, x + t[i + 3].toFloat() * k, y + t[i + 4].toFloat() * k,
                        x + t[i + 5].toFloat() * k, y + t[i + 6].toFloat() * k); i += 7
                }
                "O" -> { p.addCircle(x + t[i + 1].toFloat() * k, y + t[i + 2].toFloat() * k, t[i + 3].toFloat() * k, Path.Direction.CW); i += 4 }
                "Z" -> { p.close(); i += 1 }
                else -> i += 1
            }
        }
        c.drawPath(p, line(color, 1.7f * k))
    }

    /** Uma linha "Rótulo: texto" das observações (com as linhas seguintes, quando é uma lista). */
    class NoteRow(val label: String, val lines: MutableList<String>)

    private val LABELS = listOf("Material", "Móveis do projeto", "Cores do projeto")
    private val WALLS = listOf("Parede do fundo", "Parede da esquerda", "Parede da direita")
    private fun oneOf(s: String, keys: List<String>): Boolean {
        val t = s.trim()
        return keys.any { t.equals(it, true) || t.equals(tr(it), true) }
    }

    /** Linha de móvel da lista do editor: "• 2 × Balcão · …". */
    private fun furnBullet(l: String): Boolean {
        if (!l.startsWith("• ")) return false
        val r = l.substring(2)
        val n = r.takeWhile { it in '0'..'9' }.length
        return n > 0 && r.substring(n).startsWith(" × ")
    }

    /**
     * Separa as observações do orçamento. As linhas que o editor de móveis escreve (Material, Móveis do projeto com a lista
     * e Cores do projeto) viram linhas dos detalhes da proposta; tudo que a pessoa digitou fica em Observações.
     * Nenhum texto é mudado nem some.
     */
    fun parseNotes(notes: String): Pair<List<NoteRow>, List<String>> {
        val rows = ArrayList<NoteRow>()
        val free = ArrayList<String>()
        var open: NoteRow? = null
        for (raw in notes.split('\n')) {
            val l = raw.trim()
            if (l.isEmpty()) { open = null; continue }
            val o = open
            // lista aberta: as linhas dos móveis e o nome da parede ("Parede do fundo:") entram nela
            if (o != null && (furnBullet(l) || (l.endsWith(":") && oneOf(l.dropLast(1), WALLS)))) { o.lines += l; continue }
            open = null
            if (l.endsWith(":")) {
                // cabeçalho de lista: "Móveis do projeto (3) · largura × altura × profundidade:"
                val cut = listOf(l.indexOf(" ("), l.indexOf(" · ")).filter { it > 0 }.minOrNull()
                val label = (if (cut != null) l.substring(0, cut) else l.dropLast(1)).trim()
                val rest = if (cut != null) l.substring(cut).trim().removePrefix("·").trim() else ""
                if (oneOf(label, LABELS)) {
                    val r = NoteRow(label, if (rest.isEmpty()) arrayListOf() else arrayListOf(rest))
                    rows += r; open = r; continue
                }
            }
            val i = l.indexOf(": ")
            if (i > 0 && i < l.length - 2 && oneOf(l.substring(0, i), LABELS)) {
                rows += NoteRow(l.substring(0, i).trim(), arrayListOf(l.substring(i + 2).trim()))
                continue
            }
            free += l
        }
        return rows to free
    }

    /** Partes da linha Material ("MDF 15 mm · caixa Branco · …"), uma por item das especificações. */
    fun specParts(rows: List<NoteRow>): List<String> {
        val mat = rows.firstOrNull { oneOf(it.label, listOf("Material")) } ?: return emptyList()
        return mat.lines.joinToString(" ").trim().trimEnd('.').split(" · ").map { it.trim() }.filter { it.isNotEmpty() }
            .map { it.substring(0, 1).uppercase() + it.substring(1) }
    }

    /** Quantas fotos em cada linha: até 3 numa linha; sobrando 2 ou 4, as primeiras linhas saem com 2 fotos maiores. */
    fun photoGroups(n: Int): List<Int> = when {
        n <= 0 -> emptyList()
        n <= 3 -> listOf(n)
        n % 3 == 0 -> List(n / 3) { 3 }
        n % 3 == 2 -> listOf(2) + List((n - 2) / 3) { 3 }
        else -> listOf(2, 2) + List((n - 4) / 3) { 3 }
    }

    private class Block(val h: Float, val draw: (Canvas, Float, Boolean) -> Unit)

    private class TRow(val main: List<String>, val sub: List<String>, val qty: String, val unit: String, val unitV: String, val tot: String, val h: Float)

    private class Layout(val doc: PdfDocument?, val total: Int, val company: Company, val q: Quote, val logo: Bitmap?, val photos: List<Bitmap>) {
        /** Passada que só conta as páginas (pro "página N/M" do rodapé): desenha num papel de rascunho. */
        val dry = doc == null
        private val scratch: Canvas? = if (dry) Canvas(Bitmap.createBitmap(4, 4, Bitmap.Config.ARGB_8888)) else null
        private var page: PdfDocument.Page? = null
        private val dateFmt = br.com.arque.measure.i18n.I18n.dateFormat()
        var no = 0
        lateinit var c: Canvas
        var y = TOP

        private fun open() {
            if (doc != null) {
                page?.let { doc.finishPage(it) }
                no++
                val p = doc.startPage(PdfDocument.PageInfo.Builder(W, H, no).create())
                page = p; c = p.canvas
            } else { no++; c = scratch!! }
            c.drawColor(Color.WHITE)
        }

        /** Página nova do orçamento, já com o cabeçalho e o rodapé. */
        fun next() { open(); header(); footer(); y = TOP }

        /** Página em branco (folha do desenho). */
        fun blank(): Canvas { open(); return c }

        fun finish() { if (doc != null) page?.let { doc.finishPage(it) }; page = null }

        private fun header() {
            c.drawRoundRect(M + 4f, 30f, M + 7.5f, 90f, 1.75f, 1.75f, fill(YEL))
            var tx = M + 18f
            val bl = 306f
            if (logo != null && logo.width > 0 && logo.height > 0) {
                val k = minOf(52f / logo.height, 64f / logo.width)
                val lw = logo.width * k; val lh = logo.height * k
                if (!dry) c.drawBitmap(logo, null, RectF(tx, 60f - lh / 2f, tx + lw, 60f + lh / 2f), Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG))
                tx += lw + 12f
            }
            val maxW = bl - 14f - tx
            val txt = 0xFF2B2D31.toInt()
            val name = company.name.ifBlank { tr("Minha empresa") }.uppercase()
            val np = paint(21f, true)
            while (np.measureText(name) > maxW && np.textSize > 13f) np.textSize -= 0.5f
            val nl = if (np.measureText(name) > maxW) wrap(name, np, maxW).take(2) else listOf(name)
            // CNPJ e telefone: numa linha só se couber; senão, uma linha pra cada (nada é cortado)
            val pieces = listOfNotNull(
                company.cnpj.takeIf { it.isNotBlank() }?.let { tr("CNPJ {0}", it) },
                company.phone.takeIf { it.isNotBlank() },
            )
            val joined = pieces.joinToString("   |   ")
            var subSize = 10f
            while (paint(subSize).measureText(joined) > maxW && subSize > 8.5f) subSize -= 0.5f
            val subLines = if (pieces.isEmpty()) emptyList() else if (paint(subSize).measureText(joined) <= maxW) listOf(joined) else { subSize = 10f; pieces }
            // endereço: quebra em até 3 linhas
            val addr = listOf(company.address, company.city).filter { it.isNotBlank() }.joinToString(" – ")
            var addrSize = 10f
            var al = if (addr.isEmpty()) emptyList() else wrap(addr, paint(addrSize), maxW - 14f)
            if (al.size > 2) { addrSize = 8.5f; al = wrap(addr, paint(addrSize), maxW - 14f).take(3) }
            val small = subLines.size + al.size
            val step = if (small <= 2) 17f else 13.5f
            val ns = np.textSize
            var by = 60f - (nl.size * ns * 1.08f + small * step) / 2f
            nl.forEach { l -> c.drawText(l, tx, by + ns * 0.82f, np); by += ns * 1.08f }
            subLines.forEach { l ->
                val sp = paint(subSize, color = txt)
                c.drawText(fit(l, sp, maxW, 7f), tx, by + step - 4.5f, sp); by += step
            }
            al.forEachIndexed { k, l ->
                val ap = paint(addrSize, color = txt)
                if (k == 0) icon(c, "pin", tx - 1f, by + step - 13.5f, 11f, INK)
                c.drawText(fit(l, ap, maxW - 14f, 7f), tx + 14f, by + step - 4.5f, ap); by += step
            }

            // selo ORÇAMENTO
            val bt = 26f; val bb = 92f; val br = W - M
            c.drawPath(Path().apply { moveTo(bl - 4f, bb); lineTo(bl + 26f, bt); lineTo(bl + 44f, bt); lineTo(bl + 14f, bb); close() }, fill(YEL))
            c.drawPath(Path().apply {
                moveTo(bl + 42f, bt); lineTo(br - 9f, bt); quadTo(br, bt, br, bt + 9f); lineTo(br, bb - 9f); quadTo(br, bb, br - 9f, bb)
                lineTo(bl + 12f, bb); close()
            }, fill(DARK))
            icon(c, "quote", bl + 52f, bt + 14f, 38f, YEL)
            val tp = paint(24f, true, Color.WHITE)
            c.drawText(fit(tr("ORÇAMENTO"), tp, br - 14f - (bl + 100f), 12f), bl + 100f, bt + 33f, tp)
            icon(c, "cal", bl + 100f, bt + 43f, 12f, YEL)
            c.drawText(dateFmt.format(Date(q.dateMs)), bl + 117f, bt + 53.5f, paint(11.5f, color = Color.WHITE))
        }

        private fun footer() {
            val ft = H - 36f
            c.drawRect(0f, ft, W.toFloat(), H.toFloat(), fill(DARK))
            c.drawRect(0f, ft + 8f, 336f, ft + 10f, fill(YEL))
            c.drawPath(Path().apply { moveTo(350f, H.toFloat()); lineTo(376f, ft - 8f); lineTo(W.toFloat(), ft - 8f); lineTo(W.toFloat(), H.toFloat()); close() }, fill(YEL))
            c.drawPath(Path().apply { moveTo(W - 44f, H.toFloat()); lineTo(W.toFloat(), H - 44f); lineTo(W.toFloat(), H.toFloat()); close() }, fill(YEL2))
            if (total > 1) {
                val s = "$no/$total"
                val pp = paint(10.5f, color = Color.WHITE, align = Paint.Align.CENTER)
                c.drawText(s, 298f, H - 9.5f, pp)
                val hw = pp.measureText(s) / 2f + 9f
                c.drawRect(298f - hw - 1.5f, H - 19f, 298f - hw, H - 8f, fill(YEL))
                c.drawRect(298f + hw, H - 19f, 298f + hw + 1.5f, H - 8f, fill(YEL))
            }
        }

        private fun client() {
            val t = y; val b = y + 46f
            val mid = 300f
            c.drawRoundRect(M, t, W - M, b, 8f, 8f, fill(CARD))
            icon(c, "user", M + 20f, t + 12f, 22f, INK)
            c.drawText(tr("CLIENTE"), M + 56f, t + 18f, paint(8.5f, color = GRAY))
            val cp = paint(13f, true)
            c.drawText(fit(q.clientName.ifBlank { "—" }, cp, mid - 12f - (M + 56f), 9f), M + 56f, t + 34f, cp)
            c.drawRect(mid, t + 10f, mid + 0.8f, b - 10f, fill(0xFFC6C9CF.toInt()))
            icon(c, "pin", mid + 24f, t + 12f, 22f, INK)
            c.drawText(tr("CIDADE"), mid + 60f, t + 18f, paint(8.5f, color = GRAY))
            val yp = paint(13f, true)
            c.drawText(fit(q.city.ifBlank { "—" }, yp, W - M - 12f - (mid + 60f), 9f), mid + 60f, t + 34f, yp)
            y = b + 14f
        }

        private fun table() {
            val descX = M + 14f; val descW = 262f
            val qtyX = 322f; val unX = 362f; val unitR = 470f; val subL = 480f; val subR = W - M - 10f
            val mp = paint(10.5f, true); val sp = paint(9.5f, color = GRAY)
            val rows = q.items.filter { it.desc.isNotBlank() || it.unitValue != 0.0 }.map { it ->
                val d = it.desc.ifBlank { "—" }.trim()
                // "Cozinha · Módulos de cima (aéreos) · 1 módulo": a contagem do fim desce pra uma segunda linha
                val cut = d.lastIndexOf(" · ")
                val tail = if (cut > 0) d.substring(cut + 3).trim() else ""
                val split = tail.isNotEmpty() && tail[0] in '0'..'9'
                val main = wrap(if (split) d.substring(0, cut) else d, mp, descW)
                val sub = if (split) wrap(tail, sp, descW) else emptyList()
                TRow(main, sub, QuoteMath.numStr(it.qty), it.unit, QuoteMath.brl(it.unitValue), QuoteMath.brl(QuoteMath.lineTotal(it)),
                    maxOf(34f, 21f + main.size * 13f + sub.size * 12f))
            }.ifEmpty { listOf(TRow(listOf("—"), emptyList(), "", "", "", "", 34f)) }

            fun head() {
                c.drawPath(rr(M, y, W - M, y + 24f, 7f, 7f, 0f, 0f), fill(DARK))
                c.drawText(tr("DESCRIÇÃO"), descX, y + 16f, paint(9.5f, true, Color.WHITE))
                c.drawText(tr("QTD"), qtyX, y + 16f, paint(9.5f, true, Color.WHITE, Paint.Align.CENTER))
                c.drawText(tr("UN"), unX, y + 16f, paint(9.5f, true, Color.WHITE, Paint.Align.CENTER))
                c.drawText(tr("VALOR UNIT."), unitR, y + 16f, paint(9.5f, true, Color.WHITE, Paint.Align.RIGHT))
                c.drawText(tr("SUBTOTAL"), subR, y + 16f, paint(9.5f, true, Color.WHITE, Paint.Align.RIGHT))
                y += 24f
            }

            var i = 0
            while (true) {
                if (y + 24f + rows[i].h > BOTTOM && y > TOP) next()
                head()
                val top = y
                var bot = top
                val start = i
                while (i < rows.size && (bot + rows[i].h <= BOTTOM || i == start)) { bot += rows[i].h; i++ }
                val body = rr(M, top, W - M, bot, 0f, 0f, 7f, 7f)
                c.save(); c.clipPath(body)
                c.drawRect(M, top, W - M, bot, fill(Color.WHITE))
                c.drawRect(subL, top, W - M, bot, fill(0xFFF4F5F7.toInt()))
                c.restore()
                var ry = top
                for (k in start until i) {
                    val r = rows[k]
                    if (k > start) c.drawRect(M, ry - 0.35f, W - M, ry + 0.35f, fill(EDGE))
                    var ty = ry + 21f
                    r.main.forEach { l -> c.drawText(l, descX, ty, mp); ty += 13f }
                    ty -= 1f
                    r.sub.forEach { l -> c.drawText(l, descX, ty, sp); ty += 12f }
                    val by = ry + r.h / 2f + 3.8f
                    c.drawText(r.qty, qtyX, by, paint(10.5f, align = Paint.Align.CENTER))
                    c.drawText(r.unit, unX, by, paint(10.5f, align = Paint.Align.CENTER))
                    val up = paint(10.5f, align = Paint.Align.RIGHT)
                    c.drawText(fit(r.unitV, up, unitR - 384f, 7f), unitR, by, up)
                    val sb = paint(10.5f, true, align = Paint.Align.RIGHT)
                    c.drawText(fit(r.tot, sb, subR - subL - 4f, 7f), subR, by, sb)
                    ry += r.h
                }
                c.drawPath(body, line(EDGE, 0.8f))
                y = bot
                if (i >= rows.size) break
                next()
            }
            y += 12f
        }

        /** Faixa do total: rótulo no amarelo, valor em amarelo no escuro. */
        private fun bar(label: String, value: String, l: Float, r: Float, t: Float) {
            val b = t + 34f
            val lp = paint(11f, true)
            val vp = paint(16f, true, YEL, Paint.Align.RIGHT)
            // o rótulo cede espaço pro valor: o valor nunca é cortado
            val lab = fit(label, lp, r - l - 16f - 14f - 13f - 8f - 12f - minOf(vp.measureText(value), 120f), 8f)
            val x0 = l + 16f + lp.measureText(lab) + 14f
            val shape = rr(l, t, r, b, 8f, 8f, 8f, 8f)
            c.drawPath(shape, fill(DARK))
            c.save(); c.clipPath(shape)
            c.drawPath(Path().apply { moveTo(l, t); lineTo(x0 + 13f, t); lineTo(x0, b); lineTo(l, b); close() }, fill(YEL))
            c.restore()
            c.drawText(lab, l + 16f, t + 21.5f, lp)
            c.drawText(fit(value, vp, r - 12f - (x0 + 13f + 8f), 8f), r - 12f, t + 22.5f, vp)
        }

        private fun totals() {
            val l = 262f; val r = W - M
            val hasDisc = q.discountPct > 0.0
            if (y + (if (hasDisc) 52f else 0f) + 34f > BOTTOM) next()
            if (hasDisc) {
                c.drawPath(rr(l, y, r, y + 64f, 8f, 8f, 0f, 0f), fill(CARD))
                val lp = paint(10.5f, color = 0xFF2B2D31.toInt(), align = Paint.Align.RIGHT)
                val vp = paint(10.5f, align = Paint.Align.RIGHT)
                c.drawText(tr("Valor original"), l + 150f, y + 17f, lp)
                c.drawText(QuoteMath.brl(QuoteMath.original(q)), r - 12f, y + 17f, vp)
                c.drawRect(l + 70f, y + 26f, r - 10f, y + 26.7f, fill(EDGE))
                c.drawText(tr("Desconto ({0}%)", QuoteMath.numStr(q.discountPct)), l + 150f, y + 43f, lp)
                c.drawText("− " + QuoteMath.brl(QuoteMath.discountValue(q)), r - 12f, y + 43f, vp)
                y += 52f
            }
            bar(if (hasDisc) tr("VALOR COM DESCONTO") else tr("TOTAL"), QuoteMath.brl(QuoteMath.finalValue(q)), l, r, y)
            y += 34f + 16f
        }

        private fun tab(top: Float, ic: String, title: String, cont: Boolean) {
            val tp = paint(10.5f, true, Color.WHITE)
            val yp = paint(9.5f, true, YEL)
            val more = tr("(CONTINUAÇÃO)")
            val w = 36f + tp.measureText(title) + (if (cont) 6f + yp.measureText(more) else 0f) + 26f
            val b = top + 25f
            c.drawPath(Path().apply {
                moveTo(M + 7f, top); lineTo(M + w, top); lineTo(M + w - 13f, b); lineTo(M, b); lineTo(M, top + 7f); quadTo(M, top, M + 7f, top); close()
            }, fill(DARK))
            icon(c, ic, M + 12f, top + 5.5f, 14f, YEL)
            c.drawText(title, M + 36f, top + 16.5f, tp)
            if (cont) c.drawText(more, M + 36f + tp.measureText(title) + 6f, top + 16.5f, yp)
        }

        /** Seção: aba escura com o título e cartão com as linhas. Passou do fim da folha, continua na outra com "(CONTINUAÇÃO)". */
        private fun section(ic: String, title: String, blocks: List<Block>, padB: Float = 9f) {
            if (blocks.isEmpty()) return
            val head = 33f
            var i = 0
            var first = true
            while (i < blocks.size) {
                if (y + head + blocks[i].h + padB > BOTTOM && y > TOP) next()
                val top = y
                var cy = top + head
                val start = i
                while (i < blocks.size && (cy + blocks[i].h + padB <= BOTTOM || i == start)) { cy += blocks[i].h; i++ }
                val bottom = cy + padB
                val card = rr(M, top + 15f, W - M, bottom, 0f, 8f, 8f, 8f)
                c.drawPath(card, fill(SOFT)); c.drawPath(card, line(EDGE, 0.8f))
                tab(top, ic, title, !first)
                var by = top + head
                for (k in start until i) { blocks[k].draw(c, by, k == start); by += blocks[k].h }
                y = bottom + 14f
                first = false
                if (i < blocks.size) next()
            }
        }

        private fun addenda() {
            val ads = q.addenda.filter { it.desc.isNotBlank() || it.value != 0.0 }
            if (ads.isEmpty()) return
            val dp = paint(9.5f, color = GRAY); val ap = paint(10.5f); val vp = paint(10.5f, true, align = Paint.Align.RIGHT)
            val descX = M + 84f; val descW = 470f - descX
            val blocks = ArrayList<Block>()
            ads.forEachIndexed { ai, a ->
                val ls = wrap(a.desc.ifBlank { "—" }, ap, descW)
                ls.forEachIndexed { k, l ->
                    val h = 14f + (if (k == 0) 6f else 0f) + (if (k == ls.size - 1) 5f else 0f)
                    blocks += Block(h) { cv, top, firstSeg ->
                        val base = top + (if (k == 0) 6f else 0f) + 10.5f
                        if (k == 0) {
                            if (ai > 0 && !firstSeg) cv.drawRect(M + 12f, top - 0.35f, W - M - 12f, top + 0.35f, fill(EDGE))
                            cv.drawText(dateFmt.format(Date(a.dateMs)), M + 14f, base, dp)
                            cv.drawText(QuoteMath.brl(a.value), W - M - 12f, base, vp)
                        }
                        cv.drawText(l, descX, base, ap)
                    }
                }
            }
            section("plus", tr("ADITIVOS"), blocks)
            if (y + 20f + 34f > BOTTOM) next()
            c.drawText(tr("Total dos aditivos"), 412f, y + 10f, paint(10.5f, color = 0xFF2B2D31.toInt(), align = Paint.Align.RIGHT))
            c.drawText(QuoteMath.brl(QuoteMath.addendaTotal(q)), W - M - 12f, y + 10f, paint(10.5f, align = Paint.Align.RIGHT))
            y += 20f
            bar(tr("TOTAL COM ADITIVOS"), QuoteMath.brl(QuoteMath.grandTotal(q)), 262f, W - M, y)
            y += 34f + 16f
        }

        private fun iconFor(label: String): String = when {
            oneOf(label, listOf("Material")) -> "doc"
            oneOf(label, listOf("Móveis do projeto")) -> "box"
            oneOf(label, listOf("Cores do projeto")) -> "roller"
            else -> "info"
        }

        private fun details(rows: List<NoteRow>) {
            val until = Date(q.dateMs + q.validityDays * 86_400_000L)
            val all = ArrayList<Triple<String, String, List<String>>>()
            all += Triple("cal", tr("Validade da proposta"), listOf(tr("{0} dias (até {1})", q.validityDays, dateFmt.format(until))))
            rows.forEach { r -> all += Triple(iconFor(r.label), r.label, r.lines) }
            val lp = paint(10f, true); val vp = paint(10f)
            val labX = M + 40f
            val labW = minOf(150f, all.maxOf { lp.measureText(it.second + ":") })
            val valX = labX + labW + 16f
            val valW = W - M - 12f - valX
            val blocks = ArrayList<Block>()
            all.forEachIndexed { ri, (ic, label, lines) ->
                val ll = wrap("$label:", lp, labW)
                val vl = lines.flatMap { wrap(it, vp, valW) }
                val n = maxOf(ll.size, vl.size, 1)
                for (k in 0 until n) {
                    val h = 14f + (if (k == 0) 7f else 0f) + (if (k == n - 1) 4f else 0f)
                    blocks += Block(h) { cv, top, firstSeg ->
                        val base = top + (if (k == 0) 7f else 0f) + 10.5f
                        if (k == 0) {
                            if (ri > 0 && !firstSeg) cv.drawRect(labX, top - 0.35f, W - M - 12f, top + 0.35f, fill(EDGE))
                            icon(cv, ic, M + 13f, top + 5f, 15f, INK)
                        }
                        ll.getOrNull(k)?.let { cv.drawText(it, labX, base, lp) }
                        vl.getOrNull(k)?.let { cv.drawText(it, valX, base, vp) }
                    }
                }
            }
            section("list", tr("DETALHES DA PROPOSTA"), blocks)
        }

        /** Fotos inteiras (sem cortar nada do móvel): cada linha ocupa a largura do cartão, todas na mesma altura. */
        private fun photoSec() {
            val ph = photos.filter { it.width > 0 && it.height > 0 }
            if (ph.isEmpty()) return
            val x0 = M + 10f; val wAll = W - 2 * M - 20f; val gap = 8f
            val bp = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)
            val blocks = ArrayList<Block>()
            var idx = 0
            photoGroups(ph.size).forEach { k ->
                val row = ph.subList(idx, idx + k); idx += k
                val ars = row.map { it.width.toFloat() / it.height }
                var h = minOf((wAll - gap * (k - 1)) / ars.sum(), if (k == 1) 300f else 240f)
                // primeira linha: se falta pouco pra caber no resto da folha, diminui um pouco em vez de pular de folha
                if (blocks.isEmpty()) { val room = BOTTOM - y - 33f - 2f - gap; if (h > room && room >= h * 0.6f) h = room }
                val ws = ars.map { it * h }
                val tot = ws.sum() + gap * (k - 1)
                blocks += Block(h + gap) { cv, top, _ ->
                    var x = x0 + (wAll - tot) / 2f
                    row.forEachIndexed { j, b ->
                        val r = RectF(x, top, x + ws[j], top + h)
                        if (!dry) {
                            cv.save(); cv.clipPath(Path().apply { addRoundRect(r, 6f, 6f, Path.Direction.CW) })
                            cv.drawBitmap(b, null, r, bp)
                            cv.restore()
                        }
                        x += ws[j] + gap
                    }
                }
            }
            section("camera", tr("FOTOS DO PROJETO"), blocks, 2f)
        }

        private fun specs(parts: List<String>) {
            if (parts.size < 2) return
            val half = (parts.size + 1) / 2
            val colW = (W - 2 * M) / 2f
            val blocks = (0 until half).map { r ->
                Block(21f) { cv, top, firstSeg ->
                    if (!firstSeg) {
                        cv.drawRect(M + 38f, top - 0.35f, M + colW - 14f, top + 0.35f, fill(EDGE))
                        if (r + half < parts.size) cv.drawRect(M + colW + 38f, top - 0.35f, W - M - 12f, top + 0.35f, fill(EDGE))
                    }
                    cv.drawRect(M + colW - 0.4f, top + 1f, M + colW + 0.4f, top + 20f, fill(EDGE))
                    for (col in 0..1) {
                        val i = r + col * half
                        if (i >= parts.size) continue
                        val x = M + 16f + col * colW
                        icon(cv, "check", x, top + 4f, 13f, INK)
                        val tp = paint(10f)
                        cv.drawText(fit(parts[i], tp, colW - 16f - 22f - 14f, 7.5f), x + 22f, top + 14.5f, tp)
                    }
                }
            }
            section("tools", tr("ESPECIFICAÇÕES TÉCNICAS"), blocks)
        }

        private fun obs(free: List<String>) {
            if (free.isEmpty()) return
            val p = paint(10.5f)
            val blocks = ArrayList<Block>()
            free.forEach { raw ->
                var t = raw.trim()
                if (t.startsWith("•")) t = t.substring(1).trim() else if (t.startsWith("- ")) t = t.substring(2).trim()
                wrap(t, p, W - 2 * M - 30f - 14f).forEachIndexed { k, l ->
                    blocks += Block(14.5f) { cv, top, _ ->
                        if (k == 0) cv.drawCircle(M + 19f, top + 7.2f, 1.7f, fill(INK))
                        cv.drawText(l, M + 30f, top + 11f, p)
                    }
                }
            }
            section("note", tr("OBSERVAÇÕES"), blocks)
        }

        /** Desenha o orçamento inteiro e devolve quantas páginas ele ocupou. */
        fun run(): Int {
            next()
            client()
            table()
            totals()
            addenda()
            val (rows, free) = parseNotes(q.notes)
            details(rows)
            photoSec()
            specs(specParts(rows))
            obs(free)
            return no
        }
    }

    fun write(company: Company, q: Quote, note: Note?, renderer: SheetRenderer?, out: OutputStream, logo: Bitmap? = null, photos: List<Bitmap> = emptyList()) {
        // 1ª passada: só conta as páginas do orçamento, pro rodapé dizer "página N/M"
        val total = Layout(null, 0, company, q, logo, photos).run()
        val doc = PdfDocument()
        try {
            val lay = Layout(doc, total, company, q, logo, photos)
            lay.run()
            // desenho (folhas da nota), uma página cada
            if (q.includeDrawing && note != null && renderer != null) {
                val k = W / Sheet.W
                note.pages.forEach { sheet ->
                    val cv = lay.blank()
                    cv.scale(k, k)
                    renderer.draw(cv, sheet, note.unit, null, 1f, withPaper = false)
                }
            }
            lay.finish()
            doc.writeTo(out)
        } finally {
            doc.close()
        }
    }
}
