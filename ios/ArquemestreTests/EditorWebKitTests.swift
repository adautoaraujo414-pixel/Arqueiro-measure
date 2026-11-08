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
        XCTAssertEqual(o["caso"] as? String, "542.5x800,542.5x800", "aéreo 1105 × 800 com cava de perfil: portas 542,5 × 800 (2 mm entre as folhas; não 770)")
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
          /* porta de canto: folha do fundo = vão − 10, folha do lado = vão − 15, altura vão + 30 */newTpl(T('Canto em L (base)'));var c=S.mods[0];draw();var P=partsOf(c),e=c.esp,D=c.d+(c.fundo?(c.fundoMm||6):0),W2=Math.max(c.d+200,c.cw2||900),ds=P.filter(function(p){return p.name==='Porta'});var canto=ds.map(function(p){return p.cl+'x'+p.cw}).join(','),esp=(c.w-e-D-10)+'x650,'+(W2-e-D-15)+'x650';/* folha do fundo = vão − 10 (0,5 mm de folga da folha do lado), folha do lado = vão − 15 */
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
        XCTAssertEqual(o["order"] as? [String], ["x", "fita", "fitaMod", "fitaAll", "fitaW", "one", "type", "typeAll", "mod", "modIn"], "tocando na fita, as opções de fita vêm primeiro (com a opção de fita branca só nela)")
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

    func testTomadasRegistroChurrasqueiraBotaoDoLEDETVComLogo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Aba 🎨 Cores no 2D com cabeçalho (paredes e pisos, armários, portas e fitas) e 15 pisos e porcelanatos com textura,
    /// Caixa da geladeira (laterais até em cima + aéreo), ripado em cima dos módulos até o teto (na frente ou na parede) e réguas das laterais por nível
    func testCaixaDaGeladeiraRipadoEmCimaEReguasDasLaterais() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* caixa da geladeira: laterais até em cima + aéreo, vão aberto embaixo e a geladeira já dentro */
          newTpl(tpl('Caixa da geladeira side by side (laterais + aéreo)'));var g=S.mods[0];R.caixa=[g.h,g.base,g.rod].join(',');R.nicho=partsOf(g).some(function(p){return p.gelN});R.gel=S.fr.filter(function(f){return f.t==='geladeira'}).length;
          /* ripado em cima dos superiores até o teto */
          for(var i=0;i<2;i++){newTpl(4);var u=S.mods[S.mods.length-1];u.x=1100+i*800;u.w=800}var up=S.mods.filter(function(m){return m.sup});S.m=up[0];S.tab=4;draw();panel();
          document.querySelector('#bd [data-rpt="frente"]').click();document.querySelector('#bd [data-rptall]').click();R.ripado=up.every(function(m){return m.rpTop==='frente'});var ch=partsOf(up[0]).filter(function(p){return /^Chapa base do ripado/.test(p.name)})[0];R.ateTeto=ch?ch.h:0;
          document.querySelector('#bd [data-rpt="parede"]').click();R.parede=(partsOf(up[0]).filter(function(p){return /^Ripa/.test(p.name)})[0]||{rpz:[-1]}).rpz[0];
          /* réguas das laterais por nível */
          document.querySelector('#bd [data-rgm="sup|pontas"]').click();R.pontas=up.map(function(m){return (m.egL||0)+''+(m.egR||0)}).join(',');
          document.querySelector('#bd [data-rgm="sup|duplo"]').click();R.duplo=up[0].egD===up[0].d;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          S.W=5610;S.H=2600;S.mods=[];S.fr=[];S.stones=[];draw();var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Porta do ambiente abre na parede do lado, pedra sólida (caixa da geladeira e geladeira não passam por ela), geladeira acompanha a caixa e 5 toques abrem o 2D só do módulo
    func testPedraSolidaGeladeiraAcompanhaPortaDaSalaE5ToquesEditaSoOModulo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=5000;S.H=2700;S.mods=[];S.fr=[];S.stones=[];S.ops=[];draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          __foto3({yaw:.6,pitch:.35});__foto3(null);__build();var n=0,ok=0;__boxes().filter(function(b){return /^\d+:Lateral/.test(b.nm)}).forEach(function(b){var c=__p3(b.x1,(b.y0+b.y1)/2,b.z1);if(!c)return;var h0=__rayMod(c[0]-1,c[1]);if(!h0||h0.nm!==b.nm)return;n++;var p=__pick(c[0]+5,c[1]);if(p&&String(p.nm).split(':')[0]===String(b.nm).split(':')[0])ok++});
          R.borda=n>3&&ok===n;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["tot"] as? Bool, true, "muitos pontos conferidos")
        XCTAssertEqual(o["bad"] as? Int, 0, "o toque acha a peça que está na frente no ponto tocado")
        XCTAssertEqual(o["borda"] as? Bool, true, "dedo pertinho da borda da lateral acha o módulo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          S.W=4000;S.H=2700;S.mods=[];S.fr=[];S.stones=[];S.ops=[];draw();var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};
          newTpl(tpl('Caixa da geladeira side by side (laterais + aéreo)'));var g=S.mods[0];g.x=1500;S.m=null;draw();var top=function(){var e=document.querySelector('#svg [data-ap]');return !!e&&!!e.compareDocumentPosition&&!!(document.querySelector('#svg [data-mi]').compareDocumentPosition(e)&Node.DOCUMENT_POSITION_FOLLOWING)};R.gel2d=top();
          var k0=JSON.stringify(Object.assign({},g,{x:0,wing:0,_gel:0}));__mdDrop(0,[0.5,1200,1500]);R.gelLado=g.wing==='e'&&!!document.querySelector('#svg [data-ap]');R.naoPerde=JSON.stringify(Object.assign({},g,{x:0,wing:0,_gel:0}))===k0;
          /* trena no 2D: gruda nas bordas e dá a medida */
          S.mods=[];S.fr=[];draw();newTpl(tpl('Balcão 2 portas'));var m=S.mods[0];m.x=600;S.m=null;draw();document.getElementById('med2b').click();
          var sv=document.getElementById('svg'),host=sv.parentNode,rc=sv.getBoundingClientRect(),f=rc.width/VB.w,P=function(x,y){return [rc.left+(OX+x*K-VB.x)*f,rc.top+(OY+(S.H-y)*K-VB.y)*f]},ev=function(tp,el,p){el.dispatchEvent(new PointerEvent(tp,{clientX:p[0],clientY:p[1],pointerId:1,bubbles:true,isPrimary:true,pointerType:'touch'}))};
          var pa=P(m.x+6,400),pb=P(m.x+m.w-5,410);ev('pointerdown',sv,pa);ev('pointermove',sv,pb);ev('pointerup',sv,pb);R.trena2d=MED2.L.length===1&&Math.round(Math.hypot(MED2.L[0].b[0]-MED2.L[0].a[0],MED2.L[0].b[1]-MED2.L[0].a[1]))===900&&/900 mm/.test((document.querySelector('#medg text')||{}).textContent||'');R.naoMexeu=m.x===600;document.getElementById('med2b').click();
          /* trena no 3D */
          /* mede o tampo do armário visto de cima (base superior, sem travessa nem moldura): as portas agora sobem e cobrem a travessa, então a aresta da frente não é mais um ponto livre pra trena */m.trav=false;m.mold=false;draw();open3D();await new Promise(function(r){setTimeout(r,300)});__foto3({yaw:.2,pitch:.9});__foto3(null);__build();document.getElementById('v3med').click();var x0=1e9,x1=-1e9,y1=-1e9,z1=-1e9;__boxes().forEach(function(q){if(!/^0:Base superior/.test(String(q.nm)))return;x0=Math.min(x0,q.x0);x1=Math.max(x1,q.x1);y1=Math.max(y1,q.y1);z1=Math.max(z1,q.z1)});
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Painéis lisos da parede: um não entra em cima do outro (o vizinho encurta e a junta continua), a placa recortada na porta é uma peça só no 3D e placa só até 2700 (o resto vai em cima depois da junta)
    func testPaineisLisosSemSobreporEPortaSemRiscoNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3979;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.rp=[];S.ops=[{id:9,t:'porta',x:0,b:0,w:800,h:2100,st:'vao'}];draw();var R={};
          /* 4 placas com junta de 15 (rebaixo) e a primeira recortada na porta */
          var x=0;[983.5,983.5,983.5,983.5].forEach(function(w,i){var a={id:100+i,liso:true,x:x,b:0,w:w,h:2600,jt:{t:'reb',w:15,d:6}};if(Math.min(800,x+w)-Math.max(0,x)>1)a.rc={op:9,f:0};S.rp.push(a);x+=w+15});draw();
          /* a primeira cresce: a segunda encurta e a junta de 15 continua (uma não entra em cima da outra) */
          S.rp[0].w=1079;draw();var p=S.rp[0],q=S.rp[1];R.junta=Math.round((q.x-(p.x+p.w))*10)/10;R.w2=q.w;R.fim=Math.round((S.rp[3].x+S.rp[3].w)*10)/10;
          /* no 3D a placa recortada é uma peça só: sem risco de emenda em cima da porta (só o contorno) */
          open3D();await new Promise(function(r){setTimeout(r,300)});__build();var bx=__boxes().filter(function(b){return b.rpid===100});R.semRisco=bx.filter(function(b){return b.g!=='lo'}).every(function(b){return b.nol===1})&&bx.some(function(b){return b.g==='lo'&&Math.abs(b.x0-800)<1&&Math.abs(b.x1-1079)<1});
          /* regra: placa vai até 2700 · parede de 3100: em cima, depois da junta de 15, a continuação com a mesma largura */
          document.getElementById('v3x').click();S.H=3100;S.rp=[];S.ops=[];S.rodape=0;draw();S.trena={x0:1070,x1:3979};TRT='reb';TRJ=15;TRN=3;TRW=0;TRH=0;trCreate();var lo=S.rp.filter(function(a){return a.b===0}),hi=S.rp.filter(function(a){return a.b>0});
          R.max2700=Math.max.apply(null,S.rp.map(function(a){return a.h}))===2700;R.emCima=lo.length===3&&hi.length===3&&lo.every(function(a){return hi.some(function(u){return u.x===a.x&&u.w===a.w&&u.b===2715&&u.h===385})});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["junta"] as? Double, 15, "a junta de 15 continua entre as placas")
        XCTAssertEqual(o["w2"] as? Double, 888, "a placa vizinha encurta")
        XCTAssertEqual(o["fim"] as? Double, 3979, "a última placa continua no fim da parede")
        XCTAssertEqual(o["semRisco"] as? Bool, true, "placa recortada na porta sem risco de emenda no 3D")
        XCTAssertEqual(o["max2700"] as? Bool, true, "placa vai até 2700 de altura")
        XCTAssertEqual(o["emCima"] as? Bool, true, "acima de 2700: junta e a continuação em cima, mesma largura")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Trena no 3D: gruda sozinha no canto de dentro (parede + parede + chão) e na quina de fora do painel, e mede reto
    func testTrenaGrudaNoCantoPorDentroEPorFora() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          /* trena no 3D gruda no canto de dentro (parede + parede + chão) e na quina de fora do painel, e mede reto pelo chão */
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3979;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.ops=[];S.rp=[];S.rodape=0;draw();
          S.trena={x0:1070,x1:3979};TRT='reb';TRJ=15;TRN=3;TRW=0;TRH=0;trCreate();draw();
          open3D();await new Promise(function(r){setTimeout(r,400)});__foto3({yaw:.45,pitch:.25});__foto3(null);__build();var R={};
          /* canto de dentro: parede da esquerda + parede do fundo + chão · toque 8 px fora do canto */
          var q=__p3(0,0,0);var h=__med3Hit(q[0]+8,q[1]-6);R.canto=h.map(Math.round);
          /* canto de fora do painel (quina de baixo esquerda do 1º painel, na frente) */
          var pz=__boxes().filter(function(b){return b.rpid!=null&&b.x0>=1069&&b.x0<=1071&&b.y0<1})[0];R.pz=pz?[pz.x0,pz.z1]:null;var q2=__p3(1070,0,pz?pz.z1:18);var h2=__med3Hit(q2[0]-6,q2[1]+5);R.quina=h2.map(Math.round);
          /* medir do canto até o painel pelo chão: reta, 1070 */
          document.getElementById('v3med').click();var cv=document.getElementById('cv3'),cr=cv.getBoundingClientRect(),ev=function(tp,p){cv.dispatchEvent(new PointerEvent(tp,{clientX:cr.left+p[0],clientY:cr.top+p[1],pointerId:1,bubbles:true,isPrimary:true,pointerType:'touch'}))};
          ev('pointerdown',[q[0]+8,q[1]-6]);ev('pointermove',[q2[0]-6,q2[1]+5]);ev('pointerup',[q2[0]-6,q2[1]+5]);var M3=__med3(),L=M3.L[0];R.seg=L?JSON.stringify([L.a.map(Math.round),L.b.map(Math.round)]):null;R.len=L?Math.round(Math.hypot(L.b[0]-L.a[0],L.b[1]-L.a[1],L.b[2]-L.a[2])):0;
          R.canto0=JSON.stringify(R.canto)==='[0,0,0]';R.quinaOk=JSON.stringify(R.quina)==='[1070,0,18]';R.mede=R.len===1070;R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["canto0"] as? Bool, true, "canto de dentro exato: \(o["canto"] ?? "")")
        XCTAssertEqual(o["quinaOk"] as? Bool, true, "quina de fora do painel exata: \(o["quina"] ?? "")")
        XCTAssertEqual(o["mede"] as? Bool, true, "do canto até o painel: 1070 (\(o["len"] ?? ""))")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Rack do zero (Sala): entra a caixa vazia com foto no catálogo e já abre o 2D só dele pra montar divisória, gaveta e porta
    func testRackDoZeroAbreSoEleParaMontar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3600;S.H=2600;S.mods=[];S.fr=[];S.stones=[];S.ops=[];S.rp=[];draw();var R={};
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Sólido: peça nova não entra em outra (torres, prateleiras, geladeiras, air fryer, guarda-roupa, porta de correr no painel) e painel liso maior que a chapa sai em placas de 1800 × 2700 no sentido escolhido
    func testSolidoNadaEntraEmNadaEPainelSaiEmPlacasDaChapa() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          var fresh=function(room){S.room=room;S.env='cozinha';S.W=4200;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw()};
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
          fresh('cozinha');S.W=4140;S.H=3190;var L=rpNew({x:0,b:2610,w:4140,h:580});L.liso=true;LAST='rp';S.tab=8;RPSEL=L.id;draw();panel();rpBar();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Área do painel/ripado: toque no vão ou arraste marcando a área, o app acha as áreas livres (desvia de móvel, pedra, janela, eletro e outro painel), largura final e cria
    func testAreaDoPainelDesviaDosSolidosComLarguraFinal() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='cozinha';S.env='cozinha';S.W=4200;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Cor e veio dos painéis (placa lisa, ripas e fundo do ripado) com textura real no 3D, plano de corte por cor com veio travado, e a régua da junta em pé fecha o cruzamento com a junta de cima
    func testCorEVeioDosPaineisEReguaDaJuntaFechaOCruzamento() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=4140;S.H=3190;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Pintar painéis: pelo 3D (pincel, conta-gotas e borracha, sem selecionar o painel) e pela aba Cores › ▥ Painéis (mesmo sem módulo), com o veio
    func testPintarPaineisPelo3DEPelaAbaCores() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='quarto';S.env='livre';S.W=3841;S.H=3215;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// 2 toques na parede no 3D: sem nada escolhido pergunta (porta, vão, janela) e cria ali; com a porta escolhida ela vai pra lá; medidas digitadas no quadro
    func testDoisToquesNaParedeCriaEMovePortaEJanela() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();open3D();await new Promise(function(q){setTimeout(q,400)});__build();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Régua do rebaixo das juntas: cor própria (Cores, painel e pincel do 3D) e no plano de corte; vão nas paredes do lado igual ao do fundo
    func testReguaDoRebaixoPintaEVaoNaParedeDoLado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=3215;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Parede com porta ou vão sai inteira: sem risco nem emenda em cima da porta (fundo e lados); janela não recorta a parede
    func testParedeSemRiscoEmCimaDaPortaEJanela() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          S.room='sala';S.env='livre';S.W=3841;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.stones=[];S.st=null;S.m=null;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Rack do zero entra suspenso no meio do painel (moldura e régua de escolha, tampo em cima), painel aparece no 2D só dele,
    /// ⇔ Centralizar rack e prateleira (sobra igual dos dois lados) e sem painel fica no meio da parede
    func testRackNoMeioDoPainelSuspensoECentralizar() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Localizador da chapa: tocar na placa do painel no plano de corte acende ela em rosa no 3D (por cima da cor/madeira),
    /// cada peça de painel acha a sua, régua do rebaixo acende só as réguas e a folha da porta embutida acende a folha
    func testLocalizadorDaChapaAchaAPlacaDoPainelNo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R={};
          S.room='sala';S.env='livre';S.W=6000;S.H=3215;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// ⧉ Copiar: módulo pela Estrutura e pelo 2D só dele (sai igual, do lado, sem entrar em nada), prateleira (em cima/embaixo) e painel; sem lugar avisa
    func testCopiarModuloPainelEPrateleira() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=3215;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          run('salaChao',function(){S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;for(var i=0;i<4;i++){var a=rpNew({x:i*964,b:0,w:949,h:2700});a.liso=true}var tv=apAdd('tv',1);tv.x=1350;tv.b=1100;newTpl(JSON.parse(JSON.stringify(pick('Rack de TV'))))});
          run('salaDois',function(){S.room='sala';S.env='cozinha';S.W=4200;S.H=2700;newTpl(JSON.parse(JSON.stringify(pick('Rack de TV'))));newTpl(JSON.parse(JSON.stringify(pick('Rack suspenso'))));});
          run('cozinha',function(){S.room='cozinha';S.env='cozinha';S.W=3600;S.H=2700;['Balcão 2 portas','Gaveteiro 3 gavetas','Balcão da pia (cuba)','Balcão 1 porta'].forEach(function(n){newTpl(JSON.parse(JSON.stringify(pick(n))))});newTpl(4);newTpl(4);newTpl(4)});
          run('demo',function(){demoScene()});
          run('quarto',function(){S.room='quarto';S.env='livre';S.W=3600;S.H=2700;var it=null;CATS.forEach(function(c){if(/Quarto|quarto/.test(c.n))c.it.slice(0,4).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.w&&!t.act)newTpl(JSON.parse(JSON.stringify(t)))})})});
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual((o["salaChao"] as? [String])?.count, 0, "textos sobrepostos em salaChao: \(o["salaChao"] ?? "")")
        XCTAssertEqual((o["salaDois"] as? [String])?.count, 0, "textos sobrepostos em salaDois: \(o["salaDois"] ?? "")")
        XCTAssertEqual((o["cozinha"] as? [String])?.count, 0, "textos sobrepostos em cozinha: \(o["cozinha"] ?? "")")
        XCTAssertEqual((o["demo"] as? [String])?.count, 0, "textos sobrepostos em demo: \(o["demo"] ?? "")")
        XCTAssertEqual((o["quarto"] as? [String])?.count, 0, "textos sobrepostos em quarto: \(o["quarto"] ?? "")")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// 🔒 Travar porta, vão e janela (Ambiente e quadro do 3D) e projeto recebido pelo link (funcionário/cliente/ao vivo) abre tudo travado: só quem criou mexe
    func testTravarPortaJanelaEProjetoRecebidoTudoTravado() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.confirm=function(){return true};var R={},W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
          S.room='sala';S.env='cozinha';S.W=3841;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.stones=[];S.st=null;S.m=null;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          rooms.forEach(function(room){S.room=room;S.env=room==='quarto'||room==='closet'?'livre':'cozinha';S.W=4200;S.H=2700;S.mods=[];S.fr=[];S.rp=[];S.isl=[];S.ops=[];S.stones=[];S.st=null;S.m=null;draw();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Torre com portas separadas e réguas, todas as portas abrem, mover módulo com 2 toques e planta em ângulo sem peça por cima da pedra
    func testTorrePortasSeparadasPortasAbremMoverDe2ToquesEPlantaSemSobrepor() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=4200;S.H=2700;S.mods=[];S.fr=[];S.stones=[];draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          /* todas as portas de todos os módulos abrem (caixa da geladeira e torres também) */
          var items=[];CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.w&&t.v)items.push(t)})});var bad=[];
          items.forEach(function(t){S.mods=[];S.fr=[];try{newTpl(t)}catch(e){return}var m=S.mods[0];if(!m)return;partsOf(m).filter(function(p){return /^Porta/.test(p.name)&&p.vi!==undefined&&!p.noCut}).forEach(function(p){var v=m.v[p.vi];if(!v)return;v.od={};v.od[p.dq]=1;var q=partsOf(m).filter(function(x){return x.pk===p.pk})[0];if(!q||!q.open)bad.push(t.n);v.od={}})});R.portas=bad.length;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Painel: no cabeçalho escolhe ripado ou painel liso (toque pra adicionar) e troca depois no painel selecionado
    func testPainelRipadoOuLisoNoCabecalho() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=3000;S.H=2700;S.mods=[];S.fr=[];S.rp=[];draw();S.tab=8;panel();var R={};
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Rodapé do armário alto igual aos de baixo, pintar o módulo por dentro, dobradiça real, porta com amortecedor e eletro aberto sem ficar azul
    func testRodapeIgualPintarPorDentroEletroSemAzulEPortaAmortecida() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.env='cozinha';S.W=4200;S.H=2700;S.mods=[];S.fr=[];S.stones=[];S.isl=[];draw();
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
        XCTAssertEqual(o["tamp"] as? String, "2100,2100", "tamponamento do armário alto para em cima do rodapé")
        XCTAssertEqual(o["alto"] as? Int, 2100)
        XCTAssertEqual(o["tempero"] as? Bool, true, "porta-tempero pintado por dentro (frente de trás, costa, base, réguas e fundo)")
        XCTAssertEqual(o["fora"] as? Bool, false, "por dentro não pinta frente, tamponamento nem rodapé")
        XCTAssertEqual(o["corte"] as? Bool, true, "plano de corte com a cor de dentro")
        XCTAssertEqual(o["dob"] as? Int, 4, "porta de 2000: 4 dobradiças")
        XCTAssertEqual(o["amort"] as? Bool, true, "os últimos 20% fecham devagar")
        XCTAssertEqual(o["fechou"] as? Bool, true, "porta encosta e fecha")
        XCTAssertEqual(o["semAzul"] as? Bool, true, "eletro aberto não fica azul")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Editar qualquer peça de qualquer módulo pronto: caixa da gaveta inteira, canto em L, régua do tamponamento e medida digitada
    func testEditarQualquerPecaCaixaDaGavetaCantoEmLEMedidaDigitada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.rp=[];S.env='cozinha';S.W=4200;S.H=2700;draw();
          var tpl=function(nm){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===nm)it=q})});return it};var R={};
          open3D();await new Promise(function(r){setTimeout(r,300)});
          /* caixa da gaveta: altura e profundidade digitadas mudam laterais, frente/costa e fundo juntos */
          newTpl(tpl('Gaveteiro 3 gavetas'));var g=S.mods[0];__build();__e3t(0,'Lateral de gaveta#1',1,160);__e3t(0,'Fundo de gaveta (6 mm)#1',2,450);
          var P=partsOf(g),pk=function(k){return P.filter(function(p){return p.pk===k})[0]||{}};
          R.lat=[pk('Lateral de gaveta#1').cl,pk('Lateral de gaveta#1').cw,pk('Lateral de gaveta#2').cl,pk('Lateral de gaveta#2').cw].join(',');R.fc=pk('Frente/costa de gaveta (contra-frente e traseira)#1').cw;R.fundo=pk('Fundo de gaveta (6 mm)#1').cw;R.outra=pk('Lateral de gaveta#3').cl;
          /* canto em L: peça do lado do canto muda no corte e no 3D */
          S.mods=[];newTpl(tpl('Canto L guarda-roupa · esquerdo'));var c=S.mods[0];__build();var t3=__e3t(0,'Travessa frontal (lado do canto)#1',1,200);R.trav=(partsOf(c).filter(function(p){return p.pk==='Travessa frontal (lado do canto)#1'})[0]||{}).cw;R.trav3=t3.d?Math.round(t3.d[1]):0;
          /* tamponamento com engrosso: tocar na régua de dentro seleciona o tamponamento */
          S.mods=[];newTpl(tpl('Balcão 2 portas'));__build();var rg=__boxes().filter(function(b){return b.ppk})[0];R.ppk=rg?rg.ppk:'';R.sel=rg?__e3(0,rg.ppk).part:false;
          /* forno: aparelho, não estica */
          S.mods=[];newTpl(tpl('Torre quente (forno)'));__build();R.forno=__e3(0,'Corte do forno#1').h.length;
          R.errs=__errs;return JSON.stringify(R);
          """#)
        XCTAssertEqual(o["lat"] as? String, "450,160,450,160", "as duas laterais da gaveta mudam juntas (altura e profundidade)")
        XCTAssertEqual(o["fc"] as? Int, 145, "frente/costa acompanha a altura da caixa")
        XCTAssertEqual(o["fundo"] as? Int, 450, "fundo acompanha a profundidade (corrediça de 450)")
        XCTAssertEqual(o["outra"] as? Int, 500, "as outras gavetas não mudam")
        XCTAssertEqual(o["trav"] as? Int, 200, "peça do lado do canto muda no corte")
        XCTAssertEqual(o["trav3"] as? Int, 200, "e no 3D")
        XCTAssertEqual(o["ppk"] as? String, "Tamponamento direito#1", "régua de dentro aponta pro tamponamento")
        XCTAssertEqual(o["sel"] as? Bool, true, "tamponamento selecionado")
        XCTAssertEqual(o["forno"] as? Int, 0, "forno é aparelho: sem bolinhas")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Armário alto: 3 toques põem o nicho de forno / micro-ondas e as réguas do cava (em cima e embaixo)
    func testTorreNichoDeEmbutirEReguaDoCavaEmCimaEEmbaixo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2400;S.H=2600;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Torre: marcar o pedestal desce o módulo suspenso até o chão; a prateleira de dentro arrasta pra cima e pra baixo
    func testTorrePedestalDesceAteOChaoEPrateleiraArrasta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3000;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// 3 toques no módulo: encaixar o lado de fora embaixo da pedra (pingadeira 0,5 cm, o outro lado fica) e esticar ou encurtar o móvel
    func testTresToquesEncaixaNaPedraComPingadeiraEEsticaOMovel() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Torre quente: acha pela lupa e muda forno (embutido, só nicho, sem) e micro-ondas (embutir, nicho aberto, só nicho, sem)
    func testTorreQuenteEditavelPelaLupaComNichosEMicroOndas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2400;S.H=2600;draw();var R={};
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Gaveta não encosta em cima: a folga do vão fica dividida (em cima e embaixo); se estiver apertado, 2 cm embaixo e 1,5 cm em cima,
    /// e a corrediça telescópica vai no meio da lateral da caixa
    func testGavetaComFolgaDivididaENaoEncostaEmCimaCorredicaNoMeio() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=2000;S.H=2700;
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
        XCTAssertEqual(o["folgaTopo"] as? Int, 28, "caixa de cima não encosta na travessa")
        XCTAssertEqual(o["corredica"] as? Int, 0, "corrediça no meio da lateral")
        XCTAssertEqual(o["nota"] as? Bool, true, "lista de corte diz onde vai a corrediça")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// separados por categoria, no piso e nas paredes do 3D (as juntas vêm na peça); tudo salvo no projeto
    func testCoresComPisosEPorcelanatosReaisParedesArmariosPortasEFitas() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testModoPessoaNaoAtravessaMesaCafeteiraPedrasReaisESetinhasDaPedra() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4100;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testGestosNoEletro2ToquesMudaDeLugar3ToquesConfiguracoes() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testEletroPelo3DComLupaEmCimaDaPedraMesaEParedeDoL() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;
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
        XCTAssertEqual(o["lado"] as? String, "e,200,0,610,180,880", "churrasqueira na parede da esquerda (L)")
        XCTAssertGreaterThan(o["fumaca"] as? Int ?? 0, 10, "na lateral ela também assa e solta fumaça")
        XCTAssertEqual(o["dir"] as? String, "4000,180", "e na parede da direita")
        XCTAssertEqual(o["salaCat"] as? Bool, true, "churrasqueira e eletros em qualquer ambiente")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testBotaoDoLEDUmSoOuUmPorModuloCorEMudarDeLugarCom2Toques() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=3600;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testCarneAssandoComFumacaEBotaoDoLEDLigaEDesliga() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4200;S.H=2700;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testPedraLateralIlhaRipadoZoomCantoCegoELinkRecebido() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;S.mods=[];S.fr=[];S.stones=[];S.isl=[];S.env='cozinha';S.W=4000;S.H=2700;
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
        XCTAssertEqual(o["cfg"] as? Int, 9, "⚙ abre as Configurações com 9 assuntos (Pedra entrou)")
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
        XCTAssertEqual(o["dw"] as? Double, 0, "pedra travada no 3D: o − não muda a medida (muda pela aba Pedra)")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    /// Balcão em L e U: módulos do fundo e da lateral não se sobrepõem (pingadeira de 5 mm descontada na divisão)
    func testPlacaDo3DSolidaTravaApagaAparece2DEPlanoDeCorte() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.geo=[];S.env='sala';S.room='sala';S.W=3400;S.H=2890;var a=rpNew({x:600,b:0,w:1035,h:2700});a.liso=true;draw();open3D();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testBasculanteComCavaSemEngrossoFolga4NoTopo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.env='sala';S.room='sala';S.W=3400;S.H=2890;
          newTpl({n:'Rack de TV',w:1800,h:500,d:450,b:400,keep:true,div:[1/3,2/3],v:[{k:'door',n:1},{k:'door',n:1},{k:'door',n:1}]});var m=S.mods[S.mods.length-1];
          m.v.forEach(function(v){if(v.k==='door')v.bas=1});draw();var top=function(){return Math.round(Math.max.apply(null,dbg3all().filter(function(q){return /^\d+:Porta/.test(q.nm)}).map(function(q){return q.y1})))};
          var a=top();m.regua=1;draw();var b=top();
          return JSON.stringify({sem:(m.b+m.h)-a,com:(m.b+m.h)-b,errs:__errs});
          """#)
        XCTAssertEqual(o["sem"] as? Int, 4, "basculante com cava sem engrosso: 4 mm abaixo do topo")
        XCTAssertLessThan(o["com"] as? Int ?? 99, 1, "com engrosso cava a porta sobe até o topo")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testSofaSolidoGiraSalvaExcluiEm2DE3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.fr=[];S.geo=[];S.ops=[];S.stones=[];S.env='sala';S.room='sala';S.W=4000;S.H=2800;S.RD=4000;draw();open3D();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testPortaDeVidroTelescopicaReconstroiEAbre() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.fr=[];S.ops=[];S.stones=[];S.env='sala';S.room='sala';S.W=4000;S.H=2800;draw();open3D();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testPainelNaoEntraNoVizinhoNemNaJunta() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};S.mods=[];S.rp=[];S.env='sala';S.room='sala';S.W=2600;S.H=2890;
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testBalcaoEmLSemModuloSobreposto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var R=[];[['e',3000,2000,600],['d',3000,2000,600],['u',3600,1800,600],['e',3333,1777,600],['d',4100,2650,580]].forEach(function(c){S.mods=[];S.rp=[];S.stones=[];S.fr=[];S.isl=[];S.env='cozinha';S.W=Math.max(c[1],3000);S.H=2700;draw();mkL(c[0],c[1],c[2],c[3],1);draw();
           var row=S.mods.filter(function(m){return !m.sup&&!m.wing}).sort(function(a,b){return a.x-b.x});for(var i=1;i<row.length;i++){var ov=row[i-1].x+row[i-1].w-row[i].x;if(ov>0.5)R.push(c.join('x')+': '+Math.round(ov)+' mm')}
           var st=S.stones[0];row.forEach(function(m){if(m.x<st.x+4.5||m.x+m.w>st.x+st.w-4.5)R.push(c.join('x')+': módulo sem pingadeira '+m.x+'+'+m.w)})});
          return JSON.stringify({r:R.join(' | '),errs:__errs});
          """#)
        XCTAssertEqual(o["r"] as? String, "", "módulos sobrepostos no balcão em L/U")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          var cx={base:(g('Caixote · base superior')[0]||{}).cl,vw:vw,regua:g('Caixote · régua espaçadora 40').length,trav:g('Caixote · travessa 100').length,fr:g('Frente de gaveta (caixote)').map(function(p){return p.cl})};
          S.mods=[];newTpl(find('Balcão canto cego · cego na esquerda (porta na direita)'));var c=S.mods[0];draw();var rg=partsOf(c).filter(function(p){return p.name==='Régua espaçadora do canto'})[0];
          S.mods=[];newTpl(CATS[0].it[3]);var gv=S.mods[0];gv.v[0].dt=[0];draw();var dt=partsOf(gv).filter(function(p){return /Divisor de talheres/.test(p.name)}).length;
          catOpen();await new Promise(function(r){setTimeout(r,200)});var abas=[].slice.call(document.querySelectorAll('#catsec [data-catsec]')).map(function(b){return b.dataset.catsec}).join(',');document.getElementById('catm').hidden=true;
          S.mods=[];S.fr=[];S.H=2600;open3D();await new Promise(function(r){setTimeout(r,300)});var lu=apAdd('luminaria',0),ca=apAdd('cama',1),cd=apAdd('cadesc',0);__build();var B=__boxes(),top=function(f){return Math.round(Math.max.apply(null,B.filter(function(q){return q.fr===f.id}).map(function(q){return q.y1})))},n3=function(f){return B.filter(function(q){return q.fr===f.id}).length};document.getElementById('v3x').click();
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }

    func testDescontoZeroTamponamentoPedraCooktopModo3D() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          window.MINI3OFF=1;PR.setupDone=1;var sm=document.getElementById('stdm');if(sm)sm.hidden=true;
          var tp=function(c){return CATS.filter(function(q){return q.id===c})[0].it.filter(function(i){return /2 portas/.test(i.n)})[0]};
          S.mods=[];S.stones=[];S.fr=[];S.W=3000;var sd=STD();
          sd.gDesc=0;SPC={};newTpl(CATS[0].it[3]);var g=S.mods[0];g.v.forEach(function(v){v.px='g';v.cava=false});var semDesc=partsOf(g).filter(function(p){return p.pxD}).length;sd.gDesc=35;
          S.mods=[];newTpl(tp('inf'));newTpl(tp('sup'));var mi=S.mods[0],ms=S.mods[1];mi.x=600;ms.x=600;mi.tl=ms.tl=true;ms.tlA='full';
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
        XCTAssertEqual(o["modos"] as? Int, 3, "barra Toque: Normal · Editar peça · Tamanho")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
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
          return JSON.stringify({bad:bad,mold:mold,pedra:pedra,topo:topo,errs:__errs});
          """#)
        XCTAssertEqual(o["bad"] as? Int, 0, "canto novo: os módulos encostam do lado, sem entrar um no outro")
        XCTAssertEqual(o["mold"] as? Bool, false, "balcão de canto embaixo da pedra sem moldura deitada em cima")
        XCTAssertGreaterThan(o["pedra"] as? Int ?? 0, 0, "planta em ângulo mostra a pedra depois do só o módulo")
        XCTAssertEqual(o["topo"] as? Bool, true, "quadro do cooktop por cima do 3D")
        XCTAssertEqual((o["errs"] as? [String])?.count, 0, "\(o["errs"] ?? "")")
    }
}
