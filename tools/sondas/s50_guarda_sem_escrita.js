/* (_gel = id do eletro com a hora, normalizado como os outros ids) */
/* item 31: o guarda das passadas de restrição (confineAll/roomClamp) sem escrever-e-desfazer tem que dar o MESMO projeto e os MESMOS avisos.
   142 modelos do catálogo, cada um posto fora do lugar (passando da parede, do teto, embaixo do chão, maior que o pé-direito), mais uma cozinha
   com vizinhos sobrepostos; desenha, monta o 3D, arrasta (campo) e reabre. Assinatura = projeto (ids trocados pela posição) + avisos. Compare antigo × novo. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(t&&!t.act&&t.w&&t.h)its.push(t)})});
var norm=function(){var o=JSON.parse(JSON.stringify(snapState())),ids={},n=0,tira=function(x){if(Array.isArray(x))return x.map(tira);if(x&&typeof x==='object'){var r={};Object.keys(x).forEach(function(k){var v=x[k];if(k==='uid'||k==='id'||k==='at'||k==='t0'||k==='_gel'){if(typeof v==='string'||typeof v==='number'){if(!(v in ids))ids[v]='#'+(n++);v=ids[v]}}r[k]=tira(v)});return r}return x};return JSON.stringify(tira(o))};
var avisos=function(){try{return JSON.stringify((window.fgConflitos?fgConflitos():[]).map(function(c){return c.texto}))}catch(e){return 'erro'}};
var H_=function(t){var h=0;for(var i=0;i<t.length;i++)h=(h*31+t.charCodeAt(i))|0;return h};
var R={N:0,sig:{},erros:[]};
var passo=function(k,f){try{f()}catch(e){R.erros.push(k+': '+String(e).slice(0,80))}};
for(var i=0;i<its.length;i++){var it=its[i];passo(it.n,function(){
 loadState(initLimpo());S.env='cozinha';S.W=3600;S.H=2600;S.mods=[];draw();newTpl(JSON.parse(JSON.stringify(it)));newTpl(JSON.parse(JSON.stringify(it)));draw();if(S.mods.length<2)return;R.N++;
 var a=S.mods[0],b=S.mods[1],L=[];var st0=JSON.stringify(snapState());loadState(JSON.parse(st0));a=S.mods[0];b=S.mods[1];
 /* fora do lugar, sem ser a pessoa mexendo (como num projeto antigo) */a.x=S.W-a.w/2;b.b=S.H-200;b.h=Math.max(b.h,S.H+100);var st1=JSON.stringify(snapState());loadState(JSON.parse(st1));
 draw();L.push(norm(),avisos());__build();L.push(norm());draw();draw();L.push(norm(),avisos());
 /* a pessoa mexe no campo x do módulo escolhido (só esse campo pode encaixar) */S.m=S.mods[1];try{setv('x',String(S.W-100))}catch(_){}draw();L.push(norm(),avisos());
 /* parede encolhe (mudar o ambiente não autoriza nada) */S.W=Math.round(S.W*0.7);draw();__build();L.push(norm(),avisos());
 R.sig[it.n]=H_(L.join('|'))})}
passo('cozinha',function(){loadState(initLimpo());S.env='cozinha';S.W=3000;S.H=2500;S.mods=[];draw();['Balcão 2 portas','Balcão da pia (cuba)','Aéreo 2 portas','Torre quente (forno)'].forEach(function(n){var t=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var x=typeof q==='number'?TPL[q]:q;if(!t&&x&&x.n===n&&!x.act)t=x})});newTpl(JSON.parse(JSON.stringify(t)))});draw();
 var st=JSON.stringify(snapState());loadState(JSON.parse(st));S.mods[1].x=S.mods[0].x+100;S.mods[3].h=2600;S.mods[2].b=2300;st=JSON.stringify(snapState());loadState(JSON.parse(st));var L=[];draw();__build();L.push(norm(),avisos());
 S.m=S.mods[0];try{setv('x','2900')}catch(_){}draw();L.push(norm(),avisos());S.W=2400;draw();__build();L.push(norm(),avisos());R.sig.cozinha=H_(L.join('|'));R.cozinhaAvisos=avisos()});
return JSON.stringify(R);
