/* PROPOSTA do gv (17/11) — testada SÓ NA PÁGINA DE TESTE, sem mudar o app. window.__gvModo escolhe:
     'atual' : o gv de hoje (cria vãos até o índice pedido);
     'p1'    : índice inválido (negativo, não inteiro, ≥ divisórias+1) não grava nada e devolve uma cópia padrão desligada do módulo (registra em __gvInvalidos);
               índice válido sem configuração gravada continua sendo preenchido (como hoje);
     'p2'    : p1 + leitura nunca grava: índice válido sem configuração devolve cópia padrão desligada (as edições usariam outra função, vEditar).
   Cenários: sem divisórias, várias divisórias, tirar e pôr divisórias (Limpar e de novo), trocar de módulo pelo 2D e pelo 3D, índices -1 / 1.5 / NaN / 99,
   projeto antigo com vãos sobrando, salvar/fechar/reabrir, desfazer/refazer depois de Limpar. Mede: tamanho de m.v, vão alterado, peças, corte, 3D. */
var MODO=window.__gvModo||'p1';window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};window.confirm=function(){return true};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={modo:MODO,casos:{}};
var gvAtual=gv,nvOf=function(m){return ((m&&m.div)||[]).length+1};
var padrao=function(){return S.pxDef?{k:'free',n:1,cava:S.pxDef.px==='cava',px:S.pxDef.px,pxc:S.pxDef.pxc,ow:560,oh:595,ot:3}:{k:'free',n:1,cava:STD().pux==='cava',ow:560,oh:595,ot:3}};
window.__gvInvalidos=[];
if(MODO!=='atual'){gv=window.gv=function(i,mm){var m=mm||S.m;if(!m)return padrao();var k=Number(i),n=nvOf(m);if(!(Number.isInteger(k)&&k>=0&&k<n)){window.__gvInvalidos.push(String(i)+'/'+n);return padrao()}
  if(m.v[k])return m.v[k];if(MODO==='p2')return padrao();while(m.v.length<=k)m.v.push(padrao());return m.v[k]}}
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var sig=function(m){return partsOf(m).map(function(p){return p.pk+' '+p.cl+'x'+p.cw}).sort().join(';')};
var cx3=function(){__build();return __boxes().filter(function(q){return /^0:/.test(String(q.nm))}).length};
var est=function(m){return 'divisórias '+m.div.length+' · m.v '+m.v.length+(m.v.length>m.div.length+1?' (sobra)':'')+' · tipos '+m.v.slice(0,m.div.length+1).map(function(v){return v.k}).join(',')};
var cena=function(div,v){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));var m=S.mods[0];m.x=800;m.div=div;m.v=v;S.m=m;S.sv=0;S.tab=1;draw();panel();return m};
draw();open3D();await W(200);var x3=document.getElementById('v3x');if(x3)x3.click();
/* 1. índices fora do limite em módulo sem divisórias e com várias */
for(var c of [[[],[{k:'door',n:1}]],[[0.25,0.5,0.75],[{k:'door',n:1},{k:'shelves',n:1},{k:'drawers',n:3},{k:'door',n:2}]]]){var m=cena(c[0],c[1]),p0=sig(m),n0=m.v.length,r=[];
 [-1,1.5,NaN,99,c[0].length+1].forEach(function(ix){var v=gv(ix,m);r.push(String(ix)+'→m.v '+m.v.length)});R.casos['índices ruins · '+(c[0].length?c[0].length+' divisórias':'sem divisórias')]=r.join(' · ')+' · peças iguais '+(sig(m)===p0)+' · m.v antes '+n0}
