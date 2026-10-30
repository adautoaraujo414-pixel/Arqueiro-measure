import SwiftUI
import UIKit

enum EraserMode: String, CaseIterable { case PIXEL, STROKE, LASSO
    var label: String { self == .PIXEL ? tr("Pixels") : (self == .STROKE ? tr("Traços") : tr("Laço")) }
}

enum Tool: String, CaseIterable {
    case NAVIGATE, SELECT, PEN, PENCIL, HIGHLIGHTER, ERASER, LINE, DASHED, ARROW, DIM, DOOR, ROOM, RECT, RRECT, ELLIPSE, TRIANGLE, DARROW, CURVE, ELBOW, RTRI, DIAMOND, TRAP, LASSO, TEXT

    var label: String {
        switch self {
        case .NAVIGATE: return tr("Navegar"); case .SELECT: return tr("Selecionar"); case .PEN: return tr("Caneta"); case .PENCIL: return tr("Lápis")
        case .HIGHLIGHTER: return tr("Marca-texto"); case .ERASER: return tr("Borracha"); case .LINE: return tr("Linha"); case .DASHED: return tr("Tracejada")
        case .ARROW: return tr("Seta"); case .DIM: return tr("Seta de cota"); case .DOOR: return tr("Porta na linha"); case .ROOM: return tr("Cômodo"); case .RECT: return tr("Retângulo")
        case .RRECT: return tr("Retângulo arredondado"); case .ELLIPSE: return tr("Oval"); case .TRIANGLE: return tr("Triângulo"); case .DARROW: return tr("Seta dupla")
        case .CURVE: return tr("Curva"); case .ELBOW: return tr("Linha em L"); case .RTRI: return tr("Triângulo retângulo"); case .DIAMOND: return tr("Losango")
        case .TRAP: return tr("Trapézio"); case .LASSO: return tr("Laço"); case .TEXT: return tr("Texto")
        }
    }
    var drawing: Bool { !(self == .NAVIGATE || self == .SELECT || self == .TEXT) }
    /// Nome curto que aparece embaixo do ícone na barra.
    var short: String {
        switch self {
        case .DIM: return tr("Medida"); case .DOOR: return tr("Porta"); case .RRECT: return tr("Arredond."); case .RTRI: return tr("Tri. reto")
        case .DARROW: return tr("Seta dupla"); case .ELBOW: return tr("Linha L")
        default: return label
        }
    }
    var symbol: String {
        switch self {
        case .NAVIGATE, .SELECT: return "cursorarrow"
        case .PEN: return "custom.pen"
        case .PENCIL: return "pencil"
        case .HIGHLIGHTER: return "custom.marker"
        case .ERASER: return "eraser"
        case .LINE: return "line.diagonal"
        case .DASHED: return "line.3.horizontal.decrease"
        case .ARROW: return "arrow.up.right"
        case .DARROW: return "arrow.up.left.and.arrow.down.right"
        case .DIM: return "ruler"
        case .DOOR: return "door.left.hand.open"
        case .ROOM: return "house"
        case .RECT: return "rectangle"
        case .RRECT: return "app"
        case .ELLIPSE: return "oval"
        case .TRIANGLE: return "triangle"
        case .CURVE: return "point.topleft.down.curvedto.point.bottomright.up"
        case .ELBOW: return "arrow.turn.right.up"
        case .RTRI: return "triangle.lefthalf.filled"
        case .DIAMOND: return "diamond"
        case .TRAP: return "trapezoid.and.line.horizontal"
        case .LASSO: return "lasso"
        case .TEXT: return "textformat"
        }
    }
}

let shapeTools: [Tool] = [.LINE, .DASHED, .ARROW, .DARROW, .CURVE, .ELBOW, .DIM, .DOOR, .ROOM, .RECT, .RRECT, .ELLIPSE, .TRIANGLE, .RTRI, .DIAMOND, .TRAP]

/// Cores da paleta: preto, vermelho, azul, verde, âmbar.
let PALETTE: [Int] = [argb(0xFF111111), argb(0xFFE53935), argb(0xFF1E5BD8), argb(0xFF2E9E57), argb(0xFFF5B400)]
let EXTRA_COLORS: [Int] = [0xFF000000, 0xFF424242, 0xFF757575, 0xFFBDBDBD, 0xFF795548, 0xFF8D6E63,
                           0xFFB71C1C, 0xFFE53935, 0xFFFF5252, 0xFFFF6F00, 0xFFFF9800, 0xFFFFC107,
                           0xFFFFEB3B, 0xFFCDDC39, 0xFF8BC34A, 0xFF2E9E57, 0xFF1B5E20, 0xFF009688,
                           0xFF00BCD4, 0xFF03A9F4, 0xFF1E5BD8, 0xFF0D2A8C, 0xFF3F51B5, 0xFF673AB7,
                           0xFF9C27B0, 0xFFE91E63, 0xFFF48FB1, 0xFFFFFFFF].map { argb(UInt32($0)) }

