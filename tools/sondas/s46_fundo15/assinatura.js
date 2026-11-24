/* assinatura completa de um projeto aberto: peças, corte, fundo/profundidade, orçamento com preços fixos, DXF */
window.__SIG=function(){var r1=function(v){return Math.round(v*100)/100};
 var o={};o.p=S.mods.map(function(m){return partsOf(m).map(function(p){return p.name+' '+p.cl+'x'+p.cw+' q'+(p.qty||1)+' m'+(p.mat||'')}).sort().join(';')});
 try{var G=cutGroups();o.c=G.ord.map(function(k){var g=G.map[k];return [g.L,g.W,g.mat,g.fin||'',g.qty,(g.names||[]).join('/')].join(' ')}).sort()}catch(e){o.c=['ERRO '+e]}
 o.f=S.mods.map(function(m){var fb=0;try{fb=fBack(m)}catch(_){}return [m.fundo?1:0,m.fundoPia?1:0,m.fundoMm,fTipo(m),fb,(+m.d||0)+fb].join(',')});
 var pr={mdfB:301.11,mdfC:402.22,mdfM:453.33,mdf25:505.55,fundo:121.21,fitaB:1.17,fitaC:2.23,fitaT:3.31,dob:11.1,cor:31.3,coro:61.6,pux:9.9,concha:7.7,perfilG:22.2,perfil:33.3,facetado:44.4,toque:55.5,pesQ:5.5,pesR:6.6},bk={};Object.keys(pr).forEach(function(k){bk[k]=PR[k];PR[k]=pr[k]});
 try{SPC={};var b=budget();o.tot=r1(b.tot);o.nB=b.nB;o.nC=b.nC;o.nF=b.nF;o.cB=r1(b.cB);o.cC=r1(b.cC);o.cF=r1(b.cF);o.rows=b.rows.map(function(x){return r1(x.c)});o.pr=prAuto(b).filter(function(r){return r[3]>0.0001}).map(function(r){return r[0]+'|'+r[1]+'|'+r1(r[3])});o.plan=b.plan.groups.map(function(g){return g.key+':'+g.n+':'+g.pieces})}catch(e){o.tot='ERRO '+e}
 finally{Object.keys(bk).forEach(function(k){PR[k]=bk[k]})}
 try{var D=dxfPecas({uniao:'nenhuma'});o.dxf=D.pecas.map(function(q){return q.nome+' '+q.L+'x'+q.W+' e'+q.esp+' f'+q.furos.length+' r'+q.rasgos.length}).sort()}catch(e){o.dxf=['ERRO '+e]}
 return o};
