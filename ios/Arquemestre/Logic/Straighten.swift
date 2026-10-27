import Foundation
import CoreGraphics

/// Endireita um traço à mão em paredes retas (igual ao Android): simplifica, alinha na
/// horizontal/vertical, fecha o contorno e une pontas soltas (uma reta = uma medida).
enum Straighten {
    struct Result: Equatable { var pts: [Pt]; var closed: Bool }
    private enum Axis { case H, V }

    private static func dist(_ a: Pt, _ b: Pt) -> CGFloat { hypotf2(b.x - a.x, b.y - a.y) }

    private static func dp(_ pts: [Pt], _ lo: Int, _ hi: Int, _ eps: CGFloat, _ keep: inout Set<Int>) {
        if hi <= lo + 1 { return }
        var maxD: CGFloat = -1, idx = -1
        for i in (lo + 1)..<hi {
            let d = Geo.distToSegment(pts[i], pts[lo], pts[hi])
            if d > maxD { maxD = d; idx = i }
        }
        if maxD > eps && idx > 0 {
            keep.insert(idx)
            dp(pts, lo, idx, eps, &keep)
            dp(pts, idx, hi, eps, &keep)
        }
    }

    private static func axisOf(_ a: Pt, _ b: Pt, _ snapDeg: CGFloat) -> Axis? {
        let dx = b.x - a.x, dy = b.y - a.y
        if hypotf2(dx, dy) < 1 { return nil }
        let ang = atan2(abs(dy), abs(dx)) * 180 / .pi
        if ang < snapDeg { return .H }
        if ang > 90 - snapDeg { return .V }
        return nil
    }

    private static func turnDeg(_ p0: Pt, _ p1: Pt, _ p2: Pt) -> Double {
        let d1 = atan2(Double(p1.y - p0.y), Double(p1.x - p0.x))
        let d2 = atan2(Double(p2.y - p1.y), Double(p2.x - p1.x))
        var turn = abs(d2 - d1) * 180 / .pi
        if turn > 180 { turn = 360 - turn }
        return turn
    }

    static func run(_ raw: [Pt], closeTol: CGFloat = 40, eps: CGFloat = 12, snapDeg: CGFloat = 12, minSeg: CGFloat = 24) -> Result? {
        if raw.count < 2 { return nil }
        var pathLen: CGFloat = 0
        for i in 1..<raw.count { pathLen += dist(raw[i - 1], raw[i]) }
        if pathLen < minSeg { return nil }
        let closed = raw.count >= 4 && dist(raw.first!, raw.last!) <= closeTol && pathLen > closeTol * 4

        // 1) simplifica
        var pts: [Pt]
        if closed {
            let ring = raw + [raw[0]]
            var far = 0, fd: CGFloat = -1
            for i in 1..<(ring.count - 1) { let d = dist(ring[i], ring[0]); if d > fd { fd = d; far = i } }
            var keep: Set<Int> = [0, far, ring.count - 1]
            dp(ring, 0, far, eps, &keep)
            dp(ring, far, ring.count - 1, eps, &keep)
            pts = keep.sorted().map { ring[$0] }
            pts.removeLast()
        } else {
            var keep: Set<Int> = [0, raw.count - 1]
            dp(raw, 0, raw.count - 1, eps, &keep)
            pts = keep.sorted().map { raw[$0] }
        }

        // 2) remove trechos minúsculos
        var changed = true
        while changed && pts.count > 2 {
            changed = false
            let n = pts.count
            let last = closed ? n : n - 1
            for i in 0..<last {
                let j = (i + 1) % n
                if dist(pts[i], pts[j]) < minSeg && pts.count > (closed ? 3 : 2) {
                    let drop = (!closed && j == n - 1) ? i : j
                    if !closed && drop == 0 { continue }
                    pts.remove(at: drop)
                    changed = true
                    break
                }
            }
        }
        if closed && pts.count < 3 { return nil }
        if !closed && pts.count < 2 { return nil }

        // 3) alinha na horizontal/vertical
        let n = pts.count
        var axes = [Axis?](repeating: nil, count: n)
        for i in 0..<(n - 1) {
            let a = pts[i], b = pts[i + 1]
            let ax = axisOf(a, b, snapDeg)
            axes[i] = ax
            if ax == .H { pts[i + 1] = Pt(b.x, a.y) } else if ax == .V { pts[i + 1] = Pt(a.x, b.y) }
        }
        if closed && n >= 2 {
            let a = pts[n - 1], b = pts[0]
            if let cAxis = axisOf(a, b, snapDeg) {
                let prev = n >= 2 ? axes[n - 2] : nil
                if prev == nil {
                    pts[n - 1] = cAxis == .H ? Pt(a.x, b.y) : Pt(b.x, a.y)
                } else if prev != cAxis {
                    let p = pts[n - 2]
                    pts[n - 1] = prev == .H ? Pt(b.x, p.y) : Pt(p.x, b.y)
                }
            }
        }

        // 4) une trechos na mesma linha
        var merged = true
        while merged {
            merged = false
            let m = pts.count
            if m <= (closed ? 3 : 2) { break }
            let range = closed ? Array(0..<m) : Array(1..<(m - 1))
            for i in range {
                let p0 = pts[(i - 1 + m) % m], p1 = pts[i], p2 = pts[(i + 1) % m]
                let a1 = axisOf(p0, p1, snapDeg), a2 = axisOf(p1, p2, snapDeg)
                let sameAxis = a1 != nil && a1 == a2
                let straight = turnDeg(p0, p1, p2) < Double(snapDeg) || Geo.distToSegment(p1, p0, p2) < eps
                if sameAxis || straight { pts.remove(at: i); merged = true; break }
            }
        }
        for i in 0..<pts.count {
            let j = (i + 1) % pts.count
            if j == 0 { break }
            switch axisOf(pts[i], pts[j], snapDeg) {
            case .H: pts[j] = Pt(pts[j].x, pts[i].y)
            case .V: pts[j] = Pt(pts[i].x, pts[j].y)
            case nil: break
            }
        }
        return Result(pts: pts, closed: closed)
    }

