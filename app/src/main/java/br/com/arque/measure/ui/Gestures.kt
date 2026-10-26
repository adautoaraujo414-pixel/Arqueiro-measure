package br.com.arque.measure.ui

import androidx.compose.ui.geometry.Offset
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.Seg
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
    /** Toque num segmento de cômodo: se houver leitura esperando, ela é atribuída. */
    data class TapSeg(val id: String, val seg: Int) : GestureAction
    data class EditText(val id: String?, val at: Pt) : GestureAction
}

/**
 * Interpreta toque, arraste e pinça sobre a folha.
 *
 * Regra de ouro: a pinça redimensiona a FOTO selecionada (nunca a folha). Sem foto selecionada,
 * a pinça só dá zoom na visualização. A folha mantém sempre o tamanho do papel.
 */
class GestureController(private val s: EditorSession, private val density: Float) {
    private enum class Mode { NONE, PAN, MOVE, HANDLE, STROKE, SHAPE, ERASE, ERASE_LASSO, ROOM, LASSO, GROUP }
    private enum class H { CORNER, ROTATE, A, B, VERTEX, CAB_W, CAB_H }

    private var mode = Mode.NONE
    private var handle = H.A
    private var handleIdx = 0
    private var activeId: String? = null
    private var createdId: String? = null
    private var tapDimId: String? = null
    private var tapRoomId: String? = null
    private var tapSegIdx = -1
    private var tapTextId: String? = null
    private var downScreen = Offset.Zero
    private var lastScreen = Offset.Zero
    private var lastSheet = Pt(0f, 0f)
    private var moved = false
    // escrita livre: segurar parado no fim do traço vira reta (estilo Star Note), pontas encaixam em pontos próximos
    private var strokeStraight = false
    private var lastSigT = 0L
    private var lastSigScreen = Offset.Zero

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
    private val straightKinds = setOf(ShapeKind.LINE, ShapeKind.DASHED, ShapeKind.ARROW, ShapeKind.DARROW)

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
        tapRoomId = null
        tapSegIdx = -1
        tapTextId = null
        val tool = s.tool
        if (isTouch && s.stylusOnly && tool.drawing) {
            mode = Mode.PAN // proteção contra palma: dedo só navega
            return
        }
        when (tool) {
            Tool.NAVIGATE -> mode = Mode.PAN
            Tool.SELECT, Tool.DIM, Tool.DOOR -> downSelectOrDim(screen, p, tool)
            Tool.ROOM -> downRoom(screen, p)
            Tool.LASSO -> downLasso(p)
            Tool.PEN, Tool.PENCIL, Tool.HIGHLIGHTER -> startStroke(p, tool)
            Tool.ERASER -> if (s.eraserMode == EraserMode.LASSO) {
                s.lasso = listOf(p)
                mode = Mode.ERASE_LASSO
            } else {
                mode = Mode.ERASE
                st.beginGesture()
                lastErase = null
                erase(p)
            }
            Tool.LINE, Tool.DASHED, Tool.ARROW, Tool.RECT, Tool.RRECT, Tool.ELLIPSE, Tool.TRIANGLE,
            Tool.DARROW, Tool.CURVE, Tool.ELBOW, Tool.RTRI, Tool.DIAMOND, Tool.TRAP -> startShape(p, tool)
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
        if (hit != null && (tool == Tool.SELECT || (tool == Tool.DIM && hit is DimObj) || (tool == Tool.DOOR && hit is br.com.arque.measure.model.DoorObj))) {
            if (hit is TextObj && prevSelected == hit.id) tapTextId = hit.id
            if (hit is DimObj) tapDimId = hit.id
            st.select(hit.id)
            if (hit is RoomObj) {
                val k = Geo.hitSeg(st.sheet, hit, p, tol(), st.unit)
                if (k >= 0) { st.selectSeg(hit.id, k); tapRoomId = hit.id; tapSegIdx = k }
            }
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
        } else if (tool == Tool.DOOR) {
            startDoor(p)
        } else {
            startShapeLike(p, dim = true, kind = null)
        }
    }

