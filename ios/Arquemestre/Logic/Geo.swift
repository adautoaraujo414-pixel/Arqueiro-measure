import Foundation
import CoreGraphics

struct Box: Equatable {
    var l: CGFloat, t: CGFloat, r: CGFloat, b: CGFloat
    func contains(_ p: Pt, _ pad: CGFloat = 0) -> Bool { p.x >= l - pad && p.x <= r + pad && p.y >= t - pad && p.y <= b + pad }
}

@inline(__always) func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(max(v, lo), hi) }
@inline(__always) func hypotf2(_ x: CGFloat, _ y: CGFloat) -> CGFloat { (x * x + y * y).squareRoot() }

/// Geometria pura (igual ao Android): foto livre, anotações coladas na foto, testes de toque.
enum Geo {
    static let DIM_TEXT_SIZE: CGFloat = 14
    static let MIN_PHOTO_SIDE: CGFloat = 40

    static func rad(_ deg: CGFloat) -> CGFloat { deg * .pi / 180 }

    // ---- fotos ----
    static func photoLocalToSheet(_ p: PhotoObj, _ u: CGFloat, _ v: CGFloat) -> Pt {
        let lx = (u - 0.5) * p.w, ly = (v - 0.5) * p.h
        let c = cos(rad(p.rot)), s = sin(rad(p.rot))
        return Pt(p.cx + lx * c - ly * s, p.cy + lx * s + ly * c)
    }

    static func photoSheetToLocal(_ p: PhotoObj, _ s: Pt) -> Pt {
        let dx = s.x - p.cx, dy = s.y - p.cy
        let c = cos(rad(p.rot)), sn = sin(rad(p.rot))
        let lx = dx * c + dy * sn, ly = -dx * sn + dy * c
        return Pt(lx / p.w + 0.5, ly / p.h + 0.5)
    }

    static func photoContains(_ p: PhotoObj, _ s: Pt) -> Bool {
        let l = photoSheetToLocal(p, s)
        return l.x >= 0 && l.x <= 1 && l.y >= 0 && l.y <= 1
    }

    static func corners(_ p: PhotoObj) -> [Pt] {
        [photoLocalToSheet(p, 0, 0), photoLocalToSheet(p, 1, 0), photoLocalToSheet(p, 1, 1), photoLocalToSheet(p, 0, 1)]
    }

    static func rotateHandle(_ p: PhotoObj, _ viewScale: CGFloat, _ distPx: CGFloat = 44) -> Pt {
        let top = photoLocalToSheet(p, 0.5, 0)
        let d = distPx / viewScale
        return Pt(top.x + sin(rad(p.rot)) * d, top.y - cos(rad(p.rot)) * d)
    }

    static func photoAt(_ sheet: Sheet, _ s: Pt) -> PhotoObj? {
        for o in sheet.objs.reversed() { if case .photo(let p) = o, photoContains(p, s) { return p } }
        return nil
    }

    // ---- vínculo foto <-> anotação ----
    static func toSheet(_ photos: [String: PhotoObj], _ photoId: String?, _ p: Pt) -> Pt {
        guard let pid = photoId, let ph = photos[pid] else { return p }
        return photoLocalToSheet(ph, p.x, p.y)
    }

    static func fromSheet(_ photos: [String: PhotoObj], _ photoId: String?, _ s: Pt) -> Pt {
        guard let pid = photoId, let ph = photos[pid] else { return s }
        return photoSheetToLocal(ph, s)
    }

