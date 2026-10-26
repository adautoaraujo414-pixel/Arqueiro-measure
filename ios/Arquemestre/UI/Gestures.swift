import UIKit

enum GestureAction {
    case tapDim(String)
    case tapSeg(String, Int)
    case editText(String?, Pt)
}

/// Interpreta toque, arraste e pinça sobre a folha (mesma lógica do Android).
/// A pinça redimensiona a FOTO selecionada; sem foto selecionada, só dá zoom na visualização.
final class GestureController {
    private enum Mode { case NONE, PAN, MOVE, HANDLE, STROKE, SHAPE, ERASE, ERASE_LASSO, ROOM, LASSO, GROUP }
    private enum H { case CORNER, ROTATE, A, B, VERTEX }

    private let s: EditorSession
    private var mode: Mode = .NONE
    private var handle: H = .A
    private var handleIdx = 0
    private var activeId: String?
    private var createdId: String?
    private var tapDimId: String?
    private var tapRoomId: String?
    private var tapSegIdx = -1
    private var tapTextId: String?
    private var downScreen = CGPoint.zero
    private var lastScreen = CGPoint.zero
    private var lastSheet = Pt(0, 0)
    private(set) var moved = false
    // escrita livre: segurar parado no fim do traço vira reta; as pontas encaixam em pontos próximos
    private var strokeStraight = false
    private var lastSigT: TimeInterval = -1
    private var lastSigScreen = CGPoint.zero
    private var groupBase: Sheet?
    private var groupStart = Pt(0, 0)
    // pinça
    private var prevC = CGPoint.zero
    private var prevSpan: CGFloat = 1
    private var prevAng: CGFloat = 0
    private var accAng: CGFloat = 0
    private var rotating = false
    private var pinchPhotoId: String?

    init(_ s: EditorSession) { self.s = s }

    private var st: EditorState { s.state }
    private let slop: CGFloat = 8
    private func tol() -> CGFloat { 22 / s.view.scale }
    private let straightKinds: Set<ShapeKind> = [.LINE, .DASHED, .ARROW, .DARROW]

    private func replace(_ o: Obj) -> Sheet { st.mapObj(o.id) { _ in o } }

    // ---- um dedo ----
    func down(_ screen: CGPoint, isFinger: Bool) {
        downScreen = screen; lastScreen = screen
        s.pickPage(screen)
        s.loupe = nil
        let p = s.view.toSheet(screen)
        lastSheet = p
        moved = false
        mode = .NONE
        activeId = nil; createdId = nil; tapDimId = nil; tapRoomId = nil; tapSegIdx = -1; tapTextId = nil
        let tool = s.tool
        if isFinger && s.stylusOnly && tool.drawing { mode = .PAN; return } // só o Apple Pencil desenha
        switch tool {
        case .NAVIGATE: mode = .PAN
        case .SELECT, .DIM, .DOOR: downSelectOrDim(screen, p, tool)
        case .ROOM: downRoom(screen, p)
        case .LASSO: downLasso(p)
        case .PEN, .PENCIL, .HIGHLIGHTER: startStroke(p, tool)
        case .ERASER:
            if s.eraserMode == .LASSO { s.lasso = [p]; mode = .ERASE_LASSO } else { mode = .ERASE; st.beginGesture(); erase(p) }
        case .LINE, .DASHED, .ARROW, .RECT, .RRECT, .ELLIPSE, .TRIANGLE, .DARROW, .CURVE, .ELBOW, .RTRI, .DIAMOND, .TRAP: startShape(p, tool)
        case .TEXT: mode = .NONE
        }
    }

