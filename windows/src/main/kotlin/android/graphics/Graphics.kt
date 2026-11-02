@file:Suppress("unused", "MemberVisibilityCanBePrivate", "FunctionName")

package android.graphics

/*
 * Camada de compatibilidade do Arquemestre para Windows: a mesma API de desenho do Android
 * (Canvas, Paint, Path, Bitmap...) implementada em cima do Skia (o motor de desenho do Compose Desktop).
 * Assim o desenho da folha, a exportação PNG/PDF e o orçamento usam exatamente o mesmo código do celular.
 */

import org.jetbrains.skia.ClipMode
import org.jetbrains.skia.Codec
import org.jetbrains.skia.Data
import org.jetbrains.skia.EncodedImageFormat
import org.jetbrains.skia.EncodedOrigin
import org.jetbrains.skia.Font
import org.jetbrains.skia.FontMgr
import org.jetbrains.skia.FontStyle
import org.jetbrains.skia.Image
import org.jetbrains.skia.PaintMode
import org.jetbrains.skia.PaintStrokeCap
import org.jetbrains.skia.PaintStrokeJoin
import org.jetbrains.skia.PathDirection
import org.jetbrains.skia.RRect
import org.jetbrains.skia.SamplingMode
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import org.jetbrains.skia.Bitmap as SkBitmap
import org.jetbrains.skia.Canvas as SkCanvas
import org.jetbrains.skia.Paint as SkPaint
import org.jetbrains.skia.Path as SkPath
import org.jetbrains.skia.PathEffect as SkPathEffect
import org.jetbrains.skia.Rect as SkRect
import org.jetbrains.skia.Typeface as SkTypeface

object Color {
    const val BLACK: Int = -0x1000000
    const val DKGRAY: Int = -0xbbbbbc
    const val GRAY: Int = -0x777778
    const val LTGRAY: Int = -0x333334
    const val WHITE: Int = -0x1
    const val RED: Int = -0x10000
    const val GREEN: Int = -0xff0100
    const val BLUE: Int = -0xffff01
    const val YELLOW: Int = -0x100
    const val CYAN: Int = -0xff0001
    const val MAGENTA: Int = -0xff01
    const val TRANSPARENT: Int = 0

    @JvmStatic fun argb(a: Int, r: Int, g: Int, b: Int): Int = (a shl 24) or (r shl 16) or (g shl 8) or b
    @JvmStatic fun rgb(r: Int, g: Int, b: Int): Int = argb(255, r, g, b)
    @JvmStatic fun alpha(c: Int): Int = c ushr 24
    @JvmStatic fun red(c: Int): Int = (c shr 16) and 0xFF
    @JvmStatic fun green(c: Int): Int = (c shr 8) and 0xFF
    @JvmStatic fun blue(c: Int): Int = c and 0xFF
    @JvmStatic fun parseColor(s: String): Int {
        val h = s.trim().removePrefix("#")
        return when (h.length) {
            6 -> (0xFF000000L or h.toLong(16)).toInt()
            8 -> h.toLong(16).toInt()
            else -> throw IllegalArgumentException("Unknown color")
        }
    }
}

/** Fontes: Segoe UI no Windows (com troca automática pra emoji e símbolos que ela não tem). */
class Typeface private constructor(val isBold: Boolean, val mono: Boolean) {
    val style: Int get() = if (isBold) BOLD else NORMAL

    internal val sk: SkTypeface? by lazy { Fonts.find(mono, isBold) }

    companion object {
        const val NORMAL = 0
        const val BOLD = 1
        const val ITALIC = 2
        const val BOLD_ITALIC = 3
        @JvmField val DEFAULT = Typeface(false, false)
        @JvmField val DEFAULT_BOLD = Typeface(true, false)
        @JvmField val MONOSPACE = Typeface(false, true)
        @JvmField val SANS_SERIF = DEFAULT
        @JvmField val SERIF = DEFAULT
        @JvmStatic fun create(family: Typeface?, style: Int): Typeface =
            if (family?.mono == true) (if (style and BOLD != 0) Typeface(true, true) else MONOSPACE)
            else if (style and BOLD != 0) DEFAULT_BOLD else DEFAULT
        @JvmStatic fun defaultFromStyle(style: Int): Typeface = create(null, style)
    }
}

internal object Fonts {
    private val sans = listOf("Segoe UI", "Arial", "Helvetica", "DejaVu Sans", "Liberation Sans", "Noto Sans")
    private val monoNames = listOf("Consolas", "Courier New", "DejaVu Sans Mono", "Liberation Mono", "Noto Sans Mono")
    private val cache = HashMap<String, SkTypeface?>()

    fun find(mono: Boolean, bold: Boolean): SkTypeface? = synchronized(cache) {
        cache.getOrPut("$mono/$bold") {
            val st = if (bold) FontStyle.BOLD else FontStyle.NORMAL
            val mgr = FontMgr.default
            (if (mono) monoNames else sans).firstNotNullOfOrNull { runCatching { mgr.matchFamilyStyle(it, st) }.getOrNull() }
                ?: runCatching { mgr.legacyMakeTypeface("", st) }.getOrNull()
        }
    }