    /// Planta da casa: alinha os cantos do traço novo com os cantos que já existem.
    static func alignTo(_ pts0: [Pt], _ closed: Bool, _ refs: [Pt], _ tol: CGFloat, _ snapDeg: CGFloat = 12) -> [Pt] {
        if refs.isEmpty || pts0.count < 2 { return pts0 }
        var p = pts0
        let n = p.count
        let segs = closed ? n : n - 1
        let ax = (0..<segs).map { axisOf(p[$0], p[($0 + 1) % n], snapDeg) }
        func neighbors(_ i: Int, _ want: Axis) -> [Int] {
            var r: [Int] = []
            let prev = i > 0 ? i - 1 : (closed ? n - 1 : -1)
            if prev >= 0 && prev < segs && ax[prev] == want { r.append(prev) }
            if i < segs && ax[i] == want { r.append((i + 1) % n) }
            return r
        }
        func setX(_ i: Int, _ x: CGFloat, _ seen: inout Set<Int>) {
            if !seen.insert(i).inserted { return }
            p[i] = Pt(x, p[i].y)
            for k in neighbors(i, .V) { setX(k, x, &seen) }
        }
        func setY(_ i: Int, _ y: CGFloat, _ seen: inout Set<Int>) {
            if !seen.insert(i).inserted { return }
            p[i] = Pt(p[i].x, y)
            for k in neighbors(i, .H) { setY(k, y, &seen) }
        }
        var doneX = Set<Int>(), doneY = Set<Int>()
        for i in 0..<n {
            if !doneX.contains(i), let rx = refs.min(by: { abs($0.x - p[i].x) < abs($1.x - p[i].x) }), abs(rx.x - p[i].x) <= tol { setX(i, rx.x, &doneX) }
            if !doneY.contains(i), let ry = refs.min(by: { abs($0.y - p[i].y) < abs($1.y - p[i].y) }), abs(ry.y - p[i].y) <= tol { setY(i, ry.y, &doneY) }
        }
        return p
    }

    /// Índices dos vértices que ficam (tira os do meio de uma reta). Cantos de verdade não saem.
    static func strayFreeIndices(_ pts: [Pt], _ closed: Bool, tolDeg: Double = 18, fixed: Set<Int> = []) -> [Int] {
        var keep = Array(pts.indices)
        var changed = true
        while changed {
            changed = false
            let m = keep.count
            if m <= (closed ? 3 : 2) { break }
            let range = closed ? Array(0..<m) : Array(1..<(m - 1))
            for i in range {
                if fixed.contains(keep[i]) { continue }
                let p0 = pts[keep[(i - 1 + m) % m]], p1 = pts[keep[i]], p2 = pts[keep[(i + 1) % m]]
                if turnDeg(p0, p1, p2) < tolDeg { keep.remove(at: i); changed = true; break }
            }
        }
        return keep
    }
}

