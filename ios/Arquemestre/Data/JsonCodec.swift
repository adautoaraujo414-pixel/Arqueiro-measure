import Foundation
import CoreGraphics

/// JSON no MESMO formato do app Android (org.json). Medidas sempre em milímetros.
enum JsonCodec {
    static let VERSION = 2

    // ---- utilidades ----
    typealias J = [String: Any]

    static func parseObject(_ text: String) throws -> J {
        guard let d = text.data(using: .utf8), let o = try JSONSerialization.jsonObject(with: d) as? J else { throw CodecError.bad("objeto inválido") }
        return o
    }

    static func parseArray(_ text: String) throws -> [Any] {
        guard let d = text.data(using: .utf8), let o = try JSONSerialization.jsonObject(with: d) as? [Any] else { throw CodecError.bad("lista inválida") }
        return o
    }

    static func string(_ o: Any) -> String {
        guard let d = try? JSONSerialization.data(withJSONObject: o, options: [.withoutEscapingSlashes, .sortedKeys]) else { return "{}" }
        return String(decoding: d, as: UTF8.self)
    }

    enum CodecError: Error { case bad(String) }

    static func str(_ j: J, _ k: String) throws -> String {
        guard let v = j[k] as? String else { throw CodecError.bad("falta \(k)") }
        return v
    }
    static func optStr(_ j: J, _ k: String) -> String? {
        if j[k] == nil || j[k] is NSNull { return nil }
        return j[k] as? String
    }
    static func dbl(_ j: J, _ k: String) throws -> Double {
        guard let v = (j[k] as? NSNumber)?.doubleValue else { throw CodecError.bad("falta \(k)") }
        return v
    }
    static func optDbl(_ j: J, _ k: String) -> Double? {
        if j[k] == nil || j[k] is NSNull { return nil }
        if let n = j[k] as? NSNumber { return n.doubleValue }
        if let s = j[k] as? String { return Double(s) }
        return nil
    }
    static func dbl(_ j: J, _ k: String, _ def: Double) -> Double { optDbl(j, k) ?? def }
    static func int(_ j: J, _ k: String, _ def: Int) -> Int { (j[k] as? NSNumber)?.intValue ?? def }
    static func int64(_ j: J, _ k: String, _ def: Int64) -> Int64 { (j[k] as? NSNumber)?.int64Value ?? def }
    static func bool(_ j: J, _ k: String, _ def: Bool) -> Bool { (j[k] as? NSNumber)?.boolValue ?? def }
    static func s(_ j: J, _ k: String, _ def: String = "") -> String { (j[k] as? String) ?? def }
    static func nul(_ v: Any?) -> Any { v ?? NSNull() }

    static func pt(_ p: Pt) -> [Double] { [Double(p.x), Double(p.y)] }
    static func pt(_ a: Any?) throws -> Pt {
        guard let arr = a as? [Any], arr.count >= 2, let x = (arr[0] as? NSNumber)?.doubleValue, let y = (arr[1] as? NSNumber)?.doubleValue else { throw CodecError.bad("ponto inválido") }
        return Pt(CGFloat(x), CGFloat(y))
    }
    static func pts(_ a: Any?) throws -> [Pt] { try ((a as? [Any]) ?? []).map { try pt($0) } }

    // ---- Reading ----
    static func readingToJ(_ r: Reading) -> J {
        ["id": r.id, "mm": r.mm, "source": r.source.rawValue, "timeMs": r.timeMs, "device": nul(r.device), "rawHex": nul(r.rawHex)]
    }
    static func readingFromJ(_ o: J) throws -> Reading {
        Reading(id: try str(o, "id"), mm: try dbl(o, "mm"), source: MeasureSource(rawValue: try str(o, "source")) ?? .MANUAL,
                timeMs: int64(o, "timeMs", 0), device: optStr(o, "device"), rawHex: optStr(o, "rawHex"))
    }
    static func readingsToJson(_ list: [Reading]) -> String { string(["v": VERSION, "readings": list.map(readingToJ)]) }
    static func readingsFromJson(_ text: String) throws -> [Reading] {
        try ((try parseObject(text)["readings"] as? [Any]) ?? []).compactMap { $0 as? J }.map(readingFromJ)
    }

