#!/usr/bin/env python3
"""Escolhe o simulador: python3 pick_sim.py iphone|ipad|storekit -> imprime o UDID.
storekit = iPhone num iOS até 26.2: no iOS 26.3+ o `xcodebuild test` não carrega o .storekit
(bug da Apple FB22237318, "SKTestSession ... Error saving configuration file", SKInternalErrorDomain 3)."""
import json, subprocess, sys

kind = sys.argv[1] if len(sys.argv) > 1 else "iphone"
storekit = kind == "storekit"
if storekit:
    kind = "iphone"
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))
devs = []
for runtime, lst in data["devices"].items():
    if "iOS" not in runtime:
        continue
    ver = runtime.split("iOS-")[-1].replace("-", ".")
    for d in lst:
        devs.append((ver, d["name"], d["udid"]))

def score(name):
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
if not best or score(best[0][1]) >= 999:
    sys.exit("nenhum simulador " + kind)
print(best[0][2])
print(f"{best[0][1]} (iOS {best[0][0]})", file=sys.stderr)
