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
        var rolou = 0
        repeat {
            // 8ª rodada no iPad: isHittable num elemento sem área dá erro do XCTest ("Activation point invalid"); só pergunta a quem tem área
            // 25/11 (run 31): nem a quem está fora da janela (rolado pra cima): o mesmo erro; esse vai pra rolagem abaixo
            let janela = app.windows.firstMatch.frame
            for i in 0..<min(q.count, 12) { let e = q.element(boundBy: i); if e.exists && !e.frame.isEmpty && e.frame.width > 1 && janela.contains(CGPoint(x: e.frame.midX, y: e.frame.midY)) { return e } }  // run 32: isHittable falha nesse elemento do WebKit mesmo dentro da janela; decide pela posição
            // existe mas está fora da tela (iPhone: a lista de clientes passa da altura): rola a página e tenta de novo
            // 25/11 (run 30): a página pode estar rolada pra baixo, com o botão ACIMA da tela; rola na direção em que ele está
            if q.count > 0 && rolou < 6 && base == nil {
                let y = q.element(boundBy: 0).frame.minY, wv = app.webViews.firstMatch
                if y < wv.frame.minY { wv.swipeDown(velocity: .slow) } else { wv.swipeUp(velocity: .slow) }
                rolou += 1; continue
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < fim
        return nil
    }

    private func toca(_ textos: [String], contem: Bool = false, ate: TimeInterval = 30) throws {
        guard let e = acha(textos, contem: contem, ate: ate) else { mostra("não achei \(textos)"); XCTFail("FALHA-VIDEO-UI: não achei \(textos)"); throw Falha() }
        print("VIDEO-UI: toquei \"\(e.label)\""); e.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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
        // 25/11 (run 29): no iPhone frio do runner o editor da versão PUBLICADA (3.0.13, que não muda) levou mais de 30 s pra
        // aparecer; aqui só se espera ele ficar pronto — a velocidade de abertura do app é medida no iOS CI (limite de 20 s, intocado)
        try toca(["Clientes e projetos"], ate: 120)
        sleep(2)
        try toca(["📷 Fotos e obra"])
        sleep(2)
        try toca(["Vídeos"])
        sleep(2)
        // botões da página do editor (pra nunca tocar neles achando que são do seletor), lidos com a página parada
        let daPagina = Set(app.webViews.firstMatch.buttons.allElementsBoundByIndex.map { $0.label })
        try toca(["🎥 Gravar / adicionar vídeo"], contem: true)
        sleep(3)
        // menu do iOS pro campo de arquivo (sem câmera no simulador): Fototeca / Photo Library
        let menu = ["Fototeca", "Photo Library", "Biblioteca de Fotos", "Fotos", "Photos"]
        if acha(menu, ate: 15) == nil {
            // 5ª rodada no iPad: o botão fica no pé da tela e o menu não abriu no 1º toque; toca de novo
            print("VIDEO-UI: menu não abriu, toco de novo no botão")
            try toca(["🎥 Gravar / adicionar vídeo"], contem: true); sleep(3)
        }
        try toca(menu, ate: 20)
        sleep(4)
        // 4ª rodada: sem o app.tap() no meio da tela — no iPad o seletor é um balão e o toque fora dele fecha o seletor antes da
        // escolha (a permissão de fotos já vem do simctl privacy). Como está a tela com o seletor aberto:
        mostra("seletor aberto")
        // a grade do seletor de fotos (fora da página): o vídeo de teste é o único item. Só imagem/célula do seletor — nunca a aba
        // "Vídeos" do editor, que continua por baixo (1ª rodada no CI tocou nela de novo)
        // 5ª rodada: no iOS 26 o seletor abre antes uma apresentação de primeiro uso (ícone "PickerOnboardingHeaderViewIcon",
        // 38×38) — a 4ª rodada tocou nesse ícone. Passa pela apresentação pelo botão dela e só toca numa miniatura de verdade.
        let pv = NSPredicate(format: "label CONTAINS[c] %@", "video")
        // 7ª rodada: a apresentação é o aviso "Location Is Included · Learn More…" por cima da grade, e fecha no "Close"
        // (a miniatura "Video, two seconds…" já estava lá, mas sem toque por baixo do aviso). "Close" não existe na página (lá é "Fechar").
        let segue = ["Close", "Fechar aviso", "Continue", "Continuar", "Get Started", "Começar", "Next", "Seguinte", "Avançar"]
        // botão da apresentação: só botão, sem rolar a página do editor (rolar fecharia o seletor)
        // 6ª rodada: nenhum botão com esses nomes apareceu em 60 s; vale também quem CONTÉM "Continu"/"Get Started"/"Começar",
        // e só fora da página do editor (botões do seletor, que é outro processo)
        // 11ª rodada (iOS-atualização 37, 26/11): os botões da página são lidos antes de abrir o seletor (acima). Com o seletor aberto, no
        // iPad, listar os botões da página passava do tempo da consulta do XCUITest (176 s) e o teste caía antes de escolher o vídeo.
        func botaoSegue() -> XCUIElement? {
            let ps = segue.map { NSPredicate(format: "label == %@", $0) } + ["Continu", "Get Started", "Começar"].map { NSPredicate(format: "label CONTAINS[c] %@", $0) }
            let q = app.buttons.matching(NSCompoundPredicate(orPredicateWithSubpredicates: ps))
            for i in 0..<min(q.count, 6) { let e = q.element(boundBy: i); if e.exists && e.frame.width > 1 && e.isHittable && !daPagina.contains(e.label) { return e } }
            return nil
        }
        var mostrouSeletor = false
        var tentAlbum = 0
        var proxAlbum = Date()
        var fimAlbum = Date().addingTimeInterval(3600)
        var alvo: XCUIElement? = nil
        var passos = 0
        // 10ª rodada: cada volta de busca no seletor (outro processo) leva vários segundos; 60 s não bastavam no iPad
        let fim = Date().addingTimeInterval(120)
        repeat {
            for q in [app.images.matching(pv), app.cells.matching(pv), app.collectionViews.cells, app.scrollViews.images] {
                for i in 0..<min(q.count, 12) {
                    let e = q.element(boundBy: i)
                    guard e.exists && e.frame.width > 1 && e.isHittable else { continue }
                    if e.label == "Vídeos" || e.label == "Videos" || e.identifier.contains("Onboarding") || e.frame.width < 60 || e.frame.height < 60 { continue }
                    alvo = e; break
                }
                if alvo != nil { break }
            }
            if alvo != nil { break }
            // 8ª rodada: depois do Close a miniatura "Video, two seconds…" existe com tamanho certo, mas o iOS a dá como não
            // tocável (é do seletor, outro processo). Depois de passar pela apresentação, vale ela mesma, tocada pela posição.
            if passos > 0 {
                let qv = app.images.matching(pv)
                for i in 0..<min(qv.count, 6) { let e = qv.element(boundBy: i); if e.exists && !e.identifier.contains("Onboarding") && e.frame.width >= 60 && e.frame.height >= 60 && e.label != "Vídeos" && e.label != "Videos" { alvo = e; break } }
                if alvo != nil { break }
            }
            // 9ª rodada no iPad: depois do Close o seletor mostra os álbuns (miniaturas sem nome), não a grade; abre o álbum
            // "Videos" do seletor (o da página é "Vídeos", com acento, e fica de fora)
            if passos > 0 && tentAlbum < 3 && Date() > proxAlbum && (Date() > fimAlbum || app.images.matching(pv).count == 0) {  // 10ª: sem esperar, se não há miniatura de vídeo
                // 11ª (run 30): o álbum pode ter outro rótulo ("Videos, 1 item", célula); vale o que COMEÇA com "Videos", fora da página; até 3 vezes
                tentAlbum += 1; proxAlbum = Date().addingTimeInterval(15)
                let qa = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Videos"))
                print("VIDEO-UI: álbum, tentativa \(tentAlbum): " + qa.allElementsBoundByIndex.prefix(10).map { "\($0.label) (\($0.elementType.rawValue)) \($0.frame)" }.joined(separator: " | "))
                for i in 0..<min(qa.count, 10) {
                    let e = qa.element(boundBy: i)
                    if e.exists && e.frame.width > 1 && !daPagina.contains(e.label) {
                        print("VIDEO-UI: abri o álbum \"\(e.label)\" do seletor (\(e.elementType.rawValue)) em \(e.frame)")
                        if e.isHittable { e.tap() } else { e.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
                        sleep(3); break
                    }
                }
                continue
            }
            if passos < 3, let b = botaoSegue() {
                print("VIDEO-UI: apresentação do seletor, toquei \"\(b.label)\" (\(b.identifier))"); b.tap(); passos += 1; sleep(2); fimAlbum = Date().addingTimeInterval(8); continue
            }
            let mv = app.images.matching(pv).firstMatch
            if passos == 0 && mv.exists && !mv.isHittable { print("VIDEO-UI: a miniatura do vídeo está no seletor mas coberta: \(mv.label)") }
            if !mostrouSeletor {
                mostrouSeletor = true
                print("VIDEO-UI: no seletor (fora da página): botões " + app.buttons.allElementsBoundByIndex.filter { !daPagina.contains($0.label) }.prefix(30).map { "\($0.label)/\($0.identifier)" }.joined(separator: ", ")
                      + " · textos " + app.staticTexts.allElementsBoundByIndex.filter { $0.frame.minY >= 0 }.suffix(20).map { $0.label }.joined(separator: " | "))
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.5))
        } while Date() < fim
        print("VIDEO-UI: no seletor: botões " + app.buttons.allElementsBoundByIndex.prefix(60).map { $0.label + "/" + $0.identifier }.filter { $0 != "/" }.joined(separator: ", "))
        print("VIDEO-UI: no seletor: imagens " + app.images.allElementsBoundByIndex.prefix(20).map { "\($0.label)/\($0.identifier) \($0.frame.size)" }.joined(separator: ", "))
        guard let v = alvo else { mostra("seletor de fotos sem o vídeo"); XCTFail("FALHA-VIDEO-UI: seletor de fotos sem o vídeo"); throw Falha() }
        print("VIDEO-UI: toquei no item do seletor \"\(v.label)\" (\(v.elementType.rawValue)) em \(v.frame), tocável \(v.isHittable)")
        if v.isHittable { v.tap() } else { v.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
        sleep(3)
        mostra("depois de tocar no vídeo do seletor")
        // diagnóstico (2ª rodada no CI: depois do item apareceu um "OK" e o editor não salvou): o que há na tela agora
        for al in app.alerts.allElementsBoundByIndex { print("VIDEO-UI: alerta \"\(al.label)\" · " + al.staticTexts.allElementsBoundByIndex.map { $0.label }.joined(separator: " | ") + " · botões " + al.buttons.allElementsBoundByIndex.map { $0.label }.joined(separator: ", ")) }
        print("VIDEO-UI: botões na tela: " + app.buttons.allElementsBoundByIndex.prefix(40).map { $0.label }.filter { !$0.isEmpty }.joined(separator: ", "))
        if let ok = acha(["Adicionar", "Add", "Escolher", "Choose", "Done", "Concluído"], ate: 6) { print("VIDEO-UI: toquei \"\(ok.label)\""); ok.tap() }
        sleep(4)
        // diagnóstico (3ª rodada no iPad: o seletor fechou e o editor não avisou): os textos da página sobre vídeo/backup agora
        let tv = NSPredicate(format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@", "víde", "backup", "salv")
        print("VIDEO-UI: textos: " + app.staticTexts.matching(tv).allElementsBoundByIndex.prefix(12).map { $0.label }.joined(separator: " | "))
        print("VIDEO-UI: vídeos na página: \(app.webViews.firstMatch.descendants(matching: .any).matching(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.other.rawValue)).matching(NSPredicate(format: "label CONTAINS[c] %@", "video")).count)")
        // o editor avisa "1 vídeo(s) salvo(s) neste cliente."
        guard acha(["vídeo(s) salvo(s)"], contem: true, ate: 90) != nil else { mostra("o editor não avisou que salvou"); XCTFail("FALHA-VIDEO-UI: o editor não avisou que salvou o vídeo"); throw Falha() }
        print("VIDEO-UI: o editor da versão publicada salvou o vídeo")
        sleep(5)
        app.terminate()
    }
}
