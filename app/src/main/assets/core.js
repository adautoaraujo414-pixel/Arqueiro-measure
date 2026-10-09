/* Arque Measure deterministic calculation and data core — no AI, no network. */
(function(root,factory){ const api=factory(); if(typeof module==='object'&&module.exports)module.exports=api; root.ArqueCore=api; })(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const uid=()=> (typeof crypto!=='undefined'&&crypto.randomUUID)?crypto.randomUUID():'id-'+Date.now().toString(36)+'-'+Math.random().toString(36).slice(2);
const mm=v=>{if(String(v??'').trim()==='')throw Error('Medida obrigatória.');let n=Number(String(v).replace(',','.'));if(!Number.isFinite(n)||n<0||n>1000000)throw Error('Informe uma medida válida em milímetros (0 a 1.000.000).');return n;};
const money=v=>{let n=Number(v);if(!Number.isFinite(n)||n<0||n>1000000000)throw Error('Valor financeiro inválido.');return Math.round(n*100)/100;};
function socket(w,left,obj,right,tolerance=5){[w,left,obj,right,tolerance].forEach(mm);const error=w-left-obj-right;return {center:left+obj/2,rightEdge:left+obj,closureError:error,withinTolerance:Math.abs(error)<=tolerance};}
function variations(vals){if(!Array.isArray(vals)||!vals.length)throw Error('Informe pelo menos uma medida.');const arr=vals.map(mm);return {min:Math.min(...arr),max:Math.max(...arr),difference:Math.max(...arr)-Math.min(...arr),count:arr.length};}
function carcass(top,stone,base,clearance){[top,stone,base,clearance].forEach(mm);let result=top-stone-base-clearance;if(result<0)throw Error('A composição ultrapassa a altura disponível.');return {underside:top-stone,height:result};}
function usableOpening(values,leftClearance,rightClearance){let v=variations(values);[leftClearance,rightClearance].forEach(mm);if(v.min<leftClearance+rightClearance)throw Error('Folgas maiores que o vão.');return {minimum:v.min,usable:v.min-leftClearance-rightClearance,variation:v.difference};}
function diagonal(a,b){return Math.hypot(mm(a),mm(b));}
function finance(project){let total=money(project.value||0),discount=money(project.discount||0);if(discount>total)throw Error('Desconto maior que o contrato.');let paid=(project.payments||[]).reduce((s,p)=>s+money(p.amount),0);return {contract:total,discount,net:Math.round((total-discount)*100)/100,paid:Math.round(paid*100)/100,balance:Math.round((total-discount-paid)*100)/100};}
function measurement(value,kind,source='manual',target='',ref=''){return {id:uid(),value:mm(value),kind:String(kind||'distância'),source,target,reference:ref,createdAt:new Date().toISOString()};}
function client(name,phone='',address=''){if(!name.trim())throw Error('Informe o nome do cliente.');return {id:uid(),name:name.trim(),phone,address,createdAt:new Date().toISOString()};}
function project(clientId,name,address=''){if(!clientId||!name.trim())throw Error('Informe cliente e nome da obra.');return {id:uid(),clientId,name:name.trim(),address,status:'Levantamento',value:0,discount:0,payments:[],rooms:[],photos:[],notes:[],createdAt:new Date().toISOString(),updatedAt:new Date().toISOString(),revision:1};}
function room(name){if(!name.trim())throw Error('Informe o ambiente.');return {id:uid(),name:name.trim(),measurements:[],elements:[],strokes:[],annotations:[],photoIds:[],createdAt:new Date().toISOString()};}
function validateImport(obj){if(!obj||obj.format!=='arque-measure'||obj.version!==1||!obj.state||!Array.isArray(obj.state.clients)||!Array.isArray(obj.state.projects))throw Error('Backup incompatível ou inválido.');for(const p of obj.state.projects){if(!p.id||!p.clientId||!Array.isArray(p.rooms)||!Array.isArray(p.photos)||!Array.isArray(p.payments))throw Error('Projeto inválido no backup.');}return obj.state;}
function exportProject(state,id){
 const p=state.projects.find(p=>p.id===id);if(!p)throw Error('Projeto não encontrado');
 const client=state.clients.find(c=>c.id===p.clientId);if(!client)throw Error('Cliente do projeto não encontrado');
 return {format:'arque-link',version:1,createdAt:new Date().toISOString(),client:structuredClone(client),project:structuredClone(p)};
}
function mergeProject(state,raw){
 if(!raw||raw.format!=='arque-link'||raw.version!==1||!raw.client||!raw.project)throw Error('Arquivo Arque Link incompatível');
 const c=raw.client,p=raw.project;
 if(!c.id||typeof c.name!=='string'||!c.name.trim()||!p.id||p.clientId!==c.id||typeof p.name!=='string'||!p.name.trim()||!Array.isArray(p.rooms)||!Array.isArray(p.photos)||!Array.isArray(p.payments))throw Error('Dados do projeto inválidos');
 const next=structuredClone(state);
 // Import as an independent copy. Never overwrite local measurements or projects.
 let newClient=next.clients.find(x=>x.id===c.id);
 if(!newClient){newClient=structuredClone(c);next.clients.push(newClient)}
 const copy=structuredClone(p);copy.id=uid();copy.clientId=newClient.id;copy.name=p.name+' (recebido)';copy.linkOriginId=p.id;copy.linkReceivedAt=new Date().toISOString();
 next.projects.push(copy);return {state:next,projectId:copy.id};
}
// Audits compare repeated measurements only when type, position and reference match.
// They do NOT infer geometry, update values or invent readings.
function auditMeasurements(measurements,tolerance=5){
 const limit=mm(tolerance);if(!Array.isArray(measurements))throw Error('Lista de medições inválida.');
 const groups=new Map();const invalid=[];
 for(const m of measurements){
  try{
   const value=mm(m.value);const kind=String(m.kind||'').trim();const target=String(m.target||'').trim();const reference=String(m.reference||'').trim();
   if(!kind||!target||!reference){invalid.push({id:m.id||null,reason:'Preencha tipo, identificação e referência antes de comparar.'});continue;}
   const key=JSON.stringify([kind.toLowerCase(),target.toLowerCase(),reference.toLowerCase()]);
   if(!groups.has(key))groups.set(key,[]);groups.get(key).push({id:m.id,value,kind,target,reference});
  }catch(e){invalid.push({id:m?.id||null,reason:e.message});}
 }
 const compared=[];
 for(const items of groups.values())if(items.length>=2){const vals=items.map(x=>x.value);const min=Math.min(...vals),max=Math.max(...vals);compared.push({kind:items[0].kind,target:items[0].target,reference:items[0].reference,count:items.length,min,max,difference:max-min,withinTolerance:max-min<=limit,measurementIds:items.map(x=>x.id)});}
 return {compared,invalid,notComparable:measurements.length-invalid.length-compared.reduce((n,g)=>n+g.count,0)};
}
function unusedBleReadings(readings,rooms){const used=new Set((rooms||[]).flatMap(r=>(r.measurements||[]).map(m=>m.readingId||m.originalReadingId).filter(Boolean)));return (readings||[]).filter(x=>!used.has(x.id));}
function decodeBosch(hex){let bytes=typeof hex==='string'?hex.replace(/[^0-9a-f]/gi,'').match(/.{2}/g)?.map(x=>parseInt(x,16)):Array.from(hex||[]);if(!bytes||bytes.length<11||bytes[0]!==0xc0||bytes[1]!==0x55||bytes[2]!==0x10||bytes[3]!==0x06)return null;const a=new Uint8Array(bytes.slice(7,11));const meters=new DataView(a.buffer).getFloat32(0,true);if(!Number.isFinite(meters)||meters<0.05||meters>50)return null;return Math.round(meters*1000);}
return {auditMeasurements,unusedBleReadings,exportProject,mergeProject,uid,mm,money,socket,variations,carcass,usableOpening,diagonal,finance,measurement,client,project,room,validateImport,decodeBosch};
});
