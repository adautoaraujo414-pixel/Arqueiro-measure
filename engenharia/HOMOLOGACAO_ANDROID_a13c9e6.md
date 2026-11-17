# Homologação da candidata Android `a13c9e6` (17/11/2026)

- **Branch:** `claude/arquemestre-candidata-android`.
- **Base:** P0 `790a990` + Fase 3 `e02faaf`, sobre a versão publicada `7c939bc` (Android 1.0.632).
- **Escopo congelado:** só P0 (parede/pé-direito) e Fase 3 (precisão de toque e medidas).
- **No app:** só o `editor.html` mudou; Java/Kotlin, backup e salvamento estão idênticos à versão publicada.
- **Testes:** o resto do commit são testes, documentos e novidades.

## Resultados
| Verificação | Resultado |
|---|---|
| Bateria completa do editor (Chromium, máquina livre) | **357/357** |
| CI Android 635 (compilação, testes JVM incluindo backup e `foto..jpg`, lint, APK de teste) | **passou** (a 1ª tentativa caiu ao baixar dependência do Gradle, rede do GitHub; refeita no mesmo commit) |
| Projetos da versão publicada abertos na candidata (15 projetos, 116 módulos, catálogo inteiro) | 15/15 iguais em peças, corte e chapas; salvar/reabrir igual; 0 erros |
| Restauração de backup (sonda JVM com o `DataBackup`) | 6/6 (válido, truncado, só a marca, bytes trocados, falha no meio) |
| Windows 46 (`fc98cc5`, mesmo app) | 356/357; a falha era a do teste do tamponamento, corrigida no `a13c9e6` |

## Falhas investigadas (rodadas isoladas, máquina livre, 3× em cada versão)
- **`testImaDoTopo…`:**
  - publicada 3/3 e candidata 3/3; posição e linha verde certas em 5 telas;
  - na bateria sobrecarregada, a linha (desenhada no próximo quadro, código igual ao publicado) saiu depois dos 80 ms que o teste espera;
  - sem defeito.
- **`testTamponamentoNo2D…`:**
  - publicada b1410 e candidata b1390, 3/3;
  - causa: a Fase 3 (aprovada) aumentou a folga do arrasto de 6 para 10 px, e o teste descontava 6 px fixos;
  - o teste agora lê a folga do app e passa nas duas versões em 6 telas;
  - sem defeito de cálculo.
- **`testFitaDaBase…`:**
  - teste corrigido (mira pela geometria e espera a porta fechar); passa 3/3 nas duas versões e com zoom;
  - mirando em cima da porta, falha: continua pegando seleção errada.

## Não verificado
- Instalação limpa e atualização da 1.0.632 num aparelho Android real: não há emulador nem aparelho neste ambiente.
- Procedimento seguro para o Adauto, com o APK de teste: ver o relatório.

## Reversão
- A 1.0.632 (`7c939bc`) continua na release `apk-632`.
- Para voltar: `android.yml` no modo publicar no commit `7c939bc` ("PUBLICAR 7c939bc"). Gera um número novo com o código anterior.
- A candidata não muda o formato dos dados, então a volta não exige migração.
