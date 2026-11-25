#!/usr/bin/env bash
set -uo pipefail
./gradlew --no-daemon connectedPlayDebugAndroidTest -Pteste=1
result=$?
mkdir -p app/build/reports/androidTests/provas
adb pull /sdcard/Android/data/br.com.arque.measure.teste/files/demonstracao.png app/build/reports/androidTests/provas/demonstracao.png || true
exit "$result"
