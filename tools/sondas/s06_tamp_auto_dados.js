window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var all=TPL.concat(CATS.flatMap(function(c){return c.it})),T=function(n){return JSON.parse(JSON.stringify(all.filter(function(i){return i.n===n})[0]))};
var clr=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.room='livre';S.env='cozinha';S.W=3000;S.RD=3000;S.H=2700;S.m=null};
var st=function(m){return 'x='+m.x+' w='+m.w+' tl='+!!m.tl+(m.tlAuto?'(auto)':'')+' tr='+!!m.tr+(m.trAuto?'(auto)':'')+' y='+(m.b||0)};
var R={};draw();
/* A: um módulo sozinho no meio da parede */
clr();newTpl(T('Balcão 2 portas'));var a=S.mods[0];draw();R.A0=st(a);a.x=800;draw();R.A1_meio=st(a);
/* B: vizinho encosta do lado direito e depois sai */
newTpl(T('Balcão 1 porta'));var b=S.mods[S.mods.length-1];b.x=a.x+a.w;draw();R.B1_vizinho=st(a)+' | viz '+st(b);
S.mods.splice(S.mods.indexOf(b),1);S.m=a;draw();R.B2_saiu=st(a);
/* C: arrastar pra parede esquerda e voltar */
a.x=0;draw();R.C1_naParede=st(a);a.x=800;draw();R.C2_volta800=st(a);
/* D: ida e volta de posição perto da parede (15–35 mm) */
var D=[];[5,15,25,35,45,25,5].forEach(function(x){a.x=x;draw();D.push(x+'→'+st(a))});R.D=D;
/* E: desenhar 5x seguidas não muda nada (estável) */
a.x=20;draw();var e0=JSON.stringify(a);for(var i=0;i<5;i++)draw();R.E_estavel=e0===JSON.stringify(a);
return JSON.stringify(R);
