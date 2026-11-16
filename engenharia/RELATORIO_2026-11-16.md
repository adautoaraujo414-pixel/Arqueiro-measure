# Relatório da madrugada de 16/11/2026 (Adauto ausente)

Escopo autorizado:
- Corrigir só o gola.
- Auditoria só de leitura.
- Diagnóstico do motor 3D e proposta.
- Plano de evolução.
- Documentação.

Nada foi publicado. Nenhum dado real foi alterado.

## 1. O que foi corrigido
**GOLA-001: perfil G espelhado.** Aprovado às 01:26.
- **Antes:** parede de 42 na frente, abertura dos dedos para dentro do móvel e uma placa escura fechando o vão.
- **Agora:** abertura para a frente, parede de 42 atrás abraçando 13 mm da face de dentro, sem placa. É igual à referência de 12/11 às 01:30.
- **Onde vale:** porta, gaveta, aéreo (perfil embaixo), gola vertical da porta comum e gola lateral do editor por vãos.
- **Não mudou:** desconto de 29, medidas das portas e frentes, metros de perfil, lista de materiais, plano de corte, salvar e reabrir, e os outros puxadores (cava, cava de perfil, facetado, concha, barra, porta de correr).
- **Arquivo:** `app/src/main/assets/editor.html`. Mudaram só o bloco `t==='g'` de `pxParts` e a função `G_` do gola lateral.
- **Evidência:**
  - Seção desenhada com as caixas reais do 3D, antes e depois, ao lado da referência.
  - 6 vistas antes e depois: frente, por trás, lateral, ponta, porta aberta e gola vertical.
  - As imagens foram mandadas na conversa.

## 2. Testes
- **Teste novo:** `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical`.
  - Na versão corrigida: 5 peças, 1 cor, parede atrás de 42 (43 no vertical), maior peça da frente 8 e fundo 18, em todos os casos.
  - Na versão anterior o mesmo teste falha: `pecas 6 · cores 2 · parede atrás 0 · frente maior 42`.
- **Expectativas atualizadas** (de 12 para 10 peças, porque a placa saiu, com o motivo no comentário):
  - `golaPerfil` e `golaAbre` (gola lateral).
  - `b3` (gola vertical).
- **Bateria completa (harness Chromium):** ver a seção 8.
- **iPhone de verdade:** **não testado.**

## 3. O que foi investigado (só leitura)
- Histórico de referências do gola: as 435 imagens da conversa vistas em miniatura. Ver `REFERENCIAS.md`.
- Motor 3D: ver `MOTOR_3D_AUDITORIA.md`.
  - WebGL 1 próprio, 1 shader, luz fixa por face, metal sem reflexo, vidro sem ordenação.
  - Refaz a cena inteira a cada mudança.
- Arquitetura: ver `ARQUITETURA.md`.
  - Editor de um arquivo só.
  - As regras ficam em camadas de embrulhos (`partsOf` 18 vezes, `draw` 41, `panel` 43).
- Gravação de projetos (parcial): `localStorage` + `projects.json` + cópia do arquivo corrompido.

## 4. Erros anteriores identificados
Ver `HISTORICO_ERROS.md`. Os principais:
- **WEBGL-001 (novo, estabilidade):** se o sistema tirar o contexto gráfico (app no fundo ou falta de memória), o 3D fica apagado até reabrir o app. O app não trata esse caso. Reproduzido no Chromium.
- **3D-045:** módulo do 2D que não aparece no 3D no iPhone. Está mitigado, sem causa raiz. Os prints mostram paredes e pedra, então não é perda de contexto.
- **CI do iOS vermelho desde o commit e3d68b8:** o teste `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa` (criado para o PEDIDO 45) espera 1 erro. No WebKit, o erro de teste é anotado 2 vezes ("(peças)" e o geral), porque a pilha de chamadas do JavaScript do Safari é diferente da do Chrome.
  - O comportamento do app está certo: fica a caixa do módulo, os outros aparecem e o aviso sai.
  - **Quem errou foi o teste.** Não mexi nele (fora do escopo autorizado). Proposta: aceitar a contagem das duas engines.

