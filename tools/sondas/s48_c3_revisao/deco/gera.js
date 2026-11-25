window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var cs=function(){try{var G=cutGroups();return G.ord.map(function(k){var g=G.map[k];return [g.fin||'',g.qty,g.L,g.W,(g.names||[]).join('/')].join(' ')}).sort()}catch(e){return ['ERRO']}};
var sig=function(){return JSON.stringify(S.mods.map(function(m){return partsOf(m)}))};
var hs=function(s){s=String(s);var h=2166136261;for(var i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return (h>>>0).toString(16)+':'+s.length};
var deco=function(){window.__build();var B=window.__boxes().filter(function(b){return b.nm==null||b.nm===''});return hs(JSON.stringify(B.map(function(b){return [b.x0,b.x1,b.y0,b.y1,b.z0,b.z1].map(Math.round)})))+'#'+B.length};
var orc=function(){try{var b=budget();return [b.tot,b.sale].join('/')}catch(e){return 'ERRO'}};var dxf=function(){try{return hs(JSON.stringify(dxfPecas(),function(k,v){return k==='ids'?undefined:v}))}catch(e){return 'ERRO'}};
open3D();await W(300);var out={};
for(var i=0;i<its.length;i++){S.stones=[];S.mods=[];S.fr=[];S.isl=[];S.m=null;S.env='livre';S.room='livre';S.W=6000;S.H=3000;draw();newTpl(JSON.parse(JSON.stringify(its[i])));if(!S.mods.length)continue;draw();out[its[i].n]={st:JSON.stringify(snapState()),p:sig(),c:cs(),d:deco(),o:orc(),x:dxf()}}
if(typeof demoScene==='function'){demoScene();await W(400);draw();out['__demo']={st:JSON.stringify(snapState()),p:sig(),c:cs(),d:deco(),o:orc(),x:dxf()}}
(window.__BK||[]).forEach(function(p){loadState(JSON.parse(JSON.stringify(p.st)));draw();out['bk '+p.id]={st:JSON.stringify(snapState()),p:sig(),c:cs(),d:deco(),o:orc(),x:dxf()}});
document.getElementById('v3x').click();return JSON.stringify(out)
