package br.com.arque.measure.logic

import br.com.arque.measure.i18n.tr

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.Seg
import br.com.arque.measure.model.SegKind
import br.com.arque.measure.model.isOpening
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.Template
import br.com.arque.measure.model.TextObj
import br.com.arque.measure.model.newId
import br.com.arque.measure.model.withId
import br.com.arque.measure.model.withLocked
import br.com.arque.measure.model.withPhotoId

/**
 * Estado de uma nota em edição: folha ativa, seleção, desfazer/refazer e operações.
 * Lógica pura (sem Android) para poder ser testada na JVM.
 *
 * Todas as operações sobre objetos agem na folha ativa ([sheet]). Cada passo de desfazer guarda
 * a nota inteira; um gesto contínuo (beginGesture/live/endGesture) vira UM passo.
 */
class EditorState(
    initial: Note,
    private val onCommit: (Note) -> Unit = {},
    private val onChange: () -> Unit = {},
) {
    var note: Note = initial
        private set
    var pageIdx: Int = 0
        private set
    var selectedId: String? = null
        private set

    /** Segmento selecionado quando o objeto selecionado é um cômodo (-1 = nenhum). */
    var selectedSeg: Int = -1
        private set

    /** Chamado quando muda algo que os painéis/barras mostram (fora de um gesto contínuo). */
    var onUi: () -> Unit = {}
    /** Tem um gesto contínuo em andamento (traço, arrasto, borracha). */
    val inGesture: Boolean get() = gestureBase != null

    /** Folha muda: a tela redesenha sempre; os painéis só recompõem fora do gesto (não pesa no traço). */
    private fun notifyChange() {
        onChange()
        if (gestureBase == null) onUi()
    }

    private val undoStack = ArrayDeque<Note>()
    private val redoStack = ArrayDeque<Note>()
    private var gestureBase: Note? = null

    val sheet: Sheet get() = note.pages[pageIdx.coerceIn(0, note.pages.lastIndex)]
    val unit: LengthUnit get() = note.unit
    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()
    val selected: Obj? get() = sheet.obj(selectedId)

    fun select(id: String?) {
        if (selectedId != id || groupIds.isNotEmpty()) {
            selectedId = id
            selectedSeg = -1
            groupIds = emptySet()
            notifyChange()
        }
    }

    /** Seleção em grupo (laço). Vazia = sem grupo. */
    var groupIds: Set<String> = emptySet()
        private set

    fun selectGroup(ids: Set<String>) {
        selectedId = null
        selectedSeg = -1
        groupIds = ids
        notifyChange()
    }

    fun groupObjs(): List<Obj> = sheet.objs.filter { it.id in groupIds }

    /** Objetos do grupo mais as anotações coladas nas fotos do grupo (para copiar/apagar). */
    fun groupWithLinked(): List<Obj> {
        val photoIds = groupObjs().filterIsInstance<PhotoObj>().map { it.id }.toSet()
        return sheet.objs.filter { it.id in groupIds || (it is Ann && it.photoId != null && it.photoId in photoIds) }
    }

    /** Apaga vários objetos de uma vez (laço da borracha). */
    fun deleteIds(ids: Set<String>) {
        val gone = sheet.objs.filter { it.id in ids && !it.locked }.map { it.id }.toSet()
        if (gone.isEmpty()) return
        commit(sheet.copy(objs = sheet.objs.filter { it.id !in gone }))
        fixSelection()
        notifyChange()
    }

    /** Limpa a folha: traços, formas e textos (fotos, cotas e cômodos ficam). Dá para desfazer. */
    fun clearPageDrawings() {
        val keep = sheet.objs.filter { it is PhotoObj || it is DimObj || it is br.com.arque.measure.model.DoorObj || it is RoomObj || it is CabObj || it is br.com.arque.measure.model.WallObj || it.locked }
        if (keep.size == sheet.objs.size) return
        commit(sheet.copy(objs = keep))
        fixSelection()
        notifyChange()
    }

    fun deleteGroup() {
        val gone = groupWithLinked().filter { !it.locked }.map { it.id }.toSet()
        if (gone.isEmpty()) return
        commit(sheet.copy(objs = sheet.objs.filter { it.id !in gone }))
        selectGroup(emptySet())
    }

    /** Move o grupo (ao vivo). Anotações coladas numa foto do grupo acompanham a foto. */
    fun moveGroupLive(base: Sheet, dx: Float, dy: Float) {
        val photoIds = base.objs.filter { it.id in groupIds }.filterIsInstance<PhotoObj>().map { it.id }.toSet()
        live(
            base.copy(
                objs = base.objs.map { o ->
                    when {
                        o.id !in groupIds -> o
                        o is Ann && o.photoId != null && o.photoId in photoIds -> o
                        else -> Geo.translate(base, o, dx, dy)
                    }
                },
            ),
        )
    }

    /** Coloca um móvel novo na folha ativa e o seleciona. */
    fun addCab(at: Pt, cab: Cabinet = Cabinet(), name: String = tr("Armário base")): String {
        val o = CabObj(at = at, cab = br.com.arque.measure.logic.CabinetMath.normalized(cab), name = name)
        commit(sheet.copy(objs = sheet.objs + o))
        select(o.id)
        return o.id
    }

    /**
     * Encaixa um móvel novo na parede [k] do cômodo [roomId]: a escala vem da medida da parede
     * (traço desenhado ÷ mm medidos). Devolve um aviso (ou null se tudo certo).
     */
    fun addCabOnWall(roomId: String, k: Int): String? {
        val room = sheet.obj(roomId) as? br.com.arque.measure.model.RoomObj ?: return tr("Cômodo não encontrado")
        val mm = room.segs.getOrNull(k)?.valueMm ?: return tr("Meça (ou digite) esta parede antes de encaixar o móvel")
        if (mm <= 0.0) return tr("Medida da parede inválida")
        val photos = sheet.photos()
        val (a, b) = Geo.segEnds(photos, room, k)
        val dx = b.x - a.x
        val dy = b.y - a.y
        val len = kotlin.math.hypot(dx, dy)
        if (len < 1f) return tr("Parede curta demais no desenho")
        val ux = dx / len
        val uy = dy / len
        val poly = Geo.annPoints(photos, room)
        fun inside(p: Pt): Boolean {
            var c = false
            var j = poly.size - 1
            for (i in poly.indices) {
                val pi = poly[i]; val pj = poly[j]
                if ((pi.y > p.y) != (pj.y > p.y) && p.x < (pj.x - pi.x) * (p.y - pi.y) / (pj.y - pi.y) + pi.x) c = !c
                j = i
            }
            return c
        }
        val mid = Pt((a.x + b.x) / 2f, (a.y + b.y) / 2f)
        val probe = 6f
        var nx = -uy
        var ny = ux
        if (!inside(Pt(mid.x + nx * probe, mid.y + ny * probe)) && inside(Pt(mid.x - nx * probe, mid.y - ny * probe))) { nx = -nx; ny = -ny }
        val upm = len.toDouble() / mm
        val base = br.com.arque.measure.logic.CabinetMath.normalized(Cabinet())
        val w = minOf(base.wMm, mm)
        val cab = br.com.arque.measure.logic.CabinetMath.normalized(base.copy(wMm = w))
        val wf = br.com.arque.measure.model.WallFit(roomId, k, a.x, a.y, ux, uy, nx, ny, upm, mm, 0.0)
        val o = CabObj(at = a, cab = cab, name = tr("Armário base"), wall = wf)
        commit(sheet.copy(objs = sheet.objs + o))
        select(o.id)
        return if (base.wMm > mm) tr("Parede de {0} mm: o móvel foi ajustado para caber", mm.toLong()) else null
    }

    // ---- parede do projeto ----

    private val wallSteps = listOf(5, 8, 10, 15, 20, 25, 30, 40, 50, 75, 100)

    fun addWall(at: Pt, wMm: Double = 3000.0, hMm: Double = 2600.0): String {
        val need = maxOf(wMm * 3.7795277 / 680.0, hMm * 3.7795277 / 800.0)
        val den = wallSteps.firstOrNull { it >= need } ?: 100
        val o = br.com.arque.measure.model.WallObj(at = at, wMm = wMm, hMm = hMm, scaleDen = den)
        commit(sheet.copy(objs = sheet.objs + o))
        select(o.id)
        return o.id
    }

    fun setWall(id: String, wMm: Double? = null, hMm: Double? = null, upperBottomMm: Double? = null, scaleDen: Int? = null, folgaMm: Double? = null, alignRow: Int? = null,
        stoneWMm: Double? = null, stoneXMm: Double? = null, stoneTopMm: Double? = null) {
        val o = sheet.obj(id) as? br.com.arque.measure.model.WallObj ?: return
        if (o.locked) return
        commit(mapObj(id) {
            (it as br.com.arque.measure.model.WallObj).copy(
                wMm = (wMm ?: it.wMm).coerceIn(300.0, 20000.0), hMm = (hMm ?: it.hMm).coerceIn(300.0, 6000.0),
                upperBottomMm = (upperBottomMm ?: it.upperBottomMm).coerceIn(0.0, 6000.0),
                scaleDen = (scaleDen ?: it.scaleDen).coerceIn(2, 100),
                folgaMm = (folgaMm ?: it.folgaMm).coerceIn(0.0, 200.0),
                alignRow = (alignRow ?: it.alignRow).coerceIn(0, 2),
                stoneWMm = (stoneWMm ?: it.stoneWMm).coerceIn(0.0, 20000.0),
                stoneXMm = (stoneXMm ?: it.stoneXMm).coerceIn(0.0, 20000.0),
                stoneTopMm = (stoneTopMm ?: it.stoneTopMm).coerceIn(0.0, 6000.0),
            )
        })
    }

    /** Novo módulo ao lado do último da fileira (baixa ou de cima). Devolve o id. */
    fun addWallModule(wallId: String, upper: Boolean): String? {
        val w = sheet.obj(wallId) as? br.com.arque.measure.model.WallObj ?: return null
        if (w.locked) return null
        val row = WallLayout.members(sheet, wallId, upper)
        val left = w.usableMm - row.sumOf { WallLayout.occ(it) }
        val width = if (left >= 300.0) minOf(800.0, left) else 800.0
        val base = if (upper) {
            Cabinet(
                wMm = width, hMm = 700.0, dMm = 350.0, superior = true, hasRodape = false, hasTravessa = false,
                hasMoldura = false, folgaTopoMm = 0.0, prateleiraMenorMm = 30.0,
            )
        } else Cabinet(wMm = width)
        val o = CabObj(
            at = w.at, cab = br.com.arque.measure.logic.CabinetMath.normalized(base),
            name = (if (upper) tr("Superior ") else tr("Base ")) + (row.size + 1),
            scaleDen = w.scaleDen, layout = br.com.arque.measure.model.LayoutFit(wallId, (row.maxOfOrNull { it.layout!!.order } ?: -1) + 1),
        )
        commit(sheet.copy(objs = sheet.objs + o))
        select(o.id)
        return o.id
    }

    /** Alinha o módulo pelo topo (ao diminuir, a base sobe) ou volta a alinhar por baixo. */
    fun setAnchorTop(id: String, on: Boolean) {
        val o = sheet.obj(id) as? CabObj ?: return
        val fit = o.layout ?: return
        val w = sheet.obj(fit.wallId) as? br.com.arque.measure.model.WallObj ?: return
        if (o.locked) return
        val top = WallLayout.topMm(w, o)
        commit(mapObj(id) { (it as CabObj).copy(layout = fit.copy(anchorTop = on, topMm = if (on) top else 0.0)) })
    }

    /** Junta (ou separa) o tamponamento de baixo deste módulo com o do módulo seguinte da fileira. */
    fun joinBottom(id: String, on: Boolean): Boolean {
        val o = sheet.obj(id) as? CabObj ?: return false
        val fit = o.layout ?: return false
        if (o.locked) return false
        val row = WallLayout.members(sheet, fit.wallId, o.cab.superior)
        val i = row.indexOfFirst { it.id == id }
        val next = row.getOrNull(i + 1) ?: return false
        val ids = setOf(o.id, next.id)
        commit(sheet.copy(objs = sheet.objs.map {
            if (it is CabObj && it.id in ids) it.copy(cab = it.cab.copy(tampBaixo = if (on) true else it.cab.tampBaixo, tampBaixoJunto = on)) else it
        }))
        return true
    }

    /** Troca de lugar com o vizinho da fileira ([dir] = -1 esquerda, +1 direita). */
    fun moveModule(id: String, dir: Int) {
        val o = sheet.obj(id) as? CabObj ?: return
        val fit = o.layout ?: return
        val row = WallLayout.members(sheet, fit.wallId, o.cab.superior)
        val i = row.indexOfFirst { it.id == id }
        val j = i + dir
        if (i < 0 || j !in row.indices) return
        val other = row[j]
        commit(sheet.copy(objs = sheet.objs.map {
            when (it.id) {
                o.id -> (it as CabObj).copy(layout = fit.copy(order = other.layout!!.order))
                other.id -> (it as CabObj).copy(layout = other.layout!!.copy(order = fit.order))
                else -> it
            }
        }))
    }

    /** Edita o módulo [id] (cada chamada é um passo de desfazer). */
    fun updateCab(id: String, f: (Cabinet) -> Cabinet) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked) return
        val next = br.com.arque.measure.logic.CabinetMath.normalized(f(o.cab))
        if (next == o.cab) return
        commit(mapObj(id) { (it as CabObj).copy(cab = next) })
    }

    /** Igual a [updateCab], mas ao vivo (arrastar): um gesto inteiro vira um passo de desfazer. */
    fun liveCab(id: String, f: (Cabinet) -> Cabinet) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked) return
        val next = br.com.arque.measure.logic.CabinetMath.normalized(f(o.cab))
        if (next == o.cab) return
        live(mapObj(id) { (it as CabObj).copy(cab = next) })
    }

    fun renameCab(id: String, name: String) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked || name.isBlank()) return
        commit(mapObj(id) { (it as CabObj).copy(name = name.trim()) })
    }

    /** Se o móvel passa da folha na escala atual, escolhe a menor escala que o faz caber (nunca aumenta). */
    fun fitCabToPage(id: String, maxW: Float = 700f, maxH: Float = 880f) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked) return
        val need = maxOf(o.cab.wMm * 3.7795277 / maxW, o.cab.hMm * 3.7795277 / maxH)
        val steps = listOf(5, 8, 10, 15, 20, 25, 30, 40, 50, 75, 100)
        val den = steps.firstOrNull { it >= need } ?: 100
        if (den > o.scaleDen) setCabScale(id, den)
    }

    fun setCabScale(id: String, den: Int) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked) return
        commit(mapObj(id) { (it as CabObj).copy(scaleDen = den.coerceIn(2, 100)) })
    }

    /** Seleciona o cômodo [id] e o segmento [k]. */
    fun selectSeg(id: String, k: Int) {
        selectedId = id
        selectedSeg = k
        notifyChange()
    }

    /** Anda para o segmento anterior/seguinte do cômodo selecionado. */
    fun stepSeg(delta: Int) {
        val r = selected as? RoomObj ?: return
        val n = r.segCount()
        if (n == 0) return
        selectedSeg = ((if (selectedSeg < 0) 0 else selectedSeg) + delta + n) % n
        notifyChange()
    }

    /** Insere um cômodo recém-criado e seleciona o primeiro segmento. */
    fun addRoom(room: RoomObj) {
        commit(sheet.copy(objs = sheet.objs + room))
        selectSeg(room.id, 0)
    }

    fun setSegKind(id: String, k: Int, kind: SegKind) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked || k !in r.segs.indices) return
        commit(mapObj(id) { (it as RoomObj).copy(segs = it.segs.mapIndexed { i, sg -> if (i == k) sg.copy(kind = kind) else sg }) })
    }

    /** Sentido da porta: dobradiça (0 início / 1 fim), lado que abre (1 / -1) e se é de correr. */
    fun setSegDoor(id: String, k: Int, hinge: Int? = null, side: Int? = null, slide: Boolean? = null) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked || k !in r.segs.indices) return
        commit(mapObj(id) { (it as RoomObj).copy(segs = it.segs.mapIndexed { i, sg -> if (i == k) sg.copy(hinge = hinge ?: sg.hinge, side = side ?: sg.side, slide = slide ?: sg.slide) else sg }) })
    }

    /**
     * Divide o trecho [k]. Com [mid] = null, parte no meio (2 trechos do mesmo tipo).
     * Com [mid], abre uma porta/janela/vão no meio da parede (3 trechos: parede · [mid] · parede).
     * Medida do trecho dividido some: cada pedaço é medido de novo (manual ou trena).
     */
    fun splitSeg(id: String, k: Int, mid: SegKind? = null) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked || k !in r.segs.indices) return
        val a = r.pts[k]
        val b = r.pts[(k + 1) % r.pts.size]
        val sg = r.segs[k]
        val clean = sg.copy(valueMm = null, source = null, history = emptyList())
        val newPts: List<Pt>
        val newSegs: List<Seg>
        if (mid == null) {
            newPts = listOf(a + (b - a) * 0.5f)
            newSegs = listOf(clean, clean)
        } else {
            val want = if (mid == SegKind.WINDOW) 1200.0 else 800.0
            val f = (sg.valueMm?.let { (want / it).coerceIn(0.15, 0.8) } ?: (1.0 / 3.0)).toFloat()
            val t0 = (1f - f) / 2f
            newPts = listOf(a + (b - a) * t0, a + (b - a) * (t0 + f))
            val wall = clean.copy(kind = if (sg.kind.isOpening()) SegKind.WALL else sg.kind)
            newSegs = listOf(wall, Seg(kind = mid), wall)
        }
        val pts = r.pts.toMutableList().apply { addAll(k + 1, newPts) }
        val segs = r.segs.toMutableList().apply { removeAt(k); addAll(k, newSegs) }
        commit(mapObj(id) { (it as RoomObj).copy(pts = pts, segs = segs) })
        selectSeg(id, if (mid == null) k else k + 1)
    }

    /** Marca todos os segmentos do cômodo com o mesmo tipo (medidas ficam como estão). */
    fun setAllSegKinds(id: String, kind: SegKind) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked) return
        commit(mapObj(id) { (it as RoomObj).copy(segs = it.segs.map { sg -> sg.copy(kind = kind) }) })
    }

    /** Fecha o contorno (liga o último vértice ao primeiro, novo segmento de parede) ou reabre. */
    fun setRoomClosed(id: String, closed: Boolean) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked || r.closed == closed || r.pts.size < 3) return
        val segs = if (closed) r.segs + Seg() else r.segs.dropLast(1)
        commit(mapObj(id) { (it as RoomObj).copy(closed = closed, segs = segs) })
        if (selectedSeg >= segs.size) selectedSeg = segs.lastIndex
    }

    /**
     * Tira os pontos soltos no meio das retas: uma reta = uma medida só.
     * Se todos os pedaços tinham medida, a reta unida fica com a soma; senão fica sem medida.
     */
    fun mergeRoomStray(id: String): Boolean {
        val r = sheet.obj(id) as? RoomObj ?: return false
        if (r.locked) return false
        val nSeg = r.segs.size
        val fixed = r.pts.indices.filter { i ->
            val before = if (i == 0) (if (r.closed) r.segs.getOrNull(nSeg - 1) else null) else r.segs.getOrNull(i - 1)
            val after = r.segs.getOrNull(i)
            before != null && after != null && (before.kind != after.kind || before.kind.isOpening() || after.kind.isOpening())
        }.toSet()
        val keep = br.com.arque.measure.logic.Straighten.strayFreeIndices(r.pts, r.closed, fixed = fixed)
        if (keep.size == r.pts.size) return false
        val n = r.pts.size
        val segs = ArrayList<br.com.arque.measure.model.Seg>()
        val pairs = if (r.closed) keep.indices.map { keep[it] to keep[(it + 1) % keep.size] } else keep.zipWithNext()
        for ((a, b) in pairs) {
            val group = ArrayList<br.com.arque.measure.model.Seg>()
            var idx = a
            do { r.segs.getOrNull(idx)?.let { group += it }; idx = (idx + 1) % n } while (idx != b)
            val first = group.firstOrNull() ?: br.com.arque.measure.model.Seg()
            val all = group.isNotEmpty() && group.all { it.valueMm != null }
            segs += if (group.size <= 1) first else first.copy(
                valueMm = if (all) group.sumOf { it.valueMm!! } else null,
                source = if (all) first.source else null,
                history = emptyList(),
            )
        }
        val next = mapObj(id) { (it as RoomObj).copy(pts = keep.map { i -> r.pts[i] }, segs = segs) }
        commit(next)
        if (selectedSeg >= segs.size) selectedSeg = segs.lastIndex
        return true
    }

    fun setRoomLabelScale(id: String, scale: Float, live: Boolean = false) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked) return
        val next = mapObj(id) { (it as RoomObj).copy(labelScale = scale.coerceIn(0.1f, 4f)) }
        if (live) live(next) else commit(next)
    }

    /** Troca a folha ativa (limpa a seleção). */
    fun setPage(i: Int) {
        val n = i.coerceIn(0, note.pages.lastIndex)
        if (n != pageIdx) {
            pageIdx = n
            selectedId = null
            groupIds = emptySet()
            notifyChange()
        }
    }

    private fun withSheet(s: Sheet): Note =
        note.copy(pages = note.pages.mapIndexed { i, p -> if (i == pageIdx) WallLayout.sync(s) else p })

    // ---- gestos contínuos ----

    fun beginGesture() {
        if (gestureBase == null) { gestureBase = note; onUi() }
    }

    fun live(newSheet: Sheet) {
        val first = gestureBase == null
        if (first) gestureBase = note
        note = withSheet(newSheet)
        notifyChange()
        if (first) onUi()
    }

    fun endGesture() {
        val base = gestureBase ?: return
        gestureBase = null
        if (base !== note) {
            push(base)
            redoStack.clear()
            onCommit(note)
        }
        notifyChange()
    }

    fun cancelGesture() {
        gestureBase?.let { note = it }
        gestureBase = null
        fixSelection()
        notifyChange()
    }

    // ---- operações discretas ----

    fun commit(newSheet: Sheet) = commitNote(withSheet(newSheet))

    fun commitNote(n: Note) {
        if (n == note) return
        push(note)
        redoStack.clear()
        note = n
        onCommit(note)
        notifyChange()
    }

    private fun push(s: Note) {
        undoStack.addLast(s)
        if (undoStack.size > MAX_UNDO) undoStack.removeFirst()
    }

    private fun restore(n: Note) {
        note = n
        pageIdx = pageIdx.coerceIn(0, note.pages.lastIndex)
        fixSelection()
        onCommit(note)
        notifyChange()
    }

    fun undo() {
        if (undoStack.isEmpty()) return
        cancelGesture()
        redoStack.addLast(note)
        restore(undoStack.removeLast())
    }

    fun redo() {
        if (redoStack.isEmpty()) return
        cancelGesture()
        undoStack.addLast(note)
        restore(redoStack.removeLast())
    }

    private fun fixSelection() {
        if (selectedId != null && sheet.obj(selectedId) == null) selectedId = null
    }

    private fun mapObj(id: String, f: (Obj) -> Obj): Sheet =
        sheet.copy(objs = sheet.objs.map { if (it.id == id) f(it) else it })

    fun addObj(o: Obj, select: Boolean = true) {
        commit(sheet.copy(objs = sheet.objs + o))
        if (select) select(o.id)
    }

    /** Apaga o objeto. Apagar uma foto apaga também as anotações vinculadas a ela. */
    fun delete(id: String) {
        val o = sheet.obj(id) ?: return
        if (o.locked) return
        val gone = buildSet {
            add(id)
            if (o is PhotoObj) sheet.objs.filterIsInstance<Ann>().filter { it.photoId == id }.forEach { add(it.id) }
        }
        commit(sheet.copy(objs = sheet.objs.filter { it.id !in gone }))
        fixSelection()
        notifyChange()
    }

    /** Duplica o objeto com deslocamento. Foto duplicada leva suas anotações junto. */
    fun duplicate(id: String) {
        val o = sheet.obj(id) ?: return
        val fit = (o as? CabObj)?.layout
        if (o is CabObj && fit != null) {
            // módulo da parede: a cópia entra logo ao lado (mesma fileira), com as mesmas medidas
            val row = WallLayout.members(sheet, fit.wallId, o.cab.superior)
            val copy = o.copy(id = newId(), name = o.name + tr(" (cópia)"), locked = false, layout = fit.copy(order = fit.order + 1))
            commit(sheet.copy(objs = sheet.objs.map {
                if (it is CabObj && it.layout?.wallId == fit.wallId && it.cab.superior == o.cab.superior && it.layout.order > fit.order) it.copy(layout = it.layout.copy(order = it.layout.order + 1)) else it
            } + copy))
            select(copy.id)
            return
        }
        val off = 24f
        val newObjs = mutableListOf<Obj>()
        val dupId: String
        if (o is PhotoObj) {
            val copy = o.copy(id = newId(), cx = o.cx + off, cy = o.cy + off, locked = false)
            dupId = copy.id
            newObjs += copy
            sheet.objs.filterIsInstance<Ann>().filter { it.photoId == o.id }.forEach {
                newObjs += (it.withId(newId()) as Ann).withPhotoId(copy.id)
            }
        } else {
            val moved = Geo.translate(sheet, o, off, off).withId(newId()).withLocked(false)
            dupId = moved.id
            newObjs += moved
        }
        commit(sheet.copy(objs = sheet.objs + newObjs))
        select(dupId)
    }

    /** Cola objetos copiados (foto leva suas anotações) na folha ativa, com novos ids e deslocamento. */
    fun pasteObjs(src: List<Obj>) {
        if (src.isEmpty()) return
        val idMap = src.associate { it.id to newId() }
        val copies = src.map { o ->
            val n = o.withId(idMap.getValue(o.id)).withLocked(false)
            val moved = if (n is PhotoObj) n.copy(cx = n.cx + 24f, cy = n.cy + 24f) else n
            val pid = (moved as? Ann)?.photoId
            if (moved is Ann && pid != null && idMap.containsKey(pid)) moved.withPhotoId(idMap.getValue(pid)) else moved
        }
        commit(sheet.copy(objs = sheet.objs + copies))
        if (copies.size > 1) selectGroup(copies.map { it.id }.toSet()) else select(copies.first().id)
    }

    /** Camadas: sobe/desce uma posição na ordem de desenho. */
    fun reorder(id: String, up: Boolean) {
        val i = sheet.objs.indexOfFirst { it.id == id }
        if (i < 0) return
        val j = if (up) i + 1 else i - 1
        if (j !in sheet.objs.indices) return
        val list = sheet.objs.toMutableList()
        val t = list[i]; list[i] = list[j]; list[j] = t
        commit(sheet.copy(objs = list))
    }

    fun setLocked(id: String, locked: Boolean) {
        commit(mapObj(id) { it.withLocked(locked) })
    }

    fun setStyle(id: String, color: Int? = null, width: Float? = null) {
        val o = sheet.obj(id) ?: return
        if (o.locked) return
        commit(
            mapObj(id) {
                when (it) {
                    is StrokeObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is ShapeObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is DimObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is br.com.arque.measure.model.DoorObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is RoomObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is CabObj -> it
                    is br.com.arque.measure.model.WallObj -> it
                    is TextObj -> it.copy(color = color ?: it.color, size = width?.let { w -> w * 6f } ?: it.size)
                    is PhotoObj -> it
                }
            },
        )
    }

    /** Ajusta o quadradinho da medida: tamanho, opacidade e intensidade da cor (null = não muda). */
    fun setDimLabel(id: String, scale: Float? = null, alpha: Float? = null, intensity: Float? = null, live: Boolean = false) {
        val d = sheet.obj(id) as? DimObj ?: return
        if (d.locked) return
        val next = (
            mapObj(id) {
                (it as DimObj).copy(
                    labelScale = scale?.coerceIn(0.1f, 4f) ?: it.labelScale,
                    labelAlpha = alpha?.coerceIn(0f, 1f) ?: it.labelAlpha,
                    labelIntensity = intensity?.coerceIn(0f, 1f) ?: it.labelIntensity,
                )
            }
            )
        if (live) live(next) else commit(next)
    }

    /** Copia o estilo do quadradinho de [id] para todas as cotas da nota (não travadas). */
    fun applyDimLabelToAll(id: String) {
        val src = sheet.obj(id) as? DimObj ?: return
        commitNote(
            note.copy(
                pages = note.pages.map { p ->
                    p.copy(
                        objs = p.objs.map {
                            if (it is DimObj && !it.locked) {
                                it.copy(labelScale = src.labelScale, labelAlpha = src.labelAlpha, labelIntensity = src.labelIntensity)
                            } else it
                        },
                    )
                },
            ),
        )
    }

    fun rotatePhoto90(id: String) {
        val o = sheet.obj(id) as? PhotoObj ?: return
        if (o.locked) return
        commit(mapObj(id) { (it as PhotoObj).copy(rot = (it.rot + 90f) % 360f) })
    }

    fun setText(id: String, text: String) {
        val o = sheet.obj(id) as? TextObj ?: return
        if (o.locked) return
        commit(mapObj(id) { (it as TextObj).copy(text = text) })
    }

    fun setUnit(u: LengthUnit) {
        commitNote(note.copy(unit = u))
    }

    /**
     * Troca o nome da nota sem entrar no desfazer (o nome vem do cliente do projeto ligado).
     * As cópias do desfazer/refazer também levam o nome novo, pra ↶ não voltar o nome antigo.
     */
    fun renameNoteSilently(name: String) {
        if (name.isBlank() || name == note.name) return
        val u = undoStack.map { it.copy(name = name) }; undoStack.clear(); undoStack.addAll(u)
        val r = redoStack.map { it.copy(name = name) }; redoStack.clear(); redoStack.addAll(r)
        note = note.copy(name = name)
        onCommit(note)
        notifyChange()
    }

    fun setNoteLocked(v: Boolean) {
        commitNote(note.copy(locked = v))
    }

    // ---- folhas ----

    /** Insere uma folha em [pos] (0..size) e a torna ativa. Retorna false se atingiu o limite. */
    fun addPage(pos: Int, tpl: Template): Boolean {
        if (note.pages.size >= Sheet.MAX_PAGES) return false
        val at = pos.coerceIn(0, note.pages.size)
        val pages = note.pages.toMutableList().apply { add(at, Sheet(tpl = tpl)) }
        commitNote(note.copy(pages = pages))
        pageIdx = at
        selectedId = null
        notifyChange()
        return true
    }

    fun duplicatePage(i: Int): Boolean {
        if (note.pages.size >= Sheet.MAX_PAGES || i !in note.pages.indices) return false
        val src = note.pages[i]
        val idMap = src.objs.associate { it.id to newId() }
        val copy = Sheet(
            tpl = src.tpl,
            objs = src.objs.map { o ->
                val n = o.withId(idMap.getValue(o.id))
                val pid = (n as? Ann)?.photoId
                if (n is Ann && pid != null) n.withPhotoId(idMap[pid] ?: pid) else n
            },
        )
        val pages = note.pages.toMutableList().apply { add(i + 1, copy) }
        commitNote(note.copy(pages = pages))
        pageIdx = i + 1
        selectedId = null
        notifyChange()
        return true
    }

    /** Exclui a folha [i]; a nota sempre mantém pelo menos uma. */
    fun deletePage(i: Int): Boolean {
        if (note.pages.size <= 1 || i !in note.pages.indices) return false
        val pages = note.pages.toMutableList().apply { removeAt(i) }
        commitNote(note.copy(pages = pages))
        pageIdx = pageIdx.coerceIn(0, note.pages.lastIndex)
        selectedId = null
        notifyChange()
        return true
    }

    // ---- medidas (única origem: trena Bosch) ----

    /** Sentido da porta marcada na linha: dobradiça (0 início / 1 fim), lado que abre (1 / -1) e se é de correr. */
    fun setDoor(
        id: String, hinge: Int? = null, side: Int? = null, slide: Boolean? = null,
        labelScale: Float? = null, width: Float? = null, labelVert: Boolean? = null, live: Boolean = false,
    ) {
        val d = sheet.obj(id) as? br.com.arque.measure.model.DoorObj ?: return
        if (d.locked) return
        val next = mapObj(id) {
            d.copy(
                hinge = hinge ?: d.hinge, side = side ?: d.side, slide = slide ?: d.slide,
                labelScale = labelScale?.coerceIn(0.1f, 4f) ?: d.labelScale,
                width = width?.coerceIn(0.3f, 8f) ?: d.width,
                labelVert = labelVert ?: d.labelVert,
            )
        }
        if (live) live(next) else commit(next)
    }

    fun setRoomLabelVert(id: String, vert: Boolean) {
        val r = sheet.obj(id) as? RoomObj ?: return
        if (r.locked) return
        commit(mapObj(id) { (it as RoomObj).copy(labelVert = vert) })
    }

    fun clearValue(id: String) {
        (sheet.obj(id) as? br.com.arque.measure.model.DoorObj)?.let { d ->
            if (d.locked) return
            commit(mapObj(id) { d.copy(valueMm = null, source = null) })
            return
        }
        val room = sheet.obj(id) as? RoomObj
        if (room != null) {
            val k = selectedSeg
            if (room.locked || k !in room.segs.indices) return
            commit(mapObj(id) { (it as RoomObj).copy(segs = it.segs.mapIndexed { i, sg -> if (i == k) sg.copy(valueMm = null, source = null) else sg }) })
            return
        }
        val d = sheet.obj(id) as? DimObj ?: return
        if (d.locked) return
        commit(mapObj(id) { (it as DimObj).copy(valueMm = null, source = null) })
    }

    /**
     * Aplica uma leitura à cota selecionada, salva na hora e avança a seleção para a próxima
     * cota sem valor. Retorna o id da cota atualizada, ou null se não havia cota selecionável.
     */
    fun assignReading(r: Reading): String? {
        val room = selected as? RoomObj
        if (room != null) {
            val k = selectedSeg
            if (room.locked || k !in room.segs.indices) return null
            commit(
                mapObj(room.id) {
                    (it as RoomObj).copy(
                        segs = it.segs.mapIndexed { i, sg ->
                            if (i == k) sg.copy(valueMm = r.mm, source = r.source, history = sg.history + r) else sg
                        },
                    )
                },
            )
            nextPendingTarget(room.id, k)?.let { (pg, id, seg) ->
                setPage(pg)
                if (seg >= 0) selectSeg(id, seg) else select(id)
            }
            return room.id
        }
        (selected as? br.com.arque.measure.model.DoorObj)?.let { dr ->
            if (dr.locked) return null
            commit(mapObj(dr.id) { dr.copy(valueMm = r.mm, source = r.source, history = dr.history + r) })
            return dr.id
        }
        val d = selected as? DimObj ?: return null
        if (d.locked) return null
        commit(
            mapObj(d.id) {
                (it as DimObj).copy(valueMm = r.mm, source = r.source, history = it.history + r)
            },
        )
        nextPendingTarget(d.id, -1)?.let { (pg, id, seg) ->
            setPage(pg)
            if (seg >= 0) selectSeg(id, seg) else select(id)
        }
        return d.id
    }

    /** Medida digitada à mão (trena desconectada): fica marcada como MANUAL, nunca como Bluetooth. */
    fun setManualValue(mm: Double): String? {
        if (!mm.isFinite() || mm <= 0.0) return null
        return assignReading(Reading(mm = mm, source = br.com.arque.measure.model.MeasureSource.MANUAL, timeMs = System.currentTimeMillis()))
    }

    /** Próxima cota sem valor (e destravada) depois de [id], nesta ou nas outras folhas. */
    fun nextPending(id: String): Pair<Int, String>? = nextPendingTarget(id, -1)?.let { it.first to it.second }

    /** Como [nextPending], mas também percorre os segmentos dos cômodos: (folha, id, segmento ou -1). */
    fun nextPendingTarget(id: String, seg: Int): Triple<Int, String, Int>? {
        data class Item(val page: Int, val id: String, val seg: Int, val pending: Boolean)
        val all = note.pages.flatMapIndexed { pi, p ->
            p.objs.flatMap { o ->
                when {
                    o is DimObj -> listOf(Item(pi, o.id, -1, o.valueMm == null && !o.locked))
                    o is RoomObj -> o.segs.mapIndexed { k, sg -> Item(pi, o.id, k, sg.valueMm == null && !o.locked) }
                    else -> emptyList()
                }
            }
        }
        val idx = all.indexOfFirst { it.id == id && it.seg == seg }
        val ordered = if (idx < 0) all else all.drop(idx + 1) + all.take(idx)
        return ordered.firstOrNull { it.pending }?.let { Triple(it.page, it.id, it.seg) }
    }

    companion object {
        const val MAX_UNDO = 200
    }
}
