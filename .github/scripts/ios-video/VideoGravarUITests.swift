import XCTest

/// Vídeo do cliente na atualização do iOS (N13; auditoria final 24/11). Este teste de interface é montado só dentro do teste de
/// atualização, em cima do código da versão PUBLICADA (o app não muda: o alvo de teste é acrescentado ao projeto só na compilação
/// do simulador). Ele usa o app como a pessoa: lista de clientes → "📷 Fotos e obra" → "Vídeos" → "🎥 Gravar / adicionar vídeo" →
/// menu do iOS → Fototeca → o vídeo que o script pôs no simulador (simctl addmedia). Quem grava é o próprio app publicado.
final class VideoGravarUITests: XCTestCase {
    private struct Falha: Error {}
    private var app: XCUIApplication!

    private func mostra(_ porque: String) {
        print("VIDEO-UI: \(porque)")
        let s = XCTAttachment(screenshot: XCUIScreen.main.screenshot()); s.name = porque; s.lifetime = .keepAlways; add(s)
        print("VIDEO-UI: árvore\n\(app.debugDescription.prefix(12000))")
    }

    /// primeiro elemento visível cujo rótulo é (ou contém) um dos textos
    private func acha(_ textos: [String], contem: Bool = false, em base: XCUIElement? = nil, ate: TimeInterval = 30) -> XCUIElement? {
        let raiz = base ?? app!
        let pred = textos.map { contem ? NSPredicate(format: "label CONTAINS[c] %@", $0) : NSPredicate(format: "label == %@", $0) }
        let q = raiz.descendants(matching: .any).matching(NSCompoundPredicate(orPredicateWithSubpredicates: pred))
        let fim = Date().addingTimeInterval(ate)
        repeat {
            for i in 0..<min(q.count, 12) { let e = q.element(boundBy: i); if e.exists && e.isHittable { return e } }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < fim
        return nil
    }

    private func toca(_ textos: [String], contem: Bool = false, ate: TimeInterval = 30) throws {
        guard let e = acha(textos, contem: contem, ate: ate) else { mostra("não achei \(textos)"); XCTFail("FALHA-VIDEO-UI: não achei \(textos)"); throw Falha() }
        print("VIDEO-UI: toquei \"\(e.label)\""); e.tap()
    }

    func testGravarVideoPeloEditorDaVersaoPublicada() throws {
        guard ProcessInfo.processInfo.environment["ARQ_VIDEO_UI"] == "1" else { throw XCTSkip("só no teste de atualização (ARQ_VIDEO_UI=1)") }
        app = XCUIApplication()
        // -arque.lang pt: textos do app e do editor em português (o simulador vem em inglês); -demo: pula a apresentação e a licença do primeiro uso (só em compilação de teste); -screen moveis: abre o editor de móveis
        app.launchArguments = ["-demo", "-screen", "moveis", "-arque.lang", "pt"]
        app.launch()
        // pedidos de permissão do sistema (fotos, notificações) que aparecerem no caminho
        addUIInterruptionMonitor(withDescription: "permissões") { a in
            for t in ["Permitir Acesso Total", "Allow Full Access", "Permitir", "Allow", "OK"] where a.buttons[t].exists { a.buttons[t].tap(); return true }
            return false
        }
        XCTAssertTrue(app.webViews.firstMatch.waitForExistence(timeout: 90), "o editor abriu")
        sleep(6)
        try toca(["Clientes e projetos"])
        sleep(2)
        try toca(["📷 Fotos e obra"])
        sleep(2)
        try toca(["Vídeos"])
        sleep(2)
        try toca(["🎥 Gravar / adicionar vídeo"], contem: true)
        sleep(3)
        // menu do iOS pro campo de arquivo (sem câmera no simulador): Fototeca / Photo Library
        try toca(["Fototeca", "Photo Library", "Biblioteca de Fotos", "Fotos", "Photos"], ate: 20)
        sleep(4)
        app.tap()  // dispara o monitor de permissão, se houver
        // a grade do seletor de fotos (fora da página): o vídeo de teste é o único item. Só imagem/célula do seletor — nunca a aba
        // "Vídeos" do editor, que continua por baixo (1ª rodada no CI tocou nela de novo)
        let pv = NSPredicate(format: "label CONTAINS[c] %@", "video")
        var alvo: XCUIElement? = nil
        let fim = Date().addingTimeInterval(30)
        repeat {
            for q in [app.images.matching(pv), app.cells.matching(pv), app.collectionViews.cells, app.scrollViews.images] {
                for i in 0..<min(q.count, 6) { let e = q.element(boundBy: i); if e.exists && e.isHittable && e.label != "Vídeos" && e.label != "Videos" { alvo = e; break } }
                if alvo != nil { break }
            }
            if alvo != nil { break }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < fim
        guard let v = alvo else { mostra("seletor de fotos sem o vídeo"); XCTFail("FALHA-VIDEO-UI: seletor de fotos sem o vídeo"); throw Falha() }
        print("VIDEO-UI: toquei no item do seletor \"\(v.label)\" (\(v.elementType.rawValue))"); v.tap()
        sleep(2)
        if let ok = acha(["Adicionar", "Add", "Escolher", "Choose", "Done", "OK"], ate: 6) { print("VIDEO-UI: toquei \"\(ok.label)\""); ok.tap() }
        // o editor avisa "1 vídeo(s) salvo(s) neste cliente."
        guard acha(["vídeo(s) salvo(s)"], contem: true, ate: 90) != nil else { mostra("o editor não avisou que salvou"); XCTFail("FALHA-VIDEO-UI: o editor não avisou que salvou o vídeo"); throw Falha() }
        print("VIDEO-UI: o editor da versão publicada salvou o vídeo")
        sleep(5)
        app.terminate()
    }
}
