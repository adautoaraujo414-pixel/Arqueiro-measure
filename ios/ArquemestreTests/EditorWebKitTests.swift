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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["g"] as? Double ?? 0, a - 35, accuracy: 0.01, "perfil G desconta 35 mm")
        XCTAssertEqual(o["c"] as? Double ?? 0, a - 30, accuracy: 0.01, "cava de perfil desconta 30 mm")
        XCTAssertEqual(o["k"] as? Double ?? 0, a, accuracy: 0.01, "concha não muda a altura")
        XCTAssertTrue((o["gnote"] as? String ?? "").contains("+ perfil 35 ="))
        func n1(_ v: Double) -> String { String(format: "%g", (v * 10).rounded() / 10).replacingOccurrences(of: ".", with: ",") }
        XCTAssertTrue((o["knote"] as? String ?? "").contains("furos a \(n1((w - 96) / 2)) e \(n1((w + 96) / 2)) mm da esquerda, \(n1(a / 2)) mm de cima"), "\(o["knote"] ?? "")")
        XCTAssertEqual(o["foto"] as? Bool, true, "foto do puxador no quadro")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["fw"] as? Double ?? 0, cx - 18, accuracy: 0.11, "fundo no rebaixo 6 × 6 = caixa − 30 + 12")
        XCTAssertEqual(o["fd"] as? Double ?? 0, o["ld"] as? Double ?? -1, accuracy: 0.11, "fundo no comprimento todo da lateral")
        XCTAssertEqual(o["fmat"] as? Double ?? 0, 6, accuracy: 0.01)
        XCTAssertEqual(o["cq"] as? Int, 6, "3 gavetas = 6 peças de contra-frente/traseira")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testSoEmbaixoDaPiaSemFundoETorreComBaseETeto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.env='cozinha';var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Balcão da pia (cuba)'));newTpl(T('Gaveteiro 3 gavetas'));newTpl(0);newTpl(4);addStone();draw();open3D();var B=__boxes();
          var z=S.mods.map(function(m,i){return Math.min.apply(null,B.filter(function(b){return String(b.nm)===i+':Lateral esquerda'}).map(function(b){return Math.round(b.z0)}))});
          var tor=S.mods[3],bt=partsOf(tor).filter(function(p){return /^Base (inferior|superior)$/.test(p.name)}).length;
          return JSON.stringify({f:S.mods.map(function(m){return m.fundo}).join(','),z:z.join(','),bt:bt,tt:!!tor.tt,errs:__errs});
          """#)
        XCTAssertEqual(o["f"] as? String, "true,false,true,true,true", "só o balcão embaixo da pia fica sem fundo (área úmida)")
        XCTAssertEqual(o["z"] as? String, "6,6,6,6,6", "frentes alinhadas, com ou sem fundo")
        XCTAssertEqual(o["bt"] as? Int, 2, "torre tem base e teto")
        XCTAssertEqual(o["tt"] as? Bool, false, "torre sem tamponamento em cima")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["cfg"] as? Int, 8, "⚙ abre as Configurações com 8 assuntos")
        XCTAssertEqual(o["ow"] as? Double ?? 0, (vw - 12).rounded(), accuracy: 1, "oculta: caixa = vão − 12")
        XCTAssertEqual((o["onl"] as? Double ?? 0) - (o["od"] as? Double ?? 0), 10, accuracy: 0.01, "oculta: caixa 10 mm mais curta que a corrediça")
        XCTAssertEqual(o["ooc"] as? Bool, true)
        XCTAssertTrue((o["fnote"] as? String ?? "").contains("13 mm acima da borda de baixo"), "\(o["fnote"] ?? "")")
        XCTAssertTrue((o["cn"] as? String ?? "").contains("60 mm de cima"), "concha em cima, 60 mm: \(o["cn"] ?? "")")
        XCTAssertEqual(o["mc"] as? Bool, true, "corte avulso calcula as chapas")
        XCTAssertEqual(o["gd"] as? Int, 13, "passo a passo com 13 assuntos")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["dw"] as? Double, 50, "− na pedra diminui 50 mm")
        XCTAssertEqual(o["wc"] as? String, "#b8c4ae", "cor da parede")
        XCTAssertEqual(o["svled"] as? Bool, true, "projeto salva o LED")
        XCTAssertEqual(o["svwc"] as? String, "#b8c4ae", "projeto salva a cor da parede")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Tamponamento do aéreo rente com a régua (sem vão), tamponamento de baixo colado nela, eletros com formato de verdade e desenho no catálogo
    func testReguaTamponamentoRenteEEletrosReais() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];newTpl(CATS[1].it[2]);var m=S.mods[0];m.regua=true;m.regN=2;m.tl=true;m.tlA='tamp';m.tr=true;m.trA='cava';m.tb=true;m.tpass=false;draw();
          var top=m.b+m.h,y0=function(p){return top-p.y-p.h},y1=function(p){return top-p.y},pn=function(L,n){return L.filter(function(p){return p.name===n})[0]};
          var P=partsOf(m),reg=P.filter(function(p){return /^Engrosso cava · régua/.test(p.name)}),rb=Math.min.apply(null,reg.map(y0)),tb=pn(P,'Tamponamento de baixo'),tl=pn(P,'Tamponamento esquerdo'),tr=pn(P,'Tamponamento direito');
          m.tb=false;draw();var tl2=pn(partsOf(m),'Tamponamento esquerdo');
          S.fr=[];var g=apAdd('geladeira',2),t=apAdd('torneira',0);window.open3D();var bx=window.dbg3all(),gb=bx.filter(function(b){return b.fr===g.id}).length,tq=bx.filter(function(b){return b.fr===t.id}).length;document.getElementById('v3x').click();
          catOpen('cgel');var ic=document.querySelectorAll('#catb [data-cati] svg').length,nb=document.querySelectorAll('#catb [data-cati]').length;document.getElementById('catm').hidden=true;
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
        XCTAssertEqual(o["ic"] as? Int, o["nb"] as? Int, "cada eletro do catálogo com o desenho na frente")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          var arm=CATS.filter(function(c){return c.id==='dArm'})[0].it;newTpl(arm[4]);var P=partsOf(S.mods[0]).map(function(p){return p.name});newTpl(arm[10]);var P2=partsOf(S.mods[1]).map(function(p){return p.name});
          return JSON.stringify({lados:lados,campos:campos,tipos:tipos,ori:ori,gir:gir,ang:ang,cuba:cuba,cook:cook,bocas:bocas,cubas:cubas,narm:arm.length,portas:P.filter(function(n){return n==='Porta'}).length,gav:P.filter(function(n){return n==='Frente de gaveta'}).length,semLat:P2.indexOf('Lateral esquerda')<0&&P2.indexOf('Lateral direita')>=0,errs:__errs});
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
        XCTAssertEqual(o["narm"] as? Int, 13, "13 armários de dormitório")
        XCTAssertEqual(o["portas"] as? Int, 2, "2P+Gav Ext: 2 portas")
        XCTAssertEqual(o["gav"] as? Int, 3, "2P+Gav Ext: 3 gavetas de fora")
        XCTAssertEqual(o["semLat"] as? Bool, true, "s/ Lat Esq sem a lateral esquerda")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["st"] as? String, "xm,xp,zp,yp", "pedra: setinhas nos lados, frente e altura")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          var fi=apModels('forno').findIndex(function(q){return /6 bocas \(tipo/.test(q[0])}),fg=apAdd('forno',fi);window.ele3api.toggle(fg.id,true);
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }
}
