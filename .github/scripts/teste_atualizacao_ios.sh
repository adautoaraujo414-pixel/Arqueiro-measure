#!/bin/bash
# Atualização por cima no simulador do iOS (pedido do Adauto, 20/11): instala a versão publicada, põe os dados do backup de referência,
# instala a nova POR CIMA (sem desinstalar), abre, e confere arquivo por arquivo (hash) que nada sumiu nem mudou; depois abre cada projeto no
# editor da versão nova (AtualizacaoAbreProjetosTests) e confere de novo os arquivos. Só simulador: não publica.
set -u
BID=br.com.arque.measure; OLD=$1; NEW=$2; OUT0=atualizacao; mkdir -p $OUT0; FALHAS=0
falha(){ echo "FALHA: $*"; FALHAS=$((FALHAS+1)); }
# 24/11 (auditoria final, pedido do Adauto: "Android, iPhone, iPad e Windows"): a mesma sequência no iPhone e no iPad, cada um com a sua pasta.
roda(){ KIND=$1; ZIP=$2; OUT=$OUT0/$KIND-$3; mkdir -p $OUT; echo "######## $KIND · backup $3"
  UDID=$(python3 novo/ios/scripts/pick_sim.py "$KIND"); xcrun simctl boot "$UDID" 2>/dev/null; xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1
  # cada rodada do zero: sem o app de antes no simulador
  xcrun simctl uninstall "$UDID" $BID >/dev/null 2>&1
  echo "== 1. instala a versão anterior"; xcrun simctl install "$UDID" "$OLD" || falha "não instalou a anterior"
  xcrun simctl launch "$UDID" $BID >/dev/null; sleep 12; xcrun simctl terminate "$UDID" $BID
  DATA=$(xcrun simctl get_app_container "$UDID" $BID data); F="$DATA/Library/Application Support/Arquemestre/files"; mkdir -p "$F"
  echo "== 2. põe os dados do backup de referência"; rm -rf ref && mkdir ref && unzip -q "novo/$ZIP" -d ref
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
  # 24/11: confere também com o manifesto do backup (hash de cada arquivo, igual ao Android e ao Windows)
  python3 - "$OUT/depois.txt" "novo/$(dirname "$ZIP")/manifesto.json" <<'PY' || FALHAS=$((FALHAS+1))
import json,sys
m=json.load(open(sys.argv[2]))['arquivos'];d={l.split()[1]:l.split()[0] for l in open(sys.argv[1]) if len(l.split())==2}
ruins=[k for k,h in m.items() if d.get(k)!=h]
print('iguais ao manifesto: %d de %d'%(len(m)-len(ruins),len(m)));ruins and print('FALHA: diferentes do manifesto:',ruins);sys.exit(1 if ruins else 0)
PY
  xcrun simctl spawn "$UDID" log show --last 5m --predicate "process == 'Arquemestre'" 2>/dev/null | grep -iE "fatal|crash|exception" | head -5 > $OUT/quedas.txt; [ -s $OUT/quedas.txt ] && falha "o app registrou erro grave: $(head -1 $OUT/quedas.txt)"
  echo "== 5. abre os projetos no editor da versão nova (Adauto, 21/11): medidas, peças, corte, foto do projeto e notas"
  XTR=$(ls novo/ios/build/dd/Build/Products/*.xctestrun 2>/dev/null | head -1)
  if [ -z "$XTR" ]; then falha "não achei o pacote de testes da versão nova (build-for-testing)"; else
    TEST_RUNNER_ARQ_ATUALIZACAO=1 xcodebuild test-without-building -xctestrun "$XTR" -destination "id=$UDID" -only-testing:ArquemestreTests/AtualizacaoAbreProjetosTests > $OUT/abre.log 2>&1; RA=$?
    grep -E "ATUALIZACAO-ABRE|error:|Test Case .*(passed|failed|skipped)|Executed" $OUT/abre.log | grep -v -E "ProcessAssertion|makeImagePlus|WEBP" | head -40
    [ $RA -eq 0 ] || falha "os projetos não abriram iguais no editor (veja abre.log)"
    grep -q "ATUALIZACAO-ABRE: projeto" $OUT/abre.log || falha "o teste de abrir os projetos não rodou (pulado?)"
  fi
  echo "== 6. confere de novo os arquivos: abrir no editor não mexeu em nada"
  DATA3=$(xcrun simctl get_app_container "$UDID" $BID data); F="$DATA3/Library/Application Support/Arquemestre/files"; hashes > $OUT/depois_abrir.txt
  diff $OUT/antes.txt $OUT/depois_abrir.txt && echo "arquivos iguais depois de abrir: $(wc -l < $OUT/depois_abrir.txt)" || falha "abrir os projetos mudou ou apagou arquivo"
}
# 24/11: os dois backups de referência (o de sempre e o rico gerado pelo editor publicado), cada um do zero
for K in ${DISPOSITIVOS:-iphone ipad}; do
  roda $K tests/backup-referencia/android-backup-referencia.zip referencia
  roda $K tests/backup-referencia-rico/backup-rico.zip rico
done
echo "RESULTADO: falhas $FALHAS"; exit $FALHAS
