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

    @Test fun doorInsideWallKeepsVerticesAndSense() {
        val wall = RoomObj(photoId = null, pts = listOf(Pt(0f, 0f), Pt(300f, 0f)), closed = false, segs = listOf(Seg()), color = 0, width = 2f)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(wall)))))
        st.splitSeg(wall.id, 0, SegKind.DOOR)
        var r = st.sheet.objs[0] as RoomObj
        assertEquals(4, r.pts.size)
        assertEquals(listOf(SegKind.WALL, SegKind.DOOR, SegKind.WALL), r.segs.map { it.kind })
        assertEquals(1, st.selectedSeg)
        // unir pontos soltos não pode apagar a porta (pontos em linha reta, mas tipos diferentes)
        st.mergeRoomStray(wall.id)
        r = st.sheet.objs[0] as RoomObj
        assertEquals(4, r.pts.size)
        st.setSegDoor(wall.id, 1, hinge = 1, side = -1, slide = true)
        r = st.sheet.objs[0] as RoomObj
        assertEquals(1, r.segs[1].hinge); assertEquals(-1, r.segs[1].side); assertTrue(r.segs[1].slide)
        val back = Json.noteFromJson(Json.noteToJson(Note(name = "t", pages = listOf(st.sheet)))).pages[0].objs[0] as RoomObj
        assertEquals(r.segs, back.segs)
    }

    @Test fun newWallAlignsWithExistingCorners() {
        // parede nova quase em cima da linha x=100 de uma parede que já existe: a junta fica reta
        val refs = listOf(Pt(100f, 0f), Pt(100f, 300f), Pt(400f, 300f))
        val drawn = listOf(Pt(104f, 300f), Pt(104f, 600f), Pt(396f, 600f))
        val r = Straighten.alignTo(drawn, false, refs, 10f)
        assertEquals(100f, r[0].x, 0.01f); assertEquals(100f, r[1].x, 0.01f) // parede vertical inteira foi junto
        assertEquals(400f, r[2].x, 0.01f)
        assertEquals(600f, r[1].y, 0.01f); assertEquals(600f, r[2].y, 0.01f)
    }

    @Test fun doorUsesMeasuredWallForWidth() {
        val wall = RoomObj(photoId = null, pts = listOf(Pt(0f, 0f), Pt(400f, 0f)), closed = false, segs = listOf(Seg(valueMm = 4000.0, source = MeasureSource.BLUETOOTH)), color = 0, width = 2f)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(wall)))))
        st.splitSeg(wall.id, 0, SegKind.DOOR)
        val r = st.sheet.objs[0] as RoomObj
        assertEquals(80f, r.pts[2].x - r.pts[1].x, 0.01f) // 800 de 4000 = 20% do traço de 400
        assertTrue(r.segs.all { it.valueMm == null })
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

    private fun line(raw: MutableList<Pt>, a: Pt, b: Pt, n: Int, seed: Int, amp: Float) {
        val rnd = java.util.Random(seed.toLong())
        for (i in 1..n) {
            val t = i / n.toFloat()
            raw += Pt(a.x + (b.x - a.x) * t + (rnd.nextFloat() - 0.5f) * amp, a.y + (b.y - a.y) * t + (rnd.nextFloat() - 0.5f) * amp)
        }
    }

    @Test fun closedLShapeHasNoStrayVertexOnStraightEdges() {
        for (seed in 1..60) for (amp in listOf(2f, 5f)) {
            val tl = Pt(100f, 100f); val tr = Pt(420f, 112f); val br = Pt(405f, 190f)
            val nt = Pt(250f, 172f); val nb = Pt(245f, 250f); val bl = Pt(95f, 235f)
            val raw = mutableListOf(Pt(250f, 105f)) // começa no meio da borda de cima
            line(raw, Pt(250f, 105f), tr, 12, seed, amp)
            line(raw, tr, br, 8, seed + 1, amp)
            line(raw, br, nt, 14, seed + 2, amp)
            line(raw, nt, nb, 8, seed + 3, amp)
            line(raw, nb, bl, 12, seed + 4, amp)
            line(raw, bl, tl, 14, seed + 5, amp)
            line(raw, tl, Pt(250f, 105f), 14, seed + 6, amp)
            val r = Straighten.run(raw, closeTol = 40f, eps = 10f, minSeg = 22f)!!
            assertTrue("seed $seed amp $amp", r.closed)
            assertEquals("seed $seed amp $amp pts=${r.pts}", 6, r.pts.size)
        }
    }

    @Test fun mergeStrayKeepsCornersAndSumsMeasures() {
        val st = EditorState(Note(name = "t", pages = listOf(Sheet())))
        val pts = listOf(Pt(0f, 0f), Pt(100f, 3f), Pt(200f, 0f), Pt(200f, 100f), Pt(0f, 100f))
        val room = RoomObj(photoId = null, pts = pts, closed = true,
            segs = listOf(Seg(valueMm = 1000.0), Seg(valueMm = 1500.0), Seg(valueMm = 800.0), Seg(valueMm = 2500.0), Seg(valueMm = 800.0)),
            color = 0, width = 2f)
        st.addRoom(room)
        assertTrue(st.mergeRoomStray(room.id))
        val r = st.sheet.obj(room.id) as RoomObj
        assertEquals(4, r.pts.size)
        assertEquals(4, r.segs.size)
        assertEquals(2500.0, r.segs[0].valueMm!!, 0.0)
    }

    @Test fun manualValueIsMarkedManual() {
        val d = DimObj(photoId = null, a = Pt(0f, 0f), b = Pt(100f, 0f), color = 0, width = 2f)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(d)))))
        st.select(d.id)
        assertNotNull(st.setManualValue(2500.0))
        val r = st.sheet.obj(d.id) as DimObj
        assertEquals(2500.0, r.valueMm!!, 0.0)
        assertEquals(MeasureSource.MANUAL, r.source)
    }
}
