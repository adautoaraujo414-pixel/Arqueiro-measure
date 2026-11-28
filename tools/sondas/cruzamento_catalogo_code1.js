// Sonda do Code 1 (Playwright). Precisa de tools/sondas/ponte.js (a ponte em memória do bateria_editor.py, extraída) ao lado.
// Item 24/40: cruzamento por modelo do catálogo. node cruza.js URL saida.json [LxAxD]
const {chromium}=require('playwright');const fs=require('fs');
const [,,URL,OUT,JAN='1366x768x1']=process.argv;const [W,H,D]=JAN.split('x').map(Number);
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({viewport:{width:W,height:H},deviceScaleFactor:D});
const p0=await ctx.newPage();await p0.addInitScript(fs.readFileSync(__dirname+'/ponte.js','utf8'));await p0.goto(URL);await p0.waitForTimeout(1800);
const lista=await p0.evaluate(()=>{const L=[];CATS.forEach(c=>(c.it||[]).forEach(q=>{const t=typeof q==='number'?TPL[q]:q;if(t&&!t.act&&L.indexOf(t.n)<0)L.push(t.n)}));return L});await p0.close();
const out={};
for(const n of lista.filter(n=>!process.env.ONLY||n.indexOf(process.env.ONLY)>=0)){const p=await ctx.newPage();await p.addInitScript(fs.readFileSync(__dirname+'/ponte.js','utf8'));await p.goto(URL);await p.waitForTimeout(1500);
 try{out[n]=await p.evaluate(async(n)=>{const W=ms=>new Promise(r=>setTimeout(r,ms));window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};const R={},er=[];
  const T=n=>{let r=null;CATS.forEach(c=>(c.it||[]).forEach(q=>{const t=typeof q==='number'?TPL[q]:q;if(!r&&t&&!t.act&&t.n===n)r=t}));return JSON.parse(JSON.stringify(r))};
  loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=6000;S.H=2700;S.mods=[];draw();newTpl(T(n));const m=S.mods[0];m.x=1500;draw();S.m=m;
  const P=partsOf(m),pks=P.map(q=>q.pk),nomes=P.map(q=>q.name);const deriv=k=>/^Fundo/.test(k)||nomes.some(n=>k.indexOf(n+' · ')===0||k.indexOf(n+' (')===0);const temDeriv=q=>Object.keys(bpkAll||{}).concat([...srcpk]).some(k=>k!==q.pk&&(k.indexOf(q.name+' · ')===0||k.indexOf(q.name+' (')===0));let bpkAll=null;
  // A. campos do painel × módulo (mm)
  S.tab=0;panel();await W(50);const f={};['w','h','d','x','b'].forEach(k=>{const i=[...document.querySelectorAll('#bd input[data-k="'+k+'"]')].filter(e=>e.offsetParent)[0];if(i)f[k]=i.value});
  R.campos=Object.keys(f).filter(k=>String(f[k]).trim()!==UN.num(String(Math.round(m[k]||0)))).map(k=>k+' campo '+f[k]+' × dado '+m[k]+' ('+UN.u()+')');
  // B. lista de peças × corte (pelo src)
  const g=cutGroups(),srcpk=new Set();Object.values(g.map||{}).forEach(G=>(G.src||[]).forEach(s=>s.forEach(x=>{if(x.mi===0)srcpk.add(x.pk)})));
  R.foraDoCorte=P.filter(q=>!q.noCut&&!srcpk.has(q.pk)&&!temDeriv(q)).map(q=>q.pk+(q.noCut?'':'')+' mat'+q.mat);R.fantasmaNoCorte=[...srcpk].filter(k=>pks.indexOf(k)<0&&!deriv(k));R._fundoCorte=[...srcpk].filter(k=>/^Fundo#/.test(k)).sort().join();
  // C. 3D × peças
  window.__build&&__build();const B=__boxes().filter(x=>String(x.nm).split(':')[0]==='0');bpkAll={};B.forEach(x=>{if(x.pk)bpkAll[x.pk]=1});const bpk={};B.forEach(x=>{if(!x.pk||x.ft||x.cup||x.hg||x.pf||x.dq||x.poly)return;const k=x.pk;const o=bpk[k]||(bpk[k]={x0:1e9,x1:-1e9,y0:1e9,y1:-1e9,z0:1e9,z1:-1e9});['x','y','z'].forEach(a=>{o[a+'0']=Math.min(o[a+'0'],x[a+'0']);o[a+'1']=Math.max(o[a+'1'],x[a+'1'])})});
  R.semNo3D=P.filter(q=>!q.no3d&&!q.hide3d&&!bpkAll[q.pk]&&!temDeriv(q)).map(q=>q.pk+' noCut'+!!q.noCut+' mat'+q.mat);R.fantasma3D=Object.keys(bpkAll).filter(k=>pks.indexOf(k)<0&&!deriv(k));R._fundo3D=Object.keys(bpk).filter(k=>/^Fundo#/.test(k)).sort().join();R.fundoCorteX3D=R._fundoCorte===R._fundo3D?[]:['corte '+R._fundoCorte+' × 3D '+R._fundo3D];
  R.medida3D=[];P.forEach(q=>{const o=bpk[q.pk];if(!o||q.qty>1)return;const d3=[o.x1-o.x0,o.y1-o.y0,o.z1-o.z0].map(v=>Math.round(v)).sort((a,b)=>a-b);const dp=[q.w,q.h,(q.base&&q.base.d)||q.mat||15].map(v=>Math.round(+v||0)).sort((a,b)=>a-b);if(d3.join()!==dp.join())R.medida3D.push(q.pk+' 3D '+d3.join('×')+' peça '+dp.join('×'))});
  // D. salvar e reabrir
  const pj=x=>JSON.stringify(x.map(q=>[q.pk,q.w,q.h,q.cl,q.cw,q.qty,q.mat,q.note||'']));const a0=pj(P);const sv=JSON.stringify(snapState());S.mods=[];draw();loadState(JSON.parse(sv));draw();R.reaberto=pj(partsOf(S.mods[0]))===a0;
  // E. mudar e desfazer
  const m2=S.mods[0];S.m=m2;try{histTick&&histTick()}catch(_){}await W(50);m2.w+=100;draw();try{histTick&&histTick()}catch(_){}await W(50);const mudou=pj(partsOf(m2))!==a0;const ub=document.getElementById('und');if(ub)ub.click();else er.push('sem botão und');await W(80);draw();R.desfazer=(mudou?'mudou':'NÃO MUDOU')+' · volta '+(pj(partsOf(S.mods[0]))===a0);
  R.erros=er.concat(__errs.slice(0,3));return R},n)}catch(e){out[n]={erro:String(e).slice(0,200)}}
 await p.close()}
fs.writeFileSync(OUT,JSON.stringify(out,null,1));
const prob={};for(const [n,r] of Object.entries(out)){const L=[];for(const k of ['campos','foraDoCorte','fantasmaNoCorte','semNo3D','fantasma3D','medida3D','fundoCorteX3D'])if(r[k]&&r[k].length)L.push(k+': '+r[k].slice(0,4).join(' | '));if(r.reaberto===false)L.push('reaberto diferente');if(r.desfazer&&!/mudou · volta true/.test(r.desfazer))L.push('desfazer '+r.desfazer);if(r.erro)L.push('ERRO '+r.erro);if(r.erros&&r.erros.length)L.push('erros '+r.erros.join(';'));if(L.length)prob[n]=L}
console.log('modelos',Object.keys(out).length,'com achado',Object.keys(prob).length);console.log(JSON.stringify(prob,null,1));await b.close()})();
