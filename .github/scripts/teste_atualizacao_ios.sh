#!/bin/bash
# Atualização por cima no simulador do iOS (pedido do Adauto, 20/11): instala a versão publicada, põe os dados do backup de referência,
# instala a nova POR CIMA (sem desinstalar), abre, e confere arquivo por arquivo (hash) que nada sumiu nem mudou. Só simulador: não publica.
set -u
BID=br.com.arque.measure; OLD=$1; NEW=$2; OUT=atualizacao; mkdir -p $OUT; FALHAS=0
falha(){ echo "FALHA: $*"; FALHAS=$((FALHAS+1)); }
UDID=$(python3 novo/ios/scripts/pick_sim.py iphone); xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
echo "== 1. instala a versão anterior"; xcrun simctl install "$UDID" "$OLD" || falha "não instalou a anterior"
xcrun simctl launch "$UDID" $BID >/dev/null; sleep 12; xcrun simctl terminate "$UDID" $BID
DATA=$(xcrun simctl get_app_container "$UDID" $BID data); F="$DATA/Library/Application Support/Arquemestre/files"; mkdir -p "$F"
echo "== 2. põe os dados do backup de referência"; rm -rf ref && mkdir ref && unzip -q novo/tests/backup-referencia/android-backup-referencia.zip -d ref
(cd ref/files && find . -type f | sed 's#^\./##' | sort) > $OUT/lista.txt; cp -R ref/files/. "$F/"
xcrun simctl launch "$UDID" $BID >/dev/null; sleep 12; xcrun simctl terminate "$UDID" $BID
hashes(){ while read -r rel; do [ -f "$F/$rel" ] && echo "$(shasum -a 256 "$F/$rel" | cut -d' ' -f1)  $rel" || echo "  $rel"; done < $OUT/lista.txt; }
hashes > $OUT/antes.txt; cat $OUT/antes.txt
echo "== 3. instala a versão nova por cima"; xcrun simctl install "$UDID" "$NEW" || falha "a nova não instalou por cima"
xcrun simctl launch "$UDID" $BID >/dev/null; sleep 25; xcrun simctl terminate "$UDID" $BID
DATA2=$(xcrun simctl get_app_container "$UDID" $BID data); [ "$DATA2" = "$DATA" ] || echo "aviso: pasta de dados mudou de lugar: $DATA2"; F="$DATA2/Library/Application Support/Arquemestre/files"
hashes > $OUT/depois.txt
echo "== 4. confere"; diff $OUT/antes.txt $OUT/depois.txt && echo "arquivos iguais antes e depois: $(wc -l < $OUT/depois.txt)" || falha "arquivos mudaram ou sumiram na atualização"
grep -q '^  ' $OUT/depois.txt && falha "algum arquivo sumiu"
xcrun simctl spawn "$UDID" log show --last 5m --predicate "process == 'Arquemestre'" 2>/dev/null | grep -iE "fatal|crash|exception" | head -5 > $OUT/quedas.txt; [ -s $OUT/quedas.txt ] && falha "o app registrou erro grave: $(head -1 $OUT/quedas.txt)"
echo "RESULTADO: falhas $FALHAS"; exit $FALHAS
