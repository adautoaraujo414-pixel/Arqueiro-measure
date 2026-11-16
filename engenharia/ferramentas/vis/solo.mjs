// Comprovação visual do XP-PK-SOLO: Armário alto com cor nas 2 portas; entra e sai do "só ele no 2D"; foto do 3D.
import { chromium } from '/opt/npm-tools/node_modules/playwright/index.mjs';
const [ED, PRE] = process.argv.slice(2);
const b = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist', '--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 440, height: 760 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true });
await p.addInitScript(`window.__noSetup=1;window.__files={};window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},shareCut:function(){},shareClient:function(){},listNotes:function(){return '[]'},contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};`);
await p.goto('file://' + ED); await p.waitForTimeout(1500);
const r = await p.evaluate(`(async function(){window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
S.mods=[];S.fr=[];S.rp=[];S.stones=[];S.env='cozinha';S.room='cozinha';S.W=2400;S.H=2700;newTpl(T('Armário alto 2 portas'));var m=S.mods[0];m.x=800;
var A=MATBY['arauco-ameixa-negra-nature'],B=MATBY['arauco-azul-sereno-matt'];m.pc={'Porta#1':{c:A.hex,n:A.n,id:A.id},'Porta#2':{c:B.hex,n:B.n,id:B.id}};S.m=m;draw();panel();await W(300);
var antes=Object.keys(m.pc).join(', ');
if(${PRE.endsWith('_semtocar') ? 0 : 1}){document.getElementById('plsolo').click();await W(150);document.getElementById('plsolo').click();await W(300)}
var depois=Object.keys(m.pc).join(', ')||'(nenhuma)';
open3D();await W(2500);__cam(.35,.18,1.25);await W(800);return 'cores por peça antes: '+antes+' · depois de entrar e sair do só ele: '+depois})()`);
console.log(r);
await (await p.$('#cv3')).screenshot({ path: PRE + '.png' });
await b.close();
