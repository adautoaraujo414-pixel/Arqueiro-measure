package br.com.arque.measure

import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeObj
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class EditorStateTest {
    private fun dim(id: String, v: Double? = null, locked: Boolean = false) =
        DimObj(id = id, photoId = null, a = Pt(0f, 0f), b = Pt(10f, 0f), valueMm = v, color = 0, width = 3f, locked = locked)

    private fun reading(mm: Double, src: MeasureSource = MeasureSource.BLUETOOTH) =
        Reading(mm = mm, source = src, timeMs = 1L, device = "GLM 50 C", rawHex = "C0 55")

    private fun state(vararg objs: br.com.arque.measure.model.Obj, onCommit: (Sheet) -> Unit = {}) =
        EditorState(Sheet(roomId = "r", name = "s", objs = objs.toList()), onCommit)

    @Test fun `leitura vai para a cota selecionada e e salva na hora`() {
        var saved: Sheet? = null
        val st = state(dim("a"), dim("b"), onCommit = { saved = it })
        st.select("a")
        val id = st.assignReading(reading(2345.0))
        assertEquals("a", id)
        val d = st.sheet.obj("a") as DimObj
        assertEquals(2345.0, d.valueMm!!, 0.0)
        assertEquals(MeasureSource.BLUETOOTH, d.source)
        assertEquals(1, d.history.size)
        assertEquals("C0 55", d.history[0].rawHex)
        // salvamento automático foi acionado
        assertEquals(2345.0, (saved!!.obj("a") as DimObj).valueMm!!, 0.0)
    }

    @Test fun `depois de medir seleciona a proxima cota sem valor`() {
        val st = state(dim("a"), dim("b", v = 100.0), dim("c"))
        st.select("a")
        st.assignReading(reading(500.0))
        assertEquals("c", st.selectedId)
        st.assignReading(reading(700.0))
        // não sobrou nenhuma pendente: a seleção permanece
        assertEquals("c", st.selectedId)
    }

    @Test fun `sem cota selecionada a leitura nao e aplicada`() {
        val st = state(dim("a"))
        assertNull(st.assignReading(reading(100.0)))
        assertNull((st.sheet.obj("a") as DimObj).valueMm)
        st.select("a")
        st.setLocked("a", true)
        assertNull(st.assignReading(reading(100.0)))
    }

    @Test fun `nova leitura substitui o valor e mantem historico`() {
        val st = state(dim("a", v = 1000.0))
        st.select("a")
        st.assignReading(reading(1002.0))
        val d = st.sheet.obj("a") as DimObj
        assertEquals(1002.0, d.valueMm!!, 0.0)
        assertEquals(1, d.history.size)
    }

    @Test fun `edicao manual marca a origem como manual e guarda em mm`() {
        val st = state(dim("a"))
        assertTrue(st.setManual("a", 1850.0))
        val d = st.sheet.obj("a") as DimObj
        assertEquals(MeasureSource.MANUAL, d.source)
        assertEquals(1850.0, d.valueMm!!, 0.0)
        assertFalse(st.setManual("a", -3.0))
        assertFalse(st.setManual("a", Double.NaN))
    }

    @Test fun `desfazer e refazer`() {
        val st = state(dim("a"))
        st.select("a")
        st.assignReading(reading(300.0))
        assertTrue(st.canUndo)
        st.undo()
        assertNull((st.sheet.obj("a") as DimObj).valueMm)
        assertTrue(st.canRedo)
        st.redo()
        assertEquals(300.0, (st.sheet.obj("a") as DimObj).valueMm!!, 0.0)
    }

    @Test fun `um gesto inteiro vira um unico passo de desfazer`() {
        val photo = PhotoObj(id = "p", file = "a.jpg", pxW = 10, pxH = 10, cx = 100f, cy = 100f, w = 100f, h = 100f)
        val st = state(photo)
        st.beginGesture()
        for (i in 1..30) st.live(st.sheet.copy(objs = listOf(photo.copy(cx = 100f + i))))
        st.endGesture()
        assertEquals(130f, (st.sheet.obj("p") as PhotoObj).cx, 0f)
        st.undo()
        assertEquals(100f, (st.sheet.obj("p") as PhotoObj).cx, 0f)
        assertFalse(st.canUndo)
    }

    @Test fun `gesto cancelado nao deixa rastro`() {
        val st = state(dim("a"))
        st.beginGesture()
        st.live(st.sheet.copy(objs = st.sheet.objs + dim("x")))
        st.cancelGesture()
        assertEquals(1, st.sheet.objs.size)
        assertFalse(st.canUndo)
    }

    @Test fun `apagar foto apaga as anotacoes vinculadas e duplicar leva junto`() {
        val photo = PhotoObj(id = "p", file = "a.jpg", pxW = 10, pxH = 10, cx = 100f, cy = 100f, w = 100f, h = 100f)
        val linked = dim("d").copy(photoId = "p", valueMm = 800.0)
        val free = StrokeObj(id = "s", photoId = null, pts = listOf(Pt(1f, 1f)), color = 0, width = 2f)
        val st = state(photo, linked, free)

        st.duplicate("p")
        assertEquals(5, st.sheet.objs.size)
        val copy = st.sheet.objs.filterIsInstance<PhotoObj>().first { it.id != "p" }
        val copyDim = st.sheet.objs.filterIsInstance<DimObj>().first { it.photoId == copy.id }
        assertEquals(800.0, copyDim.valueMm!!, 0.0)

        st.delete("p")
        assertEquals(listOf("s") + listOf(copy.id, copyDim.id), st.sheet.objs.map { it.id }.sortedBy { if (it == "s") 0 else 1 })
        assertNull(st.sheet.obj("p"))
        assertNull(st.sheet.obj("d"))
    }

    @Test fun `objeto travado nao pode ser apagado`() {
        val st = state(dim("a", locked = true))
        st.delete("a")
        assertEquals(1, st.sheet.objs.size)
    }

    @Test fun `camadas sobem e descem`() {
        val st = state(dim("a"), dim("b"), dim("c"))
        st.reorder("a", up = true)
        assertEquals(listOf("b", "a", "c"), st.sheet.objs.map { it.id })
        st.reorder("c", up = false)
        assertEquals(listOf("b", "c", "a"), st.sheet.objs.map { it.id })
    }
}
