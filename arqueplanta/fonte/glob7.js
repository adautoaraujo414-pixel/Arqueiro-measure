/* ===== 🏠 Planta da casa: um modelo só (S.casa) pra planta 2D, 3D, medidas, áreas, quantitativos e documentos ===== */
var CFIN=[['alv','Alvenaria aparente'],['chap','Chapisco'],['reb','Rebocada'],['mas','Massa corrida'],['pin','Pintada'],['rev','Revestida']],CFLV={alv:0,chap:1,reb:2,mas:3,pin:4,rev:4};
/* alvenaria: [chave, nome, comprimento da face, altura da face, textura, cor] */
var CMAT=[['tij','Tijolo maciço 5×10×20',200,55,1,'#b5643e'],['b6','Tijolo 6 furos 9×14×19',190,140,16,'#c47343'],['b8','Tijolo 8 furos 9×19×19',190,190,2,'#c26f40'],['bce','Bloco cerâmico 14×19×29',290,190,17,'#bd6c3f'],['bc9','Bloco de concreto 9×19×39',390,190,3,'#a3a29d'],['bc14','Bloco de concreto 14×19×39',390,190,3,'#9b9a95']];
/* revestimento de parede e piso: [chave, nome, textura, cor, peça x, peça y] */
var CREV=[['porc60','Porcelanato 60×60',8,'#d9d5cd',600,600],['porc120','Porcelanato 120×60',9,'#cfcac2',1200,600],['cer30','Cerâmica 30×30',10,'#e9e7e2',300,300],['cer45','Cerâmica 45×45',11,'#ddd7cd',450,450],['metro','Azulejo metrô 10×20',12,'#f3f3f1',200,100],['past','Pastilha 5×5',13,'#6aa3b8',50,50],['pedra','Pedra (filete)',14,'#a8998a',0,0]];
var CPISO=[['contra','Contrapiso',20,'#8f8d88',0,0],['porc60','Porcelanato 60×60',8,'#d9d5cd',600,600],['porc120','Porcelanato 120×60',9,'#cfcac2',1200,600],['cer45','Cerâmica 45×45',11,'#d6cfc3',450,450],['mad','Madeira / laminado',21,'#a77b52',0,0],['vin','Vinílico',22,'#b9966f',0,0],['cim','Cimento queimado',23,'#a09e99',0,0],['ext','Piso externo (pedra)',25,'#a7a39b',400,400],['grama','Grama',24,'#5f8f45',0,0]];
var CPAINT=[['#f2efe9','Branco gelo'],['#ffffff','Branco'],['#e9e1d3','Areia'],['#d9cbb4','Palha'],['#c9c3b8','Cinza claro'],['#8e959c','Cinza'],['#4a5058','Grafite'],['#9bab8f','Verde sálvia'],['#6f8fa8','Azul'],['#c98f6b','Terracota'],['#e7c9a9','Pêssego'],['#2f3338','Preto']];
/* pontos: [chave, nome, grupo, altura (-1 = teto, 0 = piso), sigla] */
var CPT=[['tug','Tomada baixa','ele',300,'TUG'],['tum','Tomada média (bancada)','ele',1100,'TUM'],['tua','Tomada alta (ar-cond.)','ele',2200,'TUA'],['tue','Tomada de uso específico','ele',300,'TUE'],['int','Interruptor','ele',1100,'S'],['int2','Interruptor paralelo','ele',1100,'S3w'],['qd','Quadro de distribuição','ele',1500,'QD'],['rede','Ponto de rede / TV','ele',300,'TV'],
 ['luz','Ponto de luz (teto)','luz',-1,'L'],['spot','Spot embutido','luz',-1,'SP'],['pend','Pendente','luz',-1,'PD'],['arand','Arandela','luz',1800,'AR'],
 ['af','Água fria','hid',600,'AF'],['aq','Água quente','hid',600,'AQ'],['esg','Esgoto','hid',500,'ESG'],['ralo','Ralo','hid',0,'RL'],['vaso','Saída do vaso','hid',0,'VS'],['chuv','Chuveiro','hid',2200,'CH'],['gas','Gás','hid',1000,'GÁS']];
