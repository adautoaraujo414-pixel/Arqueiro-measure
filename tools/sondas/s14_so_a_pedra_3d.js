window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
draw();demoScene();await W(400);draw();var mods=function(){return __boxes().filter(function(b){return b.sid==null&&/^\d+:/.test(String(b.nm))}).length};
open3D();await W(500);R.aberto=mods();
/* liga "👁 Só a pedra no 3D" pelo botão (clique real no elemento com data-qstonly) */
var b=document.createElement('button');b.setAttribute('data-qstonly','1');document.body.appendChild(b);b.click();b.remove();await W(200);R.soAPedra=mods();
/* fecha o 3D pelo X */
var x=document.getElementById('v3x');if(x)x.click();await W(300);R.fechou3D=!!document.getElementById('v3')&&document.getElementById('v3').hidden;
/* abre outro projeto (salva e reabre) e abre o 3D de novo */
var t=JSON.stringify(snapState());loadState(JSON.parse(t));draw();open3D();await W(600);R.reabriu3D_modulos=mods();R.ST3ONLY=window.ST3ONLY;
/* outro projeto do zero */
loadState(initLimpo());draw();demoScene();await W(400);draw();open3D();await W(600);R.outroProjeto_modulos=mods();
await W(1200);R.depoisDoDiag3=mods();
return JSON.stringify(R);
