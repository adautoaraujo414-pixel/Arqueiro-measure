'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
for(const [token,label] of [
 ["version:'0.33'",'Versão persistente'],['function validModuleWidth(', 'Validação de redimensionamento'],
 ['data-resize-module=', 'Alça 3D'],["kind:'moduleResize'",'Arraste de largura'],
 ['function simulateSheets(', 'Simulação de faixas'],['function showCutSimulation(', 'Tela de simulação'],
 ['st.sheetKerf=kerf;st.sheetTrim=trim','Parâmetros de refilo/serra'],
 ['function cutCsv()', 'Peças exportáveis'],['caseMaterial','Materiais separados']
]) assert(s.includes(token),label+' ausente');
const open=s.indexOf('<script>')+8,close=s.lastIndexOf('</script>');
assert(open>8&&close>open);new Function(s.slice(open,close));
const js=s.slice(open,close),start=js.indexOf('function simulateSheets('),end=js.indexOf('function showCutSimulation(){');
assert(start>=0&&end>start,'Simulador não isolado');
const cfg={sheetL:235,sheetW:185,sheetTrim:3,sheetKerf:.32};
const sim=new Function('st','planAll','const rd=n=>Math.round(n*10)/10;\n'+js.slice(start,end)+'\nreturn simulateSheets;')(cfg,()=>[]);
const pieces=[
 {q:2,name:'lateral',w:77,h:55,material:'MDF 18 mm',status:'conferir'},
 {q:1,name:'base',w:105,h:56,material:'MDF 18 mm',status:'conferir'},
 {q:1,name:'fundo',w:100,h:70,material:'MDF 6 mm',status:'pendente'},
 {q:1,name:'fora',w:250,h:20,material:'MDF 18 mm',status:'pendente'}
];
const result=sim(pieces);
assert.equal(result.total,4);assert.equal(result.unfit.length,1);assert.equal(result.lots.length,2);assert.equal(result.allValidated,false);
let placed=0;
for(const l of result.lots)for(const sh of l.sheets){
 for(const p of sh.placed){
  assert(p.x>=cfg.sheetTrim-1e-6&&p.y>=cfg.sheetTrim-1e-6);
  assert(p.x+p.w<=cfg.sheetL-cfg.sheetTrim+1e-4);
  assert(p.y+p.h<=cfg.sheetW-cfg.sheetTrim+1e-4);
  assert.equal(p.material,l.material);placed++;
 }
 for(let i=0;i<sh.placed.length;i++)for(let j=i+1;j<sh.placed.length;j++){
  const a=sh.placed[i],b=sh.placed[j];
  const overlap=a.x<b.x+b.w-1e-5&&b.x<a.x+a.w-1e-5&&a.y<b.y+b.h-1e-5&&b.y<a.y+a.h-1e-5;
  assert(!overlap,`Peças sobrepostas: ${a.name} e ${b.name}`);
 }
}
assert.equal(placed,4);
assert.throws(()=>sim(pieces,{sheetL:235,sheetW:185,sheetTrim:100,sheetKerf:.32}));
console.log('Arque Mob v0.22: dimensões, materiais, limites e não sobreposição: OK');
