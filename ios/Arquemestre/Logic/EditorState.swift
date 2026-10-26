import Foundation
import CoreGraphics

/// Estado de uma nota em edição (lógica pura, igual ao Android): folha ativa, seleção,
/// desfazer/refazer e operações. Um gesto contínuo (begin/live/end) vira UM passo de desfazer.
final class EditorState {
    static let MAX_UNDO = 200

    private(set) var note: Note
    private(set) var pageIdx = 0
    private(set) var selectedId: String?
    /// Segmento selecionado do cômodo (-1 = nenhum).
    private(set) var selectedSeg = -1
    private(set) var groupIds: Set<String> = []

    private var undoStack: [Note] = []
    private var redoStack: [Note] = []
    private var gestureBase: Note?

    var onCommit: (Note) -> Void
    var onChange: () -> Void

    init(_ initial: Note, onCommit: @escaping (Note) -> Void = { _ in }, onChange: @escaping () -> Void = {}) {
        note = initial
        self.onCommit = onCommit
        self.onChange = onChange
    }

    var sheet: Sheet { note.pages[clamp(pageIdx, 0, note.pages.count - 1)] }
    var unit: LengthUnit { note.unit }
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var selected: Obj? { sheet.obj(selectedId) }

    func select(_ id: String?) {
        if selectedId != id || !groupIds.isEmpty {
            selectedId = id
            selectedSeg = -1
            groupIds = []
            onChange()
        }
    }

    func selectGroup(_ ids: Set<String>) {
        selectedId = nil
        selectedSeg = -1
        groupIds = ids
        onChange()
    }

    func groupObjs() -> [Obj] { sheet.objs.filter { groupIds.contains($0.id) } }

    func groupWithLinked() -> [Obj] {
        let photoIds = Set(groupObjs().compactMap { $0.asPhoto?.id })
        return sheet.objs.filter { groupIds.contains($0.id) || ($0.photoId.map { photoIds.contains($0) } ?? false) }
    }

    func deleteIds(_ ids: Set<String>) {
        let gone = Set(sheet.objs.filter { ids.contains($0.id) && !$0.locked }.map(\.id))
        if gone.isEmpty { return }
        var s = sheet; s.objs = s.objs.filter { !gone.contains($0.id) }
        commit(s)
        fixSelection()
        onChange()
    }

    /// Limpa traços, formas e textos (fotos, cotas e cômodos ficam).
    func clearPageDrawings() {
        let keep = sheet.objs.filter {
            switch $0 { case .photo, .dim, .door, .room, .legacy: return true; default: return $0.locked }
        }
        if keep.count == sheet.objs.count { return }
        var s = sheet; s.objs = keep
        commit(s)
        fixSelection()
        onChange()
    }

    func deleteGroup() {
        let gone = Set(groupWithLinked().filter { !$0.locked }.map(\.id))
        if gone.isEmpty { return }
        var s = sheet; s.objs = s.objs.filter { !gone.contains($0.id) }
        commit(s)
        selectGroup([])
    }

    func moveGroupLive(_ base: Sheet, _ dx: CGFloat, _ dy: CGFloat) {
        let photoIds = Set(base.objs.filter { groupIds.contains($0.id) }.compactMap { $0.asPhoto?.id })
        var s = base
        s.objs = base.objs.map { o in
            if !groupIds.contains(o.id) { return o }
            if let pid = o.photoId, photoIds.contains(pid) { return o }
            return Geo.translate(base, o, dx, dy)
        }
        live(s)
    }

    func selectSeg(_ id: String, _ k: Int) {
        selectedId = id
        selectedSeg = k
        groupIds = []
        onChange()
    }

    func stepSeg(_ delta: Int) {
        guard let r = selected?.asRoom else { return }
        let n = r.segCount
        if n <= 0 { return }
        selectedSeg = ((selectedSeg < 0 ? 0 : selectedSeg) + delta + n) % n
        onChange()
    }

    func addRoom(_ room: RoomObj) {
        var s = sheet; s.objs.append(.room(room))
        commit(s)
        selectSeg(room.id, 0)
    }

    private func mapRoom(_ id: String, _ f: (inout RoomObj) -> Void) -> Sheet? {
        guard var r = sheet.obj(id)?.asRoom, !r.locked else { return nil }
        f(&r)
        return mapObj(id) { _ in .room(r) }
    }

    func setSegKind(_ id: String, _ k: Int, _ kind: SegKind) {
        guard let r = sheet.obj(id)?.asRoom, r.segs.indices.contains(k) else { return }
        if let s = mapRoom(id, { $0.segs[k].kind = kind }) { commit(s) }
        _ = r
    }

