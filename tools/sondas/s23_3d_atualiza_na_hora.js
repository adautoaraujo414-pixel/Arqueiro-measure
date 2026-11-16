/* Com o 3D aberto: a edição aparece no 3D sem fechar e abrir?
   Para cada edição, compara as caixas do 3D logo depois (sem montar à mão) com as caixas montadas do zero.
   "atrasado" = o que está na tela é diferente do projeto atual. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var bs=function(){return __boxes().filter(function(q){return q.pk}).map(function(q){return (q.nm||'').split(':')[0]+'|'+q.pk+'@'+[q.x0,q.x1,q.y0,q.y1,q.z0,q.z1].map(function(v){return Math.round(v)}).join(',')}).sort().join(';')};
var base=null;draw();demoScene();await W(400);draw();base=JSON.stringify(snapState());
var E={
 'largura pelo campo (setv w)':function(){S.m=S.mods[1];setv('w',S.m.w+100)},
 'altura pelo campo (setv h)':function(){S.m=S.mods[1];setv('h',S.m.h-100)},
 'posição pelo campo (setv x)':function(){S.m=S.mods[2];setv('x',S.m.x+60)},
 'parede (setv W)':function(){setv('W',S.W-200)},
 'pé-direito (setv H)':function(){setv('H',S.H-200)},
 'tamponamento esquerdo pelo Usar':function(){S.m=S.mods[1];snap();S.m.tl=true;S.m.tlM=1;draw()},
 'tirar tamponamento (tpDesliga)':function(){S.m=S.mods[0];tpDesliga(S.m,'tr');draw()},
 'vão vira gavetas':function(){S.m=S.mods[1];snap();S.m.v[0].k='drawers';S.m.v[0].n=3;draw()},
 'apagar módulo (splice + draw)':function(){S.mods.splice(2,1);S.m=S.mods[0];draw()},
 'desfazer (↶)':function(){S.m=S.mods[1];LASTT=0;histTick();setv('w',S.m.w+150);LASTT=0;histTick();document.getElementById('und').onclick()},
 'pedra mais grossa':function(){snap();S.stones[0].e=(+S.stones[0].e||30)+20;draw()}
};
var out={};
for(var k in E){loadState(JSON.parse(base));draw();open3D();await W(300);var antes=bs();try{E[k]()}catch(e){out[k]='exceção '+e;continue}await W(400);var tela=bs();__build();var certo=bs();
 out[k]=(tela===certo?'atualizou na hora':(tela===antes?'ATRASADO: o 3D continua igual ao de antes':'ATRASADO: o 3D mudou, mas diferente do projeto'))+(certo===antes?' (a edição não muda o 3D)':'')}
return JSON.stringify(out);
