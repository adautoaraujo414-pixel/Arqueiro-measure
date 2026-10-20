package br.com.arque.measure

import br.com.arque.measure.data.Json
import br.com.arque.measure.logic.CabinetMath
import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.model.*
import org.junit.Assert.*
import org.junit.Test

class CabinetTest {
    private val base = Cabinet(
        dividers = listOf(0.5f),
        vaos = listOf(Vao(VaoKind.SHELVES, shelves = 1), Vao(VaoKind.DRAWERS, drawers = 3)),
    )

    @Test fun drawerFrontMatchesPromobFormula() {
        // vão = 720-100-80-18 = 522; (522 - 2 - 2 - 3*2) / 3
        assertEquals(522.0, CabinetMath.vaoH(base), 1e-9)
        assertEquals((522.0 - 4 - 6) / 3, CabinetMath.drawerFrontH(base, 3), 1e-9)
    }

    @Test fun changingWidthRecentersDivider() {
        val wide = base.copy(wMm = 1000.0)
        val r = CabinetMath.vaoRanges(wide)
        assertEquals(2, r.size)
        assertEquals(r[0].second - r[0].first, r[1].second - r[1].first - 0.0, 20.0)
        assertTrue(r[1].second == 1000.0 - 18.0)
    }

    @Test fun partsAndCutList() {
        val parts = CabinetMath.parts(base)
        assertEquals(2, parts.count { it.kind == PartKind.LATERAL })
        assertEquals(1, parts.count { it.kind == PartKind.DIVISORIA })
        assertEquals(3, parts.count { it.kind == PartKind.FRENTE_GAVETA })
        val list = CabinetMath.cutList(base)
        assertEquals(3, list.first { it.kind == PartKind.FRENTE_GAVETA }.qty)
        assertEquals(2, list.first { it.kind == PartKind.LATERAL }.qty)
        assertNotNull(list.firstOrNull { it.kind == PartKind.FUNDO })
    }

    @Test fun normalizeFixesVaoCount() {
        val c = CabinetMath.normalized(Cabinet(dividers = listOf(0.3f, 0.7f), vaos = listOf(Vao())))
        assertEquals(3, c.vaos.size)
    }

    @Test fun updateAndJsonRoundTrip() {
        val st = EditorState(Note(name = "t", pages = listOf(Sheet())))
        val id = st.addCab(Pt(50f, 50f), base, "Base 800")
        st.updateCab(id) { it.copy(wMm = 900.0) }
        val o = st.sheet.obj(id) as CabObj
        assertEquals(900.0, o.cab.wMm, 0.0)
        val back = Json.noteFromJson(Json.noteToJson(st.note))
        val b = back.pages[0].objs[0] as CabObj
        assertEquals(o.cab, b.cab)
        assertEquals("Base 800", b.name)
        st.undo()
        assertEquals(800.0, (st.sheet.obj(id) as CabObj).cab.wMm, 0.0)
    }
}
