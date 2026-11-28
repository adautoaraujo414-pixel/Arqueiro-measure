#!/usr/bin/env python3
"""Escolhe o simulador: python3 pick_sim.py iphone|ipad|storekit|iphone375 -> imprime o UDID.
iphone375 = iPhone de 375 de largura (iPhone SE 3ª geração; senão SE 2ª, 13 mini ou 12 mini). Se o runner não tiver o
aparelho criado, cria um a partir do tipo e do iOS mais novo que o aceita (Chefe 28/11, ETAPA 3 · 3.6).
storekit = iPhone num iOS até 26.2: no iOS 26.3+ o `xcodebuild test` não carrega o .storekit
(bug da Apple FB22237318, "SKTestSession ... Error saving configuration file", SKInternalErrorDomain 3)."""
import json, subprocess, sys

kind = sys.argv[1] if len(sys.argv) > 1 else "iphone"
storekit = kind == "storekit"
if storekit:
    kind = "iphone"
P375 = ["iPhone SE (3rd generation)", "iPhone SE (2nd generation)", "iPhone 13 mini", "iPhone 12 mini"]
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
devs = []
for runtime, lst in data["devices"].items():
    if "iOS" not in runtime:
        continue
    ver = runtime.split("iOS-")[-1].replace("-", ".")
    for d in lst:
        devs.append((ver, d["name"], d["udid"]))

def score(name):
    if kind == "iphone375":
        return P375.index(name) if name in P375 else 999
    if kind == "iphone":
        prefs = ["iPhone 17 Pro Max", "iPhone 16 Pro Max", "iPhone 17 Pro", "iPhone 16 Plus", "iPhone 17"]
    else:
        prefs = ["iPad Pro 13-inch (M5)", "iPad Pro 13-inch (M4)", "iPad Air 13-inch (M3)", "iPad Air 13-inch (M2)", "iPad Pro (12.9-inch) (6th generation)"]
    for i, p in enumerate(prefs):
        if name == p:
            return i
    if kind == "iphone" and name.startswith("iPhone"):
        return 50
    if kind == "ipad" and name.startswith("iPad"):
        return 50 if "13" in name or "12.9" in name else 80
    return 999

def vkey(v):
    try:
        return tuple(int(x) for x in v.split("."))
    except ValueError:
        return (0,)

if storekit:
    devs = [d for d in devs if (17,) <= vkey(d[0]) <= (26, 2, 99)]
best = sorted(devs, key=lambda d: (score(d[1]), tuple(-x for x in vkey(d[0]))))
if kind == "iphone375" and (not best or score(best[0][1]) >= 999):
    # o runner não tem o aparelho de 375 criado: cria um (tipo da lista P375, no iOS mais novo que aceita o tipo)
    tipos = {t["name"]: t["identifier"] for t in json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "-j"]))["devicetypes"]}
    rts = [r for r in json.loads(subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "-j"]))["runtimes"] if r.get("isAvailable") and r.get("platform", "iOS") == "iOS"]
    rts.sort(key=lambda r: vkey(r.get("version", "0")), reverse=True)
    for nome in P375:
        if nome not in tipos:
            continue
        for r in rts:
            ok = [t.get("identifier") for t in r.get("supportedDeviceTypes", [])]
            if ok and tipos[nome] not in ok:
                continue
            udid = subprocess.check_output(["xcrun", "simctl", "create", nome, tipos[nome], r["identifier"]]).decode().strip()
            print(udid)
            print(f"{nome} (iOS {r.get('version')}, criado agora)", file=sys.stderr)
            sys.exit(0)
    sys.exit("nenhum simulador iphone375 (nem tipo pra criar)")
if not best or score(best[0][1]) >= 999:
    sys.exit("nenhum simulador " + kind)
print(best[0][2])
print(f"{best[0][1]} (iOS {best[0][0]})", file=sys.stderr)
