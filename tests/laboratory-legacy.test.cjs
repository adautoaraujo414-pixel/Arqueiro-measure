'use strict';
/* Regressão: projeto legado não pode apagar a tela inteira se uma peça salva for inválida. */
const assert=require('node:assert/strict'),fs=require('node:fs'),{JSDOM}=require('jsdom');
const dom=new JSDOM('<!doctype html><html><body><div id="arqueLab"></div></body></html>',{url:'https://arque.test/',runScripts:'outside-only'});
const w=dom.window,assets='app/src/main/assets/';
for(const f of ['modules.js','corner45.js','kitchen-catalog.js','lab-alignment.js','lab-precision.js','lab-advanced.js','lab-fabrication.js','lab-visual.js','workshop.js','module-ui.js','lab.js'])
 w.eval(fs.readFileSync(assets+f,'utf8'));
const oldRoom={id:'oldroom',name:'Cozinha antiga',measurements:[]};
const invalidModule={id:'oldmodule',kind:'module',label:'Módulo versão antiga',x:200,y:200,z:100,w:500,d:500,height:730,view:'plan',moduleSpec:{width:0,height:730}};
const invalidPanel={id:'oldpanel',kind:'panel',label:'Peça sem largura',x:1100,y:400,w:0,d:260,height:18,thickness:18,material:'MDF antigo',view:'plan'};
const p={rooms:[oldRoom],photos:[],labLayouts:{oldroom:{width:3400,depth:2800,height:2600,confirmed:false,items:[invalidModule,invalidPanel],history:[],future:[],roomRefs:{}}}};
const state={moduleTemplates:[],profileTemplates:[]};
const html=w.ArqueLab.screen(p,state);
assert(html.includes('Laboratório · ambiente visual e montagem'),'início da página carregado mesmo com projeto legado');
assert(html.includes('lab-recovery'),'erro localizado sem tela branca');
assert(html.includes('id="labBoard"'),'existe área de trabalho mesmo com peça incorreta');
assert(html.includes('Peça sem largura')||html.includes('Módulo versão antiga'),'peças legadas permanecem identificáveis');
assert(html.includes('Plano de corte deste ambiente'),'aviso localizado ao importar peça antiga inválida');
w.ArqueLab.mount(p,{state,persist:()=>Promise.resolve(),toast:()=>{},exportCutMaterial:()=>{}});
assert(w.document.getElementById('arqueLab').textContent.length>200,'montagem não apaga a interface');
const empty=w.ArqueLab.screen({rooms:[],labLayouts:{}},state);
assert(empty.includes('Cadastre um ambiente'),'orientação clara quando não há ambientes');
console.log('Projeto antigo inválido: editor, biblioteca e planta não ficam em branco; dados preservados.');
