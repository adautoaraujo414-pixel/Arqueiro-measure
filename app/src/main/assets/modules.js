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
const ratio=(value,label,min=0.001,max=0.999)=>{const v=Number(String(value).replace(',','.'));if(!Number.isFinite(v)||v<min||v>max)throw Error(label+' deve ficar entre '+min+' e '+max+'.');return Math.round(v*1000000)/1000000;};
const integer=(x,name,min,max)=>{const v=Number(x);if(!Number.isInteger(v)||v<min||v>max)throw Error(name+' deve estar entre '+min+' e '+max+'.');return v;};
const round=v=>Math.round(v*10)/10;
const clean=s=>String(s||'').trim().slice(0,90);
function standard(){
 return {name:'Armário base 2 portas',width:800,height:730,depth:560,thickness:18,backThickness:6,
  caseMaterial:'MDF 18 mm',frontMaterial:'MDF 18 mm',backMaterial:'MDF 6 mm',baseArrangement:'continuous',
  construction:'between',back:'overlay',doorCount:2,doorGap:3,doorReveal:2,
  frontType:'cava',vertical:[],bayLayoutMode:'manual',bayCount:1,bayRules:[],shelvesByBay:{},shelfCount:1,shelfInset:20,shelfRearInset:0,shelfClearance:2,dividerFrontInset:0,dividerRearInset:0,
  leftFiller:0,rightFiller:0,grainCase:false,grainFront:true,doorTopDiscount:0,doorBottomDiscount:0,construction:'between',accessories:[],fixedShelves:[],assemblyPieces:[],doorMode:'global',bayDoors:{},revision:1};
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
 s.shelfInset=n(s.shelfInset,'Recuo frontal da prateleira',0,150);
 s.shelfRearInset=n(s.shelfRearInset,'Recuo traseiro da prateleira',0,150);
 s.dividerFrontInset=n(s.dividerFrontInset,'Recuo frontal da divisória',0,150);
 s.dividerRearInset=n(s.dividerRearInset,'Recuo traseiro da divisória',0,150);
 s.shelfClearance=n(s.shelfClearance,'Folga lateral da prateleira',0,15);
 s.leftFiller=n(s.leftFiller,'Tamponamento esquerdo',0,100);
 s.rightFiller=n(s.rightFiller,'Tamponamento direito',0,100);
 s.doorCount=integer(s.doorCount,'Portas',0,8);
 s.shelfCount=integer(s.shelfCount,'Prateleiras por vão',0,12);
 s.caseMaterial=clean(s.caseMaterial);s.frontMaterial=clean(s.frontMaterial);s.backMaterial=clean(s.backMaterial);
 if(!s.caseMaterial||s.doorCount&&!s.frontMaterial||s.backThickness&&!s.backMaterial)throw Error('Informe os materiais de cada parte.');
 if(!['between','over'].includes(s.construction))throw Error('Montagem da carcaça inválida.');
 if(!['continuous','byBay'].includes(s.baseArrangement))throw Error('Modo do tampo e base inválido.');
 if(s.baseArrangement==='byBay'&&s.construction!=='between')throw Error('Bases por vão exigem tampo/base entre as laterais nesta versão.');
 if(!['overlay','none'].includes(s.back))throw Error('Tipo de fundo inválido.');
 if(!['cava','concha','sem'].includes(s.frontType))throw Error('Modelo de puxador inválido.');
 if(!['manual','equal','custom'].includes(s.bayLayoutMode))throw Error('Modo de divisão de vãos inválido.');
 if(!Array.isArray(s.bayRules))throw Error('Regras de largura inválidas.');
 if(s.bayLayoutMode==='equal'){
  s.bayCount=integer(s.bayCount,'Quantidade de vãos',1,11);
  const inner=s.width-2*s.thickness,t=s.thickness;
  if((inner-(s.bayCount-1)*t)/s.bayCount<100)throw Error('Quantidade de vãos não cabe na largura útil com MDF e divisórias.');
  const opening=(inner-(s.bayCount-1)*t)/s.bayCount;
  s.vertical=Array.from({length:s.bayCount-1},(_,j)=>Math.round((((j+1)*opening+(j+0.5)*t)/inner)*1000000)/1000000);
 }
 if(s.bayLayoutMode==='custom'){
  s.bayCount=integer(s.bayCount,'Quantidade de vãos',1,11);
  if(s.bayRules.length!==s.bayCount)throw Error('Regras de largura não correspondem à quantidade de vãos.');
  const result=allocateBayWidths(s,s.bayRules);
  s.vertical=result.centers;
 }
 if(!s.shelvesByBay||typeof s.shelvesByBay!=='object'||Array.isArray(s.shelvesByBay))throw Error('Prateleiras por vão inválidas.');
 for(const [bay,value] of Object.entries(s.shelvesByBay)){
  if(!/^\d+$/.test(bay)||Number(bay)>10)throw Error('Identificador de vão inválido.');
  s.shelvesByBay[bay]=integer(value,'Prateleiras do vão '+bay,0,12);
 }
 if(!Array.isArray(s.vertical))throw Error('Lista de divisórias inválida.');
 s.vertical=s.vertical.map((r,i)=>ratio(r,'Posição da divisória '+(i+1),0.001,0.999));
 s.vertical.sort((a,b)=>a-b);
 if(s.vertical.length>10)throw Error('No máximo 10 divisórias verticais.');
 if(s.width<=2*s.thickness+120)throw Error('Largura insuficiente para duas laterais e vão interno.');
 if(s.height<=2*s.thickness+100)throw Error('Altura insuficiente para tampo e base.');
 if(s.depth<=s.shelfInset+s.shelfRearInset+60)throw Error('Profundidade insuficiente para prateleiras com esses recuos.');
 if(s.depth<=s.dividerFrontInset+s.dividerRearInset+60)throw Error('Profundidade insuficiente para divisórias com esses recuos.');
 if(s.shelfCount&&s.height-2*s.thickness-s.shelfCount*s.thickness<100*(s.shelfCount+1))throw Error('Prateleiras demais para a altura: os espaços ficam menores que 100 mm.');
 if(s.doorCount&&((s.width-2*s.doorReveal-(s.doorCount-1)*s.doorGap)/s.doorCount)<80)throw Error('Portas estreitas demais para as folgas configuradas.');
 if(s.doorCount&&s.height-2*s.doorReveal-s.doorTopDiscount-s.doorBottomDiscount<80)throw Error('Descontos superior e inferior deixam porta inviável.');
 if(!['global','byBay'].includes(s.doorMode))throw Error('Montagem das portas inválida.');
 if(!s.bayDoors||typeof s.bayDoors!=='object'||Array.isArray(s.bayDoors))throw Error('Portas por vão inválidas.');
 for(const [key,amount] of Object.entries(s.bayDoors)){
  if(!/^(0|[1-9][0-9]*)$/.test(key)||Number(key)>10)throw Error('Vão de porta inválido.');
  s.bayDoors[key]=integer(amount,'Portas do vão '+(Number(key)+1),0,8);
 }
 if(!Array.isArray(s.fixedShelves)||s.fixedShelves.length>20)throw Error('Divisórias horizontais inválidas.');
 s.fixedShelves=s.fixedShelves.map((o,i)=>({bay:integer(o.bay,'Vão da divisória fixa '+(i+1),0,10),at:ratio(o.at,'Altura proporcional divisória '+(i+1),0.01,0.99)}));
 if(!Array.isArray(s.accessories)||s.accessories.length>20)throw Error('Acessórios internos inválidos.');
 s.accessories=s.accessories.map((o,i)=>({
  type:(o.type==='spice'?'spice':o.type==='drawer'?'drawer':(()=>{throw Error('Tipo de acessório '+(i+1)+' inválido.');})()),
  bay:integer(o.bay,'Vão do acessório '+(i+1),0,10),
  count:integer(o.count,'Quantidade de bandejas/gavetas',1,6),
  slideSide:n(o.slideSide,'Desconto lateral de cada corrediça',0.1,50),
  rearClearance:n(o.rearClearance,'Desconto traseiro',0,150),
  frontClearance:n(o.frontClearance,'Desconto frontal',0,150),
  height:n(o.height,'Altura da caixa ou bandeja',60,400),
  slideLength:n(o.slideLength,'Comprimento informado da corrediça',100,1000)
 }));
 // Peças de montagem adicionais são dimensões paramétricas, nunca um traçado em pixel.
 if(!Array.isArray(s.assemblyPieces)||s.assemblyPieces.length>50)throw Error('Excesso de peças especiais neste módulo.');
 const seen=new Set();
 s.assemblyPieces=s.assemblyPieces.map((p,i)=>{
  if(!p||typeof p!=='object')throw Error('Peça adicional inválida.');
  const id=String(p.id||'').trim();
  if(!/^[A-Za-z0-9_-]{1,90}$/.test(id)||seen.has(id))throw Error('Identificador de peça repetido ou inválido.');
  seen.add(id);
  if(!['rail','cavaRail','backPanel'].includes(p.type))throw Error('Tipo de peça especial não suportado.');
  const entry={id,type:p.type,bay:integer(p.bay,'Vão da peça adicional '+(i+1),0,10),
    at:ratio(p.at??0.5,'Posição na altura da peça',0.02,0.98),
    widthClearance:n(p.widthClearance??0,'Folga lateral da peça',0,30),
    frontInset:n(p.frontInset??0,'Recuo dianteiro da peça',0,150),
    rearInset:n(p.rearInset??0,'Recuo traseiro da peça',0,150),
    height:n(p.height??70,'Altura da travessa/régua',20,350),
    label:clean(p.label)||{rail:'Travessa',cavaRail:'Régua de cava',backPanel:'Fundo por vão'}[p.type]
  };
  return entry;
 });
 // A origem dos descontos das corrediças é a ferragem escolhida.
 return s;
}
/* Repartição exata: remove espessuras antes de distribuir as larguras livres.
   bayRules: null/'' => flexível, número => largura fixa em milímetros. */
