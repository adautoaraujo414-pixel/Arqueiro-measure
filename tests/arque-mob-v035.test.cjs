'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const source=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,name] of [
 ["version:'0.35'",'versionamento'],
 ['sheet2dPenOnly:false','opção da S Pen'],
 ["if(st.sheet2dPenOnly&&e.pointerType==='touch')",'um dedo move a folha'],
 ["data-ribbon=\"penOnly\"",'botão S Pen'],
 ["st.sheetTouchPan.last=now",'movimentação com um dedo'],
 ["function sheetPinchMove(){",'zoom com dois dedos'],
 ["linked.cm=rd(sheetLength(linked.a,linked.b)/sheetCmScale)",'cotas estimadas seguem ponto conectado'],
 ["parentId:sheetPieceParent(piece)?.id||null",'contenção da peça interna'],
 ['function sheetPieceCenter(){','centralização das peças'],
 ["function sheetMagicStraight(points)",'riscos paralelos'],
 ["function sheetMagicXCross(first,second)",'X para apagar'],
 ["function sheetMagicLayout(piece,count,dividerCm",'divisões com espessuras reais'],
 ["photoLocked",'campo de foto travada'],
 ['id=\"photoLocked\"','controle de foto travada'],
 ['function sheetPhotoRead(file){','foto com desenho por cima'],
 ["function sheetCutEstimate(){",'prévia de chapas'],
 ['Esquema estimado da chapa','visualizar chapas com peças'],
 ['function sheetCutGroups(){','agrupar peças iguais'],
 ['function sheetCutSet(','marcar cortou'],
 ['sheet2dShape:\'rect\'','formas de croqui'],
 ['sheet2dLinePattern:\'solid\'','linhas tracejadas'],
 ['data-ribbon=\"shapeKind\"','formas no cabeçalho'],
 ['data-ribbon=\"linePattern\"','traçado no cabeçalho'],
 ['function sheetPageAdd(){','folhas múltiplas'],
 ['function sheet2dRedo(){','desfazer/refazer'],
 ['function scene3d(){','código 3D preservado']
])assert(source.includes(token),name+' ausente');
assert(!source.includes('data-view="ambient"')&&!source.includes('data-view="iso"'),'3D deve ficar oculto');
const begin=source.indexOf('<script>')+8,end=source.lastIndexOf('</script>');
const script=source.slice(begin,end);new Function(script);
const pos=script.indexOf('function sheetMagicLayout('),finish=script.indexOf('function sheetPieceSvg(',pos);
assert(pos>=0&&finish>pos);
const calc=new Function('sheetPieceCm','sheetCmScale',script.slice(pos,finish)+';return sheetMagicLayout;')(n=>n/2,2);
const outer={id:1,x:200,y:0,w:400,h:154,edgeCm:1.8,kind:'rect'};
const layout=calc(outer,4,1.5,'vertical');
assert.equal(layout.positionsCm.length,3);
assert(Math.abs(4*layout.gapCm+3*layout.dividerCm+2*layout.edgeCm-200)<.00001);
assert(Math.abs(layout.gapCm-layout.lastGapCm)<.00001);
assert.throws(()=>calc({...outer,kind:'ellipse'},4,1.5,'vertical'));
assert.throws(()=>calc({...outer,w:20},20,2,'vertical'));
const a=script.indexOf('function sheetMagicStraight('),b=script.indexOf('function sheetMagicEraseAt(',a);
assert(a>=0&&b>a);
const magic=new Function('rd',script.slice(a,b)+';return {sheetMagicStraight,sheetMagicXCross};')(v=>Math.round(v*10)/10);
assert(magic.sheetMagicStraight([{x:20,y:20},{x:70,y:20}]));
assert(!magic.sheetMagicStraight([{x:20,y:20},{x:30,y:50},{x:70,y:20}]));
assert(magic.sheetMagicXCross([{x:10,y:10},{x:50,y:50}],[{x:10,y:50},{x:50,y:10}]));
assert.equal(magic.sheetMagicXCross([{x:10,y:10},{x:50,y:10}],[{x:10,y:20},{x:50,y:20}]),null);
console.log('Arque Mob 0.35: geometria de MDF, caneta mágica, cotas, foto, S Pen, formas e prévia de chapas: OK');
