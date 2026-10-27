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

/// Orçamento em PDF (A4). Se vier a nota, as folhas do desenho entram depois.
enum QuotePdf {
    static let W: CGFloat = 595, H: CGFloat = 842, M: CGFloat = 40
    static let GOLD = UIColor(argb: argb(0xFFB8903A)), INK = UIColor(argb: argb(0xFF1B1B1B)), GRAY = UIColor(argb: argb(0xFF666666))

    private static func font(_ size: CGFloat, _ bold: Bool) -> UIFont { bold ? .boldSystemFont(ofSize: size) : .systemFont(ofSize: size) }

    private static func draw(_ s: String, _ x: CGFloat, _ baseline: CGFloat, _ size: CGFloat, bold: Bool = false, color: UIColor = INK, right: Bool = false) {
        let f = font(size, bold)
        let attrs: [NSAttributedString.Key: Any] = [.font: f, .foregroundColor: color]
        let w = (s as NSString).size(withAttributes: attrs).width
        (s as NSString).draw(at: CGPoint(x: right ? x - w : x, y: baseline - f.ascender), withAttributes: attrs)
    }

    private static func wrap(_ text: String, _ size: CGFloat, _ width: CGFloat) -> [String] {
        let attrs: [NSAttributedString.Key: Any] = [.font: font(size, false)]
        func w(_ s: String) -> CGFloat { (s as NSString).size(withAttributes: attrs).width }
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

    static func write(company: Company, quote q: Quote, note: Note?, logo: UIImage?, to url: URL) throws {
        let df = I18n.shared.dateFormatter(.date)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: W, height: H))
        try renderer.writePDF(to: url) { ctx in
            var y = M
            func newPage() { ctx.beginPage(); UIColor.white.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: W, height: H)); y = M }
            func ensure(_ h: CGFloat, _ onNew: () -> Void = {}) { if y + h > H - M { newPage(); onNew() } }
            newPage()
            let top = y
            var tx = M, logoH: CGFloat = 0
            if let lg = logo, lg.size.width > 0, lg.size.height > 0 {
                let k = min(64 / lg.size.height, 150 / lg.size.width)
                let lw = lg.size.width * k; logoH = lg.size.height * k
                lg.draw(in: CGRect(x: M, y: top, width: lw, height: logoH))
                tx = M + lw + 14
            }
            draw((company.name.isEmpty ? tr("Minha empresa") : company.name).uppercased(), tx, y + 18, 18, bold: true)
            y += 26
            let sub = [company.cnpj.isEmpty ? nil : tr("CNPJ {0}", company.cnpj), company.phone.isEmpty ? nil : company.phone].compactMap { $0 }.joined(separator: "  ·  ")
            if !sub.isEmpty { draw(sub, tx, y + 10, 10, color: GRAY); y += 14 }
            let addr = [company.address, company.city].filter { !$0.isEmpty }.joined(separator: " - ")
            if !addr.isEmpty { draw(addr, tx, y + 10, 10, color: GRAY); y += 14 }
            if y < top + logoH { y = top + logoH }
            y += 6
            GOLD.setFill(); ctx.fill(CGRect(x: M, y: y - 1, width: W - 2 * M, height: 2))
            y += 22
            draw(tr("ORÇAMENTO"), M, y, 20, bold: true)
            draw(df.string(from: Date(timeIntervalSince1970: Double(q.dateMs) / 1000)), W - M, y, 11, color: GRAY, right: true)
            y += 22
            draw(tr("CLIENTE"), M, y, 10, color: GRAY); draw(tr("CIDADE"), 330, y, 10, color: GRAY)
            y += 15
            draw(q.clientName.isEmpty ? "—" : q.clientName, M, y, 12, bold: true); draw(q.city.isEmpty ? "—" : q.city, 330, y, 12, bold: true)
            y += 26

            let right1: CGFloat = 300, unitX: CGFloat = 308, right2: CGFloat = 440, right3 = W - M
            let descW = right1 - 52 - M
            func head() {
                INK.setFill(); ctx.fill(CGRect(x: M, y: y, width: W - 2 * M, height: 20))
                draw(tr("DESCRIÇÃO"), M + 6, y + 13.5, 9.5, bold: true, color: .white)
                draw(tr("QTD"), right1, y + 13.5, 9.5, bold: true, color: .white, right: true)
                draw(tr("UN"), unitX, y + 13.5, 9.5, bold: true, color: .white)
                draw(tr("VALOR UNIT."), right2, y + 13.5, 9.5, bold: true, color: .white, right: true)
                draw(tr("SUBTOTAL"), right3 - 6, y + 13.5, 9.5, bold: true, color: .white, right: true)
                y += 20
            }
            head()
            let items = q.items.filter { !$0.desc.isEmpty || $0.unitValue != 0 }
            for (idx, it) in items.enumerated() {
                let lines = wrap(it.desc.isEmpty ? "—" : it.desc, 11, descW)
                let rowH = CGFloat(lines.count) * 14 + 10
                ensure(rowH + 4, head)
                if idx % 2 == 1 { UIColor(argb: argb(0xFFF6F3EC)).setFill(); ctx.fill(CGRect(x: M, y: y, width: W - 2 * M, height: rowH)) }
                var ty = y + 15
                for l in lines { draw(l, M + 6, ty, 11); ty += 14 }
                let y1 = y + 15
                draw(QuoteMath.numStr(it.qty), right1, y1, 11, right: true)
                draw(it.unit, unitX, y1, 11)
                draw(QuoteMath.brl(it.unitValue), right2, y1, 11, right: true)
                draw(QuoteMath.brl(QuoteMath.lineTotal(it)), right3 - 6, y1, 11, bold: true, right: true)
                y += rowH
                UIColor(argb: argb(0xFFDDDDDD)).setFill(); ctx.fill(CGRect(x: M, y: y - 0.35, width: W - 2 * M, height: 0.7))
            }
            y += 14
            let hasDisc = q.discountPct > 0
            ensure(hasDisc ? 90 : 50)
            if hasDisc {
                draw(tr("Valor original"), right2, y + 12, 11, color: GRAY, right: true)
                draw(QuoteMath.brl(QuoteMath.original(q)), right3 - 6, y + 12, 11, right: true)
                y += 18
                draw(tr("Desconto ({0}%)", QuoteMath.numStr(q.discountPct)), right2, y + 12, 11, color: GRAY, right: true)
                draw("− " + QuoteMath.brl(QuoteMath.discountValue(q)), right3 - 6, y + 12, 11, right: true)
                y += 22
            }
            GOLD.setFill(); ctx.fill(CGRect(x: 300, y: y, width: W - M - 300, height: 28))
            draw(hasDisc ? tr("VALOR COM DESCONTO") : tr("TOTAL"), 308, y + 18.5, 10.5, bold: true, color: .white)
            draw(QuoteMath.brl(QuoteMath.finalValue(q)), right3 - 8, y + 19, 14, bold: true, color: .white, right: true)
            y += 46
            let until = Date(timeIntervalSince1970: Double(q.dateMs) / 1000 + Double(q.validityDays) * 86400)
            var extra = [tr("Validade desta proposta: {0} dias (até {1}).", q.validityDays, df.string(from: until))]
            if !q.notes.trimmingCharacters(in: .whitespaces).isEmpty { extra.append(tr("Observações: ") + q.notes.trimmingCharacters(in: .whitespaces)) }
            for l in extra.flatMap({ wrap($0, 11, W - 2 * M) + [""] }) {
                ensure(16)
                draw(l, M, y + 11, 11); y += l.isEmpty ? 6 : 15
            }
            if q.includeDrawing, let n = note {
                let r = SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 3000) })
                let k = W / Sheet.W
                for s in n.pages {
                    newPage()
                    let c = ctx.cgContext
                    c.saveGState(); c.scaleBy(x: k, y: k)
                    r.draw(c, s, n.unit, selectedId: nil, viewScale: 1, withPaper: false)
                    c.restoreGState()
                }
            }
        }
    }
}
