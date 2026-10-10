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
 {id:'tower-oven',group:'Torres',label:'Torre quente com nichos',kind:'module',w:700,d:560,h:2100,doors:0,shelves:0,z:100,back:'none',fixed:[.28,.68],warning:'Torre sem fundo contínuo: dimensionar nichos pela ficha do forno/micro-ondas e ventilação.'},
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
 {id:'led-shelf',group:'Iluminação',label:'LED sob prateleira',kind:'led',w:600,d:18,h:10,z:1200,color:'#ffe3ad'},
 // Famílias de modulação autoral Arque; tamanhos iniciais, editáveis conforme obra.
 {id:'base-1door',group:'Inferiores',label:'Balcão 1 porta · estreito',kind:'module',w:450,d:560,h:730,doors:1,shelves:1,z:100},
 {id:'base-3doors',group:'Inferiores',label:'Balcão 3 portas',kind:'module',w:1200,d:560,h:730,doors:3,shelves:1,z:100},
 {id:'base-4doors',group:'Inferiores',label:'Balcão 4 portas',kind:'module',w:1600,d:560,h:730,doors:4,shelves:1,z:100},
 {id:'base-3drawers',group:'Inferiores',label:'Gaveteiro 3 gavetas',kind:'module',w:550,d:560,h:730,doors:0,shelves:0,z:100,drawers:3},
 {id:'base-4drawers',group:'Inferiores',label:'Gaveteiro 4 gavetas',kind:'module',w:550,d:560,h:730,doors:0,shelves:0,z:100,drawers:4},
 {id:'base-spice',group:'Inferiores',label:'Porta-temperos extraível',kind:'module',w:350,d:560,h:730,doors:0,shelves:0,z:100,spice:3},
 {id:'base-cooktop',group:'Inferiores',label:'Balcão sob cooktop',kind:'module',w:900,d:560,h:730,doors:2,shelves:0,z:100,warning:'Recorte do cooktop e ventilação não são criados automaticamente. Confirmar manual do aparelho e pedra.'},
 {id:'base-corner-90',group:'Cantos',label:'Encontro de balcões a 90° · ajustar canto',kind:'module',w:800,d:560,h:730,doors:1,shelves:1,z:100,warning:'É um armário reto para compor encontro a 90°, NÃO é gabinete cego/canto fabricável sem definir junção.'},
 {id:'corner-pentagonal',group:'Cantos',label:'Canto 45° pentagonal · 1 porta',kind:'corner45',w:800,d:800,h:730,doors:1,shelves:0,z:100},
 {id:'corner-pentagonal-open',group:'Cantos',label:'Canto 45° pentagonal · aberto',kind:'corner45',w:800,d:800,h:730,doors:0,shelves:2,z:100},
 {id:'upper-1door',group:'Aéreos',label:'Aéreo 1 porta',kind:'module',w:450,d:350,h:700,doors:1,shelves:1,z:1500},
 {id:'upper-3doors',group:'Aéreos',label:'Aéreo 3 portas',kind:'module',w:1200,d:350,h:700,doors:3,shelves:1,z:1500},
 {id:'upper-open',group:'Aéreos',label:'Nicho aéreo aberto · prateleiras',kind:'module',w:800,d:350,h:700,doors:0,shelves:2,z:1500},
 {id:'upper-shelf',group:'Aéreos',label:'Aéreo horizontal aberto',kind:'module',w:1000,d:350,h:350,doors:0,shelves:1,z:1850},
 {id:'upper-hood',group:'Aéreos',label:'Módulo sob coifa · nicho aberto',kind:'module',w:900,d:350,h:450,doors:0,shelves:0,z:1600,warning:'Verificar distância ao cooktop, calor e manual da coifa.'},
 {id:'tower-2niches',group:'Torres',label:'Torre com dois nichos técnicos',kind:'module',w:700,d:560,h:2200,doors:0,shelves:0,z:0,fixed:[.35,.68],warning:'Aparelhos devem ser encaixados com ventilação e medidas de fabricante.'},
 {id:'tower-cupboard',group:'Torres',label:'Torre armário 4 portas',kind:'module',w:800,d:560,h:2200,doors:4,shelves:3,z:0},
 {id:'bath-vanity',group:'Banheiros',label:'Gabinete banheiro 2 portas',kind:'module',w:800,d:480,h:600,doors:2,shelves:0,z:220,back:'none'},
 {id:'bath-drawers',group:'Banheiros',label:'Gabinete banheiro 2 gavetas',kind:'module',w:800,d:480,h:600,doors:0,shelves:0,z:220,drawers:2,back:'none'},
 {id:'bath-upper',group:'Banheiros',label:'Armário espelheira · referência',kind:'module',w:700,d:180,h:700,doors:2,shelves:2,z:1300,warning:'Espelho e fixação exigem material/ferragens específicos.'},
 {id:'living-low',group:'Salas e painéis',label:'Home slim baixo · 2 portas',kind:'module',w:1600,d:350,h:300,doors:2,shelves:0,z:150},
 {id:'living-niche',group:'Salas e painéis',label:'Nicho decorativo aberto',kind:'module',w:600,d:300,h:600,doors:0,shelves:2,z:1100},
 {id:'living-panel',group:'Salas e painéis',label:'Painel decorativo liso',kind:'panel',w:1600,d:18,h:2000,z:0},
 {id:'led-niche',group:'Iluminação',label:'LED de nicho',kind:'led',w:450,d:18,h:10,z:1200,color:'#ffe6b4'}
];
const catalog=()=>copy(types);
function definition(id){return types.find(x=>x.id===id)||null;}
function create(id,engine=globalThis.ArqueModules){
 const p=definition(id);
 if(!p)throw Error('Modelo não encontrado no catálogo Arque.');
 if(p.kind==='corner45'){
  if(!globalThis.ArqueCorner45)throw Error('Módulo pentagonal de canto indisponível.');
  const item=globalThis.ArqueCorner45.create(engine);
  const config=engine.check({...item.moduleSpec,doorCount:p.doors,corner45:{enabled:true,chamfer:380,shelves:p.shelves}});
  engine.regenerate(item,config);item.presetId=p.id;item.catalogGroup=p.group;return item;
 }
 if(p.kind==='module'){
  if(!engine||!engine.parts)throw Error('Motor paramétrico indisponível.');
  const s=engine.standard();
  Object.assign(s,{name:p.label,width:p.w,depth:p.d,height:p.h,doorCount:p.doors,shelfCount:p.shelves,back:p.back||s.back,
   fixedShelves:(p.fixed||[]).map(at=>({bay:0,at})),
   accessories:p.drawers?[{type:'drawer',bay:0,count:p.drawers,slideSide:12.7,rearClearance:20,frontClearance:20,height:120,slideLength:400}]:
    p.spice?[{type:'spice',bay:0,count:p.spice,slideSide:12.7,rearClearance:20,frontClearance:20,height:100,slideLength:400}]:[]});
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
 if(Number(module.rotation||0)!==0||Number(appliance.rotation||0)!==0)throw Error('Encaixe automático requer nicho e aparelho sem rotação; use posicionamento manual para canto girado.');
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