## 5. Pendências que precisam de decisão sua
1. **Perfil G encostando na caixa:** a parede de trás tem 1,5 mm. No 3D ela entra até 1,5 mm na travessa, nas laterais, na base e na caixa da gaveta. Antes da correção já entrava, em área menor. A porta deve ficar 1,5 mm afastada, ou a caixa ganha um rebaixo?
2. **"Sobra malfeita":** era a ponta fechada (tubo com a placa)? Agora a ponta mostra o "C" aberto. Confirme olhando as imagens.
3. Detalhes da referência que não mudei, porque não têm cota ou mexem em outras coisas:
   - Cantos arredondados.
   - Gancho com uns 6 mm em vez de 8.
   - Encaixe de 15,5.
   - Desenho genérico de Ajustes.
   - Porta de correr.
4. **WEBGL-001:** autorizar a correção (baixo risco).
5. **Teste do PEDIDO 45 no iOS:** autorizar o ajuste.
6. **Pedidos 61 e 62** (faixa da parede minimiza; 2 toques no vão do editor por vãos): estão prontos na branch `wip/pedidos-61-62` (commit cbbe30f), **fora** da branch principal. Testados no simulador, falta a bateria completa. Esperam seu ok para entrar.
7. **Repositório público:** o GitHub `Arqueiro-measure` é público. `CLAUDE.md` e `engenharia/` ficam visíveis no GitHub, mas não no site. Por isso não escrevi nada sensível ali. Para ser privado mesmo, o repositório teria que ser privado (o site do link do cliente depende dele) ou a documentação teria que ir para outro repositório privado.
8. **Fase 2 do motor 3D:** escolher os itens da proposta (`MOTOR_3D_AUDITORIA.md`, seção 5).
9. **Plano de evolução:** escolher prioridades (`PLANO_EVOLUCAO.md`).

## 6. Melhorias visuais recomendadas (não feitas)
- Luz com normais (profundidade em rebaixos e no canal do gola).
- Metal com brilho e reflexo por acabamento.
- Vidro com Fresnel e ordenação.
- Não refazer a cena inteira quando uma foto de padrão carrega.
- Liberar texturas sem uso.
- Detalhes em `MOTOR_3D_AUDITORIA.md`.

## 7. Arquivos e commits
- `app/src/main/assets/editor.html`: correção do gola.
- `ios/ArquemestreTests/EditorWebKitTests.swift`: teste novo e 3 expectativas.
- `.github/novidades.txt`: uma linha do gola.
- `CLAUDE.md` (novo).
- `engenharia/` (novo): ARQUITETURA, HISTORICO_ERROS, REGRAS_MARCENARIA, GESTOS_CONTROLES, DECISOES_TECNICAS, REFERENCIAS, MOTOR_3D_AUDITORIA, PLANO_EVOLUCAO, `especificacoes/puxador-gola.md` e este relatório.
- Branch `wip/pedidos-61-62`: trabalho anterior (pedidos 61 e 62) guardado à parte.

## 8. Resultado da bateria
**Bateria completa no harness Chromium, com a correção do gola** (commit fcfcf28): 296 execuções em 35 minutos.

**O que passou:**
- O teste novo do gola.
- As 3 expectativas atualizadas: `golaPerfil "10 true false"`, `golaAbre "10 true"` e `b3 10`.
- `testPuxadoresDescontamCertoEConchaNoMeio`, com desconto de 29.
- `testPortasNaoEntramEmNada…`.
- `testBateriaGeralCatalogoNo3DEPedraNaoEntraEmNada`.

**Falhas conhecidas e aceitas** (iguais na versão anterior):
- `onl`
- `pinkR`
- `depois`

