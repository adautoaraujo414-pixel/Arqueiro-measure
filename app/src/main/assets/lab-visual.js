/* Arque Measure: cena espacial em milimetros, renderizada offline por SVG.
   Perspectiva axonometrica com rotacao; usa o MESMO modelo de corte, nao inventa medidas.
   Nao e render fotografico nem ferramenta CNC. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueVisual=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const esc=x=>String(x??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const num=(v,f=0)=>Number.isFinite(Number(v))?Number(v):f;
const fmt=v=>num(v).toLocaleString('pt-BR',{maximumFractionDigits:1});
const clamp=(x,a,b)=>Math.min(b,Math.max(a,x));
const pt=coord=>coord.map(x=>Math.round(x*100)/100).join(',');
const poly=(points,project,fill,stroke='#647b88',width=1,extra='')=>'<polygon points="'+points.map(p=>pt(project(...p))).join(' ')+'" fill="'+fill+'" stroke="'+stroke+'" stroke-width="'+width+'" stroke-linejoin="round" '+extra+'/>';
const line=(p,q,project,color='#9caebb',width=1,extra='')=>'<line x1="'+project(...p)[0]+'" y1="'+project(...p)[1]+'" x2="'+project(...q)[0]+'" y2="'+project(...q)[1]+'" stroke="'+color+'" stroke-width="'+width+'" '+extra+'/>';
const text=(p,project,value,size=12,color='#375568',more='')=>{const v=project(...p);return '<text x="'+v[0]+'" y="'+v[1]+'" font-size="'+size+'" fill="'+color+'" text-anchor="middle" font-weight="650" pointer-events="none" '+more+'>'+esc(value)+'</text>';};
const palettes={
 'branco':['#f4f1e9','#dedbd5','#fffdfa'],
 'greige':['#c8bbae','#ad9f93','#d5c9be'],
 'beige':['#dfd0c0','#c6b5a2','#eee1d1'],
 'grafite':['#515961','#3a444c','#687079'],
 'preto':['#373c41','#242c32','#4d5358'],
 'cinza':['#b1b6b7','#939a9d','#c8cccb'],
 'jade':['#89aa97','#6d8977','#a5c4ac'],
 'verde':['#779184','#597668','#99afa4'],
 'freijo':['#b99068','#91714e','#d4b18b'],
 'jatoba':['#9f694a','#754832','#ba8562'],
 'castanha':['#8c6349','#6a4938','#aa7858'],
 'madeira':['#aa805e','#806044','#c39a73']
};
function finishColor(name){const v=String(name||'').toLowerCase();for(const [key,colors] of Object.entries(palettes))if(v.includes(key))return colors;return ['#d6d7d3','#afb6ba','#eff0ec'];}
function identifier(item,index){return item.code||((item.kind==='module'?'M':item.kind==='countertop'?'P':'E')+String(index+1).padStart(2,'0'));}
function camera(layout,opt={}){
 const W=Math.max(100,num(layout.width,3500)),D=Math.max(100,num(layout.depth,2800)),H=Math.max(100,num(layout.height,2600));
 const angle=num(opt.angle,40)*Math.PI/180,elev=32*Math.PI/180,zoom=clamp(num(opt.zoom,1),.65,2.5);
 const c=Math.cos(angle),si=Math.sin(angle),ev=Math.sin(elev),cv=Math.cos(elev);
 const raw=(x,y,z)=>[c*x-si*y,si*ev*x+c*ev*y-cv*z];
 const corners=[];for(const x of [0,W])for(const y of [0,D])for(const z of [0,H])corners.push(raw(x,y,z));
 const minX=Math.min(...corners.map(x=>x[0])),maxX=Math.max(...corners.map(x=>x[0])),minY=Math.min(...corners.map(x=>x[1])),maxY=Math.max(...corners.map(x=>x[1]));
 const scale=Math.min(880/Math.max(1,maxX-minX),510/Math.max(1,maxY-minY))*zoom;
 const cx=(maxX+minX)/2,cy=(maxY+minY)/2;
 const project=(x,y,z)=>{const v=raw(x,y,z);return [Math.round((500+(v[0]-cx)*scale)*100)/100,Math.round((320+(v[1]-cy)*scale)*100)/100];};
 return {project,width:1000,height:650,scale,angle,elevation:elev};
}
function surfaces(x,y,z,w,d,h,project,colors,selected){
 const far='#b1c4cc',edge=selected?'#087fad':'#77858b',sw=selected?2.7:1.15;
 const P=(dx,dy,dz)=>[x+dx,y+dy,z+dz];
 let out='';
 out+=poly([P(0,0,h),P(w,0,h),P(w,d,h),P(0,d,h)],project,colors[2],edge,sw);
 // Lateral direita e frente voltadas para o observador em vista diagonal padrao.
 out+=poly([P(w,0,0),P(w,d,0),P(w,d,h),P(w,0,h)],project,colors[1],edge,sw);
 out+=poly([P(0,d,0),P(w,d,0),P(w,d,h),P(0,d,h)],project,colors[0],edge,sw);
 return out;
}
function scene(layout,selectedId='',opts={}){
 const cam=camera(layout,opts),project=cam.project,roomW=num(layout.width,3500),roomD=num(layout.depth,2800),roomH=num(layout.height,2600);
 const mode=opts.mode==='structure'?'structure':'fronts';
 const items=(layout.items||[]).filter(i=>i.kind==='module'||(i.view==='plan'&&['base','upper','drawers','countertop','sink','fridge','stove','cooktop','led','filler','panel','outlet','drain','door'].includes(i.kind)));
 let out='<svg id="labBoard" class="lab-visual" xmlns="http://www.w3.org/2000/svg" width="100%" viewBox="0 0 1000 650" role="img" aria-label="Ambiente técnico 3D, medidas em milímetros" style="touch-action:manipulation;user-select:none"><defs>'+
  '<linearGradient id="arqueVisualFloor" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#f5f5f1"/><stop offset="1" stop-color="#dfebe9"/></linearGradient>'+
  '<linearGradient id="arqueWall" x1="0" y1="0" x2=".6" y2="1"><stop stop-color="#fdfefd"/><stop offset="1" stop-color="#e6ebec"/></linearGradient>'+
  '</defs><rect width="1000" height="650" fill="#f3f7fa"/>';
 out+=poly([[0,0,0],[roomW,0,0],[roomW,roomD,0],[0,roomD,0]],project,'url(#arqueVisualFloor)','#bacad3',1.4);
 // Duas paredes e piso em angulo de ambiente, como referencia arquitetonica.
 out+=poly([[0,0,0],[roomW,0,0],[roomW,0,roomH],[0,0,roomH]],project,'url(#arqueWall)','#bdcbd3',1.3);
 out+=poly([[0,0,0],[0,roomD,0],[0,roomD,roomH],[0,0,roomH]],project,'#e8edf0','#bdcbd3',1.3);
 const step=roomW>7000||roomD>7000?1000:500;
 for(let x=step;x<roomW;x+=step)out+=line([x,0,1],[x,roomD,1],project,'#d4dfdf',.65);
 for(let y=step;y<roomD;y+=step)out+=line([0,y,1],[roomW,y,1],project,'#d4dfdf',.65);
 out+=line([0,roomD,0],[roomW,roomD,0],project,'#7998a6',2);
 out+=line([roomW,0,0],[roomW,roomD,0],project,'#7998a6',2);
 const positions=items.map((item,i)=>({item,i,sort:num(item.x)+num(item.y)})).sort((a,b)=>a.sort-b.sort);
 for(const {item,i} of positions){
  const sel=item.id===selectedId,x=num(item.x),y=num(item.y),z=num(item.z,0),w=Math.max(1,num(item.w,600)),d=Math.max(1,num(item.d,450)),h=Math.max(1,num(item.height,item.kind==='countertop'?40:600));
  const spec=item.moduleSpec||{},t=num(spec.thickness,18),code=identifier(item,items.indexOf(item));
  const body=finishColor(spec.caseMaterial||item.material||'branco'),front=finishColor(spec.frontMaterial||spec.caseMaterial||'branco');
  const special=['sink','fridge','stove','cooktop'].includes(item.kind)?'#8a9fa7':item.kind==='led'?'#f4d696':item.kind==='countertop'?'#b4aea0':null;
  let content='<g data-lab-object="'+esc(item.id)+'" data-lab-code="'+esc(code)+'" class="'+(sel?'lab-selected':'')+'" tabindex="0" role="button" aria-label="'+esc(code+' '+item.label)+'">';
  if(mode==='fronts'||item.kind!=='module'){
   content+=surfaces(x,y,z,w,d,h,project,special?[special,'#8d8e87','#d2d2cb']:body,sel);
   if(item.kind==='sink'||item.kind==='cooktop'||item.kind==='stove'){
    const c=project(x+w/2,y+d/2,z+h+1);
    content+='<ellipse cx="'+c[0]+'" cy="'+c[1]+'" rx="'+(item.kind==='sink'?21:34)+'" ry="'+(item.kind==='sink'?10:15)+'" fill="'+(item.kind==='sink'?'#e3e8e9':'#272d31')+'" stroke="#697980" stroke-width="1.5"/>';
    if(item.kind!=='sink')for(const shift of [-15,15])content+='<circle cx="'+(c[0]+shift)+'" cy="'+c[1]+'" r="7" fill="none" stroke="#b7bec1" stroke-width="1.5"/>';
   }
   if(item.kind==='fridge')content+=line([x+w*.5,y+d+2,z+50],[x+w*.5,y+d+2,z+h-50],project,'#cbd1d4',2.5);
   if(item.kind==='led')content+=line([x,y+d+2,z+h/2],[x+w,y+d+2,z+h/2],project,'#ffc75e',5);
   if(item.kind==='module'){
    const fy=y+d+Math.max(1,t/8),z1=z+Math.min(t,h/3),z2=z+h-Math.min(t,h/3);
    // Frentes reais: numero e dimensoes seguem porta global ou por vao.
    const A=globalThis.ArqueModules,checked=A?.check(spec),bays=checked?A.bayBounds(checked):[];
    if(checked?.doorMode==='byBay'){
     for(const [j,b] of bays.entries()){
      const qty=checked.bayDoors[j]||0;
      if(!qty)continue;
      for(let k=0;k<qty;k++){
       const left=x+b.start+k*b.width/qty+2,right=x+b.start+(k+1)*b.width/qty-2;
       content+=poly([[left,fy,z1],[right,fy,z1],[right,fy,z2],[left,fy,z2]],project,front[0],front[1],.9);
       if(checked.frontType==='cava')content+=line([left+5,fy+2,z2-38],[right-5,fy+2,z2-38],project,'#9b8c7a',2.1);
      }
     }
    }else if(num(checked?.doorCount)>0){
     const count=checked.doorCount;
     for(let k=0;k<count;k++){
      const left=x+k*w/count+2,right=x+(k+1)*w/count-2;
      content+=poly([[left,fy,z1],[right,fy,z1],[right,fy,z2],[left,fy,z2]],project,front[0],front[1],1);
      if(checked.frontType==='cava')content+=line([left+6,fy+1,z2-38],[right-6,fy+1,z2-38],project,'#a49683',2);
     }
    }
   }
  }else{
   // Carcaca aberta: laterais, tampo/base, divisorias e prateleiras visiveis.
   const bodyColors=body;const s=globalThis.ArqueModules?.check(spec),bays=s?globalThis.ArqueModules.bayBounds(s):[];
   content+=poly([[x,y,z+h],[x+w,y,z+h],[x+w,y+d,z+h],[x,y+d,z+h]],project,bodyColors[2],'#657d89',1.1);
   for(const xx of [x,x+w-t]){
    content+=poly([[xx,y,z],[xx+t,y,z],[xx+t,y+d,z],[xx,y+d,z]],project,bodyColors[0],'#6b8794',.7);
    content+=poly([[xx,y+d,z],[xx+t,y+d,z],[xx+t,y+d,z+h],[xx,y+d,z+h]],project,bodyColors[1],'#647e8b',1);
   }
   for(const height of [0,h-t]){
    content+=poly([[x,y+d,height+z],[x+w,y+d,height+z],[x+w,y+d,height+z+t],[x,y+d,height+z+t]],project,bodyColors[0],'#6b8794',1);
   }
   for(const b of bays.slice(0,-1)){
    const xx=x+b.end;
    content+=poly([[xx,y+d,z+t],[xx+t,y+d,z+t],[xx+t,y+d,z+h-t],[xx,y+d,z+h-t]],project,bodyColors[1],'#7b98a6',.8);
   }
   for(const [j,b] of bays.entries()){
    const count=s?.shelvesByBay?.[j]??s?.shelfCount??0;
    for(let k=0;k<count;k++){const zz=z+t+(h-2*t)*(k+1)/(count+1);
     content+=poly([[x+b.start,y+d,zz],[x+b.end,y+d,zz],[x+b.end,y+d,zz+t],[x+b.start,y+d,zz+t]],project,bodyColors[0],'#809ca8',.6);}
    for(const fix of s?.fixedShelves||[])if(fix.bay===j){const zz=z+t+(h-2*t)*fix.at;
     content+=poly([[x+b.start,y+d,zz],[x+b.end,y+d,zz],[x+b.end,y+d,zz+t],[x+b.start,y+d,zz+t]],project,'#b9a892','#6d8fa0',.8);}
   }
  }
  content+=text([x+w/2,y+d/2,z+h+Math.max(110,roomH*.035)],project,code,17,sel?'#075b8d':'#415d70','paint-order="stroke" stroke="#fff" stroke-width="3"');
  content+='</g>';
  out+=content;
 }
 const p1=project(0,roomD,0),p2=project(roomW,roomD,0);
 out+='<text x="18" y="27" font-size="14" fill="#325873" font-weight="700">ARQUE · AMBIENTE CONSTRUTIVO</text>';
 out+='<text x="18" y="47" font-size="11" fill="#688294">'+esc(fmt(roomW)+' × '+fmt(roomD)+' × '+fmt(roomH)+' mm')+(layout.confirmed?' · MEDIDAS CONFIRMADAS':' · RASCUNHO NÃO CONFERIDO')+'</text>';
 out+='<text x="982" y="632" font-size="10" text-anchor="end" fill="#698291">Vista espacial técnica · não é foto real</text>';
 out+='</svg>';
 return out;
}
function catalog(layout){
 const list=(layout.items||[]).filter(i=>i.kind==='module'||['countertop','sink','fridge','stove','cooktop','led'].includes(i.kind));
 return list.map((item,i)=>({id:item.id,code:identifier(item,i),name:item.label,
  dims:fmt(item.w)+' × '+fmt(item.height)+' × '+fmt(item.d)+' mm',z:num(item.z,0),kind:item.kind}));
}
return {scene,catalog,camera,identifier,finishColor};
});