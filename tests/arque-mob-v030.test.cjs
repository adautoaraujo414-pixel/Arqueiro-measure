'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const token of [
 "version:'0.33'","function sheetMagicLayout(","function sheetPieceSvg(","function sheetPieceEditor(",
 "function sheetPieceCenter(","function sheetMeasureU(","function sheetTripleTap(","data-sheet-tool=\"magic\"",
 "data-sheet-tool=\"rect\"","data-sheet-tool=\"gap\"","sheet2dPieces:st.sheet2dPieces",
 "pieces:st.sheet2dPieces","function sheet2dRedo(){","function sheetPinchMove(){",
 "function sheetPhotoRead(file){","function scene3d(){","data-ribbon=\"lineTh\"",
 "data-ribbon=\"unit\""
])assert(s.includes(token),'Recurso ausente: '+token);
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'),'3D deve continuar oculto');
const script=s.slice(s.indexOf('<script>')+8,s.lastIndexOf('</script>'));new Function(script);
const from=script.indexOf('function sheetToCm('),to=script.indexOf('function sheet2dSvg(){',from);
assert(from>=0&&to>from,'Funções geométricas ausentes');
const st={sheet2dUnit:'cm',sheet2dPieces:[],sheet2dLines:[]},rd=n=>Math.round(n*10)/10,fmt=n=>String(n);
const geom=new Function('st','rd','fmt','sheetCmScale','sheetDist','sheetLength','sheetCheckpoint','render','persist','toast','sheet',
 script.slice(from,to)+';return {sheetMagicLayout,sheetToCm,sheetFromCm,sheetMeasureU};')(
 st,rd,fmt,2,(a,b)=>Math.hypot(a.x-b.x,a.y-b.y),(a,b)=>Math.hypot(a.x-b.x,a.y-b.y),
 ()=>{},()=>{},()=>{},()=>{},()=>{});
const piece={id:1,x:100,y:100,w:400,h:160,edgeCm:1.8};
const x=geom.sheetMagicLayout(piece,4,1.5,'vertical');
assert(Math.abs(x.insideCm-196.4)<1e-6);
assert(Math.abs(x.gapCm-47.975)<1e-6);
assert(Math.abs(x.gapMm-479.75)<1e-6);
assert.equal(x.positionsCm.length,3);
assert(Math.abs(4*x.gapCm+3*1.5+2*1.8-200)<1e-6);
assert.throws(()=>geom.sheetMagicLayout(piece,24,14,'vertical'));
assert.throws(()=>geom.sheetMagicLayout(piece,100,1.5,'vertical'));
st.sheet2dUnit='mm';assert.equal(geom.sheetToCm(15),1.5);assert.equal(geom.sheetFromCm(1.5),15);
st.sheet2dLines=[
 {id:1,a:{x:140,y:100},b:{x:140,y:254},cm:77,cmSource:'manual',thicknessCm:1.5},
 {id:2,a:{x:140,y:254},b:{x:210,y:254},cm:35,cmSource:'manual',thicknessCm:1.5},
 {id:3,a:{x:210,y:100},b:{x:210,y:254},cm:77,cmSource:'manual',thicknessCm:1.5}
];
const u=geom.sheetMeasureU({x:175,y:200});
assert.equal(u.widthCm,35);assert.equal(u.leftCm,77);assert.equal(u.rightCm,77);
assert(Math.abs(u.insideCm-33.5)<1e-6);
console.log('Arque Mob 0.33: peças, divisões válidas, cm/mm, vãos U e preservação 2D/3D: OK');