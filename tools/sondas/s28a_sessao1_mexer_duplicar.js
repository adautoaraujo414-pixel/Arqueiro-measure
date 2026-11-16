/* Sessão 1: projeto na biblioteca → abrir como o app → mexer (largura com espaço, módulo novo do catálogo) → desfazer/refazer → duplicar pela lista → gravar (como ao fechar) */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};window.confirm=function(){return true};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();await W(20);
var a=pLoadAll();a.push({id:'pS',client:{nome:'Sessão'},created:1,updated:1,current:JSON.parse(JSON.stringify(snapState()))});pSaveAll(a);await W(20);
var p=pLoadAll().filter(function(q){return q.id==='pS'})[0];CUR=p.id;loadState(p.current);draw();await W(700);
S.m=S.mods[1];var w0=S.mods[1].w;setv('w',w0+100);await W(700);R.w=S.mods[1].w;
newTpl(T('Gaveteiro 3 gavetas'));draw();await W(700);R.n=S.mods.length;
histTick();LASTT=0;document.getElementById('und').onclick();await W(50);R.desfez=S.mods.length;document.getElementById('red').onclick();await W(50);R.refez=S.mods.length;
R.dims=S.mods.map(function(m){return [Math.round(m.x),m.w,m.h,m.d].join('/')}).join(' ');
await W(4500);try{svFechar()}catch(_){}try{svFlush()}catch(_){}await W(200);
/* duplicar pela lista de clientes */
/* o botão de duplicar fica na lista de clientes (#clm), que é quem escuta o clique */clRender();var b=document.createElement('button');b.dataset.pd='pS';document.getElementById('clm').appendChild(b);b.click();b.remove();await W(200);
var L=pLoadAll();R.copias=L.filter(function(q){return /^Sessão/.test(q.client.nome)}).map(function(q){return q.client.nome+' '+q.current.mods.length}).join(' | ');
R.files=JSON.stringify(__files);R.ls=localStorage.getItem('arque.projects.v1');
return JSON.stringify(R);
