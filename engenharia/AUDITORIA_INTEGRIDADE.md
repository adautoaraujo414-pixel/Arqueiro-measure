# Auditoria de integridade (16/11/2026, tarde) — etapas 1 e 2 autorizadas

Branch isolada `claude/arquemestre-engineering-audit-s3x5mc`, a partir do checkpoint `0aa152c` (`feature/arque-measure-kotlin`).

**Nenhuma linha do app foi alterada.** Nada publicado, nenhum workflow disparado (a branch `claude/**` não dispara nenhum).

Como foi feito:
- A bateria completa rodou no Chromium desta máquina, com `tools/bateria_editor.py`, WebGL por SwiftShader, sem dados reais.
- Sondas novas em `tools/sondas/` rodam dentro do editor com a ponte em memória da bateria.

Classificação usada:
- **COMPROVADO**: reproduzido rodando o editor.
- **CÓDIGO**: visto no código, não reproduzido.
- **RISCO**: pode dar erro, falta prova.
- **CORRETO**: conferido e funcionando.

## 1. Regra arquitetural proposta (pedido de 16/11)
**Renderizar não modifica o modelo de fabricação.**

`draw()`, `build()`, `partsOf()`, `cutLines()`, `cutGroups()`, `hwOf()` e `mCost()` não podem gravar medida, posição ou propriedade que vai para o arquivo. Uma regra que hoje "corrige" o projeto ao desenhar tem dois destinos possíveis:
- vira **derivada**: calculada na hora, sem gravar;
- vira **ação explícita**: só quando a pessoa mexe naquilo, reversível pelo desfazer.

## 2. O que funciona (conferido, preservar)
| Item | Evidência |
|---|---|
| Desenhar e montar o 3D de novo sem ação não muda nada | s10: 142 modelos e cozinha demo, `draw()` ×5 e `build()` ×2 com estado idêntico, nenhuma escrita registrada |
| `partsOf` idempotente e sem escrita em uso normal | s01: 142 modelos |
| Salvar e reabrir dá as mesmas peças, o mesmo corte e o mesmo 3D | s01 (142 modelos, ponto fixo depois de 2 reaberturas), s02 (cozinha inteira) |
| Edição incremental (largura, altura, profundidade) dá o mesmo resultado que salvar e reabrir | s01 e s02: 2D, 3D e corte iguais |
| Módulo isolado e no projeto dão as mesmas peças | s02 |
| Ordem dos módulos na lista não muda o resultado | s15: 4 ordens, com e sem a parede encolhida |
| **Desfazer e refazer do projeto inteiro (`histTick`/`histGo`)** | s02 e s11: mexer, ↶ e ↷ voltam idênticos, inclusive depois de encolher a parede |
| Tamponamento automático pelo **arrasto real** é determinístico | s12: toda chegada perto da parede dá x=35 com o tamponamento ligado, sem vão |
| Peça tirada pelo 🗑 sai de `partsOf` | s07: todas as peças de 142 modelos |

**Correção da documentação:** o desfazer **não** é só do módulo escolhido. `snap()` (linha 259) é o legado do módulo. O histórico de verdade é `histTick` (263): o projeto inteiro, até 100 passos, juntando mexidas em menos de 700 ms. A volta é por `histGo` → `loadState`. Não deve ser substituído.

## 3. Achados

### P1-A. O desenho grava posição e medida e não desfaz (efeito catraca) — COMPROVADO
A cadeia `draw()` → `confineAll()` (linha 1174) roda `confine`, `stPush`, `placeFree` e `roomClamp`. Essas funções gravam `m.x`, `m.h`, `m.b` e `stone.w` quando uma entrada muda. Quando a entrada volta, o dado não volta.

| Sequência (cozinha demo, caminho real `setv`) | Fica depois de voltar | Quem gravou |
|---|---|---|
| Parede do fundo −300 e volta | torre da parede lateral x 606 → **636** | `confineAll` (1174) via `stPush` |
| Pé-direito −400 e volta | torre h 2400 → **2300**; aéreos b 1560 → **1950** pelo campo (pela atribuição direta 1560 → 1550) | `roomClamp` (3011) e `wallFollow` |
| Módulo 1 largura +300 e volta | vizinho x 2105 → **2405**, pedra w 2735 → **3035**, torre +30 | `placeFree` (1148), `stFitApply` (2276) |
| Espessura +3 e volta (14 modelos com forno) | largura do módulo 600 → **606**, peças mudam | `sanM` (508, `m.w=wmin_`) |
| Canto em L direito, largura +150 e volta | x deslocado 150 | `confine` |
| Ligar e desligar `sup`/`rack` | travessa e moldura apagadas de vez | `sanBase` (10389, `m.trav=false`) e `sanM` |

