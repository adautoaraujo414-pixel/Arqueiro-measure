window.MINI3OFF=1;PR.setupDone=1;var W=function(t){return new Promise(function(r){setTimeout(r,t)})};
var T=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n&&!t.act)it=t})});return JSON.parse(JSON.stringify(it))};
loadState(initLimpo());S.W=4000;S.mods=[];draw();newTpl(T('Balcão 2 portas'));newTpl(T('Aéreo 2 portas'));draw();Object.keys(PRAVG).forEach(function(k){PR[k]=PRAVG[k]});PR.mult=2;
PR.cfxLib=[cfxLimpa({n:'Frete padrão',d:'até 30 km',t:'R',v:150}),cfxLimpa({n:'Comissão do arquiteto',t:'P',v:10,base:'fin'})];
S.cfx=[cfxLimpa({n:'Montagem',d:'equipe de 2 pessoas',t:'R',v:350,cli:1}),cfxLimpa({n:'Transporte',t:'R',v:120.5}),cfxLimpa({n:'Taxa administrativa',t:'P',v:5,base:'mat'})];S.cfxModo=window.__MODO||'emb';if(S.cfxModo==='emb')delete S.cfxModo;
vlOpen();await W(400);var x=document.getElementById(window.__ALVO||'cfxbox');if(x)x.scrollIntoView({block:'start'});await W(200);return JSON.stringify(quoteData().items.map(function(i){return i.desc+'='+i.value}));
