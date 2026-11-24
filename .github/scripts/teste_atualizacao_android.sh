#!/bin/bash
# N05 (auditoria de 17/11): atualização por cima da versão publicada no emulador, sem perder dados.
# Uso: teste_atualizacao_android.sh <apk-anterior> <apk-novo>   (os dois com a mesma chave fixa do app)
set -u
PKG=br.com.arque.measure; OLD=$1; NEW=$2; OUT0=atualizacao; mkdir -p $OUT0; FALHAS=0
falha(){ echo "FALHA: $*"; FALHAS=$((FALHAS+1)); }
adb wait-for-device; adb shell settings put global window_animation_scale 0 >/dev/null 2>&1
# 24/11 (auditoria final): a mesma sequência pra cada backup de referência, cada uma do zero (sem o app e sem as cópias em Download):
# o de sempre (tests/backup-referencia) e o rico gerado pelo editor publicado (tests/backup-referencia-rico).
rodada(){ ZIP=$1; MAN=$2; OUT=$OUT0/$3; mkdir -p $OUT; echo "######## backup $3"
adb uninstall $PKG >/dev/null 2>&1; adb shell rm -rf /sdcard/Download/ArqueMeasure >/dev/null 2>&1
echo "== 1. instala a versão anterior"; adb install -r "$OLD" || falha "não instalou a versão anterior"
V0=$(adb shell dumpsys package $PKG | grep -m1 versionCode | tr -s ' ' | cut -d' ' -f2 | cut -d= -f2); echo "versão anterior: $V0"
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 10; adb shell am force-stop $PKG
echo "== 2. põe os dados do backup de referência"
rm -rf ref && mkdir ref && unzip -q "$ZIP" -d ref
adb shell rm -rf /data/local/tmp/ref; (cd ref/files && find . -type f | sed 's#^\./##') > $OUT/lista.txt
# dentro do while, todo adb lê de /dev/null: senão ele come o resto da lista e só o 1º arquivo é tratado
while read -r rel; do adb shell mkdir -p "/data/local/tmp/ref/$(dirname "$rel")" </dev/null; adb push "ref/files/$rel" "/data/local/tmp/ref/$rel" </dev/null >/dev/null; done < $OUT/lista.txt
adb shell chmod -R a+rX /data/local/tmp/ref
# o adb shell junta os argumentos numa linha só: o comando vai inteiro numa string, com aspas simples por dentro
while read -r rel; do adb shell "run-as $PKG sh -c 'mkdir -p files/$(dirname "$rel") && cat /data/local/tmp/ref/$rel > files/$rel'" </dev/null || falha "não gravou $rel"; done < $OUT/lista.txt
hashes(){ while read -r rel; do echo "$(adb shell "run-as $PKG sha256sum files/$rel" </dev/null 2>/dev/null | cut -d' ' -f1)  $rel"; done < $OUT/lista.txt; }
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 12; adb shell am force-stop $PKG
hashes > $OUT/antes.txt; cat $OUT/antes.txt
adb logcat -c
echo "== 3. instala a versão nova por cima (sem desinstalar)"; adb install -r "$NEW" || falha "a versão nova não instalou por cima (assinatura?)"
V1=$(adb shell dumpsys package $PKG | grep -m1 versionCode | tr -s ' ' | cut -d' ' -f2 | cut -d= -f2); echo "versão nova: $V1"
# sai do app pelo botão Início (como a pessoa faz): é no onStop que o app grava as cópias em Download/ArqueMeasure.
# O force-stop direto mata o processo sem passar pelo onStop e a cópia nunca seria feita.
# N14 (24/11): a cópia "antes-de-usar" já tem que existir ao ABRIR a versão nova, antes de a pessoa usar e sair (antes só saía no onStop)
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 20
adb shell ls /sdcard/Download/ArqueMeasure/Projetos/ 2>/dev/null | tee $OUT/copias_ao_abrir.txt
grep -q "antes-de-usar-a-versao-$V1" $OUT/copias_ao_abrir.txt && echo "cópia antes-de-usar ao abrir (N14): ok" || falha "N14: ao abrir a versão nova ainda não existe a cópia antes-de-usar-a-versao-$V1"
adb shell input keyevent 3; sleep 15; adb shell am force-stop $PKG
hashes > $OUT/depois.txt
echo "== 4. confere"
diff $OUT/antes.txt $OUT/depois.txt && echo "arquivos iguais antes e depois: $(wc -l < $OUT/depois.txt)" || falha "arquivos mudaram ou sumiram na atualização"
grep -q '^  ' $OUT/depois.txt && falha "algum arquivo sumiu (sem hash)"
python3 - "$OUT/depois.txt" "$MAN" <<'PY' || FALHAS=$((FALHAS+1))
import json,sys
m=json.load(open(sys.argv[2]))['arquivos'];d={l.split()[1]:l.split()[0] for l in open(sys.argv[1]) if len(l.split())==2}
ruins=[k for k,h in m.items() if d.get(k)!=h]
print('iguais ao manifesto: %d de %d'%(len(m)-len(ruins),len(m)));ruins and print('FALHA: diferentes do manifesto:',ruins);sys.exit(1 if ruins else 0)
PY
adb shell ls /sdcard/Download/ArqueMeasure/Projetos/ 2>/dev/null | tee $OUT/copias.txt
grep -q "antes-de-usar-a-versao-$V1" $OUT/copias.txt && echo "cópia antes-de-usar-a-versao-$V1: ok" || falha "não achei a cópia antes-de-usar-a-versao-$V1"
adb logcat -d > $OUT/logcat.txt; grep -E "FATAL EXCEPTION|ANR in $PKG" -A3 $OUT/logcat.txt | grep -B1 -A3 "$PKG" | head -20 && grep -qE "FATAL EXCEPTION" $OUT/logcat.txt && grep -A2 "FATAL EXCEPTION" $OUT/logcat.txt | grep -q "$PKG" && falha "o app fechou com erro depois de atualizar"
}
rodada tests/backup-referencia/android-backup-referencia.zip tests/backup-referencia/manifesto.json referencia
rodada tests/backup-referencia-rico/backup-rico.zip tests/backup-referencia-rico/manifesto.json rico
# Vídeo do cliente (N13; auditoria final 24/11): o app PUBLICADO grava o vídeo pelo caminho do editor (aba Vídeos do cliente → seletor
# de arquivo #phv2 → phPut → ArqueApp.putVideo), sem simular a ponte; depois a versão nova instala por cima e o editor novo acha e toca.
# Entra no WebView pela depuração que o APK de teste (debug) já tem. O arquivo vai pra pasta do próprio app, que é de onde o app lê.
# Limite: o toque no botão abre a câmera do sistema (capture=environment); aqui o arquivo é entregue direto ao seletor, sem a câmera.
toca(){ for i in 1 2 3 4 5 6 7 8; do adb shell uiautomator dump /sdcard/ui.xml </dev/null >/dev/null 2>&1; adb pull /sdcard/ui.xml $OUT/ui.xml </dev/null >/dev/null 2>&1
XY=$(python3 - "$OUT/ui.xml" "$1" <<'PY'
import re,sys
try: s=open(sys.argv[1],encoding='utf-8').read()
except Exception: s=''
todos=[]
for m in re.finditer(r'<node [^>]*>',s):
    n=m.group(0);t=re.search(r' text="([^"]*)"',n);d=re.search(r'content-desc="([^"]*)"',n)
    alvos=sys.argv[2].split('|')
    if (t and t.group(1) in alvos) or (d and d.group(1) in alvos):
        b=re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"',n);x1,y1,x2,y2=map(int,b.groups());todos.append(((x1+x2)//2,(y1+y2)//2))
# no app publicado "3D Projector" aparece no cartão e na barra de baixo: TOCA_IDX escolhe (padrão: o último)
import os
if todos: print(*todos[int(os.environ.get('TOCA_IDX','-1'))])
PY
)
if [ -n "$XY" ]; then adb shell input tap $XY </dev/null; echo "toquei \"$1\" em $XY"; sleep 2; return 0; fi; sleep 3; done
echo "não achei \"$1\" na tela; textos na tela: $(grep -o 'text="[^"]\+"' $OUT/ui.xml 2>/dev/null | head -25 | tr '\n' ' ')"; adb exec-out screencap -p > "$OUT/sem_$(echo "$1" | tr -c 'a-zA-Z0-9' _).png" 2>/dev/null; return 1; }
abre_cdp(){ for i in $(seq 1 20); do SOCK=$(adb shell grep -ao 'webview_devtools_remote_[0-9]*' /proc/net/unix </dev/null | head -1 | tr -d '\r'); [ -n "$SOCK" ] && break; sleep 2; done
[ -z "$SOCK" ] && { echo "o WebView do editor não abriu a depuração"; return 1; }
adb forward --remove tcp:9333 >/dev/null 2>&1; adb forward tcp:9333 localabstract:$SOCK >/dev/null && echo "depuração do editor: $SOCK"; }
sha_video(){ N=$(adb exec-out run-as $PKG sh -c 'ls files/moveis/ 2>/dev/null' | grep -c '^video_.*\.json$'); if [ "$N" != 1 ]; then echo "arquivos de vídeo: $N" >&2; return; fi
adb exec-out run-as $PKG sh -c 'cat files/moveis/video_*.json' | python3 -c "import json,sys,base64,hashlib;v=json.load(sys.stdin)['videoData'];print(hashlib.sha256(base64.b64decode(v.split(',',1)[1])).hexdigest())"; }
abre_editor(){ for ix in -1 0; do TOCA_IDX=$ix toca "Novo Projetor 3D|New 3D Projector|Projetor 3D|3D Projector" || return 1; sleep 8
  echo "tela depois do toque: $(adb shell uiautomator dump /sdcard/ui.xml </dev/null >/dev/null 2>&1; adb exec-out cat /sdcard/ui.xml | grep -o 'text="[^"]\+"' | head -15 | tr '\n' ' ')"
  echo "sockets de depuração: $(adb shell cat /proc/net/unix </dev/null | grep -ao '@[a-z_]*devtools[a-z_0-9]*' | tr '\n' ' ')"
  abre_cdp && return 0; adb shell input keyevent 4 </dev/null; sleep 3; done; return 1; }
rodada_video(){ VID=$1; OUT=$OUT0/video; mkdir -p $OUT; echo "######## vídeo gravado pelo app publicado"
python3 -m pip install --quiet websocket-client >/dev/null 2>&1 || pip install --quiet websocket-client
ESP=$(sha256sum "$VID" | cut -d' ' -f1); echo "vídeo de teste: $VID · sha256 $ESP"
adb uninstall $PKG >/dev/null 2>&1; adb shell rm -rf /sdcard/Download/ArqueMeasure >/dev/null 2>&1
echo "== 1. instala a versão anterior e grava o vídeo nela"; adb install -r "$OLD" || falha "não instalou a versão anterior"
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 8
toca "Começar agora|Start now|Pular|Skip" || true
abre_editor || falha "não abri o editor de móveis na versão anterior"
adb push "$VID" /data/local/tmp/video-teste.webm >/dev/null; adb shell chmod a+r /data/local/tmp/video-teste.webm
adb shell "run-as $PKG sh -c 'mkdir -p cache && cat /data/local/tmp/video-teste.webm > cache/video-teste.webm'" || falha "não pus o vídeo na pasta do app"
DIRAPP=$(adb shell "run-as $PKG pwd" | tr -d '\r')
python3 .github/scripts/video_cdp.py gravar --cdp http://127.0.0.1:9333 --video "$VID" --caminho "$DIRAPP/cache/video-teste.webm" || falha "o app publicado não gravou o vídeo"
adb exec-out screencap -p > $OUT/1_gravado_na_versao_anterior.png 2>/dev/null
adb shell input keyevent 3; sleep 5; adb shell am force-stop $PKG
S0=$(sha_video); echo "vídeo no arquivo do app (antes): $S0"; [ "$S0" = "$ESP" ] || falha "o arquivo de vídeo do app publicado não tem o vídeo gravado"
adb exec-out run-as $PKG sh -c 'cd files && find . -type f' | sed 's#^\./##' | grep -v '^\s*$' > $OUT/lista.txt
hashes > $OUT/antes.txt; cat $OUT/antes.txt
echo "== 2. instala a versão nova por cima (sem desinstalar)"; adb install -r "$NEW" || falha "a versão nova não instalou por cima"
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 20; adb shell input keyevent 3; sleep 10; adb shell am force-stop $PKG
hashes > $OUT/depois.txt
diff $OUT/antes.txt $OUT/depois.txt && echo "arquivos iguais antes e depois: $(wc -l < $OUT/depois.txt)" || falha "arquivos mudaram ou sumiram na atualização (vídeo)"
S1=$(sha_video); echo "vídeo no arquivo do app (depois): $S1"; [ "$S1" = "$ESP" ] || falha "o vídeo mudou ou sumiu na atualização"
echo "== 3. o editor novo acha e toca o vídeo"
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 8
abre_editor || falha "não abri o editor de móveis na versão nova"
python3 .github/scripts/video_cdp.py conferir --cdp http://127.0.0.1:9333 --video "$VID" || falha "o editor novo não achou ou não tocou o vídeo"
adb exec-out screencap -p > $OUT/2_na_versao_nova.png 2>/dev/null
adb shell am force-stop $PKG
}
rodada_video tests/backup-referencia-rico/video-teste.webm
echo "RESULTADO: versão $V0 → $V1 · falhas $FALHAS"; exit $FALHAS
