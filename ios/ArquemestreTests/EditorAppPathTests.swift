import XCTest
import WebKit
@testable import Arquemestre

/// O editor de móveis aberto do MESMO jeito que o app abre (origem arque://app, ponte ArqueApp, script de vídeos):
/// confere que a tela carrega (não fica branca), em português, inglês e espanhol, e passa por tudo sem erro.
/// Roda no simulador do CI (não é um iPhone de verdade).
final class EditorAppPathTests: XCTestCase {
    /// Responde a ponte síncrona do editor (window.prompt) como o app, com tudo em memória.
    private final class Host: NSObject, WKNavigationDelegate, WKUIDelegate {
        var ready: XCTestExpectation?
        var failed: String?
        var files: [String: String] = [:]
        func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) { ready?.fulfill(); ready = nil }
        func webView(_ w: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed = error.localizedDescription; ready?.fulfill(); ready = nil }
        func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed = error.localizedDescription; ready?.fulfill(); ready = nil }
        func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            switch prompt {
            case "__arque__:listFiles": completionHandler(JsonCodec.string(Array(files.keys)))
            case "__arque__:getFile": completionHandler(files[defaultText ?? ""] ?? "")
            case "__arque__:listNotes": completionHandler("[]")
            case "__arque__:companyName": completionHandler("Marcenaria Teste")
            case "__arque__:putVideo": completionHandler("ok")
            default: completionHandler("")
            }
        }
        func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
        func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) { completionHandler(true) }
    }
    private final class Sink: NSObject, WKScriptMessageHandler {
        var host: Host?
        func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let m = message.body as? [String: Any], let op = m["op"] as? String else { return }
            if op == "putFile", let n = m["name"] as? String, let b = m["b64"] as? String { host?.files[n] = b }
        }
    }

    private var hold: [WKWebView] = []
    private var hosts: [Host] = []
    private var sinks: [Sink] = []

    override func tearDown() async throws {
        await MainActor.run { hold.forEach { $0.removeFromSuperview() }; hold = []; hosts = []; sinks = [] }
        try await super.tearDown()
    }

    /// Igual ao MoveisWeb.makeUIView: esquema arque://, ponte ArqueApp e o script dos vídeos.
    @MainActor
    private func openLikeTheApp(lang: String) async throws -> (WKWebView, TimeInterval) {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        cfg.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "arque")
        let uc = WKUserContentController()
        uc.addUserScript(WKUserScript(source: "window.__errs=[];window.addEventListener('error',function(e){__errs.push(String(e.message||e)+' @'+(e.lineno||''))});window.addEventListener('unhandledrejection',function(e){__errs.push('promise: '+String(e.reason))});", injectionTime: .atDocumentStart, forMainFrameOnly: true))
        uc.addUserScript(WKUserScript(source: MoveisWeb.bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let media = try XCTUnwrap(Bundle.main.url(forResource: "EditorMediaBackup", withExtension: "js"), "EditorMediaBackup.js tem que ir dentro do app")
        uc.addUserScript(WKUserScript(source: try String(contentsOf: media, encoding: .utf8), injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let host = Host(), sink = Sink()
        sink.host = host
        uc.add(sink, name: "arque")
        cfg.userContentController = uc
        let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 430, height: 900), configuration: cfg)
        w.navigationDelegate = host
        w.uiDelegate = host
        if let win = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first { win.addSubview(w) }
        hold.append(w); hosts.append(host); sinks.append(sink)
        let ready = expectation(description: "editor aberto pelo esquema do app")
        host.ready = ready
        let t0 = Date()
        w.load(URLRequest(url: try XCTUnwrap(URL(string: "arque://app/editor.html?lang=\(lang)&cur=R%24&nosetup=1"))))
        await fulfillment(of: [ready], timeout: 60)
        XCTAssertNil(host.failed, "o editor não abriu: \(host.failed ?? "")")
        let dt = Date().timeIntervalSince(t0)
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return (w, dt)
    }

    @MainActor
    private func run(_ w: WKWebView, _ js: String) async throws -> [String: Any] {
        let r = try await w.callAsyncJavaScript(js, arguments: [:], in: nil, contentWorld: .page)
        let s = try XCTUnwrap(r as? String, "o JS tem que devolver um JSON")
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(s.utf8)) as? [String: Any])
    }

    /// A tela do editor de móveis carrega de verdade pelo caminho do app (não fica branca) e rápido.
    @MainActor
    func testEditorAbreComoNoAppSemTelaBranca() async throws {
        let (w, dt) = try await openLikeTheApp(lang: "pt")
        let o = try await run(w, #"""
          var vis=Array.prototype.filter.call(document.querySelectorAll('button'),function(b){var r=b.getBoundingClientRect();return r.width>0&&r.height>0}).length;
          return JSON.stringify({vis:vis,txt:(document.body.innerText||'').length,app:!!(window.ArqueApp&&ArqueApp.isApp()),s:typeof S,svg:document.querySelectorAll('svg').length,errs:__errs});
          """#)
        XCTAssertLessThan(dt, 20, "o editor tem que abrir em menos de 20 s (abriu em \(dt) s)")
        XCTAssertGreaterThan(o["vis"] as? Int ?? 0, 15, "botões do editor aparecendo na tela")
        XCTAssertGreaterThan(o["txt"] as? Int ?? 0, 200, "texto do editor na tela")
        XCTAssertEqual(o["s"] as? String, "object", "editor iniciou")
        XCTAssertEqual(o["app"] as? Bool, true, "ponte do app ligada")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "erros: \(o["errs"] ?? "")")
    }

    /// Texturas reais dos padrões (cores/<id>.jpg) vêm do pacote do app pelo esquema arque:// e entram no WebGL:
    /// porta em Louro Freijó (Arauco Trend) fica com a textura (t=7), e a chapa do plano de corte sai com o nome da cor
    @MainActor
    func testTexturaRealDoPadraoCarregaPeloEsquemaDoApp() async throws {
        let (w, _) = try await openLikeTheApp(lang: "pt")
        let o = try await run(w, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;newTpl(3);var m=S.mods[0];m.tl=m.tr=true;m.tlW=30;m.trW=30;m.tlM=m.trM=1;
          var lf=MAT.filter(function(c){return c.id==='arauco-louro-freijo-trend'})[0];m.corF=lf.hex;m.corFN=matLabel(lf);m.corFId=lf.id;S.m=m;draw();open3D();
          var img=await new Promise(function(r){var im=new Image();im.onload=function(){r(im.naturalWidth+'x'+im.naturalHeight)};im.onerror=function(){r('erro')};im.src=matImg(lf.id)});
          await new Promise(function(r){var t0=Date.now();(function w(){var st=__mtex().join(',');if(/ok/.test(st)||/err/.test(st)||Date.now()-t0>15000)r();else setTimeout(w,100)})()});
          re3();var B=__boxes(),tx=B.filter(function(b){return /^0:Porta$/.test(String(b.nm))&&(b.x1-b.x0)>300&&!b.nol}).map(function(b){return __matTx(b)}).join(',');
          var pl=sheetPlan().groups.filter(function(g){return g.t==='c'}).map(function(g){return g.colN});
          return JSON.stringify({img:img,mtex:__mtex().join(','),tx:tx,pl:pl,n:MAT.length,errs:__errs});
          """#)
        XCTAssertEqual(o["img"] as? String, "512x1024", "textura cores/arauco-louro-freijo-trend.jpg servida pelo app (512×1024, veio na vertical)")
        XCTAssertEqual(o["mtex"] as? String, "arauco-louro-freijo-trend:ok", "textura entrou no WebGL")
        XCTAssertEqual(o["tx"] as? String, "7,7", "portas desenhadas com a foto do padrão")
        XCTAssertEqual(o["pl"] as? [String], ["Louro Freijó · Arauco Trend"], "chapa do plano com o nome da cor")
        XCTAssertEqual(o["n"] as? Int, 60, "60 padrões reais no catálogo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "erros: \(o["errs"] ?? "")")
    }

    /// Em inglês e espanhol o editor também abre e traduz (a tradução vem do próprio app, pelo esquema arque://).
    @MainActor
    func testEditorEmInglesEEspanhol() async throws {
        for (lang, word) in [("en", "Furniture Editor"), ("es", "Editor de Muebles")] {
            let (w, _) = try await openLikeTheApp(lang: lang)
            try await Task.sleep(nanoseconds: 1_000_000_000)
            let o = try await run(w, #"""
              return JSON.stringify({t:document.body.innerText||'',pt:/Fechar|Ajustes|Orçamento/.test(document.body.innerText||''),errs:__errs});
              """#)
            let t = o["t"] as? String ?? ""
            XCTAssertTrue(t.contains(word), "\(lang): editor traduzido (\(t.prefix(80)))")
            XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(lang): erros \(o["errs"] ?? "")")
        }
    }

    /// Passa por tudo do editor de móveis no WebKit do iOS, pelo caminho do app: todas as abas da cozinha
    /// (módulos, cubas, cooktops, fornos, coifas, geladeiras, tanques, torneiras), plano de corte, orçamento,
    /// 3D com setinhas, paredes, caixa e LED, ilha, dormitório, sala, banho, escritório, guia, salvar e abrir.
    @MainActor
    func testTudoNoEditorSemErro() async throws {
        let (w, _) = try await openLikeTheApp(lang: "pt")
        let o = try await run(w, #"""
          var R={};var step=function(n,f){try{f()}catch(e){__errs.push(n+': '+(e&&e.message||e))}};var cat=function(id){return CATS.filter(function(x){return x.id===id})[0]||{it:[]}};
          window.MINI3OFF=1;PR.setupDone=1;
          step('cozinha',function(){S.room='cozinha';S.env='cozinha';S.mods=[];draw();panel();
           ['inf','sup','canto','alto','csob','ccoz','ccook','cforno','ccoifa','cgel','ctanq','cacc'].forEach(function(id){catOpen(id);var c=cat(id);R['cat_'+id]=document.querySelectorAll('#catb [data-cati]').length;(c.it||[]).forEach(function(it){if(it.act==='ap')apAdd(it.ap,it.mi);else if(it.act==='cuba'||it.act==='cook')catAct2(it);else if(!it.act&&it.w&&S.mods.length<40)newTpl(it)});document.getElementById('catm').hidden=true});
           draw();panel();R.cozinha=[S.mods.length,S.fr.length,(S.st&&S.st.items||[]).length]});
          step('abas',function(){for(var t=0;t<12;t++){S.tab=t;try{panel()}catch(e){__errs.push('aba '+t+': '+e.message)}}S.tab=0;panel()});
          step('corte',function(){openCut();var b=budget();R.rows=b.rows.length;R.q=quoteData().items.length;var cm=document.getElementById('cutm');if(cm)cm.hidden=true});
          step('3d',function(){window.open3D();var a=window.ah3api;R.setas=0;S.fr.slice(0,12).forEach(function(f){fx3api.open({k:'fr',id:f.id});R.setas+=a.specs().length});
           fx3api.open({k:'st',id:S.st.id});fx3api.open({k:'wall',s:'P'});fx3api.open({k:'wall',s:'L'});fx3api.open({k:'mod',mi:0});
           a.wm(1);S.xw=[{id:1,a:[500,1500],b:[2000,1500],t:150}];S.geo=[{id:1,x:500,z:900,w:600,d:400,b:0,h:300,c:'#d9d4ca'}];window.re3();fx3api.open({k:'wall',s:'X1'});a.del('X1');a.wm(0);fx3api.open({k:'geo',id:1});
           S.mods.forEach(function(m){if(m.sup)m.led={k:'emb',c:'3000',pf:'alu',pos:'base',on:1}});fx3api.night(1);window.re3();fx3api.night(0);R.leds=fx3api.leds();document.getElementById('v3x').click()});
          step('ilha',function(){var a=islNew('ilha');S.isl.push(a);draw();R.ilha=S.isl.length});
          step('quarto',function(){S.room='quarto';S.env='livre';S.mods=[];S.stones=[];S.st=null;S.fr=[];S.isl=[];draw();panel();
           ['dArm','dCan','dFec','dEsp','dCant','dPas','quarto'].forEach(function(id){(cat(id).it||[]).forEach(function(it){if(!it.act&&it.w&&S.mods.length<40)newTpl(it)})});draw();panel();R.quarto=S.mods.length;window.open3D();document.getElementById('v3x').click()});
          step('outros',function(){['sala','banho','escr'].forEach(function(r){S.room=r;S.env='livre';S.mods=[];draw();panel();(ROOMCATS[r]||[]).forEach(function(id){(cat(id).it||[]).slice(0,4).forEach(function(it){if(!it.act&&it.w)newTpl(it)})});draw();window.open3D();document.getElementById('v3x').click()})});
          step('guia',function(){gdOpen();document.getElementById('gdm').hidden=true});
          step('salvar',function(){var st=JSON.parse(JSON.stringify(snapState()));loadState(st);R.salvo=S.mods.length});
          await new Promise(function(r){setTimeout(r,1500)});
          return JSON.stringify({errs:__errs,R:R});
          """#)
        let r = o["R"] as? [String: Any] ?? [:]
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "erros: \(o["errs"] ?? "")")
        XCTAssertEqual(r["cat_csob"] as? Int, 11, "cubas de sobrepor")
        XCTAssertGreaterThanOrEqual(r["cat_cgel"] as? Int ?? 0, 8, "geladeiras")
        XCTAssertGreaterThanOrEqual(r["setas"] as? Int ?? 0, 20, "setinhas nos eletros")
        XCTAssertGreaterThan(r["rows"] as? Int ?? 0, 0, "orçamento")
        XCTAssertGreaterThanOrEqual(r["quarto"] as? Int ?? 0, 20, "armários do quarto")
    }
}
