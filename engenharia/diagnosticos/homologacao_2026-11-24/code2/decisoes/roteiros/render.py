import json,sys
from PIL import Image,ImageDraw
O='/home/user/wt-dec/engenharia/diagnosticos/homologacao_2026-11-24/code2/decisoes'
TIT={'G':'Perfil G × travessa frontal (corte vertical no meio da porta; z = profundidade, y = altura)','FAC':'Facetado × travessa frontal (corte vertical no meio da porta)','DOB':'Caneco da dobradiça × lateral (corte horizontal na altura da dobradiça; x, z)','FITA':'Porta do aéreo × fita de 0,8 da lateral (corte horizontal; x, z)'}
def ov(a,b):
  return (min(a[1],b[1])-max(a[0],b[0]), min(a[3],b[3])-max(a[2],b[2]))
def draw(C,v):
  d=json.load(open(f'sec_{C}_{v}.json'));B=d['b']
  CUPC=([195,201,208],[125,132,140],[74,79,86])
  isPull=lambda b: C in('G','FAC') and b['nm'] in('Porta','Frente de gaveta') and b.get('nol') and b.get('mt')
  isCup=lambda b: C=='DOB' and b['nm']=='Porta' and list(b['c'][:3]) in [list(x) for x in CUPC]
  key=[b for b in B if isPull(b) or isCup(b)]
  if C=='FITA':key=[b for b in B if (b['a'][3]-b['a'][2])<1.0 or (b['a'][1]-b['a'][0])<1.0]
  if not key:key=B
  x0=min(b['a'][0] for b in key)-25;x1=max(b['a'][1] for b in key)+25;y0=min(b['a'][2] for b in key)-25;y1=max(b['a'][3] for b in key)+25
  if C=='FITA':
    pt=[b for b in B if b['nm']=='Porta'];
    if pt: x0=pt[0]['a'][0]-30;x1=pt[0]['a'][0]+30;y0=pt[0]['a'][2]-20;y1=pt[0]['a'][2]+20
  sc=min(900/(x1-x0),620/(y1-y0));W=int((x1-x0)*sc)+40;Hh=int((y1-y0)*sc)+90
  im=Image.new('RGB',(W,Hh),(250,250,248));g=ImageDraw.Draw(im,'RGBA')
  P=lambda x,y:(20+(x-x0)*sc,60+(y1-y)*sc)
  for b in sorted(B,key=lambda b:1 if isPull(b) or isCup(b) else 0):
    a=b['a'];
    if a[1]<x0 or a[0]>x1 or a[3]<y0 or a[2]>y1: continue
    c=tuple(int(v) for v in b['c'][:3]);p0=P(a[0],a[3]);p1=P(a[1],a[2])
    g.rectangle([p0,p1],fill=c+(200,),outline=(40,40,40,255))
  n=0;txt=[]
  if C=='FITA':
    pts=[b for b in B if b['nm']=='Porta' and not b.get('nol')];prof=sorted(pts,key=lambda b:-(b['a'][1]-b['a'][0])*(b['a'][3]-b['a'][2]))[:2]
  else: prof=[b for b in B if isPull(b) or isCup(b)]
  for q in prof:
    for o in B:
      if o is q or o['nm'] in ('Porta','Frente de gaveta'): continue
      if C=='FITA' and not ((o['a'][3]-o['a'][2])<1.0 or (o['a'][1]-o['a'][0])<1.0): continue
      dx,dy=ov(q['a'],o['a'])
      if dx>0.05 and dy>0.05:
        a=[max(q['a'][0],o['a'][0]),min(q['a'][1],o['a'][1]),max(q['a'][2],o['a'][2]),min(q['a'][3],o['a'][3])]
        g.rectangle([P(a[0],a[3]),P(a[1],a[2])],fill=(220,30,30,230));n+=1;txt.append(f"{o['nm']}: {dx:.1f} × {dy:.1f} mm")
  g.text((10,8),f'{TIT[C]}',fill=(0,0,0));g.text((10,24),('ANTES' if v=='antes' else 'DEPOIS')+f' · em vermelho: puxador/dobradiça dentro de outra peça · {n} área(s)',fill=(160,0,0) if n else (0,110,0))
  if txt:g.text((10,40),' | '.join(sorted(set(txt))[:3]),fill=(160,0,0))
  g.text((10,Hh-18),f'escala {sc:.1f} px/mm · caixas reais do 3D do editor (plano em {d["ax"]} = {d["pl"]:.1f})',fill=(90,90,90))
  return im
for C in ['G','FAC','DOB','FITA']:
  a=draw(C,'antes');b=draw(C,'depois');S=Image.new('RGB',(a.size[0]+b.size[0]+10,max(a.size[1],b.size[1])),'white');S.paste(a,(0,0));S.paste(b,(a.size[0]+10,0));nm={'G':'5_perfilG','FAC':'8_facetado','DOB':'4_dobradica','FITA':'6_aereo_fita'}[C];S.save(f'{O}/{nm}_corte_antes_depois.png')
  print(C,S.size)
