'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const src=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,purpose] of [
 ["version:'0.28'",'versão correta'],['id="sheetRibbon"','cabeçalho centralizado'],
 ['id="sheetContextBar"','menu específico da ferramenta'],['id="sheetPages"','abas de folhas'],
 ['function sheetPageCapture(){','gravar folha'],['function sheetPageRestore(id){','restaurar folha'],
 ['function sheetPageAdd(){','nova folha'],['function sheetPhotoRead(file){','importar foto'],
 ['id="sheetPhotoFile"','seleção de foto'],['data-sheet-tool="photo"','mover foto'],
 ['function sheetPhotoOptions(){','opções da foto'],['function sheetLabel(','medida sobre o traço'],
 ['function sheetPinchMove(){','zoom de dois dedos ancorado'],['function sheet2dRedo(){','refazer'],
 ['function sheet2dUndo(){','desfazer'],['data-sheet-tool="free"','escrita livre'],
 ['data-sheet-tool="note"','nota livre'],['function sheetNoteEditor(){','editar nota'],
 ['function sheetThicknessPolygon(','espessura quadrada'],['function sheetSnapTarget(','encaixe'],
 ['function sheetSplitAt(','fusão de linhas'],['function initializeSheet2dCalculator(){','calculadora'],
 ['function scene3d(){','3D preservado mas oculto'],
 ['sheetPageInit();render();loadFromMeasure();','inicialização das páginas'],
 ['sheetPages:(sheetPageCapture(),st.sheetPages)','persistência das páginas'],
 ["if(d.moved){sheetAddSegment(d.start,p);st.sheet2dAnchor=null;}else{st.sheet2dAnchor=null;}","sem linha por toque isolado"],
 ["st.sheetPhoto=d.photo===undefined?st.sheetPhoto:d.photo","desfazer foto até null"]
])assert(src.includes(token),purpose);
assert(!src.includes('data-view="ambient"')&&!src.includes('data-view="iso"'),'3D deve permanecer oculto');
assert(!src.includes("if(d.moved||st.sheet2dAnchor){if(!sheetAddSegment"),'regressão: clique criou linha');
assert(!src.includes('const dist=sheetDist(g.from,p);if(dist>2&&!g.moved){sheetCheckpoint();g.moved=true}st.sheetPhoto.x=rd(g.x+p.x-g.from.x);st.sheetPhoto.y=rd(g.y+p.y-g.from.y);render();return;}\n if(st.sheet2dPhotoDrag){const moved='),'regressão foto solta');
const start=src.indexOf('<script>')+8,end=src.lastIndexOf('</script>');assert(start>=8&&end>start);new Function(src.slice(start,end));
console.log('Arque Mob 0.28: folhas múltiplas, foto, toolbar e linhas por arraste: OK');