var CGRP=[['ele','Elétrica'],['luz','Iluminação'],['hid','Hidráulica']];
/* aberturas: [chave, nome, largura, altura, peitoril] */
var COPN=[['porta','Porta de abrir',800,2100,0],['porta2','Porta de 2 folhas',1400,2100,0],['correr','Porta de correr',1600,2100,0],['janela','Janela',1200,1000,1100],['basc','Basculante',600,600,1500],['vao','Vão livre',900,2100,0]];
var CWK=[['int','Parede interna'],['ext','Parede externa'],['muro','Muro'],['meia','Meia parede'],['vidro','Vidro']];
var CSTG=[['alv','Alvenaria'],['reb','Reboco'],['acab','Acabamentos'],['fin','Casa finalizada']];
/* móveis: [chave, nome, largura, profundidade, altura, cor] */
var CMOV=[['cama2','Cama de casal',1380,1880,520,'#e8e2d6'],['cama1','Cama de solteiro',880,1880,520,'#e8e2d6'],['gr','Guarda-roupa',2000,600,2400,'#cdb79a'],['cri','Criado-mudo',450,400,550,'#b48f66'],['sofa','Sofá',2100,900,850,'#7f8a96'],['pol','Poltrona',800,800,850,'#8a7a6a'],['rack','Rack / painel de TV',1800,450,550,'#6f5b47'],['mesa','Mesa de jantar',1600,900,750,'#a07a52'],['mcen','Mesa de centro',1000,600,400,'#a07a52'],['escr','Escrivaninha',1200,600,750,'#b98f62'],['gel','Geladeira',700,720,1850,'#c9ced4'],['fog','Fogão',760,620,850,'#9aa3ad'],['banc','Bancada / pia',1800,600,900,'#e9e6e0'],['arm','Armário',1200,600,2200,'#d8cbb7'],['vaso','Vaso sanitário',380,650,750,'#f6f6f4'],['lav','Lavatório',600,450,850,'#f6f6f4'],['box','Box do chuveiro',900,900,1900,'vidro'],['tanq','Tanque',600,550,850,'#f2f2f0'],['maq','Máquina de lavar',600,650,850,'#e4e7ea'],['carro','Carro',1800,4300,1450,'#5b6b7c']];
function cOf(L,k){for(var i=0;i<L.length;i++)if(L[i][0]===k)return L[i];return null}
function casaNew(){return {v:1,W:[],O:[],R:[],P:[],F:[],E:[],Q:[],cfg:{stg:'fin',t:150,h:2800,mat:'b8',jn:10,pd:{alv:5,chap:10,reb:10,mas:10,pin:10,rev:15,pis:12,rod:10},dm:2,rend:10,cut:'auto',roof:{k:'',inc:30,bei:500,c:'#8b4a32'},src:''}}}
function casaFix(){var c=S.casa,n=casaNew();if(!c||typeof c!=='object')c=S.casa=n;['W','O','R','P','F','E','Q'].forEach(function(k){if(!Array.isArray(c[k]))c[k]=[]});c.cfg=Object.assign(n.cfg,c.cfg||{});c.cfg.pd=Object.assign(casaNew().cfg.pd,c.cfg.pd||{});c.cfg.roof=Object.assign(casaNew().cfg.roof,c.cfg.roof||{});return c}
function casa(){return S.casa&&typeof S.casa==='object'&&S.casa.cfg?S.casa:casaFix()}
function cBy(L,id){for(var i=0;i<L.length;i++)if(L[i].id===id)return L[i];return null}
function cId(L){var m=0;L.forEach(function(o){m=Math.max(m,+o.id||0)});return m+1}
function cLen(w){return Math.hypot(w.b[0]-w.a[0],w.b[1]-w.a[1])}
function cU(w){var L=cLen(w)||1;return [(w.b[0]-w.a[0])/L,(w.b[1]-w.a[1])/L]}
function cNL(w){var u=cU(w);return [u[1],-u[0]]}
function cT(w){return +w.t>0?+w.t:casa().cfg.t}
function cH(w){var c=casa().cfg;return +w.h>0?+w.h:(w.k==='muro'?2000:w.k==='meia'?1100:c.h)}
function cAt(w,s,off){var u=cU(w),n=cNL(w);off=off||0;return [w.a[0]+u[0]*s+n[0]*off,w.a[1]+u[1]*s+n[1]*off]}
function cFace(w,sd){var f=w[sd]||{};return {f:f.f||'pin',c:f.c||'#f2efe9',rv:f.rv||'cer45',rh:+f.rh||0,rc:f.rc||''}}
function cMat(w){return cOf(CMAT,w.m||casa().cfg.mat)||CMAT[2]}
function cOps(w){return casa().O.filter(function(o){return o.w===w.id}).sort(function(a,b){return a.d-b.d})}
function cOpFix(o){var w=cBy(casa().W,o.w);if(!w)return;var L=cLen(w),H=cH(w);o.l=Math.round(Math.max(100,Math.min(+o.l||800,L-20)));o.d=Math.round(Math.max(0,Math.min(+o.d||0,L-o.l)));o.p=Math.round(Math.max(0,Math.min(+o.p||0,H-150)));o.h=Math.round(Math.max(100,Math.min(+o.h||2100,H-o.p)))}
/* números: vírgula em pt/es, ponto em inglês */
function cDec(){return /[?&]lang=en/.test(location.search)?'.':','}
function cN(v,d){var s=(Math.round(v*Math.pow(10,d))/Math.pow(10,d)).toFixed(d);return cDec()===','?s.replace('.',','):s}
function cM(mm){return cN(mm/1000,2)+' m'}
function cA(mm2){return cN(mm2/1e6,2)+' m²'}
function cV(mm3){return cN(mm3/1e9,2)+' m³'}
function cCm(mm){return String(Math.round(mm/10))}
/* geometria auxiliar */
function lineX(p,d,q,e){var cr=d[0]*e[1]-d[1]*e[0];if(Math.abs(cr)<1e-9)return null;var t=((q[0]-p[0])*e[1]-(q[1]-p[1])*e[0])/cr;return [p[0]+d[0]*t,p[1]+d[1]*t]}
function segX(a,b,c,d){var r=[b[0]-a[0],b[1]-a[1]],s=[d[0]-c[0],d[1]-c[1]],cr=r[0]*s[1]-r[1]*s[0];if(Math.abs(cr)<1e-9)return null;var t=((c[0]-a[0])*s[1]-(c[1]-a[1])*s[0])/cr,u=((c[0]-a[0])*r[1]-(c[1]-a[1])*r[0])/cr;return [t,u]}
function pArea(P){var s=0;for(var i=0;i<P.length;i++){var a=P[i],b=P[(i+1)%P.length];s+=a[0]*b[1]-b[0]*a[1]}return s/2}
function pPer(P){var s=0;for(var i=0;i<P.length;i++){var a=P[i],b=P[(i+1)%P.length];s+=Math.hypot(b[0]-a[0],b[1]-a[1])}return s}
function pIn(p,P){var c=false;for(var i=0,j=P.length-1;i<P.length;j=i++){var a=P[i],b=P[j];if(((a[1]>p[1])!==(b[1]>p[1]))&&(p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]))c=!c}return c}
function pSegD(p,a,b){var dx=b[0]-a[0],dz=b[1]-a[1],L2=dx*dx+dz*dz,t=L2?Math.max(0,Math.min(1,((p[0]-a[0])*dx+(p[1]-a[1])*dz)/L2)):0;return Math.hypot(p[0]-a[0]-dx*t,p[1]-a[1]-dz*t)}
/* tira os vértices no meio de um lado reto */
function pSimp(P){var o=[];for(var i=0;i<P.length;i++){var a=P[(i-1+P.length)%P.length],b=P[i],c=P[(i+1)%P.length],cr=(b[0]-a[0])*(c[1]-b[1])-(b[1]-a[1])*(c[0]-b[0]),la=Math.hypot(b[0]-a[0],b[1]-a[1]),lc=Math.hypot(c[0]-b[0],c[1]-b[1]);if(la<1||lc<1||Math.abs(cr)/(la*lc)>.01)o.push(b)}return o.length>=3?o:P}
/* ponto bem dentro do polígono (pra escrever o nome do ambiente) */
function pInner(P){var x0=1e18,x1=-1e18,z0=1e18,z1=-1e18;P.forEach(function(p){x0=Math.min(x0,p[0]);x1=Math.max(x1,p[0]);z0=Math.min(z0,p[1]);z1=Math.max(z1,p[1])});var best=null,bd=-1;for(var i=1;i<12;i++)for(var j=1;j<12;j++){var q=[x0+(x1-x0)*i/12,z0+(z1-z0)*j/12];if(!pIn(q,P))continue;var d=1e18;for(var k=0;k<P.length;k++)d=Math.min(d,pSegD(q,P[k],P[(k+1)%P.length]));if(d>bd){bd=d;best=q}}return best||[(x0+x1)/2,(z0+z1)/2]}
/* ===== paredes → nós, trechos e faces fechadas (ambientes) ===== */
var CGK='',CG=null,CRNEW=1;
function casaGeo(){var C=casa(),k=JSON.stringify(C.W.map(function(w){return [w.id,w.a,w.b,w.t||0]}))+'|'+C.cfg.t;if(CG&&CGK===k)return CG;CGK=k;try{CG=cgBuild(C.W)}catch(e){CG={N:[],E:[],H:[],F:[],rooms:[],outs:[],fs:{}}}return CG}
function cgBuild(W){var TOL=30,ws=W.filter(function(w){return cLen(w)>=50}),sp=ws.map(function(){return [0,1]}),EP=ws.map(function(w){return [w.a.slice(),w.b.slice()]}),i,j;
 /* pontas que encostam numa parede (no meio dela, até meia espessura) ou na ponta de outra: ligam ali */
 for(j=0;j<ws.length;j++)for(var e=0;e<2;e++){var p=EP[j][e],done=false;
  for(i=0;i<ws.length&&!done;i++){if(i===j)continue;var A=ws[i];[A.a,A.b].forEach(function(q){if(!done&&Math.hypot(q[0]-p[0],q[1]-p[1])<=Math.max(TOL,cT(A)/2+5)){EP[j][e]=q.slice();done=true}})}
  for(i=0;i<ws.length&&!done;i++){if(i===j)continue;var A2=ws[i],La=cLen(A2),u=cU(A2),s=(p[0]-A2.a[0])*u[0]+(p[1]-A2.a[1])*u[1],d=Math.abs((p[0]-A2.a[0])*u[1]-(p[1]-A2.a[1])*u[0]);if(s>TOL&&s<La-TOL&&d<=Math.max(TOL,cT(A2)/2+5)){EP[j][e]=[A2.a[0]+u[0]*s,A2.a[1]+u[1]*s];sp[i].push(s/La);done=true}}}
 for(i=0;i<ws.length;i++)for(j=i+1;j<ws.length;j++){var r=segX(EP[i][0],EP[i][1],EP[j][0],EP[j][1]);if(r&&r[0]>.002&&r[0]<.998&&r[1]>.002&&r[1]<.998){sp[i].push(r[0]);sp[j].push(r[1])}}
 var N=[],node=function(p){for(var k=0;k<N.length;k++)if(Math.hypot(N[k][0]-p[0],N[k][1]-p[1])<=TOL)return k;N.push([p[0],p[1]]);return N.length-1};
 EP.forEach(function(q){node(q[0]);node(q[1])});
 var E=[],seen={};
 ws.forEach(function(w,ii){var a=EP[ii][0],b=EP[ii][1],ts=sp[ii].slice().sort(function(x,y){return x-y}),prev=null;
  ts.forEach(function(t){var k=node([a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t]);if(prev!==null&&k!==prev){var key=Math.min(k,prev)+'-'+Math.max(k,prev);if(!seen[key]){seen[key]=1;E.push({a:prev,b:k,w:w.id})}}prev=k})});
 var deg=N.map(function(){return 0});E.forEach(function(q){deg[q.a]++;deg[q.b]++});var alive=E.map(function(){return true}),ch=true;
 while(ch){ch=false;E.forEach(function(q,k){if(alive[k]&&(deg[q.a]<2||deg[q.b]<2)){alive[k]=false;deg[q.a]--;deg[q.b]--;ch=true}})}
 var H=[];E.forEach(function(q,k){if(!alive[k])return;H.push({f:q.a,t:q.b,e:k},{f:q.b,t:q.a,e:k})});
 var out={},ang=function(h){return Math.atan2(N[h.t][1]-N[h.f][1],N[h.t][0]-N[h.f][0])};H.forEach(function(h,hi){(out[h.f]=out[h.f]||[]).push(hi)});Object.keys(out).forEach(function(n){out[n].sort(function(x,y){return ang(H[x])-ang(H[y])})});
 var used=H.map(function(){return false}),F=[];
 H.forEach(function(h0,hi0){if(used[hi0])return;var hs=[],hi=hi0,g=0;while(!used[hi]&&g++<5000){used[hi]=true;hs.push(hi);var h=H[hi],L=out[h.t],ix=L.indexOf(hi^1);hi=L[(ix-1+L.length)%L.length]}if(hi===hi0&&hs.length>=3)F.push({hs:hs,poly:hs.map(function(x){return N[H[x].f]})})});
 /* componentes ligados: a maior face de cada um é o lado de fora */
 var par=N.map(function(_,k){return k}),fd=function(k){while(par[k]!==k){par[k]=par[par[k]];k=par[k]}return k};E.forEach(function(q,k){if(alive[k])par[fd(q.a)]=fd(q.b)});
 F.forEach(function(f){f.area=pArea(f.poly);f.comp=fd(H[f.hs[0]].f)});var big={};F.forEach(function(f){var b=big[f.comp];if(!b||Math.abs(f.area)>Math.abs(b.area))big[f.comp]=f});
 F.forEach(function(f){f.outer=big[f.comp]===f});
 var G={N:N,E:E,H:H,F:F,alive:alive,rooms:[],outs:[],fs:{}};
 W.forEach(function(w){G.fs[w.id]={L:[],R:[]}});
 F.forEach(function(f){if(!f.outer&&(f.area>0)===(big[f.comp].area>0))return;var o=cgOff(G,f);if(!o)return;
  if(!f.outer){var A=Math.abs(pArea(o.pts));if(A<3e5||(pArea(o.pts)>0)!==(f.area>0))return;o.area=A;o.face=f;G.rooms.push(o)}else{o.face=f;G.outs.push(o)}
  var tag=f.outer?'ext':G.rooms.length-1;o.ed.forEach(function(q){var w=q.w,u=cU(w),s0=(q.p0[0]-w.a[0])*u[0]+(q.p0[1]-w.a[1])*u[1],s1=(q.p1[0]-w.a[0])*u[0]+(q.p1[1]-w.a[1])*u[1];G.fs[w.id][q.sd].push({s0:Math.min(s0,s1),s1:Math.max(s0,s1),len:q.len,r:tag,p0:q.p0,p1:q.p1})})});
 return G}
