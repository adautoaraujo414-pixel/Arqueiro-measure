final class X {
    func testLibVz() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
window.MINI3OFF=1;PR.setupDone=1;var R={},svg=document.getElementById('svg'),pe=function(t,el,x,y){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:1,isPrimary:true,pointerType:'mouse',buttons:t==='pointerup'?0:1}))},sob=function(){return 'x'},e0=__errs.length,W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},msgs=[],tw=window.toast;window.toast=function(t){if(tw(t)!=='mudo')msgs.push(String(t))};
        /* JSON canônico (chaves em ordem): o conteúdo tem que ser idêntico; a ordem das chaves no objeto não é conteúdo */var CJ=function(v){return JSON.stringify(v,function(k,x){return x&&typeof x==='object'&&!Array.isArray(x)?Object.keys(x).sort().reduce(function(o,kk){o[kk]=x[kk];return o},{}):x})};
        var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!r&&t&&!t.act&&t.n===n)r=t})});return JSON.parse(JSON.stringify(r))};
        var cena=function(W_,lista){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=W_;S.H=2700;S.mods=[];draw();lista.forEach(function(b){S.m=S.mods[S.mods.length-1]||null;newTpl(T(b));draw()});var q=document.getElementById('fitq');if(q)q.hidden=true;msgs=[];/* identidade (D23) é dada na hora em que alguém pede; aqui já antes de guardar o JSON de comparação */S.mods.forEach(function(m){modUid(m,true)});draw();return S.mods.map(function(m){return CJ(m)})};
        var iguais=function(J){return J.every(function(j,k){return S.mods[k]&&CJ(S.mods[k])===j})};
        var perg=function(){var q=document.getElementById('fitq');return q&&!q.hidden?q:null};
        var botoes=function(q){return q?[].map.call(q.querySelectorAll('button'),function(b){return b.textContent.trim()}).join(' / '):'sem pergunta'};
        var d=function(m){return m?Math.round(m.x)+'+'+Math.round(m.w)+'@'+(+m.b||0):'-'};
        var arrasta=async function(mi,dxmm,dymm){if(S.mods[mi]!==S.m){S.m=S.mods[mi];draw();panel();await W(60)}var rc=document.querySelector('#mod[data-mi="'+mi+'"] rect[data-mi]').getBoundingClientRect(),x=rc.left+rc.width/2,y=rc.top+rc.height*.6,el=document.elementFromPoint(x,y),k=rc.width/S.mods[mi].w,sb='nenhuma';pe('pointerdown',el,x,y);await W(30);for(var i=1;i<=10;i++){pe('pointermove',svg,x+dxmm*k*i/10,y-dymm*k*i/10);await W(20);var s_=sob();if(s_!=='nenhuma')sb=s_}pe('pointerup',svg,x+dxmm*k,y-dymm*k);await W(300);return sb};
        var AER=['Balcão 2 portas','Balcão da pia (cuba)','Aéreo 2 portas','Aéreo 2 portas'];
        var DD=function(x,y,p,o){o=o||[];if(JSON.stringify(x)===JSON.stringify(y))return o;if(x&&y&&typeof x==='object'&&typeof y==='object'){Object.keys(x).concat(Object.keys(y)).filter(function(k,i,a){return a.indexOf(k)===i}).forEach(function(k){DD(x[k],y[k],p+'.'+k,o)})}else o.push(p+'='+JSON.stringify(x)+'→'+JSON.stringify(y));return o};
        var SN=function(){return JSON.parse(JSON.stringify(snapState()))},df=function(a,b){var o=DD(a,b,'');return o.length?o.slice(0,12).join(' ; ')+(o.length>12?' …(+'+(o.length-12)+')':''):'igual'};
        var undoN=function(){try{return (window.UNDO||window.undoStack||window.H||[]).length}catch(_){return '?'}};
        /* B) catálogo: Cancelar */
        var J=cena(3000,AER),s1=SN();S.m=S.mods[1];newTpl(T('Aéreo 2 portas'));await W(80);var q=perg();R.b0_botoes=botoes(q);var b=q&&q.querySelector('[data-fitq="nao"]');if(b)b.click();await W(150);R.b1_cancelar=df(s1,SN());
        /* D) medida: Cancelar (na base: só o aviso) */
        J=cena(2000,['Balcão 2 portas','Balcão 2 portas']);s1=SN();S.m=S.mods[0];setv('w',1400);await W(60);q=perg();R.d0_botoes=botoes(q);b=q&&q.querySelector('[data-fitq="nao"]');if(b)b.click();await W(80);R.d1_medidaCancelar=df(s1,SN());
        /* A) colocar, arrastar o novo, desfazer */
        J=cena(3000,AER);var s0=SN();S.m=S.mods[1];newTpl(T('Aéreo 2 portas'));await W(80);b=perg()&&perg().querySelector('[data-fitqf]');if(b){b.click();await W(150);var n=S.mods[J.length];var s2=SN();R.a1_colocou=d(n)+' · vizinhos (só eles) '+df(s0.mods,s2.mods.slice(0,J.length));
          await arrasta(J.length,-150,0);await W(200);q=perg();if(q){R.a2_pergunta=botoes(q)}var s3=SN();R.a2_arrastou=d(S.mods[J.length])+' · vizinhos '+df(s2.mods.slice(0,J.length),s3.mods.slice(0,J.length));
          var cnt=[];for(var u=0;u<4;u++){document.getElementById('und').click();await W(120);cnt.push(S.mods.length)}R.a3_desfaz=cnt.join(',')+' · vs antes de colocar '+df(s0.mods,SN().mods.slice(0,J.length))}else R.a1_colocou='sem botão (base)';
        R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
