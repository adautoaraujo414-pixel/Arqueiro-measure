import SwiftUI

/// Feriados do Brasil na agenda, calculados sozinhos pra qualquer ano (sem internet):
/// feriados nacionais, pontos facultativos e datas comemorativas — inclusive os que mudam
/// com a Páscoa (Carnaval, Sexta-feira Santa, Corpus Christi) e os de "2º domingo"
/// (Dia das Mães, Dia dos Pais). Mesma lista do Android e do Windows (model/Holidays.kt).
enum Holidays {
    enum Kind: Int { case feriado = 0, facultativo = 1, comemorativa = 2 }

    struct Day: Hashable, Identifiable {
        let year: Int, month: Int, day: Int
        let name: String
        let kind: Kind
        var id: String { "\(year)-\(month)-\(day)-\(name)" }
        var kindLabel: String {
            switch kind {
            case .feriado: return "Feriado nacional"
            case .facultativo: return "Ponto facultativo"
            case .comemorativa: return "Data comemorativa"
            }
        }
        var color: Color { Holidays.color(kind) }
    }

    /// Domingo de Páscoa (Meeus/Jones/Butcher). Retorna (mês 1...12, dia).
    static func easter(_ y: Int) -> (Int, Int) {
        let a = y % 19, b = y / 100, c = y % 100, d = b / 4, e = b % 4
        let f = (b + 8) / 25, g = (b - f + 1) / 3, h = (19 * a + b - d - g + 15) % 30
        let i = c / 4, k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = (a + 11 * h + 22 * l) / 451
        return ((h + l - 7 * m + 114) / 31, ((h + l - 7 * m + 114) % 31) + 1)
    }

    private static var greg: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }

    private static func shifted(_ y: Int, _ m: Int, _ d: Int, _ days: Int) -> (Int, Int, Int) {
        let c = greg
        let base = c.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
        let r = c.date(byAdding: .day, value: days, to: base)!
        let k = c.dateComponents([.year, .month, .day], from: r)
        return (k.year!, k.month!, k.day!)
    }

    /// n-ésimo domingo do mês (1 = primeiro).
    static func nthSunday(_ y: Int, _ m: Int, _ n: Int) -> Int {
        let c = greg
        let first = c.date(from: DateComponents(year: y, month: m, day: 1, hour: 12))!
        let wd = c.component(.weekday, from: first) // 1 = domingo
        return 1 + (1 - wd + 7) % 7 + 7 * (n - 1)
    }

    private static var cache: [Int: [Day]] = [:]
    private static let lock = NSLock()

    /// Todas as datas do ano, em ordem.
    static func of(_ y: Int) -> [Day] {
        lock.lock(); defer { lock.unlock() }
        if let c = cache[y] { return c }
        var r: [Day] = []
        func add(_ m: Int, _ d: Int, _ n: String, _ k: Kind) { r.append(Day(year: y, month: m, day: d, name: n, kind: k)) }
        let (em, ed) = easter(y)
        func addE(_ off: Int, _ n: String, _ k: Kind) { let (yy, mm, dd) = shifted(y, em, ed, off); r.append(Day(year: yy, month: mm, day: dd, name: n, kind: k)) }
        add(1, 1, "Confraternização Universal", .feriado)
        addE(-48, "Carnaval", .facultativo)
        addE(-47, "Carnaval", .facultativo)
        addE(-46, "Quarta-feira de Cinzas", .facultativo)
        add(3, 8, "Dia Internacional da Mulher", .comemorativa)
        add(3, 19, "Dia do Marceneiro e do Carpinteiro", .comemorativa)
        addE(-2, "Sexta-feira Santa", .feriado)
        addE(0, "Páscoa", .comemorativa)
        add(4, 21, "Tiradentes", .feriado)
        add(5, 1, "Dia do Trabalho", .feriado)
        add(5, nthSunday(y, 5, 2), "Dia das Mães", .comemorativa)
        addE(60, "Corpus Christi", .facultativo)
        add(6, 12, "Dia dos Namorados", .comemorativa)
        add(8, nthSunday(y, 8, 2), "Dia dos Pais", .comemorativa)
        add(9, 7, "Independência do Brasil", .feriado)
        add(10, 12, "Nossa Senhora Aparecida", .feriado)
        add(10, 12, "Dia das Crianças", .comemorativa)
        add(10, 15, "Dia do Professor", .comemorativa)
        add(10, 28, "Dia do Servidor Público", .facultativo)
        add(11, 2, "Finados", .feriado)
        add(11, 15, "Proclamação da República", .feriado)
        // feriado nacional desde 2024 (Lei 14.759/2023); antes era data comemorativa
        add(11, 20, "Dia da Consciência Negra", y >= 2024 ? .feriado : .comemorativa)
        add(12, 24, "Véspera de Natal", .facultativo)
        add(12, 25, "Natal", .feriado)
        add(12, 31, "Véspera de Ano-Novo", .facultativo)
        r.sort { ($0.month, $0.day, $0.kind.rawValue) < ($1.month, $1.day, $1.kind.rawValue) }
        cache[y] = r
        return r
    }

    static func show(_ h: Day, feriados: Bool, comemorativas: Bool) -> Bool {
        h.kind == .comemorativa ? comemorativas : feriados
    }

    /// Datas de um dia (mês 1...12).
    static func on(_ y: Int, _ m: Int, _ d: Int, feriados: Bool = true, comemorativas: Bool = true) -> [Day] {
        of(y).filter { $0.month == m && $0.day == d && show($0, feriados: feriados, comemorativas: comemorativas) }
    }

    /// Datas de um dia do calendário do aparelho.
    static func on(_ date: Date, cal: Calendar, feriados: Bool = true, comemorativas: Bool = true) -> [Day] {
        let k = cal.dateComponents([.year, .month, .day], from: date)
        return on(k.year!, k.month!, k.day!, feriados: feriados, comemorativas: comemorativas)
    }

    /// Próximas datas a partir de hoje (inclusive), até n.
    static func upcoming(from date: Date, cal: Calendar, n: Int, feriados: Bool = true, comemorativas: Bool = true) -> [Day] {
        let k = cal.dateComponents([.year, .month, .day], from: date)
        let y = k.year!, m = k.month!, d = k.day!
        return Array((of(y) + of(y + 1))
            .filter { show($0, feriados: feriados, comemorativas: comemorativas) }
            .filter { $0.year > y || $0.month > m || ($0.month == m && $0.day >= d) }
            .prefix(n))
    }

    /// Cor do chip (igual a ideia do Google Agenda: feriado verde).
    static func color(_ k: Kind) -> Color {
        switch k {
        case .feriado: return Color(argb: 0xFF0B8043)
        case .facultativo: return Color(argb: 0xFF33B679)
        case .comemorativa: return Color(argb: 0xFF8E24AA)
        }
    }
}
