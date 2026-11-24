const {chromium}=require('playwright');const fs=require('fs');const [P1,P2,PONTE]=process.argv.slice(2);
(async()=>{const b=await chromium.launch();const ponte=fs.readFileSync(PONTE,'utf8');
const pg=async(port)=>{const p=await (await b.newContext({viewport:{width:1366,height:768}})).newPage();await p.addInitScript(ponte);await p.goto('http://127.0.0.1:'+port+'/editor.html?lang=pt&v='+Math.random(),{waitUntil:'load'});await p.waitForTimeout(2500);return p};
const a=await pg(P1);const d=await a.evaluate('(async()=>{'+fs.readFileSync(process.argv[5],'utf8')+'})()');const c=await pg(P2);await c.evaluate((d)=>{window.__D=JSON.parse(d)},d);const r=await c.evaluate('(async()=>{'+fs.readFileSync(process.argv[6],'utf8')+'})()');console.log(r);await b.close()})();
