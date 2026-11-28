/* Item 40 (ETAPA 2, parte financeira e de dados · Claude 5, 28/11): orçamento × lista × plano de corte × fitas × ferragens × materiais
   em 3 ambientes de um cliente (orçamentos de 1, 2 e 3 ambientes); salvar/reabrir; arquivos do backup (projects.json, prices.json).
   Rodar com ?un=mm e ?un=cm: o resultado em dinheiro e quantidade tem que ser o mesmo (só o texto da medida muda). */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
var T=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n&&!t.act)it=t})});if(!it)throw new Error('sem modelo '+n);return JSON.parse(JSON.stringify(it))};
var r2=function(v){return Math.round((+v||0)*100)/100},r3=function(v){return Math.round((+v||0)*1000)/1000};
Object.keys(PRAVG).forEach(function(k){PR[k]=PRAVG[k]});PR.mult=2.5;['pux','concha','perfilG','perfil','facetado','toque','pesQ','pesR','coro'].forEach(function(k){if(!(+PR[k]>0))PR[k]=10});prSave();
var AMB=[['Cozinha',['Balcão 2 portas','Balcão da pia (cuba)','Gaveteiro 3 gavetas','Aéreo 2 portas','Aéreo basculante','Torre quente (forno)']],
 ['Quarto',['Guarda-roupa 3 vãos','Cômoda 4 gavetas']],['Sala',['Estante torre aberta com gavetas embaixo','Nicho com prateleiras']]];