**Contraria a regra "módulo não age sozinho"** e altera **medida de fabricação** (altura da torre, largura do forno) sem pedido.

Sondas: s11, s13 e s05.

### P1-B. Tamponamento automático depende do caminho quando a posição vem de campo ou de dado — COMPROVADO
`autoTamp` (5664) roda dentro de `draw` (5667) e liga e desliga `tl`/`tr` sozinho. Junto com o empurrão do `confineAll`, o resultado depende do estado anterior.
- **Pelo campo digitado** ("Da esquerda", `setv('x')`):
  - x=25 dá 25 ou 35 conforme o valor anterior;
  - x=5 vindo de 800 dá **x=35 sem tamponamento: vão de 35 mm** na parede;
  - x=15 ou 25 também ficam com vão de 15 ou 25 mm sem tamponamento.
- **Pelo arrasto real:** determinístico, sem vão (ver a seção 2).
- `tpTlVolta` (1554) devolve o empurrão só no caminho do "Usar" e só fora da parede lateral (`!m.wing`). Os outros caminhos que desligam `tl` não devolvem: `autoTamp` 5665, canto 1480 e 1691, porta de correr 10701, emenda 7158 e 12153.

**A regra aprovada de tamponamento não foi alterada.** Falta decidir o que fazer com a posição.

Sondas: s13, s06 e s12.

### P1-C. Abrir um projeto regrava o arquivo e apaga o engrosso — COMPROVADO
- O `loadState` faz `draw()`, que chama `schedSave()` (2437). Em 500 ms o projeto é regravado com `updated=agora`, mesmo sem nenhuma mexida.
- No caminho, `defs()` (274) e `partsOf` (509) fazem `if(!ENGON()){m.egL=0;m.egR=0}`. `egOn` é **ajuste do aparelho**, com padrão 0 (305), e não do projeto.
- **Teste:** projeto com `egL=30` aberto com o ajuste padrão. O `projects.json` passou a ter `egL=0` e a data mudou.
- Ligar e desligar `egOn` também zera, e religar não devolve (s07).
- **Efeito na sincronização Wi-Fi:** o aviso "a mais nova" usa `updated`. Um projeto só aberto parece mais novo.

Sondas: s08b e s07.

### P1-D. "Só a pedra no 3D" esconde os módulos em todos os projetos até recarregar o editor — COMPROVADO (provável causa do 3D-045)
- `ST3ONLY` (6449) só é desligado pelo próprio botão. Fechar o 3D ou abrir outro projeto na mesma página não desliga.
- **Teste:** 922 caixas de módulo → botão → 0. Fechar o 3D, salvar e reabrir, outro projeto: continua 0. O diagnóstico de 900 ms não corrige.
- No iPhone, abrir o projeto pela lista cria um WKWebView novo (`MoveisView.swift:178`), e isso zera a chave. Isso explica o relato "fechar e abrir o projeto fazia aparecer".
- Que o Adauto tenha tocado no 👁 é **hipótese**. O mecanismo está comprovado.

Sonda: s14.

### P1-E. Arrastar a divisória de um módulo não escolhido muda a divisória do módulo escolhido — COMPROVADO
Os alvos `data-d`/`data-s` são desenhados em todos os módulos (1106–1107). O tratador 1219/1225 e o 12181 arrastam `S.m.div[i]` sem conferir de qual módulo é o alvo.
- **Teste com toque simulado** (PointerEvent no `elementFromPoint`): divisória do B arrastada, a do A foi de 0,5 para **0,876** e a do B não mudou.
- O mesmo vale para o 🗑 depois desse toque: `LAST='div'`, aplicado ao `S.m`.

Sonda: s09.

### P1-F. Arquivo vazio apaga a única cópia que sobrou — COMPROVADO
Linha 3085: `if(!pLoadAll().length){…localStorage.setItem(PK,unb64(d))}`. Com `projects.json` = `[]`, o `pLoadAll` (que lê o arquivo primeiro) dá vazio, e o `[]` é gravado por cima do `localStorage`.
- **Teste:** `localStorage` com 1 projeto e arquivo `[]`. Depois de abrir, o `localStorage` ficou com 0.
- Passa por fora de todas as proteções do `pSaveAll`.

Sonda: s08a.

### P2. Gravação e backup — CÓDIGO (não reproduzido em aparelho)
- **Restaurar backup no Android** (`DataBackup.applyPending`):
  - a validação só confere os caminhos;
  - depois apaga `files`, `app_webview`, `shared_prefs` e `databases` e extrai o ZIP;
  - um erro no meio fica num `catch` vazio, e o ZIP pendente é apagado no `finally`;
  - **não existe cópia do estado atual antes de restaurar.** O iOS tem área de preparo e volta (rollback).
  - O Windows é cópia do mesmo código.
