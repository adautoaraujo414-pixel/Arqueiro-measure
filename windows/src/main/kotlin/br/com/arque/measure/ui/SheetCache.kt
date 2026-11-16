package br.com.arque.measure.ui

import android.graphics.Bitmap
import android.graphics.Canvas
import br.com.arque.measure.model.StrokeObj

/**
 * Imagem guardada da folha do caderno, igual à do iPhone (SheetCanvas.swift).
 *
 * PROTOCOLO DE PERFORMANCE (16/11): no Android e no Windows a folha inteira (todos os traços, fotos, medidas e o papel)
 * era desenhada de novo a cada ponto do traço. Com a folha cheia ou com fotos, isso atrasava a escrita.
 *
 * - Escrevendo: a imagem guardada é posta na tela e só o traço novo é desenhado por cima.
 * - Soltou o traço: ele é somado à imagem guardada (a folha não é redesenhada).
 * - Mudou algo parado (desfazer, mover, apagar, trocar a página, foto que terminou de abrir): a imagem é refeita uma vez.
 * - Câmera mexendo (arrastar a folha, pinça), laço, borracha e outros gestos que mudam a folha a cada quadro: desenho direto, como era.
 *
 * O desenho final é o mesmo do desenho direto (conferido no teste do Windows, pixel a pixel).
 */
class SheetCache {
    private var bmp: Bitmap? = null
    private var key = ""
    private var lastCam = ""
    private var liveId: String? = null
    private var liveCam = ""
    private var liveRev = 0
    private var liveCount = 0

    /** Conferidos nos testes: folha inteira desenhada, imagem guardada aproveitada, traço somado à imagem. */
    var fullRenders = 0; private set
    var cacheHits = 0; private set
    var bakes = 0; private set
    /** Testes: desliga a imagem guardada pra comparar com o desenho direto. */
    var off = false

    /**
     * Desenha a folha com a imagem guardada. Devolve false quando é pra desenhar direto (câmera mexendo, laço, borracha…).
     * [full] desenha a cena inteira (com a câmera) sem o objeto indicado; [one] desenha só um objeto (com a câmera).
     */
    fun paint(
        nc: Canvas, w: Int, h: Int, s: EditorSession, live: String?, imagesVersion: Int, bg: Int,
        full: (Canvas, String?) -> Unit, one: (Canvas, String) -> Unit,
    ): Boolean {
        val st = s.state
        val v = s.view
        val cam = "${v.ox}|${v.oy}|${v.scale}|${v.pageOffsetY}|$w|$h|${st.pageIdx}"
        val moving = cam != lastCam
        lastCam = cam
        val lv = if (st.inGesture) live else null
        val usable = !off && !moving && (lv != null || !st.inGesture) && s.lasso.isEmpty() && s.eraserTrail.isEmpty() && w > 0 && h > 0
        if (!usable) { if (!off) liveId = null; return false }
        val k = "${s.staticRev}|$cam|$imagesVersion"
        if (bmp == null || key != k) {
            if (!bake(s, cam, k, imagesVersion, one)) rebuild(w, h, k, bg, lv, full)
        } else cacheHits++
        nc.drawBitmap(bmp!!, 0f, 0f, null)
        if (lv != null) {
            one(nc, lv)
            liveId = lv; liveCam = cam; liveRev = s.staticRev; liveCount = st.sheet.objs.size
        } else liveId = null
        return true
    }

    private fun rebuild(w: Int, h: Int, k: String, bg: Int, skip: String?, full: (Canvas, String?) -> Unit) {
        val b0 = bmp
        // a imagem antiga não é reciclada à mão: no Android a tela ainda pode estar usando ela neste quadro (fica pro coletor)
        val b = if (b0 != null && b0.width == w && b0.height == h) b0 else Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        b.eraseColor(bg)
        full(Canvas(b), skip)
        bmp = b
        key = k
        fullRenders++
    }

    /** Soltou o traço e mais nada mudou: o traço pronto é somado à imagem guardada, sem desenhar a folha inteira de novo. */
    private fun bake(s: EditorSession, cam: String, k: String, imagesVersion: Int, one: (Canvas, String) -> Unit): Boolean {
        val id = liveId ?: return false
        val b = bmp ?: return false
        if (liveCam != cam || key != "$liveRev|$cam|$imagesVersion" || s.staticRev != liveRev + 1) return false
        val st = s.state
        if (st.inGesture || st.selectedId != null || st.groupIds.isNotEmpty()) return false
        val objs = st.sheet.objs
        // o traço ficou como o último da folha, ou o gesto foi cancelado e a folha voltou ao que era
        val kept = objs.size == liveCount && objs.lastOrNull()?.id == id && objs.last() is StrokeObj
        val gone = objs.size == liveCount - 1 && objs.none { it.id == id }
        if (!kept && !gone) return false
        if (kept) one(Canvas(b), id)
        key = k
        liveId = null
        bakes++
        return true
    }
}
