import XCTest
import StoreKit
import StoreKitTest
@testable import Arquemestre

/// Assinatura de verdade do app (LicenseManager) contra o StoreKit de teste do Xcode, usando o mesmo
/// arquivo Arquemestre.storekit (assinatura mensal R$ 29,90, oferta introdutória grátis de 3 dias).
/// Cobre: preço e teste antes da compra, teste só depois da confirmação, compra pendente (Ask to Buy),
/// renovação, cancelamento, expiração (dados preservados), reembolso, nova assinatura sem 2º teste e restaurar.
/// Obs.: isto é o ambiente local do Xcode (StoreKit Testing), não o Sandbox dos servidores da Apple.
@MainActor
final class SubscriptionTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        if let s = try? SKTestSession(configurationFileNamed: "Arquemestre") {
            session = s
        } else {
            let url = try XCTUnwrap(Bundle(for: SubscriptionTests.self).url(forResource: "Arquemestre", withExtension: "storekit"),
                                    "Arquemestre.storekit precisa estar no pacote de testes")
            session = try SKTestSession(contentsOf: url)
        }
        session.resetToDefaultState()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        session = nil
    }

    private final class Flag { var done = false }

    /// Roda uma chamada do StoreKit com prazo: se travar, o teste falha com o nome do passo (em vez de travar tudo).
    @discardableResult
    private func within(_ seconds: Double, _ what: String, _ op: @escaping @MainActor () async -> Void) async -> Bool {
        print("SKT: \(name) → \(what)")
        let f = Flag()
        Task { @MainActor in await op(); f.done = true }
        let deadline = Date().addingTimeInterval(seconds)
        while !f.done && Date() < deadline { try? await Task.sleep(nanoseconds: 200_000_000) }
        if !f.done { XCTFail("Travou (\(Int(seconds)) s): \(what)"); print("SKT: TRAVOU \(what)") }
        return f.done
    }

    private func fresh() async -> LicenseManager {
        let l = LicenseManager()
        await within(30, "carregar o produto da loja") { await l.load() }
        print("SKT: produto=\(l.subProduct?.id ?? "nil") preço=\(l.price) teste=\(l.trialDays) status=\(l.status)")
        return l
    }

    /// Compra pelo mesmo caminho do botão "Começar 3 dias grátis" (Product.purchase do app).
    private func buy(_ l: LicenseManager) async {
        let ok = await within(45, "comprar (Product.purchase)") { await l.subscribe() }
        if !ok {
            // registra a falha acima e segue com a compra pela sessão de teste, pra testar o resto do fluxo
            _ = try? session.buyProduct(productIdentifier: LicenseManager.SUB_ID)
            await within(30, "recarregar depois da compra") { await l.load() }
        }
        print("SKT: depois da compra status=\(l.status) fim=\(String(describing: l.periodEnd)) msg=\(l.message ?? "")")
    }

    /// Espera a App Store de teste processar (renovação, expiração e reembolso chegam um pouco depois).
    private final class Box { var ok = false }

    private func waitUntil(_ what: String, timeout: TimeInterval = 20, _ cond: @escaping @MainActor () async -> Bool) async {
        let t0 = Date()
        while Date().timeIntervalSince(t0) < timeout {
            let b = Box()
            await within(15, what) { b.ok = await cond() }
            if b.ok { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        XCTFail("Tempo esgotado esperando: \(what)")
    }

    private func lastTransactionId() throws -> UInt {
        let all = session.allTransactions().filter { $0.productIdentifier == LicenseManager.SUB_ID }
        return try XCTUnwrap(all.last, "sem transação da assinatura").identifier
    }

    func test00_DiagnosticoDaLojaDeTeste() async {
        print("SKT: storefront=\(session.storefront) locale=\(session.locale.identifier) bundle=\(Bundle.main.bundleIdentifier ?? "-")")
        do {
            let ps = try await Product.products(for: [LicenseManager.SUB_ID])
            print("SKT: Product.products → \(ps.map { "\($0.id) \($0.displayPrice)" })")
            XCTAssertEqual(ps.count, 1, "a loja de teste não devolveu o produto")
        } catch {
            print("SKT: Product.products erro → \(error)")
            XCTFail("Product.products falhou: \(error)")
        }
    }

    func test01_AntesDeAssinarMostraPrecoTesteENaoLibera() async {
        let l = await fresh()
        XCTAssertNotNil(l.subProduct, "produto arquemestre_mensal não carregou")
        XCTAssertTrue(l.price.contains("29,90"), "preço: \(l.price)")
        XCTAssertEqual(l.trialDays, 3)
        XCTAssertTrue(l.trialEligible)
        XCTAssertEqual(l.subProduct?.subscription?.subscriptionPeriod.unit, .month)
        XCTAssertEqual(l.subProduct?.subscription?.subscriptionPeriod.value, 1)
        XCTAssertEqual(l.status, .notStarted)
        XCTAssertFalse(l.hasAccess, "nada pode ficar liberado antes da Apple confirmar")
    }

    func test02_TesteGratisComecaSoDepoisDaConfirmacao() async throws {
        let l = await fresh()
        XCTAssertEqual(l.status, .notStarted)
        XCTAssertNil(l.periodEnd)
        await buy(l)
        XCTAssertEqual(l.status, .trial, l.message ?? "")
        XCTAssertTrue(l.hasAccess)
        let end = try XCTUnwrap(l.periodEnd)
        XCTAssertEqual(end.timeIntervalSinceNow / 86_400, 3, accuracy: 0.05, "o teste tem de durar 3 dias a partir da confirmação")
        XCTAssertTrue(l.willRenew)
        XCTAssertFalse(l.trialEligible, "depois de assinar, não tem 2º teste")
        XCTAssertEqual(l.trialDays, 0)
    }

    func test03_CompraPendenteNaoLibera() async {
        session.askToBuyEnabled = true
        let l = await fresh()
        await buy(l)
        XCTAssertEqual(l.status, .notStarted, "compra aguardando aprovação não libera o app")
        XCTAssertFalse(l.hasAccess)
        XCTAssertNotNil(l.message)
    }

    func test04_RenovacaoDepoisDoTesteViraAssinaturaPaga() async throws {
        let l = await fresh()
        await buy(l)
        XCTAssertEqual(l.status, .trial)
        try session.forceRenewalOfSubscription(productIdentifier: LicenseManager.SUB_ID)
        await waitUntil("renovação paga") { await l.refresh(); return l.status == .unlocked }
        XCTAssertTrue(l.hasAccess)
        let end = try XCTUnwrap(l.periodEnd)
        XCTAssertGreaterThan(end.timeIntervalSinceNow, 20 * 86_400, "período pago de 1 mês")
    }

    func test05_CancelarMantemAcessoAteOFimDoPeriodo() async throws {
        let l = await fresh()
        await buy(l)
        try session.disableAutoRenewForTransaction(identifier: try lastTransactionId())
        await waitUntil("renovação desligada") { await l.refresh(); return !l.willRenew }
        XCTAssertEqual(l.status, .trial, "cancelou: continua liberado até o fim do teste")
        XCTAssertTrue(l.hasAccess)
        XCTAssertNotNil(l.periodEnd)
    }

    func test06_ExpirarBloqueiaMasNaoApagaOsProjetos() async throws {
        // um projeto salvo antes (mesmo arquivo que o editor de móveis usa)
        let f = MoveisProjects.file
        let old = try? Data(contentsOf: f)
        defer { if let old { try? old.write(to: f) } else { try? FileManager.default.removeItem(at: f) } }
        try FileManager.default.createDirectory(at: f.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(#"[{"id":"p-teste","client":{"nome":"Cliente do teste"},"created":1,"updated":2,"current":{"mods":[1,2,3]}}]"#.utf8).write(to: f)

        let l = await fresh()
        await buy(l)
        XCTAssertTrue(l.hasAccess)
        try session.expireSubscription(productIdentifier: LicenseManager.SUB_ID)
        await waitUntil("assinatura expirada") { await l.refresh(); return l.status == .expired }
        XCTAssertFalse(l.hasAccess, "expirou: telas bloqueadas")
        let p = MoveisProjects.list().first { $0.id == "p-teste" }
        XCTAssertEqual(p?.name, "Cliente do teste", "o projeto continua salvo depois de expirar")
        XCTAssertEqual(p?.mods, 3)
    }

    func test07_AssinarDeNovoDepoisDeExpirarNaoTemSegundoTeste() async throws {
        let l = await fresh()
        await buy(l)
        try session.expireSubscription(productIdentifier: LicenseManager.SUB_ID)
        await waitUntil("assinatura expirada") { await l.refresh(); return l.status == .expired }
        await within(30, "recarregar") { await l.load() }
        XCTAssertEqual(l.trialDays, 0, "quem já usou o teste vê só o preço")
        await buy(l)
        XCTAssertEqual(l.status, .unlocked, "assinou de novo: liberado e pago, sem teste")
    }

    func test08_ReembolsoTiraOAcesso() async throws {
        let l = await fresh()
        await buy(l)
        try session.refundTransaction(identifier: try lastTransactionId())
        await waitUntil("acesso revogado") { await l.refresh(); return !l.hasAccess }
        XCTAssertEqual(l.status, .expired)
    }

    func test09_RestaurarEmOutraInstalacao() async {
        let a = await fresh()
        await buy(a)
        XCTAssertTrue(a.hasAccess)
        // app reinstalado ou outro aparelho com o mesmo Apple ID: o acesso vem da App Store, sem senha
        let b = await fresh()
        XCTAssertTrue(b.hasAccess)
        await within(45, "restaurar (AppStore.sync)") { await b.restore() }
        XCTAssertTrue(b.hasAccess)
        XCTAssertEqual(b.message, tr("Assinatura restaurada."))
    }

    func test10_RestaurarSemAssinaturaNaoLibera() async {
        let l = await fresh()
        await within(45, "restaurar (AppStore.sync)") { await l.restore() }
        XCTAssertFalse(l.hasAccess)
        XCTAssertEqual(l.status, .notStarted)
        XCTAssertEqual(l.message, tr("Não encontrei assinatura ativa neste Apple ID."))
    }
}
