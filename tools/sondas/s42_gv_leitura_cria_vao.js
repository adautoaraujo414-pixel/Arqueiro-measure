/* Fase 2 · risco do gv (16/11): ler um vão fora dos vãos do módulo (divisórias + 1) cria vãos fantasma no módulo.
   (1) o risco em si: gv(5) num módulo de 1 vão — a função ainda faz isso (mudança da função está pra aprovação);
   (2) o caminho que levava até lá: escolher outro módulo pelo 3D e ler o vão escolhido — com SEL-VAO o vão escolhido é válido e nada é criado. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.W=4000;draw();newTpl(T('Balcão 1 porta'));var m=S.mods[0];var n0=m.v.length;gv(5,m);R.risco='vãos antes '+n0+' · depois de ler gv(5): '+m.v.length+' (divisórias '+m.div.length+')';
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();var A=S.mods[0],B=S.mods[1];A.div=[1/3,2/3];A.v=[{k:'door',n:1},{k:'door',n:1},{k:'door',n:1}];B.v=[{k:'door',n:1}];B.div=[];B.x=A.x+A.w+400;draw();S.m=A;S.sv=2;panel();draw();
open3D();await W(400);__build();var p=org3api.proj([B.x+B.w/2,B.b+B.h/2,B.d+20]);__sel3(p[0],p[1]);await W(500);gv(S.sv);R.caminho3D='escolhido B '+(S.m===B)+' · vão '+S.sv+' · vãos de B depois de ler o vão escolhido: '+B.v.length;var x3=document.getElementById('v3x');if(x3)x3.click();
return JSON.stringify(R);