    // ---- Objetos ----
    static func objToJ(_ o: Obj) -> J {
        switch o {
        case .photo(let p):
            return ["id": p.id, "locked": p.locked, "type": "photo", "file": p.file, "pxW": p.pxW, "pxH": p.pxH,
                    "cx": Double(p.cx), "cy": Double(p.cy), "w": Double(p.w), "h": Double(p.h), "rot": Double(p.rot)]
        case .stroke(let s):
            return ["id": s.id, "locked": s.locked, "type": "stroke", "photoId": nul(s.photoId), "pts": s.pts.map(pt),
                    "color": s.color, "width": Double(s.width), "kind": s.kind.rawValue]
        case .shape(let s):
            return ["id": s.id, "locked": s.locked, "type": "shape", "photoId": nul(s.photoId), "kind": s.kind.rawValue,
                    "a": pt(s.a), "b": pt(s.b), "color": s.color, "width": Double(s.width), "fill": s.fill]
        case .text(let t):
            return ["id": t.id, "locked": t.locked, "type": "text", "photoId": nul(t.photoId), "at": pt(t.at), "text": t.text,
                    "size": Double(t.size), "color": t.color]
        case .dim(let d):
            return ["id": d.id, "locked": d.locked, "type": "dim", "photoId": nul(d.photoId), "a": pt(d.a), "b": pt(d.b),
                    "valueMm": nul(d.valueMm), "source": nul(d.source?.rawValue), "history": d.history.map(readingToJ),
                    "color": d.color, "width": Double(d.width), "labelScale": Double(d.labelScale), "labelAlpha": Double(d.labelAlpha),
                    "labelIntensity": Double(d.labelIntensity), "refSize": Double(d.refSize)]
        case .door(let d):
            return ["id": d.id, "locked": d.locked, "type": "door", "photoId": nul(d.photoId), "a": pt(d.a), "b": pt(d.b),
                    "hinge": d.hinge, "side": d.side, "slide": d.slide, "valueMm": nul(d.valueMm), "source": nul(d.source?.rawValue),
                    "history": d.history.map(readingToJ), "color": d.color, "width": Double(d.width),
                    "labelScale": Double(d.labelScale), "labelVert": d.labelVert]
        case .room(let r):
            return ["id": r.id, "locked": r.locked, "type": "room", "photoId": nul(r.photoId), "pts": r.pts.map(pt), "closed": r.closed,
                    "segs": r.segs.map { sg -> J in
                        ["kind": sg.kind.rawValue, "valueMm": nul(sg.valueMm), "source": nul(sg.source?.rawValue),
                         "history": sg.history.map(readingToJ), "hinge": sg.hinge, "side": sg.side, "slide": sg.slide]
                    },
                    "color": r.color, "width": Double(r.width), "labelScale": Double(r.labelScale), "labelAlpha": Double(r.labelAlpha),
                    "labelIntensity": Double(r.labelIntensity), "labelVert": r.labelVert]
        case .legacy(let l):
            var j = (try? parseObject(l.rawJSON)) ?? [:]
            j["id"] = l.id; j["locked"] = l.locked
            return j
        }
    }

