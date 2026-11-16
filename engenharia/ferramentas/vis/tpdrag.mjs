// Reproduz: arrastar o tamponamento externo no 2D (toque/caneta de verdade) e ver o que muda no módulo.
import { chromium } from '/opt/npm-tools/node_modules/playwright/index.mjs';
const [ED, MODO] = process.argv.slice(2); // MODO: sel (módulo já escolhido) | nsel (outro módulo escolhido)
const b = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist', '--allow-file-access-from-files'] });
const ctx = await b.newContext({ viewport: { width: 1280, height: 800 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true });
const p = await ctx.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message));
await p.addInitScript(`window.__noSetup=1;window.__files={};window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},shareCut:function(){},shareClient:function(){},listNotes:function(){return '[]'},contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};`);
await p.addInitScript('window.__FY='+(process.argv[6]||0.75));await p.goto('file://' + ED); await p.waitForTimeout(1500);
const cdp = await ctx.newCDPSession(p);
const info = await p.evaluate(`(async function(){window.MINI3OFF=1;PR.setupDone=1;window.toast=function(t){(window.__TL=window.__TL||[]).push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5610;S.H=3270;S.stones=[];S.mods=[];draw();
var x=200;['Balcão 2 portas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var m=S.mods[S.mods.length-1];m.x=x;x+=m.w});x=3200;['Gaveteiro 3 gavetas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var m=S.mods[S.mods.length-1];m.x=x;x+=m.w});
addStone();var m=S.mods[3];m.tr=true;delete m.trAuto;draw();S.m=${MODO === 'nsel' ? 'S.mods[0]' : 'm'};S.tab=0;draw();panel();await W(200);
var P=partsOf(m),i=P.findIndex(function(q){return q.name==='Tamponamento direito'});var g=[].filter.call(document.querySelectorAll('#svg #mod'),function(q){return +q.dataset.mi===3})[0];var r=${MODO==='centro'?"g.querySelector('rect[data-mi]')":"g.querySelector('rect[data-p=\"'+i+'\"]')"};r.scrollIntoView({block:'center'});await W(150);var bb=r.getBoundingClientRect();var FY=+(window.__FY||0.75);var X=bb.left+bb.width/2,Y=bb.top+bb.height*FY;var top=document.elementFromPoint(X,Y);
window.__EV=[];['pointerdown','pointermove','pointerup','pointercancel'].forEach(function(n){document.getElementById('svg').addEventListener(n,function(e){__EV.push(n[7]+(e.pointerType||'')[0]+':'+(window.drag?drag.t:'-'))},true)});var tp=function(nm){return (P[+((top&&top.dataset&&top.dataset.p)||-1)]||{}).name||'-'};
return {X:X,Y:Y,alvo:(top?top.tagName+' p='+(top.dataset.p||'')+' '+tp():'nada'),antes:{x:m.x,b:m.b,h:m.h,rod:m.rod,base:m.base,trAdj:m.trAdj||0}}})()`);
console.log('alvo do toque:', info.alvo, '· antes:', JSON.stringify(info.antes));
// caneta: pointerdown, move pra baixo 80 px, solta
const DX = +(process.argv[4] || 0), DY = +(process.argv[5] || 80);
const tch = async (type, x, y) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x, y, id: 1, radiusX: 4, radiusY: 4, force: 1 }] });
await tch('touchStart', info.X, info.Y); await p.waitForTimeout(60);
for (let i = 1; i <= 10; i++) { await tch('touchMove', info.X + i * DX / 10, info.Y + i * DY / 10); await p.waitForTimeout(30); }
await tch('touchEnd', info.X + DX, info.Y + DY); await p.waitForTimeout(400);
const dep = await p.evaluate(`(function(){var m=S.mods[3],P=partsOf(m);return {x:m.x,b:m.b,h:m.h,rod:m.rod,base:m.base,trAdj:m.trAdj||0,pecaBase:P.some(function(q){return /^Base inferior/.test(q.name)}),rodape:P.filter(function(q){return /^Rodapé/.test(q.name)}).length,avisos:(window.__TL||[]).slice(-3)}})()`);
console.log('eventos:', await p.evaluate('__EV.join(" ")'));console.log('depois:', JSON.stringify(dep), errs.length ? 'ERROS ' + errs[0] : '');
await p.screenshot({ path: 'vis/out/tpdrag_' + MODO + '.png' });
await b.close();
