window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* PROTOCOLO DE PERFORMANCE (16/11) · prevenção de regressão (conta o trabalho, não o relógio):
   arrastando um módulo no 2D, a vista de cima não mede os rótulos a cada movimento (getBBox) nem a própria largura (getBoundingClientRect);
   com a vista de cima aberta, arruma os rótulos uma vez quando o dedo para; fechada, não mede nada (antes: 466 medições de rótulo e 36 da largura em 12 movimentos).
   E no 3D, refazer a cena reaproveita a memória dos vértices (antes criava listas novas e copiava tudo a cada quadro da animação da porta). */
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5000;S.H=2700;S.stones=[];S.mods=[];draw();var x=0;['Balcão 2 portas','Gaveteiro 3 gavetas','Balcão da pia (cuba)','Balcão 2 portas'].forEach(function(n){newTpl(T(n));var m=S.mods[S.mods.length-1];m.x=x;x+=m.w});addStone();S.m=S.mods[1];draw();panel();await W(100);
var nb=0,nr=0,P=document.getElementById('plan');var gb0=SVGGraphicsElement.prototype.getBBox;SVGGraphicsElement.prototype.getBBox=function(){if(this.closest&&this.closest('#plan'))nb++;return gb0.apply(this,arguments)};var br0=Element.prototype.getBoundingClientRect;Element.prototype.getBoundingClientRect=function(){if(this===P)nr++;return br0.apply(this,arguments)};
var arr=async function(tab){S.tab=tab;panel();await W(150);var x0=S.m.x;window.drag={t:'m',m:JSON.parse(JSON.stringify(S.m)),p:{x:0,y:0}};nb=0;nr=0;for(var i=1;i<=12;i++){S.m.x=x0+i*10;draw();await W(16)}var d={bbox:nb,larg:nr,moveu:S.m.x!==x0};window.drag=null;S.m.x=x0;draw();await W(400);return 'mexeu '+d.moveu+' · durante o arraste a vista de cima mediu: rótulos '+d.bbox+', largura '+d.larg+' · depois que soltou: rótulos '+(nb>0?'arrumados':'não arrumados')};
R.arrastar2D_vistaDeCimaAberta=await arr(TABORD.filter(function(t){return /Pedra/.test(TABS[t])})[0]);R.arrastar2D_vistaDeCimaFechada=(await arr(0)).replace(' · depois que soltou: rótulos não arrumados','');
SVGGraphicsElement.prototype.getBBox=gb0;Element.prototype.getBoundingClientRect=br0;
/* 3D: refazer a cena (selecionar peça, cada quadro da animação da porta) manda os vértices da mesma memória de 32 bits, sem criar outra a cada vez */
open3D();await W(400);var BUFS=[],bd0=WebGLRenderingContext.prototype.bufferData;WebGLRenderingContext.prototype.bufferData=function(t,d,u){if(d&&d.buffer&&d.byteLength>1000)BUFS.push(d.buffer);return bd0.apply(this,arguments)};
re3();var b1=BUFS.slice();BUFS=[];re3();var b2=BUFS.slice();WebGLRenderingContext.prototype.bufferData=bd0;
R.refazer3D='envios '+(b1.length===b2.length&&b1.length>0?'iguais':'diferentes')+' · mesma memória '+(b1.length>0&&b1.every(function(x,i){return x===b2[i]}));
document.getElementById('v3x').click();
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
