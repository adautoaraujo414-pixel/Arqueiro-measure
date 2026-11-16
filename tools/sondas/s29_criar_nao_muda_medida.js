/* Encaixe inicial: móvel novo do catálogo nasce com as medidas do catálogo (exceto a largura mínima aprovada do forno) e os móveis que já existiam não mudam nada.
   Parede com espaço e parede quase cheia (o novo vai pra parede do lado ou pro espaço que sobra). */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h&&!it.corner)its.push(it)})});
var V={},ex=function(k,t){(V[k]=V[k]||[]).push(t)},N=0;var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var dims=function(ms){return ms.map(function(m){return [m.x,m.b||0,m.w,m.h,m.d,m.esp].join('/')}).join(' ')};
draw();
for(var cheia of [false,true]){for(var i=0;i<its.length;i++){var it=its[i];loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=cheia?2700:8000;S.H=2700;draw();
 newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();await W(5);var antes=S.mods.slice(),d0=dims(antes);
 newTpl(JSON.parse(JSON.stringify(it)));draw();await W(5);var nv=S.mods.filter(function(q){return antes.indexOf(q)<0})[0];N++;
 if(dims(antes)!==d0)ex((cheia?'parede cheia':'parede livre')+': móvel existente mudou',it.n+' · '+d0+' → '+dims(antes));
 if(!nv){ex('não criou',it.n);continue}
 var ow=(nv.v||[]).filter(function(v){return v&&v.k==='oven'})[0],wmin=ow?(+ow.ow||560)+2*(+nv.esp||15)+10:0,wEsp=Math.max(+it.w,wmin);
 if(nv.w!==wEsp||nv.h!==+it.h||(+it.d&&nv.d!==+it.d))ex((cheia?'parede cheia':'parede livre')+': medida do novo ≠ catálogo',it.n+' · catálogo '+it.w+'×'+it.h+'×'+(it.d||'-')+(wmin>+it.w?' (forno pede '+wmin+')':'')+' · criado '+nv.w+'×'+nv.h+'×'+nv.d)}}
var R={criados:N,achados:{}};Object.keys(V).forEach(function(k){R.achados[k]=V[k].length+' :: '+V[k].slice(0,5).join(' ‖ ')});return JSON.stringify(R);