/* contorno deslocado meia espessura (dentro do ambiente, ou pro lado de fora no contorno externo) */
function cgOff(G,f){var C=casa(),n=f.hs.length,P=f.poly,sg=f.area>0?1:-1,lines=[],i;
 for(i=0;i<n;i++){var a=P[i],b=P[(i+1)%n],d=[b[0]-a[0],b[1]-a[1]],L=Math.hypot(d[0],d[1])||1;d=[d[0]/L,d[1]/L];var nE=sg>0?[-d[1],d[0]]:[d[1],-d[0]];if(f.outer)nE=[-nE[0],-nE[1]];var w=cBy(C.W,G.E[G.H[f.hs[i]].e].w);if(!w)return null;var o=cT(w)/2;lines.push({p:[a[0]+nE[0]*o,a[1]+nE[1]*o],d:d,n:nE,w:w})}
 var V=[];for(i=0;i<n;i++){var l0=lines[(i-1+n)%n],l1=lines[i],x=lineX(l0.p,l0.d,l1.p,l1.d);V.push(x&&Math.hypot(x[0]-l1.p[0],x[1]-l1.p[1])<4*cT(l1.w)+2000?x:[l1.p[0],l1.p[1]])}
 var ed=[];for(i=0;i<n;i++){var l=lines[i],p0=V[i],p1=V[(i+1)%n],nl=cNL(l.w),sd=(l.n[0]*nl[0]+l.n[1]*nl[1])>0?'L':'R';ed.push({w:l.w,sd:sd,p0:p0,p1:p1,len:Math.hypot(p1[0]-p0[0],p1[1]-p0[1]),n:l.n})}
 return {pts:V,ed:ed}}
