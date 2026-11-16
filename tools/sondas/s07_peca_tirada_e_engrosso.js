window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var clr=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.room='livre';S.env='livre';S.W=6000;S.RD=3500;S.H=3000;S.m=null};
var R={N:0,apagadaContinua:{},apagadaNoCorte:{},custoNaoMuda:{}};var add=function(o,k,v){(o[k]=o[k]||[]).push(v)};draw();
for(var i=0;i<its.length;i++){var it=its[i];clr();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[S.mods.length-1];if(!m)continue;R.N++;S.m=m;draw();
 var base=JSON.stringify(m),pks={};partsOf(m).forEach(function(p){if(p.pk)pks[p.pk]=p.name});
 Object.keys(pks).forEach(function(pk){S.mods[0]=JSON.parse(base);m=S.mods[0];S.m=m;m.xp=(m.xp||[]).concat([{pk:pk}]);draw();
   var still=partsOf(m).some(function(p){return p.pk===pk});if(still)add(R.apagadaContinua,pks[pk].replace(/#.*/,''),it.n);
   var nm=pks[pk];var inCut=cutLines(m).some(function(l){return (l.names||[]).some(function(n){return n===nm})&&false});});
 S.mods[0]=JSON.parse(base);}
var cnt=function(o){var r={};Object.keys(o).forEach(function(k){r[k]=o[k].length+' :: '+o[k].slice(0,3).join(' | ')});return r};
R.apagadaContinua=cnt(R.apagadaContinua);
/* E3: engrosso some com egOn desligado no aparelho */
clr();var t=its.filter(function(x){return /Balcão 2 portas/.test(x.n)})[0];newTpl(JSON.parse(JSON.stringify(t)));var m=S.mods[0];S.m=m;
var on0=PR.std&&PR.std.egOn;try{PR.std=PR.std||{};PR.std.egOn=1}catch(e){}m.egL=30;m.egR=30;draw();var a=m.egL+'/'+m.egR+' pecas '+partsOf(m).filter(function(p){return /ngrosso/.test(p.name)}).length;
PR.std.egOn=0;draw();var b=m.egL+'/'+m.egR;PR.std.egOn=1;draw();var c=m.egL+'/'+m.egR+' pecas '+partsOf(m).filter(function(p){return /ngrosso/.test(p.name)}).length;
R.E3='ligado: '+a+' · desliga no aparelho: '+b+' · religa: '+c+' · STD().egOn='+STD().egOn;PR.std.egOn=on0;
return JSON.stringify(R);
