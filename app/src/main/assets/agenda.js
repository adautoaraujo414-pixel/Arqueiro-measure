/* Arque Agenda: offline schedule calculations, no external calendar or network required. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueAgenda=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const MINUTE=60000;
const types=['Entrega','Medição','Montagem','Visita técnica','Reunião','Compra de material','Pessoal','Outro'];
const reminderOptions=[0,10,30,60,120,1440];
const parse=value=>{const time=new Date(value).getTime();if(!Number.isFinite(time))throw Error('Informe uma data e horário válidos.');return time;};
const dayOf=value=>{const t=String(value||'');return t.slice(0,10);};
function validate(raw,existing=[]){
 const title=String(raw.title||'').trim(),type=types.includes(raw.type)?raw.type:'Outro';
 if(!title||title.length>120)throw Error('Informe um título de até 120 caracteres.');
 const startAt=String(raw.startAt||''),endAt=String(raw.endAt||'');
 const start=parse(startAt),end=parse(endAt);
 if(end<=start)throw Error('O horário final precisa ser posterior ao inicial.');
 if(end-start>14*24*60*MINUTE)throw Error('O compromisso não pode ultrapassar 14 dias.');
 const reminderMinutes=Number(raw.reminderMinutes);
 if(!reminderOptions.includes(reminderMinutes))throw Error('Antecedência de notificação inválida.');
 const item={id:String(raw.id||''),title,type,startAt,endAt,reminderMinutes,
  projectId:String(raw.projectId||''),notes:String(raw.notes||'').trim().slice(0,1500),
  status:['Pendente','Concluído','Cancelado'].includes(raw.status)?raw.status:'Pendente'};
 const collisions=conflicts(existing,item);
 if(collisions.length)throw Error('Horário ocupado por: '+collisions.map(x=>x.title).slice(0,3).join(', ')+'. Ajuste um dos compromissos.');
 return item;
}
function conflicts(items,item){
 const a=parse(item.startAt),b=parse(item.endAt);
 return (items||[]).filter(x=>x.id!==item.id&&x.status!=='Cancelado'&&x.status!=='Concluído'&&a<parse(x.endAt)&&b>parse(x.startAt));
}
function dayEvents(items,day){const start=parse(day+'T00:00'),end=new Date(start);end.setDate(end.getDate()+1);return (items||[]).filter(x=>parse(x.startAt)<end.getTime()&&parse(x.endAt)>start).slice().sort((a,b)=>parse(a.startAt)-parse(b.startAt));}
function freeSlots(items,day,from='08:00',until='19:00'){
 const start=parse(day+'T'+from),end=parse(day+'T'+until);
 if(end<=start)throw Error('Intervalo de expediente inválido.');
 const taken=dayEvents(items,day).filter(x=>x.status!=='Cancelado'&&x.status!=='Concluído')
 .map(x=>[Math.max(start,parse(x.startAt)),Math.min(end,parse(x.endAt))]).filter(([a,b])=>b>a).sort((a,b)=>a[0]-b[0]);
 const gaps=[];let cursor=start;
 for(const [a,b] of taken){if(a>cursor)gaps.push({start:cursor,end:a,minutes:Math.round((a-cursor)/MINUTE)});cursor=Math.max(cursor,b);}
 if(cursor<end)gaps.push({start:cursor,end,minutes:Math.round((end-cursor)/MINUTE)});
 return gaps;
}
function nativeReminders(items,now=Date.now()){
 return (items||[]).filter(x=>x.status==='Pendente'&&parse(x.startAt)>now&&parse(x.startAt)<now+366*24*60*MINUTE)
 .map(x=>({id:x.id,title:x.title,type:x.type,notes:x.notes||'',at:parse(x.startAt),reminderMinutes:Number(x.reminderMinutes||0)}));
}
return {types,reminderOptions,parse,dayOf,validate,conflicts,dayEvents,freeSlots,nativeReminders};
});
