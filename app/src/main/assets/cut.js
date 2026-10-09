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
 const ordering=input.strategy||'area';
 const byArea=(a,b)=>b.w*b.h-a.w*a.h || Math.max(b.w,b.h)-Math.max(a.w,a.h);
 if(ordering==='longest')parts.sort((a,b)=>Math.max(b.w,b.h)-Math.max(a.w,a.h)||byArea(a,b));
 else if(ordering==='width')parts.sort((a,b)=>b.w-a.w||byArea(a,b));
 else if(ordering==='height')parts.sort((a,b)=>b.h-a.h||byArea(a,b));
 else parts.sort(byArea);
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

/* Manual stock-sheet simulator for repeated identical parts. Counts strip/rip cuts as an estimate. */
function manualGrid(input){
 const width=positive(input.width,'Comprimento disponível'),height=positive(input.height,'Largura disponível');
 const partW=positive(input.partW,'Comprimento da peça'),partH=positive(input.partH,'Largura da peça');
 const kerf=Number(input.kerf??3),trim=Number(input.trim??0);
 if(!Number.isFinite(kerf)||kerf<0||kerf>20||!Number.isFinite(trim)||trim<0||trim>100)throw Error('Serra ou refilo inválidos.');
 const usableW=width-2*trim,usableH=height-2*trim;
 if(usableW<=0||usableH<=0)throw Error('O refilo supera a chapa.');
 const qty=Number(input.qty??0);
 if(!Number.isInteger(qty)||qty<1||qty>5000)throw Error('Quantidade solicitada inválida.');
 const allowRotation=input.rotate!==false&&!input.grain;
 const orientations=[{w:partW,h:partH,rotated:false}];
 if(allowRotation&&partW!==partH)orientations.push({w:partH,h:partW,rotated:true});
 const configurations=orientations.map(o=>{
  const cols=Math.max(0,Math.floor((usableW+kerf)/(o.w+kerf)));
  const rows=Math.max(0,Math.floor((usableH+kerf)/(o.h+kerf)));
  return {...o,cols,rows,capacity:cols*rows};
 });
 const best=configurations.sort((a,b)=>b.capacity-a.capacity || Number(a.rotated)-Number(b.rotated))[0];
 const placed=Math.min(qty,best.capacity),pieces=[];
 for(let n=0;n<placed;n++){const col=n%best.cols,row=Math.floor(n/best.cols);pieces.push({x:trim+col*(best.w+kerf),y:trim+row*(best.h+kerf),w:best.w,h:best.h});}
 // Strip-first guillotine workflow: one rip per strip (if separation from a remnant),
 // then crosscuts dividing pieces in that strip. These are indicative, not machine instructions.
 const usedRows=placed?Math.ceil(placed/best.cols):0;
 const cutCount=placed?usedRows+placed:0;
 const usedArea=placed*partW*partH;
 return {width,height,kerf,trim,cols:best.cols,rows:best.rows,capacity:best.capacity,rotated:best.rotated,placed,pending:Math.max(0,qty-placed),pieces,usedArea,unusedArea:width*height-usedArea,utilization:Math.round(10000*usedArea/(width*height))/100,estimatedCuts:cutCount,estimatedCutsNote:'Estimativa de cortes retos em tiras; depende da sequência e do esquadrejamento.'};
}


