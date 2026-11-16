window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var st=function(m){return 'x='+Math.round(m.x*10)/10+' tl='+(m.tl?1:0)+(m.tlAuto?'a':'')+' tr='+(m.tr?1:0)+(m.trAuto?'a':'')};
var svg=document.getElementById('svg'),pe=function(t,el,x,y){el.dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:1,isPrimary:true,pointerType:'touch'}))};
/* arrasta o módulo 0 pelo dedo até a posição alvo (mm), em passos pequenos, como a mão faz */
var drag=async function(alvo){var m=S.mods[0],rc=document.querySelector('#mod[data-mi="0"] rect[data-mi]').getBoundingClientRect(),cpm=rc.width/m.w,x=rc.left+rc.width*.5,y=rc.top+rc.height*.6,el=document.elementFromPoint(x,y);if(!el||!el.closest('#mod'))el=document.querySelector('#mod[data-mi="0"] rect[data-mi]');
  var dx=(alvo-m.x)*cpm;var tx=dx+(dx>0?6.5:-6.5);pe('pointerdown',el,x,y);await W(20);for(var i=1;i<=8;i++){pe('pointermove',svg,x+tx*i/8,y);await W(14)}await W(30);pe('pointerup',svg,x+tx,y);await W(150)};
var cena=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;draw();newTpl(T('Balcão 2 portas'));draw();if(window.SOLO2)soloOff();var m=S.mods[0];m.x=800;draw();S.m=m;S.tab=0;panel();draw();return m};
var seq=[800,5,800,5,45,25,5,25,0,800];
var out=[];var m=cena();await W(300);out.push('início '+st(m));
for(var i=0;i<seq.length;i++){await drag(seq[i]);m=S.mods[0];out.push('arrastou pra '+seq[i]+' → '+st(m))}
R.arrasto=out;
/* mesma entrada, dois começos: chega em 25 vindo de 800 ou vindo de 0 */
var r2=[];m=cena();await drag(25);r2.push('de 800 pra 25 → '+st(S.mods[0]));m=cena();await drag(0);await drag(25);r2.push('de 0 pra 25 → '+st(S.mods[0]));R.mesmaEntrada=r2;
/* vão: módulo sem tamponamento esquerdo e x>5 junto da parede */
m=S.mods[0];R.vaoNaParede=(m.tl?0:Math.round(m.x))+' mm entre a parede e o módulo (sem tamponamento)';
return JSON.stringify(R);