/* ===== ambientes: liga cada face fechada a um registro (nome, piso, pé-direito) ===== */
function casaRooms(){var C=casa(),G=casaGeo(),taken={},out=[];
 G.rooms.forEach(function(g,gi){var r=null;C.R.forEach(function(q){if(!r&&!taken[q.id]&&pIn([q.x,q.z],g.pts))r=q});
  if(!r){var ip=pInner(g.pts),nn=1;while(C.R.some(function(q){return q.n==='Ambiente '+nn}))nn++;r={id:cId(C.R),n:'Ambiente '+nn,x:Math.round(ip[0]),z:Math.round(ip[1]),pf:'porc60',ph:0,lv:0,tmp:CRNEW?undefined:1};if(CRNEW)C.R.push(r);else r.id=-1-gi}
  else if(CRNEW){var d0=1e18;for(var k2=0;k2<g.pts.length;k2++)d0=Math.min(d0,pSegD([r.x,r.z],g.pts[k2],g.pts[(k2+1)%g.pts.length]));if(d0<400){var ip2=pInner(g.pts);r.x=Math.round(ip2[0]);r.z=Math.round(ip2[1])}}
  taken[r.id]=1;var hs=g.ed.map(function(q){return cH(q.w)}),ph=+r.ph>0?+r.ph:Math.min.apply(null,hs.length?hs:[C.cfg.h]),x0=1e18,x1=-1e18,z0=1e18,z1=-1e18;g.pts.forEach(function(p){x0=Math.min(x0,p[0]);x1=Math.max(x1,p[0]);z0=Math.min(z0,p[1]);z1=Math.max(z1,p[1])});
  var per=pPer(g.pts),dr=0,wa=0;g.ed.forEach(function(q){var w=q.w,u=cU(w),s0=(q.p0[0]-w.a[0])*u[0]+(q.p0[1]-w.a[1])*u[1],s1=(q.p1[0]-w.a[0])*u[0]+(q.p1[1]-w.a[1])*u[1],a=Math.min(s0,s1),b=Math.max(s0,s1),H=cH(w),oa=0;
   cOps(w).forEach(function(o){var ov=Math.max(0,Math.min(b,o.d+o.l)-Math.max(a,o.d));if(ov<=0)return;oa+=ov*Math.min(o.h,H-(o.p||0));if(o.k!=='janela'&&o.k!=='basc')dr+=ov});wa+=Math.max(0,q.len*H-oa)});
  var sp=pSimp(g.pts),rect=sp.length===4&&sp.every(function(p,i){var q=sp[(i+1)%4];return Math.abs(q[0]-p[0])<2||Math.abs(q[1]-p[1])<2});
  out.push({r:r,g:g,pts:g.pts,sp:sp,area:g.area,per:per,ph:ph,rod:Math.max(0,per-dr),wa:wa,bb:[x0,z0,x1,z1],rect:rect,ed:g.ed})});
 return out}
/* ===== medidas de uma parede (eixo e cada face) ===== */
function cWallInfo(w){var G=casaGeo(),fs=G.fs[w.id]||{L:[],R:[]},L=cLen(w),H=cH(w),t=cT(w),ops=cOps(w),oa=0,R=null;ops.forEach(function(o){oa+=o.l*Math.min(o.h,H-(o.p||0))});
 var side=function(sd){var sg=fs[sd]||[],fl=sg.length?sg.reduce(function(s,q){return s+q.len},0):L,names=[],ext=false;sg.forEach(function(q){if(q.r==='ext'){ext=true;return}if(!R)R=casaRooms();var rr=R[q.r];if(rr&&names.indexOf(rr.r.n)<0)names.push(rr.r.n)});return {len:fl,gross:fl*H,ops:oa,net:Math.max(0,fl*H-oa),rooms:names,ext:ext,f:cFace(w,sd)}};
 return {len:L,t:t,h:H,ops:ops,opA:oa,gross:L*H,net:Math.max(0,L*H-oa),vol:Math.max(0,(L*H-oa)*t),L:side('L'),R:side('R')}}
