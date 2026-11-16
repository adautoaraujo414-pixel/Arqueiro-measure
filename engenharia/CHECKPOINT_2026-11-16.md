# Checkpoint do Arquemestre: 16/11/2026, 14:56 (horário de Brasília)

**Pausa pedida pelo Adauto às 14:54:** "Quero pausar temporariamente todas as implementações e correções… A partir desse checkpoint, não faça mais alterações até nova autorização."
Este arquivo serve pra quem assumir a engenharia (outro Claude Code) retomar sem perder nada.

**Ler antes de tudo:**
- `CLAUDE.md` na raiz. As regras permanentes valem, inclusive a seção 11, o protocolo global de correção.
- `engenharia/HISTORICO_ERROS.md`.

**Sigla do status:** "Chromium" = testado no Chromium desta máquina; "aparelho" = iPhone, iPad, Android ou Windows de verdade. **Nada foi testado em aparelho nesta sessão.**

---

## 1. Branches e commits

| Branch | Último commit | O que tem |
|---|---|---|
| `feature/arque-measure-kotlin` (desenvolvimento) | este checkpoint, em cima de `0aa152c` | Tudo que está validado nesta sessão, mais este relatório e as ferramentas de teste |
| `wip/area-molhada-2026-11-16` | `f379a2e` (em cima de `0aa152c`) | Área molhada no 3D **pela metade, não validada**. Ver a seção 3 e `engenharia/wip/area-molhada/LEIA.md` nessa branch |
| `main` | **não foi tocada** | — |

**Commits desta sessão** (de `9f3dc3e` pra frente):
- `e28a490`: caixa da geladeira (TORRE-GEL-PORTA).
- `38ed268`: tamponamento no 2D com alvo único e base que não some (TAMP-2D-ALVO), mais `PLANO_PRECISAO.md`.
- `0aa152c`: ambiente: profundidade da sala (AMB-RD) e rebaixo do teto (AMB-TZ).
- `f379a2e` (só na branch `wip/...`): área molhada, rascunho.
- Os commits do checkpoint usam `[skip ci]` pra não disparar nenhum workflow.

**Alterações não commitadas:** nenhuma. A área molhada foi guardada na branch `wip/...` e a `feature/...` ficou limpa antes deste checkpoint.

## 2. Publicação e CI (situação às 14:56)

**Publicado com autorização do Adauto nesta sessão** (antes das 13:34): Android apk-626, Windows e iPhone (TestFlight), todos de `9f3dc3e`.

| O quê | Estado |
|---|---|
| Android apk-626 (`9f3dc3e`) | Publicado. A versão pública anterior era apk-603 |
| Windows (`9f3dc3e`), run 43907504189 | Publicado, sucesso |
| iOS TestFlight (`9f3dc3e`), run **43907510476** | **Ainda rodando** às 14:56. Não foi cancelado nem mexido |
| CI de `e28a490`: Android | sucesso |
| CI de `e28a490`: iOS | falhou (ver 5.2) |
| CI de `e28a490`: Windows | cancelado pelo commit seguinte |
| CI de `38ed268`: Android | sucesso |
| CI de `38ed268`: Windows | **falhou 1 de 322** (ver 5.1) |
| CI de `38ed268`: iOS | rodando |
| CI de `0aa152c`: Android | sucesso |
| CI de `0aa152c`: iOS e Windows | rodando |

- Depois das 13:48 **nada mais foi publicado** e nada pode ser publicado sem novo "sim" do Adauto (`CLAUDE.md`, seção 7). Os pedidos das 13:48, 14:29 e 14:54 proíbem de novo.
- `pages-build-deployment` roda sozinho a cada push. A pasta `docs/` não foi mexida nesta sessão, então o site não mudou.

## 3. Pia e área molhada: textura, geometria e o que falta (pedido de 14:56)

### 3.1 Comportamento esperado
- **Pedido de 14:41:** "Área molhada muito feio o acabamento dessa mancha horrível". Veio uma foto do tablet: pedra granito com uma placa lisa verde-escura retangular em volta da cuba.
- **Resposta de 14:42 à minha pergunta:** "rebaixo da pia área molhada 2 cm, pegue referências na intente [internet]".
- **Referência** (Bella Granitos, "Você conhece os tipos de rebaixo para a área molhada?" e "Rebaixo de Área Molhada: Qual Modelo Escolher para Sua Bancada?"):

  | Rebaixo | Profundidade | Cantos | Como é feito |
  |---|---|---|---|
  | Tradicional | cerca de 2 cm | retos | peças emendadas |
  | Americano | cerca de 2 cm | arredondados | uma peça colada por baixo |
  | Italiano (usinado) | cerca de 0,5 cm | arredondados | no próprio material |

  Ou seja: **a área molhada é a mesma pedra, num nível mais baixo, com um degrau em volta.** Não é outra cor nem uma placa por cima.
