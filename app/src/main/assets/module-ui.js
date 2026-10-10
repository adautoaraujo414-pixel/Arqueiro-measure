/* Controles compactos do catalogo paramétrico dentro do Laboratorio. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueModuleUI=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const M=()=>globalThis.ArqueModules;
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const mm=x=>Number(x).toLocaleString('pt-BR',{maximumFractionDigits:1});
const btn=(text,action,arg='')=>'<button type="button" data-lab="'+action+'" data-arg="'+esc(arg)+'">'+text+'</button>';
const fld=(id,label,val,type='number',extra='')=>'<label>'+label+'<input id="'+id+'" type="'+type+'" value="'+esc(val)+'" '+extra+'></label>';
const choice=(id,label,value,options)=>'<label>'+label+'<select id="'+id+'">'+options.map(o=>'<option value="'+esc(o[0])+'" '+(o[0]===value?'selected':'')+'>'+esc(o[1])+'</option>').join('')+'</select></label>';
const values=[
 ['width','Largura',150],['height','Altura do corpo',150],['depth','Profundidade do corpo',150],
 ['thickness','Espessura MDF estrutura',6],['backThickness','Espessura fundo',0],
 ['doorGap','Folga entre portas',0],['doorReveal','Folga externa portas',0],
 ['shelfInset','Recuo das prateleiras',0],['shelfClearance','Folga lateral prateleira',0],
 ['leftFiller','Tamponamento esquerdo',0],['rightFiller','Tamponamento direito',0]
];
const integers=[['doorCount','Quantidade de portas',0,8],['shelfCount','Prateleiras por vão',0,12]];
function panel(p,state,l,selected){
 if(!M())return '<p>Motor de módulos não carregado.</p>';
 const templates=M().templateLibrary(state||{});
 const item=l.items.find(i=>i.id===selected&&i.kind==='module'),groups=M().groupedCutRows(p,p.rooms.find(r=>p.labLayouts?.[r.id]===l)?.id||'');
 let h='<section class="lab-module-panel"><div class="lab-module-title"><h3>Biblioteca de módulos inteligentes</h3><small>Crie uma vez, salve e use em qualquer obra. Cada cópia é independente.</small></div>';
 h+='<div class="lab-module-pick">'+btn('＋ Criar armário base','moduleNew');
 h+=choice('moduleLibrary','Modelos salvos','',[['','Escolha um modelo'],...templates.map(t=>[t.id,t.name+' · '+t.spec.width+' × '+t.spec.height+' × '+t.spec.depth+' mm'])]);
 h+=btn('Inserir modelo na obra','moduleInsert')+'</div>';
 if(!item){h+='<p class="lab-fine">Selecione um armário na planta ou crie um novo para configurar portas, divisórias, material, espessura e lista de peças.</p></section>';return h;}
 let generated=null,error='';
 try{generated=M().parts(item.moduleSpec);}catch(e){error=e.message;}
 const s=item.moduleSpec;
 h+='<div class="lab-module-subtitle"><strong>'+esc(item.label)+'</strong><span>Peça no projeto · '+mm(item.w)+' × '+mm(item.height)+' × '+mm(item.d)+' mm</span></div>';
 h+='<div class="lab-module-grid">';
 h+=fld('modName','Nome do módulo',s.name,'text','maxlength="90"');
 for(const [key,label,min] of values)h+=fld('mod_'+key,label+' (mm)',s[key],'number','min="'+min+'" max="50000" step="0.1"');
 for(const [key,label,min,max] of integers)h+=fld('mod_'+key,label,s[key],'number','min="'+min+'" max="'+max+'" step="1"');
 for(const key of ['caseMaterial','frontMaterial','backMaterial'])h+=fld('mod_'+key,{caseMaterial:'Material do corpo',frontMaterial:'Material das portas',backMaterial:'Material do fundo'}[key],s[key],'text','maxlength="90"');
 h+=choice('mod_frontType','Puxador',s.frontType,[['cava','Cava (usinagem)'],['concha','Concha (ferragem)'],['sem','Sem puxador']]);
 h+=choice('mod_grainFront','Sentido do veio nas portas',String(!!s.grainFront),[['true','Fixo na altura'],['false','Livre para girar']]);
 h+='</div><p class="lab-fine">Largura e profundidade acima são da CARCAÇA. Os tamponamentos aumentam a largura instalada. Fundo aplicado aumenta a profundidade.</p>';
 h+='<div class="lab-module-buttons">'+btn('Aplicar medidas e recalcular','moduleApply')+btn('Duplicar nesta obra','moduleDuplicate')+btn('Salvar como modelo','moduleSaveTemplate')+'</div>';
 h+='<div class="lab-module-dividers"><h4>Divisórias verticais</h4><p>Posicionadas em porcentagem do vão interno. Ao alterar largura, mantêm a proporção; a espessura continua fixa.</p>';
 h+='<div class="lab-divider-add">'+fld('modDividerPct','Posição da divisória (%)',50,'number','min="1" max="99" step="0.1"')+btn('＋ Divisória','moduleAddDivider')+'</div>';
 h+=(s.vertical||[]).map((fraction,i)=>'<div class="lab-divider-line"><strong>Divisória '+(i+1)+'</strong><span>'+mm(fraction*100)+'% do vão</span>'+btn('Retirar','moduleRemoveDivider',String(i))+'</div>').join('')||'<p class="lab-fine">Sem divisórias internas; adicione uma central ou na posição que preferir.</p>';
 h+='</div>';
 if(error)h+='<p class="lab-warning">'+esc(error)+'</p>';
 if(generated){
  h+='<div class="lab-module-summary"><div><strong>'+generated.bays.length+'</strong><small>Vãos</small></div><div><strong>'+generated.parts.reduce((acc,r)=>acc+r.qty,0)+'</strong><small>Peças de corte</small></div><div><strong>'+mm(generated.installedWidth)+'</strong><small>Largura instalada (mm)</small></div><div><strong>'+mm(generated.installedDepth)+'</strong><small>Profundidade instalada (mm)</small></div></div>';
  h+='<details class="lab-module-cut" open><summary>Conferir lista técnica deste módulo</summary><div class="lab-table"><table><thead><tr><th>Peça</th><th>Qtde</th><th>Compr.</th><th>Larg.</th><th>Esp.</th><th>Material</th></tr></thead><tbody>';
  h+=generated.parts.map(part=>'<tr><td>'+esc(part.name)+'</td><td>'+part.qty+'</td><td>'+mm(part.w)+'</td><td>'+mm(part.h)+'</td><td>'+mm(part.thickness)+'</td><td>'+esc(part.material)+'</td></tr>').join('')+'</tbody></table></div>';
  h+=generated.warnings.map(w=>'<p class="lab-fine">⚠ '+esc(w)+'</p>').join('')+'</details>';
 }
 const materials=Object.keys(groups);
 if(materials.length){h+='<div class="lab-module-export"><h4>Enviar ao plano de corte</h4><p>Somente peças do mesmo material e espessura serão colocadas juntas na mesma chapa. Inclui todos os módulos do ambiente.</p>';
 h+=choice('modCutMaterial','Lote de material',materials[0],materials.map(k=>[k,k+' · '+groups[k].reduce((a,x)=>a+x.qty,0)+' peças']));
 h+=btn('Conferir e enviar lote','moduleCut')+'</div>';}
 h+='</section>';return h;
}
function act(action,ctx){
 const {p,room,l,state,selected,get,notify,onCut}=ctx,lib=M().templateLibrary(state),item=l.items.find(x=>x.id===selected),L=globalThis.ArqueLab;
 const val=id=>get(id)?.value??'';
 const result=(sel,skipRefresh=false)=>({handled:true,...(sel!==undefined?{selected:sel}:{}),skipRefresh});
 if(action==='moduleNew'||action==='moduleInsert'){
  const t=action==='moduleNew'?{id:null,version:1,spec:M().standard()}:lib.find(x=>x.id===val('moduleLibrary'));
  if(!t)throw Error('Selecione um modelo salvo na biblioteca.');
  const instance=M().instantiate(t,100,100);
  L.remember(l);l.items.push(instance);
  notify('Módulo inserido no ambiente. Ajuste as medidas antes do corte.');
  return result(instance.id);
 }
 if(!item||item.kind!=='module')throw Error('Selecione um módulo na planta para editar.');
 if(action==='moduleApply'){
  const updates={name:val('modName')};
  for(const [key] of values)updates[key]=val('mod_'+key);
  for(const [key] of integers)updates[key]=val('mod_'+key);
  for(const key of ['caseMaterial','frontMaterial','backMaterial'])updates[key]=val('mod_'+key);
  updates.frontType=val('mod_frontType');updates.grainFront=val('mod_grainFront')==='true';
  // Check every derived panel BEFORE mutating project state.
  M().parts({...item.moduleSpec,...updates});
  L.remember(l);M().regenerate(item,updates);
  item.refs={};notify('Todas as peças foram recalculadas e salvas.');
  return result(selected);
 }
 if(action==='moduleAddDivider'){
  const pct=Number(String(val('modDividerPct')).replace(',','.'));
  if(!Number.isFinite(pct)||pct<=0||pct>=100)throw Error('Informe uma posição entre 0 e 100%.');
  const candidate=M().addDivider(item.moduleSpec,pct/100);
  M().parts(candidate);
  L.remember(l);M().regenerate(item,{vertical:candidate.vertical});
  return result(selected);
 }
 if(action==='moduleRemoveDivider'){
  const index=Number(ctx.arg);const vertical=[...(item.moduleSpec.vertical||[])];
  if(!Number.isInteger(index)||index<0||index>=vertical.length)throw Error('Divisória não encontrada.');
  vertical.splice(index,1);M().parts({...item.moduleSpec,vertical});L.remember(l);
  M().regenerate(item,{vertical});return result(selected);
 }
 if(action==='moduleSaveTemplate'){
  const proposed=val('modName').trim();if(!proposed)throw Error('Informe o nome do modelo.');
  const tpl=M().saveTemplate(state,{...item.moduleSpec,name:proposed},proposed);
  item.templateId=tpl.id;item.templateVersion=tpl.version;
  notify('Modelo salvo na biblioteca geral. Outras obras poderão reutilizá-lo.');
  return result(selected);
 }
 if(action==='moduleDuplicate'){
  const instance=M().instantiate({id:item.templateId,version:item.templateVersion||1,spec:item.moduleSpec},item.x+100,item.y+100);
  L.remember(l);l.items.push(instance);notify('Cópia independente adicionada.');
  return result(instance.id);
 }
 if(action==='moduleCut'){
  const material=val('modCutMaterial'),groups=M().groupedCutRows(p,room.id);
  if(!groups[material]?.length)throw Error('Nenhuma peça para este lote.');
  onCut(room.id,material);return result(selected,true);
 }
 return {handled:false};
}
return {panel,act};
});