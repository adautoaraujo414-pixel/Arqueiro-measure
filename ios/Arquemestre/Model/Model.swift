import Foundation
import CoreGraphics

// Modelo igual ao do app Android (mesmos campos e mesmo JSON), para que um backup
// feito num aparelho abra no outro. Medidas sempre em milímetros.

func newId() -> String { UUID().uuidString.lowercased() }
func nowMs() -> Int64 { Int64(Date().timeIntervalSince1970 * 1000) }

struct Pt: Equatable, Hashable {
    var x: CGFloat
    var y: CGFloat
    init(_ x: CGFloat, _ y: CGFloat) { self.x = x; self.y = y }
    static func + (a: Pt, b: Pt) -> Pt { Pt(a.x + b.x, a.y + b.y) }
    static func - (a: Pt, b: Pt) -> Pt { Pt(a.x - b.x, a.y - b.y) }
    static func * (a: Pt, k: CGFloat) -> Pt { Pt(a.x * k, a.y * k) }
    var cg: CGPoint { CGPoint(x: x, y: y) }
}

enum MeasureSource: String { case MANUAL, BLUETOOTH }

enum LengthUnit: String, CaseIterable {
    case MM, CM, M
    var label: String { switch self { case .MM: return "mm"; case .CM: return "cm"; case .M: return "m" } }
    var next: LengthUnit { switch self { case .M: return .MM; case .MM: return .CM; case .CM: return .M } }
}

enum ShapeKind: String, CaseIterable { case LINE, DASHED, ARROW, RECT, RRECT, ELLIPSE, TRIANGLE, DARROW, CURVE, ELBOW, RTRI, DIAMOND, TRAP }

enum StrokeKind: String { case PEN, PENCIL, HIGHLIGHTER }

struct Reading: Equatable, Identifiable {
    var id: String = newId()
    var mm: Double
    var source: MeasureSource
    var timeMs: Int64
    var device: String? = nil
    var rawHex: String? = nil
}

/// Foto: centro, tamanho e rotação em unidades de folha.
struct PhotoObj: Equatable {
    var id: String = newId()
    var file: String
    var pxW: Int
    var pxH: Int
    var cx: CGFloat
    var cy: CGFloat
    var w: CGFloat
    var h: CGFloat
    var rot: CGFloat = 0
    var locked: Bool = false
}

struct StrokeObj: Equatable {
    var id: String = newId()
    var photoId: String?
    var pts: [Pt]
    var color: Int
    var width: CGFloat
    var kind: StrokeKind = .PEN
    var locked: Bool = false
}

struct ShapeObj: Equatable {
    var id: String = newId()
    var photoId: String?
    var kind: ShapeKind
    var a: Pt
    var b: Pt
    var color: Int
    var width: CGFloat
    var fill: Bool = false
    var locked: Bool = false
}

struct TextObj: Equatable {
    var id: String = newId()
    var photoId: String?
    var at: Pt
    var text: String
    var size: CGFloat
    var color: Int
    var locked: Bool = false
}

/// Cota (seta dimensional). valueMm é a medida real; nunca vem de pixels.
struct DimObj: Equatable {
    var id: String = newId()
    var photoId: String?
    var a: Pt
    var b: Pt
    var valueMm: Double? = nil
    var source: MeasureSource? = nil
    var history: [Reading] = []
    var color: Int
    var width: CGFloat
    var labelScale: CGFloat = 1
    var labelAlpha: CGFloat = 1
    var labelIntensity: CGFloat = 1
    var refSize: CGFloat = 0
    var locked: Bool = false
}

enum SegKind: String, CaseIterable {
    case WALL, PANEL, SINK, BASIN, DOOR, DIVIDER, WINDOW, OPENING
    var label: String {
        switch self {
        case .WALL: return "Parede"
        case .PANEL: return "Painel"
        case .SINK: return "Pia"
        case .BASIN: return "Cuba"
        case .DOOR: return "Porta"
        case .DIVIDER: return "Divisória"
        case .WINDOW: return "Janela"
        case .OPENING: return "Vão"
        }
    }
    var isOpening: Bool { self == .DOOR || self == .WINDOW || self == .OPENING }
}