**Falha só com carga:**
- `testOrganizacao3DClienteEModoPessoa` (`clv`, `ro`): rodando sozinho, deu `clv: true, ro: true`.

**Para revisar:**
- `quarto`: o resultado novo é o que o teste espera (`"quarto true true"`). A diferença é da versão antiga de comparação.

**Nenhuma regressão nova.**

**Bateria da versão anterior (e3d68b8, antes do gola):**
- As mesmas falhas conhecidas.
- `testSoOModulo3DE2D…`, que só falha com carga (sozinho passa igual à versão antiga).

**CI do iOS (simulador iPhone, WebKit de verdade), commit fcfcf28 (run 43822406584): 366 testes, 5 asserções falhando.**

O que **passou** no WebKit:
- `testPerfilGolaAberturaPraFrente…` (teste novo do gola).
- `testGolaVerticalEHorizontalEDesenhoDeCadaPuxador`.
- `testPortasNaoEntramEmNada…`, com `golaPerfil 10`.
- `testPuxadoresDescontamCertoEConchaNoMeio`.
- Todos os outros testes de puxador.

O que **falhou**:
1. `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa`: o mesmo problema do teste já descrito na seção 4. Já falhava antes do gola.
2. `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra`: no WebKit, o canto L do guarda-roupa, lado esquerdo, deu `abertas 90/67` em vez de `90/70`.
   - No Chromium, antes e depois do gola, dá `90/70`.
   - Esse teste mede a porta abrindo com espera de 150 ms. **Hipótese** (não comprovada): a animação ainda não tinha terminado no simulador lento.
   - A correção do gola não mexe em porta de canto, nem no ângulo, nem na colisão das folhas. Conferido: as portas do "Canto L guarda-roupa" do catálogo não têm gola (`gola 0`, puxador padrão).
   - Não deu para confirmar se é instável: os commits seguintes só mudaram documentação e o CI do iOS não rodou de novo. Fica pendente rodar o CI do iOS outra vez.

**Aparelho real:** não testado.

---

# Segunda rodada (16/11, depois das 05:43, com a autorização nova)

## Corrigido
| Item | O que mudou | Evidência | Status |
|---|---|---|---|
| WEBGL-001 (3D apagado) | O 3D volta sozinho quando o sistema devolve o contexto gráfico. Projeto, câmera e edição não mudam | Teste novo. Na versão anterior: `apagado`. Agora: `desenha`, mesmo projeto, mesmas caixas, foto do padrão de volta | Resolvido no Chromium e na bateria. Aparelho: não testado |
| Teste do PEDIDO 45 no Safari | Causa: limite de pilha do Chrome (10). O teste agora roda com a pilha sem limite e espera os 2 erros. O app não mudou | No Chromium, com a pilha sem limite, dá o mesmo resultado do log do iPhone | Teste corrigido |
| Teste do canto 67/70 | Causa: o teste lia a animação em 3,5 s fixos, e o simulador dá poucos quadros. Agora espera a animação terminar. O app não mudou (o alvo é 70° pela fórmula) | Reproduzido com quadros a cada 1,2 s: o teste antigo leu 0; o novo dá 90/70 | Teste corrigido |

## Investigado e não corrigido
- **PEDIDO 45 (módulo some no 3D):** não reproduzido.
  - Testados os 119 módulos de cozinha e a cena dos prints, na versão que estava no iPhone (97b6eef) e na atual.
  - Para achar a causa, falta o "🔎 Diagnóstico do 3D", que só existe na versão nova. Ela ainda não está no iPhone, porque subir depende da sua autorização.
- **Gola, interferência de 1,5 mm:** validada peça por peça (ver a especificação do gola, pendência 1).
  - O perfil real também tem parede atrás da porta: 18 de fundo para encaixe de 15,5.
  - Para resolver sem mexer em porta ou caixa, falta saber como você instala: folga da dobradiça ou rebaixo na caixa. **Pergunta aberta.**
