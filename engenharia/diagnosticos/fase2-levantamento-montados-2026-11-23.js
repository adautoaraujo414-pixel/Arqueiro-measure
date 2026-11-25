/* FASE2 · ponto 2 do levantamento (23/11/2026, Claude Code 2): PROJETOS MONTADOS. Só levantamento (nada no editor muda).
   Roda no editor (bateria ou console). Cenas: cozinha de exemplo, cozinha reta com tamponamentos e pedra, cozinha em L (canto + parede esquerda + pedra em L),
   cozinha em U, ilha, 2 guarda-roupas lado a lado, caixa da geladeira com aéreo do lado. Para cada cena compara as caixas do 3D:
   (1) peças sólidas de MÓDULOS DIFERENTES (ou módulo × pedra) se sobrepondo mais de 1 mm nos 3 eixos; (2) dentro de cada módulo, o mesmo
   levantamento da 1ª parte (porta × corpo, peça × peça, peça sem 3D, medida 3D × corte). Devolve a lista classificável. */
window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})};
var TOL=1.0,CARC=/^(Lateral|Base|Tampo|Travessa|Divis|Prateleira|Fundo|Tamponamento|Rodapé|Régua|Moldura|Teto|Chão|Porta|Frente)/;
var T=function(n){var it=null;CATS.forEach(function(c){(c.it||[]).forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n)it=t})});return it?JSON.parse(JSON.stringify(it)):null};
var add=function(n){var t=T(n);if(!t)return null;newTpl(t);return S.mods[S.mods.length-1]};
var ov=function(a,b){var x=Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0),y=Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0),z=Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0);return (x>TOL&&y>TOL&&z>TOL)?[x,y,z]:null};
var solido=function(b){return !b.gp&&b.a>=.95&&!b.nol&&!b.hg&&!b.gl&&!b.cvl&&!b.em&&!b.ft&&b.g!=='sh'&&b.g!=='lo'&&!b.rpid};
var dono=function(b){var nm=String(b.nm||'');var m=/^(\d+):/.exec(nm);if(m)return 'm'+m[1];if(b.sid!==undefined)return 'pedra'+b.sid;if(b.isl!==undefined)return 'ilha'+b.isl;return ''};
var CONF0=null;var cena=async function(nome,monta){var R={cena:nome,entre:[],erro:''},B=[];try{loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=5000;S.H=2700;draw();await monta();draw();open3D();await W(120);__build();
  B=__boxes().filter(function(b){return solido(b)&&dono(b)&&CARC.test(String(b.nm||'').replace(/^\d+:/,'')||'Pedra')||(solido(b)&&(b.sid!==undefined||b.isl!==undefined))});
  for(var i=0;i<B.length;i++)for(var j=i+1;j<B.length;j++){var a=B[i],b=B[j];if(dono(a)===dono(b))continue;var o=ov(a,b);if(o)R.entre.push(dono(a)+' '+String(a.nm||'pedra').replace(/^\d+:/,'')+' × '+dono(b)+' '+String(b.nm||'pedra').replace(/^\d+:/,'')+' '+o.map(Math.round).join('×'))}
  document.getElementById('v3x').click();await W(80)}catch(e){R.erro=String(e&&e.message||e).slice(0,160)}finally{if(CONF0){window.confineAll=CONF0;CONF0=null}}if(false){R.erro=String(e&&e.message||e).slice(0,160)}R.n=R.entre.length;R.modulos=(S.mods||[]).length;R.pedras=(S.stones||[]).length+(S.stw||[]).length;R.ilhas=(S.isl||[]).length;R.caixas=B.length;R.entre=R.entre.slice(0,40);return R};
var res=[];
res.push(await cena('cozinha de exemplo',async function(){demoScene()}));
res.push(await cena('reta: 4 balcões + 3 aéreos, tamponamentos nas pontas e pedra',async function(){['Balcão 2 portas','Gaveteiro 3 gavetas','Balcão da pia (cuba)','Balcão 2 portas'].forEach(add);var a=S.mods[0],z=S.mods[S.mods.length-1];a.tl=true;z.tr=true;['Aéreo 2 portas','Aéreo 2 portas','Aéreo 2 portas'].forEach(add);addStone();draw()}));
res.push(await cena('em L: canto + parede esquerda + pedra em L',async function(){mkCorner('e');add('Balcão 2 portas');add('Gaveteiro 3 gavetas');addStone();var st=S.st;st.x=0;st.w=2400;st.shape='Le';st.lenA=1500;st.widA=650;draw();wvGo('e');await W(40);add('Balcão 2 portas');wvGo('f');await W(40)}));
res.push(await cena('em U: dois cantos',async function(){mkCorner('e');mkCorner('d');add('Balcão 2 portas');draw()}));
res.push(await cena('ilha',async function(){add('Balcão 2 portas');S.isl=S.isl||[];var il=islNew('pen');il.x=1500;il.z=1500;S.isl.push(il);var i2=islNew('ilha');i2.x=3000;i2.z=2600;S.isl.push(i2);draw()}));
res.push(await cena('2 guarda-roupas lado a lado',async function(){S.env='quarto';S.room='quarto';var g=CATS.filter(function(c){return /guarda|roupa|quarto/i.test(c.id+' '+(c.n||''))})[0];var it=g&&g.it.map(function(q){return typeof q==='number'?TPL[q]:q}).filter(function(t){return t&&t.w&&!t.corner})[0];if(it){newTpl(JSON.parse(JSON.stringify(it)));newTpl(JSON.parse(JSON.stringify(it)))}draw()}));
res.push(await cena('caixa da geladeira + aéreo ao lado',async function(){var g=add('Caixa da geladeira side by side (laterais + aéreo)');if(g){g.tl=true;g.tr=true}add('Balcão 2 portas');add('Aéreo 2 portas');draw()}));
/* controle: dois balcões no mesmo lugar TÊM que aparecer (prova de que a conferência pega) */
res.push(await cena('CONTROLE: 2 balcões no mesmo lugar',async function(){var a=add('Balcão 2 portas'),b=add('Balcão 2 portas');b.x=a.x;CONF0=window.confineAll;window.confineAll=function(){};draw()}));
return JSON.stringify({cenas:res.length,res:res});
