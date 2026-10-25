import Foundation
import SwiftUI

// ---------------- Agenda ----------------

enum ApptKind: String, CaseIterable, Identifiable {
    case ENTREGA, VISITA, MEDICAO, INSTALACAO, OUTRO
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ENTREGA: return "Entrega"
        case .VISITA: return "Visita"
        case .MEDICAO: return "Medição"
        case .INSTALACAO: return "Instalação"
        case .OUTRO: return "Outro"
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

let REMIND_OPTIONS: [(Int, String)] = [
    (0, "Na hora"), (15, "15 min antes"), (30, "30 min antes"), (60, "1 h antes"),
    (120, "2 h antes"), (1440, "1 dia antes"), (2880, "2 dias antes"),
]

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
}