/* paredes ligadas numa ponta (pra mexer junto) */
function cLinked(p,skip){var out=[];casa().W.forEach(function(w){if(w===skip)return;if(Math.hypot(w.a[0]-p[0],w.a[1]-p[1])<=30)out.push([w,'a']);if(Math.hypot(w.b[0]-p[0],w.b[1]-p[1])<=30)out.push([w,'b'])});return out}
/* ===== quantitativos (estimativa, com as premissas) ===== */
function casaQuant(){var C=casa(),cf=C.cfg,pd=cf.pd,R=casaRooms(),q={alv:0,alvW:0,chap:0,reb:0,mas:0,pin:0,pinT:0,rev:{},pis:{},rod:0,teto:0,ext:0,pts:{},ops:{},vol:0};
 C.W.forEach(function(w){if(w.k==='vidro')return;var I=cWallInfo(w);q.alv+=I.net;q.vol+=I.vol;['L','R'].forEach(function(sd){var f=I[sd].f,lv=CFLV[f.f]||0,a=I[sd].net;if(I[sd].ext)q.ext+=a;if(lv>=1)q.chap+=a;if(lv>=2)q.reb+=a;
   if(f.f==='rev'){var rh=f.rh>0?Math.min(f.rh,I.h):I.h,ar=a*rh/I.h;q.rev[f.rv]=(q.rev[f.rv]||0)+ar;if(rh<I.h){q.mas+=a-ar;q.pin+=a-ar}}else{if(f.f==='mas'||f.f==='pin')q.mas+=a;if(f.f==='pin')q.pin+=a}})});
 R.forEach(function(r){var k=r.r.pf||'porc60';q.pis[k]=(q.pis[k]||0)+r.area;if(k!=='grama'&&k!=='ext'){q.teto+=r.area;q.rod+=r.rod}});q.pinT=q.teto;
 C.P.forEach(function(p){q.pts[p.k]=(q.pts[p.k]||0)+1});C.O.forEach(function(o){var k=o.k+'|'+o.l+'×'+o.h;q.ops[k]=(q.ops[k]||0)+1});
 var M=cOf(CMAT,cf.mat)||CMAT[2],jn=+cf.jn>=0?+cf.jn:10,porM=1e6/((M[2]+jn)*(M[3]+jn)),k1=function(v,p){return v*(1+(+p||0)/100)},rows=[];
 var row=function(g,n,v,u,p,pr,ex){rows.push({g:g,n:n,v:v,u:u,p:p,tot:p==null?v:k1(v,p),pr:pr||'',ex:ex||''})};
 row('Alvenaria','Área de alvenaria',q.alv/1e6,'m²',pd.alv,'Eixo das paredes × altura, descontando portas, janelas e vãos.');
 row('Alvenaria',M[1],q.alv/1e6*porM,'un',pd.alv,cN(porM,1)+' peças por m² (peça '+cCm(M[2])+' × '+cCm(M[3])+' cm na face, junta de '+jn+' mm).');
 row('Revestimento de parede','Chapisco',q.chap/1e6,'m²',pd.chap,'Faces das paredes com chapisco ou mais (as duas faces), sem os vãos.');
 row('Revestimento de parede','Reboco',q.reb/1e6,'m²',pd.reb,'Faces rebocadas, com massa, pintadas ou revestidas.');
 row('Revestimento de parede','Massa corrida',q.mas/1e6,'m²',pd.mas,'Faces com massa corrida ou pintura.');
 row('Pintura','Pintura das paredes',q.pin/1e6,'m²',pd.pin,'Faces pintadas (acima do revestimento, quando ele não vai até o teto).');
 row('Pintura','Pintura do teto',q.pinT/1e6,'m²',pd.pin,'Área dos tetos (forro ou laje) dos ambientes cobertos.');
 var tl=(q.pin+q.pinT)/1e6*(1+pd.pin/100)*(+cf.dm||2)/(+cf.rend||10);row('Pintura','Tinta (estimada)',tl,'L',null,(+cf.dm||2)+' demãos, rendimento de '+(+cf.rend||10)+' m² por litro por demão.');
 Object.keys(q.rev).forEach(function(k){var Rv=cOf(CREV,k)||CREV[3],a=q.rev[k]/1e6,pc=Rv[4]?' · ≈ '+Math.ceil(a*(1+pd.rev/100)/(Rv[4]*Rv[5]/1e6))+' peças':'';row('Revestimentos',Rv[1]+' (parede)',a,'m²',pd.rev,'Faces revestidas, até a altura escolhida'+pc+'.')});
 Object.keys(q.pis).forEach(function(k){var P=cOf(CPISO,k)||CPISO[1],a=q.pis[k]/1e6,pc=P[4]?' · ≈ '+Math.ceil(a*(1+pd.pis/100)/(P[4]*P[5]/1e6))+' peças':'';row('Pisos',P[1],a,'m²',pd.pis,'Área interna dos ambientes'+pc+'.')});
 row('Pisos','Rodapé',q.rod/1000,'m',pd.rod,'Perímetro interno dos ambientes, sem as portas e vãos.');
 row('Paredes','Faces externas (fachada)',q.ext/1e6,'m²',null,'Lado de fora das paredes externas, sem os vãos.');
 row('Paredes','Volume das paredes',q.vol/1e9,'m³',null,'Eixo × altura × espessura, sem os vãos.');
 Object.keys(q.ops).sort().forEach(function(k){var a=k.split('|'),O=cOf(COPN,a[0])||COPN[0];row('Portas e janelas',O[1]+' '+a[1].replace(/(\d+)×(\d+)/,function(_,x,y){return cCm(+x)+' × '+cCm(+y)+' cm'}),q.ops[k],'un',null,'')});
 Object.keys(q.pts).forEach(function(k){var P=cOf(CPT,k)||[k,k,'ele'];row('Pontos · '+(cOf(CGRP,P[2])||['',''])[1],P[1],q.pts[k],'un',null,'')});
 return {rows:rows,q:q,R:R,porM:porM,M:M}}