    static func objFromJ(_ j: J) throws -> Obj {
        let id = try str(j, "id")
        let locked = bool(j, "locked", false)
        let type = try str(j, "type")
        switch type {
        case "photo":
            return .photo(PhotoObj(id: id, file: try str(j, "file"), pxW: int(j, "pxW", 1), pxH: int(j, "pxH", 1),
                                   cx: CGFloat(try dbl(j, "cx")), cy: CGFloat(try dbl(j, "cy")), w: CGFloat(try dbl(j, "w")), h: CGFloat(try dbl(j, "h")),
                                   rot: CGFloat(dbl(j, "rot", 0)), locked: locked))
        case "stroke":
            return .stroke(StrokeObj(id: id, photoId: optStr(j, "photoId"), pts: try pts(j["pts"]), color: int(j, "color", -16777216),
                                     width: CGFloat(try dbl(j, "width")), kind: StrokeKind(rawValue: s(j, "kind", "PEN")) ?? .PEN, locked: locked))
        case "shape":
            return .shape(ShapeObj(id: id, photoId: optStr(j, "photoId"), kind: ShapeKind(rawValue: try str(j, "kind")) ?? .LINE,
                                   a: try pt(j["a"]), b: try pt(j["b"]), color: int(j, "color", -16777216), width: CGFloat(try dbl(j, "width")),
                                   fill: bool(j, "fill", false), locked: locked))
        case "text":
            return .text(TextObj(id: id, photoId: optStr(j, "photoId"), at: try pt(j["at"]), text: try str(j, "text"),
                                 size: CGFloat(try dbl(j, "size")), color: int(j, "color", -16777216), locked: locked))
        case "dim":
            return .dim(DimObj(id: id, photoId: optStr(j, "photoId"), a: try pt(j["a"]), b: try pt(j["b"]), valueMm: optDbl(j, "valueMm"),
                               source: optStr(j, "source").flatMap(MeasureSource.init(rawValue:)),
                               history: try ((j["history"] as? [Any]) ?? []).compactMap { $0 as? J }.map(readingFromJ),
                               color: int(j, "color", -16777216), width: CGFloat(try dbl(j, "width")),
                               labelScale: CGFloat(dbl(j, "labelScale", 1)), labelAlpha: CGFloat(dbl(j, "labelAlpha", 1)),
                               labelIntensity: CGFloat(dbl(j, "labelIntensity", 1)), refSize: CGFloat(dbl(j, "refSize", 0)), locked: locked))
        case "door":
            return .door(DoorObj(id: id, photoId: optStr(j, "photoId"), a: try pt(j["a"]), b: try pt(j["b"]),
                                 hinge: int(j, "hinge", 0), side: int(j, "side", 1), slide: bool(j, "slide", false),
                                 valueMm: optDbl(j, "valueMm"), source: optStr(j, "source").flatMap(MeasureSource.init(rawValue:)),
                                 history: try ((j["history"] as? [Any]) ?? []).compactMap { $0 as? J }.map(readingFromJ),
                                 color: int(j, "color", argb(0xFFE53935)), width: CGFloat(dbl(j, "width", 2.1)),
                                 labelScale: CGFloat(dbl(j, "labelScale", 1)), labelVert: bool(j, "labelVert", false), locked: locked))
        case "room":
            let segs = try ((j["segs"] as? [Any]) ?? []).compactMap { $0 as? J }.map { sj -> Seg in
                Seg(kind: SegKind(rawValue: s(sj, "kind", "WALL")) ?? .WALL, valueMm: optDbl(sj, "valueMm"),
                    source: optStr(sj, "source").flatMap(MeasureSource.init(rawValue:)),
                    history: try ((sj["history"] as? [Any]) ?? []).compactMap { $0 as? J }.map(readingFromJ),
                    hinge: int(sj, "hinge", 0), side: int(sj, "side", 1), slide: bool(sj, "slide", false))
            }
            return .room(RoomObj(id: id, photoId: optStr(j, "photoId"), pts: try pts(j["pts"]), closed: bool(j, "closed", false), segs: segs,
                                 color: int(j, "color", -16777216), width: CGFloat(try dbl(j, "width")),
                                 labelScale: CGFloat(dbl(j, "labelScale", 1)), labelAlpha: CGFloat(dbl(j, "labelAlpha", 1)),
                                 labelIntensity: CGFloat(dbl(j, "labelIntensity", 1)), labelVert: bool(j, "labelVert", false), locked: locked))
        case "cab", "wallplan":
            return .legacy(legacy(j, id: id, locked: locked, type: type))
        default:
            throw CodecError.bad("tipo de objeto desconhecido: \(type)")
        }
    }

