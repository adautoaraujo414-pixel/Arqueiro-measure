"""Prepara a versão em preparo do App Store Connect pra revisão e (opcional) envia pra Apple.

1) espera o build mais novo ficar pronto (VALID), 2) coloca ele na versão, 3) mostra o que falta,
4) com ENVIAR=1 cria o envio pra revisão e manda. Uso: python asc_submit.py <app_id>
"""
import os, sys, time
import jwt, requests

API = "https://api.appstoreconnect.apple.com/v1"
APP_ID = sys.argv[1]
SUBMIT = os.environ.get("ENVIAR") == "1"


def token():
    key = os.environ["ASC_KEY_P8"].strip() + "\n"
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


S = requests.Session()


def call(method, path, ok=False, **kw):
    S.headers["Authorization"] = "Bearer " + token()
    url = path if path.startswith("http") else API + path
    r = S.request(method, url, timeout=120, **kw)
    if r.status_code >= 400:
        print(f"::{'warning' if ok else 'error'}::{method} {path} -> {r.status_code} {r.text[:1500]}")
        if ok:
            return None
        r.raise_for_status()
    return r.json() if r.text else {}


PREP = ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED")
TIRAR = os.environ.get("TIRAR") == "1"
LIBERAR = os.environ.get("LIBERAR") == "1"  # lançamento automático quando a Apple aprovar (ou liberar agora se já aprovada)


def versao_em_preparo():
    vs = call("GET", f"/apps/{APP_ID}/appStoreVersions", params={"filter[platform]": "IOS", "limit": 20})["data"]
    return vs, next((v for v in vs if v["attributes"]["appStoreState"] in PREP), None)


def lancamento_automatico(v):
    """Deixa a versão ir pra loja sozinha assim que a Apple aprovar (releaseType AFTER_APPROVAL)."""
    nome = v["attributes"]["versionString"]
    if v["attributes"].get("releaseType") == "AFTER_APPROVAL":
        print("versão", nome, "já está em lançamento automático ✓")
        return True
    r = call("PATCH", f"/appStoreVersions/{v['id']}", ok=True,
             json={"data": {"type": "appStoreVersions", "id": v["id"], "attributes": {"releaseType": "AFTER_APPROVAL"}}})
    if r:
        print("LANÇAMENTO AUTOMÁTICO LIGADO: versão", nome, "vai pra loja sozinha quando a Apple aprovar ✓")
        return True
    return False


versions, ver = versao_em_preparo()
# -1) com LIBERAR=1: versão já aprovada e esperando → libera agora; senão liga o lançamento automático
if LIBERAR:
    pend = next((v for v in versions if v["attributes"]["appStoreState"] == "PENDING_DEVELOPER_RELEASE"), None)
    if pend:
        call("POST", "/appStoreVersionReleaseRequests", json={"data": {"type": "appStoreVersionReleaseRequests", "relationships": {
             "appStoreVersion": {"data": {"type": "appStoreVersions", "id": pend["id"]}}}}})
        print("VERSÃO", pend["attributes"]["versionString"], "LIBERADA PRA LOJA AGORA (já estava aprovada) ✓")
        sys.exit(0)
    alvo = ver or next((v for v in versions if v["attributes"]["appStoreState"] in ("WAITING_FOR_REVIEW", "IN_REVIEW")), None)
    if not alvo:
        for v in versions:
            print("versão", v["attributes"]["versionString"], v["attributes"]["appStoreState"], v["attributes"].get("releaseType"))
        sys.exit("::error::nenhuma versão em preparo nem na fila da revisão")
    if lancamento_automatico(alvo):
        if not (TIRAR or SUBMIT):
            sys.exit(0)
    elif alvo is not ver:
        print("::warning::a Apple não deixou mudar com a versão na fila · tirando da fila, ligando o automático e reenviando")
        TIRAR = SUBMIT = True
