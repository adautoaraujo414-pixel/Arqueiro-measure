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
        let url = try XCTUnwrap(Bundle(for: SubscriptionTests.self).url(forResource: "Arquemestre", withExtension: "storekit"),
                                "Arquemestre.storekit precisa estar no pacote de testes")
        session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.askToBuyEnabled = false
        session.clearTransactions()
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        session = nil
    }

    private func fresh() async -> LicenseManager {
        let l = LicenseManager()
        await l.load()
        return l
    }

    /// Espera a App Store de teste processar (renovação, expiração e reembolso chegam um pouco depois).
    private func waitUntil(_ what: String, timeout: TimeInterval = 20, _ cond: () async -> Bool) async {
        let t0 = Date()
        while Date().timeIntervalSince(t0) < timeout {
            if await cond() { return }
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
        XCTFail("Tempo esgotado esperando: \(what)")
    }

    private func lastTransactionId() throws -> UInt {
        let all = session.allTransactions().filter { $0.productIdentifier == LicenseManager.SUB_ID }
        return try XCTUnwrap(all.last, "sem transação da assinatura").identifier
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
        await l.subscribe()
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
        await l.subscribe()
        XCTAssertEqual(l.status, .notStarted, "compra aguardando aprovação não libera o app")
        XCTAssertFalse(l.hasAccess)
        XCTAssertNotNil(l.message)
    }

    func test04_RenovacaoDepoisDoTesteViraAssinaturaPaga() async throws {
        let l = await fresh()
        await l.subscribe()
        XCTAssertEqual(l.status, .trial)
        try session.forceRenewalOfSubscription(productIdentifier: LicenseManager.SUB_ID)
        await waitUntil("renovação paga") { await l.refresh(); return l.status == .unlocked }
        XCTAssertTrue(l.hasAccess)
        let end = try XCTUnwrap(l.periodEnd)
        XCTAssertGreaterThan(end.timeIntervalSinceNow, 20 * 86_400, "período pago de 1 mês")
    }

    func test05_CancelarMantemAcessoAteOFimDoPeriodo() async throws {
        let l = await fresh()
        await l.subscribe()
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
        await l.subscribe()
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
        await l.subscribe()
        try session.expireSubscription(productIdentifier: LicenseManager.SUB_ID)
        await waitUntil("assinatura expirada") { await l.refresh(); return l.status == .expired }
        await l.load()
        XCTAssertEqual(l.trialDays, 0, "quem já usou o teste vê só o preço")
        await l.subscribe()
        XCTAssertEqual(l.status, .unlocked, "assinou de novo: liberado e pago, sem teste")
    }

    func test08_ReembolsoTiraOAcesso() async throws {
        let l = await fresh()
        await l.subscribe()
        try session.refundTransaction(identifier: try lastTransactionId())
        await waitUntil("acesso revogado") { await l.refresh(); return !l.hasAccess }
        XCTAssertEqual(l.status, .expired)
    }

    func test09_RestaurarEmOutraInstalacao() async {
        let a = await fresh()
        await a.subscribe()
        XCTAssertTrue(a.hasAccess)
        // app reinstalado ou outro aparelho com o mesmo Apple ID: o acesso vem da App Store, sem senha
        let b = await fresh()
        XCTAssertTrue(b.hasAccess)
        await b.restore()
        XCTAssertTrue(b.hasAccess)
        XCTAssertEqual(b.message, tr("Assinatura restaurada."))
    }

    func test10_RestaurarSemAssinaturaNaoLibera() async {
        let l = await fresh()
        await l.restore()
        XCTAssertFalse(l.hasAccess)
        XCTAssertEqual(l.status, .notStarted)
        XCTAssertEqual(l.message, tr("Não encontrei assinatura ativa neste Apple ID."))
    }
}
