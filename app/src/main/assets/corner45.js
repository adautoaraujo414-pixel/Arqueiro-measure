/* Módulo Arque canto 45° de cinco lados.
   Polígonos verdadeiros em mm e chapas retangulares separadas.
   Nenhum contorno angular segue como peça retangular para a serra/CNC. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueCorner45=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const round=n=>Math.round(n*10)/10;
const num=(v,name,min,max)=>{if(v===undefined||v===null||String(v).trim()==='')throw Error(name+' obrigatório.');const n=Number(String(v).replace(',','.'));if(!Number.isFinite(n)||n<min||n>max)throw Error(name+' deve estar entre '+min+' e '+max+' mm.');return round(n);};
function validate(s){
 if(!s.corner45||s.corner45.enabled!==true)throw Error('Configuração do módulo de canto ausente.');
 const t=Number(s.thickness),w=Number(s.width),d=Number(s.depth),h=Number(s.height);
 const chamfer=num(s.corner45.chamfer??380,'Chanfro do canto',150,Math.min(w,d)-3*t);
 const shelves=num(s.corner45.shelves??0,'Prateleiras do canto',0,6);
 if(!Number.isInteger(shelves))throw Error('Prateleiras devem ser inteiras.');
 if(s.doorCount>1||s.doorMode!=='global')throw Error('Módulo de canto utiliza uma frente diagonal ou nicho aberto.');
 if(s.vertical.length||s.assemblyPieces.length||s.fixedShelves.length||s.accessories.length||
    Object.keys(s.bayDoors).length||Object.keys(s.shelvesByBay).length||s.shelfCount)
  throw Error('Divisórias retas, gavetas e acessórios comuns não se aplicam ao canto 45°. Use somente prateleiras poligonais do canto.');
 if(s.construction!=='between'||s.baseArrangement!=='continuous')throw Error('Canto 45° usa a montagem específica entre as estruturas.');
 if(s.back!=='none')throw Error('Canto 45° não admite fundo aplicado contínuo: projete o fundo angular separadamente.');
 const doorReveal=num(s.doorReveal,'Folga da frente',0,25);
 const diagonal=round(chamfer*Math.SQRT2),doorWidth=round(diagonal-2*doorReveal);
 if(doorWidth<160)throw Error('A frente diagonal não oferece largura útil para porta.');
 const insetOffset=round(t*(Math.SQRT2-1));
 if(chamfer<=3*t||d-chamfer-insetOffset<2*t||w-chamfer-insetOffset<2*t)
  throw Error('Chanfro incompatível com espessura das peças estruturais.');
 if(shelves&&(h-2*t-(shelves*t))/(shelves+1)<120)throw Error('Prateleiras deixam altura livre inferior a 120 mm.');
 return {enabled:true,chamfer,shelves,doorWidth,diagonal};
}
function geometry(spec){
 const s={...spec,corner45:{...spec.corner45}},c=validate(s),t=Number(s.thickness),w=Number(s.width),d=Number(s.depth),k=t*(Math.SQRT2-1);
 const outline=[[0,0],[w,0],[w,d-c.chamfer],[w-c.chamfer,d],[0,d]];
 const inner=[[t,t],[w-t,t],[w-t,d-c.chamfer-k],[w-c.chamfer-k,d-t],[t,d-t]];
 const norm=points=>points.map(([x,y])=>[round(x),round(y)]);
 const diagStart=[w,d-c.chamfer],diagEnd=[w-c.chamfer,d];
 const area=round(w*d-c.chamfer*c.chamfer/2);
 return {outline:norm(outline),inner:norm(inner),diagonal:[diagStart,diagEnd],diagonalLength:c.diagonal,
  doorWidth:c.doorWidth,chamfer:c.chamfer,area,shelves:c.shelves,
  contourBounding:{w:round(w-2*t),d:round(d-2*t)},thickness:t,
  footprint:{w,d},volume:{w,d,h:s.height},angle:45};
}
function parts(s){
 const g=geometry(s),t=s.thickness,H=s.height,W=s.width,D=s.depth,C=g.chamfer;
 const out=[],warnings=[];
 const item=(key,name,w,h,qty,thickness,material,{shape='rect',outline=null,notes='',grain=false,edge2=0,edge04=0,cutStatus='review'}={})=>{
  w=round(w);h=round(h);
  if(w<40||h<20)throw Error('Peça inviável: '+name+' ('+w+' × '+h+' mm).');
  out.push({key,name,w,h,qty,thickness,material,grain,rotate:!grain,edge2,edge04,notes,shape,outline,cutStatus,needsContour:shape==='polygon'});
 };
 // Estruturas verticais retangulares: indicação da junta continua pendente.
 item('corner-left','Lateral esquerda inteira',H,D,1,t,s.caseMaterial,{edge04:1,notes:'Encontro da parede e junta com travessa traseira: conferir montagem. Comprimento externo.'});
 item('corner-right','Lateral direita até início do chanfro',H,D-C,1,t,s.caseMaterial,{edge04:1,notes:'Aresta terminal junto à porta 45° exige plano de junta e apoio de dobradiça.'});
 item('corner-back','Travessa/fechamento traseiro',W-2*t,H-2*t,1,t,s.caseMaterial,{notes:'Entre as laterais; posição de fixação e interferência com base devem ser conferidas.'});
 item('corner-return','Retorno frontal esquerdo',W-C-t,H,1,t,s.caseMaterial,{notes:'Reto até o início da diagonal. Testar junta e acessibilidade à porta.'});
 const shifted=g.inner.map(p=>[round(p[0]-t),round(p[1]-t)]);
 item('corner-deck','Tampo e base pentagonais',W-2*t,D-2*t,2,t,s.caseMaterial,{shape:'polygon',outline:shifted,
  notes:'POLÍGONO pentagonal com chanfro a 45°. W×D são somente limites da chapa; não inserir na otimização retangular/CNC.'});
 for(let i=0;i<g.shelves;i++)item('corner-shelf-'+i,'Prateleira pentagonal '+(i+1),W-2*t,D-2*t,1,t,s.caseMaterial,{shape:'polygon',outline:shifted,
  notes:'Contorno pentagonal com recuo interno. Validar ferragens de suporte e sentido do veio.'});
 if(s.doorCount){
  const height=round(H-2*s.doorReveal-s.doorTopDiscount-s.doorBottomDiscount);
  if(height<120)throw Error('Altura da porta diagonal insuficiente.');
  item('corner-front','Porta diagonal de canto 45°',height,g.doorWidth,1,t,s.frontMaterial,{grain:s.grainFront,edge2:2,edge04:2,
   notes:'Porta retangular apoiada em plano diagonal. Dobradiça de canto, recobrimento, cava e sentido de abertura dependem da ferragem.'});
  if(g.doorWidth>550)warnings.push('Porta diagonal '+g.doorWidth+' mm excede referência de 550 mm; escolha reforço ou altere chanfro.');
 }
 if(s.leftFiller)item('corner-filler-left','Tamponamento da parede esquerda',H,D,1,s.leftFiller,s.caseMaterial,{notes:'Revisar se o engrosso entra na projeção do ambiente.'});
 if(s.rightFiller)item('corner-filler-right','Tamponamento da parede direita',H,D-C,1,s.rightFiller,s.caseMaterial,{notes:'Revisar junta com retorno da porta diagonal.'});
 warnings.push('CANTO 45°: validar juntas, lado de abertura, prumadas, furação de dobradiça e fixação das estruturas com montagem física.');
 warnings.push('TAMPO/BASE/PRATELEIRAS PENTAGONAIS: somente contornos dimensionados, sem programação de serra angular ou CNC.');
 if(s.frontType==='cava')warnings.push('Puxador cava da porta diagonal exige perfil e usinagem específicos não fornecidos.');
 return {spec:s,bays:[],parts:out,warnings,geometry:g,installedWidth:round(W+s.leftFiller+s.rightFiller),
  installedDepth:round(D),nonRectangular:true};
}
function create(engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor paramétrico indisponível.');
 const s=engine.standard();
 Object.assign(s,{name:'Canto 45° · cinco lados',width:800,depth:800,height:730,doorCount:1,frontType:'sem',shelfCount:0,
  back:'none',construction:'between',baseArrangement:'continuous',corner45:{enabled:true,chamfer:380,shelves:0}});
 engine.parts(s);
 const item=engine.instantiate({id:'arque-corner45',version:1,spec:s},100,100);
 item.z=100;item.presetId='corner45-pentagon';item.productionApproval=false;
 return item;
}
function update(spec,changes={},engine=globalThis.ArqueModules){
 if(!engine)throw Error('Motor paramétrico indisponível.');
 const s=engine.check({...spec,corner45:{...spec.corner45,...changes}});
 engine.parts(s);return s;
}
function svgTechnical(spec){
 const g=geometry(spec),s=spec,scale=360/Math.max(s.width,s.depth),outline=g.inner.map(p=>p.join(',')).join(' '),outer=g.outline.map(p=>p.join(',')).join(' ');
 // SVG somente de desenho técnico local, sem instrução máquina nem conversão em DXF.
 return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="-35 -35 '+(s.width+70)+' '+(s.depth+70)+'" width="100%" role="img" aria-label="Canto 45° cinco lados em milímetros">'+
  '<polygon points="'+outer+'" fill="#e1e9ec" stroke="#50778e" stroke-width="5"/>'+
  '<polygon points="'+outline+'" fill="#f6f8f9" stroke="#9bb9c9" stroke-width="3" stroke-dasharray="10 6"/>'+
  '<line x1="'+g.diagonal[0].join('" y1="')+'" x2="'+g.diagonal[1].join('" y2="')+'" stroke="#be8157" stroke-width="10"/>'+
  '<text x="'+s.width/2+'" y="'+Math.max(55,s.depth/2)+'" font-size="32" fill="#205773" text-anchor="middle">'+g.diagonalLength+' mm · 45°</text></svg>';
}
return {validate,geometry,parts,create,update,svgTechnical};
});