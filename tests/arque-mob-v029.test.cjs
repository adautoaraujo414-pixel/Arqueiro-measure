'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,why] of [
 ["version:'0.35'",'v0.35'],
 ["function sheetLabel(a,b,label,selected=false,preview=false,lineId=null){",'etiqueta com ID'],
 ["const x=(a.x+b.x)/2,y=(a.y+b.y)/2",'etiqueta centralizada sobre linha'],
 ["data-line-id=", 'editar medida tocando na etiqueta'],
 ["out+=sheetLabel(line.a,line.b,label,sel,false,line.id)",'etiqueta clicável para medida salva'],
 ["out+=sheetLabel(d.a,d.b", 'medida sobre linha durante arraste'],
 ["line[h.end]=snapped;line.cm=rd(sheetLength(line.a,line.b)/sheetCmScale)",'medida muda enquanto arrasta alça'],
 ["pointer-events=\"none\"", 'ponto de origem não bloqueia alça'],
 ["function sheetPinchMove(){",'pinça do zoom'],
 ["function sheet2dRedo(){",'refazer'],
 ["function sheetPageAdd(){",'várias folhas'],
 ["function sheetPhotoRead(file){",'foto anotável'],
 ["function initializeSheet2dCalculator(){",'calculadora'],
 ["function scene3d(){",'preservar 3D oculto']
])assert(s.includes(token),why+' ausente');
assert(!s.includes(" · aprox"),'rótulo não deve deslocar a medida');
assert(!s.includes('data-view="ambient"')&&!s.includes('data-view="iso"'));
const start=s.indexOf('<script>')+8,end=s.lastIndexOf('</script>');assert(start>=8&&end>start);
const js=s.slice(start,end);new Function(js);
const i=js.indexOf('function sheetLabel('),j=js.indexOf('function sheetScreenPoint(',i);
assert(i>=0&&j>i);const R=(x,y,w,h,fill,stroke,extra)=>({kind:'rect',x,y,w,h,fill,stroke,extra});
const T=(x,y,text,size,color,anchor,extra)=>({kind:'text',x,y,text,size,color,anchor,extra});
const fn=new Function('R','T','st','clamp',js.slice(i,j)+';return sheetLabel;')(R,T,{sheet2dLabelSize:10},(x,min,max)=>Math.max(min,Math.min(max,x)));
for(const [a,b] of [[{x:100,y:100},{x:420,y:100}],[{x:420,y:100},{x:420,y:510}]]){
 // Actual implementation returns SVG markup, so evaluate with SVG helpers as in app.
 const RR=(x,y,w,h,fill,stroke,extra)=>'<rect x="'+x+'" y="'+y+'" width="'+w+'" height="'+h+'" '+extra+'/>';
 const TT=(x,y,val,size,color,anchor,extra)=>'<text x="'+x+'" y="'+y+'" '+extra+'>'+val+'</text>';
 const label=new Function('R','T','st','clamp',js.slice(i,j)+';return sheetLabel;')(RR,TT,{sheet2dLabelSize:10},(x,min,max)=>Math.max(min,Math.min(max,x)))(a,b,'210,7 cm',true,false,17);
 const cx=(a.x+b.x)/2,cy=(a.y+b.y)/2;
 assert(label.includes('data-line-id="17"'),'etiqueta editável');
 const m=label.match(/<rect x="([^"]+)" y="([^"]+)" width="([^"]+)" height="([^"]+)"/);
 assert(m,'retângulo não gerado');
 assert(Math.abs(Number(m[1])+Number(m[3])/2-cx)<.01,'cota fora do eixo horizontal');
 assert(Math.abs(Number(m[2])+Number(m[4])/2-cy)<.01,'cota fora do eixo vertical');
}
console.log('Arque Mob v0.35: etiqueta horizontal central, edição e medida ao vivo OK');