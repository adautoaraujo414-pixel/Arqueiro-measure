'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
const required=[
 ["version:'0.35'",'versão e persistência'],
 ['Folha 2D • versão 0.35','identificação na tela'],
 ['data-sheet-tool="free"','mão livre'],
 ['data-sheet-tool="highlight"','destaque tipo marcador'],
 ["st.sheet2dTool==='free'||st.sheet2dTool==='highlight'",'escrever sem selecionar'],
 ['sheet2dHighlightWidth:14','espessura separada do marcador'],
 ['highlightWidth:st.sheet2dHighlightWidth','marcador salvo na folha'],
 ['stroke-opacity=','opacidade de destaque'],
 ['highlighter:!!path.highlighter','identificar traços destacados'],
 ['function sheetMagicXCross(','reconhecimento de X'],
 ['function sheetMagicEraseAt(','apagar elemento atingido'],
 ['if(sheetMagicEraseAt(cross))return;','apagar antes da divisão'],
 ['sheetMagicOnlyThickness(session.strokes)','preservar divisão de vãos'],
 ['function sheetMagicLayout(','descontos das divisórias'],
 ['function sheet2dUndo(){','desfazer disponível'],
 ['function sheetPageAdd(){','múltiplas folhas'],
 ['function sheetPhotoRead(file){','foto preservada'],
 ['function sheetPinchMove(){','zoom preservado'],
 ['function scene3d(){','código 3D preservado']
];
for(const [key,name] of required)assert(s.includes(key),name+' ausente');
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'),'3D continua oculto');
const a=s.indexOf('<script>')+8,b=s.lastIndexOf('</script>');assert(a>=8&&b>a);const js=s.slice(a,b);new Function(js);
const first=js.indexOf('function sheetMagicXCross('),last=js.indexOf('function sheetErase(',first);assert(first>=0&&last>first);
const st={sheet2dFree:[],sheet2dLines:[],sheet2dPieces:[],sheet2dNotes:[]};let calls=0,checkpoint=0;
const rd=n=>Math.round(n*10)/10,clamp=(n,a,b)=>Math.max(a,Math.min(n,b));
const getPiece=p=>st.sheet2dPieces.find(q=>p.x>=q.x&&p.y>=q.y&&p.x<=q.x+q.w&&p.y<=q.y+q.h);
const functions=new Function('st','rd','clamp','sheetPieceAt','sheetCheckpoint','persist','render','toast',js.slice(first,last)+';return {sheetMagicXCross,sheetMagicEraseAt}')(st,rd,clamp,getPiece,()=>checkpoint++,()=>calls++,()=>{},()=>{});
const x=[[{x:100,y:100},{x:140,y:140}],[{x:100,y:140},{x:140,y:100}]];
assert.deepEqual(functions.sheetMagicXCross(...x),{x:120,y:120},'X precisa cruzar na área central');
assert.equal(functions.sheetMagicXCross(x[0],[{x:100,y:102},{x:140,y:142}]),null,'riscos paralelos não são X');
assert.equal(functions.sheetMagicXCross(x[0],[{x:230,y:140},{x:270,y:100}]),null,'dois riscos distantes não são X');
st.sheet2dPieces=[{id:22,x:80,y:80,w:100,h:100}];
st.sheet2dLines=[{id:3,a:{x:90,y:120},b:{x:150,y:120}}];
st.sheet2dFree=[{id:7,width:2,points:[{x:110,y:120},{x:135,y:120}]}];
assert(functions.sheetMagicEraseAt({x:120,y:120}));
assert.equal(st.sheet2dFree.length,0,'apagar escrita atingida primeiro');
assert.equal(st.sheet2dLines.length,1,'preservar linha sobreposta');
assert.equal(st.sheet2dPieces.length,1,'preservar peça de fundo');
assert(functions.sheetMagicEraseAt({x:120,y:120}));
assert.equal(st.sheet2dLines.length,0,'apagar linha após escrita');
assert.equal(st.sheet2dPieces.length,1,'não apagar peça sem necessidade');
assert.equal(functions.sheetMagicEraseAt({x:999,y:999}),false,'X fora da folha não remove nada');
assert.equal(checkpoint,2,'cada exclusão pode ser desfeita');
assert.equal(calls,2,'cada exclusão é salva');
console.log('Arque Mob 0.35: escrita sobreposta, marcador e X seguro preservando divisões OK');
