/* Automated verification of cut allocation and loss accounting. */
const fs=require('fs'),vm=require('vm'),assert=require('assert/strict');
const ctx={};vm.runInNewContext(fs.readFileSync('app/src/main/assets/cut.js','utf8'),ctx);
const calc=ctx.ArqueCut.calculate;
const empty=calc({width:2750,height:1830,pieces:[]});
assert.equal(empty.sheetCount,0);
const single=calc({width:2750,height:1830,kerf:3,pieces:[{name:'Lateral',w:2000,h:600,qty:1}]});
assert.equal(single.sheetCount,1);assert.equal(single.placedPieces,1);assert.equal(single.usedArea,1200000);
const two=calc({width:2750,height:1830,kerf:3,pieces:[{name:'Lateral',w:2000,h:600,qty:2}]});
assert.equal(two.sheetCount,1);assert.equal(two.placedPieces,2);
const overflow=calc({width:2750,height:1830,kerf:3,pieces:[{name:'Gigante',w:2800,h:2000,qty:1}]});
assert.equal(overflow.unfit.length,1);assert.equal(overflow.placedPieces,0);
const grain=calc({width:2750,height:1830,kerf:3,pieces:[{name:'Veio fixo',w:1800,h:2700,qty:1,grain:true}]});
assert.equal(grain.unfit.length,1);
const rotated=calc({width:2750,height:1830,kerf:3,pieces:[{name:'Sem veio',w:1800,h:2700,qty:1,rotate:true}]});
assert.equal(rotated.placedPieces,1);
for(const sheet of two.sheets){for(let i=0;i<sheet.pieces.length;i++)for(let j=i+1;j<sheet.pieces.length;j++){const a=sheet.pieces[i],b=sheet.pieces[j];assert(a.x+a.w<=b.x||b.x+b.w<=a.x||a.y+a.h<=b.y||b.y+b.h<=a.y,'Peças sobrepostas');}}
assert.throws(()=>calc({width:2750,height:1830,pieces:[{w:-100,h:300,qty:1}]}));
new Function(fs.readFileSync('app/src/main/assets/app.js','utf8'));
console.log('Plano de corte: testes passaram.');
