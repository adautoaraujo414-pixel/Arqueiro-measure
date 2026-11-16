/* Cena de testParedeLateralNaoCresceSozinha (sala, parede da direita de 3170, aéreo de 1000 posto no fim da parede).
   Confere: posição persistida, medidas e peças, aviso correto (ou nenhum se cabe), salvar/reabrir e desfazer/refazer. */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var R={};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
S.stones=[];S.rp=[];S.fr=[];S.ops=[];S.env='livre';S.room='sala';S.W=4140;S.RD=3170;S.H=3400;S.Hm=1;S.Wm=1;S.mods=[];S.tz=[];S.wall={};draw();
wvGo('d');await W(60);[0,781.3,1562.6,2343.9].forEach(function(x){var a=rpNew({x:x,b:0,w:781,h:2700});a.liso=true});draw();
newTpl({n:'Aéreo',w:1000,h:750,d:350,b:1500,sup:true,v:[{k:'door',n:2,cava:true}]});draw();await W(100);
wvGo('f');await W(60);wvGo('d');await W(60);var m=S.mods[0];if(m){m.x=S.W-m.w;draw()}wvGo('f');await W(60);wvGo('d');await W(60);if(S.mods[0]){S.mods[0].x=S.W-S.mods[0].w;draw()}wvGo('f');await W(60);wvGo('d');await W(60);
m=S.mods[0];var pec=function(q){return partsOf(q).map(function(p){return p.pk+' '+p.cl+'x'+p.cw}).sort().join(';')};
var fab=function(q){return [q.x,q.b,q.w,q.h,q.d,q.esp,!!q.tl,!!q.tr].join('/')};
var st=JSON.parse(JSON.stringify(snapState()));R.persistido_x=st.mods[0].x;R.na_tela_x=m.x;R.parede=roomD();R.lado=m.wing;
R.cabe='fim do móvel '+(m.x+m.w)+(rt(m)?' + tamponamento '+rt(m):'')+' · início '+(m.x-lt(m))+' · parede '+roomD()+' → '+((m.x-lt(m)>=-0.5&&m.x+m.w+rt(m)<=roomD()+0.5)?'cabe':'NÃO cabe');
R.avisos=fgConflitos().map(function(c){return c.texto});
var p0=pec(m),f0=fab(m);
/* salvar e reabrir */
loadState(JSON.parse(JSON.stringify(st)));draw();wvGo('d');await W(60);m=S.mods[0];R.reabriu_x=m.x;R.reabriu_igual=(fab(m)===f0)+' · peças '+(pec(m)===p0);R.reabriu_avisos=fgConflitos().length;
/* desfazer e refazer (mexe noutra coisa: altura do aéreo do chão) */
histTick();LASTT=0;S.m=m;setv('b',1400);await W(20);LASTT=0;histTick();var mid=fab(S.mods[0]);document.getElementById('und').onclick();await W(20);R.desfez=fab(S.mods[0])===f0;document.getElementById('red').onclick();await W(20);R.refez=fab(S.mods[0])===mid;R.refez_x=S.mods[0].x;
R.parede_final=roomD();R.errs=__errs.length;
return JSON.stringify(R);
