#!/usr/bin/env python3
"""Bateria do editor de móveis rodando dentro de um navegador de verdade, pela porta de depuração (CDP).

São os MESMOS testes do iOS (ios/ArquemestreTests/EditorWebKitTests.swift): o JavaScript de cada teste roda
na página do editor e o resultado é conferido com os mesmos valores esperados. Serve pra conferir que o editor
dá o mesmo resultado no motor do Windows (o Chromium embutido no Arquemestre) que dá no iOS e no Android.

No Windows (GitHub Actions): o Arquemestre é aberto com ARQUE_BATERIA=1 (abre direto no editor e espera)
e ARQUE_CDP_PORT=9333; depois:
    python tools/bateria_editor.py --cdp http://127.0.0.1:9333 --saida bateria-windows

Não grava nada nos dados do app: os testes usam uma ponte "ArqueApp" em memória (igual à do teste do iOS).
Precisa do pacote websocket-client (pip install websocket-client).
"""
import argparse, json, os, re, sys, time, urllib.request

PONTE = r"""
/* cada teste começa sem nada guardado do teste anterior (ao sair da página o editor grava o que estava pendente) */
try{localStorage.clear();sessionStorage.clear()}catch(e){}
window.__noSetup=1;window.__errs=[];
window.addEventListener('error',function(e){__errs.push(String(e.message||e))});
window.addEventListener('unhandledrejection',function(e){__errs.push('promise: '+String(e.reason))});
window.__files={};window.__shared=null;
(function(){var A={isApp:function(){return true},isWindows:function(){return true},isViewer:function(){return false},isSharing:function(){return false},setCurrent:function(){},
  putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},
  listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},
  shareCut:function(c,n,t){__shared={code:c,name:n,title:t}},shareClient:function(c,n,t){window.__sharedCl={code:c,name:n,title:t}},listNotes:function(){return '[]'},
  contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){},shareUpdate:function(){},shareStart:function(){},
  makeQuote:function(){},quotePhotos:function(){},openTrena:function(){},tourResult:function(){},close:function(){window.__closed=(window.__closed||0)+1}};
  /* a ponte de verdade do app (que grava em arquivo) é posta depois: aqui ela é ignorada, os testes ficam só na memória */
  try{Object.defineProperty(window,'ArqueApp',{configurable:true,get:function(){return A},set:function(){}})}catch(e){window.ArqueApp=A}})();
"""


def testes(swift):
    src = open(swift, encoding='utf-8').read()
    partes = re.split(r'\n    func (test\w+)\(\)', src)
    out = []
    for i in range(1, len(partes), 2):
        nome, corpo = partes[i], partes[i + 1]
        m = re.search(r'run\(web, #"""\n(.*?)\n\s*"""#\)', corpo, re.S)
        if m:
            out.append((nome, m.group(1), corpo))
    return out


def confere(corpo, o):
    """Confere o resultado com os XCTAssert do teste. Devolve a lista de falhas (vazia = passou)."""
    f = []
    for m in re.finditer(r'XCTAssertEqual\(o\["(\w+)"\] as\? (\w+)(?:\?\.(\w+))?(?: \?\? [^,()]+)?, ("(?:[^"\\]|\\.)*"|true|false|-?[\d.]+)[,)]', corpo):
        k, _ty, _conv, exp = m.groups()
        if exp.startswith('"') and '\\(' in exp:
            continue  # valor esperado montado com outro campo: conferido só no iOS
        if k not in o:
            f.append('%s: faltou no resultado' % k); continue
        v = o[k]
        if exp.startswith('"'):
            try: e = json.loads(exp)
            except Exception: e = exp[1:-1].replace('\\"', '"').replace('\\\\', '\\')
            ok = (not isinstance(v, bool)) and str(v) == e
        elif exp in ('true', 'false'):
            ok = v is (exp == 'true')
        else:
            try: ok = abs(float(v) - float(exp)) < 1e-6
            except Exception: ok = False
        if not ok:
            f.append('%s: veio %s · esperado %s' % (k, json.dumps(v, ensure_ascii=False)[:200], exp[:200]))
    for m in re.finditer(r'XCTAssert(LessThanOrEqual|LessThan|GreaterThanOrEqual|GreaterThan)\(o\["(\w+)"\] as\? \w+(?: \?\? [^,()]+)?, (-?[\d.]+)[,)]', corpo):
        op, k, exp = m.groups()
        if k not in o:
            f.append('%s: faltou no resultado' % k); continue
        try:
            v, e = float(o[k]), float(exp)
            ok = {'LessThanOrEqual': v <= e, 'LessThan': v < e, 'GreaterThanOrEqual': v >= e, 'GreaterThan': v > e}[op]
        except Exception:
            ok = False
        if not ok:
            f.append('%s: veio %s · esperado %s %s' % (k, json.dumps(o[k], ensure_ascii=False)[:80], op, exp))
    for m in re.finditer(r'XCTAssertEqual\(o\["(\w+)"\] as\? \w+, o\["(\w+)"\] as\? \w+', corpo):
        a, b = m.groups()
        if a not in o or b not in o:
            f.append('%s/%s: faltou no resultado' % (a, b)); continue
        if o[a] != o[b]:
            f.append('%s diferente de %s' % (a, b))
    for m in re.finditer(r'XCTAssert(True|False)\(\(o\["(\w+)"\] as\? String \?\? ""\)\.contains\(("(?:[^"\\]|\\.)*")\)', corpo):
        tf, k, exp = m.groups()
        if '\\(' in exp:
            continue
        if k not in o:
            f.append('%s: faltou no resultado' % k); continue
        try: e = json.loads(exp)
        except Exception: e = exp[1:-1]
        if (e in str(o[k])) != (tf == 'True'):
            f.append('%s: %s %s · veio %s' % (k, 'devia ter' if tf == 'True' else 'não devia ter', exp[:80], json.dumps(o[k], ensure_ascii=False)[:120]))
    for m in re.finditer(r'XCTAssert(True|False)\(o\["(\w+)"\] as\? Bool (?:\?\? (?:true|false)|== (true|false))', corpo):
        tf, k, eq = m.groups()
        if k not in o:
            f.append('%s: faltou no resultado' % k); continue
        quer = (tf == 'True') if eq in (None, 'true') else (tf != 'True')
        if o[k] is not quer:
            f.append('%s: veio %s · esperado %s' % (k, json.dumps(o[k]), 'true' if quer else 'false'))
    return f


