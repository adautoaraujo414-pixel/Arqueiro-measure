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

## TESTE-RECUO: testes novos não compilavam no iOS (CI 604, 17/11)
- **Erro:** `insufficient indentation of next N lines in multi-line string literal`. O JavaScript dos testes novos começava na coluna 0; no Swift, o texto entre `#"""` e `"""#` tem que estar pelo menos tão recuado quanto o `"""#`. A bateria do Windows/Chromium lê o JS direto e não acusa.
- **Correção:** só recuo (8 espaços) nas linhas do JS dos testes novos. Nenhuma conferência mudou.
- **Prevenção:** conferir o recuo dos blocos `#"""` antes de cada commit de teste (script na pasta de rascunho da sessão).

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
