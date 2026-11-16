/* Escolha de peça que fica de um projeto pro outro: no projeto A a pessoa toca numa divisória (o 2D marca LAST='div' e DIVI).
   Abre o projeto B na mesma página e toca no 🗑 (#delMod). O 🗑 não pode apagar a divisória do módulo do B que ninguém tocou. */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var sv=document.getElementById('svg');
var ev=function(t,x,y,el){(el||document.elementFromPoint(x,y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:5,isPrimary:true,pointerType:'touch',buttons:t==='pointerup'?0:1}))};
var mk=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;draw();newTpl(T('Balcão 2 portas'));draw();if(window.SOLO2)soloOff();var m=S.mods[0];m.x=35;m.div=[0.5];m.v=[{k:'door',n:1},{k:'door',n:1}];draw();S.m=m;S.tab=0;panel();draw();return JSON.parse(JSON.stringify(snapState()))};
var B=mk();var A=mk();
/* em A: toque (sem arrastar) na divisória */
var c=sv.querySelector('[data-d="0"]'),b=c.getBoundingClientRect(),x=b.left+b.width/2,y=b.top+b.height/2;ev('pointerdown',x,y);ev('pointerup',x,y,sv);ev('pointerup',x,y,window);await W(500);
var R={A_LAST:window.LAST,A_DIVI:window.DIVI};
/* abre B como na lista do editor e toca no 🗑 */
loadState(JSON.parse(JSON.stringify(B)));draw();S.m=S.mods[0];draw();await W(300);R.B_LAST=window.LAST;R.B_DIVI=window.DIVI;var d0=JSON.stringify(S.mods[0].div);
window.__delConfirma=1;var del=document.getElementById('delMod');if(del){del.click();await W(150);del.click();await W(300)}window.__delConfirma=0;
R.B_div_antes=d0;R.B_div_depois=S.mods[0]?JSON.stringify(S.mods[0].div):'(módulo apagado)';R.B_modulos=S.mods.length;R.avisos=TL.slice(-3);
return JSON.stringify(R);
