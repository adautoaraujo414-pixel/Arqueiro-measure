# Transferência do DNA do Arquemestre (estado em 18/11/2026, 08:00 UTC)

Este documento serve para outra conta ou sessão do Claude continuar **exatamente do último estado comprovado**. Ele não repete o que já está nos outros documentos de `engenharia/`; diz onde está cada coisa e o que só existe aqui (estado, branches, CI, pendências).

> **Ordem de leitura obrigatória:**
> 1. `CLAUDE.md` (regras permanentes).
> 2. Este arquivo.
> 3. `engenharia/REGRAS_MARCENARIA.md` e `engenharia/DECISOES_TECNICAS.md`.
> 4. `engenharia/HISTORICO_ERROS.md` (um registro por erro).
> 5. `engenharia/CHECKLIST_EXECUCAO.md` (160 pedidos, 89 defeitos e os itens N01–N24).
> 6. `engenharia/ARQUITETURA.md` e `engenharia/GESTOS_CONTROLES.md`.

---

## 1. Quem decide e como trabalhar
- **Dono:** Adauto. Ele decide regras de marcenaria, layout, publicação e mudanças de comportamento.
- **Língua:** português informal e curto.
- **Publicação:** nada vai pra loja, TestFlight, APK do site ou Windows sem o "sim" dele para aquela versão e plataforma.
  - A trava `.github/scripts/trava_publicacao.py` faz todos os workflows falharem se algum passo de publicação aparecer fora do modo "publicar". Nunca contornar.
  - **TestFlight (18/11):** pode preparar uma candidata. Antes de enviar, apresentar o commit, a versão, o estado dos testes e os riscos, e esperar a aprovação específica. App Store pública não está autorizada.
- **Projetos:** nada apaga, esvazia ou muda projeto sozinho. Projeto antigo inconsistente **avisa** e a pessoa decide. Mudança em dados: backup, compatibilidade e teste de salvar e reabrir.
- **Cada erro:**
  1. reproduzir;
  2. teste que falha antes (commit só do teste);
  3. correção mínima (outro commit);
  4. teste passando;
  5. bateria completa;
  6. registro no HISTORICO.
- **Testes:** nunca afrouxar. Mudar uma expectativa só com pedido aprovado e data no comentário.
- **Componente compartilhado de minimizar** (9 quadros: `it4`, `pt3q`, `gvbox`, `crgbox`, `slcfg`, `trbox`, `rpfbox`, `qebox`, `det3bar`): não modificar.
- **Repositório público:** sem senhas, dados de clientes, preços ou regras de licença. Por isso o N12 está bloqueado.

## 2. Versões publicadas (não mexer)

| Plataforma | Versão pública | Commit |
|---|---|---|
| Android (site) | `apk-636` (ponteiro `apk-latest/latest.txt` = 636) | `6b0e9cd` (branch `claude/arquemestre-candidata-android`) |
| Windows | `win-143` | (release do workflow `windows.yml`, modo publicar) |
| iOS | **não informado.** Perguntar ao Adauto qual commit está na loja ou no TestFlight; precisa pro teste de atualização N05 do iOS | — |

## 3. Mapa das branches (todas `claude/arquemestre-*`)

| Branch | Para quê | Estado |
|---|---|---|
| `integracao` (68c132b) | Base de integração. Tem a etapa de segurança (N01–N06, N09, N13) e N07/N10 | Android 642 ok, Windows 152 ok, iOS 625 **verde inteira** (iPhone, iPad, Release, capturas, StoreKit), bateria 359/359 |
| `gavetas-paredes` (1626b57) | Pedidos de 18/11 em cima da integração: GAV-SET, DUPLO-TOQUE, CANTO-SOZINHO, PORTA-CAVA, MENU-ARRASTA, FUNDO-SOBRE, FITA-CORTE | Bateria 366/366 local e Windows 54 (366/366), Android 645 ok. iOS 628 **verde inteira** (76bb82c); iOS 629 no topo (com MENU-ARRASTA/FUNDO-SOBRE/FITA-CORTE) rodando |
| `candidata-android` (6b0e9cd) | O que está publicado no Android | Congelada |
| `seg-nomes`, `seg-backup-ref`, `seg-salvar`, `seg-estado`, `seg-videos`, `win-testes` | Correções isoladas da etapa de segurança | Já integradas na `integracao` |
| `protocolo-cirurgico` | Tem `AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md`, `PLANO_EXECUCAO_2026-11-17.md`, `AUDITORIA_LINHAS.md`, `PLANO_MESTRE` | Documentação; trazer pra integração quando autorizado |
| `p0-parede`, `fase3-precisao`, `ajustes-3d`, `plano-corte`, `lateral-inteira`, `travessao`, `canto-folha-lado`, `fita-rebaixo-3d`, `fita-portas-3d`, `batente-cava`, `fase2-selecao` | Trabalhos anteriores | Ver CHECKLIST. Integrar um por vez, com bateria e CI das 3 plataformas |
| `main` | Não mexer (protegida) | — |