    /// Caixa aproximada dos objetos que só o Android edita (para desenhar e selecionar).
    static func legacy(_ j: J, id: String, locked: Bool, type: String) -> LegacyObj {
        let at = (try? pt(j["at"])) ?? Pt(60, 160)
        var w: CGFloat = 120, h: CGFloat = 120, origin = at
        var label = tr("Móvel (só visualização)")
        let k = 3.7795277
        if type == "cab" {
            let cab = (j["cab"] as? J) ?? [:]
            let den = Double(max(2, int(j, "scaleDen", 10)))
            let wMm = dbl(cab, "w", 600), hMm = dbl(cab, "h", 720), dMm = dbl(cab, "d", 550)
            label = s(j, "name", tr("Móvel")) + tr(" · {0} mm", Int(wMm))
            if let wf = j["wall"] as? J {
                let upm = dbl(wf, "upm", 0.2)
                let ax = dbl(wf, "ax", 0), ay = dbl(wf, "ay", 0), ux = dbl(wf, "ux", 1), uy = dbl(wf, "uy", 0)
                let nx = dbl(wf, "nx", 0), ny = dbl(wf, "ny", 1), off = dbl(wf, "offMm", 0)
                let x0 = ax + ux * off * upm, y0 = ay + uy * off * upm
                let lw = wMm * upm, dd = dMm * upm
                let xs = [x0, x0 + ux * lw, x0 + ux * lw + nx * dd, x0 + nx * dd]
                let ys = [y0, y0 + uy * lw, y0 + uy * lw + ny * dd, y0 + ny * dd]
                origin = Pt(CGFloat(xs.min()!), CGFloat(ys.min()!))
                w = CGFloat(xs.max()! - xs.min()!); h = CGFloat(ys.max()! - ys.min()!)
            } else {
                w = CGFloat(wMm * k / den); h = CGFloat(hMm * k / den)
            }
        } else {
            let den = Double(max(2, int(j, "scaleDen", 20)))
            let wMm = dbl(j, "wMm", 3000), hMm = dbl(j, "hMm", 2600)
            w = CGFloat(wMm * k / den); h = CGFloat(hMm * k / den)
            label = tr("Parede {0} × {1} mm (só visualização)", Int(wMm), Int(hMm))
        }
        var raw = j
        raw.removeValue(forKey: "id"); raw.removeValue(forKey: "locked")
        return LegacyObj(id: id, locked: locked, type: type, rawJSON: string(raw), at: origin, wUnits: max(w, 10), hUnits: max(h, 10), label: label)
    }

    // ---- Nota ----
    static func noteToJson(_ n: Note) -> String {
        string(["v": VERSION, "id": n.id, "name": n.name, "folderId": nul(n.folderId), "createdMs": n.createdMs,
                "pinned": n.pinned, "locked": n.locked, "trash": n.trash, "unit": n.unit.rawValue,
                "pages": n.pages.map { p -> J in ["id": p.id, "tpl": p.tpl.rawValue, "objs": p.objs.map(objToJ)] }])
    }

    static func noteFromJson(_ text: String) throws -> Note {
        let j = try parseObject(text)
        var pages = try ((j["pages"] as? [Any]) ?? []).compactMap { $0 as? J }.map { p -> Sheet in
            Sheet(id: try str(p, "id"), tpl: Template(rawValue: s(p, "tpl", "ARAUJO")) ?? .ARAUJO,
                  objs: try ((p["objs"] as? [Any]) ?? []).compactMap { $0 as? J }.map(objFromJ))
        }
        if pages.isEmpty { pages = [Sheet()] }
        return Note(id: try str(j, "id"), name: try str(j, "name"), folderId: optStr(j, "folderId"), createdMs: int64(j, "createdMs", 0),
                    pinned: bool(j, "pinned", false), locked: bool(j, "locked", false), trash: bool(j, "trash", false),
                    unit: LengthUnit(rawValue: s(j, "unit", "M")) ?? .M, pages: pages)
    }

    // ---- Índice ----
    static func indexToJson(_ i: LibIndex) -> String {
        string(["v": VERSION, "folders": i.folders.map { ["id": $0.id, "name": $0.name] },
                "notes": i.notes.map { m -> J in
                    ["id": m.id, "name": m.name, "folderId": nul(m.folderId), "createdMs": m.createdMs, "pinned": m.pinned,
                     "locked": m.locked, "trash": m.trash, "pageCount": m.pageCount, "dimCount": m.dimCount]
                }])
    }

    static func indexFromJson(_ text: String) throws -> LibIndex {
        let j = try parseObject(text)
        let folders = try ((j["folders"] as? [Any]) ?? []).compactMap { $0 as? J }.map { Folder(id: try str($0, "id"), name: try str($0, "name")) }
        let notes = try ((j["notes"] as? [Any]) ?? []).compactMap { $0 as? J }.map { m -> NoteMeta in
            NoteMeta(id: try str(m, "id"), name: try str(m, "name"), folderId: optStr(m, "folderId"), createdMs: int64(m, "createdMs", 0),
                     pinned: bool(m, "pinned", false), locked: bool(m, "locked", false), trash: bool(m, "trash", false),
                     pageCount: int(m, "pageCount", 1), dimCount: int(m, "dimCount", 0))
        }
        return LibIndex(folders: folders, notes: notes)
    }

