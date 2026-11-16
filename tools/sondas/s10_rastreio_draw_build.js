window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
__TRACER__
function diff(a,b,p,out){if(out.length>20)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+'='+JSON.stringify(a)+'→'+JSON.stringify(b));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var R={cenarios:{}};draw();open3D();await W(300);
var run=async function(nome,prep){var st=prep();loadState(JSON.parse(st));
  /* 1º draw depois de abrir (normalização) */
  hookAll();TR.log={};TR.on=true;draw();TR.on=false;var L1=TR.log;var s1=JSON.stringify(snapState());
  /* draws seguintes sem ação: tem que ser nada */
  hookAll();TR.log={};TR.on=true;for(var i=0;i<5;i++)draw();TR.on=false;var L2=TR.log;var s2=JSON.stringify(snapState());
  hookAll();TR.log={};TR.on=true;__build();__build();TR.on=false;var L3=TR.log;var s3=JSON.stringify(snapState());
  var d12=[],d23=[],d01=[];diff(JSON.parse(s1),JSON.parse(s2),'',d12);diff(JSON.parse(s2),JSON.parse(s3),'',d23);diff(JSON.parse(st),JSON.parse(s1),'',d01);
  R.cenarios[nome]={abrirEDesenhar_muda:d01.slice(0,10),desenharDeNovo_muda:d12,build_muda:d23,escritas_1oDraw:L1,escritas_drawsSeguintes:L2,escritas_build:L3}};
await run('cozinha demo',function(){demoScene();draw();return JSON.stringify(snapState())});
await run('cozinha demo com parede 3300',function(){demoScene();draw();var o=snapState();o.W=3300;return JSON.stringify(o)});
/* catálogo inteiro numa parede grande, cada modelo isolado: soma as escritas */
var AGG={a:{},b:{},c:{}},nd=0,nb=0;
for(var i=0;i<its.length;i++){var it=its[i];loadState(initLimpo());S.env='cozinha';S.W=6000;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(it)));draw();var st=JSON.stringify(snapState());loadState(JSON.parse(st));
 hookAll();TR.log={};TR.on=true;draw();TR.on=false;var s1=JSON.stringify(snapState());Object.keys(TR.log).forEach(function(k){(AGG.a[k]=AGG.a[k]||[]).push(it.n)});
 hookAll();TR.log={};TR.on=true;for(var j=0;j<3;j++)draw();TR.on=false;var s2=JSON.stringify(snapState());if(s1!==s2)nd++;Object.keys(TR.log).forEach(function(k){(AGG.b[k]=AGG.b[k]||[]).push(it.n)});
 hookAll();TR.log={};TR.on=true;__build();TR.on=false;if(JSON.stringify(snapState())!==s2)nb++;Object.keys(TR.log).forEach(function(k){(AGG.c[k]=AGG.c[k]||[]).push(it.n)})}
var cnt=function(o){var r={};Object.keys(o).forEach(function(k){r[k]=o[k].length+' :: '+o[k].slice(0,2).join(' | ')});return r};
R.catalogo={modelos:its.length,desenharDeNovoMudou:nd,buildMudou:nb,escritas_abrir:cnt(AGG.a),escritas_drawsSeguintes:cnt(AGG.b),escritas_build:cnt(AGG.c)};
return JSON.stringify(R);
