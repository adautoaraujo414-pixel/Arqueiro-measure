/* Fase 2 · seleção: "portas ocupando o móvel inteiro quando só o vão de cima foi escolhido".
   Em cada modelo do catálogo cujo vão tem partes internas (forno, micro-ondas, tempero, geladeira), toca de verdade na porta de cima no 2D e usa os caminhos do app
   pra trocar a porta (aba Portas: 1 e 2 portas; 2 toques no vão: menu rápido "1 porta"). Certo: só a porta de cima muda; o forno/micro/nicho/geladeira continuam
   e nenhuma porta passa da altura que a porta de cima tinha. */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={modelos:{}};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h&&(it.v||[]).some(function(v){return /oven|tempero|gel/.test(v.k)}))its.push(it)})});
var sv=document.getElementById('svg');
var ev=function(t,x,y,el){(el||document.elementFromPoint(x,y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:5,isPrimary:true,pointerType:'touch',buttons:t==='pointerup'?0:1}))};
var portas=function(m){return partsOf(m).filter(function(p){return /^(Porta|Frente)/.test(p.name)&&!/gaveta/i.test(p.name)}).map(function(p){return {n:p.name,y:Math.round(p.y),h:Math.round(p.h),t:Math.round(p.y+p.h)}})};
var eletro=function(m){return (m.v||[]).map(function(v){return v.k}).join(',')+' · '+partsOf(m).filter(function(p){return /forno|micro|Nicho|geladeira|Forno|Micro/i.test(p.name)}).length+' peça(s) de forno/micro/nicho'};
var cena=function(it){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];m.x=1500;S.m=m;S.sv=0;S.tab=0;draw();panel();return JSON.stringify(snapState())};
var tocaPortaDeCima=async function(m){var P=partsOf(m),best=-1,top=-1;P.forEach(function(p,i){if(/^Porta/.test(p.name)&&p.y+p.h>top){top=p.y+p.h;best=i}});if(best<0)return null;var r=sv.querySelector('#mod[data-mi="0"] rect[data-p="'+best+'"]');if(!r)return null;var b=r.getBoundingClientRect(),x=b.left+b.width/2,y=b.top+b.height/2;ev('pointerdown',x,y,r);ev('pointerup',x,y,sv);ev('pointerup',x,y,window);await W(500);return P[best]};
draw();
for(var i=0;i<its.length;i++){var it=its[i],res={};
 for(var cam of ['aba Portas · 1 porta','aba Portas · 2 portas','2 toques · menu 1 porta']){var base=cena(it),m=S.mods[0],p0=portas(m),e0=eletro(m),alvo=await tocaPortaDeCima(m);if(!alvo){res[cam]='sem porta de cima no desenho';continue}
  var altoAntes=Math.round(alvo.y+alvo.h)-Math.round(alvo.y);
  if(/aba Portas/.test(cam)){S.tab=3;panel();var n=/2 portas/.test(cam)?'2':'1',b=[].filter.call(document.querySelectorAll('#bd [data-door="'+n+'"]'),function(q){return q.offsetParent!==null})[0];if(!b){res[cam]='sem botão';continue}b.click();await W(300)}
  else{vmenuOpen(0,S.sv||0,200,300);await W(50);var bm=document.querySelector('#vmenu [data-vk="door1"]');if(!bm){res[cam]='menu sem "1 porta" (escondido)';vmenuClose();continue}bm.click();await W(300);vmenuClose()}
  m=S.mods[0];var p1=portas(m),e1=eletro(m),maior=p1.reduce(function(a,q){return Math.max(a,q.h)},0);
  res[cam]=(e1===e0?'eletro igual':'ELETRO MUDOU ('+e0+' → '+e1+')')+' · maior porta '+maior+' mm (a de cima tinha '+altoAntes+') · '+(maior>altoAntes+1&&e1!==e0?'ERRO: porta passou do vão de cima':'ok')+(TL.length?' · aviso: '+TL[TL.length-1].slice(0,60):'');TL=[]}
 R.modelos[it.n]=res}
R.errs=__errs.length;return JSON.stringify(R);
