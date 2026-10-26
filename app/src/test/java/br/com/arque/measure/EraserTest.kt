package br.com.arque.measure

import br.com.arque.measure.data.Json
import br.com.arque.measure.logic.Eraser
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.DoorObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.Seg
import br.com.arque.measure.model.SegKind
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.Sheet
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Borracha normal (apaga o rastro em linhas, formas e paredes) e escrita em pé/deitada. */
class EraserTest {
    private val room = RoomObj(
        photoId = null, pts = listOf(Pt(0f, 0f), Pt(400f, 0f), Pt(400f, 300f), Pt(0f, 300f)), closed = true,
        segs = listOf(Seg(SegKind.WALL, 4000.0), Seg(SegKind.WALL, 3000.0), Seg(SegKind.DOOR), Seg(SegKind.WALL)), color = 0, width = 2f,
    )

    @Test fun `borracha numa parede tira so aquele trecho e o resto fica aberto com as medidas`() {
        val pieces = Eraser.roomPieces(room, room.pts, Pt(200f, 0f), 5f)!!
        assertEquals(1, pieces.size)
        val (verts, segs) = pieces[0]
        assertEquals(listOf(1, 2, 3), segs)
        assertEquals(listOf(1, 2, 3, 0), verts)
    }

    @Test fun `borracha longe da parede nao muda nada`() {
        assertNull(Eraser.roomPieces(room, room.pts, Pt(200f, 150f), 5f))
    }

    @Test fun `contorno aberto apagado no meio vira dois pedacos`() {
        val open = room.copy(closed = false)
        val pieces = Eraser.roomPieces(open, open.pts, Pt(400f, 150f), 5f)!!
        assertEquals(listOf(listOf(0), listOf(2)), pieces.map { it.second })
    }

    @Test fun `retangulo vira contorno fechado e a borracha corta um pedaco`() {
        val o = Eraser.shapeOutline(ShapeKind.RECT, Pt(0f, 0f), Pt(100f, 50f))
        assertEquals(o.first(), o.last())
        val pieces = Eraser.erasePieces(o, Pt(50f, 0f), 6f)!!
        assertTrue(pieces.isNotEmpty())
        assertTrue(pieces.none { pc -> pc.any { kotlin.math.hypot(it.x - 50f, it.y) < 6f } })
    }

    @Test fun `quadradinho em pe troca largura por altura e salva`() {
        val a = Pt(0f, 0f); val b = Pt(0f, 300f)
        val h = Geo.dimLabelBox(a, b, "Parede")
        val v = Geo.dimLabelBox(a, b, "Parede", vert = true)
        assertEquals(h.r - h.l, v.b - v.t, 0.01f)
        val d = DoorObj(a = a, b = b, labelScale = 0.5f, labelVert = true)
        val back = Json.noteFromJson(Json.noteToJson(br.com.arque.measure.model.Note(name = "t", pages = listOf(Sheet(objs = listOf(d, room.copy(labelVert = true))))))).pages[0].objs
        assertEquals(0.5f, (back[0] as DoorObj).labelScale, 0.001f)
        assertTrue((back[0] as DoorObj).labelVert)
        assertTrue((back[1] as RoomObj).labelVert)
    }
}
