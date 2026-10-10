/* Biblioteca Arque Cozinha: itens autorais parametricos inspirados nos fluxos de
   catalogo CAD. Valores de referencia para EDICAO, nao fichas de fabricantes. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueKitchen=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const copy=o=>JSON.parse(JSON.stringify(o));
const uid=()=>typeof crypto!=='undefined'&&crypto.randomUUID?crypto.randomUUID():'kitchen-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2);
const mm=(n,name,min,max=50000)=>{const v=Number(String(n).replace(',','.'));if(!Number.isFinite(v)||v<min||v>max)throw Error(name+' deve ficar entre '+min+' e '+max+' mm.');return Math.round(v*10)/10;};
const types=[
 {id:'base-doors',group:'Inferiores',label:'Balcão com 2 portas',kind:'module',w:800,d:560,h:730,doors:2,shelves:1,z:100},
 {id:'base-pia',group:'Inferiores',label:'Gabinete de pia · sem fundo',kind:'module',w:1000,d:560,h:730,doors:2,shelves:0,z:100,back:'none'},
 {id:'base-drawers',group:'Inferiores',label:'Gaveteiro · configurar corrediças',kind:'module',w:500,d:560,h:730,doors:0,shelves:0,z:100,warning:'Gavetas e corrediças precisam ser configuradas no editor de montagem.'},
 {id:'base-open',group:'Inferiores',label:'Nicho inferior aberto',kind:'module',w:500,d:560,h:730,doors:0,shelves:1,z:100},
 {id:'upper-doors',group:'Aéreos',label:'Aéreo com 2 portas',kind:'module',w:800,d:350,h:700,doors:2,shelves:1,z:1500},
 {id:'upper-lift',group:'Aéreos',label:'Aéreo basculante · ferragem pendente',kind:'module',w:800,d:350,h:400,doors:1,shelves:0,z:1800,warning:'Frente calculada; basculante e pistões exigem especificação e furação próprios.'},
 {id:'upper-microwave',group:'Aéreos',label:'Nicho de micro-ondas aéreo',kind:'module',w:700,d:450,h:500,doors:0,shelves:0,z:1500,warning:'Conferir ventilação e folgas do micro-ondas específico antes de fabricar.'},
 {id:'fridge-overhead',group:'Aéreos',label:'Aéreo sobre geladeira',kind:'module',w:1050,d:600,h:420,doors:2,shelves:0,z:2000},
 {id:'tower-oven',group:'Torres',label:'Torre quente com nichos',kind:'module',w:700,d:560,h:2100,doors:0,shelves:0,z:100,fixed:[.28,.68],warning:'Nichos de forno/micro-ondas são referenciais: verificar ficha do aparelho e ventilação.'},
 {id:'tower-pantry',group:'Torres',label:'Despenseiro com portas',kind:'module',w:600,d:560,h:2100,doors:2,shelves:4,z:100},
 {id:'tower-open',group:'Torres',label:'Estante torre com prateleiras',kind:'module',w:500,d:400,h:2100,doors:0,shelves:5,z:100},
 {id:'microwave',group:'Eletrodomésticos',label:'Micro-ondas · referência',kind:'appliance',w:520,d:400,h:300,z:1100},
 {id:'oven',group:'Eletrodomésticos',label:'Forno de embutir · referência',kind:'appliance',w:600,d:560,h:600,z:800},
 {id:'fridge',group:'Eletrodomésticos',label:'Geladeira · referência',kind:'appliance',w:760,d:720,h:1850,z:0},
 {id:'cooktop',group:'Eletrodomésticos',label:'Cooktop · referência',kind:'appliance',w:600,d:510,h:45,z:900},
 {id:'stove',group:'Eletrodomésticos',label:'Fogão de piso · referência',kind:'appliance',w:600,d:620,h:900,z:0},
 {id:'hood',group:'Eletrodomésticos',label:'Coifa · referência',kind:'appliance',w:900,d:500,h:350,z:1600},
 {id:'dishwasher',group:'Eletrodomésticos',label:'Lava-louças · referência',kind:'appliance',w:600,d:600,h:850,z:0},
 {id:'airfryer',group:'Eletrodomésticos',label:'Air fryer · referência',kind:'appliance',w:320,d:400,h:350,z:900},
 {id:'sink',group:'Bancadas',label:'Cuba de cozinha',kind:'sink',w:500,d:400,h:180,z:720},
 {id:'countertop',group:'Bancadas',label:'Bancada de pedra · referência',kind:'countertop',w:1600,d:600,h:35,z:865},
 {id:'led-strip',group:'Iluminação',label:'Fita LED linear',kind:'led',w:900,d:20,h:10,z:1450,color:'#ffd292'},
 {id:'led-profile',group:'Iluminação',label:'Perfil LED embutido',kind:'led',w:1200,d:35,h:18,z:1450,color:'#fff1ca'},
 {id:'led-shelf',group:'Iluminação',label:'LED sob prateleira',kind:'led',w:600,d:18,h:10,z:1200,color:'#ffe3ad'}
];
const catalog=()=>copy(types);
function definition(id){return types.find(x=>x.id===id)||null;}
function create(id,engine=globalThis.ArqueModules){
 const p=definition(id);
 if(!p)throw Error('Modelo não encontrado no catálogo Arque.');
 if(p.kind==='module'){
  if(!engine||!engine.parts)throw Error('Motor paramétrico indisponível.');
  const s=engine.standard();
  Object.assign(s,{name:p.label,width:p.w,depth:p.d,height:p.h,doorCount:p.doors,shelfCount:p.shelves,back:p.back||s.back,
   fixedShelves:(p.fixed||[]).map(at=>({bay:0,at}))});
  const result=engine.parts(s);
  const item=engine.instantiate({id:'arque-'+p.id,version:1,spec:result.spec},100,100);
  item.z=p.z;item.presetId=p.id;item.catalogGroup=p.group;
  if(p.warning)item.presetWarning=p.warning;
  return item;
 }
 return {id:uid(),kind:p.kind,type:p.id==='led-strip'||p.id==='led-profile'||p.id==='led-shelf'?'led':p.id,
  label:p.label,x:100,y:100,z:p.z,w:p.w,d:p.d,height:p.h,view:'plan',refs:{},
  catalogGroup:p.group,presetId:p.id,manufacturerVerified:false,visualReference:true,
  lightColor:p.color||'',lightOn:true,
  notice:p.kind==='led'?'Referência luminosa: potência, fonte, fita, dissipação e posição devem ser especificadas.':
  p.kind==='appliance'?'Geometria de referência, não corresponde a produto ou ficha técnica de fabricante.':'Dimensões de referência: verificar obra.'};
}
function dimensions(item,values){
 const p={...item};
 p.w=mm(values.w,'Largura',40);
 p.d=mm(values.d,'Profundidade',20);
 p.height=mm(values.height,'Altura',5);
 p.x=mm(values.x??item.x,'Posição X',0);
 p.y=mm(values.y??item.y,'Posição Y',0);
 p.z=mm(values.z??item.z??0,'Posição Z',0);
 if(values.label!==undefined)p.label=String(values.label).trim().slice(0,70)||item.label;
 return p;
}
/* Posicionamento técnico: usa o vão livre da carcaça e as prateleiras fixas.
   Não inventa folga de fabricante e não ajusta dimensão do eletrodoméstico. */