    private val fallback = HashMap<Long, SkTypeface?>()

    /** Fonte que tem o caractere (emoji, símbolos) quando a principal não tem. */
    fun forChar(base: SkTypeface?, bold: Boolean, cp: Int): SkTypeface? = synchronized(fallback) {
        val key = (cp.toLong() shl 1) or (if (bold) 1L else 0L)
        fallback.getOrPut(key) {
            val st = if (bold) FontStyle.BOLD else FontStyle.NORMAL
            runCatching { FontMgr.default.matchFamilyStyleCharacter(null, st, null, cp) }.getOrNull() ?: base
        }
    }
}

open class PathEffect internal constructor(internal val sk: SkPathEffect?)

class DashPathEffect(intervals: FloatArray, phase: Float) : PathEffect(SkPathEffect.makeDash(intervals, phase))

class Paint() {
    enum class Style { FILL, STROKE, FILL_AND_STROKE }
    enum class Cap { BUTT, ROUND, SQUARE }
    enum class Join { MITER, ROUND, BEVEL }
    enum class Align { LEFT, CENTER, RIGHT }

    var color: Int = Color.BLACK
    var strokeWidth: Float = 0f
    var style: Style = Style.FILL
    var strokeCap: Cap = Cap.BUTT
    var strokeJoin: Join = Join.MITER
    var strokeMiter: Float = 4f
    var pathEffect: PathEffect? = null
    var textAlign: Align = Align.LEFT
    var textSize: Float = 12f
    var typeface: Typeface? = Typeface.DEFAULT
    var isAntiAlias: Boolean = false
    var isFilterBitmap: Boolean = false
    var isDither: Boolean = false
    var isFakeBoldText: Boolean = false
    /** Em "em" (fração do tamanho da letra), como no Android. */
    var letterSpacing: Float = 0f
    /** Largura das letras (1 = normal): usado pra encolher texto comprido. */
    var textScaleX: Float = 1f

    var alpha: Int
        get() = color ushr 24
        set(v) { color = (color and 0x00FFFFFF) or ((v.coerceIn(0, 255)) shl 24) }

    constructor(flags: Int) : this() {
        isAntiAlias = flags and ANTI_ALIAS_FLAG != 0
        isFilterBitmap = flags and FILTER_BITMAP_FLAG != 0
        isDither = flags and DITHER_FLAG != 0
    }

    constructor(p: Paint) : this() { set(p) }

    fun set(p: Paint) {
        color = p.color; strokeWidth = p.strokeWidth; style = p.style; strokeCap = p.strokeCap; strokeJoin = p.strokeJoin
        strokeMiter = p.strokeMiter; pathEffect = p.pathEffect; textAlign = p.textAlign; textSize = p.textSize; typeface = p.typeface
        isAntiAlias = p.isAntiAlias; isFilterBitmap = p.isFilterBitmap; isDither = p.isDither; isFakeBoldText = p.isFakeBoldText
        letterSpacing = p.letterSpacing; textScaleX = p.textScaleX
    }

    fun setARGB(a: Int, r: Int, g: Int, b: Int) { color = Color.argb(a, r, g, b) }
    fun reset() { set(Paint()) }

    internal fun sk(): SkPaint = SkPaint().also { s ->
        s.color = color
        s.isAntiAlias = isAntiAlias
        s.mode = when (style) { Style.FILL -> PaintMode.FILL; Style.STROKE -> PaintMode.STROKE; Style.FILL_AND_STROKE -> PaintMode.STROKE_AND_FILL }
        s.strokeWidth = strokeWidth
        s.strokeCap = when (strokeCap) { Cap.BUTT -> PaintStrokeCap.BUTT; Cap.ROUND -> PaintStrokeCap.ROUND; Cap.SQUARE -> PaintStrokeCap.SQUARE }
        s.strokeJoin = when (strokeJoin) { Join.MITER -> PaintStrokeJoin.MITER; Join.ROUND -> PaintStrokeJoin.ROUND; Join.BEVEL -> PaintStrokeJoin.BEVEL }
        s.strokeMiter = strokeMiter
        s.pathEffect = pathEffect?.sk
    }

    private val bold: Boolean get() = (typeface?.isBold == true) || isFakeBoldText

    internal fun font(tf: SkTypeface?): Font = Font(tf, textSize).also { f ->
        if (isFakeBoldText && typeface?.isBold != true) f.isEmboldened = true
        f.isSubpixel = true
        if (textScaleX != 1f) f.scaleX = textScaleX
    }

