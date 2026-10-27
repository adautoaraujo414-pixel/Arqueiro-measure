#!/bin/bash
# Capturas de tela para a App Store, tiradas no simulador com dados de exemplo (-demo).
# Uso: screenshots.sh <caminho do Arquemestre.app> <pasta de saída>
set -euo pipefail
APP="$1"; OUT="$2"
BID=br.com.arque.measure
mkdir -p "$OUT"
DIR="$(cd "$(dirname "$0")" && pwd)"

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
    local n=1
    for scr in library editor agenda quotes moveis trial; do
      xcrun simctl terminate "$udid" "$BID" 2>/dev/null || true
      xcrun simctl privacy "$udid" grant photos "$BID" 2>/dev/null || true
      if [ "$scr" = "trial" ]; then
        xcrun simctl launch "$udid" "$BID" -arque.lang "$lang" -demo -trialOffer >/dev/null
      else
        xcrun simctl launch "$udid" "$BID" -arque.lang "$lang" -demo -screen "$scr" >/dev/null
      fi
      sleep 7
      xcrun simctl io "$udid" screenshot "$dir/${kind}-${n}-${scr}.png"
      n=$((n+1))
    done
  done
  xcrun simctl shutdown "$udid" || true
}

shoot iphone
shoot ipad
ls -la "$OUT"
