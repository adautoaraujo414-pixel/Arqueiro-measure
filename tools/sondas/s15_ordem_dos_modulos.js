window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
draw();demoScene();await W(400);draw();var base=snapState();base.mods.forEach(function(m,i){m.uid=m.uid||('M'+i)});var bs=JSON.stringify(base);
var srt=function(o){var r={};Object.keys(o).sort().forEach(function(k){r[k]=o[k]});return r};var key=function(){var o={};S.mods.forEach(function(m){o[m.uid]=[Math.round(m.x*10)/10,m.w,m.h,m.b||0,m.d,!!m.tl,!!m.tr].join('/')});return srt(o)};
var sigP=function(){var o={};S.mods.forEach(function(m){o[m.uid]=partsOf(m).map(function(p){return p.pk+' '+Math.round(p.cl)+'x'+Math.round(p.cw)}).sort().join(';')});return srt(o)};
var perm=[[0,1,2,3,4,5,6,7,8],[8,7,6,5,4,3,2,1,0],[2,0,1,5,3,4,8,6,7],[5,4,3,2,1,0,8,7,6]];
/* cenário 1: só abrir; cenário 2: abrir e encolher a parede 300 */
var res=[];[0,300].forEach(function(enc){var ref=null,refP=null;perm.forEach(function(p,pi){var o=JSON.parse(bs);o.mods=p.map(function(i){return o.mods[i]});o.W-=enc;loadState(o);draw();draw();var k=JSON.stringify(key()),q=JSON.stringify(sigP());if(ref===null){ref=k;refP=q}else res.push('parede -'+enc+' ordem '+pi+': posições '+(k===ref?'iguais':'DIFERENTES')+' · peças '+(q===refP?'iguais':'DIFERENTES')+(k===ref?'':' · '+JSON.stringify(Object.keys(key()).filter(function(x){return key()[x]!==JSON.parse(ref)[x]}).map(function(x){return x+': '+JSON.parse(ref)[x]+' vs '+key()[x]}))))})});
R.ordem=res;return JSON.stringify(R);
