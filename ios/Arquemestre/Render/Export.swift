import UIKit

/// Exportação da nota (PDF, PNG, CSV) e orçamento em PDF. Usa o mesmo desenho da tela.
enum Export {
    /// 1 unidade de folha = 1/96 pol; 1 ponto de PDF = 1/72 pol.
    static let PT_PER_UNIT: CGFloat = 0.75

    static func tempURL(_ name: String) -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("export", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
        return dir.appendingPathComponent(safe)
    }

    static func pdf(_ note: Note, to url: URL) throws {
        let r = SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 3000) })
        let page = CGRect(x: 0, y: 0, width: Sheet.W * PT_PER_UNIT, height: Sheet.H * PT_PER_UNIT)
        let pdf = UIGraphicsPDFRenderer(bounds: page)
        try pdf.writePDF(to: url) { ctx in
            for s in note.pages {
                ctx.beginPage()
                let c = ctx.cgContext
                c.saveGState()
                c.scaleBy(x: PT_PER_UNIT, y: PT_PER_UNIT)
                r.draw(c, s, note.unit, selectedId: nil, viewScale: 1, withPaper: false)
                c.restoreGState()
            }
        }
    }

    static func png(_ note: Note, page: Int, scale: CGFloat = 2, to url: URL) throws {
        let s = note.pages[clamp(page, 0, note.pages.count - 1)]
        let r = SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 3000) })
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = true
        let img = UIGraphicsImageRenderer(size: CGSize(width: Sheet.W * scale, height: Sheet.H * scale), format: fmt).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: Sheet.W * scale, height: Sheet.H * scale))
            ctx.cgContext.scaleBy(x: scale, y: scale)
            r.draw(ctx.cgContext, s, note.unit, selectedId: nil, viewScale: 1, withPaper: false)
        }
        guard let d = img.pngData() else { throw NSError(domain: "png", code: 1) }
        try d.write(to: url)
    }

    /// Miniatura da primeira folha (biblioteca).
    static func thumb(_ note: Note, width: CGFloat = 240) -> UIImage {
        let k = width / Sheet.W
        let r = SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 600) })
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: Sheet.H * k), format: fmt).image { ctx in
            UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: width, height: Sheet.H * k))
            ctx.cgContext.scaleBy(x: k, y: k)
            r.draw(ctx.cgContext, note.pages[0], note.unit, selectedId: nil, viewScale: 1, withPaper: false)
        }
    }

    private static func q(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }

    static func csv(_ note: Note) -> String {
        let fmt = DateFormatter(); fmt.locale = Locale(identifier: "en_US_POSIX"); fmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
        func src(_ s: MeasureSource?) -> String { s == .BLUETOOTH ? "bluetooth" : (s == .MANUAL ? "manual" : "") }
        func when(_ r: Reading?) -> String { r.map { fmt.string(from: Date(timeIntervalSince1970: Double($0.timeMs) / 1000)) } ?? "" }
        var out = "nota;folha;cota;valor_mm;valor_exibido;origem;ultima_leitura\n"
        for (pi, s) in note.pages.enumerated() {
            var i = 0
            for o in s.objs { if case .dim(let d) = o {
                i += 1
                out += [q(note.name), "\(pi + 1)", "\(i)", d.valueMm.map { String(format: "%.1f", $0) } ?? "",
                        q(Units.label(d, note.unit)), src(d.source), when(d.history.last)].joined(separator: ";") + "\n"
            } }
            for o in s.objs { if case .room(let r) = o {
                for (k, sg) in r.segs.enumerated() {
                    out += [q(note.name), "\(pi + 1)", "comodo-\(k + 1)", sg.valueMm.map { String(format: "%.1f", $0) } ?? "",
                            q(sg.kind.label + " " + Units.labelSeg(sg, note.unit)), src(sg.source), when(sg.history.last)].joined(separator: ";") + "\n"
                }
            } }
        }
        return out
    }
}

// ---------------- Orçamento em PDF ----------------
// O mesmo desenho (medidas, cores e textos) do Android e do Windows: app/src/main/java/br/com/arque/measure/QuotePdf.kt.
// Mexeu lá, mexa aqui: os três têm que sair iguais.

private let QW: CGFloat = 595, QH: CGFloat = 842, QM: CGFloat = 20
/// Onde o conteúdo começa (depois do cabeçalho) e onde tem que parar (antes do rodapé).
private let QTOP: CGFloat = 106, QBOTTOM: CGFloat = 786
private let QYEL = UIColor(argb: argb(0xFFFFC20E)), QYEL2 = UIColor(argb: argb(0xFFF2A900)), QDARK = UIColor(argb: argb(0xFF1C1D21))
private let QINK = UIColor(argb: argb(0xFF17181B)), QGRAY = UIColor(argb: argb(0xFF5F6368)), QCARD = UIColor(argb: argb(0xFFF1F2F4))
private let QSOFT = UIColor(argb: argb(0xFFF8F8FA)), QEDGE = UIColor(argb: argb(0xFFD8DADF)), QTXT = UIColor(argb: argb(0xFF2B2D31))

private enum QAlign { case left, center, right }

private func qpFont(_ size: CGFloat, _ bold: Bool) -> UIFont { bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size) }

private func qpW(_ s: String, _ size: CGFloat, _ bold: Bool = false) -> CGFloat {
    (s as NSString).size(withAttributes: [NSAttributedString.Key.font: qpFont(size, bold)]).width
}

private func qpText(_ s: String, _ x: CGFloat, _ baseline: CGFloat, _ size: CGFloat, bold: Bool = false, color: UIColor = QINK, align: QAlign = .left) {
    if s.isEmpty { return }
    let f = qpFont(size, bold)
    let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: color]
    let w = (s as NSString).size(withAttributes: attrs).width
    let x0: CGFloat = align == .left ? x : (align == .center ? x - w / 2 : x - w)
    (s as NSString).draw(at: CGPoint(x: x0, y: baseline - f.ascender), withAttributes: attrs)
}

