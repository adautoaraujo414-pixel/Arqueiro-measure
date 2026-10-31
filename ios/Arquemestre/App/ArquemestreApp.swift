import SwiftUI
import UserNotifications

extension Color {
    init(argb v: UInt32) {
        self.init(.sRGB, red: Double((v >> 16) & 0xFF) / 255, green: Double((v >> 8) & 0xFF) / 255, blue: Double(v & 0xFF) / 255, opacity: Double((v >> 24) & 0xFF) / 255)
    }
    init(model v: Int) { self.init(argb: UInt32(truncatingIfNeeded: v)) }
}

enum Ui {
    static let bg = Color(argb: 0xFF17181B)
    static let panel = Color(argb: 0xFF232529)
    static let panel2 = Color(argb: 0xFF2E3136)
    static let line = Color(argb: 0xFF3A3D43)
    static let text = Color(argb: 0xFFF2F3F5)
    static let dim = Color(argb: 0xFF9AA0A8)
    static let accent = Color(argb: 0xFF3B82F6)
    static let gold = Color(argb: 0xFFF5B400)
    static let distBlue = Color(argb: 0xFF1E5BD8)
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var onOpenAppointment: ((String) -> Void)?
    var pendingAppt: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }

    /// Toque no aviso: abre o compromisso.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if let id = response.notification.request.content.userInfo["appt"] as? String {
            if let f = onOpenAppointment { f(id) } else { pendingAppt = id }
        }
        completionHandler()
    }
}

@main
struct ArquemestreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var app = AppModel()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(app)
                .environmentObject(app.license)
                .environmentObject(app.ble)
                .environmentObject(app.peer)
                .preferredColorScheme(.dark)
                .tint(Ui.accent)
                .onAppear {
                    delegate.onOpenAppointment = { id in app.openAppointment(id) }
                    if let id = delegate.pendingAppt { delegate.pendingAppt = nil; app.openAppointment(id) }
                    app.checkCutClipboard()
                }
                // convite do plano de corte (WhatsApp → página → app): arquemestre://corte?d=...
                .onOpenURL { url in
                    guard url.scheme == "arquemestre", url.host == "corte",
                          let d = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "d" })?.value else { return }
                    app.openCutLink(d)
                }
        }
        .onChange(of: phase) { p in
            if p == .background { app.onBackground() }
            if p == .active { Task { await app.license.refresh() } }
        }
    }
}
