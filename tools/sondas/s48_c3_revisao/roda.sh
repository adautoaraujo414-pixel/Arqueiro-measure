#!/bin/bash
# uso: run.sh <nome> <assetsdir> <swift> <httpport> <cdpport> <janela|-> [so]
S=${S:-$(mktemp -d)}
N=$1; A=$2; SW=$3; HP=$4; CP=$5; J=$6; SO=$7
mkdir -p $S/out/$N; rm -rf $S/prof/$N; mkdir -p $S/prof/$N
(cd $A && exec python3 -m http.server $HP >/dev/null 2>&1) & HPID=$!
CH=$(ls -d /opt/pw-browsers/chromium-*/chrome-linux64/chrome | head -1)
$CH --headless=new --no-sandbox --remote-debugging-port=$CP --user-data-dir=$S/prof/$N --use-angle=swiftshader --enable-unsafe-swiftshader --window-size=1366,768 "http://127.0.0.1:$HP/editor.html?lang=pt&nc=$RANDOM$RANDOM" >/dev/null 2>&1 & CPID=$!
sleep 6
ARGS="--cdp http://127.0.0.1:$CP --swift $SW --saida $S/out/$N --tempo 120 --url http://127.0.0.1:$HP/editor.html?lang=pt&nc=$RANDOM"
[ "$J" != "-" ] && ARGS="$ARGS --janela $J"
[ -n "$SO" ] && ARGS="$ARGS --so $SO"
python3 /home/user/Arqueiro-measure/tools/bateria_editor.py $ARGS > $S/out/$N/log.txt 2>&1
echo "fim rc=$?" >> $S/out/$N/log.txt
kill $CPID $HPID 2>/dev/null
