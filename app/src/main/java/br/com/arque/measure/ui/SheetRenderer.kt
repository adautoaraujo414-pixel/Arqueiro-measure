package br.com.arque.measure.ui

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.logic.Units
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.logic.WallLayout
import br.com.arque.measure.model.PartKind
import br.com.arque.measure.model.SegKind
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeKind
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import br.com.arque.measure.model.Template
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

/**
 * Desenha a folha em um android.graphics.Canvas. Usado na tela e na exportação (PDF/PNG),
 * então o que se vê é exatamente o que se exporta. Coordenadas: unidades de folha.
 */
/** Cor de cada tipo de segmento (parede usa a cor do cômodo). */
fun roomSegColor(o: RoomObj, kind: SegKind): Int = when (kind) {
    SegKind.WALL -> o.color
    SegKind.PANEL -> 0xFF8E44AD.toInt()
    SegKind.SINK -> 0xFF1E88E5.toInt()
    SegKind.BASIN -> 0xFF00A88F.toInt()
    SegKind.DOOR -> 0xFFD35400.toInt()
}

class SheetRenderer(private val images: (String) -> Bitmap?) {
    private val paperFill = Paint().apply { color = 0xFFFFFFFF.toInt() }
    private val paperShadow = Paint().apply { color = 0x33000000 }
    private val paperBorder = Paint().apply { color = 0xFFC9C6BD.toInt(); style = Paint.Style.STROKE; strokeWidth = 1f }
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE; strokeCap = Paint.Cap.ROUND; strokeJoin = Paint.Join.ROUND
    }
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG or Paint.DITHER_FLAG)
    private val path = Path()
    private val rect = RectF()

    private val tplPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    private fun paintTemplate(c: Canvas, tpl: Template, w: Float, h: Float) {
        when (tpl) {
            Template.BLANK -> {}
            Template.LINES -> {
                tplPaint.style = Paint.Style.STROKE
                tplPaint.strokeWidth = 0.8f
                tplPaint.color = 0xFFD7DCE3.toInt()
                var y = 70f
                while (y < h - 30f) { c.drawLine(36f, y, w - 36f, y, tplPaint); y += 30f }
            }
            Template.ARAUJO -> paintAraujo(c, w, h)
        }
    }

    // Identidade da folha "Arquemestre": faixa preta, ouro, contatos e moldura arredondada.
    private val gold = 0xFFD9A93E.toInt()
    private val goldDeep = 0xFFC9972F.toInt()
    private val frameGold = 0xFFD9A441.toInt()

    private fun paintAraujo(c: Canvas, w: Float, h: Float) {
        val p = tplPaint
        p.reset(); p.isAntiAlias = true
        // fundo do papel
        p.style = Paint.Style.FILL; p.color = 0xFFF6F6F3.toInt()
        c.drawRect(0f, 0f, w, h, p)
        // faixa preta do topo (baixa) + filete dourado
        p.color = 0xFF121118.toInt()
        c.drawRect(0f, 0f, w, 64f, p)
        p.color = goldDeep
        c.drawRect(0f, 64f, w, 67f, p)
        // ARQUIMESTRE + frase
        p.color = gold; p.typeface = Typeface.DEFAULT_BOLD; p.textAlign = Paint.Align.LEFT
        p.textSize = 30f; p.letterSpacing = 0.06f
        c.drawText("ARQUEMESTRE", 36f, 38f, p)
        p.color = goldDeep; p.typeface = Typeface.DEFAULT; p.textSize = 9.5f; p.letterSpacing = 0.14f
        c.drawText("SOLUÇÕES DE MARCENARIA E ARQUITETURA", 37f, 54f, p)
        p.letterSpacing = 0f
        // divisória vertical
        p.style = Paint.Style.STROKE; p.strokeWidth = 1.2f; p.color = 0xFF8A6A25.toInt()
        c.drawLine(372f, 16f, 372f, 50f, p)
        // título
        p.style = Paint.Style.FILL; p.color = gold; p.typeface = Typeface.DEFAULT_BOLD
        p.textSize = 17f; p.textAlign = Paint.Align.CENTER; p.textScaleX = 0.92f
        c.drawText("ESPAÇO PARA DESENHAR / CROQUI", 584f, 44f, p)
        p.textScaleX = 1f
        // moldura arredondada dourada
        p.strokeWidth = 1.5f; p.color = frameGold
        p.style = Paint.Style.FILL; p.color = 0xFFFCFCFB.toInt()
        rect.set(18f, 84f, w - 18f, h - 14f); c.drawRoundRect(rect, 12f, 12f, p)
        p.style = Paint.Style.STROKE; p.color = frameGold
        c.drawRoundRect(rect, 12f, 12f, p)
        p.reset()
    }

    fun draw(c: Canvas, sheet: Sheet, unit: LengthUnit, selectedId: String?, viewScale: Float, withPaper: Boolean = true, selectedSeg: Int = -1) {
        if (withPaper) {
            c.drawRect(5f, 6f, sheet.width + 5f, sheet.height + 6f, paperShadow)
        }
        c.drawRect(0f, 0f, sheet.width, sheet.height, paperFill)
        paintTemplate(c, sheet.tpl, sheet.width, sheet.height)
        c.save()
        c.clipRect(0f, 0f, sheet.width, sheet.height)
        val photos = sheet.photos()
        for (o in sheet.objs) { if (o is br.com.arque.measure.model.WallObj) drawWall(c, o, sheet) else drawObj(c, o, photos, unit, selectedId == o.id) }
        c.restore()
        if (withPaper) c.drawRect(0f, 0f, sheet.width, sheet.height, paperBorder)
        sheet.obj(selectedId)?.let { drawSelection(c, sheet, it, viewScale, selectedSeg) }
    }

    private fun drawObj(c: Canvas, o: Obj, photos: Map<String, PhotoObj>, unit: LengthUnit, selected: Boolean) {
        when (o) {
            is PhotoObj -> drawPhoto(c, o)
            is StrokeObj -> drawStroke(c, o, photos)
            is ShapeObj -> drawShape(c, o, photos)
            is TextObj -> drawText(c, o, photos)
            is DimObj -> drawDim(c, o, photos, unit)
            is RoomObj -> drawRoom(c, o, photos, unit)
            is CabObj -> drawCab(c, o)
            is br.com.arque.measure.model.WallObj -> Unit
        }
    }

    private fun drawPhoto(c: Canvas, p: PhotoObj) {
        c.save()
        c.translate(p.cx, p.cy)
        c.rotate(p.rot)
        rect.set(-p.w / 2f, -p.h / 2f, p.w / 2f, p.h / 2f)
        val bmp = images(p.file)
        if (bmp != null) {
            c.drawBitmap(bmp, null, rect, bitmapPaint)
        } else {
            fillPaint.color = 0xFFDDDDDD.toInt()
            c.drawRect(rect, fillPaint)
            textPaint.color = 0xFF777777.toInt(); textPaint.textSize = 18f; textPaint.textAlign = Paint.Align.CENTER
            c.drawText("carregando…", 0f, 6f, textPaint)
        }
        c.restore()
    }

    private fun withAlpha(color: Int, alpha: Int): Int = (color and 0x00FFFFFF) or (alpha shl 24)

    private fun drawStroke(c: Canvas, o: StrokeObj, photos: Map<String, PhotoObj>) {
        val pts = Geo.annPoints(photos, o)
        val alpha = when (o.kind) {
            StrokeKind.PEN -> 255
            StrokeKind.PENCIL -> 205
            StrokeKind.HIGHLIGHTER -> 90
        }
        strokePaint.color = withAlpha(o.color, alpha)
        strokePaint.strokeWidth = o.width
        strokePaint.strokeCap = if (o.kind == StrokeKind.HIGHLIGHTER) Paint.Cap.SQUARE else Paint.Cap.ROUND
        if (pts.size == 1) {
            fillPaint.color = strokePaint.color
            c.drawCircle(pts[0].x, pts[0].y, o.width / 2f, fillPaint)
            return
        }
        path.reset()
        path.moveTo(pts[0].x, pts[0].y)
        for (i in 1 until pts.size - 1) {
            val mx = (pts[i].x + pts[i + 1].x) / 2f
            val my = (pts[i].y + pts[i + 1].y) / 2f
            path.quadTo(pts[i].x, pts[i].y, mx, my)
        }
        path.lineTo(pts.last().x, pts.last().y)
        c.drawPath(path, strokePaint)
    }

    private fun arrowHead(c: Canvas, tip: Pt, from: Pt, size: Float, color: Int) {
        val ang = atan2((tip.y - from.y).toDouble(), (tip.x - from.x).toDouble())
        val spread = Math.toRadians(24.0)
        val l = Pt(tip.x - size * cos(ang - spread).toFloat(), tip.y - size * sin(ang - spread).toFloat())
        val r = Pt(tip.x - size * cos(ang + spread).toFloat(), tip.y - size * sin(ang + spread).toFloat())
        path.reset()
        path.moveTo(tip.x, tip.y); path.lineTo(l.x, l.y); path.lineTo(r.x, r.y); path.close()
        fillPaint.color = color
        c.drawPath(path, fillPaint)
    }

    private fun drawShape(c: Canvas, o: ShapeObj, photos: Map<String, PhotoObj>) {
        val (a, b) = Geo.annPoints(photos, o)
        strokePaint.color = o.color
        strokePaint.strokeWidth = o.width
        strokePaint.strokeCap = Paint.Cap.ROUND
        fillPaint.color = withAlpha(o.color, 70)
        strokePaint.pathEffect = if (o.kind == ShapeKind.DASHED) DashPathEffect(floatArrayOf(o.width * 4f + 6f, o.width * 3f + 5f), 0f) else null
        val l = min(a.x, b.x); val r = max(a.x, b.x); val t = min(a.y, b.y); val bt = max(a.y, b.y)
        when (o.kind) {
            ShapeKind.LINE, ShapeKind.DASHED -> c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
            ShapeKind.ARROW -> {
                c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                arrowHead(c, b, a, max(10f, o.width * 4f), o.color)
            }
            ShapeKind.RECT -> {
                if (o.fill) c.drawRect(l, t, r, bt, fillPaint)
                c.drawRect(l, t, r, bt, strokePaint)
            }
            ShapeKind.RRECT -> {
                if (o.fill) c.drawRoundRect(l, t, r, bt, 14f, 14f, fillPaint)
                c.drawRoundRect(l, t, r, bt, 14f, 14f, strokePaint)
            }
            ShapeKind.ELLIPSE -> {
                rect.set(l, t, r, bt)
                if (o.fill) c.drawOval(rect, fillPaint)
                c.drawOval(rect, strokePaint)
            }
            ShapeKind.DARROW -> {
                c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                arrowHead(c, b, a, max(10f, o.width * 4f), o.color)
                arrowHead(c, a, b, max(10f, o.width * 4f), o.color)
            }
            ShapeKind.CURVE -> {
                val pts = Geo.curvePoints(a, b)
                path.reset(); path.moveTo(pts[0].x, pts[0].y)
                for (i in 1 until pts.size) path.lineTo(pts[i].x, pts[i].y)
                c.drawPath(path, strokePaint)
            }
            ShapeKind.ELBOW -> {
                val pts = Geo.polyPoints(o.kind, a, b)!!
                path.reset(); path.moveTo(pts[0].x, pts[0].y)
                for (i in 1 until pts.size) path.lineTo(pts[i].x, pts[i].y)
                strokePaint.strokeJoin = Paint.Join.ROUND
                c.drawPath(path, strokePaint)
            }
            ShapeKind.RTRI, ShapeKind.DIAMOND, ShapeKind.TRAP -> {
                val pts = Geo.polyPoints(o.kind, a, b)!!
                path.reset(); path.moveTo(pts[0].x, pts[0].y)
                for (i in 1 until pts.size) path.lineTo(pts[i].x, pts[i].y)
                path.close()
                strokePaint.strokeJoin = Paint.Join.ROUND
                if (o.fill) c.drawPath(path, fillPaint)
                c.drawPath(path, strokePaint)
            }
            ShapeKind.TRIANGLE -> {
                path.reset()
                path.moveTo((l + r) / 2f, t); path.lineTo(r, bt); path.lineTo(l, bt); path.close()
                if (o.fill) c.drawPath(path, fillPaint)
                c.drawPath(path, strokePaint)
            }
        }
        strokePaint.pathEffect = null
    }

    private fun drawText(c: Canvas, o: TextObj, photos: Map<String, PhotoObj>) {
        val at = Geo.annPoints(photos, o)[0]
        textPaint.color = o.color
        textPaint.textSize = o.size
        textPaint.textAlign = Paint.Align.LEFT
        textPaint.typeface = Typeface.DEFAULT
        o.text.split('\n').forEachIndexed { i, line ->
            c.drawText(line, at.x, at.y + o.size + i * o.size * 1.25f, textPaint)
        }
    }

    private fun luminance(color: Int): Float {
        val r = (color shr 16 and 0xFF) / 255f
        val g = (color shr 8 and 0xFF) / 255f
        val b = (color and 0xFF) / 255f
        return 0.299f * r + 0.587f * g + 0.114f * b
    }

    /** Mistura [color] com o fundo [bg]; t = quanto da cor (1 = cor cheia). */
    private fun mix(color: Int, bg: Int, t: Float): Int {
        fun ch(shift: Int): Int {
            val c = (color shr shift) and 0xFF
            val b = (bg shr shift) and 0xFF
            return (b + (c - b) * t).toInt().coerceIn(0, 255)
        }
        return (0xFF shl 24) or (ch(16) shl 16) or (ch(8) shl 8) or ch(0)
    }

    /** Seta de cota: linha fina, pontas pequenas; só mostra o número depois que a trena mediu. */
    private fun drawDim(c: Canvas, o: DimObj, photos: Map<String, PhotoObj>, unit: LengthUnit) {
        val (a, b) = Geo.annPoints(photos, o)
        strokePaint.color = o.color
        strokePaint.strokeWidth = o.width
        strokePaint.strokeCap = Paint.Cap.BUTT
        c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
        val head = max(8f, o.width * 3.2f)
        arrowHead(c, a, b, head, o.color)
        arrowHead(c, b, a, head, o.color)
        if (o.valueMm == null) return
        val label = Units.label(o, unit)
        val k = Geo.labelScale(o, photos)
        val box = Geo.dimLabelBox(a, b, label, k)
        rect.set(box.l, box.t, box.r, box.b)
        val tint = mix(o.color, 0xFFFFFFFF.toInt(), o.labelIntensity.coerceIn(0f, 1f))
        val alpha = o.labelAlpha.coerceIn(0f, 1f)
        fillPaint.color = withAlpha(tint, (alpha * 255).toInt())
        c.drawRoundRect(rect, 3f * k, 3f * k, fillPaint)
        // cor do texto pela luminância do que realmente aparece (cor sobre o papel branco)
        val shown = mix(tint, 0xFFFFFFFF.toInt(), alpha)
        textPaint.color = if (luminance(shown) > 0.6f) 0xFF111111.toInt() else 0xFFFFFFFF.toInt()
        textPaint.textSize = Geo.DIM_TEXT_SIZE * k
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT_BOLD
        c.drawText(label, (box.l + box.r) / 2f, (box.t + box.b) / 2f + Geo.DIM_TEXT_SIZE * k * 0.35f, textPaint)
    }

    /** Móvel: vista frontal na escala da folha, com largura e altura. */
    private fun drawCab(c: Canvas, o: CabObj) {
        if (o.wall != null) { drawCabOnWall(c, o); return }
        val k = o.unitsPerMm.toFloat()
        val parts = br.com.arque.measure.logic.CabinetMath.parts(o.cab)
        for (p in parts) {
            val l = o.at.x + p.x.toFloat() * k
            val t = o.at.y + p.y.toFloat() * k
            val rr = l + p.w.toFloat() * k
            val bb = t + p.h.toFloat() * k
            val front = p.kind == PartKind.FRENTE_GAVETA || p.kind == PartKind.PORTA
            fillPaint.color = when {
                p.kind == PartKind.RODAPE -> 0xFF8B7B5C.toInt()
                front -> 0xFFE6D9BE.toInt()
                else -> 0xFFCDB98F.toInt()
            }
            c.drawRect(l, t, rr, bb, fillPaint)
            strokePaint.color = 0xFF6F5F40.toInt()
            strokePaint.strokeWidth = 0.7f
            strokePaint.strokeCap = Paint.Cap.BUTT
            strokePaint.pathEffect = null
            c.drawRect(l, t, rr, bb, strokePaint)
            if (front) {
                strokePaint.color = 0xFF8B7B5C.toInt()
                strokePaint.strokeWidth = 1.6f
                if (p.kind == PartKind.FRENTE_GAVETA) {
                    val cx = (l + rr) / 2f
                    c.drawLine(cx - 9f, t + 6f, cx + 9f, t + 6f, strokePaint)
                } else {
                    c.drawLine(rr - 5f, t + (bb - t) * 0.4f, rr - 5f, t + (bb - t) * 0.6f, strokePaint)
                }
            }
        }
        val w = o.widthUnits()
        val h = o.heightUnits()
        textPaint.color = 0xFF333333.toInt()
        textPaint.textSize = 10f
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textAlign = Paint.Align.CENTER
        c.drawText("${o.cab.wMm.toLong()} mm", o.at.x + w / 2f, o.at.y - 6f, textPaint)
        textPaint.textAlign = Paint.Align.RIGHT
        c.drawText("${o.cab.hMm.toLong()}", o.at.x - 5f, o.at.y + h / 2f, textPaint)
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT
        c.drawText("${o.name} · 1:${o.scaleDen}", o.at.x + w / 2f, o.at.y + h + 14f, textPaint)
    }

    /** Parede do projeto: linha do topo, alturas, chão e o quanto cada fileira ocupa. */
    private fun drawWall(c: Canvas, o: br.com.arque.measure.model.WallObj, sheet: Sheet) {
        val l = o.at.x
        val t = o.at.y
        val r = l + o.widthUnits()
        val b = t + o.heightUnits()
        val k = o.upm.toFloat()
        strokePaint.pathEffect = null
        strokePaint.color = 0xFF3A4A66.toInt()
        strokePaint.strokeWidth = 2.2f
        c.drawLine(l, t, r, t, strokePaint)
        c.drawLine(l, t, l, b, strokePaint)
        c.drawLine(r, t, r, b, strokePaint)
        strokePaint.strokeWidth = 1.4f
        c.drawLine(l - 6f, b, r + 6f, b, strokePaint)
        strokePaint.pathEffect = DashPathEffect(floatArrayOf(6f, 5f), 0f)
        strokePaint.strokeWidth = 0.8f
        strokePaint.color = 0xFF8895AD.toInt()
        val yu = b - (o.upperBottomMm * k).toFloat()
        c.drawLine(l, yu, r, yu, strokePaint)
        strokePaint.pathEffect = null
        // pedra (tampo) na medida real, com recuo da parede esquerda
        if (o.stoneWMm > 0.0) {
            val lowTop = WallLayout.members(sheet, o.id, false).maxOfOrNull { WallLayout.topMm(o, it) } ?: 900.0
            val topMm = if (o.stoneTopMm > 0.0) o.stoneTopMm else lowTop
            val sx1 = l + (o.stoneXMm * k).toFloat()
            val sx2 = sx1 + (o.stoneWMm * k).toFloat()
            val sy2 = b - (topMm * k).toFloat()
            val sy1 = sy2 - maxOf((o.stoneEspMm * k).toFloat(), 3f)
            fillPaint.style = Paint.Style.FILL
            fillPaint.color = 0xFFB9B2A4.toInt()
            c.drawRect(sx1, sy1, sx2, sy2, fillPaint)
            strokePaint.color = 0xFF6F685A.toInt(); strokePaint.strokeWidth = 1f
            c.drawRect(sx1, sy1, sx2, sy2, strokePaint)
            textPaint.color = 0xFF6F685A.toInt(); textPaint.typeface = Typeface.DEFAULT_BOLD; textPaint.textSize = 9.5f; textPaint.textAlign = Paint.Align.CENTER
            c.drawText("pedra ${o.stoneWMm.toLong()}", (sx1 + sx2) / 2f, sy1 - 3f, textPaint)
            if (o.stoneXMm > 0.0) c.drawText("${o.stoneXMm.toLong()}", (l + sx1) / 2f, sy1 - 3f, textPaint)
            val rest = o.wMm - o.stoneXMm - o.stoneWMm
            if (rest > 0.5) c.drawText("${rest.toLong()}", (sx2 + r) / 2f, sy1 - 3f, textPaint)
        }
        textPaint.color = 0xFF3A4A66.toInt()
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 11f
        textPaint.textAlign = Paint.Align.CENTER
        c.drawText("${o.wMm.toLong()} mm", (l + r) / 2f, t - 6f, textPaint)
        textPaint.textAlign = Paint.Align.RIGHT
        c.drawText("${o.hMm.toLong()}", l - 5f, (t + b) / 2f, textPaint)
        // alturas reais na lateral direita: chão → pia → superior → teto
        val lowH = WallLayout.members(sheet, o.id, false).maxOfOrNull { WallLayout.topMm(o, it) }
        val upMods = WallLayout.members(sheet, o.id, true)
        val upTop = upMods.maxOfOrNull { WallLayout.topMm(o, it) }
        val upBot = upMods.minOfOrNull { WallLayout.topMm(o, it) - it.cab.hMm } ?: o.upperBottomMm
        val marks = ArrayList<Triple<Double, Double, Boolean>>() // de, até (mm do chão), alerta
        if (lowH != null) marks += Triple(0.0, lowH, false)
        if (upTop != null) {
            if (lowH != null) marks += Triple(lowH, upBot, upBot < lowH)
            marks += Triple(upBot, upTop, false)
            marks += Triple(upTop, o.hMm, upTop > o.hMm + 0.5)
        } else if (lowH != null) {
            marks += Triple(lowH, o.hMm, false)
        }
        val dx = r + 10f
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textSize = 9.5f
        textPaint.textAlign = Paint.Align.LEFT
        for ((a, bb, bad) in marks) {
            val ya = b - (a * k).toFloat()
            val yb = b - (bb * k).toFloat()
            val col = if (bad) 0xFFC0392B.toInt() else 0xFF2F80ED.toInt()
            strokePaint.color = col
            strokePaint.strokeWidth = 1f
            c.drawLine(dx, ya, dx, yb, strokePaint)
            c.drawLine(dx - 3f, ya, dx + 3f, ya, strokePaint)
            c.drawLine(dx - 3f, yb, dx + 3f, yb, strokePaint)
            val v = bb - a
            if (kotlin.math.abs(ya - yb) > 9f) {
                textPaint.color = col
                c.drawText("${v.toLong()}", dx + 5f, (ya + yb) / 2f + 3f, textPaint)
            }
        }
        // sobra em cima de cada módulo (até o superior ou o teto), na própria medida
        val upBottomAny = upMods.isNotEmpty()
        for (m in sheet.objs.filterIsInstance<br.com.arque.measure.model.CabObj>().filter { it.layout?.wallId == o.id }) {
            val topMm = WallLayout.topMm(o, m)
            val limit = if (!m.cab.superior && upBottomAny) upBot else o.hMm
            val gap = limit - topMm
            val org = m.origin()
            val cx = org.x + m.widthUnits() / 2f
            val yTop = org.y
            val yLim = b - (limit * k).toFloat()
            val bad = gap < -0.5
            val col = if (bad) 0xFFC0392B.toInt() else 0xFF2F80ED.toInt()
            if (kotlin.math.abs(yTop - yLim) > 10f || bad) {
                strokePaint.color = col; strokePaint.strokeWidth = 0.9f; strokePaint.pathEffect = null
                c.drawLine(cx, yTop, cx, yLim, strokePaint)
                c.drawLine(cx - 3f, yLim, cx + 3f, yLim, strokePaint)
                c.drawLine(cx - 3f, yTop, cx + 3f, yTop, strokePaint)
                textPaint.color = col; textPaint.typeface = Typeface.DEFAULT_BOLD; textPaint.textSize = 9.5f; textPaint.textAlign = Paint.Align.LEFT
                c.drawText(if (bad) "passa ${(-gap).toLong()}" else "${gap.toLong()}", cx + 5f, (yTop + yLim) / 2f + 3f, textPaint)
            }
        }
        // tamponamento de baixo contínuo (uma peça só juntando módulos vizinhos)
        for (upper in listOf(false, true)) {
            for (run in WallLayout.joinedRuns(sheet, o.id, upper)) {
                val f = run.first(); val la = run.last()
                val fo = f.origin()
                val x1 = fo.x - (WallLayout.padL(f) * k).toFloat()
                val x2 = la.origin().x + la.widthUnits() + (WallLayout.padR(la) * k).toFloat()
                val y1 = fo.y + f.heightUnits()
                val th = maxOf((f.cab.tampBaixoMm * k).toFloat(), 3f)
                fillPaint.style = Paint.Style.FILL
                fillPaint.color = 0xCCD9A93E.toInt()
                c.drawRect(x1, y1, x2, y1 + th, fillPaint)
                textPaint.color = 0xFF8A6A25.toInt(); textPaint.typeface = Typeface.DEFAULT_BOLD; textPaint.textSize = 9f; textPaint.textAlign = Paint.Align.CENTER
                c.drawText("tamp. contínuo ${WallLayout.runLength(run).toLong()} × ${f.cab.tampBaixoMm.toLong()}", (x1 + x2) / 2f, y1 + th + 10f, textPaint)
            }
        }
        // sobra dos dois lados de cada fileira: da parede até o primeiro módulo e do último até a parede
        for (upper in listOf(false, true)) {
            val mods = WallLayout.members(sheet, o.id, upper)
            if (mods.isEmpty()) continue
            val first = mods.first()
            val last = mods.last()
            val fo = first.origin()
            val lo = last.origin()
            val firstL = fo.x - (WallLayout.padL(first) * k).toFloat()
            val lastR = lo.x + last.widthUnits() + (WallLayout.padR(last) * k).toFloat()
            val ym = fo.y + first.heightUnits() / 2f
            val ym2 = lo.y + last.heightUnits() / 2f
            fun gap(x1: Float, x2: Float, y: Float, left: Boolean) {
                val mm = (x2 - x1) / k
                if (mm < 0.5f) return
                strokePaint.color = 0xFF2F80ED.toInt(); strokePaint.strokeWidth = 0.9f; strokePaint.pathEffect = null
                c.drawLine(x1, y, x2, y, strokePaint)
                c.drawLine(x1, y - 3f, x1, y + 3f, strokePaint)
                c.drawLine(x2, y - 3f, x2, y + 3f, strokePaint)
                textPaint.color = 0xFF2F80ED.toInt(); textPaint.typeface = Typeface.DEFAULT_BOLD; textPaint.textSize = 9.5f
                val small = (x2 - x1) < 26f
                textPaint.textAlign = if (small && left) Paint.Align.RIGHT else if (small) Paint.Align.LEFT else Paint.Align.CENTER
                val tx = if (small && left) x1 - 3f else if (small) x2 + 3f else (x1 + x2) / 2f
                c.drawText("${mm.toLong()}", tx, y - 4f, textPaint)
            }
            gap(l, firstL, ym, true)
            gap(lastR, r, ym2, false)
        }
        val lines = ArrayList<Pair<String, Boolean>>()
        if (lowH != null) {
            val topRef = upMods.takeIf { it.isNotEmpty() }?.let { upBot }
            lines += ("Pia (${lowH.toLong()}) até " + (if (topRef != null) "o superior: ${(topRef - lowH).toLong()} mm" else "o teto: ${(o.hMm - lowH).toLong()} mm")) to (topRef != null && topRef < lowH)
        }
        if (upTop != null) lines += "Superior até o teto: ${(o.hMm - upTop).toLong()} mm" to (upTop > o.hMm + 0.5)
        for (upper in listOf(false, true)) {
            val mods = WallLayout.members(sheet, o.id, upper)
            if (mods.isEmpty()) continue
            val used = mods.sumOf { WallLayout.occ(it) }
            val left = o.usableMm - used
            val topOver = upper && ((mods.maxOfOrNull { WallLayout.topMm(o, it) } ?: 0.0) > o.hMm + 0.5)
            val txt = (if (upper) "Superiores" else "Baixos") + ": ${used.toLong()} de ${o.usableMm.toLong()} mm úteis (folga ${o.folgaMm.toLong()}) · " +
                (if (left < -0.5) "passa ${(-left).toLong()} mm da parede" else "sobra ${left.toLong()} mm") +
                (if (topOver) " · passa do teto" else "")
            lines += txt to (left < -0.5 || topOver)
        }
        textPaint.typeface = Typeface.DEFAULT
        textPaint.textSize = 10f
        textPaint.textAlign = Paint.Align.LEFT
        lines.forEachIndexed { i, (txt, bad) ->
            textPaint.color = if (bad) 0xFFC0392B.toInt() else 0xFF555555.toInt()
            c.drawText(txt, l, b + 16f + i * 13f, textPaint)
        }
    }

    /** Móvel encaixado na parede: planta (vista de cima) na escala medida do cômodo. */
    private fun drawCabOnWall(c: Canvas, o: CabObj) {
        val q = o.corners()
        val bad = o.overflowsWall()
        val path = android.graphics.Path().apply {
            moveTo(q[0].x, q[0].y); lineTo(q[1].x, q[1].y); lineTo(q[2].x, q[2].y); lineTo(q[3].x, q[3].y); close()
        }
        fillPaint.style = Paint.Style.FILL
        fillPaint.color = if (bad) 0x55E74C3C else 0x66C8A96A
        c.drawPath(path, fillPaint)
        strokePaint.pathEffect = null
        strokePaint.color = if (bad) 0xFFC0392B.toInt() else 0xFF6F5F40.toInt()
        strokePaint.strokeWidth = 1.4f
        c.drawPath(path, strokePaint)
        // frente do móvel (lado de dentro do cômodo) em traço mais grosso
        strokePaint.strokeWidth = 2.6f
        c.drawLine(q[3].x, q[3].y, q[2].x, q[2].y, strokePaint)
        val cx = (q[0].x + q[2].x) / 2f
        val cy = (q[0].y + q[2].y) / 2f
        textPaint.color = if (bad) 0xFFC0392B.toInt() else 0xFF333333.toInt()
        textPaint.textSize = 9f
        textPaint.typeface = Typeface.DEFAULT_BOLD
        textPaint.textAlign = Paint.Align.CENTER
        c.drawText(o.name, cx, cy - 2f, textPaint)
        textPaint.typeface = Typeface.DEFAULT
        c.drawText(if (bad) "passa da parede!" else "${o.cab.wMm.toLong()} × ${o.cab.dMm.toLong()} mm", cx, cy + 9f, textPaint)
    }

    /** Cor de cada tipo de segmento (parede usa a cor do cômodo). */
    fun segColor(o: RoomObj, kind: SegKind): Int = roomSegColor(o, kind)

    /**
     * Contorno de cômodo. Parede: linha cheia. Painel: tracejada. Pia: faixa larga translúcida
     * com fio no centro. Cuba: pontilhada e grossa. Pendente mostra o nome do tipo; medido mostra a medida.
     */
    private fun drawRoom(c: Canvas, o: RoomObj, photos: Map<String, PhotoObj>, unit: LengthUnit) {
        val pts = Geo.annPoints(photos, o)
        if (pts.size < 2) return
        if (o.closed) {
            path.reset()
            path.moveTo(pts[0].x, pts[0].y)
            for (i in 1 until pts.size) path.lineTo(pts[i].x, pts[i].y)
            path.close()
            fillPaint.color = withAlpha(o.color, 18)
            c.drawPath(path, fillPaint)
        }
        val w = o.width
        for (k in 0 until o.segCount()) {
            val a = pts[k]
            val b = pts[(k + 1) % pts.size]
            val kind = o.segs[k].kind
            val col = segColor(o, kind)
            strokePaint.strokeCap = Paint.Cap.ROUND
            strokePaint.pathEffect = null
            when (kind) {
                SegKind.WALL -> {
                    strokePaint.color = col; strokePaint.strokeWidth = w * 1.6f
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                }
                SegKind.PANEL -> {
                    strokePaint.color = col; strokePaint.strokeWidth = w * 1.6f
                    strokePaint.strokeCap = Paint.Cap.BUTT
                    strokePaint.pathEffect = DashPathEffect(floatArrayOf(w * 6f, w * 4f), 0f)
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                    strokePaint.pathEffect = null
                }
                SegKind.SINK -> {
                    strokePaint.color = withAlpha(col, 70); strokePaint.strokeWidth = w * 6f
                    strokePaint.strokeCap = Paint.Cap.BUTT
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                    strokePaint.color = col; strokePaint.strokeWidth = w * 1.4f
                    strokePaint.strokeCap = Paint.Cap.ROUND
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                }
                SegKind.DOOR -> {
                    // vão da porta: linha fina tracejada + folha aberta (arco de 90°) para dentro do cômodo
                    strokePaint.color = col; strokePaint.strokeWidth = w * 0.9f
                    strokePaint.strokeCap = Paint.Cap.BUTT
                    strokePaint.pathEffect = DashPathEffect(floatArrayOf(w * 3f, w * 2.5f), 0f)
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                    strokePaint.pathEffect = null
                    val len = kotlin.math.hypot((b.x - a.x).toDouble(), (b.y - a.y).toDouble()).toFloat()
                    if (len > 1f) {
                        val ang = Math.toDegrees(kotlin.math.atan2((b.y - a.y).toDouble(), (b.x - a.x).toDouble())).toFloat()
                        val rad = Math.toRadians((ang + 90f).toDouble())
                        val lx = a.x + len * kotlin.math.cos(rad).toFloat()
                        val ly = a.y + len * kotlin.math.sin(rad).toFloat()
                        strokePaint.strokeWidth = w * 1.2f
                        c.drawLine(a.x, a.y, lx, ly, strokePaint)
                        strokePaint.strokeWidth = w * 0.7f
                        rect.set(a.x - len, a.y - len, a.x + len, a.y + len)
                        c.drawArc(rect, ang, 90f, false, strokePaint)
                    }
                }
                SegKind.BASIN -> {
                    strokePaint.color = col; strokePaint.strokeWidth = w * 3f
                    strokePaint.strokeCap = Paint.Cap.ROUND
                    strokePaint.pathEffect = DashPathEffect(floatArrayOf(0.1f, w * 4.5f), 0f)
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                    strokePaint.pathEffect = null
                }
            }
            drawSegLabel(c, o, k, a, b, col, unit)
        }
        strokePaint.pathEffect = null
        // vértices
        for (p in pts) {
            fillPaint.color = o.color
            c.drawCircle(p.x, p.y, w * 1.1f, fillPaint)
        }
    }

    private fun drawSegLabel(c: Canvas, o: RoomObj, k: Int, a: Pt, b: Pt, col: Int, unit: LengthUnit) {
        val seg = o.segs[k]
        val measured = seg.valueMm != null
        val label = if (measured) Units.labelSeg(seg, unit) else seg.kind.label
        val sc = o.labelScale
        val box = Geo.dimLabelBox(a, b, label, sc)
        rect.set(box.l, box.t, box.r, box.b)
        if (measured) {
            val tint = mix(col, 0xFFFFFFFF.toInt(), o.labelIntensity.coerceIn(0f, 1f))
            val alpha = o.labelAlpha.coerceIn(0f, 1f)
            fillPaint.color = withAlpha(tint, (alpha * 255).toInt())
            c.drawRoundRect(rect, 3f * sc, 3f * sc, fillPaint)
            val shown = mix(tint, 0xFFFFFFFF.toInt(), alpha)
            textPaint.color = if (luminance(shown) > 0.6f) 0xFF111111.toInt() else 0xFFFFFFFF.toInt()
        } else {
            fillPaint.color = 0xE6FFFFFF.toInt()
            c.drawRoundRect(rect, 3f * sc, 3f * sc, fillPaint)
            strokePaint.color = col; strokePaint.strokeWidth = 1.2f; strokePaint.pathEffect = null
            c.drawRoundRect(rect, 3f * sc, 3f * sc, strokePaint)
            textPaint.color = col
        }
        textPaint.textSize = Geo.DIM_TEXT_SIZE * sc
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT_BOLD
        c.drawText(label, (box.l + box.r) / 2f, (box.t + box.b) / 2f + Geo.DIM_TEXT_SIZE * sc * 0.35f, textPaint)
    }

    // ---- seleção e alças (só na tela) ----

    private fun drawSelection(c: Canvas, sheet: Sheet, o: Obj, viewScale: Float, selectedSeg: Int) {
        val photos = sheet.photos()
        val color = if (o.locked) 0xFF888888.toInt() else 0xFF2F80ED.toInt()
        val lw = 2f / viewScale
        val r = 9f / viewScale
        strokePaint.color = color
        strokePaint.strokeWidth = lw
        strokePaint.strokeCap = Paint.Cap.ROUND
        fun handle(p: Pt) {
            fillPaint.color = 0xFFFFFFFF.toInt()
            c.drawCircle(p.x, p.y, r, fillPaint)
            strokePaint.strokeWidth = lw
            c.drawCircle(p.x, p.y, r, strokePaint)
        }
        when (o) {
            is PhotoObj -> {
                val cs = Geo.corners(o)
                path.reset()
                path.moveTo(cs[0].x, cs[0].y)
                for (i in 1..3) path.lineTo(cs[i].x, cs[i].y)
                path.close()
                c.drawPath(path, strokePaint)
                if (!o.locked) {
                    val top = Geo.photoLocalToSheet(o, 0.5f, 0f)
                    val rh = Geo.rotateHandle(o, viewScale)
                    c.drawLine(top.x, top.y, rh.x, rh.y, strokePaint)
                    cs.forEach(::handle)
                    handle(rh)
                }
            }
            is DimObj, is ShapeObj -> {
                val pts = Geo.annPoints(photos, o as br.com.arque.measure.model.Ann)
                                if (!o.locked) {
                    val ring = if (o is DimObj) o.color else (o as ShapeObj).color
                    pts.forEach { p ->
                        fillPaint.color = 0xFFFFFFFF.toInt()
                        c.drawCircle(p.x, p.y, 7f / viewScale, fillPaint)
                        strokePaint.color = ring
                        strokePaint.strokeWidth = 2f / viewScale
                        c.drawCircle(p.x, p.y, 7f / viewScale, strokePaint)
                    }
                }
            }
            is RoomObj -> {
                val pts = Geo.annPoints(photos, o)
                if (selectedSeg in 0 until o.segCount()) {
                    val a = pts[selectedSeg]
                    val b = pts[(selectedSeg + 1) % pts.size]
                    strokePaint.color = 0x802F80ED.toInt()
                    strokePaint.strokeWidth = o.width + 10f / viewScale
                    strokePaint.strokeCap = Paint.Cap.ROUND
                    c.drawLine(a.x, a.y, b.x, b.y, strokePaint)
                }
                if (!o.locked) {
                    pts.forEach { p ->
                        fillPaint.color = 0xFFFFFFFF.toInt()
                        c.drawCircle(p.x, p.y, 7f / viewScale, fillPaint)
                        strokePaint.color = 0xFF2F80ED.toInt()
                        strokePaint.strokeWidth = 2f / viewScale
                        c.drawCircle(p.x, p.y, 7f / viewScale, strokePaint)
                    }
                }
            }
            is CabObj, is br.com.arque.measure.model.WallObj -> {
                if (o is CabObj && o.layout != null && !o.locked) {
                    val (hw, hh) = Geo.cabHandles(o)
                    for (p in listOf(hw, hh)) {
                        fillPaint.color = 0xFFFFFFFF.toInt()
                        c.drawCircle(p.x, p.y, r, fillPaint)
                        c.drawCircle(p.x, p.y, r, strokePaint)
                    }
                }
                val pts = Geo.annPoints(photos, o as br.com.arque.measure.model.Ann)
                val pad = 8f / viewScale
                strokePaint.pathEffect = DashPathEffect(floatArrayOf(8f / viewScale, 6f / viewScale), 0f)
                c.drawRect(pts[0].x - pad, pts[0].y - pad, pts[1].x + pad, pts[1].y + pad, strokePaint)
                strokePaint.pathEffect = null
            }
            is StrokeObj, is TextObj -> {
                val ann = o as br.com.arque.measure.model.Ann
                val pts = Geo.annPoints(photos, ann)
                val pad = 6f / viewScale
                val box = if (o is TextObj) Geo.textBox(o, pts[0]) else {
                    val w = (o as StrokeObj).width / 2f
                    br.com.arque.measure.logic.Box(
                        pts.minOf { it.x } - w, pts.minOf { it.y } - w, pts.maxOf { it.x } + w, pts.maxOf { it.y } + w,
                    )
                }
                strokePaint.pathEffect = DashPathEffect(floatArrayOf(8f / viewScale, 6f / viewScale), 0f)
                c.drawRect(box.l - pad, box.t - pad, box.r + pad, box.b + pad, strokePaint)
                strokePaint.pathEffect = null
            }
        }
    }
}