- **O que fica esperado no Arquemestre:**
  - mesma pedra (cor e textura) no fundo da área molhada;
  - degrau real com a medida do rebaixo;
  - cantos retos ou curvados, como escolhidos;
  - a cuba de dentro da área molhada assenta no nível de baixo;
  - o 2D e o 3D usam a mesma medida (`wetGeo`).

### 3.2 Defeitos confirmados (reproduzidos no Chromium, com imagem)

| # | Defeito | Onde aparece | Versão | Evidência |
|---|---|---|---|---|
| AM-1 | **A área molhada é uma placa lisa, sem a textura da pedra.** Cor da pedra × 0,72 → no Verde Ubatuba (cor padrão `#27372c`) vira a "mancha" verde-escura da foto. Na pedra clara (Branco Siena) vira uma placa marrom com riscos | 3D | `9f3dc3e` e `0aa152c` | `checkpoint-2026-11-16/area-molhada-antes-3vistas.png`, `…pedra-clara-antes-depois-WIP.png` (a de cima) |
| AM-2 | **Não existe degrau.** A placa fica 0,4 mm **acima** do topo da pedra (0,7 mm de espessura). O "rebaixo" não aparece no 3D; o valor só sai no resumo pra marmoraria | 3D | idem | teste rascunho: "dentro 0 · fora 0" em `9f3dc3e` |
| AM-3 | **Cantos curvos feitos com cilindros e frisos escuros só nos lados esquerdo e direito.** Na pedra clara aparecem como círculos e linhas | 3D | idem | mesma imagem |
| AM-4 | **Rebaixo padrão de 8 mm**; o Adauto pediu 2 cm | dado (`wetDefault`) | idem | teste rascunho: "rebaixo 8 mm" em `9f3dc3e` |
| PIA-1 | **Os cantos arredondados do furo da cuba ficam lisos, sem a textura da pedra e mais escuros**, visível na pedra clara. Já existia antes da área molhada, e a branch `wip/...` **não corrige isso** | 3D | `9f3dc3e`, `0aa152c` e `wip` | `checkpoint-2026-11-16/cantos-do-furo-da-cuba-sem-textura.png` (cantos do fundo do furo, nas 2 primeiras faixas) |

### 3.3 Causa raiz (arquivo `app/src/main/assets/editor.html`; linhas de `0aa152c`)

**AM-1 a AM-3:** embrulho `var build_wet=build;build=function(){…}` (linha ~5567).
- Desenha a área molhada como caixas `bx(…)` entre `y1+.4` e `y1+1.1`, por cima da pedra, com a cor `WC` (cor da pedra × 0,72).
- Os cantos são `cylY(…)` e os frisos `bx(x0-2,x0,…,'#2b3238')`.
- **Por que sai sem textura:** a textura da pedra só é aplicada em peças do grupo `'st'`/`'stc'`, e o índice dela é achado pela cor (`txRGB()[b.c.join()]`). As caixas da área molhada não têm grupo e têm outra cor.
- No desenho do 3D (linha ~3780): `tm = (b.g==='st'||b.g==='stc') ? (b.tx || txRGB()[b.c.join()] || 1) : matTx(b)`.

**AM-4:** `wetDefault` (linha ~5566) grava `dp:8`.

**PIA-1:** `cornFill` (linha ~4622), chamada por `cuba3` (linha ~4624).
- Faz os cantos redondos do furo com `BH(…)` (prisma de polígono) **sem grupo**.
- O desenho de prismas `pfFill` (linha ~3746) só põe textura de madeira (`woodT`). Pedra em prisma sai com a cor lisa.

**Achado ao testar a correção:** mudar a cor de uma peça de pedra (ex.: × 0,9 pra parecer mais funda) **faz ela perder a textura/foto da pedra** e ficar verde e lisa. A textura é escolhida pela cor exata, e o `photoT` pelo material.
- Conclusão: o fundo da área molhada tem que ter **a mesma cor** da pedra.
- O degrau aparece pela geometria e pela quina.