- **Gola, comparação com a referência** (pontas, cantos, gancho, porta de correr): está na especificação. Os cantos arredondados, o gancho de uns 6 mm e a porta de correr ficaram como estavam, porque não há cota na referência.

## Pedidos 61 e 62
- A branch `wip/pedidos-61-62` foi rebaseada em cima de tudo isso.
- **Teste novo do 62:** `testEditorPorVaosDoisToquesNoVaoAbreMenuRapidoComAsAbasEBotoesDoPainel`.
  - 1 toque não abre.
  - 2 toques abrem com as 7 abas.
  - "Horizontal" divide igual ao painel.
  - A aba Gavetas mostra 12 botões.
- **Imagem:** faixa minimizada e menu de 2 toques aberto.
- Linhas de novidades acrescentadas.
- Bateria completa: ver abaixo.

## Auditoria de projeto (criar, editar, salvar, fechar o app, reabrir)
- Feita com um harness que recarrega a página, como se fechasse e abrisse o app. O arquivo nativo continua guardado.
- **Projeto criado pelo caminho do app (`newProjFor`) com:** balcão, gaveteiro, aéreo, pedra, gola aplicada numa porta (vai para todas), gaveteiro mudado para 700 de largura e 3 gavetas. Salvo com `saveNow`.
- **Depois de reabrir:**
  - O projeto está na lista.
  - Igual ao salvo: módulos, peças, plano de corte (20 grupos), materiais (Perfil G 3,92 m) e pedra.
  - 3D com todos os módulos (110, 70 e 103 caixas) e sem erro.
  - Gola certo nas 7 frentes (2 portas do balcão, 3 gavetas e 2 portas do aéreo).
- **Achado pequeno:** ao salvar de novo sem mexer, o módulo ganha `wing: 0` no lugar de "sem valor". As duas formas valem "não é módulo de parede lateral", então nada muda no projeto. Anotado para conferir quando mexer em gravação.
- A recuperação de backup está coberta pelo teste da bateria `testRecuperarProjetosDeUmBackupSemTrocarNada`.

## Não feito nesta rodada
- **Protótipo de materiais (metal, vidro, luz de profundidade).** Para ser de verdade (reflexo e Fresnel), precisa de normais nos vértices, o que é mudança estrutural no motor 3D (formato do vértice de 32 para 44 bytes). Não quis fazer um efeito "falso" de brilho que não corresponde ao material. Proposta e custo estão em `MOTOR_3D_AUDITORIA.md`, seção 5. **Preciso do seu ok para mexer no formato do vértice** (em cópia separada, com antes e depois e medição).

## Bateria completa da segunda rodada (harness Chromium, 299 testes, 36 min)
- **Base testada:** gola + 3D que volta sozinho + os 2 testes do iPhone corrigidos + pedidos 61 e 62.
- **Passaram:** os testes novos (gola, contexto do 3D, menu de 2 toques, faixa da parede) e os corrigidos (PEDIDO 45 e canto).
- **Falhas conhecidas e aceitas:** `onl`, `pinkR` e `depois`.
- **Instáveis com carga, que passaram rodando sozinhos:** `testOrganizacao3DClienteEModoPessoa` e `testSoOModulo3DE2D…`.
- **Um teste ajustado:** `testPainelNaoDuplicaEmOutraParedeDepoisDaLista` lia o texto da faixa da parede, e o botão "—" de minimizar (PEDIDO 61) entrou no texto. O teste agora tira o "—" como já tirava Esquerda/Direita. O que ele confere não mudou. Sozinho passou.
- **Resultado:** sem regressão. Os pedidos 61 e 62 foram integrados à branch `feature/arque-measure-kotlin` (commit 1730073). **Não publicado.**

---

# Terceira rodada (16/11, depois das 07:03)

## 1. Gola: afastamento e rebaixo configuráveis
- Ajustes › Puxadores › Perfil G ganhou dois campos:
  - Afastamento da porta até a caixa (`gAfast`).
  - Rebaixo na caixa atrás do perfil (`gReb`).
