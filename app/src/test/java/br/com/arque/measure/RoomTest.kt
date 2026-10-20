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

    @Test fun mergesCollinearPointInClosedL() {
        // L fechado; o lado de cima tem uma "ponta solta" com leve quebra no fim
        val raw = mutableListOf<Pt>()
        for (i in 0..14) raw += Pt(100f + i * 20f, 100f)          // topo até x=380
        for (i in 1..4) raw += Pt(380f + i * 10f, 100f + i * 1f)  // continua quase reto
        for (i in 1..8) raw += Pt(420f, 104f + i * 12f)           // desce
        for (i in 1..12) raw += Pt(420f - i * 15f, 200f)          // volta
        for (i in 1..8) raw += Pt(240f, 200f + i * 12f)           // desce
        for (i in 1..7) raw += Pt(240f - i * 20f, 296f)           // volta
        for (i in 1..9) raw += Pt(100f, 296f - i * 21.7f)         // sobe
        raw += Pt(101f, 101f)
        val r = Straighten.run(raw)!!
        assertTrue(r.closed)
        assertEquals(6, r.pts.size)
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

class LassoTest {
    @Test fun picksOnlyObjectsInsideLoop() {
        val inside = ShapeObj(photoId = null, kind = ShapeKind.LINE, a = Pt(110f, 110f), b = Pt(190f, 190f), color = 0, width = 2f)
        val outside = ShapeObj(photoId = null, kind = ShapeKind.LINE, a = Pt(400f, 400f), b = Pt(500f, 500f), color = 0, width = 2f)
        val sheet = Sheet(objs = listOf(inside, outside))
        val loop = listOf(Pt(100f, 100f), Pt(200f, 100f), Pt(200f, 200f), Pt(100f, 200f))
        assertEquals(setOf(inside.id), br.com.arque.measure.logic.Geo.lassoPick(sheet, loop))
    }

    @Test fun deleteGroupRemovesAll() {
        val a = ShapeObj(photoId = null, kind = ShapeKind.LINE, a = Pt(1f, 1f), b = Pt(5f, 5f), color = 0, width = 2f)
        val b = ShapeObj(photoId = null, kind = ShapeKind.RECT, a = Pt(1f, 1f), b = Pt(5f, 5f), color = 0, width = 2f)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(a, b)))))
        st.selectGroup(setOf(a.id, b.id))
        st.deleteGroup()
        assertTrue(st.sheet.objs.isEmpty())
    }
}

class AllKindsTest {
    @Test fun appliesKindToEverySegment() {
        val r = RoomObj(photoId = null, pts = listOf(Pt(0f, 0f), Pt(10f, 0f), Pt(10f, 10f)), closed = false, segs = List(2) { Seg() }, color = 0, width = 2f)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(r)))))
        st.setAllSegKinds(r.id, SegKind.PANEL)
        assertTrue((st.sheet.objs[0] as RoomObj).segs.all { it.kind == SegKind.PANEL })
    }
}
