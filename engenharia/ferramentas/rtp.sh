#!/bin/bash
cd /tmp/claude-0/-home-claude/f15b56a7-bcda-5a9d-949e-c7e477d22529/scratchpad
one(){ n=$1; f=ios3/${n}_0.js; [ -f $f ] || { echo "SEM $n"; return; }
 timeout 400 node ediph.mjs $f 2>&1 | grep -v "agent-proxy\|connect_rejected\|Allowed domains\|For details\|oldest\|and 1 more" > o_$n.txt
 python3 chk1.py $n o_$n.txt 2>&1 | tail -1; }
export -f one
cat "$1" | xargs -P 6 -I{} bash -c 'one {}'