- **`putFile` não devolve erro nos 3 nativos:** `pSaveAll` sempre retorna `true`, e o aviso "memória cheia" nunca aparece no app. No Android e no Windows a gravação é feita em arquivo temporário seguido de `rename` (Windows sem `ATOMIC_MOVE`). Se o `rename` falha, grava direto no arquivo. No iOS é `.atomic`, mas por `postMessage`, sem confirmação.
- **O arquivo sempre vence o `localStorage`**, sem comparar datas.
- **Campos fora do `snapState`, perdidos ao reabrir:** `S.pw` (parede de painéis), `S.RDw`/`S.RDs` (lembrança da profundidade), `S.rodLast`, `S.deco`, `S.tvLogo`, `S.tvAnim`. O `S.RDw`/`S.RDs` é candidato a "medida errada depois de reabrir" do ambiente. Não verificado.
- **Voltar no Android** (`arqueBack`) só faz `flush()`: a mexida dos últimos 500 ms pode não ser gravada.
- **Migrações que mudam o projeto ao abrir** (e ficam gravadas por causa do P1-C):
  - 8620: canto < 1200 perde a moldura;
  - `rpRowRepair` (8148): ajusta as placas da fileira;
  - filtro do `stw`: apaga pedra lateral sem parede.

### P2. Toque e seleção — CÓDIGO
- **2 toques na lateral** (1217 EGT): troca o engrosso **e**, 330 ms depois, abre o menu do vão (`tapCount` 1216). Nenhum dos dois zera o outro.
- **9 detectores de 2 toques independentes**, com limiares de 420 a 500 ms. O `tapCount` usa um estado `TQK` compartilhado: a chamada com uma chave cancela o pendente de outra.
- **Editor de ambiente, 2 toques na parede:** `ambSelWall` e, 400 ms depois, `sel3`. O `sel3` pode mudar de parede a porta ou janela escolhida (6441).
- **No editor por vãos**, 4 toques rápidos no vão travam ou destravam o módulo (`tapCount('m')`).
- **`touchstart` com `preventDefault` nas peças da pedra** (2323): o toque não gera click e o mouse gera. São caminhos diferentes por aparelho.
- **Click sintético** 380 ms depois do `pointerup` (61–65): se o desenho mudou nesse meio tempo, o click cai em outro elemento.
- **`SEL3` (peça do 3D) e `S.m`** podem ficar de módulos diferentes por caminhos que não passam por `itOpen`.

### P2. 3D — CÓDIGO
- **Erro em `partsOf`/`cornerBoxes` dentro do `DRM`:** o módulo fica sem nenhuma caixa. O `re3()` não avisa.
- **Edições que montam o 3D sem `draw()`** (área molhada 5594, porta/janela 3948, `lRedo` 5532): o 3D mostra um estado anterior à normalização, e a gravação só acontece no próximo `draw`.
- **O refazer automático do 3D** (12239, `loadState(snapState())`) apaga o histórico de desfazer.
- **Foto de material que falha** nunca é recarregada na sessão.
- **`ANG/ANT`** (portas abertas) usam o índice do módulo: apagar um módulo passa o estado para outro.

### P2. Peças e corte — CÓDIGO
- **Coluna "onde" do plano de corte** (cutGroups 7290, `take`): a peça corrida tira `qty` e não tira de `where`.
- **Camada do forno** (12118): troca `m.v[vi]` por uma cópia e chama a cadeia de novo. O `clPoFollow` pode mexer nas chaves de `m.po/m.pc/m.xp`. Falta teste com forno com recorte e ajuste salvo.
- **Peça apagada que sobrevive em camadas posteriores ao filtro 9654** (fechamento até o teto, espaçador de canto, depurador, frente com recorte do forno): **não reproduzido** nos 142 modelos padrão (s07). Fica como risco para essas configurações específicas.

## 4. Pendências registradas (não implementar agora, sem detalhes inventados)
| Pedido | O que existe no repositório |
|---|---|
| **Churrasqueira quadrada**, conforme a referência enviada pelo Adauto | **Nenhum registro** em commits, `engenharia/`, novidades ou testes. A referência não está no repositório. Precisa ser reenviada. |
| **Correções de textura da pia e da área molhada**, que o Claude anterior tratava | **Nenhum registro do pedido nem de correção** em commits, `engenharia/`, novidades ou testes. O trabalho não foi gravado. O estado atual do código, só como fato (não verificado na tela): a área molhada é uma placa fina **por cima** do tampo (`build_wet` 5567, `dp` e `y0` calculados e não usados), em cor lisa (pedra × 0,72) sem a foto da pedra. A cuba esculpida não recebe a foto da pedra (`cb` é pulado pela `build_stx`). O pedido exato precisa ser reenviado. |