struct Seg: Equatable {
    var kind: SegKind = .WALL
    var valueMm: Double? = nil
    var source: MeasureSource? = nil
    var history: [Reading] = []
    /// Porta: dobradiça no início (0) ou no fim (1).
    var hinge: Int = 0
    /// Porta: lado que abre (1 ou -1).
    var side: Int = 1
    var slide: Bool = false
}

/// Porta marcada num trecho de uma linha (linha vermelha "Porta" por cima, com sentido de abertura).
struct DoorObj: Equatable {
    var id: String = newId()
    var photoId: String? = nil
    var a: Pt
    var b: Pt
    var hinge: Int = 0
    var side: Int = 1
    var slide: Bool = false
    var valueMm: Double? = nil
    var source: MeasureSource? = nil
    var history: [Reading] = []
    var color: Int = argb(0xFFE53935)
    var width: CGFloat = 2.1
    var labelScale: CGFloat = 1
    var labelVert: Bool = false
    var locked: Bool = false
}

/// Contorno de cômodo (planta): vértices ligados por trechos retos, cada um com tipo e medida.
struct RoomObj: Equatable {
    var id: String = newId()
    var photoId: String?
    var pts: [Pt]
    var closed: Bool
    var segs: [Seg]
    var color: Int
    var width: CGFloat
    var labelScale: CGFloat = 1
    var labelAlpha: CGFloat = 1
    var labelIntensity: CGFloat = 1
    var labelVert: Bool = false
    var locked: Bool = false
    var segCount: Int { closed ? pts.count : pts.count - 1 }
}

/// Objetos que só o Android edita (módulo de armário e parede de projeto antigos). Ficam guardados
/// intactos (JSON original) e aparecem como um quadro na folha.
struct LegacyObj: Equatable {
    var id: String
    var locked: Bool
    var type: String
    var rawJSON: String
    var at: Pt
    var wUnits: CGFloat
    var hUnits: CGFloat
    var label: String
}

enum Obj: Equatable {
    case photo(PhotoObj)
    case stroke(StrokeObj)
    case shape(ShapeObj)
    case text(TextObj)
    case dim(DimObj)
    case door(DoorObj)
    case room(RoomObj)
    case legacy(LegacyObj)

    var id: String {
        switch self {
        case .photo(let o): return o.id
        case .stroke(let o): return o.id
        case .shape(let o): return o.id
        case .text(let o): return o.id
        case .dim(let o): return o.id
        case .door(let o): return o.id
        case .room(let o): return o.id
        case .legacy(let o): return o.id
        }
    }

    var locked: Bool {
        switch self {
        case .photo(let o): return o.locked
        case .stroke(let o): return o.locked
        case .shape(let o): return o.locked
        case .text(let o): return o.locked
        case .dim(let o): return o.locked
        case .door(let o): return o.locked
        case .room(let o): return o.locked
        case .legacy(let o): return o.locked
        }
    }

    /// Foto a que a anotação está colada (nil = coordenadas da folha).
    var photoId: String? {
        switch self {
        case .stroke(let o): return o.photoId
        case .shape(let o): return o.photoId
        case .text(let o): return o.photoId
        case .dim(let o): return o.photoId
        case .door(let o): return o.photoId
        case .room(let o): return o.photoId
        default: return nil
        }
    }

    var isAnn: Bool {
        switch self {
        case .photo, .legacy: return false
        default: return true
        }
    }

    var isLegacy: Bool { if case .legacy = self { return true }; return false }
    var asPhoto: PhotoObj? { if case .photo(let o) = self { return o }; return nil }
    var asDim: DimObj? { if case .dim(let o) = self { return o }; return nil }
    var asDoor: DoorObj? { if case .door(let o) = self { return o }; return nil }
    var asRoom: RoomObj? { if case .room(let o) = self { return o }; return nil }
    var asText: TextObj? { if case .text(let o) = self { return o }; return nil }
    var asStroke: StrokeObj? { if case .stroke(let o) = self { return o }; return nil }
    var asShape: ShapeObj? { if case .shape(let o) = self { return o }; return nil }

