package br.com.arque.measure.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.TextObj
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min

enum class Tool(val label: String, val drawing: Boolean) {
    NAVIGATE("Navegar", false),
    SELECT("Selecionar", false),
    PEN("Caneta", true),
    PENCIL("Lápis", true),
    HIGHLIGHTER("Marca-texto", true),
    ERASER("Borracha", true),
    LINE("Linha", true),
    DASHED("Tracejada", true),
    ARROW("Seta", true),
    DIM("Seta de cota", true),
    RECT("Retângulo", true),
    RRECT("Retângulo arredondado", true),
    ELLIPSE("Oval", true),
    TRIANGLE("Triângulo", true),
    TEXT("Texto", false),
}

/**
 * Câmera sobre as folhas empilhadas na vertical. Coordenadas "mundo": a folha i começa em
 * y = i * (H + GAP). A câmera (scale, ox, oy) nunca altera folhas nem fotos.
 * [pageOffsetY] é o deslocamento da folha ativa: [toSheet] devolve coordenadas locais da folha ativa.
 */
class ViewState {
    var scale by mutableFloatStateOf(1f)
    var ox by mutableFloatStateOf(0f)
    var oy by mutableFloatStateOf(0f)
    var pageOffsetY by mutableFloatStateOf(0f)

    fun toWorld(o: Offset) = Pt((o.x - ox) / scale, (o.y - oy) / scale)
    fun toSheet(o: Offset): Pt {
        val w = toWorld(o)
        return Pt(w.x, w.y - pageOffsetY)
    }
    fun toScreen(p: Pt) = Offset(p.x * scale + ox, (p.y + pageOffsetY) * scale + oy)
}

data class TextEdit(val id: String?, val at: Pt)

/** Cores da paleta aprovada: preto, vermelho, azul, verde, âmbar. */
val PALETTE = listOf(
    0xFF111111.toInt(), 0xFFE53935.toInt(), 0xFF1E5BD8.toInt(), 0xFF2E9E57.toInt(), 0xFFF5B400.toInt(),
)

/** Mais cores (escolhidas pelo botão arco-íris ao lado das 5 principais). */
val EXTRA_COLORS = listOf(
    0xFF000000, 0xFF424242, 0xFF757575, 0xFFBDBDBD, 0xFF795548, 0xFF8D6E63,
    0xFFB71C1C, 0xFFE53935, 0xFFFF5252, 0xFFFF6F00, 0xFFFF9800, 0xFFFFC107,
    0xFFFFEB3B, 0xFFCDDC39, 0xFF8BC34A, 0xFF2E9E57, 0xFF1B5E20, 0xFF009688,
    0xFF00BCD4, 0xFF03A9F4, 0xFF1E5BD8, 0xFF0D2A8C, 0xFF3F51B5, 0xFF673AB7,
    0xFF9C27B0, 0xFFE91E63, 0xFFF48FB1, 0xFFFFFFFF,
).map { it.toInt() }

const val MM_PER_UNIT = 0.2645833f // 1 unidade de folha = 1/96 pol
const val UNITS_PER_MM = 3.7795277f

class EditorSession(initial: Note, onCommit: (Note) -> Unit) {
    /** Muda a cada alteração: quem lê isto recompõe/redesenha. */
    var rev by mutableIntStateOf(0)

    val state = EditorState(initial, onCommit) { rev++ }
    val view = ViewState()

    var tool by mutableStateOf(Tool.SELECT)
        private set
    var color by mutableIntStateOf(PALETTE[0])
    /** Espessura em unidades de folha. Padrão 0,55 mm. */
    var width by mutableFloatStateOf(0.55f * UNITS_PER_MM)
    var fill by mutableStateOf(false)
    var stylusOnly by mutableStateOf(false)
    var fullscreen by mutableStateOf(false)

    var textEdit by mutableStateOf<TextEdit?>(null)

    /** Ponto da tela onde o dedo está ao posicionar a ponta de uma cota/seta (lupa). */
    var loupe by mutableStateOf<Offset?>(null)

    /** Quanto o usuário puxou além do fim da última folha (px). */
    var pull by mutableFloatStateOf(0f)

    var canvasW = 0f
    var canvasH = 0f
    var density = 1f
    private var fitted = false

    fun chooseTool(t: Tool) {
        tool = t
        if (t == Tool.NAVIGATE || (t.drawing && t != Tool.DIM)) state.select(null)
        textEdit = null
    }

    // ---- câmera ----

    private val pageStep get() = Sheet.H + Sheet.GAP
    private val worldH get() = state.note.pages.size * pageStep - Sheet.GAP
    /** 100% = folha ocupando a largura da tela. */
    val fitScale get() = if (canvasW > 0f) canvasW / Sheet.W else 1f
    val zoomPercent get() = (view.scale / fitScale * 100f).toInt()

    fun onCanvasSize(w: Float, h: Float) {
        canvasW = w; canvasH = h
        if (!fitted && w > 0f && h > 0f) {
            fitWidth()
            fitted = true
        }
    }

    fun fitWidth() {
        view.scale = fitScale
        view.ox = 0f
        view.oy = topInset()
        updateActivePage()
    }

    private fun topInset() = 120f * density
    private fun bottomInset() = 90f * density

