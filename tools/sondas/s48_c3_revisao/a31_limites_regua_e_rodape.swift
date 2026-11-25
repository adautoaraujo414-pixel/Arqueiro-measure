final class X {
    func testA31Lim() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})},e0=__errs.length,R={};
        var puxa=async function(pk,k,px){__e3open(0,pk);await W(30);var h=document.querySelector('[data-hk="'+k+'"]'),opp={et:'eb',eb:'et'}[k],o=document.querySelector('[data-hk="'+opp+'"]');if(!h)return false;var r1_=h.getBoundingClientRect(),x=r1_.left+15,y=r1_.top+15,dx=0,dy=-1;if(o){var ro=o.getBoundingClientRect();dx=x-(ro.left+15);dy=y-(ro.top+15);var L=Math.hypot(dx,dy)||1;dx/=L;dy/=L}var ev=function(n,X,Y){var tg_=n==='pointerdown'?h:(document.querySelector('[data-hk="'+k+'"]')||document.getElementById('cv3'));tg_.dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:51,clientX:X,clientY:Y,isPrimary:true,pointerType:'touch'}))};ev('pointerdown',x,y);for(var i=1;i<=8;i++){ev('pointermove',x+dx*px/8*i,y+dy*px/8*i);await W(15)}ev('pointerup',x+dx*px,y+dy*px);await W(80);return true};
        var dentro=function(){__build();var B=__boxes().filter(function(b){return b.nm&&/^0:/.test(b.nm)&&!b.ft&&b.g!=='sh'&&b.g!=='lo'}),bad='';B.forEach(function(a){if(bad||!/^0:(Rodapé \(pedestal\)|Régua espaçadora)/.test(a.nm))return;B.forEach(function(b){if(bad||a===b||/^0:(Rodapé|Régua espaçadora|Tamponamento|Corte do|Pé )/.test(b.nm))return;if(Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0)>1&&Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0)>1&&Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0)>1)bad=a.nm+' em '+b.nm})});return bad};
        var mods=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(t&&!t.act&&t.n&&mods.every(function(q){return q.n!==t.n}))mods.push(t)})});
        open3D();await W(300);var reg=[],rod=[];
        for(var i=0;i<mods.length;i++){var t=JSON.parse(JSON.stringify(mods[i]));
          for(var kk=0;kk<2;kk++){var k=['et','eb'][kk];loadState(initLimpo());S.env='cozinha';S.W=6000;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(t)));var m=S.mods[0];if(!m)continue;m.x=1500;draw();__build();
          var Rg=partsOf(m).filter(function(p){return /^Régua espaçadora do canto/.test(p.name)})[0];if(!Rg)break;
          await puxa(Rg.pk,k,300);var R1=partsOf(m).filter(function(p){return p.pk===Rg.pk})[0];var B=__boxes().filter(function(b){return String(b.nm).indexOf('0:Régua espaçadora')===0}),bb=B.reduce(function(a,b){return [Math.min(a[0],b.y0),Math.max(a[1],b.y1)]},[1e9,-1e9]),mb=__boxes().filter(function(b){return /^0:(Lateral|Base|Tampo)/.test(b.nm)}).reduce(function(a,b){return [Math.min(a[0],b.y0),Math.max(a[1],b.y1)]},[1e9,-1e9]);
          reg.push(t.n+' '+k+': h '+Rg.h+'→'+(R1&&R1.h)+' · y '+(R1&&R1.y)+' · m.h '+m.h+' · 3D régua '+bb.map(Math.round)+' caixa '+mb.map(Math.round)+' · passa '+Math.round(Math.max(0,bb[1]-mb[1],mb[0]-bb[0]))+' · '+(dentro()||'sem entrar'))}
          if(/Gaveteiro|gaveta/i.test(t.n)&&!/torre|Torre|Armário|Guarda/.test(t.n)){loadState(initLimpo());S.env='cozinha';S.W=6000;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(t)));var m=S.mods[0];if(!m)continue;m.x=1500;draw();__build();var D=partsOf(m).filter(function(p){return p.name==='Rodapé (pedestal)'})[0];if(!D)continue;
            var fr=function(){return partsOf(m).filter(function(p){return /^Frente de gaveta|^Lateral de gaveta/.test(p.name)}).map(function(p){return p.name.replace(/ de gaveta/,'')+' '+p.h}).join(',')};var f0=fr(),r0=m.rodMm;await puxa(D.pk,'et',600);rod.push(t.n+': rodMm '+r0+'→'+m.rodMm+' (m.h '+m.h+') · gavetas '+f0+' → '+fr()+' · '+(dentro()||'sem entrar'))}}
        document.getElementById('v3x').click();R.reg=reg.join(' | ');R.rod=rod.join(' | ');R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
