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
        // igual ao app (MoveisWeb.makeUIView): o script que guarda e devolve as fotos e vídeos do editor nos arquivos
        let media = try XCTUnwrap(Bundle.main.url(forResource: "EditorMediaBackup", withExtension: "js"), "EditorMediaBackup.js tem que ir dentro do app")
        uc.addUserScript(WKUserScript(source: try String(contentsOf: media, encoding: .utf8), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
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
            // a volta das fotos pro IndexedDB é assíncrona e o simulador é lento: espera até 10 s (a conferência é a mesma: tem que voltar)
            let r = try await w.callAsyncJavaScript("var n=-1,t0=Date.now();while(Date.now()-t0<10000){n=await new Promise(function(res){try{phAll(function(L){res((L||[]).length)})}catch(e){res(-1)}});if(n>=quer)break;await new Promise(function(r){setTimeout(r,250)})}return JSON.stringify({n:n,ms:Date.now()-t0,idb:typeof indexedDB});", arguments: ["quer": fotosArq.count], in: nil, contentWorld: .page)
            let fo = (try? JSONSerialization.jsonObject(with: Data(((r as? String) ?? "{}").utf8))) as? [String: Any] ?? [:]
            print("ATUALIZACAO-ABRE: fotos da galeria nos arquivos \(fotosArq.count) · no editor \(fo["n"] ?? "?") · esperou \(fo["ms"] ?? "?") ms · indexedDB \(fo["idb"] ?? "?")")
            // diagnóstico (21/11): a volta não aconteceu no iOS em 10 s; mostra cada passo do caminho (ponte, banco, gravar à mão)
            if (fo["n"] as? NSNumber)?.intValue != fotosArq.count {
                let d = try await w.callAsyncJavaScript("""
                  var A=window.ArqueApp,o={};try{var L=JSON.parse(A.listFiles()||'[]');o.lista=L.filter(function(n){return /^photo_/.test(n)});var g=A.getFile(o.lista[0]||'');o.arquivo=g?g.length:0;var j=JSON.parse(decodeURIComponent(escape(atob(g))));o.id=j.id;o.temData=!!j.data}catch(e){o.erroArquivo=String(e)}
                  o.banco=await new Promise(function(r){try{phDB(function(db){r(db?'abriu':'nulo')})}catch(e){r('erro '+e)}});
                  try{o.antes=await new Promise(function(r){phAll(function(L){r((L||[]).length)})});var jj=JSON.parse(decodeURIComponent(escape(atob(A.getFile(o.lista[0])))));o.gravar=await new Promise(function(r){var t=setTimeout(function(){r('sem resposta')},4000);try{phPut(jj,function(){clearTimeout(t);r('ok')})}catch(e){r('erro '+e)}});o.depois=await new Promise(function(r){phAll(function(L){r((L||[]).length)})})}catch(e){o.erroGravar=String(e)}
                  return JSON.stringify(o);
                  """, arguments: [:], in: nil, contentWorld: .page)
                print("ATUALIZACAO-ABRE: diagnóstico da foto \(d ?? "?")")
            }
            XCTAssertEqual((fo["n"] as? NSNumber)?.intValue, fotosArq.count, "as fotos da galeria voltam no editor")
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

    /// Vídeo do cliente (N13; auditoria final 24/11): o vídeo que a versão PUBLICADA gravou pelo seletor (VideoGravarUITests, no
    /// teste de atualização) volta no editor da versão nova pelo caminho do app (video_<id>.json → EditorMediaBackup → banco do
    /// editor), igual byte a byte ao que ela gravou (ARQ_VIDEO_SHA, conferido pelo script no arquivo) e toca.
    @MainActor
    func testVideoGravadoPelaVersaoPublicadaVoltaIgualETocaNoEditorNovo() async throws {
        guard ProcessInfo.processInfo.environment["ARQ_VIDEO"] == "1" else { throw XCTSkip("só roda no teste de atualização do vídeo (ARQ_VIDEO=1)") }
        let esperado = ProcessInfo.processInfo.environment["ARQ_VIDEO_SHA"] ?? ""
        let dir = AppPaths.moveis
        let arqs = ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []).filter { $0.hasPrefix("video_") && $0.hasSuffix(".json") }
        XCTAssertEqual(arqs.count, 1, "o vídeo gravado pela versão publicada está nos arquivos do app")
        let cfg = WKWebViewConfiguration()
        // 25/11 (8ª rodada no CI): no armazenamento temporário (.nonPersistent) o WebKit não guarda Blob no IndexedDB, e o vídeo
        // restaurado do video_*.json não chegava ao banco do editor. O app usa armazenamento de verdade: aqui um novo e vazio.
        cfg.websiteDataStore = WKWebsiteDataStore(forIdentifier: UUID())
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.allowsInlineMediaPlayback = true
        cfg.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "arque")
        let uc = WKUserContentController()
        uc.addUserScript(WKUserScript(source: "window.__errs=[];window.addEventListener('error',function(e){__errs.push(String(e.message||e))});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        uc.addUserScript(WKUserScript(source: MoveisWeb.bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let media = try XCTUnwrap(Bundle.main.url(forResource: "EditorMediaBackup", withExtension: "js"), "EditorMediaBackup.js tem que ir dentro do app")
        uc.addUserScript(WKUserScript(source: try String(contentsOf: media, encoding: .utf8), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
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
        let r = try await w.callAsyncJavaScript(#"""
          var blobIDB=await new Promise(function(res){try{var q=indexedDB.open('teste-blob-'+Date.now(),1);q.onupgradeneeded=function(){q.result.createObjectStore('s')};q.onerror=function(){res('abrir: '+q.error)};q.onsuccess=function(){try{var tx=q.result.transaction('s','readwrite');tx.objectStore('s').put(new Blob(['abc'],{type:'video/mp4'}),'k');tx.oncomplete=function(){res('ok')};tx.onerror=function(){res('erro '+tx.error)};tx.onabort=function(){res('abortou '+tx.error)}}catch(e){res('exceção '+e)}}}catch(e){res('exceção '+e)}});
          var o=null,t0=Date.now();while(Date.now()-t0<20000){var L=await new Promise(function(res){try{phAll(function(X){res((X||[]).filter(function(q){return q.kind==='video'&&q.blob}))})}catch(e){res([])}});if(L.length){o=L[0];break}await new Promise(function(r){setTimeout(r,300)})}
          if(!o)return JSON.stringify({achou:false,ms:Date.now()-t0,blobIDB:blobIDB,arquivos:(function(){try{return ArqueApp.listFiles()}catch(e){return 'erro '+e}})(),errs:__errs.slice()});
          var buf=await o.blob.arrayBuffer();var h=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',buf))).map(function(b){return b.toString(16).padStart(2,'0')}).join('');
          var el=document.createElement('video');el.muted=true;el.playsInline=true;el.src=URL.createObjectURL(o.blob);document.body.appendChild(el);
          var toca=await new Promise(function(r){var t=setTimeout(function(){r('sem resposta em 20 s (pronto '+el.readyState+')')},20000);el.onerror=function(){clearTimeout(t);r('erro '+(el.error&&el.error.code))};
           el.oncanplay=function(){el.play().then(function(){setTimeout(function(){clearTimeout(t);r('tocou até '+el.currentTime.toFixed(2)+' s de '+el.duration.toFixed(2)+' s')},800)},function(e){clearTimeout(t);r('play recusado '+e)})};el.load()});
          el.remove();return JSON.stringify({achou:true,blobIDB:blobIDB,ms:Date.now()-t0,nome:o.nome,pid:o.pid,tipo:o.blob.type,tam:buf.byteLength,sha:h,toca:toca,errs:__errs.slice()});
          """#, arguments: [:], in: nil, contentWorld: .page)
        let o = try XCTUnwrap((try JSONSerialization.jsonObject(with: Data(((r as? String) ?? "{}").utf8))) as? [String: Any])
        print("ATUALIZACAO-VIDEO: \(o)")
        XCTAssertEqual(o["achou"] as? Bool, true, "o editor novo acha o vídeo")
        XCTAssertEqual(o["sha"] as? String, esperado, "o vídeo volta igual byte a byte ao que a versão publicada gravou")
        XCTAssertTrue(((o["toca"] as? String) ?? "").hasPrefix("tocou"), "o vídeo toca no editor novo: \(o["toca"] ?? "?")")
    }
}
