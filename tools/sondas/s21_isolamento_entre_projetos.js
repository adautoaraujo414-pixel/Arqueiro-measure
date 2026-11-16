/* Isolamento entre projetos na mesma página (como o app abre outro projeto pela lista do editor: CUR=p.id; loadState(p.current)).
   B aberto "limpo" x B aberto depois de mexer em A (3D, foco, só ele, seleção, câmera, ambiente, travas de tela).
   Compara o que a pessoa vê e o que vai pra fábrica, e lista as variáveis globais que ficaram de A. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var glob=function(){var o={};Object.keys(window).forEach(function(k){try{var v=window[k];if(v===null||typeof v==='number'||typeof v==='boolean'||typeof v==='string'&&v.length<60)o[k]=v;else if(v&&typeof v==='object'&&!Array.isArray(v)&&Object.getPrototypeOf(v)===Object.prototype&&k.length<12)o[k]=JSON.stringify(v).slice(0,80)}catch(_){}});return o};
var vis=function(){draw();var svg=document.getElementById('svg');open3D();__build();var bx=__boxes(),mods={};bx.forEach(function(q){var mi=parseInt(String(q.nm),10);if(!isNaN(mi))mods[mi]=(mods[mi]||0)+1});
  return {mods2D:svg.querySelectorAll('#mod').length,caixas3D:bx.length,modulosNo3D:Object.keys(mods).length,de:S.mods.length,
   pecas:S.mods.map(function(m){return partsOf(m).length}).join(','),corte:JSON.stringify(cutGroups()).length,sel:S.mods.indexOf(S.m),tab:S.tab,sv:S.sv,
   cam:(window.org3api&&org3api.cam?JSON.stringify(org3api.cam()):'?')}};
/* B */
var mkB=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2600;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();return JSON.parse(JSON.stringify(snapState()))};
draw();var B=mkB();loadState(JSON.parse(JSON.stringify(B)));draw();await W(300);var g0=glob(),v0=vis();var x=document.getElementById('v3x');if(x)x.click();await W(200);g0=glob();
/* A: cozinha demo e mexe em tudo que é "de tela" */
demoScene();await W(400);draw();open3D();await W(300);var feito=[];
try{focOn(1);feito.push('foco no módulo 1')}catch(e){feito.push('foco: '+e)}
try{S.m=S.mods[2];soloOn(S.mods[2]);feito.push('só ele no 2D')}catch(e){feito.push('solo: '+e)}
try{__cam(1.1,0.4,2.2);feito.push('câmera')}catch(e){}
try{ambSet(1);feito.push('editor de ambiente')}catch(e){feito.push('amb: '+e)}
try{window.PSEL={mi:2,pk:'Porta#1'};window.DIVI=0;window.LAST='div';feito.push('peça e divisória escolhidas')}catch(e){}
S.tab=3;S.sv=1;draw();await W(200);
/* abre B como o app faz (mesma página) */
/* abre B como o app abre (lista do editor: CUR=p.id; loadState) */var a_=pLoadAll().filter(function(q){return q.id!=='pS21'});a_.push({id:'pS21',client:{nome:'B'},created:1,updated:1,current:B});pSaveAll(a_);var pb_=pLoadAll().filter(function(q){return q.id==='pS21'})[0];CUR=pb_.id;loadState(pb_.current);draw();await W(300);var x2=document.getElementById('v3x');var g1=glob(),v1=vis();
var dif={};Object.keys(v0).forEach(function(k){if(String(v0[k])!==String(v1[k]))dif[k]=v0[k]+' → '+v1[k]});
var gd=[];Object.keys(g1).forEach(function(k){if(!(k in g0)||g0[k]!==g1[k])gd.push(k+'='+JSON.stringify(g1[k]).slice(0,40)+(k in g0?' (limpo: '+JSON.stringify(g0[k]).slice(0,30)+')':' (não existia)'))});
pSaveAll(pLoadAll().filter(function(q){return q.id!=='pS21'}));return JSON.stringify({feitoEmA:feito,B_limpo:v0,B_depoisDeA:v1,diferencas:dif,globaisQueFicaramDeA:gd.slice(0,60),totalGlobaisDiferentes:gd.length});