    /** Divide o texto em pedaços por fonte (a principal e as de emoji/símbolos). */
    internal fun runs(text: String): List<Pair<String, Font>> {
        val base = (typeface ?: Typeface.DEFAULT).sk
        val baseFont = font(base)
        val out = ArrayList<Pair<String, Font>>()
        val sb = StringBuilder()
        var cur: SkTypeface? = base
        var curFont = baseFont
        var i = 0
        while (i < text.length) {
            val cp = text.codePointAt(i)
            val n = Character.charCount(cp)
            val has = cp < 0x20 || baseFont.getUTF32Glyph(cp).toInt() != 0
            val tf = if (has) base else Fonts.forChar(base, bold, cp)
            if (tf !== cur && sb.isNotEmpty()) { out += sb.toString() to curFont; sb.setLength(0) }
            if (tf !== cur) { cur = tf; curFont = if (tf === base) baseFont else font(tf) }
            sb.append(text, i, i + n)
            i += n
        }
        if (sb.isNotEmpty()) out += sb.toString() to curFont
        return out
    }

    fun measureText(text: String): Float {
        if (text.isEmpty()) return 0f
        var w = 0f
        for ((s, f) in runs(text)) w += f.measureTextWidth(s)
        if (letterSpacing != 0f) w += letterSpacing * textSize * text.codePointCount(0, text.length)
        return w
    }

    fun measureText(text: CharSequence, start: Int, end: Int): Float = measureText(text.subSequence(start, end).toString())

    /** Quantos caracteres cabem em [maxWidth]. */
    fun breakText(text: String, measureForwards: Boolean, maxWidth: Float, measuredWidth: FloatArray?): Int {
        var n = 0
        var w = 0f
        if (measureForwards) {
            while (n < text.length) {
                val nw = measureText(text.substring(0, n + 1))
                if (nw > maxWidth) break
                w = nw; n++
            }
        } else {
            while (n < text.length) {
                val nw = measureText(text.substring(text.length - n - 1))
                if (nw > maxWidth) break
                w = nw; n++
            }
        }
        measuredWidth?.let { if (it.isNotEmpty()) it[0] = w }
        return n
    }

    fun getTextBounds(text: String, start: Int, end: Int, bounds: Rect) {
        val s = text.substring(start, end)
        val m = font((typeface ?: Typeface.DEFAULT).sk).metrics
        bounds.set(0, m.ascent.toInt(), measureText(s).toInt(), m.descent.toInt())
    }

    fun ascent(): Float = font((typeface ?: Typeface.DEFAULT).sk).metrics.ascent
    fun descent(): Float = font((typeface ?: Typeface.DEFAULT).sk).metrics.descent

    class FontMetrics { @JvmField var ascent = 0f; @JvmField var descent = 0f; @JvmField var top = 0f; @JvmField var bottom = 0f; @JvmField var leading = 0f }

    val fontMetrics: FontMetrics
        get() {
            val m = font((typeface ?: Typeface.DEFAULT).sk).metrics
            return FontMetrics().also { it.ascent = m.ascent; it.descent = m.descent; it.top = m.top; it.bottom = m.bottom; it.leading = m.leading }
        }

    companion object {
        const val ANTI_ALIAS_FLAG = 1
        const val FILTER_BITMAP_FLAG = 2
        const val DITHER_FLAG = 4
        const val FAKE_BOLD_TEXT_FLAG = 32
    }
}

class Rect(@JvmField var left: Int = 0, @JvmField var top: Int = 0, @JvmField var right: Int = 0, @JvmField var bottom: Int = 0) {
    fun set(l: Int, t: Int, r: Int, b: Int) { left = l; top = t; right = r; bottom = b }
    fun width() = right - left
    fun height() = bottom - top
    fun centerX() = (left + right) / 2
    fun centerY() = (top + bottom) / 2
    fun isEmpty() = left >= right || top >= bottom
}

class RectF(@JvmField var left: Float = 0f, @JvmField var top: Float = 0f, @JvmField var right: Float = 0f, @JvmField var bottom: Float = 0f) {
    constructor(r: RectF) : this(r.left, r.top, r.right, r.bottom)
    constructor(r: Rect) : this(r.left.toFloat(), r.top.toFloat(), r.right.toFloat(), r.bottom.toFloat())

    fun set(l: Float, t: Float, r: Float, b: Float) { left = l; top = t; right = r; bottom = b }
    fun set(r: RectF) = set(r.left, r.top, r.right, r.bottom)
    fun setEmpty() = set(0f, 0f, 0f, 0f)
    fun width() = right - left
    fun height() = bottom - top
    fun centerX() = (left + right) / 2f
    fun centerY() = (top + bottom) / 2f
    fun isEmpty() = left >= right || top >= bottom
    fun offset(dx: Float, dy: Float) { left += dx; right += dx; top += dy; bottom += dy }
    fun offsetTo(x: Float, y: Float) = offset(x - left, y - top)
    fun inset(dx: Float, dy: Float) { left += dx; right -= dx; top += dy; bottom -= dy }
    fun contains(x: Float, y: Float) = left < right && top < bottom && x >= left && x < right && y >= top && y < bottom
    fun union(x: Float, y: Float) { left = minOf(left, x); top = minOf(top, y); right = maxOf(right, x); bottom = maxOf(bottom, y) }
    fun union(r: RectF) { if (r.isEmpty()) return; if (isEmpty()) set(r) else { left = minOf(left, r.left); top = minOf(top, r.top); right = maxOf(right, r.right); bottom = maxOf(bottom, r.bottom) } }
    fun intersects(l: Float, t: Float, r: Float, b: Float) = left < r && l < right && top < b && t < bottom
    fun sort() { if (left > right) left = right.also { right = left }; if (top > bottom) top = bottom.also { bottom = top } }
    internal fun sk(): SkRect = SkRect.makeLTRB(left, top, right, bottom)
    override fun toString() = "RectF($left, $top, $right, $bottom)"
}

