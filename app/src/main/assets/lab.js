/* Arque Measure | Laboratorio 2D em milimetros. Sem inferencia automatica de medidas. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueLab=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const kinds={wall:['Parede / linha',1500,0],countertop:['Bancada / pedra',1600,600],sink:['Cuba',500,400],base:['Armário base',800,560],upper:['Armário aéreo',800,350],door:['Porta',450,20],drawers:['Gaveteiro',450,560],filler:['Tamponamento',30,560],cava:['Puxador cava',450,35],outlet:['Tomada / ponto',80,80],drain:['Esgoto / água',80,80],fridge:['Geladeira · referência',760,720],stove:['Fogão/forno · referência',600,600],cooktop:['Cooktop · referência',600,510],led:['Fita LED · referência',900,25],panel:['Peça avulsa retangular',600,300]};
const modes={plan:'Planta baixa 2D',front:'Vista frontal 2D',iso:'Ambiente espacial 3D'};
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Number(n).toLocaleString('pt-BR',{maximumFractionDigits:1});
const uid=()=>String(Date.now())+'-'+Math.random().toString(36).slice(2);
const copy=o=>JSON.parse(JSON.stringify(o));
const numeric=(value,min=0,max=50000)=>{const n=Number(String(value).replace(',','.'));if(!Number.isFinite(n)||n<min||n>max)throw Error('Medida inválida: informe um valor entre '+min+' e '+max+' mm.');return Math.round(n*10)/10;};
function ensureModuleCodes(layout){
 if(!Number.isInteger(layout.moduleSerial)||layout.moduleSerial<0)layout.moduleSerial=0;
 const used=new Set();
 for(const item of layout.items||[]){
  if(item.kind==='module'&&/^M\d{2,}$/.test(item.code||'')&&!used.has(item.code)){
   used.add(item.code);layout.moduleSerial=Math.max(layout.moduleSerial,Number(item.code.slice(1)));
  }else if(item.kind==='module')item.code='';
 }
 for(const item of layout.items||[]){
  if(item.kind!=='module'||item.code)continue;
  let code;
  do{code='M'+String(++layout.moduleSerial).padStart(2,'0');}while(used.has(code));
  item.code=code;used.add(code);
 }
 return layout;
}
function layout(p,roomId){
 if(!p||!Array.isArray(p.rooms)||!p.rooms.some(r=>r.id===roomId))throw Error('Selecione um ambiente cadastrado.');
 if(!p.labLayouts||typeof p.labLayouts!=='object')p.labLayouts={};
 let l=p.labLayouts[roomId];
 if(!l)l=p.labLayouts[roomId]={width:3500,depth:2800,height:2600,confirmed:false,roomRefs:{},items:[],history:[],future:[],photoId:''};
 if(!Array.isArray(l.items))l.items=[];
 if(!Array.isArray(l.history))l.history=[];
 if(!Array.isArray(l.future))l.future=[];
 if(!l.roomRefs)l.roomRefs={};
 ensureModuleCodes(l);
 return l;
}
function snapshot(l){return copy({width:l.width,depth:l.depth,height:l.height,confirmed:l.confirmed,roomRefs:l.roomRefs,items:l.items,photoId:l.photoId,moduleSerial:l.moduleSerial});}
function remember(l){l.history.push(snapshot(l));if(l.history.length>25)l.history.shift();l.future=[];}
function undo(l){if(!l.history.length)return false;l.future.push(snapshot(l));Object.assign(l,l.history.pop());return true;}
function redo(l){if(!l.future.length)return false;l.history.push(snapshot(l));Object.assign(l,l.future.pop());return true;}
function add(l,kind,x,y,view='plan'){
 if(!kinds[kind]&&kind!=='pen')throw Error('Elemento desconhecido');
 if(!modes[view])throw Error('Vista desconhecida');
 const dims=kinds[kind]||['Rabisco',0,0];
 const item={id:uid(),kind,label:dims[0],x:numeric(x),y:numeric(y),w:dims[1],d:dims[2],height:({base:730,upper:700,fridge:1850,stove:850,cooktop:45,led:12,countertop:35,sink:170})[kind]||0,z:({fridge:0,stove:0,cooktop:900,led:1450,countertop:900,sink:720})[kind]||0,view,refs:{}};
 if(kind==='panel'){item.material='MDF 18 mm';item.thickness=18;item.grain=false;item.edge2=0;item.edge04=0;}
 remember(l);l.items.push(item);return item;
}
function place(item,values){
 for(const key of ['x','y','w','d','height'])if(values[key]!==undefined)item[key]=numeric(values[key],key==='w'&&item.kind==='wall'?-50000:key==='d'&&item.kind==='wall'?-50000:0);
 if(values.label!==undefined)item.label=String(values.label).trim().slice(0,70)||kinds[item.kind]?.[0]||'Elemento';
 return item;
}
function attach(l,room,measureId,target,itemId){
 const m=(room.measurements||[]).find(x=>x.id===measureId);if(!m)throw Error('Leitura não encontrada no ambiente.');
 const value=numeric(m.value,0.1);
 if(!['width','depth','height','w','d'].includes(target))throw Error('Destino inválido.');
 if(itemId){const item=l.items.find(x=>x.id===itemId);if(!item)throw Error('Peça não encontrada.');if(!['w','d','height'].includes(target))throw Error('Selecione uma dimensão da peça.');if(item.kind==='module'&&globalThis.ArqueModules){const k={w:'width',d:'depth',height:'height'}[target],update={[k]:value};globalThis.ArqueModules.parts({...item.moduleSpec,...update});remember(l);globalThis.ArqueModules.regenerate(item,update);}else{remember(l);item[target]=value;}item.refs[target]={id:m.id,recorded:value};}
 else{if(!['width','depth','height'].includes(target))throw Error('Selecione largura, profundidade ou altura do ambiente.');remember(l);l[target]=value;l.confirmed=true;l.roomRefs[target]={id:m.id,recorded:value};}
 return value;
}
function linkStatus(ref,room){
 if(!ref)return '';
 const m=(room.measurements||[]).find(x=>x.id===ref.id);
 if(!m)return 'Medida de origem excluída: conferir';
 if(Number(m.value)!==Number(ref.recorded))return 'Medida de origem alterada: conferir '+fmt(ref.recorded)+' → '+fmt(m.value)+' mm';
 return 'Vinculado à medição '+fmt(ref.recorded)+' mm ('+(m.source||'manual')+')';
}
function shape(item,selected){
 const x=item.x,y=item.y,w=item.w,d=item.d,k=item.kind,sw=selected?15:8,fill=selected?'#d8eef9':'#e7f1f6';
 const attrs='stroke="#246681" stroke-width="'+sw+'" vector-effect="non-scaling-stroke"';
 if(k==='pen'){const pts=(item.points||[]).map(p=>p[0]+','+p[1]).join(' ');return '<polyline points="'+pts+'" fill="none" stroke="#277da8" stroke-width="9" vector-effect="non-scaling-stroke" stroke-linecap="round" stroke-linejoin="round"/>';}
 if(k==='profile'){
  const pts=(item.points||[]).map(p=>(x+p[0]*w)+','+(y+p[1]*d)).join(' ');
  return '<rect x="'+x+'" y="'+y+'" width="'+w+'" height="'+d+'" fill="none" stroke="#a4c5d5" stroke-dasharray="9 9" stroke-width="3" vector-effect="non-scaling-stroke"/><polyline points="'+pts+'" fill="none" stroke="'+(selected?'#187cae':'#486b82')+'" stroke-width="7" vector-effect="non-scaling-stroke" stroke-linejoin="round"/>';
 }
 if(k==='wall')return '<line x1="'+x+'" y1="'+y+'" x2="'+(x+w)+'" y2="'+(y+d)+'" stroke="#263b45" stroke-width="15" vector-effect="non-scaling-stroke"/>';
 if(k==='outlet'||k==='drain')return '<circle cx="'+(x+w/2)+'" cy="'+(y+d/2)+'" r="'+Math.max(15,Math.min(w,d)/2)+'" fill="'+fill+'" '+attrs+'/>'+'<text x="'+(x+w/2)+'" y="'+(y+d/2)+'" text-anchor="middle" dominant-baseline="middle" font-size="40" fill="#165274">'+(k==='outlet'?'T':'H')+'</text>';
 let out='<rect x="'+x+'" y="'+y+'" width="'+w+'" height="'+d+'" rx="5" fill="'+(k==='filler'?'#aab8bf':fill)+'" '+attrs+'/>';
 if(k==='countertop')out+='<rect x="'+(x+20)+'" y="'+(y+20)+'" width="'+Math.max(1,w-40)+'" height="'+Math.max(1,d-40)+'" rx="4" fill="none" stroke="#91b3c5" stroke-width="3"/>';
 if(k==='sink')out+='<ellipse cx="'+(x+w/2)+'" cy="'+(y+d/2)+'" rx="'+Math.max(1,w*.39)+'" ry="'+Math.max(1,d*.36)+'" fill="#fff" stroke="#628aa0" stroke-width="5"/>';
 if(k==='base'||k==='upper')out+='<line x1="'+(x+w/2)+'" y1="'+y+'" x2="'+(x+w/2)+'" y2="'+(y+d)+'" stroke="#5c849a" stroke-width="5"/>';
 if(k==='drawers'){for(let i=1;i<4;i++)out+='<line x1="'+x+'" y1="'+(y+d*i/4)+'" x2="'+(x+w)+'" y2="'+(y+d*i/4)+'" stroke="#5c849a" stroke-width="5"/>';}
 if(k==='door')out+='<line x1="'+x+'" y1="'+(y+d)+'" x2="'+(x+w)+'" y2="'+y+'" stroke="#6d9bb3" stroke-width="4"/>';
 if(k==='cava')out+='<path d="M '+(x+8)+' '+(y+d*.25)+' L '+(x+w-8)+' '+(y+d*.25)+' L '+(x+w-8)+' '+(y+d*.55)+'" fill="none" stroke="#176f9d" stroke-width="5"/>';
 return out;
}
function moduleShape(item,view,selected,l){
 const spec=item.moduleSpec||{},t=Number(spec.thickness)||18,W=item.w,depth=item.d,H=item.height;
 const x=item.x,y=view==='front'?(item.frontY??Math.max(0,l.height-H-100)):item.y;
 const rotated=Number(item.rotation||0)%180===90,shownW=view==='front'?W:(rotated?depth:W),shownH=view==='front'?H:(rotated?W:depth);
 let res='<rect x="'+x+'" y="'+y+'" width="'+shownW+'" height="'+shownH+'" fill="'+(selected?'#cbe9f6':'#dfedf5')+'" stroke="'+(selected?'#117caf':'#477b95')+'" stroke-width="7" vector-effect="non-scaling-stroke"/>';
 if(view==='front'){
  res+='<path d="M '+(x+t)+' '+y+' V '+(y+H)+' M '+(x+W-t)+' '+y+' V '+(y+H)+' M '+x+' '+(y+t)+' H '+(x+W)+' M '+x+' '+(y+H-t)+' H '+(x+W)+'" stroke="#577e90" stroke-width="4" vector-effect="non-scaling-stroke" fill="none"/>';
  const inner=W-2*t;
  for(const pos of spec.vertical||[]){let cx=x+t+inner*pos;res+='<rect x="'+(cx-t/2)+'" y="'+(y+t)+'" width="'+t+'" height="'+Math.max(1,H-2*t)+'" fill="#8db9ce" stroke="#456b81" stroke-width="2"/>';}
  try{
   const bays=globalThis.ArqueModules?.bayBounds(spec)||[];
   for(let i=0;i<bays.length;i++){
    const b=bays[i],count=spec.shelvesByBay?.[i]??spec.shelfCount??0;
    for(let j=0;j<count;j++){
     const at=(j+1)/(count+1),covered=(spec.fixedShelves||[]).some(f=>f.bay===i&&Math.abs(f.at-at)*(H-2*t)<t);
     if(covered)continue;
     const sy=y+t+(H-2*t)*at;
     res+='<line x1="'+(x+b.start)+'" x2="'+(x+b.end)+'" y1="'+sy+'" y2="'+sy+'" stroke="#7194a8" stroke-width="7" vector-effect="non-scaling-stroke"/>';
    }
    if(b.width>=100&&H>=280)res+='<text x="'+(x+(b.start+b.end)/2)+'" y="'+(y+H-t-18)+'" font-size="'+Math.max(14,Math.min(30,b.width/5))+'" fill="#235b77" text-anchor="middle" pointer-events="none">'+fmt(b.width)+' mm</text>';
   }
  }catch(_){/* Vista desenhada não muda os cálculos de montagem. */}
  try{
   const bays=globalThis.ArqueModules?.bayBounds(spec)||[];
   for(const slot of spec.fixedShelves||[]){const bay=bays[slot.bay];if(!bay)continue;const yy=y+t+(H-2*t)*slot.at;res+='<line x1="'+(x+bay.start)+'" x2="'+(x+bay.end)+'" y1="'+yy+'" y2="'+yy+'" stroke="#327d9d" stroke-width="8" vector-effect="non-scaling-stroke"/>';}
   for(const acc of spec.accessories||[]){const bay=bays[acc.bay];if(!bay)continue;for(let i=0;i<Math.min(6,acc.count||1);i++){const ay=y+H-t-(i+1)*(acc.height+8);res+='<rect x="'+(x+bay.start+acc.slideSide)+'" y="'+ay+'" width="'+Math.max(1,bay.width-2*acc.slideSide)+'" height="'+Math.max(1,acc.height)+'" fill="none" stroke="#d08332" stroke-width="5" vector-effect="non-scaling-stroke"/>';}}
  }catch(_){/* Falha visual não altera geometria ou peças. */}
  try{
   const bays=globalThis.ArqueModules?.bayBounds(globalThis.ArqueModules.check(spec))||[];
   for(const p of spec.assemblyPieces||[]){
    const b=bays[p.bay];if(!b)continue;
    const bx=x+b.start+p.widthClearance,bw=Math.max(1,b.width-2*p.widthClearance);
    if(p.type==='backPanel')res+='<rect x="'+bx+'" y="'+(y+t)+'" width="'+bw+'" height="'+Math.max(1,H-2*t)+'" fill="#819faf" fill-opacity=".11" stroke="#738e9f" stroke-dasharray="9 9" stroke-width="2" vector-effect="non-scaling-stroke"/>';
    else{
     const py=y+t+(H-2*t)*p.at-p.height/2;
     res+='<rect x="'+bx+'" y="'+py+'" width="'+bw+'" height="'+p.height+'" fill="'+(p.type==='cavaRail'?'#87bbd4':'#a7bbc4')+'" fill-opacity=".75" stroke="#3c738d" stroke-width="3" vector-effect="non-scaling-stroke"/>';
     if(p.type==='cavaRail')res+='<path d="M '+(bx+10)+' '+(py+8)+' H '+(bx+bw-10)+'" stroke="#11618d" stroke-width="4" vector-effect="non-scaling-stroke"/>';
    }
   }
   if(spec.doorMode==='byBay'){
    for(const [i,b] of bays.entries()){
     const qty=spec.bayDoors?.[i]||0;
     for(let j=1;j<qty;j++){const dx=x+b.start+b.width*j/qty;res+='<line x1="'+dx+'" x2="'+dx+'" y1="'+(y+12)+'" y2="'+(y+H-12)+'" stroke="#317ca3" stroke-width="4" stroke-dasharray="14 12" vector-effect="non-scaling-stroke"/>';}
     if(qty===1)res+='<rect x="'+(x+b.start+5)+'" y="'+(y+5)+'" width="'+Math.max(1,b.width-10)+'" height="'+Math.max(1,H-10)+'" fill="none" stroke="#3a83a8" stroke-dasharray="12 12" stroke-width="3" vector-effect="non-scaling-stroke"/>';
    }
   }
  }catch(_){/* Desenho de referência não altera a lista técnica. */}
  if(spec.doorMode!=='byBay'&&spec.doorCount){for(let j=1;j<spec.doorCount;j++){let dx=x+W*j/spec.doorCount;res+='<path d="M '+dx+' '+(y+12)+' V '+(y+H-12)+'" stroke="#317ca3" stroke-width="3" stroke-dasharray="14 12"/>';}
   if(spec.frontType==='cava')res+='<path d="M '+(x+30)+' '+(y+60)+' H '+(x+W-30)+'" stroke="#0f729c" stroke-width="6" vector-effect="non-scaling-stroke"/>';}
 }else{
  res+='<line x1="'+x+'" x2="'+(x+shownW)+'" y1="'+(y+shownH*.14)+'" y2="'+(y+shownH*.14)+'" stroke="#8bb6cc" stroke-width="5" vector-effect="non-scaling-stroke"/>';
  if(rotated)res+='<text x="'+(x+shownW/2)+'" y="'+(y+shownH/2)+'" text-anchor="middle" font-size="30" fill="#2b6587">90°</text>'; 
 }
 if(view==='front'){
  try{
   const bays=globalThis.ArqueModules?.bayBounds(globalThis.ArqueModules.check(spec))||[];
   for(const [i,b] of bays.entries()){
    const active=selected&&focusedModule===item.id&&focusedBay===i;
    res+='<rect data-lab-bay="'+i+'" x="'+(x+b.start)+'" y="'+(y+t)+'" width="'+b.width+'" height="'+Math.max(1,H-2*t)+'" fill="'+(active?'#36a4db':'transparent')+'" fill-opacity="'+(active?'.10':'0')+'" stroke="'+(active?'#087fb7':'transparent')+'" stroke-width="'+(active?7:0)+'" stroke-dasharray="18 12" vector-effect="non-scaling-stroke" pointer-events="all"/>';
   }
  }catch(_){/* Não altera medida de fábrica. */}
 }
 return res;
}
function svg(l,view,selectedId){
 const W=l.width||3500,H=view==='front'?(l.height||2600):(l.depth||2800);
 const ticks=Math.max(W,H)>10000?500:100;
 let a='<svg id="labBoard" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '+W+' '+H+'" width="100%" style="aspect-ratio:'+W+'/'+H+';touch-action:none" role="img" aria-label="Ambiente em milímetros, '+esc(modes[view])+'"><defs><pattern id="labGrid" width="'+ticks+'" height="'+ticks+'" patternUnits="userSpaceOnUse"><path d="M '+ticks+' 0 L 0 0 0 '+ticks+'" fill="none" stroke="#d9e6ed" stroke-width="3"/></pattern></defs><rect width="'+W+'" height="'+H+'" fill="#fff"/><rect width="'+W+'" height="'+H+'" fill="url(#labGrid)"/><rect x="7" y="7" width="'+Math.max(1,W-14)+'" height="'+Math.max(1,H-14)+'" fill="none" stroke="#526570" stroke-width="14" vector-effect="non-scaling-stroke"/>';
 for(const item of l.items.filter(x=>x.view===view||x.kind==='module')){const sel=item.id===selectedId;
  a+='<g data-lab-object="'+esc(item.id)+'" class="'+(sel?'lab-selected':'')+'">'+(item.kind==='module'?moduleShape(item,view,sel,l):shape(item,sel))+'</g>';
  if(item.kind!=='pen'&&item.kind!=='wall')a+='<text x="'+(item.x+((view==='plan'&&Number(item.rotation||0)%180===90)?item.d:item.w)/2)+'" y="'+Math.max(38,item.y-22)+'" font-size="'+Math.max(34,Math.min(70,W/75))+'" text-anchor="middle" fill="'+(sel?'#0c6899':'#667e89')+'" pointer-events="none">'+esc(item.label)+' · '+fmt(item.w)+' × '+fmt(item.d)+'</text>';
 }
 return a+'</svg>';
}
let activeRoom='',view='iso',tool='select',selected='',gridSnap=true,drag=null,focusedBay=0,focusedModule='',selectedPartKey='',visualAngle=40,visualZoom=1,visualMode='fronts',pointLineId='';
const option=(value,label,current)=>'<option value="'+esc(value)+'" '+(value===current?'selected':'')+'>'+esc(label)+'</option>';
const button=(label,action,arg='',active=false)=>'<button type="button" data-lab="'+action+'" data-arg="'+esc(arg)+'" class="'+(active?'lab-active':'')+'">'+label+'</button>';
function screen(p,state){
 const rooms=p.rooms||[];if(!rooms.length)return '<div class="notice">Cadastre um ambiente em Ambientes e medições para iniciar o Laboratório.</div>';
 const r=rooms.find(x=>x.id===activeRoom)||rooms[0];activeRoom=r.id;const l=layout(p,r.id);
 const photos=(p.photos||[]).filter(ph=>!ph.roomId||ph.roomId===r.id);
 const measurements=(r.measurements||[]).filter(m=>Number.isFinite(Number(m.value))&&Number(m.value)>0);
 const item=l.items.find(x=>x.id===selected);
 let out='<section class="lab"><div class="lab-heading"><div><h3>Laboratório · ambiente visual e montagem</h3><small>Ambiente espacial, planta e elevação ligados à mesma engenharia em milímetros. Funciona offline.</small></div><label>Ambiente<select id="labRoom">'+rooms.map(x=>option(x.id,x.name,r.id)).join('')+'</select></label></div>';
 out+='<div class="lab-views">'+button('▧ Ambiente 3D','view','iso',view==='iso')+button('▱ Planta', 'view','plan',view==='plan')+button('▥ Vista frontal','view','front',view==='front')+'<span>'+fmt(l.width)+' × '+fmt(view==='front'?l.height:l.depth)+' mm'+(l.confirmed?' · informado':' · rascunho')+'</span></div>';
 out+='<div class="lab-sizes"><label>Largura da parede (mm)<input id="labWidth" type="number" min="100" max="50000" value="'+esc(l.width)+'"></label><label>Profundidade (mm)<input id="labDepth" type="number" min="100" max="50000" value="'+esc(l.depth)+'"></label><label>Altura (mm)<input id="labHeight" type="number" min="100" max="50000" value="'+esc(l.height)+'"></label>'+button('Aplicar dimensões','roomSize')+'</div>';
 if(!l.confirmed)out+='<p class="lab-warning">As dimensões exibidas são apenas um rascunho inicial. Confirme com medidas feitas na obra.</p>';
 out+='<div class="lab-actions">'+(view==='iso'?button('↶ Girar','visualRotate','-25')+button('Girar ↷','visualRotate','25')+button('− Zoom','visualZoom','-.2')+button('＋ Zoom','visualZoom','.2')+button('Ver frentes','visualMode','fronts',visualMode==='fronts')+button('Ver estrutura','visualMode','structure',visualMode==='structure'):'')+(view!=='iso'?button('✓ Alinhamento automático','autoSketch'):'')+button('↶ Desfazer','undo')+button('↷ Refazer','redo')+button('⌗ Ajuste 5 mm','snap','',gridSnap)+button('Salvar desenho SVG','export')+'</div>';
 const Adv=globalThis.ArqueAdvanced;
 if(Adv){
  const modules=l.items.filter(i=>i.kind==='module');
  const opts=modules.map(i=>option(i.id,(i.code||'M')+' · '+i.label,i.id===selected?selected:'')).join('');
  out+='<div class="lab-adv-panel"><h4>Oficina Arque · construção inteligente</h4><div class="lab-adv-grid">';
  out+='<details><summary>① Cozinha em L · encaixe</summary><p class="lab-fine">Posiciona dois móveis nas paredes de fundo e esquerda, considerando o fundo aplicado.</p>'+
   '<label>Móvel da parede de fundo<select id="advCornerBack">'+opts+'</select></label>'+
   '<label>Móvel da parede esquerda<select id="advCornerSide">'+modules.map(i=>option(i.id,(i.code||'M')+' · '+i.label,modules[1]?.id||'')).join('')+'</select></label>'+
   '<label>Folga do canto em mm<input id="advCornerGap" type="number" min="0" max="300" step=".1" value="30"></label>'+
   button('Montar canto 90°','advCorner')+'<small>Canto 45° ainda requer desenho técnico específico e conferência.</small></details>';
  out+='<details><summary>② Cava entre módulos</summary><p class="lab-fine">Alinha a régua de cava no mesmo nível absoluto (Z), sem presumir usinagem pronta.</p>'+
   '<label>Referência<select id="advCavaOrigin">'+opts+'</select></label>'+
   '<label>Segundo módulo<select id="advCavaTarget">'+modules.map(i=>option(i.id,(i.code||'M')+' · '+i.label,modules[1]?.id||'')).join('')+'</select></label>'+
   '<label>Nível a partir do piso (mm)<input id="advCavaLevel" type="number" value="680" step=".1"></label>'+
   '<label>Altura da régua (mm)<input id="advCavaHeight" type="number" min="30" max="200" value="70"></label>'+
   '<label>Folga lateral (mm)<input id="advCavaGap" type="number" min="0" max="20" value="3"></label>'+
   button('Alinhar e gerar réguas','advCava')+'</details>';
  out+='<details><summary>③ Ímã de encaixe</summary><p class="lab-fine">Arrastar módulos com encaixe de bordas e verificação de colisões.</p>'+
   button(magnetEnabled?'Ímã ativo · desligar':'Ímã desligado · ativar','advMagnet')+'</details>';
  out+='<details><summary>④ MDF e iluminação</summary><p class="lab-fine">Selecione um módulo para editar estrutura/frentes e um LED para editar a cor e o estado da luz.</p>'+
   button('Ver acabamentos','visualMode','fronts')+button('Ver estrutura','visualMode','structure')+'</details>';
  const report=Adv.production(l,globalThis.ArqueModules);
  out+='<details><summary>⑤ Etiquetas e conferência de produção</summary><p class="lab-fine">'+report.lines.length+' referências de peças · '+report.errors.length+' erros · '+report.warnings.length+' pendências.</p>'+
   report.errors.slice(0,3).map(v=>'<p class="lab-warning">'+esc(v)+'</p>').join('')+
   report.warnings.slice(0,4).map(v=>'<p class="lab-fine">'+esc(v)+'</p>').join('')+
   button('Exportar CSV de peças','advExportCsv')+'<small>Pré-lista dimensional, não libera CNC.</small></details>';
  out+='<details><summary>⑥ Paredes do esboço</summary><p class="lab-fine">Corrige o traçado na planta e gera segmentos de parede com medidas preliminares.</p>'+
   '<label>Tolerância (mm)<input id="advWallTolerance" type="number" min="0" max="300" value="40"></label>'+
   button('Criar paredes do desenho','advTraceWalls')+
   (l.wallTrace?'<p class="lab-fine">'+l.wallTrace.segments.length+' segmentos · '+(l.wallTrace.verified?'conferido':'pendente de medição')+'</p>':'')+
   '<small>Não presume escala fotográfica nem confirma a obra automaticamente.</small></details></div></div>';
 }
 const visual=globalThis.ArqueVisual;
 out+='<div class="lab-main '+(view==='iso'?'lab-with-catalog':'')+'">';
 if(view==='iso'){
  const entries=visual?.catalog(l)||[];
  out+='<aside class="lab-catalog"><h4>Biblioteca de construção</h4><p>Inserir no ambiente · referências de eletros exigem medidas do fabricante</p><div class="lab-catalog-add">'+
   button('＋ Armário inferior','catalogAdd','base')+button('＋ Armário aéreo','catalogAdd','upper')+
   button('＋ Torre','catalogAdd','tower')+button('＋ Bancada','catalogAdd','countertop')+button('＋ Cuba','catalogAdd','sink')+button('＋ Fogão','catalogAdd','stove')+button('＋ Geladeira','catalogAdd','fridge')+button('＋ Cooktop','catalogAdd','cooktop')+button('＋ LED linear','catalogAdd','led')+
   '</div><div class="lab-kitchen-presets"><h4>Catálogo Arque Cozinha · editável</h4><p>Modelos de referência: ajuste as medidas antes de fabricar.</p>'+
  (globalThis.ArqueKitchen?.groupIds()||[]).map(group=>'<details '+(['Inferiores','Eletrodomésticos'].includes(group)?'open':'')+'><summary>'+esc(group)+'</summary><div class="lab-preset-list">'+globalThis.ArqueKitchen.catalog().filter(p=>p.group===group).map(p=>button('＋ '+esc(p.label),'catalogPreset',p.id)).join('')+'</div></details>').join('')+
  (state?.moduleTemplates?.length?'<details><summary>Meus modelos salvos</summary><div class="lab-preset-list">'+state.moduleTemplates.map(t=>button('＋ '+esc(t.name),'catalogSaved',t.id)).join('')+'</div></details>':'')+'</div><h4>Árvore dos módulos</h4><p>Toque para selecionar e editar</p><div class="lab-tree">'+
   (entries.map(e=>'<button type="button" data-lab="catalogSelect" data-arg="'+esc(e.id)+'" class="'+(e.id===selected?'lab-active':'')+'"><b>'+esc(e.code)+'</b><span>'+esc(e.name)+'<small>'+esc(e.dims)+' · Z '+fmt(e.z)+' mm</small></span></button>').join('')||'<p>Adicione um módulo para começar.</p>')+
   '</div><p class="lab-fine">Seleção, dimensões e peças são ligadas ao mesmo projeto. Nenhuma medida é deduzida da foto.</p></aside>';
 }
 out+='<div class="lab-work">';
 if(view!=='iso')out+='<div class="lab-palette">'+button('↖ Selecionar / mover','tool','select',tool==='select')+button('✎ Rabisco','tool','pen',tool==='pen')+button('⌁ Linha por pontos','tool','pointline',tool==='pointline')+(tool==='pointline'?button('Finalizar linha','finishPointLine'):'')+Object.entries(kinds).map(([key,item])=>button(item[0],'tool',key,tool===key)).join('')+'</div>';
 out+='<div class="lab-board-wrap">'+(view==='iso'?(visual?visual.scene(l,selected,{angle:visualAngle,zoom:visualZoom,mode:visualMode}):'<p>Visualizador não carregado.</p>'):svg(l,view,selected))+'</div>';
 out+='<div class="lab-hint">'+(view==='iso'?'Toque no móvel para identificá-lo; arraste o móvel selecionado para reposicionar em X/Y. Use Girar, Zoom e Ver estrutura. Ajuste as medidas numéricas na lateral.' :tool==='pointline'?'Toque para adicionar pontos à linha; use Finalizar linha e Alinhamento automático.':'Rabisco ou Linha por pontos: o alinhamento automático corrige linhas e conecta extremidades.')+'</div></div>';
 out+='<aside class="lab-side"><h4>Medidas salvas</h4><p>Escolha a medição real e onde aplicar, sem mudar o registro original.</p><label>Medição<select id="labMeasure">'+option('','Selecionar medida','')+measurements.map(m=>option(m.id,fmt(m.value)+' mm · '+m.kind+' · '+(m.target||'sem posição'), '')).join('')+'</select></label>';
 out+='<label>Aplicar em<select id="labTarget">'+[['width','Largura do ambiente'],['depth','Profundidade do ambiente'],['height','Altura do ambiente'],['w','Largura da peça selecionada'],['d','Profundidade da peça selecionada'],['itemHeight','Altura da peça selecionada']].map(a=>option(a[0],a[1],'')).join('')+'</select></label>'+button('Vincular medição','attach');
 for(const k of ['width','depth','height']){const status=linkStatus(l.roomRefs[k],r);if(status)out+='<p class="lab-link '+(status.includes('conferir')?'lab-warning':'')+'">'+esc(k)+' · '+esc(status)+'</p>';}
 out+='<h4>Foto de referência</h4><select id="labPhoto">'+option('','Sem fotografia',l.photoId||'')+photos.map(ph=>option(ph.id,ph.name||'Foto',l.photoId||'')).join('')+'</select>';
 const ph=photos.find(x=>x.id===l.photoId);if(ph&&typeof ph.data==='string'&&/^data:image\//.test(ph.data))out+='<img class="lab-photo" src="'+esc(ph.data)+'" alt="Foto original do ambiente">';
 out+='<p class="lab-fine">Fotos reais são referência visual, não escala automática.</p>';
 out+='<h4>Peça selecionada</h4>';
 if(item){
  out+='<div class="lab-item-title">'+(visual?esc(visual.identifier(item,l.items.indexOf(item)))+' · ':'')+esc(item.label)+' <small>'+esc(item.kind==='module'?'Módulo construtivo paramétrico':modes[item.view]||'Peça avulsa')+'</small></div>';
   if(item.kind==='module'&&globalThis.ArqueModules){const gen=globalThis.ArqueModules.parts(item.moduleSpec);out+='<div class="lab-selected-summary"><b>'+fmt(item.w)+' × '+fmt(item.height)+' × '+fmt(item.d)+' mm</b><small>'+gen.parts.reduce((total,p)=>total+p.qty,0)+' peças · '+gen.bays.length+' vãos · '+esc(item.moduleSpec.frontType||'Sem puxador')+'</small></div>';}
  if(item.kind==='module'&&globalThis.ArqueModules){
    const computed=globalThis.ArqueModules.parts(item.moduleSpec),parts=computed.parts,selectedPart=parts.find(p=>p.key===selectedPartKey);
    out+='<div class="lab-construction-tree"><details '+(selectedPart?'open':'')+'><summary>Identificação construtiva · '+parts.reduce((sum,p)=>sum+p.qty,0)+' peças</summary><p class="lab-fine">Identifique a peça pelo módulo, código, material e dimensões de corte.</p><div class="lab-components">'+parts.map((p,i)=>{
     const pc='P'+String(i+1).padStart(2,'0');
     return '<button type="button" data-lab="partSelect" data-arg="'+esc(p.key)+'" class="'+(p.key===selectedPartKey?'lab-active':'')+'"><b>'+pc+'</b><span>'+esc(p.name)+'<small>'+fmt(p.w)+' × '+fmt(p.h)+' mm · '+p.qty+'x</small></span></button>';
    }).join('')+'</div></details>';
    if(selectedPart){const index=parts.indexOf(selectedPart)+1;out+='<div class="lab-selected-part"><b>'+esc((visual?visual.identifier(item,l.items.indexOf(item)):'M')+'-P'+String(index).padStart(2,'0'))+' · '+esc(selectedPart.name)+'</b><p>'+fmt(selectedPart.w)+' × '+fmt(selectedPart.h)+' mm · '+selectedPart.qty+' unidade(s)</p><p>'+esc(selectedPart.material)+' · espessura '+fmt(selectedPart.thickness)+' mm</p><p>Veio: '+(selectedPart.grain?'fixo no comprimento':'giro permitido')+' · bordas 2 mm: '+selectedPart.edge2+' · bordas 0,4 mm: '+selectedPart.edge04+'</p><p>'+esc(selectedPart.notes||'Conferir montagem e ferragens antes do corte.')+'</p></div>';}
    out+='</div>';
   }
   out+='<label>Nome<input id="labName" maxlength="70" value="'+esc(item.label)+'"></label>';
  if(item.kind==='module'&&globalThis.ArqueModules){
   const s=item.moduleSpec;
   out+='<div class="lab-quick-edit"><h4>Editar módulo selecionado</h4><div class="lab-module-grid">'+
    '<label>Portas padrão<input id="labQuickDoors" type="number" min="0" max="8" value="'+s.doorCount+'"></label>'+
    '<label>Prateleiras padrão<input id="labQuickShelves" type="number" min="0" max="12" value="'+s.shelfCount+'"></label>'+
    '<label>Material da estrutura<input id="labQuickMaterial" maxlength="90" value="'+esc(s.caseMaterial)+'"></label>'+
    '<label>Material das frentes<input id="labQuickFrontMaterial" maxlength="90" value="'+esc(s.frontMaterial)+'"></label>'+
    '<label>Puxador<select id="labQuickFront">'+[['cava','Cava'],['concha','Concha'],['sem','Sem puxador']].map(k=>option(k[0],k[1],s.frontType)).join('')+'</select></label>'+
    '</div>'+button('Aplicar edição','catalogEditModule')+button('Salvar como meu modelo','catalogSaveOwn')+
    '<p class="lab-fine">Para alterar portas e prateleiras por vão, utilize a Montagem por Peça.</p></div>';
  }else if(item.kind==='appliance'||item.kind==='led'||['fridge','cooktop','stove'].includes(item.kind)){
   out+='<div class="lab-quick-edit"><h4>Objeto de referência</h4><p class="lab-fine">'+esc(item.notice||'Confirmar medidas reais antes de fabricar qualquer nicho.')+'</p>';
   if(item.kind==='led')out+='<label>Cor da luz<input id="labLightColor" type="color" value="'+(/^#[0-9a-f]{6}$/i.test(item.lightColor||'')?item.lightColor:'#ffd292')+'"></label>'+
    '<label>LED<select id="labLightOn">'+option('on','Ligado',item.lightOn===false?'off':'on')+option('off','Desligado',item.lightOn===false?'off':'on')+'</select></label>';
   else out+='<label>Modelo / referência técnica<input id="labDeviceModel" maxlength="90" value="'+esc(item.deviceModel||'')+'" placeholder="Marca e modelo do fabricante"></label>';
   if(item.kind==='appliance'){
    if(item.hostModuleId)out+='<p class="lab-link">'+esc(item.note||'Aparelho encaixado por dimensão de referência. Conferir fabricante.')+'</p>';
    const niches=l.items.filter(x=>x.kind==='module'&&x.moduleSpec?.doorCount===0);
    out+='<div class="lab-niche-fit"><h4>Encaixe assistido no nicho</h4><p class="lab-fine">Não redimensiona o aparelho. Informe folgas conforme o fabricante.</p>'+
     '<label>Nicho do projeto<select id="labFitNiche">'+niches.map(n=>option(n.id,(n.code||'M')+' · '+n.label,'')).join('')+'</select></label>'+
     '<div class="lab-props">'+
     '<label>Folga lateral/lado (mm)<input id="labFitSide" type="number" min="0" value="5"></label>'+
     '<label>Folga superior (mm)<input id="labFitTop" type="number" min="0" value="10"></label>'+
     '<label>Folga inferior (mm)<input id="labFitBottom" type="number" min="0" value="5"></label>'+
     '<label>Folga traseira (mm)<input id="labFitRear" type="number" min="0" value="20"></label></div>'+
     (niches.length?button('Verificar e encaixar','catalogFitNiche'):'<p class="lab-warning">Adicione um nicho aberto antes de encaixar.</p>')+'</div>';
   }
   out+=button('Salvar referência','catalogSaveReference')+'</div>';
  }
    out+='<div class="lab-props">'+[['x','X'],['y','Y'],['w',item.kind==='wall'?'Delta X':'Largura'],['d',item.kind==='wall'?'Delta Y':'Profundidade'],['height','Altura da peça'],['z','Altura do piso (Z)']].map(k=>'<label>'+k[1]+' (mm)<input type="number" step="1" data-lab-prop="'+k[0]+'" value="'+esc(item[k[0]]||0)+'"></label>').join('')+'</div>'+button('Salvar ajustes','properties')+button('Excluir peça','delete');
  if(item.kind==='module'||item.kind==='appliance'||item.kind==='led'||['fridge','stove','cooktop'].includes(item.kind))
   out+='<label>Rotação<select id="labRotation">'+[0,90,180,270].map(deg=>option(String(deg),deg+'°',String(item.rotation||0))).join('')+'</select></label>';
    for(const k of ['w','d','height']){const st=linkStatus(item.refs?.[k],r);if(st)out+='<p class="lab-link '+(st.includes('conferir')?'lab-warning':'')+'">'+esc(k)+' · '+esc(st)+'</p>';}
  if(globalThis.ArqueAlign&&item.kind!=='pen'&&item.kind!=='wall'&&item.kind!=='profile'){
   const targets=l.items.filter(other=>other.id!==item.id&&['countertop','module','panel','base','upper'].includes(other.kind));
   out+='<section class="lab-align-box"><h4>Alinhar e centralizar</h4><p class="lab-fine">Reposicionar sem alterar largura, profundidade ou altura.</p>';
   if(targets.length){
    const cooktop=item.kind==='cooktop'||item.type==='cooktop';
    out+='<label>Referência<select id="labAlignTarget">'+targets.map(other=>option(other.id,(other.code||'')+' '+other.label,'')).join('')+'</select></label>'+
      '<label>Posição<select id="labAlignMode">'+[['both','Centralizar X e Y'],['x','Centralizar largura'],['y','Centralizar profundidade'],['left','Encostar à esquerda'],['right','Encostar à direita'],['front','Alinhar frente'],['back','Alinhar fundo']].concat(cooktop?[['cooktop','Centralizar cooktop na bancada']]:[]).map(a=>option(a[0],a[1],cooktop?'cooktop':'both')).join('')+'</select></label>'+
      '<label>Afastamento (mm)<input id="labAlignGap" type="number" min="0" max="500" step="0.1" value="0"></label>'+button('✓ Alinhar à referência','alignTarget');
    if(item.kind==='module')out+='<label>Encaixe entre móveis<select id="labJoinMode">'+[['right','À direita · frentes alinhadas'],['left','À esquerda · frentes alinhadas'],['frontFlush','Igualar face frontal'],['front','À frente'],['back','Atrás']].map(a=>option(a[0],a[1],'right')).join('')+'</select></label>'+button('✓ Encostar módulo','alignBeside');
   }
   if(item.kind==='module')out+='<label>Parede<select id="labWallSide">'+[['back','Fundo'],['front','Frente'],['left','Esquerda · giro 90°'],['right','Direita · giro 270°']].map(a=>option(a[0],a[1],'back')).join('')+'</select></label>'+
    '<label>Folga da parede (mm)<input id="labWallGap" type="number" min="0" max="500" step="0.1" value="0"></label>'+button('✓ Encaixar na parede','alignWall');
   if(item.alignment)out+='<p class="lab-link">Referência: '+esc(item.alignment.targetId)+' · '+esc(item.alignment.mode)+'</p>';
   out+='</section>';
  }
  if(item.kind==='panel')out+='<div class="lab-profile-actions"><h4>Peça retangular para corte</h4><p class="lab-fine">Comprimento e largura usam as dimensões do desenho. Configure material, espessura e veio antes do corte.</p><label>Material<input id="labPanelMaterial" maxlength="90" value="'+esc(item.material||'MDF 18 mm')+'"></label><label>Espessura (mm)<input id="labPanelThickness" type="number" step="0.1" min="1" max="50" value="'+esc(item.thickness||18)+'"></label><label>Veio<select id="labPanelGrain"><option value="false" '+(!item.grain?'selected':'')+'>Livre</option><option value="true" '+(item.grain?'selected':'')+'>Fixo no comprimento</option></select></label>'+button('Salvar material da peça','panelMaterial')+'</div>';
  if(item.kind==='pen')out+='<div class="lab-profile-actions"><label>Nome da moldura/perfil<input id="labProfileName" placeholder="Ex.: moldura da porta" maxlength="90"></label>'+button('Salvar traço como perfil reutilizável','profileSave')+'</div>';
 }else out+='<p class="lab-fine">Selecione uma peça na planta para editar dimensões e posição com precisão.</p>';
 out+='</aside></div>';
 if(view!=='iso')out+='<section class="lab-auto-sketch"><h4>Alinhamento automático do esboço</h4><p class="lab-fine">Transforma linhas tortas em segmentos e conecta pontas próximas. Não muda registros de trena.</p><div class="lab-auto-controls"><label>Conectar a até (mm)<input id="labAutoTolerance" type="number" min="0" max="500" value="80"></label><label>Suavização (mm)<input id="labAutoSmooth" type="number" min="1" max="500" value="35"></label></div>'+button('✓ Alinhar todas as linhas','autoSketch')+((item?.kind==='pen'||item?.kind==='wall')?button('Só linha selecionada','autoSketchOne'):'')+'</section>';
 if(globalThis.ArqueWorkshop&&state){
  const savedProfiles=globalThis.ArqueWorkshop.library(state);
  out+='<section class="lab-module-panel"><h3>Perfis e molduras desenhados à mão</h3><p class="lab-fine">Desenhe com Rabisco, selecione o traço e salve como perfil. Reaproveite em outras obras, com dimensões ajustáveis em mm.</p>';
  out+='<div class="lab-module-pick"><label>Perfis salvos<select id="labProfileLibrary"><option value="">Escolha um perfil</option>'+savedProfiles.map(prof=>'<option value="'+esc(prof.id)+'">'+esc(prof.name)+' · '+fmt(prof.width)+' × '+fmt(prof.height)+' mm</option>').join('')+'</select></label>'+button('Inserir perfil','profileInsert')+'</div>';
  out+='<p class="lab-warning">Moldura livre é referência geométrica: NÃO vai automaticamente ao plano de corte/CNC. Exige fechamento do contorno, material e validação para fabricação.</p></section>';
  const audit=globalThis.ArqueWorkshop.roomAudit(l);
  out+='<div class="lab-module-panel"><h3>Conferência do ambiente</h3><p class="lab-fine">'+audit.checkedModules+' módulos verificados · '+audit.errors.length+' possíveis conflitos · '+audit.warnings.length+' pendências</p>';
  out+=audit.issues.map(i=>'<p class="'+(i.severity==='error'?'lab-warning':'lab-fine')+'">'+esc(i.message)+'</p>').join('')||'<p class="lab-link">Nenhum conflito geométrico simples detectado. Confira ferragens e condições reais.</p>';
  out+='</div>';
  const groups=globalThis.ArqueModules?.groupedCutRows(p,r.id)||{};
  if(Object.keys(groups).length)out+='<div class="lab-module-panel"><h3>Peças calculadas para corte</h3><p class="lab-fine">Escolha um lote de mesmo material e espessura. Peças avulsas retangulares e módulos são separados automaticamente.</p><label>Material<select id="labAllMaterial">'+Object.keys(groups).map(k=>'<option value="'+esc(k)+'">'+esc(k)+' · '+groups[k].reduce((acc,part)=>acc+part.qty,0)+' peças</option>').join('')+'</select></label>'+button('Enviar lote de peças para conferência','labAllCut')+'</div>';
 }
 out+=(globalThis.ArqueModuleUI&&state?globalThis.ArqueModuleUI.panel(p,state,l,selected,focusedModule===selected?focusedBay:0):'')+'</section>';return out;
}
function mount(p,ops){
 const root=document.getElementById('arqueLab');if(!root)return;
 const num=(v,f=0)=>Number.isFinite(Number(v))?Number(v):f;
  const save=()=>Promise.resolve(ops.persist()).catch(e=>ops.toast('Erro ao salvar Laboratório: '+e.message));
 const alertError=e=>ops.toast(e.message||String(e));
 const refresh=()=>{root.innerHTML=screen(p,ops.state);};
 refresh();
 root.addEventListener('change',e=>{
  try{
   if(e.target.id==='labRoom'){activeRoom=e.target.value;selected='';focusedModule='';focusedBay=0;refresh();}
   if(e.target.id==='modWorkbenchBay'){focusedBay=Number(e.target.value)||0;focusedModule=selected;refresh();}
   if(e.target.id==='labPhoto'){const l=layout(p,activeRoom);remember(l);l.photoId=e.target.value;save();refresh();}
  }catch(err){alertError(err);}
 });
 root.addEventListener('click',e=>{
  const el=e.target.closest('[data-lab]');if(!el)return;
  const a=el.dataset.lab,arg=el.dataset.arg,r=p.rooms.find(x=>x.id===activeRoom),l=layout(p,activeRoom);
  try{
   if(a==='autoSketch'||a==='autoSketchOne'){
    const A=globalThis.ArqueAlign;if(!A)throw Error('Alinhamento indisponível.');
    const result=A.automaticSketch(l,a==='autoSketchOne'?selected:'',{
     tolerance:root.querySelector('#labAutoTolerance')?.value??80,
     smoothness:root.querySelector('#labAutoSmooth')?.value??35
    },view);
    remember(l);
    for(const update of result.updates){const part=l.items.find(i=>i.id===update.id);if(part)Object.assign(part,update);}
    pointLineId='';tool='select';save();refresh();ops.toast(result.count+' linhas corrigidas; '+result.connected+' conexões.');return;
   }
   if(['alignTarget','alignBeside','alignWall'].includes(a)){
    const A=globalThis.ArqueAlign;if(!A)throw Error('Motor de alinhamento indisponível.');
    const item=l.items.find(i=>i.id===selected);if(!item)throw Error('Selecione um móvel ou eletrodoméstico.');
    const gap=root.querySelector('#labAlignGap')?.value??0;
    const result=a==='alignWall'?A.alongWall(l,selected,root.querySelector('#labWallSide')?.value,root.querySelector('#labWallGap')?.value):
     a==='alignBeside'?A.beside(l,selected,root.querySelector('#labAlignTarget')?.value,root.querySelector('#labJoinMode')?.value,gap):
     A.center(l,selected,root.querySelector('#labAlignTarget')?.value,root.querySelector('#labAlignMode')?.value,gap);
    remember(l);Object.assign(item,result);delete item.hostModuleId;
    save();refresh();ops.toast('Alinhado sem alterar medidas. Confira folgas na obra.');return;
   }
   if(a==='panelMaterial'){const item=l.items.find(x=>x.id===selected);if(item?.kind!=='panel')throw Error('Selecione uma peça retangular.');
    const material=String(root.querySelector('#labPanelMaterial')?.value||'').trim().slice(0,90),thickness=numeric(root.querySelector('#labPanelThickness')?.value,1,50);
    if(!material)throw Error('Informe o material da peça.');remember(l);item.material=material;item.thickness=thickness;item.grain=root.querySelector('#labPanelGrain')?.value==='true';save();refresh();return;}
   if(a==='labAllCut'){const key=root.querySelector('#labAllMaterial')?.value;if(!key)throw Error('Selecione um material.');ops.exportCutMaterial(r.id,key);return;}
   if(a==='profileSave'){const item=l.items.find(x=>x.id===selected),nm=root.querySelector('#labProfileName')?.value;
    const profile=globalThis.ArqueWorkshop.saveProfile(ops.state,item,nm);save();refresh();ops.toast('Moldura '+profile.name+' guardada na biblioteca geral.');return;}
   if(a==='profileInsert'){const id=root.querySelector('#labProfileLibrary')?.value,t=globalThis.ArqueWorkshop.library(ops.state).find(x=>x.id===id);
    if(!t)throw Error('Escolha uma moldura salva.');const item=globalThis.ArqueWorkshop.insertProfile(t,100,100,view);remember(l);l.items.push(item);selected=item.id;save();refresh();return;}
   if(a.startsWith('module')){if(!globalThis.ArqueModuleUI)throw Error('Módulos ainda não disponíveis.');const res=globalThis.ArqueModuleUI.act(a,{p,room:r,l,state:ops.state,selected,arg,get:id=>root.querySelector('#'+id),notify:ops.toast,onCut:ops.exportCutMaterial});if(res.handled){if(res.selected!==undefined){if(res.selected!==selected){focusedBay=0;focusedModule=res.selected;selectedPartKey='';}selected=res.selected;}if(res.focusBay!==undefined)focusedBay=res.focusBay;if(res.view)view=res.view;if(!res.skipRefresh){save();refresh();}return;}}
   if(a==='view'){view=arg;tool='select';pointLineId='';if(!l.items.some(it=>it.id===selected&&it.kind==='module'))selected='';refresh();return;}
    if(a==='visualRotate'){visualAngle=(visualAngle+Number(arg)+360)%360;refresh();return;}
    if(a==='visualZoom'){visualZoom=Math.max(.65,Math.min(2.5,Math.round((visualZoom+Number(arg))*100)/100));refresh();return;}
    if(a==='visualMode'){visualMode=arg==='structure'?'structure':'fronts';refresh();return;}
    if(a==='catalogSelect'){selected=arg;focusedModule=arg;focusedBay=0;selectedPartKey='';refresh();return;}
    if(a==='partSelect'){selectedPartKey=arg;refresh();return;}
   if(a==='catalogPreset'||a==='catalogSaved'){
    const K=globalThis.ArqueKitchen,M=globalThis.ArqueModules;
    if(!K||!M)throw Error('Biblioteca de cozinha indisponível.');
    let item;
    if(a==='catalogSaved'){
     const tpl=(ops.state.moduleTemplates||[]).find(t=>t.id===arg);
     if(!tpl)throw Error('Modelo salvo não encontrado.');
     item=M.instantiate(tpl,100,80);item.z=100;
    }else item=K.create(arg,M);
    const peers=l.items.filter(it=>it.kind==='module'&&Number(it.y)<950);
    const end=peers.length?Math.max(...peers.map(it=>Number(it.x)+Number(it.w)+40)):100;
    item.x=Math.min(end,Math.max(0,l.width-item.w));item.y=80;
    if(item.z+item.height>l.height)ops.toast('Altura ultrapassa o ambiente. Confira Z e dimensão real.');
    remember(l);l.items.push(item);ensureModuleCodes(l);
    selected=item.id;focusedModule=item.id;focusedBay=0;selectedPartKey='';tool='select';
    save();refresh();ops.toast('Inserido '+item.label+'. Edite as medidas na lateral.');
    return;
   }
   if(a==='catalogEditModule'){
    const item=l.items.find(i=>i.id===selected);
    if(item?.kind!=='module')throw Error('Selecione um armário para editar.');
    const spec={...item.moduleSpec,doorCount:Number(root.querySelector('#labQuickDoors')?.value),
     shelfCount:Number(root.querySelector('#labQuickShelves')?.value),caseMaterial:String(root.querySelector('#labQuickMaterial')?.value||'').trim(),frontMaterial:String(root.querySelector('#labQuickFrontMaterial')?.value||'').trim(),
     frontType:root.querySelector('#labQuickFront')?.value};
    globalThis.ArqueModules.parts(spec);remember(l);globalThis.ArqueModules.regenerate(item,spec);
    save();refresh();ops.toast('Módulo recalculado com peças e materiais atualizados.');return;
   }
   if(a==='catalogSaveOwn'){
    const item=l.items.find(i=>i.id===selected);
    if(item?.kind!=='module')throw Error('Selecione um módulo para salvar.');
    globalThis.ArqueModules.saveTemplate(ops.state,item.moduleSpec,item.label);
    save();refresh();ops.toast('Modelo salvo na sua biblioteca para outras obras.');return;
   }
   if(a==='catalogFitNiche'){
    const item=l.items.find(it=>it.id===selected);
    if(item?.kind!=='appliance')throw Error('Selecione um eletrodoméstico.');
    const module=l.items.find(it=>it.id===root.querySelector('#labFitNiche')?.value);
    const next=globalThis.ArqueKitchen.fitInNiche(item,module,{
     side:root.querySelector('#labFitSide')?.value,top:root.querySelector('#labFitTop')?.value,
     bottom:root.querySelector('#labFitBottom')?.value,rear:root.querySelector('#labFitRear')?.value
    },globalThis.ArqueModules);
    remember(l);Object.assign(item,next);save();refresh();
    ops.toast('Aparelho posicionado no nicho. Verificar ventilação e ficha do fabricante.');return;
   }
   if(a==='catalogSaveReference'){
    const item=l.items.find(i=>i.id===selected);
    if(!item||!['appliance','led','fridge','stove','cooktop'].includes(item.kind))throw Error('Selecione um eletrodoméstico ou LED.');
    remember(l);
    if(item.kind==='led'){item.lightColor=root.querySelector('#labLightColor')?.value||'#ffd292';item.lightOn=root.querySelector('#labLightOn')?.value==='on';}
    else item.deviceModel=String(root.querySelector('#labDeviceModel')?.value||'').trim().slice(0,90);
    save();refresh();ops.toast('Referência visual atualizada.');return;
   }
      if(a==='catalogAdd'){
     let item;
     const freeX=Math.max(80,...l.items.filter(it=>it.kind==='module'&&num(it.y,0)<900).map(it=>Number(it.x||0)+Number(it.w||0)+50));
     const x=Math.min(Math.max(50,freeX===80?100:freeX),Math.max(50,l.width-800));
     if(['base','upper','tower'].includes(arg)){
      const M=globalThis.ArqueModules;if(!M)throw Error('Motor de módulos indisponível.');
      const spec=M.standard();
      if(arg==='upper')Object.assign(spec,{name:'Aéreo 2 portas',height:700,depth:350,shelfCount:1});
      if(arg==='tower')Object.assign(spec,{name:'Torre alta',height:2000,depth:560,shelfCount:3});
      M.parts(spec);
      item=M.instantiate({id:null,version:1,spec},x,80);
      item.z=arg==='upper'?Math.max(0,l.height-950):arg==='base'?100:0;
      if(item.z+item.height>l.height)throw Error('O módulo ultrapassa a altura do ambiente. Confira as medidas.');
     }else if(['countertop','sink','stove','fridge','cooktop','led'].includes(arg)){
      item=add(l,arg,x,80,'plan');l.items.pop();l.history.pop();
     }else throw Error('Item não disponível no catálogo.');
     remember(l);l.items.push(item);selected=item.id;focusedModule=item.id;focusedBay=0;selectedPartKey='';tool='select';
     if(item.x+item.w>l.width)ops.toast('Peça incluída, mas ultrapassa a largura da parede: revise a posição.');
     save();refresh();return;
    }
    if(a==='tool'){tool=arg;pointLineId='';refresh();return;}
   if(a==='finishPointLine'){pointLineId='';tool='select';save();refresh();ops.toast('Linha finalizada.');return;}
   if(a==='snap'){gridSnap=!gridSnap;refresh();return;}
   if(a==='undo'||a==='redo'){if(a==='undo'?undo(l):redo(l)){selected='';pointLineId='';save();refresh();}return;}
   if(a==='roomSize'){
    const w=numeric(root.querySelector('#labWidth').value,100),d=numeric(root.querySelector('#labDepth').value,100),h=numeric(root.querySelector('#labHeight').value,100);
    remember(l);l.width=w;l.depth=d;l.height=h;l.confirmed=true;l.roomRefs={};save();refresh();return;
   }
   if(a==='attach'){
    const id=root.querySelector('#labMeasure').value,dest=root.querySelector('#labTarget').value;
    if(!id)throw Error('Escolha uma medição já registrada.');
    const target=dest==='itemHeight'?'height':dest;const itemId=['w','d','itemHeight'].includes(dest)?selected:null;
    if(['w','d','itemHeight'].includes(dest)&&!itemId)throw Error('Selecione uma peça no desenho antes de vincular.');
    attach(l,r,id,target,itemId);save();refresh();ops.toast('Medida vinculada à geometria, mantendo a origem.');return;
   }
   if(a==='properties'){
    const item=l.items.find(x=>x.id===selected);if(!item)throw Error('Selecione uma peça.');
    const props={label:root.querySelector('#labName').value};
    for(const input of root.querySelectorAll('[data-lab-prop]'))props[input.dataset.labProp]=numeric(input.value,(item.kind==='wall'&&['w','d'].includes(input.dataset.labProp))?-50000:0);
    const rotation=root.querySelector('#labRotation')?Number(root.querySelector('#labRotation').value):Number(item.rotation||0);
    if(![0,90,180,270].includes(rotation))throw Error('Rotação inválida.');
    if(item.kind==='module'&&globalThis.ArqueModules){const updates={width:props.w,depth:props.d,height:props.height,name:props.label};globalThis.ArqueModules.parts({...item.moduleSpec,...updates});remember(l);globalThis.ArqueModules.regenerate(item,updates);item.x=props.x;item.y=props.y;item.z=props.z;item.rotation=rotation;}else{remember(l);place(item,props);item.z=props.z;item.rotation=rotation;}
    for(const key of ['w','d','height'])delete item.refs[key];
    save();refresh();return;
   }
   if(a==='delete'){if(!selected)return;remember(l);l.items=l.items.filter(x=>x.id!==selected);selected='';save();refresh();return;}
   if(a==='export'){
    const board=root.querySelector('#labBoard');if(!board)throw Error('Nenhum desenho.');
    const blob=new Blob([board.outerHTML],{type:'image/svg+xml;charset=utf-8'}),url=URL.createObjectURL(blob),link=document.createElement('a');
    link.href=url;link.download='arque-laboratorio-'+(r?.name||'ambiente').replace(/[^a-z0-9_-]/gi,'-')+'.svg';
    document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1500);return;
   }
  }catch(err){alertError(err);}
 });
 const point=e=>{
  const board=root.querySelector('#labBoard'),box=board.getBoundingClientRect();
  const l=layout(p,activeRoom),W=l.width,H=view==='front'?l.height:l.depth;
  // The board is rendered with the exact viewBox aspect ratio (no letterboxing).
  let x=Math.max(0,Math.min(W,(e.clientX-box.left)*W/(box.width||1))),y=Math.max(0,Math.min(H,(e.clientY-box.top)*H/(box.height||1)));
  if(gridSnap&&tool!=='pen'){x=Math.round(x/5)*5;y=Math.round(y/5)*5;}
  return {x,y};
 };
 root.addEventListener('pointerdown',e=>{
  const board=e.target.closest?.('#labBoard');if(!board||e.isPrimary===false)return;
  try{
   const l=layout(p,activeRoom),hit=e.target.closest('[data-lab-object]');
   if(view==='iso'){
    const id=hit?.dataset.labObject||'';
    if(id!==selected){selectedPartKey='';selected=id;focusedModule=id;focusedBay=0;tool='select';e.preventDefault();refresh();return;}
    if(id){
     const item=l.items.find(it=>it.id===id);if(!item)return;
     drag={mode:'iso-move',id,pointer:e.pointerId,startX:e.clientX,startY:e.clientY,
      originalX:Number(item.x||0),originalY:Number(item.y||0),snapshotted:false};
     try{board.setPointerCapture(e.pointerId);}catch(_){}
    }else{selected='';refresh();}
    e.preventDefault();return;
   }
   const pt=point(e);
   if(tool==='pointline'){
    let line=pointLineId?l.items.find(i=>i.id===pointLineId&&i.kind==='pen'):null;
    if(!line){line=add(l,'pen',pt.x,pt.y,view);line.label='Linha por pontos';line.points=[[pt.x,pt.y]];pointLineId=line.id;}
    else{
     const last=line.points[line.points.length-1];
     if(Math.hypot(last[0]-pt.x,last[1]-pt.y)<3)throw Error('O novo ponto deve estar pelo menos 3 mm afastado.');
     remember(l);line.points.push([pt.x,pt.y]);
    }
    selected=line.id;e.preventDefault();save();refresh();return;
   }
   if(tool==='select'){
    if(!hit){selected='';refresh();return;}
    selected=hit.dataset.labObject;const item=l.items.find(x=>x.id===selected);
    if(!item)return;
    if(item.kind==='module'&&focusedModule!==item.id){focusedModule=item.id;focusedBay=0;}
    const tappedBay=e.target.closest('[data-lab-bay]');
    if(view==='front'&&item.kind==='module'&&tappedBay){focusedBay=Number(tappedBay.dataset.labBay)||0;e.preventDefault();refresh();return;}
    drag={mode:'move',id:item.id,start:pt,x:item.x,y:(item.kind==='module'&&view==='front'?(item.frontY??Math.max(0,l.height-item.height-100)):item.y),pointer:e.pointerId};
   }else{
    const k=tool;
    const item=add(l,k,pt.x,pt.y,view);selected=item.id;
    if(k==='pen'){item.points=[[pt.x,pt.y]];}
    else if(k==='wall'){item.w=0;item.d=0;}
    else{item.x=Math.max(0,pt.x-item.w/2);item.y=Math.max(0,pt.y-item.d/2);}
    drag=k==='pen'||k==='wall'?{mode:k,id:item.id,start:pt,pointer:e.pointerId}:null;
    tool=k==='pen'||k==='wall'?k:'select';
    if(!drag){save();refresh();return;}
    const group=document.createElementNS('http://www.w3.org/2000/svg','g');
    group.setAttribute('data-lab-object',item.id);group.innerHTML=shape(item,true);board.appendChild(group);
   }
   e.preventDefault();
   // Capture on the ORIGINAL SVG: swapping it mid-gesture loses real tablet touches.
   try{board.setPointerCapture(e.pointerId);}catch(_){}
  }catch(err){alertError(err);}
 });
 root.addEventListener('pointermove',e=>{
  if(!drag||drag.pointer!==e.pointerId)return;
  if(view==='iso'&&drag.mode==='iso-move'){
   try{
    const l=layout(p,activeRoom),item=l.items.find(it=>it.id===drag.id),board=root.querySelector('#labBoard');
    if(!item||!board)return;
    const box=board.getBoundingClientRect(),camera=globalThis.ArqueVisual.camera(l,{angle:visualAngle,zoom:visualZoom});
    const du=(e.clientX-drag.startX)*1000/(box.width||1000)/camera.scale;
    const dv=(e.clientY-drag.startY)*650/(box.height||650)/camera.scale/Math.sin(camera.elevation);
    const cos=Math.cos(camera.angle),sin=Math.sin(camera.angle);
    const dx=cos*du+sin*dv,dy=-sin*du+cos*dv;
    if(Math.abs(e.clientX-drag.startX)+Math.abs(e.clientY-drag.startY)<4)return;
    if(!drag.snapshotted){remember(l);drag.snapshotted=true;}
    const snap=x=>gridSnap?Math.round(x/5)*5:Math.round(x*10)/10;
    const rotated=Number(item.rotation||0)%180===90,fw=rotated?item.d:item.w,fd=rotated?item.w:item.d;
    item.x=snap(Math.max(0,Math.min(l.width-fw,drag.originalX+dx)));
    item.y=snap(Math.max(0,Math.min(l.depth-fd,drag.originalY+dy)));
    const group=board.querySelector('[data-lab-object="'+drag.id+'"]');
    if(group){
     const p0=camera.project(drag.originalX,drag.originalY,0),p1=camera.project(item.x,item.y,0);
     group.setAttribute('transform','translate('+(p1[0]-p0[0])+' '+(p1[1]-p0[1])+')');
    }
    e.preventDefault();
   }catch(err){alertError(err);}
   return;
  }
  try{
   const l=layout(p,activeRoom),item=l.items.find(x=>x.id===drag.id);if(!item)return;
   const pt=point(e);
   if(drag.mode==='move'){
    if(!drag.snapshotted){remember(l);drag.snapshotted=true;}
    item.x=Math.max(0,Math.min(l.width,drag.x+pt.x-drag.start.x));
    if(item.kind==='module'&&view==='front')item.frontY=Math.max(0,Math.min(l.height-item.height,drag.y+pt.y-drag.start.y));else item.y=Math.max(0,Math.min(view==='front'?l.height:l.depth,drag.y+pt.y-drag.start.y));
   }else if(drag.mode==='wall'){item.w=pt.x-drag.start.x;item.d=pt.y-drag.start.y;}
   else if(drag.mode==='pen'){item.points.push([pt.x,pt.y]);}
   // SVG geometry updates in place without interrupting the captured pointer.
   const group=root.querySelector('[data-lab-object="'+drag.id+'"]');if(group)group.innerHTML=item.kind==='module'?moduleShape(item,view,true,l):shape(item,true);
   e.preventDefault();
  }catch(err){alertError(err);}
 });
 const finish=e=>{if(!drag||drag.pointer!==e.pointerId)return;const l=layout(p,activeRoom);
  const item=l.items.find(x=>x.id===drag.id);if(item&&item.kind==='wall'&&Math.hypot(item.w,item.d)<10){l.items=l.items.filter(x=>x.id!==item.id);selected='';}
  drag=null;save();refresh();
 };
 root.addEventListener('pointerup',finish);root.addEventListener('pointercancel',finish);
}
return {layout,ensureModuleCodes,add,place,attach,linkStatus,snapshot,remember,undo,redo,svg,screen,mount};
});