package br.com.arque.measure.logic

import br.com.arque.measure.model.Ann
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.Paper
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import br.com.arque.measure.model.newId
import br.com.arque.measure.model.withId
import br.com.arque.measure.model.withLocked
import br.com.arque.measure.model.withPhotoId

/**
 * Estado de uma folha em edição: seleção, desfazer/refazer e operações sobre objetos.
 * Lógica pura (sem Android) para poder ser testada na JVM.
 *
 * Gestos contínuos usam beginGesture/live/endGesture: um gesto inteiro vira UM passo de desfazer.
 */
class EditorState(
    initial: Sheet,
    private val onCommit: (Sheet) -> Unit = {},
    private val onChange: () -> Unit = {},
) {
    var sheet: Sheet = initial
        private set
    var selectedId: String? = null
        private set

    private val undoStack = ArrayDeque<Sheet>()
    private val redoStack = ArrayDeque<Sheet>()
    private var gestureBase: Sheet? = null

    val canUndo: Boolean get() = undoStack.isNotEmpty()
    val canRedo: Boolean get() = redoStack.isNotEmpty()
    val selected: Obj? get() = sheet.obj(selectedId)

    fun select(id: String?) {
        if (selectedId != id) {
            selectedId = id
            onChange()
        }
    }

    // ---- gestos contínuos ----

    fun beginGesture() {
        if (gestureBase == null) gestureBase = sheet
    }

    fun live(newSheet: Sheet) {
        if (gestureBase == null) gestureBase = sheet
        sheet = newSheet
        onChange()
    }

    fun endGesture() {
        val base = gestureBase ?: return
        gestureBase = null
        if (base != sheet) {
            push(base)
            redoStack.clear()
            onCommit(sheet)
        }
        onChange()
    }

    fun cancelGesture() {
        gestureBase?.let { sheet = it }
        gestureBase = null
        fixSelection()
        onChange()
    }

    // ---- operações discretas ----

    fun commit(newSheet: Sheet) {
        if (newSheet == sheet) return
        push(sheet)
        redoStack.clear()
        sheet = newSheet
        onCommit(sheet)
        onChange()
    }

    private fun push(s: Sheet) {
        undoStack.addLast(s)
        if (undoStack.size > MAX_UNDO) undoStack.removeFirst()
    }

    fun undo() {
        if (undoStack.isEmpty()) return
        cancelGesture()
        redoStack.addLast(sheet)
        sheet = undoStack.removeLast()
        fixSelection()
        onCommit(sheet)
        onChange()
    }

    fun redo() {
        if (redoStack.isEmpty()) return
        cancelGesture()
        undoStack.addLast(sheet)
        sheet = redoStack.removeLast()
        fixSelection()
        onCommit(sheet)
        onChange()
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
        commit(sheet.copy(unit = u))
    }

    fun setPaper(p: Paper, landscape: Boolean) {
        commit(sheet.copy(paper = p, landscape = landscape))
    }

    // ---- medidas ----

    /** Digitação manual da cota (edição rápida). O valor é sempre armazenado em mm. */
    fun setManual(id: String, mm: Double, nowMs: Long = System.currentTimeMillis()): Boolean {
        val d = sheet.obj(id) as? DimObj ?: return false
        if (d.locked || !mm.isFinite() || mm <= 0.0) return false
        val r = Reading(mm = mm, source = MeasureSource.MANUAL, timeMs = nowMs)
        commit(mapObj(id) { (it as DimObj).copy(valueMm = mm, source = MeasureSource.MANUAL, history = it.history + r) })
        return true
    }

    fun clearValue(id: String) {
        val d = sheet.obj(id) as? DimObj ?: return
        if (d.locked) return
        commit(mapObj(id) { (it as DimObj).copy(valueMm = null, source = null) })
    }

    /**
     * Aplica uma leitura (normalmente do Bluetooth) à cota selecionada.
     * Salva na hora e avança a seleção para a próxima cota sem valor, se houver.
     * Retorna o id da cota atualizada, ou null se não havia cota selecionável.
     */
    fun assignReading(r: Reading): String? {
        val d = selected as? DimObj ?: return null
        if (d.locked) return null
        commit(
            mapObj(d.id) {
                (it as DimObj).copy(valueMm = r.mm, source = r.source, history = it.history + r)
            },
        )
        nextPendingAfter(d.id)?.let { select(it) }
        return d.id
    }

    /** Próxima cota sem valor (e destravada) depois de [id], dando a volta na lista. */
    fun nextPendingAfter(id: String): String? {
        val dims = sheet.objs.filterIsInstance<DimObj>()
        val idx = dims.indexOfFirst { it.id == id }
        val ordered = if (idx < 0) dims else dims.drop(idx + 1) + dims.take(idx)
        return ordered.firstOrNull { it.valueMm == null && !it.locked }?.id
    }

    companion object {
        const val MAX_UNDO = 200
    }
}