### 3.4 Correção feita (só na branch `wip/area-molhada-2026-11-16`, commit `f379a2e`; **não validada, não publicar**)

Tudo em `editor.html`:
- **`stSlab`:**
  - chama `wetSlab(st,y1)`: rebaixo visível = `min(dp, espessura da pedra − 5)`;
  - chama `wetCut(...)`: recorta as caixas `'stc'` da placa na área da área molhada. A parte de dentro desce (`y1 = yc`), as de fora ficam inteiras (subtração de retângulos);
  - nos cantos curvados, põe a pedra de cima por fora do arco (prismas `BH` com grupo `'stc'` e a textura da pedra);
  - pula canto que cai na cuba ou fora da placa.
- **`cuba3(st,it,y0,yC(it))`:** a cuba cujo centro está dentro da área molhada recebe o topo de baixo. Assim a borda da cuba de sobrepor, a esculpida e a ponte entre cubas ficam no nível do rebaixo.
- **`wetEdge`:**
  - um fio claro de 3 mm em volta do degrau (cor da pedra clareada 38%) com arcos nos cantos, como a quina polida pegando a luz;
  - recorta onde tem cuba.
- **`pfFill`:** prisma com grupo `'stc'` passa a usar a textura da pedra (`stn`). **Só as peças novas da área molhada usam isso**; nenhuma peça antiga tem prisma `'stc'`.
- **`wetDefault`:** `dp:20` pra área molhada nova.
  - **Projeto que já tem área molhada fica com o valor dele (8 mm), sem mudar sozinho.**
  - O valor de reserva `||8` dos lugares que leem `dp` também não foi mudado.
- **O embrulho antigo `build_wet` (placas, cilindros e frisos) foi tirado.** Nenhum outro código lia `b.wet`; conferido com busca.

**Resultado:** o teste rascunho rodou só no Chromium, comparando com `9f3dc3e`. As fotos estão em `checkpoint-2026-11-16/area-molhada-depois-3vistas-WIP.png` e `…pedra-clara-antes-depois-WIP.png`.

| Caso | `9f3dc3e` | `wip` |
|---|---|---|
| Criar pela aba Pedra | 8 mm, sem degrau | 20 mm |
| Pedra dentro / fora / fundo da área | 0 / 0 / 0 | −20 / 0 / −20 |
| Placa de outra cor | 10 | 0 |
| Cantos curvos de pedra | 0 | 4 |
| Pedra de 2 cm | 0 | −15 (sobra 5 mm) |
| Projeto antigo com 8 mm | sem degrau | continua 8, degrau de 8 |
| Salvar e reabrir | igual | igual |
| Tirar a área molhada | pedra inteira | pedra inteira |
| Erros de JS | 0 | 0 |

### 3.5 Pendente na área molhada e na pia (nada disso foi feito)
1. **Consertar o teste rascunho** (`engenharia/wip/area-molhada/teste-rascunho.js` na branch `wip`):
   - os casos "quadrado" e "rebaixo8" mexem na pedra de uma cena que já foi trocada; o resultado deles **não vale**;
   - a "cuba de sobrepor" não foi achada pelo filtro do teste (deu "—"). **A borda no nível de baixo não está comprovada**;
   - o resumo pra marmoraria é `marmHtml(st)`, não `stResumo`.
2. **Não verificado** (pode estar certo ou errado):
   - cantos quadrados (`c:'reto'`);
   - área molhada encostada na ponta da pedra;
   - pedra em L e em U;
   - lixeira de embutir dentro da área molhada;
   - cuba esculpida;
   - toque na pedra no 3D depois do recorte (pegar a pedra certa);
   - os arcos do `wetEdge` em todas as posições;
   - desempenho com muitas pedras;
   - foto no iPad.
3. Passar o teste pra bateria (`ios/ArquemestreTests/EditorWebKitTests.swift`). Hoje **não existe nenhum teste de área molhada na bateria** (busca por `wet|molhad` deu 0). Depois:
   - rodar os 22 testes que têm cuba no 3D;
   - rodar a bateria completa.
4. **PIA-1 (cantos do furo da cuba sem textura):** não corrigido.
   - Caminho provável: dar grupo `'stc'` e `tx` aos prismas do `cornFill`. Isso muda o visual de toda pia, então pedir autorização.
