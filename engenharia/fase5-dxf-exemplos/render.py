import sys,ezdxf
from ezdxf.addons.drawing import matplotlib as dm
for f in sys.argv[1:]:
    doc=ezdxf.readfile(f); dm.qsave(doc.modelspace(), f.replace('.dxf','.png'), bg='#FFFFFF', dpi=150)
    print('ok',f)