let MM_PER_UNIT: CGFloat = 0.2645833
let UNITS_PER_MM: CGFloat = 3.7795277

/// Câmera sobre as folhas empilhadas (a câmera nunca muda folhas nem fotos).
struct ViewState {
    var scale: CGFloat = 1
    var ox: CGFloat = 0
    var oy: CGFloat = 0
    var pageOffsetY: CGFloat = 0
    func toWorld(_ o: CGPoint) -> Pt { Pt((o.x - ox) / scale, (o.y - oy) / scale) }
    func toSheet(_ o: CGPoint) -> Pt { let w = toWorld(o); return Pt(w.x, w.y - pageOffsetY) }
    func toScreen(_ p: Pt) -> CGPoint { CGPoint(x: p.x * scale + ox, y: (p.y + pageOffsetY) * scale + oy) }
}

struct TextEdit: Equatable { var id: String?; var at: Pt }

/// Uma nota aberta no editor: estado, câmera e ferramenta.
final class EditorSession: ObservableObject {
    @Published var rev = 0
    let state: EditorState
    var view = ViewState() { didSet { staticRev &+= 1; rev &+= 1 } }
    /// A folha desenha direto (sem passar pelo SwiftUI) a cada ponto do traço.
    var onCanvas: (() -> Void)?
    /// Muda quando o que está parado na folha mudou (fora do gesto): a imagem guardada é refeita.
    var staticRev = 0
    /// Rastro da borracha (folha), desenhado por cima enquanto apaga.
    var eraserTrail: [Pt] = []

    @Published private(set) var tool: Tool = .SELECT
    @Published var color: Int = PALETTE[0]
    /// Espessura em unidades de folha (padrão 0,55 mm).
    @Published var width: CGFloat = 0.55 * UNITS_PER_MM
    @Published var fill = false
    @Published var stylusOnly = false
    @Published var eraserMode: EraserMode = .PIXEL
    @Published var eraserSize: CGFloat = 12
    @Published var eraserOnlyHighlighter = false
    @Published var textEdit: TextEdit?
    @Published var screenLocked = false
    @Published var lockMsg: String?
    @Published var calcOpen = false
    @Published var loupe: CGPoint?
    @Published var lasso: [Pt] = []
    @Published var pull: CGFloat = 0
    /// Área de transferência (cortar/copiar/colar): vale entre folhas e entre notas enquanto o app estiver aberto.
    var clipboard: [Obj] { Clip.shared.objs }

    var canvasW: CGFloat = 0
    var canvasH: CGFloat = 0
    var topInsetPts: CGFloat = 165
    var bottomInsetPts: CGFloat = 90
    private var fitted = false
    private var tapTimes: [TimeInterval] = []
    private var tapPos: [CGPoint] = []
    private var tapSelId: String?
    private var tapSelSeg = -1

    init(_ note: Note, onCommit: @escaping (Note) -> Void) {
        state = EditorState(note, onCommit: onCommit)
        // durante o traço só a folha redesenha; os painéis (SwiftUI) só no começo e no fim do gesto
        state.onChange = { [weak self] in
            guard let self = self else { return }
            self.onCanvas?()
            if !self.state.inGesture { self.staticRev &+= 1; self.rev &+= 1 }
        }
        state.onGestureStart = { [weak self] in self?.rev &+= 1 }
    }

    func chooseTool(_ t: Tool) {
        tool = t
        if t == .NAVIGATE || (t.drawing && t != .DIM) { state.select(nil) }
        if t != .LASSO { lasso = [] }
        textEdit = nil
        rev &+= 1
    }

    // ---- três toques travam a tela ----
    func tapDown(_ t: TimeInterval) {
        if tapTimes.isEmpty || t - (tapTimes.last ?? 0) > 0.9 { tapSelId = state.selected?.id; tapSelSeg = state.selectedSeg }
    }

