#!/bin/bash
# Capturas de tela para a App Store, tiradas no simulador com dados de exemplo (-demo).
# Uso: screenshots.sh <caminho do Arquemestre.app> <pasta de saída>
set -euo pipefail
APP="$1"; OUT="$2"
BID=br.com.arque.measure
mkdir -p "$OUT"
DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="$(dirname "$OUT")/capturas-tentativas.txt"
: > "$LOG"

# tira a captura; se saiu vazia (o app ainda não desenhou a primeira tela), espera mais e tira de novo.
# Se continuar vazia, abre o app de novo uma vez. Anota cada nova tentativa (fica no RESUMO), pra não esconder nada.
take() { # $1 udid  $2 arquivo  $3.. comando de abrir o app
  local udid="$1" f="$2" t; shift 2
  for t in 1 2 3 4 5 6; do
    xcrun simctl io "$udid" screenshot "$f" >/dev/null
    if python3 "$DIR/check_blank.py" --one "$f"; then
      [ "$t" = 1 ] || echo "$(basename "$(dirname "$f")")/$(basename "$f"): saiu certa na tentativa $t" >> "$LOG"
      return 0
    fi
    echo "$(basename "$(dirname "$f")")/$(basename "$f"): tentativa $t vazia, esperando mais" >> "$LOG"
    if [ "$t" = 3 ]; then
      xcrun simctl terminate "$udid" "$BID" 2>/dev/null || true
      "$@" >/dev/null
      sleep 10
    else
      sleep 6
    fi
  done
}

shoot() { # $1 kind (iphone|ipad)
  local kind="$1" udid
  udid=$(python3 "$DIR/pick_sim.py" "$kind")
  # aparelho limpo: só os dados de exemplo (os testes deixam dados no simulador)
  xcrun simctl shutdown "$udid" 2>/dev/null || true
  xcrun simctl erase "$udid"
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 || true
  xcrun simctl ui "$udid" appearance dark || true
  # um jogo de capturas por idioma (português na raiz, os outros em en/ e es/), com os dados de exemplo no idioma
  for lang in pt en es; do
    local dir="$OUT"
    [ "$lang" = "pt" ] || dir="$OUT/$lang"
    mkdir -p "$dir"
    xcrun simctl uninstall "$udid" "$BID" 2>/dev/null || true
    xcrun simctl install "$udid" "$APP"
    # região do idioma: no simulador ela é EUA, e o dinheiro sairia "$" nas capturas em português
    local loc=pt_BR
    [ "$lang" = "en" ] && loc=en_US
    [ "$lang" = "es" ] && loc=es_MX
    local n=1
    # loja: só projetos prontos e cores (sem agenda, orçamento, assinatura nem plano de corte)
    for scr in moveis3d moveissala moveiscores moveiscloset moveisplanta moveis editor; do
      xcrun simctl terminate "$udid" "$BID" 2>/dev/null || true
      xcrun simctl privacy "$udid" grant photos "$BID" 2>/dev/null || true
      local cmd=(xcrun simctl launch "$udid" "$BID" -arque.lang "$lang" -AppleLocale "$loc" -demo)
      if [ "$scr" = "trial" ]; then cmd+=(-trialOffer); else cmd+=(-screen "$scr"); fi
      "${cmd[@]}" >/dev/null
      case "$scr" in moveis*) sleep 22;; *) sleep 7;; esac
      take "$udid" "$dir/${kind}-${n}-${scr}.png" "${cmd[@]}"
      n=$((n+1))
    done
  done
  xcrun simctl shutdown "$udid" || true
}

shoot iphone
shoot ipad
ls -la "$OUT"
