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
            Template.ARAUJO -> {
                tplPaint.style = Paint.Style.STROKE
                tplPaint.strokeWidth = 1.5f
                tplPaint.color = 0xFF2B2B2B.toInt()
                c.drawRect(24f, 24f, w - 24f, h - 24f, tplPaint)
                c.drawLine(24f, 96f, w - 24f, 96f, tplPaint)
                tplPaint.style = Paint.Style.FILL
                tplPaint.color = 0xFF111111.toInt()
                tplPaint.typeface = Typeface.DEFAULT_BOLD
                tplPaint.textSize = 24f
                tplPaint.textAlign = Paint.Align.LEFT
                c.drawText("ARAÚJO PLANEJADOS", 40f, 62f, tplPaint)
                tplPaint.typeface = Typeface.DEFAULT
                tplPaint.textSize = 11f
                tplPaint.color = 0xFF555555.toInt()
                tplPaint.textAlign = Paint.Align.RIGHT
                c.drawText("CROQUI DE MEDIDAS", w - 40f, 50f, tplPaint)
                c.drawText("Cliente: ____________________   Data: ___/___/_____", w - 40f, 72f, tplPaint)
                tplPaint.color = 0xFF999999.toInt()
                tplPaint.textAlign = Paint.Align.CENTER
                c.drawText("medidas em metros", w / 2f, h - 32f, tplPaint)
            }
        }
    }

    fun draw(c: Canvas, sheet: Sheet, unit: LengthUnit, selectedId: String?, viewScale: Float, withPaper: Boolean = true) {
        if (withPaper) {
            c.drawRect(5f, 6f, sheet.width + 5f, sheet.height + 6f, paperShadow)
        }
        c.drawRect(0f, 0f, sheet.width, sheet.height, paperFill)
        paintTemplate(c, sheet.tpl, sheet.width, sheet.height)
        c.save()
        c.clipRect(0f, 0f, sheet.width, sheet.height)
        val photos = sheet.photos()
        for (o in sheet.objs) drawObj(c, o, photos, unit, selectedId == o.id)
        c.restore()
        if (withPaper) c.drawRect(0f, 0f, sheet.width, sheet.height, paperBorder)
        sheet.obj(selectedId)?.let { drawSelection(c, sheet, it, viewScale) }
    }

    private fun drawObj(c: Canvas, o: Obj, photos: Map<String, PhotoObj>, unit: LengthUnit, selected: Boolean) {
        when (o) {
            is PhotoObj -> drawPhoto(c, o)
            is StrokeObj -> drawStroke(c, o, photos)
            is ShapeObj -> drawShape(c, o, photos)
            is TextObj -> drawText(c, o, photos)
            is DimObj -> drawDim(c, o, photos, unit)
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
        val box = Geo.dimLabelBox(a, b, label)
        rect.set(box.l, box.t, box.r, box.b)
        fillPaint.color = o.color
        c.drawRoundRect(rect, 3f, 3f, fillPaint)
        textPaint.color = if (luminance(o.color) > 0.6f) 0xFF111111.toInt() else 0xFFFFFFFF.toInt()
        textPaint.textSize = Geo.DIM_TEXT_SIZE
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.DEFAULT_BOLD
        c.drawText(label, (box.l + box.r) / 2f, (box.t + box.b) / 2f + Geo.DIM_TEXT_SIZE * 0.35f, textPaint)
    }

    // ---- seleção e alças (só na tela) ----

    private fun drawSelection(c: Canvas, sheet: Sheet, o: Obj, viewScale: Float) {
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