private func qpWrap(_ text: String, _ size: CGFloat, _ bold: Bool, _ width: CGFloat) -> [String] {
    func w(_ s: String) -> CGFloat { qpW(s, size, bold) }
    var out: [String] = []
    for para in text.components(separatedBy: "\n") {
        var line = ""
        for word in para.components(separatedBy: " ") {
            let t = line.isEmpty ? word : line + " " + word
            if w(t) <= width { line = t } else {
                if !line.isEmpty { out.append(line) }
                var rest = word
                while w(rest) > width && rest.count > 1 {
                    var n = rest.count
                    while n > 1 && w(String(rest.prefix(n))) > width { n -= 1 }
                    out.append(String(rest.prefix(n))); rest = String(rest.dropFirst(n))
                }
                line = rest
            }
        }
        out.append(line)
    }
    return out
}

/// Encolhe a letra até caber na largura; se nem no tamanho mínimo couber, corta com reticências. Devolve o texto e o tamanho.
private func qpFit(_ s: String, _ size: CGFloat, _ bold: Bool, _ width: CGFloat, _ minSize: CGFloat) -> (String, CGFloat) {
    var z = size
    while qpW(s, z, bold) > width && z > minSize { z -= 0.5 }
    if qpW(s, z, bold) <= width { return (s, z) }
    var t = s
    while t.count > 1 && qpW(t + "…", z, bold) > width { t.removeLast() }
    return (t + "…", z)
}

