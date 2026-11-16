#!/bin/bash
# roda testes da bateria (pelo nome) no editor atual e confere as expectativas
cd /tmp/claude-0/-home-claude/f15b56a7-bcda-5a9d-949e-c7e477d22529/scratchpad
python3 ext3.py > /dev/null
for n in "$@"; do f=ios3/${n}_0.js; [ -f $f ] || { echo "SEM $n"; continue; }
 timeout 400 node ediph.mjs $f 2>&1 | grep -v "agent-proxy\|connect_rejected\|Allowed domains\|For details\|oldest\|and 1 more" > o_$n.txt
 python3 chk1.py $n o_$n.txt 2>&1 | tail -6
done