    func setSegDoor(_ id: String, _ k: Int, hinge: Int? = nil, side: Int? = nil, slide: Bool? = nil) {
        guard let r = sheet.obj(id)?.asRoom, r.segs.indices.contains(k) else { return }
        if let s = mapRoom(id, { rr in
            if let h = hinge { rr.segs[k].hinge = h }
            if let sd = side { rr.segs[k].side = sd }
            if let sl = slide { rr.segs[k].slide = sl }
        }) { commit(s) }
    }

    /// Divide o trecho k. mid = nil parte no meio; mid = porta/janela/vão abre no meio da parede.
    func splitSeg(_ id: String, _ k: Int, _ mid: SegKind? = nil) {
        guard let r = sheet.obj(id)?.asRoom, !r.locked, r.segs.indices.contains(k) else { return }
        let a = r.pts[k], b = r.pts[(k + 1) % r.pts.count]
        let sg = r.segs[k]
        var clean = sg; clean.valueMm = nil; clean.source = nil; clean.history = []
        var newPts: [Pt], newSegs: [Seg]
        if let mid = mid {
            let want: Double = mid == .WINDOW ? 1200 : 800
            let f = CGFloat(sg.valueMm.map { clamp(want / $0, 0.15, 0.8) } ?? (1.0 / 3.0))
            let t0 = (1 - f) / 2
            newPts = [a + (b - a) * t0, a + (b - a) * (t0 + f)]
            var wall = clean; wall.kind = sg.kind.isOpening ? .WALL : sg.kind
            newSegs = [wall, Seg(kind: mid), wall]
        } else {
            newPts = [a + (b - a) * 0.5]
            newSegs = [clean, clean]
        }
        var pts = r.pts; pts.insert(contentsOf: newPts, at: k + 1)
        var segs = r.segs; segs.remove(at: k); segs.insert(contentsOf: newSegs, at: k)
        if let s = mapRoom(id, { $0.pts = pts; $0.segs = segs }) { commit(s) }
        selectSeg(id, mid == nil ? k : k + 1)
    }

    func setAllSegKinds(_ id: String, _ kind: SegKind) {
        if let s = mapRoom(id, { rr in for i in rr.segs.indices { rr.segs[i].kind = kind } }) { commit(s) }
    }

    func setRoomClosed(_ id: String, _ closed: Bool) {
        guard let r = sheet.obj(id)?.asRoom, !r.locked, r.closed != closed, r.pts.count >= 3 else { return }
        let segs = closed ? r.segs + [Seg()] : Array(r.segs.dropLast())
        if let s = mapRoom(id, { $0.closed = closed; $0.segs = segs }) { commit(s) }
        if selectedSeg >= segs.count { selectedSeg = segs.count - 1 }
    }

    /// Tira os pontos soltos no meio das retas: uma reta = uma medida.
    @discardableResult
    func mergeRoomStray(_ id: String) -> Bool {
        guard let r = sheet.obj(id)?.asRoom, !r.locked else { return false }
        let nSeg = r.segs.count
        var fixed = Set<Int>()
        for i in r.pts.indices {
            let before: Seg? = i == 0 ? (r.closed && nSeg > 0 ? r.segs[nSeg - 1] : nil) : (i - 1 < nSeg ? r.segs[i - 1] : nil)
            let after: Seg? = i < nSeg ? r.segs[i] : nil
            if let b = before, let a = after, b.kind != a.kind || b.kind.isOpening || a.kind.isOpening { fixed.insert(i) }
        }
        let keep = Straighten.strayFreeIndices(r.pts, r.closed, fixed: fixed)
        if keep.count == r.pts.count { return false }
        let n = r.pts.count
        var segs: [Seg] = []
        var pairs: [(Int, Int)] = []
        if r.closed { pairs = keep.indices.map { (keep[$0], keep[($0 + 1) % keep.count]) } }
        else { for i in 0..<(keep.count - 1) { pairs.append((keep[i], keep[i + 1])) } }
        for (a, b) in pairs {
            var group: [Seg] = []
            var idx = a
            repeat { if idx < r.segs.count { group.append(r.segs[idx]) }; idx = (idx + 1) % n } while idx != b
            var first = group.first ?? Seg()
            let all = !group.isEmpty && group.allSatisfy { $0.valueMm != nil }
            if group.count > 1 {
                first.valueMm = all ? group.reduce(0) { $0 + ($1.valueMm ?? 0) } : nil
                first.source = all ? first.source : nil
                first.history = []
            }
            segs.append(first)
        }
        let newPts = keep.map { r.pts[$0] }
        if let s = mapRoom(id, { $0.pts = newPts; $0.segs = segs }) { commit(s) }
        if selectedSeg >= segs.count { selectedSeg = segs.count - 1 }
        return true
    }

