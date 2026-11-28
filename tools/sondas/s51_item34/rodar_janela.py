#!/usr/bin/env python3
"""Roda uma sonda de auditoria dentro do editor (Chromium com --remote-debugging-port).
Só leitura: usa a ponte "ArqueApp" em memória da bateria (tools/bateria_editor.py). Nada é gravado nos dados do app.

  python3 -m http.server 8765 --bind 127.0.0.1   (na pasta app/src/main/assets)
  chrome --headless=new --remote-debugging-port=9334 --use-angle=swiftshader --enable-unsafe-swiftshader about:blank
  python3 tools/sondas/rodar.py tools/sondas/s11_rastreio_ida_e_volta.js [--semente arquivo.js]

Sondas com __TRACER__ recebem tools/sondas/rastreador.js no lugar.
s08a precisa de --semente vazio (ver semente_arquivo_vazio.js) e s08b de um projeto salvo como semente (ver o relatório).
"""
import argparse, json, os, re, sys, time, urllib.request, websocket
H = '/home/user/Arqueiro-measure/tools/sondas'
ap = argparse.ArgumentParser(); ap.add_argument('sonda'); ap.add_argument('--porta', default='9334'); ap.add_argument('--url', default='http://127.0.0.1:8765/editor.html?lang=pt'); ap.add_argument('--semente', default='')
a = ap.parse_args()
js = open(a.sonda, encoding='utf-8').read().replace('__TRACER__', open(os.path.join(H, 'rastreador.js'), encoding='utf-8').read())
ponte = re.search(r'PONTE = r"""(.*?)"""', open(os.path.join(H, '..', 'bateria_editor.py'), encoding='utf-8').read(), re.S).group(1)
if a.semente: ponte += '\n' + open(a.semente, encoding='utf-8').read()
t = [x for x in json.load(urllib.request.urlopen('http://127.0.0.1:%s/json' % a.porta)) if x['type'] == 'page'][0]
ws = websocket.create_connection(t['webSocketDebuggerUrl'], timeout=3600, suppress_origin=True); n = [0]
def call(m, p={}):
    n[0] += 1; ws.send(json.dumps({'id': n[0], 'method': m, 'params': p}))
    while True:
        r = json.loads(ws.recv())
        if r.get('id') == n[0]: return r
call('Page.enable'); call('Runtime.enable'); call('Page.addScriptToEvaluateOnNewDocument', {'source': ponte})
J=os.environ.get('JANELA','1366x768').split('x');call('Emulation.setDeviceMetricsOverride', {'width': int(J[0]), 'height': int(J[1]), 'deviceScaleFactor': 0, 'mobile': int(J[0])<600})
call('Page.navigate', {'url': a.url}); time.sleep(8)
r = call('Runtime.evaluate', {'expression': '(async()=>{' + js + '\n})()', 'awaitPromise': True, 'returnByValue': True})
v = r.get('result', {}).get('result', {}).get('value')
print(json.dumps(json.loads(v), ensure_ascii=False, indent=1) if v else json.dumps(r, ensure_ascii=False)[:3000])
