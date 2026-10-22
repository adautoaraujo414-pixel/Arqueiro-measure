package br.com.arque.measure.data

import br.com.arque.measure.model.Folder
import br.com.arque.measure.model.Note
import br.com.arque.measure.model.NoteMeta
import br.com.arque.measure.model.Template
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.RoomObj
import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Cabinet
import br.com.arque.measure.model.Vao
import br.com.arque.measure.model.VaoKind
import br.com.arque.measure.model.Seg
import br.com.arque.measure.model.SegKind
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.StrokeKind
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import org.json.JSONArray
import org.json.JSONObject

/** Serialização JSON (org.json) do modelo. Valores de medida são sempre em milímetros. */
object Json {
    const val VERSION = 2

    private inline fun <T> JSONArray.mapObjects(f: (JSONObject) -> T): List<T> =
        (0 until length()).map { f(getJSONObject(it)) }

    private fun JSONObject.optStringOrNull(k: String): String? =
        if (has(k) && !isNull(k)) getString(k) else null

    private fun JSONObject.optDoubleOrNull(k: String): Double? =
        if (has(k) && !isNull(k)) getDouble(k) else null

    private fun ptToJson(p: Pt) = JSONArray().put(p.x.toDouble()).put(p.y.toDouble())
    private fun ptFromJson(a: JSONArray) = Pt(a.getDouble(0).toFloat(), a.getDouble(1).toFloat())

    // ---- Reading ----

    fun readingToJson(r: Reading): JSONObject = JSONObject()
        .put("id", r.id)
        .put("mm", r.mm)
        .put("source", r.source.name)
        .put("timeMs", r.timeMs)
        .put("device", r.device ?: JSONObject.NULL)
        .put("rawHex", r.rawHex ?: JSONObject.NULL)

    fun readingFromJson(o: JSONObject) = Reading(
        id = o.getString("id"),
        mm = o.getDouble("mm"),
        source = MeasureSource.valueOf(o.getString("source")),
        timeMs = o.getLong("timeMs"),
        device = o.optStringOrNull("device"),
        rawHex = o.optStringOrNull("rawHex"),
    )

    fun readingsToJson(list: List<Reading>): String =
        JSONObject().put("v", VERSION).put("readings", JSONArray(list.map(::readingToJson))).toString()

    fun readingsFromJson(text: String): List<Reading> =
        JSONObject(text).getJSONArray("readings").mapObjects(::readingFromJson)

    // ---- Objetos ----

    private fun objToJson(o: Obj): JSONObject {
        val j = JSONObject().put("id", o.id).put("locked", o.locked)
        when (o) {
            is PhotoObj -> j.put("type", "photo").put("file", o.file).put("pxW", o.pxW).put("pxH", o.pxH)
                .put("cx", o.cx.toDouble()).put("cy", o.cy.toDouble())
                .put("w", o.w.toDouble()).put("h", o.h.toDouble()).put("rot", o.rot.toDouble())
            is StrokeObj -> j.put("type", "stroke").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("pts", JSONArray(o.pts.map(::ptToJson))).put("color", o.color)
                .put("width", o.width.toDouble()).put("kind", o.kind.name)
            is ShapeObj -> j.put("type", "shape").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("kind", o.kind.name).put("a", ptToJson(o.a)).put("b", ptToJson(o.b))
                .put("color", o.color).put("width", o.width.toDouble()).put("fill", o.fill)
            is TextObj -> j.put("type", "text").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("at", ptToJson(o.at)).put("text", o.text).put("size", o.size.toDouble()).put("color", o.color)
            is CabObj -> j.put("type", "cab").put("at", ptToJson(o.at)).put("name", o.name).put("scaleDen", o.scaleDen)
                .put("cab", cabToJson(o.cab)).also { jj ->
                    o.wall?.let { jj.put("wall", wallToJson(it)) }
                    o.layout?.let { jj.put("layout", JSONObject().put("wallId", it.wallId).put("order", it.order)) }
                }
            is br.com.arque.measure.model.WallObj -> j.put("type", "wallplan").put("at", ptToJson(o.at)).put("wMm", o.wMm).put("hMm", o.hMm)
                .put("upperBottom", o.upperBottomMm).put("scaleDen", o.scaleDen)
            is RoomObj -> j.put("type", "room").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("pts", JSONArray(o.pts.map(::ptToJson))).put("closed", o.closed)
                .put(
                    "segs",
                    JSONArray(
                        o.segs.map { sg ->
                            JSONObject().put("kind", sg.kind.name).put("valueMm", sg.valueMm ?: JSONObject.NULL)
                                .put("source", sg.source?.name ?: JSONObject.NULL)
                                .put("history", JSONArray(sg.history.map(::readingToJson)))
                        },
                    ),
                )
                .put("color", o.color).put("width", o.width.toDouble())
                .put("labelScale", o.labelScale.toDouble()).put("labelAlpha", o.labelAlpha.toDouble())
                .put("labelIntensity", o.labelIntensity.toDouble())
            is DimObj -> j.put("type", "dim").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("a", ptToJson(o.a)).put("b", ptToJson(o.b))
                .put("valueMm", o.valueMm ?: JSONObject.NULL)
                .put("source", o.source?.name ?: JSONObject.NULL)
                .put("history", JSONArray(o.history.map(::readingToJson)))
                .put("color", o.color).put("width", o.width.toDouble())
                .put("labelScale", o.labelScale.toDouble()).put("labelAlpha", o.labelAlpha.toDouble())
                .put("labelIntensity", o.labelIntensity.toDouble()).put("refSize", o.refSize.toDouble())
        }
        return j
    }

