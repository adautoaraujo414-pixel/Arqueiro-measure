window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* TORRE-GEL-PORTA: projeto salvo em que a caixa da geladeira já tinha virado porta inteira (como no vídeo de 16/11 às 13:34).
   Abrir não muda nada; a aba Portas avisa e o botão volta a caixa (porta só em cima, nicho e prateleira de volta, tamponamento igual). */
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(t&&t.n===n&&!r)r=t})});return JSON.parse(JSON.stringify(r))};
loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3000;S.H=2700;S.stones=[];S.mods=[];draw();newTpl(T('Caixa da geladeira side by side (laterais + aéreo)'));var m=S.mods[0];m.x=600;m.tl=true;m.tr=true;
m.v[0].k='door';m.v[0].n=1;draw();
var st=function(m){var P=partsOf(m),pt=P.filter(function(p){return p.name==='Porta'});return m.v[0].k+' · portas '+pt.length+(pt.length?' '+pt.map(function(p){return p.cl+'×'+p.cw}).join(','):'')+' · nicho '+P.some(function(p){return p.gelN})+' · tamp '+P.filter(function(p){return /^Tamponamento (esquerdo|direito)$/.test(p.name)}).map(function(p){return p.cl}).join(',')};
var salvo=JSON.stringify(snapState());loadState(JSON.parse(salvo));draw();m=S.mods[0];S.m=m;S.sv=0;draw();var A_=JSON.parse(salvo).mods[0],B_=snapState().mods[0];R.abriuIgual=st(m)+' · mudou ao abrir: '+(Object.keys(Object.assign({},A_,B_)).filter(function(k){return JSON.stringify(A_[k])!==JSON.stringify(B_[k])&&!(!A_[k]&&!B_[k])/* undefined→0 não é mudança */}).map(function(k){return k+' '+JSON.stringify(A_[k])+'→'+JSON.stringify(B_[k])}).join(', ')||'nada');
S.tab=3;panel();await W(60);var bd=document.getElementById('bd');R.aviso=!!bd.querySelector('[data-gelvolta]')&&/tampa a geladeira/.test(bd.querySelector('[data-gelvolta]').textContent);
bd.querySelector('[data-gelback]').click();await W(60);R.voltou=st(m);R.avisoSumiu=!document.querySelector('#bd [data-gelvolta]');
/* caixa normal (sem ter virado porta) não mostra o aviso */
loadState(initLimpo());S.mods=[];newTpl(T('Caixa da geladeira duplex / inverse (laterais + aéreo)'));S.m=S.mods[0];S.sv=0;S.tab=3;draw();panel();await W(40);R.caixaNormalSemAviso=!document.querySelector('#bd [data-gelvolta]');
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
