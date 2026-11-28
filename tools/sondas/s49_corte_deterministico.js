/* N11 (item 30): o plano de corte não pode depender do relógio. 142 modelos do catálogo, cada um com 3 relógios:
   normal · parado (máquina "infinitamente rápida": só o nº de tentativas limita) · carregado (cada leitura do relógio anda 40 ms).
   Compara o HTML do plano (planHtml(sheetPlan())) e o nº de chapas. Sem SPC (cache) entre as rodadas. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};
var its=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(t&&!t.act&&t.w&&t.h)its.push(t)})});
var clr=function(){S.stones=[];S.st=null;S.rp=[];S.fr=[];S.ops=[];S.mods=[];S.room='livre';S.env='livre';S.W=6000;S.RD=3500;S.H=3000;S.m=null};
var DN=Date.now,PN=performance.now.bind(performance),modo='n',falso=0;
Date.now=function(){if(modo==='p')return 1e12;if(modo==='c'){falso+=40;return DN()+falso}return DN()};
performance.now=function(){if(modo==='p')return 1e6;if(modo==='c'){falso+=40;return PN()+falso}return PN()};
var LAY=function(pl){return JSON.stringify(pl.groups.map(function(g){return g.sheets.map(function(s){return s.used.map(function(u){return [u.p.lab,u.x,u.y,u.w,u.h,u.r?1:0]})})}))};
var plano=function(m_){modo=m_;falso=0;try{SPC={};var pl=sheetPlan();return {h:planHtml(pl),l:LAY(pl),n:pl.groups.map(function(g){return g.n}).join('+')}}finally{modo='n';SPC={}}};
/* abrir a lista de corte: 1º o plano rápido (CUTFAST) e depois o "melhor aproveitamento" em segundo plano (deepInit/deepStep + packTight), aqui sem esperar a tela */
var rapido=function(m_){modo=m_;falso=0;window.CUTFAST=1;window.CUTJOBS=[];try{SPC={};var pl=sheetPlan();window.CUTFAST=0;var J=window.CUTJOBS.slice(),D=J.map(function(j){var st=deepInit(j);while(!deepStep(st,j,1e12)){}return packTight(deepRes(st),j.SW,j.SH,j.kf,j.rot,st.mt)});
  return {h:planHtml(pl),l:LAY(pl),d:JSON.stringify(D.map(function(r){return r.sheets.map(function(s){return s.used.map(function(u){return [u.x,u.y,u.w,u.h,u.r?1:0]})})}))}}finally{modo='n';window.CUTFAST=0;window.CUTJOBS=[];SPC={}}};
var H_=function(t){var h=0;for(var i=0;i<t.length;i++)h=(h*31+t.charCodeAt(i))|0;return h};var R={sig:{},sigParado:{},rapidoNxP:[],rapidoNxC:[],fundoNxP:[],fundoNxC:[],N:0,normalXparado:[],normalXcarregado:[],repete:[],erros:[]};
for(var i=0;i<its.length;i++){var it=its[i];try{clr();newTpl(JSON.parse(JSON.stringify(it)));if(!S.mods.length)continue;R.N++;draw();
 var a=plano('n'),b=plano('p'),c=plano('c'),d=plano('n');
 if(a.h!==b.h)R.normalXparado.push(it.n+' ('+a.n+' × '+b.n+')');if(a.h!==c.h)R.normalXcarregado.push(it.n+' ('+a.n+' × '+c.n+')');if(a.h!==d.h)R.repete.push(it.n);
 var f1=rapido('n'),f2=rapido('p'),f3=rapido('c');if(f1.h!==f2.h)R.rapidoNxP.push(it.n);if(f1.h!==f3.h)R.rapidoNxC.push(it.n);R.sig[it.n]=[H_(a.l),H_(f1.l),H_(f1.d)].join(',');R.sigParado[it.n]=[H_(b.l),H_(f2.l),H_(f2.d)].join(',');if(f1.d!==f2.d)R.fundoNxP.push(it.n);if(f1.d!==f3.d)R.fundoNxC.push(it.n);
}catch(e){R.erros.push(it.n+': '+String(e).slice(0,100))}}
Date.now=DN;performance.now=PN;
return JSON.stringify(R);