## 4. Arquitetura em 10 linhas
Detalhes em `ARQUITETURA.md`.
- **Um editor só:** `app/src/main/assets/editor.html` (~2,9 MB, JS em vários `<script>`). Roda no Android (WebView), no iOS (WKWebView, `ios/Arquemestre/UI/MoveisView.swift`) e no Windows (CEF, `windows/.../desktop/Browser.kt` + `ui/MoveisScreen.kt`).
- **Estado e peças:** o estado global é `S`. A única fonte de peças é `partsOf(m)`; 2D, 3D, lista, corte (`cutLines`) e orçamento leem dela. O fundo do armário sai de `fundoDims(m)`.
- **Salvar e abrir:** `snapState()` e `loadState(o)`, encadeados por embrulhos (`var x=snapState;snapState=window.snapState=function(){…}`). Projetos em `pSaveAll`/`pLoadAll`, `projects.json` (PK `arque.projects.v1`). Escolha na abertura em `pjsDecide`/`__pjsBoot`.
- **Pontes nativas (`window.ArqueApp`):**
  - Android: `MoveisBridge` (@JavascriptInterface).
  - Windows: `when(method)` devolvendo String; `A()` é texto, `B()` é booleano.
  - iOS: `post` assíncrono, mais `prompt('__arque__:op')` síncrono em `runJavaScriptTextInputPanelWithPrompt`.
- **Mídia:** fotos e vídeos no IndexedDB `arque-photos`; cópia nativa `photo_<id>.json` / `video_<id>.json` pelo `EditorMediaBackup.js`. Esse script é o mesmo no iOS e no Android/Windows (`window.__mediaKeepBig` só nesses dois).
- **Backup:** `DataBackup.kt` (Android e Windows: `check`, `stage`, `applyPending`, cópias datadas) e `Backup.swift` (iOS).
- **Editor por vãos (torres):** `m.v[0].k==='rt'`, árvore `m.rt`. Funções `lay`, `rgOverlay` (só com `SOLO2===m`), painel `body(m)`/`tabsHtml(m)`, menu rápido `#rgqk` (2 toques no vão). A conversão `rgConvert` acontece no `soloOn`; `RGAUTO` desfaz se nada mudou.
- **2D por parede:**
  - `wvGo(w)` com `toView`/`toCanon`. Paredes `f`, `e` e `d`. Nas paredes do lado, o `x` conta a partir do canto do fundo.
  - **Defeito em aberto:** a parede da esquerda aparece espelhada no 2D (N20).
  - O canto entre paredes (`cantoEncosta`) só mexe no módulo que a pessoa mexeu (CANTO-SOZINHO).
- **Gestos** (`GESTOS_CONTROLES.md`): `SEL={mov:10,dt:350,dd:40,div:12}` e `tapCount`. No desenho, 1 toque escolhe, 2 toques abrem o menu do vão, 4 toques travam. 1 dedo no módulo move o módulo.

## 5. Regras de marcenaria mais recentes
O resto está em `REGRAS_MARCENARIA.md`.
- **Fundo do armário:** sempre sobreposto, parafusado atrás, 6 mm. Rasgo só no fundo da gaveta (18/11). Módulo antigo com rasgo avisa e tem o botão "Passar pra sobreposto".
- **Fita de borda:** não desconta nada no plano de corte (18/11). A fita entra só em metros.
- **Medida e posição são do marceneiro:** o app avisa e nunca altera sozinho (16/11).
- **Gaveta:** a altura da lateral vale pro conjunto todo (mesmo vão); frentes, profundidade e folgas não mudam (18/11).
- **Tamponamentos:** sempre por fora do corpo (pedido de 18/11, ainda a implementar no item 7 abaixo).

## 6. Testes e ferramentas
- **Bateria do editor:** `ios/ArquemestreTests/EditorWebKitTests.swift`, 366 testes em 18/11. Roda igual em três lugares:
  - Chromium local: `tools/bateria_editor.py --cdp http://127.0.0.1:9401 --swift ios/ArquemestreTests/EditorWebKitTests.swift --url "http://127.0.0.1:PORTA/editor.html?lang=pt&v=$RANDOM" [--so REGEX] [--janela 1366x768] --saida DIR`. Precisa de um Chrome headless aberto numa aba do editor (`curl -X PUT "http://127.0.0.1:9401/json/new?http://127.0.0.1:PORTA/editor.html?lang=pt"`) e de um servidor (`python3 -m http.server PORTA` na pasta `app/src/main/assets`).
  - iOS: XCTest no simulador do iPhone e do iPad.
  - Windows: `windows-bateria.yml`, dentro do app de verdade. Tem o filtro `so` no disparo manual.