class Path() {
    enum class Direction { CW, CCW }
    enum class FillType { WINDING, EVEN_ODD, INVERSE_WINDING, INVERSE_EVEN_ODD }

    internal var sk = SkPath()

    constructor(src: Path) : this() { sk = SkPath().also { it.addPath(src.sk) } }

    private fun dir(d: Direction) = if (d == Direction.CW) PathDirection.CLOCKWISE else PathDirection.COUNTER_CLOCKWISE

    fun moveTo(x: Float, y: Float) { sk.moveTo(x, y) }
    fun lineTo(x: Float, y: Float) { sk.lineTo(x, y) }
    fun rMoveTo(dx: Float, dy: Float) { sk.rMoveTo(dx, dy) }
    fun rLineTo(dx: Float, dy: Float) { sk.rLineTo(dx, dy) }
    fun quadTo(x1: Float, y1: Float, x2: Float, y2: Float) { sk.quadTo(x1, y1, x2, y2) }
    fun cubicTo(x1: Float, y1: Float, x2: Float, y2: Float, x3: Float, y3: Float) { sk.cubicTo(x1, y1, x2, y2, x3, y3) }
    fun close() { sk.closePath() }
    fun reset() { sk.reset() }
    fun rewind() { sk.rewind() }
    val isEmpty: Boolean get() = sk.isEmpty
    fun addCircle(x: Float, y: Float, r: Float, d: Direction) { sk.addCircle(x, y, r, dir(d)) }
    fun addRect(l: Float, t: Float, r: Float, b: Float, d: Direction) { sk.addRect(SkRect.makeLTRB(l, t, r, b), dir(d), 0) }
    fun addRect(r: RectF, d: Direction) = addRect(r.left, r.top, r.right, r.bottom, d)
    fun addOval(r: RectF, d: Direction) { sk.addOval(r.sk(), dir(d), 1) }
    fun addOval(l: Float, t: Float, r: Float, b: Float, d: Direction) { sk.addOval(SkRect.makeLTRB(l, t, r, b), dir(d), 1) }
    fun addRoundRect(r: RectF, rx: Float, ry: Float, d: Direction) { sk.addRRect(RRect.makeLTRB(r.left, r.top, r.right, r.bottom, rx, ry), dir(d), 6) }
    fun addRoundRect(l: Float, t: Float, r: Float, b: Float, rx: Float, ry: Float, d: Direction) { sk.addRRect(RRect.makeLTRB(l, t, r, b, rx, ry), dir(d), 6) }
    fun addPath(p: Path) { sk.addPath(p.sk) }
    fun arcTo(oval: RectF, startAngle: Float, sweepAngle: Float, forceMoveTo: Boolean) { sk.arcTo(oval.sk(), startAngle, sweepAngle, forceMoveTo) }
    fun arcTo(oval: RectF, startAngle: Float, sweepAngle: Float) = arcTo(oval, startAngle, sweepAngle, false)
    fun addArc(oval: RectF, startAngle: Float, sweepAngle: Float) { sk.addArc(oval.sk(), startAngle, sweepAngle) }
    fun offset(dx: Float, dy: Float) { sk.offset(dx, dy) }
    var fillType: FillType = FillType.WINDING
        set(v) {
            field = v
            sk.fillMode = when (v) {
                FillType.WINDING -> org.jetbrains.skia.PathFillMode.WINDING
                FillType.EVEN_ODD -> org.jetbrains.skia.PathFillMode.EVEN_ODD
                FillType.INVERSE_WINDING -> org.jetbrains.skia.PathFillMode.INVERSE_WINDING
                FillType.INVERSE_EVEN_ODD -> org.jetbrains.skia.PathFillMode.INVERSE_EVEN_ODD
            }
        }
    fun computeBounds(out: RectF, @Suppress("UNUSED_PARAMETER") exact: Boolean) {
        val b = sk.bounds
        out.set(b.left, b.top, b.right, b.bottom)
    }
}

/** Imagem em memória (foto da nota, logotipo, miniatura). */
class Bitmap internal constructor(internal val sk: SkBitmap) {
    enum class Config { ALPHA_8, RGB_565, ARGB_4444, ARGB_8888, RGBA_F16, HARDWARE }
    enum class CompressFormat { JPEG, PNG, WEBP, WEBP_LOSSY, WEBP_LOSSLESS }

