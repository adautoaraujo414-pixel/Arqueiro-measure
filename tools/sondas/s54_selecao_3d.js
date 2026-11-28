/* s54 · ETAPA 3.1 (Adauto 28/11, pedido do Chefe ao Claude 5) · RÉGUA DA SELEÇÃO NO 3D — só mede, não mexe no código de seleção.
   Cenários: catálogo inteiro (cada modelo sozinho) e projetos com módulos encostados, aéreo sobre balcão, nichos, canto L e canto cego.
   Vistas: 3 ângulos (isométrica, frente, lado) × 3 zooms (1×, ~2,6×, ~6,7× pela roda, no centro da tela).
   VERDADE: raio da tela contra as caixas do 3D (a caixa mais perto do olho no ponto). Peça visível = tem ponto da tela em que ela é a da frente.
   TOQUE: no ponto visível da peça mais perto do centro dos pontos visíveis dela ("centro da peça visível"), pelo window.__sel3 (o mesmo do toque duplo).
   Métricas: (1) % acerto · (2) seleções no módulo vizinho · (3) acerto por zoom · (4) acerto em peças pequenas (< 600 px² visíveis)
             (5) tempo do __sel3 até o 3D redesenhado (ms) · (6) LED: ledAdd('mod') depois do toque cai no módulo tocado e encosta na peça tocada
   Ids: caixa sem pk, pk repetido no partsOf, pk com 2 peças, peça desenhável sem caixa, destaque (laranja) só na peça tocada.
   Uso: python3 tools/sondas/rodar.py tools/sondas/s54_selecao_3d.js --porta P --url ...  (window.__S54={so:'cat'|'proj',lim:N} opcional, pela semente) */
window.MINI3OFF=1;PR.setupDone=1;window.__MSG='';window.toast=function(t){window.__MSG=String(t)};window.ambMsg=function(t){window.__MSG=String(t)};
var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var ARG=window.__S54||{};
var T=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n&&!t.act)it=t})});if(!it)TPL.forEach(function(t){if(!it&&t&&t.n===n)it=t});return it?JSON.parse(JSON.stringify(it)):null};
var ORANGE=function(b){return b.c&&b.c[0]===255&&b.c[1]===159&&b.c[2]===26};
var OKB=function(b){return b.nm&&/^\d+:/.test(b.nm)&&b.g!=='sh'&&!b.nol&&b.a>0&&!b.wl&&!b.cs};
var RAY=function(cx,cy,bx){var P=window.PM3;var nx=cx/P.w*2-1,ny=1-cy/P.h*2,r1=[0,1,2,3].map(function(i){return P.X[i]-nx*P.W[i]}),r2=[0,1,2,3].map(function(i){return P.Y[i]-ny*P.W[i]}),best=null,bw=1e18;
 for(var k=0;k<bx.length;k++){var b=bx[k],lo=[b.x0,b.y0,b.z0],hi=[b.x1,b.y1,b.z1];for(var a=0;a<3;a++)for(var s2=0;s2<2;s2++){var v=s2?hi[a]:lo[a],u1=(a+1)%3,u2=(a+2)%3,A=r1[u1],B_=r1[u2],C=r2[u1],D=r2[u2],det=A*D-B_*C;if(Math.abs(det)<1e-12)continue;var e1=-(r1[a]*v+r1[3]),e2=-(r2[a]*v+r2[3]),p1=(e1*D-B_*e2)/det,p2=(A*e2-e1*C)/det;
   if(p1<lo[u1]||p1>hi[u1]||p2<lo[u2]||p2>hi[u2])continue;var q=[0,0,0];q[a]=v;q[u1]=p1;q[u2]=p2;var w=P.W[0]*q[0]+P.W[1]*q[1]+P.W[2]*q[2]+P.W[3];if(w<=0)continue;if(w<bw){bw=w;best=b}}}return best};
