final class X {
    func testC2Caminhos() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length,W=function(t){return new Promise(function(r){setTimeout(r,t)})};
        var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(!r&&t&&!t.act&&t.n===n)r=t})});return JSON.parse(JSON.stringify(r))};
        var svg=document.getElementById('svg'),pe=function(t,el,x,y){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:1,isPrimary:true,pointerType:'mouse',buttons:t==='pointerup'?0:1}))};
        var med=function(){return S.mods.map(function(m){return [m.w,m.h,m.d].join('x')}).join(' ')},sob=function(){for(var i=0;i<S.mods.length;i++)for(var j=i+1;j<S.mods.length;j++)if(modOv(S.mods[i],S.mods[j]))return i+'×'+j;return 'nenhuma'};
        var arrasta=async function(mi,dxmm,dymm){if(S.mods[mi]!==S.m){S.m=S.mods[mi];draw();panel();await W(60)}var rc=document.querySelector('#mod[data-mi="'+mi+'"] rect[data-mi]').getBoundingClientRect(),x=rc.left+rc.width/2,y=rc.top+rc.height*.6,el=document.elementFromPoint(x,y),k=rc.width/S.mods[mi].w,sb='nenhuma';pe('pointerdown',el,x,y);await W(30);for(var i=1;i<=10;i++){pe('pointermove',svg,x+dxmm*k*i/10,y-dymm*k*i/10);await W(20);var s_=sob();if(s_!=='nenhuma')sb=s_}pe('pointerup',svg,x+dxmm*k,y-dymm*k);await W(300);return sb};
        var puxa=async function(pk,k,px){__e3open(0,pk);await W(30);var h=document.querySelector('[data-hk="'+k+'"]'),opp={et:'eb',eb:'et'}[k],o=document.querySelector('[data-hk="'+opp+'"]');if(!h)return false;var r1_=h.getBoundingClientRect(),x=r1_.left+15,y=r1_.top+15,dx=0,dy=-1;if(o){var ro=o.getBoundingClientRect();dx=x-(ro.left+15);dy=y-(ro.top+15);var L=Math.hypot(dx,dy)||1;dx/=L;dy/=L}var ev=function(n,X,Y){var tg_=n==='pointerdown'?h:(document.querySelector('[data-hk="'+k+'"]')||document.getElementById('cv3'));tg_.dispatchEvent(new PointerEvent(n,{bubbles:true,cancelable:true,pointerId:51,clientX:X,clientY:Y,isPrimary:true,pointerType:'touch'}))};ev('pointerdown',x,y);for(var i=1;i<=8;i++){ev('pointermove',x+dx*px/8*i,y+dy*px/8*i);await W(15)}ev('pointerup',x+dx*px,y+dy*px);await W(80);return true};
        var T2=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(!r&&t&&!t.act&&t.n===n)r=t})});return JSON.parse(JSON.stringify(r))};
        /* 1) régua do aéreo canto cego: seta et puxada pra baixo até o limite */
        open3D();await W(300);var reg=[];['Aéreo canto cego · cego na direita','Aéreo canto cego · cego na esquerda'].forEach(function(){});
        for(var q=0;q<2;q++){var nm=['Aéreo canto cego · cego na direita','Aéreo canto cego · cego na esquerda'][q];for(var px=-200;px>=-1400;px-=600){loadState(initLimpo());S.env='cozinha';S.W=6000;S.H=2700;draw();newTpl(T2(nm));var m=S.mods[0];m.x=1500;draw();__build();var Rg=partsOf(m).filter(function(p){return /^Régua espaçadora do canto/.test(p.name)})[0];await puxa(Rg.pk,'et',px);var R1=partsOf(m).filter(function(p){return p.pk===Rg.pk})[0];reg.push(nm.slice(-8)+' et '+px+'px: y '+R1.y+' h '+R1.h+' topo '+(R1.y+R1.h)+' / m.h '+m.h+' passa '+Math.max(0,R1.y+R1.h-m.h))}}
        document.getElementById('v3x').click();R.regua=reg.join(' | ');
        /* 2) arrasto do balcão pro canto L do guarda-roupa */
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5000;S.H=2700;draw();newTpl(T2('Canto L guarda-roupa · esquerdo'));newTpl(T2('Balcão 2 portas'));var c=S.mods[0],b=S.mods[1];b.x=2500;S.m=null;draw();await W(100);var cr=JSON.stringify([c.x,c.w,c.d,c.cw2]);var dur=await arrasta(1,-2400,0);
        var ov=function(a,o){var ea=extOf(a),eo=extOf(o);return ea[0]<eo[1]-1&&eo[0]<ea[1]-1&&(+a.b||0)<(+o.b||0)+(+o.h)-1&&(+o.b||0)<(+a.b||0)+(+a.h)-1};
        R.arrasto='canto '+Math.round(c.x)+'..'+Math.round(c.x+c.w)+' (cw2 '+c.cw2+', d '+c.d+') · balcão '+Math.round(b.x)+'..'+Math.round(b.x+b.w)+' · faixa da largura e altura se cruzam '+ov(b,c)+' · modOv '+modOv(b,c)+' · canto '+(JSON.stringify([c.x,c.w,c.d,c.cw2])===cr?'parado':'mexeu');
        R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
