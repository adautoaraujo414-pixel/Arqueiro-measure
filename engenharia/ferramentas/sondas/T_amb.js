window.MINI3OFF=1;PR.setupDone=1;var TL=[];window.toast=function(t){TL.push(t)};var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})},R={},e0=__errs.length;
/* AUDITORIA DO AMBIENTE (16/11, 14:29): medidas da parede da direita pelo editor do ambiente (campo do teclado do app: um número por vez e OK no fim).
   AMB-RD: a profundidade do ambiente não fica presa num valor digitado errado. AMB-TZ: o rebaixo do teto não passa do fim da parede. */
var base=function(){loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4000;S.H=2700;S.RD=2600;S.stones=[];S.mods=[];S.ambOk=1;draw()};
var digita=async function(k,val){var i=document.querySelector('[data-ambs="'+k+'"]');if(!i)return 'sem campo '+k;i.value='';for(var c of String(val)){i.value+=c;i.dispatchEvent(new Event('input',{bubbles:true}))}i.dispatchEvent(new Event('change',{bubbles:true}));await W(60);return 'ok'};
var cfg=function(){var c=wallCfg('R');return 'direita '+c.len+' × '+c.h0+'/'+c.h1+' · profundidade '+S.RD+' · fundo '+S.W+' × '+S.H};
/* 1) medidas da imagem: parede da direita 3170, altura no fundo 3400, na frente 3400 */
base();ambSetOpen();await W(150);ambSelWall('d');await W(60);await digita('Rlen',3170);await digita('Rh0',3400);await digita('Rh1',3400);
R.digitou=cfg()+' · campos '+[].map.call(document.querySelectorAll('[data-ambs^="R"]'),function(i){return i.value}).join('/');
ambSetClose(true);await W(80);wvGo('d');await W(60);R.doisDNaParede='2D na parede da direita: '+S.W+' × '+S.H;wvGo('f');await W(60);
var sv=JSON.stringify(snapState());loadState(JSON.parse(sv));draw();R.reabriu=cfg();
/* 2) digitou errado (31700) e corrigiu pra 3170: a profundidade volta (antes ficava 31700) */
base();ambSetOpen();await W(150);ambSelWall('d');await W(60);await digita('Rlen',31700);var rd1=S.RD;await digita('Rlen',3170);R.errouECorrigiu='com 31700: '+rd1+' · corrigiu: '+S.RD;
/* parede do lado menor que a profundidade: a profundidade que você tinha fica */await digita('Rlen',2000);R.paredeMenor='parede 2000: profundidade '+S.RD;
/* profundidade mexida por você depois (campo Profundidade da sala, sem parede escolhida): o comprimento da parede não encolhe a sua */ambSelWall(null);await W(60);var dr_=await digita('RD',5000);ambSelWall('d');await W(60);await digita('Rlen',3000);R.profundidadeSua='campo '+dr_+' · profundidade digitada 5000, parede 3000: '+S.RD;ambSetClose(true);
/* 3) rebaixos 3170 e 1000 na parede da direita; a parede encurta pra 2500 e volta pra 3170 */
base();wallSet('R','len',3170);wallSet('R','h0',3400);wallSet('R','h1',3400);draw();tzAdd('d',{x:0,w:3170,hc:3000});tzAdd('d',{x:2400,w:1000,hc:2800});try{document.getElementById('tzbox').hidden=true}catch(_){}
var fim=function(){return (S.tz||[]).map(function(z){var g=tzGeo(z);return g?Math.round(g.z1):'fora'}).join(',')};R.rebaixos3D='fim no 3D: '+fim();
ambSetOpen();await W(150);ambSelWall('d');await W(60);await digita('Rlen',2500);R.paredeCurta='parede 2500 · fim no 3D: '+fim()+' · guardado '+(S.tz||[]).map(function(z){return z.x+'+'+z.w}).join(',');
await digita('Rlen',3170);ambSetClose(true);R.paredeVoltou='parede 3170 · fim no 3D: '+fim();
R.errs=__errs.slice(e0).length;return JSON.stringify(R,null,1);
