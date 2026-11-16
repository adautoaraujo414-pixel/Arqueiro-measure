# Teste da restauração de backup (Android/Windows)
Roda o `DataBackup.kt` de verdade (cópia do Windows; `stage`, `check`, `applyPending` e `swapIn` são iguais aos do Android) contra pastas temporárias. Não toca dados reais.

    cp ../../../windows/src/main/kotlin/br/com/arque/measure/data/DataBackup.kt src/main/kotlin/br/com/arque/measure/data/
    gradle test --rerun-tasks

P0-02 (16/11): antes da correção, "falha de escrita no meio" trocava os projetos e apagava as notas, e "só a marca" apagava tudo. Ver `engenharia/HISTORICO_ERROS.md` (BKP-RESTAURA).
