window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* TAMP-2D-ALVO (vídeo de 16/11 às 13:48): mexer na altura do tamponamento externo pelo 2D jogava o móvel pra cima (fora da pedra) e apagava rodapé, travessa e moldura.
   Sequência do marceneiro: balcão + pedra + tamponamento → toque no tamponamento → arrastar pelo 2D → 3D → base → porta → salvar e reabrir → plano de corte. */
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5610;S.H=3270;S.stones=[];S.mods=[];draw();
var x=200;['Balcão 2 portas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var q=S.mods[S.mods.length-1];q.x=x;x+=q.w});x=3200;['Gaveteiro 3 gavetas','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var q=S.mods[S.mods.length-1];q.x=x;x+=q.w});
addStone();var m=S.mods[3];m.tr=true;delete m.trAuto;draw();S.m=S.mods[0];S.tab=0;draw();panel();await W(100);
var sv=document.getElementById('svg');
var ev=function(t,X,Y,el){(el||document.elementFromPoint(X,Y)||sv).dispatchEvent(new PointerEvent(t,{bubbles:true,cancelable:true,clientX:X,clientY:Y,pointerId:7,isPrimary:true,pointerType:'touch'}))};
var arr=async function(X,Y,dx,dy){ev('pointerdown',X,Y);for(var k=1;k<=8;k++){ev('pointermove',X+dx*k/8,Y+dy*k/8,sv);ev('pointermove',X+dx*k/8,Y+dy*k/8,window)}ev('pointerup',X+dx,Y+dy,sv);ev('pointerup',X+dx,Y+dy,window);await W(80);draw()};
var gm=function(){return [].filter.call(sv.querySelectorAll('#mod'),function(q){return +q.dataset.mi===3})[0]};
var ponto=function(nome,fy){var P=partsOf(m),i=P.findIndex(function(q){return q.name===nome}),r=gm().querySelector('rect[data-p="'+i+'"]');r.scrollIntoView({block:'center'});var b=r.getBoundingClientRect();return [b.left+b.width/2,b.top+b.height*fy]};
var tpH=function(){var p=partsOf(m).filter(function(q){return q.name==='Tamponamento direito'})[0];return p?Math.round(p.y)+'+'+Math.round(p.h):'-'};
var st=function(){var P=partsOf(m);return 'x'+m.x+' b'+(+m.b||0)+' · rodapé '+P.filter(function(q){return /^Rodapé/.test(q.name)}).length+' · travessa '+!!m.trav+' · moldura '+!!m.mold+' · base '+P.some(function(q){return /^Base inferior/.test(q.name)})+' · tamp '+tpH()};
R.antes=st();
/* 1) módulo não escolhido: tocar no tamponamento e arrastar pra cima só escolhe; o móvel não sai do lugar */
var q=ponto('Tamponamento direito',0.2);await arr(q[0],q[1],0,-90);R.toqueSemEscolher=st()+' · escolhido '+(S.m===m);
/* 2) escolhido: arrastar o tamponamento pra baixo estica até o chão e para (não passa do piso) */
q=ponto('Tamponamento direito',0.2);await arr(q[0],q[1],0,240);var tp=partsOf(m).filter(function(q){return q.name==='Tamponamento direito'})[0];R.esticaAteOChao=st()+' · fim do tamponamento '+Math.round(tp.y+tp.h)+' · chão '+(m.h+(+m.b||0));
/* 3) arrastar pra cima encurta; o móvel continua no lugar */
q=ponto('Tamponamento direito',0.2);await arr(q[0],q[1],0,-60);R.encurta=st();
/* 4) erguer o módulo e descer de novo: rodapé, travessa e moldura voltam */
var bx=gm().querySelector('rect[data-mi]').getBoundingClientRect();await arr(bx.left+bx.width*0.6,bx.top+bx.height*0.5,0,-90);R.ergueu='b'+(+m.b||0)+' · rodapé '+partsOf(m).filter(function(q){return /^Rodapé/.test(q.name)}).length;
bx=gm().querySelector('rect[data-mi]').getBoundingClientRect();await arr(bx.left+bx.width*0.6,bx.top+bx.height*0.5,0,400);R.voltouProChao=st();
/* 5) 3D: base e tamponamento com as medidas das peças */
open3D();await W(300);__build();var b3=__boxes().filter(function(b){return String(b.nm).indexOf('3:')===0}),h3=function(re){var a=b3.filter(function(b){return re.test(String(b.nm).slice(2))&&(b.y1-b.y0)>10}).map(function(b){return Math.round(b.y1-b.y0)});return a.length?Math.max.apply(null,a):0};
var P=partsOf(m);/* módulos encostados: a base e o rodapé são uma peça só (contínua), desenhada com o vizinho; confere que ela passa por baixo deste módulo */var bI=__boxes().filter(function(b){return /:Base inferior$/.test(String(b.nm))&&b.x0<=m.x+1&&b.x1>=m.x+m.w-1}).length,rI=__boxes().filter(function(b){return /:Rodapé \(pedestal\)$/.test(String(b.nm))&&b.x0<=m.x+60&&b.x1>=m.x+m.w-60}).length;R.tresD='base embaixo '+(bI>0)+' · rodapé embaixo '+(rI>0)+' · tamp 3D '+h3(/^Tamponamento direito/)+' = peça '+Math.round(P.filter(function(q){return q.name==='Tamponamento direito'})[0].h);document.getElementById('v3x').click();
/* 6) porta no vão (1 porta) e plano de corte com as peças de verdade */
S.m=m;S.sv=0;vmenuOpen(3,0,200,300);await W(40);var dv=document.querySelector('#vmenu [data-vk="door1"]');if(dv)dv.click();await W(40);
var cg_=cutGroups().map;R.corte=Object.keys(cg_).map(function(k){return cg_[k]}).filter(function(l){return l.names.some(function(n){return /^(Tamponamento direito · face|Rodapé \(pedestal\)|Porta$|Base inferior)/.test(n)})}).map(function(l){return l.names.filter(function(n){return /^(Tamponamento direito · face|Rodapé \(pedestal\)|Porta$|Base inferior)/.test(n)})[0].replace(/ \(.*/,'')+' '+l.L+'×'+l.W+' q'+l.qty}).sort().join(' | ');
/* 7) salvar, fechar e reabrir */
var a=st(),sv_=JSON.stringify(snapState());loadState(JSON.parse(sv_));draw();m=S.mods[3];R.reabriu=(st()===a)+' · '+st();
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
