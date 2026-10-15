'use strict';
const fs=require('node:fs'),a=require('node:assert/strict');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,name] of [
 ["version:'0.32'",'versão'],
 ['function sheetPageInit(){','criar primeira folha'],
 ['function sheetPageAdd(){','múltiplas folhas'],
 ['function sheetPageOpen(','alternar folhas'],
 ['function sheetPageSerialize(){','salvamento sem foto duplicada'],
 ['sheetPages:(sheetPageCapture(),st.sheetPages)','persistência por folha'],
 ['function sheetPhotoRead(file){','importação de foto'],
 ['function sheetPhotoOptions(){','propriedades da foto'],
 ['function sheetPageTabs(){','abas no cabeçalho'],
 ['id="sheetRibbon"','ferramentas no cabeçalho'],
 ['id="sheetContextBar"','menu por ferramenta'],
 ['data-sheet-tool="free"','mão livre'],
 ['data-sheet-tool="note"','nota'],
 ['function sheet2dRedo(){','refazer'],
 ['function sheetPinchMove(){','zoom suave'],
 ['function sheetSnapTarget(','encaixe de linhas'],
 ['function sheetSplitAt(','modo fundir'],
 ["cmSource:inferred?.source??'estimado'",'medida visual preservada'],
 ["line.cmSource!=='estimado'",'não deduzir medidas a partir de prévias'],
 ["if(d.moved){sheetAddSegment(d.start,p)",'linhas apenas arrastando'],
 ['function sheetLabel(','etiqueta de cm sobre a linha'],
 ['st.sheet2dStrokeWidth','controle de espessura'],
 ['function sheetNoteEditor(){','nota redimensionável'],
 ['function initializeSheet2dCalculator(){','calculadora'],
 ['function scene3d(){','3D preservado']
])a(s.includes(token),name+' ausente');
a(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'),'3D precisa continuar oculto');
const start=s.indexOf('<script>')+8,end=s.lastIndexOf('</script>');
a(start>=8&&end>start);new Function(s.slice(start,end));
console.log('Arque Mob v0.32: linhas arrastáveis com cota, fotos, páginas, menu e legado OK');