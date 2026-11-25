final class X {
    func testArrCanto() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length,W=function(t){return new Promise(function(r){setTimeout(r,t)})};
        var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(!r&&t&&!t.act&&t.n===n)r=t})});return JSON.parse(JSON.stringify(r))};
        var svg=document.getElementById('svg'),pe=function(t,el,x,y){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:1,isPrimary:true,pointerType:'mouse',buttons:t==='pointerup'?0:1}))};
        var med=function(){return S.mods.map(function(m){return [m.w,m.h,m.d].join('x')}).join(' ')},sob=function(){for(var i=0;i<S.mods.length;i++)for(var j=i+1;j<S.mods.length;j++)if(modOv(S.mods[i],S.mods[j]))return i+'×'+j;return 'nenhuma'};
        var arrasta=async function(mi,dxmm,dymm){if(S.mods[mi]!==S.m){S.m=S.mods[mi];draw();panel();await W(60)}var rc=document.querySelector('#mod[data-mi="'+mi+'"] rect[data-mi]').getBoundingClientRect(),x=rc.left+rc.width/2,y=rc.top+rc.height*.6,el=document.elementFromPoint(x,y),k=rc.width/S.mods[mi].w,sb='nenhuma';pe('pointerdown',el,x,y);await W(30);for(var i=1;i<=10;i++){pe('pointermove',svg,x+dxmm*k*i/10,y-dymm*k*i/10);await W(20);var s_=sob();if(s_!=='nenhuma')sb=s_}pe('pointerup',svg,x+dxmm*k,y-dymm*k);await W(300);return sb};
        var res=[];
        var CN=['Canto em L (aéreo) · esquerdo','Canto em L (aéreo) · direito','Canto L guarda-roupa · esquerdo','Canto L guarda-roupa · direito','Balcão canto cego · cego na esquerda (porta na direita)'],VZ=['Aéreo 2 portas','Aéreo 2 portas','Guarda-roupa 2 vãos','Guarda-roupa 2 vãos','Balcão 2 portas'];
        for(var f=0;f<CN.length;f++){var dir=/direito/.test(CN[f]);
          /* A) parede normal: arrasta o vizinho com força pra dentro do canto */
          loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T(CN[f]));newTpl(T(VZ[f]));var c=S.mods[0],v=S.mods[1];if(dir){c.x=S.W-c.w;v.x=c.x-v.w-600}else{c.x=0;v.x=c.w+600}S.m=null;draw();await W(100);var m0=med(),cx0=c.x,cr0=JSON.stringify([c.x,c.w,c.corner||'']);var d1=await arrasta(1,dir?2500:-2500,0);
          res.push(CN[f]+' A: durante '+d1+' · fim '+sob()+' · medidas '+(med()===m0?'iguais':'MUDARAM '+med())+' · canto '+(JSON.stringify([c.x,c.w,c.corner||''])===cr0?'parado':'MEXEU')+' · vizinho x '+Math.round(v.x)+' canto '+Math.round(c.x)+'..'+Math.round(c.x+c.w));
          /* B) parede encolhida: o vizinho fica fora e é arrastado pro lado do canto */
          loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T(CN[f]));newTpl(T(VZ[f]));c=S.mods[0];v=S.mods[1];if(dir){c.x=S.W-c.w;v.x=c.x-v.w-600}else{c.x=0;v.x=c.w+600}S.m=null;draw();await W(100);m0=med();cr0=JSON.stringify([c.x,c.w,c.corner||'']);S.W=Math.round(c.w*1.2);draw();await W(80);var d2=await arrasta(1,dir?300:-300,0);
          res.push(CN[f]+' B: durante '+d2+' · fim '+sob()+' · medidas '+(med()===m0?'iguais':'MUDARAM '+med())+' · canto '+(JSON.stringify([c.x,c.w,c.corner||''])===cr0?'parado':'MEXEU'))}
        R.res=res.join(' | ');R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
