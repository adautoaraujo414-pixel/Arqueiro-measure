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

enum class ShapeKind { LINE, ARROW, RECT, ELLIPSE }

enum class StrokeKind { PEN, PENCIL, HIGHLIGHTER }

/** Dimensões da folha em unidades de folha (96 dpi). A folha nunca muda de tamanho ao mexer em fotos. */
enum class Paper(val label: String, val w: Float, val h: Float) {
    A4("A4", 794f, 1123f),
    A3("A3", 1123f, 1587f),
    A5("A5", 559f, 794f),
    LETTER("Carta", 816f, 1056f),
}

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

data class Sheet(
    val id: String = newId(),
    val roomId: String,
    val name: String,
    val paper: Paper = Paper.A4,
    val landscape: Boolean = false,
    val unit: LengthUnit = LengthUnit.MM,
    val objs: List<Obj> = emptyList(),
) {
    val width: Float get() = if (landscape) paper.h else paper.w
    val height: Float get() = if (landscape) paper.w else paper.h

    fun photos(): Map<String, PhotoObj> =
        objs.filterIsInstance<PhotoObj>().associateBy { it.id }

    fun obj(id: String?): Obj? = if (id == null) null else objs.firstOrNull { it.id == id }
}

data class Client(
    val id: String = newId(),
    val name: String,
    val city: String,
    val address: String = "",
    val phone: String = "",
    val notes: String = "",
)

data class Room(val id: String = newId(), val clientId: String, val name: String)

data class SheetMeta(val id: String, val roomId: String, val name: String)

data class Index(
    val clients: List<Client> = emptyList(),
    val rooms: List<Room> = emptyList(),
    val sheets: List<SheetMeta> = emptyList(),
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
