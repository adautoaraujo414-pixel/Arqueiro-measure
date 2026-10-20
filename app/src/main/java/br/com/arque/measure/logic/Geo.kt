package br.com.arque.measure.logic

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import br.com.arque.measure.model.withPhotoId
import kotlin.math.PI
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

data class Box(val l: Float, val t: Float, val r: Float, val b: Float) {
    fun contains(p: Pt, pad: Float = 0f) =
        p.x >= l - pad && p.x <= r + pad && p.y >= t - pad && p.y <= b + pad
}

/** Geometria pura (sem Android) para foto livre, anotações vinculadas e testes de toque. */
object Geo {
    const val DIM_TEXT_SIZE = 14f
    const val MIN_PHOTO_SIDE = 40f

    private fun rad(deg: Float): Double = deg * PI / 180.0

    // ---- fotos ----

    /** Ponto normalizado (u,v) da foto -> coordenada da folha. */
    fun photoLocalToSheet(p: PhotoObj, u: Float, v: Float): Pt {
        val lx = (u - 0.5f) * p.w
        val ly = (v - 0.5f) * p.h
        val c = cos(rad(p.rot)).toFloat()
        val s = sin(rad(p.rot)).toFloat()
        return Pt(p.cx + lx * c - ly * s, p.cy + lx * s + ly * c)
    }

    /** Coordenada da folha -> ponto normalizado da foto. */
    fun photoSheetToLocal(p: PhotoObj, s: Pt): Pt {
        val dx = s.x - p.cx
        val dy = s.y - p.cy
        val c = cos(rad(p.rot)).toFloat()
        val sn = sin(rad(p.rot)).toFloat()
        val lx = dx * c + dy * sn
        val ly = -dx * sn + dy * c
        return Pt(lx / p.w + 0.5f, ly / p.h + 0.5f)
    }

    fun photoContains(p: PhotoObj, s: Pt): Boolean {
        val l = photoSheetToLocal(p, s)
        return l.x in 0f..1f && l.y in 0f..1f
    }

    /** Cantos em ordem TL, TR, BR, BL, em coordenadas da folha. */
    fun corners(p: PhotoObj): List<Pt> = listOf(
        photoLocalToSheet(p, 0f, 0f),
        photoLocalToSheet(p, 1f, 0f),
        photoLocalToSheet(p, 1f, 1f),
        photoLocalToSheet(p, 0f, 1f),
    )

    /** Posição da alça de rotação: acima do centro da borda superior. */
    fun rotateHandle(p: PhotoObj, viewScale: Float, distPx: Float = 44f): Pt {
        val top = photoLocalToSheet(p, 0.5f, 0f)
        val d = distPx / viewScale
        return Pt(top.x + sin(rad(p.rot)).toFloat() * d, top.y - cos(rad(p.rot)).toFloat() * d)
    }

    fun photoAt(sheet: Sheet, s: Pt): PhotoObj? =
        sheet.objs.asReversed().firstOrNull { it is PhotoObj && photoContains(it, s) } as PhotoObj?

    // ---- vínculo foto <-> anotação ----

    fun toSheet(photos: Map<String, PhotoObj>, photoId: String?, p: Pt): Pt {
        if (photoId == null) return p
        val ph = photos[photoId] ?: return p
        return photoLocalToSheet(ph, p.x, p.y)
    }

    fun fromSheet(photos: Map<String, PhotoObj>, photoId: String?, s: Pt): Pt {
        if (photoId == null) return s
        val ph = photos[photoId] ?: return s
        return photoSheetToLocal(ph, s)
    }