    func setRoomLabelScale(_ id: String, _ scale: CGFloat, live isLive: Bool = false) {
        guard let s = mapRoom(id, { $0.labelScale = clamp(scale, 0.1, 4) }) else { return }
        if isLive { live(s) } else { commit(s) }
    }

    func setPage(_ i: Int) {
        let n = clamp(i, 0, note.pages.count - 1)
        if n != pageIdx {
            pageIdx = n
            selectedId = nil
            groupIds = []
            onChange()
        }
    }

    private func withSheet(_ s: Sheet) -> Note {
        var n = note
        n.pages[clamp(pageIdx, 0, n.pages.count - 1)] = s
        return n
    }

    // ---- gestos contínuos ----
    func beginGesture() { if gestureBase == nil { gestureBase = note } }

    func live(_ newSheet: Sheet) {
        if gestureBase == nil { gestureBase = note }
        note = withSheet(newSheet)
        onChange()
    }

    func endGesture() {
        guard let base = gestureBase else { return }
        gestureBase = nil
        if base != note {
            push(base)
            redoStack.removeAll()
            onCommit(note)
        }
        onChange()
    }

    func cancelGesture() {
        if let g = gestureBase { note = g }
        gestureBase = nil
        fixSelection()
        onChange()
    }

    // ---- operações discretas ----
    func commit(_ newSheet: Sheet) { commitNote(withSheet(newSheet)) }

    func commitNote(_ n: Note) {
        if n == note { return }
        push(note)
        redoStack.removeAll()
        note = n
        onCommit(note)
        onChange()
    }

    private func push(_ s: Note) {
        undoStack.append(s)
        if undoStack.count > EditorState.MAX_UNDO { undoStack.removeFirst() }
    }

    private func restore(_ n: Note) {
        note = n
        pageIdx = clamp(pageIdx, 0, note.pages.count - 1)
        fixSelection()
        onCommit(note)
        onChange()
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        cancelGesture()
        redoStack.append(note)
        restore(undoStack.removeLast())
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        cancelGesture()
        undoStack.append(note)
        restore(redoStack.removeLast())
    }

    private func fixSelection() {
        if selectedId != nil && sheet.obj(selectedId) == nil { selectedId = nil }
    }

    func mapObj(_ id: String, _ f: (Obj) -> Obj) -> Sheet {
        var s = sheet
        s.objs = s.objs.map { $0.id == id ? f($0) : $0 }
        return s
    }

    func addObj(_ o: Obj, select sel: Bool = true) {
        var s = sheet; s.objs.append(o)
        commit(s)
        if sel { select(o.id) }
    }

    /// Apaga o objeto. Apagar uma foto apaga também o que está colado nela.
    func delete(_ id: String) {
        guard let o = sheet.obj(id), !o.locked else { return }
        var gone: Set<String> = [id]
        if case .photo = o { for a in sheet.objs where a.photoId == id { gone.insert(a.id) } }
        var s = sheet; s.objs = s.objs.filter { !gone.contains($0.id) }
        commit(s)
        fixSelection()
        onChange()
    }

    func duplicate(_ id: String) {
        guard let o = sheet.obj(id) else { return }
        if case .legacy = o { return }
        let off: CGFloat = 24
        var newObjs: [Obj] = []
        let dupId: String
        if case .photo(var p) = o {
            p.id = newId(); p.cx += off; p.cy += off; p.locked = false
            dupId = p.id
            newObjs.append(.photo(p))
            for a in sheet.objs where a.photoId == o.id { newObjs.append(a.withId(newId()).withPhotoId(p.id)) }
        } else {
            let moved = Geo.translate(sheet, o, off, off).withId(newId()).withLocked(false)
            dupId = moved.id
            newObjs.append(moved)
        }
        var s = sheet; s.objs += newObjs
        commit(s)
        select(dupId)
    }

    func pasteObjs(_ src: [Obj]) {
        if src.isEmpty { return }
        var idMap: [String: String] = [:]
        for o in src { idMap[o.id] = newId() }
        let copies: [Obj] = src.map { o in
            var n = o.withId(idMap[o.id]!).withLocked(false)
            if case .photo(var p) = n { p.cx += 24; p.cy += 24; n = .photo(p) }
            if let pid = n.photoId, let np = idMap[pid] { n = n.withPhotoId(np) }
            return n
        }
        var s = sheet; s.objs += copies
        commit(s)
        if copies.count > 1 { selectGroup(Set(copies.map(\.id))) } else { select(copies[0].id) }
    }

