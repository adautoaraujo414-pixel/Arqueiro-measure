'use strict';
const A=require('node:assert/strict'),fs=require('node:fs'),{JSDOM}=require('jsdom');
const root='app/src/main/assets/';
const dom=new JSDOM('<!doctype html><html><body><div id="arqueLab"></div></body></html>',{
 url:'https://arque.test/',runScripts:'outside-only',pretendToBeVisual:true});
const w=dom.window,d=w.document;
for(const file of ['modules.js','kitchen-catalog.js','lab-alignment.js','lab-precision.js','lab-advanced.js','lab-fabrication.js','lab-visual.js','workshop.js','module-ui.js','lab.js'])
 w.eval(fs.readFileSync(root+file,'utf8'));
const M=w.ArqueModules;
function create(id,x,y,spec=M.standard()){const it=M.instantiate({id,spec},x,y);it.z=100;return it;}
const back=create('back',1300,100),side=create('side',100,1400);
const drawerSpec=M.check({...M.standard(),accessories:[{type:'drawer',bay:0,count:3,slideSide:12.7,frontClearance:20,rearClearance:20,height:150,slideLength:400}]});
const drawer=create('drawer',2600,1400,drawerSpec);
const layout={width:4500,depth:3200,height:2600,confirmed:true,roomRefs:{},items:[back,side,drawer],history:[],future:[]};
const p={rooms:[{id:'r',name:'Cozinha piloto',measurements:[]}],photos:[],labLayouts:{r:layout}};
const toast=[];
w.ArqueLab.mount(p,{state:{moduleTemplates:[],profileTemplates:[]},persist:()=>Promise.resolve(),toast:x=>toast.push(x),exportCutMaterial:()=>{}});
function click(name,arg){const x=[...d.querySelectorAll('[data-lab="'+name+'"]')].find(el=>arg===undefined||el.dataset.arg===arg);A(x,'Botão '+name+' não encontrado');x.click();}
function field(id,v){const el=d.getElementById(id);A(el,'Campo '+id+' não encontrado');el.value=String(v);}
function select(id){const el=d.querySelector('#labBoard [data-lab-object="'+id+'"]');A(el,'Módulo ausente');const ev=new w.Event('pointerdown',{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:123},isPrimary:{value:true},clientX:{value:160},clientY:{value:180}});el.dispatchEvent(ev);}
A(d.body.textContent.includes('Cozinha piloto'),'laboratório carregado');
field('advCornerBack',back.id);field('advCornerSide',side.id);click('advCorner');
A.equal(side.rotation,90);A.equal(back.rotation,0);
field('fabCornerBack',back.id);field('fabCornerSide',side.id);field('fabCornerReach',400);
click('fabCorner45');
A.equal(layout.cornerGuides.length,1);
A(d.querySelector('#labBoard').outerHTML.includes('45° · 565,7 mm'),'diagonal visível no 3D');
click('view','plan');
A(d.querySelector('#labBoard').outerHTML.includes('45° · 565,7 mm'),'diagonal visível na planta');
click('undo');
A.equal(layout.cornerGuides.length,0,'undo descarta a frente de referência');
click('redo');
A.equal(layout.cornerGuides.length,1,'redo restaura canto diagonal');
click('view','iso');
select(back.id);
A(d.querySelector('#fabHingeDiameter'),'editor de caneca disponível');
field('fabHingeBrand','Modelo teste');
field('fabHingeCount','3');
click('fabHinges');
A.equal(back.hingePlan.holes.length,6,'duas portas com três dobradiças');
A.equal(back.hingePlan.brand,'Modelo teste');
A(d.body.textContent.includes('centros calculados'),'prévia na ficha técnica');
field('labQuickDoors',3);
click('catalogEditModule');
A.equal(back.moduleSpec.doorCount,3);
A(w.ArqueFabrication.hingesStale(back,back.hingePlan,M),'alterar portas sinaliza furação anterior vencida');
A(d.body.textContent.includes('desatualizados'),'alerta visível no editor');
select(drawer.id);
A(d.querySelector('#fabSlideLength'),'corrediças aparecem para gavetas');
field('fabSlideSide','13');
field('fabSlideRear','25');
click('fabSlides');
A.equal(drawer.moduleSpec.accessories[0].slideSide,13,'desconto lateral da gaveta atualizado');
A.equal(drawer.moduleSpec.accessories[0].rearClearance,25);
A.equal(drawer.slideConfiguration.verified,false,'montagem exige validação técnica');
const report=w.ArqueAdvanced.production(layout,M);
A(report.warnings.some(x=>x.includes('carcaça')),'canto diagonal não libera corte');
A(report.warnings.some(x=>x.includes('desatualizado')),'furação desatualizada impede aprovação');
A.equal(report.ready,false);
console.log('Etapa 8 UI: 45°, vista 2D/3D, undo/redo, dobradiças, corrediças e pendências OK.');