    /** Pontos da anotação em coordenadas da folha. */
    fun annPoints(photos: Map<String, PhotoObj>, a: Ann): List<Pt> = when (a) {
        is StrokeObj -> a.pts.map { toSheet(photos, a.photoId, it) }
        is ShapeObj -> listOf(toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b))
        is DimObj -> listOf(toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b))
        is TextObj -> listOf(toSheet(photos, a.photoId, a.at))
    }

    /** Move o objeto por (dx,dy) em unidades de folha. */
    fun translate(sheet: Sheet, o: Obj, dx: Float, dy: Float): Obj {
        if (o is PhotoObj) return o.copy(cx = o.cx + dx, cy = o.cy + dy)
        val photos = sheet.photos()
        val ann = o as Ann
        fun mv(p: Pt): Pt {
            val s = toSheet(photos, ann.photoId, p)
            return fromSheet(photos, ann.photoId, Pt(s.x + dx, s.y + dy))
        }
        return when (ann) {
            is StrokeObj -> ann.copy(pts = ann.pts.map(::mv))
            is ShapeObj -> ann.copy(a = mv(ann.a), b = mv(ann.b))
            is DimObj -> ann.copy(a = mv(ann.a), b = mv(ann.b))
            is TextObj -> ann.copy(at = mv(ann.at))
        }
    }

    /** Move um ponto específico (extremidade) para a coordenada de folha [s]. */
    fun withEndpoint(sheet: Sheet, o: Obj, endB: Boolean, s: Pt): Obj {
        val ann = o as? Ann ?: return o
        val local = fromSheet(sheet.photos(), ann.photoId, s)
        return when (ann) {
            is ShapeObj -> if (endB) ann.copy(b = local) else ann.copy(a = local)
            is DimObj -> if (endB) ann.copy(b = local) else ann.copy(a = local)
            else -> o
        }
    }

    /** Re-vincula (ou desvincula) mantendo a posição visual. */
    fun relink(sheet: Sheet, a: Ann, newPhotoId: String?): Ann {
        val photos = sheet.photos()
        fun conv(p: Pt) = fromSheet(photos, newPhotoId, toSheet(photos, a.photoId, p))
        return when (a) {
            is StrokeObj -> a.copy(pts = a.pts.map(::conv)).withPhotoId(newPhotoId)
            is ShapeObj -> a.copy(a = conv(a.a), b = conv(a.b)).withPhotoId(newPhotoId)
            is DimObj -> a.copy(a = conv(a.a), b = conv(a.b)).withPhotoId(newPhotoId)
            is TextObj -> a.copy(at = conv(a.at)).withPhotoId(newPhotoId)
        }
    }

    // ---- distâncias e testes de toque ----

    fun distToSegment(p: Pt, a: Pt, b: Pt): Float {
        val dx = b.x - a.x
        val dy = b.y - a.y
        val len2 = dx * dx + dy * dy
        if (len2 < 1e-6f) return hypot(p.x - a.x, p.y - a.y)
        val t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / len2).coerceIn(0f, 1f)
        return hypot(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }

    fun textBox(t: TextObj, at: Pt): Box {
        val lines = t.text.split('\n')
        val w = (lines.maxOfOrNull { it.length } ?: 1).coerceAtLeast(1) * t.size * 0.55f
        val h = lines.size * t.size * 1.25f
        return Box(at.x, at.y, at.x + w, at.y + h)
    }

    fun dimLabelCenter(a: Pt, b: Pt): Pt = Pt((a.x + b.x) / 2f, (a.y + b.y) / 2f)

    fun dimLabelBox(a: Pt, b: Pt, label: String): Box {
        val c = dimLabelCenter(a, b)
        val w = label.length * DIM_TEXT_SIZE * 0.58f + 12f
        val h = DIM_TEXT_SIZE + 8f
        return Box(c.x - w / 2, c.y - h / 2, c.x + w / 2, c.y + h / 2)
    }

    fun hitObj(sheet: Sheet, o: Obj, s: Pt, tol: Float, unit: LengthUnit): Boolean {
        val photos = sheet.photos()
        return when (o) {
            is PhotoObj -> photoContains(o, s)
            is StrokeObj -> {
                val pts = annPoints(photos, o)
                val r = tol + o.width / 2f
                if (pts.size == 1) hypot(s.x - pts[0].x, s.y - pts[0].y) <= r
                else pts.zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
            }
            is ShapeObj -> {
                val (a, b) = annPoints(photos, o)
                val r = tol + o.width / 2f
                when (o.kind) {
                    ShapeKind.LINE, ShapeKind.DASHED, ShapeKind.ARROW -> distToSegment(s, a, b) <= r
                    ShapeKind.TRIANGLE -> {
                        val l = min(a.x, b.x); val rr = max(a.x, b.x)
                        val t = min(a.y, b.y); val bb = max(a.y, b.y)
                        val c = listOf(Pt((l + rr) / 2f, t), Pt(rr, bb), Pt(l, bb))
                        (c + c.first()).zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    }
                    ShapeKind.RECT, ShapeKind.RRECT -> {
                        val l = min(a.x, b.x); val rr = max(a.x, b.x)
                        val t = min(a.y, b.y); val bb = max(a.y, b.y)
                        val c = listOf(Pt(l, t), Pt(rr, t), Pt(rr, bb), Pt(l, bb))
                        (c + c.first()).zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    }
                    ShapeKind.ELLIPSE -> {
                        val cx = (a.x + b.x) / 2f; val cy = (a.y + b.y) / 2f
                        val rx = abs(b.x - a.x) / 2f; val ry = abs(b.y - a.y) / 2f
                        val poly = (0..48).map {
                            val t = it / 48.0 * 2 * PI
                            Pt(cx + rx * cos(t).toFloat(), cy + ry * sin(t).toFloat())
                        }
                        poly.zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    }
                }
            }
            is TextObj -> textBox(o, annPoints(photos, o)[0]).contains(s, tol)
            is DimObj -> {
                val (a, b) = annPoints(photos, o)
                distToSegment(s, a, b) <= tol + o.width / 2f ||
                    (o.valueMm != null && dimLabelBox(a, b, Units.label(o, unit)).contains(s, tol / 2f))
            }
        }
    }

    /** Id do objeto mais acima sob o ponto, ou null. */
    fun hit(sheet: Sheet, s: Pt, tol: Float, unit: LengthUnit): String? =
        sheet.objs.asReversed().firstOrNull { hitObj(sheet, it, s, tol, unit) }?.id

    fun inDimLabel(sheet: Sheet, d: DimObj, s: Pt, unit: LengthUnit, pad: Float = 6f): Boolean {
        if (d.valueMm == null) return false
        val (a, b) = annPoints(sheet.photos(), d)
        return dimLabelBox(a, b, Units.label(d, unit)).contains(s, pad)
    }

    /** Alinha [p] na horizontal/vertical em relação a [anchor] se estiver a menos de [tolDeg] graus. */
    fun snapAxis(anchor: Pt, p: Pt, tolDeg: Float = 3f): Pt {
        val dx = p.x - anchor.x
        val dy = p.y - anchor.y
        if (hypot(dx, dy) < 1f) return p
        val ang = Math.toDegrees(atan2(abs(dy), abs(dx)).toDouble())
        return when {
            ang < tolDeg -> Pt(p.x, anchor.y)
            ang > 90 - tolDeg -> Pt(anchor.x, p.y)
            else -> p
        }
    }

    /**
     * Redimensiona a foto arrastando o canto [idx] (0=TL,1=TR,2=BR,3=BL) até [p] (folha),
     * mantendo proporção e o canto oposto fixo.
     */
    fun resizeFromCorner(o: PhotoObj, idx: Int, p: Pt, maxSide: Float): PhotoObj {
        val cu = floatArrayOf(0f, 1f, 1f, 0f)
        val cv = floatArrayOf(0f, 0f, 1f, 1f)
        val ax = cu[(idx + 2) % 4]; val ay = cv[(idx + 2) % 4]
        val anchor = photoLocalToSheet(o, ax, ay)
        val dxL = (cu[idx] - ax) * o.w
        val dyL = (cv[idx] - ay) * o.h
        val vx = p.x - anchor.x
        val vy = p.y - anchor.y
        val c = cos(rad(o.rot)).toFloat(); val sn = sin(rad(o.rot)).toFloat()
        val vlx = vx * c + vy * sn
        val vly = -vx * sn + vy * c
        var s = (vlx * dxL + vly * dyL) / (dxL * dxL + dyL * dyL)
        val minS = MIN_PHOTO_SIDE / min(o.w, o.h)
        val maxS = maxSide / max(o.w, o.h)
        s = s.coerceIn(minS, maxS)
        val nw = o.w * s; val nh = o.h * s
        val ox = (ax - 0.5f) * nw; val oy = (ay - 0.5f) * nh
        val ncx = anchor.x - (ox * c - oy * sn)
        val ncy = anchor.y - (ox * sn + oy * c)
        return o.copy(cx = ncx, cy = ncy, w = nw, h = nh)
    }
}
