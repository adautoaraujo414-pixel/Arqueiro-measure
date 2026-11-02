package br.com.arque.measure

import br.com.arque.measure.logic.CutOptimizer
import br.com.arque.measure.logic.CutOptimizer.Piece
import org.junit.Assert.*
import org.junit.Test

class CutOptimizerTest {
    private fun noOverlap(s: CutOptimizer.Sheet, kerf: Double) {
        val p = s.placed
        for (i in p.indices) {
            assertTrue(p[i].x >= -1e-6 && p[i].y >= -1e-6 && p[i].x + p[i].w <= s.w + 1e-6 && p[i].y + p[i].h <= s.h + 1e-6)
            for (j in i + 1 until p.size) {
                val a = p[i]; val b = p[j]
                val apart = a.x + a.w + kerf <= b.x + 1e-6 || b.x + b.w + kerf <= a.x + 1e-6 ||
                    a.y + a.h + kerf <= b.y + 1e-6 || b.y + b.h + kerf <= a.y + 1e-6
                assertTrue("peças ${a.label} e ${b.label} sem folga da serra", apart)
            }
        }
    }

    @Test fun fitsSimpleCaseAndKeepsKerf() {
        val pieces = List(2) { Piece("Lateral", 655.0, 580.0) } + listOf(Piece("Base", 770.0, 580.0), Piece("Travessa", 770.0, 70.0))
        val r = CutOptimizer.run(pieces, 2750.0, 1840.0, 4.0, false)
        assertEquals(1, r.sheets.size)
        assertEquals(4, r.sheets[0].placed.size)
        assertTrue(r.tooBig.isEmpty())
        noOverlap(r.sheets[0], 4.0)
    }

    @Test fun opensSecondSheetAndNeverOverlaps() {
        val pieces = List(20) { Piece("P$it", 900.0 + it * 10, 600.0) }
        val r = CutOptimizer.run(pieces, 2750.0, 1840.0, 4.0, true)
        assertTrue(r.sheets.size >= 2)
        assertEquals(20, r.sheets.sumOf { it.placed.size })
        r.sheets.forEach { noOverlap(it, 4.0) }
    }

    @Test fun reportsPieceBiggerThanSheet() {
        val r = CutOptimizer.run(listOf(Piece("Gigante", 3000.0, 2000.0)), 2750.0, 1840.0, 4.0, true)
        assertEquals(1, r.tooBig.size)
        assertEquals(0, r.sheets.size)
    }

    @Test fun rotationOnlyWhenAllowed() {
        val p = listOf(Piece("Longa", 1900.0, 300.0))
        assertEquals(1, CutOptimizer.run(p, 2750.0, 1840.0, 4.0, false).sheets.size)
        val r = CutOptimizer.run(listOf(Piece("Alta", 300.0, 2000.0)), 2750.0, 1840.0, 4.0, false)
        assertEquals(1, r.tooBig.size)
        assertEquals(1, CutOptimizer.run(listOf(Piece("Alta", 300.0, 2000.0)), 2750.0, 1840.0, 4.0, true).sheets.size)
    }

    @Test fun cutsAreFullWidthGuillotineSteps() {
        val r = CutOptimizer.run(listOf(Piece("A", 1000.0, 500.0), Piece("B", 1000.0, 500.0)), 2750.0, 1840.0, 4.0, false)
        val s = r.sheets[0]
        assertTrue(s.cuts.isNotEmpty())
        s.cuts.forEachIndexed { i, c -> assertEquals(i + 1, c.step) }
    }
}
