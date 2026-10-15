'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-planta.html','utf8');
const mob=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
const app=fs.readFileSync('app/src/main/assets/app.js','utf8');
const index=fs.readFileSync('app/src/main/assets/index.html','utf8');
for(const [term,meaning] of [
 ['Planta 2D 0.35','Versão da planta'],
 ['function polygon(){','Parede retangular e L'],
 ['function updateRoom(','Redimensionar planta a partir de centímetros'],
 ['function measureApply(','Aplicar milímetros recebidos'],
 ['window.ArqueBleMeasure=mm=>','Leitura nativa BLE na planta'],
 ['window.ArqueBleDevices=json=>','Conectar trena'],
 ['window.ArqueBleStatus=status=>','Estado de conexão'],
 ['autoLaser','Aplicação automática opcional'],
 ['function dimensions(it){','Folgas reais em torno dos equipamentos'],
 ['function snapInsideParent(','Impedir que equipamento saia da bancada'],
 ["['sink','cooktop']",'Cuba e cooktop'],
 ['function keepItem(','Limitar elementos ao ambiente'],
 ['function linkedDb(){','Persistência vinculada à obra'],
 ['arquePlantaByRoom','Separar projeto por ambiente'],
 ['function cameraFit(){','Enquadramento proporcional'],
 ['function zoom(','Zoom no tablet'],
 ['function renderLive(){','Distâncias durante o arraste']
])assert(s.includes(term),meaning+' ausente');
assert(mob.includes('id="openPlanta"')&&mob.includes("location.href='arque-planta.html'+location.search"),'Acesso pela folha indisponível');
assert(index.includes('data-action="openArquePlanta"')&&app.includes("case'openArquePlanta'"),'Acesso direto sem cadastro completo indisponível');
const start=s.indexOf('<script>')+8,end=s.lastIndexOf('</script>');
assert(start>=8&&end>start);const js=s.slice(start,end);new Function(js);
const a=js.indexOf('function polygon(){'),b=js.indexOf('function create(type){',a);
assert(a>=0&&b>a);
const st={shape:'L',room:{w:394,d:280,recessW:110,recessD:70},items:[]};
const clamp=(n,a,b)=>Math.min(b,Math.max(a,n)),round=n=>Math.round(n*10)/10;
const engine=new Function('st','clamp','round',js.slice(a,b)+';return {polygon,isInRoom,fitsRoom,dimensions,keepItem,snapInsideParent};')(st,clamp,round);
assert.deepEqual(engine.polygon(),[[0,0],[394,0],[394,70],[284,70],[284,280],[0,280]]);
assert(engine.isInRoom(200,180));assert(!engine.isInRoom(330,190));
const stone={id:1,type:'stone',x:10,y:210,w:240,h:60};
const sink={id:2,type:'sink',parent:1,x:80,y:220,w:48,h:39};
st.items=[stone,sink];
assert.deepEqual(engine.dimensions(sink),{left:70,right:122,top:10,bottom:11});
sink.x=100;assert.equal(engine.dimensions(sink).left,90);
sink.x=999;engine.keepItem(sink);assert.equal(sink.x,202);
assert(engine.fitsRoom(stone));
st.shape='rect';assert.deepEqual(engine.polygon(),[[0,0],[394,0],[394,280],[0,280]]);
console.log('Arque Planta 0.35: proporção em L, cuba, folgas, fonte BLE e armazenamento: OK');
