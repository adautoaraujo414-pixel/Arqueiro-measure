/* Arque Measure: deterministic guillotine cutting estimator. Units: mm. */
(function(root){
'use strict';
function positive(v,label){const n=Number(v);if(!Number.isFinite(n)||n<=0)throw Error(label+' deve ser maior que zero.');return n;}
function calculate(input){
 const sheetW=positive(input.width,'Comprimento da chapa'),sheetH=positive(input.height,'Largura da chapa');
 const kerf=Number(input.kerf??3);if(!Number.isFinite(kerf)||kerf<0||kerf>20)throw Error('Espessura da serra inválida.');
 const trim=Number(input.trim??0);if(!Number.isFinite(trim)||trim<0||trim>100)throw Error('Margem de refilo inválida.');
 const W=sheetW-2*trim,H=sheetH-2*trim;if(W<=0||H<=0)throw Error('Refilo maior do que a chapa.');
 const rows=(input.pieces||[]).map((p,i)=>({id:p.id||String(i),name:String(p.name||'Peça '+(i+1)),w:positive(p.w,'Comprimento'),h:positive(p.h,'Largura'),qty:Number(p.qty),rotate:p.rotate!==false,grain:!!p.grain,edge2:Number(p.edge2||0),edge04:Number(p.edge04||0)}));
 const parts=[];let edge2=0,edge04=0;
 for(const p of rows){
  if(!Number.isInteger(p.qty)||p.qty<1||p.qty>1000)throw Error('Quantidade inválida: '+p.name);
  if(parts.length+p.qty>5000)throw Error('Máximo de 5.000 peças por plano.');
  if(!Number.isInteger(p.edge2)||p.edge2<0||p.edge2>4||!Number.isInteger(p.edge04)||p.edge04<0||p.edge04>4||p.edge2+p.edge04>4)throw Error('Bordas inválidas: '+p.name);
  const perimeter=2*(p.w+p.h);edge2+=p.qty*perimeter*p.edge2/4;edge04+=p.qty*perimeter*p.edge04/4;
  for(let k=0;k<p.qty;k++)parts.push({...p,ordinal:k+1});
 }
 parts.sort((a,b)=>b.w*b.h-a.w*a.h || Math.max(b.w,b.h)-Math.max(a.w,a.h));
 const sheets=[],unfit=[];
 function options(p,free){const out=[{w:p.w,h:p.h,rotated:false}];if(p.rotate&&!p.grain&&p.w!==p.h)out.push({w:p.h,h:p.w,rotated:true});return out.filter(o=>o.w<=free.w+1e-7&&o.h<=free.h+1e-7);}
 for(const p of parts){
  let best=null;
  for(let s=0;s<sheets.length;s++)for(let f=0;f<sheets[s].free.length;f++){
   const rect=sheets[s].free[f];
   for(const opt of options(p,rect)){const waste=rect.w*rect.h-opt.w*opt.h;if(!best||waste<best.waste)best={s,f,opt,waste};}
  }
  if(!best){
   const rect={x:trim,y:trim,w:W,h:H};const opts=options(p,rect);
   if(!opts.length){unfit.push({name:p.name,w:p.w,h:p.h,ordinal:p.ordinal});continue;}
   sheets.push({pieces:[],free:[rect]});best={s:sheets.length-1,f:0,opt:opts.sort((a,b)=>a.w-b.w)[0]};
  }
  const sh=sheets[best.s],r=sh.free.splice(best.f,1)[0],o=best.opt;
  sh.pieces.push({id:p.id,name:p.name,x:r.x,y:r.y,w:o.w,h:o.h,rotated:o.rotated,ordinal:p.ordinal});
  const rw=r.w-o.w-kerf,rh=r.h-o.h-kerf;
  // Guillotine split: remaining right strip and bottom strip, without overlapping.
  if(rw>0.0001)sh.free.push({x:r.x+o.w+kerf,y:r.y,w:rw,h:o.h});
  if(rh>0.0001)sh.free.push({x:r.x,y:r.y+o.h+kerf,w:r.w,h:rh});
 }
 const used= sheets.reduce((v,s)=>v+s.pieces.reduce((n,p)=>n+p.w*p.h,0),0);
 const area=sheetW*sheetH,allocated=sheets.length*area;
 return {sheets,unfit,sheetWidth:sheetW,sheetHeight:sheetH,kerf,trim,totalPieces:parts.length,placedPieces:parts.length-unfit.length,sheetCount:sheets.length,usedArea:used,allocatedArea:allocated,wasteArea:Math.max(0,allocated-used),utilization:allocated?100*used/allocated:0,edge2mm:edge2,edge04mm:edge04,cutLengthEstimate:sheets.reduce((sum,s)=>sum+s.pieces.reduce((n,p)=>n+p.w+p.h,0),0)};
}
root.ArqueCut={calculate};
})(typeof window!=='undefined'?window:globalThis);
