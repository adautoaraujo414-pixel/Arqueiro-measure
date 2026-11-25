#!/bin/bash
# RECURSO-DIAG (Chefe 25/11, quedas do iOS 699): a cada 60 s, quantos processos do WebKit e do app de teste existem
# no Mac do CI e quanta memória usam. O simulador roda os processos no próprio Mac, então o ps enxerga todos.
# Só leitura: não mexe em teste, limite nem simulador. Uso: amostra_processos.sh <arquivo> &
OUT="$1"; : > "$OUT"
while true; do
  ps -axo rss=,etime=,comm= 2>/dev/null | awk -v t="$(date -u +%H:%M:%S)" '
    /WebContent/{w++;wr+=$1} /GPU/{g++;gr+=$1} /Networking/{n++;nr+=$1} /Arquemestre/{a++;ar+=$1}
    END{printf "%s · WebContent %d (%d MB) · GPU %d (%d MB) · Networking %d (%d MB) · app de teste %d (%d MB)\n",t,w,wr/1024,g,gr/1024,n,nr/1024,a,ar/1024}' >> "$OUT"
  sleep 60
done
