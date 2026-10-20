package br.com.arque.measure.ui

import androidx.compose.ui.geometry.Offset
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeKind
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sin

sealed interface GestureAction {
    /** Toque numa cota: se houver leitura da trena esperando, ela é atribuída. */
    data class TapDim(val id: String) : GestureAction
    data class EditText(val id: String?, val at: Pt) : GestureAction
}

/**
 * Interpreta toque, arraste e pinça sobre a folha.
 *
 * Regra de ouro: a pinça redimensiona a FOTO selecionada (nunca a folha). Sem foto selecionada,
 * a pinça só dá zoom na visualização. A folha mantém sempre o tamanho do papel.
 */
class GestureController(private val s: EditorSession, private val density: Float) {
    private enum class Mode { NONE, PAN, MOVE, HANDLE, STROKE, SHAPE, ERASE }
    private enum class H { CORNER, ROTATE, A, B }

    private var mode = Mode.NONE
    private var handle = H.A
    private var handleIdx = 0
    private var activeId: String? = null
    private var createdId: String? = null
    private var tapDimId: String? = null
    private var tapTextId: String? = null
    private var downScreen = Offset.Zero
    private var lastScreen = Offset.Zero
    private var lastSheet = Pt(0f, 0f)
    private var moved = false

    // pinça
    private var prevC = Offset.Zero
    private var prevSpan = 1f
    private var prevAng = 0f
    private var accAng = 0f
    private var rotating = false
    private var pinchPhotoId: String? = null

    private val st get() = s.state
    private val slop get() = 8f * density
    private fun tol() = 22f * density / s.view.scale
    private val straightKinds = setOf(ShapeKind.LINE, ShapeKind.DASHED, ShapeKind.ARROW)

    private fun replace(o: Obj): Sheet = st.sheet.copy(objs = st.sheet.objs.map { if (it.id == o.id) o else it })

    // ---- um dedo ----

    fun down(screen: Offset, isTouch: Boolean) {
        downScreen = screen
        lastScreen = screen
        s.pickPage(screen)
        s.loupe = null
        val p = s.view.toSheet(screen)
        lastSheet = p
        moved = false
        mode = Mode.NONE
        activeId = null
        createdId = null
        tapDimId = null
        tapTextId = null
        val tool = s.tool
        if (isTouch && s.stylusOnly && tool.drawing) {
            mode = Mode.PAN // proteção contra palma: dedo só navega
            return
        }
        when (tool) {
            Tool.NAVIGATE -> mode = Mode.PAN
            Tool.SELECT, Tool.DIM -> downSelectOrDim(screen, p, tool)
            Tool.PEN, Tool.PENCIL, Tool.HIGHLIGHTER -> startStroke(p, tool)
            Tool.ERASER -> {
                mode = Mode.ERASE
                st.beginGesture()
                erase(p)
            }
            Tool.LINE, Tool.DASHED, Tool.ARROW, Tool.RECT, Tool.RRECT, Tool.ELLIPSE, Tool.TRIANGLE -> startShape(p, tool)
            Tool.TEXT -> mode = Mode.NONE
        }
    }