- Os dois **começam em 0**, que é o comportamento de antes ("a folga do caixote mantém o padrão").
- A nota embaixo mostra quanto o perfil encosta: `1,5 − afastamento − rebaixo`.
- **Afastamento:** move no 3D só a porta ou frente com G (e o perfil dela). A porta sem G fica onde estava.
- **Não mudam:** medidas das peças, desconto de 29 e plano de corte. Teste: `testPerfilGAfastamentoERebaixoConfiguraveisPadraoZeroSemMudarPecas`.
- **Medido com afastamento de 1,5:** o perfil deixa de entrar na travessa e nas laterais do balcão. No aéreo ainda encosta 0,8 mm na fita de borda, mas a **porta** do aéreo já entrava 0,8 mm nessa fita antes, sem gola (FITA-08, pendente).
- **Rebaixo:** só entra na conta. A usinagem não sai no plano de corte nem no 3D, porque falta definir as peças e a altura. **Pendente.**
- **Pendente de confirmação:** a folga real da dobradiça com G e se existe rebaixo.

## 2. PEDIDO 45: teste "módulo cadastrado = módulo no 3D"
- **Teste novo:** `testTodoModuloCadastradoApareceNo3DEmQualquerCaminho`. Confere a contagem e se a tela desenha em 8 caminhos:
  1. Abrir com a foto do padrão carregando.
  2. Depois de a foto carregar.
  3. Refazer a cena.
  4. Perder e voltar o contexto gráfico.
  5. Trocar de parede no 2D.
  6. Abrir a lista de peças.
  7. Fechar e reabrir o projeto, e restaurar o estado.
  8. Criar módulos depois de já ter aberto o 3D.
- **Versão atual:** todos dão N de N e desenham.
- **Versão que estava no iPhone (97b6eef):** a contagem dá certo, mas depois da perda de contexto **a tela inteira apaga**, paredes inclusive. Era o WEBGL-001, já corrigido.
  - O sintoma dos seus prints é outro: paredes e pedra aparecendo e os módulos não.
  - **Esse sintoma continua sem reproduzir. Não está resolvido.**
  - O diagnóstico novo só chega ao iPhone numa versão de teste, que depende de autorização.

## 3. Projetos antigos e novos (fechar e reabrir o app)
- Projeto salvo na versão de 05/11 (bd920b8) e na versão do iPhone (97b6eef), aberto na versão atual depois de fechar o app:
  - Na lista.
  - Mesmos módulos (medidas, posição e cores).
  - Mesma pedra.
  - Plano de corte gerado.
  - Todos os módulos no 3D.
  - Salva de novo sem perder nada.
- Projeto novo: igual à rodada anterior.
- Harness: `aud2.mjs` (abre a versão velha, salva, abre a versão nova com o mesmo armazenamento).

## 4. Protótipo AQRender (cópia isolada, fora do app)
- Ver `prototipos/aqrender/LEIAME.md`. Imagens antes e depois com mesmo projeto, mesma câmera e mesmas peças (562 caixas nos dois).
- **Faz:** luz com normal, sombra suave, metal com brilho e reflexo, vidro com Fresnel, MDF com a mesma cor e veio, e LED só onde a peça é LED.
- **No Chromium sem GPU:** quadro uns 3× mais lento (1,1 s contra 0,3–0,4 s), memória JS igual, mapa de sombra de 6 MB.
- **Não medido em aparelho.**
- **Não faz:** refração, luz do LED nas peças em volta, acabamento do metal como dado do projeto.
- **O motor do app não foi mexido.**

---

# Quarta rodada (16/11, das 07:45 às 09:40)

