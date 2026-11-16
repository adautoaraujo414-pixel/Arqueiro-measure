/* Desempenho e vazamentos (precisa de --semente semente_contadores.js e do Chromium com --enable-precise-memory-info --js-flags=--expose-gc).
   Projeto grande (40 módulos em 3 paredes), tempos de draw, montagem do 3D e plano de corte, e crescimento de ouvintes, texturas, buffers e memória
   ao repetir abrir/fechar 3D, trocar de projeto e redesenhar o painel. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var heap=function(){try{if(window.gc)gc()}catch(_){}return performance.memory?Math.round(performance.memory.usedJSHeapSize/1048576):-1};
var t=function(f,n){var a=performance.now();for(var i=0;i<(n||1);i++)f();return Math.round((performance.now()-a)/(n||1))};
var C=window.__CNT||{};var snapC=function(){return {ouvintes:C.ouvintes,tex:C.tex,texDel:C.texDel,buf:C.buf,bufDel:C.bufDel,intervals:C.intervals,heapMB:heap(),nosDOM:document.getElementsByTagName('*').length}};
var R={};draw();
/* projeto grande */
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=12000;S.H=2700;draw();
var cz=its.filter(function(i){return /Balcão|Aéreo|Gaveteiro/.test(i.n)});for(var i=0;i<40;i++){newTpl(JSON.parse(JSON.stringify(cz[i%cz.length])))}draw();
R.modulos=S.mods.length;R.pecas=S.mods.reduce(function(a,m){return a+partsOf(m).length},0);
R.ms_draw=t(draw,5);R.ms_partsOf_todos=t(function(){S.mods.forEach(function(m){partsOf(m)})},5);R.ms_corte=t(function(){cutGroups()},3);
open3D();await W(500);R.ms_build3D=t(__build,3);R.caixas3D=__boxes().length;R.ms_selecionar=t(function(){S.m=S.mods[7];draw()},5);
var big=JSON.stringify(snapState());R.tamanhoProjetoKB=Math.round(big.length/1024);R.ms_salvarJSON=t(function(){JSON.stringify(snapState())},5);R.ms_reabrir=t(function(){loadState(JSON.parse(big));draw()},2);
/* repetição */
var c0=snapC();var x=function(){var b=document.getElementById('v3x');if(b)b.click()};
for(var k=0;k<20;k++){open3D();await W(60);x();await W(30)}var c1=snapC();
for(var k2=0;k2<20;k2++){loadState(JSON.parse(big));draw();panel()}var c2=snapC();
for(var k3=0;k3<30;k3++){S.m=S.mods[k3%S.mods.length];panel();draw()}var c3=snapC();
R.inicio=c0;R.depois_20x_abrir_fechar_3D=c1;R.depois_20x_reabrir_projeto=c2;R.depois_30x_trocar_modulo_e_painel=c3;
R.ouvintesPorTipo=Object.keys(C.porTipo||{}).sort(function(a,b){return C.porTipo[b]-C.porTipo[a]}).slice(0,8).map(function(k){return k+':'+C.porTipo[k]}).join(' ');
return JSON.stringify(R);
