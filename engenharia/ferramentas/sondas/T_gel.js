window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* TORRE-GEL-PORTA (vídeo de 16/11 às 13:34): "troquei as portas de cima do armário acima da geladeira e a porta alterou foi do móvel todo, até tampando a geladeira".
   Regra: a porta é do aéreo em cima da geladeira; tamponamento e laterais são da estrutura e vão até o chão. Trocar porta nunca troca a caixa toda. */
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
var mk=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.stones=[];S.mods=[];draw();newTpl(T('Caixa da geladeira side by side (laterais + aéreo)'));var m=S.mods[0];m.x=600;m.tl=true;m.tr=true;S.m=m;S.sv=0;draw();return m};
var st=function(m){var P=partsOf(m),pt=P.filter(function(p){return p.name==='Porta'});return m.v[0].k+' · portas '+pt.length+(pt.length?' '+pt.map(function(p){return p.cl+'×'+p.cw}).join(','):'')+' · nicho '+P.some(function(p){return p.gelN})+' · tamp '+P.filter(function(p){return /^Tamponamento (esquerdo|direito)$/.test(p.name)}).map(function(p){return p.cl}).join(',')};
var clk=function(par,ds,v){var b=document.createElement('button');b.dataset[ds]=v;par.appendChild(b);b.click();b.remove()};
/* 1) torre com geladeira, porta de cima e tamponamentos até o chão */
var m=mk();R.original=st(m);
/* 2) aba Portas: só as portas do aéreo (1, 2, sem porta); os botões gerais que trocavam a caixa toda não aparecem */
S.tab=3;panel();await W(60);var bd=document.getElementById('bd');R.abaPortas='gel '+bd.querySelectorAll('[data-geln]').length+' · gerais '+bd.querySelectorAll('[data-door],[data-slide]').length+' · nota "trocam a caixa toda" '+/trocam a caixa toda/.test(bd.textContent);
bd.querySelector('[data-geln="1"]').click();await W(40);R.umaPorta=st(m);bd=document.getElementById('bd');bd.querySelector('[data-geln="2"]').click();await W(40);R.duasPortas=st(m);
/* mesmo que chegue um clique de porta geral (projeto antigo, outro caminho): continua caixa da geladeira e a porta fica em cima */
clk(document.getElementById('bd'),'door','1');await W(40);R.cliqueGeral1=st(m);clk(document.getElementById('bd'),'door','3');await W(40);R.cliqueGeral3=st(m);clk(document.getElementById('bd'),'slide','2');await W(40);R.cliqueCorrer=st(m);clk(document.getElementById('bd'),'door','2');await W(40);
/* 3) menu do vão (2 toques): portas só no quadro de cima; "frente do vão inteiro" sem porta/correr (o resto continua trocando a caixa, com o aviso) */
vmenuOpen(0,0,200,300);await W(60);var d=document.getElementById('vmenu');R.menuVao='gel '+d.querySelectorAll('[data-geln]').length+' · porta inteira '+d.querySelectorAll('[data-vk="door1"],[data-vk="door2"],[data-vk="slide"]').length+' · trocar a caixa '+d.querySelectorAll('[data-vk="drawers"],[data-vk="shelves"],[data-vk="free"]').length;
clk(d,'vk','door1');await W(40);R.menuVao1porta=st(m);vmenuOpen(0,0,200,300);await W(40);clk(document.getElementById('vmenu'),'vk','door2');await W(40);R.menuVao2portas=st(m);
/* 4) altura do vão de cima (geladeira mais alta) e altura total da torre: a porta segue o vão dela, o tamponamento segue a torre */
m.v[0].gh=1930;draw();R.vaoDeCimaMenor=st(m);m.v[0].gh=1830;m.h=2700;draw();R.torreMaisAlta=st(m);m.h=2500;draw();
/* 5) 🗑 da porta no 3D e ↺ voltar */
open3D();await W(500);__cam(.35,.15,1.2);await W(150);var bx=__boxes().filter(function(b){return /^0:Porta/.test(String(b.nm))&&b.pk==='Porta#1'&&(b.y1-b.y0)>200})[0],q=org3api.proj([(bx.x0+bx.x1)/2,(bx.y0+bx.y1)/2,bx.z1]);__sel3(q[0],q[1]);await W(150);var del=document.querySelector('#e3 [data-e3del]');if(del){del.click();await W(80);var d2=document.querySelector('#e3 [data-e3del]');if(d2&&(m.xp||[]).length===0){d2.click();await W(80)}}R.lixo=st(m);
clk(document.body,'xpr','1');await W(60);R.voltou=st(m);
/* 6) 2D, 3D e plano de corte com as mesmas medidas (porta em cima, tamponamento até o chão) */
var P=partsOf(m);__build();var b3=__boxes().filter(function(b){return /^0:/.test(String(b.nm))});var h3=function(pk){var a=b3.filter(function(b){return b.pk===pk&&(b.y1-b.y0)>100}).map(function(b){return Math.round(b.y1-b.y0)});return a.length?Math.max.apply(null,a):0};
var sv=document.getElementById('svg'),rh=function(i){var e=sv.querySelector('#mod rect[data-p="'+i+'"]')||sv.querySelector('rect[data-p="'+i+'"]');return e?+e.getAttribute('height'):0},iP=P.findIndex(function(p){return p.name==='Porta'}),iT=P.findIndex(function(p){return p.name==='Tamponamento esquerdo'});
var cl=cutLines(m).filter(function(l){return /^Porta$|^Tamponamento esquerdo · face$/.test((l.names||[l.name])[0])}).map(function(l){return (l.names||[l.name]).join('+').replace(/ \(.*/,'')+' '+l.L+'×'+l.W+' q'+l.qty}).sort().join(' | ');
R.conferencia='3D porta '+h3('Porta#1')+' · 3D tamp '+h3('Tamponamento esquerdo#1')+' · 2D porta/tamp '+(Math.round(rh(iP)/rh(iT)*1000)/1000)+' (peças '+(Math.round(P[iP].h/P[iT].h*1000)/1000)+') · corte: '+cl;
document.getElementById('v3x').click();
/* 7) salvar, fechar e reabrir */
var sv_=JSON.stringify(snapState());loadState(JSON.parse(sv_));draw();R.reabriu=st(S.mods[0]);
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
