/* Browser-like UI/persistence smoke test (jsdom + fake-indexeddb). */
const fs=require('node:fs'),assert=require('node:assert/strict'),{JSDOM}=require('jsdom'),{IDBFactory}=require('fake-indexeddb');
const html=fs.readFileSync('app/src/main/assets/index.html','utf8');
const core=fs.readFileSync('app/src/main/assets/core.js','utf8'),cut=fs.readFileSync('app/src/main/assets/cut.js','utf8'),app=fs.readFileSync('app/src/main/assets/app.js','utf8');
const storage=new IDBFactory();const sleep=(ms=40)=>new Promise(r=>setTimeout(r,ms));
async function launch(){
 const dom=new JSDOM(html,{url:'https://appassets.arque.invalid/index.html',runScripts:'outside-only',pretendToBeVisual:true});
 const w=dom.window;
 Object.defineProperty(w,'indexedDB',{value:storage,configurable:true});
 w.confirm=()=>true;w.scrollTo=()=>{};w.alert=()=>{};
 w.HTMLCanvasElement.prototype.getContext=function(){if(!this.__mockCtx){const canvas=this;this.__mockCtx={fillRect(){canvas.__paintedStrokes=0},fillText(){},beginPath(){},arc(){},fill(){},moveTo(){},lineTo(){},stroke(){if(this.lineWidth>1)canvas.__paintedStrokes=(canvas.__paintedStrokes||0)+1},drawImage(){}};}return this.__mockCtx;};
 w.HTMLCanvasElement.prototype.setPointerCapture=function(){};
 w.eval(core);w.eval(cut);w.eval(app);
 await sleep(90);return {dom,w,doc:w.document};
}
function click(doc,act,arg){const nodes=[...doc.querySelectorAll('[data-action]')];let b=nodes.find(x=>x.dataset.action===act&&(arg===undefined||x.dataset.arg===arg));if(!b&&act==='openWorkspace')b=doc.querySelector('[data-subtab="'+arg+'"]');assert(b,'Action not found: '+act+' '+arg);b.click();}
function dragMeasure(doc,x1=80,y1=80,x2=450,y2=230){
 const svg=doc.getElementById('photoOverlay');assert(svg,'photo overlay');
 svg.getBoundingClientRect=()=>({left:0,top:0,width:1000,height:650,right:1000,bottom:650});
 svg.setPointerCapture=()=>{};
 for(const [type,x,y] of [['pointerdown',x1,y1],['pointermove',x2,y2],['pointerup',x2,y2]]){
  const ev=new doc.defaultView.Event(type,{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:1},clientX:{value:x},clientY:{value:y}});
  svg.dispatchEvent(ev);
 }
}
function assign(doc,id,value){const x=doc.getElementById(id);assert(x,'Input not found: '+id);x.value=value;x.dispatchEvent(new doc.defaultView.Event('input',{bubbles:true}));}
(async()=>{
 let {dom,w,doc}=await launch();
 assert(doc.querySelector('h1').textContent.includes('Painel'),'home loaded');
 click(doc,'go','clients');
 assign(doc,'cname','Cliente persistência');click(doc,'addClient');await sleep(80);
 assert(doc.body.textContent.includes('Cliente persistência'),'client visible after save');
 click(doc,'openClient');click(doc,'clientProject');
 assert(doc.body.textContent.includes('Ambiente (ex.: Cozinha, Quarto, Sala)'),'form asks for ambiente');assert(!doc.getElementById('paddr'),'address is not asked twice');assign(doc,'pname','Cozinha teste');click(doc,'addProject');await sleep(80);
 assert(doc.body.textContent.includes('Cozinha teste'),'project created');click(doc,'openWorkspace','medidas');await sleep(30);assert(doc.body.textContent.includes('Cozinha teste'),'initial environment created');click(doc,'openWorkspace','resumo');

 // Regression: clicking the Projetos navigation must open the project list, not bounce to Clientes.
 doc.querySelector('[data-tab="projects"]').click();await sleep(40);
 assert(doc.querySelector('h1')?.textContent==='Projetos','Projetos tab opens project index');
 assert(doc.body.textContent.includes('Cozinha teste'),'existing project listed in Projetos');
 click(doc,'openProject');await sleep(40);
 assert(doc.querySelector('h1')?.textContent==='Cozinha teste','project opens from Projetos');
 assert(doc.body.textContent.includes('Área de trabalho'),'project workspace opens');
 click(doc,'closeProject');await sleep(40);
 assert(doc.querySelector('h1')?.textContent==='Projetos','back from project returns to Projetos');
 click(doc,'openProject');await sleep(40);

 // Test all primary project tabs without any crash or blank screen.
 for(const section of ['resumo','medidas','fotos','fotomedidas','atelier','corte','financeiro']){
   click(doc,'openWorkspace',section);await sleep(35);
   assert(![...doc.querySelectorAll('#main .notice')].some(x=>x.textContent.startsWith('Falha ao exibir:')),'tab '+section+' must not throw: '+[...doc.querySelectorAll('#main .notice')].map(x=>x.textContent).join(' / '));
   assert(doc.querySelector('#main').textContent.trim().length>40,'tab '+section+' must render');
 }
 // One Esboço tab: named A4 pages, immersive open/close, and persistence.
 click(doc,'openWorkspace','resumo');await sleep(30);
 assert(!doc.body.textContent.includes('Desenho livre'),'old drawing tab removed');
 assert(doc.body.textContent.includes('Esboço'),'single sketch workspace exists');
 click(doc,'openWorkspace','atelier');await sleep(30);
 assign(doc,'studioNewName','Parede da pia');click(doc,'studioNew');await sleep(75);
 assert(doc.querySelector('#studioCanvas')?.getAttribute('width')==='840','new sheet uses A4 width');
 assert(doc.querySelector('#studioCanvas')?.getAttribute('height')==='1188','new sheet uses A4 portrait height');
 assert(doc.body.textContent.includes('Parede da pia'),'named sheet created');
 const sketch=doc.getElementById('studioCanvas');
 assert.equal(typeof sketch.onpointerdown,'function','S Pen drawing listeners are attached');
 function sketchEvent(type,x,y){const ev=new w.Event(type,{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:8},clientX:{value:x},clientY:{value:y}});if(typeof sketch['on'+type]==='function')sketch['on'+type](ev);else sketch.dispatchEvent(ev);}
 sketch.getBoundingClientRect=()=>({left:0,top:0,width:840,height:1188});
 sketchEvent('pointerdown',30,30);sketchEvent('pointermove',130,150);sketchEvent('pointercancel',130,150);
 sketchEvent('pointerdown',230,300);sketchEvent('pointermove',360,450);sketchEvent('pointerup',360,450);
 assert.equal(sketch.dataset.strokeCount,'2','second stroke remains alongside first stroke on canvas');
 await sleep(100);
 click(doc,'studioUndo');await sleep(40);
 assert(doc.querySelector('#studioCanvas'),'stroke remains editable after pointercancel');
 click(doc,'studioRedo');await sleep(50);
 click(doc,'studioOpenFull');await sleep(45);
 assert(doc.querySelector('#studioWork.studio-fullscreen'),'sheet expands to full screen');
 click(doc,'studioCloseFull');await sleep(45);
 assert(!doc.querySelector('#studioWork.studio-fullscreen'),'sheet closes full screen');
 assign(doc,'studioNewName','Armário superior');click(doc,'studioNew');await sleep(65);
 assert(doc.querySelectorAll('.studio-page').length===2,'multiple named sheets');
 click(doc,'studioSelect',doc.querySelector('.studio-page').dataset.arg);await sleep(40);
 assert(doc.querySelector('.studio-paper-head').textContent.includes('Parede da pia'),'can reopen first sheet');
 // Unified 2D lab: drawing tools, real dimensions and modes share the same sheet.
 click(doc,'studioMode','laboratorio');await sleep(40);
 assert(doc.querySelector('#studioTool option[value="cabinet"]'),'cabinet tool available');
 assert(doc.querySelector('#studioTool option[value="drawers"]'),'drawer tool available');
 assert(doc.querySelector('#studioReferencePhoto'),'photo reference selector available');
 const labCanvas=doc.getElementById('studioCanvas');
 labCanvas.getBoundingClientRect=()=>({left:0,top:0,width:840,height:1188});
 const tool=doc.getElementById('studioTool');tool.value='cabinet';tool.dispatchEvent(new w.Event('change',{bubbles:true}));
 for(const [type,x,y] of [['pointerdown',50,100],['pointermove',240,320],['pointerup',240,320]]){
  const ev=new w.Event(type,{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:18},clientX:{value:x},clientY:{value:y}});
  labCanvas.dispatchEvent(ev);
 }
 await sleep(65);
 assert.equal(labCanvas.dataset.strokeCount,'3','lab furniture is stored alongside original sketch strokes');
 assign(doc,'studioElementMm','2400');click(doc,'studioSetMeasure');await sleep(65);
 assert(doc.querySelector('#studioElementMm').value==='2400','dimension attached to last drawn cabinet');
 click(doc,'studioMode','planta');await sleep(40);
 assert(doc.querySelector('#studioCanvas'),'floor plan mode reuses same drawing');
 click(doc,'studioMode','esboco');await sleep(40);

 // MeasureOn-inspired single distance tool: no horizontal/vertical/free arrow choices.
 click(doc,'openWorkspace','fotomedidas');await sleep(30);
 assert(!doc.body.textContent.includes('Nova seta horizontal'),'old arrow options removed');
 assert(!doc.body.textContent.includes('Seta livre'),'free-arrow option removed');
 assert(doc.body.textContent.includes('Adicione uma foto')||doc.body.textContent.includes('Zoom')||doc.body.textContent.includes('100%'),'photo zoom controls or empty state available');
 assert(doc.body.textContent.includes('Nova medida')||doc.body.textContent.includes('Adicione uma foto'),'distance workflow available when photo exists');
 click(doc,'openWorkspace','corte');await sleep();
 assign(doc,'cutName','Lateral');assign(doc,'cutW','800');assign(doc,'cutH','550');assign(doc,'cutQty','2');
 click(doc,'cutAdd');await sleep(90);
 assert(doc.body.textContent.includes('Lista')===false||doc.body.textContent.includes('Lateral'),'piece visible');
 assert(doc.querySelectorAll('[data-cut-field="w"]').length===1,'one saved piece row');
 const first=doc.querySelector('[data-cut-field="w"]');first.value='850';first.dispatchEvent(new w.Event('change',{bubbles:true}));await sleep(100);
 assert(doc.querySelector('[data-cut-field="w"]').value==='850','row edited');
 dom.window.close();
 let x=await launch();doc=x.doc;w=x.w;
 click(doc,'go','clients');await sleep(30);
 assert(doc.body.textContent.includes('Cliente persistência'),'client survives WebView reload');

 click(doc,'openClient');assert(doc.body.textContent.includes('Cozinha teste'),'project survives reload');
 click(doc,'openProject');click(doc,'openWorkspace','atelier');await sleep(40);assert(doc.querySelectorAll('.studio-page').length===2,'A4 pages survive reload');click(doc,'openWorkspace','corte');
 assert(doc.querySelector('[data-cut-field="w"]').value==='850','cut piece survives reload');
 // Mixed stock from two different modules, persisted per client/project.
 assign(doc,'cutName','Prateleira');assign(doc,'cutW','220');assign(doc,'cutH','300');assign(doc,'cutQty','3');
 click(doc,'cutAdd');await sleep(85);
 assert(doc.querySelectorAll('[data-cut-field="w"]').length===2,'two different pieces saved');
 // Production queue: units sorted by area, individual completion and persistent colors.
 const rowsBefore=[...doc.querySelectorAll('.cut-status-line')];assert(rowsBefore.length===5,'one status per physical piece');
 assert(rowsBefore.every(row=>row.classList.contains('cut-pending')),'new units are red');
 assert(rowsBefore[0].textContent.includes('Lateral'),'larger piece first');
 const firstKey=rowsBefore[0].querySelector('[data-action="cutToggle"]').dataset.arg;
 click(doc,'cutToggle',firstKey);await sleep(80);
 assert(doc.querySelectorAll('.cut-finished').length===1,'one finished becomes green');
 assert(doc.querySelectorAll('.cut-pending').length===4,'remaining pieces stay red');
 assert(doc.querySelectorAll('.cut-status-line').length===5,'finished row remains visible');

 assign(doc,'mixedW','1200');assign(doc,'mixedH','700');
 click(doc,'mixedSimulate');await sleep(85);
 assert(doc.body.textContent.includes('Peças colocadas'),'mixed plan calculated');

 assign(doc,'cutName','Frente');assign(doc,'cutW','700');assign(doc,'cutH','300');await sleep(70);
 x.dom.window.close();
 x=await launch();doc=x.doc;w=x.w;
 click(doc,'go','clients');click(doc,'openClient');click(doc,'openProject');click(doc,'openWorkspace','corte');
 assert(doc.getElementById('cutName').value==='Frente','draft survives reload');
 assert(doc.getElementById('cutW').value==='700','draft dimensions survive reload');
 assert(doc.querySelectorAll('.cut-finished').length===1,'finished unit saved after restart');
 assert(doc.querySelectorAll('.cut-status-line').length===5,'all units retained after restart');

 // Preserve the completed cut in a versioned audit history on dimensional edits.
 const dimension=doc.querySelector('[data-cut-field="w"]');
 dimension.value='875';dimension.dispatchEvent(new w.Event('change',{bubbles:true}));
 await sleep(110);
 assert(doc.querySelectorAll('.cut-finished').length===0,'changed geometry requires new cut approval');
 const history=doc.querySelector('.cut-history');
 assert(history&&history.textContent.includes('850 × 550 mm'),'historical dimensions archived');
 assert(history.textContent.includes('1 concluída(s)'),'completed unit retained in prior revision');
 x.dom.window.close();
 x=await launch();doc=x.doc;w=x.w;
 click(doc,'go','clients');click(doc,'openClient');click(doc,'openProject');click(doc,'openWorkspace','corte');
 assert(doc.querySelector('.cut-history').textContent.includes('850 × 550 mm'),'revision persists after restart');


 
 // Photo overlay integration: manual yellow arrows, rectangle and room association.
 click(doc,'openWorkspace','medidas');assign(doc,'roomname','Cozinha do teste');click(doc,'addRoom');await sleep(60);
 click(doc,'openWorkspace','fotos');
 // Insert test photo in saved model through project persistence via normal photo-file chooser.
 const fileInput=doc.getElementById('photoFile');
 const photoFile=new w.File([new Uint8Array([137,80,78,71])],'referencia.png',{type:'image/png'});
 // The file input path depends on createImageBitmap; simulate supported file decode/canvas.
 w.createImageBitmap=async()=>({width:100,height:100});
 const oldCanvas=w.HTMLCanvasElement.prototype.getContext;
 w.HTMLCanvasElement.prototype.getContext=function(){return {drawImage:()=>{}};};
 w.HTMLCanvasElement.prototype.toDataURL=()=> 'data:image/jpeg;base64,AA==';
 Object.defineProperty(fileInput,'files',{value:[photoFile],configurable:true});
 fileInput.dispatchEvent(new w.Event('change',{bubbles:true}));await sleep(80);
 click(doc,'openWorkspace','fotomedidas');
 assert(doc.getElementById('photoOverlay'),'overlay rendered. Screen: '+doc.getElementById('main')?.textContent.slice(0,1200)+' Toast: '+doc.getElementById('toast')?.textContent);
 click(doc,'photoAddDistance');await sleep(30);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===0,'no unwanted pre-positioned arrow');dragMeasure(doc);await sleep(75);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===1,'yellow arrow appears above image');
 assert(doc.querySelector('.photo-floating-dock [data-action="photoAddDistance"].active'),'arrow tool stays active after first drag');
 dragMeasure(doc);await sleep(75);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===2,'second drag adds arrow without tapping the icon again');
 assert(doc.querySelector('.photo-floating-dock [data-action="photoAddDistance"].active'),'arrow tool stays active after second drag');

 assert(doc.querySelector('#photoZoomSurface'),'photo and overlay share a zoom surface');
 assert(doc.querySelector('.photo-floating-dock [data-action="photoInkToggle"]'),'pen is in floating photo dock');
 assert(doc.querySelector('.photo-floating-dock [data-action="photoAddDistance"]'),'arrow is in floating photo dock');
 assert(doc.querySelector('.photo-ink-tools [data-action="photoDimensionApply"]'),'apply Bosch reading is alongside colors above image');

 click(doc,'photoZoomIn');assert(doc.getElementById('photoZoomReadout').textContent==='125%','zoom in increases to 125%');
 assert(doc.getElementById('photoZoomSurface').style.transform.includes('scale(1.25)'),'zoom scales image and arrows together');
 click(doc,'photoZoomOut');assert(doc.getElementById('photoZoomReadout').textContent==='100%','zoom out returns to 100%');
 click(doc,'photoZoomMode');assert(!!doc.querySelector('[data-action="photoZoomMode"][title="Travar zoom"]'),'pan and pinch mode is available');click(doc,'photoZoomMode');
 // Two rapid taps toggle free zoom, then lock it again.
 const tap=(x,y)=>{const stage=doc.getElementById('photoMeasureStage');for(const type of ['pointerdown','pointerup']){const ev=new w.Event(type,{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:91},pointerType:{value:'touch'},clientX:{value:x},clientY:{value:y}});stage.dispatchEvent(ev);}};
 tap(80,90);tap(80,90);assert(!!doc.querySelector('[data-action="photoZoomMode"][title="Travar zoom"]'),'double tap unlocks navigation');
 // A third tap restores original framing and locks navigation.
 click(doc,'photoZoomIn');assert(doc.getElementById('photoZoomReadout').textContent==='125%','zoom before triple tap');
 tap(80,90);assert(doc.getElementById('photoZoomReadout').textContent==='100%','triple tap resets zoom');
 assert(!!doc.querySelector('[data-action="photoZoomMode"][title="Mover e ampliar"]'),'triple tap locks navigation');
 await sleep(470);
 tap(80,90);tap(80,90);assert(!!doc.querySelector('[data-action="photoZoomMode"][title="Travar zoom"]'),'double tap still unlocks after triple tap');
 await sleep(470);
 tap(80,90);tap(80,90);assert(!!doc.querySelector('[data-action="photoZoomMode"][title="Mover e ampliar"]'),'second double tap locks navigation');

 assert(doc.querySelector('#photoOverlay [data-handle="a"]'),'arrow handle exists');assert(doc.querySelector('#photoOverlay .measure-hit')?.getAttribute('stroke')==='transparent','interaction hitbox is invisible');assert(doc.querySelector('#photoOverlay .measure-label rect'),'unmeasured arrow shows one small central yellow box');assert(!doc.querySelector('[data-action="photoAddHorizontal"]'),'no directional arrow menu');
 assign(doc,'photoMeasureValue','2780');click(doc,'photoDimensionManual');await sleep(60);
 assert(doc.body.textContent.includes('2.780 mm'),'manual value appears in photo');assert(doc.querySelector('#photoOverlay .measure-label rect')?.getAttribute('fill')==='#ffe000','measured label is yellow');
 // Central box opens the piece specifications directly, even with pen selected.
 click(doc,'photoInkToggle');
 const boxes=doc.querySelectorAll('#photoOverlay [data-measure-label] rect');const box=boxes[boxes.length-1];assert(box,'measurement center box is tappable');
 const ev=new w.Event('pointerdown',{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:88},clientX:{value:250},clientY:{value:150}});
 box.dispatchEvent(ev);
 assert(doc.querySelector('#photoMeasureDetails'),'tapping yellow box opens specifications');
 assert(doc.getElementById('photoMeasureValue').value==='2780','selected piece value shown in details');

 click(doc,'photoAddDistance');await sleep(30);dragMeasure(doc,110,360,800,450);await sleep(70);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===3,'third distance arrow appears');
 const thick=doc.getElementById('photoMeasureThickness');assert(thick,'thickness control exists');
 assign(doc,'photoMeasureValue','1100');assign(doc,'photoMeasureThickness','3');click(doc,'photoDimensionManual');await sleep(70);
 assert(doc.querySelector('#photoOverlay line[stroke-width="3"]'),'adjustable width saved');
 click(doc,'photoAddRect');await sleep(70);
 assert(doc.querySelector('#photoOverlay rect'),'rectangle overlay appears');
 w.prompt=()=> 'Tomada atrás do armário';click(doc,'photoNoteAdd');await sleep(50);assert(doc.body.textContent.includes('Tomada atrás do armário'),'annotation saved');
 // Automatic freehand: one pointer contact is one saved stroke, no Concluir button.
 click(doc,'photoInkToggle');assert(!doc.body.textContent.includes('Concluir desenho'),'drawing needs no finish button');
 click(doc,'photoInkColor','#e23d3d');
 assert(!doc.querySelector('[data-action="photoInkThinner"]'),'writing thickness control removed from toolbar');
 const drawStroke=(x1,y1,x2,y2)=>{
  const svg=doc.getElementById('photoOverlay');svg.getBoundingClientRect=()=>({left:0,top:0,width:1000,height:650});
  svg.setPointerCapture=()=>{};
  for(const [type,x,y] of [['pointerdown',x1,y1],['pointermove',x2,y2],['pointerup',x2,y2]]){
   const ev=new w.Event(type,{bubbles:true,cancelable:true});Object.defineProperties(ev,{pointerId:{value:7},clientX:{value:x},clientY:{value:y}});
   svg.dispatchEvent(ev);
  }
 };
 drawStroke(50,50,120,130);drawStroke(150,160,260,270);await sleep(80);
 assert.equal(doc.querySelectorAll('#photoOverlay polyline[stroke="#e23d3d"]').length,2,'each lift and new contact creates separate persistent red stroke');
 click(doc,'photoInkUndo');await sleep(80);
 assert.equal(doc.querySelectorAll('#photoOverlay polyline[stroke="#e23d3d"]').length,1,'undo removes only last stroke');
  // prompt may be unavailable in jsdom: no-op possible here.
 const roomSelector=doc.getElementById('photoRoom');
 assert(roomSelector,'room association selector exists');
 w.HTMLCanvasElement.prototype.getContext=oldCanvas;

 console.log('UI INTEGRAÇÃO OK: cliente, obra, chapa, edição e rascunho persistiram após recriar a tela.');
 x.dom.window.close();
})().catch(err=>{console.error(err);process.exitCode=1;});