# 0) com TIRAR=1: se a versão está "Aguardando revisão", tira da fila (cancela o envio) pra poder trocar o build e as capturas
if not ver and TIRAR:
    esperando = next((v for v in versions if v["attributes"]["appStoreState"] in ("WAITING_FOR_REVIEW", "IN_REVIEW")), None)
    if esperando:
        subs = call("GET", "/reviewSubmissions", params={"filter[app]": APP_ID, "filter[platform]": "IOS", "limit": 10})["data"]
        for sb in subs:
            if sb["attributes"]["state"] in ("WAITING_FOR_REVIEW", "IN_REVIEW", "UNRESOLVED_ISSUES"):
                call("PATCH", f"/reviewSubmissions/{sb['id']}", json={"data": {"type": "reviewSubmissions", "id": sb["id"], "attributes": {"canceled": True}}})
                print("envio", sb["id"], "tirado da revisão (estava", sb["attributes"]["state"] + ")")
        for i in range(20):
            time.sleep(15)
            versions, ver = versao_em_preparo()
            if ver:
                break
            print("esperando a versão voltar pra preparo…")
if not ver:
    for v in versions:
        print("versão", v["attributes"]["versionString"], v["attributes"]["appStoreState"])
    sys.exit("::error::nenhuma versão em preparo (talvez já esteja em revisão)")
vs = ver["attributes"]["versionString"]
print("versão", vs, ver["attributes"]["appStoreState"])
if LIBERAR:
    lancamento_automatico(ver)

# 1) build mais novo pronto
build = None
for i in range(40):
    bs = call("GET", "/builds", params={"filter[app]": APP_ID, "sort": "-uploadedDate", "limit": 5,
                                         "fields[builds]": "version,uploadedDate,processingState,expired,usesNonExemptEncryption"})["data"]
    for b in bs:
        a = b["attributes"]
        print("build", a["version"], a["uploadedDate"], a["processingState"], "expirado" if a.get("expired") else "")
    top = bs[0] if bs else None
    if top and top["attributes"]["processingState"] == "VALID":
        build = top
        break
    print("esperando a Apple terminar de processar o build mais novo…")
    time.sleep(45)
if not build:
    sys.exit("::error::o build mais novo ainda não ficou pronto na Apple")
print("usando build", build["attributes"]["version"], build["attributes"]["uploadedDate"])
if build["attributes"].get("usesNonExemptEncryption") is None:
    call("PATCH", f"/builds/{build['id']}", ok=True, json={"data": {"type": "builds", "id": build["id"], "attributes": {"usesNonExemptEncryption": False}}})

# 2) coloca o build na versão
call("PATCH", f"/appStoreVersions/{ver['id']}/relationships/build", json={"data": {"type": "builds", "id": build["id"]}})
print("build colocado na versão", vs)

# 3) conferência do que a Apple pede
for loc in call("GET", f"/appStoreVersions/{ver['id']}/appStoreVersionLocalizations")["data"]:
    a = loc["attributes"]
    falta = [k for k in ("description", "keywords", "supportUrl") if not a.get(k)]
    sets = call("GET", f"/appStoreVersionLocalizations/{loc['id']}/appScreenshotSets")["data"]
    print("idioma", a["locale"], "· falta:", ", ".join(falta) or "nada", "· conjuntos de capturas:", len(sets))
rd = call("GET", f"/appStoreVersions/{ver['id']}/appStoreReviewDetail", ok=True)
if rd and rd.get("data"):
    a = rd["data"]["attributes"]
    print("contato da revisão:", a.get("contactFirstName"), a.get("contactLastName"), a.get("contactEmail"), "· conta demo exigida:", a.get("demoAccountRequired"))
else:
    print("::warning::sem dados de contato pra revisão")

if not SUBMIT:
    print("Pronto pra enviar. Rode de novo com enviar=true pra mandar pra revisão.")
    sys.exit(0)

# 4) envio pra revisão
subs = call("GET", "/reviewSubmissions", params={"filter[app]": APP_ID, "filter[platform]": "IOS", "limit": 10})["data"]
sub = next((s for s in subs if s["attributes"]["state"] in ("READY_FOR_REVIEW",)), None)
if not sub:
    sub = call("POST", "/reviewSubmissions", json={"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
               "relationships": {"app": {"data": {"type": "apps", "id": APP_ID}}}}})["data"]
items = call("GET", f"/reviewSubmissions/{sub['id']}/items", ok=True)
if not (items and items.get("data")):
    call("POST", "/reviewSubmissionItems", json={"data": {"type": "reviewSubmissionItems", "relationships": {
         "reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
         "appStoreVersion": {"data": {"type": "appStoreVersions", "id": ver["id"]}}}}})
r = call("PATCH", f"/reviewSubmissions/{sub['id']}", json={"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}}})
print("ENVIADO PRA REVISÃO DA APPLE:", r["data"]["attributes"].get("state"))
