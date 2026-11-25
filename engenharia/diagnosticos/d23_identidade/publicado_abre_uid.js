window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&!t.act&&t.w&&t.h&&its.indexOf(t)<0)its.push(t)})});
var dif=0,perde=0,n=0;its.forEach(function(t,i){try{loadState(initLimpo());S.W=8000;S.mods=[];draw();newTpl(JSON.parse(JSON.stringify(t)));draw()}catch(e){return}var st=JSON.parse(JSON.stringify(snapState()));
 var sig=function(){return JSON.stringify(S.mods.map(function(m){return partsOf(m)}))+JSON.stringify(cutGroups().ord)};loadState(JSON.parse(JSON.stringify(st)));draw();var a=sig();
 var st2=JSON.parse(JSON.stringify(st));(st2.mods||[]).forEach(function(m,j){m.uid='uTESTE'+i+'x'+j});if(st2.m)st2.m.uid=st2.mods[st2.mi]?st2.mods[st2.mi].uid:st2.m.uid;loadState(st2);draw();var b=sig();n++;if(a!==b)dif++;var sv=snapState();if(!(sv.mods||[]).every(function(m,j){return m.uid==='uTESTE'+i+'x'+j}))perde++});
R.modelos=n;R.pecasECorteDiferentes=dif;R.uidPerdidoAoSalvar=perde;R.erros=__errs.length-e0;return JSON.stringify(R);
