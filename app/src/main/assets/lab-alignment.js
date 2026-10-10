/* Arque Measure: alinhamento dimensionado de módulos/eletros e correção assistida do esboço.
   Em milímetros; nunca altera as medidas originais do eletrodoméstico. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueAlign=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const r=x=>Math.round(x*10)/10;
const n=(x,name,min=0,max=50000)=>{if(x===null||x===undefined||String(x).trim()==='')throw Error(name+' obrigatório.');const v=Number(String(x).replace(',','.'));if(!Number.isFinite(v)||v<min||v>max)throw Error(name+' deve estar entre '+min+' e '+max+' mm.');return r(v);};
const dist=(a,b)=>Math.hypot(a[0]-b[0],a[1]-b[1]);
function rect(item){
 if(!item)throw Error('Selecione um objeto válido.');
 const spec=item.moduleSpec||{};
 const w=n(item.w,'Largura',0.1)+Number(spec.leftFiller||0)+Number(spec.rightFiller||0);
 const d=n(item.d,'Profundidade',0.1)+(spec.back==='overlay'?Number(spec.backThickness||0):0);
 if(![0,90,180,270].includes(Number(item.rotation||0)))throw Error('Rotação precisa ser 0°, 90°, 180° ou 270°.');
 return Number(item.rotation||0)%180===90?{w:r(d),d:r(w)}:{w:r(w),d:r(d)};
}
function validSpace(layout,item,x,y,rotation=Number(item.rotation||0)){
 const w=n(layout.width,'Parede',100),d=n(layout.depth,'Profundidade do ambiente',100);
 const box=rect({...item,rotation});
 const X=r(x),Y=r(y);
 if(X<-.05||Y<-.05||X+box.w>w+.05||Y+box.d>d+.05)throw Error('O alinhamento ultrapassa os limites do ambiente. Revise as medidas ou posição.');
 return {x:X,y:Y};
}
function center(layout,itemId,targetId,mode='both',clearance=0){
 const item=(layout.items||[]).find(i=>i.id===itemId),target=(layout.items||[]).find(i=>i.id===targetId);
 if(!item||!target||item.id===target.id)throw Error('Selecione o objeto e a bancada ou módulo de referência.');
 if(!['x','y','both','left','right','front','back','cooktop'].includes(mode))throw Error('Tipo de alinhamento inválido.');
 if(!['countertop','module','panel','base','upper'].includes(target.kind))throw Error('Alinhe em uma bancada ou móvel, não em outro eletrodoméstico.');
 if(mode==='cooktop'&&!(item.kind==='cooktop'||item.type==='cooktop'))throw Error('Selecione um cooktop para centralizar na bancada.');
 if(mode==='cooktop'&&target.kind!=='countertop')throw Error('O cooktop deve ser centralizado sobre a bancada selecionada.');
 const gap=n(clearance,'Afastamento lateral',0,500),a=rect(item),b=rect(target);
 if(a.w+2*gap>b.w+.05||a.d+2*gap>b.d+.05)
  throw Error('O aparelho/peça não cabe na superfície escolhida com o afastamento informado.');
 let x=Number(item.x)||0,y=Number(item.y)||0;
 if(['both','cooktop','x'].includes(mode))x=target.x+(b.w-a.w)/2;
 if(['both','cooktop','y'].includes(mode))y=target.y+(b.d-a.d)/2;
 if(mode==='left')x=target.x+gap;
 if(mode==='right')x=target.x+b.w-a.w-gap;
 if(mode==='back')y=target.y+gap;
 if(mode==='front')y=target.y+b.d-a.d-gap;
 if(['x','left','right'].includes(mode)&&!(y>=target.y-.05&&y+a.d<=target.y+b.d+.05))
  throw Error('A profundidade está fora da bancada. Use centralizar ambos os eixos.');
 if(['y','back','front'].includes(mode)&&!(x>=target.x-.05&&x+a.w<=target.x+b.w+.05))
  throw Error('A largura está fora da bancada. Use centralizar ambos os eixos.');
 const p=validSpace(layout,item,x,y);
 let z=Number(item.z||0);
 if(mode==='cooktop')z=r((target.z||0)+target.height);
 return {...p,z,alignment:{targetId:target.id,mode,clearance:gap},
  notice:mode==='cooktop'?'Cooktop centralizado: verificar recorte, afastamentos, sobreposição, ventilação e manual do fabricante.':
   'Posição alinhada à referência; validar folgas e interferências de montagem.'};
}
function alongWall(layout,id,wall,gap=0){
 const item=(layout.items||[]).find(x=>x.id===id);if(!item)throw Error('Selecione um móvel.');
 if(!['back','front','left','right'].includes(wall))throw Error('Parede inválida.');
 const clearance=n(gap,'Afastamento da parede',0,500);
 const rotation={back:0,right:270,front:180,left:90}[wall],b=rect({...item,rotation});
 let x=Number(item.x)||0,y=Number(item.y)||0;
 if(wall==='back')y=clearance;
 if(wall==='front')y=layout.depth-b.d-clearance;
 if(wall==='left')x=clearance;
 if(wall==='right')x=layout.width-b.w-clearance;
 return {...validSpace(layout,{...item,rotation},x,y),rotation,
  alignment:{targetId:'wall:'+wall,mode:'wall',clearance},
  notice:'Alinhado à parede '+wall+'. Confira portas, quinas e folgas de montagem.'};
}
function beside(layout,id,targetId,side,gap=0){
 const item=(layout.items||[]).find(x=>x.id===id),host=(layout.items||[]).find(x=>x.id===targetId);
 if(!item||!host||item.id===host.id)throw Error('Selecione dois módulos diferentes.');
 if(!['left','right','front','back','frontFlush'].includes(side))throw Error('Alinhamento entre módulos inválido.');
 const clearance=n(gap,'Folga entre módulos',0,500),a=rect(item),b=rect(host);
 let x=item.x,y=item.y;
 if(side==='right'){x=host.x+b.w+clearance;y=host.y+b.d-a.d;}
 if(side==='left'){x=host.x-a.w-clearance;y=host.y+b.d-a.d;}
 if(side==='front'){y=host.y+b.d+clearance;x=host.x;}
 if(side==='back'){y=host.y-a.d-clearance;x=host.x;}
 if(side==='frontFlush'){y=host.y+b.d-a.d;x=item.x;}
 return {...validSpace(layout,item,x,y),alignment:{targetId:host.id,mode:'beside:'+side,clearance},
  notice:'Módulos alinhados na planta; confira tamponamento e abertura das portas.'};
}
function reapply(layout,targetId){
 const changes=[];
 for(const item of layout.items||[]){
  if(item.alignment?.targetId!==targetId)continue;
  const mode=item.alignment.mode,gap=item.alignment.clearance||0;
  try{
   const next=mode.startsWith('beside:')?beside(layout,item.id,targetId,mode.slice(7),gap):
    mode==='wall'?null:center(layout,item.id,targetId,mode,gap);
   if(next)changes.push({id:item.id,next});
  }catch(err){throw Error('Alinhamento dependente "'+item.label+'": '+err.message);}
 }
 return changes;
}
const clonePts=points=>points.map(p=>[r(p[0]),r(p[1])]);
function simplify(points,epsilon=35){
 const list=clonePts(points).filter((p,i,a)=>i===0||dist(p,a[i-1])>=.5);
 if(list.length<=2)return list;
 const first=list[0],last=list[list.length-1],length=Math.max(.00001,dist(first,last));
 let index=-1,max=0;
 for(let i=1;i<list.length-1;i++){
  const p=list[i],v=Math.abs((last[1]-first[1])*p[0]-(last[0]-first[0])*p[1]+last[0]*first[1]-last[1]*first[0])/length;
  if(v>max){max=v;index=i;}
 }
 if(max<=epsilon||index<0)return [first,last];
 const left=simplify(list.slice(0,index+1),epsilon),right=simplify(list.slice(index),epsilon);
 return left.slice(0,-1).concat(right);
}
function orthogonal(points,threshold=90){
 if(points.length<2)throw Error('Trace pelo menos dois pontos.');
 const result=[points[0].slice()];
 for(let i=1;i<points.length;i++){
  const prev=result[result.length-1],p=points[i].slice();
  if(dist(prev,p)<3)continue;
  const dx=Math.abs(p[0]-prev[0]),dy=Math.abs(p[1]-prev[1]);
  if(dx<=threshold&&dy>=dx)p[0]=prev[0];
  else if(dy<=threshold&&dx>=dy)p[1]=prev[1];
  result.push(p);
 }
 return result.length>1?result:points;
}
function automaticSketch(layout,selectedId='',options={}){
 const tol=n(options.tolerance??80,'Tolerância para unir pontos',0,500);
 const epsilon=n(options.smoothness??35,'Correção do rabisco',1,500);
 const all=(layout.items||[]).filter(i=>(i.view==='plan'||i.view==='front')&&(i.kind==='pen'||i.kind==='wall'));
 const targets=selectedId?all.filter(i=>i.id===selectedId):all;
 if(!targets.length)throw Error('Desenhe uma linha ou rabisco no Esboço antes do alinhamento.');
 const nodes=[];
 for(const item of all){
  const pts=item.kind==='pen'?item.points||[]:[[item.x,item.y],[item.x+item.w,item.y+item.d]];
  if(pts.length<2)continue;
  nodes.push({id:item.id,kind:item.kind,points:pts});
 }
 const update=[];
 for(const it of targets){
  const raw=it.kind==='pen'?it.points||[]:[[it.x,it.y],[it.x+it.w,it.y+it.d]];
  if(raw.length<2)continue;
  let points=it.kind==='pen'?orthogonal(simplify(raw,epsilon),tol):orthogonal(clonePts(raw),tol);
  if(points.length<2||dist(points[0],points[points.length-1])<4)continue;
  update.push({id:it.id,kind:it.kind,view:it.view,points});
 }
 if(!update.length)throw Error('Não há traços suficientemente longos para alinhar.');
 // Encaixe em pontos finais de outras linhas da MESMA vista (nunca une planta com elevação).
 const byId=new Map(update.map(u=>[u.id,u]));
 const stationary=nodes.filter(n=>!byId.has(n.id));
 const endpoints=[];
 for(const it of update)for(const side of [0,1])endpoints.push({item:it,side,pt:it.points[side===0?0:it.points.length-1]});
 const external=[];
 for(const n of stationary){
  const source=(layout.items||[]).find(i=>i.id===n.id);
  if(!source)continue;
  external.push({view:source.view,pt:n.points[0]},{view:source.view,pt:n.points[n.points.length-1]});
 }
 let connected=0;
 // Conecta de forma determinística: primeiro pontos existentes, depois pontos de linhas já ajustadas.
 for(let i=0;i<endpoints.length;i++){
  const end=endpoints[i],candidates=[
   ...external.filter(x=>x.view===end.item.view),
   ...endpoints.slice(0,i).filter(x=>x.item.id!==end.item.id&&x.item.view===end.item.view)
  ];
  const nearest=candidates.map(c=>({point:c.pt,d:dist(end.pt,c.pt)})).sort((a,b)=>a.d-b.d)[0];
  if(nearest&&nearest.d<=tol&&nearest.d>.01){
   end.pt[0]=r(nearest.point[0]);end.pt[1]=r(nearest.point[1]);connected++;
  }
 }
 for(const u of update){
  if(dist(u.points[0],u.points[u.points.length-1])<4)throw Error('Uma linha ficou com comprimento menor que 4 mm após conectar pontos.');
 }
 return {updates:update.map(u=>u.kind==='wall'?{id:u.id,kind:'wall',x:r(u.points[0][0]),y:r(u.points[0][1]),
    w:r(u.points[u.points.length-1][0]-u.points[0][0]),d:r(u.points[u.points.length-1][1]-u.points[0][1])}:
    {id:u.id,kind:'pen',points:u.points}),connected,count:update.length};
}
return {rect,validSpace,center,alongWall,beside,reapply,simplify,orthogonal,automaticSketch};
});