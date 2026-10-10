'use strict';
/* A interface ativa inclui somente Esboço, Planta, Fotos e Corte. Lab temporariamente suspenso. */
const assert=require('node:assert/strict'),fs=require('node:fs');
const index=fs.readFileSync('app/src/main/assets/index.html','utf8');
const java=fs.readFileSync('app/src/main/java/com/arque/measure/MainActivity.java','utf8');
const list=java.match(/LOCAL_WEB_ASSETS\s*=\s*new HashSet<>\(Arrays\.asList\(([\s\S]*?)\)\)/);
assert(list,'A lista segura dos assets precisa estar explícita no código Java.');
const allowed=[...list[1].matchAll(/"([^"]+)"/g)].map(m=>m[1]);
assert.equal(new Set(allowed).size,allowed.length,'assets sem duplicação');
const expected=new Set(['index.html']);
for(const match of index.matchAll(/<(?:script|link)\b[^>]*?\b(?:src|href)="([^"]+)"[^>]*>/g))
 if(/\.(js|css)$/.test(match[1]))expected.add(match[1]);
assert.equal(expected.size,5,'apenas index, estilos, core, corte e app são carregados');
for(const file of expected){
 assert(allowed.includes(file),'Android WebView está bloqueando '+file+' -> Laboratório ficará indisponível.');
 assert(fs.existsSync('app/src/main/assets/'+file),'Recurso permitido mas ausente no APK: '+file);
}
for(const file of allowed)assert(expected.has(file),'Recurso indevido ou obsoleto liberado em WebView: '+file);
assert(java.includes('if(!LOCAL_WEB_ASSETS.contains(name))return denied();'),'interceptador não utiliza allowlist para negar desconhecidos');
assert(java.includes('setCacheMode(WebSettings.LOAD_NO_CACHE)'),'WebView deve usar scripts da versão instalada, nunca resposta 403 antiga');
assert(java.includes('"https".equals(uri.getScheme())')&&java.includes('"appassets.arque.invalid".equals(uri.getHost())'),'origem segura restrita');
assert(!/if\(!name\.equals\("index\.html"\)/.test(java),'allowlist antiga do WebView não pode retornar');
for(const name of ['lab.js','modules.js','lab-visual.js','lab-fabrication.js','corner45.js','lab.css','module-ui.css'])
 assert(!allowed.includes(name),'Laboratório suspenso não deve ser servido pelo WebView: '+name);
assert(fs.existsSync('app/src/main/assets/lab.js'),'código do Laboratório permanece no repositório para retomada futura');
console.log('WebView Android: somente os '+expected.size+' arquivos ativos são servidos; Laboratório suspenso.');
