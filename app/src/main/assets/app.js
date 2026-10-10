/* Arque Measure offline UI. All data saved to IndexedDB on this device. */
(()=>{'use strict';
const C=window.ArqueCore; const $=s=>document.querySelector(s);
const escape=s=>String(s??'').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const money=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const fmt=v=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
const statuses=['Levantamento','Projeto','Orçamento','Aprovado','Produção','Montagem','Finalizado','Cancelado'];
let navigationHistory=[];let pendingPhotoRoom='';let pendingPhotoCategory='Levantamento',drawColor='#ffd329';
let photoPlacement=false, photoPlacementStart=null, photoPlacementPreview=null;
let photoZoom=1,photoPanX=0,photoPanY=0,photoZoomMode=false;
const photoZoomClamp=n=>Math.max(1,Math.min(5,n));
function applyPhotoZoom(){const surface=$('#photoZoomSurface');if(surface){surface.style.transform='translate('+photoPanX+'px,'+photoPanY+'px) scale('+photoZoom+')';}const readout=$('#photoZoomReadout');if(readout)readout.textContent=Math.round(photoZoom*100)+'%';
 // All photo annotations zoom with the image at the same scale.
}
function photoZoomSet(n){photoZoom=photoZoomClamp(n);if(photoZoom===1){photoPanX=0;photoPanY=0;}applyPhotoZoom();}

let studioPageId=null, studioFullscreen=false, studioMode='esboco', studioInk='#176f9d', studioWidth=3, studioTool='pen', studioGrid='dots', studioActive=false, studioPoints=[];
let linkPeers=[];
let linkInfo=null,linkNotice='';
let db, state={clients:[],projects:[],settings:{tolerance:5}},tab='home',selectedClient=null,selectedProject=null,selectedRoom=null,subtab='medidas',lastBLE=null,lastBleReceipt=null,bleReadings=[],bleDevice=null,diagnostics=null,cameraCheck='Não testada',drawActive=false,drawPoints=[];
const field=(id,label,type='text',value='',extra='')=>`<div class="field"><label for="${id}">${escape(label)}</label><input id="${id}" type="${type}" value="${escape(value)}" ${extra}></div>`;
const select=(id,label,items,value='')=>`<div class="field"><label for="${id}">${escape(label)}</label><select id="${id}">${items.map(x=>{const val=typeof x==='string'?x:x.id, txt=typeof x==='string'?x:x.name;return `<option value="${escape(val)}" ${val===value?'selected':''}>${escape(txt)}</option>`}).join('')}</select></div>`;
const btn=(label,action,arg='',cl='')=>`<button class="btn ${cl}" data-action="${action}" data-arg="${escape(arg)}">${label}</button>`;
function toast(t){const el=$('#toast');el.textContent=t;el.style.display='block';clearTimeout(toast.t);toast.t=setTimeout(()=>el.style.display='none',3800)}
function openDb(){return new Promise((resolve,reject)=>{let req=indexedDB.open('arque_measure_local',1);req.onupgradeneeded=()=>req.result.createObjectStore('store');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});}
function readState(){return new Promise((resolve,reject)=>{let r=db.transaction('store').objectStore('store').get('state');r.onsuccess=()=>resolve(r.result||null);r.onerror=()=>reject(r.error);});}
function persist(){const now=new Date().toISOString();const active=state.projects.find(x=>x.id===selectedProject);if(active)active.updatedAt=now;const client=state.clients.find(x=>x.id===(active?.clientId||selectedClient));if(client)client.updatedAt=now;return new Promise((resolve,reject)=>{let r=db.transaction('store','readwrite').objectStore('store').put(state,'state');r.onsuccess=()=>resolve();r.onerror=()=>reject(r.error);});}
function project(){return state.projects.find(p=>p.id===selectedProject)}
function room(){return project()?.rooms.find(r=>r.id===selectedRoom)}

function latestProjectMeasurement(p){
  if(!p)return null;
  let out=null;
  for(const r of (p.rooms||[]))for(const m of (r.measurements||[])){
    // Historical records are compared by creation time, never by their last edit.
    if(!out||String(m.createdAt||'')>String(out.measurement.createdAt||''))out={room:r,measurement:m};
  }
  return out;
}
function editLastMeasureView(p){
 const last=latestProjectMeasurement(p);
 if(!last)return `<div class="card"><h3>Editar última medida do projeto</h3><p class="muted">Nenhuma medição salva ainda.</p></div>`;
 const m=last.measurement;
 return `<div class="card"><h3>Editar última medida do projeto</h3><p class="muted">Ambiente: ${escape(last.room.name)} · ${escape(m.createdAt||'')} · Origem: ${escape(m.source||'manual')}</p><p class="muted">Valor original registrado: ${fmt(m.rawValue??m.value)} mm. Correções são manuais e ficam no histórico; a leitura Bluetooth original é preservada.</p><div class="fields">${field('editLastValue','Valor corrigido (mm)','number',m.value,'min="0" step="0.01"')}${field('editLastKind','Tipo / descrição','text',m.kind)}${field('editLastTarget','Identificação / posição','text',m.target)}${field('editLastReference','Referência','text',m.reference)}</div>${btn('Salvar correção da última medida','editLastMeasure',m.id,'primary')}<p class="muted">Editar não muda a ordem das medições nem apaga o registro original.</p></div>`;
}

function clientName(id){return state.clients.find(c=>c.id===id)?.name||'Cliente desconhecido'}
function header(title,description=''){return `<h1>${title}</h1>${description?`<p class="intro">${description}</p>`:''}`}
function render(){const main=$('#main');try{main.innerHTML=({home:homeView,clients:clientsView,projects:projectsView,tools:toolsView,transfer:transferView,diagnostics:diagnosticsView})[tab]();}catch(e){main.innerHTML=`<div class="notice">Falha ao exibir: ${escape(e.message)}</div>`;}document.querySelectorAll('nav button').forEach(b=>b.classList.toggle('active',b.dataset.tab===tab)); if(tab==='projects'&&project()&&subtab==='desenho')setTimeout(()=>{setupDrawing();const dc=$('#drawColor');if(dc)dc.value=drawColor;},0);if(tab==='projects'&&project()&&subtab==='atelier')setTimeout(setupStudio,0);}
function workGroup(status){
 if(status==='Finalizado')return 'finalizados';
 if(status==='Cancelado')return 'cancelados';
 if(status==='Orçamento')return 'orcamentos';
 if(status==='Aprovado'||status==='Produção'||status==='Montagem')return 'andamento';
 return 'levantamento';
}
const groupNames={andamento:'Em andamento',orcamentos:'Orçamentos',levantamento:'Levantamentos e projetos',finalizados:'Finalizados',cancelados:'Cancelados'};
function statusBadge(status){return '<span class="project-status status-'+workGroup(status)+'">'+escape(status||'Levantamento')+'</span>';}
function projectRow(p){return '<div class="item project-row"><div><strong>'+escape(clientName(p.clientId))+' · '+escape(p.name)+'</strong><small>'+escape(p.address||'')+' · '+(p.rooms||[]).length+' ambientes</small></div><div class="project-row-end">'+statusBadge(p.status)+btn('Abrir','openProject',p.id,'small')+'</div></div>';}
function groupedProjects(projects){
 return Object.keys(groupNames).map(k=>{
 const entries=projects.filter(p=>workGroup(p.status)===k);
 return '<details class="project-group" '+(k==='andamento'||k==='orcamentos'||k==='levantamento'?'open':'')+'><summary>'+groupNames[k]+' <span class="group-count">'+entries.length+'</span></summary>'+
 (entries.map(projectRow).join('')||'<p class="muted">Nenhum projeto nesta categoria.</p>')+'</details>';
 }).join('');
}
function homeView(){
 const active=state.projects.filter(p=>!['Finalizado','Cancelado'].includes(p.status));
 return header('Painel de clientes e obras','Cada obra tem seus próprios ambientes, medidas, desenhos, corte e contratos.')+
 '<div class="grid"><div class="card"><small class="muted">Clientes</small><div class="stat">'+state.clients.length+'</div>'+btn('Abrir clientes','go','clients','primary')+'</div>'+
 '<div class="card"><small class="muted">Obras ativas</small><div class="stat">'+active.length+'</div></div>'+
 '<div class="card"><small class="muted">Obras finalizadas</small><div class="stat">'+state.projects.filter(p=>p.status==='Finalizado').length+'</div></div></div>'+
 '<div class="card"><h3>Projetos por situação</h3>'+groupedProjects(state.projects)+'</div>';
}
function contractsView(c){
 if(!Array.isArray(c.contracts))c.contracts=[];
 const related=state.projects.filter(p=>p.clientId===c.id);
 return '<div class="card"><h3>Contratos e documentos do cliente</h3><p class="muted">Anexe PDF ou imagem. Os arquivos ficam neste aparelho e são incluídos no backup Arque.</p>'+
 '<div class="fields">'+select('contractProject','Vincular à obra',[{id:'',name:'Geral do cliente'},...related.map(p=>({id:p.id,name:p.name}))])+'</div>'+
 btn('Anexar contrato (PDF ou imagem)','contractAttach','','primary')+
 c.contracts.map(doc=>'<div class="item"><div><strong>'+escape(doc.name)+'</strong><small>'+escape(related.find(p=>p.id===doc.projectId)?.name||'Documento geral')+' · '+escape(doc.date||'')+'</small></div><div class="actions">'+btn('Abrir','contractOpen',doc.id,'small')+btn('Excluir','contractRemove',doc.id,'small danger')+'</div></div>').join('')+
 (c.contracts.length?'':'<div class="empty">Nenhum contrato anexado ainda.</div>')+'</div>';
}
function clientsView(){
 if(selectedClient){
  const c=state.clients.find(x=>x.id===selectedClient);
  if(!c){selectedClient=null;return clientsView();}
  const projects=state.projects.filter(p=>p.clientId===c.id);
  return '<div class="row"><div>'+header(escape(c.name),'Cliente · '+escape(c.phone||'Sem telefone')+' · '+escape(c.address||'Sem endereço'))+'</div>'+btn('← Clientes','closeClient','','small')+'</div>'+
   '<div class="card"><h3>Obras de '+escape(c.name)+'</h3><p class="muted">Abra a obra para acessar suas ferramentas.</p>'+(projects.length?projects.map(pr=>'<div class="item"><div><strong>'+escape(pr.name)+'</strong><small>'+escape(pr.status)+' · '+(pr.rooms||[]).length+' ambientes</small></div>'+btn('Abrir','openProject',pr.id,'small primary')+'</div>').join(''):'<p class="muted">Nenhuma obra ainda.</p>')+
   '<div class="actions">'+btn('+ Nova obra','clientProject',c.id,'primary')+'</div></div>'+contractsView(c);
 }
 return header('Clientes','Abra o cliente para acessar projetos e contratos.')+
 '<div class="card"><h3>Novo cliente</h3><div class="fields">'+field('cname','Nome completo')+field('cphone','Telefone','tel')+field('caddr','Endereço')+'</div>'+btn('Salvar cliente','addClient','','primary')+'</div>'+
 '<div class="card"><h3>Clientes por nome ('+state.clients.length+')</h3>'+
 state.clients.slice().sort((a,b)=>a.name.localeCompare(b.name,'pt-BR')).map(c=>{
 const ps=state.projects.filter(p=>p.clientId===c.id);
 const dates=[c.createdAt,c.updatedAt,...ps.map(p=>p.updatedAt||p.createdAt),...(c.contracts||[]).map(d=>d.createdAt)].filter(Boolean).sort();
 const fmtDate=v=>v?new Date(v).toLocaleDateString('pt-BR'):'—';
 return '<div class="item project-row"><div><strong>'+escape(c.name)+'</strong><small>'+escape(c.phone||'')+' · '+ps.length+' obra(s)</small><small class="client-dates">Cadastro: '+fmtDate(c.createdAt)+' · Última movimentação: '+fmtDate(dates[dates.length-1])+'</small></div><div class="project-row-end">'+btn('Abrir','openClient',c.id,'small')+'</div></div>';}).join('')+
 (state.clients.length?'':'<div class="empty">Nenhum cliente cadastrado.</div>')+'</div>';
}
function projectsView(){
 if(project())return detailView();
 if(selectedClient){
  const c=state.clients.find(x=>x.id===selectedClient);
  if(!c){selectedClient=null;return projectsView();}
  return header('Nova obra de '+escape(c.name),'O projeto sempre pertence ao cliente selecionado.')+'<div class="card"><h3>Criar projeto</h3><div class="fields">'+select('pclient','Cliente',[c],c.id)+field('pname','Ambiente (ex.: Cozinha, Quarto, Sala)')+'</div>'+btn('Criar projeto','addProject','','primary')+btn('← Voltar aos projetos','closeProject','','small')+'</div>';
 }
 return header('Projetos','Abra uma obra existente ou selecione um cliente para criar uma nova. Cada obra continua vinculada ao seu cliente.')+
 '<div class="card"><h3>Nova obra</h3><p class="muted">Escolha primeiro o cliente.</p>'+
 (state.clients.length?'<div class="fields">'+select('projectClientPick','Cliente',state.clients.slice().sort((a,b)=>a.name.localeCompare(b.name,'pt-BR')))+'</div>'+btn('Criar obra para este cliente','chooseProjectClient','','primary'):btn('Cadastrar primeiro cliente','go','clients','primary'))+'</div>'+
 '<div class="card"><h3>Obras cadastradas ('+state.projects.length+')</h3>'+groupedProjects(state.projects)+'</div>';
}
function cuttingPlan(p){if(!p.cutPlan)p.cutPlan={width:2750,height:1830,kerf:3,trim:0,pieces:[]};return p.cutPlan;}

function archiveCutRevision(plan,piece,reason){
 if(!plan.cutHistory)plan.cutHistory=[];
 const done=plan.cutDone||{};
 const completed=Array.from({length:Math.max(0,Number(piece.qty)||0)},(_,i)=>({unit:i+1,finishedAt:done[piece.id+':'+(i+1)]||null}));
 plan.cutHistory.push({id:C.uid(),pieceId:piece.id,name:String(piece.name),w:Number(piece.w),h:Number(piece.h),qty:Number(piece.qty),grain:!!piece.grain,rotate:piece.rotate!==false,reason,at:new Date().toISOString(),units:completed});
}
function cutHistoryView(plan){
 const history=(plan.cutHistory||[]).slice().reverse();
 return '<details class="card cut-history"><summary><strong>Histórico de fabricação e revisões</strong> ('+history.length+')</summary><p class="muted">Medidas antigas e peças concluídas continuam registradas mesmo quando uma peça é alterada ou retirada do plano atual.</p>'+
 (history.map(h=>'<div class="item"><div><strong>'+escape(h.name)+' · '+Number(h.w).toLocaleString('pt-BR')+' × '+Number(h.h).toLocaleString('pt-BR')+' mm</strong><small>'+escape(h.reason||'Revisão')+' · '+new Date(h.at).toLocaleString('pt-BR')+' · '+h.qty+' unidade(s), '+(h.units||[]).filter(u=>u.finishedAt).length+' concluída(s)</small></div></div>').join('')||'<p class="muted">Nenhuma revisão anterior.</p>')+'</details>';
}
function cutUnits(plan){
 const done=plan.cutDone||{};
 return plan.pieces.flatMap(piece=>Array.from({length:Number(piece.qty)||0},(_,i)=>({id:piece.id,key:piece.id+':'+(i+1),ordinal:i+1,name:piece.name,w:Number(piece.w),h:Number(piece.h),done:!!done[piece.id+':'+(i+1)],finishedAt:done[piece.id+':'+(i+1)]||null}))).sort((a,b)=>b.w*b.h-a.w*a.h||Math.max(b.w,b.h)-Math.max(a.w,a.h)||a.name.localeCompare(b.name,'pt-BR')||a.ordinal-b.ordinal);
}
function cutChecklistView(plan){
 const items=cutUnits(plan),finished=items.filter(p=>p.done).length;
 const number=n=>Number(n).toLocaleString('pt-BR',{maximumFractionDigits:2});
 return '<div class="card"><h3>Lista de corte · maior para menor</h3><p class="muted">Uma linha por unidade. Vermelho = falta cortar; verde = finalizada. O histórico fica salvo neste projeto e não desaparece quando você marcar OK.</p><div class="cut-progress">Total: <b>'+items.length+'</b> · Pendentes: <b>'+(items.length-finished)+'</b> · Finalizadas: <b>'+finished+'</b></div><div class="cut-production-list">'+items.map((p,i)=>'<div class="cut-status-line '+(p.done?'cut-finished':'cut-pending')+'"><span class="cut-item-n">'+(i+1)+'</span><div class="cut-item-description"><strong>'+escape(p.name)+' #'+p.ordinal+'</strong><small>'+number(p.w)+' × '+number(p.h)+' mm'+(p.done?' · Cortada em '+new Date(p.finishedAt).toLocaleString('pt-BR'):' · Falta cortar')+'</small></div>'+btn(p.done?'↶ Desfazer':'✓ OK', 'cutToggle',p.key,'small')+'</div>').join('')+'</div>'+(items.length?'':'<p class="muted">Adicione as peças acima para iniciar a lista.</p>')+'</div>';
}
function mixedStockView(plan){
 const stock=plan.mixedStock||{width:plan.width,height:plan.height,kerf:plan.kerf,trim:plan.trim,ids:plan.pieces.map(p=>p.id)};
 const n=v=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
 let outcome=null,error='';
 try{if(plan.pieces.length){outcome=window.ArqueCut.mixedStock({...stock,pieces:plan.pieces.filter(p=>stock.ids?.includes(p.id))});if(stock.moves&&Object.keys(stock.moves).length)outcome=window.ArqueCut.positionMixed(outcome,stock.moves);}}catch(e){error=e.message;}
 let html='<div class="card"><h3>Vários módulos na mesma chapa ou sobra</h3><p class="muted">Selecione peças diferentes, simule e arraste as peças com o dedo ou S Pen. O aplicativo impede sobreposição ou saída da chapa.</p><div class="fields">'+field('mixedW','Comprimento da chapa/sobra (mm)','number',stock.width,'min="1"')+field('mixedH','Largura da chapa/sobra (mm)','number',stock.height,'min="1"')+field('mixedKerf','Espessura da serra (mm)','number',stock.kerf,'min="0" step="0.1"')+field('mixedTrim','Refilo por lado (mm)','number',stock.trim,'min="0" step="0.1"')+'</div><div class="cut-checkboxes">'+plan.pieces.map(p=>'<label><input type="checkbox" data-mixed-piece="'+escape(p.id)+'" '+(stock.ids?.includes(p.id)?'checked':'')+'> '+escape(p.name)+' · '+n(p.w)+' × '+n(p.h)+' mm · '+p.qty+' un.</label>').join('')+'</div>'+btn('Simular peças juntas','mixedSimulate','','primary')+'</div>';
 if(error)html+='<div class="notice">'+escape(error)+'</div>';
 if(outcome){html+='<div class="card"><h3>Resultado: uma chapa</h3><div class="metric">Peças colocadas <b>'+outcome.placedCount+' de '+outcome.requested+'</b></div><div class="metric">Peças que não couberam <b>'+outcome.unplaced.length+'</b></div><div class="metric">Aproveitamento <b>'+n(outcome.utilization)+'%</b></div><div class="metric">Cortes estimados <b>'+outcome.cutCountEstimate+'</b></div><div class="cut-sheet mixed-drag-sheet" style="aspect-ratio:'+stock.width+'/'+stock.height+'">'+outcome.placed.map((p,i)=>'<div class="cut-piece mixed-movable" data-mixed-key="'+escape(p.id+':'+p.ordinal)+'" data-mixed-x="'+p.x+'" data-mixed-y="'+p.y+'" style="left:'+p.x/stock.width*100+'%;top:'+p.y/stock.height*100+'%;width:'+p.w/stock.width*100+'%;height:'+p.h/stock.height*100+'%;background:'+(plan.cutDone?.[p.id+':'+p.ordinal]?'#32ac64':'#e12d35')+';color:#fff">'+escape(p.name)+'<small>'+n(p.w)+' × '+n(p.h)+'</small></div>').join('')+'</div><h4>Ajustar posições manualmente (mm)</h4><p class="muted">X: da esquerda para direita; Y: de cima para baixo. Não permite peças sobrepostas nem fora da chapa. A ordem e as posições devem ser conferidas antes do corte.</p><div class="cut-table"><table><thead><tr><th>Peça</th><th>X (mm)</th><th>Y (mm)</th><th></th></tr></thead><tbody>'+outcome.placed.map(p=>'<tr><td>'+escape(p.name)+' #'+p.ordinal+'</td><td><input type="number" min="0" step="1" id="mx_'+escape(p.id)+'_'+p.ordinal+'" value="'+n(p.x).replace(/\\./g,'').replace(',','.')+'"></td><td><input type="number" min="0" step="1" id="my_'+escape(p.id)+'_'+p.ordinal+'" value="'+n(p.y).replace(/\\./g,'').replace(',','.')+'"></td><td>'+btn('Mover','mixedMove',p.id+':'+p.ordinal,'small')+'</td></tr>').join('')+'</tbody></table></div>'+btn('Voltar ao arranjo automático','mixedReset','','small')+'<h4>Sobras retangulares identificadas</h4>'+outcome.reusable.map((r,i)=>'<div class="item"><strong>Sobra '+(i+1)+'</strong><small>'+n(r.w)+' × '+n(r.h)+' mm</small></div>').join('')+(outcome.reusable.length?'':'<p class="muted">Nenhuma sobra retangular acima de 50 mm.</p>')+'<p class="muted">'+escape(outcome.note)+'</p></div>';}
 return html;
}
function manualCutView(p,plan){
 const stock=plan.manualStock||{width:plan.width,height:plan.height,kerf:plan.kerf,trim:plan.trim,partId:'',qty:0,rotate:true};
 let chosen=plan.pieces.find(x=>x.id===stock.partId)||plan.pieces[0];
 let outcome=null,error='';
 if(chosen){try{outcome=window.ArqueCut.manualGrid({...stock,partW:chosen.w,partH:chosen.h,qty:Number(stock.qty||chosen.qty),grain:chosen.grain,rotate:chosen.rotate});}catch(e){error=e.message;}}
 const n=v=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
 const metric=(name,value)=>'<div class="metric"><span>'+name+'</span><b>'+value+'</b></div>';
 let h='<div class="card"><h3>Modo manual · testar chapa ou sobra</h3><p class="muted">Digite o tamanho da chapa que você tem, escolha uma peça cadastrada de qualquer módulo deste projeto e veja quantas unidades cabem. Pode simular várias sobras sem alterar o plano automático.</p><div class="fields">'+field('manualSheetW','Comprimento disponível (mm)','number',stock.width,'min="1"')+field('manualSheetH','Largura disponível (mm)','number',stock.height,'min="1"')+field('manualKerf','Espessura serra (mm)','number',stock.kerf,'min="0" step="0.1"')+field('manualTrim','Refilo por lado (mm)','number',stock.trim,'min="0" step="0.1"')+'</div>';
 if(plan.pieces.length){h+='<div class="fields">'+select('manualPart','Peça / módulo',plan.pieces.map(x=>({id:x.id,name:x.name+' · '+n(x.w)+' × '+n(x.h)+' mm'})),chosen.id)+field('manualQty','Quantidade que você precisa','number',stock.partId===chosen.id?stock.qty||chosen.qty:chosen.qty,'min="0" step="1"')+'</div>'+btn('Simular aproveitamento','manualSimulate','','primary');}
 else h+='<div class="notice">Cadastre primeiro as peças dos módulos na lista acima.</div>';
 h+='</div>';
 if(error)h+='<div class="notice">'+escape(error)+'</div>';
 if(outcome){h+='<div class="card"><h3>Resultado da chapa disponível</h3>'+metric('Chapa informada',n(outcome.width)+' × '+n(outcome.height)+' mm')+metric('Peças que cabem',outcome.capacity)+metric('Peças solicitadas nesta simulação',outcome.placed+outcome.pending)+metric('Peças faltantes',outcome.pending)+metric('Distribuição',outcome.cols+' por faixa × '+outcome.rows+' faixas')+metric('Aproveitamento nesta simulação',n(outcome.utilization)+'%')+metric('Área restante (inclui serragem)',n(outcome.unusedArea/1e6)+' m²')+metric('Cortes retos estimados',outcome.estimatedCuts)+'<div class="cut-sheet" style="aspect-ratio:'+stock.width+'/'+stock.height+'">'+outcome.pieces.map((piece,i)=>'<div class="cut-piece" style="left:'+100*piece.x/stock.width+'%;top:'+100*piece.y/stock.height+'%;width:'+100*piece.w/stock.width+'%;height:'+100*piece.h/stock.height+'%;background:#b6ddeb">'+escape(chosen.name)+'<small>'+n(piece.w)+'×'+n(piece.h)+'</small></div>').join('')+'</div><p class="muted">'+escape(outcome.estimatedCutsNote)+' Sobra por área não equivale a uma única sobra retangular reutilizável. Verifique sentido do veio, posições e medidas na máquina.</p></div>';}
 return h;
}

function cuttingView(){
 const p=project(),plan=cuttingPlan(p);let result=null,error='';
 try{if(plan.pieces.length)result=window.ArqueCut.optimize(plan);}catch(e){error=e.message;}
 const met=(title,value)=>'<div class="metric"><span>'+title+'</span><b>'+value+'</b></div>';
 const num=(v)=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
 let html='<div class="card"><h3>Plano de corte · '+escape(clientName(p.clientId))+'</h3><p class="muted">Peças e chapas vinculadas a esta obra. Valores em milímetros; cálculo de aproveitamento com cortes guilhotinados.</p><div class="fields">'+field('cutWidth','Comprimento chapa (mm)','number',plan.width,'min="1"')+field('cutHeight','Largura chapa (mm)','number',plan.height,'min="1"')+field('cutKerf','Espessura serra (mm)','number',plan.kerf,'min="0" step="0.1"')+field('cutTrim','Refilo em cada borda (mm)','number',plan.trim,'min="0" step="0.1"')+'</div>'+btn('Salvar configuração','cutSettings','','primary')+'</div>';
 const draft=plan.draft||{name:'',w:'',h:'',qty:1,grain:false,rotate:true,edge2:0,edge04:0};
 html+='<div class="card"><div class="row"><div><h3>Peças · entrada em sequência</h3><p class="muted">Preencha uma linha por vez, como no SketchCut. Ao tocar em Adicionar linha, a próxima já fica pronta. As peças salvas podem ser editadas na própria tabela.</p></div>'+btn('+ Adicionar linha','cutAdd','','primary')+'</div>'+
 '<div class="cut-table"><table class="cut-entry"><thead><tr><th>#</th><th>Compr. (mm)</th><th>×</th><th>Largura (mm)</th><th>Quant.</th><th>Girar</th><th>Nome</th><th>Veio</th><th></th></tr></thead><tbody>'+
 plan.pieces.map((x,i)=>'<tr><td>'+(i+1)+'</td><td><input aria-label="Comprimento da peça '+(i+1)+'" inputmode="decimal" type="number" min="1" data-cut-id="'+escape(x.id)+'" data-cut-field="w" value="'+x.w+'"></td><td>×</td><td><input aria-label="Largura da peça '+(i+1)+'" type="number" min="1" data-cut-id="'+escape(x.id)+'" data-cut-field="h" value="'+x.h+'"></td><td><input aria-label="Quantidade da peça '+(i+1)+'" type="number" min="1" max="1000" step="1" data-cut-id="'+escape(x.id)+'" data-cut-field="qty" value="'+x.qty+'"></td><td><select aria-label="Rotação" data-cut-id="'+escape(x.id)+'" data-cut-field="rotate"><option value="true" '+(x.rotate?'selected':'')+'>Sim</option><option value="false" '+(!x.rotate?'selected':'')+'>Não</option></select></td><td><input aria-label="Nome" data-cut-id="'+escape(x.id)+'" data-cut-field="name" value="'+escape(x.name)+'"></td><td><select aria-label="Veio" data-cut-id="'+escape(x.id)+'" data-cut-field="grain"><option value="false" '+(!x.grain?'selected':'')+'>Livre</option><option value="true" '+(x.grain?'selected':'')+'>Fixo</option></select></td><td>'+btn('✕','cutRemove',x.id,'small danger')+'</td></tr>').join('')+
 '<tr class="cut-draft"><td>+</td><td><input id="cutW" data-cut-draft="w" aria-label="Comprimento novo" type="number" min="1" value="'+escape(draft.w)+'" placeholder="2750"></td><td>×</td><td><input id="cutH" data-cut-draft="h" aria-label="Largura nova" type="number" min="1" value="'+escape(draft.h)+'" placeholder="550"></td><td><input id="cutQty" data-cut-draft="qty" aria-label="Quantidade nova" type="number" min="1" value="'+escape(draft.qty)+'"></td><td><select id="cutRotate" data-cut-draft="rotate"><option value="Sim" '+(draft.rotate?'selected':'')+'>Sim</option><option value="Não" '+(!draft.rotate?'selected':'')+'>Não</option></select></td><td><input id="cutName" data-cut-draft="name" aria-label="Nome da nova peça" value="'+escape(draft.name)+'" placeholder="Lateral"></td><td><select id="cutGrain" data-cut-draft="grain"><option value="Livre" '+(!draft.grain?'selected':'')+'>Livre</option><option value="Fixo" '+(draft.grain?'selected':'')+'>Fixo</option></select></td><td>'+btn('+','cutAdd','','small primary')+'</td></tr>'+
 '</tbody></table></div><div class="fields cut-extra">'+field('cutEdge2','Fitas 2 mm · novas peças (0 a 4)','number',draft.edge2,'min="0" max="4" data-cut-draft="edge2"')+field('cutEdge04','Fitas 0,4 mm · novas peças (0 a 4)','number',draft.edge04,'min="0" max="4" data-cut-draft="edge04"')+'</div><div class="actions">'+btn('+ Adicionar linha','cutAdd','','primary')+'</div><p class="muted">Os campos da lista são salvos ao editar. Para salvar uma nova peça, toque em Adicionar linha.</p></div>';
 html+=cutChecklistView(plan)+cutHistoryView(plan)+mixedStockView(plan)+manualCutView(p,plan);
 if(error)html+='<div class="notice">Não foi possível calcular: '+escape(error)+'</div>';
 if(result){html+='<div class="card"><div class="row"><h3>Resultados</h3>'+btn('Imprimir / PDF','cutPrint','','small')+'</div>'+met('Dimensões da chapa',num(plan.width)+' × '+num(plan.height)+' mm')+met('Quantidade de chapas',result.sheetCount)+met('Estratégias comparadas',result.testedStrategies)+'<p class="muted">Otimização heurística: confira as dimensões e a sequência de cortes antes de produzir.</p>'+met('Área por chapa',num(plan.width*plan.height/1e6)+' m²')+met('Área das chapas',num(result.allocatedArea/1e6)+' m²')+met('Quantidade de peças',result.totalPieces)+met('Peças acomodadas',result.placedPieces)+met('Área das peças',num(result.usedArea/1e6)+' m²')+met('Sobra + serragem + refilo',num(result.wasteArea/1e6)+' m²')+met('Aproveitamento',num(result.utilization)+'%')+met('Estimativa comprimento de cortes',num(result.cutLengthEstimate/1000)+' m')+met('Fita 2 mm (aproximada)',num(result.edge2mm/1000)+' m')+met('Fita 0,4 mm (aproximada)',num(result.edge04mm/1000)+' m')+'</div>';
 if(result.unfit.length)html+='<div class="notice">ATENÇÃO: '+result.unfit.length+' peça(s) não cabem nesta chapa e NÃO foram incluídas no plano. Revise as dimensões antes de cortar.</div>';
 result.sheets.forEach((sh,i)=>{html+='<div class="card"><h3>Chapa '+(i+1)+' / '+result.sheetCount+'</h3><div class="cut-sheet" style="aspect-ratio:'+plan.width+'/'+plan.height+'">'+sh.pieces.map((x,j)=>'<div class="cut-piece" style="left:'+100*x.x/plan.width+'%;top:'+100*x.y/plan.height+'%;width:'+100*x.w/plan.width+'%;height:'+100*x.h/plan.height+'%;background:'+(plan.cutDone?.[x.id+':'+x.ordinal]?'#32ac64':'#e12d35')+';color:#fff" title="'+escape(x.name)+'">'+escape(x.name)+'<small>'+num(x.w)+' × '+num(x.h)+'</small></div>').join('')+'</div><small class="muted">Desenho proporcional em mm. Confirme a sequência de corte, o veio e as medidas antes da produção.</small></div>';});
 }
 return html;
}

function projectOverview(){
 const p=project();
 const tiles=[
 ['medidas','▱','Ambientes e medições',(p.rooms||[]).length+' ambientes'],
 ['fotos','▣','Fotografias',(p.photos||[]).length+' fotos'],
 ['fotomedidas','↔','Setas e medidas','Anotar diretamente sobre fotos'],
 ['atelier','✎','Esboço + Laboratório','Plantas, móveis e folhas A4 com S Pen'],
 ['corte','▦','Plano de corte','Peças, chapas e sobras'],
 ['calculo','⌗','Cálculos da obra','Conferência baseada no projeto'],
 ['financeiro','R$','Financeiro','Contrato e pagamentos']];
 return '<div class="card"><h3>Área de trabalho · '+escape(p.name)+'</h3><p class="muted">Tudo que você registrar aqui permanece vinculado à obra e ao cliente '+escape(clientName(p.clientId))+'.</p><div class="project-workspace">'+tiles.map(x=>'<button class="workspace-tile" data-action="'+(x[0]==='calculo'?'projectCalc':'openWorkspace')+'" data-arg="'+x[0]+'"><span class="workspace-icon">'+x[1]+'</span><strong>'+x[2]+'</strong><small>'+x[3]+'</small></button>').join('')+'</div></div>';
}
function detailView(){
 const p=project();
 return '<div class="row"><div><h1>'+escape(p.name)+'</h1><p class="intro">'+escape(clientName(p.clientId))+(p.address?' · '+escape(p.address):'')+'</p></div>'+btn('← Cliente','closeProject','','small')+'</div>'+
 '<div class="card"><div class="fields">'+select('pstatus','Etapa do serviço',statuses,p.status)+field('pvalue','Contrato (R$)','number',p.value,'min="0" step="0.01"')+field('pdiscount','Desconto (R$)','number',p.discount,'min="0" step="0.01"')+'</div>'+btn('Salvar informações da obra','saveProject','','primary')+'</div>'+
 '<div class="tabs">'+[['resumo','▦ Visão geral'],['medidas','📏 Ambientes'],['fotos','📷 Fotos'],['fotomedidas','↔ Setas na foto'],['atelier','✎ Esboço'],['corte','▦ Plano de corte'],['financeiro','R$ Financeiro']].map(([key,label])=>'<button data-subtab="'+key+'" class="'+(subtab===key?'selected':'')+'">'+label+'</button>').join('')+'</div>'+
 ({resumo:projectOverview,medidas:measureView,fotos:photoView,fotomedidas:photoMeasureView,desenho:drawView,atelier:studioView,corte:cuttingView,financeiro:financeView})[subtab]();
}
function auditRoomView(r){
 const check=C.auditMeasurements(r.measurements,state.settings.tolerance??5);
 return `<div class="card"><h3>Conferência técnica das medidas</h3><p class="muted">Comparação somente de medições com o mesmo tipo, identificação e referência. Tolerância: ${fmt(state.settings.tolerance??5)} mm. Valores não são alterados automaticamente.</p>`+
 (check.compared.map(g=>`<div class="item"><div><strong>${escape(g.kind)} — ${escape(g.target)}</strong><small>Referência: ${escape(g.reference)} · ${g.count} medições · menor ${fmt(g.min)} mm · maior ${fmt(g.max)} mm</small></div><div class="${g.withinTolerance?'':'warn'}">Diferença ${fmt(g.difference)} mm · ${g.withinTolerance?'dentro da tolerância':'CONFERIR'}</div></div>`).join('')||'<p class="muted">Sem medições repetidas com referências idênticas para cruzamento.</p>')+
 (check.invalid.length?`<p class="warn">${check.invalid.length} medida(s) sem dados suficientes para comparar. Preencha tipo, identificação e referência.</p>`:'')+
 `<p class="muted">${check.notComparable} medida(s) não comparável(is) a outras. Não significa erro.</p></div>`;
}
function measureView(){const p=project(),r=room();return `<div class="card"><h3>Ambientes</h3><div class="fields">${field('roomname','Novo ambiente (ex.: Cozinha)')}</div>${btn('Adicionar ambiente','addRoom','','primary')}<div class="tabs">${p.rooms.map(x=>`<button class="${x.id===selectedRoom?'selected':''}" data-room="${x.id}">${escape(x.name)}</button>`).join('')}</div></div>${r?`<div class="card"><h3>Trena Bluetooth</h3><div class="measure" id="bleValue">${lastBLE===null?'Aguardando leitura':fmt(lastBLE)+' mm'}</div><div class="actions">${btn('Buscar trena','bleScan','','primary')}${btn('Desconectar','bleDisconnect')}</div><p class="muted" style="font-size:12px">Bluetooth requer o APK Android e uma trena compatível. O protocolo Bosch GLM 50-27 CG ainda precisa de validação física. Escolha o campo antes de medir.</p></div><div class="card"><h3>Adicionar medição — ${escape(r.name)}</h3><div class="fields">${select('mkind','Tipo',['Parede','Altura esquerda','Altura centro','Altura direita','Profundidade','Pedra','Cuba','Tomada','Água','Esgoto','Outro'])}${field('mtarget','Identificação / posição')}${field('mvalue','Medida (mm)','number','','min="0" step="0.01"')}${field('mreference','Referência (ex.: canto esquerdo)')}</div>${btn('Salvar medição','addMeasure','','primary')}<div class="actions">${btn('Usar última leitura','useBLE')}</div></div><div class="card"><h3>Histórico de leituras da trena (sessão)</h3><p class="muted">Toda leitura válida recebida nesta sessão aparece aqui, mesmo antes de ser atribuída a um elemento. Não substitui a medição salva.</p>${C.unusedBleReadings((p.bleReadings||[]).filter(x=>x.roomId===selectedRoom),p.rooms).slice(-30).reverse().map(x=>`<div class="item"><div><strong>${fmt(x.value)} mm</strong><small>${escape(x.date)} · origem Bluetooth · sem atribuição</small></div>${btn('Selecionar leitura','useReading',x.id,'small')}</div>`).join('')||'<div class="empty">Nenhuma leitura pendente neste ambiente.</div>'}</div>${auditRoomView(r)}${editLastMeasureView(p)}<div class="card"><h3>Medições registradas (${r.measurements.length})</h3><p class="muted">Valores originais preservados · medidas manuais e da trena identificadas por origem.</p>${r.measurements.map(m=>`<div class="item"><div><strong>${escape(m.kind)} — ${fmt(m.value)} mm</strong><small>${escape(m.target)} · ${escape(m.reference)} · ${escape(m.source)} · ${escape(m.createdAt||'')} ${m.readingId?'· leitura '+escape(m.readingId):''}</small></div>${btn('Excluir','deleteMeasure',m.id,'small danger')}</div>`).join('')||'<div class="empty">Nenhuma medição neste ambiente.</div>'}</div><div class="card"><h3>Elementos de obra</h3><div class="fields">${select('ekind','Elemento',['Tomada','Interruptor','Água','Esgoto','Registro','Gás','Pilar','Viga','Janela','Porta','Outro'])}${field('elabel','Descrição')}${field('ex','Posição X (mm)','number',0)}${field('ez','Altura Z (mm)','number',0)}${field('ew','Largura (mm)','number',0)}</div>${btn('Marcar elemento','addElement','','primary')}${r.elements.map(e=>`<div class="item"><div><strong>${escape(e.kind)} · ${escape(e.label)}</strong><small>X ${fmt(e.x)} mm · Z ${fmt(e.z)} mm · largura ${fmt(e.width)} mm</small></div>${btn('Excluir','deleteElement',e.id,'small danger')}</div>`).join('')}</div>`:'<div class="empty">Adicione um ambiente para começar as medições.</div>'}`;}

let photoMeasurePhoto=null,photoMeasureSelected=null,photoMeasureMode='horizontal',photoDrag=null,photoMoveAnchor=null,photoInk=true,photoStrokeActive=null,photoInkColor='#197da5',photoInkWidth=3,photoInkPointer=null,photoPaletteOpen=false,photoDockExpanded=false;
function overlayFor(photo){if(!Array.isArray(photo.dimensions))photo.dimensions=[];return photo.dimensions;}
function photoMeasureView(){
 const p=project(),photo=p.photos.find(f=>f.id===photoMeasurePhoto)||p.photos[0];
 if(!photo)return '<div class="card"><h3>Medidas na foto</h3><p>Adicione uma foto ao projeto para começar.</p>'+btn('Abrir fotos','photoGoto')+'</div>';
 photoMeasurePhoto=photo.id;const dims=overlayFor(photo);
 const strokes=(photo.inkStrokes||[]).map(stroke=>{const points=Array.isArray(stroke)?stroke:stroke.points||[],color=Array.isArray(stroke)?'#197da5':stroke.color||'#197da5',width=Array.isArray(stroke)?5:stroke.width||3;return '<polyline points="'+points.map(point=>point.x+','+point.y).join(' ')+'" fill="none" stroke="'+escape(color)+'" stroke-width="'+width+'" stroke-linecap="round" stroke-linejoin="round"/>';}).join('');
 const shapes=dims.map(d=>{
  const selected=d.id===photoMeasureSelected,shape=d.shape||'arrow',value=d.value?fmt(d.value)+' mm':'';
  const mx=(d.x1+d.x2)/2,my=(d.y1+d.y2)/2,angle=Math.atan2(d.y2-d.y1,d.x2-d.x1)*180/Math.PI;
  const rotation=angle>90?angle-180:angle< -90?angle+180:angle;
  const color=escape(d.color||'#ffe000');
  const length=Math.hypot(d.x2-d.x1,d.y2-d.y1);
  // Arrowhead, line and center label follow the drawn distance, not screen pixels.
  const ratio=Math.max(.38,Math.min(1.3,length/240));
  const thick=Number(d.thickness)||Math.max(1.3,Math.min(4,3*ratio));
  const head=Math.min(length*.23,Math.max(5,14*ratio));
  const wing=Math.max(2.5,head*.45);
  const ux=length?(d.x2-d.x1)/length:1,uy=length?(d.y2-d.y1)/length:0;
  const tip=(x,y,dx,dy)=>[x+dx*head-dy*wing,y+dy*head+dx*wing,x,y,x+dx*head+dy*wing,y+dy*head-dx*wing].join(',');
  const heads=shape==='rect'?'':'<polygon points="'+tip(d.x1,d.y1,ux,uy)+'" fill="'+color+'"/><polygon points="'+tip(d.x2,d.y2,-ux,-uy)+'" fill="'+color+'"/>';
  const labelScale=Math.max(.45,Math.min(1,length/155));
  const labelWidth=Math.min(150,Math.max(44,18+value.length*9));
  const label='<g class="measure-label" data-measure-label="'+escape(d.id)+'" role="button" aria-label="Ver detalhes da medida" transform="translate('+mx+' '+my+') rotate('+rotation+') scale('+labelScale+')"><rect x="'+(-labelWidth/2)+'" y="-13" width="'+labelWidth+'" height="26" rx="2" fill="'+color+'"/><text x="0" y="5" text-anchor="middle" fill="#1c1c1c" font-size="15" font-weight="700">'+escape(value||'…')+'</text></g>';
  const mark=shape==='rect'?'<rect x="'+Math.min(d.x1,d.x2)+'" y="'+Math.min(d.y1,d.y2)+'" width="'+Math.abs(d.x2-d.x1)+'" height="'+Math.abs(d.y2-d.y1)+'" fill="none" stroke="'+color+'" stroke-width="'+thick+'"/>':'<line x1="'+d.x1+'" y1="'+d.y1+'" x2="'+d.x2+'" y2="'+d.y2+'" stroke="'+color+'" stroke-width="'+thick+'"/>'+heads;
  return '<g data-dimension="'+escape(d.id)+'" class="dim-group'+(selected?' dim-selected':'')+'">'+mark+
  '<line class="measure-hit" x1="'+d.x1+'" y1="'+d.y1+'" x2="'+d.x2+'" y2="'+d.y2+'" stroke="transparent" stroke-width="30"/>'+
  '<circle data-handle="a" cx="'+d.x1+'" cy="'+d.y1+'" r="'+(selected?7:5)+'" fill="'+color+'" opacity="'+(selected?1:0)+'"/>'+
  '<circle data-handle="b" cx="'+d.x2+'" cy="'+d.y2+'" r="'+(selected?12:7)+'" fill="'+color+'" opacity="'+(selected?1:0)+'"/>'+
  (shape==='rect'?'':label)+'</g>';
 }).join('');
 const notes=(photo.notes||[]).map(n=>'<g data-photo-note="'+escape(n.id)+'"><rect x="'+n.x+'" y="'+n.y+'" rx="9" width="240" height="72" fill="#fff6b5" stroke="#b38b16" stroke-width="3"/><text x="'+(n.x+12)+'" y="'+(n.y+28)+'" font-size="22" fill="#232323">'+escape(n.text.slice(0,16))+'</text><text x="'+(n.x+12)+'" y="'+(n.y+53)+'" font-size="17" fill="#4f4115">Nota</text></g>').join('');
 const svg='<svg id="photoOverlay" viewBox="0 0 1000 650" preserveAspectRatio="none" aria-label="Medidas sobre a fotografia"><defs><marker id="arqueArrowStart" markerUnits="userSpaceOnUse" markerWidth="19" markerHeight="17" refX="1" refY="8.5" orient="auto"><path d="M0 8.5 L18 0 L18 17 Z" fill="#ffe000"/></marker><marker id="arqueArrowEnd" markerUnits="userSpaceOnUse" markerWidth="19" markerHeight="17" refX="18" refY="8.5" orient="auto"><path d="M0 0 L18 8.5 L0 17 Z" fill="#ffe000"/></marker></defs>'+strokes+shapes+notes+'<line id="photoPlacementPreview" x1="0" y1="0" x2="0" y2="0" stroke="#ffe000" stroke-width="3" vector-effect="non-scaling-stroke" stroke-dasharray="12 8" visibility="hidden" pointer-events="none"/></svg>';
 const choices=p.rooms.map(r=>({id:r.id,name:r.name}));
 return '<div class="card photo-workspace"><div class="photo-workspace-head"><strong>Medidas na foto</strong><span class="muted">Desenhe ou meça direto na imagem</span></div><div class="photo-context">'+select('measurePhoto','Fotografia',p.photos.map(x=>({id:x.id,name:x.name})),photo.id)+(choices.length?select('photoRoom','Ambiente',[{id:'',name:'Sem ambiente'},...choices],photo.roomId||''):'')+'</div>'+
 '<div class="photo-workbar photo-workbar-compact">'+
 '<div class="photo-ink-tools"><button type="button" class="photo-icon-button" data-action="photoPaletteToggle" title="Cores da caneta">🎨</button>'+
 (photoPaletteOpen?'<div class="photo-palette-popover">'+['#197da5','#171717','#ffe000','#e23d3d','#288047','#ffffff'].map(c=>'<button type="button" class="photo-ink-swatch '+(photoInkColor===c?'selected':'')+'" data-action="photoInkColor" data-arg="'+c+'" style="background:'+c+'" aria-label="Cor '+c+'"></button>').join('')+'</div>':'')+
 '<button type="button" class="photo-apply-reading" data-action="photoDimensionApply" title="Aplicar leitura Bosch à medida selecionada">⌁ Aplicar leitura</button></div>'+
 '<div class="photo-secondary-tools"><button type="button" class="photo-icon-button" data-action="photoAddRect" title="Criar área" aria-label="Criar área">▣</button><button type="button" class="photo-icon-button" data-action="photoNoteAdd" title="Adicionar texto" aria-label="Adicionar texto">T⁺</button><button type="button" class="photo-icon-button" data-action="bleScan" title="Conectar Bosch" aria-label="Conectar Bosch">ᛒ</button><div class="photo-zoom-tools">'+btn('−','photoZoomOut')+'<span id="photoZoomReadout">'+Math.round(photoZoom*100)+'%</span>'+btn('+','photoZoomIn')+btn('100%','photoZoomReset')+'<button type="button" class="photo-icon-button '+(photoZoomMode?'active':'')+'" data-action="photoZoomMode" title="'+(photoZoomMode?'Travar zoom':'Mover e ampliar')+'" aria-label="'+(photoZoomMode?'Travar zoom':'Mover e ampliar')+'">✥</button></div></div></div>'+
  '<div class="photo-measure-stage" id="photoMeasureStage"><div class="photo-zoom-surface" id="photoZoomSurface" style="transform:translate('+photoPanX+'px,'+photoPanY+'px) scale('+photoZoom+')"><img src="'+photo.data+'" alt="Foto do ambiente">'+svg+'</div><div class="photo-floating-dock '+(photoDockExpanded?'expanded':'')+'" role="toolbar" aria-label="Ferramentas da foto"><button type="button" data-action="photoDockToggle" class="photo-dock-tool photo-dock-menu" title="Abrir ou fechar ferramentas" aria-label="Abrir ou fechar ferramentas">☷</button><button type="button" data-action="photoInkToggle" class="photo-dock-tool '+(photoInk?'active':'')+'" title="Caneta" aria-label="Caneta">✎</button><button type="button" data-action="photoAddDistance" class="photo-dock-tool '+(photoPlacement?'active':'')+'" title="Seta" aria-label="Seta">↗</button><button type="button" data-action="photoInkSelect" class="photo-dock-tool" title="Editar setas" aria-label="Editar setas">⌖</button><button type="button" data-action="photoInkUndo" class="photo-dock-tool" title="Desfazer risco" aria-label="Desfazer risco">↶</button></div></div><p class="muted">Leitura atual: <b id="photoBleLive">'+(lastBLE===null?'Aguardando trena':fmt(lastBLE)+' mm')+'</b>. Selecione a seta ou o quadrado e associe a leitura.</p>'+
 dims.map(d=>'<div class="item"><div><strong>'+escape(d.label||'Medida')+' — '+(d.value?fmt(d.value)+' mm':'Aguardando medida')+'</strong><small>'+escape(d.note||'')+' '+escape(d.source||'manual')+'</small></div><div class="actions">'+btn('Selecionar','photoDimensionSelect',d.id,'small')+btn('Excluir','photoDimensionDelete',d.id,'small danger')+'</div></div>').join('')+
 (photoMeasureSelected?'<div id="photoMeasureDetails" class="photo-measure-details"><h4>Editar seta selecionada</h4><div class="photo-resize-actions">'+btn('− Diminuir','photoDimensionResize','shrink')+btn('＋ Aumentar','photoDimensionResize','grow')+'</div><p class="muted">Toque no quadrado amarelo de outra seta para consultar ou editar.</p><div class="fields">'+field('photoMeasureValue','Distância (mm)','number',dims.find(x=>x.id===photoMeasureSelected)?.value||'','min="0" step="0.01"')+field('photoMeasureLabel','Identificação',dims.find(x=>x.id===photoMeasureSelected)?.label||'')+field('photoMeasureNote','Observação','text',dims.find(x=>x.id===photoMeasureSelected)?.note||'')+field('photoMeasureThickness','Espessura da linha','number',dims.find(x=>x.id===photoMeasureSelected)?.thickness||5,'min="2" max="14" step="1"')+'</div>'+btn('Salvar medida e observações','photoDimensionManual','','primary')+'</div>':'<p class="muted" id="photoMeasureHint">Toque no quadrado amarelo de uma seta para ver suas especificações.</p>')+
 '<h4>Leituras disponíveis da Bosch</h4><p class="muted">Selecione a seta ou quadrado antes de vincular uma leitura. Os valores são exibidos em mm.</p>'+bleReadings.slice(-15).reverse().map(reading=>'<div class="item"><strong>'+fmt(reading.value)+' mm</strong>'+btn('Aplicar à seleção','photoReadingApply',reading.id,'small')+'</div>').join('')+'<h4>Anotações da foto</h4>'+(photo.notes||[]).map(n=>'<div class="item"><span>'+escape(n.text)+'</span>'+btn('Excluir','photoNoteDelete',n.id,'small danger')+'</div>').join('')+'</div>';
}
function photoOverlayCoords(ev,svg){const r=svg.getBoundingClientRect();return {x:Math.round(Math.max(0,Math.min(1000,(ev.clientX-r.left)/Math.max(1,r.width)*1000))),y:Math.round(Math.max(0,Math.min(650,(ev.clientY-r.top)/Math.max(1,r.height)*650)))};}
function applyPhotoValue(value,source,readingId){const p=project(),photo=p?.photos.find(x=>x.id===photoMeasurePhoto),d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!d)throw Error('Selecione uma seta amarela primeiro.');if(!Number.isFinite(Number(value))||Number(value)<=0)throw Error('Leitura inválida.');d.value=Number(value);d.source=source;d.readingId=readingId||null;d.date=new Date().toISOString();update();toast('Medida vinculada à seta selecionada.');}

function photoView(){const p=project();return `<div class="card"><h3>Fotos e referências da obra</h3><p class="muted">As fotos ficam salvas no armazenamento local do aplicativo, associadas ao projeto.</p>${btn('Abrir câmera','takePhoto','','primary')}${btn('Escolher da galeria','addPhoto')}<div class="field"><label for="photoCategory">Tipo da próxima foto</label><select id="photoCategory"><option>Levantamento</option><option>Rascunho</option><option>Referência</option><option>Produção</option><option>Projeto finalizado</option></select></div>${p.rooms.length?select('photoRoomNext','Ambiente da próxima foto',[{id:'',name:'Sem ambiente'},...p.rooms.map(r=>({id:r.id,name:r.name}))]):''}</div><div class="photo-grid">${p.photos.map(f=>`<div class="card"><img class="photo" src="${f.data}" alt="Foto da obra"><p><b>${escape(f.name)}</b></p><small>${escape(f.category||'Levantamento')} · ${escape(f.createdAt||'')}</small>${btn('Medir e anotar','photoAnnotate',f.id,'small primary')}${btn('Excluir','deletePhoto',f.id,'small danger')}</div>`).join('')}</div>${p.photos.length?'':'<div class="empty">Nenhuma foto anexada.</div>'}`;}
function drawView(){const r=room();return `<div class="card"><h3>Caderno técnico</h3><p class="muted">Desenhe com o dedo ou caneta do tablet. Os traços ficam associados ao ambiente.</p><div class="field"><label>Ambiente</label><select id="drawRoom">${project().rooms.map(x=>`<option value="${x.id}" ${x.id===selectedRoom?'selected':''}>${escape(x.name)}</option>`).join('')}</select></div>${r?`<div class="field"><label for="drawColor">Cor da caneta</label><select id="drawColor"><option value="#ffd329">Amarelo</option><option value="#171717">Preto</option><option value="#e23d3d">Vermelho</option><option value="#235ed7">Azul</option><option value="#288047">Verde</option></select></div><div class="canvas-wrap"><canvas class="draw" id="drawing" width="900" height="500"></canvas></div><div class="actions">${btn('Desfazer traço','undoStroke')}${btn('Limpar desenho','clearDrawing','','danger')}</div><div class="field"><label>Observação / referência</label><textarea id="noteText" placeholder="Ex.: tomada atrás da torre quente; conferir altura do sifão"></textarea></div>${btn('Salvar anotação','addNote','','primary')}${r.annotations.map(n=>`<div class="item"><div>${escape(n.text)}<small>${escape(n.date)}</small></div>${btn('Excluir','deleteNote',n.id,'small danger')}</div>`).join('')}`:'<div class="empty">Crie um ambiente na aba Medições antes de desenhar.</div>'}</div>`;}
function studioPages(p){ if(!Array.isArray(p.studioPages))p.studioPages=[];return p.studioPages; }
function studioCurrent(p){const pages=studioPages(p);if(!pages.length)return null;return pages.find(x=>x.id===studioPageId)||pages[0];}
function studioModeTitle(mode){return mode==='planta'?'Planta':mode==='laboratorio'?'Laboratório':'Esboço';}
function studioObjectPaths(kind,x1,y1,x2,y2){
 const x=Math.min(x1,x2),y=Math.min(y1,y2),w=Math.abs(x2-x1),h=Math.abs(y2-y1);
 if(kind==='wall')return [[[x1,y1],[x2,y2]]];
 const rect=[[x,y],[x+w,y],[x+w,y+h],[x,y+h],[x,y]];
 const paths=[rect];
 if(kind==='cabinet'){paths.push([[x+w/2,y],[x+w/2,y+h]]);paths.push([[x+w*.44,y+h*.5],[x+w*.44,y+h*.65]]);paths.push([[x+w*.56,y+h*.5],[x+w*.56,y+h*.65]]);}
 if(kind==='drawers'){for(let i=1;i<4;i++)paths.push([[x,y+h*i/4],[x+w,y+h*i/4]]);}
 if(kind==='door'){paths.push([[x,y+h],[x+w,y]]);}
 return paths;
}

function studioView(){
 const p=project(),pages=studioPages(p),page=studioCurrent(p);if(page)studioPageId=page.id;
 return `<div class="studio-hero studio-hero-compact"><div class="studio-hero-actions"><label for="studioNewName" class="studio-compact-title">Esboço + Laboratório <small>· ${pages.length} folhas</small></label><input id="studioNewName" aria-label="Nome da nova folha" placeholder="Nome da folha" maxlength="100">${btn('+ Nova folha','studioNew','','primary')}</div><div class="studio-mode-tabs">${['esboco','planta','laboratorio'].map(mode=>btn(studioModeTitle(mode),'studioMode',mode,studioMode===mode?'primary':'')).join('')}</div></div>
 <div class="studio-layout"><aside class="studio-sidebar"><div class="eyebrow">FOLHAS · ${pages.length}</div>${pages.map((x,i)=>`<button class="studio-page ${page&&page.id===x.id?'on':''}" data-action="studioSelect" data-arg="${escape(x.id)}"><span class="studio-page-num">${String(i+1).padStart(2,'0')}</span><span>${escape(x.name)}</span><span>↗</span></button>`).join('')||'<div class="empty">Adicione sua primeira folha A4.</div>'}</aside>
 <div class="studio-work ${studioFullscreen?'studio-fullscreen':''}" id="studioWork">${page?`
 <div class="studio-paper-head"><div><div class="eyebrow">FOLHA ${page.width===1000?'ANTIGA':'A4'} · ${pages.findIndex(x=>x.id===page.id)+1}/${pages.length}</div><strong>${escape(page.name)}</strong></div><div class="studio-head-actions">${studioFullscreen?btn('✕ Fechar tela cheia','studioCloseFull','','primary'):btn('⛶ Abrir em tela cheia','studioOpenFull','','primary')}</div></div>
 <div class="studio-tools"><label>Ambiente <select id="studioRoom"><option value="">Sem ambiente</option>${p.rooms.map(r=>`<option value="${escape(r.id)}" ${r.id===page.roomId?'selected':''}>${escape(r.name)}</option>`).join('')}</select></label><label>Ferramenta <select id="studioTool"><option value="pen" ${studioTool==='pen'?'selected':''}>Caneta</option><option value="eraser" ${studioTool==='eraser'?'selected':''}>Borracha</option><option value="cabinet" ${studioTool==='cabinet'?'selected':''}>Armário 2 portas</option><option value="drawers" ${studioTool==='drawers'?'selected':''}>Gaveteiro</option><option value="room" ${studioTool==='room'?'selected':''}>Retângulo / ambiente</option><option value="wall" ${studioTool==='wall'?'selected':''}>Parede / linha reta</option><option value="door" ${studioTool==='door'?'selected':''}>Porta</option></select></label><label>Cor <input type="color" id="studioColor" value="${studioInk}" aria-label="Cor da caneta"></label><label>Espessura <input type="range" min="1" max="16" id="studioWidth" value="${studioWidth}"></label><label>Fundo <select id="studioGrid"><option value="dots" ${studioGrid==='dots'?'selected':''}>Pontilhado</option><option value="lines" ${studioGrid==='lines'?'selected':''}>Linhas</option><option value="blank" ${studioGrid==='blank'?'selected':''}>Liso</option></select></label></div>

 <div class="studio-lab-panel"><label>Foto de referência <select id="studioReferencePhoto"><option value="">Sem foto</option>${(p.photos||[]).map(photo=>'<option value="'+escape(photo.id)+'" '+(photo.id===page.referencePhotoId?'selected':'')+'>'+escape(photo.name)+'</option>').join('')}</select></label>${btn('📷 Fotos do ambiente','studioGotoPhotos')}<label>Medida real do último elemento (mm) <input type="number" id="studioElementMm" min="1" max="50000" placeholder="Ex.: 2400" value="${escape(page.lastMeasureMm||'')}"></label>${btn('Vincular medida','studioSetMeasure')}<small class="muted">Desenhe um móvel com a S Pen e informe sua medida real. Planta e Laboratório são estudos 2D; não são escaneamento 3D.</small></div>
 ${page.referencePhotoId&&p.photos.some(x=>x.id===page.referencePhotoId)?'<div class="studio-photo-reference"><img alt="Foto de referência da obra" src="'+p.photos.find(x=>x.id===page.referencePhotoId).data+'"></div>':''}
 <div class="studio-canvas-shell"><canvas id="studioCanvas" width="${page.width||1000}" height="${page.height||690}" aria-label="Folha de esboço ${escape(page.name)}"></canvas></div>
 <div class="studio-actions">${btn('↶ Desfazer','studioUndo')}${btn('↷ Refazer','studioRedo')}${btn('Renomear folha','studioRename')}${btn('Exportar PNG','studioExport')}${btn('Excluir folha','studioDelete','','danger')}</div>
 <div class="field"><label for="studioText">Anotações desta folha</label><textarea id="studioText" placeholder="Medidas, cortes, ferragens e referências...">${escape(page.text||'')}</textarea></div>${btn('Salvar anotação','studioSaveText','','primary')}
 `:'<div class="empty">Escolha um nome e adicione uma folha A4 para começar.</div>'}</div></div>`;
}
function setupStudio(){
 const canvas=$('#studioCanvas'),p=project();if(!canvas||!p)return;
 const page=studioCurrent(p);if(!page)return;
 const ctx=canvas.getContext('2d');if(!ctx)return;
 const drawStroke=(stroke)=>{
  if(!stroke?.points?.length)return;
  ctx.beginPath();ctx.strokeStyle=stroke.color||'#151515';ctx.lineWidth=stroke.width||3;ctx.lineCap='round';ctx.lineJoin='round';
  const paths=stroke.kind?studioObjectPaths(stroke.kind,...stroke.points[0],...stroke.points[stroke.points.length-1]):[stroke.points];
  for(const points of paths){ctx.beginPath();points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));if(points.length===1)ctx.lineTo(points[0][0]+.1,points[0][1]);ctx.stroke();}
  if(stroke.mm){const p1=stroke.points[0],p2=stroke.points[stroke.points.length-1];ctx.fillStyle='#066a9b';ctx.font='bold 16px Arial';ctx.fillText(String(stroke.mm)+' mm',(p1[0]+p2[0])/2,(p1[1]+p2[1])/2-9);}
 };
 function paint(){
  canvas.dataset.strokeCount=String((page.strokes||[]).length);
  ctx.fillStyle='#ffffff';ctx.fillRect(0,0,canvas.width,canvas.height);
  ctx.fillStyle='rgba(14,106,154,0.12)';ctx.font='600 18px Arial';ctx.fillText('ARQUE MEASURE · '+studioModeTitle(studioMode).toUpperCase(),22,27);
  ctx.strokeStyle='#dfdcd3';ctx.fillStyle='#d5cfc3';ctx.lineWidth=1;
  if(studioGrid==='dots'){for(let y=22;y<canvas.height;y+=25)for(let x=22;x<canvas.width;x+=25){ctx.beginPath();ctx.arc(x,y,.8,0,7);ctx.fill();}}
  else if(studioGrid==='lines'){for(let y=25;y<canvas.height;y+=25){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(canvas.width,y);ctx.stroke();}}
  for(const stroke of page.strokes||[])drawStroke(stroke);
 }
 const coords=e=>{const b=canvas.getBoundingClientRect();return [Math.max(0,Math.min(canvas.width,(e.clientX-b.left)*canvas.width/(b.width||1))),Math.max(0,Math.min(canvas.height,(e.clientY-b.top)*canvas.height/(b.height||1)))]};
 let active=null,activePointer=null,saveQueue=Promise.resolve();
 const save=()=>{saveQueue=saveQueue.catch(()=>{}).then(()=>persist()).catch(x=>toast('Erro ao salvar esboço: '+x.message));};
 const finish=e=>{
  if(!active||e.pointerId!==activePointer)return;
  active=null;activePointer=null;studioActive=false;studioPoints=[];save();
 };
 canvas.style.touchAction='none';
 canvas.onpointerdown=e=>{
  if(active)return;
  e.preventDefault();
  const stroke={points:[coords(e)],color:studioTool==='eraser'?'#ffffff':studioInk,width:studioTool==='eraser'?28:studioWidth};if(!['pen','eraser'].includes(studioTool))stroke.kind=studioTool;
  (page.strokes||(page.strokes=[])).push(stroke);page.undone=[];
  active=stroke;activePointer=e.pointerId;studioActive=true;
  try{canvas.setPointerCapture(e.pointerId)}catch(_){}
  paint();
 };
 canvas.onpointermove=e=>{
  if(!active||e.pointerId!==activePointer)return;
  e.preventDefault();
  const events=typeof e.getCoalescedEvents==='function'?e.getCoalescedEvents():[];
  for(const sample of events.length?events:[e]){if(active.kind)active.points=[active.points[0],coords(sample)];else active.points.push(coords(sample));}
  paint();
 };
 canvas.onpointerup=e=>{if(active&&e.pointerId===activePointer){active.points.push(coords(e));finish(e);paint();}};
 canvas.onpointercancel=e=>{finish(e);paint();};
 canvas.onlostpointercapture=e=>{if(active&&e.pointerId===activePointer){finish(e);paint();}};
 $('#studioTool').onchange=e=>studioTool=e.target.value;
 $('#studioColor').onchange=e=>studioInk=e.target.value;
 $('#studioWidth').oninput=e=>studioWidth=+e.target.value;
 $('#studioGrid').onchange=e=>{studioGrid=e.target.value;paint()};
 $('#studioReferencePhoto').onchange=e=>{page.referencePhotoId=e.target.value;save();render();};
 paint();
}

