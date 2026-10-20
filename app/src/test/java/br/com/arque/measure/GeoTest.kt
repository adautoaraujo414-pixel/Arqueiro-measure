package br.com.arque.measure

import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Sheet
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class GeoTest {
    private fun photo(rot: Float = 0f) =
        PhotoObj(id = "p", file = "a.jpg", pxW = 4000, pxH = 3000, cx = 400f, cy = 500f, w = 400f, h = 300f, rot = rot)

    private fun close(a: Pt, b: Pt, eps: Float = 0.01f) {
        assertEquals(a.x, b.x, eps)
        assertEquals(a.y, b.y, eps)
    }

    @Test fun `local para folha e de volta e identidade mesmo girado`() {
        for (rot in listOf(0f, 33f, 90f, 200f)) {
            val p = photo(rot)
            val s = Geo.photoLocalToSheet(p, 0.3f, 0.8f)
            close(Pt(0.3f, 0.8f), Geo.photoSheetToLocal(p, s), 1e-4f)
        }
    }

    @Test fun `contem pontos dentro e fora da foto girada`() {
        val p = photo(90f)
        assertTrue(Geo.photoContains(p, Pt(400f, 500f)))
        assertFalse(Geo.photoContains(p, Pt(900f, 900f)))
    }

    @Test fun `cota vinculada acompanha mover redimensionar e girar a foto`() {
        val p = photo()
        val dim = DimObj(id = "d", photoId = "p", a = Pt(0.1f, 0.5f), b = Pt(0.9f, 0.5f), valueMm = 2345.0, color = 0, width = 3f)
        val sheet = Sheet(objs = listOf(p, dim))
        val before = Geo.annPoints(sheet.photos(), dim)

        val moved = Geo.translate(sheet, p, 50f, -20f) as PhotoObj
        val after = Geo.annPoints(mapOf("p" to moved), dim)
        close(Pt(before[0].x + 50f, before[0].y - 20f), after[0])
        // a medida real não muda
        assertEquals(2345.0, dim.valueMm!!, 0.0)

        val bigger = moved.copy(w = moved.w * 2, h = moved.h * 2)
        val afterBig = Geo.annPoints(mapOf("p" to bigger), dim)
        val lenBefore = Math.hypot((after[1].x - after[0].x).toDouble(), (after[1].y - after[0].y).toDouble())
        val lenAfter = Math.hypot((afterBig[1].x - afterBig[0].x).toDouble(), (afterBig[1].y - afterBig[0].y).toDouble())
        assertEquals(lenBefore * 2, lenAfter, 0.01)
    }

    @Test fun `folha mantem o tamanho do papel`() {
        val s = Sheet()
        assertEquals(794f, s.width, 0f)
        assertEquals(1123f, s.height, 0f)
        val grown = s.copy(objs = listOf(photo().copy(w = 5000f, h = 4000f)))
        assertEquals(794f, grown.width, 0f)
        assertEquals(1123f, grown.height, 0f)
    }

    @Test fun `redimensionar pelo canto mantem proporcao e canto oposto`() {
        val p = photo()
        val anchor = Geo.photoLocalToSheet(p, 0f, 0f) // oposto ao canto 2 (BR)
        val target = Geo.photoLocalToSheet(p, 1f, 1f).let { Pt(it.x + 100f, it.y + 75f) }
        val r = Geo.resizeFromCorner(p, 2, target, maxSide = 4000f)
        assertEquals(p.w / p.h, r.w / r.h, 1e-3f)
        close(anchor, Geo.photoLocalToSheet(r, 0f, 0f), 0.05f)
        assertTrue(r.w > p.w)
    }

    @Test fun `teste de toque acha a cota e respeita a ordem de camadas`() {
        val p = photo()
        val dim = DimObj(id = "d", photoId = null, a = Pt(100f, 100f), b = Pt(300f, 100f), color = 0, width = 3f)
        val sheet = Sheet(objs = listOf(p.copy(cx = 200f, cy = 100f), dim))
        assertEquals("d", Geo.hit(sheet, Pt(200f, 102f), 10f, LengthUnit.M))
        assertEquals("p", Geo.hit(sheet, Pt(200f, 180f), 10f, LengthUnit.M))
        assertNull(Geo.hit(sheet, Pt(700f, 1000f), 10f, LengthUnit.M))
    }

    @Test fun `alinha na horizontal e vertical perto do eixo`() {
        val a = Pt(0f, 0f)
        assertEquals(0f, Geo.snapAxis(a, Pt(100f, 2f)).y, 0f)
        assertEquals(0f, Geo.snapAxis(a, Pt(2f, 100f)).x, 0f)
        assertNotNull(Geo.snapAxis(a, Pt(100f, 60f)))
        assertEquals(60f, Geo.snapAxis(a, Pt(100f, 60f)).y, 0f)
    }
}
