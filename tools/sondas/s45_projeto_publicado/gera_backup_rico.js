const {chromium}=require('playwright');const fs=require('fs');const [PORT,PONTE,OUT]=process.argv.slice(2);
(async()=>{const b=await chromium.launch();const ctx=await b.newContext({viewport:{width:1366,height:768}});const p=await ctx.newPage();const log=[];
p.on('pageerror',e=>log.push('ERRO '+e.message.slice(0,120)));p.on('dialog',d=>d.accept('Arquemestre teste'));
await p.addInitScript(fs.readFileSync(PONTE,'utf8'));await p.goto('http://127.0.0.1:'+PORT+'/editor.html?lang=pt',{waitUntil:'load'});await p.waitForTimeout(3000);
const ev=async(js)=>{try{return await p.evaluate('(async()=>{'+js+'})()')}catch(e){return 'EXC '+String(e).slice(0,160)}};
log.push('fecha ajustes: '+await ev("PR.setupDone=1;window.MINI3OFF=1;[].forEach.call(document.querySelectorAll('div'),function(d){var cs=getComputedStyle(d);if(cs.position==='fixed'&&/Configurações da marcenaria/.test(d.textContent)&&d.getBoundingClientRect().width>300)d.style.display='none'});return 'ok'"));
const T="var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!r&&t&&!t.act&&t.n===n)r=t})});return r?JSON.parse(JSON.stringify(r)):null};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};";
/* projeto 1: cozinha completa */
log.push('P1: '+await ev(T+"newProjFor({nome:'Cliente Cozinha',end:'Rua A, 1',cidade:'Cidade',tel:'1199999'});await W(200);demoScene();await W(500);draw();var o=[];try{apAdd('geladeira',0);o.push('geladeira')}catch(e){o.push('geladeira: '+e)}try{apAdd('forno',1);o.push('forno')}catch(e){o.push('forno: '+e)}try{apAdd('tv',0);o.push('tv')}catch(e){o.push('tv: '+e)}try{if(typeof islAdd==='function'){islAdd();o.push('ilha')}}catch(e){o.push('ilha: '+e)}try{if(typeof rpAdd==='function'){rpAdd();o.push('painel')}}catch(e){o.push('painel: '+e)}draw();saveNow();await W(300);return 'mods '+S.mods.length+' stones '+S.stones.length+' fr '+(S.fr||[]).length+' isl '+(S.isl||[]).length+' rp '+(S.rp||[]).length+' · '+o.join(', ')"));
/* Meus modelos pelo quadro do app */
log.push('meus modelos: '+await ev("S.m=S.mods[1];window.mySaveOpen(S.m);return 'aberto'"));await p.waitForTimeout(500);
let salvou='';const okb=await p.$('[data-myok]');if(okb){await okb.click().catch(()=>{});salvou='data-myok'}
await p.waitForTimeout(400);log.push('meus modelos salvo: "'+salvou+'" -> '+await ev("return (PR.myMods||[]).length+' modelo(s)'"));
/* foto do projeto pelo caminho do editor (phPut, como a galeria grava) */
log.push('foto: '+await ev("var c=document.createElement('canvas');c.width=64;c.height=48;var x=c.getContext('2d');x.fillStyle='#c84';x.fillRect(0,0,64,48);x.fillStyle='#fff';x.fillText('obra',10,28);var d=c.toDataURL('image/jpeg',.9);return await new Promise(function(r){phPut({id:'f'+Date.now(),pid:CUR,kind:'projeto',data:d,nome:'obra.jpg',marks:[],created:Date.now()},function(){r('gravou')})})"));
/* preço mudado e gravado pelo editor */
log.push('preço: '+await ev("if(typeof prSave==='function'){PR.mdfM2=(+PR.mdfM2||0)+1;prSave();return 'prSave ok'}return 'sem prSave'"));
/* mexidas pra gerar o histórico de versões */
log.push('histórico: '+await ev(T+"for(var i=0;i<3;i++){snap();S.mods[0].w=S.mods[0].w+(i%2?-10:10);draw();saveNow();await W(400)}return 'ok'"));
/* projeto 2: quarto */
log.push('P2: '+await ev(T+"newProjFor({nome:'Cliente Quarto',end:'',cidade:'',tel:''});await W(200);S.env='quarto';S.room='quarto';S.W=3500;S.H=2700;newTpl(T('Guarda-roupa 3 vãos')||T('Guarda-roupa 2 vãos'));draw();var o=[];try{apAdd('cama',0);o.push('cama')}catch(e){o.push('cama: '+e)}draw();saveNow();await W(300);return 'mods '+S.mods.length+' fr '+(S.fr||[]).length+' · '+o.join(', ')"));
/* esperado: peças e corte de cada projeto, aberto pelo caminho do app */
const esp=await ev(T+"var out={};var L=pLoadAll();for(var i=0;i<L.length;i++){var id=L[i].id;window.arqueOpenClient(id);await W(500);out[id]={cliente:(L[i].client||{}).nome,mods:S.mods.length,pecas:S.mods.map(function(m){return partsOf(m).filter(function(q){return !q.noCut&&q.cl>0&&q.cw>0}).map(function(q){return q.name+' '+q.cl+'x'+q.cw+' q'+(q.qty||1)}).sort()}),corte:(function(){try{var G=cutGroups();return G.ord.map(function(k){var g=G.map[k];return [g.fin||'',g.qty,(g.names||[]).join('/')].join(' ')}).sort()}catch(e){return ['ERRO '+e]}})()}}return JSON.stringify(out)");
const files=await ev("return JSON.stringify(window.__files||{})");
fs.writeFileSync(OUT+'/esperado.json',esp);fs.writeFileSync(OUT+'/arquivos.json',files);
console.log(log.join('\n'));let F={};try{F=JSON.parse(files)}catch(e){console.log('arquivos: '+files.slice(0,200))}console.log('arquivos gravados pelo editor: '+Object.keys(F).map(k=>k+' '+String(F[k]).length).join(' | '));
let E={};try{E=JSON.parse(esp)}catch(e){console.log('esperado: '+esp.slice(0,200))}console.log('projetos: '+Object.keys(E).map(k=>k+' '+E[k].cliente+' mods '+E[k].mods+' corte '+E[k].corte.length).join(' | '));await b.close()})();
