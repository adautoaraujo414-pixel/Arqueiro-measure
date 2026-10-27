import Foundation
import StoreKit

/// Assinatura no iPhone/iPad (App Review 3.1.1 e 3.1.2), só pela App Store:
///  • download grátis; o acesso é pela assinatura mensal com renovação automática [SUB_ID] (grupo "Arquemestre"), R$ 29,90/mês;
///  • teste grátis = oferta introdutória de 3 dias da própria assinatura, só pra quem nunca assinou.
///    O teste só começa quando a Apple confirma a assinatura (antes disso, nada fica liberado);
///  • restaurar compras e gerenciar/cancelar pela App Store; sem senha, sem compra única, sem pagamento por fora.
/// Sem login e sem servidor: o StoreKit 2 guarda e assina as transações (vale também sem internet).
/// Quando a assinatura acaba, as telas bloqueiam, mas nada dos dados é apagado (dá pra fazer backup e assinar de novo).
@MainActor
final class LicenseManager: ObservableObject {
    /// Único produto do app na App Store.
    static let SUB_ID = "arquemestre_mensal"
    /// Teste grátis configurado na oferta introdutória (o valor real vem da App Store).
    static let TRIAL_DAYS = 3
    static let TRIAL_SECONDS: TimeInterval = Double(TRIAL_DAYS) * 24 * 3600

    /// notStarted = nunca assinou · trial = no teste grátis · unlocked = assinatura paga ativa · expired = assinou e acabou
    enum Status: Equatable { case loading, notStarted, trial, expired, unlocked }

    @Published private(set) var status: Status = .loading
    @Published private(set) var subProduct: Product?
    /// Esta conta ainda tem direito ao teste grátis?
    @Published private(set) var trialEligible = true
    /// Fim do teste grátis (quando está no teste) ou do período pago atual.
    @Published private(set) var periodEnd: Date?
    /// A renovação automática continua ligada? (false = cancelou; o acesso vai até [periodEnd])
    @Published private(set) var willRenew = true
    /// Cobrança falhou e a Apple está dando o período de carência (o acesso continua).
    @Published private(set) var inGrace = false
    @Published var busy = false
    @Published var message: String?

    /// Liberado pra usar (teste grátis ou assinatura paga).
    var hasAccess: Bool { status == .trial || status == .unlocked }

    private var updates: Task<Void, Never>?
    private var expiryCheck: Task<Void, Never>?

    /// Capturas de tela automáticas (só no build de teste): mostra o preço e o teste como na loja.
    private var demoPaywall: Bool {
        #if DEBUG
        return subProduct == nil && ProcessInfo.processInfo.arguments.contains("-trialOffer")
        #else
        return false
        #endif
    }

    /// "R$ 29,90" (preço da App Store no país da conta); vazio enquanto a loja não respondeu.
    var price: String {
        if let p = subProduct { return p.displayPrice }
        return demoPaywall ? (I18n.shared.lang == "pt" ? "R$ 29,90" : "$5.99") : ""
    }

    /// Dias do teste grátis que a App Store oferece pra esta conta (0 se não tiver direito).
    var trialDays: Int {
        if demoPaywall { return LicenseManager.TRIAL_DAYS }
        guard trialEligible, let o = subProduct?.subscription?.introductoryOffer, o.paymentMode == .freeTrial else { return 0 }
        let n = o.period.value * max(1, o.periodCount)
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
        // renovações, cancelamentos, reembolsos e compras aprovadas depois (Ask to Buy) chegam por aqui
        updates = Task { [weak self] in
            for await r in Transaction.updates {
                if case .verified(let t) = r { await t.finish() }
                await self?.refresh()
            }
        }
        Task { await load() }
    }

    deinit { updates?.cancel(); expiryCheck?.cancel() }

    func load() async {
        do {
            let ps = try await Product.products(for: [LicenseManager.SUB_ID])
            if let p = ps.first(where: { $0.id == LicenseManager.SUB_ID }) { subProduct = p }
            if let s = subProduct?.subscription { trialEligible = await s.isEligibleForIntroOffer }
        } catch {
            // sem internet: a assinatura já feita continua valendo (o StoreKit guarda no aparelho)
        }
        await refresh()
    }

    /// Foi a oferta introdutória (teste grátis)?
    private static func isIntro(_ t: Transaction) -> Bool {
        if #available(iOS 17.2, *) { return t.offer?.type == .introductory }
        return t.offerType == .introductory
    }

    /// Lê as transações assinadas pela Apple deste Apple ID e decide o acesso.
    func refresh() async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-trialOffer") { status = .notStarted; return }
        if ProcessInfo.processInfo.arguments.contains("-demo") { status = .unlocked; return }
        #endif
        var active = false, inTrial = false, grace = false, renew = true
        var end: Date?
        // 1) direito atual guardado no aparelho (funciona sem internet)
        for await r in Transaction.currentEntitlements {
            guard case .verified(let t) = r, t.productID == LicenseManager.SUB_ID, t.revocationDate == nil else { continue }
            if let e = t.expirationDate, e <= Date() { continue }
            active = true
            end = t.expirationDate
            inTrial = LicenseManager.isIntro(t)
        }
        // 2) situação da assinatura na App Store: renovação ligada/desligada e período de carência
        if let statuses = try? await subProduct?.subscription?.status {
            for st in statuses {
                guard case .verified(let tx) = st.transaction, tx.productID == LicenseManager.SUB_ID else { continue }
                if case .verified(let info) = st.renewalInfo { renew = info.willAutoRenew }
                switch st.state {
                case .subscribed:
                    if tx.revocationDate == nil, (tx.expirationDate ?? .distantFuture) > Date() {
                        active = true; end = tx.expirationDate; inTrial = LicenseManager.isIntro(tx)
                    }
                case .inGracePeriod:
                    if tx.revocationDate == nil {
                        active = true; grace = true
                        if case .verified(let info) = st.renewalInfo, let g = info.gracePeriodExpirationDate { end = g }
                    }
                default: break
                }
            }
        }
        periodEnd = active ? end : nil
        willRenew = renew
        inGrace = grace
        scheduleExpiryCheck(active ? end : nil)
        if active { status = inTrial ? .trial : .unlocked; return }
        // nunca assinou → tela da assinatura com o teste grátis; já assinou → "sua assinatura terminou"
        let had = await Transaction.latest(for: LicenseManager.SUB_ID) != nil
        status = had ? .expired : .notStarted
    }

    /// Com o app aberto, confere de novo na hora que o período acaba (a renovação chega por Transaction.updates).
    private func scheduleExpiryCheck(_ end: Date?) {
        expiryCheck?.cancel()
        guard let end else { return }
        let wait = end.timeIntervalSinceNow + 2
        guard wait > 0, wait < 40 * 24 * 3600 else { return }
        expiryCheck = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            if Task.isCancelled { return }
            await self?.refresh()
        }
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

    /// Data do fim do período atual, no formato do idioma.
    var periodEndText: String {
        guard let e = periodEnd else { return "" }
        return I18n.shared.dateFormatter(.date).string(from: e)
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

    /// Abre a compra da Apple. O acesso (e o teste grátis) só libera depois que a Apple confirma.
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

    /// "Já assino": busca as compras deste Apple ID na App Store (outro aparelho, reinstalação).
    func restore() async {
        busy = true
        defer { busy = false }
        do { try await AppStore.sync() } catch { message = tr("Não consegui falar com a App Store agora.") }
        await load()
        if hasAccess { message = tr("Assinatura restaurada.") }
        else { message = tr("Não encontrei assinatura ativa neste Apple ID.") }
    }
}
