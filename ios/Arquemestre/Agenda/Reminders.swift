import Foundation
import UserNotifications

/// Avisos da agenda com notificações locais do iOS (funcionam com o app fechado).
/// O iOS guarda no máximo 64 avisos por app: ficam agendados os 60 mais próximos.
enum Reminders {
    static let MAX = 60
    private static var dayFmt: DateFormatter { I18n.shared.dateFormatter(.shortDay) }
    private static var hourFmt: DateFormatter { I18n.shared.dateFormatter(.hour) }

    static func requestPermission(_ done: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { ok, _ in
            DispatchQueue.main.async { done(ok) }
        }
    }

    static func whenText(_ off: Int) -> String {
        if off == 0 { return "agora" }
        if off < 60 { return tr("em {0} min", off) }
        if off < 1440 { return tr("em {0} h", off / 60) }
        if off == 1440 { return tr("amanhã") }
        return tr("em {0} dias", off / 1440)
    }

    /// Refaz todos os avisos (chamado ao salvar/apagar compromisso e ao abrir o app).
    static func rescheduleAll(_ list: [Appointment]) {
        let c = UNUserNotificationCenter.current()
        c.getPendingNotificationRequests { reqs in
            c.removePendingNotificationRequests(withIdentifiers: reqs.map(\.identifier).filter { $0.hasPrefix("appt:") })
            let now = Date()
            var items: [(Date, Appointment, Int)] = []
            for a in list where !a.done {
                for off in Set(a.remindMin) {
                    let at = a.startDate.addingTimeInterval(-Double(off) * 60)
                    if at > now { items.append((at, a, off)) }
                }
            }
            for (at, a, off) in items.sorted(by: { $0.0 < $1.0 }).prefix(MAX) {
                let ct = UNMutableNotificationContent()
                ct.title = "\(a.kind.icon) \(a.kind.label): \(a.title.isEmpty ? (a.clientName.isEmpty ? "sem título" : a.clientName) : a.title)"
                var body = tr("{0} às {1} ({2})", dayFmt.string(from: a.startDate), hourFmt.string(from: a.startDate), whenText(off))
                if !a.clientName.isEmpty { body += " · \(a.clientName)" }
                if !a.address.isEmpty { body += "\n\(a.address)" }
                ct.body = body
                ct.sound = .default
                ct.userInfo = ["appt": a.id]
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: at)
                let req = UNNotificationRequest(identifier: "appt:\(a.id):\(off)", content: ct,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
                c.add(req)
            }
        }
    }
}
