/* ARQUE Measure — Motor parametrico de marcenaria, unidades em mm.
   Dimensoes reais; nao faz corte de usinagem (cava, furo, dobradica).
   Tudo e recalculado do modelo, nunca redimensionado como imagem. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueModules=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const clone=x=>JSON.parse(JSON.stringify(x));
const uid=()=>typeof crypto!=='undefined'&&crypto.randomUUID?crypto.randomUUID():'arque-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2);
const n=(x,name,min=0,max=50000)=>{
 if(x===null||x===undefined||String(x).trim()==='')throw Error(name+' e obrigatorio.');
 const v=Number(String(x).replace(',','.'));
 if(!Number.isFinite(v)||v<min||v>max)throw Error(name+' deve estar entre '+min+' e '+max+' mm.');
 return Math.round(v*10)/10;
};
const integer=(x,name,min,max)=>{const v=Number(x);if(!Number.isInteger(v)||v<min||v>max)throw Error(name+' deve estar entre '+min+' e '+max+'.');return v;};
const round=v=>Math.round(v*10)/10;
const clean=s=>String(s||'').trim().slice(0,90);
function standard(){
 return {name:'Armário base 2 portas',width:800,height:730,depth:560,thickness:18,backThickness:6,
  caseMaterial:'MDF 18 mm',frontMaterial:'MDF 18 mm',backMaterial:'MDF 6 mm',
  construction:'between',back:'overlay',doorCount:2,doorGap:3,doorReveal:2,
  frontType:'cava',vertical:[],shelfCount:1,shelfInset:20,shelfClearance:2,
  leftFiller:0,rightFiller:0,grainCase:false,grainFront:true,revision:1};
}
function check(spec){
 const s={...standard(),...clone(spec||{})};
 s.name=clean(s.name)||'Módulo sem nome';
 for(const key of ['width','height','depth'])s[key]=n(s[key],key,150);
 s.thickness=n(s.thickness,'Espessura da estrutura',6,50);
 s.backThickness=n(s.backThickness,'Espessura do fundo',0,30);
 s.doorGap=n(s.doorGap,'Folga entre portas',0,25);
 s.doorReveal=n(s.doorReveal,'Folga externa das portas',0,25);
 s.shelfInset=n(s.shelfInset,'Recuo da prateleira',0,100);
 s.shelfClearance=n(s.shelfClearance,'Folga lateral da prateleira',0,15);
 s.leftFiller=n(s.leftFiller,'Tamponamento esquerdo',0,100);
 s.rightFiller=n(s.rightFiller,'Tamponamento direito',0,100);
 s.doorCount=integer(s.doorCount,'Portas',0,8);
 s.shelfCount=integer(s.shelfCount,'Prateleiras por vão',0,12);
 s.caseMaterial=clean(s.caseMaterial);s.frontMaterial=clean(s.frontMaterial);s.backMaterial=clean(s.backMaterial);
 if(!s.caseMaterial||s.doorCount&&!s.frontMaterial||s.backThickness&&!s.backMaterial)throw Error('Informe os materiais de cada parte.');
 if(s.construction!=='between')throw Error('Esta versão fabrica tampo e base ENTRE laterais.');
 if(!['overlay','none'].includes(s.back))throw Error('Tipo de fundo inválido.');
 if(!['cava','concha','sem'].includes(s.frontType))throw Error('Modelo de puxador inválido.');
 if(!Array.isArray(s.vertical))throw Error('Lista de divisórias inválida.');
 s.vertical=s.vertical.map((r,i)=>n(r,'Posição da divisória '+(i+1),0.001,0.999));
 s.vertical.sort((a,b)=>a-b);
 if(s.vertical.length>10)throw Error('No máximo 10 divisórias verticais.');
 if(s.width<=2*s.thickness+120)throw Error('Largura insuficiente para duas laterais e vão interno.');
 if(s.height<=2*s.thickness+100)throw Error('Altura insuficiente para tampo e base.');
 if(s.depth<=s.shelfInset+60)throw Error('Profundidade insuficiente com o recuo configurado.');
 if(s.shelfCount&&s.height-2*s.thickness-s.shelfCount*s.thickness<100*(s.shelfCount+1))throw Error('Prateleiras demais para a altura: os espaços ficam menores que 100 mm.');
 if(s.doorCount&&((s.width-2*s.doorReveal-(s.doorCount-1)*s.doorGap)/s.doorCount)<80)throw Error('Portas estreitas demais para as folgas configuradas.');
 return s;
}
function bayBounds(s){
 const inner=s.width-2*s.thickness,starts=[0],ends=[];
 for(const frac of s.vertical){
   const center=round(inner*frac),left=round(center-s.thickness/2),right=round(center+s.thickness/2);
   ends.push(left);starts.push(right);
 }
 ends.push(inner);
 const bays=starts.map((start,i)=>({start:round(start+s.thickness),end:round(ends[i]+s.thickness),width:round(ends[i]-start)}));
 for(const b of bays)if(b.width<100)throw Error('Divisórias muito próximas ou vão menor que 100 mm. Reposicione antes do corte.');
 return bays;
}
function addDivider(spec,at=0.5){const s=check(spec);s.vertical.push(n(at,'Posição proporcional',0.001,0.999));return check(s),s;}
function parts(spec){
 const s=check(spec),bays=bayBounds(s),t=s.thickness,innerWidth=round(s.width-2*t),innerHeight=round(s.height-2*t);
 const out=[],warnings=[];
 function panel(key,name,len,wid,qty,thickness,material,grain=false,edge2=0,edge04=0,notes=''){
  len=round(len);wid=round(wid);
  if(!Number.isFinite(len)||!Number.isFinite(wid)||len<40||wid<20)throw Error('Peça inviável: '+name+' ('+len+' × '+wid+' mm).');
  out.push({key,name,w:len,h:wid,qty,thickness,material,grain,rotate:!grain,edge2,edge04,notes});
 }
 panel('side','Lateral',s.height,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,'Estrutura: peças laterais inteiras');
 panel('topbottom','Tampo / base',innerWidth,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,'Entre as duas laterais');
 for(const [i,fraction] of s.vertical.entries())panel('divider-'+i,'Divisória vertical '+(i+1),innerHeight,s.depth,1,t,s.caseMaterial,s.grainCase,0,1,'Eixo em '+Math.round(1000*fraction)/10+'% do vão interno');
 for(let j=0;j<s.shelfCount;j++)for(let i=0;i<bays.length;i++){
  panel('shelf-'+j+'-'+i,'Prateleira '+(j+1)+' / vão '+(i+1),bays[i].width-2*s.shelfClearance,s.depth-s.shelfInset,1,t,s.caseMaterial,s.grainCase,0,1,'Conferir ferragens e recuo traseiro');
 }
 if(s.back==='overlay'&&s.backThickness>0)panel('back','Fundo aplicado',s.width,s.height,1,s.backThickness,s.backMaterial,false,0,0,'Fundo externo: confirmar encaixe, fixação e vão disponível');
 if(s.doorCount){
  const leaf=round((s.width-2*s.doorReveal-(s.doorCount-1)*s.doorGap)/s.doorCount),height=round(s.height-2*s.doorReveal);
  panel('front','Porta',height,leaf,s.doorCount,t,s.frontMaterial,s.grainFront,2,2,'Frente externa. Puxador '+s.frontType+'; verificar dobradiças, sobreposição e folgas.');
  if(leaf>550)warnings.push('Porta de '+leaf+' mm: conferir limite usual de largura e dobradiças.');
  if(s.frontType==='cava')warnings.push('Cava é operação de usinagem, não peça do plano de corte. Conferir régua, batente e posição da cava.');
 }
 if(s.leftFiller)panel('filler-left','Tamponamento esquerdo',s.height,s.depth,1,s.leftFiller,s.caseMaterial,s.grainCase,0,1,'Acrescenta '+s.leftFiller+' mm à largura total instalada');
 if(s.rightFiller)panel('filler-right','Tamponamento direito',s.height,s.depth,1,s.rightFiller,s.caseMaterial,s.grainCase,0,1,'Acrescenta '+s.rightFiller+' mm à largura total instalada');
 if(s.back==='overlay'&&s.backThickness)warnings.push('Fundo aplicado soma '+s.backThickness+' mm à profundidade externa. Confirme a montagem.');
 warnings.push('Lista preliminar: confirmar sentido do veio, bordas, encaixes, ferragens e cortes especiais antes da CNC.');
 return {spec:s,bays,parts:out,warnings,installedWidth:round(s.width+s.leftFiller+s.rightFiller),installedDepth:round(s.depth+(s.back==='overlay'?s.backThickness:0))};
}
function templateLibrary(state){
 if(!Array.isArray(state.moduleTemplates))state.moduleTemplates=[];
 return state.moduleTemplates;
}
function saveTemplate(state,spec,name){
 const value=check({...spec,name:name||spec?.name});
 const item={id:uid(),name:value.name,createdAt:new Date().toISOString(),version:1,spec:clone(value)};
 templateLibrary(state).push(item);return item;
}
function instantiate(template,x=100,y=100){
 if(!template||!template.spec)throw Error('Modelo inválido.');
 const s=check(template.spec);
 return {id:uid(),kind:'module',label:s.name,x:n(x,'X'),y:n(y,'Y'),w:s.width,d:s.depth,height:s.height,view:'plan',
  moduleSpec:clone(s),templateId:template.id,templateVersion:template.version,refs:{}};
}
function regenerate(item,updates){
 if(item.kind!=='module'||!item.moduleSpec)throw Error('Selecione um módulo paramétrico.');
 const candidate=check({...item.moduleSpec,...updates});
 const generated=parts(candidate);
 item.moduleSpec=clone(candidate);item.w=candidate.width;item.d=candidate.depth;item.height=candidate.height;item.label=candidate.name;
 return generated;
}
function cutRows(item,roomName){
 const generated=parts(item.moduleSpec);
 return generated.parts.map(part=>({
  id:'mod-'+item.id+'-'+part.key,sourceModuleId:item.id,modulePartKey:part.key,sourceRoom:roomName||'',
  name:(roomName?roomName+' · ':'')+item.label+' · '+part.name,w:part.w,h:part.h,qty:part.qty,
  grain:part.grain,rotate:part.rotate,edge2:part.edge2,edge04:part.edge04,
  material:part.material,thickness:part.thickness,notes:part.notes,generated:true
 }));
}
function groupedCutRows(project,roomId){
 const room=(project.rooms||[]).find(r=>r.id===roomId);if(!room)throw Error('Ambiente desconhecido.');
 const l=project.labLayouts?.[roomId],out={};
 for(const item of l?.items||[])if(item.kind==='module'&&item.moduleSpec){
  for(const piece of cutRows(item,room.name)){
   piece.sourceRoomId=roomId;
   const key=piece.material+' · '+piece.thickness+' mm';
   (out[key]||(out[key]=[])).push(piece);
  }
 }
 return out;
}
return {standard,check,bayBounds,addDivider,parts,templateLibrary,saveTemplate,instantiate,regenerate,cutRows,groupedCutRows};
});