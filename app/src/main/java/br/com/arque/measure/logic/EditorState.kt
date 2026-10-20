package br.com.arque.measure.logic

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.Seg
import br.com.arque.measure.model.SegKind
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
            onChange()
        }
    }

    /** Seleção em grupo (laço). Vazia = sem grupo. */
    var groupIds: Set<String> = emptySet()
        private set

    fun selectGroup(ids: Set<String>) {
        selectedId = null
        selectedSeg = -1
        groupIds = ids
        onChange()
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
        onChange()
    }

    /** Limpa a folha: traços, formas e textos (fotos, cotas e cômodos ficam). Dá para desfazer. */
    fun clearPageDrawings() {
        val keep = sheet.objs.filter { it is PhotoObj || it is DimObj || it is RoomObj || it is CabObj || it.locked }
        if (keep.size == sheet.objs.size) return
        commit(sheet.copy(objs = keep))
        fixSelection()
        onChange()
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
    fun addCab(at: Pt, cab: Cabinet = Cabinet(), name: String = "Armário base"): String {
        val o = CabObj(at = at, cab = br.com.arque.measure.logic.CabinetMath.normalized(cab), name = name)
        commit(sheet.copy(objs = sheet.objs + o))
        select(o.id)
        return o.id
    }

    /** Edita o módulo [id] (cada chamada é um passo de desfazer). */
    fun updateCab(id: String, f: (Cabinet) -> Cabinet) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked) return
        val next = br.com.arque.measure.logic.CabinetMath.normalized(f(o.cab))
        if (next == o.cab) return
        commit(mapObj(id) { (it as CabObj).copy(cab = next) })
    }

    fun renameCab(id: String, name: String) {
        val o = sheet.obj(id) as? CabObj ?: return
        if (o.locked || name.isBlank()) return
        commit(mapObj(id) { (it as CabObj).copy(name = name.trim()) })
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
        onChange()
    }

    /** Anda para o segmento anterior/seguinte do cômodo selecionado. */
    fun stepSeg(delta: Int) {
        val r = selected as? RoomObj ?: return
        val n = r.segCount()
        if (n == 0) return
        selectedSeg = ((if (selectedSeg < 0) 0 else selectedSeg) + delta + n) % n
        onChange()
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
            onChange()
        }
    }

    private fun withSheet(s: Sheet): Note =
        note.copy(pages = note.pages.mapIndexed { i, p -> if (i == pageIdx) s else p })

    // ---- gestos contínuos ----

    fun beginGesture() {
        if (gestureBase == null) gestureBase = note
    }

    fun live(newSheet: Sheet) {
        if (gestureBase == null) gestureBase = note
        note = withSheet(newSheet)
        onChange()
    }

    fun endGesture() {
        val base = gestureBase ?: return
        gestureBase = null
        if (base != note) {
            push(base)
            redoStack.clear()
            onCommit(note)
        }
        onChange()
    }

    fun cancelGesture() {
        gestureBase?.let { note = it }
        gestureBase = null
        fixSelection()
        onChange()
    }

    // ---- operações discretas ----

    fun commit(newSheet: Sheet) = commitNote(withSheet(newSheet))

    fun commitNote(n: Note) {
        if (n == note) return
        push(note)
        redoStack.clear()
        note = n
        onCommit(note)
        onChange()
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
        onChange()
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
        onChange()
    }

    /** Duplica o objeto com deslocamento. Foto duplicada leva suas anotações junto. */
    fun duplicate(id: String) {
        val o = sheet.obj(id) ?: return
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
                    is RoomObj -> it.copy(color = color ?: it.color, width = width ?: it.width)
                    is CabObj -> it
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
        onChange()
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
        onChange()
        return true
    }

    /** Exclui a folha [i]; a nota sempre mantém pelo menos uma. */
    fun deletePage(i: Int): Boolean {
        if (note.pages.size <= 1 || i !in note.pages.indices) return false
        val pages = note.pages.toMutableList().apply { removeAt(i) }
        commitNote(note.copy(pages = pages))
        pageIdx = pageIdx.coerceIn(0, note.pages.lastIndex)
        selectedId = null
        onChange()
        return true
    }

    // ---- medidas (única origem: trena Bosch) ----

    fun clearValue(id: String) {
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