    /** Limita a câmera. Em cima: parada dura. Embaixo: resistência além do fim (puxar para criar folha). */
    fun clampView(allowPull: Boolean = false) {
        val s = view.scale
        val sw = Sheet.W * s
        view.ox = if (sw <= canvasW) (canvasW - sw) / 2f else view.ox.coerceIn(canvasW - sw - 24f * density, 24f * density)
        val top = topInset()
        val minOy = canvasH - bottomInset() - worldH * s
        val lowest = min(top, minOy)
        var oy = min(view.oy, top)
        if (oy < lowest) {
            if (allowPull) {
                pull = (lowest - oy)
                oy = lowest - pull * 0.5f
            } else {
                oy = lowest
                pull = 0f
            }
        } else pull = 0f
        view.oy = oy
    }

    fun panBy(dx: Float, dy: Float) {
        view.ox += dx
        view.oy += dy
        clampView(allowPull = true)
    }

    fun zoomAround(factor: Float, cx: Float, cy: Float) {
        val ns = (view.scale * factor).coerceIn(fitScale * 0.25f, fitScale * 10f)
        val real = ns / view.scale
        view.ox = cx - (cx - view.ox) * real
        view.oy = cy - (cy - view.oy) * real
        view.scale = ns
        clampView()
    }

    /** Ao soltar: se puxou o bastante além do fim, adiciona uma folha. */
    fun settle(): Boolean {
        var added = false
        if (pull >= 80f * density && state.note.pages.size < Sheet.MAX_PAGES) {
            state.addPage(state.note.pages.size, state.sheet.tpl)
            added = true
            updateActivePage()
        }
        pull = 0f
        clampView()
        return added
    }

    /** A folha sob o ponto da tela passa a ser a ativa (os gestos usam coordenadas locais dela). */
    fun pickPage(screen: Offset) {
        val w = view.toWorld(screen)
        val i = floor(w.y / pageStep).toInt().coerceIn(0, state.note.pages.lastIndex)
        if (i != state.pageIdx) state.setPage(i)
        view.pageOffsetY = i * pageStep
    }

    fun updateActivePage() {
        view.pageOffsetY = state.pageIdx * pageStep
    }

    /** Leva a câmera até a folha [i], centrada na largura. */
    fun goToPage(i: Int) {
        val n = i.coerceIn(0, state.note.pages.lastIndex)
        state.setPage(n)
        view.scale = fitScale
        view.ox = 0f
        view.oy = topInset() - n * pageStep * view.scale
        updateActivePage()
        clampView()
    }

    fun fitButton() = goToPage(state.pageIdx)

    /** Folha visível no centro da tela (para o indicador "1/3"). */
    fun visiblePage(): Int {
        val w = view.toWorld(Offset(canvasW / 2f, canvasH / 2f))
        return floor(w.y / pageStep).toInt().coerceIn(0, state.note.pages.lastIndex)
    }

    /** Insere a foto no centro do que está visível, na folha visível. */
    fun addPhoto(file: String, pxW: Int, pxH: Int) {
        val vp = visiblePage()
        state.setPage(vp)
        updateActivePage()
        val s = state.sheet
        val aspect = pxW.toFloat() / pxH.toFloat()
        val w = min(s.width * 0.7f, s.height * 0.5f * aspect)
        val h = w / aspect
        val c = view.toSheet(Offset(canvasW / 2f, canvasH / 2f))
        val cascade = (s.objs.count { it is PhotoObj } % 5) * 28f
        val cx = (c.x + cascade).coerceIn(0f, s.width)
        val cy = (c.y + cascade).coerceIn(0f, s.height)
        state.addObj(PhotoObj(file = file, pxW = pxW, pxH = pxH, cx = cx, cy = cy, w = w, h = h))
        chooseTool(Tool.SELECT)
        state.select(state.sheet.objs.last().id)
    }

    fun commitText(edit: TextEdit, text: String) {
        val trimmed = text.trim()
        if (edit.id != null) {
            if (trimmed.isEmpty()) state.delete(edit.id) else state.setText(edit.id, trimmed)
        } else if (trimmed.isNotEmpty()) {
            val photoId = Geo.photoAt(state.sheet, edit.at)?.id
            val local = Geo.fromSheet(state.sheet.photos(), photoId, edit.at)
            state.addObj(TextObj(photoId = photoId, at = local, text = trimmed, size = 18f, color = color))
        }
        textEdit = null
    }

    /** Área de transferência (cortar/copiar/colar) entre folhas da mesma nota. */
    var clipboard by mutableStateOf<List<br.com.arque.measure.model.Obj>>(emptyList())

    fun copySelection(cut: Boolean = false) {
        val o = state.selected ?: return
        val objs = buildList {
            add(o)
            if (o is PhotoObj) addAll(state.sheet.objs.filterIsInstance<br.com.arque.measure.model.Ann>().filter { it.photoId == o.id })
        }
        clipboard = objs
        if (cut) state.delete(o.id)
    }

    fun paste() {
        if (clipboard.isEmpty()) return
        state.pasteObjs(clipboard)
    }

    fun widthMm(): Float = width * MM_PER_UNIT

    @Suppress("unused")
    private fun keep() = max(0, 0)
}
