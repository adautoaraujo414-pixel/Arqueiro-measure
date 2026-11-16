window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var st=function(m){return 'x='+Math.round(m.x*10)/10+' tl='+(m.tl?1:0)+(m.tlAuto?'a':'')};
var cena=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;draw();newTpl(T('Balcão 2 portas'));draw();var m=S.mods[0];S.m=m;setv('x',800);return m};
var fire=function(k){var i=document.querySelector('[data-k="'+k+'"]');if(i){i.dispatchEvent(new Event('change',{bubbles:true}))}};
var typ=function(k,v){setv(k,v);fire(k)};
var out=[];var m=cena();[5,15,25,35,45,25,5,0,25,800,25].forEach(function(x){typ('x',x);out.push('digitou '+x+' → '+st(S.mods[0]))});R.digitandoX=out;
/* mesma entrada (25) de começos diferentes */
var r2=[];cena();typ('x',25);r2.push('800→25: '+st(S.mods[0]));cena();typ('x',45);typ('x',25);r2.push('45→25: '+st(S.mods[0]));cena();typ('x',5);typ('x',25);r2.push('5→25: '+st(S.mods[0]));R.mesmaEntrada25=r2;
/* parede e pé-direito pelo campo, na cozinha demo */
draw();demoScene();await W(400);draw();var base=JSON.stringify(snapState());var dims=function(){return S.mods.map(function(m){return [Math.round(m.x),m.w,m.h,m.b||0].join('/')}).join(' ')};
var a0=dims();S.m=S.mods[0];typ('W',S.W-300);typ('W',S.W+300);R.paredeDigitada=a0===dims()?'voltou igual':{antes:a0,depois:dims()};
loadState(JSON.parse(base));draw();a0=dims();S.m=S.mods[0];typ('H',S.H-400);typ('H',S.H+400);R.peDireitoDigitado=a0===dims()?'voltou igual':{antes:a0,depois:dims()};
return JSON.stringify(R);
