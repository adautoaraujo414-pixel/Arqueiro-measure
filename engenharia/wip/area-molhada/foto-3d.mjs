// Área molhada no 3D: como fica (antes x depois)
import { chromium } from '/opt/npm-tools/node_modules/playwright/index.mjs';
const [ED, DIR, TAG, COR] = process.argv.slice(2);
const b = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist', '--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 800, height: 640 }, deviceScaleFactor: 1, hasTouch: true, isMobile: true });
await p.addInitScript(`window.__noSetup=1;window.__files={};window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},shareCut:function(){},shareClient:function(){},listNotes:function(){return '[]'},contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};`);
await p.goto('file://' + ED); await p.waitForTimeout(1500);
const info = await p.evaluate(`(async function(){window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
 loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=2400;S.H=2600;S.stones=[];S.mods=[];draw();addStone();var st=S.stones[0];st.x=100;st.w=2200;st.d=600;st.t=870;st.e=30;${COR?"st.cor='"+COR+"';":""}
 st.items=[{k:'cuba',x:900,w:500,d:400,y:100}];st.wet=wetDefault(st);draw();open3D();await W(1500);return JSON.stringify(st.wet)+' '+JSON.stringify(wetGeo(st))})()`);
console.log(TAG, info);
const cams = [['cima', '0,1.25,2.6'], ['lado', '.45,.55,2.3'], ['perto', '.25,.35,4.2']];
for (const [n, c] of cams) { await p.evaluate(`__cam(${c})`); await p.waitForTimeout(900); await (await p.$('#cv3')).screenshot({ path: `${DIR}/wet_${TAG}_${n}.png` }); }
await b.close();
