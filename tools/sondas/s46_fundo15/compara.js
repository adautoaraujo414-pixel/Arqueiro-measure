const {chromium}=require('playwright');const fs=require('fs');
const U=(d)=>'file://'+d+'/app/src/main/assets/editor.html?lang=pt&v='+Math.random();
const [PUB,BASE,NEW,PONTE,RICO]=process.argv.slice(2);/* pastas com app/src/main/assets (git archive <sha> app/src/main/assets | tar -x) */
const ponte=fs.readFileSync(PONTE,'utf8'),sig=fs.readFileSync(__dirname+'/assinatura.js','utf8');
const gera=fs.readFileSync(__dirname+'/../s45_projeto_publicado/gera_no_publicado.js','utf8');
(async()=>{const b=await chromium.launch();
const pg=async(dir)=>{const p=await (await b.newContext({viewport:{width:1366,height:768}})).newPage();p.on('pageerror',e=>console.log('ERR',dir.slice(-5),String(e).slice(0,150)));await p.addInitScript(ponte);await p.goto(U(dir),{waitUntil:'load'});await p.waitForTimeout(2500);await p.evaluate(sig);return p};
const a=await pg(PUB);const d=JSON.parse(await a.evaluate('(async()=>{'+gera+'})()'));
let extra={};if(RICO&&fs.existsSync(RICO))extra=JSON.parse(fs.readFileSync(RICO,'utf8'));Object.assign(d,extra);
const keys=Object.keys(d);console.log('projetos',keys.length,'(rico',Object.keys(extra).length+')');
const run=async(dir)=>{const p=await pg(dir);const out={};for(const k of keys){out[k]=await p.evaluate(async(st)=>{window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};loadState(JSON.parse(st));draw();await new Promise(r=>setTimeout(r,2));return window.__SIG()},d[k].st)}return out};
const A=await run(BASE),B=await run(NEW);let dif=[];
for(const k of keys){const x=A[k],y=B[k];for(const f of Object.keys(x)){if(JSON.stringify(x[f])!==JSON.stringify(y[f]))dif.push(k+' · '+f+': '+JSON.stringify(x[f]).slice(0,200)+' → '+JSON.stringify(y[f]).slice(0,200))}}
const fundos=keys.reduce((s,k)=>s+A[k].f.filter(q=>q.startsWith('1')).length,0);
console.log(JSON.stringify({projetos:keys.length,camposPorProjeto:Object.keys(A[keys[0]]).length,modulosComFundo:fundos,diferencas:dif.length,ex:dif.slice(0,15)},null,1));
await b.close()})();
