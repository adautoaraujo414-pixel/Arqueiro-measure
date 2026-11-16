/* Tamponamento esquerdo e direito, pelo "Usar" de verdade, em todos os casos: encostado na parede, entre vizinhos (com e sem espaço), no canto entre paredes.
   Cada caso tem que dar UMA das duas:
     LIGOU: tamponamento marcado, medidas de todos iguais, módulos de outras fileiras parados, régua fora do próprio módulo e nenhuma peça entrando em outra no 3D;
     NÃO COUBE: tamponamento desmarcado, projeto idêntico (histKey) e aviso "Não cabe".
   E a regra do canto (módulo de baixo na parede do lado começa depois do canto) não é aplicada ao abrir/desenhar/3D de projeto existente — só quando a pessoa põe/move. */
window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(String(t))};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={casos:{}};
var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
var tab=async function(){[].filter.call(document.querySelectorAll('#tabs [data-t]'),function(x){return /Tamponamento/.test(x.textContent)})[0].click();await W(60)};
var med=function(){return S.mods.map(function(m){return [m.w,m.h,m.d,m.esp,m.b||0].join('/')}).join(' ')};
var pos=function(){return S.mods.map(function(m){return (m.wing||'f')+Math.round(m.x)+(m.sup?'s':'')}).join(',')};
var dentro=function(){__build();var B=__boxes().filter(function(q){return q.pk&&q.a!==0&&!/Puxador|LED|Dobradi|Corrediça|Pedra/.test(q.pk)&&!q.gl}),o=[];
 for(var i=0;i<B.length;i++)for(var j=0;j<i;j++){var p=B[i],q=B[j];var mp=String(p.nm).split(':')[0],mq=String(q.nm).split(':')[0];if(mp===mq&&!(/Tamponamento/.test(p.pk)!==/Tamponamento/.test(q.pk)))continue;
  var ox=Math.min(p.x1,q.x1)-Math.max(p.x0,q.x0),oy=Math.min(p.y1,q.y1)-Math.max(p.y0,q.y0),oz=Math.min(p.z1,q.z1)-Math.max(p.z0,q.z0);if(ox>1&&oy>1&&oz>1){var nn=mp+':'+p.pk+' × '+mq+':'+q.pk;if(/fundo \(6 mm\)|Fundo de gaveta/.test(nn))continue;o.push(nn+' ('+Math.round(Math.min(ox,oy,oz))+')')}}return o};
var cena=function(Wp,itens,xs){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=Wp;S.H=2700;S.stones=[];draw();itens.forEach(function(n){newTpl(T(n))});['tl','tr'].forEach(function(k){S.mods.forEach(function(m){m[k]=false;delete m[k+'Auto'];m[k+'M']=1})});if(xs)xs.forEach(function(x,i){if(x!==null){S.mods[i].x=x}});S.mods.forEach(function(m){if(!m.sup)m.w=900});if(xs)xs.forEach(function(x,i){if(x!==null)S.mods[i].x=x});draw()};
var caso=async function(nome,mi,c){var k0=histKey(snapState()),m0=med(),p0=pos(),d0=dentro().length;TL=[];S.m=S.mods[mi];draw();panel();await tab();var cb=document.querySelector('#bd input[type=checkbox][data-c="'+c+'"]');if(!cb){R.casos[nome]='sem caixinha';return}cb.click();await W(700);
 var lig=!!S.mods[mi][c],av=TL.some(function(t){return /Não cabe/.test(t)}),res;
 if(lig){var d=dentro(),m=S.mods[mi],nm=c==='tl'?'Tamponamento esquerdo':'Tamponamento direito',p=partsOf(m).filter(function(q){return q.name===nm})[0],fora=p?(c==='tl'?(p.x+p.w<=0.5):(p.x>=m.w-0.5)):false;
  res='LIGOU · posições '+p0+' → '+pos()+' · medidas iguais '+(med()===m0)+' · régua fora do módulo '+fora+' · peça entrando em outra '+(d.length-d0>0?d.slice(0,2).join(' | '):'nenhuma')}
 else res='NÃO COUBE · projeto igual '+(histKey(snapState())===k0)+' · aviso '+av;
 var ok=lig?(med()===m0&&/régua fora do módulo true/.test(res)&&/entrando em outra nenhuma/.test(res)):(histKey(snapState())===k0&&av);
 R.casos[nome]=(ok?'OK  ':'ERRO ')+res};
