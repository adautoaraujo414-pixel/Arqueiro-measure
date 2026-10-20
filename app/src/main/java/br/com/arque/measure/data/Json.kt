package br.com.arque.measure.data

import br.com.arque.measure.model.Client
import br.com.arque.measure.model.DimObj
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.LengthUnit
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Obj
import br.com.arque.measure.model.Paper
import br.com.arque.measure.model.PhotoObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Reading
import br.com.arque.measure.model.Room
import br.com.arque.measure.model.ShapeKind
import br.com.arque.measure.model.ShapeObj
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.SheetMeta
import br.com.arque.measure.model.StrokeKind
import br.com.arque.measure.model.StrokeObj
import br.com.arque.measure.model.TextObj
import org.json.JSONArray
import org.json.JSONObject

/** Serialização JSON (org.json) do modelo. Valores de medida são sempre em milímetros. */
object Json {
    const val VERSION = 1

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
                .put("color", o.color).put("width", o.width.toDouble())
            is TextObj -> j.put("type", "text").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("at", ptToJson(o.at)).put("text", o.text).put("size", o.size.toDouble()).put("color", o.color)
            is DimObj -> j.put("type", "dim").put("photoId", o.photoId ?: JSONObject.NULL)
                .put("a", ptToJson(o.a)).put("b", ptToJson(o.b))
                .put("valueMm", o.valueMm ?: JSONObject.NULL)
                .put("source", o.source?.name ?: JSONObject.NULL)
                .put("history", JSONArray(o.history.map(::readingToJson)))
                .put("color", o.color).put("width", o.width.toDouble())
        }
        return j
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
                color = j.getInt("color"), width = j.getDouble("width").toFloat(), locked = locked,
            )
            "text" -> TextObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                at = ptFromJson(j.getJSONArray("at")), text = j.getString("text"),
                size = j.getDouble("size").toFloat(), color = j.getInt("color"), locked = locked,
            )
            "dim" -> DimObj(
                id = id, photoId = j.optStringOrNull("photoId"),
                a = ptFromJson(j.getJSONArray("a")), b = ptFromJson(j.getJSONArray("b")),
                valueMm = j.optDoubleOrNull("valueMm"),
                source = j.optStringOrNull("source")?.let { MeasureSource.valueOf(it) },
                history = j.optJSONArray("history")?.mapObjects(::readingFromJson) ?: emptyList(),
                color = j.getInt("color"), width = j.getDouble("width").toFloat(), locked = locked,
            )
            else -> throw IllegalArgumentException("tipo de objeto desconhecido: $type")
        }
    }

    // ---- Folha ----

    fun sheetToJson(s: Sheet): String = JSONObject()
        .put("v", VERSION)
        .put("id", s.id).put("roomId", s.roomId).put("name", s.name)
        .put("paper", s.paper.name).put("landscape", s.landscape).put("unit", s.unit.name)
        .put("objs", JSONArray(s.objs.map(::objToJson)))
        .toString()

    fun sheetFromJson(text: String): Sheet {
        val j = JSONObject(text)
        return Sheet(
            id = j.getString("id"), roomId = j.getString("roomId"), name = j.getString("name"),
            paper = Paper.valueOf(j.optString("paper", "A4")),
            landscape = j.optBoolean("landscape", false),
            unit = LengthUnit.valueOf(j.optString("unit", "MM")),
            objs = j.getJSONArray("objs").mapObjects(::objFromJson),
        )
    }

    // ---- Índice (clientes, ambientes, folhas) ----

    fun indexToJson(i: Index): String = JSONObject()
        .put("v", VERSION)
        .put(
            "clients",
            JSONArray(
                i.clients.map {
                    JSONObject().put("id", it.id).put("name", it.name).put("city", it.city)
                        .put("address", it.address).put("phone", it.phone).put("notes", it.notes)
                },
            ),
        )
        .put("rooms", JSONArray(i.rooms.map { JSONObject().put("id", it.id).put("clientId", it.clientId).put("name", it.name) }))
        .put("sheets", JSONArray(i.sheets.map { JSONObject().put("id", it.id).put("roomId", it.roomId).put("name", it.name) }))
        .toString()

    fun indexFromJson(text: String): Index {
        val j = JSONObject(text)
        return Index(
            clients = j.getJSONArray("clients").mapObjects {
                Client(
                    it.getString("id"), it.getString("name"), it.getString("city"),
                    it.optString("address", ""), it.optString("phone", ""), it.optString("notes", ""),
                )
            },
            rooms = j.getJSONArray("rooms").mapObjects { Room(it.getString("id"), it.getString("clientId"), it.getString("name")) },
            sheets = j.getJSONArray("sheets").mapObjects { SheetMeta(it.getString("id"), it.getString("roomId"), it.getString("name")) },
        )
    }
}
