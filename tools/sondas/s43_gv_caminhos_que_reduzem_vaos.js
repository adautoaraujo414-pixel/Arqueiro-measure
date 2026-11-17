/* Investigação do gv (16–17/11, sem mudar o app): quais caminhos deixam o vão escolhido (S.sv) apontando pra um vão que não existe NO MESMO módulo,
   e se aí alguma leitura cria vãos fantasma (m.v maior que divisórias + 1).
   Módulo com 3 vãos e o 3º escolhido; reduz as divisórias por cada caminho do app; depois: (1) lê o vão escolhido como as 32 chamadas gv(S.sv) fazem;
   (2) abre as abas Internos e Portas; (3) toca em "2 portas" na aba Portas. Mede S.sv, divisórias+1, tamanho de m.v e em qual vão a ação caiu.
   Parte 2: projeto antigo com vãos fantasma já gravados — eles mudam peças, corte ou 3D? (efeito de uma futura correção do gv em projetos antigos). */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={caminhos:{},antigo:{}};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var cena=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));var m=S.mods[0];m.x=800;m.div=[1/3,2/3];m.v=[{k:'door',n:1},{k:'shelves',n:1},{k:'drawers',n:3}];S.m=m;S.sv=2;S.tab=1;draw();panel();return m};
var mede=async function(nome,acao){var m=cena();await W(30);var a0=m.v.map(function(v){return v.k}).join(',');try{await acao(m)}catch(e){R.caminhos[nome]='exceção '+e;return}m=S.mods[0];
 var r={depois:'divisórias '+m.div.length+' → vãos '+(m.div.length+1)+' · S.sv '+S.sv+' · m.v '+m.v.length};
 var n0=m.v.length;try{gv(S.sv)}catch(_){}r.lerVaoEscolhido='m.v '+n0+' → '+m.v.length+(m.v.length>m.div.length+1?' · FANTASMA':'');
 S.tab=2;panel();S.tab=3;panel();r.abasInternosEPortas='S.sv '+S.sv+' · m.v '+m.v.length+(m.v.length>m.div.length+1?' · FANTASMA':'');
 var b=[].filter.call(document.querySelectorAll('#bd [data-door="2"]'),function(q){return q.offsetParent!==null})[0];if(b){b.click();await W(50)}m=S.mods[0];r.dois_portas='vão '+S.sv+' · tipos '+m.v.map(function(v){return v.k+(v.n||'')}).join(',')+(m.v.length>m.div.length+1?' · FANTASMA':'');
 R.caminhos[nome]=r};
draw();
await mede('aba Divisões · "1 divisória → 2 vãos"',async function(m){var b=document.querySelector('#bd [data-dvq="1"]');b.click();await W(50)});
await mede('aba Divisões · Limpar divisões',async function(m){var b=[].filter.call(document.querySelectorAll('#bd button'),function(q){return /Limpar divis/.test(q.textContent)})[0];window.confirm=function(){return true};b.click();await W(50)});
await mede('🗑 numa divisória escolhida (a 2ª)',async function(m){window.DIVI=1;window.LAST='div';window.__delConfirma=1;document.getElementById('delMod').click();window.__delConfirma=0;await W(50)});
await mede('desfazer pra antes das divisórias',async function(m){HIST=[];FUT=[];LASTS=null;var s3=JSON.stringify(snapState());var o=JSON.parse(s3);o.mods[0].div=[];o.mods[0].v=[o.mods[0].v[0]];HIST=[{s:JSON.stringify(o),k:histKey(o)}];LASTS={s:s3,k:histKey(JSON.parse(s3))};S.sv=2;document.getElementById('und').onclick();await W(50)});
await mede('mexer direto: m.div=[] e desenhar (como camadas que mudam divisórias)',async function(m){m.div=[];draw();await W(20)});
/* parte 2: projeto antigo com vãos fantasma gravados */
var sig=function(m){return partsOf(m).map(function(p){return p.pk+' '+p.cl+'x'+p.cw}).sort().join(';')};
var m=cena();m.div=[0.5];m.v=[{k:'door',n:1},{k:'drawers',n:2}];S.sv=0;draw();__build();var p0=sig(m),c0=JSON.stringify(cutLines(m)),b0=__boxes().filter(function(q){return String(q.nm).indexOf('0:')===0}).length,s0=JSON.stringify(snapState());
m.v.push({k:'free',n:1});m.v.push({k:'door',n:4});draw();__build();
R.antigo.pecasIguais=sig(m)===p0;R.antigo.corteIgual=JSON.stringify(cutLines(m))===c0;R.antigo.tresDIgual=__boxes().filter(function(q){return String(q.nm).indexOf('0:')===0}).length===b0;
var s1=JSON.parse(JSON.stringify(snapState()));R.antigo.fantasmaGravado=s1.mods[0].v.length+' vãos gravados com '+s1.mods[0].div.length+' divisória(s)';
loadState(s1);draw();R.antigo.reabrir='m.v '+S.mods[0].v.length+' (a abertura não tira nada sozinha)';
S.m=S.mods[0];S.tab=1;panel();R.antigo.abaDivisoesMostra=[].filter.call(document.querySelectorAll('#bd [data-dvsv]'),function(b){return true}).length+' vão(s)';
R.errs=__errs.length;return JSON.stringify(R);
