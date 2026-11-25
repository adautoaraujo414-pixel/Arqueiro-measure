final class X {
    func testA31Antigo() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})},e0=__errs.length,R={};
        var puxa=async function(pk,k,px){__e3open(0,pk);await W(30);var h=document.querySelector('[data-hk="'+k+'"]'),opp={et:'eb',eb:'et'}[k],o=document.querySelector('[data-hk="'+opp+'"]');if(!h)return false;var r1_=h.getBoundingClientRect(),x=r1_.left+15,y=r1_.top+15,dx=0,dy=-1;if(o){var ro=o.getBoundingClientRect();dx=x-(ro.left+15);dy=y-(ro.top+15);var L=Math.hypot(dx,dy)||1;dx/=L;dy/=L}var ev=function(n,X,Y){var tg_=n==='pointerdown'?h:(document.querySelector('[data-hk="'+k+'"]')||document.getElementById('cv3'));tg_.dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:51,clientX:X,clientY:Y,isPrimary:true,pointerType:'touch'}))};ev('pointerdown',x,y);for(var i=1;i<=8;i++){ev('pointermove',x+dx*px/8*i,y+dy*px/8*i);await W(15)}ev('pointerup',x+dx*px,y+dy*px);await W(80);return true};
        var t=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){var q=typeof it==='number'?TPL[it]:it;if(q&&q.n==='Balcão 2 portas')t=q})});
        open3D();await W(300);loadState(initLimpo());S.env='cozinha';S.W=6000;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(t)));var m=S.mods[0];m.x=1500;draw();__build();
        var D=partsOf(m).filter(function(p){return p.name==='Rodapé (pedestal)'})[0];m.po=m.po||{};m.po[D.pk]={v2:1,et:40};/* projeto antigo: rodapé esticado do jeito de antes (só a peça) */draw();__build();
        var fot=function(){var P=partsOf(m);return 'rodMm '+m.rodMm+' · rodapé '+P.filter(function(p){return p.name==='Rodapé (pedestal)'})[0].h+' · portas '+P.filter(function(p){return /^Porta/.test(p.name)}).map(function(p){return p.cw+'x'+p.h}).join(',')+' · po rodapé '+JSON.stringify(m.po[D.pk]||null)};
        R.antes=fot();var L=partsOf(m).filter(function(p){return /^Prateleira|^Lateral esquerda/.test(p.name)})[0];R.outra=L.name;await puxa(L.pk,'ef',-20);R.depois=fot();
        document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
