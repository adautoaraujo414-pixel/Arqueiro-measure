window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var clr=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.room='livre';S.env='livre';S.W=6000;S.RD=3500;S.H=3000;S.m=null};
var sig=function(m){return partsOf(m).map(function(p){return p.pk+' '+Math.round(p.cl*10)/10+'x'+Math.round(p.cw*10)/10+' q'+(p.qty||1)}).sort().join(';')};
function diff(a,b,p,out){if(out.length>6)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+'='+JSON.stringify(a)+'→'+JSON.stringify(b));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var R={N:0,num:{},bool:{},erros:[]};var add=function(o,k,v){(o[k]=o[k]||[]).push(v)};
draw();open3D();await W(300);var e0=__errs.length;
var NUM=[['w',150],['h',-120],['d',-60],['y',300],['esp',3]];
for(var i=0;i<its.length;i++){var it=its[i];try{
 clr();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[S.mods.length-1];if(!m)continue;R.N++;S.m=m;draw();
 var base=JSON.stringify(m),bs=sig(m);
 NUM.forEach(function(f){var k=f[0];if(typeof m[k]!=='number')return;var v0=m[k];m[k]=v0+f[1];draw();__build();m[k]=v0;draw();__build();
   var d=[];diff(JSON.parse(base),JSON.parse(JSON.stringify(m)),'',d);var ps=sig(m)!==bs;
   if(d.length||ps){add(R.num,k,it.n+(ps?' [PEÇAS MUDARAM]':'')+' '+d.slice(0,4).join(' '));}
   /* restaura pro próximo campo */
   S.mods[S.mods.length-1]=JSON.parse(base);m=S.mods[S.mods.length-1];S.m=m;draw()});
 Object.keys(m).forEach(function(k){var v0=m[k];if(!(v0===true||v0===false||v0===0||v0===1))return;if(/^_|^id$|^sel/.test(k))return;
   m[k]=(v0===true?false:v0===false?true:1-v0);draw();__build();m[k]=v0;draw();__build();
   var d=[];diff(JSON.parse(base),JSON.parse(JSON.stringify(m)),'',d);var ps=sig(m)!==bs;
   if(d.length||ps)add(R.bool,k,it.n+(ps?' [PEÇAS MUDARAM]':'')+' '+d.slice(0,4).join(' '));
   S.mods[S.mods.length-1]=JSON.parse(base);m=S.mods[S.mods.length-1];S.m=m;draw()});
}catch(e){R.erros.push(it.n+': '+String(e).slice(0,120))}}
var cnt=function(o){var r={};Object.keys(o).forEach(function(k){r[k]=o[k].length+' :: '+o[k].slice(0,3).join(' || ')});return r};
R.num=cnt(R.num);R.bool=cnt(R.bool);R.nErrsJS=__errs.length-e0;R.errsJS=__errs.slice(e0,e0+6);
return JSON.stringify(R);
