package br.com.arque.measure

import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.WallFit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class CabWallTest {
    private fun cab(off: Double = 0.0) = CabObj(
        at = Pt(0f, 0f), cab = Cabinet(wMm = 800.0),
        wall = WallFit("r", 0, 100f, 100f, 1f, 0f, 0f, 1f, 0.1, 3000.0, off),
    )

    @Test fun slidesAlongWallAndClamps() {
        val c = cab().slide(50f, 999f) // só o componente ao longo da parede conta
        assertEquals(500.0, c.wall!!.offMm, 0.01)
        assertEquals(2200.0, cab().slide(1e6f, 0f).wall!!.offMm, 0.01) // 3000 - 800
        assertEquals(0.0, cab().slide(-1e6f, 0f).wall!!.offMm, 0.01)
    }

    @Test fun overflowWhenWiderThanWall() {
        assertTrue(cab().copy(cab = Cabinet(wMm = 3200.0)).overflowsWall())
        assertTrue(!cab().overflowsWall())
    }

    @Test fun footprintUsesMeasuredScale() {
        val c = cab()
        assertEquals(80f, c.widthUnits(), 0.01f) // 800 mm × 0.1
    }
}