    func reorder(_ id: String, up: Bool) {
        guard let i = sheet.objs.firstIndex(where: { $0.id == id }) else { return }
        let j = up ? i + 1 : i - 1
        guard sheet.objs.indices.contains(j) else { return }
        var s = sheet; s.objs.swapAt(i, j)
        commit(s)
    }

    func setLocked(_ id: String, _ locked: Bool) { commit(mapObj(id) { $0.withLocked(locked) }) }

    func setStyle(_ id: String, color: Int? = nil, width: CGFloat? = nil) {
        guard let o = sheet.obj(id), !o.locked else { return }
        commit(mapObj(id) { o in
            switch o {
            case .stroke(var a): a.color = color ?? a.color; a.width = width ?? a.width; return .stroke(a)
            case .shape(var a): a.color = color ?? a.color; a.width = width ?? a.width; return .shape(a)
            case .dim(var a): a.color = color ?? a.color; a.width = width ?? a.width; return .dim(a)
            case .door(var a): a.color = color ?? a.color; a.width = width ?? a.width; return .door(a)
            case .room(var a): a.color = color ?? a.color; a.width = width ?? a.width; return .room(a)
            case .text(var a): a.color = color ?? a.color; if let w = width { a.size = w * 6 }; return .text(a)
            default: return o
            }
        })
    }

    func setDimLabel(_ id: String, scale: CGFloat? = nil, alpha: CGFloat? = nil, intensity: CGFloat? = nil, live isLive: Bool = false) {
        guard var d = sheet.obj(id)?.asDim, !d.locked else { return }
        if let v = scale { d.labelScale = clamp(v, 0.1, 4) }
        if let v = alpha { d.labelAlpha = clamp(v, 0, 1) }
        if let v = intensity { d.labelIntensity = clamp(v, 0, 1) }
        let next = mapObj(id) { _ in .dim(d) }
        if isLive { live(next) } else { commit(next) }
    }

    func applyDimLabelToAll(_ id: String) {
        guard let src = sheet.obj(id)?.asDim else { return }
        var n = note
        for pi in n.pages.indices {
            n.pages[pi].objs = n.pages[pi].objs.map { o in
                if case .dim(var d) = o, !d.locked {
                    d.labelScale = src.labelScale; d.labelAlpha = src.labelAlpha; d.labelIntensity = src.labelIntensity
                    return .dim(d)
                }
                return o
            }
        }
        commitNote(n)
    }

    func rotatePhoto90(_ id: String) {
        guard var p = sheet.obj(id)?.asPhoto, !p.locked else { return }
        p.rot = (p.rot + 90).truncatingRemainder(dividingBy: 360)
        commit(mapObj(id) { _ in .photo(p) })
    }

    func setText(_ id: String, _ text: String) {
        guard var t = sheet.obj(id)?.asText, !t.locked else { return }
        t.text = text
        commit(mapObj(id) { _ in .text(t) })
    }

    func setUnit(_ u: LengthUnit) { var n = note; n.unit = u; commitNote(n) }
    func setNoteLocked(_ v: Bool) { var n = note; n.locked = v; commitNote(n) }

    // ---- folhas ----
    @discardableResult
    func addPage(_ pos: Int, _ tpl: Template) -> Bool {
        if note.pages.count >= Sheet.MAX_PAGES { return false }
        let at = clamp(pos, 0, note.pages.count)
        var n = note; n.pages.insert(Sheet(tpl: tpl), at: at)
        commitNote(n)
        pageIdx = at
        selectedId = nil
        onChange()
        return true
    }

    @discardableResult
    func duplicatePage(_ i: Int) -> Bool {
        if note.pages.count >= Sheet.MAX_PAGES || !note.pages.indices.contains(i) { return false }
        let src = note.pages[i]
        var idMap: [String: String] = [:]
        for o in src.objs { idMap[o.id] = newId() }
        let copy = Sheet(tpl: src.tpl, objs: src.objs.map { o in
            var n = o.withId(idMap[o.id]!)
            if let pid = n.photoId { n = n.withPhotoId(idMap[pid] ?? pid) }
            return n
        })
        var n = note; n.pages.insert(copy, at: i + 1)
        commitNote(n)
        pageIdx = i + 1
        selectedId = nil
        onChange()
        return true
    }

    @discardableResult
    func deletePage(_ i: Int) -> Bool {
        if note.pages.count <= 1 || !note.pages.indices.contains(i) { return false }
        var n = note; n.pages.remove(at: i)
        commitNote(n)
        pageIdx = clamp(pageIdx, 0, note.pages.count - 1)
        selectedId = nil
        onChange()
        return true
    }

