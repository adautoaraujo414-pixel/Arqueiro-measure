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
  leftFiller:0,rightFiller:0,grainCase:false,grainFront:true,doorTopDiscount:0,doorBottomDiscount:0,construction:'between',accessories:[],fixedShelves:[],revision:1};
}
function check(spec){
 const s={...standard(),...clone(spec||{})};
 s.name=clean(s.name)||'Módulo sem nome';
 for(const key of ['width','height','depth'])s[key]=n(s[key],key,150);
 s.thickness=n(s.thickness,'Espessura da estrutura',6,50);
 s.backThickness=n(s.backThickness,'Espessura do fundo',0,30);
 s.doorGap=n(s.doorGap,'Folga entre portas',0,25);
 s.doorReveal=n(s.doorReveal,'Folga externa das portas',0,25);
 s.doorTopDiscount=n(s.doorTopDiscount,'Desconto adicional superior da porta',0,150);
 s.doorBottomDiscount=n(s.doorBottomDiscount,'Desconto adicional inferior da porta',0,150);
 s.shelfInset=n(s.shelfInset,'Recuo da prateleira',0,100);
 s.shelfClearance=n(s.shelfClearance,'Folga lateral da prateleira',0,15);
 s.leftFiller=n(s.leftFiller,'Tamponamento esquerdo',0,100);
 s.rightFiller=n(s.rightFiller,'Tamponamento direito',0,100);
 s.doorCount=integer(s.doorCount,'Portas',0,8);
 s.shelfCount=integer(s.shelfCount,'Prateleiras por vão',0,12);
 s.caseMaterial=clean(s.caseMaterial);s.frontMaterial=clean(s.frontMaterial);s.backMaterial=clean(s.backMaterial);
 if(!s.caseMaterial||s.doorCount&&!s.frontMaterial||s.backThickness&&!s.backMaterial)throw Error('Informe os materiais de cada parte.');
 if(!['between','over'].includes(s.construction))throw Error('Montagem da carcaça inválida.');
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
 if(s.doorCount&&s.height-2*s.doorReveal-s.doorTopDiscount-s.doorBottomDiscount<80)throw Error('Descontos superior e inferior deixam porta inviável.');
 if(!Array.isArray(s.fixedShelves)||s.fixedShelves.length>20)throw Error('Divisórias horizontais inválidas.');
 s.fixedShelves=s.fixedShelves.map((o,i)=>({bay:integer(o.bay,'Vão da divisória fixa '+(i+1),0,10),at:n(o.at,'Altura proporcional divisória '+(i+1),0.01,0.99)}));
 if(!Array.isArray(s.accessories)||s.accessories.length>20)throw Error('Acessórios internos inválidos.');
 s.accessories=s.accessories.map((o,i)=>({
  type:(o.type==='spice'?'spice':o.type==='drawer'?'drawer':(()=>{throw Error('Tipo de acessório '+(i+1)+' inválido.');})()),
  bay:integer(o.bay,'Vão do acessório '+(i+1),0,10),
  count:integer(o.count,'Quantidade de bandejas/gavetas',1,6),
  slideSide:n(o.slideSide,'Desconto lateral de cada corrediça',0,50),
  rearClearance:n(o.rearClearance,'Desconto traseiro',0,150),
  frontClearance:n(o.frontClearance,'Desconto frontal',0,150),
  height:n(o.height,'Altura da caixa ou bandeja',60,400),
  slideLength:n(o.slideLength,'Comprimento informado da corrediça',0,1000)
 }));
 // A origem desses descontos é a ferragem escolhida: não presumir 12,5 mm para qualquer modelo.

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
 panel('side','Lateral',s.construction==='over'?innerHeight:s.height,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,s.construction==='over'?'Tampo e base sobrepõem as laterais':'Laterais inteiras: tampo e base entre elas');
 panel('topbottom','Tampo / base',s.construction==='over'?s.width:innerWidth,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,s.construction==='over'?'Sobre e sob as laterais':'Entre as duas laterais');
 for(const [i,fraction] of s.vertical.entries())panel('divider-'+i,'Divisória vertical '+(i+1),innerHeight,s.depth,1,t,s.caseMaterial,s.grainCase,0,1,'Eixo em '+Math.round(1000*fraction)/10+'% do vão interno');
 for(let j=0;j<s.shelfCount;j++)for(let i=0;i<bays.length;i++){
  panel('shelf-'+j+'-'+i,'Prateleira '+(j+1)+' / vão '+(i+1),bays[i].width-2*s.shelfClearance,s.depth-s.shelfInset,1,t,s.caseMaterial,s.grainCase,0,1,'Conferir ferragens e recuo traseiro');
 }
 for(const [i,o] of s.fixedShelves.entries()){
  const bay=bays[o.bay];
  if(!bay)throw Error('Divisória fixa '+(i+1)+' aponta para um vão inexistente.');
  const heightAt=round(o.at*innerHeight);
  if(heightAt<t+30||heightAt>innerHeight-t-30)throw Error('Divisória fixa muito próxima ao tampo ou à base.');
  panel('fixed-'+i,'Divisória horizontal fixa '+(i+1)+' / vão '+(o.bay+1),bay.width-2*s.shelfClearance,s.depth-s.shelfInset,1,t,s.caseMaterial,s.grainCase,0,1,'Fixa a '+heightAt+' mm sobre o piso interno; confirmar prateleiras no mesmo vão.');
 }
 for(const [i,o] of s.accessories.entries()){
  const bay=bays[o.bay];if(!bay)throw Error('Acessório '+(i+1)+' aponta para um vão inexistente.');
  const outside=round(bay.width-2*o.slideSide),availableDepth=round(s.depth-o.frontClearance-o.rearClearance);
  if(outside<100||outside<=2*t+80)throw Error('Sem largura útil para gaveta/porta-tempero com as corrediças configuradas.');
  if(availableDepth<100)throw Error('Descontos frontal/traseiro deixam profundidade insuficiente.');
  if(o.slideLength>0&&availableDepth<o.slideLength)throw Error('Comprimento da corrediça maior que a profundidade útil disponível.');
  if(o.count*o.height+(o.count+1)*5>innerHeight)throw Error('Acessórios empilhados ultrapassam a altura útil.');
  const kind=o.type==='spice'?'Porta-temperos':'Gaveta';
  panel('acc-'+i+'-sides',kind+' · laterais',availableDepth,o.height,2*o.count,t,s.caseMaterial,false,0,0,'Comprimento da corrediça informado: '+o.slideLength+' mm; confirmar ferragem.');
  panel('acc-'+i+'-ends',kind+' · frente/traseira da caixa',outside-2*t,o.height,2*o.count,t,s.caseMaterial,false,0,0,'Largura externa '+outside+' mm = vão '+bay.width+' - 2 × '+o.slideSide+' mm.');
  panel('acc-'+i+'-bottom',kind+' · fundo',outside,availableDepth,o.count,s.backThickness||6,s.backMaterial,false,0,0,'Fundo de bandeja aplicado. Conferir modelo de montagem.');
  warnings.push(kind+' no vão '+(o.bay+1)+': conferir especificação, fixação e folga real da corrediça ('+o.slideSide+' mm/lado).');
 }
 if(s.back==='overlay'&&s.backThickness>0)panel('back','Fundo aplicado',s.width,s.height,1,s.backThickness,s.backMaterial,false,0,0,'Fundo externo: confirmar encaixe, fixação e vão disponível');
 if(s.doorCount){
  const leaf=round((s.width-2*s.doorReveal-(s.doorCount-1)*s.doorGap)/s.doorCount),height=round(s.height-2*s.doorReveal-s.doorTopDiscount-s.doorBottomDiscount);
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
 for(const item of l?.items||[]){
  if(item.kind==='module'&&item.moduleSpec){
   for(const piece of cutRows(item,room.name)){
    piece.sourceRoomId=roomId;
    const key=piece.material+' · '+piece.thickness+' mm';
    (out[key]||(out[key]=[])).push(piece);
   }
  }else if(item.kind==='panel'){
   const w=n(item.w,'Comprimento da peça avulsa',40),h=n(item.d,'Largura da peça avulsa',20);
   const thickness=n(item.thickness,'Espessura da peça avulsa',1,50);
   const material=clean(item.material);
   if(!material)throw Error('Material não informado na peça retangular '+item.label);
   const piece={id:'panel-'+item.id,sourceRoomId:roomId,sourcePanelId:item.id,sourceRoom:room.name,
    name:room.name+' · '+(clean(item.label)||'Peça avulsa'),w,h,qty:1,grain:!!item.grain,rotate:!item.grain,
    edge2:Number(item.edge2)||0,edge04:Number(item.edge04)||0,material,thickness,
    notes:'Peça retangular manual em mm: verificar ângulo, fita e corte de borda.',generated:true};
   const key=piece.material+' · '+piece.thickness+' mm';
   (out[key]||(out[key]=[])).push(piece);
  }
 }
 return out;
}
return {standard,check,bayBounds,addDivider,parts,templateLibrary,saveTemplate,instantiate,regenerate,cutRows,groupedCutRows};
});