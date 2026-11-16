package br.com.arque.measure.desktop

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.ui.EditorSession
import br.com.arque.measure.ui.SheetCache
import br.com.arque.measure.ui.SheetRenderer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * PROTOCOLO DE PERFORMANCE (16/11) · caderno no Android e no Windows (o mesmo código).
 * Antes: a folha inteira (traços, fotos, papel) era desenhada de novo a cada ponto do traço.
 * Agora (SheetCache, igual ao iPhone): escrevendo, a imagem guardada da folha vai pra tela e só o traço novo é desenhado por cima;
 * soltou, o traço é somado à imagem. Confere: o desenho é igual ao direto (pixel a pixel), a folha inteira é desenhada 1 vez só
 * no traço todo, e o tempo por ponto cai.
 */
class CadernoDesempenhoTest {
    private val W = 1200
    private val H = 1700
    private val esc = 1.45f

    private fun foto(w: Int, h: Int): Bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also { b ->
        val c = Canvas(b); c.drawColor(0xFFDDE3EA.toInt())
        c.drawRect(w * 0.2f, h * 0.3f, w * 0.8f, h * 0.8f, Paint().apply { color = 0xFF8A5A2B.toInt() })
    }

    private fun folhaCheia(tracos: Int): Sheet {
        val r = java.util.Random(7)
        val objs = ArrayList<Obj>()
        objs += PhotoObj(id = "f1", file = "f1", pxW = 3000, pxH = 2000, cx = 250f, cy = 330f, w = 380f, h = 250f)
        objs += PhotoObj(id = "f2", file = "f2", pxW = 3000, pxH = 2000, cx = 560f, cy = 330f, w = 380f, h = 250f)
        for (i in 0 until tracos) {
            val x0 = 40f + r.nextFloat() * 700f; val y0 = 480f + r.nextFloat() * 600f
            val pts = (0 until 60).map { k -> Pt(x0 + k * 0.9f + r.nextFloat() * 2f, y0 + (Math.sin(k / 4.0) * 6).toFloat()) }
            objs += StrokeObj(photoId = null, pts = pts, color = 0xFF1E5BD8.toInt(), width = 2.1f)
        }
        return Sheet(objs = objs)
    }

    private val fotos = mapOf("f1" to foto(3000, 2000), "f2" to foto(3000, 2000))
    private val rd = SheetRenderer { fotos[it] }

    /** Um quadro da tela: com a imagem guardada (como no app) ou direto (como era). Devolve o tempo em ms. */
    private fun quadro(tela: Bitmap, s: EditorSession, cache: SheetCache, live: String?): Double {
        val c = Canvas(tela)
        val st = s.state; val v = s.view
        val t0 = System.nanoTime()
        c.drawColor(0xFF1E2025.toInt())
        val full = { cc: Canvas, skip: String? -> cc.save(); cc.translate(v.ox, v.oy); cc.scale(v.scale, v.scale); rd.draw(cc, st.sheet, st.unit, st.selectedId, v.scale, skipId = skip); cc.restore() }
        val ok = cache.paint(c, W, H, s, live, 0, 0xFF1E2025.toInt(), full = full, one = { cc, id ->
            cc.save(); cc.translate(v.ox, v.oy); cc.scale(v.scale, v.scale); rd.drawOne(cc, st.sheet, st.unit, id); cc.restore()
        })
        if (!ok) full(c, null)
        return (System.nanoTime() - t0) / 1e6
    }

    private fun iguais(a: Bitmap, b: Bitmap): Int { var dif = 0; var y = 0; while (y < H) { var x = 0; while (x < W) { if (a.getPixel(x, y) != b.getPixel(x, y)) dif++; x += 3 }; y += 3 }; return dif }

    @Test fun escreverNaFolhaCheiaSoDesenhaOTracoNovoEOResultadoEIgual() {
        val s = EditorSession(Note(name = "Teste", pages = listOf(folhaCheia(600)))) {}
        s.view.scale = esc; s.view.ox = 20f; s.view.oy = 10f
        val st = s.state
        val cache = SheetCache(); val direto = SheetCache().also { it.off = true }
        val telaC = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888); val telaD = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888)
        quadro(telaC, s, cache, null); quadro(telaC, s, cache, null) // abriu a folha: a câmera parou, a imagem é feita uma vez
        assertEquals(1, cache.fullRenders)
        // escreve um traço de 120 pontos, ponto a ponto
        val id = "vivo"
        st.beginGesture()
        val tC = ArrayList<Double>(); val tD = ArrayList<Double>()
        for (n in 2..120) {
            val pts = (0 until n).map { Pt(100f + it * 2.5f, 900f + (Math.sin(it / 5.0) * 20).toFloat()) }
            st.live(st.sheet.copy(objs = st.sheet.objs.filter { it.id != id } + StrokeObj(id = id, photoId = null, pts = pts, color = 0xFF000000.toInt(), width = 2f)))
            tC += quadro(telaC, s, cache, id)
            tD += quadro(telaD, s, direto, id)
        }
        assertEquals("no traço todo a folha inteira não é desenhada de novo", 1, cache.fullRenders)
        assertEquals("o que aparece escrevendo é igual ao desenho direto", 0, iguais(telaC, telaD))
        st.endGesture()
        quadro(telaC, s, cache, null); quadro(telaD, s, direto, null)
        assertEquals("soltou: o traço entra na imagem guardada, sem redesenhar a folha", 1, cache.bakes)
        assertEquals(1, cache.fullRenders)
        assertEquals("depois de soltar também é igual ao direto", 0, iguais(telaC, telaD))
        // desfazer muda a folha parada: a imagem é refeita uma vez e continua igual ao direto
        st.undo(); quadro(telaC, s, cache, null); quadro(telaD, s, direto, null)
        assertEquals(2, cache.fullRenders)
        assertEquals(0, iguais(telaC, telaD))
        val mC = tC.drop(10).sorted()[tC.size / 2 - 5]; val mD = tD.drop(10).sorted()[tD.size / 2 - 5]
        println("CADERNO folha com 600 traços + 2 fotos · por ponto do traço: antes (folha inteira) ${"%.1f".format(mD)} ms · agora ${"%.1f".format(mC)} ms (mediana)")
        assertTrue("escrevendo, o quadro fica bem mais leve que desenhar a folha inteira (${"%.1f".format(mC)} × ${"%.1f".format(mD)} ms)", mC < mD * 0.6)
    }

    @Test fun cameraMexendoDesenhaDiretoComoEra() {
        val s = EditorSession(Note(name = "Teste", pages = listOf(folhaCheia(50)))) {}
        val cache = SheetCache(); val tela = Bitmap.createBitmap(W, H, Bitmap.Config.ARGB_8888)
        quadro(tela, s, cache, null)
        for (i in 1..10) { s.view.ox = i * 5f; quadro(tela, s, cache, null) }
        assertEquals("arrastando a folha não fica refazendo a imagem guardada a cada quadro", 0, cache.fullRenders)
        quadro(tela, s, cache, null)
        assertEquals("parou: refaz uma vez", 1, cache.fullRenders)
    }
}
