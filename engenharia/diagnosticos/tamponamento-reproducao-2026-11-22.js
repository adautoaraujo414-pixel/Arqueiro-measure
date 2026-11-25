PR.setupDone=1;window.MINI3OFF=1;window.toast=function(){};var o={},W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};var T=function(n){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n)it=t})});return JSON.parse(JSON.stringify(it))};
var est=function(f){return 'tl='+!!f.tl+(f.tlAuto?' (auto)':'')+' tr='+!!f.tr+(f.trAuto?' (auto)':'')};
var junta=function(e,d){var g=(d.x-lt(d))-(e.x+e.w+rt(e));return 'folga '+Math.round(g)+' mm · tamp entre: '+((e.tr&&rt(e)>0)||(d.tl&&lt(d)>0))};
/* 1a catálogo: aberto, depois forno */
S.mods=[];S.stones=[];S.W=3600;draw();newTpl(T('Balcão aberto (prateleira)'));newTpl(T('Balcão forno embutido'));var a=S.mods[0],f=S.mods[1];o.catalogo_abertoDepoisForno=est(f)+' · '+junta(a,f);
/* 1b catálogo: forno encostado na parede direita, depois aberto (vai pra esquerda dele) */
S.mods=[];draw();newTpl(T('Balcão forno embutido'));f=S.mods[0];f.x=S.W-f.w-rt(f);draw();var fAntes=est(f);newTpl(T('Balcão aberto (prateleira)'));a=S.mods[1];draw();o.catalogo_fornoNaParedeDepoisAberto='forno antes: '+fAntes+' · depois: '+est(f)+' · aberto x '+a.x+' · '+(a.x<f.x?junta(a,f):'aberto foi pra direita');
/* 2 arraste 2D pelo dedo: forno sozinho no meio (auto dos 2 lados), aberto longe à esquerda, arrasta até encostar */
S.mods=[];draw();newTpl(T('Balcão forno embutido'));f=S.mods[0];f.x=1800;draw();newTpl(T('Balcão aberto (prateleira)'));a=S.mods[1];a.x=200;draw();var fA=est(f);S.m=a;draw();
var sv=document.getElementById('svg'),r=sv.querySelector('rect[data-mi="1"]'),k=(+r.getAttribute('width'))/a.w,ctm=r.getScreenCTM(),bb=r.getBoundingClientRect(),p0={x:bb.left+bb.width/2,y:bb.top+bb.height*0.4};
var alvoX=f.x-lt(f)-a.w-rt(a),dmm=alvoX-a.x+3,dpx=dmm*k*ctm.a;var ev=function(t,p){return new PointerEvent(t,{bubbles:true,cancelable:true,pointerId:3,clientX:p.x,clientY:p.y,isPrimary:true,pointerType:'mouse',button:0,buttons:1})};
var el=document.elementFromPoint(p0.x,p0.y);el.dispatchEvent(ev('pointerdown',p0));for(var i=1;i<=10;i++){document.dispatchEvent(ev('pointermove',{x:p0.x+dpx*i/10,y:p0.y}));sv.dispatchEvent(ev('pointermove',{x:p0.x+dpx*i/10,y:p0.y}));await W(20)}sv.dispatchEvent(ev('pointerup',{x:p0.x+dpx,y:p0.y}));document.dispatchEvent(ev('pointerup',{x:p0.x+dpx,y:p0.y}));await W(200);draw();
o.arraste2D='forno antes: '+fA+' · depois: '+est(f)+' · aberto x '+a.x+' (alvo '+Math.round(alvoX)+') · '+junta(a,f);
/* 3 arraste 3D: solta o aberto, leva pra perto do forno e encaixa na parede do fundo */
S.mods=[];draw();newTpl(T('Balcão forno embutido'));f=S.mods[0];f.x=1800;draw();newTpl(T('Balcão aberto (prateleira)'));a=S.mods[1];a.x=200;draw();fA=est(f);
lvSolta(a);a.rot=0;a.lx=f.x-lt(f)-a.w-rt(a)-2;a.lz=8;draw();var res=__mv3.encaixa(a);draw();o.arraste3D='forno antes: '+fA+' · depois: '+est(f)+' · encaixa: '+JSON.stringify(res)+' · aberto wing='+(a.wing||'fundo')+' x '+a.x+' · '+(!a.wing?junta(a,f):'');
return JSON.stringify(o,null,1);
PR.setupDone=1;window.MINI3OFF=1;window.toast=function(){};var o={};var T=function(n){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n)it=t})});return JSON.parse(JSON.stringify(it))};
var est=function(f){return 'tl='+!!f.tl+(f.tlAuto?' (auto)':'')+' tr='+!!f.tr+(f.trAuto?' (auto)':'')};
S.mods=[];S.stones=[];S.W=3600;draw();newTpl(T('Balcão forno embutido'));var f=S.mods[0];f.x=1800;draw();newTpl(T('Balcão aberto (prateleira)'));var a=S.mods[1];a.x=200;draw();var fA=est(f);
lvSolta(a);a.rot=0;var tries=[];[0,10,20,30,40,60].forEach(function(g){if(a.wing!=='L')return;a.lx=f.x-lt(f)-a.w-g;a.lz=10;draw();var r=__mv3.encaixa(a);draw();tries.push(g+':'+(a.wing==='L'?'não':'encaixou x'+a.x))});
o.tentativas=tries.join(' · ');o.forno='antes '+fA+' · depois '+est(f);o.aberto={wing:a.wing||'fundo',x:a.x,tr:a.tr,trAuto:a.trAuto,rt:rt(a)};o.folga=a.wing?'-':Math.round((f.x-lt(f))-(a.x+a.w+rt(a)));o.tampEntre=!a.wing&&((f.tl&&lt(f)>0)||(a.tr&&rt(a)>0));return JSON.stringify(o,null,1);
