#!/usr/bin/env python3
"""N06 (auditoria de 17/11): gera o backup de referência no formato do backup completo do Android
(arque-full-backup.txt + files/... + shared_prefs/arque.links.xml) e a lista do que tem que voltar (manifesto.json).
Os testes de restauração das 3 plataformas usam este mesmo arquivo. Conteúdo fixo (datas fixas): rodar de novo gera o mesmo ZIP."""
import hashlib, json, os, zipfile
AQUI = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tests', 'backup-referencia')
os.makedirs(AQUI, exist_ok=True)
MOD = lambda i, w: {"id": "m%d" % i, "x": i * 1000, "w": w, "h": 820, "d": 560, "b": 0, "div": [], "v": [{"k": "door", "n": 2}]}
PROJ = [
    {"id": "p1", "client": {"nome": "Cliente Referência 1"}, "created": 1700000000000, "updated": 1700000100000,
     "current": {"W": 4000, "H": 2700, "mods": [MOD(0, 900), MOD(1, 600)], "stones": []}},
    {"id": "p2", "client": {"nome": "Cliente Referência 2"}, "created": 1700000200000, "updated": 1700000300000,
     "current": {"W": 3200, "H": 2600, "mods": [MOD(0, 800)], "stones": []}},
]
# 21/11 (teste de abrir as notas depois da atualização): a medida e a foto no formato que o app grava de verdade (Json.kt / JsonCodec.swift:
# medida com a, b, valueMm, color e width; foto com cx, cy, w e h). Antes era um formato inventado (x1, y1, value) que nenhum app abre.
NOTA = lambda nid, foto: {"v": 3, "id": nid, "name": "Nota " + nid, "folderId": "f1", "createdMs": 1700000000000, "pinned": False, "locked": False, "trash": False, "unit": "M",
                          "pages": [{"id": "pg1", "tpl": "ARAUJO", "objs": [
                              {"id": "o2", "type": "photo", "file": foto, "pxW": 100, "pxH": 80, "cx": 397.0, "cy": 300.0, "w": 500.0, "h": 400.0, "rot": 0.0, "locked": False},
                              {"id": "o1", "type": "dim", "photoId": "o2", "a": [150.0, 300.0], "b": [650.0, 300.0], "valueMm": 1234.0, "source": None, "history": [],
                               "color": -1762269, "width": 2.1, "labelScale": 1.0, "labelAlpha": 1.0, "labelIntensity": 1.0, "refSize": 0.0, "locked": False}]}]}
IDX = {"v": 3, "folders": [{"id": "f1", "name": "Obras"}],
       "notes": [{"id": n, "name": "Nota " + n, "folderId": "f1", "createdMs": 1, "pinned": False, "locked": False, "trash": False, "pageCount": 1, "dimCount": 1} for n in ("n1", "n2")]}
FOTO = bytes((i * 7) % 251 for i in range(6000))
FOTO2 = bytes((i * 13) % 251 for i in range(4000))
PH = {"id": "f900", "pid": "p1", "kind": "obra", "data": "data:image/jpeg;base64,AQIDBAU=", "w": 10, "h": 8, "marks": [], "created": 1700000000000}
ARQ = {
    "files/moveis/projects.json": json.dumps(PROJ, ensure_ascii=False).encode(),
    "files/moveis/photo_f900.json": json.dumps(PH).encode(),
    "files/moveis/prices.json": json.dumps({"sheetW": 2750, "sheetH": 1840}).encode(),
    "files/projects/index.json": json.dumps(IDX, indent=2).encode(),
    "files/projects/notes/n1.json": json.dumps(NOTA("n1", "foto..jpg")).encode(),
    "files/projects/notes/n2.json": json.dumps(NOTA("n2", "obra1.jpg")).encode(),
    "files/projects/images/foto..jpg": FOTO,
    "files/projects/images/obra1.jpg": FOTO2,
}
LINKS = b'<?xml version="1.0" encoding="utf-8" standalone="yes" ?>\n<map>\n    <string name="n1">p1</string>\n</map>\n'
zp = os.path.join(AQUI, 'android-backup-referencia.zip')
with zipfile.ZipFile(zp, 'w', zipfile.ZIP_DEFLATED) as z:
    def add(n, b):
        zi = zipfile.ZipInfo(n, date_time=(2026, 11, 17, 12, 0, 0)); zi.compress_type = zipfile.ZIP_DEFLATED; z.writestr(zi, b)
    add('arque-full-backup.txt', b'backup')
    for n in sorted(ARQ): add(n, ARQ[n])
    add('shared_prefs/arque.links.xml', LINKS)
man = {"arquivos": {n[len('files/'):]: hashlib.sha256(b).hexdigest() for n, b in sorted(ARQ.items())},
       "projetos": [p["id"] for p in PROJ], "notas": ["n1", "n2"], "vinculos": {"n1": "p1"}}
open(os.path.join(AQUI, 'manifesto.json'), 'w').write(json.dumps(man, indent=2, ensure_ascii=False) + '\n')
print(zp, os.path.getsize(zp))
