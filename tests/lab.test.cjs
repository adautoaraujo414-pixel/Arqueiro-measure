/* Laboratorio 2D: geometria em mm, medidas de origem e historico por obra. */
const assert=require('node:assert/strict');
globalThis.ArqueModules=require('../app/src/main/assets/modules.js');
globalThis.ArqueVisual=require('../app/src/main/assets/lab-visual.js');
const L=require('../app/src/main/assets/lab.js');
const p={rooms:[
 {id:'cozinha',name:'Cozinha',measurements:[{id:'m1',value:3170,kind:'Parede',target:'parede pia',source:'Bluetooth'},{id:'m2',value:580,kind:'Profundidade',source:'manual'}]},
 {id:'quarto',name:'Quarto',measurements:[]}
],photos:[]};
const a=L.layout(p,'cozinha'),other=L.layout(p,'quarto');
assert.notEqual(a,other,'ambientes independentes');
assert.equal(a.confirmed,false,'medida inicial nao e declarada real');
assert.throws(()=>L.layout(p,'inexistente'),/Selecione um ambiente/);
const old=L.snapshot(a);
assert.equal(L.attach(a,p.rooms[0],'m1','width'),3170);
assert.equal(a.width,3170);
assert.equal(a.roomRefs.width.id,'m1');
assert.equal(a.confirmed,true);
assert.match(L.linkStatus(a.roomRefs.width,p.rooms[0]),/Bluetooth/);
assert.equal(p.rooms[0].measurements[0].value,3170,'leitura original intacta');
const base=L.add(a,'base',100,200);
assert.equal(base.w,800);
L.attach(a,p.rooms[0],'m2','d',base.id);
assert.equal(base.d,580,'medicao vinculada a profundidade da base');
assert.equal(base.refs.d.id,'m2');
assert.equal(p.rooms[0].measurements[1].value,580,'origem intacta');
L.place(base,{x:400,y:600,w:900,height:730});
assert.equal(base.w,900);assert.equal(base.height,730);
assert.match(L.svg(a,'plan',base.id),/Armário base/);
assert.match(L.svg(a,'front',base.id),/Vista frontal 2D/);
assert.throws(()=>L.add(a,'mesa-3d',0,0),/desconhecido/);
assert.throws(()=>L.attach(a,p.rooms[1],'m1','width'),/não encontrada/);
p.rooms[0].measurements[0].value=3200;
assert.match(L.linkStatus(a.roomRefs.width,p.rooms[0]),/alterada.*conferir/);
assert.equal(L.undo(a),true);
assert.equal(a.items[0].d,560,'desfaz vinculo de medida');
assert.equal(L.redo(a),true);
assert.equal(a.items[0].d,580,'refaz ajuste');
assert.equal(other.items.length,0,'outro ambiente preservado');
assert.equal(old.confirmed,false,'historico anterior mantido');
const html=L.screen(p);
assert(html.includes('labBoard')&&html.includes('labMeasure'),'editor e lista de medidas presentes');
assert(html.includes('Ambiente técnico 3D'),'laboratorio abre em vista construtiva espacial');
assert(html.includes('Foto de referência')&&html.includes('Vista frontal'),'fotografia e vista frontal presentes');
const saved=JSON.parse(JSON.stringify(p));
assert.equal(saved.labLayouts.cozinha.width,3170,'layout pronto para armazenamento local e backup');
console.log('Laboratorio 2D: geometria, vinculos e historico OK');