## 1. Corrigido e testado no Chromium (falta testar no aparelho)
| O quê | Commit | Teste (falha na versão anterior) |
|---|---|---|
| Perfil G sólido: sem madeira dentro e sem granulado | 328f602 | `testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado` |
| Furação da dobradiça com padrão de 120 do MDF da porta, no centro do caneco, igual com qualquer puxador. Quem já usava continua com o valor gravado (opção A) | eb6ed5b | `testFuracaoPadrao120…`, `testFuracaoDaDobradicaNoMesmoLugar…` |
| 3D da dobradiça no mesmo lugar do furo do plano de corte (era 100 fixo; 110 na basculante) | eb6ed5b | idem |
| Tamponamento do vídeo: a seta estica a peça de verdade | 7b9bb3a | `testTamponamentoDoAereoEstica…`, `…AfastadoDaParede…` |
| Setas certas em módulo na parede lateral; travado não estica; para na parede do fundo | 7b9bb3a | `testSetasDo3DNaParedeLateral…` |
| Trava da geladeira (2D e 3D, abre normal) | 0f4644d | `testGeladeiraTravada…` |
| Seta só aparece quando a peça existe na lista | ddb41c8 | auditoria abaixo |

## 2. Auditoria das setas do 3D (136 modelos, 2845 peças)
- Toda peça que dá pra escolher no 3D existe na lista de peças.
- **2786 peças** mudam na lista e no 3D quando esticadas.
- **Que não mudam:**
  - **Lateral de gaveta (40):** por projeto, a caixa da gaveta é ajustada inteira (`gbox`), não lateral por lateral.
  - **Régua espaçadora do canto (8):** as setas de altura aparecem, mas não mexem (a altura vem da porta). **Pendente.**
  - **Rodapé entre laterais até o piso (4):** as setas aparecem e não mexem. **Pendente.**
- **Gaveta interna, frente:** a lista e o 3D mudam juntos pela seta. A medida no 3D é maior que a de corte (inclui o puxador ou recorte?). **A conferir.**

## 3. Editor por vãos em todos os módulos (ramo `exp/editor-vaos-universal`, **não integrado**)
- Ver `especificacoes/editor-por-vaos-universal.md`.
- Fase 1: a conversão só acontece com peças idênticas, e as frentes seguem a regra do módulo comum. 29 modelos convertem idênticos, incluindo os balcões e aéreos simples.
- **Fora desta subida.** Gavetas de cozinha, basculante, vidro, forno, canto e outros ficam para as próximas fases.
- **Erro que já existe no app:** "Só ele no 2D" converte módulo alto e muda peças sem avisar. A trava que corrige isso está no ramo. Falta a decisão do Adauto de trazer pra versão principal antes.

## 4. CI do iPhone
- Em d9b9240, **os 326 testes passaram**. O CI ficou vermelho porque o simulador reiniciou uma vez no meio ("Restarting after unexpected exit, crash, or test timeout"), o que faz o xcodebuild terminar com 65.
- Isso já acontecia em rodadas anteriores, em testes diferentes a cada vez. É instabilidade do simulador. **Pendente investigar.**

## 5. Pendências que dependem do Adauto
1. Porta baixa com 120: na torre do micro-ondas, as portas de 292 e 282 ficam com as dobradiças a 120/172 e 120/162. Falta a regra para porta baixa.
2. Calço da dobradiça entrando na divisória do meio no 3D (16 modelos, já era assim com 100).
3. FITA-08: porta do aéreo 0,8 mm dentro da fita.
4. Folga e rebaixo reais do perfil G.
5. Trazer a trava de conversão do editor por vãos pra versão principal agora?

# Quinta rodada (16/11, das 09:32 às 13:00)
Commits: b3c1e74, 93495d1 e o desta rodada. **Nada publicado.** Detalhes em `HISTORICO_ERROS.md` e `PERFORMANCE.md`.

