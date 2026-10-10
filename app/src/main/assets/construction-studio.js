/* Arque Studio de construção: catálogo autoral de módulos, miniaturas e inserção com referência.
   Apenas padrão de fluxo CAD, sem copiar bibliotecas/código/identidade visual de terceiros. */
(function(root,factory){const api=factory();if(typeof module==='object'&&module.exports)module.exports=api;root.ArqueStudio=api;})(typeof globalThis!=='undefined'?globalThis:this,function(){
'use strict';
const esc=s=>String(s??'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
const fmt=n=>Number(n||0).toLocaleString('pt-BR',{maximumFractionDigits:1});
const categories=['Todos','Inferiores','Aéreos','Torres','Cantos','Bancadas','Eletrodomésticos','Iluminação','Banheiros','Salas e painéis','Meus modelos','Favoritos'];
function sketch(p){
 const isModule=p.kind==='module'||p.kind==='corner45',door=Number(p.doors||0),shelf=Number(p.shelves||0);
 let lines='';
 if(p.kind==='corner45')lines='<path d="M17 21 L62 21 L80 39 L60 74 L17 74 Z" fill="#dde9ef" stroke="#5e8193" stroke-width="2"/><path d="M62 21 L80 39 L60 74" fill="none" stroke="#9b6a49" stroke-width="3"/>';
 else if(isModule){const parts=door>0?door:1;for(let i=1;i<parts;i++)lines+='<path d="M'+(17+i*63/parts)+' 20V79" stroke="#7f9cac" stroke-width="1.7"/>';
 if(door){lines+='<path d="M17 27H80" stroke="#8d775f" stroke-width="2.4"/>';}else for(let i=1;i<=Math.min(5,shelf);i++)lines+='<path d="M17 '+(20+i*59/(shelf+1))+'H80" stroke="#7e9fad" stroke-width="1.7"/>';}
 else if(p.kind==='led')lines='<path d="M12 48H90" stroke="#e6b660" stroke-width="5" stroke-linecap="round"/><path d="M12 43H90" stroke="#f5e1a4" stroke-width="3" stroke-linecap="round"/>';
 else if(p.kind==='appliance')lines='<rect x="22" y="22" width="56" height="48" rx="3" fill="#d9e5eb" stroke="#829aaa" stroke-width="2"/><rect x="29" y="29" width="42" height="29" rx="2" fill="#839ca8"/><circle cx="68" cy="65" r="3" fill="#52748a"/>';
 else lines='<rect x="12" y="35" width="78" height="33" fill="#b4c6cc" stroke="#71919f" stroke-width="2"/>';
 return '<svg viewBox="0 0 100 94" aria-hidden="true"><path d="M18 20H80V78H18Z" fill="'+(isModule?'#e1e8e5':'#f0f4f6')+'" stroke="#6f93a5" stroke-width="2"/>'+lines+'<path d="M17 79H80" stroke="#4a829d" stroke-width="2.5"/></svg>';
}
function templates(kitchen=[],saved=[]){
 const a=kitchen.map(p=>({...p,action:p.kind==='corner45'?'cornerCreate':'catalogPreset',arg:p.id}));
 const b=saved.map(t=>({id:t.id,label:t.name||'Meu módulo',group:'Meus modelos',kind:'module',
  w:t.spec?.width||0,d:t.spec?.depth||0,h:t.spec?.height||0,doors:t.spec?.doorCount||0,shelves:t.spec?.shelfCount||0,
  action:'catalogSaved',arg:t.id}));
 return a.concat(b);
}
function catalogHTML(items,category,search,favorites=[]){
 const q=String(search||'').trim().toLocaleLowerCase('pt-BR');
 const result=items.filter(p=>(category==='Todos'||(category==='Favoritos'?favorites.includes(p.id):p.group===category))&&
  (!q||(p.label+' '+p.group+' '+p.id).toLocaleLowerCase('pt-BR').includes(q)));
 return result.map(p=>{
  const favorite=favorites.includes(p.id);
  return '<div class="studio-preset" data-studio-label="'+esc((p.label+' '+p.group+' '+p.id).toLocaleLowerCase('pt-BR'))+'">'+
   '<button type="button" data-lab="'+esc(p.action)+'" data-arg="'+esc(p.arg)+'" class="studio-preset-insert">'+
   '<span class="studio-preset-graphic">'+sketch(p)+'</span><span class="studio-preset-info"><b>'+esc(p.label)+'</b><small>'+fmt(p.w)+' × '+fmt(p.d)+' × '+fmt(p.h)+' mm</small></span><span class="studio-plus" aria-hidden="true">＋</span></button>'+
   '<button type="button" data-lab="studioFavorite" data-arg="'+esc(p.id)+'" class="studio-fav '+(favorite?'on':'')+'" title="'+(favorite?'Retirar favorito':'Adicionar favorito')+'" aria-label="'+(favorite?'Retirar dos':'Adicionar aos')+' favoritos: '+esc(p.label)+'">'+(favorite?'★':'☆')+'</button></div>';
 }).join('')||'<div class="studio-empty">Nenhum módulo nesta categoria. Escolha outra família ou limpe a busca.</div>';
}
function rect(obj){
 const s=obj.moduleSpec||{},w=Number(obj.w)+Number(s.leftFiller||0)+Number(s.rightFiller||0);
 const d=Number(obj.d)+(s.back==='overlay'?Number(s.backThickness||0):0);
 return Number(obj.rotation||0)%180===90?{w:d,d:w}:{w,d};
}
function overlaps(a,x,y,b){
 const A=rect(a),B=rect(b),az=Number(a.z||0),bz=Number(b.z||0);
 return x<b.x+B.w-.01&&b.x<x+A.w-.01&&y<b.y+B.d-.01&&b.y<y+A.d-.01&&az<bz+Number(b.height||0)-.01&&bz<az+Number(a.height||0)-.01;
}
function check(layout,obj,x,y){
 const r=rect(obj);if(x<0||y<0||x+r.w>layout.width||y+r.d>layout.depth||Number(obj.z||0)+Number(obj.height||0)>layout.height)return false;
 if(obj.kind==='module'&&layout.items.some(b=>b.kind==='module'&&b.id!==obj.id&&overlaps(obj,x,y,b)))return false;
 return true;
}
function proposed(layout,obj,selectedId='',side='right',gap=3){
 const host=(layout.items||[]).find(i=>i.id===selectedId&&i.kind==='module'),r=rect(obj),p=host?rect(host):null;
 const c=[];
 if(host&&obj.kind==='module'){
  const sides=[side,'right','left','front','back'].filter((v,i,a)=>['right','left','front','back'].includes(v)&&a.indexOf(v)===i);
  for(const s of sides){
   if(s==='right')c.push({x:host.x+p.w+gap,y:host.y+p.d-r.d,side:s});
   if(s==='left')c.push({x:host.x-r.w-gap,y:host.y+p.d-r.d,side:s});
   if(s==='front')c.push({x:host.x,y:host.y+p.d+gap,side:s});
   if(s==='back')c.push({x:host.x,y:host.y-r.d-gap,side:s});
  }
 }
 // Fallback: scan the measured floor at a moderate grid step; never place outside or overlap modules.
 const step=100;
 for(let y=0;y<=layout.depth-r.d;y+=step)for(let x=0;x<=layout.width-r.w;x+=step)c.push({x,y,side:'livre'});
 for(const v of c){
  const x=Math.round(v.x*10)/10,y=Math.round(v.y*10)/10;
  if(check(layout,obj,x,y))return {x,y,side:v.side};
 }
 throw Error('Não há espaço livre para inserir este módulo. Ajuste o ambiente ou os móveis existentes.');
}
return {categories,templates,catalogHTML,proposed,check,rect,sketch};
});