    private func downSelectOrDim(_ screen: CGPoint, _ p: Pt, _ tool: Tool) {
        if let sel = st.selected, !sel.locked, let h = hitHandle(screen, sel) {
            handle = h.0; handleIdx = h.1; activeId = sel.id; mode = .HANDLE; st.beginGesture(); return
        }
        let prevSelected = st.selectedId
        if let hit = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit)), tool == .SELECT || (tool == .DIM && hit.asDim != nil) || (tool == .DOOR && hit.asDoor != nil) {
            if hit.asText != nil && prevSelected == hit.id { tapTextId = hit.id }
            if hit.asDim != nil { tapDimId = hit.id }
            st.select(hit.id)
            if let r = hit.asRoom {
                let k = Geo.hitSeg(st.sheet, r, p, tol(), st.unit)
                if k >= 0 { st.selectSeg(r.id, k); tapRoomId = r.id; tapSegIdx = k }
            }
            activeId = hit.id
            if !hit.locked { if case .legacy = hit {} else { mode = .MOVE; st.beginGesture() } }
            return
        }
        if tool == .SELECT { st.select(nil); mode = .PAN } else if tool == .DOOR { startDoor(p) } else { startShapeLike(p, dim: true, kind: nil) }
    }

    private func downRoom(_ screen: CGPoint, _ p: Pt) {
        if let sel = st.selected, let r = sel.asRoom, !r.locked, let h = hitHandle(screen, sel) {
            handle = h.0; handleIdx = h.1; activeId = r.id; mode = .HANDLE; st.beginGesture(); return
        }
        if let hit = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit))?.asRoom {
            let k = Geo.hitSeg(st.sheet, hit, p, tol(), st.unit)
            if k >= 0 { tapRoomId = hit.id; tapSegIdx = k }
        }
        let o = StrokeObj(photoId: nil, pts: [p], color: argb(0xFF2F80ED), width: 2.5, kind: .PENCIL)
        var sh = st.sheet; sh.objs.append(.stroke(o))
        st.live(sh)
        createdId = o.id
        mode = .ROOM
    }

    private func downLasso(_ p: Pt) {
        if !st.groupIds.isEmpty {
            if st.groupObjs().contains(where: { Geo.bounds(st.sheet, $0).contains(p, tol()) }) {
                mode = .GROUP; groupBase = st.sheet; groupStart = p; st.beginGesture(); return
            }
            st.selectGroup([])
        }
        s.lasso = [p]
        mode = .LASSO
    }

    private func finishRoom() {
        guard let prev = st.sheet.obj(createdId)?.asStroke else { st.cancelGesture(); return }
        let k = 1 / s.view.scale
        guard let res = Straighten.run(prev.pts, closeTol: clamp(36 * k, 20, 60), eps: clamp(10 * k, 5, 16), minSeg: clamp(22 * k, 14, 36)) else {
            st.cancelGesture(); return
        }
        let n = res.closed ? res.pts.count : res.pts.count - 1
        let tolS = clamp(26 * k, 14, 44)
        let photos = st.sheet.photos()
        let refPts = st.sheet.objs.compactMap { $0.asRoom }.filter { $0.id != prev.id }.flatMap { Geo.annPoints(photos, .room($0)) }
        let aligned = Straighten.alignTo(res.pts, res.closed, refPts, tolS)
        let snapped = snapToRooms(aligned, res.closed, tolS, prev.id)
        let room = RoomObj(photoId: nil, pts: snapped, closed: res.closed, segs: Array(repeating: Seg(), count: n), color: s.color, width: s.width)
        var sh = st.sheet
        sh.objs = sh.objs.filter { $0.id != prev.id } + [.room(room)]
        st.live(sh)
        st.endGesture()
        st.mergeRoomStray(room.id)
        st.selectSeg(room.id, 0)
    }

    /// Cantos do traço novo grudam nos cantos das paredes existentes; pontas de divisória grudam na parede.
    private func snapToRooms(_ pts: [Pt], _ closed: Bool, _ tolS: CGFloat, _ skipId: String) -> [Pt] {
        let photos = st.sheet.photos()
        let others = st.sheet.objs.compactMap { $0.asRoom }.filter { $0.id != skipId }
        if others.isEmpty { return pts }
        let verts = others.flatMap { Geo.annPoints(photos, .room($0)) }
        var segs: [(Pt, Pt)] = []
        for o in others {
            let q = Geo.annPoints(photos, .room(o))
            let n = o.closed ? q.count : q.count - 1
            if n > 0 { for i in 0..<n { segs.append((q[i], q[(i + 1) % q.count])) } }
        }
        func d(_ a: Pt, _ b: Pt) -> CGFloat { hypotf2(a.x - b.x, a.y - b.y) }
        return pts.enumerated().map { (i, p) in
            if let v = verts.min(by: { d($0, p) < d($1, p) }), d(v, p) <= tolS { return v }
            let end = !closed && (i == 0 || i == pts.count - 1)
            if !end { return p }
            var best: Pt?
            var bd = tolS
            for (a, b) in segs {
                let dx = b.x - a.x, dy = b.y - a.y
                let l2 = dx * dx + dy * dy
                if l2 < 1e-6 { continue }
                let t = clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / l2, 0, 1)
                let pr = Pt(a.x + dx * t, a.y + dy * t)
                let dd = d(pr, p)
                if dd <= bd { bd = dd; best = pr }
            }
            return best ?? p
        }
    }

    /// Pontos de encaixe: pontas de traços, linhas, setas e cantos de cômodo.
    private func snapPoint(_ p: Pt, _ skipId: String?) -> Pt? {
        let photos = st.sheet.photos()
        let tolS = 14 / s.view.scale
        var best: Pt?
        var bd = tolS
        func cand(_ q: Pt) { let dd = hypotf2(q.x - p.x, q.y - p.y); if dd <= bd { bd = dd; best = q } }
        for o in st.sheet.objs where o.id != skipId {
            switch o {
            case .stroke(let s2): if s2.pts.count >= 2 { cand(Geo.toSheet(photos, s2.photoId, s2.pts[0])); cand(Geo.toSheet(photos, s2.photoId, s2.pts[s2.pts.count - 1])) }
            case .shape(let sh): cand(Geo.toSheet(photos, sh.photoId, sh.a)); cand(Geo.toSheet(photos, sh.photoId, sh.b))
            case .dim(let dm): cand(Geo.toSheet(photos, dm.photoId, dm.a)); cand(Geo.toSheet(photos, dm.photoId, dm.b))
            case .room: Geo.annPoints(photos, o).forEach(cand)
            default: break
            }
        }
        return best
    }

    /// Caneta parada sem andar: conta o tempo.
    func still(_ t: TimeInterval) {
        if mode == .STROKE && !strokeStraight && lastSigT >= 0 && t - lastSigT > 0.55 { hold() }
    }

    /// Segurou parado no fim do traço: vira linha reta do começo até ali.
    func hold() {
        guard mode == .STROKE, !strokeStraight, let o = st.sheet.obj(createdId)?.asStroke else { return }
        let photos = st.sheet.photos()
        let pts = o.pts.map { Geo.toSheet(photos, o.photoId, $0) }
        if pts.count < 3 { return }
        var len: CGFloat = 0
        for i in 1..<pts.count { len += hypotf2(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y) }
        if len * s.view.scale < 30 { return }
        strokeStraight = true
        let a0 = snapPoint(pts[0], o.id) ?? pts[0]
        let e0 = snapPoint(pts[pts.count - 1], o.id) ?? Geo.snapAxis(a0, pts[pts.count - 1])
        var n = o; n.pts = [Geo.fromSheet(photos, o.photoId, a0), Geo.fromSheet(photos, o.photoId, e0)]
        st.live(replace(.stroke(n)))
    }

    private func startStroke(_ p: Pt, _ tool: Tool) {
        let photos = st.sheet.photos()
        let photoId = Geo.photoAt(st.sheet, p)?.id
        let kind: StrokeKind = tool == .PENCIL ? .PENCIL : (tool == .HIGHLIGHTER ? .HIGHLIGHTER : .PEN)
        let width: CGFloat = kind == .PEN ? s.width : (kind == .PENCIL ? max(1.2, s.width * 0.6) : s.width * 6)
        let color = (kind == .HIGHLIGHTER && s.color == PALETTE[0]) ? argb(0xFFFFEB3B) : s.color
        let o = StrokeObj(photoId: photoId, pts: [Geo.fromSheet(photos, photoId, p)], color: color, width: width, kind: kind)
        var sh = st.sheet; sh.objs.append(.stroke(o))
        st.live(sh)
        createdId = o.id
        mode = .STROKE
        strokeStraight = false
        lastSigT = -1
        lastSigScreen = s.view.toScreen(p)
    }

    private func startShape(_ p: Pt, _ tool: Tool) {
        let map: [Tool: ShapeKind] = [.ARROW: .ARROW, .DASHED: .DASHED, .RECT: .RECT, .RRECT: .RRECT, .ELLIPSE: .ELLIPSE, .TRIANGLE: .TRIANGLE,
                                      .DARROW: .DARROW, .CURVE: .CURVE, .ELBOW: .ELBOW, .RTRI: .RTRI, .DIAMOND: .DIAMOND, .TRAP: .TRAP]
        startShapeLike(p, dim: false, kind: map[tool] ?? .LINE)
    }

    /// Linha onde a porta está sendo marcada (a porta fica só num trecho dela).
    private var doorHost: (Pt, Pt)?

    private func startDoor(_ p: Pt) {
        doorHost = Geo.nearestLine(st.sheet, p, tol() * 1.6)
        let start = doorHost.map { Geo.projectOnSegment(p, $0.0, $0.1) } ?? p
        let o = DoorObj(a: start, b: start, width: max(1.6, s.width))
        var sh = st.sheet; sh.objs.append(.door(o))
        st.live(sh)
        createdId = o.id
        mode = .SHAPE
    }

    private func doorTarget(_ anchor: Pt, _ p: Pt, _ host: (Pt, Pt)?) -> Pt {
        host.map { Geo.projectOnSegment(p, $0.0, $0.1) } ?? Geo.snapAxis(anchor, p)
    }

    private func startShapeLike(_ p: Pt, dim: Bool, kind: ShapeKind?) {
        let photos = st.sheet.photos()
        let photoId = Geo.photoAt(st.sheet, p)?.id
        let local = Geo.fromSheet(photos, photoId, p)
        let o: Obj = dim
            ? .dim(DimObj(photoId: photoId, a: local, b: local, color: s.color, width: s.width, refSize: photoId.flatMap { photos[$0]?.w } ?? 0))
            : .shape(ShapeObj(photoId: photoId, kind: kind ?? .LINE, a: local, b: local, color: s.color, width: s.width, fill: s.fill))
        var sh = st.sheet; sh.objs.append(o)
        st.live(sh)
        createdId = o.id
        mode = .SHAPE
    }

    func move(_ screen: CGPoint, _ t: TimeInterval) {
        let p = s.view.toSheet(screen)
        if !moved && hypot(screen.x - downScreen.x, screen.y - downScreen.y) > slop { moved = true }
        switch mode {
        case .PAN: s.panBy(screen.x - lastScreen.x, screen.y - lastScreen.y)
        case .MOVE:
            if !moved { return }
            if let o = st.sheet.obj(activeId) {
                var n = Geo.translate(st.sheet, o, p.x - lastSheet.x, p.y - lastSheet.y)
                if case .photo(var ph) = n { ph.cx = clamp(ph.cx, 0, st.sheet.width); ph.cy = clamp(ph.cy, 0, st.sheet.height); n = .photo(ph) }
                st.live(replace(n))
            }
        case .HANDLE: applyHandle(p)
        case .STROKE, .ROOM:
            if let o = st.sheet.obj(createdId)?.asStroke {
                let photos = st.sheet.photos()
                if mode == .STROKE && strokeStraight {
                    let a = Geo.toSheet(photos, o.photoId, o.pts[0])
                    let end = snapPoint(p, o.id) ?? Geo.snapAxis(a, p)
                    var n = o; n.pts = [o.pts[0], Geo.fromSheet(photos, o.photoId, end)]
                    st.live(replace(.stroke(n)))
                } else {
                    let last = Geo.toSheet(photos, o.photoId, o.pts[o.pts.count - 1])
                    // passo mínimo bem pequeno (em pontos de tela) para a escrita fina ficar precisa em qualquer zoom
                    if hypotf2(p.x - last.x, p.y - last.y) * s.view.scale >= 0.6 {
                        var n = o; n.pts.append(Geo.fromSheet(photos, o.photoId, p))
                        st.live(replace(.stroke(n)))
                    }
                    if mode == .STROKE && t >= 0 {
                        if lastSigT < 0 || hypot(screen.x - lastSigScreen.x, screen.y - lastSigScreen.y) > 3 { lastSigScreen = screen; lastSigT = t }
                        else if t - lastSigT > 0.55 { hold() }
                    }
                }
            }
        case .SHAPE:
            if let o = st.sheet.obj(createdId), o.isAnn {
                let anchor = Geo.annPoints(st.sheet.photos(), o)[0]
                let straight = o.asDim != nil || (o.asShape.map { straightKinds.contains($0.kind) } ?? false)
                let target = o.asDoor != nil ? doorTarget(anchor, p, doorHost) : (straight ? Geo.snapAxis(anchor, p) : p)
                st.live(replace(Geo.withEndpoint(st.sheet, o, true, target)))
                if o.asDim != nil || o.asDoor != nil || o.asShape?.kind == .ARROW || o.asShape?.kind == .DARROW { s.loupe = screen }
            }
        case .ERASE: erase(p)
        case .LASSO, .ERASE_LASSO:
            if let last = s.lasso.last, hypotf2(p.x - last.x, p.y - last.y) < 3 {} else { s.lasso.append(p) }
        case .GROUP: if moved, let b = groupBase { st.moveGroupLive(b, p.x - groupStart.x, p.y - groupStart.y) }
        case .NONE: break
        }
        lastScreen = screen
        lastSheet = p
    }

    private func erasable(_ o: Obj) -> Bool {
        switch o {
        case .stroke(let s2): return !s2.locked && (!s.eraserOnlyHighlighter || s2.kind == .HIGHLIGHTER)
        case .shape(let s2): return !s2.locked && !s.eraserOnlyHighlighter
        case .text(let t): return !t.locked && !s.eraserOnlyHighlighter
        default: return false
        }
    }

    private func erase(_ p: Pt) {
        let sh = st.sheet
        let r = s.eraserSize / s.view.scale
        if s.eraserMode == .PIXEL {
            let photos = sh.photos()
            var changed = false
            var out: [Obj] = []
            for o in sh.objs {
                if !erasable(o) { out.append(o); continue }
                if case .stroke(let so) = o {
                    let sp = Geo.annPoints(photos, o)
                    guard let pieces = Eraser.erasePieces(sp, p, r + so.width / 2) else { out.append(o); continue }
                    changed = true
                    for (k, pc) in pieces.enumerated() {
                        var n = so
                        n.pts = pc.map { Geo.fromSheet(photos, so.photoId, $0) }
                        if k > 0 { n.id = newId() }
                        out.append(.stroke(n))
                    }
                } else if Geo.hitObj(sh, o, p, r, st.unit) { changed = true } else { out.append(o) }
            }
            if changed { var n = sh; n.objs = out; st.live(n) }
            return
        }
        let gone = Set(sh.objs.filter { erasable($0) && Geo.hitObj(sh, $0, p, r, st.unit) }.map(\.id))
        if !gone.isEmpty { var n = sh; n.objs = sh.objs.filter { !gone.contains($0.id) }; st.live(n) }
    }

    func up(_ screen: CGPoint) -> GestureAction? {
        let p = s.view.toSheet(screen)
        switch mode {
        case .PAN: s.settle()
        case .SHAPE:
            if !moved || (st.sheet.obj(createdId)?.asDoor.map { hypotf2($0.b.x - $0.a.x, $0.b.y - $0.a.y) < 6 } ?? false) { st.cancelGesture() } else {
                if let d = st.sheet.obj(createdId)?.asDim, d.refSize <= 0 {
                    let ab = Geo.annPoints(st.sheet.photos(), .dim(d))
                    var n = d; n.refSize = hypotf2(ab[1].x - ab[0].x, ab[1].y - ab[0].y)
                    st.live(replace(.dim(n)))
                }
                st.endGesture()
                if let id = createdId, st.sheet.obj(id) != nil { st.select(id) }
            }
        case .ROOM: if !moved { st.cancelGesture() } else { finishRoom() }
        case .LASSO:
            let ids = Geo.lassoPick(st.sheet, s.lasso)
            s.lasso = []
            st.selectGroup(ids)
        case .GROUP: if moved { st.endGesture() } else { st.cancelGesture() }
        case .ERASE_LASSO:
            let ids = Geo.lassoPick(st.sheet, s.lasso).filter { id in st.sheet.obj(id).map(erasable) ?? false }
            s.lasso = []
            st.deleteIds(Set(ids))
        case .STROKE, .MOVE, .HANDLE, .ERASE:
            let roomHandle = mode == .HANDLE && st.sheet.obj(activeId)?.asRoom != nil
            st.endGesture()
            if roomHandle, let id = activeId { st.mergeRoomStray(id) }
        case .NONE: break
        }
        s.loupe = nil
        var action: GestureAction?
        if !moved {
            let tool = s.tool
            if (tool == .SELECT || tool == .DIM), let id = tapDimId, let d = st.sheet.obj(id)?.asDim, !d.locked { action = .tapDim(d.id) }
            else if (tool == .SELECT || tool == .ROOM), let id = tapRoomId, let r = st.sheet.obj(id)?.asRoom {
                if st.selectedId != r.id || st.selectedSeg != tapSegIdx { st.selectSeg(r.id, tapSegIdx) }
                if !r.locked { action = .tapSeg(r.id, tapSegIdx) }
            } else if tool == .SELECT, let id = tapTextId { action = .editText(id, p) }
            else if tool == .TEXT {
                let t = st.sheet.obj(Geo.hit(st.sheet, p, tol(), st.unit))?.asText
                action = .editText(t?.id, p)
            }
        }
        mode = .NONE
        return action
    }

    /// Um segundo dedo apareceu: descarta o desenho em andamento.
    func cancelSingle() {
        s.loupe = nil
        if [.STROKE, .SHAPE, .ERASE, .ROOM, .GROUP, .MOVE, .HANDLE].contains(mode) { st.cancelGesture() }
        if mode == .LASSO || mode == .ERASE_LASSO { s.lasso = [] }
        mode = .NONE
    }

    // ---- alças ----
    private func hitHandle(_ screen: CGPoint, _ o: Obj) -> (H, Int)? {
        let r: CGFloat = 26
        func near(_ p: Pt) -> Bool { let sp = s.view.toScreen(p); return hypot(sp.x - screen.x, sp.y - screen.y) <= r }
        let photos = st.sheet.photos()
        switch o {
        case .photo(let p):
            if near(Geo.rotateHandle(p, s.view.scale)) { return (.ROTATE, 0) }
            for (i, c) in Geo.corners(p).enumerated() where near(c) { return (.CORNER, i) }
            return nil
        case .dim, .shape, .door:
            let pts = Geo.annPoints(photos, o)
            if near(pts[1]) { return (.B, 0) }
            if near(pts[0]) { return (.A, 0) }
            return nil
        case .room:
            for (i, p) in Geo.annPoints(photos, o).enumerated() where near(p) { return (.VERTEX, i) }
            return nil
        default: return nil
        }
    }

    private func normalizeDeg(_ d: CGFloat) -> CGFloat {
        var r = d.truncatingRemainder(dividingBy: 360)
        if r < 0 { r += 360 }
        let snap = (r / 90).rounded() * 90
        return abs(r - snap) < 3 ? snap.truncatingRemainder(dividingBy: 360) : r
    }

    private func applyHandle(_ p: Pt) {
        guard let o = st.sheet.obj(activeId) else { return }
        switch o {
        case .photo(var ph):
            if handle == .ROTATE {
                ph.rot = normalizeDeg(atan2(p.y - ph.cy, p.x - ph.cx) * 180 / .pi + 90)
                st.live(replace(.photo(ph)))
            } else {
                st.live(replace(.photo(Geo.resizeFromCorner(ph, handleIdx, p, max(st.sheet.width, st.sheet.height) * 3))))
            }
        case .dim, .shape, .door:
            let pts = Geo.annPoints(st.sheet.photos(), o)
            let other = handle == .B ? pts[0] : pts[1]
            let straight = o.asDim != nil || (o.asShape.map { straightKinds.contains($0.kind) } ?? false)
            let target = o.asDoor != nil ? doorTarget(other, p, Geo.nearestLine(st.sheet, other, 2, skip: o.id)) : (straight ? Geo.snapAxis(other, p) : p)
            st.live(replace(Geo.withEndpoint(st.sheet, o, handle == .B, target)))
            s.loupe = s.view.toScreen(target)
        case .room(var r):
            let i = handleIdx
            let sp = Geo.annPoints(st.sheet.photos(), o)
            let neighbour: Pt? = i > 0 ? sp[i - 1] : (sp.count > 1 ? sp[1] : nil)
            let target = neighbour.map { Geo.snapAxis($0, p) } ?? p
            if r.pts.indices.contains(i) {
                r.pts[i] = Geo.fromSheet(st.sheet.photos(), r.photoId, target)
                st.live(replace(.room(r)))
                s.loupe = s.view.toScreen(target)
            }
        default: break
        }
    }

    // ---- dois dedos ----
    private func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint { CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { max(1, hypot(b.x - a.x, b.y - a.y)) }
    private func ang(_ a: CGPoint, _ b: CGPoint) -> CGFloat { atan2(b.y - a.y, b.x - a.x) * 180 / .pi }

    func pinchBegin(_ a: CGPoint, _ b: CGPoint) {
        prevC = mid(a, b); prevSpan = dist(a, b); prevAng = ang(a, b)
        accAng = 0; rotating = false
        if let sel = st.selected?.asPhoto, !sel.locked { pinchPhotoId = sel.id; st.beginGesture() } else { pinchPhotoId = nil }
    }

    func pinch(_ a: CGPoint, _ b: CGPoint) {
        let c = mid(a, b), span = dist(a, b)
        let zoom = span / prevSpan
        var dAng = ang(a, b) - prevAng
        while dAng > 180 { dAng -= 360 }
        while dAng < -180 { dAng += 360 }
        if abs(dAng) > 90 { dAng = 0 }
        if let pid = pinchPhotoId, var ph = st.sheet.obj(pid)?.asPhoto {
            accAng += dAng
            var applyAng: CGFloat = 0
            if rotating { applyAng = dAng } else if abs(accAng) > 8 { rotating = true }
            let sh = st.sheet
            let kMin = Geo.MIN_PHOTO_SIDE / min(ph.w, ph.h)
            let kMax = max(sh.width, sh.height) * 3 / max(ph.w, ph.h)
            let k = clamp(clamp(zoom, 0.5, 2), kMin, max(kMin, kMax))
            let pc0 = s.view.toSheet(prevC), pc1 = s.view.toSheet(c)
            let th = applyAng * .pi / 180
            let cs = cos(th), sn = sin(th)
            let vx = ph.cx - pc0.x, vy = ph.cy - pc0.y
            ph.cx = clamp(pc1.x + k * (vx * cs - vy * sn), 0, sh.width)
            ph.cy = clamp(pc1.y + k * (vx * sn + vy * cs), 0, sh.height)
            ph.w *= k; ph.h *= k; ph.rot += applyAng
            st.live(replace(.photo(ph)))
        } else {
            s.view.ox += c.x - prevC.x
            s.view.oy += c.y - prevC.y
            s.zoomAround(zoom, c.x, c.y)
        }
        prevC = c; prevSpan = span; prevAng = ang(a, b)
    }

    func pinchEnd() {
        if let pid = pinchPhotoId {
            if var ph = st.sheet.obj(pid)?.asPhoto { ph.rot = normalizeDeg(ph.rot); st.live(replace(.photo(ph))) }
            st.endGesture()
        }
        pinchPhotoId = nil
        mode = .NONE
    }
}
