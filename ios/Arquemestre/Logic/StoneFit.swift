import CoreGraphics
import Foundation

/// Pedra: o desenho segue as medidas. Cada lado medido fica do tamanho proporcional à medida
/// (medida maior = lado maior, na mesma escala), os ângulos do desenho ficam como estão e,
/// no contorno fechado, os lados ainda sem medida esticam ou encolhem pra fechar a pedra.
/// Também confere se as medidas fecham (precisão) e calcula os lados que faltam.
/// Mesma conta do Android (StoneFit.kt).
enum StoneFit {
    struct Check {
        /// Quanto as medidas deixam de fechar (mm) deitado e em pé; nil se ainda faltam lados naquela direção.
        var gapX: Double?
        var gapY: Double?
        /// Lado sem medida → quanto ele dá pelas outras medidas (mm), só quando dá pra saber com certeza.
        var derived: [Int: Double]
        var missing: Int
    }

    private static func dirs(_ pts: [Pt], _ closed: Bool) -> [(Double, Double, Double)] {
        let n = closed ? pts.count : pts.count - 1
        guard n > 0 else { return [] }
        return (0..<n).map { (k: Int) -> (Double, Double, Double) in
            let a = pts[k], b = pts[(k + 1) % pts.count]
            let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
            let l = hypot(dx, dy)
            return l < 1e-6 ? (1, 0, 0) : (dx / l, dy / l, l)
        }
    }

    /// Ajusta os comprimentos [w] dos lados [free] pra fechar o contorno, com a menor mudança relativa.
    private static func closeLoop(_ d: [(Double, Double, Double)], _ w: inout [Double], _ free: [Int]) {
        if free.isEmpty { return }
        var ex = 0.0, ey = 0.0
        for k in d.indices { ex += w[k] * d[k].0; ey += w[k] * d[k].1 }
        var a = 0.0, b = 0.0, c = 0.0
        for k in free {
            let q = max(w[k], 1e-3) * max(w[k], 1e-3)
            a += q * d[k].0 * d[k].0; b += q * d[k].0 * d[k].1; c += q * d[k].1 * d[k].1
        }
        let det = a * c - b * b
        if abs(det) > 1e-9 * max(1.0, a * c) {
            let lx = (-ex * c + ey * b) / det
            let ly = (ex * b - ey * a) / det
            for k in free {
                let q = max(w[k], 1e-3) * max(w[k], 1e-3)
                w[k] += q * (d[k].0 * lx + d[k].1 * ly)
            }
        } else {
            // todos os lados livres na mesma direção: fecha só nessa direção
            let ux = d[free[0]].0, uy = d[free[0]].1
            var den = 0.0
            for k in free { let q = max(w[k], 1e-3) * max(w[k], 1e-3); let s = d[k].0 * ux + d[k].1 * uy; den += q * s * s }
            if den > 1e-12 {
                let lam = -(ex * ux + ey * uy) / den
                for k in free { let q = max(w[k], 1e-3) * max(w[k], 1e-3); w[k] += q * (d[k].0 * ux + d[k].1 * uy) * lam }
            }
        }
    }

