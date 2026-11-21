import XCTest
import WebKit
import CryptoKit
@testable import Arquemestre

/// Atualização por cima no iOS (Adauto, 21/11: "Testar a abertura real dos projetos após atualização por cima no iOS").
/// Roda só dentro do teste de atualização (.github/scripts/teste_atualizacao_ios.sh liga ARQ_ATUALIZACAO=1): o app já foi
/// atualizado por cima da versão publicada com os dados do backup de referência. Aqui o editor abre do mesmo jeito do app
/// (arque://app, ponte ArqueApp) lendo os arquivos que a atualização deixou (AppPaths.moveis), abre cada projeto pelo caminho
/// do app (arqueOpenClient) e confere as medidas salvas, as peças, a foto do projeto e as notas com medida e foto.
/// Nada é gravado no aparelho: o que o editor mandar gravar fica só na memória (e o script confere os arquivos de novo depois).
final class AtualizacaoAbreProjetosTests: XCTestCase {
    private final class Host: NSObject, WKNavigationDelegate, WKUIDelegate {
        var ready: XCTestExpectation?
        var failed: String?
        let dir: URL
        var escritos: [String: Data] = [:]
        init(dir: URL) { self.dir = dir }
        private func safe(_ n: String) -> String { String(n.map { $0.isLetter || $0.isNumber || "_.-".contains($0) ? $0 : "_" }) }
        func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) { ready?.fulfill(); ready = nil }
        func webView(_ w: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed = error.localizedDescription; ready?.fulfill(); ready = nil }
        func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed = error.localizedDescription; ready?.fulfill(); ready = nil }
        /// a mesma ponte síncrona do MoveisWeb.Coord, lendo da pasta real; gravação vai pra memória
        func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            switch prompt {
            case "__arque__:listFiles":
                var names = Set((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
                escritos.keys.forEach { names.insert($0) }
                completionHandler(JsonCodec.string(Array(names)))
            case "__arque__:getFile":
                let n = safe(defaultText ?? "")
                completionHandler((escritos[n] ?? (try? Data(contentsOf: dir.appendingPathComponent(n))))?.base64EncodedString() ?? "")
            case "__arque__:putFile":
                if let d0 = (defaultText ?? "").data(using: .utf8), let o = (try? JSONSerialization.jsonObject(with: d0)) as? [String: Any],
                   let n = o["name"] as? String, let b = o["b64"] as? String, let d = Data(base64Encoded: b, options: .ignoreUnknownCharacters) {
                    escritos[safe(n)] = d; completionHandler("ok")
                } else { completionHandler("error") }
            case "__arque__:putVideo": completionHandler("ok")
            case "__arque__:listNotes": completionHandler("[]")
            case "__arque__:companyName": completionHandler("Marcenaria Teste")
            default: completionHandler(nil)
            }
        }
        func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
        func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) { completionHandler(true) }
    }
    private final class Sink: NSObject, WKScriptMessageHandler {
        weak var host: Host?
        func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let m = message.body as? [String: Any], let op = m["op"] as? String else { return }
            if op == "putFile", let n = m["name"] as? String, let b = m["b64"] as? String, let d = Data(base64Encoded: b, options: .ignoreUnknownCharacters) { host?.escritos[n] = d }
        }
    }
    private var hold: [AnyObject] = []

    private func sha(_ d: Data) -> String { SHA256.hash(data: d).map { String(format: "%02x", $0) }.joined() }

    @MainActor
    func testProjetosDaVersaoAnteriorAbremNoEditorComAsMesmasMedidasPecasFotosENotas() async throws {
        guard ProcessInfo.processInfo.environment["ARQ_ATUALIZACAO"] == "1" else { throw XCTSkip("só roda no teste de atualização por cima (ARQ_ATUALIZACAO=1)") }
        let dir = AppPaths.moveis
        let pjURL = dir.appendingPathComponent("projects.json")
        let pj = try Data(contentsOf: pjURL, options: [])
        let h0 = sha(pj)
        let lista = try XCTUnwrap((try JSONSerialization.jsonObject(with: pj)) as? [[String: Any]], "projects.json da atualização")
        XCTAssertGreaterThan(lista.count, 0, "a atualização deixou os projetos")

        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        cfg.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "arque")
        let uc = WKUserContentController()
        uc.addUserScript(WKUserScript(source: "window.__errs=[];window.addEventListener('error',function(e){__errs.push(String(e.message||e))});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        uc.addUserScript(WKUserScript(source: MoveisWeb.bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let host = Host(dir: dir), sink = Sink()
        sink.host = host
        uc.add(sink, name: "arque")
        cfg.userContentController = uc
        let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 430, height: 900), configuration: cfg)
        w.navigationDelegate = host
        w.uiDelegate = host
        if let win = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first { win.addSubview(w) }
        hold = [w, host, sink]
        let ready = expectation(description: "editor aberto pelo esquema do app")
        host.ready = ready
        w.load(URLRequest(url: try XCTUnwrap(URL(string: "arque://app/editor.html?lang=pt&cur=R%24&nosetup=1"))))
        await fulfillment(of: [ready], timeout: 90)
        XCTAssertNil(host.failed, "o editor não abriu: \(host.failed ?? "")")
        try await Task.sleep(nanoseconds: 3_000_000_000)

        for p in lista {
            let id = try XCTUnwrap(p["id"] as? String)
            let cur = (p["current"] as? [String: Any]) ?? [:]
            let mods = (cur["mods"] as? [[String: Any]]) ?? []
            let salvo = mods.map { m in ["x", "w", "h", "d", "b"].map { k in String(describing: (m[k] as? NSNumber)?.doubleValue ?? -1) }.joined(separator: "/") }.joined(separator: " ")
            let r = try await w.callAsyncJavaScript(#"""
              var ok=window.arqueOpenClient(id);await new Promise(function(r){setTimeout(r,800)});
              var dims=S.mods.map(function(m){return ['x','w','h','d','b'].map(function(k){return String(+m[k])}).join('/')}).join(' ');
              var pc=S.mods.map(function(m){SPC={};return partsOf(m).filter(function(q){return !q.noCut&&q.cl>0&&q.cw>0}).length}),cl=S.mods.map(function(m){return cutLines(m).length});
              var fotos=await new Promise(function(res){try{phAll(function(L){res((L||[]).filter(function(f){return f.pid===id}).length)})}catch(e){res(-1)}});
              return JSON.stringify({ok:ok,dims:dims,pecas:pc,corte:cl,fotos:fotos,errs:__errs.slice()});
              """#, arguments: ["id": id], in: nil, contentWorld: .page)
            let o = try XCTUnwrap((try JSONSerialization.jsonObject(with: Data(((r as? String) ?? "{}").utf8))) as? [String: Any])
            // os números do editor viram texto como "900" e os do arquivo como "900.0": compara pelo valor
            let dimsEd = ((o["dims"] as? String) ?? "").split(separator: " ").map { $0.split(separator: "/").map { String(describing: Double($0) ?? -2) }.joined(separator: "/") }.joined(separator: " ")
            let pecas = (o["pecas"] as? [Int]) ?? [], corte = (o["corte"] as? [Int]) ?? []
            print("ATUALIZACAO-ABRE: projeto \(id) · aberto \(o["ok"] ?? "?") · \(mods.count) módulos · medidas \(dimsEd == salvo ? "iguais" : "DIFERENTES (\(salvo) → \(dimsEd))") · peças \(pecas) · linhas do corte \(corte) · fotos \(o["fotos"] ?? "?") · erros \(o["errs"] ?? "?")")
            XCTAssertEqual(o["ok"] as? Bool, true, "projeto \(id) abriu pelo caminho do app")
            XCTAssertEqual(dimsEd, salvo, "projeto \(id): as medidas e posições abrem iguais às salvas")
            XCTAssertEqual(pecas.count, mods.count, "projeto \(id): todo módulo do arquivo está no editor")
            XCTAssertTrue(pecas.allSatisfy { $0 > 0 } && corte.allSatisfy { $0 > 0 }, "projeto \(id): todo módulo gera peças e plano de corte")
            XCTAssertEqual((o["errs"] as? [Any])?.count, 0, "projeto \(id): sem erro no editor")
        }
        // foto da galeria do editor que o backup traz (photo_f900.json, do projeto p1)
        let fotosArq = ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []).filter { $0.hasPrefix("photo_") }
        if !fotosArq.isEmpty {
            let r = try await w.callAsyncJavaScript("return await new Promise(function(res){try{phAll(function(L){res((L||[]).length)})}catch(e){res(-1)}});", arguments: [:], in: nil, contentWorld: .page)
            print("ATUALIZACAO-ABRE: fotos da galeria nos arquivos \(fotosArq.count) · no editor \(r ?? "?")")
            XCTAssertEqual((r as? NSNumber)?.intValue, fotosArq.count, "as fotos da galeria voltam no editor")
        }
        // notas (caderno) com medida e foto: abrem pelo Store do app e a foto existe com o mesmo tamanho
        let st = Store()
        let idx = st.loadIndex()
        for meta in idx.notes {
            let n = try XCTUnwrap(st.loadNote(meta.id), "nota \(meta.id) abre")
            var fotos: [String] = []
            for pg in n.pages { for ob in pg.objs { if case .photo(let ph) = ob { fotos.append(ph.file) } } }
            let existem = fotos.allSatisfy { FileManager.default.fileExists(atPath: st.imageFile($0).path) }
            print("ATUALIZACAO-ABRE: nota \(meta.id) · páginas \(n.pages.count) · medidas \(n.dimCount()) · fotos \(fotos) · arquivo da foto \(existem ? "existe" : "SUMIU")")
            XCTAssertGreaterThan(n.pages.count, 0, "nota \(meta.id) com página")
            XCTAssertEqual(n.dimCount(), meta.dimCount, "nota \(meta.id): as medidas abrem todas")
            XCTAssertTrue(existem, "nota \(meta.id): a foto continua no aparelho")
        }
        // abrir não muda nada: o arquivo no aparelho continua o mesmo e, se o editor mandou gravar a lista, as medidas são as mesmas
        XCTAssertEqual(sha(try Data(contentsOf: pjURL)), h0, "abrir os projetos não mexeu no projects.json do aparelho")
        if let novo = host.escritos["projects.json"], let l2 = (try? JSONSerialization.jsonObject(with: novo)) as? [[String: Any]] {
            let med = { (l: [[String: Any]]) -> String in l.map { p in (((p["current"] as? [String: Any])?["mods"] as? [[String: Any]]) ?? []).map { m in ["x", "w", "h", "d", "b"].map { k in String(describing: (m[k] as? NSNumber)?.doubleValue ?? -1) }.joined(separator: "/") }.joined(separator: " ") }.joined(separator: " | ") }
            print("ATUALIZACAO-ABRE: o editor pediu pra gravar a lista ao abrir · medidas \(med(l2) == med(lista) ? "iguais" : "DIFERENTES")")
            XCTAssertEqual(med(l2), med(lista), "se o editor regravar a lista ao abrir, as medidas são as mesmas")
        }
    }
}
