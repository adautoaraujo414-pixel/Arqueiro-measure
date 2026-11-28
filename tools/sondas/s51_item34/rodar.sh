#!/bin/bash
# uso: run34.sh TELA JANELA PORTA URL
S=${S:-$(cd "$(dirname "$0")" && pwd)}  # pasta com sonda.js e rodar_janela.py
case $1 in
 vlm) A="[{id:'vlm',abre:async function(){document.getElementById('vlb').click()}}]";;
 prm) A="[{id:'prm',abre:async function(){document.getElementById('prb').click();await new Promise(function(r){setTimeout(r,60)});document.querySelector('[data-propen]').click()}}]";;
 cutm) A="[{id:'cutm',abre:async function(){document.getElementById('cutb').click()}}]";;
 mcm) A="[{id:'mcm',abre:async function(){MC=null;mcLoad();MC.list=[{n:'Lateral',w:700,h:500,q:2},{n:'Porta',w:700,h:400,q:1}];mcSave();document.getElementById('mcb').click();await new Promise(function(r){setTimeout(r,50)});mcCalc()}}]";;
 clm) A="[{id:'clm',max:150,abre:async function(){document.getElementById('clb').click()}}]";;
 stdm) A="[{id:'stdm',max:150,abre:async function(){document.getElementById('prb').click()}}]";;
 gdm) A="[{id:'gdm',abre:async function(){document.getElementById('gdb').click()}}]";;
esac
python3 - "$A" <<'P'
import sys;import os;S=os.environ.get('S','.')+'/'
open(S+'a34_tmp_'+sys.argv[1][7:11]+'.js','w').write(open(S+'sonda.js').read().replace('__TELAS__',sys.argv[1]))
P
cp $S/a34_tmp_$(echo "$A" | cut -c8-11).js $S/a34_run_$1_$2.js; JANELA=$2 timeout 3500 python3 $S/rodar_janela.py $S/a34_run_$1_$2.js --porta $3 --url "$4" > $S/a34_$1_$2.txt 2>&1
