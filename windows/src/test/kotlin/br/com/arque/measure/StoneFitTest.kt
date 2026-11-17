package br.com.arque.measure

import br.com.arque.measure.logic.StoneFit
import br.com.arque.measure.model.Pt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.hypot

class StoneFitTest {
    /** Pedra em L desenhada à mão (fora de proporção). */
    private val pts = listOf(Pt(0f, 0f), Pt(500f, 0f), Pt(500f, 120f), Pt(200f, 120f), Pt(200f, 400f), Pt(0f, 400f))

    private fun lens(p: List<Pt>) = p.indices.map { k -> val a = p[k]; val b = p[(k + 1) % p.size]; hypot((b.x - a.x).toDouble(), (b.y - a.y).toDouble()) }

    @Test fun ladosFicamProporcionaisAsMedidas() {
        val mm = listOf(3600.0, 605.0, 2951.0, 1273.0, 649.0, 1878.0)
        val r = StoneFit.fit(pts, true, mm)!!
        val l = lens(r)
        val k0 = l[0] / mm[0]
        l.indices.forEach { assertEquals("lado $it", 1.0, l[it] / mm[it] / k0, 0.002) }
        // cantos continuam em esquadro
        r.indices.forEach { k ->
            val a = r[k]; val b = r[(k + 1) % r.size]
            val ang = Math.toDegrees(atan2((b.y - a.y).toDouble(), (b.x - a.x).toDouble()))
            assertTrue("ângulo $ang", abs(ang % 90.0) < 0.05 || abs(abs(ang % 90.0) - 90.0) < 0.05)
        }
    }

    @Test fun ladoQueFaltaFechaAPedraEConfereAMedida() {
        val mm = listOf(3600.0, 605.0, 2951.0, null, 649.0, 1878.0)
        val r = StoneFit.fit(pts, true, mm)!!
        val l = lens(r)
        val s = l[0] / 3600.0
        assertEquals(1273.0, l[3] / s, 1.0)
        val c = StoneFit.check(pts, true, mm)
        assertEquals(1273.0, c.derived[3]!!, 0.01)
        assertEquals(1, c.missing)
        assertEquals(0.0, c.gapX!!, 0.01)
    }

    @Test fun medidasQueNaoFechamAvisam() {
        val mm = listOf(3611.0, 605.0, 2951.0, 1272.0, 649.0, 1878.0)
        val c = StoneFit.check(pts, true, mm)
        assertEquals(11.0, c.gapX!!, 0.01)
        assertEquals(1.0, c.gapY!!, 0.01)
        assertNotNull(StoneFit.fit(pts, true, mm))
    }

    @Test fun semMedidaNaoMexe() {
        assertNull(StoneFit.fit(pts, true, List(6) { null }))
    }
}