5. **Decisão do Adauto:** o campo "Rebaixo (mm)" (3 a 20) continua, ou fica fixo em 20? Ele disse "2 cm" e não falou do campo.
6. **Visto e não investigado:** linhas retas finas atravessando a pedra clara de ponta a ponta, perto da frente. Aparecem igual em `9f3dc3e` e na `wip`. Não sei se é defeito. Não registrar como erro sem investigar.
7. **2D × 3D:**
   - A vista de cima do 2D desenha a área molhada com `wetGeo` (`wetSvg`, linha ~2297: retângulo azul 10%). É a mesma medida usada no 3D, então largura, posição e raio batem.
   - O 2D não mostra o degrau; não houve pedido pra isso.
   - **Não foi encontrado** problema de sincronização 2D/3D na área molhada.
8. Registrar AM-1…AM-4 e PIA-1 em `HISTORICO_ERROS.md` e na `.github/novidades.txt` **quando** a correção for validada e autorizada.

## 4. Correções concluídas nesta sessão (na `feature/...`, commits acima)

| Código | O que era | Teste (falha na versão anterior → passa agora) | Onde testou |
|---|---|---|---|
| TORRE-GEL-PORTA | Trocar a porta de cima da caixa da geladeira fazia porta do teto ao chão | `testTorreDaGeladeiraTrocarAPortaMexeSoNaPortaDeCimaETamponamentoSegueATorre`, `testTorreDaGeladeiraQueJaVirouPortaInteiraAvisaENaoMudaSozinho` | Chromium. Windows ainda não rodou limpo depois |
| TAMP-2D-ALVO | Mexer no tamponamento pelo 2D erguia o móvel e apagava rodapé, travessa e moldura | `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase` | Chromium passa. **Windows falha** (5.1) |
| XP-PK-SOLO, TB-ROTULO, TB-INV-NUM | Erros da bateria do Windows em `93495d1` | testes no `8dbc7ae` | Chromium e Windows |
| Desempenho (`glFill` sem cópia, 2D sem medir a vista de cima no arrasto) | — | `testDesempenhoArrastarNo2DNaoMedeAVistaDeCimaERefazer3DReaproveitaAMemoria` | Chromium |
| AMB-RD | Errar o comprimento da parede do lado prendia a profundidade da sala | `testAmbienteParedeDoLadoProfundidadeNaoFicaPresaERebaixoNaoPassaDaParede` | Chromium |
| AMB-TZ | O rebaixo do teto passava do fim da parede no 3D | o mesmo teste | Chromium |

- **Conferido no ambiente:** digitar número por número (3, 31, 317…) não mexe em móvel nem painel da parede (sonda `ferramentas/sondas/P_d4.js`). Comportamento correto.
- **81 testes de parede, rebaixo e painel:**
  - 79 passaram de primeira;
  - 2 falharam só com 6 rodando juntos e passaram sozinhos, com a mesma saída de `9f3dc3e`: `testEdicaoAmbiente3DParedeNo2DEAbasLimpas` e `testAbrirPortasEGavetasFuncionaEmTodoJeitoDeModuloDoCatalogo`.
- Detalhes, causas e arquivos de cada erro: `HISTORICO_ERROS.md`.

## 5. Erros encontrados e pendentes