function financeView(){const p=project(),f=C.finance(p);return `<div class="grid"><div class="card"><small class="muted">Contrato líquido</small><div class="stat">${money(f.net)}</div></div><div class="card"><small class="muted">Recebido</small><div class="stat">${money(f.paid)}</div></div><div class="card"><small class="muted">Saldo a receber</small><div class="stat">${money(f.balance)}</div></div></div><div class="card"><h3>Registrar pagamento</h3><div class="fields">${field('payamount','Valor (R$)','number','','min="0.01" step="0.01"')}${select('paymethod','Forma',['Pix','Dinheiro','Cartão','Transferência','Cheque','Boleto','Outro'])}${field('paydate','Data','date',new Date().toISOString().slice(0,10))}</div>${btn('Registrar recebimento','addPayment','','primary')}${p.payments.map(x=>`<div class="item"><div><strong>${money(x.amount)}</strong><small>${escape(x.method)} · ${escape(x.date)}</small></div>${btn('Excluir','deletePayment',x.id,'small danger')}</div>`).join('')}</div>`;}
function toolsView(){const p=project();if(!p)return header('Cálculos por obra','Escolha primeiro o cliente e a obra para que os cálculos sejam associados ao projeto.')+btn('Abrir clientes','go','clients','primary');return header('Cálculos da obra · '+escape(p.name),'Confira as medições do ambiente antes de usar os resultados na produção.')+`<div class="grid"><div class="card"><h3>Tomada por referências</h3><div class="fields">${field('tw','Largura parede (mm)','number',3500)}${field('tl','Esquerda → caixa (mm)','number',1210)}${field('tc','Largura caixa (mm)','number',80)}${field('tr','Caixa → direita (mm)','number',2210)}${field('tt','Tolerância fechamento (mm)','number',state.settings.tolerance)}</div>${btn('Calcular tomada','calcSocket','','primary')}<div id="socketResult"></div></div><div class="card"><h3>Alturas e desníveis</h3><div class="fields">${field('h1','Altura esquerda (mm)','number',2710)}${field('h2','Altura central (mm)','number',2706)}${field('h3','Altura direita (mm)','number',2702)}</div>${btn('Comparar alturas','calcHeights','','primary')}<div id="heightsResult"></div></div><div class="card"><h3>Carcaça abaixo da pedra</h3><div class="fields">${field('ct','Topo pedra (mm)','number',900)}${field('cs','Espessura pedra (mm)','number',30)}${field('cb','Rodapé/base (mm)','number',100)}${field('cc','Folga instalação (mm)','number',5)}</div>${btn('Calcular carcaça','calcCarcass','','primary')}<div id="carcassResult"></div></div><div class="card"><h3>Vão com paredes irregulares</h3><div class="fields">${field('v1','Largura baixa (mm)','number',2735)}${field('v2','Largura média (mm)','number',2728)}${field('v3','Largura alta (mm)','number',2731)}${field('vl','Folga esquerda (mm)','number',5)}${field('vr','Folga direita (mm)','number',5)}</div>${btn('Calcular vão','calcOpening','','primary')}<div id="openingResult"></div></div></div><div class="notice">A variação entre alturas piso-teto não identifica isoladamente se o desnível está no piso ou no teto. É preciso medir com uma referência de nível.</div>`;}
function transferView(){return header('Arque Link','Encontre um Arque Measure por Bluetooth e transfira uma obra ou cópia completa pela mesma rede Wi-Fi/hotspot, com código de autorização.')+
 `<div class="card"><h3>Enviar projeto</h3><p>Abra o Arque Measure nos dois aparelhos. Ative um ponto de acesso ou conecte ambos ao mesmo Wi-Fi.</p>${select('linkMode','O que compartilhar',['Uma obra','Backup completo'],'Uma obra')}${state.projects.length?select('linkProject','Projeto para enviar',state.projects):'<p>Cadastre um projeto primeiro.</p>'}
 ${btn('Compartilhar projeto','linkShare','','primary')}${btn('Ativar anúncio Bluetooth','linkAdvertise')}${btn('Parar compartilhamento','linkStop')}
 <div class="notice">${linkInfo?`Endereço: <b>${escape(linkInfo.ip)}</b><br>Código de autorização (não compartilhe com estranhos):<br><b style="overflow-wrap:anywhere">${escape(linkInfo.code)}</b>`:'O endereço e o código aparecerão aqui após iniciar o envio.'}</div></div>
 <div class="card"><h3>Receber projeto</h3><p>Toque em procurar para encontrar outro Arque Measure próximo por Bluetooth. Ambos precisam estar na mesma rede local ou hotspot para transmitir o projeto.</p>${btn('Procurar aparelhos por Bluetooth','linkDiscover','','primary')}<div id="linkPeers">${linkPeers.map((x,i)=>`<div class="item"><div><strong>Aparelho encontrado ${i+1}</strong><small>Endereço local: ${escape(x.ip)}</small></div>${btn('Usar este aparelho','linkUsePeer',x.ip,'small')}</div>`).join('')||'<p class="muted">Nenhum aparelho localizado nesta busca.</p>'}</div>${field('linkIP','IP do telefone que está enviando','text','','placeholder="192.168.1.10"')}${field('linkCode','Código exibido no telefone de origem','text','','placeholder="32 caracteres"')}${btn('Buscar projeto e importar cópia','linkFetch','','primary')}<p class="muted">Receber uma obra adiciona cópia; receber backup completo substitui dados após confirmação explícita.</p></div>
 <div class="notice" id="linkNotice">${escape(linkNotice||'Somente rede local. A descoberta BLE está disponível no APK Android; a transferência com iPhone ainda não está implementada.')}</div>
 <div class="card"><h3>Backup completo do aparelho</h3>${btn('Exportar arquivo .arque','export')}${btn('Importar backup','import')}<p>Importar o backup substitui todos os dados. Diferente do Arque Link, que adiciona uma cópia.</p></div>`;}