    /** Ferramenta Cômodo: arrastar desenha o contorno; tocar num segmento existente o seleciona. */
    private fun downRoom(screen: Offset, p: Pt) {
        val sel = st.selected
        if (sel is RoomObj && !sel.locked) {
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
        val hit = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit)) as? RoomObj
        if (hit != null) {
            val k = Geo.hitSeg(st.sheet, hit, p, tol(), st.unit)
            if (k >= 0) { tapRoomId = hit.id; tapSegIdx = k }
        }
        val o = StrokeObj(photoId = null, pts = listOf(p), color = 0xFF2F80ED.toInt(), width = 2.5f, kind = StrokeKind.PENCIL)
        st.live(st.sheet.copy(objs = st.sheet.objs + o))
        createdId = o.id
        mode = Mode.ROOM
    }

    private fun downLasso(p: Pt) {
        if (st.groupIds.isNotEmpty()) {
            val inside = st.groupObjs().any { Geo.bounds(st.sheet, it).contains(p, tol()) }
            if (inside) {
                mode = Mode.GROUP
                groupBase = st.sheet
                groupStart = p
                st.beginGesture()
                return
            }
            st.selectGroup(emptySet())
        }
        s.lasso = listOf(p)
        mode = Mode.LASSO
    }

    private var groupBase: br.com.arque.measure.model.Sheet? = null
    private var groupStart = Pt(0f, 0f)

    private fun finishRoom() {
        val prev = st.sheet.obj(createdId) as? StrokeObj
        if (prev == null) { st.cancelGesture(); return }
        val k = 1f / s.view.scale
        val res = br.com.arque.measure.logic.Straighten.run(
            prev.pts,
            closeTol = (36f * density * k).coerceIn(20f, 60f),
            eps = (10f * density * k).coerceIn(5f, 16f),
            minSeg = (22f * density * k).coerceIn(14f, 36f),
        )
        if (res == null) { st.cancelGesture(); return }
        val n = if (res.closed) res.pts.size else res.pts.size - 1
        val tolS = (26f * density * k).coerceIn(14f, 44f)
        val refPts = st.sheet.objs.filterIsInstance<RoomObj>().filter { it.id != prev.id }.flatMap { Geo.annPoints(st.sheet.photos(), it) }
        val aligned = br.com.arque.measure.logic.Straighten.alignTo(res.pts, res.closed, refPts, tolS)
        val snapped = snapToRooms(aligned, res.closed, tolS, prev.id)
        val room = RoomObj(
            photoId = null, pts = snapped, closed = res.closed, segs = List(n) { Seg() },
            color = s.color, width = s.width,
        )
        st.live(st.sheet.copy(objs = st.sheet.objs.filter { it.id != prev.id } + room))
        st.endGesture()
        st.mergeRoomStray(room.id)
        st.selectSeg(room.id, 0)
    }

    /**
     * Planta da casa: os cantos do traço novo grudam nos cantos das paredes que já existem,
     * e as pontas de uma parede aberta (divisória) grudam em cima da parede mais perto.
     */
    private fun snapToRooms(pts: List<Pt>, closed: Boolean, tolS: Float, skipId: String): List<Pt> {
        val photos = st.sheet.photos()
        val others = st.sheet.objs.filterIsInstance<RoomObj>().filter { it.id != skipId }
        if (others.isEmpty()) return pts
        val verts = others.flatMap { Geo.annPoints(photos, it) }
        val segs = others.flatMap { o ->
            val q = Geo.annPoints(photos, o)
            val n = if (o.closed) q.size else q.size - 1
            (0 until n).map { q[it] to q[(it + 1) % q.size] }
        }
        fun d(a: Pt, b: Pt) = kotlin.math.hypot((a.x - b.x).toDouble(), (a.y - b.y).toDouble()).toFloat()
        return pts.mapIndexed { i, p ->
            val v = verts.minByOrNull { d(it, p) }
            if (v != null && d(v, p) <= tolS) return@mapIndexed v
            val end = !closed && (i == 0 || i == pts.lastIndex)
            if (!end) return@mapIndexed p
            var best: Pt? = null
            var bd = tolS
            for ((a, b) in segs) {
                val dx = b.x - a.x; val dy = b.y - a.y
                val l2 = dx * dx + dy * dy
                if (l2 < 1e-6f) continue
                val t = (((p.x - a.x) * dx + (p.y - a.y) * dy) / l2).coerceIn(0f, 1f)
                val pr = Pt(a.x + dx * t, a.y + dy * t)
                val dd = d(pr, p)
                if (dd <= bd) { bd = dd; best = pr }
            }
            best ?: p
        }
    }

    /** Pontos que servem de encaixe: pontas de traços, linhas, setas e cantos de cômodo. */
    private fun snapPoint(p: Pt, skipId: String?): Pt? {
        val photos = st.sheet.photos()
        val tolS = 14f * density / s.view.scale
        var best: Pt? = null
        var bd = tolS
        fun cand(q: Pt) { val d = hypot(q.x - p.x, q.y - p.y); if (d <= bd) { bd = d; best = q } }
        st.sheet.objs.forEach { o ->
            if (o.id == skipId) return@forEach
            when (o) {
                is StrokeObj -> if (o.pts.size >= 2) { cand(Geo.toSheet(photos, o.photoId, o.pts.first())); cand(Geo.toSheet(photos, o.photoId, o.pts.last())) }
                is ShapeObj -> { cand(Geo.toSheet(photos, o.photoId, o.a)); cand(Geo.toSheet(photos, o.photoId, o.b)) }
                is DimObj -> { cand(Geo.toSheet(photos, o.photoId, o.a)); cand(Geo.toSheet(photos, o.photoId, o.b)) }
                is RoomObj -> Geo.annPoints(photos, o).forEach(::cand)
                else -> {}
            }
        }
        return best
    }

    /** Caneta encostada sem andar (só pressão mudando): conta o tempo parado. */
    fun still(t: Long) {
        if (mode == Mode.STROKE && !strokeStraight && lastSigT >= 0 && t - lastSigT > 550L) hold()
    }

    /** Segurou parado no fim do traço: vira linha reta do começo até ali (encaixa no eixo e nos pontos perto). */
    fun hold() {
        if (mode != Mode.STROKE || strokeStraight) return
        val o = st.sheet.obj(createdId) as? StrokeObj ?: return
        if (o.kind == StrokeKind.HIGHLIGHTER && o.pts.size < 2) return
        val photos = st.sheet.photos()
        val pts = o.pts.map { Geo.toSheet(photos, o.photoId, it) }
        if (pts.size < 3) return
        val len = pts.zipWithNext().sumOf { (a, b) -> hypot(b.x - a.x, b.y - a.y).toDouble() }.toFloat()
        if (len * s.view.scale < 30f * density) return
        strokeStraight = true
        val a0 = snapPoint(pts.first(), o.id) ?: pts.first()
        val e0 = snapPoint(pts.last(), o.id) ?: Geo.snapAxis(a0, pts.last())
        st.live(replace(o.copy(pts = listOf(Geo.fromSheet(photos, o.photoId, a0), Geo.fromSheet(photos, o.photoId, e0)))))
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
        strokeStraight = false
        lastSigT = -1L
        lastSigScreen = s.view.toScreen(p)
    }

    private fun startShape(p: Pt, tool: Tool) {
        val kind = when (tool) {
            Tool.ARROW -> ShapeKind.ARROW
            Tool.DASHED -> ShapeKind.DASHED
            Tool.RECT -> ShapeKind.RECT
            Tool.RRECT -> ShapeKind.RRECT
            Tool.ELLIPSE -> ShapeKind.ELLIPSE
            Tool.TRIANGLE -> ShapeKind.TRIANGLE
            Tool.DARROW -> ShapeKind.DARROW
            Tool.CURVE -> ShapeKind.CURVE
            Tool.ELBOW -> ShapeKind.ELBOW
            Tool.RTRI -> ShapeKind.RTRI
            Tool.DIAMOND -> ShapeKind.DIAMOND
            Tool.TRAP -> ShapeKind.TRAP
            else -> ShapeKind.LINE
        }
        startShapeLike(p, dim = false, kind = kind)
    }

    /** Linha onde a porta está sendo marcada (a porta fica só num trecho dela). */
    private var doorHost: Pair<Pt, Pt>? = null

    /** Ferramenta Porta: arrastar EM CIMA de uma linha marca só aquele trecho como porta. */
    private fun startDoor(p: Pt) {
        val host = Geo.nearestLine(st.sheet, p, tol() * 1.6f)
        doorHost = host
        val start = host?.let { Geo.projectOnSegment(p, it.first, it.second) } ?: p
        val o = br.com.arque.measure.model.DoorObj(a = start, b = start, width = maxOf(1.6f, s.width))
        st.live(st.sheet.copy(objs = st.sheet.objs + o))
        createdId = o.id
        mode = Mode.SHAPE
    }

    /** Ponto da porta: em cima da linha de apoio (se houver), senão alinhado na horizontal/vertical. */
    private fun doorTarget(anchor: Pt, p: Pt, host: Pair<Pt, Pt>?): Pt =
        if (host != null) Geo.projectOnSegment(p, host.first, host.second) else Geo.snapAxis(anchor, p)

    private fun startShapeLike(p: Pt, dim: Boolean, kind: ShapeKind?) {
        val photos = st.sheet.photos()
        val photoId = Geo.photoAt(st.sheet, p)?.id
        val local = Geo.fromSheet(photos, photoId, p)
        val o: Obj = if (dim) {
            DimObj(photoId = photoId, a = local, b = local, color = s.color, width = s.width, refSize = photoId?.let { st.sheet.photos()[it]?.w } ?: 0f)
        } else {
            ShapeObj(photoId = photoId, kind = kind!!, a = local, b = local, color = s.color, width = s.width, fill = s.fill)
        }
        st.live(st.sheet.copy(objs = st.sheet.objs + o))
        createdId = o.id
        mode = Mode.SHAPE
    }

    fun move(screen: Offset, t: Long = -1L) {
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
            Mode.STROKE, Mode.ROOM -> {
                val o = st.sheet.obj(createdId) as? StrokeObj
                if (o != null) {
                    val photos = st.sheet.photos()
                    if (mode == Mode.STROKE && strokeStraight) {
                        // reta: a ponta acompanha o dedo, encaixa no eixo e em pontos próximos
                        val a = Geo.toSheet(photos, o.photoId, o.pts.first())
                        val end = snapPoint(p, o.id) ?: Geo.snapAxis(a, p)
                        st.live(replace(o.copy(pts = listOf(o.pts.first(), Geo.fromSheet(photos, o.photoId, end)))))
                    } else {
                        val last = Geo.toSheet(photos, o.photoId, o.pts.last())
                        // passo mínimo bem pequeno (em pixels de tela) pra escrita fina ficar precisa em qualquer zoom
                        if (hypot(p.x - last.x, p.y - last.y) * s.view.scale >= 0.6f) {
                            st.live(replace(o.copy(pts = o.pts + Geo.fromSheet(photos, o.photoId, p))))
                        }
                        if (mode == Mode.STROKE && t >= 0) {
                            if (lastSigT < 0 || (screen - lastSigScreen).getDistance() > 3f * density) { lastSigScreen = screen; lastSigT = t }
                            else if (t - lastSigT > 550L) hold()
                        }
                    }
                }
            }
            Mode.SHAPE -> {
                val o = st.sheet.obj(createdId)
                if (o is Ann) {
                    val anchor = Geo.annPoints(st.sheet.photos(), o)[0]
                    val straight = o is DimObj || (o is ShapeObj && o.kind in straightKinds)
                    val target = if (o is br.com.arque.measure.model.DoorObj) doorTarget(anchor, p, doorHost) else if (straight) Geo.snapAxis(anchor, p) else p
                    st.live(replace(Geo.withEndpoint(st.sheet, o, true, target)))
                    if (o is DimObj || o is br.com.arque.measure.model.DoorObj || (o is ShapeObj && (o.kind == ShapeKind.ARROW || o.kind == ShapeKind.DARROW))) s.loupe = screen
                }
            }
            Mode.ERASE -> erase(p)
            Mode.LASSO, Mode.ERASE_LASSO -> {
                val last = s.lasso.lastOrNull()
                if (last == null || hypot(p.x - last.x, p.y - last.y) >= 3f) s.lasso = s.lasso + p
            }
            Mode.GROUP -> if (moved) groupBase?.let { st.moveGroupLive(it, p.x - groupStart.x, p.y - groupStart.y) }
            Mode.NONE -> {}
        }
        lastScreen = screen
        lastSheet = p
    }

    /** Último ponto onde a borracha apagou: pontos muito perto são pulados (não trava com o dedo/caneta rápido). */
    private var lastErase: Pt? = null

    private fun erase(p: Pt) {
        val sh = st.sheet
        val r = s.eraserSize * density / s.view.scale
        val le = lastErase
        if (le != null && hypot(p.x - le.x, p.y - le.y) < r * 0.45f) return
        lastErase = p
        val onlyHl = s.eraserOnlyHighlighter
        // apaga qualquer linha ou contorno (traço, forma, cota, porta, parede do cômodo); módulos ficam protegidos
        fun erasable(o: Obj) = o is Ann && o !is br.com.arque.measure.model.CabObj && o !is br.com.arque.measure.model.WallObj && !o.locked &&
            (!onlyHl || (o is StrokeObj && o.kind == StrokeKind.HIGHLIGHTER))
        s.eraserTrail = (s.eraserTrail + p).takeLast(40)
        if (s.eraserMode == EraserMode.PIXEL) {
            val photos = sh.photos()
            var changed = false
            val out = ArrayList<Obj>(sh.objs.size)
            for (o in sh.objs) {
                if (!erasable(o)) { out += o; continue }
                if (o is StrokeObj) {
                    val sp = Geo.annPoints(photos, o)
                    val pieces = br.com.arque.measure.logic.Eraser.erasePieces(sp, p, r + o.width / 2f)
                    if (pieces == null) { out += o; continue }
                    changed = true
                    pieces.forEachIndexed { k, pc ->
                        val local = pc.map { Geo.fromSheet(photos, o.photoId, it) }
                        out += if (k == 0) o.copy(pts = local) else o.copy(id = br.com.arque.measure.model.newId(), pts = local)
                    }
                } else if (o is ShapeObj && !o.fill) {
                    // forma vira traço e a borracha tira só o pedaço que passou
                    val (sa, sb) = Geo.annPoints(photos, o)
                    val outline = br.com.arque.measure.logic.Eraser.shapeOutline(o.kind, sa, sb)
                    val pieces = br.com.arque.measure.logic.Eraser.erasePieces(outline, p, r + o.width / 2f)
                    if (pieces == null) { out += o; continue }
                    changed = true
                    pieces.forEach { pc ->
                        out += StrokeObj(photoId = o.photoId, pts = pc.map { Geo.fromSheet(photos, o.photoId, it) }, color = o.color, width = o.width)
                    }
                } else if (o is RoomObj) {
                    val rp = Geo.annPoints(photos, o)
                    val pieces = br.com.arque.measure.logic.Eraser.roomPieces(o, rp, p, r + o.width / 2f)
                    if (pieces == null) { out += o; continue }
                    changed = true
                    pieces.forEachIndexed { k, (verts, segs) ->
                        out += o.copy(
                            id = if (k == 0) o.id else br.com.arque.measure.model.newId(),
                            pts = verts.map { o.pts[it] }, segs = segs.map { o.segs[it] }, closed = false,
                        )
                    }
                } else if (Geo.hitObj(sh, o, p, r, st.unit)) {
                    changed = true
                } else out += o
            }
            if (changed) st.live(sh.copy(objs = out))
            return
        }
        val gone = sh.objs.filter { erasable(it) && it !is DimObj && it !is RoomObj && Geo.hitObj(sh, it, p, r, st.unit) }.map { it.id }.toSet()
        if (gone.isNotEmpty()) st.live(sh.copy(objs = sh.objs.filter { it.id !in gone }))
    }

    /** Fim do gesto de um dedo. Retorna uma ação de UI (editar número da cota, editar texto) se foi um toque. */
    /** Id do módulo de parede sob o ponto da tela (para o triplo toque). */
    fun cabAt(screen: Offset): String? {
        val id = Geo.hit(st.sheet, s.view.toSheet(screen), tol(), st.unit) ?: return null
        val o = st.sheet.obj(id) as? br.com.arque.measure.model.CabObj ?: return null
        return if (o.layout != null) id else null
    }

    fun up(screen: Offset): GestureAction? {
        val p = s.view.toSheet(screen)
        when (mode) {
            Mode.PAN -> { s.settle() }
            Mode.SHAPE -> if (!moved || (st.sheet.obj(createdId) as? br.com.arque.measure.model.DoorObj)?.let { d -> hypot(d.b.x - d.a.x, d.b.y - d.a.y) < 6f } == true) {
                st.cancelGesture()
            } else {
                // seta livre: o comprimento ao soltar vira a referência do tamanho do quadradinho
                (st.sheet.obj(createdId) as? DimObj)?.let { d ->
                    if (d.refSize <= 0f) {
                        val (pa, pb) = Geo.annPoints(st.sheet.photos(), d)
                        st.live(replace(d.copy(refSize = hypot(pb.x - pa.x, pb.y - pa.y))))
                    }
                }
                st.endGesture()
                createdId?.let { if (st.sheet.obj(it) != null) st.select(it) }
            }
            Mode.ROOM -> if (!moved) st.cancelGesture() else finishRoom()
            Mode.LASSO -> {
                val ids = Geo.lassoPick(st.sheet, s.lasso)
                s.lasso = emptyList()
                st.selectGroup(ids)
            }
            Mode.GROUP -> if (moved) st.endGesture() else st.cancelGesture()
            Mode.ERASE_LASSO -> {
                val onlyHl = s.eraserOnlyHighlighter
                val ids = Geo.lassoPick(st.sheet, s.lasso).filter { id ->
                    val o = st.sheet.obj(id)
                    o is Ann && o !is DimObj && o !is br.com.arque.measure.model.DoorObj && o !is RoomObj && o !is br.com.arque.measure.model.CabObj && o !is br.com.arque.measure.model.WallObj && (!onlyHl || (o is StrokeObj && o.kind == StrokeKind.HIGHLIGHTER))
                }.toSet()
                s.lasso = emptyList()
                st.deleteIds(ids)
            }
            Mode.STROKE, Mode.MOVE, Mode.HANDLE, Mode.ERASE -> {
                s.eraserTrail = emptyList()
                val roomHandle = mode == Mode.HANDLE && st.sheet.obj(activeId) is RoomObj
                st.endGesture()
                if (roomHandle) activeId?.let { st.mergeRoomStray(it) }
            }
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
                (tool == Tool.SELECT || tool == Tool.ROOM) && tapRoomId != null -> {
                    val r = st.sheet.obj(tapRoomId) as? RoomObj
                    if (r != null) {
                        if (st.selectedId != r.id || st.selectedSeg != tapSegIdx) st.selectSeg(r.id, tapSegIdx)
                        if (!r.locked) action = GestureAction.TapSeg(r.id, tapSegIdx)
                    }
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
        if (mode == Mode.STROKE || mode == Mode.SHAPE || mode == Mode.ERASE || mode == Mode.ROOM || mode == Mode.GROUP) st.cancelGesture()
        if (mode == Mode.LASSO || mode == Mode.ERASE_LASSO) s.lasso = emptyList()
        s.eraserTrail = emptyList()
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
            is DimObj, is ShapeObj, is br.com.arque.measure.model.DoorObj -> {
                val pts = Geo.annPoints(photos, o as Ann)
                if (near(pts[1])) H.B to 0 else if (near(pts[0])) H.A to 0 else null
            }
            is RoomObj -> {
                val pts = Geo.annPoints(photos, o)
                pts.forEachIndexed { i, p -> if (near(p)) return H.VERTEX to i }
                null
            }
            is br.com.arque.measure.model.CabObj -> {
                if (o.layout == null) return null
                val (w, h) = Geo.cabHandles(o)
                if (near(w)) H.CAB_W to 0 else if (near(h)) H.CAB_H to 0 else null
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
            is DimObj, is ShapeObj, is br.com.arque.measure.model.DoorObj -> {
                val pts = Geo.annPoints(st.sheet.photos(), o as Ann)
                val other = if (handle == H.B) pts[0] else pts[1]
                val straight = o is DimObj || (o is ShapeObj && o.kind in straightKinds)
                val target = if (o is br.com.arque.measure.model.DoorObj) {
                    // a ponta da porta corre em cima da mesma linha da outra ponta
                    val host = Geo.nearestLine(st.sheet, other, 2f, o.id)
                    doorTarget(other, p, host)
                } else if (straight) Geo.snapAxis(other, p) else p
                st.live(replace(Geo.withEndpoint(st.sheet, o, handle == H.B, target)))
                s.loupe = s.view.toScreen(target)
            }
            is RoomObj -> {
                val pts = o.pts
                val i = handleIdx
                // alinha o vértice na horizontal/vertical com o vizinho anterior (ou seguinte)
                val neighbour = Geo.annPoints(st.sheet.photos(), o).let { sp ->
                    if (i > 0) sp[i - 1] else if (sp.size > 1) sp[1] else null
                }
                val target = if (neighbour != null) Geo.snapAxis(neighbour, p) else p
                if (i in pts.indices) {
                    val local = Geo.fromSheet(st.sheet.photos(), o.photoId, target)
                    st.live(replace(o.copy(pts = pts.mapIndexed { j, q -> if (j == i) local else q })))
                    s.loupe = s.view.toScreen(target)
                }
            }
            is br.com.arque.measure.model.CabObj -> {
                val fit = o.layout ?: return
                val wall = st.sheet.obj(fit.wallId) as? br.com.arque.measure.model.WallObj ?: return
                val k = wall.upm.toFloat()
                val snapMm = 12f * density / s.view.scale / k
                val others = st.sheet.objs.filterIsInstance<br.com.arque.measure.model.CabObj>().filter { it.layout?.wallId == wall.id && it.id != o.id }
                val org = o.origin()
                if (handle == H.CAB_W) {
                    var mm = ((p.x - org.x) / k).toDouble()
                    val cand = ArrayList<Double>()
                    others.forEach { cand += it.cab.wMm }
                    val rowOthers = others.filter { it.cab.superior == o.cab.superior }.sumOf { br.com.arque.measure.logic.WallLayout.occ(it) }
                    val cap = (wall.usableMm - rowOthers - br.com.arque.measure.logic.WallLayout.padL(o) - br.com.arque.measure.logic.WallLayout.padR(o)).coerceAtLeast(150.0)
                    cand += cap // fecha a parede (já com a folga)
                    cand.minByOrNull { kotlin.math.abs(it - mm) }?.let { if (kotlin.math.abs(it - mm) <= snapMm) mm = it }
                    val v = kotlin.math.round(mm).coerceIn(150.0, cap)
                    st.liveCab(o.id) { it.copy(wMm = v) }
                } else {
                    val anchored = fit.anchorTop
                    var mm = if (anchored) ((p.y - org.y) / k).toDouble() else (((org.y + o.heightUnits()) - p.y) / k).toDouble()
                    val cand = ArrayList<Double>()
                    others.forEach { cand += it.cab.hMm }
                    if (o.cab.superior) cand += wall.hMm - wall.upperBottomMm // até o teto
                    cand.minByOrNull { kotlin.math.abs(it - mm) }?.let { if (kotlin.math.abs(it - mm) <= snapMm) mm = it }
                    val capH = if (anchored) fit.topMm else if (o.cab.superior) wall.hMm - wall.upperBottomMm else wall.hMm
                    val v = kotlin.math.round(mm).coerceIn(150.0, capH.coerceAtLeast(150.0))
                    st.liveCab(o.id) { it.copy(hMm = v) }
                }
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