var PROJ=function(c){var P=window.PM3,d=function(r){return r[0]*c[0]+r[1]*c[1]+r[2]*c[2]+r[3]},w=d(P.W);if(!(w>0))return null;return [(d(P.X)/w+1)/2*P.w,(1-d(P.Y)/w)/2*P.h]};
var idOf=function(b){var mi=parseInt(String(b.nm),10);return {mi:mi,pk:b.pk||null,ppk:b.ppk||null,nm:String(b.nm).slice(String(mi).length+1),k:mi+'|'+(b.ppk||b.pk||('∅'+String(b.nm)))}};
var cv=function(){return document.querySelector('#cv3')||document.querySelector('#v3 canvas')};
async function vista(ang,zt){var bt=document.querySelector('#v3 [data-v="'+ang+'"]');if(bt)bt.click();await W(30);var c=cv(),r=c.getBoundingClientRect();for(var i=0;i<zt;i++)c.dispatchEvent(new WheelEvent('wheel',{deltaY:-1,clientX:r.left+r.width/2,clientY:r.top+r.height/2,bubbles:true,cancelable:true}));await W(40)}
var fechaTudo=function(){var mx=false;S.mods.forEach(function(m){(m.v||[]).forEach(function(v){if(v&&(v.open||(v.od&&Object.keys(v.od).length)||(v.dop&&Object.keys(v.dop).length))){v.open=false;v.od={};v.dop={};mx=true}})});return mx};
var modSig=function(){return JSON.stringify(S.mods.map(function(m){return [m.x,m.w,m.h,m.d,m.b,m.wing||0,!!m.tl,!!m.tr,m.tlW,m.trW,m.sup?1:0]}))};
var limpa=function(){try{__sel3(-99999,-99999)}catch(_){}window.SEL3=null};
var REG={efeito:0,efeitoEx:[],tot:0,ok:0,viz:0,nada:0,hl:0,hlOk:0,pq:0,pqOk:0,ms:[],porZ:{},porA:{},porC:{},falhas:[],ids:{semPk:0,pkRep:0,pkAmb:0,semCaixa:0,ex:[]},led:{tot:0,mod:0,sup:0,ex:[]}};
var add=function(o,k,ok){o[k]=o[k]||{t:0,ok:0};o[k].t++;if(ok)o[k].ok++};
function ids(cen){var all=__boxes();S.mods.forEach(function(m,mi){var P=partsOf(m),seen={},bxm=all.filter(function(b){return OKB(b)&&parseInt(String(b.nm),10)===mi});
  P.forEach(function(p){if(!p.pk)return;if(seen[p.pk]&&seen[p.pk]!==p){REG.ids.pkRep++;if(REG.ids.ex.length<40)REG.ids.ex.push(cen+' · mód '+mi+' · pk repetido '+p.pk)}seen[p.pk]=p});
  var nomes={};bxm.forEach(function(b){if(!b.pk){REG.ids.semPk++;if(REG.ids.ex.length<40)REG.ids.ex.push(cen+' · mód '+mi+' · caixa sem pk: '+b.nm);return}var k=b.ppk||b.pk;(nomes[k]=nomes[k]||{})[String(b.nm).replace(/^\d+:/,'')]=1});
  Object.keys(nomes).forEach(function(k){var n=Object.keys(nomes[k]);var pn=seen[k]&&seen[k].name;if(pn&&n.indexOf(pn)<0&&n.length>1){REG.ids.pkAmb++;if(REG.ids.ex.length<40)REG.ids.ex.push(cen+' · mód '+mi+' · pk '+k+' em caixas de '+n.join(' / '))}});
  P.forEach(function(p){if(!p.pk||p.noDraw||p.hide3||p.noCut&&!p.pe||!(p.w>0&&p.h>0))return;if(!bxm.some(function(b){return b.pk===p.pk||b.ppk===p.pk})){REG.ids.semCaixa++;if(REG.ids.ex.length<40)REG.ids.ex.push(cen+' · mód '+mi+' · peça sem caixa no 3D: '+p.pk)}})})}
