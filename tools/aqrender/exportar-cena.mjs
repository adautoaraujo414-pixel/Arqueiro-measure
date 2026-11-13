// AQRender · Fase 2 (prova isolada, fora do editor).
// Abre o editor de verdade, monta um projeto de teste no 3D e salva uma CÓPIA congelada da cena que o editor desenha
// (caixas e prismas, com a câmera que está na tela) em saida/cena.json, mais a foto do próprio 3D em saida/editor3d.png.
// Só lê: usa os mesmos acessos que os testes já usam (__boxes, __bg, PM3). Nada do editor é alterado.
// uso: node exportar-cena.mjs [giro] [inclinacao] [zoom]
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
const AQ = path.dirname(fileURLToPath(import.meta.url));
const { chromium } = await import(process.env.PLAYWRIGHT || '/opt/npm-tools/node_modules/playwright/index.mjs');
const ED = path.resolve(AQ, '../../app/src/main/assets/editor.html');
const [yaw, pitch, zoom] = [process.argv[2] || 0.55, process.argv[3] || 0.28, process.argv[4] || 1.25].map(Number);
fs.mkdirSync(path.join(AQ, 'saida'), { recursive: true });
const b = await chromium.launch({ executablePath: process.env.CHROME || '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
const p = await b.newPage({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
await p.addInitScript(`window.__noSetup=1;window.__files={};window.ArqueApp={isApp:function(){return true},isViewer:function(){return false},setCurrent:function(){},putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},listFiles:function(){return '[]'},companyName:function(){return 'Marcenaria Teste'},listNotes:function(){return '[]'},contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){}};`);
await p.goto('file://' + ED);
await p.waitForTimeout(1500);
const r = await p.evaluate(`(async()=>{
  var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};PR.setupDone=1;window.toast=function(){};
  demoScene();try{demoPaintMods()}catch(_){}
  var antes=JSON.stringify(snapState());
  open3D();await W(1200);__cam(${yaw},${pitch},${zoom});re3();await W(800);
  var semRef=function(k,v){return (k==='dpm'||k==='o'||typeof v==='function')?undefined:v};
  var cena={feito:new Date().toISOString(),tela:{w:PM3.w,h:PM3.h},cam:{X:PM3.X,Y:PM3.Y,W:PM3.W},boxes:JSON.parse(JSON.stringify(__boxes(),semRef)),bg:JSON.parse(JSON.stringify(__bg(),semRef))};
  re3();var c=document.getElementById('cv3');/* o WebGL limpa a tela depois de mostrar: a foto sai logo depois de desenhar, como o modo foto do app */
  return {cena:cena,foto:c.toDataURL('image/png'),projetoIgual:JSON.stringify(snapState())===antes,cv:[c.width,c.height]};
})()`);
await b.close();
fs.writeFileSync(path.join(AQ, 'saida/cena.json'), JSON.stringify(r.cena));
fs.writeFileSync(path.join(AQ, 'saida/editor3d.png'), Buffer.from(r.foto.split(',')[1], 'base64'));
const tipos = {}, tags = {};
for (const q of r.cena.boxes.concat(r.cena.bg)) { const t = q.gp ? 'gp' : q.pf ? 'pf-' + q.pf.ax : q.poly ? 'poly' : 'caixa'; tipos[t] = (tipos[t] || 0) + 1; tags[q.g || '-'] = (tags[q.g || '-'] || 0) + 1; }
console.log(JSON.stringify({ moveis: r.cena.boxes.length, ambiente: r.cena.bg.length, tela: r.cena.tela, canvas: r.cv, tipos, tags, projetoIgual: r.projetoIgual }));
