# Etapa 3 — integração das branches prontas (plano de 17/11), uma por vez

**Branch:** `claude/arquemestre-etapa3-integracao`, a partir de `feature/arquemestre-auditoria-final-ios` (`fbc946e`).
**Bateria local:** `tools/bateria_editor.py` no Chrome headless 156 (Windows 11), janela 1366×768, uma bateria por vez.
Chromium não aprova sozinho nenhuma plataforma (a CI do iOS e do Windows confere depois).

## Referência (`fbc946e`)
- 378 testes, 377 passaram. A falha (`testTomadasRegistroChurrasqueiraBotaoDoLEDETVComLogo`) foi carga da máquina: essa bateria rodou junto com a da junção 1. Repetido sozinho 3 vezes: passou nas 3.

## Junção 1 — `fita-rebaixo-3d` (`791a67d`)
- 379 testes: 378 + 1 falha de carga (`testPedraSolidaGeladeira…`, rodou junto com a referência). Repetido sozinho 3 vezes: passou nas 3. **379/379.**

## Junção 2 — `fita-portas-3d` (`829d64b`, `b5bc4ec`, `b23fc30`)
- 380 testes: 378 passaram. As 2 falhas vinham das duas correções juntas (expectativas calibradas cada uma na sua branch).
- Conferido pela geometria (ver HISTORICO, "Junção FT-REBAIXO + FT-PORTA"). Expectativas ajustadas com a aprovação do Adauto (opção a, 19/11). Os 2 testes passaram. **380/380.**

## Junção 3 — `plano-corte` (`2172c1d`) · validada em duas execuções no mesmo commit
- **Execução 1 (bateria completa):** foi interrompida por falta de memória do sistema; o Claude Code parou a tarefa.
  - 327 testes passaram.
  - O resto ficou sem rodar: o Chrome da bateria foi fechado na limpeza e a conexão caiu (WinError 10054, 0,0 s).
  - Valem os testes das posições 1 a 325.
- **Execução 2 (autorizada pelo Adauto):** os 58 testes das posições 326 a 383, por nome exato, no mesmo commit, com o mesmo script e a mesma janela, sem bateria em paralelo. 58/58 em 236 s.
- **Resultado consolidado: 383/383** (325 + 58). Os 3 testes novos do plano de corte estão incluídos.
