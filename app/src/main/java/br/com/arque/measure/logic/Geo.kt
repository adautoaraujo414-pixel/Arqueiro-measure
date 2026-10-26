package br.com.arque.measure.logic

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.CabObj
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
        is br.com.arque.measure.model.DoorObj -> listOf(toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b))
        is TextObj -> listOf(toSheet(photos, a.photoId, a.at))
        is RoomObj -> a.pts.map { toSheet(photos, a.photoId, it) }
        is CabObj -> a.origin().let { o -> listOf(o, Pt(o.x + a.widthUnits(), o.y + a.heightUnits())) }
        is br.com.arque.measure.model.WallObj -> listOf(a.at, Pt(a.at.x + a.widthUnits(), a.at.y + a.heightUnits()))
    }

    /** Alças de arrastar de um módulo da parede: largura (meio da lateral direita) e altura (meio do topo). */
    fun cabHandles(o: CabObj): Pair<Pt, Pt> {
        val org = o.origin()
        val w = o.widthUnits()
        val h = o.heightUnits()
        val anchored = o.layout?.anchorTop == true
        return Pt(org.x + w, org.y + h / 2f) to Pt(org.x + w / 2f, if (anchored) org.y + h else org.y)
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
            is br.com.arque.measure.model.DoorObj -> ann.copy(a = mv(ann.a), b = mv(ann.b))
            is TextObj -> ann.copy(at = mv(ann.at))
            is RoomObj -> ann.copy(pts = ann.pts.map(::mv))
            is CabObj -> ann.slide(dx, dy)
            is br.com.arque.measure.model.WallObj -> ann.copy(at = Pt(ann.at.x + dx, ann.at.y + dy))
        }
    }

    /** Move um ponto específico (extremidade) para a coordenada de folha [s]. */
    fun withEndpoint(sheet: Sheet, o: Obj, endB: Boolean, s: Pt): Obj {
        val ann = o as? Ann ?: return o
        val local = fromSheet(sheet.photos(), ann.photoId, s)
        return when (ann) {
            is ShapeObj -> if (endB) ann.copy(b = local) else ann.copy(a = local)
            is DimObj -> if (endB) ann.copy(b = local) else ann.copy(a = local)
            is br.com.arque.measure.model.DoorObj -> if (endB) ann.copy(b = local) else ann.copy(a = local)
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
            is br.com.arque.measure.model.DoorObj -> a.copy(a = conv(a.a), b = conv(a.b)).withPhotoId(newPhotoId)
            is TextObj -> a.copy(at = conv(a.at)).withPhotoId(newPhotoId)
            is RoomObj -> a.copy(pts = a.pts.map(::conv)).withPhotoId(newPhotoId)
            is CabObj -> a
            is br.com.arque.measure.model.WallObj -> a
        }
    }

    // ---- distâncias e testes de toque ----

    /** Ponto dentro do polígono (regra par-ímpar). */
    fun inPolygon(poly: List<Pt>, p: Pt): Boolean {
        var inside = false
        var j = poly.lastIndex
        for (i in poly.indices) {
            val a = poly[i]; val b = poly[j]
            if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) inside = !inside
            j = i
        }
        return inside
    }

    /** Caixa do objeto em coordenadas da folha. */
    fun bounds(sheet: Sheet, o: Obj): Box {
        if (o is PhotoObj) {
            val cs = corners(o)
            return Box(cs.minOf { it.x }, cs.minOf { it.y }, cs.maxOf { it.x }, cs.maxOf { it.y })
        }
        val ann = o as Ann
        val pts = annPoints(sheet.photos(), ann)
        if (ann is TextObj) return textBox(ann, pts[0])
        return Box(pts.minOf { it.x }, pts.minOf { it.y }, pts.maxOf { it.x }, pts.maxOf { it.y })
    }

    /** Objetos (não travados) contornados pelo laço: pelo menos 60% dos pontos dentro. */
    fun lassoPick(sheet: Sheet, poly: List<Pt>): Set<String> {
        if (poly.size < 3) return emptySet()
        val photos = sheet.photos()
        return sheet.objs.filter { !it.locked }.filter { o ->
            val pts = if (o is PhotoObj) listOf(Pt(o.cx, o.cy)) + corners(o) else annPoints(photos, o as Ann)
            pts.isNotEmpty() && pts.count { inPolygon(poly, it) } >= pts.size * 0.6
        }.map { it.id }.toSet()
    }

    /** Pontos de formas poligonais (RTRI, DIAMOND, TRAP) ou do "L" (ELBOW); null para as demais. */
    fun polyPoints(kind: br.com.arque.measure.model.ShapeKind, a: Pt, b: Pt): List<Pt>? {
        val l = min(a.x, b.x); val r = max(a.x, b.x); val t = min(a.y, b.y); val bt = max(a.y, b.y)
        val w = r - l
        return when (kind) {
            br.com.arque.measure.model.ShapeKind.RTRI -> listOf(Pt(l, t), Pt(r, bt), Pt(l, bt))
            br.com.arque.measure.model.ShapeKind.DIAMOND -> listOf(Pt((l + r) / 2f, t), Pt(r, (t + bt) / 2f), Pt((l + r) / 2f, bt), Pt(l, (t + bt) / 2f))
            br.com.arque.measure.model.ShapeKind.TRAP -> listOf(Pt(l + w * 0.2f, t), Pt(r - w * 0.2f, t), Pt(r, bt), Pt(l, bt))
            br.com.arque.measure.model.ShapeKind.ELBOW -> listOf(a, Pt(b.x, a.y), b)
            else -> null
        }
    }

    /** Curva (arco): quadrática de a a b com o ponto de controle deslocado 25% do comprimento. */
    fun curvePoints(a: Pt, b: Pt, n: Int = 24): List<Pt> {
        val mx = (a.x + b.x) / 2f; val my = (a.y + b.y) / 2f
        val dx = b.x - a.x; val dy = b.y - a.y
        val c = Pt(mx - dy * 0.25f, my + dx * 0.25f)
        return (0..n).map {
            val t = it / n.toFloat(); val u = 1f - t
            Pt(u * u * a.x + 2f * u * t * c.x + t * t * b.x, u * u * a.y + 2f * u * t * c.y + t * t * b.y)
        }
    }

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

    /**
     * Escala do quadradinho: ajuste manual × proporção automática. Se a foto (ou a seta livre)
     * diminui ou aumenta em relação ao tamanho de referência, o quadradinho acompanha.
     */
    fun labelScale(d: DimObj, photos: Map<String, PhotoObj>): Float {
        val (a, b) = annPoints(photos, d)
        val cur = d.photoId?.let { photos[it]?.w } ?: hypot(b.x - a.x, b.y - a.y)
        val auto = if (d.refSize > 1f && cur > 1f) (cur / d.refSize).coerceIn(0.1f, 4f) else 1f
        return (d.labelScale * auto).coerceIn(0.05f, 8f)
    }

    fun dimLabelBox(a: Pt, b: Pt, label: String, scale: Float = 1f): Box {
        val c = dimLabelCenter(a, b)
        val w = (label.length * DIM_TEXT_SIZE * 0.58f + 12f) * scale
        val h = (DIM_TEXT_SIZE + 8f) * scale
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
                    ShapeKind.LINE, ShapeKind.DASHED, ShapeKind.ARROW, ShapeKind.DARROW -> distToSegment(s, a, b) <= r
                    ShapeKind.CURVE -> curvePoints(a, b).zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    ShapeKind.ELBOW -> polyPoints(o.kind, a, b)!!.zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    ShapeKind.RTRI, ShapeKind.DIAMOND, ShapeKind.TRAP -> {
                        val c = polyPoints(o.kind, a, b)!!
                        (c + c.first()).zipWithNext().any { (p, q) -> distToSegment(s, p, q) <= r }
                    }
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
            is br.com.arque.measure.model.DoorObj -> {
                val (a, b) = annPoints(photos, o)
                distToSegment(s, a, b) <= tol + o.width * 1.5f ||
                    dimLabelBox(a, b, doorLabel(o, unit)).contains(s, tol / 2f)
            }
            is RoomObj -> hitSeg(sheet, o, s, tol, unit) >= 0
            is CabObj -> {
                val p = annPoints(photos, o)
                Box(p[0].x, p[0].y, p[1].x, p[1].y).contains(s, tol / 2f)
            }
            is br.com.arque.measure.model.WallObj -> {
                val p = annPoints(photos, o)
                val l = p[0].x; val t = p[0].y; val r = p[1].x; val bt = p[1].y
                distToSegment(s, Pt(l, t), Pt(r, t)) <= tol || distToSegment(s, Pt(l, t), Pt(l, bt)) <= tol ||
                    distToSegment(s, Pt(r, t), Pt(r, bt)) <= tol || distToSegment(s, Pt(l, bt), Pt(r, bt)) <= tol
            }
            is DimObj -> {
                val (a, b) = annPoints(photos, o)
                distToSegment(s, a, b) <= tol + o.width / 2f ||
                    (o.valueMm != null && dimLabelBox(a, b, Units.label(o, unit), labelScale(o, photos)).contains(s, tol / 2f))
            }
        }
    }

    /** Texto do quadradinho da porta: "Porta" ou "Porta 0,820 m". */
    fun doorLabel(d: br.com.arque.measure.model.DoorObj, unit: LengthUnit): String =
        "Porta" + (d.valueMm?.let { " " + Units.format(it, unit) } ?: "")

    /**
     * Trecho de linha mais perto de [p] (paredes de cômodo, linhas/setas e traços), para a porta ficar
     * em cima da linha. Devolve (início, fim) em coordenadas da folha, ou null se nada estiver a [tol].
     */
    fun nearestLine(sheet: Sheet, p: Pt, tol: Float, skipId: String? = null): Pair<Pt, Pt>? {
        val photos = sheet.photos()
        var best: Pair<Pt, Pt>? = null
        var bd = tol
        fun cand(a: Pt, b: Pt) {
            if (hypot(b.x - a.x, b.y - a.y) < 4f) return
            val d = distToSegment(p, a, b)
            if (d <= bd) { bd = d; best = a to b }
        }
        for (o in sheet.objs) {
            if (o.id == skipId) continue
            when (o) {
                is RoomObj -> { val q = annPoints(photos, o); for (k in 0 until o.segCount()) cand(q[k], q[(k + 1) % q.size]) }
                is ShapeObj -> {
                    val q = annPoints(photos, o)
                    when (o.kind) {
                        ShapeKind.LINE, ShapeKind.DASHED, ShapeKind.ARROW, ShapeKind.DARROW -> cand(q[0], q[1])
                        ShapeKind.RECT, ShapeKind.RRECT -> {
                            val l = min(q[0].x, q[1].x); val r = max(q[0].x, q[1].x); val t = min(q[0].y, q[1].y); val bt = max(q[0].y, q[1].y)
                            cand(Pt(l, t), Pt(r, t)); cand(Pt(r, t), Pt(r, bt)); cand(Pt(r, bt), Pt(l, bt)); cand(Pt(l, bt), Pt(l, t))
                        }
                        ShapeKind.ELBOW, ShapeKind.RTRI, ShapeKind.DIAMOND, ShapeKind.TRAP -> {
                            val c = polyPoints(o.kind, q[0], q[1])!!
                            val ring = if (o.kind == ShapeKind.ELBOW) c else c + c.first()
                            ring.zipWithNext().forEach { (a, b) -> cand(a, b) }
                        }
                        else -> {}
                    }
                }
                is StrokeObj -> annPoints(photos, o).zipWithNext().forEach { (a, b) -> cand(a, b) }
                else -> {}
            }
        }
        return best
    }

    /** Projeta [p] na reta [a]-[b], sem passar das pontas. */
    fun projectOnSegment(p: Pt, a: Pt, b: Pt): Pt {
        val dx = b.x - a.x; val dy = b.y - a.y
        val l2 = dx * dx + dy * dy
        if (l2 < 1e-6f) return a
        val t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / l2).coerceIn(0f, 1f)
        return Pt(a.x + dx * t, a.y + dy * t)
    }

    /** Extremidades do segmento [k] do cômodo, em coordenadas da folha. */
    fun segEnds(photos: Map<String, PhotoObj>, o: RoomObj, k: Int): Pair<Pt, Pt> {
        val pts = annPoints(photos, o)
        return pts[k] to pts[(k + 1) % pts.size]
    }

    fun segLabelBox(photos: Map<String, PhotoObj>, o: RoomObj, k: Int, unit: LengthUnit): Box {
        val (a, b) = segEnds(photos, o, k)
        return dimLabelBox(a, b, Units.labelSeg(o.segs[k], unit), o.labelScale)
    }

    /** Segmento do cômodo sob o ponto (linha ou quadradinho), ou -1. O mais próximo ganha. */
    fun hitSeg(sheet: Sheet, o: RoomObj, s: Pt, tol: Float, unit: LengthUnit): Int {
        val photos = sheet.photos()
        var best = -1
        var bestD = Float.MAX_VALUE
        for (k in 0 until o.segCount()) {
            val (a, b) = segEnds(photos, o, k)
            var d = distToSegment(s, a, b) - o.width / 2f
            if (o.segs[k].valueMm != null && segLabelBox(photos, o, k, unit).contains(s, tol / 2f)) d = -1f
            if (d <= tol && d < bestD) { bestD = d; best = k }
        }
        return best
    }

    /** Id do objeto mais acima sob o ponto, ou null. */
    fun hit(sheet: Sheet, s: Pt, tol: Float, unit: LengthUnit): String? =
        sheet.objs.asReversed().firstOrNull { hitObj(sheet, it, s, tol, unit) }?.id

    fun inDimLabel(sheet: Sheet, d: DimObj, s: Pt, unit: LengthUnit, pad: Float = 6f): Boolean {
        if (d.valueMm == null) return false
        val (a, b) = annPoints(sheet.photos(), d)
        return dimLabelBox(a, b, Units.label(d, unit), labelScale(d, sheet.photos())).contains(s, pad)
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
