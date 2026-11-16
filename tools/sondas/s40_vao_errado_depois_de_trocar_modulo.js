/* Fase 2 · seleção: o vão escolhido (S.sv) de um módulo não pode ir parar em outro módulo.
   A tem 3 vãos e o 3º está escolhido. Troca pra B (1 vão) por cada caminho do app e toca no botão "Gavetas" do painel do vão.
   Certo: a mudança cai no vão que a pessoa está vendo de B (o 1º) e B continua com 1 vão. */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var sv=document.getElementById('svg');
var ev=function(t,x,y,el){(el||document.elementFromPoint(x,y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:x,clientY:y,pointerId:5,isPrimary:true,pointerType:'touch',buttons:t==='pointerup'?0:1}))};
var toque=async function(el){var b=el.getBoundingClientRect(),x=b.left+b.width/2,y=b.top+b.height/2;ev('pointerdown',x,y,el);ev('pointerup',x,y,sv);ev('pointerup',x,y,window);await W(500)};
var cena=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();var A=S.mods[0],B=S.mods[1];A.div=[1/3,2/3];A.v=[{k:'door',n:1},{k:'door',n:1},{k:'door',n:1}];B.v=[{k:'door',n:1}];B.div=[];B.x=A.x+A.w+400;draw();S.m=A;S.sv=2;S.tab=0;panel();draw();return JSON.stringify(snapState())};
/* os botões do tipo do vão ficam na aba Internos (S.tab=2) */var botaoGavetas=function(){S.tab=2;panel();return document.querySelector('#bd button[data-k="drawers"]')};
var mede=async function(nome){var B=S.mods.filter(function(m){return m.v&&m.v.length===1&&m!==S.mods[0]||(S.mods.length===1)})[0]||S.m;var antes={sv:S.sv,mi:S.mods.indexOf(S.m),nv:S.m?S.m.v.length:-1};var b=botaoGavetas();if(b){b.click();await W(200)}
 R[nome]='S.sv depois de trocar '+antes.sv+' · módulo escolhido '+antes.mi+' (vãos '+antes.nv+') · depois de "Gavetas": vãos '+(S.m?S.m.v.length:-1)+' · tipos '+(S.m?S.m.v.map(function(v){return v.k}).join(','):'')+(b?'':' · (sem botão Gavetas)')};
draw();
/* 1. toque no 2D no módulo B */
var base=cena();var gB=[].filter.call(sv.querySelectorAll('#mod'),function(g){return +g.dataset.mi===1})[0];await toque(gB.querySelector('rect[data-mi]'));await mede('toque2D');
/* 2. toque no 3D no módulo B */
loadState(JSON.parse(base));draw();S.m=S.mods[0];S.sv=2;panel();draw();open3D();await W(400);__build();var B=S.mods[1],p=org3api.proj([B.x+B.w/2,B.b+B.h/2,B.d+20]);try{__sel3(p[0],p[1])}catch(e){}await W(500);var x3=document.getElementById('v3x');if(x3)x3.click();await W(100);await mede('toque3D');
/* 3. abrir outro projeto (só B) pela lista do editor */
loadState(JSON.parse(base));draw();S.m=S.mods[0];S.sv=2;panel();draw();var o=JSON.parse(base);o.mods=[o.mods[1]];var a=pLoadAll().filter(function(q){return q.id!=='pB40'});a.push({id:'pB40',client:{nome:'B'},created:1,updated:1,current:o});pSaveAll(a);var pb=pLoadAll().filter(function(q){return q.id==='pB40'})[0];CUR=pb.id;loadState(pb.current);draw();S.m=S.mods[0];panel();await mede('outroProjeto');
/* 4. apagar o módulo A pelo 🗑 (confirmado) e ficar no B */
loadState(JSON.parse(base));draw();S.m=S.mods[0];S.sv=2;LAST='mod';panel();draw();window.__delConfirma=1;var del=document.getElementById('delMod');del.click();await W(100);del.click();await W(300);window.__delConfirma=0;if(S.mods.length===1)S.m=S.mods[0];panel();await mede('apagouA');
/* 5. desfazer depois de escolher B */
loadState(JSON.parse(base));draw();HIST=[];FUT=[];LASTS=null;histTick();S.m=S.mods[0];S.sv=2;panel();draw();LASTT=0;S.mods[1].h-=10;draw();LASTT=0;histTick();document.getElementById('und').onclick();await W(100);S.m=S.mods[1];panel();await mede('desfazerEEscolherB');
pSaveAll(pLoadAll().filter(function(q){return q.id!=='pB40'}));R.errs=__errs.length;return JSON.stringify(R);
