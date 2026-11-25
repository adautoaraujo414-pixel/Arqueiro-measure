#!/usr/bin/env python3
# shot.py <pasta do editor> <arquivo js> <saida.png> <LxAxD> <porta>
# abre o editor no Chromium, roda o js (async, pode usar await) e tira o print da tela
import sys,json,time,subprocess,os,base64,urllib.request,glob,websocket,tempfile
ed,jsf,out,jan,port=sys.argv[1:6];L,A,D=(jan.split('x')+['1'])[:3]
hp=int(port);cp=hp+700
srv=subprocess.Popen(['python3','-m','http.server',str(hp)],cwd=ed,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
ch=glob.glob('/opt/pw-browsers/chromium-*/chrome-linux64/chrome')[0]
br=subprocess.Popen([ch,'--headless=new','--no-sandbox',f'--remote-debugging-port={cp}',f'--user-data-dir={tempfile.mkdtemp()}','--use-angle=swiftshader','--enable-unsafe-swiftshader','--window-size=1366,900',f'http://127.0.0.1:{hp}/editor.html?lang=pt&nc={time.time()}'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
try:
  time.sleep(4)
  t=[x for x in json.load(urllib.request.urlopen(f'http://127.0.0.1:{cp}/json')) if x['type']=='page'][0]
  ws=websocket.create_connection(t['webSocketDebuggerUrl'],timeout=180);n=[0]
  def c(m,p=None):
    n[0]+=1;ws.send(json.dumps({'id':n[0],'method':m,'params':p or {}}))
    while True:
      r=json.loads(ws.recv())
      if r.get('id')==n[0]: return r
  c('Emulation.setDeviceMetricsOverride',{'width':int(L),'height':int(A),'deviceScaleFactor':float(D),'mobile':os.environ.get('MOB','1')=='1'})
  ponte=open('/home/user/Arqueiro-measure/tools/bateria_editor.py').read().split('PONTE = r"""')[1].split('"""')[0]
  c('Page.addScriptToEvaluateOnNewDocument',{'source':ponte})
  c('Page.enable');c('Page.navigate',{'url':f'http://127.0.0.1:{hp}/editor.html?lang=pt&x={time.time()}'});time.sleep(6)
  for _ in range(30):
    v=c('Runtime.evaluate',{'expression':'typeof initLimpo','returnByValue':True})['result']['result'].get('value')
    if v=='function': break
    time.sleep(1)
  print('initLimpo',v)
  r=c('Runtime.evaluate',{'expression':'(async function(){'+open(jsf).read()+'})()','awaitPromise':True,'returnByValue':True})
  print(json.dumps(r.get('result',{}).get('result',{}).get('value'),ensure_ascii=False)[:1500])
  if 'exceptionDetails' in r.get('result',{}): print('ERRO',r['result']['exceptionDetails'].get('exception',{}).get('description','')[:400])
  time.sleep(.5);img=c('Page.captureScreenshot',{'format':'png'})['result']['data'];open(out,'wb').write(base64.b64decode(img))
finally:
  br.kill();srv.kill()
