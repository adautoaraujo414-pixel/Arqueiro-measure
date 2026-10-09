/* Audit of four areas: measurement, cutting, clients/contracts, integrity. */
'use strict';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const core=require('../app/src/main/assets/core.js');
const ctx={};vm.runInNewContext(fs.readFileSync('app/src/main/assets/cut.js','utf8'),ctx);const {calculate,manualGrid}=ctx.ArqueCut;
const app=fs.readFileSync('app/src/main/assets/app.js','utf8');
const html=fs.readFileSync('app/src/main/assets/index.html','utf8');
let checks=0;const ok=(p,m)=>{assert.ok(p,m);checks++},eq=(a,b,m)=>{assert.equal(a,b,m);checks++},throws=(fn,m)=>{assert.throws(fn,m);checks++};
// 1. Measurements, calculations, simulated Bosch payloads.
eq(core.mm('1250,5'),1250.5);throws(()=>core.mm(''));throws(()=>core.mm(-1));throws(()=>core.mm('xxx'));
eq(core.diagonal(300,400),500);eq(core.carcass(900,30,100,5).height,765);
eq(core.usableOpening([2735,2728,2731],5,5).usable,2718);
throws(()=>core.usableOpening([8],5,5));eq(core.socket(3500,1210,80,2210,5).withinTolerance,true);
const ms=[core.measurement(2720,'Parede','manual','parede A','canto esquerdo'),core.measurement(2735,'Parede','manual','parede A','canto esquerdo')];
const audit=core.auditMeasurements(ms,5);eq(audit.compared.length,1);eq(audit.compared[0].withinTolerance,false);eq(audit.compared[0].difference,15);
const payload=new Uint8Array(11);payload.set([0xc0,0x55,0x10,0x06]);new DataView(payload.buffer).setFloat32(7,2.345,true);eq(core.decodeBosch(payload),2345);eq(core.decodeBosch(new Uint8Array(11)),null);
ok(app.includes("case'photoDimensionManual'"),'manual measurements in photos');
ok(app.includes("case'photoDimensionApply'"),'BLE measurements associated with photos');
ok(app.includes("photo.inkStrokes"),'photo drawing state persisted');
// 2. Cut optimizer, kerf, refilo, grain, random layout geometry.
throws(()=>calculate({width:0,height:1830,pieces:[]}));throws(()=>manualGrid({width:1200,height:700,partW:500,partH:300,qty:0}));
throws(()=>manualGrid({width:1200,height:700,partW:500,partH:300,qty:-5}));throws(()=>manualGrid({width:1200,height:700,partW:500,partH:300,qty:1,kerf:-2}));
throws(()=>calculate({width:500,height:400,trim:250,pieces:[]}));
const rotated=manualGrid({width:400,height:800,partW:750,partH:350,qty:1});
eq(rotated.rotated,true);eq(rotated.placed,1);
const grain=manualGrid({width:400,height:800,partW:750,partH:350,qty:1,grain:true});eq(grain.placed,0);
const kerfTest=manualGrid({width:1000,height:1000,partW:500,partH:500,kerf:3,qty:4});eq(kerfTest.capacity,1);
const inventory=calculate({width:2750,height:1830,kerf:3,trim:6,pieces:[{name:'Módulo A',w:800,h:550,qty:3,grain:true},{name:'Módulo B',w:450,h:400,qty:4,rotate:true}]});
eq(inventory.totalPieces,7);eq(inventory.placedPieces+inventory.unfit.length,7);
function checkGeometry(result,width,height,trim,kerf){
  for(const sheet of result.sheets){
    for(let i=0;i<sheet.pieces.length;i++){
      const a=sheet.pieces[i];
      ok(a.x>=trim-1e-6&&a.y>=trim-1e-6&&a.x+a.w<=width-trim+1e-6&&a.y+a.h<=height-trim+1e-6,'bounds');
      for(let j=i+1;j<sheet.pieces.length;j++){
        const b=sheet.pieces[j];
        ok(a.x+a.w+kerf<=b.x+1e-5||b.x+b.w+kerf<=a.x+1e-5||a.y+a.h+kerf<=b.y+1e-5||b.y+b.h+kerf<=a.y+1e-5,'non overlapping with blade');
      }
    }
  }
}
checkGeometry(inventory,2750,1830,6,3);
let seed=732491;const rand=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296;};
for(let i=0;i<160;i++){
 const width=900+Math.floor(rand()*1900),height=650+Math.floor(rand()*1100),kerf=1+Math.floor(rand()*5),trim=Math.floor(rand()*14);
 const pieces=Array.from({length:2+Math.floor(rand()*9)},(_,j)=>({name:'Peça '+j,w:100+Math.floor(rand()*1300),h:100+Math.floor(rand()*900),qty:1+Math.floor(rand()*4),rotate:rand()>.3,grain:rand()>.8}));
 const result=calculate({width,height,kerf,trim,pieces});
 eq(result.placedPieces+result.unfit.length,result.totalPieces,'counts');
 ok(result.usedArea<=result.allocatedArea+1e-3,'surface');
 checkGeometry(result,width,height,trim,kerf);
}
// 3. Clients, project separation, financial status and contracts.
const c=core.client('Cliente de teste','3433330000'),p=core.project(c.id,'Cozinha'),p2=core.project(c.id,'Quarto');
p.status='Produção';p2.status='Finalizado';p.rooms.push(core.room('Cozinha'));
eq(p.clientId,p2.clientId);eq(p.rooms.length,1);eq(p2.rooms.length,0);
eq(core.finance({...p,value:10000,discount:500,payments:[{amount:2500}]}).balance,7000);
throws(()=>core.finance({...p,value:100,discount:200}));
const state={clients:[c],projects:[p,p2],settings:{tolerance:5}};
const packed={format:'arque-measure',version:1,state:structuredClone(state)};
eq(core.validateImport(packed).projects.length,2);
throws(()=>core.validateImport({format:'arque-measure',version:1,state:{clients:[],projects:[{id:'a'}]}}));
const exported=core.exportProject(state,p.id);eq(exported.project.clientId,c.id);
const merged=core.mergeProject(state,exported);eq(merged.state.projects.length,3);eq(state.projects.length,2);
ok(merged.state.projects[2].id!==p.id,'import does not overwrite original');
ok(app.includes("contractFile")&&html.includes('id="contractFile"'),'document picker');
ok(app.includes("file.size>6*1024*1024"),'maximum file size');
ok(app.includes("'application/pdf'")&&app.includes("'image/png'"),'contract formats');
ok(app.includes("function groupedProjects")&&app.includes("function statusBadge"),'status grouping and badge');
ok(app.includes("function contractsView"),'contracts linked to client');
// 4. Security/syntax, backups and persistence.
new Function(app);new Function(fs.readFileSync('app/src/main/assets/cut.js','utf8'));
ok(html.indexOf('src="core.js"')<html.indexOf('src="cut.js"')&&html.indexOf('src="cut.js"')<html.indexOf('src="app.js"'),'script load order');
ok(app.includes('async function exportBackup')&&app.includes('async function receiveImport'),'backup support');
ok(app.includes('indexedDB.open')&&app.includes('persist()'),'local persistence');
ok(app.includes('const escape=')&&app.includes('escape(c.name)'),'HTML escaping');