- **Sonda rápida:** um arquivo JS que devolve `{v0..v39}`. Monta-se uma classe Swift com `testSonda` e roda com `--so testSonda`. Fica num arquivo descartável, fora do repositório.
- **Testes nativos:**
  - Android: JVM em `app/src/test` (inclui `BackupReferenciaTest`, `EditorVideoTest`, `SyncTest`).
  - Windows: `windows/src/test` (inclui `DesktopCompatTest`, `StoneFitTest`, `QuotePdfTest`).
  - iOS: `BackupSafetyTests`, `SyncInteropTests`, `SubscriptionTests` (StoreKit), `EditorAppPathTests`.
- **Backup de referência:** `tests/backup-referencia/` (zip e `manifesto.json` com sha256). É restaurado igual nas 3 plataformas e usado nos testes de atualização.
- **Workflows:**
  - `android.yml` (modo `teste`);
  - `windows.yml` (modo `teste`: testes JVM, instalador e passeio pelo app instalado);
  - `windows-bateria.yml`;
  - `ios.yml` (`testflight:false`; o iPad roda mesmo se o iPhone falha; o resumo vai pro branch `ci/ios-resultados`, que guarda só a última execução, com `RESUMO.txt`, `QUEDAS.txt` e o resumo do xcresult);
  - `android-atualizacao.yml` (emulador: apk-636 → commit);
  - `windows-atualizacao.yml` (win-143 → commit).
- **Limitações do ambiente:**
  - o proxy bloqueia download de artefatos do Actions e o dl.google.com (sem gradle local); os logs saem com `gh api repos/…/actions/jobs/ID/logs`;
  - o container reinicia e derruba servidores e Chrome, que precisam ser abertos de novo;
  - a pasta temporária (`scratchpad`) pode sumir; os worktrees estão lá.
- **iOS:**
  - limite de **120 s por teste**: teste de varrer o catálogo tem que ficar abaixo de ~100 s (N07);
  - instáveis conhecidos (N15): tempo de abrir o editor (limite 20 s; no simulador às vezes 25–51 s na 1ª tentativa) e `botaoPegaDePrimeira` do `testMaoDeObra…`; os dois passam na repetição.

## 7. Estado dos itens desta rodada (detalhe e commits no CHECKLIST e no HISTORICO)

| Item | O que é | Estado comprovado |
|---|---|---|
| N01/N02 | `foto..jpg` no backup do iOS e na sincronização | Corrigido. Antes: 619/637/145 falham; depois: 621/638/146/152 ok |
| N03 | Gravação do `projects.json` que falhava calada e voltava o projeto velho | Corrigido (ponte responde se gravou). Android 639/642, Windows 147/151/152, iOS 622 (teste ok) e 625 ok |
| N04 | 7 dados fora do `snapState` (painéis da parede, sala, rodapé, escolhas do 3D) | Corrigido pela causa (embrulho de `snapState`/`loadState` no mesmo padrão; desfazer inclusive). Bateria ok |
| N05 | Atualização por cima da versão anterior | Android ok (636 → 90005, 8/8 sha256, cópia antes-de-usar). Windows ok (win-143 → 60001, 8/8, 1 instalação). **iOS pendente** (falta o commit publicado) |
| N06 | Backup entre plataformas | Validado nas 3 (Android 640, Windows 149, iOS 621) |
| N07/N10 | iOS vermelho sem falha | **Causa comprovada:** limite de 120 s por teste. Teste dividido (113 s → 54 + 61 s). **Confirmado no iOS 628** (verde inteira, 0 quedas) |
| N08 | iPad nunca rodava | Corrigido (iPad passou na 621, 622 e 625) |
| N09 | Testes do Windows (pedra, PDF, aditivos) | Corrigido (CI 153) |
| N12 | Teste de licença | **Bloqueado:** regra de licença não pode ir pro repositório público |
| N13 | Vídeos fora do backup no Android/Windows | Corrigido (Android 641, Windows 150). **Pendente: ponta a ponta em aparelho real** |
| N14 | Cópia "antes-de-usar-a-versao-N" só ao sair da versão nova | Risco. Proposta: fazer também ao abrir. Aguarda o Adauto |
| N15 | 2 testes do iOS sensíveis a tempo | Monitorar; detalhe na mensagem (880a194) |
| N16/N17 | Gaveta: lateral do conjunto e excesso no máximo | Corrigido (gavetas-paredes) |
| N18 | 2 toques: 8 itens não abriam (geladeira, torres) | Corrigido. Auditoria de 567 itens sem regressão |
| N19 | Abrir o projeto empurrava o móvel do canto (7 de 15 projetos) | Corrigido (P0); depois 0 de 15 |
| N20 | Parede da esquerda espelhada no 2D | Medido (3D × 2D). Correção autorizada em 18/11, **ainda não feita**. Ver §8 |
| N21 | Porta cava na aba Portas do editor por vãos | Feito (vale pro móvel todo; a conta é por móvel) |
| N22 | Puxador cava do projeto não chega nas torres `rt` | Aguarda decisão |
| N23 | Menu do vão arrasta e minimiza | Feito (Windows achou diferença de 8 px, corrigida) |
| N24 | Fundo sempre sobreposto | Feito |
| FITA-CORTE | Fita não desconta no corte | Conferido e travado por teste |