    // ---- Agenda ----
    static func agendaToJson(_ list: [Appointment]) -> String {
        string(list.map { a -> J in
            ["id": a.id, "kind": a.kind.rawValue, "title": a.title, "start": a.startMs, "address": a.address, "notes": a.notes,
             "client": a.clientName, "phone": a.clientPhone, "projectId": nul(a.projectId), "noteId": nul(a.noteId),
             "quoteId": nul(a.quoteId), "done": a.done, "remind": a.remindMin]
        })
    }

    static func agendaFromJson(_ text: String) throws -> [Appointment] {
        try parseArray(text).compactMap { $0 as? J }.map { j in
            func opt(_ n: String) -> String? { let v = optStr(j, n); return (v?.isEmpty ?? true) ? nil : v }
            return Appointment(id: try str(j, "id"), kind: ApptKind(rawValue: s(j, "kind")) ?? .OUTRO, title: s(j, "title"),
                               startMs: int64(j, "start", 0), address: s(j, "address"), notes: s(j, "notes"), clientName: s(j, "client"),
                               clientPhone: s(j, "phone"), projectId: opt("projectId"), noteId: opt("noteId"), quoteId: opt("quoteId"),
                               remindMin: ((j["remind"] as? [Any]) ?? []).compactMap { ($0 as? NSNumber)?.intValue }, done: bool(j, "done", false))
        }
    }

    /// Clientes salvos no editor de móveis (moveis/projects.json).
    static func clientsFromProjects(_ json: String) -> [ClientRef] {
        guard let a = try? parseArray(json) else { return [] }
        return a.compactMap { $0 as? J }.compactMap { p in
            guard let c = p["client"] as? J else { return nil }
            let nome = s(c, "nome").trimmingCharacters(in: .whitespaces)
            if nome.isEmpty { return nil }
            let addr = [s(c, "end"), s(c, "cidade")].filter { !$0.isEmpty }.joined(separator: " · ")
            return ClientRef(name: nome, phone: s(c, "tel"), projectId: s(p, "id"), address: addr)
        }
    }

    // ---- Orçamentos ----
    static func companyToJson(_ c: Company) -> String {
        string(["name": c.name, "cnpj": c.cnpj, "address": c.address, "city": c.city, "phone": c.phone])
    }
    static func companyFromJson(_ text: String) throws -> Company {
        let j = try parseObject(text)
        return Company(name: s(j, "name"), cnpj: s(j, "cnpj"), address: s(j, "address"), city: s(j, "city"), phone: s(j, "phone"))
    }

    static func quotesToJson(_ list: [Quote]) -> String {
        string(list.map { q -> J in
            ["id": q.id, "client": q.clientName, "city": q.city, "date": q.dateMs, "discount": q.discountPct, "validity": q.validityDays,
             "drawing": q.includeDrawing, "noteId": nul(q.noteId), "notes": q.notes,
             "items": q.items.map { i -> J in ["id": i.id, "desc": i.desc, "qty": i.qty, "unit": i.unit, "value": i.unitValue] }]
        })
    }

    static func quotesFromJson(_ text: String) throws -> [Quote] {
        try parseArray(text).compactMap { $0 as? J }.map { j in
            let items = try ((j["items"] as? [Any]) ?? []).compactMap { $0 as? J }.map {
                QuoteItem(id: try str($0, "id"), desc: s($0, "desc"), qty: dbl($0, "qty", 1), unit: s($0, "unit", "un"), unitValue: dbl($0, "value", 0))
            }
            return Quote(id: try str(j, "id"), clientName: s(j, "client"), city: s(j, "city"), dateMs: int64(j, "date", nowMs()),
                         items: items, discountPct: dbl(j, "discount", 0), validityDays: int(j, "validity", 15),
                         includeDrawing: bool(j, "drawing", false), noteId: optStr(j, "noteId"), notes: s(j, "notes"))
        }
    }
}