| # | Gravidade | O quê | Estado |
|---|---|---|---|
| 5.1 | P1 (a confirmar) | **Bateria do Windows em `38ed268`:** `testTamponamentoNo2D…` falha. Erguer deu `b590` (esperado `b1410`); ao voltar pro chão o módulo foi pra `x4675` (esperado `x3800`); o corte mudou porque o módulo se separou do vizinho. Pode ser só o teste dependendo do tamanho da tela, ou o arrasto do corpo também mexer na horizontal no Windows | **Não investigado.** Não afrouxar o teste sem achar a causa |
| 5.2 | P2 | **iOS:** `testDivisoriaArrastaComODedoEmQualquerProjetoECaminho` ("não arrastou", Balcão porta + gavetas) falha só no iOS desde `8dbc7ae`; passa no Chromium. O CI de `e28a490` falhou no iOS (não abri o detalhe desse run) | Causa desconhecida; sem WebKit aqui |
| 5.3 | P1 | Área molhada (AM-1…AM-4) | Correção na `wip`, não validada (seção 3) |
| 5.4 | P3 | Cantos do furo da cuba sem textura (PIA-1) | Não corrigido |
| 5.5 | P2 | **Regra nova "parede do ambiente tem 15 cm, não se mexe" (14:42) ainda não implementada.** O quadro "Paredes" do 3D tem o campo "Espessura (mm)" (`wallSetK` chave `wt` → `S.wall[s].t`); o padrão no código é 150 (`wallCfg`) | Precisa de pedido de implementação: tirar ou travar o campo. Projeto antigo com outra espessura não muda sozinho |
| 5.6 | Risco identificado (código, não reproduzido) | `partsOf(m)` grava dado: `if(!ENGON()){m.egL=0;m.egR=0}` apaga o engrosso das laterais de todos os módulos quando o engrosso está desligado nos Ajustes, e não volta ao religar. Também `sanM` grava largura mínima do forno e normaliza campos | Reproduzir antes de chamar de erro (fase 5 do `PLANO_PRECISAO.md`) |
| 5.7 | Risco identificado | Família da geladeira: nas torres quentes (9 modelos), no balcão de forno e no porta-tempero, "1 porta" da seção geral troca o vão inteiro | Depende de decisão do Adauto |
| 5.8 | Limite conhecido | AMB-RD: a profundidade lembrada (`S.RDw`) não vai pro arquivo. Depois de reabrir, a profundidade fica a que estava (não muda sozinha) | Documentado |
| 5.9 | P3 | O editor do ambiente grava (`snap`) a cada tecla: o desfazer volta número por número | Não mexido |
| 5.10 | — | Testes que oscilam com o computador carregado (BAT-FLAKY, `testRodape…` amortecedor) | Ver `HISTORICO_ERROS.md` |
| 5.11 | — | A imagem do pedido das 14:29 (parede direita 3170 × 3400, rebaixos 3170 e 1000) **não veio anexada**. A auditoria usou as medidas escritas | Pedir a imagem se precisar comparar a tela |

## 6. Regras de marcenaria aprovadas
- **Lista completa:** `engenharia/REGRAS_MARCENARIA.md`, atualizado neste checkpoint.
- **Novas hoje:**
  - **Parede do ambiente: profundidade (espessura) de 15 cm, fixa. "É regra."** (A, 16/11: mensagem de 14:42 e resposta à pergunta logo depois). Implementação pendente (5.5).
  - **Área molhada da pia: rebaixo de 2 cm.** (A, 16/11 14:42). Implementação na `wip` (seção 3).
  - **Caixa da geladeira:** a porta pertence ao vão de cima; o tamponamento pertence à estrutura e desce até o chão. (A, 16/11 13:34)
  - **Editor do ambiente no 3D com "Mesma altura em todas" ligado:** o Adauto respondeu "sem preferência". Fica como está: o editor 3D muda só a parede escolhida e o modo fácil continua "mudou uma, mudam todas".

## 7. Decisões de arquitetura (já em uso)
1. **Fonte única:** `partsOf(m)`. O 2D, o 3D, a lista, o corte e o orçamento leem dela.
   - Identidade da peça: `pk` = nome + número.
   - A peça segue o objeto do vão (`clPoFollow`, que guarda `{ids, vus}` e passa a identidade quando o vão é trocado por cópia no mesmo lugar).
2. **Corrigir na causa, no componente compartilhado.** Nada de peça visual de mentira. Exemplos:
   - rebaixo do teto cortado na hora de desenhar (`tzClamp`), sem apagar a medida guardada;
   - módulo erguido guarda o que tinha no chão (`m._noChao`) e devolve.
3. **Projeto antigo nunca muda sozinho ao abrir.** Mudança de padrão vale só pro que for criado depois (ex.: rebaixo de 20 mm).
4. **Alvo único por toque** (fase 1 do `PLANO_PRECISAO.md`): começou pelo tamponamento. As fases 2 a 5 (travas, edição que valida antes de gravar, escolha de peça sobreposta, regras que gravam dado) **dependem de aprovação**.
5. **3D:**
   - `glFill` escreve em memória reaproveitada (`FB3`/`fb3(k)`), sem cópia;
   - resolução dinâmica testada e **descartada**, porque ficou mais lenta (`PERFORMANCE.md`);
   - peças contínuas (base, rodapé) desenhadas pelo vizinho e listadas uma vez no corte.
6. **Testes:**
   - cada correção tem um teste que falha na versão anterior (cópia em `editor.<sha>.html`) e passa agora;
   - expectativa de teste só muda com comentário citando o pedido e a data.
