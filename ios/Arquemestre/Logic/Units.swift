import Foundation

/// Conversões e formatação. Internamente tudo é milímetro (igual ao Android).
enum Units {
    static let PENDING_LABEL = "···"

    static func fromMm(_ mm: Double, _ u: LengthUnit) -> Double {
        switch u { case .MM: return mm; case .CM: return mm / 10; case .M: return mm / 1000 }
    }

    static func toMm(_ v: Double, _ u: LengthUnit) -> Double {
        switch u { case .MM: return v; case .CM: return v * 10; case .M: return v * 1000 }
    }

    private static func formatter(min: Int, max: Int) -> NumberFormatter {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumIntegerDigits = 1
        f.minimumFractionDigits = min
        f.maximumFractionDigits = max
        f.roundingMode = .halfUp
        return f
    }
    private static let fMM = formatter(min: 0, max: 1)
    private static let fCM = formatter(min: 1, max: 2)
    private static let fM = formatter(min: 3, max: 3) // 3 casas igual ao visor da trena

    /// Número sem sufixo (vírgula decimal).
    static func formatNumber(_ mm: Double, _ u: LengthUnit) -> String {
        let v = fromMm(mm, u)
        let f: NumberFormatter = u == .MM ? fMM : (u == .CM ? fCM : fM)
        // arredonda pela representação decimal (evita 0,5 virar 0 por causa do binário)
        let dec = NSDecimalNumber(string: String(format: "%.6f", v))
        return f.string(from: dec) ?? String(v)
    }

    static func format(_ mm: Double, _ u: LengthUnit) -> String { formatNumber(mm, u) + " " + u.label }

    static func labelSeg(_ seg: Seg, _ u: LengthUnit) -> String { seg.valueMm.map { format($0, u) } ?? PENDING_LABEL }

    static func label(_ d: DimObj, _ u: LengthUnit) -> String { d.valueMm.map { format($0, u) } ?? "" }

    /// Lê o que foi digitado: vírgula ou ponto e sufixo opcional (mm, cm, m). Retorna mm.
    static func parseToMm(_ text: String, _ current: LengthUnit) -> Double? {
        var t = text.trimmingCharacters(in: .whitespaces).lowercased()
        var unit = current
        if t.hasSuffix("mm") { unit = .MM; t.removeLast(2) }
        else if t.hasSuffix("cm") { unit = .CM; t.removeLast(2) }
        else if t.hasSuffix("m") { unit = .M; t.removeLast(1) }
        t = t.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard let v = Double(t), v.isFinite, v > 0 else { return nil }
        return toMm(v, unit)
    }
}

/// Calculadora simples: + − × ÷, %, parênteses, vírgula ou ponto.
enum Calc {
    static func eval(_ expr: String) -> Double? {
        let s = expr.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/").replacingOccurrences(of: "−", with: "-")
        if s.isEmpty { return nil }
        var p = Parser(Array(s))
        guard let v = try? p.parseExpr(), p.pos == p.s.count, v.isFinite else { return nil }
        return v
    }

    static func format(_ v: Double) -> String {
        let r = (v * 1_000_000).rounded() / 1_000_000
        var txt: String
        if r == r.rounded() && abs(r) < 1e12 { txt = String(format: "%.0f", r) } else {
            txt = String(format: "%.6f", r)
            while txt.hasSuffix("0") { txt.removeLast() }
            if txt.hasSuffix(".") { txt.removeLast() }
        }
        return txt.replacingOccurrences(of: ".", with: ",")
    }

    private struct Parser {
        let s: [Character]
        var pos = 0
        init(_ s: [Character]) { self.s = s }
        struct E: Error {}
        mutating func parseExpr() throws -> Double {
            var v = try parseTerm()
            while pos < s.count && (s[pos] == "+" || s[pos] == "-") {
                let op = s[pos]; pos += 1
                let r = try parseTerm()
                v = op == "+" ? v + r : v - r
            }
            return v
        }
        mutating func parseTerm() throws -> Double {
            var v = try parseUnary()
            while pos < s.count && (s[pos] == "*" || s[pos] == "/") {
                let op = s[pos]; pos += 1
                let r = try parseUnary()
                if op == "/" && r == 0 { throw E() }
                v = op == "*" ? v * r : v / r
            }
            return v
        }
        mutating func parseUnary() throws -> Double {
            if pos < s.count && s[pos] == "-" { pos += 1; return -(try parseUnary()) }
            if pos < s.count && s[pos] == "+" { pos += 1; return try parseUnary() }
            var v = try parseAtom()
            while pos < s.count && s[pos] == "%" { pos += 1; v /= 100 }
            return v
        }
        mutating func parseAtom() throws -> Double {
            if pos < s.count && s[pos] == "(" {
                pos += 1
                let v = try parseExpr()
                if pos >= s.count || s[pos] != ")" { throw E() }
                pos += 1
                return v
            }
            let st = pos
            while pos < s.count && (s[pos].isNumber || s[pos] == ".") { pos += 1 }
            if st == pos { throw E() }
            guard let d = Double(String(s[st..<pos])) else { throw E() }
            return d
        }
    }
}

/// Contas do orçamento e reais.
enum QuoteMath {
    static func cents(_ v: Double) -> Double { (v * 100).rounded() / 100 }
    static func lineTotal(_ i: QuoteItem) -> Double { cents(i.qty * i.unitValue) }
    static func original(_ q: Quote) -> Double { cents(q.items.reduce(0) { $0 + lineTotal($1) }) }
    static func discountValue(_ q: Quote) -> Double { cents(original(q) * min(max(q.discountPct, 0), 100) / 100) }
    static func finalValue(_ q: Quote) -> Double { cents(original(q) - discountValue(q)) }

    private static let brlF: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "pt_BR")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2; f.maximumFractionDigits = 2
        f.usesGroupingSeparator = true
        return f
    }()

    /// 1234.5 → "R$ 1.234,50".
    static func brl(_ v: Double) -> String { "R$ " + (brlF.string(from: NSNumber(value: cents(v))) ?? "0,00") }

    static func numStr(_ d: Double) -> String {
        if d == d.rounded() && abs(d) < 1e15 { return String(Int64(d)) }
        return String(d).replacingOccurrences(of: ".", with: ",")
    }
}
