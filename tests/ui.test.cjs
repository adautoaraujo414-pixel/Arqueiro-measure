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
 w.eval(core);w.eval(cut);w.eval(app);
 await sleep(90);return {dom,w,doc:w.document};
}
function click(doc,act,arg){const nodes=[...doc.querySelectorAll('[data-action]')];let b=nodes.find(x=>x.dataset.action===act&&(arg===undefined||x.dataset.arg===arg));if(!b&&act==='openWorkspace')b=doc.querySelector('[data-subtab="'+arg+'"]');assert(b,'Action not found: '+act+' '+arg);b.click();}
function assign(doc,id,value){const x=doc.getElementById(id);assert(x,'Input not found: '+id);x.value=value;x.dispatchEvent(new doc.defaultView.Event('input',{bubbles:true}));}
(async()=>{
 let {dom,w,doc}=await launch();
 assert(doc.querySelector('h1').textContent.includes('Painel'),'home loaded');
 click(doc,'go','clients');
 assign(doc,'cname','Cliente persistência');click(doc,'addClient');await sleep(80);
 assert(doc.body.textContent.includes('Cliente persistência'),'client visible after save');
 click(doc,'openClient');click(doc,'clientProject');
 assign(doc,'pname','Cozinha teste');click(doc,'addProject');await sleep(80);
 assert(doc.body.textContent.includes('Cozinha teste'),'project created');

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
 for(const section of ['resumo','medidas','fotos','fotomedidas','desenho','atelier','corte','financeiro']){
   click(doc,'openWorkspace',section);await sleep(35);
   assert(!doc.querySelector('#main .notice'),'tab '+section+' must not throw');
   assert(doc.querySelector('#main').textContent.trim().length>40,'tab '+section+' must render');
 }
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
 click(doc,'openProject');click(doc,'openWorkspace','corte');
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
 click(doc,'photoAddHorizontal');await sleep(60);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===1,'yellow arrow appears above image');
 assert(doc.querySelector('#photoOverlay [data-handle="a"]'),'arrow handle exists');
 assign(doc,'photoMeasureValue','2780');click(doc,'photoDimensionManual');await sleep(60);
 assert(doc.body.textContent.includes('2.780 mm'),'manual value appears in photo');
 click(doc,'photoAddFree');await sleep(70);
 assert(doc.querySelectorAll('#photoOverlay [data-dimension]').length===2,'free arrow appears');
 const thick=doc.getElementById('photoMeasureThickness');assert(thick,'thickness control exists');
 assign(doc,'photoMeasureValue','1100');assign(doc,'photoMeasureThickness','3');click(doc,'photoDimensionManual');await sleep(70);
 assert(doc.querySelector('#photoOverlay line[stroke-width="3"]'),'adjustable width saved');
 click(doc,'photoAddRect');await sleep(70);
 assert(doc.querySelector('#photoOverlay rect'),'rectangle overlay appears');
 w.prompt=()=> 'Tomada atrás do armário';click(doc,'photoNoteAdd');await sleep(50);assert(doc.body.textContent.includes('Tomada atrás do armário'),'annotation saved');
 // prompt may be unavailable in jsdom: no-op possible here.
 const roomSelector=doc.getElementById('photoRoom');
 assert(roomSelector,'room association selector exists');
 w.HTMLCanvasElement.prototype.getContext=oldCanvas;

 console.log('UI INTEGRAÇÃO OK: cliente, obra, chapa, edição e rascunho persistiram após recriar a tela.');
 x.dom.window.close();
})().catch(err=>{console.error(err);process.exitCode=1;});
