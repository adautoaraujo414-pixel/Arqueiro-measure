/* Arque: cotas, distâncias e movimento preciso em milímetros.
   Nunca modifica medidas de fabricação; posições só são aplicadas após validação. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArquePrecision=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const r=x=>Math.round(x*10)/10;
const numeric=(x,label)=>{if(x===''||x===null||x===undefined||!Number.isFinite(Number(x)))throw Error(label+' deve ser um número em mm.');return Number(x);};
function footprint(i){
 const s=i.moduleSpec||{},w=numeric(i.w,'Largura')+Number(s.leftFiller||0)+Number(s.rightFiller||0);
 const d=numeric(i.d,'Profundidade')+(s.back==='overlay'?Number(s.backThickness||0):0);
 if(w<=0||d<=0)throw Error('Dimensão de objeto inválida.');
 return Math.abs(Number(i.rotation||0))%180===90?{w:r(d),d:r(w)}:{w:r(w),d:r(d)};
}
function metrics(layout,id){
 const obj=(layout.items||[]).find(x=>x.id===id);if(!obj)throw Error('Objeto não encontrado.');
 const f=footprint(obj),x=numeric(obj.x,'X'),y=numeric(obj.y,'Y'),z=Number(obj.z||0);
 const W=numeric(layout.width,'Parede'),D=numeric(layout.depth,'Profundidade do ambiente'),H=numeric(layout.height,'Altura da obra');
 return {id,x:r(x),y:r(y),z:r(z),w:f.w,d:f.d,height:r(Number(obj.height)||0),
  left:r(x),right:r(W-x-f.w),back:r(y),front:r(D-y-f.d),
  top:r(H-z-Number(obj.height||0)),ceiling:r(H),
  confirmed:!!layout.confirmed};
}
function overlap3d(a,ax,ay,b){
 const A=footprint(a),B=footprint(b);
 const az=Number(a.z||0),bz=Number(b.z||0),ah=Number(a.height||0),bh=Number(b.height||0);
 return ax<b.x+B.w-.01&&b.x<ax+A.w-.01&&ay<b.y+B.d-.01&&b.y<ay+A.d-.01&&az<bz+bh-.01&&bz<az+ah-.01;
}
function nudge(layout,id,axis,amount){
 const obj=(layout.items||[]).find(x=>x.id===id);if(!obj)throw Error('Selecione um móvel ou eletrodoméstico.');
 if(!['x','y','z'].includes(axis))throw Error('Escolha o eixo X, Y ou Z.');
 const delta=numeric(amount,'Deslocamento');
 if(!delta||Math.abs(delta)>1000)throw Error('Deslocamento deve ficar entre -1.000 e 1.000 mm, sem ser zero.');
 const f=footprint(obj),out={x:r(Number(obj.x)||0),y:r(Number(obj.y)||0),z:r(Number(obj.z)||0)};
 out[axis]=r(out[axis]+delta);
 if(out.x<0||out.y<0||out.z<0||out.x+f.w>Number(layout.width)+.01||out.y+f.d>Number(layout.depth)+.01||out.z+Number(obj.height||0)>Number(layout.height)+.01)
  throw Error('Deslocamento ultrapassa os limites reais do ambiente.');
 if(obj.kind==='module'){
  for(const other of layout.items||[]){
   if(other.id!==obj.id&&other.kind==='module'&&overlap3d({...obj,z:out.z},out.x,out.y,other))
    throw Error('O movimento faria '+(obj.code||obj.label)+' invadir '+(other.code||other.label)+'.');
  }
 }
 return out;
}
function clearances(layout,id){
 const a=(layout.items||[]).find(x=>x.id===id);if(!a)throw Error('Objeto não encontrado.');
 const A=footprint(a),az=Number(a.z||0),ah=Number(a.height||0),out=[];
 for(const b of layout.items||[]){
  if(b.id===id||b.kind!=='module'||a.kind!=='module')continue;
  const B=footprint(b),bz=Number(b.z||0),bh=Number(b.height||0);
  if(az>=bz+bh||bz>=az+ah)continue;
  const lateralOverlap=!(a.y+A.d<=b.y||b.y+B.d<=a.y);
  const depthOverlap=!(a.x+A.w<=b.x||b.x+B.w<=a.x);
  if(lateralOverlap)out.push({id:b.id,axis:'x',gap:r(Math.max(0,b.x-(a.x+A.w),a.x-(b.x+B.w))),name:b.code||b.label});
  if(depthOverlap)out.push({id:b.id,axis:'y',gap:r(Math.max(0,b.y-(a.y+A.d),a.y-(b.y+B.d))),name:b.code||b.label});
 }
 return out.sort((a,b)=>a.gap-b.gap);
}
return {footprint,metrics,nudge,clearances};
});