/* Integration regressions: row editor, Android assets, backup and authorized transfer. */
const activity=fs.readFileSync('app/src/main/java/com/arque/measure/MainActivity.java','utf8');
const link=fs.readFileSync('app/src/main/java/com/arque/measure/ArqueLink.java','utf8');
ok(activity.includes('!name.equals("cut.js")'),'Android WebView must actually serve cut.js');
ok(app.includes('data-cut-field="w"')&&app.includes('data-cut-field="qty"'),'row editor exists');
ok(app.includes("case'cutAdd'")&&app.includes("case'cutRemove'"),'add/remove rows exist');
ok(app.includes("dataset.cutDraft")&&app.includes("persist().catch"),'draft autosaves to IndexedDB');
ok(activity.includes('Intent.ACTION_CREATE_DOCUMENT')&&activity.includes('Intent.ACTION_OPEN_DOCUMENT'),'SAF for SD/Drive backup');
ok(app.includes("val('linkMode')==='full'"),'full transfer option');
ok(app.includes("received?.format==='arque-measure'"),'full transfer reception');
ok(app.includes('state=previous;throw e;'),'rollback on persistence failure');
ok(link.includes('AES/GCM/NoPadding')&&link.includes('freshSecret()'),'transfer encryption and one-time pairing secret');
ok(link.includes('MAX_BYTES = 24 * 1024 * 1024'),'large backup transfer size guard');
ok(app.includes("confirm('O outro Arque Measure enviou um BACKUP COMPLETO"),'explicit confirmation before remote overwrite');


