package br.com.arque.measure

import br.com.arque.measure.logic.Eraser
import br.com.arque.measure.model.Pt
import org.junit.Assert.*
import org.junit.Test

class EraserTest {
    private val line = listOf(Pt(0f, 0f), Pt(100f, 0f))

    @Test fun untouchedReturnsNull() {
        assertNull(Eraser.erasePieces(line, Pt(50f, 50f), 5f))
    }

    @Test fun middleHitSplitsInTwo() {
        val pieces = Eraser.erasePieces(line, Pt(50f, 0f), 6f)!!
        assertEquals(2, pieces.size)
        assertTrue(pieces[0].last().x < 50f)
        assertTrue(pieces[1].first().x > 50f)
    }

    @Test fun fullCoverRemovesStroke() {
        assertTrue(Eraser.erasePieces(line, Pt(50f, 0f), 80f)!!.isEmpty())
    }
}
