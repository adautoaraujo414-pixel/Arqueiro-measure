/* Alterar uma medida e voltar ao valor inicial preserva exatamente dados, peças, plano de corte e 3D, e os avisos somem (regra GEO-AVISA de 16/11).
   Pelo caminho do app (setv, como o campo do painel), em cada modelo do catálogo sozinho numa parede, e no ambiente (parede e pé-direito) na cozinha demo.
   Cada mudança é uma ação separada (espera entre elas), como a pessoa faz. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var NRM=function(o){(o.mods||[]).concat(o.m?[o.m]:[]).forEach(function(m){if(m&&m.wing===undefined)m.wing=0});if(o.amb===undefined)o.amb={};return o};
var SN=function(){return JSON.stringify(NRM(JSON.parse(JSON.stringify(snapState()))))};
var sigP=function(){return S.mods.map(function(m){return partsOf(m).map(function(p){return p.pk+' '+p.cl+'x'+p.cw+' q'+(p.qty||1)}).sort().join(';')}).join('#')};
var sigC=function(){return JSON.stringify(cutGroups())};
var sigB=function(){__build();return __boxes().map(function(q){return (q.nm||'')+'|'+(q.pk||'')+'@'+[q.x0,q.x1,q.y0,q.y1,q.z0,q.z1].map(function(v){return Math.round(v)}).join(',')}).sort().join(';')};
var av=function(){return window.fgConflitos?fgConflitos().length:-1};
var tudo=function(){return {d:SN(),p:sigP(),c:sigC(),b:sigB(),a:av()}};
var cmp=function(x,y){var o=[];['d','p','c','b'].forEach(function(k){if(x[k]!==y[k])o.push({d:'dados',p:'peças',c:'corte',b:'3D'}[k])});if(y.a!==x.a)o.push('avisos '+x.a+'→'+y.a);return o};
var V={},ex=function(k,t){(V[k]=V[k]||[]).push(t)},N=0;draw();open3D();await W(300);
var CAMPOS=[['w',150],['w',-150],['h',-120],['h',120],['d',-60],['b',300],['x',200]];
for(var i=0;i<its.length;i++){var it=its[i];loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=8000;S.H=3000;draw();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];if(!m)continue;S.m=m;draw();await W(5);
 var base=SN();loadState(JSON.parse(base));draw();await W(5);m=S.mods[0];S.m=m;var t0=tudo();N++;
 for(var c=0;c<CAMPOS.length;c++){var k=CAMPOS[c][0],v0=+m[k]||0;S.m=m;setv(k,v0+CAMPOS[c][1]);await W(2);S.m=m;setv(k,v0);await W(2);var t1=tudo(),d=cmp(t0,t1);if(d.length)ex(k+(CAMPOS[c][1]>0?'+':'')+CAMPOS[c][1],it.n+': '+d.join(', '));loadState(JSON.parse(base));draw();m=S.mods[0];S.m=m}
 /* espessura (configuração do módulo) */
 var e0=+m.esp||15;snap();m.esp=e0+3;draw();await W(2);m.esp=e0;draw();await W(2);var t2=tudo(),d2=cmp(t0,t2);if(d2.length)ex('esp+3',it.n+': '+d2.join(', '));
 /* ambiente: parede e pé-direito */
 loadState(JSON.parse(base));draw();m=S.mods[0];S.m=m;setv('W',2000);await W(2);setv('W',8000);await W(2);var t3=tudo(),d3=cmp(t0,t3);if(d3.length)ex('parede 8000→2000→8000',it.n+': '+d3.join(', '));
 loadState(JSON.parse(base));draw();m=S.mods[0];S.m=m;setv('H',1500);await W(2);setv('H',3000);await W(2);var t4=tudo(),d4=cmp(t0,t4);if(d4.length)ex('pé-direito 3000→1500→3000',it.n+': '+d4.join(', '))}
/* cozinha demo inteira: parede, pé-direito e cada módulo */
draw();demoScene();await W(400);draw();var b0=SN();loadState(JSON.parse(b0));draw();await W(5);var z0=tudo(),R2=[];
[['W',3000],['W',2400],['H',2300],['H',2000]].forEach(function(){});
for(var q of [['W',3000],['W',2400],['H',2300],['H',2000]]){loadState(JSON.parse(b0));draw();await W(5);var o_=q[0]==='W'?S.W:S.H;S.m=S.mods[0];setv(q[0],q[1]);await W(2);var mid=av();setv(q[0],o_);await W(2);var z1=tudo(),dz=cmp(z0,z1);R2.push(q[0]+' '+o_+'→'+q[1]+'→'+o_+': avisos no meio '+mid+' · '+(dz.length?dz.join(', '):'tudo igual e sem aviso'))}
for(var j=0;j<9;j++){loadState(JSON.parse(b0));draw();await W(5);var mm=S.mods[j];S.m=mm;var w0=mm.w;setv('w',w0+100);await W(2);S.m=mm;setv('w',w0);await W(2);var z2=tudo(),dj=cmp(z0,z2);if(dj.length)R2.push('módulo '+j+' largura +100 e volta: '+dj.join(', '))}
var R={modelos:N,trocasPorModelo:CAMPOS.length+3,diferencas:{},cozinhaDemo:R2};Object.keys(V).forEach(function(k){R.diferencas[k]=V[k].length+' :: '+V[k].slice(0,4).join(' ‖ ')});
return JSON.stringify(R);