function diagnosticsView(){const d=diagnostics;const row=(name,value)=>`<div class="diag-row"><span>${escape(name)}</span><strong>${escape(String(value))}</strong></div>`;
return header('Diagnóstico do aparelho','Verificação local de recursos. A confirmação de funcionamento exige testes com hardware real.')+
`<div class="card"><h3>Permissões e hardware</h3>${d?[
row('Sistema',d.platform||'Android'),row('Android API',d.sdk),row('Câmera disponível',d.cameraHardware?'Detectada':'Não detectada'),
row('Bluetooth LE',d.bleHardware?'Disponível':'Indisponível'),row('Bluetooth ligado',d.bluetoothEnabled?'Sim':'Não'),
row('Permissão Bluetooth',d.bluetoothPermission?'Concedida':'Não concedida'),row('Espaço local livre',d.freeMegabytes+' MB'),
row('Captura de câmera',cameraCheck)].join(''):'<p class="muted">Toque em verificar para consultar as capacidades deste aparelho.</p>'}
<div class="actions">${btn('Verificar aparelho','checkDevice','','primary')}${btn('Testar câmera','testCamera')}${btn('Buscar Bluetooth','bleScan')}</div>
<p class="diag-note">A câmera usa o aplicativo de câmera do Android; não exige permissão CAMERA própria. O seletor de arquivos usa o acesso autorizado pelo sistema. A busca Bluetooth poderá solicitar permissão de dispositivos próximos.</p></div>
<div class="card"><h3>Verificações pendentes de equipamento</h3><p>Após instalar o APK: tire uma foto real, confirme a imagem, conecte a trena, receba 10 medições, desligue a internet, feche/reabra o aplicativo e exporte/restaure um backup.</p><p class="notice">O teste automático em navegador não substitui câmera, Bluetooth e armazenamento físico do Android.</p></div>`;}

