#!/bin/bash
# Build local (offline, com o cache de dependências baixado do release win-dev-deps)
export GRADLE_USER_HOME=${GRADLE_USER_HOME:-/root/wingradle/.gradle}
cd "$(dirname "$0")"
JN=$(cat $GRADLE_USER_HOME/../jcef-natives-version.txt 2>/dev/null || cat /root/wingradle/.gradle/jcef-natives-version.txt)
exec gradle --offline -q -PjcefNativesVersion="$JN" "$@"
