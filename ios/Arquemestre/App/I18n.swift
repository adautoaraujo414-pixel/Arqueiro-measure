import Foundation
import SwiftUI

/// Idiomas do app. O texto original (português) é a chave; os outros idiomas vêm de en.json / es.json
/// (os mesmos arquivos do Android e do editor de móveis). Texto sem tradução continua em português.
enum AppLang: String, CaseIterable, Identifiable {
    case auto, pt, en, es
    var id: String { rawValue }
    /// Nome no próprio idioma.
    var label: String {
        switch self {
        case .auto: return ""
        case .pt: return "Português"
        case .en: return "English"
        case .es: return "Español"
        }
    }
}

final class I18n: ObservableObject {
    static let shared = I18n()
    private static let key = "arque.lang"

    /// Idioma escolhido (auto = segue o iPhone).
    @Published private(set) var choice: AppLang = .auto
    /// Idioma em uso: "pt", "en" ou "es". A tela raiz usa isto como identidade: trocar redesenha tudo.
    @Published private(set) var lang: String = "pt"

    fileprivate var dict: [String: String] = [:]

    init() {
        choice = AppLang(rawValue: UserDefaults.standard.string(forKey: Self.key) ?? "auto") ?? .auto
        // testes automáticos conferem os textos originais (português)
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { choice = .pt }
        // capturas automáticas: "-arque.lang en" escolhe o idioma só nesta abertura
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-arque.lang"), i + 1 < args.count, let l = AppLang(rawValue: args[i + 1]) { choice = l }
        apply()
    }

    func set(_ l: AppLang) {
        UserDefaults.standard.set(l.rawValue, forKey: Self.key)
        choice = l
        apply()
    }

    /// Idioma do aparelho: português e espanhol têm tradução; qualquer outro vira inglês.
    static func deviceLang() -> String {
        let first = (Locale.preferredLanguages.first ?? "pt").lowercased()
        if first.hasPrefix("pt") { return "pt" }
        if first.hasPrefix("es") { return "es" }
        return "en"
    }

    private func apply() {
        let code = choice == .auto ? Self.deviceLang() : choice.rawValue
        dict = code == "pt" ? [:] : Self.load(code)
        lang = code
    }

    private static func load(_ code: String) -> [String: String] {
        guard let url = Bundle.main.url(forResource: code, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: String] else { return [:] }
        return obj.filter { !$0.value.isEmpty }
    }

    func t(_ s: String) -> String {
        if dict.isEmpty || s.isEmpty { return s }
        if let v = dict[s] { return v }
        let core = s.trimmingCharacters(in: .whitespaces)
        if core.count != s.count, let v = dict[core] { return s.replacingOccurrences(of: core, with: v) }
        return s
    }

    var locale: Locale {
        switch lang {
        case "en": return Locale(identifier: "en_US")
        case "es": return Locale(identifier: "es")
        default: return Locale(identifier: "pt_BR")
        }
    }

    /// Formato de data do idioma (EUA: mês/dia, 12 h).
    func dateFormatter(_ kind: DateKind) -> DateFormatter {
        let f = DateFormatter()
        f.locale = locale
        switch kind {
        case .date: f.dateFormat = lang == "en" ? "MM/dd/yyyy" : "dd/MM/yyyy"
        case .hour: f.dateFormat = lang == "en" ? "h:mm a" : "HH:mm"
        case .day: f.dateFormat = lang == "en" ? "EEEE, MMMM d" : (lang == "es" ? "EEEE, d 'de' MMMM" : "EEEE, dd 'de' MMMM")
        case .month: f.dateFormat = lang == "en" ? "MMMM yyyy" : "MMMM 'de' yyyy"
        case .shortDay: f.dateFormat = lang == "en" ? "EEE MM/dd" : "EEE dd/MM"
        }
        return f
    }

    enum DateKind { case date, hour, day, month, shortDay }

    /// Região do aparelho (Brasil → R$; EUA → $; Espanha → €...).
    private var region: String {
        // testes automáticos conferem o formato brasileiro (R$ 1.234,50), como no Android
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil { return "BR" }
        return Locale.current.region?.identifier ?? ""
    }

    /// Dinheiro na moeda do país do aparelho.
    func money(_ v: Double) -> String {
        if region == "BR" || (region.isEmpty && lang == "pt") {
            let f = NumberFormatter()
            f.locale = Locale(identifier: "pt_BR")
            f.numberStyle = .decimal
            f.minimumFractionDigits = 2
            f.maximumFractionDigits = 2
            return "R$ " + (f.string(from: NSNumber(value: v)) ?? String(format: "%.2f", v))
        }
        let f = NumberFormatter()
        f.locale = region.isEmpty ? Locale(identifier: lang == "es" ? "es_MX" : "en_US") : Locale.current
        f.numberStyle = .currency
        return f.string(from: NSNumber(value: v)) ?? String(format: "$%.2f", v)
    }

    func currencySymbol() -> String {
        if region == "BR" || (region.isEmpty && lang == "pt") { return "R$" }
        let l = region.isEmpty ? Locale(identifier: lang == "es" ? "es_MX" : "en_US") : Locale.current
        return l.currencySymbol ?? "$"
    }
}

/// Traduz um texto do app (a chave é o texto em português).
func tr(_ s: String) -> String { I18n.shared.t(s) }

/// Traduz com valores: tr("Folha {0} de {1}", 2, 5).
func tr(_ s: String, _ args: Any...) -> String {
    var r = I18n.shared.t(s)
    for (i, a) in args.enumerated() {
        let v: String
        if let o = a as? (any OptionalProtocol) { v = o.textOrEmpty } else { v = "\(a)" }
        r = r.replacingOccurrences(of: "{\(i)}", with: v)
    }
    return r
}

/// Para "Optional(x)" não aparecer na tela quando um valor opcional entra no texto.
protocol OptionalProtocol { var textOrEmpty: String { get } }
extension Optional: OptionalProtocol {
    var textOrEmpty: String {
        switch self {
        case .some(let w): return "\(w)"
        case .none: return ""
        }
    }
}

/// Nome do item de menu: sempre com "Language" junto, pra quem não lê português achar.
func langMenuLabel() -> String { "🌐 " + tr("Idioma") + (I18n.shared.lang == "en" ? "" : " · Language") }
func currentLangName() -> String { AppLang(rawValue: I18n.shared.lang)?.label ?? "Português" }

/// Escolha do idioma (lista com marcação).
struct LanguagePicker: View {
    @ObservedObject var i18n = I18n.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(AppLang.allCases) { l in
                    Button {
                        i18n.set(l)
                        dismiss()
                    } label: {
                        HStack {
                            Text(l == .auto ? tr("Automático (idioma do aparelho)") : l.label)
                                .foregroundColor(Ui.text)
                            Spacer()
                            if i18n.choice == l { Image(systemName: "checkmark").foregroundColor(Ui.accent) }
                        }
                    }
                }
            }
            .navigationTitle(langMenuLabel())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
