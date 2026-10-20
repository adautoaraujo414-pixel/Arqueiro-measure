package br.com.arque.measure.ui

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Offset
import br.com.arque.measure.logic.EditorState
import br.com.arque.measure.logic.Geo
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.TextObj
import kotlin.math.min

enum class Tool(val label: String, val drawing: Boolean) {
    NAVIGATE("Navegar", false),
    SELECT("Selecionar", false),
    PEN("Caneta", true),
    PENCIL("Lápis", true),
    HIGHLIGHTER("Marca-texto", true),
    ERASER("Borracha", true),
    LINE("Linha", true),
    ARROW("Seta", true),
    RECT("Retângulo", true),
    ELLIPSE("Círculo", true),
    TEXT("Texto", false),
    DIM("Cota", true),
}

/** Zoom/posição da visualização. Não altera a folha nem as fotos. */
class ViewState {
    var scale by mutableFloatStateOf(1f)
    var ox by mutableFloatStateOf(0f)
    var oy by mutableFloatStateOf(0f)

    fun toSheet(o: Offset) = Pt((o.x - ox) / scale, (o.y - oy) / scale)
    fun toScreen(p: Pt) = Offset(p.x * scale + ox, p.y * scale + oy)

    fun fit(canvasW: Float, canvasH: Float, sheetW: Float, sheetH: Float, margin: Float) {
        if (canvasW <= 0f || canvasH <= 0f) return
        val s = min((canvasW - 2 * margin) / sheetW, (canvasH - 2 * margin) / sheetH).coerceAtLeast(0.05f)
        scale = s
        ox = (canvasW - sheetW * s) / 2f
        oy = (canvasH - sheetH * s) / 2f
    }
}

data class TextEdit(val id: String?, val at: Pt)

val PALETTE = listOf(
    0xFF111827.toInt(), 0xFF1F4E79.toInt(), 0xFFD32F2F.toInt(),
    0xFF2E7D32.toInt(), 0xFFF57C00.toInt(), 0xFF7B1FA2.toInt(),
)

class EditorSession(initial: Sheet, onCommit: (Sheet) -> Unit) {
    /** Muda a cada alteração: quem lê isto recompõe/redesenha. */
    var rev by mutableIntStateOf(0)

    val state = EditorState(initial, onCommit) { rev++ }
    val view = ViewState()

    var tool by mutableStateOf(Tool.SELECT)
        private set
    var color by mutableIntStateOf(PALETTE[1])
    var width by mutableFloatStateOf(3f)
    var stylusOnly by mutableStateOf(false)

    var dimEditId by mutableStateOf<String?>(null)
    var textEdit by mutableStateOf<TextEdit?>(null)

    var canvasW = 0f
    var canvasH = 0f
    private var fitted = false

    fun chooseTool(t: Tool) {
        tool = t
        if (t == Tool.NAVIGATE || (t.drawing && t != Tool.DIM)) state.select(null)
        dimEditId = null
        textEdit = null
    }

    fun onCanvasSize(w: Float, h: Float) {
        canvasW = w; canvasH = h
        if (!fitted && w > 0f && h > 0f) {
            fitToScreen()
            fitted = true
        }
    }

    fun fitToScreen() {
        val s = state.sheet
        view.fit(canvasW, canvasH, s.width, s.height, margin = 24f)
    }

    /** Insere a foto no centro do que está visível, com tamanho que cabe na folha. */
    fun addPhoto(file: String, pxW: Int, pxH: Int) {
        val s = state.sheet
        val aspect = pxW.toFloat() / pxH.toFloat()
        val w = min(s.width * 0.7f, s.height * 0.5f * aspect)
        val h = w / aspect
        val c = view.toSheet(Offset(canvasW / 2f, canvasH / 2f))
        // várias fotos de uma vez não ficam empilhadas exatamente no mesmo ponto
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
}