    private fun cabToJson(c: Cabinet): JSONObject = JSONObject()
        .put("w", c.wMm).put("h", c.hMm).put("d", c.dMm).put("esp", c.espMm).put("rodape", c.rodapeMm)
        .put("travessa", c.travessaMm).put("hasTravessa", c.hasTravessa)
        .put("superior", c.superior).put("prateleiraMenor", c.prateleiraMenorMm).put("reguas", c.reguas).put("reguaMm", c.reguaMm).put("tampBaixo", c.tampBaixo).put("tampBaixoMm", c.tampBaixoMm).put("tampBaixoPassa", c.tampBaixoPassa).put("folga", c.folgaMm).put("folgaGaveta", c.folgaGavetaMm)
        .put("bordaSup", c.bordaSupMm).put("bordaInf", c.bordaInfMm).put("recuoFundo", c.recuoFundoMm)
        .put("back", c.hasBack)
        .put("folgaTopo", c.folgaTopoMm).put("moldura", c.molduraMm).put("hasMoldura", c.hasMoldura).put("hasRodape", c.hasRodape).put("hasBase", c.hasBase).put("tampEsq", c.tampEsq).put("tampDir", c.tampDir)
        .put("pedraW", c.pedraWMm ?: JSONObject.NULL).put("pedraD", c.pedraDMm ?: JSONObject.NULL)
        .put("dividers", JSONArray(c.dividers.map { it.toDouble() }))
        .put(
            "vaos",
            JSONArray(
                c.vaos.map { v ->
                    JSONObject().put("kind", v.kind.name).put("shelves", v.shelves).put("drawers", v.drawers).put("doors", v.doors).put("shelvesAbove", v.shelvesAbove).put("gaveteiro", v.gaveteiroMm).put("cava", v.cava).put("batente", v.batenteMm).put("shelfYs", JSONArray(v.shelfYs)).put("ovenW", v.ovenW).put("ovenH", v.ovenH).put("ovenTop", v.ovenTop)
                },
            ),
        )

    private fun cabFromJson(j: JSONObject): Cabinet {
        val d = Cabinet()
        return Cabinet(
            wMm = j.optDouble("w", d.wMm), hMm = j.optDouble("h", d.hMm), dMm = j.optDouble("d", d.dMm),
            espMm = j.optDouble("esp", d.espMm), rodapeMm = j.optDouble("rodape", d.rodapeMm),
            travessaMm = j.optDouble("travessa", d.travessaMm), hasTravessa = j.optBoolean("hasTravessa", true),
            superior = j.optBoolean("superior", false), prateleiraMenorMm = j.optDouble("prateleiraMenor", 20.0), reguas = j.optBoolean("reguas", false), reguaMm = j.optDouble("reguaMm", 70.0), tampBaixo = j.optBoolean("tampBaixo", false), tampBaixoMm = j.optDouble("tampBaixoMm", 30.0), tampBaixoPassa = j.optBoolean("tampBaixoPassa", false), folgaMm = j.optDouble("folga", d.folgaMm),
            folgaGavetaMm = j.optDouble("folgaGaveta", d.folgaGavetaMm),
            bordaSupMm = j.optDouble("bordaSup", d.bordaSupMm), bordaInfMm = j.optDouble("bordaInf", d.bordaInfMm),
            recuoFundoMm = j.optDouble("recuoFundo", d.recuoFundoMm), hasBack = j.optBoolean("back", true),
            folgaTopoMm = j.optDouble("folgaTopo", d.folgaTopoMm), molduraMm = j.optDouble("moldura", d.molduraMm),
            hasMoldura = j.optBoolean("hasMoldura", true), hasRodape = j.optBoolean("hasRodape", true), hasBase = j.optBoolean("hasBase", true), tampEsq = j.optBoolean("tampEsq", false), tampDir = j.optBoolean("tampDir", false),
            pedraWMm = j.optDoubleOrNull("pedraW"), pedraDMm = j.optDoubleOrNull("pedraD"),
            dividers = j.optJSONArray("dividers")?.let { a -> (0 until a.length()).map { a.getDouble(it).toFloat() } } ?: emptyList(),
            vaos = j.optJSONArray("vaos")?.mapObjects { v ->
                Vao(
                    kind = VaoKind.valueOf(v.optString("kind", "FREE")), shelves = v.optInt("shelves", 1),
                    drawers = v.optInt("drawers", 3), doors = v.optInt("doors", 1),
                    shelvesAbove = v.optInt("shelvesAbove", 0), gaveteiroMm = v.optDouble("gaveteiro", 0.0), cava = v.optBoolean("cava", false), batenteMm = v.optDouble("batente", 50.0),
                    ovenW = v.optDouble("ovenW", 560.0), ovenH = v.optDouble("ovenH", 595.0), ovenTop = v.optDouble("ovenTop", 0.0),
                    shelfYs = v.optJSONArray("shelfYs")?.let { a -> (0 until a.length()).map { a.getDouble(it) } } ?: emptyList(),
                )
            } ?: listOf(Vao()),
        )
    }

