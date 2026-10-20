package br.com.arque.measure.model

import java.util.UUID

fun newId(): String = UUID.randomUUID().toString()

data class Pt(val x: Float, val y: Float) {
    operator fun plus(o: Pt) = Pt(x + o.x, y + o.y)
    operator fun minus(o: Pt) = Pt(x - o.x, y - o.y)
    operator fun times(k: Float) = Pt(x * k, y * k)
}

/** Origem de uma medida: digitada ou recebida da trena por Bluetooth. */
enum class MeasureSource { MANUAL, BLUETOOTH }

enum class LengthUnit(val label: String) { MM("mm"), CM("cm"), M("m") }

enum class ShapeKind { LINE, DASHED, ARROW, RECT, RRECT, ELLIPSE, TRIANGLE }

enum class StrokeKind { PEN, PENCIL, HIGHLIGHTER }

/** Uma leitura de medida. Sempre em milímetros, independente da escala visual. */
data class Reading(
    val id: String = newId(),
    val mm: Double,
    val source: MeasureSource,
    val timeMs: Long,
    val device: String? = null,
    val rawHex: String? = null,
)

sealed class Obj {
    abstract val id: String
    abstract val locked: Boolean
}

/** Foto: objeto independente. Centro, tamanho e rotação em unidades de folha. */
data class PhotoObj(
    override val id: String = newId(),
    val file: String,
    val pxW: Int,
    val pxH: Int,
    val cx: Float,
    val cy: Float,
    val w: Float,
    val h: Float,
    val rot: Float = 0f,
    override val locked: Boolean = false,
) : Obj()

/**
 * Anotação. Se [photoId] != null, os pontos ficam em coordenadas normalizadas da foto
 * (0,0 = canto superior esquerdo, 1,1 = inferior direito), então acompanham mover/girar/redimensionar.
 * Se null, os pontos estão em coordenadas da folha.
 */
sealed class Ann : Obj() {
    abstract val photoId: String?
}

data class StrokeObj(
    override val id: String = newId(),
    override val photoId: String?,
    val pts: List<Pt>,
    val color: Int,
    val width: Float,
    val kind: StrokeKind = StrokeKind.PEN,
    override val locked: Boolean = false,
) : Ann()

data class ShapeObj(
    override val id: String = newId(),
    override val photoId: String?,
    val kind: ShapeKind,
    val a: Pt,
    val b: Pt,
    val color: Int,
    val width: Float,
    val fill: Boolean = false,
    override val locked: Boolean = false,
) : Ann()

data class TextObj(
    override val id: String = newId(),
    override val photoId: String?,
    val at: Pt,
    val text: String,
    val size: Float,
    val color: Int,
    override val locked: Boolean = false,
) : Ann()

/** Cota (seta dimensional). [valueMm] é a dimensão real; nunca é derivada de pixels. */
data class DimObj(
    override val id: String = newId(),
    override val photoId: String?,
    val a: Pt,
    val b: Pt,
    val valueMm: Double? = null,
    val source: MeasureSource? = null,
    val history: List<Reading> = emptyList(),
    val color: Int,
    val width: Float,
    override val locked: Boolean = false,
) : Ann()

/** Modelos de folha. */
enum class Template(val label: String) {
    ARAUJO("Araújo croqui"),
    BLANK("Em branco"),
    LINES("Linha fina"),
}

/** Uma folha A4 de uma nota. Tamanho fixo: a folha nunca muda ao mexer em fotos. */
data class Sheet(
    val id: String = newId(),
    val tpl: Template = Template.ARAUJO,
    val objs: List<Obj> = emptyList(),
) {
    val width: Float get() = W
    val height: Float get() = H

    fun photos(): Map<String, PhotoObj> =
        objs.filterIsInstance<PhotoObj>().associateBy { it.id }

    fun obj(id: String?): Obj? = if (id == null) null else objs.firstOrNull { it.id == id }

    companion object {
        const val W = 794f
        const val H = 1123f
        const val GAP = 28f
        const val MAX_PAGES = 30
    }
}

/** Uma nota = um projeto com várias folhas A4 empilhadas. */
data class Note(
    val id: String = newId(),
    val name: String,
    val folderId: String? = null,
    val createdMs: Long = System.currentTimeMillis(),
    val pinned: Boolean = false,
    val locked: Boolean = false,
    val trash: Boolean = false,
    val unit: LengthUnit = LengthUnit.M,
    val pages: List<Sheet> = listOf(Sheet()),
) {
    fun dimCount(): Int = pages.sumOf { p -> p.objs.count { it is DimObj } }
    fun meta() = NoteMeta(id, name, folderId, createdMs, pinned, locked, trash, pages.size, dimCount())
}

data class Folder(val id: String = newId(), val name: String)

data class NoteMeta(
    val id: String,
    val name: String,
    val folderId: String?,
    val createdMs: Long,
    val pinned: Boolean,
    val locked: Boolean,
    val trash: Boolean,
    val pageCount: Int,
    val dimCount: Int,
)

data class Index(
    val folders: List<Folder> = emptyList(),
    val notes: List<NoteMeta> = emptyList(),
)

fun Obj.withLocked(v: Boolean): Obj = when (this) {
    is PhotoObj -> copy(locked = v)
    is StrokeObj -> copy(locked = v)
    is ShapeObj -> copy(locked = v)
    is TextObj -> copy(locked = v)
    is DimObj -> copy(locked = v)
}

fun Obj.withId(newId: String): Obj = when (this) {
    is PhotoObj -> copy(id = newId)
    is StrokeObj -> copy(id = newId)
    is ShapeObj -> copy(id = newId)
    is TextObj -> copy(id = newId)
    is DimObj -> copy(id = newId)
}

fun Ann.withPhotoId(pid: String?): Ann = when (this) {
    is StrokeObj -> copy(photoId = pid)
    is ShapeObj -> copy(photoId = pid)
    is TextObj -> copy(photoId = pid)
    is DimObj -> copy(photoId = pid)
}
