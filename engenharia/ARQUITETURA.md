# Arquitetura verificada (16/11/2026)

Só o que foi conferido no código. O que não foi conferido está marcado como **não verificado**.

## Visão geral
- **Editor de móveis (2D, 3D, peças, plano de corte, valores):** um arquivo só, `app/src/main/assets/editor.html`. Tem 2,7 MB, 12.088 linhas, HTML, CSS e JS sem framework.
- O mesmo arquivo roda nas 3 plataformas:
  - **Android:** app Kotlin (`app/src/main/java/br/com/arque/measure/`) com WebView. As telas nativas são agenda, clientes, caderno, orçamentos, licença e sincronização.
  - **iOS:** app Swift (`ios/Arquemestre/`) com WKWebView. Testes em `ios/ArquemestreTests/`.
  - **Windows:** pasta `windows/` (build Gradle). Bateria própria no workflow `windows-bateria.yml`. Detalhe da tecnologia da janela: **não verificado**.
- **Ponte nativa:** objeto `ArqueApp` (`putFile`, `getFile`, `delFile`, `listFiles`, `shareCut`, `shareClient`, notas…). O editor grava e lê projetos por ela.
- **Traduções:** `app/src/main/assets/i18n/{en,es}.json`, de português para inglês e espanhol.
- **Fotos dos padrões de MDF:** `app/src/main/assets/cores/*.jpg` (271 arquivos) e `cores/catalogo.json`.
- **Site público:** a pasta `docs/` (GitHub Pages, montado a partir da branch `feature/arque-measure-kotlin`). Tem link do cliente, plano de corte e páginas da loja. **Documentação interna não entra aí.**

## Dentro do editor.html
- **Estado:** objeto global `S` (paredes, `S.mods` módulos, `S.stones` pedras, `S.rp` painéis, `S.fr` móveis soltos, `S.ops` portas e janelas…).
- Salvar e carregar: `snapState()` e `loadState()`.
- **Peças:** `partsOf(m)` é a fonte das peças de um módulo. O plano de corte, os materiais (`hwOf`, `mCost`) e o 3D leem dela.
- **2D:** SVG (`#svg`), redesenhado por `draw()`. Os painéis de edição saem de `panel()`.
- **3D:** WebGL 1 próprio (ver `MOTOR_3D_AUDITORIA.md`). `build()` monta as caixas a partir do projeto e `renderGL()` desenha.
- **Camadas de "embrulho":** cada correção costuma embrulhar a função anterior (`var po=partsOf; partsOf=function(){…po…}`). Contagem de redefinições:

  | Função | Redefinições |
  |---|---|
  | `partsOf` | 20 (recontado em 16/11 à tarde: faltavam 1943 e 12127) |
  | `draw` | 39 na cadeia (+2 `draw` locais de outro escopo) |
  | `panel` | 43 |
  | `build` | 27 |
  | `open3D` | 14 |
  | `loadState` | 11 |
  | `snapState` | 8 |
  | `newTpl` | 9 |

  **Risco:** a regra final depende da ordem dos embrulhos, e a mesma regra pode estar em mais de um lugar. Ver `PLANO_EVOLUCAO.md`.

## Desfazer
- `histTick` (linha 263) guarda o projeto inteiro a cada `draw`, até 100 passos. `histGo` volta por `loadState`. `snap()` (259) é o legado do módulo escolhido, usado na pinça.

## Achados de integridade
- Ver `AUDITORIA_INTEGRIDADE.md`: o desenho grava posição e medida (catraca), abrir regrava o arquivo, "Só a pedra" fica ligado, e outros.

## Gravação (verificado em parte)
- **Projetos:** todos ficam numa lista, gravada no `localStorage` (`pSaveAll`) e também no arquivo `projects.json` pela ponte nativa.
- Antes de gravar por cima, um `projects.json` que não abre é copiado para `projects.corrompido.json`.
- Há também os arquivos `hist_*` (histórico), `photo_*` (fotos) e `apmodels.json` (modelos do usuário).
- O `pSaveAll` é embrulhado várias vezes. **Ainda não foi levantada a ordem exata das proteções** (backup, lixeira, senha de 24 h). Antes de mexer em gravação, ler os testes `BackupSafetyTests.swift` e `testRecuperarProjetosDeUmBackupSemTrocarNada`.
- **Ajustes e preços:** objeto `PR` (`STD()` traz os padrões de marcenaria), gravado no `localStorage` e em `prices.json`.

## Testes
- `ios/ArquemestreTests/EditorWebKitTests.swift` é a bateria do editor. Cada teste roda um JS dentro do editor e confere o resultado. Roda no CI do iOS (`ios.yml`) e no Windows (`windows-bateria.yml`).
- Outros testes iOS: backup (`BackupSafetyTests.swift`), caderno, núcleo, assinatura e sincronização.
- Fora do repositório, na máquina de trabalho, existe um harness em Chromium que roda a bateria inteira, compara antes e depois (A/B) e confere as asserções.

## Publicação (workflows)
- `ios.yml`: testes a cada push na branch. TestFlight só manualmente, com `testflight=true`.
- `android.yml`: publicar só manualmente, com `modo=publicar` e a confirmação `PUBLICAR <sha7>`.
- `windows.yml`: igual ao Android.
- Envio à App Store: `asc-enviar.yml` (não está neste repositório; **não verificado**). Nunca roda com `enviar=true` sem autorização.
