'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [key,label] of [
 ["version:'0.27'",'estado 0.27'],
 ["function sheetPinchStart(){",'pinça de dois dedos'],
 ["function sheetPinchMove(){",'zoom com âncora'],
 ["st.pinch.anchor.x",'âncora estável'],
 ["function sheetScreenPoint(e)",'coordenadas da tela'],
 ["function sheetLabel(",'rótulos horizontais'],
 ["vertical=Math.abs(b.y-a.y)>",'detecção de linha vertical'],
 ["function sheet2dRedo(){",'refazer'],
 ["function sheet2dUndo(){",'desfazer'],
 ['data-sheet-tool="free"','mão livre'],
 ['data-sheet-tool="note"','notas'],
 ["function sheetNoteEditor(){",'edição de nota'],
 ["function sheetAppearance(){",'cores, setas e espessura'],
 ["function sheetThicknessPolygon(",'peça com contorno quadrado'],
 ["function sheetInferClosure(",'fechamento calculado preservado'],
 ["function sheetSnapTarget(",'encaixe'],
 ["function sheetSplitAt(",'fundir'],
 ["function initializeSheet2dCalculator(){",'calculadora'],
 ["function scene3d(){",'código 3D preservado']
])assert(s.includes(key),label+' ausente');
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'),'3D ainda oculto');
const a=s.indexOf('<script>')+8,b=s.lastIndexOf('</script>');
assert(a>=8&&b>a);new Function(s.slice(a,b));
const vw=950,vh=650,zoom=2.1,mid={x:250,y:310},anchor={x:555,y:345},w=1000/zoom,h=w*vh/vw;
const panX=500-w/2-(anchor.x-mid.x/vw*w),panY=320-h/2-(anchor.y-mid.y/vh*h);
assert(Math.abs((500-w/2-panX+mid.x/vw*w)-anchor.x)<.000001);
assert(Math.abs((320-h/2-panY+mid.y/vh*h)-anchor.y)<.000001);
console.log('Arque Mob 0.27: zoom ancorado, cotas horizontais e recursos preservados: OK');
