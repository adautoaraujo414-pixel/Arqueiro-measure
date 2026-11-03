"""Envia as capturas de tela (ramo ci/ios-resultados) para a versão em preparo no App Store Connect.

Usa a chave da API (ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8). Substitui as capturas que já estiverem
nos tamanhos enviados. Uso: python asc_screenshots.py <pasta-capturas> <app_id>
"""
import hashlib, os, sys, time, glob
import jwt, requests
from PIL import Image

API = "https://api.appstoreconnect.apple.com/v1"
SRC, APP_ID = sys.argv[1], sys.argv[2]

# ordem na loja: tela inicial nova primeiro
IPHONE = ["iphone-7-moveis3d", "iphone-1-library", "iphone-8-moveisplanta", "iphone-5-moveis", "iphone-2-editor", "iphone-4-quotes", "iphone-3-agenda", "iphone-6-trial"]
IPAD = ["ipad-7-moveis3d", "ipad-8-moveisplanta", "ipad-5-moveis", "ipad-2-editor", "ipad-1-library", "ipad-4-quotes", "ipad-3-agenda", "ipad-6-trial"]
# (tipo na API, lista, tamanho final ou None pra manter)
SETS = [
    ("APP_IPHONE_61", IPHONE, (1206, 2622)),          # obrigatório: iPhone com Dynamic Island (tela média)
    ("APP_IPHONE_67", IPHONE, None),                  # 1320 x 2868 (tela grande)
    ("APP_IPAD_PRO_3GEN_129", IPAD, None),            # 2064 x 2752 (iPad 13")
]
# pasta por idioma da loja (as capturas em pt ficam na raiz)
LOCALES = {"pt-BR": "", "en-US": "en", "es-ES": "es", "es-MX": "es"}


def token():
    key = os.environ["ASC_KEY_P8"].strip() + "\n"
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


S = requests.Session()


def call(method, path, **kw):
    S.headers["Authorization"] = "Bearer " + token()
    url = path if path.startswith("http") else API + path
    r = S.request(method, url, timeout=120, **kw)
    if r.status_code >= 400:
        print(f"::error::{method} {path} -> {r.status_code} {r.text[:800]}")
        r.raise_for_status()
    return r.json() if r.text else {}


versions = call("GET", f"/apps/{APP_ID}/appStoreVersions", params={"filter[platform]": "IOS", "limit": 20})["data"]
ver = next((v for v in versions if v["attributes"]["appStoreState"] in
            ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")), None)
if not ver:
    sys.exit("::error::nenhuma versão em preparo encontrada")
print("versão", ver["attributes"]["versionString"], ver["attributes"]["appStoreState"])
locs = call("GET", f"/appStoreVersions/{ver['id']}/appStoreVersionLocalizations")["data"]
out = "/tmp/asc-shots"
os.makedirs(out, exist_ok=True)

for loc in locs:
    lang = loc["attributes"]["locale"]
    if lang not in LOCALES:
        print("pulando idioma", lang)
        continue
    folder = os.path.join(SRC, LOCALES[lang])
    sets = {s["attributes"]["screenshotDisplayType"]: s["id"] for s in
            call("GET", f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]}
    for dtype, names, size in SETS:
        files = [os.path.join(folder, n + ".png") for n in names if os.path.exists(os.path.join(folder, n + ".png"))]
        if not files:
            print(lang, dtype, "sem arquivos")
            continue
        if dtype in sets:  # substitui as que já estavam
            for old in call("GET", f"/appScreenshotSets/{sets[dtype]}/appScreenshots")["data"]:
                call("DELETE", f"/appScreenshots/{old['id']}")
            set_id = sets[dtype]
        else:
            set_id = call("POST", "/appScreenshotSets", json={"data": {"type": "appScreenshotSets",
                          "attributes": {"screenshotDisplayType": dtype},
                          "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}})["data"]["id"]
        for f in files:
            name = os.path.basename(f)
            path = os.path.join(out, f"{lang}-{dtype}-{name}")
            im = Image.open(f).convert("RGB")
            if size and im.size != size:
                im = im.resize(size, Image.LANCZOS)
            im.save(path)
            data = open(path, "rb").read()
            shot = call("POST", "/appScreenshots", json={"data": {"type": "appScreenshots",
                        "attributes": {"fileName": name, "fileSize": len(data)},
                        "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
            for op in shot["attributes"]["uploadOperations"]:
                hdr = {h["name"]: h["value"] for h in op["requestHeaders"]}
                chunk = data[op["offset"]: op["offset"] + op["length"]]
                r = requests.request(op["method"], op["url"], headers=hdr, data=chunk, timeout=120)
                r.raise_for_status()
            call("PATCH", f"/appScreenshots/{shot['id']}", json={"data": {"type": "appScreenshots", "id": shot["id"],
                 "attributes": {"uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
            print("ok", lang, dtype, name, Image.open(path).size)

print("Capturas enviadas. A Apple processa em alguns minutos.")
