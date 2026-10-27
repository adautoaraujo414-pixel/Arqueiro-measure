import UIKit

extension UIColor {
    /// Cor ARGB do modelo (Int de 32 bits com sinal, como no Android).
    convenience init(argb v: Int) {
        let u = UInt32(truncatingIfNeeded: v)
        self.init(red: CGFloat((u >> 16) & 0xFF) / 255, green: CGFloat((u >> 8) & 0xFF) / 255,
                  blue: CGFloat(u & 0xFF) / 255, alpha: CGFloat((u >> 24) & 0xFF) / 255)
    }
}

@inline(__always) func argb(_ v: UInt32) -> Int { Int(Int32(bitPattern: v)) }

/// Cor de cada tipo de trecho (parede usa a cor do cômodo).
func roomSegColor(_ o: RoomObj, _ kind: SegKind) -> Int {
    switch kind {
    case .WALL: return o.color
    case .PANEL: return argb(0xFF8E44AD)
    case .SINK: return argb(0xFF1E88E5)
    case .BASIN: return argb(0xFF00A88F)
    case .DOOR: return argb(0xFFD35400)
    case .DIVIDER: return argb(0xFF6D4C41)
    case .WINDOW: return argb(0xFF0288D1)
    case .OPENING: return argb(0xFF7F8C8D)
    }
}

/// Desenha a folha num CGContext (tela, miniatura, PDF e PNG usam o mesmo código: o que se vê é o que se exporta).
/// Coordenadas: unidades de folha (794 × 1123, 1 unidade = 1/96 pol).
final class SheetRenderer {
    var images: (String) -> UIImage?
    init(images: @escaping (String) -> UIImage? = { ImageCache.shared.image($0) }) { self.images = images }

    private func withAlpha(_ c: Int, _ a: Int) -> Int { argb((UInt32(truncatingIfNeeded: c) & 0x00FFFFFF) | (UInt32(a & 0xFF) << 24)) }

    private func luminance(_ c: Int) -> CGFloat {
        let u = UInt32(truncatingIfNeeded: c)
        return 0.299 * CGFloat((u >> 16) & 0xFF) / 255 + 0.587 * CGFloat((u >> 8) & 0xFF) / 255 + 0.114 * CGFloat(u & 0xFF) / 255
    }