    /// Pontos da anotação em coordenadas da folha.
    static func annPoints(_ photos: [String: PhotoObj], _ o: Obj) -> [Pt] {
        switch o {
        case .stroke(let a): return a.pts.map { toSheet(photos, a.photoId, $0) }
        case .shape(let a): return [toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b)]
        case .dim(let a): return [toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b)]
        case .door(let a): return [toSheet(photos, a.photoId, a.a), toSheet(photos, a.photoId, a.b)]
        case .text(let a): return [toSheet(photos, a.photoId, a.at)]
        case .room(let a): return a.pts.map { toSheet(photos, a.photoId, $0) }
        case .legacy(let l): return [l.at, Pt(l.at.x + l.wUnits, l.at.y + l.hUnits)]
        case .photo(let p): return corners(p)
        }
    }

    static func translate(_ sheet: Sheet, _ o: Obj, _ dx: CGFloat, _ dy: CGFloat) -> Obj {
        if case .photo(var p) = o { p.cx += dx; p.cy += dy; return .photo(p) }
        let photos = sheet.photos()
        let pid = o.photoId
        func mv(_ p: Pt) -> Pt {
            let s = toSheet(photos, pid, p)
            return fromSheet(photos, pid, Pt(s.x + dx, s.y + dy))
        }
        switch o {
        case .stroke(var a): a.pts = a.pts.map(mv); return .stroke(a)
        case .shape(var a): a.a = mv(a.a); a.b = mv(a.b); return .shape(a)
        case .dim(var a): a.a = mv(a.a); a.b = mv(a.b); return .dim(a)
        case .door(var a): a.a = mv(a.a); a.b = mv(a.b); return .door(a)
        case .text(var a): a.at = mv(a.at); return .text(a)
        case .room(var a): a.pts = a.pts.map(mv); return .room(a)
        default: return o // objetos do Android não se movem aqui
        }
    }

    static func withEndpoint(_ sheet: Sheet, _ o: Obj, _ endB: Bool, _ s: Pt) -> Obj {
        let local = fromSheet(sheet.photos(), o.photoId, s)
        switch o {
        case .shape(var a): if endB { a.b = local } else { a.a = local }; return .shape(a)
        case .dim(var a): if endB { a.b = local } else { a.a = local }; return .dim(a)
        case .door(var a): if endB { a.b = local } else { a.a = local }; return .door(a)
        default: return o
        }
    }

    // ---- distâncias e toque ----
    static func inPolygon(_ poly: [Pt], _ p: Pt) -> Bool {
        var inside = false
        var j = poly.count - 1
        for i in 0..<poly.count {
            let a = poly[i], b = poly[j]
            if (a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x { inside.toggle() }
            j = i
        }
        return inside
    }

    static func bounds(_ sheet: Sheet, _ o: Obj) -> Box {
        if case .photo(let p) = o {
            let cs = corners(p)
            return Box(l: cs.map(\.x).min()!, t: cs.map(\.y).min()!, r: cs.map(\.x).max()!, b: cs.map(\.y).max()!)
        }
        let pts = annPoints(sheet.photos(), o)
        if case .text(let t) = o { return textBox(t, pts[0]) }
        return Box(l: pts.map(\.x).min() ?? 0, t: pts.map(\.y).min() ?? 0, r: pts.map(\.x).max() ?? 0, b: pts.map(\.y).max() ?? 0)
    }

    /// Objetos (não travados) contornados pelo laço: 60% dos pontos dentro.
    static func lassoPick(_ sheet: Sheet, _ poly: [Pt]) -> Set<String> {
        if poly.count < 3 { return [] }
        let photos = sheet.photos()
        var out = Set<String>()
        for o in sheet.objs where !o.locked {
            let pts: [Pt]
            if case .photo(let p) = o { pts = [Pt(p.cx, p.cy)] + corners(p) } else { pts = annPoints(photos, o) }
            if !pts.isEmpty && CGFloat(pts.filter { inPolygon(poly, $0) }.count) >= CGFloat(pts.count) * 0.6 { out.insert(o.id) }
        }
        return out
    }

    static func polyPoints(_ kind: ShapeKind, _ a: Pt, _ b: Pt) -> [Pt]? {
        let l = min(a.x, b.x), r = max(a.x, b.x), t = min(a.y, b.y), bt = max(a.y, b.y), w = r - l
        switch kind {
        case .RTRI: return [Pt(l, t), Pt(r, bt), Pt(l, bt)]
        case .DIAMOND: return [Pt((l + r) / 2, t), Pt(r, (t + bt) / 2), Pt((l + r) / 2, bt), Pt(l, (t + bt) / 2)]
        case .TRAP: return [Pt(l + w * 0.2, t), Pt(r - w * 0.2, t), Pt(r, bt), Pt(l, bt)]
        case .ELBOW: return [a, Pt(b.x, a.y), b]
        default: return nil
        }
    }

    static func curvePoints(_ a: Pt, _ b: Pt, _ n: Int = 24) -> [Pt] {
        let mx = (a.x + b.x) / 2, my = (a.y + b.y) / 2
        let dx = b.x - a.x, dy = b.y - a.y
        let c = Pt(mx - dy * 0.25, my + dx * 0.25)
        return (0...n).map { i in
            let t = CGFloat(i) / CGFloat(n), u = 1 - t
            return Pt(u * u * a.x + 2 * u * t * c.x + t * t * b.x, u * u * a.y + 2 * u * t * c.y + t * t * b.y)
        }
    }

    static func distToSegment(_ p: Pt, _ a: Pt, _ b: Pt) -> CGFloat {
        let dx = b.x - a.x, dy = b.y - a.y
        let len2 = dx * dx + dy * dy
        if len2 < 1e-6 { return hypotf2(p.x - a.x, p.y - a.y) }
        let t = clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / len2, 0, 1)
        return hypotf2(p.x - (a.x + t * dx), p.y - (a.y + t * dy))
    }

    static func textBox(_ t: TextObj, _ at: Pt) -> Box {
        let lines = t.text.components(separatedBy: "\n")
        let w = CGFloat(max(1, lines.map(\.count).max() ?? 1)) * t.size * 0.55
        let h = CGFloat(lines.count) * t.size * 1.25
        return Box(l: at.x, t: at.y, r: at.x + w, b: at.y + h)
    }

    static func dimLabelCenter(_ a: Pt, _ b: Pt) -> Pt { Pt((a.x + b.x) / 2, (a.y + b.y) / 2) }

    static func labelScale(_ d: DimObj, _ photos: [String: PhotoObj]) -> CGFloat {
        let p = annPoints(photos, .dim(d))
        let cur = d.photoId.flatMap { photos[$0]?.w } ?? hypotf2(p[1].x - p[0].x, p[1].y - p[0].y)
        let auto: CGFloat = (d.refSize > 1 && cur > 1) ? clamp(cur / d.refSize, 0.1, 4) : 1
        return clamp(d.labelScale * auto, 0.05, 8)
    }

    static func dimLabelBox(_ a: Pt, _ b: Pt, _ label: String, _ scale: CGFloat = 1, vert: Bool = false) -> Box {
        let c = dimLabelCenter(a, b)
        let w0 = (CGFloat(label.count) * DIM_TEXT_SIZE * 0.58 + 12) * scale
        let h0 = (DIM_TEXT_SIZE + 8) * scale
        let w = vert ? h0 : w0
        let h = vert ? w0 : h0
        return Box(l: c.x - w / 2, t: c.y - h / 2, r: c.x + w / 2, b: c.y + h / 2)
    }

    private static func ring(_ c: [Pt]) -> [(Pt, Pt)] {
        let r = c + [c[0]]
        return (0..<(r.count - 1)).map { (r[$0], r[$0 + 1]) }
    }
    private static func pairs(_ c: [Pt]) -> [(Pt, Pt)] {
        c.count < 2 ? [] : (0..<(c.count - 1)).map { (c[$0], c[$0 + 1]) }
    }

    static func hitObj(_ sheet: Sheet, _ o: Obj, _ s: Pt, _ tol: CGFloat, _ unit: LengthUnit) -> Bool {
        let photos = sheet.photos()
        switch o {
        case .photo(let p): return photoContains(p, s)
        case .stroke(let st):
            let pts = annPoints(photos, o)
            let r = tol + st.width / 2
            if pts.count == 1 { return hypotf2(s.x - pts[0].x, s.y - pts[0].y) <= r }
            return pairs(pts).contains { distToSegment(s, $0.0, $0.1) <= r }
        case .shape(let sh):
            let ab = annPoints(photos, o); let a = ab[0], b = ab[1]
            let r = tol + sh.width / 2
            switch sh.kind {
            case .LINE, .DASHED, .ARROW, .DARROW: return distToSegment(s, a, b) <= r
            case .CURVE: return pairs(curvePoints(a, b)).contains { distToSegment(s, $0.0, $0.1) <= r }
            case .ELBOW: return pairs(polyPoints(sh.kind, a, b)!).contains { distToSegment(s, $0.0, $0.1) <= r }
            case .RTRI, .DIAMOND, .TRAP: return ring(polyPoints(sh.kind, a, b)!).contains { distToSegment(s, $0.0, $0.1) <= r }
            case .TRIANGLE:
                let l = min(a.x, b.x), rr = max(a.x, b.x), t = min(a.y, b.y), bb = max(a.y, b.y)
                return ring([Pt((l + rr) / 2, t), Pt(rr, bb), Pt(l, bb)]).contains { distToSegment(s, $0.0, $0.1) <= r }
            case .RECT, .RRECT:
                let l = min(a.x, b.x), rr = max(a.x, b.x), t = min(a.y, b.y), bb = max(a.y, b.y)
                return ring([Pt(l, t), Pt(rr, t), Pt(rr, bb), Pt(l, bb)]).contains { distToSegment(s, $0.0, $0.1) <= r }
            case .ELLIPSE:
                let cx = (a.x + b.x) / 2, cy = (a.y + b.y) / 2, rx = abs(b.x - a.x) / 2, ry = abs(b.y - a.y) / 2
                let poly = (0...48).map { i -> Pt in let t = CGFloat(i) / 48 * 2 * .pi; return Pt(cx + rx * cos(t), cy + ry * sin(t)) }
                return pairs(poly).contains { distToSegment(s, $0.0, $0.1) <= r }
            }
        case .text(let t): return textBox(t, annPoints(photos, o)[0]).contains(s, tol)
        case .door(let d):
            let ab = annPoints(photos, o)
            return distToSegment(s, ab[0], ab[1]) <= tol + d.width * 1.5 || dimLabelBox(ab[0], ab[1], doorLabel(d, unit), d.labelScale, vert: d.labelVert).contains(s, tol / 2)
        case .room(let r): return hitSeg(sheet, r, s, tol, unit) >= 0
        case .legacy(let l): return Box(l: l.at.x, t: l.at.y, r: l.at.x + l.wUnits, b: l.at.y + l.hUnits).contains(s, tol / 2)
        case .dim(let d):
            let ab = annPoints(photos, o)
            return distToSegment(s, ab[0], ab[1]) <= tol + d.width / 2 ||
                (d.valueMm != nil && dimLabelBox(ab[0], ab[1], Units.label(d, unit), labelScale(d, photos)).contains(s, tol / 2))
        }
    }

    static func doorLabel(_ d: DoorObj, _ unit: LengthUnit) -> String { tr("Porta") + (d.valueMm.map { " " + Units.format($0, unit) } ?? "") }

    /// Trecho de linha mais perto de p (paredes, linhas e traços): a porta fica em cima da linha.
    static func nearestLine(_ sheet: Sheet, _ p: Pt, _ tol: CGFloat, skip: String? = nil) -> (Pt, Pt)? {
        let photos = sheet.photos()
        var best: (Pt, Pt)?
        var bd = tol
        func cand(_ a: Pt, _ b: Pt) {
            if hypotf2(b.x - a.x, b.y - a.y) < 4 { return }
            let d = distToSegment(p, a, b)
            if d <= bd { bd = d; best = (a, b) }
        }
        for o in sheet.objs where o.id != skip {
            switch o {
            case .room(let r):
                let q = annPoints(photos, o)
                if r.segCount > 0 { for k in 0..<r.segCount { cand(q[k], q[(k + 1) % q.count]) } }
            case .shape(let sh):
                let q = annPoints(photos, o)
                switch sh.kind {
                case .LINE, .DASHED, .ARROW, .DARROW: cand(q[0], q[1])
                case .RECT, .RRECT:
                    let l = min(q[0].x, q[1].x), r = max(q[0].x, q[1].x), t = min(q[0].y, q[1].y), bt = max(q[0].y, q[1].y)
                    cand(Pt(l, t), Pt(r, t)); cand(Pt(r, t), Pt(r, bt)); cand(Pt(r, bt), Pt(l, bt)); cand(Pt(l, bt), Pt(l, t))
                default: break
                }
            case .stroke:
                let q = annPoints(photos, o)
                if q.count > 1 { for i in 1..<q.count { cand(q[i - 1], q[i]) } }
            default: break
            }
        }
        return best
    }

    static func projectOnSegment(_ p: Pt, _ a: Pt, _ b: Pt) -> Pt {
        let dx = b.x - a.x, dy = b.y - a.y, l2 = dx * dx + dy * dy
        if l2 < 1e-6 { return a }
        let t = clamp(((p.x - a.x) * dx + (p.y - a.y) * dy) / l2, 0, 1)
        return Pt(a.x + dx * t, a.y + dy * t)
    }

    static func segEnds(_ photos: [String: PhotoObj], _ o: RoomObj, _ k: Int) -> (Pt, Pt) {
        let pts = annPoints(photos, .room(o))
        return (pts[k], pts[(k + 1) % pts.count])
    }

    static func segLabelBox(_ photos: [String: PhotoObj], _ o: RoomObj, _ k: Int, _ unit: LengthUnit) -> Box {
        let (a, b) = segEnds(photos, o, k)
        return dimLabelBox(a, b, Units.labelSeg(o.segs[k], unit), o.labelScale, vert: o.labelVert)
    }

    static func hitSeg(_ sheet: Sheet, _ o: RoomObj, _ s: Pt, _ tol: CGFloat, _ unit: LengthUnit) -> Int {
        let photos = sheet.photos()
        var best = -1
        var bestD = CGFloat.greatestFiniteMagnitude
        if o.segCount <= 0 { return -1 }
        for k in 0..<o.segCount {
            let (a, b) = segEnds(photos, o, k)
            var d = distToSegment(s, a, b) - o.width / 2
            if k < o.segs.count && o.segs[k].valueMm != nil && segLabelBox(photos, o, k, unit).contains(s, tol / 2) { d = -1 }
            if d <= tol && d < bestD { bestD = d; best = k }
        }
        return best
    }

    static func hit(_ sheet: Sheet, _ s: Pt, _ tol: CGFloat, _ unit: LengthUnit) -> String? {
        sheet.objs.reversed().first { hitObj(sheet, $0, s, tol, unit) }?.id
    }

    static func snapAxis(_ anchor: Pt, _ p: Pt, _ tolDeg: CGFloat = 3) -> Pt {
        let dx = p.x - anchor.x, dy = p.y - anchor.y
        if hypotf2(dx, dy) < 1 { return p }
        let ang = atan2(abs(dy), abs(dx)) * 180 / .pi
        if ang < tolDeg { return Pt(p.x, anchor.y) }
        if ang > 90 - tolDeg { return Pt(anchor.x, p.y) }
        return p
    }

    /// Redimensiona a foto puxando o canto idx (0=TL,1=TR,2=BR,3=BL), proporção mantida e canto oposto fixo.
    static func resizeFromCorner(_ o: PhotoObj, _ idx: Int, _ p: Pt, _ maxSide: CGFloat) -> PhotoObj {
        let cu: [CGFloat] = [0, 1, 1, 0], cv: [CGFloat] = [0, 0, 1, 1]
        let ax = cu[(idx + 2) % 4], ay = cv[(idx + 2) % 4]
        let anchor = photoLocalToSheet(o, ax, ay)
        let dxL = (cu[idx] - ax) * o.w, dyL = (cv[idx] - ay) * o.h
        let vx = p.x - anchor.x, vy = p.y - anchor.y
        let c = cos(rad(o.rot)), sn = sin(rad(o.rot))
        let vlx = vx * c + vy * sn, vly = -vx * sn + vy * c
        var s = (vlx * dxL + vly * dyL) / (dxL * dxL + dyL * dyL)
        let minS = MIN_PHOTO_SIDE / min(o.w, o.h), maxS = maxSide / max(o.w, o.h)
        s = clamp(s, minS, maxS)
        let nw = o.w * s, nh = o.h * s
        let ox = (ax - 0.5) * nw, oy = (ay - 0.5) * nh
        var n = o
        n.cx = anchor.x - (ox * c - oy * sn); n.cy = anchor.y - (ox * sn + oy * c); n.w = nw; n.h = nh
        return n
    }
}
