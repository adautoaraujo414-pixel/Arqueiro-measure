"""Abre o Arquemestre instalado em modo de teste (ARQUE_TOUR) e confere o relatório."""
import json, os, subprocess, sys, time

exe, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
env = dict(os.environ, ARQUE_TOUR=os.path.abspath(out))
t0 = time.time()
p = subprocess.Popen([exe], env=env)
rep = os.path.join(out, 'report.json')
while time.time() - t0 < 900:
    if os.path.exists(rep) and p.poll() is not None:
        break
    if p.poll() is not None and not os.path.exists(rep):
        time.sleep(3)
        break
    time.sleep(2)
if p.poll() is None:
    time.sleep(20)
    if p.poll() is None:
        p.kill()
        print('o app não fechou sozinho no fim do teste')
print('tempo', round(time.time() - t0), 's · saída', p.returncode)
if not os.path.exists(rep):
    print('sem report.json: o app não chegou ao fim do teste')
    sys.exit(1)
r = json.load(open(rep, encoding='utf-8'))
for s in r['passos']:
    print(('OK   ' if s['ok'] else 'FALHA') + ' ' + s['passo'] + (' · ' + s['detalhe'][:300] if s['detalhe'] else ''))
print('FALHAS', r['falhas'])
sys.exit(1 if r['falhas'] else 0)