/* quadro de áreas */
function casaAreas(){var R=casaRooms(),G=casaGeo(),tot=0,cons=0;R.forEach(function(r){tot+=r.area});G.outs.forEach(function(o){cons+=Math.abs(pArea(o.pts))});return {R:R,util:tot,cons:cons}}
/* ===== planta da nota (ferramenta Cômodo) → casa ===== */
/* J = {rooms:[{pts:[[x,y]...],closed,segs:[{k:'WALL'|'DOOR'|'WINDOW'|'OPENING'|'DIVIDER'|..., mm, hinge, side, slide}]}], doors:[{a,b,mm,hinge,side,slide}], texts:[{x,y,t}]} em pontos da folha */
function casaFromNote(J,opt){opt=opt||{};var C=casaNew(),t=+opt.t||150,rat=[],rooms=(J.rooms||[]).filter(function(r){return r.pts&&r.pts.length>=2});
 rooms.forEach(function(r){var n=r.closed?r.pts.length:r.pts.length-1;for(var i=0;i<n;i++){var s=(r.segs||[])[i]||{},a=r.pts[i],b=r.pts[(i+1)%r.pts.length],px=Math.hypot(b[0]-a[0],b[1]-a[1]);if(s.mm>0&&px>3)rat.push(s.mm/px)}});
 rat.sort(function(a,b){return a-b});var k=rat.length?rat[Math.floor(rat.length/2)]:10;
 var snapA=function(a){var q=Math.round(a/(Math.PI/2))*(Math.PI/2);return Math.abs(a-q)<12*Math.PI/180?q:a};
 /* cada cômodo: contorno interno com as medidas da trena, depois o eixo das paredes (meia espessura pra fora) */
 var txIn=function(P){return (J.texts||[]).filter(function(tx){return pIn([tx.x,tx.y],P)}).map(function(tx){return String(tx.t||'')}).join('\n')};
 var RS=rooms.map(function(r,ri){var m=r.closed?r.pts.length:r.pts.length-1,sg=[],i,tx=r.closed?txIn(r.pts):'';
  for(i=0;i<m;i++){var a=r.pts[i],b=r.pts[(i+1)%r.pts.length],s=(r.segs||[])[i]||{},px=Math.hypot(b[0]-a[0],b[1]-a[1]),an=snapA(Math.atan2(b[1]-a[1],b[0]-a[0]));sg.push({an:an,L:s.mm>0?+s.mm:px*k,meas:s.mm>0,k:s.k||'WALL',s:s})}
  if(r.closed){var rx=0,rz=0;sg.forEach(function(q){rx+=Math.cos(q.an)*q.L;rz+=Math.sin(q.an)*q.L});
   [[0,rx],[1,rz]].forEach(function(c){var ax=c[0],res=c[1],cs=function(q){return ax?Math.sin(q.an):Math.cos(q.an)},set=sg.filter(function(q){return Math.abs(cs(q))>.99&&!q.meas});if(!set.length)set=sg.filter(function(q){return Math.abs(cs(q))>.99});var tot=set.reduce(function(s,q){return s+q.L},0);if(!tot||Math.abs(res)<.5)return;set.forEach(function(q){q.L=Math.max(10,q.L-res*Math.sign(cs(q))*q.L/tot)})})}
  var V=[[r.pts[0][0]*k,r.pts[0][1]*k]];sg.forEach(function(q){var p=V[V.length-1];V.push([p[0]+Math.cos(q.an)*q.L,p[1]+Math.sin(q.an)*q.L])});if(r.closed)V.pop();
  var CL=V;if(r.closed&&V.length>=3){var A=pArea(V),sgn=A>0?1:-1,ln=[];for(i=0;i<V.length;i++){var p0=V[i],p1=V[(i+1)%V.length],d=[p1[0]-p0[0],p1[1]-p0[1]],L=Math.hypot(d[0],d[1])||1;d=[d[0]/L,d[1]/L];var nO=sgn>0?[d[1],-d[0]]:[-d[1],d[0]];ln.push({p:[p0[0]+nO[0]*t/2,p0[1]+nO[1]*t/2],d:d})}
   CL=[];for(i=0;i<V.length;i++){var l0=ln[(i-1+V.length)%V.length],l1=ln[i],x=lineX(l0.p,l0.d,l1.p,l1.d);CL.push(x||l1.p.slice())}}
  return {r:r,ri:ri,sg:sg,V:V,CL:CL,area:r.closed?Math.abs(pArea(V)):0,off:[0,0],tx:tx,nm:(tx.split(/[\n·]/)[0]||'').trim()}});
 /* encaixa os cômodos uns nos outros pelos cantos que eram iguais no desenho */
 var placed=[],ord=RS.slice().sort(function(a,b){return b.area-a.area}),near=function(p,q){return Math.hypot(p[0]-q[0],p[1]-q[1])<5};
 ord.forEach(function(R){var full=[],perp=[];placed.forEach(function(Q){R.r.pts.forEach(function(sp,j){if(j>=R.CL.length)return;var hit=-1;Q.r.pts.forEach(function(qp,i){if(hit<0&&i<Q.CL.length&&near(sp,qp))hit=i});
   if(hit>=0){full.push([Q.CL[hit][0]+Q.off[0]-R.CL[j][0],Q.CL[hit][1]+Q.off[1]-R.CL[j][1]]);return}
   var nq=Q.r.closed?Q.r.pts.length:Q.r.pts.length-1;for(var i=0;i<nq;i++){var a=Q.r.pts[i],b=Q.r.pts[(i+1)%Q.r.pts.length];if(pSegD(sp,a,b)<5&&!near(sp,a)&&!near(sp,b)&&i<Q.CL.length){var A=[Q.CL[i][0]+Q.off[0],Q.CL[i][1]+Q.off[1]],B2=[Q.CL[(i+1)%Q.CL.length][0]+Q.off[0],Q.CL[(i+1)%Q.CL.length][1]+Q.off[1]],d=[B2[0]-A[0],B2[1]-A[1]],L=Math.hypot(d[0],d[1])||1,n=[-d[1]/L,d[0]/L];perp.push({A:A,n:n,j:j});break}}})});
  if(full.length){R.off=[full.reduce(function(s,q){return s+q[0]},0)/full.length,full.reduce(function(s,q){return s+q[1]},0)/full.length]}
  else if(perp.length){var o=[0,0];perp.forEach(function(c){var P=[R.CL[c.j][0]+o[0],R.CL[c.j][1]+o[1]],dd=(c.A[0]-P[0])*c.n[0]+(c.A[1]-P[1])*c.n[1];o=[o[0]+c.n[0]*dd,o[1]+c.n[1]*dd]});R.off=o}
  placed.push(R)});
 /* trechos de parede (eixo) de todos os cômodos; os que caem na mesma linha viram uma parede só */
 var segs=[];RS.forEach(function(R){var P=R.CL.map(function(p){return [p[0]+R.off[0],p[1]+R.off[1]]}),m=R.r.closed?P.length:P.length-1;for(var i=0;i<m;i++){var a=P[i],b=P[(i+1)%P.length];if(Math.hypot(b[0]-a[0],b[1]-a[1])<20)continue;segs.push({a:a,b:b,k:R.sg[i].k,s:R.sg[i].s,R:R,ri:R.ri,i:i,len:R.sg[i].L})}});
 var groups=[];segs.forEach(function(sg){var d=[sg.b[0]-sg.a[0],sg.b[1]-sg.a[1]],L=Math.hypot(d[0],d[1]);d=[d[0]/L,d[1]/L];if(d[0]<-1e-6||(Math.abs(d[0])<1e-6&&d[1]<0))d=[-d[0],-d[1]];var n=[-d[1],d[0]],c=n[0]*sg.a[0]+n[1]*sg.a[1],s0=d[0]*sg.a[0]+d[1]*sg.a[1],s1=d[0]*sg.b[0]+d[1]*sg.b[1];sg.d=d;sg.c=c;sg.s0=Math.min(s0,s1);sg.s1=Math.max(s0,s1);
  var g=null;groups.forEach(function(G2){if(!g&&Math.abs(G2.d[0]*d[0]+G2.d[1]*d[1])>.9994&&Math.abs(G2.c-c)<60)g=G2});if(!g){g={d:d,n:n,c:c,L:[]};groups.push(g)}g.L.push(sg)});
 groups.forEach(function(g){g.c=g.L.reduce(function(s,q){return s+q.c},0)/g.L.length;var L=g.L.slice().sort(function(a,b){return a.s0-b.s0}),cur=null,runs=[];L.forEach(function(q){if(cur&&q.s0<=cur.s1+60){cur.s1=Math.max(cur.s1,q.s1);cur.L.push(q)}else{cur={s0:q.s0,s1:q.s1,L:[q]};runs.push(cur)}});
  runs.forEach(function(rn){var P=function(s){return [Math.round(g.d[0]*s+g.n[0]*g.c),Math.round(g.d[1]*s+g.n[1]*g.c)]},w={id:cId(C.W),a:P(rn.s0),b:P(rn.s1),t:t,k:'int'};if(rn.L.every(function(q){return q.k==='DIVIDER'}))w.t=100;C.W.push(w);
   rn.L.forEach(function(q){if(q.k!=='DOOR'&&q.k!=='WINDOW'&&q.k!=='OPENING')return;var nm=((q.R.nm||'')+'').toLowerCase(),ba=/banh|lavab|wc|sanit/.test(nm),s=q.s||{},kd=q.k==='DOOR'?(s.slide?'correr':'porta'):q.k==='WINDOW'?(ba?'basc':'janela'):'vao',O=cOf(COPN,kd),l=Math.round(q.s1-q.s0),d=Math.round(q.s0-rn.s0);
    var u=[w.b[0]-w.a[0],w.b[1]-w.a[1]],uL=Math.hypot(u[0],u[1])||1,flip=(q.b[0]-q.a[0])*u[0]+(q.b[1]-q.a[1])*u[1]<0,hg=(s.hinge?1:0)^(flip?1:0);
    if(C.O.some(function(o){return o.w===w.id&&Math.min(o.d+o.l,d+l)-Math.max(o.d,d)>l*.5}))return;C.O.push({id:cId(C.O),w:w.id,k:kd,d:d,l:l,h:O[3],p:O[4],hg:hg,sd:s.side<0?-1:1})})})});
 /* portas desenhadas soltas (ferramenta Porta) */
 (J.doors||[]).forEach(function(dr){var a=[dr.a[0]*k,dr.a[1]*k],b=[dr.b[0]*k,dr.b[1]*k],m=[(a[0]+b[0])/2,(a[1]+b[1])/2],best=null,bd=600;C.W.forEach(function(w){var dd=pSegD(m,w.a,w.b);if(dd<bd){bd=dd;best=w}});if(!best)return;var u=cU(best),s=(m[0]-best.a[0])*u[0]+(m[1]-best.a[1])*u[1],l=dr.mm>0?+dr.mm:Math.hypot(b[0]-a[0],b[1]-a[1]),O=cOf(COPN,dr.slide?'correr':'porta');C.O.push({id:cId(C.O),w:best.id,k:O[0],d:Math.round(s-l/2),l:Math.round(l),h:O[3],p:0,hg:dr.hinge?1:0,sd:dr.side<0?-1:1})});
 C.O.forEach(function(o){var w=cBy(C.W,o.w),L=cLen(w);o.l=Math.min(o.l,L-20);o.d=Math.max(0,Math.min(o.d,L-o.l))});
 /* nomes e pé-direito: o texto escrito dentro do cômodo na nota */
 var S0=S.casa;S.casa=C;try{var GR=casaRooms();RS.forEach(function(R){if(!R.r.closed)return;var txt=R.tx,P=R.V.map(function(p){return [p[0]+R.off[0],p[1]+R.off[1]]}),c=pInner(P),g=null;
   GR.forEach(function(q){if(!g&&pIn(c,q.pts))g=q});if(!g)return;var nm=R.nm,ph=/p[ée][ -]?direito[^\d]*([\d.,]+)\s*(mm|cm|m)?/i.exec(txt);
   if(nm)g.r.n=nm.slice(0,40);if(ph){var v=parseFloat(ph[1].replace(',','.')),u2=(ph[2]||'').toLowerCase(),mm=u2==='mm'?v:u2==='cm'?v*10:v<20?v*1000:v;if(mm>=1800&&mm<=6000)g.r.ph=Math.round(mm)}});
  casaDefaults(C)}finally{S.casa=S0}
 return C}
