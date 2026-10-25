import Foundation
import StoreKit

/// Licença no iPhone/iPad, do jeito que a Apple permite (App Review 3.1.1):
///  • teste grátis = compra NÃO consumível de preço zero ("Teste grátis de 3 dias");
///  • acesso completo = compra única NÃO consumível;
///  • restaurar compras (mesmo Apple ID).
/// Sem login e sem servidor: o StoreKit guarda e assina as compras.
@MainActor
final class LicenseManager: ObservableObject {
    static let FULL_ID = "arquemestre_acesso_completo"
    static let TRIAL_ID = "arquemestre_teste_3_dias"
    static let TRIAL_DAYS = 3
    static let TRIAL_SECONDS: TimeInterval = Double(TRIAL_DAYS) * 24 * 3600

    enum Status: Equatable { case loading, notStarted, trial, expired, unlocked }

    @Published private(set) var status: Status = .loading
    @Published private(set) var fullProduct: Product?
    @Published private(set) var trialProduct: Product?
    @Published var busy = false
    @Published var message: String?

    private let d = UserDefaults.standard
    private var updates: Task<Void, Never>?

    var fullPrice: String { fullProduct?.displayPrice ?? "pagamento único" }

    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-trialOffer") { status = .notStarted; return }
        if ProcessInfo.processInfo.arguments.contains("-demo") { status = .unlocked; return }
        #endif
        updates = Task { [weak self] in
            for await r in Transaction.updates {
                if case .verified(let t) = r { await t.finish() }
                await self?.refresh()
            }
        }
        Task { await load() }
    }

    deinit { updates?.cancel() }

    func load() async {
        do {
            let ps = try await Product.products(for: [LicenseManager.FULL_ID, LicenseManager.TRIAL_ID])
            fullProduct = ps.first { $0.id == LicenseManager.FULL_ID }
            trialProduct = ps.first { $0.id == LicenseManager.TRIAL_ID }
        } catch {
            // sem internet: o que já foi comprado continua valendo (fica guardado no aparelho)
        }
        await refresh()
    }

    /// Lê as compras assinadas pela Apple que estão neste Apple ID.
    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-trialOffer") { status = .notStarted; return }
        if ProcessInfo.processInfo.arguments.contains("-demo") { status = .unlocked; return }
        #endif
        var unlocked = false
        var trialStart: Date?
        for await r in Transaction.currentEntitlements {
            guard case .verified(let t) = r, t.revocationDate == nil else { continue }
            if t.productID == LicenseManager.FULL_ID { unlocked = true }
            if t.productID == LicenseManager.TRIAL_ID { trialStart = t.originalPurchaseDate }
        }
        if unlocked { d.set(true, forKey: "lic.unlocked") } else { d.set(false, forKey: "lic.unlocked") }
        if let s = trialStart { d.set(s.timeIntervalSince1970, forKey: "lic.trialStart") }
        status = computeStatus(unlocked: unlocked, trialStart: trialStart ?? storedTrialStart)
    }

    private var storedTrialStart: Date? {
        let v = d.double(forKey: "lic.trialStart")
        return v > 0 ? Date(timeIntervalSince1970: v) : nil
    }

    /// Tempo de teste usado, protegido contra voltar o relógio (vale a maior data já vista).
    nonisolated static func used(start: Date, now: Date, seen: Date?) -> TimeInterval {
        let ref = max(now, seen ?? now)
        return max(0, ref.timeIntervalSince(start))
    }

    private func computeStatus(unlocked: Bool, trialStart: Date?) -> Status {
        if unlocked { return .unlocked }
        guard let start = trialStart else { return .notStarted }
        let now = Date()
        let seenV = d.double(forKey: "lic.seen")
        let seen = seenV > 0 ? Date(timeIntervalSince1970: seenV) : nil
        d.set(max(now, seen ?? now).timeIntervalSince1970, forKey: "lic.seen")
        return LicenseManager.used(start: start, now: now, seen: seen) >= LicenseManager.TRIAL_SECONDS ? .expired : .trial
    }

    /// "1 dia e 5 h", "3 h", "20 min".
    var leftLabel: String {
        guard let start = storedTrialStart else { return "\(LicenseManager.TRIAL_DAYS) dias" }
        let seenV = d.double(forKey: "lic.seen")
        let left = max(0, LicenseManager.TRIAL_SECONDS - LicenseManager.used(start: start, now: Date(), seen: seenV > 0 ? Date(timeIntervalSince1970: seenV) : nil))
        return LicenseManager.leftText(left)
    }

    nonisolated static func leftText(_ left: TimeInterval) -> String {
        let h = Int(left / 3600)
        if h >= 24 {
            let dd = h / 24, hh = h % 24
            return "\(dd) dia" + (dd > 1 ? "s" : "") + (hh > 0 ? " e \(hh) h" : "")
        }
        if h >= 1 { return "\(h) h" }
        return "\(Int(left / 60)) min"
    }

    // ---- ações ----
    func startTrial() async { await purchase(trialProduct, ok: "Teste grátis de \(LicenseManager.TRIAL_DAYS) dias liberado.") }
    func buyFull() async { await purchase(fullProduct, ok: "Compra confirmada. App desbloqueado. Obrigado!") }

    private func purchase(_ p: Product?, ok: String) async {
        guard let p = p else {
            message = "Não consegui falar com a App Store agora. Confira a internet e tente de novo."
            await load()
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await p.purchase() {
            case .success(let r):
                if case .verified(let t) = r { await t.finish(); message = ok } else { message = "A compra não pôde ser verificada." }
            case .pending: message = "Compra pendente (aguardando aprovação). O app libera sozinho quando for aprovada."
            case .userCancelled: break
            @unknown default: break
            }
        } catch {
            message = "Não deu certo: \(error.localizedDescription)"
        }
        await refresh()
    }

    func restore() async {
        busy = true
        defer { busy = false }
        do { try await AppStore.sync() } catch { message = "Não consegui falar com a App Store agora." }
        await refresh()
        if status != .unlocked && status != .trial { message = "Não encontrei compra neste Apple ID." }
        else if status == .unlocked { message = "Compra restaurada. App desbloqueado." }
    }
}
