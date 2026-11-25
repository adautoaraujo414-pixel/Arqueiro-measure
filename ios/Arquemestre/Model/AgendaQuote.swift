import Foundation
import SwiftUI

// ---------------- Agenda ----------------

enum ApptKind: String, CaseIterable, Identifiable {
    case ENTREGA, VISITA, MEDICAO, INSTALACAO, OUTRO
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ENTREGA: return tr("Entrega")
        case .VISITA: return tr("Visita")
        case .MEDICAO: return tr("Medição")
        case .INSTALACAO: return tr("Instalação")
        case .OUTRO: return tr("Outro")
        }
    }
    var icon: String {
        switch self {
        case .ENTREGA: return "🚚"
        case .VISITA: return "🏠"
        case .MEDICAO: return "📏"
        case .INSTALACAO: return "🔧"
        case .OUTRO: return "📌"
        }
    }
    var color: Color {
        switch self {
        case .ENTREGA: return Color(argb: 0xFF22A06B)
        case .VISITA: return Color(argb: 0xFF3B82F6)
        case .MEDICAO: return Color(argb: 0xFFF5B400)
        case .INSTALACAO: return Color(argb: 0xFFB35AE8)
        case .OUTRO: return Color(argb: 0xFF9AA0A8)
        }
    }
}

struct Appointment: Equatable, Identifiable {
    var id: String = newId()
    var kind: ApptKind = .VISITA
    var title: String = ""
    var startMs: Int64 = nowMs() + 3_600_000
    var address: String = ""
    var notes: String = ""
    var clientName: String = ""
    var clientPhone: String = ""
    /// Id do projeto do cliente no editor de móveis.
    var projectId: String? = nil
    var noteId: String? = nil
    var quoteId: String? = nil
    var remindMin: [Int] = [60, 1440]
    var done: Bool = false

    var startDate: Date {
        get { Date(timeIntervalSince1970: Double(startMs) / 1000) }
        set { startMs = Int64(newValue.timeIntervalSince1970 * 1000) }
    }
}

var REMIND_OPTIONS: [(Int, String)] { [
    (0, tr("Na hora")), (15, tr("15 min antes")), (30, tr("30 min antes")), (60, tr("1 h antes")),
    (120, tr("2 h antes")), (1440, tr("1 dia antes")), (2880, tr("2 dias antes")),
]}

struct ClientRef: Equatable, Identifiable {
    var name: String
    var phone: String = ""
    var projectId: String? = nil
    var address: String = ""
    var id: String { (projectId ?? "") + "|" + name }
}

// ---------------- Orçamentos ----------------

struct Company: Equatable {
    var name = ""
    var cnpj = ""
    var address = ""
    var city = ""
    var phone = ""
}

struct QuoteItem: Equatable, Identifiable {
    var id: String = newId()
    var desc: String = ""
    var qty: Double = 1
    var unit: String = "un"
    var unitValue: Double = 0
}

/// Aditivo: item acrescentado depois do orçamento fechado, com descrição, valor e data próprios. Não mexe no orçamento original.
struct QuoteAddendum: Equatable, Identifiable {
    var id: String = newId()
    var desc: String = ""
    var value: Double = 0
    var dateMs: Int64 = nowMs()
}

/// ORC-AMB (Adauto 25/11): um ambiente (projeto do editor) no orçamento de vários ambientes do mesmo cliente.
/// Cópia dos valores do projeto no momento em que entrou (mudar o projeto depois não muda o orçamento).
/// `mat` e `labor` são custo interno: só na tela do editor; nunca no PDF nem no link do cliente. Igual ao Android e ao Windows.
struct QuoteSection: Equatable, Identifiable {
    var id: String = newId()
    var pid: String = ""
    var title: String = ""
    var desc: String = ""
    var finish: String = ""
    var mat: Double = 0
    var labor: Double = 0
    var sug: Double = 0
    var manual: Double? = nil
    var discountPct: Double = 0
    var at: Int64 = 0
}

struct Quote: Equatable, Identifiable {
    var id: String = newId()
    var clientName: String = ""
    var city: String = ""
    var dateMs: Int64 = nowMs()
    var items: [QuoteItem] = [QuoteItem()]
    var discountPct: Double = 0
    /// Regra fixa: a proposta vale 15 dias.
    var validityDays: Int = 15
    var includeDrawing: Bool = false
    var noteId: String? = nil
    var notes: String = ""
    /// Aditivos (entram depois do orçamento fechado; somam no total geral, separados do original).
    var addenda: [QuoteAddendum] = []
    /// Fotos do projeto (arquivos junto dos do editor de móveis), tiradas no 3D ou escolhidas da galeria.
    var photos: [String] = []
    /// Projeto do editor de móveis ligado a este orçamento (de onde saem as fotos).
    var projId: String? = nil
    /// ORC-AMB: ambientes do orçamento de vários ambientes (vazio = orçamento de sempre, pelos itens).
    var sections: [QuoteSection] = []
    /// ORC-AMB: cliente (nome normalizado, a mesma chave da lista de clientes do editor).
    var clientKey: String? = nil
    /// ORC-AMB: PDF só com o total geral (as descrições continuam por ambiente).
    var onlyTotal: Bool = false
}
