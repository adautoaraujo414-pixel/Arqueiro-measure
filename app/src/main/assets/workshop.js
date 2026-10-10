/* Engenharia auxiliar do Laboratório. Geometria real em mm, sem inferir CNC. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueWorkshop=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const n=(v,name,min=0,max=50000)=>{if(v===null||v===undefined||String(v).trim()==='')throw Error(name+' obrigatório.');const x=Number(String(v).replace(',','.'));if(!Number.isFinite(x)||x<min||x>max)throw Error(name+' inválido ('+min+' a '+max+' mm).');return Math.round(x*10)/10;};
const clone=x=>JSON.parse(JSON.stringify(x));
const uid=()=>Date.now().toString(36)+'-'+Math.random().toString(36).slice(2);
function library(state){if(!Array.isArray(state.profileTemplates))state.profileTemplates=[];return state.profileTemplates;}
function saveProfile(state,item,name){
 if(item?.kind!=='pen'||!Array.isArray(item.points)||item.points.length<2)throw Error('Desenhe primeiro um traço livre com no mínimo dois pontos.');
 const label=String(name||'').trim().slice(0,90);if(!label)throw Error('Informe um nome para a moldura.');
 if(item.points.length>4000)throw Error('Desenho muito complexo. Simplifique para no máximo 4.000 pontos.');
 const coords=item.points.map(p=>[n(p[0],'X'),n(p[1],'Y')]);
 let minX=Math.min(...coords.map(p=>p[0])),minY=Math.min(...coords.map(p=>p[1]));
 let maxX=Math.max(...coords.map(p=>p[0])),maxY=Math.max(...coords.map(p=>p[1]));
 const width=Math.round((maxX-minX)*10)/10,height=Math.round((maxY-minY)*10)/10;
 if(width<5||height<5)throw Error('Moldura muito pequena: desenhe um contorno com largura e altura maiores que 5 mm.');
 const points=coords.map(p=>[Math.round((p[0]-minX)/width*10000)/10000,Math.round((p[1]-minY)/height*10000)/10000]);
 const itemTpl={id:uid(),name:label,createdAt:new Date().toISOString(),version:1,width,height,points,manufacturable:false};
 library(state).push(itemTpl);return itemTpl;
}
function insertProfile(template,x=100,y=100,view='front'){
 if(!template||!Array.isArray(template.points)||template.points.length<2)throw Error('Modelo de moldura inválido.');
 const w=n(template.width,'Largura da moldura',5),h=n(template.height,'Altura da moldura',5);
 if(!['front','plan'].includes(view))throw Error('Vista inválida.');
 return {id:uid(),kind:'profile',label:template.name,x:n(x,'X'),y:n(y,'Y'),w,d:h,height:0,
  view,profileId:template.id,points:clone(template.points),refs:{},manufacturable:false};
}
function fit(spec,opening,left=0,right=0,engine){
 if(!engine||typeof engine.parts!=='function')throw Error('Motor de módulos indisponível.');
 const w=n(opening,'Vão medido',150);
 const discount=n(left,'Folga esquerda',0,500)+n(right,'Folga direita',0,500);
 const desired=Math.round((w-discount-n(spec.leftFiller??0,'Tamponamento esquerdo')-n(spec.rightFiller??0,'Tamponamento direito'))*10)/10;
 if(desired<=150)throw Error('Vão útil insuficiente depois das folgas e tamponamentos.');
 const candidate={...spec,width:desired};
 const derived=engine.parts(candidate);
 return {spec:derived.spec,opening:w,clearance:discount,installed:derived.installedWidth,remaining:Math.round((w-derived.installedWidth)*10)/10};
}
function footprint(item){
 const w=Number(item.w)+Number(item.moduleSpec?.leftFiller||0)+Number(item.moduleSpec?.rightFiller||0);
 const d=Number(item.d)+(item.moduleSpec?.back==='overlay'?Number(item.moduleSpec.backThickness||0):0);
 return Number(item.rotation||0)%180===90?{w:d,d:w}:{w,d};
}
function roomAudit(layout){
 const issues=[],modules=(layout.items||[]).filter(x=>x.kind==='module'&&x.moduleSpec);
 if(!layout.confirmed)issues.push({severity:'warning',code:'UNCONFIRMED',message:'Dimensões do ambiente ainda não confirmadas por medição.'});
 for(const m of modules){
  const s=m.moduleSpec;
  const {w:width,d:depth}=footprint(m);
  if([m.x,m.y,width,depth].some(v=>!Number.isFinite(Number(v)))){issues.push({severity:'error',code:'INVALID',moduleId:m.id,message:'Geometria inválida: '+m.label});continue;}
  if(m.x<0||m.y<0||m.x+width>layout.width+0.01||m.y+depth>layout.depth+0.01){
   issues.push({severity:'error',code:'OUTSIDE',moduleId:m.id,message:m.label+' ultrapassa a parede ou a profundidade do ambiente.'});
  }
  const z=Number(m.z||0);
  if(!Number.isFinite(z)||z<0||z+Number(m.height)>Number(layout.height)+0.01)issues.push({severity:'error',code:'HEIGHT',moduleId:m.id,message:m.label+' ultrapassa a altura registrada: Z '+z+' mm + corpo '+m.height+' mm.'});
 }
 for(let i=0;i<modules.length;i++)for(let j=i+1;j<modules.length;j++){
  const a=modules[i],b=modules[j];
  const {w:aw,d:ad}=footprint(a),{w:bw,d:bd}=footprint(b);
  const az=Number(a.z||0),bz=Number(b.z||0),ah=Number(a.height||0),bh=Number(b.height||0);
  if(a.x<b.x+bw&&b.x<a.x+aw&&a.y<b.y+bd&&b.y<a.y+ad&&az<bz+bh&&bz<az+ah)issues.push({severity:'error',code:'OVERLAP',moduleId:a.id,message:a.label+' e '+b.label+' se sobrepõem na planta.'});
 }
 return {issues,errors:issues.filter(i=>i.severity==='error'),warnings:issues.filter(i=>i.severity!=='error'),productionReady:issues.length===0,checkedModules:modules.length};
}
return {library,saveProfile,insertProfile,fit,roomAudit};
});