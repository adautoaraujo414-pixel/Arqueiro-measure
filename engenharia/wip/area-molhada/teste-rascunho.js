window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* ÁREA MOLHADA NO 3D (16/11, 14:41 "muito feio o acabamento dessa mancha"; 14:42 "rebaixo da pia área molhada 2 cm").
   Referência (marmorarias): rebaixo tradicional/americano de ~2 cm, a mesma pedra, cantos retos ou arredondados. */
var cena=function(cor,e,cm){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=2400;S.H=2600;S.stones=[];S.mods=[];draw();addStone();var st=S.stones[0];st.x=100;st.w=2200;st.d=600;st.t=870;st.e=e||30;if(cor)st.cor=cor;st.items=[{k:'cuba',x:900,w:500,d:400,y:100,cm:cm||undefined}];draw();return st};
var r1=function(v){return Math.round(v*10)/10},hex=function(c){c=String(c);if(c.length===4)c='#'+c[1]+c[1]+c[2]+c[2]+c[3]+c[3];return [parseInt(c.substr(1,2),16),parseInt(c.substr(3,2),16),parseInt(c.substr(5,2),16)]};
var olha=function(st){re3();var g=wetGeo(st),top=st.t+st.e,cor=hex(stC(st)).join(),B=__boxes(),pd=B.filter(function(b){return b.g==='stc'}),
  /* pedra no meio da área molhada (longe da cuba e dos cantos) e fora dela */
  em=function(x,z){var q=pd.filter(function(b){return !b.pf&&b.x0<=x&&b.x1>=x&&b.z0<=z&&b.z1>=z});return q.length?q.map(function(b){return r1(b.y1-top)}).join('/'):'nada'},
  placa=B.filter(function(b){return g&&b.y0>=top-.01&&b.y1<=top+1.5&&b.x0>=g.x0-1&&b.x1<=g.x1+1&&b.z0>=g.z0-1&&b.z1<=g.z1+1&&b.c.join()!==cor&&b.g!=='lo'&&(b.x1-b.x0)>20&&(b.z1-b.z0)>20}).length,
  outra=pd.filter(function(b){return b.c.join()!==cor}).length,cantos=pd.filter(function(b){return b.pf}).length;
 return g?{dentro:em(g.x0+30+(g.r||0),g.z0+20),fora:em(g.x0-100,300),fundoMeio:em((g.x0+g.x1)/2,(g.z0+50)),placaDeOutraCor:placa,pedraDeOutraCor:outra,cantos:cantos}:{fora:em(500,300),dentro:em(1150,50)}};
/* 1) criar pelo botão (como o marceneiro): rebaixo de 2 cm, mesma pedra */
var st=cena();open3D();await W(600);S.st=st;S.tab=6;panel();await W(60);if(window.secAbreTudo)secAbreTudo();var bt=document.querySelector('#bd [data-stwet="1"]');R.botao=!!bt;if(bt)bt.click();await W(80);
R.criou='rebaixo '+st.wet.dp+' mm · cantos '+st.wet.c+' r'+st.wet.r;var o=olha(st);R.pedra='dentro '+o.dentro+' · fora '+o.fora+' · no fundo da área '+o.fundoMeio;R.semMancha='placa de outra cor '+o.placaDeOutraCor+' · pedra de outra cor '+o.pedraDeOutraCor+' · cantos curvos '+o.cantos;
/* a cuba de sobrepor dentro da área molhada assenta no nível de baixo */
var st2=cena(null,30,'sob');st2.wet=wetDefault(st2);draw();re3();var top2=st2.t+st2.e,cb=__boxes().filter(function(b){return b.x0>=st2.x+900-30&&b.x1<=st2.x+1400+30&&b.y0>=top2-25&&b.y1<=top2+6&&b.g!=='stc'&&b.g!=='lo'}),ys=cb.map(function(b){return r1(b.y0-top2)});R.cubaSobrepor='borda da cuba em '+(ys.length?Math.min.apply(null,ys):'—')+' (o topo da pedra é 0)';
/* 2) cantos quadrados, rebaixo menor pelo campo e pedra de 2 cm */
st.wet.c='reto';draw();o=olha(st);R.quadrado='cantos curvos '+o.cantos+' · dentro '+o.dentro;
wetSet(st,'dp',8);draw();o=olha(st);R.rebaixo8='dentro '+o.dentro;st.wet.c='curvo';wetSet(st,'dp',20);
var st3=cena(null,20);st3.wet=wetDefault(st3);draw();o=olha(st3);R.pedra2cm='dentro '+o.dentro+' (sobra pedra embaixo)';
/* 3) projeto antigo com rebaixo de 8 mm: abre igual (não muda sozinho) */
var st4=cena();st4.wet={on:1,w:900,x:700,c:'curvo',r:40,dp:8};draw();var sv=JSON.stringify(snapState());loadState(JSON.parse(sv));draw();var s4=S.stones[0];o=olha(s4);R.antigo='guardado '+s4.wet.dp+' mm · dentro '+o.dentro;
/* 4) salvar e reabrir a nova; tirar a área molhada volta a pedra inteira */
var s5=cena();s5.wet=wetDefault(s5);draw();var sv2=JSON.stringify(snapState());loadState(JSON.parse(sv2));draw();var s6=S.stones[0];o=olha(s6);R.reabriu='rebaixo '+s6.wet.dp+' · dentro '+o.dentro+' · fora '+o.fora;
delete s6.wet;draw();o=olha(s6);R.tirou='dentro '+o.dentro+' · fora '+o.fora;
/* 5) a área molhada não muda a pedra do orçamento/resumo (só a linha dela) */
var s7=cena();var r0=(window.stResumo?stResumo(s7):'');s7.wet=wetDefault(s7);draw();var r1_=(window.stResumo?stResumo(s7):'');R.resumo=typeof stResumo==='function'?('linha nova: '+String(r1_).split(/\n|<br>/).filter(function(l){return String(r0).indexOf(l)<0}).join(' | ').replace(/<[^>]+>/g,'').slice(0,160)):'sem resumo';
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
