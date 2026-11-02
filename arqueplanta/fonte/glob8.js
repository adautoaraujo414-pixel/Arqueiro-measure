/* ===== desenho da planta da casa: um desenho só, duas saídas (SVG na tela e PDF vetorial) ===== */
function DW(){this.o=[]}
DW.prototype.L=function(a,b,c,d,s){this.o.push(['L',a,b,c,d,s||{}]);return this};
DW.prototype.P=function(p,s){if(p&&p.length>1)this.o.push(['P',p,s||{}]);return this};
DW.prototype.C=function(x,y,r,s){this.o.push(['C',x,y,r,s||{}]);return this};
DW.prototype.A=function(x,y,r,a0,a1,s){this.o.push(['A',x,y,r,a0,a1,s||{}]);return this};
DW.prototype.T=function(x,y,t,s){if(t!==''&&t!=null)this.o.push(['T',x,y,String(t),s||{}]);return this};
/* larguras da Helvetica (pra centralizar texto no PDF igual na tela) */
var HVW=[278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,556,556,333,500,278,556,500,722,500,500,500,334,260,334,584];
function hvBase(ch){var m='ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ',b='AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOooooooUUUUuuuuCcNnYyy',i=m.indexOf(ch);return i>=0?b[i]:ch}
function hvW(t,sz,b){var w=0;t=String(t);for(var i=0;i<t.length;i++){var c=hvBase(t[i]).charCodeAt(0);w+=c>=32&&c<127?HVW[c-32]:c===215||c===176||c===183||c===178||c===179?556:600}return w/1000*sz*(b?1.06:1)}
function dwEsc(t){return String(t).replace(/[&<>"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]})}
function dwSVG(dw,vb,W,H,bg){var f=function(v){return Math.round(v*100)/100},st=function(s){return ' stroke="'+(s.c||'#222')+'" stroke-width="'+f(s.w||1)+'"'+(s.d?' stroke-dasharray="'+s.d.map(f).join(' ')+'"':'')+' stroke-linecap="round" stroke-linejoin="round"'},h='<svg xmlns="http://www.w3.org/2000/svg" viewBox="'+vb.map(f).join(' ')+'"'+(W?' width="'+W+'" height="'+H+'"':'')+' style="display:block;max-width:100%'+(W?'':';width:100%;height:auto')+'">'+(bg?'<rect x="'+f(vb[0])+'" y="'+f(vb[1])+'" width="'+f(vb[2])+'" height="'+f(vb[3])+'" fill="'+bg+'"/>':'');
 dw.o.forEach(function(o){var s=o[o.length-1],op=s.op!=null?' opacity="'+s.op+'"':'';
  if(o[0]==='L')h+='<line x1="'+f(o[1])+'" y1="'+f(o[2])+'" x2="'+f(o[3])+'" y2="'+f(o[4])+'"'+st(s)+op+'/>';
  else if(o[0]==='P')h+='<'+(s.open?'polyline':'polygon')+' points="'+o[1].map(function(p){return f(p[0])+','+f(p[1])}).join(' ')+'" fill="'+(s.f||'none')+'"'+(s.c||!s.f?st(s):'')+op+'/>';
  else if(o[0]==='C')h+='<circle cx="'+f(o[1])+'" cy="'+f(o[2])+'" r="'+f(o[3])+'" fill="'+(s.f||'none')+'"'+(s.c||!s.f?st(s):'')+op+'/>';
  else if(o[0]==='A'){var x=o[1],y=o[2],r=o[3],a0=o[4],a1=o[5];h+='<path d="M'+f(x+r*Math.cos(a0))+' '+f(y+r*Math.sin(a0))+' A'+f(r)+' '+f(r)+' 0 '+(Math.abs(a1-a0)>Math.PI?1:0)+' '+(a1>a0?1:0)+' '+f(x+r*Math.cos(a1))+' '+f(y+r*Math.sin(a1))+'" fill="none"'+st(s)+op+'/>'}
  else if(o[0]==='T'){var sz=s.fs||10,an=s.al==='c'?'middle':s.al==='r'?'end':'start',tr=s.r?' transform="rotate('+f(s.r)+' '+f(o[1])+' '+f(o[2])+')"':'',dy=s.v==='m'?sz*.35:0;
   if(s.bg){var tw=hvW(o[3],sz,s.b),x0=s.al==='c'?o[1]-tw/2:s.al==='r'?o[1]-tw:o[1];h+='<rect x="'+f(x0-sz*.2)+'" y="'+f(o[2]+dy-sz*.85)+'" width="'+f(tw+sz*.4)+'" height="'+f(sz*1.1)+'" fill="'+s.bg+'"'+tr+'/>'}
   h+='<text x="'+f(o[1])+'" y="'+f(o[2]+dy)+'" font-size="'+f(sz)+'" font-family="Helvetica,Arial,sans-serif"'+(s.b?' font-weight="700"':'')+' fill="'+(s.c||'#222')+'" text-anchor="'+an+'"'+tr+op+'>'+dwEsc(o[3])+'</text>'}});
 return h+'</svg>'}
/* PDF vetorial (Helvetica, A4), sem bibliotecas */
function pdfTxt(t){var M={8211:150,8212:151,8216:145,8217:146,8220:147,8221:148,8226:149,8230:133,8364:128},o='';t=String(t);for(var i=0;i<t.length;i++){var c=t.charCodeAt(i);if(c===8776){o+='~';continue}if(c===8594){o+='->';continue}if(c>=55296&&c<=57343)continue;if(M[c])c=M[c];else if(c>255){continue}if(c===40||c===41||c===92)o+='\\'+String.fromCharCode(c);else if(c<32||c>126)o+='\\'+('00'+c.toString(8)).slice(-3);else o+=String.fromCharCode(c)}return o}
function pdfCol(h){if(!h||h[0]!=='#')h='#222222';if(h.length===4)h='#'+h[1]+h[1]+h[2]+h[2]+h[3]+h[3];return [parseInt(h.substr(1,2),16)/255,parseInt(h.substr(3,2),16)/255,parseInt(h.substr(5,2),16)/255]}
function pdfPage(P){var n=function(v){return (Math.round(v*1000)/1000).toString()},hp=P.h*72/25.4,o=['q 2.834646 0 0 -2.834646 0 '+n(hp)+' cm 1 J 1 j'],sc=function(c){var q=pdfCol(c);return n(q[0])+' '+n(q[1])+' '+n(q[2])},str=function(s){return sc(s.c||'#222222')+' RG '+n(s.w||.2)+' w ['+(s.d?s.d.map(n).join(' '):'')+'] 0 d'};
 var arc=function(x,y,r,a0,a1){var seg=Math.max(1,Math.ceil(Math.abs(a1-a0)/(Math.PI/2))),da=(a1-a0)/seg,out=n(x+r*Math.cos(a0))+' '+n(y+r*Math.sin(a0))+' m';for(var i=0;i<seg;i++){var b0=a0+da*i,b1=b0+da,k=4/3*Math.tan(da/4),p1=[x+r*(Math.cos(b0)-k*Math.sin(b0)),y+r*(Math.sin(b0)+k*Math.cos(b0))],p2=[x+r*(Math.cos(b1)+k*Math.sin(b1)),y+r*(Math.sin(b1)-k*Math.cos(b1))],p3=[x+r*Math.cos(b1),y+r*Math.sin(b1)];out+=' '+n(p1[0])+' '+n(p1[1])+' '+n(p2[0])+' '+n(p2[1])+' '+n(p3[0])+' '+n(p3[1])+' c'}return out};
 P.dw.o.forEach(function(op){var s=op[op.length-1];
  if(op[0]==='L')o.push(str(s)+' '+n(op[1])+' '+n(op[2])+' m '+n(op[3])+' '+n(op[4])+' l S');
  else if(op[0]==='P'){var pth=op[1].map(function(p,i){return n(p[0])+' '+n(p[1])+(i?' l':' m')}).join(' ')+(s.open?'':' h'),fl=s.f&&s.f!=='none';o.push((fl?sc(s.f)+' rg ':'')+(s.c||!fl?str(s)+' ':'')+pth+' '+(fl?(s.c?'B':'f'):'S'))}
  else if(op[0]==='C'){var fl2=s.f&&s.f!=='none';o.push((fl2?sc(s.f)+' rg ':'')+(s.c||!fl2?str(s)+' ':'')+arc(op[1],op[2],op[3],0,Math.PI*2)+' h '+(fl2?(s.c?'B':'f'):'S'))}
  else if(op[0]==='A')o.push(str(s)+' '+arc(op[1],op[2],op[3],op[4],op[5])+' S');
  else if(op[0]==='T'){var TT=window.arqueT?window.arqueT(op[3]):op[3],sz=s.fs||3,an=(s.r||0)*Math.PI/180,cs=Math.cos(an),sn=Math.sin(an),tw=hvW(TT,sz,s.b),dx=s.al==='c'?-tw/2:s.al==='r'?-tw:0,dy=s.v==='m'?sz*.35:0,x=op[1]+cs*dx-sn*dy,y=op[2]+sn*dx+cs*dy;
   if(s.bg){var bx=dx-sz*.2,by=dy-sz*.85,bw=tw+sz*.4,bh=sz*1.1,cn=[[bx,by],[bx+bw,by],[bx+bw,by+bh],[bx,by+bh]].map(function(q){return [op[1]+cs*q[0]-sn*q[1],op[2]+sn*q[0]+cs*q[1]]});o.push(sc(s.bg)+' rg '+cn.map(function(q,i){return n(q[0])+' '+n(q[1])+(i?' l':' m')}).join(' ')+' h f')}
   o.push('BT /'+(s.b?'F2':'F1')+' '+n(sz)+' Tf '+sc(s.c||'#222222')+' rg '+n(cs)+' '+n(sn)+' '+n(sn)+' '+n(-cs)+' '+n(x)+' '+n(y)+' Tm ('+pdfTxt(TT)+') Tj ET')}});
 o.push('Q');return o.join('\n')}
function dwPDF(pages){var objs=[],add=function(s){objs.push(s);return objs.length},cat=add(''),pg=add(''),f1=add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>'),f2=add('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>'),kids=[];
 pages.forEach(function(P){var c=pdfPage(P),cs=add('<< /Length '+c.length+' >>\nstream\n'+c+'\nendstream'),po=add('<< /Type /Page /Parent '+pg+' 0 R /MediaBox [0 0 '+(P.w*72/25.4).toFixed(2)+' '+(P.h*72/25.4).toFixed(2)+'] /Resources << /Font << /F1 '+f1+' 0 R /F2 '+f2+' 0 R >> >> /Contents '+cs+' 0 R >>');kids.push(po+' 0 R')});
 objs[cat-1]='<< /Type /Catalog /Pages '+pg+' 0 R >>';objs[pg-1]='<< /Type /Pages /Kids ['+kids.join(' ')+'] /Count '+kids.length+' >>';
 var out='%PDF-1.4\n%âãÏÓ\n',off=[];objs.forEach(function(s,i){off.push(out.length);out+=(i+1)+' 0 obj\n'+s+'\nendobj\n'});var xr=out.length;out+='xref\n0 '+(objs.length+1)+'\n0000000000 65535 f \n'+off.map(function(v){return ('0000000000'+v).slice(-10)+' 00000 n \n'}).join('')+'trailer\n<< /Size '+(objs.length+1)+' /Root '+cat+' 0 R >>\nstartxref\n'+xr+'\n%%EOF\n';
 return btoa(out)}
/* códigos das esquadrias: P (portas), J (janelas), V (vãos), iguais pro mesmo tamanho */
function cOpCodes(){var C=casa(),g={},rows=[],map={};C.O.slice().sort(function(a,b){return (a.k>b.k?1:a.k<b.k?-1:0)||a.l-b.l||a.h-b.h}).forEach(function(o){var pre=o.k==='janela'||o.k==='basc'?'J':o.k==='vao'?'V':'P',key=pre+'|'+o.k+'|'+o.l+'|'+o.h+'|'+(o.p||0);if(!g[key]){var n=rows.filter(function(r){return r.pre===pre}).length+1;g[key]={pre:pre,code:pre+n,k:o.k,l:o.l,h:o.h,p:o.p||0,q:0};rows.push(g[key])}g[key].q++;map[o.id]=g[key].code});return {map:map,rows:rows}}
/* ===== peças da parede na planta (cortada nas portas e janelas) ===== */
function cWallRange(w){var G=casaGeo(),fs=G.fs[w.id]||{L:[],R:[]},L=cLen(w),rg=function(sd){var a=fs[sd];if(!a||!a.length)return [0,L];var s0=1e18,s1=-1e18;a.forEach(function(q){s0=Math.min(s0,q.s0);s1=Math.max(s1,q.s1)});return [s0,s1]};return {L:rg('L'),R:rg('R'),len:L}}
function cWallFoot(w){var R=cWallRange(w),t=cT(w)/2,out=[],aL=R.L[0],aR=R.R[0],pc=function(a1,b1,a2,b2){if(b1-a1<1&&b2-a2<1)return;out.push([cAt(w,a1,t),cAt(w,Math.max(a1,b1),t),cAt(w,Math.max(a2,b2),-t),cAt(w,a2,-t)])};
 cOps(w).forEach(function(o){pc(aL,o.d,aR,o.d);aL=aR=o.d+o.l});pc(aL,R.L[1],aR,R.R[1]);return out}
/* ===== cota (linha de medida) ===== */
function cDim(dw,T,a,b,n,off,txt,o){o=o||{};var pt=T.pt,col=o.c||'#3b4350',A=T.P(a[0]+n[0]*off,a[1]+n[1]*off),B=T.P(b[0]+n[0]*off,b[1]+n[1]*off),a0=T.P(a[0],a[1]),b0=T.P(b[0],b[1]),dx=B[0]-A[0],dy=B[1]-A[1],L=Math.hypot(dx,dy);if(L<pt*2)return;var ux=dx/L,uy=dy/L,nx=-uy,ny=ux;
 var sd=(A[0]-a0[0])*nx+(A[1]-a0[1])*ny;if(sd<0){nx=-nx;ny=-ny}var ext=1.6*pt,lw=.45*pt;
 if(off){dw.L(a0[0]+nx*pt*1.2,a0[1]+ny*pt*1.2,A[0]+nx*ext,A[1]+ny*ext,{w:lw*.8,c:col});dw.L(b0[0]+nx*pt*1.2,b0[1]+ny*pt*1.2,B[0]+nx*ext,B[1]+ny*ext,{w:lw*.8,c:col})}
 dw.L(A[0]-ux*ext,A[1]-uy*ext,B[0]+ux*ext,B[1]+uy*ext,{w:lw,c:col});var tk=1.4*pt,tx=(ux+nx)*.7071*tk,ty=(uy+ny)*.7071*tk;dw.L(A[0]-tx,A[1]-ty,A[0]+tx,A[1]+ty,{w:lw*1.8,c:col});dw.L(B[0]-tx,B[1]-ty,B[0]+tx,B[1]+ty,{w:lw*1.8,c:col});
 var an=Math.atan2(uy,ux)*180/Math.PI;if(an>90.5)an-=180;if(an<=-89.5)an+=180;var sz=(o.fs||6.5)*pt,tw=hvW(txt,sz),m=[(A[0]+B[0])/2,(A[1]+B[1])/2],up=(off?1:-1)*pt*1.2,rad=an*Math.PI/180,txn=[Math.sin(rad),-Math.cos(rad)];
 if(tw>L*.95&&!o.force){m=[B[0]+ux*(tw/2+ext*1.5),B[1]+uy*(tw/2+ext*1.5)]}
 dw.T(m[0]+txn[0]*up,m[1]+txn[1]*up,txt,{fs:sz,al:'c',r:an,c:col,bg:o.bg})}
function cmT(mm){return cDec()===','?cN(mm/1000,2):cN(mm/1000,2)}
/* ===== a planta (tela e documentos) ===== */
/* T = {P:(x,z)->[X,Y] no papel, k: papel por mm, pt: papel por ponto tipográfico}; o.mode: edit | cot | lay | ele | luz | hid | base */
function cPlan(dw,T,o){o=o||{};var C=casa(),G=casaGeo(),R=casaRooms(),pt=T.pt,md=o.mode||'edit',ed=md==='edit',sel=o.sel||{},P=function(p){return T.P(p[0],p[1])},PP=function(L){return L.map(P)},WALL=ed?'#2f343b':'#2b2b2b',dimC='#3b4350';
 /* pisos */
 R.forEach(function(r){var fc='#ffffff';if(ed){var pf=cOf(CPISO,r.r.pf)||CPISO[1];fc=mixHex(pf[3],'#ffffff',.72)}else if(md==='cot'||md==='lay'){var nm=r.r.n.toLowerCase();fc=/banh|lavab|wc|cozinh|lavand|servi/.test(nm)?'#f1f4f6':'#ffffff'}
  dw.P(PP(r.pts),{f:sel.t==='r'&&sel.id===r.r.id?'#d8e6fb':fc,c:ed?'#b9bec6':'#d0d0d0',w:.25*pt})});
 /* móveis (layout) */
 if(ed||md==='lay')C.F.forEach(function(f){cMovPlan(dw,T,f,ed&&sel.t==='f'&&sel.id===f.id)});
 /* escadas */
 C.E.forEach(function(e){cEscPlan(dw,T,e,ed&&sel.t==='e'&&sel.id===e.id)});
 /* paredes */
 C.W.forEach(function(w){var sl=ed&&sel.t==='w'&&sel.id===w.id,fc=w.k==='vidro'?'#b9d6e6':w.k==='muro'?(ed?'#7c838c':'#6b6b6b'):w.k==='meia'?(ed?'#8f969f':'#8a8a8a'):WALL;cWallFoot(w).forEach(function(q){dw.P(PP(q),{f:sl?'#1f6feb':fc,c:sl?'#1f6feb':fc,w:.2*pt})})});
 /* portas, janelas e vãos */
 var OC=md==='cot'?cOpCodes():null;C.O.forEach(function(op){var w=cBy(C.W,op.w);if(w)cOpPlan(dw,T,w,op,{ed:ed,sel:ed&&sel.t==='o'&&sel.id===op.id,lab:md==='cot',code:OC?OC.map[op.id]:null})});
 /* pontos */
 if(ed||md==='ele'||md==='luz'||md==='hid')C.P.forEach(function(p){var D=cOf(CPT,p.k);if(!D)return;if(!ed&&D[2]!==md)return;cPtPlan(dw,T,p,D,ed&&sel.t==='p'&&sel.id===p.id,!ed)});
 /* nomes e áreas */
 R.forEach(function(r){var c=P([r.r.x,r.r.z]),nm=r.r.n,sz=(ed?8:7.5)*pt;var lines=[[nm,sz,1]];lines.push([cA(r.area),sz*.82,0]);if(md==='cot'||ed)lines.push(['PD '+cmT(r.ph),sz*.7,0]);if(md==='cot')lines.push(['Per. '+cM(r.per),sz*.7,0]);
  var y=c[1]-(lines.length-1)*sz*.6;lines.forEach(function(l){dw.T(c[0],y,l[0],{fs:l[1],al:'c',b:!!l[2],c:'#1b1f27',bg:ed?null:'#ffffff'});y+=l[1]*1.15})});
 /* cotas */
 if(o.dims!==false&&md!=='base'){var off1=(ed?16:7)*pt/T.k,off2=(ed?28:13)*pt/T.k;
  G.outs.forEach(function(ou){ou.ed.forEach(function(q){if(q.len<250)return;var w=q.w,u=cU(w),s0=(q.p0[0]-w.a[0])*u[0]+(q.p0[1]-w.a[1])*u[1],s1=(q.p1[0]-w.a[0])*u[0]+(q.p1[1]-w.a[1])*u[1],lo=Math.min(s0,s1),hi=Math.max(s0,s1),cuts=[lo];
   if(md==='cot')cOps(w).forEach(function(op){if(op.d>lo+1&&op.d<hi-1)cuts.push(op.d);if(op.d+op.l>lo+1&&op.d+op.l<hi-1)cuts.push(op.d+op.l)});cuts.push(hi);cuts.sort(function(a,b){return a-b});
   var sideOff=cT(w)/2*((q.sd==='L')?1:-1);if(cuts.length>2){for(var i=0;i<cuts.length-1;i++)if(cuts[i+1]-cuts[i]>20)cDim(dw,T,cAt(w,cuts[i],sideOff),cAt(w,cuts[i+1],sideOff),q.n,off1,cmT(cuts[i+1]-cuts[i]),{c:dimC,fs:5.6})}
   cDim(dw,T,q.p0,q.p1,q.n,cuts.length>2?off2:off1,cmT(q.len),{c:dimC})})});
  R.forEach(function(r){var sp=r.sp||r.pts;if(r.rect){var x0=r.bb[0],z0=r.bb[1],x1=r.bb[2],z1=r.bb[3],ins=(ed?14:6)*pt/T.k;if(x1-x0>400)cDim(dw,T,[x0,z0],[x1,z0],[0,1],ins,cmT(x1-x0),{c:'#2b6cb0',fs:6});if(z1-z0>400)cDim(dw,T,[x0,z0],[x0,z1],[1,0],ins,cmT(z1-z0),{c:'#2b6cb0',fs:6})}
   else for(var i=0;i<sp.length;i++){var a=sp[i],b=sp[(i+1)%sp.length],L=Math.hypot(b[0]-a[0],b[1]-a[1]);if(L<400)continue;var nI=[-(b[1]-a[1])/L,(b[0]-a[0])/L];if(!pIn([(a[0]+b[0])/2+nI[0]*50,(a[1]+b[1])/2+nI[1]*50],r.pts))nI=[-nI[0],-nI[1]];cDim(dw,T,a,b,nI,(ed?12:5)*pt/T.k,cmT(L),{c:'#2b6cb0',fs:6})}});
  if(md==='cot'){var bb=cBBox();if(bb){var off3=24*pt/T.k;cDim(dw,T,[bb[0],bb[1]],[bb[2],bb[1]],[0,-1],off3,cmT(bb[2]-bb[0]),{c:dimC,fs:7});cDim(dw,T,[bb[0],bb[1]],[bb[0],bb[3]],[-1,0],off3,cmT(bb[3]-bb[1]),{c:dimC,fs:7})}}}
 /* medidas feitas com 📏 Medir */
 if(md==='cot'||ed)C.Q.forEach(function(q){var a=cQPt(q.a),b=cQPt(q.b);if(!a||!b)return;var L=Math.hypot(b[0]-a[0],b[1]-a[1]);if(L<50)return;var n=[-(b[1]-a[1])/L,(b[0]-a[0])/L];cDim(dw,T,a,b,n,0,cmT(L),{c:'#c2410c',fs:6.5,bg:ed?'#fff7ed':null,force:1});if(ed&&sel.t==='q'&&sel.id===q.id)dw.L(P(a)[0],P(a)[1],P(b)[0],P(b)[1],{w:2.5*pt,c:'#f97316',op:.5})});
 return dw}
function mixHex(a,b,t){var A=pdfCol(a),B=pdfCol(b),h=function(v){return ('0'+Math.round(v*255).toString(16)).slice(-2)};return '#'+h(A[0]*(1-t)+B[0]*t)+h(A[1]*(1-t)+B[1]*t)+h(A[2]*(1-t)+B[2]*t)}
function cBBox(){var C=casa(),G=casaGeo(),x0=1e18,z0=1e18,x1=-1e18,z1=-1e18;(G.outs.length?G.outs.map(function(o){return o.pts}):C.W.map(function(w){return [w.a,w.b]})).forEach(function(L){L.forEach(function(p){x0=Math.min(x0,p[0]);x1=Math.max(x1,p[0]);z0=Math.min(z0,p[1]);z1=Math.max(z1,p[1])})});C.W.forEach(function(w){[w.a,w.b].forEach(function(p){var t=cT(w)/2;x0=Math.min(x0,p[0]-t);x1=Math.max(x1,p[0]+t);z0=Math.min(z0,p[1]-t);z1=Math.max(z1,p[1]+t)})});return x1>x0?[x0,z0,x1,z1]:null}
/* ponto de uma medida: preso numa parede (acompanha quando ela muda) ou solto */
function cQPt(r){if(!r)return null;if(r.w){var w=cBy(casa().W,r.w);if(!w)return null;var L=cLen(w);return cAt(w,Math.max(0,Math.min(1,r.s))*L,(r.o||0)*cT(w)/2)}return [r.x,r.z]}
function cOpPlan(dw,T,w,op,o){var pt=T.pt,t=cT(w)/2,P=function(p){return T.P(p[0],p[1])},col=o.sel?'#1f6feb':'#2b2b2b',lw=(o.sel?1.4:.7)*pt,u=cU(w),n=cNL(w),d=op.d,l=op.l,sd=op.sd<0?-1:1;
 /* batentes */
 [d,d+l].forEach(function(s){var a=P(cAt(w,s,t)),b=P(cAt(w,s,-t));dw.L(a[0],a[1],b[0],b[1],{w:.5*pt,c:'#2b2b2b'})});
 if(op.k==='janela'||op.k==='basc'){[t,-t,t*.22,-t*.22].forEach(function(of,i){var a=P(cAt(w,d,of)),b=P(cAt(w,d+l,of));dw.L(a[0],a[1],b[0],b[1],{w:i<2?.45*pt:lw,c:col})})}
 else if(op.k==='correr'){var a1=P(cAt(w,d,t*.25)),b1=P(cAt(w,d+l*.56,t*.25)),a2=P(cAt(w,d+l*.44,-t*.25)),b2=P(cAt(w,d+l,-t*.25));dw.L(a1[0],a1[1],b1[0],b1[1],{w:lw*1.6,c:col});dw.L(a2[0],a2[1],b2[0],b2[1],{w:lw*1.6,c:col})}
 else if(op.k==='vao'){var a=P(cAt(w,d,0)),b=P(cAt(w,d+l,0));dw.L(a[0],a[1],b[0],b[1],{w:.4*pt,c:'#777',d:[2*pt,1.5*pt]})}
 else{var leaf=function(sh,len,dir){var h=cAt(w,sh,sd*t),e=[h[0]+n[0]*sd*len,h[1]+n[1]*sd*len],cl=cAt(w,sh+dir*len,sd*t),H=P(h),E=P(e),Cl=P(cl);dw.L(H[0],H[1],E[0],E[1],{w:lw*1.4,c:col});var r=Math.hypot(E[0]-H[0],E[1]-H[1]),a0=Math.atan2(E[1]-H[1],E[0]-H[0]),a1=Math.atan2(Cl[1]-H[1],Cl[0]-H[0]),da=a1-a0;while(da>Math.PI)da-=2*Math.PI;while(da<-Math.PI)da+=2*Math.PI;dw.A(H[0],H[1],r,a0,a0+da,{w:.35*pt,c:col,d:[1.2*pt,.8*pt]})};
  if(op.k==='porta2'){leaf(d,l/2,1);leaf(d+l,l/2,-1)}else{var hg=op.hg?d+l:d;leaf(hg,l,op.hg?-1:1)}}
 if(o.code){var G=casaGeo(),fs=G.fs[w.id]||{L:[],R:[]},ins=(fs.L||[]).some(function(q){return q.r==='ext'})?1:(fs.R||[]).some(function(q){return q.r==='ext'})?-1:-sd,mc=P(cAt(w,d+l/2,ins*(t+4.2*pt/T.k)));dw.T(mc[0],mc[1],o.code,{fs:5.2*pt,al:'c',v:'m',b:1,c:'#1f4f8f',bg:'#ffffff'});return}
 if(o.lab||o.sel){var O=cOf(COPN,op.k)||COPN[0],m=P(cAt(w,d+l/2,-sd*(t+(op.k==='janela'||op.k==='basc'?5:9)*pt/T.k))),tx=(op.k==='janela'||op.k==='basc'?'J ':op.k==='vao'?'V ':'P ')+cCm(l)+'×'+cCm(op.h)+(op.p?' / '+cCm(op.p):''),an=Math.atan2(u[1],u[0])*180/Math.PI;if(an>90.5)an-=180;if(an<=-89.5)an+=180;dw.T(m[0],m[1],tx,{fs:5.4*pt,al:'c',v:'m',r:an,c:o.sel?'#1f6feb':'#444',bg:'#ffffff'})}}
function cPtPos(p){var C=casa();if(p.w){var w=cBy(C.W,p.w);if(!w)return null;var sd=p.s==='R'?-1:1;return cAt(w,p.d,sd*(cT(w)/2+60))}return [p.x,p.z]}
function cPtPlan(dw,T,p,D,sl,doc){var q=cPtPos(p);if(!q)return;var c=T.P(q[0],q[1]),pt=T.pt,r=2.6*pt,g=D[2],col=sl?'#1f6feb':g==='hid'?(p.k==='aq'?'#c0392b':p.k==='esg'||p.k==='ralo'||p.k==='vaso'?'#7a5230':p.k==='gas'?'#b7791f':'#1d6fb8'):g==='luz'?'#b7791f':'#c2410c';
 if(g==='luz'&&D[3]<0){dw.C(c[0],c[1],r*1.2,{f:'#ffffff',c:col,w:.6*pt});dw.L(c[0]-r*.85,c[1]-r*.85,c[0]+r*.85,c[1]+r*.85,{w:.5*pt,c:col});dw.L(c[0]-r*.85,c[1]+r*.85,c[0]+r*.85,c[1]-r*.85,{w:.5*pt,c:col})}
 else if(p.k==='ralo'||p.k==='vaso'){dw.P([[c[0]-r,c[1]-r],[c[0]+r,c[1]-r],[c[0]+r,c[1]+r],[c[0]-r,c[1]+r]],{f:'#ffffff',c:col,w:.6*pt});dw.L(c[0]-r,c[1]-r,c[0]+r,c[1]+r,{w:.4*pt,c:col})}
 else if(g==='ele'&&/^int/.test(p.k)){dw.C(c[0],c[1],r,{f:'#ffffff',c:col,w:.6*pt});dw.T(c[0],c[1],'S',{fs:3.6*pt,al:'c',v:'m',b:1,c:col})}
 else if(g==='ele'){dw.P([[c[0],c[1]-r*1.1],[c[0]+r,c[1]+r*.8],[c[0]-r,c[1]+r*.8]],{f:p.k==='tue'||p.k==='qd'?col:'#ffffff',c:col,w:.6*pt})}
 else dw.C(c[0],c[1],r,{f:'#ffffff',c:col,w:.7*pt});
 if(doc||sl){var lab=D[4]+(D[3]>0?' '+cmT(p.y!=null?p.y:D[3]).replace(/^0[,.]/,cDec()==','?'0,':'0.'):'');dw.T(c[0]+r*1.5,c[1]-r*.9,lab,{fs:4.4*pt,c:col,bg:'#ffffff'})}}
function cMovPlan(dw,T,f,sl){var M=cOf(CMOV,f.k)||[f.k,f.n||'',f.w,f.d],w=f.w||M[2],d=f.d||M[3],an=(f.r||0)*Math.PI/180,cs=Math.cos(an),sn=Math.sin(an),pt=T.pt,Q=function(x,z){return T.P(f.x+x*cs-z*sn,f.z+x*sn+z*cs)},R=function(x0,z0,x1,z1){return [Q(x0,z0),Q(x1,z0),Q(x1,z1),Q(x0,z1)]},st={f:sl?'#d8e6fb':'#ffffff',c:sl?'#1f6feb':'#555',w:.5*pt},st2={c:sl?'#1f6feb':'#777',w:.35*pt};
 dw.P(R(-w/2,-d/2,w/2,d/2),st);
 if(/^cama/.test(f.k)){var pw=f.k==='cama2'?w/2-80:w-160;dw.P(R(-w/2+40,-d/2+40,-w/2+40+pw,-d/2+260),st2);if(f.k==='cama2')dw.P(R(w/2-40-pw,-d/2+40,w/2-40,-d/2+260),st2);dw.L.apply(dw,Q(-w/2,-d/2+420).concat(Q(w/2,-d/2+420)).concat([st2]))}
 else if(f.k==='sofa'||f.k==='pol'){dw.P(R(-w/2,-d/2,w/2,-d/2+200),st2);dw.P(R(-w/2,-d/2+200,-w/2+180,d/2),st2);dw.P(R(w/2-180,-d/2+200,w/2,d/2),st2)}
 else if(f.k==='vaso'){var c=Q(0,d/2-230),r=T.k*190;dw.P(R(-w/2,-d/2,w/2,-d/2+180),st2);dw.C(c[0],c[1],r,st2)}
 else if(f.k==='fog'){[[-1,-1],[1,-1],[-1,1],[1,1]].forEach(function(s){var c=Q(s[0]*w/4.5,s[1]*d/5);dw.C(c[0],c[1],T.k*90,st2)})}
 else if(f.k==='banc'||f.k==='lav'||f.k==='tanq'){var c2=Q(0,0);dw.P(R(-Math.min(w*.3,300),-d/2+80,Math.min(w*.3,300),d/2-80),st2)}
 else if(f.k==='gr'||f.k==='arm'){dw.L.apply(dw,Q(-w/2,d/2-60).concat(Q(w/2,d/2-60)).concat([st2]))}
 else if(f.k==='carro'){dw.P(R(-w/2+60,-d/2+500,w/2-60,-d/2+1400),st2);dw.P(R(-w/2+60,d/2-1200,w/2-60,d/2-500),st2)}
 else if(f.k==='box'){dw.L.apply(dw,Q(-w/2,-d/2).concat(Q(w/2,d/2)).concat([st2]))}
 var c=Q(0,0);if(w*T.k>12*pt&&d*T.k>6*pt)dw.T(c[0],c[1],f.n||M[1],{fs:Math.min(5.2*pt,w*T.k/7),al:'c',v:'m',c:sl?'#1f6feb':'#555'})}
function cEscPlan(dw,T,e,sl){var w=e.w||900,l=e.l||3000,n=Math.max(2,e.n||Math.round((e.h||2800)/175)),an=(e.r||0)*Math.PI/180,cs=Math.cos(an),sn=Math.sin(an),pt=T.pt,Q=function(x,z){return T.P(e.x+x*cs-z*sn,e.z+x*sn+z*cs)},col=sl?'#1f6feb':'#444';
 dw.P([Q(-w/2,-l/2),Q(w/2,-l/2),Q(w/2,l/2),Q(-w/2,l/2)],{f:sl?'#d8e6fb':'#ffffff',c:col,w:.6*pt});for(var i=1;i<n;i++){var z=-l/2+l*i/n,a=Q(-w/2,z),b=Q(w/2,z);dw.L(a[0],a[1],b[0],b[1],{w:.35*pt,c:col})}
 var a0=Q(0,l/2-100),a1=Q(0,-l/2+150),ar1=Q(-w/6,-l/2+380),ar2=Q(w/6,-l/2+380);dw.L(a0[0],a0[1],a1[0],a1[1],{w:.5*pt,c:col});dw.L(a1[0],a1[1],ar1[0],ar1[1],{w:.5*pt,c:col});dw.L(a1[0],a1[1],ar2[0],ar2[1],{w:.5*pt,c:col});var t=Q(0,l/2-300);dw.T(t[0],t[1],'SOBE',{fs:4.4*pt,al:'c',c:col,bg:'#ffffff'})}
/* ===== documentos (pranchas em PDF) ===== */
var CDOCS=[['cot','Planta baixa cotada'],['lay','Planta de layout e mobiliário'],['ele','Planta de pontos elétricos'],['luz','Planta de iluminação'],['hid','Planta de pontos hidráulicos'],['elev','Elevações das paredes'],['cort','Cortes esquemáticos'],['area','Quadro de áreas'],['quant','Relatório de quantitativos']];
function casaTitle(){try{var p=CUR&&pLoadAll().filter(function(q){return q.id===CUR})[0];if(p&&p.client&&p.client.nome)return p.client.nome+(p.client.cidade?' · '+p.client.cidade:'')}catch(_){}return 'Projeto da casa'}
function casaCompany(){try{return String(window.ArqueApp&&ArqueApp.companyName?ArqueApp.companyName():'')}catch(_){return ''}}
var CDISC='Desenho de estudo e documentação gerado no Arquemestre. Não é projeto executivo: estrutura, instalações elétricas e hidráulicas, conformidade com as normas técnicas e aprovação na prefeitura exigem projeto e responsabilidade técnica de profissional habilitado (CREA/CAU). Quantitativos são estimativas.';
function dwWrap(t,mw,sz,b){var ws=String(t).split(' '),L=[],cur='';ws.forEach(function(w){var tt=cur?cur+' '+w:w;if(hvW(tt,sz,b)>mw&&cur){L.push(cur);cur=w}else cur=tt});if(cur)L.push(cur);return L}
/* moldura e carimbo de cada prancha (A4 deitada: 297 × 210 mm) */
function cFrame(dw,pg,tot,title,scale){var W=297,H=210,pt=.3528,c='#222';dw.P([[8,8],[W-8,8],[W-8,H-8],[8,H-8]],{c:c,w:.5});dw.L(8,H-34,W-8,H-34,{w:.35,c:c});dw.L(W-108,H-34,W-108,H-8,{w:.35,c:c});
 var co=casaCompany(),y=H-27.5;dw.T(W-104,y,co||'Arquemestre',{fs:3.6,b:1,c:c});dw.T(W-104,y+5,casaTitle(),{fs:3,c:c});dw.T(W-104,y+10,title,{fs:3.2,b:1,c:c});var d=new Date(),pd=function(n){return (n<10?'0':'')+n};dw.T(W-104,y+15,(scale?'Escala 1:'+scale+'   ·   ':'')+pd(d.getDate())+'/'+pd(d.getMonth()+1)+'/'+d.getFullYear(),{fs:2.7,c:c});dw.T(W-12,y+15,'Folha '+pg+'/'+tot,{fs:2.7,c:c,al:'r'});
 dwWrap(CDISC,W-130,2.4).forEach(function(l,i){dw.T(12,H-28.5+i*3.2,l,{fs:2.4,c:'#444'})});
 if(scale){var bx=12,by=H-12,u=1000/scale;dw.T(bx,by-2.2,'0',{fs:2.2,c:c});for(var i=0;i<5;i++)dw.P([[bx+i*u,by-1.2],[bx+(i+1)*u,by-1.2],[bx+(i+1)*u,by],[bx+i*u,by]],{f:i%2?'#ffffff':'#222222',c:c,w:.2});dw.T(bx+5*u,by-2.2,'5 m',{fs:2.2,c:c,al:'c'})}}
function cFit(bw,bh,aw,ah){var SC=[20,25,50,75,100,125,150,200,250,300,400,500];for(var i=0;i<SC.length;i++)if(bw/SC[i]<=aw&&bh/SC[i]<=ah)return SC[i];return 500}
function casaDocPages(keys){var C=casa(),pages=[],bb=cBBox(),tot=0,add=function(fn){pages.push(fn)};keys=keys||CDOCS.map(function(d){return d[0]});
 var planPage=function(md,title){return function(i,n){var dw=new DW(),A=md==='cot'&&casa().O.length?[14,14,269-80,156]:[14,14,269,156];if(!bb)return {w:297,h:210,dw:dw};var pad=md==='cot'?3000:2000,sc=cFit(bb[2]-bb[0]+pad,bb[3]-bb[1]+pad,A[2],A[3]),cx=(bb[0]+bb[2])/2,cz=(bb[1]+bb[3])/2,T={P:function(x,z){return [A[0]+A[2]/2+(x-cx)/sc,A[1]+A[3]/2+(z-cz)/sc]},k:1/sc,pt:.3528};
  cPlan(dw,T,{mode:md});if(md==='cot'){cSecMarks(dw,T,bb);cOpTable(dw,[14,14,269,156])}if(md==='ele'||md==='luz'||md==='hid')cLegend(dw,md,A);cFrame(dw,i,n,title,sc);return {w:297,h:210,dw:dw}}};
 keys.forEach(function(k){var D=cOf(CDOCS,k);if(!D)return;if(k==='elev'){cElevPages(D[1]).forEach(add);return}if(k==='cort'){add(function(i,n){var dw=new DW();cSections(dw);cFrame(dw,i,n,D[1],dw.sc);return {w:297,h:210,dw:dw}});return}
  if(k==='area'){add(function(i,n){var dw=new DW();cAreaTable(dw);cFrame(dw,i,n,D[1],0);return {w:297,h:210,dw:dw}});return}
  if(k==='quant'){cQuantPages(D[1]).forEach(add);return}add(planPage(k,D[1]))});
 var n=pages.length;return pages.map(function(f,i){return f(i+1,n)})}
function cLegend(dw,md,A){var C=casa(),cnt={};C.P.forEach(function(p){cnt[p.k]=(cnt[p.k]||0)+1});var L=CPT.filter(function(d){return d[2]===md}),x=A[0]+A[2]-62,y=A[1]+2,T={P:function(a,b){return [a,b]},k:1,pt:.3528};dw.P([[x-3,y-4],[x+62,y-4],[x+62,y+4+L.length*5.2],[x-3,y+4+L.length*5.2]],{f:'#ffffff',c:'#999',w:.25});dw.T(x,y+.5,'Legenda',{fs:3,b:1});
 L.forEach(function(d,i){var yy=y+6+i*5.2;cPtPlan(dw,T,{k:d[0],x:x+2.5,z:yy-1},d,false,false);dw.T(x+7,yy,d[1]+(d[3]>0?' (h '+cmT(d[3])+' m)':'')+' — '+(cnt[d[0]]||0),{fs:2.6})})}
function cSecMarks(dw,T,bb){var cz=cSecAt(bb,0),cx=cSecAt(bb,1),ext=900,pt=T.pt;[[[bb[0]-ext,cz],[bb[2]+ext,cz],'A',[0,-1]],[[cx,bb[1]-ext],[cx,bb[3]+ext],'B',[-1,0]]].forEach(function(s){var a=T.P(s[0][0],s[0][1]),b=T.P(s[1][0],s[1][1]);dw.L(a[0],a[1],b[0],b[1],{w:.35,c:'#b91c1c',d:[3,1,.6,1]});[a,b].forEach(function(p){dw.C(p[0],p[1],2.4,{f:'#ffffff',c:'#b91c1c',w:.35});dw.T(p[0],p[1],s[2],{fs:3,b:1,al:'c',v:'m',c:'#b91c1c'})})})}
/* elevações: cada face de parede de cada ambiente, vista de dentro */
function cElevList(){var R=casaRooms(),L=[];R.forEach(function(r){r.ed.forEach(function(q,i){if(q.len<300)return;L.push({r:r,q:q,i:i})})});return L}
function cElevDraw(dw,E,box,sc){var w=E.q.w,H=cH(w),f=[-E.q.n[0],-E.q.n[1]],rt=[-f[1],f[0]],pr=function(p){return p[0]*rt[0]+p[1]*rt[1]},a=pr(E.q.p0),b=pr(E.q.p1),x0=Math.min(a,b),x1=Math.max(a,b),u=cU(w),X=function(v){return box[0]+(v-x0)/sc},Y=function(y){return box[1]+box[3]-y/sc},pt=.3528,C=casa(),fin=cFace(w,E.q.sd),fl=cOf(CFIN,fin.f);
 dw.P([[X(x0),Y(0)],[X(x1),Y(0)],[X(x1),Y(H)],[X(x0),Y(H)]],{f:fin.f==='rev'?'#f3f4f2':'#ffffff',c:'#222',w:.5});
 if(fin.f==='rev'&&fin.rh>0&&fin.rh<H)dw.L(X(x0),Y(fin.rh),X(x1),Y(fin.rh),{w:.25,c:'#666',d:[1.5,1]});
 dw.L(X(x0)-4,Y(0),X(x1)+4,Y(0),{w:.7,c:'#222'});
 var chain=[x0];cOps(w).forEach(function(o){var pa=pr(cAt(w,o.d,0)),pb=pr(cAt(w,o.d+o.l,0)),oa=Math.max(x0,Math.min(pa,pb)),ob=Math.min(x1,Math.max(pa,pb));if(ob-oa<20)return;chain.push(oa,ob);
  dw.P([[X(oa),Y(o.p)],[X(ob),Y(o.p)],[X(ob),Y(o.p+o.h)],[X(oa),Y(o.p+o.h)]],{f:o.k==='janela'||o.k==='basc'?'#e3f0f7':'#f7f3ec',c:'#333',w:.4});
  if(o.k==='janela'||o.k==='basc'){dw.L(X((oa+ob)/2),Y(o.p),X((oa+ob)/2),Y(o.p+o.h),{w:.25,c:'#555'})}else if(o.k!=='vao'){var hl=o.hg?ob:oa,hr=o.hg?oa:ob;dw.L(X(hr),Y(o.p),X(hl),Y(o.p+o.h/2),{w:.2,c:'#888',d:[1,.8]});dw.L(X(hl),Y(o.p+o.h/2),X(hr),Y(o.p+o.h),{w:.2,c:'#888',d:[1,.8]})}
  var T0={P:function(x,y){return [X(x),Y(y)]},k:1/sc,pt:pt};if(o.p>0)cDim(dw,T0,[ob,0],[ob,o.p],[1,0],0,cmT(o.p),{fs:5});cDim(dw,T0,[ob,o.p],[ob,o.p+o.h],[1,0],0,cmT(o.h),{fs:5})});
 chain.push(x1);chain.sort(function(p,q){return p-q});var T={P:function(x,y){return [X(x),Y(y)]},k:1/sc,pt:pt};
 for(var i=0;i<chain.length-1;i++)if(chain[i+1]-chain[i]>20)cDim(dw,T,[chain[i],0],[chain[i+1],0],[0,-1],5*sc,cmT(chain[i+1]-chain[i]),{fs:5.2});
 cDim(dw,T,[x0,0],[x1,0],[0,-1],11*sc,cmT(x1-x0),{fs:6});cDim(dw,T,[x0,0],[x0,H],[-1,0],6*sc,cmT(H),{fs:6});
 C.P.forEach(function(p){if(p.w!==w.id||(p.s||'L')!==E.q.sd)return;var D=cOf(CPT,p.k);if(!D||D[3]<=0)return;var xp=pr(cAt(w,p.d,0)),y=p.y!=null?p.y:D[3];if(xp<x0||xp>x1)return;var c=[X(xp),Y(y)];dw.P([[c[0]-1.4,c[1]-1.4],[c[0]+1.4,c[1]-1.4],[c[0]+1.4,c[1]+1.4],[c[0]-1.4,c[1]+1.4]],{f:'#ffffff',c:D[2]==='hid'?'#1d6fb8':D[2]==='luz'?'#b7791f':'#c2410c',w:.35});dw.T(c[0]+2.2,c[1]+1,D[4]+' '+cmT(y),{fs:2.3,c:'#444'})});
 dw.T(box[0],box[1]-3,E.r.r.n+' — parede '+(casa().W.indexOf(w)+1)+' · '+(fl?fl[1]:'')+(fin.f==='pin'?' ('+((cOf(CPAINT,fin.c)||['',fin.c])[1])+')':fin.f==='rev'?' ('+((cOf(CREV,fin.rv)||['',''])[1])+(fin.rh>0?' até '+cmT(fin.rh)+' m':'')+')':''),{fs:3,b:1})}
function cElevPages(title){var L=cElevList(),out=[],per=2;for(var i=0;i<L.length;i+=per)(function(chunk){out.push(function(pg,n){var dw=new DW(),maxL=0,maxH=0;chunk.forEach(function(E){maxL=Math.max(maxL,E.q.len);maxH=Math.max(maxH,cH(E.q.w))});var sc=cFit(maxL+1200,maxH+900,250,64);
  chunk.forEach(function(E,j){cElevDraw(dw,E,[30,22+j*76,250,maxH/sc],sc)});cFrame(dw,pg,n,title,sc);return {w:297,h:210,dw:dw}})})(L.slice(i,i+per));if(!out.length)out.push(function(pg,n){var dw=new DW();dw.T(20,40,'Sem ambientes fechados ainda.',{fs:4});cFrame(dw,pg,n,title,0);return {w:297,h:210,dw:dw}});return out}
/* cortes A (deitado, olhando pro fundo) e B (em pé, olhando pra esquerda) */
function cSections(dw){var bb=cBBox();if(!bb){dw.sc=0;return}var C=casa(),R=casaRooms(),maxH=0;C.W.forEach(function(w){maxH=Math.max(maxH,cH(w))});var rf=C.cfg.roof,rh=rf.k==='2a'||rf.k==='4a'?(Math.min(bb[2]-bb[0],bb[3]-bb[1])/2+rf.bei)*rf.inc/100:rf.k==='laje'?120:0,span=Math.max(bb[2]-bb[0],bb[3]-bb[1])+2400,sc=cFit(span,(maxH+rh+900)*2+3000,265,150);dw.sc=sc;
 [['A',0,cSecAt(bb,0)],['B',1,cSecAt(bb,1)]].forEach(function(S2,si){var ax=S2[1],cut=S2[2],lo=ax?bb[1]:bb[0],hi=ax?bb[3]:bb[2],base=[22,20+si*76],X=function(v){return base[0]+(v-lo+1200)/sc},Y=function(y){return base[1]+(maxH+rh+400)/sc-y/sc},hits=[];
  C.W.forEach(function(w){var u=cU(w),along=ax?u[1]:u[0],cr=ax?u[0]:u[1];if(Math.abs(cr)<.35)return;var r=segX(w.a,w.b,ax?[cut,lo-1e5]:[lo-1e5,cut],ax?[cut,hi+1e5]:[hi+1e5,cut]);if(!r||r[0]<-.001||r[0]>1.001)return;var s=r[0]*cLen(w),p=cAt(w,s,0),v=ax?p[1]:p[0],t=cT(w)/Math.abs(cr)/2,H=cH(w),op=cOps(w).filter(function(o){return s>=o.d&&s<=o.d+o.l})[0];hits.push({v:v,t:t,H:H,w:w,op:op})});
  dw.T(base[0],base[1]-2,'Corte '+S2[0]+'-'+S2[0],{fs:3.4,b:1});dw.L(X(lo-900),Y(0),X(hi+900),Y(0),{w:.8,c:'#222'});dw.P([[X(lo-600),Y(0)],[X(hi+600),Y(0)],[X(hi+600),Y(-100)],[X(lo-600),Y(-100)]],{f:'#d9d6d0',c:'#555',w:.2});
  hits.sort(function(a,b){return a.v-b.v});hits.forEach(function(h){var pc=function(y0,y1){if(y1-y0<5)return;dw.P([[X(h.v-h.t),Y(y0)],[X(h.v+h.t),Y(y0)],[X(h.v+h.t),Y(y1)],[X(h.v-h.t),Y(y1)]],{f:'#3a3f46',c:'#222',w:.25})};if(h.op){pc(0,h.op.p);pc(h.op.p+h.op.h,h.H);if(h.op.k==='janela'||h.op.k==='basc')dw.L(X(h.v),Y(h.op.p),X(h.v),Y(h.op.p+h.op.h),{w:.3,c:'#1d6fb8'})}else pc(0,h.H)});
  var T={P:function(x,y){return [X(x),Y(y)]},k:1/sc,pt:.3528};
  for(var i=0;i<hits.length-1;i++){var a=hits[i],b=hits[i+1],m=(a.v+b.v)/2,pnt=ax?[cut,m]:[m,cut],rm=null;R.forEach(function(r){if(!rm&&pIn(pnt,r.pts))rm=r});if(!rm)continue;var ph=rm.ph;dw.L(X(a.v+a.t),Y(ph),X(b.v-b.t),Y(ph),{w:.5,c:'#555'});dw.T(X(m),Y(ph/2),rm.r.n,{fs:2.8,al:'c',c:'#333'});if(b.v-a.v>900)cDim(dw,T,[m,0],[m,ph],[1,0],0,cmT(ph),{fs:5});cDim(dw,T,[a.v+a.t,0],[b.v-b.t,0],[0,-1],5*sc,cmT(b.v-b.t-a.v-a.t),{fs:5})}
  if(rh&&hits.length){var l0=hits[0].v-hits[0].t-rf.bei,l1=hits[hits.length-1].v+hits[hits.length-1].t+rf.bei,top=maxH;if(rf.k==='laje')dw.P([[X(l0),Y(top)],[X(l1),Y(top)],[X(l1),Y(top+120)],[X(l0),Y(top+120)]],{f:'#bdb8ae',c:'#555',w:.25});else{var ridge=ax?(rf.k==='2a'&&(bb[3]-bb[1])<(bb[2]-bb[0])):(rf.k==='2a'&&(bb[2]-bb[0])<=(bb[3]-bb[1]));var m2=(l0+l1)/2,pk=ridge?top+(m2-l0)*rf.inc/100:top+rh;dw.P(ridge||rf.k==='4a'?[[X(l0),Y(top)],[X(m2),Y(pk)],[X(l1),Y(top)]]:[[X(l0),Y(top)],[X(l0),Y(top+rh)],[X(l1),Y(top+rh)],[X(l1),Y(top)]],{f:'#e8d7cf',c:rf.c,w:.5})}}})}
function cTable(dw,x,y,cols,rows,o){o=o||{};var rh=o.rh||5.2,sz=o.fs||2.7,cx=[x];cols.forEach(function(c,i){cx.push(cx[i]+c[1])});var W=cx[cx.length-1]-x;
 dw.P([[x,y],[x+W,y],[x+W,y+rh],[x,y+rh]],{f:'#e8ecf1',c:'#999',w:.2});cols.forEach(function(c,i){dw.T(c[2]==='r'?cx[i+1]-1.5:cx[i]+1.5,y+rh*.68,c[0],{fs:sz,b:1,al:c[2]==='r'?'r':'l'})});y+=rh;
 rows.forEach(function(r,ri){if(r.sec){dw.T(x+1.5,y+rh*.68,r.sec,{fs:sz,b:1,c:'#1f4f8f'});y+=rh;return}if(ri%2)dw.P([[x,y],[x+W,y],[x+W,y+rh],[x,y+rh]],{f:'#f7f8fa'});r.forEach(function(v,i){dw.T(cols[i][2]==='r'?cx[i+1]-1.5:cx[i]+1.5,y+rh*.68,v,{fs:sz,b:!!(r.b),al:cols[i][2]==='r'?'r':'l'})});y+=rh});dw.L(x,y,x+W,y,{w:.2,c:'#999'});return y}
function cAreaTable(dw){var A=casaAreas(),rows=A.R.map(function(r){return [r.r.n,cA(r.area),cM(r.per),cM(r.ph).replace(' m',''),cA(r.area),cA(r.wa),(cOf(CPISO,r.r.pf)||['',''])[1]]});rows.push(['Área útil (soma dos ambientes)',cA(A.util),'','','','','']);rows[rows.length-1].b=1;rows.push(['Área construída (contorno externo)',cA(A.cons),'','','','','']);rows[rows.length-1].b=1;
 dw.T(14,20,'Quadro de áreas',{fs:4.4,b:1});cTable(dw,14,26,[['Ambiente',62],['Piso',28,'r'],['Perímetro',28,'r'],['Pé-direito (m)',28,'r'],['Teto',28,'r'],['Paredes (líquida)',34,'r'],['Acabamento do piso',60]],rows)}
function cQuantPages(title){var Q=casaQuant(),C=casa(),out=[],rows=[],last='';Q.rows.forEach(function(r){if(r.g!==last){rows.push({sec:r.g});last=r.g}var d=r.u==='un'?0:2;rows.push([r.n,cN(r.v,d)+' '+r.u,r.p!=null?r.p+'%':'—',cN(r.tot,d)+' '+r.u,r.pr])});
 var per=26;for(var i=0;i<rows.length;i+=per)(function(ch,first){out.push(function(pg,n){var dw=new DW();dw.T(14,20,'Relatório de quantitativos (estimativa)',{fs:4.4,b:1});var y=cTable(dw,14,26,[['Item',70],['Quantidade',28,'r'],['Perda',16,'r'],['Com perda',28,'r'],['Premissa de cálculo',127]],ch.map(function(r){if(r.sec)return r;return [r[0],r[1],r[2],r[3],(r[4]||'').length>92?r[4].slice(0,90)+'…':r[4]]}),{fs:2.5,rh:4.8});
  if(first)dw.T(14,Math.min(166,y+6),'Premissas gerais: medidas pelo eixo das paredes, descontando todos os vãos; perdas configuráveis em 📊 Quantitativos. Confira as quantidades com o fornecedor antes de comprar.',{fs:2.4,c:'#444'});cFrame(dw,pg,n,title,0);return {w:297,h:210,dw:dw}})})(rows.slice(i,i+per),i===0);return out}

/* onde passam os cortes: perto do meio, mas fora dos nomes dos ambientes */
function cSecAt(bb,ax){var R=casaRooms(),lo=ax?bb[0]:bb[2],best=null,bs=-1;for(var f=.3;f<=.701;f+=.05){var v=(ax?bb[0]:bb[1])+f*((ax?bb[2]-bb[0]:bb[3]-bb[1])),d=1e18;R.forEach(function(r){d=Math.min(d,Math.abs((ax?r.r.x:r.r.z)-v))});casa().W.forEach(function(w){var u=cU(w);if(Math.abs(ax?u[1]:u[0])>.9){var c0=ax?w.a[0]:w.a[1];d=Math.min(d,Math.abs(c0-v)*2)}});var sc=Math.min(d,1500)-Math.abs(f-.5)*800;if(sc>bs){bs=sc;best=v}}return best}
/* quadro de esquadrias na prancha */
function cOpTable(dw,A){var R=cOpCodes().rows;if(!R.length)return;var x=A[0]+A[2]-74,y=A[1],nm={porta:'Porta de abrir',porta2:'Porta 2 folhas',correr:'Porta de correr',janela:'Janela',basc:'Basculante',vao:'Vão'};cTable(dw,x,y,[['Cód.',10],['Tipo',24],['L × A (cm)',18,'r'],['Peit.',10,'r'],['Qtd.',10,'r']],R.map(function(r){return [r.code,nm[r.k]||r.k,cCm(r.l)+' × '+cCm(r.h),r.p?cCm(r.p):'—',String(r.q)]}),{fs:2.3,rh:3.9})}