draw();
/* 1. encostado na parede */
cena(4000,['Balcão 2 portas','Balcão 1 porta','Aéreo 2 portas'],[5,905,null]);await W(30);await caso('esquerdo · encostado na parede esquerda · com espaço',0,'tl');
cena(4000,['Balcão 2 portas','Balcão 2 portas'],[5,3095]);await W(30);await caso('direito · encostado na parede direita · com espaço',1,'tr');
cena(1810,['Balcão 2 portas','Balcão 2 portas'],[5,905]);await W(30);await caso('esquerdo · parede cheia',0,'tl');
cena(1810,['Balcão 2 portas','Balcão 2 portas'],[5,905]);await W(30);await caso('direito · parede cheia',1,'tr');
/* 2. entre vizinhos */
cena(4000,['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas'],[5,905,1805]);await W(30);await caso('esquerdo · módulo do meio · com espaço no fim',1,'tl');
cena(4000,['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas'],[5,905,1805]);await W(30);await caso('direito · módulo do meio · com espaço no fim',1,'tr');
cena(2710,['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas'],[5,905,1805]);await W(30);await caso('esquerdo · módulo do meio · parede cheia',1,'tl');
cena(2710,['Balcão 2 portas','Balcão 2 portas','Balcão 2 portas'],[5,905,1805]);await W(30);await caso('direito · módulo do meio · parede cheia',1,'tr');
/* 3. canto entre paredes (módulo do fundo no canto esquerdo + módulo da parede do lado) */
var canto=async function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=3200;S.H=2600;S.RD=3000;draw();newTpl(T('Balcão 2 portas'));draw();S.mods[0].x=0;draw();await W(50);wvGo('e');draw();newTpl(T('Balcão 2 portas'));draw();var Wm=S.mods[S.mods.length-1];Wm.x=0;S.m=Wm;draw();await W(600);wvGo('f');draw();await W(400);R.cantoTampAntes=S.mods.map(function(m){return (m.wing||'f')+' tl'+(m.tl?1:0)+(m.tlAuto?'a':'')+' tr'+(m.tr?1:0)+(m.trAuto?'a':'')}).join(', ')};
var cantoLimpo=async function(){await canto();S.mods.forEach(function(m){if(!m.wing){['tl','tr'].forEach(function(k){m[k]=false;delete m[k+'Auto'];m[k+'M']=1})}});draw();await W(400)};
await cantoLimpo();var cp=pos();R.cantoMontado=cp;await caso('esquerdo · módulo do fundo no canto',0,'tl');
await cantoLimpo();await caso('direito · módulo do fundo no canto',0,'tr');
/* 4. regra do canto (9 mm) não é aplicada ao abrir / desenhar / 3D de projeto existente */
await canto();var st=JSON.parse(JSON.stringify(snapState())),wi=st.mods.findIndex(function(m){return m.wing==='e'});R.cantoPosicaoAprovada=st.mods[wi].x;
st.mods[wi].x=st.mods[wi].x-9;/* projeto antigo gravado com o módulo da parede do lado 9 mm mais pro canto */
loadState(JSON.parse(JSON.stringify(st)));draw();draw();open3D();await W(300);__build();document.getElementById('v3x').click();await W(50);draw();await W(700);
var wm=S.mods.filter(function(m){return m.wing==='e'})[0];R.projetoAntigoAbriu='x '+wm.x+' (gravado '+st.mods[wi].x+') · igual '+(wm.x===st.mods[wi].x)+' · avisos '+(window.fgConflitos?fgConflitos():[]).map(function(c){return c.texto}).join(' | ');
/* quando a pessoa mexe nele (campo "Da ponta da parede"), o encaixe aprovado vale */
wvGo('e');draw();await W(100);var wv_=S.mods.filter(function(m){return m.wing==='e'})[0]||S.mods[S.mods.length-1];S.m=wv_;var xa_=wv_.x;setv('x',xa_+1);await W(800);wvGo('f');draw();await W(300);R.pessoaMexeu='na vista da parede do lado: digitou '+(xa_+1)+' → x '+S.mods.filter(function(m){return m.wing==='e'})[0].x;
R.errs=__errs.length;return JSON.stringify(R);
