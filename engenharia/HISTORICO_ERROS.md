# Histórico de erros

Erro relatado pelo Adauto ou achado na bateria. Cada um tem teste quando dá para automatizar.
Status possíveis: **resolvido** (reproduzido antes, validado depois, com teste), **mitigado** (sem causa raiz), **pendente** e **não reproduzido**.

Fontes:
- Mensagens do Adauto.
- Commits.
- As notas de trabalho das sessões, que não estão versionadas. O que veio só das notas está marcado "(notas)".

Começou em 16/11/2026. Os erros anteriores a essa data estão aqui só quando a causa e a correção estão confirmadas.

---

## GOLA-001: perfil G espelhado (abertura dos dedos para dentro)
- **Relatado:** 16/11/2026 às 00:58, com print: "Puxador gola invertido pra dentro… sobra mal feita… deve mostrar a característica real".
- **Afeta:** 3D do puxador gola horizontal (porta, gaveta e aéreo), gola vertical (porta comum) e gola lateral do editor por vãos.
- **Esperado:** abertura para a frente, parede de 42 atrás abraçando 13 mm, sem placa. Referência de 12/11 às 01:30.
- **Errado:** parede de 42 na frente, abertura virada para dentro do móvel e placa escura fechando o vão. Na ponta, parecia um tubo fechado.
- **Reproduzir:** pôr gola num balcão, abrir o 3D e ver a porta aberta por dentro, ou rodar `testPerfilGolaAberturaPraFrente…` na versão anterior, que dá `parede atrás 0 · frente maior 42`.
- **Causa raiz:** no commit 41fab29 (12/11), o desenho técnico foi lido com a frente do lado errado. A mesma seção foi copiada para o gola lateral e o vertical (b3760c8, 205603a).
- **Arquivos:** `app/src/main/assets/editor.html`, em `pxParts` (bloco `t==='g'`) e na função `G_` do gola lateral.
- **Correção:** seção espelhada em relação ao meio da porta e placa removida. Descontos, comprimentos, materiais e salvamento não mudaram.
- **Testes:** `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical` (novo) e mais 2 expectativas atualizadas de 12 para 10 peças, por causa da placa removida.
- **Evidência:** imagens antes e depois (frente, por trás, lateral, ponta, porta aberta e gola vertical) e seção desenhada a partir das caixas reais do 3D. Estão no relatório de 16/11.
- **Risco de voltar:** baixo, porque o teste falha se a orientação inverter.
- **Status:** resolvido no simulador e na bateria. **Não testado em aparelho real.** A "sobra malfeita" ainda depende da confirmação do Adauto (ver `especificacoes/puxador-gola.md`, pendência 7).

## TAMP-SETA: tamponamento não aumentava pela seta do 3D (vídeo de 16/11 às 08:30)
- **Relatado:** vídeo no tablet. Com 2 toques no tamponamento, apareciam as setas. Arrastando, o rótulo subia ("Profundidade 95… 310… 675 mm · tampou até o fundo"), mas a peça não mudava. Ao soltar, ficava igual.
- **Reproduzido:** no editor atual e na versão do iPhone (97b6eef).
  - Aéreo com tamponamento de 80 mm: o toque escolhe `Tamponamento esquerdo (régua)#1`.
  - A seta grava o ajuste nessa chave. Rótulo 155, peça 750×80, 3D 80.
- **Causa raiz:**
  - O PEDIDO 37 (15/11) fez o toque na régua do tamponamento escolher só a régua, pra poder apagar só ela.
  - Só que a régua é um pedaço do desenho, não uma peça da lista (`partsOf`).
  - O quadro da peça sumia (`e3Part` nulo). As setas (`e3Handles`, chamadas a cada redesenho) apareciam mesmo assim.
  - O arraste gravava `m.po['… (régua)#1']`, que nenhuma peça lê.
- **Correção** (`editor.html`, perto de `e3Fine` e `e3Bounds`):
  - `e3K()`: esticar, digitar a medida e "Original" sempre mexem na peça de verdade (o tamponamento inteiro, `SEL3.ppk`).
  - O 🗑 continua apagando só a régua (PEDIDO 37) e agora diz "Só esta régua".
  - A seta só grava se a peça existir na lista.
- **Achados na mesma investigação (mesma ferramenta de setas):**
  - **Módulo na parede da esquerda ou da direita:** o 3D gira o módulo, mas as setas usavam o eixo do mundo. A seta de profundidade mudava a largura, e o rótulo mostrava uma medida que não era a da peça. O tamponamento desses módulos não tinha seta de profundidade. Corrigido com `e3Ax` e `e3LAx`.
  - **Módulo travado (🔒):** as setas do 3D esticavam a peça mesmo travado. Agora avisam "Módulo travado", igual às outras edições.
  - **Puxando pra trás passava da parede do fundo.** Agora para na parede ("tampou até o fundo").
- **Testes (falham na versão anterior e passam agora):**
  - `testTamponamentoDoAereoEsticaPelaSetaDo3DMesmoTocandoNaReguaListaCorteE3DReabre`: 4 falhas antes.
  - `testTamponamentoDoAereoAfastadoDaParedeEsticaAteOFundoPelaSeta`: 4 falhas antes.
  - `testSetasDo3DNaParedeLateralMexemNaMedidaCertaEModuloTravadoNaoEstica`: 5 falhas antes.
  - O que eles conferem: o toque de verdade na régua, a seta arrastada, a lista de peças, o 3D, o plano de corte (`cutLines`), salvar e reabrir, e o 🗑 da régua.
- **Status:** corrigido no Chromium. **Não testado no aparelho.** Falta o Adauto conferir no tablet.

## GEL-TRAVA: travar a geladeira (pedido de 16/11 às 08:32)
- **Pedido:** "opção de travar geladeiras também, pra não ficar mexendo; aí só abre normal mas não mexe". Veio com print do 2D: os módulos têm cadeado e a geladeira não.
- **O que já existia:** o campo `lock` do eletro era respeitado no arraste do 3D e nos números do 3D, mas não havia botão pra travar, e o 2D não conferia.
- **Feito:**
  - Botão 🔓 Travar / 🔒 Travada no quadro da geladeira no 2D e no 3D.
  - Cadeado no desenho do 2D.
  - Travada, nada mexe nela:
    - 2D: arrastar, as bolinhas de esticar, os campos digitados (quadro e painel), centralizar, girar e remover;
    - 3D: setas, 2 toques pra mudar de lugar, girar e tirar.
  - A porta abre e fecha normal.
- **Teste:** `testGeladeiraTravadaNaoSaiDoLugarNemMudaDeMedidaMasAbreNormal`. Na versão anterior, a geladeira "travada" saía do lugar arrastando (de 2000 pra 0) e pelo número digitado.
- **Status:** feito no Chromium. **Não testado no aparelho.**

## GOLA-002: madeira aparecendo dentro do perfil G (perfil parecia transparente)
- **Relatado:** 16/11 às 07:45, com a referência do perfil sólido: "não pode só encostar no corpo do armário, ficar transparente e mostrando as costas do armário".
- **Causa raiz** (auditoria das 07:38):
  - A parede de trás do perfil (1,5 mm) fica no mesmo plano da frente da travessa, porque a porta encosta na caixa. As duas superfícies disputavam o pixel e apareciam listras da travessa.
  - O perfil claro (inox, branco) recebia o granulado do MDF (`matTx` = 6).
- **Correção:** o perfil é desenhado numa passada própria, por cima do que coincide com ele (`GB.g` + `polygonOffset(-1,-2)`), e sem textura de MDF. Geometria, porta, caixa, descontos e dobradiças não mudaram.
- **Teste:** `testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado` (antes: `não · 0 peças`; agora: `sim · 40 peças`).
- **Status:** resolvido no Chromium, nos testes do gola e do 3D (bateria completa: ver o relatório de 16/11). **Não testado em aparelho real.** A interferência física de 1,5 mm continua pendente (`especificacoes/puxador-gola.md`, pendência 1).

## DOB-3D-FURD: dobradiça no 3D não segue a distância do furo de Ajustes (achado em 16/11)
- **Medido:** com `furD = 120` em Ajustes, o plano de corte fura a 120 das pontas da porta, e o 3D desenha a 100.
- **Causa:** `hinges3` usa `off = 100` fixo (ou 20% da altura em porta com menos de 300 mm). Não lê `STD().furD` nem `p.fur`.
- **Com o padrão (100):** os dois batem, com externo, cava e gola.
- **Correção (16/11, junto com o padrão de 120 pedido às 08:07):** o 3D desenha a dobradiça no centro do furo da lista (`p.fur.pos`), na porta comum e na basculante. Sem furo (porta de vidro ou furo desligado), usa a distância de Ajustes.
- **Status:** resolvido no Chromium. Teste: `testFuracaoPadrao120NoCentroDoCanecoAjustavelEInstalacaoAntigaFicaCom100` (antes: `com110 … 3D 100, 605`). **Não testado em aparelho real.**

## DOB-DIVISORIA: calço da dobradiça entra na divisória no 3D (achado em 16/11)
- Em 16 modelos com divisória ou montante entre portas, o calço da dobradiça fixado na divisória entra nela no 3D. É igual com 100 e com 120.
- **Status:** pendente. Só no 3D.

## TESTE-FAIXA-WEBKIT: testes da faixa da parede falhavam só no CI do iPhone (16/11)
- `testTrocaDeParedeSoPeloCabecalhoDo2DSempreVisivelEPainelGuardado`: o teste é anterior ao PEDIDO 61 e não esperava o botão "—" de minimizar. Também falhava no Chromium. Expectativa atualizada, com comentário do pedido e da data.
- `testFaixaDaParedeMinimizaEAbreDeNovo`: o Safari devolve um espaço a mais no fim do `innerText` ("— ", "Paredes "). O teste agora compara sem o espaço sobrando. O app não mudou.

## IOS-ABRE-20S: `testEditorAbreComoNoAppSemTelaBranca` passa do limite de 20 s no CI
- 13/11: falhou com 43 s e passou na repetição com 3 s. Em outras rodadas passou com 14 a 22 s.
- 16/11 (1730073): 24,7 s.
- É o primeiro teste a abrir o editor no simulador (início a frio). **Não mexi no limite** (regra: não afrouxar teste). **Pendente:** ver se repete nas próximas rodadas.

## 3D-045: módulo criado no 2D não aparece no 3D (iOS)
- **Relatado:** 15/11 às 10:36 e 16/11 às 00:45/00:53. Fechar e abrir o projeto de novo fazia o módulo aparecer.
- **Verificado:** no Chrome, no simulador iOS e sem WebGL os módulos aparecem. Nos prints de 16/11 às 00:45, as paredes e a pedra aparecem e os módulos não. **Não é perda do contexto WebGL**, porque com o contexto perdido nada apareceria.
- **Mitigação (commit e3d68b8):**
  - Cada módulo é montado separado no 3D (`ERR3`).
  - O app aponta quando um módulo ficou sem caixas.
  - O 3D refaz a partir do projeto salvo e avisa.
  - Há o botão "🔎 Diagnóstico do 3D".
- **Status:** mitigado. **Causa raiz desconhecida.** Para achar, falta o texto do diagnóstico ou o backup do projeto.

- **Investigação de 16/11:**
  - Versão que estava no iPhone dele (TestFlight do commit 97b6eef): cada um dos 119 módulos do catálogo de cozinha, criado sozinho e aberto no 3D, apareceu (0 falhas).
  - Mesma versão, cena dos prints de 00:44 (gaveteiro + balcão 1 porta + balcão forno + pedra + aéreo, com "Só ele no 2D" e voltar): todos aparecem.
  - A mesma cena na versão atual também aparece.
  - **Não reproduzido.** Hipótese, não comprovada: algum campo do módulo recém-criado ficava inválido até o projeto ser reaberto (a reabertura normaliza os dados). O diagnóstico e o refazer automático do commit e3d68b8 ainda não estão no iPhone dele, porque é preciso subir uma versão nova, e isso depende de autorização.
## WEBGL-001: perda do contexto gráfico não era tratada
- **Achado:** auditoria de 16/11. O código não escutava `webglcontextlost` nem `webglcontextrestored`.
- **Reproduzido no Chromium:** depois de `WEBGL_lose_context.loseContext()` e `restoreContext()`, o 3D ficava de uma cor só, mesmo fechando e abrindo o 3D. Só recarregar o app resolvia.
- **Correção** (autorizada em 16/11 às 05:43):
  - O app segura o contexto (`preventDefault`).
  - Quando o contexto volta, refaz shader, texturas e buffers e desenha de novo.
  - Não mexe no projeto (`S`), na câmera nem na edição.
  - Código: logo depois de `glInit()` em `editor.html`.
- **Teste:** `test3DVoltaSozinhoQuandoOSistemaTiraEDevolveOContextoGrafico`.
  - Na versão anterior: `voltou false · depois apagado · reabre3D apagado`.
  - Agora: `desenha`, mesmo projeto, mesmas caixas, foto do padrão de volta.
- **Status:** resolvido no Chromium e no CI. **Não testado em aparelho real.** Para testar no aparelho, é preciso forçar a perda de memória gráfica.

## TAMP-ENGROSSO: engrosso do tamponamento entrando no módulo
- **Relatado:** 16/11 às 00:55 ("erro gravíssimo").
- **Verificado:** todos os módulos do catálogo, mais o caso do balcão com forno, mantêm o tamponamento por fora (`testTamponamentoSempreForaDoModuloEmTodosOsModelosComReguasDe80`).
- **Status:** não reproduzido. Falta saber em qual módulo e de que lado.
- **Atualização 22/11:** reproduzido no tamponamento de **25 mm** (ver TAMP-25-3D). O teste de 16/11 só usava 30.

## FORNO-3MM: folga em cima do forno embutido
- **Relatado:** 16/11 às 00:55 e 01:02. A folga entre a parte de cima e o forno tem que ser de 3 mm.
- **Correção (e3d68b8):** forno novo fica a 3 mm da travessa. O bloco do forno não deixa sair `NaN`. Teste `testFornoEmbutidoNoBalcaoA3mmDaTravessaESemNaN`.
- **Status:** resolvido para forno novo. Forno de projeto antigo mantém o valor salvo (o app não muda nada sozinho).

## CANTO-3MM: portas do armário de canto em L batendo
- **Pedido:** 15/11 às 21:50, folga de 3 mm entre as folhas.
- **Correção:** 97b6eef e anteriores. Teste `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra`.
- **Status:** resolvido.

## TESTE-45-WEBKIT: teste do PEDIDO 45 dava resultado diferente no Safari
- **Causa real:** o teste dispara um erro olhando se `DRM` está na pilha de chamadas. O Chrome guarda só 10 chamadas (`Error.stackTraceLimit=10`). Como o `partsOf` é embrulhado 18 vezes, `DRM` sai da pilha e o erro não cai dentro das peças. O Safari guarda mais e cai.
- Comprovado: no Chromium, com `Error.stackTraceLimit=Infinity`, o resultado fica igual ao do iPhone.
- **Correção (só no teste):** pilha sem limite durante o teste e expectativa com os 2 erros ("(peças)" e o geral), igual nos dois. O app não mudou.

## TESTE-CANTO-67: armário de canto do guarda-roupa abria 67° em vez de 70° no CI do iPhone
- **Causa real:** o teste lia o ângulo da animação em 3,5 s fixos. No simulador do iPhone (WebView fora da tela) os quadros de animação vêm espaçados, e a folha do lado ainda estava abrindo.
  - O alvo do app é calculado por fórmula (`cnAng_`) e é 70°.
  - Reproduzido no Chromium com quadros a cada 1,2 s: o teste antigo leu 0.
- **Correção (só no teste):** espera a animação chegar ao alvo, até 10 s, continuando a conferir que as folhas não se cruzam. Com quadros a cada 1,2 s agora dá 90/70. O app não mudou.

## BAT-FLAKY: testes que falham só com carga
- `testSoOModulo3DE2DComPortaGavetaEDivisoriaSoNele`: falhou na bateria de 16/11 (e3d68b8) e passou rodando sozinho, com resultado igual ao da versão anterior.
- `testOrganizacao3DClienteEModoPessoa` (clv/ro) e `testRodape…` (amort): o mesmo comportamento (notas).
- Falhas aceitas e conhecidas, que vêm das notas: `onl`, `pinkR` e `depois`.
- **Status:** pendente. É instabilidade de tempo no harness com 3 processos em paralelo, não do app. Antes de declarar uma falha, sempre rodar o teste sozinho de novo.

## BAT-SILENCIO: bateria pulava teste com erro (notas)
- Os scripts de conferência pulavam em silêncio o teste que não devolvia JSON.
- **Corrigido:** agora imprimem "SEM RESULTADO" e contam como falha.

## TAMPA-CEGA: tampa cega virava porta comum no "2D só dele" (notas, p119)
- **Causa:** `soloOn → rgConvert` não levava o `v.fixa`.
- **Correção:** a árvore do editor por vãos guarda `p.fx`.
- **Teste:** `testTampaCegaContinuaCegaNoEditorPorVaosNaoAbreSemDobradicaNemPuxador`.
- **Status:** resolvido.

## TECLADO-TOQUE: primeiro toque perdido depois do teclado (notas)
- **Causa:** ao fechar o teclado, a página descia no meio do toque.
- **Status:** resolvido, com teste.

## VALORES-FERRAGEM: tabela Material sem linha da corrediça oculta e do facetado (notas, p153)
- **Status:** resolvido. Teste `testTelaValoresTodaFerragemQueEntraNoTotalTemLinhaNaTabela`.

## FITA-08: porta do aéreo encosta 0,8 mm na fita de borda da caixa (achado em 16/11)
- **Medido no 3D:** no aéreo, a porta vai de `z = 356` a `z = 371`, e a fita de borda das laterais e da base vai de `z = 356` a `z = 356,8`. A porta entra 0,8 mm na fita. No balcão isso não acontece, porque a porta fica na frente da travessa.
- Só no 3D. O plano de corte não muda.
- **Status:** pendente. Precisa de decisão: a porta do aéreo deve ficar na frente da fita? Isso muda a posição de todas as portas do aéreo no 3D.

## TAMP-XP: tamponamento da torre marcado, contado na medida e sem a peça (print de 16/11 às 09:15 · pedido prioritário 09:32)
- **Relatado:** torre 800 × 2600 com forno e micro-ondas. Aba Tamponamentos: direito com "Usar (já existe)" marcado, medida "890 com tamponamento", mas sem a linha "Peça:" e sem "Inverter". Marcar de novo não punha a peça.
- **Módulo:** torre (achado), mas o mecanismo é de todos os módulos com tamponamento.
- **Reproduzir:** tamponamento direito marcado → 1 toque na peça → 🗑 (ou ✏️ no 3D → 🗑). Resultado antigo: `tr true · rt 30 · sem peça · tiradas 1`; desmarcar e marcar "Usar" continuava sem peça.
- **Causa raiz:** o 🗑 "apaga só a peça" (`pcDelAt`) põe qualquer peça na lista de peças tiradas `m.xp`, que o `partsOf` esconde do 2D, 3D, lista, corte e orçamento. Para o tamponamento, a marcação `m.tr` continuava ligada, e é ela que a medida (`lt`/`rt`), o encaixe na parede e os vizinhos usam. Duas fontes de verdade: a marcação contava, a lista de tiradas escondia. A caixinha "Usar" não limpava a lista.
- **Arquivos e funções:** `editor.html`: `pcDelAt`, filtro `partsOf_xp`, `lt`/`rt`, handler `data-c`, `tampOpt`, `tampHtml`.
- **Outros afetados (investigados):**
  - tamponamento esquerdo, de cima e de baixo: mesmo erro comprovado;
  - lado do canto: a peça sumia e a marcação ficava;
  - régua/engrosso do tamponamento: o 🗑 tira só a régua, de propósito (PEDIDO 37), e continua igual.
  - Catálogo inteiro com o 🗑 em cada tamponamento: ver o teste universal.
- **Correção:**
  - O 🗑 num tamponamento passa a ser o mesmo que desmarcar "Usar" (`tpDesliga`), pelo mesmo caminho da caixinha: sai a peça e sai a espessura da medida, o módulo volta o que tinha sido empurrado, e ↶ desfaz.
  - Marcar ou desmarcar "Usar" limpa da lista de tiradas o que era daquele tamponamento (`tpXpLimpa`): marcou, a peça existe de verdade.
  - Projeto antigo que já ficou assim não muda sozinho: a aba mostra o aviso (`tpApagadaNota`) e a pessoa decide.
- **Testes:**
  - `testTamponamentoDaTorreNoLixoDesmarcaAMedidaSegueAPecaEProjetoAntigoSoAvisa`: 2D, 3D, desfazer, projeto antigo, desmarcar/marcar, lista, corte, 3D, salvar/reabrir, superior e canto.
  - `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo`: regra universal com o 🗑.
  - Os dois falham na versão anterior (`editor.pre204`) e passam depois.
- **Status:** resolvido na bateria (Chromium). **Não testado em aparelho real.** Commit: ver o log ("Tamponamento: 🗑 = desmarcar…").

## TB-MED: "aumentar comprimento" do tamponamento de baixo contava na medida sem peça (achado na investigação do TAMP-XP, 16/11)
- **Reproduzir:** balcão com tamponamento inferior marcado e "aumentar à direita" 100. Resultados:
  - medida +100 com a caixinha desmarcada;
  - medida +100 em módulo com base, que não gera a peça;
  - medida +100 em módulo sem base no chão, onde a peça fica entre as laterais e não estica.
  - Antes: `rt 100` nos três.
- **Causa raiz:** `lt`/`rt` somavam `tbL`/`tbR` em todo módulo de baixo, sem olhar se a peça existe e se estica. A peça só estica quando o módulo de baixo não tem base e está suspenso (`partsOf`, 'Tamponamento de baixo', `sus_`).
- **Correção:** `tbEstica(o)` (de baixo, marcado, sem base, sem canto, suspenso) decide se `tbL`/`tbR` contam. No suspenso nada muda (peça 1000 = 900 + 100, medida +100). Aéreo continua igual (já não contava).
- **Projetos antigos:** a medida só diminui onde não havia peça. Nenhum módulo é empurrado, porque a restrição de espaço só fica mais folgada.
- **Teste:** `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo` (875 cenários do catálogo; mais de 200 deles com 🗑). Falha antes com 3 grupos de cenários e passa depois.
- **Status:** resolvido na bateria. **Não testado em aparelho real.**

## TB-BASE: tamponamento inferior marcado em módulo de baixo COM base não gera peça nenhuma (achado em 16/11)
- 83 módulos do catálogo (balcões, gaveteiros, torres, guarda-roupas). A caixinha diz "Usar (fica abaixo da base)", mas a lista não tem a peça.
- Mesmo assim, os tamponamentos laterais descem mais 30 mm (`tEnd`), e até o TB-MED a medida contava o "aumentar comprimento".
- **Decisão (16/11 10:56):** onde existe peça real, ela entra no modelo, no 3D, na lista e no corte; onde não se aplica, a opção fica desligada sem prejudicar projeto antigo.
- **Correção:**
  - `tbAplica`, `tbBaseSusp` e `tbPeca` decidem.
  - Módulo com base, **suspenso e sem rodapé**: gera a peça, que fecha por baixo da base e das laterais (mesma conta do módulo sem base suspenso).
  - **No chão com base** e **canto em L**: a caixinha fica desligada, com o motivo escrito.
  - Projeto antigo que já estava marcado continua marcado (dá pra desmarcar), mas não gera peça.
  - O tamponamento lateral não desce mais 30 mm por causa de peça que não existe (`tEnd`), e a profundidade externa não soma 25 (`dimExt`).
- **Teste:** `testTamponamentoDeBaixoSoOndeViraPecaComBaseSuspensoTemPecaNoChaoNaoSeAplica`.
  - Antes: no chão, a lateral passava de 720 para 750 sem a peça; suspenso, "sem peça".
  - Depois: no chão a lateral fica igual; suspenso, a peça vai na lista, no corte e no 3D, e o "aumentar comprimento" estica a peça e a medida juntos.
- **Varredura:** 196 cenários.
  - No chão: 76 módulos com base ficam sem peça e sem efeito.
  - Suspensos: todos com peça.
  - `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo` continua sem diferença.
- **Status:** resolvido na bateria.

## XP-PK: mexer num vão faz a peça apagada de outro vão voltar, e o ajuste do 3D pular de porta (achado em 16/11)
- **Reproduzir:** guarda-roupa 2 vãos. Apagar (🗑) a porta esquerda do vão 2 e trocar o vão 1 de 2 portas pra 1. A porta apagada volta e a direita do vão 2 some.
  - Varredura: 33 de 183 casos de balcões, aéreos, torres e guarda-roupas.
  - Mesmo jeito com o ajuste do 3D (`m.po`): a porta do vão 2 encurtada 100 mm em cima passa o ajuste para a outra porta.
- **Causa raiz:** a peça é identificada por `pk` = nome + número de ordem no módulo inteiro (`Porta#3`). A lista de tiradas (`m.xp`), os ajustes do 3D (`m.po`) e outros mapas usam essa chave. Quando um vão ganha ou perde peça, a numeração dos outros muda. O editor por vãos (`isRg`) já segue as peças (`rgPoFollow`), o módulo comum não.
- **Correção (autorizada às 10:56):** `clPoFollow` faz no módulo comum o mesmo que o `rgPoFollow` faz no editor por vãos.
  - Cada peça é reconhecida pelo objeto do vão dela (continua o mesmo quando outro vão muda ou ganha divisória) e pela ordem dentro do vão.
  - Quando a numeração muda, andam junto com a peça: a lista de tiradas (`m.xp`, inclusive o `vi`), os ajustes (`po`), as cores (`pc`) e as fitas (`pf`).
  - Peça que sai guarda o que era dela na sessão e, se voltar, volta com ela.
  - O formato do arquivo não mudou.
- **Projetos:** abrir, desenhar e abrir o 3D não muda nada nos dados. A 1ª vez só guarda as chaves; o teste confere `xp` e `po` iguais.
- **Testes:**
  - `testPecaApagadaEAjusteDo3DSeguemAPecaQuandoOutroVaoMuda`. Antes, a porta apagada voltava e a encurtada perdia o ajuste; depois, ficam certas mesmo depois de dividir o vão e de salvar e reabrir.
  - Varredura de 183 casos: antes 33 com erro, agora 0.
- **Status:** resolvido na bateria.

## XP-ESTRUTURAL: o 🗑 tira lateral, base ou divisória e as outras peças continuam descontando ela (risco, 16/11)
- O 🗑 aceita lateral, base, base superior, divisória, rodapé e travessa. A peça sai, mas as vizinhas não mudam (a base continua `largura − 2 × 15` sem a lateral).
- A regra "lateral não se desliga em módulo pronto" (Laterais do módulo) contradiz isso.
- **Decisão (16/11 10:56):** recalcular quando a remoção vale construtivamente; senão bloquear e explicar; oferecer "sem lateral" quando dá.
- **Correção:** `pcEstrutural`, chamado pelo `pcDelAt` (2D e 3D).
  - **Lateral com módulo encostado** (mesma altura de começo, cobrindo a altura e a profundidade): vira "sem lateral" (`semLE`/`semLD`). O módulo usa a lateral do vizinho, e base, teto, travessas e prateleiras vão até a ponta. Ex.: prateleira 570 → 585.
  - **Lateral sem vizinho**, vizinho também sem lateral ou vizinho que não cobre: não sai, e a mensagem diz o porquê.
  - **Lateral do canto em L:** não sai.
  - **Base de baixo:** módulo sem base, igual a desmarcar "Base inferior". No canto saem os 2 lados.
  - **Base de cima:** não sai e explica. Em balcão, sugere travessas.
  - **Divisória:** os 2 vãos viram 1; no editor por vãos, pelo `rgDelDiv`.
- **Teste:** `testLateralBaseEDivisoriaSaemPelaRegraDoMovelOuNaoSaemComMotivo`. Antes, tudo saía "só a peça"; depois, sai pela regra ou não sai com motivo, sem fantasma no 3D nem no corte, e continua certo depois de salvar e reabrir.
- **Status:** resolvido na bateria.

## RGQK-LARGA: "2 toques no vão" do editor por vãos não abria o menu rápido em tela larga (CI do Windows, 16/11)
- **Achado:** a bateria do Windows falhava em `testEditorPorVaosDoisToquesNoVaoAbreMenuRapidoComAsAbasEBotoesDoPainel` desde d9b9240. As execuções anteriores tinham sido canceladas.
- O script da bateria caía ao imprimir "▦" no console cp1252 e escondia o motivo da falha.
- **Reproduzido** no Chromium com tela 1366 × 768 e cliques de mouse de verdade: o 1º clique deixa o vão rosa e o 2º não abre o menu.
  - No celular (440 de largura) abre.
  - Afeta Windows e, provavelmente, tablet deitado. **No iPad, não verificado.**
- **Causa raiz:** em tela larga, o 1º toque escolhe o vão e o desenho é refeito antes de o detector de 2 toques rodar. O alvo do toque já saiu da página, `closest('#svg …')` dá nulo e o toque não é contado.
- **Correção:**
  - `editor.html`, detector do PEDIDO 62: com o alvo fora da página, acha o vão pelo ponto do toque (`elementsFromPoint`), como já fazia quando o alvo era outra coisa do desenho.
  - `tools/bateria_editor.py`: imprime em UTF-8.
- **Teste:** o mesmo teste do PEDIDO 62.
  - Antes, com tela larga: "não abriu".
  - Depois: abre com as 7 abas na tela larga e no celular.
- **Status:** resolvido no Chromium. **Falta confirmar no CI do Windows** (próximo push).

## FUNDO-LIXO: o fundo mostrava "🗑 Só esta peça" no 3D e não saía (print de 16/11 às 10:07 · pedido "peças que não podem ser removidas")
- **Reproduzir:**
  - No 3D, 1 toque no fundo e "🗑 Só esta peça". Resposta: "Essa peça não sai sozinha (ela faz parte de um conjunto)". O fundo continuava no 2D, no 3D e no corte.
  - Igual em todo módulo com fundo, inclusive no editor por vãos e no "Fundo (lado do canto)".
- **Causa raiz:**
  - O fundo não é peça do `partsOf`. Ele sai da regra "Fundo" do módulo (`m.fundo`, `fundoDims`).
  - O quadro do 3D monta uma peça de mentira pro fundo (`e3Part`, que oferece o 🗑).
  - O 🗑 (`pcDelAt`) procura a peça no `partsOf`, não acha e recusa.
- **Correção:** o 🗑 no fundo faz o mesmo que desmarcar "Fundo" na aba Fundos (`m.fundo=false`, `fundoMan`). Sai do 2D, 3D, lista e corte, e ↶ desfaz.
  - No canto em L o fundo é uma regra só, então saem os 2 lados. O botão diz "🗑 Tirar o fundo (os 2 lados)".
  - A mensagem de recusa que sobrou explica o motivo e manda pra aba do módulo.
- **Teste:** `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` (fundo, corte, salvar e reabrir).
- **Status:** resolvido na bateria. **Não testado em aparelho.**

## GAV-FANTASMA: lateral ou contra-frente da caixa da gaveta apagada continuava no 3D com a chave da vizinha (achado em 16/11)
- **Reproduzir:** gaveteiro 3 gavetas, 🗑 na contra-frente da 1ª gaveta. Ela sai da lista e do corte, mas o 3D continua com 65 caixas e a chave `#3` aparece 2 vezes. Com a lateral é igual.
- **Causa raiz:** o 3D desenhava a caixa da gaveta inteira (2 laterais, contra-frente e traseira) a partir da 1ª peça que aparecia, e a chave da traseira era "a próxima" (`#n+1`). Sem uma das peças, a vizinha virava a de referência.
- **Correção:**
  - As peças da caixa da gaveta ganharam marca de lado e de gaveta (`cgS`, `cgVi`, `cgDq`, `cgD`, `cgH`; não vão pro arquivo do projeto, são calculadas).
  - O 3D desenha cada lado só se a peça dele está na lista, com a chave dela. Vale pro módulo comum e pro editor por vãos, com corrediça normal e oculta.
- **Teste:** o mesmo. Antes: 65 → 65 caixas, `#3×2`. Depois: 65 → 64, chaves únicas.
- **Status:** resolvido na bateria.

## CANTO-FANTASMA: peça do lado do canto em L apagada continuava no 3D (achado em 16/11)
- **Afeta:** base inferior, base superior, lateral do fim do lado e prateleira do lado.
- **Causa raiz:** o 3D do canto desenha as peças do lado por conta própria e acha a chave pelo nome (`pkFix3`). Com a peça tirada, o nome não estava na lista e a caixa ganhava a chave da peça do fundo.
- **Correção:** `pkFix3` acha a chave certa também para as peças tiradas, e nenhuma caixa cuja peça está na lista de tiradas (`m.xp`) é desenhada, em nenhum módulo.
- **Teste:** o mesmo (22 → 20 caixas, a base do fundo continua com 2).
- **Status:** resolvido na bateria.

## E3-EIXO-ALA: no módulo da parede lateral, o quadro da peça no 3D mostrava as medidas trocadas (print de 16/11 às 10:07)
- **Reproduzir:** balcão na parede esquerda, 1 toque no fundo. Mostrava "6 × 820 × 600"; o certo é "600 × 820 × 6". A lateral mostrava 560 × 690 × 15.
  - Digitar em "Larg." mexia na largura usando a profundidade como base.
  - O print do fundo "161 × 999 × 965" é esse caso: Larg. e Prof. trocadas.
- **Causa raiz:** `e3DimsOf` e o texto do quadro usavam as medidas do mundo. O módulo da parede lateral é girado: a largura dele é o eixo z do mundo.
- **Correção:** `e3Loc` devolve Larg., Alt. e Prof. da peça, com o giro desfeito no módulo da parede lateral. Digitar a medida usa a mesma conta.
- **Teste:** `testQuadroDaPecaNoModuloDaParedeLateralMostraAsMedidasDaPeca`. Falha antes e passa depois.
- **Status:** resolvido na bateria.

## Auditoria do 🗑 (16/11): o que foi conferido
- **Como:** catálogo inteiro, no módulo comum (193 peças) e no editor por vãos (104 peças). Cada peça que o 3D deixa escolher passou pelo 🗑 do quadro do 3D.
- **O que foi conferido:**
  - sai da lista, sai do 3D, sem peça repetida, sem mexer nas outras;
  - no fundo, sai do corte e continua fora depois de salvar e reabrir.
- **Resultado depois das correções:**
  - **Nenhuma peça "não sai" e nenhuma fantasma.**
  - Prateleira interna: as 2 partes viram 1, como no pedido anterior.
- **Riscos que dependem de decisão** (o 🗑 tira a peça e só ela; as vizinhas não são recalculadas):
  - XP-ESTRUTURAL (lateral, base, divisória, rodapé);
  - XP-PK (mexer num vão pode trocar qual peça fica apagada);
  - "Corte do forno" e "Nicho do micro-ondas (aberto)", que somem do desenho mas o aparelho continua.

## SAIA-ALTURA: com saia na pedra, o armário ia até embaixo da pedra e a saia ficava na frente da porta (pedido de 16/11 às 10:34, resposta "A" às 10:39)
- **Antes:** bancada com o embaixo da pedra a 820, pedra de 30 e saia de 100. A saia fica de 750 a 850, mas o módulo ia até 820 e a porta até 815, atrás da saia, que bate nela ao abrir.
- **Regra confirmada:** opção A às 10:39 e regra definitiva às 10:56.
  - O armário inteiro (caixa e frentes) fica embaixo da saia, com 15 mm de folga (`STFOLGA_SAIA`, aplicada uma vez só), e a pedra fica por cima.
  - No exemplo, a saia vai até 750, o armário até 735, a porta até 730 e a gaveta até 725 (folgas normais).
  - Sem saia: até 820, sem a folga.
  - Mudar a altura da saia, a espessura da pedra, tirar ou pôr a saia: o armário encaixado acompanha (`stAdapta`, limite guardado por pedra). Mudar a altura da pedra continua como era.
- **Código:**
  - `stArmTop(st)` calcula o embaixo da saia, com a mesma conta do desenho da saia (`stSaiaGeo`).
  - `stAdapta` passa a usar esse limite, inclusive no canto em L de baixo, só quando há saia nova.
  - `underStone` aceita o módulo que vai até a saia, então a moldura não aparece.
  - Esticar no 3D respeita o mesmo limite.
- **Projetos antigos:**
  - Pedra com saia de projeto antigo não muda sozinha. A regra vale quando a saia é ligada ou tem a altura escolhida (`st.saiaArm`).
  - Em projeto antigo, basta tocar de novo no tamanho da saia na aba Pedra.
- **Teste:** `testComSaiaNaPedraOArmarioInteiroVaiAteEmbaixoDaSaia`. Falha antes e passa depois. Cobre:
  - portas e gavetas;
  - folga medida no 3D (15);
  - lateral na lista e no corte;
  - saia de 7 cm e pedra de 40;
  - tirar e pôr a saia;
  - salvar e reabrir;
  - sem saia;
  - projeto antigo;
  - canto em L.
- **Status:** resolvido na bateria. **Não testado em aparelho real.**
- **Pendente:** a frente do armário continua parando atrás da saia na profundidade (PEDIDO 59). Com o armário inteiro embaixo da saia, a porta poderia vir mais pra frente, mas isso não foi pedido e não mudou.

## GAV-MARCA-GDQ: a marca nova da caixa da gaveta usava o nome `gdq`, que já era do gola lateral (achado na bateria de b3c1e74, 16/11)
- **Sintoma:** a contra-frente da 1ª gaveta ia pra altura da porta (y 5, h 705) e entrava na travessa e no batente. Acusado por `testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D` (pecaDentroDeOutra).
- **Causa:** `stkParts` trata peça com `gdq` como perfil gola lateral: copia a altura da porta e, no maleiro embaixo de porta inteira, tira a peça.
- **Correção:** as marcas viraram `cgS`, `cgVi`, `cgDq`, `cgD` e `cgH`, nomes que não existiam no editor.
- **Status:** corrigido e conferido no teste que acusou. Só ficou no commit b3c1e74 (não publicado).

## BAT-FLAKY (16/11, continuação): testes que falham só com o computador carregado
- **Causa comum:** o teste espera um tempo fixo (150 a 900 ms) depois de um clique que abre 3D, "só ele no 2D" ou o projeto do cliente. Com 3 navegadores ao mesmo tempo em 2 processadores, o tempo não basta.
- **Correção (só nos testes):** esperar o estado chegar (até 5 s) em vez do relógio. As expectativas não mudaram.
  - `testSoOModulo3DE2DComPortaGavetaEDivisoriaSoNele`: solo e backSolo.
  - `testOrganizacao3DClienteEModoPessoa`: clv e ro.
  - `testAereoFechamentoAteOTetoEmCimaDaBaseEmbutirMuduloDeCimaListaETirarMolduraAntiga`: a caixa do fechamento.
- **Continua intermitente:** `testRodapeIgualPintarPorDentroEletroSemAzulEPortaAmortecida` (amort). Ele mede o tempo da animação da porta com amostras a cada 40 ms; com carga, as amostras ficam espaçadas. Corrigir sem afrouxar exige medir a curva do amortecedor pela própria animação. Fica pendente; passa rodando sozinho.

## XP-PK-SOLO: entrar e sair do "2D só dele" apagava a cor, o ajuste do 3D e a peça tirada das portas (bateria do Windows em 93495d1, 16/11)
- **Achado:** `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho` falhou na bateria do Windows de 93495d1: "2D só dele no módulo 9 → mód 9 [pc]". Nunca foi publicado (93495d1 é só de desenvolvimento).
- **Reproduzir:** Armário alto 2 portas com cor por peça. Tocar em ✏️ Só ele no 2D e depois em ↩ Projeto todo. As cores das 2 portas somem (15 → 13 chaves). O mesmo vale para o ajuste do 3D (`po`) e para a porta tirada pelo 🗑 (`xp`), que voltava.
- **Módulos afetados (varredura do catálogo, 142 modelos):** 34. São os que passam pelo editor por vãos ao entrar no "só ele":
  - armários altos e despenseiro;
  - torres (cozinha, guarda-roupa, prateleiras, banheiro, sapateira);
  - guarda-roupas de 2, 3 e 4 vãos e closets;
  - armário sem lateral.
  - Balcões, aéreos e gabinetes não mudavam.
- **Causa raiz:** o XP-PK (93495d1) reconhece cada peça pelo objeto do vão. Entrar no "só ele" passa o módulo alto pelo editor por vãos (`soloOn` → `rgConvert` → `rgInit`), que troca `m.v` por cópias iguais. O vão era o mesmo, mas o objeto era outro. `clPoFollow` entendia que as peças tinham saído: guardava a cor, o ajuste e a tirada como "peça que saiu" e tirava do projeto.
- **Correção:** `clPoFollow` guarda também o objeto de cada vão por posição. Objeto novo na mesma posição do vão que sumiu é tratado como o mesmo vão: as peças continuam as mesmas e nada é movido nem guardado. Divisão, troca de porta por gaveta e mudança de vão continuam como antes.
- **Testes:**
  - `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho` (existente): falhava em 93495d1 e passa.
  - `testEntrarESairDoSoEleNoCatalogoNaoMudaCorAjusteNemPecaTirada` (novo): catálogo inteiro com cor em todas as peças, ajuste numa porta e uma peça tirada. Resultado: 93495d1 → 34 mudam sozinhos; b3c1e74 → 0; agora → 0.
  - `testPecaApagadaEAjusteDo3DSeguemAPecaQuandoOutroVaoMuda` continua passando.
- **Status:** resolvido na bateria.

## TB-ROTULO: o texto do tamponamento de baixo mudou sem pedido (bateria do Windows em 93495d1, 16/11)
- **Achado:** `testTamponamentoInferiorReconheceACavaSozinhoSemSecaoPosCava` mostrava "Usar (fica abaixo da base, módulo suspenso)". O esperado é "Usar (fica abaixo da base)".
- **Causa:** no TB-BASE eu acrescentei ", módulo suspenso" ao texto da caixinha. Isso não foi pedido.
- **Correção:** o texto voltou ao que era. A caixinha continua travada com a nota quando a peça não se aplica.
- **Status:** resolvido na bateria.

## TB-INV-NUM: conferência do tamponamento invertido com 9 modelos a mais no lado de baixo (bateria do Windows em 93495d1, 16/11)
- **Achado:** `testTamponamentoInvertidoNaoMudaTamanhoDeNadaEmTodoOCatalogo` dava 36 conferidos no lado de baixo. O esperado era 27.
- **Causa:** o TB-BASE (pedido das 10:56, item 3) fez a peça existir de verdade nos módulos com base suspenso. Por isso eles entraram na conferência:
  - Gabinete 2 portas, Gabinete com gavetas, Gabinete suspenso 2 gavetas e Gabinete 1 porta + gavetas;
  - Rack do zero, Rack suspenso (2 modelos) e Rack suspenso basculante;
  - Aparador suspenso 2 gavetas.
  - Inverter não muda o tamanho de nada em nenhum deles ("problemas" continua 0).
- **Correção:** a expectativa do número foi atualizada, com comentário citando o pedido e a data. As outras expectativas do teste não mudaram.
- **Status:** resolvido na bateria.

## TORRE-GEL-PORTA: trocar a porta de cima da caixa da geladeira fazia uma porta do teto ao chão, tampando a geladeira (vídeo de 16/11 às 13:34)
- **Relatado:** "troquei as portas de cima do armário acima da geladeira, e a porta alterou foi do móvel todo, até tampando a geladeira". Também com a porta fechada.
- **Reproduzir:** Caixa da geladeira side by side. Na aba Portas, tocar no "1 porta" da seção geral (embaixo dos puxadores), ou 2 toques no vão e "1 porta" em "Frente do vão inteiro".
  - Antes: porta 944 × 2515 (mais alta que o tamponamento de 2500), sem nicho e sem a prateleira de cima da geladeira, no 2D, no 3D e no corte.
  - Certo: porta 944 × 652 só em cima da geladeira.
- **Causa raiz:** no modelo de dados, não no desenho.
  - A caixa da geladeira é 1 vão com `k:'gel'`. O aéreo de cima, a prateleira e o nicho saem de `partsOf` a partir desse tipo e da altura da geladeira (`gh`).
  - Os botões gerais de porta (aba Portas, `data-door` e `data-slide`; menu do vão, `vk=door1`, `door2` e `slide`) trocam o tipo do vão inteiro para `door` ou `slide`. A porta passa a ser do vão inteiro, do teto ao chão.
  - A aba mostrava os dois blocos de "1 porta / 2 portas": o da geladeira (certo) e o geral, com uma nota de que "trocam a caixa toda".
- **Correção** (`editor.html`):
  - Na caixa da geladeira, a seção geral de portas não aparece. O menu do vão não mostra 1 porta, 2 portas nem correr na "frente do vão inteiro". As portas são as do quadro "Portas do aéreo": 1, 2 ou sem porta.
  - Se ainda chegar um clique de porta geral: 1 e 2 mexem só nas portas de cima; 3, 4 e correr são recusados com aviso.
  - Gavetas, prateleiras, forno, livre e divisórias continuam trocando a caixa toda pelo menu do vão, com o aviso que já existia.
  - Projeto em que a caixa já virou porta inteira não muda ao abrir. A aba Portas mostra o aviso com "↺ Voltar a caixa da geladeira (porta só em cima)".
- **Família investigada:** o mesmo mecanismo existe nas torres de forno e micro-ondas (9 modelos), no balcão de forno embutido e no porta-tempero. Nesses, "1 porta" da seção geral troca a torre toda; nas torres há a nota "trocam a torre toda". **Não mexido** (risco identificado, depende de decisão).
- **Testes:**
  - `testTorreDaGeladeiraTrocarAPortaMexeSoNaPortaDeCimaETamponamentoSegueATorre`. Cobre a porta de cima, os tamponamentos até o chão, a aba Portas, o menu do vão, a altura da geladeira, a altura da torre, o 🗑 e o ↺, o 2D, o 3D, o corte e salvar e reabrir. Falha em 9f3dc3e (porta 2515) e passa agora.
  - `testTorreDaGeladeiraQueJaVirouPortaInteiraAvisaENaoMudaSozinho`. Falha em 9f3dc3e.
  - Conferidos também: `testCaixaDaGeladeiraPrateleiraSoNoNichoDeCimaEmTodosOsCaminhos`, `testTorreDoFornoTrocaAPortaDeCadaVaoEGeladeira`, os 3 testes de pedra com geladeira e `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho`.
- **Status:** resolvido na bateria. **Não testado no aparelho.**

## TAMP-2D-ALVO: mexer na altura do tamponamento externo pelo 2D jogava o móvel pra cima e apagava a base (vídeo de 16/11 às 13:48)
- **Relatado:** "vou mexer na altura do tamponamento externo, pelo 2D, e ele joga o móvel pra fora e elimina a base". O Adauto disse que já tinha comentado antes; nas conversas antigas que consegui pesquisar não achei esse mesmo relato. Achei as regras combinadas do ajuste do tamponamento por toque (alinhado com a cava ou com o tamponamento, +2 mm).
- **Reproduzir:** 2 balcões e um gaveteiro embaixo da pedra, tamponamento direito ligado, outro módulo escolhido. Encostar o dedo no tamponamento e arrastar pra cima.
  - Antes: o módulo subiu (b 0 → 1410) e saiu de baixo da pedra. Rodapé (4 → 0), travessa e moldura foram apagados.
  - Ao descer de volta pro chão, rodapé e moldura não voltavam. A porta ficou 100 mm mais alta (805) e o plano de corte perdeu o rodapé desse módulo.
- **Causas (3), todas em `editor.html`:**
  1. **Toque sem alvo único** (`pointerdown` do `#svg`). O arrasto da altura do tamponamento (`drag 'tp'`) só valia com o módulo já escolhido e o dedo exatamente na chapa. Com o módulo não escolhido, ou na régua do engrosso, o toque caía no "mover o módulo inteiro" (`drag 'm'`), inclusive na vertical.
  2. **Erguer apagava dado.** No cálculo das peças (normalização perto de `tbW`/`fundoMm`), o módulo de baixo com `b>0` tinha `rod`, `trav` e `mold` gravados como `false`. Era sem volta: um arrasto acidental destruía a configuração.
  3. **O tamponamento passava do chão.** O arrasto aceitava até 600 mm pra baixo, sem limite no piso.
- **Correção:**
  1. Toque no tamponamento (chapa, face ou régua do engrosso):
     - módulo não escolhido: só escolhe, com aviso;
     - módulo escolhido: muda só a altura do tamponamento.
     - O móvel não se mexe.
  2. Erguer o módulo guarda o que ele tinha no chão (`m._noChao`). Voltar pro chão devolve rodapé, travessa e moldura. Projeto antigo já erguido não muda ao abrir, porque não tem o que devolver.
  3. No módulo de baixo, o tamponamento desce no máximo até o chão.
- **Comportamento que continua (decisão pendente):** arrastar o corpo do módulo pra cima ainda ergue o módulo (é assim que se faz um módulo suspenso). A trava de posição pros módulos de baixo que estão embaixo da pedra é a fase 2 da proposta e depende de aprovação.
- **Teste:** `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase`. É a sequência real, com toques de verdade no 2D:
  - toque com o módulo não escolhido;
  - esticar até o chão e encurtar;
  - erguer e descer o módulo;
  - 3D com a base e o rodapé contínuos embaixo;
  - porta;
  - plano de corte;
  - salvar e reabrir.
  - Falha em 9f3dc3e (b1410, rodapé 0) e passa agora.
- **Status:** resolvido na bateria. **Não testado no aparelho.**

## AMB-RD: a profundidade do ambiente ficava presa no maior comprimento já digitado na parede do lado (auditoria de 16/11, 14:29)
- **Achado na auditoria** (não relatado assim). Ponto de partida: as medidas da imagem de 14:29 (parede direita 3170, altura 3400 no fundo e na frente, rebaixos 3170 e 1000). A imagem não veio anexada; usei as medidas escritas no pedido.
- **Reproduzir:** editor do ambiente no 3D, parede da direita, digitar 31700 no comprimento e corrigir pra 3170. Cada número digitado conta (o campo grava a cada tecla).
  - Antes: a sala ficava com 31700 de profundidade, mesmo depois de corrigir. Encurtando a parede pra 2000 também continuava 31700.
- **Causa:** `setV` (`editor.html`), ramo do comprimento da parede do lado: `if(n>(+S.RD||0))S.RD=n`. Só aumentava, nunca voltava.
- **Correção:** a profundidade passa a ser a maior entre a que você tinha e as duas paredes do lado.
  - A sua fica guardada enquanto a parede passa dela (`S.RDw`), e volta quando a parede encurta.
  - Mexer no campo "Profundidade" apaga essa lembrança: vale o que você digitou.
- **Limite conhecido:** `S.RDw` não é gravado no arquivo. Depois de reabrir, a profundidade fica a que estava (não muda nada sozinho). Pra diminuir, é pelo campo Profundidade.
- **Teste:** `testAmbienteParedeDoLadoProfundidadeNaoFicaPresaERebaixoNaoPassaDaParede`. Falha em 9f3dc3e (31700) e passa agora (3170; parede 2000 → 2600).

## AMB-TZ: rebaixo do teto passava do fim da parede no 3D (auditoria de 16/11, 14:29)
- **Achado na auditoria.** Parede da direita 3170 com rebaixo 1 (0 + 3170) e rebaixo 2 (2400 + 1000).
  - Antes: o rebaixo 2 ia até 3400 no 3D, 230 mm pra fora da parede. Encurtando a parede pra 2500, os dois continuavam até 3170 e 3400.
- **Causa:** `zs()` e `tzGeo()` (`editor.html`, rebaixo do teto) desenhavam `x + w` sem olhar o comprimento da parede.
- **Correção:** na hora de desenhar e medir, o rebaixo é cortado no fim da parede (`tzClamp`).
  - A medida guardada não muda. Se a parede volta a crescer, o rebaixo volta.
  - Rebaixo que fica todo fora da parede não é desenhado, mas também não é apagado.
- **Teste:** o mesmo de AMB-RD. Falha em 9f3dc3e (fim 3400) e passa agora (3170; parede 2500 → 2500; guardado 0+3170 e 2400+1000).
- **Família conferida:** 81 testes da bateria que mexem em paredes, profundidade, rebaixo, painel na parede e vista da parede.

## Auditoria de integridade (16/11, tarde): achados ainda sem correção
Detalhes, reprodução e sondas em `AUDITORIA_INTEGRIDADE.md` e `tools/sondas/`. **Nada corrigido ainda: depende de aprovação.**
- **DRAW-CATRACA (P1-A):** o desenho (`confineAll`, `roomClamp`, `placeFree`, `stFitApply`, `sanM`, `sanBase`) grava posição e medida quando a entrada muda, e o dado não volta quando a entrada volta.
  - Exemplos: torre 2400 → 2300 depois de mexer no pé-direito; forno 600 → 606 depois de mudar a espessura.
- **TAMP-CAMINHO (P1-B):** pelo campo digitado, a mesma posição dá resultados diferentes conforme o valor anterior, e fica vão de até 35 mm sem tamponamento junto à parede. Pelo arrasto real: determinístico.
- **ABRIR-REGRAVA / ENGROSSO-APARELHO (P1-C):** abrir o projeto regrava o arquivo e muda `updated`. Com `egOn=0` no aparelho (padrão), o `egL/egR` do projeto é zerado e gravado.
- **3D-045 (P1-D, provável causa):** `ST3ONLY` ("👁 Só a pedra no 3D") fica ligado entre projetos até recarregar o editor.
- **DIV-OUTRO-MODULO (P1-E):** arrastar a divisória de um módulo não escolhido muda a do módulo escolhido.
- **ARQ-VAZIO (P1-F):** `projects.json` vazio grava `[]` por cima do `localStorage` (linha 3085).
- **BKP-RESTAURA (P0):** Android e Windows apagam os dados antes de extrair o backup. Falha no meio = estado misturado (notas somem). Backup só com a marca apaga tudo. No iOS, `projects.json` vazio passa na validação.
- **SEL-ENTRE-PROJETOS (P1-G):** a escolha de divisória em A faz o 🗑 apagar a divisória do B.
- **CATALOGO-SOBREPOE (I7):** módulo novo do catálogo em parede cheia entra por cima dos vizinhos.
- **TAMP-2D-ALVO-PARCIAL:** o teste do 38ed268 falha em 1366×768. Erguer até uma altura que atravessa a pedra faz o módulo pular 875 mm de lado ao soltar (`confineAll`→`stPush`).
- **VAO-3D-ABERTO:** trocar o vão por gavetas com o 3D aberto não atualiza o 3D.


## P0-01 / ARQ-VAZIO: projects.json vazio ou quebrado apagava a cópia boa do navegador (corrigido em 16/11, commit 73ec2f3)
- **Como reproduzir:** navegador com projetos, `projects.json` = `[]`. Ao abrir, a lista fica vazia e o navegador é sobrescrito com `[]` (sonda s08a: 1 → 0).
- **Causa raiz:** na abertura o arquivo vencia sempre que era uma lista, mesmo vazia (`PJS`). Depois, a linha 3085 copiava o arquivo para o `localStorage` quando a lista estava vazia.
- **Correção** (`editor.html`, `pjsEscolhe`/`pjsDecide`/`pjsCopia`):
  - arquivo com projetos vale como antes;
  - arquivo vazio, ilegível, que não é lista ou ausente, com o navegador cheio: vale o navegador, e a próxima gravação devolve a lista ao arquivo;
  - os dois vazios: vazio de verdade;
  - a cópia do arquivo ilegível não sobrescreve a anterior.
- **Testes:** `testArquivoDeProjetosVazioOuQuebradoNaoApagaACopiaBoaDoNavegador`. Falha antes, passa depois. Sonda s08a agora dá 1 → 1.
- **Outros módulos:** `prices.json` e `apmodels.json` só são copiados quando o `localStorage` não tem nada. Não sobrescrevem dado bom.

## P0-03 / ENGROSSO-APARELHO: engrosso do projeto zerado pelo ajuste do aparelho (corrigido em 16/11, commit 37c9915)
- **Como reproduzir:** projeto com `egL=1`, ajuste "Engrosso" desligado no aparelho (é o padrão). Desenhar, abrir ou reabrir grava `egL=0`, e religar não devolve.
- **Causa raiz:** `defs()` (274) e `partsOf()` (509) faziam `m.egL=0;m.egR=0` com `!ENGON()`. O ajuste é do aparelho, não do projeto.
- **Correção:** o dado fica. `egEf(m,lado)` dá 0 com o ajuste desligado e é usado em `vaoRanges`, nas peças de engrosso e na conversão para o editor por vãos.
- **Regra de fabricação não mudou:** com o ajuste desligado não sai peça de engrosso e os vãos têm a medida de sem engrosso.
- **Testes:** `testEngrossoDoProjetoNaoSomeComOAjusteDesligadoNoAparelho`. Falha antes (egL 1 → 0 gravado), passa depois. Sonda s08b: arquivo 30 → 30.

## P0-03 (continuação) / ABRIR-REGRAVA: abrir sem mexer regravava e mudava a data (corrigido em 16/11, commit 0e353e3)
- **Causa raiz:** o `draw()` da abertura chama `schedSave()`, e o `SVSIG` era nulo ou de outro projeto.
- **Correção:** quando o que é aberto é igual ao guardado do projeto atual, `SVSIG` passa a ser o do projeto aberto. Desfazer, refazer e mexidas gravam como antes.
- **Teste:** `testAbrirProjetoSemMexerNaoRegravaNemMudaAData`. Falha antes (1–2 gravações e `updated` mudado), passa depois.

## P0-02 / BKP-RESTAURA: restauração de backup destrutiva no Android e no Windows (corrigido em 16/11, commit f96b3e5)
- **Como reproduzir** (código real, `tools/sondas/backup`):
  - falha de escrita no meio da extração: projetos trocados e notas apagadas;
  - backup só com a marca: tudo apagado.
- **Causa raiz:** `applyPending` apagava as pastas antes de extrair, sem cópia, e engolia o erro. O `stage` só conferia a marca.
- **Correção:**
  - `check()` confere o ZIP inteiro (índice, CRC, caminhos, lista de projetos, não vazio);
  - extração em `restore_staging`;
  - `swapIn()` guarda o estado atual em `restore_previous_<hora>`, que não é apagado e não entra no backup, com volta em qualquer falha;
  - recuperação se o app fechar no meio da troca;
  - recusa avisada, sem cair na restauração antiga;
  - resultado avisado ao reabrir.
- **iOS:** já tinha área de preparo e volta. Agora recusa backup sem nenhuma nota e sem nenhum projeto, e guarda o anterior em `files.restore-previous-<hora>`.
- **Testes:**
  - 13 casos JVM passando;
  - 2 testes novos em `BackupSafetyTests`, **não executados aqui** (sem Xcode);
  - compilação completa do Android e do Windows **não feita aqui**: o servidor dl.google.com está bloqueado na rede deste ambiente.

## GEO-AVISA: o ambiente modificava os móveis (regra aprovada em 16/11; corrigido em 16/11, commit desta entrada)
- **Como reproduzir:** P1-A da auditoria (s11, s13).
  - pé-direito −400 e volta: torre 2400 → 2300 e aéreos subidos;
  - parede −300 e volta: torre da parede lateral +30;
  - espessura +3 e volta: forno 600 → 606;
  - alargar e voltar: vizinho e pedra empurrados.
- **Causa raiz:** as passadas de restrição (`confineAll`: `confine`, `stPush`, `placeFree`; `roomClamp`), o `wallFollow` (aéreo no teto) e o `sanM` (largura mínima do forno) gravavam medida e posição a cada desenho, e só num sentido.
- **Correção:** guarda de fabricação no fim do `editor.html`.
  - **Medidas:** largura, altura e profundidade nunca mudam por essas passadas.
  - **Posição:** x e b só mudam no módulo que a pessoa está mexendo, no eixo mexido, ou no módulo recém-criado, na própria criação.
  - **Pedra e móveis soltos:** não são cortados pela parede.
  - **`wallFollow`:** não move o aéreo.
  - **Forno:** não alarga.
  - **Conflito:** vira aviso pelo toast existente, com módulo, medida, disponível, diferença e "Nenhuma medida foi alterada". `fgConflitos()` lista os conflitos.
  - **Fica igual (regra aprovada):** o armário embaixo da pedra acompanha a saia e a espessura (`stAdapta`).
- **Mudança de comportamento:** alargar um módulo contra o vizinho não empurra mais o vizinho. A regra que já existia ("medida não aplicada, diminua ou mova o vizinho primeiro") passa a aparecer.
- **Teste:** `testAmbienteNaoModificaOsMoveisSoAvisa`. Falha antes, passa depois.
- **Não coberto ainda:**
  - painéis "até o teto" que acompanham o pé-direito (`wallFollow`, parte dos painéis): ver a pergunta no relatório;
  - `confine` chamado direto no arrasto do módulo (só o módulo arrastado);
  - `sanBase` (`trav=false`).


## Fase 2 · seleção inteligente (16/11, noite) — branch `claude/arquemestre-fase2-selecao` (de `9ec0869`)
### SEL-DIV: divisória ou prateleira de outro módulo mexia na do módulo escolhido (commit d77ff63)
- **Reproduzir:** dois balcões, A escolhido; arrastar a alça de divisória do B (A.div 0,5 → 0,876); com a aba Divisões, arrastar a prateleira do B (A.shv 0,5 → 0,907).
- **Causa raiz:** as alças (`data-d`/`data-s`) ficam fora do grupo do módulo e só têm o número da peça; o toque armava `drag {t:'d'|'s', i}` sem o módulo e o arrasto aplicava em `S.m` (linhas 1225/1226); a camada 12181 escolhia a alça mais perto do dedo e calculava o deslocamento com `circle[data-d=i]` entre TODOS os módulos (o 1º do DOM era o do outro módulo).
- **Correção:** cada alça leva o módulo dono (`data-dm`); tocar na de outro módulo escolhe o dono (`S.m`, `S.sv=0`) e o arrasto guarda o dono (`drag.mo`); o movimento só age no dono; a camada 12181 só olha as alças do módulo escolhido.
- **Testes:** `testSelecaoDivisoriaDeOutroModuloSoEscolheEleENaoMexeEmNinguem` (inclui o arrasto no próprio módulo) e `testSelecaoPrateleiraDeOutroModuloMexeSoNela`: falham em 9ec0869, passam agora. Família: 27 testes de divisória/prateleira passando.

### SEL-PROJ / SEL-ESTADO: escolha de tela do projeto A agindo no B (commits 7db71af e d612d17)
- **Reproduzir:** tocar numa divisória em A, abrir o B pela lista do editor, tocar no 🗑 → apagava a divisória do B. Ficavam do A: `LAST`, `DIVI`, `PSEL`, `S.selS`, `ST3ONLY`.
- **Causa raiz:** escolha de tela em variáveis globais e em `S`, e o `loadState` não limpava.
- **Correção:** `loadState` de OUTRO projeto (CUR mudou, fora do desfazer) zera `LAST`, `DIVI`, `PSEL`, `SEL3`, `FOC3`, `RPSEL`, `SELAP`, `ST3ONLY`, alvo armado do 🗑 e `S.selS` (null, como no resto do editor), e o vão escolhido; desfazer/refazer/recarga só descartam escolha que não existe mais. Dados do projeto não mudam.
- **Regressão achada e corrigida no caminho (d612d17):** com `S.selS=-1` o 2D tratava como prateleira escolhida e perdia o 1º toque (`testDoisToquesNoVaoDeCima…`). Agora `null`.
- **Testes:** `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto`, `testSelecaoEscolhasDeTelaZeramAoAbrirOutroProjeto`: falham em 9ec0869, passam agora. Sondas s21/s22 (abrindo como o app: `CUR=p.id; loadState`).

### SEL-VAO: vão escolhido inválido depois de escolher outro módulo pelo 3D (commit 7a95037)
- **Reproduzir:** A com 3 vãos e o 3º escolhido; tocar no B (1 vão) pelo 3D → `S.sv=2`. Ler o vão escolhido nesse estado criava vãos fantasma no B (sonda s42: 1 → 3 em 9ec0869).
- **Causa raiz:** o caminho do 3D troca `S.m` dentro do bloco do 3D sem conferir `S.sv`.
- **Correção:** acessor em `S.m` — trocou o módulo escolhido (qualquer caminho), `S.sv` é conferido contra divisórias + 1 do módulo novo. `S.sv` é estado de tela.
- **Risco que fica (para aprovação):** `gv(i)` com `i` fora de divisórias + 1 ainda cria vãos (s42, `gv(5)`: 1 → 6). O caminho comprovado que chegava lá está fechado; nenhum modelo do catálogo tem vãos além de divisórias + 1.
- **Teste:** `testSelecaoVaoEscolhidoExisteNoModuloEscolhidoDepoisDoToqueNo3D`: falha em 9ec0869, passa agora.

### SEL-TORRE: porta de cima virava a torre inteira (opção A aprovada pelo Adauto; commit desta entrada)
- **Reproduzir:** nos 9 modelos de torre de forno/micro-ondas, tocar na porta de cima e escolher 1 ou 2 portas (aba Portas ou 2 toques no vão "1 porta") → uma porta de 2100 mm, forno/micro/nichos somem (27 erros).
- **Causa raiz:** a torre é um vão `k:'oven'`; os comandos gerais de porta trocam o tipo do vão inteiro. Mesmo mecanismo já corrigido na geladeira (TORRE-GEL-PORTA).
- **Correção (opção A):** `torreForno(m,v)` = vão 'oven' em módulo de baixo com 1500 mm ou mais. Na torre, a seção geral de portas da aba Portas e "1 porta / 2 portas / correr" do menu do vão não aparecem; clique geral que ainda chegue é recusado com aviso ("Nada foi alterado"). A porta de cada vão se troca pelos botões que já existem ("Só este vão da torre"; torre antiga pelo "🚪 Trocar a porta", que é a conversão manual existente — nada é convertido sozinho). Balcão de forno (mais baixo) continua como era (frente com recorte).
- **Testes:** `testSelecaoPortaDeCimaDaTorreMudaSoAPortaDeCima` (9 torres × 3 caminhos; falha em 9ec0869, passa agora) e `testSelecaoTorrePortaDeCimaPeloVaoDaTorreMudaSoEla` (o caminho certo: só a porta de cima vira 2 folhas, forno/micro no lugar, medidas externas iguais, outras portas iguais, 3D e corte com as mesmas portas, desfazer/refazer e reabrir certos — passa nas duas versões, é garantia do caminho certo).
- **Correção de contagem:** o diagnóstico dizia 10 modelos; são 9.

## GV-P1: ler um vão que não existe gravava vãos fantasma (aprovado pelo Adauto em 17/11; branch `claude/arquemestre-fase2-selecao`)
- **Módulo:** todos os módulos com vãos (`m.v`), em todas as famílias.
- **Reproduzir:** `gv(99)` num balcão sem divisórias → `m.v` 1 → 100 (s42/s44). Também `gv(divisórias + 1)` em inferior, superior, torre, guarda-roupa, rack e estante (1 → 7, 2 → 8, 3 → 9). `gv(undefined)` devolvia `undefined` (erro em quem usasse).
- **Causa raiz:** `gv(i)` preenchia `m.v` até `i` sem conferir se o vão `i` existe (0 a divisórias). Investigação completa em `engenharia/GV_INVESTIGACAO.md`, proposta em `GV_PROPOSTA.md`.
- **Arquivos e funções:** `editor.html`, `gv` (linha 274), nova `gvPadrao` (o mesmo vão padrão de antes).
- **Correção:**
  - índice que não existe (negativo, quebrado, `NaN`, vazio, ou ≥ divisórias + 1) não grava nada e devolve um vão padrão solto (editar ele não muda o projeto e nenhum outro vão é usado no lugar);
  - fica anotado em `window.__gvInvalidos` (últimos 50) e no console;
  - índice que existe: igual a antes.
  - Sem migração: a sobra que já está gravada em projeto antigo fica como está.
- **Uso normal:** cozinha demo (todos os módulos, vãos e abas), os 142 modelos do catálogo (vãos × abas, peças, corte) e 3D → 0 chamadas inválidas, 0 erros.
- **Testes:**
  - falham em `9561fcd` e passam com a correção: `testGvVaoQueNaoExisteSemDivisoriasNaoGravaNada`, `testGvVaoQueNaoExisteComTresDivisoriasNaoGravaNadaEOsQueExistemSaoOsCertos` e `testGvVaoQueNaoExisteNaoGravaNadaEmTodaAFamiliaDeModulos`;
  - de garantia, passam nas duas versões: `testGvLimparDivisoesDesfazerRefazerEPorDeNovoNaoTrazVaoAntigo`, `testGvTrocarDeModuloPeloDoisDETresDNaoCriaVao`, `testGvProjetoAntigoComVaosSobrandoAbreSalvaEReabreSemMudarNada` e `testGvEditarVaoQueExisteSemConfiguracaoGravadaContinuaValendo`.
- **Não aparece para o usuário:** sem linha nova em `.github/novidades.txt`.

## GV-C: vão escolhido inválido depois de "Limpar divisões" (aprovado pelo Adauto em 17/11; commit separado da P1)
- **Reproduzir:** 3 vãos, o 3º escolhido, aba Divisões → Limpar divisões → `S.sv=2` num módulo de 1 vão até trocar de aba. Com a P1, ler esse vão devolve o padrão solto e fica anotado (1 chamada inválida); antes da P1, lia a sobra parada em `m.v[2]`.
- **Causa raiz:** o botão `#clr` zera `div/shv/dr/sr` e não ajusta o vão escolhido.
- **Correção:** `S.sv=0` no próprio botão (sem divisórias só existe o vão 1). É estado de tela: não muda peça, medida, configuração nem o que é gravado. `m.v` não é cortado, então o desfazer continua igual.
- **Fora do escopo autorizado (fica como risco):** outras camadas que mudam `m.div` direto no mesmo módulo. Com a P1, ler um vão que não existe nelas não grava nada.
- **Teste:** `testGvLimparDivisoesVoltaOVaoEscolhidoProPrimeiroNaHora` falha só com a P1 (`vão escolhido 2 de 1`, 1 inválida) e passa com o C.

## BKP-PONTOS: restaurar backup recusava o backup inteiro se algum arquivo tivesse ".." no nome (achado na validação da publicação, 17/11) — corrigido (autorizado pelo Adauto em 17/11)
- **Módulo:** backup completo, Android e Windows (`DataBackup.check`, introduzido na correção P0-02 de 16/11). iOS não tem: lá a entrada com ".." é só pulada, como antes.
- **Como apareceu:** a CI do Windows em modo teste (run 141, código do `5a468bf`) falhou em `DesktopCompatTest.backupCompletoERestauracao`. Esse teste passava na versão pública win-140 (`9f3dc3e`).
- **Reproduzido aqui:** `gradle test --tests '*DesktopCompatTest*'` com o cache `win-dev-deps`. Rodando sozinho ele passa; com a classe inteira ele falha.
- **Causa raiz comprovada:**
  - outro teste (`ponteDoEditorDeMoveis`) deixa na pasta de dados o arquivo `moveis-teste/.._fora.txt`. É um nome válido: a ponte do editor troca `../` por `.._`;
  - `check` recusa qualquer entrada cujo nome **contenha** `..` (`n.contains("..")`). Com isso o backup inteiro sai como "caminho inválido" e `stage` devolve false;
  - antes de 16/11 a proteção era por caminho canônico (só bloqueava sair da pasta).
- **Efeito para o usuário:** backup feito num aparelho que tenha qualquer arquivo com ".." no nome (ex.: "foto..jpg") não pode ser restaurado ("Nada foi alterado"). Não apaga nada, mas impede a restauração.
- **Correção proposta (mínima):** recusar só quando um **pedaço** do caminho for exatamente `..` (`n.split('/', '\\').any { it == ".." }`), mantendo as outras proteções, nos dois `DataBackup.kt`. Teste novo: backup com `notas/foto..jpg` restaura, e backup com `../fora.txt` continua recusado.
- **Publicação:** interrompida em Android, Windows e iOS até a autorização da correção.
- **Correção (autorizada em 17/11):** nos dois `DataBackup.kt` (Android e Windows), `n.contains("..")` virou `n.split('/', '\\').any { it == ".." }`. As outras proteções (raiz, `\\`, `:`, caminho canônico na extração, conferência do ZIP inteiro) ficam como estavam. iOS sem mudança.
- **Testes:**
  - `BackupCaminhoTest` (Android e Windows): nomes com pontos aceitos; `../`, `files/../..`, `files\\..\\`, `..`, `files/..`, raiz, `\\` e `C:` recusados;
  - sonda `tools/sondas/backup`: `nomesComPontosRestauram`, `projetoAntigoComFotoDePontosRestauraIgual` e `travessiasContinuamRecusadas`.
  - Antes da correção: `nomesComPontosSaoAceitos`, `nomesComPontosRestauram`, `projetoAntigoComFotoDePontosRestauraIgual` e `DesktopCompatTest.backupCompletoERestauracao` falham. Depois: sonda 16/16 e Windows JVM 134/134. Android JVM: na CI.

## TESTE-CUBA-PAREDE: expectativa velha contra a regra GEO-AVISA (achado na CI do iOS, 17/11)
- **Como apareceu:** a CI do iOS do `a17bcbf` (run 597) foi a primeira a compilar desde `9561fcd`. Dos 348 testes, 347 passaram no iPhone. Falhou só `testCubaArrastaNoTouchTecladoSomaLixeiraEParedeEncolhida`, nas duas tentativas: pedra em 2950 e lixeira em 2955 com a parede encolhida a 2400. O teste esperava as duas em 2400 ou menos.
- **Causa raiz:** comportamento mudado de propósito pela regra GEO-AVISA (Adauto, 16/11): "pedra e móveis soltos não são cortados pela parede".
  - Reproduzido aqui com o mesmo código do teste: em `0aa152c` (antes da regra) dá 2400/2400; no atual, 2950/2955.
  - A bateria daqui não lia esse formato (`(enc?["stFim"] as? Double) ?? 9e9`). Por isso o GEO-AVISA não atualizou a expectativa.
  - Medido: das 3.334 verificações dos testes, 380 só são conferidas pelo Xcode.
- **Correção (só o teste):** a expectativa passa a ser a regra aprovada: a pedra e a lixeira ficam **exatamente** onde estavam (2950 e 2955). O comentário do teste cita a regra e a data. O app não muda.
- **Risco registrado, não corrigido:** com a pedra ou a lixeira fora da parede encolhida, o app **não avisa** (`fgConflitos` só confere módulos). A regra GEO-AVISA pede aviso. É do editor, compartilhado com Android (apk-632) e Windows (win-143), e fica para decisão do Adauto.
- **Decisão do Adauto (17/11):**
  - a geometria atual da pedra, da lixeira e dos móveis soltos não muda;
  - a falta do aviso de objeto fora da parede fica como **melhoria pendente para as três plataformas**, fora desta homologação;
  - a correção do teste vale desde que o comportamento real siga a regra aprovada (a CI do iOS confere).

## P0-PAREDE: digitar a parede ou o pé-direito esmagava os móveis e cortava a pedra (autorizado pelo Adauto em 17/11; branch `claude/arquemestre-p0-parede`)
- **Versões afetadas:** públicas Android 1.0.632 e Windows win-143, e as anteriores. A homologação de 16/11 não pegou porque as sondas mudavam a parede pelo `setv`, sem passar pela cota.
- **Como reproduzir (versão pública):** cozinha demo, cota da parede no 2D, digitar 320 e depois 3600.
  - Todos os módulos ficam com largura 500 e x 0, e não voltam.
  - O aviso diz "Nenhuma medida foi alterada" (falso).
  - O mesmo com pé-direito 1500 ou 260, com "até o teto" sem pé-direito medido, e com guarda-roupa de 2400 e pé-direito 2000 (fica 2000).
  - O desfazer precisava de 2 toques.
- **Causa raiz (3 pontos):**
  1. `change` dos campos W/H/stT (`editor.html` ~2391): depois do `setv`, um laço gravava `o.w`, `o.x`, `o.h` e `o.b` de todos os módulos e cortava `S.stW`, fora da guarda GEO-AVISA.
  2. `stFollowAll`, chamado no `draw`: a conta do encaixe da pedra (`stFitCalc`) limita a pedra à parede. Mudar só a parede recalculava a pedra, que era cortada; a cuba andava e o fundo da pia trocava de módulo (`baseSemFundo`).
  3. Guarda do `roomClamp`: devolvia só largura e posição da pedra, não as pernas do L/U (`widA`/`widB`/`lenA`/`lenB`) nem a posição das cubas.
- **Correção:**
  1. Laço tirado. O mínimo de 500 mm do ambiente continua, mas avisa.
  2. A pedra acompanha só os módulos: assinatura `stModSig` dos módulos e móveis soltos; se só a parede mudou, a pedra não é recalculada.
  3. A guarda devolve a pedra inteira (pernas e cubas).
- **O que não mudou:** a regra aprovada "a pedra acompanha os módulos" (mexer nos módulos ainda reencaixa a pedra), os outros caminhos de parede, layout e fórmulas.
- **Testes:** os 3 falham na versão pública e passam agora.
  - `testP0ParedeEPeDireitoDigitadosNaoMexemNosMoveis`: 7 caminhos — cota W 320/1500, cota H 1500/260, "até o teto", `setv` e campo da parede do ambiente;
  - `testP0ParedeMenorQueOsMoveisSoAvisa`: nada muda, o aviso do mínimo e o de conflito aparecem;
  - `testP0ParedeDesfazRefazReabreEGuardaRoupa`: desfazer, refazer, salvar/reabrir, voltar a parede, guarda-roupa de 2400 com pé-direito 2000.
- **Contorno na versão pública até atualizar:** ↶ Desfazer antes de fechar o projeto.
- **Regressão achada e corrigida na homologação:** a 1ª assinatura (`6a319d7`) só tinha medidas e posição dos módulos, então ligar o tamponamento não fazia mais a pedra crescer 30 (`testTamponamentoNaoEntraNaPedraNemEmOutroModuloESemEspacoNaoLiga`). Agora a assinatura leva tudo que o `stFitCalc` lê, menos a parede: tamponamentos, recuo, fundo, nicho, lava-louças solta e as outras pedras. Os 36 testes de pedra e de P0 passam.
- **Homologação da P0 (`b9da40b`, 17/11):**
  - **Bateria:** 349 de 351. As 2 falhas não são da P0:
    - tamponamento b590 × b1410: já documentada, falha igual na versão pública;
    - `testFitaDaBaseEmbaixoDaPortaPintaPeloToque`: oscila neste ambiente. Com a máquina livre, 3 rodadas seguidas falharam 3/3 na versão pública `7c939bc`, 2/3 na P0 antiga e 3/3 na atual. Passou na CI do iOS (iPhone). Fica como teste instável, para investigar à parte.
  - **Sondas:** 25 de 29 idênticas às de `d669be5`. As diferentes: s10 e s25 só nos números de linha (+7); s21 só em horários e ids; s24 só nos tempos, com os contadores de vazamento iguais.
  - **Backup:** 16 de 16.
  - **Custo da assinatura da pedra:** 0,06 ms por desenho com 36 módulos.

## F3-TOQUE: o 1º toque num módulo não escolhido movia o módulo (Fase 3 item 1; decisão do Adauto em 17/11; branch `claude/arquemestre-fase3-precisao`)
- **Reproduzir (versão pública):** 2 balcões, A escolhido. Encostar o dedo no B e deslizar 60 px. B fica escolhido e já sobe 290 mm (vertical) ou anda 290 mm de lado (horizontal).
- **Causa:** `pointerdown` do 2D (`editor.html` ~1246–1250). Com o módulo não escolhido (`!was`), o app escolhia e armava `drag={t:'m'}` no mesmo gesto.
- **Correção:** com `!was`, o resto do gesto vira `drag={t:'pan'}`, o mesmo do toque no fundo, e só rola a vista. Com o módulo já escolhido, arrastar move como antes.
- **Testes:**
  - `testF3PrimeiroToqueEmModuloNaoEscolhidoSoEscolheNuncaMove`: falha na versão pública e passa agora.
  - **Expectativa adaptada (pedido do Adauto de 17/11):** o ajudante `drag2` de `testImaDoTopoAlinhaAereo…`, `testTocarOuSegurarOModulo…` e `testModuloNaoFazNadaSozinho…` agora escolhe o módulo antes de medir e arrastar. O que eles verificam (ímã, encostar, não fechar folga) não muda, e eles passam nas duas versões.
  - 20 testes de toque e arrasto passam nas duas versões.

## F3-SEL: divisória escolhida sem tocar nela, 2 toques que não abrem o menu e tremida que move (Fase 3 itens 2, 3 e 5; decisão do Adauto em 17/11)
- **Reproduzir (versão pública, 2 balcões de 2 vãos):**
  - toque a 16 px da divisória escolhe a divisória em qualquer zoom (o alcance era 22 px, e a área da divisória crescia com o zoom: 40 px no VB 450, 78 px no VB 225);
  - 2 toques no vão com 460 ms de um soltar ao outro não abrem o menu (limite 430 ms, contando o tempo do dedo apertado);
  - 2 toques a 16 px da divisória: o 1º escolhe a divisória e o menu não abre;
  - tremida de 8 px no módulo escolhido anda 15 mm; 7 px no 1º de 2 toques cancela os 2 toques.
- **Causa:** limites soltos e em unidades diferentes: `tapCount` (430 ms, 34 px), `pointerup` (6 unidades do SVG), zona morta do arrasto (6 px), alça da divisória `Math.max(18, …40 px…)` e a camada da divisória (22 px fixos).
- **Correção (`editor.html`):** uma constante `SEL` em px de tela: toque até 10 px; 2 toques até 500 ms de um soltar ao outro e 40 px; divisória só dentro da própria área (12 px de cada lado, nunca mais que metade do vão menor); o 2º de 2 toques no vão não vira divisória. Sem mudança de layout, peça ou medida.
- **Outros módulos (§11.2):** o mecanismo é o mesmo para todos os módulos do 2D comum (inferiores, superiores, torres, painéis). O editor por vãos (guarda-roupa, armário alto) tem a sua própria seleção (~9 px) e não foi mexido.
- **Testes:** `testF3SelecaoDivisoriaDoisToquesETremidaIguaisEmQualquerZoom` (relógio controlado no teste): falha na versão pública em 5 de 6 conferências e passa agora.
- **Expectativa adaptada (pedido do Adauto de 17/11):** o ajudante `drag2` de `testImaDoTopoAlinhaAereo…`, `testModuloNaoFazNadaSozinho…` e `testTocarOuSegurarOModulo…` tinha a zona morta antiga (6,5 px) escrita no teste. Agora lê `SEL.mov` do app (10 px; 6 na versão pública). O que eles conferem não muda, e passam nas duas versões.

## F3-MED: medida digitada fora do limite trocada em silêncio e campo arredondado (Fase 3 item 6; decisão do Adauto em 17/11: recusar com aviso)
- **Reproduzir (versão pública, Balcão 2 portas 900×820×560):** digitar largura 3 → vira 100; altura 3 → 290; profundidade 99999 → 1200; largura 99999 → 3160 (encaixa na parede). Nenhum aviso, e o campo mostra o que foi digitado. Largura 605,5 grava 605,5, mas o campo mostra 606.
- **Causa:** o `sanM` corta a medida no limite (`c('w',100,6000)`, `c('d',100,1200)`, altura mínima pelas peças) a cada desenho, sem avisar; `inp`/`syncInputs` usam `Math.round`.
- **Correção (`editor.html`):** `setv` testa a medida numa **cópia** do módulo com o próprio `sanM` (mesma conta, sem segunda regra de limite). Se o `sanM` mudaria o valor, a medida é recusada: nada muda, nenhum passo novo no desfazer, aviso com o mínimo ou o máximo, e o campo volta a mostrar o valor gravado. Enquanto digita (tecla a tecla) não avisa; avisa no OK ou ao sair do campo. O campo mostra o décimo gravado.
- **Fica igual:** medidas válidas, décimo virando folga na peça, a parede e o pé-direito (P0, outra branch), "Do chão" e o encaixe na parede de largura válida (perguntas 8 da Fase 3, sem decisão).
- **Outros módulos (§11.2):** o caminho é o mesmo para todos os módulos que usam os campos do painel (`data-k` w/h/d e as medidas externas wE/hE/dE).
- **Teste:** `testF3MedidaInvalidaRecusadaComAvisoECampoMostraODecimo`: falha na versão pública (6 de 8 conferências) e passa agora.

## F3-SETA: seta de trás do 3D não diminui depois de "tampou até o fundo" (Fase 3 item 7)
- **Reproduzir (versão pública):** aéreo afastado 300 mm da parede, tamponamento esquerdo; puxar a seta de trás até "tampou até o fundo" (681). Empurrar a seta pra dentro ~60 mm: a peça continua 681.
- **Causa:** `pointermove` das setas do 3D (`editor.html`, seta `ek`): qualquer posição até 120 mm da parede grudava na parede, também empurrando pra dentro.
- **Correção:** só gruda na parede quando o dedo puxa em direção a ela (ou se passaria da parede). Empurrando pra dentro, diminui.
- **Teste:** `testF3SetaDeTrasDo3DDiminuiDepoisDeTamparAteOFundo`: falha na versão pública (fica 681) e passa agora (621). Puxar de novo continua grudando no fundo.

## F3-REGN: "Réguas por lado (camadas: 1 a 3)" aceitava qualquer número (Fase 3 item 7)
- **Reproduzir (versão pública):** aéreo com engrosso cava; digitar 4 → grava 4 e gera 3; 0 → grava 0 e gera 2; 1,5 → grava 1,5. Sem aviso.
- **Correção:** só 1, 2 ou 3 são gravados; outro número avisa, não muda nada e o campo volta ao valor que vale.
- **Teste:** `testF3CamadasDoEngrossoCavaSo1a3ComAviso`: falha na versão pública e passa agora.

## F3-MENU: menus mudando de lugar entre os módulos (Fase 3 item 1; decisão do Adauto em 17/11: ordem fixa)
- **Reproduzir (versão pública):**
  - abas do editor por vãos: Divisões › Gavetas › Internos › Portas › Eletros › Estrutura › Cores, diferente do editor normal (Cores › Estrutura › Divisões › Portas › Internos › … › Eletros);
  - menu de 2 toques: "1 porta" a 31 px do topo no balcão, 260 px no armário alto e 316 px no guarda-roupa, porque o quadro "Por dentro deste vão" entra antes dos botões de frente.
- **Correção:** abas do editor por vãos na ordem do editor normal (Gavetas junto de Divisões); o quadro "Por dentro / Só esta parte" vai para depois dos botões de frente. Nenhum botão novo ou tirado.
- **Não reproduzido:** o vazamento da aba Portas para o editor por vãos (FASE3 1.B). Na sonda, entrar no editor por vãos com a aba Portas aberta não mostrou "Modelo da porta" fora da aba Portas. Fica como risco.
- **Teste:** `testF3MenusNaMesmaOrdemEmTodosOsModulos`: falha na versão pública e passa agora.
- **Expectativa adaptada (pedido do Adauto de 17/11, ordem fixa):** a ordem das abas no menu rápido de `testDoisToques…` (linha com "abas:").

## F3-AZUL: azul de seleção forte (Fase 3 item 4; decisão do Adauto em 17/11: mais suave sem perder a identificação)
- **Mudança:** módulo escolhido no 3D (Tamanho) de 40% para 25% de azul; divisórias do editor por vãos sem escolha de 0,35 para 0,22 de opacidade. A divisória escolhida continua vermelha e a cor continua #2f6be0.
- **Não mexido:** botões escolhidos (`.sel`), contorno do módulo no 2D e tamponamento. Se o azul forte for outro, um print resolve.
- **Teste:** só visual (imagens antes e depois no relatório). Nenhum teste da bateria depende dessas opacidades.

## PLANO DE CORTE (Adauto 17/11): peça tirada por identidade, toque longo, rodapé fora do corte (opção A) e brancos juntos — branch `claude/arquemestre-plano-corte`
- **Como era (versão pública):**
  - "− tirar" guardava em `S.cutOff` só tipo|material|cor|nome|medida com uma contagem. Duas peças iguais (a lateral de dois balcões iguais) não tinham como sair uma específica: saía "uma delas".
  - Não havia toque longo nem clique direito na peça do plano.
  - Não havia como tirar o rodapé do corte. O rodapé contínuo (módulos encostados) é uma peça só, ligada a todos os módulos do trecho.
  - Cor de fora branca (ex.: Branco Supremo) ia para chapas separadas da caixa branca (`sameFin` era calculado e não usado).
- **Identidade (PC-ID, decisão do Adauto: uma só, compartilhada):** `uid` do módulo (o `m.uid` que já existia, usado no empilhamento) + `pk` da peça + nº da ocorrência dessa `pk` no módulo (o fundo grande de guarda-roupa sai em 2 peças com o mesmo `pk`: achado em 6 modelos do catálogo). Sem índice de módulo. Cópia de módulo com o mesmo `uid`: só o primeiro fica com ele (mesma regra do `stkSync`) e a cópia não herda o que foi tirado. O `uid` só é criado quando a pessoa tira uma peça (nenhum projeto muda ao abrir).
- **`S.cutOff` reaproveitado:** chave nova `@uid|pk|n` (valor 1) ao lado das chaves antigas de contagem, que continuam valendo. Mesmo `offAdd`, mesmo "Fora do plano · ↩ Voltar". Passa pelo desfazer (histórico por estado). Orçamento usa `sheetPlan(1)`, que já ignora o que foi tirado: não muda.
- **Toque longo (PC-TOQUE):** 1,5 s parado (até 10 px) abre o menu com a peça, o módulo, 🗑 Remover peça (pede confirmação) e Cancelar; o clique direito abre o mesmo menu. Rolar, arrastar ou soltar antes não abre; o "click" depois do toque longo não vira 3D nem "cortada".
- **Rodapé (PC-ROD, opção A):** aba Estrutura › Rodapé: "Incluir no plano de corte · todos os rodapés deste módulo" e, com um rodapé escolhido no 2D ou no 3D, "· só este". Rodapé contínuo com o trecho de um módulo fora: o corte fica com os trechos que sobraram (3 balcões 800+600+700: 2100 → 800 e 700), frente e trás separados. 2D, 3D e medidas não mudam.
- **Brancos (PC-BRANCO):** peça de cor branca (qualquer branco, pelo nome) vai para as chapas da caixa quando a caixa é branca; sem caixa branca, os brancos de cor se juntam entre si. As chaves antigas de "− tirar" continuam com o tipo original (não reaparecem peças tiradas).
- **Testes (falham na versão pública e passam agora):** `testPlanoDeCorteToqueLongoTiraSoAquelaPecaPelaIdentidade`, `testPlanoDeCorteRodapeForaDoCorteRodapeContinuoFicaSoComOsTrechos`, `testPlanoDeCortePecaBrancaDeQualquerBrancoVaiProMesmoGrupoDaCaixaBranca`. Os 4 testes antigos do plano de corte passam nas duas versões.
- **Pendente / risco:** rodapé corrido das fileiras em L (`cutGroups_lr`): tirar um trecho só tira o rodapé inteiro quando todos os trechos estão fora (não divide). Peça grande dividida em partes ("em n partes"): cada parte tem a própria ocorrência.

## TESTE-RECUO: testes novos não compilavam no iOS (CI 604, 17/11)
- **Erro:** `insufficient indentation of next N lines in multi-line string literal`. O JavaScript dos testes novos começava na coluna 0; no Swift, o texto entre `#"""` e `"""#` tem que estar pelo menos tão recuado quanto o `"""#`. A bateria do Windows/Chromium lê o JS direto e não acusa.
- **Correção:** só recuo (8 espaços) nas linhas do JS dos testes novos. Nenhuma conferência mudou.
- **Prevenção:** conferir o recuo dos blocos `#"""` antes de cada commit de teste (script na pasta de rascunho da sessão).
- **Bateria do Windows (run 41, 17/11):** 349/351.
  - `testTamponamentoNo2D…` também falha na versão pública.
  - `testOpcaoMarcadaSempreMudaAlgumaCoisa` acusou o "Incluir no plano de corte" do rodapé como opção que não muda nada. Esse teste só olhava peças, `cutLines` e custo, e a opção muda o plano de corte (`S.cutOff`).
  - **Expectativa adaptada (pedido do Adauto 17/11):** o teste também olha o `S.cutOff`. Continua exigindo que toda opção marcada mude algo. Passa nas duas versões.

## F3-SEL-REGRESSÃO: 2 pares de toques viravam 4 toques (podia travar o módulo) e a divisória não pegava logo depois de arrastar (achado na bateria final da Fase 3, 17/11)
- **Testes que pegaram:** `testDoisToquesNoVaoDeCimaAteOTetoRipadoPainelOuFechamento` (versão pública 3/3; F3-SEL 0 a 1 de 3, intermitente) e `testDivisoriaArrastaComODedoEmQualquerProjetoECaminho` (12 px do lado não arrastava).
- **Causa 1 (commit 469c0d0):** a janela dos 2 toques passou a 500 ms contados de soltar a soltar. Dois pares de 2 toques com ~450 ms entre eles somavam 3 e 4 toques (4 toques travam o módulo).
  - **Correção:** contar do 1º soltar ao 2º encostar, até 350 ms (é o número da proposta aprovada). O tempo do dedo apertado não conta, e pares separados não se somam.
- **Causa 2:** arrastar uma divisória contava como toque. O toque seguinte, em até 500 ms, virava "2º toque" e não pegava a divisória.
  - **Correção:** se a divisória andou, o soltar não conta como toque.
- **Causa 3:** a área da divisória ficou estreita demais em vão estreito: só até metade do vão menor, e com 12 px exatos de fora por arredondamento.
  - **Correção:** até 12 px de cada lado, contando a borda. Em vão estreito, até 35% do espaço entre as divisórias, como no pedido antigo do dedo que errava a divisória.
- **Teste F3 ajustado:**
  - "2 toques com o dedo apertado 150 ms e 330 ms entre soltar e encostar" abre o menu (falha na versão pública);
  - "2 pares com 400 ms entre eles" não trava o módulo.

## SEG-NOMES — iOS pulava no backup, e as 3 plataformas na sincronização, arquivos com ".." no nome (17/11/2026, auditoria geral, P0)
- **Defeito:**
  - **Backup no iOS:** `ios/Arquemestre/Data/Backup.swift` restaurava pulando, **sem avisar**, todo nome com ".." (`contains("..")`). Uma foto `foto..jpg`, vinda do backup do Android, sumia no iPhone.
  - **Sincronização Wi-Fi:** `safeName` (SyncCore no Android, no Windows e no iOS) recusava qualquer nome com "..". A foto não era enviada nem recebida.
- **Causa:** a regra confundia "dois pontos seguidos no nome" com "subir uma pasta".
  - O Android e o Windows já tinham corrigido isso no backup (BKP-PONTOS: só um pedaço do caminho igual a ".." é travessia).
  - O iOS e a sincronização não acompanharam.
- **Correção (decisão do Adauto em 17/11: aceitar nomes válidos e bloquear só caminhos inseguros):**
  - **Backup do iOS:** recusa só um pedaço do caminho igual a "..", ou caminho que começa por "/" ou "\". A conferência de que o arquivo cai dentro da pasta de restauração continua.
  - **Sincronização:** o nome é de um arquivo só. Recusa vazio, mais de 120 caracteres, barra, contrabarra e os nomes "." e ".." sozinhos.
- **Testes (commit `a215f60`, antes da correção):**
  - **iOS:** `BackupSafetyTests.testRestoreKeepsNamesWithDoubleDotsAndStillBlocksTraversal` restaura `foto..jpg`, `a..b/c.json` e `projeto..v2.json` com o conteúdo certo. `files/../fora.txt` e `files/projects/../../../fora2.txt` não são gravados fora.
  - **iOS:** `SyncInteropTests.testCodigoDaTelaEPacoteInvalido` confere `safeName`.
  - **Android e Windows:** `SyncTest`, "foto com dois pontos seguidos no nome passa" (mesmos bytes) e ".." recusado.
- **Prova:** CI no `a215f60` (só os testes), que deve falhar, e no commit da correção, que deve passar.

## N03 — gravação do arquivo dos projetos que falhava sem aviso e fazia voltar o projeto velho (17/11/2026, auditoria geral, P0)
- **Reproduzido** na versão publicada, com o teste `testGravacaoDoArquivoDeProjetosQueFalhaAvisaENaoVoltaOProjetoVelhoAoAbrir`:
  1. O aparelho recusa gravar o `projects.json` (sem espaço).
  2. Nenhum aviso aparece.
  3. Na abertura seguinte, o app carrega o arquivo velho (v1) por cima do que foi feito (v2), que ficou só na cópia do navegador.
  4. O próximo salvamento automático grava o velho de novo.
- **Causa:**
  - Os 3 nativos engoliam o erro do `putFile`:
    - Android: `runCatching` sem retorno;
    - Windows: devolvia `""`;
    - iOS: `try?` assíncrono.
  - Na abertura, o `pjsEscolhe` sempre prefere o arquivo quando ele tem projetos.
- **Correção:**
  - **Android:** `putFile` devolve Boolean.
  - **Windows:** responde `"true"`/`"false"` e a ponte usa `B('putFile')`.
  - **iOS:** o `projects.json` passa pelo canal síncrono e responde `"ok"`. Os outros arquivos seguem assíncronos, para não pesar no toque.
  - **Editor:** quando a gravação falha, avisa uma vez e guarda uma marca (`arque.projects.v1.pend`) com a assinatura do arquivo velho. Na abertura:
    - se a marca existe e o arquivo é o mesmo de então, vale a cópia mais nova do navegador;
    - se o arquivo mudou por fora (restauração de backup), vale o arquivo, como sempre.

    A marca sai quando uma gravação dá certo.
- **Teste:** falha na versão publicada e passa na correção.
- **Ainda não testado:** a falha real de espaço no aparelho. O retorno nativo é conferido na compilação e no fluxo de teste do Windows.
- **Aviso à pessoa:** é um texto curto (toast). Não muda o layout.

## N04 — dados do projeto que não iam no arquivo salvo (17/11/2026, auditoria geral, P0)
- **Reproduzido:** sonda e teste `testDadosDoAmbienteEEscolhasDo3DVoltamDepoisDeSalvarEReabrir`. Ao salvar e abrir de novo, 7 dados voltavam ao padrão:
  - `S.pw`: medidas do gerador de painéis de parede;
  - `S.RDw` e `S.RDs`: profundidade original da sala quando a parede lateral a estica;
  - `S.rodLast`: última altura do rodapé, usada ao religar;
  - `S.deco`, `S.tvLogo` e `S.tvAnim`: escolhas do 3D.
- **Também:** o desfazer não voltava a escolha de decoração.
- **Causa:** esses campos não estavam no `snapState` (nem nos embrulhos dele). Enquanto o app ficava aberto, eles continuavam na memória e passavam até para o próximo projeto aberto.
- **Não afeta:** peças, móveis e painéis já criados (`S.rp`), que sempre foram salvos.
- **Correção:** mais um embrulho de `snapState`/`loadState`, no mesmo padrão dos outros (`tz`, `pxk`…).
  - **Ao salvar:** o campo vai junto só quando existe, então projeto antigo não ganha nada.
  - **Ao abrir:** volta o que está no arquivo e apaga o que vier do projeto anterior.
- **Teste:** falha antes (commit do teste) e passa depois.

## N13 — vídeos do editor fora do backup no Android e no Windows (17/11/2026, auditoria geral, P0)
- **Encontrado na auditoria:** no iOS, cada vídeo do editor (IndexedDB `arque-photos`, `kind:"video"`) é copiado para `video_<id>.json` pelo `EditorMediaBackup.js` e entra no backup completo. No Android e no Windows o script não era carregado e a ponte não tinha `putVideo`. O vídeo ficava só no IndexedDB do WebView, fora do backup, e se perdia ao trocar de aparelho ou restaurar.
- **Causa:** o espelhamento dos vídeos foi feito só no iOS. Fotos já iam pelos três (`photo_<id>.json`).
- **Correção (sem mudar o editor):**
  - **Script:** o mesmo `EditorMediaBackup.js` fica agora também em `app/src/main/assets/`, com cópia idêntica conferida por teste.
  - **Vídeos grandes:** vídeo acima de 64 MB fica no aparelho, com o aviso "não vai no backup". No iOS, com `window.__mediaKeepBig` ausente, nada muda.
  - **Android:** `MoveisBridge.putVideo` → `EditorVideo.save`; o script é injetado no `onPageFinished`.
  - **Windows:** a ponte ganha `putVideo:B('putVideo')`, o script vai no `editorHtml()` e o asset entra no `build.gradle.kts`.
  - **`EditorVideo.save`:**
    - id só `[A-Za-z0-9_-]`, até 120 caracteres;
    - `kind` precisa ser `"video"`;
    - `data:` precisa estar em base64 válido;
    - até 64 MB;
    - gravação atômica (temporário + troca de nome).
- **Testes:**
  - `EditorVideoTest` (Android e Windows): vídeo válido grava; id que sobe pasta, id com barra, outro tipo, base64 quebrado e texto que não é JSON não gravam nada; o script é igual ao do iPhone.
  - `DesktopCompatTest.ponteDoEditorDeMoveis`: a ponte responde true/false.
- **Validação:** CI Android 641 e Windows 150 (commit 2089f26).
- **Pendente:** teste de ponta a ponta no aparelho (gravar vídeo no editor → backup → restaurar em outro aparelho). Precisa de aparelho real; ainda não verificado.

## GAV-SET e GAV-EXCESSO — altura da lateral da gaveta vale pro conjunto todo (pedido do Adauto, 18/11)
- **Pedido:** mudar a altura da lateral de uma gaveta muda as laterais de todas as gavetas do mesmo conjunto (acima e abaixo), não só as duas da gaveta tocada.
- **Reproduzido:**
  - gaveteiro de 4: a lateral da gaveta 3 em 100 deixava só a gaveta 3 com 100; as outras continuavam com 57;
  - corte antes: 2× 107, 2× 57, 2× 100, 2× 70.
- **Causa:** o ajuste à mão (`m.po` da lateral) entra só na caixa daquela gaveta (`gbOv` soma as 2 laterais da mesma gaveta).
- **Achado junto (GAV-EXCESSO):** pedir mais que o máximo da frente guardava o excesso (pediu 120, ficou 107,8, mas guardou +63). A redução seguinte saía errada (pediu 70, dava 83,8). Já acontecia com 1 gaveta, antes deste pedido.
- **Correção:** `gavSetSync`, ligado no `poAlign`, que já roda depois de digitar, dos botões finos e do arrasto no 3D.
  - Lê a altura que o `partsOf` deu e põe o mesmo ajuste de altura em todas as gavetas do mesmo vão do mesmo módulo, inclusive a editada, com a diferença exata.
  - Não mexe em frente, largura, profundidade, posição, folgas nem corrediça.
  - Se alguma não cabe, o conjunto volta pra altura anterior e avisa.
  - Desfazer e refazer: uma operação só.
  - Quando a altura pedida passa do máximo em todas, todas ficam no máximo, como já era com 1 gaveta.
- **Teste:** `testLateralDeUmaGavetaMudaTodasAsGavetasDoConjunto`.
  - Cobre 2, 3, 4 e 5 gavetas, mexendo na primeira, numa do meio e na última; aumentar, passar do máximo e diminuir; desfazer e refazer; frentes; salvar e reabrir; plano de corte; outro conjunto do mesmo módulo; outro módulo.
  - Falha antes (fab3d8b) e passa depois (0f45970).
- **Fora deste pedido (sugestão):** a altura da frente/costa da gaveta também é altura da caixa e não foi ligada ao conjunto. A caixa interna do guarda-roupa (caixote) usa outras peças.

## DUPLO-TOQUE — 2 toques não funcionavam na geladeira e nas torres altas (pedido do Adauto, 18/11)
- **Auditoria:** 2 toques em todos os itens do catálogo (567 itens, um editor novo por item).
  - Falhavam 8: as 2 caixas da geladeira, a Torre do banheiro e 5 torres da sala (torre 2 portas, torre 1 porta, armário alto de correr, cristaleira, estante torre).
  - Os demais abrem o que já era aprovado: menu do vão, ajustes das gavetas, configuração da porta de correr.
- **Causa (2 classes, mesmo mecanismo):** o `pointerup` dos 2 toques procura o módulo com `closest('#mod')`. Dois desenhos ficam por cima do módulo, fora do grupo dele:
  - o eletro no nicho (`data-ap`, a geladeira);
  - o puxador invisível da prateleira interna do módulo selecionado (`data-ish`, faixa de 20 px).
- **Correção:** só para os 2 toques, quando o toque cai num desses dois, vale o módulo que está embaixo (`elementsFromPoint`).
  - 1 toque continua igual: pega a geladeira ou a prateleira.
  - 4 toques não travam por cima.
  - Sem tratamento por tipo de móvel.
- **Teste:** `testDoisToquesFuncionamNaGeladeiraENasTorresComPrateleira`, com toque e mouse, zoom normal e com zoom; o módulo não sai do lugar. Falha antes (7a2b277) e passa depois (f18e74f).
- **Regressão:** auditoria por categoria antes e depois, sem nenhum item que funcionava parando de funcionar.

## CANTO-SOZINHO — abrir o projeto empurrava o móvel da parede do lado (achado no pedido das paredes, 18/11, P0)
- **Reproduzido:** projeto salvo com o balcão da parede da esquerda a 49 mm do canto. Só de abrir e esperar 0,25 s, ele ia de 630 para 581 e ficava salvo assim.
  - Em 15 projetos gerados (abrir, tocar, trocar de parede), 7 tinham móveis mudando sozinhos. Um armário foi de 1034 para 558 e uma geladeira de 100 para 715.
- **Causa:** o encosto no canto entre paredes (A55, 15/11: "chegou perto, encostam") não sabia quem foi mexido. Na 1ª conferência depois de abrir, empurrava o módulo da parede do lado (ou o do fundo).
  - Isso fere a decisão de 16/11: o app nunca muda posição sozinho.
- **Correção:** cada módulo tem a posição anotada.
  - Abrir o projeto e desfazer só anotam onde cada um está.
  - Só o módulo que mudou de posição ou medida, ou acabou de entrar, anda até encostar.
- **Testes:**
  - `testTrocarDeParedeEMexerNaGeladeiraNaoMoveNenhumMovel`: abrir; geladeira com 1 e 2 toques; fundo → esquerda → direita → fundo pela barra; escolher um módulo na esquerda e trocar; salvar e reabrir. Nada muda. Falha antes (84e7db9) e passa depois (062a536).
  - O `testModulosDeParedesDiferentesEncostamNoCantoSemEntrar` (A55) continua passando.
  - Sonda com 15 projetos: 0 mudanças depois da correção.
- **Risco anotado:** posição digitada perto do canto ainda encosta (a pessoa mexeu). Fica pra decisão do Adauto se a posição digitada deve valer exatamente.

## PAREDE-ESPELHADA — a parede da esquerda aparece invertida no 2D (pedido do Adauto, 18/11) · corrigido na representação
- **Medido:** no 3D o fundo fica em z = 0. Olhando a parede da esquerda de dentro do ambiente, o canto do fundo fica à **direita**. O 2D mostrava o canto à esquerda: **invertido**. Fundo e direita estavam certos.
- **Causa raiz:** as paredes do lado guardam x a partir do canto do fundo. O `draw()` desenha x = 0 à esquerda da tela nas duas paredes laterais; na da esquerda devia ser o contrário.
- **1ª tentativa (revertida, `c10930d`):** virar as coordenadas (`wvFlipE`) e espelhar o 3D por dentro.
  - Quebrou 4 testes aprovados: pedra, encosto entre paredes, canto em L e espaçador.
  - No 3D isolado, deu 32 sobreposições de módulo dentro de módulo.
- **Decisão do Adauto (18/11):** "Manter físico, corrigir nomes". O 3D, as posições, os dados e o corte não mudam. Só o 2D da parede esquerda é desenhado como visto de dentro, e os nomes dos lados no painel seguem quem olha.
- **Correção (só representação, bloco no fim do `editor.html`):**
  - Depois de `draw()`, na parede `e` (fora do "Só ele no 2D"), o conteúdo do `#svg` vai pro grupo `#wvmir` com `matrix(-1 0 0 1 900 0)`. Espelha o quadro inteiro (0–900), então o que cabe no desenho normal cabe no espelhado.
  - Cada texto é desvirado em volta do próprio centro e continua legível.
  - `px(ev)` devolve o ponto espelhado. Toque, 2 toques no vão e arrasto usam as contas de sempre, a partir do canto.
  - Nomes: o painel (`#bd`) troca esquerdo↔direito nos móveis da parede esquerda (`ladoNaEsquerda`). Não troca nomes de parede, nem "lado do canto", nem os seletores de parede.
- **Ajuste (18/11):** a 1ª versão espelhava em volta da parede (eixo `2·OX + W·K`). Com o móvel no fim da parede, o "⚠ pé-direito não medido" do móvel saía 108 px pra fora do quadro.
  - Medir o texto e empurrar o desenho não serve: o aviso some e aparece conforme o móvel escolhido, e o desenho andava entre o 1º e o 2º toque (o 2º toque caía fora do vão).
  - Correção: eixo fixo 900, a largura do quadro (`setVB`).
- **Ajuste 2 (18/11, CI iOS 630):** o eixo fixo 900 tirava a parede esquerda da vista no celular, que enquadra a vista na parede.
  - **Sintoma:** no iPhone, `testDoisToquesNoVaoDeCima…` não achou o vão ("nenhum"). Reproduzido na janela 440x956.
  - **Correção:** volta o eixo da própria parede. Só o texto que passaria da borda esquerda (como o aviso do pé-direito) vai pro outro lado da sua linha, no espaço acima do móvel. O desenho não anda.
  - O teste do arrasto passou a usar a distância na escala da tela (800 mm). No iPhone e no iPad, 150 px fixos batiam no limite, inclusive na parede do fundo.
  - **Validação:** passa em 440x956, 1032x1376 e notebook.
  - **Commits:** `a6d7cc1` (teste), `7d7fd3c` (correção).
- **Não mudou:** `S.mods`, `m.x`, `m.wing`, `tl`/`tr`, `pk`, o ajuste por peça (`po`), `partsOf`, `cutLines`, lista, plano de corte, orçamento e 3D.
- **Fica com o nome guardado (pendente de decisão):** a lista e o plano de corte. Lá o nome da peça faz parte da chave da marca "✓ cortada" (`offKey`/`ck`), e trocar apagaria marcas já salvas.
- **Testes:**
  - `testParedeDaEsquerdaNaoFicaEspelhadaNo2DNemNo3D`: ordem 2D × 3D, tamponamento, texto legível, dados e corte iguais.
  - `testParedeEsquerdaToqueDoisToquesEArrastoSeguemODesenho`
  - `testParedeEsquerdaNomesDosLadosSeguemQuemOlha`
  - `testProjetoAntigoComMoveisNaParedeEsquerdaAbreIgual`: posições, peças, corte, pedra com cuba, orçamento, 3D caixa a caixa, salvar e reabrir.
  - `testParedeEsquerdaAvisoNaoSaiDoQuadroEDesenhoNaoAndaAoEscolher`
  - Cada um falha antes da sua correção e passa depois. Os 4 testes que quebraram na 1ª tentativa passam.
- **Risco visual anotado:** na parede esquerda o desenho fica mais à direita do quadro. Com parede larga, a ponta da cota "Parede X" passa por baixo dos botões flutuantes (cadeado, lixeira, calculadora), como já acontece com o lado direito no desenho normal.
- **Commits:** `19ae71e`, `df6ea18`, `e2c1272`, `8896510`, `4460b2e`, `44553aa`, `4079a63`, `6bcdf6e`.

## AUDITORIA-GEOMETRIA e CENARIO-COMPLETO — itens 9 e 11 do pedido de 18/11 (auditoria, sem defeito novo)
- **Item 9, motor geométrico e plano de corte** (`testCatalogoInteiroMesmaPecaNo2DNo3DENoCorteSemDecimo`): no catálogo inteiro (142 modelos, 2971 peças de corte), nenhum problema:
  - nenhuma peça de corte com medida zero;
  - nenhuma com décimo (peça só em mm inteiro);
  - nenhuma fora do plano de corte;
  - nenhuma do corte fora do 3D;
  - nenhuma caixa do 3D sem peça de origem.
  - Comportamento correto conferido: o tamponamento de 30 mm do aéreo sai no corte como 2 réguas de 15 (chave "(régua)"); face e engrosso são partes da mesma peça.
  - O guarda da fita (`374faea`, "não aplicar desconto da fita de 1 mm no corte") continua valendo.
  - Teste de guarda: não houve defeito pra reproduzir antes.
- **Item 11, cenário completo** (`testCenarioCompletoDoClienteAoBackupTudoCoerente`), passando em notebook, 440x956 (iPhone) e 1032x1376 (iPad). Passos:
  1. cliente e projeto, paredes medidas;
  2. 4 módulos;
  3. gaveteiro pra parede esquerda;
  4. balcão da pia por vãos (basculante e 2 gavetas) e torre em 3 partes;
  5. tamponamento de cima e esquerdo;
  6. medida interna (vão 1170 = 1200 − 2×15);
  7. 3D sem peça faltando nem inventada;
  8. corte sem décimo;
  9. salvar, fechar e reabrir com peças e corte iguais;
  10. backup lido e restaurado com peças e corte iguais;
  11. o projeto original continua.
- **Regra que já existia, registrada (decisão do Adauto se quiser mudar):** ao passar um móvel pra outra parede, o lado que fica exposto ganha o tamponamento automático (`tlAuto`/`trAuto`). Medida e posição não mudam; só entra essa peça.

## VAOS-BALCAO — editor por vãos também no balcão de pia (pedido do Adauto, 18/11, item 8; resposta: "Aplicar isso para balcões de pia também")
- **Pedido (item 8):** escolher qualquer vão e pôr porta (comum ou basculante), gaveta (uma ou conjunto), prateleira (com engrosso ou sem recuo), divisória e puxador. Cada mudança só no vão escolhido. Exemplo dele: no balcão da pia, gaveta no vão de baixo e basculante no de cima.
- **Antes:** o editor por vãos (`rgFrom`/`rgInit`/`rgParts`) só ligava em torres (`soloOn`: altura ≥ 1500 ou "em cima").
- **Medido (18/11):** converter um balcão com a conta da torre mudava peças de fabricação:
  - porta 705 → 650;
  - "Moldura de acabamento" de 30 mm a mais;
  - em Balcão da pia, Balcão 2 portas e Balcão 1 porta.
- **Causa raiz:**
  - **Porta:** no editor normal, com travessa frontal a frente sobe e cobre a travessa (`tX_`/`tXv_` no `partsOf`); o `doorBox` do editor por vãos não aplicava essa regra.
  - **Moldura:** `moldFr` (tem frente?) só olhava `m.v`, e no editor por vãos as frentes ficam na árvore `m.rt`.
- **Correção (só balcão: não superior, abaixo de 1500, não "em cima"; torre não muda):**
  - `rgBalTx`: a frente de cima sobe com a mesma conta do editor normal (inclui rack/moldura e cava).
  - `moldFr` enxerga porta e gaveta na árvore.
  - Resultado: corte e posição de cada peça idênticos ao converter (Balcão da pia, 2 portas, 1 porta).
- **Entrada:** `soloOn` ("Editar só ele no 2D") converte o **balcão de pia**: `m.pia` (o "Balcão da pia") ou cuba na pedra em cima dele (`rgBalPia`). Só fica convertido se o corte (medidas, espessura, nome) e a posição de cada peça forem idênticos (`rgBalTenta`); senão volta e avisa. Sem mexer, sair do 2D volta igual (RGAUTO).
- **Não muda:** balcão que não é de pia, aéreo e o editor de hoje.
- **Teste:** `testBalcaoDaPiaNoEditorPorVaosGavetaEmbaixoBasculanteEmCima`.
  - Verifica: entrar sem mudar peça, sair igual, o exemplo do pedido (basculante em y 10 cobrindo a travessa; 2 gavetas por fora terminando em 710, como a porta normal), corte, outro balcão sem mudar, salvar e reabrir, balcão comum fica no editor de hoje, torre continua.
  - Falha em `e39e655` e passa na correção.
- **Não verificado:** balcão de pia com cuba na pedra (só o `m.pia` está no teste); aéreo (não pedido).
- **Commits:** `6a21984` (teste), `6a3b26f` (correção). Ramo `claude/arquemestre-vaos-balcao`.

## TAMP-DESCE — 2 toques na ponta do tamponamento de cima descem um tamponamento livre (pedido do Adauto, 18/11, item 7)
- **Pedido:** "Eu seleciono o lado que quero descer um tamponamento clicando na ponta duas vezes no 2D e o app pergunta descer tamponamento direito ou esquerdo, opção de inverter, aumentar ou diminuir ele também ao selecionar pelo arrasto".
- **Esclarecimento dele (18/11):**
  - "Tamponamento lateral é um tamponamento livre descendo esquerda ou direita";
  - "não mudar forma que já existe, apenas implementar";
  - "inverter é o mesmo dos outros já existente";
  - "procure ferramentas que já estão funcionando e agregue".
- **1ª versão (`7a54293`, substituída):** descer ligava o tamponamento esquerdo/direito do próprio móvel (`tl`/`tr`). Não era isso.
- **Correção (bloco TAMP-DESCE no fim do `editor.html`):** 2 toques no "Tamponamento de cima" no 2D abrem `#ttq`.
  - **Descer esquerdo/direito:** cria o **tamponamento solto que já existe** (`S.geo`, tipo `tamp`, o mesmo do "Tamponamento criado · arraste pra mover" do 3D), que já entra no corte (`geoCutPieces`, 30 mm = 2 × 15) e no 3D.
  - Ele fica encostado na ponta do de cima (posição tirada das caixas do 3D, `__build`), com a mesma profundidade, do topo do de cima até a base do móvel.
  - O tamponamento do móvel e o móvel não mudam. Tocar de novo tira.
  - **Inverter:** o `tpInvSet` que já existe, no de cima.
  - **Aumentar/diminuir:** no 2D, o tamponamento livre que desceu ganha uma alça por cima do desenho. A ponta de baixo anda com o dedo e o topo fica no lugar.
  - Os outros tamponamentos soltos continuam só desenho no 2D.
  - 2 toques no corpo do móvel continuam abrindo o vão.
- **Ajuste (18/11, "ela começa por baixo do tamponamento superior"):** o lateral livre começa embaixo do de cima e vai do fundo dele até a base do móvel (no aéreo 2 portas: h750, não 780).
  - O de cima passa por cima do livre também: a conta dele (`if(m.tt)` no `partsOf`), que já somava os laterais do móvel, soma `ttExL`/`ttExR`, a espessura do livre. Exemplo: de 1000 vai a 1030 com o esquerdo e a 1060 com os dois.
  - Tirar o livre apaga o campo e o de cima volta ao que era.
  - Falha em `2d50eaa` e passa na correção. Os 38 testes de tamponamento, o cenário e a auditoria passam em notebook e 440x956.
- **Ajuste 2 (18/11):** "A ideia é criar um tamponamento flutuante ou separado do corpo do módulo, como se fosse uma extensão que vira mesa" e "Livre eu controlo como quiser, sem dependência, sem puxar o outro".
  - Saiu o esticamento automático do de cima (`ttExL`/`ttExR`, do ajuste anterior). O de cima e o móvel não mudam.
  - O livre começa embaixo do de cima e, no 2D, é independente: pelo meio anda pra qualquer lado; pelas pontas de cima ou de baixo muda o tamanho.
  - Só não entra dentro de um móvel (peça sólida, CLAUDE.md §4).
  - Tocar de novo no menu tira o livre daquele lado, mesmo depois de movido (marca `dm` do móvel).
  - Falha em `efa5aaa` e passa na correção. Os 47 testes (tamponamento, peças soltas, cenário, catálogo) passam em notebook e 440x956.
- **Plano de corte em tempo real (conferido em 18/11, teste `testTamponamentoLivreSobeEAtualizaNaHoraNoPlanoDeCorte`):** `cutGroups` soma `geoCutPieces` a cada chamada, e o plano de chapas (`sheetPlan`), a lista de corte (`cutAll`) e o número de chapas do orçamento (`budget().nC`) leem dele.
  - Num balcão 2 portas:

    | Momento | Corte | Peças | Chapas na cor |
    |---|---|---|---|
    | Antes | — | 19 | 1 |
    | Desceu | 2×820x585 | 21 | 2 |
    | Encolheu 200 | 2×620x585 | 21 | 2 |
    | Tirou | — | 19 | 1 |

  - **Fita no orçamento:** a fita de borda da peça solta não entrava nos metros de fita do orçamento. O Adauto decidiu (18/11): "Fita de borda no orçamento pode aplicar sim do tamponamento".
    - **Regra:** a mesma do tamponamento do móvel (`mCost`/`edgeMm`): 4 bordas, 2 × (comprimento + largura). Com 25 mm ou mais vai na fita larga 35 mm; mais fino, na fita da cor. Só tamponamento, não a placa.
    - **Validação:** livre 820 × 585 de 30 mm dá +2,81 m de fita larga; encolhido 620 dá +2,41 m; tirado volta a 0; livre de 15 mm 700 × 500 dá +2,4 m na fita da cor.
    - Falha antes (0 m) e passa depois.
- **Limite:** só na parede do fundo, porque o tamponamento solto só é desenhado no 2D da parede do fundo. Na parede do lado o app avisa.
- **Teste:** `testDoisToquesNaPontaDoTamponamentoDeCimaDesceOLateralEInverte`.
  - Verifica: pergunta, sem menu do vão, livre com x1170, w30, z6, d375, b1750, h780 e móvel igual, corte 2×780x375, inverter, direito, arrasto aumenta com o topo no lugar e o móvel parado, tocar tira, corpo abre o vão, salvar e reabrir.
  - Falha em `7907232` e em `7a54293`; passa na correção.
  - Os 36 testes de tamponamento e o do cenário completo passam em notebook e 440x956.
- **Commits:** `2b1ba4c`, `7907232` e o teste do esclarecimento; `7a54293` (1ª versão) e a correção do tamponamento livre.

## TORRE-DIRETO — torre / armário alto por vãos: painel por vãos sem ir pro 2D isolado (pedido do Adauto, 18/11, 2 fotos)
- **Pedido:** "Ao clicar em torre/armário alto não aparece somente essa cabeçalho lateral… aparecer esse [painel] sem precisar de ir pro 2D isolado dele". Escolha dele (18/11): **painel por vãos + vão tocável no desenho do projeto**; 1 dedo arrastando continua movendo o móvel.
- **Antes:** numa torre que já é por vãos (editada antes no 2D isolado, ou "montar do zero"), o painel do projeto só mostrava o quadro "Este módulo é montado por vãos no desenho… ✏️ Editar só ele no 2D" (o "cabeçalho"). O editor por vãos (`rgOverlay`, `tabsHtml`/`body`, menu de 2 toques) só ligava com `window.SOLO2 === m`, e 2 toques entravam no 2D isolado.
- **Correção:**
  - `window.rgDir(m)`: torre por vãos escolhida no projeto (sem 2D isolado, sem Planta, sem só-leitura). Liga o painel por vãos, com "✏️ Editar só ele no 2D" no topo, e os vãos tocáveis.
  - No projeto, os retângulos dos vãos ficam num grupo `#mod` do móvel (`data-rgdir`): o arrasto de 1 dedo move o móvel, e o toque sem arrastar escolhe o vão.
  - 2 toques no vão abrem o menu do vão (`#rgqk`), sem entrar no 2D isolado.
- **Tentativa descartada (`e4992a8`, revertida em `e39e655`):** converter sozinha toda torre comum ao ser tocada.
  - A bateria deu 359/373, com 14 falhas: o editor normal das torres (torre por dentro, abas, modelos reais) mudava, e só olhar o 2D isolado passou a mudar 32 modelos.
  - **Torre comum continua com o editor de hoje** e só vira por vãos pelo 2D isolado, como antes.
- **Risco identificado (já existia, não mexido):** a conversão pro editor por vãos (`rgFrom`/`rgInit`) muda peças em 27 modelos do catálogo, entre eles guarda-roupas, cantos retos e torres da sala (medido em 18/11). Acontece ao editar esses modelos no 2D isolado. Fica pra decisão do Adauto.
- **Testes:**
  - `testTorreTocadaNoProjetoMostraPainelPorVaosSemIrPro2DIsolado`: painel, vão tocável, botão do 2D isolado, corte e gravação iguais, sem passo no desfazer, vão rosa, menu de 2 toques, arrasto move, sair igual, balcão normal, torre comum sem conversão. Falha em `635299a` e passa na correção.
  - `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho`: o roteiro passou a refazer o painel ao escolher o módulo (como o toque). Passa antes e depois.
- **Commits:** ramo `claude/arquemestre-torre-direto`.
  - Testes: `b58b769`, `40d987e`, `d6b9aed`.
  - Correção: `e4992a8` e `e39e655`.

## PORTA-CAVA — porta cava na aba Portas das torres (pedido do Adauto, 18/11, foto do iPad)
- **Pedido:** "Adicionar portas cava aqui também", na aba Portas do editor por vãos (torre 780 × 2600 × 560).
- **Situação:** as portas do vão (`n.p`) já eram calculadas com a cava do móvel (`m.v[0].cava`: `doorBox` com cava, nota "cava usinada a 30°", sem marca de puxador). A torre já herdava a cava do módulo original ao virar "por vãos". Faltava só a opção na tela.
- **Correção:** "Porta cava" (`data-rgc="dcava"`) na aba Portas, que liga e desliga `m.v[0].cava`.
  - Vale pra todas as portas e frentes do móvel, porque a conta é por móvel.
  - Não aparece em basculante, vidro ou tampa cega.
  - Com gola marcada, a gola vale; a conta já fazia assim.
- **Teste:** `testPortaCavaNaAbaPortasDoEditorPorVaos`, cobrindo ligar, plano de corte, salvar e reabrir, desligar, basculante e vidro. Falha antes e passa depois.
- **Risco anotado:** escolher o puxador "cava" pro projeto todo (Ajustes) não chega nas torres por vãos, porque a regra da linha 1764 só olha vãos `door`, `drawers`, `tempero` e `free`; a torre é `rt`. Fica pra decisão do Adauto se deve chegar.

## MENU-ARRASTA — menu rápido do vão arrasta pro lado e minimiza (pedido do Adauto, 18/11, foto do iPad)
- **Pedido:** "Opção de arrastar pro lado ou minimizar para não atrapalhar a visão", no quadro "Vão escolhido" (`#rgqk`, menu de 2 toques do editor por vãos, PEDIDO 62) que cobre o desenho.
- **Correção (no código do próprio menu):**
  - Faixa do título com ⠿: segurar e arrastar move o quadro, sempre dentro da tela. O lugar fica guardado enquanto o app está aberto, e o menu abre ali da próxima vez.
  - `▁` minimiza (fica só a faixa) e `▢ abrir` mostra tudo de novo. Ao abrir de novo com 2 toques, abre inteiro.
- **Componente compartilhado:** o minimizar dos outros 9 quadros (`IDS` da linha "▁ minimizar: todo quadro…") não foi modificado, pela regra do Adauto. O menu usa o mesmo jeito (`▁` / `▢ abrir`).
- **Teste:** `testMenuRapidoDoVaoArrastaPraLadoEMinimiza`, em 1366×768 e 390×844.
  - Confere: arrasta junto com o dedo, fica dentro da tela, não fecha, não mexe no móvel; minimiza; abre de novo; reabre inteiro no lugar escolhido; as abas continuam funcionando.
  - Falha antes e passa depois.
  - O `testEditorPorVaosDoisToquesNoVaoAbreMenuRapido…` continua passando.
- **Achado na bateria do Windows (51–53), corrigido:** com o quadro arrastado até embaixo, o `▢ abrir` e o abrir de novo com 2 toques punham o quadro inteiro em lugares diferentes (8 px).
  - **Causa:** um usava 8 px de margem da borda de baixo e o outro 0.
  - **Correção:** a mesma regra nos dois.
  - **Teste:** cenário "arrastado até embaixo" (antes 306 × 314, depois igual).
  - **Validação:** Windows 54 com 366/366 e local com 366/366.
- **CI:** a bateria do Windows ganhou o filtro opcional `so` no disparo manual, pra investigar um teste sem rodar os 366.

## N07/N10 — etapa do iPhone/iPad vermelha sem nenhuma conferência falhar (CI 613–626) · causa achada em 18/11
- **Sintoma:** o app de teste "caía" no começo da bateria do editor e o xcodebuild repetia e passava, mas marcava a etapa como falha.
  - Na 618 caiu duas vezes e o resto não contou (só 181 testes, N10).
  - O `SubscriptionTests.test05` não tinha nada a ver: passou 10/10 na 621.
- **Como achei:** a CI passou a guardar o resumo do xcresult no `ci/ios-resultados` (6725aa4). Na 626 ele disse: "Test exceeded execution time allowance of 2 minutes" em `testAbrirPortasEGavetasFuncionaEmTodoJeitoDeModuloDoCatalogo`.
- **Causa:** esse teste abre e fecha um módulo de cada jeito de abrir do catálogo, com esperas fixas da animação. Levava 113 s no Chromium, e o limite do iOS é 120 s por teste (`-default-test-execution-time-allowance 120`). No simulador carregado passava do limite, o sistema derrubava o app de teste e a queda aparecia no teste seguinte (`testArmarioDeCanto…`).
- **Correção:** o teste foi dividido em 2 partes, com as mesmas conferências e os mesmos itens (54 s e 61 s). Nada foi afrouxado.
- **Risco anotado:** outros testes de varrer o catálogo estão entre 91 e 94 s. Um deles (`testNadaDeEnfeiteTelaPrincipal3D…`) caiu na 618. Dividir do mesmo jeito se algum passar de 100 s ou cair de novo.

## SEM-AVISO-ERRO — tirar o aviso de erro de código que abria sozinho (pedido do Adauto, 18/11)
- **Pedido:** "Remova também o texto de aviso"; na pergunta, ele respondeu "Aviso sobre erro de códigos no app". É o quadro amarelo com "Copiar diagnóstico" que aparece numa das fotos dele.
- **O que abria sozinho:**
  - o quadro do PEDIDO 45, com "⚠ 3D: N módulo(s) sem aparecer" ou "🔄 3D refeito…" e "Copiar diagnóstico";
  - o mesmo quadro quando o desenho do 3D falhava;
  - o aviso "⚠ 3D: erro no … · mande um print desse aviso".
- **Mudança:**
  - nada disso abre mais sozinho;
  - o 3D continua se refazendo sozinho quando um módulo não aparece;
  - o erro continua guardado (`ERR3`, `__diag3Antes`);
  - o diagnóstico continua no botão 🔎 do menu, quando a pessoa pede.
- **Testes:** `testModuloQueNaoApareceNo3DViraAvisoERefazSozinho` e `testErroNoMontarUmModuloNo3D…`, com as expectativas atualizadas por este pedido. Falham antes e passam depois. O diagnóstico manual foi conferido.

## PAREDE-ESPELHADA (N20) — em andamento (18/11), branch `claude/arquemestre-parede-espelhada`, NÃO integrar
- **Defeito comprovado** (`testParedeDaEsquerdaNaoFicaEspelhadaNo2DNemNo3D`, falha antes):
  - na parede da esquerda, o 3D põe o lado "esquerdo" do móvel (tamponamento, dobradiça, ordem dos vãos) à direita de quem olha a parede;
  - o 2D mostra o canto do fundo à esquerda da tela.
  - Fundo e direita estão certos.
  - O espelhamento é só de projeção: os dados guardam x a partir do canto do fundo, e peças e corte estão certos.
- **Feito no commit em andamento:**
  - 3D: em `wingX`, o móvel da parede esquerda é espelhado por dentro em volta do meio dele (ocupa o mesmo trecho). O teste novo confirma.
  - 2D: `wvFlipE` inverte o x na tela (inclusive a cuba e o cooktop da pedra), e `extOf` e a linha do canto usam o lado direito do móvel na esquerda.
- **Quebrou 4 testes aprovados** (passam na base): `testPedraEmQualquerParede…`, `testModulosDeParedesDiferentesEncostam…`, `testCantoEmLProfundidade…`, `testEspacadorDeCanto…`.
  - **Causa:** com o x invertido na tela, as regras que contam a partir do canto passaram a contar a partir da frente: onde o módulo novo nasce, onde a pedra nova nasce, profundidade do canto em L, espaçador do canto e encosto no canto. Os módulos criados no teste ficaram em outra posição nos dados.
- **Próximo passo (escolher um):**
  - **(a) recomendado:** manter toda a conta da parede esquerda em "a partir do canto", como era, e inverter só o desenho e o toque. Isso exige espelhar a posição de cada grupo do desenho (sem espelhar o móvel por dentro nem os textos) e o x do toque/arrasto.
  - **(b):** manter o x invertido e inverter junto cada regra que conta a partir do canto.
- **Depois:** rodar a bateria inteira, conferir projeto antigo da parede esquerda (o tamponamento/dobradiça "esquerdo" passa a aparecer do lado da frente da sala no 3D; peças e corte iguais) e mostrar imagens das 3 paredes.

## B24 — mudar medida e voltar não devolvia o móvel igual (corrigido 20/11)
- **Módulo:** rack (folga) e qualquer módulo empurrado ao mudar largura, altura, profundidade ou base; família: todos (inferiores, superiores, torres, guarda-roupas, demais).
- **Reproduzir:** rack com espessura +3 e voltar; módulo 3 da cozinha demo com largura +100 e voltar. A folga do rack e o `x` não voltavam.
- **Causa raiz:** (1) a regra do rack subia a folga até a espessura e não lembrava a folga anterior (catraca); (2) ao aumentar uma medida o módulo era empurrado pra caber e, voltando a medida, ficava no lugar empurrado.
- **Correção (`editor.html`):** a folga do rack guarda a original (`_fgR`/`_fgR0`) e volta quando a espessura volta. Um invólucro de `setv` guarda o `x` de antes do empurrão (WeakMap), mas só nas mudanças de w, h, d e b. Ele devolve esse `x` só quando o lugar está livre e os outros módulos não mudaram. Não altera nenhuma medida.
- **Testes:** `testMudarMedidaEVoltarDeixaOMovelExatamenteComoEra` (catálogo inteiro + demo; comparação sem depender da ordem das chaves). Falhou antes (d43552c/83f7714), passa depois (470e4de).

## B22/B23 — móvel novo do catálogo encolhia sozinho ou entrava por cima (corrigido 20/11)
- **Decisão do Adauto (20/11):** "não redimensionar móveis existentes nem encolher automaticamente móveis novos. Avisar quando não houver espaço e solicitar decisão do usuário".
- **Módulo:** colocação de móvel novo do catálogo (`fitNew`/`newTpl`); todas as famílias que entram pelo catálogo.
- **Reproduzir:** parede cheia, sobrando 1310 mm, e pôr um balcão de 1600. Ele entrava encolhido, ou por cima dos vizinhos.
- **Causa raiz:** `fitNew` tinha tentativas que encolhiam o módulo (85% / mínimo) e aceitava a última tentativa mesmo sem caber.
- **Correção:** as tentativas que encolhem só rodam com `window.FITENCOLHE`, que fica ligado apenas quando a pessoa escolhe. Se não couber, o móvel novo não fica. O app mostra "Usar N mm" (o maior espaço livre, simulado sem mexer em ninguém) e "Não colocar". Os móveis existentes não mudam.
- **Testes:** `testMovelNovoNaoEncolheSozinhoNemEntraPorCimaEPerguntaQuandoNaoCabe` (pergunta "Usar 1310 mm / Não colocar", entra com 1310 só depois de escolher, com espaço livre entra 1600 sem pergunta). Falhou antes (488ed65), passa depois (fb972ec). Bateria completa: 364 passaram direto e 18 falharam só pela pergunta nova; com o jeito antigo os 18 passam. Esses 18 usam a colocação só como preparação e passaram a fazer como quem escolhe "Usar N mm" (0e3143e). Resultado: 382/382.

## ETAPA B — móvel livre no meio da sala (implementado 20/11)
- **Pedido:** "móvel livre, com posicionamento independente das paredes e rotação de 0°, 90°, 180° e 270°", na Planta 2D e no 3D, com seleção, movimentação, salvamento e reabertura; arquitetura pronta pra outros ângulos.
- **Representação:** `m.wing='L'`, `m.lx`/`m.lz` (canto de trás-esquerdo no chão, mm) e `m.rot` em graus (`ang(m)`). As peças continuam vindo de `partsOf(m)` e não mudam. Só o 3D gira e posiciona as caixas (`lvX`, depois do `DRM`). Na Planta aparece a pegada com uma linha vermelha na frente; o móvel some das vistas de parede.
- **Defeitos achados e corrigidos durante a etapa (causa → correção):**
  1. Tamponamento do livre desligava ao mudar a parede ou o pé-direito. `autoTamp` é local e o invólucro global não pegava → o livre fica de fora do laço do `autoTamp`, como canto, nicho, TV e travado. O tamponamento dele é só manual.
  2. Fita da frente (0,8 mm) ficava sempre em z1, atrás depois de 180° → passa a ir na face que ficou de frente (`lvFt`).
  3. A divisão do tamponamento de 30 em face de 15 + réguas de 80 era feita no mundo. Depois de 180° a face de fora ia pra dentro e a régua "#1 frente" ficava atrás, e apagar a régua da frente apagaria a de trás → o livre divide no próprio referencial (`lvLoc`) e volta pro mundo.
  4. A colisão e o ímã usavam só o corpo (sem portas e tamponamento, que saem 31 mm). Dois livres de frente podiam entrar um no outro → passam a usar o sólido real do 3D (`real(m)`).
- **Regras mantidas:** base e rodapé corridos entre balcões vizinhos na parede (o livre sai da corrida e volta a ter as próprias peças); nada muda sozinho nos outros móveis.
- **Limitações (risco registrado):** as tiras finas do cava (1×3 mm) não aparecem no 3D fora da parede do fundo. Já era assim nas paredes do lado; é só visual, e o corte está certo.
- **Testes:** `testMovelLivreNoMeioDaSalaGiraArrastaSalvaENaoMexeEmNinguem`. Confere:
  - botão "Livre (no meio da sala)";
  - peças iguais ao passar pra livre;
  - 3D com as mesmas peças;
  - fora da vista da parede;
  - 180° com o 3D no espelho exato e a régua da frente na frente;
  - 270° com a pegada girada;
  - Planta: aparece, arrasta 300 mm, bloqueia ao bater;
  - dois balcões de costas encostados pelo ímã (folga 0);
  - parede e pé-direito não mexem no livre;
  - salvar e reabrir iguais;
  - 0 erros.

  Falhou antes (0909fe9, `lvIs` não existe), passa depois. Bateria completa com a Etapa B: 383/383 (365 direto + os 18 do B22 com a preparação "Usar N mm").
## B22/B23 · iOS — `testTudoNoEditorSemErro` com 10 armários no quarto (21/11)
- **Onde:** `ios/ArquemestreTests/EditorAppPathTests.swift` (abre o editor pelo caminho do app). O executor local não roda esse arquivo, então a falha só apareceu no iOS CI 44844711866 (gavetas-paredes bd26713) e 44844714225 (vaos-balcao 262a9b7). Falhou no iPhone e no iPad, nas duas tentativas.
- **Causa comprovada (mesma da B22):** o teste enche o quarto com 40 itens do catálogo.
  - Antes da B22 (e655aa9^): entravam 40.
  - Agora: 10 entram direto e 30 abrem a pergunta "Não tem espaço livre… Usar N mm". Nenhum some sem pergunta, e "Usar" coloca com a medida do espaço livre.
  - Com `FITENCOLHE=1`: 40 de novo, 0 erros.
- **Ajuste:** só a preparação, igual aos 18 testes (commit do teste). A expectativa (>=20) continua a mesma.
- **Outra falha no mesmo CI, que não é erro:** `testEditorAbreComoNoAppSemTelaBranca` levou 32,9 s para abrir no iPad (limite 20 s) e passou na repetição. É lentidão do simulador e o teste não mudou.
- **Também não é erro:** `testMaoDeObra…` (N15) falhou uma vez no iPhone e passou na repetição, como já registrado.

## R-CANTO — pôr "Canto L guarda-roupa" empurra os armários da parede (erro comprovado, anterior; **corrigido 21/11**)
- **Reproduzir:** quarto vazio, 3 armários (x = 35, 335, 935), depois "Canto L guarda-roupa · esquerdo". Os 3 vão para x = 1060, 1360, 1960 (+1025 mm) e o canto fica em x = 0. Com a parede cheia, a fileira inteira troca de ordem (espelho). O "· direito" desfaz.
- **Não foi causado pela B22 nem pela Etapa B:** o resultado é igual em e655aa9^ (antes da B22) e na versão atual.
- **Conflito:** a regra de 16/11 diz "o app nunca altera sozinho medida ou posição de fabricação".
- **Situação em 20/11:** não corrigido, aguardando decisão.
- **Decisão do Adauto (21/11):** "O módulo Canto L nunca poderá empurrar, deslocar, inverter, redimensionar ou reorganizar móveis existentes automaticamente." Sem espaço: "Usar espaço disponível" ou "Não colocar"; a primeira só se o canto adaptado continuar válido; sem espaço pra um canto válido, não coloca e explica.
- **Causa raiz:** `cornerPack` (chamado só ao criar o canto: catálogo `newTpl` e botão da Planta `mkCorner`) encostava a fileira do lado do canto mudando o `x` dos vizinhos. `mkCorner` e o botão "Módulo de canto" do painel também empurravam os módulos da parede lateral pra depois do canto. Com a parede cheia, os empurrões seguidos invertiam a ordem.
- **Família investigada:** inferiores (canto de base pelo botão da Planta e do painel), superiores (canto aéreo esquerdo/direito), guarda-roupas (canto L esquerdo/direito). Torres e demais não têm canto L.
- **Correção (`editor.html`):** `cornerPack` não mexe em ninguém (devolve 0). `cnChk` mede sem mexer o espaço até o 1º vizinho da mesma altura (com a folga da parede de `limX`) e o lado. Os 3 caminhos passam por ela.
  - Cabe: entra com a medida do catálogo.
  - Não cabe mas o canto adaptado é válido: pergunta "Usar espaço disponível (N mm)" / "Não colocar".
  - Sem espaço pra canto válido, ou já tem canto daquele lado: explica o mínimo e não coloca.
  - "Não colocar" deixa o projeto igual (inclusive o desfazer).
  - Canto válido (regra que a construção já usa no lado: W2 = máx(prof. + 200, cw2); espelhada no fundo): fundo ≥ prof. do lado + 200; lado ≥ prof. + 200. **A confirmar pelo Adauto** (`DECISOES_TECNICAS.md`).
  - Tamponamento AUTOMÁTICO da ponta da fileira virado pro canto: sai quando o canto encosta (regra que já existe pra qualquer módulo que encosta). Então "usar o espaço" vai até o corpo do vizinho e tira esse tamponamento antes, pra não deixar vão. Sem isso, outra regra levava o canto pra outro vão. Tamponamento escolhido pela pessoa conta sempre.
- **Testes:** `testCantoLNuncaEmpurraOsMoveisPerguntaOuImpedeEmParedeVaziaParcialECheia`.
  - Paredes vazia, com espaço, com espaço curto, cheia e lateral ocupada; base, aéreo e guarda-roupa, esquerdo e direito; catálogo, Planta e painel.
  - Confere: ninguém muda; sem sobrepor; peças iguais às do canto da mesma medida na parede vazia; salvar e reabrir.
  - Falha antes (7e0c5b1) e passa depois (7d0476b).
- **Testes que mudaram por esta decisão:** `testCantoEncostaPlantaEmAnguloComPedraECooktopPorCimaDo3D` e `testListaDeMoveisNoOrcamento` punham o canto onde já tinha módulo e contavam com o empurrão. Agora a preparação deixa o lugar livre; as conferências continuam (9aa2afd).
- **Projetos salvos:** não mudam (`cornerPack` só rodava ao criar o canto).

## CAVA NO LIVRE — linha fina do cava sumia fora da parede do fundo (pedido do Adauto 21/11; corrigido)
- **Pedido:** "Corrigir as faixas da cava no móvel livre em todas as orientações."
- **Reproduzir:** balcão de 2 portas com cava. Na parede do fundo saem 75 caixas finas; na parede do lado e no livre (0/90/180/270) saem 73. Faltam as 2 linhas de sombra do cava (0,6 × 3 mm na frente de cada porta).
- **Causa raiz:** a passada do fim (`build_cava`) achava a porta pelo perfil `b.poly`. Fora da parede do fundo, o giro (`lvX` no livre, `wingX` nas paredes do lado) já tinha trocado `poly` por `pf`, e a linha não saía. O chanfro continuava certo; só a linha faltava.
- **Correção:**
  - A conta da linha virou `cvLinha(b)`.
  - Fora da parede do fundo ela roda no referencial do módulo antes do giro (`cavaLin`, chamado no DRM), e o giro leva a linha junto.
  - Parede do fundo: 3D idêntico (cozinha demo com cava: 566 caixas, mesmo hash). Peças e corte não mudam.
  - Paredes do lado: mesmo defeito, mesma família, corrigido no componente compartilhado.
- **Teste:** `testCavaDoMovelLivreTemALinhaNasQuatroPosicoesENasParedesDoLado`.
  - Cada linha no livre e nas paredes do lado é a da parede do fundo levada pela conta do giro (1 mm), no balcão e no gaveteiro.
  - Falha antes (0/2 e 0/3) e passa depois (cfcbdb0 → b5594a5).

## ETAPA C — segurar o móvel 2 s abre o menu de edição (pedido do Adauto 21/11; implementado)
- **Decisão do Adauto (21/11, perguntas):** abre o mesmo menu dos toques; mouse só segurando o botão esquerdo.
- **Implementação:** bloco próprio no fim do `editor.html`, na captura da janela. A conta do vão dos 2 toques virou `vaoNoPonto` (mesma conta). `__modAt3` expõe o `modAt` do 3D. Ver `GESTOS_CONTROLES.md`.
- **Defeitos achados no caminho e corrigidos antes de fechar:**
  1. Na Planta o segurar não armava quando outro tratador redesenhava a planta no mesmo toque: o alvo do toque saía da página. Agora vale o elemento que está no ponto.
  2. No 3D, soltar depois do menu contava como 1 toque (o canvas não olha o tempo) e abria a porta embaixo do dedo. Agora o soltar vira cancelado pro 2D/3D.
  3. O clique que o navegador manda logo depois de soltar caía num botão do menu (o menu abre perto do dedo) e mudava o vão. Agora esse clique não chega. Provado: sem o bloqueio, o teste mostra "vão mudou".
- **Teste:** `testSegurarOMovel2SegundosAbreOMenuSemMexerEPreservaToqueEArrasto`.
  - 2D com inferior, gaveteiro, aéreo, torre e guarda-roupa; Planta; 3D.
  - Confere: dedo tremendo; soltar; clique depois; segurar pouco; arrastar; 2 toques; 2 dedos; mouse esquerdo e direito; 1 e 3 toques do 3D.
  - Falha antes (7e0c5b1: segurar não abre nada) e passa depois.
- **Registro:** o `GESTOS_CONTROLES.md` dizia "1 toque no módulo abre o quadro" no 3D. No código, 1 toque escolhe e 3 toques abrem. Corrigido no inventário.

## PROJETO-SEM-SHV — projeto antigo/mínimo sem a lista de prateleiras soltas não abria (achado 21/11; corrigido)
- **Como achei:** simulando o teste de atualização (abrir os projetos do backup de referência no editor).
- **Reproduzir:** `loadState` de um módulo `{id,x,w,h,d,b,div,v}` sem `shv`. O `partsOf` dá `TypeError ... reading 'forEach'` e o projeto não abre. Igual na 7e0c5b1.
- **Causa raiz:** `defs` (o que completa os campos de projeto antigo ao abrir) não tinha a lista `shv`, e o resto do código conta com ela. A 3.0.12 sempre grava `shv`, então afeta projeto mínimo ou antigo.
- **Correção:** `defs` completa `shv`, `div` e `v` vazios quando faltam. Lista vazia é o que o campo ausente significa. Medidas e arquivo salvo não mudam.
- **Teste:** `testProjetoAntigoSemPrateleirasSoltasAbreComAsMesmasMedidasEGeraPecas`. Falha antes e passa depois (50344d7 → 8f644d4).

## BACKUP-REF — notas do backup de referência em formato que nenhum app abre (achado 21/11; corrigido no gerador)
- `tools/gerar_backup_referencia.py` (N06, 17/11) gravava a medida da nota como `x1/y1/value` e a foto sem `cx/cy/w/h`. Android (`Json.kt`) e iOS (`JsonCodec.swift`) exigem `a`, `b`, `color`, `width` e `cx`, `cy`, `w`, `h`. Servia só pra conferir arquivos por hash.
- Agora grava no formato real, com os mesmos ids, nomes, fotos e vínculo. ZIP e manifesto foram gerados juntos (31b761c). Os testes de restauração e atualização das 3 plataformas comparam com o manifesto, então seguem valendo.

## ATUALIZACAO-IOS-ABRE — teste de atualização do iOS abre os projetos no editor (pedido do Adauto 21/11)
- `AtualizacaoAbreProjetosTests` (só com `ARQ_ATUALIZACAO=1`): depois de instalar por cima da 3.0.12, abre o editor como o app, lendo os arquivos que ficaram, e abre cada projeto pelo `arqueOpenClient`. Confere:
  - medidas e posições iguais às salvas;
  - peças e corte em todo módulo, sem erro;
  - foto da galeria de volta;
  - notas abertas pelo `Store` com as medidas e a foto.
- Nada é gravado no aparelho. O script confere os arquivos de novo depois (passo 6) (0e25f29).
- Simulado antes no Chromium com a ponte do app e o backup de referência: p1 com 2 módulos e p2 com 1, medidas iguais, 13 peças e 7 linhas de corte por módulo, 1 foto do p1, só `prices.json` gravado ao abrir.

## N15 / animação — falhas intermitentes do iOS (investigação 21/11)
- **testMaoDeObra…:** a falha do CI (linha 8973) é `janelaNaoDesceNoMeioDoToque`, não o `botaoPega`.
  - Hipótese: a janela ainda está subindo com o teclado. A animação dura 0,15 s e há reajustes em 60…1200 ms depois de abrir o campo; o teste mede 90 ms depois. Não comprovada: só acontece no simulador do iOS.
  - O teste agora mostra y antes/depois, transform e ms desde que o campo abriu. Nenhuma espera foi acrescentada, pra não esconder defeito real: no iOS, tocar num botão não tira o foco do campo, e um reajuste atrasado mexeria a janela debaixo do dedo.
- **testAbrirPortasEGavetas… parte 1:** gaveta que não abriu e porta que não fechou depois da espera de até 10 s pela animação; passa na repetição.
  - Hipótese: o simulador segura os quadros de animação quando está carregado.
  - O teste agora diz se a espera esgotou e se a animação andou ou ficou parada.
- As conferências são as mesmas (49aca08). Classificação: **não foi possível verificar** até o próximo CI do iOS trazer o detalhe.

## Ferramenta da bateria local — editor velho do cache (21/11)
- O Chrome da bateria local tem perfil fixo e às vezes servia o `editor.html` antigo do cache: um teste falhava com o código já corrigido.
- A partir daqui as rodadas locais usam endereço único (`?v=...`). As provas de "falha antes" usaram a porta 8836 (editor fixo da 7e0c5b1), sem esse problema. O CI do Windows abre um navegador novo e não é afetado.

## ETAPA C · MENU DO 3D — segurar 2 s no 3D abre menu de 8 opções (pedido do Adauto 21/11; implementado)
- **Pedido:** girar 90°/−90°/180°, tirar da parede, vincular à parede, mover livremente, editar medidas e excluir com confirmação. Módulo destacado, ninguém mais muda, sem sobrepor (com alternativa), salva sozinho, sem sistema novo de movimento.
- **Decisões do Adauto (perguntas de 21/11):** girar só no móvel livre (no de parede fica apagado com "Tire da parede para girar"); 2D e Planta seguem com o menu do vão.
- **Reuso (nada novo de geometria):**

  | Opção | Função usada |
  |---|---|
  | Girar | `lvGira` (em volta do centro, `bate`/`imanta`) |
  | Tirar da parede | `lvSolta` |
  | Vincular | o tratador dos botões "Em qual parede" do painel (`modHit`/`modSlide`) |
  | Mover | a Planta (arrasto com as regras de colisão) |
  | Medidas | `mz3Open` |
  | Excluir | `delMod` com `LAST='mod'`, como no quadro do 3D |

- **Destaque:** caixa azul translúcida sem nome de peça e com `nol`. Não é pega pelo `pickFace`/`tap3`, não entra em `solidos`, lista nem corte. Hook `build_lp3` dentro do 3D, ao lado do `__size3`.
- **Mudança de expectativa (pedido de 21/11):** `testSegurarOMovel2…` esperava o quadro dos 3 toques no 3D; agora espera o menu. Os 3 toques continuam abrindo o quadro (o mesmo teste confere).
- **Teste:** `testMenuDoSegurarNo3DGiraTiraVinculaMoveMedeExcluiSemMexerEmNinguem`.
  - O catálogo inteiro abre o menu com destaque, e nada muda.
  - Segurar de verdade em 9 tipos (balcão, gaveteiro, geladeira, canto L aéreo e de guarda-roupa, torre, aéreo, guarda-roupa, rack, livre).
  - Ações:
    - girar: centro no lugar; medidas, peças e corte iguais; vizinho igual;
    - girar que bateria: não gira e oferece mover;
    - vincular: sem sobrepor;
    - medidas e mover;
    - excluir: só confirmando; o travado não sai;
    - salva sozinho.
  - Falha antes (`lp3Open` não existe) e passa depois (5566d98 → 60b4b4f).
- **Detalhe do teste:** a comparação dos vizinhos ignora a ordem das chaves do JSON (como no da B24). Uma regra tira e põe de volta o mesmo campo com o mesmo valor; campo por campo, nada muda.

## DEMO-B22 — cozinha de exemplo das capturas com 6 módulos e a pergunta aberta (achado 21/11; corrigido)
- **Como achei:** na captura do menu do 3D, a pergunta "Não tem espaço livre" aparecia atrás do menu.
- **Reproduzir:** `demoScene()` (usada por `?demo3d=1`, `demoCores`, `demoCorte`, `demo2D`, pelas capturas da loja e por vários testes).
  - Antes da B22: 9 módulos (900, 1200, 600, 860, 860, 800 e 3 aéreos de 1000).
  - Desde a B22 (já na 7e0c5b1): 6 módulos e a pergunta aberta.
- **Causa raiz:** o exemplo contava com o encolher automático dos balcões da lateral (900 → 860/860/800), que a B22 tirou.
- **Correção:** `demoScene` monta o exemplo com `FITENCOLHE` ligado só durante a montagem, como quem escolhe "Usar N mm", e volta o valor de antes. `demoSala`, `demoCloset` e `demoLed` não mudaram. A B22 continua pra quem põe móvel.
- **Teste:** `testCenaDeExemploDasCapturasIgualAntesDaB22SemPergunta`. Falha antes e passa depois (165c82e → fb8b789).
- **Efeito nos testes:** os testes que usam a cozinha de exemplo voltam a ver os 9 módulos de antes da B22, que é o que tinham sido escritos pra ver.

## ETAPA C2 — Mover no 3D com encaixe magnético (pedido do Adauto 21/11; ramo `claude/arquemestre-etapa-c-arraste3d`, separado da homologação)
- **Auditoria antes de fazer:**
  - Arrasto do 3D (`MDRG`): move o módulo de parede ao longo dela e na altura, com `mvSnap`, `stoneLim` e colisão. No móvel livre não funcionava (mexe no `x` da parede).
  - O livre só andava na Planta (`lvTenta`: `bate` + `imanta`). O `imanta` puxava pras paredes da sala a 25 mm.
  - Pedra: corpo = pedra − 40 (`dSobPedra`) ao criar.
  - Achado: no 3D, o móvel da parede **esquerda** é guardado espelhado. Medido: livre de costas pra ela tem a porta à esquerda; como módulo da esquerda, à direita. É a decisão de 18/11 (manter físico, corrigir nomes).
- **Decisões do Adauto (perguntas de 21/11):**
  - encaixa só de costas pra parede (nada gira sozinho);
  - só a pedra da parede;
  - puxado mais de 20 mm sai da parede;
  - ímã liga/desliga nos Ajustes, guardado;
  - parede esquerda: só fundo e direita encaixam/soltam arrastando; na esquerda continua "Vincular à parede" do menu.
- **Implementação (reuso):**
  - "Mover no 3D" no menu dos 2 s.
  - Livre:
    - anda no chão com `lvTenta` em mm inteiros, sem bater, com ímã entre móveis (no arrasto do 3D o `imanta` não puxa pras paredes: `__lvSemParede`; Planta igual);
    - guia azul a até 20 mm, medida no sólido real do 3D;
    - ao soltar, vira módulo da parede no mesmo lugar e confere colisão no sólido do 3D e com `modOverlaps`. Se bater, volta e diz em quem.
  - Pedra: confere o fundo ≤ pedra − 40 e a altura até a pedra; se não couber, explica e não muda.
  - De parede: o arrasto de sempre; puxado mais de 20 mm pra fora vira livre de costas (`__mdrgStop` para o arrasto de sempre).
  - Canto L: não encaixa arrastando (precisa ficar no canto; R-CANTO).
  - Barra com X/Z (livre) ou "da parede" (`setv('x')`) em mm.
  - Ímã: `PR.ima` (o `LVSNAP` da Etapa B passa a ler dele).
- **Defeito achado no caminho:** a função nova `alvo(m)` tinha o mesmo nome da `alvo(ev)` do segurar 2 s, no mesmo bloco, e tomava o lugar dela: o segurar parou de abrir o menu. Renomeada `paredeAlvo`. Pego pelos testes da Etapa C antes do commit.
- **Teste:** `testMoverNo3DEncaixaNaParedeAte20mmSoDeCostasSemMexerEmNinguem` (19/20/21 mm, orientação, esquerda, colisão, pedra cabe/não cabe, soltar, arrasto real, posição digitada, ímã desligado e guardado, lado a lado, desfazer/refazer, reabrir, tipos). Falha antes (`__mv3` não existe) e passa depois (cd0cb1f → 6b8cbf2).
- **Riscos registrados:**
  - ~~A colisão do livre (`bate`) só olha módulos, não a pedra (já era assim na Etapa B).~~ Resolvido em PEDRA-LIVRE (21/11).
  - No 3D, o módulo de parede ainda anda pelo arrasto de sempre ("segure um instante e arraste").
## FOTO-BANCO-LENTO — foto da galeria do editor sumia quando o banco das fotos abria devagar (achado 21/11 no teste de atualização do iOS; corrigido)
- **Como achei:** `AtualizacaoAbreProjetosTests` (CIs 44906277546, 44909214405, 44910617585). Depois de atualizar por cima da 3.0.12, a foto do `photo_f900.json` não voltava pro editor, nem esperando 10 s.
- **Diagnóstico no iOS (CI 44910617585):** a ponte lista e lê o arquivo (192 bytes, com imagem), o banco abre, e gravar a foto à mão funciona (0 → 1). O defeito era só na volta automática.
- **Causa raiz:** `phDB` espera o IndexedDB 1,5 s e depois usa a memória (`PHMEM`). Quando o banco abre atrasado, ele passa a ser usado, mas o que ficou em `PHMEM` nunca ia pra ele, e `phAll` lia só do banco.
- **Afeta:** fotos da galeria do editor devolvidas do backup ao abrir, e foto tirada nesse intervalo num aparelho lento (o arquivo nativo fica; some da lista naquela sessão).
- **Família:** só as fotos do editor usam `phDB`. Os vídeos (`EditorMediaBackup.js`) passam pelo mesmo `phPut`/`phAll` e ficam cobertos pela correção.
- **Correção:** ao abrir atrasado, copia `PHMEM` pro banco; até terminar, `phAll` junta banco e memória sem repetir. Nada é apagado.
- **Teste:** `testFotoGuardadaComOBancoDasFotosLentoNaoSomeDaLista` (banco real abrindo em 2,2 s). Falha antes e passa depois. Os 5 testes de foto passam.

## PEDRA-LIVRE — móvel livre atravessava a pedra e passava do recuo de 40 mm (pedido do Adauto 21/11; corrigido)
- **Pedido:** "corrija o movimento do módulo livre para respeitar a pedra, os móveis existentes e o recuo de 40 mm, sem alterar medidas ou posições de outros módulos".
- **Como reproduzir (antes):** pedra 2400 × 606 a 820 mm; livre de 900 mm de altura arrastado pra baixo dela → entrava na pedra. Livre de 820 mm com o corpo indo até 570 ou 590 mm → passava do recuo (limite 606 − 40 = 566).
- **Módulo:** bloco ETAPA B (`lvTenta`, `lvSolta`), usado pela Planta, pelo arrasto do 3D, pelas caixas X/Z do Mover no 3D e pelo girar.
- **Causa raiz:** `bate` só olhava as caixas dos módulos (`nm` `índice:peça`); a pedra (`sid`, sem `nm`) ficava de fora. O recuo só era conferido no encaixe na parede (`pedra(m,s)` da C2), não no movimento livre.
- **Correção:** `porque(m)` = outro móvel → parede → pedra. Pedra: a placa e a cuba do 3D são sólidas (altura); embaixo da placa o corpo (`lvFoot`) fica até a frente − 40 (a mesma regra do encaixe), com a frente do lado da sala (fundo → z; perna do L → x). Bloqueia e mostra o motivo (`__lvMotivo`) no toast da Planta, na barra do Mover no 3D e no girar. Só confere: nenhum móvel, pedra ou medida muda.
- **Família:** módulo de parede embaixo da pedra já tinha `stoneLim`/`stLimX` (não mudou). Superior acima da pedra: não conta (fica em cima). Ilha sem parede: só a colisão, sem recuo.
- **Teste:** `testMovelLivreNaoEntraNaPedraERespeitaORecuoDe40mm` (fora, rente, 30 mm, 566/570 mm sem ímã, 900 mm de altura, girado 90°, caixa Z, outro módulo/peças/corte/pedra iguais). Falha antes e passa depois; 39 testes de pedra e de livre passam.
- **Commits:** `0893a57` (teste), `7d5acdf` (correção).

## LIVRE-PAREDE — girar o livre levava as costas pra dentro da parede (achado na revisão do arraste, 21/11; corrigido)
- **Como reproduzir (antes):** livre de 900 mm encostado na parede do fundo, girar 90° → gira em volta do meio e fica com as costas 185 mm dentro da parede. Arrastar sem ímã também passava das paredes.
- **Causa raiz:** nenhuma conferência de parede no movimento livre (só o ímã puxava pra ela).
- **Correção:** `naParede(m)`: parede do fundo e paredes do lado (quando existem, `sideWalls`) são sólidas. No ambiente livre (sem paredes) não há limite. Giro bloqueado fica como estava e diz o motivo.
- **Teste:** `testMovelLivreNaoEntraNaParedeAoArrastarOuGirar`. Falha antes e passa depois.
- **Projeto antigo:** nada é conferido ao abrir; um livre que já estava dentro da parede ou da pedra continua igual até a pessoa mover.
- **Commits:** `0893a57` (teste), `7d5acdf` (correção).

## ABERTURA-LENTA — editor levando 25,6 s / 39,4 s / mais de 60 s pra abrir nos testes do iOS (medido 21/11; falta aparelho real)
- **Visto:** `testEditorAbreComoNoAppSemTelaBranca` no iPad do CI (25,6 s na homologação, 39,4 s na C2; limite 20 s) e `testTamponamentoInferiorReconheceACava…` no iPhone (passou de 60 s). Os dois passaram só na repetição automática do CI (`-retry-tests-on-failure`), e o resumo do xcresult mostra "0 failed".
- **Medido aqui (Chromium, mesmo editor.html de 2,9 MB):** 0,3–0,7 s; com a CPU 6× mais lenta, 2,4–3,1 s. O código do editor sozinho não explica 25–60 s.
- **Diagnóstico ligado (`840aa74`):** `ABERTURA-DIAG` mede quando a página começou a rodar e quando o DOM ficou pronto. O CI agora lista como aviso todo teste que só passou na repetição (pedido do Adauto 21/11: "não esconda falhas com repetição automática"). O critério dos testes não mudou.
- **Resultado do diagnóstico (iOS CI 44933773950, `840aa74`):** só a **primeira** abertura depois que o simulador liga é lenta. iPhone: página começou em 8,30 s, DOM pronto em 13,99 s (editor sozinho 5,79 s). iPad: 8,12 s / 11,98 s (3,89 s). Da 2ª abertura em diante: página em 0,4–1,3 s, editor sozinho 0,4–0,7 s. Na bateria, um único teste passou de 8 s (9,02 s). Nenhum teste do editor precisou de repetição nessa rodada.
- **Causa provável (risco identificado, não comprovado em aparelho):** os ~8 s antes da página começar são o simulador criando o processo do WebKit a frio; os 4–6 s seguintes são o primeiro parse/compilação do editor.html (2,9 MB) com cache frio. Os 25–60 s eram esse começo a frio com a máquina do CI mais carregada. Não é laço nem travamento no editor (depois de aquecido ele abre em ~1 s).
- **Correção:** nenhuma no app nesta etapa (não há defeito comprovado no código). A repetição automática continua, mas agora todo teste que só passou na repetição aparece como aviso no CI.
- **Pendente:** medir a primeira abertura no iPhone/iPad real pela build de teste do TestFlight. Se lá passar de ~3 s, investigar o tamanho do editor.html (carregamento em partes).
- **Visto também:** `SubscriptionTests.test05_CancelarMantemAcessoAteOFimDoPeriodo` (StoreKit no simulador) falhou na 1ª tentativa por tempo (22,6 s esperando "renovação desligada") e passou na repetição (1,5 s). É o ambiente de teste do StoreKit; o aviso de repetidos ainda não lê esse log.

## TESTFLIGHT-VERSAO — build de teste da C2 recusada pela Apple (22/11)
- **Visto:** iOS CI 44952837633 (`d85c6d8`, `testflight=true`). Os 466 testes passaram, sem nenhuma repetição, e o archive saiu. O `exportArchive` foi recusado pelo App Store Connect com "CFBundleShortVersionString [1.0.0] ... must contain a higher version than ... [3.0.12]", "train version '1.0.0' is closed" e "version 3.0.9 ... a later version has been closed".
- **Causa:** `ios/project.yml` está com `MARKETING_VERSION: "1.0.0"` nesse ramo, e a loja só aceita versão maior que a 3.0.12 publicada.
- **Resultado:** nada chegou ao TestFlight e nada foi pra App Store.
- **Pendente:** o número da versão é decisão do Adauto. A auditoria de 19/11 cita a 3.0.13 como candidata. Não mudei.

## PAREDE-ESQ-NOVO — móvel novo da parede esquerda saía espelhado pra quem olha (pedido do Adauto 22/11: "Resolva o espelhamento da parede esquerda, sem prejudicar as outras paredes"; resposta: "Só móveis novos")
- **Módulo:** todos os módulos de parede na parede esquerda (inferiores, superiores, torres, guarda-roupas e closets, demais). O canto (corner) fica de fora, porque o lado do canto é da parede.
- **Como reproduzir (antes):** colocar "Balcão porta + gavetas" na parede esquerda. No 2D e no 3D as gavetas ficavam à esquerda de quem olha e a porta à direita, o contrário do fundo e da direita. O plano de corte chamava de "esquerdo" o tamponamento que o marceneiro vê à direita. No 3D, a esquerda não encaixava nem soltava arrastando.
- **Causa raiz:** as paredes do lado guardam x a partir do canto. Na esquerda, o canto fica à direita de quem olha, então o lado guardado como esquerdo do móvel aparecia à direita. A decisão de 18/11 ("manter físico, corrigir nomes") trocou só os nomes no painel.
- **Correção (`editor.html`, bloco PAREDE-ESQ-NOVO):**
  - Móvel criado a partir desta versão leva a marca `espN`. Enquanto ele está na parede esquerda, os dados ficam guardados virados (`espE`):
    - tamponamento escolhido ou do modelo (o automático, do lado exposto, é do lugar e não vira);
    - tamponamento de baixo, engrosso, "sem lateral";
    - ordem dos vãos e divisórias (`1 − r`, com o valor original guardado pra voltar exato);
    - árvore de vãos, dobradiça (1 folha, grupo ímpar, camarão, torre), folhas de correr e corrediça do porta-tempero;
    - ajuste por peça (`po`) e peça fora do corte (`xp`), que acham a mesma peça pela posição espelhada.
  - As contas (colisão, pedra, canto, corte) não mudaram: leem um móvel virado.
  - O nome de quem olha só aparece na saída (`cutLines`: plano de corte, lista, orçamento). Dentro do app o nome guardado continua, porque várias contas leem o lado pelo nome.
  - Troca de parede: vira e desvira sozinho, e os dados voltam iguais.
  - Móvel que aparece por outro caminho (duplicar, completar fileira): fica como nasceu (`espE` sem virar).
  - Móvel ANTIGO (sem `espN`): fica exatamente como era. O painel mostra o aviso e o botão manual "Desespelhar", com desfazer.
  - Mover no 3D: encaixa e solta na esquerda só o móvel novo (270°, x = lz − largura).
- **Não muda de propósito:** forno e micro-ondas (eletrodoméstico de verdade). A divisória do pedestal, quando duas divisórias do módulo estão à mesma distância do meio, fica embaixo da primeira (mesma medida e corte).
- **Achado no caminho e corrigido:** na 1ª versão a virada trocava também o tamponamento automático. O `autoTamp` refazia a conta e o `rowJoin` empurrava o móvel 60 mm (rastreado no `testParedeEsquerdaToqueDoisToquesEArrasto…`). Agora o automático fica no lugar.
- **Testes:**
  - `testParedeEsquerdaMovelNovoSemEspelhoAntigoIgualComDesespelhar` confere:
    - catálogo inteiro (587 itens): esquerda = espelho da direita;
    - medidas iguais e nome do lado = lado de quem olha;
    - antigo igual, aviso, Desespelhar, desfazer e tamponamento automático no lugar;
    - salvar e reabrir, ida e volta de parede, `po`/`xp`;
    - encaixar e soltar no 3D;
    - ordem dos vãos no 2D (novo e antigo).
  - Na versão anterior (`e3f34cc`) ele falha: 55 itens espelhados, 2341 nomes de lado errados, sem aviso, sem encaixe e 2D invertido.
  - Adaptados, com comentário do pedido de 22/11: `testMoverNo3D…` e `testParedeEsquerdaNomesDosLados…`. A regra antiga continua conferida num móvel antigo, e entrou a conferência do novo.
- **Projetos:** nenhum projeto salvo muda ao abrir. Projeto salvo nesta versão e aberto numa versão anterior mostra o móvel novo com o mesmo desenho. Só o nome do lado no corte volta a ser o guardado.
- **Pendente:** aparelho real; ordem "Vão 1, Vão 2" no painel do móvel novo da esquerda continua contando a partir do canto.

## PAREDE-ESQ-TEMPO (22/11/2026) · teste longo derrubava a bateria do iOS
- **Módulo:** bateria iOS (`ios/ArquemestreTests/EditorWebKitTests.swift`). O app não foi alterado.
- **Como apareceu:** no iOS CI 649 (`24a91b8`), o teste novo `testParedeEsquerdaMovelNovoSemEspelhoAntigoIgualComDesespelhar` (catálogo inteiro, 587 itens) levou 161 s no iPhone e 136 s no iPad, e o limite é 2 min por teste. O XCTest reiniciou o app de teste logo depois, durante `testPedraDivididaNoFogao`, e a bateria saiu como falha. Esse teste é inocente. No Chrome o teste inteiro levava 40 s.
- **Causa raiz:** o tempo de um único teste passava do limite do XCTest. Evidência: `QUEDAS.txt` no ramo `ci/ios-resultados`.
- **Correção:** o teste foi dividido em 4: o catálogo em 3 terços (`i%3`, mínimo de 167 itens por terço, somando o catálogo inteiro) e o resto num teste próprio. As conferências e as expectativas são as mesmas (commits `8e50530` e `3f1c3a5`). O `8e50530` deixou um fechamento `"""#)` duplicado que quebrou a compilação no CI 650, corrigido no `3f1c3a5`.
- **Validação:** local, 4 de 4 passaram, com cerca de 12 s cada. iOS CI 651: 470 testes (397 do editor), 0 falhas no iPhone e no iPad, nenhum teste repetido, StoreKit OK.
- **Prevenção:** teste que percorre o catálogo inteiro tem que caber em menos de 2 min no simulador. Medir no Chrome e multiplicar por cerca de 4.
## FT-REBAIXO — fita de 0,8 mm do rebaixo da lateral desenhada dentro da travessa frontal no 3D (17/11/2026)
- **Pedido:** Adauto, 17/11: correção cirúrgica só do defeito visual, com teste antes e depois.
- **Causa:** o `build_ft` põe uma tira de 0,8 mm na frente de cada caixa da lateral. A caixa de cima (o rebaixo, z até 551) ganha a tira de 551 a 551,8, dentro da travessa (de 551 a 566). Sobreposição de 15 × 70 × 0,8 mm.
- **Correção:** a tira que cairia dentro de uma Travessa, Travessão ou Frontal do mesmo módulo não é desenhada. Peças, lista e corte iguais aos da versão publicada (assinaturas no teste `testFitaDoRebaixoNaoFicaDentroDaTravessaNo3DEPecasECorteNaoMudam`).
- **Bateria local completa:** 347/349.
  - `testTamponamentoNo2D…` é a falha antiga; a correção dela está na branch do P0.
  - `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` **aguarda decisão do Adauto**:
    - O teste confere pelo **total de caixas** do módulo no 3D. Com a correção há 2 caixas a menos (as tiras escondidas), então "caixas 65 → 64" vira "63 → 62".
    - Ao apagar a travessa, a frente do rebaixo fica descoberta e as 2 tiras voltam a aparecer. O total cai menos do que o teste espera, e ele acusa "saiu da lista e ficou no 3D".
    - Conferido peça a peça: depois de apagar, a travessa sai do 3D (0 caixas) e as duas versões ficam **idênticas** (112 caixas, 5 tiras).
    - **O teste não foi alterado.**

## FT-PORTA — fita de 0,8 mm desenhada dentro da porta/frente fechada no 3D (17/11/2026)
- **Pedido:** Adauto, 17/11: investigar e corrigir cirurgicamente só a representação visual. Separado da branch da travessa e do frontal.
- **Reproduzido** na versão publicada `7c939bc`:
  - a frente do corpo fica em z = profundidade + 6, e a porta/frente fechada começa exatamente ali;
  - a tira de topo (`build_ft`) é desenhada de z1 a z1 + 0,8, ou seja, dentro da folha;
  - as tiras afetadas: 3 no Balcão 2 portas, 4 no Aéreo 2 portas, 6 no Guarda-roupa 3 vãos (laterais, bases, divisórias).
- **Causa:** desenho só. A posição da porta não considera a espessura da fita, e mudar a posição da porta está fora do escopo.
- **Correção (`editor.html`, `ftClipAll`, depois do `build_ft`):**
  - uma passada por desenho, agrupada por módulo;
  - recorta das tiras a parte que fica atrás de uma folha fechada (Porta, Frente ou Basculante, com pelo menos 50 × 50 × 10 mm);
  - a parte que aparece continua;
  - com a porta aberta, a folha sai da frente e a tira volta inteira; ao fechar, o recorte volta.
- **O que não muda:** peças, lista, corte, medidas, posição e movimento das portas. As assinaturas do teste são da versão publicada.
- **Teste novo:** `testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D`. Falha na publicada e passa depois. Confere:
  - 7 módulos, com a área da tira visível idêntica;
  - abrir e fechar pelo toque.
- **Desempenho** (40 módulos, `__build`, Chromium headless): mediana de 52 ms passou para 56–61 ms. A primeira versão, que filtrava as caixas por tira, ia a ~127 ms e foi descartada.
- **Efeito num teste existente: aguarda decisão do Adauto.**
  - `testFitaDaBaseEmbaixoDaPortaPintaPeloToque` pega a **primeira** caixa da fita da base (`[0]`). Com o recorte, essa é a lasca de 9 mm na ponta, então o teste toca outro lugar.
  - No mesmo ponto real (centro da tirinha embaixo da porta), o app faz igual nas duas versões: pega a fita da base e oferece "Era a peça «Porta»?".
  - Com o teste escolhendo o pedaço embaixo do centro da porta, **todas as conferências dele passam** na correção.
  - **O teste não foi alterado.**
  - Na publicada, ele continua com a falha instável antiga (linha 13, `click` em `null`).
- **Fora do escopo, só registrado:** canto em L (prateleira/base de um braço dentro da do outro braço, base superior dentro da moldura).
- **Bateria local completa (`1454596`):** 346/349.
  - `testTamponamentoNo2D…`: falha antiga. A correção está na branch do P0.
  - `testFitaDaBaseEmbaixoDaPortaPintaPeloToque`: o teste pega a primeira caixa da tira, que agora é a lasca da ponta. **Aguarda decisão do Adauto.**
  - `testToPecaQueO3DOfereceApagar…`: total de caixas 65 → 71, porque as tiras viram pedaços. Corrigido **só no teste**, com a mesma mudança autorizada para a branch da fita do rebaixo (`288e0e2`, `1a499eb`, por cherry-pick): conferência pela identidade da peça e totais tirados da geometria da versão testada. Passa nesta branch.

## Junção FT-REBAIXO + FT-PORTA (Etapa 3, 19/11/2026) · expectativas de 2 testes ajustadas (aprovado pelo Adauto, opção a)
- **Bateria da junção 2 (`829d64b`):** 378/380. As 2 falhas vinham das duas correções juntas, cada teste calibrado na sua branch sem a outra. O app não muda.
- **Conferido pela geometria** (variante temporária com só o corte do FT-REBAIXO desligado, fora do repositório):
  - sem o corte: nos 3 módulos com travessa (Balcão 2 portas, Gaveteiro 3 gavetas, Balcão porta + gavetas) há 2 tiras dentro da travessa, Lateral esquerda e direita, 15 × 70 × 0,8 mm, 1050 mm² visíveis cada = 2100 mm²;
  - com o corte: 0 tiras dentro da travessa e a área visível exatamente 2100 mm² menor; aéreos, guarda-roupa e torre iguais;
  - assinaturas de peças+corte idênticas nas duas e iguais às da versão publicada guardadas nos testes.
- **`testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D`:** m0 22360 → 20260, m1 15320,5 → 13220,5, m6 21750,5 → 19650,5; abrir/fechar (Lateral esquerda do Balcão 2 portas) 6630/10350/6630 → 5580/9300/5580, −1050 mm² = a tira do rebaixo dessa lateral, atrás da travessa com a porta aberta ou fechada.
- Na 1ª leitura só vi o começo das mensagens de falha (cortadas); a lista completa saiu do JSON da bateria e foi conferida com a mesma geometria.
- **`testFitaDoRebaixoNaoFicaDentroDaTravessaNo3D…`:** número de caixas de fita m0 3 → 7, m1 4 → 12, m2 3 → 9, m3 4 → 8, m4 4 → 7, m5 8 → 11, m6 6 → 24, m7 igual (o FT-PORTA corta a mesma tira em pedaços em volta das folhas fechadas).
- Nenhuma conferência saiu; o motivo está no comentário de cada teste.

## ETAPA 3 (nova) · integração e auditoria de 22/11/2026 · ramo `claude/arquemestre-etapa3-precisao` (base `d7d9ee3` = app publicado `c561120`)
- **Junções recuperadas da antiga Etapa 3:**
  - FT-REBAIXO: `b12b6e0`.
  - FT-PORTA: `72c36d0`.
  - PC-ID, PC-TOQUE, PC-ROD e PC-BRANCO: `35a1d7b`.
  - Conflitos resolvidos mantendo os dois lados (encaixe do móvel livre + corte da fita).
  - Bateria local completa no `c7429ea`: 399/399.
- **LAT-MEIO (junção 4) não integrada:** muda regra de fabricação, e as perguntas 2, 3 e 4 de 17/11 continuam sem resposta.

### PC-ESQ · plano de corte da parede esquerda
- **Defeito 1 (rótulo):** no móvel novo da parede esquerda (`espE`), o plano mostrava o nome guardado ("Tamponamento esquerdo") e a lista mostrava o de quem olha ("direito").
  - Também acontece na versão publicada. Só o nome; as medidas estão certas.
- **Defeito 2 (identidade):** peça tirada do plano pela identidade (PC-ID) voltava ao plano quando o móvel antigo era desespelhado (38 → 39 peças).
- **Causa:**
  - o `sheetPlan` monta o rótulo pelo pk;
  - o `vira()` remapeava `po` e `xp`, mas não o `S.cutOff` (uid|pk|ocorrência).
- **Correção:**
  - `pcNomeVe` deixa o rótulo com o nome de quem olha; a chave da contagem antiga continua com o nome guardado;
  - o `vira()` passa a remapear também o `S.cutOff` do módulo.
- **Teste:** `testPlanoDeCorteParedeEsquerdaNomeDeQuemOlhaEPecaTiradaSegueAoDesespelhar` (`c6419b9`, falha antes) · correção `c7429ea`.

### PX-SEL · bolinha do puxador engolia o toque
- **Defeito:** com o puxador bola ou externo, tocar no puxador de um móvel não escolhido não o escolhia (só o aviso "Segure a bolinha…"). Os 2 toques em cima dele não abriam o menu do vão.
  - Afeta 68 de 138 modelos com o puxador bola; no padrão, as 6 torres que já usam bola.
- **Causa:** o círculo de arrastar (raio ≥ 13 px) parava o pointerdown e o pointerup. O desenho não escolhia o módulo nem contava os toques.
- **Correção:**
  - o toque curto escolhe o módulo dono da bolinha (`data-gm`) e segue para o desenho;
  - arrastar continua igual;
  - com o móvel escolhido, o toque curto continua só avisando.
  - Ficam de fora os pontos em cima da área da divisória: lá o toque escolhe a divisória (regra de 18/11).
- **Testes:**
  - `testPuxadorBolaNaoEngoleOToqueNemOsDoisToquesDoMovel` (`c2dce6e`, falha 5 de 5 antes) · correção `d54721d`;
  - `testPuxadorArrastaABolinha…` adaptado (pedido 22/11).

### VAO-ESQ · numeração dos vãos do móvel novo da parede esquerda
- **Defeito:** "Vão 1" era o vão da direita de quem olha. Aparecia no painel, no menu dos 2 toques, no Editar só ele, nos títulos de prateleiras e divisórias do vão e nos avisos.
- **Causa:** os dados do móvel novo ficam guardados virados (PAREDE-ESQ-NOVO), e a tela numerava pelo índice guardado.
- **Correção:** `vaoN(m,i)` = N − i quando `espE`, com os botões na ordem de quem olha. Só a tela muda. Fundo, lados e móvel antigo ficam iguais.
- **Teste:** `testParedeEsquerdaMovelNovoNumeraOsVaosDaEsquerdaPraDireitaDeQuemOlha` (`f9588eb`) · correção `f46fae7`.

### GAV-TORRE e GAV-FUNDO · gaveta no 3D diferente do corte
- **Auditoria corte × 3D:** a lista de corte final comparada com a geometria 3D de cada peça em 284 cenários (catálogo em cozinha e quarto, 7826 peças).
- **GAV-TORRE:** na torre com gavetas (`v.tw`), as laterais das gavetas estavam no corte e não no 3D.
  - Causa: o passo da torre renumerava o `dq` (`j*10+dq`) e não o `cgDq` da contra-frente. O 3D não achava as laterais da gaveta e montava a caixa sem elas.
- **GAV-FUNDO:** o fundo da gaveta no 3D era 3 mm mais estreito que a peça (526 × 529).
  - Causa: o 3D não usava o "a mais por lado" dos Ajustes (regra de 09/11).
  - Correção: usa a largura da própria peça (`partsOf`).
- Corte e medidas não mudam.
- **Teste:** `testLateralDeGavetaDoCorteApareceNo3DEmTodoOCatalogoTambemNaTorre` (`97f515f`, falha antes: 4 laterais e 74 fundos) · correção `aa2060f`.
- **Achados da mesma auditoria ainda abertos:**
  - fundo do lado do canto do Canto L guarda-roupa: corte 2400 × 3D 2300 (pergunta ao Adauto);
  - "Sapateira · aparador": está no corte e não no 3D (depende da pergunta da prateleira inclinada);
  - gaveta interna desenhada como bloco (já conhecida).

### Auditoria de colisões
- 2208 cenários: paredes do fundo, esquerda (novo e antigo) e direita; móvel livre a 0°, 90°, 180° e 270°; portas fechadas e abertas.
- Nenhuma porta, gaveta ou peça do corpo entra em outra.
- Só a ferragem da dobradiça (o braço reto) passa 1 mm pelo canto da frente da lateral ou da divisória (A05).
  - É cosmético, sem peça nem corte.
- **Desfazer 3× e refazer 3×** em 142 modelos: corte igual. A única diferença nos dados é `wing` vazio → `0`, tratados igual em todo o código.
## CANTO-FOLHA: folha do lado do canto em L não cobria a lateral do fim (fotos do Adauto, 17/11)
- **Reproduzir (versão pública, Canto em L (aéreo) · esquerdo 700×750×350):** no 3D, a lateral do fim ocupa z 685–700. A folha do lado (319) vai de z 359 a 678: começa 3 mm atrás da frente da caixa do fundo e para 7 mm antes da lateral. A borda de 15 mm da lateral fica à mostra.
- **Causa:** a regra antiga da folha do lado era "vão − 10, vai até 3 mm do armário" (`partsOf0`, porta de canto). No 3D, `z0 = D + 3`.
- **Correção (pedido do Adauto):** a folha do lado começa 4 mm atrás da frente da caixa do fundo e cobre 5 mm da lateral do fim.
  - Largura: `vão + 1`. No exemplo: 330 (360 → 690). Canto de baixo: 309 → 320.
  - No 3D: `z0 = D + 4`.
  - A folha do fundo não muda: 3 mm da folha do lado.
- **Família:** os 4 cantos em L de cozinha (aéreo e baixo, esquerdo e direito; altura < 1500). O **canto do guarda-roupa** pegava a mesma conta e foi deixado como estava (416 + 419).
- **Abrir:** as duas folhas abrem 165/165 sem bater (teste de colisão do 3D).
- **Expectativas atualizadas (pedido do Adauto 17/11, comentário em cada teste):**
  - `testPortaDeCantoMarcacao…`;
  - `testPortasDeCantoRobocop…`: lado 320; começa 4 mm;
  - `testArmarioDeCantoFolgaDe3mm…`: baixo 306 + 320, aéreo 316 + 330, guarda-roupa igual;
  - `testCantoEmLProfundidade…`: Porta 326.
  - Elas falham na versão pública e passam agora. Os outros 12 testes de canto passam nas duas.

- **Junção 6 (22/11/2026), branch `claude/arquemestre-juncao6`, base `db35ceb`:**
  - Integração: testes c6b1975 (4 falham na base, 13 de canto passam); código 3e33ec2.
  - **Risco achado na integração e corrigido:** como foi escrita em 17/11, a regra mudava a folha do lado de **todo** canto de cozinha, inclusive de projeto antigo. Ficava 309 → 320 no corte, sem aviso.
    - Isso contraria a regra do Adauto de 22/11: "projetos antigos … só recebem as novas medidas mediante confirmação do usuário".
  - **Correção (b8b5399):** a regra nova vale só para o canto criado a partir desta versão, que leva a marca `m.cnP` (`newTpl` e `mkCorner`).
    - O canto antigo continua com vão − 10.
    - Ele mostra o aviso "Canto de antes da atualização" com as duas medidas e o botão "Atualizar portas do canto", que tem desfazer; o aviso mostra o antes e o depois de cada peça de porta que muda (ex.: folha do lado 309×650 → 320×650).
  - **Teste:** `testCantoFolhaNovaSoNoCantoNovoOAntigoAvisaEAtualizaComConfirmacao` (864c52c). No 3e33ec2 o canto antigo ia sozinho a 320.
    - Cobre: novo pelo catálogo e pelo botão; antigo igual e com aviso; botão; desfazer; salvar e reabrir; guarda-roupa inalterado.
  - **Marca e botão únicos (acordo Code 1 + Code 2 pedido pelo Code 3, 22/11):** `m.cnP` e "Atualizar portas do canto" (`window.cnPAtualiza`, `#cnpbox`, `[data-cnpup]`) servem para TODAS as regras novas das portas do canto; o antes/depois é calculado comparando `partsOf` com e sem a marca.
  - **Coordenação:** o Code 2 prepara a correção completa das portas do canto (altura, cava, textura, painel cego, dobradiça) em branch isolada, sobre esta junção.
    - O botão e a marca podem ser os mesmos.


## TAMP-JUNTA — tamponamento automático escondido entre dois módulos encostados (22/11/2026)
- **Relatado:** Adauto 22/11, com foto: balcão aberto (sem porta) à esquerda do balcão do forno embutido, com pedra, e 4 faixas verticais na junta. Confirmou que o tamponamento apareceu sozinho (automático).
- **Módulo:** tamponamento automático (`autoTamp`, `tlAuto`/`trAuto`), todos os módulos de parede.
- **Como reproduzir:** forno sozinho em x=1500 (ganha o automático no lado esquerdo exposto); balcão aberto pelo catálogo, longe à esquerda; levar o aberto até o forno (arraste no 2D ou posição digitada), arrastar o forno no 3D até o aberto, ou encaixar na parede um móvel livre do 3D (`__mv3.encaixa`) encostado no forno.
- **Causa raiz (comprovada):** o automático só era decidido na criação do módulo (`ATGO`, armado no `newTpl`). Mudar o módulo de lugar não reavaliava a junta:
  - 2D: `pointerup`, `gapJoinDir`;
  - 3D: fim do `MDRG`, `gapJoin`;
  - posição digitada: `setv('x')`, o B05 só tirava o automático do próprio módulo;
  - encaixe do 3D: `encaixa`.
  O lado que tinha ficado exposto continuava com o automático depois de encostar.
- **As 4 faixas:** face de 15 do tamponamento esquerdo do forno + réguas de 80 (engrosso), por fora do forno (não entram no módulo).
  - São peças reais: `partsOf`, lista (`cutLines`: face 720×585 + réguas 720×80 e 425×80), plano de corte, 3D e orçamento (2,61 m de fita por tamponamento).
  - No arraste e no encaixe ficavam os dois automáticos na junta (60–62 mm).
  - Digitando a posição, o aberto era empurrado de 900 pra 870.
- **Correção:** `tampJunta(m,dir,x0)` ao lado do `autoTamp`, chamada no fim de cada movimento feito pela pessoa (2D, 3D, posição digitada, encaixe):
  - encostou → sai o automático dos dois lados da junta (`tampNbOf`, mesma regra de vizinho da criação);
  - o módulo arrastado encosta no vizinho, fechando só a folga do tamponamento que saiu (o vizinho não anda; se entraria em outro, fica onde soltou);
  - separou → volta o automático no lado que ficou exposto (`tampExposed`);
  - nunca mexe em manual (`tlM`/`trM`), do modelo, travado, canto, nicho, painel de TV, livre, nem com o ajuste "automático" desligado;
  - projeto aberto não muda; aviso na tela quando tira ou põe.
- **Decisões:** DECISOES_TECNICAS 22/11 (~20:25, ~21:10 e ~21:40 UTC).
- **Família conferida:** aéreos (sai), torre quente + balcão (o tamponamento do modelo da torre fica, o automático do balcão sai), guarda-roupas (do modelo, não muda), remover e recolocar pelo catálogo.
- **Testes:** `testTamponamentoAutomaticoSaiDaJuntaQuandoOModuloEncostaNoOutroEOManualFica` (84fb89c, ampliado em fd72cce) · correção a6712f1.
  - Falha antes em 8 conferências.
  - Cobre 2D, 3D, digitado, encaixe, manual, aviso, orçamento (só os dois tamponamentos), desfazer/refazer, salvar e reabrir, separar, projeto antigo.
- **Pendente:** aparelho real; CI das 3 plataformas na branch `claude/arquemestre-tamp-junta` (não integrada à candidata).

## TAMP-25-3D — engrosso do tamponamento de 25 mm entrando 5 mm no módulo no 3D (22/11/2026)
- **Achado:** na investigação do TAMP-JUNTA (provável origem do TAMP-ENGROSSO de 16/11).
- **Causa raiz (comprovada):** o 3D (`build_eng3`) dividia em camadas de 15 qualquer tamponamento de 25 a 45 mm (`n=round(th/15)`).
  - O de 25 virava face 15 + réguas 15 = 30, dentro de uma caixa de 25.
  - As réguas ficavam em 990..1005, com a lateral do módulo em 1000.
  - O corte é chapa única de 25: o 3D mostrava réguas que não estão no corte.
- **Correção:** o 3D só divide quando a espessura é múltipla de 15, a mesma regra do corte (`mat%15===0`). O de 30 continua face + moldura, duas de 15.
- **Regra (Adauto 22/11):** tamponamento só de 15, 25 (chapa única) e 30 (duas de 15). Não existe 35 (pedido de 35 cancelado pelo Adauto; nada de 35 entrou no código).
- **Teste:** `testTamponamentoDe25No3DIgualAoCorteSemEntrarNoModulo` (fd72cce, falha antes: 975..1005, entra no módulo) · correção a6712f1.

## CPAN-DUPLO — "Panelas no cooktop" e "Panelas e louça" com o mesmo atributo no ＋ Criar (23/11/2026, relato do Code 2)
- **Reproduzir:** Balcão 2 portas + pedra + cooktop → 3D → ＋ Criar.
- **Defeito:**
  - "🍲 Panelas no cooktop" punha um item decorativo (`S.fr` +1) e não ligava as panelas do cooktop;
  - a seção "Panelas e louça" sumia quando havia cooktop.
- **Causa:**
  - os dois usavam `data-cpan`, com o cooktop em `"1"` e a louça com o índice do item;
  - o tratador da louça, em captura com `stopImmediatePropagation`, pegava o toque do cooktop;
  - a guarda da seção da louça ("se já tem `[data-cpan]` não monta") achava o do cooktop e não montava.
- **Correção (001bf4e):** a louça passa a usar `data-clou`. O `data-cpan` fica só no cooktop. Nenhum botão some.
- **Família (§11):** varridos os 33 `data-*` do `#crp3`. Os repetidos são valores da mesma ferramenta; não há outra colisão entre ferramentas diferentes.
- **Teste:** `testFASE4_PanelasDoCooktopEPanelasELoucaNoMenuCriarSemConflito` (6905651, falha antes).

## FASE4 · M1 — menu ＋ Criar em 2×3 (23/11/2026)
- **Pedido:** Adauto, com a imagem `engenharia/referencias/menu-criar-aprovado-2026-11-22.jpg`. Plano do Code 2 (PLANO_MENU_CRIAR_ESPELHOS_LED.md §2/§7/§8).
- **Feito (8657f4d):** um bloco no fim do `editor.html` mais um `MutationObserver` no `#crp3`. Não mexe no `crpRender` nem nos 12 embrulhos.
  - **Grade 2×3:** Móveis | LED · Espelhos | Pedras · Paredes | Outros, com cartão preto, botões #242424 e o "+" de Outros em cinza.
  - **Categoria:** cada uma abre as ferramentas dela com "‹ Voltar".
  - **🔎:** procura em todas as categorias.
  - **Classificação:** pelo título da seção. O que não casa cai em Outros, então nada some.
  - **Pedras:** recebe "Só a pedra" (o mesmo botão, movido), ilha/península e cozinha viva.
  - **Espelhos:** o espelho que já existe na folha de correr (`slideCfgOpen`). Sem porta de correr no projeto, oferece criar o guarda-roupa de correr.
  - **Outros:** sofás e consultório.
- **Conferido:**
  - 34 `data-*` iguais em 3 ciclos de abrir e fechar;
  - 0 `__build` ao abrir e ao trocar de categoria;
  - a ferramenta funciona a 1 toque;
  - capturas em iPhone 390, iPad 820, Tab S9 FE 800 e Windows 1366 (Chromium, não aparelho real).
- **Diferença para a imagem:** o título continua "＋ Criar no 3D", com ▁ e ✕ (regra §0, não tirar nada). A imagem tem "+ Criar" com chevron.
- **Teste:** `testFASE4_MenuCriarSeisCategoriasNenhumaFerramentaSome` (69a6002, falha antes).

## FASE3 · móvel livre: câmera, Planta, 3D e ilha (23/11/2026, branch `claude/fase3-editor-livre`, base `3b99c01`)
- **Pedido:** Adauto, 23/11: Fase 3, editor livre (mover e girar sem afetar os outros, câmera 2D que nunca mexe móvel, 3D na hora, preservar os vínculos e a regra de nada entrar em nada).
- **Levantamento:** o que já existia — `lv*` (Etapa B), `isl*`, `__mv3`, Planta e câmera pelo viewBox. A partir dele foram achados e **comprovados** 6 defeitos.
- **CAM-MOVE:** na Planta, o arrasto do livre (`DG`) não olhava o `pointerId`.
  - Efeito: um segundo dedo (pinça ou arraste da vista) movia o móvel (659 mm no teste).
  - Correção: o segundo dedo cancela o arrasto e devolve o móvel.
- **LV-3D-ARRASTO:** no 3D, segurar e arrastar um livre caía no arrasto de módulo de parede (`MDRG`).
  - Efeito: mexia só no `m.x` interno (2675), e o móvel não andava.
  - Correção: um bloco próprio leva o livre pelo chão, com `lvTenta` (colisão e ímã). O de parede fica igual.
- **PL-FANTASMA:** o desenho de parede da Planta (`plantaSvg`, função `TF` sem o ramo `'L'`) e o `plExtrude3` desenhavam o livre também como módulo de parede (`[data-pm]`).
  - Na Planta plana: 1 polígono no lugar antigo da parede. Na Planta em ângulo: 76 faces marcadas como de parede.
  - Esse fantasma respondia ao arrasto de parede.
  - Correção: a Planta plana pula o livre; em ângulo, as faces dele viram `[data-lv]`.
- **PL-ANGULO:** o arrasto do livre na Planta em ângulo não desfazia a inclinação, e o móvel fugia do dedo. Correção: usar `px()`, a mesma conta do resto da Planta.
- **PL-SEGURA:** segurar 2 s no livre da Planta não abria o menu, porque só procurava `[data-pm]`. Correção: aceita também `[data-lv]`.
- **LV-ILHA:** a ilha (`S.isl`) não entrava em `solidos()`.
  - Efeito: o livre entrava dentro da ilha, e a ilha arrastada (`IDRG`) passava por cima do livre.
  - Correção: a ilha passa a ser sólida para o livre (colisão e ímã). A ilha para no último lugar livre.
- **Testes:**
  - `testFASE3_MovelLivreCameraNaoMexePlantaSemFantasmaArrastoNo3DESegurar` (0004c96, falha antes) · correção 191eb5b;
  - `testFASE3_MovelLivreNaoEntraNaIlhaNemAIlhaNele` (f032fa5, falha antes) · correção c5862be.
- **Não mexido:** `partsOf`, `build`/`cornerBoxes`, `snapState`/`loadState`, plano de corte.
- **Pendente:**
  - rotação em ângulo livre (hoje só 90°; aguarda o Adauto escolher entre 45° e qualquer ângulo);
  - teste em aparelho real (pinça com dedos de verdade).

## FASE3 · ROTAÇÃO 45° e ângulo livre do móvel livre (23/11/2026, branch `claude/fase3-rotacao`, base `f8e40ab`)
- **Pedido (Adauto, 23/11):** "Preservar os comandos atuais de 90° e acrescentar 45° e rotação livre de 0° a 360°, com campo para digitar o ângulo exato… respeitando colisões e limites do ambiente. Não movimentar outros móveis automaticamente."
- **Antes:** o livre só girava de 90 em 90 (`lvGira`, `lvFoot`, `lvX` arredondavam cos/sin). Não existia `lvAng` nem botão de 45°.
- **Implementado:**
  - Planta: barra do livre com ⟲/⟳ 90° (os de sempre), ⟲/⟳ 45° e campo do ângulo (`[data-lvang]` + "° Girar").
  - 3D: menu do segurar com ↺/↻ 45° e o campo (`[data-l3ang]`), só no móvel livre; o de parede fica igual.
  - `window.lvAng(m,graus)`: ângulo exato, pelo mesmo `lvGira` (mesma colisão, mesmo centro).
  - Ângulo oblíquo (não múltiplo de 90): `lvFt/lvLoc/lvX` usam o caminho de 0°, e um envoltório do `build` dentro do fechamento do 3D gira todas as caixas do módulo com `rotY` em volta de (lx, lz). Múltiplos de 90 seguem o caminho de sempre (0 caixas giradas).
  - Colisão do oblíquo pelo contorno real girado (`__lvPoly`, teste SAT): pode encostar a quina a 2 mm do balcão; 60 mm pra dentro bloqueia; parede, pedra, ilha e outros móveis bloqueiam; nada é empurrado. Sem ímã no oblíquo.
  - Planta desenha o oblíquo como polígono (frente em vermelho). Sem alça ↕ fantasma de esticar no livre selecionado (família PL-FANTASMA).
- **Peças:** `partsOf` igual em qualquer ângulo (rotação é só posição).
- **Testes:** `testFASE3_MovelLivreGira45EAnguloExatoSemBaterNemMexerNosOutros` e `testFASE3_MovelLivreBotoes45ECampoDeAnguloNaPlantaENo3D` (3190a88, falham antes: `lvAng` não existe; botão 45° não existe) · implementação c6cda87.
- **Não mexido:** `partsOf`, `cornerBoxes`, `snapState`/`loadState` (o `m.rot` já era salvo), plano de corte.
- **Risco identificado:** versões publicadas antes desta arredondam ângulo que não é de 90 ao abrir o projeto (só o desenho; peças iguais). Projeto com livre a 45° aberto num app antigo aparece girado errado.
- **Pendente:** aparelho real (iPhone, Tab S9 FE).

## FASE4 · ESPELHO NA PAREDE (23/11/2026, branch `claude/fase4-espelhos-parede`, base `6341a22`)
- **Pedido (Adauto, 23/11):** "Implementar espelhos independentes nas paredes, com largura, altura, espessura e posição editáveis, visualização correta em 2D/3D e persistência no projeto. Preservar integralmente os espelhos existentes nas portas de correr."
- **Formato:** item da parede em `S.fr` (`t:'espelho'`, `w`, `h`, `d` = espessura, `x`, `b`, `wall` 'e'/'d' ou sem = fundo). `S.fr` já vai no `snapState`/`loadState`, no desfazer e na vista 2D de cada parede: não foi preciso mexer em salvar/abrir.
- **Implementado:**
  - `APM.espelho` com 4 modelos (60×90, 50×70, 80×120, corpo inteiro 50×160 a 300 do chão); nasce no meio da parede.
  - 3D (`espW3`, via `ap3model`): placa de vidro `#d3dde3` (`mir`) com borda lapidada, igual ao espelho da folha de correr; na parede lateral vira com `frWall3` de sempre.
  - 2D: mesmo desenho do espelho da folha (`slMir2d`), com rótulo e medidas.
  - Editor de medidas (3D e 2D): "Espessura (mm)" no lugar de profundidade, passo de 1 mm, de 2 a 50 mm (o mínimo de 20 dos eletros não vale para o espelho). Parede: fundo, esquerda, direita. Sem girar e sem acabamento.
  - ＋ Criar · Espelhos: nova seção "Espelho na parede" (um botão por modelo); a seção do espelho da porta de correr continua igual.
- **Testes:** `testFASE4_EspelhoNaParedeMedidasParede2D3DSalvarEPortaDeCorrerIntacta` (666b222, falha antes: botão não existe) · implementação 42a33eb.
- **Regressão pega pela bateria e corrigida:** o catálogo monta um item por modelo de `APM`, e a regra do catálogo é todo item com foto (`testCatalogoComFotoDeCadaModuloEEletro`: 7 sem foto, máximo 3). Correção 2ce6c40: o espelho de parede fica fora do catálogo; entra pelo ＋ Criar · Espelhos e pela aba Eletrodomésticos.
- **Comportamento correto (não é erro):** o Desfazer junta mudanças feitas em menos de 0,7 s (`histTick`, vale para todos os itens).
- **ESP-APP-ANTIGO (erro comprovado e corrigido, 23/11):**
  - **Medição** (pedido do Chefe, no editor publicado c561120, links gerados no editor novo): com `t:'espelho'` em `fr`, o link de corte e o de cliente **não abrem**. Aparece "Não consegui abrir o plano de corte", o modo corte não liga, e o `draw` quebra em `APM[t].n` (o módulo some do 2D). Os mesmos links sem espelho abrem normal.
  - **Causa:** o app antigo desenha todo item de `fr` e lê `APM[f.t].n`, que não existe pra tipo novo.
  - **Correção evolutiva:** envoltório de `snapState`/`loadState` no fim do arquivo (padrão dos outros, sem mexer no corpo). Salvo, o espelho vai em `frx`, campo que o app antigo não lê; ao abrir no app novo, volta pro `S.fr` (sem duplicar). Projeto com espelho dentro do `fr` continua abrindo. Na memória nada muda.
  - **Depois, no c561120:** corte e cliente com espelho abrem normal (modo corte ligado, 2D e 3D ok, peças iguais, 0 erro), só sem o espelho. No app novo os links trazem os 2 espelhos. Salvar, fechar e reabrir mantém as medidas e a parede.
  - **Limite conhecido:** projeto aberto e salvo de novo num app antigo perde o `frx` naquela cópia (o app antigo não conhece o campo). Não trava nem estraga o resto.
  - **Teste:** `testFASE4_EspelhoNaParedeSalvoForaDoFrPraAppAntigoEVoltaAoAbrir` (1fd4a2e, falha antes) · correção ccd2274.
- **Não mexido:** espelho da folha de correr (`v.esp`, `slideCfgOpen`), `partsOf`, plano de corte. `snapState`/`loadState` só ganharam o envoltório do `frx`.
- **Sugestão (não feita):** espelho de parede na lista de materiais e no orçamento (m²), como o da porta de correr.
- **Pendente:** aparelho real (iPhone, Tab S9 FE).

## FASE3 · PL-ANG-GIRADO — móvel girado com peças sobrepostas na Planta "Ângulo" (23/11/2026, branch `claude/fase3-rotacao`)
- **Relato:** print do Adauto (23/11): gaveteiro livre a 45° na Planta "Ângulo" com gavetas, laterais e caixa em blocos sobrepostos. O 3D estava certo. Na captura `rot45_planta_angulo` da entrega da rotação o defeito já aparecia, e eu não percebi.
- **Causa raiz (comprovada):**
  - `plExtrude3` só sabia desenhar caixa reta e contorno girado (`pf`). O prisma do `rotY` (`b.gp`: base `a` + vetor `d`) caía no caso da caixa reta e virava a caixa em volta de cada peça (488 de 488 arestas alinhadas com a sala).
  - `plDepthSort` ordenava pela mesma caixa reta.
- **Correção:**
  - `plExtrude3` desenha as faces do prisma (lados visíveis pela mesma regra `fv` e o topo, de trás pra frente).
  - `plDepthSort` separa peça girada pelo contorno real no chão (`pdHull`/`pdProj`, eixos das arestas das duas peças). Peça reta com peça reta continua na conta de antes.
- **Família conferida:** a geladeira na parede direita (prisma do `frWall3`) e os módulos da parede esquerda (`wingX`) passam pelo mesmo caminho. Comparação antes/depois numa cozinha em L: só alguns pixels de borda na geladeira; o desenho é o mesmo.
- **Não mexido:** medidas, `partsOf`, plano de corte, DXF, 3D.
- **Teste:** `testFASE3_PlantaAnguloDesenhaMovelGiradoPelaFormaRealSemSobrepor` (68a8543, falha antes: 488 arestas alinhadas) · correção 17d8418. Confere forma, frente de gaveta por cima da lateral e salvar/reabrir.
- **Evidência:** antes = print do Adauto; depois = captura do Chromium. Aparelho real pendente.

## DIG-TECLADO + DIG-SAIDA — valor digitado perdido / preço zerado (23/11/2026, branch `claude/digitacao-toques`, base `8ec9118`)
- **Pedido:** Adauto, 23/11, "AUDITORIA GERAL DE DIGITAÇÃO" (prioridade crítica): "ao adicionar um módulo e tentar digitar um número no campo de dimensões, a edição fecha automaticamente".
- **Reprodução do relato:** a imagem citada não chegou. O fluxo descrito foi refeito com toque emulado de tablet (Chromium): adicionar pelo catálogo, no 2D e no ＋ Criar do 3D, e digitar logo em seguida (250 ms) no teclado do app e no físico. Nesse ambiente o campo **não fechou**. **Não foi possível verificar** no iPhone/iPad/Tab S9 FE.
- **Auditoria automática** (Playwright, digitação de verdade, uma tecla por vez, conferindo a cada tecla se o campo é o mesmo, tem o foco e acumula o valor; Tab no fim e conferência se o valor chegou ao projeto ou aos ajustes):
  - painel 2D (todas as abas, 2 tipos de módulo, seções abertas): 55 campos;
  - janelas Cliente, Valores, ArqueCut, Trena, Ajustes e caixa do eletro: 136;
  - 3D (caixa do módulo, peça, geladeira, móvel livre): 15;
  - total: **206 campos**, 0 perdendo foco nem fechando durante a digitação.
- **Erro comprovado 1 · DIG-TECLADO (teclado físico: Windows, tablet com teclado):**
  - Efeito: o valor digitado se perdia ao sair do campo (Tab ou toque em outro campo) e o Enter não confirmava.
  - Medido antes: 51 de 55 campos do painel 2D; Valores 6 de 8; Ajustes 84 de 106; ArqueCut (chapa, serra).
  - Causa: o teclado do app segura o `input` de cada tecla (pra não aplicar 7 → 75 → 750). O `change` de verdade do navegador (Tab/Enter) zerava o "pendente" achando que já tinha aplicado. O painel 2D aplica no `input`, então nada era aplicado, e ao sair do campo não havia mais nada pendente.
  - Correção: o `change` de verdade com valor pendente fica pendente e é aplicado ao sair, pelo mesmo `commit` do OK. Enter = OK.
- **Erro comprovado 2 · DIG-SAIDA (preço zerado):**
  - Efeito: nos preços do Ajustes (`data-stdp`), digitar e tocar no campo de baixo sem OK (teclado do app) **zerava o preço** (PR = 0, campo vazio). Com teclado físico + Tab, idem.
  - Causa: o "saiu do campo" do preço (`money(PR[...])`) rodava antes do "saiu do campo" do teclado e voltava o valor antigo antes de aplicar.
  - Correção: o do teclado roda na captura, antes dos outros.
- **Comportamento correto (conferido):**
  - valor inválido continua recusado com aviso (ex.: altura 123 mm, "mínimo 290");
  - eletrodoméstico com medida do modelo ("troque o modelo");
  - geladeira presa pela regra da pedra;
  - Cliente/Trena/peça avulsa do ArqueCut aplicam no botão.
- **Testes:** `testDigitacaoTecladoFisicoTabEnterEPrecoAoSairDoCampoNaoPerdeValor` (4dd6540, falha antes) · correção 68f13ff · bateria 431/431.
- **Observação (não mexido):** a geladeira volta sozinha pro fim da parede quando o valor digitado a colocaria embaixo da pedra, sem aviso. É a regra física de sempre; fica a sugestão de avisar.

## TOQ-TAMP — tamponamento quase impossível de tocar com o dedo (23/11/2026, mesma branch)
- **Pedido:** Adauto, 23/11, "precisão absoluta na seleção… tamponamentos confundidos com outros elementos".
- **Medição:**
  - com a parede inteira no 2D, o tamponamento de 15 mm tem 4,7 px na tela;
  - toque a até 3 px do centro acerta;
  - a 6 px pra dentro cai na porta; a 6 px pra fora cai no fundo vazio;
  - arrastar a 8 px pra fora não fazia nada.
- **Causa:** o 2D escolhe pelo elemento embaixo do ponto (sem tolerância) e o alvo é menor que a ponta do dedo.
- **Correção:** o toque que cairia no **fundo vazio** (nada tocável embaixo) a até 12 px de um tamponamento é repassado pra ele, e segue o TAMP-2D-ALVO de sempre (não escolhido só escolhe; escolhido muda só a altura). Dentro do móvel nada muda: porta, frente e vão continuam com prioridade.
- **Conferido sem mudança (comportamento correto):**
  - pinça em cima do módulo escolhido só dá zoom; peças e seleção ficam;
  - 1 dedo arrastando + 2º dedo vira pinça sem mover nada;
  - arrastar a porta de módulo escolhido move o módulo (regra F3-TOQUE).
- **Testes:** `testToqueNoTamponamentoFinoTemToleranciaSoPraForaSemMexerEmOutraPeca` (e9cb775, falha antes) · correção d96a38d.
- **Pendente:** aparelho real (dedo de verdade); toque no 3D não auditado nesta etapa.

## CODE 2 · registro consolidado das correções de 22–23/11/2026 (CLAUDE.md §8.9/§11.1)
Cada item: pedido → causa → correção → teste (falha antes) → evidência. Lista completa com status em `ENTREGA_CODE2_2026-11-23.md`.
- **CANTO-PORTA-L (22–23/11, Adauto 23:01):** porta do canto em L com 650 mm (retas 705), sem cobrir a travessa, cava sem chanfro no 3D. Causa: a folha do canto não usava a regra vertical das retas. Correção `f9c5cc7`/`e130848`: mesma regra (705, sobe 5 mm, cava), canto novo com `m.cnP`, antigo com aviso + prévia + botão (estrutura única da junção 6 do Code 1). Teste `testPortasDoCantoEmLAlinhadasComAsRetasNovoEAntigo`.
- **PAINEL-CEGO (23/11 00:38):** painel cego tratado como porta (dobradiça Ø35, altura da porta). Correção `f7a242f`: peça fixa alinhada com a porta ao lado, sem furo; antigo só confirmando. Teste `testPainelCegoAlinhadoComAPortaSemFuroDeDobradicaNovoEAntigo`.
- **FASE2 gaveta (gf6):** fundo de gaveta 2 × 1,5 mm mais largo que o rebaixo de 6 (entrava 7,5 em cada lateral). Correção `bf2abf6`/`78e05ab`: módulo novo (`m.gf6`, por todo caminho de criação e ilha) entra exatamente o rebaixo; antigo e ilha antiga com aviso + prévia + "Atualizar fundo das gavetas" + desfazer. Testes `testFASE2_*`. iOS CI 674: expectativa calculada em Swift ainda era caixa − 15 → `68783b4` (novo − 18, antigo − 15).
- **FASE2 rodapé do encontro:** rodapé lateral do encontro entre balcões com rodapé contínuo saía do corte/3D mas ficava na lista (orçamento). Correção `bf2abf6`: sai do `partsOf`. Nenhuma exportação lê o `partsOf0` cru (conferido 23/11; não existe exportação CSV).
- **FASE5 DXF:** exportador novo (contornos, furos, rasgos, cavilhas, camadas por operação; não inventa furação). `a923d59`; `testFASE5_*`; validação ezdxf em `FASE5_DXF_CNC.md`. Aspire não validado.
- **3D-ACABAMENTO (z-fighting):** fita de 0,8 mm desenhada dentro de outro sólido (só recortada atrás de porta ≥ 50 mm do mesmo módulo) e fundo de gaveta coplanar dentro da lateral. Correção `5080d78` (FT-GLOBAL + rebaixo desenhado), `4a56268` (peça girada `gp` fora do recorte). Testes `test3D_SemSolidoDentroDeOutroFitaERebaixo`, `test3D_CatalogoSemCaixaInvalidaSelecaoTexturaEGirado` (591 modelos: 0 caixa inválida/invertida, toda peça com chave, textura com medida real, móvel 45° com textura).
- **PEDRA-L-2D (23/11 07:11):** a elevação da parede lateral não mostrava o braço da pedra em L. Causa: na vista de parede só entravam as pedras daquela parede. Correção `235f4f7`/`5c838a6`: trecho que encosta na parede pelas mesmas contas do 3D, com saia, rodobanca, lateral, cuba e textura real; também nas Vistas. Teste `testPedraEmLApareceNaParedeDoLado2DIgualAo3D`.
- **ID-PAREDE (intermitente `testPaineisDiferentesEmCadaParede…`):** id novo de painel/eletro na vista de parede só conferido contra a lista daquela parede → podia repetir o de outra (peça na parede errada no 3D, projeto com id duplicado). Correção `278e643`: confere todas as paredes. Teste `testIdNovoNaVistaDaParedeNaoRepeteODeOutraParede` (relógio fixo: falha sempre antes).
- **GEL-LAT (23/11 09:31):** caixa da geladeira com a lateral do armário descendo até o chão junto com o tamponamento. Correção `b45a408`: com tamponamento, a lateral fica só no aéreo; caixa antiga com aviso + prévia + botão + desfazer. Teste `testCaixaDaGeladeiraLateralSoNoAereoTamponamentoAteOChao`.
- **MED-PAREDE (23/11 10:11):** trena do 2D na parede esquerda ia pro lado do espelho ao arrastar/soltar (redesenho fora do `#wvmir`) e a do fundo aparecia espelhada na esquerda. Correção `d8173fe`: entra no grupo espelhado; medidas por parede. Teste `testTrenaNaParedeEsquerdaEspelhadaECadaParedeComAsMedidasDela`.
- **ÁREA MOLHADA (AM-1..4) e PIA-1 (pedido 16/11 14:41, especificação de 16/11):** placa lisa mais escura por cima da pedra ("mancha"), sem degrau, cilindros/frisos fictícios, rebaixo padrão 8; cantos do furo da cuba sem textura. Correção `775fcf0`: mesma pedra rebaixada o dp guardado (novo 20; antigo fica), cantos de pedra, cuba no nível de baixo, aviso se o rebaixo não cabe; canto do furo no grupo `stc`. Teste `testAreaMolhadaMesmaPedraRebaixadaComDegrauECantoDoFuroComTextura`. Pendente com o Adauto: rebaixo maior que a pedra e faixa do campo.
- **VAO-LIVRE (D27):** editor normal não mostrava a medida livre do vão. `59129eb`; teste `testVaoEscolhidoMostraAMedidaLivreReal`.
- **Conferidos sem defeito (com teste):** textura da folha do canto e das portas na parede lateral (`f32837f`, `testPortaDoCantoEDaParedeLateralComATexturaRealDasRetas`: a auditoria suspeitava do `matTx`, mas o `pfFill` usa `woodT`); rodapé fora do corte em L (`testPlanoDeCorteRodapeForaDoCorteNaCozinhaEmL`); projetos montados sem sobreposição (`FASE2_LEVANTAMENTO_MONTADOS_2026-11-23.md`).
- **Ferramenta:** bateria do Chromium confere asserts com expressão Swift e os testes com JS em `static let` (`8f21fa0`: 3728 → 4166 asserts conferidos).
- **PAREDES A–F (23/11, "Faça todos"):** abertura com peitoril (antes: vão com "do chão" > 0 deixava buraco embaixo no 3D), meia parede com altura editável (antes fixa 1100), remover/restaurar fundo e laterais (antes o 🗑 da lateral apagava as portas dela; o fundo não saía), menu EDITAR PAREDE, Soltar sem mexer. Detalhes, commits e testes em `PAREDES_ETAPAS_A_F_2026-11-23.md`; compatibilidade com o app publicado medida (nada se perde ao salvar no app antigo).
- **JUNÇÃO 5 · TRAVESSÃO (23/11):** `a849a43`, `testJuncao5TravessaoDuasReguasDe80PorCimaDasLaterais`. Regra do a862927 (Code 1, 17/11) refeita sem depender da LAT-MEIO; padrão 80 mm.

## Pendências da candidata 5bd11f5 (23/11/2026, branch `claude/abertos-1`)
- **testFASE3_PlantaAngulo (298 × 274 arestas):** a contagem depende de quantas caixas o 3D gera, e subiu com a auditoria do 3D do Code 2. O teste passa a conferir "desenhadas · alinhadas 0" e reabrir com as mesmas arestas. Continua falhando antes da PL-ANG-GIRADO. Commit 9d0c48a.
- **iOS CI 674, testFASE3_MovelLivreCameraNaoMexe… — "embaixo do dedo false": comportamento correto, não é defeito.**
  - Reproduzido em 390×844 (tela do iPhone): 80 px de dedo dão 1620 mm. O móvel bate na parede direita e para ("ele entraria na parede direita").
  - Medido: dedo 80,40 px; móvel 50,25 px.
  - O teste passa a arrastar 40% da largura do móvel na tela.
  - O arrasto 3D confere andou/b/rot/m.x, sem o ponto exato.
  - Conferido em 390×844, 375×667, 820×1180, 1024×1366 e 1366×768. Commit 31e55b7.
- **Revisão dos testes do Code 1 nas telas do iPhone e do iPad** (verificador que extrai o JS e as asserções do Swift e roda com Playwright): FASE3_* e FASE4_* passam. O testToqueNoTamponamento (claude/digitacao-toques) dependia da tela e foi corrigido no 6d6ab18.
- **CANTO-ESPELHO (erro comprovado, achado pelo Code 2):**
  - Efeito: na parede esquerda, o `cantoEncosta` redesenhava pelo `d0` guardado antes do envoltório PAREDE-ESPELHADA. O 2D ficava sem espelho e o `WVMIRX` velho, e o toque convertia errado.
  - Repro: balcão no canto, `wvGo('e')`, módulo novo em x=606 → encosta em 630 → `#wvmir` some.
  - Correção: redesenhar por `window.draw`, com `busy`.
  - Teste `testCantoEncostaNaParedeEsquerdaMantemOEspelhoDo2D` (7670248, falha antes) · correção 9fd337d.
- **testFornoDaTorrePorVaosAbreNoToqueEmQualquerPonto (intermitente): era do teste, não do app.**
  - Medido: com 60 ms entre fechar e tocar, o toque caía no meio da animação de fechar (ângulo ~0,85). Com a máquina carregada, fechar + toque se anulavam (ângulo ficava 1).
  - Em todas as rodadas o toque mudou o forno.
  - O teste agora espera fechar (até 3 s), toca e espera abrir (até 3 s). Continua falhando se o toque não abrir.
  - 6/6 rodadas (antes 1/6). Commit 2f52a83.
- **GEL-TAMP (23/11, "Só o tamponamento"):** caixa nova da geladeira já nasce com tamponamento dos dois lados terminando 100 mm acima do piso. `5a48d40`; `testCaixaDaGeladeiraNovaComTamponamentoCemMilimetrosAcimaDoPiso`. Caixa antiga não muda sozinha.
- **CSV (23/11):** não existia exportação CSV. `988986e`: botão no plano de corte, mesmas linhas do PDF (lê o `partsOf`, não o cru), UTF-8 com BOM, ";" e compartilhar nativo. `testPlanoDeCorteListaEmCSVMesmasLinhasDoPDF`.
- **CHURRASQUEIRA QUADRADA (pedido 16/11, padrões aprovados 23/11):** não existia o modelo. `2cc652d`: 900 × pé-direito × 600, boca 680 × 520, moldura 45°, 2D/3D/quadro pela mesma geometria. Defeito achado no caminho: `apSvg` chama `churSvg` com `f=null` e desenhava a forma padrão → procura pelo nome. `testChurrasqueiraQuadradaDeEmbutirComMolduraA45`.
- **MOLDURA/FRONTAL (23/11):** painel na ordem Moldura → Travessão → Frontal e 3D = corte. `0714b18`; `testMolduraTravessaoFrontalTresDIgualCorteEOrdemNoPainel`.
- **PINTAR COMPACTO (D44, decisão 17/11):** cabeçalho alto, sem cor, opções sem rolagem própria, "#1" sempre visível. `e314a8b`: cabeçalho fixo em 2 linhas com a cor, rolagem interna, 2 colunas a partir de 700 px, "#1" só some da tela quando a peça é única; ordem dinâmica e todas as opções iguais. `testPintarCompactoCabecalhoDuasLinhasRolagemEDuasColunasSemPerderOpcao` (falha antes). Ajustado `testAcabamentoNaoMudaAoAbrirPortaEFitaPeloToque` (título sem o "#1").
- **FITA 1 mm · CORTE × ACABADA (decisão 17/11):** o quadro da peça só mostrava uma medida. `a283ce6`: corte do MDF (igual ao plano, sem desconto) e acabada com a fita de 1 mm por borda (MDF 560 + 1 = 561). `testQuadroDaPecaMostraCorteEAcabadaComFitaDe1mmSemMudarOCorte` (falha antes).
- **AQRENDER (23/11, "Acabamento realista", opção desligada):** `4445cf2`. Defeitos achados ao trazer o protótipo de 16/11: o motor passou a usar buffers tipados (`F.concat is not a function` → convertido), a luz de lado fazia a parede lateral sombrear o móvel em diagonal (luz quase de frente) e a parede de raspão ficava listrada (sombra some em `ndl` baixo). Desligado o 3D é idêntico (imagem igual byte a byte no teste). `testAcabamentoRealistaOpcaoDesligadaPorPadraoSoMudaAAparencia`.

## ESP-FORMAS · ESP-VAO · LED-LIVRE (23/11/2026, branch `claude/espelhos-d33`, base `d33886f`)
- **Pedido:** Adauto, 23/11: "LED completo e o resto dos espelhos (formatos, espelho no vão, girar, acabamentos, orçamento de vidro)", confirmado direto com ele: fazer agora.
- **Respostas dele (23/11):**
  - LED: os modelos de LED que já existem, barra de 2 m; o LED de hoje fica igual (o novo é a mais); fonte por botão, rasgo deixa no mínimo 3 mm, usinagem por metro (R$ 0).
  - Espelhos: preços em branco; ornamental quando ele mandar o desenho.
- **ESP-FORMAS** (94095e3 teste · 7555e0f código):
  - espelho de parede (`S.fr` t:'espelho') com formato retangular/quadrado, redondo/oval ou arco (contorno de verdade, 72 pontos no oval);
  - girar 0/90/180/270 ou ângulo digitado;
  - prata, bronze ou fumê; borda lapidada ou bisotê; moldura 3 ou 5 cm atrás do vidro (sem faces no mesmo plano);
  - duplicar;
  - 2D desenha o contorno;
  - orçamento de vidraçaria separado do MDF: m² pela área real por acabamento; lapidação, bisotê e moldura por metro; 6 preços novos no Ajustes (R$ 0). Não entra no plano de corte.
  - Espelho sem as opções novas desenha igual.
- **ESP-VAO** (2fd941a teste · 60e5dc8 código):
  - "Espelho no vão escolhido" no ＋ Criar;
  - medida e lugar vêm do vão: `vaoRanges`, base de baixo/de cima e frente do fundo pelas caixas do 3D, menos o recuo 0/10/20/50;
  - preso ao módulo pelo `uid` (outro módulo entrando ou saindo não troca o dono);
  - anda e acompanha a medida; não muda peça; "Soltar do vão" deixa ele solto na parede;
  - por enquanto só módulos da parede do fundo (avisa nos outros).
- **LED-LIVRE** (e4202d3 teste · ddfb3b7 código):
  - "Adicionar LED numa peça" no ＋ Criar · LED: toque na peça → o LED vai na face tocada, preso pelo `pk` (anda com o módulo);
  - quadro com lado, comprimento, posições, girar 90°, sobreposto/embutido, cor, perfil, acender, duplicar e tirar;
  - embutido: rasgo de 12 mm anotado na peça (deixa ≥ 3 mm); a medida da peça não muda;
  - orçamento: perfil em barras de 2 m, fita, fonte (1 por botão / 1 por módulo), usinagem (m);
  - o LED de sempre não muda (os 4 testes antigos de LED passam).
- **Testes:** os 3 falham antes. A expectativa do ＋ Criar passou de 35 para 37 chaves (`data-cespv`, `data-cledl`), com comentário; nenhuma antiga saiu.
- **Não feito (fica registrado):**
  - espelho ornamental (aguarda desenho);
  - espelho em painel/ripado e espelho com LED;
  - espelho no vão de módulo de parede lateral;
  - LED magnético (não há perfil magnético entre os modelos de hoje);
  - zonas proibidas de ferragem (dobradiça, corrediça, sistema 32) na colisão do LED;
  - LED livre em peça girada (gp) do móvel livre.
- **Compatibilidade:** app antigo ignora `m.leds` (abre o projeto sem o LED livre; salvar de novo naquela cópia perde ele). Os campos novos do espelho vão dentro do item, já salvo em `frx`.
- **POLÍTICA B · LED livre e espelho (bloqueador pedido pelo Adauto, 23/11):**
  - O link do cortador e o do cliente de projeto com LED livre ou espelho saem como `arque-corte-v2`/`arque-cliente-v2`. A versão publicada recusa ("Não consegui abrir"), em vez de abrir sem o LED, sem o rasgo do embutido ou sem o espelho.
  - Antes de mandar aparece a mesma janela de confirmação das peças livres. Este app abre normal. Sem LED livre nem espelho, nada muda.
  - **Limite que não tem como corrigir:** projeto copiado à mão (backup/arquivo) pra um aparelho com app antigo ainda abre sem o LED. App antigo não pode ser mudado; a saída é atualizar.
  - Teste `testPoliticaBLedLivreEEspelhoNaoAbremEmVersaoAntigaSemAviso` (4ee3da8, falha antes) · correção 316d3c8.
- **JUNÇÃO 4 · LAT-MEIO (Adauto 23/11):** `21daeffd` (sobre a LAT-MEIO do Code 1, `3991175`). Travessa em uma peça por vão (7,5 mm de cada lado do rebaixo, mm inteiro com a folga no encontro); montante junto das gavetas vira lateral inteira; recuo traseiro mantido. Achado: a peça com décimo quebrava a regra do corte em mm inteiro (testes do catálogo) → corrigido antes do commit. `testJuncao4TravessaEmPecasRebaixoMeioAMeioRecuoMontanteSemSobreposicao`.
- **BATENTE CAVA (23/11):** `9dde42f5`. Régua por régua, batente superior, conferência pela geometria (5 mm mínimo, sem colisão nova), restaurar a automática do modelo, editor por vãos (não tinha campo). `testBatenteCavaReguaPorReguaComLimitesRestaurarEEditorPorVaos`.
- **BASE INTEIRA/DIVIDIDA/PERSONALIZADA (23/11):** `a9049cd3`. `testBaseInteiraDivididaOuPersonalizadaPorModuloComDivisoriaDescendo`.
- **GAVETAS QUE NÃO CABEM (23/11):** colisão que já existia (cava com muitas gavetas num vão baixo: caixa/régua na travessa ou na outra caixa). `b07085a4`: o + não aceita, módulo antigo avisa com botão. `testGavetasQueNaoCabemNaoEntramEModuloAntigoAvisaComBotao`.
- **Ferramenta:** rodar sonda ou teste no mesmo Chromium em que a bateria completa está rodando derruba testes aleatórios (a bateria pega a 1ª aba do editor). Sempre um navegador só pra bateria.

## AUDITORIA GERAL · espelhos e LED (23/11/2026, branch `claude/auditoria-1`, base `bfae688`)
Pedido: "ESPELHOS ULTRARREALISTAS E AUDITORIA GERAL" (Claude 1 audita). Testes `e341bef` (falham antes) · código `d9fc207`.
- **AUD-ESP-SOLIDO — espelho atravessando móvel (ponto 1, erro comprovado).**
  - Reproduzir: espelho de parede com altura/posição que cai sobre um módulo → antes ficava dentro do módulo.
  - Causa: `itSet`/troca de parede/formato/giro/moldura e `espWallAdd` não conferiam colisão com as caixas dos módulos.
  - Correção: `espBate(f)` (caixas do espelho × caixas do 3D; espelho no vão fica fora de propósito). Edição que levaria pra dentro volta e avisa ("Nada mudou"); espelho que já estava dentro pode ser editado. Criação nasce no lugar de sempre e, se cair num módulo, só avisa qual (CLAUDE.md §4 — a 1ª versão subia/removia sozinha e quebrava 3 testes antigos; trocada no mesmo dia).
- **AUD-LED-GIRO — LED livre no móvel livre girado (ponto 8, erro comprovado).**
  - Causa: `lvlHost` pulava peças `gp` (prisma girado) → LED sumia/não achava face.
  - Correção: `lvlRot`/`lvlDesgira` desfazem o giro, `lvlDraw1` desenha reto e gira junto; `lvlPickFace` aceita peça girada.
- **AUD-LED-FERRAGEM — LED atravessando dobradiça/corrediça (ponto 7, erro comprovado).**
  - Correção: `lvlFerragem` na face de dentro da lateral: faixa das corrediças (altura das laterais de gaveta) e faixa da dobradiça (porta do lado, 95 mm da frente). Recusa com aviso ao criar e ao mudar campo.
- **AUD-ANGULO-ENTER — ângulo digitado só valia no botão (ponto 6, erro comprovado).** Espelho, móvel livre na Planta e no 3D aplicam no Enter/ao sair.
- **Comportamento correto:** reflexo não invertido (2); toque/seleção do espelho (5); digitação nos quadros novos (6).
- **Defeitos repassados ao Code 2:** espelho em parede lateral sem reflexo e com linha escura (9); espelho redondo jateado com emenda vertical (3).
- **Compatibilidade (10):** Política B cobre LED livre e espelho nos links; backup copiado à mão pra app antigo perde o LED (não corrigível, aviso registrado).
- **Não verificado:** FPS/memória em aparelho real, iPhone/iPad/Android/Windows reais (só Chromium e viewports).

## PROJ-SEM-MODULO — abrir projeto sem módulo apagava obra e esquadro ao salvar (23/11/2026, branch `claude/loadstate-sem-modulo`)
- **Achado na auditoria final da candidata 20c11b0**; já existia na versão publicada `c561120`. Classificação: erro comprovado (perda de dado do projeto, CLAUDE.md §3).
- **Reproduzir:** projeto sem módulo (só espelho, pedra…) com trava de obra (`S.obra`) e esquadro do ambiente (`S.amb`) → abrir pela lista de projetos → salvar → `obra` some e `amb` vira `{}`.
- **Causa:** `loadState` fazia `defs(S.m)` e `S.m.sup` sem módulo → TypeError no meio; as camadas seguintes do `loadState` (obra, amb, pxm, Hm/Wm, pxk/pxo, tz, pw/RDw/deco…) e o `showBox/draw/panel` não rodavam; o salvamento seguinte gravava sem eles.
- **Correção:** guarda mínima (`if(S.m)defs(S.m)`, `S.m&&S.m.sup`). Projeto com módulo não muda. Efeito: `newProjFor`/`arqueNewProject` agora chegam ao `ATGO=2` (com 0 módulo o autoTamp não faz nada).
- **Teste:** `testAbrirProjetoSemModuloNaoPerdeObraNemAmbiente` (d80c925, falha antes) · correção a4148a2.
- **Autorização:** Adauto 23/11 ("Sim, colocar agora") para entrar nesta candidata.


## PROVENÇAL e CONCHA (23/11/2026, branch `claude/portas-provencal-concha`, base `28e24535`)
- **Pedido:** Adauto, 23/11 14:40, com 6 fotos (ver `REFERENCIAS.md`): portas provençais e puxador concha.
- **Entrega inicial:** `057f8722`.
  - Estilos de porta na aba Portas. Régua ou moldura aplicadas viram peças reais de MDF 6 mm; CNC vira frisos no DXF.
  - Concha com 7 modelos e furação pelo modelo.
  - Testes: `testPortaProvencalReguasAplicadasPecasReaisCorteEDxf`, `testPortaProvencalUsinadaCncFrisosNoDxfEConflitoComDobradica`, `testEstilosDePortaPreviaAplicarEmMassaUmDesfazerESalvar`, `testConchaSeteModelosFuracaoPorModeloECorPorEscopo`.
- **PROV-BORDA (print das 15h21):** "réguas na borda direta, sem essa interferência".
  - **Causa:** padrão de 50/40 mm de distância da borda. Era escolha minha, não do pedido.
  - **Correção:** `09f18b40`. Distância padrão 0; veio deitado nas réguas horizontais (`pfFill`, `vr`); portas de canto em L pela medida real da folha (`estCanto`).
  - **Teste:** `testProvencalNaBordaConchaDesviradaEPortasDeCantoAlinhadas`.
- **PROV-TOPO (print das 15h37):** "até o topo em cima também".
  - **Causa:** do lado da cava usinada a régua começava a 21 mm, para não cobrir a cava.
  - **Correção:** `a34e2d9e`. Vai até a borda; a nota avisa que cobre a cava. Teste do CNC atualizado.
- **CONCHA-DESVIRADA (print das 15h21):** "puxadores estão invertido, é contrário".
  - **Antes:** borda reta em cima e arco embaixo, que é o que as fotos 1, 2 e 4 mostram.
  - **Correção:** `09f18b40` passou para arco em cima e borda reta embaixo. Parafusos na altura dos furos do DXF; antes ficavam 0,16 × altura acima do centro, um desvio entre 3D e fabricação achado nessa mesma correção.
  - **⚠ Pendente:** confirmar com o Adauto. O pedido dele sobre o print contraria as fotos de referência (ver `REFERENCIAS.md`).
- **CONCHA-ESCOPO:** a cor "só este puxador" ficava presa quando o vão trocava para outro puxador. Achado no meu código, antes de entregar.
  - **Correção:** `09f18b40`. O escopo vale só na concha.
  - **Teste:** `testEscopoDaCorSoNaConchaEPortaEscolhidaDentroDoVao`.
- **Arquivos:** `app/src/main/assets/editor.html`. Módulo PORTAS PROVENÇAIS no fim, mais ganchos em `px3` (5 chamadas), `cornerBoxes`, `pfFill`, linha do 2D e `pxSvg`.
- **Status:** resolvido na bateria (485/485 em `8eab70a3`). Orientação da concha pendente de confirmação. **Não testado em aparelho real.**

## PASSANTE (23/11/2026)
- **Pedido:** Adauto, 23/11: "puxador passante… em configurações… o quanto a pessoa coloca passando do módulo".
- **Implementado:** `b1a167ba`.
  - Novo tipo "Passante", sem ferragem.
  - `pasAplica` no `partsOf`: a porta passa da borda do módulo o tanto de `pasMm` (Configurações › Puxadores). No balcão e na torre passa em cima; no aéreo, embaixo. No gaveteiro só a frente da ponta passa.
  - Desenho vetorial do botão em `PXF.passante`.
- **Defeito achado no caminho:** a primeira conta media o excesso a partir da borda normal da porta (que já fica uns mm dentro), e não da borda do módulo. Corrigido antes do commit.
- **Padrão `pasMm = 20`:** foi escolha minha e o **Adauto confirmou em 23/11** (via Code 1). Cada marceneiro ainda pode mudar em Configurações › Puxadores.
- **Testes:**
  - `testPuxadorPassantePortaPassaDoModuloPeloAjuste` (novo);
  - `testGolaVerticalEHorizontalEDesenhoDeCadaPuxador`: lista de puxadores +1, com comentário.
- **Status:** resolvido na bateria; padrão confirmado.

## PEÇA LIVRE: 2 toques, Duplicar, ímã e puxador no 3D (23/11/2026)
- **Pedidos do Adauto, 23/11:**
  - "ao clicar duas vezes na peça… duplicar… arrastar… imã alinhado as faces";
  - "Duplicar no 3D… barra minimizar";
  - "dois cliques sobre o puxador, reposicionar… reposicionando um reposiciona todos";
  - "ao selecionar qualquer peça… duplicar".
- **Implementado:**
  - `8a678565`: 2D com menu Duplicar / Medidas / Apagar e ímã de 15 mm. Porta e frente só servem de ímã se a peça estiver na frente delas.
  - `c15faffc`: 3D com ⧉ Duplicar na barra e 2 toques no puxador de barra, bola ou concha (`S.pxa`, todas seguem).
  - `e4f0528c`: Duplicar em qualquer peça; a cópia vira peça livre de MDF 15 com a medida de corte.
- **Defeito IMÃ-ENCOSTO, achado pela bateria completa:**
  - `testEstruturaPeca15SegurarCriaArrastaEncostaEMedidaExata` deu "encostou 5, esperado 0": a peça parava encostada na parede e o ímã puxava 5 mm para a borda do módulo.
  - **Correção:** `8eab70a3`. O ímã só age no eixo em que a peça chegou onde foi solta.
  - No mesmo teste, "arrasta 100" passou a dar 99: a borda da peça encaixou na borda da porta, a 1 mm. Expectativa mudada, com comentário (aceita pelo Code 1).
- **Defeito do teste:** o 2 toques numa peça livre caía no puxador de cava atrás dela (`pickFace` com filtro). Corrigido para usar a face da frente e só puxadores que mudam de lugar.
- **Setas de mover no 3D:** feitas em `cf4c9aae` e **tiradas a pedido do Adauto** (revert `0cf24e8f`). Retirada confirmada por ele em 23/11 (via Code 1).
- **Testes:** `testPecaLivreDoisToquesDuplicarEImaAlinhaAsFaces`, `testNo3DDuplicarPecaEDoisToquesNoPuxadorReposicionaTodos`, `testNo3DDuplicarQualquerPecaViraPecaLivre`.
- **Arquivos:** `editor.html`, no bloco PEÇA LIVRE (fim), em `e3Render` (barra do 3D) e no despacho de toques do 3D (`lastTap.pxm`).
- **Status:** resolvido na bateria.

## ESP-FAIXA: faixa jateada do espelho LED sumia de longe e em ângulo (auditoria do Code 1, 23/11)
- **Relatado:** Code 1, na candidata 20c11b0. Com zoom 1,05 e yaw −0,5 a faixa ficava cinza. Valia de dia e à noite, nas 3 qualidades.
- **Reproduzir:** S.W 4600, `espWallAdd(4)`, `a.x = 150`, `__cam(-.5,.12,1.05)`. Dá 0 de 24 pontos da faixa acesos.
- **Causa raiz:** o passe normal desenha com `polygonOffset(+1,+1)`, que empurra a faixa para trás conforme a inclinação. O vidro do espelho vai no passe do espelho, depois e sem empurrão, e ganhava a profundidade.
  - Não era a espessura de 0,3 mm: subir a resolução de profundidade não resolveu.
  - Tirar o corpo do vidro resolvia, o que confirma a causa.
- **Correção:** `13419b70`. A faixa (`espLed`='fr'/'frs') vai no passe puxado para a câmera (o do gola, −1,−2). O espelho não sai do lugar e nenhuma medida muda.
- **Teste:** `testFaixaDoEspelhoLedApareceDeLongeEEmAngulo`. Pior caso 0/24 antes e 24/24 depois, em dia/noite × auto/equil/alta × 4 vistas.
- **Status:** resolvido na bateria. Falta o Code 1 reauditar a cena com balcão e 2 espelhos à noite.

## ESP-LEVE e RECUO SWIFT (23/11)
- **ESP-LEVE:** `85411be3`.
  - **Relatado:** achados do Chefe no CI. O iOS foi barrado no `appstore_check` pela palavra "Android" na regex de celular. O WebView2 sem GPU caiu na bateria do Windows.
  - **Correção:** regex `/Andr[o]id|…/`; no automático, sem reflexo planar com renderizador por software ou depois de perder o contexto WebGL.
  - A causa da queda do WebView2 **não foi comprovada**: a mudança é uma proteção.
  - **Teste:** `testEspelhoLeveNoAutomaticoSemGpuEContextoPerdido`. Os 3 testes de reflexo pedem 'equil', com comentário.
- **RECUO SWIFT:**
  - **Relatado:** achado do Chefe. Em `testBatenteCavaReguaPorRegua…`, uma linha começava na coluna 0 dentro de `#"""…"""#`. O iOS não compila; o Chromium não pega.
  - **Correção:** `2ec82605` em `claude/juncao4-batente`.
  - **Prevenção:** daqui pra frente, verificador de recuo antes de cada entrega.

## CONCHA-PRUMO e ESCOLHA POR PUXADOR (Adauto, prompt oficial de 23/11, via Code 1)
- **Pedido:**
  - concha com a parte reta EM CIMA, curva embaixo, abertura por baixo, como nas fotos;
  - porta EM PÉ perto da lateral que abre; gaveta deitada e no meio;
  - "respeitar a orientação física correta de cada modelo";
  - escolha individual de modelo, cor, posição, orientação e medidas, aplicando só na peça ou em todas as compatíveis com confirmação;
  - mudar a cor de um puxador não muda os outros;
  - DXF sem furação inventada.
- **Erro corrigido:** a 09f18b40 tinha virado a concha (arco em cima) por causa do print das 15h21. Estava de cabeça para baixo em relação às fotos.
- **Decisão sem resposta do Adauto: para que lado vai a parte reta na porta em pé.**
  - Decidi pela construção física.
  - A parte reta é o lado fechado da concha (onde a chapa encosta e os dedos fazem força). A curva é a boca, por onde os dedos entram.
  - Abrindo a porta, o puxador anda num arco em volta da dobradiça: primeiro para fora, depois para o lado da dobradiça. A mão puxa a parede fechada para esse lado.
  - Então **a parte reta fica do lado da dobradiça e a boca do lado que abre**. A mão chega pelo lado que abre, que é o natural.
  - **Fontes consultadas** (guias de instalação; nenhuma norma diz o lado da boca na vertical):
    - os puxadores vão no lado oposto à dobradiça;
    - na vertical, a concha fica no meio do montante;
    - na horizontal, a boca fica para baixo para os dedos engancharem.
  - Links: housedigest.com "The Right Way To Mount Cup Pulls…", vandykes.com "How to Execute Cabinet Hardware Placement", onton.com "Cabinet knob and pull placement", kitchencabinetkings.com/guides/cabinet-pull-placement.
  - **A confirmar com o Adauto quando ele puder.** Se for o contrário, é inverter o sinal `O.sg` em `chmOri`.
- **Correções:**
  - `7fe0047a`:
    - geometria num sistema próprio (`conchaPartes3` + `chmOri`), posta em pé ou deitada;
    - parafusos na linha dos furos do DXF;
    - porta com régua aplicada: concha no meio do montante quando cabe;
    - por puxador: automática / deitada / em pé, modelo, cor e medidas;
    - padrão "Apenas este puxador"; os outros escopos pedem confirmação com a contagem (só concha);
    - 3D: "Só este puxador" (`v.chuQ`) ou "Todas as portas" (com confirmação).
  - `f9507178`: o DXF só fura a concha com a furação confirmada. Os entre-furos 64/96/76 dos modelos eram escolha minha (medidas comerciais comuns), o que é furação sem especificação. Até confirmar: sem furo e FALTA no aviso.
- **Testes:**
  - `testConchaRetaEmCimaEmPeNaPortaDeitadaNaGavetaEEscolhaIndividual` (novo, falha na 3933f94f).
  - Atualizados com comentário, todos desta mesma entrega e ainda não homologados: ConchaSete (modelos conferidos deitados e com furação confirmada; escopos com confirmação), ProvencalNaBorda (reta em cima), No3DDuplicar… ("Todas as portas" + confirmação).
- **Arquivos:** `editor.html`, nos blocos CONCHA e escolha por puxador (módulo das provençais), `px3Panel` (lugar de um puxador) e o despacho dos 2 toques (`PXSEL`).
- **Status:** resolvido na bateria. Falta o Adauto confirmar o lado da parte reta na porta em pé.

## PB-PORTAS — link de projeto com portas provençais/puxadores novos abria na versão antiga sem eles (23/11/2026, branch `claude/politica-b-portas`)
- **Achado na auditoria do Code 1** da integração 259fef0 + `claude/portas-provencal-concha` b3cf2f3 (erro comprovado, mesma família do bloqueador do LED livre).
- **Reproduzir:** projeto com régua/moldura provençal (`v.est`/`v.estQ`), concha com modelo (`v.chm`/`v.chmQ`), porta passante (`px:'passante'`) ou cor de um puxador só (`v.pxcQ`, `v.chuQ`) → `cutEncode(cutPayload())` saía `arque-corte`. A versão publicada abriria e recalcularia as peças sem as réguas (8 peças de MDF 6 mm num balcão 2 portas) e com a porta passante na medida antiga (705 em vez de 735).
- **Causa:** a Política B do LED/espelho só contava `m.leds` e espelhos.
- **Correção:** `conta` da Política B também conta vãos com porta/puxador novo (`portaNova`); link sai `arque-corte-v2`/`arque-cliente-v2` e a mesma janela avisa antes ("Projeto com portas e puxadores novos"). Concha sem modelo, porta lisa e puxadores de sempre: tipo de sempre, sem janela. Este app abre o link novo com tudo.
- **Teste:** `testPoliticaBPortasProvencaisEPuxadoresNovosNaoAbremEmVersaoAntiga` (falha antes).
- **Limite (igual ao LED):** backup copiado à mão pra app antigo abre sem esses campos; app antigo não tem como ser corrigido.

## CONCHA-GAVETA (Adauto, print das 19:56 de 23/11)
- **Relatado:** "Puxador concha as gavetas estão de cabeça pra baixo, rês usar isso, opção de mexer somente neles, colocar inverter e movimentar". Os prints mostram as gavetas com a parte reta em cima e a curva embaixo (versão 7fe0047a).
- **Conflito registrado:** o prompt oficial (via Code 1) pedia "reta em cima" para a concha. Olhando o app, o Adauto disse que **nas gavetas** isso está de cabeça para baixo. Vale a instrução mais nova, só para as gavetas. As portas em pé não mudam (ele não reclamou delas).
- **Correção:** `2885dcc8`.
  - Frente de gaveta deitada vem invertida: curva em cima, reta embaixo.
  - ⇅ Inverter por puxador (`md.inv`), na aba (escopos de sempre + "Todas as gavetas", com confirmação) e no 3D (só ele).
  - Os 2 toques no puxador da gaveta abrem a bolinha para mover (antes só porta): só este, ou todas as gavetas com confirmação.
  - Os furos do DXF continuam no centro da concha.
- **Achado no caminho:** o puxador da frente de gaveta aparece na aba **Internos** (id 2), não em Portas. É comportamento de sempre do app, mantido.
- **Teste:** `testConchaDaGavetaInverterEMoverSoElas` (falha na b3cf2f3b). A expectativa da gaveta em `testConchaRetaEmCima…` foi atualizada, com comentário.
- **Status:** resolvido na bateria. Falta o Adauto conferir no aparelho.

## PEÇA-2TOQUES-ARRASTE (Code 3 no CI iOS da candidata 5c56454, via Code 1, 24/11)
- **Relatado:** `testEstruturaPeca15SegurarCriaArrastaEncostaEMedidaExata` falhou no iPhone e no iPad com "encostou 154, esperado 0". Android e Windows passaram. No Chromium reproduz com `--janela 430x900`.
- **Efeito real:** no celular, arrastar a peça livre, soltar e pegar de novo em menos de meio segundo abria o menu de 2 toques em vez de arrastar.
- **Causa raiz:** `8a678565`. O 1º toque (`TQ`) era gravado em todo pointerdown, mesmo quando aquele toque virava arraste. Na tela de 430 px os 99 mm andados viram ~7 px (< 14), então o 2º pointerdown contava como 2º toque, abria o menu (preventDefault) e a peça não andava.
- **Correção:** o toque fica armado no pointerdown, cai se o dedo andar mais de 4 px e só vale quando solta parado. O 2º toque tem que vir até 450 ms depois de soltar. As duas funções ficam (arrastar e 2 toques); o teste antigo não mudou.
- **Mesmo mecanismo conferido:**
  - os 2 toques do 3D (puxador de porta e gaveta, peça) contam no pointerup e só com menos de 10 px de movimento: arraste e giro de câmera não contam;
  - o ímã não usa toque.
- **Teste:** `testPecaLivreArrastarDeNovoLogoNaoAbreMenuEDoisToquesParadosAbrem`. Falha antes ("true false", menu aberto) e passa depois, em 1366 e em 430×900.
- **Nota de processo:** nas rodadas parciais no mesmo navegador, a página antiga pode ficar em cache. Desde agora uso a URL com `&v=<hora>`. As baterias completas sempre rodaram num perfil novo.

## FECHAMENTO CODE 1 (24/11/2026, ramo `claude/fechamento-code1`, base `ed041eb`) — ordem do Adauto via Chefe: fechar tudo, corrigir na hora (§0, §11)
- **B21 — 3D aberto atrasado** (erro comprovado, sonda s23: parede, vão em gavetas e apagar módulo).
  - Causa: o 3D só remontava nos comandos que chamavam `re3`; os que só redesenham (`draw`) deixavam o 3D velho.
  - Correção: com o 3D aberto, o `draw` agenda uma montagem (≤ 1 por quadro; pula se o comando já montou). 3D fechado: nada muda.
  - Teste `testB21Com3DAbertoParedeGavetasEApagarAtualizamNaHora` (29bc3ba/3f7e893, falha antes) · código f91429c · s23: 11/11 na hora.
- **B24 — digitar posição e voltar não devolvia igual** (erro comprovado, s27: 70 modelos).
  - Causa: o wrapper do B05 tirava o tamponamento automático dos dois lados antes de aplicar a posição e só devolvia quando um vizinho se afastava.
  - Correção: depois de aplicar, o automático que já existia volta no lado que continua exposto (regra da criação). Nada novo liga sozinho; manual e TAMP-JUNTA iguais. `tampExposed` exposto em `window`.
  - Teste `testB24DigitarPosicaoEVoltarDevolveOTamponamentoAutomaticoDoLadoExposto` (eddb30d, falha antes) · código 700a81c · s27: 0 diferenças de verdade (o texto difere só na ordem das chaves).
- **B23 — módulo novo entrando no vizinho** (erro comprovado, s20 I7: 12).
  - Causa: o `autoTamp` da criação chamava `rowJoin` na fileira inteira e fechava vãos ≤ 70 mm andando com móveis que ninguém tocou (a sapateira andou 100 mm e entrou embaixo do aéreo). Achado junto: com vão do tamanho do tamponamento, o `tampExposed` oscilava a cada desenho.
  - Correção: `rowJoin`/`wingJoin` com âncora opcional (`fixo`): no `autoTamp` só anda quem teve o tamponamento decidido e o recém-criado; `tampExposed` vê o vizinho como se o tamponamento daquele lado já estivesse (igual à parede).
  - Teste `testB23CriarModuloNovoNaoAndaComOsQueJaExistem` (44e5781 + a23584c, falha antes) · código 17df4a5 + 8a19010 · s20: I7 0, I2 0.
- **N14 — Android: cópia antes-de-usar só no onStop** (risco P0, achado 17/11).
  - Correção: `DataBackup.versionCopyIfNew` também no `onCreate` (thread; só acrescenta zip em Download). onStop igual.
  - Teste: `.github/scripts/teste_atualizacao_android.sh` confere a cópia ao abrir (0614832) · código 414b523 · roda no workflow `android-atualizacao.yml` (disparo manual).
- **B05** confirmado pelos caminhos da pessoa: digitar 25 → 25 (s13, s06 com setv); arrastar até a parede → 35 com tamponamento preenchendo. O "5→35 sem tamponamento" do s06 vem de `a.x=` direto (não é caminho do app).
- **B22** confirmado: o novo nasce com a medida do catálogo; em parede cheia não cria e avisa (s29). Achados: aviso duplicado "não tem espaço" + "foi ajustado pra caber (170 mm)" quando não cria (texto, risco); "Balcão com laterais até o piso" 870 no catálogo nasce 820 (pergunta ao Adauto).

## AUDITORIA TÉCNICA COMPLETA — Code 1 (24/11/2026, ramo `claude/fechamento-code1`)
- **PRECOS-RESTAURO (P0, perda de dados do cliente; já existia na publicada 3f1c3a58/c561120).**
  - Reproduzir: aparelho novo com o backup restaurado (arquivos lá, banco do navegador vazio) → abrir o editor → o `prices.json` do backup é sobrescrito com os padrões (4192 → 2600 bytes): preços e "Meus modelos" somem.
  - Causa: a inicialização (`STD0_`) chama `prSave()` antes da leitura do `prices.json`; o `prSave` grava no banco e no arquivo.
  - Correção: o 1º `prSave` da sessão, com o banco vazio, lê o arquivo antes de gravar (arquivo por cima dos padrões — a regra da leitura de sempre). Uso normal (banco cheio) igual.
  - Teste `testBackupRestauradoNaoPerdePrecosNemMeusModelosNaAbertura` (falha antes) · código 70f5130. Prova: com os arquivos do backup rico, publicada e ed041eb mudam o prices.json ao abrir; a candidata deixa os 4 arquivos iguais.
- **AUD-INT-GAVETA (erro nº 10 do protocolo).** Vão de portas com internos (caixote, maleiro, cabideiro) trocado pra gavetas continuava gerando os internos (4 frentes de caixote + 8 corrediças no corte, dentro das gavetas). Correção no `partsOf`: com o vão em gavetas os internos não entram; os dados ficam e voltam com as portas. Teste `testVaoDePortasComCaixoteViraGavetasSemCaixoteFantasmaEVoltaAoTrocar` · 8e8522a.
- **AUD-RODAPE-TRASEIRO (toque).** No 2D de frente o rodapé traseiro era desenhado por cima do da frente (mesma camada) e o toque no rodapé que se vê escolhia o de trás (51 modelos, 1366 e 430). Peça traseira vai pra camada do fundo. Teste `testToqueNoRodapeDaFrenteEscolheEleEnaoOTraseiroEmTodoOCatalogo` · 514fa78.
- **2 toques no 3D nos testes (instabilidade investigada).** `testNo3DDuplicarPecaEDoisToques…` falhou 1× na bateria. Com a CPU 4× mais lenta: o ajudante do teste esperava 80 ms DEPOIS do 1º toque terminar (145–183 ms) → 2º toque a 470–520 ms > janela de 420 ms; a base falha igual. O app usa `e.timeStamp` (não sofre isso no aparelho). Correção só nos 3 testes (intervalo contado do início do 1º toque), expectativas iguais · 9964d11, 596f7d6.
- **Passante (Code 2), crítico:** 2P+Gav Ext com passante: frente de gaveta virava 585×1944; dobradiça entrava na travessa. Enviado ao Code 2 com repro.
- **Preservação na atualização:** backup de referência rico gerado pelo editor publicado (tests/backup-referencia-rico); Android, iOS (iPhone e iPad) e Windows conferem os dois backups; `testProjetoGravadoPelaVersaoPublicadaAbreComOMesmoPlanoDeCorte` em toda CI; sonda s45 (139 projetos, corte igual contra as duas publicadas) · 843213f, d413b48.
- **Conferido sem defeito:** catálogo inteiro (142 modelos, 907 verificações) com portas/gavetas iguais por vão, sem sobreposição nem frente entrando na caixa, mm inteiro, DXF = lista; lado de abertura das portas; digitação (foco, décimo, vazio e texto inválido); abertura a frio 0,4 s (CPU 6×: 2,7 s); desempenho (draw 13 ms, 3D 23 ms, 2039 caixas) igual à base.

## PASSANTE-PONTA (auditoria técnica do Code 1 em ed041eb, 24/11)
- **Relatado:**
  1. Na torre "2P+Gav Ext 600mm" com passante, a frente de gaveta de baixo ia de 585 × 167 para 585 × 1944 e entrava nas portas no 3D.
  2. No "Balcão 2 portas", a dobradiça de cima subia com a porta e entrava na travessa frontal.
- **Causa raiz (`b1a167ba`):**
  - `pasAplica` esticava a 1ª frente de cada vão até a borda do módulo, mesmo com o vão longe da borda (gavetas embaixo das portas, nicho aberto acima, moldura do rack).
  - O furo da dobradiça (`p.fur.pos`) é medido da borda de cima da porta. A porta crescia em cima e o furo ia junto: 3D e DXF.
- **Correção:**
  - Só passa a frente da ponta: sem outra frente entre ela e a borda, e rente à borda. No catálogo as frentes das pontas ficam de −5 a 10 mm da borda; o rack com moldura fica a 32, o nicho aberto a 1053. O limite é 15.
  - A frente que não passa fica como estava e a nota diz por quê.
  - A porta que cresce em cima leva o furo junto (+d). Assim o copo fica no mesmo lugar da caixa, no 3D e no DXF.
  - No aéreo, que cresce embaixo, nada muda: o furo já ficava no lugar.
- **Não é defeito do passante:** as outras frentes de gaveta passarem de 167 para 181 (e a contra-frente de 66 para 99) é a regra de sempre de puxador sem cava. É igual com "toque" e "nenhum".
- **Teste:** `testPassanteCatalogoInteiroSoAFrenteDaBordaCresceDobradicaNoLugarE3DIgualCorte`. Percorre os 142 modelos e compara passante × toque nos 3 invariantes do Code 1, mais o caso da torre, a dobradiça × travessa e o DXF. Falha antes. Na mesma varredura achou também:
  - portas das torres de forno uma dentro da outra;
  - frentes das torres por vãos fora do corte.

  Passa depois: 168 frentes passam, 147 portas com furo no lugar, 0 em cada invariante.

## SANBASE (B25 / defeito 82, auditoria 24/11) e a regressão que a bateria pegou
- **Defeito:**
  - virar aéreo (sup) apagava a travessa;
  - voltar pra baixo não devolvia (sonda s05, "Módulo livre baixo · montar do zero").
- **Correção (`14ef6aac`):** o sanBase guarda `_travSB` quando apaga a travessa por ser aéreo e devolve ao voltar. Só pela troca de aéreo; módulo alto que fica baixo continua como antes.
- **Regressão no mesmo commit, achada na bateria completa do ramo de auditoria:**
  - o commit também "devolvia" travessa e moldura do rack suspenso sempre que as duas estavam desligadas;
  - isso religava a travessa de rack que não tem (Rack de TV erguido);
  - falharam `testBasculanteComCavaSemEngrossoFolga4NoTopo` (60 ≠ 4), `testMedidaDePecaSemDecimo…` (6315 ≠ 6308) e `testPlanoDeCorteTodaPeca…` (12844 ≠ 12836).
  - Bisseção pelos 5 commits: entrou em `14ef6aac`.
- **Correção da regressão:**
  - a parte do rack saiu;
  - o liga/desliga do "rack" da s05 não tem caminho pela tela (só o catálogo liga o rack), então ficou como era;
  - o teste passou a `testAereoIdaEVoltaDevolveATravessa`;
  - os 3 testes voltam a passar.
## VIS-MAT — acabamentos do 3D padrão (Adauto, revisão visual completa da biblioteca 3D, 24/11)
- **Pedido:** mais realismo nos acabamentos (metais, eletros, puxadores, pedras, madeira, estofados) sem pesar o app e sem mudar medida, geometria, posição, furação ou corte.
- **O que entrou:**
  - programa WebGL à parte (`__GPV`, e `__GPRV` no reflexo), com shader enxuto, só para as peças classificadas por `vizMat`;
  - **metal**: aspereza pelo acabamento do puxador (cromado 0, prata .12, dourado .2, inox .32, grafite .55, preto fosco .92…), reflexo do ambiente e dois brilhos;
  - **eletros** (geladeira, forno, micro-ondas, coifa, depurador, lava-louças, airfryer, churrasqueira, lixeira, TV): inox escovado; painel e vidro preto brilhante;
  - torneira cromada; perfil gola e alumínio anodizado;
  - **tecido** em sofá, poltrona e cama;
  - **veio** em mesa, cadeira e banco de madeira;
  - **pedra** da bancada com brilho de polida.
  - Sem textura nova: nenhuma imagem, nenhum arquivo, nenhum byte de download.
- **Fica igual:**
  - parede, piso, MDF dos módulos, foto do padrão, vidro e espelho;
  - o "Acabamento realista" (AQ), que tem caminho próprio.
  - O teste confere: pixel da parede igual, caixas do 3D com as mesmas coordenadas, peças e corte iguais.
- **Erros achados no caminho:**
  - 1ª versão com os ramos novos no shader comum: quadro de 113 → 176 ms (+55%) no renderizador por software (Windows sem GPU). Por isso o programa separado.
  - Coifa com pintinha de pedra: as faces laterais (`pfFill`) zeravam o tipo.
  - Cromado mais escuro que antes: ambiente baixo demais na metade de baixo da tela. Base recentrada em 1,0.
  - Tabela de aspereza vazia: `hex()` não é global e o `try` engolia o erro. Todo puxador caía no padrão .35. Agora com leitor de cor próprio.
- **Desempenho** (SwiftShader, pior caso, cozinha com 761 caixas, 10 rodadas alternadas):
  - quadro: base 130,7 ms → 135,6 ms (≈ +4%, dentro da variação de ±10 ms entre rodadas);
  - montagem: 5,7–9,3 ms nas duas;
  - heap JS: 15–18 MB nas duas.
- **Teste:** `testAcabamentoVisualMetalTecidoMadeiraPedraSemMudarGeometria`. Falha antes (`vizMat` não existe) e passa depois.
- **Capturas:** `diagnosticos/visual_materiais_3d_2026-11-24/` (antes em cima, depois embaixo).

## TESTE-2TOQUES-CARGA (pedido do Code 1, 24/11): `testPedraVistaDeCima…` e `testDoisToquesNaPontaDoTamponamento…` falharam na bateria de 430 do VIS-MAT e passavam sozinhos
- **Protocolo**, a 430, na base `ed041eb2` e no VIS-MAT `13bb4e47`, alternados:
  - 5× sozinhos;
  - 5× com os 30 testes anteriores da bateria;
  - CPU 4× (5×) e 10× (3×).
- **Resultado:**
  - CPU 4× e 10×: 0 falhas, nas duas versões.
  - Com vizinhos: a **base** falhou uma vez (`testDoisToquesNaPontaDoTamponamento…`, mesmo erro da bateria, `Cannot read properties of null (reading 'click')`: o menu de 2 toques não abriu).
  - A rodada 4 do VIS-MAT com vizinhos não vale: rodei uma sonda no mesmo navegador ao mesmo tempo ("socket is already closed").
  - **Não é o VIS-MAT.**
- **Causa (mesmo padrão que o Code 1 achou em 3 testes de 2 toques do 3D):**
  - o ajudante dos 2 toques esperava 120 ms **depois** de o 1º toque terminar;
  - com a máquina carregada, o tempo do 1º toque soma no intervalo e o 2º pode sair da janela de 450 ms do app;
  - no aparelho o intervalo vem do `e.timeStamp` do toque.
- **Correção, só no teste:**
  - o intervalo conta do início do 1º toque: `W(max(0, 120 − tempo do 1º toque))`;
  - as expectativas são as mesmas e nenhum limite aumentou;
  - os dois passam em 1366 e 430.

## DECISÕES DO ADAUTO 24/11 (itens 1, 2, 4, 5, 6, 8 e 9; Code 2, ramo `claude/decisoes-2411-code2`)
- **1 · forno/micro-ondas (`aac3afb5`):**
  - o 🗑 não tira "Corte do forno", "Nicho do forno (aberto)", "Corte do micro-ondas" nem "Nicho do micro-ondas (aberto)" sozinhos, e mostra o motivo;
  - tocar de novo em até 4 s tira o conjunto: no balcão o vão fica livre, na torre fica "sem", na torre por vãos sai o vão dele;
  - catálogo: 17 peças, 0 "só a peça".
- **2 · rodapé e travessa (`aac3afb5`, teste `2ee42fbc`):**
  - o 🗑 é o mesmo que desmarcar a caixinha do módulo, e as peças dependentes recalculam (base de cima, moldura e porta, como na caixinha);
  - a travessa que segura módulo sem base de cima não sai;
  - o teste antigo do 🗑 na travessa (regra de 17/11, "outras iguais") agora confere que as outras ficam **iguais às da caixinha**.
- **4 · dobradiça (`dcd57685`), só no 3D:**
  - o caneco ficava 1 mm dentro da peça que a porta cobre: 1178 partes em 74 modelos;
  - com a porta fechada, o caneco é cortado depois da montagem (`cupTrim`);
  - furação, medida e DXF iguais.
  - Achado: o caso "16 modelos na divisória" de 16/11 já não existia; o que restava era o caneco na lateral, na divisória e no montante.
- **5 e 8 · perfis × caixa (`0976fb27`):**
  - o rebaixo sai das caixas reais do 3D que desenham o perfil (`pxCarve`): o tamanho exato da parte do perfil em cada peça;
  - G: travessa 440 × 37 × 1,5 (a "pendência 1" da especificação). GV: travessa e base. Facetado: 300 × 10,5 × 10, mais as ponteiras;
  - a nota vai na peça (lista), a camada `REBAIXO_P…` no DXF, e a medida de corte fica igual;
  - móvel de antes (sem `rbP`): aviso e botão, nada muda sozinho;
  - varredura dos 9 puxadores × 142 modelos: 0 interseção nova (antes: facetado 236, G 549, GV 349, perfil 1).
  - `testPerfilGAfastamentoERebaixo…` passa de "entra 1,5 mm" para "entra 0 mm".
  - **Desempenho:** a 1ª versão montava o 3D dentro do `draw()` (desenho 11 → 37 ms). Agora o desenho 2D não monta o 3D, e lista/corte/DXF montam uma vez. Desenho e montagem ficam iguais à base.
- **6 · fita do aéreo:** sem mudança de código. Já resolvido: 0 de 1629 fitas dentro de porta ou frente; porta na posição de fabricação.
- **9 · curvos:** adiados pelo Adauto (checklist N25).

## CUSTOS FIXOS (pedido do Adauto 24/11, via Chefe; Code 2)
- **Pedido:** cadastrar custos fixos no orçamento.
  - Nome, descrição e valor; vários; recorrentes reaproveitados; editar, excluir, ativar e desativar.
  - Entram no valor sem duplicar. PDF discriminado ou embutido. Persistência.
  - Mais 5 garantias: biblioteca não mexe em projeto existente; R$ e %; base explícita; interno nunca aparece; a margem não muda.
- **Feito:** ver `DECISOES_TECNICAS.md` (24/11, custos fixos). Tela: Valores do projeto › "Custos fixos deste orçamento" e "Custos recorrentes (biblioteca)".
- **Conferido:**
  - Projeto sem custos: os mesmos números da versão de antes, até o float sem arredondar. Margem 2, campos antigos, desconto de 7% e valor fechado: `[889.6282213822807, 1145.1282213822806, 1064.97, 1064.97, "640.7/504.43", 3000, 3000]` nas duas.
  - PDF: embutido 773,43 + 608,94 = 1382,37; discriminado 577,61 + 454,76 + 350,00 = 1382,37.
  - Os testes "nada de enfeite" pediram resposta no toque da opção que já está escolhida (aviso curto).
- **Testes:**
  - `testCustosFixosAdicionarEditarDesativarExcluirRecorrenteSalvarReabrirEDuplicar`;
  - `testCustosFixosPdfDiscriminadoEmbutidoMesmoTotalInternoNuncaApareceNoPdfNemNoLink`;
  - `testCustosFixosSemDuplicidadeComCamposAntigosProjetoAntigoMesmoValorEBibliotecaNaoMudaProjeto`.

  Os três falham antes e passam depois.
- **Nota de ambiente:** `testDigitacaoTecladoFisico…` e `testMaoDeObra…` falharam no navegador de sondas (aba extra aberta toma o foco). Falham igual em todas as versões, inclusive nas que passaram na bateria. Num navegador novo passam.

## DECISÕES DO ADAUTO 24/11 — parte do Code 1 (ramo `claude/fechamento-code1`)
Pedido via Chefe: itens 3 e 7, arrasto confinado, B26, D23, o quarto item aberto e as 3 falhas de 430 da base. Cada um: teste que falha antes, família, projeto antigo intacto, sem limite aumentado.

### TOQUE-430 (falha de 430 da base: testSegurarOMovel2Segundos…) — erro comprovado, do app
- **Reproduzir:** 430×900, Planta com 5 módulos: o guarda-roupa (y 328–351) fica embaixo dos botões flutuantes 🔓 🗑 🧮 (até y 344) e não pega o toque ("sem módulo na planta").
- **Causa:** a margem de cima do desenho (OY 50 unidades) vale 21 px em 430 (0,42 px/unidade); os botões ocupam 42 px.
- **Correção (ed3571b):** `topoLivre()` mede até onde vão os botões; frente e planta descem só o que cabe no espaço vazio de baixo. Em 1366 a conta dá menos que a margem: nada muda (mesmas posições conferidas).
- **Teste:** o próprio `testSegurarOMovel2Segundos…` (falha antes em 430, passa depois).

### TRENA-ESCALA (falha de 430 da base: testTrenaNaParedeEsquerda…) — defeito do teste, com prova
- Texto da trena igual nas duas larguras ("820 mm", girado 90°, sem espelhar). Matriz na tela: [0, 0.423, −0.423, 0] em 430 e [0, 1.086, −1.086, 0] em 1366. A regra comparava |b| com 0,5 absoluto (depende de px por unidade).
- **Correção (d6d5c97, só teste):** mesma regra normalizada pela escala. Expectativa igual.

### LED-DENSIDADE (falha de 430 da base: testFaixaDoEspelhoLed…) — risco identificado (não é do app nos aparelhos)
- Com densidade 1 em 430×900 a faixa jateada tem ~1,3 px e some em 6 de 24 ângulos (12/24 no ponto exato; 18/24 lendo a largura da faixa). Com densidade 2 (todo celular; o iOS roda a mesma bateria a 430×900 com densidade 3) e em 1366: 24/24 em todos os casos. Sonda radial: a faixa está acesa nas 8 direções nas duas densidades.
- **Sem mudança no teste nem no app.** A bateria passou a aceitar a densidade (`--janela 430x900x2`, f23373b). Densidade 1 em 430 só existe em janela de computador estreitada: registrado como risco.

### FITA-BASE-MIRA (defeito 89) — decisão do Adauto 24/11: tocar na porta pega a porta; fita só no modo ▭ Fita
- **Antes:** fora do modo Fita, toque até 8 px da fita da base pegava a fita (mesmo em cima da porta).
- **Correção (ff41ff3):** `paintPick` fora do modo Fita devolve a peça (se o raio bateu na fita, a peça dela). No modo Fita nada muda. É o que o botão já dizia ("Fita desligado · o toque pega a peça inteira").
- **Testes (ec2296a):** `testFitaDaBaseEmbaixoDaPortaPintaPeloToque` ganhou a conferência sem o modo Fita (4, 12, 40 mm e meio da porta → Porta, sem oferecer fita; falha antes) e liga o modo Fita nas conferências de fita; `testCavaSemFaixaPreta…` idem. Expectativas mudadas por decisão (comentário no teste).

### ARRASTO-CONFINADO (B15 / defeito 45, parte do arrasto) — erro comprovado em 2D e 3D
- **Reproduzir (2D):** parede encolhida pra 800 (regra: o ambiente não mexe nos móveis); arrastar o balcão de 900 → ficava com 730 (`confine`: `m.w=room`). Com dois módulos e a parede encolhida, arrastar o que ficou fora → era puxado pra dentro por cima do outro (265..1195 sobre 150..1050) pelo `noOverlap('m')` do `snapMod` e pelo `confine` do desenho.
- **Reproduzir (3D):** o mesmo no soltar do arrasto do 3D (`tidy → noOverlap`, `confineAll`): 565..1465 sobre 5..905.
- **Correção (b1fa11e, 8b0bf44):** no arrasto do módulo (2D: `drag.t==='m'` no `S.m`; 3D: `window.__ARR` só durante o soltar) o `confine` não encolhe e trazer pra dentro da parede não pode sobrepor (fica onde estava). Fora do arrasto nada muda (criação e tamponamento que desloca a fileira: 5 testes conferidos).
- **Testes (bcd3603, afd988a):** `testArrastoFicaNoAmbienteSemMudarMedidaNemEntrarEmOutro` (balcão, gaveteiro, aéreo, torre, guarda-roupa; falhava em 4 das 5) e `testArrastoNo3DFicaNoAmbienteSemMudarMedidaNemEntrarEmOutro` (falha antes: "SOBREPÔS"). Família: 20 testes de arrasto passando.

### B26 (peça flutuante) — investigado: nenhuma peça de fabricação solta
- Sonda no 3D do catálogo inteiro (138 modelos, 15.654 caixas): toda peça de corte encosta em outra, no chão ou na parede. O que apareceu solto é desenho de eletro (moldura do forno/micro-ondas, `noCut`) e o cabideiro do "Armário sem laterais", que entre dois guarda-roupas se apoia nas laterais dos vizinhos (conferido).
- **Validação nova:** `testNenhumaPecaDeFabricacaoFicaSoltaNo3DEmTodoOCatalogo` (bcd3603).

### A31 — decisão do Adauto 24/11: altura da régua espaçadora do canto e do rodapé editável dentro do limite construtivo
- **Reproduzir:** régua (8 modelos): a seta de altura do 3D não mexia (a altura vinha sempre da porta; a régua é montada depois do passo que aplica o ajuste `po`). Rodapé (qualquer módulo com pedestal, inclusive "laterais até o piso"): a seta esticava só a peça (até 340), que entrava na base (100–115), e as portas ficavam iguais.
- **Correção (d51fa62):** régua: `poOne` aplicado nela; não sai do módulo; mínimo 50; corte acompanha. Rodapé: `rodPoFix` converte a seta de altura em `rodMm` do módulo (base sobe, portas e gavetas recalculam); limite = o que o app já exige pra caixa (folga + 3 espessuras + travessa + 60), mínimo 1. Só na ação da pessoa: projeto antigo não muda sozinho.
- **Teste (a22988f):** `testA31AlturaDaReguaEspacadoraEDoRodapePelaSetaDo3D` (falha antes nos dois).

### Quarto item aberto do checklist = defeito 45 (GEO-AVISA), parte "painéis até o teto" — depende do Adauto
- As 4 linhas ABERTO do checklist: B15, B26, D23 e o defeito 45 ("igual à B15"). Do 45 sobra o `wallFollow` dos painéis: mudar o pé-direito/parede muda a altura/largura do painel que ia até o teto/parede (com aviso "Parede mudou: N painel até o teto acompanhou").
- **Conflito de regras aprovadas:** a regra de 16/11 ("o ambiente não modifica os móveis") × pedidos explícitos em que o painel acompanha o teto e o gesso (`testRebaixoDoTeto…`, "o gesso morre na altura digitada e os painéis acompanham"). Não mudei: pergunta objetiva ao Adauto no relatório.

### D23 (identidade única de módulo e peça) — não feito nesta rodada
- Mudança de arquitetura (identidade persistente em editor, 3D, corte, duplicar, salvar/reabrir, desfazer e projeto antigo). Exige migração de dados com backup e teste de projeto antigo (§3). Não cabia com segurança nesta rodada; segue pendente.

### Vídeo do cliente na atualização (N13) — pedido do Chefe
- **Windows (70f7782):** coberto no CI (25a6867): win-166 gravou pelo seletor do editor, atualizou por cima, `video_*.json` igual byte a byte, o editor novo acha, lista e toca.
- **Android (dc4892b):** CDP no WebView do apk-660 (debug). 1ª rodada: botões em inglês no emulador (corrigido); 2ª: falha de infraestrutura (download do emulador). Reexecutado.
- **iOS (69aca94):** teste de interface montado só na compilação do simulador em cima de 3f1c3a58 (o app não muda). 1ª rodada: chegou à Fototeca e tocou na aba "Vídeos" do editor em vez do item do seletor (corrigido).

## A05-GIRADO (achado na bateria completa do ramo de decisões, 24/11)
- **Falhou:** `testMovelLivreNoMeioDaSalaGiraArrastaSalvaENaoMexeEmNinguem`, "3D fora" no giro de 180°. Passava na base.
- **Causa:** o recorte do caneco (`dcd57685`) corta no eixo x e no sentido da porta. No móvel girado (livre, ou na parede do lado), as caixas já estão giradas: o corte saía no lado errado e o contorno ficava fora do lugar.
- **Correção:** no móvel girado (`m.wing`) o caneco não é recortado. Lá fica como era antes (1 mm dentro da lateral, só no 3D).
- **Pendente (registrado):** recorte do caneco também no móvel girado. Teste do móvel livre e da dobradiça: ok em 1366 e em 430.

### Auditoria do Code 1 — CUSTOS FIXOS (Code 2, ca930f4; pedido do Adauto 24/11 + 5 garantias)
Sondas independentes (`pcfx1/2/3`), Chromium. Resultado: **nenhum defeito encontrado**.
- **Sem custo novo, mesmo valor (garantia 5):** cozinha de exemplo com preços de chapa, fita e dobradiça; 4 cenários (padrão, 3 campos antigos 350,55/120,33/77,77, margem 2,37, desconto 7,5%) — `sale0`, `sale`, total e itens do orçamento **idênticos** entre b9f4476 (antes) e a versão nova.
- **Centavos:** 6 custos (R$ 123,456 → 123,46; R$ 250; 7,33% dos materiais; 3,17% do preço com margem; 5,55% e 2,2% do valor final). Soma das linhas = total dos custos; valor = preço com margem + extras; os % do valor final batem ao centavo com o valor final (525,17 e 208,18), sem conta circular. Embutido = discriminado = 9.462,52 (soma dos itens do discriminado também); com desconto 8.752,83 nos dois.
- **Margem dos itens:** `sale0` igual antes e depois de pôr os custos.
- **Sigilo (garantia 4):** nome e descrição dos custos internos não aparecem no orçamento embutido, no discriminado nem no link do cliente (`clientPayload`). O CSV do editor é o do plano de corte (sem preço).
- **Biblioteca (garantia 1):** mudar o valor na biblioteca não muda o orçamento que já tem a cópia.
- **Salvar/reabrir/desfazer/desativar:** reabrir pelo estado salvo dá o mesmo valor e os 7 custos; Desfazer tira o custo; desativar tira o valor (e os % do valor final se recalculam).
- **Limite:** % do valor final somando ≥ 90% → aviso e esses custos não entram (observação: todos os de % do valor final saem juntos, com aviso na tela).
- **430×900 (densidade 2):** tocar em "+ Adicionar custo fixo", digitar "150,75", Salvar — campos visíveis, valor certo, gravado no projeto.
- **Não verificado nesta sonda:** botão Duplicar clicado (o custo está no estado salvo do projeto, que é o que a duplicação copia); PDF renderizado em aparelho.

## D23 · IDENTIDADE ÚNICA (Code 2, 24/11; ramo `claude/d23-identidade` a partir de `claude/fechamento-code1`)
- **Feito:** ver `DECISOES_TECNICAS.md` (24/11, D23).
- **Conferido:**
  - **s45 (139 projetos gravados pela publicada `3f1c3a58`):** corte igual em todos; lista igual em 138. A diferença conhecida é a cozinha de exemplo (rodapé lateral do encontro, FASE2), a mesma de antes.
  - **Editor PUBLICADO (`3f1c3a58`) abrindo projeto com `uid` nos módulos:** 142 modelos; peças e corte iguais com e sem `uid`; o `uid` continua depois do `snapState` dele; 0 erros (roteiro em `diagnosticos/d23_identidade/publicado_abre_uid.js`).
  - `testAbrirProjetoSemMexerNaoRegrava…`, `testProjetoGravadoPelaVersaoPublicada…`, plano de corte, histórico, Meus modelos e backup: ok.
- **Achado no caminho:** abrir projeto com id repetido. O `loadState` desenha por dentro e o `stkSync` trocava o id da 2ª cópia sozinho. Agora o id repetido que vem do arquivo fica, com aviso.
- **Teste:** `testIdentidadeUnicaModuloEPecaMesmaChaveNo3DListaCorteEDxfCopiaSalvarDesfazer`. Falha antes, passa depois.

- **Atualização (Chefe, 24/11):** o pendente de cima foi resolvido.
  - Juntei o MOVEL-GIRADO do Code 1 (`78e7d62`: no módulo girado, o corte vai no eixo da largura da porta, do lado oposto à peça que encosta).
  - O contorno do caneco (`pf.pts`) agora também é cortado no mesmo eixo. Antes, a 90° e 270° só a borda era cortada.
  - A trava de `a79780b7` (sem recorte no móvel girado) saiu.
  - Varredura de 81 modelos com porta × (livre a 0/90/180/270° + paredes esquerda e direita) = 486 cenas: 11.404 → 0.
  - `testMovelLivre…`, `testCanecoDaDobradicaIgualEmQualquerParede` (do Code 1) e `testDobradicaNoMovelGiradoENasParedesLateraisVarreduraZeroInterseccao` passam juntos.
- **Custos fixos × link do cliente (Chefe, 24/11):** o link do cliente não leva valor nenhum, nem total (é assim desde antes: "ele só vê, não vê valores").
  - Não existe total do link para divergir.
  - O teste confere: tela = PDF ao centavo, com e sem desconto, embutido e discriminado, com custos internos R$ e %. E o link sem preço, desconto, custo ou total.

- **Bateria completa do `d687d0a9`:** 1366 527/528 e 430 526/528.
  - A falha nova nas duas foi `testMoverNo3DEncaixaNaParede…` ("vizinho mudou"). O teste comparava o vizinho da cena 5 com o da cena 1. Com o D23, cada módulo novo tem o seu id, então o vizinho de outra cena nunca é igual.
  - **Correção, só no teste:** o vizinho é comparado com ele mesmo, na mesma cena, antes e depois do encaixe. É a intenção do teste ("sem mexer em ninguém"), igualmente estrita.
  - O outro de 430 (`testFaixaDoEspelhoLed…`) é da base.

## INTEGRAÇÃO FINAL DO CODE 1 (24/11, ramo `claude/fechamento-code1`)
- **Juntado e auditado:** decisões do Code 2 (`7d257c1`, `3ae2216`), D23 (`e6e95ba`), giro do caneco + contorno (`c0865d3` e correção), teste do vizinho (`dae8a33`).
  - No merge do `33b6512` o editor veio inteiro do outro lado e perdeu correções minhas (4 testes vermelhos). Refeito: o meu editor + só o bloco do contorno `pf.pts` do Code 2. Sem teste repetido.
  - Teste do vizinho (`d0a715db`): compara o mesmo módulo, na mesma cena, antes e depois. Mesma força do anterior.
- **FASE4 (achado na bateria 1366 do `78e7d62`, 526/527):** `testFASE4_EspelhoNaParede…` falhava às vezes. O botão de minimizar do painel (`qmn`) só aparece no quadro seguinte ao abrir. O teste perguntava no mesmo quadro (diagnóstico: `qmn 0→1`).
  - **Correção, só no teste (`3dbbd50`):** espera 2 quadros depois de abrir. A expectativa (37) não mudou. Não foi aumento de tempo limite.
- **Baterias completas, editor `7835d4b390bd` (= HEAD), Swift do `3dbbd50`:** 1366 528/529 e 430 528/529.
  - A única falha nas duas é `testMoverNo3DEncaixaNaParede…`, da versão do teste anterior ao `d0a715db`.
  - Rodado de novo no HEAD, junto com FASE4, caneco, giro e D23: 11/11 em 1366 e 11/11 em 430.
- **Vídeo na atualização do iOS: coberto em 25/11 (`02e5269`, run 27).** iPhone 17 Pro Max e iPad Pro 13 (iOS 26.5, simulador). O app não mudou em nenhuma rodada: só o teste.
  - Causas no teste, achadas rodada a rodada pelo log:
    1. O seletor do iOS 26 abre com o aviso "Location Is Included · Learn More…" por cima da grade. O teste tocava no ícone do aviso (`PickerOnboardingHeaderViewIcon`). Agora fecha no "Close".
    2. A miniatura do vídeo (seletor = outro processo) não é "hittable". O toque vai pela posição.
    3. No iPad o seletor abre nos álbuns. O teste abre o álbum "Videos" do seletor.
    4. `isHittable` num elemento sem área dá erro do XCTest. Só pergunta a quem tem área.
    5. O teste do editor novo abria em `.nonPersistent`, onde o vídeo restaurado não chegava ao banco do editor. No Chromium o mesmo caminho acha o vídeo em 315 ms. Agora usa um armazenamento de verdade, novo e vazio, como o app.
  - Resultado nos dois: a versão publicada gravou pelo seletor (`video_*.json`), 12/12 arquivos iguais depois da atualização, o editor novo acha o vídeo igual byte a byte (sha f1723490…) e toca ("tocou até 0,78 s de 2,00 s"). Falhas 0.
- **Android e Windows no editor final (`7751eeb`):** apk-660 → 90031, falhas 0, vídeo igual byte a byte e tocando; win-166 verde.
- **Aparelho real: não testado.**

- **Vídeo na atualização do iOS: ainda não coberto.**
  - Dados: iPhone e iPad iguais (8/8 e 4/4), projetos abrem iguais.
  - Vídeo (run 19, `ee1e152`): iPhone e iPad chegam ao seletor e tocam no vídeo. O seletor fecha, mas o editor publicado não grava (nenhum `video_*.json`).
  - Causa ainda não comprovada. Hipótese: o `app.tap()` no meio da tela fecha o balão do iPad antes da escolha.
  - Rodada `7751eeb`: sem esse toque, com a tela registrada no seletor aberto e depois do toque.
- **FUNDO-15 (Code 2, 24/11), achados durante o trabalho:**
  - 1º aviso de vizinho pegava a maior entrada entre peças. A porta (cerca de 15 mm na frente) já encostava antes, e isso escondia os 9 mm novos da caixa. Corrigido para o contorno do módulo (com as portas), só entre paredes diferentes ou com o canto, com "antes X mm" no texto.
  - 1º aviso de pedra disparava na cozinha de exemplo. Mas a pedra encaixada acompanha a frente sozinha (regra de hoje, `stFitCalc`/`stFitEq`, igual na base `553745a1`). Agora só avisa da pedra que a pessoa deixou com medida própria, e a prévia mostra a pedra encaixada que acompanha (606 → 615).
  - O nome do módulo no aviso vinha "Módulo N": `modLabel` está fora do escopo global. Passou a usar o mesmo nome da lista de corte.
  - Ambiente: o servidor local foi bloqueado pela permissão desta sessão. Bateria, s46 e PNGs rodaram com o editor aberto por file:// (mesmo arquivo).
- **ZOOM-CORTE e CORTE-LEGÍVEL (Code 2, 24/11), achados durante o trabalho:**
  - O zoom pela roda andava 0,4 px do cursor a 430: a conta usava a caixa do SVG com a borda de 6 px. Passou a usar a transformação real (`getScreenCTM`). O teste mede em pixels da tela (1 px).
  - O zoom se perdia quando o plano se redesenhava sozinho (o otimizador termina 1 a 2 s depois de abrir). Agora o zoom de cada chapa volta no desenho novo (com assert no teste).
  - `sheetPlan(1)` muda sozinho logo depois de abrir o plano (o rápido e depois o otimizador fundo), e o desenho grava `no` nas peças do cache. Isso já era assim antes. O teste espera o plano parar e compara sem o `no`.
  - Na 1ª versão da conta, 103 textos ficavam em cima de outro texto (número da sobra deitado × em pé; "furo dobradiça" × nome da porta). Corrigido e incluído no teste.
  - 45 peças muito estreitas (réguas, molduras de 30 com fita) ficavam sem nada legível dentro. Ganharam etiqueta ao lado, com linha.
  - Bateria: o Chromium da bateria parou no limite de 30 min do segundo plano (eu não tinha dado tempo maior). A rodada de 1366 do `f66075bf` parou em 228 ok, 0 falha real. Refeita no SHA final com o navegador no limite de 2 h.
- **Conta da legibilidade ampliada (ordem final do Adauto: "nenhuma linha sobrepõe ou esconde medida"):** passou a valer para toda linha do desenho, não só a fita. Isso pegou 258 casos: furos da dobradiça/sistema 32 debaixo do #n e das medidas; linha da etiqueta passando por cima de outra peça; número da sobra. Correções:
  - furos e linhas da furação/recorte são obstáculo pros textos;
  - a linha da etiqueta procura caminho livre e, sem ele, vai por baixo das peças (o fundo opaco da peça cobre);
  - número da sobra com halo da cor do fundo da chapa;
  - #n da peça com recorte em plaquinha branca;
  - o bloco do meio do recorte encolhe quando o recorte é baixo (só aparecia no PDF).
  - A conta do contorno tracejado do recorte passou a olhar segmento por segmento (antes tratava o retângulo como cheio).
- **Veio:** com caixa amadeirada e veio, os fundos altos (torre e guarda-roupa) não cabem sem girar e ficam como "maior que a chapa", fora da contagem. É igual às portas altas na cor, que já ficavam assim. Não mudei a regra do veio; pergunta enviada.
- **Ampliar (achado pelo Chefe no 94a5f412):** eu tinha trocado os níveis do Ampliar (60–1600%, passos de 25/50) pelos do motor novo (100–1200%, ×1,25). Era perda de função (§0). Os níveis de antes voltaram, ligados ao motor novo. Também: chapa ampliada no plano ia ampliada pra impressão. Agora imprime a chapa inteira e o zoom volta depois. Os dois casos estão no teste.
- **ORC-AMB (Code 2, 25/11):**
  - Na 1ª versão, uma chave repetida no objeto do ambiente fazia a descrição dos móveis sair com o número do desconto. Corrigido e coberto pelo teste.
  - No teste da bateria, a ponte do navegador não pode ser trocada; os métodos do app simulado entram no objeto que já existe.
  - Ambiente: o Gradle local não baixa as dependências (Maven Central 429, Google Maven bloqueado pela rede). Os testes nativos vão pelo CI.
- **DESC-CENTAVO, defeito (achado pelo Code 2 em 25/11; o Chefe classificou como defeito; Adauto: "corrija todos os erros", "tela = PDF ao centavo"):**
  - Sintoma: o valor com desconto podia diferir 1 centavo entre a tela do editor e o PDF do app. Exemplo: R$ 830,55 com 10% dava 747,50 na tela e 747,49 no PDF.
  - Causa: duas contas para a mesma coisa.
    - Tela (vlFin): arredondava valor × (1 − d).
    - App (QuoteMath, o documento do cliente): desconto arredondado em centavos, depois valor − desconto.
    - Na varredura de R$ 0,01 a 1.000,00 × 1..50%, as duas divergiam em 135.928 de 5.000.000 casos.
  - Correção na causa, uma regra só: `descAplica` (a do QuoteMath), usada na tela e nos ambientes do orçamento de vários ambientes. Sem 2ª conta.
  - O que não muda: orçamentos e PDFs já salvos (o app sempre usou a regra do QuoteMath). O orçamento individual dos 141 projetos da s45 sai igual.
  - Testes:
    - `testDescontoDoProjetoTelaIgualAoPdfAoCentavo…` (bateria; falha antes);
    - `QuoteAmbientesTest.descontoUmaRegraSo…` (JVM);
    - `CoreTests.testDescontoUmaRegraSo…` (iOS);
    - a mesma soma da varredura nos três: 186.251.793.425 centavos.
  - Expectativa alterada com o pedido e a data no comentário: `testMaoDeObra…` (descontoDe10: de valor × 0,9 para a regra do PDF).
- **ORC-AMB, bateria de 430 (41a0842d):** `testNadaDeEnfeite3DEValoresParteB…` achou a caixinha da lista de projetos sem efeito visível (marcar só valia ao tocar em "Adicionar os marcados"). Agora o botão conta os marcados ("Adicionar 2 marcados"). Teste sem mudança; 10/10 em 1366 e 430.

## AUDITORIA DO CODE 1: FUNDO 15, ZOOM E LEGIBILIDADE DO PLANO, ORÇAMENTO DE VÁRIOS AMBIENTES (25/11, Code 2 até `4f60b3e`, juntado em `b0143b7`)
Sondas independentes em `scratchpad` (Chromium). Editor de antes = `553745a1`.

- **Fundo 15 nos 139 modelos do catálogo** (fundo 6 → 15 pelo botão):
  - Nos 135 que não são de canto, nenhuma peça interna muda, as medidas externas ficam iguais e o fundo atrás vai de 6 → 15 (D = d + fundo). **Correto.**
  - Nos 4 de canto em L (aéreo e guarda-roupa, esquerdo e direito), a medida externa fica igual e todas as peças de dentro que mudam perdem exatamente 9 mm (opção A do Adauto).
  - Exceção: os tamponamentos do guarda-roupa de canto crescem 9 mm (581 → 590) pra cobrir a profundidade maior. É a regra do canto de antes, igual em `553745a1`.
  - Nos módulos comuns, o tamponamento só acompanha o fundo com o ajuste `tpFundo` ligado (+9 em balcão, guarda-roupa e canto, igual ao editor de antes). Sem ele vale d + avanço, como sempre. **Correto.**
- **Projeto antigo com fundo de 15 ou 18 mm digitado** (o campo numérico já existia):
  - Total, peças, corte, plano e DXF iguais ao editor de antes.
  - Muda só a divisão do valor entre os módulos (ex.: 291,04/143,99 → 260,05/174,98), porque o fundo passa a contar como chapa da caixa, que é onde o plano já o colocava.
  - Orçamento salvo (cópia no app) não muda. **Risco identificado, sem perda.** O total do cliente é o mesmo.
- **Veio:**
  - Com veio e caixa amadeirada, 0 peças com veio giradas.
  - **Erro pré-existente comprovado, igual em `553745a1`, que o fundo de 15 aumenta:** com a chapa padrão 1840 × 2750, o comprimento da peça vai no lado de 1840. As peças altas (portas de 2300 e, com o fundo de 15, fundos de 2200/2400) ficam em "maior que a chapa", fora do plano e da contagem de chapas do orçamento.
  - Regra de cálculo: **não mudei**, depende do Adauto (§5).
- **Orçamento de vários ambientes:**
  - A conta da tela (`orcTotais`/`descAplica`) e a do app (`QuoteMath.kt`) são iguais: desconto do ambiente em centavos → subtotal → desconto geral em centavos, mesma ordem e mesmo arredondamento.
  - Calcular outro ambiente não muda o projeto aberto (estado, seleção, CUR, `__edited`) nem a lista de projetos.
  - A única gravação no período (aprendizado do projeto aberto, `brain`) acontece igual sem o cálculo. **Correto.**
- **Testes:**
  - `testMaoDeObra…` (`descontoDe10`): a nova expectativa é a regra do PDF, não ficou mais frouxa.
  - O teste dos custos fixos ainda conferia `base × 0,9`. Trocado pela regra do PDF, escrita sem a função do editor (`2d86496`). Passa.
- **CI:** os pacotes de teste agora ficam só como artefato do Actions (sem release pública). A trava de publicação não mudou.
- **Baterias completas, editor `639199fa`:**
  - 1366: 538/538.
  - 430: 537/538. A única falha é `testFaixaDoEspelhoLed…`, só na densidade 1; 3/3 a 430 × 2.
- **CIs no SHA juntado `2d86496` (25/11):**
  - Android CI, Windows CI e os 3 testes de atualização (Android, Windows, iOS iPhone + iPad, com vídeo): verdes.
  - **iOS CI 690: vermelho.** Duas falhas, repetidas duas vezes cada:
    1. `testNadaDeEnfeite3DEValoresParteB…`, no iPhone e no iPad. No 688 (`41a0842d`, Code 2) a mensagem foi: a caixinha de marcar ambiente (`#orcamb [data-oapk]`) e os campos Nome/Descrição do custo fixo (`#cfxform [data-cfxi]`) "não fazem nada".
    2. `testPlanoDeCorteLegivel…`, só no iPad. No 688: "641" e "125" da contra-frente do caixote (641 × 125, guarda-roupa 4 vãos) cruzam o contorno da peça.
  - Nos dois casos passa no Chromium, inclusive no tamanho do iPad (1032 × 1376, ×1 e ×2). A diferença é do WebKit. **Erro comprovado no iOS, causa não identificada** (sem WebKit no ambiente do Code 1).
  - As duas baterias do iOS também estouraram o limite de 75 min do passo, então parte dos testes não rodou no 690. Não aumentei o limite.
- **iOS CI no 41a0842d:** os testes de unidade passaram (146, 0 falhas), incluindo o orçamento de vários ambientes e o desconto (mesma soma da varredura). Na bateria do editor, duas falhas:
  - `testNadaDeEnfeite3DEValoresParteB…`, no iPhone e no iPad:
    - a caixinha da lista de projetos não mudava nada visível (corrigido no 4f60b3ed: o botão conta os marcados);
    - os campos Nome e Descrição do custo fixo também não mudavam nada visível. No Chromium passava; no WebKit não. Agora o botão Salvar mostra o que vai ser salvo enquanto se digita.
  - `testPlanoDeCorteLegivel…`, só no iPad, nas duas tentativas. O catálogo inteiro num teste só leva 35 s no iPhone, e a mesma rodada mostra outro teste longo estourando o limite de 2 min. Foi dividido em três terços, como os outros testes de catálogo inteiro. Nenhuma expectativa de zero mudou; só os mínimos de cenas/peças/textos de cada parte.
- **iOS CI 689 no 189feb04 (25/11):** os testes de unidade passaram (146, 0 falhas). No iPhone, Nada de enfeite e os três terços de `testPlanoDeCorteLegivel…` passaram. Dois achados:
  - **iPad, `testPlanoDeCorteLegivel…SegundoTerco`, nas duas tentativas.** Não era tempo, como suposto no 688: é defeito. No Guarda-roupa 4 vãos (2 cabideiros + torre de gavetas), chapa 2, os textos "641" e "125" da peça Caixote · gaveta · contra-frente/traseira 641 × 125 cruzam o contorno da peça (6 casos).
    - Aqui não reproduz: Chromium com tela do iPad 1024×1366, CPU até 8× mais lenta, tempo do arranjo rápido simulado de 1 a 400×, e as duas orientações com todas as fitas dessa peça (folga mínima de 5 unidades).
    - Hipóteses ainda abertas: arranjo diferente no iPad, métrica do texto no WebKit ou a conta de tela do WebKit.
    - A mensagem de falha agora traz a geometria exata (fonte, posição, caixa do texto, peça, viewBox, largura na tela e zoom), pra corrigir a causa no próximo iOS CI. A expectativa de zero não muda.
  - **iPhone, `testRebaixoDoPerfilGGola…`:** a varredura dos puxadores × catálogo levou 166 s, acima do limite de 2 min (aqui leva 42 s). Dividida em três terços, como os outros testes de catálogo inteiro: cada terço exige mais de 43 modelos, juntos mais de 130 como antes. As conferências do G, gola, facetado e móvel de antes ficam no 1º terço, iguais. O Chefe aprovou a divisão em 25/11.
- **Rodada seguinte (25/11), Code 2 juntado até `ed6b650d`, editor `555deaba`:**
  - Baterias do editor: 1366 542/542. 430 540/542:
    - LED na densidade 1, o caso de sempre.
    - `testNo3DDuplicarPeca…`: instável, causa comprovada. Passa 5/5 isolado. Com a CPU 4–6× mais lenta, o teste perde o toque duplo, porque os toques que ele cria por código saem com mais de 420 ms de intervalo. O editor mede pelo `e.timeStamp` do toque, certo para o toque real. **Não é defeito do app; teste não mudou.**
  - Android CI, Windows CI e atualizações do Android e do Windows: verdes.
  - Atualização do iOS (iPhone e iPad, com vídeo): verde no run 33 (`4c879a79`), depois de corrigir só o teste de interface:
    - rolagem na direção do botão (página rolada pra baixo);
    - espera pelo editor da versão publicada;
    - toque pela posição (`isHittable` falha no WebKit);
    - álbum "Videos" no iPad.
  - iOS CI 692 (`7f1d9fb`):
    - "Nada de enfeite" resolvido pelo Code 2.
    - **Abertura do iPhone 10,36 s.** Os 47 s do 690 eram do ambiente: mesmo app, e no run 29 até a 3.0.13 publicada demorou a abrir no mesmo tipo de runner.
    - **Continua aberto: legibilidade no iPad** ("641"/"125" da contra-frente do caixote, guarda-roupa 4 vãos). Correção com o Code 2.
    - As baterias cortaram no limite do passo (o Code 2 subiu o do iPad para 100 min em `8b8e444c`).
- **`testFaixaDoEspelhoLedApareceDeLongeEEmAngulo` a 430×900 (pior 12 a 13, esperado ≥ 20), 25/11, pendência do Code 1 assumida pelo Code 2.** A causa é a amostragem do teste, não o app.
  - A 430 o espelho de 700 mm aparece com ~60 px e a faixa jateada de 40 mm fica com 2 a 3 px.
  - Em todos os pontos que falhavam há pixel aceso da faixa a 1 px, às vezes pra dentro, às vezes pra fora: é o arredondamento da projeção, não deslocamento da faixa.
  - Nas capturas ampliadas (/tmp, 430 e 1366) a faixa aparece contínua.
  - Correção no teste:
    - cada ponto conta se ele ou um vizinho a 1 px estiver aceso;
    - os mesmos 24 pontos, as mesmas câmeras e qualidades, dia e noite;
    - o limite ≥ 20 não muda.
  - Prova de que o teste continua pegando o defeito: com a faixa desligada no app, dá 0 de 24 a 430 e a 1366.
  - Antes: 12–13 a 430 (falha). Depois: passa a 430 e a 1366, e os 15 testes de espelho passam nos dois tamanhos.
  - Visto de passagem e NÃO alterado: a linha de contorno escura do vidro de dentro passa na borda interna da faixa e, de longe, come parte dela. A faixa é jateada no mesmo vidro, então essa linha não existe de verdade. Fica registrado como possível melhoria.

## REVISÃO DO CODE 2 NAS CORREÇÕES DO CODE 1 (25/11 tarde): achados e correções
- **A31, três defeitos comprovados.** Teste `testA31ReguaNaoSai…` (`7ad4af82`), que falha antes nos três; correção `87b0e9ec`.
  1. Régua encurtada até o mínimo de 50 saía do módulo (50 em 747 num aéreo de 750). Causa: o mínimo era aplicado depois do limite do topo.
  2. Rodapé pela seta chegava a 630 num balcão de 820, dentro da lateral de gaveta. Causa: o limite só via folga + espessuras.
     - Agora inclui a régua do aéreo (regra do `sanM`).
     - Subindo, o rodapé para antes de entrar em outra peça do módulo, pela geometria do 3D.
  3. **Projeto antigo mudava** (rodMm 100→160, portas 705→645) ao mexer na seta da porta. Causa: `rodPoFix(m)` convertia todos os rodapés do módulo. Agora `rodPoFix(m,K)` só converte a peça do gesto.
  - Conferido também pelas sondas s48 do Claude 3 (projeto antigo mexendo na lateral: igual; limites no catálogo: nada entra).
- **TOQUE-430 parcial, comprovado:** na cena funda, 12 de 35 pontos do móvel caíam embaixo de 🔓🗑🧮. Teste `testPlantaFunda…` (`db9b0de5`), que falha antes; correção `87b0e9ec`.
  - Causa: a planta só descia no espaço que sobrava e a escala era fixa (440).
  - Agora desce até sair dos botões e a escala diminui só o que faltar (`window.PLH`); com espaço sobrando, igual a antes.
  - Na sonda do Claude 3 (paredes de 3000 a 8000), nenhum ponto nos botões. Os pontos que não pegam o móvel caem no fundo da planta, fora do desenho dele.
- **B26:** nenhuma peça de fabricação solta (138 modelos; 690 variações do Code 2). O caso do Code 2 (altura × 0,75, 2 mm) é o desenho da dobradiça. Ela é ferragem desenhada e as partes se chamam "Porta", presas na lateral pelo braço. **Risco baixo, sem correção.**
- **Vídeo na atualização:** verde no HEAD do teste (run 33, `4c879a79`). Depois disso o editor mudou: nova rodada no SHA final.
- **Baterias, editor `21470d8d`** (`d29d3d44`: A31/TOQUE + LED 4fb5695a + liberdade 257195a8): 1366 546/547 e 430 546/547.
  - A única falha nas duas é `testNichoDaParedeDoLado…` ("campoX 100, esperado 1300"). Vem do ramo da liberdade de composição: falha igual no editor dele sozinho e passa no `450ec24b`.
  - **Achado para o Code 2:** a medida digitada que entra no vizinho já fica aplicada ANTES da resposta à pergunta (x = 100 com interseção). Se a pessoa sair sem responder, a sobreposição fica sem confirmação.
  - O teste não está na lista de expectativas que o Code 2 avisou que mudaria.
- **iPad, `testPlanoDeCorteLegivel…SegundoTerco` (iOS CI 694, 25/11): causa achada e corrigida.** A mensagem com a geometria mostrou o seguinte:
  - No iPad o texto "641" (fonte 28,5) tem caixa de 40,1 de altura e subida de 32,8 acima da linha de base, ou seja 1,15 da letra.
  - O plano reservava 0,95 de subida e 0,26 de descida, então o número da peça estreita (Caixote 641 × 125) passava 0,7 do contorno.
  - O iPhone passa porque o WebKit em modo celular usa outra "sans-serif"; o iPad abre em modo computador. No Chromium (Android, Windows) a fonte mede 0,91/0,22.
  - Correção pela causa: `cpMet()` mede uma vez a subida e a descida da fonte de verdade do aparelho e o plano usa a maior entre a medida e a de antes. No Chromium o plano fica idêntico.
  - Com as medidas do iPad forçadas no Chromium, os três terços dão 0 cruzamentos e 0 peças sem identificação, a 1032×1376 e a 440×956.
  - No mesmo commit, o mínimo de cobertura dos terços foi corrigido (o Chefe achou afrouxado): >33/>333/>1666 por terço, que somam o >100/>1000/>5000 do teste inteiro de antes. Medido aqui: 47/1082/4459, 47/1436/5948 e 49/1541/6549.
  - iPhone 694: `testTomadasRegistro…TVComLogo` e `testToqueNoVaoComoNoIPhone…` (editor demorou mais de 60 s pra abrir) falharam na 1ª tentativa e passaram na repetição. É intermitente do simulador, fora destas mudanças.
- **iPad, `testPlanoDeCorteLegivel…SegundoTerco` (iOS CI 697, 25/11): a correção do 694 não chegou no iPad.**
  - A geometria da falha é idêntica à do 694: o "641", com fonte 28,5, tem a caixa em y 1582.8 e a peça começa em 1582. Ou seja, o plano continuou com a métrica de antes (0,95/0,26), e o `cpMet()` não valeu no iPad.
  - Causa provável: a medida não deu caixa (página ainda escondida ou sem layout) e o resultado vazio ficou guardado.
  - Correção:
    - Sem medida, nada é guardado e o plano usa a métrica alta conservadora (1,16/0,30), que cobre a do iPad (1,15/0,30). A próxima chamada mede de novo.
    - Com medida, fica igual a antes: no Chromium o plano é idêntico, os 22 testes de plano passam a 1366 e a 430, com `__cpMetInfo.ok` = 2.
    - No Chromium, com a medida forçada a falhar, os três terços passam a 1032×1376 e a 440×956.
  - A mensagem de falha dos três terços agora traz `__cpMetInfo` (mediu ou não, quantas vezes) e a métrica usada, pra confirmar no próximo iOS. As expectativas não mudam.
  - iPhone 697: `testSalvarSozinhoSoGravaQuandoMudaERespondeRapido` falhou com o editor levando 24 s pra abrir (no mesmo log, outro teste levou 43 s). É lentidão do simulador, a conferir no próximo iOS.
- **SHA final em teste: `b4a45134`** (editor `ac9d8eda`: + iPad legível `23acd260` + liberdade de composição `aae4ef93`).
  - Baterias do editor: **1366 547/547 · 430 547/547**.
  - Android CI, Windows CI e atualizações do Android e do Windows (com vídeo): verdes.
  - **Abertura lenta do iPhone, causa comprovada:** no 695 a 1ª abertura deu "página começou em 42,97 s · editor sozinho 13,30 s". Noutro teste: página 43,52 s, editor 1,99 s.
    - A demora está antes do editor: o simulador frio subindo o processo da página (WebContent).
    - O mesmo app abriu em 10,4 s no 692.
    - **Ambiente, não regressão.** Aquecimento do simulador do iPhone no `ios.yml` (`4b7ade52`), como no iPad; nenhum limite muda.
  - **89b ("só a fita, sem a peça atrás") não reproduz.** Sonda nos toques de fita em 5 modelos, bordas e cantos, a 1366 e 430: 0 de 855 escolhem a fita fora do modo Fita.
    - Controle: com o modo Fita, 855 de 855.
    - **Comportamento correto.**
  - O teste do nicho (`testNichoDaParedeDoLado…`), que o ramo da liberdade quebrava, passa no `aae4ef93` sem mudança no teste: o Code 2 corrigiu o comportamento.
- **iOS CI 696 (`b4a45134`):**
  - iPhone com aquecimento: 1ª abertura 9,21 s (página 5,33 s, editor 3,88 s). A lentidão está resolvida.
  - iPad: bateria completa, 628 testes. As 4 falhas são `testPlanoDeCorteLegivel…SegundoTerco` (2 testes × 2 tentativas): "641" a 0,8 do contorno, com a correção do Code 2 (`23acd260`) junta.
  - O iPhone parou de novo no limite de 75 min do passo, com a bateria incompleta (só o iPad tem 100 min autorizado).
- **CORTE-LEGÍVEL no iPad, causa comprovada e corrigida:** teste `testEtiquetaDeMedida…`, que falha antes; correção `c1682687`.
  - As etiquetas vermelhas de medida das sobras ficavam em y+fs+4 e x+fs+2, conta da fonte do Chromium.
  - Agora usam `max(1, cpMet().AS)`, na posição, na faixa de cima e no espaço reservado pros nomes. No Chromium a conta é idêntica.
  - Plano de corte e sobras: 48/48 a 1366 e a 430. **Falta conferir no iPad real do CI.**
- **Atualização do iOS:**
  - Run 33 (`4c879a79`): verde.
  - Run 34 (`b4a45134`): iPad verde; no iPhone o seletor fechou e o vídeo não chegou ao editor publicado. Instável, causa não comprovada (sem o log do simulador).
  - Run 35: cancelada na fila (sem máquina Mac).

## UNIDADE (25/11): unidade de medida mm/cm nos Ajustes (pedido do Adauto, via Chefe) — Claude 4
- **Pedido:** escolher mm (padrão) ou cm nos Ajustes do app; vale no editor (2D, Medir, campos), lista de peças, plano de corte, documentos impressos e nota nova do caderno. Internamente tudo em mm.
- **Onde:** `editor.html` (script UNIDADE logo depois do de idioma: `UN.num/len/parse/u`, campos de medida com sufixo, rótulo "Cotas em …"); teclado do app (`V/SV`: o teclado mexe no texto do campo, quem lê o `.value` recebe mm); **conversão só na origem** (decisão do Chefe 25/11: nada de converter por padrão de texto, nem no DOM nem na saída do SVG): 129 pontos — dimH/dimV/dimS, cotas `qtx` da vista de frente, cpTxt (dW/dH), medSeg, sobras do plano, totais/vão livre/janelas/eletrodomésticos/pedra/cuba, planta, corte lateral, prévias dos Ajustes, dimf e cabeçalhos "Comp × Larg (un)", chapa/sobras, módulo/parede, gaveta, vão, tamponamento. Nativo: `UnitPref` em `Units.kt` (Android e Windows) e `Units.swift`; `files/unidade.json`; item "Unidade de medida" nos Ajustes das 3 plataformas; `?un=` na URL do editor.
- **Regras:** em cm é o mm com a vírgula andando (695 → 69,5; 634,5 → 63,45), por texto, sem ponto flutuante: alternar quantas vezes quiser não muda nada. Digitar 69,5 ou 69.5 em cm grava 695. Número com #, %, °, R$, "1/1", ×quantidade e número de ordem ("Base 1", "Vão 2") nunca é medida.
- **Caderno:** notas antigas com a unidade delas; nota nova segue os Ajustes, sem escolha = mm (decisão do Adauto; antes nascia em cm). A unidade M do caderno continua.
- **Testes:** bateria `testUNIDADE_*` (5, mais os 3 terços de `testPlanoDeCorteLegivel…EmCm`; o 5º varre o catálogo inteiro em mm e em cm: 0 cota do desenho no número em mm, 0 palavra mudada, 0 nº de peça/litros/%/°/nº de módulos mudado — pegou "912 × 716" antes da correção). Os 5 falham na base `claude/fechamento-code1` porque a função não existe e passam: 69,5/1,5/3,5 e digitado → 695; alternar 20× byte a byte; projeto antigo igual; catálogo inteiro com partsOf/corte/orçamento/DXF idênticos em mm e cm; lista e corte em cm; preço/%/quantidade/nº/nomes iguais. JVM `UnitsTest` (Android e Windows) e XCTest `UnitPrefTests`: conversão, vírgula/ponto, ida e volta 0..100000 mm sem perda, formato do arquivo, padrão mm, arquivo dentro de files/ (backup).
- **Pendências (não convertidas, continuam em mm):** textos de ajuda/notas do painel com número sem unidade (ex.: "Folga… 57 da borda", furação dos puxadores "192 · 288", catálogo de eletrodomésticos com medidas no nome), nomes de peça com número ("engrosso 80"), "MDF 15" (nome do material). As explicações das peças na lista e no corte ganham "mm:" na frente quando a tela está em cm. DXF R12 não tem `$INSUNITS`.
- **Erro meu achado e corrigido no caminho:** uma troca deixou a string do rótulo "lateral … maior" (planta) sem aspas (`SyntaxError` no bloco das paredes, pego pela bateria completa: `errs` 1 em vários testes). Corrigido em `8fb9763`; agora confiro `node --check` em todos os blocos `<script>` depois de cada troca.

## REG12-FILA e MENU-F3 (25/11): 5 falhas na bateria completa do claude/menus-por-tipo (e7f1cb1f), as mesmas a 1366 e a 430 — Code 2
- **Bisseção** (140d2a4b passa tudo):
  - O f94fe1b5 quebra `testMenuDoVaoDoBalcaoDaCozinhaSemQuadroRepetidoELixeiraNaLista` e `testF3MenusNaMesmaOrdemEmTodosOsModulos`.
  - O 7c47847e quebra `testCenarioCompletoDoClienteAoBackupTudoCoerente`, `testProjetoAntigoComMoveisNaParedeEsquerdaAbreIgual` e `testMoverNo3DEncaixaNaParedeAte20mmSoDeCostasSemMexerEmNinguem`. Quebra também `testPainelSolidoNuncaDentroDoMovelNaCozinha` e `testProjetoNaoSomeAoTrocarDeParedeOuAmbienteEHistoricoRestaura`.
- **Causa 1 (f94fe1b5):** o menu de 2 toques do vão era reordenado por tipo de móvel. Isso contraria o F3 (menus na mesma ordem em todo módulo, com a porta no mesmo lugar).
  - **Correção:** a ordem fica a de sempre. O que antes sumia continua em "Mais opções".
- **Causa 2 (7c47847e):** o embrulho do rowJoin desfazia também o que o autoTamp faz quando o draw o chama, na criação e na abertura (`draw.__at`). Esse autoTamp liga o tamponamento E acomoda o mesmo módulo num passo só. Desfazer só a posição deixava o módulo pela metade: tamponamento ligado sem a posição.
  - **Correção:** o embrulho não age dentro do `draw.__at`. Continua valendo no gesto (tirar e pôr tamponamento: `tpDesliga`, caixas tl/tr, largura).
  - **O diagnóstico do e7f1cb1f (opção A) estava incompleto.** O aéreo se mover na criação vem desse autoTamp, que já existia antes da varredura. O e7f1cb1f foi revertido: os 2 testes de painel voltam aos valores originais (1045x870 e 1 painel).
  - **Pendente (decisão do Chefe):** levar a §12 para o autoTamp da criação nos vizinhos. Tem que desfazer tamponamento e posição JUNTOS, como sugestão.
- **Status:** resolvido para as 7 falhas.
## ESP-FAIXA-430, ARQ-CORROMPIDO e B26-ALTURA (Code 3, 25/11, áreas dadas pelo Chefe; ramo `claude/c3-revisao`)
### ESP-FAIXA-430: faixa jateada do espelho LED com falhas de longe (achado do Code 3 na revisão do 4fb5695a)
- **Reproduzir:** 430×900 com densidade 1, `espWallAdd(4)`, `a.x=150`, `__cam(-.5,.12,1.05)`. Varredura radial: 9 de 360 direções sem nenhum pixel aceso da faixa, de dia e à noite, nas 3 qualidades (54 no total).
- **Causa raiz (comprovada):** no `espDraw3`, com faixa (`J_`), o centro espelhado é uma peça separada (`espPts(f,-(J_.off+J_.w))`). Era a única camada do espelho com LED sem `nol=1`. A linha de contorno dela caía exatamente na borda de dentro da faixa e, de longe, apagava a faixa em alguns ângulos. A faixa é jateada no mesmo vidro: essa borda não existe no espelho de verdade.
  - Prova: só com `nol=1` nessa peça, as direções apagadas caem de 9 para 0. Nada mais muda.
- **Correção:** `nol=1` no centro espelhado quando há faixa. O contorno de fora, as medidas, o lugar e a profundidade não mudam.
- **Família:** todas as formas (retangular, redondo/oval, arco), bordas e molduras passam pelo mesmo `espDraw3`. Espelho sem faixa: igual. Os 26 testes de espelho/LED passam a 430 d1, 430x2 e 1366.
- **Teste:** `testFaixaDoEspelhoLedContinuaNasTrezentasESessentaDirecoes`, com varredura radial de 360 direções × 24 vistas e controle (LED desligado = 360 apagadas).
  - Antes: 54 apagadas a 430 d1. Depois: 0 a 430 d1, 430x2 e 1366.
  - Com o ESP-FAIXA de volta (faixa fora do passe GOL): 1217 a 6480 apagadas. A margem saiu de 15/20 do teste de pontos pra mais de mil.
  - O `testFaixaDoEspelhoLedApareceDeLongeEEmAngulo` não mudou.
- **Projeto antigo:** nada é gravado; só o desenho do 3D.

### ARQ-CORROMPIDO: prices.json ilegível gravado por cima sem cópia (P0, achado do Code 3 na revisão do 70f5130)
- **Reproduzir:** `prices.json` com JSON quebrado ou texto que nem é base64, banco do navegador vazio, abrir o editor. O 1º `prSave` grava os padrões por cima. Preços e Meus modelos (`PR.myMods`) ilegíveis somem sem cópia.
- **Causa:** o `prSave` grava o arquivo sem olhar o que está lá. O PRECOS-RESTAURO lê o arquivo, mas, se o `JSON.parse` falha, segue e grava por cima.
- **Correção (camada, sem mexer no caminho do PRECOS-RESTAURO):**
  - `arqCorrCopia(nome, valido)`: arquivo ilegível → cópia como está, pela mesma ponte (`<nome>.corrompido-AAAAMMDD-HHMMSS.json`, conferida byte a byte) e aviso.
  - A mesma cópia não se repete.
  - Se a cópia não grava, `__prBloq` impede gravar o `prices.json` nesta sessão: o arquivo fica intacto e o aviso pede backup.
  - Nunca apaga. Roda na 1ª gravação da sessão.
- **Família:**
  - `projects.json`: já guardava `projects.corrompido.json`, mas calado. Agora avisa, e a checagem ficou em `window.pjsCorrGuard` (mesmo código, chamado na abertura como antes).
  - Meus modelos ficam no `prices.json`: cobertos.
  - **Risco identificado, não mexido (fora das áreas):** `apmodels.json` (eletros com medida própria). Ilegível na abertura, o texto quebrado vai pro banco do navegador e o `JSON.parse` lança dentro do mesmo `try` que restaura as fotos depois (as fotos não voltariam nessa abertura). Gravar um modelo de eletro grava por cima sem cópia.
- **Teste:** `testArquivoIlegivelGuardaCopiaEAvisaAntesDeGravarPorCima`.
  - Antes: cópias 0 e arquivo mexido.
  - Depois: cópia byte a byte e aviso nos 2 tipos de quebra, sem repetir; cópia que falha deixa o arquivo intacto.
  - Backup restaurado (PRECOS-RESTAURO) e uso normal iguais, sem cópia nem aviso. `projects.json`: cópia e aviso.
  - `testBackupRestaurado…` e `testProjetoGravadoPelaVersaoPublicada…` passam iguais.

### B26-ALTURA: peça fora do lugar que ainda encosta de lado (pedido do Chefe, a partir da revisão do Code 3)
- O `testNenhumaPecaDeFabricacaoFicaSoltaNo3D…` (Code 1, sem mudança) confere ligação: peça subida 10 mm que encosta de lado passa.
- Só pela geometria não dá pra saber se ela está fora do lugar: 317 tamponamentos e 4434 portas do catálogo não têm nada embaixo, presos de lado como na montagem de verdade.
- **Teste novo `testCadaPecaNo3DFicaNaAlturaDoPartsOfEmTodoOCatalogo`:** a altura de cada peça de fabricação no 3D (y0/y1) tem que ser a do `partsOf` (topo − y − h / topo − y), com 1,5 mm, em todo o catálogo (138 modelos, 2089 peças).
  - Fora só o que corre por dentro (gaveta, gaveta interna, caixote de gaveta, porta-tempero: o desenho de frente deles não é a posição) e a prateleira inclinada da sapateira.
  - Controle interno: prateleira e tamponamento subidos 10 mm são acusados.
  - Prova no app: editor com o 3D subindo prateleira e tamponamento 10 mm. O teste do Code 1 passa; o novo acusa ("Tamponamento esquerdo 10/10" em todos os balcões).
- **Resultado no catálogo:** nenhuma peça fora da altura. Nenhum defeito pra mandar ao Code 1.
- **Visto e não mexido (risco de identidade, D23):**
  - No aéreo com tamponamento de 30 + cava, o `partsOf` tem "Tamponamento esquerdo#1" (750 × 80) e o 3D tem só as réguas com `pk` "Tamponamento esquerdo (régua)#1/#2". O `pk` da peça não acha caixa no 3D (o "localizar no 3D" do plano de corte pode não achar).
  - Sapateira · aparador e as peças da gaveta interna também não têm caixa 3D com o mesmo `pk`.

## ARQ-CORROMPIDO (2ª parte) e LOC-REGUA (Code 3, 25/11, pedidos do Chefe; ramo `claude/c3-revisao`)
### ARQ-CORROMPIDO, outros arquivos da ponte
- **Varredura dos arquivos que o editor grava pela ponte:**

| Arquivo | Ilegível na leitura | Gravado por cima sem cópia? | Situação |
|---|---|---|---|
| `apmodels.json` (eletros com medida própria) | o texto quebrado ia pro banco do navegador; o `JSON.parse` lançava no mesmo `try` que restaura as fotos | sim, ao salvar um eletro | **corrigido** |
| `hist_<projeto>.json` (histórico de versões) | vira lista vazia | sim, na próxima versão: o histórico inteiro sumia | **corrigido** |
| `trash.json` (lixeira) | `fget` devolve nada: lixeira vazia | sim, no próximo excluir ou restaurar | **corrigido** |
| `guard.json` (senha) | volta pela cópia do navegador | sim | **corrigido** (mesma guarda do `fput`) |
| `cur_<projeto>.json` (recuperação de queda) | pulado | sim, na próxima edição do projeto | **corrigido**: sem a cópia, vai pela gravação inteira |
| `photo_<id>.json` | cada um no seu `try`, pulado | não (só grava a mesma foto de novo) | sem o risco |
| `video_<id>.json` (iOS, `EditorMediaBackup.js`) | cada um no seu `try` | não (id novo; apaga só quando a pessoa apaga o vídeo) | sem o risco |
| notas | gravadas pelo app nativo, fora do editor | — | não verificado (fora do editor) |

- **Reproduzir (antes, f02a19b):**
  - Com o mesmo bloco de abertura, `apmodels.json` quebrado faz a foto não voltar; com ele bom, a foto volta.
  - `hist_` e `trash.json` quebrados: a gravação seguinte grava por cima, sem cópia.
- **Correção:**
  - `arqCorrAntes(nome, valido)`, que usa o `arqCorrCopia`: na 1ª gravação de cada arquivo na sessão, se ele estiver ilegível, guarda uma cópia byte a byte e avisa. Se a cópia não grava, não grava por cima.
  - Ligado em `apSaveModel`, no `store` do histórico, no `fput` (lixeira e senha) e no `svLeve` (`cur_`).
  - A abertura (`window.__arqBoot`, chamada como antes) ficou com um `try` por passo: o `apmodels.json` quebrado não entra no banco do navegador e não impede as fotos.
  - Nunca apaga.
- **Teste:** `testOutrosArquivosIlegiveisGuardamCopiaEFotosVoltam`.
  - Fotos voltam com o `apmodels.json` quebrado.
  - Cópia byte a byte e aviso em eletros, histórico e lixeira.
  - Sem a cópia, o histórico fica intacto (com aviso).
  - Arquivos bons: igual, sem cópia nem aviso.
  - Antes: cópias 0 nos 3.
- `cur_` e `guard.json` passam pelo mesmo ajudante, sem teste próprio.

### LOC-REGUA: localizar no 3D pela chave do partsOf
- **No app real** (plano de corte → tocar a peça → 3D em rosa), a peça é encontrada nos 3 casos:
  - aéreo com tamponamento de 30 + cava: 4 réguas, porque o plano já usa a chave das réguas;
  - Sapateira · aparador: na prateleira inclinada;
  - gaveta interna: na frente.
  - Os dois últimos já eram ligados pelo `hlResolve`.
  - Os 2 caminhos de "mostrar no 3D" (plano ou lista geral, e lista do módulo) acham as 8150 chaves dos 138 modelos.
- **Defeito pela chave do partsOf (a da identidade D23):** o tamponamento que o 3D desenha em réguas não achava caixa. São 48 chaves: aéreos com tamponamento de 30 e cava, aéreo canto cego, fechamento e passagem livre. "Tamponamento esquerdo#1" contra "Tamponamento esquerdo (régua)#1/#2".
- **Correção, só no mapeamento:** no `hlResolve`, a chave do tamponamento sem caixa própria aponta para as réguas dele (`any`). Peças, medidas, corte e o código do D23 não mudam.
- **Teste:** `testLocalizarNo3DAchaTodaPecaDoCatalogoPelosTresCaminhos`, com 11463 chaves (plano, lista do módulo e `partsOf`) nos 138 modelos.
  - Antes: 48 sem caixa. Depois: 0.
  - Exceções, com o motivo no teste: só os registros fora do corte, que não são peça de fabricação. São eles: Vão da torre N, Nicho do forno, do micro-ondas e da geladeira, Decoração e o lado do canto em L com porta articulada.

## DECO-MANUAL: enfeite do 3D só por escolha (pedido do Adauto 25/11, via Chefe; Code 3, ramo `claude/c3-revisao`)
- **Pedido:**
  - Ao pôr prateleira, cabideiro ou porta-temperos, nada de enfeite automático.
  - Projeto de antes continua igual.
  - Opção manual de pôr e tirar em cada componente.
  - Enfeite nunca é peça.
  - Biblioteca de objetos: cada objeto entra e sai um por um.
  - Regra §12: nada que já existe muda sozinho.
- **Inventário (antes):** 37 modelos do catálogo ganhavam enfeite sozinhos no 3D (`deco3`, a partir das entradas "Decoração" do `partsOf`, sem corte, sem 2D e sem valor):
  - `fold`: roupa dobrada em prateleira e maleiro, 100 vezes;
  - `hang`: roupa no cabideiro, 28;
  - `shoes`: sapatos na sapateira, 9;
  - `drawer`: gaveta interna, 5.
  - Só fora da cozinha e do banho, e com "Mostrar decoração no 3D" ligado.
  - **Porta-temperos:** não gera enfeite nenhum, nem automático; o 3D só desenha a estrutura. Pôr enfeite nele exigiria desenho novo: pergunta ao Adauto, não feito.
- **Implementação, só no desenho do 3D (o `partsOf` fica idêntico em JSON):**
  - Cada entrada "Decoração" leva `dsrc`, uma função que devolve o componente (`v.int[k]` ou o nó da torre). O `JSON.stringify` ignora funções.
  - O desenho pergunta ao `decoMostra(m,p)`:
    - "Mostrar decoração no 3D" desligado → nada;
    - `deco=1` → mostra, e `deco=0` → esconde;
    - móvel com marca `dv` ou componente com `dv` → não mostra;
    - sem marca → a regra de antes (fora da cozinha e do banho).
  - Marca de formato `dv=1`, pelo mesmo jeito do `espN` (22/11):
    - o móvel criado a partir desta versão (catálogo, do zero, cópia) leva a marca;
    - num móvel de antes, só o componente novo (prateleira, cabideiro, gaveta, sapateira) leva a marca;
    - ao abrir nada é marcado (a abertura só registra o que existe).
  - Manual: no quadro da parte tocada, "🧺 Enfeite no 3D · Pôr enfeite / Tirar enfeite"; também `window.decoPoe(m, componente, on)`, com desfazer.
  - Na torre por vãos, o botão fica pro menu do vão, área do Code 2 (pedido mandado); a função já está pronta.
- **Prova (sondas s48/deco, Chromium):**
  - 139 projetos do catálogo + cozinha de exemplo + 4 dos backups de referência, gravados no editor de antes (483d83c) e abertos no novo: `partsOf`, corte (`cutGroups` com medidas), enfeite no 3D (caixas do enfeite), orçamento e DXF iguais nos 143.
  - O estado salvo difere só na normalização da abertura (`wing` 0, `amb` {}), que o editor de antes faz igual.
  - Catálogo novo: os 37 modelos nascem sem enfeite, com peças e valores iguais. "Armário livre · montar do zero" depende do móvel criado antes, também no editor de antes.
- **Testes:**
  - `testEnfeiteDo3DSoPorEscolhaNovoSemAntigoIgualPorETirar`:
    - 37 modelos com enfeite: novos 0, de antes 37;
    - peças, corte, orçamento e DXF iguais nos 37, com enfeite automático, sem enfeite e com todos postos à mão;
    - componente novo em móvel de antes nasce sem enfeite e com a marca.
    - Antes: novos 37 e componente com enfeite.
  - `testEnfeiteDo3DPorETirarAMaoComDesfazerSalvarEReabrir`: botão do quadro põe, desfaz, salva e reabre igual, e tira. Antes: sem botão.
  - `testObjetosDaBibliotecaPoeETiraUmPorUm` (17 objetos):
    - nenhum entra sozinho, no catálogo inteiro, no quarto e na cozinha;
    - cada um põe, aparece no 3D, valores iguais, sai pelo 🗑 e some;
    - os 17 juntos: salvar, reabrir, tirar um por um e desfazer.
    - Já passava antes: a biblioteca já era manual e removível um por um. É a prova que faltava, não correção.
- **Não verificado:** com dezenas de `loadState` seguidos no mesmo teste, o desfazer logo depois perdeu o passo (a pilha foi zerada por algo atrasado). Isolado, funciona. Por isso a parte manual tem teste próprio.
## CI-ESTAB (25/11): intermitentes e lentidão do CI (pendência do Chefe) — Claude 4
- **FOCO-3D (app), causa do "chips[1] undefined" do testSoOModulo3DE2D… sob carga.**
  - Causa: 900 ms depois de abrir o 3D, o autodiagnóstico do PEDIDO 45 (wrapper do `open3D`) contava os módulos escondidos de propósito pelo foco "só o módulo" (FOC3) como 3D quebrado. Também rodava com o 3D já fechado. Aí relia o projeto: `loadState` → `limpa` → FOC3/SOLO2 perdidos, e o "✏️ 2D só ele" não fazia nada.
  - Como foi achado: armadilha no `window.FOC3`; a pilha deu `limpa < loadState < setTimeout 900 ms do open3D`.
  - Reproduz sem carga: abrir o 3D e focar ou fechar antes de 0,9 s. Com a CPU 6× mais lenta, 5 de 5 falham.
  - Correção: o diagnóstico só confere o módulo focado e não confere com o 3D fechado. O reparo do 3D quebrado de verdade continua (teste do PEDIDO 45).
  - Teste `testFOCO3D_…`: falha antes, passa depois. Depois da correção: 15 de 15 a 6× e 4 de 4 a 12×.
- **TZ-ID (app), causa do testRebaixoDoTetoComDente intermitente** (bateria 1366 do Code 2, aae4ef93: `esq` veio "2800+600@2600").
  - Causa: o id do rebaixo do teto era relógio + sorteio (0..996). Zonas criadas a poucos ms podiam repetir o id, e o "dente" saía da 1ª zona com aquele id (o dente anterior).
  - Reproduzido com o relógio e o sorteio presos: o mesmo "2800+600@2600", com 2 ids únicos em 4 zonas.
  - Correção: `tzUid()`, igual ao `rpUid()` dos painéis: pula id que já existe.
  - Mesma família: 2 lugares de painel (placa do lado e cópia) ainda usavam relógio + sorteio; agora usam `rpUid()`.
  - Risco identificado, não alterado (sem defeito reproduzido): ids de nível (`L`, relógio%1e9 + sorteio) e da pedra (relógio%1e6). Projeto antigo com id repetido não muda sozinho.
  - Teste `testTZID_…`: falha antes ("2800+600@2600"), passa depois.
- **iOS (lentidão da abertura no CI):** o log do WebKit no run 695 mostra o tempo antes da página começar.
  - Processos levando 14 a 300 s pra lançar e 1186 "Failed to terminate process".
  - Cerca de 27 s parado no WebPrivacy sem listas.
  - O editor sozinho leva de 1 a 2 s.
  - Mudança aprovada pelo Chefe: um armazenamento do WebKit compartilhado e limpo antes de cada teste (`WebKitCompartilhado`, com o teste `testISOLAMENTO_…`) e aquecimento do WebKit medido à parte ("ABERTURA-DIAG WebKit frio"). Os mesmos 20 s na 1ª abertura do editor.

## UNIDADE-2 (25/11): medidas que ainda ficavam em mm, sem unidade, no modo cm (achado do Claude 3 na revisão do pre-final 436ac8f2) — Claude 4
- **Reproduzir:** `?un=cm` (ou `arqueUnidade('cm')`), `loadState(initLimpo());demoScene();draw()`, pedra selecionada.
  - 2D: cotas da pedra `sT`/`sR`/`sL` = 820 e 865; rótulo da cuba "fundo 100 · frente 106"; "frontão N".
  - Lista: cabeçalho "Base 1 · 900 × 820 × 560" e a tabela de ferragens "900 × 820 × 560".
  - 3D: título dos quadros (eletro "616 × 1700 × 691", pedra "2735 × 606", cooktop, cuba, caixa, módulo, paredes/piso), os rótulos de arrastar (largura/altura no 3D, painel, módulo, tamanho) e o texto da parede no 3D.
- **Causa:** pontos de origem que montavam o texto com o número em mm direto (`m.w+' × '+…`), fora do `UN.num/UN.len` da 1ª rodada.
- **Correção (na origem, sem mexer em texto pronto):** `UN.med(t)`, que em mm devolve o mesmo texto e em cm converte e escreve "cm". Onde já havia " mm", `UN.len`. Também o card do catálogo, o rótulo da caixa no 2D, "Encostou…", "Editando só…", Meus modelos e os avisos de cópia, nicho e lava-louças.
- **Em mm nada muda:** o teste confere o texto em mm igual ao de antes.
- **Teste:** `testUNIDADE_CotasDaPedraCubaListaEQuadrosDo3DEmCmEMmIgualAntes`. No 436ac8f2 falha em todos os pontos (ex.: "820 | 865 → 820 | 865"); agora "820 | 865 → 82 | 86,5". Os 6 `testUNIDADE_*` passam a 1366 e a 430.
- **Ficou como está (já tem unidade escrita, em mm):** o relatório de medidas da planta (`cmmm`, "… mm") e a nota do rebaixo do perfil na lista. Não convertidos.
- **2ª parte (Claude 3: o "3384" era o campo "Da parede esquerda" do quadro do eletro):** os campos dos quadros do 3D (eletro, pedra, cuba, caixa, módulo, peça, LED) não têm `<label>` (o rótulo é um `<span>`), então a camada UN não os via como medida. Na origem: `UN.lab(rótulo)` põe o rótulo no campo (`data-lab`) e `UN.rot` faz o "(mm)" do texto seguir os Ajustes. Em cm o eletro mostra 61,6 · 170 · 69,1 · 298,4 · 0, o código continua lendo 616 · 1700 · 691 · 2984 · 0, e digitar 61,5 na pedra grava 615. Mesmo teste, que falha no 436ac8f2.

## TOQUE-2X (25/11): `testNo3DDuplicarPecaEDoisToquesNoPuxadorReposicionaTodos` intermitente (bateria completa do pre-final 436ac8f2, 1366) — Claude 4
- **Achado:** falhou 1 vez na bateria a 1366 (botao false, dup 1). Repetido sozinho: pre-final 1/2 e depois 4/4 falhando com as 2 baterias rodando; 5/5 ok com a máquina livre. No fechamento-code1 (base) também falha: 2/5. **Não é da integração.**
- **Causa (comprovada):** o app conta o duplo toque pelo `e.timeStamp` (no aparelho é a hora do toque), com limite de 420 ms. O teste só criava o 2º toque depois que o 1º acabava de rodar (≈170–250 ms medidos; mais com a máquina carregada), então o `timeStamp` do 2º passava de 420 ms. Os toques do teste ficavam 236–275 ms separados, não os 80 pretendidos.
  - Prova: com o 1º toque preso 450 ms de propósito, o teste antigo dá exatamente a falha (botao false, dup 1) e o novo passa. Controle: com 500 ms entre os toques, o novo continua falhando (não é duplo toque).
- **Correção (só no teste, expectativas iguais):** os 2 toques nascem com 80 ms de diferença, como o dedo, e depois são entregues. O mesmo em `testNo3DDuplicarQualquerPecaViraPecaLivre` e `testConchaDaGavetaInverterEMoverSoElas`, que usam o mesmo toque duplo. Nenhum limite muda.
- **Validação:** 3/3 a 1366 e a 430; 5/5 no fechamento-code1, onde o antigo falhava 2/5. O app não mudou.

## SOOID (25/11): `testIdentidadeUnica…` falhava em "abrir o projeto antigo só soma o id" (opção a do Chefe; passou do Code 1 pro Claude 4) — Claude 4
- **Causa:** a comparação via `wing` ausente (projeto antigo) contra `wing: 0` (o `loadState` põe 0 no módulo sem parede), nos módulos e no `m`. Antes o reparo do 3D de 900 ms relia o projeto e normalizava os dois lados. O FOCO-3D tirou esse reparo espúrio.
- **Correção (só no teste, só nesse campo, com comentário):** na comparação do `soOId`, `wing` ausente = 0. `loadState` não muda.
- **Prova pedida pelo Chefe:** no mesmo cenário, o projeto antigo aberto e o original fabricam igual: peças (`partsOf`), corte (`cutLines`), orçamento (`budget` tot/venda) e DXF (`dxfPecas`), sem os ids. Controle: 10 mm a mais num módulo muda a comparação.
- **Validação:** passa a 1366 e a 430.

## CORTE-PRIORIDADE (25/11): peça sem identificação no plano com a métrica do iPad (achado do Claude 3 no 47324009; vem do c1682687) — Claude 4
- **Reproduzir:** `window.__cpMet={AS:1.16,DS:.30}` (a métrica do iPad), "Guarda-roupa de sala 2 vãos (cabideiro + prateleiras)" sozinho, plano de corte. A régua espaçadora 815 × 30 #2 fica sem texto e sem callout. `…TerceiroTerco` e `…TerceiroTercoEmCm` falham, a 1366 e a 430.
- **Causa:** a etiqueta de medida da sobra ("161") cresce com a subida real da fonte (c1682687, certo pra não passar do contorno) e entra como obstáculo no `cpCallouts`. Sem outro lugar, a régua não ganha callout. Além disso, o desenho e o `cpCallouts` chamavam `cpMet()` cada um por si, e as caixas da etiqueta eram calculadas duas vezes.
- **Correção (pedido do Chefe):**
  - Um retrato só da métrica por chapa (`MT_`), usado pelas etiquetas das sobras, pelo `cpTxt` e pelo `cpCallouts`.
  - As etiquetas das sobras viram lista (`SOB_`, com a caixa de cada uma) e entram no lugar delas no fim. O `cpCallouts` usa essas mesmas caixas.
  - **Prioridade:** a identificação da peça é obrigatória. Se o callout não acha lugar, procura de novo sem as etiquetas das sobras e tira só a que ficaria embaixo dele.
- **Sem conflito nada muda:** com a métrica normal, o SVG do plano das 24 cenas do catálogo inteiro (903 etiquetas, 38 callouts) é idêntico byte a byte ao de antes. Com a métrica do iPad também, exceto o único caso de conflito, onde sai só a etiqueta "161". O segundo terço (o 641 × 125) dá o mesmo SVG antes e depois nas duas métricas.
- **Testes:**
  - `testCORTEPRIORIDADE_PecaSempreIdentificadaEtiquetaDaSobraCedeLugarComMetricaDoIPad`: antes "sem identificação 1 (Caixote · régua espaçadora 30 · 815 × 30)"; agora 0, sem callout em cima de etiqueta.
  - Os 6 terços passam a 1366 e a 430, com a métrica normal e com a do iPad forçada.
  - Os testes de corte, sobra e chapa passam.


## REG12-CRIACAO (25/11): o que a bateria achou no caminho — Code 2
- **1ª versão (6d269a40), revertendo a cada desenho:** a bateria completa deu 7 falhas, as mesmas a 1366 e a 430. Duas eram defeito de verdade:
  - **Módulo do catálogo recusado:** ao pôr um módulo encostado, o tamponamento da junta passa do existente pro novo. Com o existente voltando, os dois tamponamentos se sobrepunham e o `modGuard` tirava o novo ("Não tem espaço livre…").
  - **Artefatos das várias passadas de desenho de uma mesma criação:** o novo andava 30 mm pra dentro do tamponamento do vizinho, e a sugestão não dava o de antes.
- **Correção (desenho novo):**
  - A criação roda igual e a comparação é feita UMA vez, no fim da ação (`atInicio`/`atFim`), só nos campos de posição, largura e tamponamento, e só em ação que criou módulo.
  - O S.m nunca volta, e o novo se acomoda se ficar entrando no vizinho.
  - A sugestão guarda o estado final de cada módulo e o toque volta exatamente ele.
  - O `loadState` zera a ação.
- **Testes:**
  - Os 29 relacionados passam a 1366.
  - A s45 dá igual à da candidata.
  - Os testes que criavam passo a passo e esperavam o vizinho ajustado tocam na sugestão e conferem os mesmos valores: desfazer/refazer, valores das chapas, mão de obra, fechamento até o teto, "Usar N mm", peças livres e os 9 de tamponamento.
- **Correção na causa (c006b9d9; decisão do Chefe 25/11):** o "desfaz no fim da ação" (a348ee31) foi trocado pela proposta calculada numa cópia. Nada é escrito nos existentes durante a criação; o espião no `testReg12…` prova.
- **RISCO registrado (não corrigido, a pedido do Chefe):** num redesenho comum, módulo que a PESSOA pôs fora do lugar válido fica onde está, mas pelo padrão escreve-e-desfaz:
  - `confineAll` (editor.html ~1297, pelo embrulho ~13428) escreve x (ex.: 3900→3265);
  - `roomClamp` (~3231) escreve b (ex.: 2100→1950);
  - o `guarda` (~13110–13114) devolve os dois.

  Se algum caminho chamar `confineAll`/`roomClamp` fora do `guarda`, a mudança fica.

## QUEDA-PARALELO (25/11): as quedas do app de teste no iOS ("Restarting after…") — causa comprovada pelo RECURSO-DIAG do iOS 701 — Claude 4
- **Descartado com medida:**
  - harness: WKWebView vivos 0 em todo teste, 0 de 503 criados;
  - vazamento no app de teste: memória de 69 a 84 MB a bateria toda;
  - acúmulo de processos: 1 WebContent, às vezes 2.
- **Causa:** o passo do iPhone tem 75 min e acaba por tempo (701: 22:53:49), mas o `xcodebuild` do iPhone **não morre** e continua rodando junto com o iPad. São dois simuladores, dois apps de teste e WebContent de até 1 GB no mesmo Mac.
  - O Mac troca memória com o disco: o amostrador, que dorme 60 s, atrasa para 74–133 s, e a memória residente de todos os processos cai a quase nada.
  - O teste do momento passa de 120 s e o Xcode reinicia o app.
  - As 2 quedas do 701 (≈22:58 e 23:14) e as do 699 (21:06 e 21:24) estão dentro dessa sobreposição. O `testTamanhoDoModuloInteiroNo3DAoVivo…` leva 3,5–11 s em toda execução e levou 167 s só nessa janela.
- **Correção (CI, nenhum limite muda):** antes do iPad, o `ios.yml` encerra o `xcodebuild` e o amostrador que sobraram do iPhone, desliga os simuladores ligados e avisa quando isso aconteceu.
- **Pendente (decisão do Chefe):** a bateria do iPhone não cabe nos 75 min do passo, então ele sai incompleto. O iPad tem 100 min.
- **BATERIA-2-PASSOS (decisão do Chefe 25/11: não aumentar o passo do iPhone, nenhum limite muda):**
  - O iPhone roda em 2 passos, A e B, com os mesmos 75 min e a mesma tolerância por teste. O B usa `test-without-building` e encerra o que sobrou do A antes de começar.
  - `ios/scripts/metade_testes.py` divide o `EditorWebKitTests` ao meio pela lista do código. As outras classes ficam no A, e a SubscriptionTests segue no passo dela.
  - Prova da contagem: 669 testes = A 376 + B 293, sem repetir. Contra o log do 701, nenhum teste que rodou fica fora da lista, e os 5 que faltam no 701 são os criados depois dele. O passo B imprime "começaram X de 669".
  - O iPad virou job próprio (outro Mac, os mesmos 100 min), então os 2 simuladores nunca ficam juntos. Os resultados vão pra `ci/ios-resultados-<ramo>-ipad`.

## ATU-IOS-37 (26/11): atualização do iOS falhou no iPad (iOS-atualização 37, 7cf195eb) — Claude 4
- **No iPhone passou tudo:** projetos, notas e fotos iguais; o vídeo da versão publicada voltou igual byte a byte e tocou no editor novo. No iPad passou o "backup rico".
- **Falha 1, iPad, "backup referência":** "Exceeded timeout of 90 seconds… editor aberto pelo esquema do app". Era a 1ª abertura do editor no iPad, com o WebKit frio; depois ele abriu e conferiu tudo igual. O 2º teste do iPad, logo depois, abriu em 28 s.
  - É o mesmo WebKit frio já tratado no `EditorWebKitTests`.
  - Correção: `WebKitCompartilhado.aquece(store:rotulo:)` aquece o armazenamento do próprio teste antes de abrir. Não apaga dados; só lê a lista e abre about:blank. Nenhum limite muda.
- **Falha 2, iPad, vídeo:** o roteiro que grava o vídeo **na versão publicada** caiu antes da versão nova entrar. Com o seletor de fotos aberto, listar os botões da página passou do tempo da consulta do XCUITest (176 s).
  - Correção (11ª rodada do roteiro): os botões da página são lidos antes de abrir o seletor, com a página parada.

## CPMET-IPAD (26/11): o "641" do caixote 641×125 encostava no contorno no iPad (…SegundoTerco, iOS 694/697/701/704) — Claude 4
- **Medido:** no iPad o `cpMet` mediu (`ok:2`) e deu 0,95/0,26, mas no plano a caixa do "641" (fonte 28,5, chapa de 2810 mostrada em 398 px, ~4 px na tela) sobe 1,15.
- **1ª tentativa (a532a142, revertida):** medir também a 40 e a 16 px e usar a maior pra tudo.
  - No Chromium a escala pequena também cresce (1,00/0,30) e o plano mudou: o Claude 3 achou o nome "Lateral gaveta" saindo de 6 peças.
  - Eu achei a porta 390×2300 da cozinha de exemplo sem identificação nenhuma e a do Aparador só com "#20". O mesmo acontece com a métrica do iPad forçada (1,16).
  - Inflar o espaço reservado do layout piora.
- **Correção (CPMET-IPAD):**
  - O espaço reservado continua o de sempre (AS/DS a 400 px).
  - **Só no iPad** (WebKit em modo computador: `Macintosh` + toque) o `cpMet` mede também a 40 e a 16 px (ASr/DSr), e o texto da peça só centraliza a linha de base com essa medida. A caixa real fica no meio do espaço reservado, em vez de deslocada pra cima até o contorno.
- **Fora do iPad, o plano é idêntico ao do 71915d90**: SVG do catálogo inteiro (24 cenas) igual byte a byte, métrica 0,95/0,26, 38 callouts.
- **iPad simulado no Chromium** (agente de navegador do iPad + toque; ASr 1,00/DSr 0,30):
  - os 61 testes de corte passam a 1366 e a 430;
  - as portas do Aparador e da cozinha de exemplo mantêm "497 × 330 #20 Porta" e "2300 × 390 #22 Porta".
  A medida real do iPad (1,15) só se confere no iOS CI.
- **iOS 706 (7dcd8b3e):** só centralizar a linha de base não bastou. O iPad mediu ASr 1,13 / DSr 0,26 (a subida cresce, a descida não), e os 6 terços falharam com o texto empurrado pra baixo.
- **Correção final:**
  - **CPMET-IPAD:** no iPad o plano usa a medida em escala pequena (como o fallback 1,16/0,30 do c624f1c6, que passa os terços). Fora do iPad nada muda.
  - **ID-SEMPRE** (regra do Chefe, "a identificação da peça nunca some"): toda peça que fica sem texto e sem callout ganha "medida #n" ou "#n" num lugar livre dentro dela, sem bater em furo nem linha. Na métrica do iPad, as portas 290/326×2300 do "2P c/ Cab" ficavam sem nada.
- **Validação no Chromium:**
  - os 61 testes de corte passam a 1366 e a 430, e a 1366 com o iPad simulado;
  - com a medida do iPad forçada (1,13/0,26), os 8 de legibilidade passam a 1032×1376 e a 430;
  - peças sem "#n" no catálogo com a métrica do iPad: 16 → 12, menos que as 14 da métrica normal.

## NOME-IPAD (26/11): com a métrica do iPad, nomes de peça sumiam do plano de corte (achado do Claude 3 no 955db9b0) — Claude 4
- **Erro:** com o agente de navegador do iPad, "Lateral gaveta" sumia no Gaveteiro 3 gavetas e no Balcão porta + gavetas. A Porta 497×330 do Aparador suspenso ficava só "#20" (antes "497 × 330 #20 Porta"). Regra do Chefe: "Se o nome não couber dentro da peça, ele vai junto no callout ou abreviado de forma legível. Nunca some".
- **Causa raiz:** `cpTxt` (editor.html) ficava com o 1º tamanho em que medidas e "#n" cabiam, mesmo sem lugar pro nome.
  - Com a subida maior do iPad, esse tamanho não deixava espaço pro nome.
  - Na faixa estreita, a linha com o nome batia nas dobradiças no tamanho máximo e caía direto pra só "#n".
  - O callout (`cpCallouts`) levava só "#n medida".
- **Correção (só no iPad, marcada por `cpMet().ip`, que só existe quando a métrica em escala pequena do iPad é aplicada):**
  - no bloco "completo", se o nome não cabe, tenta os tamanhos menores (até 12, o mínimo legível) e só fica sem nome se nenhum servir;
  - na faixa estreita, a linha com o nome tenta os tamanhos menores antes das sem nome;
  - no callout, tenta "#n medida · nome" e, se não couber, o de antes.
- **Fora do iPad (Chromium, Android, Windows):** o mesmo plano do 955db9b0, byte a byte (24 cenas, hash rikh02). A única diferença em relação ao 71915d90 é o ganho do ID-SEMPRE: duas peças 2300×326 que não tinham texto ganharam "2300×326 #9". As posições das peças são idênticas.
- **Validação (Chromium, 24 cenas, 3098 peças):**
  - nomes na métrica normal: 2743, igual ao 71915d90;
  - com o iPad simulado: 2826, contra 2743 no 71915d90 e 2817 no 955db9b0;
  - peças que perdem o nome em relação ao 71915d90: 0, tanto no normal quanto no iPad.
- **Teste novo:** `testNOMEIPAD_ComAMetricaDoIPadOsNomesDasPecasNaoSomem` (métrica 1,00/0,30 e 1,13/0,30 com `ip`). No 955db9b0 falha: 246 com nome e "Lateral de gaveta" perdida. Com a correção: 271, sem perda.
- **iOS 708 (d8f36ead): o iPad falhou em 3 testes.** O iPhone passou nos passos A e B.
  - **1 e 2.** "furo dobradiça" em cima de "705" (Balcão 2 portas) e "roldana" em cima de "906" (porta de correr), nos terços 1 e 2 (mm e cm).
    - **Causa:** o `cpObs` calcula as caixas que a medida precisa evitar. Para os textos do desenho, ele usava a métrica fixa do Chromium: subida 0,95 e ±0,62 no texto centralizado. Mesmo no Chromium, o rótulo centralizado mede 0,65 para cima e 0,48 para baixo. No iPad a fonte sobe 1,13, e com os nomes em letra menor a medida passou a caber justo no espaço que, pela conta errada, estava livre.
    - **Correção (só no iPad, `ip`):** o `cpMet` mede também a subida e a descida do texto centralizado (MU/MD) nas mesmas escalas pequenas. O `cpObs` recebe a métrica da chapa e usa AS/DS/MU/MD. Fora do iPad, continua 0,95 e ±0,62 (SVG do Chromium igual, hash rikh02).
    - **Teste novo:** `testNOMEIPAD_RotuloDeFuroERoldanaNaoFicaEmCimaDaMedidaNoIPad`, com as caixas calculadas na métrica do iPad. No d8f36ead falha: 705, 906 nas 2 portas e 8 na cena de exemplo. Com a correção: 0.
  - **3.** `testCORTEPRIORIDADE…`, cenário "normal": no iPad deu 23 etiquetas de sobra, quando o esperado eram 25.
    - **Causa:** o cenário apagava a métrica forçada, e no iPad a medida real já é a do iPad, então ele não era o "normal".
    - **Correção:** a normal passa a ser forçada em 0,95/0,26, com comentário no teste. Entrou um cenário próprio para a métrica do iPad medida (1,13/0,26 com `ip`), que dá os mesmos 23 do iPad real, com identificação 0 e callout em cima de etiqueta 0.

## DOB-METAL (ETAPA 2 item 3, R3, 26/11): dobradiça na cor da porta — Claude 3
- **Módulo:** 3D, todas as portas com dobradiça de caneco (balcão, aéreo, torre, guarda-roupa) e o basculante.
- **Reproduzir:** pintar a porta com a ferramenta Pintar (madeira com textura) e abrir a porta no 3D. Calço, braço, caneco e parafusos saem na madeira da porta.
- **Causa raiz:** `hinges3`/`basHw3_` desenham a ferragem com o nome e a chave da porta (`CURN`/`CURK` = "N:Porta", `Porta#k`). Depois, o passo de pintura do 3D (`build_pc`, `pcOf`/`modMatId`) troca a cor e põe a textura (`mid`) em toda caixa com essa chave.
- **Correção:** toda caixa criada por `hinges3`/`basHw3_` ganha a marca `ferr`, e o passo de pintura pula as caixas `ferr`. As cores metálicas que o desenho já tinha ficam. Geometria, furação, lista, corte e DXF ficam iguais.
- **Família conferida:** balcão e aéreo, com a porta fechada e aberta: nenhuma caixa da dobradiça dentro de lateral, tampo ou base.
- **Teste:** `testE2ITEM3_DobradicaMetalicaNaoPegaACorDaPortaENaoAtravessa`. No 3174dbd8 dá "metal false · sem textura false"; agora passa.

## CANTO-165 (ETAPA 2 item 5, pedido do Adauto 26/11): portas do canto paravam em 90° sem obstáculo e abriam juntas — Claude 3
- **Módulo:** 3D, canto em L (baixo, aéreo, guarda-roupa; esquerdo e direito) e canto cego (balcão e aéreo; na esquerda e na direita).
- **Reproduzir:** canto em L com um vizinho faceado ao lado: a folha do fundo parava em 90°. Abrir só a folha do lado também abria a do fundo. A porta do canto cego abria só 90°.
- **Causa raiz:** `cnAng_` tratava qualquer vizinho encostado como obstáculo, mesmo faceado. O `partsOf` do canto marcava a folha do fundo aberta quando só a do lado (`od[1]`) estava aberta. A porta do canto cego usava o 90° fixo da porta comum.
- **Correção:**
  - `cnObs_` e `cgObs` listam só o que sai de fato para a frente da face das portas: tamponamento com avanço > 16,5 mm, vizinho mais fundo, tamponamento do vizinho que avança e puxador de barra do vizinho.
  - Sem obstáculo a abertura é 165°. Com obstáculo é 90°, e a folha do lado fica no limite que já existia, com aviso técnico (`ambMsg`) dizendo o quê e quanto, uma vez por mudança.
  - Cada folha abre sozinha (`od[0]` só para a do fundo). A do lado só espera a do fundo quando as duas estão abrindo juntas (aí uma cruza a outra).
  - Os botões de ângulo do canto e do canto cego são 90, 120 e 165. Corte, lista e 2D ficam iguais.
- **Observação:** o tamponamento automático da ponta tem `tpAv` 25, ou seja, avança 9 mm na frente da porta. Com ele a porta para em 90° com aviso, o que é correto pelo pedido. Faceado (`tpAv` 16), abre 165°.
- **Testes:**
  - novo `testE2ITEM5_PortasDoCantoAbrem165EmLECegoEsquerdaEDireita`: no 3174dbd8 dá "0 de 6" e o canto cego falha; agora passa;
  - ajustado `testPortasDeCantoRobocop…`: a folha do lado abre sozinha, com comentário do pedido;
  - `testArmarioDeCantoFolga…`: as duas juntas continuam em ordem, bateu 0;
  - `testFitaDeTopo…`: o filtro da porta tira a dobradiça (`ferr`, item 3).