private func qpBlank(_ s: String) -> Bool { s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

private func qpRect(_ l: CGFloat, _ t: CGFloat, _ r: CGFloat, _ b: CGFloat, _ color: UIColor) {
    color.setFill()
    UIRectFill(CGRect(x: l, y: t, width: r - l, height: b - t))
}

private func qpFill(_ p: UIBezierPath, _ color: UIColor) { color.setFill(); p.fill() }

private func qpStroke(_ p: UIBezierPath, _ color: UIColor, _ w: CGFloat) {
    color.setStroke()
    p.lineWidth = w; p.lineCapStyle = .round; p.lineJoinStyle = .round
    p.stroke()
}

private func qpPoly(_ pts: [(CGFloat, CGFloat)]) -> UIBezierPath {
    let p = UIBezierPath()
    for (i, pt) in pts.enumerated() {
        if i == 0 { p.move(to: CGPoint(x: pt.0, y: pt.1)) } else { p.addLine(to: CGPoint(x: pt.0, y: pt.1)) }
    }
    p.close()
    return p
}

/// Retângulo com o raio de cada canto: cima-esquerda, cima-direita, baixo-direita, baixo-esquerda.
private func qpRR(_ l: CGFloat, _ t: CGFloat, _ r: CGFloat, _ b: CGFloat, _ c1: CGFloat, _ c2: CGFloat, _ c3: CGFloat, _ c4: CGFloat) -> UIBezierPath {
    let p = UIBezierPath()
    p.move(to: CGPoint(x: l + c1, y: t))
    p.addLine(to: CGPoint(x: r - c2, y: t)); if c2 > 0 { p.addQuadCurve(to: CGPoint(x: r, y: t + c2), controlPoint: CGPoint(x: r, y: t)) }
    p.addLine(to: CGPoint(x: r, y: b - c3)); if c3 > 0 { p.addQuadCurve(to: CGPoint(x: r - c3, y: b), controlPoint: CGPoint(x: r, y: b)) }
    p.addLine(to: CGPoint(x: l + c4, y: b)); if c4 > 0 { p.addQuadCurve(to: CGPoint(x: l, y: b - c4), controlPoint: CGPoint(x: l, y: b)) }
    p.addLine(to: CGPoint(x: l, y: t + c1)); if c1 > 0 { p.addQuadCurve(to: CGPoint(x: l + c1, y: t), controlPoint: CGPoint(x: l, y: t)) }
    p.close()
    return p
}

/// Ícones de traço em caixa 24×24: M = começa, L = reta, C = curva, O = círculo (centro e raio), Z = fecha.
private let QICONS: [String: String] = [
    "user": "O 12 8 4 M 4 21 C 4 16.6 7.6 14.5 12 14.5 C 16.4 14.5 20 16.6 20 21",
    "pin": "M 12 22 C 9.5 19.4 5 14.6 5 10 C 5 6.1 8.1 3 12 3 C 15.9 3 19 6.1 19 10 C 19 14.6 14.5 19.4 12 22 Z O 12 10 2.6",
    "cal": "M 5.2 5 L 18.8 5 C 20.02 5 21 5.98 21 7.2 L 21 18.8 C 21 20.02 20.02 21 18.8 21 L 5.2 21 C 3.98 21 3 20.02 3 18.8 L 3 7.2 C 3 5.98 3.98 5 5.2 5 Z M 3 10 L 21 10 M 8 3 L 8 7 M 16 3 L 16 7 M 7.6 14 L 8.6 14 M 11.5 14 L 12.5 14 M 15.4 14 L 16.4 14 M 7.6 17.5 L 8.6 17.5 M 11.5 17.5 L 12.5 17.5",
    "doc": "M 7 3 L 14 3 L 19 8 L 19 19 C 19 20.1 18.1 21 17 21 L 7 21 C 5.9 21 5 20.1 5 19 L 5 5 C 5 3.9 5.9 3 7 3 Z M 14 3 L 14 8 L 19 8 M 8.5 12.5 L 15.5 12.5 M 8.5 16.5 L 15.5 16.5",
    "box": "M 12 2.5 L 20.5 7 L 20.5 17 L 12 21.5 L 3.5 17 L 3.5 7 Z M 3.5 7 L 12 11.5 L 20.5 7 M 12 11.5 L 12 21.5",
    "roller": "M 4.7 3.5 L 15.8 3.5 C 16.46 3.5 17 4.04 17 4.7 L 17 7.8 C 17 8.46 16.46 9 15.8 9 L 4.7 9 C 4.04 9 3.5 8.46 3.5 7.8 L 3.5 4.7 C 3.5 4.04 4.04 3.5 4.7 3.5 Z M 17 6.2 L 20.5 6.2 L 20.5 12.4 L 11.6 12.4 L 11.6 15 M 10.8 15 L 12.4 15 C 12.95 15 13.4 15.45 13.4 16 L 13.4 20.5 C 13.4 21.05 12.95 21.5 12.4 21.5 L 10.8 21.5 C 10.25 21.5 9.8 21.05 9.8 20.5 L 9.8 16 C 9.8 15.45 10.25 15 10.8 15 Z",
    "camera": "M 4 7.5 L 7.4 7.5 L 9 5 L 15 5 L 16.6 7.5 L 20 7.5 C 21.1 7.5 22 8.4 22 9.5 L 22 18 C 22 19.1 21.1 20 20 20 L 4 20 C 2.9 20 2 19.1 2 18 L 2 9.5 C 2 8.4 2.9 7.5 4 7.5 Z O 12 13.5 3.6",
    "list": "M 6 3.5 L 18 3.5 C 19.1 3.5 20 4.4 20 5.5 L 20 18.5 C 20 19.6 19.1 20.5 18 20.5 L 6 20.5 C 4.9 20.5 4 19.6 4 18.5 L 4 5.5 C 4 4.4 4.9 3.5 6 3.5 Z M 8 8.5 L 16 8.5 M 8 12 L 16 12 M 8 15.5 L 13 15.5",
    "note": "M 6 4.5 L 18 4.5 C 19.1 4.5 20 5.4 20 6.5 L 20 19 C 20 20.1 19.1 21 18 21 L 6 21 C 4.9 21 4 20.1 4 19 L 4 6.5 C 4 5.4 4.9 4.5 6 4.5 Z M 8 2.8 L 8 6.2 M 12 2.8 L 12 6.2 M 16 2.8 L 16 6.2 M 8 11 L 16 11 M 8 14.2 L 16 14.2 M 8 17.4 L 13 17.4",
    "check": "O 12 12 9 M 8 12.3 L 11 15.2 L 16.2 9.2",
    "plus": "O 12 12 9 M 12 8 L 12 16 M 8 12 L 16 12",
    "info": "O 12 12 9 M 12 11 L 12 16.5 M 12 7.6 L 12 7.9",
    "quote": "M 11 21.5 L 6 21.5 C 4.9 21.5 4 20.6 4 19.5 L 4 4.5 C 4 3.4 4.9 2.5 6 2.5 L 13 2.5 L 17.5 7 L 17.5 10.2 M 13 2.5 L 13 7 L 17.5 7 M 7 10 L 11 10 M 7 13.5 L 9.6 13.5 M 7 17 L 9.6 17 M 13.6 12.4 L 20.2 12.4 C 20.97 12.4 21.6 13.03 21.6 13.8 L 21.6 20.8 C 21.6 21.57 20.97 22.2 20.2 22.2 L 13.6 22.2 C 12.83 22.2 12.2 21.57 12.2 20.8 L 12.2 13.8 C 12.2 13.03 12.83 12.4 13.6 12.4 Z M 14.6 15 L 19.2 15 M 14.7 17.7 L 14.9 17.7 M 16.8 17.7 L 17 17.7 M 18.9 17.7 L 19.1 17.7 M 14.7 19.9 L 14.9 19.9 M 16.8 19.9 L 17 19.9 M 18.9 19.9 L 19.1 19.9",
    "tools": "M 20.98 7.93 C 21.14 9.78 20.34 11.59 18.85 12.71 C 17.37 13.83 15.41 14.11 13.67 13.44 L 7.82 19.29 C 6.96 20.15 5.57 20.15 4.71 19.29 C 3.85 18.43 3.85 17.04 4.71 16.18 L 10.56 10.33 C 9.89 8.59 10.17 6.63 11.29 5.15 C 12.41 3.66 14.22 2.86 16.07 3.02 L 12.86 6.23 L 17.77 11.14 Z",
]

private func qpIcon(_ name: String, _ x: CGFloat, _ y: CGFloat, _ size: CGFloat, _ color: UIColor) {
    guard let d = QICONS[name] else { return }
    let k = size / 24
    let t = d.components(separatedBy: " ")
    func n(_ i: Int) -> CGFloat { CGFloat(Double(t[i]) ?? 0) * k }
    let p = UIBezierPath()
    var i = 0
    while i < t.count {
        switch t[i] {
        case "M": p.move(to: CGPoint(x: x + n(i + 1), y: y + n(i + 2))); i += 3
        case "L": p.addLine(to: CGPoint(x: x + n(i + 1), y: y + n(i + 2))); i += 3
        case "C":
            p.addCurve(to: CGPoint(x: x + n(i + 5), y: y + n(i + 6)), controlPoint1: CGPoint(x: x + n(i + 1), y: y + n(i + 2)), controlPoint2: CGPoint(x: x + n(i + 3), y: y + n(i + 4)))
            i += 7
        case "O":
            let r = n(i + 3)
            p.append(UIBezierPath(ovalIn: CGRect(x: x + n(i + 1) - r, y: y + n(i + 2) - r, width: r * 2, height: r * 2)))
            i += 4
        case "Z": p.close(); i += 1
        default: i += 1
        }
    }
    qpStroke(p, color, 1.7 * k)
}

private struct QBlock {
    let h: CGFloat
    let draw: (CGFloat, Bool) -> Void
}

private struct QRow {
    let main: [String]
    let sub: [String]
    let qty: String
    let unit: String
    let unitV: String
    let tot: String
    let h: CGFloat
}

private final class QuotePdfLayout {
    let pdf: UIGraphicsPDFRendererContext?
    let total: Int
    let company: Company
    let q: Quote
    let logo: UIImage?
    let photos: [UIImage]
    let df = I18n.shared.dateFormatter(.date)
    /// Passada que só conta as páginas (pro "página N/M" do rodapé): desenha num papel de rascunho.
    var dry: Bool { pdf == nil }
    var no = 0
    var y: CGFloat = QTOP

    init(pdf: UIGraphicsPDFRendererContext?, total: Int, company: Company, q: Quote, logo: UIImage?, photos: [UIImage]) {
        self.pdf = pdf; self.total = total; self.company = company; self.q = q; self.logo = logo; self.photos = photos
    }

    private func open() {
        no += 1
        if let p = pdf { p.beginPage() }
        qpRect(0, 0, QW, QH, .white)
    }

    /// Página nova do orçamento, já com o cabeçalho e o rodapé.
    func next() { open(); header(); footer(); y = QTOP }

    /// Página em branco (folha do desenho).
    func blank() { open() }

    private func header() {
        qpFill(UIBezierPath(roundedRect: CGRect(x: QM + 4, y: 30, width: 3.5, height: 60), cornerRadius: 1.75), QYEL)
        var tx = QM + 18
        let bl: CGFloat = 306
        if let lg = logo, lg.size.width > 0, lg.size.height > 0 {
            let k = min(52 / lg.size.height, 64 / lg.size.width)
            let lw = lg.size.width * k, lh = lg.size.height * k
            if !dry { lg.draw(in: CGRect(x: tx, y: 60 - lh / 2, width: lw, height: lh)) }
            tx += lw + 12
        }
        let maxW = bl - 14 - tx
        let name = (qpBlank(company.name) ? tr("Minha empresa") : company.name).uppercased()
        var ns: CGFloat = 21
        while qpW(name, ns, true) > maxW && ns > 13 { ns -= 0.5 }
        let nl: [String] = qpW(name, ns, true) > maxW ? Array(qpWrap(name, ns, true, maxW).prefix(2)) : [name]
        // CNPJ e telefone: numa linha só se couber; senão, uma linha pra cada (nada é cortado)
        var pieces: [String] = []
        if !qpBlank(company.cnpj) { pieces.append(tr("CNPJ {0}", company.cnpj)) }
        if !qpBlank(company.phone) { pieces.append(company.phone) }
        let joined = pieces.joined(separator: "   |   ")
        var subSize: CGFloat = 10
        while qpW(joined, subSize) > maxW && subSize > 8.5 { subSize -= 0.5 }
        var subLines: [String] = []
        if !pieces.isEmpty {
            if qpW(joined, subSize) <= maxW { subLines = [joined] } else { subSize = 10; subLines = pieces }
        }
        // endereço: quebra em até 3 linhas
        let addr = [company.address, company.city].filter { !qpBlank($0) }.joined(separator: " – ")
        var addrSize: CGFloat = 10
        var al: [String] = addr.isEmpty ? [] : qpWrap(addr, addrSize, false, maxW - 14)
        if al.count > 2 { addrSize = 8.5; al = Array(qpWrap(addr, addrSize, false, maxW - 14).prefix(3)) }
        let small = subLines.count + al.count
        let step: CGFloat = small <= 2 ? 17 : 13.5
        var by = 60 - (CGFloat(nl.count) * ns * 1.08 + CGFloat(small) * step) / 2
        for l in nl { qpText(l, tx, by + ns * 0.82, ns, bold: true); by += ns * 1.08 }
        for l in subLines {
            let (s, z) = qpFit(l, subSize, false, maxW, 7)
            qpText(s, tx, by + step - 4.5, z, color: QTXT); by += step
        }
        for (k, l) in al.enumerated() {
            if k == 0 { qpIcon("pin", tx - 1, by + step - 13.5, 11, QINK) }
            let (s, z) = qpFit(l, addrSize, false, maxW - 14, 7)
            qpText(s, tx + 14, by + step - 4.5, z, color: QTXT); by += step
        }

        // selo ORÇAMENTO
        let bt: CGFloat = 26, bb: CGFloat = 92, br = QW - QM
        qpFill(qpPoly([(bl - 4, bb), (bl + 26, bt), (bl + 44, bt), (bl + 14, bb)]), QYEL)
        let body = UIBezierPath()
        body.move(to: CGPoint(x: bl + 42, y: bt))
        body.addLine(to: CGPoint(x: br - 9, y: bt)); body.addQuadCurve(to: CGPoint(x: br, y: bt + 9), controlPoint: CGPoint(x: br, y: bt))
        body.addLine(to: CGPoint(x: br, y: bb - 9)); body.addQuadCurve(to: CGPoint(x: br - 9, y: bb), controlPoint: CGPoint(x: br, y: bb))
        body.addLine(to: CGPoint(x: bl + 12, y: bb))
        body.close()
        qpFill(body, QDARK)
        qpIcon("quote", bl + 52, bt + 14, 38, QYEL)
        let (ts, tz) = qpFit(tr("ORÇAMENTO"), 24, true, br - 14 - (bl + 100), 12)
        qpText(ts, bl + 100, bt + 33, tz, bold: true, color: .white)
        qpIcon("cal", bl + 100, bt + 43, 12, QYEL)
        qpText(df.string(from: Date(timeIntervalSince1970: Double(q.dateMs) / 1000)), bl + 117, bt + 53.5, 11.5, color: .white)
    }

    private func footer() {
        let ft = QH - 36
        qpRect(0, ft, QW, QH, QDARK)
        qpRect(0, ft + 8, 336, ft + 10, QYEL)
        qpFill(qpPoly([(350, QH), (376, ft - 8), (QW, ft - 8), (QW, QH)]), QYEL)
        qpFill(qpPoly([(QW - 44, QH), (QW, QH - 44), (QW, QH)]), QYEL2)
        if total > 1 {
            let s = "\(no)/\(total)"
            qpText(s, 298, QH - 9.5, 10.5, color: .white, align: .center)
            let hw = qpW(s, 10.5) / 2 + 9
            qpRect(298 - hw - 1.5, QH - 19, 298 - hw, QH - 8, QYEL)
            qpRect(298 + hw, QH - 19, 298 + hw + 1.5, QH - 8, QYEL)
        }
    }

    /// Nome do cliente / cidade no cartão: encolhe a letra pra caber; nome muito comprido desce pra uma segunda linha em vez de ser cortado.
    private func name2(_ text: String, _ x: CGFloat, _ w: CGFloat, _ t: CGFloat) {
        var z: CGFloat = 13
        while qpW(text, z, true) > w && z > 9 { z -= 0.5 }
        if qpW(text, z, true) <= w { qpText(text, x, t + 34, z, bold: true); return }
        let ls = qpWrap(text, z, true, w)
        qpText(ls[0], x, t + 29.5, z, bold: true)
        let (s2, z2) = qpFit(ls.dropFirst().joined(separator: " "), z, true, w, 7)
        qpText(s2, x, t + 39.5, z2, bold: true)
    }

    private func client() {
        let t = y, b = y + 46
        let mid: CGFloat = 300
        qpFill(UIBezierPath(roundedRect: CGRect(x: QM, y: t, width: QW - 2 * QM, height: 46), cornerRadius: 8), QCARD)
        qpIcon("user", QM + 20, t + 12, 22, QINK)
        qpText(tr("CLIENTE"), QM + 56, t + 18, 8.5, color: QGRAY)
        name2(qpBlank(q.clientName) ? "—" : q.clientName, QM + 56, mid - 12 - (QM + 56), t)
        qpRect(mid, t + 10, mid + 0.8, b - 10, UIColor(argb: argb(0xFFC6C9CF)))
        qpIcon("pin", mid + 24, t + 12, 22, QINK)
        qpText(tr("CIDADE"), mid + 60, t + 18, 8.5, color: QGRAY)
        name2(qpBlank(q.city) ? "—" : q.city, mid + 60, QW - QM - 12 - (mid + 60), t)
        y = b + 14
    }

    private func table() {
        let descX = QM + 14, descW: CGFloat = 262
        let qtyX: CGFloat = 322, unX: CGFloat = 362, unitR: CGFloat = 470, subL: CGFloat = 480, subR = QW - QM - 10
        var rows: [QRow] = q.items.filter { !qpBlank($0.desc) || $0.unitValue != 0 }.map { it -> QRow in
            let d = (qpBlank(it.desc) ? "—" : it.desc).trimmingCharacters(in: .whitespacesAndNewlines)
            // "Cozinha · Módulos de cima (aéreos) · 1 módulo": a contagem do fim desce pra uma segunda linha
            var mainText = d, tail = ""
            if let r = d.range(of: " · ", options: .backwards), r.lowerBound > d.startIndex {
                let t = String(d[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                if let f = t.first, f >= "0", f <= "9" { mainText = String(d[..<r.lowerBound]); tail = t }
            }
            let main = qpWrap(mainText, 10.5, true, descW)
            let sub: [String] = tail.isEmpty ? [] : qpWrap(tail, 9.5, false, descW)
            return QRow(main: main, sub: sub, qty: QuoteMath.numStr(it.qty), unit: it.unit, unitV: QuoteMath.brl(it.unitValue),
                        tot: QuoteMath.brl(QuoteMath.lineTotal(it)), h: max(34, 21 + CGFloat(main.count) * 13 + CGFloat(sub.count) * 12))
        }
        if rows.isEmpty { rows = [QRow(main: ["—"], sub: [], qty: "", unit: "", unitV: "", tot: "", h: 34)] }

        func head() {
            qpFill(qpRR(QM, y, QW - QM, y + 24, 7, 7, 0, 0), QDARK)
            qpText(tr("DESCRIÇÃO"), descX, y + 16, 9.5, bold: true, color: .white)
            qpText(tr("QTD"), qtyX, y + 16, 9.5, bold: true, color: .white, align: .center)
            qpText(tr("UN"), unX, y + 16, 9.5, bold: true, color: .white, align: .center)
            qpText(tr("VALOR UNIT."), unitR, y + 16, 9.5, bold: true, color: .white, align: .right)
            qpText(tr("SUBTOTAL"), subR, y + 16, 9.5, bold: true, color: .white, align: .right)
            y += 24
        }

        var i = 0
        while true {
            if y + 24 + rows[i].h > QBOTTOM && y > QTOP { next() }
            head()
            let top = y
            var bot = top
            let start = i
            while i < rows.count && (bot + rows[i].h <= QBOTTOM || i == start) { bot += rows[i].h; i += 1 }
            let body = qpRR(QM, top, QW - QM, bot, 0, 0, 7, 7)
            let cg = UIGraphicsGetCurrentContext()
            cg?.saveGState()
            body.addClip()
            qpRect(QM, top, QW - QM, bot, .white)
            qpRect(subL, top, QW - QM, bot, UIColor(argb: argb(0xFFF4F5F7)))
            cg?.restoreGState()
            var ry = top
            for k in start..<i {
                let r = rows[k]
                if k > start { qpRect(QM, ry - 0.35, QW - QM, ry + 0.35, QEDGE) }
                var ty = ry + 21
                for l in r.main { qpText(l, descX, ty, 10.5, bold: true); ty += 13 }
                ty -= 1
                for l in r.sub { qpText(l, descX, ty, 9.5, color: QGRAY); ty += 12 }
                let by = ry + r.h / 2 + 3.8
                qpText(r.qty, qtyX, by, 10.5, align: .center)
                // unidade comprida ("metros lineares"): encolhe e, se precisar, vai em duas linhas
                var nz: CGFloat = 10.5
                while qpW(r.unit, nz) > 40 && nz > 8 { nz -= 0.5 }
                if qpW(r.unit, nz) <= 40 { qpText(r.unit, unX, by, nz, align: .center) } else {
                    let ul = qpWrap(r.unit, nz, false, 44)
                    qpText(ul[0], unX, by - 4.5, nz, align: .center)
                    let (u2, z2) = qpFit(ul.dropFirst().joined(separator: " "), nz, false, 44, 6)
                    qpText(u2, unX, by + 4.5, z2, align: .center)
                }
                let (us, uz) = qpFit(r.unitV, 10.5, false, unitR - 384, 7)
                qpText(us, unitR, by, uz, align: .right)
                let (ss, sz) = qpFit(r.tot, 10.5, true, subR - subL - 4, 7)
                qpText(ss, subR, by, sz, bold: true, align: .right)
                ry += r.h
            }
            qpStroke(body, QEDGE, 0.8)
            y = bot
            if i >= rows.count { break }
            next()
        }
        y += 12
    }

    /// Faixa do total: rótulo no amarelo, valor em amarelo no escuro.
    private func bar(_ label: String, _ value: String, _ l: CGFloat, _ r: CGFloat, _ t: CGFloat) {
        let b = t + 34
        // o rótulo cede espaço pro valor: o valor nunca é cortado
        let (lab, lz) = qpFit(label, 11, true, r - l - 16 - 14 - 13 - 8 - 12 - min(qpW(value, 16, true), 120), 8)
        let x0 = l + 16 + qpW(lab, lz, true) + 14
        let shape = qpRR(l, t, r, b, 8, 8, 8, 8)
        qpFill(shape, QDARK)
        let cg = UIGraphicsGetCurrentContext()
        cg?.saveGState()
        shape.addClip()
        qpFill(qpPoly([(l, t), (x0 + 13, t), (x0, b), (l, b)]), QYEL)
        cg?.restoreGState()
        qpText(lab, l + 16, t + 21.5, lz, bold: true)
        let (vs, vz) = qpFit(value, 16, true, r - 12 - (x0 + 13 + 8), 8)
        qpText(vs, r - 12, t + 22.5, vz, bold: true, color: QYEL, align: .right)
    }

    private func totals() {
        let l: CGFloat = 262, r = QW - QM
        let hasDisc = q.discountPct > 0
        if y + (hasDisc ? 52 : 0) + 34 > QBOTTOM { next() }
        if hasDisc {
            qpFill(qpRR(l, y, r, y + 64, 8, 8, 0, 0), QCARD)
            qpText(tr("Valor original"), l + 150, y + 17, 10.5, color: QTXT, align: .right)
            qpText(QuoteMath.brl(QuoteMath.original(q)), r - 12, y + 17, 10.5, align: .right)
            qpRect(l + 70, y + 26, r - 10, y + 26.7, QEDGE)
            qpText(tr("Desconto ({0}%)", QuoteMath.numStr(q.discountPct)), l + 150, y + 43, 10.5, color: QTXT, align: .right)
            qpText("− " + QuoteMath.brl(QuoteMath.discountValue(q)), r - 12, y + 43, 10.5, align: .right)
            y += 52
        }
        bar(hasDisc ? tr("VALOR COM DESCONTO") : tr("TOTAL"), QuoteMath.brl(QuoteMath.finalValue(q)), l, r, y)
        y += 34 + 16
    }

    private func tab(_ top: CGFloat, _ ic: String, _ title: String, _ cont: Bool) {
        let more = tr("(CONTINUAÇÃO)")
        let w = 36 + qpW(title, 10.5, true) + (cont ? 6 + qpW(more, 9.5, true) : 0) + 26
        let b = top + 25
        let p = UIBezierPath()
        p.move(to: CGPoint(x: QM + 7, y: top))
        p.addLine(to: CGPoint(x: QM + w, y: top))
        p.addLine(to: CGPoint(x: QM + w - 13, y: b))
        p.addLine(to: CGPoint(x: QM, y: b))
        p.addLine(to: CGPoint(x: QM, y: top + 7))
        p.addQuadCurve(to: CGPoint(x: QM + 7, y: top), controlPoint: CGPoint(x: QM, y: top))
        p.close()
        qpFill(p, QDARK)
        qpIcon(ic, QM + 12, top + 5.5, 14, QYEL)
        qpText(title, QM + 36, top + 16.5, 10.5, bold: true, color: .white)
        if cont { qpText(more, QM + 36 + qpW(title, 10.5, true) + 6, top + 16.5, 9.5, bold: true, color: QYEL) }
    }

    /// Seção: aba escura com o título e cartão com as linhas. Passou do fim da folha, continua na outra com "(CONTINUAÇÃO)".
    private func section(_ ic: String, _ title: String, _ blocks: [QBlock], _ padB: CGFloat = 9) {
        if blocks.isEmpty { return }
        let head: CGFloat = 33
        var i = 0
        var first = true
        while i < blocks.count {
            if y + head + blocks[i].h + padB > QBOTTOM && y > QTOP { next() }
            let top = y
            var cy = top + head
            let start = i
            while i < blocks.count && (cy + blocks[i].h + padB <= QBOTTOM || i == start) { cy += blocks[i].h; i += 1 }
            let bottom = cy + padB
            let card = qpRR(QM, top + 15, QW - QM, bottom, 0, 8, 8, 8)
            qpFill(card, QSOFT)
            qpStroke(card, QEDGE, 0.8)
            tab(top, ic, title, !first)
            var by = top + head
            for k in start..<i { blocks[k].draw(by, k == start); by += blocks[k].h }
            y = bottom + 14
            first = false
            if i < blocks.count { next() }
        }
    }

    private func addenda() {
        let ads = q.addenda.filter { !qpBlank($0.desc) || $0.value != 0 }
        if ads.isEmpty { return }
        let descX = QM + 84, descW = 470 - (QM + 84)
        var blocks: [QBlock] = []
        for (ai, a) in ads.enumerated() {
            let ls = qpWrap(qpBlank(a.desc) ? "—" : a.desc, 10.5, false, descW)
            let date = df.string(from: Date(timeIntervalSince1970: Double(a.dateMs) / 1000))
            let value = QuoteMath.brl(a.value)
            for (k, l) in ls.enumerated() {
                let h: CGFloat = 14 + (k == 0 ? 6 : 0) + (k == ls.count - 1 ? 5 : 0)
                blocks.append(QBlock(h: h) { top, firstSeg in
                    let base = top + (k == 0 ? 6 : 0) + 10.5
                    if k == 0 {
                        if ai > 0 && !firstSeg { qpRect(QM + 12, top - 0.35, QW - QM - 12, top + 0.35, QEDGE) }
                        qpText(date, QM + 14, base, 9.5, color: QGRAY)
                        qpText(value, QW - QM - 12, base, 10.5, bold: true, align: .right)
                    }
                    qpText(l, descX, base, 10.5)
                })
            }
        }
        section("plus", tr("ADITIVOS"), blocks)
        if y + 20 + 34 > QBOTTOM { next() }
        qpText(tr("Total dos aditivos"), 412, y + 10, 10.5, color: QTXT, align: .right)
        qpText(QuoteMath.brl(QuoteMath.addendaTotal(q)), QW - QM - 12, y + 10, 10.5, align: .right)
        y += 20
        bar(tr("TOTAL COM ADITIVOS"), QuoteMath.brl(QuoteMath.grandTotal(q)), 262, QW - QM, y)
        y += 34 + 16
    }

    private func iconFor(_ label: String) -> String {
        if QuotePdf.oneOf(label, ["Material"]) { return "doc" }
        if QuotePdf.oneOf(label, ["Móveis do projeto"]) { return "box" }
        if QuotePdf.oneOf(label, ["Cores do projeto"]) { return "roller" }
        return "info"
    }

    private func details(_ rows: [QuotePdf.NoteRow]) {
        let until = Date(timeIntervalSince1970: Double(q.dateMs) / 1000 + Double(q.validityDays) * 86400)
        var all: [(String, String, [String])] = [("cal", tr("Validade da proposta"), [tr("{0} dias (até {1})", q.validityDays, df.string(from: until))])]
        for r in rows { all.append((iconFor(r.label), r.label, r.lines)) }
        let labX = QM + 40
        let labW = min(150, all.map { qpW($0.1 + ":", 10, true) }.max() ?? 0)
        let valX = labX + labW + 16
        let valW = QW - QM - 12 - valX
        var blocks: [QBlock] = []
        for (ri, row) in all.enumerated() {
            let ic = row.0
            let ll = qpWrap(row.1 + ":", 10, true, labW)
            let vl = row.2.flatMap { qpWrap($0, 10, false, valW) }
            let n = max(ll.count, vl.count, 1)
            for k in 0..<n {
                let h: CGFloat = 14 + (k == 0 ? 7 : 0) + (k == n - 1 ? 4 : 0)
                blocks.append(QBlock(h: h) { top, firstSeg in
                    let base = top + (k == 0 ? 7 : 0) + 10.5
                    if k == 0 {
                        if ri > 0 && !firstSeg { qpRect(labX, top - 0.35, QW - QM - 12, top + 0.35, QEDGE) }
                        qpIcon(ic, QM + 13, top + 5, 15, QINK)
                    }
                    if k < ll.count { qpText(ll[k], labX, base, 10, bold: true) }
                    if k < vl.count { qpText(vl[k], valX, base, 10) }
                })
            }
        }
        section("list", tr("DETALHES DA PROPOSTA"), blocks)
    }

    /// Fotos inteiras (sem cortar nada do móvel): cada linha ocupa a largura do cartão, todas na mesma altura.
    private func photoSec() {
        let ph = photos.filter { $0.size.width > 0 && $0.size.height > 0 }
        if ph.isEmpty { return }
        let x0 = QM + 10, wAll = QW - 2 * QM - 20, gap: CGFloat = 8
        var blocks: [QBlock] = []
        var idx = 0
        let isDry = dry
        for k in QuotePdf.photoGroups(ph.count) {
            let row = Array(ph[idx..<(idx + k)])
            idx += k
            let ars: [CGFloat] = row.map { $0.size.width / $0.size.height }
            var h = min((wAll - gap * CGFloat(k - 1)) / ars.reduce(0, +), k == 1 ? 300 : 240)
            // primeira linha: se falta pouco pra caber no resto da folha, diminui um pouco em vez de pular de folha
            if blocks.isEmpty {
                let room = QBOTTOM - y - 33 - 2 - gap
                if h > room && room >= h * 0.6 { h = room }
            }
            let hh = h
            let ws: [CGFloat] = ars.map { $0 * hh }
            let tot = ws.reduce(0, +) + gap * CGFloat(k - 1)
            blocks.append(QBlock(h: hh + gap) { top, _ in
                var x = x0 + (wAll - tot) / 2
                for (j, b) in row.enumerated() {
                    let r = CGRect(x: x, y: top, width: ws[j], height: hh)
                    if !isDry {
                        let cg = UIGraphicsGetCurrentContext()
                        cg?.saveGState()
                        UIBezierPath(roundedRect: r, cornerRadius: 6).addClip()
                        b.draw(in: r)
                        cg?.restoreGState()
                    }
                    x += ws[j] + gap
                }
            })
        }
        section("camera", tr("FOTOS DO PROJETO"), blocks, 2)
    }

    private func specs(_ parts: [String]) {
        if parts.count < 2 { return }
        let half = (parts.count + 1) / 2
        let colW = (QW - 2 * QM) / 2
        var blocks: [QBlock] = []
        for r in 0..<half {
            blocks.append(QBlock(h: 21) { top, firstSeg in
                if !firstSeg {
                    qpRect(QM + 38, top - 0.35, QM + colW - 14, top + 0.35, QEDGE)
                    if r + half < parts.count { qpRect(QM + colW + 38, top - 0.35, QW - QM - 12, top + 0.35, QEDGE) }
                }
                qpRect(QM + colW - 0.4, top + 1, QM + colW + 0.4, top + 20, QEDGE)
                for col in 0...1 {
                    let i = r + col * half
                    if i >= parts.count { continue }
                    let x = QM + 16 + CGFloat(col) * colW
                    qpIcon("check", x, top + 4, 13, QINK)
                    let (s, z) = qpFit(parts[i], 10, false, colW - 16 - 22 - 14, 7.5)
                    qpText(s, x + 22, top + 14.5, z)
                }
            })
        }
        section("tools", tr("ESPECIFICAÇÕES TÉCNICAS"), blocks)
    }

    private func obs(_ free: [String]) {
        if free.isEmpty { return }
        var blocks: [QBlock] = []
        for raw in free {
            var t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if t.hasPrefix("•") { t = String(t.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) }
            else if t.hasPrefix("- ") { t = String(t.dropFirst(2)).trimmingCharacters(in: .whitespacesAndNewlines) }
            for (k, l) in qpWrap(t, 10.5, false, QW - 2 * QM - 30 - 14).enumerated() {
                blocks.append(QBlock(h: 14.5) { top, _ in
                    if k == 0 { qpFill(UIBezierPath(ovalIn: CGRect(x: QM + 19 - 1.7, y: top + 7.2 - 1.7, width: 3.4, height: 3.4)), QINK) }
                    qpText(l, QM + 30, top + 11, 10.5)
                })
            }
        }
        section("note", tr("OBSERVAÇÕES"), blocks)
    }

    /// Desenha o orçamento inteiro e devolve quantas páginas ele ocupou.
    func run() -> Int {
        next()
        client()
        table()
        totals()
        addenda()
        let parsed = QuotePdf.parseNotes(q.notes)
        details(parsed.rows)
        photoSec()
        specs(QuotePdf.specParts(parsed.rows))
        obs(parsed.free)
        return no
    }
}

/// Orçamento em PDF (A4). Cabeçalho com os dados da empresa e o selo ORÇAMENTO, cartão do cliente, tabela dos itens, totais,
/// aditivos, detalhes da proposta, fotos do projeto, especificações técnicas e observações; rodapé com a página.
/// Só entra o que existe no orçamento: nada é inventado. Se vier a nota, as folhas do desenho entram depois.
enum QuotePdf {
    /// Uma linha "Rótulo: texto" das observações (com as linhas seguintes, quando é uma lista).
    struct NoteRow: Equatable {
        var label: String
        var lines: [String]
    }

    private static let LABELS = ["Material", "Móveis do projeto", "Cores do projeto"]
    private static let WALLS = ["Parede do fundo", "Parede da esquerda", "Parede da direita"]

    static func oneOf(_ s: String, _ keys: [String]) -> Bool {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return keys.contains { t == $0.lowercased() || t == tr($0).lowercased() }
    }

    /// Linha de móvel da lista do editor: "• 2 × Balcão · …".
    private static func furnBullet(_ l: String) -> Bool {
        guard l.hasPrefix("• ") else { return false }
        let r = l.dropFirst(2)
        let n = r.prefix { $0 >= "0" && $0 <= "9" }.count
        return n > 0 && r.dropFirst(n).hasPrefix(" × ")
    }

    /// Separa as observações do orçamento. As linhas que o editor de móveis escreve (Material, Móveis do projeto com a lista
    /// e Cores do projeto) viram linhas dos detalhes da proposta; tudo que a pessoa digitou fica em Observações.
    /// Nenhum texto é mudado nem some.
    static func parseNotes(_ notes: String) -> (rows: [NoteRow], free: [String]) {
        var rows: [NoteRow] = []
        var free: [String] = []
        var open: Int? = nil
        for raw in notes.components(separatedBy: "\n") {
            let l = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if l.isEmpty { open = nil; continue }
            // lista aberta: as linhas dos móveis e o nome da parede ("Parede do fundo:") entram nela
            if let o = open, furnBullet(l) || (l.hasSuffix(":") && oneOf(String(l.dropLast()), WALLS)) {
                rows[o].lines.append(l)
                continue
            }
            open = nil
            if l.hasSuffix(":") {
                // cabeçalho de lista: "Móveis do projeto (3) · largura × altura × profundidade:"
                var cut: String.Index? = nil
                if let a = l.range(of: " (")?.lowerBound, a > l.startIndex { cut = a }
                if let b = l.range(of: " · ")?.lowerBound, b > l.startIndex {
                    if let c = cut { if b < c { cut = b } } else { cut = b }
                }
                var label = String(l.dropLast())
                var rest = ""
                if let c = cut {
                    label = String(l[..<c])
                    rest = String(l[c...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if rest.hasPrefix("·") { rest = String(rest.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                label = label.trimmingCharacters(in: .whitespacesAndNewlines)
                if oneOf(label, LABELS) {
                    rows.append(NoteRow(label: label, lines: rest.isEmpty ? [] : [rest]))
                    open = rows.count - 1
                    continue
                }
            }
            if let r = l.range(of: ": "), r.lowerBound > l.startIndex, r.upperBound < l.endIndex, oneOf(String(l[..<r.lowerBound]), LABELS) {
                rows.append(NoteRow(label: String(l[..<r.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines),
                                    lines: [String(l[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)]))
                continue
            }
            free.append(l)
        }
        return (rows, free)
    }

    /// Partes da linha Material ("MDF 15 mm · caixa Branco · …"), uma por item das especificações.
    static func specParts(_ rows: [NoteRow]) -> [String] {
        guard let mat = rows.first(where: { oneOf($0.label, ["Material"]) }) else { return [] }
        var s = mat.lines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix(".") { s.removeLast() }
        return s.components(separatedBy: " · ").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            .map { String($0.prefix(1)).uppercased() + String($0.dropFirst()) }
    }

    /// Quantas fotos em cada linha: até 3 numa linha; sobrando 2 ou 4, as primeiras linhas saem com 2 fotos maiores.
    static func photoGroups(_ n: Int) -> [Int] {
        if n <= 0 { return [] }
        if n <= 3 { return [n] }
        if n % 3 == 0 { return Array(repeating: 3, count: n / 3) }
        if n % 3 == 2 { return [2] + Array(repeating: 3, count: (n - 2) / 3) }
        return [2, 2] + Array(repeating: 3, count: (n - 4) / 3)
    }

    static func write(company: Company, quote q: Quote, note: Note?, logo: UIImage?, photos: [UIImage] = [], to url: URL) throws {
        // 1ª passada: só conta as páginas do orçamento, pro rodapé dizer "página N/M"
        var total = 0
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        _ = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4), format: fmt).image { _ in
            total = QuotePdfLayout(pdf: nil, total: 0, company: company, q: q, logo: logo, photos: photos).run()
        }
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: QW, height: QH))
        try renderer.writePDF(to: url) { ctx in
            let lay = QuotePdfLayout(pdf: ctx, total: total, company: company, q: q, logo: logo, photos: photos)
            _ = lay.run()
            // desenho (folhas da nota), uma página cada
            if q.includeDrawing, let n = note {
                let r = SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 3000) })
                let k = QW / Sheet.W
                for s in n.pages {
                    lay.blank()
                    let c = ctx.cgContext
                    c.saveGState(); c.scaleBy(x: k, y: k)
                    r.draw(c, s, n.unit, selectedId: nil, viewScale: 1, withPaper: false)
                    c.restoreGState()
                }
            }
        }
    }
}
