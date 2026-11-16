window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var clr=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.room='livre';S.env='livre';S.W=6000;S.RD=3500;S.H=3000;S.m=null};
var sig=function(m){return partsOf(m).map(function(p){return p.pk+' '+Math.round(p.cl*10)/10+'x'+Math.round(p.cw*10)/10+' q'+(p.qty||1)+' '+(p.mat||'')+' '+Math.round(p.x)+','+Math.round(p.y)+','+Math.round(p.w)+','+Math.round(p.h)}).sort().join(';')};
var bsig=function(){return __boxes().filter(function(q){return q.pk}).map(function(q){return q.pk+'@'+[q.x0,q.x1,q.y0,q.y1,q.z0,q.z1].map(function(v){return Math.round(v)}).join(',')}).sort().join(';')};
function diff(a,b,p,out){if(out.length>12)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+': '+JSON.stringify(a)+' -> '+JSON.stringify(b));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var SN=function(){return JSON.parse(JSON.stringify(snapState()))};
var R={N:0,partsOfMuda:{},drawMuda:{},buildMuda:{},cutMuda:{},naoIdempotente:[],reabrirMuda:{},reabrirNaoEstavel:[],reabrirMudaPecas:[],incrementalDif3D:[],incrementalDifPecas:[],erros:[]};
var add=function(o,k,v){(o[k]=o[k]||[]).push(v)};
clr();draw();open3D();await W(400);
var e0=__errs.length;
for(var i=0;i<its.length;i++){var it=its[i];try{
 clr();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[S.mods.length-1];if(!m)continue;R.N++;S.m=m;draw();__build();
 var s0=SN(),d=[];partsOf(m);partsOf(m);var s1=SN();diff(s0,s1,'',d);d.forEach(function(x){add(R.partsOfMuda,x.replace(/\.mods\.\d+/,'.mods[]').split(':')[0],it.n)});
 d=[];cutLines(m);cutGroups();try{hwOf&&hwOf(m)}catch(e){}var s2=SN();diff(s1,s2,'',d);d.forEach(function(x){add(R.cutMuda,x.replace(/\.mods\.\d+/,'.mods[]').split(':')[0],it.n)});
 d=[];draw();draw();var s3=SN();diff(s2,s3,'',d);d.forEach(function(x){add(R.drawMuda,x.replace(/\.mods\.\d+/,'.mods[]').split(':')[0],it.n)});
 d=[];__build();__build();var s4=SN();diff(s3,s4,'',d);d.forEach(function(x){add(R.buildMuda,x.replace(/\.mods\.\d+/,'.mods[]').split(':')[0],it.n)});
 var a=sig(m),b=sig(m);if(a!==b)R.naoIdempotente.push(it.n);
 /* salvar e reabrir duas vezes: tem que ser ponto fixo */
 var t1=JSON.stringify(snapState());loadState(JSON.parse(t1));draw();var t2=JSON.stringify(snapState());loadState(JSON.parse(t2));draw();var t3=JSON.stringify(snapState());
 if(t1!==t2){d=[];diff(JSON.parse(t1),JSON.parse(t2),'',d);d.forEach(function(x){add(R.reabrirMuda,x.replace(/\.mods\.\d+/,'.mods[]').split(':')[0],it.n)})}
 if(t2!==t3)R.reabrirNaoEstavel.push(it.n);
 m=S.mods[S.mods.length-1];S.m=m;if(sig(m)!==a)R.reabrirMudaPecas.push(it.n);
 /* edição incremental (largura, altura, profundidade) x projeto reaberto: o 3D e as peças têm que ser iguais */
 m.w=Math.round(m.w+100);m.h=Math.round(m.h-50);m.d=Math.round(m.d-20);draw();__build();var pi=sig(m),bi=bsig();
 var t4=JSON.stringify(snapState());loadState(JSON.parse(t4));draw();m=S.mods[S.mods.length-1];S.m=m;__build();var pr=sig(m),br=bsig();
 if(bi!==br)R.incrementalDif3D.push(it.n);if(pi!==pr)R.incrementalDifPecas.push(it.n);
}catch(e){R.erros.push(it.n+': '+String(e).slice(0,120))}}
R.errsJS=__errs.slice(e0,e0+10);R.nErrsJS=__errs.length-e0;
var cnt=function(o){var r={};Object.keys(o).forEach(function(k){r[k]=o[k].length+' ex: '+o[k].slice(0,3).join(' | ')});return r};
R.partsOfMuda=cnt(R.partsOfMuda);R.drawMuda=cnt(R.drawMuda);R.buildMuda=cnt(R.buildMuda);R.cutMuda=cnt(R.cutMuda);R.reabrirMuda=cnt(R.reabrirMuda);
return JSON.stringify(R);
