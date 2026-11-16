/* Do teste testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase (falha no Chromium 1366×768): erguer o módulo e descer pelo arrasto vertical
   faz o módulo pular de lado? Rastreia quem grava m.x durante o arrasto. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
__TRACER__
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5610;S.H=3270;S.stones=[];S.mods=[];draw();
var x=200;['Balcão 2 portas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var q=S.mods[S.mods.length-1];q.x=x;x+=q.w});x=3200;['Gaveteiro 3 gavetas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var q=S.mods[S.mods.length-1];q.x=x;x+=q.w});
addStone();var m=S.mods[3];draw();S.m=m;S.tab=0;draw();panel();await W(100);
var sv=document.getElementById('svg');var ev=function(t,X,Y,el){(el||document.elementFromPoint(X,Y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:X,clientY:Y,pointerId:7,isPrimary:true,pointerType:'touch'}))};
var gm=function(){return [].filter.call(sv.querySelectorAll('#mod'),function(q){return +q.dataset.mi===3})[0]};
var trilha=[];var arr=async function(X,Y,dx,dy){ev('pointerdown',X,Y);for(var k=1;k<=8;k++){ev('pointermove',X+dx*k/8,Y+dy*k/8,sv);ev('pointermove',X+dx*k/8,Y+dy*k/8,window);trilha.push('x'+m.x+' b'+(+m.b||0))}ev('pointerup',X+dx,Y+dy,sv);ev('pointerup',X+dx,Y+dy,window);await W(80);draw();trilha.push('solto x'+m.x+' b'+(+m.b||0))};
R.vizinhos=S.mods.map(function(q,i){return i+': x'+q.x+'–'+(q.x+q.w)+' b'+(+q.b||0)+' h'+q.h}).join(' | ');R.pedra=S.stones.map(function(s){return 'x'+s.x+' w'+s.w}).join(' ');
[-90,-60,-30].forEach(function(){});
var bx=gm().querySelector('rect[data-mi]').getBoundingClientRect();bx.top<0&&gm().scrollIntoView({block:'center'});bx=gm().querySelector('rect[data-mi]').getBoundingClientRect();
hookAll();TR.log={};TR.on=true;await arr(bx.left+bx.width*0.6,bx.top+bx.height*0.5,0,-90);TR.on=false;R.quemGravouAoSubir=Object.keys(TR.log).filter(function(k){return /mod\.x /.test(k)}).map(function(k){return k+' '+TR.log[k].ex});R.ergueu='x'+m.x+' b'+(+m.b||0);R.trilhaSobe=trilha.slice();trilha=[];
hookAll();TR.log={};TR.on=true;bx=gm().querySelector('rect[data-mi]').getBoundingClientRect();await arr(bx.left+bx.width*0.6,bx.top+bx.height*0.5,0,400);TR.on=false;
R.desceu='x'+m.x+' b'+(+m.b||0);R.trilhaDesce=trilha;R.quemGravou=Object.keys(TR.log).filter(function(k){return /mod\.(x|b) /.test(k)}).map(function(k){return k+' '+TR.log[k].ex+' ×'+TR.log[k].n});
return JSON.stringify(R);