    val width: Int get() = sk.width
    val height: Int get() = sk.height
    val byteCount: Int get() = sk.rowBytes * sk.height
    val allocationByteCount: Int get() = byteCount
    var isRecycled = false
        private set
    val config: Config get() = Config.ARGB_8888

    private var img: Image? = null
    internal fun image(): Image = img ?: Image.makeFromBitmap(sk).also { img = it }
    internal fun touched() { img = null }

    fun recycle() { if (!isRecycled) { isRecycled = true; img?.close(); img = null; sk.close() } }

    fun compress(format: CompressFormat, quality: Int, out: OutputStream): Boolean = try {
        val fmt = when (format) { CompressFormat.PNG -> EncodedImageFormat.PNG; CompressFormat.JPEG -> EncodedImageFormat.JPEG; else -> EncodedImageFormat.WEBP }
        val data = Image.makeFromBitmap(sk).encodeToData(fmt, quality.coerceIn(0, 100)) ?: error("encode")
        out.write(data.bytes); true
    } catch (_: Throwable) { false }

    fun getPixel(x: Int, y: Int): Int = sk.getColor(x, y)
    fun eraseColor(c: Int) { sk.erase(c); touched() }
    fun hasAlpha(): Boolean = true

    companion object {
        @JvmStatic fun createBitmap(w: Int, h: Int, @Suppress("UNUSED_PARAMETER") cfg: Config): Bitmap {
            val b = SkBitmap()
            b.allocN32Pixels(w.coerceAtLeast(1), h.coerceAtLeast(1), false)
            b.erase(0)
            return Bitmap(b)
        }

        @JvmStatic fun createScaledBitmap(src: Bitmap, w: Int, h: Int, filter: Boolean): Bitmap {
            if (w == src.width && h == src.height) return src
            val out = createBitmap(w, h, Config.ARGB_8888)
            val c = SkCanvas(out.sk)
            c.drawImageRect(src.image(), SkRect.makeWH(src.width.toFloat(), src.height.toFloat()), SkRect.makeWH(w.toFloat(), h.toFloat()),
                if (filter) SamplingMode.LINEAR else SamplingMode.DEFAULT, null, true)
            c.close()
            return out
        }

        /** Recorte + transformação (girar/espelhar), como no Android. */
        @JvmStatic fun createBitmap(src: Bitmap, x: Int, y: Int, w: Int, h: Int, m: Matrix?, filter: Boolean): Bitmap {
            val mm = m ?: Matrix()
            val r = RectF(0f, 0f, w.toFloat(), h.toFloat())
            mm.mapRect(r)
            val out = createBitmap(Math.round(r.width()).coerceAtLeast(1), Math.round(r.height()).coerceAtLeast(1), Config.ARGB_8888)
            val c = SkCanvas(out.sk)
            c.translate(-r.left, -r.top)
            c.concat(mm.sk())
            c.drawImageRect(src.image(), SkRect.makeXYWH(x.toFloat(), y.toFloat(), w.toFloat(), h.toFloat()), SkRect.makeWH(w.toFloat(), h.toFloat()),
                if (filter) SamplingMode.LINEAR else SamplingMode.DEFAULT, null, true)
            c.close()
            return out
        }

        @JvmStatic fun createBitmap(src: Bitmap): Bitmap = createBitmap(src, 0, 0, src.width, src.height, null, false)

        internal fun fromImage(img: Image): Bitmap {
            val out = createBitmap(img.width, img.height, Config.ARGB_8888)
            val c = SkCanvas(out.sk)
            c.drawImage(img, 0f, 0f)
            c.close()
            return out
        }

        /** Gira/espelha conforme a orientação gravada pela câmera (EXIF). */
        internal fun oriented(src: Bitmap, origin: EncodedOrigin): Bitmap {
            if (origin == EncodedOrigin.TOP_LEFT) return src
            val swap = origin == EncodedOrigin.LEFT_TOP || origin == EncodedOrigin.RIGHT_TOP || origin == EncodedOrigin.RIGHT_BOTTOM || origin == EncodedOrigin.LEFT_BOTTOM
            val w = src.width.toFloat(); val h = src.height.toFloat()
            val out = createBitmap(if (swap) src.height else src.width, if (swap) src.width else src.height, Config.ARGB_8888)
            val c = SkCanvas(out.sk)
            when (origin) {
                EncodedOrigin.TOP_RIGHT -> { c.translate(w, 0f); c.scale(-1f, 1f) }
                EncodedOrigin.BOTTOM_RIGHT -> { c.translate(w, h); c.rotate(180f) }
                EncodedOrigin.BOTTOM_LEFT -> { c.translate(0f, h); c.scale(1f, -1f) }
                EncodedOrigin.LEFT_TOP -> { c.rotate(90f); c.scale(1f, -1f) }
                EncodedOrigin.RIGHT_TOP -> { c.translate(h, 0f); c.rotate(90f) }
                EncodedOrigin.RIGHT_BOTTOM -> { c.translate(h, w); c.rotate(270f); c.scale(1f, -1f) }
                EncodedOrigin.LEFT_BOTTOM -> { c.translate(0f, w); c.rotate(270f) }
                else -> {}
            }
            c.drawImage(src.image(), 0f, 0f)
            c.close()
            return out
        }
    }
}

