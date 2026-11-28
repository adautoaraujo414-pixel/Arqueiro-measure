/* Auditoria independente (Claude 5, 28/11, pedido do Chefe) das entregas do Code 2: item 21 (não une sozinho + Unir completo), 22/32 (travessa frontal
   e teto independentes, painel não pula), 33 (moldura) e "vizinho igual em todo caminho". Age pela tela (botões e caixinhas da Estrutura). */
window.MINI3OFF=1;PR.setupDone=1;var TS=[];window.toast=function(t){TS.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n&&!t.act)it=t})});if(!it)throw new Error('sem '+n);return JSON.parse(JSON.stringify(it))};
Object.keys(PRAVG).forEach(function(k){PR[k]=PRAVG[k]});
var R={erros:[],c21:{},c22:[],viz:[],combo:[]},e0=__errs.length;
var J=function(o){return JSON.stringify(o)},semMarca=function(m){var c=JSON.parse(J(m));['une','unV','uneK','uid','_gel'].forEach(function(k){delete c[k]});return J(c)};
var nomes=function(){var G=cutGroups(),r=[];G.ord.forEach(function(k){var g=G.map[k];g.names.forEach(function(n){if(r.indexOf(n)<0)r.push(n)})});return r};
var unidas=function(){return nomes().filter(function(n){return /contínu|corrida|unid/i.test(n)})};
var coer=function(){var b=budget(),L=prAuto(b),soma=L.reduce(function(s,r){return s+r[3]*(+PR[r[0]]||0)},0)+b.cat.t+(b.rpC||0),G=cutGroups(),nL=0;G.ord.forEach(function(k){var g=G.map[k],lay=(+g.mat>18&&+g.mat%15===0)?+g.mat/15:1;nL+=g.qty*lay});var nP=0;b.plan.groups.forEach(function(g){g.sheets.forEach(function(s){nP+=s.used.length});nP+=(g.big||[]).length});var off=(b.plan.off||[]).reduce(function(s,o){return s+o.q},0);return (Math.abs(soma-b.tot)<0.005?'':'ORC≠ ')+(nL===nP+off?'':'LISTA'+nL+'≠PLANO'+(nP+off))};
var fila=function(nms,sup){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=6000;S.H=2700;S.mods=[];draw();var x=0;nms.forEach(function(n){newTpl(T(n));var m=S.mods[S.mods.length-1];m.x=x;x+=m.w});draw();var st=J(snapState());loadState(JSON.parse(st));draw();return S.mods};
var abre=async function(m){S.m=m;S.tab=0;try{panel()}catch(_){}await W(40);return document.getElementById('bd')};
var reabreIgual=function(){var a=J(snapState());loadState(JSON.parse(a));draw();return J(snapState())===a};
try{
 /* ===== item 21: não une sozinho; Unir / Separar / desfazer / reabrir / escolha por peça / > 2700 ===== */
 var M=fila(['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas']);R.c21.criaSemUnir=unidas().join(',')||'nada unido';var viz0=M.map(semMarca);
 var bd=await abre(M[0]),b=bd.querySelector('[data-une="1"]');R.c21.botaoUnir=!!b;if(b){await W(800);var st0=J(snapState());b.click();await W(60);
  R.c21.unir=unidas().join(',')+' · marca '+(M[0].une&&M[0].une===M[1].une)+' · vizinhos iguais '+M.every(function(m,i){return semMarca(m)===viz0[i]})+' · '+(coer()||'lista=plano, orçamento ok');
  await W(800);document.getElementById('und').click();await W(80);R.c21.desfazUnir=(J(snapState())===st0)+' · '+(unidas().join(',')||'nada unido');document.getElementById('red').click();await W(80);R.c21.refaz=unidas().join(',');
  R.c21.reabre=reabreIgual();M=S.mods;
  bd=await abre(M[0]);var ks=[].map.call(bd.querySelectorAll('[data-unek]'),function(c){return c.dataset.unek+(c.checked?'✓':'')});R.c21.caixinhas=ks.join(' ');
  ['trav','mold'].forEach(function(k){var c=bd.querySelector('[data-unek="'+k+'"]');if(c&&!c.checked){c.click()}});await W(60);R.c21.comTravMold=unidas().join(',')+' · '+(coer()||'ok');

  M=S.mods;bd=await abre(M[1]);var b2=bd.querySelector('[data-une="-1"]');if(b2)b2.click();await W(40);bd=await abre(M[1]);var b3=bd.querySelector('[data-une="1"]');if(b3)b3.click();await W(40);R.c21.tresUnidos=unidas().join(',')+' · '+(coer()||'ok');
  bd=await abre(M[1]);var sp=bd.querySelector('[data-unsep="1"]');if(sp)sp.click();await W(40);R.c21.separaUmaJunta=unidas().join(',')+' · marcas '+M.map(function(m){return m.une?m.une.slice(-3):'-'}).join('/');}
 M=fila(['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas','Balcão 2 portas']);for(var i=0;i<3;i++){var bb=(await abre(M[i])).querySelector('[data-une="1"]');if(bb)bb.click();await W(30)}var G=cutGroups(),Ls=[];G.ord.forEach(function(k){var g=G.map[k];if(/contínu|corrida/.test(g.names.join()))Ls.push(g.names[0].slice(0,22)+' '+g.L+'×'+g.qty)});R.c21.quatroAte2700=Ls.join(' | ');
 /* ===== itens 22/32/33: cada caixinha da Estrutura sozinha, e todas juntas, em balcão, aéreo e armário alto ===== */
 var casos=[['Balcão 2 portas',['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas'],1],['Aéreo 2 portas',['Aéreo 2 portas','Aéreo 2 portas','Aéreo 2 portas'],1],['Armário alto 2 portas',['Balcão 2 portas','Armário alto 2 portas','Balcão 2 portas'],1]];
 for(var ci=0;ci<casos.length;ci++){var cs=casos[ci];M=fila(cs[1]);var alvo=M[cs[2]],base=J(snapState());bd=await abre(alvo);var cbs=[].filter.call(bd.querySelectorAll('input[type=checkbox][data-rc],input[type=checkbox][data-tt]'),function(c){return !c.disabled});
  var ids=cbs.map(function(c){return c.dataset.rc?'rc='+c.dataset.rc:'tt='+c.dataset.tt});
  for(var k=0;k<ids.length;k++){loadState(JSON.parse(base));draw();M=S.mods;alvo=M[cs[2]];bd=await abre(alvo);var sel='input[data-'+ids[k].replace('=','="')+'"]',c=bd.querySelector(sel);if(!c){R.c22.push(cs[0]+' '+ids[k]+': sumiu');continue}
   c.scrollIntoView({block:'center'});await W(20);var y0=c.getBoundingClientRect().top,a0=JSON.parse(J(alvo)),v0=M.filter(function(m){return m!==alvo}).map(semMarca),tl=TS.length,was=c.checked;await W(800);var stA=J(snapState());c.click();await W(80);
   var c2=document.querySelector('#bd '+sel),y1=c2?c2.getBoundingClientRect().top:null,a1=JSON.parse(J(alvo)),mud=Object.keys(Object.assign({},a0,a1)).filter(function(q){return J(a0[q])!==J(a1[q])}),vz=M.filter(function(m){return m!==alvo}).every(function(m,i){return semMarca(m)===v0[i]});
   var stB,outros=[].filter.call(document.querySelectorAll('#bd input[type=checkbox][data-rc],#bd input[type=checkbox][data-tt]'),function(x){return x!==c2}).map(function(x){return (x.dataset.rc||x.dataset.tt)+(x.checked?'1':'0')}).join(','),stB=J(snapState());
   /* desfazer antes de reabrir (reabrir mexe no histórico) */await W(800);document.getElementById('und').click();await W(80);var des=J(snapState())===stA;loadState(JSON.parse(stB));draw();var reab=reabreIgual();M=S.mods;alvo=M[cs[2]];
   R.c22.push(cs[0]+' · '+ids[k]+' '+(was?'on→off':'off→on')+' · mudou '+(mud.join('+')||'NADA')+(c2&&c2.checked===was?' · CAIXINHA NAO MUDOU':'')+(vz?'':' · VIZINHO MUDOU')+(y1===null?' · controle sumiu':Math.abs(y1-y0)>40?' · PULOU '+Math.round(y1-y0):'')+' · '+(coer()||'ok')+(reab?'':' · REABRE≠')+(des?'':' · NAO DESFAZ')+(TS.length>tl?' · aviso: '+TS.slice(tl).join(' / ').slice(0,90):''))}
  /* todas ligadas, uma depois da outra: nenhuma desliga outra */loadState(JSON.parse(base));draw();M=S.mods;alvo=M[cs[2]];var lig=[];for(k=0;k<ids.length;k++){bd=await abre(alvo);var cc=bd.querySelector('input[data-'+ids[k].replace('=','="')+'"]');if(cc&&!cc.checked&&!cc.disabled){cc.click();await W(40);lig.push(ids[k])}}
  bd=await abre(alvo);var desl=lig.filter(function(id){var x=bd.querySelector('input[data-'+id.replace('=','="')+'"]');return !x||!x.checked});R.combo.push(cs[0]+': ligou '+lig.join(',')+(desl.length?' · DESLIGOU SOZINHO: '+desl.join(','):' · todas continuam ligadas')+' · '+(coer()||'ok')+(reabreIgual()?'':' · REABRE≠'))}
 /* ===== vizinho igual em todo caminho: largura, x digitado, altura, profundidade ===== */
 M=fila(['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas']);var cam=[['w','1000'],['x','100'],['h','900'],['d','600']];
 for(var q=0;q<cam.length;q++){var st=J(snapState());loadState(JSON.parse(st));draw();M=S.mods;S.m=M[1];var v1=[semMarca(M[0]),semMarca(M[2])];try{setv(cam[q][0],cam[q][1])}catch(x){R.erros.push('setv '+cam[q][0]+': '+x)}draw();await W(30);var dd=function(a,b){a=JSON.parse(a);b=JSON.parse(b);return Object.keys(Object.assign({},a,b)).filter(function(z){return J(a[z])!==J(b[z])}).map(function(z){return z+':'+J(a[z])+'→'+J(b[z])}).join(' ')};R.viz.push(cam[q][0]+'='+cam[q][1]+': '+((semMarca(M[0])===v1[0]&&semMarca(M[2])===v1[1])?'vizinhos iguais':'VIZINHO MUDOU esq['+dd(v1[0],semMarca(M[0]))+'] dir['+dd(v1[1],semMarca(M[2]))+']')+' · módulo '+M[1][cam[q][0]]+' · aviso: '+TS.slice(-1).join('').slice(0,120))}
}catch(x){R.erros.push(String(x&&x.stack||x).slice(0,300))}
R.errsJS=__errs.slice(e0,e0+5);return JSON.stringify(R);