    private func mix(_ color: Int, _ bg: Int, _ t: CGFloat) -> Int {
        let c = UInt32(truncatingIfNeeded: color), b = UInt32(truncatingIfNeeded: bg)
        func ch(_ s: UInt32) -> UInt32 {
            let cv = CGFloat((c >> s) & 0xFF), bv = CGFloat((b >> s) & 0xFF)
            return UInt32(clamp(Int(bv + (cv - bv) * t), 0, 255))
        }
        return argb(0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0))
    }

    // ---- texto (linha de base igual ao Android) ----
    enum Align { case left, center, right }
    private func text(_ c: CGContext, _ s: String, _ x: CGFloat, _ baseline: CGFloat, size: CGFloat, color: Int, bold: Bool = false,
                      align: Align = .left, spacing: CGFloat = 0, scaleX: CGFloat = 1) {
        guard size > 0.1 else { return }
        let font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        var attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: UIColor(argb: color)]
        if spacing != 0 { attrs[.kern] = spacing * size }
        let str = s as NSString
        let w = str.size(withAttributes: attrs).width * scaleX
        var x0 = x
        if align == .center { x0 -= w / 2 } else if align == .right { x0 -= w }
        UIGraphicsPushContext(c)
        c.saveGState()
        c.translateBy(x: x0, y: baseline - font.ascender)
        if scaleX != 1 { c.scaleBy(x: scaleX, y: 1) }
        str.draw(at: .zero, withAttributes: attrs)
        c.restoreGState()
        UIGraphicsPopContext()
    }

    private func stroke(_ c: CGContext, _ color: Int, _ w: CGFloat, cap: CGLineCap = .round, dash: [CGFloat]? = nil, join: CGLineJoin = .round) {
        c.setStrokeColor(UIColor(argb: color).cgColor)
        c.setLineWidth(w)
        c.setLineCap(cap)
        c.setLineJoin(join)
        if let d = dash { c.setLineDash(phase: 0, lengths: d) } else { c.setLineDash(phase: 0, lengths: []) }
    }

    private func line(_ c: CGContext, _ a: Pt, _ b: Pt) {
        c.beginPath(); c.move(to: a.cg); c.addLine(to: b.cg); c.strokePath()
    }

    private func fill(_ c: CGContext, _ color: Int) { c.setFillColor(UIColor(argb: color).cgColor) }

    // ---- modelos de folha ----
    private func paintTemplate(_ c: CGContext, _ tpl: Template, _ w: CGFloat, _ h: CGFloat) {
        switch tpl {
        case .BLANK: break
        case .LINES:
            stroke(c, argb(0xFFD7DCE3), 0.8)
            var y: CGFloat = 70
            while y < h - 30 { line(c, Pt(36, y), Pt(w - 36, y)); y += 30 }
        case .ARAUJO: paintAraujo(c, w, h)
        }
    }

    private let gold = argb(0xFFD9A93E), goldDeep = argb(0xFFC9972F), frameGold = argb(0xFFD9A441)

    private func paintAraujo(_ c: CGContext, _ w: CGFloat, _ h: CGFloat) {
        fill(c, argb(0xFFF6F6F3)); c.fill(CGRect(x: 0, y: 0, width: w, height: h))
        fill(c, argb(0xFF121118)); c.fill(CGRect(x: 0, y: 0, width: w, height: 64))
        fill(c, goldDeep); c.fill(CGRect(x: 0, y: 64, width: w, height: 3))
        text(c, "ARQUEMESTRE", 36, 38, size: 30, color: gold, bold: true, spacing: 0.06)
        text(c, "SOLUÇÕES DE MARCENARIA E ARQUITETURA", 37, 54, size: 9.5, color: goldDeep, spacing: 0.14)
        stroke(c, argb(0xFF8A6A25), 1.2); line(c, Pt(372, 16), Pt(372, 50))
        text(c, "ESPAÇO PARA DESENHAR / CROQUI", 584, 44, size: 17, color: gold, bold: true, align: .center, scaleX: 0.92)
        let r = CGRect(x: 18, y: 84, width: w - 36, height: h - 98)
        let p = UIBezierPath(roundedRect: r, cornerRadius: 12).cgPath
        fill(c, argb(0xFFFCFCFB)); c.addPath(p); c.fillPath()
        stroke(c, frameGold, 1.5); c.addPath(p); c.strokePath()
    }

    // ---- folha inteira ----
    /// Desenha só um objeto da folha (o que está sendo escrito), por cima da imagem guardada do resto.
    func drawOne(_ c: CGContext, _ sheet: Sheet, _ unit: LengthUnit, id: String) {
        guard let o = sheet.obj(id) else { return }
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height))
        drawObj(c, o, sheet.photos(), unit)
        c.restoreGState()
    }

    func draw(_ c: CGContext, _ sheet: Sheet, _ unit: LengthUnit, selectedId: String?, viewScale: CGFloat, withPaper: Bool = true, selectedSeg: Int = -1, skipId: String? = nil) {
        if withPaper { fill(c, argb(0x33000000)); c.fill(CGRect(x: 5, y: 6, width: sheet.width, height: sheet.height)) }
        fill(c, argb(0xFFFFFFFF)); c.fill(CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height))
        paintTemplate(c, sheet.tpl, sheet.width, sheet.height)
        c.saveGState()
        c.clip(to: CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height))
        let photos = sheet.photos()
        for o in sheet.objs where o.id != skipId { drawObj(c, o, photos, unit) }
        c.restoreGState()
        if withPaper { stroke(c, argb(0xFFC9C6BD), 1); c.stroke(CGRect(x: 0, y: 0, width: sheet.width, height: sheet.height)) }
        if let o = sheet.obj(selectedId) { drawSelection(c, sheet, o, viewScale, selectedSeg) }
    }

    private func drawObj(_ c: CGContext, _ o: Obj, _ photos: [String: PhotoObj], _ unit: LengthUnit) {
        switch o {
        case .photo(let p): drawPhoto(c, p)
        case .stroke(let s): drawStroke(c, s, photos)
        case .shape(let s): drawShape(c, s, photos)
        case .text(let t): drawText(c, t, photos)
        case .dim(let d): drawDim(c, d, photos, unit)
        case .door(let d): drawDoor(c, d, photos, unit)
        case .room(let r): drawRoom(c, r, photos, unit)
        case .legacy(let l): drawLegacy(c, l)
        }
    }

    private func drawPhoto(_ c: CGContext, _ p: PhotoObj) {
        c.saveGState()
        c.translateBy(x: p.cx, y: p.cy)
        c.rotate(by: Geo.rad(p.rot))
        let r = CGRect(x: -p.w / 2, y: -p.h / 2, width: p.w, height: p.h)
        if let img = images(p.file) {
            UIGraphicsPushContext(c)
            img.draw(in: r)
            UIGraphicsPopContext()
        } else {
            fill(c, argb(0xFFDDDDDD)); c.fill(r)
            text(c, "carregando…", 0, 6, size: 18, color: argb(0xFF777777), align: .center)
        }
        c.restoreGState()
    }

    private func drawStroke(_ c: CGContext, _ o: StrokeObj, _ photos: [String: PhotoObj]) {
        let pts = Geo.annPoints(photos, .stroke(o))
        let alpha: Int = o.kind == .PEN ? 255 : (o.kind == .PENCIL ? 205 : 90)
        let col = withAlpha(o.color, alpha)
        if pts.count == 1 {
            fill(c, col)
            c.fillEllipse(in: CGRect(x: pts[0].x - o.width / 2, y: pts[0].y - o.width / 2, width: o.width, height: o.width))
            return
        }
        stroke(c, col, o.width, cap: o.kind == .HIGHLIGHTER ? .square : .round)
        c.beginPath()
        c.move(to: pts[0].cg)
        if pts.count > 2 {
            for i in 1..<(pts.count - 1) {
                let mx = (pts[i].x + pts[i + 1].x) / 2, my = (pts[i].y + pts[i + 1].y) / 2
                c.addQuadCurve(to: CGPoint(x: mx, y: my), control: pts[i].cg)
            }
        }
        c.addLine(to: pts[pts.count - 1].cg)
        c.strokePath()
    }

    private func arrowHead(_ c: CGContext, _ tip: Pt, _ from: Pt, _ size: CGFloat, _ color: Int) {
        let ang = atan2(tip.y - from.y, tip.x - from.x)
        let spread: CGFloat = 24 * .pi / 180
        let l = Pt(tip.x - size * cos(ang - spread), tip.y - size * sin(ang - spread))
        let r = Pt(tip.x - size * cos(ang + spread), tip.y - size * sin(ang + spread))
        fill(c, color)
        c.beginPath(); c.move(to: tip.cg); c.addLine(to: l.cg); c.addLine(to: r.cg); c.closePath(); c.fillPath()
    }

    private func poly(_ c: CGContext, _ pts: [Pt], close: Bool) -> CGPath {
        let p = CGMutablePath()
        p.move(to: pts[0].cg)
        for q in pts.dropFirst() { p.addLine(to: q.cg) }
        if close { p.closeSubpath() }
        return p
    }

    private func drawShape(_ c: CGContext, _ o: ShapeObj, _ photos: [String: PhotoObj]) {
        let ab = Geo.annPoints(photos, .shape(o)); let a = ab[0], b = ab[1]
        let fillCol = withAlpha(o.color, 70)
        stroke(c, o.color, o.width, cap: .round, dash: o.kind == .DASHED ? [o.width * 4 + 6, o.width * 3 + 5] : nil)
        let l = min(a.x, b.x), r = max(a.x, b.x), t = min(a.y, b.y), bt = max(a.y, b.y)
        let rect = CGRect(x: l, y: t, width: r - l, height: bt - t)
        func both(_ p: CGPath) {
            if o.fill { fill(c, fillCol); c.addPath(p); c.fillPath() }
            c.addPath(p); c.strokePath()
        }
        switch o.kind {
        case .LINE, .DASHED: line(c, a, b)
        case .ARROW: line(c, a, b); arrowHead(c, b, a, max(10, o.width * 4), o.color)
        case .DARROW: line(c, a, b); arrowHead(c, b, a, max(10, o.width * 4), o.color); arrowHead(c, a, b, max(10, o.width * 4), o.color)
        case .RECT: both(CGPath(rect: rect, transform: nil))
        case .RRECT: both(UIBezierPath(roundedRect: rect, cornerRadius: 14).cgPath)
        case .ELLIPSE: both(CGPath(ellipseIn: rect, transform: nil))
        case .CURVE: c.addPath(poly(c, Geo.curvePoints(a, b), close: false)); c.strokePath()
        case .ELBOW: c.addPath(poly(c, Geo.polyPoints(.ELBOW, a, b)!, close: false)); c.strokePath()
        case .RTRI, .DIAMOND, .TRAP: both(poly(c, Geo.polyPoints(o.kind, a, b)!, close: true))
        case .TRIANGLE: both(poly(c, [Pt((l + r) / 2, t), Pt(r, bt), Pt(l, bt)], close: true))
        }
        c.setLineDash(phase: 0, lengths: [])
    }

    private func drawText(_ c: CGContext, _ o: TextObj, _ photos: [String: PhotoObj]) {
        let at = Geo.annPoints(photos, .text(o))[0]
        for (i, ln) in o.text.components(separatedBy: "\n").enumerated() {
            text(c, ln, at.x, at.y + o.size + CGFloat(i) * o.size * 1.25, size: o.size, color: o.color)
        }
    }

    private func labelBox(_ c: CGContext, _ box: Box, _ label: String, _ k: CGFloat, col: Int, alpha: CGFloat, intensity: CGFloat, measured: Bool) {
        let rect = CGRect(x: box.l, y: box.t, width: box.r - box.l, height: box.b - box.t)
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 3 * k).cgPath
        var txtCol: Int
        if measured {
            let tint = mix(col, argb(0xFFFFFFFF), clamp(intensity, 0, 1))
            let a = clamp(alpha, 0, 1)
            fill(c, withAlpha(tint, Int(a * 255))); c.addPath(path); c.fillPath()
            txtCol = luminance(mix(tint, argb(0xFFFFFFFF), a)) > 0.6 ? argb(0xFF111111) : argb(0xFFFFFFFF)
        } else {
            fill(c, argb(0xE6FFFFFF)); c.addPath(path); c.fillPath()
            stroke(c, col, 1.2); c.addPath(path); c.strokePath()
            txtCol = col
        }
        text(c, label, (box.l + box.r) / 2, (box.t + box.b) / 2 + Geo.DIM_TEXT_SIZE * k * 0.35, size: Geo.DIM_TEXT_SIZE * k, color: txtCol, bold: true, align: .center)
    }

    /// Seta de cota: linha fina com pontas; o número só aparece depois de medido.
    private func drawDim(_ c: CGContext, _ o: DimObj, _ photos: [String: PhotoObj], _ unit: LengthUnit) {
        let ab = Geo.annPoints(photos, .dim(o)); let a = ab[0], b = ab[1]
        stroke(c, o.color, o.width, cap: .butt)
        line(c, a, b)
        let head = max(8, o.width * 3.2)
        arrowHead(c, a, b, head, o.color)
        arrowHead(c, b, a, head, o.color)
        if o.valueMm == nil { return }
        let label = Units.label(o, unit)
        let k = Geo.labelScale(o, photos)
        labelBox(c, Geo.dimLabelBox(a, b, label, k), label, k, col: o.color, alpha: o.labelAlpha, intensity: o.labelIntensity, measured: true)
    }

    /// Porta num trecho da linha: linha vermelha, batentes, sentido de abertura e "Porta".
    private func drawDoor(_ c: CGContext, _ o: DoorObj, _ photos: [String: PhotoObj], _ unit: LengthUnit) {
        let ab = Geo.annPoints(photos, .door(o)); let a = ab[0], b = ab[1]
        let w = o.width
        let len = hypotf2(b.x - a.x, b.y - a.y)
        stroke(c, o.color, w * 2.6, cap: .butt); line(c, a, b)
        if len > 1 {
            let px = -(b.y - a.y) / len * w * 2.4, py = (b.x - a.x) / len * w * 2.4
            stroke(c, o.color, w * 1.2, cap: .butt)
            line(c, Pt(a.x - px, a.y - py), Pt(a.x + px, a.y + py)); line(c, Pt(b.x - px, b.y - py), Pt(b.x + px, b.y + py))
            let h = o.hinge == 1 ? b : a, e = o.hinge == 1 ? a : b
            let ux = (e.x - h.x) / len, uy = (e.y - h.y) / len
            let sd: CGFloat = o.side < 0 ? -1 : 1
            let nx = -uy * sd, ny = ux * sd
            if o.slide {
                let off = w * 3
                stroke(c, o.color, w * 1.6, cap: .butt)
                line(c, Pt(h.x + nx * off, h.y + ny * off), Pt(h.x + ux * len * 0.62 + nx * off, h.y + uy * len * 0.62 + ny * off))
                stroke(c, o.color, w * 0.8, cap: .butt)
                let a0 = Pt(h.x + ux * len * 0.25 + nx * off * 2.4, h.y + uy * len * 0.25 + ny * off * 2.4)
                let a1 = Pt(h.x + ux * len * 0.75 + nx * off * 2.4, h.y + uy * len * 0.75 + ny * off * 2.4)
                line(c, a0, a1)
                let hx = w * 2.2
                line(c, a1, Pt(a1.x - ux * hx + nx * hx * 0.6, a1.y - uy * hx + ny * hx * 0.6))
                line(c, a1, Pt(a1.x - ux * hx - nx * hx * 0.6, a1.y - uy * hx - ny * hx * 0.6))
            } else {
                stroke(c, o.color, w * 1.1, cap: .butt); line(c, h, Pt(h.x + nx * len, h.y + ny * len))
                stroke(c, o.color, w * 0.7, cap: .butt, dash: [w * 2.5, w * 2])
                let ang = atan2(uy, ux)
                c.beginPath(); c.addArc(center: h.cg, radius: len, startAngle: ang, endAngle: ang + (.pi / 2) * sd, clockwise: sd < 0); c.strokePath()
                c.setLineDash(phase: 0, lengths: [])
            }
        }
        let label = Geo.doorLabel(o, unit)
        let sc = min(4, max(0.1, o.labelScale))
        let box = Geo.dimLabelBox(a, b, label, sc)
        let rect = CGRect(x: box.l, y: box.t, width: box.r - box.l, height: box.b - box.t)
        c.saveGState()
        if o.labelVert { c.translateBy(x: rect.midX, y: rect.midY); c.rotate(by: -.pi / 2); c.translateBy(x: -rect.midX, y: -rect.midY) }
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 3 * sc).cgPath
        fill(c, argb(0xF2FFFFFF)); c.addPath(path); c.fillPath()
        stroke(c, o.color, 1.4 * sc); c.addPath(path); c.strokePath()
        text(c, label, rect.midX, rect.midY + Geo.DIM_TEXT_SIZE * sc * 0.35, size: Geo.DIM_TEXT_SIZE * sc, color: o.color, bold: true, align: .center)
        c.restoreGState()
    }

    private func drawLegacy(_ c: CGContext, _ l: LegacyObj) {
        let r = CGRect(x: l.at.x, y: l.at.y, width: l.wUnits, height: l.hUnits)
        fill(c, argb(0x33C8A96A)); c.fill(r)
        stroke(c, argb(0xFF6F5F40), 1.2, cap: .butt, dash: [6, 4]); c.stroke(r)
        c.setLineDash(phase: 0, lengths: [])
        text(c, l.label, r.midX, r.maxY + 12, size: 9.5, color: argb(0xFF6F5F40), bold: true, align: .center)
    }

    /// Contorno de cômodo (planta).
    private func drawRoom(_ c: CGContext, _ o: RoomObj, _ photos: [String: PhotoObj], _ unit: LengthUnit) {
        let pts = Geo.annPoints(photos, .room(o))
        if pts.count < 2 { return }
        if o.closed { fill(c, withAlpha(o.color, 18)); c.addPath(poly(c, pts, close: true)); c.fillPath() }
        let w = o.width
        for k in 0..<o.segCount where k < o.segs.count {
            let a = pts[k], b = pts[(k + 1) % pts.count]
            let sg = o.segs[k]
            let col = roomSegColor(o, sg.kind)
            switch sg.kind {
            case .WALL: stroke(c, col, w * 1.6); line(c, a, b)
            case .PANEL: stroke(c, col, w * 1.6, cap: .butt, dash: [w * 6, w * 4]); line(c, a, b)
            case .SINK:
                stroke(c, withAlpha(col, 70), w * 6, cap: .butt); line(c, a, b)
                stroke(c, col, w * 1.4); line(c, a, b)
            case .DOOR:
                stroke(c, col, w * 0.9, cap: .butt, dash: [w * 3, w * 2.5]); line(c, a, b)
                let h = sg.hinge == 1 ? b : a, e = sg.hinge == 1 ? a : b
                let len = hypotf2(e.x - h.x, e.y - h.y)
                if len > 1 {
                    let ux = (e.x - h.x) / len, uy = (e.y - h.y) / len
                    let sd: CGFloat = sg.side < 0 ? -1 : 1
                    let nx = -uy * sd, ny = ux * sd
                    if sg.slide {
                        let off = w * 2.6
                        stroke(c, col, w * 1.8, cap: .butt)
                        line(c, Pt(h.x + nx * off, h.y + ny * off), Pt(h.x + ux * len * 0.62 + nx * off, h.y + uy * len * 0.62 + ny * off))
                        stroke(c, col, w * 0.8, cap: .butt)
                        let a0 = Pt(h.x + ux * len * 0.25 + nx * off * 2.4, h.y + uy * len * 0.25 + ny * off * 2.4)
                        let a1 = Pt(h.x + ux * len * 0.75 + nx * off * 2.4, h.y + uy * len * 0.75 + ny * off * 2.4)
                        line(c, a0, a1)
                        let hx = w * 2
                        line(c, a1, Pt(a1.x - ux * hx + nx * hx * 0.6, a1.y - uy * hx + ny * hx * 0.6))
                        line(c, a1, Pt(a1.x - ux * hx - nx * hx * 0.6, a1.y - uy * hx - ny * hx * 0.6))
                    } else {
                        stroke(c, col, w * 1.2, cap: .butt)
                        line(c, h, Pt(h.x + nx * len, h.y + ny * len))
                        stroke(c, col, w * 0.7, cap: .butt)
                        let ang = atan2(uy, ux)
                        c.beginPath()
                        c.addArc(center: h.cg, radius: len, startAngle: ang, endAngle: ang + (.pi / 2) * sd, clockwise: sd < 0)
                        c.strokePath()
                    }
                }
            case .WINDOW:
                let len = hypotf2(b.x - a.x, b.y - a.y)
                if len > 1 {
                    let nx = -(b.y - a.y) / len * w * 1.4, ny = (b.x - a.x) / len * w * 1.4
                    stroke(c, col, w * 0.7, cap: .butt)
                    line(c, Pt(a.x + nx, a.y + ny), Pt(b.x + nx, b.y + ny))
                    line(c, Pt(a.x - nx, a.y - ny), Pt(b.x - nx, b.y - ny))
                    line(c, a, b)
                    line(c, Pt(a.x + nx, a.y + ny), Pt(a.x - nx, a.y - ny))
                    line(c, Pt(b.x + nx, b.y + ny), Pt(b.x - nx, b.y - ny))
                }
            case .OPENING: stroke(c, col, w * 0.8, cap: .butt, dash: [w * 2, w * 3]); line(c, a, b)
            case .DIVIDER: stroke(c, col, w * 1.1); line(c, a, b)
            case .BASIN: stroke(c, col, w * 3, cap: .round, dash: [0.1, w * 4.5]); line(c, a, b)
            }
            c.setLineDash(phase: 0, lengths: [])
            let measured = sg.valueMm != nil
            let label = measured ? Units.labelSeg(sg, unit) : sg.kind.label
            let lb = Geo.dimLabelBox(a, b, label, o.labelScale)
            c.saveGState()
            if o.labelVert { let mx = (lb.l + lb.r) / 2, my = (lb.t + lb.b) / 2; c.translateBy(x: mx, y: my); c.rotate(by: -.pi / 2); c.translateBy(x: -mx, y: -my) }
            labelBox(c, lb, label, o.labelScale, col: col, alpha: o.labelAlpha, intensity: o.labelIntensity, measured: measured)
            c.restoreGState()
        }
        fill(c, o.color)
        for p in pts { c.fillEllipse(in: CGRect(x: p.x - w * 1.1, y: p.y - w * 1.1, width: w * 2.2, height: w * 2.2)) }
    }

    // ---- seleção e alças (só na tela) ----
    private func drawSelection(_ c: CGContext, _ sheet: Sheet, _ o: Obj, _ viewScale: CGFloat, _ selectedSeg: Int) {
        let photos = sheet.photos()
        let color = o.locked ? argb(0xFF888888) : argb(0xFF2F80ED)
        let lw = 2 / viewScale, r = 9 / viewScale
        func handle(_ p: Pt, _ ring: Int? = nil, _ radius: CGFloat? = nil) {
            let rad = radius ?? r
            let rc = CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2)
            fill(c, argb(0xFFFFFFFF)); c.fillEllipse(in: rc)
            stroke(c, ring ?? color, lw); c.strokeEllipse(in: rc)
        }
        switch o {
        case .photo(let p):
            let cs = Geo.corners(p)
            stroke(c, color, lw); c.addPath(poly(c, cs, close: true)); c.strokePath()
            if !p.locked {
                let top = Geo.photoLocalToSheet(p, 0.5, 0), rh = Geo.rotateHandle(p, viewScale)
                stroke(c, color, lw); line(c, top, rh)
                cs.forEach { handle($0) }
                handle(rh)
            }
        case .dim(let d):
            if !d.locked { Geo.annPoints(photos, o).forEach { handle($0, d.color, 7 / viewScale) } }
        case .shape(let s):
            if !s.locked { Geo.annPoints(photos, o).forEach { handle($0, s.color, 7 / viewScale) } }
        case .door(let d):
            if !d.locked { Geo.annPoints(photos, o).forEach { handle($0, d.color, 7 / viewScale) } }
        case .room(let ro):
            let pts = Geo.annPoints(photos, o)
            if selectedSeg >= 0 && selectedSeg < ro.segCount {
                stroke(c, argb(0x802F80ED), ro.width + 10 / viewScale)
                line(c, pts[selectedSeg], pts[(selectedSeg + 1) % pts.count])
            }
            if !ro.locked { pts.forEach { handle($0, argb(0xFF2F80ED), 7 / viewScale) } }
        case .legacy(let l):
            let pad = 8 / viewScale
            stroke(c, color, lw, dash: [8 / viewScale, 6 / viewScale])
            c.stroke(CGRect(x: l.at.x - pad, y: l.at.y - pad, width: l.wUnits + 2 * pad, height: l.hUnits + 2 * pad))
            c.setLineDash(phase: 0, lengths: [])
        case .stroke, .text:
            let pts = Geo.annPoints(photos, o)
            let pad = 6 / viewScale
            let box: Box
            if case .text(let t) = o { box = Geo.textBox(t, pts[0]) } else {
                let w = (o.asStroke?.width ?? 0) / 2
                box = Box(l: pts.map(\.x).min()! - w, t: pts.map(\.y).min()! - w, r: pts.map(\.x).max()! + w, b: pts.map(\.y).max()! + w)
            }
            stroke(c, color, lw, dash: [8 / viewScale, 6 / viewScale])
            c.stroke(CGRect(x: box.l - pad, y: box.t - pad, width: box.r - box.l + 2 * pad, height: box.b - box.t + 2 * pad))
            c.setLineDash(phase: 0, lengths: [])
        }
    }
}