object BitmapFactory {
    class Options {
        @JvmField var inJustDecodeBounds = false
        @JvmField var inSampleSize = 1
        @JvmField var inPreferredConfig: Bitmap.Config = Bitmap.Config.ARGB_8888
        @JvmField var inMutable = false
        @JvmField var outWidth = -1
        @JvmField var outHeight = -1
        @JvmField var outMimeType: String? = null
    }

    private fun mime(bytes: ByteArray): String? = when {
        bytes.size > 3 && bytes[0] == 0x89.toByte() && bytes[1] == 'P'.code.toByte() -> "image/png"
        bytes.size > 2 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xD8.toByte() -> "image/jpeg"
        bytes.size > 12 && String(bytes, 8, 4, Charsets.ISO_8859_1) == "WEBP" -> "image/webp"
        bytes.size > 3 && String(bytes, 0, 3, Charsets.ISO_8859_1) == "GIF" -> "image/gif"
        bytes.size > 2 && bytes[0] == 'B'.code.toByte() && bytes[1] == 'M'.code.toByte() -> "image/bmp"
        else -> null
    }

    /** Decodifica como no Android: a orientação EXIF fica por conta de quem chama (ExifInterface). */
    @JvmStatic fun decodeByteArray(bytes: ByteArray, offset: Int, length: Int, opts: Options?): Bitmap? = try {
        val b = if (offset == 0 && length == bytes.size) bytes else bytes.copyOfRange(offset, offset + length)
        val codec = Codec.makeFromData(Data.makeFromBytes(b))
        opts?.outWidth = codec.width
        opts?.outHeight = codec.height
        opts?.outMimeType = mime(b)
        if (opts?.inJustDecodeBounds == true) { codec.close(); null } else {
            codec.close()
            var bmp = Bitmap.fromImage(Image.makeFromEncoded(b))
            val s = (opts?.inSampleSize ?: 1).coerceAtLeast(1)
            if (s > 1) bmp = Bitmap.createScaledBitmap(bmp, (bmp.width / s).coerceAtLeast(1), (bmp.height / s).coerceAtLeast(1), true)
            bmp
        }
    } catch (_: Throwable) { null }

    @JvmStatic fun decodeByteArray(bytes: ByteArray, offset: Int, length: Int): Bitmap? = decodeByteArray(bytes, offset, length, null)
    @JvmStatic fun decodeFile(path: String?, opts: Options?): Bitmap? =
        if (path == null) null else runCatching { File(path).readBytes() }.getOrNull()?.let { decodeByteArray(it, 0, it.size, opts) }
    @JvmStatic fun decodeFile(path: String?): Bitmap? = decodeFile(path, null)
    @JvmStatic fun decodeStream(input: InputStream?): Bitmap? = decodeStream(input, null, null)
    @JvmStatic fun decodeStream(input: InputStream?, @Suppress("UNUSED_PARAMETER") pad: Rect?, opts: Options?): Bitmap? =
        input?.let { runCatching { it.readBytes() }.getOrNull() }?.let { decodeByteArray(it, 0, it.size, opts) }
}

/** O Canvas do Android desenhando num Canvas do Skia (tela, PNG ou página de PDF). */
class Canvas(val sk: SkCanvas) {
    private var bitmap: Bitmap? = null
    private var w = 0
    private var h = 0

    constructor(bmp: Bitmap) : this(SkCanvas(bmp.sk)) { bitmap = bmp; w = bmp.width; h = bmp.height; bmp.touched() }

    internal constructor(sk: SkCanvas, width: Int, height: Int) : this(sk) { w = width; h = height }

    val width: Int get() = w
    val height: Int get() = h

    private fun done() { bitmap?.touched() }