function fitInNiche(appliance,module,options={},engine=globalThis.ArqueModules){
 if(!appliance||appliance.kind!=='appliance')throw Error('Selecione um eletrodoméstico para encaixar.');
 if(!module||module.kind!=='module'||!engine)throw Error('Escolha um nicho construtivo válido.');
 const spec=engine.check(module.moduleSpec),sides=mm(options.side??5,'Folga lateral',0,100),
  top=mm(options.top??10,'Folga superior',0,150),bottom=mm(options.bottom??5,'Folga inferior',0,150),
  rear=mm(options.rear??20,'Folga traseira',0,200);
 if(spec.doorCount||spec.doorMode==='byBay'&&Object.values(spec.bayDoors).some(Boolean))throw Error('Abra o vão ou retire as portas antes de encaixar o aparelho.');
 if(spec.vertical.length>0)throw Error('Nicho com divisórias verticais exige escolher o vão: verifique manualmente.');
 const t=spec.thickness,freeWidth=spec.width-2*t,freeDepth=spec.depth-(spec.back==='overlay'?spec.backThickness:0);
 if(appliance.w+2*sides>freeWidth)throw Error('O aparelho não cabe na largura interna com as folgas laterais.');
 if(appliance.d+rear>freeDepth)throw Error('O aparelho não cabe em profundidade com a ventilação traseira indicada.');
 const inner=spec.height-2*t,fixed=spec.fixedShelves.filter(p=>p.bay===0).sort((a,b)=>a.at-b.at);
 if((spec.shelvesByBay[0]??spec.shelfCount)>0)throw Error('Retire prateleiras móveis desse nicho antes de encaixar um eletrodoméstico.');
 const sections=[],planes=[t,...fixed.map(p=>t+inner*p.at),spec.height-t];
 for(let i=1;i<planes.length;i++){const start=planes[i-1]+(i===1?0:t),stop=planes[i];if(stop>start)sections.push({start,stop,clear:stop-start});}
 const slot=sections.find(p=>p.clear>=appliance.height+top+bottom);
 if(!slot)throw Error('Não existe altura livre suficiente entre as prateleiras fixas e as folgas informadas.');
 const x=Math.round((module.x+(spec.width-appliance.w)/2)*10)/10;
 const y=Math.round((module.y+spec.depth-appliance.d)*10)/10;
 const z=Math.round(((module.z||0)+slot.start+bottom)*10)/10;
 return {x,y,z,hostModuleId:module.id,clearance:{side:sides,top,bottom,rear},
   note:'Aparelho encaixado por dimensão de referência. Confirmar ventilação, tomada, porta e ficha do fabricante.'};
}
function groupIds(){return [...new Set(types.map(t=>t.group))];}
return {catalog,definition,create,dimensions,fitInNiche,groupIds};
});