/* A single real stock sheet shared by different modules.  No invented extra sheets. */
function mixedStock(input){
 const width=positive(input.width,'Comprimento disponível'),height=positive(input.height,'Largura disponível');
 const kerf=Number(input.kerf??3),trim=Number(input.trim??0);
 if(!Number.isFinite(kerf)||kerf<0||kerf>20||!Number.isFinite(trim)||trim<0||trim>100||width<=trim*2||height<=trim*2)throw Error('Serra, refilo ou chapa inválidos.');
 const stock={width,height,kerf,trim};
 const rows=(input.pieces||[]).map((p,i)=>({id:String(p.id??i),name:String(p.name||'Peça '+(i+1)),w:positive(p.w,'Comprimento'),h:positive(p.h,'Largura'),qty:Number(p.qty),grain:!!p.grain,rotate:p.rotate!==false}));
 let requested=0,parts=[];
 for(const p of rows){
  if(!Number.isInteger(p.qty)||p.qty<1||p.qty>1000||requested+p.qty>5000)throw Error('Quantidade inválida ou excessiva.');
  requested+=p.qty;
  for(let i=0;i<p.qty;i++)parts.push({...p,ordinal:i+1});
 }
 parts.sort((a,b)=>b.w*b.h-a.w*a.h||Math.max(b.w,b.h)-Math.max(a.w,a.h));
 const free=[{x:trim,y:trim,w:width-2*trim,h:height-2*trim}],placed=[],unplaced=[];
 for(const p of parts){
  let candidate=null;
  for(let i=0;i<free.length;i++){
   const f=free[i],options=[{w:p.w,h:p.h,rotated:false}];
   if(!p.grain&&p.rotate&&p.w!==p.h)options.push({w:p.h,h:p.w,rotated:true});
   for(const o of options)if(o.w<=f.w&&o.h<=f.h){
    const waste=f.w*f.h-o.w*o.h;
    if(!candidate||waste<candidate.waste)candidate={i,o,waste};
   }
  }
  if(!candidate){unplaced.push({id:p.id,name:p.name,w:p.w,h:p.h,ordinal:p.ordinal});continue;}
  const f=free.splice(candidate.i,1)[0],o=candidate.o;
  placed.push({id:p.id,name:p.name,ordinal:p.ordinal,x:f.x,y:f.y,w:o.w,h:o.h,rotated:o.rotated});
  const right=f.w-o.w-kerf,bottom=f.h-o.h-kerf;
  if(right>0.0001)free.push({x:f.x+o.w+kerf,y:f.y,w:right,h:o.h});
  if(bottom>0.0001)free.push({x:f.x,y:f.y+o.h+kerf,w:f.w,h:bottom});
 }
 const pieceArea=placed.reduce((sum,p)=>sum+p.w*p.h,0);
 const reusable=free.filter(r=>r.w>=50&&r.h>=50).sort((a,b)=>b.w*b.h-a.w*a.h);
 return {...stock,placed,unplaced,reusable,requested,placedCount:placed.length,usedArea:pieceArea,wasteArea:width*height-pieceArea,utilization:Math.round(10000*pieceArea/(width*height))/100,cutCountEstimate:placed.length?placed.length*2:0,note:'Estimativa de disposição por cortes guilhotinados. Confira sequência de cortes, sentido do veio e peças antes de fabricar.'};
}


/* Apply optional user positions. Reject every out-of-bounds and overlapping placement. */
function positionMixed(stock,moves){
 const pieces=stock.placed.map(p=>({...p}));
 const attempted=moves||{};
 for(const p of pieces){
  const key=p.id+':'+p.ordinal,override=attempted[key];
  if(!override)continue;
  const x=Number(override.x),y=Number(override.y);
  if(!Number.isFinite(x)||!Number.isFinite(y)||x<stock.trim||y<stock.trim||x+p.w>stock.width-stock.trim||y+p.h>stock.height-stock.trim)throw Error('Posição fora da chapa: '+p.name);
  p.x=x;p.y=y;
 }
 for(let i=0;i<pieces.length;i++)for(let j=i+1;j<pieces.length;j++){
  const a=pieces[i],b=pieces[j],k=stock.kerf;
  if(!(a.x+a.w+k<=b.x||b.x+b.w+k<=a.x||a.y+a.h+k<=b.y||b.y+b.h+k<=a.y))throw Error('Peças sobrepostas ou sem espaço de serra: '+a.name+' / '+b.name);
 }
 return {...stock,placed:pieces,manuallyPositioned:true,reusable:[],note:'Posições editadas manualmente: verifique as sobras, pois a lista de sobras automáticas não se aplica após mover peças.'};
}

function optimize(input){
 const approaches=['area','longest','width','height'];
 const trials=approaches.map(strategy=>({...calculate({...input,strategy}),strategy}));
 trials.sort((a,b)=>a.unfit.length-b.unfit.length||a.sheetCount-b.sheetCount||b.utilization-a.utilization);
 return {...trials[0],testedStrategies:approaches.length,optimizationNote:'Melhor resultado entre quatro heurísticas. Não garante o mínimo global de chapas.'};
}
root.ArqueCut={calculate,manualGrid,mixedStock,positionMixed,optimize};
})(typeof window!=='undefined'?window:globalThis);