async function medir(cen,ang,zl,zt,base){var P=window.PM3,pm0=JSON.stringify(window.PM3);if(!P)return;var bx=__boxes().filter(OKB),G={},H={},st=6;
 for(var y=st/2;y<P.h;y+=st)for(var x=st/2;x<P.w;x+=st){var b=RAY(x,y,bx);if(!b)continue;var id=idOf(b),g=G[id.k]||(G[id.k]={id:id,pts:[],px:0});g.pts.push([x,y]);g.px+=st*st;H[x+','+y]=id.k}
 /* peça pequena com poucos pontos: amostra fina no retângulo dela na tela */
 var porId={};bx.forEach(function(b){var k=idOf(b).k;(porId[k]=porId[k]||[]).push(b)});
 Object.keys(porId).forEach(function(k){if(G[k]&&G[k].pts.length>=4)return;var x0=1e9,x1=-1e9,y0=1e9,y1=-1e9;porId[k].forEach(function(b){[[b.x0,b.y0,b.z0],[b.x1,b.y0,b.z0],[b.x0,b.y1,b.z0],[b.x1,b.y1,b.z0],[b.x0,b.y0,b.z1],[b.x1,b.y0,b.z1],[b.x0,b.y1,b.z1],[b.x1,b.y1,b.z1]].forEach(function(c){var s=PROJ(c);if(!s)return;x0=Math.min(x0,s[0]);x1=Math.max(x1,s[0]);y0=Math.min(y0,s[1]);y1=Math.max(y1,s[1])})});
  x0=Math.max(0,x0);y0=Math.max(0,y0);x1=Math.min(P.w-1,x1);y1=Math.min(P.h-1,y1);if(!(x1>x0&&y1>y0))return;var sx=Math.max(1,(x1-x0)/40),sy=Math.max(1,(y1-y0)/40),pts=[];for(var yy=y0+sy/2;yy<y1;yy+=sy)for(var xx=x0+sx/2;xx<x1;xx+=sx){var b2=RAY(xx,yy,bx);if(b2&&idOf(b2).k===k)pts.push([xx,yy])}
  if(pts.length){G[k]={id:idOf(porId[k][0]),pts:pts,px:pts.length*sx*sy}}});
 var keys=Object.keys(G);
 for(var i=0;i<keys.length;i++){var g=G[keys[i]],cx=0,cy=0;g.pts.forEach(function(p){cx+=p[0];cy+=p[1]});cx/=g.pts.length;cy/=g.pts.length;var bp=g.pts[0],bd=1e18;g.pts.forEach(function(p){var d=(p[0]-cx)*(p[0]-cx)+(p[1]-cy)*(p[1]-cy);if(d<bd){bd=d;bp=p}});
  limpa();if(JSON.stringify(window.PM3)!==pm0)await vista(ang,zt);var t0=performance.now();try{__sel3(bp[0],bp[1])}catch(e){}var dt=performance.now()-t0;var s=window.SEL3,id=g.id;
  var ok=!!(s&&s.mi===id.mi&&(s.pk===id.pk||s.pk===id.ppk||(s.ppk&&s.ppk===id.ppk)));var viz=!!(s&&s.mi!==id.mi);
  var or=__boxes().filter(ORANGE),hl=!!s,hlOk=hl&&or.length>0&&or.every(function(b){return parseInt(String(b.nm),10)===s.mi&&(b.pk===s.pk||b.ppk===s.pk)});
  /* inequívoco: nenhum ponto da grade a até 12 px do toque é de outra peça */var inq=true;for(var gx=Math.round((bp[0]-st/2)/st)*st+st/2-2*st;gx<=bp[0]+12;gx+=st)for(var gy=Math.round((bp[1]-st/2)/st)*st+st/2-2*st;gy<=bp[1]+12;gy+=st){if(Math.hypot(gx-bp[0],gy-bp[1])>12)continue;var hk=H[gx+','+gy];if(hk&&hk!==keys[i])inq=false}
  if(inq){REG.inq=(REG.inq||0)+1;if(ok)REG.inqOk=(REG.inqOk||0)+1;add(REG.inqZ=REG.inqZ||{},zl,ok);if(g.px<600){REG.inqPq=(REG.inqPq||0)+1;if(ok)REG.inqPqOk=(REG.inqPqOk||0)+1}}
  var pq=g.px<600;REG.tot++;if(ok)REG.ok++;if(viz)REG.viz++;if(!s)REG.nada++;if(hl){REG.hl++;if(hlOk)REG.hlOk++}if(pq){REG.pq++;if(ok)REG.pqOk++}REG.ms.push(dt);add(REG.porZ,zl,ok);add(REG.porA,ang,ok);add(REG.porC,cen.split(' · ')[0],ok);
  if((!ok||(hl&&!hlOk))&&REG.falhas.length<400)REG.falhas.push({inq:inq,c:cen,v:ang+' z'+zl,peca:id.mi+':'+id.nm+' ('+(id.ppk||id.pk)+')',px:Math.round(g.px),xy:bp.map(Math.round),sel:s?(s.mi+':'+s.pk):'nada',hl:hl?(hlOk?'ok':'acende outra: '+or.slice(0,3).map(function(b){return b.nm+'|'+b.pk}).join(', ')):'-'});
  /* selecionar nunca muda o projeto (§12): se o toque mexeu em posição/medida/tamponamento de algum módulo, conta como achado e volta o projeto */limpa();if(modSig()!==base.sig){REG.efeito++;if(REG.efeitoEx.length<40)REG.efeitoEx.push(cen+' · tocou '+id.mi+':'+id.nm+' → o projeto mudou sozinho');loadState(JSON.parse(base.st));draw();try{window.re3()}catch(_){}await vista(ang,zt)}else if(fechaTudo()){try{window.re3()}catch(_){}}}
 limpa();try{window.re3()}catch(_){}}