/* 2. Limpar divisões e pôr de novo; desfazer e refazer */
var m=cena([1/3,2/3],[{k:'door',n:1},{k:'shelves',n:1},{k:'drawers',n:3}]);S.sv=2;HIST=[];FUT=[];LASTS=null;histTick();LASTT=0;
[].filter.call(document.querySelectorAll('#bd button'),function(q){return /Limpar divis/.test(q.textContent)})[0].click();await W(50);LASTT=0;histTick();m=S.mods[0];var limp=est(m)+' · S.sv '+S.sv;
try{gv(S.sv)}catch(_){}var lido=est(S.mods[0]);
document.getElementById('und').onclick();await W(50);var desf=est(S.mods[0])+' · S.sv '+S.sv;document.getElementById('red').onclick();await W(50);var ref=est(S.mods[0]);
S.sv=0;S.tab=1;panel();document.querySelector('#bd [data-dvq="2"]').click();await W(50);R.casos['Limpar → ler → desfazer → refazer → pôr 2 divisórias']='limpou: '+limp+' | leu o vão escolhido: '+lido+' | desfez: '+desf+' | refez: '+ref+' | pôs 2 de novo: '+est(S.mods[0]);
/* 3. trocar de módulo pelo 2D e pelo 3D com o 3º vão escolhido */
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();newTpl(T('Balcão 2 portas'));newTpl(T('Balcão 1 porta'));draw();var A=S.mods[0],B=S.mods[1];A.div=[1/3,2/3];A.v=[{k:'door',n:1},{k:'door',n:1},{k:'door',n:1}];B.v=[{k:'door',n:1}];B.div=[];B.x=A.x+A.w+400;draw();S.m=A;S.sv=2;panel();draw();
var sv_=document.getElementById('svg'),g=[].filter.call(sv_.querySelectorAll('#mod'),function(q){return +q.dataset.mi===1})[0].querySelector('rect[data-mi]').getBoundingClientRect(),xx=g.left+g.width/2,yy=g.top+g.height/2;
[['pointerdown',null],['pointerup',sv_],['pointerup',window]].forEach(function(q){(q[1]||document.elementFromPoint(xx,yy)||sv_).dispatchEvent(new PointerEvent(q[0],{bubbles:true,cancelable:true,clientX:xx,clientY:yy,pointerId:5,isPrimary:true,pointerType:'touch'}))});await W(400);gv(S.sv);var t2='S.sv '+S.sv+' · B m.v '+B.v.length;
S.m=A;S.sv=2;panel();draw();open3D();await W(300);__build();var p=org3api.proj([B.x+B.w/2,B.b+B.h/2,B.d+20]);__sel3(p[0],p[1]);await W(400);gv(S.sv);var t3='S.sv '+S.sv+' · B m.v '+B.v.length;if(x3)x3.click();
R.casos['trocar de módulo (A com 3º vão escolhido → B de 1 vão)']='2D: '+t2+' | 3D: '+t3;
/* 4. projeto antigo com vãos sobrando: abrir, desenhar, peças, corte, 3D, salvar e reabrir */
var m4=cena([0.5],[{k:'door',n:1},{k:'drawers',n:2},{k:'free',n:1},{k:'door',n:4}]);await W(20);var s4=JSON.stringify(snapState());loadState(JSON.parse(s4));draw();m4=S.mods[0];
var limpo=JSON.parse(s4);limpo.mods[0].v=limpo.mods[0].v.slice(0,2);var pr=sig(m4),cr=JSON.stringify(cutLines(m4)),br=cx3();loadState(limpo);draw();var pl=sig(S.mods[0]),cl=JSON.stringify(cutLines(S.mods[0])),bl=cx3();
loadState(JSON.parse(s4));draw();var s5=JSON.parse(JSON.stringify(snapState()));
R.casos['projeto antigo com 2 vãos sobrando']='peças iguais a sem sobra '+(pr===pl)+' · corte igual '+(cr===cl)+' · 3D igual '+(br===bl)+' · salvar e reabrir mantém a sobra '+(s5.mods[0].v.length===4)+' · nada apagado '+(s5.mods[0].div.length===1);
/* 5. desenhar/peças/3D não gravam vão (pureza) num módulo com vão sem configuração gravada */
var m6=cena([1/3,2/3],[{k:'door',n:1}]);m6.v=[{k:'door',n:1}];var n6=m6.v.length;draw();partsOf(m6);cx3();cutLines(m6);R.casos['módulo com vão sem configuração gravada · desenhar/peças/3D/corte']='m.v '+n6+' → '+S.mods[0].v.length+(S.mods[0].v.length!==n6?' (desenhar gravou)':' (nada gravado)');
/* 6. edição num vão que existe mas não tem configuração gravada (vão 2 de 2): '2 portas' tem que valer */
var m7=cena([0.5],[{k:'free',n:1}]);m7.v=[{k:'free',n:1}];S.sv=1;S.tab=3;panel();var b7=[].filter.call(document.querySelectorAll('#bd [data-door="2"]'),function(q){return q.offsetParent!==null})[0];if(b7){b7.click();await W(50)}var v7=S.mods[0].v[1];
R.casos['2 portas no vão 2 sem configuração gravada']=(b7?'tocou':'sem botão')+' · vão 2 ficou '+(v7?v7.k+(v7.n||''):'(nada gravado — edição perdida)')+' · peças com porta '+partsOf(S.mods[0]).filter(function(p){return /Porta/.test(p.pk||p.name||'')}).length;
R.invalidosRegistrados=window.__gvInvalidos.length;R.errs=__errs.length;gv=window.gv=gvAtual;return JSON.stringify(R);
