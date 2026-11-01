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
        await fulfillment(of: [ready], timeout: 30)
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
          PR.setupDone=1;S.mods=[];newTpl(3);newTpl(2);newTpl(4);draw();
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
          PR.setupDone=1;S.mods=[];newTpl(3);newTpl(4);draw();S.preco=1234;
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
          PR.setupDone=1;S.mods=[];newTpl(3);draw();var m=S.mods[0];
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
          PR.setupDone=1;S.tab=9;panel();document.querySelector('[data-room="sala"]').click();
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
          PR.setupDone=1;S.mods=[];newTpl(3);newTpl(4);draw();pxApplyAll('g','dourado');
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
          PR.setupDone=1;function nm(q){return catFind(q).reduce(function(a,g){return a.concat(g.it.map(function(r){return r.it.n}))},[])}
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

    func testConfiguracoesCorredicaOcultaConchaECorteAvulso() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
          PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[3]);draw();var m=S.mods[0];
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
          PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[0].it[3]);S.m=S.mods[0];draw();
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
          PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];S.st.items.push({id:77,k:'cook',x:1500,y:60,w:600,d:500});apAdd('torneira',0);draw();
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
          PR.setupDone=1;S.mods=[];newTpl(CATS[1].it[2]);var m=S.mods[0];m.regua=true;m.regN=2;m.tl=true;m.tlA='tamp';m.tr=true;m.trA='cava';m.tb=true;m.tpass=false;draw();
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
          PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);S.fr=[];var g=apAdd('geladeira',2),t=apAdd('torneira',0),v=apAdd('tv',1);draw();
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
          PR.setupDone=1;S.mods=[];newTpl(CATS[0].it[0]);newTpl(CATS[1].it[2]);S.m=S.mods[0];draw();
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
}