## 5. Plano de correção mínima (para aprovação, nada feito)
Uma correção por vez, cada uma com teste que falha antes, bateria completa depois e registro em `HISTORICO_ERROS.md`.

| Ordem | Erro | Alteração mínima proposta | Arquivo e função | Precisa decidir |
|---|---|---|---|---|
| 1 | P1-F | Na linha 3085, copiar o arquivo para o `localStorage` só se ele **tiver** projetos. Nunca gravar `[]` por cima | `editor.html` 3085 | — |
| 2 | P1-C | (a) Não gravar ao abrir: guardar a assinatura do estado aberto (`SVSIG`) logo depois do `loadState` de abertura. (b) `egL/egR` não são zerados no dado: o engrosso desligado só deixa de gerar peça | `schedSave`, `defs` 274, `partsOf` 509 | (b) muda a lista de corte de quem tem egOn=0 e egL salvo? Proposta: não, porque a peça continua sem engrosso enquanto egOn=0 |
| 3 | P1-D | Desligar `ST3ONLY` ao fechar e ao abrir o 3D e no `loadState`. O diagnóstico do 3D passa a mostrar a chave | `build_stOnly` 6449, `open3D`/`v3x` | — |
| 4 | P1-E | Toque em `data-d`/`data-s` de outro módulo só escolhe o módulo, igual ao tamponamento (38ed268). O arrasto só no módulo escolhido | tratador 1219/1225 e 12181 | — |
| 5 | P1-A | Transformar a catraca em memória do empurrão: o `confineAll`/`roomClamp` guardam o valor pedido (ex.: `m._xPed`, `m._hPed`) e devolvem quando a restrição some. A pessoa que digita ou arrasta passa a ser o novo valor pedido. Altura de torre e largura de forno nunca mudam pelo desenho | `confineAll` 1174, `roomClamp` 3011, `placeFree` 1148, `sanM` 508, `sanBase` 10389 | **Sim:** confirmar que é isso que você quer (empurrar ao encolher e voltar ao crescer) ou se encolher parede só avisa sem mexer |
| 6 | P1-B | Mesma memória do empurrão para o tamponamento: posição pedida = posição pela parede, e o `autoTamp` decide só pela posição pedida. Resolve o vão de 35 mm sem mudar a regra do tamponamento | `autoTamp` 5664, `tpTlVolta` 1554 | Sim, depois do 5 |
| 7 | P2 backup | Android e Windows: cópia completa do estado atual antes de restaurar e volta se a extração falhar | `DataBackup.applyPending` | — |
| 8 | P2 outros | Um por vez, na ordem que você escolher | — | — |

**Fora do plano:** refatoração geral, layout, menus, botões, cores e regras de marcenaria aprovadas.

## 6. Testes permanentes propostos (entram na bateria `EditorWebKitTests.swift` junto com cada correção)
1. **Pureza:** `draw` ×5, `build` ×2, `partsOf`, corte e materiais, no catálogo inteiro e na cozinha demo. Estado idêntico e nenhuma escrita (rastreador).
2. **Ida e volta:** parede, pé-direito, largura/altura/profundidade/espessura, erguer, `sup`, `rack`, tamponamento, pelo campo (`setv`) e pela atribuição. Tudo volta igual.
3. **Determinismo:** mesma entrada vinda de começos diferentes dá o mesmo resultado (x pelo campo, pelo arrasto real e pelo 3D). Ordem dos módulos não muda nada.
4. **Abrir não grava:** projeto aberto e não mexido mantém `updated` e o conteúdo idênticos. O engrosso sobrevive com qualquer ajuste do aparelho.
5. **Arquivo vazio** não apaga o `localStorage`. **Arquivo corrompido** não apaga nada.
6. **3D:** depois de "Só a pedra", fechar ou abrir outro projeto mostra todos os módulos.
7. **Toque:** alvo de outro módulo (divisória, prateleira, tamponamento, lateral) só escolhe. Nenhum toque gera duas ações (2 toques na lateral).
8. **Salvar e reabrir em sequências longas:** criar → base → tamponamento → altura pelo 2D → 3D → porta → salvar → fechar → reabrir → corte, em cada família (balcão, aéreo, torre, guarda-roupa), comparando peças, corte e caixas do 3D.
