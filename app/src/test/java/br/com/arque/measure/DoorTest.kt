package br.com.arque.measure

import br.com.arque.measure.data.Json
import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.DoorObj
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.Seg
import br.com.arque.measure.model.Sheet
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Porta marcada num trecho da linha (não na linha inteira). */
class DoorTest {
    private val room = RoomObj(photoId = null, pts = listOf(Pt(0f, 0f), Pt(400f, 0f), Pt(400f, 300f), Pt(0f, 300f)), closed = true, segs = List(4) { Seg() }, color = 0, width = 2f)

    @Test fun `acha a linha da parede e projeta o ponto em cima dela`() {
        val sheet = Sheet(objs = listOf(room))
        val host = Geo.nearestLine(sheet, Pt(150f, 8f), 20f)
        assertNotNull(host)
        val p = Geo.projectOnSegment(Pt(150f, 8f), host!!.first, host.second)
        assertEquals(150f, p.x, 0.01f); assertEquals(0f, p.y, 0.01f)
    }

    @Test fun `porta guarda sentido e medida e volta igual do JSON`() {
        val d = DoorObj(a = Pt(100f, 0f), b = Pt(180f, 0f))
        val st = EditorState(Note(name = "t", pages = listOf(Sheet(objs = listOf(room, d)))))
        st.select(d.id)
        st.setDoor(d.id, hinge = 1, side = -1)
        st.assignReading(Reading(mm = 820.0, source = MeasureSource.BLUETOOTH, timeMs = 1))
        val got = st.sheet.obj(d.id) as DoorObj
        assertEquals(1, got.hinge); assertEquals(-1, got.side); assertEquals(820.0, got.valueMm!!, 0.0)
        // a parede continua inteira (a porta é só um trecho por cima)
        assertEquals(4, (st.sheet.obj(room.id) as RoomObj).segs.size)
        val back = Json.noteFromJson(Json.noteToJson(st.note))
        assertEquals(got, back.pages[0].obj(d.id))
        assertTrue(Geo.hitObj(st.sheet, got, Pt(140f, 1f), 10f, st.unit))
    }
}