async function update(){await persist();render()}
function val(id){return document.getElementById(id)?.value??''}
function num(id){return C.mm(val(id))}
function action(a,arg){let p=project(),r=room();switch(a){
case'go':tab=arg;selectedProject=null;selectedClient=null;selectedRoom=null;subtab='resumo';render();break;
case'contractAttach':{if(!selectedClient)throw Error('Abra um cliente.');const inp=$('#contractFile');inp.dataset.clientId=selectedClient;inp.dataset.projectId=val('contractProject');inp.click();break;}
case'contractOpen':{const c=state.clients.find(x=>x.id===selectedClient);const doc=c?.contracts?.find(x=>x.id===arg);if(!doc)throw Error('Documento não encontrado.');const link=document.createElement('a');link.href=doc.data;link.download=doc.name;document.body.append(link);link.click();link.remove();break;}
case'contractRemove':{const c=state.clients.find(x=>x.id===selectedClient);if(c?.contracts&&confirm('Excluir este contrato do cadastro?')){c.contracts=c.contracts.filter(x=>x.id!==arg);update();}break;}
case'openClient':selectedClient=arg;selectedProject=null;tab='clients';render();break;
case'closeClient':selectedClient=null;selectedProject=null;tab='clients';render();break;
case'projectCalc':tab='tools';render();break;
case'openWorkspace':subtab=arg;tab='projects';render();break;
case'addClient':{let c=C.client(val('cname'),val('cphone'),val('caddr'));state.clients.push(c);update();toast('Cliente salvo no aparelho.');break;}
case'clientProject':selectedClient=arg;tab='projects';selectedProject=null;render();break;
case'chooseProjectClient':{const id=val('projectClientPick');if(!state.clients.some(c=>c.id===id))throw Error('Escolha um cliente válido.');selectedClient=id;selectedProject=null;tab='projects';render();break;}
case'addProject':{if(!selectedClient||val('pclient')!==selectedClient)throw Error('Selecione primeiro um cliente existente.');const client=state.clients.find(c=>c.id===selectedClient);const environment=val('pname').trim();if(!environment)throw Error('Informe o ambiente.');let x=C.project(selectedClient,environment,client?.address||'');const initialRoom=C.room(environment);x.rooms.push(initialRoom);state.projects.push(x);selectedProject=x.id;selectedClient=x.clientId;selectedRoom=initialRoom.id;subtab='resumo';update();toast('Ambiente criado e vinculado ao cliente.');break;}
case'openProject':selectedProject=arg;selectedClient=project()?.clientId||null;tab='projects';selectedRoom=project()?.rooms[0]?.id||null;subtab='resumo';render();break;
case'closeProject':selectedProject=null;selectedRoom=null;selectedClient=null;tab='projects';render();break;
case'saveProject':{p.status=val('pstatus');p.value=C.money(val('pvalue'));p.discount=C.money(val('pdiscount'));C.finance(p);p.updatedAt=new Date().toISOString();p.revision++;update();toast('Projeto atualizado.');break;}
case'mixedMove':{const plan=cuttingPlan(p),stock=plan.mixedStock;if(!stock)throw Error('Simule a chapa antes.');const [id,ordinal]=arg.split(':');const x=Number(val('mx_'+id+'_'+ordinal)),y=Number(val('my_'+id+'_'+ordinal));const moves={...(stock.moves||{}),[arg]:{x,y}};const layout=window.ArqueCut.mixedStock({...stock,pieces:plan.pieces.filter(q=>stock.ids?.includes(q.id))});window.ArqueCut.positionMixed(layout,moves);stock.moves=moves;update();toast('Posição salva.');break;}
case'mixedReset':{const plan=cuttingPlan(p);if(plan.mixedStock){plan.mixedStock.moves={};update();toast('Arranjo automático restaurado.');}break;}
case'mixedSimulate':{const plan=cuttingPlan(p);const stock={width:Number(val('mixedW')),height:Number(val('mixedH')),kerf:Number(val('mixedKerf')),trim:Number(val('mixedTrim')),ids:[...document.querySelectorAll('[data-mixed-piece]:checked')].map(x=>x.dataset.mixedPiece),moves:{}};if(!stock.ids.length)throw Error('Selecione uma ou mais peças.');window.ArqueCut.mixedStock({...stock,pieces:plan.pieces.filter(x=>stock.ids.includes(x.id))});plan.mixedStock=stock;update();toast('Plano misto salvo.');break;}
case'manualSimulate':{const plan=cuttingPlan(p);const chosen=plan.pieces.find(x=>x.id===val('manualPart'));if(!chosen)throw Error('Selecione uma peça.');const stock={width:Number(val('manualSheetW')),height:Number(val('manualSheetH')),kerf:Number(val('manualKerf')),trim:Number(val('manualTrim')),partId:chosen.id,qty:Number(val('manualQty'))};window.ArqueCut.manualGrid({...stock,partW:chosen.w,partH:chosen.h,grain:chosen.grain,rotate:chosen.rotate});plan.manualStock=stock;update();toast('Simulação manual atualizada.');break;}
case'cutSettings':{const plan=cuttingPlan(p);const updated={...plan,width:Number(val('cutWidth')),height:Number(val('cutHeight')),kerf:Number(val('cutKerf')),trim:Number(val('cutTrim'))};window.ArqueCut.calculate({...updated,pieces:[]});p.cutPlan=updated;update();toast('Chapa e serra configuradas.');break;}
case'cutAdd':{const plan=cuttingPlan(p);const piece={id:C.uid(),name:val('cutName').trim(),w:Number(val('cutW')),h:Number(val('cutH')),qty:Number(val('cutQty')),grain:val('cutGrain')==='Fixo',rotate:val('cutRotate')==='Sim',edge2:Number(val('cutEdge2')),edge04:Number(val('cutEdge04'))};if(!piece.name)throw Error('Informe o nome da peça.');window.ArqueCut.calculate({...plan,pieces:[piece]});plan.pieces.push(piece);plan.draft={name:'',w:'',h:'',qty:1,grain:false,rotate:true,edge2:0,edge04:0};update();toast('Linha adicionada e salva.');break;}
case'cutToggle':{const plan=cuttingPlan(p),parts=arg.split(':'),id=parts[0],index=Number(parts[1]);const piece=plan.pieces.find(x=>x.id===id);if(!piece||!Number.isInteger(index)||index<1||index>piece.qty)throw Error('Esta peça não existe mais.');if(!plan.cutDone)plan.cutDone={};if(plan.cutDone[arg])delete plan.cutDone[arg];else plan.cutDone[arg]=new Date().toISOString();update();toast('Lista de corte atualizada e salva.');break;}
case'cutRemove':{const plan=cuttingPlan(p),piece=plan.pieces.find(x=>x.id===arg);if(!piece)break;if(!confirm('Retirar esta peça do plano atual? A versão e os cortes concluídos ficarão guardados no histórico.'))break;archiveCutRevision(plan,piece,'Retirada do plano atual');plan.pieces=plan.pieces.filter(x=>x.id!==arg);for(const key of Object.keys(plan.cutDone||{}))if(key.startsWith(arg+':'))delete plan.cutDone[key];update();toast('Peça retirada; histórico preservado.');break;}
case'cutPrint':{if(window.ArqueNative?.printCutPlan)window.ArqueNative.printCutPlan();else window.print();break;}
case'addRoom':{let x=C.room(val('roomname'));p.rooms.push(x);selectedRoom=x.id;update();toast('Ambiente criado.');break;}
case'addMeasure':{if(!r)throw Error('Selecione um ambiente.');const input=$('#mvalue');const receiptId=input?.dataset.readingId;const stored=(p.bleReadings||[]).find(x=>x.id===receiptId&&x.roomId===selectedRoom);const alreadyAssigned=p.rooms.some(room=>room.measurements.some(m=>m.readingId===receiptId||m.originalReadingId===receiptId));const receipt=stored&&!alreadyAssigned&&Number(val('mvalue'))===stored.value?stored:null;const item=C.measurement(val('mvalue'),val('mkind'),receipt?'Bluetooth':'manual',val('mtarget'),val('mreference'));if(receipt){if(!String(item.target).trim()||!String(item.reference).trim())throw Error('Identifique posição e referência antes de salvar uma leitura Bluetooth.');item.readingId=receipt.id;item.rawValue=receipt.value;item.deviceProtocol='Bosch BLE (não validado fisicamente)';}r.measurements.push(item);if(input)delete input.dataset.readingId;update();toast('Medida salva com origem identificada.');break;}
case'useReading':{if(!r)throw Error('Selecione um ambiente.');const receipt=(p.bleReadings||[]).find(x=>x.id===arg&&x.roomId===selectedRoom);if(!receipt)throw Error('Leitura não encontrada neste ambiente.');if(p.rooms.some(room=>room.measurements.some(m=>m.readingId===arg||m.originalReadingId===arg)))throw Error('Esta leitura já foi associada a uma medição.');const input=$('#mvalue');if(!input)throw Error('Campo de medição indisponível.');input.value=receipt.value;input.dataset.readingId=receipt.id;toast('Leitura selecionada. Confira tipo, posição e referência antes de salvar.');break;}
case'useBLE':if(!lastBleReceipt)throw Error('Nenhuma medida Bluetooth recebida.');if(!(p.bleReadings||[]).some(x=>x.id===lastBleReceipt.id&&x.roomId===selectedRoom))throw Error('A última leitura não pertence a este ambiente.');if(p.rooms.some(room=>room.measurements.some(m=>m.readingId===lastBleReceipt.id||m.originalReadingId===lastBleReceipt.id)))throw Error('Esta leitura já foi utilizada.');$('#mvalue').value=lastBleReceipt.value;$('#mvalue').dataset.readingId=lastBleReceipt.id;break;
case'editLastMeasure':{
 const latest=latestProjectMeasurement(p);
 if(!latest||latest.measurement.id!==arg)throw Error('A última medição mudou. Abra novamente o projeto.');
 const m=latest.measurement;
 const corrected=C.mm(val('editLastValue'));
 const kind=val('editLastKind').trim(), target=val('editLastTarget').trim(), reference=val('editLastReference').trim();
 if(!kind)throw Error('Informe o tipo da medida.');
 if(corrected===m.value&&kind===m.kind&&target===(m.target||'')&&reference===(m.reference||'')){toast('Nenhuma alteração encontrada.');break;}
 const old={value:m.value,kind:m.kind,target:m.target||'',reference:m.reference||'',source:m.source,readingId:m.readingId||null,editedAt:new Date().toISOString()};
 if(!Array.isArray(m.revisions))m.revisions=[];
 m.revisions.push(old);
 m.value=corrected;m.kind=kind;m.target=target;m.reference=reference;
 m.source='manual (corrigida)';m.lastEditedAt=old.editedAt;
 // The source reading is kept in the history, never used to authenticate the corrected number.
 m.originalReadingId=m.originalReadingId||m.readingId||null;
 delete m.readingId;
 p.updatedAt=old.editedAt;p.revision=(p.revision||0)+1;
 update();toast('Correção salva e valor anterior preservado no histórico.');break;
 }
 case'deleteMeasure':if(confirm('Excluir esta medição?')){r.measurements=r.measurements.filter(x=>x.id!==arg);update();}break;
case'addElement':r.elements.push({id:C.uid(),kind:val('ekind'),label:val('elabel'),x:num('ex'),z:num('ez'),width:num('ew')});update();toast('Elemento marcado.');break;
case'deleteElement':if(confirm('Excluir elemento?')){r.elements=r.elements.filter(x=>x.id!==arg);update();}break;
case'photoAnnotate':photoMeasurePhoto=arg;photoMeasureSelected=null;photoInk=true;subtab='fotomedidas';render();break;
case'photoGoto':subtab='fotos';render();break;
case'photoInkToggle':photoInk=true;photoPlacement=false;photoZoomMode=false;render();break;
case'photoDockToggle':photoDockExpanded=!photoDockExpanded;render();break;
case'photoInkSelect':photoInk=false;photoPlacement=false;photoZoomMode=false;render();break;
case'photoInkThinner':photoInkWidth=Math.max(1,photoInkWidth-1);photoInk=true;render();break;
case'photoInkThicker':photoInkWidth=Math.min(14,photoInkWidth+1);photoInk=true;render();break;
case'photoPaletteToggle':photoPaletteOpen=!photoPaletteOpen;render();break;
case'photoInkColor':if(/^#[0-9a-f]{6}$/i.test(arg)){photoInkColor=arg;photoInk=true;render();}break;
case'photoInkUndo':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(photo&&photo.inkStrokes?.length){photo.inkStrokes.pop();update();}break;}
case'photoZoomIn':photoZoomSet(photoZoom*1.25);break;
case'photoZoomOut':photoZoomSet(photoZoom/1.25);break;
case'photoZoomReset':photoZoomSet(1);break;
case'photoZoomMode':if(!photoZoomMode){photoZoomPreviousInk=photoInk;photoZoomPreviousPlacement=photoPlacement;photoZoomMode=true;photoPlacement=false;photoInk=false;}else{photoZoomMode=false;photoInk=photoZoomPreviousInk;photoPlacement=photoZoomPreviousPlacement;}photoLastTap=null;render();break;
case'photoAddDistance':{photoZoomMode=false;photoInk=false;photoPlacement=!photoPlacement;photoPlacementStart=null;photoPlacementPreview=null;render();if(photoPlacement)toast('Arraste o dedo ou a S Pen sobre a foto para criar a medida.');break;}
case'photoAddHorizontal':case'photoAddVertical':case'photoAddFree':case'photoAddRect':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(!photo)throw Error('Selecione uma foto.');const vert=a==='photoAddVertical',d={id:C.uid(),label:'Medida '+(overlayFor(photo).length+1),shape:a==='photoAddRect'?'rect':'arrow',thickness:5,color:'#ffe000',x1:vert?500:200,y1:vert?140:330,x2:vert?500:800,y2:vert?500:a==='photoAddFree'?470:330,value:null,source:'manual'};photo.dimensions.push(d);photoMeasureSelected=d.id;update();break;}
case'photoNoteAdd':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(!photo)throw Error('Selecione uma foto.');const text=prompt('Anotação importante da foto');if(!text?.trim())break;if(!photo.notes)photo.notes=[];photo.notes.push({id:C.uid(),text:text.trim().slice(0,400),x:30+photo.notes.length%3*260,y:25+photo.notes.length%5*90});update();break;}
case'photoNoteDelete':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(photo){photo.notes=(photo.notes||[]).filter(x=>x.id!==arg);update();}break;}
case'photoDimensionSelect':photoMeasureSelected=arg;photoInk=false;photoPlacement=false;render();break;
case'photoDimensionResize':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto),d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!d)break;const scale=arg==='grow'?1.12:.88;const mx=(d.x1+d.x2)/2,my=(d.y1+d.y2)/2;d.x1=Math.max(0,Math.min(1000,mx+(d.x1-mx)*scale));d.x2=Math.max(0,Math.min(1000,mx+(d.x2-mx)*scale));d.y1=Math.max(0,Math.min(650,my+(d.y1-my)*scale));d.y2=Math.max(0,Math.min(650,my+(d.y2-my)*scale));update();break;}
case'photoDimensionDelete':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(photo){photo.dimensions=overlayFor(photo).filter(x=>x.id!==arg);if(photoMeasureSelected===arg)photoMeasureSelected=null;update();}break;}
case'photoDimensionManual':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto),d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!d)throw Error('Selecione uma seta ou quadrado.');d.label=val('photoMeasureLabel').trim()||d.label;d.note=val('photoMeasureNote').trim();d.thickness=Math.max(2,Math.min(14,Number(val('photoMeasureThickness'))||5));applyPhotoValue(val('photoMeasureValue'),'manual');break;}
case'photoReadingApply':{const reading=bleReadings.find(x=>x.id===arg);if(!reading)throw Error('Leitura não encontrada.');applyPhotoValue(reading.value,'Bluetooth',reading.id);break;}
case'photoDimensionApply':{if(!lastBleReceipt)throw Error('Nenhuma leitura da trena disponível.');applyPhotoValue(lastBleReceipt.value,'Bluetooth',lastBleReceipt.id);break;}
case'addPhoto':pendingPhotoRoom=val('photoRoomNext');pendingPhotoCategory=val('photoCategory')||'Levantamento';$('#photoFile').click();break;
case'takePhoto':pendingPhotoRoom=val('photoRoomNext');pendingPhotoCategory=val('photoCategory')||'Levantamento';$('#cameraFile').click();break;
case'testCamera':$('#diagCameraFile').click();break;
case'checkDevice':if(window.ArqueNative?.checkDevice){window.ArqueNative.checkDevice();}else{diagnostics={platform:'Navegador (simulação)',sdk:'—',cameraHardware:false,bleHardware:false,bluetoothEnabled:false,bluetoothPermission:false,freeMegabytes:'—'};render();toast('Diagnóstico nativo disponível no APK Android.');}break;
case'deletePhoto':if(confirm('Excluir foto?')){p.photos=p.photos.filter(x=>x.id!==arg);update();}break;
case'addNote':{let text=val('noteText').trim();if(!text)throw Error('Escreva a anotação.');r.annotations.push({id:C.uid(),text,date:new Date().toLocaleString('pt-BR')});update();break;}
case'deleteNote':r.annotations=r.annotations.filter(x=>x.id!==arg);update();break;
case'undoStroke':r.strokes.pop();update();break;
case'clearDrawing':if(confirm('Limpar todos os traços deste ambiente?')){r.strokes=[];update();}break;
case'studioMode':studioMode=['esboco','planta','laboratorio'].includes(arg)?arg:'esboco';if(studioMode==='planta')studioGrid='lines';render();break;
case'studioGotoPhotos':subtab='fotos';render();break;
case'studioSetMeasure':{const pg=studioCurrent(p);const mm=Number(val('studioElementMm'));if(!pg?.strokes?.length)throw Error('Desenhe um elemento primeiro.');if(!Number.isFinite(mm)||mm<1||mm>50000)throw Error('Informe uma medida entre 1 e 50000 mm.');pg.strokes[pg.strokes.length-1].mm=mm;pg.lastMeasureMm=mm;update();toast('Medida vinculada ao último elemento.');break;}
case'studioNew':{const name=val('studioNewName').trim()||'Folha '+(studioPages(p).length+1);const pg={id:C.uid(),name:name.slice(0,100),width:840,height:1188,strokes:[],undone:[],text:'',roomId:selectedRoom||'',createdAt:new Date().toISOString()};studioPages(p).push(pg);studioPageId=pg.id;update();break;}
case'studioSelect':studioPageId=arg;studioFullscreen=false;render();break;
case'studioOpenFull':if(!studioCurrent(p))throw Error('Crie uma folha primeiro.');studioFullscreen=true;render();break;
case'studioCloseFull':studioFullscreen=false;render();break;
case'studioRename':{const pg=studioCurrent(p);if(!pg)break;const name=prompt('Nome da página',pg.name);if(name===null)break;pg.name=name.trim()||pg.name;update();break;}
case'studioDelete':{const pg=studioCurrent(p);if(!pg||!confirm('Excluir esta folha e seus desenhos?'))break;p.studioPages=p.studioPages.filter(x=>x.id!==pg.id);studioPageId=null;studioFullscreen=false;update();break;}
case'studioSaveText':{const pg=studioCurrent(p);if(!pg)break;pg.text=val('studioText');update();toast('Anotação salva.');break;}
case'studioUndo':{const pg=studioCurrent(p);if(!pg||!pg.strokes?.length)break;(pg.undone||(pg.undone=[])).push(pg.strokes.pop());update();break;}
case'studioRedo':{const pg=studioCurrent(p);if(!pg||!pg.undone?.length)break;pg.strokes.push(pg.undone.pop());update();break;}
case'studioExport':{const canvas=$('#studioCanvas');if(!canvas)throw Error('Crie uma página primeiro.');const a=document.createElement('a');a.href=canvas.toDataURL('image/png');a.download='arque-rascunho.png';document.body.appendChild(a);a.click();a.remove();break;}
case'addPayment':{let amount=C.money(val('payamount'));if(amount<=0)throw Error('Pagamento deve ser positivo.');p.payments.push({id:C.uid(),amount,method:val('paymethod'),date:val('paydate')});update();toast('Recebimento registrado.');break;}
case'deletePayment':if(confirm('Excluir recebimento?')){p.payments=p.payments.filter(x=>x.id!==arg);update();}break;
case'calcSocket':{let x=C.socket(num('tw'),num('tl'),num('tc'),num('tr'),num('tt'));state.settings.tolerance=num('tt');$('#socketResult').innerHTML=`<div class="metric">Centro da tomada <b>${fmt(x.center)} mm</b></div><div class="metric">Erro de fechamento <b>${fmt(x.closureError)} mm</b></div><p class="${x.withinTolerance?'':'warn'}">${x.withinTolerance?'Dentro da tolerância configurada.':'⚠ Conferir medidas antes de fabricar.'}</p>`;persist();break;}
case'calcHeights':{let x=C.variations([num('h1'),num('h2'),num('h3')]);$('#heightsResult').innerHTML=`<div class="metric">Menor altura <b>${fmt(x.min)} mm</b></div><div class="metric">Maior altura <b>${fmt(x.max)} mm</b></div><div class="metric">Diferença <b>${fmt(x.difference)} mm</b></div>`;break;}
case'calcCarcass':{let x=C.carcass(num('ct'),num('cs'),num('cb'),num('cc'));$('#carcassResult').innerHTML=`<div class="metric">Face inferior da pedra <b>${fmt(x.underside)} mm</b></div><div class="metric">Altura teórica da carcaça <b>${fmt(x.height)} mm</b></div><p class="warn">Conferir cuba, sifão e travessas.</p>`;break;}
case'calcOpening':{let x=C.usableOpening([num('v1'),num('v2'),num('v3')],num('vl'),num('vr'));$('#openingResult').innerHTML=`<div class="metric">Menor vão <b>${fmt(x.minimum)} mm</b></div><div class="metric">Vão teórico útil <b>${fmt(x.usable)} mm</b></div><div class="metric">Variação <b>${fmt(x.variation)} mm</b></div>`;break;}
case'linkShare':{if(!window.ArqueNative?.linkStart)throw Error('Arque Link requer APK Android.');const full=val('linkMode')==='full';if(full&&!confirm('Compartilhar todos os clientes, contratos, fotos e obras com outro dispositivo autorizado?'))break;const payload=full?{format:'arque-measure',version:1,createdAt:new Date().toISOString(),state}:C.exportProject(state,val('linkProject'));window.ArqueNative.linkStart(JSON.stringify(payload));linkNotice='Iniciando compartilhamento…';render();break;}
case'linkAdvertise':{if(!window.ArqueNative?.linkAdvertise)throw Error('Anúncio BLE exige APK Android.');window.ArqueNative.linkAdvertise();break;}
case'linkDiscover':{if(!window.ArqueNative?.linkDiscover)throw Error('Busca Bluetooth exige APK Android.');linkPeers=[];window.ArqueNative.linkDiscover();linkNotice='Buscando aparelhos próximos por Bluetooth…';render();break;}
case'linkUsePeer':{const fieldIP=$('#linkIP');if(fieldIP)fieldIP.value=String(arg);linkNotice='Aparelho selecionado. Informe o código mostrado no aparelho de origem.';const notice=$('#linkNotice');if(notice)notice.textContent=linkNotice;break;}
case'linkStop':window.ArqueNative?.linkStop?.();linkInfo=null;linkNotice='Compartilhamento encerrado';render();break;
case'linkFetch':{if(!window.ArqueNative?.linkReceive)throw Error('Arque Link requer APK Android.');const ip=val('linkIP').trim(),code=val('linkCode').trim();if(!confirm('Importar uma cópia do projeto enviado por '+ip+'?'))break;window.ArqueNative.linkReceive(ip,code);linkNotice='Recebendo projeto…';render();break;}
case'export':exportBackup();break;
case'import':if(window.ArqueNative?.importBackup)window.ArqueNative.importBackup();else $('#importFile').click();break;
case'bleScan':if(window.ArqueNative?.scanBle){window.ArqueNative.scanBle();toast('Procurando trenas próximas…');}else toast('A conexão Bluetooth requer o aplicativo Android.');break;
case'bleDisconnect':window.ArqueNative?.disconnectBle?.();lastBLE=null;lastBleReceipt=null;render();break;
}}
async function exportBackup(){const payload=JSON.stringify({format:'arque-measure',version:1,createdAt:new Date().toISOString(),state});if(window.ArqueNative?.exportBackup){window.ArqueNative.exportBackup(payload);return;}const blob=new Blob([payload],{type:'application/json'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='arque-measure-'+new Date().toISOString().slice(0,10)+'.arque';document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(url),2000);toast('Backup exportado.');}
async function receiveImport(text){const parsed=JSON.parse(text),newState=C.validateImport(parsed);if(!confirm('Substituir TODOS os clientes, projetos e contratos deste aparelho? Faça backup dos dados atuais antes.'))return;const previous=state;state=newState;try{await persist();render();toast('Backup restaurado com sucesso.');}catch(e){state=previous;render();throw e;}}
window.ArqueLinkReady=raw=>{try{linkInfo=JSON.parse(raw);linkNotice='Compartilhamento ativado. Informe o endereço e o código no outro Android.';render();}catch(e){toast('Erro na autorização');}};
window.ArqueLinkEvent=(kind,value)=>{linkNotice=String(value).slice(0,250);if(tab==='transfer')render();if(kind==='error')toast('Arque Link: '+linkNotice);};
window.ArqueLinkReceive=async raw=>{try{
 const received=JSON.parse(raw);
 if(received?.format==='arque-measure'){
   const incoming=C.validateImport(received);
   if(!confirm('O outro Arque Measure enviou um BACKUP COMPLETO com '+incoming.clients.length+' clientes e '+incoming.projects.length+' obras. SUBSTITUIR todos os dados locais? Exporte seu backup primeiro.'))return;
   const previous=state;state=incoming;
   try{await persist();}catch(e){state=previous;throw e;}
   selectedProject=null;selectedClient=null;tab='home';render();toast('Dados completos recebidos e salvos.');return;
 }
 if(!confirm('Receber projeto "'+String(received.project?.name||'').slice(0,100)+'" de "'+String(received.client?.name||'').slice(0,100)+'"? Será salva uma cópia independente.'))return;
 const merged=C.mergeProject(state,received);const oldState=state;state=merged.state;
 try{await persist();}catch(e){state=oldState;throw e;}
 linkNotice='Projeto recebido, validado e salvo localmente.';selectedProject=merged.projectId;selectedRoom=null;tab='projects';render();toast('Projeto recebido com sucesso.');
 }catch(e){linkNotice='Falha ao importar: '+e.message;render();toast(linkNotice);}};
window.ArqueDiagnostics=raw=>{try{diagnostics=typeof raw==='string'?JSON.parse(raw):raw;render();}catch(e){toast('Diagnóstico inválido: '+e.message)}};
window.ArqueReceiveBackup=text=>receiveImport(text).catch(e=>toast('Falha na importação: '+e.message));
window.ArqueBleMeasure=millimeters=>{let n=Number(millimeters);if(!Number.isInteger(n)||n<50||n>50000)return;lastBLE=n;lastBleReceipt={id:C.uid(),value:n,date:new Date().toISOString()};bleReadings.push(lastBleReceipt);if(bleReadings.length>200)bleReadings.shift();const activeProject=project();if(activeProject){if(!Array.isArray(activeProject.bleReadings))activeProject.bleReadings=[];activeProject.bleReadings.push({...lastBleReceipt,roomId:selectedRoom});persist().catch(e=>toast('Falha ao salvar leitura da trena: '+e.message));}const el=$('#bleValue');if(el)el.textContent=fmt(n)+' mm';const inp=$('#mvalue');if(inp){inp.value=n;inp.dataset.readingId=lastBleReceipt.id;}const live=$('#photoBleLive');if(live)live.textContent=fmt(n)+' mm';toast('Leitura recebida: '+fmt(n)+' mm. Confira a referência.');};
window.ArqueBleStatus=status=>{const el=$('#connection');if(el)el.textContent=String(status).slice(0,70)};
window.ArqueBleDevices=devices=>{try{const list=JSON.parse(devices);if(!list.length)return;let msg=list.map((x,i)=>`${i+1}: ${x.name||'Trena BLE'} (${x.address})`).join('\n');let n=prompt('Selecione a trena:\n'+msg);let d=list[Number(n)-1];if(d)window.ArqueNative.connectBle(d.address);}catch(e){toast('Erro ao listar trenas: '+e.message)}};
$('#contractFile').addEventListener('change',async e=>{const file=e.target.files[0];const c=state.clients.find(x=>x.id===e.target.dataset.clientId);try{if(!file||!c)return;if(file.size>6*1024*1024)throw Error('Arquivo muito grande. Máximo de 6 MB por contrato.');if(!(['application/pdf','image/jpeg','image/png','image/webp'].includes(file.type)))throw Error('Aceita apenas PDF, JPG, PNG ou WebP.');const data=await new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=()=>reject(Error('Erro na leitura'));r.readAsDataURL(file);});if(!Array.isArray(c.contracts))c.contracts=[];c.contracts.push({id:C.uid(),name:file.name.slice(0,120),type:file.type,size:file.size,data,projectId:e.target.dataset.projectId||'',date:new Date().toLocaleDateString('pt-BR'),createdAt:new Date().toISOString()});await persist();render();toast('Contrato anexado ao cliente.');}catch(err){toast('Não foi possível anexar: '+err.message);}finally{e.target.value='';}});
$('#importFile').addEventListener('change',async e=>{try{let f=e.target.files[0];if(f)await receiveImport(await f.text());}catch(err){toast('Erro no backup: '+err.message)}e.target.value='';});
for(const fileInput of ['#photoFile','#cameraFile'])$(fileInput).addEventListener('change',async e=>{try{const f=e.target.files[0];if(!f)return;const img=await createImageBitmap(f);let ratio=Math.min(1,1600/Math.max(img.width,img.height)),can=document.createElement('canvas');can.width=Math.round(img.width*ratio);can.height=Math.round(img.height*ratio);can.getContext('2d').drawImage(img,0,0,can.width,can.height);const photo={id:C.uid(),name:f.name.slice(0,100),data:can.toDataURL('image/jpeg',0.72),createdAt:new Date().toISOString(),category:pendingPhotoCategory,roomId:pendingPhotoRoom};project().photos.push(photo);await update();toast('Foto salva no projeto.');}catch(err){toast('Falha ao salvar foto: '+err.message)}e.target.value='';});
$('#diagCameraFile').addEventListener('change',async e=>{const file=e.target.files[0];if(file){cameraCheck='Imagem recebida ('+Math.round(file.size/1024)+' KB)';render();toast('Imagem de teste recebida.');}e.target.value='';});
function setupDrawing(){const canvas=$('#drawing'),r=room();if(!canvas||!r)return;const ctx=canvas.getContext('2d');function repaint(){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#fff';ctx.fillRect(0,0,canvas.width,canvas.height);ctx.strokeStyle='#dae6dc';ctx.lineWidth=1;for(let x=0;x<canvas.width;x+=50){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,canvas.height);ctx.stroke()}for(let y=0;y<canvas.height;y+=50){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(canvas.width,y);ctx.stroke()}ctx.lineWidth=3;ctx.lineJoin='round';ctx.lineCap='round';for(const stored of [...r.strokes,...(drawActive?[{points:drawPoints,color:drawColor}]:[])]){const stroke=Array.isArray(stored)?stored:stored.points;if(!stroke?.length)continue;ctx.strokeStyle=stored.color||'#1c563b';ctx.beginPath();ctx.moveTo(stroke[0][0],stroke[0][1]);for(let i=1;i<stroke.length;i++)ctx.lineTo(stroke[i][0],stroke[i][1]);if(stroke.length===1)ctx.lineTo(stroke[0][0]+.01,stroke[0][1]);ctx.stroke()}}function point(e){const b=canvas.getBoundingClientRect();return [(e.clientX-b.left)*canvas.width/b.width,(e.clientY-b.top)*canvas.height/b.height].map(n=>Math.round(n*10)/10)}canvas.onpointerdown=e=>{drawActive=true;drawPoints=[point(e)];canvas.setPointerCapture(e.pointerId);repaint()};canvas.onpointermove=e=>{if(drawActive){drawPoints.push(point(e));repaint()}};canvas.onpointerup=async()=>{if(!drawActive)return;drawActive=false;if(drawPoints.length)r.strokes.push({points:drawPoints,color:drawColor});drawPoints=[];await persist();repaint()};canvas.onpointercancel=()=>{drawActive=false;drawPoints=[];repaint()};repaint();}
document.addEventListener('click',e=>{let b=e.target.closest('[data-action]');if(b){try{const out=action(b.dataset.action,b.dataset.arg);if(out?.catch)out.catch(x=>toast(x.message));}catch(err){toast(err.message)}return;}let t=e.target.closest('[data-tab]');if(t){if(tab!==t.dataset.tab)navigationHistory.push({tab,selectedClient,selectedProject,selectedRoom,subtab});tab=t.dataset.tab;selectedProject=null;selectedRoom=null;selectedClient=null;subtab='resumo';render();window.scrollTo(0,0);return;}let s=e.target.closest('[data-subtab]');if(s){if(subtab!==s.dataset.subtab)navigationHistory.push({tab,selectedProject,selectedRoom,subtab});subtab=s.dataset.subtab;render();window.scrollTo(0,0);return;}let r=e.target.closest('[data-room]');if(r){if(selectedRoom!==r.dataset.room)navigationHistory.push({tab,selectedProject,selectedRoom,subtab});selectedRoom=r.dataset.room;render();window.scrollTo(0,0);return;}});
document.addEventListener('input',e=>{if(e.target.dataset.cutDraft&&project()){const plan=cuttingPlan(project());if(!plan.draft)plan.draft={};plan.draft[e.target.dataset.cutDraft]=e.target.dataset.cutDraft==='rotate'?e.target.value==='Sim':e.target.dataset.cutDraft==='grain'?e.target.value==='Fixo':e.target.value;persist().catch(err=>toast('Rascunho não salvo: '+err.message));}if(e.target.id==='mvalue')delete e.target.dataset.readingId;});
let mixedDrag=null;
document.addEventListener('pointerdown',e=>{
 const piece=e.target.closest('.mixed-movable');
 if(!piece||tab!=='projects'||subtab!=='corte')return;
 const sheet=piece.closest('.mixed-drag-sheet');if(!sheet)return;
 mixedDrag={piece,sheet,key:piece.dataset.mixedKey,x:Number(piece.dataset.mixedX),y:Number(piece.dataset.mixedY),px:e.clientX,py:e.clientY};
 piece.setPointerCapture(e.pointerId);e.preventDefault();
});
document.addEventListener('pointermove',e=>{
 if(!mixedDrag)return;
 mixedDrag.piece.style.transform='translate('+(e.clientX-mixedDrag.px)+'px,'+(e.clientY-mixedDrag.py)+'px)';
 e.preventDefault();
});
document.addEventListener('pointerup',e=>{
 if(!mixedDrag)return;
 const drag=mixedDrag;mixedDrag=null;const plan=project()?.cutPlan,stock=plan?.mixedStock;
 if(!stock){render();return;}
 const box=drag.sheet.getBoundingClientRect();
 const x=Math.round(drag.x+(e.clientX-drag.px)*stock.width/box.width);
 const y=Math.round(drag.y+(e.clientY-drag.py)*stock.height/box.height);
 const moves={...(stock.moves||{}),[drag.key]:{x,y}};
 try{const layout=window.ArqueCut.mixedStock({...stock,pieces:plan.pieces.filter(p=>stock.ids.includes(p.id))});window.ArqueCut.positionMixed(layout,moves);stock.moves=moves;persist().then(()=>render()).catch(err=>{render();toast('Erro ao salvar: '+err.message);});}
 catch(err){render();toast('Não é possível mover: '+err.message);}
 e.preventDefault();
});
document.addEventListener('pointercancel',()=>{if(mixedDrag){mixedDrag=null;render();}});
// Double tap on the photograph toggles free navigation; a normal stroke is not a double tap.
let photoTapDown=null,photoLastTap=null,photoTriplePending=null,photoZoomPreviousInk=true,photoZoomPreviousPlacement=false;
document.addEventListener('pointerdown',e=>{
 if(!e.target.closest('#photoMeasureStage')||e.pointerType==='mouse'&&e.button!==0)return;
 const now=Date.now();
 if(photoTriplePending&&now-photoTriplePending.time<420&&Math.hypot(e.clientX-photoTriplePending.x,e.clientY-photoTriplePending.y)<38){
  photoTriplePending=null;photoLastTap=null;photoTapDown=null;
  photoZoom=1;photoPanX=0;photoPanY=0;
  if(photoZoomMode){photoZoomMode=false;photoInk=photoZoomPreviousInk;photoPlacement=photoZoomPreviousPlacement;}
  photoZoomPointers.clear();photoZoomPinch=null;photoZoomPan=null;
  render();applyPhotoZoom();
  e.preventDefault();e.stopImmediatePropagation();return;
 }
 const doubleTap=photoLastTap&&now-photoLastTap.time<360&&Math.hypot(e.clientX-photoLastTap.x,e.clientY-photoLastTap.y)<38;
 photoTapDown={id:e.pointerId,x:e.clientX,y:e.clientY,moved:false,ink:photoInk&&!photoZoomMode&&!photoPlacement};
 if(!doubleTap)return;
 photoTriplePending={x:e.clientX,y:e.clientY,time:now};
 const firstTap=photoLastTap;photoLastTap=null;photoTapDown=null;
 const wasZoom=photoZoomMode;
 if(!wasZoom){photoZoomPreviousInk=photoInk;photoZoomPreviousPlacement=photoPlacement;photoZoomMode=true;photoInk=false;photoPlacement=false;}
 else{photoZoomMode=false;photoInk=photoZoomPreviousInk;photoPlacement=photoZoomPreviousPlacement;}
 // The first tap must not leave a small ink dot on the photograph.
 if(!wasZoom&&firstTap?.ink){const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);const strokes=photo?.inkStrokes;if(strokes?.length){const last=strokes[strokes.length-1];const points=Array.isArray(last)?last:last.points||[];if(points.length<=2){strokes.pop();persist().catch(()=>{});}}}
 photoZoomPointers.clear();photoZoomPinch=null;photoZoomPan=null;
 render();applyPhotoZoom();
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointermove',e=>{
 if(photoTapDown?.id===e.pointerId&&Math.hypot(e.clientX-photoTapDown.x,e.clientY-photoTapDown.y)>12)photoTapDown.moved=true;
},true);
document.addEventListener('pointerup',e=>{
 if(photoTapDown?.id!==e.pointerId)return;
 if(!photoTapDown.moved)photoLastTap={x:e.clientX,y:e.clientY,time:Date.now(),ink:photoTapDown.ink};
 else photoLastTap=null;
 photoTapDown=null;
},true);
document.addEventListener('pointercancel',e=>{if(photoTapDown?.id===e.pointerId){photoTapDown=null;photoLastTap=null;}},true);
// Photo zoom: pan with one finger or S Pen; pinch with two fingers in move/zoom mode.
const photoZoomPointers=new Map();let photoZoomPinch=null,photoZoomPan=null;
document.addEventListener('pointerdown',e=>{
 if(!photoZoomMode||!e.target.closest('#photoMeasureStage'))return;
 const stage=$('#photoMeasureStage');if(!stage)return;
 photoZoomPointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
 if(photoZoomPointers.size===1)photoZoomPan={x:e.clientX,y:e.clientY,panX:photoPanX,panY:photoPanY};
 if(photoZoomPointers.size===2){const pts=[...photoZoomPointers.values()];photoZoomPinch={distance:Math.hypot(pts[0].x-pts[1].x,pts[0].y-pts[1].y)||1,zoom:photoZoom};photoZoomPan=null;}
 try{stage.setPointerCapture(e.pointerId)}catch(_){}
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointermove',e=>{
 if(!photoZoomPointers.has(e.pointerId))return;
 photoZoomPointers.set(e.pointerId,{x:e.clientX,y:e.clientY});
 if(photoZoomPointers.size>=2&&photoZoomPinch){const pts=[...photoZoomPointers.values()];photoZoomSet(photoZoomPinch.zoom*Math.hypot(pts[0].x-pts[1].x,pts[0].y-pts[1].y)/photoZoomPinch.distance);}
 else if(photoZoomPan){photoPanX=photoZoomPan.panX+e.clientX-photoZoomPan.x;photoPanY=photoZoomPan.panY+e.clientY-photoZoomPan.y;applyPhotoZoom();}
 e.preventDefault();e.stopImmediatePropagation();
},true);
const photoZoomEnd=e=>{if(!photoZoomPointers.has(e.pointerId))return;photoZoomPointers.delete(e.pointerId);photoZoomPinch=null;photoZoomPan=null;e.preventDefault();e.stopImmediatePropagation();};
document.addEventListener('pointerup',photoZoomEnd,true);
document.addEventListener('pointercancel',photoZoomEnd,true);
document.addEventListener('wheel',e=>{if(!e.target.closest('#photoMeasureStage'))return;if(!e.ctrlKey&&!photoZoomMode)return;e.preventDefault();photoZoomSet(photoZoom*(e.deltaY<0?1.12:1/1.12));},{passive:false});
document.addEventListener('pointerdown',e=>{
 if(photoZoomMode||!photoPlacement||!e.target.closest('#photoOverlay'))return;
 const svg=$('#photoOverlay');if(!svg)return;
 photoPlacementStart={...photoOverlayCoords(e,svg),pointerId:e.pointerId};photoPlacementPreview={...photoPlacementStart};
 try{svg.setPointerCapture(e.pointerId)}catch(_){}
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointermove',e=>{
 if(!photoPlacementStart||photoPlacementStart.pointerId!==e.pointerId)return;
 const svg=$('#photoOverlay');if(!svg)return;
 const point=photoOverlayCoords(e,svg);photoPlacementPreview=point;
 const line=svg.querySelector('#photoPlacementPreview');
 if(line){line.setAttribute('x1',photoPlacementStart.x);line.setAttribute('y1',photoPlacementStart.y);line.setAttribute('x2',point.x);line.setAttribute('y2',point.y);line.setAttribute('visibility','visible');}
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointerup',e=>{
 if(!photoPlacementStart||photoPlacementStart.pointerId!==e.pointerId)return;
 const svg=$('#photoOverlay'),start=photoPlacementStart,end=svg?photoOverlayCoords(e,svg):photoPlacementPreview;
 photoPlacementStart=null;photoPlacementPreview=null;
 // Keep arrow tool selected after finishing: next drag creates another arrow.
 photoPlacement=true;photoInk=false;
 const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);
 if(photo&&end&&Math.hypot(end.x-start.x,end.y-start.y)>12){
  const d={id:C.uid(),label:'Medida '+(overlayFor(photo).length+1),shape:'arrow',thickness:4,color:'#ffe000',x1:start.x,y1:start.y,x2:end.x,y2:end.y,value:null,source:'manual'};
  overlayFor(photo).push(d);photoMeasureSelected=d.id;update();
 }else{render();toast('Arraste sobre a foto para desenhar a seta.');}
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointercancel',e=>{if(photoPlacementStart?.pointerId===e.pointerId){photoPlacementStart=null;photoPlacementPreview=null;render();}},true);
// Each pen contact creates one independent, immediately visible stroke.
// A measurement's central yellow box is always tappable, even when the pen is active.
document.addEventListener('pointerdown',e=>{
 const label=e.target.closest('[data-measure-label]');
 if(!label||!e.target.closest('#photoOverlay')||photoPlacement||photoZoomMode)return;
 photoMeasureSelected=label.dataset.measureLabel;
 photoInk=false;photoStrokeActive=null;photoInkPointer=null;
 render();
 const details=$('#photoMeasureDetails');if(details)details.scrollIntoView?.({block:'nearest',behavior:'smooth'});
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointerdown',e=>{
 if(photoZoomMode||photoPlacement||!photoInk||!e.target.closest('#photoOverlay'))return;
 if(photoInkPointer!==null)return;
 const svg=$('#photoOverlay'),photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);
 if(!svg||!photo)return;
 if(!photo.inkStrokes)photo.inkStrokes=[];
 const stroke={points:[photoOverlayCoords(e,svg)],color:photoInkColor,width:photoInkWidth};
 photo.inkStrokes.push(stroke);photoStrokeActive=stroke;photoInkPointer=e.pointerId;
 try{svg.setPointerCapture(e.pointerId)}catch(_){}
 e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointermove',e=>{
 if(!photoStrokeActive||photoInkPointer!==e.pointerId)return;
 const svg=$('#photoOverlay');if(!svg)return;
 photoStrokeActive.points.push(photoOverlayCoords(e,svg));
 let line=svg.querySelector('#livePhotoInk');
 if(!line){line=document.createElementNS('http://www.w3.org/2000/svg','polyline');line.id='livePhotoInk';line.setAttribute('fill','none');line.setAttribute('stroke-linecap','round');line.setAttribute('stroke-linejoin','round');svg.append(line);}
 line.setAttribute('stroke',photoStrokeActive.color);line.setAttribute('stroke-width',photoStrokeActive.width);
 line.setAttribute('points',photoStrokeActive.points.map(p=>p.x+','+p.y).join(' '));
 e.preventDefault();e.stopImmediatePropagation();
},true);
const finishPhotoInk=e=>{
 if(!photoStrokeActive||photoInkPointer!==e.pointerId)return;
 photoStrokeActive=null;photoInkPointer=null;
 const svg=$('#photoOverlay'),live=svg?.querySelector('#livePhotoInk');
 if(live){live.removeAttribute('id');}
 persist().catch(err=>toast(err.message));
};
document.addEventListener('pointerup',finishPhotoInk,true);
document.addEventListener('pointercancel',finishPhotoInk,true);
document.addEventListener('lostpointercapture',finishPhotoInk,true);
document.addEventListener('pointerdown',e=>{const h=e.target.closest('[data-handle]');const g=e.target.closest('[data-dimension]');if(!g||!e.target.closest('#photoOverlay'))return;if(photoInk){photoInk=false;photoPlacement=false;}photoMeasureSelected=g.dataset.dimension;document.querySelectorAll('#photoOverlay [data-dimension]').forEach(node=>{const active=node===g;node.classList.toggle('dim-selected',active);node.querySelectorAll('circle').forEach(c=>{c.setAttribute('opacity',active?'1':'0');c.setAttribute('r',active?'12':'7');});});if(h){photoDrag=h.dataset.handle;h.setPointerCapture(e.pointerId);}else{const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto),d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(d){photoDrag='move';const start=photoOverlayCoords(e,$('#photoOverlay'));photoMoveAnchor={start,x1:d.x1,y1:d.y1,x2:d.x2,y2:d.y2};g.setPointerCapture(e.pointerId);const input=$('#photoMeasureValue'),name=$('#photoMeasureLabel'),note=$('#photoMeasureNote');if(input)input.value=d.value||'';if(name)name.value=d.label||'';if(note)note.value=d.note||'';const thick=$('#photoMeasureThickness');if(thick)thick.value=d.thickness||5;}}e.preventDefault();});
document.addEventListener('pointermove',e=>{if(!photoDrag)return;const svg=$('#photoOverlay');const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);const d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!svg||!d)return;const point=photoOverlayCoords(e,svg);if(photoDrag==='a'){d.x1=point.x;d.y1=point.y;}else if(photoDrag==='b'){d.x2=point.x;d.y2=point.y;}else if(photoDrag==='move'&&photoMoveAnchor){const dx=point.x-photoMoveAnchor.start.x,dy=point.y-photoMoveAnchor.start.y;const nx1=photoMoveAnchor.x1+dx,nx2=photoMoveAnchor.x2+dx,ny1=photoMoveAnchor.y1+dy,ny2=photoMoveAnchor.y2+dy;if(Math.min(nx1,nx2)>=0&&Math.max(nx1,nx2)<=1000&&Math.min(ny1,ny2)>=0&&Math.max(ny1,ny2)<=650){d.x1=nx1;d.x2=nx2;d.y1=ny1;d.y2=ny2;}}const g=[...svg.querySelectorAll('[data-dimension]')].find(x=>x.dataset.dimension===d.id);if(g){const line=g.querySelector('line:not(.measure-hit)'),hit=g.querySelector('.measure-hit'),rect=d.shape==='rect'?g.querySelector(':scope > rect'):null,circles=g.querySelectorAll('circle'),label=g.querySelector('.measure-label');
 if(line){for(const l of [line,hit]){if(!l)continue;l.setAttribute('x1',d.x1);l.setAttribute('y1',d.y1);l.setAttribute('x2',d.x2);l.setAttribute('y2',d.y2);}}
 if(rect){rect.setAttribute('x',Math.min(d.x1,d.x2));rect.setAttribute('y',Math.min(d.y1,d.y2));rect.setAttribute('width',Math.abs(d.x2-d.x1));rect.setAttribute('height',Math.abs(d.y2-d.y1));}
 if(circles.length===2){circles[0].setAttribute('cx',d.x1);circles[0].setAttribute('cy',d.y1);circles[1].setAttribute('cx',d.x2);circles[1].setAttribute('cy',d.y2);}
 if(label)label.setAttribute('transform','translate('+((d.x1+d.x2)/2)+' '+((d.y1+d.y2)/2)+')'+((function(){const a=Math.atan2(d.y2-d.y1,d.x2-d.x1)*180/Math.PI;return ' rotate('+(a>90?a-180:a< -90?a+180:a)+')'})()));
 }e.preventDefault();});