## 8. Pedidos em aberto (na ordem pedida pelo Adauto em 18/11)
1. **Paredes espelhadas (N20), autorizado.** Corrigir só a projeção da parede da esquerda (tela = comprimento − x − largura) na fronteira `toView`/`toCanon`.
   - Junto: o canto ocupado (`wvOcc`, `confineAll` com `[0,ws]`), as pedras (`wvStCorner`, linha "st.x=c_") e os objetos da parede (`mods`, `fr`, `ops`, `rp`, pedras do lado).
   - Cuidado com pedra em L (`Le`/`Ld`) e recortes de cuba dentro da pedra.
   - Os dados salvos não mudam. Testar fundo → esquerda → direita → fundo, cantos, portas com dobradiça dos dois lados, salvar e reabrir.
2. **Armário alto, edição direta.** Ao escolher a torre no projeto, o painel do lado já mostra o editor por vãos, sem exigir o 2D isolado (o isolado continua como opção).
   - **Pergunta pendente:** os vãos ficam tocáveis no desenho do projeto? Isso conflita com "1 dedo move o módulo". Alternativa: escolher o vão pelo painel.
3. **Régua de acabamento / rodapé.** Achar o pedido original e a referência antes de qualquer mudança (ainda não localizado nesta sessão).
4. **Tamponamentos e laterais que descem** (pedido de 18/11, item 7): superior editável, descer a lateral esquerda, a direita ou as duas, laterais por dentro ou por fora, medida interna real. A geometria definitiva só depois das referências (decisão 7 de 17/11).
5. **Editor de vãos padronizado** (item 8): gaveta, basculante, prateleira com engrosso ou sem recuo, divisória, puxador, tudo por vão (ex.: balcão da pia com gaveta embaixo e basculante em cima).
6. **Auditoria do motor geométrico e do plano de corte** (item 9).
7. **Cenário completo nas 3 plataformas** (item 11): cliente → paredes → módulos → mudar de parede → vãos → peças → 3D → lista e corte → salvar, fechar e reabrir → backup e restauração → conferir tudo.
8. **N14, N22 e a posição digitada perto do canto:** decisões do Adauto.

## 9. Próximos passos exatos
1. Conferir o iOS 629 (topo da `gavetas-paredes`). O 628 já passou inteiro, sem queda.
2. Integrar a `gavetas-paredes` na `integracao` só depois do iOS verde: bateria e CI das 3 plataformas.
3. N20 (paredes espelhadas) em branch nova a partir da `gavetas-paredes`, com teste que falha antes.
4. Perguntar ao Adauto: o commit do iOS publicado (N05), a pergunta do §8.2, N14, N22, a posição digitada no canto e a régua de acabamento (referência).
5. Candidata TestFlight só depois disso, apresentando antes o commit, a versão, os testes e os riscos.

## 10. Como recriar o ambiente de teste em uma sessão nova
```
git fetch origin claude/arquemestre-gavetas-paredes
git worktree add /tmp/wt-gp origin/claude/arquemestre-gavetas-paredes
(cd /tmp/wt-gp/app/src/main/assets && python3 -m http.server 8831 --bind 127.0.0.1 &)
/opt/pw-browsers/chromium-*/chrome-linux64/chrome --headless=new --no-sandbox --remote-debugging-port=9401 --use-angle=swiftshader --enable-unsafe-swiftshader --user-data-dir=/tmp/chr about:blank &
curl -s -X PUT "http://127.0.0.1:9401/json/new?http://127.0.0.1:8831/editor.html?lang=pt"
cd /tmp/wt-gp && python3 tools/bateria_editor.py --cdp http://127.0.0.1:9401 --swift ios/ArquemestreTests/EditorWebKitTests.swift --url "http://127.0.0.1:8831/editor.html?lang=pt&v=1" --saida /tmp/bat
```
- A bateria inteira leva cerca de 38 min e deve dar 366/366 no topo da `gavetas-paredes`.
- Não rode duas baterias ao mesmo tempo: os testes de arrasto ficam instáveis com a máquina carregada.
