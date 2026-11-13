// AQRender · Fase 2: abre a prova (prova.html) num navegador, espera renderizar e salva saida/aqrender.png e saida/relatorio.json.
// uso: node rodar-prova.mjs [modo: realista|rapido] [k: escala da imagem, 1 = tamanho da tela do 3D]
import fs from 'fs';
import http from 'http';
import path from 'path';
import { fileURLToPath } from 'url';
const AQ = path.dirname(fileURLToPath(import.meta.url));
const { chromium } = await import(process.env.PLAYWRIGHT || '/opt/npm-tools/node_modules/playwright/index.mjs');
const modo = process.argv[2] || 'realista', k = process.argv[3] || '1';
const TP = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json', '.png': 'image/png' };
const srv = http.createServer((q, s) => { const f = path.join(AQ, decodeURIComponent(q.url.split('?')[0])); if (!f.startsWith(AQ) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { s.writeHead(404); s.end(); return; } s.writeHead(200, { 'content-type': TP[path.extname(f)] || 'application/octet-stream' }); fs.createReadStream(f).pipe(s); });
await new Promise(r => srv.listen(0, '127.0.0.1', r));
const b = await chromium.launch({ executablePath: process.env.CHROME || '/usr/bin/google-chrome', args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
const p = await b.newPage({ viewport: { width: 1280, height: 900 }, deviceScaleFactor: 1 });
const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
const t0 = Date.now();
await p.goto(`http://127.0.0.1:${srv.address().port}/prova.html?modo=${modo}&k=${k}`);
await p.waitForFunction('window.aqPronto===true', null, { timeout: 180000 }).catch(() => { });
const rel = await p.evaluate('window.aqRelatorio||null'), png = await p.evaluate(`document.getElementById('aq').toDataURL('image/png')`);
await b.close(); srv.close();
if (rel) { rel.tempoTotalMs = Date.now() - t0; rel.erros = errs.slice(0, 5); fs.writeFileSync(path.join(AQ, `saida/relatorio-${modo}.json`), JSON.stringify(rel, null, 1)); }
if (rel && rel.liberado) fs.writeFileSync(path.join(AQ, `saida/aqrender-${modo}.png`), Buffer.from(png.split(',')[1], 'base64'));
console.log(JSON.stringify(rel || { erro: 'a prova não terminou', erros: errs.slice(0, 5) }, null, 1));