class Cdp:
    def __init__(self, ws_url):
        import websocket
        self.ws = websocket.create_connection(ws_url, timeout=30, suppress_origin=True)
        self.n = 0
        self.eventos = []

    def chama(self, metodo, params=None, espera=60):
        self.n += 1
        meu = self.n
        self.ws.send(json.dumps({'id': meu, 'method': metodo, 'params': params or {}}))
        fim = time.time() + espera
        while True:
            resta = fim - time.time()
            if resta <= 0:
                raise TimeoutError(metodo)
            self.ws.settimeout(max(0.5, min(resta, 30)))
            try:
                msg = json.loads(self.ws.recv())
            except Exception as e:
                if 'timed out' in str(e).lower():
                    continue
                raise
            if msg.get('id') == meu:
                if 'error' in msg:
                    raise RuntimeError('%s: %s' % (metodo, msg['error'].get('message')))
                return msg.get('result', {})
            if 'method' in msg:
                self.eventos.append(msg)

    def espera_evento(self, nome, espera=60):
        fim = time.time() + espera
        while time.time() < fim:
            for i, e in enumerate(self.eventos):
                if e.get('method') == nome:
                    del self.eventos[: i + 1]
                    return True
            self.ws.settimeout(max(0.5, min(fim - time.time(), 5)))
            try:
                msg = json.loads(self.ws.recv())
                if 'method' in msg:
                    self.eventos.append(msg)
            except Exception as e:
                if 'timed out' not in str(e).lower():
                    raise
        return False


