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
        XCTAssertEqual(o["c"] as? Double ?? 0, a, accuracy: 0.01, "cava de perfil NÃO desconta: porta = lateral + 30, o perfil entra na cava")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testFerragensFitaPorCorNichoNaCorDeForaEPaletaAmadeirada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;S.H=2700;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          newTpl(T('Balcão 2 portas'));newTpl(T('Gaveteiro 3 gavetas'));newTpl(T('2P c/ Cab+Gav Int 600mm'));newTpl(4);S.mods.forEach(function(m){m.corF='#a67c52';m.corFN='Freijó'});draw();var n2=addNichoMicro(1,'liso');newTpl(T('Estante com porta de correr'));draw();
          var hw={};S.mods.forEach(function(m,i){hw[hwTag(m,i)]=hwOf(m)});var g=function(t,k){return (hw[t]&&hw[t][k])?hw[t][k].n:0};
          var nl=cutLines(n2);var txt=cutAll().replace(/<[^>]+>/g,' ');
          open3D();var B=__boxes();var ni=S.mods.indexOf(n2);var cols=B.filter(function(b){return String(b.nm).indexOf(ni+':')===0&&!b.pf&&b.c}).map(function(b){return b.c.join(',')});var okCol=cols.length>0&&cols.every(function(c){return c==='166,124,82'});
          return JSON.stringify({dob1:g('Base 1','Dobradiça 35 mm (caneco)'),cor2:g('Base 2','Corrediça telescópica 500 mm (par)'),dob3:g('Base 3','Dobradiça 35 mm (caneco)'),kit:Object.keys(hw['Base 4']||{}).some(function(k){return /Kit porta de correr/.test(k)}),nichoCor:nl.every(function(l){return l.fin==='c'}),okCol:okCol,fita:/Total de fita de borda/.test(txt)&&/na cor de fora/.test(txt),amad:SWW.length>=10&&/Amadeiradas/.test(swRow('corF','')),errs:__errs});
          """#)
        XCTAssertEqual(o["dob1"] as? Int, 4, "2 portas de 820 → 2 dobradiças 35 mm cada")
        XCTAssertEqual(o["cor2"] as? Int, 3, "3 gavetas → 3 pares de corrediça no comprimento da lateral (500)")
        XCTAssertEqual(o["dob3"] as? Int, 10, "2 portas de 2400 → 5 dobradiças cada")
        XCTAssertEqual(o["kit"] as? Bool, true, "porta de correr → kit de trilhos")
        XCTAssertEqual(o["nichoCor"] as? Bool, true, "nicho aberto: todas as peças na chapa cor")
        XCTAssertEqual(o["okCol"] as? Bool, true, "nicho no 3D na cor de fora do módulo vizinho")
        XCTAssertEqual(o["fita"] as? Bool, true, "plano de corte traz metros de fita por cor")
        XCTAssertEqual(o["amad"] as? Bool, true, "paleta com cores amadeiradas")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual(o["caso"] as? String, "543.5x800,543.5x800", "aéreo 1105 × 800 com cava de perfil: portas 543,5 × 800 (não 770)")
        XCTAssertEqual(o["cv"] as? Int, 0, "cava de perfil não desconta altura")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testRipadoNoPlanoOtimizadoComPlacasDaBaseEParedeLateralAteOMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='sala';S.W=4140;S.H=2700;var ra=rpNew({x:0,b:0,w:4000,h:2600});draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testLateraisPorForaLadoDaFitaEImpressaoDoPlano() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;
          newTpl(4);var m=S.mods[0];m.w=900;m.h=800;m.d=350;m.latFora=true;draw();var P=partsOf(m),g=function(n){var p=P.filter(function(q){return q.name===n})[0];return p?p.cl+'x'+p.cw:''};
          var sides=['Porta','Lateral esquerda','Base inferior','Base superior','Fundo','Lateral de gaveta','Rodapé (pedestal)','Ripa 40 mm','Tamponamento esquerdo'].map(function(n){return edgeSides(n)}).join('|');
          window.print=function(){window.__printed=1};openCut();var pb=document.getElementById('cutprint');var tbl=document.querySelector('#cutbody table.cutpt'),heads=tbl?[].map.call(tbl.querySelectorAll('th'),function(t){return t.textContent}).join(','):'';cutPrint();var hd=document.getElementById('pthead');
          var greens=(document.querySelector('#cutbody svg')||{innerHTML:''}).innerHTML.indexOf('#1f9d55')>=0;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testAssistenteDeAjustesAplicaNosModulosPlantaOpacaECompletarFileira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;S.H=2700;var all=TPL.concat(CATS.flatMap(function(c){return c.it}));var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          /* assistente: laterais por fora, desconto da lateral da gaveta 60, rasgo 8 */wizOpen();var st=STD();st.caixa='fora';st.gavDsc=60;st.gavRb=8;window.WIZ=5;stdRe();var done=!!document.querySelector('#stdbody [data-wizdone="1"]');window.WIZ=null;stdSave();
          newTpl(T('Gaveteiro 3 gavetas'));var m=S.mods[0];draw();var P=partsOf(m),g=function(n){var p=P.filter(function(q){return q.name===n})[0];return p?p.cl+'x'+p.cw:''};var fund=P.filter(function(q){return /^Fundo de gaveta/.test(q.name)})[0];
          var cl=cutLines(m).filter(function(l){return /Lateral de gaveta|Fundo de gaveta/.test(l.name)}).map(function(l){return l.L+'x'+l.W}).join(',');
          /* planta em ângulo: portas e frentes opacas */PLV=true;PLANG=true;draw();var g_=document.getElementById('plx');var trans=g_?[].filter.call(g_.querySelectorAll('polygon[data-pm]'),function(p){return p.getAttribute('fill-opacity')&&+p.getAttribute('fill-opacity')<1}).length:-1;var polys=g_?g_.querySelectorAll('polygon[data-pm]').length:0;PLV=false;PLANG=false;
          /* completar acima: toda a fileira, mesma divisão */S.rp=[];[0,1400,2800].forEach(function(x){var a=rpNew({x:x,b:0,w:1340,h:1000});a.liso=true;a.jt={t:'seca',w:0,d:0}});pwAbove(S.rp[0]);var up=S.rp.filter(function(a){return a.b>0});var okRow=[0,1400,2800].every(function(x){return up.some(function(u){return Math.abs(u.x-x)<.1&&Math.abs(u.w-1340)<.1})});
          return JSON.stringify({done:done,latFora:!!m.latFora,lat:g('Lateral esquerda'),gl:g('Lateral de gaveta'),fundo:fund?fund.cl+'x'+fund.cw:'',cl:cl,trans:trans,polys:polys,okRow:okRow,up:up.length,errs:__errs});
          """#)
        XCTAssertEqual(o["done"] as? Bool, true, "assistente tem o passo final")
        XCTAssertEqual(o["latFora"] as? Bool, true, "módulo novo nasce com laterais por fora (do assistente)")
        XCTAssertEqual(o["lat"] as? String, "705x560", "lateral inteira do chão ao topo da caixa")
        XCTAssertEqual(o["gl"] as? String, "500x110", "lateral da gaveta = frente 170 − 60")
        XCTAssertEqual(o["fundo"] as? String, "530x500", "fundo = caixa 544 − 30 + 2 × 8")
        XCTAssertEqual(o["cl"] as? String, "500x110,530x500", "plano de corte segue os ajustes do assistente")
        XCTAssertEqual(o["trans"] as? Int, 0, "planta em ângulo: nenhuma face de módulo transparente (portas/frentes opacas)")
        XCTAssertGreaterThan(o["polys"] as? Int ?? 0, 10, "planta em ângulo desenha o módulo")
        XCTAssertEqual(o["okRow"] as? Bool, true, "completar acima faz a fileira inteira com a mesma divisão")
        XCTAssertEqual(o["up"] as? Int, 3, "3 colunas, uma placa de 1700 cada até o teto")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testPortaDeCantoMarcacaoEmTodaPortaELixoApagaDivisoriaOuPortas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=4140;var all=TPL.concat(CATS.flatMap(function(c){return c.it})).filter(function(i){return i.w&&i.v});var T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
          /* porta de canto: folha do fundo = vão − 10, folha do lado = vão − 15, altura vão + 30 */newTpl(T('Canto em L (base)'));var c=S.mods[0];draw();var P=partsOf(c),e=c.esp,D=c.d+(c.fundo?(c.fundoMm||6):0),W2=Math.max(c.d+200,c.cw2||900),ds=P.filter(function(p){return p.name==='Porta'});var canto=ds.map(function(p){return p.cl+'x'+p.cw}).join(','),esp=(c.w-e-D-10)+'x650,'+(W2-e-D-15)+'x650';
          /* toda porta tem marcação (dobradiça ou roldana) */var tot=0,ok=0;all.forEach(function(t){S.mods=[];try{newTpl(JSON.parse(JSON.stringify(t)))}catch(_){return}var m=S.mods[0];if(!m)return;partsOf(m).forEach(function(p){if(!/^Porta/.test(p.name)||p.glass||p.noCut)return;tot++;if(p.fur)ok++})});
          /* 🗑 apaga só a divisória selecionada; 🗑 na porta tira as portas do vão */S.mods=[];newTpl(T('Rack de TV'));var m=S.mods[0];S.m=m;draw();var d0=m.div.length,v0=m.v.length;window.DIVI=1;LAST='div';$('delMod').click();var d1=m.div.length,v1=m.v.length,n1=S.mods.length;S.sv=0;LAST='porta';$('delMod').click();var k0=m.v[0].k,n2=S.mods.length;
          var cat=CATS.filter(function(q){return q.id==='painel'})[0].it.some(function(i){return /superior livre/.test(i.n)});
          return JSON.stringify({canto:canto,esp:esp,tot:tot,ok:ok,d:d0+'>'+d1,v:v0+'>'+v1,mods:n1+'/'+n2,k0:k0,cat:cat,errs:__errs});
          """#)
        XCTAssertEqual(o["canto"] as? String, o["esp"] as? String, "porta de canto: vão − 10 e vão − 15, altura do vão + 30")
        XCTAssertEqual(o["ok"] as? Int, o["tot"] as? Int, "toda porta (abrir, basculante, camarão, canto, correr) tem marcação no plano")
        XCTAssertGreaterThan(o["tot"] as? Int ?? 0, 90, "auditou o catálogo inteiro")
        XCTAssertEqual(o["d"] as? String, "2>1", "🗑 com divisória selecionada apaga só ela")
        XCTAssertEqual(o["v"] as? String, "3>2", "os dois vãos viram um")
        XCTAssertEqual(o["mods"] as? String, "1/1", "o módulo pronto continua (não apaga o módulo)")
        XCTAssertEqual(o["k0"] as? String, "free", "🗑 na porta tira as portas do vão")
        XCTAssertEqual(o["cat"] as? Bool, true, "painel/home tem módulo superior livre")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testPortaBasculanteAbreParaBaixoOuCimaNo2DENo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='sala';S.W=3200;S.H=2600;newTpl(4);var m=S.mods[0];m.w=1700;m.h=230;m.d=300;m.b=1500;m.div=[1/3,2/3];
          m.v=[{k:'door',n:1,cava:true,open:1},{k:'door',n:1,cava:true,bas:true,bd:'down',open:1},{k:'door',n:1,cava:true,bas:true,bd:'up',open:1}];S.m=m;draw();
          var paths=[].map.call(document.querySelectorAll('#svg #mod path[fill="#e6d9be"]'),function(p){var d=p.getAttribute('d').match(/-?[\d.]+/g).map(Number);var xs=[d[0],d[2],d[4],d[6]],ys=[d[1],d[3],d[5],d[7]];return (Math.max.apply(null,xs)-Math.min.apply(null,xs))>(Math.max.apply(null,ys)-Math.min.apply(null,ys))?'deitada':'em pé'});
          open3D();var B=__boxes();var d3=B.filter(function(b){return /^0:Porta$/.test(String(b.nm))&&!b.nol&&(b.y1-b.y0)>12&&((b.x1-b.x0)>300||(b.z1-b.z0)>300)}).map(function(b){return b.vi+':'+((b.pf&&b.pf.ax==='x')?'gira-eixo-x':'lado')+':'+Math.round(b.y1-b.y0)});
          return JSON.stringify({p2d:paths.join(','),d3:d3.join(','),errs:__errs});
          """#)
        XCTAssertEqual(o["p2d"] as? String, "em pé,deitada,deitada", "2D: porta de lado abre pro lado; basculante abre pra baixo/cima (faixa deitada)")
        XCTAssertEqual(o["d3"] as? String, "0:lado:209,1:gira-eixo-x:15,2:gira-eixo-x:15", "3D: basculante gira no eixo horizontal (fica deitada), a comum gira de lado (230 − 21 do chanfro da cava, que sai em degraus finos)")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Tamponamento total = moldura de 4 réguas de 80 (frente, trás e as duas pontas) no 3D e no corte · cor amadeirada com veio no 3D e nas bolinhas ·
    /// 🖌 Pintar no 3D: pinta só a peça tocada (3D, 2D e plano de corte NA COR), por tipo, e tira · opção de desligar o tamponamento automático
    func testMolduraDoTamponamentoVeioDaMadeiraPincelEAutoTamponamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;newTpl(3);var m=S.mods[0];m.w=1400;m.x=500;m.tl=m.tr=true;m.tlW=30;m.trW=30;m.tlM=m.trM=1;m.corF='#b98d5b';m.corFN='Carvalho Hanover';S.m=m;draw();open3D();
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
        XCTAssertEqual(o["eng"] as? String, "1:15x720x80,2:15x720x80,3:15x80x431,4:15x80x431", "3D: 4 réguas de 80 por camada — frente, trás e as duas pontas (591 − 160 = 431)")
        XCTAssertEqual(o["cl"] as? String, "720x80x4,431x80x4", "corte: 2 réguas no comprimento + 2 nas pontas, por lado")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Paleta real (Arauco, Duratex, Greenplac) com nome · marca · textura, 🔍 procurar cor no painel e no pincel do 3D,
    /// peça pintada/colorida sai NA COR com o nome da cor, e cada cor vira a sua chapa no plano (tamponamento Louro Freijó → chapa Louro Freijó)
    func testPaletaRealComBuscaEChapaPorCor() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;newTpl(3);var m=S.mods[0];m.tl=m.tr=true;m.tlW=30;m.trW=30;m.tlM=m.trM=1;S.m=m;draw();panel();
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
        XCTAssertEqual(o["n"] as? Int, 60, "60 padrões reais na paleta (45 lisos + 15 amadeirados)")
        XCTAssertEqual(o["vis"] as? [String], ["Louro Freijó · Arauco Trend", "Louro Freijó · Arauco Poro"], "🔍 'louro freij' acha os dois Louro Freijó")
        XCTAssertEqual(o["corFId"] as? String, "arauco-louro-freijo-trend")
        XCTAssertEqual(o["corFN"] as? String, "Louro Freijó · Arauco Trend", "nome real: padrão · fabricante · textura")
        XCTAssertEqual(o["cl"] as? String, "c:Louro Freijó · Arauco Trend", "tamponamento em Louro Freijó → peça NA COR Louro Freijó")
        XCTAssertEqual(o["pl"] as? [String], ["b|", "c|Cinza Sagrado · Duratex Essencial Acetinada", "c|Louro Freijó · Arauco Trend", "f|"], "uma chapa por cor no plano")
        XCTAssertEqual(o["heads"] as? [String], ["🎨 CHAPA CINZA SAGRADO · DURATEX ESSENCIAL ACETINADA · MDF 15 mm", "🎨 CHAPA LOURO FREIJÓ · ARAUCO TREND · MDF 15 mm"], "cabeçalho da chapa com o nome da cor")
        XCTAssertEqual(o["rows"] as? [String], ["Chapa MDF 15 mm · Cinza Sagrado · Duratex Essencial Acetinada", "Chapa MDF 15 mm · Louro Freijó · Arauco Trend"], "material: uma linha por cor")
        XCTAssertEqual(o["pvis"] as? [String], ["Cinza Puro · Arauco Matt", "Cinza Cristal · Arauco TX", "Cinza Sagrado · Duratex Essencial Acetinada"], "🔍 no pincel do 3D")
        XCTAssertEqual(o["pc"] as? String, "duratex-cinza-sagrado-essencial", "pintura guarda o padrão")
        XCTAssertEqual(o["pcl"] as? [String], ["c:Cinza Sagrado · Duratex Essencial Acetinada:1", "c:Louro Freijó · Arauco Trend:1"], "porta pintada separa da outra no corte, cada uma na sua cor")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Regras novas nos Ajustes (valem pros módulos novos e "aplicar a todos"): recuo do rodapé, avanço do tamponamento, recuo da prateleira,
    /// corrediça pela profundidade, frente de gaveta sobe separado, porta de correr (sobreposição/folga/altura), arredondamento, peça máxima,
    /// Sistema 32 no plano e padrão de cor real dos módulos novos
    func testAjustesNovosRodapeTamponamentoPrateleiraCorredicaCorrerSistema32ECorPadrao() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
          var st=STD(),keep=JSON.stringify(st);
          /* 1) valores novos nos ajustes */st.rodRec=50;st.tpAv=40;st.pm=40;st.corrDsc=50;st.corrStep=50;st.gUp=10;st.frUp=5;st.pcSob=40;st.pcW=20;st.pcH=40;st.s32=1;st.s32Off=37;st.s32Step=32;st.rnd=1;st.pcMax=2000;
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
        XCTAssertEqual(o["tp"] as? Double, 636, "tamponamento = prof 590 + avanço 40 + fundo 6")
        XCTAssertEqual(o["frY"] as? [Double], [10, 10], "frentes de gaveta sobem 10 (separado das portas, 5)")
        XCTAssertEqual(o["nl"] as? Double, 500, "corrediça: múltiplo de 50 abaixo de (590 − 50)")
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
        XCTAssertEqual(o["mats"] as? Int, 61, "paleta real do padrão (60 + sem padrão)")
        XCTAssertEqual(o["mvis"] as? [String], ["Cinza Sagrado · Duratex Essencial Acetinada"], "🔍 no padrão de cor dos Ajustes")
        XCTAssertEqual(o["rnd"] as? Bool, true, "arredondamento em 1 mm")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Fita de topo do caixote branco na cor das portas (branca só em prateleira, gaveta e porta tempero · editável nos Ajustes),
    /// pincel: 💧 copiar a cor de uma peça e pintar só a fita de topo · tudo vai pro plano de corte (nome da cor da fita)
    func testFitaDeTopoNaCorDasPortasContaGotasEPintarSoAFita() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Abrir a porta não muda a cor de nada: tamponamento, engrosso e réguas seguem a cor das portas (pintadas pelo pincel) com a porta fechada,
    /// abrindo e fechando de novo · no plano de corte também · tocar na fita de topo abre o diálogo pela fita e, pintando uma, pergunta pelas outras
    func testAcabamentoNaoMudaAoAbrirPortaEFitaPeloToque() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
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
        XCTAssertEqual(o["order"] as? [String], ["x", "fita", "fitaMod", "fitaAll", "fitaW", "one", "type", "typeAll", "mod"], "tocando na fita, as opções de fita vêm primeiro (com a opção de fita branca só nela)")
        XCTAssertEqual(o["pvFita"] as? Bool, true, "prévia só na fita")
        XCTAssertTrue((o["same"] as? String ?? "").contains("já estava"), "fita já na cor das portas: avisa em vez de repetir: \(o["same"] ?? "")")
        XCTAssertTrue((o["more"] as? String ?? "").hasPrefix("Pintar as outras fitas de topo"), "depois de pintar uma fita pergunta pelas outras: \(o["more"] ?? "")")
        XCTAssertEqual(o["pf1"] as? String, "duratex-cinza-sagrado-essencial")
        XCTAssertEqual(o["pfAll"] as? String, "duratex-cinza-sagrado-essencial", "fitas de todos os módulos")
        XCTAssertEqual(o["pfGone"] as? Bool, true, "a pintura por fita sai quando pinta o módulo inteiro")
        XCTAssertEqual(o["hid"] as? Bool, true, "diálogo fecha depois de responder")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Porta de vidro real: 4 réguas de perfil de alumínio na cor escolhida + vidro de 4 mm (reflexo bronze, fumê…) no 3D, fechada, aberta e basculante;
    /// cor do alumínio e do vidro por módulo (aba Portas) e padrão nos Ajustes; o pincel não pinta o perfil; ferragens listam perfil (m) e vidro (m²)
    func testPortaDeVidroComPerfilDeAluminioEVidroBronze() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Eletros vivos: forno embutido no módulo e na torre abre com 1 toque (forno e micro-ondas separados), porta com vidro transparente
    /// mostrando a cavidade (guias, grade, assadeira, lâmpada), luz acende ao abrir ou pelo 💡 · coifa liga luz e motor · TV liga
    func testEletrosVivosFornoMicroCoifaETV() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3600;S.H=2600;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Torre forno + micro-ondas (embutir)'));draw();['forno','coifa','tv'].forEach(function(t){apAdd(t,0)});draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();
          var ov=__boxes().filter(function(b){return /^0:Corte do forno/.test(b.nm)}),mc=__boxes().filter(function(b){return /^0:Corte do micro/.test(b.nm)});
          var glassOv=ov.filter(function(b){return b.gl&&b.a<.6}).length,glassMc=mc.filter(function(b){return b.gl&&b.a<.6}).length,emClosed=ov.filter(function(b){return b.em}).length;
          ele3api.toggle('mo0|0',true);await new Promise(function(r){setTimeout(r,1800)});
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Cava usinada sem faixa preta (só a linha fina de sombra na cor da porta) e com o chanfro na porta aberta ·
    /// pincel: tocar perto da fita de topo (0,8 mm) pega a fita, modo ▭ Fita e 💧 copiando a cor da fita
    func testCavaSemFaixaPretaChanfroNaPortaAbertaEFitaFacilDeTocar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=2400;S.H=2600;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Fita uma por uma, com toque de verdade: base, prateleira, tirar a pintura de uma fita só, fita branca numa peça só,
    /// a fita tocada fica destacada em laranja e, se a cor for a mesma, avisa que já estava (acompanha as portas)
    func testFitaUmaPorUmaPrateleiraTirarEBranca() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Micro-ondas no nicho do armário: medidas reais no catálogo, encaixar (centraliza no vão, apoia na base, frente rente à caixa),
    /// só apoiar na base e o aviso de folga / não cabe
    func testMicroondasEncaixaNoNichoComMedidaReal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.env='cozinha';S.W=3000;S.H=2600;
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Aéreo nicho aberto'));var m=S.mods[0];m.x=900;m.w=600;m.h=450;m.b=1500;m.d=350;m.v=[{k:'shelves',n:0}];S.m=m;draw();
          apAdd('microondas',0);var f=S.fr[S.fr.length-1];var models=APM.microondas.m.map(function(q){return q[0]}).filter(function(n){return /tipo /.test(n)}).length;
          var q=APM.microondas.m.filter(function(q){return /NN-ST25/.test(q[0])})[0];f.w=q[1];f.h=q[2];f.d=q[3];f.nome=q[0];f.x=1000;f.b=1600;draw();
          open3D();await new Promise(function(r){setTimeout(r,300)});fx3api.open({k:'fr',id:f.id});var msg=(document.querySelector('#it4').textContent.match(/Nicho [^·]*· [^·]*·[^·]*/)||[''])[0].trim();
          document.querySelector('#it4 [data-qnicho="1"]').click();var emb={x:f.x,b:f.b,nicho:f.nicho};
          var zs=__boxes().filter(function(b){return b.x0>=f.x-1&&b.x1<=f.x+f.w+1&&b.y0>=f.b-1&&b.y1<=f.b+f.h+2&&!/^0:/.test(String(b.nm||''))}),zmin=Math.round(Math.min.apply(null,zs.map(function(b){return b.z0})));
          f.d=300;__build();var zs2=__boxes().filter(function(b){return b.x0>=f.x-1&&b.x1<=f.x+f.w+1&&b.y0>=f.b-1&&b.y1<=f.b+f.h+2&&!/^0:/.test(String(b.nm||''))}),zmin2=Math.round(Math.min.apply(null,zs2.map(function(b){return b.z0})));
          f.x=850;f.b=1700;delete f.nicho;fx3api.open({k:'fr',id:f.id});document.querySelector('#it4 [data-qapoia]').click();var apoia={x:f.x,b:f.b};
          f.w=700;fx3api.open({k:'fr',id:f.id});var nao=/não cabe/.test(document.querySelector('#it4').textContent);
          document.getElementById('v3x').click();
          /* 2D: arrastou e soltou em cima do módulo → encaixa sozinho e aparece por cima do módulo (dentro do nicho) */
          f.w=442;delete f.nicho;f.x=1100;f.b=1650;draw();drag={t:'ap',id:f.id,p:{x:0,y:0},x0:f.x,b0:f.b};document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));drag={t:'none'};
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
        XCTAssertEqual(o["zmin2"] as? Int, 48, "300 de fundo: entra até ficar com a frente rente à caixa (350 − 300 − 2)")
        let ap = o["apoia"] as? [String: Any] ?? [:]
        XCTAssertEqual(ap["x"] as? Int, 850, "só apoiar: não mexe no lado")
        XCTAssertEqual(ap["b"] as? Int, 1515, "só apoiar: desce até a base")
        XCTAssertEqual(o["nao"] as? Bool, true, "avisa quando não cabe")
        let dr = o["drop"] as? [String: Any] ?? [:]
        XCTAssertEqual(dr["x"] as? Int, 979, "2D: soltou em cima do módulo, centraliza no vão")
        XCTAssertEqual(dr["b"] as? Int, 1515, "2D: apoia na base")
        XCTAssertEqual(dr["nicho"] as? Int, 1)
        XCTAssertEqual(o["order"] as? String, "mod,ap", "2D: o micro-ondas aparece por cima do módulo (dentro do nicho), não atrás")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }
}