async function led(cen){/* (6) LED: toca a maior peça visível de cada módulo e põe o LED no módulo selecionado */await vista('iso',0);var P=window.PM3,bx=__boxes().filter(OKB),G={};for(var y=4;y<P.h;y+=8)for(var x=4;x<P.w;x+=8){var b=RAY(x,y,bx);if(!b)continue;var id=idOf(b);if(!/^(Prateleira|Base superior|Base inferior|Lateral|Divisória|Fundo|Teto|Porta|Frente)/.test(id.nm))continue;var g=G[id.k]||(G[id.k]={id:id,pts:[]});g.pts.push([x,y])}
 var porM={};Object.keys(G).forEach(function(k){var g=G[k];if(!porM[g.id.mi]||porM[g.id.mi].pts.length<g.pts.length)porM[g.id.mi]=g});
 for(var mi in porM){var g=porM[mi],m=S.mods[+mi];if(!m||m.corner)continue;var p=g.pts[Math.floor(g.pts.length/2)];var L0=S.mods.map(function(o){return JSON.stringify(o.led||null)});limpa();window.__MSG='';S.m=null;try{__sel3(p[0],p[1])}catch(_){}REG.led.sel=(REG.led.sel||0)+(window.SEL3&&window.SEL3.mi===+mi?1:0);try{/* caminho do usuário: ＋ (#v3add) abre o painel · "＋ No módulo escolhido" · fecha o painel */var bL=document.querySelector('[data-cled="mod"]'),ab=false;if(!bL||bL.closest('[hidden]')){var va=document.getElementById('v3add');if(va){va.click();ab=true;bL=document.querySelector('[data-cled="mod"]')}}if(bL)bL.click();else REG.led.err='sem botão "LED no módulo" na tela';var C=document.getElementById('crp3');if(ab&&C)C.hidden=true}catch(e){REG.led.err=String(e)}
  var dono=-1;S.mods.forEach(function(o,j){if(JSON.stringify(o.led||null)!==L0[j])dono=j});REG.led.tot++;var apl=!!(m.sup||/cristaleira/i.test(String(m.n||m.nome||'')));if(!apl&&dono<0){REG.led.recusa=(REG.led.recusa||0)+1;continue}REG.led.apl=(REG.led.apl||0)+1;var okM=dono===+mi;if(okM)REG.led.mod++;
  var okS=false;if(dono>=0){var B=__boxes(),pc=B.filter(function(b){return OKB(b)&&idOf(b).k===g.id.k}),lb=B.filter(function(b){return String(b.ledg||b.led||'')==='m'+dono});okS=lb.some(function(l){return pc.some(function(q){return l.x0<=q.x1+3&&l.x1>=q.x0-3&&l.y0<=q.y1+3&&l.y1>=q.y0-3&&l.z0<=q.z1+3&&l.z1>=q.z0-3})})}
  if(okS)REG.led.sup++;if((!okM||!okS)&&REG.led.ex.length<40)REG.led.ex.push(cen+' · tocou '+g.id.mi+':'+g.id.nm+' → LED em '+(dono<0?'nenhum':'mód '+dono+' ('+((S.mods[dono].led||{}).pos||'padrão')+')')+(okM&&!okS?' · não encosta na peça tocada':'')+(window.__MSG?' · app: "'+window.__MSG.slice(0,90)+'"':''));
  S.mods.forEach(function(o,j){var v=JSON.parse(L0[j]);if(v)o.led=v;else delete o.led});try{window.re3()}catch(_){}}}
async function cenario(cen,monta){loadState(initLimpo());monta();S.m=null;window.SEL3=null;draw();open3D();await W(700);try{window.re3()}catch(_){}await W(60);ids(cen);var base={st:JSON.stringify(snapState()),sig:modSig()};
 var A=['iso','front','left'],Z=[[1,0],[2,10],[3,20]];for(var a=0;a<A.length;a++)for(var z=0;z<Z.length;z++){await vista(A[a],Z[z][1]);await medir(cen+' · '+A[a]+' z'+Z[z][0],A[a],'z'+Z[z][0],Z[z][1],base)}
 if(/^P/.test(cen))await led(cen);await vista('iso',0)}
