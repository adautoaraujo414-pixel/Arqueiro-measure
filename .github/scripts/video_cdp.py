"""Vídeo do cliente na atualização (N13; auditoria final 24/11).

Entra no app do Windows pela porta de depuração (como a windows-bateria) e usa o caminho real do editor:
lista de clientes (📋) → "📷 Fotos e obra" → aba "Vídeos" → o seletor de arquivo (#phv2) recebe o arquivo.
Nada da ponte é simulado: quem grava é o próprio app (phPut → EditorMediaBackup → ArqueApp.putVideo).

  python video_cdp.py gravar   --cdp http://127.0.0.1:9333 --video tests/backup-referencia-rico/video-teste.webm
  python video_cdp.py conferir --cdp http://127.0.0.1:9333 --video tests/backup-referencia-rico/video-teste.webm

Sai com 0 quando deu certo; imprime o que viu.
"""
import argparse, hashlib, json, os, sys, time, urllib.request

import websocket


def alvo(cdp, limite=90):
    fim = time.time() + limite
    while time.time() < fim:
        try:
            for t in json.load(urllib.request.urlopen(cdp + '/json/list', timeout=5)):
                if t.get('type') == 'page' and 'editor' in t.get('url', '') and t.get('webSocketDebuggerUrl'):
                    return t['webSocketDebuggerUrl']
        except Exception:
            pass
        time.sleep(2)
    raise SystemExit('FALHA: o editor não abriu na porta de depuração')


class Pagina:
    def __init__(self, ws_url):
        self.ws = websocket.create_connection(ws_url, timeout=120, suppress_origin=True)
        self.n = 0

    def cmd(self, metodo, **p):
        self.n += 1
        self.ws.send(json.dumps({'id': self.n, 'method': metodo, 'params': p}))
        while True:
            r = json.loads(self.ws.recv())
            if r.get('id') == self.n:
                if 'error' in r:
                    raise RuntimeError(metodo + ': ' + json.dumps(r['error']))
                return r.get('result', {})

    def js(self, expr):
        r = self.cmd('Runtime.evaluate', expression='(async()=>{' + expr + '})()', awaitPromise=True, returnByValue=True)
        if r.get('exceptionDetails'):
            raise RuntimeError('js: ' + json.dumps(r['exceptionDetails'])[:400])
        return r.get('result', {}).get('value')

    def espera(self, expr, limite=60):
        fim = time.time() + limite
        while time.time() < fim:
            try:
                if self.js('return !!(' + expr + ')'):
                    return True
            except Exception:
                pass
            time.sleep(1)
        return False


VIDEOS = ("return await new Promise(function(r){try{phAll(function(X){r(JSON.stringify((X||[]).filter(function(o){return o.kind==='video'})"
          ".map(function(o){return {id:o.id,pid:o.pid,nome:o.nome,tem:!!o.blob,tam:o.blob?o.blob.size:0}})))})}catch(e){r('ERRO '+e)}})")


