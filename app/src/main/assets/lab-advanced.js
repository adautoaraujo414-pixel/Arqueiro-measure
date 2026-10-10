/* Oficina Arque: funções CAD independentes para seis operações controladas.
   Coordenadas sempre em mm. Sem gerar código de CNC/usinagem não verificado. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueAdvanced=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const round=v=>Math.round(v*10)/10,copy=o=>JSON.parse(JSON.stringify(o));
function mm(v,name,min=0,max=50000){if(v===null||v===undefined||String(v).trim()==='')throw Error(name+' obrigatório.');const x=Number(String(v).replace(',','.'));if(!Number.isFinite(x)||x<min||x>max)throw Error(name+' deve estar entre '+min+' e '+max+' mm.');return round(x);}
function item(layout,id,kind){const it=layout.items?.find(i=>i.id===id);if(!it||(kind&&it.kind!==kind))throw Error('Não foi encontrado o objeto solicitado.');return it;}
function dims(obj){const s=obj.moduleSpec||{},w=Number(obj.w||0)+Number(s.leftFiller||0)+Number(s.rightFiller||0),d=Number(obj.d||0)+(s.back==='overlay'?Number(s.backThickness||0):0);return Number(obj.rotation||0)%180===90?{w:round(d),d:round(w)}:{w:round(w),d:round(d)};}
function fits(layout,obj,x,y,rotation=obj.rotation||0){const b=dims({...obj,rotation});return x>=-.05&&y>=-.05&&x+b.w<=layout.width+.05&&y+b.d<=layout.depth+.05;}
function collide(a,ax,ay,b){const A=dims(a),B=dims(b),az=Number(a.z||0),bz=Number(b.z||0);return ax<b.x+B.w-.05&&b.x<ax+A.w-.05&&ay<b.y+B.d-.05&&b.y<ay+A.d-.05&&az<bz+Number(b.height||0)-.05&&bz<az+Number(a.height||0)-.05;}
function free(layout,entry,x,y,omit=[]){return fits(layout,entry,x,y)&&!(layout.items||[]).some(other=>other.id!==entry.id&&!omit.includes(other.id)&&other.kind==='module'&&entry.kind==='module'&&collide(entry,x,y,other));}
function magnetic(layout,id,proposedX,proposedY,limit=45){
 const obj=item(layout,id),threshold=mm(limit,'Tolerância do ímã',1,250),w=dims(obj);
 const x=mm(proposedX,'X',0),y=mm(proposedY,'Y',0);
 const sx=[{v:x,d:threshold+1,label:'livre'}],sy=[{v:y,d:threshold+1,label:'livre'}];
 // Preferir encaixes de bordas sem sobreposição tridimensional.
 for(const other of layout.items||[]){
  if(other.id===id||other.kind!=='module'||obj.kind!=='module')continue;
  const b=dims(other);
  for(const nx of [other.x+b.w,other.x-w.w,other.x,other.x+b.w-w.w])if(Math.abs(nx-x)<=threshold)sx.push({v:round(nx),d:Math.abs(nx-x),label:'módulo'});
  for(const ny of [other.y+b.d,other.y-w.d,other.y,other.y+b.d-w.d])if(Math.abs(ny-y)<=threshold)sy.push({v:round(ny),d:Math.abs(ny-y),label:'módulo'});
 }
 for(const nx of [0,layout.width-w.w])if(Math.abs(nx-x)<=threshold)sx.push({v:round(nx),d:Math.abs(nx-x),label:'parede'});
 for(const ny of [0,layout.depth-w.d])if(Math.abs(ny-y)<=threshold)sy.push({v:round(ny),d:Math.abs(ny-y),label:'parede'});
 sx.sort((a,b)=>a.d-b.d);sy.sort((a,b)=>a.d-b.d);
 const pair=[];
 for(const X of sx)for(const Y of sy)if(free(layout,obj,X.v,Y.v))pair.push({x:X.v,y:Y.v,score:X.d+Y.d,snapped:X.label!=='livre'||Y.label!=='livre'});
 pair.sort((a,b)=>a.score-b.score);
 const chosen=pair[0];
 if(!chosen)throw Error('Não há posição livre: objeto invade parede ou outro módulo.');
 return {x:chosen.x,y:chosen.y,snapped:chosen.snapped};
}
function kitchenCorner(layout,backId,leftId,opts={}){
 const rear=item(layout,backId,'module'),side=item(layout,leftId,'module');if(rear.id===side.id)throw Error('Selecione dois módulos diferentes.');
 const gap=mm(opts.clearance??30,'Folga no encontro',0,300);
 const wall=mm(opts.wallGap??0,'Folga da parede',0,300);
 const left={...side,rotation:90},back={...rear,rotation:0};
 const sw=dims(left),bw=dims(back);
 // Área ocupada pelo módulo da parede esquerda é reservada antes da fileira traseira.
 const leftPosition={x:wall,y:wall,rotation:90};
 const backPosition={x:round(wall+sw.w+gap),y:wall,rotation:0};
 if(!fits(layout,left,leftPosition.x,leftPosition.y,90)||!fits(layout,back,backPosition.x,backPosition.y,0))throw Error('Os dois módulos não cabem nas paredes medidas.');
 // Checar contra terceiros em volume, mas não colidir o par em construção.
 for(const [obj,pos] of [[left,leftPosition],[back,backPosition]]){
  if(!free(layout,obj,pos.x,pos.y,[rear.id,side.id]))throw Error('O encontro em L invade outro armário. Revise o espaço.');
 }
 return {changes:[{id:side.id,...leftPosition},{id:rear.id,...backPosition}],corner:{type:'L90',gap,wallGap:wall},
  note:'Canto em L posicionado. Verificar portas, rodapés, tamponamentos, abertura e pedra; NÃO gera corte angular automaticamente.'};
}
function cavaAlign(layout,originId,selectedIds,options={},engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor de módulos indisponível.');
 const source=item(layout,originId,'module'),ids=[...new Set([originId,...selectedIds])],level=mm(options.levelZ??((source.z||0)+source.height-65),'Linha da cava',0);
 const angle=mm(options.angle??30,'Ângulo de cava',5,60),railHeight=mm(options.railHeight??70,'Altura da régua',30,200),
  edge=mm(options.clearance??3,'Folga da cava',0,20);
 const changes=[];
 for(const id of ids){
  const obj=item(layout,id,'module'),s=copy(obj.moduleSpec),inside=level-Number(obj.z||0);
  if(inside<railHeight+s.thickness||inside>s.height-s.thickness-8)throw Error('Linha de cava fora da carcaça em '+obj.label+'. Confira altura instalada.');
  s.frontType='cava';
  // Posicionamento de régua físico por vão, livre de presumir fresa CNC e batente.
  if(!Array.isArray(s.assemblyPieces))s.assemblyPieces=[];
  const bays=engine.bayBounds(engine.check(s)),at=round((inside-railHeight/2-s.thickness)/(s.height-2*s.thickness)*1000000)/1000000;
  if(at<=.02||at>=.98)throw Error('Linha de cava não comporta régua com a altura cadastrada.');
  s.assemblyPieces=s.assemblyPieces.filter(p=>!(p.type==='cavaRail'&&p.alignedBy==='arque'));
  for(let bay=0;bay<bays.length;bay++){
   const rail={id:'arque-cava-'+bay,type:'cavaRail',bay,at,height:railHeight,widthClearance:edge,
    frontInset:0,rearInset:0,label:'Régua cava alinhada'};
   s.assemblyPieces.push(rail);
  }
  s.cavaProfile={levelZ:level,angle,railHeight,clearance:edge,source:originId,verified:false};
  engine.parts(s);
  changes.push({id,spec:s});
 }
 return {changes,level,note:'Régua dimensional recalculada em cada módulo. O perfil de 30° e a furação/fresagem ainda requerem usinagem validada.'};
}
function editPart(spec,partId,patch,engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor indisponível.');
 const s=engine.check(spec),index=s.assemblyPieces.findIndex(p=>p.id===partId);
 if(index<0)throw Error('Selecione uma travessa, régua ou fundo individual. Laterais estruturais devem ser editadas pelo módulo.');
 const old=s.assemblyPieces[index],v={...old};
 for(const key of ['height','at','widthClearance','frontInset','rearInset']){
  if(patch[key]===undefined)continue;
  v[key]=key==='at'?mm(patch[key],'Posição (%)',2,98)/100:mm(patch[key],key,0,key==='height'?350:150);
 }
 if(patch.label!==undefined)v.label=String(patch.label).trim().slice(0,90)||v.label;
 s.assemblyPieces[index]=v;
 engine.parts(s);
 return s;
}
function traceWalls(layout,selectedIds=[],tolerance=40){
 const tol=mm(tolerance,'Tolerância das extremidades',0,300);
 const selected=(layout.items||[]).filter(p=>p.view==='plan'&&(p.kind==='wall'||p.kind==='pen')&&(!selectedIds.length||selectedIds.includes(p.id)));
 if(!selected.length)throw Error('Desenhe paredes ou linhas por pontos na planta primeiro.');
 const segments=[];
 for(const source of selected){
  const pts=source.kind==='wall'?[[source.x,source.y],[source.x+source.w,source.y+source.d]]:source.points;
  if(!pts||pts.length<2)continue;
  for(let i=1;i<pts.length;i++){
   const a=pts[i-1],b=pts[i],dx=b[0]-a[0],dy=b[1]-a[1],len=Math.hypot(dx,dy);
   if(len<20)continue;
   if(Math.min(Math.abs(dx),Math.abs(dy))>tol)throw Error('Linha diagonal: confirme ângulo ou aplique Alinhamento automático antes de gerar paredes.');
   const p=Math.abs(dx)>Math.abs(dy)?[b[0],a[1]]:[a[0],b[1]];
   segments.push({id:source.id,start:[round(a[0]),round(a[1])],end:[round(p[0]),round(p[1])],length:round(Math.hypot(p[0]-a[0],p[1]-a[1]))});
  }
 }
 if(!segments.length)throw Error('Nenhuma parede com comprimento suficiente.');
 if(segments.some(s=>[...s.start,...s.end].some(v=>v<0||!Number.isFinite(v))||s.start[0]>layout.width||s.end[0]>layout.width||s.start[1]>layout.depth||s.end[1]>layout.depth))
  throw Error('Parede fora dos limites do ambiente.');
 let joins=0;
 for(let i=0;i<segments.length;i++)for(let j=i+1;j<segments.length;j++)
  if(Math.hypot(segments[i].end[0]-segments[j].start[0],segments[i].end[1]-segments[j].start[1])<=tol)joins++;
 return {segments,joins,sourceIds:selected.map(x=>x.id),verified:false,warning:'Paredes vetorizadas do esboço; conferir comprimentos, esquadro, portas e origem das medições.'};
}
function production(layout,engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor de módulos indisponível.');
 const lines=[],warnings=[],errors=[];
 if(!layout.confirmed)errors.push('Ambiente não confirmado por medição.');
 if(layout.wallTrace&&!layout.wallTrace.verified)warnings.push('Paredes do esboço não verificadas em obra.');
 for(const obj of layout.items||[]){
  if(obj.kind!=='module'||!obj.moduleSpec)continue;
  try{
   const output=engine.parts(obj.moduleSpec);
   if(!obj.code)errors.push('Módulo sem código: '+obj.label);
   for(let k=0;k<output.parts.length;k++){
    const p=output.parts[k],code=(obj.code||obj.id)+'-P'+String(k+1).padStart(2,'0');
    lines.push({code,module:obj.code||obj.id,name:p.name,length:p.w,width:p.h,qty:p.qty,material:p.material,thickness:p.thickness,
     grain:p.grain,edge2:p.edge2,edge04:p.edge04,notes:p.notes});
   }
   for(const warning of output.warnings||[])warnings.push((obj.code||obj.label)+': '+warning);
   if(obj.moduleSpec.frontType==='cava'&&!obj.moduleSpec.cavaProfile?.verified)warnings.push((obj.code||obj.label)+': fresagem da cava não aprovada.');
   if(obj.moduleSpec.doorCount||Object.values(obj.moduleSpec.bayDoors||{}).some(Boolean))warnings.push((obj.code||obj.label)+': conferir dobradiças, batentes e furação.');
   if(obj.moduleSpec.accessories?.length)warnings.push((obj.code||obj.label)+': confirmar referência e comprimento das corrediças.');
   if(!obj.productionApproval)warnings.push((obj.code||obj.label)+': módulo ainda não conferido e aprovado para produção.');
  }catch(err){errors.push((obj.code||obj.label)+': '+err.message);}
 }
 if(!lines.length)warnings.push('Nenhuma peça de MDF dimensionada.');
 return {lines,warnings,errors,ready:lines.length>0&&errors.length===0&&warnings.length===0,
  message:'Relatório preliminar em milímetros. Não contém furação CNC ou operação de cava pronta.'};
}
function csv(report){
 const cols=['code','module','name','length','width','qty','material','thickness','grain','edge2','edge04','notes'];
 const esc=v=>'"'+String(v??'').replace(/"/g,'""')+'"';
 return '\ufeff'+[cols.join(';'),...report.lines.map(row=>cols.map(k=>esc(row[k])).join(';'))].join('\r\n');
}
return {magnetic,kitchenCorner,cavaAlign,editPart,traceWalls,production,csv,free,dims};
});