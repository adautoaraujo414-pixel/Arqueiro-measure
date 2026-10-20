package br.com.arque.measure.logic

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
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

    private val undoStack = ArrayDeque<Note>()
    private val redoStack = ArrayDeque<Note>()
    private var gestureBase: Note? = null

    val sheet: Sheet get() = note.pages[pageIdx.coerceIn(0, note.pages.lastIndex)]
    val unit: LengthUnit get() = note.unit
    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()
    val selected: Obj? get() = sheet.obj(selectedId)

    fun select(id: String?) {
        if (selectedId != id) {
            selectedId = id
            onChange()
        }
    }

    /** Troca a folha ativa (limpa a seleção). */
    fun setPage(i: Int) {
        val n = i.coerceIn(0, note.pages.lastIndex)
        if (n != pageIdx) {
            pageIdx = n
            selectedId = null
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
        select(copies.first().id)
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
                    labelScale = scale?.coerceIn(0.4f, 4f) ?: it.labelScale,
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
        val d = sheet.obj(id) as? DimObj ?: return
        if (d.locked) return
        commit(mapObj(id) { (it as DimObj).copy(valueMm = null, source = null) })
    }

    /**
     * Aplica uma leitura à cota selecionada, salva na hora e avança a seleção para a próxima
     * cota sem valor. Retorna o id da cota atualizada, ou null se não havia cota selecionável.
     */
    fun assignReading(r: Reading): String? {
        val d = selected as? DimObj ?: return null
        if (d.locked) return null
        commit(
            mapObj(d.id) {
                (it as DimObj).copy(valueMm = r.mm, source = r.source, history = it.history + r)
            },
        )
        nextPending(d.id)?.let { (pg, id) ->
            setPage(pg)
            select(id)
        }
        return d.id
    }

    /** Próxima cota sem valor (e destravada) depois de [id], nesta ou nas outras folhas. */
    fun nextPending(id: String): Pair<Int, String>? {
        val all = note.pages.flatMapIndexed { pi, p -> p.objs.filterIsInstance<DimObj>().map { pi to it } }
        val idx = all.indexOfFirst { it.second.id == id }
        val ordered = if (idx < 0) all else all.drop(idx + 1) + all.take(idx)
        return ordered.firstOrNull { it.second.valueMm == null && !it.second.locked }?.let { it.first to it.second.id }
    }

    companion object {
        const val MAX_UNDO = 200
    }
}
