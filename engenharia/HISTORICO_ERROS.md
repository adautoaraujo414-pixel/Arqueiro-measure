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
