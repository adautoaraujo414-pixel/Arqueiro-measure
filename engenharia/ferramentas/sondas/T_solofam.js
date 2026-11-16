/* XP-PK-SOLO (bateria de 93495d1, 16/11): entrar e sair do "2D só dele" troca o vão por uma cópia igual (editor por vãos).
   As cores das peças (pc), o ajuste do 3D (po) e a peça tirada pelo 🗑 (xp) não podem mudar: em todo o catálogo, nada muda sozinho (antes: 34 de 142 modelos perdiam). */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});var bad=[],n=0,e0=__errs.length;
var mt=MAT.filter(function(c){return c.cat==='wood'}).slice(0,4);
for(var i=0;i<its.length;i++){var it=its[i];S.mods=[];S.stones=[];S.fr=[];S.rp=[];S.room='cozinha';S.env='cozinha';S.W=6000;S.H=2700;if(window.SOLO2)soloOff();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[S.mods.length-1];if(!m)continue;
 m.pc={};m.po={};var ps=partsOf(m);ps.forEach(function(p,j){if(p.pk){var c=mt[j%mt.length];m.pc[p.pk]={c:c.hex,n:c.n,id:c.id}}});var por=ps.filter(function(p){return /^Porta|^Frente/.test(p.name)&&p.pk})[0];if(por)m.po[por.pk]={dx:3};var pr=ps.filter(function(p){return /^Prateleira|^Porta/.test(p.name)&&p.pk&&p!==por})[0];if(pr){m.xp=[{pk:pr.pk,vi:pr.vi===undefined?-1:pr.vi,n:pr.name}];SPC={}}
 S.m=m;draw();await W(5);var a=JSON.stringify({pc:m.pc,po:m.po,xp:m.xp||[]});n++;
 document.getElementById('plsolo').click();await W(5);document.getElementById('plsolo').click();await W(5);draw();
 var b=JSON.stringify({pc:m.pc,po:m.po,xp:m.xp||[]});if(a!==b){var A=JSON.parse(a),B=JSON.parse(b);bad.push(it.n+': pc '+Object.keys(A.pc).length+'→'+Object.keys(B.pc).length+' po '+Object.keys(A.po).length+'→'+Object.keys(B.po).length+' tiradas '+A.xp.length+'→'+B.xp.length)}}
if(window.SOLO2)soloOff();return JSON.stringify({modelos:n>130,mudouSozinho:bad.length+(bad.length?': '+bad.slice(0,6).join(' | '):''),errs:__errs.length-e0})
