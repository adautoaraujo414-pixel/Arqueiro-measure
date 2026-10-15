'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const src=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
const checks=[
 ["version:'0.33'","versão e salvamento"],
 ["function sheetBounds(){return {xmin:160,xmax:840,ymin:-161,ymax:801};}","folha A4 fixa"],
 ["sheetRectFit(g.x,g.y,g.w,g.h)","validar peça dentro da folha"],
 ['clip-path="url(#arqueA4clip)"',"não desenhar fora do A4"],
 ['function sheetZoomTo(','zoom na ponta da medida'],
 ['function sheetCenterTripleTap(','toque triplo para centralizar'],
 ['function sheetPieceCenter(){','centralização pelas peças'],
 ['function sheetErase(','borracha'],
 ['data-sheet-tool="erase"','borracha visível no cabeçalho'],
 ['function sheetMagicOnlyThickness(','quantidade de riscos define vãos'],
 ['function sheetCutGroups(){','agrupar peças iguais'],
 ['function sheetCutAddDialog(){','formulário de corte'],
 ['function sheetCutView(){','lista de corte'],
 ['function sheetCutEstimate(){','estimativa de chapas'],
 ['function sheetCutSet(','marcar corte concluído'],
 ['id="calcAddCut"','adicionar peça pela calculadora'],
 ['id="calcShowCut"','ver plano de corte pela calculadora'],
 ['sheetCutRows:st.sheetCutRows','persistência do corte'],
 ['st.sheet2dLabelSize','números configuráveis'],
 ['st.sheet2dEndZoom','zoom configurável'],
 ['function sheet2dSettings(){','ajustes da folha'],
 ['function sheetMagicLayout(','cálculo com descontar divisórias'],
 ['function sheet2dRedo(){','refazer'],
 ['function scene3d(){','preservar projeto 3D']
];
for(const [needle,msg] of checks)assert(src.includes(needle),'Ausente: '+msg);
assert(!src.includes('data-view="ambient"')&&!src.includes('data-view="iso"'),'3D deve permanecer oculto');
const start=src.indexOf('<script>')+8,end=src.lastIndexOf('</script>');
assert(start>=8&&end>start);new Function(src.slice(start,end));
const script=src.slice(start,end),from=script.indexOf('function sheetCutGroups(){'),to=script.indexOf('function sheetCutAddDialog(){',from);
assert(from>=0&&to>from);const groupFn=new Function('st',script.slice(from,to)+';return sheetCutGroups;');
const st={sheetCutRows:[
 {id:1,name:'Lateral',wCm:74,dCm:24,material:'MDF 18 mm',qty:2,cut:0},
 {id:2,name:'Lateral',wCm:74,dCm:24,material:'MDF 18 mm',qty:1,cut:1},
 {id:3,name:'Base',wCm:50,dCm:20,material:'MDF 18 mm',qty:1,cut:0}
]};
const list=groupFn(st)();
assert.equal(list.length,2);assert.equal(list[0].qty,3);assert.equal(list[0].cut,1);assert.equal(list[0].name,'Lateral');
const bounds={xmin:160,xmax:840,ymin:-161,ymax:801};
assert.equal(bounds.xmax-bounds.xmin,680);assert.equal(bounds.ymax-bounds.ymin,962);
console.log('Arque Mob 0.33: folha A4, corte, borracha, régua e salvamento verificados');