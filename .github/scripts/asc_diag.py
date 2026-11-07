"""Diagnóstico da assinatura no App Store Connect (só leitura): estado da assinatura, grupo, preços, oferta
de teste, disponibilidade, versões e builds. Uso: python asc_diag.py <app_id>"""
import os, sys, time
import jwt, requests

API = "https://api.appstoreconnect.apple.com/v1"
APP_ID = sys.argv[1]


def token():
    key = os.environ["ASC_KEY_P8"].strip() + "\n"
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"], "iat": now, "exp": now + 1100, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": os.environ["ASC_KEY_ID"], "typ": "JWT"})


S = requests.Session()


def get(path, **params):
    S.headers["Authorization"] = "Bearer " + token()
    r = S.get(API + path, params=params, timeout=120)
    if r.status_code >= 400:
        print(f"  (erro {r.status_code} em {path}: {r.text[:300]})")
        return {"data": []}
    return r.json()


def a(x):
    return x.get("attributes", {})


print("== APP ==")
app = get(f"/apps/{APP_ID}", **{"fields[apps]": "name,bundleId,sku,primaryLocale,availableInNewTerritories,contentRightsDeclaration"})["data"]
print(" ", a(app).get("name"), a(app).get("bundleId"), "· sku", a(app).get("sku"), "· novos países:", a(app).get("availableInNewTerritories"))

print("== VERSÕES ==")
for v in get(f"/apps/{APP_ID}/appStoreVersions", **{"filter[platform]": "IOS", "limit": 10})["data"]:
    print("  versão", a(v).get("versionString"), a(v).get("appStoreState"), "· lançamento", a(v).get("releaseType"), "· criada", a(v).get("createdDate"))

print("== GRUPOS DE ASSINATURA ==")
grupos = get(f"/apps/{APP_ID}/subscriptionGroups", limit=20)["data"]
if not grupos:
    print("  NENHUM grupo de assinatura")
for g in grupos:
    print("  grupo", g["id"], a(g).get("referenceName"))
    for loc in get(f"/subscriptionGroups/{g['id']}/subscriptionGroupLocalizations")["data"]:
        print("    nome na loja:", a(loc).get("locale"), a(loc).get("name"), "· estado", a(loc).get("state"))
    for s in get(f"/subscriptionGroups/{g['id']}/subscriptions", limit=20)["data"]:
        at = a(s)
        print("    ASSINATURA", at.get("productId"), "·", at.get("name"), "· ESTADO:", at.get("state"), "· período", at.get("subscriptionPeriod"), "· família", at.get("familySharable"), "· nível", at.get("groupLevel"))
        for loc in get(f"/subscriptions/{s['id']}/subscriptionLocalizations")["data"]:
            print("      texto:", a(loc).get("locale"), a(loc).get("name"), "·", (a(loc).get("description") or "")[:60], "· estado", a(loc).get("state"))
        pr = get(f"/subscriptions/{s['id']}/prices", **{"include": "subscriptionPricePoint,territory", "limit": 200})
        pts = {i["id"]: i for i in pr.get("included", [])}
        n = 0
        for p in pr["data"]:
            n += 1
            rel = p.get("relationships", {})
            t = (rel.get("territory", {}).get("data") or {}).get("id")
            pp = pts.get((rel.get("subscriptionPricePoint", {}).get("data") or {}).get("id"), {})
            if t in ("BRA", "USA", "PRT"):
                print("      preço", t, a(pp).get("customerPrice"), "· a partir de", a(p).get("startDate"), "· preservado", a(p).get("preserved"))
        print("      países com preço:", n)
        for o in get(f"/subscriptions/{s['id']}/introductoryOffers", limit=200)["data"][:3]:
            print("      oferta de teste:", a(o).get("offerMode"), a(o).get("duration"), a(o).get("numberOfPeriods"), "· território", (o.get("relationships", {}).get("territory", {}).get("data") or {}).get("id"), "· início", a(o).get("startDate"), "· fim", a(o).get("endDate"))
        av = get(f"/subscriptions/{s['id']}/subscriptionAvailability", **{"include": "availableTerritories", "limit[availableTerritories]": 200})
        if av.get("data"):
            print("      disponível em novos países:", a(av["data"]).get("availableInNewTerritories"), "· países:", len(av.get("included", [])))
        rs = get(f"/subscriptions/{s['id']}/appStoreReviewScreenshot")
        if rs.get("data"):
            print("      print da revisão:", a(rs["data"]).get("assetDeliveryState", {}).get("state"), a(rs["data"]).get("fileName"))
        else:
            print("      print da revisão: NENHUM")

print("== DISPONIBILIDADE DO APP ==")
av = get(f"/apps/{APP_ID}/appAvailabilityV2", **{"include": "territoryAvailabilities", "limit[territoryAvailabilities]": 200})
if av.get("data"):
    inc = av.get("included", [])
    ok = [i for i in inc if a(i).get("available")]
    bra = [i for i in inc if i["id"].endswith("BRA") or (a(i).get("territory") == "BRA")]
    print("  países disponíveis:", len(ok), "de", len(inc), "· novos países:", a(av["data"]).get("availableInNewTerritories"))
    for i in inc:
        if "BRA" in i["id"]:
            print("  Brasil:", a(i))

print("== BUILDS ==")
for b in get("/builds", **{"filter[app]": APP_ID, "sort": "-uploadedDate", "limit": 6, "fields[builds]": "version,uploadedDate,processingState,expired"})["data"]:
    print("  build", a(b).get("version"), a(b).get("processingState"), a(b).get("uploadedDate"), "expirado" if a(b).get("expired") else "")
print("FIM")