    fun drawColor(color: Int) { sk.drawPaint(SkPaint().also { it.color = color }); done() }
    fun drawARGB(a: Int, r: Int, g: Int, b: Int) = drawColor(Color.argb(a, r, g, b))
    fun drawRGB(r: Int, g: Int, b: Int) = drawColor(Color.rgb(r, g, b))
    fun drawPaint(p: Paint) { sk.drawPaint(p.sk()); done() }
    fun drawLine(x0: Float, y0: Float, x1: Float, y1: Float, p: Paint) {
        // no Android, linha não liga pra FILL/STROKE: desenha com a espessura do traço
        val s = p.sk(); s.mode = PaintMode.STROKE
        sk.drawLine(x0, y0, x1, y1, s); done()
    }
    fun drawLines(pts: FloatArray, p: Paint) { var i = 0; while (i + 3 < pts.size) { drawLine(pts[i], pts[i + 1], pts[i + 2], pts[i + 3], p); i += 4 } }
    fun drawPoint(x: Float, y: Float, p: Paint) { sk.drawPoint(x, y, p.sk()); done() }
    fun drawRect(l: Float, t: Float, r: Float, b: Float, p: Paint) { sk.drawRect(SkRect.makeLTRB(l, t, r, b), p.sk()); done() }
    fun drawRect(r: RectF, p: Paint) = drawRect(r.left, r.top, r.right, r.bottom, p)
    fun drawRect(r: Rect, p: Paint) = drawRect(r.left.toFloat(), r.top.toFloat(), r.right.toFloat(), r.bottom.toFloat(), p)
    fun drawRoundRect(l: Float, t: Float, r: Float, b: Float, rx: Float, ry: Float, p: Paint) {
        sk.drawRRect(RRect.makeLTRB(l, t, r, b, rx, ry), p.sk()); done()
    }
    fun drawRoundRect(r: RectF, rx: Float, ry: Float, p: Paint) = drawRoundRect(r.left, r.top, r.right, r.bottom, rx, ry, p)
    fun drawCircle(cx: Float, cy: Float, r: Float, p: Paint) { sk.drawCircle(cx, cy, r, p.sk()); done() }
    fun drawOval(l: Float, t: Float, r: Float, b: Float, p: Paint) { sk.drawOval(SkRect.makeLTRB(l, t, r, b), p.sk()); done() }
    fun drawOval(r: RectF, p: Paint) = drawOval(r.left, r.top, r.right, r.bottom, p)
    fun drawArc(l: Float, t: Float, r: Float, b: Float, start: Float, sweep: Float, useCenter: Boolean, p: Paint) {
        sk.drawArc(l, t, r, b, start, sweep, useCenter, p.sk()); done()
    }
    fun drawArc(oval: RectF, start: Float, sweep: Float, useCenter: Boolean, p: Paint) = drawArc(oval.left, oval.top, oval.right, oval.bottom, start, sweep, useCenter, p)
    fun drawPath(path: Path, p: Paint) { sk.drawPath(path.sk, p.sk()); done() }

    fun drawText(text: String, x: Float, y: Float, p: Paint) {
        if (text.isEmpty()) return
        val total = p.measureText(text)
        var cx = when (p.textAlign) { Paint.Align.LEFT -> x; Paint.Align.CENTER -> x - total / 2f; Paint.Align.RIGHT -> x - total }
        val s = p.sk()
        if (p.style == Paint.Style.FILL) s.mode = PaintMode.FILL
        val extra = p.letterSpacing * p.textSize
        for ((run, font) in p.runs(text)) {
            if (extra == 0f) {
                sk.drawString(run, cx, y, font, s)
                cx += font.measureTextWidth(run)
            } else {
                var i = 0
                while (i < run.length) {
                    val n = Character.charCount(run.codePointAt(i))
                    val ch = run.substring(i, i + n)
                    sk.drawString(ch, cx, y, font, s)
                    cx += font.measureTextWidth(ch) + extra
                    i += n
                }
            }
        }
        done()
    }
    fun drawText(text: CharSequence, start: Int, end: Int, x: Float, y: Float, p: Paint) = drawText(text.subSequence(start, end).toString(), x, y, p)
    fun drawText(text: CharArray, index: Int, count: Int, x: Float, y: Float, p: Paint) = drawText(String(text, index, count), x, y, p)

    fun drawBitmap(bmp: Bitmap, src: Rect?, dst: RectF, p: Paint?) {
        val s = src?.let { SkRect.makeLTRB(it.left.toFloat(), it.top.toFloat(), it.right.toFloat(), it.bottom.toFloat()) }
            ?: SkRect.makeWH(bmp.width.toFloat(), bmp.height.toFloat())
        sk.drawImageRect(bmp.image(), s, dst.sk(), SamplingMode.LINEAR, p?.sk(), true); done()
    }
    fun drawBitmap(bmp: Bitmap, src: Rect?, dst: Rect, p: Paint?) = drawBitmap(bmp, src, RectF(dst), p)
    fun drawBitmap(bmp: Bitmap, left: Float, top: Float, p: Paint?) = drawBitmap(bmp, null, RectF(left, top, left + bmp.width, top + bmp.height), p)