function allocateBayWidths(spec,rules){
 const inner=round(spec.width-2*spec.thickness),t=spec.thickness;
 const count=rules.length;
 if(count<1||count>11)throw Error('Quantidade de vãos inválida.');
 const desired=rules.map((value,i)=>(value===null||value===undefined||String(value).trim()==='')?null:n(value,'Largura fixa do vão '+(i+1),100));
 const free=desired.filter(x=>x===null).length,used=desired.reduce((a,b)=>a+(b||0),0),available=round(inner-(count-1)*t-used);
 if(free===0&&Math.abs(available)>0.11)throw Error('As larguras informadas precisam somar o vão útil de '+round(inner-(count-1)*t)+' mm, descontadas as divisórias.');
 if(free>0&&available/free<100-0.0001)throw Error('Vãos flexíveis ficariam menores que 100 mm. Revise as larguras fixas.');
 const widthFlex=free?available/free:0;
 const widths=desired.map(x=>round(x===null?widthFlex:x));
 // Preservar 0,1 mm e distribuir erro de arredondamento no último flexível.
 const discrepancy=round(inner-(count-1)*t-widths.reduce((a,b)=>a+b,0));
 if(Math.abs(discrepancy)>0.0001){
  const index=desired.lastIndexOf(null);
  if(index<0)throw Error('Vãos informados não fecham na precisão de 0,1 mm.');
  widths[index]=round(widths[index]+discrepancy);
 }
 if(widths.some(x=>x<100))throw Error('Vão menor que 100 mm após dividir.');
 let position=0;const centers=[];
 for(let i=0;i<count-1;i++){position=round(position+widths[i]+t/2);centers.push(round(position/inner*1000000)/1000000);position=round(position+t/2);}
 return {widths,centers,inner,dividerCount:count-1,usable:round(inner-(count-1)*t)};
}
function validateRepartition(original,desiredCount){
 const current=bayBounds(original).length;
 if(current!==desiredCount&&(original.assemblyPieces.length||original.accessories.length||original.fixedShelves.length||
    original.doorMode==='byBay'&&Object.values(original.bayDoors).some(Boolean)))
  throw Error('Retire ou reorganize as peças internas antes de mudar a quantidade de vãos para evitar atribuição incorreta.');
}
function equalBays(spec,count){
 validateRepartition(check(spec),Number(count));
 const s=check({...spec,bayLayoutMode:'equal',bayCount:count,bayRules:[],vertical:[]});
 parts(s);return s;
}
function customBays(spec,rules){
 validateRepartition(check(spec),rules.length);
 const s=check({...spec,bayLayoutMode:'custom',bayCount:rules.length,bayRules:clone(rules),vertical:[]});
 parts(s);return s;
}
/* Editor de montagem: cada ação cria uma peça vinculada a um vão, não uma duplicata
   da estrutura preexistente. Tudo é calculado de novo ao redimensionar o módulo. */