    private fun objFromJson(j: JSONObject): Obj {
        val id = j.getString("id")
        val locked = j.optBoolean("locked", false)
        return when (val type = j.getString("type")) {
            "photo" -> PhotoObj(
                id = id, file = j.getString("file"), pxW = j.getInt("pxW"), pxH = j.getInt("pxH"),
                cx = j.getDouble("cx").toFloat(), cy = j.getDouble("cy").toFloat(),
                w = j.getDouble("w").toFloat(), h = j.getDouble("h").toFloat(),
                rot = j.optDouble("rot", 0.0).toFloat(), locked = locked,
            )
            "stroke" -> StrokeObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                pts = j.getJSONArray("pts").let { a -> (0 until a.length()).map { ptFromJson(a.getJSONArray(it)) } },
                color = j.getInt("color"), width = j.getDouble("width").toFloat(),
                kind = StrokeKind.valueOf(j.optString("kind", "PEN")), locked = locked,
            )
            "shape" -> ShapeObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                kind = ShapeKind.valueOf(j.getString("kind")),
                a = ptFromJson(j.getJSONArray("a")), b = ptFromJson(j.getJSONArray("b")),
                color = j.getInt("color"), width = j.getDouble("width").toFloat(),
                fill = j.optBoolean("fill", false), locked = locked,
            )
            "text" -> TextObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                at = ptFromJson(j.getJSONArray("at")), text = j.getString("text"),
                size = j.getDouble("size").toFloat(), color = j.getInt("color"), locked = locked,
            )
            "cab" -> CabObj(
                id = id, at = ptFromJson(j.getJSONArray("at")), name = j.optString("name", "Móvel"),
                scaleDen = j.optInt("scaleDen", 10), cab = cabFromJson(j.getJSONObject("cab")), locked = locked,
                wall = j.optJSONObject("wall")?.let(::wallFromJson),
                layout = j.optJSONObject("layout")?.let { br.com.arque.measure.model.LayoutFit(it.optString("wallId"), it.optInt("order")) },
            )
            "wallplan" -> br.com.arque.measure.model.WallObj(
                id = id, at = ptFromJson(j.getJSONArray("at")), wMm = j.optDouble("wMm", 3000.0), hMm = j.optDouble("hMm", 2600.0),
                upperBottomMm = j.optDouble("upperBottom", 1400.0), scaleDen = j.optInt("scaleDen", 20), locked = locked,
            )
            "room" -> RoomObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                pts = j.getJSONArray("pts").let { a -> (0 until a.length()).map { ptFromJson(a.getJSONArray(it)) } },
                closed = j.optBoolean("closed", false),
                segs = j.getJSONArray("segs").mapObjects { sj ->
                    Seg(
                        kind = SegKind.valueOf(sj.optString("kind", "WALL")),
                        valueMm = sj.optDoubleOrNull("valueMm"),
                        source = sj.optStringOrNull("source")?.let { MeasureSource.valueOf(it) },
                        history = sj.optJSONArray("history")?.mapObjects(::readingFromJson) ?: emptyList(),
                    )
                },
                color = j.getInt("color"), width = j.getDouble("width").toFloat(),
                labelScale = j.optDouble("labelScale", 1.0).toFloat(),
                labelAlpha = j.optDouble("labelAlpha", 1.0).toFloat(),
                labelIntensity = j.optDouble("labelIntensity", 1.0).toFloat(),
                locked = locked,
            )
            "dim" -> DimObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                a = ptFromJson(j.getJSONArray("a")), b = ptFromJson(j.getJSONArray("b")),
                valueMm = j.optDoubleOrNull("valueMm"),
                source = j.optStringOrNull("source")?.let { MeasureSource.valueOf(it) },
                history = j.optJSONArray("history")?.mapObjects(::readingFromJson) ?: emptyList(),
                color = j.getInt("color"), width = j.getDouble("width").toFloat(),
                labelScale = j.optDouble("labelScale", 1.0).toFloat(),
                labelAlpha = j.optDouble("labelAlpha", 1.0).toFloat(),
                labelIntensity = j.optDouble("labelIntensity", 1.0).toFloat(),
                refSize = j.optDouble("refSize", 0.0).toFloat(), locked = locked,
            )
            else -> throw IllegalArgumentException("tipo de objeto desconhecido: $type")
        }
    }

    // ---- Nota ----

    fun noteToJson(n: Note): String = JSONObject()
        .put("v", VERSION)
        .put("id", n.id).put("name", n.name).put("folderId", n.folderId ?: JSONObject.NULL)
        .put("createdMs", n.createdMs).put("pinned", n.pinned).put("locked", n.locked)
        .put("trash", n.trash).put("unit", n.unit.name)
        .put(
            "pages",
            JSONArray(
                n.pages.map { p ->
                    JSONObject().put("id", p.id).put("tpl", p.tpl.name).put("objs", JSONArray(p.objs.map(::objToJson)))
                },
            ),
        )
        .toString()

    fun noteFromJson(text: String): Note {
        val j = JSONObject(text)
        val pages = j.getJSONArray("pages").mapObjects { p ->
            Sheet(
                id = p.getString("id"),
                tpl = Template.valueOf(p.optString("tpl", "ARAUJO")),
                objs = p.getJSONArray("objs").mapObjects(::objFromJson),
            )
        }.ifEmpty { listOf(Sheet()) }
        return Note(
            id = j.getString("id"), name = j.getString("name"), folderId = j.optStringOrNull("folderId"),
            createdMs = j.optLong("createdMs", 0L), pinned = j.optBoolean("pinned", false),
            locked = j.optBoolean("locked", false), trash = j.optBoolean("trash", false),
            unit = LengthUnit.valueOf(j.optString("unit", "M")), pages = pages,
        )
    }

    // ---- Índice (pastas e notas) ----

    fun indexToJson(i: Index): String = JSONObject()
        .put("v", VERSION)
        .put("folders", JSONArray(i.folders.map { JSONObject().put("id", it.id).put("name", it.name) }))
        .put(
            "notes",
            JSONArray(
                i.notes.map {
                    JSONObject().put("id", it.id).put("name", it.name).put("folderId", it.folderId ?: JSONObject.NULL)
                        .put("createdMs", it.createdMs).put("pinned", it.pinned).put("locked", it.locked)
                        .put("trash", it.trash).put("pageCount", it.pageCount).put("dimCount", it.dimCount)
                },
            ),
        )
        .toString()

    fun indexFromJson(text: String): Index {
        val j = JSONObject(text)
        return Index(
            folders = j.getJSONArray("folders").mapObjects { Folder(it.getString("id"), it.getString("name")) },
            notes = j.getJSONArray("notes").mapObjects {
                NoteMeta(
                    id = it.getString("id"), name = it.getString("name"), folderId = it.optStringOrNull("folderId"),
                    createdMs = it.optLong("createdMs", 0L), pinned = it.optBoolean("pinned", false),
                    locked = it.optBoolean("locked", false), trash = it.optBoolean("trash", false),
                    pageCount = it.optInt("pageCount", 1), dimCount = it.optInt("dimCount", 0),
                )
            },
        )
    }
}

private fun wallToJson(w: br.com.arque.measure.model.WallFit): JSONObject = JSONObject()
    .put("roomId", w.roomId).put("seg", w.seg).put("ax", w.ax.toDouble()).put("ay", w.ay.toDouble())
    .put("ux", w.ux.toDouble()).put("uy", w.uy.toDouble()).put("nx", w.nx.toDouble()).put("ny", w.ny.toDouble())
    .put("upm", w.upm).put("lenMm", w.lenMm).put("offMm", w.offMm)

private fun wallFromJson(j: JSONObject) = br.com.arque.measure.model.WallFit(
    roomId = j.optString("roomId"), seg = j.optInt("seg"),
    ax = j.optDouble("ax").toFloat(), ay = j.optDouble("ay").toFloat(),
    ux = j.optDouble("ux").toFloat(), uy = j.optDouble("uy").toFloat(),
    nx = j.optDouble("nx").toFloat(), ny = j.optDouble("ny").toFloat(),
    upm = j.optDouble("upm", 0.2), lenMm = j.optDouble("lenMm"), offMm = j.optDouble("offMm"),
)
