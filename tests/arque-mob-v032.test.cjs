'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,meaning] of [
 ["version:'0.32'",'versão de armazenamento'],
 ['function sheetFitA4(){','ajuste automático do A4'],
 ['sheetFitA4();render();loadFromMeasure();','enquadrar ao iniciar'],
 ["$('fit').onclick=()=>{if(st.view==='sheet2d'){sheetFitA4();",'enquadramento manual'],
 ['id="calcCutFlow"','corte sem janela de cadastro'],
 ['id="calcCutName"','nome da peça'],
 ['id="calcCutOK"','avançar com OK'],
 ['function cutNext(){','sequência da calculadora'],
 ["if(cutFlow.step!==3){cutFlow.step++;",'seguir para o próximo campo'],
 ["persist();cutReset();toast('Peça salva no corte. Próxima peça.')",'salvar e avançar'],
 ['function sheetCutGroups(){','agrupar cortes iguais'],
 ['function sheetCutSet(','verde/vermelho do corte'],
 ['function sheetMagicLayout(','divisão do quadro'],
 ['lastGapCm:lastGap','conferir último vão'],
 ['const bg=','representação de laterais do quadro'],
 ['function sheet2dUndo(){','preservar desfazer'],
 ['function sheetPinchMove(){','preservar zoom com pinça'],
 ['function scene3d(){','preservar 3D oculto']
])assert(s.includes(token),'Ausente: '+meaning);
const i=s.indexOf('<script>')+8,j=s.lastIndexOf('</script>');assert(i>=8&&j>i);const js=s.slice(i,j);new Function(js);
const a=js.indexOf('function sheetBounds(){'),b=js.indexOf('function sheetInside(',a);assert(a>=0&&b>a);
for(const [vw,vh] of [[1180,618],[820,1018],[390,685]]){
 const st={zoom:1,sheet2dPanX:90,sheet2dPanY:55};
 const $=()=>({clientWidth:vw,clientHeight:vh});
 const clamp=(v,low,high)=>Math.min(high,Math.max(low,v));
 const fit=new Function('st','$','clamp',js.slice(a,b)+';return sheetFitA4;')(st,$,clamp);
 fit();const width=1000/st.zoom,height=width*vh/vw,x=500-width/2-st.sheet2dPanX,y=320-height/2-st.sheet2dPanY;
 assert(x<=160&&x+width>=840&&y<=-161&&y+height>=801,'folha A4 cortada');
 assert(Math.max(680/width,962/height)>.93,'folha A4 muito pequena');
 assert.equal(st.sheet2dPanX,0);assert.equal(st.sheet2dPanY,0);
}
const d=js.indexOf('function sheetMagicLayout('),e=js.indexOf('function sheetPieceSvg(',d);assert(d>=0&&e>d);
const layout=new Function('sheetPieceCm','sheetCmScale',js.slice(d,e)+';return sheetMagicLayout;')(n=>n/2,2);
const p={w:500,h:320,edgeCm:1.8},l=layout(p,4,1.5,'vertical');
assert.equal(l.positionsCm.length,3);
assert(Math.abs(l.gapCm-l.lastGapCm)<1e-6);
assert(Math.abs(2*l.edgeCm+4*l.gapCm+3*l.dividerCm-l.spanCm)<1e-6);
assert.throws(()=>layout({w:20,h:20,edgeCm:3},9,8,'vertical'));
console.log('Arque Mob v0.32: A4 maximizado, lançamentos pelo OK, 4 vãos e preservação OK.');
