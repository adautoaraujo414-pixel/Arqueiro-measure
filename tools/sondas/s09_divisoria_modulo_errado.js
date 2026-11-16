window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var all=TPL.concat(CATS.flatMap(function(c){return c.it})),T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
var sv=document.getElementById('svg');
var ev=function(t,x,y,el){(el||document.elementFromPoint(x,y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:5,isPrimary:true,pointerType:'touch',buttons:t==='pointerup'?0:1}))};
var R={};var res=[];
for(var tab of [0,1]){
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 2 portas'));draw();if(window.SOLO2)soloOff();
var A=S.mods[0],B=S.mods[1];A.x=35;B.x=A.x+A.w+400;A.div=[0.5];B.div=[0.5];A.v=[{k:'door',n:1},{k:'door',n:1}];B.v=[{k:'door',n:1},{k:'door',n:1}];draw();S.m=A;S.tab=tab;panel();draw();await W(200);
var a0=A.div[0],b0=B.div[0];
var hs=[].slice.call(sv.querySelectorAll('[data-d="0"]')).map(function(c){var b=c.getBoundingClientRect();return {c:c,x:b.left+b.width/2,y:b.top+b.height/2}}).filter(function(o){return o.x>0}).sort(function(p,q){return q.x-p.x});
if(!hs.length){res.push('aba '+tab+': sem alça de divisória na tela');continue}
var h=hs[0];/* a de maior x = divisória do módulo B (não escolhido) */
var x=h.x,y=h.y;ev('pointerdown',x,y);for(var k=1;k<=6;k++){ev('pointermove',x+k*8,y,sv);ev('pointermove',x+k*8,y,window);await W(16)}ev('pointerup',x+48,y,sv);ev('pointerup',x+48,y,window);await W(500);draw();
res.push('aba '+tab+': alças na tela '+hs.length+' · escolhido '+S.mods.indexOf(S.m)+' · A.div '+a0+'→'+S.mods[0].div[0]+' · B.div '+b0+'→'+S.mods[1].div[0])}
R.casos=res;return JSON.stringify(R);