    func registerTap(_ t: TimeInterval, _ pos: CGPoint) -> Bool {
        if let lt = tapTimes.last, let lp = tapPos.last, t - lt > 0.7 || hypot(pos.x - lp.x, pos.y - lp.y) > 90 { tapTimes = []; tapPos = [] }
        tapTimes.append(t); tapPos.append(pos)
        if tapTimes.count >= 3 && t - tapTimes[tapTimes.count - 3] < 1.2 { tapTimes = []; tapPos = []; return true }
        return false
    }

    func toggleLock() {
        if !screenLocked, let id = tapSelId {
            if state.sheet.obj(id)?.asRoom != nil && tapSelSeg >= 0 { state.selectSeg(id, tapSelSeg) } else { state.select(id) }
        }
        screenLocked.toggle()
        lockMsg = screenLocked ? tr("Tela travada") : tr("Tela destravada")
    }

    // ---- câmera ----
    private var pageStep: CGFloat { Sheet.H + Sheet.GAP }
    private var worldH: CGFloat { CGFloat(state.note.pages.count) * pageStep - Sheet.GAP }
    var fitScale: CGFloat { canvasW > 0 ? canvasW / Sheet.W : 1 }
    var zoomPercent: Int { Int(view.scale / fitScale * 100) }

    func onCanvasSize(_ w: CGFloat, _ h: CGFloat) {
        canvasW = w; canvasH = h
        if !fitted && w > 0 && h > 0 { fitWidth(); fitted = true } else { clampView() }
    }

    func fitWidth() {
        var v = view
        v.scale = fitScale; v.ox = 0; v.oy = topInsetPts
        view = v
        updateActivePage()
    }

    func clampView(allowPull: Bool = false) {
        var v = view
        let s = v.scale
        let sw = Sheet.W * s
        v.ox = sw <= canvasW ? (canvasW - sw) / 2 : clamp(v.ox, canvasW - sw - 24, 24)
        let top = topInsetPts
        let minOy = canvasH - bottomInsetPts - worldH * s
        let lowest = min(top, minOy)
        var oy = min(v.oy, top)
        if oy < lowest {
            if allowPull { pull = lowest - oy; oy = lowest - pull * 0.5 } else { oy = lowest; pull = 0 }
        } else if pull != 0 { pull = 0 }
        v.oy = oy
        view = v
    }

    func panBy(_ dx: CGFloat, _ dy: CGFloat) {
        view.ox += dx; view.oy += dy
        clampView(allowPull: true)
    }

    func zoomAround(_ factor: CGFloat, _ cx: CGFloat, _ cy: CGFloat) {
        var v = view
        let ns = clamp(v.scale * factor, fitScale * 0.25, fitScale * 10)
        let real = ns / v.scale
        v.ox = cx - (cx - v.ox) * real
        v.oy = cy - (cy - v.oy) * real
        v.scale = ns
        view = v
        clampView()
    }

    /// Ao soltar: se puxou bastante além do fim, cria uma folha.
    @discardableResult
    func settle() -> Bool {
        var added = false
        if pull >= 80 && state.note.pages.count < Sheet.MAX_PAGES {
            state.addPage(state.note.pages.count, state.sheet.tpl)
            added = true
            updateActivePage()
        }
        pull = 0
        clampView()
        return added
    }

    func pickPage(_ screen: CGPoint) {
        let w = view.toWorld(screen)
        let i = clamp(Int(floor(w.y / pageStep)), 0, state.note.pages.count - 1)
        if i != state.pageIdx { state.setPage(i) }
        view.pageOffsetY = CGFloat(i) * pageStep
    }

    func updateActivePage() { view.pageOffsetY = CGFloat(state.pageIdx) * pageStep }

    func goToPage(_ i: Int) {
        let n = clamp(i, 0, state.note.pages.count - 1)
        state.setPage(n)
        var v = view
        v.scale = fitScale; v.ox = 0; v.oy = topInsetPts - CGFloat(n) * pageStep * v.scale
        view = v
        updateActivePage()
        clampView()
    }

    func fitButton() { goToPage(state.pageIdx) }

    func visiblePage() -> Int {
        let w = view.toWorld(CGPoint(x: canvasW / 2, y: canvasH / 2))
        return clamp(Int(floor(w.y / pageStep)), 0, state.note.pages.count - 1)
    }

