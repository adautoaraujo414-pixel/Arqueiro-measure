/* Teste do laboratorio completo: alinhamento, cooktop e esboço com toque real. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),{JSDOM}=require('jsdom');
const P='app/src/main/assets/';
const dom=new JSDOM('<!doctype html><html><body><div id="arqueLab"></div></body></html>',
 {url:'https://arque.test/',runScripts:'outside-only',pretendToBeVisual:true});
const w=dom.window,doc=w.document;
for(const file of ['modules.js','kitchen-catalog.js','lab-alignment.js','lab-visual.js','workshop.js','module-ui.js','lab.js']){
 w.eval(fs.readFileSync(P+file,'utf8'));
}
const M=w.ArqueModules;
const base=M.instantiate({id:'base',spec:M.standard()},100,500);base.z=100;
const second=M.instantiate({id:'second',spec:M.standard()},1200,200);second.z=100;
const stone={id:'stone',kind:'countertop',label:'Pedra',x:100,y:100,w:1600,d:600,height:35,z:865,view:'plan',refs:{}};
const cook={id:'cooker',kind:'appliance',type:'cooktop',label:'Cooktop',x:400,y:150,w:600,d:510,height:45,z:900,view:'plan',refs:{}};
const pen={id:'scribble',kind:'pen',label:'Linha torta',view:'plan',points:[[100,100],[260,113],[450,97],[800,101]],x:100,y:100,w:0,d:0,height:0};
const pen2={id:'scribble-2',kind:'pen',label:'Segunda linha',view:'plan',points:[[830,117],[1000,120]],x:830,y:117,w:0,d:0,height:0};
const l={width:4500,depth:3000,height:2700,confirmed:true,roomRefs:{},items:[base,second,stone,cook,pen,pen2],history:[],future:[],photoId:''};
const p={rooms:[{id:'r',name:'Cozinha real',measurements:[]}],photos:[],labLayouts:{r:l}};
const state={moduleTemplates:[],profileTemplates:[]};const toast=[];
w.ArqueLab.mount(p,{state,persist:()=>Promise.resolve(),toast:m=>toast.push(m),exportCutMaterial:()=>{}});
const click=(action,arg)=>{const el=[...doc.querySelectorAll('[data-lab="'+action+'"]')].find(x=>arg===undefined||x.dataset.arg===arg);assert(el,action+' '+arg+' não apareceu');el.click();};
const input=(id,value)=>{const el=doc.getElementById(id);assert(el,id+' não apareceu');el.value=value;};
function selectObject(id){
 const group=doc.querySelector('#labBoard [data-lab-object="'+id+'"]');assert(group,id+' sem desenho');
 const ev=new w.Event('pointerdown',{bubbles:true,cancelable:true});
 Object.defineProperties(ev,{pointerId:{value:56},isPrimary:{value:true},clientX:{value:100},clientY:{value:100}});
 group.dispatchEvent(ev);
}
assert(doc.querySelector('#labBoard.lab-visual'),'Laboratório inicia no ambiente espacial');
assert(doc.body.textContent.includes('Cozinha real'),'ambiente associado à obra');
selectObject('cooker');
assert(doc.getElementById('labAlignTarget'),'menu de alinhamento para eletrodoméstico');
input('labAlignTarget','stone');input('labAlignMode','cooktop');input('labAlignGap','25');
click('alignTarget');
assert.equal(cook.x,600);
assert.equal(cook.y,145);
assert.equal(cook.z,900);
assert.equal(cook.alignment.targetId,'stone');
assert.equal(cook.w,600,'a largura real do cooktop não é alterada');
click('undo');assert.equal(l.items.find(i=>i.id==='cooker').x,400,'desfazer restaura posição');
click('redo');assert.equal(l.items.find(i=>i.id==='cooker').x,600,'refazer restaura centralização');
selectObject(second.id);
assert(doc.getElementById('labWallSide'),'encaixe em paredes disponível');
input('labWallSide','left');input('labWallGap','30');
click('alignWall');
assert.equal(l.items.find(i=>i.id===second.id).rotation,90,'encaixar parede esquerda gira módulo');
assert.equal(l.items.find(i=>i.id===second.id).x,30);
selectObject(second.id);input('labAlignTarget',base.id);input('labJoinMode','right');
click('alignBeside');
assert.equal(l.items.find(i=>i.id===second.id).x,900,'encostar módulos na extremidade direita');
click('view','plan');
assert(doc.getElementById('labBoard').getAttribute('aria-label').includes('Planta'),'abre planta 2D');
assert(doc.querySelector('[data-lab="tool"][data-arg="pointline"]'),'linha por pontos disponível');
assert(doc.querySelector('[data-lab="autoSketch"]'),'comando alinhamento automático disponível');
click('autoSketch');
assert.equal(l.items.find(i=>i.id==='scribble').points.length,2,'rabisco endireitado como reta');
assert.deepEqual(l.items.find(i=>i.id==='scribble').points[1],l.items.find(i=>i.id==='scribble-2').points[0],'conectar pontas próximas');
const count=l.items.filter(i=>i.kind==='pen').length;
click('tool','pointline');
function tap(x,y){
 const board=doc.querySelector('#labBoard');
 board.getBoundingClientRect=()=>({left:0,top:0,width:450,height:300});
 const ev=new w.Event('pointerdown',{bubbles:true,cancelable:true});
 Object.defineProperties(ev,{pointerId:{value:57},isPrimary:{value:true},clientX:{value:x},clientY:{value:y}});
 board.dispatchEvent(ev);
}
tap(50,200);tap(130,200);tap(170,190);
assert.equal(l.items.filter(i=>i.kind==='pen').length,count+1,'toques acrescentam uma só linha');
const drawn=l.items.filter(i=>i.kind==='pen').at(-1);
assert.equal(drawn.points.length,3,'três pontos conectados na mesma linha');
click('finishPointLine');
assert(doc.querySelector('[data-lab="autoSketch"]'),'pode alinhar após finalizar');
click('autoSketch');
assert(l.items.find(i=>i.id===drawn.id).points.length<=3,'corrigir pontos da linha feita por toques');
assert(toast.some(t=>t.includes('linhas corrigidas')),'resultado avisado no editor');
console.log('Interface de alinhamento: abertura, cooktop, parede, módulo e linha por pontos OK.');