def pagina(cdp_http, espera=240):
    """Acha a página do editor na porta de depuração (espera o app abrir)."""
    fim = time.time() + espera
    ultimo = ''
    while time.time() < fim:
        try:
            alvos = json.load(urllib.request.urlopen(cdp_http.rstrip('/') + '/json', timeout=5))
            for a in alvos:
                if a.get('type') == 'page' and 'editor.html' in a.get('url', '') and a.get('webSocketDebuggerUrl'):
                    return a
            ultimo = ', '.join(a.get('url', '')[:60] for a in alvos)
        except Exception as e:
            ultimo = str(e)
        time.sleep(2)
    raise SystemExit('não achei a página do editor na porta de depuração: ' + ultimo)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--cdp', default='http://127.0.0.1:9333')
    ap.add_argument('--swift', default=os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'ios', 'ArquemestreTests', 'EditorWebKitTests.swift'))
    ap.add_argument('--saida', default='bateria')
    ap.add_argument('--so', default='', help='só os testes cujo nome casa com esta expressão')
    ap.add_argument('--url', default='', help='endereço do editor (padrão: o que o app abriu, em português)')
    ap.add_argument('--tempo', type=int, default=300, help='limite por teste, em segundos')
    ap.add_argument('--janela', default='1366x768', help='tamanho da área do editor nos testes (notebook comum); vazio = o tamanho real da janela')
    a = ap.parse_args()
    os.makedirs(a.saida, exist_ok=True)
    T = [t for t in testes(a.swift) if not a.so or re.search(a.so, t[0])]
    print('testes:', len(T), flush=True)
    alvo = pagina(a.cdp)
    time.sleep(6)  # o app ainda manda o "projeto novo" pra página que acabou de abrir: espera passar antes do 1º teste
    url = a.url or (alvo['url'].split('?')[0] + '?lang=pt')
    origem = re.match(r'^[a-z]+://[^/]*', url)
    c = Cdp(alvo['webSocketDebuggerUrl'])
    c.chama('Page.enable'); c.chama('Runtime.enable')
    c.chama('Page.addScriptToEvaluateOnNewDocument', {'source': PONTE})
    if a.janela:
        # mesma área em qualquer computador de teste (a tela do GitHub é pequena: 1024×768)
        try:
            w, h = [int(x) for x in a.janela.lower().split('x')]
            c.chama('Emulation.setDeviceMetricsOverride', {'width': w, 'height': h, 'deviceScaleFactor': 0, 'mobile': False}, 20)
        except Exception as e:
            print('não deu pra fixar o tamanho da área (%s): os testes usam o tamanho real da janela' % str(e)[:120], flush=True)
    info = {}
    falhas, passou, rel, sem3d = [], 0, [], []
    usa3d = re.compile(r'open3D|org3api|__cam\(|__boxes|re3\(|fx3api|ah3api|paintTap|__sel3|__size3|tap3|demoScene|v3x|#v3')
    t00 = time.time()
    for nome, js, corpo in T:
        t0 = time.time()
        res, erro = None, ''
        try:
            # cada teste começa do zero: página nova e nada guardado do teste anterior
            try: c.chama('Runtime.evaluate', {'expression': 'try{localStorage.clear();sessionStorage.clear()}catch(e){}', 'returnByValue': True}, 20)
            except Exception: pass
            if origem:
                try: c.chama('Storage.clearDataForOrigin', {'origin': origem.group(0), 'storageTypes': 'local_storage,indexeddb,cache_storage'}, 20)
                except Exception: pass
            c.eventos = []
            c.chama('Page.navigate', {'url': url}, 60)
            if not c.espera_evento('Page.loadEventFired', 90):
                raise TimeoutError('a página não carregou')
            time.sleep(1.5)
            if not info:
                r = c.chama('Runtime.evaluate', {'expression': "JSON.stringify({ua:navigator.userAgent,janela:innerWidth+'x'+innerHeight,escala:devicePixelRatio,editor:typeof S,ponte:!!(window.ArqueApp&&ArqueApp.isApp()),webgl:(function(){try{var t=document.createElement('canvas');return !!(t.getContext('webgl')||t.getContext('experimental-webgl'))}catch(e){return false}})()})", 'returnByValue': True}, 30)
                info = json.loads(r['result']['value'])
                print('motor:', json.dumps(info, ensure_ascii=False), flush=True)
            r = c.chama('Runtime.evaluate', {'expression': '(async()=>{' + js + '\n})()', 'awaitPromise': True, 'returnByValue': True}, a.tempo)
            if r.get('exceptionDetails'):
                ex = r['exceptionDetails']
                erro = 'erro no JS: ' + str((ex.get('exception') or {}).get('description') or ex.get('text'))[:300]
            else:
                res = r['result'].get('value')
        except Exception as e:
            erro = 'não terminou: %s' % str(e)[:200]
        f = []
        o = None
        if erro:
            f = [erro]
        else:
            try:
                o = json.loads(res)
                f = confere(corpo, o)
            except Exception as e:
                f = ['resultado não é JSON: %s' % str(res)[:200]]
        dt = round(time.time() - t0, 1)
        open(os.path.join(a.saida, nome + '.json'), 'w', encoding='utf-8').write(res if isinstance(res, str) else json.dumps({'erro': erro}, ensure_ascii=False))
        if f and info and not info.get('webgl') and usa3d.search(js):
            # este computador de teste não tem WebGL: o 3D não abre aqui (não é defeito do editor); fica anotado à parte
            sem3d.append(nome)
            print('sem3D %s (%ss)' % (nome, dt), flush=True)
            rel.append({'teste': nome, 'ok': None, 'segundos': dt, 'falhas': f, 'sem3d': True})
            continue
        if f:
            falhas.append((nome, f))
            print('FALHA %s (%ss)' % (nome, dt), flush=True)
            for x in f[:8]:
                print('     ' + x, flush=True)
        else:
            passou += 1
            print('ok    %s (%ss)' % (nome, dt), flush=True)
        rel.append({'teste': nome, 'ok': not f, 'segundos': dt, 'falhas': f})
    tot = round(time.time() - t00)
    json.dump({'motor': info, 'testes': len(T), 'passaram': passou, 'falharam': len(falhas), 'sem3d': len(sem3d), 'segundos': tot, 'lista': rel}, open(os.path.join(a.saida, 'relatorio.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('\nBATERIA DO EDITOR · %d testes · passaram %d · falharam %d%s · %d s' % (len(T), passou, len(falhas), (' · %d não conferidos (precisam do 3D e este computador de teste não tem WebGL)' % len(sem3d)) if sem3d else '', tot), flush=True)
    for nome, f in falhas:
        print('  FALHA ' + nome + ': ' + ' | '.join(f[:3]), flush=True)
    sys.exit(1 if falhas else 0)


if __name__ == '__main__':
    main()