    func addPhoto(_ file: String, _ pxW: Int, _ pxH: Int) {
        let vp = visiblePage()
        state.setPage(vp); updateActivePage()
        let s = state.sheet
        let aspect = CGFloat(pxW) / CGFloat(max(1, pxH))
        let w = min(s.width * 0.7, s.height * 0.5 * aspect), h = w / aspect
        let c = view.toSheet(CGPoint(x: canvasW / 2, y: canvasH / 2))
        let cascade = CGFloat(s.objs.filter { $0.asPhoto != nil }.count % 5) * 28
        state.addObj(.photo(PhotoObj(file: file, pxW: pxW, pxH: pxH, cx: clamp(c.x + cascade, 0, s.width), cy: clamp(c.y + cascade, 0, s.height), w: w, h: h)))
        chooseTool(.SELECT)
        if let last = state.sheet.objs.last { state.select(last.id) }
    }

    /// Várias fotos: 2 por folha, sem sobrepor.
    @discardableResult
    func addPhotos(_ list: [(String, Int, Int)], newPage: Bool) -> Int {
        if list.isEmpty { return 0 }
        if list.count == 1 && !newPage { addPhoto(list[0].0, list[0].1, list[0].2); return 1 }
        var page = visiblePage()
        state.setPage(page)
        var used = newPage ? 2 : state.sheet.objs.filter { $0.asPhoto != nil }.count
        var placed = 0
        for (file, pxW, pxH) in list {
            if used >= 2 {
                if !state.addPage(page + 1, .BLANK) { break }
                page += 1; used = 0
            }
            let s = state.sheet
            let top = s.height * 0.08
            let slotH = (s.height - top - s.height * 0.04) / 2
            let aspect = CGFloat(pxW) / CGFloat(max(1, pxH))
            var w = s.width * 0.86, h = w / aspect
            if h > slotH * 0.94 { h = slotH * 0.94; w = h * aspect }
            state.addObj(.photo(PhotoObj(file: file, pxW: pxW, pxH: pxH, cx: s.width / 2, cy: top + slotH * CGFloat(used) + slotH / 2, w: w, h: h)), select: false)
            used += 1; placed += 1
        }
        goToPage(state.pageIdx)
        chooseTool(.SELECT)
        return placed
    }

    func addTextCenter(_ text: String) {
        let vp = visiblePage()
        state.setPage(vp); updateActivePage()
        let c = view.toSheet(CGPoint(x: canvasW / 2, y: canvasH / 3))
        let n = state.sheet.objs.filter { $0.asText != nil }.count % 6
        commitText(TextEdit(id: nil, at: Pt(c.x, c.y + CGFloat(n) * 26)), text)
    }

    func commitText(_ edit: TextEdit, _ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let id = edit.id {
            if t.isEmpty { state.delete(id) } else { state.setText(id, t) }
        } else if !t.isEmpty {
            let photoId = Geo.photoAt(state.sheet, edit.at)?.id
            let local = Geo.fromSheet(state.sheet.photos(), photoId, edit.at)
            state.addObj(.text(TextObj(photoId: photoId, at: local, text: t, size: 18, color: color)))
        }
        textEdit = nil
    }

    func copyGroup(cut: Bool = false) {
        let objs = state.groupWithLinked()
        if objs.isEmpty { return }
        Clip.shared.put(objs, state.sheet, cut: cut); objectWillChange.send()
        if cut { state.deleteGroup() }
    }

    func copySelection(cut: Bool = false) {
        guard let o = state.selected else { return }
        var objs = [o]
        if case .photo = o { objs += state.sheet.objs.filter { $0.photoId == o.id } }
        Clip.shared.put(objs, state.sheet, cut: cut); objectWillChange.send()
        if cut { state.delete(o.id) }
    }

    /// Cola deslocado (cada colagem um pouco mais pro lado, pra não ficar em cima da original).
    func paste() {
        let c = Clip.shared
        if c.objs.isEmpty { return }
        c.n += 1
        state.pasteObjs(c.objs, from: c.from, off: 24 * CGFloat(c.n))
    }

    func applyColor(_ c: Int) {
        color = c
        if let s = state.selected, s.asPhoto == nil { state.setStyle(s.id, color: c) }
    }

    func applyWidth(_ deltaMm: CGFloat) {
        let w = clamp(width + deltaMm * UNITS_PER_MM, 0.1 * UNITS_PER_MM, 6 * UNITS_PER_MM)
        width = w
        if let s = state.selected, s.asPhoto == nil, s.asText == nil { state.setStyle(s.id, width: w) }
    }
}

/// O que foi copiado/cortado: os traços e a folha de onde vieram (pra converter quando estavam presos numa foto).
final class Clip {
    static let shared = Clip()
    private(set) var objs: [Obj] = []
    private(set) var from: Sheet?
    var n = 0
    func put(_ o: [Obj], _ sheet: Sheet, cut: Bool) { objs = o; from = sheet; n = cut ? -1 : 0 }
}
