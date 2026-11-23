import sys,ezdxf
from ezdxf import recover
from collections import Counter
for f in sys.argv[1:]:
    try:
        doc=ezdxf.readfile(f)
    except Exception as e:
        print(f,'ERRO',e);continue
    aud=doc.audit()
    msp=doc.modelspace();c=Counter((e.dxftype(),e.dxf.layer) for e in msp)
    pl=[e for e in msp if e.dxftype()=='POLYLINE' and e.dxf.layer=='CONTORNO']
    fech=sum(1 for p in pl if p.is_closed)
    print(f'{f}: versão {doc.dxfversion} · erros auditoria {len(aud.errors)} · contornos {len(pl)} (fechados {fech})')
    for (t,l),n in sorted(c.items(),key=lambda x:(x[0][1],x[0][0])):
        if l!='CONTORNO': print(f'   {l:28s} {t:9s} {n}')