/* acabamentos de partida: fora pintado areia, banheiro revestido, cozinha com azulejo até 1,80 m, piso por tipo de ambiente */
function casaDefaults(C){var S0=S.casa;S.casa=C;try{CGK='';var G=casaGeo(),R=casaRooms();
  C.W.forEach(function(w){['L','R'].forEach(function(sd){var fs=G.fs[w.id][sd];if(fs.some(function(q){return q.r==='ext'})){w.k='ext';if(!w[sd])w[sd]={f:'pin',c:'#e6dccb'}}})});
  R.forEach(function(r){var nm=r.r.n.toLowerCase(),ba=/banh|lavab|wc|sanit/.test(nm),co=/cozinh|lavand|servi|gourmet/.test(nm),ga=/garag|varand|quintal|area externa|área externa/.test(nm);
   r.r.pf=ba?'cer45':co?'porc60':/quarto|dormit|suite|suíte/.test(nm)?'mad':ga?'ext':'porc60';
   r.ed.forEach(function(q){if(q.w[q.sd])return;q.w[q.sd]=ba?{f:'rev',rv:'cer30',rh:0}:co?{f:'rev',rv:'metro',rh:1800,c:'#f2efe9'}:{f:'pin',c:'#f2efe9'}})});
  var maxph=0;R.forEach(function(r){if(+r.r.ph>0)maxph=Math.max(maxph,+r.r.ph)});if(maxph)C.cfg.h=maxph}finally{S.casa=S0;CGK=''}}
