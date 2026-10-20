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
        // base sob as laterais: vão = (850-100-15) - (15+70) = 650; (650 - 2 - 2 - 3*2) / 3
        assertEquals(650.0, CabinetMath.vaoH(base), 1e-9)
        assertEquals((650.0 - 4 - 6) / 3, CabinetMath.drawerFrontH(base, 3), 1e-9)
    }

    @Test fun changingWidthRecentersDivider() {
        val wide = base.copy(wMm = 1000.0)
        val r = CabinetMath.vaoRanges(wide)
        assertEquals(2, r.size)
        assertEquals(r[0].second - r[0].first, r[1].second - r[1].first - 0.0, 20.0)
        assertTrue(r[1].second == 1000.0 - 15.0)
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

    @Test fun baseIsOnePieceFullWidthUnderLaterals() {
        val parts = CabinetMath.parts(base)
        val b = parts.single { it.kind == PartKind.BASE }
        assertEquals(base.wMm, b.w, 1e-9)
        val lat = parts.first { it.kind == PartKind.LATERAL }
        assertEquals(b.y, lat.y + lat.h, 1e-9) // lateral apoiada em cima da base
        assertEquals(750.0 - 15.0 - 15.0, lat.h, 1e-9) // 720
    }

    @Test fun frontCrossbarSameWidthAs70mm() {
        val t = CabinetMath.parts(base).single { it.kind == PartKind.TRAVESSA }
        assertEquals(base.wMm, t.w, 1e-9)
        assertEquals(70.0, t.h, 1e-9)
        assertTrue(CabinetMath.parts(base).filter { it.kind == PartKind.LATERAL }.all { it.note.contains("rebaixo") })
    }

    @Test fun moldingIsWidthBy30AndOptional() {
        val m = CabinetMath.parts(base).single { it.kind == PartKind.MOLDURA }
        assertEquals(base.wMm, m.w, 1e-9); assertEquals(30.0, m.h, 1e-9)
        assertTrue(CabinetMath.parts(base.copy(hasMoldura = false)).none { it.kind == PartKind.MOLDURA })
    }

    @Test fun stoneWidthMinus40() {
        assertEquals(2660.0, 2700.0 - CabinetMath.DESCONTO_PEDRA_MM, 0.0)
    }

    @Test fun liveDragMovesDividerAsOneUndoStep() {
        val st = EditorState(Note(name = "t", pages = listOf(Sheet())))
        val id = st.addCab(Pt(50f, 50f), base, "Base")
        st.beginGesture()
        st.liveCab(id) { it.copy(dividers = listOf(0.3f)) }
        st.liveCab(id) { it.copy(dividers = listOf(0.4f)) }
        st.endGesture()
        assertEquals(0.4f, (st.sheet.obj(id) as CabObj).cab.dividers[0], 0f)
        st.undo()
        assertEquals(0.5f, (st.sheet.obj(id) as CabObj).cab.dividers[0], 0f)
    }

    @Test fun oldJsonWithoutNewFieldsStillLoads() {
        val c = base.copy(pedraWMm = 2700.0)
        val st = EditorState(Note(name = "t", pages = listOf(Sheet())))
        st.addCab(Pt(1f, 1f), c, "x")
        val back = (Json.noteFromJson(Json.noteToJson(st.note)).pages[0].objs[0] as CabObj).cab
        assertEquals(2700.0, back.pedraWMm!!, 0.0)
        assertNull(back.pedraDMm)
    }

    @Test fun tamponamentoBothSidesDiscounts70() {
        val c = base.copy(tampEsq = true, tampDir = true)
        assertEquals(70.0, CabinetMath.descontoPedra(c), 0.0)
        assertEquals(1930.0, 2000.0 - CabinetMath.descontoPedra(c), 0.0)
        assertEquals(40.0, CabinetMath.descontoPedra(base), 0.0)
    }

    @Test fun tamponamentoSizeAndDrawerBox() {
        val c = base.copy(tampEsq = true, tampDir = true)
        val t = CabinetMath.parts(c).filter { it.kind == PartKind.TAMPONAMENTO }
        assertEquals(2, t.size)
        assertEquals(CabinetMath.lateralH(c) + 30.0, t[0].cutL, 1e-9)
        assertEquals(585.0, t[0].cutW, 1e-9)
        val vw = CabinetMath.vaoRanges(c)[1].let { it.second - it.first }
        assertTrue(CabinetMath.parts(c).first { it.kind == PartKind.FRENTE_GAVETA }.note.contains(CabinetMath.vaoRanges(c)[1].let { "%.0f".format(vw - 26.0) }.take(2)))
    }

    @Test fun twoDoorsOverlapFormula() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao(VaoKind.DOOR, doors = 2, cava = true)))
        val vw = CabinetMath.vaoRanges(c)[0].let { it.second - it.first }
        val doors = CabinetMath.parts(c).filter { it.kind == PartKind.PORTA }
        assertEquals(2, doors.size)
        assertEquals((vw + 12.0) / 2, doors[0].cutL, 1e-9)
        assertEquals(CabinetMath.vaoH(c) + 30.0, doors[0].cutW, 1e-9)
        assertTrue(doors[0].note.contains("30°"))
    }

    @Test fun drawersWithShelvesAbove() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao(VaoKind.DRAWERS, drawers = 2, shelvesAbove = 1, gaveteiroMm = 300.0)))
        val p = CabinetMath.parts(c)
        assertEquals(1, p.count { it.kind == PartKind.PRATELEIRA })
        val f = p.filter { it.kind == PartKind.FRENTE_GAVETA }
        assertEquals((300.0 - 4 - 3) / 2, f[0].cutW, 1e-9)
        val vb = CabinetMath.vaoBottom(c)
        assertTrue(f.last().y + f.last().h <= vb)
        val back = Json.noteFromJson(Json.noteToJson(Note(name = "t", pages = listOf(Sheet(objs = listOf(CabObj(id = "a", at = Pt(1f, 1f), cab = c)))))))
        assertEquals(c.vaos, (back.pages[0].objs[0] as CabObj).cab.vaos)
    }

    @Test fun cavaBatentesBetweenDrawers() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao(VaoKind.DRAWERS, drawers = 4, cava = true, batenteMm = 50.0)))
        val p = CabinetMath.parts(c)
        assertEquals(3, p.count { it.kind == PartKind.BATENTE })
        val fh = (CabinetMath.vaoH(c) - 150.0) / 4
        assertEquals(fh, p.first { it.kind == PartKind.FRENTE_GAVETA }.cutW, 1e-9)
        val sum = p.filter { it.kind == PartKind.FRENTE_GAVETA }.sumOf { it.h } + p.filter { it.kind == PartKind.BATENTE }.sumOf { it.h }
        assertEquals(CabinetMath.vaoH(c), sum, 1e-9)
    }

    @Test fun looseShelfAtChosenHeight() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao(shelfYs = listOf(400.0))))
        val s = CabinetMath.parts(c).single { it.kind == PartKind.PRATELEIRA }
        assertEquals(400.0 - 7.5, s.y, 1e-9)
        val back = Json.noteFromJson(Json.noteToJson(Note(name = "t", pages = listOf(Sheet(objs = listOf(CabObj(id = "a", at = Pt(1f, 1f), cab = c)))))))
        assertEquals(listOf(400.0), (back.pages[0].objs[0] as CabObj).cab.vaos[0].shelfYs)
    }

    @Test fun ovenCutoutCentered() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao(VaoKind.OVEN, ovenW = 560.0, ovenH = 595.0)))
        val (x0, x1) = CabinetMath.vaoRanges(c)[0]
        val o = CabinetMath.parts(c).single { it.kind == PartKind.FORNO }
        assertEquals(560.0, o.w, 0.0)
        assertEquals(o.x - x0, x1 - (o.x + o.w), 1e-9)
        assertTrue(CabinetMath.cutList(c).none { it.kind == PartKind.FORNO })
        assertEquals(1, CabinetMath.parts(c).count { it.kind == PartKind.PRATELEIRA })
    }

    @Test fun baseAndPedestalAreOptional() {
        val noRod = base.copy(hasRodape = false)
        assertTrue(CabinetMath.parts(noRod).none { it.kind == PartKind.RODAPE })
        assertEquals(850.0 - 15.0 - 15.0, CabinetMath.lateralH(noRod), 1e-9)
        val noBase = base.copy(hasBase = false)
        assertTrue(CabinetMath.parts(noBase).none { it.kind == PartKind.BASE })
        assertEquals(750.0 - 15.0, CabinetMath.lateralH(noBase), 1e-9)
        assertEquals(CabinetMath.baseBottom(noBase), CabinetMath.vaoBottom(noBase), 1e-9)
        val back = Json.noteFromJson(Json.noteToJson(Note(name = "t", pages = listOf(Sheet(objs = listOf(CabObj(id = "a", at = Pt(1f, 1f), cab = noBase.copy(hasRodape = false))))))))
        val b = (back.pages[0].objs[0] as CabObj).cab
        assertFalse(b.hasBase); assertFalse(b.hasRodape)
    }

    @Test fun splitVaoIntoEqualParts() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao()))
        val s = CabinetMath.splitVao(c, 0, 4)
        assertEquals(3, s.dividers.size)
        val w = CabinetMath.vaoRanges(s).map { it.second - it.first }
        assertEquals(4, w.size)
        assertTrue(w.all { Math.abs(it - w[0]) < 1.0 })
    }

    @Test fun addDividerAtTap() {
        val c = Cabinet(dividers = emptyList(), vaos = listOf(Vao()))
        val a = CabinetMath.addDividerAt(c, 300.0)
        val b = CabinetMath.addDividerAt(a, 600.0)
        assertEquals(2, b.dividers.size)
        assertEquals(3, b.vaos.size)
        assertEquals(300.0 - 7.5, CabinetMath.dividerX(b)[0], 1.5)
    }

    @Test fun fitCabToPageShrinksOnlyWhenTooBig() {
        val st = EditorState(Note(name = "t", pages = listOf(Sheet())))
        val id = st.addCab(Pt(10f, 10f), Cabinet(wMm = 2627.0), "Base")
        st.fitCabToPage(id)
        val o = st.sheet.obj(id) as CabObj
        assertTrue(o.widthUnits() <= 700f)
        st.setCabScale(id, 100)
        st.fitCabToPage(id)
        assertEquals(100, (st.sheet.obj(id) as CabObj).scaleDen)
    }

    @Test fun tamponamentoAlignedAtTopAndEndsAtBase() {
        val c = base.copy(tampEsq = true)
        val t = CabinetMath.parts(c).single { it.kind == PartKind.TAMPONAMENTO }
        assertEquals(0.0, t.y, 0.0)
        assertEquals(CabinetMath.baseBottom(c), t.y + t.h, 1e-9)
    }
}
