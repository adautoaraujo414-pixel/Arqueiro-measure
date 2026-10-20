package br.com.arque.measure

import br.com.arque.measure.data.Json
import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.logic.Straighten
import br.com.arque.measure.model.*
import org.junit.Assert.*
import org.junit.Test

class RoomTest {
    @Test fun straightensWobblyLShape() {
        val raw = mutableListOf<Pt>()
        for (i in 0..20) raw += Pt(100f + i * 10f, 100f + (if (i % 2 == 0) 2f else -2f))
        for (i in 1..15) raw += Pt(300f + (if (i % 2 == 0) 2f else -2f), 100f + i * 10f)
        val r = Straighten.run(raw)!!
        assertFalse(r.closed)
        assertEquals(3, r.pts.size)
        assertEquals(r.pts[0].y, r.pts[1].y, 0.01f)
        assertEquals(r.pts[1].x, r.pts[2].x, 0.01f)
    }

    @Test fun closesRectangle() {
        val raw = mutableListOf<Pt>()
        for (i in 0..10) raw += Pt(100f + i * 20f, 100f)
        for (i in 1..10) raw += Pt(300f, 100f + i * 15f)
        for (i in 1..10) raw += Pt(300f - i * 20f, 250f)
        for (i in 1..9) raw += Pt(100f, 250f - i * 15f)
        raw += Pt(102f, 102f)
        val r = Straighten.run(raw)!!
        assertTrue(r.closed)
        assertEquals(4, r.pts.size)
    }

    @Test fun tinyStrokeIgnored() {
        assertNull(Straighten.run(listOf(Pt(0f, 0f), Pt(3f, 3f))))
    }

    private fun room() = RoomObj(
        photoId = null, pts = listOf(Pt(0f, 0f), Pt(100f, 0f), Pt(100f, 100f)), closed = false,
        segs = List(2) { Seg() }, color = 0xFF000000.toInt(), width = 2f,
    )

    @Test fun readingsFillSegmentsInOrder() {
        val sheet = Sheet(objs = listOf(room()))
        val note = Note(name = "t", pages = listOf(sheet))
        val st = EditorState(note)
        val id = st.sheet.objs[0].id
        st.selectSeg(id, 0)
        st.assignReading(Reading(mm = 1500.0, source = MeasureSource.BLUETOOTH, timeMs = 1L))
        assertEquals(1, st.selectedSeg)
        st.setSegKind(id, 1, SegKind.SINK)
        st.assignReading(Reading(mm = 600.0, source = MeasureSource.BLUETOOTH, timeMs = 2L))
        val r = st.sheet.objs[0] as RoomObj
        assertEquals(1500.0, r.segs[0].valueMm!!, 0.0)
        assertEquals(SegKind.SINK, r.segs[1].kind)
        assertEquals(600.0, r.segs[1].valueMm!!, 0.0)
    }

    @Test fun jsonRoundTrip() {
        val r = room().copy(segs = listOf(Seg(SegKind.PANEL, 1234.0, MeasureSource.BLUETOOTH), Seg(SegKind.BASIN)))
        val n = Note(name = "t", pages = listOf(Sheet(objs = listOf(r))))
        val back = Json.noteFromJson(Json.noteToJson(n))
        val b = back.pages[0].objs[0] as RoomObj
        assertEquals(r.segs, b.segs)
        assertEquals(r.pts, b.pts)
    }
}
