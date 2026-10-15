'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [key,label] of [
 ["version:'0.34'",'Versão 0.34'],
 ['sheet2dEndZoom:false','Lupa desativada de início'],
 ["st.sheet2dEndZoom=false;st.view='sheet2d';sheetPageInit()",'Desligar lupa em projetos anteriores'],
 ['Pontas invisíveis','Área sensível sem desenhos'],
 ['fill="transparent" stroke="none" pointer-events="all"','Alça invisível'],
 ["if(sel&&st.sheet2dTool==='select')",'Editar pontas somente no modo Selecionar'],
 ['const onLabel=!!e.target.closest','Etiquetas clicáveis'],
 ['if(st.sheet2dTool===\'draw\'&&line&&!onLabel)','Arraste a partir de linha'],
 ['function sheetAddSegment(a,b,startTarget=null)','Unir ponta de partida'],
 ['if(startTarget)sheetSplitAt(startTarget,a)','Dividir em T na origem'],
 ['sheetAddSegment(d.start,p,d.startTarget||null)','Salvar encontro na origem'],
 ['function sheetPinchMove(){','Pinça permanece'],
 ['function sheetMagicLayout(','Caneta Mágica permanece'],
 ['function sheetCutGroups(){','Plano de corte permanece'],
 ['function sheetPageAdd(){','Múltiplas folhas permanecem'],
 ['function sheetPhotoRead(file){','Foto permanece'],
 ['function scene3d(){','3D continua preservado e oculto']
])assert(s.includes(key),label+' ausente');
assert(!s.includes('Zoom nas pontas')&&!s.includes('⌕')&&!s.includes('id="sheetZoomEnds"'),'Lupas ou controles indevidos');
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'),'3D deve permanecer oculto');
const script=s.slice(s.indexOf('<script>')+8,s.lastIndexOf('</script>'));
new Function(script);
const start=script.indexOf('function sheetProjection('),end=script.indexOf('function sheetHitLine(',start);
assert(start>=0&&end>start);
const st={sheet2dLines:[{id:1,a:{x:200,y:200},b:{x:500,y:200},cm:150}],sheet2dAutoAlign:true,sheet2dSquare:true,sheet2dSnapCm:8,sheet2dFuse:true,sheet2dNextId:2};
const clamp=(x,a,b)=>Math.max(a,Math.min(x,b)),rd=x=>Math.round(x*10)/10;
const dist=(a,b)=>Math.hypot(a.x-b.x,a.y-b.y);
const engine=new Function('st','clamp','rd','sheetDist','sheetPoint','sheetCmScale',script.slice(start,end)+';return {sheetProjection,sheetSplitAt,sheetSnapTarget};')(st,clamp,rd,dist,p=>({...p}),2);
const pt={x:350,y:200},hit=engine.sheetProjection(pt,st.sheet2dLines[0]);
assert.equal(hit.dist,0);assert(Math.abs(hit.t-.5)<1e-10);
assert(engine.sheetSplitAt({lineId:1,at:hit.t},pt));
assert.equal(st.sheet2dLines.length,2);
assert.deepEqual(st.sheet2dLines[0].b,pt);assert.deepEqual(st.sheet2dLines[1].a,pt);
st.sheet2dFuse=false;
const separate=engine.sheetSplitAt({lineId:1,at:.4},{x:260,y:200});
assert.equal(separate,false,'Encostar sem dividir');
assert.equal(st.sheet2dLines.length,2);
console.log('Arque Mob 0.34: encontros limpos, T, desativação da lupa e compatibilidade OK');