/// Borracha de pixels: tira o pedaço do traço sob o círculo e divide o resto.
enum Eraser {
    static func densify(_ pts: [Pt], _ step: CGFloat) -> [Pt] {
        if pts.count < 2 { return pts }
        var out: [Pt] = [pts[0]]
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let d = hypotf2(b.x - a.x, b.y - a.y)
            let n = max(1, Int(ceil(d / step)))
            for k in 1...n { let t = CGFloat(k) / CGFloat(n); out.append(Pt(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)) }
        }
        return out
    }

    /// nil = não tocou; [] = sumiu inteiro.
    static func erasePieces(_ pts: [Pt], _ c: Pt, _ r: CGFloat) -> [[Pt]]? {
        let touched: Bool
        if pts.count == 1 { touched = hypotf2(pts[0].x - c.x, pts[0].y - c.y) <= r }
        else { touched = (1..<pts.count).contains { Geo.distToSegment(c, pts[$0 - 1], pts[$0]) <= r } }
        if !touched { return nil }
        let dense = densify(pts, max(r / 3, 1.5))
        var pieces: [[Pt]] = []
        var cur: [Pt] = []
        for p in dense {
            if hypotf2(p.x - c.x, p.y - c.y) <= r {
                if cur.count >= 2 { pieces.append(cur) }
                cur = []
            } else { cur.append(p) }
        }
        if cur.count >= 2 { pieces.append(cur) }
        return pieces
    }

    /// Contorno de uma forma como linha de pontos (fechada quando a forma é fechada). Folha.
    static func shapeOutline(_ kind: ShapeKind, _ a: Pt, _ b: Pt) -> [Pt] {
        let l = min(a.x, b.x), r = max(a.x, b.x), t = min(a.y, b.y), bt = max(a.y, b.y)
        func closed(_ c: [Pt]) -> [Pt] { c + [c[0]] }
        switch kind {
        case .LINE, .DASHED, .ARROW, .DARROW: return [a, b]
        case .CURVE: return Geo.curvePoints(a, b)
        case .ELBOW: return Geo.polyPoints(kind, a, b) ?? [a, b]
        case .RTRI, .DIAMOND, .TRAP: return closed(Geo.polyPoints(kind, a, b) ?? [a, b])
        case .TRIANGLE: return closed([Pt((l + r) / 2, t), Pt(r, bt), Pt(l, bt)])
        case .RECT, .RRECT: return closed([Pt(l, t), Pt(r, t), Pt(r, bt), Pt(l, bt)])
        case .ELLIPSE:
            let cx = (a.x + b.x) / 2, cy = (a.y + b.y) / 2, rx = abs(b.x - a.x) / 2, ry = abs(b.y - a.y) / 2
            return (0...64).map { i in let q = CGFloat(i) / 64 * 2 * .pi; return Pt(cx + rx * cos(q), cy + ry * sin(q)) }
        }
    }

    /// Cômodo depois da borracha: tira os trechos tocados; o resto vira contornos abertos (índices de vértices e trechos). nil = não tocou.
    static func roomPieces(_ o: RoomObj, _ pts: [Pt], _ c: Pt, _ r: CGFloat) -> [([Int], [Int])]? {
        let n = o.segCount
        if n <= 0 || pts.count < 2 { return nil }
        let hit = (0..<n).map { k in Geo.distToSegment(c, pts[k], pts[(k + 1) % pts.count]) <= r }
        guard let f = hit.firstIndex(of: true) else { return nil }
        let order: [Int] = o.closed ? (1...n).map { (f + $0) % n } : Array(0..<n)
        var out: [([Int], [Int])] = []
        var segs: [Int] = []
        func flush() {
            if !segs.isEmpty { out.append((segs + [(segs[segs.count - 1] + 1) % pts.count], segs)) }
            segs = []
        }
        for k in order { if hit[k] { flush() } else { segs.append(k) } }
        flush()
        return out
    }
}
