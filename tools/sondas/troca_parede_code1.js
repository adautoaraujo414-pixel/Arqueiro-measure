// Sonda do Code 1 (Playwright). Precisa de tools/sondas/ponte.js (a ponte em memória do bateria_editor.py, extraída) ao lado.
// 3.9 troca de parede: node parede.js URL
const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch({args:['--use-angle=swiftshader','--enable-unsafe-swiftshader']});const ctx=await b.newContext({viewport:{width:1366,height:768}});const P=fs.readFileSync(__dirname+'/ponte.js','utf8');
for(const cen of ['demo','cantos','closet']){const p=await ctx.newPage();await p.addInitScript(P);await p.goto(process.argv[2]);await p.waitForTimeout(1500);
 console.log('== '+cen+'\n'+await p.evaluate(async(cen)=>{const W=ms=>new Promise(r=>setTimeout(r,ms));window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};const T=n=>{let r=null;CATS.forEach(k=>(k.it||[]).forEach(q=>{const t=typeof q==='number'?TPL[q]:q;if(!r&&t&&!t.act&&t.n===n)r=t}));return r?JSON.parse(JSON.stringify(r)):null};
  loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=6000;S.H=2700;S.mods=[];draw();const put=(n,x)=>{const t=T(n);if(!t)return;newTpl(t);S.mods[S.mods.length-1].x=x;draw()};
  if(cen==='demo')demoScene();
  if(cen==='cantos'){put('Canto em L (aéreo) · esquerdo',0);put('Balcão canto cego · cego na direita (porta na esquerda)',1500);put('Balcão 2 portas',2700);wvGo('e');put('Balcão 2 portas',1200);put('Aéreo 2 portas',1200);wvGo('d');put('Torre forno + micro-ondas (embutir)',600);wvGo('f')}
  if(cen==='closet'){S.env='livre';S.room='quarto';let x=0;['Guarda-roupa 3 vãos','2P c/ Cab+Gav Int 600mm','Canto L guarda-roupa · direito'].forEach(n=>{put(n,x);const m=S.mods[S.mods.length-1];if(m)x=m.x+m.w+40});wvGo('e');put('Guarda-roupa porta de correr',500);wvGo('f')}
  draw();await W(400);
  const foto=()=>{wvGo('f');draw();const s=JSON.parse(JSON.stringify(snapState()));delete s.m;const pk=S.mods.map(m=>{try{return (m.uid||'')+':'+partsOf(m).map(x=>[x.pk,x.cl,x.cw,x.mat,x.qty].join(',')).join(';')}catch(e){return 'ERR'}});const cg=Object.entries(cutGroups().map).map(([k,G])=>k+'='+G.qty).sort();let b3='';try{__build();b3=__boxes().filter(x=>x.pk).map(x=>[x.nm,x.pk,Math.round(x.x0),Math.round(x.x1),Math.round(x.y0),Math.round(x.y1),Math.round(x.z0),Math.round(x.z1)].join(',')).sort().join('|')}catch(e){b3='ERR '+e}let pl='';try{pl=plantaSvg()}catch(e){pl='ERR'}return {s:JSON.stringify(s),pk:JSON.stringify(pk),cg:cg.join('|'),b3,pl,n:S.mods.length}};
  const a=foto();const R=[];const cmp=(rot,c)=>{const dif=['s','pk','cg','b3','pl','n'].filter(k=>a[k]!==c[k]);R.push(rot+': '+(dif.length?'MUDOU '+dif.join(','):'igual'));if(dif.indexOf('s')>=0){const A=JSON.parse(a.s),B=JSON.parse(c.s),o=[];const cm=(x,y,pa)=>{if(o.length>6)return;if(typeof x!==typeof y||Array.isArray(x)!==Array.isArray(y)){o.push(pa+': '+String(JSON.stringify(x)).slice(0,60)+' → '+String(JSON.stringify(y)).slice(0,60));return}if(x&&typeof x==='object'){new Set(Object.keys(x).concat(Object.keys(y||{}))).forEach(k=>cm(x[k],y?y[k]:undefined,pa+'.'+k))}else if(x!==y)o.push(pa+': '+JSON.stringify(x)+' → '+JSON.stringify(y))};cm(A,B,'S');R.push('   '+o.join('\n   '))}};
  for(let i=0;i<3;i++){wvGo('e');draw();await W(80);wvGo('d');draw();await W(80);wvGo('f');draw();await W(80)}cmp('3 voltas f→e→d→f',foto());
  wvGo('e');draw();open3D();await W(500);try{document.getElementById('v3x').click()}catch(_){}await W(200);wvGo('d');draw();cmp('3D aberto na esquerda, fecha, vai pra direita, volta',foto());
  wvGo('e');draw();const sv=JSON.stringify(snapState());S.mods=[];loadState(JSON.parse(sv));draw();await W(300);cmp('salvar na esquerda e reabrir',foto());
  wvGo('d');draw();try{histTick&&histTick()}catch(_){}await W(80);cmp('na direita (histórico)',foto());
  return R.join('\n')},cen));await p.close()}
await b.close()})();
