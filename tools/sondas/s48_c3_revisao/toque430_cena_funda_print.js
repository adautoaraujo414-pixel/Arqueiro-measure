window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var res=[],BL={},last=null;
for(var wi=0;wi<4;wi++){var WW=[3000,4600,6000,8000][wi];for(var di=0;di<3;di++){var LX=[0,2000,5000][di];
 loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=WW;S.H=2700;draw();newTpl(T('Guarda-roupa 2 vãos'));var m=S.mods[0];m.x=WW-m.w-50;
 if(LX){newTpl(T('Balcão 2 portas'));var b=S.mods[1];b.wing=2;b.x=LX;}S.m=null;draw();PLV=true;draw();await W(120);
 var g=document.querySelector('#svg [data-pm="0"]'),gr=g?g.getBoundingClientRect():null,tot=0,ok=0,bt=0;
 if(gr){for(var fx=.05;fx<1;fx+=.1)for(var fy=.05;fy<1;fy+=.1){var x=gr.left+gr.width*fx,y=gr.top+gr.height*fy;tot++;var el=document.elementFromPoint(x,y);if(el&&el.closest&&el.closest('[data-pm="0"]'))ok++;else if(el&&/lockAll|delMod|cutc/.test(el.id||(el.closest('button')||{}).id||''))bt++}}
 res.push('W'+WW+' lado'+(LX||'-')+': pega '+ok+'/'+tot+' botão por cima '+bt);if(WW===8000&&LX===5000)last=gr;PLV=false;draw()}}
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=8000;S.H=2700;draw();newTpl(T('Guarda-roupa 2 vãos'));var m=S.mods[0];m.x=8000-m.w-50;newTpl(T('Balcão 2 portas'));S.mods[1].wing=2;S.mods[1].x=5000;S.m=null;draw();PLV=true;draw();await W(300);
var g=document.querySelector('#svg [data-pm="0"]').getBoundingClientRect();var d=document.createElement('div');d.style.cssText='position:fixed;pointer-events:none;border:2px dashed red;z-index:99999;left:'+g.left+'px;top:'+g.top+'px;width:'+g.width+'px;height:'+g.height+'px';document.body.appendChild(d);
document.getElementById('svg').scrollIntoView({block:'center'});await W(200);
return res.join(' | ');