document.addEventListener('pointerup',()=>{if(photoDrag){photoDrag=null;photoMoveAnchor=null;persist().then(()=>{if(tab==='projects'&&subtab==='fotomedidas')render();}).catch(e=>toast(e.message));}});
document.addEventListener('change',e=>{
 const el=e.target;
 if(el.dataset.cutId&&tab==='projects'&&subtab==='corte'){
 const plan=cuttingPlan(project()),piece=plan.pieces.find(x=>x.id===el.dataset.cutId);if(!piece)return;
 const key=el.dataset.cutField;const value=key==='rotate'||key==='grain'?el.value==='true':(['w','h','qty'].includes(key)?Number(el.value):el.value.trim());
 const changed={...piece,[key]:value};
 try{window.ArqueCut.calculate({...plan,pieces:[changed]});if(JSON.stringify(changed)!==JSON.stringify(piece)){archiveCutRevision(plan,piece,'Alteração de '+key);Object.assign(piece,changed);if(['w','h','qty'].includes(key)){for(const record of Object.keys(plan.cutDone||{}))if(record.startsWith(piece.id+':'))delete plan.cutDone[record];}}persist().then(()=>render()).catch(err=>toast('Erro ao salvar: '+err.message));}catch(err){toast('Valor inválido: '+err.message);render();}
 return;
 }
if(e.target.id==='photoRoom'){const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);if(photo){photo.roomId=e.target.value;persist().catch(err=>toast(err.message));}}
if(e.target.id==='measurePhoto'){photoMeasurePhoto=e.target.value;photoMeasureSelected=null;render();}if(e.target.id==='studioRoom'){const pg=studioCurrent(project());if(pg){pg.roomId=e.target.value;persist().catch(err=>toast(err.message));}}
if(e.target.id==='drawRoom'){selectedRoom=e.target.value;render()}if(e.target.id==='drawColor')drawColor=e.target.value});
(async()=>{try{db=await openDb();let saved=await readState();if(saved)state=saved;render();}catch(e){$('#main').innerHTML=`<div class="notice">Não foi possível iniciar o armazenamento local: ${escape(e.message)}. Use um navegador compatível ou o APK.</div>`}})();

window.ArqueAppBack=()=>{
 const previous=navigationHistory.pop();
 if(previous){({tab,selectedClient,selectedProject,selectedRoom,subtab}=previous);render();window.scrollTo(0,0);return true;}
 if(tab!=='home'){tab='home';selectedProject=null;selectedRoom=null;render();window.scrollTo(0,0);return true;}
 return false;
};
window.ArqueLinkDiscoveryEvent=(kind,value)=>{
 if(kind==='discovery_peers'){
   try{linkPeers=JSON.parse(value).filter(x=>x&&typeof x.ip==='string'&&/^(\d{1,3}\.){3}\d{1,3}$/.test(x.ip));
     linkNotice=linkPeers.length?linkPeers.length+' aparelho(s) localizado(s). Selecione um.':'Nenhum Arque Measure foi encontrado por Bluetooth.';
   }catch(e){linkPeers=[];linkNotice='Erro ao interpretar resultado da busca BLE.';}
 }else{linkNotice=String(value).slice(0,240);}
 if(tab==='transfer')render();
};

})();
