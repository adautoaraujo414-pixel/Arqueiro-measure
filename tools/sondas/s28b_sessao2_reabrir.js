/* Sessão 2: editor novo, só com os arquivos e o navegador da sessão 1 */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={};await W(500);
var L=pLoadAll();R.projetos=L.filter(function(q){return /^Sessão/.test(q.client.nome)}).map(function(q){return q.client.nome+' '+q.current.mods.length}).join(' | ');
var p=L.filter(function(q){return q.id==='pS'})[0];CUR=p.id;loadState(p.current);draw();await W(700);R.dims=S.mods.map(function(m){return [Math.round(m.x),m.w,m.h,m.d].join('/')}).join(' ');
var c=L.filter(function(q){return /cópia/.test(q.client.nome)})[0];R.copiaIgual=!!c&&JSON.stringify(c.current.mods)===JSON.stringify(p.current.mods);
R.avisos=window.fgConflitos?fgConflitos().length:-1;R.updatedNaoMudouAoAbrir=pLoadAll().filter(function(q){return q.id==='pS'})[0].updated===p.updated;
return JSON.stringify(R);
