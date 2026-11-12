import XCTest
import WebKit
@testable import Arquemestre

/// O editor de móveis de verdade (o editor.html que vai dentro do app) rodando no WebKit do iOS:
/// plano de corte, enviar projeto pro cortador (compactação + modo corte), puxadores (perfil G, cava de perfil, concha),
/// travar módulo, TV na sala e o 3D. Roda no simulador do CI (não é um iPhone de verdade).
final class EditorWebKitTests: XCTestCase {
    private final class Loaded: NSObject, WKNavigationDelegate {
        let ready: XCTestExpectation
        init(_ ready: XCTestExpectation) { self.ready = ready }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { ready.fulfill() }
    }

    /// Mesma ponte "ArqueApp" que o app injeta, só que guardando tudo em memória.
    private static let bridge = """
    window.__noSetup=1;window.__errs=[];
    window.addEventListener('error',function(e){__errs.push(String(e.message||e))});
    window.addEventListener('unhandledrejection',function(e){__errs.push('promise: '+String(e.reason))});
    window.__files={};window.__shared=null;
    window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},
      putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},
      listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},
      shareCut:function(c,n,t){__shared={code:c,name:n,title:t}},listNotes:function(){return '[]'},
      contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};
    """

    private var hold: [WKWebView] = []

    override func tearDown() async throws {
        await MainActor.run {
            hold.forEach { $0.removeFromSuperview() }
            hold = []
        }
        try await super.tearDown()
    }

    @MainActor
    private func editor() async throws -> WKWebView {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "editor", withExtension: "html"), "editor.html tem que ir dentro do app")
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.addUserScript(WKUserScript(source: Self.bridge, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 430, height: 900), configuration: config)
        if let w = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first { w.addSubview(web) }
        hold.append(web)
        let ready = expectation(description: "editor carregado"), d = Loaded(ready)
        web.navigationDelegate = d
        web.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        await fulfillment(of: [ready], timeout: 60)
        web.navigationDelegate = nil
        _ = d
        try await Task.sleep(nanoseconds: 700_000_000)
        return web
    }

    @MainActor
    private func run(_ web: WKWebView, _ js: String) async throws -> [String: Any] {
        let r = try await web.callAsyncJavaScript(js, arguments: [:], in: nil, contentWorld: .page)
        let s = try XCTUnwrap(r as? String, "o JS tem que devolver um JSON")
        return try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(s.utf8)) as? [String: Any])
    }

    @MainActor
    func testPlanoDeCorteAbreOtimizaENaoDaErro() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(3);newTpl(2);newTpl(4);draw();
          var t0=performance.now();openCut();var dt=performance.now()-t0;
          var n=document.querySelectorAll('#cutbody [data-cp]').length;
          await new Promise(function(r){var t1=Date.now();(function w(){var b=(document.getElementById('cutopt')||{}).textContent||'';if(b.indexOf('✓')>=0||Date.now()-t1>30000)r();else setTimeout(w,100)})()});
          var tot=(document.getElementById('cutbody').textContent.match(/(\d+) peças no total/)||[])[1];
          return JSON.stringify({n:n,ms:dt,badge:(document.getElementById('cutopt')||{}).textContent||'',tot:+tot||0,
            enviar:!document.getElementById('cutsend').hidden,errs:__errs});
          """#)
        XCTAssertGreaterThan(o["n"] as? Int ?? 0, 0, "peças no plano das chapas")
        XCTAssertGreaterThan(o["tot"] as? Int ?? 0, 0, "total de peças da lista")
        XCTAssertTrue((o["badge"] as? String ?? "").contains("✓"), "otimização terminou: \(o["badge"] ?? "")")
        XCTAssertLessThan(o["ms"] as? Double ?? 99999, 5000, "plano de corte abre rápido")
        XCTAssertEqual(o["enviar"] as? Bool, true, "botão Enviar projeto aparece no app")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    @MainActor
    func testEnviarProjetoCompactaSemPrecoEAbreNoModoCorte() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(3);newTpl(4);draw();S.preco=1234;
          openCut();cutSend();
          await new Promise(function(r){var t=Date.now();(function w(){if(__shared||Date.now()-t>5000)r();else setTimeout(w,50)})()});
          var code=__shared?__shared.code:'';var back=code?await cutDecode(code):null;
          window.arqueCutOpen(code);
          await new Promise(function(r){setTimeout(r,1200)});
          var txt=document.getElementById('cutbody').textContent;
          return JSON.stringify({prefix:code.charAt(0),len:code.length,json:JSON.stringify(cutPayload()).length,
            mods:back?back.st.mods.length:-1,preco:back?('preco' in back.st):true,
            cutmode:!!window.CUTMODE&&!!window.RO,banner:txt.indexOf('Modo corte')>=0,valores:txt.indexOf('R$')>=0,
            fr:txt.indexOf('Marcenaria Teste')>=0,avisar:document.getElementById('cutsend').textContent,errs:__errs});
          """#)
        XCTAssertEqual(o["prefix"] as? String, "z", "compactado (CompressionStream do WebKit)")
        XCTAssertLessThan(o["len"] as? Int ?? 99999, o["json"] as? Int ?? 0, "o link fica menor que o projeto")
        XCTAssertEqual(o["mods"] as? Int, 2)
        XCTAssertEqual(o["preco"] as? Bool, false, "o link não leva o preço")
        XCTAssertEqual(o["cutmode"] as? Bool, true, "quem recebe abre no modo corte (só ver e cortar)")
        XCTAssertEqual(o["banner"] as? Bool, true)
        XCTAssertEqual(o["valores"] as? Bool, false, "o cortador não vê valores")
        XCTAssertEqual(o["fr"] as? Bool, true, "mostra quem mandou")
        XCTAssertTrue((o["avisar"] as? String ?? "").contains("Avisar"))
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    @MainActor
    func testPuxadoresDescontamCertoEConchaNoMeio() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(3);draw();var m=S.mods[0];
          function fr(){return partsOf(m).filter(function(p){return p.name==='Porta'&&!p.noDraw}).map(function(p){return {cl:p.cl,cw:p.cw,note:p.note||''}})[0]}
          pxApplyAll('externo','inox');var a=fr();pxApplyAll('g','inox');var g=fr();pxApplyAll('perfil','preto');var c=fr();pxApplyAll('concha','dourado');var k=fr();
          S.m=m;S.sv=0;S.tab=3;panel();var foto=!!document.querySelector('.pxcard img');
          return JSON.stringify({a:a.cw,w:a.cl,g:g.cw,c:c.cw,k:k.cw,gnote:g.note,knote:k.note,foto:foto,errs:__errs});
          """#)
        let a = o["a"] as? Double ?? 0, w = o["w"] as? Double ?? 0
        XCTAssertEqual(o["g"] as? Double ?? 0, a - 29, accuracy: 0.01, "perfil gola (G) desconta 29 mm: 42 de altura − 13 que abraçam a MDF")
        XCTAssertEqual(o["c"] as? Double ?? 0, a, accuracy: 0.01, "cava de perfil NÃO desconta: porta = lateral + 30, o perfil entra na cava")
        XCTAssertEqual(o["k"] as? Double ?? 0, a, accuracy: 0.01, "concha não muda a altura")
        XCTAssertTrue((o["gnote"] as? String ?? "").contains("+ perfil 29 ="))
        func n1(_ v: Double) -> String { String(format: "%g", (v * 10).rounded() / 10).replacingOccurrences(of: ".", with: ",") }
        XCTAssertTrue((o["knote"] as? String ?? "").contains("furos a \(n1((w - 96) / 2)) e \(n1((w + 96) / 2)) mm da esquerda, \(n1(a / 2)) mm de cima"), "\(o["knote"] ?? "")")
        XCTAssertEqual(o["foto"] as? Bool, true, "foto do puxador no quadro")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    @MainActor
    func testTVNaSalaETravarModulo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.tab=9;panel();document.querySelector('[data-room="sala"]').click();
          S.mods=[];S.rp=[];S.fr=[];draw();panel();
          catOpen('painel');Array.from(document.querySelectorAll('#catgw [data-cati]')).filter(function(x){return /Painel liso \(placa\)/.test(x.textContent)})[0].click();
          await new Promise(function(r){setTimeout(r,300)});
          var tabs=Array.from(document.querySelectorAll('#tabs [data-t]')).map(function(d){return d.textContent}).join('|');
          var tv=apAdd('tv',3);draw();
          var svg=document.getElementById('svg').innerHTML,tvTop=svg.indexOf('data-ap=')>svg.lastIndexOf('data-rp=');
          catOpen('sala');Array.from(document.querySelectorAll('#catgw [data-cati]')).filter(function(x){return /Rack de TV/.test(x.textContent)})[0].click();
          var msg=lockToggle(S.mods[0]);draw();
          var st=snapState();
          return JSON.stringify({tabs:tabs,tvMeio:Math.abs(tv.x+tv.w/2-(S.rp[0].x+S.rp[0].w/2)),tvCentro:tv.b+tv.h/2,tvTop:tvTop,
            lock:!!S.mods[0].lock,msg:msg,cadeado:!!document.querySelector('[data-lockmark]'),salvo:!!(st.mods&&st.mods[0]&&st.mods[0].lock),errs:__errs});
          """#)
        XCTAssertTrue((o["tabs"] as? String ?? "").contains("TV"), "aba TV na sala: \(o["tabs"] ?? "")")
        XCTAssertLessThanOrEqual(o["tvMeio"] as? Double ?? 99, 1, "TV no meio do painel")
        XCTAssertEqual(o["tvCentro"] as? Double ?? 0, 1150, accuracy: 1, "centro da TV a 1150 mm do chão")
        XCTAssertEqual(o["tvTop"] as? Bool, true, "TV desenhada por cima do painel")
        XCTAssertEqual(o["lock"] as? Bool, true)
        XCTAssertTrue((o["msg"] as? String ?? "").contains("travado"))
        XCTAssertEqual(o["cadeado"] as? Bool, true, "cadeado no desenho")
        XCTAssertEqual(o["salvo"] as? Bool, true, "trava fica salva no projeto")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    @MainActor
    func test3DAbreComPuxadorEPrateleira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(3);newTpl(4);draw();pxApplyAll('g','dourado');
          S.rp.push({id:77,prat:true,x:200,w:900,b:1600,h:40,pd:250,rd:60});draw();
          open3D();await new Promise(function(r){setTimeout(r,1000)});
          var n=dbg3().length;document.getElementById('v3x').click();
          return JSON.stringify({boxes:n,errs:__errs});
          """#)
        XCTAssertGreaterThan(o["boxes"] as? Int ?? 0, 20, "3D montado")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testBuscaAchaTVEletrodomesticoEFacetadoDesconta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;function nm(q){return catFind(q).reduce(function(a,g){return a.concat(g.it.map(function(r){return r.it.n}))},[])}
          var tv=nm('tv'),tele=nm('televisão'),gela=nm('gela'),dois=nm('2p');
          S.tab=9;panel();document.querySelector('[data-room="sala"]').click();catOpen();
          var abas=Array.from(document.querySelectorAll('#catb [data-catt]')).map(function(b){return b.textContent}).join('|'),prim=document.querySelector('#catgw [data-cati]').textContent;
          document.querySelector('#catm').hidden=true;
          S.mods=[];newTpl(3);draw();var m=S.mods[0],a=partsOf(m).filter(function(p){return p.name==='Porta'})[0].cw;
          pxApplyAll('facetado','preto');var f=partsOf(m).filter(function(p){return p.name==='Porta'})[0];
          open3D();await new Promise(function(r){setTimeout(r,600)});var n=dbg3().length;document.getElementById('v3x').click();
          return JSON.stringify({tv:tv.filter(function(x){return /^TV /.test(x)}).length,tv1:tv[0],tele:tele.filter(function(x){return /^TV /.test(x)}).length,
            gela:gela.filter(function(x){return /^Geladeira/.test(x)}).length,dois:dois[0]||'',abas:abas,prim:prim,a:a,f:f.cw,fnote:f.note||'',boxes:n,errs:__errs});
          """#)
        XCTAssertEqual(o["tv"] as? Int, 5, "busca \"tv\" acha as 5 TVs")
        XCTAssertTrue((o["tv1"] as? String ?? "").hasPrefix("TV "), "TVs vêm primeiro")
        XCTAssertEqual(o["tele"] as? Int, 5, "busca \"televisão\" acha as TVs")
        XCTAssertGreaterThanOrEqual(o["gela"] as? Int ?? 0, 4, "abreviação \"gela\" acha geladeiras")
        XCTAssertTrue((o["dois"] as? String ?? "").contains("2 portas"), "\"2p\" = 2 portas")
        XCTAssertTrue((o["abas"] as? String ?? "").contains("TV"), "aba TV no catálogo da sala: \(o["abas"] ?? "")")
        XCTAssertTrue((o["prim"] as? String ?? "").contains("TV na parede"), "TV aparece em cima na sala")
        let a = o["a"] as? Double ?? 0
        XCTAssertEqual(o["f"] as? Double ?? 0, a - 15.5, accuracy: 0.01, "facetado desconta 15,5 mm")
        XCTAssertTrue((o["fnote"] as? String ?? "").contains("Perfil facetado"), "\(o["fnote"] ?? "")")
        XCTAssertGreaterThan(o["boxes"] as? Int ?? 0, 20, "3D com o facetado")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testGavetaTelescopicaRebaixoContraFrenteEFundo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));S.mods=[];newTpl(JSON.parse(JSON.stringify(all.filter(function(i){return i.n==='Gaveteiro 3 gavetas'})[0])));var m=S.mods[0];S.m=m;CURM=m;
          var v=m.v[0],vr=vaoRanges(m)[0],vw=vr[1]-vr[0],fh=drawerH(v);CURM=null;
          var P=partsOf(m),g=function(re){return P.filter(function(p){return re.test(p.name)})[0]},la=g(/^Lateral de gaveta/),cf=g(/^Frente\/costa de gaveta/),fu=g(/^Fundo de gaveta/);
          var L=cutLines(m),cq=L.filter(function(l){return /^Frente\/costa de gaveta/.test(l.names[0])}).reduce(function(a,l){return a+l.qty},0);
          return JSON.stringify({vw:vw,fh:fh,lh:la.cw,ld:la.cl,cl:cf.cl,ch:cf.cw,fw:fu.cl,fd:fu.cw,fmat:fu.mat,cq:cq,errs:__errs});
          """#)
        let vw = o["vw"] as? Double ?? 0, fh = o["fh"] as? Double ?? 0, lh = o["lh"] as? Double ?? 0
        let cx = (vw - 26).rounded()
        XCTAssertEqual(lh, fh - 56, accuracy: 0.11, "lateral = vão da gaveta − 56")
        XCTAssertEqual(o["ch"] as? Double ?? 0, lh - 15, accuracy: 0.11, "contra-frente 15 mm menor que a lateral (fica em cima do fundo)")
        XCTAssertEqual(o["cl"] as? Double ?? 0, cx - 30, accuracy: 0.11, "contra-frente entre as laterais = caixa − 30")
        XCTAssertEqual(o["fw"] as? Double ?? 0, cx - 15, accuracy: 0.11, "fundo no rebaixo 6 × 6 + 1,5 a mais por lado (Ajustes) = caixa − 30 + 12 + 3")
        XCTAssertEqual(o["ld"] as? Double ?? 0, 460, accuracy: 0.11, "regra: caixote acima de 470 → laterais da gaveta com 460")
        XCTAssertEqual(o["fd"] as? Double ?? 0, o["ld"] as? Double ?? -1, accuracy: 0.11, "fundo no comprimento todo da lateral")
        XCTAssertEqual(o["fmat"] as? Double ?? 0, 6, accuracy: 0.01)
        XCTAssertEqual(o["cq"] as? Int, 6, "3 gavetas = 6 peças de contra-frente/traseira")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testTamponamentoDeBaixoPassaPorBaixoDoVizinhoSemAfastar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(4);newTpl(4);var A=S.mods[0],B=S.mods[1];A.tb=true;B.tb=true;B.tl=true;B.x=A.x+A.w+30;draw();var x0=[A.x,B.x];
          B.tbL=500;tbCover(B,{});S.mods.forEach(function(q){noOverlap(q,'m')});draw();
          var c=[].concat.apply([],S.mods.map(function(m){return cutLines(m).filter(function(l){return /de baixo/.test(l.name)&&/face|única/.test(l.name)&&!/engrosso/.test(l.name)}).map(function(l){return l.L})}));
          return JSON.stringify({ax:A.x,bx:B.x,ax0:x0[0],bx0:x0[1],pecas:c.length,L:c[0]||0,errs:__errs});
          """#)
        XCTAssertEqual(o["ax"] as? Double, o["ax0"] as? Double, "o vizinho não sai do lugar")
        XCTAssertEqual(o["bx"] as? Double, o["bx0"] as? Double, "o módulo não sai do lugar")
        XCTAssertEqual(o["pecas"] as? Int, 1, "vira uma peça só (até 2700)")
        XCTAssertEqual(o["L"] as? Double ?? 0, 2030, accuracy: 0.5)
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testTamponamentoLateralDoMeioAlinhaComODeBaixo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(4);newTpl(4);var A=S.mods[0],B=S.mods[1];A.tb=B.tb=true;A.tl=true;B.tl=true;B.x=A.x+A.w+30;draw();
          var pa=partsOf(A).filter(function(p){return p.name==='Tamponamento de baixo'})[0],pb=partsOf(B).filter(function(p){return p.name==='Tamponamento de baixo'})[0],sl=partsOf(B).filter(function(p){return p.name==='Tamponamento esquerdo'})[0];
          var c=[].concat.apply([],S.mods.map(function(m){return cutLines(m).filter(function(l){return /de baixo/.test(l.name)&&!/engrosso/.test(l.name)}).map(function(l){return l.L})}));
          return JSON.stringify({fimA:A.x+pa.x+pa.w,iniB:B.x+pb.x,meioH:sl.h,modH:B.h,pecas:c.length,L:c[0]||0,errs:__errs});
          """#)
        XCTAssertEqual(o["fimA"] as? Double, o["iniB"] as? Double, "o de baixo encontra o do vizinho, sem sobrar pedaço")
        XCTAssertEqual(o["meioH"] as? Double, o["modH"] as? Double, "o lateral do meio para em cima do de baixo")
        XCTAssertEqual(o["pecas"] as? Int, 1)
        XCTAssertEqual(o["L"] as? Double ?? 0, 2030, accuracy: 0.5)
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPlanoDeCorteLocalizaCadaPecaNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.env='cozinha';var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          mkCorner('e');newTpl(T('Balcão 2 portas'));newTpl(T('Gaveteiro 3 gavetas'));PLWS='e';plwAdd('base');plwAdd('base');PLWS=null;newTpl(4);newTpl(4);var U=S.mods.filter(function(m){return m.sup});U.forEach(function(m,i){m.tb=true;m.tt=true;m.tl=i===0;m.tr=i===U.length-1});U[1].x=U[0].x+U[0].w;
          draw();open3D();var B=__boxes();pkFix3(B);var tot=0,ruins=[];
          sheetPlan().groups.forEach(function(g){g.sheets.forEach(function(s){s.used.forEach(function(u){tot++;(u.p.src||[{}]).forEach(function(e){if(e.mi==='rp')return;if(e.mi===undefined||!e.pk){ruins.push(u.p.lab);return}var ok=hlResolve(B,[{mi:e.mi,pk:e.pk}]).length>1||B.some(function(b){return parseInt(String(b.nm),10)===e.mi&&b.pk===e.pk});if(!ok)ruins.push(u.p.lab)})})})});
          return JSON.stringify({tot:tot,ruins:ruins.length,lista:ruins.slice(0,5).join(' | '),errs:__errs});
          """#)
        XCTAssertGreaterThan(o["tot"] as? Int ?? 0, 40)
        XCTAssertEqual(o["ruins"] as? Int, 0, "toda peça do plano acha a peça certa no 3D: \(o["lista"] ?? "")")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testSoEmbaixoDaPiaSemFundoETorreComBaseETeto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.env='cozinha';S.W=4200;/* parede onde tudo cabe inteiro (sem espaço, o módulo novo vai pra parede do lado) */var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Balcão da pia (cuba)'));newTpl(T('Gaveteiro 3 gavetas'));newTpl(0);newTpl(4);addStone();draw();open3D();var B=__boxes();
          var z=S.mods.map(function(m,i){return Math.min.apply(null,B.filter(function(b){return String(b.nm)===i+':Lateral esquerda'}).map(function(b){return Math.round(b.z0)}))});
          var tor=S.mods[3],bt=partsOf(tor).filter(function(p){return /^Base (inferior|superior)$/.test(p.name)}).length;
          return JSON.stringify({f:S.mods.map(function(m){return m.fundo}).join(','),z:z.join(','),bt:bt,tt:!!tor.tt,errs:__errs});
          """#)
        XCTAssertEqual(o["f"] as? String, "true,false,true,true,true", "só o balcão embaixo da pia fica sem fundo (área úmida)")
        XCTAssertEqual(o["z"] as? String, "6,6,6,6,6", "frentes alinhadas, com ou sem fundo")
        XCTAssertEqual(o["bt"] as? Int, 2, "torre tem base e teto")
        XCTAssertEqual(o["tt"] as? Bool, false, "torre sem tamponamento em cima")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPontaExpostaGanhaTamponamentoSozinhaEPlantaEmAnguloDaZoom() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.env='cozinha';S.W=4140;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Gaveteiro 3 gavetas'));draw();var A=S.mods[0],B=S.mods[1];
          var s1=[A.tl?1:0,A.tr?1:0,B.tl?1:0,B.tr?1:0].join('');/* parede à esquerda; ponta direita do gaveteiro exposta */
          B.x=2000;draw();var s2=[A.tr?1:0,B.tl?1:0,B.tr?1:0].join('');/* afastou: as duas pontas do meio ficam expostas */
          B.x=A.x+A.w+30;draw();var s3=[A.tr?1:0,B.tl?1:0,B.tr?1:0,B.x-(A.x+A.w)].join('');/* voltou a encostar: tamponamentos do meio somem e os módulos se encontram */
          S.m=B;B.tr=false;B.trM=1;delete B.trAuto;draw();var s4=B.tr?1:0;/* desmarcou na mão: não volta sozinho */
          PLV=true;PLANG=true;VB={x:0,y:0,w:900,h:560};setVB();draw();zoom(1.4);var vb=$('svg').getAttribute('viewBox').split(' ').map(Number);
          return JSON.stringify({s1:s1,s2:s2,s3:s3,s4:s4,zw:Math.round(vb[2]),ang:PLANG,errs:__errs});
          """#)
        XCTAssertEqual(o["s1"] as? String, "0001", "só a ponta exposta (direita do gaveteiro) ganha tamponamento; encostado na parede e entre vizinhos não")
        XCTAssertEqual(o["s2"] as? String, "111", "afastou: as pontas que ficaram soltas ganham tamponamento")
        XCTAssertEqual(o["s3"] as? String, "0010", "encostou de novo: tamponamentos do meio somem e os módulos se encontram (gap 0)")
        XCTAssertEqual(o["s4"] as? Int, 0, "desmarcado na mão fica desmarcado")
        XCTAssertEqual(o["zw"] as? Int, 643, "zoom (+) funciona na planta em ângulo igual na reta")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testFerragensFitaPorCorNichoNaCorDeForaEPaletaAmadeirada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;S.H=2700;S.Hm=1;S.Wm=1;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Gaveteiro 3 gavetas'));newTpl(T('2P c/ Cab+Gav Int 600mm'));newTpl(4);S.mods.forEach(function(m){m.corF='#a67c52';m.corFN='Freijó'});draw();var n2=addNichoMicro(1,'liso');newTpl(T('Estante com porta de correr'));draw();
          var hw={};S.mods.forEach(function(m,i){hw[hwTag(m,i)]=hwOf(m)});var g=function(t,k){return (hw[t]&&hw[t][k])?hw[t][k].n:0};
          var nl=cutLines(n2);var txt=cutAll().replace(/<[^>]+>/g,' ');
          open3D();var B=__boxes();var ni=S.mods.indexOf(n2);var cols=B.filter(function(b){return String(b.nm).indexOf(ni+':')===0&&!b.pf&&b.c}).map(function(b){return b.c.join(',')});var okCol=cols.length>0&&cols.every(function(c){return c==='166,124,82'});
          return JSON.stringify({dob1:g('Base 1','Dobradiça 35 mm (caneco)'),cor2:g('Base 2','Corrediça telescópica 450 mm (par)'),dob3:g('Base 3','Dobradiça 35 mm (caneco)'),kit:Object.keys(hw['Base 4']||{}).some(function(k){return /Kit porta de correr/.test(k)}),nichoCor:nl.every(function(l){return l.fin==='c'}),okCol:okCol,fita:/Total de fita de borda/.test(txt)&&/na cor de fora/.test(txt),amad:SWW.length>=10&&/Amadeiradas/.test(swRow('corF','')),errs:__errs});
          """#)
        XCTAssertEqual(o["dob1"] as? Int, 4, "2 portas de 820 → 2 dobradiças 35 mm cada")
        XCTAssertEqual(o["cor2"] as? Int, 3, "3 gavetas → 3 pares de corrediça (regra: lateral 460, corrediça 450)")
        XCTAssertEqual(o["dob3"] as? Int, 10, "2 portas de 2400 → 5 dobradiças cada")
        XCTAssertEqual(o["kit"] as? Bool, true, "porta de correr → kit de trilhos")
        XCTAssertEqual(o["nichoCor"] as? Bool, true, "nicho aberto: todas as peças na chapa cor")
        XCTAssertEqual(o["okCol"] as? Bool, true, "nicho no 3D na cor de fora do módulo vizinho")
        XCTAssertEqual(o["fita"] as? Bool, true, "plano de corte traz metros de fita por cor")
        XCTAssertEqual(o["amad"] as? Bool, true, "paleta com cores amadeiradas")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPortaComCavaSempreLateralMais30EmTodoOCatalogo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var all=TPL.concat(CATS.flatMap(function(c){return c.it})).filter(function(i){return i.w&&i.v});var bad=[],n=0;
          ['cava','perfil'].forEach(function(px){all.forEach(function(t){S.mods=[];S.stones=[];S.fr=[];try{newTpl(JSON.parse(JSON.stringify(t)))}catch(e){return}var m=S.mods[0];if(!m||m.corner)return;
            (m.v||[]).forEach(function(v){if(v.k==='door'){v.px=px;v.cava=px==='cava'}});draw();var P=partsOf(m),lat=P.filter(function(p){return p.name==='Lateral esquerda'})[0],pV=mv(m,'pV',15),pS=mv(m,'pSn',6);
            P.filter(function(p){return p.name==='Porta'&&!p.glass}).forEach(function(p){var v=m.v[p.vi];if(!v||v.mw||v.gx)return;n++;
              /* altura: vão + 2×15 (= lateral + 30 quando o vão é único) */if(Math.abs(p.cw-(p.h+(p.pxD||0)))>0.11||(p.pxD||0)>0)bad.push(t.n+' | '+px+' | porta '+p.cl+'×'+p.cw+' com desconto '+(p.pxD||0));
              if(m.v.length===1&&!m.div&&lat&&Math.abs(p.cw-(lat.cl+2*pV))>0.11)bad.push(t.n+' | '+px+' | porta alt '+p.cw+' ≠ lateral '+lat.cl+' + '+(2*pV));
              /* largura: (vão + 12) ÷ n nas portas duplas do aéreo/balcão */if(v.n>=2&&m.v.length===1&&!m.div&&Math.abs(p.cl-Math.round(((m.w-2*m.esp)+2*pS-(v.n-1)*mv(m,'pGap',0))/v.n*10)/10)>0.11)bad.push(t.n+' | '+px+' | porta larg '+p.cl)})})});
          /* o caso real: aéreo 1105 × 800 × 350, 2 portas, cava de perfil */S.mods=[];newTpl(4);var m=S.mods[0];m.w=1105;m.h=800;m.d=350;m.v=[{k:'door',n:2,cava:false,px:'perfil'}];draw();var d=partsOf(m).filter(function(p){return p.name==='Porta'}).map(function(p){return p.cl+'x'+p.cw}).join(',');
          return JSON.stringify({portas:n,bad:bad.slice(0,10),caso:d,cv:STD().cvDesc,errs:__errs});
          """#)
        XCTAssertGreaterThan(o["portas"] as? Int ?? 0, 100, "auditou o catálogo inteiro")
        XCTAssertEqual((o["bad"] as? [String])?.count, 0, "porta com cava fora da regra lateral + 30: \(o["bad"] ?? "")")
        XCTAssertEqual(o["caso"] as? String, "542.5x800,542.5x800", "aéreo 1105 × 800 com cava de perfil: portas 542,5 × 800 (2 mm entre as folhas; não 770)")
        XCTAssertEqual(o["cv"] as? Int, 0, "cava de perfil não desconta altura")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testRipadoNoPlanoOtimizadoComPlacasDaBaseEParedeLateralAteOMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='sala';S.W=4140;S.H=2700;S.Hm=1;S.Wm=1;var ra=rpNew({x:0,b:0,w:4000,h:2600});draw();
          var L=rpLayout(ra),pcs=rpCutPieces(),P=sheetPlan(),big=P.groups.reduce(function(s,g){return s+(g.big?g.big.length:0)},0);
          var base=pcs.filter(function(p){return /Chapa base/.test(p.name)}),ripas=pcs.filter(function(p){return /^Ripa /.test(p.name)});
          open3D();var B=__boxes();var b3=B.filter(function(b){return b.rpid===ra.id&&Math.abs((b.z1-b.z0)-6)<0.01}).length;
          S.env='cozinha';newTpl(4);var m=S.mods[0];m.x=5;m.d=350;S.pw={ate:'movel',tipo:'ripado'};pwGenerateWall('e');var wl=S.rp.filter(function(a){return a.wall==='e'})[0];
          /* localizar no 3D: a placa 2 da base e as ripas têm origem no plano e ficam em rosa */
          var G=cutGroups(),gb=G.ord.map(function(k){return G.map[k]}).filter(function(g){return /^Chapa base do ripado/.test(g.names[0])}),src2=srcStr([].concat.apply([],gb[1].src)),srcR=srcStr([].concat.apply([],G.ord.map(function(k){return G.map[k]}).filter(function(g){return /^Ripa /.test(g.names[0])})[0].src));
          show3D(src2,'Chapa base');await new Promise(function(r){setTimeout(r,250)});var pink=function(){return __boxes().filter(function(b){return b.rpid===ra.id&&b.c[0]===227&&b.c[1]===25&&b.c[2]===123}).map(function(b){return b.rpart})};var pink2=pink();
          show3D(srcR,'Ripa');await new Promise(function(r){setTimeout(r,250)});var pr=pink(),pinkR=pr.length+':'+pr.filter(function(v,i,a){return a.indexOf(v)===i}).join();document.getElementById('v3x').click();
          return JSON.stringify({seams:L.seams.join(','),nBase:base.length,baseW:base.map(function(p){return p.L+'x'+p.W}).join(','),ripas:ripas.reduce(function(s,p){return s+p.qty},0),n:L.n,big:big,b3:b3,wallW:wl?wl.w:null,wallRip:wl?!wl.liso:null,front:pwFront('e'),src2:src2,pink2:pink2,pinkR:pinkR,errs:__errs});
          """#)
        XCTAssertEqual(o["seams"] as? String, "1820,3640", "emendas da chapa base pela chapa útil (1840 − 2×10 de refilo)")
        XCTAssertEqual(o["nBase"] as? Int, 3, "chapa base dividida em 3 placas")
        XCTAssertEqual(o["baseW"] as? String, "2600x1820,2600x1820,2600x360", "placas 1820 + 1820 + 360")
        XCTAssertEqual(o["ripas"] as? Int, o["n"] as? Int, "todas as ripas entram no plano otimizado")
        XCTAssertEqual(o["big"] as? Int, 0, "nenhuma peça fora da chapa")
        XCTAssertEqual(o["b3"] as? Int, 3, "3D mostra as 3 placas da base")
        XCTAssertTrue((o["src2"] as? String ?? "").hasPrefix("rp|") && (o["src2"] as? String ?? "").hasSuffix("|base2"), "placa da base tem origem pro 3D: \(o["src2"] ?? "")")
        XCTAssertEqual(o["pink2"] as? [String], ["base2"], "localizar a placa 2: só ela em rosa no 3D")
        XCTAssertEqual(o["pinkR"] as? String, "\(o["n"] as? Int ?? -1):ripa", "localizar as ripas: todas em rosa, só elas")
        XCTAssertEqual(o["wallRip"] as? Bool, true, "parede lateral pode ser ripado")
        XCTAssertEqual((o["wallW"] as? Double ?? 0), (o["front"] as? Double ?? 0) - 50, accuracy: 0.6, "painel lateral vai até 50 mm antes da frente do móvel")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testLateraisPorForaLadoDaFitaEImpressaoDoPlano() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;
          newTpl(4);var m=S.mods[0];m.w=900;m.h=800;m.d=350;m.latFora=true;draw();var P=partsOf(m),g=function(n){var p=P.filter(function(q){return q.name===n})[0];return p?p.cl+'x'+p.cw:''};
          var sides=['Porta','Lateral esquerda','Base inferior','Base superior','Fundo','Lateral de gaveta','Rodapé (pedestal)','Ripa 40 mm','Tamponamento esquerdo'].map(function(n){return edgeSides(n)}).join('|');
          window.print=function(){window.__printed=1};openCut();var pb=document.getElementById('cutprint');var tbl=document.querySelector('#cutbody table.cutpt'),heads=tbl?[].map.call(tbl.querySelectorAll('th'),function(t){return t.textContent}).join(','):'';cutPrint();var hd=document.getElementById('pthead');
          var greens=(document.querySelector('#cutbody svg[viewBox^="-30 "]')||{innerHTML:''}).innerHTML.indexOf('#1f9d55')>=0;
          return JSON.stringify({lat:g('Lateral esquerda'),base:g('Base inferior'),teto:g('Base superior'),sides:sides,btn:!!pb,heads:heads,hd:!!(hd&&/Data|Ordem/.test(hd.textContent)),greens:greens,opt:STDOPT.caixa.length,errs:__errs});
          """#)
        XCTAssertEqual(o["lat"] as? String, "800x350", "laterais por fora: lateral inteira (altura do módulo)")
        XCTAssertEqual(o["base"] as? String, "870x350", "base entre as laterais: largura − 2 × 15")
        XCTAssertEqual(o["teto"] as? String, "870x350", "teto entre as laterais")
        XCTAssertEqual(o["sides"] as? String, "LRTB|B|B|LRTB||T||TB|LRTB", "regra do lado da fita por peça")
        XCTAssertEqual(o["btn"] as? Bool, true, "botão Imprimir / PDF na lista")
        XCTAssertEqual(o["heads"] as? String, "#,Peça,Compr. × Larg.,Qtd,Fita,☐", "tabela da chapa: número, peça, medida, qtd, lado da fita e ☐")
        XCTAssertEqual(o["hd"] as? Bool, true, "cabeçalho de impressão com ordem e data")
        XCTAssertEqual(o["greens"] as? Bool, true, "lado da fita em verde no desenho da chapa")
        XCTAssertEqual(o["opt"] as? Int, 2, "opção de caixaria: por dentro / por fora")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testAssistenteDeAjustesAplicaNosModulosPlantaOpacaECompletarFileira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;STD().latPiso='sim';/* confere o jeito "até o piso" (o padrão agora é em cima do rodapé) */S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;S.H=2700;S.Hm=1;S.Wm=1;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          /* assistente: laterais por fora, desconto da lateral da gaveta 60, rasgo 8 */wizOpen();var st=STD();st.caixa='fora';st.gavDsc=60;st.gavRb=8;window.WIZ=wizSteps().length-1;stdRe();var done=!!document.querySelector('#stdbody [data-wizdone="1"]');window.WIZ=null;stdSave();
          newTpl(T('Gaveteiro 3 gavetas'));var m=S.mods[0];draw();var P=partsOf(m),g=function(n){var p=P.filter(function(q){return q.name===n})[0];return p?p.cl+'x'+p.cw:''};var fund=P.filter(function(q){return /^Fundo de gaveta/.test(q.name)})[0];
          var cl=cutLines(m).filter(function(l){return /Lateral de gaveta|Fundo de gaveta/.test(l.name)}).map(function(l){return l.L+'x'+l.W}).join(',');
          /* planta em ângulo: portas e frentes opacas */PLV=true;PLANG=true;draw();var g_=document.getElementById('plx');var trans=g_?[].filter.call(g_.querySelectorAll('polygon[data-pm]'),function(p){return p.getAttribute('fill-opacity')&&+p.getAttribute('fill-opacity')<1}).length:-1;var polys=g_?g_.querySelectorAll('polygon[data-pm]').length:0;PLV=false;PLANG=false;
          /* completar acima: toda a fileira, mesma divisão */S.rp=[];[0,1400,2800].forEach(function(x){var a=rpNew({x:x,b:0,w:1340,h:1000});a.liso=true;a.jt={t:'seca',w:0,d:0}});pwAbove(S.rp[0]);var up=S.rp.filter(function(a){return a.b>0});var okRow=[0,1400,2800].every(function(x){return up.some(function(u){return Math.abs(u.x-x)<.1&&Math.abs(u.w-1340)<.1})});
          return JSON.stringify({done:done,latFora:!!m.latFora,lat:g('Lateral esquerda'),gl:g('Lateral de gaveta'),fundo:fund?fund.cl+'x'+fund.cw:'',cl:cl,trans:trans,polys:polys,okRow:okRow,up:up.length,errs:__errs});
          """#)
        XCTAssertEqual(o["done"] as? Bool, true, "assistente tem o passo final")
        XCTAssertEqual(o["latFora"] as? Bool, true, "módulo novo nasce com laterais por fora (do assistente)")
        XCTAssertEqual(o["lat"] as? String, "805x560", "lateral inteira do chão (até o piso) ao topo da caixa")
        XCTAssertEqual(o["gl"] as? String, "460x110", "lateral da gaveta = frente 170 − 60 · comprimento pela regra (caixote > 470 → 460)")
        XCTAssertEqual(o["fundo"] as? String, "533x460", "fundo = caixa 544 − 30 + 2 × 8 + 2 × 1,5")
        XCTAssertEqual(o["cl"] as? String, "460x110,533x460", "plano de corte segue os ajustes do assistente")
        XCTAssertEqual(o["trans"] as? Int, 0, "planta em ângulo: nenhuma face de módulo transparente (portas/frentes opacas)")
        XCTAssertGreaterThan(o["polys"] as? Int ?? 0, 10, "planta em ângulo desenha o módulo")
        XCTAssertEqual(o["okRow"] as? Bool, true, "completar acima faz a fileira inteira com a mesma divisão")
        XCTAssertEqual(o["up"] as? Int, 3, "3 colunas, uma placa de 1700 cada até o teto")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPortaDeCantoMarcacaoEmTodaPortaELixoApagaDivisoriaOuPortas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;var all=TPL.concat(CATS.flatMap(function(c){return c.it})).filter(function(i){return i.w&&i.v});var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          /* porta de canto: folha do fundo = vão − 10, folha do lado = vão − 15, altura vão + 30 */newTpl(T('Canto em L (base)'));var c=S.mods[0];draw();var P=partsOf(c),e=c.esp,D=c.d+(c.fundo?(c.fundoMm||6):0),W2=Math.max(c.d+200,c.cw2||900),ds=P.filter(function(p){return p.name==='Porta'});var canto=ds.map(function(p){return p.cl+'x'+p.cw}).join(','),esp=(Math.round((c.w-e-D-12.9)*10)/10)+'x650,'+(W2-e-D-10)+'x650';/* dobradiça 165°: fundo = vão − 12,9 (3,4 mm da folha do lado) · lado = vão − 10 (3 mm do armário) *//* folha do fundo = vão − 10 (0,5 mm de folga da folha do lado), folha do lado = vão − 15 */
          /* toda porta tem marcação (dobradiça ou roldana) */var tot=0,ok=0;all.forEach(function(t){S.mods=[];try{newTpl(JSON.parse(JSON.stringify(t)))}catch(_){return}var m=S.mods[0];if(!m)return;partsOf(m).forEach(function(p){if(!/^Porta/.test(p.name)||p.glass||p.noCut)return;tot++;if(p.fur)ok++})});
          /* 🗑 apaga só a divisória selecionada; 🗑 na porta tira as portas do vão */S.mods=[];newTpl(T('Rack de TV'));var m=S.mods[0];S.m=m;draw();var d0=m.div.length,v0=m.v.length;window.DIVI=1;LAST='div';$('delMod').click();var d1=m.div.length,v1=m.v.length,n1=S.mods.length;S.sv=0;LAST='porta';$('delMod').click();var k0=m.v[0].k,n2=S.mods.length;
          var cat=CATS.filter(function(q){return q.id==='painel'})[0].it.some(function(i){return /superior livre/.test(i.n)});
          return JSON.stringify({canto:canto,esp:esp,tot:tot,ok:ok,d:d0+'>'+d1,v:v0+'>'+v1,mods:n1+'/'+n2,k0:k0,cat:cat,errs:__errs});
          """#)
        XCTAssertEqual(o["canto"] as? String, o["esp"] as? String, "porta de canto (165°): vão − 12,9 e vão − 10, altura do vão + 30")
        XCTAssertEqual(o["ok"] as? Int, o["tot"] as? Int, "toda porta (abrir, basculante, camarão, canto, correr) tem marcação no plano")
        XCTAssertGreaterThan(o["tot"] as? Int ?? 0, 90, "auditou o catálogo inteiro")
        XCTAssertEqual(o["d"] as? String, "2>1", "🗑 com divisória selecionada apaga só ela")
        XCTAssertEqual(o["v"] as? String, "3>2", "os dois vãos viram um")
        XCTAssertEqual(o["mods"] as? String, "1/1", "o módulo pronto continua (não apaga o módulo)")
        XCTAssertEqual(o["k0"] as? String, "free", "🗑 na porta tira as portas do vão")
        XCTAssertEqual(o["cat"] as? Bool, true, "painel/home tem módulo superior livre")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPortaBasculanteAbreParaBaixoOuCimaNo2DENo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='sala';S.W=3200;S.H=2600;S.Hm=1;S.Wm=1;newTpl(4);var m=S.mods[0];m.w=1700;m.h=230;m.d=300;m.b=1500;m.div=[1/3,2/3];
          m.v=[{k:'door',n:1,cava:true,open:1},{k:'door',n:1,cava:true,bas:true,bd:'down',open:1},{k:'door',n:1,cava:true,bas:true,bd:'up',open:1}];S.m=m;draw();
          var paths=[].map.call(document.querySelectorAll('#svg #mod path[fill="#e6d9be"]'),function(p){var d=p.getAttribute('d').match(/-?[\d.]+/g).map(Number);var xs=[d[0],d[2],d[4],d[6]],ys=[d[1],d[3],d[5],d[7]];return (Math.max.apply(null,xs)-Math.min.apply(null,xs))>(Math.max.apply(null,ys)-Math.min.apply(null,ys))?'deitada':'em pé'});
          open3D();var B=__boxes();var d3=B.filter(function(b){return /^0:Porta$/.test(String(b.nm))&&!b.nol&&(b.y1-b.y0)>12&&((b.x1-b.x0)>300||(b.z1-b.z0)>300)}).map(function(b){return b.vi+':'+((b.pf&&b.pf.ax==='x')?'gira-eixo-x':'lado')+':'+Math.round(b.y1-b.y0)});
          return JSON.stringify({p2d:paths.join(','),d3:d3.join(','),errs:__errs});
          """#)
        XCTAssertEqual(o["p2d"] as? String, "em pé,deitada,deitada", "2D: porta de lado abre pro lado; basculante abre pra baixo/cima (faixa deitada)")
        XCTAssertEqual(o["d3"] as? String, "0:lado:230,1:gira-eixo-x:15,2:gira-eixo-x:15", "3D: basculante gira no eixo horizontal (fica deitada), a comum gira de lado (porta inteira, cava a 30° liso num sólido só, sem degraus)")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Tamponamento total = moldura de 4 réguas de 80 (frente, trás e as duas pontas) no 3D e no corte · cor amadeirada com veio no 3D e nas bolinhas ·
    /// 🖌 Pintar no 3D: pinta só a peça tocada (3D, 2D e plano de corte NA COR), por tipo, e tira · opção de desligar o tamponamento automático
    func testMolduraDoTamponamentoVeioDaMadeiraPincelEAutoTamponamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;STD().latPiso='sim';/* confere o jeito "até o piso" (o padrão agora é em cima do rodapé) */S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;newTpl(3);var m=S.mods[0];m.w=1400;m.x=500;m.tl=m.tr=true;m.tlW=30;m.trW=30;m.tlM=m.trM=1;m.corF='#b98d5b';m.corFN='Carvalho Hanover';S.m=m;draw();open3D();
          var B=__boxes(),eng=B.filter(function(b){return /Tamponamento esquerdo · engrosso 80#/.test(String(b.pk||''))}).map(function(b){return String(b.pk).replace(/^.*#/,'')+':'+[b.x1-b.x0,b.y1-b.y0,b.z1-b.z0].map(Math.round).join('x')}).sort().join(',');
          var cl=cutLines(m).filter(function(l){return /engrosso/.test(l.name||'')}).map(function(l){return l.L+'x'+l.W+'x'+l.qty}).join(',');
          var tx=B.filter(function(b){return /^0:Porta$/.test(String(b.nm))&&(b.x1-b.x0)>300&&!b.nol}).map(function(b){return __matTx(b)}).join(',');
          var sw=/data-bg="cores\/arauco-louro-freijo-trend\.jpg"/.test(swRow('corF',''))&&!/sem textura/.test(swRow('corF',''));
          pt3(true);var on=__pt3state().on&&!document.getElementById('pt3').hidden&&document.querySelectorAll('#pt3 [data-ptc]').length>=20;
          window.PT3={c:'#6b4a2f',n:'Nogueira',erase:false};__pt3pick(0,'Fundo#1','one');
          var fb=__boxes().filter(function(b){return /^0:Fundo$/.test(String(b.nm))})[0],fc=fb?fb.c.join()+'/'+__matTx(fb):'';
          var fl=cutLines(m).filter(function(l){return /^Fundo/.test((l.names||[])[0]||'')}).map(function(l){return l.fin+':'+(l.names||[]).join('/')}).join(',');
                    __pt3pick(0,'Porta#1','type');var fp=partsOf(m).filter(function(p){return p.name==='Porta'})[0];paintCol(m,fp);var f2=fp.col;var pt=m.pcT&&m.pcT.Porta&&m.pcT.Porta.n,pb=__boxes().filter(function(b){return /^0:Porta$/.test(String(b.nm))&&(b.x1-b.x0)>300&&!b.nol}).map(function(b){return b.c.join()}).join(',');
          window.PT3={c:'',n:'Tirar',erase:true};__pt3pick(0,'Fundo#1','one');var fb2=__boxes().filter(function(b){return /^0:Fundo$/.test(String(b.nm))})[0],fc2=fb2?fb2.c.join():'';
          pt3(false);var off=!__pt3state().on&&document.getElementById('pt3').hidden;document.getElementById('v3x').click();
          S.mods=[];newTpl(3);var a=S.mods[0];a.x=800;draw();var at1=[!!a.tl,!!a.tr,!!a.tlAuto].join();var s=STD();s.autoTamp=0;prSave();draw();var at0=[!!a.tl,!!a.tr].join();s.autoTamp=1;prSave();draw();var at2=[!!a.tl,!!a.tr].join();
          document.getElementById('prb').click();var chips=document.querySelectorAll('#stdm [data-std="autoTamp"]').length;document.getElementById('stdm').hidden=true;
          return JSON.stringify({eng:eng,cl:cl,tx:tx,sw:sw,on:on,fc:fc,fl:fl,f2:f2,pt:pt,pb:pb,fc2:fc2,off:off,at1:at1,at0:at0,at2:at2,chips:chips,errs:__errs});
          """#)
        XCTAssertEqual(o["eng"] as? String, "1:15x820x80,2:15x820x80,3:15x80x425,4:15x80x425", "3D: 4 réguas de 80 por camada — frente, trás e as duas pontas (tamponamento rente com a lateral: 585 − 160 = 425)")
        XCTAssertEqual(o["cl"] as? String, "820x80x4,425x80x4", "corte: 2 réguas no comprimento (até o piso, junto com as laterais) + 2 nas pontas, por lado")
        XCTAssertEqual(o["tx"] as? String, "5,5", "portas na cor amadeirada ganham veio no 3D")
        XCTAssertEqual(o["sw"] as? Bool, true, "bolinhas amadeiradas mostram a textura real do padrão")
        XCTAssertEqual(o["on"] as? Bool, true, "🖌 Pintar abre a paleta com todas as cores")
        XCTAssertEqual(o["fc"] as? String, "107,74,47/5", "fundo pintado de Nogueira no 3D, com veio")
        XCTAssertEqual(o["fl"] as? String, "c:Fundo · Nogueira", "plano de corte: fundo pintado vira NA COR com o nome da cor")
        XCTAssertEqual(o["f2"] as? String, "#6b4a2f", "2D: porta pintada (paintCol)")
        XCTAssertEqual(o["pt"] as? String, "Nogueira", "por tipo: todas as portas do módulo")
        XCTAssertEqual(o["pb"] as? String, "107,74,47,107,74,47", "as duas portas pintadas")
        XCTAssertEqual(o["fc2"] as? String, "244,242,238", "tirar a pintura volta pro branco")
        XCTAssertEqual(o["off"] as? Bool, true)
        XCTAssertEqual(o["at1"] as? String, "true,true,true", "ponta exposta ganha tamponamento sozinha")
        XCTAssertEqual(o["at0"] as? String, "false,false", "automático desligado nos ajustes: tira os automáticos")
        XCTAssertEqual(o["at2"] as? String, "true,true", "ligando de novo, volta")
        XCTAssertEqual(o["chips"] as? Int, 2, "opção nos ajustes (seção e assistente)")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Paleta real (Arauco, Duratex, Greenplac) com nome · marca · textura, 🔍 procurar cor no painel e no pincel do 3D,
    /// peça pintada/colorida sai NA COR com o nome da cor, e cada cor vira a sua chapa no plano (tamponamento Louro Freijó → chapa Louro Freijó)
    func testPaletaRealComBuscaEChapaPorCor() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;newTpl(3);var m=S.mods[0];m.tl=m.tr=true;m.tlW=30;m.trW=30;m.tlM=m.trM=1;S.m=m;draw();window.__cores('port');S.tab=10;panel();
          var n=[].filter.call(document.querySelectorAll('[data-csl="corF"] [data-cs]'),function(b){return !!b.title}).length,q=document.querySelector('[data-csq="corF"]');q.value='louro freij';q.dispatchEvent(new Event('input',{bubbles:true}));
          var vis=[].filter.call(document.querySelectorAll('[data-csl="corF"] [data-cs]'),function(b){return !b.hidden}).map(function(b){return b.title});
          document.querySelector('[data-csl="corF"] [data-cs*="arauco-louro-freijo-trend"]').click();m=S.mods[0];
          var cs=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];newTpl(4);var a=S.mods[1];a.corF=cs.hex;a.corFN=matLabel(cs);a.corFId=cs.id;a.cor=cs.hex;a.corN=matLabel(cs);a.corId=cs.id;draw();
          var cl=cutLines(m).filter(function(l){return /^Tamponamento esquerdo · face/.test(l.name||'')}).map(function(l){return l.fin+':'+l.colN})[0];
          var pl=sheetPlan().groups.map(function(g){return g.t+'|'+g.colN});
          openCut();var heads=[].map.call(document.querySelectorAll('#cutbody div'),function(d){return d.textContent}).filter(function(t){return /^🎨 CHAPA [A-Z]/.test(t)&&!/chapa \d/.test(t)});
          var rows=[].map.call(document.querySelectorAll('#cutbody tr'),function(r){return r.textContent.replace(/\s+/g,' ').trim()}).filter(function(t){return /^Chapa MDF 15 mm ·/.test(t)}).map(function(t){return t.replace(/\d+% aproveit\..*$/,'').trim()});
          document.getElementById('cutm').hidden=true;
          open3D();pt3(true);var pq=document.querySelector('#pt3 [data-csq]');pq.value='cinza';pq.dispatchEvent(new Event('input',{bubbles:true}));
          var pvis=[].filter.call(document.querySelectorAll('#pt3 [data-ptc]'),function(b){return !b.hidden}).map(function(b){return b.title});
          window.PT3={c:cs.hex,n:matLabel(cs),id:cs.id,erase:false};__pt3pick(0,'Porta#1','one');var pc=m.pc['Porta#1'].id,pcl=cutLines(m).filter(function(l){return /^Porta/.test((l.names||[])[0]||'')}).map(function(l){return l.fin+':'+l.colN+':'+l.qty});
          pt3(false);document.getElementById('v3x').click();
          return JSON.stringify({n:n,vis:vis,corF:m.corF,corFN:m.corFN,corFId:m.corFId,cl:cl,pl:pl,heads:heads,rows:rows,pvis:pvis,pc:pc,pcl:pcl,errs:__errs});
          """#)
        XCTAssertEqual(o["n"] as? Int, 197, "197 padrões reais na paleta (Arauco 74, Duratex 71, Greenplac 52), agrupados por marca")
        XCTAssertEqual(o["vis"] as? [String], ["Louro Freijó · Arauco Trend", "Louro Freijó · Arauco Poro"], "🔍 'louro freij' acha os dois Louro Freijó")
        XCTAssertEqual(o["corFId"] as? String, "arauco-louro-freijo-trend")
        XCTAssertEqual(o["corFN"] as? String, "Louro Freijó · Arauco Trend", "nome real: padrão · fabricante · textura")
        XCTAssertEqual(o["cl"] as? String, "c:Louro Freijó · Arauco Trend", "tamponamento em Louro Freijó → peça NA COR Louro Freijó")
        XCTAssertEqual(o["pl"] as? [String], ["b|", "c|Cinza Sagrado · Duratex Essencial Acetinada", "c|Louro Freijó · Arauco Trend", "f|"], "uma chapa por cor no plano")
        XCTAssertEqual(o["heads"] as? [String], ["🎨 CHAPA CINZA SAGRADO · DURATEX ESSENCIAL ACETINADA · MDF 15 mm", "🎨 CHAPA LOURO FREIJÓ · ARAUCO TREND · MDF 15 mm"], "cabeçalho da chapa com o nome da cor")
        XCTAssertEqual(o["rows"] as? [String], ["Chapa MDF 15 mm · Cinza Sagrado · Duratex Essencial Acetinada", "Chapa MDF 15 mm · Louro Freijó · Arauco Trend"], "material: uma linha por cor")
        XCTAssertEqual(o["pvis"] as? [String], ["Cinza Puro · Arauco Matt", "Cinza Cristal · Arauco TX", "Cinza Sagrado · Duratex Essencial Acetinada", "Cinza Fóssil · Duratex Velluto", "Cinza Cristal · Greenplac Clássicos"], "🔍 no pincel do 3D acha em todas as marcas")
        XCTAssertEqual(o["pc"] as? String, "duratex-cinza-sagrado-essencial", "pintura guarda o padrão")
        XCTAssertEqual(o["pcl"] as? [String], ["c:Cinza Sagrado · Duratex Essencial Acetinada:1", "c:Louro Freijó · Arauco Trend:1"], "porta pintada separa da outra no corte, cada uma na sua cor")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Regras novas nos Ajustes (valem pros módulos novos e "aplicar a todos"): recuo do rodapé, avanço do tamponamento, recuo da prateleira,
    /// corrediça pela profundidade, frente de gaveta sobe separado, porta de correr (sobreposição/folga/altura), arredondamento, peça máxima,
    /// Sistema 32 no plano e padrão de cor real dos módulos novos
    func testAjustesNovosRodapeTamponamentoPrateleiraCorredicaCorrerSistema32ECorPadrao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
          var st=STD(),keep=JSON.stringify(st);
          /* 1) valores novos nos ajustes (rodapé por baixo das laterais pra conferir o rodapé lateral) */st.latPiso='nao';st.rodRec=50;st.tpAv=40;st.pm=40;st.corrDsc=50;st.corrStep=50;st.gUp=10;st.frUp=5;st.pcSob=40;st.pcW=20;st.pcH=40;st.s32=1;st.s32Off=37;st.s32Step=32;st.rnd=1;st.pcMax=2000;
          var lf=MAT.filter(function(c){return c.id==='arauco-louro-freijo-trend'})[0],cs=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];st.corFDef=lf.id;st.corDef=cs.id;prSave();
          newTpl(3);var m=S.mods[0];m.d=590;m.tl=true;m.tlM=1;m.tlW=30;m.v=[{k:'drawers',n:2,cava:true}];S.m=m;draw();
          var P=partsOf(m),g=function(re){return P.filter(function(p){return re.test(p.name)})[0]||{}};
          var rl=g(/^Rodapé lateral esquerdo/),tp=g(/^Tamponamento esquerdo/),fr=P.filter(function(p){return /^Frente de gaveta/.test(p.name)}),gb=gbox(m.v[0],vaoRanges(m)[0][1]-vaoRanges(m)[0][0],drawerH(m.v[0]),m.d),lat=g(/^Lateral esquerda$/);
          var cor={corF:m.corF,corFId:m.corFId,corN:m.corN,corId:m.corId};
          open3D();var B=__boxes(),rb=B.filter(function(b){return /^0:Rodapé \(pedestal\)$/.test(String(b.nm))})[0],tb=B.filter(function(b){return /^0:Tamponamento esquerdo$/.test(String(b.nm))&&!b.pk.match(/engrosso|régua/)})[0];document.getElementById('v3x').click();
          /* 2) prateleira, porta de correr e peça máxima */S.mods=[];newTpl(5);var n2=S.mods[0];n2.v=[{k:'shelves',n:1}];n2.d=400;draw();var sh=partsOf(n2).filter(function(p){return p.name==='Prateleira'})[0]||{};
          S.mods=[];newTpl(1);var n3=S.mods[0];n3.div=[];n3.v=[{k:'slide',n:2}];n3.w=1800;draw();var vr=vaoRanges(n3)[0],vw=vr[1]-vr[0],sl=partsOf(n3).filter(function(p){return p.name==='Porta de correr'})[0]||{};
          S.mods=[];newTpl(3);newTpl(3);newTpl(3);S.mods.forEach(function(q,i){q.x=i*900;q.w=900;q.b=0;q.sup=false;q.rod=true;q.tb=false});draw();var runs=moldRuns('rod').map(function(r){return r.idx.length});
          /* 3) sistema 32 no plano */var s32=lat.fur&&lat.fur.kind,s32n=lat.fur&&lat.fur.n,s32rows=lat.fur&&lat.fur.rows;
          S.mods=[];newTpl(3);S.m=S.mods[0];draw();openCut();await new Promise(function(r){var t0=Date.now();(function w(){var b=(document.getElementById('cutopt')||{}).textContent||'';if(b.indexOf('✓')>=0||Date.now()-t0>30000)r();else setTimeout(w,100)})()});
          var svg=document.getElementById('cutbody').innerHTML,circ=(svg.match(/stroke="#1f7a4d"/g)||[]).length,txt32=/sistema 32/.test(svg);document.getElementById('cutm').hidden=true;
          /* 4) campos nos ajustes */document.getElementById('prb').click();var ids=['tpAv','rodRec','pm','corrDsc','gUp','pcSob','pcW','pcH','pcMax','s32Off','s32Step'].filter(function(k){return !document.querySelector('#stdm [data-stdn="'+k+'"]')}),chips=['s32','rnd','corrStep'].filter(function(k){return !document.querySelector('#stdm [data-std="'+k+'"]')}),mats=document.querySelectorAll('#stdm [data-stdmat^="corFDef|"]').length;
          var mq=document.querySelector('#stdm [data-csq="stdcorDef"]');mq.value='sagrado';mq.dispatchEvent(new Event('input',{bubbles:true}));var mvis=[].filter.call(document.querySelectorAll('#stdm [data-csl="stdcorDef"] [data-stdmat]'),function(b){return !b.hidden}).map(function(b){return b.title});
          document.getElementById('stdm').hidden=true;
          /* volta os ajustes */PR.std=JSON.parse(keep);prSave();
          return JSON.stringify({rl:rl.cl,tp:tp.cw,frY:fr.map(function(p){return p.upMm}),nl:gb.nl,cor:cor,rbZ:rb?Math.round(rb.z0):null,rbD:rb?Math.round(rb.z1-rb.z0):null,tbZ:tb?Math.round(tb.z1):null,sh:sh.cw,slW:sl.cl,slH:sl.cw,vw:vw,runs:runs,s32:s32,s32n:s32n,s32rows:s32rows,circ:circ,txt32:txt32,ids:ids,chips:chips,mats:mats,mvis:mvis,rnd:[rl.cl,tp.cw,lat.cl,lat.cw].every(function(v){return v===Math.round(v)}),errs:__errs});
          
          """#)
        XCTAssertEqual(o["rl"] as? Double, 460, "rodapé lateral = prof 590 − 2 × recuo 50 − 2 × 15")
        XCTAssertEqual(o["tp"] as? Double, 630, "tamponamento = prof 590 + avanço 40 (rente com a lateral atrás; o fundo sobreposto só soma com a opção “Cobre o fundo” nos Ajustes)")
        XCTAssertEqual(o["frY"] as? [Double], [10, 10], "frentes de gaveta sobem 10 (separado das portas, 5)")
        XCTAssertEqual(o["nl"] as? Double, 450, "regra: caixote 590 (> 470) → lateral 460, corrediça de 450")
        XCTAssertEqual((o["cor"] as? [String: Any])?["corFId"] as? String, "arauco-louro-freijo-trend", "módulo novo já vem com o padrão das frentes")
        XCTAssertEqual((o["cor"] as? [String: Any])?["corId"] as? String, "duratex-cinza-sagrado-essencial", "e com o padrão do caixote")
        XCTAssertEqual(o["sh"] as? Double, 360, "prateleira = prof 400 − recuo 40")
        XCTAssertEqual(o["slW"] as? Double, 915, "porta de correr = (vão 1770 + 20 + 40) ÷ 2")
        XCTAssertEqual(o["slH"] as? Double, 2310, "folha = vão + 40 de altura")
        XCTAssertEqual(o["runs"] as? [Int], [2, 1], "peça corrida máxima 2000: 3 módulos de 900 viram 2 + 1")
        XCTAssertEqual(o["s32"] as? String, "s32", "lateral com Sistema 32")
        XCTAssertEqual(o["s32rows"] as? [Double], [37, 553], "fileiras a 37 mm da frente e de trás (prof 590)")
        XCTAssertGreaterThan(o["circ"] as? Int ?? 0, 40, "furos desenhados no plano de corte")
        XCTAssertEqual(o["txt32"] as? Bool, true)
        XCTAssertEqual(o["ids"] as? [String], [], "todos os campos novos nos Ajustes")
        XCTAssertEqual(o["chips"] as? [String], [], "chips s32 / arredondamento / passo da corrediça")
        XCTAssertEqual(o["mats"] as? Int, 198, "paleta real do padrão (197 + sem padrão)")
        XCTAssertEqual(o["mvis"] as? [String], ["Cinza Sagrado · Duratex Essencial Acetinada"], "🔍 no padrão de cor dos Ajustes")
        XCTAssertEqual(o["rnd"] as? Bool, true, "arredondamento em 1 mm")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Fita de topo do caixote branco na cor das portas (branca só em prateleira, gaveta e porta tempero · editável nos Ajustes),
    /// pincel: 💧 copiar a cor de uma peça e pintar só a fita de topo · tudo vai pro plano de corte (nome da cor da fita)
    func testFitaDeTopoNaCorDasPortasContaGotasEPintarSoAFita() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;
          newTpl(3);var m=S.mods[0];newTpl(5);var e=S.mods[1];S.m=m;draw();panel();
          var cum=MAT.filter(function(c){return /cumaru/i.test(c.n)})[0],cz=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];
          var white=['Prateleira','Lateral de gaveta','Base (porta tempero)','Lateral esquerda','Base inferior','Divisória 1','Porta'].map(function(n){return n+':'+fitaWhite(n)});
          m.pcT={Porta:{c:cum.hex,n:matLabel(cum),id:cum.id}};e.pcT={Porta:{c:cum.hex,n:matLabel(cum),id:cum.id}};
          open3D();
          var fts=function(mi){var o={};__boxes().forEach(function(b){if(!b.ft||(mi!==undefined&&String(b.nm).split(':')[0]!==String(mi)))return;var nm=String(b.nm).split(':')[1].replace(/#\d+$/,'');var hx='#'+b.c.slice(0,3).map(function(n){return ('0'+Math.round(n).toString(16)).slice(-2)}).join('');o[nm]=o[nm]||{};o[nm][hx+(b.mid?'|'+b.mid:'')]=1});var r={};Object.keys(o).forEach(function(k){r[k]=Object.keys(o[k]).join(',')});return r};
          var f1=fts(),cut1=cutLines(m).filter(function(l){return /^(Lateral esquerda|Base inferior)/.test((l.names||[])[0]||'')}).map(function(l){return (l.names||[])[0]+'='+(l.ftN||'-')+'/'+l.fin});
          STD().fitaB='gav,temp,div';__build();var f2=fts()['Prateleira'],cut2=cutLines(e).filter(function(l){return /^Prateleira/.test((l.names||[])[0]||'')}).map(function(l){return l.ftN||'-'})[0];STD().fitaB='prat,gav,temp';
          m.cor=cz.hex;m.corN=matLabel(cz);m.corId=cz.id;STD().fitaCor='fora';__build();var f3=fts(0)['Lateral direita'];STD().fitaCor='portas';__build();var f3b=fts(0)['Lateral direita'];delete m.cor;delete m.corN;delete m.corId;
          pt3(true);window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};__pt3pick(0,'Lateral esquerda#1','fita');
          var pf=m.pf['Lateral esquerda#1'].id,lat=(function(){var b=__boxes().filter(function(b){return !b.ft&&/^0:Lateral esquerda/.test(b.nm)})[0];return '#'+b.c.slice(0,3).map(function(n){return ('0'+Math.round(n).toString(16)).slice(-2)}).join('')})();
          var cut4=cutLines(m).filter(function(l){return /^Lateral esquerda/.test((l.names||[])[0]||'')}).map(function(l){return (l.ftN||'-')+'×'+l.qty}).sort();
          window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};__pt3pick(0,'Base inferior#1','fitaMod');var pfM=m.pfM.id+'|'+(m.pf===undefined),f5=fts(0)['Base inferior'];
          window.PT3={c:'',n:'Tirar pintura',erase:true};__pt3pick(0,'Base inferior#1','fitaMod');var f6=fts(0)['Base inferior'];
          var pb=__boxes().filter(function(b){return !b.ft&&/^0:Porta/.test(b.nm)&&b.a>=.95})[0],pick=__pt3pickCol(pb);
          document.querySelector('#pt3 [data-ptk]').click();var pickOn=__pt3state().pick,hdr=document.querySelector('#pt3 [data-pth]').textContent;
          pt3(false);document.getElementById('v3x').click();
          stdOpen(0,'chapa');var chips=[].map.call(document.querySelectorAll('#stdm [data-stdm="fitaB"]'),function(b){return b.dataset.v+':'+b.classList.contains('on')}),chipCor=[].map.call(document.querySelectorAll('#stdm [data-std="fitaCor"]'),function(b){return b.dataset.v+':'+b.classList.contains('on')});
          document.querySelector('#stdm [data-stdm="fitaB"][data-v="div"]').click();var after=STD().fitaB;document.querySelector('#stdm [data-stdm="fitaB"][data-v="div"]').click();var after2=STD().fitaB;
          openCut();var txt=document.getElementById('cutbody').textContent.replace(/\s+/g,' ');var fitaTxt=(txt.match(/fita: Cumaru · Arauco Trend/g)||[]).length,fitaRow=(txt.match(/branco · fita Cumaru · Arauco Trend/g)||[]).length;document.getElementById('cutm').hidden=true;
          return JSON.stringify({white:white,f1:f1,cut1:cut1,f2:f2,cut2:cut2,f3:f3,f3b:f3b,pf:pf,lat:lat,cut4:cut4,pfM:pfM,f5:f5,f6:f6,pick:pick,pickOn:pickOn,hdr:hdr,chips:chips,chipCor:chipCor,after:after,after2:after2,fitaTxt:fitaTxt,fitaRow:fitaRow,errs:__errs});
          """#)
        XCTAssertEqual(o["white"] as? [String], ["Prateleira:true", "Lateral de gaveta:true", "Base (porta tempero):true", "Lateral esquerda:false", "Base inferior:false", "Divisória 1:false", "Porta:false"], "fita branca só em prateleira, gaveta e porta tempero")
        let f1 = o["f1"] as? [String: String] ?? [:]
        XCTAssertEqual(f1["Lateral esquerda"], "#b49c7d|arauco-cumaru-trend", "caixote branco com portas Cumaru → fita da lateral em Cumaru (com a textura)")
        XCTAssertEqual(f1["Base inferior"], "#b49c7d|arauco-cumaru-trend")
        XCTAssertEqual(f1["Base superior"], "#b49c7d|arauco-cumaru-trend")
        XCTAssertEqual(f1["Prateleira"], "#f4f2ee", "prateleira com fita branca")
        XCTAssertNil(f1["Tamponamento direito"], "tamponamento não ganha fita por cima")
        XCTAssertEqual(o["cut1"] as? [String], ["Base inferior=Cumaru · Arauco Trend/b", "Lateral esquerda=Cumaru · Arauco Trend/b"], "plano de corte: peça branca com o nome da cor da fita")
        XCTAssertEqual(o["f2"] as? String, "#b49c7d|arauco-cumaru-trend", "Ajustes: desmarcando prateleira, a fita dela vai na cor")
        XCTAssertEqual(o["cut2"] as? String, "Cumaru · Arauco Trend")
        XCTAssertEqual(o["f3"] as? String, "#716c69|duratex-cinza-sagrado-essencial", "fita na cor de fora do caixote quando configurado")
        XCTAssertEqual(o["f3b"] as? String, "#b49c7d|arauco-cumaru-trend", "fita na cor das portas (padrão)")
        XCTAssertEqual(o["pf"] as? String, "duratex-cinza-sagrado-essencial", "pintar só a fita guarda o padrão")
        XCTAssertEqual(o["lat"] as? String, "#f4f2ee", "a peça fica como está (branca)")
        XCTAssertEqual(o["cut4"] as? [String], ["Cinza Sagrado · Duratex Essencial Acetinada×1", "Cumaru · Arauco Trend×1"], "lateral com fita pintada separa da outra no corte")
        XCTAssertEqual(o["pfM"] as? String, "duratex-cinza-sagrado-essencial|true", "fitas do módulo inteiro (tira as por peça)")
        XCTAssertEqual(o["f5"] as? String, "#716c69|duratex-cinza-sagrado-essencial")
        XCTAssertEqual(o["f6"] as? String, "#b49c7d|arauco-cumaru-trend", "tirar a pintura das fitas volta pro padrão")
        let pick = o["pick"] as? [String: Any] ?? [:]
        XCTAssertEqual(pick["id"] as? String, "arauco-cumaru-trend", "💧 copia o padrão real da porta")
        XCTAssertEqual(pick["n"] as? String, "Cumaru · Arauco Trend")
        XCTAssertEqual(o["pickOn"] as? Bool, true)
        XCTAssertEqual(o["hdr"] as? String, "💧 toque na peça pra copiar")
        XCTAssertEqual(o["chips"] as? [String], ["prat:true", "gav:true", "temp:true", "div:false", "cx:false"], "chips da fita branca nos Ajustes")
        XCTAssertEqual(o["chipCor"] as? [String], ["portas:true", "fora:false"])
        XCTAssertEqual(o["after"] as? String, "prat,gav,temp,div")
        XCTAssertEqual(o["after2"] as? String, "prat,gav,temp")
        XCTAssertGreaterThan(o["fitaTxt"] as? Int ?? 0, 0, "coluna Fita do plano mostra a cor")
        XCTAssertGreaterThan(o["fitaRow"] as? Int ?? 0, 0, "lista geral mostra a cor da fita")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Abrir a porta não muda a cor de nada: tamponamento, engrosso e réguas seguem a cor das portas (pintadas pelo pincel) com a porta fechada,
    /// abrindo e fechando de novo · no plano de corte também · tocar na fita de topo abre o diálogo pela fita e, pintando uma, pergunta pelas outras
    func testAcabamentoNaoMudaAoAbrirPortaEFitaPeloToque() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;S.Hm=1;S.Wm=1;
          newTpl(4);var m=S.mods[0];m.v=[{k:'door',n:1,cava:true,bas:true,bd:'up',open:0}];m.tb=true;m.regua=true;m.regN=2;m.regMm=70;m.tl=true;m.tlW=30;m.tlM=1;S.m=m;draw();panel();
          var jat=MAT.filter(function(c){return /jatob/i.test(c.n)})[0];m.pcT={Porta:{c:jat.hex,n:matLabel(jat),id:jat.id}};
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();
          var col=function(){var o={};__boxes().forEach(function(b){if(!/^0:(Tamponamento|Engrosso|Porta)/.test(b.nm)||b.ft)return;var nm=String(b.nm).split(':')[1].replace(/#\d+$/,'');var hx='#'+b.c.slice(0,3).map(function(n){return ('0'+Math.round(n).toString(16)).slice(-2)}).join('');o[nm]=o[nm]||{};o[nm][hx+'|'+(b.mid||'-')]=1});var r={};Object.keys(o).forEach(function(k){r[k]=Object.keys(o[k]).join(',')});return r};
          var closed=col();m.v[0].open=1;window.anim3();await new Promise(function(r){setTimeout(r,1600)});var opened=col();m.v[0].open=0;window.anim3();await new Promise(function(r){setTimeout(r,1600)});var closed2=col();
          var cl=cutLines(m).filter(function(l){return /^(Tamponamento|Engrosso)/.test((l.names||[])[0]||'')}).map(function(l){return l.fin+':'+(l.colN||'-')});
          pt3(true);window.PT3={c:jat.hex,n:matLabel(jat),id:jat.id,erase:false};var fb=__boxes().filter(function(b){return b.ft&&/^0:Lateral esquerda/.test(b.nm)})[0];__pt3tapBox(fb);
          var q=document.getElementById('pt3q'),title=q.textContent.replace(/\s+/g,' ').slice(0,90),order=[].map.call(q.querySelectorAll('[data-ptq]'),function(b){return b.dataset.ptq}),pv=__pt3state().pv;
          q.querySelector('[data-ptq="fita"]').click();var same=(document.getElementById('amsg')||{}).textContent||'';
          var cz=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};__pt3tapBox(fb);q=document.getElementById('pt3q');
          q.querySelector('[data-ptq="fita"]').click();var more=q.hidden?'hidden':q.textContent.replace(/\s+/g,' ').slice(0,40),pf1=m.pf['Lateral esquerda#1'].id;
          q.querySelector('[data-ptq="fitaAll"]').click();var pfAll=S.mods.map(function(q){return (q.pfM&&q.pfM.id)||'-'}).join(','),pfGone=m.pf===undefined,hid=q.hidden;
          pt3(false);document.getElementById('v3x').click();
          return JSON.stringify({closed:closed,opened:opened,closed2:closed2,cl:cl,title:title,order:order,pvFita:pv.fita,same:same,more:more,pf1:pf1,pfAll:pfAll,pfGone:pfGone,hid:hid,errs:__errs});
          """#)
        let jat = "#623516|arauco-jatoba-brasileiro-trend"
        for st in ["closed", "opened", "closed2"] {
            let c = o[st] as? [String: String] ?? [:]
            XCTAssertEqual(c["Tamponamento de baixo"], jat, "\(st): tamponamento na cor das portas pintadas, com a textura")
            XCTAssertEqual(c["Tamponamento esquerdo"], jat, st)
            XCTAssertEqual(c["Engrosso cava · régua da frente 1"], jat, "\(st): régua do engrosso cava na cor das portas")
            XCTAssertTrue((c["Porta"] ?? "").hasPrefix(jat), "\(st): porta pintada")
        }
        XCTAssertEqual(o["cl"] as? [String], ["c:Jatobá Brasileiro · Arauco Trend", "c:Jatobá Brasileiro · Arauco Trend", "c:Jatobá Brasileiro · Arauco Trend", "c:Jatobá Brasileiro · Arauco Trend", "c:Jatobá Brasileiro · Arauco Trend"], "plano de corte: tamponamentos e réguas na cor das portas pintadas")
        XCTAssertTrue((o["title"] as? String ?? "").contains("Fita de topo de Lateral esquerda#1"), "\(o["title"] ?? "")")
        XCTAssertEqual(o["order"] as? [String], ["x", "fita", "fitaMod", "fitaAll", "fitaW", "one", "type", "typeAll", "mod", "modIn"], "tocando na fita, as opções de fita vêm primeiro (com a opção de fita branca só nela)")
        XCTAssertEqual(o["pvFita"] as? Bool, true, "prévia só na fita")
        XCTAssertTrue((o["same"] as? String ?? "").contains("já estava"), "fita já na cor das portas: avisa em vez de repetir: \(o["same"] ?? "")")
        XCTAssertTrue((o["more"] as? String ?? "").hasPrefix("Pintar as outras fitas de topo"), "depois de pintar uma fita pergunta pelas outras: \(o["more"] ?? "")")
        XCTAssertEqual(o["pf1"] as? String, "duratex-cinza-sagrado-essencial")
        XCTAssertEqual(o["pfAll"] as? String, "duratex-cinza-sagrado-essencial", "fitas de todos os módulos")
        XCTAssertEqual(o["pfGone"] as? Bool, true, "a pintura por fita sai quando pinta o módulo inteiro")
        XCTAssertEqual(o["hid"] as? Bool, true, "diálogo fecha depois de responder")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Porta de vidro real: 4 réguas de perfil de alumínio na cor escolhida + vidro de 4 mm (reflexo bronze, fumê…) no 3D, fechada, aberta e basculante;
    /// cor do alumínio e do vidro por módulo (aba Portas) e padrão nos Ajustes; o pincel não pinta o perfil; ferragens listam perfil (m) e vidro (m²)
    func testPortaDeVidroComPerfilDeAluminioEVidroBronze() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;S.Hm=1;S.Wm=1;
          newTpl(0);var t=S.mods[0];t.w=600;t.h=2300;t.d=400;t.v=[{k:'door',n:2,vidro:true,open:0}];S.m=t;S.sv=0;S.tab=3;draw();panel();
          var chips=[].map.call(document.querySelectorAll('[data-alcor]'),function(b){return b.dataset.alcor+(b.classList.contains('sel')?'*':'')}).join(',')+' | '+[].map.call(document.querySelectorAll('[data-vicor]'),function(b){return b.dataset.vicor+(b.classList.contains('sel')?'*':'')}).join(',');
          var hw=hwOf(t),hwk=Object.keys(hw).filter(function(k){return /vidro|Vidro/.test(k)}).map(function(k){return k+'='+hw[k].n+hw[k].u});
          var pd=partsOf(t).filter(function(p){return p.glass})[0],p2d=pd.col+'/'+pd.st;
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();
          var snap=function(mi){var gb=__boxes().filter(function(b){return (new RegExp('^'+mi+':Porta')).test(b.nm)});return {n:gb.length,alu:gb.filter(function(b){return b.alu}).map(function(b){return b.c.slice(0,3).join()}).filter(function(v,i,a){return a.indexOf(v)===i}),gl:gb.filter(function(b){return b.gl}).map(function(b){return b.c.slice(0,3).join()+'/'+b.a+'/'+(b.pf?'pf':'box')}).filter(function(v,i,a){return a.indexOf(v)===i})}};
          var s1=snap(0);
          document.getElementById('v3x').click();document.querySelector('[data-alcor="champagne"]').click();document.querySelector('[data-vicor="fume"]').click();var mod=t.alCor+'/'+t.viCor;
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var s2=snap(0);
          var jat=MAT.filter(function(c){return /jatob/i.test(c.n)})[0];t.pcT={Porta:{c:jat.hex,n:matLabel(jat),id:jat.id}};__build();var s3=snap(0);delete t.pcT;
          t.v[0].open=1;window.anim3();await new Promise(function(r){setTimeout(r,1600)});var s4=snap(0);t.v[0].open=0;
          newTpl(4);var a=S.mods[1];a.v=[{k:'door',n:1,vidro:true,bas:true,bd:'up',open:1}];window.anim3();await new Promise(function(r){setTimeout(r,1600)});var sb=snap(1);
          document.getElementById('v3x').click();
          stdOpen(0,'portas');var std=[].map.call(document.querySelectorAll('#stdm [data-std="alCor"]'),function(b){return b.dataset.v+(b.classList.contains('on')?'*':'')}).join(',')+' | '+[].map.call(document.querySelectorAll('#stdm [data-std="viCor"]'),function(b){return b.dataset.v+(b.classList.contains('on')?'*':'')}).join(',');
          document.querySelector('#stdm [data-std="viCor"][data-v="incolor"]').click();var stdAfter=STD().viCor;STD().viCor='bronze';prSave();
          return JSON.stringify({chips:chips,hw:hwk,p2d:p2d,s1:s1,mod:mod,s2:s2,s3:s3,s4:s4,sb:sb,std:std,stdAfter:stdAfter,errs:__errs});
          """#)
        XCTAssertEqual(o["chips"] as? String, "preto*,champagne,prata,bronze,grafite,branco | bronze*,fume,incolor,preto,verde", "aba Portas: cor do perfil e do vidro por módulo")
        XCTAssertEqual(o["hw"] as? [String], ["Perfil de alumínio p/ vidro · Preto fosco (m)=9.96m", "Vidro 4 mm · Reflexo bronze (m²)=1.28m²"], "ferragens: perfil em metros e vidro em m²")
        XCTAssertEqual(o["p2d"] as? String, "#b9a088/#262626", "2D: vidro bronze claro com perfil preto")
        let s1 = o["s1"] as? [String: Any] ?? [:]
        XCTAssertEqual(s1["alu"] as? [String], ["38,38,38"], "perfil preto fosco no 3D")
        XCTAssertEqual(s1["gl"] as? [String], ["91,63,42/0.55/box"], "vidro reflexo bronze (translúcido) fechado")
        XCTAssertEqual(o["mod"] as? String, "champagne/fume")
        let s2 = o["s2"] as? [String: Any] ?? [:]
        XCTAssertEqual(s2["alu"] as? [String], ["201,180,140"], "perfil champagne depois de trocar no painel")
        XCTAssertEqual(s2["gl"] as? [String], ["58,61,66/0.52/box"], "vidro fumê")
        let s3 = o["s3"] as? [String: Any] ?? [:]
        XCTAssertEqual(s3["alu"] as? [String], ["201,180,140"], "o pincel (porta pintada por tipo) não pinta o perfil de alumínio")
        let s4 = o["s4"] as? [String: Any] ?? [:]
        XCTAssertEqual(s4["alu"] as? [String], ["201,180,140"], "porta aberta: perfil continua")
        XCTAssertEqual(s4["gl"] as? [String], ["58,61,66/0.52/pf"], "porta aberta: vidro girado junto")
        let sb = o["sb"] as? [String: Any] ?? [:]
        XCTAssertEqual(sb["n"] as? Int, 5, "basculante de vidro aberta: 4 réguas + 1 vidro")
        XCTAssertEqual((sb["gl"] as? [String])?.count, 1)
        XCTAssertEqual(o["std"] as? String, "preto*,champagne,prata,bronze,grafite,branco | bronze*,fume,incolor,preto,verde", "Ajustes · Portas: padrão do perfil e do vidro")
        XCTAssertEqual(o["stdAfter"] as? String, "incolor")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Eletros vivos: forno embutido no módulo e na torre abre com 1 toque (forno e micro-ondas separados), porta com vidro transparente
    /// mostrando a cavidade (guias, grade, assadeira, lâmpada), luz acende ao abrir ou pelo 💡 · coifa liga luz e motor · TV liga
    func testEletrosVivosFornoMicroCoifaETV() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3600;S.H=2600;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Torre forno + micro-ondas (embutir)'));draw();['forno','coifa','tv'].forEach(function(t){apAdd(t,0)});draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();
          var ov=__boxes().filter(function(b){return /^0:Corte do forno/.test(b.nm)}),mc=__boxes().filter(function(b){return /^0:Corte do micro/.test(b.nm)});
          var glassOv=ov.filter(function(b){return b.gl&&b.a<.6}).length,glassMc=mc.filter(function(b){return b.gl&&b.a<.6}).length,emClosed=ov.filter(function(b){return b.em}).length;
          ele3api.toggle('mo0|0',true);for(var w_=0;w_<60&&ele3api.ang('mo0|0')<1;w_++)await new Promise(function(r){setTimeout(r,100)});
          var ov2=__boxes().filter(function(b){return /^0:Corte do forno/.test(b.nm)}),openOv=ele3api.ang('mo0|0'),micStill=ele3api.ang('mo0|0m')||0,litOv=ele3api.ovLit('mo0|0'),emOpen=ov2.filter(function(b){return b.em}).length,rot=ov2.filter(function(b){return b.pf}).length;
          var tvf=S.fr.filter(function(f){return f.t==='tv'})[0],cof=S.fr.filter(function(f){return f.t==='coifa'})[0],fo=S.fr.filter(function(f){return f.t==='forno'})[0];
          var emOf=function(f){return __boxes().filter(function(b){return b.em&&b.x0>=f.x-5&&b.x1<=f.x+f.w+5&&b.y0>=(f.b||0)-500&&b.y1<=(f.b||0)+f.h+5}).length};
          var e0={tv:emOf(tvf),co:emOf(cof)};ele3api.luz(tvf.id,1);ele3api.luz(cof.id,1);var e1={tv:emOf(tvf),co:emOf(cof)};
          fx3api.open({k:'fr',id:fo.id});var btns=[].map.call(document.querySelectorAll('[data-qfro],[data-qluz]'),function(b){return b.textContent});
          document.getElementById('v3x').click();
          return JSON.stringify({glassOv:glassOv,glassMc:glassMc,emClosed:emClosed,openOv:openOv,micStill:micStill,litOv:litOv,emOpen:emOpen,rot:rot,e0:e0,e1:e1,btns:btns,errs:__errs});
          """#)
        XCTAssertGreaterThanOrEqual(o["glassOv"] as? Int ?? 0, 1, "porta do forno com vidro transparente")
        XCTAssertGreaterThanOrEqual(o["glassMc"] as? Int ?? 0, 1, "janela do micro-ondas transparente")
        XCTAssertEqual(o["openOv"] as? Double, 1, "forno do módulo abre")
        XCTAssertEqual(o["micStill"] as? Double, 0, "micro-ondas da torre não abre junto com o forno")
        XCTAssertEqual(o["litOv"] as? Bool, true, "abriu: a luz de dentro acende")
        XCTAssertGreaterThan(o["emOpen"] as? Int ?? 0, o["emClosed"] as? Int ?? 0, "luz acesa = mais pontos de luz")
        XCTAssertGreaterThan(o["rot"] as? Int ?? 0, 3, "porta girou pra baixo")
        let e0 = o["e0"] as? [String: Int] ?? [:], e1 = o["e1"] as? [String: Int] ?? [:]
        XCTAssertGreaterThan(e1["tv"] ?? 0, e0["tv"] ?? 0, "TV liga a tela")
        XCTAssertGreaterThan(e1["co"] ?? 0, e0["co"] ?? 0, "coifa liga a luz")
        XCTAssertEqual(o["btns"] as? [String], ["💡 Acender a luz de dentro", "🚪 Abrir o forno"], "quadro do forno: luz e porta")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Cava usinada sem faixa preta (só a linha fina de sombra na cor da porta) e com o chanfro na porta aberta ·
    /// pincel: tocar perto da fita de topo (0,8 mm) pega a fita, modo ▭ Fita e 💧 copiando a cor da fita
    func testCavaSemFaixaPretaChanfroNaPortaAbertaEFitaFacilDeTocar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;
          newTpl(4);var m=S.mods[0];m.x=600;var pf=MAT.filter(function(c){return /pau ferro/i.test(c.n)})[0],cz=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];m.corF=pf.hex;m.corFN=matLabel(pf);m.corFId=pf.id;S.m=m;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();
          var cvl=__boxes().filter(function(b){return b.cvl}),cvlH=cvl.map(function(b){return Math.round(b.y1-b.y0)}),dark=__boxes().filter(function(b){return /^0:Porta/.test(b.nm)&&b.c[0]<70&&b.c[1]<70&&b.c[2]<70&&(b.y1-b.y0)>5}).length;
          m.v[0].open=1;window.anim3();await new Promise(function(r){setTimeout(r,1800)});var doorBoxes=__boxes().filter(function(b){return /^0:Porta/.test(b.nm)&&b.pf&&!b.nol}).length;m.v[0].open=0;window.anim3();await new Promise(function(r){setTimeout(r,1800)});
          S.mods=[];newTpl(5);var e=S.mods[0];e.pcT={Porta:{c:pf.hex,n:matLabel(pf),id:pf.id}};S.m=e;draw();__build();pt3(true);
          var fb=__boxes().filter(function(b){return b.ft&&/^0:Base superior/.test(b.nm)})[0],x=0,y=0;[[fb.x0,fb.y0,fb.z1],[fb.x1,fb.y0,fb.z1],[fb.x1,fb.y1,fb.z1],[fb.x0,fb.y1,fb.z1]].forEach(function(c){var p=org3api.proj(c);x+=p[0]/4;y+=p[1]/4});
          window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};paintTap(x,y+7);var pv1=__pt3state().pv;document.getElementById('pt3q').querySelector('[data-ptq="x"]').click();
          document.querySelector('#pt3 [data-ptk]').click();paintTap(x,y+6);var pick=__pt3state().n;
          document.querySelector('#pt3 [data-ptf]').click();var lat=__boxes().filter(function(b){return !b.ft&&/^0:Lateral esquerda/.test(b.nm)})[0],c1=org3api.proj([lat.x0,(lat.y0+lat.y1)/2,(lat.z0+lat.z1)/2]);window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};paintTap(c1[0],c1[1]);var pv2=__pt3state().pv;
          pt3(false);var fmOff=!window.PTFM;document.getElementById('v3x').click();
          return JSON.stringify({cvlH:cvlH,dark:dark,doorBoxes:doorBoxes,pv1:pv1&&(pv1.key+'|'+pv1.fita),pick:pick,pv2:pv2&&(pv2.key+'|'+pv2.fita),fmOff:fmOff,errs:__errs});
          """#)
        XCTAssertEqual(o["dark"] as? Int, 0, "sem faixa preta na porta com cava")
        XCTAssertEqual(o["cvlH"] as? [Int], [3, 3], "só uma linha fina de 3 mm na borda da cava, em cada porta")
        XCTAssertGreaterThan(o["doorBoxes"] as? Int ?? 0, 10, "porta aberta mostra o chanfro da cava (perfil em degraus)")
        XCTAssertEqual(o["pv1"] as? String, "Base superior#1|true", "tocar 7 px ao lado da fita pega a fita, não o fundo")
        XCTAssertEqual(o["pick"] as? String, "Pau Ferro Natural · Duratex Essencial Wood Madeira Leve", "💧 na fita copia a cor da fita (cor das portas)")
        XCTAssertEqual(o["pv2"] as? String, "Lateral esquerda#1|true", "modo ▭ Fita: tocar no meio da lateral pega a fita dela")
        XCTAssertEqual(o["fmOff"] as? Bool, true, "fechar o pincel desliga o modo fita")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Cooktop: 1 toque numa boca acende só ela, sem selecionar o cooktop inteiro · toque no vidro fora das bocas abre o quadro
    func testCooktopToqueNaBocaAcendeSemSelecionar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];S.st.items.push({id:77,k:'cook',x:1500,y:60,w:600,d:500});draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});
          var st=S.st,it=st.items.filter(function(i){return i.id===77})[0],y=st.t+st.e+9,B=cookPos(it).map(function(q){return [st.x+it.x+it.w*q[0],it.y+it.d*q[1]]});
          var p=org3api.proj([B[0][0],y,B[0][1]]);org3api.one(p[0],p[1]);var isx1=org3api.isx(),lit=Object.keys(fx3api.fire()).filter(function(k){var f=fx3api.fire()[k];return f&&!f.off}).length;
          var c=org3api.proj([st.x+it.x+it.w*.5,y,it.y+it.d*.5]);org3api.one(c[0],c[1]);var isx2=org3api.isx()&&org3api.isx().k;
          document.getElementById('v3x').click();
          return JSON.stringify({isx1:isx1,lit:lit,isx2:isx2,errs:__errs});
          """#)
        XCTAssertTrue(o["isx1"] is NSNull || o["isx1"] == nil, "toque na boca não seleciona o cooktop")
        XCTAssertEqual(o["lit"] as? Int, 1, "só a boca tocada acende")
        XCTAssertEqual(o["isx2"] as? String, "cook", "toque no vidro fora das bocas abre o quadro do cooktop")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Fita uma por uma, com toque de verdade: base, prateleira, tirar a pintura de uma fita só, fita branca numa peça só,
    /// a fita tocada fica destacada em laranja e, se a cor for a mesma, avisa que já estava (acompanha as portas)
    func testFitaUmaPorUmaPrateleiraTirarEBranca() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};newTpl(tpl('Aéreo 2 portas'));newTpl(tpl('Aéreo 2 portas'));var m=S.mods[1];m.shv=[0.5];S.m=m;draw();
          var pf=MAT.filter(function(c){return /pau ferro/i.test(c.n)})[0],cz=MAT.filter(function(c){return c.id==='duratex-cinza-sagrado-essencial'})[0];S.mods.forEach(function(q){q.pcT={Porta:{c:pf.hex,n:matLabel(pf),id:pf.id}}});
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();pt3(true);
          var fb=function(re){return __boxes().filter(function(b){return b.ft&&re.test(b.nm)})[0]},col=function(re){var b=fb(re);return b.c.slice(0,3).join()+'|'+(b.mid||'-')},Q=function(){return document.getElementById('pt3q')},pick=function(k){Q().querySelector('[data-ptq="'+k+'"]').click();if(!Q().hidden){var x=Q().querySelector('[data-ptq="x"]');if(x)x.click()}};
          var shelf0=col(/^1:Prateleira solta/);
          window.PT3={c:cz.hex,n:matLabel(cz),id:cz.id,erase:false};__pt3tapBox(fb(/^1:Base inferior/));var now1=(Q().textContent.match(/Fita agora: (.*?)Só a fita/)||['',''])[1];pick('fita');var base1=col(/^1:Base inferior/);
          __pt3tapBox(fb(/^1:Prateleira solta/));pick('fita');var shelf1=col(/^1:Prateleira solta/);
          __pt3tapBox(fb(/^1:Base inferior/));var hasOff=!!Q().querySelector('[data-ptq="fitaOff"]');pick('fitaOff');var base2=col(/^1:Base inferior/);
          __pt3tapBox(fb(/^1:Lateral esquerda/));pick('fitaW');var lat=col(/^1:Lateral esquerda/),latOther=col(/^1:Lateral direita/);
          window.PT3={c:pf.hex,n:matLabel(pf),id:pf.id,erase:false};__pt3tapBox(fb(/^1:Base superior/));var hl=fb(/^1:Base superior/).c.slice(0,3).join();pick('fita');var msg=(document.getElementById('amsg')||{}).textContent||'';
          var cut=cutLines(m).filter(function(l){return /^(Prateleira solta|Lateral esquerda)/.test((l.names||[])[0]||'')}).map(function(l){return (l.names||[])[0]+'='+(l.ftN||'-')+'×'+l.qty});
          pt3(false);document.getElementById('v3x').click();
          return JSON.stringify({shelf0:shelf0,now1:now1,base1:base1,shelf1:shelf1,hasOff:hasOff,base2:base2,lat:lat,latOther:latOther,hl:hl,msg:msg,cut:cut,errs:__errs});
          """#)
        let cz = "113,108,105|duratex-cinza-sagrado-essencial", pfz = "117,69,46|duratex-pau-ferro-natural-essencial-wood"
        XCTAssertEqual(o["shelf0"] as? String, "244,242,238|-", "prateleira começa com fita branca")
        XCTAssertEqual(o["now1"] as? String, "Pau Ferro Natural · Duratex Essencial Wood Madeira Leve", "diálogo mostra a cor da fita agora")
        XCTAssertEqual(o["base1"] as? String, cz, "fita da base pintada")
        XCTAssertEqual(o["shelf1"] as? String, cz, "fita da prateleira pintada")
        XCTAssertEqual(o["hasOff"] as? Bool, true, "fita pintada tem a opção de tirar a pintura")
        XCTAssertEqual(o["base2"] as? String, pfz, "tirar a pintura de uma fita só: volta pra cor das portas")
        XCTAssertEqual(o["lat"] as? String, "244,242,238|-", "fita branca só na lateral esquerda")
        XCTAssertEqual(o["latOther"] as? String, pfz, "a outra lateral continua na cor das portas")
        XCTAssertEqual(o["hl"] as? String, "255,159,26", "mesma cor: a fita tocada fica em laranja pra ver qual foi")
        XCTAssertTrue((o["msg"] as? String ?? "").hasPrefix("A fita já estava em Pau Ferro"), "\(o["msg"] ?? "")")
        XCTAssertEqual(o["cut"] as? [String], ["Lateral esquerda=-×1", "Lateral esquerda=Pau Ferro Natural · Duratex Essencial Wood Madeira Leve×1", "Prateleira solta=Cinza Sagrado · Duratex Essencial Acetinada×1"].sorted(), "plano de corte: fita de cada peça")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Micro-ondas no nicho do armário: medidas reais no catálogo, encaixar (centraliza no vão, apoia na base, frente rente à caixa),
    /// só apoiar na base e o aviso de folga / não cabe
    func testMicroondasEncaixaNoNichoComMedidaReal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Aéreo nicho aberto'));var m=S.mods[0];m.x=900;m.w=600;m.h=450;m.b=1500;m.d=350;m.v=[{k:'shelves',n:0}];S.m=m;draw();
          apAdd('microondas',0);var f=S.fr[S.fr.length-1];var models=APM.microondas.m.map(function(q){return q[0]}).filter(function(n){return /tipo /.test(n)}).length;
          var q=APM.microondas.m.filter(function(q){return /NN-ST25/.test(q[0])})[0];f.w=q[1];f.h=q[2];f.d=q[3];f.nome=q[0];f.x=1000;f.b=1600;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});fx3api.open({k:'fr',id:f.id});var msg=(document.querySelector('#it4').textContent.match(/Nicho [^·]*· [^·]*·[^·]*/)||[''])[0].trim();
          document.querySelector('#it4 [data-qnicho="1"]').click();var emb={x:f.x,b:f.b,nicho:f.nicho};
          var zs=__boxes().filter(function(b){return b.x0>=f.x-1&&b.x1<=f.x+f.w+1&&b.y0>=f.b-1&&b.y1<=f.b+f.h+2&&!/^0:/.test(String(b.nm||''))}),zmin=Math.round(Math.min.apply(null,zs.map(function(b){return b.z0})));
          f.d=300;__build();var zs2=__boxes().filter(function(b){return b.x0>=f.x-1&&b.x1<=f.x+f.w+1&&b.y0>=f.b-1&&b.y1<=f.b+f.h+2&&!/^0:/.test(String(b.nm||''))}),zmin2=Math.round(Math.min.apply(null,zs2.map(function(b){return b.z0})));
          f.x=850;f.b=1700;delete f.nicho;fx3api.open({k:'fr',id:f.id});document.querySelector('#it4 [data-qapoia]').click();var apoia={x:f.x,b:f.b};
          var big=APM.microondas.m.slice().sort(function(a,b){return b[1]-a[1]})[0];f.nome=big[0];f.w=big[1];f.h=big[2];f.d=big[3];fx3api.open({k:'fr',id:f.id});var nao=big[1]<=570||/não cabe/.test(document.querySelector('#it4').textContent);
          document.getElementById('v3x').click();
          /* 2D: arrastou e soltou em cima do módulo → encaixa sozinho e aparece por cima do módulo (dentro do nicho) */
          f.nome=q[0];f.w=q[1];f.h=q[2];f.d=q[3];delete f.nicho;f.x=1100;f.b=1650;draw();drag={t:'ap',id:f.id,p:{x:0,y:0},x0:f.x,b0:f.b};document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));drag={t:'none'};
          var drop={x:f.x,b:f.b,nicho:f.nicho},order=[].map.call(document.querySelectorAll('#svg [data-ap], #svg #mod'),function(g){return g.id==='mod'?'mod':'ap'}).join(',');
          return JSON.stringify({models:models,msg:msg,emb:emb,zmin:zmin,zmin2:zmin2,apoia:apoia,nao:nao,drop:drop,order:order,errs:__errs});
          """#)
        XCTAssertGreaterThanOrEqual(o["models"] as? Int ?? 0, 5, "micro-ondas com medida real no catálogo")
        XCTAssertEqual(o["msg"] as? String, "Nicho 570 × 420 × 350 · micro-ondas 442 × 260 × 366 · sobra 64 de cada lado e 160 em cima", "mostra o nicho e a folga")
        let emb = o["emb"] as? [String: Any] ?? [:]
        XCTAssertEqual(emb["x"] as? Int, 979, "centralizado no vão (915..1485)")
        XCTAssertEqual(emb["b"] as? Int, 1515, "apoiado na base do armário (1500 + 15)")
        XCTAssertEqual(emb["nicho"] as? Int, 1)
        XCTAssertEqual(o["zmin"] as? Int, 0, "mais fundo que o nicho (366 > 350): encosta no fundo e sobra pra frente")
        XCTAssertEqual(o["zmin2"] as? Int, o["zmin"] as? Int, "eletro tem a medida real do modelo: mexer na profundidade não muda (volta pro real)")
        let ap = o["apoia"] as? [String: Any] ?? [:]
        XCTAssertEqual(ap["x"] as? Int, 850, "só apoiar: não mexe no lado")
        XCTAssertEqual(ap["b"] as? Int, 1515, "só apoiar: desce até a base")
        XCTAssertEqual(o["nao"] as? Bool, true, "avisa quando não cabe")
        let dr = o["drop"] as? [String: Any] ?? [:]
        XCTAssertEqual(dr["x"] as? Int, 979, "2D: soltou em cima do módulo, centraliza no vão")
        XCTAssertEqual(dr["b"] as? Int, 1515, "2D: apoia na base")
        XCTAssertEqual(dr["nicho"] as? Int, 1)
        XCTAssertEqual(o["order"] as? String, "mod,ap", "2D: o micro-ondas aparece por cima do módulo (dentro do nicho), não atrás")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testEletrosComMedidaRealDeFabricaFrenchDoorEInducao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];
          /* nada de "medida típica" ou "conferir" no catálogo: todo eletro tem a medida da ficha do fabricante */
          var gen=0,real=0;['geladeira','microondas','forno','depurador','coifa','lavaloucas','airfryer','tv'].forEach(function(t){APM[t].m.forEach(function(q){if(/conferir|t[ií]pica/i.test(q[0]))gen++;if(/\(tipo [A-Z]/.test(q[0]))real++})});
          var M=function(t,re){return APM[t].m.filter(function(q){return re.test(q[0])})[0]||[]};
          var brm=M('geladeira',/BRM45/).slice(1,4).join('x'),ib=M('geladeira',/IB54/).slice(1,4).join('x'),fd=M('geladeira',/BRO85/).slice(1,4).join('x'),oe8=M('forno',/OE8MX/).slice(1,4).join('x'),cfo=M('forno',/CFO4NAR \(/).slice(1,4).join('x'),tv55=M('tv',/55"/).slice(1,4).join('x');
          /* French door: 2 portas em cima que abrem pros lados e a gaveta do freezer que sai pra frente */
          var gi=APM.geladeira.m.indexOf(M('geladeira',/BRO85/)),g=apAdd('geladeira',gi);g.x=0;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});ele3api.toggle(g.id);await new Promise(function(r){setTimeout(r,1800)});__build();
          var B=__boxes().filter(function(b){return b.fr===g.id}),gav=B.filter(function(b){return b.inv}).length,rotL=0,rotR=0;B.forEach(function(b){if(b.pf&&b.pf.ax!=='x'&&b.y0>g.h*.38){if((b.x0+b.x1)/2<g.x+g.w/2)rotL++;else rotR++}});
          /* fogão de piso: altura de verdade com a tampa (a mesa fica abaixo) · de embutir: mesa na altura da bancada */
          var fg=apAdd('forno',APM.forno.m.indexOf(M('forno',/CFO4NAR \(/)));fg.x=900;var fe=apAdd('forno',APM.forno.m.indexOf(M('forno',/76EXR/)));fe.x=2200;__build();
          var fgTop=Math.round(Math.max.apply(null,__boxes().filter(function(b){return b.fr===fg.id}).map(function(b){return b.y1}))),feTop=fe.b+fe.h,bt=benchTop();
          /* cooktop de indução: vidro liso, zona fica vermelha ao tocar (sem chama) */
          var ind=COOKM.filter(function(q){return q.ind})[0];S.st.items.push({id:77,k:'cook',x:1500,y:60,w:ind.w,d:ind.d,cm:ind.id});var st=S.st,it=st.items.filter(function(i){return i.id===77})[0];__build();
          var y=st.t+st.e+9,P=cookPos(it).map(function(q){return [st.x+it.x+it.w*q[0],it.y+it.d*q[1]]}),p=org3api.proj([P[0][0],y,P[0][1]]);org3api.one(p[0],p[1]);await new Promise(function(r){setTimeout(r,500)});
          var lit=Object.keys(fx3api.fire()).length,fx=fx3api.fx(),grade=__boxes().filter(function(b){return b.ck===st.id+':77'&&b.c&&(b.c==='#1d1f23'||String(b.c)==='29,31,35')}).length;
          document.getElementById('v3x').click();
          return JSON.stringify({gen:gen,real:real,brm:brm,ib:ib,fd:fd,oe8:oe8,cfo:cfo,tv55:tv55,gav:gav,rotL:rotL,rotR:rotR,fgTop:fgTop,fgH:fg.h,feTop:feTop,bt:bt,ind:ind.n,lit:lit,fx:fx,errs:__errs});
          """#)
        XCTAssertEqual(o["gen"] as? Int, 0, "nenhum eletro com medida típica/conferir")
        XCTAssertGreaterThanOrEqual(o["real"] as? Int ?? 0, 60, "modelos reais (tipo marca) em todas as categorias")
        XCTAssertEqual(o["brm"] as? String, "621x1760x755", "Duplex BRM45 da ficha da Brastemp")
        XCTAssertEqual(o["ib"] as? String, "699x1895x749", "Inverse IB54")
        XCTAssertEqual(o["fd"] as? String, "836x1857x793", "French door BRO85")
        XCTAssertEqual(o["oe8"] as? String, "595x595x575", "forno OE8MX")
        XCTAssertEqual(o["cfo"] as? String, "515x960x603", "fogão CFO4NAR")
        XCTAssertEqual(o["tv55"] as? String, "1236x718x68", "TV 55 sem a base")
        XCTAssertGreaterThanOrEqual(o["gav"] as? Int ?? 0, 1, "French door: gaveta do freezer sai pra frente")
        XCTAssertGreaterThan(o["rotL"] as? Int ?? 0, 0, "porta da esquerda abre")
        XCTAssertGreaterThan(o["rotR"] as? Int ?? 0, 0, "porta da direita abre")
        XCTAssertEqual(o["fgTop"] as? Int, o["fgH"] as? Int, "fogão de piso não passa da altura real")
        XCTAssertEqual(o["feTop"] as? Int, o["bt"] as? Int, "fogão de embutir com a mesa na altura da bancada")
        XCTAssertTrue((o["ind"] as? String ?? "").contains("Indução"))
        XCTAssertEqual(o["lit"] as? Int, 1, "toque na zona liga a indução")
        XCTAssertGreaterThan(o["fx"] as? Int ?? 0, 0, "zona vermelha acesa")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testFitaDaBaseEmbaixoDaPortaPintaPeloToque() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.env='cozinha';S.W=3000;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));var m=S.mods[0];m.x=600;newTpl(tpl('Aéreo 2 portas'));var a=S.mods[1];a.x=600;a.b=1500;S.m=m;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});
          var Q=function(){return document.getElementById('pt3q')},fb=function(re){return __boxes().filter(function(b){return b.ft&&re.test(b.nm)})[0]};
          /* toque ao longo de cada fita do caixote (base, laterais, topo), portas fechadas e abertas: tem que pegar a fita tocada, não a porta nem a fita do lado */
          var erra=[];var probe=function(){__build();pt3(true);window.PT3={c:'#2e86c1',n:'Azul',id:'',erase:false};
            __boxes().filter(function(b){return b.ft&&/^(Base|Lateral)/.test(String(b.nm).split(':')[1])}).forEach(function(b){[.15,.5,.85].forEach(function(t){var big=(b.x1-b.x0)>(b.y1-b.y0),p=big?[b.x0+(b.x1-b.x0)*t,(b.y0+b.y1)/2,b.z1]:[(b.x0+b.x1)/2,b.y0+(b.y1-b.y0)*t,b.z1],c=org3api.proj(p);if(!c)return;paintTap(c[0],c[1]);var st=__pt3state(),k=st.pv?st.pv.mi+':'+String(st.pv.key).replace(/#\d+$/,''):'none';if(k!==String(b.nm))erra.push(b.nm+'@'+t+'->'+k);if(Q())Q().hidden=true})});pt3(false)};
          probe();org3api.open(m,true);org3api.open(a,true);await new Promise(function(r){setTimeout(r,1500)});probe();org3api.open(m,false);org3api.open(a,false);await new Promise(function(r){setTimeout(r,1500)});__build();
          /* a fita da base do balcão (a tirinha embaixo da porta) pinta de verdade · a porta fica no botão "Era a peça?" e o botão troca */
          pt3(true);window.PT3={c:'#2e86c1',n:'Azul',id:'',erase:false};var bi=fb(/^0:Base inferior/),c=org3api.proj([(bi.x0+bi.x1)/2,102,bi.z1]);paintTap(c[0],c[1]);var pv1=__pt3state().pv.key,alt1=(Q().querySelector('[data-ptalt]')||{}).textContent||'';
          Q().querySelector('[data-ptq="fita"]').click();var base=fb(/^0:Base inferior/).c.slice(0,3).join(),lat=fb(/^0:Lateral esquerda/).c.slice(0,3).join();var x=Q().querySelector('[data-ptq="x"]');if(x)x.click();
          paintTap(c[0],c[1]);Q().querySelector('[data-ptalt]').click();var pv2=__pt3state().pv.key,alt2=(Q().querySelector('[data-ptalt]')||{}).textContent||'';Q().querySelector('[data-ptq="x"]').click();
          /* fita pintada de propósito ganha da cor da peça pintada (fitas do módulo inteiro) */
          a.pc={'Base inferior#1':{c:'#ffffff',n:'Branco'}};a.pfM={c:'#c0392b',n:'Vermelho'};__build();var aBase=fb(/^1:Base inferior/).c.slice(0,3).join(),aLat=fb(/^1:Lateral esquerda/).c.slice(0,3).join();
          pt3(false);document.getElementById('v3x').click();
          return JSON.stringify({erra:erra,pv1:pv1,alt1:alt1,base:base,lat:lat,pv2:pv2,alt2:alt2,aBase:aBase,aLat:aLat,errs:__errs});
          """#)
        XCTAssertEqual((o["erra"] as? [String])?.count, 0, "toque na fita pega a fita certa: \(o["erra"] ?? "")")
        XCTAssertEqual(o["pv1"] as? String, "Base inferior#1", "toque na tirinha embaixo da porta pega a fita da base")
        XCTAssertTrue((o["alt1"] as? String ?? "").contains("Porta"), "botão pra trocar pra porta")
        XCTAssertEqual(o["base"] as? String, "46,134,193", "fita da base pintada de azul")
        XCTAssertNotEqual(o["lat"] as? String, "46,134,193", "só a fita tocada muda")
        XCTAssertEqual(o["pv2"] as? String, "Porta#1", "botão troca pra porta")
        XCTAssertTrue((o["alt2"] as? String ?? "").contains("Base inferior"), "e volta pra fita da base")
        XCTAssertEqual(o["aBase"] as? String, "192,57,43", "fitas do módulo pintadas ganham da peça pintada")
        XCTAssertEqual(o["aLat"] as? String, "192,57,43")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testTomadasRegistroChurrasqueiraBotaoDoLEDETVComLogo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));var b=S.mods[0];b.x=300;newTpl(tpl('Aéreo 2 portas'));var a=S.mods[1];a.x=300;a.b=1500;a.led={k:'quente',c:'#ffd27a',pf:'alu',pos:'base',on:1};S.m=b;draw();
          /* tomada dentro do armário (no fundo) e na parede, registro de água */
          var t1=apAdd('eletrica',0);t1.x=500;t1.b=400;var dentro0=elDentro(t1);var t2=apAdd('eletrica',1);t2.x=500;t2.b=1150;var rg=apAdd('eletrica',7);rg.x=900;rg.b=1100;draw();
          var cats=CATS.filter(function(c){return c.id==='cel'||c.id==='cchur'}).map(function(c){return c.id+':'+c.it.length}).join(',');
          /* churrasqueira pré-moldada com medida real */
          var ci=apModels('churrasqueira').findIndex(function(q){return /Natural 84/.test(q[0])}),ch=apAdd('churrasqueira',ci);ch.x=2600;var chm=[ch.w,ch.h,ch.d].join('x');
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();
          var z1=Math.round(Math.min.apply(null,__boxes().filter(function(q){return q.fr===t1.id}).map(function(q){return q.z0}))),z2=Math.round(Math.min.apply(null,__boxes().filter(function(q){return q.fr===t2.id}).map(function(q){return q.z0})));
          /* toque na churrasqueira acende a brasa */
          var cb=__boxes().filter(function(q){return q.fr===ch.id});var bb=cb[0],cp=org3api.proj([ch.x+ch.w/2,700,ch.d-20]);org3api.one(cp[0],cp[1]);var brasa=__boxes().filter(function(q){return q.fr===ch.id&&q.em}).length;
          /* botão do LED: bolinha preta embaixo do aéreo · toque desliga */
          var lb=__lbt(),s0=lb[0]&&lb[0].s;if(s0)org3api.one(s0[0],s0[1]);var ledOff=a.led.on;
          /* TV: abertura com a logo e depois a imagem */
          var tv=apAdd('tv',1);tv.x=1500;tv.b=1300;__build();ele3api.luz(tv.id,1);await new Promise(function(r){setTimeout(r,1400)});var tvs=__tvs(),logo=fx3api.fx();await new Promise(function(r){setTimeout(r,2400)});var wel=fx3api.fx();var car=0;for(var ci_=0;ci_<20;ci_++){await new Promise(function(r){setTimeout(r,150)});car=Math.max(car,__tvCar())}var tvs2=__tvs();
          document.getElementById('v3x').click();
          return JSON.stringify({dentro0:dentro0,cats:cats,chm:chm,z1:z1,z2:z2,brasa:brasa,lb:lb.length,ledOff:ledOff,tvSplash:Object.keys(tvs).map(function(k){return tvs[k].done})[0],logo:logo,wel:wel,car:car,tvDone:Object.keys(tvs2).map(function(k){return tvs2[k].done})[0],rooms:ROOMS.map(function(r){return r[0]}).indexOf('gourmet'),errs:__errs});
          """#)
        XCTAssertEqual(o["dentro0"] as? Bool, true, "tomada posta em cima do módulo vai dentro do armário")
        XCTAssertEqual(o["cats"] as? String, "cel:12,cchur:19", "abas de tomadas/registros e de churrasqueiras")
        XCTAssertEqual(o["chm"] as? String, "840x2350x570", "churrasqueira com a medida do fabricante")
        XCTAssertGreaterThan(o["z1"] as? Int ?? 0, 15, "tomada dentro do armário fica no fundo do módulo (não na parede)")
        XCTAssertEqual(o["z2"] as? Int, 0, "tomada na parede")
        XCTAssertGreaterThan(o["brasa"] as? Int ?? 0, 5, "toque acende a brasa")
        XCTAssertEqual(o["lb"] as? Int, 1, "botão do LED no aéreo")
        XCTAssertEqual(o["ledOff"] as? Int, 0, "toque no botão desliga o LED")
        XCTAssertEqual(o["tvSplash"] as? Bool, false, "TV ligando mostra a abertura")
        XCTAssertGreaterThan(o["logo"] as? Int ?? 0, 50, "logo do Arquemestre na tela")
        XCTAssertGreaterThan(o["wel"] as? Int ?? 0, 50, "depois da logo: SEJA BEM-VINDO na tela")
        XCTAssertGreaterThan(o["car"] as? Int ?? 0, 30, "TV ligada: o marceneiro passa de carro com a escada e a logo")
        XCTAssertEqual(o["tvDone"] as? Int, 1, "depois da abertura, a imagem normal")
        XCTAssertGreaterThanOrEqual(o["rooms"] as? Int ?? -1, 0, "ambiente Área gourmet")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Aba 🎨 Cores no 2D com cabeçalho (paredes e pisos, armários, portas e fitas) e 15 pisos e porcelanatos com textura,
    /// Caixa da geladeira (laterais até em cima + aéreo), ripado em cima dos módulos até o teto (na frente ou na parede) e réguas das laterais por nível
    func testCaixaDaGeladeiraRipadoEmCimaEReguasDasLaterais() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* caixa da geladeira: laterais até em cima + aéreo, vão aberto embaixo e a geladeira já dentro */
          newTpl(tpl('Caixa da geladeira side by side (laterais + aéreo)'));var g=S.mods[0];R.caixa=[g.h,g.base,g.rod].join(',');R.nicho=partsOf(g).some(function(p){return p.gelN});R.gel=S.fr.filter(function(f){return f.t==='geladeira'}).length;
          /* ripado em cima dos superiores até o teto */
          for(var i=0;i<2;i++){newTpl(4);var u=S.mods[S.mods.length-1];u.x=1100+i*800;u.w=800}var up=S.mods.filter(function(m){return m.sup});S.m=up[0];S.tab=8;draw();panel();
          document.querySelector('#bd [data-rpt="frente"]').click();document.querySelector('#bd [data-rptall]').click();R.ripado=up.every(function(m){return m.rpTop==='frente'});var ch=partsOf(up[0]).filter(function(p){return /^Chapa base do ripado/.test(p.name)})[0];R.ateTeto=ch?ch.h:0;
          document.querySelector('#bd [data-rpt="parede"]').click();R.parede=(partsOf(up[0]).filter(function(p){return /^Ripa/.test(p.name)})[0]||{rpz:[-1]}).rpz[0];
          /* réguas das laterais por nível */
          stdOpen(0);document.querySelector('#stdbody [data-rgm="sup|pontas"]').click();R.pontas=up.map(function(m){return (m.egL||0)+''+(m.egR||0)}).join(',');
          document.querySelector('#stdbody [data-rgm="sup|duplo"]').click();R.duplo=up[0].egD===up[0].d;document.getElementById('stdm').hidden=true;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["caixa"] as? String, "2500,false,false", "caixa da geladeira do chão até em cima, sem base e sem pedestal")
        XCTAssertEqual(o["nicho"] as? Bool, true, "vão aberto da geladeira")
        XCTAssertEqual(o["gel"] as? Int, 1, "geladeira já dentro da caixa")
        XCTAssertEqual(o["ripado"] as? Bool, true, "ripado em todos os superiores")
        XCTAssertEqual(o["ateTeto"] as? Int, 200, "ripado do topo do aéreo até o teto")
        XCTAssertEqual(o["parede"] as? Int, 6, "ripado encostado na parede")
        XCTAssertEqual(o["pontas"] as? String, "10,01", "régua só nas pontas")
        XCTAssertEqual(o["duplo"] as? Bool, true, "engrossado total duplo na profundidade toda")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// 🎯 Só este módulo (câmera fixa nele, frente/ângulo/lado/cima, ↩ volta) e janela arrastável no 2D
    func testFocarSoNoModuloEArrastarJanelaNo2D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          /* 🎯 só este módulo: câmera fixa nele, só o corpo dele aparece; ↩ volta pro ambiente */
          demoScene();draw();var wi=S.mods.findIndex(function(m){return m.wing==='e'});open3D();await new Promise(function(r){setTimeout(r,300)});var n0=__boxes().length;
          focOn(wi,'front');var f=__foc();R.so=__boxes().every(function(b){return String(b.nm).indexOf(wi+':')===0});R.menos=f.n<n0;R.barra=!document.getElementById('foc3').hidden;
          document.querySelector('#foc3 [data-fcv="side"]').click();R.lado=__foc().v;document.querySelector('#foc3 [data-fcx]').click();R.volta=__foc()===null&&__boxes().length===n0;document.getElementById('v3x').click();
          /* janela: arrasta no 2D mesmo com móvel embaixo (não trava sozinha) */
          S.W=5610;S.H=2600;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];draw();var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));S.mods[0].x=1400;S.ops=[{id:7,t:'janela',x:1500,b:1100,w:1700,h:600}];draw();
          var g=document.querySelector('#svg [data-op2="7"] rect'),rc=g.getBoundingClientRect(),x=rc.left+rc.width/2,y=rc.top+rc.height/2,svg=document.getElementById('svg'),ev=function(tp,el,cx,cy){el.dispatchEvent(new PointerEvent(tp,{clientX:cx,clientY:cy,pointerId:1,bubbles:true,isPrimary:true,pointerType:'touch'}))};
          ev('pointerdown',g,x,y);ev('pointermove',svg,x+40,y-20);ev('pointermove',svg,x+60,y-25);ev('pointerup',svg,x+60,y-25);R.janela=S.ops[0].x!==1500&&S.ops[0].b!==1100;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["so"] as? Bool, true, "só as peças do módulo focado aparecem")
        XCTAssertEqual(o["menos"] as? Bool, true)
        XCTAssertEqual(o["barra"] as? Bool, true, "barra do foco com as vistas")
        XCTAssertEqual(o["lado"] as? String, "side", "vista de lado no foco")
        XCTAssertEqual(o["volta"] as? Bool, true, "↩ volta pro ambiente com tudo")
        XCTAssertEqual(o["janela"] as? Bool, true, "janela arrasta no 2D mesmo com móvel embaixo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Porta do ambiente abre na parede do lado, pedra sólida (caixa da geladeira e geladeira não passam por ela), geladeira acompanha a caixa e 5 toques abrem o 2D só do módulo
    func testPedraSolidaGeladeiraAcompanhaPortaDaSalaE5ToquesEditaSoOModulo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=5000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.ops=[];draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* porta do ambiente na parede da esquerda abre de verdade (a folha gira pra dentro do ambiente) */
          S.ops=[{id:5,t:'porta',x:1400,b:0,w:700,h:2000,wall:'e'}];draw();open3D();await new Promise(function(r){setTimeout(r,300)});
          var folha=function(){var m=0;__bg().concat(__boxes()).forEach(function(b){if(b.pf&&b.y1>1900&&b.y1<2050&&b.x0<300)m=Math.max(m,b.x1-b.x0)});return Math.round(m)};
          S.ops[0].open=true;anim3();await new Promise(function(r){setTimeout(r,1500)});R.abriu=__ang().g.od5===90&&folha()>=600;S.ops[0].open=false;S.ops=[];document.getElementById('v3x').click();
          /* pedra sólida: a caixa da geladeira não entra embaixo da pedra; os balcões continuam embaixo dela */
          newTpl(tpl('Balcão 2 portas'));S.mods[0].x=0;newTpl(tpl('Balcão 2 portas'));S.mods[1].x=S.mods[0].w;draw();var bx0=S.mods.map(function(m){return m.x}).join();
          S.stones=[{id:1,x:0,w:S.mods[0].w+S.mods[1].w,d:600,t:820,e:40,items:[],shape:'reta'}];var fimPedra=S.stones[0].w;
          newTpl(tpl('Caixa da geladeira duplex / inverse (laterais + aéreo)'));var g=S.mods[S.mods.length-1];g.x=900;draw();
          R.foraDaPedra=g.x>=fimPedra-1;R.balcoes=S.mods.slice(0,2).map(function(m){return m.x}).join()===bx0;
          var f=S.fr.filter(function(q){return q.id===g._gel})[0];R.gelDentro=!!f&&f.x>=g.x&&f.x+f.w<=g.x+g.w;
          /* geladeira solta também não passa pela pedra; micro-ondas em cima da pedra fica */
          S.fr.push({id:77,t:'geladeira',x:600,y:0,w:700,h:1800,d:750,b:0},{id:78,t:'microondas',x:300,y:0,w:450,h:260,d:340,b:860});draw();
          var gs=S.fr.filter(function(q){return q.id===77})[0],mw=S.fr.filter(function(q){return q.id===78})[0];R.solta=gs.x+gs.w<=1||gs.x>=fimPedra-1;R.micro=mw.x===300;
          /* puxada pra frente (fora da pedra) pode ficar onde está */
          gs.x=600;gs.y=700;draw();R.frente=gs.x===600;
          /* 5 toques no módulo: sai do 3D e abre o 2D só dele com o cabeçalho; mudar profundidade; fechar volta pro projeto */
          S.fr=S.fr.filter(function(q){return q.id!==77&&q.id!==78});draw();var nAll=document.querySelectorAll('#svg [data-mi]').length;
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var mi=S.mods.indexOf(g),b=__boxes().filter(function(q){return String(q.nm).indexOf(mi+':Lateral')===0})[0],c=__p3((b.x0+b.x1)/2,(b.y0+b.y1)/2,b.z1);
          __solo3(c[0],c[1]);await new Promise(function(r){setTimeout(r,200)});var bar=document.getElementById('solobar');
          R.solo=window.SOLO2===g&&S.m===g&&!!bar&&!bar.hidden&&/Editando só/.test(bar.textContent);R.saiu3D=getComputedStyle(document.getElementById('v3')).display==='none'||document.getElementById('v3').hidden;
          R.soEle=document.querySelectorAll('#svg [data-mi]').length<nAll;
          var d0=g.d,inp=[].slice.call(document.querySelectorAll('input')).filter(function(i){var l=i.closest('label')||i.parentNode;return l&&/Profund/i.test(l.textContent)&&i.offsetParent})[0];if(inp){inp.value=String(d0-150);inp.dispatchEvent(new Event('input',{bubbles:true}));inp.dispatchEvent(new Event('change',{bubbles:true}))}draw();R.prof=g.d===d0-150&&bar.textContent.indexOf('× '+(d0-150)+' mm')>0;
          document.getElementById('cx').click();R.voltou=!window.SOLO2&&bar.hidden&&document.querySelectorAll('#svg [data-mi]').length>=nAll;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["abriu"] as? Bool, true, "porta do ambiente na parede do lado abre com a folha girando pra dentro")
        XCTAssertEqual(o["foraDaPedra"] as? Bool, true, "caixa da geladeira não entra embaixo da pedra")
        XCTAssertEqual(o["balcoes"] as? Bool, true, "balcões continuam embaixo da pedra")
        XCTAssertEqual(o["gelDentro"] as? Bool, true, "a geladeira acompanha a caixa dela")
        XCTAssertEqual(o["solta"] as? Bool, true, "geladeira solta não passa pela pedra")
        XCTAssertEqual(o["micro"] as? Bool, true, "micro-ondas em cima da pedra fica onde está")
        XCTAssertEqual(o["frente"] as? Bool, true, "geladeira puxada pra frente da pedra pode ficar")
        XCTAssertEqual(o["solo"] as? Bool, true, "5 toques: 2D só do módulo com o cabeçalho")
        XCTAssertEqual(o["saiu3D"] as? Bool, true, "sai do 3D")
        XCTAssertEqual(o["soEle"] as? Bool, true, "só ele aparece no 2D")
        XCTAssertEqual(o["prof"] as? Bool, true, "dá pra diminuir a profundidade")
        XCTAssertEqual(o["voltou"] as? Bool, true, "fechar volta pro 2D do projeto todo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Só o módulo: no 3D tem o 2D só dele e no 2D só dele tem os vãos (porta, gaveta, divisória) e o 3D só dele, sem mexer nos outros módulos
    func testSoOModulo3DE2DComPortaGavetaEDivisoriaSoNele() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          /* 🎯 só o módulo no 3D tem o ✏️ 2D só ele; no 2D só dele: vãos com porta, gaveta, divisória e 🧊 3D só ele */
          window.MINI3OFF=1;PR.setupDone=1;demoScene();draw();var R={};var mi=1,m=S.mods[mi];var others=JSON.stringify(S.mods.filter(function(q){return q!==m}));
          open3D();await new Promise(function(r){setTimeout(r,300)});focOn(mi,'front');await new Promise(function(r){setTimeout(r,200)});
          var b2=document.querySelector('#foc3 [data-fc2d]');R.btn2d=!!b2&&b2.offsetParent!==null;
          b2.click();await new Promise(function(r){setTimeout(r,300)});R.solo=window.SOLO2===m;R.v3=getComputedStyle(document.getElementById('v3')).display;R.foc=!window.FOC3;
          var chips=[].slice.call(document.querySelectorAll('#solobar [data-sov]'));R.chips=chips.map(function(c){return c.textContent});
          R.v0=m.v.map(function(v){return v.k+(v.n||'')}).join();
          /* vão 2: 1 porta */
          var c2=chips[chips.length>1?1:0];c2.click();await new Promise(function(r){setTimeout(r,150)});R.menu=!!document.getElementById('vmenu');var d1=document.querySelector('#vmenu [data-vk="door1"]');if(d1)d1.click();await new Promise(function(r){setTimeout(r,150)});
          R.v1=m.v.map(function(v){return v.k+(v.n||'')}).join();R.soloStill=window.SOLO2===m;
          /* vão 1: gavetas */
          chips=[].slice.call(document.querySelectorAll('#solobar [data-sov]'));chips[0].click();await new Promise(function(r){setTimeout(r,150)});var dg=document.querySelector('#vmenu [data-vk="drawers"]');if(dg)dg.click();await new Promise(function(r){setTimeout(r,150)});
          R.v2=m.v.map(function(v){return v.k+(v.n||'')}).join();
          /* divisória no vão 1 */
          chips=[].slice.call(document.querySelectorAll('#solobar [data-sov]'));chips[chips.length-1].click();await new Promise(function(r){setTimeout(r,150)});var ds=document.querySelector('#vmenu [data-vk="split"]');if(ds)ds.click();await new Promise(function(r){setTimeout(r,100)});var d2=document.querySelector('#vmenu [data-vk="dv|2"]');R.dvBtn=!!d2;if(d2)d2.click();await new Promise(function(r){setTimeout(r,150)});
          R.v3v=m.v.map(function(v){return v.k+(v.n||'')}).join();R.chips2=[].slice.call(document.querySelectorAll('#solobar [data-sov]')).map(function(c){return c.textContent});
          R.othersSame=JSON.stringify(S.mods.filter(function(q){return q!==m}))===others;
          /* 3D só ele */
          document.querySelector('#solobar [data-so3]').click();await new Promise(function(r){setTimeout(r,400)});R.foc3=window.FOC3&&window.FOC3.mi===mi;R.so3=__boxes().every(function(b){return String(b.nm).indexOf(mi+':')===0});
          document.getElementById('v3x').click();await new Promise(function(r){setTimeout(r,200)});R.backSolo=window.SOLO2===m;
          document.querySelector('#solobar [data-sox]').click();R.geral=!window.SOLO2;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["btn2d"] as? Bool, true, "no 3D só do módulo tem o ✏️ 2D só ele")
        XCTAssertEqual(o["solo"] as? Bool, true, "abre o 2D só dele")
        XCTAssertEqual(o["v3"] as? String, "none", "sai do 3D")
        XCTAssertEqual(o["menu"] as? Bool, true, "tocar no vão abre porta, gaveta, divisória…")
        XCTAssertEqual(o["v1"] as? String, "door1", "1 porta no vão")
        XCTAssertEqual(o["v2"] as? String, "drawers3", "gavetas no vão")
        XCTAssertEqual(o["v3v"] as? String, "drawers3,drawers3,drawers3", "divisórias em pé no vão")
        XCTAssertEqual((o["chips2"] as? [String])?.count, 3, "os vãos novos aparecem no cabeçalho")
        XCTAssertEqual(o["othersSame"] as? Bool, true, "os outros módulos não mudam")
        XCTAssertEqual(o["foc3"] as? Bool, true, "🧊 3D só ele")
        XCTAssertEqual(o["so3"] as? Bool, true, "no 3D só as peças dele")
        XCTAssertEqual(o["backSolo"] as? Bool, true, "fechar o 3D volta pro 2D só dele")
        XCTAssertEqual(o["geral"] as? Bool, true, "↩ volta pro projeto todo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Toque no 3D acha a peça certa no ponto exato (a da frente) em várias vistas, e o dedo pertinho da borda de peça fina ainda acha o módulo
    func testToqueNo3DAchaAPecaCertaEBordaFina() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;demoScene();draw();open3D();await new Promise(function(r){setTimeout(r,400)});var R={};
          /* o toque acha a peça que está na frente no ponto exato (raio do dedo), em várias vistas */
          var cv=document.getElementById('cv3'),W=cv.clientWidth,H=cv.clientHeight,views=[[.6,.35],[0,.2],[1.1,.4],[-.9,.3],[.3,1.2]],tot=0,bad=0;
          views.forEach(function(v){__foto3({yaw:v[0],pitch:v[1]});__foto3(null);__build();for(var y=40;y<H-40;y+=18)for(var x=10;x<W-10;x+=18){var h=__rayMod(x,y);if(!h)continue;tot++;var p=__pick(x,y);if(!p||p.nm!==h.nm)bad++}});
          R.tot=tot>300;R.bad=bad;
          /* dedo pertinho da borda de fora da lateral (peça fina) ainda acha o módulo */
          __foto3({yaw:.6,pitch:.35});__foto3(null);__build();var n=0,ok=0;__boxes().filter(function(b){return /^\d+:Lateral/.test(b.nm)}).forEach(function(b){var c=__p3(b.x1,(Math.max(b.y0,115)+b.y1)/2,b.z1);/* meio da lateral acima do rodapé (com as laterais até o piso o meio desceu pra perto da quina da pedra) */if(!c)return;var h0=__rayMod(c[0]-1,c[1]);if(!h0||h0.nm!==b.nm)return;n++;var p=__pick(c[0]+5,c[1]);if(p&&String(p.nm).split(':')[0]===String(b.nm).split(':')[0])ok++});
          R.borda=n>3&&ok===n;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["tot"] as? Bool, true, "muitos pontos conferidos")
        XCTAssertEqual(o["bad"] as? Int, 0, "o toque acha a peça que está na frente no ponto tocado")
        XCTAssertEqual(o["borda"] as? Bool, true, "dedo pertinho da borda da lateral acha o módulo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Pedra não some editando o 2D só do módulo (nem no desfazer), 🗑 não tira pedra, pedra travada no 3D, geladeira visível no 2D, mudar de parede sem perder nada, trena 2D/3D e lado da porta do ambiente
    func testPedraTravadaNaoSomeTrenaComLupaGeladeiraNo2DEPortaDoAmbiente() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;demoScene();draw();var R={};var st=S.stones[0],w0=JSON.stringify(st);
          /* editar no 2D só do módulo não tira a pedra (nem do desfazer) */
          soloOn(S.mods[1]);snap();S.mods[1].d=500;draw();await new Promise(function(r){setTimeout(r,800)});snap();S.mods[1].w=1100;draw();await new Promise(function(r){setTimeout(r,800)});
          R.hist=HIST.every(function(h){return JSON.parse(h.s).stones.length===1});soloOff();document.getElementById('und').click();R.desfazer=S.stones.length===1;
          /* 🗑 do 2D não tira pedra nem cuba */
          S.st=S.stones[0];LAST='stone';document.getElementById('delMod').click();var n1=S.stones.length;LAST='item';S.selI=(S.stones[0].items[0]||{}).id;document.getElementById('delMod').click();R.lixo=n1===1&&S.stones[0].items.length===1;
          /* no 3D a pedra, a cuba e o cooktop ficam travados */
          open3D();await new Promise(function(r){setTimeout(r,300)});st=S.stones[0];var a=__itOpen({k:'st',id:st.id});var it=st.items[0],b=__itOpen({k:'cook',sid:st.id,iid:it.id});R.trava3d=a.h===0&&!a.bdr&&b.h===0&&!b.bdr&&!!document.querySelector('.stlk');document.getElementById('v3x').click();
          /* geladeira aparece no 2D dentro da caixa (parede do fundo e do lado) */
          S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.ops=[];draw();var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Caixa da geladeira side by side (laterais + aéreo)'));var g=S.mods[0];g.x=1500;S.m=null;draw();var top=function(){var e=document.querySelector('#svg [data-ap]');return !!e&&!!e.compareDocumentPosition&&!!(document.querySelector('#svg [data-mi]').compareDocumentPosition(e)&Node.DOCUMENT_POSITION_FOLLOWING)};R.gel2d=top();
          var k0=JSON.stringify(Object.assign({},g,{x:0,wing:0,_gel:0}));__mdDrop(0,[0.5,1200,1500]);R.gelLado=g.wing==='e'&&!!document.querySelector('#svg [data-ap]');R.naoPerde=JSON.stringify(Object.assign({},g,{x:0,wing:0,_gel:0}))===k0;
          /* trena no 2D: gruda nas bordas e dá a medida */
          S.mods=[];S.fr=[];draw();newTpl(tpl('Balcão 2 portas'));var m=S.mods[0];m.x=600;S.m=null;draw();document.getElementById('med2b').click();
          var sv=document.getElementById('svg'),host=sv.parentNode,rc=sv.getBoundingClientRect(),f=rc.width/VB.w,P=function(x,y){return [rc.left+(OX+x*K-VB.x)*f,rc.top+(OY+(S.H-y)*K-VB.y)*f]},ev=function(tp,el,p){el.dispatchEvent(new PointerEvent(tp,{clientX:p[0],clientY:p[1],pointerId:1,bubbles:true,isPrimary:true,pointerType:'touch'}))};
          var pa=P(m.x+6,400),pb=P(m.x+m.w-5,410);ev('pointerdown',sv,pa);ev('pointermove',sv,pb);ev('pointerup',sv,pb);R.trena2d=MED2.L.length===1&&Math.round(Math.hypot(MED2.L[0].b[0]-MED2.L[0].a[0],MED2.L[0].b[1]-MED2.L[0].a[1]))===900&&/900 mm/.test((document.querySelector('#medg text')||{}).textContent||'');R.naoMexeu=m.x===600;document.getElementById('med2b').click();
          /* trena no 3D */
          /* mede o tampo do armário visto de cima (base superior, sem travessa nem moldura): as portas agora sobem e cobrem a travessa, então a aresta da frente não é mais um ponto livre pra trena */m.trav=false;m.mold=false;m.latPiso=false;m.latFora=false;/* tampo inteiro de ponta a ponta (laterais por dentro) */draw();open3D();await new Promise(function(r){setTimeout(r,300)});__foto3({yaw:.2,pitch:.9});__foto3(null);__build();document.getElementById('v3med').click();var x0=1e9,x1=-1e9,y1=-1e9,z1=-1e9;__boxes().forEach(function(q){if(!/^0:Base superior/.test(String(q.nm)))return;x0=Math.min(x0,q.x0);x1=Math.max(x1,q.x1);y1=Math.max(y1,q.y1);z1=Math.max(z1,q.z1)});
          var cv=document.getElementById('cv3'),cr=cv.getBoundingClientRect(),qa=__p3(x0,y1,z1),qb=__p3(x1,y1,z1);ev('pointerdown',cv,[cr.left+qa[0]+4,cr.top+qa[1]-3]);ev('pointermove',cv,[cr.left+qb[0]-4,cr.top+qb[1]-3]);ev('pointerup',cv,[cr.left+qb[0]-4,cr.top+qb[1]-3]);
          var M3=__med3();R.trena3d=M3.L.length===1&&Math.round(Math.hypot(M3.L[0].b[0]-M3.L[0].a[0],M3.L[0].b[1]-M3.L[0].a[1],M3.L[0].b[2]-M3.L[0].a[2]))===900&&!!document.querySelector('#med3 text');R.naoMexeu3=m.x===600;
          /* a trena não atravessa o armário: do chão na frente até o fundo do tampo, para no balcão · só tocar não mede */
          __foto3({yaw:.5,pitch:.45});__foto3(null);__build();cr=cv.getBoundingClientRect();var n0=M3.L.length,fa=__p3(1050,0,1300),fb=__p3(1050,820,200);ev('pointerdown',cv,[cr.left+fa[0],cr.top+fa[1]]);ev('pointermove',cv,[cr.left+fb[0],cr.top+fb[1]]);ev('pointerup',cv,[cr.left+fb[0],cr.top+fb[1]]);var L1=M3.L[M3.L.length-1];R.solida=M3.L.length===n0+1&&Math.hypot(L1.b[0]-L1.a[0],L1.b[1]-L1.a[1],L1.b[2]-L1.a[2])<1300;
          var n1=M3.L.length,ft=__p3(1050,400,566);ev('pointerdown',cv,[cr.left+ft[0],cr.top+ft[1]]);ev('pointerup',cv,[cr.left+ft[0],cr.top+ft[1]]);R.toque=M3.L.length===n1;document.getElementById('v3med').click();

          /* porta do ambiente: lado e pra dentro / pra fora */
          S.ops=[{id:6,t:'porta',x:2600,b:0,w:800,h:2100,hg:'d',out:1,open:true}];__build();anim3();await new Promise(function(r){setTimeout(r,1500)});var lf=null;__bg().concat(__boxes()).forEach(function(q){if(q.op===6&&q.pf&&q.y1>1900&&q.y1<2200&&q.x1-q.x0+q.z1-q.z0>500)lf=q});R.porta=!!lf&&lf.x0>3300&&lf.z1<=1&&lf.z0<-700;
          /* basculante aberta: dobradiças, caneco e compasso/pistão aparecem */
          S.ops=[];S.mods=[];S.fr=[];draw();newTpl(tpl('Rack com portas basculantes'));newTpl(tpl('Aéreo basculante'));S.mods[1].x=1900;S.mods.forEach(function(q){q.v.forEach(function(v){v.open=true})});draw();__build();anim3();await new Promise(function(r){setTimeout(r,1800)});__build();R.dobBas=__boxes().filter(function(q){return q.pf&&q.pf.ax==='x'&&q.c&&q.c[0]===195&&q.c[1]===201}).length>=6;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["hist"] as? Bool, true, "editar no 2D só do módulo não tira a pedra do desfazer")
        XCTAssertEqual(o["desfazer"] as? Bool, true, "desfazer mantém a pedra")
        XCTAssertEqual(o["lixo"] as? Bool, true, "🗑 do 2D não tira pedra nem cuba")
        XCTAssertEqual(o["trava3d"] as? Bool, true, "pedra, cuba e cooktop travados no 3D")
        XCTAssertEqual(o["gel2d"] as? Bool, true, "geladeira aparece no 2D por cima da caixa")
        XCTAssertEqual(o["gelLado"] as? Bool, true, "geladeira aparece com a caixa na parede do lado")
        XCTAssertEqual(o["naoPerde"] as? Bool, true, "mudar a caixa de parede não perde nada")
        XCTAssertEqual(o["trena2d"] as? Bool, true, "trena no 2D gruda nas bordas e dá 900 mm")
        XCTAssertEqual(o["naoMexeu"] as? Bool, true, "medir não arrasta o módulo")
        XCTAssertEqual(o["trena3d"] as? Bool, true, "trena no 3D dá 900 mm")
        XCTAssertEqual(o["naoMexeu3"] as? Bool, true, "medir no 3D não arrasta o módulo")
        XCTAssertEqual(o["porta"] as? Bool, true, "porta do ambiente abre do lado direito pra fora")
        XCTAssertEqual(o["solida"] as? Bool, true, "a trena não atravessa o armário")
        XCTAssertEqual(o["toque"] as? Bool, true, "só tocar não cria trena")
        XCTAssertEqual(o["dobBas"] as? Bool, true, "basculante aberta mostra dobradiças e caneco")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Painéis lisos da parede: um não entra em cima do outro (o vizinho encurta e a junta continua), a placa recortada na porta é uma peça só no 3D e placa só até 2700 (o resto vai em cima depois da junta)
    func testPaineisLisosSemSobreporEPortaSemRiscoNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3979;S.H=2600;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.rp=[];S.ops=[{id:9,t:'porta',x:0,b:0,w:800,h:2100,st:'vao'}];draw();var R={};
          /* 4 placas com junta de 15 (rebaixo) e a primeira recortada na porta */
          var x=0;[983.5,983.5,983.5,983.5].forEach(function(w,i){var a={id:100+i,liso:true,x:x,b:0,w:w,h:2600,jt:{t:'reb',w:15,d:6}};if(Math.min(800,x+w)-Math.max(0,x)>1)a.rc={op:9,f:0};S.rp.push(a);x+=w+15});draw();
          /* a primeira cresce: a segunda encurta e a junta de 15 continua (uma não entra em cima da outra) */
          S.rp[0].w=1079;draw();var p=S.rp[0],q=S.rp[1];R.junta=Math.round((q.x-(p.x+p.w))*10)/10;R.w2=q.w;R.fim=Math.round((S.rp[3].x+S.rp[3].w)*10)/10;
          /* no 3D a placa recortada é uma peça só: sem risco de emenda em cima da porta (só o contorno) */
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var bx=__boxes().filter(function(b){return b.rpid===100});R.semRisco=bx.filter(function(b){return b.g!=='lo'}).every(function(b){return b.nol===1})&&bx.some(function(b){return b.g==='lo'&&Math.abs(b.x0-800)<1&&Math.abs(b.x1-1079)<1});
          /* regra: placa vai até 2700 · parede de 3100: em cima, depois da junta de 15, a continuação com a mesma largura */
          document.getElementById('v3x').click();S.H=3100;S.Hm=1;S.Wm=1;S.rp=[];S.ops=[];S.rodape=0;draw();S.trena={x0:1070,x1:3979};TRT='reb';TRJ=15;TRN=3;TRW=0;TRH=0;trCreate();var lo=S.rp.filter(function(a){return a.b===0}),hi=S.rp.filter(function(a){return a.b>0});
          R.max2700=Math.max.apply(null,S.rp.map(function(a){return a.h}))===2700;R.emCima=lo.length===3&&hi.length===3&&lo.every(function(a){return hi.some(function(u){return u.x===a.x&&u.w===a.w&&u.b===2715&&u.h===385})});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["junta"] as? Double, 15, "a junta de 15 continua entre as placas")
        XCTAssertEqual(o["w2"] as? Double, 888, "a placa vizinha encurta")
        XCTAssertEqual(o["fim"] as? Double, 3979, "a última placa continua no fim da parede")
        XCTAssertEqual(o["semRisco"] as? Bool, true, "placa recortada na porta sem risco de emenda no 3D")
        XCTAssertEqual(o["max2700"] as? Bool, true, "placa vai até 2700 de altura")
        XCTAssertEqual(o["emCima"] as? Bool, true, "acima de 2700: junta e a continuação em cima, mesma largura")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Trena no 3D: gruda sozinha no canto de dentro (parede + parede + chão) e na quina de fora do painel, e mede reto
    func testTrenaGrudaNoCantoPorDentroEPorFora() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          try{STD().supPedra=0}catch(_){}/* teste antigo: aéreo pela altura do chão (sem a regra dos 700 acima da pedra) */
          /* trena no 3D gruda no canto de dentro (parede + parede + chão) e na quina de fora do painel, e mede reto pelo chão */
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3979;S.H=2600;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.ops=[];S.rp=[];S.rodape=0;draw();
          S.trena={x0:1070,x1:3979};TRT='reb';TRJ=15;TRN=3;TRW=0;TRH=0;trCreate();draw();
          open3D();await new Promise(function(r){setTimeout(r,400)});__foto3({yaw:.45,pitch:.25});__foto3(null);__build();var R={};
          /* canto de dentro: parede da esquerda + parede do fundo + chão · toque 8 px fora do canto */
          var q=__p3(0,0,0);var h=__med3Hit(q[0]+8,q[1]-6);R.canto=h.map(Math.round);
          /* canto de fora do painel (quina de baixo esquerda do 1º painel, na frente) */
          var pz=__boxes().filter(function(b){return b.rpid!=null&&b.x0>=1069&&b.x0<=1071&&b.y0<1})[0];R.pz=pz?[pz.x0,pz.z1]:null;var q2=__p3(1070,0,pz?pz.z1:18);var h2=__med3Hit(q2[0]-6,q2[1]+5);R.quina=h2.map(Math.round);
          /* medir do canto até o painel pelo chão: reta, 1070 */
          document.getElementById('v3med').click();__build();q=__p3(0,0,0);q2=__p3(1070,0,pz?pz.z1:18);/* o Medir pode mudar a altura da tela: projeta de novo */var cv=document.getElementById('cv3'),cr=cv.getBoundingClientRect(),ev=function(tp,p){cv.dispatchEvent(new PointerEvent(tp,{clientX:cr.left+p[0],clientY:cr.top+p[1],pointerId:1,bubbles:true,isPrimary:true,pointerType:'touch'}))};
          ev('pointerdown',[q[0]+8,q[1]-6]);ev('pointermove',[q2[0]-6,q2[1]+5]);ev('pointerup',[q2[0]-6,q2[1]+5]);var M3=__med3(),L=M3.L[0];R.seg=L?JSON.stringify([L.a.map(Math.round),L.b.map(Math.round)]):null;R.len=L?Math.round(Math.hypot(L.b[0]-L.a[0],L.b[1]-L.a[1],L.b[2]-L.a[2])):0;
          R.canto0=JSON.stringify(R.canto)==='[0,0,0]';R.quinaOk=JSON.stringify(R.quina)==='[1070,0,18]';R.mede=R.len===1070;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["canto0"] as? Bool, true, "canto de dentro exato: \(o["canto"] ?? "")")
        XCTAssertEqual(o["quinaOk"] as? Bool, true, "quina de fora do painel exata: \(o["quina"] ?? "")")
        XCTAssertEqual(o["mede"] as? Bool, true, "do canto até o painel: 1070 (\(o["len"] ?? ""))")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Rack do zero (Sala): entra a caixa vazia com foto no catálogo e já abre o 2D só dele pra montar divisória, gaveta e porta
    func testRackDoZeroAbreSoEleParaMontar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3600;S.H=2600;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.ops=[];S.rp=[];draw();var R={};
          /* Rack do zero na Sala: entra a caixa vazia e já abre o 2D só dele pra montar (divisória, gavetas, porta) */
          var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q.n==='Rack do zero (você monta)')it=q})});R.noCatalogo=!!it&&CATS.some(function(c){return c.it.indexOf(it)>=0&&/Sala/.test(c.n)});R.foto=!!it&&!!FOTOS[fotoKey(it)];
          newTpl(it);await new Promise(function(r){setTimeout(r,200)});var m=S.mods[0];R.caixa=!!m&&m.v.length===1&&m.v[0].k==='free'&&m.w===1800;R.solo=window.SOLO2===m&&!document.getElementById('solobar').hidden;
          var c1=document.querySelector('#solobar [data-sov]');c1.click();document.querySelector('#vmenu [data-vk="split"]').click();document.querySelector('#vmenu [data-vk="dv|2"]').click();await new Promise(function(r){setTimeout(r,100)});
          var ch=[].slice.call(document.querySelectorAll('#solobar [data-sov]'));R.vaos=ch.length;ch[0].click();document.querySelector('#vmenu [data-vk="drawers"]').click();ch=[].slice.call(document.querySelectorAll('#solobar [data-sov]'));ch[2].click();document.querySelector('#vmenu [data-vk="door1"]').click();
          R.v=m.v.map(function(v){return v.k+(v.n||'')}).join();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["noCatalogo"] as? Bool, true, "Rack do zero na Sala")
        XCTAssertEqual(o["foto"] as? Bool, true, "com foto no catálogo")
        XCTAssertEqual(o["caixa"] as? Bool, true, "entra a caixa vazia")
        XCTAssertEqual(o["solo"] as? Bool, true, "abre o 2D só dele")
        XCTAssertEqual(o["vaos"] as? Int, 3, "2 divisórias = 3 vãos")
        XCTAssertEqual(o["v"] as? String, "drawers3,free1,door1", "gavetas, nicho e porta")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Sólido: peça nova não entra em outra (torres, prateleiras, geladeiras, air fryer, guarda-roupa, porta de correr no painel) e painel liso maior que a chapa sai em placas de 1800 × 2700 no sentido escolhido
    func testSolidoNadaEntraEmNadaEPainelSaiEmPlacasDaChapa() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          var fresh=function(room){S.room=room;S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw()};
          var clk=function(cid,re){window.CATALL=true;catOpen(cid);var c=CATS.filter(function(x){return x.id===cid})[0],k=-1;c.it.forEach(function(it,i){var t=typeof it==='number'?TPL[it]:it;if(k<0&&t&&re.test(t.n))k=i});document.querySelector('#catm [data-cati="'+cid+'|'+k+'"]').click();var m=document.getElementById('catm');if(m)m.hidden=true};
          var ov=function(a,b,c,d){return a<d-1&&c<b-1};
          /* torres: a 4ª não cabe mais na parede do fundo (pedra + 3 torres) e vai pra parede do lado, sem entrar em nada */
          fresh('cozinha');addStone();['Armário alto 2 portas','Despenseiro','Torre quente','Torre forno \\+ micro'].forEach(function(n){clk('alto',new RegExp('^'+n))});draw();
          R.torres=S.mods.filter(function(m){return modOverlaps(m)||!fitsHere(m)}).length;R.lado=S.mods.filter(function(m){return m.wing}).length;
          /* duas prateleiras suspensas: a segunda não entra na primeira (empilha) */
          fresh('sala');clk('sala',/^Prateleira suspensa · canto quadrado/);clk('sala',/^Prateleira suspensa · canto quadrado/);draw();var p=S.rp.filter(function(a){return a.prat});
          R.prat=p.length===2&&!(ov(p[0].x,p[0].x+p[0].w,p[1].x,p[1].x+p[1].w)&&ov(p[0].b-150,p[0].b+p[0].h+150,p[1].b,p[1].b+p[1].h));
          /* duas geladeiras e duas air fryers: lado a lado, dentro da parede e a air fryer em cima da pedra */
          fresh('cozinha');addStone();clk('cgel',/SS90X/);clk('cgel',/SS90X/);clk('clav',/Air fryer 4 L AFN-40/);clk('clav',/Air fryer 4 L AFN-40/);draw();
          var g=S.fr.filter(function(f){return f.t==='geladeira'}),af=S.fr.filter(function(f){return f.t==='airfryer'}),st=S.stones[0];
          R.gel=g.length===2&&!ov(g[0].x,g[0].x+g[0].w,g[1].x,g[1].x+g[1].w)&&g.every(function(f){return f.x>=0&&f.x+f.w<=S.W});
          R.af=af.length===2&&!ov(af[0].x,af[0].x+af[0].w,af[1].x,af[1].x+af[1].w)&&af.every(function(f){return f.y===af[0].y&&f.x>=st.x&&f.x+f.w<=st.x+st.w});
          /* catálogo sem módulo escolhido não quebra */
          fresh('cozinha');clk('inf',/^Módulo vazio/);clk('canto',/^Canto em L/);clk('ccoz',/^Cuba de embutir 50/);draw();
          /* guarda-roupa: as roupas da decoração ficam dentro dele (não viram caixas soltas no canto) */
          fresh('quarto');clk('dArm',/^2P 600mm/);clk('dArm',/^2P 600mm/);draw();__build();R.deco=__boxes().filter(function(b){return /Decora/.test(String(b.nm||''))}).length;R.dois=S.mods.length===2&&!modOverlaps(S.mods[1]);
          /* painel com porta de correr embutida: a folha corre no rasgo do batente, não entra na madeira */
          fresh('sala');clk('painel',/^Painel liso \+ porta de correr/);draw();__build();var a=S.rp[0],X=__boxes(),fo=X.filter(function(b){return b.rpd===a.id}),pa=X.filter(function(b){return b.rpid===a.id&&b.g!=='lo'});
          R.folha=fo.length>0&&!fo.some(function(f){return pa.some(function(q){return ov(f.x0,f.x1,q.x0,q.x1)&&ov(f.y0,f.y1,q.y0,q.y1)&&ov(f.z0,f.z1,q.z0,q.z1)})});
          /* painel liso esticado (4140 × 580): sai em placas de no máximo 1800 × 2700 no sentido escolhido e vai pro plano de corte */
          fresh('cozinha');S.W=4140;S.H=3190;S.Hm=1;S.Wm=1;var L=rpNew({x:0,b:2610,w:4140,h:580});L.liso=true;LAST='rp';S.tab=8;RPSEL=L.id;draw();panel();rpBar();
          R.pergunta=!!document.querySelector('#rpbar [data-rpb="ps|c"]')&&/maior que a chapa/.test(document.getElementById('rpbar').innerText);
          document.querySelector('#rpbar [data-rpb="ps|c"]').click();R.c=JSON.stringify(plPlates(L).cols);
          document.querySelector('#rpbar [data-rpb="ps|l"]').click();R.l=JSON.stringify(plPlates(L).cols);
          var G=cutGroups(),pc=G.ord.map(function(k){return G.map[k]}).filter(function(q){return /^Placa do painel liso/.test(q.names[0])});R.corte=pc.map(function(q){return q.qty+'x'+q.L+'x'+q.W}).join(' ');
          /* qualquer peça maior que a chapa sai em partes (prateleira de 3200) */
          var sh=rpNew({x:200,b:1750,w:3200,h:50});sh.prat=true;sh.pd=250;draw();G=cutGroups();R.partes=G.ord.some(function(k){return /em 2 partes/.test(G.map[k].names[0])&&G.map[k].L<=2730});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["torres"] as? Int, 0, "nenhuma torre entra em outra nem na pedra")
        XCTAssertEqual(o["lado"] as? Int, 1, "a que não cabe vai pra parede do lado")
        XCTAssertEqual(o["prat"] as? Bool, true, "prateleira nova não entra na outra")
        XCTAssertEqual(o["gel"] as? Bool, true, "geladeiras lado a lado, dentro da parede")
        XCTAssertEqual(o["af"] as? Bool, true, "air fryer ao lado da outra, em cima da pedra")
        XCTAssertEqual(o["deco"] as? Int, 0, "decoração dentro do guarda-roupa")
        XCTAssertEqual(o["dois"] as? Bool, true, "dois guarda-roupas sem sobrepor")
        XCTAssertEqual(o["folha"] as? Bool, true, "folha de correr no rasgo do batente")
        XCTAssertEqual(o["pergunta"] as? Bool, true, "pergunta o sentido do corte")
        XCTAssertEqual(o["c"] as? String, "[[0,2700],[2700,4140]]", "comprimento: 2700 + 1440")
        XCTAssertEqual(o["l"] as? String, "[[0,1800],[1800,3600],[3600,4140]]", "largura: 1800 + 1800 + 540")
        XCTAssertEqual(o["corte"] as? String, "2x580x1800 1x580x540", "placas no plano de corte no sentido certo")
        XCTAssertEqual(o["partes"] as? Bool, true, "peça maior que a chapa sai em partes")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Área do painel/ripado: toque no vão ou arraste marcando a área, o app acha as áreas livres (desvia de móvel, pedra, janela, eletro e outro painel), largura final e cria
    func testAreaDoPainelDesviaDosSolidosComLarguraFinal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          try{STD().supPedra=0}catch(_){}/* teste antigo: aéreo pela altura do chão (sem a regra dos 700 acima da pedra) */
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='cozinha';S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          addStone();S.stones[0].x=0;S.stones[0].w=3000;newTpl({n:'Balcão',w:1500,h:820,d:560,b:0,v:[{k:'door',n:2}]});newTpl({n:'Balcão',w:1500,h:820,d:560,b:0,v:[{k:'door',n:2}]});
          newTpl({n:'Aéreo',w:1400,h:700,d:350,b:1600,sup:true,v:[{k:'door',n:2}]});newTpl({n:'Aéreo',w:1400,h:700,d:350,b:1600,sup:true,v:[{k:'door',n:2}]});
          apAdd('geladeira',0);S.ops.push({id:99,t:'janela',w:600,h:800,x:3100,b:1300});S.tab=8;draw();panel();
          /* base do 2º balcão: no limite da pedra (não vai pra parede do lado, diminui um pouco) */
          R.balcao=S.mods.filter(function(m){return !m.sup}).map(function(m){return m.x+'+'+m.w+(m.wing||'')}).join(' ');
          /* toque no vão entre a pedra e o aéreo: a área livre vai da pedra até o aéreo e até a janela */
          document.querySelector('[data-rparm]').click();R.arm=!!(RPSA&&RPSA.arm)&&!RPSA.liso;
          RPSA.pt=[700,1200];RPSA.areas=saAreas();saBar();R.toque=JSON.stringify(RPSA.areas.map(function(a){return [a.x0,a.x1,a.y0,a.y1]}));
          /* largura final 2000 encostada na esquerda e cria o ripado */
          var inp=document.querySelector('#rpsabar [data-saw="0"]');inp.value='2000';inp.dispatchEvent(new Event('change',{bubbles:true}));document.querySelector('#rpsabar [data-sab="al|0|e"]').click();
          document.querySelector('#rpsabar [data-sab="go"]').click();R.criado=S.rp.map(function(a){return a.x+'+'+a.w+' b'+a.b+' h'+a.h+(a.liso?' liso':' ripado')}).join();R.fechou=!window.RPSA&&document.getElementById('rpsabar').hidden;
          /* arrastando a parede toda acima da pedra: várias áreas, nenhuma entra em móvel, pedra, janela, eletro ou no ripado que já está lá */
          saStart(true);RPSA.sel={x0:0,x1:4200,y0:0,y1:2700};RPSA.areas=saAreas();var sol=saSolids(false),bad=0;RPSA.areas.forEach(function(a){sol.forEach(function(q){if(a.x0<q.x1-1&&q.x0<a.x1-1&&a.y0<q.y1-1&&q.y0<a.y1-1)bad++})});R.areas=RPSA.areas.length;R.bad=bad;
          /* passar por trás dos móveis: a área acima da pedra fica inteira */
          document.querySelector('#rpsabar [data-sab="bh|1"]').click();R.atras=RPSA.areas.some(function(a){return a.y0<=860.5&&a.y1>=2300});
          document.querySelector('#rpsabar [data-sab="x"]').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["balcao"] as? String, "5+1500 1505+1465", "2º balcão diminui um pouco no limite da pedra")
        XCTAssertEqual(o["arm"] as? Bool, true, "botão arma a seleção de área")
        XCTAssertEqual(o["toque"] as? String, "[[0,3100,860,1600]]", "vão entre a pedra e o aéreo até a janela")
        XCTAssertEqual(o["criado"] as? String, "0+2000 b860 h740 ripado", "largura final 2000 encostada na esquerda")
        XCTAssertEqual(o["fechou"] as? Bool, true, "barra fecha depois de criar")
        XCTAssertGreaterThan(o["areas"] as? Int ?? 0, 3, "várias áreas livres na parede")
        XCTAssertEqual(o["bad"] as? Int, 0, "nenhuma área entra em algo sólido")
        XCTAssertEqual(o["atras"] as? Bool, true, "passando por trás dos móveis a área fica inteira")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Cor e veio dos painéis (placa lisa, ripas e fundo do ripado) com textura real no 3D, plano de corte por cor com veio travado, e a régua da junta em pé fecha o cruzamento com a junta de cima
    func testCorEVeioDosPaineisEReguaDaJuntaFechaOCruzamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=4140;S.H=3190;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var wood=MAT.filter(function(c){return c.cat==='wood'})[0],uni=MAT.filter(function(c){return c.cat!=='wood'})[0];
          /* painel liso grande: escolhe a cor amadeirada pela barra do painel e o sentido deitado (veio deitado) */
          var a=rpNew({x:0,b:2610,w:4140,h:580});a.liso=true;LAST='rp';S.tab=8;RPSEL=a.id;draw();panel();rpBar();
          R.secao=/Cor da placa/.test(document.getElementById('rpbar').innerText);
          document.querySelector('#rpbar [data-rpcor="cor|'+wood.id+'"]').click();document.querySelector('#rpbar [data-rpb="ps|c"]').click();
          R.cor=a.corId===wood.id&&a.cor===wood.hex;R.veio=rpVeio(a);
          /* ripado: ripas numa cor, fundo em outra */
          var r=rpNew({x:200,b:0,w:1200,h:2400});LAST='rp';RPSEL=r.id;draw();rpBar();document.querySelector('#rpbar [data-rpcor="cor|'+uni.id+'"]').click();document.querySelector('#rpbar [data-rpb="ct|b"]').click();document.querySelector('#rpbar [data-rpcor="corB|'+wood.id+'"]').click();
          R.ripado=r.corId===uni.id&&r.corBId===wood.id;
          /* 3D: textura real e veio deitado só no liso deitado */
          __build();var B=__boxes(),pl=B.filter(function(b){return b.rpid===a.id&&b.g!=='lo'}),rb=B.filter(function(b){return b.rpid===r.id&&b.rpart==='ripa'}),rf=B.filter(function(b){return b.rpid===r.id&&/^base/.test(b.rpart||'')});
          R.tex3d=pl.length>0&&pl.every(function(b){return b.mid===wood.id&&b.vr===1})&&rb.length>0&&rb.every(function(b){return b.mid===uni.id&&!b.vr})&&rf.length>0&&rf.every(function(b){return b.mid===wood.id})?1:0;
          /* plano de corte: as placas vão na chapa da cor certa, com o veio travado */
          var G=cutGroups(),pk=G.ord.filter(function(k){return /^Placa do painel liso/.test(G.map[k].names[0])});R.placas=pk.length>0&&pk.every(function(k){return G.map[k].colN===matLabel(wood)&&G.map[k].vfix===1});
          var sp=sheetPlan();R.chapa=sp.groups.some(function(g){return g.colN===matLabel(wood)&&g.mat===rpE()});
          R.ripas=G.ord.some(function(k){return /^Ripa/.test(G.map[k].names[0])&&G.map[k].colN===matLabel(uni)});
          /* "usar em todos": outro painel liso pega a mesma cor */
          var a2=rpNew({x:0,b:0,w:600,h:600});a2.liso=true;RPSEL=a.id;rpBar();document.querySelector('#rpbar [data-rpb="corall|cor"]').click();R.todos=a2.corId===wood.id;S.rp=S.rp.filter(function(q){return q!==a2});
          /* junta com rebaixo: a régua em pé de baixo sobe o vão da junta de cima (sem buraco no cruzamento) e o plano de corte sai com a medida certa */
          S.rp=[];var jt={t:'reb',w:15,d:6};var p1=rpNew({x:0,b:0,w:1800,h:2700}),p2=rpNew({x:1815,b:0,w:1800,h:2700}),p3=rpNew({x:0,b:2715,w:1800,h:475}),p4=rpNew({x:1815,b:2715,w:1800,h:475});[p1,p2,p3,p4].forEach(function(q){q.liso=true;q.jt=Object.assign({},jt)});draw();
          var gv=jtGaps(p1).filter(function(g){return g.dir==='v'})[0];R.regua=gv?gv.y0+'..'+gv.y1:'';
          R.corte=/Detalhe de rebaixo à direita da placa 1[^<]*<\/td><td>2715 × 15/.test(rpCutHtml());
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["secao"] as? Bool, true, "barra do painel tem a cor")
        XCTAssertEqual(o["cor"] as? Bool, true, "cor amadeirada na placa")
        XCTAssertEqual(o["veio"] as? String, "h", "chapa deitada = veio deitado")
        XCTAssertEqual(o["ripado"] as? Bool, true, "ripas e fundo com cores diferentes")
        XCTAssertEqual(o["tex3d"] as? Int, 1, "textura real no 3D, veio girado só na placa deitada")
        XCTAssertEqual(o["placas"] as? Bool, true, "placas no plano de corte com a cor e o veio travado")
        XCTAssertEqual(o["chapa"] as? Bool, true, "chapa da cor certa no plano")
        XCTAssertEqual(o["ripas"] as? Bool, true, "ripas na cor delas")
        XCTAssertEqual(o["todos"] as? Bool, true, "usar a cor em todos os painéis")
        XCTAssertEqual(o["regua"] as? String, "0..2715", "régua em pé sobe os 15 da junta de cima")
        XCTAssertEqual(o["corte"] as? Bool, true, "plano de corte com a régua de 2715")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Pintar painéis: pelo 3D (pincel, conta-gotas e borracha, sem selecionar o painel) e pela aba Cores › ▥ Painéis (mesmo sem módulo), com o veio
    func testPintarPaineisPelo3DEPelaAbaCores() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='quarto';S.env='livre';S.W=3841;S.H=3215;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var wood=MAT.filter(function(c){return /Louro Freij/.test(c.n)})[0]||MAT.filter(function(c){return c.cat==='wood'})[0],uni=MAT.filter(function(c){return c.cat!=='wood'})[2];
          /* parede de painéis lisos (sem nenhum módulo) + um ripado */
          var P=[];for(var i=0;i<3;i++){var a=rpNew({x:i*960,b:0,w:949,h:2700});a.liso=true;P.push(a)}var r=rpNew({x:2880,b:0,w:900,h:2400});draw();
          /* 2D: aba Cores › ▥ Painéis aparece mesmo sem módulo e pinta todos os lisos */
          S.tab=10;CORTAB='arm';panel();R.dica=/aba <b>▥ Painéis<\/b>/.test(document.getElementById('bd').innerHTML)||/Painéis/.test(document.getElementById('bd').innerText);
          document.querySelector('[data-cortab="pain"]').click();R.aba=!!document.querySelector('[data-cpn="liso"]');
          document.querySelector('[data-cpnc="'+uni.id+'"]').click();R.lisos=P.every(function(a){return a.corId===uni.id});
          document.querySelector('[data-cpn="rip"]').click();document.querySelector('[data-cpnc="'+wood.id+'"]').click();R.ripas=r.corId===wood.id&&!P.some(function(a){return a.corId===wood.id});
          document.querySelector('[data-cpn="liso"]').click();document.querySelector('[data-cpnv="c"]').click();R.veio=P.every(function(a){return a.ps==='c'});
          /* 3D: pincel com Louro Freijó pinta só o painel tocado; conta-gotas copia a cor do painel */
          open3D();await new Promise(function(q){setTimeout(q,300)});document.getElementById('v3pt').click();window.PT3={c:wood.hex,n:matLabel(wood),id:wood.id,erase:false};
          __build();var b=__boxes().filter(function(q){return q.rpid===P[1].id&&q.g!=='lo'})[0];__pt3tapBox(b);R.pinta3d=P[1].corId===wood.id&&P[0].corId===uni.id;
          __build();R.tex=__boxes().filter(function(q){return q.rpid===P[1].id&&q.g!=='lo'}).every(function(q){return q.mid===wood.id});
          window.PT3={c:'#000000',n:'x',id:'',erase:false,pick:true};var b0=__boxes().filter(function(q){return q.rpid===P[0].id&&q.g!=='lo'})[0];__pt3tapBox(b0);R.copia=PT3.id===uni.id;
          window.PT3={c:'',n:'',id:'',erase:true};__build();b=__boxes().filter(function(q){return q.rpid===P[2].id&&q.g!=='lo'})[0];__pt3tapBox(b);R.apaga=!P[2].cor;
          /* toque de verdade na tela em cima do 1º painel */window.PT3={c:wood.hex,n:matLabel(wood),id:wood.id,erase:false};__build();var c3=__p3(P[0].x+P[0].w/2,1200,60);paintTap(c3[0],c3[1]);R.toque=P[0].corId===wood.id;
          try{document.getElementById('v3x').click()}catch(_){}R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["dica"] as? Bool, true, "sem módulo aponta pra aba Painéis")
        XCTAssertEqual(o["aba"] as? Bool, true, "aba ▥ Painéis em Cores")
        XCTAssertEqual(o["lisos"] as? Bool, true, "pinta todos os painéis lisos")
        XCTAssertEqual(o["ripas"] as? Bool, true, "pinta só as ripas")
        XCTAssertEqual(o["veio"] as? Bool, true, "veio deitado em todos")
        XCTAssertEqual(o["pinta3d"] as? Bool, true, "pincel do 3D pinta só o painel tocado")
        XCTAssertEqual(o["tex"] as? Bool, true, "textura real no 3D")
        XCTAssertEqual(o["copia"] as? Bool, true, "conta-gotas copia a cor do painel")
        XCTAssertEqual(o["apaga"] as? Bool, true, "borracha tira a cor")
        XCTAssertEqual(o["toque"] as? Bool, true, "toque na tela em cima do painel pinta")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// 2 toques na parede no 3D: sem nada escolhido pergunta (porta, vão, janela) e cria ali; com a porta escolhida ela vai pra lá; medidas digitadas no quadro
    func testDoisToquesNaParedeCriaEMovePortaEJanela() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();open3D();await new Promise(function(q){setTimeout(q,400)});__build();
          /* 2 toques na parede do fundo, sem nada escolhido: pergunta o que criar ali */
          var c=__p3(2500,1200,0);__sel3(c[0],c[1]);var ch=document.getElementById('opch3');R.pergunta=!!ch&&!ch.hidden&&/Porta aqui/.test(ch.innerText)&&/Janela aqui/.test(ch.innerText);
          ch.querySelector('[data-och="porta"]').click();var o=S.ops[S.ops.length-1];R.porta=o&&o.t==='porta'&&!o.st&&(o.wall||'f')==='f'&&Math.abs(o.x+o.w/2-2500)<=2&&o.b===0;
          /* com a porta escolhida, 2 toques na parede da esquerda: ela vai pra lá */
          __build();var c2=__p3(0,1000,1500),hw=__wallHit3(c2[0]+4,c2[1]);__sel3(c2[0]+4,c2[1]);R.esquerda=!!hw&&hw.w==='e'&&o.wall==='e'&&Math.abs(o.x+o.w/2-hw.a)<=2;
          /* medidas digitadas no quadro */
          var inp=document.querySelector('[data-ofi="w"]');inp.value='900';inp.dispatchEvent(new Event('change',{bubbles:true}));R.largura=o.w===900;
          inp=document.querySelector('[data-ofi="x"]');inp.value='600';inp.dispatchEvent(new Event('change',{bubbles:true}));R.posicao=o.x===600;
          /* janela: criada na altura do toque */
          __opSel(0);try{document.querySelector('[data-ox="1"]').click()}catch(_){}__build();var c3=__p3(1000,1500,0);__sel3(c3[0],c3[1]);ch=document.getElementById('opch3');ch.querySelector('[data-och="janela"]').click();var j=S.ops[S.ops.length-1];
          R.janela=j.t==='janela'&&(j.wall||'f')==='f'&&Math.abs(j.b+j.h/2-1500)<=2&&Math.abs(j.x+j.w/2-1000)<=2;
          inp=document.querySelector('[data-ofi="b"]');inp.value='1100';inp.dispatchEvent(new Event('change',{bubbles:true}));R.chao=j.b===1100;
          /* vão (passagem) */
          __opSel(0);__build();var c4=__p3(3300,1000,0);__sel3(c4[0],c4[1]);document.getElementById('opch3').querySelector('[data-och="vao"]').click();var v=S.ops[S.ops.length-1];R.vao=v.t==='porta'&&v.st==='vao'&&v.x+v.w<=S.W;
          /* "Só voltar a vista" não cria nada */
          __opSel(0);var n0=S.ops.length;__build();__sel3(c[0],c[1]);document.getElementById('opch3').querySelector('[data-och="vista"]').click();R.vista=S.ops.length===n0;
          /* no 2D também aparece */
          document.getElementById('v3x').click();draw();R.no2d=S.ops.length===3;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["pergunta"] as? Bool, true, "pergunta o que criar na parede")
        XCTAssertEqual(o["porta"] as? Bool, true, "porta com folha onde tocou")
        XCTAssertEqual(o["esquerda"] as? Bool, true, "porta escolhida vai pra parede da esquerda")
        XCTAssertEqual(o["largura"] as? Bool, true, "largura digitada")
        XCTAssertEqual(o["posicao"] as? Bool, true, "posição digitada")
        XCTAssertEqual(o["janela"] as? Bool, true, "janela na altura do toque")
        XCTAssertEqual(o["chao"] as? Bool, true, "altura do chão digitada")
        XCTAssertEqual(o["vao"] as? Bool, true, "vão (passagem)")
        XCTAssertEqual(o["vista"] as? Bool, true, "só voltar a vista não cria nada")
        XCTAssertEqual(o["no2d"] as? Bool, true, "aparece no 2D")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Régua do rebaixo das juntas: cor própria (Cores, painel e pincel do 3D) e no plano de corte; vão nas paredes do lado igual ao do fundo
    func testReguaDoRebaixoPintaEVaoNaParedeDoLado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=3215;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var wood=MAT.filter(function(c){return /Louro Freij/.test(c.n)})[0]||MAT.filter(function(c){return c.cat==='wood'})[0],preto=MAT.filter(function(c){return c.cat!=='wood'&&/preto|black|grafite/i.test(c.n)})[0]||MAT.filter(function(c){return c.cat!=='wood'})[0];
          /* duas fileiras de placas lisas com junta de rebaixo 15 */
          var jt={t:'reb',w:15,d:6},P=[];[[0,0,1800,2700],[1815,0,1800,2700],[0,2715,1800,500],[1815,2715,1800,500]].forEach(function(q){var a=rpNew({x:q[0],b:q[1],w:q[2],h:q[3]});a.liso=true;a.jt=Object.assign({},jt);a.cor=wood.hex;a.corId=wood.id;P.push(a)});draw();
          /* a régua sai na cor da placa (um pouco mais escura), em #hex (no 3D não fica branca) */
          var g=jtGaps(P[0]).filter(function(q){return q.dir==='v'})[0];R.hex=/^#[0-9a-f]{6}$/.test(g.c);
          /* Cores › Painéis › Rebaixo das juntas: pinta todas as réguas */
          S.tab=10;panel();document.querySelector('[data-cortab="pain"]').click();document.querySelector('[data-cpn="junta"]').click();document.querySelector('[data-cpnc="'+preto.id+'"]').click();R.todas=P.every(function(a){return a.corJId===preto.id});
          open3D();await new Promise(function(q){setTimeout(q,300)});__build();var J=__boxes().filter(function(b){return b.rpart==='junta'});R.junta3d=J.length>0&&J.every(function(b){return b.mid===preto.id&&b.rpid!=null});
          /* pincel do 3D na régua: pinta só a régua */
          document.getElementById('v3pt').click();window.PT3={c:wood.hex,n:matLabel(wood),id:wood.id,erase:false};__pt3tapBox(J[0]);var dono=P.filter(function(a){return a.id===J[0].rpid})[0];R.pincel=dono.corJId===wood.id&&dono.corId===wood.id;try{pt3Off()}catch(_){}
          /* plano de corte: a régua na cor dela */
          var G=cutGroups();R.corte=G.ord.some(function(k){return /^Detalhe de rebaixo/.test(G.map[k].names[0])&&!!G.map[k].colN});
          /* ⬆ completar acima: 15 mm de junta e já sai com a cor da placa e da régua */
          S.rp=[];var pa=rpNew({x:0,b:0,w:1800,h:2700});pa.liso=true;pa.jt={t:'reb',w:15,d:6};pa.cor=wood.hex;pa.corId=wood.id;pa.corJ=preto.hex;pa.corJId=preto.id;var n0=S.rp.length;pwAbove(pa);var up=S.rp.slice(n0);R.acima=up.length===1&&up[0].b===2715&&up[0].corId===wood.id&&up[0].corJId===preto.id;
          /* vão na parede da esquerda: a parede é recortada (dá pra ver a passagem), igual à do fundo */
          S.rp=[];S.ops=[{id:1,t:'porta',st:'vao',w:800,h:2100,x:468,b:0,wall:'e'}];document.getElementById('v3x').click();draw();open3D();await new Promise(function(q){setTimeout(q,300)});var vb=document.querySelector('#v3 [data-v="left"]');if(vb)vb.click();await new Promise(function(q){setTimeout(q,200)});__build();
          var c=__p3(0,1000,868),r=__ray(c[0],c[1]);R.furo=!!r&&r.p[0]<-50;var c2=__p3(0,1000,2500),r2=__ray(c2[0],c2[1]);R.parede=!!r2&&Math.abs(r2.p[0])<2;
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["hex"] as? Bool, true, "régua na cor da placa (hex)")
        XCTAssertEqual(o["todas"] as? Bool, true, "Cores › Painéis pinta todas as réguas")
        XCTAssertEqual(o["junta3d"] as? Bool, true, "réguas do 3D com a cor escolhida")
        XCTAssertEqual(o["pincel"] as? Bool, true, "pincel do 3D pinta só a régua")
        XCTAssertEqual(o["corte"] as? Bool, true, "plano de corte com a cor da régua")
        XCTAssertEqual(o["acima"] as? Bool, true, "completar acima: junta de 15 e mesma cor")
        XCTAssertEqual(o["furo"] as? Bool, true, "parede da esquerda recortada no vão")
        XCTAssertEqual(o["parede"] as? Bool, true, "fora do vão a parede continua")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Parede com porta ou vão sai inteira: sem risco nem emenda em cima da porta (fundo e lados); janela não recorta a parede
    func testParedeSemRiscoEmCimaDaPortaEJanela() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.stones=[];S.st=null;S.m=null;
          /* vão e porta no fundo, porta e vão na esquerda, janela no fundo e na direita */
          S.ops=[{id:1,t:'porta',st:'vao',w:800,h:2100,x:1500,b:0,wall:'f'},{id:2,t:'porta',w:800,h:2100,x:2600,b:0,wall:'f'},{id:3,t:'janela',w:1000,h:1000,x:300,b:1100,wall:'f'},{id:4,t:'porta',w:800,h:2100,x:900,b:0,wall:'e'},{id:5,t:'porta',st:'vao',w:900,h:2100,x:2000,b:0,wall:'e'},{id:6,t:'janela',w:1200,h:1000,x:700,b:1100,wall:'d'}];
          draw();open3D();await new Promise(function(q){setTimeout(q,400)});__build();
          var pol=function(b){return b.pf?b.pf.pts:b.poly?b.poly:[[b.x0,b.y0],[b.x1,b.y0],[b.x1,b.y1],[b.x0,b.y1]]},area=function(P){var a=0;for(var i=0;i<P.length;i++){var p=P[i],q=P[(i+1)%P.length];a+=p[0]*q[1]-q[0]*p[1]}return Math.abs(a)/2};
          var chk=function(wl,ow){var ps=__bg().filter(function(b){return b.wl===wl&&!b.cs&&b.c&&(b.pf||b.poly||b.x1-b.x0>50)&&(wl==='F'?b.z1<=0.01&&b.z0<-50:true)}),ds=S.ops.filter(function(o){return o.t==='porta'&&(o.wall||'f')===ow}),risco=0,jamb=0;
            ps.forEach(function(b){var P=pol(b);for(var k=0;k<P.length;k++){var p=P[k],q=P[(k+1)%P.length];if(Math.abs(p[0]-q[0])>.01)continue;var y0=Math.min(p[1],q[1]),y1=Math.max(p[1],q[1]),hid=b.he&&b.he.indexOf(k)>=0;ds.forEach(function(o){if(Math.abs(p[0]-o.x)>.6&&Math.abs(p[0]-o.x-o.w)>.6)return;if(!hid&&y1>o.b+o.h+1)risco++;if(!hid&&y1<=o.b+o.h+.5&&y0<=.5)jamb++})}});return {n:ps.length,risco:risco,jamb:jamb,ps:ps}};
          var F=chk('F','f'),L=chk('L','e');R.fundo=F.risco===0&&F.jamb>=4;R.esquerda=L.risco===0&&L.jamb>=4;
          /* a parede do fundo continua inteira (só falta o vão das portas) */
          var xs=[];F.ps.forEach(function(b){pol(b).forEach(function(p){xs.push(p[0])})});var X0=Math.min.apply(null,xs),X1=Math.max.apply(null,xs),A=F.ps.reduce(function(s,b){return s+area(pol(b))},0);R.inteira=Math.abs(A-((X1-X0)*2700-800*2100*2))<5;
          /* janela não recorta a parede (nada de emenda) */
          R.janela=__bg().filter(function(b){return b.wl==='R'&&(b.poly||b.pf)}).length===1&&!__bg().some(function(b){return b.wl==='R'&&b.he});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["fundo"] as? Bool, true, "parede do fundo sem risco em cima da porta, só o contorno do vão")
        XCTAssertEqual(o["esquerda"] as? Bool, true, "parede da esquerda sem risco em cima da porta")
        XCTAssertEqual(o["inteira"] as? Bool, true, "parede inteira, só falta o vão")
        XCTAssertEqual(o["janela"] as? Bool, true, "janela não recorta a parede")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Rack do zero entra suspenso no meio do painel (moldura e régua de escolha, tampo em cima), painel aparece no 2D só dele,
    /// ⇔ Centralizar rack e prateleira (sobra igual dos dois lados) e sem painel fica no meio da parede
    func testRackNoMeioDoPainelSuspensoECentralizar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var pick=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n===nm)it=q})});return it},sob=function(m,a,b){return [(m.x-lt(m))-a,b-(m.x+m.w+rt(m))]};
          /* painel liso 2400 (2 placas) e o rack do zero: entra suspenso, sem pedestal, com moldura e régua, no meio do painel */
          var p1=rpNew({x:1000,b:0,w:1200,h:2700});p1.liso=true;var p2=rpNew({x:2215,b:0,w:1200,h:2700});p2.liso=true;draw();
          var tt=JSON.parse(JSON.stringify(pick('Rack do zero (você monta)')));tt.sup=!!tt.sup;newTpl(tt);await new Promise(function(r){setTimeout(r,300)});var m=S.mods[0],s0=sob(m,1000,3415);
          R.suspenso=m.b===350&&!m.rod&&!!m.mold&&!!m.trav;R.meio=Math.abs(s0[0]-s0[1])<=.5&&m.tl===m.tr;
          /* no 2D só dele o painel continua aparecendo (apagado, sem mexer) */
          R.solo=window.SOLO2===m&&!!document.querySelector('#svg g[opacity=".35"] [data-rp]');
          var P=function(){return partsOf(m).map(function(p){return p.name}).join('|')};R.pecas=/Moldura de acabamento/.test(P())&&/Travessa frontal/.test(P());/* rack não leva pedra: tem tampo em cima mesmo com a régua */R.tampo=/Base superior/.test(P())&&__build()===undefined&&__boxes().some(function(b){return String(b.nm||'').indexOf('0:Base superior')===0&&Math.abs(b.y1-850)<1});
          /* moldura e régua saem e voltam pelo cabeçalho */
          var cl=function(k){document.querySelector('#solobar [data-sorc="'+k+'"]').click()};cl('mold');cl('trav');R.tira=!m.mold&&!m.trav&&!/Moldura de acabamento/.test(P())&&!/Travessa frontal/.test(P());cl('mold');cl('trav');R.volta=!!m.mold&&!!m.trav;
          cl('sus');R.chao=m.b===0&&!!m.rod;cl('sus');R.sobe=m.b===350&&!m.rod;
          /* arrastou pro lado: ⇔ Centralizar volta pro meio, sobra igual dos dois lados */
          m.x=1150;draw();cl('ctr');var s1=sob(m,1000,3415);R.centraliza=Math.abs(s1[0]-s1[1])<=.5&&s1[0]>0;
          /* prateleira: centraliza no painel, até meio milímetro */
          var pr=rpNew({x:1300,b:1750,w:1001,h:50});pr.prat=true;pr.pd=250;LAST='rp';RPSEL=pr.id;soloOff();draw();panel();var bt=document.querySelector('[data-rpctr]');R.botao=!!bt;if(bt)bt.click();R.prat=Math.abs((pr.x-1000)-(3415-pr.x-pr.w))<.01;
          /* sem painel: no meio da parede */
          S.mods=[];S.rp=[];draw();newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso'))));await new Promise(function(r){setTimeout(r,100)});var m2=S.mods[0],s2=sob(m2,0,S.W);R.parede=Math.abs(s2[0]-s2[1])<=.5;try{soloOff()}catch(_){}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["suspenso"] as? Bool, true, "rack do zero entra suspenso, sem pedestal, com moldura e régua")
        XCTAssertEqual(o["meio"] as? Bool, true, "rack entra no meio do painel")
        XCTAssertEqual(o["solo"] as? Bool, true, "no 2D só do rack o painel continua aparecendo")
        XCTAssertEqual(o["pecas"] as? Bool, true, "moldura e régua no plano de corte")
        XCTAssertEqual(o["tampo"] as? Bool, true, "rack tem tampo em cima mesmo com a régua")
        XCTAssertEqual(o["tira"] as? Bool, true, "tira moldura e régua pelo cabeçalho")
        XCTAssertEqual(o["volta"] as? Bool, true, "volta moldura e régua")
        XCTAssertEqual(o["chao"] as? Bool, true, "rack no chão com pedestal")
        XCTAssertEqual(o["sobe"] as? Bool, true, "rack suspenso de novo")
        XCTAssertEqual(o["centraliza"] as? Bool, true, "⇔ Centralizar: sobra igual dos dois lados")
        XCTAssertEqual(o["botao"] as? Bool, true, "botão Centralizar na barra da prateleira")
        XCTAssertEqual(o["prat"] as? Bool, true, "prateleira centralizada no painel")
        XCTAssertEqual(o["parede"] as? Bool, true, "sem painel: rack no meio da parede")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Localizador da chapa: tocar na placa do painel no plano de corte acende ela em rosa no 3D (por cima da cor/madeira),
    /// cada peça de painel acha a sua, régua do rebaixo acende só as réguas e a folha da porta embutida acende a folha
    func testLocalizadorDaChapaAchaAPlacaDoPainelNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          S.room='sala';S.env='livre';S.W=6000;S.H=3215;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var wood=MAT.filter(function(c){return /Louro Freij/.test(c.n)})[0]||MAT.filter(function(c){return c.cat==='wood'})[0];
          /* painel liso maior que a chapa (2 placas) em Louro Freijó, com rebaixo · ripado com porta embutida · liso com porta de correr · prateleira */
          var a1=rpNew({x:0,b:0,w:2400,h:2700});a1.liso=true;a1.jt={t:'reb',w:15,d:6};a1.cor=wood.hex;a1.corId=wood.id;var a2=rpNew({x:0,b:2715,w:2400,h:500});a2.liso=true;a2.jt={t:'reb',w:15,d:6};
          var a3=rpNew({x:2500,b:0,w:1500,h:2600});a3.pt={x:300,w:800,h:2100};var a4=rpNew({x:4100,b:0,w:1200,h:2600});a4.liso=true;a4.pt={x:200,w:800,h:2100,tipo:'correr',lado:'d'};var a5=rpNew({x:5400,b:1500,w:500,h:50});a5.prat=true;a5.pd=250;draw();
          var pink=function(){return __boxes().filter(function(b){return b.a===1&&b.c&&b.c[0]===227&&b.c[1]===25&&b.c[2]===123})};
          /* toque na peça desenhada na chapa (plano de corte) */
          openCut();var ps=[].slice.call(document.querySelectorAll('#cutbody [data-cp]')).filter(function(g){return /^Placa do painel liso 1 · placa 2 de 2/.test(g.dataset.lab)});R.naChapa=ps.length>0;
          ps[0].dispatchEvent(new MouseEvent('click',{bubbles:true}));await new Promise(function(r){setTimeout(r,700)});__build();var P=pink();
          R.acha=P.length>0&&P.every(function(b){return b.rpid===a1.id&&b.rpart==='placa2'});R.rosa=P.length>0&&P.every(function(b){return !b.mid});R.banner=!document.getElementById('v3hl').hidden;
          /* cada peça de painel do plano acha alguma coisa no 3D (e só do painel dela) */
          var G=cutGroups(),tot=0,ok=0,fal=[];G.ord.forEach(function(k){var g=G.map[k],seen={};(g.src||[]).forEach(function(sub){var ss=srcStr(Array.isArray(sub)?sub:[sub]);if(ss.indexOf('rp|')<0||seen[ss])return;seen[ss]=1;tot++;show3D(ss,g.names[0]);__build();var p=pink(),id=ss.split('|')[1];if(p.length&&p.every(function(b){return String(b.rpid)===id||String(b.rpd)===id})&&!p.some(function(b){return b.mid}))ok++;else fal.push(g.names[0].slice(0,40))})});
          R.todas=tot>10&&ok===tot;R.fal=fal.join(' / ');
          /* régua do rebaixo acende só as réguas · folha da porta embutida acende a folha */
          var jr=G.ord.map(function(k){return G.map[k]}).filter(function(g){return /^Detalhe de rebaixo/.test(g.names[0])})[0];show3D(srcStr(jr.src[0]),'r');__build();R.regua=pink().length>0&&pink().every(function(b){return b.rpart==='junta'});
          var fo=G.ord.map(function(k){return G.map[k]}).filter(function(g){return /^Folha da porta/.test(g.names[0])})[0];show3D(srcStr(fo.src[0]),'f');__build();R.folha=pink().length>0&&pink().every(function(b){return b.rpd===a4.id});
          try{document.getElementById('v3x').click()}catch(_){}R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["naChapa"] as? Bool, true, "placa do painel desenhada na chapa")
        XCTAssertEqual(o["acha"] as? Bool, true, "toque na placa 2 acende só a placa 2 no 3D")
        XCTAssertEqual(o["rosa"] as? Bool, true, "rosa por cima da madeira")
        XCTAssertEqual(o["banner"] as? Bool, true, "faixa da peça localizada")
        XCTAssertEqual(o["todas"] as? Bool, true, "toda peça de painel acha a sua: \(o["fal"] ?? "")")
        XCTAssertEqual(o["regua"] as? Bool, true, "régua do rebaixo acende só as réguas")
        XCTAssertEqual(o["folha"] as? Bool, true, "folha da porta embutida")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// ⧉ Copiar: módulo pela Estrutura e pelo 2D só dele (sai igual, do lado, sem entrar em nada), prateleira (em cima/embaixo) e painel; sem lugar avisa
    func testCopiarModuloPainelEPrateleira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=3215;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          var pick=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n===nm)it=q})});return it};
          /* rack suspenso com portas: Estrutura › ⧉ Copiar este módulo · sai outro igual do lado, sem entrar em nada */
          newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso basculante'))));try{soloOff()}catch(_){}var m=S.mods[0];m.x=40;m.cor='#7a5230';draw();S.tab=1;panel();
          var b=document.querySelector('[data-mcopy]');R.botao=!!b;b.click();var c=S.mods[1];if(!c)return JSON.stringify({semCopia:1,errs:__errs});
          R.igual=!!c&&c!==m&&c.w===m.w&&c.h===m.h&&c.d===m.d&&c.b===m.b&&c.cor===m.cor&&JSON.stringify(c.v)===JSON.stringify(m.v)&&JSON.stringify(c.div)===JSON.stringify(m.div);
          R.lado=!!c&&c.x-lt(c)>=m.x+m.w+rt(m)-.5&&!modOverlaps(c)&&!modOverlaps(m);R.escolhido=S.m===c;
          /* cópia independente: mexer na cópia não muda o original */c.w=c.w-100;R.independente=m.w!==c.w;
          /* prateleira de módulo (aérea fina): cópia vai pra cima ou pra baixo */
          S.mods=[];draw();newTpl({n:'Prateleira com LED',w:1200,h:60,d:250,b:1750,sup:true,v:[{k:'free',n:1}]});var p=S.mods[0];p.x=800;p.b=1750;draw();var p2=modCopy(p);R.pratModulo=!!p2&&p2.x===p.x&&Math.abs(p2.b-p.b)===350&&!modOverlaps(p2);
          /* 2D só dele: ⧉ Copiar no cabeçalho */
          soloOn(p2);await new Promise(function(r){setTimeout(r,50)});var n0=S.mods.length;var sb=document.querySelector('#solobar [data-sorc="copy"]');R.solo=!!sb;if(sb)sb.click();R.soloCopia=S.mods.length===n0+1;try{soloOff()}catch(_){}
          /* prateleira suspensa (painel): ⧉ Copiar na barra · vai pra 350 embaixo ou em cima, mesma largura */
          S.mods=[];var pr=rpNew({x:600,b:1750,w:1200,h:50});pr.prat=true;pr.pd=250;pr.rd=60;LAST='rp';RPSEL=pr.id;draw();panel();var cb=document.querySelector('[data-rpcopy]');R.barra=!!cb;if(cb)cb.click();var q=S.rp[S.rp.length-1];
          R.prat=!!q&&q!==pr&&q.prat&&q.w===pr.w&&q.pd===pr.pd&&q.rd===pr.rd&&q.x===pr.x&&Math.abs(q.b-pr.b)===350&&q.id!==pr.id;
          /* painel liso: cópia sai do lado, sem entrar no outro */
          var pl=rpNew({x:0,b:0,w:900,h:2700});pl.liso=true;pl.cor='#8a6a4a';var old=S.rp.slice();var pc=rpCopy(pl);R.painel=!!pc&&pc.liso&&pc.cor===pl.cor&&pc.w===900&&(pc.x>=pl.x+pl.w-.5||pc.x+pc.w<=pl.x+.5);
          /* sem lugar na parede: não cria por cima de nada, avisa */
          S.mods=[];S.rp=[];draw();newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso basculante'))));try{soloOff()}catch(_){}var mm=S.mods[0];mm.x=900;draw();R.semLugar=modCopy(mm)===null&&S.mods.length===1;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semCopia"] as? Int, nil, "o rack tinha que copiar")
        XCTAssertEqual(o["botao"] as? Bool, true, "botão Copiar na Estrutura")
        XCTAssertEqual(o["igual"] as? Bool, true, "cópia igual (medidas, vãos, divisões, cor)")
        XCTAssertEqual(o["lado"] as? Bool, true, "cópia do lado, sem entrar em nada")
        XCTAssertEqual(o["escolhido"] as? Bool, true, "a cópia fica escolhida")
        XCTAssertEqual(o["independente"] as? Bool, true, "mexer na cópia não muda o original")
        XCTAssertEqual(o["pratModulo"] as? Bool, true, "prateleira de módulo: cópia em cima ou embaixo")
        XCTAssertEqual(o["solo"] as? Bool, true, "Copiar no 2D só dele")
        XCTAssertEqual(o["soloCopia"] as? Bool, true, "copiou pelo 2D só dele")
        XCTAssertEqual(o["barra"] as? Bool, true, "Copiar na barra da prateleira")
        XCTAssertEqual(o["prat"] as? Bool, true, "prateleira copiada igual, 350 embaixo ou em cima")
        XCTAssertEqual(o["painel"] as? Bool, true, "painel copiado do lado")
        XCTAssertEqual(o["semLugar"] as? Bool, true, "sem lugar: não cria por cima, avisa")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Desenho 2D sem texto em cima de texto nem da trena (sala com rack no chão e suspenso, cozinha, exemplo, quarto)
    func testDesenhoSemTextoEmCimaDeTexto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;
          window.__ovl=function(){var svg=document.getElementById('svg'),T=[].slice.call(svg.querySelectorAll('text')).filter(function(t){var r=t.getBoundingClientRect();return r.width>2&&r.height>2&&t.textContent.trim()&&getComputedStyle(t).display!=='none'}),
           O=[].slice.call(svg.querySelectorAll('rect[fill="#f5c400"],circle[data-trh]')).map(function(e){return {r:e.getBoundingClientRect(),n:'trena'}}),ov=[];
           var hit=function(a,b,m){var ix=Math.min(a.right,b.right)-Math.max(a.left,b.left),iy=Math.min(a.bottom,b.bottom)-Math.max(a.top,b.top);return ix>m&&iy>m};
           for(var i=0;i<T.length;i++){var a=T[i].getBoundingClientRect();for(var j=i+1;j<T.length;j++){var b=T[j].getBoundingClientRect();if(hit(a,b,2))ov.push(T[i].textContent.slice(0,28)+' X '+T[j].textContent.slice(0,28))}
            if(!/^Trena|^\d$/.test(T[i].textContent))O.forEach(function(o){if(hit(a,o.r,2))ov.push(T[i].textContent.slice(0,28)+' X '+o.n)})}
           return ov.filter(function(v,i,s){return s.indexOf(v)===i})};
          window.MINI3OFF=1;PR.setupDone=1;var R={};var pick=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n===nm)it=q})});return it};
          var run=function(tag,setup){S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;setup();try{soloOff()}catch(_){}draw();panel();var all=[];for(var i=-1;i<S.mods.length;i++){S.m=i<0?null:S.mods[i];LAST='';draw();__ovl().forEach(function(v){if(all.indexOf(v)<0)all.push(v)})}R[tag]=all};
          run('salaChao',function(){S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;for(var i=0;i<4;i++){var a=rpNew({x:i*964,b:0,w:949,h:2700});a.liso=true}var tv=apAdd('tv',1);tv.x=1350;tv.b=1100;newTpl(JSON.parse(JSON.stringify(pick('Rack de TV'))))});
          run('salaDois',function(){S.room='sala';S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;newTpl(JSON.parse(JSON.stringify(pick('Rack de TV'))));newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso'))));});
          run('cozinha',function(){S.room='cozinha';S.env='cozinha';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;['Balcão 2 portas','Gaveteiro 3 gavetas','Balcão da pia (cuba)','Balcão 1 porta'].forEach(function(n){newTpl(JSON.parse(JSON.stringify(pick(n))))});newTpl(4);newTpl(4);newTpl(4)});
          run('demo',function(){demoScene()});
          run('quarto',function(){S.room='quarto';S.env='livre';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;var it=null;CATS.forEach(function(c){if(/Quarto|quarto/.test(c.n))c.it.slice(0,4).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.w&&!t.act)newTpl(JSON.parse(JSON.stringify(t)))})})});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual((o["salaChao"] as? [String])?.count, 0, "textos sobrepostos em salaChao: \(o["salaChao"] ?? "")")
        XCTAssertEqual((o["salaDois"] as? [String])?.count, 0, "textos sobrepostos em salaDois: \(o["salaDois"] ?? "")")
        XCTAssertEqual((o["cozinha"] as? [String])?.count, 0, "textos sobrepostos em cozinha: \(o["cozinha"] ?? "")")
        XCTAssertEqual((o["demo"] as? [String])?.count, 0, "textos sobrepostos em demo: \(o["demo"] ?? "")")
        XCTAssertEqual((o["quarto"] as? [String])?.count, 0, "textos sobrepostos em quarto: \(o["quarto"] ?? "")")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Teclado numérico nunca cobre o campo que está sendo digitado (Estrutura, barra do painel, aba Painéis, quadro da prateleira, trena, quadro da porta no 3D, área do ripado)
    func testTecladoNumericoNuncaCobreOCampo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={},W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
          var chk=async function(tag,el){await W(60);if(typeof el==='function')el=el();if(!el){R[tag]='sem campo';return}el.focus();el.dispatchEvent(new Event('focusin',{bubbles:true}));await W(1000);var kp=document.getElementById('calcbar'),a=el.getBoundingClientRect(),b=kp&&!kp.hidden?kp.getBoundingClientRect():null;
           R[tag]=!b?'teclado não abriu':((a.bottom<=b.top+1||a.right<=b.left||a.left>=b.right)&&a.top>=0&&a.height>0?'ok':'COBERTO in '+Math.round(a.top)+'-'+Math.round(a.bottom)+' kp '+Math.round(b.top)+' vh '+innerHeight);
           try{document.activeElement.blur()}catch(_){}document.body.click();await W(150)};
          var pick=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n===nm)it=q})});return it};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
          newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso basculante'))));try{soloOff()}catch(_){}S.tab=0;panel();draw();
          await chk('estruturaLargura',function(){return document.querySelector('#bd [data-k="w"]')});
          await chk('estruturaProf',function(){return document.querySelector('#bd [data-k="d"]')});
          await chk('estruturaUltimo',function(){var ins=[].slice.call(document.querySelectorAll('#bd [data-calc]'));return ins[ins.length-1]});
          /* painel: barra do painel (posição e ajuste fino) */
          var a=rpNew({x:0,b:0,w:949,h:2700});a.liso=true;LAST='rp';RPSEL=a.id;RPBM='sz';draw();panel();await chk('barraPainel',function(){return document.querySelector('#rpbar [data-rpbf]')});S.tab=8;panel();await chk('abaPaineis',function(){return document.querySelector('#bd [data-pwf]')});
          /* prateleira: quadro de medidas */
          var pr=rpNew({x:30,b:1750,w:1100,h:50});pr.prat=true;pr.pd=250;pratEdit(pr);await W(100);await chk('quadroPrateleira',document.querySelector('#pratm [data-pe="x"]'));await chk('quadroPrateleiraW',document.querySelector('#pratm [data-pe="w"]'));document.getElementById('pratm').hidden=true;
          /* trena */
          S.m=null;LAST='';draw();panel();await chk('trena',function(){return document.querySelector('[data-trf]')});
          /* porta/janela no 3D */
          S.ops=[{id:1,t:'porta',w:800,h:2100,x:500,b:0,wall:'f'}];draw();open3D();await W(400);__build();__opSel(1);await W(200);await chk('porta3D',function(){return document.querySelector('[data-ofi="w"]')});await chk('porta3Dx',function(){return document.querySelector('[data-ofi="x"]')});try{document.getElementById('v3x').click()}catch(_){}
          /* área do ripado (largura final) */try{document.getElementById('v3x').click()}catch(_){}S.ops=[];S.rp=[];S.mods=[];draw();LAST='';S.tab=8;draw();panel();try{var bt=document.querySelector('[data-rparm]');if(bt)bt.click();else saStart(false);RPSA.pt=[700,1200];RPSA.areas=saAreas();saBar()}catch(e){R.saErr=String(e)}await W(100);await chk('areaRipado',function(){return document.querySelector('[data-saw]')});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["estruturaLargura"] as? String, "ok", "teclado cobrindo estruturaLargura: \(o["estruturaLargura"] ?? "")")
        XCTAssertEqual(o["estruturaProf"] as? String, "ok", "teclado cobrindo estruturaProf: \(o["estruturaProf"] ?? "")")
        XCTAssertEqual(o["estruturaUltimo"] as? String, "ok", "teclado cobrindo estruturaUltimo: \(o["estruturaUltimo"] ?? "")")
        XCTAssertEqual(o["barraPainel"] as? String, "ok", "teclado cobrindo barraPainel: \(o["barraPainel"] ?? "")")
        XCTAssertEqual(o["abaPaineis"] as? String, "ok", "teclado cobrindo abaPaineis: \(o["abaPaineis"] ?? "")")
        XCTAssertEqual(o["quadroPrateleira"] as? String, "ok", "teclado cobrindo quadroPrateleira: \(o["quadroPrateleira"] ?? "")")
        XCTAssertEqual(o["quadroPrateleiraW"] as? String, "ok", "teclado cobrindo quadroPrateleiraW: \(o["quadroPrateleiraW"] ?? "")")
        XCTAssertEqual(o["trena"] as? String, "ok", "teclado cobrindo trena: \(o["trena"] ?? "")")
        XCTAssertEqual(o["porta3D"] as? String, "ok", "teclado cobrindo porta3D: \(o["porta3D"] ?? "")")
        XCTAssertEqual(o["porta3Dx"] as? String, "ok", "teclado cobrindo porta3Dx: \(o["porta3Dx"] ?? "")")
        XCTAssertEqual(o["areaRipado"] as? String, "ok", "teclado cobrindo areaRipado: \(o["areaRipado"] ?? "")")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// 🔒 Travar porta, vão e janela (Ambiente e quadro do 3D) e projeto recebido pelo link (funcionário/cliente/ao vivo) abre tudo travado: só quem criou mexe
    func testTravarPortaJanelaEProjetoRecebidoTudoTravado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={},W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.stones=[];S.st=null;S.m=null;
          S.ops=[{id:1,t:'porta',st:'vao',w:800,h:2100,x:300,b:0,wall:'f'},{id:2,t:'janela',w:1200,h:1000,x:2200,b:1100,wall:'f'}];draw();
          /* aba Ambiente: toda porta, vão e janela tem 🔒 Travar (não só as que têm painel em cima) */
          S.tab=9;panel();R.ambiente=!!document.querySelector('[data-oplk="1"]')&&!!document.querySelector('[data-oplk="2"]');
          /* quadro da porta no 3D: 🔓 Travar · travada não muda medida, tipo, parede nem apaga */
          open3D();await W(300);__build();__opSel(1);await W(100);var o=S.ops[0],q=function(s){return document.querySelector(s)};q('[data-olk]').click();R.trava=o.lk===1;
          q('[data-osz="w|100"]').click();q('[data-ost="std"]').click();q('[data-odel]').click();var inp=q('[data-ofi="w"]');inp.value='950';inp.dispatchEvent(new Event('change',{bubbles:true}));
          var c=__p3(1500,1000,0),hw=__wallHit3(c[0],c[1]);__sel3(c[0],c[1]);R.travada=S.ops.length===2&&o.w===800&&o.st==='vao'&&o.x===300&&o.wall==='f';
          q('[data-olk]').click();q('[data-osz="w|100"]').click();R.destrava=!o.lk&&o.w===900;
          /* janela também trava */__opSel(2);await W(50);q('[data-olk]').click();var j=S.ops[1];q('[data-osz="h|100"]').click();R.janela=j.lk===1&&j.h===1000;try{q('#v3x').click()}catch(_){}
          /* projeto enviado (link do WhatsApp pro funcionário): abre tudo travado, só quem criou mexe */
          var pick=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n===nm)it=q})});return it};S.ops.forEach(function(x){delete x.lk});
          newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso'))));try{soloOff()}catch(_){}var pa=rpNew({x:0,b:0,w:949,h:2700});pa.liso=true;var tv=apAdd('tv',1);tv.x=1500;tv.b=1200;draw();
          openCut();cutSend();await new Promise(function(r){var t=Date.now();(function w(){if(window.__shared||Date.now()-t>5000)r();else setTimeout(w,50)})()});var code=window.__shared?__shared.code:'';window.arqueCutOpen(code);await W(1200);
          R.recebido=!!window.RO&&S.mods.length===1;R.tudo=S.mods.every(function(m){return m.lock})&&S.rp.every(function(a){return a.lock})&&S.fr.every(function(f){return f.lock})&&S.ops.every(function(x){return x.lk===1});
          var n0=S.mods.length,r0=S.rp.length;R.semCopia=modCopy(S.mods[0])===null&&rpCopy(S.rp[0])===null&&S.mods.length===n0&&S.rp.length===r0;
          var x0=S.mods[0].x;modCenter(S.mods[0]);R.semMover=S.mods[0].x===x0;R.semDestravar=lockToggle(S.mods[0])===''&&!!S.mods[0].lock;
          open3D();await W(300);__build();var c2=__p3(2500,1500,0);__sel3(c2[0],c2[1]);var ch=document.getElementById('opch3');R.semCriar=(!ch||ch.hidden)&&S.ops.length===2;
          __opSel(1);await W(50);var ol=document.querySelector('[data-olk]');if(ol)ol.click();R.semDestravarPorta=S.ops[0].lk===1;try{document.getElementById('v3x').click()}catch(_){}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ambiente"] as? Bool, true, "ambiente")
        XCTAssertEqual(o["trava"] as? Bool, true, "trava")
        XCTAssertEqual(o["travada"] as? Bool, true, "travada")
        XCTAssertEqual(o["destrava"] as? Bool, true, "destrava")
        XCTAssertEqual(o["janela"] as? Bool, true, "janela")
        XCTAssertEqual(o["recebido"] as? Bool, true, "recebido")
        XCTAssertEqual(o["tudo"] as? Bool, true, "tudo")
        XCTAssertEqual(o["semCopia"] as? Bool, true, "semCopia")
        XCTAssertEqual(o["semMover"] as? Bool, true, "semMover")
        XCTAssertEqual(o["semDestravar"] as? Bool, true, "semDestravar")
        XCTAssertEqual(o["semCriar"] as? Bool, true, "semCriar")
        XCTAssertEqual(o["semDestravarPorta"] as? Bool, true, "semDestravarPorta")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Monta vários armários do catálogo (cozinha, sala, quarto), muda largura, altura e fundo digitando: nada entra em nada,
    /// peças sem medida errada, plano de corte sem peça maior que a chapa e sem travar (plano, 3D e 2D rápidos)
    func testMontaVariosArmariosSemSobreporECortePreciso() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={rooms:{},bad:[],slow:[]},T=function(){return performance.now()};
          var ref=+(PR.refilo===undefined?10:PR.refilo),SW=(+PR.sheetW||2750)-2*ref,SH=(+PR.sheetH||1840)-2*ref;
          var rooms=['cozinha','sala','quarto'];
          var items=function(room){var out=[];CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.w&&!t.act&&!t.corner)out.push(t)})});return out};
          var check=function(tag){S.mods.forEach(function(m,i){if(modOverlaps(m)){var e=extOf(m),pr=S.mods.filter(function(o){if(o===m||(o.wing||0)!==(m.wing||0))return false;if(!((+m.b||0)<(+o.b||0)+(+o.h||0)-1&&(+o.b||0)<(+m.b||0)+(+m.h||0)-1))return false;var f=extOf(o);return e[0]<f[1]-1&&f[0]<e[1]-1}).map(function(o){return S.mods.indexOf(o)+(o.corner?'c':'')+':'+extOf(o).join('-')});R.bad.push(tag+' sobrepõe: '+i+(m.wing?' wing'+m.wing:'')+' '+e.join('-')+' b'+m.b+' com '+pr.join(','))}
            var P=[];try{P=partsOf(m)}catch(e){R.bad.push(tag+' partsOf erro '+i+': '+e.message);return}
            P.forEach(function(p){['w','h','x','y'].forEach(function(k){if(!isFinite(+p[k]))R.bad.push(tag+' peça '+p.name+' '+k+'='+p[k])});if(!p.noCut&&!p.noDraw&&(+p.w<=0||+p.h<=0))R.bad.push(tag+' peça vazia '+p.name+' '+p.w+'x'+p.h+' mod '+i)})});
            var G;try{G=cutGroups()}catch(e){R.bad.push(tag+' cutGroups erro '+e.message);return}
            G.ord.forEach(function(k){var g=G.map[k],L=+g.L,Wd=+g.W;if(!isFinite(L)||!isFinite(Wd)||L<=0||Wd<=0||!(g.qty>0))R.bad.push(tag+' corte '+g.names[0].slice(0,40)+' '+g.L+'x'+g.W+' q'+g.qty);
             else if((Math.max(L,Wd)>Math.max(SW,SH)+.5||Math.min(L,Wd)>Math.min(SW,SH)+.5)&&!/partes|emenda/.test(g.names.join(' ')+(g.note||'')))R.bad.push(tag+' maior que a chapa '+g.names[0].slice(0,40)+' '+L+'x'+Wd)});
            var t0=T();try{if(window.sheetPlan)sheetPlan()}catch(e){R.bad.push(tag+' plano erro '+e.message)}var tp=T()-t0;t0=T();try{__build()}catch(e){R.bad.push(tag+' 3D erro '+e.message)}var tb=T()-t0;t0=T();draw();var td=T()-t0;if(tp>4000||tb>4000||td>2500)R.slow.push(tag+' plano '+Math.round(tp)+' 3D '+Math.round(tb)+' 2D '+Math.round(td))};
          rooms.forEach(function(room){S.room=room;S.env=room==='quarto'||room==='closet'?'livre':'cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
            var its=items(room).filter(function(t){return CATS.some(function(c){return c.it.indexOf(t)>=0||c.it.some(function(q){return TPL[q]===t})})}),n=0;
            /* arma o ambiente com o que couber */
            var semLugar=0;its.slice(0,40).forEach(function(t){var k=S.mods.length;try{newTpl(JSON.parse(JSON.stringify(Object.assign({},t,{sup:!!t.sup}))))}catch(e){R.bad.push(room+' newTpl '+t.n+': '+e.message)}try{soloOff()}catch(_){}if(S.mods.length>k){if(modOverlaps(S.mods[S.mods.length-1])){S.mods.pop();semLugar++;S.m=S.mods[S.mods.length-1]||null}else n++}});draw();
            check(room);
            /* mexe nas medidas de cada um e confere de novo */
            S.mods.forEach(function(m,i){if(m.corner)return;S.m=m;S.tab=0;try{panel()}catch(e){R.bad.push(room+' panel '+e.message);return}var set=function(k,v){var el=document.querySelector('#bd [data-k="'+k+'"]');if(!el)return;el.value=String(v);el.dispatchEvent(new Event('input',{bubbles:true}));el.dispatchEvent(new Event('change',{bubbles:true}))};set('w',Math.round(m.w*(0.7+((i*37)%60)/100)));set('d',Math.round(m.d*(0.8+((i*13)%40)/100)));if(!m.sup&&m.h<1500)set('h',Math.round(m.h*(0.85+((i*7)%30)/100)))});draw();check(room+'*');
            R.rooms[room]=n+' (sem lugar '+semLugar+')'});
          R.nbad=R.bad.length;R.bad=R.bad.slice(0,60);R.errs=__errs.slice(0,10);return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["nbad"] as? Int, 0, "\(o["bad"] ?? "")")
        XCTAssertEqual((o["slow"] as? [String])?.count, 0, "lento: \(o["slow"] ?? "")")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Torre com portas separadas e réguas, todas as portas abrem, mover módulo com 2 toques e planta em ângulo sem peça por cima da pedra
    func testTorrePortasSeparadasPortasAbremMoverDe2ToquesEPlantaSemSobrepor() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* todas as portas de todos os módulos abrem (caixa da geladeira e torres também) */
          var items=[];CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.w&&t.v)items.push(t)})});var bad=[];
          items.forEach(function(t){S.mods=[];S.fr=[];try{newTpl(t)}catch(e){return}var m=S.mods[0];if(!m)return;partsOf(m).filter(function(p){return /^Porta/.test(p.name)&&p.vi!==undefined&&!p.noCut&&!p.cego/* painel cego é fixo: não abre */}).forEach(function(p){var v=m.v[p.vi];if(!v)return;v.od={};v.od[p.dq]=1;var q=partsOf(m).filter(function(x){return x.pk===p.pk})[0];if(!q||!q.open)bad.push(t.n);v.od={}})});R.portas=bad.length;
          /* torre: portas separadas (em cima e embaixo) com divisão, régua do cava e volta pra inteiras */
          S.mods=[];S.fr=[];newTpl(tpl('Despenseiro'));var d=S.mods[0];draw();open3D();await new Promise(function(r){setTimeout(r,300)});fx3api.open({k:'mod',mi:0});
          document.querySelector('#it4 [data-qtqsep^="1"]').click();var P=partsOf(d);R.sep=P.filter(function(p){return /^Porta/.test(p.name)}).length;R.div=P.some(function(p){return /divide as portas/.test(p.name)});
          document.querySelector('#it4 [data-qtqr$="|rgI"]').click();R.regua=partsOf(d).some(function(p){return /régua da torre \(embaixo/.test(p.name)});
          document.querySelector('#it4 [data-qtqsep^="0"]').click();R.inteira=d.v[0].k;try{itClose()}catch(_){}
          /* 2 toques no módulo e 2 toques perto da parede da direita: o módulo vai pra lá */
          S.mods=[];newTpl(tpl('Balcão 2 portas'));var m=S.mods[0];m.x=1200;draw();__build();var b=__boxes().filter(function(q){return String(q.nm)==='0:Lateral esquerda'})[0];var c=__p3((b.x0+b.x1)/2,(b.y0+b.y1)/2,b.z1);__sel3(c[0],c[1]);var f=__p3(4000,0,1300);__sel3(f[0],f[1]);R.parede=m.wing||'';
          /* planta em ângulo: nenhuma peça de baixo por cima da pedra */
          demoScene();PLV=true;PLANG=true;draw();var L=window.__plL||[],e=.6,st=function(q){return q.g==='stc'||q.g==='st'},nb=0;
          for(var i=0;i<L.length;i++)for(var j=i+1;j<L.length;j++){var A=L[i],B=L[j];if(!st(A.b)||st(B.b))continue;var a=A.b,q=B.b;if(q.x0<a.x1-e&&q.x1>a.x0+e&&q.z0<a.z1-e&&q.z1>a.z0+e&&q.y1<=a.y1+e&&A.s0<B.s1-.3&&B.s0<A.s1-.3&&A.t0<B.t1-.3&&B.t0<A.t1-.3)nb++}
          R.planta=nb;R.n=L.length;PLANG=false;PLV=false;draw();
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["portas"] as? Int, 0, "todas as portas de todos os módulos abrem")
        XCTAssertEqual(o["sep"] as? Int, 4, "portas separadas: 2 em cima e 2 embaixo")
        XCTAssertEqual(o["div"] as? Bool, true, "prateleira fixa dividindo as portas")
        XCTAssertEqual(o["regua"] as? Bool, true, "régua do cava embaixo da divisão")
        XCTAssertEqual(o["inteira"] as? String, "door", "volta pra portas inteiras")
        XCTAssertEqual(o["parede"] as? String, "d", "2 toques no módulo e 2 toques perto da parede da direita: foi pra lá")
        XCTAssertEqual(o["planta"] as? Int, 0, "planta em ângulo: a pedra sempre por cima do módulo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Painel: no cabeçalho escolhe ripado ou painel liso (toque pra adicionar) e troca depois no painel selecionado
    func testPainelRipadoOuLisoNoCabecalho() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.rp=[];draw();S.tab=8;panel();var R={};
          /* cabeçalho de criar: escolhe ripado ou painel liso e toca pra adicionar */
          document.querySelector('#bd [data-rpk="liso"]').click();R.on=document.querySelector('#bd [data-rpk="liso"]').classList.contains('on');
          document.querySelector('#bd [data-rpadd]').click();var a=S.rp[S.rp.length-1];R.liso=!!a.liso;
          /* cabeçalho do painel selecionado: troca de painel liso pra ripado */
          var bar=document.getElementById('rpbar');R.bar=!bar.hidden;bar.querySelector('[data-rpb="tp|rip"]').click();R.ripado=!S.rp[S.rp.length-1].liso;R.ripas=rpStats(S.rp[S.rp.length-1]).n>0;
          document.getElementById('rpbar').querySelector('[data-rpb="tp|liso"]').click();R.volta=!!S.rp[S.rp.length-1].liso;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["on"] as? Bool, true, "painel liso escolhido no cabeçalho")
        XCTAssertEqual(o["liso"] as? Bool, true, "o painel criado sai liso")
        XCTAssertEqual(o["bar"] as? Bool, true, "painel novo já fica selecionado")
        XCTAssertEqual(o["ripado"] as? Bool, true, "troca pra ripado no cabeçalho do painel")
        XCTAssertEqual(o["ripas"] as? Bool, true, "ripado com ripas")
        XCTAssertEqual(o["volta"] as? Bool, true, "volta pra painel liso")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Rodapé do armário alto igual aos de baixo, pintar o módulo por dentro, dobradiça real, porta com amortecedor e eletro aberto sem ficar azul
    func testRodapeIgualPintarPorDentroEletroSemAzulEPortaAmortecida() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;STD().latPiso='sim';/* confere o jeito "até o piso" (o padrão agora é em cima do rodapé) */S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* armário alto com rodapé: o tamponamento para em cima do rodapé, igual aos módulos de baixo */
          newTpl(tpl('Despenseiro'));var d=S.mods[0];R.tamp=partsOf(d).filter(function(p){return /^Tamponamento/.test(p.name)}).map(function(p){return p.h}).join(',');R.alto=d.h-d.rodMm;
          /* pintar o módulo inteiro por dentro (porta-tempero): peças de dentro na cor, frente e tamponamento não */
          S.mods=[];newTpl(tpl('Porta-tempero'));var m=S.mods[0];draw();open3D();await new Promise(function(r){setTimeout(r,300)});
          window.PT3={c:'#ff00ff',n:'Rosa',id:''};var pk0=partsOf(m).filter(function(p){return /^Base \(porta tempero/.test(p.name)})[0].pk;__pt3pick(0,pk0,'modIn');__build();
          var bx=__boxes().filter(function(b){return String(b.nm).indexOf('0:')===0&&Array.isArray(b.c)}),pink=function(b){return b.c[0]>240&&b.c[1]<20&&b.c[2]>240},nm=function(b){return String(b.nm).split(':')[1]};
          R.tempero=['Frente atrás (porta tempero)','Costa (porta tempero)','Base (porta tempero)','Régua (porta tempero)','Fundo'].every(function(n){return bx.some(function(b){return nm(b)===n&&pink(b)})});
          R.fora=bx.some(function(b){return pink(b)&&/^(Porta|Frente \(porta tempero|Tamponamento|Rodapé)/.test(nm(b))});R.corte=cutLines(m).some(function(l){return /Rosa/.test(l.name+' '+(l.note||''))});window.PT3=null;
          /* dobradiça real: quantidade pela altura da porta (2 até 900, 3 até 1600...) */
          S.mods=[];newTpl(tpl('Armário alto 2 portas'));draw();__build();R.dob=dobFor(2000);
          /* porta fecha com amortecedor: 80% do curso rápido, os últimos 20% devagar */
          S.mods=[];newTpl(tpl('Balcão 2 portas'));draw();__build();__e3open(0,'Porta#1');document.querySelector('#e3 [data-op="one"]').click();await new Promise(function(r){setTimeout(r,1400)});
          var k=Object.keys(__ang().t).filter(function(q){return q[0]==='p'&&__ang().t[q]>0})[0];document.querySelector('#e3 [data-op="one"]').click();var t0=performance.now(),smp=[];
          while(performance.now()-t0<2200){await new Promise(function(r){setTimeout(r,40)});smp.push([performance.now()-t0,__ang().g[k]])}
          var tA=(smp.filter(function(s){return s[1]<=90*0.2})[0]||[9999])[0],tB=(smp.filter(function(s){return s[1]<=0.5})[0]||[9999])[0];R.amort=tB-tA>tA*0.35;R.fechou=smp[smp.length-1][1]<0.5;
          document.querySelector('#e3 [data-e3x]').click();
          /* eletro aberto não fica azul */
          S.mods=[];S.fr=[];draw();var f=apAdd('lavaloucas',2);draw();__build();var col=function(){return __boxes().filter(function(b){return b.fr===f.id&&Array.isArray(b.c)}).map(function(b){return b.c.join()}).join('|')};var c0=col();
          fx3api.open({k:'fr',id:f.id});await new Promise(function(r){setTimeout(r,200)});R.semAzul=col()===c0;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["tamp"] as? String, "2200,2200", "tamponamento do armário alto desce até o piso junto com as laterais")
        XCTAssertEqual(o["alto"] as? Int, 2100)
        XCTAssertEqual(o["tempero"] as? Bool, true, "porta-tempero pintado por dentro (frente de trás, costa, base, réguas e fundo)")
        XCTAssertEqual(o["fora"] as? Bool, false, "por dentro não pinta frente, tamponamento nem rodapé")
        XCTAssertEqual(o["corte"] as? Bool, true, "plano de corte com a cor de dentro")
        XCTAssertEqual(o["dob"] as? Int, 4, "porta de 2000: 4 dobradiças")
        XCTAssertEqual(o["amort"] as? Bool, true, "os últimos 20% fecham devagar")
        XCTAssertEqual(o["fechou"] as? Bool, true, "porta encosta e fecha")
        XCTAssertEqual(o["semAzul"] as? Bool, true, "eletro aberto não fica azul")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Editar qualquer peça de qualquer módulo pronto: caixa da gaveta inteira, canto em L, régua do tamponamento e medida digitada
    func testEditarQualquerPecaCaixaDaGavetaCantoEmLEMedidaDigitada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.rp=[];S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          open3D();await new Promise(function(r){setTimeout(r,300)});
          /* caixa da gaveta: altura e profundidade digitadas mudam laterais, frente/costa e fundo juntos */
          newTpl(tpl('Gaveteiro 3 gavetas'));var g=S.mods[0];__build();__e3t(0,'Lateral de gaveta#1',1,160);__e3t(0,'Fundo de gaveta (6 mm)#1',2,450);
          var P=partsOf(g),pk=function(k){return P.filter(function(p){return p.pk===k})[0]||{}};
          R.lat=[pk('Lateral de gaveta#1').cl,pk('Lateral de gaveta#1').cw,pk('Lateral de gaveta#2').cl,pk('Lateral de gaveta#2').cw].join(',');R.fc=pk('Frente/costa de gaveta (contra-frente e traseira)#1').cw;R.fundo=pk('Fundo de gaveta (6 mm)#1').cw;R.outra=pk('Lateral de gaveta#3').cl;
          /* canto em L: peça do lado do canto muda no corte e no 3D */
          S.mods=[];newTpl(tpl('Canto L guarda-roupa · esquerdo'));var c=S.mods[0];__build();var t3=__e3t(0,'Base superior (lado do canto)#1',0,500);R.trav=(partsOf(c).filter(function(p){return p.pk==='Base superior (lado do canto)#1'})[0]||{}).cw;R.trav3=t3.d?Math.round(t3.d[0]):0;
          /* tamponamento com engrosso: tocar na régua de dentro seleciona o tamponamento */
          S.mods=[];newTpl(tpl('Balcão 2 portas'));__build();var rg=__boxes().filter(function(b){return b.ppk})[0];R.ppk=rg?rg.ppk:'';R.sel=rg?__e3(0,rg.ppk).part:false;
          /* forno: aparelho, não estica */
          S.mods=[];newTpl(tpl('Torre quente (forno)'));__build();R.forno=__e3(0,'Corte do forno#1').h.length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["lat"] as? String, "450,160,450,160", "as duas laterais da gaveta mudam juntas (altura e profundidade)")
        XCTAssertEqual(o["fc"] as? Int, 145, "frente/costa acompanha a altura da caixa")
        XCTAssertEqual(o["fundo"] as? Int, 450, "fundo acompanha a profundidade (corrediça de 450)")
        XCTAssertEqual(o["outra"] as? Int, 460, "as outras gavetas não mudam (regra: 460)")
        XCTAssertEqual(o["trav"] as? Int, 500, "peça do lado do canto muda no corte (canto alto tem base em cima, não travessa)")
        XCTAssertEqual(o["trav3"] as? Int, 500, "e no 3D")
        XCTAssertEqual(o["ppk"] as? String, "Tamponamento direito#1", "régua de dentro aponta pro tamponamento")
        XCTAssertEqual(o["sel"] as? Bool, true, "tamponamento selecionado")
        XCTAssertEqual(o["forno"] as? Int, 0, "forno é aparelho: sem bolinhas")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Armário alto: 3 toques põem o nicho de forno / micro-ondas e as réguas do cava (em cima e embaixo)
    func testTorreNichoDeEmbutirEReguaDoCavaEmCimaEEmbaixo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Despenseiro'));var m=S.mods[0];m.x=900;S.m=m;draw();var R={};
          /* 3 toques no armário alto: pôr nicho de forno / micro-ondas e réguas do cava em cima e embaixo */
          open3D();await new Promise(function(r){setTimeout(r,300)});fx3api.open({k:'mod',mi:0});var it=document.getElementById('it4');it.querySelector('[data-qtqadd]').click();R.k=m.v[0].k;
          it.querySelector('[data-qtqm$="|embutir"]').click();it.querySelector('[data-qtqr$="|rgS"]').click();it.querySelector('[data-qtqr$="|rgI"]').click();
          R.reguas=partsOf(m).filter(function(p){return /^Engrosso cava · régua da torre/.test(p.name)}).length;R.cortes=partsOf(m).filter(function(p){return /^Corte do (forno|micro-ondas)/.test(p.name)}).length;
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["k"] as? String, "oven", "virou torre com nicho")
        XCTAssertEqual(o["cortes"] as? Int, 2, "forno e micro-ondas de embutir")
        XCTAssertEqual(o["reguas"] as? Int, 2, "régua do cava em cima e embaixo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Torre: marcar o pedestal desce o módulo suspenso até o chão; a prateleira de dentro arrasta pra cima e pra baixo
    func testTorrePedestalDesceAteOChaoEPrateleiraArrasta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3000;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Despenseiro'));var m=S.mods[0];m.x=1000;m.w=730;m.h=2260;m.b=140;S.m=m;S.tab=0;draw();panel();var R={};
          /* torre suspensa: marcar o pedestal desce até o chão (o topo fica) e põe o pedestal */
          R.antes=m.rod+'/'+m.b;document.querySelector('#bd input[data-rc="rod"]').click();R.depois=m.rod+'/'+m.b+'/'+m.h;
          /* prateleira de dentro da torre arrasta pra cima e pra baixo */
          setShelves(m,0,1);S.tab=1;draw();panel();var h=document.querySelector('#svg circle[data-ish]');R.alca=!!h;
          if(h){var r=h.getBoundingClientRect(),cx=r.left+r.width/2,cy=r.top+r.height/2,a0=m.v[0].int[0].h,s0=m.v[0].int[0].h+m.v[0].int[1].h;h.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,cancelable:true,clientX:cx,clientY:cy,pointerId:7,isPrimary:true}));document.dispatchEvent(new PointerEvent('pointermove',{bubbles:true,cancelable:true,clientX:cx,clientY:cy-8,pointerId:7}));document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true,cancelable:true,clientX:cx,clientY:cy-8,pointerId:7}));R.subiu=m.v[0].int[0].h<a0;R.soma=(m.v[0].int[0].h+m.v[0].int[1].h)===s0;R.x=m.x}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["antes"] as? String, "false/140", "torre suspensa sem pedestal")
        XCTAssertEqual(o["depois"] as? String, "true/0/2400", "pedestal: desce até o chão e o topo fica")
        XCTAssertEqual(o["alca"] as? Bool, true, "bolinha na prateleira")
        XCTAssertEqual(o["subiu"] as? Bool, true, "arrastou pra cima")
        XCTAssertEqual(o["soma"] as? Bool, true, "vão de cima + vão de baixo fica igual")
        XCTAssertEqual(o["x"] as? Int, 1000, "o módulo não sai do lugar")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// 3 toques no módulo: encaixar o lado de fora embaixo da pedra (pingadeira 0,5 cm, o outro lado fica) e esticar ou encurtar o móvel
    func testTresToquesEncaixaNaPedraComPingadeiraEEsticaOMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));newTpl(tpl('Balcão 2 portas'));var a=S.mods[0],b=S.mods[1];a.x=1000;b.x=1900;addStone();S.st.x=1100;S.st.w=1800;draw();var R={};
          open3D();await new Promise(function(r){setTimeout(r,300)});
          /* 3 toques: encaixar o lado de fora embaixo da pedra com pingadeira de 5 mm, o lado encostado no vizinho fica */
          fx3api.open({k:'mod',mi:1});var it=document.getElementById('it4'),e0=extOf(b)[0];it.querySelector('[data-qmfit]').click();R.ping=Math.round((S.st.x+S.st.w)-extOf(b)[1]);R.fica=extOf(b)[0]===e0;
          /* esticar ou encurtar o móvel pelo quadro */
          var w0=b.w;it.querySelector('[data-qms="w|-10"]').click();R.encurta=w0-b.w;R.campos=it.querySelectorAll('[data-qmf="w"],[data-qmf="h"],[data-qmf="d"]').length;
          it.querySelector('[data-qmz]').click();await new Promise(function(r){setTimeout(r,100)});R.bolinhas=[].map.call(document.querySelectorAll('[data-mzh]'),function(d){return d.dataset.mzh}).sort().join(',');
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ping"] as? Int, 5, "pedra passa 5 mm do lado de fora")
        XCTAssertEqual(o["fica"] as? Bool, true, "o lado encostado no vizinho fica")
        XCTAssertEqual(o["encurta"] as? Int, 10, "encurta pelo quadro")
        XCTAssertEqual(o["campos"] as? Int, 3, "largura, altura e profundidade no quadro")
        XCTAssertEqual(o["bolinhas"] as? String, "d,h,w,wl", "bolinhas dos dois lados")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Torre quente: acha pela lupa e muda forno (embutido, só nicho, sem) e micro-ondas (embutir, nicho aberto, só nicho, sem)
    func testTorreQuenteEditavelPelaLupaComNichosEMicroOndas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2400;S.H=2600;S.Hm=1;S.Wm=1;draw();var R={};
          /* lupa do catálogo de baixo acha a torre quente */
          catLevel('inf');var q=document.getElementById('catq');q.value='torre quente';q.dispatchEvent(new Event('input',{bubbles:true}));await new Promise(function(r){setTimeout(r,200)});
          R.achou=[].filter.call(document.querySelectorAll('#catgw [data-cati]'),function(b){return b.style.display!=='none'&&/^Torre/.test(b.textContent)}).length;document.getElementById('catm').hidden=true;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Torre quente (forno)'));var m=S.mods[0];S.m=m;draw();var vi=m.v.findIndex(function(v){return v.k==='oven'});S.sv=vi;S.tab=2;panel();
          var nm=function(){return partsOf(m).filter(function(p){return /^(Corte|Nicho|Porta)/.test(p.name)}).map(function(p){return p.name.split(' (')[0]}).join(',')};
          R.forno=nm();document.querySelector('#bd [data-tqm="embutir"]').click();R.micro=nm();document.querySelector('#bd [data-tqm="aberto"]').click();R.aberto=partsOf(m).some(function(p){return p.mwOpen});
          document.querySelector('#bd [data-tqf="nao"]').click();R.semForno=nm();document.querySelector('#bd [data-tqf="nicho"]').click();document.querySelector('#bd [data-tqm="nicho"]').click();R.nichos=nm();
          /* 3 toques na torre no 3D também mudam */
          open3D();await new Promise(function(r){setTimeout(r,300)});fx3api.open({k:'mod',mi:0});document.querySelector('#it4 [data-qtqf$="|forno"]').click();R.q3=m.v[vi].fo;
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertGreaterThanOrEqual(o["achou"] as? Int ?? 0, 6, "lupa acha as torres")
        XCTAssertEqual(o["forno"] as? String, "Corte do forno,Porta,Porta", "torre quente com portas em cima e embaixo")
        XCTAssertEqual(o["micro"] as? String, "Corte do forno,Corte do micro-ondas,Porta,Porta", "micro-ondas de embutir")
        XCTAssertEqual(o["aberto"] as? Bool, true, "nicho aberto do micro-ondas de bancada")
        XCTAssertEqual(o["semForno"] as? String, "Nicho do micro-ondas,Porta,Porta", "sem forno")
        XCTAssertEqual(o["nichos"] as? String, "Nicho do forno,Nicho do micro-ondas,Porta,Porta", "só os nichos")
        XCTAssertEqual(o["q3"] as? String, "forno", "3 toques no 3D mudam a torre")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Planta em ângulo: cada peça desenhada na ordem certa (a pedra cobre o módulo, nada sobreposto ou torto)
    func testPlantaEmAnguloPedraCobreOModuloSemSobreposicao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;var R={};
          /* ordem: a pedra (em cima) vem depois do módulo (embaixo); o que está mais pra frente vem depois do que está atrás */
          var T=function(x,z,h){return [x-z*.5,z*.3-h]},bx=function(n,x0,x1,y0,y1,z0,z1){return {n:n,b:{x0:x0,x1:x1,y0:y0,y1:y1,z0:z0,z1:z1}}};
          var L=[bx('pedra',0,600,860,900,0,600),bx('frente',0,600,0,860,560,580),bx('modulo',0,600,0,860,0,560)];
          R.ordem=plDepthSort(L,0,1,T).map(function(it){return it.n}).join(',');
          /* cozinha em L na planta em ângulo: desenha e não dá erro */
          demoScene();PLV=true;PLANG=true;draw();R.polys=document.querySelectorAll('#plx polygon').length;PLANG=false;PLV=false;draw();
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ordem"] as? String, "modulo,frente,pedra", "módulo, depois a frente, e a pedra por cima")
        XCTAssertGreaterThan(o["polys"] as? Int ?? 0, 100, "cozinha em L desenhada")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Gaveta não encosta em cima: a folga do vão fica dividida (em cima e embaixo); se estiver apertado, 2 cm embaixo e 1,5 cm em cima,
    /// e a corrediça telescópica vai no meio da lateral da caixa
    func testGavetaComFolgaDivididaENaoEncostaEmCimaCorredicaNoMeio() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2000;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Gaveteiro 3 gavetas'));var m=S.mods[0];S.m=m;draw();var R={};
          var vi=m.v.findIndex(function(v){return v.k==='drawers'}),v=m.v[vi];CURM=m;var fh=drawerH(v);
          /* folga dividida em cima e embaixo; apertado: 2 cm embaixo e 1,5 cm em cima */
          var g0=gbox(v,900,fh,560);R.normal=g0.fb+'/'+g0.ft;v.gH=fh-20;var g1=gbox(v,900,fh,560);R.apertado=(fh-g1.h)+':'+g1.fb+'/'+g1.ft;delete v.gH;CURM=null;
          /* no 3D a caixa de cima não encosta na travessa e a corrediça fica no meio da lateral */
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var bx=__boxes(),lat=bx.filter(function(b){return /:Lateral de gaveta$/.test(b.nm)}),topo=Math.max.apply(null,lat.map(function(b){return b.y1})),tr=bx.filter(function(b){return /:Travessa frontal$/.test(b.nm)})[0];
          R.folgaTopo=Math.round(tr.y0-topo);var c1=lat.filter(function(b){return b.y1===topo})[0],rl=bx.filter(function(b){return /Corrediça telescópica/.test(b.nm)&&b.y0<topo&&b.y1>c1.y0})[0];R.corredica=rl?Math.round(((rl.y0+rl.y1)/2-(c1.y0+c1.y1)/2)):'sem';
          R.nota=/corrediça no meio da lateral/.test(partsOf(m).filter(function(p){return /^Lateral de gaveta/.test(p.name)})[0].note);
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["normal"] as? String, "28/28", "folga do vão dividida em cima e embaixo")
        XCTAssertEqual(o["apertado"] as? String, "35:20/15", "apertado: 2 cm embaixo e 1,5 cm em cima")
        XCTAssertEqual(o["folgaTopo"] as? Int, 13, "caixa de cima não encosta na travessa (com cava ela sobe pra ficar livre do batente de baixo)")
        XCTAssertEqual(o["corredica"] as? Int, 0, "corrediça no meio da lateral")
        XCTAssertEqual(o["nota"] as? Bool, true, "lista de corte diz onde vai a corrediça")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// separados por categoria, no piso e nas paredes do 3D (as juntas vêm na peça); tudo salvo no projeto
    func testCoresComPisosEPorcelanatosReaisParedesArmariosPortasEFitas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          for(var i=0;i<3;i++){newTpl(tpl('Balcão 2 portas'));S.mods[S.mods.length-1].x=200+i*900}
          S.m=S.mods[0];S.tab=10;__cores('pp','all','piso');draw();panel();var R={},Q=function(q){return document.querySelector('#bd '+q)};
          /* aba 🎨 Cores logo depois do Ambiente, com o cabeçalho organizado */
          R.aba=[].map.call(document.querySelectorAll('#tabs [data-t]'),function(d){return d.textContent})[1];
          R.cab=[].map.call(document.querySelectorAll('#bd .cortb button'),function(b){return b.textContent}).join('|');
          /* 15 pisos e porcelanatos com textura, separados por categoria */
          R.pisos=document.querySelectorAll('#bd [data-cfm]:not([data-cfm=""])').length;R.cats=[].map.call(document.querySelectorAll('#bd .rvc'),function(d){return d.textContent}).join(',');
          R.img=/cores\/piso-calacata-altissimo\.jpg/.test(Q('[data-cfm="piso-calacata-altissimo"] i').style.backgroundImage);
          Q('[data-cfm="piso-carvalho-natural"]').click();R.fm=S.fm;R.junta=!Q('[data-cpj]');
          __cores('pp','all','parede');panel();Q('[data-cwm="piso-calacata-altissimo"]').click();R.wm=S.wm;
          /* armários e portas: a cor vai pra todos os módulos */
          __cores('arm','all');panel();var b=Q('[data-csl="cor"] [data-cs*="arauco"]'),id=b.dataset.cs.split('|')[3];b.click();R.arm=S.mods.map(function(m){return m.corId===id?1:0}).join('');
          __cores('port','all');panel();var b2=Q('[data-csl="corF"] [data-cs*="duratex"]'),id2=b2.dataset.cs.split('|')[3];b2.click();R.port=S.mods.map(function(m){return m.corFId===id2?1:0}).join('');
          /* fitas */
          __cores('fita');panel();var f0=STD().fitaMm;Q('[data-std="fitaMm"][data-v="35"]').click();R.fita=STD().fitaMm;STD().fitaMm=f0;prSave();
          /* salva no projeto (e o botão do LED também) */
          S.lbtm='um';S.lbtc='preto';var sv=JSON.parse(JSON.stringify(snapState()));delete S.fm;delete S.wm;delete S.lbtm;delete S.lbtc;loadState(sv);R.salvo=S.fm+'|'+S.wm+'|'+S.lbtm+'|'+S.lbtc;
          /* no 3D: piso e paredes com o porcelanato (as juntas vêm na peça) e o quadro do piso com as categorias */
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var bs=__bg();R.piso3d=bs[0].mid;R.juntas=bs.filter(function(q){return q.fj}).length;R.paredes3d=bs.filter(function(q){return q.wl&&q.mid==='piso-calacata-altissimo'}).length>0;
          fx3api.open({k:'wall',s:'P'});var it=document.getElementById('it4');R.quadro=it.querySelectorAll('[data-qrv]').length;it.querySelector('[data-qrv="piso-terrae-cotta"]').click();R.fm3=S.fm;
          it.querySelector('[data-qwc]:not([data-qwc=""])').click();R.tinta=String(S.fm);
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["aba"] as? String, "🎨 Cores", "aba Cores logo depois do Ambiente")
        XCTAssertEqual(o["cab"] as? String, "🧱 Paredes e pisos|🗄 Armários|🚪 Portas|▥ Painéis|🎞 Fitas", "cabeçalho organizado")
        XCTAssertEqual(o["pisos"] as? Int, 15, "15 pisos e porcelanatos")
        XCTAssertEqual(o["cats"] as? String, "Liso,Neutro,Cimentício,Marmorizado,Pedra,Granilite,Amadeirado,Terracota", "separados por categoria")
        XCTAssertEqual(o["img"] as? Bool, true, "cada piso mostra a textura")
        XCTAssertEqual(o["fm"] as? String, "piso-carvalho-natural", "piso escolhido")
        XCTAssertEqual(o["junta"] as? Bool, true, "com porcelanato as juntas vêm na peça")
        XCTAssertEqual(o["wm"] as? String, "piso-calacata-altissimo", "porcelanato nas paredes")
        XCTAssertEqual(o["arm"] as? String, "111", "cor dos armários em todos os módulos")
        XCTAssertEqual(o["port"] as? String, "111", "cor das portas em todos os módulos")
        XCTAssertEqual(o["fita"] as? Int, 35, "largura da fita pela aba Cores")
        XCTAssertEqual(o["salvo"] as? String, "piso-carvalho-natural|piso-calacata-altissimo|um|preto", "piso, parede e botão do LED salvos no projeto")
        XCTAssertEqual(o["piso3d"] as? String, "piso-carvalho-natural", "no 3D o piso usa a textura")
        XCTAssertEqual(o["juntas"] as? Int, 0, "sem as juntas de desenho por cima do porcelanato")
        XCTAssertEqual(o["paredes3d"] as? Bool, true, "no 3D as paredes usam o porcelanato")
        XCTAssertEqual(o["quadro"] as? Int, 16, "quadro do piso no 3D com os 15 e o sem porcelanato")
        XCTAssertEqual(o["fm3"] as? String, "piso-terrae-cotta", "troca o piso pelo 3D")
        XCTAssertEqual(o["tinta"] as? String, "undefined", "escolher a cor tira o porcelanato")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testModoPessoaNaoAtravessaMesaCafeteiraPedrasReaisESetinhasDaPedra() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4100;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          for(var i=0;i<3;i++){newTpl(tpl('Balcão 2 portas'));S.mods[S.mods.length-1].x=200+i*900}
          addStone();S.st.x=200;S.st.w=2700;S.st.cor='#a3a4a3';var me=apAdd('mesa',0);
          var ci=apModels('deco').findIndex(function(q){return /Cafeteira/.test(q[0])}),cf=apAdd('deco',ci);cf.x=600;cf.b=860;cf.y=150;
          var hi=apModels('churrasqueira').findIndex(function(q){return /Natural 84/.test(q[0])}),ch=apAdd('churrasqueira',hi);ch.x=3150;S.tab=6;draw();panel();var R={};
          /* 15 pedras com nome real e faixa · a pedra pinta com a textura */
          R.pedras=STS.filter(function(c){return c[3]}).length+'/'+STS.filter(function(c){return c[4]==='Premium'}).length;R.nome=STS[0][0];R.f2d=stF(S.st);
          /* setinhas da pedra longe dos números */
          var hl=document.querySelector('#plan circle[data-sth^="l|"]'),lb=document.querySelector('#plan text[data-q="ed|3"]');var hb=hl.getBBox(),tb=lb.getBBox();R.setinha=Math.round(Math.max(0,Math.max(tb.x-(hb.x+hb.width),hb.x-(tb.x+tb.width),tb.y-(hb.y+hb.height),hb.y-(tb.y+tb.height))));
          var hf=document.querySelector('#plan circle[data-sth^="f|"]'),lf=document.querySelector('#plan text[data-q="ed|2"]');var fb=hf.getBBox(),ff=lf.getBBox();R.setinhaF=Math.round(Math.max(0,Math.max(ff.x-(fb.x+fb.width),fb.x-(ff.x+ff.width),ff.y-(fb.y+fb.height),fb.y-(ff.y+ff.height))));
          R.imers=!!document.querySelector('[data-imers]');
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();R.tex3d=__boxes().filter(function(b){return b.mid==='pedra-cinza-corumba'}).length>0;
          /* cafeteira: toque passa o café */
          var c=[cf.x+cf.w/2,cf.b+cf.h*.4,cf.y+cf.d],s0=org3api.proj(c);org3api.one(s0[0],s0[1]);R.cafe=JSON.stringify(__caf()).indexOf('enchendo')>0;
          /* modo pessoa: a mesa não deixa passar e o toque acende a churrasqueira na hora */
          fp3api.start();await new Promise(function(r){setTimeout(r,200)});var e=fp3api.st().e;fp3api.st();var f=window.FPV;f.e[0]=me.x+me.w/2;f.e[2]=me.y+me.d+600;for(var k=0;k<40;k++)fp3api.walk(1,0);R.mesa=Math.round(window.FPV.e[2]-(me.y+me.d));
          var cp=org3api.proj([ch.x+ch.w/2,700,ch.d-20]);var before=__chg();if(cp){org3api.one(cp[0],cp[1])}R.churras=before+'>'+__chg();
          fp3api.stop();document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["pedras"] as? String, "15/3", "15 pedras com textura, 3 premium")
        XCTAssertEqual(o["nome"] as? String, "Granito Cinza Corumbá", "nome real da pedra")
        XCTAssertEqual(o["f2d"] as? String, "url(#stp-pedra-cinza-corumba)", "no 2D a pedra tem a textura dela")
        XCTAssertGreaterThan(o["setinha"] as? Int ?? 0, 2, "a setinha ↔ não fica em cima do número do lado")
        XCTAssertGreaterThan(o["setinhaF"] as? Int ?? 0, 2, "a setinha ↕ não fica em cima do número da frente")
        XCTAssertEqual(o["imers"] as? Bool, true, "botão da imersão na vista de cima")
        XCTAssertEqual(o["tex3d"] as? Bool, true, "no 3D a pedra usa a textura dela")
        XCTAssertEqual(o["cafe"] as? Bool, true, "toque na cafeteira passa o café")
        XCTAssertGreaterThanOrEqual(o["mesa"] as? Int ?? 0, 200, "no modo pessoa a mesa não deixa atravessar")
        XCTAssertEqual(o["churras"] as? String, "0>1", "no modo pessoa o toque acende a churrasqueira na hora")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testGestosNoEletro2ToquesMudaDeLugar3ToquesConfiguracoes() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));var b=S.mods[0];b.x=1600;addStone();S.st.x=1600;S.st.w=1800;draw();
          var mw=apAdd('microondas',0);mw.x=200;var me=apAdd('mesa',0);me.x=1900;var ci=apModels('churrasqueira').findIndex(function(q){return /Natural 84/.test(q[0])}),ch=apAdd('churrasqueira',ci);ch.x=3500;draw();
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var R={};
          var ctr=function(f){var bb=__boxes().filter(function(q){return q.fr===f.id});var p=[0,1,2].map(function(i){var k=['x','y','z'][i];return (Math.min.apply(null,bb.map(function(q){return q[k+'0']}))+Math.max.apply(null,bb.map(function(q){return q[k+'1']})))/2});return org3api.proj(p)};
          /* 2 toques no micro-ondas, 2 toques na pedra */
          var s0=ctr(mw);__sel3(s0[0],s0[1]);R.esc=__frmv()===mw.id;var lar=__boxes().filter(function(q){return q.fr===mw.id&&q.c&&q.c[0]>200&&q.c[1]<200&&q.c[2]<150}).length;R.laranja=lar>0;
          var st=S.stones[0],sp=org3api.proj([st.x+st.w*0.75,860,300]);__sel3(sp[0],sp[1]);R.pedra=[mw.b,Math.round(mw.x+mw.w/2-(st.x+st.w*0.75))].join();s0=ctr(mw);__sel3(s0[0],s0[1]);var dp=org3api.proj([st.x+st.w*0.3,400,zoOf(b)+b.d+18]);__sel3(dp[0],dp[1]);R.porta=mw.b;
          /* 2 toques na mesa: vai pra cima dela */
          s0=ctr(mw);__sel3(s0[0],s0[1]);var mp=org3api.proj([me.x+me.w/2,750,(+me.y)+me.d/2]);__sel3(mp[0],mp[1]);R.mesa=mw.b;
          /* 2 toques na churrasqueira e 2 toques na parede da esquerda */
          s0=ctr(ch);__sel3(s0[0],s0[1]);var wp=org3api.proj([0,1200,1500]);var h=__ray(wp[0],wp[1]);R.alvoParede=h&&h.n.join();__sel3(wp[0],wp[1]);R.parede=[ch.wall,ch.x].join();
          /* 2 toques no chão */
          s0=ctr(mw);__sel3(s0[0],s0[1]);var fp=org3api.proj([3000,0,1600]);__sel3(fp[0],fp[1]);R.chao=[mw.b,Math.round(mw.x+mw.w/2),Math.round(mw.y+mw.d/2)].join();
          /* 3 toques: configurações */
          s0=ctr(mw);__size3(s0[0],s0[1]);R.config=JSON.stringify(org3api.isx());
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["esc"] as? Bool, true, "2 toques no micro-ondas: escolhido pra mudar de lugar")
        XCTAssertEqual(o["laranja"] as? Bool, true, "fica laranja enquanto espera o lugar novo")
        XCTAssertEqual(o["pedra"] as? String, "860,-2", "2 toques na pedra: vai pra cima dela, no ponto tocado")
        XCTAssertEqual(o["porta"] as? Int, 860, "2 toques na frente do balcão: sobe pra cima da pedra")
        XCTAssertEqual(o["mesa"] as? Int, 750, "2 toques na mesa: vai pra cima da mesa")
        XCTAssertEqual(o["parede"] as? String, "e,1080", "2 toques na parede da esquerda: vai pra ela (L)")
        XCTAssertEqual(o["chao"] as? String, "0,2998,1597", "2 toques no chão: vai pro chão no ponto tocado")
        XCTAssertTrue((o["config"] as? String ?? "").contains("\"fr\""), "3 toques: abre as configurações")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testEletroPelo3DComLupaEmCimaDaPedraMesaEParedeDoL() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));var b=S.mods[0];b.x=600;addStone();S.st.x=600;S.st.w=1800;draw();
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var R={};
          /* ＋ Criar tem a lupa e os atalhos */
          document.getElementById('v3add').click();R.lupa=!!document.querySelector('#crp3 #crpq')+'/'+document.querySelectorAll('#crp3 [data-ccat]').length;
          var qi=document.getElementById('crpq');qi.value='micro-ondas';qi.dispatchEvent(new KeyboardEvent('keydown',{key:'Enter',bubbles:true}));await new Promise(function(r){setTimeout(r,200)});
          var cm=document.getElementById('catm');R.cat=cm&&!cm.hidden?cm.style.zIndex:'fechado';var btn=[].slice.call(document.querySelectorAll('#catm [data-cati]')).filter(function(b){return /Micro-ondas · Bancada/.test(b.textContent)})[0];R.achou=!!btn;
          if(!btn)return JSON.stringify(R);btn.click();await new Promise(function(r){setTimeout(r,200)});var mw=S.fr[S.fr.length-1];R.novo=mw&&mw.t;R.quadro=!!(document.querySelector('[data-qon="st"]'));
          /* em cima da pedra */
          var qq=document.querySelector('[data-qon="st"]');if(!qq){R.isx=JSON.stringify(window.org3api.isx());return JSON.stringify(R)}qq.click();var st=S.stones[0];R.pedra=[mw.b,Math.round(+st.t+(+st.e||40)),mw.y].join();R.onde=!!document.querySelector('[data-qon="st"][style*="1f6feb"]');var bb=__boxes().filter(function(q){return q.fr===mw.id});R.y0=Math.round(Math.min.apply(null,bb.map(function(q){return q.y0})));R.z0=Math.round(Math.min.apply(null,bb.map(function(q){return q.z0})));
          /* mesa no meio e a air fryer em cima dela */
          var me=apAdd('mesa',0);__build();var af=apAdd('airfryer',0);af.x=200;__build();org3api.isx&&0;
          window.__3dAdded(S.fr.length-1,S.mods.length);document.querySelector('[data-qon="mesa"]').click();R.mesa=[af.b,me.h,Math.round(af.x+af.w/2-(me.x+me.w/2)),Math.round(af.y+af.d/2-(me.y+me.d/2))].join();
          var ab=__boxes().filter(function(q){return q.fr===af.id});R.afz=Math.round(Math.min.apply(null,ab.map(function(q){return q.z0})))+'>'+Math.round(me.y);
          /* churrasqueira na parede da esquerda (L) */
          var ci=apModels('churrasqueira').findIndex(function(q){return /Natural 84/.test(q[0])}),ch=apAdd('churrasqueira',ci);ch.x=2500;__build();window.__3dAdded(S.fr.length-1,S.mods.length);fx3api.open({k:'fr',id:ch.id});
          document.querySelector('#it4 [data-qwl="e"]').click();var cb=__boxes().filter(function(q){return q.fr===ch.id}),X0=Math.min.apply(null,cb.map(function(q){return q.x0})),X1=Math.max.apply(null,cb.map(function(q){return q.x1})),Z0=Math.min.apply(null,cb.map(function(q){return q.z0})),Z1=Math.max.apply(null,cb.map(function(q){return q.z1}));
          R.lado=[ch.wall,ch.x,Math.round(X0),Math.round(X1-X0),Math.round(Z0),Math.round(Z1-Z0)].join();
          ele3api.luz(ch.id,1);__build();await new Promise(function(r){setTimeout(r,500)});R.fumaca=fx3api.fx();
          var dc=__boxes().filter(function(q){return q.fr===ch.id});
          /* direita */
          fx3api.open({k:'fr',id:ch.id});document.querySelector('#it4 [data-qwl="d"]').click();cb=__boxes().filter(function(q){return q.fr===ch.id});R.dir=[Math.round(Math.max.apply(null,cb.map(function(q){return q.x1}))),Math.round(Math.min.apply(null,cb.map(function(q){return q.z0})))].join();
          /* sala também tem churrasqueira */
          document.getElementById('v3x').click();var rm=window.roomOf?roomOf():'';R.salaCat=ROOMCATS.sala.indexOf('cchur')>=0&&ROOMCATS.sala.indexOf('ele')>=0;
          /* planta e vista de frente */
          var svgF=document.getElementById('svg').innerHTML.length;R.errs=__errs;
          return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["lupa"] as? String, "true/5", "no ＋ Criar do 3D: lupa e atalhos pros módulos, eletros e mobília")
        XCTAssertEqual(o["cat"] as? String, "90", "o catálogo abre por cima do 3D")
        XCTAssertEqual(o["achou"] as? Bool, true, "a lupa acha o micro-ondas")
        XCTAssertEqual(o["novo"] as? String, "microondas", "escolhido no catálogo, entra no 3D")
        XCTAssertEqual(o["quadro"] as? Bool, true, "e abre o quadro dele com o lugar")
        XCTAssertEqual(o["pedra"] as? String, "860,860,127", "micro-ondas em cima da pedra (pia), na altura dela (pedra encaixada: frente do armário + 40)")
        XCTAssertEqual(o["y0"] as? Int, 860, "no 3D ele fica em cima da pedra")
        XCTAssertEqual(o["mesa"] as? String, "750,750,0,0", "air fryer em cima da mesa, no meio dela")
        XCTAssertEqual(o["lado"] as? String, "e,200,0,570,200,840", "churrasqueira na parede da esquerda (L): medida de fábrica 840 × 570, sem sobra")
        XCTAssertGreaterThan(o["fumaca"] as? Int ?? 0, 10, "na lateral ela também assa e solta fumaça")
        XCTAssertEqual(o["dir"] as? String, "4000,200", "e na parede da direita (medida de fábrica)")
        XCTAssertEqual(o["salaCat"] as? Bool, true, "churrasqueira e eletros em qualquer ambiente")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testBotaoDoLEDUmSoOuUmPorModuloCorEMudarDeLugarCom2Toques() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão 2 portas'));var b=S.mods[0];b.x=1300;
          newTpl(tpl('Aéreo 2 portas'));var a=S.mods[1];a.x=600;a.b=1500;a.led={k:'quente',c:'#ffd27a',pf:'alu',pos:'base',on:1};
          newTpl(tpl('Aéreo 2 portas'));var a2=S.mods[2];a2.x=1600;a2.b=1500;a2.led={k:'quente',c:'#ffd27a',pf:'alu',pos:'base',on:1};S.m=b;draw();
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();
          var R={};document.getElementById('v3add').click();R.ui=document.querySelectorAll('#crp3 [data-clbm]').length+'/'+document.querySelectorAll('#crp3 [data-clbc]').length;
          /* um botão só: liga e desliga todas as luzes */
          document.querySelector('#crp3 [data-clbm="um"]').click();var lb=__lbt();R.um=lb.length+':'+lb.map(function(q){return q.mi}).join();
          org3api.one(lb[0].s[0],lb[0].s[1]);R.off=[a.led.on,a2.led.on].join();org3api.one(lb[0].s[0],lb[0].s[1]);R.on=[a.led.on,a2.led.on].join();
          /* cor do botão */
          document.querySelector('#crp3 [data-clbc="branco"]').click();R.cor=__boxes().filter(function(q){return q.lbt===-1&&q.c&&q.c.join()==='241,241,238'}).length;
          /* um em cada módulo */
          document.querySelector('#crp3 [data-clbm="cada"]').click();R.cada=__lbt().length;document.getElementById('crp3').hidden=true;
          /* 2 toques no botão e 2 toques na porta do balcão: o botão vai pra lá e continua ligando/desligando */
          var s0=__lbt().filter(function(q){return q.mi===1})[0].s;__sel3(s0[0],s0[1]);
          var zf=zoOf(b)+b.d,tg=org3api.proj([b.x+b.w*0.7,b.h*0.55,zf+18]);__sel3(tg[0],tg[1]);
          R.bt=a.led.bt&&a.led.bt.f;var q=__lbt().filter(function(q){return q.mi===1})[0];R.dist=Math.round(Math.hypot(q.s[0]-tg[0],q.s[1]-tg[1]));
          var o0=a.led.on;org3api.one(q.s[0],q.s[1]);R.tog=o0+'>'+a.led.on;
          /* o botão anda junto com o módulo dele */
          var px0=__lbtp().filter(function(q){return q.mi===1})[0].p[0];a.x+=100;__build();R.fica=Math.round(__lbtp().filter(function(q){return q.mi===1})[0].p[0]-px0);b.x+=100;__build();R.anda=Math.round(__lbtp().filter(function(q){return q.mi===1})[0].p[0]-px0);
          document.getElementById('v3x').click();R.errs=__errs;
          return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ui"] as? String, "3/5", "no menu do LED: um botão só / um em cada módulo / sem botão e as cores")
        XCTAssertEqual(o["um"] as? String, "1:-1", "um botão só pra todas as luzes")
        XCTAssertEqual(o["off"] as? String, "0,0", "o botão único desliga todas")
        XCTAssertEqual(o["on"] as? String, "1,1", "e liga todas")
        XCTAssertEqual(o["cor"] as? Int, 1, "botão na cor escolhida (branco)")
        XCTAssertEqual(o["cada"] as? Int, 2, "um botão em cada módulo com LED")
        XCTAssertEqual(o["bt"] as? String, "pt", "2 toques no botão e 2 toques em outro lugar: ele muda de lugar")
        XCTAssertLessThanOrEqual(o["dist"] as? Int ?? 99, 3, "o botão vai pro ponto tocado")
        XCTAssertEqual(o["tog"] as? String, "1>0", "no lugar novo o toque continua desligando o LED")
        XCTAssertEqual(o["fica"] as? Int, 0, "mexer o aéreo não tira o botão da porta onde ele foi posto")
        XCTAssertEqual(o["anda"] as? Int, 100, "o botão anda junto com o móvel onde ele está")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testCatalogoComFotoDeCadaModuloEEletro() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;S.mods=[];S.fr=[];S.env='cozinha';draw();window.CATALL=true;catOpen('inf');
          var imgs=[].slice.call(document.querySelectorAll('#catb img'));
          await Promise.all(imgs.slice(0,6).map(function(im){return new Promise(function(r){if(im.complete&&im.naturalWidth)return r();im.onload=im.onerror=function(){r()};setTimeout(r,5000)})}));
          var ok=imgs.slice(0,6).filter(function(im){return im.naturalWidth>=200}).length;
          /* todo item do catálogo tem foto */
          try{catAp()}catch(_){}var semFoto=[];CATS.forEach(function(c){c.it.forEach(function(it){if(it.act!=='tvs'&&!FOTOS[fotoKey(it)])semFoto.push(it.n)})});
          document.getElementById('catm').hidden=true;
          /* aba Eletrodomésticos também com foto */
          S.tab=7;panel();var tab=document.querySelectorAll('#bd img[src^="fotos/"]').length;
          return JSON.stringify({nf:Object.keys(FOTOS).length,imgs:imgs.length,ok:ok,nSem:semFoto.length,sem:semFoto.slice(0,4).join(' | '),tab:tab,errs:__errs});
          """#)
        XCTAssertGreaterThan(o["nf"] as? Int ?? 0, 250, "fotos de todos os itens do catálogo")
        XCTAssertGreaterThan(o["imgs"] as? Int ?? 0, 5, "os cartões do catálogo mostram a foto")
        XCTAssertEqual(o["ok"] as? Int, 6, "as fotos carregam de dentro do app (pasta fotos)")
        XCTAssertLessThanOrEqual(o["nSem"] as? Int ?? 99, 3, "item sem foto: \(o["sem"] ?? "")")
        XCTAssertGreaterThan(o["tab"] as? Int ?? 0, 50, "a aba Eletrodomésticos também mostra as fotos")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testCarneAssandoComFumacaEBotaoDoLEDLigaEDesliga() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Aéreo 2 portas'));var a=S.mods[0];a.x=600;a.b=1500;a.led={k:'quente',c:'#ffd27a',pf:'alu',pos:'base',on:1};
          newTpl(tpl('Aéreo 2 portas'));var a2=S.mods[1];a2.x=1600;a2.b=1500;a2.led={k:'quente',c:'#ffd27a',pf:'alu',pos:'base',on:1};S.m=a;draw();
          var ci=apModels('churrasqueira').findIndex(function(q){return /Natural 84/.test(q[0])}),ch=apAdd('churrasqueira',ci);ch.x=3000;
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();
          /* botão do LED: cada toque liga/desliga só o LED daquele aéreo */
          var hid=0,nb=0;__boxes().filter(function(q){return q.lbt!==undefined&&q.c&&q.c.join()==='20,21,24'}).forEach(function(k){nb++;var cx=(k.x0+k.x1)/2,cy=(k.y0+k.y1)/2,cz=(k.z0+k.z1)/2;if(__boxes().some(function(q){return q.lbt===undefined&&String(q.nm||'').indexOf(k.lbt+':')===0&&!q.em&&cx>q.x0+.5&&cx<q.x1-.5&&cy>q.y0+.5&&cy<q.y1-.5&&cz>q.z0+.5&&cz<q.z1-.5}))hid++});
          var lb=__lbt(),led=[];for(var i=0;i<lb.length;i++){var s0=lb[i].s;org3api.one(s0[0],s0[1]);led.push(S.mods[lb[i].mi].led.on);org3api.one(s0[0],s0[1]);led.push(S.mods[lb[i].mi].led.on)}
          var door=__boxes().filter(function(q){return /^0:Porta/.test(q.nm)&&(q.x1-q.x0)>300})[0],dc=org3api.proj([(door.x0+door.x1)/2,(door.y0+door.y1)/2,door.z1]);org3api.one(dc[0],dc[1]);var ledDoor=a.led.on;
          /* toque na churrasqueira: acende, a carne vai pra grelha e sai fumaça */
          var n0=__boxes().filter(function(q){return q.fr===ch.id}).length,cp=org3api.proj([ch.x+ch.w/2,700,ch.d-20]);org3api.one(cp[0],cp[1]);var n1=__boxes().filter(function(q){return q.fr===ch.id}).length,msg=(document.getElementById('ambMsg')||{}).textContent||'';
          await new Promise(function(r){setTimeout(r,800)});var fx=fx3api.fx(),chg=__chg();
          org3api.one(cp[0],cp[1]);await new Promise(function(r){setTimeout(r,300)});var chgOff=__chg(),n2=__boxes().filter(function(q){return q.fr===ch.id}).length;
          /* todos os tipos têm carne quando acesos */
          var semCarne=[];['alv','parrilla','gasbox','emb','alvv','ele'].forEach(function(k){S.fr=S.fr.filter(function(f){return f.id!==ch.id});var mi=apModels('churrasqueira').findIndex(function(q){return (q[4]&&q[4].k)===k||chKind({nome:q[0]})===k});if(mi<0){semCarne.push(k+'?');return}var c=apAdd('churrasqueira',mi);c.x=3000;ele3api.luz(c.id,1);__build();var m=__boxes().filter(function(q){return q.fr===c.id&&q.c&&(q.c.join()==='123,52,32'||q.c.join()==='138,47,29')}).length;if(m<4)semCarne.push(k+':'+m);ele3api.luz(c.id,0);S.fr=S.fr.filter(function(f){return f.id!==c.id})});
          document.getElementById('v3x').click();
          return JSON.stringify({nb:nb,hid:hid,tamp:__boxes().filter(function(q){return /^0:Tamponamento/.test(q.nm)}).length,lb:lb.length,led:led.join(','),ledDoor:ledDoor,carne:n1-n0,fx:fx,chg:chg,chgOff:chgOff,volta:n2===n0,semCarne:semCarne.join(','),errs:__errs});
          """#)
        XCTAssertEqual(o["nb"] as? Int, 2, "uma bolinha em cada aéreo com LED")
        XCTAssertEqual(o["hid"] as? Int, 0, "a bolinha fica na face de fora (não escondida dentro do tamponamento)")
        XCTAssertEqual(o["lb"] as? Int, 2, "botão do LED nos dois aéreos")
        XCTAssertEqual(o["led"] as? String, "0,1,0,1", "cada toque na bolinha desliga e liga o LED daquele aéreo")
        XCTAssertEqual(o["ledDoor"] as? Int, 1, "toque na porta não mexe no LED")
        XCTAssertGreaterThan(o["carne"] as? Int ?? 0, 20, "toque na churrasqueira põe a carne na grelha e nos espetos")
        XCTAssertGreaterThan(o["fx"] as? Int ?? 0, 10, "sai fumaça da carne")
        XCTAssertEqual(o["chg"] as? Int, 1, "churrasqueira acesa")
        XCTAssertEqual(o["chgOff"] as? Int, 0, "outro toque apaga")
        XCTAssertEqual(o["volta"] as? Bool, true, "apagada, a carne sai")
        XCTAssertEqual(o["semCarne"] as? String, "", "todos os tipos de churrasqueira assam carne")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPedraLateralIlhaRipadoZoomCantoCegoELinkRecebido() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Balcão canto cego · cego na direita (porta na esquerda)'));var cg=S.mods[0];cg.x=600;newTpl(tpl('Balcão 2 portas'));var n2=S.mods[1];n2.x=1600;S.m=n2;draw();
          var dobCg=mCost(cg).dob,dobN=mCost(n2).dob,cego=partsOf(cg).filter(function(p){return p.cego}).length;
          /* lateral de pedra descendo até o chão: na ponta e num ponto */
          addStone();var st=S.st;st.x=600;st.w=2200;S.tab=6;draw();panel();document.querySelector('#bd [data-stlat="d"]').click();/* lateral só nas pontas (o ponto no meio foi tirado a pedido) */if(document.querySelector('[data-stlat="e"]'))document.querySelector('#bd [data-stlat="e"]').click();
          var lat=(st.lat||[]).map(function(l){return l.at+(l.x!==undefined?l.x:'')}).join(','),svg2=(document.getElementById('svg').innerHTML.match(/stroke="#20262e"/g)||[]).length;
          /* zoom na vista de cima */
          var P=document.getElementById('plan'),w0=+P.getAttribute('viewBox').split(' ')[2];document.querySelector('[data-pz="1"]').click();var w1=+P.getAttribute('viewBox').split(' ')[2];document.querySelector('[data-pz="0"]').click();var w2=+P.getAttribute('viewBox').split(' ')[2];
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var latB=__boxes().filter(function(q){return q.slat!==undefined}).map(function(q){return Math.round(q.y1-q.y0)});
          /* painel cego não abre */
          var fp=partsOf(cg).filter(function(p){return p.cego})[0],pb=__boxes().filter(function(q){return q.pk===fp.pk&&String(q.nm).indexOf('0:Porta')===0})[0],pc=org3api.proj([(pb.x0+pb.x1)/2,(pb.y0+pb.y1)/2,pb.z1]);org3api.one(pc[0],pc[1]);await new Promise(function(r){setTimeout(r,300)});var cegoOd=Object.keys(cg.v[1].od||{}).length;
          /* ilha no meio com armários e painel ripado no lado fechado */
          var il=__islAdd('ilha');for(var w_=0;w_<60&&il._rise;w_++)await new Promise(function(r){setTimeout(r,100)});if(il._rise){delete il._rise;il.h=islNew('ilha').h}il.rip=1;il.st.cas=1;__build();var rip=__boxes().filter(function(q){return q.irip}).length,ripCut=rpCutPieces().filter(function(p){return /painel ripado/.test(p.where)}).length;
          /* tamanho do móvel inteiro com bolinhas no 3D */
          S.m=n2;window.mz3Open();var mzh=document.querySelectorAll('[data-mzh]').length;
          document.getElementById('v3x').click();
          /* link recebido (do Android/iPhone) colado: abre só pra ver */
          var cli=null;ArqueApp.shareClient=function(c){cli=c};document.querySelector('#shb').click();await new Promise(function(r){setTimeout(r,1500)});var ok=cli?arquePasteLink('https://adautoaraujo414-pixel.github.io/Arqueiro-measure/p.html#d='+cli):false;await new Promise(function(r){setTimeout(r,1500)});
          return JSON.stringify({dobCg:dobCg,dobN:dobN,cego:cego,lat:lat,svg2:svg2,w:[w0,w1,w2],latB:latB,cegoOd:cegoOd,rip:rip,ripCut:ripCut,mzh:mzh,ok:ok,ro:!!window.RO,errs:__errs});
          """#)
        XCTAssertEqual(o["cego"] as? Int, 1, "canto cego tem o painel cego")
        XCTAssertLessThan(o["dobCg"] as? Int ?? 9, o["dobN"] as? Int ?? 0, "painel cego sem dobradiça")
        XCTAssertEqual(Set(((o["lat"] as? String) ?? "").split(separator: ",").map(String.init)), ["d", "e"], "lateral nas duas pontas (só nas pontas, não no meio) · \(o["lat"] ?? "")")
        XCTAssertGreaterThanOrEqual(o["svg2"] as? Int ?? 0, 2, "lateral aparece no desenho de frente")
        let w = o["w"] as? [Double] ?? []
        XCTAssertEqual(w.count, 3)
        if w.count == 3 { XCTAssertLessThan(w[1], w[0], "＋ aproxima a vista de cima"); XCTAssertEqual(w[2], w[0], "⌂ volta a ver a pedra inteira") }
        XCTAssertEqual(o["latB"] as? [Int], [820, 820], "lateral desce do chão até a pedra")
        XCTAssertEqual(o["cegoOd"] as? Int, 0, "painel cego não abre")
        XCTAssertGreaterThan(o["rip"] as? Int ?? 0, 10, "ilha com painel ripado")
        XCTAssertEqual(o["ripCut"] as? Int, 2, "ripas e chapa base no plano de corte")
        XCTAssertEqual(o["mzh"] as? Int, 4, "bolinhas pra largura (dos dois lados), altura e fundura do móvel")
        XCTAssertEqual(o["ok"] as? Bool, true, "link colado abre")
        XCTAssertEqual(o["ro"] as? Bool, true, "projeto recebido abre só pra ver")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testConfiguracoesCorredicaOcultaConchaECorteAvulso() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[3]);draw();var m=S.mods[0];
          var vr=vaoRanges(m)[0],vw=vr[1]-vr[0],t=gbox(m.v[0],vw,drawerH(m.v[0]),m.d);
          document.getElementById('prb').click();var cfg=!document.getElementById('stdm').hidden&&document.querySelectorAll('#stdbody [data-cfggo]').length;
          document.querySelector('[data-std="corr"][data-v="oc"]').click();document.querySelector('[data-stdall]').click();
          var oc=gbox(m.v[0],vw,drawerH(m.v[0]),m.d),fd=partsOf(m).filter(function(p){return /^Fundo de gaveta/.test(p.name)})[0];
          var s=STD();s.corr='tel';prSave();
          S.mods=[];newTpl(CATS[0].it[0]);S.m=S.mods[0];pxApplyAll('concha','inox');S.chP={v:'cima',d:60,h:'centro',l:60};draw();
          var cn=partsOf(S.m).filter(function(p){return p.name==='Porta'}).map(function(p){return p.note})[0]||'';
          MC=null;try{localStorage.removeItem('arque.corteAvulso.v1')}catch(e){};mcOpen();MC.list=[{n:'Lateral',w:700,h:560,q:2},{n:'Base',w:870,h:560,q:2}];mcSave();mcRender();mcCalc();
          var mc=document.getElementById('mcres').textContent;document.getElementById('mcm').hidden=true;
          gdOpen();var gd=document.querySelectorAll('#gdbody details').length;document.getElementById('gdm').hidden=true;
          return JSON.stringify({vw:vw,tw:t.w,tOc:t.oc,cfg:cfg,ow:oc.w,od:oc.d,onl:oc.nl,ooc:oc.oc,fnote:fd?fd.note:'',cn:cn,mc:mc.indexOf('Quant. chapas')>=0,gd:gd,errs:__errs});
          """#)
        let vw = o["vw"] as? Double ?? 0
        XCTAssertEqual(o["tw"] as? Double ?? 0, (vw - 26).rounded(), accuracy: 1, "telescópica: caixa = vão − 26")
        XCTAssertEqual(o["tOc"] as? Bool, false)
        XCTAssertEqual(o["cfg"] as? Int, 12, "⚙ abre as Configurações com 12 assuntos (Paredes da obra, Painéis na parede, Senha da obra e Pedra)")
        XCTAssertEqual(o["ow"] as? Double ?? 0, (vw - 12).rounded(), accuracy: 1, "oculta: caixa = vão − 12")
        XCTAssertEqual((o["onl"] as? Double ?? 0) - (o["od"] as? Double ?? 0), 10, accuracy: 0.01, "oculta: caixa 10 mm mais curta que a corrediça")
        XCTAssertEqual(o["ooc"] as? Bool, true)
        XCTAssertTrue((o["fnote"] as? String ?? "").contains("13 mm acima da borda de baixo"), "\(o["fnote"] ?? "")")
        XCTAssertTrue((o["cn"] as? String ?? "").contains("60 mm de cima"), "concha em cima, 60 mm: \(o["cn"] ?? "")")
        XCTAssertEqual(o["mc"] as? Bool, true, "corte avulso calcula as chapas")
        XCTAssertEqual(o["gd"] as? Int, 13, "passo a passo com 13 assuntos")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Ilha com pedra criada no 3D: peças no corte, linha no valor, orçamento do cliente (antes quebrava: TQ não era função), paredes do lado
    func testIlhaComPedraParedesEOrcamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[0].it[3]);S.m=S.mods[0];draw();
          var a=islNew('ilha');S.isl.push(a);var vm=islVM(a),ps=partsOf(vm).map(function(p){return p.name});
          var G=cutGroups(),pc=0;G.ord.forEach(function(k){var g=G.map[k];if(g.where['Ilha 1'])pc+=g.where['Ilha 1']});
          var bu=budget(),row=bu.rows.filter(function(x){return x.m.islN==='Ilha 1'}).length;
          var q=quoteData().items.map(function(i){return i.desc}).join('|');
          S.wl={L:'s'};var wl=sideWalls().L;S.wl=null;
          window.open3D();var bx=window.dbg3all(),ib=bx.filter(function(b){return b.isl===a.id}).length,tx=(bx.filter(function(b){return b.isl===a.id&&b.g==='stc'})[0]||{}).tx||0;
          document.getElementById('v3add').click();var menu=!document.getElementById('crp3').hidden;document.querySelector('[data-cadd="pen"]').click();
          var np=S.isl.length,pen=S.isl[1]||{};document.getElementById('v3x').click();var sv=(snapState().isl||[]).length;
          return JSON.stringify({portas:ps.indexOf('Porta')>=0,fundo:vm.fundo,pc:pc,row:row,q:q,wl:wl,ib:ib,tx:tx,menu:menu,np:np,rot:pen.rot,sv:sv,errs:__errs});
          """#)
        XCTAssertEqual(o["portas"] as? Bool, true, "ilha montada com portas (mesmas regras dos módulos)")
        XCTAssertEqual(o["fundo"] as? Bool, false, "ilha sem fundo de 6 mm: tem fechamento na cor")
        XCTAssertGreaterThanOrEqual(o["pc"] as? Int ?? 0, 10, "peças da Ilha 1 na lista de corte")
        XCTAssertEqual(o["row"] as? Int, 1, "Ilha 1 aparece no valor")
        XCTAssertTrue((o["q"] as? String ?? "").contains("Ilha"), "orçamento do cliente funciona e mostra a ilha: \(o["q"] ?? "")")
        XCTAssertEqual(o["wl"] as? Double, 0, "Mostrar parede esquerda")
        XCTAssertGreaterThan(o["ib"] as? Int ?? 0, 20, "ilha desenhada no 3D")
        XCTAssertEqual(o["tx"] as? Int, 2, "pedra de mármore com veio")
        XCTAssertEqual(o["menu"] as? Bool, true, "＋ Criar abre o menu")
        XCTAssertEqual(o["np"] as? Int, 2, "＋ Península cria a segunda")
        XCTAssertEqual(o["rot"] as? Int, 90, "península girada")
        XCTAssertEqual(o["sv"] as? Int, 2, "projeto salva as ilhas")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// LED com cor embaixo dos aéreos, cooktop aceso com panelas, torneira com água e tocar pra editar (pedra, parede) no 3D
    func testLEDChamaAguaEEditarNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];S.st.items.push({id:77,k:'cook',x:1500,y:60,w:600,d:500});apAdd('torneira',0);draw();
          window.open3D();fx3api.lk({k:'45',c:'azul'});fx3api.add('sup');var led=S.mods[1].led||{},nl=fx3api.leds(),len=fx3api.len();
          fx3api.open({k:'cook',sid:S.st.id,iid:77});document.querySelector('#it4 [data-qfire="1"]').click();var fire=Object.keys(fx3api.fire()).length;document.querySelector('#it4 [data-qpan="1"]').click();var pan=S.st.items.filter(function(i){return i.k==='cook'})[0].pan;
          var tq=S.fr.filter(function(f){return f.t==='torneira'})[0];fx3api.open({k:'fr',id:tq.id});document.querySelector('#it4 [data-qwat="1"]').click();var wat=Object.keys(fx3api.water()).length;
          await new Promise(function(r){setTimeout(r,500)});var fx=fx3api.fx();
          fx3api.open({k:'st',id:S.st.id});var w0=S.st.w;document.querySelector('#it4 [data-qin="w|-50"]').click();var w1=S.st.w;
          fx3api.open({k:'wall',s:'F'});document.querySelector('#it4 [data-qwc="#b8c4ae"]').click();var wc=S.wc;
          fx3api.night(1);fx3api.night(0);var sv=snapState();document.getElementById('v3x').click();
          return JSON.stringify({k:led.k,c:led.c,nl:nl,len:len,fire:fire,pan:pan,wat:wat,fx:fx,dw:w0-w1,wc:wc,svled:!!sv.mods[1].led,svwc:sv.wc,errs:__errs});
          """#)
        XCTAssertEqual(o["k"] as? String, "45", "perfil 45°")
        XCTAssertEqual(o["c"] as? String, "azul", "luz azul")
        XCTAssertEqual(o["nl"] as? Int, 1, "uma fita embaixo do aéreo")
        XCTAssertGreaterThan(o["len"] as? Double ?? 0, 0.5, "metros de fita contados")
        XCTAssertEqual(o["fire"] as? Int, 4, "Acender todas: 4 bocas")
        XCTAssertEqual(o["pan"] as? Int, 1, "panelas no cooktop")
        XCTAssertEqual(o["wat"] as? Int, 1, "torneira com água")
        XCTAssertGreaterThan(o["fx"] as? Int ?? 0, 10, "chama, vapor e água desenhados")
        XCTAssertEqual(o["dw"] as? Double, 0, "pedra travada no 3D: o − não muda a medida (muda pela aba Pedra)")
        XCTAssertEqual(o["wc"] as? String, "#b8c4ae", "cor da parede")
        XCTAssertEqual(o["svled"] as? Bool, true, "projeto salva o LED")
        XCTAssertEqual(o["svwc"] as? String, "#b8c4ae", "projeto salva a cor da parede")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Tamponamento do aéreo rente com a régua (sem vão), tamponamento de baixo colado nela, eletros com formato de verdade e desenho no catálogo
    func testReguaTamponamentoRenteEEletrosReais() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          try{STD().supPedra=0}catch(_){}/* teste antigo: aéreo pela altura do chão (sem a regra dos 700 acima da pedra) */
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[1].it[2]);var m=S.mods[0];m.regua=true;m.regN=2;m.tl=true;m.tlA='tamp';m.tr=true;m.trA='cava';m.tb=true;m.tpass=false;draw();
          var top=m.b+m.h,y0=function(p){return top-p.y-p.h},y1=function(p){return top-p.y},pn=function(L,n){return L.filter(function(p){return p.name===n})[0]};
          var P=partsOf(m),reg=P.filter(function(p){return /^Engrosso cava · régua/.test(p.name)}),rb=Math.min.apply(null,reg.map(y0)),tb=pn(P,'Tamponamento de baixo'),tl=pn(P,'Tamponamento esquerdo'),tr=pn(P,'Tamponamento direito');
          m.tb=false;draw();var tl2=pn(partsOf(m),'Tamponamento esquerdo');
          S.fr=[];var g=apAdd('geladeira',2),t=apAdd('torneira',0);window.open3D();var bx=window.dbg3all(),gb=bx.filter(function(b){return b.fr===g.id}).length,tq=bx.filter(function(b){return b.fr===t.id}).length;document.getElementById('v3x').click();
          catOpen('cgel');var ic=document.querySelectorAll('#catb [data-cati] svg, #catb [data-cati] img').length,nb=document.querySelectorAll('#catb [data-cati]').length;document.getElementById('catm').hidden=true;
          return JSON.stringify({mb:m.b,rb:rb,tbTop:y1(tb),tbBot:y0(tb),tlBot:y0(tl),trBot:y0(tr),tl2Bot:y0(tl2),gb:gb,tq:tq,ic:ic,nb:nb,errs:__errs});
          """#)
        let mb = o["mb"] as? Double ?? 0, rb = o["rb"] as? Double ?? 0, tbBot = o["tbBot"] as? Double ?? 0
        XCTAssertEqual(mb - rb, 30, accuracy: 0.01, "régua de 2 camadas = 30 mm embaixo do aéreo")
        XCTAssertEqual(o["tbTop"] as? Double ?? 0, rb, accuracy: 0.01, "tamponamento de baixo colado na régua (sem vão)")
        XCTAssertEqual(o["tlBot"] as? Double ?? 0, tbBot, accuracy: 0.01, "pós cava rente com o tamponamento de baixo")
        XCTAssertEqual(o["trBot"] as? Double ?? 0, tbBot, accuracy: 0.01, "até a cava rente com o tamponamento de baixo")
        XCTAssertEqual(o["tl2Bot"] as? Double ?? 0, rb, accuracy: 0.01, "sem tamponamento de baixo: pós cava rente com a régua")
        XCTAssertGreaterThanOrEqual(o["gb"] as? Int ?? 0, 15, "geladeira com portas, puxadores e dispenser")
        XCTAssertGreaterThan(o["tq"] as? Int ?? 0, 10, "torneira gourmet com mola e bico")
        XCTAssertEqual(o["ic"] as? Int, o["nb"] as? Int, "cada eletro do catálogo com a foto (ou o desenho) na frente")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Balcão em L e U: módulos do fundo e da lateral não se sobrepõem (pingadeira de 5 mm descontada na divisão)
    func testPlacaDo3DSolidaTravaApagaAparece2DEPlanoDeCorte() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.geo=[];S.env='sala';S.room='sala';S.W=3400;S.H=2890;S.Hm=1;S.Wm=1;var a=rpNew({x:600,b:0,w:1035,h:2700});a.liso=true;draw();open3D();
          var T=__geoT();T.add('placa');var g=S.geo[0];T.set('gx',700);T.set('gz',-10);var z=g.z;T.set('gh',3500);var h=g.h;T.close();var lk=g.lock?1:0;
          var G=cutGroups(),pl=G.ord.filter(function(k){return /\|geo\|/.test(k)}).length;document.getElementById('v3x').click();draw();var d2=document.querySelectorAll('.geo2d').length;
          open3D();__itOpen({k:'geo',id:g.id});var E=T.box();var b=E.querySelector('[data-qdel]')||E.querySelector('[data-qgdel]');b.click();(E.querySelector('[data-qdel]')||E.querySelector('[data-qgdel]')).click();
          return JSON.stringify({z:z,h:h,lk:lk,pl:pl,d2:d2,sobra:S.geo.length,errs:__errs});
          """#)
        XCTAssertEqual(o["z"] as? Int, 18, "não entra na parede nem no painel: fica encostada na frente")
        XCTAssertEqual(o["h"] as? Int, 2890, "não passa do teto")
        XCTAssertEqual(o["lk"] as? Int, 1, "fechar o quadro trava")
        XCTAssertEqual(o["pl"] as? Int, 1, "placa no plano de corte")
        XCTAssertEqual(o["d2"] as? Int, 1, "placa aparece no 2D")
        XCTAssertEqual(o["sobra"] as? Int, 0, "🗑 apaga a placa")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testBasculanteComCavaSemEngrossoFolga4NoTopo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.env='sala';S.room='sala';S.W=3400;S.H=2890;S.Hm=1;S.Wm=1;
          newTpl({n:'Rack de TV',w:1800,h:500,d:450,b:400,keep:true,div:[1/3,2/3],v:[{k:'door',n:1},{k:'door',n:1},{k:'door',n:1}]});var m=S.mods[S.mods.length-1];
          m.v.forEach(function(v){if(v.k==='door')v.bas=1});draw();var top=function(){return Math.round(Math.max.apply(null,dbg3all().filter(function(q){return /^\d+:Porta/.test(q.nm)}).map(function(q){return q.y1})))};
          var a=top();m.regua=1;draw();var b=top();
          return JSON.stringify({sem:(m.b+m.h)-a,com:(m.b+m.h)-b,errs:__errs});
          """#)
        XCTAssertEqual(o["sem"] as? Int, 4, "basculante com cava sem engrosso: 4 mm abaixo do topo")
        XCTAssertLessThan(o["com"] as? Int ?? 99, 1, "com engrosso cava a porta sobe até o topo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testSofaSolidoGiraSalvaExcluiEm2DE3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.fr=[];S.geo=[];S.ops=[];S.stones=[];S.env='sala';S.room='sala';S.W=4000;S.H=2800;S.Hm=1;S.Wm=1;S.RD=4000;draw();open3D();
          var a=apAdd('sofa',1);draw();var b3=__bb3('fr',a.id);var dentro=b3.x0>=a.x-1&&b3.x1<=a.x+a.w+1&&b3.z0>=a.y-1&&b3.z1<=a.y+a.d+1&&b3.y0>=0;
          var p=apAdd('poltrona',0);__isx({k:'fr',id:p.id});__itSet('x',a.x);__itSet('y',0);var sob=Math.min(a.x+a.w,p.x+p.w)-Math.max(a.x,p.x)>1&&Math.min(a.y+a.d,p.y+p.d)-Math.max(a.y,p.y)>1;
          mobAct(a,'rot',90);var g90=a.rot===90&&a.w===950&&a.d===2200;mobAct(a,'cor','verde');mobAct(a,'tec','veludo');
          var st=JSON.stringify(snapState());S.fr=[];loadState(JSON.parse(st));var a2=S.fr.filter(function(q){return q.id===a.id})[0];var salvo=!!a2&&a2.rot===90&&a2.cor==='verde'&&a2.tec==='veludo';
          document.getElementById('v3x').click();draw();var em2d=!!document.querySelector('[data-ap="'+a.id+'"]');open3D();
          S.fr=S.fr.filter(function(q){return q.id!==a.id});draw();var some=!__bb3('fr',a.id);
          return JSON.stringify({dentro:dentro,sob:sob,g90:g90,salvo:salvo,em2d:em2d,some:some,errs:__errs});
          """#)
        XCTAssertEqual(o["dentro"] as? Bool, true, "3D do sofá dentro da medida e no piso")
        XCTAssertEqual(o["sob"] as? Bool, false, "poltrona não fica por cima do sofá")
        XCTAssertEqual(o["g90"] as? Bool, true, "girou 90° trocando largura e profundidade")
        XCTAssertEqual(o["salvo"] as? Bool, true, "salva e reabre com giro, cor e tecido")
        XCTAssertEqual(o["em2d"] as? Bool, true, "aparece no 2D")
        XCTAssertEqual(o["some"] as? Bool, true, "excluir tira do 3D")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPortaDeVidroTelescopicaReconstroiEAbre() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.fr=[];S.ops=[];S.stones=[];S.env='sala';S.room='sala';S.W=4000;S.H=2800;S.Hm=1;S.Wm=1;draw();open3D();
          S.ops.push({id:77,t:'porta',w:3000,h:2300,x:500,b:0,st:'vidro',vm:'t4',vc:'fume',fp:'preto'});draw();var I=vdInfo(S.ops[0]);
          var vid=function(){__anim();return dbg3().filter(function(q){return q.a&&q.a<.9&&q.y1-q.y0>1500}).length};var n4=vid();S.ops[0].vm='t3';var n3=vid();S.ops[0].vm='t6';var n6=vid();
          var xs=function(){return dbg3().filter(function(q){return q.a&&q.a<.9&&q.y1-q.y0>1500}).map(function(q){return Math.round(q.x0)}).sort(function(a,b){return a-b}).join(',')};__anim();var fe=xs();S.ops[0].open=true;__anim();var ab=xs();
          return JSON.stringify({lw:I.lw,nt:I.nt,free:I.free,n3:n3,n4:n4,n6:n6,mudou:fe!==ab,errs:__errs});
          """#)
        XCTAssertEqual(o["lw"] as? Double, 787.5, "folha = (vão + 3 sobreposições de 50) ÷ 4")
        XCTAssertEqual(o["nt"] as? Int, 4, "4 trilhos")
        XCTAssertEqual(o["n3"] as? Int, 3, "3 folhas no 3D")
        XCTAssertEqual(o["n4"] as? Int, 4, "4 folhas no 3D")
        XCTAssertEqual(o["n6"] as? Int, 6, "6 folhas no 3D")
        XCTAssertEqual(o["mudou"] as? Bool, true, "abriu: folhas recolheram")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPainelNaoEntraNoVizinhoNemNaJunta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.env='sala';S.room='sala';S.W=2600;S.H=2890;S.Hm=1;S.Wm=1;
          var a=rpNew({x:0,b:1000,w:1035,h:365});a.liso=true;a.jt={t:'reb',w:15,d:6};var c=rpNew({x:1050,b:1000,w:721,h:365});c.liso=true;c.jt={t:'reb',w:15,d:6};var t=rpNew({x:0,b:1365,w:1035,h:175});t.liso=true;draw();
          var R={x:0,w:1035,b:1000,h:365},lr=rpEdgeLim(a,'r',R),lt=rpEdgeLim(a,'t',R);
          a.w=1300;rpFitTyped(a,'w',1035);var w1=a.w;a.h=800;rpFitTyped(a,'h',365);var h1=a.h;draw();
          return JSON.stringify({lr:lr,lt:lt,w:w1,h:h1,cx:c.x,cw:c.w,errs:__errs});
          """#)
        XCTAssertEqual(o["lr"] as? Double, 1035, "borda direita para antes da junta de 15")
        XCTAssertEqual(o["lt"] as? Double, 1365, "borda de cima para no painel de cima")
        XCTAssertEqual(o["w"] as? Double, 1035, "largura digitada não entra no vizinho")
        XCTAssertEqual(o["h"] as? Double, 365, "altura digitada não entra no de cima")
        XCTAssertEqual(o["cx"] as? Double, 1050, "vizinho não foi empurrado")
        XCTAssertEqual(o["cw"] as? Double, 721, "vizinho não foi encolhido")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testBalcaoEmLSemModuloSobreposto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R=[];[['e',3000,2000,600],['d',3000,2000,600],['u',3600,1800,600],['e',3333,1777,600],['d',4100,2650,580]].forEach(function(c){S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.env='cozinha';S.W=Math.max(c[1],3000);S.H=2700;S.Hm=1;S.Wm=1;draw();mkL(c[0],c[1],c[2],c[3],1);draw();
           var row=S.mods.filter(function(m){return !m.sup&&!m.wing}).sort(function(a,b){return a.x-b.x});for(var i=1;i<row.length;i++){var ov=row[i-1].x+row[i-1].w-row[i].x;if(ov>0.5)R.push(c.join('x')+': '+Math.round(ov)+' mm')}
           var st=S.stones[0];row.forEach(function(m){if(m.x<st.x+4.5||m.x+m.w>st.x+st.w-4.5)R.push(c.join('x')+': módulo sem pingadeira '+m.x+'+'+m.w)})});
          return JSON.stringify({r:R.join(' | '),errs:__errs});
          """#)
        XCTAssertEqual(o["r"] as? String, "", "módulos sobrepostos no balcão em L/U")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testAcabamentoDosEletrosETVReal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);S.fr=[];var g=apAdd('geladeira',2),t=apAdd('torneira',0),v=apAdd('tv',1);draw();
          var d0=[apFin(g),apFin(t),apFin(v)].join();
          window.open3D();var lum=function(id){var b=window.dbg3all().filter(function(q){return q.fr===id&&!q.em&&Array.isArray(q.c)}),s=0,n=0;b.forEach(function(q){var a=(q.x1-q.x0)*(q.y1-q.y0)+(q.x1-q.x0)*(q.z1-q.z0)+(q.y1-q.y0)*(q.z1-q.z0);s+=a*(q.c[0]+q.c[1]+q.c[2])/3;n+=a});return n?s/n:-1};
          var gI=lum(g.id);window.fx3api.open({k:'fr',id:g.id});var chips=document.querySelectorAll('#it4 [data-qfin]').length;document.querySelector('#it4 [data-qfin="preto"]').click();var gP=lum(g.id);
          window.fx3api.open({k:'fr',id:t.id});var tch=document.querySelectorAll('#it4 [data-qfin]').length;document.querySelector('#it4 [data-qfin="dourado"]').click();
          window.fx3api.open({k:'fr',id:v.id});var vch=document.querySelectorAll('#it4 [data-qfin]').length,tvn=window.dbg3all().filter(function(q){return q.fr===v.id}).length;
          document.getElementById('v3x').click();
          var st=JSON.parse(JSON.stringify(snapState()));S.fr.forEach(function(f){delete f.fin});loadState(st);
          var svg=(document.querySelector('[data-ap="'+g.id+'"]')||{}).innerHTML||'';
          return JSON.stringify({d0:d0,gI:gI,gP:gP,chips:chips,tch:tch,vch:vch,tvn:tvn,fins:S.fr.map(function(f){return f.fin||''}).join(),preto2d:svg.indexOf('#3a3e44')>=0,errs:__errs});
          """#)
        XCTAssertEqual(o["d0"] as? String, "inox,cromado,", "sem escolher: Inox e Cromado; TV sem acabamento")
        XCTAssertEqual(o["chips"] as? Int, 3, "geladeira: Inox, Branco, Preto")
        XCTAssertEqual(o["tch"] as? Int, 5, "torneira: Cromado, Preto fosco, Dourado, Inox escovado, Rose gold")
        XCTAssertEqual(o["vch"] as? Int, 0, "TV sem botão de acabamento")
        let gI = o["gI"] as? Double ?? 0, gP = o["gP"] as? Double ?? 0
        XCTAssertLessThan(gP, gI * 0.5, "geladeira preta fica escura no 3D")
        XCTAssertGreaterThanOrEqual(o["tvn"] as? Int ?? 0, 7, "TV com borda, caixa de trás, suporte, luz e reflexo")
        XCTAssertEqual(o["fins"] as? String, "preto,dourado,", "acabamento salvo no projeto")
        XCTAssertEqual(o["preto2d"] as? Bool, true, "desenho 2D segue o acabamento")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testParedesCubasCooktopEDormitorio() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];draw();
          var sw=sideWalls(),lados=(sw.L===0&&sw.R===S.W);
          window.open3D();window.fx3api.open({k:'wall',s:'L'});var campos=Array.prototype.map.call(document.querySelectorAll('#it4 [data-qf]'),function(i){return i.dataset.qf}).join(),tipos=document.querySelectorAll('#it4 [data-qwt]').length,ori=document.querySelectorAll('#it4 [data-qwo]').length;
          var i=document.querySelector('#it4 [data-qf="wrel"]');i.value='110';i.dispatchEvent(new Event('change',{bubbles:true}));var w=window.dbgWall(),gir=!!(w.L[0]&&w.L[0].gp&&w.L[0].x0<-500),ang=S.wall.L.a;
          document.getElementById('v3x').click();S.wall=null;draw();
          S.st.items=[];S.st.w=2600;catAct2({act:'cuba',cm:'mar2'});catAct2({act:'cook',cm:'b5t'});S.st.items[0].x=200;S.st.items[1].x=1500;draw();
          window.open3D();var bx=window.dbg3all(),cuba=bx.filter(function(q){return q.sid===S.st.id&&!q.ck}).length,cook=bx.filter(function(q){return q.ck}).length;document.getElementById('v3x').click();
          var bocas=cookPos(S.st.items[1]).length,cubas=cubaBowls(S.st.items[0]).length;
          S.room='quarto';S.env='livre';S.mods=[];S.stones=[];S.st=null;draw();
          var arm=CATS.filter(function(c){return c.id==='dArm'})[0].it;newTpl(arm[4]);var P=partsOf(S.mods[0]).map(function(p){return p.name});var semL=arm.filter(function(it){S.mods=[];newTpl(it);var q=partsOf(S.mods[0]).map(function(p){return p.name});return q.indexOf('Lateral esquerda')<0||q.indexOf('Lateral direita')<0}).map(function(it){return it.n});var P2=semL;
          return JSON.stringify({lados:lados,campos:campos,tipos:tipos,ori:ori,gir:gir,ang:ang,cuba:cuba,cook:cook,bocas:bocas,cubas:cubas,narm:arm.length,portas:P.filter(function(n){return n==='Porta'}).length,gav:P.filter(function(n){return n==='Frente de gaveta'}).length,semLat:P2.join(','),errs:__errs});
          """#)
        XCTAssertEqual(o["lados"] as? Bool, true, "paredes do lado aparecem sempre")
        XCTAssertEqual(o["campos"] as? String, "wlen,wabs,wrel,wt,wh0,wh1", "editor de paredes com comprimento, ângulos, espessura e pé-direito")
        XCTAssertEqual(o["tipos"] as? Int, 4, "tipo da parede")
        XCTAssertEqual(o["ori"] as? Int, 3, "orientação")
        XCTAssertEqual(o["gir"] as? Bool, true, "parede girada no 3D")
        XCTAssertEqual(o["ang"] as? Int, 110, "ângulo salvo")
        XCTAssertGreaterThan(o["cuba"] as? Int ?? 0, 60, "cuba com aba, cantos redondos e ralo")
        XCTAssertGreaterThan(o["cook"] as? Int ?? 0, 60, "cooktop com grades e botões")
        XCTAssertEqual(o["bocas"] as? Int, 5, "cooktop 5 bocas")
        XCTAssertEqual(o["cubas"] as? Int, 2, "Marea 2C com 2 cubas")
        XCTAssertEqual(o["narm"] as? Int, 12, "12 armários de dormitório (10 com as duas laterais + 2 que usam a lateral do vizinho)")
        XCTAssertEqual(o["portas"] as? Int, 2, "2P+Gav Ext: 2 portas")
        XCTAssertEqual(o["gav"] as? Int, 3, "2P+Gav Ext: 3 gavetas de fora")
        XCTAssertEqual(o["semLat"] as? String, "Armário sem lateral direita (usa a do vizinho),Armário sem laterais (entre dois armários)", "só os 2 armários feitos pra usar a lateral do vizinho ficam sem lateral")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testSetinhasParedesECaixa() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];draw();apAdd('geladeira',0);draw();
          window.open3D();window.fx3api.open({k:'st',id:S.st.id});var st=ah3api.specs().join();
          window.fx3api.open({k:'fr',id:S.fr[0].id});var fr=ah3api.specs().join();window.fx3api.open({k:'mod',mi:1});var md=ah3api.specs().join();
          window.fx3api.open({k:'wall',s:'P'});var pi=ah3api.specs().join();var vis=document.querySelectorAll('#ah3 [data-ah]').length;
          S.geo=[{id:1,x:600,z:900,w:600,d:400,b:0,h:300,c:'#d9d4ca'}];S.xw=[{id:1,a:[500,1500],b:[2000,1500],t:150}];window.re3();
          var gb=window.dbg3all().length;window.fx3api.open({k:'geo',id:1});var gs=ah3api.specs().join();window.fx3api.open({k:'wall',s:'X1'});var xs=ah3api.specs().join();
          ah3api.wm(1);var bar=Array.prototype.map.call(document.querySelectorAll('#v3wb [data-wb]'),function(b){return b.dataset.wb}).slice(0,3).join();ah3api.del('X1');var nx=S.xw.length;ah3api.del('L');var semL=sideWalls().L===null;ah3api.wm(0);
          var sv=JSON.parse(JSON.stringify(snapState()));document.getElementById('v3x').click();
          return JSON.stringify({st:st,fr:fr,md:md,pi:pi,vis:vis,gs:gs,xs:xs,bar:bar,nx:nx,semL:semL,sg:(sv.geo||[]).length,errs:__errs});
          """#)
        XCTAssertEqual(o["st"] as? String, "", "pedra travada no 3D: sem setinhas (muda pela aba Pedra)")
        XCTAssertEqual(o["fr"] as? String, "xm,xp,yp,ym,zp", "eletro: setinhas")
        XCTAssertEqual(o["md"] as? String, "xm,xp,yp,zp,ym", "aéreo: setinhas")
        XCTAssertEqual(o["pi"] as? String, "pc,px,pz", "piso: canto e lados")
        XCTAssertGreaterThanOrEqual(o["vis"] as? Int ?? 0, 2, "setinhas aparecem por cima do 3D")
        XCTAssertEqual(o["gs"] as? String, "xm,xp,ym,yp,zm,zp", "caixa: 6 setinhas")
        XCTAssertEqual(o["xs"] as? String, "xa,xb,xt", "parede nova: pontas e altura")
        XCTAssertEqual(o["bar"] as? String, "new,del,ok", "cabeçalho simples das paredes")
        XCTAssertEqual(o["nx"] as? Int, 0, "apagar parede nova")
        XCTAssertEqual(o["semL"] as? Bool, true, "apagar parede esquerda")
        XCTAssertEqual(o["sg"] as? Int, 1, "caixa salva no projeto")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Testes do iPhone (02/11): quadro do módulo, LED só em cima, teto, fogão que abre, puxador arrastável, mobília, modo pessoa e projeto do cliente.
    @MainActor
    func testOrganizacao3DClienteEModoPessoa() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(3);newTpl(2);newTpl(4);draw();ensureProj();
          window.open3D();await new Promise(function(r){setTimeout(r,400)});
          window.fx3api.open({k:'mod',mi:0});var E=document.getElementById('it4'),ledBase=!!E.querySelector('[data-qmled]');
          S.m=S.mods[0];window.mz3Open();document.querySelector('#mz3 [data-mz="w|10"]').click();var w=S.mods[0].w,nx=S.mods[1].x;
          window.fx3api.open({k:'mod',mi:2});var ledSup=!!document.querySelector('#it4 [data-qmled]');
          document.getElementById('v3wal').click();document.querySelector('#it4 [data-qwtab="T"]').click();document.querySelector('#it4 [data-qtt="1"]').click();
          var fi=apModels('forno').findIndex(function(q){return /^Fogão de piso 6 bocas/.test(q[0])}),fg=apAdd('forno',fi);window.ele3api.toggle(fg.id,true);
          await new Promise(function(r){setTimeout(r,700)});var ang=window.ele3api.ang(fg.id);
          window.pux3api.open(0);document.querySelector('#it4 [data-pxt="bola"]').click();window.pux3api.set(60,120);var px=S.mods[0].v[0].px;
          var bq=apAdd('banqueta',1);
          window.fp3api.start();var teto=window.org3api.teto();window.fp3api.walk(1,0);var fp=!!window.fp3api.st();window.fp3api.stop();
          var code=await cutEncode(window.clientPayload());window.arqueCutOpen(code);await new Promise(function(r){setTimeout(r,900)});
          return JSON.stringify({ledBase:ledBase,ledSup:ledSup,w:w,nx:nx,teto:teto,ang:ang,px:px,bq:bq.t,fp:fp,clv:!!window.CLV,ro:!!window.RO,errs:__errs});
          """#)
        XCTAssertEqual(o["ledBase"] as? Bool, false, "LED não vai no módulo de baixo")
        XCTAssertEqual(o["ledSup"] as? Bool, true, "LED no aéreo")
        XCTAssertEqual(o["w"] as? Double, 910, "＋10 na largura")
        XCTAssertEqual(o["nx"] as? Double, 915, "o módulo do lado foi empurrado")
        XCTAssertGreaterThan(o["teto"] as? Int ?? 0, 0, "teto no 3D")
        XCTAssertGreaterThan(o["ang"] as? Double ?? 0, 0, "porta do forno do fogão abrindo")
        XCTAssertEqual(o["px"] as? String, "bola", "puxador bola")
        XCTAssertEqual(o["bq"] as? String, "banqueta", "banqueta")
        XCTAssertEqual(o["fp"] as? Bool, true, "modo pessoa")
        XCTAssertEqual(o["clv"] as? Bool, true, "projeto do cliente abre só pra ver")
        XCTAssertEqual(o["ro"] as? Bool, true, "cliente não edita")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }
    /// iPad/iPhone: cuba e cooktop arrastam na vista de cima (toque), de novo e de novo, com zoom, e seguem pelos eventos de toque
    /// se o WebKit cancelar o ponteiro (pointercancel); teclado do campo só aplica no OK (125+120+120+120 = 485 sem bagunçar a cuba);
    /// lixeira no 3D; parede encolhida leva pedra e móveis junto; altura da pedra puxa os módulos; tamponamento automático não pisca
    @MainActor
    func testCubaArrastaNoTouchTecladoSomaLixeiraEParedeEncolhida() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          S.mods=[];S.fr=[];S.stones=[];S.W=5610;newTpl(CATS[0].it[0]);newTpl(CATS[0].it[0]);addStone();var st=S.st;st.x=0;st.w=2950;st.shape='Le';st.lenA=1870;st.widA=650;
          addItem('cuba');addItem('cook');var cu=S.items[0],ck=S.items[1];cu.x=970;cu.y=95;ck.x=1700;ck.y=60;S.tab=6;draw();panel();pzSet(1);await new Promise(function(r){setTimeout(r,250)});
          var P=document.getElementById('plan');P.scrollIntoView({block:'center'});await new Promise(function(r){setTimeout(r,150)});
          function pe(type,tg,id,x,y){tg.dispatchEvent(new PointerEvent(type,{bubbles:true,cancelable:true,pointerId:id,pointerType:'touch',isPrimary:true,clientX:x,clientY:y}))}
          async function drag(it,dx,id){var el=P.querySelector('[data-i="'+it.id+'"]');if(!el)return 'sem rect';var bb=el.getBoundingClientRect(),x0=bb.left+bb.width/2,y0=bb.top+bb.height/2,ox=it.x;pe('pointerdown',el,id,x0,y0);await new Promise(function(r){setTimeout(r,30)});for(var i=1;i<=8;i++){pe('pointermove',P,id,x0+dx*i/8,y0);await new Promise(function(r){requestAnimationFrame(r)})}pe('pointerup',P,id,x0+dx,y0);await new Promise(function(r){setTimeout(r,120)});return it.x-ox}
          var d1=await drag(cu,30,11),d2=await drag(cu,-20,12),d3=await drag(ck,-25,13),d4=await drag(ck,20,14);pzSet(2);await new Promise(function(r){setTimeout(r,120)});var d5=await drag(cu,15,15);pzSet(1);await new Promise(function(r){setTimeout(r,120)});
          /* pointercancel → segue pelo toque (TouchEvent só se o WebKit deixar construir) */var d6=null;try{var el=P.querySelector('[data-i="'+cu.id+'"]'),bb=el.getBoundingClientRect(),x0=bb.left+bb.width/2,y0=bb.top+bb.height/2,ox=cu.x;pe('pointerdown',el,17,x0,y0);await new Promise(function(r){setTimeout(r,30)});P.dispatchEvent(new PointerEvent('pointercancel',{bubbles:true,cancelable:true,pointerId:17,pointerType:'touch',isPrimary:true}));
            function tm(type,x,y){var tc=new Touch({identifier:17,target:el,clientX:x,clientY:y});P.dispatchEvent(new TouchEvent(type,{bubbles:true,cancelable:true,touches:type==='touchend'?[]:[tc],changedTouches:[tc]}))}
            for(var j=1;j<=8;j++){tm('touchmove',x0+5*j,y0);await new Promise(function(r){requestAnimationFrame(r)})}tm('touchend',x0+40,y0);await new Promise(function(r){setTimeout(r,120)});d6=cu.x-ox}catch(e){d6='sem Touch: '+e.message}
          /* teclado do campo: 125+120+120+120 → 485 só no OK; a cuba não é empurrada enquanto digita */
          cu.x=300;draw();panel();var inp=document.querySelector('#bd input[data-k="stW"]');var ws=[],cxs=[];var kd=null;if(inp){inp.focus();await new Promise(function(r){setTimeout(r,120)});var seq=['1','2','5','+','1','2','0','+','1','2','0','+','1','2','0'];for(var q=0;q<seq.length;q++){var bt=document.querySelector('[data-c="'+seq[q]+'"]');bt.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,cancelable:true}));await new Promise(function(r){setTimeout(r,25)});ws.push(S.st.w);cxs.push(cu.x)}var okb=document.querySelector('[data-c="ok"]');okb.dispatchEvent(new PointerEvent('pointerdown',{bubbles:true,cancelable:true}));await new Promise(function(r){setTimeout(r,200)});kd={w:S.st.w,wsDuranteOk:ws.every(function(w){return w===2950}),cxDurante:cxs.every(function(c){return c===300})}}
          /* lixeira */var lx=apAdd('lixeira',1);var lix={b:lx.b,x:lx.x,y:lx.y,n:apModels('lixeira').length};open3D();await new Promise(function(r){setTimeout(r,300)});__build();lix.caixas=__boxes().filter(function(b){return b.fr===lx.id}).length;document.getElementById('v3x').click();
          /* parede encolhe: pedra e lixeira ficam dentro */S.st.w=2950;setv('W',2400);await new Promise(function(r){setTimeout(r,150)});var enc={W:S.W,stFim:S.st.x+S.st.w,lixFim:lx.x+lx.w};
          /* altura da pedra puxa os módulos */var tops0=S.mods.filter(function(m){return !m.sup}).map(function(m){return (m.b||0)+m.h});setv('stT',900);await new Promise(function(r){setTimeout(r,100)});var tops1=S.mods.filter(function(m){return !m.sup}).map(function(m){return (m.b||0)+m.h});
          /* tamponamento automático não pisca a 25 mm da parede */S.W=3000;var m0=S.mods[0];m0.x=25;m0.tl=false;delete m0.tlAuto;var seq2=[];for(var z=0;z<4;z++){window.autoTamp();seq2.push(m0.tl?1:0)}
          return JSON.stringify({d1:d1,d2:d2,d3:d3,d4:d4,d5:d5,d6:d6,kd:kd,lix:lix,enc:enc,tops0:tops0,tops1:tops1,stT:S.st.t,pisca:seq2,errs:__errs});
          """#)
        for k in ["d1", "d3", "d4", "d5"] { XCTAssertGreaterThan(abs((o[k] as? Double) ?? 0), 20, "\(k): a cuba/cooktop tem que andar no arrasto · \(o[k] ?? "")") }
        XCTAssertLessThan((o["d2"] as? Double) ?? 0, -20, "2º arrasto pra esquerda também anda")
        if let d6 = o["d6"] as? Double { XCTAssertGreaterThan(d6, 20, "depois do pointercancel o arrasto segue pelo toque") }
        let kd = o["kd"] as? [String: Any]
        XCTAssertEqual(kd?["w"] as? Double, 485, "125+120+120+120 = 485 no OK · \(kd ?? [:])")
        XCTAssertEqual(kd?["wsDuranteOk"] as? Bool, true, "enquanto digita a pedra não muda")
        XCTAssertEqual(kd?["cxDurante"] as? Bool, true, "enquanto digita a cuba não é empurrada")
        let lix = o["lix"] as? [String: Any]
        XCTAssertEqual(lix?["n"] as? Int, 5); XCTAssertEqual(lix?["b"] as? Double, 0); XCTAssertGreaterThanOrEqual((lix?["caixas"] as? Int) ?? 0, 3, "lixeira aparece no 3D")
        let enc = o["enc"] as? [String: Any]
        XCTAssertLessThanOrEqual((enc?["stFim"] as? Double) ?? 9e9, 2400, "pedra dentro da parede encolhida · \(enc ?? [:])")
        XCTAssertLessThanOrEqual((enc?["lixFim"] as? Double) ?? 9e9, 2400, "lixeira dentro da parede encolhida")
        XCTAssertEqual(o["tops1"] as? [Double], [900, 900], "módulos acompanham a pedra a 900 · \(o["tops0"] ?? "")")
        XCTAssertEqual(o["pisca"] as? [Int], [0, 0, 0, 0], "a 25 mm da parede o tamponamento automático não liga e desliga")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }
    /// Caixote de gavetas do guarda-roupa, régua do canto cego, divisor de talheres, catálogo em 3 abas e biblioteca (luminária, cama, cadeira)
    @MainActor
    func testCaixoteReguaTalheresBiblioteca() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          var find=function(n){var q=null;CATS.forEach(function(c){c.it.forEach(function(i){var t=typeof i==='number'?TPL[i]:i;if(t&&t.n===n)q=i})});return q};
          S.mods=[];S.stones=[];S.fr=[];S.W=3000;S.room='quarto';newTpl(find('1 Vão 600mm'));var m=S.mods[0];m.w=994;m.d=550;m.v[0].int=[{t:'cxg',h:830,n:4}];draw();
          var vr=vaoRanges(m)[0],vw=vr[1]-vr[0],P=partsOf(m),g=function(n){return P.filter(function(p){return p.name===n})};
          var cx={base:(g('Caixote · base superior')[0]||{}).cl,vw:vw,regua:g('Caixote · régua espaçadora 30').length,trav:g('Caixote · travessa 80').length,fr:g('Frente de gaveta (caixote)').map(function(p){return p.cl})};
          S.mods=[];newTpl(find('Balcão canto cego · cego na esquerda (porta na direita)'));var c=S.mods[0];draw();var rg=partsOf(c).filter(function(p){return p.name==='Régua espaçadora do canto'})[0];
          S.mods=[];newTpl(CATS[0].it[3]);var gv=S.mods[0];gv.v[0].dt=[0];draw();var dt=partsOf(gv).filter(function(p){return /Divisor de talheres/.test(p.name)}).length;
          catOpen();await new Promise(function(r){setTimeout(r,200)});var abas=[].slice.call(document.querySelectorAll('#catsec [data-catsec]')).map(function(b){return b.dataset.catsec}).join(',');document.getElementById('catm').hidden=true;
          S.mods=[];S.fr=[];S.H=2600;S.Hm=1;S.Wm=1;open3D();await new Promise(function(r){setTimeout(r,300)});var lu=apAdd('luminaria',0),ca=apAdd('cama',1),cd=apAdd('cadesc',0);__build();var B=__boxes(),top=function(f){return Math.round(Math.max.apply(null,B.filter(function(q){return q.fr===f.id}).map(function(q){return q.y1})))},n3=function(f){return B.filter(function(q){return q.fr===f.id}).length};document.getElementById('v3x').click();
          return JSON.stringify({cx:cx,regua:rg?rg.cw:0,dt:dt,abas:abas,lumTopo:top(lu),cama:n3(ca),cad:n3(cd),errs:__errs});
          """#)
        let cx = o["cx"] as? [String: Any]
        XCTAssertEqual(cx?["base"] as? Double, cx?["vw"] as? Double, "base superior do caixote com a largura do vão")
        XCTAssertEqual(cx?["regua"] as? Int, 2); XCTAssertEqual(cx?["trav"] as? Int, 4)
        XCTAssertEqual((cx?["fr"] as? [Double])?.count, 4, "4 frentes")
        XCTAssertEqual(o["regua"] as? Double, 40, "canto cego nasce com régua de 40")
        XCTAssertGreaterThan(o["dt"] as? Int ?? 0, 5, "divisor de talheres dentro da gaveta")
        XCTAssertEqual(o["abas"] as? String, "mod,ele,bib", "catálogo em 3 abas")
        XCTAssertEqual(o["lumTopo"] as? Int, 2600, "pendente pendurado do teto")
        XCTAssertGreaterThan(o["cama"] as? Int ?? 0, 5); XCTAssertGreaterThan(o["cad"] as? Int ?? 0, 5)
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testDescontoZeroTamponamentoPedraCooktopModo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          var tp=function(c){return CATS.filter(function(q){return q.id===c})[0].it.filter(function(i){return /2 portas/.test(i.n)})[0]};
          S.mods=[];S.stones=[];S.fr=[];S.W=3000;var sd=STD();
          sd.gDesc=0;SPC={};newTpl(CATS[0].it[3]);var g=S.mods[0];g.v.forEach(function(v){v.px='g';v.cava=false});var semDesc=partsOf(g).filter(function(p){return p.pxD}).length;sd.gDesc=35;
          S.mods=[];newTpl(tp('inf'));newTpl(tp('sup'));var mi=S.mods[0],ms=S.mods[1];mi.latPiso=false;mi.latFora=false;/* tamponamento passando embaixo: módulo com o rodapé por baixo */mi.x=600;ms.x=600;mi.tl=ms.tl=true;ms.tlA='full';
          var T=function(m){return partsOf(m).filter(function(p){return p.name==='Tamponamento esquerdo'})[0].h};var i0=T(mi),s0=T(ms);
          sd.tiBx=25;sd.tsCm=20;stdApplyAll(true);SPC={};var i1=T(mi),s1=T(ms);
          sd.stAvF=30;addStone();var st=S.stones[0];var dEsp=Math.round(zoOf(mi)+fBack(mi)+mi.d+30),pd=st.d;
          sd.tiBx=0;sd.tsCm=0;sd.stAvF=40;stdApplyAll(true);
          var bx=document.createElement('button');bx.dataset.additem='cook';document.body.appendChild(bx);bx.click();var ck=document.getElementById('ckpk');var perg=!!ck&&!ck.hidden;
          document.querySelector('#ckpk [data-cknb="2"]').click();document.querySelector('#ckpk [data-ckm="g2f"]').click();var it=st.items.filter(function(i){return i.k==='cook'})[0];
          open3D();await new Promise(function(r){setTimeout(r,300)});var modos=document.querySelectorAll('#t3mode [data-t3m]').length;document.getElementById('v3x').click();
          return JSON.stringify({semDesc:semDesc,ti:i1-i0,ts:s1-s0,pd:pd,pdEsp:dEsp,perg:perg,ck:it?[it.w,it.d,cookNb(it)]:[],modos:modos,errs:__errs});
          """#)
        XCTAssertEqual(o["semDesc"] as? Int, 0, "desconto 0 = sem desconto do perfil")
        XCTAssertEqual(o["ti"] as? Double, 25, "tamponamento inferior passa 25 embaixo")
        XCTAssertEqual(o["ts"] as? Double, 20, "tamponamento superior passa 20 em cima")
        XCTAssertEqual(o["pd"] as? Int, o["pdEsp"] as? Int, "pedra = frente do armário + avanço do Ajustes")
        XCTAssertEqual(o["perg"] as? Bool, true, "＋ Cooktop pergunta quantas bocas")
        XCTAssertEqual(o["ck"] as? [Int], [302, 514, 2], "cooktop 2 bocas com medida real")
        XCTAssertEqual(o["modos"] as? Int, 3, "barra Toque: Normal · Módulo 2D · Tamanho")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPedrasNo3DMuretaComPedra() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.W=3600;for(var i=0;i<3;i++){newTpl(CATS[0].it[0]);S.mods[i].x=600+i*900}addStone();draw();open3D();await new Promise(function(r){setTimeout(r,400)});
          document.getElementById('v3pd').click();var bts=[].map.call(document.querySelectorAll('#pd3 [data-pda]'),function(b){return b.dataset.pda}).join(',');
          document.querySelector('#pd3 [data-pda="mur"]').click();await new Promise(function(r){setTimeout(r,1200)});
          var a=S.isl[0],st=S.stones[0];__build();var B=__boxes().filter(function(q){return q.isl===a.id});var top=Math.round(Math.max.apply(null,B.map(function(q){return q.y1})));
          __islApi.set(a,'tw',450);__islApi.fix(a);var tw=__islApi.get(a,'tw');var mdf=__islApi.lines(a).length;
          document.getElementById('v3x').click();
          return JSON.stringify({bts:bts,k:a.k,cola:a.x===st.x&&a.w===st.w&&a.z===st.d,top:top,tw:tw,errs:__errs});
          """#)
        XCTAssertEqual(o["bts"] as? String, "base,mur,ilha,pen,cook,cuba,aj", "🪨 Pedras com tudo de pedra")
        XCTAssertEqual(o["k"] as? String, "mur"); XCTAssertEqual(o["cola"] as? Bool, true, "mureta na frente da pedra da pia")
        XCTAssertEqual(o["top"] as? Int, 1100, "1,10 m com a pedra")
        XCTAssertEqual(o["tw"] as? Int, 450, "largura da pedra em cima editável")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testCantoEncostaPlantaEmAnguloComPedraECooktopPorCimaDo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;var W=function(ms){return new Promise(function(r){setTimeout(r,ms||300)})};
          S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.W=3200;for(var i=0;i<2;i++){newTpl(CATS[0].it[0]);S.mods[i].x=900+i*900}addStone();S.st.x=0;S.st.w=S.W;S.m=S.mods[1];mkCorner('d');draw();
          var row=S.mods.filter(function(m){return !m.sup&&!m.wing}),bad=0;row.forEach(function(a,i){row.forEach(function(c,j){if(j<=i)return;var A=extOf(a),C=extOf(c);if(A[0]<C[1]-0.5&&C[0]<A[1]-0.5)bad++})});
          var c=S.mods.filter(function(m){return m.corner})[0],mold=partsOf(c).some(function(p){return /Moldura/.test(p.name)});
          S.mods=[];S.stones=[];for(var k=0;k<2;k++){newTpl(CATS[0].it[0]);S.mods[k].x=300+k*900}addStone();S.st.cor='#123456';S.m=S.mods[0];draw();panel();
          var f=document.getElementById('plfoc');if(f){f.click();await W(600);document.getElementById('v3x').click();await W()}if(!PLV)document.getElementById('plv').click();await W();if(!PLANG)document.getElementById('pla').click();await W();
          var g=document.getElementById('plx'),pedra=g?[].filter.call(g.querySelectorAll('polygon'),function(p){return /rgb\(1[0-9],\s?[3-5][0-9],/.test(p.getAttribute('fill')||'')}).length:-1;document.getElementById('plv').click();await W();
          open3D();await W();document.getElementById('v3pd').click();await W(200);document.querySelector('#pd3 [data-pda="cook"]').click();await W(200);var ck=document.getElementById('ckpk'),topo=+getComputedStyle(ck).zIndex>+getComputedStyle(document.getElementById('v3')).zIndex;document.getElementById('v3x').click();ck.hidden=true;
          var cb=document.createElement('button');cb.dataset.additem='cuba';document.body.appendChild(cb);cb.click();var cbx=document.getElementById('cbpk'),cbn=cbx.querySelectorAll('[data-cbm]').length,cbf=cbx.querySelectorAll('[data-cbm] img').length;cbx.querySelector('[data-cbm]').click();
          return JSON.stringify({bad:bad,mold:mold,pedra:pedra,topo:topo,cbn:cbn,cbf:cbf,cubas:S.stones[0].items.filter(function(i){return i.k==='cuba'}).length,errs:__errs});
          """#)
        XCTAssertEqual(o["bad"] as? Int, 0, "canto novo: os módulos encostam do lado, sem entrar um no outro")
        XCTAssertEqual(o["mold"] as? Bool, false, "balcão de canto embaixo da pedra sem moldura deitada em cima")
        XCTAssertGreaterThan(o["pedra"] as? Int ?? 0, 0, "planta em ângulo mostra a pedra depois do só o módulo")
        XCTAssertEqual(o["topo"] as? Bool, true, "quadro do cooktop por cima do 3D")
        XCTAssertGreaterThan(o["cbn"] as? Int ?? 0, 3, "＋ Cuba mostra os modelos"); XCTAssertEqual(o["cbf"] as? Int, o["cbn"] as? Int, "cada cuba com foto"); XCTAssertEqual(o["cubas"] as? Int, 1, "cuba escolhida entra na pedra")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testMedidasDaObraTravadasComSenhaTomadaEEsquadro() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;delete PR.obraPw;var W=function(ms){return new Promise(function(r){setTimeout(r,ms||200)})};
          S.mods=[];S.stones=[];S.fr=[];S.ops=[];S.W=3200;S.H=2600;S.Hm=1;S.Wm=1;S.wall={};S.obra=null;for(var i=0;i<2;i++){newTpl(CATS[0].it[0]);S.mods[i].x=300+i*900}addStone();var st=S.stones[0];st.t=860;st.e=30;var tm=apAdd('eletrica',0);tm.x=1000;tm.b=1100;S.m=S.mods[0];draw();
          S.tab=9;panel();document.querySelector('#bd [data-oblk]').click();await W();var bx=document.getElementById('obrapw');bx.querySelector('#obrapw1').value='1234';bx.querySelector('#obrapw2').value='1234';bx.querySelector('[data-obok]').click();await W();
          S.W=3000;st.w=1000;tm.x=1500;draw();var travou=[S.W,st.w===S.obra.snap.stones[0].w,tm.x];
          S.tab=9;panel();document.querySelector('#bd [data-obun]').click();await W();bx.querySelector('#obrapw1').value='0000';bx.querySelector('[data-obok]').click();await W();var errada=obraOn();bx.querySelector('#obrapw1').value='1234';bx.querySelector('[data-obok]').click();await W();var certa=!obraOn();
          S.tab=7;panel();var inf=(document.querySelector('#bd [data-ptinfo]')||{}).textContent||'';
          S.wall={L:{a:88,len:2000}};var sq=sqDiff().L;
          return JSON.stringify({travou:travou,errada:errada,certa:certa,info:/até o teto/.test(inf)&&/Da pedra/.test(inf),fecha:sq?sq.fecha:null,errs:__errs});
          """#)
        XCTAssertEqual(o["travou"] as? [AnyHashable], [3200, true, 1000] as [AnyHashable], "medidas da obra travadas voltam")
        XCTAssertEqual(o["errada"] as? Bool, true, "senha errada não destrava"); XCTAssertEqual(o["certa"] as? Bool, true, "senha certa destrava")
        XCTAssertEqual(o["info"] as? Bool, true, "tomada mostra até o teto e da pedra")
        XCTAssertEqual(o["fecha"] as? Int, 70, "lateral a 88° com 2 m fecha 70 mm")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testMedidasCruzadasTrenaNoCampoDetalhamentoEAereoPelaPedra() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;var W=function(ms){return new Promise(function(r){setTimeout(r,ms||200)})};
          S.mods=[];S.stones=[];S.fr=[];S.ops=[];S.W=3200;S.H=2600;S.Hm=1;S.Wm=1;S.wall={};S.obra=null;S.amb={};for(var i=0;i<2;i++){newTpl(CATS[0].it[0]);S.mods[i].x=300+i*900}addStone();var st=S.stones[0];st.t=860;st.e=30;S.m=S.mods[0];draw();
          newMod(true);var ms=S.mods[S.mods.length-1];ms.x=300;supByStone(ms);
          S.tab=9;panel();stdOpen(0,'obra');var wf=document.querySelector('#cfgobra [data-amx="wf"]');wf.focus();wf.dispatchEvent(new FocusEvent('focusin',{bubbles:true}));window.arqueLaser(3212.4);await W();var q=sqDiff();
          S.ops.push({id:7001,t:'porta',w:800,h:2100,x:2300,b:0});panel();var hr=document.querySelector('#bd [data-opf="7001|hR"]');hr.value='2112';hr.dispatchEvent(new Event('change',{bubbles:true}));await W();
          var tm=apAdd('eletrica',0);tm.x=500;tm.b=400;draw();open3D();await W(300);document.getElementById('v3det').click();await W();var det3_=!!document.querySelector('#det3svg line[marker-end]');document.querySelector('#det3bar [data-d3l]').click();await W();var tx=document.getElementById('detbx').textContent;document.getElementById('detbx').hidden=true;document.getElementById('v3x').click();
          return JSON.stringify({det3:det3_,supB:ms.b,wf:S.amb.wf,abre:q.L.fecha<0&&q.R.fecha<0,hR:S.ops[0].hR,det:tx.indexOf('furo no fundo')>=0&&tx.indexOf('sobra')>=0&&tx.indexOf('Da pedra até o teto')>=0,errs:__errs});
          """#)
        XCTAssertEqual(o["supB"] as? Int, 1590, "aéreo 700 acima da pedra (860 + 30 + 700)")
        XCTAssertEqual(o["wf"] as? Int, 3212, "trena cai no campo tocado")
        XCTAssertEqual(o["abre"] as? Bool, true, "frente 12 mm maior: as duas laterais abrem")
        XCTAssertEqual(o["hR"] as? Int, 2112, "porta com altura diferente na direita")
        XCTAssertEqual(o["det3"] as? Bool, true, "📏 Detalhamento desenha as cotas em cima do 3D")
        XCTAssertEqual(o["det"] as? Bool, true, "detalhamento com furo da tomada, sobra até o teto e pedra até o teto") // 📋 lista escrita
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testPeDireitoNaoMedidoNaoInventaMedidaAteOTeto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          var z=snapState();z.H=2600;z.W=3200;delete z.Hm;delete z.Wm;loadState(z);var novo=S.Hm===false&&S.Wm===false;
          S.room='sala';S.mods=[];S.stones=[];S.rp=[];draw();newMod(false);var m=S.mods[S.mods.length-1];m.x=600;m.w=1180;m.b=475;m.h=300;S.m=m;draw();
          var lab=function(){return [].map.call(document.querySelectorAll('[data-q="mt"]'),function(e){return e.textContent}).join('|')};var l0=lab();
          TRN=4;TRT='reb';var n0=S.rp.length;trCreate();var bloqueou=S.rp.length===n0;
          stdOpen(0,'obra');var hi=document.querySelector('[data-pf="F|h"]');hi.value='3150';hi.dispatchEvent(new Event('change',{bubbles:true}));draw();var l1=lab();
          var sv=snapState();loadState(z);var vNovo=S.Hm;loadState(sv);
          return JSON.stringify({novo:novo,l0:l0,bloqueou:bloqueou,l1:l1,salvo:!!S.Hm&&S.H===3150,vNovo:vNovo,errs:__errs});
          """#)
        XCTAssertEqual(o["novo"] as? Bool, true, "projeto novo: pé-direito e largura não medidos")
        XCTAssertEqual(o["l0"] as? String, "⚠ pé-direito não medido", "sem medir não mostra número até o teto")
        XCTAssertEqual(o["bloqueou"] as? Bool, true, "placas até o teto não saem do valor padrão")
        XCTAssertEqual(o["l1"] as? String, "2375 até o teto (pé-direito 3150)", "medido 3150: 3150 − 475 − 300")
        XCTAssertEqual(o["salvo"] as? Bool, true, "salvo e aberto continua medido")
        XCTAssertEqual(o["vNovo"] as? Bool, false, "projeto novo volta pra não medido")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testDistanciasDoModuloTocaEDigitaELimiteDoAereo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;S.mods=[];S.stones=[];S.fr=[];S.W=3200;S.H=2600;S.Hm=1;S.Wm=1;S.wall={};STD().supPedra=700;
          for(var i=0;i<2;i++){newTpl(CATS[0].it[0]);S.mods[i].x=300+i*900}addStone();var st=S.stones[0];st.t=870;st.e=30;newMod(true);var a=S.mods[2];a.x=300;supByStone(a);S.m=a;draw();
          var temRot=!!document.querySelector('#svg text[data-q="mp"]')&&!!document.querySelector('#svg text[data-q="mt"]');
          modGapSet(a,'mp',750);var b750=a.b;modGapSet(a,'mp',600);var lim=a.b;modGapSet(a,'mt',300);var teto=Math.round(2600-a.b-a.h-fgh());var x0=a.x,g=modGaps(a).esq;modGapSet(a,'ml',g+50);var andou=Math.round(a.x-x0);
          return JSON.stringify({temRot:temRot,b750:b750,lim:lim,teto:teto,andou:andou,errs:__errs});
          """#)
        XCTAssertEqual(o["temRot"] as? Bool, true, "mostra da pedra e até o teto no desenho")
        XCTAssertEqual(o["b750"] as? Int, 1650, "750 da pedra (pedra em cima a 900)")
        XCTAssertEqual(o["lim"] as? Int, 1600, "não desce abaixo de 700 da pedra")
        XCTAssertEqual(o["teto"] as? Int, 300, "até o teto 300")
        XCTAssertEqual(o["andou"] as? Int, 50, "distância da esquerda move o módulo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testRodapeDoCantoNaMesmaCorDosOutros() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          demoScene();S.m=null;draw();open3D();await new Promise(function(q){setTimeout(q,400)});__build();
          /* o rodapé (pedestal) do módulo de canto sai igual ao dos outros módulos, não na cor de madeira crua */
          var B=__boxes(),ci=-1;S.mods.forEach(function(m,i){if(m.corner&&!m.sup&&ci<0)ci=i});R.canto=ci>=0;
          var rc=B.filter(function(b){return String(b.nm).indexOf(ci+':Rodapé')===0}),ro=B.filter(function(b){var k=+String(b.nm).split(':')[0];return k!==ci&&/^\d+:Rodapé/.test(String(b.nm))&&S.mods[k]&&!S.mods[k].sup&&!S.mods[k].corner});
          var kd=function(b){return /traseiro/.test(String(b.nm))?'t':'f'},igual=function(rc,ro){return ['f','t'].every(function(k){var cs={};ro.filter(function(b){return kd(b)===k}).forEach(function(b){cs[String(b.c)]=1});var cc=rc.filter(function(b){return kd(b)===k});return cc.length>0&&cc.every(function(b){return cs[String(b.c)]})})};R.tem=rc.length>0&&ro.length>0;R.igual=R.tem&&igual(rc,ro);R.semCru=rc.every(function(b){return String(b.c)!=='205,185,143'});
          /* com a caixa pintada continua igual aos outros */
          var gi=MAT.filter(function(c){return /gianduia/i.test(c.id)})[0]||MAT[0];S.mods.forEach(function(m){m.cor=gi.hex;m.corId=gi.id;m.corF=gi.hex;m.corFId=gi.id});draw();__build();B=__boxes();
          rc=B.filter(function(b){return String(b.nm).indexOf(ci+':Rodapé')===0});ro=B.filter(function(b){var k=+String(b.nm).split(':')[0];return k!==ci&&/^\d+:Rodapé/.test(String(b.nm))&&S.mods[k]&&!S.mods[k].sup&&!S.mods[k].corner});
          R.pintado=rc.length>0&&ro.length>0&&igual(rc,ro);
          document.getElementById('v3x').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["canto"] as? Bool, true, "a cozinha de exemplo tem módulo de canto")
        XCTAssertEqual(o["tem"] as? Bool, true, "rodapé do canto e dos outros no 3D")
        XCTAssertEqual(o["igual"] as? Bool, true, "rodapé do canto na mesma cor dos outros")
        XCTAssertEqual(o["semCru"] as? Bool, true, "rodapé do canto não sai cor de madeira crua")
        XCTAssertEqual(o["pintado"] as? Bool, true, "com a caixa pintada continua igual aos outros")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testLateraisAtePisoRodapeEntreElasETudoNaCorPorFora() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};STD().latPiso='sim';/* este teste confere o jeito "até o piso" (o padrão agora é em cima do rodapé) */
          S.mods=[];S.fr=[];S.stones=[];S.rp=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          var gi=MAT.filter(function(c){return /gianduia/i.test(c.id)})[0]||MAT[0],cor=function(q){q.corF=gi.hex;q.corFId=gi.id;q.corFN=matLabel(gi)};
          newTpl(tpl('Balcão 2 portas'));try{soloOff()}catch(_){}var m=S.mods[0];m.x=1200;cor(m);draw();
          /* módulo de baixo nasce com as laterais até o piso e o rodapé entre elas (não fica "flutuando" num caixote) */
          R.nasce=!!m.latPiso&&!!m.latFora;var P=partsOf(m),pn=function(n){return P.filter(function(p){return p.name===n})[0]};
          var le=pn('Lateral esquerda');R.latChao=Math.abs(le.y+le.h-m.h)<.6;R.tampChao=Math.abs(pn('Tamponamento esquerdo').h-m.h)<.6&&Math.abs(pn('Tamponamento direito').h-m.h)<.6;
          var rf=pn('Rodapé (pedestal)');R.rodEntre=Math.abs(rf.x-m.esp)<.6&&Math.abs(rf.w-(m.w-2*m.esp))<.6;R.semRodLat=!P.some(function(p){return /^Rodapé lateral/.test(p.name)});
          /* aéreo continua igual */
          newTpl(4);try{soloOff()}catch(_){}var a=S.mods[1];a.x=1200;cor(a);draw();R.aereo=!a.latPiso;
          /* 3D: lateral e tamponamento no chão, rodapé da frente e o aéreo por baixo na cor de fora */
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var B=__boxes(),hx=[1,3,5].map(function(i){return parseInt(gi.hex.slice(i,i+2),16)}).join(),of=function(n){return B.filter(function(b){return String(b.nm)===n&&Array.isArray(b.c)})};
          R.chao3d=of('0:Lateral esquerda').some(function(b){return b.y0<1})&&of('0:Tamponamento esquerdo').some(function(b){return b.y0<1});
          var rod=of('0:Rodapé (pedestal)');R.rod3d=rod.length>0&&rod.some(function(b){return b.c.join()===hx})&&!rod.some(function(b){return b.c.join()==='244,242,238'||b.c.join()==='205,185,143'});
          R.aereoBaixo=of('1:Base inferior').some(function(b){return b.c.join()===hx});
          /* plano de corte: rodapé da frente e base do aéreo na chapa da cor */
          R.corteRod=cutLines(m).some(function(l){return l.names.indexOf('Rodapé (pedestal)')>=0&&l.fin==='c'});R.corteAereo=cutLines(a).some(function(l){return l.names.indexOf('Base inferior')>=0&&l.fin==='c'});
          document.getElementById('v3x').click();
          /* botão do módulo: desliga só nele; "aplicar em todos" liga em todos os de baixo */
          newTpl(tpl('Balcão 2 portas'));try{soloOff()}catch(_){}var n2=S.mods[2];n2.x=200;n2.latPiso=false;draw();
          /* a regra da base é uma só, em Ajustes: no módulo não tem mais botão; lateral aparece marcada (todo módulo tem as duas) */
          S.m=m;S.tab=0;panel();R.botao=!document.querySelector('#bd [data-latop="latPiso"]')&&!document.querySelector('#bd [data-latall]')&&!!document.querySelector('#bd [data-cfggo2]');R.lat=[].map.call(document.querySelectorAll('#bd [data-latop]'),function(b){return b.textContent}).join('|')+' '+/Tamponamento \(acabamento por fora\) é outra peça/.test(document.getElementById('bd').textContent);
          document.querySelector('#bd [data-cfggo2]').click();var c=document.querySelector('#stdm [data-std="latPiso"][data-v="nao"]');R.ajustes=!!c&&/Lateral até a base/.test(c.textContent);c.click();await new Promise(function(r){setTimeout(r,60)});R.desliga=STD().latPiso==='nao'&&S.mods.filter(function(q){return !q.sup}).every(function(q){return !q.latPiso});
          var Lb=partsOf(m).filter(function(p){return p.name==='Lateral esquerda'})[0];R.sobreBase=Lb.h<m.h-100;
          c=document.querySelector('#stdm [data-std="latPiso"][data-v="sim"]');R.todos=!!c&&/descendo até o chão/.test(c.textContent);c.click();await new Promise(function(r){setTimeout(r,60)});R.ligouTodos=STD().latPiso==='sim'&&S.mods.filter(function(q){return !q.sup}).every(function(q){return q.latPiso});document.getElementById('stdm').hidden=true;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["nasce"] as? Bool, true, "módulo de baixo nasce com as laterais até o piso")
        XCTAssertEqual(o["latChao"] as? Bool, true, "lateral desce até o chão")
        XCTAssertEqual(o["tampChao"] as? Bool, true, "tamponamento desce até o chão junto")
        XCTAssertEqual(o["rodEntre"] as? Bool, true, "rodapé de lateral a lateral")
        XCTAssertEqual(o["semRodLat"] as? Bool, true, "sem rodapé lateral (a lateral faz o papel)")
        XCTAssertEqual(o["aereo"] as? Bool, true, "aéreo não muda")
        XCTAssertEqual(o["chao3d"] as? Bool, true, "3D: lateral e tamponamento no chão")
        XCTAssertEqual(o["rod3d"] as? Bool, true, "3D: rodapé da frente na cor de fora")
        XCTAssertEqual(o["aereoBaixo"] as? Bool, true, "3D: aéreo por baixo na cor de fora")
        XCTAssertEqual(o["corteRod"] as? Bool, true, "corte: rodapé da frente na chapa da cor")
        XCTAssertEqual(o["corteAereo"] as? Bool, true, "corte: base do aéreo na chapa da cor")
        XCTAssertEqual(o["botao"] as? Bool, true, "no módulo não tem mais botão de lateral até o piso: é regra dos Ajustes")
        XCTAssertEqual(o["lat"] as? String, "✓ Esquerda|✓ Direita true", "todo módulo tem as duas laterais; tamponamento é outra peça")
        XCTAssertEqual(o["ajustes"] as? Bool, true, "Ajustes: lateral até a base")
        XCTAssertEqual(o["desliga"] as? Bool, true, "em cima da base em todos os módulos de uma vez")
        XCTAssertEqual(o["sobreBase"] as? Bool, true, "a lateral para na base, não desce até o chão")
        XCTAssertEqual(o["todos"] as? Bool, true, "Ajustes: lateral descendo até o chão")
        XCTAssertEqual(o["ligouTodos"] as? Bool, true, "até o chão em todos os módulos de baixo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }
    func testAssistenteMostraAOpcaoEscolhidaEmAzul() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          /* no assistente de ajustes a opção escolhida aparece em azul (antes ficava tudo cinza) */
          wizOpen();var bg=function(e){return getComputedStyle(e).backgroundColor};
          var ref=document.createElement('button');ref.style.background='var(--acc)';document.getElementById('stdbody').appendChild(ref);var az=bg(ref);ref.remove();
          var on=document.querySelector('#stdbody .stc button.on');R.temOn=!!on;R.onAzul=!!on&&bg(on)===az;
          var off=document.querySelector('#stdbody .stc button:not(.on)');R.outraCinza=!!off&&bg(off)!==az;
          var cx=STD().caixa==='fora'?'dentro':'fora';document.querySelector('#stdbody [data-std="caixa"][data-v="'+cx+'"]').click();
          R.trocou=bg(document.querySelector('#stdbody [data-std="caixa"][data-v="'+cx+'"]'))===az&&bg(document.querySelector('#stdbody [data-std="caixa"]:not([data-v="'+cx+'"])'))!==az;
          var ok=true,n=0;for(var i=0;i<10;i++){window.WIZ=i;stdRe();[].slice.call(document.querySelectorAll('#stdbody .stc')).forEach(function(g){var bs=[].slice.call(g.querySelectorAll('button'));var a=bs.filter(function(b){return bg(b)===az}).length,c=g.querySelectorAll('button.on').length;n++;if(a!==c||getComputedStyle(g).display!=='flex')ok=false})}
          R.todos=ok;R.grupos=n;window.WIZ=null;document.getElementById('stdx').click();R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["temOn"] as? Bool, true, "o passo 1 tem uma opção escolhida")
        XCTAssertEqual(o["onAzul"] as? Bool, true, "a opção escolhida aparece em azul")
        XCTAssertEqual(o["outraCinza"] as? Bool, true, "a outra opção fica sem destaque")
        XCTAssertEqual(o["trocou"] as? Bool, true, "tocar na outra opção passa o azul pra ela")
        XCTAssertEqual(o["todos"] as? Bool, true, "em todos os 10 passos só a escolhida fica em azul")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testNichoDaParedeDoLadoNaoEntraNoAereoESemNumeracao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=2960;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(){};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return JSON.parse(JSON.stringify(it))};
          /* cabeçalho e abas na ordem do trabalho, sem os números */
          var b3=document.getElementById('b3d'),tb=document.querySelector('#tabs [data-t]');R.semNumBotao=!!b3&&!b3.hasAttribute('data-step')&&getComputedStyle(b3,'::before').content==='none';R.semNumAba=!!tb&&getComputedStyle(tb,'::before').content==='none';
          /* aéreos na parede do fundo, do canto até o fim */
          for(var i=0;i<3;i++){newTpl(tpl('Aéreo 2 portas'))}S.mods.forEach(function(m,i){m.w=985;m.x=5+i*985;m.b=1750});draw();
          var n={x:1300,b:1840,w:900,h:350,d:300,sup:true,div:[],shv:[],v:[{k:'free',n:1}],tl:true,tr:true,fundo:true,wing:'e'};defs(n);n.b=1840;n.h=350;n.d=300;n.w=900;S.mods.push(n);S.m=n;draw();panel();
          var modHit=window.modHit||function(m){return S.mods.some(function(o){return o!==m&&modOv(m,o)})};var noInside=window.noInside||function(){return false};R.longeLivre=!modHit(n);
          /* no canto: o nicho da parede esquerda entraria no aéreo do fundo */
          n.x=0;R.cantoBate=modHit(n);n.x=1300;
          /* pelo campo "Distância da parede do fundo": não deixa entrar */
          setv('x',100);R.campoNaoEntra=!modHit(n);R.campoX=n.x;
          /* arrastando (2D/3D): encosta ou pula pro lado livre, nunca fica dentro */
          var st={};noInside(n,st);n.x=150;var bateu=noInside(n,st);R.arrasteAvisou=bateu;R.arrasteFora=!modHit(n);
          /* trocar pra parede do fundo: lá não cabe (aéreos do canto ao fim), então não troca */
          n.x=1300;var bf=[].slice.call(document.querySelectorAll('[data-wing]')).filter(function(b){return b.dataset.wing==='0'})[0];if(bf)bf.click();R.ficouNaLateral=n.wing==='e'&&!modHit(n);
          /* 2D: o nicho da parede do lado aparece marcado (não parece estar dentro do aéreo) */
          draw();R.etiqueta=!!document.querySelector('#svg [data-wingtag="e"]');
          /* 2D: arrastar um balcão por cima do vizinho: encosta nele, não entra */
          S.mods=[];draw();newTpl(tpl('Balcão 2 portas'));newTpl(tpl('Balcão 2 portas'));var a=S.mods[0],c=S.mods[1];a.x=5;c.x=1400;a.lock=false;c.lock=false;S.m=a;draw();var ra=document.querySelector('#svg rect[data-mi="0"]'),rc=ra.getBoundingClientRect(),kpx=rc.width/a.w;
          var ev=function(tp,x,y,el){(el||document.getElementById('svg')).dispatchEvent(new PointerEvent(tp,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:7,pointerType:'mouse',button:0,buttons:tp==='pointerup'?0:1,isPrimary:true}))};
          var x0=rc.left+rc.width/2,y0=rc.top+rc.height/2;ev('pointerdown',x0,y0,ra);for(var k=1;k<=10;k++)ev('pointermove',x0+k*(700*kpx/10),y0);ev('pointerup',x0+700*kpx,y0);
          R.balcaoMexeu=a.x>300;R.balcaoFora=!(a.x<c.x+c.w-1&&c.x<a.x+a.w-1);R.balcaoX=a.x;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semNumBotao"] as? Bool, true, "botões do cabeçalho sem o número")
        XCTAssertEqual(o["semNumAba"] as? Bool, true, "abas sem o número")
        XCTAssertEqual(o["longeLivre"] as? Bool, true, "nicho da parede esquerda longe do canto não bate em nada")
        XCTAssertEqual(o["cantoBate"] as? Bool, true, "no canto ele entraria no aéreo do fundo: a regra enxerga")
        XCTAssertEqual(o["campoX"] as? Int, 1300, "pelo campo não deixa ele entrar no aéreo do canto")
        XCTAssertEqual(o["arrasteAvisou"] as? Bool, true, "arrastando pra dentro do aéreo: encosta ou pula pro lado")
        XCTAssertEqual(o["arrasteFora"] as? Bool, true, "depois de arrastar ele não fica dentro de nada")
        XCTAssertEqual(o["ficouNaLateral"] as? Bool, true, "trocar pra parede do fundo cheia não joga ele dentro dos aéreos")
        XCTAssertEqual(o["etiqueta"] as? Bool, true, "no 2D o nicho da parede do lado aparece com contorno tracejado")
        XCTAssertEqual(o["balcaoMexeu"] as? Bool, true, "o balcão foi arrastado")
        XCTAssertEqual(o["balcaoFora"] as? Bool, true, "arrastado contra o vizinho ele encosta, não entra")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testArrastarNo3DSoSegurandoBaseNoChaoESemSumir() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(){};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return JSON.parse(JSON.stringify(it))};
          ['Balcão 2 portas','Balcão 2 portas','Aéreo 2 portas','Aéreo 2 portas'].forEach(function(n){newTpl(tpl(n))});S.mods.forEach(function(m){m.lock=false});S.m=S.mods[0];draw();panel();
          open3D();await new Promise(function(r){setTimeout(r,300)});__cam(0.25,0.3,1);__build();var cv=document.querySelector('#v3 canvas'),M_=document.getElementById('v3');
          var ev=function(tp,x,y,el){(el||cv).dispatchEvent(new PointerEvent(tp,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:9,pointerType:'touch',button:0,buttons:tp==='pointerup'?0:1,isPrimary:true}))};
          var ctr=function(i){var bb=null;__boxes().forEach(function(q){if(String(q.nm||'').indexOf(i+':')!==0||/Rodapé|Base inferior/.test(q.nm))return;/* rodapé e base contínuos passam por baixo dos vizinhos: não contam pro meio do móvel */if(!bb)bb={x0:q.x0,x1:q.x1,y0:q.y0,y1:q.y1,z0:q.z0,z1:q.z1};else{bb.x0=Math.min(bb.x0,q.x0);bb.x1=Math.max(bb.x1,q.x1);bb.y0=Math.min(bb.y0,q.y0);bb.y1=Math.max(bb.y1,q.y1);bb.z1=Math.max(bb.z1,q.z1)}});var p=__p3((bb.x0+bb.x1)/2,(bb.y0+bb.y1)/2,bb.z1),rc=cv.getBoundingClientRect();return [rc.left+p[0],rc.top+p[1]]};
          var drag=async function(i,dx,dy,hold){__build();var c=ctr(i);ev('pointerdown',c[0],c[1]);if(hold)await new Promise(function(r){setTimeout(r,420)});for(var s=1;s<=10;s++)ev('pointermove',c[0]+dx*s/10,c[1]+dy*s/10,s>1?M_:cv);ev('pointerup',c[0]+dx,c[1]+dy,M_);await new Promise(function(r){setTimeout(r,40)})};
          /* arrastar logo de cara em cima do móvel: gira a vista, o móvel fica onde estava */
          var a=S.mods[0],x0=a.x;await drag(0,250,0,false);R.rapidoNaoMove=a.x===x0&&a.b===0;
          /* segurando um instante e arrastando: move; o balcão continua no chão */
          await drag(0,250,0,true);R.seguraMove=a.x!==x0;R.noChao=a.b===0;await drag(1,-200,-120,true);R.noChao2=S.mods[1].b===0;
          /* aéreo puxado pra baixo: para em cima do balcão, não entra nele nem pula de lado */
          var u=S.mods[3],ux=u.x;await drag(3,0,260,true);var mh_=window.modHit||function(m){return S.mods.some(function(o){return o!==m&&o.b<m.b+m.h-1&&m.b<o.b+o.h-1&&o.x<m.x+m.w-1&&m.x<o.x+o.w-1})};R.aereoNaoEntra=!mh_(u);R.todos=S.mods.length===4&&S.mods.every(function(m){return !mh_(m)});
          try{document.getElementById('v3x').click()}catch(_){}R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["rapidoNaoMove"] as? Bool, true, "arrastar logo de cara em cima do móvel gira a vista e não leva o móvel")
        XCTAssertEqual(o["seguraMove"] as? Bool, true, "segurando um instante e arrastando o móvel muda de lugar")
        XCTAssertEqual(o["noChao"] as? Bool, true, "balcão arrastado continua no chão")
        XCTAssertEqual(o["noChao2"] as? Bool, true, "balcão arrastado na diagonal continua no chão (não flutua)")
        XCTAssertEqual(o["aereoNaoEntra"] as? Bool, true, "aéreo puxado pra baixo para em cima do balcão")
        XCTAssertEqual(o["todos"] as? Bool, true, "nenhum módulo sumiu e nenhum ficou dentro de outro")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testTamanhoDoModuloInteiroNo3DAoVivoSemFurarAPedra() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;STD().latPiso='sim';/* confere o jeito "até o piso" (o padrão agora é em cima do rodapé) */S.env='cozinha';S.room='cozinha';S.W=2400;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={vivo:[]};window.toast=function(){};
          var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n==='Módulo vazio (montar do zero)'&&!t.sup&&!it)it=t})});newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];m.x=300;
          S.stones=[{id:1,x:300,w:1500,d:600,t:m.h,e:30,shape:'reta',items:[]}];S.st=S.stones[0];draw();R.m0=[m.x,m.w,m.h,m.d,m.b];var m0w_=m.w;
          open3D();await new Promise(function(r){setTimeout(r,300)});__cam(0.3,0.3,1.2);fx3api.open({k:'mod',mi:0});await new Promise(function(r){setTimeout(r,200)});
          var cv=document.querySelector('#v3 canvas');var drag=async function(k,px){var h=document.querySelector('[data-ah="'+k+'"]');if(!h)return 'sem '+k;var r=h.getBoundingClientRect(),x=r.left+16,y=r.top+16,pe=function(t,el,X,Y){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:X,clientY:Y,pointerId:5,pointerType:'touch',isPrimary:true,buttons:t==='pointerup'?0:1}))};
            var vx=0,vy=0;var hs=[].slice.call(document.querySelectorAll('[data-ah]'));pe('pointerdown',h,x,y);for(var i=1;i<=6;i++){pe('pointermove',cv,x+px[0]*i/6,y+px[1]*i/6);await new Promise(function(r){requestAnimationFrame(r)});R.vivo.push(m.w)}pe('pointerup',cv,x+px[0],y+px[1]);await new Promise(function(r){setTimeout(r,100)});return [m.x,m.w,m.h,m.d,m.b].join(',')};
          R.xp=await drag('xp',[120,0]);fx3api.open({k:'mod',mi:0});await new Promise(function(r){setTimeout(r,150)});R.yp=await drag('yp',[0,-60]);fx3api.open({k:'mod',mi:0});await new Promise(function(r){setTimeout(r,150)});R.zp=await drag('zp',[40,40]);
          R.aoVivo=R.vivo.slice(0,6).filter(function(v,i,a){return a.indexOf(v)===i}).length>=3;R.cresceu=+R.xp.split(',')[1]>m0w_;R.naoFurouPedra=m.h<=820&&m.x===330;R.fundura=m.d<=560;R.portasLaterais=partsOf(m).some(function(p){return /^Lateral direita/.test(p.name)&&p.cl===805});R.partes=partsOf(m).filter(function(p){return /^(Base|Lateral|Fundo|Travessa|Teto)/.test(p.name)}).map(function(p){return p.name+':'+p.cl+'x'+p.cw}).join(' | ');R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["aoVivo"] as? Bool, true, "a largura do módulo inteiro muda enquanto puxa a seta (ao vivo)")
        XCTAssertEqual(o["cresceu"] as? Bool, true, "puxando a seta da direita o módulo inteiro cresce")
        XCTAssertEqual(o["naoFurouPedra"] as? Bool, true, "puxando a altura ele para na pedra e não pula de lugar")
        XCTAssertEqual(o["fundura"] as? Bool, true, "a fundura para embaixo da pedra (com a pingadeira)")
        XCTAssertEqual(o["portasLaterais"] as? Bool, true, "laterais acompanham o módulo inteiro")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Planta (vista de cima): arrasta o módulo até o fim da pedra e ele fica lá (não volta pro vizinho);
    /// bolinhas azuis esticam/encolhem o módulo e param encostadas no vizinho.
    func testPlantaArrastaAteOFimEEsticaPelasBolinhas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;S.RD=3030;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(){};
          S.stones=[{id:1,x:0,w:3170,d:600,t:820,e:30,shape:'Le',lenA:2430,widA:600,items:[]}];S.st=S.stones[0];
          addWing('e');var a=S.mods[0];a.w=900;addWing('e');var b=S.mods[1];b.w=1510;a.x=600;b.x=1525;a.lock=false;b.lock=false;draw();
          document.getElementById('plv').click();draw();
          var ev=function(tp,X,Y,el){(el||document.getElementById('svg')).dispatchEvent(new PointerEvent(tp,{bubbles:true,cancelable:true,clientX:X,clientY:Y,pointerId:3,pointerType:'touch',isPrimary:true,buttons:tp==='pointerup'?0:1}))};
          var dragEl=function(el,dy,k){var rc=el.getBoundingClientRect(),x0=rc.left+rc.width/2,y0=rc.top+rc.height/2;ev('pointerdown',x0,y0,el);for(var i=1;i<=8;i++)ev('pointermove',x0,y0+i*(dy*k/8));ev('pointerup',x0,y0+dy*k)};
          var g=document.querySelector('#svg [data-pm="1"]'),k=g.getBoundingClientRect().height/b.w;
          dragEl(g,200,k);R.bFim=b.x+b.w;
          S.m=a;draw();var h=document.querySelector('#svg [data-plh="r"]');R.bolinha=!!h;if(h)dragEl(h,300,k);R.aW=a.w;R.encosta=Math.abs(a.x+a.w-b.x)<1&&!modHit(a);
          S.m=b;draw();var hl=document.querySelector('#svg [data-plh="l"]');dragEl(hl,200,k);R.bEnc=[b.x,b.w];hl=document.querySelector('#svg [data-plh="l"]');dragEl(hl,-400,k);R.bVolta=[b.x,b.w,b.x+b.w];
          R.semHit=!S.mods.some(function(o){return modHit(o)});R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["bFim"] as? Int, 3030, "arrastou até o fim da pedra: fica no fim (não volta pro vizinho)")
        XCTAssertEqual(o["bolinha"] as? Bool, true, "módulo selecionado na planta tem as bolinhas azuis pra esticar")
        XCTAssertEqual(o["aW"] as? Int, 920, "esticou pela bolinha até encostar no vizinho")
        XCTAssertEqual(o["encosta"] as? Bool, true)
        XCTAssertEqual(o["bEnc"] as? [Int], [1720, 1310], "bolinha do outro lado encolhe")
        XCTAssertEqual(o["bVolta"] as? [Int], [1520, 1510, 3030], "e estica de volta até o vizinho, sem passar")
        XCTAssertEqual(o["semHit"] as? Bool, true, "nenhum módulo entra no outro")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Lava-louças com os modelos reais (medida da ficha, sem embalagem), desenho de cada modelo
    /// (painel, display, puxador, cor de fábrica) e a de 8 serviços embutida no módulo (nicho com ela dentro).
    func testLavaLoucasModelosReaisEOitoServicosEmbutidaNoNicho() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};var tm='';window.toast=function(t){tm=t};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return JSON.parse(JSON.stringify(it))};
          var M=function(re){return APM.lavaloucas.m.filter(function(q){return re.test(q[0])})[0]||[]};
          R.ls08e=M(/LS08E/).slice(1,4).join('x');R.lb08e=M(/LB08E/).slice(1,4).join('x')+':'+(M(/LB08E/)===M(/LS08E/));R.ll08s=M(/LL08S/).slice(1,4).join('x');R.blf08=M(/BLF08/).slice(1,4).join('x');
          R.m10=M(/MDWEF1034/).slice(1,4).join('x');R.ls10e=M(/LS10E/).slice(1,4).join('x');R.dwa14=M(/DWA14B/).slice(1,4).join('x');R.m14=M(/MDWEF1433/).slice(1,4).join('x');R.m14b=/black inox/.test(M(/MDWEF1433/)[0]||'');R.blf14=M(/BLF14AB/).slice(1,4).join('x');
          R.nModelos=APM.lavaloucas.m.length;R.semGenerico=!APM.lavaloucas.m.some(function(q){return /conferir|t[ií]pica|painel do m/i.test(q[0])});
          newTpl(tpl('Balcão 2 portas'));draw();catAp();var c=CATS.filter(function(q){return q.id==='clav'})[0];R.nichos=c.it.filter(function(i){return i.act==='lvn'}).length;
          catAct2(c.it.filter(function(i){return i.act==='lvn'})[0]);draw();
          var m=S.mods.filter(function(o){return o.lavaNicho})[0],f=S.fr.filter(function(q){return q.t==='lavaloucas'})[0];
          R.nicho=m?[m.w,m.h,m.fundo].join(','):null;R.dentro=!!(m&&f&&Math.abs((m.x+m.w/2)-(f.x+f.w/2))<1&&f.b>=m.b+100&&f.b+f.h<=m.b+m.h-15);
          m.x+=300;draw();R.segue=Math.abs((m.x+m.w/2)-(f.x+f.w/2))<1;R.semPorta=!partsOf(m).some(function(p){return /^Porta|^Frente/.test(p.name)});
          S.stones=[{id:1,x:0,w:2400,d:600,t:820,e:30,shape:'reta',items:[]}];S.st=S.stones[0];
          var g=apAdd('lavaloucas',APM.lavaloucas.m.indexOf(M(/LL08S/)));draw();R.naBancada=g.b===benchTop();
          var p=apAdd('lavaloucas',APM.lavaloucas.m.indexOf(M(/MDWEF1433/)));p.fin='preto';draw();R.piso=[p.b,p.fin].join(',');R.semDup=!CATS.some(function(c){return c.it.some(function(i){return /Lava-louças · Lava-louças/.test(i.n)})});
          R.desenho=(document.getElementById('svg').innerHTML.match(/>1:19</g)||[]).length;
          R.foto=c.it.filter(function(i){return /Lava/.test(i.n)}).every(function(i){return !!FOTOS[fotoKey(i)]});
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();R.box3=__boxes().filter(function(q){return q.fr===f.id}).length;R.inox=__boxes().filter(function(q){return q.fr===f.id&&q.mid==='inox-escovado'}).length;try{document.getElementById('v3x').click()}catch(_){}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ls08e"] as? String, "550x609x500", "Electrolux LS08E de embutir: 55 × 60,9 × 50 cm")
        XCTAssertEqual(o["lb08e"] as? String, "550x609x500:true", "LS08E inox e LB08E branca são o mesmo aparelho: um item só (a cor no Acabamento)")
        XCTAssertEqual(o["ll08s"] as? String, "550x595x500")
        XCTAssertEqual(o["blf08"] as? String, "510x630x650")
        XCTAssertEqual(o["m10"] as? String, "447x845x594", "Midea 10 serviços estreita: 44,7 × 84,5 × 59,4 cm")
        XCTAssertEqual(o["ls10e"] as? String, "495x845x600")
        XCTAssertEqual(o["dwa14"] as? String, "598x850x600", "Midea 14 serviços branca: 59,8 × 85 × 60 cm")
        XCTAssertEqual(o["m14"] as? String, "600x845x594", "Midea SmartHome 14 serviços: 60 × 84,5 × 59,4 cm (inox ou black inox num item só)")
        XCTAssertEqual(o["m14b"] as? Bool, true, "black inox no mesmo item")
        XCTAssertEqual(o["blf14"] as? String, "598x845x600")
        XCTAssertEqual(o["nModelos"] as? Int, 8, "uma de cada (sem repetir a mesma em outra cor)")
        XCTAssertEqual(o["semGenerico"] as? Bool, true, "só modelos reais (troca os genéricos)")
        XCTAssertEqual(o["nichos"] as? Int, 3, "as de 8 serviços aparecem também embutidas no módulo")
        XCTAssertEqual(o["nicho"] as? String, "600,820,false", "nicho 600 (550 + folgas + laterais), altura do balcão, sem fundo")
        XCTAssertEqual(o["dentro"] as? Bool, true, "lava-louças centralizada dentro do nicho, em cima da base")
        XCTAssertEqual(o["segue"] as? Bool, true, "mexeu o nicho: a lava-louças vai junto")
        XCTAssertEqual(o["semPorta"] as? Bool, true, "nicho aberto (sem porta) pra lava-louças")
        XCTAssertEqual(o["naBancada"] as? Bool, true, "compacta solta vai em cima da bancada")
        XCTAssertEqual(o["piso"] as? String, "0,preto", "de piso embaixo da bancada, black inox pelo acabamento")
        XCTAssertEqual(o["semDup"] as? Bool, true, "catálogo sem \"Lava-louças · Lava-louças\"")
        XCTAssertGreaterThanOrEqual(o["desenho"] as? Int ?? 0, 3, "desenho com painel e display de cada modelo")
        XCTAssertEqual(o["foto"] as? Bool, true, "foto de cada lava-louças no catálogo")
        XCTAssertGreaterThan(o["box3"] as? Int ?? 0, 6, "3D detalhado")
        XCTAssertGreaterThan(o["inox"] as? Int ?? 0, 0, "chapas de inox com a textura escovada no 3D")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Porta de correr: 2 toques na folha (2D e 3D) abre a configuração dela; puxador perfil G lateral 35 mm de cima a baixo
    /// (desconta na largura do MDF), lado (pontas ou meio), cor; espelho só na folha escolhida, tamanho e posição editáveis, centralizar.
    func testPortaDeCorrerGLateralEEspelhoNaFolhaCom2Toques() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='quarto';S.room='quarto';S.W=2400;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(t){R.toast=String(t)};
          var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n==='Guarda-roupa porta de correr')it=t})});newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];m.x=200;m.lock=false;S.m=m;draw();panel();
          var L=function(){return partsOf(m).filter(function(p){return p.name==='Porta de correr'})};R.leaf0=L().map(function(p){return p.cl+'x'+p.cw});
          /* 2 toques na folha 2 no desenho */
          var r2=[].slice.call(document.querySelectorAll('#svg rect[data-p]')).filter(function(r){var p=partsOf(m)[+r.dataset.p];return p&&p.name==='Porta de correr'&&p.dq===1})[0];r2.scrollIntoView({block:'center'});await new Promise(function(r){setTimeout(r,80)});var bb=r2.getBoundingClientRect(),cx=bb.left+bb.width*.6,cy=bb.top+bb.height*.5;
          var pe=function(t){document.getElementById('svg').dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:cx,clientY:cy,pointerId:4,pointerType:'touch',isPrimary:true,buttons:t==='pointerup'?0:1}))};
          pe('pointerdown');pe('pointerup');await new Promise(function(r){setTimeout(r,60)});pe('pointerdown');pe('pointerup');await new Promise(function(r){setTimeout(r,450)});
          var box=document.getElementById('slcfg');R.abriu=!!box&&/folha 2 de 2/.test(box.textContent);R.semMenuVao=!document.querySelector('#vmenu:not([hidden])');
          var clk=function(a){var b=document.querySelector('#slcfg [data-slc="'+a+'"]');if(!b)return 'sem '+a;b.click();return 'ok'};
          R.c1=clk('px|gl');R.gl=L().map(function(p){return p.cl+'x'+p.cw+':'+p.sps});R.nota=/perfil G lateral 29/.test(L()[0].note);
          R.c2=clk('esp|on');var E=function(){var e=partsOf(m).filter(function(p){return p.mirror});return e.map(function(p){return [p.dq,p.cl,p.cw,m.v[0].esp[p.dq].x,m.v[0].esp[p.dq].y].join(',')})};R.esp1=E();
          var inp=document.querySelector('#slcfg [data-slci="w"]');inp.value='600';inp.dispatchEvent(new Event('change',{bubbles:true}));R.esp2=E();
          R.c3=clk('mv|10|0');R.esp3=E();R.c4=clk('ctr|ab');R.esp4=E();R.c5=clk('esp|cheio');R.esp5=E();
          var iy=document.querySelector('#slcfg [data-slci="y"]');iy.value='5000';iy.dispatchEvent(new Event('change',{bubbles:true}));R.esp6=E();
          R.c6=clk('lado|meio');R.meio=L().map(function(p){return p.sps}).join('');R.c7=clk('cor|dourado');
          /* só a folha 2 tem espelho */R.so2=partsOf(m).filter(function(p){return p.mirror}).length===1;
          var sv=document.getElementById('svg').innerHTML;R.svgEsp=/stroke="#7f8f9a"/.test(sv);
          var hw=hwOf(m);R.hw=Object.keys(hw).filter(function(k){return /Perfil G lateral|Espelho/.test(k)}).map(function(k){return k+'='+hw[k].n});
          R.cx=clk('x');R.fechou=!document.getElementById('slcfg');
          /* 3D: perfil G e espelho; 2 toques na folha abre a configuração */
          open3D();await new Promise(function(r){setTimeout(r,400)});__cam(0,0.15,1.2);__build();var B=__boxes();R.mir3=B.filter(function(q){return q.mir}).length;
          var fb=B.filter(function(q){return /:Porta de correr/.test(q.nm)&&q.dq===0&&(q.x1-q.x0)>300})[0];R.fbOk=!!fb;
          if(fb){var cv=document.querySelector('#v3 canvas'),rc=cv.getBoundingClientRect(),pp=__p3((fb.x0+fb.x1)/2,(fb.y0+fb.y1)/2,fb.z1),X=rc.left+pp[0],Y=rc.top+pp[1];var mk=function(t){return new PointerEvent(t,{bubbles:true,cancelable:true,clientX:X,clientY:Y,pointerId:7,pointerType:'touch',isPrimary:true,buttons:t==='pointerup'?0:1})};/* os 2 toques criados juntos (o 1º toque mexe a folha e o desenho demora no teste) */var E4=[mk('pointerdown'),mk('pointerup'),mk('pointerdown'),mk('pointerup')];E4.forEach(function(e){cv.dispatchEvent(e)});await new Promise(function(r){setTimeout(r,700)});var b3=document.getElementById('slcfg');R.abriu3D=!!b3&&/folha 1 de 2/.test(b3.textContent);try{window.slideCfgClose()}catch(_){}}
          try{document.getElementById('v3x').click()}catch(_){}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["leaf0"] as? [String], ["906x2300", "906x2300"])
        XCTAssertEqual(o["abriu"] as? Bool, true, "2 toques na folha 2 no desenho abre a configuração dela")
        XCTAssertEqual(o["semMenuVao"] as? Bool, true, "não abre o menu do vão em cima")
        XCTAssertEqual(o["gl"] as? [String], ["877x2300:l", "877x2300:r"], "perfil G lateral: MDF 906 − 29 (perfil gola de 42 − 13 que abraçam a MDF), nas pontas de fora")
        XCTAssertEqual(o["nota"] as? Bool, true, "plano de corte explica MDF + perfil G lateral")
        XCTAssertEqual(o["esp1"] as? [String], ["1,700,2000,103,150"], "espelho só na folha 2, centralizado")
        XCTAssertEqual(o["esp2"] as? [String], ["1,600,2000,153,150"], "mudou a largura: continua centralizado")
        XCTAssertEqual(o["esp3"] as? [String], ["1,600,2000,163,150"], "reposiciona 10 mm")
        XCTAssertEqual(o["esp4"] as? [String], ["1,600,2000,153,150"], "centralizar")
        XCTAssertEqual(o["esp5"] as? [String], ["1,866,2260,20,20"], "espelho na folha inteira")
        XCTAssertEqual(o["esp6"] as? [String], ["1,866,2260,20,40"], "posição limitada dentro da folha")
        XCTAssertEqual(o["meio"] as? String, "rl", "puxador no encontro das folhas")
        XCTAssertEqual(o["so2"] as? Bool, true, "espelho só na folha escolhida")
        XCTAssertEqual(o["svgEsp"] as? Bool, true, "espelho aparece no desenho")
        XCTAssertEqual(o["hw"] as? [String], ["Perfil G lateral 29 mm · dourado (m)=4.6", "Espelho 4 mm lapidado · 866 × 2260 (folha 2)=1", "Espelho 4 mm (m²)=1.96"], "ferragens: perfil G e espelho")
        XCTAssertEqual(o["fechou"] as? Bool, true)
        XCTAssertEqual(o["mir3"] as? Int, 1, "espelho no 3D")
        XCTAssertEqual(o["abriu3D"] as? Bool, true, "2 toques na folha no 3D abre a configuração")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Lixeira de embutir na pedra com medida real (furo redondo, aro, altura), no catálogo da cozinha, na pedra e no resumo pra marmoraria;
    /// não conta como cuba (a torneira vai na cuba).
    func testLixeiraDeEmbutirNaPedraComMedidaReal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};var tm='';window.toast=function(t){tm=String(t)};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return JSON.parse(JSON.stringify(it))};
          newTpl(tpl('Balcão 2 portas'));newTpl(tpl('Balcão 2 portas'));draw();if(!S.stones.length)addStone();draw();
          var c=CATS.filter(function(q){return q.id==='clix'})[0];R.cat=c?c.it.map(function(i){return i.n}):null;R.noCozinha=ROOMCATS.cozinha.indexOf('clix')>=0;
          catAct2(c.it[0]);var st=S.stones[0],lx=st.items.filter(function(i){return isLix(i)})[0];R.toast=tm;R.item=lx?[lx.w,lx.d,lx.cm].join(','):null;
          /* cuba normal + torneira: a torneira vai na cuba, não na lixeira */
          var cu=CATS.filter(function(q){return q.id==='ccoz'})[0].it[0];catAct2(cu);var cub=st.items.filter(function(i){return i.k==='cuba'&&!isLix(i)})[0];cub.x=200;lx.x=1200;draw();
          var tq=apAdd('torneira',0);draw();R.torneiraNaCuba=Math.abs((tq.x+tq.w/2)-(st.x+cub.x+cub.w/2))<2;
          R.marm=((window.marmHtml?marmHtml(st):document.body.innerHTML).match(/Recorte da lixeira[^<]*/)||[''])[0];
          R.svg=/fill="#2f6be0"/.test(document.getElementById('svg').innerHTML);
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var B=__boxes();R.b3=B.length>0;try{document.getElementById('v3x').click()}catch(_){}
          S.sel=null;S.selI=lx.id;LAST='item';S.tab=6;panel();R.painel=/Lixeira selecionad/.test(document.getElementById('bd')?document.getElementById('bd').innerHTML:document.body.innerHTML);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual((o["cat"] as? [String])?.count, 3, "3 lixeiras de embutir no catálogo")
        XCTAssertEqual((o["cat"] as? [String])?.first, "Lixeira de embutir 5 L (tipo Lorben) · furo Ø225 · aro Ø235 · altura 240")
        XCTAssertEqual(o["noCozinha"] as? Bool, true)
        XCTAssertEqual(o["item"] as? String, "235,235,lxlor", "aro Ø235 em cima da pedra")
        XCTAssertEqual(o["torneiraNaCuba"] as? Bool, true, "a torneira vai na cuba, não na lixeira")
        XCTAssertEqual((o["marm"] as? String)?.hasPrefix("Recorte da lixeira · redondo Ø225 mm"), true, "marmoraria: recorte redondo Ø225")
        XCTAssertEqual(o["svg"] as? Bool, true, "balde aparece embaixo da pedra no desenho")
        XCTAssertEqual(o["painel"] as? Bool, true, "quadro diz Lixeira (não Cuba)")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Girar no lugar (0, 90, 180, 270°) em todos os eletrodomésticos, pelo quadro do 3D e do 2D: no 3D, na planta e no desenho de frente.
    func testGirarEletrodomesticoNoLugar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(t){R.toast=String(t)};
          var M=function(re){return APM.lavaloucas.m.filter(function(q){return re.test(q[0])})[0]};var f=apAdd('lavaloucas',APM.lavaloucas.m.indexOf(M(/BLF14/)));f.x=1000;f.y=0;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var ext=function(){var B=__boxes().filter(function(q){return q.fr===f.id}),x0=1e9,x1=-1e9,z0=1e9,z1=-1e9;B.forEach(function(q){x0=Math.min(x0,q.x0);x1=Math.max(x1,q.x1);z0=Math.min(z0,q.z0);z1=Math.max(z1,q.z1)});return [Math.round(x1-x0),Math.round(z1-z0),Math.round((x0+x1)/2),Math.round((z0+z1)/2)]};R.e0=ext();
          /* quadro do 3D: botão girar 90 */fx3api.open({k:'fr',id:f.id});await new Promise(function(r){setTimeout(r,200)});var b=document.querySelector('[data-qgiro="90"]');R.botao3D=!!b;if(b)b.click();await new Promise(function(r){setTimeout(r,200)});__build();R.giro=f.giro;R.e90=ext();
          var b2=document.querySelector('[data-qgiro="180"]');if(b2)b2.click();await new Promise(function(r){setTimeout(r,200)});__build();R.e180=ext();
          try{document.getElementById('v3x').click()}catch(_){}
          /* planta e 2D */f.giro=90;draw();var r=frFoot(f);R.foot=r?[Math.round(r.x1-r.x0),Math.round(r.y1-r.y0)]:null;R.lado=/de lado 90/.test(document.getElementById('svg').innerHTML);
          /* quadro do 2D */SELAP=f.id;LAST='ap';showBox();var c=document.querySelector('[data-apgiro="270"]');R.botao2D=!!c;if(c)c.click();R.g2=f.giro;
          /* mobília não leva (já gira pelo dela) */var me=apAdd('mesa',0);R.mesa=frGiroOk(me);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["botao3D"] as? Bool, true, "quadro do 3D tem Girar")
        XCTAssertEqual(o["giro"] as? Int, 90)
        XCTAssertEqual((o["e0"] as? [Int])?.prefix(2).map { $0 }, [598, 640], "de frente: largura × fundura (com o puxador)")
        XCTAssertEqual((o["e90"] as? [Int])?.prefix(2).map { $0 }, [640, 598], "girado 90°: troca largura e fundura no 3D")
        XCTAssertEqual((o["e180"] as? [Int])?.prefix(2).map { $0 }, [598, 640])
        XCTAssertEqual(o["foot"] as? [Int], [600, 598], "planta: pegada girada")
        XCTAssertEqual(o["lado"] as? Bool, true, "desenho de frente mostra de lado")
        XCTAssertEqual(o["botao2D"] as? Bool, true, "quadro do 2D tem Girar")
        XCTAssertEqual(o["g2"] as? Int, 270)
        XCTAssertEqual(o["mesa"] as? Bool, false, "mobília continua com o giro dela")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Desconto (%) no valor do projeto: recalcula na hora (chips e digitando), vai pro orçamento (itens no valor cheio + desconto) e fica salvo no projeto.
    func testDescontoNoValorDoProjeto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];draw();var R={};window.toast=function(){};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return JSON.parse(JSON.stringify(it))};
          newTpl(tpl('Balcão 2 portas'));newTpl(tpl('Balcão 2 portas'));draw();PR.mdfB=PR.mdfB||300;
          var b=budget();S.preco=10000;vlOpen();R.base=vlFin(b);
          var c=document.querySelector('#vlm [data-vdesc="10"]');R.chip=!!c;c.click();R.fin10=vlFin(budget());R.caixa=/Valor com desconto/.test(document.getElementById('vlbody').innerHTML)&&/R\$\s*9\.000,00/.test(document.getElementById('vlbody').innerHTML.replace(/&nbsp;/g,' '));
          var i=document.querySelector('#vlm [data-vdesci]');i.value='12,5';i.dispatchEvent(new Event('input',{bubbles:true}));R.fin125=vlFin(budget());R.foco=document.activeElement&&document.activeElement.dataset&&document.activeElement.dataset.vdesci==='1';
          var q=quoteData();R.q={total:q.total,disc:q.discountPct,sum:Math.round(q.items.reduce(function(a,x){return a+x.value},0)*100)/100,n:q.items.length};
          S.vlTot=1;var q2=quoteData();R.q2={total:q2.total,disc:q2.discountPct,v:q2.items[0].value,n:q2.items.length};S.vlTot=0;
          /* salva no projeto e volta */var st=snapState();R.salvo=st.desc;S.desc=0;loadState(st);R.volta=S.desc;
          document.querySelector('#vlm [data-vdesc="0"]').click();R.zero=vlFin(budget());R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual((o["base"] as? NSNumber)?.doubleValue, 10000)
        XCTAssertEqual(o["chip"] as? Bool, true)
        XCTAssertEqual((o["fin10"] as? NSNumber)?.doubleValue, 9000, "10% de desconto: 10.000 → 9.000")
        XCTAssertEqual(o["caixa"] as? Bool, true, "mostra o valor com desconto")
        XCTAssertEqual((o["fin125"] as? NSNumber)?.doubleValue, 8750, "digitando 12,5 já recalcula")
        let q = o["q"] as? [String: Any]
        XCTAssertEqual((q?["total"] as? NSNumber)?.doubleValue, 8750)
        XCTAssertEqual((q?["disc"] as? NSNumber)?.doubleValue, 12.5, "orçamento leva o desconto (%)")
        XCTAssertEqual((q?["sum"] as? NSNumber)?.doubleValue, 10000, "itens no valor cheio (o PDF mostra o desconto)")
        let q2 = o["q2"] as? [String: Any]
        XCTAssertEqual((q2?["v"] as? NSNumber)?.doubleValue, 10000, "orçamento com uma linha só também")
        XCTAssertEqual((o["salvo"] as? NSNumber)?.doubleValue, 12.5, "desconto fica salvo no projeto")
        XCTAssertEqual((o["volta"] as? NSNumber)?.doubleValue, 12.5)
        XCTAssertEqual((o["zero"] as? NSNumber)?.doubleValue, 10000, "sem desconto volta ao valor cheio")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testSomaDasPlacasConfereComATrenaEAJunta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.ops=[];S.env='sala';S.room='sala';S.Hm=1;var R={},F=[],N=0,r1=function(v){return Math.round(v*10)/10};
          var jw=function(a){return a.jt&&a.jt.t&&a.jt.t!=='seca'?(+a.jt.w||0):0};
          var chk=function(tag,x0,x1,n,j){N++;var g={};S.rp.filter(function(a){return a.liso&&!a.prat}).forEach(function(a){var k=r1(a.b);(g[k]=g[k]||[]).push(a)});var bad=[];Object.keys(g).forEach(function(k){var Rw=g[k].sort(function(p,q){return p.x-q.x}),ws=Rw.map(function(a){return a.w});if(Math.max.apply(null,ws)-Math.min.apply(null,ws)>0.25)bad.push('larguras '+ws.join('/'));for(var i=1;i<Rw.length;i++){var gp=r1(Rw[i].x-(Rw[i-1].x+Rw[i-1].w));if(Math.abs(gp-j)>0.15)bad.push('junta '+gp)}if(Math.abs(Rw[0].x-x0)>0.15)bad.push('começa '+Rw[0].x);var e=Rw[Rw.length-1].x+Rw[Rw.length-1].w;if(Math.abs(e-x1)>0.15)bad.push('termina '+r1(e));if(Rw.length!==n)bad.push(Rw.length+' placas')});if(bad.length)F.push(tag+': '+bad.slice(0,3).join(' | '))};
          /* trena com sobra até a parede (0 a 60 mm) dos dois lados, rebaixo, vão e junta seca */
          [1415,3841].forEach(function(W){[[0,0],[0,10],[0,39],[15,0],[35,20],[100,5]].forEach(function(sb){['reb','seca'].forEach(function(t){[2,5].forEach(function(n){S.W=W;S.H=3215;S.rodape=10;wallSet('F','h1',3215);S.rp=[];S.trena={x0:sb[0],x1:W-sb[1]};TRN=n;TRW=0;TRT=t;TRJ=15;TRH=0;TRFR=false;if(!trCalc().fits)return;trCreate();draw();draw();chk('trena '+W+' '+sb.join('/')+' '+t+' '+n,sb[0],W-sb[1],n,t==='seca'?0:15)})})})});
          /* painéis na parede com recuo */
          [[3841,0],[3841,10],[2890,30]].forEach(function(q){S.W=q[0];S.rp=[];S.pw={x0:q[1],x1:q[0]-q[1]};pwGenerate();draw();draw();var n=S.rp.filter(function(a){return a.b<1}).length;chk('painéis '+q.join('/'),q[1],q[0]-q[1],n,15)});S.pw={};
          /* mais uma: rebaixo marcado com 0 no campo do Dividir, e junta seca com 15 no campo */
          [[0,'reb',15],[15,'seca',0]].forEach(function(q){S.W=4000;S.rp=[{id:1,liso:true,x:0,b:0,w:900,h:2700,jt:{t:q[1],w:15,d:6}}];PLJ=q[0];PLJT={t:q[1],w:15,d:6};rpAddNext(S.rp[0],1);rpAddNext(rpCur(),1);draw();draw();chk('mais uma '+q[1],0,2700+2*q[2],3,q[2])});
          R.total=N;R.falhas=F;
          /* conferência da soma: caso da parede de 3841 com a trena até 3831 */
          S.W=3841;S.H=3215;S.rodape=10;wallSet('F','h1',3215);S.rp=[];S.trena={x0:0,x1:3831};TRN=5;TRT='reb';TRJ=15;trCreate();draw();var t=rpConf().replace(/<[^>]+>/g,' ').replace(/\s+/g,' ');
          R.conf=/Fileira a 10 do chão: 5 × 754,2 \+ 4 juntas de 15 = 3831 · de 0 a 3831 \(parede 3841, sobra 10 na direita\)/.test(t)&&/Altura: 10 \(embaixo\) \+ 2700 \+ 15 de junta \+ 490 = 3215 · teto 3215/.test(t)&&!/⚠/.test(t);
          R.naLista=rpCutHtml().indexOf('data-rpconf="ok"')>=0;
          /* plano antigo com junta perdida (706/736): a conferência avisa */
          S.W=3000;S.rp=[{id:21,liso:true,x:0,b:0,w:736,h:2700},{id:22,liso:true,x:751,b:0,w:706,h:2700},{id:23,liso:true,x:1472,b:0,w:721,h:2700},{id:24,liso:true,x:2208,b:0,w:721,h:2700}];S.rp.forEach(function(a){a.wFix=1;a.jt={t:'reb',w:15,d:6}});var t2=rpConf().replace(/<[^>]+>/g,' ').replace(/\s+/g,' ');
          R.avisa=/⚠/.test(t2)&&/placa 1 com 15 a mais/.test(t2)&&/placa 2 com 15 a menos/.test(t2);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertGreaterThan((o["total"] as? NSNumber)?.intValue ?? 0, 30, "cenários conferidos")
        XCTAssertEqual((o["falhas"] as? [String])?.count, 0, "soma das placas: \(((o["falhas"] as? [String]) ?? []).joined(separator: " || "))")
        XCTAssertEqual(o["conf"] as? Bool, true, "conferência mostra 5 × 754,2 + 4 juntas de 15 = 3831 e a altura somando 3215")
        XCTAssertEqual(o["naLista"] as? Bool, true, "a conferência vai junto na lista de corte")
        XCTAssertEqual(o["avisa"] as? Bool, true, "placa com 15 a mais/menos que as outras é avisada")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    func testTorrePorVaosRecorteMeioRecortePortaNormalEModelosReais() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];S.ops=[];draw();var R={};
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=t})});return it?JSON.parse(JSON.stringify(it)):null};
          var clk=function(sel){var b=document.querySelector('#bd '+sel);if(!b)return false;b.click();return true};
          var P=function(m){return partsOf(m)},nm=function(p){return p.name};
          /* 1) torre pronta: micro de embutir (manual) + forno + 2 gavetas */
          newTpl(tpl('Torre por vãos · micro-ondas + forno + gavetas'));var m=S.mods[0];S.m=m;S.sv=0;S.tab=2;draw();panel();var v=m.v[0];
          var A=P(m),cm=A.filter(function(p){return p.name==='Corte do micro-ondas'})[0],cf=A.filter(function(p){return p.name==='Corte do forno'})[0];
          R.micro=cm?[cm.mdl,cm.w,cm.h].join(' '):'';R.forno=cf?[cf.mdl,cf.w,cf.h].join(' '):'';
          R.gav=A.filter(function(p){return /^Frente de gaveta|^Gaveta/.test(p.name)&&p.dq!==undefined&&p.dq>=20}).length;
          R.regua=A.filter(function(p){return /^Engrosso cava · régua da torre/.test(p.name)}).length;R.prat=A.filter(function(p){return /^Prateleira fixa da torre/.test(p.name)}).length;
          R.painel=!!document.getElementById('twed');R.warn=(v.twW||[]).length;
          /* 2) toca no vão 1 (micro) e vira 2 portas; a prateleira 1 ganha engrosso, frontal pra baixo de 80 e régua em cima */
          clk('[data-twsel="v|0"]');clk('[data-twk="door|2"]');R.porta2=v.tw[0].k==='door'&&+v.tw[0].n===2&&P(m).filter(function(p){return p.dq!==undefined&&Math.floor(p.dq/10)===0&&/^Porta/.test(p.name)}).length===2;
          clk('[data-twsel="p|0"]');clk('[data-twpe="1"]');clk('[data-twpf="down"]');var ip=document.querySelector('#bd [data-twpfh]');if(ip){ip.value='80';ip.dispatchEvent(new Event('change',{bubbles:true}))}clk('[data-twpr="up"]');
          var B2=P(m);R.eng=B2.filter(function(p){return /Prateleira fixa da torre 1/.test(p.name)}).length;R.front=B2.filter(function(p){return /^Frontal da prateleira 1/.test(p.name)}).map(function(p){return Math.round(p.h)}).join(',');R.rg1=B2.filter(function(p){return /régua da torre \(prateleira 1, em cima\)/.test(p.name)}).length;
          /* 3) vão 3 (gavetas) vira 3 gavetas; depois divide o vão e o novo vira porta */
          clk('[data-twsel="v|3"]');clk('[data-twn="1"]');R.g3=+v.tw[3].n;clk('[data-twadd="1"]');R.nv=v.tw.length;
          /* 4) torre com porta de recorte: detalhe por fora e por dentro bate com o manual do forno */
          S.mods=[];newTpl(tpl('Torre por vãos · forno + micro com porta de recorte'));m=S.mods[0];S.m=m;S.sv=0;S.tab=2;v=m.v[0];draw();panel();
          var fo=v.tw.map(function(t,j){return t.k==='forno'?j:-1}).filter(function(j){return j>=0})[0];v.twS={t:'v',j:fo};draw();panel();
          var fp=P(m).filter(function(p){return p.rec&&p.tws===fo})[0],M=TWM[v.tw[fo].mdl];
          R.rec=!!fp&&fp.rec.w===M.nw&&fp.rec.h===M.nh&&fp.rec.x>0&&fp.rec.y>=0&&fp.rec.x+fp.rec.w<fp.w&&fp.rec.y+fp.rec.h<=fp.h;
          var tx=(document.getElementById('twed')||{}).textContent||'';R.det=/Por fora: [\d,]+ × [\d,]+/.test(tx)&&/Por dentro \(recorte\): 560 × 580/.test(tx)&&/medida do fabricante, não muda/.test(tx);
          R.semAltura=!document.querySelector('#bd [data-twh]');
          /* troca o modelo: o recorte segue o nicho do novo forno */
          var se=document.querySelector('#bd select[data-twm]');if(se){se.value='f_bx84';se.dispatchEvent(new Event('change',{bubbles:true}))}var fp2=P(m).filter(function(p){return p.rec&&p.tws===fo})[0];R.rec2=fp2?fp2.rec.w+'x'+fp2.rec.h:'';
          /* meio recorte: aberto embaixo (o recorte vai até a borda de baixo da frente) */
          clk('[data-twfr="meio"]');var fm=P(m).filter(function(p){return p.rec&&p.tws===fo})[0];R.meio=!!fm&&/meio recorte/.test(fm.name)&&Math.abs(fm.rec.y+fm.rec.h-fm.h)<.6&&fm.rec.w===TWM.f_bx84.nw;
          tx=(document.getElementById('twed')||{}).textContent||'';R.meioTx=/embaixo aberto/.test(tx)&&/Por dentro · em cima 570/.test(tx);
          /* no plano de corte o recorte sai desenhado em cima da peça, com as medidas de fora e de dentro */
          var pl=sheetPlan(1),hs=planHtml(pl,0),un=[];pl.groups.forEach(function(g){g.sheets.forEach(function(sh){sh.used.forEach(function(u){if(/recorte/.test(u.p.lab))un.push(u)})})});R.chapa=un.length>=1&&un.every(function(u){var t=recPcSvg(u,0,0);return /RECORTE/.test(t)&&/topo da peça/.test(t)&&/esq\. \d/.test(t)})&&/RECORTE/.test(hs);
          /* porta normal: porta que abre na frente, o eletro fica atrás (e avisa no forno) */
          clk('[data-twfr="normal"]');R.normal=P(m).some(function(p){return p.name==='Porta'&&p.tws===fo})&&!P(m).some(function(p){return p.rec&&p.tws===fo})&&P(m).some(function(p){return p.name==='Corte do forno'&&p.behind});R.avisoF=(v.twW||[]).some(function(w){return /ventilação/.test(w)});
          clk('[data-twfr="porta"]');
          /* embutido: some a porta e fica só o corte */
          clk('[data-twfr="emb"]');R.emb=!P(m).some(function(p){return p.rec&&p.tws===fo})&&P(m).some(function(p){return p.name==='Corte do forno'&&p.tws===fo});
          /* 2D: a frente do modelo e o tracejado do vão escolhido */
          draw();R.hl=document.querySelectorAll('#svg [stroke="#2f6be0"]').length>0&&partsOf(m).some(function(p){return p.twsl&&p.tws===fo&&p.st==='#2f6be0'});
          /* padrão: nenhum módulo desce até o chão, as laterais apoiam na base do rodapé (torre e balcão iguais) */
          S.mods=[];newTpl(tpl('Torre por vãos · forno + micro com porta de recorte'));newTpl(tpl('Balcão 2 portas'));var tq=S.mods[0],bq=S.mods[1];R.padrao=STD().latPiso==='nao'&&!tq.latPiso&&!bq.latPiso;
          var latT=partsOf(tq).filter(function(p){return p.name==='Lateral esquerda'})[0],latB=partsOf(bq).filter(function(p){return p.name==='Lateral esquerda'})[0];R.latRod=!!latT&&!!latB&&tq.h-(latT.y+latT.h)>=(+tq.rodMm||0)-1&&bq.h-(latB.y+latB.h)>=(+bq.rodMm||0)-1&&(+tq.rodMm||0)>0;
          /* torre antiga converte sem perder o forno */
          var old=tpl('Torre forno + micro-ondas (embutir)');if(old){S.mods=[];newTpl(old);m=S.mods[0];S.m=m;S.sv=0;S.tab=2;v=m.v.filter(function(x){return x.k==='oven'})[0];S.sv=m.v.indexOf(v);draw();panel();clk('[data-twconv="1"]');R.conv=!!(v.tw&&v.tw.some(function(t){return t.k==='forno'}))}else R.conv='sem modelo';
          /* modelos: medidas do manual, todos diferentes no desenho, todos no catálogo */
          var ids=Object.keys(TWM),st={};ids.forEach(function(id){var q=TWM[id];st[[q.k,q.emb,q.st.c,q.st.pn,q.st.dr||'',q.st.px,q.w,q.h].join('|')]=1});R.mod=ids.length;R.dif=Object.keys(st).length;
          R.medida=ids.every(function(id){var q=TWM[id];return q.w>300&&q.h>200&&q.d>300&&(!q.emb||(q.nw>=500&&q.nh>=300&&q.nd>=400))});
          var cat=[];CATS.forEach(function(c){if(c.id==='ele')c.it.forEach(function(it){cat.push(it.n)})});R.noCat=ids.filter(function(id){return !cat.some(function(n){return n.indexOf(TWM[id].n)>=0})});
          /* eletro solto (forno do catálogo) desenha a frente do modelo dele */
          S.mods=[];S.ap=[];var ap=apAdd('forno',apModels('forno').map(function(q){return q[0]}).indexOf(TWM.f_bx84.n));R.solto=ap?__tw.mdlOf({nome:ap.nome})==='f_bx84'&&ap.w===600&&ap.h===620:false;
          /* blindex: porta pivotante com ferragens, de correr aparente e janela com esquadria preta */
          S.ap=[];S.mods=[];S.env='sala';S.ops=[{id:1,t:'porta',x:200,b:0,w:900,h:2100,st:'blindex',vm:'a1',fp:'sem',ve:10,pux:'barra',fc:'preto',wall:'f'},{id:2,t:'porta',x:1400,b:0,w:900,h:2100,st:'vidro',vm:'ca',fp:'sem',ve:10,pux:'barra',fc:'cromo',wall:'f'},{id:3,t:'janela',x:2600,b:1000,w:1200,h:1000,st:'blindex',fp:'preto',wall:'f'}];draw();
          R.vdm=!!VDM.ca;R.cfg=vdCfg(S.ops[1]).fp+'/'+vdCfg(S.ops[0]).fc;
          var bad=[];CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;(t&&t.v||[]).forEach(function(v){(v.tw||[]).forEach(function(s){if(s.mdl&&!TWM[s.mdl])bad.push(t.n+' '+s.mdl)})})})});R.idsOk=bad.length===0;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["micro"] as? String, "m_me3bp 570 370", "micro de embutir com o nicho do manual")
        XCTAssertEqual(o["forno"] as? String, "f_el80 560 600", "forno com o nicho do manual")
        XCTAssertEqual((o["gav"] as? NSNumber)?.intValue, 2, "2 gavetas no vão de baixo")
        XCTAssertEqual(o["painel"] as? Bool, true, "painel da torre por vãos")
        XCTAssertEqual((o["warn"] as? NSNumber)?.intValue, 0, "torre pronta sem aviso")
        XCTAssertEqual(o["porta2"] as? Bool, true, "vão vira 2 portas")
        XCTAssertEqual((o["eng"] as? NSNumber)?.intValue, 2, "prateleira engrossada = 2 peças")
        XCTAssertEqual(o["front"] as? String, "80", "frontal de 80 pra baixo")
        XCTAssertEqual((o["rg1"] as? NSNumber)?.intValue, 1, "régua do cava em cima da prateleira 1")
        XCTAssertEqual((o["g3"] as? NSNumber)?.intValue, 3, "3 gavetas")
        XCTAssertEqual((o["nv"] as? NSNumber)?.intValue, 5, "dividir o vão cria mais um")
        XCTAssertEqual(o["rec"] as? Bool, true, "recorte da porta = nicho do manual, dentro da porta")
        XCTAssertEqual(o["det"] as? Bool, true, "detalhe do corte por fora e por dentro")
        XCTAssertEqual(o["semAltura"] as? Bool, true, "altura do vão do forno não é editável")
        XCTAssertEqual(o["rec2"] as? String, "570x610", "trocar o modelo troca o recorte")
        XCTAssertEqual(o["meio"] as? Bool, true, "meio recorte aberto embaixo")
        XCTAssertEqual(o["meioTx"] as? Bool, true, "meio recorte mostra os 4 lados de dentro")
        XCTAssertEqual(o["chapa"] as? Bool, true, "recorte desenhado em cima da peça no plano de corte")
        XCTAssertEqual(o["normal"] as? Bool, true, "porta normal na frente do eletro")
        XCTAssertEqual(o["avisoF"] as? Bool, true, "forno atrás de porta normal avisa")
        XCTAssertEqual(o["emb"] as? Bool, true, "embutido: só o corte")
        XCTAssertEqual(o["hl"] as? Bool, true, "vão escolhido aparece marcado no desenho")
        XCTAssertEqual(o["padrao"] as? Bool, true, "padrão: laterais em cima do rodapé")
        XCTAssertEqual(o["latRod"] as? Bool, true, "torre e balcão com a lateral apoiada na base do rodapé")
        XCTAssertEqual(o["conv"] as? Bool, true, "torre antiga converte pra vãos")
        XCTAssertEqual((o["mod"] as? NSNumber)?.intValue, (o["dif"] as? NSNumber)?.intValue, "cada modelo com desenho diferente")
        XCTAssertEqual(o["medida"] as? Bool, true, "medidas reais coerentes")
        XCTAssertEqual((o["noCat"] as? [String])?.count, 0, "todos os modelos no catálogo")
        XCTAssertEqual(o["solto"] as? Bool, true, "eletro solto usa o modelo")
        XCTAssertEqual(o["vdm"] as? Bool, true, "porta de vidro de correr aparente")
        XCTAssertEqual(o["cfg"] as? String, "sem/preto", "blindex sem perfil e ferragem preta")
        XCTAssertEqual(o["idsOk"] as? Bool, true, "modelos das torres prontas existem")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || "))")
    }

    /// Guarda-roupa: torre por dentro. Toca na parte (quadro ou desenho), digita a medida livre (real, sem a prateleira),
    /// todo item novo pede a medida (maleiro com confirmação), gaveteiro é o caixote com régua espaçadora e fica em cima da base,
    /// "só mais uma prateleira", tubo cabideiro e 2 toques no vão abrem só aquela parte.
    func testTorrePorDentroDoGuardaRoupaMedidaRealEMaisUmaPrateleira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='livre';S.room='quarto';S.W=3500;S.H=2600;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='quarto'})[0];R.torres=c.it.filter(function(q){return /^Torre (do|de prateleiras do) guarda-roupa/.test(q.n)}).length;
          newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Guarda-roupa 2 vãos'})[0])));var m=S.m,v=m.v[0],A=vhm(m),Lv=function(k){return ibLivre(intLayout(v,A),k,m.esp)};S.tab=2;S.sv=0;draw();panel();
          var Q=function(s){return document.querySelector('#bd '+s)};R.keys=[].map.call(document.querySelectorAll('#bd [data-intadd]'),function(b){return b.dataset.intadd}).join(',');
          Q('[data-intadd="mal"]').click();R.pede=ISB.cf===1&&/Confirme a altura do maleiro/.test(Q('#ibbox').textContent);Q('[data-ibmh="450"]').click();Q('[data-ibok]').click();R.mal=Lv(0)+' '+ISB.cf;
          Q('[data-intadd="nic"]').click();R.pede2=ISB.cf;var il=Q('[data-ibl]');il.value='300';il.dispatchEvent(new Event('input',{bubbles:true}));il.dispatchEvent(new Event('change',{bubbles:true}));R.nic=Lv(1)+' '+v.int[0].h;
          Q('[data-intadd="cxg"]').click();R.cxg=v.int.map(function(o){return o.t}).join(',')+' '+Math.round(intLayout(v,A).free);R.regua=partsOf(m).filter(function(p){return p.vi===0&&/régua espaçadora/.test(p.name)}).length;
          var sh0=partsOf(m).filter(function(p){return p.vi===0&&p.name==='Prateleira interna'}).length;S.sv=0;ISB.k=2;panel();Q('[data-ibsp]').click();R.mais=partsOf(m).filter(function(p){return p.vi===0&&p.name==='Prateleira interna'}).length-sh0;
          R.soma=Math.round(intLayout(v,A).it.reduce(function(a,o){return a+o.h},0)+intLayout(v,A).free)===Math.round(A);
          /* o outro vão: cabideiro e o tubo */S.sv=1;ISB.k=-1;panel();Q('[data-intadd="cab"]').click();Q('[data-ibtb="10"]').click();var tb=partsOf(m).filter(function(p){return p.vi===1&&/^Cabideiro/.test(p.name)})[0];R.tubo=tb?Math.round(tb.y-vTop(m)):-1;
          /* desenho grande: alturas de cada parte e digitar tocando no número */draw();R.pilulas=document.querySelectorAll('#svg [data-q^="itw|0.1."]').length;QEXT.itw.set('0.0.0',400);R.digitou=Lv(0);
          /* 2 toques no vão: só aquela parte */vmenuOpen(0,0,100,100,0);var mb=document.getElementById('vmib');R.menu=!!mb&&/Só esta parte/.test(mb.textContent)&&!!document.querySelector('#vmenu [data-ibm="b|cxg"]');document.querySelector('#vmib [data-ibm="t|nic"]').click();R.troca=v.int[0].t;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual((o["torres"] as? NSNumber)?.intValue, 2, "torres do guarda-roupa no catálogo do quarto")
        XCTAssertEqual(o["keys"] as? String, "mal,nic,cab,cabl,cxg,sap", "gaveta de guarda-roupa é o caixote com espaçador")
        XCTAssertEqual(o["pede"] as? Bool, true, "maleiro pede pra confirmar a altura")
        XCTAssertEqual(o["mal"] as? String, "450 0", "maleiro 450 livre confirmado")
        XCTAssertEqual((o["pede2"] as? NSNumber)?.intValue, 1, "todo item novo pede a medida")
        XCTAssertEqual(o["nic"] as? String, "300 465", "nicho com 300 livre e o maleiro não mexe")
        XCTAssertEqual(o["cxg"] as? String, "mal,nic,nic,cxg 0", "gaveteiro fica em cima da base")
        XCTAssertEqual((o["regua"] as? NSNumber)?.intValue, 2, "régua espaçadora dos dois lados")
        XCTAssertEqual((o["mais"] as? NSNumber)?.intValue, 1, "só mais uma prateleira")
        XCTAssertEqual(o["soma"] as? Bool, true, "a soma das partes é o vão")
        XCTAssertEqual((o["tubo"] as? NSNumber)?.intValue, 60, "tubo cabideiro a 60 da prateleira de cima")
        XCTAssertGreaterThan((o["pilulas"] as? NSNumber)?.intValue ?? 0, 0, "altura de cada parte no desenho")
        XCTAssertEqual((o["digitou"] as? NSNumber)?.intValue, 400, "digitar tocando no número")
        XCTAssertEqual(o["menu"] as? Bool, true, "2 toques: só aquela parte")
        XCTAssertEqual(o["troca"] as? String, "nic")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// 🗑 com uma peça escolhida apaga só ela: prateleira de dentro (as duas partes viram uma), porta, base; volta as peças; 3D também.
    func testApagarSoUmaPecaPrateleiraPortaENo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='livre';S.room='quarto';S.W=3500;S.H=2600;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='quarto'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Guarda-roupa 2 vãos'})[0])));var m=S.m;m.v[0].int=[{t:'mal',h:400},{t:'nic',h:350},{t:'nic',h:350},{t:'cabl',h:1170}];S.tab=2;draw();panel();
          var svg=document.getElementById('svg');svg.scrollIntoView({block:'start'});await new Promise(function(r){setTimeout(r,60)});
          var h=document.querySelectorAll('#svg rect[data-ish^="0|"]')[1],b=h.getBoundingClientRect(),x=b.left+b.width/2,y=b.top+b.height/2,pe=function(el,t){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:9,pointerType:'touch',isPrimary:true,buttons:t==='pointerup'?0:1}))};
          pe(h,'pointerdown');pe(document.elementFromPoint(x,y)||svg,'pointerup');await new Promise(function(r){setTimeout(r,80)});R.escolheu=LAST+' '+(window.PSEL&&PSEL.nm);R.marca=!!document.querySelector('#svg rect[stroke="#e5484d"]');
          $('delMod').click();R.prat=JSON.stringify(m.v[0].int)+' '+S.mods.length;
          var p0=partsOf(m).filter(function(p){return p.name==='Porta'&&p.vi===1})[0];pcSel(0,p0.pk);$('delMod').click();R.porta=partsOf(m).filter(function(p){return p.name==='Porta'}).length+' '+S.mods.length;
          var G=cutGroups();R.corte=G.ord.filter(function(k){return /^Porta/.test(G.map[k].names[0])}).reduce(function(a,k){return a+G.map[k].qty},0);
          S.tab=0;panel();R.voltar=!!document.querySelector('[data-xpr]');document.querySelector('[data-xpr]').click();R.voltou=partsOf(m).filter(function(p){return p.name==='Porta'}).length;
          /* trocar a frente do vão devolve as peças daquele vão */pcSel(0,partsOf(m).filter(function(p){return p.name==='Porta'&&p.vi===1})[0].pk);$('delMod').click();vmenuOpen(0,1,100,100,-1);document.querySelector('#vmenu [data-vk="door1"]').click();R.limpou=(m.xp||[]).length;
          /* 3D: ✏️ Editar peça · 🗑 Só esta peça */open3D();await new Promise(function(r){setTimeout(r,400)});var bs=partsOf(m).filter(function(p){return p.name==='Base inferior'})[0];__e3open(0,bs.pk);var E=[].filter.call(document.querySelectorAll('[data-e3del]'),function(q){return q.offsetParent})[0];R.botao3d=!!E;if(E)E.click();R.base=partsOf(m).filter(function(p){return p.name==='Base inferior'}).length+' '+S.mods.length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["escolheu"] as? String, "peca Prateleira interna", "toque na prateleira escolhe só ela")
        XCTAssertEqual(o["marca"] as? Bool, true, "a peça escolhida fica marcada")
        XCTAssertEqual(o["prat"] as? String, "[{\"t\":\"mal\",\"h\":400},{\"t\":\"nic\",\"h\":700},{\"t\":\"cabl\",\"h\":1170}] 1", "só a prateleira sai, o módulo fica")
        XCTAssertEqual(o["porta"] as? String, "3 1", "só uma porta sai")
        XCTAssertEqual((o["corte"] as? NSNumber)?.intValue, 3, "a porta sai do corte também")
        XCTAssertEqual(o["voltar"] as? Bool, true)
        XCTAssertEqual((o["voltou"] as? NSNumber)?.intValue, 4, "↺ volta as peças")
        XCTAssertEqual((o["limpou"] as? NSNumber)?.intValue, 0, "trocar a frente do vão devolve as peças dele")
        XCTAssertEqual(o["botao3d"] as? Bool, true)
        XCTAssertEqual(o["base"] as? String, "0 1", "no 3D apaga só a peça")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Torre do forno: a porta de cada vão muda (1 ou 2, dobradiça, mais uma porta, gavetas, sem porta) sem tirar o forno —
    /// na aba Portas e nos 2 toques; caixa da geladeira: portas do aéreo (1, 2 ou sem porta).
    func testTorreDoFornoTrocaAPortaDeCadaVaoEGeladeira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='cozinha';S.room='cozinha';S.W=3500;S.H=2600;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='alto'})[0],T=function(n){return JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n===n})[0]))};newTpl(T('Torre forno + micro-ondas (embutir)'));var m=S.m,v=m.v[0];S.tab=3;S.sv=0;draw();panel();
          var Q=function(a){var b=document.querySelector('#bd [data-twd="0|0|'+a+'"]');if(!b)return 'sem '+a;b.click();return 'ok'};R.conv=Q('conv');
          R.a=[Q('n|0|2'),Q('add|0'),Q('n|1|1'),Q('hg|1|r'),Q('k|4|drw'),Q('dn|4|1'),Q('fr|3|porta')].join(',');
          R.tw=v.tw.map(function(t){return t.k+(t.n||'')+(t.hg||'')+(t.fr||'')}).join(',');R.forno=partsOf(m).filter(function(p){return /^Corte do (forno|micro)/.test(p.name)}).length;
          R.portas=partsOf(m).filter(function(p){return p.name==='Porta'}).map(function(p){return p.hinge}).join('');
          vmenuOpen(0,0,100,100);var vt=document.getElementById('vmtw');R.menu=!!vt&&/Só este vão da torre/.test(vt.textContent);
          var bk=document.querySelector('#vmtw [data-twd*="|add|"]');var n0=v.tw.length;bk.click();R.mais=v.tw.length-n0;R.fechou=!document.getElementById('vmenu');
          S.mods=[];newTpl(T('Caixa da geladeira duplex / inverse (laterais + aéreo)'));m=S.m;S.tab=3;draw();panel();var P=function(){return partsOf(m).filter(function(p){return p.name==='Porta'}).length};
          document.querySelector('#bd [data-geln="1"]').click();R.g1=P();document.querySelector('#bd [data-geln="0"]').click();R.g0=P()+m.v[0].k;document.querySelector('#bd [data-geln="2"]').click();R.g2=P();
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["conv"] as? String, "ok", "torre antiga vira torre por vãos pra trocar a porta")
        XCTAssertEqual(o["a"] as? String, "ok,ok,ok,ok,ok,ok,ok")
        XCTAssertEqual(o["tw"] as? String, "door2,door1r,micro,fornoporta,drw3", "cada vão com a sua porta; forno e micro continuam")
        XCTAssertEqual((o["forno"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual(o["menu"] as? Bool, true, "2 toques no vão da torre: só aquele vão")
        XCTAssertEqual((o["mais"] as? NSNumber)?.intValue, 1, "mais uma porta")
        XCTAssertEqual(o["fechou"] as? Bool, true)
        XCTAssertEqual((o["g1"] as? NSNumber)?.intValue, 1)
        XCTAssertEqual(o["g0"] as? String, "0gel", "sem porta continua caixa da geladeira")
        XCTAssertEqual((o["g2"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Painel novo pergunta a parede (fundo, esquerda, direita), muda de parede e faz cópia separada em outra parede (sala).
    func testPainelEmOutraParedeMudaECopia() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='livre';S.room='sala';S.W=3800;S.H=2700;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='sala'})[0],ix=c.it.findIndex(function(q){return q.act==='pl'});catOpen();await new Promise(function(r){setTimeout(r,80)});document.querySelector('#catm [data-cati="sala|'+ix+'"]').click();await new Promise(function(r){setTimeout(r,250)});
          var M=document.getElementById('rwm');R.pergunta=!!M&&!M.hidden&&/Em qual parede vai o painel/.test(M.textContent);var a=S.rp[0];document.querySelector('#rwm [data-rwg="'+a.id+'|m|e"]').click();R.esq=a.wall+' '+(a.x+a.w<=roomD());
          rwAsk(a.id);document.querySelector('#rwm [data-rwg="'+a.id+'|c|d"]').click();rwAsk(a.id);document.querySelector('#rwm [data-rwg="'+a.id+'|c|f"]').click();R.paredes=S.rp.map(function(q){return q.wall||'f'}).join('');
          var G=cutGroups();R.corte=G.ord.filter(function(k){return /painel liso/i.test(G.map[k].names[0])}).reduce(function(s,k){return s+G.map[k].qty},0);
          LAST='rp';RPSEL=S.rp[2].id;draw();rpBar();R.barra=!!document.querySelector('#rpbar [data-rwq]');
          open3D();await new Promise(function(r){setTimeout(r,400)});__build();var B=__boxes();R.b3=['e','d'].map(function(w){var q=S.rp.filter(function(x){return x.wall===w})[0];return B.some(function(b){return b.rpid===q.id})}).join(',');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["pergunta"] as? Bool, true, "painel novo pergunta a parede")
        XCTAssertEqual(o["esq"] as? String, "e true", "foi pra parede da esquerda, cabe nela")
        XCTAssertEqual(o["paredes"] as? String, "edf", "cópias separadas na direita e no fundo")
        XCTAssertEqual((o["corte"] as? NSNumber)?.intValue, 3, "cada painel com o seu corte")
        XCTAssertEqual(o["barra"] as? Bool, true, "dá pra mudar de parede tocando no painel")
        XCTAssertEqual(o["b3"] as? String, "true,true", "aparece no 3D nas paredes do lado")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Toque nas gavetas abre os ajustes: quantidade e altura da caixa de todas (centralizada na frente), também no caixote;
    /// catálogo: sala com torres tipo guarda-roupa, cada ambiente só com o que serve e mais modelos.
    func testGavetasAjustesNoToqueECatalogoOrganizado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='cozinha';S.room='cozinha';S.W=3500;S.H=2600;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='inf'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Gaveteiro 4 gavetas'})[0])));var m=S.m;draw();
          var p=partsOf(m).filter(function(q){return q.name==='Frente de gaveta'})[1];window.__pcWas=m;pcTap(m,p);var B=function(a){var b=document.querySelector('#gvbox [data-gv="'+a+'"]');if(b)b.click();return !!b};R.abriu=!document.getElementById('gvbox').hidden;
          B('h|10');var g=gbox(m.v[0],vaoRanges(m)[0][1]-vaoRanges(m)[0][0],drawerH(m.v[0]),m.d);R.alta=m.v[0].gH+' '+(Math.abs(g.ft-g.fb)<0.6);B('h|-10');B('h|-10');g=gbox(m.v[0],vaoRanges(m)[0][1]-vaoRanges(m)[0][0],drawerH(m.v[0]),m.d);R.baixa=(m.v[0].gH<R.alta.split(' ')[0]*1)+' '+(Math.abs(g.ft-g.fb)<0.6);
          B('n|1');R.n=m.v[0].n;B('auto');R.auto=m.v[0].gH===undefined;B('x');R.fechou=document.getElementById('gvbox').hidden;
          S.mods=[];S.room='quarto';S.env='livre';var cq=CATS.filter(function(x){return x.id==='quarto'})[0];newTpl(JSON.parse(JSON.stringify(cq.it.filter(function(q){return /^Torre do guarda-roupa/.test(q.n)})[0])));m=S.m;gvOpenK(0,0,2);B('h|-10');R.cx=m.v[0].int[2].gH>0&&partsOf(m).some(function(q){return /^Caixote · gaveta · lateral/.test(q.name)});
          R.sala=ROOMCATS.sala.slice(0,2).join(',')+' '+CATS.filter(function(x){return x.id==='salaT'})[0].it.length;var Lq_=ROOMCATS.quarto.filter(function(c){return c!=='recent'&&c!=='mine'&&!/^uc_/.test(c)});R.quarto=Lq_[0]+' '+(Lq_.indexOf('alto')>Lq_.indexOf('dArm'))+' '+(Lq_.indexOf('cchur')===Lq_.length-1);
          S.mods=[];S.room='sala';var cs=CATS.filter(function(x){return x.id==='salaT'})[0];newTpl(JSON.parse(JSON.stringify(cs.it.filter(function(q){return !q.free0})[0])));S.tab=2;S.sv=0;panel();R.chaves=[].map.call(document.querySelectorAll('#bd [data-intadd]'),function(b){return b.dataset.intadd}).join(',');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["abriu"] as? Bool, true, "toque na gaveta abre os ajustes")
        XCTAssertTrue(((o["alta"] as? String) ?? "").hasSuffix(" true"), "caixa centralizada na frente")
        XCTAssertEqual(o["baixa"] as? String, "true true", "diminui todas e continua centralizada")
        XCTAssertEqual((o["n"] as? NSNumber)?.intValue, 5)
        XCTAssertEqual(o["auto"] as? Bool, true)
        XCTAssertEqual(o["fechou"] as? Bool, true)
        XCTAssertEqual(o["cx"] as? Bool, true, "caixote do guarda-roupa também")
        XCTAssertEqual(o["sala"] as? String, "sala,salaT 9", "torres tipo guarda-roupa na sala (8 + armário livre)")
        XCTAssertEqual(o["quarto"] as? String, "quarto true true", "no quarto, torre de forno e churrasqueira ficam no fim da lista")
        XCTAssertEqual(o["chaves"] as? String, "mal,nic,cab,cabl,cxg,sap", "torre da sala monta igual guarda-roupa")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// 🧠 Cérebro: revisão anti-erros (forno solto na frente da porta vira torre com nicho, porta tempero no banheiro),
    /// aprende o costume dos projetos (maleiro e fundo) só no aparelho; parede do painel no desenho 3D com largura e altura;
    /// porta com cava = vão + 30 (passa 20 em cima e 10 embaixo); armário livre do zero.
    func testCerebroAntiErrosAprendeCostumeEParedeEmTresD() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};PR.brain={p:{},ign:{}};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.env='cozinha';S.room='cozinha';S.W=5610;S.H=2600;S.Hm=1;S.Wm=1;S.ambOk=1;draw();
          var c=CATS.filter(function(x){return x.id==='alto'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Armário alto 2 portas'})[0])));var m=S.m;m.w=800;m.h=2600;m.x=2000;draw();
          var P=partsOf(m).filter(function(p){return p.name==='Porta'})[0];R.cava=Math.round(P.h-vhm(m))+' '+Math.round(vTop(m)-P.y);
          apAdd('microondas',apModels('microondas').findIndex(function(q){return /ME3EP/.test(q[0])}));var f1=S.fr[S.fr.length-1];f1.x=2130;f1.b=1170;apAdd('forno',0);var f2=S.fr[S.fr.length-1];f2.x=2100;f2.b=453;draw();
          var L=brainIssues();R.acha=L.filter(function(q){return q.id==='eletro.porta'}).length;brainOpen();var b=[].filter.call(document.querySelectorAll('#brainm [data-brf]'),function(x){return /torre/.test(x.textContent)})[0];b.click();R.torre=m.v[0].k+' '+m.v[0].tw.map(function(t){return t.k}).join(',')+' '+S.fr.length;document.getElementById('brainm').hidden=true;
          S.mods=[];S.fr=[];S.room='banho';var cb=CATS.filter(function(x){return x.id==='banho'})[0];newTpl(JSON.parse(JSON.stringify(cb.it.filter(function(q){return q.n==='Gabinete 2 portas'})[0])));S.m.v[0].k='tempero';R.banho=brainIssues().map(function(q){return q.id}).join(',');vmenuOpen(0,0,100,100);R.semForno=!document.querySelector('#vmenu [data-vk="oven"]')&&!document.querySelector('#vmenu [data-vk="tempero"]')||S.m.v[0].k==='tempero';vmenuClose();
          /* aprende: 2 projetos com maleiro 450 → o próximo maleiro já vem com 450 */S.room='quarto';S.env='livre';var cq=CATS.filter(function(x){return x.id==='quarto'})[0];['p1','p2'].forEach(function(k){S.mods=[];newTpl(JSON.parse(JSON.stringify(cq.it.filter(function(q){return q.n==='Guarda-roupa 2 vãos'})[0])));S.m.v[0].int=[{t:'mal',h:450},{t:'cab',h:1820}];PR.brain.p[k]={t:Date.now(),f:(function(){var CUR0=window.CUR;return null})()}});
          PR.brain.p={p1:{t:1,f:['mal=450','d.quarto.alto=600']},p2:{t:2,f:['mal=450','d.quarto.alto=600']}};R.costume=(brainHabit('mal')||{}).v+' '+(brainHabit('d.quarto.alto')||{}).v;
          S.mods=[];newTpl(JSON.parse(JSON.stringify(cq.it.filter(function(q){return q.n==='Guarda-roupa 2 vãos'})[0])));m=S.m;S.sv=0;var at=ibAdd(m,0,'mal');R.malAprendido=Math.round(m.v[0].int[at].h);R.foge=brainIssues().some(function(q){return q.id==='hab.d.alto'});
          /* parede do painel: desenho 3D das 3 paredes e o tamanho da parede */S.room='sala';S.mods=[];var a=rpNew({x:100,b:0,w:1800,h:2400});a.liso=true;rwAsk(a.id,true);var g=document.querySelector('#rwm [data-rwp="'+a.id+'|d"]');g.dispatchEvent(new MouseEvent('click',{bubbles:true}));var inp=document.querySelector('#rwm [data-rwz="'+a.id+'|L"]');inp.value='3100';inp.dispatchEvent(new Event('change',{bubbles:true}));R.parede=a.wall+' '+wallCfg('R').len;document.querySelector('#rwm [data-rwx]').click();
          var cs=CATS.filter(function(x){return x.id==='salaT'})[0];R.livre=cs.it[0].free0===1&&/montar do zero/.test(cs.it[0].n);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cava"] as? String, "30 25", "porta com cava: vão + 30, passa 20 em cima (mais a travessa)")
        XCTAssertEqual((o["acha"] as? NSNumber)?.intValue, 2, "acha o forno e o micro soltos na frente da porta")
        XCTAssertEqual(o["torre"] as? String, "oven door,micro,forno,door 0", "1 toque vira torre com nicho")
        XCTAssertEqual(o["banho"] as? String, "room.tempero", "porta tempero no banheiro não faz sentido")
        XCTAssertEqual(o["semForno"] as? Bool, true)
        XCTAssertEqual(o["costume"] as? String, "450 600", "aprende o que se repete")
        XCTAssertEqual((o["malAprendido"] as? NSNumber)?.intValue, 450, "maleiro novo já vem no costume")
        XCTAssertEqual(o["foge"] as? Bool, true, "avisa quando foge do costume")
        XCTAssertEqual(o["parede"] as? String, "d 3100", "escolhe a parede no desenho e muda a largura dela")
        XCTAssertEqual(o["livre"] as? Bool, true, "armário livre do zero")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testDetalhamento3DComSetasESalvarModuloNaCategoriaERecentes() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};PR.myMods=[];PR.myCats=[];PR.recent=[];S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.ops=[];S.env='cozinha';S.room='cozinha';S.W=4200;S.H=2600;S.Hm=1;S.Wm=1;S.ambOk=1;draw();
          /* recentes: o que entrou pelo catálogo aparece primeiro, do mais novo pro mais velho */
          catOpen('inf');document.querySelector('[data-cati="inf|0"]').click();catOpen('inf');document.querySelector('[data-cati="inf|3"]').click();
          catOpen();R.primeira=(document.querySelector('#catb [data-catt]')||{dataset:{}}).dataset.catt;catOpen('recent');R.recentes=document.querySelectorAll('#catgw [data-cati]').length;var n0=S.mods.length;document.querySelector('#catgw [data-cati="recent|1"]').click();R.usa=S.mods.length-n0;
          /* pedra e aéreo pra ter cotas */addStone();var x1=0;S.mods.forEach(function(m){x1=Math.max(x1,m.x+m.w)});S.st.x=0;S.st.w=x1;var cs=CATS.filter(function(x){return x.id==='sup'})[0];newTpl(JSON.parse(JSON.stringify(cs.it.filter(function(q){return q.n==='Aéreo 2 portas'})[0])));draw();
          open3D();await new Promise(function(r){setTimeout(r,700)});document.getElementById('v3det').click();await new Promise(function(r){setTimeout(r,400)});var sv=document.getElementById('det3svg');
          R.setas=sv.querySelectorAll('marker').length>0&&sv.querySelectorAll('line[marker-start][marker-end]').length>=3;R.chamada=sv.querySelectorAll('line[stroke-opacity]').length>0;
          var tx=[].map.call(sv.querySelectorAll('text'),function(t){return t.textContent});R.alturas=['820','40'].every(function(v){return tx.indexOf(v)>=0});R.parede=tx.indexOf('parede 4200')>=0;R.nome=tx.indexOf('módulo')>=0;
          window.det3Mode('c');tx=[].map.call(sv.querySelectorAll('text'),function(t){return t.textContent});R.doChao=tx.indexOf('+860')>=0&&tx.indexOf('+820')>=0;window.det3Stop();
          /* salvar o módulo escolhendo a categoria (inclusive uma nova) */
          S.m=S.mods[0];window.mySaveOpen(S.m);document.getElementById('myname').value='Balcão do João';document.querySelector('#mysvb [data-myall]').click();R.todas=document.querySelectorAll('#mysvb [data-mycat]').length;
          document.querySelector('#mysvb [data-mynew]').click();document.getElementById('mynewc').value='Padrão da loja';document.querySelector('#mysvb [data-mynewok]').click();document.querySelector('#mysvb [data-myok]').click();
          var uc=(PR.myCats[0]||{}).id;R.cat=PR.myMods.length===1&&PR.myMods[0].cat===uc;
          catOpen();R.chips=[].map.call(document.querySelectorAll('#catb [data-catt]'),function(b){return b.dataset.catt}).slice(0,3).join(',').replace(uc,'uc');
          catOpen(uc);document.querySelector('#catgw [data-cati="'+uc+'|0"]').click();R.entrou=S.m.myN;
          window.myManage();var se=document.querySelector('#mysvb select[data-mycs]');se.value='alto';se.dispatchEvent(new Event('change',{bubbles:true}));R.muda=PR.myMods[0].cat;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["primeira"] as? String, "recent", "usados por último vem primeiro no catálogo")
        XCTAssertEqual((o["recentes"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((o["usa"] as? NSNumber)?.intValue, 1, "o recente entra igual ao original")
        XCTAssertEqual(o["setas"] as? Bool, true, "cota com seta nas duas pontas")
        XCTAssertEqual(o["chamada"] as? Bool, true, "linha de chamada saindo da peça")
        XCTAssertEqual(o["alturas"] as? Bool, true)
        XCTAssertEqual(o["parede"] as? Bool, true)
        XCTAssertEqual(o["nome"] as? Bool, true, "diz o que é cada medida")
        XCTAssertEqual(o["doChao"] as? Bool, true, "altura de cada nível a partir do chão")
        XCTAssertGreaterThanOrEqual((o["todas"] as? NSNumber)?.intValue ?? 0, 16, "pode escolher qualquer categoria")
        XCTAssertEqual(o["cat"] as? Bool, true, "salva na categoria nova")
        XCTAssertEqual(o["chips"] as? String, "recent,mine,uc")
        XCTAssertEqual(o["entrou"] as? String, "Balcão do João")
        XCTAssertEqual(o["muda"] as? String, "alto", "troca a categoria depois")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testAjustesEm3DNoModuloDoProjetoComLupaEAntesTracejado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.stones=[];S.fr=[];S.env='cozinha';S.room='cozinha';S.W=3000;draw();
          var c=CATS.filter(function(x){return x.id==='inf'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Balcão 2 portas'})[0])));S.m.w=800;draw();
          stdOpen(0);await new Promise(function(r){setTimeout(r,300)});
          R.cards=[].map.call(document.querySelectorAll('#stdbody [data-aj3]'),function(e){return e.dataset.aj3}).join(',');
          var inp=document.querySelector('#stdbody [data-stdn="pSn"]');inp.focus();inp.dispatchEvent(new FocusEvent('focusin',{bubbles:true}));await new Promise(function(r){setTimeout(r,150)});
          var cd=document.querySelector('#stdbody [data-aj3="portas"]');R.real=/No seu projeto/.test(cd.textContent);R.vermelho=cd.querySelectorAll('polygon[stroke="#d92d20"]').length>0;R.lupa=!!cd.querySelector('clipPath')&&/^6$/.test((cd.querySelector('g[clip-path] text')||{}).textContent||'');
          var fl=document.getElementById('cfgfloat');R.topo=!!(fl&&fl.querySelector('[data-aj3svg]'));
          inp.value='9';inp.dispatchEvent(new Event('input',{bubbles:true}));cd=document.querySelector('#stdbody [data-aj3="portas"]');R.antes=/antes/.test(cd.textContent)&&cd.querySelectorAll('polygon[stroke-dasharray]').length>0;R.lupa9=(cd.querySelector('g[clip-path] text')||{}).textContent;
          STD().pSn=6;var g=document.querySelector('#stdbody [data-aj3="gavetas"] [data-aj3svg]');R.gaveta=!!g;window.CFGHL='baseH';R.alturas=/820/.test(aj3Html('alturas'));
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cards"] as? String, "portas,gavetas,puxadores,caixa,tamp,pedra,alturas", "3D em cada seção")
        XCTAssertEqual(o["real"] as? Bool, true, "mostra o módulo do projeto")
        XCTAssertEqual(o["vermelho"] as? Bool, true, "a peça que muda em vermelho")
        XCTAssertEqual(o["lupa"] as? Bool, true, "lupa com a medida pequena")
        XCTAssertEqual(o["topo"] as? Bool, true, "3D no quadro preso no topo enquanto digita")
        XCTAssertEqual(o["antes"] as? Bool, true, "antes tracejado quando muda")
        XCTAssertEqual(o["lupa9"] as? String, "9")
        XCTAssertEqual(o["gaveta"] as? Bool, true)
        XCTAssertEqual(o["alturas"] as? Bool, true)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testFolgaNoMeioDasDuasPortasELadoComDesenhoNoModulo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.env='cozinha';S.room='cozinha';S.W=3000;draw();
          var c=CATS.filter(function(x){return x.id==='inf'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Balcão 2 portas'})[0])));newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return q.n==='Balcão 2 portas'})[0])));S.m=S.mods[0];S.tab=3;S.sv=0;draw();panel();
          R.semNoModulo=!document.getElementById('pgbox');window.PGBOX=1;panel();
          var bx=document.getElementById('pgbox');R.caixa=!!bx&&!!bx.querySelector('svg circle')&&/folga no meio/.test(bx.textContent)&&/passa no lado/.test(bx.textContent);
          var D=function(m){return partsOf(m).filter(function(p){return p.name==='Porta'}).sort(function(a,b){return a.x-b.x})};
          document.querySelector('#pgbox [data-pg="g|3"]').click();var d=D(S.mods[0]);R.meio=Math.round((d[1].x-(d[0].x+d[0].w))*10)/10;R.lupa=/3 mm/.test(document.getElementById('pgbox').textContent);
          document.querySelector('#pgbox [data-pg="g|0"]').click();d=D(S.mods[0]);R.encostadas=Math.round((d[1].x-(d[0].x+d[0].w))*10)/10;
          var i=document.querySelector('#pgbox [data-pgi="g"]');i.value='1';i.dispatchEvent(new Event('change',{bubbles:true}));d=D(S.mods[0]);R.digitou=Math.round((d[1].x-(d[0].x+d[0].w))*10)/10;
          document.querySelector('#pgbox [data-pg="s|5"]').click();d=D(S.mods[0]);var vr=vaoRanges(S.mods[0])[0];R.lado=Math.round((vr[0]-d[0].x)*10)/10;
          R.outro=S.mods[1].pGap;document.querySelector('#pgbox [data-pg="all|1"]').click();R.todas=S.mods[1].pGap+' '+S.mods[1].pSn;
          document.querySelector('#pgbox [data-pg="std|1"]').click();R.padrao=STD().pGap+' '+STD().pSn;
          S.mods[0].v[0].n=1;draw();panel();R.uma=!!document.querySelector('#pgbox [data-pg^="s1|"]')&&!document.querySelector('#pgbox [data-pg^="g|"]');window.PGBOX=0;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semNoModulo"] as? Bool, true, "folgas da porta ficam só nos Ajustes, não no painel do módulo")
        XCTAssertEqual(o["caixa"] as? Bool, true, "desenho com as lupas do meio e do lado")
        XCTAssertEqual((o["meio"] as? NSNumber)?.doubleValue, 3, "folga de 3 mm no meio")
        XCTAssertEqual(o["lupa"] as? Bool, true)
        XCTAssertEqual((o["encostadas"] as? NSNumber)?.doubleValue, 0)
        XCTAssertEqual((o["digitou"] as? NSNumber)?.doubleValue, 1, "digita a folga que quiser")
        XCTAssertEqual((o["lado"] as? NSNumber)?.doubleValue, 5, "passa 5 mm no lado")
        XCTAssertEqual((o["outro"] as? NSNumber)?.intValue, 2, "o outro módulo não muda sozinho")
        XCTAssertEqual(o["todas"] as? String, "1 5", "usar em todas as portas do projeto")
        XCTAssertEqual(o["padrao"] as? String, "1 5", "guardar como padrão")
        XCTAssertEqual(o["uma"] as? Bool, true, "1 porta: só o lado")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testSobraQueEuTenhoEntraNoPlanoDeCorteETrocaChapaInteira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};PR.metodo='max';PR.veio=false;S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.sobras=[];S.env='cozinha';S.W=5000;S.ambOk=1;draw();addStone();S.st.w=4600;draw();var R={};
          var c=CATS.filter(function(x){return x.id==='inf'})[0];[0,3,5,0,3].forEach(function(i){newTpl(JSON.parse(JSON.stringify(c.it[i])))});draw();
          var cnt=function(p){return p.groups.reduce(function(a,g){return a+g.sheets.reduce(function(b,s){return b+s.used.length},0)},0)},pl0=sheetPlan(),gb=pl0.groups.filter(function(g){return g.t==='b'})[0];R.antes=gb.n;
          /* no cabeçalho do plano: todas as chapas em fila, minimizadas, e o botão da sobra */
          openCut();await new Promise(function(r){setTimeout(r,400)});var B=function(){return document.getElementById('sobbar')};R.fila=!!B()&&B().querySelectorAll('[data-cgo]').length===pl0.groups.reduce(function(a,g){return a+g.sheets.length},0);
          B().querySelector('[data-sobadd]').click();R.chips=B().querySelectorAll('[data-sobg] svg').length===pl0.groups.length;B().querySelector('[data-sobg="'+gb.key+'"]').click();
          var iw=B().querySelector('[data-sobf="w"]'),ih=B().querySelector('[data-sobf="h"]');iw.value='1500';iw.dispatchEvent(new Event('input',{bubbles:true}));ih.value='1800';ih.dispatchEvent(new Event('input',{bubbles:true}));B().querySelector('[data-sobok]').click();await new Promise(function(r){setTimeout(r,300)});
          R.sobra=JSON.stringify(S.sobras.map(function(b){return [b.k===gb.key,b.w,b.h,b.q,b.on]}));
          /* recalcula em cima dela: entra primeiro, as peças continuam todas no plano e sai uma chapa inteira a menos */
          var pl=sheetPlan(),g=pl.groups.filter(function(x){return x.key===gb.key})[0];R.depois=g.n0+'>'+g.n+' sob '+g.nSob+' '+(!!g.sheets[0].sob&&g.sheets[0].used.length>3);R.pecas=cnt(pl)===cnt(pl0);
          R.dentro=g.sheets[0].used.every(function(u){return u.x>=0&&u.y>=0&&u.x+u.w<=1500-2*pl.ref+.5&&u.y+u.h<=1800-2*pl.ref+.5});
          R.desenho=!!document.getElementById('cs'+pl.groups.indexOf(g)+'_0')&&/SOBRA/.test(document.getElementById('cs'+pl.groups.indexOf(g)+'_0').textContent);
          /* por comprimento e por largura também */
          PR.metodo='comp';var pc=sheetPlan().groups.filter(function(x){return x.key===gb.key})[0];PR.metodo='larg';var pg=sheetPlan().groups.filter(function(x){return x.key===gb.key})[0];PR.metodo='max';R.metodos=pc.sheets[0].ms+' '+pg.sheets[0].ms+' '+pc.nSob+pg.nSob;
          /* o orçamento continua com as chapas inteiras; a sobra fica no projeto */
          R.orcamento=sheetPlan(1).groups.filter(function(x){return x.key===gb.key})[0].n===R.antes;R.salva=(snapState().sobras||[]).length;
          /* pausar e tirar */
          openCut();await new Promise(function(r){setTimeout(r,300)});B().querySelector('[data-sobon]').click();R.pausou=sheetPlan().groups.filter(function(x){return x.key===gb.key})[0].nSob;
          openCut();await new Promise(function(r){setTimeout(r,300)});var dl=B().querySelector('[data-sobdel]');dl.click();R.confirma=S.sobras.length;dl=B().querySelector('[data-sobdel]');dl.click();R.tirou=S.sobras.length;
          document.getElementById('cutm').hidden=true;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["fila"] as? Bool, true, "todas as chapas minimizadas em fila no cabeçalho")
        XCTAssertEqual(o["chips"] as? Bool, true, "escolhe de qual chapa é pelo desenho pequeno")
        XCTAssertEqual(o["sobra"] as? String, "[[true,1500,1800,1,1]]", "sobra branca 1500 × 1800 guardada")
        XCTAssertEqual(o["depois"] as? String, "\((o["antes"] as? NSNumber)?.intValue ?? 0)>\(((o["antes"] as? NSNumber)?.intValue ?? 1) - 1) sob 1 true", "a sobra troca uma chapa inteira")
        XCTAssertEqual(o["pecas"] as? Bool, true, "nenhuma peça some")
        XCTAssertEqual(o["dentro"] as? Bool, true, "as peças cabem na sobra (com o refilo)")
        XCTAssertEqual(o["desenho"] as? Bool, true, "a sobra aparece desenhada no plano")
        XCTAssertEqual(o["metodos"] as? String, "comp larg 11", "por comprimento e por largura também")
        XCTAssertEqual(o["orcamento"] as? Bool, true, "orçamento com as chapas inteiras")
        XCTAssertEqual((o["salva"] as? NSNumber)?.intValue, 1, "fica salva no projeto")
        XCTAssertEqual((o["pausou"] as? NSNumber)?.intValue, 0, "pausar tira do plano")
        XCTAssertEqual((o["confirma"] as? NSNumber)?.intValue, 1, "tirar pede o segundo toque")
        XCTAssertEqual((o["tirou"] as? NSNumber)?.intValue, 0)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testMeusModelosSalvosNoCatalogoEDivisorDeTalheresModelo1e2() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};PR.myMods=[];S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.env='cozinha';S.W=3000;S.ambOk=1;draw();addStone();draw();var R={};
          /* monta do zero pelo catálogo (Inferiores > Módulo vazio): o módulo guarda de qual categoria veio */
          catOpen('inf');var c=CATS.filter(function(x){return x.id==='inf'})[0],iz=c.it.map(function(it){return it.n}).indexOf('Módulo vazio (montar do zero)');document.querySelector('#catm [data-cati="inf|'+iz+'"]').click();await new Promise(function(r){setTimeout(r,60)});
          var m=S.m;R.cat0=m.cat0;m.w=600;m.div=[0.45];m.v=[{k:'door',n:1,cava:true},{k:'drawers',n:3,cava:true}];draw();
          /* divisor de talheres: escolher o modelo já põe na gaveta 1; modelo 1 sem a atravessada, modelo 2 com */
          S.tab=2;S.sv=1;panel();var b1=document.querySelector('[data-dtk="1"]');R.previas=document.querySelectorAll('[data-dtk] svg').length;if(b1)b1.click();R.dt1=JSON.stringify(m.v[1].dt)+' '+m.v[1].dtk;
          var cruz=function(){return partsOf(m).filter(function(p){return p.name==='Divisor de talheres · divisória'&&p.w>200}).length};var emPe=function(){return partsOf(m).filter(function(p){return p.name==='Divisor de talheres · divisória'&&p.w<10}).length};
          R.m1=cruz()+' '+emPe()+' '+(partsOf(m).filter(function(p){return /^Divisor de talheres \(gaveta 1\) · modelo 1/.test(p.name)}).length);
          document.querySelector('[data-dtk="2"]').click();R.m2=cruz()+' '+emPe()+' '+m.v[1].dtk;document.querySelector('[data-dtk="1"]').click();
          /* salvar com nome: aparece primeiro no catálogo (⭐) e a lupa acha */
          S.tab=0;panel();document.querySelector('[data-msave]').click();var nm=document.getElementById('myname');R.sugere=!!nm&&nm.value.length>3;R.catSel=[].slice.call(document.querySelectorAll('#mysv [data-mycat]')).filter(function(b){return /✓/.test(b.textContent)}).map(function(b){return b.dataset.mycat}).join();
          nm.value='Gaveteiro com talher';document.querySelector('[data-myok]').click();var sv=PR.myMods[0];R.salvo=PR.myMods.length+' '+sv.n+' '+sv.cat+' '+sv.t.w+' '+sv.t.v[1].dtk+' '+(sv.t.x===undefined);R.guardado=/Gaveteiro com talher/.test(localStorage.getItem(PRK)||'');
          catOpen('inf');var cards=[].slice.call(document.querySelectorAll('#catm .catc'));R.primeiro=cards.length&&/⭐ Gaveteiro com talher/.test(cards[0].textContent);R.grupo=(document.querySelector('#catm .catgh')||{}).textContent;
          window.CATQ='talher';document.getElementById('catgw').innerHTML=catGrid(window.CATC);R.lupa=[].slice.call(document.querySelectorAll('#catgw .catc')).some(function(b){return /Gaveteiro com talher/.test(b.textContent)});window.CATQ='';catOpen('inf');
          /* usar: entra igual (porta, 3 gavetas, divisor modelo 1 na gaveta 1) e dá pra mudar só a medida */
          var n0=S.mods.length;[].slice.call(document.querySelectorAll('#catm .catc')).filter(function(b){return /Gaveteiro com talher/.test(b.textContent)})[0].click();await new Promise(function(r){setTimeout(r,60)});
          var n=S.mods[S.mods.length-1];R.entrou=(S.mods.length-n0)+' '+JSON.stringify(n.div)+' '+n.v.map(function(v){return v.k+(v.n||'')+(v.dt?':'+v.dt.join()+'m'+v.dtk:'')}).join(',')+' '+(n.v!==m.v);
          n.w=800;draw();R.esticou=partsOf(n).filter(function(p){return /^Divisor de talheres \(gaveta 1\)/.test(p.name)}).length===1;
          /* salvar de novo com o mesmo nome atualiza (não duplica); mudar nome e apagar */
          window.mySaveOpen(n);document.getElementById('myname').value='Gaveteiro com talher';document.querySelector('[data-myok]').click();R.atualiza=PR.myMods.length+' '+PR.myMods[0].t.w;
          window.myManage();var ren=document.querySelector('#mysv [data-myren]');ren.value='Gaveteiro talher 80';ren.dispatchEvent(new Event('change',{bubbles:true}));R.renomeou=PR.myMods[0].n;
          var del=document.querySelector('#mysv [data-mydel]');del.click();R.confirma=PR.myMods.length;del=document.querySelector('#mysv [data-mydel]');del.click();R.apagou=PR.myMods.length+' '+CATS.filter(function(x){return x.id==='inf'})[0].it.some(function(it){return it.my});
          document.getElementById('mysv').hidden=true;var cm=document.getElementById('catm');if(cm)cm.hidden=true;PR.myMods=[];prSave();
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cat0"] as? String, "inf", "módulo do zero sabe que veio dos inferiores da cozinha")
        XCTAssertEqual((o["previas"] as? NSNumber)?.intValue, 2, "os dois modelos com desenho de prévia")
        XCTAssertEqual(o["dt1"] as? String, "[0] 1", "escolher o modelo já põe na gaveta 1")
        XCTAssertEqual(o["m1"] as? String, "0 2 1", "modelo 1: só divisórias em pé")
        XCTAssertEqual(o["m2"] as? String, "1 2 2", "modelo 2: com a atravessada no fundo")
        XCTAssertEqual(o["sugere"] as? Bool, true, "sugere um nome")
        XCTAssertEqual(o["catSel"] as? String, "inf", "aparece na mesma categoria de onde veio")
        XCTAssertEqual(o["salvo"] as? String, "1 Gaveteiro com talher inf 600 1 true", "salvo com nome, categoria e estrutura, sem a posição")
        XCTAssertEqual(o["guardado"] as? Bool, true, "fica guardado no aparelho")
        XCTAssertEqual(o["primeiro"] as? Bool, true, "vem primeiro no catálogo, com ⭐")
        XCTAssertEqual(o["grupo"] as? String, "⭐ Meus modelos")
        XCTAssertEqual(o["lupa"] as? Bool, true, "a lupa acha pelo nome")
        XCTAssertEqual(o["entrou"] as? String, "1 [0.45] door1,drawers3:0m1 true", "entra igual ao salvo")
        XCTAssertEqual(o["esticou"] as? Bool, true, "muda a medida e o divisor acompanha")
        XCTAssertEqual(o["atualiza"] as? String, "1 800", "mesmo nome: atualiza")
        XCTAssertEqual(o["renomeou"] as? String, "Gaveteiro talher 80")
        XCTAssertEqual((o["confirma"] as? NSNumber)?.intValue, 1, "apagar pede o segundo toque")
        XCTAssertEqual(o["apagou"] as? String, "0 false", "apagou e saiu do catálogo")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testCooktopsReaisCincoBocasEColunaArrastadaComAsMedidas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.geo=[];S.xw=[];S.env='cozinha';S.W=3600;S.H=2700;S.RD=3600;S.ambOk=1;draw();addStone();var st=S.st;st.w=2400;draw();var R={};
          /* modelos com a medida real: quantas bocas, onde fica cada uma e o recorte da pedra */
          R.cinco=COOKM.filter(function(q){return q.nb===5}).every(function(q){var t={cm:q.id,w:q.w,d:q.d};return cookNb(t)===5&&cookPos(t).length===5});
          R.batem=COOKM.every(function(q){var t={cm:q.id,w:q.w,d:q.d};return cookPos(t).length===q.nb&&cookLay(t).bz.length===q.nb&&(!q.rc||(q.rc[0]<q.w&&q.rc[1]<q.d))});
          var M=cookM('bdd85');R.bdd85=M.w+'x'+M.d+' '+M.rc.join('x')+' '+M.nb+' '+cookLay({cm:'bdd85',w:M.w,d:M.d}).lay;
          /* sem modelo (ou com a medida mudada) a largura manda: 75 cm sai com 5 bocas */
          R.largura=[cookNb({k:'cook',w:750,d:510}),cookNb({k:'cook',w:580,d:510}),cookNb({k:'cook',w:300,d:500})].join(',');
          var it={id:NID++,k:'cook',x:100,y:50,w:580,d:510};st.items.push(it);it.w=760;draw();R.esticou=cookNb(it)+' '+it.w;
          /* trocar o modelo pelo quadro do cooktop */
          S.items=st.items;S.selI=it.id;S.tab=6;LAST='';draw();panel();showBox();var rbt=document.querySelector('#itbox [data-ckrep]');R.trocarBtn=!!rbt;if(rbt)rbt.click();
          var bx=document.getElementById('ckpk');R.trocaAbre=!!bx&&!bx.hidden&&bx.dataset.rep===String(it.id);var mb=bx&&bx.querySelector('[data-ckm="bdd75"]');if(mb)mb.click();
          R.trocou=it.cm+' '+it.w+'x'+it.d+' '+cookNb(it)+' '+st.items.length;
          /* no 3D: as 5 bocas, as grades e os botões */
          open3D();await new Promise(function(r){setTimeout(r,300)});R.tem3D=__boxes().filter(function(b){return b.ck===st.id+':'+it.id}).length>40;
          /* montar o ambiente: a coluna arrasta na planta do cabeçalho e as medidas até as paredes ficam em volta */
          document.getElementById('v3x').click();S.stones=[];S.items=[];S.st=null;draw();ambSetOpen();await new Promise(function(r){setTimeout(r,300)});var A=document.getElementById('ambset');
          A.querySelector('[data-ambsb="addcol"]').click();var col=A.querySelector('[data-amo="g:0"]');R.planta=!!col&&!!A.querySelector('#ambplan [data-q="ra|L"]');
          var pe=function(el,t,x,y){el.dispatchEvent(new PointerEvent(t,{clientX:x,clientY:y,bubbles:true,cancelable:true,pointerId:7,pointerType:'touch',isPrimary:true}))};
          var g=S.geo[0],x0=g.x,z0=g.z,r=col.getBoundingClientRect(),X=r.left+r.width/2,Y=r.top+r.height/2;pe(col,'pointerdown',X,Y);for(var k=1;k<=6;k++)pe(A,'pointermove',X-k*8,Y);pe(A,'pointerup',X-48,Y);
          R.arrastou=S.geo[0].x<x0&&S.geo[0].z===z0&&S.geo[0].x%10===0;
          /* toca no número da direita e digita: a coluna fica a 1000 da parede direita */
          var lb=A.querySelector('#ambplan [data-q="ra|R"]'),lr=lb.getBoundingClientRect();pe(lb,'pointerdown',lr.left+lr.width/2,lr.top+lr.height/2);pe(lb,'pointerup',lr.left+lr.width/2,lr.top+lr.height/2);
          var qi=document.getElementById('qein');R.quadro=!document.getElementById('qebox').hidden&&/parede direita/.test(document.getElementById('qelab').textContent);qi.value='1000';qi.dispatchEvent(new Event('input',{bubbles:true}));
          R.direita=S.W-S.geo[0].x-S.geo[0].w;document.getElementById('qebox').hidden=true;
          /* no 3D, a medida da coluna escolhida também se toca e digita (com a da frente) */
          var c=org3api.proj([S.geo[0].x+150,1200,S.geo[0].z+150]);org3api.one(c[0],c[1]);await new Promise(function(r){setTimeout(r,150)});
          var l3=document.querySelector('[data-q="rb|F"]');R.frente3D=!!l3;R.quadroEscondido=getComputedStyle(document.getElementById('it4')||document.body).display==='none'||!document.getElementById('it4');
          if(l3){var q3=l3.getBoundingClientRect();pe(l3,'pointerdown',q3.left+5,q3.top+5);pe(l3,'pointerup',q3.left+5,q3.top+5);qi.value='900';qi.dispatchEvent(new Event('input',{bubbles:true}))}R.frente=roomD()-S.geo[0].z-S.geo[0].d;
          document.getElementById('qebox').hidden=true;A.querySelector('[data-ambsb="ok"]').click();
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cinco"] as? Bool, true, "todo cooktop de 5 bocas mostra as 5")
        XCTAssertEqual(o["batem"] as? Bool, true, "bocas, tamanhos e recorte batem com o modelo")
        XCTAssertEqual(o["bdd85"] as? String, "850x460 815x405 5 l", "medida, recorte e a quadrichama do lado")
        XCTAssertEqual(o["largura"] as? String, "5,4,2", "sem modelo, a largura decide as bocas")
        XCTAssertEqual(o["esticou"] as? String, "5 760", "cooktop sem modelo esticado pra 76 cm: 5 bocas")
        XCTAssertEqual(o["trocarBtn"] as? Bool, true, "botão Trocar modelo no quadro do cooktop")
        XCTAssertEqual(o["trocaAbre"] as? Bool, true, "abre a lista pra trocar")
        XCTAssertEqual(o["trocou"] as? String, "bdd75 730x460 5 1", "trocou no mesmo lugar")
        XCTAssertEqual(o["tem3D"] as? Bool, true, "desenha no 3D")
        XCTAssertEqual(o["planta"] as? Bool, true, "planta com a coluna e as medidas")
        XCTAssertEqual(o["arrastou"] as? Bool, true, "arrasta a coluna (de 10 em 10 mm)")
        XCTAssertEqual(o["quadro"] as? Bool, true, "tocar na medida abre o quadro de digitar")
        XCTAssertEqual((o["direita"] as? NSNumber)?.intValue, 1000, "fica a 1000 da parede direita")
        XCTAssertEqual(o["frente3D"] as? Bool, true, "no 3D aparece a medida até a frente")
        XCTAssertEqual(o["quadroEscondido"] as? Bool, true, "na montagem o quadro do 3D não cobre o cabeçalho")
        XCTAssertEqual((o["frente"] as? NSNumber)?.intValue, 900, "digitou no 3D: 900 até a frente")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    func testRodapeDePedraNaFrenteEMontarOAmbienteNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.geo=[];S.xw=[];S.env='cozinha';S.W=3600;S.H=2700;S.Hm=1;S.Wm=1;S.ambOk=1;draw();mkL('e',3600,2000,600,1);draw();var R={};
          var m0=S.mods.filter(function(m){return !m.sup&&!m.corner&&!m.wing})[0],r0=rodRF(m0),lat0=partsOf(m0).filter(function(p){return /Rodapé lateral esquerdo/.test(p.name)})[0];
          /* liga pela regra do módulo: o MDF recua mais 40 e a pedra de 20 vem na frente */
          S.m=m0;S.tab=4;draw();panel();var tg=document.querySelector('#bd [data-rpp="tog"]');if(!tg){S.tab=0;panel();tg=document.querySelector('#bd [data-rpp="tog"]')}R.botao=!!tg;if(tg)tg.click();else S.rpp={on:true};
          R.recuo=rodRF(m0)-r0;var lat1=partsOf(m0).filter(function(p){return /Rodapé lateral esquerdo/.test(p.name)})[0];R.lateral=lat0&&lat1?lat0.cl-lat1.cl:null;
          var P=rppRuns();R.pecas=P.map(function(p){return p.at+':'+p.len+'x'+p.h});
          /* nenhuma entra na outra: as caixas não se sobrepõem e as da frente encostam na do canto (topo a topo) */
          var ov=0;for(var i=0;i<P.length;i++)for(var j=i+1;j<P.length;j++){var a=P[i],b=P[j];if(a.x0<b.x1-0.6&&b.x0<a.x1-0.6&&a.z0<b.z1-0.6&&b.z0<a.z1-0.6)ov++}R.sobrepoe=ov;
          var fr=P.filter(function(p){return p.ax==='x'}),ld=P.filter(function(p){return p.ax==='z'})[0];R.encosta=!!ld&&fr.length>0&&Math.abs(Math.min.apply(null,fr.map(function(p){return p.x0}))-ld.x1)<0.6;
          R.altura=P.every(function(p){return p.h===m0.rodMm});R.max=P.every(function(p){return p.len<=3000});
          /* aba Pedra: cor, medidas e a lista pra marmoraria */
          S.tab=6;S.st=S.stones[0];draw();panel();var bd=document.getElementById('bd');R.secao=!!bd.querySelector('[data-rppv="t"]')&&/Peças pra marmoraria/.test(bd.textContent);
          var c=bd.querySelector('[data-rppc="#27372c"]');if(c)c.click();R.cor=S.rpp.c==='#27372c';var hi=document.querySelector('#bd [data-rppv="h"]');if(hi){hi.value='80';hi.dispatchEvent(new Event('change',{bubbles:true}))}R.h80=rppRuns().every(function(p){return p.h===80});
          R.parte2D=partsOf(m0).some(function(p){return p.rppS&&p.noCut});R.semCorteMDF=!cutLines(m0).some(function(l){return (l.names||[]).some(function(n){return /pedra/i.test(n)})});
          R.salva=(function(){var o=snapState();return o.rpp&&o.rpp.on===true})();
          /* montar o ambiente: ao escolher o ambiente num projeto vazio abre o 3D só da sala, com tudo num cabeçalho */
          S.mods=[];S.stones=[];S.rpp=null;delete S.ambOk;S.tab=9;draw();panel();var rb=document.querySelector('#bd [data-room="cozinha"]');R.btn=!!document.querySelector('#bd [data-ambopen]');if(rb)rb.click();await new Promise(function(r){setTimeout(r,400)});
          var A=document.getElementById('ambset');R.abre=!!A&&!A.hidden&&!!window.AMBSET&&!document.getElementById('v3').hidden;
          var setI=function(k,v){var i=A.querySelector('[data-ambs="'+k+'"]');if(!i)return false;i.value=String(v);i.dispatchEvent(new Event('change',{bubbles:true}));return true},bt=function(k){var x=A.querySelector('[data-ambsb="'+k+'"]');if(x)x.click();return !!x};
          setI('W',4200);setI('RD',3600);setI('H',2750);bt('addcol');bt('addxw');bt('addil');bt('min');setI('g0.x',500);setI('xw0.L',1800);bt('xwdir:0');setI('Rlen',3900);setI('Lh',2600);
          R.medidas=[S.W,S.RD,S.H,S.geo.length,S.geo[0].x,S.geo[0].h,S.xw.length,Math.round(Math.hypot(S.xw[0].b[0]-S.xw[0].a[0],S.xw[0].b[1]-S.xw[0].a[1])),Math.abs(S.xw[0].b[0]-S.xw[0].a[0])<1?'pra frente':'deitada',S.isl.length,wallCfg('R').len,wallCfg('L').h0].join(',');
          R.pisoAcompanha=roomD()>=3900;
          bt('ok');await new Promise(function(r){setTimeout(r,300)});R.pronto=document.getElementById('v3').hidden&&A.hidden&&!window.AMBSET&&S.ambOk===1;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["botao"] as? Bool, true, "liga o rodapé de pedra pela regra do módulo")
        XCTAssertEqual((o["recuo"] as? NSNumber)?.intValue, 40, "o rodapé de MDF recua mais 40 mm")
        XCTAssertEqual((o["lateral"] as? NSNumber)?.intValue, 40, "as peças do lado do pedestal diminuem junto")
        XCTAssertEqual((o["sobrepoe"] as? NSNumber)?.intValue, 0, "nenhum rodapé de pedra entra no outro: \(o["pecas"] ?? "")")
        XCTAssertEqual(o["encosta"] as? Bool, true, "a peça da frente encosta na do canto (topo a topo)")
        XCTAssertEqual(o["altura"] as? Bool, true, "altura = rodapé do móvel")
        XCTAssertEqual(o["max"] as? Bool, true, "peças até 3 m")
        XCTAssertEqual(o["secao"] as? Bool, true, "aba Pedra com medidas e lista pra marmoraria")
        XCTAssertEqual(o["cor"] as? Bool, true, "qualquer cor de pedra")
        XCTAssertEqual(o["h80"] as? Bool, true, "altura editável")
        XCTAssertEqual(o["parte2D"] as? Bool, true, "aparece no desenho")
        XCTAssertEqual(o["semCorteMDF"] as? Bool, true, "não entra no corte de MDF")
        XCTAssertEqual(o["salva"] as? Bool, true, "fica salvo no projeto")
        XCTAssertEqual(o["btn"] as? Bool, true, "botão de montar o ambiente")
        XCTAssertEqual(o["abre"] as? Bool, true, "criar o ambiente abre o 3D só da sala")
        XCTAssertEqual(o["medidas"] as? String, "4200,3900,2750,1,500,2750,1,1800,pra frente,1,3900,2600", "medidas, coluna, parede no meio, ilha e paredes do lado pelo cabeçalho")
        XCTAssertEqual(o["pisoAcompanha"] as? Bool, true, "o piso aumenta sozinho")
        XCTAssertEqual(o["pronto"] as? Bool, true, "Pronto volta pro 2D")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || "))")
    }

    func testJuntaDoPainelAcompanhaEDesnivelDoTeto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.ops=[];S.env='sala';S.room='sala';S.W=1415;S.H=2700;S.Hm=1;wallSet('F','h1',2850);var R={};
          var L=function(){return S.rp.map(function(a){return [a.x,a.b,a.w,a.h,a.sl?a.sl.l+'/'+a.sl.r:''].join(',')}).sort().join(' ')};
          /* trena: divisão 1,5 em 2 placas, teto com desnível 2700 → 2850 */
          S.trena={x0:0,x1:1415};TRN=2;TRW=0;TRT='reb';TRJ=15;TRH=0;TRFR=false;trCreate();RPSEL=0;draw();R.tr=L();R.H=S.H;
          var bot=S.rp.filter(function(a){return a.b<1}),top=S.rp.filter(function(a){return a.b>1});
          R.alin=top.length===2&&top.every(function(t){return bot.some(function(b){return Math.abs(b.x-t.x)<0.05&&Math.abs(b.w-t.w)<0.05})});
          R.teto=top.every(function(t){return Math.abs(rpTopAt(t,t.x)-trTop(t.x))<0.3&&Math.abs(rpTopAt(t,t.x+t.w)-trTop(t.x+t.w))<0.3});
          R.reg=[];S.rp.forEach(function(a){jtGaps(a).forEach(function(g){R.reg.push(g.dir+':'+g.x0+'-'+g.x1+'@'+g.y0+'-'+g.y1)})});R.reg=R.reg.sort().join(' ');
          var sv=document.getElementById('svg').innerHTML;R.d2=/Parede 2700 · direita 2850/.test(sv)&&/corte 6\.1°/.test(sv);
          /* painéis da parede: dividir a de baixo em 2 com junta de 15 (marcada junta seca): a de cima divide junto e o corte do teto continua reto */
          S.W=1400;S.rp=[];pwGenerate();R.Hpw=S.H;var b0=S.rp.filter(function(a){return a.b<1})[0];RPMS=[b0.id];PLN=2;PLJ=15;PLJT={t:'seca',w:15,d:6};PLDIR='v';PLAREA='sel';window.PLCOL=true;plDivide();RPSEL=0;draw();R.dv=L();R.jt=PLJT.t;
          R.corte=(rpCutHtml().replace(/<[^>]+>/g,' ').match(/o corte começa a [0-9.]+ mm da ponta esquerda/)||[''])[0];
          /* sem desnível: placa de cima na mesma coluna acompanha; desligado, só a marcada */
          wallSet('F','h1',2700);S.W=2000;S.rp=[];var p1={id:11,liso:true,x:0,b:0,w:1000,h:1600,jt:{t:'reb',w:15,d:6}},p2={id:12,liso:true,x:0,b:1615,w:1000,h:985,jt:{t:'reb',w:15,d:6}};S.rp.push(p1,p2);RPMS=[11];PLN=2;PLJ=15;PLJT={t:'reb',w:15,d:6};plDivide();draw();R.col=L();
          S.rp=[];S.rp.push(JSON.parse(JSON.stringify(p1)),JSON.parse(JSON.stringify(p2)));RPMS=[11];window.PLCOL=false;plDivide();draw();R.sem=S.rp.length;window.PLCOL=true;
          /* coluna onde o teto passa da altura da chapa: placa reta até ali e depois em ângulo, sem buraco */
          S.W=3000;S.H=2850;wallSet('F','h1',2650);S.rp=[];pwGenerate();R.kn=L();R.kc=(rpCutHtml().replace(/<[^>]+>/g,' ').match(/reta na altura 2700 até [0-9.]+ mm da ponta esquerda/)||[''])[0];
          open3D();await new Promise(function(r){setTimeout(r,800)});R.n3=dbg3().length;R.errs=__errs;
          return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["tr"] as? String, "0,0,700,2700, 0,2715,700,59.2,-15/59.2 715,0,700,2700, 715,2715,700,135,60.8/135", "trena 2 placas com divisão 1,5: as de cima na mesma coluna e cortadas no teto")
        XCTAssertEqual((o["H"] as? NSNumber)?.doubleValue, 2700, "altura da ponta esquerda não muda")
        XCTAssertEqual(o["alin"] as? Bool, true, "junta de cima alinhada com a de baixo")
        XCTAssertEqual(o["teto"] as? Bool, true, "corte das placas de cima em cima da linha do teto")
        XCTAssertEqual(o["reg"] as? String, "h:141.5-700@2700-2715 h:715-1415@2700-2715 v:700-715@0-2715 v:700-715@2715-2774.2", "réguas da junta param no corte do teto")
        XCTAssertEqual(o["d2"] as? Bool, true, "2D mostra o desnível e o ângulo")
        XCTAssertEqual((o["Hpw"] as? NSNumber)?.doubleValue, 2700, "criar painéis não apaga o desnível")
        XCTAssertEqual(o["dv"] as? String, "0,0,692.5,2700, 0,2715,692.5,59.2,-15/59.2 707.5,0,692.5,2700, 707.5,2715,692.5,135,60.8/135", "dividir a de baixo: a de cima divide no mesmo lugar e o corte continua reto")
        XCTAssertEqual(o["jt"] as? String, "reb", "junta digitada vira rebaixo (placas iguais)")
        XCTAssertEqual(o["corte"] as? String, "o corte começa a 140 mm da ponta esquerda")
        XCTAssertEqual(o["col"] as? String, "0,0,492.5,1600, 0,1615,492.5,985, 507.5,0,492.5,1600, 507.5,1615,492.5,985,", "sem desnível: a placa de cima da coluna acompanha")
        XCTAssertEqual((o["sem"] as? NSNumber)?.intValue, 3, "desligado: só a marcada")
        XCTAssertEqual(o["kn"] as? String, "0,0,1492.5,2700, 0,2715,1492.5,135,135/35.5 1507.5,0,1492.5,2700,2749.5/2650 1507.5,2715,1492.5,34.5,34.5/-65", "teto passa da chapa no meio da coluna: reta até ali e depois em ângulo")
        XCTAssertEqual(o["kc"] as? String, "reta na altura 2700 até 742.5 mm da ponta esquerda", "lista de corte explica onde o ângulo começa")
        XCTAssertGreaterThan((o["n3"] as? NSNumber)?.intValue ?? 0, 0)
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || ").replacingOccurrences(of: "\n", with: " "))")
    }

    /// Editor por vãos (2ª rodada): 🗑 apaga só o escolhido, medida do vão digitada, engrosso da prateleira,
    /// 3 portas com montante, basculante, vidro, gaveta interna sem caixote fora do quarto, frente do conjunto fixa,
    /// portas alinhadas no projeto todo e porta de correr de trás cobrindo a lateral.
    func testEditorPorVaosLixeiraEngrossoPortasEAlinhamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.env='quarto';S.room='quarto';S.W=4000;S.H=2700;draw();
          var c=CATS.filter(function(x){return x.id==='quarto'})[0],fo=JSON.parse(JSON.stringify(c.it.filter(function(q){return /Armário livre/.test(q.n)})[0]));newTpl(fo);var m=S.m;soloOn(m);
          var C=function(s){document.querySelector(s).click()},CH=function(s,v){var i=document.querySelector(s);i.value=String(v);i.dispatchEvent(new Event('change',{bubbles:true}))},CK=function(s,on){var i=document.querySelector(s);i.checked=on;i.dispatchEvent(new Event('change',{bubbles:true}))};
          RG.sel={mi:0,path:'r'};RG.tab='div';panel();C('[data-rga="sp|h|2"]');
          RG.sel={mi:0,path:'r.0'};panel();CH('[data-rgi="vh"]',700);R.vh=rgLay(m).regs.filter(function(r){return r.leaf}).map(function(r){return Math.round(r.y1-r.y0)}).join(' ');
          RG.tab='por';panel();C('[data-rga="door|3"]');R.tres=partsOf(m).filter(function(p){return p.name==='Porta'}).length+' '+partsOf(m).filter(function(p){return /^Montante/.test(p.name)}).length;
          C('[data-rga="dbas|down"]');R.bas=partsOf(m).filter(function(p){return p.name==='Porta'}).map(function(p){return p.basv&&p.basv.bd}).join();
          C('[data-rga="door|2"]');CK('[data-rgc="vid"]',true);R.vid=partsOf(m).filter(function(p){return p.name==='Porta'}).every(function(p){return p.glass&&p.noCut});
          RG.sel=null;RG.dsel={mi:0,path:'r',i:0};RG.tab='div';panel();C('[data-rga="eng|25"]');C('[data-rga="engn|1"]');CK('[data-rgc="etop"]',true);CH('[data-rgi="ew"]',50);
          R.eng=partsOf(m).filter(function(p){return /^Engrosso/.test(p.name)}).length+' '+partsOf(m).filter(function(p){return /^Engrosso/.test(p.name)})[0].cw+' '+partsOf(m).filter(function(p){return /^Prateleira encostada/.test(p.name)}).length;
          RG.sel={mi:0,path:'r.1'};RG.tab='gav';panel();C('[data-rga="ins|gav"]');var lat=function(){var l=partsOf(m).filter(function(p){return p.name==='Gaveteiro · lateral'})[0];return l?l.cw+'@'+l.cxz.join(':'):'-'};R.lat0=lat();CH('[data-rgi="gvD"]',400);R.lat1=lat();CH('[data-rgi="gvR"]',100);R.lat2=lat();
          RG.sel=null;RG.dsel={mi:0,path:'r',i:0};
          var n0=S.mods.length;document.getElementById('delMod').click();R.soDiv=(S.mods.length===n0)+' '+!m.rt.c;
          RG.sel=null;RG.dsel=null;document.getElementById('delMod').click();R.pede2=S.mods.length===n0;
          soloOff();S.mods=[];S.env='cozinha';S.room='cozinha';newTpl(JSON.parse(JSON.stringify(fo)));var k=S.m;soloOn(k);RG.sel={mi:0,path:'r'};RG.tab='div';panel();C('[data-rga="sp|h|2"]');RG.sel={mi:0,path:'r.1'};RG.tab='gav';panel();C('[data-rga="ins|gav"]');
          R.cozinha=partsOf(k).filter(function(p){return /^Gaveteiro/.test(p.name)}).length+' '+partsOf(k).filter(function(p){return p.name==='Gaveta interna · frente'}).length;soloOff();
          S.mods=[];var ti=TPL.findIndex(function(t){return t.n==='Armário baixo (balcão)'});newTpl(ti);newTpl(ti);var d=partsOf(S.mods[0]).filter(function(p){return p.name==='Porta'});S.mods[0].po={};S.mods[0].po[d[0].pk]={v2:1,et:-5,eb:12};R.alinhou=poAlign(0,d[0].pk);R.alturas=S.mods.map(function(q){return partsOf(q).filter(function(p){return p.name==='Porta'}).map(function(p){return p.h}).join(' ')}).join(' | ');
          S.mods=[];S.env='quarto';S.room='quarto';newTpl(JSON.parse(JSON.stringify(fo)));newTpl(JSON.parse(JSON.stringify(fo)));soloOff();var a=S.mods[0],b=S.mods[1];a.x=500;b.x=500+a.w;a.tl=true;b.tr=true;draw();soloOn(a);RG.tab='est';panel();C('[data-rga="slr|2"]');soloOff();
          var sl=partsOf(a).filter(function(p){return p.name==='Porta de correr'});R.correr=sl.map(function(p){return Math.round(a.x+p.x)+'+'+p.w}).join(' ');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["vh"] as? String, "700 1555", "digita a altura do vão e a divisão anda")
        XCTAssertEqual(o["tres"] as? String, "3 1", "3 portas: montante de 80 na junta da dobradiça")
        XCTAssertEqual(o["bas"] as? String, "down", "basculante abre pra baixo")
        XCTAssertEqual(o["vid"] as? Bool, true, "porta de vidro não entra no corte de MDF")
        XCTAssertEqual(o["lat0"] as? String, "480@70:550", "conjunto 70 pra dentro, até o fundo")
        XCTAssertEqual(o["lat1"] as? String, "400@70:470", "profundidade menor: encurta atrás, a frente fica")
        XCTAssertEqual(o["lat2"] as? String, "400@100:500", "frente pra dentro digitada")
        XCTAssertEqual(o["eng"] as? String, "4 50 1", "engrosso 2 camadas × frente e trás, réguas de 50, prateleira encostada")
        XCTAssertEqual(o["soDiv"] as? String, "true true", "🗑 com a divisão escolhida apaga só ela")
        XCTAssertEqual(o["pede2"] as? Bool, true, "módulo inteiro só com 2 toques")
        XCTAssertEqual(o["cozinha"] as? String, "0 4", "fora do quarto: gaveta normal, sem afastador, lateral nem base em cima")
        XCTAssertEqual((o["alinhou"] as? NSNumber)?.intValue, 3, "as outras portas alinhadas seguem a mesma folga")
        XCTAssertEqual(o["alturas"] as? String, "688 688 | 688 688")
        XCTAssertEqual(o["correr"] as? String, "530+870 1385+885", "porta de trás cobre a lateral (gola 20 na ponta), a da frente passa 15 dos dois lados")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "errs: \(((o["errs"] as? [String]) ?? []).joined(separator: " || "))")
    }

    func testEditorPorVaosGavetasColunaTorreCorrerECantos() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.env='quarto';S.room='quarto';S.W=3200;S.H=2700;draw();
          var c=CATS.filter(function(x){return x.id==='quarto'})[0];newTpl(JSON.parse(JSON.stringify(c.it.filter(function(q){return /Armário livre/.test(q.n)})[0])));soloOn(S.m);
          var m=S.m;R.vaos=rgIs(m)&&window.SOLO2===m;document.querySelector('#svg [data-rgr]').dispatchEvent(new MouseEvent('click',{bubbles:true}));R.rosa=!!RG.sel;
          document.querySelector('[data-rga="sp|h|2"]').click();RG.sel={mi:0,path:'r.1'};RG.tab='gav';panel();document.querySelector('[data-rga="ins|gav"]').click();
          RG.sel={mi:0,path:'r'};RG.tab='por';panel();document.querySelector('[data-rga="door|2"]').click();
          var P=partsOf(m),f=function(n){return P.filter(function(p){return p.name===n})};
          R.base=f('Gaveteiro · base sobre as gavetas').map(function(p){return p.cw})[0];R.afast=f('Gaveteiro · afastador frontal esquerdo').map(function(p){return p.cw})[0];R.lat=f('Gaveteiro · lateral').map(function(p){return p.cw})[0];
          var fr=f('Gaveta interna · frente'),lg=f('Gaveta interna · lateral');R.folga=Math.round((fr[1].y-(fr[0].y+fr[0].h))*10)/10;R.caixa=Math.round((fr[0].cw-lg[0].cw)*10)/10;R.portas=f('Porta').length;
          var h=document.querySelector('#svg circle[data-rgd]'),b=h.getBoundingClientRect(),x=b.left+b.width/2,y=b.top+b.height/2,pe=function(t,el,yy){el.dispatchEvent(new PointerEvent(t,{bubbles:true,clientX:x,clientY:yy,pointerId:1,isPrimary:true}))};pe('pointerdown',h,y);for(var i=1;i<=6;i++)pe('pointermove',window,y-i*10);pe('pointerup',window,y-60);R.arrastou=!!(m.rt.c[0].z>0);
          RG.tab='est';panel();document.querySelector('[data-rga="stk|mal"]').click();R.coluna=S.mods.length===2&&S.mods[1].stkB===m.uid&&S.mods[1].b===m.h;R.tamp=partsOf(m).filter(function(p){return p.name==='Tamponamento esquerdo'})[0].cl;
          S.mods=[];S.room='cozinha';S.env='cozinha';draw();var a=CATS.filter(function(x){return x.id==='alto'})[0];newTpl(JSON.parse(JSON.stringify(a.it.filter(function(q){return /Armário alto livre/.test(q.n)})[0])));soloOn(S.m);var t=S.m;
          t.rt={s:'h',c:[{p:{n:2}},{t:'ele',el:{mdl:'m_cm146',fr:'rec'},z:600},{p:{n:2}}]};var Q=partsOf(t),fc=Q.filter(function(p){return /^Frente com recorte do micro/.test(p.name)})[0],ct=Q.filter(function(p){return p.name==='Corte do micro-ondas'})[0];
          R.recorte=fc?fc.rec.w+'x'+fc.rec.h:'';R.centro=fc?Math.round((fc.rec.x*2+fc.rec.w-fc.w)*10)/10:'x';R.puxEmbaixo=Q.filter(function(p){return p.name==='Porta'&&p.pxDn}).length;
          S.mods=[];S.room='quarto';S.env='quarto';draw();var d=CATS.filter(function(x){return x.id==='dArm'})[0];['2P c/ Cab 600mm','2P 600mm','2P c/ Cab 600mm'].forEach(function(n){newTpl(JSON.parse(JSON.stringify(d.it.filter(function(q){return q.n===n})[0])))});S.m=S.mods[1];S.tab=3;draw();panel();document.querySelector('#bd [data-rga="slr|3"]').click();
          var C=partsOf(S.mods[0]).filter(function(p){return p.name==='Porta de correr'});R.correr=C.length+' '+C.map(function(p){return p.trk}).join('')+' '+S.mods[2].d;R.gola=partsOf(S.mods[0]).filter(function(p){return p.name==='Puxador gola lateral'}).length;
          var k=CATS.filter(function(x){return x.id==='dCan'})[0];R.cr=k.it.filter(function(q){return /Canto reto \(CR\)/.test(q.n)}).length;S.mods=[];newTpl(JSON.parse(JSON.stringify(k.it[0])));var L=S.m;R.baseCima=partsOf(L).some(function(p){return p.name==='Base superior'});L.cshT='45';R.p45=partsOf(L).filter(function(p){return /^Prateleira 45/.test(p.name)}).length;
          R.modbar=!/data-selm/.test(modBar());R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["vaos"] as? Bool, true, "armário livre abre no 2D por vãos")
        XCTAssertEqual(o["rosa"] as? Bool, true, "toque no vão escolhe ele")
        XCTAssertEqual(o["base"] as? Double, 500, "base sobre as gavetas passa 20: 480 + 20")
        XCTAssertEqual(o["afast"] as? Double, 35, "afastador de 35")
        XCTAssertEqual(o["lat"] as? Double, 480, "conjunto 70 pra dentro: 550 − 70")
        XCTAssertEqual(o["folga"] as? Double, 2.5, "folga 2,5 entre frentes")
        XCTAssertEqual(o["caixa"] as? Double, 30, "caixa = frente − 30")
        XCTAssertEqual(o["portas"] as? Double, 2, "2 portas no vão de fora")
        XCTAssertEqual(o["arrastou"] as? Bool, true, "arrasta a divisão")
        XCTAssertEqual(o["coluna"] as? Bool, true, "maleiro unido em cima")
        XCTAssertEqual(o["tamp"] as? Double, 2600, "tamponamento pega a coluna toda")
        XCTAssertEqual(o["recorte"] as? String, "560x380", "recorte do manual")
        XCTAssertEqual(o["centro"] as? Double, 0, "eletro centralizado")
        XCTAssertEqual(o["puxEmbaixo"] as? Double, 2, "porta acima da pedra com puxador embaixo")
        XCTAssertEqual(o["correr"] as? String, "3 010 580", "3 portas: 2 atrás e 1 na frente, corpo 650 − 70")
        XCTAssertEqual(o["gola"] as? Double, 4, "gola: frente dos 2 lados, as de trás do lado de fora")
        XCTAssertEqual(o["cr"] as? Double, 4, "cantos retos CR")
        XCTAssertEqual(o["baseCima"] as? Bool, true, "canto alto tem base superior")
        XCTAssertEqual(o["p45"] as? Double, 1, "prateleira em 45")
        XCTAssertEqual(o["modbar"] as? Bool, true, "sem a fila Base 1 / Superior 1")
        XCTAssertEqual((o["errs"] as? [Any])?.count, 0)
    }

    /// Edição ambiente 3D: minimizar, 2 toques na parede escolhe a parede e o 2D passa a mostrar ela (painel criado lá vai pra
    /// aquela parede, sem perguntar); salvar, desfazer, 3D e lista de corte sempre com o projeto real; painel nas 3 paredes.
    /// Abas limpas: Ambiente sem as medidas (ficam no Ajustes › Paredes da obra), sem a conferência na aba Painéis,
    /// Estrutura com Dimensões em cima e sem o bloco de cores, chapa limpa no Ajustes › Chapa e corte.
    func testEdicaoAmbiente3DParedeNo2DEAbasLimpas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.mods=[];S.stones=[];S.fr=[];S.isl=[];S.rp=[];S.ops=[];S.env='livre';S.room='sala';S.W=3800;S.H=2700;S.RD=3000;S.ambOk=1;S.wl=null;draw();
          var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},c=CATS.filter(function(x){return x.id==='sala'})[0],ix=c.it.findIndex(function(q){return q.act==='pl'}),ADD=async function(){catOpen('sala');await W(80);document.querySelector('#catm [data-cati="sala|'+ix+'"]').click();await W(250)},WL=function(){return S.rp.map(function(a){return a.wall||'f'}).join('')};
          await ADD();var M=document.getElementById('rwm');if(M)M.hidden=true;S.tab=9;panel();
          var bt=document.querySelector('[data-ambopen]');R.btn=/Edição ambiente 3D/.test(bt.textContent);R.aba=[].map.call(document.querySelectorAll('#bd .sec'),function(e){return e.textContent.replace('⌃','').trim()}).join('|');bt.click();await W(600);
          var P=document.getElementById('ambset');R.tit=/Edição ambiente 3D/.test(P.textContent)&&/Toque 2 vezes numa parede/.test(P.textContent);
          var cv=__cv3(),r=cv.getBoundingClientRect(),pt=null;for(var y=r.height*.45;y<r.height&&!pt;y+=10)for(var x=25;x<r.width;x+=10){var h=__wallHit3(x,y);if(h&&h.w==='e'){pt=[x,y];break}}
          var tap=function(x,y){['pointerdown','pointerup'].forEach(function(t){cv.dispatchEvent(new PointerEvent(t,{bubbles:true,clientX:r.left+x,clientY:r.top+y,pointerId:1,isPrimary:true,pointerType:'touch'}))})};
          if(pt){tap(pt[0],pt[1]);await W(120);tap(pt[0],pt[1]);await W(300)}
          var card=P.querySelector('[data-ambw]');R.card=card?card.dataset.ambw+' '+/sem painel/.test(card.textContent)+' '+[].map.call(card.querySelectorAll('input'),function(i){return i.dataset.ambs+'='+i.value}).join(','):'';
          var full=P.getBoundingClientRect().height;P.querySelector('[data-ambsb="hide"]').click();R.min=P.getBoundingClientRect().height<70&&full>150;P.querySelector('[data-ambsb="hide"]').click();
          P.querySelector('[data-ambsb="wvrp"]').click();await W(500);R.vista=wvCur()+' '+S.W+' '+S.rp.length+' '+(!document.getElementById('catm').hidden)+' '+(!document.getElementById('wvbar').hidden);
          document.querySelector('#catm [data-cati="sala|'+ix+'"]').click();await W(300);M=document.getElementById('rwm');R.semPergunta=!(M&&!M.hidden);R.naVista=S.rp.length+' '+S.W;
          var st=snapState();R.salvo=st.rp.map(function(a){return a.wall||'f'}).join('')+' '+st.W;
          S.rp[0].w=1500;draw();UNDOING=true;try{loadState(st)}finally{UNDOING=false}R.desfaz=wvCur()+' '+S.rp.length+' '+S.rp[0].w+' '+S.W;
          open3D();await W(400);__build();var B=__boxes();R.no3d=wvCur()+' '+WL()+' '+S.W+' '+['f','e'].map(function(w){var q=S.rp.filter(function(x){return (x.wall||'f')===w})[0];return B.some(function(b){return b.rpid===q.id})}).join(',');
          document.getElementById('v3x').click();await W(300);R.volta=wvCur()+' '+S.rp.length;
          var G=cutGroups();R.corte=G.ord.filter(function(k){return /painel liso/i.test(G.map[k].names[0])}).reduce(function(s,k){return s+G.map[k].qty},0)+' '+wvCur();
          wvGo('d');await ADD();wvGo('f');R.tres=WL()+' '+S.W+' '+wvCur();
          S.tab=8;panel();R.conf=!!document.querySelector('#bd [data-rpconf]');
          S.rp=[];S.env='cozinha';S.room='cozinha';S.W=3000;newTpl(0);S.tab=0;panel();R.est=[].map.call(document.querySelectorAll('#bd .sec'),function(e){return e.textContent.replace('⌃','').trim()}).join('|');
          stdOpen(0,'obra');await W(100);var o=document.getElementById('cfgobra');R.obra=!!o&&/Paredes \(modo fácil\)/.test(o.textContent)&&/Esquadro/.test(o.textContent);var i=o.querySelector('[data-pf="F|w"]');i.value='3300';i.dispatchEvent(new Event('change',{bubbles:true}));R.W=S.W;
          var q=document.querySelector('#stdbody [data-stdq="limH"]');R.lim=q.value;var l0=PR.limH;q.value='2600';q.dispatchEvent(new Event('input',{bubbles:true}));q.dispatchEvent(new Event('change',{bubbles:true}));R.plLim=plLim().h+' '+plLim().w;PR.limH=l0;document.getElementById('stdm').hidden=true;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["btn"] as? Bool, true, "botão com o nome novo")
        XCTAssertEqual(o["aba"] as? String, "Ambiente|Módulos prontos|Medidas das paredes|Porta / vão da sala (medida real)|Janelas e portas da parede", "Ambiente só com o útil")
        XCTAssertEqual(o["tit"] as? Bool, true)
        XCTAssertEqual(o["card"] as? String, "e true Llen=3000,Lh0=2700,Lh1=2700", "2 toques na parede livre: comprimento e a altura de cada ponta")
        XCTAssertEqual(o["min"] as? Bool, true, "minimiza e volta")
        XCTAssertEqual(o["vista"] as? String, "e 3000 0 true true", "2D na parede da esquerda, catálogo aberto")
        XCTAssertEqual(o["semPergunta"] as? Bool, true, "na parede escolhida não pergunta de novo")
        XCTAssertEqual(o["naVista"] as? String, "1 3000")
        XCTAssertEqual(o["salvo"] as? String, "fe 3800", "o que salva é o projeto real")
        XCTAssertEqual(o["desfaz"] as? String, "e 1 1800 3000", "desfazer continua na parede")
        XCTAssertEqual(o["no3d"] as? String, "null fe 3800 true,true", "3D mostra as duas paredes com painel")
        XCTAssertEqual(o["volta"] as? String, "e 1", "fechou o 3D: volta pra parede")
        XCTAssertEqual(o["corte"] as? String, "2 e", "lista de corte com os painéis de todas as paredes")
        XCTAssertEqual(o["tres"] as? String, "fed 3800 null", "painel nas 3 paredes")
        XCTAssertEqual(o["conf"] as? Bool, false, "sem a conferência da soma na aba")
        XCTAssertEqual(o["est"] as? String, "Dimensões|Posição e tipo do módulo|Módulo de canto (cozinha em L)|Em qual parede (cozinha em L)|Tipo do módulo|Regras do módulo|Componentes")
        XCTAssertEqual(o["obra"] as? Bool, true, "medidas das paredes e esquadro no Ajustes")
        XCTAssertEqual((o["W"] as? NSNumber)?.intValue, 3300)
        XCTAssertEqual(o["lim"] as? String, "2700")
        XCTAssertEqual(o["plLim"] as? String, "2600 1800", "chapa limpa vem do Ajustes")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Regras que não podem voltar a quebrar: nenhuma porta ou frente entra em outra peça (fechada, aberta ou com moldura),
    /// gaveta com cava sem calço (contra-frente encostada na frente, caixa livre dos batentes), moldura + cava com 30 mm de pega,
    /// e a dobradiça diz se é reta, curva ou alta pela conta do recobrimento (toque nela no 3D).
    func testPortasNaoEntramEmNadaGavetaSemCalcoMolduraEDobradica() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.mods=[];draw();
          var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))};
          /* dobradiça: tipo pela conta do recobrimento e toque nela no 3D */
          S.mods=[];newTpl(T('inf','Gaveteiro 4 gavetas'));newTpl(T('inf','Balcão 2 portas'));m=S.m;newTpl(T('inf','Gaveteiro 4 gavetas'));m.v.forEach(function(v){v.open=true});draw();var pp=partsOf(m).filter(function(p){return p.name==='Porta'})[0],hi=hgInfo(m,pp);R.hg=hi.k+' '+hi.D+' '+hi.K+' '+hi.H;m.pSn=14;var h2=hgInfo(m,partsOf(m).filter(function(p){return p.name==='Porta'})[0]);R.hgReta=h2.k+' '+h2.D+' '+h2.H;delete m.pSn;draw();open3D();await W(400);
          var H=__boxes().filter(function(b){return b.hg}),hit='';for(var i=0;i<H.length&&!hit;i++){var h0=H[i],sp=__p3((h0.x0+h0.x1)/2,(h0.y0+h0.y1)/2,(h0.z0+h0.z1)/2);__tap3(sp[0],sp[1]);var am=document.getElementById('amsg');if(am&&/Dobradiça CURVA/.test(am.textContent))hit=am.textContent}
          R.toque=/a porta cobre 6 mm da lateral/.test(hit)&&/calço de 2 mm/.test(hit);R.abertaAinda=m.v.every(function(v){return v.open});
          document.getElementById('v3x').click();await W(200);S.W=9000;
          open3D();await W(400);
          var OV=function(aberta){var A=__ang();Object.keys(A.g).forEach(function(k){delete A.g[k]});Object.keys(A.t).forEach(function(k){delete A.t[k]});__build();var B=__boxes().filter(function(b){return b.nm&&/^\d+:/.test(String(b.nm))&&b.a!==0&&(aberta||(!b.gp&&!b.pf))}),bad=[];
           for(var i=0;i<B.length;i++){var a=B[i],an=String(a.nm);if(aberta?!(/:Porta$/.test(an)&&(a.pf||a.gp)&&a.y1-a.y0>60):!(/:(Porta|Frente de gaveta)$/.test(an)&&a.z1-a.z0>=3&&(a.x1-a.x0>8||a.y1-a.y0>8)))continue;
            for(var j=0;j<B.length;j++){var b=B[j],bn=String(b.nm);if(b===a||bn===an&&(!aberta||b.pk===a.pk)||b.hg||/Puxador|puxador|Dobradiça|Perfil|perfil|Corrediça|LED|Vidro/.test(bn))continue;var ox=Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0),oy=Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0),oz=Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0);if(ox>1.2&&oy>1.2&&oz>1.2)bad.push(an+'×'+bn)}}return bad};
          var L=[['inf','Balcão 2 portas'],['inf','Balcão 1 porta'],['inf','Balcão porta + gavetas'],['inf','Gaveteiro 4 gavetas'],['sup','Aéreo 2 portas'],['sup','Aéreo 1 porta'],['sup','Aéreo basculante'],['alto','Armário alto 2 portas'],['alto','Despenseiro'],['quarto','Guarda-roupa 2 vãos']],fe=[],ab=[],mo=[];
          for(var q=0;q<L.length;q++){var it=T(L[q][0],L[q][1]),nb=(it.b>0||it.sup)?it:T('inf','Gaveteiro 4 gavetas');
           S.mods=[];newTpl(JSON.parse(JSON.stringify(nb)));newTpl(JSON.parse(JSON.stringify(it)));newTpl(JSON.parse(JSON.stringify(nb)));draw();OV(false).forEach(function(x){fe.push(L[q][1]+': '+x)});
           S.mods.forEach(function(m){(m.v||[]).forEach(function(v){v.open=true})});draw();OV(true).forEach(function(x){ab.push(L[q][1]+': '+x)});
           S.mods=[];newTpl(JSON.parse(JSON.stringify(it)));newTpl(JSON.parse(JSON.stringify(it)));S.mods.forEach(function(m){m.mold=true;m.moldOn=true});draw();OV(false).forEach(function(x){mo.push(L[q][1]+': '+x)})}
          R.fechadas=fe.length;R.abertas=ab.length;R.moldura=mo.length;R.ex=fe.concat(ab,mo).slice(0,4);
          /* gaveta com cava: sem calço, contra-frente encostada na frente e caixa livre dos batentes */
          S.mods=[];newTpl(T('inf','Gaveteiro 4 gavetas'));var m=S.m;draw();var Pm=partsOf(m);R.calco=Pm.filter(function(p){return /Calço/.test(p.name)}).length;__build();var B=__boxes().filter(function(b){return /^0:/.test(String(b.nm))}),fr=B.filter(function(b){return /:Frente de gaveta$/.test(b.nm)&&b.y1-b.y0>50}),cf=B.filter(function(b){return /contra-frente/.test(b.nm)}),bt=B.filter(function(b){return /Batente/.test(b.nm)}),lt=B.filter(function(b){return /:Lateral de gaveta$/.test(b.nm)});
          R.encosta=Math.abs(Math.max.apply(null,cf.map(function(b){return b.z1}))-Math.min.apply(null,fr.map(function(b){return b.z0})))<0.6;R.livre=!lt.some(function(l){return bt.some(function(b){return Math.min(l.y1,b.y1)-Math.max(l.y0,b.y0)>0.5&&Math.min(l.z1,b.z1)-Math.max(l.z0,b.z0)>0.5})});
          /* moldura + cava: 30 mm de pega (balcão e gaveteiro) · sem cava em cima (aéreo): 2 mm */
          var gap=function(mm){var P=partsOf(mm),mo=P.filter(function(p){return p.name==='Moldura de acabamento'})[0],f=P.filter(function(p){return /^(Porta|Frente de gaveta)$/.test(p.name)}).sort(function(a,b){return a.y-b.y})[0];return mo&&f?Math.round((f.y-(mo.y+mo.h))*10)/10:null};
          m.mold=true;m.moldOn=true;draw();R.pegaGav=gap(m);var fh=partsOf(m).filter(function(p){return p.name==='Frente de gaveta'}).map(function(p){return p.h});R.iguais=Math.max.apply(null,fh)-Math.min.apply(null,fh)<0.6;
          S.mods=[];newTpl(T('inf','Balcão 2 portas'));m=S.m;m.mold=true;m.moldOn=true;draw();R.pegaPorta=gap(m);S.mods=[];newTpl(T('sup','Aéreo 2 portas'));m=S.m;m.mold=true;draw();R.aereo=gap(m);
          /* puxador gola lateral: perfil G de verdade junto com a porta (fechada e aberta), na cor escolhida */
          S.mods=[];S.W=3000;var cq=CATS.filter(function(x){return x.id==='quarto'})[0];newTpl(JSON.parse(JSON.stringify(cq.it.filter(function(q){return /Armário livre/.test(q.n)})[0])));await W(300);m=S.m;m.w=1060;m.h=450;m.b=1100;m.golaCor='preto';m.rt={p:{n:2,gl:1}};draw();__build();
          var GB=function(){return __boxes().filter(function(b){return /^0:/.test(String(b.nm))})},pg=GB().filter(function(b){return b.nol&&/:Porta$/.test(b.nm)&&b.y1-b.y0>300});R.golaSolta=GB().filter(function(b){return /gola/.test(b.nm)}).length;R.golaPerfil=pg.length+' '+pg.some(function(b){return String(b.c)==='42,43,46'})+' '+pg.some(function(b){return !!b.pf});
          (m.v||[]).forEach(function(v){v.open=true});draw();var Ag=__ang();Object.keys(Ag.g).forEach(function(k){delete Ag.g[k]});__build();pg=GB().filter(function(b){return b.nol&&/:Porta$/.test(b.nm)&&b.y1-b.y0>300});R.golaAbre=pg.length+' '+pg.every(function(b){return !!b.pf});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["hg"] as? String, "c 6 4.5 2.5", "cobre 6 mm: curva")
        XCTAssertEqual(o["hgReta"] as? String, "r 14 3.5", "cobre 14 mm: reta")
        XCTAssertEqual(o["toque"] as? Bool, true, "toque na dobradiça informa o tipo")
        XCTAssertEqual(o["abertaAinda"] as? Bool, true, "tocar na dobradiça não fecha a porta")
        XCTAssertEqual((o["fechadas"] as? NSNumber)?.intValue, 0, "porta/frente fechada entrando em outra peça: \(o["ex"] ?? "")")
        XCTAssertEqual((o["abertas"] as? NSNumber)?.intValue, 0, "porta aberta entrando no vizinho ou na caixa: \(o["ex"] ?? "")")
        XCTAssertEqual((o["moldura"] as? NSNumber)?.intValue, 0, "porta/frente entrando na moldura: \(o["ex"] ?? "")")
        XCTAssertEqual((o["calco"] as? NSNumber)?.intValue, 0, "sem a peça do meio (calço)")
        XCTAssertEqual(o["encosta"] as? Bool, true, "contra-frente encostada na frente")
        XCTAssertEqual(o["livre"] as? Bool, true, "caixa não pega nos batentes da cava")
        XCTAssertEqual((o["pegaGav"] as? NSNumber)?.intValue, 30)
        XCTAssertEqual(o["iguais"] as? Bool, true, "frentes das gavetas continuam iguais")
        XCTAssertEqual((o["pegaPorta"] as? NSNumber)?.intValue, 30)
        XCTAssertEqual((o["golaSolta"] as? NSNumber)?.intValue, 0, "sem a régua chapada solta no armário")
        XCTAssertEqual(o["golaPerfil"] as? String, "12 true false", "perfil G (6 peças por porta) na cor escolhida")
        XCTAssertEqual(o["golaAbre"] as? String, "12 true", "o perfil abre junto com a porta")
        XCTAssertEqual((o["aereo"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Puxadores reais (alça e ponto) na aba Portas: modelo pelo desenho, furação e comprimento de catálogo, lugar digitado
    /// com a medida até os 4 cantos; as outras portas copiam (par espelhado, aéreo de baixo pra cima); gaveta no meio,
    /// um pouco acima do centro; 3D com o puxador no tamanho real; modelo guardado no projeto.
    func testPuxadoresReaisModeloLugarEMedidasNosQuatroCantos() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.mods=[];delete S.pxa;delete S.pxm;delete S.pxk;
          var T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))},R={};
          newTpl(T('inf','Balcão 2 portas'));newTpl(T('inf','Gaveteiro 4 gavetas'));newTpl(T('sup','Aéreo 2 portas'));S.m=S.mods[0];S.sv=0;draw();S.tab=3;panel();
          var bx=document.querySelector('#bd [data-pxbox]');R.box=!!bx;R.cards=document.querySelectorAll('#bd [data-pxmd]').length+'+'+document.querySelectorAll('#bd [data-pxkd]').length;
          document.querySelector('#bd [data-pxmd="luce"]').click();R.pxm=S.pxm;R.tipos=[...new Set(S.mods.flatMap(m=>m.v.map(v=>v.px)))].join(',');
          R.sizes=[].map.call(document.querySelectorAll('#bd [data-pxm2]'),b=>b.dataset.pxm2).join(',');document.querySelector('#bd [data-pxm2="luce192"]').click();R.pxm2=S.pxm;
          var m=S.mods[0],P=partsOf(m).filter(p=>p.name==='Porta');R.note=(P[0].note||'').split(' · ').filter(s=>/Luce|furos/.test(s)).join(' | ');
          var M0=__pxMeas();R.m0=[M0.L,M0.R,M0.T,M0.B].map(Math.round).join(',');
          var i=document.querySelector('#bd [data-pxin="du"]');i.value='60';i.dispatchEvent(new Event('change',{bubbles:true}));i=document.querySelector('#bd [data-pxin="dt"]');i.value='150';i.dispatchEvent(new Event('change',{bubbles:true}));R.pxa=JSON.stringify(S.pxa);
          var pos=function(mm){return partsOf(mm).filter(p=>p.name==='Porta').map(p=>{var b=pxBar(p,mm,p.w,p.h);return p.hinge+':'+Math.round(b.u)+'/'+Math.round(p.w-b.u)+' cima'+Math.round(p.h-b.v)+' baixo'+Math.round(b.v)+' L'+b.L})};R.base=pos(S.mods[0]);R.aereo=pos(S.mods[2]);
          var g=S.mods[1],fr=partsOf(g).filter(p=>p.name==='Frente de gaveta')[0],bg=pxBar(fr,g,fr.w,fr.h);R.gav='u'+Math.round(bg.u)+'/'+Math.round(fr.w)+' v'+bg.v+'/'+fr.h+' L'+bg.L;
          R.txt=[].map.call(document.querySelectorAll('#bd [data-pxpad2] text'),t=>t.textContent).join(' ');
          document.querySelector('#bd [data-pxo="h"]').click();var bh=pxBar(P[0],m,P[0].w,P[0].h);R.deitada=S.pxo+' '+bh.vert+' '+Math.round(bh.u)+' '+Math.round(P[0].h-bh.v)+' '+snapState().pxo;document.querySelector('#bd [data-pxo="v"]').click();R.empe=String(S.pxo)+' '+pxBar(P[0],m,P[0].w,P[0].h).vert;
          open3D();await new Promise(r=>setTimeout(r,500));__build();var B=__boxes().filter(b=>b.nol&&/^0:Porta/.test(b.nm));R.b3=B.length+' '+B.slice(0,4).map(b=>'x['+Math.round(b.x0)+','+Math.round(b.x1)+'] y['+Math.round(b.y0)+','+Math.round(b.y1)+'] z['+Math.round(b.z0)+','+Math.round(b.z1)+']').join(' ');
          document.getElementById('v3x').click();S.tab=3;panel();document.querySelector('#bd [data-pxkd="cog"]').click();R.k=S.pxk+' '+[...new Set(S.mods.flatMap(m=>m.v.map(v=>v.px)))].join(',');R.kn=(partsOf(S.mods[0]).filter(p=>p.name==='Porta')[0].note||'').split(' · ').filter(s=>/ponto|Cog/.test(s)).join('|');
          var st=snapState();R.salvo=st.pxm+' '+st.pxk+' '+JSON.stringify(st.pxa);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["box"] as? Bool, true, "quadro de puxadores na aba Portas")
        XCTAssertEqual(o["cards"] as? String, "6+2")
        XCTAssertEqual(o["tipos"] as? String, "externo", "vale pra todas as portas e gavetas")
        XCTAssertEqual(o["sizes"] as? String, "luce192,luce288,luce384")
        XCTAssertEqual(o["pxm2"] as? String, "luce192")
        XCTAssertEqual(o["note"] as? String, "Luce | furos a 192 mm um do outro | 2 furos Ø35 a 100 mm das pontas")
        XCTAssertEqual(o["pxa"] as? String, "{\"du\":60,\"dt\":150}")
        XCTAssertEqual(o["base"] as? [String], ["l:380/60 cima150 baixo555 L214", "r:60/380 cima150 baixo555 L214"], "porta par: espelhado, mesma altura")
        XCTAssertEqual(o["aereo"] as? [String], ["l:430/60 cima596 baixo150 L214", "r:60/430 cima596 baixo150 L214"], "aéreo: de baixo pra cima")
        XCTAssertEqual(o["gav"] as? String, "u393/785 v107.4/173.3 L214", "gaveta: no meio, um pouco acima do centro")
        XCTAssertEqual(o["txt"] as? String, "380 60 150 555", "medida até os 4 cantos")
        XCTAssertEqual(o["deitada"] as? String, "h 0 328 150 h", "alça deitada: cabe dentro da porta, mesma altura, guardada no projeto")
        XCTAssertEqual(o["empe"] as? String, "undefined 1", "volta pra em pé")
        XCTAssertTrue(((o["b3"] as? String) ?? "").hasPrefix("36 "), "3D com a alça real (pés + arco em gomos + brilho)")
        XCTAssertEqual(o["k"] as? String, "cog bola")
        XCTAssertEqual(o["kn"] as? String, "Puxador ponto Cog")
        XCTAssertEqual(o["salvo"] as? String, "luce192 cog {\"du\":60,\"dt\":150}", "modelo e lugar guardados no projeto")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// 🚪 Meus modelos de porta: a porta fica salva com o puxador E o lugar dele; um toque usa em todas as portas;
    /// a ⭐ já vem no projeto novo; não repete, dá pra apagar.
    func testModeloDePortaSalvoComPuxadorELugar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};delete PR.pxSave;delete PR.pxDoors;S.stones=[];S.rp=[];S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.mods=[];delete S.pxa;delete S.pxm;delete S.pxk;delete S.pxo;S.pxDef=null;
          var T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))},R={},Q=function(s){return document.querySelector('#bd '+s)};
          newTpl(T('inf','Balcão 2 portas'));S.m=S.mods[0];S.sv=0;draw();S.tab=3;panel();Q('[data-pxmd="mano"]').click();Q('[data-pxc2="dourado"]').click();
          var i=Q('[data-pxin="du"]');i.value='70';i.dispatchEvent(new Event('change',{bubbles:true}));
          Q('[data-pxsave="1"]').click();R.salvo=JSON.stringify(PR.pxDoors);R.padrao=JSON.stringify(PR.pxSave)===JSON.stringify(PR.pxDoors[0]);R.lista=document.querySelectorAll('#bd [data-pxdu]').length+' '+/Porta 1 ⭐/.test(Q('[data-pxbox]').textContent);
          Q('[data-pxsave="1"]').click();R.semRepetir=PR.pxDoors.length;
          /* outra porta: ponto Cog em outro lugar */
          Q('[data-pxkd="cog"]').click();i=Q('[data-pxin="dt"]');i.value='300';i.dispatchEvent(new Event('change',{bubbles:true}));Q('[data-pxsave="1"]').click();R.duas=PR.pxDoors.map(function(q){return q.px+':'+(q.pxm||q.pxk)+':'+q.pxa.du+'/'+q.pxa.dt}).join(' | ');
          /* volta pra porta 1 com um toque */
          Q('[data-pxdu="0"]').click();var p=partsOf(S.mods[0]).filter(q=>q.name==='Porta')[0],b=pxBar(p,S.mods[0],p.w,p.h);R.usou=p.px+' '+p.pxc+' '+S.pxm+' L'+b.L+' '+Math.round(p.w-b.u)+'/'+Math.round(p.h-b.v);
          R.guardado=/pxDoors/.test(localStorage.getItem(PRK)||'');
          /* projeto novo: já vem com a porta ⭐ */
          loadState(JSON.parse(JSON.stringify(window.__init0)));R.novo=S.pxm+' '+JSON.stringify(S.pxDef)+' '+JSON.stringify(S.pxa);newTpl(T('inf','Balcão 2 portas'));draw();var mm=S.mods[S.mods.length-1];p=partsOf(mm).filter(q=>q.name==='Porta')[0];b=pxBar(p,mm,p.w,p.h);R.porta=p.px+' '+p.pxc+' L'+b.L+' '+Math.round(p.hinge==='r'?b.u:p.w-b.u);
          S.tab=3;S.m=mm;panel();Q('[data-pxdst="1"]').click();R.estrela=PR.pxSave.px;Q('[data-pxddel="1"]').click();R.apagou=PR.pxDoors.length+' '+(PR.pxSave===undefined);
          R.errs=__errs;delete PR.pxSave;delete PR.pxDoors;try{prSave()}catch(_){}return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["salvo"] as? String, "[{\"px\":\"externo\",\"pxc\":\"dourado\",\"pxm\":\"mano128\",\"pxa\":{\"du\":70,\"dt\":166}}]")
        XCTAssertEqual(o["padrao"] as? Bool, true, "a primeira porta salva vira a dos projetos novos")
        XCTAssertEqual(o["lista"] as? String, "1 true")
        XCTAssertEqual((o["semRepetir"] as? NSNumber)?.intValue, 1, "não salva a mesma porta duas vezes")
        XCTAssertEqual(o["duas"] as? String, "externo:mano128:70/166 | bola:cog:70/300", "cada porta com o puxador e o lugar dela")
        XCTAssertEqual(o["usou"] as? String, "externo dourado mano128 L137 70/166", "um toque volta a porta salva, no lugar salvo")
        XCTAssertEqual(o["guardado"] as? Bool, true, "fica guardado no aparelho")
        XCTAssertEqual(o["novo"] as? String, "mano128 {\"px\":\"externo\",\"pxc\":\"dourado\"} {\"du\":70,\"dt\":166}", "projeto novo já vem com a porta ⭐")
        XCTAssertEqual(o["porta"] as? String, "externo dourado L137 70")
        XCTAssertEqual(o["estrela"] as? String, "bola", "troca a ⭐")
        XCTAssertEqual(o["apagou"] as? String, "1 true")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Régua espaçadora do canto: aparece no 2D (laranja), toque nela no 2D ou no 3D abre o quadro só dela (frente, trás,
    /// maior, menor, excluir). Ajustes › Portas: dobradiça reta ou curva muda a largura da porta e a conta da dobradiça.
    func testReguaEspacadoraEditavelEDobradicaRetaOuCurva() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          var R={};window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.mods=[];
          var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))};
          /* régua espaçadora do canto: aparece no 2D, toque abre o quadro só dela */
          newTpl(T('canto','Balcão canto cego · cego na direita (porta na esquerda)'));var m=S.m;draw();var P=partsOf(m),pi=P.findIndex(function(p){return p.crg}),rg=P[pi];R.cor=rg.col+' '+rg.cxz.join(',');
          var rc=document.querySelector('#svg g[data-mi="0"] rect[data-p="'+pi+'"]');R.no2d=!!rc;rc.dispatchEvent(new MouseEvent('click',{bubbles:true}));var bx=document.getElementById('crgbox');R.abriu=!!bx&&!bx.hidden;
          var K=function(k){bx.querySelector('[data-crgb="'+k+'"]').click()},G=function(){var p=partsOf(m).filter(function(q){return q.crg})[0];return p?p.cxz.join(',')+' cw'+p.cw:'sem'};
          K('f');K('f');R.frente=m.crgZ+' '+G();K('t');K('t');K('t');R.tras=m.crgZ+' '+G();K('z0');K('+');K('+');R.maior=G();K('-');R.menor=G();
          open3D();await W(500);__build();var b3=__boxes().filter(function(b){return /:Régua espaçadora do canto$/.test(String(b.nm))})[0];R.z3=Math.round(b3.z1-b3.z0);bx.hidden=true;var sp=__p3((b3.x0+b3.x1)/2,(b3.y0+b3.y1)/2,b3.z1);__tap3(sp[0],sp[1]);R.toque3d=!bx.hidden;
          K('del');R.excluiu=G()+' '+bx.hidden+' '+m.crg;document.getElementById('v3x').click();await W(200);
          /* dobradiça reta ou curva no Ajustes: a porta muda de largura sozinha e a conta da dobradiça acompanha */
          var s0=[STD().pS1,STD().pSn,STD().pViz];S.mods=[];newTpl(T('inf','Balcão 2 portas'));m=S.m;draw();var D=function(){var p=partsOf(m).filter(function(q){return q.name==='Porta'})[0],h=hgInfo(m,p);return p.w+' '+h.k+' '+h.D};R.curva=dobTipo()+' '+D();
          stdOpen(0,'portas');await W(100);R.botoes=document.querySelectorAll('#stdm [data-dobt]').length;document.querySelector('#stdm [data-dobt="reta"]').click();await W(100);R.reta=dobTipo()+' '+STD().pS1+' '+D();R.marcado=document.querySelector('#stdm [data-dobt="reta"]').className;
          document.querySelector('#stdm [data-dobt="curva"]').click();await W(100);R.voltou=dobTipo()+' '+D();document.getElementById('stdm').hidden=true;STD().pS1=s0[0];STD().pSn=s0[1];STD().pViz=s0[2];try{prSave()}catch(_){}
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cor"] as? String, "#e08a1e -55,-15")
        XCTAssertEqual(o["no2d"] as? Bool, true, "a régua aparece no 2D do móvel")
        XCTAssertEqual(o["abriu"] as? Bool, true, "toque nela no 2D abre o quadro")
        XCTAssertEqual(o["frente"] as? String, "10 -65,-25 cw40", "mais pra frente")
        XCTAssertEqual(o["tras"] as? String, "-5 -50,-10 cw40", "mais pra trás")
        XCTAssertEqual(o["maior"] as? String, "-65,-15 cw50")
        XCTAssertEqual(o["menor"] as? String, "-60,-15 cw45")
        XCTAssertEqual((o["z3"] as? NSNumber)?.intValue, 45, "3D acompanha")
        XCTAssertEqual(o["toque3d"] as? Bool, true, "toque nela no 3D abre o quadro")
        XCTAssertEqual(o["excluiu"] as? String, "sem true 0", "exclui só a régua")
        XCTAssertEqual(o["curva"] as? String, "curva 440 c 6")
        XCTAssertEqual((o["botoes"] as? NSNumber)?.intValue, 2)
        XCTAssertEqual(o["reta"] as? String, "reta 13 447 r 13", "reta: porta mais larga, cobre 13 da lateral")
        XCTAssertEqual(o["voltou"] as? String, "curva 440 c 6")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Puxador com a porta aberta tem o MESMO formato de fechada (ponto redondo não vira quadrado;
    /// mesma quantidade de peças e de cantos em cada peça), em porta de abrir e em basculante.
    func testPuxadorIgualComPortaAbertaEFechada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};delete PR.pxSave;delete PR.pxDoors;S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];delete S.pxa;delete S.pxm;delete S.pxk;delete S.pxo;S.pxDef=null;
          var T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))},R={},Q=function(s){return document.querySelector('#bd '+s)};
          newTpl(T('inf','Balcão 2 portas'));newTpl(T('sup','Aéreo basculante'));S.m=S.mods[0];S.sv=0;draw();S.tab=3;panel();
          var fmt=function(){var A=__ang();Object.keys(A.g).forEach(function(k){delete A.g[k]});Object.keys(A.t).forEach(function(k){delete A.t[k]});__build();var c={};__boxes().filter(function(b){return b.nol&&b.g==='f'}).forEach(function(b){var k=String(b.nm).split(':')[0]+(b.pf?'p':b.gp?'g':'b')+(b.pf?b.pf.pts.length:b.gp?b.gp.a.length:4);c[k]=(c[k]||0)+1});return Object.keys(c).sort().map(function(k){return k+'x'+c[k]}).join(' ')};
          var abre=function(o){S.mods.forEach(function(m){(m.v||[]).forEach(function(v){v.open=o})});draw()};
          open3D();await new Promise(r=>setTimeout(r,500));
          var roda=function(sel){document.getElementById('v3x').click();S.tab=3;S.m=S.mods[0];panel();Q(sel).click();open3D();abre(false);var f=fmt();abre(true);var a=fmt();abre(false);return f+' | '+a};
          R.cog=roda('[data-pxkd="cog"]');R.gazza=roda('[data-pxkd="gazza"]');R.luce=roda('[data-pxmd="luce"]');R.mano=roda('[data-pxmd="mano"]');R.bono=roda('[data-pxmd="bono"]');
          R.errs=__errs;return JSON.stringify(R);
          
          """#)
        XCTAssertEqual(o["cog"] as? String, "0p12x2 0p16x4 0p20x6 1p12x1 1p16x2 1p20x3 | 0g12x2 0g16x4 0g20x6 1g12x1 1g16x2 1g20x3", "Cog redondo fechado e aberto")
        XCTAssertEqual(o["gazza"] as? String, "0p12x2 0p8x6 1p12x1 1p8x3 | 0g12x2 0g8x6 1g12x1 1g8x3", "Gazza quadrado de canto quebrado")
        XCTAssertEqual(o["luce"] as? String, "0b4x32 0p12x4 1p12x2 1p4x16 | 0g12x4 0g4x32 1g12x2 1g4x16", "Luce em arco")
        XCTAssertEqual(o["mano"] as? String, "0b4x8 0p12x4 1p12x2 1p4x3 1p6x1 | 0g12x4 0g4x6 0g6x2 1g12x2 1g4x3 1g6x1", "Mano reta")
        XCTAssertEqual(o["bono"] as? String, "0p12x8 0p14x4 1p12x4 1p14x2 | 0g12x8 0g14x4 1g12x4 1g14x2", "Bono chata")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Bolinha do puxador no desenho 2D: segura e arrasta, todas as portas acompanham (par espelhado,
    /// aéreo de baixo pra cima); toque sem arrastar não muda nada; desfazer volta.
    func testPuxadorArrastaABolinhaNo2DEAsOutrasAcompanham() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};delete PR.pxSave;delete PR.pxDoors;S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];delete S.pxa;delete S.pxm;delete S.pxk;delete S.pxo;S.pxDef=null;
          var T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))},R={};
          newTpl(T('inf','Balcão 2 portas'));newTpl(T('sup','Aéreo 2 portas'));S.m=S.mods[0];S.sv=0;draw();S.tab=3;panel();document.querySelector('#bd [data-pxkd="cog"]').click();
          var gs=document.querySelectorAll('#svg [data-pxg]');R.bolinhas=gs.length;var g=gs[0],r=g.getBoundingClientRect(),cx=r.left+r.width/2,cy=r.top+r.height/2;
          var ev=function(n,x,y,el){(el||document.elementFromPoint(x,y)||document.body).dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:7,clientX:x,clientY:y,isPrimary:true}))};
          var und0=(typeof UND!=='undefined'?UND.length:-1);
          ev('pointerdown',cx,cy,g);ev('pointermove',cx+3,cy+2,document.body);R.semMexer=JSON.stringify(S.pxa||null);
          ev('pointermove',cx+2,cy-9,document.body);await new Promise(r=>setTimeout(r,60));R.txt=(document.querySelector('#svg text[fill="#1f6feb"]')||{}).textContent;ev('pointerup',cx+2,cy-9,document.body);
          R.pxa=!!(S.pxa&&S.pxa.du>=25&&S.pxa.dt>=25);R.igual=R.txt===S.pxa.du+' · '+S.pxa.dt;R.toast=TL[TL.length-1];
          var pos=function(mm){return partsOf(mm).filter(p=>p.name==='Porta').map(p=>{var b=pxBar(p,mm,p.w,p.h);return p.hinge+':'+Math.round(p.hinge==='r'?b.u:p.w-b.u)+' cima'+Math.round(p.h-b.v)+' baixo'+Math.round(b.v)})};var pb=pos(S.mods[0]),pa=pos(S.mods[1]);R.par=pb[0].slice(2)===pb[1].slice(2)&&pa[0].slice(2)===pa[1].slice(2);R.segue=pb[0].indexOf('l:'+S.pxa.du+' cima'+S.pxa.dt+' ')===0&&pa[0].indexOf('l:'+S.pxa.du+' ')===0&&/baixo(\d+)$/.exec(pa[0])[1]==S.pxa.dt;
          R.sel=S.mods.indexOf(S.m);R.semAzul=!document.querySelector('#svg text[fill="#1f6feb"]');
          var st=snapState();R.salvo=JSON.stringify(st.pxa)===JSON.stringify(S.pxa);var antes=JSON.stringify(S.pxa);
          /* toque sem arrastar não muda nada */
          g=document.querySelectorAll('#svg [data-pxg]')[0];r=g.getBoundingClientRect();ev('pointerdown',r.left+5,r.top+5,g);ev('pointerup',r.left+5,r.top+5,document.body);R.toque=(JSON.stringify(S.pxa)===antes)+' '+TL[TL.length-1];
          document.getElementById('und')?document.getElementById('und').click():0;R.desfez=JSON.stringify(S.pxa||null);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["bolinhas"] as? Int, 4, "uma bolinha em cada porta")
        XCTAssertEqual(o["semMexer"] as? String, "null", "mexeu menos de 5 pontos: não muda")
        XCTAssertEqual(o["pxa"] as? Bool, true)
        XCTAssertEqual(o["igual"] as? Bool, true, "mostra a medida enquanto arrasta")
        XCTAssertEqual(o["par"] as? Bool, true, "porta par espelhada")
        XCTAssertEqual(o["segue"] as? Bool, true, "todas as portas no mesmo lugar")
        XCTAssertEqual(o["salvo"] as? Bool, true, "guardado no projeto")
        XCTAssertEqual(o["toque"] as? String, "true Segure a bolinha e arraste pra pôr o puxador no lugar")
        XCTAssertEqual(o["desfez"] as? String, "null", "desfazer volta")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Frontal da base (rodapé da frente) rente com o fim da lateral em todos os módulos; projeto antigo acompanha.
    /// Tamponamento diminui no 3D pela bolinha sem travar nem pular (no máximo 5 mm por ponto) e aceita medida digitada.
    func testFrontalDaBaseRenteETamponamentoDiminuiNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=9000;S.H=2700;S.mods=[];var R={};
          var T=function(cat,n){return JSON.parse(JSON.stringify(CATS.filter(function(x){return x.id===cat})[0].it.filter(function(q){return q.n===n})[0]))};
          /* 1) frontal da base rente com o fim da lateral em TODO módulo de baixo (canto fica de fora: ali ele para no canto) */
          var n=0,bad=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it||!it.v||it.act)return;S.mods=[];try{newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];if(m.corner||m.latPiso)return;var le=m.semLE?0:0,P=partsOf(m);P.forEach(function(p){if(p.name!=='Rodapé (pedestal)')return;n++;if(Math.abs(p.x)>.5||Math.abs(p.x+p.w-m.w)>.5)bad.push(it.n+' '+p.x+'/'+(m.w-p.x-p.w))})}catch(e){bad.push(it.n+' EXC')}})});R.frontais=n>80;R.fora=bad.slice(0,6);R.std=STD().rodRecL;
          /* projeto antigo (recuo 30 gravado no módulo) acompanha */
          S.mods=[];newTpl(T('inf','Balcão 2 portas'));S.mods[0].rodRecL=30;var st=snapState();loadState(JSON.parse(JSON.stringify(st)));var f=partsOf(S.mods[0]).filter(function(p){return p.name==='Rodapé (pedestal)'})[0];R.antigo=f.x+' '+f.w;
          /* 2) tamponamento: diminuir no 3D arrastando a bolinha, sem travar e sem pular */
          S.mods=[];newTpl(T('inf','Balcão 2 portas'));S.mods[0].x=600;S.mods[0].tl=S.mods[0].tr=true;draw();open3D();await new Promise(function(r){setTimeout(r,500)});
          var pk='Tamponamento esquerdo#1',H0=partsOf(S.mods[0]).filter(function(p){return p.pk===pk})[0].h;
          var drag=function(hk,dx,dy,st_){delete (S.mods[0].po||{})[pk];__e3open(0,pk);var h=document.querySelector('[data-hk="'+hk+'"]');if(!h)return null;var r=h.getBoundingClientRect(),x=r.left+15,y=r.top+15,ev=function(nm,X,Y){h.dispatchEvent(new PointerEvent(nm,{bubbles:true,cancelable:true,pointerId:5,clientX:X,clientY:Y,isPrimary:true}))};ev('pointerdown',x,y);for(var i=1;i<=st_;i++)ev('pointermove',x+dx*i/st_,y+dy*i/st_);ev('pointerup',x+dx,y+dy);var p=partsOf(S.mods[0]).filter(function(q){return q.pk===pk})[0];return {h:p.h,d:p.cw}};
          var a=drag('et',0,3,3),b=drag('et',0,6,3),c=drag('ef',-5,-5,5);R.bolinhas=!!a;R.pouco=a&&a.h<H0&&H0-a.h<=15;R.mais=b&&b.h<a.h&&H0-b.h<=30;R.fundo=c&&c.d<585;
          delete (S.mods[0].po||{})[pk];var t=__e3t(0,pk,1,600);R.digitou=partsOf(S.mods[0]).filter(function(q){return q.pk===pk})[0].h;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["frontais"] as? Bool, true)
        XCTAssertEqual((o["fora"] as? [Any])?.count ?? 9, 0, "frontal fora do fim da lateral: \(o["fora"] ?? "")")
        XCTAssertEqual(o["antigo"] as? String, "0 900", "projeto antigo (recuo 30) fica rente também")
        XCTAssertEqual(o["bolinhas"] as? Bool, true)
        XCTAssertEqual(o["pouco"] as? Bool, true, "diminui só um pouco sem travar")
        XCTAssertEqual(o["mais"] as? Bool, true, "sem pular")
        XCTAssertEqual(o["fundo"] as? Bool, true, "profundidade também")
        XCTAssertEqual(o["digitou"] as? Double, 600, "medida digitada")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Nicho com porta de vidro basculante embaixo do aéreo: mesma largura e fundo, encostado nele; "todos" põe em cada aéreo livre.
    func testNichoDeVidroBasculanteEmbaixoDoAereo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];S.fr=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n)r=q})});return JSON.parse(JSON.stringify(r))};
          R.semAereo=addNichoVidro(0).length+' '+TL[TL.length-1];
          newTpl(T('Aéreo 2 portas'));newTpl(T('Aéreo basculante'));newTpl(T('Balcão 2 portas'));draw();var a=S.mods[0],b=S.mods[1];
          var it=CATS.filter(function(c){return c.id==='sup'})[0].it.filter(function(i){return i&&i.act==='nichoVidro'});R.cat=it.length;
          S.m=a;R.um=catAct2(it[0])+' '+S.mods.length;var n=S.mods[S.mods.length-1];R.lugar=[n.x===a.x,n.w===a.w,n.d===a.d,n.b+n.h===a.b,n.h].join(' ');
          var P=partsOf(n).filter(function(p){return p.name==='Porta'});R.porta=P.length+' '+/PORTA DE VIDRO/.test(P[0].note||'')+' '+!!n.v[0].bas+' '+!!n.v[0].vidro;
          R.todos=catAct2(it[1])+' '+S.mods.filter(function(m){return m.nichoVidro}).length;R.denovo=addNichoVidro(1).length+' '+TL[TL.length-1];
          R.semBater=!S.mods.some(function(o){return typeof modHit==='function'&&modHit(o)});R.salva=snapState().mods.filter(function(m){return m.nichoVidro}).length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semAereo"] as? String, "0 Ponha um armário aéreo primeiro: o nicho de vidro vai embaixo dele")
        XCTAssertEqual(o["cat"] as? Int, 2, "duas opções no catálogo dos aéreos")
        XCTAssertEqual(o["um"] as? String, "true 4")
        XCTAssertEqual(o["lugar"] as? String, "true true true true 350", "alinhado e encostado embaixo do aéreo")
        XCTAssertEqual(o["porta"] as? String, "1 true true true", "uma porta de vidro basculante")
        XCTAssertEqual(o["todos"] as? String, "true 2", "embaixo de todos os aéreos livres")
        XCTAssertEqual(o["denovo"] as? String, "0 Já tem módulo embaixo dos aéreos", "não repete")
        XCTAssertEqual(o["semBater"] as? Bool, true)
        XCTAssertEqual(o["salva"] as? Int, 2)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Visor aceso com números: relógio 12:00 no forno e no micro-ondas da torre (21 + 21 traços) e temperatura na geladeira (16).
    func testVisorComNumerosNoFornoMicroEGeladeira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=2600;S.H=2700;S.mods=[];S.fr=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n)r=q})});return JSON.parse(JSON.stringify(r))};
          var cnt=function(){__build();return __boxes().filter(function(b){return b.em&&b.nol&&(b.z1-b.z0<1||b.pf||b.gp)}).length};
          open3D();await new Promise(function(r){setTimeout(r,400)});R.vazio=cnt();
          newTpl(T('Torre forno + micro-ondas (embutir)'));S.mods[0].x=300;draw();R.torre=cnt();
          var gi=APM.geladeira.m.findIndex(function(m){return /Inverse/.test(m[0])}),g=apAdd('geladeira',gi);g.x=1100;draw();R.geladeira=cnt()-R.torre;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["vazio"] as? Int, 0)
        XCTAssertEqual(o["torre"] as? Int, 42, "12:00 no forno e no micro-ondas")
        XCTAssertEqual(o["geladeira"] as? Int, 16, "4° -18° na porta da geladeira")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Tamponamento esticado pro lado no 3D (bolinha) entra na hora no plano de corte: lista, desenho da chapa e painel do módulo.
    func testTamponamentoEsticadoNo3DEntraNoPlanoDeCorteNaHora() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=5000;S.H=2700;S.mods=[];S.fr=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Rack suspenso'));newTpl(T('Rack suspenso'));var a=S.mods[0],b=S.mods[1];a.x=600;a.w=900;b.w=900;b.x=1500;S.mods.forEach(function(m){m.tt=true});draw();
          /* o que o marceneiro vê: a lista do plano de corte e o desenho da chapa */
          var plano=function(){document.getElementById('cutb').click();var row=[].filter.call(document.querySelectorAll('#cutm tr'),function(r){return /^Tamponamento de cima \(peça única\) · face/.test(r.textContent.trim())&&r.cells.length>2})[0],L=0;if(row)[].forEach.call(row.cells,function(c){var m=/^(\d+) × 425 mm/.exec(c.textContent.trim());if(m)L=+m[1]});var sv=[].map.call(document.querySelectorAll('#cutm svg text'),function(x){return x.textContent});document.getElementById('cutm').hidden=true;return {L:L,chapa:sv.indexOf(String(L))>=0}};
          var p0=plano();R.antes=p0.L+' '+p0.chapa;
          open3D();await new Promise(function(r){setTimeout(r,400)});var pk='Tamponamento de cima#1';
          /* arrasta a bolinha do lado no 3D */
          __e3open(1,pk);var h=document.querySelector('[data-hk="er"]');R.bolinha=!!h;var rc=h.getBoundingClientRect(),x=rc.left+15,y=rc.top+15,ev=function(nm,X,Y){h.dispatchEvent(new PointerEvent(nm,{bubbles:true,cancelable:true,pointerId:5,clientX:X,clientY:Y,isPrimary:true}))};ev('pointerdown',x,y);for(var i=1;i<=6;i++)ev('pointermove',x+i*8,y+i*2);ev('pointerup',x+48,y+12);
          var er=((b.po||{})[pk]||{}).er||0;R.esticou=er>0;document.getElementById('v3x').click();
          var p1=plano();R.depois=(p1.L===p0.L+er)+' '+p1.chapa;
          /* painel do módulo (aba Tamponamentos) mostra a medida nova */S.m=b;S.tab=4;panel();R.painel=document.getElementById('bd').textContent.indexOf('Tamponamento de cima (30 mm)'+(930+er)+' × 425')>=0;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["antes"] as? String, "1860 true", "peça única por cima dos dois módulos, desenhada na chapa")
        XCTAssertEqual(o["bolinha"] as? Bool, true)
        XCTAssertEqual(o["esticou"] as? Bool, true)
        XCTAssertEqual(o["depois"] as? String, "true true", "lista e chapa com a medida nova, sem precisar recalcular")
        XCTAssertEqual(o["painel"] as? Bool, true, "painel do módulo com a medida nova")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Portas de canto com dobradiça 165° (robocop): a folha do lado vai até 3 mm do armário, a do fundo fica 3,4 mm dela;
    /// abre uma e depois a outra; aberta não entra em nada (com tamponamento na ponta abre só 90°).
    /// Painel cego nunca abre. Torre: frente fixa do forno a 3 mm da porta de baixo.
    func testPortasDeCantoRobocopAbremEmOrdemSemEntrarEmNada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];var R={};
          newTpl(7);var m=S.mods[0];m.tl=m.tr=false;draw();open3D();await new Promise(function(r){setTimeout(r,500)});
          var P=function(){return partsOf(m).filter(function(p){return p.name==='Porta'}).map(function(p){return p.dq+':'+p.cl+':'+p.open}).join(' ')};
          var bx=function(){return __boxes().filter(function(b){return /:Porta$/.test(String(b.nm))&&!b.nol&&!b.hg&&b.pf}).sort(function(a,b){return a.dq-b.dq})};
          var inst=function(){var A=__ang();Object.keys(A.g).forEach(function(k){delete A.g[k]});Object.keys(A.t).forEach(function(k){delete A.t[k]});__build()};
          R.medidas=P();var F=bx();/* fechada: a do lado vai até 3 mm do armário; a do fundo fica 3,4 mm dela */R.folgaArmario=Math.round((F[1].z0-(m.d+6))*10)/10;R.folgaPorta=Math.round((F[0].x0-F[1].x1)*10)/10;
          /* abrir a do lado abre primeiro a do fundo */m.v[0].od={1:true};draw();R.abreAsDuas=P();anim3();var A=__ang(),t0_=Date.now();while(!(A.g['p0|0|0']>0)&&Date.now()-t0_<4000)await new Promise(function(r){setTimeout(r,16)});R.primeiro=(A.g['p0|0|0']>0)+' '+(A.g['p0|0|0']<60?(A.g['p0|0|1']||0):0);
          var t1_=Date.now();while(!(A.g['p0|0|0']>=164.5&&A.g['p0|0|1']>=164.5)&&Date.now()-t1_<9000)await new Promise(function(r){setTimeout(r,50)});R.fim=Math.round(A.g['p0|0|0'])+' '+Math.round(A.g['p0|0|1']);
          var hit=function(){var C=__boxes().filter(function(b){return /^\d+:(Lateral|Base|Fundo|Prateleira|Tamponamento)/.test(String(b.nm))&&!b.pf&&!b.gp}),D=bx(),h=0;D.forEach(function(a){C.concat(D).forEach(function(b){if(a===b)return;var ox=Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0),oy=Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0),oz=Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0);if(ox>1.2&&oy>1.2&&oz>1.2)h++})});return h};
          R.entra165=hit();
          /* com tamponamento nas duas pontas: 90° e a do lado um pouco menos · sem entrar em nada */
          m.tl=m.tr=true;draw();inst();var A2=__ang();R.comTamp=A2.t['p0|0|0']+' '+(A2.t['p0|0|1']<90)+' '+hit();
          R.nota=partsOf(m).filter(function(p){return p.name==='Porta'}).map(function(p){return /165° super curva \(robocop\)/.test(p.note)}).join(' ');
          /* painel cego do canto reto nunca abre */
          document.getElementById('v3x').click();S.mods=[];var cg=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n==='Balcão canto cego · cego na direita (porta na esquerda)')cg=q})});newTpl(JSON.parse(JSON.stringify(cg)));var c=S.mods[0];c.v.forEach(function(v){v.open=true});draw();R.cego=partsOf(c).filter(function(p){return p.name==='Porta'}).map(function(p){return p.open?1:0}).join('');
          /* torre: frente fixa do forno a 3 mm da porta de baixo */
          S.mods=[];var tw=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.n==='Torre por vãos · forno + micro com porta de recorte')tw=q})});newTpl(JSON.parse(JSON.stringify(tw)));var T2=partsOf(S.mods[0]).filter(function(p){return p.name==='Porta'||/^Frente com recorte/.test(p.name)}).sort(function(a,b){return a.y-b.y}),gs=[];for(var i=0;i<T2.length-1;i++)gs.push(Math.round((T2[i+1].y-(T2[i].y+T2[i].h))*10)/10);R.torre=gs.join(' ');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["medidas"] as? String, "0:306.1:0 1:309:0", "fundo = vão − 12,9 · lado = vão − 10")
        XCTAssertEqual(o["folgaArmario"] as? Double, 3, "a folha do lado para a 3 mm do armário")
        XCTAssertEqual(o["folgaPorta"] as? Double, 3.4, "a do fundo fica 3,4 mm da folha do lado")
        XCTAssertEqual(o["abreAsDuas"] as? String, "0:306.1:1 1:309:1", "abrir a do lado abre a do fundo junto")
        XCTAssertEqual(o["primeiro"] as? String, "true 0", "primeiro sai a do fundo; a do lado espera")
        XCTAssertEqual(o["fim"] as? String, "165 165")
        XCTAssertEqual(o["entra165"] as? Int, 0, "aberta 165° não entra em nada")
        XCTAssertEqual(o["comTamp"] as? String, "90 true 0", "com tamponamento: 90°, a do lado um pouco menos, sem bater")
        XCTAssertEqual(o["nota"] as? String, "true true")
        XCTAssertEqual(o["cego"] as? String, "10", "painel cego fixo nunca abre")
        XCTAssertEqual(o["torre"] as? String, "8 3 3", "frentes da torre com folga, sem entrar uma na outra")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Armário com maleiro: porta inteira (uma só de baixo até em cima, cabe na chapa até 2700) ou maleiro com porta própria.
    func testPortaInteiraOuMaleiroComPortaPropria() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.W=4000;S.H=2800;S.mods=[];S.fr=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Guarda-roupa 2 vãos'));var m=S.mods[0];S.m=m;draw();S.tab=3;panel();R.semMaleiro=!document.querySelector('#bd [data-pintbox]');
          rgAddStack('mal');var c=S.mods[1];
          var D=function(q){return partsOf(q).filter(function(p){return p.name==='Porta'}).map(function(p){return Math.round(p.w)+'x'+p.h+'@'+p.y}).join(' ')};
          S.m=m;S.tab=3;panel();R.caixa=!!document.querySelector('#bd [data-pintbox]')+' '+[].map.call(document.querySelectorAll('#bd [data-pint]'),function(b){return b.className}).join('|');R.antes=D(m)+' | '+D(c);
          document.querySelector('#bd [data-pint="1"]').click();R.inteira=D(m)+' | '+D(c);R.toast=TL[TL.length-1];R.nota=/PORTA INTEIRA/.test(partsOf(m).filter(function(p){return p.name==='Porta'})[0].note);
          var G=cutGroups(),ls=G.ord.map(function(k){return G.map[k]}).filter(function(l){return l.names.some(function(n){return /^Porta/.test(n)})}).map(function(l){return l.L+'x'+l.W+' q'+l.qty});R.corte=ls;
          open3D();await new Promise(function(r){setTimeout(r,400)});var B=__boxes().filter(function(b){return /:Porta$/.test(String(b.nm))&&!b.nol&&!b.hg&&(b.y1-b.y0)>200});R.b3=B.length+' '+Math.round(Math.min.apply(null,B.map(function(b){return b.y0})))+'-'+Math.round(Math.max.apply(null,B.map(function(b){return b.y1})));document.getElementById('v3x').click();
          S.m=c;S.tab=3;panel();R.noMaleiro=!!document.querySelector('#bd [data-pintbox]');document.querySelector('#bd [data-pint="0"]').click();R.separada=D(m)+' | '+D(c);
          /* alto demais: não cabe na chapa */
          m.pInt=1;c.h=700;draw();R.naoCabe=D(m).split(' ')[0]+' | '+D(c).split(' ')[0];S.m=m;S.tab=3;panel();R.aviso=/não cabe/.test(document.querySelector('#bd [data-pintbox]').textContent)+' '+document.querySelector('#bd [data-pint="1"]').disabled;
          R.salva=snapState().mods[0].pInt;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semMaleiro"] as? Bool, true, "sem maleiro não aparece a escolha")
        XCTAssertEqual(o["caixa"] as? String, "true |sel", "padrão: maleiro com porta própria")
        XCTAssertEqual(o["antes"] as? String, "444x2300@-10 444x2300@-10 444x2300@-10 444x2300@-10 | 890x400@-5 890x400@-5")
        XCTAssertEqual(o["inteira"] as? String, "444x2695@-405 444x2695@-405 444x2695@-405 444x2695@-405 | ", "porta sobe e cobre o maleiro; maleiro sem porta")
        XCTAssertEqual(o["nota"] as? Bool, true)
        XCTAssertEqual(o["corte"] as? [String], ["443.5x2695 q4"], "plano de corte com a porta inteira")
        XCTAssertEqual(o["b3"] as? String, "4 110-2805", "3D: 4 portas de baixo até em cima")
        XCTAssertEqual(o["noMaleiro"] as? Bool, true, "dá pra trocar tocando no maleiro também")
        XCTAssertEqual(o["separada"] as? String, "444x2300@-10 444x2300@-10 444x2300@-10 444x2300@-10 | 890x400@-5 890x400@-5", "volta")
        XCTAssertEqual(o["naoCabe"] as? String, "444x2300@-10 | 890x700@-5", "passou de 2700: fica separada")
        XCTAssertEqual(o["aviso"] as? String, "true true")
        XCTAssertEqual(o["salva"] as? Int, 1)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Gola vertical em porta comum (perfil em pé na borda que abre, porta 30 mm mais estreita) e gola horizontal no topo;
    /// todo tipo de puxador tem desenho na lista.
    func testGolaVerticalEHorizontalEDesenhoDeCadaPuxador() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];S.fr=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Aéreo 2 portas'));var m=S.mods[0],a=S.mods[1];S.m=m;S.sv=0;draw();
          var D=function(q){return partsOf(q).filter(function(p){return /^Porta$|gola/.test(p.name)}).map(function(p){return p.name.slice(0,12)+' x'+p.x+' w'+p.w+' cl'+p.cl+' cw'+p.cw+(p.gola?' G'+p.golaW:'')+' '+(p.hinge||'')}).join(' | ')};
          R.antes=D(m);S.tab=3;panel();var bts=[].map.call(document.querySelectorAll('#bd [data-pxt]'),function(b){return b.dataset.pxt+(b.querySelector('img')?'*':'')});R.lista=bts.join(',');
          var b=document.querySelector('#bd [data-pxt="gv"]');R.txt=b.textContent.trim();b.click();R.gv=D(m);R.v=m.v[0].px;
          var G=cutGroups(),ls=G.ord.map(function(k){return G.map[k]}).filter(function(l){return l.names.some(function(n){return /^Porta/.test(n)})}).map(function(l){return l.L+'x'+l.W+' q'+l.qty});R.corte=ls;
          R.svg=document.querySelectorAll('#svg rect[opacity=".3"]').length;
          open3D();await new Promise(function(r){setTimeout(r,400)});var B=__boxes().filter(function(b){return b.nol&&/^0:Porta/.test(String(b.nm))});R.b3=B.length;document.getElementById('v3x').click();
          S.m=m;S.sv=0;S.tab=3;panel();document.querySelector('#bd [data-pxt="g"]').click();R.g=D(m).slice(0,90)+' '+partsOf(m).filter(function(p){return p.name==='Porta'})[0].h;
          document.querySelector('#bd [data-pxt="externo"]').click();R.volta=D(m)===R.antes;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["lista"] as? String, "cava*,facetado*,concha*,g*,gv*,perfil*,externo*,bola*,toque*,nenhum*", "todos com desenho")
        XCTAssertEqual(o["gv"] as? String, "Porta x9 w410 cl410 cw705 G30 l | Porta x481 w410 cl410 cw705 G30 r | Puxador gola x419 w30 cl30 cw705  | Puxador gola x451 w30 cl30 cw705 ", "porta 30 mais estreita + perfil na borda que abre")
        XCTAssertEqual(o["corte"] as? [String], ["410x705 q2", "490x750 q2"])
        XCTAssertEqual(o["svg"] as? Int, 2, "perfil desenhado no 2D")
        XCTAssertEqual(o["b3"] as? Int, 12, "perfil G no 3D junto com a porta")
        XCTAssertEqual(o["g"] as? String, "Porta x9 w440 cl440 cw676 l | Porta x451 w440 cl440 cw676 r 676", "gola horizontal: porta mais baixa pro perfil no topo")
        XCTAssertEqual(o["volta"] as? Bool, true)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Aba Portas mais simples: escolhe o vão, quantas portas e o puxador; o resto fica em "Mais opções" (fechado) e continua funcionando.
    /// Quadros por cima do desenho ganham ▁ pra minimizar (o da peça no 3D já tem o dele).
    func testAbaPortasSimplesEMinimizarQuadros() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Balcão 2 portas + 4 gavetas'));var m=S.mods[0];S.m=m;S.sv=0;draw();S.tab=3;panel();var bd=document.getElementById('bd'),K=[].slice.call(bd.children);
          var ix=function(re){for(var i=0;i<K.length;i++)if(re.test(K[i].textContent.trim()))return i;return -1};
          R.ordem=[ix(/^Toque no vão que vai ganhar porta/),ix(/^1 · Quantas portas neste vão/),ix(/^1 porta/),ix(/^⚙ Mais opções da porta/),ix(/^2 · Puxador da porta/)].join('<');
          var d=bd.querySelector('[data-pmais]');R.fechado=!d.open;R.dentro=[/Abrir a porta/,/Porta de vidro/,/Furo da dobradiça/,/Porta basculante/].every(function(re){return re.test(d.textContent)});
          /* continua funcionando: 1 porta, e abrir a porta lá de dentro */
          var b1=[].filter.call(bd.querySelectorAll('button'),function(b){return b.textContent.trim()==='1 porta'})[0];b1.click();R.umaPorta=partsOf(m).filter(function(p){return p.name==='Porta'&&p.vi===0}).length;
          bd=document.getElementById('bd');d=bd.querySelector('[data-pmais]');var c=[].filter.call(d.querySelectorAll('input[type=checkbox]'),function(i){return /Abrir a porta/.test(i.closest('.chk').textContent)})[0];R.chk=!!c;if(c){c.click();R.abriu=!!m.v[0].open}
          /* com vidro ligado as opções já vêm abertas */m.v[0].open=false;m.v[0].vidro=true;panel();R.abertoComVidro=document.querySelector('#bd [data-pmais]').open;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["ordem"] as? String, "5<7<8<9<10", "vão, quantas portas, mais opções, puxador")
        XCTAssertEqual(o["fechado"] as? Bool, true)
        XCTAssertEqual(o["dentro"] as? Bool, true, "abrir, vidro, furo e basculante guardados")
        XCTAssertEqual(o["umaPorta"] as? Int, 1)
        XCTAssertEqual(o["abriu"] as? Bool, true, "as opções guardadas continuam funcionando")
        XCTAssertEqual(o["abertoComVidro"] as? Bool, true)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
        let web2 = try await editor()
        let q = try await run(web2, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.stones=[];S.rp=[];S.W=3000;S.H=2700;S.mods=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Balcão canto cego · cego na direita (porta na esquerda)'));draw();crgBox(0);__minScan();var e=document.getElementById('crgbox'),b=e.querySelector('[data-minb]');R.botao=!!b&&b.textContent;var h0=e.getBoundingClientRect().height;
          b.click();R.min=e.querySelector('[data-minb]').textContent+' '+(e.getBoundingClientRect().height<=40)+' '+(h0>60);
          /* o quadro se redesenha: continua minimizado */crgBox(0);__minScan();e=document.getElementById('crgbox');R.continua=e.getBoundingClientRect().height<=40;
          e.querySelector('[data-minb]').click();R.abre=e.querySelector('[data-minb]').textContent+' '+(e.getBoundingClientRect().height>60);
          /* fechou e abriu de novo: abre inteiro */e.querySelector('[data-minb]').click();e.hidden=true;__minScan();e.hidden=false;__minScan();R.novo=e.getBoundingClientRect().height>60;
          /* quadro da peça no 3D já tem o dele: não ganha outro por cima */open3D();await new Promise(function(r){setTimeout(r,400)});__e3open(0,partsOf(S.mods[0]).filter(function(p){return p.name==='Lateral esquerda'})[0].pk);__minScan();R.e3=document.querySelectorAll('#e3 [data-minb]').length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(q["botao"] as? String, "▁")
        XCTAssertEqual(q["min"] as? String, "▢ abrir true true", "encolhe e deixa ver a tela")
        XCTAssertEqual(q["continua"] as? Bool, true, "redesenhou: continua minimizado")
        XCTAssertEqual(q["abre"] as? String, "▁ true")
        XCTAssertEqual(q["novo"] as? Bool, true, "abriu de novo: vem inteiro")
        XCTAssertEqual(q["e3"] as? Int, 0, "quadro da peça já tem o botão dele")
        XCTAssertEqual((q["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(q["errs"] ?? "")")
    }

    /// Rebaixo do teto (gesso/viga) no ambiente: o painel acompanha (divide na quina e fica na altura do rebaixo),
    /// aparece no 2D e no 3D, toque nele no 3D abre o quadro, guarda no projeto, vale nas paredes laterais.
    func testRebaixoDoTetoEPainelAcompanha() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];var R={};draw();
          S.rp=[{id:11,liso:true,x:0,b:0,w:3000,h:2700}];draw();
          var P=function(){return (S.rp||[]).map(function(a){return a.x+'+'+a.w+'x'+a.h}).join(' | ')};R.antes=P();
          var z=tzAdd('f',{x:1000,w:1200,hc:2400});R.box=!document.getElementById('tzbox').hidden;R.divide=P();R.ids=new Set(S.rp.map(function(a){return a.id})).size;
          R.d2=document.querySelectorAll('#svg [data-tz2]').length+' '+(document.querySelector('#svg [data-tz2] text')||{}).textContent;
          /* muda a altura digitando: os painéis de baixo acompanham */
          var i=document.querySelector('#tzbox [data-tzf="hc"]');i.value='2300';i.dispatchEvent(new Event('change',{bubbles:true}));R.maisBaixo=P();
          /* painel novo que nasce atravessando o rebaixo já sai dividido */
          S.rp.push({id:99,liso:true,x:3000,b:0,w:1000,h:2700});var z2=tzAdd('f',{x:3500,w:500,hc:2500});R.novo=P();
          /* prateleira e painel travado não mexem */
          S.rp.push({id:77,prat:1,x:1100,b:2350,w:800,h:25});draw();R.prat=S.rp.filter(function(a){return a.id===77})[0].b;
          /* 3D: caixa do rebaixo pendurada no teto; toque nela abre o quadro */
          document.querySelector('#tzbox [data-tzb="ok"]').click();R.fechou=document.getElementById('tzbox').hidden;
          open3D();await new Promise(function(r){setTimeout(r,500)});var B=__boxes().filter(function(b){return b.tz});R.b3=B.length+' '+B.map(function(b){return [b.x0,b.x1,b.y0,b.y1,b.z0,b.z1].join(',')}).join(' / ');
          var c=B[0],p=__p3((c.x0+c.x1)/2,(c.y0+c.y1)/2,c.z1);__tap3(p[0],p[1]);R.toque=!document.getElementById('tzbox').hidden+' '+(window.TZSEL===z.id);document.getElementById('v3x').click();
          /* guarda no projeto e volta */
          var st=snapState();R.salva=(st.tz||[]).length;loadState(JSON.parse(JSON.stringify(st)));R.volta=(S.tz||[]).length;
          /* apagar */
          tzBox(S.tz[0].id);document.querySelector('#tzbox [data-tzb="del"]').click();R.apagou=S.tz.length+' '+TL[TL.length-1];
          /* parede lateral */
          var ze=tzAdd('e',{x:0,w:800,hc:2200,d:400});var g=tzGeo(ze);R.lateral=[g.x0,g.x1,g.z0,g.z1,g.y0,g.y1].join(',');R.limE=tzLim('e',100,500)+' '+tzLim('e',900,1200)+' '+tzLim('f',0,500);
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["antes"] as? String, "0+3000x2700")
        XCTAssertEqual(o["box"] as? Bool, true)
        XCTAssertEqual(o["divide"] as? String, "0+1000x2700 | 1000+1200x2400 | 2200+800x2700", "painel dividido na quina do rebaixo")
        XCTAssertEqual(o["ids"] as? Int, 3)
        XCTAssertEqual(o["d2"] as? String, "1 Rebaixo do teto · 2400 do chão")
        XCTAssertEqual(o["maisBaixo"] as? String, "0+1000x2700 | 1000+1200x2300 | 2200+800x2700", "mudou a altura: o painel de baixo acompanha")
        XCTAssertEqual(o["novo"] as? String, "0+1000x2700 | 1000+1200x2300 | 2200+800x2700 | 3000+500x2700 | 3500+500x2500", "painel novo já nasce em volta do rebaixo")
        XCTAssertEqual(o["prat"] as? Int, 2350, "prateleira não mexe")
        XCTAssertEqual(o["b3"] as? String, "4 1000,2200,2314,2700,0,2600 / 1000,2200,2300,2314,0,2600 / 3500,4000,2514,2700,0,2600 / 3500,4000,2500,2514,0,2600", "3D: rebaixo total (vai até a frente do ambiente)")
        XCTAssertEqual(o["toque"] as? String, "true true", "toque no rebaixo no 3D abre o quadro dele")
        XCTAssertEqual(o["salva"] as? Int, 2)
        XCTAssertEqual(o["volta"] as? Int, 2)
        XCTAssertEqual(o["apagou"] as? String, "1 Rebaixo do teto apagado")
        XCTAssertEqual(o["lateral"] as? String, "0,400,0,800,2200,2700", "rebaixo na parede da esquerda")
        XCTAssertEqual(o["limE"] as? String, "2200 2700 2700")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Lista de puxadores com cada modelo desenhado na porta; acabamentos prontos pintam portas, armários e piso do projeto inteiro.
    func testPuxadoresNaPortaEAcabamentosProntos() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.W=3400;S.H=2700;S.mods=[];var R={};
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Aéreo 2 portas'));S.m=S.mods[0];S.sv=0;draw();
          /* lista de puxadores: cada modelo desenhado na porta */
          S.tab=3;panel();var bx=document.querySelector('#bd [data-pxbox]');R.cards=bx.querySelectorAll('[data-pxmd],[data-pxkd]').length+' '+bx.querySelectorAll('[data-pxdoor]').length;R.umPorCard=[].every.call(bx.querySelectorAll('[data-pxmd],[data-pxkd]'),function(c){return c.querySelectorAll('[data-pxdoor]').length===1});
          /* acabamentos prontos */
          S.tab=10;panel();R.botoes=document.querySelectorAll('#bd [data-acabu]').length;
          ACABP.forEach(function(a){var n=acabUsar(a[0]);R[a[0]]=n+' '+S.mods.map(function(m){return m.corFId+'/'+m.corId}).filter(function(v,i,A){return A.indexOf(v)===i}).join(',')+' '+(JSON.stringify(snapState()).indexOf(a[4])>0)});
          document.querySelector('#bd [data-acabu="grafite"]').click();R.toque=TL[TL.length-1];R.tab=S.tab;R.cores=S.mods[0].corF+' '+S.mods[1].corF;
          /* a lista de corte continua funcionando com as cores novas */var G=cutGroups();R.corte=G.ord.length>5;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cards"] as? String, "8 8", "cada modelo de alça e ponto com a porta desenhada")
        XCTAssertEqual(o["umPorCard"] as? Bool, true)
        XCTAssertEqual(o["botoes"] as? Int, 6)
        XCTAssertEqual(o["fendi"] as? String, "3 arauco-connect-matt/arauco-connect-matt true")
        XCTAssertEqual(o["grafite"] as? String, "3 arauco-grafito-chess/arauco-louro-freijo-poro true")
        XCTAssertEqual(o["branco"] as? String, "3 arauco-branco-supremo-matt/arauco-carvalho-poro true")
        XCTAssertEqual(o["preto"] as? String, "3 arauco-ebano-chess/arauco-nogueira-persa-trend true")
        XCTAssertEqual(o["freijo"] as? String, "3 arauco-louro-freijo-poro/arauco-branco-supremo-matt true")
        XCTAssertEqual(o["cinza"] as? String, "3 arauco-cinza-puro-matt/arauco-cumaru-trend true")
        XCTAssertEqual(o["toque"] as? String, "✨ Acabamento Grafite + Freijó no projeto inteiro · portas, armários e piso")
        XCTAssertEqual(o["tab"] as? Int, 10, "continua na aba Cores")
        XCTAssertEqual(o["cores"] as? String, "#48494e #48494e", "todos os módulos")
        XCTAssertEqual(o["corte"] as? Bool, true)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Cozinha em L: espaçador de canto no gaveteiro (gaveta e porta do móvel da pia abrem sem pegar; sem ele pega),
    /// e fechamento do teto na frente em cima de todos os aéreos de uma vez.
    func testEspacadorDeCantoEFechamentoDoTetoNaFrente() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.ops=[];S.env='cozinha';S.room='cozinha';S.W=3500;S.RD=3000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];var R={};draw();
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          var last=function(){return S.mods[S.mods.length-1]};
          newTpl(T('Gaveteiro 3 gavetas'));var g=last();g.x=635;g.w=595;g.tl=g.tr=false;g.lock=true;
          S.m=g;addWing('e');var p=last();p.x=0;p.w=2000;p.div=[0.32];p.v=[{k:'free',n:1},{k:'door',n:2,cava:false,px:'externo'}];p.tl=false;draw();
          /* catálogo: espaçador e fechamento */
          var it=function(a,l){var r=null;CATS.forEach(function(c){c.it.forEach(function(q){if(q&&q.act===a&&(l===undefined||q.lado===l))r=q})});return r};R.cat=!!it('espCanto','e')+' '+!!it('espCanto','d')+' '+!!it('fechTeto');
          S.m=g;R.liga=catAct2(it('espCanto','e'))+' '+g.esL;var e=partsOf(g).filter(function(q){return q.name==='Espaçador de canto'})[0];R.peca=e?[e.x,e.w,e.h,e.cl,e.cw].join(' '):null;
          var G=cutGroups(),l=G.ord.map(function(k){return G.map[k]}).filter(function(q){return q.names.some(function(n){return /^Espaçador de canto/.test(n)})})[0];R.corte=l?l.L+'x'+l.W+' q'+l.qty:null;
          /* gavetas abertas e porta do móvel da pia: nada encosta */
          open3D();await new Promise(function(r){setTimeout(r,500)});
          var hit=function(){var A=__ang();Object.keys(A.g).forEach(function(k){delete A.g[k]});Object.keys(A.t).forEach(function(k){delete A.t[k]});__build();var gi=S.mods.indexOf(g),pi=S.mods.indexOf(p),B=__boxes(),Ga=B.filter(function(b){return String(b.nm).indexOf(gi+':')===0}),Pa=B.filter(function(b){return String(b.nm).indexOf(pi+':')===0}),h=0;Ga.forEach(function(a){Pa.forEach(function(b){var ox=Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0),oy=Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0),oz=Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0);if(ox>.5&&oy>.5&&oz>.5)h++})});return h};
          g.v[0].open=true;draw();R.gavetaAberta=hit();g.v[0].open=false;p.v[1].open=true;draw();R.portaAberta=hit();p.v[1].open=false;
          /* sem espaçador e encostado no canto: a gaveta pega (é pra isso que ele serve) */
          var x0=g.x;delete g.esL;g.x=562;g.v[0].open=true;draw();R.semEspacador=hit()>0;g.x=x0;g.v[0].open=false;g.esL=50;
          R.tira=catAct2(it('espCanto','e'))+' '+(g.esL===undefined);document.getElementById('v3x').click();
          /* fechamento do teto na frente: em todos os aéreos de uma vez */
          R.semAereo=fechTeto()+' '+TL[TL.length-1];
          [[630,600],[1230,780]].forEach(function(q){newTpl({n:'Aéreo',w:q[1],h:750,d:350,b:1750,sup:true,v:[{k:'door',n:2,cava:true}]});var m=last();m.x=q[0];m.tl=m.tr=false});draw();
          R.fecha=catAct2(it('fechTeto'))+' '+S.mods.filter(function(m){return m.rtt&&m.rtt.on}).length;R.pecas=S.mods.filter(function(m){return m.sup}).map(function(m){var q=partsOf(m).filter(function(p){return p.name==='Roda-teto'})[0];return q?q.w+'x'+q.h:'-'}).join(' ');
          R.tiraF=fechTeto()+' '+S.mods.filter(function(m){return m.rtt&&m.rtt.on}).length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["cat"] as? String, "true true true", "opções no catálogo")
        XCTAssertEqual(o["liga"] as? String, "true 50")
        XCTAssertEqual(o["peca"] as? String, "-50 50 705 705 50", "régua de 50 do lado, na altura das frentes")
        XCTAssertEqual(o["corte"] as? String, "705x50 q1", "entra no plano de corte")
        XCTAssertEqual(o["gavetaAberta"] as? Int, 0, "gaveta aberta não pega no móvel da pia")
        XCTAssertEqual(o["portaAberta"] as? Int, 0, "porta do móvel da pia aberta não pega no gaveteiro")
        XCTAssertEqual(o["semEspacador"] as? Bool, true, "sem espaçador e colado no canto, pega")
        XCTAssertEqual(o["tira"] as? String, "true true")
        XCTAssertEqual(o["semAereo"] as? String, "0 Ponha os armários de cima primeiro: o fechamento vai deles até o teto")
        XCTAssertEqual(o["fecha"] as? String, "true 2")
        XCTAssertEqual(o["pecas"] as? String, "630x200 810x200", "do armário até o teto")
        XCTAssertEqual(o["tiraF"] as? String, "2 0")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Rebaixo do teto com dente: o rebaixo termina e sobe um degrau do lado; o painel acompanha os dois níveis.
    func testRebaixoDoTetoComDente() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.W=4000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];var R={};draw();
          S.rp=[{id:11,liso:true,x:0,b:0,w:4000,h:2700}];var z=tzAdd('f',{x:1000,w:1200,hc:2300});
          document.querySelector('#tzbox [data-tzb="dente"]').click();R.zonas=S.tz.map(function(q){return q.x+'+'+q.w+'@'+q.hc}).join(' | ');R.sel=window.TZSEL===S.tz[1].id;R.toast=TL[TL.length-1];
          R.painel=S.rp.map(function(a){return a.x+'+'+a.w+'x'+a.h}).join(' | ');
          /* sem parede sobrando na direita: o dente sai pra esquerda */
          var z3=tzAdd('f',{x:3500,w:500,hc:2400});document.querySelector('#tzbox [data-tzb="dente"]').click();var d=S.tz[S.tz.length-1];R.esq=d.x+'+'+d.w+'@'+d.hc;
          open3D();await new Promise(function(r){setTimeout(r,800)});R.b3=__boxes().filter(function(b){return b.tz}).length;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["zonas"] as? String, "1000+1200@2300 | 2200+600@2500", "dente encostado, mais alto")
        XCTAssertEqual(o["sel"] as? Bool, true)
        XCTAssertEqual(o["painel"] as? String, "0+1000x2700 | 1000+1200x2300 | 2200+600x2500 | 2800+1200x2700", "painel acompanha os dois níveis")
        XCTAssertEqual(o["esq"] as? String, "2900+600@2550", "sem parede na direita: dente sai pra esquerda")
        XCTAssertEqual(o["b3"] as? Int, 8)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Pedra dividida no fogão de piso: para nele com 3 mm de folga e continua do outro lado; cuba e cooktop ficam no pedaço certo;
    /// a perna do L fica no pedaço da ponta; sem fogão avisa; não divide duas vezes.
    func testPedraDivididaNoFogao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.env='cozinha';S.W=3500;S.RD=3000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];var R={};draw();
          var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(q&&q.n===n&&!r)r=q})});return JSON.parse(JSON.stringify(r))};
          newTpl(T('Balcão da pia (cuba)'));var a=S.mods[0];a.x=0;a.w=1230;a.tl=a.tr=false;a.lock=true;newTpl(T('Balcão 2 portas'));var b=S.mods[1];b.x=2010;b.w=780;b.tl=b.tr=false;b.lock=true;draw();
          addStone();var st=S.stones[0];st.x=0;st.w=2790;draw();R.antes=S.stones.map(function(q){return q.x+'+'+q.w+' i'+q.items.map(function(i){return i.k+'@'+i.x}).join(',')}).join(' | ');
          /* sem fogão: avisa e o botão nem aparece */S.tab=6;panel();R.semFogao=stDividir()+' '+!!document.querySelector('#bd [data-stdiv]')+' '+TL[TL.length-1];
          var fi=APM.forno.m.findIndex(function(m){return /Fogão de piso 5 bocas BFS5NCR/.test(m[0])}),f=apAdd('forno',fi);f.x=1231;st.items.push({id:9,k:'cooktop',x:2200,y:100,w:400,d:350});draw();S.tab=6;panel();
          var bt=document.querySelector('#bd [data-stdiv]');R.botao=!!bt&&bt.textContent;bt.click();
          R.depois=S.stones.map(function(q){return q.x+'+'+q.w+' i'+q.items.map(function(i){return i.k+'@'+i.x}).join(',')}).join(' | ');R.toast=TL[TL.length-1];R.ids=new Set(S.stones.map(function(q){return q.id})).size;
          R.folga=(f.x-(S.stones[0].x+S.stones[0].w))+' '+(S.stones[1].x-(f.x+f.w));
          R.denovo=stDividir()+' '+TL[TL.length-1];
          /* 3D: nenhum pedaço de pedra em cima do fogão */
          open3D();await new Promise(function(r){setTimeout(r,500)});var B=__boxes().filter(function(q){return q.g==='st'||q.g==='stc'});R.b3=B.length>0&&!B.some(function(q){return Math.min(q.x1,f.x+f.w)-Math.max(q.x0,f.x)>1&&q.y1>800});document.getElementById('v3x').click();
          /* pedra em L: a perna fica só no pedaço da ponta */
          S.stones=[{id:1,x:0,w:2790,d:600,t:820,e:30,shape:'Le',lenA:2000,widA:600,items:[]}];S.st=S.stones[0];draw();stDividir();R.emL=S.stones.map(function(q){return q.x+'+'+q.w+(q.shape?' '+q.shape+' '+q.lenA:'')}).join(' | ');
          var s2=snapState();R.salva=s2.stones.length;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["antes"] as? String, "0+2790 icuba@370")
        XCTAssertEqual(o["semFogao"] as? String, "0 false Ponha o fogão de piso no lugar primeiro: a pedra é dividida onde ele está")
        XCTAssertEqual(o["botao"] as? String, "✂ Dividir a pedra no fogão")
        XCTAssertEqual(o["depois"] as? String, "0+1228 icuba@370 | 2012+778 icooktop@188", "dois pedaços, cada item no seu")
        XCTAssertEqual(o["ids"] as? Int, 2)
        XCTAssertEqual(o["folga"] as? String, "3 3", "3 mm de cada lado do fogão")
        XCTAssertEqual(o["denovo"] as? String, "0 A pedra já está dividida no fogão")
        XCTAssertEqual(o["b3"] as? Bool, true, "3D: nenhuma pedra em cima do fogão")
        XCTAssertEqual(o["emL"] as? String, "0+1228 Le 2000 | 2012+778", "a perna do L fica no pedaço da ponta")
        XCTAssertEqual(o["salva"] as? Int, 2)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Edição ambiente 3D menor: com a parede escolhida fica só o cartão dela (largura e altura de cada ponta);
    /// 2 toques no canto de cima marca a altura daquele lado (caimento) e os painéis acompanham alinhados embaixo;
    /// rebaixo do teto nasce total, medido do chão; o dente fica só depois do fim do rebaixo.
    func testAmbienteMenorCaimentoNoCantoERebaixoTotal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.mods=[];S.tz=[];S.env='livre';S.room='sala';S.W=4000;S.RD=3000;S.H=2700;S.Hm=1;S.Wm=1;S.wall={};var R={};draw();
          open3D();await new Promise(function(r){setTimeout(r,500)});ambSetOpen();await new Promise(function(r){setTimeout(r,200)});var P=document.getElementById('ambset');
          R.semParede=!!P.querySelector('[data-ambs="RD"]');var h0=P.getBoundingClientRect().height;
          ambSelWall('f');R.comParede=!P.querySelector('[data-ambs="RD"]')+' '+!!P.querySelector('[data-ambw="f"]')+' '+[].map.call(P.querySelectorAll('[data-ambw] [data-ambs]'),function(i){return i.dataset.ambs+'='+i.value}).join(',');R.menor=P.getBoundingClientRect().height<h0+60;
          /* altura de cada ponta: caimento */
          var set=function(k,v){var i=P.querySelector('[data-ambs="'+k+'"]');i.value=v;i.dispatchEvent(new Event('change',{bubbles:true}))};set('Fh1','2500');R.caimento=S.H+' '+wallCfg('F').h1+' '+Math.round(Hx_(2000));
          /* 2 toques no canto de cima da direita: destaca o campo daquela ponta */
          var c=__cv3(),rc=c.getBoundingClientRect(),p=__p3(S.W*0.93,S.H*0.82,0),X=rc.left+p[0],Y=rc.top+p[1],ev=function(n){c.dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:3,clientX:X,clientY:Y,isPrimary:true}))};
          ev('pointerdown');ev('pointerup');ev('pointerdown');ev('pointerup');R.canto=window.AMBCORNER+' '+TL[TL.length-1];
          /* ambiente inteiro abre de novo */
          [].filter.call(P.querySelectorAll('[data-ambsb="min"]'),function(b){return true})[0].click();R.inteiro=!!P.querySelector('[data-ambs="RD"]');
          /* painéis acompanham o caimento, todos alinhados embaixo */
          S.rp=[{id:1,liso:true,x:0,b:0,w:1000,h:2700},{id:2,liso:true,x:1000,b:0,w:1000,h:2700},{id:3,liso:true,x:2000,b:0,w:1000,h:2700}];draw();R.paineis=S.rp.map(function(a){return a.x+'+'+a.w+'x'+a.h+'@'+a.b}).join(' | ');
          /* rebaixo: nasce total (parede inteira, ambiente todo), medido do chão */
          var z=tzAdd('f');R.rebaixo=[z.x,z.w,z.d].join(' ')+' '+JSON.stringify(tzGeo(z)).replace(/"/g,'');var i=document.querySelector('#tzbox [data-tzf="hc"]');i.value='2300';i.dispatchEvent(new Event('change',{bubbles:true}));R.marcado=z.hc+' '+S.rp.map(function(a){return a.h}).join(',');
          /* dente: o rebaixo termina 600 antes e o teto sobe só depois dele */
          document.querySelector('#tzbox [data-tzb="dente"]').click();R.dente=S.tz.map(function(q){return q.x+'+'+q.w+'@'+q.hc}).join(' | ');R.paineis2=S.rp.map(function(a){return a.x+'+'+a.w+'x'+a.h}).join(' | ');
          __build();R.transp=__boxes().filter(function(b){return b.tz}).map(function(b){return b.a}).join(',');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["semParede"] as? Bool, true)
        XCTAssertEqual(o["comParede"] as? String, "true true W=4000,H0=2700,Fh1=2700", "só o cartão da parede, com a altura de cada ponta")
        XCTAssertEqual(o["menor"] as? Bool, true)
        XCTAssertEqual(o["caimento"] as? String, "2700 2500 2600", "teto com caimento")
        XCTAssertEqual(o["canto"] as? String, "Fh1 📐 Canto da parede: digite a altura deste lado · o teto faz o caimento e os painéis acompanham")
        XCTAssertEqual(o["inteiro"] as? Bool, true, "ambiente inteiro abre de novo")
        XCTAssertEqual(o["rebaixo"] as? String, "0 4000 0 {x0:0,x1:4000,y0:2500,y1:2600,z0:0,z1:3000,tot:true}", "rebaixo total")
        XCTAssertEqual(o["marcado"] as? String, "2300 2300,2300,2300", "altura medida do chão; painéis na altura do rebaixo")
        XCTAssertEqual(o["dente"] as? String, "0+3400@2300 | 3400+600@2450", "o teto sobe só depois do fim do rebaixo")
        XCTAssertEqual(o["transp"] as? String, "0.42,0.42,0.42,0.42", "rebaixo total transparente (gesso + tabica) pra ver o ambiente")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Gesso do teto: mede com a trena do chão, digita e toca em Ajustar teto, ou arrasta a régua; medidas dos 4 lados.
    func testGessoTrenaAjustarTetoArrastarEMedidasDosQuatroLados() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.mods=[];S.tz=[];S.env='livre';S.room='sala';S.W=4140;S.RD=3170;S.H=3400;S.Hm=1;S.Wm=1;S.wall={};var R={};draw();
          open3D();await new Promise(function(r){setTimeout(r,500)});
          S.rp=[{id:1,liso:true,x:0,b:0,w:1380,h:3400},{id:2,liso:true,x:1380,b:0,w:1380,h:3400},{id:3,liso:true,x:2760,b:0,w:1380,h:3400}];
          var z=tzAdd('f');var bx=document.getElementById('tzbox');R.quadro=!!bx.querySelector('[data-tzb="aj"]')+' '+!!bx.querySelector('[data-tzr]')+' '+bx.querySelector('[data-tzf="hc"]').value;
          /* digita a medida da trena e toca em Ajustar teto */
          var i=bx.querySelector('[data-tzf="hc"]');i.value='3000';bx.querySelector('[data-tzb="aj"]').click();R.ajustou=z.hc+' '+TL[TL.length-1]+' | '+S.rp.map(function(a){return a.h}).join(',');
          /* +10 e −10 */
          document.querySelector('#tzbox [data-tzb="p10"]').click();document.querySelector('#tzbox [data-tzb="m10"]').click();document.querySelector('#tzbox [data-tzb="m10"]').click();R.passo=z.hc;
          /* arrastar a régua: muda ao vivo */
          var rg=document.querySelector('#tzbox [data-tzr]');rg.value='2800';rg.dispatchEvent(new Event('input',{bubbles:true}));R.arrasta=z.hc+' '+document.querySelector('#tzbox [data-tzf="hc"]').value;rg.dispatchEvent(new Event('change',{bubbles:true}));R.solta=S.rp.map(function(a){return a.h}).join(',');
          /* medidas dos 4 lados no quadro e em cima do 3D */
          R.med=document.querySelector('#tzbox [data-tzmed]').textContent.replace(/\s+/g,' ').trim();__tzLab();R.rotulos=[].map.call(document.querySelectorAll('#tzlab > div'),function(d){return d.textContent}).join(' | ');
          /* 3D: gesso + tabica + trena laranja do chão até ele */
          __build();var B=__boxes().filter(function(b){return b.g==='tz'});R.b3=B.length+' '+B.filter(function(b){return b.tz}).map(function(b){return Math.round(b.y0)+'-'+Math.round(b.y1)+'@'+b.a}).join(',')+' trena '+B.filter(function(b){return b.nol&&b.y1>100}).map(function(b){return Math.round(b.y0)+'-'+Math.round(b.y1)}).join(',');
          /* não passa do teto */
          i=document.querySelector('#tzbox [data-tzf="hc"]');i.value='9000';document.querySelector('#tzbox [data-tzb="aj"]').click();R.limite=z.hc;
          document.querySelector('#tzbox [data-tzb="ok"]').click();__tzLab();R.fecha=document.getElementById('tzlab').hidden;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["quadro"] as? String, "true true 3200")
        XCTAssertEqual(o["ajustou"] as? String, "3000 ✓ Teto ajustado · gesso a 3000 do chão (desce 400) | 3000,3000,3000", "o gesso morre na altura digitada e os painéis acompanham")
        XCTAssertEqual(o["passo"] as? Double, 2990)
        XCTAssertEqual(o["arrasta"] as? String, "2800 2800", "arrastar a régua muda ao vivo")
        XCTAssertEqual(o["solta"] as? String, "2800,2800,2800")
        XCTAssertEqual(o["med"] as? String, "↔ 4140 na parede⤢ 3170 saindo da parede↕ 2800 do chão⇣ desce 600 do teto")
        XCTAssertEqual(o["rotulos"] as? String, "↔ 4140 | ↔ 3170 | ↕ 2800 do chão | ⇣ 600", "medidas reais dos 4 lados em cima do 3D")
        XCTAssertEqual(o["b3"] as? String, "4 2814-3400@0.42,2800-2814@0.42 trena 0-2800", "gesso + tabica + trena do chão até ele")
        XCTAssertEqual(o["limite"] as? Double, 3395, "não passa do teto")
        XCTAssertEqual(o["fecha"] as? Bool, true)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Aéreo com cava: a porta vai do topo até o final do caixote (não sobe 5 nem para 5 antes).
    func testPortaDoAereoVaiAteOFinal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;S.stones=[];S.rp=[];S.mods=[];S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;var R={};draw();
          var D=function(t){S.mods=[];newTpl(t);var m=S.mods[0],ps=partsOf(m).filter(function(p){return p.name==='Porta'});return ps.map(function(p){return p.y+'..'+(p.y+p.h)+' corte '+p.cw}).join(' | ')};
          R.aereo=D({n:'Aéreo',w:800,h:910,d:350,b:1500,sup:true,v:[{k:'door',n:2,cava:true}]});
          R.base=D({n:'Base',w:800,h:720,d:560,b:0,v:[{k:'door',n:2,cava:true}]});
          var bad=[];CATS.forEach(function(c){(c.it||[]).forEach(function(q){if(!q||!q.sup||!q.v||q.act)return;S.mods=[];newTpl(JSON.parse(JSON.stringify(q)));var m=S.mods[S.mods.length-1];partsOf(m).forEach(function(p){if(p.name==='Porta'&&/cava/.test(p.note||'')&&!/basculante/i.test(p.note||'')&&(p.y<-0.01||p.y+p.h>m.h+0.01))bad.push(q.n+' '+p.y+'..'+(p.y+p.h)+' de '+m.h)})})});R.bad=bad;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["aereo"] as? String, "0..910 corte 910 | 0..910 corte 910", "do topo até o final do aéreo")
        XCTAssertEqual((o["bad"] as? [Any])?.count ?? -1, 0, "nenhum aéreo do catálogo com porta passando ou faltando: \(o["bad"] ?? "")")
        XCTAssertNotNil(o["base"] as? String)
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Ripado em cima e roda-teto seguem o caminho do móvel: frente reta nos módulos iguais, lateral só no degrau.
    func testRipadoERodaTetoSeguemOCaminhoDoMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.stones=[];S.rp=[];S.fr=[];S.ops=[];S.env='cozinha';S.room='cozinha';S.W=4000;S.RD=3000;S.H=2700;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];var R={};draw();
          var mk=function(x,w,d){newTpl({n:'Torre',w:w,h:2200,d:d,b:0,v:[{k:'door',n:2,cava:false,px:'externo'}]});var m=S.mods[S.mods.length-1];m.x=x;m.w=w;m.d=d;m.tl=m.tr=false;m.rtt={on:true};return m};
          var a=mk(0,800,560),b=mk(800,800,560),g=mk(1600,900,700),c=mk(2500,800,560);c.tr=false;draw();
          var inf=function(m){return partsOf(m).filter(function(p){return /^Roda-teto/.test(p.name)}).map(function(p){return (/lateral/.test(p.name)?'lat':'frente')+' '+p.cl+'x'+p.cw+' z'+p.cxz.join('..')}).join(' | ')};
          R.rt=[inf(a),inf(b),inf(g),inf(c)].join(' // ');
          var G=cutGroups();R.corte=G.ord.map(function(k){return G.map[k]}).filter(function(q){return q.names.some(function(n){return /^Roda-teto \(lateral/.test(n)})}).map(function(l){return l.L+'x'+l.W+' q'+l.qty}).join(', ');
          [a,b,g,c].forEach(function(m){delete m.rtt;m.rpTop='frente'});draw();
          var ri=function(m){var P=partsOf(m);return P.filter(function(p){return p.name==='Ripa do ripado (em cima)'}).length+' lat['+P.filter(function(p){return /^Chapa.*curva/.test(p.name)}).map(function(p){return p.name.replace(/.*curva /,'').replace(')','')+' '+p.cl}).join(';')+']'};
          R.rp=[ri(a),ri(b),ri(g),ri(c)].join(' // ');
          var xs=[];[a,b].forEach(function(m){partsOf(m).forEach(function(p){if(p.name==='Ripa do ripado (em cima)')xs.push(Math.round((m.x+p.x)*10)/10)})});xs.sort(function(p,q){return p-q});var ds={};for(var i=1;i<xs.length;i++)ds[Math.round((xs[i]-xs[i-1])*10)/10]=1;R.passos=Object.keys(ds).join(',');
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["rt"] as? String, "frente 800x500 z-25..-10 // frente 800x500 z-25..-10 // frente 900x500 z-25..-10 | lat 125x500 z-10..115 | lat 125x500 z-10..115 // frente 830x500 z-25..-10", "fechamento só na frente; lateral só no degrau do módulo mais fundo")
        XCTAssertEqual(o["corte"] as? String, "125x500 q2", "as laterais do degrau entram no plano de corte")
        XCTAssertEqual(o["rp"] as? String, "12 lat[] // 12 lat[] // 12 lat[esquerda 119;direita 119] // 11 lat[direita 489]", "ripado: frente reta nos iguais, lateral só no degrau, recuada 5 cm igual à frente")
        XCTAssertEqual(o["passos"] as? String, "65", "mesmo espaçamento de ponta a ponta nos módulos iguais")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Catálogo: item que depende de outro móvel entra mesmo assim (o app coloca/escolhe o móvel) e nunca diz "adicionado" sem ter entrado.
    func testCatalogoTodoItemTocadoEntraNoDesenho() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var R={same:[],n:0};
          var reset=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.tz=[];S.room='cozinha';S.env='cozinha';S.W=3200;S.RD=3000;S.H=2600;S.Wm=1;S.Hm=1;S.m=null;draw()};
          for(var ci=0;ci<CATS.length;ci++){var c=CATS[ci];for(var i=0;i<c.it.length;i++){var it=c.it[i];if(!it||!/^(nichoTopo|nichoVidro|fechTeto|espCanto|fchL|fchR|fchT|lixemb|nichoMw)$/.test(it.act||''))continue;reset();var s0=__catSig();TL.length=0;CATALL=true;window.CATQ='';catOpen(c.id);var b=document.querySelector('#catm [data-cati="'+c.id+'|'+i+'"]');if(!b){R.same.push('sem botão '+it.n);continue}b.click();await new Promise(function(r){setTimeout(r,5)});R.n++;if(__catSig()===s0)R.same.push(it.n+' → '+TL[TL.length-1]);var cm=document.getElementById('catm');if(cm)cm.hidden=true}}
          /* sem pé-direito medido o nicho até o teto avisa o motivo (não diz "adicionado") */
          reset();S.Hm=0;TL.length=0;var sc=CATS.filter(function(c){return c.id==='sup'})[0],k=-1;sc.it.forEach(function(q,i){if(q&&q.act==='nichoTopo')k=i});catOpen('sup');document.querySelector('#catm [data-cati="sup|'+k+'"]').click();await new Promise(function(r){setTimeout(r,5)});R.aviso=TL.some(function(t){return /adicionado$/.test(t)&&/Nicho em cima/.test(t)})+' '+/pé-direito/.test(TL.join(' '));
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertGreaterThan(o["n"] as? Int ?? 0, 9)
        XCTAssertEqual((o["same"] as? [Any])?.count ?? -1, 0, "todo item tocado muda o desenho: \(o["same"] ?? "")")
        XCTAssertEqual(o["aviso"] as? String, "false true", "quando não dá, avisa o motivo e não diz adicionado")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }

    /// Painel liso entra igual ao ripado (toque no vão), diminui arrastando a bolinha, e painel nunca entra em móvel.
    func testPainelLisoPeloVaoArrastarPraDiminuirENaoEntraNoMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};S.stones=[];S.rp=[];S.fr=[];S.ops=[];S.env='cozinha';S.room='cozinha';S.W=4140;S.RD=3000;S.H=3400;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];var R={};draw();
          [30,1075,2120].forEach(function(x){newTpl({n:'Aéreo',w:1015,h:750,d:350,b:1930,sup:true,v:[{k:'door',n:2,cava:true}]});var m=S.mods[S.mods.length-1];m.x=x;m.tl=m.tr=false});
          newTpl({n:'Nicho',w:1015,h:200,d:350,b:1730,sup:true,v:[{k:'free',n:1}]});var n=S.mods[S.mods.length-1];n.x=1075;n.tl=n.tr=false;S.m=n;S.tab=8;RPKIND='liso';draw();panel();
          /* preencher acima: só o vão livre em cima do aéreo */
          document.querySelector('[data-rpabove]').click();var F=function(){return S.rp.map(function(a){return a.x+','+a.b+' '+a.w+'x'+a.h+(a.liso?' liso':' ripado')}).join(' | ')};R.acima=F();
          /* painel liso pelo toque no vão: mesma forma do ripado */
          saStart(true);R.ini=document.getElementById('rpsabar').querySelector('b').textContent;
          var sv=document.getElementById('svg'),rc=sv.getBoundingClientRect(),ctm=sv.getScreenCTM(),pt=function(x,y){var p=sv.createSVGPoint();p.x=OX+x*K;p.y=OY+(S.H-y)*K;var q=p.matrixTransform(ctm);return [q.x,q.y]},ev=function(t,n,x,y,id){var c=pt(x,y);t.dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:id||5,clientX:c[0],clientY:c[1],isPrimary:true,pointerType:'touch'}))};
          ev(sv,'pointerdown',3000,3000);ev(sv,'pointerup',3000,3000);R.toque=RPSA.areas.map(function(r){return [r.x0,r.x1,r.y0,r.y1].join(',')}).join(' | ')+' · '+document.getElementById('rpsabar').querySelector('b').textContent;
          document.querySelector('#rpsabar [data-sab="go"]').click();R.criou=F();
          /* arrastar a bolinha da esquerda pra diminuir até onde quiser */
          await new Promise(function(r){setTimeout(r,50)});var a=S.rp[S.rp.length-1];RPSEL=a.id;LAST='rp';draw();var h=document.querySelector('[data-rph="'+a.id+'|l"]');R.bolinha=h?h.getAttribute('r'):null;
          ev(h,'pointerdown',a.x,a.b+a.h/2,7);ev(sv,'pointermove',a.x+300,a.b+a.h/2,7);ev(sv,'pointermove',a.x+600,a.b+a.h/2,7);ev(window,'pointerup',a.x+600,a.b+a.h/2,7);await new Promise(function(r){setTimeout(r,60)});R.diminuiu=(a.x>2090&&a.w<2050&&Math.abs(a.x+a.w-4140)<1)+' '+a.h;
          /* esticar pra baixo: para em cima do aéreo, não entra */
          draw();h=document.querySelector('[data-rph="'+a.id+'|b"]');var yb=a.b;ev(h,'pointerdown',a.x+a.w/2,yb,8);ev(sv,'pointermove',a.x+a.w/2,yb-300,8);ev(sv,'pointermove',a.x+a.w/2,yb-600,8);ev(window,'pointerup',a.x+a.w/2,yb-600,8);await new Promise(function(r){setTimeout(r,60)});R.esticou=a.b+' '+a.h;
          /* arrastar o painel inteiro pra cima do aéreo: para encostado */
          draw();var g=document.querySelector('rect[data-rp="'+a.id+'"]');ev(g,'pointerdown',a.x+a.w/2,a.b+a.h/2,9);ev(sv,'pointermove',a.x+a.w/2,a.b+a.h/2-200,9);ev(sv,'pointermove',a.x+a.w/2,a.b+a.h/2-500,9);ev(window,'pointerup',a.x+a.w/2,a.b+a.h/2-500,9);await new Promise(function(r){setTimeout(r,60)});R.moveu=a.b+' '+a.h;
          var col=0;S.rp.forEach(function(p){S.mods.forEach(function(m){if(Math.min(p.x+p.w,m.x+m.w)-Math.max(p.x,m.x)>1&&Math.min(p.b+p.h,m.b+m.h)-Math.max(p.b,m.b)>1)col++})});R.dentro=col;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["acima"] as? String, "1075,2680 1015x720 liso", "preencher acima: só o vão livre em cima do aéreo (não passa por dentro dele)")
        XCTAssertEqual(o["ini"] as? String, "🎯 Toque no vão ou arraste no desenho: marque onde vai o painel liso")
        XCTAssertEqual(o["toque"] as? String, "2090,4140,2680,3400 · 🎯 1 área livre pro painel liso", "toque no vão acha a área livre, desviando do painel que já existe")
        XCTAssertEqual(o["criou"] as? String, "1075,2680 1015x720 liso | 2090,2680 2050x720 liso")
        XCTAssertEqual(o["bolinha"] as? String, "17", "bolinha grande pra pegar com o dedo")
        XCTAssertEqual(o["diminuiu"] as? String, "true 720", "arrastar a bolinha diminui o painel")
        XCTAssertEqual(o["esticou"] as? String, "2680 720", "esticar pra baixo para em cima do aéreo")
        XCTAssertEqual(o["moveu"] as? String, "2680 720", "arrastar o painel pra cima do aéreo: para encostado")
        XCTAssertEqual(o["dentro"] as? Int, 0, "nenhum painel dentro de móvel")
        XCTAssertEqual((o["errs"] as? [Any])?.count ?? 0, 0, "sem erros: \(o["errs"] ?? "")")
    }
}