    // ---- medidas ----
    func setDoor(_ id: String, hinge: Int? = nil, side: Int? = nil, slide: Bool? = nil,
                 labelScale: CGFloat? = nil, width: CGFloat? = nil, labelVert: Bool? = nil, live isLive: Bool = false) {
        guard var d = sheet.obj(id)?.asDoor, !d.locked else { return }
        if let v = hinge { d.hinge = v }
        if let v = side { d.side = v }
        if let v = slide { d.slide = v }
        if let v = labelScale { d.labelScale = min(4, max(0.1, v)) }
        if let v = width { d.width = min(8, max(0.3, v)) }
        if let v = labelVert { d.labelVert = v }
        let next = mapObj(id) { _ in .door(d) }
        if isLive { live(next) } else { commit(next) }
    }

    func setRoomLabelVert(_ id: String, _ vert: Bool) {
        guard var r = sheet.obj(id)?.asRoom, !r.locked else { return }
        r.labelVert = vert
        commit(mapObj(id) { _ in .room(r) })
    }

    func clearValue(_ id: String) {
        if var d = sheet.obj(id)?.asDoor {
            if d.locked { return }
            d.valueMm = nil; d.source = nil
            commit(mapObj(id) { _ in .door(d) })
            return
        }
        if let room = sheet.obj(id)?.asRoom {
            let k = selectedSeg
            if room.locked || !room.segs.indices.contains(k) { return }
            if let s = mapRoom(id, { $0.segs[k].valueMm = nil; $0.segs[k].source = nil }) { commit(s) }
            return
        }
        guard var d = sheet.obj(id)?.asDim, !d.locked else { return }
        d.valueMm = nil; d.source = nil
        commit(mapObj(id) { _ in .dim(d) })
    }

    /// Aplica uma leitura à cota (ou trecho) selecionada e avança para a próxima sem medida.
    @discardableResult
    func assignReading(_ r: Reading) -> String? {
        if let room = selected?.asRoom {
            let k = selectedSeg
            if room.locked || !room.segs.indices.contains(k) { return nil }
            if let s = mapRoom(room.id, { rr in rr.segs[k].valueMm = r.mm; rr.segs[k].source = r.source; rr.segs[k].history.append(r) }) { commit(s) }
            if let nx = nextPendingTarget(room.id, k) {
                setPage(nx.page)
                if nx.seg >= 0 { selectSeg(nx.id, nx.seg) } else { select(nx.id) }
            }
            return room.id
        }
        if var dr = selected?.asDoor {
            if dr.locked { return nil }
            dr.valueMm = r.mm; dr.source = r.source; dr.history.append(r)
            commit(mapObj(dr.id) { _ in .door(dr) })
            return dr.id
        }
        guard var d = selected?.asDim, !d.locked else { return nil }
        d.valueMm = r.mm; d.source = r.source; d.history.append(r)
        commit(mapObj(d.id) { _ in .dim(d) })
        if let nx = nextPendingTarget(d.id, -1) {
            setPage(nx.page)
            if nx.seg >= 0 { selectSeg(nx.id, nx.seg) } else { select(nx.id) }
        }
        return d.id
    }

    /// Medida digitada à mão (fica marcada como MANUAL, nunca como Bluetooth).
    @discardableResult
    func setManualValue(_ mm: Double) -> String? {
        guard mm.isFinite, mm > 0 else { return nil }
        return assignReading(Reading(mm: mm, source: .MANUAL, timeMs: nowMs()))
    }

    struct Target { var page: Int; var id: String; var seg: Int }

    func nextPendingTarget(_ id: String, _ seg: Int) -> Target? {
        struct Item { var page: Int; var id: String; var seg: Int; var pending: Bool }
        var all: [Item] = []
        for (pi, p) in note.pages.enumerated() {
            for o in p.objs {
                switch o {
                case .dim(let d): all.append(Item(page: pi, id: d.id, seg: -1, pending: d.valueMm == nil && !d.locked))
                case .room(let r): for (k, sg) in r.segs.enumerated() { all.append(Item(page: pi, id: r.id, seg: k, pending: sg.valueMm == nil && !r.locked)) }
                default: break
                }
            }
        }
        let idx = all.firstIndex { $0.id == id && $0.seg == seg }
        let ordered = idx.map { Array(all[($0 + 1)...]) + Array(all[..<$0]) } ?? all
        return ordered.first { $0.pending }.map { Target(page: $0.page, id: $0.id, seg: $0.seg) }
    }
}
