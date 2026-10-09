/* Arque Measure offline UI. All data saved to IndexedDB on this device. */
(()=>{'use strict';
const C=window.ArqueCore; const $=s=>document.querySelector(s);
const escape=s=>String(s??'').replace(/[&<>"']/g,ch=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
const money=v=>Number(v||0).toLocaleString('pt-BR',{style:'currency',currency:'BRL'});
const fmt=v=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
const statuses=['Levantamento','Projeto','Orçamento','Aprovado','Produção','Montagem','Finalizado','Cancelado'];
let navigationHistory=[];let pendingPhotoCategory='Levantamento',drawColor='#ffd329';
let studioPageId=null, studioInk='#176f9d', studioWidth=3, studioTool='pen', studioGrid='dots', studioActive=false, studioPoints=[];
let linkPeers=[];
let linkInfo=null,linkNotice='';
let db, state={clients:[],projects:[],settings:{tolerance:5}},tab='home',selectedClient=null,selectedProject=null,selectedRoom=null,subtab='medidas',lastBLE=null,lastBleReceipt=null,bleReadings=[],bleDevice=null,diagnostics=null,cameraCheck='Não testada',drawActive=false,drawPoints=[];
const field=(id,label,type='text',value='',extra='')=>`<div class="field"><label for="${id}">${escape(label)}</label><input id="${id}" type="${type}" value="${escape(value)}" ${extra}></div>`;
const select=(id,label,items,value='')=>`<div class="field"><label for="${id}">${escape(label)}</label><select id="${id}">${items.map(x=>{const val=typeof x==='string'?x:x.id, txt=typeof x==='string'?x:x.name;return `<option value="${escape(val)}" ${val===value?'selected':''}>${escape(txt)}</option>`}).join('')}</select></div>`;
const btn=(label,action,arg='',cl='')=>`<button class="btn ${cl}" data-action="${action}" data-arg="${escape(arg)}">${label}</button>`;
function toast(t){const el=$('#toast');el.textContent=t;el.style.display='block';clearTimeout(toast.t);toast.t=setTimeout(()=>el.style.display='none',3800)}
function openDb(){return new Promise((resolve,reject)=>{let req=indexedDB.open('arque_measure_local',1);req.onupgradeneeded=()=>req.result.createObjectStore('store');req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});}
function readState(){return new Promise((resolve,reject)=>{let r=db.transaction('store').objectStore('store').get('state');r.onsuccess=()=>resolve(r.result||null);r.onerror=()=>reject(r.error);});}
function persist(){return new Promise((resolve,reject)=>{let r=db.transaction('store','readwrite').objectStore('store').put(state,'state');r.onsuccess=()=>resolve();r.onerror=()=>reject(r.error);});}
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
   '<div class="card"><h3>Obras de '+escape(c.name)+'</h3><p class="muted">Projetos agrupados por etapa, sem misturar finalizados e orçamentos.</p>'+groupedProjects(projects)+
   '<div class="actions">'+btn('+ Nova obra','clientProject',c.id,'primary')+'</div></div>'+contractsView(c);
 }
 return header('Clientes','Abra o cliente para acessar projetos e contratos.')+
 '<div class="card"><h3>Novo cliente</h3><div class="fields">'+field('cname','Nome completo')+field('cphone','Telefone','tel')+field('caddr','Endereço')+'</div>'+btn('Salvar cliente','addClient','','primary')+'</div>'+
 '<div class="card"><h3>Todos os clientes ('+state.clients.length+')</h3>'+
 state.clients.map(c=>{const ps=state.projects.filter(p=>p.clientId===c.id);
 return '<div class="item project-row"><div><strong>'+escape(c.name)+'</strong><small>'+escape(c.phone||'')+' · '+ps.length+' obra(s)</small></div><div class="project-row-end">'+(ps.length?statusBadge(ps.slice().sort((a,b)=>String(b.updatedAt||'').localeCompare(String(a.updatedAt||'')))[0].status):'<span class="project-status">Sem obras</span>')+btn('Abrir','openClient',c.id,'small')+'</div></div>';}).join('')+
 (state.clients.length?'':'<div class="empty">Nenhum cliente cadastrado.</div>')+'</div>';
}
function projectsView(){if(project())return detailView();return header('Projetos','Levantamento, produção, entrega e financeiro em um só lugar.')+`<div class="card"><h3>Novo projeto</h3>${state.clients.length?`<div class="fields">${select('pclient','Cliente',state.clients)}${field('pname','Nome da obra')}${field('paddr','Endereço da obra')}</div>${btn('Criar projeto','addProject','','primary')}`:'<p>Cadastre primeiro um cliente na aba Clientes.</p>'}</div><div class="card"><h3>Todos os projetos</h3>${state.projects.map(p=>`<div class="item"><div><strong>${escape(p.name)}</strong><small>${escape(clientName(p.clientId))} · ${escape(p.status)} · ${p.rooms.length} ambientes</small></div>${btn('Abrir','openProject',p.id,'small')}</div>`).join('')||'<div class="empty">Nenhum projeto ainda.</div>'}</div>`;}

function cuttingPlan(p){if(!p.cutPlan)p.cutPlan={width:2750,height:1830,kerf:3,trim:0,pieces:[]};return p.cutPlan;}

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
 try{if(plan.pieces.length)result=window.ArqueCut.calculate(plan);}catch(e){error=e.message;}
 const met=(title,value)=>'<div class="metric"><span>'+title+'</span><b>'+value+'</b></div>';
 const num=(v)=>Number(v||0).toLocaleString('pt-BR',{maximumFractionDigits:2});
 let html='<div class="card"><h3>Plano de corte · '+escape(clientName(p.clientId))+'</h3><p class="muted">Peças e chapas vinculadas a esta obra. Valores em milímetros; cálculo de aproveitamento com cortes guilhotinados.</p><div class="fields">'+field('cutWidth','Comprimento chapa (mm)','number',plan.width,'min="1"')+field('cutHeight','Largura chapa (mm)','number',plan.height,'min="1"')+field('cutKerf','Espessura serra (mm)','number',plan.kerf,'min="0" step="0.1"')+field('cutTrim','Refilo em cada borda (mm)','number',plan.trim,'min="0" step="0.1"')+'</div>'+btn('Salvar configuração','cutSettings','','primary')+'</div>';
 html+='<div class="card"><h3>Adicionar peças</h3><div class="fields">'+field('cutName','Nome da peça','text','Lateral')+field('cutW','Comprimento (mm)','number','','min="1"')+field('cutH','Largura (mm)','number','','min="1"')+field('cutQty','Quantidade','number',1,'min="1" step="1"')+select('cutGrain','Veio / orientação',['Livre','Fixo'], 'Livre')+select('cutRotate','Permitir girar 90°',['Sim','Não'],'Sim')+field('cutEdge2','Nº bordas fita 2 mm (0 a 4)','number',0,'min="0" max="4"')+field('cutEdge04','Nº bordas fita 0,4 mm (0 a 4)','number',0,'min="0" max="4"')+'</div>'+btn('+ Adicionar peça','cutAdd','','primary')+'<p class="muted">Fitas: estimativa proporcional ao perímetro pelas bordas selecionadas; confira lados individuais na produção.</p></div>';
 html+='<div class="card"><h3>Lista de peças ('+plan.pieces.reduce((n,x)=>n+Number(x.qty||0),0)+')</h3><div class="cut-table"><table><thead><tr><th>Peça</th><th>Compr.</th><th>Larg.</th><th>Qtd.</th><th>Veio</th><th></th></tr></thead><tbody>'+plan.pieces.map(x=>'<tr><td>'+escape(x.name)+'</td><td>'+num(x.w)+'</td><td>'+num(x.h)+'</td><td>'+x.qty+'</td><td>'+(x.grain?'Fixo':'Livre')+'</td><td>'+btn('Excluir','cutRemove',x.id,'small danger')+'</td></tr>').join('')+'</tbody></table></div>'+(plan.pieces.length?'':'<div class="empty">Adicione peças para calcular as chapas.</div>')+'</div>';
 html+=manualCutView(p,plan);
 if(error)html+='<div class="notice">Não foi possível calcular: '+escape(error)+'</div>';
 if(result){html+='<div class="card"><div class="row"><h3>Resultados</h3>'+btn('Imprimir / PDF','cutPrint','','small')+'</div>'+met('Dimensões da chapa',num(plan.width)+' × '+num(plan.height)+' mm')+met('Quantidade de chapas',result.sheetCount)+met('Área por chapa',num(plan.width*plan.height/1e6)+' m²')+met('Área das chapas',num(result.allocatedArea/1e6)+' m²')+met('Quantidade de peças',result.totalPieces)+met('Peças acomodadas',result.placedPieces)+met('Área das peças',num(result.usedArea/1e6)+' m²')+met('Sobra + serragem + refilo',num(result.wasteArea/1e6)+' m²')+met('Aproveitamento',num(result.utilization)+'%')+met('Estimativa comprimento de cortes',num(result.cutLengthEstimate/1000)+' m')+met('Fita 2 mm (aproximada)',num(result.edge2mm/1000)+' m')+met('Fita 0,4 mm (aproximada)',num(result.edge04mm/1000)+' m')+'</div>';
 if(result.unfit.length)html+='<div class="notice">ATENÇÃO: '+result.unfit.length+' peça(s) não cabem nesta chapa e NÃO foram incluídas no plano. Revise as dimensões antes de cortar.</div>';
 result.sheets.forEach((sh,i)=>{html+='<div class="card"><h3>Chapa '+(i+1)+' / '+result.sheetCount+'</h3><div class="cut-sheet" style="aspect-ratio:'+plan.width+'/'+plan.height+'">'+sh.pieces.map((x,j)=>'<div class="cut-piece" style="left:'+100*x.x/plan.width+'%;top:'+100*x.y/plan.height+'%;width:'+100*x.w/plan.width+'%;height:'+100*x.h/plan.height+'%;background:hsl('+(195+(j*41)%95)+' 56% '+(82-(j%4)*5)+'%)" title="'+escape(x.name)+'">'+escape(x.name)+'<small>'+num(x.w)+' × '+num(x.h)+'</small></div>').join('')+'</div><small class="muted">Desenho proporcional em mm. Confirme a sequência de corte, o veio e as medidas antes da produção.</small></div>';});
 }
 return html;
}

function projectOverview(){
 const p=project();
 const tiles=[
 ['medidas','▱','Ambientes e medições',(p.rooms||[]).length+' ambientes'],
 ['fotos','▣','Fotografias',(p.photos||[]).length+' fotos'],
 ['fotomedidas','↔','Setas e medidas','Anotar diretamente sobre fotos'],
 ['desenho','✎','Esboço técnico','Desenhar por ambiente'],
 ['atelier','✦','Desenho livre','Páginas e S Pen'],
 ['corte','▦','Plano de corte','Peças, chapas e sobras'],
 ['calculo','⌗','Cálculos da obra','Conferência baseada no projeto'],
 ['financeiro','R$','Financeiro','Contrato e pagamentos']];
 return '<div class="card"><h3>Área de trabalho · '+escape(p.name)+'</h3><p class="muted">Tudo que você registrar aqui permanece vinculado à obra e ao cliente '+escape(clientName(p.clientId))+'.</p><div class="project-workspace">'+tiles.map(x=>'<button class="workspace-tile" data-action="'+(x[0]==='calculo'?'projectCalc':'openWorkspace')+'" data-arg="'+x[0]+'"><span class="workspace-icon">'+x[1]+'</span><strong>'+x[2]+'</strong><small>'+x[3]+'</small></button>').join('')+'</div></div>';
}
function detailView(){
 const p=project();
 return '<div class="row"><div><h1>'+escape(p.name)+'</h1><p class="intro">'+escape(clientName(p.clientId))+' · '+escape(p.address)+'</p></div>'+btn('← Cliente','closeProject','','small')+'</div>'+
 '<div class="card"><div class="fields">'+select('pstatus','Etapa do serviço',statuses,p.status)+field('pvalue','Contrato (R$)','number',p.value,'min="0" step="0.01"')+field('pdiscount','Desconto (R$)','number',p.discount,'min="0" step="0.01"')+'</div>'+btn('Salvar informações da obra','saveProject','','primary')+'</div>'+
 '<div class="tabs">'+[['resumo','▦ Visão geral'],['medidas','📏 Ambientes'],['fotos','📷 Fotos'],['fotomedidas','↔ Setas na foto'],['desenho','✎ Esboço'],['atelier','✦ Desenho livre'],['corte','▦ Plano de corte'],['financeiro','R$ Financeiro']].map(([key,label])=>'<button data-subtab="'+key+'" class="'+(subtab===key?'selected':'')+'">'+label+'</button>').join('')+'</div>'+
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

let photoMeasurePhoto=null,photoMeasureSelected=null,photoMeasureMode='horizontal',photoDrag=null,photoInk=false,photoStrokeActive=null;
function overlayFor(photo){if(!Array.isArray(photo.dimensions))photo.dimensions=[];return photo.dimensions;}
function photoMeasureView(){
 const p=project(),photo=p.photos.find(f=>f.id===photoMeasurePhoto)||p.photos[0];
 if(!photo)return '<div class="card"><h3>Medidas na foto</h3><p>Adicione uma foto na aba Fotos para começar.</p>'+btn('Abrir fotos','photoGoto')+'</div>';
 photoMeasurePhoto=photo.id;const dims=overlayFor(photo);
 const strokes=(photo.inkStrokes||[]).map(points=>'<polyline points="'+points.map(point=>point.x+','+point.y).join(' ')+'" fill="none" stroke="#197da5" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>').join('');
 const svg='<svg id="photoOverlay" viewBox="0 0 1000 650" preserveAspectRatio="none" aria-label="Linhas de medição">' +strokes+dims.map(d=>{
 const selected=d.id===photoMeasureSelected;
 return '<g data-dimension="'+escape(d.id)+'" class="dim-group'+(selected?' dim-selected':'')+'"><line x1="'+d.x1+'" y1="'+d.y1+'" x2="'+d.x2+'" y2="'+d.y2+'" stroke="#ffcc00" stroke-width="5"/><circle data-handle="a" cx="'+d.x1+'" cy="'+d.y1+'" r="15" fill="#ffd500" stroke="#635600" stroke-width="3"/><circle data-handle="b" cx="'+d.x2+'" cy="'+d.y2+'" r="15" fill="#ffd500" stroke="#635600" stroke-width="3"/><text x="'+(d.x1+d.x2)/2+'" y="'+((d.y1+d.y2)/2)-14+'" fill="#161616" stroke="#ffe300" stroke-width="8" paint-order="stroke" text-anchor="middle" font-size="31">'+escape(d.value?fmt(d.value)+' mm':'Toque para medir')+'</text></g>';
 }).join('')+'</svg>';
 return '<div class="card"><h3>Medidas sobre a fotografia</h3><p class="muted">Selecione uma seta, arraste as pontas amarelas para definir as referências e pressione MEDIR na Bosch. Quando chegar uma leitura compatível, ela ficará disponível para associar à seta selecionada.</p><div class="fields">'+select('measurePhoto','Fotografia',p.photos.map(x=>({id:x.id,name:x.name})),photo.id)+select('measureDirection','Nova seta',['Horizontal','Vertical'],'Horizontal')+'</div><div class="actions">'+btn('+ Nova seta','photoDimensionAdd','','primary')+btn('Conectar Bosch','bleScan')+btn('Aplicar última leitura','photoDimensionApply')+'</div><div class="photo-measure-stage"><img src="'+photo.data+'" alt="Foto da obra"><div class="photo-measure-svg">'+svg+'</div></div><p class="muted">Leitura BLE atual: <b id="photoBleLive">'+(lastBLE===null?'Aguardando trena':fmt(lastBLE)+' mm')+'</b>. Uma seta deve estar selecionada. Medidas em mm, não em metros.</p>'+dims.map(d=>'<div class="item"><div><strong>'+escape(d.label||'Medida')+' — '+(d.value?fmt(d.value)+' mm':'Sem medida')+'</strong><small>'+escape(d.source||'manual')+'</small></div><div class="actions">'+btn('Selecionar','photoDimensionSelect',d.id,'small')+btn('Excluir','photoDimensionDelete',d.id,'small danger')+'</div></div>').join('')+'<div class="fields">'+field('photoMeasureValue','Valor manual (mm)','number','','min="0" step="0.01"')+'</div>'+btn('Salvar valor manual','photoDimensionManual')+'</div>';
}
function photoOverlayCoords(ev,svg){const r=svg.getBoundingClientRect();return {x:Math.round(Math.max(0,Math.min(1000,(ev.clientX-r.left)/r.width*1000))),y:Math.round(Math.max(0,Math.min(650,(ev.clientY-r.top)/r.height*650)))};}
function applyPhotoValue(value,source,readingId){const p=project(),photo=p?.photos.find(x=>x.id===photoMeasurePhoto),d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!d)throw Error('Selecione uma seta amarela primeiro.');if(!Number.isFinite(Number(value))||Number(value)<=0)throw Error('Leitura inválida.');d.value=Number(value);d.source=source;d.readingId=readingId||null;d.date=new Date().toISOString();update();toast('Medida vinculada à seta selecionada.');}

function photoView(){const p=project();return `<div class="card"><h3>Fotos e referências da obra</h3><p class="muted">As fotos ficam salvas no armazenamento local do aplicativo, associadas ao projeto.</p>${btn('Abrir câmera','takePhoto','','primary')}${btn('Escolher da galeria','addPhoto')}<div class="field"><label for="photoCategory">Tipo da próxima foto</label><select id="photoCategory"><option>Levantamento</option><option>Rascunho</option><option>Referência</option><option>Produção</option><option>Projeto finalizado</option></select></div></div><div class="photo-grid">${p.photos.map(f=>`<div class="card"><img class="photo" src="${f.data}" alt="Foto da obra"><p><b>${escape(f.name)}</b></p><small>${escape(f.category||'Levantamento')} · ${escape(f.createdAt||'')}</small>${btn('Excluir','deletePhoto',f.id,'small danger')}</div>`).join('')}</div>${p.photos.length?'':'<div class="empty">Nenhuma foto anexada.</div>'}`;}
function drawView(){const r=room();return `<div class="card"><h3>Caderno técnico</h3><p class="muted">Desenhe com o dedo ou caneta do tablet. Os traços ficam associados ao ambiente.</p><div class="field"><label>Ambiente</label><select id="drawRoom">${project().rooms.map(x=>`<option value="${x.id}" ${x.id===selectedRoom?'selected':''}>${escape(x.name)}</option>`).join('')}</select></div>${r?`<div class="field"><label for="drawColor">Cor da caneta</label><select id="drawColor"><option value="#ffd329">Amarelo</option><option value="#171717">Preto</option><option value="#e23d3d">Vermelho</option><option value="#235ed7">Azul</option><option value="#288047">Verde</option></select></div><div class="canvas-wrap"><canvas class="draw" id="drawing" width="900" height="500"></canvas></div><div class="actions">${btn('Desfazer traço','undoStroke')}${btn('Limpar desenho','clearDrawing','','danger')}</div><div class="field"><label>Observação / referência</label><textarea id="noteText" placeholder="Ex.: tomada atrás da torre quente; conferir altura do sifão"></textarea></div>${btn('Salvar anotação','addNote','','primary')}${r.annotations.map(n=>`<div class="item"><div>${escape(n.text)}<small>${escape(n.date)}</small></div>${btn('Excluir','deleteNote',n.id,'small danger')}</div>`).join('')}`:'<div class="empty">Crie um ambiente na aba Medições antes de desenhar.</div>'}</div>`;}
function studioPages(p){ if(!Array.isArray(p.studioPages))p.studioPages=[];return p.studioPages; }
function studioCurrent(p){const pages=studioPages(p);if(!pages.length)return null;return pages.find(x=>x.id===studioPageId)||pages[0];}
function studioView(){const p=project(),pages=studioPages(p),page=studioCurrent(p);if(page)studioPageId=page.id;return `<div class="studio-hero"><div class="eyebrow">OFICINA DE IDEIAS / ${escape(p.name)}</div><h2>Ateliê Livre<span class="studio-star">✳</span></h2><p>Seu espaço para rascunhar móveis, registrar soluções e pensar com a S Pen. Cada página acompanha o projeto.</p><div class="studio-hero-actions">${btn('+ Nova página','studioNew','','primary')}${btn('Exportar página PNG','studioExport')}</div></div><div class="studio-layout"><aside class="studio-sidebar"><div class="eyebrow">PÁGINAS DO PROJETO · ${pages.length}</div>${pages.map((x,i)=>`<button class="studio-page ${page&&page.id===x.id?'on':''}" data-action="studioSelect" data-arg="${escape(x.id)}"><span class="studio-page-num">${String(i+1).padStart(2,'0')}</span><span>${escape(x.name)}</span><span>↗</span></button>`).join('')||'<div class="empty">Comece criando uma página.</div>'}<div class="studio-tip">Tudo fica salvo neste aparelho. Faça backup do projeto regularmente.</div></aside><div class="studio-work">${page?`<div class="studio-paper-head"><div><div class="eyebrow">FOLHA DE TRABALHO</div><strong>${escape(page.name)}</strong></div><span class="paper-status">● Salvo localmente</span></div><div class="studio-tools"><label>Ferramenta <select id="studioTool"><option value="pen" ${studioTool==='pen'?'selected':''}>Caneta</option><option value="eraser" ${studioTool==='eraser'?'selected':''}>Borracha</option></select></label><label>Cor <input type="color" id="studioColor" value="${studioInk}" aria-label="Cor da caneta"></label><label>Espessura <input type="range" min="1" max="16" id="studioWidth" value="${studioWidth}"></label><label>Fundo <select id="studioGrid"><option value="dots" ${studioGrid==='dots'?'selected':''}>Pontilhado</option><option value="lines" ${studioGrid==='lines'?'selected':''}>Linhas</option><option value="blank" ${studioGrid==='blank'?'selected':''}>Liso</option></select></label></div><div class="studio-canvas-shell"><canvas id="studioCanvas" width="1000" height="690" aria-label="Área livre de desenho"></canvas></div><div class="studio-actions">${btn('↶ Desfazer','studioUndo')}${btn('↷ Refazer','studioRedo')}${btn('Renomear','studioRename')}${btn('Excluir página','studioDelete','','danger')}</div><div class="field"><label for="studioText">Notas desta página</label><textarea id="studioText" placeholder="Ideias de montagem, cortes, ferragens, referências de materiais...">${escape(page.text||'')}</textarea></div>${btn('Salvar texto','studioSaveText','','primary')}`:'<div class="empty">Crie uma página para começar a desenhar livremente.</div>'}</div></div>`;}
function setupStudio(){const canvas=$('#studioCanvas'),p=project();if(!canvas||!p)return;const page=studioCurrent(p);if(!page)return;const ctx=canvas.getContext('2d');function paint(){ctx.fillStyle='#fffdf7';ctx.fillRect(0,0,canvas.width,canvas.height);ctx.strokeStyle='#dfdcd3';ctx.fillStyle='#d5cfc3';ctx.lineWidth=1;if(studioGrid==='dots'){for(let y=22;y<canvas.height;y+=25)for(let x=22;x<canvas.width;x+=25){ctx.beginPath();ctx.arc(x,y,0.8,0,7);ctx.fill();}}else if(studioGrid==='lines'){for(let y=25;y<canvas.height;y+=25){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(canvas.width,y);ctx.stroke()}}const all=[...(page.strokes||[]),...(studioActive?[{points:studioPoints,color:studioTool==='eraser'?'#fffdf7':studioInk,width:studioTool==='eraser'?28:studioWidth}]:[])];ctx.lineCap='round';ctx.lineJoin='round';for(const stroke of all){if(!stroke.points?.length)continue;ctx.beginPath();ctx.strokeStyle=stroke.color||'#151515';ctx.lineWidth=stroke.width||3;stroke.points.forEach(([x,y],i)=>i?ctx.lineTo(x,y):ctx.moveTo(x,y));if(stroke.points.length===1)ctx.lineTo(stroke.points[0][0]+0.1,stroke.points[0][1]);ctx.stroke();}}
 const coords=e=>{const b=canvas.getBoundingClientRect();return [(e.clientX-b.left)*canvas.width/b.width,(e.clientY-b.top)*canvas.height/b.height]};
 canvas.onpointerdown=e=>{e.preventDefault();studioActive=true;studioPoints=[coords(e)];canvas.setPointerCapture(e.pointerId);paint();};canvas.onpointermove=e=>{if(!studioActive)return;e.preventDefault();studioPoints.push(coords(e));paint()};canvas.onpointerup=async e=>{if(!studioActive)return;studioActive=false;(page.strokes||(page.strokes=[])).push({points:studioPoints.slice(),color:studioTool==='eraser'?'#fffdf7':studioInk,width:studioTool==='eraser'?28:studioWidth});page.undone=[];studioPoints=[];try{await persist()}catch(x){toast('Não foi possível salvar: '+x.message)}paint()};canvas.onpointercancel=()=>{studioActive=false;studioPoints=[];paint()};
 $('#studioTool').onchange=e=>studioTool=e.target.value;$('#studioColor').onchange=e=>studioInk=e.target.value;$('#studioWidth').oninput=e=>studioWidth=+e.target.value;$('#studioGrid').onchange=e=>{studioGrid=e.target.value;paint()};paint();}

function financeView(){const p=project(),f=C.finance(p);return `<div class="grid"><div class="card"><small class="muted">Contrato líquido</small><div class="stat">${money(f.net)}</div></div><div class="card"><small class="muted">Recebido</small><div class="stat">${money(f.paid)}</div></div><div class="card"><small class="muted">Saldo a receber</small><div class="stat">${money(f.balance)}</div></div></div><div class="card"><h3>Registrar pagamento</h3><div class="fields">${field('payamount','Valor (R$)','number','','min="0.01" step="0.01"')}${select('paymethod','Forma',['Pix','Dinheiro','Cartão','Transferência','Cheque','Boleto','Outro'])}${field('paydate','Data','date',new Date().toISOString().slice(0,10))}</div>${btn('Registrar recebimento','addPayment','','primary')}${p.payments.map(x=>`<div class="item"><div><strong>${money(x.amount)}</strong><small>${escape(x.method)} · ${escape(x.date)}</small></div>${btn('Excluir','deletePayment',x.id,'small danger')}</div>`).join('')}</div>`;}
function toolsView(){const p=project();if(!p)return header('Cálculos por obra','Escolha primeiro o cliente e a obra para que os cálculos sejam associados ao projeto.')+btn('Abrir clientes','go','clients','primary');return header('Cálculos da obra · '+escape(p.name),'Confira as medições do ambiente antes de usar os resultados na produção.')+`<div class="grid"><div class="card"><h3>Tomada por referências</h3><div class="fields">${field('tw','Largura parede (mm)','number',3500)}${field('tl','Esquerda → caixa (mm)','number',1210)}${field('tc','Largura caixa (mm)','number',80)}${field('tr','Caixa → direita (mm)','number',2210)}${field('tt','Tolerância fechamento (mm)','number',state.settings.tolerance)}</div>${btn('Calcular tomada','calcSocket','','primary')}<div id="socketResult"></div></div><div class="card"><h3>Alturas e desníveis</h3><div class="fields">${field('h1','Altura esquerda (mm)','number',2710)}${field('h2','Altura central (mm)','number',2706)}${field('h3','Altura direita (mm)','number',2702)}</div>${btn('Comparar alturas','calcHeights','','primary')}<div id="heightsResult"></div></div><div class="card"><h3>Carcaça abaixo da pedra</h3><div class="fields">${field('ct','Topo pedra (mm)','number',900)}${field('cs','Espessura pedra (mm)','number',30)}${field('cb','Rodapé/base (mm)','number',100)}${field('cc','Folga instalação (mm)','number',5)}</div>${btn('Calcular carcaça','calcCarcass','','primary')}<div id="carcassResult"></div></div><div class="card"><h3>Vão com paredes irregulares</h3><div class="fields">${field('v1','Largura baixa (mm)','number',2735)}${field('v2','Largura média (mm)','number',2728)}${field('v3','Largura alta (mm)','number',2731)}${field('vl','Folga esquerda (mm)','number',5)}${field('vr','Folga direita (mm)','number',5)}</div>${btn('Calcular vão','calcOpening','','primary')}<div id="openingResult"></div></div></div><div class="notice">A variação entre alturas piso-teto não identifica isoladamente se o desnível está no piso ou no teto. É preciso medir com uma referência de nível.</div>`;}
function transferView(){return header('Arque Link','Transfira um projeto completo entre dois Android usando a mesma rede Wi-Fi ou hotspot, sem internet.')+
 `<div class="card"><h3>Enviar projeto</h3><p>Abra o Arque Measure nos dois aparelhos. Ative um ponto de acesso ou conecte ambos ao mesmo Wi-Fi.</p>${state.projects.length?select('linkProject','Projeto para enviar',state.projects):'<p>Cadastre um projeto primeiro.</p>'}
 ${btn('Compartilhar projeto','linkShare','','primary')}${btn('Ativar anúncio Bluetooth','linkAdvertise')}${btn('Parar compartilhamento','linkStop')}
 <div class="notice">${linkInfo?`Endereço: <b>${escape(linkInfo.ip)}</b><br>Código de autorização (não compartilhe com estranhos):<br><b style="overflow-wrap:anywhere">${escape(linkInfo.code)}</b>`:'O endereço e o código aparecerão aqui após iniciar o envio.'}</div></div>
 <div class="card"><h3>Receber projeto</h3><p>Toque em procurar para encontrar outro Arque Measure próximo por Bluetooth. Ambos precisam estar na mesma rede local ou hotspot para transmitir o projeto.</p>${btn('Procurar aparelhos por Bluetooth','linkDiscover','','primary')}<div id="linkPeers">${linkPeers.map((x,i)=>`<div class="item"><div><strong>Aparelho encontrado ${i+1}</strong><small>Endereço local: ${escape(x.ip)}</small></div>${btn('Usar este aparelho','linkUsePeer',x.ip,'small')}</div>`).join('')||'<p class="muted">Nenhum aparelho localizado nesta busca.</p>'}</div>${field('linkIP','IP do telefone que está enviando','text','','placeholder="192.168.1.10"')}${field('linkCode','Código exibido no telefone de origem','text','','placeholder="32 caracteres"')}${btn('Buscar projeto e importar cópia','linkFetch','','primary')}<p class="muted">O sistema solicitará sua confirmação antes de salvar. Não apaga projetos anteriores.</p></div>
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
case'go':tab=arg;selectedProject=null;selectedClient=null;render();break;
case'contractAttach':{if(!selectedClient)throw Error('Abra um cliente.');const inp=$('#contractFile');inp.dataset.clientId=selectedClient;inp.dataset.projectId=val('contractProject');inp.click();break;}
case'contractOpen':{const c=state.clients.find(x=>x.id===selectedClient);const doc=c?.contracts?.find(x=>x.id===arg);if(!doc)throw Error('Documento não encontrado.');const link=document.createElement('a');link.href=doc.data;link.download=doc.name;document.body.append(link);link.click();link.remove();break;}
case'contractRemove':{const c=state.clients.find(x=>x.id===selectedClient);if(c?.contracts&&confirm('Excluir este contrato do cadastro?')){c.contracts=c.contracts.filter(x=>x.id!==arg);update();}break;}
case'openClient':selectedClient=arg;selectedProject=null;tab='clients';render();break;
case'closeClient':selectedClient=null;selectedProject=null;tab='clients';render();break;
case'projectCalc':tab='tools';render();break;
case'openWorkspace':subtab=arg;tab='projects';render();break;
case'addClient':{let c=C.client(val('cname'),val('cphone'),val('caddr'));state.clients.push(c);update();toast('Cliente salvo no aparelho.');break;}
case'clientProject':tab='projects';selectedProject=null;render();$('#pclient').value=arg;break;
case'addProject':{let x=C.project(val('pclient'),val('pname'),val('paddr'));state.projects.push(x);selectedProject=x.id;selectedClient=x.clientId;selectedRoom=null;subtab='resumo';update();toast('Projeto criado.');break;}
case'openProject':selectedProject=arg;selectedClient=project()?.clientId||null;tab='projects';selectedRoom=project()?.rooms[0]?.id||null;subtab='resumo';render();break;
case'closeProject':selectedProject=null;selectedRoom=null;tab='clients';render();break;
case'saveProject':{p.status=val('pstatus');p.value=C.money(val('pvalue'));p.discount=C.money(val('pdiscount'));C.finance(p);p.updatedAt=new Date().toISOString();p.revision++;update();toast('Projeto atualizado.');break;}
case'manualSimulate':{const plan=cuttingPlan(p);const chosen=plan.pieces.find(x=>x.id===val('manualPart'));if(!chosen)throw Error('Selecione uma peça.');const stock={width:Number(val('manualSheetW')),height:Number(val('manualSheetH')),kerf:Number(val('manualKerf')),trim:Number(val('manualTrim')),partId:chosen.id,qty:Number(val('manualQty'))};window.ArqueCut.manualGrid({...stock,partW:chosen.w,partH:chosen.h,grain:chosen.grain,rotate:chosen.rotate});plan.manualStock=stock;update();toast('Simulação manual atualizada.');break;}
case'cutSettings':{const plan=cuttingPlan(p);const updated={...plan,width:Number(val('cutWidth')),height:Number(val('cutHeight')),kerf:Number(val('cutKerf')),trim:Number(val('cutTrim'))};window.ArqueCut.calculate({...updated,pieces:[]});p.cutPlan=updated;update();toast('Chapa e serra configuradas.');break;}
case'cutAdd':{const plan=cuttingPlan(p);const piece={id:C.uid(),name:val('cutName').trim(),w:Number(val('cutW')),h:Number(val('cutH')),qty:Number(val('cutQty')),grain:val('cutGrain')==='Fixo',rotate:val('cutRotate')==='Sim',edge2:Number(val('cutEdge2')),edge04:Number(val('cutEdge04'))};if(!piece.name)throw Error('Informe o nome da peça.');window.ArqueCut.calculate({...plan,pieces:[piece]});plan.pieces.push(piece);update();toast('Peça adicionada ao plano.');break;}
case'cutRemove':{const plan=cuttingPlan(p);plan.pieces=plan.pieces.filter(x=>x.id!==arg);update();toast('Peça removida.');break;}
case'cutPrint':{window.print();break;}
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
case'photoGoto':subtab='fotos';render();break;
case'photoInkToggle':photoInk=!photoInk;render();break;
case'photoInkUndo':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(photo&&photo.inkStrokes?.length){photo.inkStrokes.pop();update();}break;}
case'photoDimensionAdd':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(!photo)throw Error('Selecione uma foto.');const vert=val('measureDirection')==='Vertical',d={id:C.uid(),label:'Medida '+(overlayFor(photo).length+1),x1:vert?500:200,y1:vert?140:330,x2:vert?500:800,y2:vert?500:330,value:null,source:'manual'};photo.dimensions.push(d);photoMeasureSelected=d.id;update();break;}
case'photoDimensionSelect':photoMeasureSelected=arg;render();break;
case'photoDimensionDelete':{const photo=p.photos.find(x=>x.id===photoMeasurePhoto);if(photo){photo.dimensions=overlayFor(photo).filter(x=>x.id!==arg);if(photoMeasureSelected===arg)photoMeasureSelected=null;update();}break;}
case'photoDimensionManual':applyPhotoValue(val('photoMeasureValue'),'manual');break;
case'photoDimensionApply':{if(!lastBleReceipt)throw Error('Nenhuma leitura da trena disponível.');applyPhotoValue(lastBleReceipt.value,'Bluetooth',lastBleReceipt.id);break;}
case'addPhoto':pendingPhotoCategory=val('photoCategory')||'Levantamento';$('#photoFile').click();break;
case'takePhoto':pendingPhotoCategory=val('photoCategory')||'Levantamento';$('#cameraFile').click();break;
case'testCamera':$('#diagCameraFile').click();break;
case'checkDevice':if(window.ArqueNative?.checkDevice){window.ArqueNative.checkDevice();}else{diagnostics={platform:'Navegador (simulação)',sdk:'—',cameraHardware:false,bleHardware:false,bluetoothEnabled:false,bluetoothPermission:false,freeMegabytes:'—'};render();toast('Diagnóstico nativo disponível no APK Android.');}break;
case'deletePhoto':if(confirm('Excluir foto?')){p.photos=p.photos.filter(x=>x.id!==arg);update();}break;
case'addNote':{let text=val('noteText').trim();if(!text)throw Error('Escreva a anotação.');r.annotations.push({id:C.uid(),text,date:new Date().toLocaleString('pt-BR')});update();break;}
case'deleteNote':r.annotations=r.annotations.filter(x=>x.id!==arg);update();break;
case'undoStroke':r.strokes.pop();update();break;
case'clearDrawing':if(confirm('Limpar todos os traços deste ambiente?')){r.strokes=[];update();}break;
case'studioNew':{const name=prompt('Título da nova página','Rascunho '+(studioPages(p).length+1));if(name===null)break;const pg={id:C.uid(),name:name.trim()||'Sem título',strokes:[],undone:[],text:'',createdAt:new Date().toISOString()};studioPages(p).push(pg);studioPageId=pg.id;update();break;}
case'studioSelect':studioPageId=arg;render();break;
case'studioRename':{const pg=studioCurrent(p);if(!pg)break;const name=prompt('Nome da página',pg.name);if(name===null)break;pg.name=name.trim()||pg.name;update();break;}
case'studioDelete':{const pg=studioCurrent(p);if(!pg||!confirm('Excluir esta página e seus desenhos?'))break;p.studioPages=p.studioPages.filter(x=>x.id!==pg.id);studioPageId=null;update();break;}
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
case'linkShare':{if(!window.ArqueNative?.linkStart)throw Error('Arque Link requer APK Android.');const payload=C.exportProject(state,val('linkProject'));window.ArqueNative.linkStart(JSON.stringify(payload));linkNotice='Iniciando compartilhamento…';render();break;}
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
async function receiveImport(text){const parsed=JSON.parse(text),newState=C.validateImport(parsed);if(!confirm('Substituir todos os dados deste aparelho pelos dados do backup?'))return;state=newState;await update();toast('Backup restaurado com sucesso.');}
window.ArqueLinkReady=raw=>{try{linkInfo=JSON.parse(raw);linkNotice='Compartilhamento ativado. Informe o endereço e o código no outro Android.';render();}catch(e){toast('Erro na autorização');}};
window.ArqueLinkEvent=(kind,value)=>{linkNotice=String(value).slice(0,250);if(tab==='transfer')render();if(kind==='error')toast('Arque Link: '+linkNotice);};
window.ArqueLinkReceive=async raw=>{try{
 const received=JSON.parse(raw);if(!confirm('Receber projeto "'+String(received.project?.name||'').slice(0,100)+'" de "'+String(received.client?.name||'').slice(0,100)+'"? Será salva uma cópia independente.'))return;
 const merged=C.mergeProject(state,received);const oldState=state;state=merged.state;
 try{await persist();}catch(e){state=oldState;throw e;}
 linkNotice='Projeto recebido, validado e salvo localmente.';selectedProject=merged.projectId;selectedRoom=null;tab='projects';render();toast('Projeto recebido com sucesso.');
 }catch(e){linkNotice='Falha ao importar: '+e.message;render();toast(linkNotice);}};
window.ArqueDiagnostics=raw=>{try{diagnostics=typeof raw==='string'?JSON.parse(raw):raw;render();}catch(e){toast('Diagnóstico inválido: '+e.message)}};
window.ArqueReceiveBackup=text=>receiveImport(text).catch(e=>toast('Falha na importação: '+e.message));
window.ArqueBleMeasure=millimeters=>{let n=Number(millimeters);if(!Number.isInteger(n)||n<50||n>50000)return;lastBLE=n;lastBleReceipt={id:C.uid(),value:n,date:new Date().toISOString()};bleReadings.push(lastBleReceipt);if(bleReadings.length>200)bleReadings.shift();const activeProject=project();if(activeProject){if(!Array.isArray(activeProject.bleReadings))activeProject.bleReadings=[];activeProject.bleReadings.push({...lastBleReceipt,roomId:selectedRoom});persist().catch(e=>toast('Falha ao salvar leitura da trena: '+e.message));}const el=$('#bleValue');if(el)el.textContent=fmt(n)+' mm';const inp=$('#mvalue');if(inp){inp.value=n;inp.dataset.readingId=lastBleReceipt.id;}const live=$('#photoBleLive');if(live)live.textContent=fmt(n)+' mm';toast('Leitura recebida: '+fmt(n)+' mm. Confira a referência.');};
window.ArqueBleStatus=status=>{const el=$('#connection');if(el)el.textContent=String(status).slice(0,70)};
window.ArqueBleDevices=devices=>{try{const list=JSON.parse(devices);if(!list.length)return;let msg=list.map((x,i)=>`${i+1}: ${x.name||'Trena BLE'} (${x.address})`).join('\n');let n=prompt('Selecione a trena:\n'+msg);let d=list[Number(n)-1];if(d)window.ArqueNative.connectBle(d.address);}catch(e){toast('Erro ao listar trenas: '+e.message)}};
$('#contractFile').addEventListener('change',async e=>{const file=e.target.files[0];const c=state.clients.find(x=>x.id===e.target.dataset.clientId);try{if(!file||!c)return;if(file.size>6*1024*1024)throw Error('Arquivo muito grande. Máximo de 6 MB por contrato.');if(!(['application/pdf','image/jpeg','image/png','image/webp'].includes(file.type)))throw Error('Aceita apenas PDF, JPG, PNG ou WebP.');const data=await new Promise((resolve,reject)=>{const r=new FileReader();r.onload=()=>resolve(r.result);r.onerror=()=>reject(Error('Erro na leitura'));r.readAsDataURL(file);});if(!Array.isArray(c.contracts))c.contracts=[];c.contracts.push({id:C.uid(),name:file.name.slice(0,120),type:file.type,size:file.size,data,projectId:e.target.dataset.projectId||'',date:new Date().toLocaleDateString('pt-BR')});await persist();render();toast('Contrato anexado ao cliente.');}catch(err){toast('Não foi possível anexar: '+err.message);}finally{e.target.value='';}});
$('#importFile').addEventListener('change',async e=>{try{let f=e.target.files[0];if(f)await receiveImport(await f.text());}catch(err){toast('Erro no backup: '+err.message)}e.target.value='';});
for(const fileInput of ['#photoFile','#cameraFile'])$(fileInput).addEventListener('change',async e=>{try{const f=e.target.files[0];if(!f)return;const img=await createImageBitmap(f);let ratio=Math.min(1,1600/Math.max(img.width,img.height)),can=document.createElement('canvas');can.width=Math.round(img.width*ratio);can.height=Math.round(img.height*ratio);can.getContext('2d').drawImage(img,0,0,can.width,can.height);project().photos.push({id:C.uid(),name:f.name.slice(0,100),data:can.toDataURL('image/jpeg',0.72),createdAt:new Date().toISOString(),category:pendingPhotoCategory});await update();toast('Foto salva no projeto.');}catch(err){toast('Falha ao salvar foto: '+err.message)}e.target.value='';});
$('#diagCameraFile').addEventListener('change',async e=>{const file=e.target.files[0];if(file){cameraCheck='Imagem recebida ('+Math.round(file.size/1024)+' KB)';render();toast('Imagem de teste recebida.');}e.target.value='';});
function setupDrawing(){const canvas=$('#drawing'),r=room();if(!canvas||!r)return;const ctx=canvas.getContext('2d');function repaint(){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#fff';ctx.fillRect(0,0,canvas.width,canvas.height);ctx.strokeStyle='#dae6dc';ctx.lineWidth=1;for(let x=0;x<canvas.width;x+=50){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,canvas.height);ctx.stroke()}for(let y=0;y<canvas.height;y+=50){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(canvas.width,y);ctx.stroke()}ctx.lineWidth=3;ctx.lineJoin='round';ctx.lineCap='round';for(const stored of [...r.strokes,...(drawActive?[{points:drawPoints,color:drawColor}]:[])]){const stroke=Array.isArray(stored)?stored:stored.points;if(!stroke?.length)continue;ctx.strokeStyle=stored.color||'#1c563b';ctx.beginPath();ctx.moveTo(stroke[0][0],stroke[0][1]);for(let i=1;i<stroke.length;i++)ctx.lineTo(stroke[i][0],stroke[i][1]);if(stroke.length===1)ctx.lineTo(stroke[0][0]+.01,stroke[0][1]);ctx.stroke()}}function point(e){const b=canvas.getBoundingClientRect();return [(e.clientX-b.left)*canvas.width/b.width,(e.clientY-b.top)*canvas.height/b.height].map(n=>Math.round(n*10)/10)}canvas.onpointerdown=e=>{drawActive=true;drawPoints=[point(e)];canvas.setPointerCapture(e.pointerId);repaint()};canvas.onpointermove=e=>{if(drawActive){drawPoints.push(point(e));repaint()}};canvas.onpointerup=async()=>{if(!drawActive)return;drawActive=false;if(drawPoints.length)r.strokes.push({points:drawPoints,color:drawColor});drawPoints=[];await persist();repaint()};canvas.onpointercancel=()=>{drawActive=false;drawPoints=[];repaint()};repaint();}
document.addEventListener('click',e=>{let b=e.target.closest('[data-action]');if(b){try{const out=action(b.dataset.action,b.dataset.arg);if(out?.catch)out.catch(x=>toast(x.message));}catch(err){toast(err.message)}return;}let t=e.target.closest('[data-tab]');if(t){if(tab!==t.dataset.tab)navigationHistory.push({tab,selectedClient,selectedProject,selectedRoom,subtab});tab=t.dataset.tab;selectedProject=null;render();window.scrollTo(0,0);return;}let s=e.target.closest('[data-subtab]');if(s){if(subtab!==s.dataset.subtab)navigationHistory.push({tab,selectedProject,selectedRoom,subtab});subtab=s.dataset.subtab;render();window.scrollTo(0,0);return;}let r=e.target.closest('[data-room]');if(r){if(selectedRoom!==r.dataset.room)navigationHistory.push({tab,selectedProject,selectedRoom,subtab});selectedRoom=r.dataset.room;render();window.scrollTo(0,0);return;}});
document.addEventListener('input',e=>{if(e.target.id==='mvalue')delete e.target.dataset.readingId;});
document.addEventListener('pointerdown',e=>{
 if(!photoInk || !e.target.closest('#photoOverlay'))return;
 const svg=$('#photoOverlay'),photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);
 if(!svg||!photo)return;
 if(!photo.inkStrokes)photo.inkStrokes=[];
 const points=[photoOverlayCoords(e,svg)];photo.inkStrokes.push(points);photoStrokeActive=points;
 svg.setPointerCapture(e.pointerId);e.preventDefault();e.stopImmediatePropagation();
},true);
document.addEventListener('pointermove',e=>{
 if(!photoStrokeActive)return;
 const svg=$('#photoOverlay');if(!svg)return;
 const point=photoOverlayCoords(e,svg);photoStrokeActive.push(point);
 let line=svg.querySelector('#livePhotoInk');
 if(!line){line=document.createElementNS('http://www.w3.org/2000/svg','polyline');line.id='livePhotoInk';line.setAttribute('fill','none');line.setAttribute('stroke','#197da5');line.setAttribute('stroke-width','5');line.setAttribute('stroke-linecap','round');svg.append(line);}
 line.setAttribute('points',photoStrokeActive.map(p=>p.x+','+p.y).join(' '));
 e.preventDefault();
},true);
document.addEventListener('pointerup',()=>{if(photoStrokeActive){photoStrokeActive=null;persist().catch(e=>toast(e.message));}},true);
document.addEventListener('pointerdown',e=>{const h=e.target.closest('[data-handle]');if(!h||!e.target.closest('#photoOverlay'))return;const g=h.closest('[data-dimension]');photoMeasureSelected=g.dataset.dimension;photoDrag=h.dataset.handle;h.setPointerCapture(e.pointerId);e.preventDefault();});
document.addEventListener('pointermove',e=>{if(!photoDrag)return;const svg=$('#photoOverlay');const photo=project()?.photos.find(x=>x.id===photoMeasurePhoto);const d=photo&&overlayFor(photo).find(x=>x.id===photoMeasureSelected);if(!svg||!d)return;const point=photoOverlayCoords(e,svg);if(photoDrag==='a'){d.x1=point.x;d.y1=point.y;}else{d.x2=point.x;d.y2=point.y;}const g=[...svg.querySelectorAll('[data-dimension]')].find(x=>x.dataset.dimension===d.id);if(g){const line=g.querySelector('line'),circles=g.querySelectorAll('circle'),txt=g.querySelector('text');line.setAttribute('x1',d.x1);line.setAttribute('y1',d.y1);line.setAttribute('x2',d.x2);line.setAttribute('y2',d.y2);circles[0].setAttribute('cx',d.x1);circles[0].setAttribute('cy',d.y1);circles[1].setAttribute('cx',d.x2);circles[1].setAttribute('cy',d.y2);txt.setAttribute('x',(d.x1+d.x2)/2);txt.setAttribute('y',(d.y1+d.y2)/2-14);}e.preventDefault();});
document.addEventListener('pointerup',()=>{if(photoDrag){photoDrag=null;persist().catch(e=>toast(e.message));}});
document.addEventListener('change',e=>{if(e.target.id==='measurePhoto'){photoMeasurePhoto=e.target.value;photoMeasureSelected=null;render();}if(e.target.id==='drawRoom'){selectedRoom=e.target.value;render()}if(e.target.id==='drawColor')drawColor=e.target.value});
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
