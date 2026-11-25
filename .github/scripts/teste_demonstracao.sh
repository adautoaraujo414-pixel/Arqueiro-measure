#!/usr/bin/env bash
set -uo pipefail
./gradlew --no-daemon connectedPlayDebugAndroidTest -Pteste=1 -Pandroid.injected.androidTest.leaveApksInstalledAfterRun=true
result=$?
mkdir -p app/build/reports/androidTests/provas
adb pull /sdcard/Android/data/br.com.arque.measure.teste/files/demonstracao.png app/build/reports/androidTests/provas/demonstracao.png || result=1
adb pull /sdcard/Android/data/br.com.arque.measure.teste/files/demonstracao-ui.xml app/build/reports/androidTests/provas/demonstracao-ui.xml || true
exit "$result"
