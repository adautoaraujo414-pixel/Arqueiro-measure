window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var cs=function(){try{var G=cutGroups();return G.ord.map(function(k){var g=G.map[k];return [g.fin||'',g.qty,g.L,g.W,(g.names||[]).join('/')].join(' ')}).sort()}catch(e){return ['ERRO']}};
var sig=function(){return JSON.stringify(S.mods.map(function(m){return partsOf(m)}))};
var hs=function(s){s=String(s);var h=2166136261;for(var i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return (h>>>0).toString(16)+':'+s.length};
var deco=function(){window.__build();var B=window.__boxes().filter(function(b){return b.nm==null||b.nm===''});return hs(JSON.stringify(B.map(function(b){return [b.x0,b.x1,b.y0,b.y1,b.z0,b.z1].map(Math.round)})))+'#'+B.length};
var orc=function(){try{var b=budget();return [b.tot,b.sale].join('/')}catch(e){return 'ERRO'}};var dxf=function(){try{return hs(JSON.stringify(dxfPecas(),function(k,v){return k==='ids'?undefined:v}))}catch(e){return 'ERRO'}};
open3D();await W(300);var D=window.__D,R={abre:{p:0,c:0,d:0,o:0,x:0,st:0,ex:[]},n:0};
for(var k in D){R.n++;loadState(JSON.parse(D[k].st));draw();var st0=D[k].st,st1=JSON.stringify(snapState());var a={p:sig()===D[k].p,c:JSON.stringify(cs())===JSON.stringify(D[k].c),d:deco()===D[k].d,o:orc()===D[k].o,x:dxf()===D[k].x,st:st1===st0};['p','c','d','o','x','st'].forEach(function(q){if(!a[q]){R.abre[q]++;if(R.abre.ex.length<12)R.abre.ex.push(k+' '+q)}})}
/* catálogo novo nesta versão: peças/corte/orçamento/DXF iguais aos de antes; enfeite: nenhum */
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});R.novo={p:0,c:0,o:0,x:0,decoAntes:0,decoAgora:0,ex:[]};
for(var i=0;i<its.length;i++){var nm=its[i].n;if(!D[nm])continue;S.stones=[];S.mods=[];S.fr=[];S.isl=[];S.m=null;S.env='livre';S.room='livre';S.W=6000;S.H=3000;draw();newTpl(JSON.parse(JSON.stringify(its[i])));if(!S.mods.length)continue;draw();
 var p=partsOf(S.mods[0]),dd=window.__boxes?0:0;window.__build();var nDeco=0;S.mods.forEach(function(m){partsOf(m).forEach(function(q){if(q.deco&&window.decoMostra&&decoMostra(m,q))nDeco++})});
 if(sig()!==D[nm].p){R.novo.p++;R.novo.ex.push(nm+' p')}if(JSON.stringify(cs())!==JSON.stringify(D[nm].c)){R.novo.c++;R.novo.ex.push(nm+' c')}if(orc()!==D[nm].o)R.novo.o++;if(dxf()!==D[nm].x)R.novo.x++;
 var antes=+String(D[nm].d).split('#')[1],agora=+deco().split('#')[1];if(antes!==agora)R.novo.decoAntes++;if(nDeco)R.novo.decoAgora++}
document.getElementById('v3x').click();return JSON.stringify(R)
