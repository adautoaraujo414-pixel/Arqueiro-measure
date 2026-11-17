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