    /// Novo desenho da pedra pelas medidas ([mm]: um item por lado, nil = sem medida). nil = nada pra ajustar.
    static func fit(_ pts: [Pt], closed: Bool, mm: [Double?]) -> [Pt]? {
        let d = dirs(pts, closed)
        let n = d.count
        if n < 1 || mm.count < n { return nil }
        let meas = (0..<n).filter { (mm[$0] ?? 0) > 0 }
        if meas.isEmpty { return nil }
        let cur = meas.reduce(0.0) { $0 + d[$1].2 }
        let tot = meas.reduce(0.0) { $0 + (mm[$1] ?? 0) }
        if cur <= 1e-6 || tot <= 1e-6 { return nil }
        let s = cur / tot // unidades de folha por mm (o tamanho da pedra na folha fica parecido)
        var w = (0..<n).map { k in meas.contains(k) ? (mm[k] ?? 0) * s : d[k].2 }
        if closed {
            let free = (0..<n).filter { !meas.contains($0) }
            closeLoop(d, &w, free)
            for k in free where w[k] < 1 { w[k] = 1 }
            // medidas que não fecham (ex.: 11 mm a mais em cima): reparte em todos os lados, sem mexer nos ângulos
            closeLoop(d, &w, Array(0..<n))
        }
        var out: [Pt] = []
        var x = Double(pts[0].x), y = Double(pts[0].y)
        out.append(Pt(CGFloat(x), CGFloat(y)))
        let last = closed ? n - 1 : n
        for k in 0..<last {
            x += w[k] * d[k].0; y += w[k] * d[k].1
            out.append(Pt(CGFloat(x), CGFloat(y)))
        }
        if closed {
            let ex = x + w[n - 1] * d[n - 1].0 - Double(pts[0].x)
            let ey = y + w[n - 1] * d[n - 1].1 - Double(pts[0].y)
            if abs(ex) > 1e-6 || abs(ey) > 1e-6 {
                let tl = max(w.reduce(0, +), 1e-6)
                var acc = 0.0
                for i in 1..<out.count {
                    acc += w[i - 1]
                    let f = acc / tl
                    out[i] = Pt(out[i].x - CGFloat(ex * f), out[i].y - CGFloat(ey * f))
                }
            }
        }
        // mantém a pedra no mesmo lugar da folha (centro do contorno)
        func ctr(_ p: [Pt]) -> (CGFloat, CGFloat) {
            let xs = p.map { $0.x }, ys = p.map { $0.y }
            return (((xs.min() ?? 0) + (xs.max() ?? 0)) / 2, ((ys.min() ?? 0) + (ys.max() ?? 0)) / 2)
        }
        let (ax, ay) = ctr(pts), (bx, by) = ctr(out)
        return out.map { Pt($0.x + (ax - bx), $0.y + (ay - by)) }
    }

    /// Conferência (precisão): quanto falta pra fechar em cada direção e, quando só falta um lado numa direção, quanto ele dá.
    static func check(_ pts: [Pt], closed: Bool, mm: [Double?]) -> Check {
        let d = dirs(pts, closed)
        let n = d.count
        let has = { (k: Int) -> Bool in k < mm.count && (mm[k] ?? 0) > 0 }
        let missing = (0..<max(n, 0)).filter { !has($0) }.count
        if !closed || n < 3 { return Check(gapX: nil, gapY: nil, derived: [:], missing: missing) }
        func axis(_ k: Int) -> Int { abs(d[k].1) < 0.17 ? 0 : (abs(d[k].0) < 0.17 ? 1 : -1) }
        var derived: [Int: Double] = [:]
        var gx: Double? = nil, gy: Double? = nil
        let slanted = (0..<n).contains { axis($0) == -1 }
        for ax in 0...1 where !slanted {
            let ks = (0..<n).filter { axis($0) == ax }
            if ks.isEmpty { continue }
            let sign = { (k: Int) -> Double in (ax == 0 ? d[k].0 : d[k].1) >= 0 ? 1 : -1 }
            let open = ks.filter { !has($0) }
            let sum = ks.filter { has($0) }.reduce(0.0) { $0 + sign($1) * (mm[$1] ?? 0) }
            if open.isEmpty { if ax == 0 { gx = abs(sum) } else { gy = abs(sum) } }
            else if open.count == 1 { let k = open[0]; let v = -sum * sign(k); if v > 0 { derived[k] = v } }
        }
        return Check(gapX: gx, gapY: gy, derived: derived, missing: missing)
    }

    /// Texto curto da conferência, pro painel.
    static func summary(_ c: Check, _ fmt: (Double) -> String) -> String? {
        var parts: [String] = []
        if c.gapX != nil || c.gapY != nil {
            var bad: [String] = []
            if let g = c.gapX, g >= 1 { bad.append("\(Int(g.rounded())) mm " + tr("deitado")) }
            if let g = c.gapY, g >= 1 { bad.append("\(Int(g.rounded())) mm " + tr("em pé")) }
            parts.append(bad.isEmpty ? tr("✓ As medidas fecham certinho") : tr("⚠ As medidas não fecham: sobra {0}. Confira antes de cortar.", bad.joined(separator: " e ")))
        }
        for k in c.derived.keys.sorted() { parts.append(tr("Lado {0} dá {1} pelas outras medidas", k + 1, fmt(c.derived[k] ?? 0))) }
        return parts.isEmpty ? nil : parts.joined(separator: "\n")
    }

    /// Pedra com medida nova: o desenho já sai proporcional.
    static func apply(_ r: inout RoomObj, force: Bool = false) {
        guard (r.stone || force), r.photoId == nil, let np = fit(r.pts, closed: r.closed, mm: r.segs.map { $0.valueMm }), np.count == r.pts.count else { return }
        r.pts = np
    }
}
