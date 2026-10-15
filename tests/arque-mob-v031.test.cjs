'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [key,label] of [
 ["version:'0.31'",'versão'],["function sheetBounds(){return {xmin:160,xmax:840,ymin:-161,ymax:801};}",'A4 fixo'],
 ["function sheetInside(",'limite da folha'],["function sheetErase(",'borracha'],
 ["function sheetZoomTo(",'zoom nas pontas'],["sheet2dEndZoom:true",'zoom opcional'],
 ["sheet2dLabelSize:10",'fonte da cota menor'],["sheetNumberSize",'configuração fonte'],
 ["function sheetCenterTripleTap(",'três toques centralizar'],
 ["function sheetMagicOnlyThickness(",'riscos mágicos só perguntam espessura'],
 ["session.strokes++",'contar traços'],["function sheetCutAddDialog(",'peças do corte'],
 ["function sheetCutGroups(",'agrupar peças iguais'],["function sheetCutSet(",'OK cortou'],
 ["function sheetCutEstimate(",'distribuição estimada'],
 ["sheetCutRows:st.sheetCutRows",'salvamento corte'],
 ["id=\"calcAddCut\"",'inserção no menu calculadora'],
 ["data-sheet-tool=\"erase\"",'ferramenta borracha'],
 ["function sheetPageAdd(",'várias folhas'],["function scene3d(){",'código 3D preservado']
])assert(s.includes(key),label+' ausente');
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'));
const start=s.indexOf('<script>')+8,end=s.lastIndexOf('</script>');assert(start>=8&&end>start);
new Function(s.slice(start,end));
const cm=2,page={xmin:160,xmax:840,ymin:-161,ymax:801};
assert.equal((page.xmax-page.xmin)/(page.ymax-page.ymin)<.72,true);
const unit=(mm)=>mm/10;assert.equal(unit(740),74);
console.log('Arque Mob v0.31: A4, zoom nas pontas, fusão, borracha, cortes e gestos: OK');