    private fun downSelectOrDim(screen: Offset, p: Pt, tool: Tool) {
        val sel = st.selected
        if (sel != null && !sel.locked) {
            val h = hitHandle(screen, sel)
            if (h != null) {
                handle = h.first
                handleIdx = h.second
                activeId = sel.id
                mode = Mode.HANDLE
                st.beginGesture()
                return
            }
        }
        val prevSelected = st.selectedId
        val hit = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit))
        if (hit != null && (tool == Tool.SELECT || hit is DimObj)) {
            if (hit is TextObj && prevSelected == hit.id) tapTextId = hit.id
            if (hit is DimObj) tapDimId = hit.id
            st.select(hit.id)
            activeId = hit.id
            if (!hit.locked) {
                mode = Mode.MOVE
                st.beginGesture()
            }
            return
        }
        if (tool == Tool.SELECT) {
            st.select(null)
            mode = Mode.PAN
        } else {
            startShapeLike(p, dim = true, kind = null)
        }
    }

    private fun startStroke(p: Pt, tool: Tool) {
        val photos = st.sheet.photos()
        val photoId = Geo.photoAt(st.sheet, p)?.id
        val kind = when (tool) {
            Tool.PENCIL -> StrokeKind.PENCIL
            Tool.HIGHLIGHTER -> StrokeKind.HIGHLIGHTER
            else -> StrokeKind.PEN
        }
        val width = when (kind) {
            StrokeKind.PEN -> s.width
            StrokeKind.PENCIL -> max(1.2f, s.width * 0.6f)
            StrokeKind.HIGHLIGHTER -> s.width * 6f
        }
        val color = if (kind == StrokeKind.HIGHLIGHTER && s.color == PALETTE[0]) 0xFFFFEB3B.toInt() else s.color
        val o = StrokeObj(photoId = photoId, pts = listOf(Geo.fromSheet(photos, photoId, p)), color = color, width = width, kind = kind)
        st.live(st.sheet.copy(objs = st.sheet.objs + o))
        createdId = o.id
        mode = Mode.STROKE
    }

    private fun startShape(p: Pt, tool: Tool) {
        val kind = when (tool) {
            Tool.ARROW -> ShapeKind.ARROW
            Tool.DASHED -> ShapeKind.DASHED
            Tool.RECT -> ShapeKind.RECT
            Tool.RRECT -> ShapeKind.RRECT
            Tool.ELLIPSE -> ShapeKind.ELLIPSE
            Tool.TRIANGLE -> ShapeKind.TRIANGLE
            else -> ShapeKind.LINE
        }
        startShapeLike(p, dim = false, kind = kind)
    }

    private fun startShapeLike(p: Pt, dim: Boolean, kind: ShapeKind?) {
        val photos = st.sheet.photos()
        val photoId = Geo.photoAt(st.sheet, p)?.id
        val local = Geo.fromSheet(photos, photoId, p)
        val o: Obj = if (dim) {
            DimObj(photoId = photoId, a = local, b = local, color = s.color, width = s.width)
        } else {
            ShapeObj(photoId = photoId, kind = kind!!, a = local, b = local, color = s.color, width = s.width, fill = s.fill)
        }
        st.live(st.sheet.copy(objs = st.sheet.objs + o))
        createdId = o.id
        mode = Mode.SHAPE
    }

    fun move(screen: Offset) {
        val p = s.view.toSheet(screen)
        if (!moved && (screen - downScreen).getDistance() > slop) moved = true
        when (mode) {
            Mode.PAN -> s.panBy(screen.x - lastScreen.x, screen.y - lastScreen.y)
            Mode.MOVE -> if (moved) {
                val o = st.sheet.obj(activeId)
                if (o != null) {
                    var n = Geo.translate(st.sheet, o, p.x - lastSheet.x, p.y - lastSheet.y)
                    if (n is PhotoObj) {
                        n = n.copy(cx = n.cx.coerceIn(0f, st.sheet.width), cy = n.cy.coerceIn(0f, st.sheet.height))
                    }
                    st.live(replace(n))
                }
            } else return
            Mode.HANDLE -> applyHandle(p)
            Mode.STROKE -> {
                val o = st.sheet.obj(createdId) as? StrokeObj
                if (o != null) {
                    val photos = st.sheet.photos()
                    val last = Geo.toSheet(photos, o.photoId, o.pts.last())
                    if (hypot(p.x - last.x, p.y - last.y) >= 0.8f) {
                        st.live(replace(o.copy(pts = o.pts + Geo.fromSheet(photos, o.photoId, p))))
                    }
                }
            }
            Mode.SHAPE -> {
                val o = st.sheet.obj(createdId)
                if (o is Ann) {
                    val anchor = Geo.annPoints(st.sheet.photos(), o)[0]
                    val straight = o is DimObj || (o is ShapeObj && o.kind in straightKinds)
                    val target = if (straight) Geo.snapAxis(anchor, p) else p
                    st.live(replace(Geo.withEndpoint(st.sheet, o, true, target)))
                    if (o is DimObj || (o is ShapeObj && o.kind == ShapeKind.ARROW)) s.loupe = screen
                }
            }
            Mode.ERASE -> erase(p)
            Mode.NONE -> {}
        }
        lastScreen = screen
        lastSheet = p
    }

    private fun erase(p: Pt) {
        val sh = st.sheet
        val r = 12f * density / s.view.scale
        val gone = sh.objs.filter { it is Ann && it !is DimObj && !it.locked && Geo.hitObj(sh, it, p, r, st.unit) }.map { it.id }.toSet()
        if (gone.isNotEmpty()) st.live(sh.copy(objs = sh.objs.filter { it.id !in gone }))
    }

    /** Fim do gesto de um dedo. Retorna uma ação de UI (editar número da cota, editar texto) se foi um toque. */
    fun up(screen: Offset): GestureAction? {
        val p = s.view.toSheet(screen)
        when (mode) {
            Mode.PAN -> { s.settle() }
            Mode.SHAPE -> if (!moved) {
                st.cancelGesture()
            } else {
                st.endGesture()
                createdId?.let { if (st.sheet.obj(it) != null) st.select(it) }
            }
            Mode.STROKE, Mode.MOVE, Mode.HANDLE, Mode.ERASE -> st.endGesture()
            else -> {}
        }
        s.loupe = null
        var action: GestureAction? = null
        if (!moved) {
            val tool = s.tool
            when {
                (tool == Tool.SELECT || tool == Tool.DIM) && tapDimId != null -> {
                    val d = st.sheet.obj(tapDimId) as? DimObj
                    if (d != null && !d.locked) action = GestureAction.TapDim(d.id)
                }
                tool == Tool.SELECT && tapTextId != null -> {
                    action = GestureAction.EditText(tapTextId, p)
                }
                tool == Tool.TEXT -> {
                    val t = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit)) as? TextObj
                    action = if (t != null) GestureAction.EditText(t.id, p) else GestureAction.EditText(null, p)
                }
            }
        }
        mode = Mode.NONE
        return action
    }

    /** Um segundo dedo apareceu: descarta desenho em andamento, mantém movimento de foto. */
    fun cancelSingle() {
        s.loupe = null
        if (mode == Mode.STROKE || mode == Mode.SHAPE || mode == Mode.ERASE) st.cancelGesture()
        mode = Mode.NONE
    }

    // ---- alças ----

    private fun hitHandle(screen: Offset, o: Obj): Pair<H, Int>? {
        val r = 26f * density
        fun near(p: Pt): Boolean {
            val sp = s.view.toScreen(p)
            return hypot(sp.x - screen.x, sp.y - screen.y) <= r
        }
        val photos = st.sheet.photos()
        return when (o) {
            is PhotoObj -> {
                if (near(Geo.rotateHandle(o, s.view.scale))) return H.ROTATE to 0
                Geo.corners(o).forEachIndexed { i, c -> if (near(c)) return H.CORNER to i }
                null
            }
            is DimObj, is ShapeObj -> {
                val pts = Geo.annPoints(photos, o as Ann)
                if (near(pts[1])) H.B to 0 else if (near(pts[0])) H.A to 0 else null
            }
            else -> null
        }
    }

    private fun normalizeDeg(d: Float): Float {
        var r = d % 360f
        if (r < 0f) r += 360f
        val snap = (r / 90f).roundToInt() * 90f
        return if (abs(r - snap) < 3f) snap % 360f else r
    }

    private fun applyHandle(p: Pt) {
        val o = st.sheet.obj(activeId) ?: return
        when (o) {
            is PhotoObj -> {
                if (handle == H.ROTATE) {
                    val deg = Math.toDegrees(atan2((p.y - o.cy).toDouble(), (p.x - o.cx).toDouble())).toFloat() + 90f
                    st.live(replace(o.copy(rot = normalizeDeg(deg))))
                } else {
                    val maxSide = max(st.sheet.width, st.sheet.height) * 3f
                    st.live(replace(Geo.resizeFromCorner(o, handleIdx, p, maxSide)))
                }
            }
            is DimObj, is ShapeObj -> {
                val pts = Geo.annPoints(st.sheet.photos(), o as Ann)
                val other = if (handle == H.B) pts[0] else pts[1]
                val straight = o is DimObj || (o is ShapeObj && o.kind in straightKinds)
                val target = if (straight) Geo.snapAxis(other, p) else p
                st.live(replace(Geo.withEndpoint(st.sheet, o, handle == H.B, target)))
                s.loupe = s.view.toScreen(target)
            }
            else -> {}
        }
    }

    // ---- dois dedos ----

    private fun mid(a: Offset, b: Offset) = Offset((a.x + b.x) / 2f, (a.y + b.y) / 2f)
    private fun dist(a: Offset, b: Offset) = max(1f, hypot(b.x - a.x, b.y - a.y))
    private fun ang(a: Offset, b: Offset) = Math.toDegrees(atan2((b.y - a.y).toDouble(), (b.x - a.x).toDouble())).toFloat()

    fun pinchBegin(a: Offset, b: Offset) {
        prevC = mid(a, b)
        prevSpan = dist(a, b)
        prevAng = ang(a, b)
        accAng = 0f
        rotating = false
        val sel = st.selected
        pinchPhotoId = if (sel is PhotoObj && !sel.locked) sel.id else null
        if (pinchPhotoId != null) st.beginGesture()
    }

    fun pinch(a: Offset, b: Offset) {
        val c = mid(a, b)
        val span = dist(a, b)
        val zoom = span / prevSpan
        var dAng = ang(a, b) - prevAng
        while (dAng > 180f) dAng -= 360f
        while (dAng < -180f) dAng += 360f
        if (abs(dAng) > 90f) dAng = 0f

        val pid = pinchPhotoId
        val ph = if (pid != null) st.sheet.obj(pid) as? PhotoObj else null
        if (ph != null) {
            // Pinça sobre foto selecionada: muda a FOTO (posição, tamanho, giro). A folha não muda.
            accAng += dAng
            val applyAng = when {
                rotating -> dAng
                abs(accAng) > 8f -> { rotating = true; 0f }
                else -> 0f
            }
            val sh = st.sheet
            val kMin = Geo.MIN_PHOTO_SIDE / min(ph.w, ph.h)
            val kMax = max(sh.width, sh.height) * 3f / max(ph.w, ph.h)
            val k = zoom.coerceIn(0.5f, 2f).coerceIn(kMin, max(kMin, kMax))
            val pc0 = s.view.toSheet(prevC)
            val pc1 = s.view.toSheet(c)
            val th = Math.toRadians(applyAng.toDouble())
            val cs = cos(th).toFloat()
            val sn = sin(th).toFloat()
            val vx = ph.cx - pc0.x
            val vy = ph.cy - pc0.y
            val nx = (pc1.x + k * (vx * cs - vy * sn)).coerceIn(0f, sh.width)
            val ny = (pc1.y + k * (vx * sn + vy * cs)).coerceIn(0f, sh.height)
            st.live(replace(ph.copy(cx = nx, cy = ny, w = ph.w * k, h = ph.h * k, rot = ph.rot + applyAng)))
        } else {
            // Sem foto selecionada: zoom/pan da visualização.
            s.view.ox += c.x - prevC.x
            s.view.oy += c.y - prevC.y
            s.zoomAround(zoom, c.x, c.y)
        }
        prevC = c
        prevSpan = span
        prevAng = ang(a, b)
    }

    fun pinchEnd() {
        val pid = pinchPhotoId
        if (pid != null) {
            val ph = st.sheet.obj(pid) as? PhotoObj
            if (ph != null) st.live(replace(ph.copy(rot = normalizeDeg(ph.rot))))
            st.endGesture()
        }
        pinchPhotoId = null
        mode = Mode.NONE
    }
}
