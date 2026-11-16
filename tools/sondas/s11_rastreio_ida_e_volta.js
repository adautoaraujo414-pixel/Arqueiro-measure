window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
__TRACER__
function diff(a,b,p,out){if(out.length>12)return;if(a===b)return;if(typeof a!=='object'||typeof b!=='object'||a===null||b===null){out.push(p+'='+JSON.stringify(a)+'→'+JSON.stringify(b));return}var ks={};Object.keys(a).forEach(function(k){ks[k]=1});Object.keys(b).forEach(function(k){ks[k]=1});Object.keys(ks).forEach(function(k){diff(a[k],b[k],p+'.'+k,out)})}
var R={};draw();demoScene();await W(500);draw();var base=JSON.stringify(snapState());
var casos={
 'parede do fundo -300 e volta':[function(){S.W-=300},function(){S.W+=300}],
 'parede do fundo -900 e volta':[function(){S.W-=900},function(){S.W+=900}],
 'pé-direito -400 e volta':[function(){S.H-=400},function(){S.H+=400}],
 'pedra: espessura +20 e volta':[function(){S.stones[0].t=(+S.stones[0].t||30)+20},function(){S.stones[0].t-=20}],
 'pedra: largura -500 e volta':[function(){S.stones[0].w-=500},function(){S.stones[0].w+=500}],
 'módulo 1: largura -200 e volta':[function(){S.mods[1].w-=200},function(){S.mods[1].w+=200}],
 'módulo 1: largura +300 e volta':[function(){S.mods[1].w+=300},function(){S.mods[1].w-=300}],
 'módulo 0: erguer 200 e descer':[function(){S.mods[0].b=200},function(){S.mods[0].b=0}],
 'módulo 6 (aéreo): altura +300 e volta':[function(){S.mods[6].h+=300},function(){S.mods[6].h-=300}],
 'torre: mover 400 e voltar':[function(){S.mods[5].x+=400},function(){S.mods[5].x-=400}],
 'tirar o módulo 1 e desfazer pelo histórico':null
};
var out={};
for(var nm in casos){var c=casos[nm];if(!c)continue;loadState(JSON.parse(base));draw();var s0=JSON.stringify(snapState());hookAll();TR.log={};TR.on=true;c[0]();draw();__build();c[1]();draw();__build();TR.on=false;var d=[];diff(JSON.parse(s0),JSON.parse(JSON.stringify(snapState())),'',d);
 out[nm]=d.length?{sobrou:d,quem_gravou:TR.log}:'voltou igual'}
/* desfazer/refazer depois de mexer na parede */
loadState(JSON.parse(base));draw();var s0=JSON.stringify(snapState());histTick();LASTT=0;S.W-=900;draw();histTick();await W(800);document.getElementById('und').onclick();await W(100);var d=[];diff(JSON.parse(s0),JSON.parse(JSON.stringify(snapState())),'',d);out['parede -900 e ↶ desfazer']=d.length?d:'voltou igual';
document.getElementById('red').onclick();await W(100);var s1=JSON.stringify(snapState());document.getElementById('und').onclick();await W(100);d=[];diff(JSON.parse(s0),JSON.parse(JSON.stringify(snapState())),'',d);out['↷ refazer e ↶ desfazer de novo']=d.length?d:'voltou igual';
/* salvar e reabrir depois de parede encolhida */
loadState(JSON.parse(base));draw();S.W-=900;draw();var t=JSON.stringify(snapState());loadState(JSON.parse(t));draw();d=[];diff(JSON.parse(t),JSON.parse(JSON.stringify(snapState())),'',d);out['parede -900, salvar e reabrir']=d.length?d:'igual';
R.casos=out;return JSON.stringify(R);
