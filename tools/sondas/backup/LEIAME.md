# Sonda da restauração de backup (Android/Windows)
Roda o `DataBackup.kt` de verdade (cópia do Windows, idêntica à do Android em `stage` e `applyPending`) contra pastas temporárias. Não toca dados reais.

    cp ../../../windows/src/main/kotlin/br/com/arque/measure/data/DataBackup.kt src/main/kotlin/br/com/arque/measure/data/
    gradle test --rerun-tasks | grep CASO

Resultado em 16/11 (commit 0aa152c): ver `engenharia/AUDITORIA_INTEGRIDADE.md`, seção P0.