7. **Publicação:** só pelo processo manual (`android.yml`/`windows.yml` com `modo=publicar` e `confirmar="PUBLICAR <sha7>"`; TestFlight com `testflight=true`), sempre com o "sim" do Adauto pra aquela versão e plataforma.

## 8. Ferramentas em desenvolvimento (guardadas em `engenharia/ferramentas/`)
Os caminhos dentro dos scripts apontam pra pasta de rascunho desta sessão. Quem continuar precisa ajustar.

| Arquivo | Pra quê |
|---|---|
| `ediph.mjs` | Abre o `editor.html` no Chromium (tela de celular), roda um JS e imprime o resultado e os erros |
| `edx.mjs` | Igual, com o editor escolhido por `ED=<arquivo>` (pra comparar com a versão anterior) |
| `ext3.py` | Extrai os JS dos testes do `EditorWebKitTests.swift` pra `ios3/<teste>_0.js` |
| `chk1.py` | Confere a saída de um teste com as expectativas do Swift |
| `rt.sh` / `rtp.sh` | Roda testes da bateria pelo nome (`rtp.sh` roda 6 juntos; com carga alguns oscilam) |
| `addtest.py` | Transforma um JS de sonda + saída num teste Swift novo |
| `synchk.mjs` | Confere a sintaxe dos blocos `<script>` do editor ("blocks 118 bad 0") |
| `vis/*.mjs`, `vis/sheet.py` | Fotos do 2D e 3D e folhas de comparação |
| `sondas/*.js` | Sondas dos erros desta sessão (ambiente, geladeira, tamponamento, desempenho, digitação) |

**Planejado, sem código ainda:**
- **Conferidor de atualização na hora** (pedido de 14:39): pra cada controle de cada aba (reaproveitando a varredura dos testes `testNadaDeEnfeite…`), comparar:
  - (a) o 2D logo depois do toque com o 2D redesenhado do zero, pra achar dado velho na tela;
  - (b) peças (`partsOf`), corte e 2D antes e depois de `saveNow` → recarregar o projeto salvo, pra achar o que só aparece ao reabrir;
  - (c) 3D (`__boxes`) antes e depois de reconstruir.
- **Sequências aleatórias com semente** e redução até a menor repetição (pedido de 14:29).
- **Documentos** `AUDITORIA_GERAL.md`, `MATRIZ_TESTES.md` e `REGRESSOES_ARQUEMESTRE.md`: **ainda não criados.**

## 9. Próximas tarefas (em ordem), todas dependendo de nova autorização
1. **Área molhada:** terminar a seção 3.5, passar o teste pra bateria e pedir a decisão do campo "Rebaixo". Depois juntar a `wip` na `feature`.
2. **Investigar a falha do Windows** em `testTamponamentoNo2D…` (5.1).
3. **Regra da parede de 15 cm** (5.5): perguntar se tira o campo "Espessura" ou se só trava.
4. **Auditoria do pedido de 14:29 e 14:39:** mapa da arquitetura, matriz de riscos, conferidor da atualização na hora, validadores de integridade, sequências com semente, e os documentos `AUDITORIA_GERAL.md`, `MATRIZ_TESTES.md` e `REGRESSOES_ARQUEMESTRE.md`.
5. **Churrasqueira quadrada de embutir** (pedido de 14:34, não começado):
   - largura externa inicial de 900;
   - as outras medidas (altura, profundidade, abertura, moldura, altura da abertura, paredes, base) **têm que ser pedidas ao Adauto, não inventadas**;
   - alvenaria, revestimento, pedra e metal não entram como MDF no plano de corte.
6. **Pendências antigas que esperam decisão:**
   - fase 2+ do motor de precisão;
   - medidor de FPS;
   - conversão do "só ele" do editor por vãos;
   - corte do forno;
   - PEDIDO 59;
   - família da geladeira (5.7);
   - erro do iOS (5.2).
7. **Não publicar nada** sem o "sim" do Adauto pra versão e plataforma.

## Fontes da referência da área molhada
- [Você conhece os tipos de rebaixo para a área molhada? (Bella Granitos)](https://www.bellagranitos.com.br/noticia.php?noticia=2)
- [Rebaixo de Área Molhada: Qual Modelo Escolher para Sua Bancada? (Bella Granitos)](https://www.bellagranitos.com.br/noticia.php?noticia=12)
