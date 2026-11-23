window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};
var TOL=1.0,out=[];var CARC=/^(Lateral|Base|Tampo|Travessa|Divis|Prateleira|Fundo|Tamponamento|Rodapé|Régua|Moldura|Teto|Chão)/;var FR=/^(Porta|Frente)/;
var ov=function(a,b){var x=Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0),y=Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0),z=Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0);return (x>TOL&&y>TOL&&z>TOL)?[x,y,z]:null};
var nmOf=function(b){return String(b.nm||'').replace(/^\d+:/,'')};
var anal=function(rot){var R={rot:rot,porta:[],sobre:[],sem3d:[],dim:[],corte:''};S.mods.forEach(function(m,mi){if(!m)return;
 var B=__boxes().filter(function(b){return String(b.nm).indexOf(mi+':')===0&&b.a>=.95&&!b.nol&&!b.hg&&!b.gl&&!b.cvl&&!b.em&&b.g!=='sh'&&b.g!=='lo'});
 var D=B.filter(function(b){return FR.test(nmOf(b))}),C=B.filter(function(b){return CARC.test(nmOf(b))});
 D.forEach(function(d){C.forEach(function(c){var o=ov(d,c);if(o)R.porta.push(mi+' '+nmOf(d)+'('+d.pk+') × '+nmOf(c)+'('+c.pk+') '+o.map(Math.round).join('×'))})});
 for(var i=0;i<C.length;i++)for(var j=i+1;j<C.length;j++){if(C[i].pk&&C[i].pk===C[j].pk)continue;var o=ov(C[i],C[j]);if(o)R.sobre.push(mi+' '+C[i].pk+' × '+C[j].pk+' '+o.map(Math.round).join('×'))}
 var P=partsOf(m);var all3=__boxes().filter(function(b){return String(b.nm).indexOf(mi+':')===0});
 P.forEach(function(p){if(p.noCut||p.noDraw||!(+p.cl>0)||!(+p.cw>0))return;var bs=all3.filter(function(b){return b.pk===p.pk&&!b.nol&&!b.cvl&&!b.hg});if(!bs.length){R.sem3d.push(mi+' '+p.pk+' '+p.cl+'x'+p.cw);return}
  var u={x0:Math.min.apply(null,bs.map(b=>b.x0)),x1:Math.max.apply(null,bs.map(b=>b.x1)),y0:Math.min.apply(null,bs.map(b=>b.y0)),y1:Math.max.apply(null,bs.map(b=>b.y1)),z0:Math.min.apply(null,bs.map(b=>b.z0)),z1:Math.max.apply(null,bs.map(b=>b.z1))};
  var d=[u.x1-u.x0,u.y1-u.y0,u.z1-u.z0].sort(function(a,b){return b-a}),q=[+p.cl,+p.cw].sort(function(a,b){return b-a});
  if(Math.abs(d[0]-q[0])>2||Math.abs(d[1]-q[1])>2)R.dim.push(mi+' '+p.pk+' corte '+q.join('x')+' × 3D '+d.slice(0,2).map(Math.round).join('x'))});
 try{var cl=cutLines(m),nq=0;(cl||[]).forEach(function(l){nq+=(+l.qty||0)});var np=P.filter(function(p){return !p.noCut}).length;if(nq!==np)R.corte+=mi+': lista '+np+' × corte '+nq+' ';}catch(e){R.corte+='erro '+e}
 });return R};
var CEN={
 'cozinha de exemplo':function(){demoScene()},
 'sala de exemplo':function(){demoSala()},
 'closet de exemplo':function(){demoCloset()},
 'LED de exemplo':function(){demoLed()},
 'balcões lado a lado c/ tamponamento entre eles':function(){S.W=4000;var t=T0('Balcão 2 portas');newTpl(t);newTpl(T0('Gaveteiro 3 gavetas'));newTpl(T0('Balcão 2 portas'));S.mods.forEach(function(m){m.tl=m.tr=true});draw()},
 'cozinha em L com aéreos e canto':function(){S.W=3600;mkCorner('e');newTpl(T0('Balcão 2 portas'));newTpl(T0('Balcão 2 portas'));newTpl(T0('Canto em L (aéreo) · esquerdo'));newTpl(T0('Aéreo 2 portas'));draw()},
 'torre + balcão + aéreo com tamponamento de cima':function(){S.W=3600;newTpl(T0('Torre quente (forno)'));newTpl(T0('Balcão 2 portas'));newTpl(T0('Aéreo 2 portas'));S.mods.forEach(function(m){m.tt=true;m.tl=m.tr=true});draw()},
 'canto cego + balcão + pedra':function(){S.W=3600;newTpl(T0('Balcão canto cego · cego na direita (porta na esquerda)'));newTpl(T0('Balcão da pia (cuba)'));try{S.tab=6;panel();var b=document.querySelector('#bd [data-stadd]');if(b)b.click()}catch(_){}draw()},
 'guarda-roupa CR + 3 vãos':function(){S.room='quarto';S.env='quarto';S.W=4000;newTpl(T0('Canto reto (CR) · esquerdo · 1 porta 1000mm (cego na esquerda)'));newTpl(T0('Guarda-roupa 3 vãos'));draw()}
};
var T0=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n)it=t})});return JSON.parse(JSON.stringify(it))};
var res=[];Object.keys(CEN).forEach(function(k){try{loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;draw();CEN[k]();draw();__build();var r=anal(k);r.mods=S.mods.length;
 /* entre módulos: porta de um × corpo do vizinho */var B=__boxes().filter(function(b){return b.a>=.95&&!b.nol&&!b.hg&&!b.cvl&&/^\d+:/.test(String(b.nm))});var D=B.filter(function(b){return FR.test(nmOf(b))}),C=B.filter(function(b){return CARC.test(nmOf(b))});r.entre=[];D.forEach(function(d){C.forEach(function(c){if(String(d.nm).split(':')[0]===String(c.nm).split(':')[0])return;var o=ov(d,c);if(o)r.entre.push(d.nm+'('+d.pk+') × '+c.nm+'('+c.pk+') '+o.map(Math.round).join('×'))})});
 r.corpoEntre=[];for(var i=0;i<C.length;i++)for(var j=i+1;j<C.length;j++){if(String(C[i].nm).split(':')[0]===String(C[j].nm).split(':')[0])continue;var o=ov(C[i],C[j]);if(o)r.corpoEntre.push(C[i].nm+'('+C[i].pk+') × '+C[j].nm+'('+C[j].pk+') '+o.map(Math.round).join('×'))}
 r.sobre=r.sobre.filter(function(x){return !/Lateral de gaveta.*Fundo de gaveta/.test(x)});r.dim=r.dim.filter(function(x){return !/Sapateira|Gaveta interna/.test(x)});r.corte='';res.push(r)}catch(e){res.push({rot:k,erro:String(e).slice(0,200)})}});
return JSON.stringify(res);
