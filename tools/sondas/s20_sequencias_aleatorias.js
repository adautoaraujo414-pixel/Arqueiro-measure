/* Sequências aleatórias reproduzíveis (semente fixa) com conferência de invariantes a cada passo.
   Ações pelos caminhos do app sempre que existe função pública (setv, newTpl, tpDesliga, histGo pelos botões ↶/↷, loadState como na abertura).
   Invariantes:
     I1 sem erro de JavaScript novo
     I2 desenhar de novo não muda o projeto
     I3 salvar e reabrir: peças, corte e 3D iguais
     I4 todo módulo tem caixas no 3D
     I5 peça de corte com medida positiva, finita e sem décimo de mm
     I6 módulo dentro da parede (x ≥ 0, fim ≤ parede, b ≥ 0, topo ≤ pé-direito) — só módulos da parede do fundo
     I7 módulos da mesma parede/altura não se sobrepõem (> 1 mm)
     I8 ↶ desfazer volta ao estado antes da ação e ↷ refazer volta ao depois
   Parâmetros: window.__SEEDS (padrão 1..8), window.__STEPS (padrão 30). */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var SEEDS=window.__SEEDS||[1,2,3,4,5,6,7,8],STEPS=window.__STEPS||30;
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h&&/cozinha|Balcão|Aéreo|Torre|Gaveteiro|Armário|Paneleiro|Despense/i.test((c.n||'')+' '+it.n))its.push(it)})});
if(its.length<10){its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!it.act&&it.w&&it.h)its.push(it)})})}
var rng;function mk(s){return function(){s|=0;s=s+0x6D2B79F5|0;var t=Math.imul(s^s>>>15,1|s);t=t+Math.imul(t^t>>>7,61|t)^t;return ((t^t>>>14)>>>0)/4294967296}}
var ri=function(a,b){return a+Math.floor(rng()*(b-a+1))},pick=function(a){return a[Math.floor(rng()*a.length)]};
/* normalização conhecida e inofensiva da abertura (wing indefinido = 0, amb indefinido = {}) não conta como diferença */
var NRM=function(o){(o.mods||[]).concat(o.m?[o.m]:[]).forEach(function(m){if(m&&m.wing===undefined)m.wing=0});if(o.amb===undefined)o.amb={};return o};
var SN=function(){return JSON.stringify(NRM(JSON.parse(JSON.stringify(snapState()))))};
var sigP=function(){return S.mods.map(function(m){try{return partsOf(m).map(function(p){return p.pk+' '+Math.round(p.cl*10)/10+'x'+Math.round(p.cw*10)/10+' q'+(p.qty||1)}).sort().join(';')}catch(e){return 'ERRO '+e}}).join('#')};
var sigC=function(){try{return JSON.stringify(cutGroups())}catch(e){return 'ERRO '+e}};
var sigB=function(){__build();return __boxes().filter(function(q){return q.pk}).map(function(q){return (q.nm||'').split(':')[0]+'|'+q.pk+'@'+[q.x0,q.x1,q.y0,q.y1,q.z0,q.z1].map(function(v){return Math.round(v)}).join(',')}).sort().join(';')};
function diff(a,b,p,out){if(out.length>6)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+'='+JSON.stringify(a)+'→'+JSON.stringify(b));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var dd=function(x,y){var o=[];diff(JSON.parse(x),JSON.parse(y),'',o);return o.join(' ')};
var other=null;
var OPS={
 add:function(){var it=pick(its);newTpl(JSON.parse(JSON.stringify(it)));return 'add '+it.n},
 del:function(){if(S.mods.length<2)return null;var i=ri(0,S.mods.length-1);var n=S.mods[i].n||S.mods[i].t;S.mods.splice(i,1);S.m=S.mods[0]||null;draw();return 'del '+i+' '+n},
 sel:function(){if(!S.mods.length)return null;var i=ri(0,S.mods.length-1);S.m=S.mods[i];draw();return 'sel '+i},
 w:function(){if(!S.m)return null;var v=ri(30,120)*10;setv('w',v);return 'w='+v},
 h:function(){if(!S.m)return null;var v=ri(30,240)*10;setv('h',v);return 'h='+v},
 d:function(){if(!S.m)return null;var v=ri(25,65)*10;setv('d',v);return 'd='+v},
 x:function(){if(!S.m)return null;var v=pick([0,5,15,25,35,45,ri(0,400)*10]);setv('x',v);return 'x='+v},
 b:function(){if(!S.m)return null;var v=pick([0,0,150,300,1500]);setv('b',v);return 'b='+v},
 W:function(){var v=ri(20,60)*100;setv('W',v);return 'W='+v},
 H:function(){var v=ri(22,32)*100;setv('H',v);return 'H='+v},
 tampOn:function(){if(!S.m)return null;var k=pick(['tl','tr','tt','tb']);snap();S.m[k]=true;S.m[k+'M']=1;draw();return 'tamp '+k+' on'},
 tampOff:function(){if(!S.m)return null;var k=pick(['tl','tr','tt','tb']);if(!S.m[k])return null;snap();tpDesliga(S.m,k);draw();return 'tamp '+k+' off'},
 vao:function(){if(!S.m||!S.m.v||!S.m.v.length)return null;var i=ri(0,S.m.v.length-1),k=pick(['door','drawers','shelves','free']);snap();S.m.v[i].k=k;if(k!=='free')S.m.v[i].n=Math.max(1,S.m.v[i].n||1);draw();return 'vão '+i+'='+k},
 esp:function(){if(!S.m)return null;var v=pick([15,18,25]);snap();S.m.esp=v;draw();return 'esp='+v},
 tresD:function(){open3D();var x=document.getElementById('v3x');if(x&&rng()<.5)x.click();return '3D'},
 reabrir:function(){loadState(JSON.parse(SN()));draw();return 'salvar e reabrir'},
 projeto:function(){var a=SN();if(!other){loadState(initLimpo());S.env='cozinha';S.W=3600;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(pick(its))));draw();other=SN()}else{loadState(JSON.parse(other));draw();other=SN()}loadState(JSON.parse(a));draw();return 'outro projeto e volta'},
 corte:function(){cutGroups();return 'corte'}
};
var NAMES=Object.keys(OPS),PESO={add:3,del:1,sel:2,w:3,h:2,d:1,x:3,b:1,W:2,H:1,tampOn:2,tampOff:2,vao:2,esp:1,tresD:1,reabrir:1,projeto:1,corte:1},BAG=[];NAMES.forEach(function(n){for(var i=0;i<PESO[n];i++)BAG.push(n)});
var V={},ex=function(k,txt){(V[k]=V[k]||[]).push(txt)};
draw();open3D();await W(300);
for(var si=0;si<SEEDS.length;si++){var seed=SEEDS[si];rng=mk(seed);other=null;
 loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3600;S.H=2700;draw();newTpl(JSON.parse(JSON.stringify(its[0])));draw();S.m=S.mods[0];
 var hist=[];
 for(var st=0;st<STEPS;st++){var op=pick(BAG),e0=__errs.length,pre=SN(),lbl=null;
  try{lbl=OPS[op]()}catch(e){lbl=op+' (exceção '+String(e).slice(0,80)+')';ex('I1 exceção',seed+'#'+st+' '+lbl)}
  if(lbl===null)continue;hist.push(lbl);var tag='semente '+seed+' passo '+st+' ['+hist.slice(-4).join(' > ')+']';
  if(__errs.length>e0)ex('I1 erro JS',tag+' '+__errs.slice(e0,e0+2).join(' | ').slice(0,160));
  var a=SN();draw();var b=SN();if(a!==b)ex('I2 desenhar de novo muda',tag+' '+dd(a,b));
  var P0=sigP(),C0=sigC(),B0=sigB(),keep=SN();loadState(JSON.parse(keep));draw();var P1=sigP(),C1=sigC(),B1=sigB();
  if(P0!==P1)ex('I3 reabrir muda peças',tag);if(C0!==C1)ex('I3 reabrir muda corte',tag);if(B0!==B1)ex('I3 reabrir muda 3D',tag);
  var nb={};__boxes().forEach(function(q){var mi=parseInt(String(q.nm),10);if(!isNaN(mi))nb[mi]=1});S.mods.forEach(function(m,i){if(!nb[i]&&!window.ST3ONLY)ex('I4 módulo sem 3D',tag+' módulo '+i+' '+(m.n||m.t))});
  S.mods.forEach(function(m,i){try{cutLines(m).forEach(function(l){if(!(l.L>0&&l.W>0&&isFinite(l.L)&&isFinite(l.W)))ex('I5 medida inválida',tag+' '+(m.n||'')+' '+l.L+'×'+l.W);else if(l.L!==Math.floor(l.L)||l.W!==Math.floor(l.W))ex('I5 décimo de mm',tag+' '+l.L+'×'+l.W)})}catch(e){ex('I5 corte com exceção',tag+' '+String(e).slice(0,80))}});
  S.mods.forEach(function(m,i){if(m.wing||m.corner)return;var b_=+m.b||0;if(m.x<-0.5||m.x+m.w>S.W+0.5||b_<-0.5||b_+m.h>S.H+0.5)ex('I6 fora da parede',tag+' módulo '+i+' x='+m.x+' w='+m.w+' b='+b_+' h='+m.h+' W='+S.W+' H='+S.H)});
  for(var i=0;i<S.mods.length;i++)for(var j=0;j<i;j++){var p=S.mods[i],q=S.mods[j];if((p.wing||'F')!==(q.wing||'F')||p.corner||q.corner||p.slIn||q.slIn)continue;var ox=Math.min(p.x+p.w,q.x+q.w)-Math.max(p.x,q.x),pb=+p.b||0,qb=+q.b||0,oy=Math.min(pb+p.h,qb+q.h)-Math.max(pb,qb);if(ox>1&&oy>1)ex('I7 módulos sobrepostos',tag+' '+j+'×'+i+' '+Math.round(ox)+'×'+Math.round(oy)+' mm')}
  if(op!=='reabrir'&&op!=='projeto'&&op!=='tresD'&&op!=='corte'&&op!=='sel'){
   /* desfazer: monta o histórico com o antes e o depois e confere ↶ ↷ */
   /* o histórico como o histTick deixa: o antes na pilha e o depois como atual */
   var post=SN();HIST=[{s:pre,k:histKey(JSON.parse(pre))}];FUT=[];LASTS={s:post,k:histKey(JSON.parse(post))};
   document.getElementById('und').onclick();var u=SN();document.getElementById('red').onclick();var r=SN();
   var dpre=dd(pre,u),dpost=dd(post,r);if(dpre)ex('I8 desfazer não volta',tag+' '+dpre);if(dpost)ex('I8 refazer não volta',tag+' '+dpost);
   loadState(JSON.parse(post));draw()}
 }}
var R={sementes:SEEDS.length,passos:STEPS,invariantes:{}};Object.keys(V).forEach(function(k){R.invariantes[k]=V[k].length+' :: '+V[k].slice(0,4).join(' ‖ ')});
return JSON.stringify(R);
