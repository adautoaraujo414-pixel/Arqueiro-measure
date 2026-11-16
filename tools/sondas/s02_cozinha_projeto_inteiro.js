window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var SN=function(){return JSON.parse(JSON.stringify(snapState()))};
function diff(a,b,p,out){if(out.length>30)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+': '+JSON.stringify(a).slice(0,60)+' -> '+JSON.stringify(b).slice(0,60));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var sig=function(m){return partsOf(m).map(function(p){return p.pk+' '+Math.round(p.cl*10)/10+'x'+Math.round(p.cw*10)/10+' q'+(p.qty||1)+' '+(p.mat||'')}).sort().join(';')};
var bsig=function(){return __boxes().filter(function(q){return q.pk}).map(function(q){return (q.nm||'').split(':')[0]+'|'+q.pk+'@'+[q.x0,q.x1,q.y0,q.y1,q.z0,q.z1].map(function(v){return Math.round(v)}).join(',')}).sort()};
var cut=function(){return JSON.stringify(cutGroups())};
var R={};var e0=__errs.length;
draw();open3D();await W(400);demoScene();await W(800);draw();__build();
R.modulos=S.mods.length;R.pedras=(S.stones||[]).length;
/* 1. só olhar (partsOf, corte, draw, build, abrir/fechar 3D) não muda o projeto */
var s0=SN();S.mods.forEach(function(m){partsOf(m)});cutGroups();draw();__build();var d=[];diff(s0,SN(),'',d);R.olharMuda=d;
/* 2. salvar e reabrir o projeto inteiro: peças, corte e 3D iguais */
var P0=S.mods.map(sig),C0=cut(),B0=bsig(),t1=JSON.stringify(snapState());loadState(JSON.parse(t1));draw();__build();
var P1=S.mods.map(sig),C1=cut(),B1=bsig();R.reabrirPecasDif=P0.filter(function(x,i){return x!==P1[i]}).length;R.reabrirCorteIgual=C0===C1;
var bd=B0.filter(function(x){return B1.indexOf(x)<0}),bd2=B1.filter(function(x){return B0.indexOf(x)<0});R.reabrir3D={so_antes:bd.length,so_depois:bd2.length,ex:bd.slice(0,4).concat(bd2.slice(0,4))};
d=[];diff(JSON.parse(t1),SN(),'',d);R.reabrirMudaDados=d;
/* 3. edição incremental em cada módulo x reaberto */
var inc=[];for(var i=0;i<S.mods.length;i++){var m=S.mods[i];S.m=m;var w0=m.w;m.w=Math.round(m.w-50);draw();__build();var a=S.mods.map(sig).join('#'),b=bsig().join(';'),c=cut();var t=JSON.stringify(snapState());loadState(JSON.parse(t));draw();__build();var a2=S.mods.map(sig).join('#'),b2=bsig().join(';'),c2=cut();if(a!==a2||b!==b2||c!==c2)inc.push((S.mods[i].n||S.mods[i].t)+' pecas '+(a===a2)+' 3d '+(b===b2)+' corte '+(c===c2));S.mods[i].w=w0;draw()}
R.incrementalXReaberto=inc;
/* 4. módulo isolado x no projeto */
var iso=[];var full=JSON.stringify(snapState());var all=JSON.parse(full);
for(var j=0;j<all.mods.length;j++){var o=JSON.parse(full);loadState(o);draw();var pj=sig(S.mods[j]);var o2=JSON.parse(full);o2.mods=[o2.mods[j]];o2.stones=[];loadState(o2);draw();var pi=sig(S.mods[0]);if(pj!==pi){var A=pj.split(';'),B=pi.split(';');iso.push((S.mods[0].n||S.mods[0].t)+': so_no_projeto='+A.filter(function(x){return B.indexOf(x)<0}).slice(0,3).join(' , ')+' || so_isolado='+B.filter(function(x){return A.indexOf(x)<0}).slice(0,3).join(' , '))}}
R.isoladoXProjeto=iso;loadState(JSON.parse(full));draw();
/* 5. desfazer: mexer e desfazer volta exatamente ao que era */
var u0=JSON.stringify(snapState());histTick();var m=S.mods[0];S.m=m;m.w+=120;draw();histTick();LASTT=0;await W(800);S.mods[1].h-=40;draw();histTick();await W(800);
document.getElementById('und').onclick();await W(50);document.getElementById('und').onclick();await W(50);var u1=JSON.stringify(snapState());d=[];diff(JSON.parse(u0),JSON.parse(u1),'',d);R.desfazerVolta=d.length?d:'igual';
/* 6. ambiente: mudar largura da parede e voltar não muda os módulos */
var a0=JSON.stringify(S.mods.map(function(m){return [m.x,m.w,m.h,m.d,m.y]}));var W0=S.W;S.W=W0-800;draw();S.W=W0;draw();var a1=JSON.stringify(S.mods.map(function(m){return [m.x,m.w,m.h,m.d,m.y]}));R.paredeEncolheVolta=a0===a1?'igual':{antes:a0,depois:a1};
R.nErrsJS=__errs.length-e0;R.errsJS=__errs.slice(e0,e0+8);
return JSON.stringify(R);