def main():
    a = argparse.ArgumentParser()
    a.add_argument('acao', choices=['gravar', 'conferir'])
    a.add_argument('--cdp', default='http://127.0.0.1:9333')
    a.add_argument('--video', required=True)
    a.add_argument('--caminho', help='onde o app enxerga o arquivo (no Android, a pasta do próprio app); padrão: o --video')
    o = a.parse_args()
    dados = open(o.video, 'rb').read()
    sha = hashlib.sha256(dados).hexdigest()
    nome = os.path.basename(o.caminho or o.video)
    p = Pagina(alvo(o.cdp))
    if not p.espera("typeof phPut==='function'&&typeof phAll==='function'&&document.getElementById('clb')", 90):
        raise SystemExit('FALHA: o editor não ficou pronto')
    time.sleep(4)
    print('editor:', p.js("return location.href.split('?')[0]+' · ArqueApp.putVideo '+(!!(window.ArqueApp&&ArqueApp.putVideo))"))
    falhas = 0
    if o.acao == 'gravar':
        # o projeto novo do modo de teste entra na lista de clientes pelo salvamento de sempre
        # cliente do vídeo: o projeto aberto, ou um cliente novo pelo "novo cliente" do próprio editor quando a lista está vazia
        print('cliente:', p.js("try{if(!pLoadAll().length&&typeof newProjFor==='function')newProjFor({nome:'Cliente vídeo',end:'',cidade:'',tel:''});saveNow()}catch(e){return 'erro '+e}"
                               "return CUR+' · clientes '+pLoadAll().length"))
        time.sleep(1)
        print('lista:', p.js("document.getElementById('clb').click();await new Promise(function(r){setTimeout(r,600)});"
                             "var b=document.querySelector('#clm [data-pph=\"'+CUR+'\"]')||document.querySelector('#clm [data-pph]');"
                             "if(!b)return 'sem o botão Fotos e obra';var id=b.dataset.pph;b.click();await new Promise(function(r){setTimeout(r,600)});"
                             "var k=document.querySelector('#phm [data-phk=\"video\"]');if(!k)return 'sem a aba Vídeos';k.click();"
                             "await new Promise(function(r){setTimeout(r,600)});return 'cliente '+id+' · seletor '+!!document.getElementById('phv2')"))
        doc = p.cmd('DOM.getDocument', depth=1)
        no = p.cmd('DOM.querySelector', nodeId=doc['root']['nodeId'], selector='#phv2').get('nodeId')
        if not no:
            raise SystemExit('FALHA: o seletor de vídeo (#phv2) não apareceu')
        p.cmd('DOM.setFileInputFiles', nodeId=no, files=[o.caminho or os.path.abspath(o.video)])
        fim = time.time() + 60
        vs = []
        while time.time() < fim:
            vs = json.loads(p.js(VIDEOS) or '[]')
            if any(v.get('nome') == nome for v in vs):
                break
            time.sleep(1)
        print('vídeos no editor:', json.dumps(vs))
        if not any(v.get('nome') == nome and v.get('tam') == len(dados) for v in vs):
            print('FALHA: o vídeo não foi gravado pelo editor'); falhas += 1
        time.sleep(3)
        print('arquivos do app:', p.js("try{return ArqueApp.listFiles()}catch(e){return 'erro '+e}"))
    else:
        time.sleep(6)  # o EditorMediaBackup traz de volta os video_*.json que não estiverem no banco do editor
        vs = json.loads(p.js(VIDEOS) or '[]')
        print('vídeos no editor:', json.dumps(vs))
        v = [x for x in vs if x.get('nome') == nome]
        if not v:
            print('FALHA: o editor novo não achou o vídeo'); falhas += 1
        else:
            r = json.loads(p.js(
                "var id=" + json.dumps(v[0]['id']) + ";var o=await new Promise(function(r){phAll(function(X){r((X||[]).filter(function(q){return q.id===id})[0])})});"
                "var buf=await o.blob.arrayBuffer();var h=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',buf))).map(function(b){return b.toString(16).padStart(2,'0')}).join('');"
                "var el=document.createElement('video');el.muted=true;el.src=URL.createObjectURL(o.blob);document.body.appendChild(el);"
                "var toca=await new Promise(function(r){var t=setTimeout(function(){r('sem resposta em 20 s')},20000);el.onerror=function(){clearTimeout(t);r('erro '+(el.error&&el.error.code))};"
                "el.oncanplay=function(){el.play().then(function(){setTimeout(function(){clearTimeout(t);r('tocou até '+el.currentTime.toFixed(2)+' s de '+el.duration.toFixed(2)+' s')},800)},function(e){clearTimeout(t);r('play recusado '+e)})}});"
                "el.remove();return JSON.stringify({sha:h,tam:buf.byteLength,tipo:o.blob.type,toca:toca})"))
            print('vídeo no editor novo:', json.dumps(r, ensure_ascii=False))
            if r['sha'] != sha:
                print('FALHA: o vídeo mudou (sha %s, esperado %s)' % (r['sha'], sha)); falhas += 1
            else:
                print('vídeo igual byte a byte ao original: %d bytes, sha256 %s' % (r['tam'], sha))
            if not r['toca'].startswith('tocou'):
                print('FALHA: o vídeo não tocou: ' + r['toca']); falhas += 1
            na = p.js("document.getElementById('clb').click();await new Promise(function(r){setTimeout(r,600)});"
                      "var b=document.querySelector('#clm [data-pph=\"'+" + json.dumps(v[0]['pid']) + "+'\"]');if(!b)return 'cliente do vídeo não está na lista';b.click();"
                      "await new Promise(function(r){setTimeout(r,600)});var k=document.querySelector('#phm [data-phk=\"video\"]');if(k)k.click();"
                      "await new Promise(function(r){setTimeout(r,1200)});return 'na aba Vídeos: '+document.querySelectorAll('#phm video').length+' vídeo(s)'")
            print('tela:', na)
            if not str(na).startswith('na aba') or str(na).startswith('na aba Vídeos: 0'):
                print('FALHA: o vídeo não aparece na aba Vídeos do cliente'); falhas += 1
    print('RESULTADO vídeo (%s): falhas %d' % (o.acao, falhas))
    sys.exit(falhas)


if __name__ == '__main__':
    main()