var R={un:UN.u(),amb:{},orc:{},erros:[]},PIDS=[];
var mk=function(tit,mods){newProjFor({nome:'Cliente Financeiro',end:'Rua 1',cidade:'Frutal',tel:'1'});var a=pLoadAll(),p=a.filter(function(q){return q.id===CUR})[0];p.titulo=tit;pSaveAll(a);S.W=6000;S.mods=[];draw();var x=0;mods.forEach(function(n){newTpl(T(n));var m=S.mods[S.mods.length-1];m.x=x;x+=m.w+50});draw();saveNow();return CUR};
var sinal=function(){var b=budget(),L=prAuto(b),fk=fK();
 /* 1) orçamento por dentro */var soma=L.reduce(function(s,r){return s+r[3]*(+PR[r[0]]||0)},0)+b.cat.t+(b.rpC||0);
 var porMod=b.rows.reduce(function(s,x){return s+x.c},0)+b.cat.t+(b.rpC||0);
 var ch=0;b.plan.groups.forEach(function(g){ch+=g.n*chUso(g)*(+g.price||0)});
 /* 2) lista × plano: peças e área */var G=cutGroups(),nL=0,aL=0;G.ord.forEach(function(k){var g=G.map[k],lay=(+g.mat>18&&+g.mat%15===0)?+g.mat/15:1;nL+=g.qty*lay;aL+=g.qty*lay*g.L*g.W});
 var nP=0,aP=0,nb=0;b.plan.groups.forEach(function(g){g.sheets.forEach(function(s){s.used.forEach(function(u){nP++;aP+=u.p.w*u.p.h})});(g.big||[]).forEach(function(p){nb++;nP++;aP+=p.w*p.h})});var off=(b.plan.off||[]).reduce(function(s,o){return s+o.q},0);
 /* 3) fita: metros do orçamento × metros pelos lados de cada peça do plano */var mO=(b.T.tB+b.T.tC+(b.T.tT||0)),mP=0,porNome={};b.plan.groups.forEach(function(g){g.sheets.forEach(function(s){s.used.forEach(function(u){var sd=u.p.fs!=null?u.p.fs:edgeSides(u.p.lab),mm=fitaMmSd(sd,u.p.w,u.p.h);mP+=mm/1000;var nn=String(u.p.lab).replace(/ \(camada.*$/,'');porNome[nn]=(porNome[nn]||0)+mm/1000})})});
 var mPartes=0,porNomeO={};S.mods.forEach(function(m){partsOf(m).forEach(function(p){var q=+p.qty||1,e=edgeMmOf(m,p)/1000*q;mPartes+=e;porNomeO[p.name]=(porNomeO[p.name]||0)+e})});
 var dif=[];Object.keys(porNomeO).concat(Object.keys(porNome)).filter(function(v,i,a){return a.indexOf(v)===i}).forEach(function(n){var a=r3(porNomeO[n]||0),c=r3(porNome[n]||0);if(Math.abs(a-c)>0.001)dif.push(n+': partes '+a+' × plano '+c)});
 /* 4) ferragens: orçamento × 3D *//* no 3D: cada dobradiça = 20 caixas da porta marcadas como ferragem (calço, braço, caneco, parafusos); cada par de corrediças = 6 caixas */var hB=0,cB3=0;try{__build();(__boxes()||[]).forEach(function(x){var nm=String(x.nm||'');if(x.ferr&&/:Porta|:Folha|:Tampa|:Frente/.test(nm))hB++;if(/Corrediça/.test(nm))cB3++})}catch(e){R.erros.push('3D: '+e)}
 var mc=S.mods.map(function(m){return mCost(m)}),sum=function(k){return mc.reduce(function(s,c){return s+(+c[k]||0)},0)};
 return {tot:r2(b.tot),sale:r2(b.sale),vlFin:r2(vlFin(b)),quote:r2((function(q){return q.discountPct>0?q.base:q.total})(quoteData())),
  somaLinhas:r2(soma)===r2(b.tot),porModulo:r2(porMod)===r2(b.tot),chapas:r2(ch)===r2(b.cB+b.cC+b.cF),
  pecas:'lista '+nL+' = plano '+nP+' + tiradas '+off+(nb?' (maiores que a chapa '+nb+')':''),pecasOk:nL===nP+off,area:Math.abs(aL-aP)<1||off>0,
  fita:'orçamento '+r3(mO)+' m (× perda '+fk+') · partes '+r3(mPartes)+' · plano '+r3(mP),fitaOk:Math.abs(mO-mPartes)<0.001,fitaDif:dif.slice(0,12),
  ferr:'dob '+sum('dob')+' · corr '+sum('drw')+'+'+sum('drwO')+' · pux E'+sum('pxE')+' C'+sum('pxC')+' G'+sum('pxG')+' P'+sum('pxP')+' F'+sum('pxF')+' T'+sum('pxT')+' · pés '+sum('pesQ')+'+'+sum('pesR'),
  ferr3D:'dobradiças '+(hB/20)+' · pares de corrediça '+(cB3/6),ferrOk:hB/20===sum('dob')&&cB3/6===sum('drw')+sum('drwO'),
  linhas:L.filter(function(r){return r[3]>0}).map(function(r){return r[0]+' '+r3(r[3])+' '+r[2]+' = '+r2(r[3]*(+PR[r[0]]||0))}),
  medidaLista:(function(){try{var h=planHtml(b.plan),m=h.match(/\d+(?:,\d+)? × \d+(?:,\d+)?/);return m?m[0]:''}catch(e){return 'erro'}})()}};
try{
 AMB.forEach(function(a){PIDS.push(mk(a[0],a[1]))});
 /* custos fixos, desconto e fita manual no 1º (o que muda o valor sem ser material) */
 arqueOpenClient(PIDS[0]);S.cfx=[cfxLimpa({n:'Transporte',t:'R',v:300,esc:'srv'}),cfxLimpa({n:'Comissão',t:'P',v:5,base:'mrg'})];S.desc=5;var m0=S.mods[0],pp=partsOf(m0).filter(function(p){return p.pk&&edgeSides(p.name)==='B'})[0];if(pp){m0.fitaMan={};m0.fitaMan[pp.pk]='LRTB'}draw();saveNow();
 arqueOpenClient(PIDS[1]);S.cfx=[cfxLimpa({n:'Transporte',t:'R',v:300,esc:'srv'})];draw();saveNow();
 PIDS.forEach(function(pid,i){arqueOpenClient(pid);draw();var s1=sinal();
  /* salvar e reabrir */var st=JSON.stringify(snapState());loadState(JSON.parse(st));draw();var s2=sinal();
  var mud=Object.keys(s1).filter(function(k){return JSON.stringify(s1[k])!==JSON.stringify(s2[k])});
  s1.reabre=mud.length?'MUDOU: '+mud.join(','):'igual';R.amb[AMB[i][0]]=s1});
 /* backup: o que vai pro arquivo (projects.json e prices.json pela ponte do app) reabre igual */
 try{var A=window.ArqueApp,dec=function(n){var b=A.getFile(n);if(!b)return null;try{return JSON.parse(decodeURIComponent(escape(atob(b))))}catch(e){try{return JSON.parse(atob(b))}catch(_){return null}}};
  var pj=dec('projects.json'),pr=dec('prices.json');R.backup={projetos:pj?pj.filter(function(p){return PIDS.indexOf(p.id)>=0}).length:'sem arquivo',precos:pr?(JSON.stringify(pr)===JSON.stringify(PR)?'igual':'DIFERENTE'):'sem arquivo'};
  if(pj){var PR0=JSON.stringify(PR);R.backup.reabre=PIDS.map(function(pid,i){var p=pj.filter(function(q){return q.id===pid})[0];if(!p)return 'falta';if(pr){PR=pr;window.PR=pr}CUR=pid;loadState(JSON.parse(JSON.stringify(p.current)));draw();var s=sinal();PR=JSON.parse(PR0);window.PR=PR;var o=R.amb[AMB[i][0]];return ['tot','sale','vlFin','quote'].every(function(k){return s[k]===o[k]})?'igual':'DIFERENTE '+s.tot+'/'+o.tot}).join(' · ')}}catch(e){R.erros.push('backup: '+e)}
 /* orçamentos de 1, 2 e 3 ambientes */
 [1,2,3].forEach(function(n){arqueOpenClient(PIDS[0]);var O=orcReabre();O.secs=[];orcAdd(PIDS.slice(0,n));O=orcAtual();var t=orcTotais({secs:O.secs.map(function(s){return {sug:s.sug,manual:s.manual,desc:s.dpc}}),disc:O.disc});
  var cada=O.secs.map(function(s,i){var a=R.amb[AMB[i][0]];return r2(s.sug)+(i>0&&AMB[i][0]==='Quarto'?' (= '+a.quote+' − transporte já contado '+r2(a.quote-s.sug)+')':(r2(s.sug)===a.quote?' (= ambiente)':' (≠ ambiente '+a.quote+')'))});
  var soma=r2(O.secs.reduce(function(s,x){return s+orcSecVal({sug:x.sug,manual:x.manual,desc:x.dpc}).fin},0));R.orc[n+' amb']={ambientes:cada,total:t.tot,somaDasLinhas:soma,fecha:soma===t.tot}});
}catch(e){R.erros.push(String(e&&e.stack||e).slice(0,300))}
return JSON.stringify(R);