/* casa de exemplo: a mesma planta que sairia de uma nota (2 quartos, banheiro, sala e cozinha) */
function casaDemoNote(){var Kp=15,O0=[60,120],T=75,rooms=[
  {n:'Quarto 1',r:[0,3500,0,3200],op:[['t','WINDOW',1000,1200],['b','DOOR',2500,800]]},
  {n:'Banheiro',r:[3500,5300,0,3200],op:[['t','WINDOW',4100,600],['b','DOOR',4300,700]]},
  {n:'Quarto 2',r:[5300,9000,0,3200],op:[['t','WINDOW',6400,1200],['b','DOOR',5400,800]]},
  {n:'Sala · pé-direito 2,80 m',r:[0,6300,3200,8000],op:[['b','DOOR',1000,900],['b','WINDOW',3000,2000],['l','WINDOW',5000,1500]]},
  {n:'Cozinha',r:[6300,9000,3200,8000],op:[['b','WINDOW',7000,1500],['r','DOOR',5600,800]]}],J={rooms:[],doors:[],texts:[]};
 var px=function(x,z){return [O0[0]+x/Kp,O0[1]+z/Kp]};
 rooms.forEach(function(R){var x0=R.r[0],x1=R.r[1],z0=R.r[2],z1=R.r[3],ix0=x0+T,ix1=x1-T,iz0=z0+T,iz1=z1-T,pts=[],segs=[];
  var side=function(sd,from,to,fix,horiz,P0,P1){var ops=R.op.filter(function(o){return o[0]===sd}).map(function(o){return [o[2],o[2]+o[3],o[1]]});var dir=to>from?1:-1;ops.sort(function(a,b){return dir*(a[0]-b[0])});var cur=from;pts.push(P0);
   ops.forEach(function(o){var a=dir>0?o[0]:o[1],b=dir>0?o[1]:o[0];segs.push({k:'WALL',mm:Math.round(Math.abs(a-cur))});pts.push(horiz?px(a,fix):px(fix,a));segs.push({k:o[2],mm:Math.round(Math.abs(b-a)),hinge:0,side:1});pts.push(horiz?px(b,fix):px(fix,b));cur=b});segs.push({k:'WALL',mm:Math.round(Math.abs(to-cur))})};
  side('t',ix0,ix1,z0,1,px(x0,z0));side('r',iz0,iz1,x1,0,px(x1,z0));side('b',ix1,ix0,z1,1,px(x1,z1));side('l',iz1,iz0,x0,0,px(x0,z1));
  J.rooms.push({pts:pts,closed:true,segs:segs});var c=px((x0+x1)/2,(z0+z1)/2);J.texts.push({x:c[0],y:c[1],t:R.n})});
 return J}

/* tira registros de ambiente que sobraram (sem face e sem nada mudado) */
function casaPrune(){var C=casa(),R=casaRooms(),live={};R.forEach(function(r){live[r.r.id]=1});C.R=C.R.filter(function(q){return live[q.id]||!/^Ambiente \d+$/.test(q.n)})}
/* paredes na mesma linha, uma em cima da outra: viram uma parede só (portas, janelas e pontos vão junto) */
function cMerge(){var C=casa(),n=0,ch=true,g=0;while(ch&&g++<80){ch=false;for(var i=0;i<C.W.length&&!ch;i++)for(var j=i+1;j<C.W.length&&!ch;j++){var A=C.W[i],B=C.W[j],ua=cU(A),ub=cU(B);if(Math.abs(ua[0]*ub[1]-ua[1]*ub[0])>.02)continue;var na=cNL(A),pd=function(p){return Math.abs((p[0]-A.a[0])*na[0]+(p[1]-A.a[1])*na[1])};if(Math.max(pd(B.a),pd(B.b))>Math.max(cT(A),cT(B))/2)continue;
  var La=cLen(A),pa=function(p){return (p[0]-A.a[0])*ua[0]+(p[1]-A.a[1])*ua[1]},s0=pa(B.a),s1=pa(B.b),lo=Math.min(s0,s1),hi=Math.max(s0,s1);if(Math.min(hi,La)-Math.max(lo,0)<60)continue;
  var nlo=Math.min(0,lo),nhi=Math.max(La,hi),na2=cAt(A,nlo,0),nb2=cAt(A,nhi,0),flip=(na[0]*cNL(B)[0]+na[1]*cNL(B)[1])<0;
  C.O.forEach(function(o){if(o.w===A.id)o.d-=nlo;else if(o.w===B.id){var p0=pa(cAt(B,o.d,0)),p1=pa(cAt(B,o.d+o.l,0));o.w=A.id;o.d=Math.round(Math.min(p0,p1)-nlo);if(flip)o.sd=-(o.sd||1)}});
  C.P.forEach(function(p){if(p.w===A.id)p.d-=nlo;else if(p.w===B.id){p.d=Math.round(pa(cAt(B,p.d,0))-nlo);p.w=A.id;if(flip)p.s=p.s==='R'?'L':'R'}});
  C.Q.forEach(function(q){[q.a,q.b].forEach(function(r){if(r&&r.w===B.id){var s=pa(cAt(B,r.s*cLen(B),0));r.w=A.id;r.s=Math.max(0,Math.min(1,(s-nlo)/(nhi-nlo)));if(flip)r.o=-(r.o||0)}else if(r&&r.w===A.id){var s2=r.s*La;r.s=(s2-nlo)/(nhi-nlo)}})});
  if(!A.L&&B[flip?'R':'L'])A.L=B[flip?'R':'L'];if(!A.R&&B[flip?'L':'R'])A.R=B[flip?'L':'R'];A.t=Math.max(cT(A),cT(B));A.a=[Math.round(na2[0]),Math.round(na2[1])];A.b=[Math.round(nb2[0]),Math.round(nb2[1])];C.W.splice(j,1);n++;ch=true}}
 C.O.forEach(cOpFix);return n}
/* pontas soltas: grudam na ponta ou na linha da parede mais perto (até R mm), sem deixar traço solto */
function cJoin(R){var C=casa(),n=0;R=R||250;var linked=function(w,p){return C.W.some(function(o){return o!==w&&(Math.hypot(o.a[0]-p[0],o.a[1]-p[1])<=30||Math.hypot(o.b[0]-p[0],o.b[1]-p[1])<=30||pSegD(p,o.a,o.b)<=cT(o)/2+5)})};
 C.W.forEach(function(w){['a','b'].forEach(function(e){var p=w[e],q=w[e==='a'?'b':'a'];if(linked(w,p))return;var best=null,bd=R;
  C.W.forEach(function(o){if(o===w)return;[o.a,o.b].forEach(function(c){var d=Math.hypot(c[0]-p[0],c[1]-p[1]);if(d<bd){bd=d;best=c.slice()}})});
  if(!best)C.W.forEach(function(o){if(o===w)return;var r=segX(q,p,o.a,o.b);if(r&&r[1]>=-.001&&r[1]<=1.001&&r[0]>.5){var x=[q[0]+(p[0]-q[0])*r[0],q[1]+(p[1]-q[1])*r[0]],d=Math.hypot(x[0]-p[0],x[1]-p[1]);if(d<bd){bd=d;best=[Math.round(x[0]),Math.round(x[1])]}}});
  if(!best)C.W.forEach(function(o){if(o===w)return;var u=cU(o),L=cLen(o),s=(p[0]-o.a[0])*u[0]+(p[1]-o.a[1])*u[1];if(s<0||s>L)return;var x=[o.a[0]+u[0]*s,o.a[1]+u[1]*s],d=Math.hypot(x[0]-p[0],x[1]-p[1]);if(d<bd){bd=d;best=[Math.round(x[0]),Math.round(x[1])]}});
  if(best&&Math.hypot(best[0]-q[0],best[1]-q[1])>200){w[e]=best;n++}})});
 if(n)C.O.forEach(cOpFix);return n}