## 1. Pedidos desta manhã
| Pedido | O que foi feito | Teste principal |
|---|---|---|
| 09:32 tamponamento da torre | 🗑 do tamponamento = desmarcar Usar: a medida e a peça saem juntas | `testTamponamentoDaTorreNoLixo…` |
| 09:33 protocolo de correção | CLAUDE.md, seção 11 | — |
| 10:07 peças que não saem | fundo, gaveta e canto sem fantasma; quadro com as medidas certas na parede lateral | `testToPecaQueO3DOfereceApagar…` |
| 10:23 menu do vão | só o 🗑 junto com os outros; Lixeira embutida na lista | `testMenuDoVaoDoBalcao…` |
| 10:34 / 10:39 / 10:56 saia | armário inteiro 15 mm abaixo da saia (850/100 → 735); sem saia até embaixo da pedra (820) | `testComSaiaNaPedra…` |
| 10:56 tamponamento de baixo | vira peça com base suspenso; travado onde não se aplica | `testTamponamentoDeBaixoSoOnde…` |
| 10:56 chaves das peças (XP-PK) | peça apagada, ajuste, cor e fita seguem a peça | `testPecaApagadaEAjusteDo3D…` |
| 10:56 lateral, base e divisória | saem pela regra do móvel ou ficam bloqueadas com o motivo | `testLateralBaseEDivisoria…` |
| 10:56 testes intermitentes | esperam o estado em vez do relógio | BAT-FLAKY |
| 10:01 desempenho | ver `PERFORMANCE.md` | `testDesempenho…`, `CadernoDesempenhoTest` |

## 2. Erros achados pela bateria do Windows em 93495d1 (corrigidos nesta rodada)
- **XP-PK-SOLO:** entrar e sair do "2D só dele" apagava a cor, o ajuste e a peça tirada das portas. Atingia 34 dos 142 modelos (armários altos, torres, guarda-roupas, closets). Agora são 0. Nunca foi publicado.
- **TB-ROTULO:** o texto da caixinha do tamponamento de baixo mudou sem pedido. Voltou ao que era.
- **TB-INV-NUM:** 9 modelos com base suspenso entraram na conferência do tamponamento invertido, por causa do pedido. A expectativa foi atualizada com o comentário do pedido.

## 3. Testes desta rodada
- **Rodados aqui um por um, no editor atual:** os 3 que falharam no Windows, os 2 novos e mais 7 da manhã (saia, tamponamento de baixo, XP-PK, lateral e base, catálogo salvar e reabrir, "só o módulo", laterais até o piso). **12 de 12 passaram.**
- **Bateria do Windows e do iPhone em 93495d1:** as mesmas 3 falhas, e só elas: 314 de 317 no Windows e 8 asserções no iPhone, todas desses 3 testes.
- **CI de 8dbc7ae:** o Android passou; o Windows e o iPhone ainda rodam (ver mensagem final).
- **Comprovação visual** (imagens enviadas na conversa):
  - saia: armário até 735 com saia e 820 sem saia, no 2D e no 3D;
  - tamponamento de baixo no gabinete suspenso: 800 × 30 × 450;
  - "só ele" antes e depois;
  - 2D e 3D iguais pixel a pixel antes e depois da mudança de desempenho.

## 4. Pendências que dependem do Adauto
1. Aprovar a fase 2 do motor 3D (refazer só o que mudou). É o que falta para a seleção ficar sempre abaixo de 50 ms e a animação perto de 60 FPS.
2. Aprovar o medidor de quadros escondido no "🔎 Diagnóstico do 3D", para medir no iPhone, no iPad, no Tab S9 FE e no Windows.
3. Continua: "só ele no 2D" converte o módulo alto para o editor por vãos (trava no ramo `exp/editor-vaos-universal`). A cor, o ajuste e as peças tiradas agora ficam, mas a conversão em si ainda depende da sua decisão.
4. "Corte do forno" e "Nicho do micro-ondas (aberto)" saem pelo 🗑 com o aparelho ainda no lugar.
5. Profundidade do PEDIDO 59 com a saia (opção A).
6. `testRodape…amort` continua intermitente com a máquina carregada.
