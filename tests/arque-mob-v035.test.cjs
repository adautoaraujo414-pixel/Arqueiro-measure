'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const k of [
 "version:'0.35'","function sheetMeasureUBySides(","function sheetPieceClearances(",
 "function sheetClearanceLabels(","function sheetMagicLayout(","function sheetCutSet(",
 "getCoalescedEvents","aria-label=\"Distribuição estimada da chapa\"",
 "function sheetPhotoRead(","const ab=sheetBounds(),vw=ab.xmax-ab.xmin-36",
 "function sheetPinchMove(){","function sheetPhotoOptions(){","function scene3d(){"
])assert(s.includes(k),'Missing '+k);
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'));
const a=s.indexOf('<script>')+8,b=s.lastIndexOf('</script>');assert(a>=8&&b>a);const js=s.slice(a,b);new Function(js);
const slice=(start,end)=>{let i=js.indexOf(start),j=js.indexOf(end,i+1);assert(i>=0&&j>i);return js.slice(i,j)};
let st={sheet2dLines:[
 {id:1,a:{x:100,y:100},b:{x:100,y:300},cm:77,cmSource:'manual',thicknessCm:1.5},
 {id:2,a:{x:100,y:300},b:{x:300,y:300},cm:35,cmSource:'manual',thicknessCm:0},
 {id:3,a:{x:300,y:100},b:{x:300,y:300},cm:77,cmSource:'manual',thicknessCm:1.5}
],sheet2dPieces:[]};
const proj=(p,l)=>{const vx=l.b.x-l.a.x,vy=l.b.y-l.a.y;const q=vx*vx+vy*vy,t=Math.max(0,Math.min(1,((p.x-l.a.x)*vx+(p.y-l.a.y)*vy)/q));return {dist:Math.hypot(p.x-l.a.x-vx*t,p.y-l.a.y-vy*t)}};
const distance=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const measure=new Function('st','sheetProjection','sheetPieceCm','sheetLength',slice('function sheetMeasureUBySides(','function sheetTripleTap(')+';return sheetMeasureUBySides')(st,proj,n=>n/2,distance);
let u=measure([{x:100,y:205},{x:185,y:300},{x:300,y:205}]);
assert.equal(u.kind,'U');assert.equal(u.widthCm,35);assert.equal(u.leftCm,77);assert.equal(u.rightCm,77);assert.equal(u.insideCm,33.5);assert.equal(u.estimated,false);
assert.equal(measure([{x:100,y:190},{x:100,y:240},{x:300,y:225}]),null);
st.sheet2dPieces=[{id:1,x:40,y:30,w:300,h:220},{id:2,x:100,y:75,w:100,h:80}];
const clear=new Function('st','sheetPieceCm',slice('function sheetPieceAt(','function sheetClearanceLabels(')+';return sheetPieceClearances;')(st,n=>n/2);
assert.deepEqual(clear(st.sheet2dPieces[1]).edges,{left:30,right:70,top:22.5,bottom:47.5});
let writes=0;const cutting={sheetCutRows:[{id:1,qty:3,cut:0},{id:2,qty:2,cut:0}]};
const cut=new Function('st','clamp','persist','sheetCutView',slice('function sheetCutSet(','function sheetCutView(')+';return sheetCutSet')(cutting,(n,a,b)=>Math.max(a,Math.min(b,n)),()=>writes++,()=>{});
for(let i=0;i<5;i++)cut([1,2],true);assert.deepEqual(cutting.sheetCutRows.map(r=>r.cut),[3,2]);cut([1,2],false);
assert.deepEqual(cutting.sheetCutRows.map(r=>r.cut),[3,1]);assert.equal(writes,6);
console.log('v0.35: três lados U, folgas, desenho, corte por unidade: OK');
