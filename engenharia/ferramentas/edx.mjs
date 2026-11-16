// Roda o editor.html no Chromium (tela de celular) e executa um JS; imprime o resultado e os erros.
// uso: node ed.mjs <arquivo.js> [shot.png]
import { chromium } from '/opt/npm-tools/node_modules/playwright/index.mjs';
import fs from 'fs';
const ED = process.env.ED || '/home/claude/arqueiro-measure/app/src/main/assets/editor.html';
const js = fs.readFileSync(process.argv[2], 'utf8');
const shot = process.argv[3];
const b = await chromium.launch({ executablePath: '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist','--allow-file-access-from-files'] });
const p = await b.newPage({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true });
const errs = [];
p.on('pageerror', e => errs.push('pageerror: ' + e.message));
p.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text()); });
await p.addInitScript(`window.__noSetup=1;window.__errs=[];window.__shared=null;
window.__files={};window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},
putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},
listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},
shareCut:function(c,n,t){__shared={code:c,name:n,title:t}},shareClient:function(c,n,t){__sharedCl={code:c,name:n,title:t}},listNotes:function(){return '[]'},contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};`);
await p.goto('file://' + ED);
await p.waitForTimeout(1500);
let r;
try { r = await p.evaluate(`(async()=>{${js}})()`); } catch (e) { r = 'EXC: ' + e.message; }
console.log(typeof r === 'string' ? r : JSON.stringify(r, null, 1));
if (shot) await p.screenshot({ path: shot });
if (errs.length) console.log('ERRS:', errs.slice(0, 20).join('\n'));
await b.close();
