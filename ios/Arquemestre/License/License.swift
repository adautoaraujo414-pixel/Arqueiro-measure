import Foundation
import StoreKit

/// Assinatura no iPhone/iPad (App Review 3.1.2):
///  • assinatura mensal com renovação automática [SUB_ID] (grupo "Arquemestre"), R$ 29,90/mês;
///  • teste grátis = oferta introdutória de 3 dias da própria assinatura (só pra quem nunca assinou);
///  • restaurar compras e gerenciar a assinatura (cancelar) pela App Store.
/// Sem login e sem servidor: o StoreKit guarda e assina as transações.
@MainActor
final class LicenseManager: ObservableObject {
    static let SUB_ID = "arquemestre_mensal"
    /// Compra única antiga (não é mais vendida): se alguém tiver, continua valendo.
    static let LEGACY_FULL_ID = "arquemestre_acesso_completo"
    /// Teste grátis configurado na oferta introdutória (o valor real vem da App Store).
    static let TRIAL_DAYS = 3
    static let TRIAL_SECONDS: TimeInterval = Double(TRIAL_DAYS) * 24 * 3600

    /// notStarted = nunca assinou · trial = no teste grátis · unlocked = assinatura ativa · expired = assinou e acabou
    enum Status: Equatable { case loading, notStarted, trial, expired, unlocked }

    @Published private(set) var status: Status = .loading
    @Published private(set) var subProduct: Product?
    /// Esta conta ainda tem direito ao teste grátis?
    @Published private(set) var trialEligible = true
    /// Fim do teste grátis (quando está no teste) ou próxima renovação.
    @Published private(set) var periodEnd: Date?
    @Published var busy = false
    @Published var message: String?

    private var updates: Task<Void, Never>?

    /// Capturas de tela automáticas (só no build de teste): mostra o preço e o teste como na loja.
    private var demoPaywall: Bool {
        #if DEBUG
        return subProduct == nil && ProcessInfo.processInfo.arguments.contains("-trialOffer")
        #else
        return false
        #endif
    }

    /// "R$ 29,90" (preço da App Store); vazio enquanto não respondeu.
    var price: String {
        if let p = subProduct { return p.displayPrice }
        return demoPaywall ? (I18n.shared.lang == "pt" ? "R$ 29,90" : "$5.99") : ""
    }

    /// Dias do teste grátis que a App Store oferece pra esta conta (0 se não tiver direito).
    var trialDays: Int {
        if demoPaywall { return LicenseManager.TRIAL_DAYS }
        guard trialEligible, let o = subProduct?.subscription?.introductoryOffer, o.paymentMode == .freeTrial else { return 0 }
        let n = o.period.value
        switch o.period.unit {
        case .day: return n
        case .week: return n * 7
        case .month: return n * 30
        case .year: return n * 365
        @unknown default: return n
        }
    }

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
            let ps = try await Product.products(for: [LicenseManager.SUB_ID])
            subProduct = ps.first { $0.id == LicenseManager.SUB_ID }
            if let s = subProduct?.subscription { trialEligible = await s.isEligibleForIntroOffer }
        } catch {
            // sem internet: a assinatura já feita continua valendo (o StoreKit guarda no aparelho)
        }
        await refresh()
    }

    /// Lê as transações assinadas pela Apple deste Apple ID.
    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-trialOffer") { status = .notStarted; return }
        if ProcessInfo.processInfo.arguments.contains("-demo") { status = .unlocked; return }
        #endif
        var active = false, inTrial = false, legacy = false
        var end: Date?
        for await r in Transaction.currentEntitlements {
            guard case .verified(let t) = r, t.revocationDate == nil else { continue }
            if t.productID == LicenseManager.LEGACY_FULL_ID { legacy = true }
            if t.productID == LicenseManager.SUB_ID, (t.expirationDate ?? .distantFuture) > Date() {
                active = true
                end = t.expirationDate
                if t.offerType == .introductory { inTrial = true }
            }
        }
        periodEnd = end
        if legacy || (active && !inTrial) { status = .unlocked; return }
        if active { status = .trial; return }
        // nunca assinou → boas-vindas com o teste grátis; já assinou → "sua assinatura terminou"
        let had = await Transaction.latest(for: LicenseManager.SUB_ID) != nil
        status = had ? .expired : .notStarted
    }

    /// Tempo usado, protegido contra voltar o relógio (vale a maior data já vista).
    nonisolated static func used(start: Date, now: Date, seen: Date?) -> TimeInterval {
        let ref = max(now, seen ?? now)
        return max(0, ref.timeIntervalSince(start))
    }

    /// Quanto falta do teste grátis: "1 dia e 5 h", "3 h", "20 min".
    var leftLabel: String {
        guard let e = periodEnd else { return tr("{0} dias", LicenseManager.TRIAL_DAYS) }
        return LicenseManager.leftText(max(0, e.timeIntervalSinceNow))
    }

    nonisolated static func leftText(_ left: TimeInterval) -> String {
        let h = Int(left / 3600)
        if h >= 24 {
            let dd = h / 24, hh = h % 24
            return tr("{0} dia", dd) + (dd > 1 ? "s" : "") + (hh > 0 ? " e \(hh) h" : "")
        }
        if h >= 1 { return "\(h) h" }
        return tr("{0} min", Int(left / 60))
    }

    // ---- ações ----
    func subscribe() async {
        guard let p = subProduct else {
            message = tr("Não consegui falar com a App Store agora. Confira a internet e tente de novo.")
            await load()
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await p.purchase() {
            case .success(let r):
                if case .verified(let t) = r { await t.finish(); message = tr("Assinatura ativa. Obrigado!") } else { message = tr("A compra não pôde ser verificada.") }
            case .pending: message = tr("Compra pendente (aguardando aprovação). O app libera sozinho quando for aprovada.")
            case .userCancelled: break
            @unknown default: break
            }
        } catch {
            message = tr("Não deu certo: {0}", error.localizedDescription)
        }
        await load()
    }

    func restore() async {
        busy = true
        defer { busy = false }
        do { try await AppStore.sync() } catch { message = tr("Não consegui falar com a App Store agora.") }
        await load()
        if status == .unlocked || status == .trial { message = tr("Assinatura restaurada.") }
        else { message = tr("Não encontrei assinatura ativa neste Apple ID.") }
    }
}