function insertAssembly(spec,kind,bay,options={}){
 const original=check(spec),bays=bayBounds(original);
 const index=integer(bay,'Vão selecionado',0,bays.length-1);
 if(!['rail','cavaRail','backPanel'].includes(kind))throw Error('Tipo de peça não disponível.');
 if(kind==='backPanel'&&original.assemblyPieces.some(p=>p.type==='backPanel'&&p.bay===index))throw Error('Esse vão já tem um fundo segmentado.');
 const entry={id:uid(),type:kind,bay:index,at:options.at??(kind==='cavaRail'?0.9:0.5),
  height:options.height??70,widthClearance:options.widthClearance??0,
  frontInset:options.frontInset??0,rearInset:options.rearInset??0,
  label:options.label||{rail:'Travessa',cavaRail:'Régua de cava',backPanel:'Fundo por vão'}[kind]};
 let update={assemblyPieces:[...original.assemblyPieces,entry]};
 if(kind==='backPanel'&&original.back==='overlay')update.back='none';
 const s=check({...original,...update});parts(s);return s;
}
function removeAssembly(spec,id){
 const original=check(spec),items=original.assemblyPieces.filter(p=>p.id!==id);
 if(items.length===original.assemblyPieces.length)throw Error('Peça não encontrada.');
 const s=check({...original,assemblyPieces:items});parts(s);return s;
}
function setDoorsInBay(spec,bay,count){
 const original=check(spec),bays=bayBounds(original),index=integer(bay,'Vão de portas',0,bays.length-1);
 const doors={...original.bayDoors,[index]:integer(count,'Portas do vão',0,8)};
 const next=check({...original,doorMode:'byBay',bayDoors:doors});parts(next);return next;
}
function restoreGlobalDoors(spec){
 const next=check({...spec,doorMode:'global'});parts(next);return next;
}
function splitBay(spec,bay,at=0.5){
 const s=check(spec),bays=bayBounds(s),index=integer(bay,'Vão selecionado',0,bays.length-1);
 const frac=ratio(at,'Posição da nova lateral',0.1,0.9),b=bays[index],t=s.thickness;
 const newLeft=(b.width-t)*frac,newRight=(b.width-t)*(1-frac);
 if(newLeft<100||newRight<100)throw Error('A divisória deixaria um vão menor que 100 mm.');
 if(s.assemblyPieces.some(p=>p.bay===index)||s.accessories.some(p=>p.bay===index)||s.fixedShelves.some(p=>p.bay===index)||
    (s.doorMode==='byBay'&&(s.bayDoors[index]||0)>0))
  throw Error('Este vão já contém peças. Retire-as antes de dividi-lo para evitar deslocar ferragens.');
 const inner=s.width-2*t,center=b.start-t+b.width*frac+(1-frac)*t/2;
 const vertical=[...s.vertical,Math.round((center/inner)*1000000)/1000000].sort((a,b)=>a-b);
 const move=(idx)=>idx>index?idx+1:idx;
 const shelvesByBay=Object.fromEntries(Object.entries(s.shelvesByBay).map(([i,n])=>[move(Number(i)),n]));
 if(s.shelvesByBay[index]!==undefined)shelvesByBay[index+1]=s.shelvesByBay[index];
 const bayDoors=Object.fromEntries(Object.entries(s.bayDoors).map(([i,n])=>[move(Number(i)),n]));
 const fixedShelves=s.fixedShelves.map(p=>({...p,bay:move(p.bay)}));
 const accessories=s.accessories.map(p=>({...p,bay:move(p.bay)}));
 const assemblyPieces=s.assemblyPieces.map(p=>({...p,bay:move(p.bay)}));
 const next=check({...s,bayLayoutMode:'manual',bayCount:vertical.length+1,bayRules:[],vertical,shelvesByBay,bayDoors,fixedShelves,accessories,assemblyPieces});
 parts(next);return next;
}
function setBayShelves(spec,bay,count){
 const s=check(spec);const bays=bayBounds(s);
 if(!bays[bay])throw Error('Escolha um vão existente.');
 const shelvesByBay={...s.shelvesByBay,[bay]:integer(count,'Prateleiras móveis',0,12)};
 const changed=check({...s,shelvesByBay});parts(changed);return changed;
}
function equalHorizontal(spec,bay,sections){
 const s=check(spec);if(!bayBounds(s)[bay])throw Error('Escolha um vão existente.');
 const count=integer(sections,'Quantidade de espaços na altura',1,12)-1;
 const next=[...s.fixedShelves.filter(x=>x.bay!==bay),...Array.from({length:count},(_,i)=>({bay,at:(i+1)/(count+1)}))];
 const changed=check({...s,fixedShelves:next});parts(changed);return changed;
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
function addDivider(spec,at=0.5){validateRepartition(check(spec),bayBounds(check(spec)).length+1);const s=check({...spec,bayLayoutMode:'manual',bayRules:[]});s.vertical.push(ratio(at,'Posição proporcional',0.001,0.999));const changed=check(s);parts(changed);return changed;}
function parts(spec){
 const s=check(spec),bays=bayBounds(s),t=s.thickness,innerWidth=round(s.width-2*t),innerHeight=round(s.height-2*t);
 const out=[],warnings=[];
 function panel(key,name,len,wid,qty,thickness,material,grain=false,edge2=0,edge04=0,notes=''){
  len=round(len);wid=round(wid);
  if(!Number.isFinite(len)||!Number.isFinite(wid)||len<40||wid<20)throw Error('Peça inviável: '+name+' ('+len+' × '+wid+' mm).');
  out.push({key,name,w:len,h:wid,qty,thickness,material,grain,rotate:!grain,edge2,edge04,notes});
 }
 panel('side','Lateral',s.construction==='over'?innerHeight:s.height,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,s.construction==='over'?'Tampo e base sobrepõem as laterais':'Laterais inteiras: tampo e base entre elas');
 if(s.baseArrangement==='byBay'){
  for(const [i,b] of bays.entries())panel('topbottom-bay-'+i,'Tampo/base vão '+(i+1),b.width,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,'Tampo e base segmentados entre laterais e divisórias, não são peças contínuas.');
 }else{
  panel('topbottom','Tampo / base',s.construction==='over'?s.width:innerWidth,s.depth,2,t,s.caseMaterial,s.grainCase,0,1,s.construction==='over'?'Sobre e sob as laterais':'Entre as duas laterais');
 }
 for(const [i,fraction] of s.vertical.entries())panel('divider-'+i,'Divisória vertical '+(i+1),innerHeight,s.depth-s.dividerFrontInset-s.dividerRearInset,1,t,s.caseMaterial,s.grainCase,0,1,'Eixo em '+Math.round(1000*fraction)/10+'% do vão interno');
 for(let i=0;i<bays.length;i++)for(let j=0;j<(s.shelvesByBay[i]??s.shelfCount);j++){
  const count=s.shelvesByBay[i]??s.shelfCount;
  const at=(j+1)/(count+1);
  // Se uma prateleira fixa ocupa exatamente o mesmo plano, gerar apenas a peça fixa.
  if(s.fixedShelves.some(f=>f.bay===i&&Math.abs(f.at-at)*innerHeight<t))continue;
  panel('shelf-'+j+'-'+i,'Prateleira '+(j+1)+' / vão '+(i+1),bays[i].width-2*s.shelfClearance,s.depth-s.shelfInset-s.shelfRearInset,1,t,s.caseMaterial,s.grainCase,0,1,'Conferir ferragens e recuo traseiro');
 }
 for(let i=0;i<s.fixedShelves.length;i++)for(let j=i+1;j<s.fixedShelves.length;j++){
  const a=s.fixedShelves[i],b=s.fixedShelves[j];
  if(a.bay===b.bay&&Math.abs(a.at-b.at)*innerHeight<t+5)throw Error('Divisórias horizontais sobrepostas no mesmo vão.');
 }
 for(const entry of s.assemblyPieces){
  const bay=bays[entry.bay];if(!bay)throw Error('Peça '+entry.label+' aponta para vão inexistente.');
  if(entry.type==='backPanel'){
   if(s.back==='overlay')throw Error('Não coloque fundo individual sobre fundo inteiro. Escolha fundo segmentado.');
   const usable=round(bay.width-2*entry.widthClearance);
   if(s.backThickness<=0)throw Error('Fundo segmentado exige espessura de fundo cadastrada.');
   panel('extra-'+entry.id,'Fundo individual / vão '+(entry.bay+1),innerHeight,usable,1,s.backThickness,s.backMaterial,false,0,0,
    'Fundo interior por vão, montagem e fixação precisam de conferência.');
  }else{
   const usable=round(bay.width-2*entry.widthClearance);
   const depth=round(s.depth-entry.frontInset-entry.rearInset);
   const axial=round(entry.at*innerHeight);
   if(usable<40||depth<20)throw Error('Dimensões inviáveis para '+entry.label+'.');
   if(axial-entry.height/2<0||axial+entry.height/2>innerHeight)throw Error(entry.label+' invade tampo ou base; altere altura/posição.');
   panel('extra-'+entry.id,entry.label+' / vão '+(entry.bay+1),usable,entry.height,1,t,s.caseMaterial,s.grainCase,0,1,
    'Fixação no vão; altura do painel '+entry.height+' mm, profundidade de instalação disponível '+depth+' mm'+(entry.type==='cavaRail'?'; USINAGEM da cava deve ser programada separadamente':'')+'.');
   if(entry.type==='cavaRail')warnings.push('Régua de cava: recorte/perfil não foi gerado automaticamente; definir fresagem, batente e folgas na produção.');
  }
 }
 for(const [i,o] of s.fixedShelves.entries()){
  const bay=bays[o.bay];
  if(!bay)throw Error('Divisória fixa '+(i+1)+' aponta para um vão inexistente.');
  const heightAt=round(o.at*innerHeight);
  if(heightAt<t+30||heightAt>innerHeight-t-30)throw Error('Divisória fixa muito próxima ao tampo ou à base.');
  panel('fixed-'+i,'Divisória horizontal fixa '+(i+1)+' / vão '+(o.bay+1),bay.width-2*s.shelfClearance,s.depth-s.shelfInset-s.shelfRearInset,1,t,s.caseMaterial,s.grainCase,0,1,'Fixa a '+heightAt+' mm sobre o piso interno; confirmar prateleiras no mesmo vão.');
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
 if(s.doorMode==='byBay'){
  if(Object.entries(s.bayDoors).some(([key,qty])=>qty>0&&!bays[Number(key)]))throw Error('Portas vinculadas a vão inexistente: confira a nova divisão.');
  if(Object.values(s.bayDoors).some(qty=>qty>0)&&!s.frontMaterial)throw Error('Material das portas não informado.');
  if(s.doorCount>0)warnings.push('Portas por vão ativadas: as '+s.doorCount+' portas globais foram substituídas nesta instância, sem duplicação.');
  for(const [idx,bay] of bays.entries()){
   const qty=s.bayDoors[idx]||0;if(!qty)continue;
   const h=round(s.height-2*s.doorReveal-s.doorTopDiscount-s.doorBottomDiscount);
   const leaf=round((bay.width-2*s.doorReveal-(qty-1)*s.doorGap)/qty);
   if(leaf<80||h<80)throw Error('Portas do vão '+(idx+1)+' não cabem com as folgas configuradas.');
   panel('bay-door-'+idx,'Porta do vão '+(idx+1),h,leaf,qty,t,s.frontMaterial,s.grainFront,2,2,'Frente dimensionada pelo vão livre; revisar recobrimento, dobradiças, sentido e posição de cava.');
   if(leaf>550)warnings.push('Porta do vão '+(idx+1)+' excede 550 mm de largura; revisar dobradiças e estabilidade.');
   if(s.frontType==='cava')warnings.push('Porta do vão '+(idx+1)+': usinagem da cava requer desenho e conferência separados.');
  }
 }
 if(s.doorMode==='global'&&s.doorCount){
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
return {standard,check,bayBounds,allocateBayWidths,equalBays,customBays,setBayShelves,equalHorizontal,addDivider,insertAssembly,removeAssembly,setDoorsInBay,restoreGlobalDoors,splitBay,parts,templateLibrary,saveTemplate,instantiate,regenerate,cutRows,groupedCutRows};
});