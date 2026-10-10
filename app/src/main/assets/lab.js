/* Arque Measure | Laboratorio 2D em milimetros. Sem inferencia automatica de medidas. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueLab=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const kinds={wall:['Parede / linha',1500,0],countertop:['Bancada / pedra',1600,600],sink:['Cuba',500,400],base:['Armário base',800,560],upper:['Armário aéreo',800,350],door:['Porta',450,20],drawers:['Gaveteiro',450,560],filler:['Tamponamento',30,560],cava:['Puxador cava',450,35],outlet:['Tomada / ponto',80,80],drain:['Esgoto / água',80,80]};
const modes={plan:'Planta baixa 2D',front:'Vista frontal 2D'};
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const fmt=n=>Number(n).toLocaleString('pt-BR',{maximumFractionDigits:1});
const uid=()=>String(Date.now())+'-'+Math.random().toString(36).slice(2);
const copy=o=>JSON.parse(JSON.stringify(o));
const numeric=(value,min=0,max=50000)=>{const n=Number(String(value).replace(',','.'));if(!Number.isFinite(n)||n<min||n>max)throw Error('Medida inválida: informe um valor entre '+min+' e '+max+' mm.');return Math.round(n*10)/10;};
function layout(p,roomId){
 if(!p||!Array.isArray(p.rooms)||!p.rooms.some(r=>r.id===roomId))throw Error('Selecione um ambiente cadastrado.');
 if(!p.labLayouts||typeof p.labLayouts!=='object')p.labLayouts={};
 let l=p.labLayouts[roomId];
 if(!l)l=p.labLayouts[roomId]={width:3500,depth:2800,height:2600,confirmed:false,roomRefs:{},items:[],history:[],future:[],photoId:''};
 if(!Array.isArray(l.items))l.items=[];
 if(!Array.isArray(l.history))l.history=[];
 if(!Array.isArray(l.future))l.future=[];
 if(!l.roomRefs)l.roomRefs={};
 return l;
}
function snapshot(l){return copy({width:l.width,depth:l.depth,height:l.height,confirmed:l.confirmed,roomRefs:l.roomRefs,items:l.items,photoId:l.photoId});}
function remember(l){l.history.push(snapshot(l));if(l.history.length>25)l.history.shift();l.future=[];}
function undo(l){if(!l.history.length)return false;l.future.push(snapshot(l));Object.assign(l,l.history.pop());return true;}
function redo(l){if(!l.future.length)return false;l.history.push(snapshot(l));Object.assign(l,l.future.pop());return true;}
function add(l,kind,x,y,view='plan'){
 if(!kinds[kind]&&kind!=='pen')throw Error('Elemento desconhecido');
 if(!modes[view])throw Error('Vista desconhecida');
 const dims=kinds[kind]||['Rabisco',0,0];
 const item={id:uid(),kind,label:dims[0],x:numeric(x),y:numeric(y),w:dims[1],d:dims[2],height:kind==='base'?730:kind==='upper'?700:0,view,refs:{}};
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
 const shownH=view==='front'?H:depth;
 let res='<rect x="'+x+'" y="'+y+'" width="'+W+'" height="'+shownH+'" fill="'+(selected?'#cbe9f6':'#dfedf5')+'" stroke="'+(selected?'#117caf':'#477b95')+'" stroke-width="7" vector-effect="non-scaling-stroke"/>';
 if(view==='front'){
  res+='<path d="M '+(x+t)+' '+y+' V '+(y+H)+' M '+(x+W-t)+' '+y+' V '+(y+H)+' M '+x+' '+(y+t)+' H '+(x+W)+' M '+x+' '+(y+H-t)+' H '+(x+W)+'" stroke="#577e90" stroke-width="4" vector-effect="non-scaling-stroke" fill="none"/>';
  const inner=W-2*t;
  for(const pos of spec.vertical||[]){let cx=x+t+inner*pos;res+='<rect x="'+(cx-t/2)+'" y="'+(y+t)+'" width="'+t+'" height="'+Math.max(1,H-2*t)+'" fill="#8db9ce" stroke="#456b81" stroke-width="2"/>';}
  for(let j=1;j<=(spec.shelfCount||0);j++){let sy=y+t+(H-2*t)*j/((spec.shelfCount||0)+1);res+='<line x1="'+(x+t)+'" x2="'+(x+W-t)+'" y1="'+sy+'" y2="'+sy+'" stroke="#7194a8" stroke-width="7" vector-effect="non-scaling-stroke"/>';}
  if(spec.doorCount){for(let j=1;j<spec.doorCount;j++){let dx=x+W*j/spec.doorCount;res+='<path d="M '+dx+' '+(y+12)+' V '+(y+H-12)+'" stroke="#317ca3" stroke-width="3" stroke-dasharray="14 12"/>';}
   if(spec.frontType==='cava')res+='<path d="M '+(x+30)+' '+(y+60)+' H '+(x+W-30)+'" stroke="#0f729c" stroke-width="6" vector-effect="non-scaling-stroke"/>';}
 }else{
  res+='<line x1="'+x+'" x2="'+(x+W)+'" y1="'+(y+depth*.14)+'" y2="'+(y+depth*.14)+'" stroke="#8bb6cc" stroke-width="5" vector-effect="non-scaling-stroke"/>';
 }
 return res;
}
function svg(l,view,selectedId){
 const W=l.width||3500,H=view==='front'?(l.height||2600):(l.depth||2800);
 const ticks=Math.max(W,H)>10000?500:100;
 let a='<svg id="labBoard" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 '+W+' '+H+'" width="100%" style="aspect-ratio:'+W+'/'+H+';touch-action:none" role="img" aria-label="Ambiente em milímetros, '+esc(modes[view])+'"><defs><pattern id="labGrid" width="'+ticks+'" height="'+ticks+'" patternUnits="userSpaceOnUse"><path d="M '+ticks+' 0 L 0 0 0 '+ticks+'" fill="none" stroke="#d9e6ed" stroke-width="3"/></pattern></defs><rect width="'+W+'" height="'+H+'" fill="#fff"/><rect width="'+W+'" height="'+H+'" fill="url(#labGrid)"/><rect x="7" y="7" width="'+Math.max(1,W-14)+'" height="'+Math.max(1,H-14)+'" fill="none" stroke="#526570" stroke-width="14" vector-effect="non-scaling-stroke"/>';
 for(const item of l.items.filter(x=>x.view===view||x.kind==='module')){const sel=item.id===selectedId;
  a+='<g data-lab-object="'+esc(item.id)+'" class="'+(sel?'lab-selected':'')+'">'+(item.kind==='module'?moduleShape(item,view,sel,l):shape(item,sel))+'</g>';
  if(item.kind!=='pen'&&item.kind!=='wall')a+='<text x="'+(item.x+item.w/2)+'" y="'+Math.max(38,item.y-22)+'" font-size="'+Math.max(34,Math.min(70,W/75))+'" text-anchor="middle" fill="'+(sel?'#0c6899':'#667e89')+'" pointer-events="none">'+esc(item.label)+' · '+fmt(item.w)+' × '+fmt(item.d)+'</text>';
 }
 return a+'</svg>';
}
let activeRoom='',view='plan',tool='select',selected='',gridSnap=true,drag=null;
const option=(value,label,current)=>'<option value="'+esc(value)+'" '+(value===current?'selected':'')+'>'+esc(label)+'</option>';
const button=(label,action,arg='',active=false)=>'<button type="button" data-lab="'+action+'" data-arg="'+esc(arg)+'" class="'+(active?'lab-active':'')+'">'+label+'</button>';
function screen(p,state){
 const rooms=p.rooms||[];if(!rooms.length)return '<div class="notice">Cadastre um ambiente em Ambientes e medições para iniciar o Laboratório.</div>';
 const r=rooms.find(x=>x.id===activeRoom)||rooms[0];activeRoom=r.id;const l=layout(p,r.id);
 const photos=(p.photos||[]).filter(ph=>!ph.roomId||ph.roomId===r.id);
 const measurements=(r.measurements||[]).filter(m=>Number.isFinite(Number(m.value))&&Number(m.value)>0);
 const item=l.items.find(x=>x.id===selected);
 let out='<section class="lab"><div class="lab-heading"><div><h3>Laboratório · ambiente real em 2D</h3><small>Medidas em milímetros. Planta e vista frontal. Offline e salvo na obra.</small></div><label>Ambiente<select id="labRoom">'+rooms.map(x=>option(x.id,x.name,r.id)).join('')+'</select></label></div>';
 out+='<div class="lab-views">'+button('▱ Planta', 'view','plan',view==='plan')+button('▥ Vista frontal','view','front',view==='front')+'<span>'+fmt(l.width)+' × '+fmt(view==='front'?l.height:l.depth)+' mm'+(l.confirmed?' · informado':' · rascunho')+'</span></div>';
 out+='<div class="lab-sizes"><label>Largura da parede (mm)<input id="labWidth" type="number" min="100" max="50000" value="'+esc(l.width)+'"></label><label>Profundidade (mm)<input id="labDepth" type="number" min="100" max="50000" value="'+esc(l.depth)+'"></label><label>Altura (mm)<input id="labHeight" type="number" min="100" max="50000" value="'+esc(l.height)+'"></label>'+button('Aplicar dimensões','roomSize')+'</div>';
 if(!l.confirmed)out+='<p class="lab-warning">As dimensões exibidas são apenas um rascunho inicial. Confirme com medidas feitas na obra.</p>';
 out+='<div class="lab-actions">'+button('↶ Desfazer','undo')+button('↷ Refazer','redo')+button('▦ Grade 50 mm','snap','',gridSnap)+button('Salvar desenho SVG','export')+'</div>';
 out+='<div class="lab-main"><div class="lab-work"><div class="lab-palette">'+button('↖ Selecionar / mover','tool','select',tool==='select')+button('✎ Rabisco','tool','pen',tool==='pen')+Object.entries(kinds).map(([key,item])=>button(item[0],'tool',key,tool===key)).join('')+'</div><div class="lab-board-wrap">'+svg(l,view,selected)+'</div><div class="lab-hint">Toque para posicionar a peça. Use Selecionar para mover. Desenhe a parede arrastando. As dimensões são editadas abaixo.</div></div>';
 out+='<aside class="lab-side"><h4>Medidas salvas</h4><p>Escolha a medição real e onde aplicar, sem mudar o registro original.</p><label>Medição<select id="labMeasure">'+option('','Selecionar medida','')+measurements.map(m=>option(m.id,fmt(m.value)+' mm · '+m.kind+' · '+(m.target||'sem posição'), '')).join('')+'</select></label>';
 out+='<label>Aplicar em<select id="labTarget">'+[['width','Largura do ambiente'],['depth','Profundidade do ambiente'],['height','Altura do ambiente'],['w','Largura da peça selecionada'],['d','Profundidade da peça selecionada'],['itemHeight','Altura da peça selecionada']].map(a=>option(a[0],a[1],'')).join('')+'</select></label>'+button('Vincular medição','attach');
 for(const k of ['width','depth','height']){const status=linkStatus(l.roomRefs[k],r);if(status)out+='<p class="lab-link '+(status.includes('conferir')?'lab-warning':'')+'">'+esc(k)+' · '+esc(status)+'</p>';}
 out+='<h4>Foto de referência</h4><select id="labPhoto">'+option('','Sem fotografia',l.photoId||'')+photos.map(ph=>option(ph.id,ph.name||'Foto',l.photoId||'')).join('')+'</select>';
 const ph=photos.find(x=>x.id===l.photoId);if(ph&&typeof ph.data==='string'&&/^data:image\//.test(ph.data))out+='<img class="lab-photo" src="'+esc(ph.data)+'" alt="Foto original do ambiente">';
 out+='<p class="lab-fine">Fotos reais são referência visual, não escala automática.</p>';
 out+='<h4>Peça selecionada</h4>';
 if(item){
  out+='<div class="lab-item-title">'+esc(item.label)+' <small>'+esc(modes[item.view])+'</small></div>';
  out+='<label>Nome<input id="labName" maxlength="70" value="'+esc(item.label)+'"></label>';
  out+='<div class="lab-props">'+[['x','X'],['y','Y'],['w',item.kind==='wall'?'Delta X':'Largura'],['d',item.kind==='wall'?'Delta Y':'Profundidade'],['height','Altura da peça']].map(k=>'<label>'+k[1]+' (mm)<input type="number" step="1" data-lab-prop="'+k[0]+'" value="'+esc(item[k[0]]||0)+'"></label>').join('')+'</div>'+button('Salvar ajustes','properties')+button('Excluir peça','delete');
  for(const k of ['w','d','height']){const st=linkStatus(item.refs?.[k],r);if(st)out+='<p class="lab-link '+(st.includes('conferir')?'lab-warning':'')+'">'+esc(k)+' · '+esc(st)+'</p>';}
 }else out+='<p class="lab-fine">Selecione uma peça na planta para editar dimensões e posição com precisão.</p>';
 out+='</aside></div>'+(globalThis.ArqueModuleUI&&state?globalThis.ArqueModuleUI.panel(p,state,l,selected):'')+'</section>';return out;
}
function mount(p,ops){
 const root=document.getElementById('arqueLab');if(!root)return;
 const save=()=>Promise.resolve(ops.persist()).catch(e=>ops.toast('Erro ao salvar Laboratório: '+e.message));
 const alertError=e=>ops.toast(e.message||String(e));
 const refresh=()=>{root.innerHTML=screen(p,ops.state);};
 refresh();
 root.addEventListener('change',e=>{
  try{
   if(e.target.id==='labRoom'){activeRoom=e.target.value;selected='';refresh();}
   if(e.target.id==='labPhoto'){const l=layout(p,activeRoom);remember(l);l.photoId=e.target.value;save();refresh();}
  }catch(err){alertError(err);}
 });
 root.addEventListener('click',e=>{
  const el=e.target.closest('[data-lab]');if(!el)return;
  const a=el.dataset.lab,arg=el.dataset.arg,r=p.rooms.find(x=>x.id===activeRoom),l=layout(p,activeRoom);
  try{
   if(a.startsWith('module')){if(!globalThis.ArqueModuleUI)throw Error('Módulos ainda não disponíveis.');const res=globalThis.ArqueModuleUI.act(a,{p,room:r,l,state:ops.state,selected,arg,get:id=>root.querySelector('#'+id),notify:ops.toast,onCut:ops.exportCutMaterial});if(res.handled){if(res.selected!==undefined)selected=res.selected;if(!res.skipRefresh){save();refresh();}return;}}
   if(a==='view'){view=arg;selected='';refresh();return;}
   if(a==='tool'){tool=arg;refresh();return;}
   if(a==='snap'){gridSnap=!gridSnap;refresh();return;}
   if(a==='undo'||a==='redo'){if(a==='undo'?undo(l):redo(l)){selected='';save();refresh();}return;}
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
    if(item.kind==='module'&&globalThis.ArqueModules){const updates={width:props.w,depth:props.d,height:props.height,name:props.label};globalThis.ArqueModules.parts({...item.moduleSpec,...updates});remember(l);globalThis.ArqueModules.regenerate(item,updates);item.x=props.x;item.y=props.y;}else{remember(l);place(item,props);}
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
  if(gridSnap){x=Math.round(x/50)*50;y=Math.round(y/50)*50;}
  return {x,y};
 };
 root.addEventListener('pointerdown',e=>{
  const board=e.target.closest?.('#labBoard');if(!board||e.isPrimary===false)return;
  try{
   const l=layout(p,activeRoom),hit=e.target.closest('[data-lab-object]'),pt=point(e);
   if(tool==='select'){
    if(!hit){selected='';refresh();return;}
    selected=hit.dataset.labObject;const item=l.items.find(x=>x.id===selected);
    if(!item)return;
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
return {layout,add,place,attach,linkStatus,snapshot,remember,undo,redo,svg,screen,mount};
});