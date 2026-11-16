#!/usr/bin/env python3
"""Persistência entre sessões: roda s28a, leva os arquivos e o navegador pra uma sessão nova (s28b) e compara."""
import json, os, subprocess, sys, tempfile
H = os.path.dirname(os.path.abspath(__file__)); url = sys.argv[1] if len(sys.argv) > 1 else 'http://127.0.0.1:8765/editor.html?lang=pt'; porta = sys.argv[2] if len(sys.argv) > 2 else '9334'
run = lambda js, seed=None: json.loads(subprocess.run([sys.executable, os.path.join(H, 'rodar.py'), os.path.join(H, js), '--porta', porta, '--url', url] + (['--semente', seed] if seed else []), capture_output=True, text=True).stdout)
a = run('s28a_sessao1_mexer_duplicar.js')
seed = tempfile.NamedTemporaryFile('w', suffix='.js', delete=False)
seed.write(';(function(){var f=%s;for(var k in f)__files[k]=f[k];localStorage.setItem("arque.projects.v1",%s)})();' % (a['files'], json.dumps(a['ls'])))
seed.close()
b = run('s28b_sessao2_reabrir.js', seed.name)
for k in ('files', 'ls'): a.pop(k)
print(json.dumps({'sessao1': a, 'sessao2': b, 'mesmasMedidas': a['dims'] == b['dims']}, ensure_ascii=False, indent=1))
