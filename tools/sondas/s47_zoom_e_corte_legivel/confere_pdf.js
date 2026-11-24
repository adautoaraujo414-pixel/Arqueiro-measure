const {chromium}=require('playwright');const fs=require('fs');const [DIR,OUT,KEY]=process.argv.slice(2);
(async()=>{const b=await chromium.launch();const p=await b.newPage({viewport:{width:1366,height:900}});await p.addInitScript(fs.readFileSync(process.env.PONTE,'utf8'));
await p.goto('file://'+DIR+'/app/src/main/assets/editor.html?lang=pt');await p.waitForTimeout(2500);await p.evaluate(fs.readFileSync(__dirname+'/confere_textos.js','utf8'));
const D=JSON.parse(fs.readFileSync(process.env.PROJ,'utf8'));
await p.evaluate(async(st)=>{window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};loadState(JSON.parse(st));draw();openCut();await new Promise(r=>setTimeout(r,2500))},D[KEY].st);
await p.emulateMedia({media:'print'});await p.evaluate(()=>{var hd=document.getElementById('pthead');if(hd)hd.style.display='block'});
const r=await p.evaluate(()=>{var c=__cutTxtChk(document.getElementById('cutm'));return {chapas:c.chapas,textos:c.textos,ruins:c.ruins.length,semTexto:c.semTexto,ex:c.ruins.slice(0,3)}});
await p.pdf({path:OUT,format:'A4',printBackground:true});console.log(JSON.stringify(r));await b.close()})();
