/* gera projetos no editor publicado: cada modelo do catálogo sozinho + cozinha demo */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});var cs=function(){try{var G=cutGroups();return G.ord.map(function(k){var g=G.map[k];return [g.fin||'',g.qty,(g.names||[]).join('/')].join(' ')}).sort()}catch(e){return ['ERRO']}};var out={},sig=function(){return S.mods.map(function(m){return partsOf(m).map(function(p){return p.name+' '+p.cl+'x'+p.cw+' q'+(p.qty||1)}).sort().join(';')})};
for(var i=0;i<its.length;i++){S.stones=[];S.mods=[];S.fr=[];S.isl=[];S.m=null;S.env='livre';S.room='livre';S.W=6000;S.H=3000;draw();newTpl(JSON.parse(JSON.stringify(its[i])));if(!S.mods.length)continue;draw();await W(2);out[its[i].n]={st:JSON.stringify(snapState()),p:sig(),c:cs()}}
draw();if(typeof demoScene==='function'){demoScene();await W(400);draw();out['__demo']={st:JSON.stringify(snapState()),p:sig(),c:cs()}}
return JSON.stringify(out)