/* Single-stock mixed-cut scenario tests, including grain and bounding boxes. */
const mixed=ctx.ArqueCut.mixedStock;
const stockA=mixed({width:1200,height:700,kerf:3,trim:0,pieces:[{id:'A',name:'Lateral',w:500,h:300,qty:2,grain:true},{id:'B',name:'Prateleira',w:180,h:200,qty:2}]});
eq(stockA.requested,4);eq(stockA.placedCount+stockA.unplaced.length,4);
ok(stockA.placedCount>=2,'mixed parts packed');
for(const piece of stockA.placed)ok(piece.x>=0&&piece.y>=0&&piece.x+piece.w<=1200&&piece.y+piece.h<=700,'mixed within stock');
for(let i=0;i<stockA.placed.length;i++)for(let j=i+1;j<stockA.placed.length;j++){
 const a=stockA.placed[i],b=stockA.placed[j],k=3;
 ok(a.x+a.w+k<=b.x||b.x+b.w+k<=a.x||a.y+a.h+k<=b.y||b.y+b.h+k<=a.y,'mixed no overlap plus kerf');
}
eq(mixed({width:400,height:800,pieces:[{name:'Veio fixo',w:750,h:350,qty:1,grain:true}]}).placedCount,0);
eq(mixed({width:400,height:800,pieces:[{name:'Livre',w:750,h:350,qty:1,grain:false}]}).placedCount,1);
throws(()=>mixed({width:300,height:200,pieces:[{name:'Inválida',w:250,h:200,qty:-2}]}));
ok(app.includes("case'mixedSimulate'"),'mixed interface workflow');


const moveStock=mixed({width:1200,height:700,kerf:3,pieces:[{id:'a',name:'A',w:300,h:250,qty:1},{id:'b',name:'B',w:150,h:150,qty:1}]});
const p0=moveStock.placed.find(p=>p.id==='a');
const p1=moveStock.placed.find(p=>p.id==='b');
const shiftX=moveStock.width-p0.w;
if(shiftX>p0.x&&shiftX!==p1.x){
 try{const changed=ctx.ArqueCut.positionMixed(moveStock,{'a:1':{x:shiftX,y:0}});ok(changed.placed.some(p=>p.id==='a'&&p.x===shiftX),'manual position is applied');}
 catch(e){ok(e.message.includes('Peças sobrepostas'),'manual safety catches conflicts');}
}
throws(()=>ctx.ArqueCut.positionMixed(moveStock,{'a:1':{x:-1,y:0}}));
throws(()=>ctx.ArqueCut.positionMixed(moveStock,{'a:1':{x:p1.x,y:p1.y}}));
ok(app.includes("case'mixedMove'")&&app.includes("case'mixedReset'"),'manual placement UI actions');

console.log('AUDITORIA OK: '+checks+' verificações. Medições, geometrias, corte, cliente/contratos, arquivos, backup e sintaxe.');