    fun save(): Int = sk.save()
    fun restore() { sk.restore() }
    fun restoreToCount(n: Int) { sk.restoreToCount(n) }
    val saveCount: Int get() = sk.saveCount
    fun translate(dx: Float, dy: Float) { sk.translate(dx, dy) }
    fun scale(sx: Float, sy: Float) { sk.scale(sx, sy) }
    fun scale(sx: Float, sy: Float, px: Float, py: Float) { sk.translate(px, py); sk.scale(sx, sy); sk.translate(-px, -py) }
    fun rotate(deg: Float) { sk.rotate(deg) }
    fun rotate(deg: Float, px: Float, py: Float) { sk.translate(px, py); sk.rotate(deg); sk.translate(-px, -py) }
    fun skew(sx: Float, sy: Float) { sk.skew(sx, sy) }
    fun clipRect(l: Float, t: Float, r: Float, b: Float): Boolean { sk.clipRect(SkRect.makeLTRB(l, t, r, b), ClipMode.INTERSECT, true); return true }
    fun clipRect(r: RectF): Boolean = clipRect(r.left, r.top, r.right, r.bottom)
    fun clipRect(r: Rect): Boolean = clipRect(r.left.toFloat(), r.top.toFloat(), r.right.toFloat(), r.bottom.toFloat())
    fun clipPath(p: Path): Boolean { sk.clipPath(p.sk, ClipMode.INTERSECT, true); return true }
}

/** Matriz 2D do Android (girar, escalar, mover). */
class Matrix() {
    // [a b c; d e f; 0 0 1]
    private var a = 1f; private var b = 0f; private var c = 0f
    private var d = 0f; private var e = 1f; private var f = 0f

    constructor(src: Matrix) : this() { set(src) }

    fun set(o: Matrix) { a = o.a; b = o.b; c = o.c; d = o.d; e = o.e; f = o.f }
    fun reset() { a = 1f; b = 0f; c = 0f; d = 0f; e = 1f; f = 0f }
    val isIdentity: Boolean get() = a == 1f && b == 0f && c == 0f && d == 0f && e == 1f && f == 0f

    private fun post(na: Float, nb: Float, nc: Float, nd: Float, ne: Float, nf: Float) {
        val ra = na * a + nb * d; val rb = na * b + nb * e; val rc = na * c + nb * f + nc
        val rd = nd * a + ne * d; val re = nd * b + ne * e; val rf = nd * c + ne * f + nf
        a = ra; b = rb; c = rc; d = rd; e = re; f = rf
    }
    private fun pre(na: Float, nb: Float, nc: Float, nd: Float, ne: Float, nf: Float) {
        val ra = a * na + b * nd; val rb = a * nb + b * ne; val rc = a * nc + b * nf + c
        val rd = d * na + e * nd; val re = d * nb + e * ne; val rf = d * nc + e * nf + f
        a = ra; b = rb; c = rc; d = rd; e = re; f = rf
    }
    private fun rot(deg: Float): FloatArray {
        val r = Math.toRadians(deg.toDouble())
        var cs = Math.cos(r).toFloat(); var sn = Math.sin(r).toFloat()
        if (Math.abs(cs) < 1e-6f) cs = 0f
        if (Math.abs(sn) < 1e-6f) sn = 0f
        return floatArrayOf(cs, -sn, sn, cs)
    }

    fun postRotate(deg: Float): Boolean { val r = rot(deg); post(r[0], r[1], 0f, r[2], r[3], 0f); return true }
    fun postRotate(deg: Float, px: Float, py: Float): Boolean { postTranslate(-px, -py); postRotate(deg); postTranslate(px, py); return true }
    fun postScale(sx: Float, sy: Float): Boolean { post(sx, 0f, 0f, 0f, sy, 0f); return true }
    fun postScale(sx: Float, sy: Float, px: Float, py: Float): Boolean { postTranslate(-px, -py); postScale(sx, sy); postTranslate(px, py); return true }
    fun postTranslate(dx: Float, dy: Float): Boolean { post(1f, 0f, dx, 0f, 1f, dy); return true }
    fun preRotate(deg: Float): Boolean { val r = rot(deg); pre(r[0], r[1], 0f, r[2], r[3], 0f); return true }
    fun preScale(sx: Float, sy: Float): Boolean { pre(sx, 0f, 0f, 0f, sy, 0f); return true }
    fun preTranslate(dx: Float, dy: Float): Boolean { pre(1f, 0f, dx, 0f, 1f, dy); return true }
    fun setRotate(deg: Float) { reset(); postRotate(deg) }
    fun setScale(sx: Float, sy: Float) { reset(); postScale(sx, sy) }
    fun setTranslate(dx: Float, dy: Float) { reset(); postTranslate(dx, dy) }

    fun mapPoints(pts: FloatArray) {
        var i = 0
        while (i + 1 < pts.size) { val x = pts[i]; val y = pts[i + 1]; pts[i] = a * x + b * y + c; pts[i + 1] = d * x + e * y + f; i += 2 }
    }
    fun mapRect(r: RectF): Boolean {
        val p = floatArrayOf(r.left, r.top, r.right, r.top, r.right, r.bottom, r.left, r.bottom)
        mapPoints(p)
        r.set(minOf(p[0], p[2], p[4], p[6]), minOf(p[1], p[3], p[5], p[7]), maxOf(p[0], p[2], p[4], p[6]), maxOf(p[1], p[3], p[5], p[7]))
        return true
    }
    internal fun sk(): org.jetbrains.skia.Matrix33 = org.jetbrains.skia.Matrix33(a, b, c, d, e, f, 0f, 0f, 1f)
}