var t0=Date.now();
if(ARG.so!=='proj'){var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(q){var it=typeof q==='number'?TPL[q]:q;if(it&&!it.act&&it.w&&it.h)its.push(it)})});if(ARG.lim)its=its.slice(0,ARG.lim);
 for(var i=0;i<its.length;i++){var it=its[i];await cenario('CAT '+it.n,function(){S.env='livre';S.room='livre';S.W=8000;S.H=3200;draw();newTpl(JSON.parse(JSON.stringify(it)))})}}
if(ARG.so!=='cat'){var put=function(n,x,wing){var t=T(n);if(!t)return null;newTpl(t);var m=S.mods[S.mods.length-1];if(x!==undefined)m.x=x;if(wing){m.wing=wing}draw();return m};
 var coz=function(){S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw()};
 await cenario('P1 fila encostada + aéreos',function(){coz();var x=0;['Balcão 2 portas','Gaveteiro 4 gavetas','Balcão 2 portas'].forEach(function(n){var m=put(n,x);if(m)x+=m.w});x=0;['Aéreo 2 portas','Aéreo 2 portas','Aéreo 2 portas'].forEach(function(n){var m=put(n,x);if(m)x+=m.w})});
 await cenario('P2 aéreo sobre balcão',function(){coz();put('Balcão 2 portas',1000);put('Aéreo 2 portas',1000)});
 await cenario('P3 nichos',function(){coz();var nn=[];CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&!t.act&&/nicho/i.test(t.n)&&nn.length<4)nn.push(t.n)})});var x=0;nn.forEach(function(n){var m=put(n,x);if(m)x+=m.w+20})});
 await cenario('P4 canto L + parede lateral',function(){coz();var m=put('Canto em L (base)',0);if(m){m.corner='e'}addWing('e');addWing('e');put('Balcão 2 portas',(m?m.w:900))});
 await cenario('P5 canto cego + parede lateral',function(){coz();put('Balcão canto cego · cego na esquerda (porta na direita)',0);addWing('e');put('Balcão 2 portas',1000)})}
var q=function(a,p){if(!a.length)return 0;var s=a.slice().sort(function(x,y){return x-y});return Math.round(s[Math.min(s.length-1,Math.floor(p*s.length))]*10)/10};
var pc=function(o){return o.t?Math.round(1000*o.ok/o.t)/10+'% ('+o.ok+'/'+o.t+')':'-'};var mp=function(o){var r={};Object.keys(o).forEach(function(k){r[k]=pc(o[k])});return r};
return JSON.stringify({codigo:(document.querySelector('meta[name=ver]')||{}).content||'',seg:Math.round((Date.now()-t0)/1000),
 '1_acerto':pc({t:REG.tot,ok:REG.ok}),'1b_acerto_inequivoco':pc({t:REG.inq||0,ok:REG.inqOk||0}),'1c_inequivoco_porZoom':mp(REG.inqZ||{}),'2_vizinho':REG.viz,'2b_nada':REG.nada,'3_porZoom':mp(REG.porZ),'3b_porAngulo':mp(REG.porA),'4_pequenas':pc({t:REG.pq,ok:REG.pqOk}),'4b_pequenas_inequivocas':pc({t:REG.inqPq||0,ok:REG.inqPqOk||0}),'5_ms':{p50:q(REG.ms,.5),p95:q(REG.ms,.95),max:q(REG.ms,1)},
 '6_led':{tot:REG.led.tot,selecionou:REG.led.sel||0,erro:REG.led.err||'',recusadoPelaRegra:(REG.led.recusa||0)+' (app: "LED vai só nos módulos de cima e na cristaleira")',aceitos:REG.led.apl||0,modulo:pc({t:REG.led.apl||0,ok:REG.led.mod}),superficie:pc({t:REG.led.apl||0,ok:REG.led.sup}),ex:REG.led.ex},
 destaque:pc({t:REG.hl,ok:REG.hlOk}),toqueMudouProjeto:{n:REG.efeito,ex:REG.efeitoEx},ids:REG.ids,porCenario:mp(REG.porC),falhas:REG.falhas})
