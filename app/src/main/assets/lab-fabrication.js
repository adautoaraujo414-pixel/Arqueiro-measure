/* Arque Measure — referências de ferragens e canto 45°, sem gerar usinagem CNC.
   Os desenhos são prévias dimensionais; fabricante deve fornecer furação, profundidade e folgas. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueFabrication=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const round=x=>Math.round(x*10)/10,copy=x=>JSON.parse(JSON.stringify(x));
function number(value,name,min=0,max=100000){
 if(value===null||value===undefined||String(value).trim()==='')throw Error(name+' obrigatório.');
 const v=Number(String(value).replace(',','.'));
 if(!Number.isFinite(v)||v<min||v>max)throw Error(name+' deve ficar entre '+min+' e '+max+'.');
 return round(v);
}
function module(layout,id){const obj=(layout.items||[]).find(i=>i.id===id);if(obj?.kind!=='module')throw Error('Selecione um módulo existente.');return obj;}
function dimensions(obj){
 const s=obj.moduleSpec||{},w=Number(obj.w)+Number(s.leftFiller||0)+Number(s.rightFiller||0);
 const d=Number(obj.d)+(s.back==='overlay'?Number(s.backThickness||0):0);
 return Number(obj.rotation||0)%180===90?{w:round(d),d:round(w)}:{w:round(w),d:round(d)};
}
function create45(layout,backId,sideId,options={}){
 const back=module(layout,backId),side=module(layout,sideId);if(side.id===back.id)throw Error('Escolha módulos diferentes para o canto.');
 if(Number(back.rotation||0)!==0||Number(side.rotation||0)!==90)
  throw Error('Primeiro monte o canto em L: módulo do fundo em 0° e o lateral em 90°.');
 const reach=number(options.reach??400,'Avanço do canto',150,1200),clearance=number(options.clearance??15,'Folga da frente diagonal',0,150);
 const backD=dimensions(back),sideD=dimensions(side);
 // Referência geométrica no encontro das faces frontais dos dois módulos.
 const x=round(side.x+sideD.w+clearance),y=round(back.y+backD.d+clearance);
 const a=[x,round(y+reach)],b=[round(x+reach),y],len=round(Math.hypot(reach,reach));
 if(a[0]<0||a[1]>layout.depth||b[0]>layout.width||b[1]<0)throw Error('Frente diagonal ultrapassa as medidas do ambiente.');
 // Ao cruzar o polígono de ocupação de outro módulo a frente não deve ser oferecida como válida.
 for(const it of layout.items||[]){
  if(it.kind!=='module'||it.id===back.id||it.id===side.id)continue;
  const D=dimensions(it);
  const xmin=it.x,xmax=it.x+D.w,ymin=it.y,ymax=it.y+D.d;
  // Teste suficiente de interseção segmento-caixa, não apenas extremos.
  if(segmentRect(a,b,xmin,ymin,xmax,ymax))throw Error('A frente diagonal atravessa o móvel '+(it.code||it.label)+'.');
 }
 return {id:'corner45-'+back.id+'-'+side.id,backId:back.id,sideId:side.id,start:a,end:b,
  reach,clearance,angle:45,diagonalLength:len,verified:false,
  note:'Guia de frente em 45°. Não dimensiona carcaça trapezoidal, portas, dobradiças, recortes ou corte CNC.'};
}
function segmentRect(a,b,xmin,ymin,xmax,ymax){
 if((a[0]>=xmin&&a[0]<=xmax&&a[1]>=ymin&&a[1]<=ymax)||(b[0]>=xmin&&b[0]<=xmax&&b[1]>=ymin&&b[1]<=ymax))return true;
 let t0=0,t1=1;const dx=b[0]-a[0],dy=b[1]-a[1];
 for(const [p,q] of [[-dx,a[0]-xmin],[dx,xmax-a[0]],[-dy,a[1]-ymin],[dy,ymax-a[1]]]){
  if(!p){if(q<0)return false;continue;}
  const r=q/p;
  if(p<0){if(r>t1)return false;t0=Math.max(t0,r);}
  else{if(r<t0)return false;t1=Math.min(t1,r);}
 }
 return t0<=t1;
}
function hingePlan(moduleItem,values={},engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor de peças indisponível.');
 if(moduleItem?.kind!=='module')throw Error('Selecione um módulo.');
 const s=engine.check(moduleItem.moduleSpec);
 if(s.corner45?.enabled)throw Error('Porta diagonal 45° exige ferragem e gabarito próprios. Plano de canecas retas não se aplica.');
 const parts=engine.parts(s).parts,doors=parts.filter(p=>p.key==='front'||p.key.startsWith('bay-door-'));
 if(!doors.length)throw Error('O módulo não possui portas para configurar dobradiças.');
 const diameter=number(values.diameter??35,'Diâmetro da caneca',10,45),edgeDistance=number(values.edgeDistance??22,'Centro à borda',10,90);
 const top=number(values.top??100,'Distância do topo',40,250),bottom=number(values.bottom??100,'Distância da base',40,250);
 const perDoor=number(values.count??2,'Dobradiças por porta',2,6);
 if(perDoor%1!==0)throw Error('Quantidade de dobradiças deve ser inteira.');
 const brand=String(values.brand||'Não informado').trim().slice(0,90),model=String(values.model||'Não informado').trim().slice(0,90);
 const holes=[];
 for(const p of doors){
  const doorHeight=Math.max(p.w,p.h),doorWidth=Math.min(p.w,p.h);
  if(doorHeight<=top+bottom+diameter||doorWidth<=2*(edgeDistance+diameter/2))throw Error('Porta '+p.name+' não comporta as distâncias e diâmetro cadastrados.');
  for(let leaf=0;leaf<p.qty;leaf++){
   const key=(moduleItem.code||'M')+'-'+p.key+'-'+String(leaf+1);
   for(let i=0;i<perDoor;i++){
    const y=round(top+(doorHeight-top-bottom)*i/(perDoor-1));
    holes.push({door:key,side:leaf%2===0?'esquerda':'direita',x:edgeDistance,y,diameter});
   }
  }
 }
 const signature=JSON.stringify({width:s.width,height:s.height,depth:s.depth,doorCount:s.doorCount,doorMode:s.doorMode,bayDoors:s.bayDoors,
  doorGap:s.doorGap,doorReveal:s.doorReveal,doorTopDiscount:s.doorTopDiscount,doorBottomDiscount:s.doorBottomDiscount,thickness:s.thickness});
 return {brand,model,diameter,edgeDistance,top,bottom,perDoor,doorLeaves:doors.reduce((sum,p)=>sum+p.qty,0),
  holes,signature,verified:false,
  note:'Posições de caneca apenas para conferência. Sentido de abertura, fixação na lateral, profundidade de furação e montagem devem seguir ferragem real.'};
}
function hingesStale(moduleItem,plan,engine=globalThis.ArqueModules){
 if(!plan)return true;
 try{return hingePlan(moduleItem,plan,engine).signature!==plan.signature;}catch(_){return true;}
}
function slidesPlan(moduleItem,values={},engine=globalThis.ArqueModules){
 if(moduleItem?.kind!=='module')throw Error('Selecione um módulo.');
 const spec=engine.check(moduleItem.moduleSpec);
 const side=number(values.side??12.7,'Folga lateral por corrediça',1,40),
  length=number(values.length??400,'Comprimento da corrediça',100,1000),
  front=number(values.front??20,'Desconto frontal',0,150),rear=number(values.rear??20,'Desconto traseiro',0,150);
 const brand=String(values.brand||'Não informado').trim().slice(0,90),model=String(values.model||'Não informado').trim().slice(0,90);
 const accessories=spec.accessories.filter(x=>x.type==='drawer'||x.type==='spice');
 if(!accessories.length)throw Error('Adicione gavetas ou porta-temperos ao módulo antes de dimensionar corrediças.');
 const next=copy(spec);
 for(const acc of next.accessories){acc.slideSide=side;acc.slideLength=length;acc.frontClearance=front;acc.rearClearance=rear;}
 engine.parts(next);
 return {spec:next,configuration:{brand,model,side,length,front,rear,drawerCount:accessories.reduce((a,x)=>a+x.count,0),verified:false,
   note:'Dimensões de corrediças informadas pelo usuário; validar modelo, folgas, fixações e curso real antes da produção.'}};
}
function hardwareWarnings(moduleItem,engine=globalThis.ArqueModules){
 if(moduleItem?.kind!=='module')return [];
 const s=engine.check(moduleItem.moduleSpec),out=[];
 if(s.corner45?.enabled)return ['Dobradica e furação de porta diagonal 45° requerem gabarito do fabricante, teste de abertura e aprovação física.'];
 const doors=s.doorMode==='global'?s.doorCount:Object.values(s.bayDoors).reduce((a,b)=>a+b,0);
 if(doors){
  if(!moduleItem.hingePlan)out.push('Falta plano de dobradiças.');
  else{
   if(hingesStale(moduleItem,moduleItem.hingePlan,engine))out.push('Plano de dobradiças desatualizado após alteração das frentes.');
   if(!moduleItem.hingePlan.verified)out.push('Furação de caneca e montagem das dobradiças não conferidas.');
  }
 }
 if(s.accessories.length){
  if(!moduleItem.slideConfiguration)out.push('Falta modelo de corrediça confirmado.');
  else if(!moduleItem.slideConfiguration.verified)out.push('Dimensões das corrediças ainda não conferidas.');
 }
 return out;
}
function hardwareCsv(objects){
 const rows=[['Modulo','Porta','Lado','X mm','Y mm','Diametro mm','Marca','Modelo','Conferido']];
 for(const item of objects||[]){
  if(!item.hingePlan)continue;
  const h=item.hingePlan;
  for(const p of h.holes)rows.push([item.code||item.id,p.door,p.side,p.x,p.y,p.diameter,h.brand,h.model,'NÃO']);
 }
 const csvRow=r=>r.map(v=>'"'+String(v).replace(/"/g,'""')+'"').join(';');
 return '\ufeff'+rows.map(csvRow).join('\r\n');
}
return {create45,segmentRect,hingePlan,hingesStale,slidesPlan,hardwareWarnings,hardwareCsv};
});