    func withLocked(_ v: Bool) -> Obj {
        switch self {
        case .photo(var o): o.locked = v; return .photo(o)
        case .stroke(var o): o.locked = v; return .stroke(o)
        case .shape(var o): o.locked = v; return .shape(o)
        case .text(var o): o.locked = v; return .text(o)
        case .dim(var o): o.locked = v; return .dim(o)
        case .door(var o): o.locked = v; return .door(o)
        case .room(var o): o.locked = v; return .room(o)
        case .legacy(var o): o.locked = v; return .legacy(o)
        }
    }

    func withId(_ nid: String) -> Obj {
        switch self {
        case .photo(var o): o.id = nid; return .photo(o)
        case .stroke(var o): o.id = nid; return .stroke(o)
        case .shape(var o): o.id = nid; return .shape(o)
        case .text(var o): o.id = nid; return .text(o)
        case .dim(var o): o.id = nid; return .dim(o)
        case .door(var o): o.id = nid; return .door(o)
        case .room(var o): o.id = nid; return .room(o)
        case .legacy(var o): o.id = nid; return .legacy(o)
        }
    }

    func withPhotoId(_ pid: String?) -> Obj {
        switch self {
        case .stroke(var o): o.photoId = pid; return .stroke(o)
        case .shape(var o): o.photoId = pid; return .shape(o)
        case .text(var o): o.photoId = pid; return .text(o)
        case .dim(var o): o.photoId = pid; return .dim(o)
        case .door(var o): o.photoId = pid; return .door(o)
        case .room(var o): o.photoId = pid; return .room(o)
        default: return self
        }
    }
}

enum Template: String, CaseIterable {
    case ARAUJO, BLANK, LINES
    var label: String {
        switch self {
        case .ARAUJO: return "Arquemestre croqui"
        case .BLANK: return "Em branco"
        case .LINES: return "Linha fina"
        }
    }
}

/// Uma folha A4 de uma nota (tamanho fixo).
struct Sheet: Equatable {
    static let W: CGFloat = 794
    static let H: CGFloat = 1123
    static let GAP: CGFloat = 28
    static let MAX_PAGES = 100

    var id: String = newId()
    var tpl: Template = .ARAUJO
    var objs: [Obj] = []

    var width: CGFloat { Sheet.W }
    var height: CGFloat { Sheet.H }

    func photos() -> [String: PhotoObj] {
        var m: [String: PhotoObj] = [:]
        for o in objs { if case .photo(let p) = o { m[p.id] = p } }
        return m
    }

    func obj(_ id: String?) -> Obj? {
        guard let id = id else { return nil }
        return objs.first { $0.id == id }
    }
}

struct Note: Equatable {
    var id: String = newId()
    var name: String
    var folderId: String? = nil
    var createdMs: Int64 = nowMs()
    var pinned = false
    var locked = false
    var trash = false
    var unit: LengthUnit = .M
    var pages: [Sheet] = [Sheet()]

    func dimCount() -> Int {
        pages.reduce(0) { acc, p in
            acc + p.objs.reduce(0) { a, o in
                switch o {
                case .dim, .door: return a + 1
                case .room(let r): return a + r.segs.count
                default: return a
                }
            }
        }
    }

    func meta() -> NoteMeta {
        NoteMeta(id: id, name: name, folderId: folderId, createdMs: createdMs, pinned: pinned, locked: locked, trash: trash, pageCount: pages.count, dimCount: dimCount())
    }
}

struct Folder: Equatable, Identifiable {
    var id: String = newId()
    var name: String
}

struct NoteMeta: Equatable, Identifiable {
    var id: String
    var name: String
    var folderId: String?
    var createdMs: Int64
    var pinned: Bool
    var locked: Bool
    var trash: Bool
    var pageCount: Int
    var dimCount: Int
}

struct LibIndex: Equatable {
    var folders: [Folder] = []
    var notes: [NoteMeta] = []
}
