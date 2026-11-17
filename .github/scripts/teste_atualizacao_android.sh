#!/bin/bash
# N05 (auditoria de 17/11): atualização por cima da versão publicada no emulador, sem perder dados.
# Uso: teste_atualizacao_android.sh <apk-anterior> <apk-novo>   (os dois com a mesma chave fixa do app)
set -u
PKG=br.com.arque.measure; OLD=$1; NEW=$2; OUT=atualizacao; mkdir -p $OUT; FALHAS=0
falha(){ echo "FALHA: $*"; FALHAS=$((FALHAS+1)); }
adb wait-for-device; adb shell settings put global window_animation_scale 0 >/dev/null 2>&1
echo "== 1. instala a versão anterior"; adb install -r "$OLD" || falha "não instalou a versão anterior"
V0=$(adb shell dumpsys package $PKG | grep -m1 versionCode | tr -s ' ' | cut -d' ' -f2 | cut -d= -f2); echo "versão anterior: $V0"
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 10; adb shell am force-stop $PKG
echo "== 2. põe os dados do backup de referência"
rm -rf ref && mkdir ref && unzip -q tests/backup-referencia/android-backup-referencia.zip -d ref
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
adb shell am start -W -n $PKG/.MainActivity >/dev/null; sleep 20; adb shell input keyevent 3; sleep 15; adb shell am force-stop $PKG
hashes > $OUT/depois.txt
echo "== 4. confere"
diff $OUT/antes.txt $OUT/depois.txt && echo "arquivos iguais antes e depois: $(wc -l < $OUT/depois.txt)" || falha "arquivos mudaram ou sumiram na atualização"
grep -q '^  ' $OUT/depois.txt && falha "algum arquivo sumiu (sem hash)"
python3 - "$OUT/depois.txt" <<'PY' || FALHAS=$((FALHAS+1))
import json,sys
m=json.load(open('tests/backup-referencia/manifesto.json'))['arquivos'];d={l.split()[1]:l.split()[0] for l in open(sys.argv[1]) if len(l.split())==2}
ruins=[k for k,h in m.items() if d.get(k)!=h]
print('iguais ao manifesto: %d de %d'%(len(m)-len(ruins),len(m)));ruins and print('FALHA: diferentes do manifesto:',ruins);sys.exit(1 if ruins else 0)
PY
adb shell ls /sdcard/Download/ArqueMeasure/Projetos/ 2>/dev/null | tee $OUT/copias.txt
grep -q "antes-de-usar-a-versao-$V1" $OUT/copias.txt && echo "cópia antes-de-usar-a-versao-$V1: ok" || falha "não achei a cópia antes-de-usar-a-versao-$V1"
adb logcat -d > $OUT/logcat.txt; grep -E "FATAL EXCEPTION|ANR in $PKG" -A3 $OUT/logcat.txt | grep -B1 -A3 "$PKG" | head -20 && grep -qE "FATAL EXCEPTION" $OUT/logcat.txt && grep -A2 "FATAL EXCEPTION" $OUT/logcat.txt | grep -q "$PKG" && falha "o app fechou com erro depois de atualizar"
echo "RESULTADO: versão $V0 → $V1 · falhas $FALHAS"; exit $FALHAS
