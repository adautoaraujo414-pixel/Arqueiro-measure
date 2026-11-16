/* Medida informada → 2D → 3D → peças → corte, no catálogo inteiro (cada modelo sozinho numa parede grande).
   A1 caixa do 3D (só o corpo: sem tamponamento, porta, frente, puxador, rodapé, pedra) cabe em L×A×P informado e encosta nas bordas (±1 mm)
   A2 retângulo do 2D tem a largura e a altura informadas (±1 mm, pela escala do desenho)
   A3 nenhuma peça de corte maior que o módulo (comprimento ≤ maior medida do módulo + 1)
   A4 quantidade: soma das quantidades do corte do módulo ≥ número de peças com corte em partsOf (o corte pode dividir engrosso, nunca perder peça)
   A5 nenhuma peça com medida de corte menor que 1 mm ou com décimo */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})});
var V={},ex=function(k,t){(V[k]=V[k]||[]).push(t)};draw();open3D();await W(300);
var CORPO=/^(Lateral|Base|Teto|Fundo|Travessa|Divis|Prateleira|Tampo)/;
for(var i=0;i<its.length;i++){var it=its[i];loadState(initLimpo());S.env='livre';S.room='livre';S.W=8000;S.H=3200;draw();newTpl(JSON.parse(JSON.stringify(it)));var m=S.mods[0];if(!m)continue;S.m=m;draw();__build();
 var bx=__boxes().filter(function(q){return String(q.nm).indexOf('0:')===0&&CORPO.test(String(q.pk||String(q.nm).slice(2)))&&!/Tamponamento|Porta|Frente|Gaveta|Rodap|Pedra|puxador|Puxador|Moldura|engrosso/i.test(String(q.pk||q.nm))});
 if(!bx.length){ex('A1 sem caixas de corpo',it.n);continue}
 var x0=Math.min.apply(null,bx.map(function(q){return q.x0})),x1=Math.max.apply(null,bx.map(function(q){return q.x1})),y1=Math.max.apply(null,bx.map(function(q){return q.y1})),z0=Math.min.apply(null,bx.map(function(q){return q.z0})),z1=Math.max.apply(null,bx.map(function(q){return q.z1}));
 var L=x1-x0,A=y1-(+m.b||0),P=z1-z0;
 if(!m.corner&&Math.abs(L-m.w)>1)ex('A1 largura 3D ≠ informada',it.n+': 3D '+Math.round(L)+' · informada '+m.w);
 if(!m.corner&&Math.abs(A-m.h)>1)ex('A1 altura 3D ≠ informada',it.n+': 3D '+Math.round(A)+' · informada '+m.h);
 if(!m.corner&&P>m.d+1)ex('A1 profundidade 3D maior que a informada',it.n+': 3D '+Math.round(P)+' · informada '+m.d);
 try{var g=document.querySelector('#svg #mod[data-mi="0"] rect[data-mi]'),svg=document.getElementById('svg');if(g){var vb=svg.viewBox.baseVal,sr=svg.getBoundingClientRect(),bb=g.getBBox();var kx=1/(typeof K==='number'?K:1);var wmm=bb.width/(typeof K==='number'?K:1),hmm=bb.height/(typeof K==='number'?K:1);if(!m.corner&&Math.abs(wmm-m.w)>1.5)ex('A2 largura 2D ≠ informada',it.n+': 2D '+Math.round(wmm)+' · informada '+m.w);if(!m.corner&&Math.abs(hmm-m.h)>1.5)ex('A2 altura 2D ≠ informada',it.n+': 2D '+Math.round(hmm)+' · informada '+m.h)}}catch(e){ex('A2 exceção',it.n+' '+e)}
 var big=Math.max(m.w,m.h,m.d,(+m.cw2||0)),cl=cutLines(m);
 cl.forEach(function(l){if(Math.max(l.L,l.W)>big+1&&!/Tamponamento|Pedra|Rodap|Moldura|Fechamento|Painel/i.test((l.names||[]).join()))ex('A3 peça maior que o módulo',it.n+': '+(l.names||[])[0]+' '+l.L+'×'+l.W+' (módulo '+m.w+'×'+m.h+'×'+m.d+')');if(l.L<1||l.W<1)ex('A5 peça < 1 mm',it.n+': '+(l.names||[])[0]+' '+l.L+'×'+l.W);if(l.L%1||l.W%1)ex('A5 décimo',it.n+': '+(l.names||[])[0]+' '+l.L+'×'+l.W)});
 var nP=partsOf(m).filter(function(p){return !p.noCut&&p.cl>0&&p.cw>0}).reduce(function(a,p){return a+(p.qty||1)},0),nC=cl.reduce(function(a,l){return a+(l.qty||0)},0);if(nC<nP)ex('A4 corte com menos peças que partsOf',it.n+': corte '+nC+' · partsOf '+nP)}
var R={modelos:its.length,achados:{}};Object.keys(V).forEach(function(k){R.achados[k]=V[k].length+' :: '+V[k].slice(0,5).join(' ‖ ')});return JSON.stringify(R);
