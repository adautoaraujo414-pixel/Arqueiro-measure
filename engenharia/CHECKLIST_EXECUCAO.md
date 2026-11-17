# Checklist de execução — 160 pedidos e 89 defeitos (criado em 17/11/2026, atualizado a cada item)

**Fonte:** `AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md` (anexos 1 e 2). O status inicial é o da auditoria.

**Status atual:** só muda com evidência (commit + teste com nome + resultado por plataforma).

**Prioridade** (classificação automática pelo assunto, revisada a cada item):
- **P0:** dados, backup e salvamento.
- **P1:** precisão de marcenaria e editor.
- **P2:** demais funcionalidades.

**Colunas por plataforma:**
- **And/iOS/Win:** resultado na plataforma.
  - **ok** = teste nomeado passou na CI daquela plataforma;
  - **—** = não se aplica ou ainda não rodou;
  - **aparelho** = depende de teste manual.
- **Chromium:** não conta como aprovado de nenhuma plataforma.

## Pedidos (160)

| ID | Pedido | Status inicial | Prior. | Ação necessária | Commit | Teste | And | iOS | Win | Status atual |
|---|---|---|---|---|---|---|---|---|---|---|
| A01 | Perfil G com abertura dos dedos pra frente, parede de 42 atrás | VALIDADO | — | — | 7c939bc (publicado) | testPerfilGolaAberturaPraFrente… ok em band2 | | | | = inicial |
| A02 | Perfil G sólido, sem madeira aparecendo dentro | VALIDADO | — | — | 7c939bc · 328f602 | testPerfilGolaSolido… ok em band2 | | | | = inicial |
| A03 | Perfil G: afastamento da porta e rebaixo na caixa configuráveis | PARCIAL | P1 | rebaixo só entra na conta (não sai no corte nem no 3D); decisão sobre folga/rebaixo real | 7c939bc | testPerfilGAfastamentoERebaixo… ok em band2 | | | | = inicial |
| A04 | Furação da dobradiça padrão 120 no centro do caneco e 3D no mesmo furo | VALIDADO | — | — | 7c939bc · eb6ed5b | testFuracaoPadrao120…, testFuracaoDaDobradica… ok em band2 | | | | = inicial |
| A05 | Calço da dobradiça entra na divisória no 3D (16 modelos) | NÃO FEITO | P1 | decisão do Adauto | — | nenhuma | | | | = inicial |
| A06 | Tamponamento estica pela seta do 3D (lista, corte e 3D juntos); setas certas na parede lateral | VALIDADO | — | — | 7c939bc · 7b9bb3a | testTamponamentoDoAereoEstica…, …AfastadoDaParede…, testSetasDo3DNaParedeLateral | | | | = inicial |
| A07 | Travar a geladeira (não sai do lugar, porta abre) | VALIDADO | — | — | 7c939bc · 0f4644d | testGeladeiraTravada… ok em band2 | | | | = inicial |
| A08 | 🗑 do tamponamento = desmarcar Usar (medida e peça saem juntas) | VALIDADO | — | — | 7c939bc | testTamponamentoDaTorreNoLixo…, testMedidaComTamponamentoEhAPonta… ok em band2 | | | | = inicial |
| A09 | Tamponamento de baixo vira peça no módulo com base suspenso; travado onde não se aplica | VALIDADO | — | — | 7c939bc | testTamponamentoDeBaixoSoOnde… ok em band2 | | | | = inicial |
| A10 | Protocolo global de correção (registro, família, 14 erros, testes) | VALIDADO | — | — | CLAUDE.md §11 (todas as branches) | arquivo presente (entregável de documento) | | | | = inicial |
| A11 | Peças que não saíam pelo 🗑 (fundo, caixa da gaveta, lado do canto) sem fantasma | VALIDADO | — | — | 7c939bc | testToPecaQueO3DOfereceApagar… ok em band2 | | | | = inicial |
| A12 | Quadro da peça na parede lateral mostra as medidas da peça | VALIDADO | — | — | 7c939bc | testQuadroDaPecaNoModuloDaParedeLateral… ok em band2 | | | | = inicial |
| A13 | Menu do vão do balcão sem quadro repetido; Lixeira embutida na lista | VALIDADO | — | — | 7c939bc | testMenuDoVaoDoBalcaoDaCozinha… ok em band2 | | | | = inicial |
| A14 | Armário inteiro 15 mm abaixo da saia da pedra | VALIDADO | — | — | 7c939bc | testComSaiaNaPedra…, testArmarioEmbaixoDaPedraComSaia… ok em band2 | | | | = inicial |
| A15 | Peça apagada, ajuste, cor e fita seguem a peça (também no 2D só dele) | VALIDADO | — | — | 7c939bc | testPecaApagadaEAjusteDo3D…, testEntrarESairDoSoEle… ok em band2 | | | | = inicial |
| A16 | Lateral, base e divisória saem pela regra do móvel ou ficam bloqueadas com motivo | VALIDADO | — | — | 7c939bc | testLateralBaseEDivisoria… ok em band2 | | | | = inicial |
| A17 | Desempenho: caderno, arrasto 2D e animação 3D mais leves | VALIDADO | — | — | 7c939bc | testDesempenhoArrastarNo2D… ok em band2; CadernoDesempenhoTest (JVM) na CI Andro | | | | = inicial |
| A18 | Trocar a porta de cima da caixa da geladeira mexe só nela | VALIDADO | — | — | 7c939bc | testTorreDaGeladeiraTrocarAPorta…, …QueJaVirouPortaInteira… ok em band2 | | | | = inicial |
| A19 | Tamponamento no 2D muda só a altura dele, não move o móvel nem apaga a base | VALIDADO | — | — | 7c939bc; teste ajustado em 32154d4/790a990/a13c9e6 | testTamponamentoNo2DMudaSoAAltura… ok em band2 (falhava antes só pelo arrasto em | | | | = inicial |
| A20 | Profundidade do ambiente não fica presa; rebaixo do teto não passa da parede | VALIDADO | — | — | 7c939bc | testAmbienteParedeDoLadoProfundidade… ok em band2 | | | | = inicial |
| A21 | 3D volta sozinho depois da perda do contexto gráfico | VALIDADO | — | — | 7c939bc | test3DVoltaSozinhoQuandoOSistemaTira… ok em band2 | | | | = inicial |
| A22 | Módulo criado no 2D que não aparece no 3D (iOS) | PARCIAL | P1 | causa raiz desconhecida; falta o diagnóstico do aparelho do Adauto | 7c939bc (mitigação) | testModuloQueNaoApareceNo3DViraAviso…, testTodoModuloCadastradoApareceNo3D… ok e | | | | = inicial |
| A23 | Forno embutido a 3 mm da travessa | VALIDADO | — | — | 7c939bc | testFornoEmbutidoNoBalcaoA3mm… ok em band2 | | | | = inicial |
| A24 | Folga de 3 mm entre as folhas do canto em L | VALIDADO | — | — | 7c939bc | testArmarioDeCantoFolgaDe3mm… ok em band2 | | | | = inicial |
| A25 | Tampa cega continua cega no 2D só dele | VALIDADO | — | — | 7c939bc | testTampaCegaContinuaCega… ok em band2 | | | | = inicial |
| A26 | 1º toque depois do teclado não se perde | VALIDADO | — | — | 7c939bc | testDepoisDeDigitarOPrimeiroToque…, testDigitarETocarEmOutroCampo… ok em band2 | | | | = inicial |
| A27 | Valores: linha de cada ferragem, chapa pelo uso, mão de obra/custo fixo/despesas | VALIDADO | — | — | 7c939bc | testTelaValoresTodaFerragem…, testValoresCobraAChapa…, testMaoDeObraCustoFixo… o | | | | = inicial |
| A28 | Faixa da parede minimiza; 2 toques no vão do editor por vãos abrem menu rápido | VALIDADO | — | — | 7c939bc | testFaixaDaParedeMinimiza…, testEditorPorVaosDoisToquesNoVao… ok em band2 | | | | = inicial |
| A29 | Engrosso do tamponamento entrando no módulo | NÃO FEITO | P1 | falta saber qual módulo e lado | — | caso do Adauto não reproduzido; catálogo conferido por testTamponamentoSempreFor | | | | = inicial |
| A30 | Porta do aéreo encosta 0,8 mm na fita de borda da caixa | NÃO FEITO | P1 | decisão do Adauto | — | nenhuma | | | | = inicial |
| A31 | Setas da régua espaçadora do canto e do rodapé até o piso não mexem | NÃO FEITO | P1 | pendente no RELATORIO | — | nenhuma | | | | = inicial |
| A32 | Editor por vãos em todos os módulos; trava do “só ele no 2D” que converte módulo alto | PARCIAL | P1 | decisão de integrar | exp/editor-vaos-universal 4874f84 (não integrado) | nenhuma na linha publicada | | | | = inicial |
| A33 | Luz, metal e vidro realistas (protótipo) | PARCIAL | P2 | aprovar mudança do formato do vértice | prototipos/aqrender (fora do app) | só protótipo isolado; não medido em aparelho | | | | = inicial |
| A34 | Exportação para CNC (furação, rasgos, nesting) | NÃO FEITO | P1 | não iniciado | — | nenhuma | | | | = inicial |
| A35 | LED no ripado e na prateleira | VALIDADO | — | — | 7c939bc | testLedNoRipadoEmPe…, …DoisToquesDePerto…, …AbertoUmModoDeCadaVez… ok em band2 | | | | = inicial |
| A36 | Laterais por fora quadradas, engrosso por fora, canto em L nas duas montagens | VALIDADO | — | — | 7c939bc | testLateraisPorForaLateralQuadrada…, testCantoEmLLateraisPorDentroEPorFora… ok e | | | | = inicial |
| A37 | Rodapé em seção própria, MDF faceando/embutido, pés de metal | VALIDADO | — | — | 7c939bc | testRodapeDeMdfFaceando…, testPesDeMetalNoLugarDoRodape…, testPesDeMetalEmTodoTi | | | | = inicial |
| A38 | Setinha dos títulos das seções fecha e abre | VALIDADO | — | — | 7c939bc | testSetinhaDoTituloDaSecao… ok em band2 | | | | = inicial |
| A39 | “Lista de peças (ao vivo)” na aba Fundos mostra a peça no 3D | SEM VALIDAÇÃO | P1 | criar teste | 7c939bc | teste específico não localizado na bateria | | | | = inicial |
| A40 | Divisória/prateleira nova no meio do vão; divisória arrasta em qualquer projeto | VALIDADO | — | — | 7c939bc | testDivisoriaEPrateleiraNovas…, testDivisoriaArrastaComODedo… ok em band2 | | | | = inicial |
| A41 | Aéreo: fechamento até o teto; 2 toques no vão de cima (ripado, painel, fechamento) | VALIDADO | — | — | 7c939bc | testAereoFechamentoAteOTeto…, testDoisToquesNoVaoDeCimaAteOTeto… ok em band2 | | | | = inicial |
| A42 | Pedra vista de cima: 2 toques na cuba/cooktop, bolinhas pequenas; saia sem divisão | VALIDADO | — | — | 7c939bc | testPedraVistaDeCimaDoisToques…, testSaiaDaPedraSemDivisao… ok em band2 | | | | = inicial |
| A43 | 3D: aviso de módulo que não monta, sem faixa de dicas, parede do lado transparente, paredes criadas selecionam/apagam | VALIDADO | — | — | 7c939bc | testErroNoMontar…, test3DSemAFaixa…, testParedeDoLadoCom…Transparente…, testPare | | | | = inicial |
| A44 | Canto em L com profundidade de cada lado pela pedra | VALIDADO | — | — | 7c939bc | testCantoEmLProfundidadeDeCadaLado… ok em band2 | | | | = inicial |
| A45 | iPhone: toque no vão pega de primeira | VALIDADO | — | — | 7c939bc | testToqueNoVaoComoNoIPhone… ok em band2 (Chromium) | | | | = inicial |
| A46 | Troca de parede só no cabeçalho do 2D; quadro “Editando só” minimiza | VALIDADO | — | — | 7c939bc | testTrocaDeParedeSoPeloCabecalho…, testQuadroEditandoSoMinimiza… ok em band2 | | | | = inicial |
| A47 | Gavetas no vão pergunta quantas (1 a 6) | VALIDADO | — | — | 7c939bc | testGavetasNoVaoPerguntaQuantas… ok em band2 | | | | = inicial |
| A48 | Porta no forno vira frente com recorte e forno no meio | VALIDADO | — | — | 7c939bc | testPortaNoFornoViraFrente… ok em band2 | | | | = inicial |
| A49 | Painel do módulo sem Travar e sem Anti-erros | VALIDADO | — | — | 7c939bc | testPainelDoModuloSemTravar… ok em band2 | | | | = inicial |
| A50 | Régua de 80 do tamponamento escolhe e apaga só ela; tamponamento sempre por fora | VALIDADO | — | — | 7c939bc | testReguaDoTamponamentoEscolhe…, testTamponamentoSempreFora… ok em band2 | | | | = inicial |
| A51 | Módulo acima de 2700 vira continuação cortando na divisória | VALIDADO | — | — | 7c939bc | testModuloAcimaDe2700… ok em band2 | | | | = inicial |
| A52 | “Montar do zero” no fim de cada categoria; quarto sem cozinha | VALIDADO | — | — | 7c939bc | testMontarDoZeroNoFim… ok em band2 | | | | = inicial |
| A53 | Forno/nicho escolhe o aparelho e nunca encolhe; pedestal sem risco solto | VALIDADO | — | — | 7c939bc | testFornoEscolheOAparelho… ok em band2 | | | | = inicial |
| A54 | Puxador escolhido numa porta vale pro projeto todo | VALIDADO | — | — | 7c939bc | testPuxadorEscolhidoNumaPorta… ok em band2 | | | | = inicial |
| A55 | Módulos de paredes diferentes encostam no canto sem entrar | VALIDADO | — | — | 7c939bc | testModulosDeParedesDiferentesEncostam… ok em band2 | | | | = inicial |
| A56 | 3D: 2 toques longe abre o módulo, perto abre a peça | VALIDADO | — | — | 7c939bc | testDoisToquesNo3DLonge… ok em band2 | | | | = inicial |
| A57 | Abrir portas e gavetas (quadro, abrir tudo, caixote, gaveta interna) | VALIDADO | — | — | 7c939bc | testAbrirPortasEGavetasFuncionaEmTodoJeito…, …DoQuadroNo3D… ok em band2 | | | | = inicial |
| A58 | Travessa do pedestal 450×100 e fundo da gaveta do caixote no 3D | VALIDADO | — | — | 7c939bc | testBateriaNovaCatalogoSalvarReabrir… (asserção semLateral 450×100) ok em band2 | | | | = inicial |
| A59 | Tirar tamponamento esquerdo devolve o módulo | VALIDADO | — | — | 7c939bc | testTirarTamponamentoEsquerdoDevolve… ok em band2 | | | | = inicial |
| A60 | Tamponamento invertido (catálogo, peça corrida, “só até a cava”) | VALIDADO | — | — | 7c939bc | testTamponamentoInvertidoNaoMuda…, …PeloToque…, …APecaEAMesma… ok em band2 | | | | = inicial |
| A61 | Pedra em qualquer parede; pedra nova dividida com móvel alto; módulo novo depois do canto | VALIDADO | — | — | 7c939bc | testPedraEmQualquerParede…, testPedraNovaNaoAtravessaMovelAlto… ok em band2 | | | | = inicial |
| A62 | Tamponamento não entra na pedra; sem espaço não liga | VALIDADO | — | — | 7c939bc | testTamponamentoNaoEntraNaPedra… ok em band2 | | | | = inicial |
| A63 | Porta de cava para no topo com tamponamento de cima (34 modelos) | VALIDADO | — | — | 7c939bc | testPortaNaoEntraNoTamponamentoDeCima… ok em band2 | | | | = inicial |
| A64 | Balcão mais alto que a pedra fica na altura dela e avisa | VALIDADO | — | — | 7c939bc | testModuloDeBaixoSeAdaptaAAlturaDaPedra… ok em band2 | | | | = inicial |
| A65 | Módulo de baixo erguido e devolvido: rodapé, travessa e moldura voltam | SEM VALIDAÇÃO | P1 | teste dedicado | 7c939bc | teste específico não localizado (só a nota do HISTORICO TAMP-2D-ALVO) | | | | = inicial |
| B01 | Assumir engenharia: branches, checkpoint 0aa152c, arquitetura, publicação, branch isolada | VALIDADO | — | — | ARQUITETURA.md, RELATORIO | documentos presentes | | | | = inicial |
| B02 | Bateria real, mapa de embrulhos, riscos de perda, plano gradual, sondas e testes por propriedade | VALIDADO | — | — | AUDITORIA_INTEGRIDADE.md, tools/sondas (45 arquivos) | documentos e sondas s01–s31 registradas (HOMOLOGACAO_9ec0869) | | | | = inicial |
| B03 | Desenhar não pode modificar o projeto (draw/confineAll/stPush) | VALIDADO | — | — | 9ec0869 → 7c939bc | testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho ok em band2; sonda s10 | | | | = inicial |
| B04 | Tamponamento determinístico; ação explícita × automática; esquerdo/direito simétricos; sem espaço cancela | VALIDADO | — | — | 9ec0869 → 7c939bc | testTamponamentoMovelExistenteNaoEEmpurrado…, …EsquerdoLigado…, …DireitoLigado…, | | | | = inicial |
| B05 | Posição digitada deixa vão de 35 mm junto à parede | NÃO FEITO | P1 | autorizar correção | — | sonda s13 ainda acusa (FASE2_SELECAO) | | | | = inicial |
| B06 | Reconhecer histTick (desfazer) e ampliar testes de salvar | VALIDADO | — | — | 7c939bc | testDesfazerERefazerDevolvemOProjetoIgualPassoAPasso ok em band2; sonda s28 | | | | = inicial |
| B07 | Churrasqueira quadrada conforme referência | NÃO LOCALIZADO | P2 | reenviar referência | — | nenhum registro em commits, engenharia/, novidades ou testes | | | | = inicial |
| B08 | Correções de textura da pia e da área molhada | NÃO LOCALIZADO | P2 | reenviar o pedido exato | — | nenhum registro (AUDITORIA_INTEGRIDADE) | | | | = inicial |
| B10 | Auditoria de desempenho (reconstrução 3D, vazamento, eventos) | VALIDADO | — | — | PERFORMANCE.md; sonda s24 | sonda s24 (40 módulos, sem vazamento) | | | | = inicial |
| B11 | Plano de separação da arquitetura (sem implementar) | VALIDADO | — | — | ARQUITETURA.md, PLANO_EVOLUCAO.md | documentos presentes | | | | = inicial |
| B12 | projects.json vazio/quebrado não apaga a cópia boa | VALIDADO | — | — | 73ec2f3 → 7c939bc | testArquivoDeProjetosVazioOuQuebrado… ok em band2; sonda s08a | | | | = inicial |
| B13 | Restauração de backup segura (Android e Windows; iOS validado) | VALIDADO | — | — | f96b3e5 → 7c939bc | JVM backup 13/13 e 16/16 (FASE2); CI Android 635 com BackupCaminhoTest; sonda de | | | | = inicial |
| B14 | Engrosso preservado; abrir sem mexer não regrava | VALIDADO | — | — | 37c9915, 0e353e3, 74fa8b1 → 7c939bc | testEngrossoDoProjetoNaoSome…, testAbrirProjetoSemMexerNaoRegrava… ok em band2;  | | | | = inicial |
| B15 | Ambiente não modifica móveis; aviso com módulo/medida/disponível/diferença; móvel novo × existente (roomClamp) | PARCIAL | P1 | não cobertos: sanBase, wallFollow de painéis até o teto, confine no arrasto (HISTORICO GEO-AVISA) | 04ab7cf, 80aa4a1, 9ec0869 → 7c939bc | testAmbienteNaoModificaOsMoveisSoAvisa ok em band2; sondas s11, s27, s29 | | | | = inicial |
| B16 | Gravação desnecessária da biblioteca inteira depois da 1ª alteração | SEM VALIDAÇÃO | P2 | confirmar o que foi corrigido | 74fa8b1 (gravação leve na abertura) — hipótese | testAbrirProjetoSemMexerNaoRegrava… e testSalvarLeve… ok em band2; registro espe | | | | = inicial |
| B17 | testParedeLateralNaoCresceSozinha: preservar x=2170 sem aprovar no automático | VALIDADO | — | — | 7c939bc | testParedeLateralNaoCresceSozinha ok em band2; sonda s30 | | | | = inicial |
| B18 | Regra dos 9 mm nos encontros só ao posicionar, nunca ao abrir/desenhar | VALIDADO | — | — | 9ec0869 | sonda s31 (“regra do canto só ao posicionar”) | | | | = inicial |
| B19 | Eletrodomésticos reais com dimensões bloqueadas e requisitos de instalação | NÃO FEITO | P2 | não iniciado | só especificação registrada (213430c) | nenhuma | | | | = inicial |
| B20 | Padronização estrutural universal (portas, gavetas, prateleiras no vão certo) | NÃO FEITO | P1 | não iniciado | — | nenhuma | | | | = inicial |
| B21 | Sincronização imediata 2D/3D (vão → gavetas com o 3D aberto) | NÃO FEITO | P1 | autorizar | — | sonda s23 ainda acusa | | | | = inicial |
| B22 | Móvel novo do catálogo não é redimensionado para caber (avisa a diferença) | NÃO FEITO | P1 | implementar na etapa de posicionamento | regra registrada em DECISOES | sonda s29: ainda ajusta a largura | | | | = inicial |
| B23 | Módulo do catálogo entra por cima dos vizinhos em parede cheia | NÃO FEITO | P1 | — | — | sonda s20 ainda acusa | | | | = inicial |
| B24 | Folga do rack que não volta; módulo da parede lateral que anda e não volta | NÃO FEITO | P1 | — | — | sonda s27 ainda acusa | | | | = inicial |
| B25 | Travessa e moldura perdidas ao alternar sup/rack (sanBase) | NÃO FEITO | P1 | — | — | nenhuma | | | | = inicial |
| B26 | Validação de peças flutuantes e interseções indevidas | PARCIAL | P1 | — | — | testes antigos testSolidoNadaEntraEmNada…, testBateriaNova…PecaNaoEntraEmPeca… o | | | | = inicial |
| B27 | Aviso de pedra/lixeira/objetos fora da parede (3 plataformas) | NÃO FEITO | P1 | melhoria pendente | b1c6dc8 (só registro) | nenhuma | | | | = inicial |
| C01 | Divisória/prateleira de outro módulo mexe só nela | VALIDADO | — | — | d77ff63 → 7c939bc | testSelecaoDivisoriaDeOutroModulo…, testSelecaoPrateleiraDeOutroModulo… ok em ba | | | | = inicial |
| C02 | Abrir outro projeto zera seleção, alvo do 🗑 e “Só a pedra no 3D” | VALIDADO | — | — | 7db71af, d612d17 → 7c939bc | testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto, testSelecaoEscolhasDeTelaZe | | | | = inicial |
| C03 | Vão escolhido sempre existe no módulo escolhido | VALIDADO | — | — | 7a95037 → 7c939bc | testSelecaoVaoEscolhidoExiste… ok em band2 | | | | = inicial |
| C04 | Porta de cima da torre de forno/micro muda só ela | VALIDADO | — | — | 7c939bc | testSelecaoPortaDeCimaDaTorre…, testSelecaoTorrePortaDeCimaPeloVao… ok em band2 | | | | = inicial |
| C05 | gv não cria vão fantasma em leitura | VALIDADO | — | — | 7c939bc | 7 testes testGv… ok em band2; gv_p1.log 7/7 | | | | = inicial |
| C06 | Limpar divisões volta o vão escolhido pro primeiro | VALIDADO | — | — | 7c939bc | testGvLimparDivisoesVoltaOVao… ok em band2; gvc_c.log 8/8 | | | | = inicial |
| C07 | Publicar Android e Windows (5a468bf → 7c939bc) | VALIDADO | — | — | release apk-632 e win-143 (7c939bc) | releases no GitHub; Adauto confirmou 1.0.632 instalada (msg 31) | | | | = inicial |
| C08 | Backup com “..” no nome: aceita foto..jpg, bloqueia ../fora.txt | VALIDADO | — | — | 7c939bc | BackupCaminhoTest (CI Android 635 passou); Windows JVM 134/134 (FASE2) | | | | = inicial |
| C09 | Enviar iOS 3.0.13 ao TestFlight | NÃO FEITO | P2 | autorização futura | — | não enviado; suspenso pelo Adauto (msg 30) | | | | = inicial |
| C10 | Homologação completa do iOS (iPhone e iPad) e finalizar iOS depois do Android | PARCIAL | P2 | iPad; SubscriptionTests test05; StoreKit ok 11/11 | CI 607, 609, 611, 613, 615, 616 | iPhone: só a falha antiga do tamponamento; 616 falhou em SubscriptionTests.test0 | | | | = inicial |
| C11 | Teste da cuba ajustado à regra GEO-AVISA (sem mudar o app) | VALIDADO | — | — | 18027d8 | testCubaArrastaNoTouch…ParedeEncolhida ok em band2 | | | | = inicial |
| D01 | Régua do batente cava com altura/largura manual (só esta / módulo / projeto) | NÃO FEITO | P2 | cancelado: “preservar a lógica atual” (msg 51) | proposta c367d4c | nenhuma | | | | = inicial |
| D02 | Altura do batente cava calcula as frentes e posiciona batentes | NÃO FEITO | P2 | cancelado pela decisão de 17/11 12:26; branch congelada | claude/arquemestre-batente-cava 507db9b (não usar) | bcava_novo.log 4/5 (testBatenteCavaEmTodosOsModelos… falha) | | | | = inicial |
| D03 | 1º toque em módulo não escolhido só escolhe, nunca move | VALIDADO | — | — | a9a195b → candidata a13c9e6 | testF3PrimeiroToque… ok em band2; iOS 609 só falha antiga | | | | = inicial |
| D04 | Divisória só na área dela; 2 toques não fecham o vão; tremida não move | VALIDADO | — | — | 469c0d0, 759ccf0 → a13c9e6 | testF3SelecaoDivisoriaDoisToquesETremida… ok em band2 | | | | = inicial |
| D05 | Medida inválida recusada com aviso, sem arredondar | VALIDADO | — | — | 849a46b → a13c9e6 | testF3MedidaInvalidaRecusada… ok em band2 | | | | = inicial |
| D06 | Menus na mesma ordem em todos os módulos | VALIDADO | — | — | 4543c0f → a13c9e6 | testF3MenusNaMesmaOrdem… ok em band2 | | | | = inicial |
| D07 | Azul de seleção mais suave | SEM VALIDAÇÃO | P1 | conferência visual pelo Adauto | c1d584f → a13c9e6 | sem teste próprio (só visual) | | | | = inicial |
| D08 | Réguas/setas que não aumentavam ou diminuíam certo | VALIDADO | — | — | 8fa40d5, d59831f → a13c9e6 | testF3SetaDeTras…, testF3CamadasDoEngrossoCava… ok em band2 | | | | = inicial |
| D09 | Rodapé fora do plano de corte (opção A, trechos do rodapé corrido) | SEM VALIDAÇÃO | P1 | bateria e iOS no commit final; integrar | claude/arquemestre-plano-corte 3c1a677/43114be | testPlanoDeCorteRodapeFora… (log local não encontrado); Windows 349/351 antes do | | | | = inicial |
| D10 | Travamento ao “Achar peça” no plano de corte | NÃO FEITO | P1 | reproduzir, causa e teste | só investigação em $SP/achar (sem commit) | nenhuma | | | | = inicial |
| D11 | Digitar parede/pé-direito não esmaga nem move móveis; aviso verdadeiro | VALIDADO | — | — | 6a319d7, b9da40b → 790a990 → a13c9e6 | testP0ParedeEPeDireitoDigitados…, testP0ParedeMenorQueOsMoveis…, testP0ParedeDes | | | | = inicial |
| D12 | Tirar peça do plano de corte por toque longo 1,5 s / clique direito, por identidade | SEM VALIDAÇÃO | P1 | bateria e iOS no commit final; integrar | plano-corte 3c1a677 (pcMenu, modUid, pcIds) | testPlanoDeCorteToqueLongo… (log local não encontrado); iOS não concluído | | | | = inicial |
| D13 | Peças brancas juntas no plano de corte | SEM VALIDAÇÃO | P1 | idem | plano-corte 3c1a677 (pcBranco) | testPlanoDeCortePecaBranca… (log local não encontrado) | | | | = inicial |
| D14 | Lateral do meio inteira junto das gavetas no inferior da cozinha (com rebaixo); aviso para módulo antigo | PARCIAL | P1 | base e travessa em 2 peças não feitas (aguarda confirmação) | claude/arquemestre-lateral-inteira 3991175 | testLateralDoMeioJuntoDasGavetas…; Windows 348/349 (ESTADO); iOS 613 só falha an | | | | = inicial |
| D15 | Só avisar profundidades diferentes entre vizinhos | VALIDADO | — | — | lateral-inteira 3991175 (data-vpav) | coberto no testLateralDoMeio… (iOS 613) | | | | = inicial |
| D16 | Altura das laterais da gaveta por 2 toques, 1 mm, divisão inteira acompanha | VALIDADO | — | — | claude/arquemestre-ajustes-3d a9b1da7 | testA6AlturaDasLaterais… 13/13 em 1024×1366 e 1920×1080 (telas.log); Windows 45; | | | | = inicial |
| D17 | Frente e contra-frente: ajuste de 1 mm só na peça, com aviso de encaixe | VALIDADO | — | — | ajustes-3d c2951f0 + 3bab8a8 | testA6AjusteDe1mmSoNaPeca… (telas.log); cmp6 107/109 (falhas antigas) | | | | = inicial |
| D18 | Porta/janela da parede: 1 toque seleciona, 2 toques abrem a configuração | NÃO FEITO | P1 | substituído pela ordem de preservar o 1 toque | 890e06e revertido em 0fad7ef | revertido por ordem do Adauto (msg 66–67) | | | | = inicial |
| D19 | 1 toque igual ao original + teste de regressão | SEM VALIDAÇÃO | P1 | rodar depois do 9d8727d | bb7bd67; mira do teste corrigida em 9d8727d | testUmToqueNaPortaDaParede… ok em 1024/1920 e falha em 390/844 (mira) no telas.l | | | | = inicial |
| D20 | Travessão interno/externo, com Frontal (recuo), lateral do meio até o topo, painel Moldura → Travessão → Frontal | PARCIAL | P1 | família reduzida: sem racks, homes, TV, canto e laterais por fora | claude/arquemestre-travessao a862927 | testTravessaoInternoExternoComESemFrontal… (relacionados 67/68); iOS 615 só falh | | | | = inicial |
| D21 | Item 7: regras automáticas de Moldura e Frontal | NÃO FEITO | P1 | apresentar dúvidas antes | — | nenhuma | | | | = inicial |
| D22 | Salvar nos meus modelos com a estrutura paramétrica (recalcula no novo tamanho) | NÃO FEITO | P1 | idem | — | não verificado com m.tvs/m.latMeio | | | | = inicial |
| D23 | Identidade estável única de módulo e peça (corte, editor, 3D) | PARCIAL | P1 | estender ao editor e ao 3D | modUid/pcIds só na branch plano-corte | só no plano de corte | | | | = inicial |
| D24 | Testes numéricos 3D = lista = corte em todas as montagens | PARCIAL | P1 | moldura, frontal, modelos | travessao a862927 | só o travessão tem teste numérico | | | | = inicial |
| D25 | Tamponamento editável por 2 toques no 3D, campo numérico e ±1 mm | NÃO FEITO | P1 | fila; aguarda referência | — | nenhuma (só a seta antiga, A06) | | | | = inicial |
| D26 | Tamponamento superior com lateral descendo à esquerda/direita | NÃO FEITO | P1 | fila; vídeo não chegou | — | grep no editor: inexistente | | | | = inicial |
| D27 | Mostrar medida livre real do vão (largura e altura) | NÃO FEITO | P1 | fila | — | grep no editor: inexistente | | | | = inicial |
| D28 | 2 toques de longe: quadro + destaque do módulo; 2 toques no destino movem | VALIDADO | — | — | ajustes-3d 9d3bcce | testA6DoisToquesDeLonge… 13/13 em 1024 e 1920; Windows 45; iOS 611 | | | | = inicial |
| D29 | Mover entre paredes (módulo, geladeira, eletro, porta/janela) bloqueando só colisão real; nada preso | VALIDADO | — | — | ajustes-3d 2ac1ddc, 6aacd8a | testA6MoverPor2ToquesConfereColisao…, testA6DepoisDeBloquear… (telas.log 8812) | | | | = inicial |
| D30 | Precisão com zoom; não escolher peça escondida | NÃO FEITO | P1 | caso real do Adauto | — | não reproduzido | | | | = inicial |
| D31 | Porta piscando nos 2 toques sem atrasar o 1 toque | NÃO FEITO | P1 | medir no aparelho | opção A testada e não mantida (052ef9e) | sem diferença medida no Chromium | | | | = inicial |
| D32 | Gestos em telas, orientações e zoom diferentes | VALIDADO | — | — | ajustes-3d 2ca030a, 7c12109 | telas.log: 390×844 12/13, 844×390 11/13, 1024×1366 13/13, 1920×1080 13/13 | | | | = inicial |
| D33 | Preservar 3, 4 e 5 toques | VALIDADO | — | — | preservado | testA6DoisToquesDeLonge… (3 toques não preparam mover); testPedraSolida…5ToquesE | | | | = inicial |
| D34 | Desempenho e resposta imediata medidos e comparados | PARCIAL | P2 | medir no aparelho | HISTORICO item 6; PERFORMANCE.md | medição item 6 (40 módulos, sem piora); FPS e aparelho real não medidos | | | | = inicial |
| D35 | CLAUDE.md §12 e §13 nas instruções permanentes | PARCIAL | P2 | levar à linha principal com autorização | claude/arquemestre-protocolo-cirurgico f373a03, ce89354 | só nessa branch; CLAUDE.md da P0 vai até §11 | | | | = inicial |
| D36 | Registrar o plano mestre no repositório | VALIDADO | — | — | protocolo-cirurgico ed63f59 | engenharia/PLANO_MESTRE.md | | | | = inicial |
| D37 | Continuidade: estado real, commits, testes e pendências no repositório | PARCIAL | P2 | atualizar | protocolo-cirurgico cb3a2de | ESTADO_E_CONTINUACAO.md existe, mas está defasado (P0 4aca2bb, item 6 6aacd8a, s | | | | = inicial |
| D38 | Canto em L: folha do lado cobre 5 mm atrás e folga de 4 mm | SEM VALIDAÇÃO | P1 | iOS; integrar | claude/arquemestre-canto-folha-lado e1d79b3 | 4 expectativas atualizadas; Windows 347/348 (ESTADO); iOS do canto não concluído | | | | = inicial |
| D39 | Biblioteca de cantos: 8 modelos (L e cego, baixo e aéreo, esq. e dir.) | VALIDADO | — | — | já existiam em 8c0ce76 (AUDITORIA_LINHAS §6) | verificação de leitura: os 8 entram com peças; decisão: preservar | | | | = inicial |
| D40 | Auditoria geral de exclusão e consistência | NÃO FEITO | P2 | fila | — | nenhuma | | | | = inicial |
| D41 | Fita de 0,8 mm do rebaixo desenhada dentro da travessa frontal no 3D (só visual) | SEM VALIDAÇÃO | P1 | bateria completa | claude/arquemestre-fita-rebaixo-3d af0c55e | testFitaDoRebaixoNaoFicaDentroDaTravessa… ok (bft.log); bateria depois do ajuste | | | | = inicial |
| D42 | Fita de 0,8 mm dentro de porta/frente fechada no 3D (só visual) | SEM VALIDAÇÃO | P1 | bateria completa | claude/arquemestre-fita-portas-3d 1454596/9a865e9 | testFitaNaoFicaDentroDaPortaOuFrenteFechada… ok (bfp.log); bateria final parcial | | | | = inicial |
| D43 | Fita de borda 1 mm padrão; quadro distingue corte × acabada | NÃO FEITO | P1 | definir 560 ou 561 no quadro | só decisão (DECISOES, 0549561) | nenhuma | | | | = inicial |
| D44 | Menu Pintar compacto (cabeçalho 2 linhas, ordem dinâmica, 2 colunas no tablet) | NÃO FEITO | P2 | fila, sem mexer no minimizar compartilhado | só decisão (PLANO_MESTRE 8b) | nenhuma | | | | = inicial |
| D45 | Tirar o “#1” só da apresentação do nome da peça | NÃO FEITO | P1 | fila | — | nenhuma | | | | = inicial |
| D46 | Corrigir só o teste testTamponamentoNo2D… (mm pela escala, folga do app) | VALIDADO | — | — | 32154d4, 790a990, a13c9e6 | testTamponamentoNo2D… ok em band2; 6 telas (HOMOLOGACAO_ANDROID) | | | | = inicial |
| D47 | Corrigir só o teste testToPecaQueO3DOfereceApagar… (identidade, totais da geometria) | SEM VALIDAÇÃO | P1 | rodar bateria | fita-rebaixo 288e0e2, 49996ac | sem rodada completa depois da correção | | | | = inicial |
| D48 | Corrigir só o teste testFitaDaBaseEmbaixoDaPorta… (mira pela geometria) | VALIDADO | — | — | 6058b74 (candidata), 9a865e9 (fita-portas) | testFitaDaBase… ok em band2; 3/3 nas duas versões e com zoom | | | | = inicial |
| D49 | Auditoria só de leitura das linhas (publicado, main, branches) e estratégia | VALIDADO | — | — | protocolo-cirurgico 28c356d | engenharia/AUDITORIA_LINHAS.md | | | | = inicial |
| D50 | Rodar iOS das branches plano de corte, lateral, canto e travessão | PARCIAL | P1 | concluir 612/614 e iPad | CI 612–615 | lateral (613) e travessão (615): só falha antiga; plano de corte e canto: rodand | | | | = inicial |
| D51 | Candidata Android (P0 + Fase 3), escopo congelado, homologada | VALIDADO | — | — | claude/arquemestre-candidata-android a13c9e6 (+6b0e9cd doc) | band2.log 357/357; CI Android 635; projetos 15/15; backup 6/6; Windows 46 356/35 | | | | = inicial |
| D52 | Publicar a candidata Android | NÃO FEITO | P2 | “sim” do Adauto para a13c9e6 | — | não publicado (ponteiro segue apk-632) | | | | = inicial |
| D53 | APK separado para teste no aparelho, sem mexer no app instalado | VALIDADO | — | — | release teste-android-635 (a13c9e6) | release existe no GitHub | | | | = inicial |
| D54 | Investigar as 3 falhas (ímã/linha verde, tamponamento, fita da base) 3× em cada versão | VALIDADO | — | — | HOMOLOGACAO_ANDROID_a13c9e6.md | iso3.log, tfb.log; 3/3 nas duas versões | | | | = inicial |
| D56 | Finalizar Windows depois do iOS | PARCIAL | P2 | gerar e validar pacote | — | Windows 46 em fc98cc5 356/357; pacote da candidata não gerado | | | | = inicial |
| D57 | Linha de integração segura das branches | NÃO FEITO | P2 | autorização | proposta claude/arquemestre-integracao (não criada) | nenhuma | | | | = inicial |
| D58 | Auditoria master final de todas as ferramentas | NÃO FEITO | P2 | última etapa | — | nenhuma | | | | = inicial |
| D59 | Inventário de pendências e AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md | PARCIAL | P2 | consolidar o relatório | esta auditoria (scratchpad) | em andamento | | | | = inicial |

## Defeitos (89)

| # | ID | Defeito | Status inicial | Prior. | Ação necessária | Commit | Teste | And | iOS | Win | Status atual |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | GOLA-001 puxador gola invertido (perfil G) | Abertura dos dedos para dentro, parede de 42 na frente, placa escura | VALIDADO | — | — | fcfcf28 | `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical` ·  | | | | = inicial |
| 2 | GOLA-002 | Madeira aparecendo dentro do perfil G (parecia transparente) | VALIDADO | — | — | 328f602 | `testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado` · existe · ok | | | | = inicial |
| 3 | TAMP-SETA | Tamponamento não aumentava pela seta do 3D | VALIDADO | — | — | 7b9bb3a, ddb41c8 | `testTamponamentoDoAereoEsticaPelaSetaDo3DMesmoTocandoNaReguaListaCorteE3DReabre`, `testTa | | | | = inicial |
| 4 | GEL-TRAVA (geladeira, pedido) | Geladeira sem trava; "travada" saía do lugar | VALIDADO | — | — | 0f4644d | `testGeladeiraTravadaNaoSaiDoLugarNemMudaDeMedidaMasAbreNormal` · existe · ok | | | | = inicial |
| 5 | DOB-3D-FURD | Dobradiça no 3D a 100 fixo, plano de corte a 120 | VALIDADO | — | — | eb6ed5b | `testFuracaoPadrao120NoCentroDoCanecoAjustavelEInstalacaoAntigaFicaCom100` · existe · ok | | | | = inicial |
| 6 | DOB-DIVISORIA | Calço da dobradiça entra na divisória no 3D (16 modelos) | NÃO FEITO | P1 | Só 3D. Sem teste | — | nenhum | | | | = inicial |
| 7 | TESTE-FAIXA-WEBKIT | 2 testes da faixa da parede falhavam no iPhone | VALIDADO | — | — | 1730073, 328f602 | `testTrocaDeParedeSoPeloCabecalhoDo2DSempreVisivelEPainelGuardado`, `testFaixaDaParedeMini | | | | = inicial |
| 8 | IOS-ABRE-20S | `testEditorAbreComoNoAppSemTelaBranca` passa de 20 s no CI | NÃO FEITO | P2 | Pendente, só observado | — | `testEditorAbreComoNoAppSemTelaBranca` (em `EditorAppPathTests.swift`, fora da bateria do  | | | | = inicial |
| 9 | 3D-045 (3D sem o módulo) | Módulo criado no 2D não aparece no 3D (iOS) | PARCIAL | P1 | Não reproduzido. `ST3ONLY=0` só no `loadState` de outro projeto; fechar o 3D não desliga (FATO: `grep ST3ONLY= | e3d68b8 (mitigação); 7db71af (zera `ST3O | `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa`, `testTodoModuloCadastradoAp | | | | = inicial |
| 10 | WEBGL-001 | 3D apagado depois da perda do contexto gráfico | VALIDADO | — | — | 457d30d (+c6d4808 teste) | `test3DVoltaSozinhoQuandoOSistemaTiraEDevolveOContextoGrafico` · existe · ok (via bateria  | | | | = inicial |
| 11 | TAMP-ENGROSSO | Engrosso do tamponamento entrando no módulo ("gravíssimo") | NÃO FEITO | P1 | Sem correção; o teste só prova o catálogo padrão | — | `testTamponamentoSempreForaDoModuloEmTodosOsModelosComReguasDe80` (guarda) · existe · ok | | | | = inicial |
| 12 | FORNO-3MM (torre/balcão forno) | Folga em cima do forno embutido ≠ 3 mm | VALIDADO | — | — | e3d68b8 | `testFornoEmbutidoNoBalcaoA3mmDaTravessaESemNaN` · existe · ok | | | | = inicial |
| 13 | CANTO-3MM (porta do canto) | Portas do canto em L batendo | VALIDADO | — | — | 503b9ad, 97b6eef | `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra` · existe · ok | | | | = inicial |
| 14 | TESTE-45-WEBKIT | Teste do PEDIDO 45 diferente no Safari | VALIDADO | — | — | 457d30d | `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa` · existe · ok | | | | = inicial |
| 15 | TESTE-CANTO-67 | Canto do guarda-roupa abria 67° no CI | SEM VALIDAÇÃO | P1 | Nome do teste não registrado | 457d30d | `testPortasDeCantoRobocopAbremEmOrdemSemEntrarEmNada`/teste do canto (nome exato não citad | | | | = inicial |
| 16 | BAT-FLAKY (2 entradas) | Testes que falham só com carga | PARCIAL | P2 | `amort` pendente | 93495d1 | `testSoOModulo3DE2DComPortaGavetaEDivisoriaSoNele`, `testOrganizacao3DClienteEModoPessoa`, | | | | = inicial |
| 17 | BAT-SILENCIO (notas) | Script da bateria pulava teste sem JSON | SEM VALIDAÇÃO | P2 | Sem teste do script | fcfcf28 (1º commit com "SEM RESULTADO",  | nenhum teste próprio | | | | = inicial |
| 18 | TAMPA-CEGA (notas) | Tampa cega virava porta comum no "2D só dele" | VALIDADO | — | — | 5ea63f0 (1º commit do teste) | `testTampaCegaContinuaCegaNoEditorPorVaosNaoAbreSemDobradicaNemPuxador` · existe · ok | | | | = inicial |
| 19 | TECLADO-TOQUE (notas) | 1º toque perdido depois do teclado | SEM VALIDAÇÃO | P1 | Teste não identificado | ab10e5d ("toques depois de digitar não s | histórico diz "com teste" sem nome. HIPÓTESE: `testTecladoNumericoNuncaCobreOCampo` (ok) | | | | = inicial |
| 20 | VALORES-FERRAGEM (notas) | Tabela Material sem corrediça oculta e facetado | VALIDADO | — | — | ab10e5d (1º commit do teste) | `testTelaValoresTodaFerragemQueEntraNoTotalTemLinhaNaTabela` · existe · ok | | | | = inicial |
| 21 | FITA-08 (fita de borda) | Porta do aéreo entra 0,8 mm na fita da caixa (3D) | PARCIAL | P1 | Posição da porta não mudou (fora do escopo) | Decisão pendente. Recorte visual só em 1 | `testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D` · **não existe** na candidata · ok em `b | | | | = inicial |
| 22 | TAMP-XP (tamponamento invisível) | Tamponamento marcado, contado na medida, sem a peça | VALIDADO | — | — | b3c1e74 | `testTamponamentoDaTorreNoLixoDesmarcaAMedidaSegueAPecaEProjetoAntigoSoAvisa`, `testMedida | | | | = inicial |
| 23 | TB-MED | "Aumentar comprimento" do tamponamento de baixo contava sem peça | VALIDADO | — | — | b3c1e74 | `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo` · existe · ok | | | | = inicial |
| 24 | TB-BASE (tamponamento invisível) | Tamponamento inferior marcado em módulo com base sem peça (83 modelos) | VALIDADO | — | — | 93495d1 | `testTamponamentoDeBaixoSoOndeViraPecaComBaseSuspensoTemPecaNoChaoNaoSeAplica` · existe ·  | | | | = inicial |
| 25 | XP-PK (peças fantasmas) | Mexer num vão fazia peça apagada de outro voltar; ajuste 3D pulava de porta | VALIDADO | — | — | 93495d1 | `testPecaApagadaEAjusteDo3DSeguemAPecaQuandoOutroVaoMuda` · existe · ok | | | | = inicial |
| 26 | XP-ESTRUTURAL | 🗑 tira lateral/base/divisória/**rodapé/travessa** e as vizinhas continuam descontando | PARCIAL | P1 | A correção registrada cobre lateral, base, base de cima e divisória. **Rodapé e travessa não aparecem na corre | 93495d1 | `testLateralBaseEDivisoriaSaemPelaRegraDoMovelOuNaoSaemComMotivo` · existe · ok | | | | = inicial |
| 27 | RGQK-LARGA | 2 toques no vão do editor por vãos não abria em tela larga | VALIDADO | — | — | b3c1e74 | `testEditorPorVaosDoisToquesNoVaoAbreMenuRapidoComAsAbasEBotoesDoPainel` · existe · ok (13 | | | | = inicial |
| 28 | FUNDO-LIXO (exclusão de fundo) | Fundo oferecia 🗑 no 3D e não saía | VALIDADO | — | — | b3c1e74 | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | | | | = inicial |
| 29 | GAV-FANTASMA (peças fantasmas / 3D inventando peças) | Lateral/contra-frente da gaveta apagada continuava no 3D | VALIDADO | — | — | b3c1e74, 93495d1 | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | | | | = inicial |
| 30 | CANTO-FANTASMA (peças fantasmas) | Peça do lado do canto em L apagada continuava no 3D | VALIDADO | — | — | b3c1e74 | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | | | | = inicial |
| 31 | E3-EIXO-ALA | Quadro da peça no 3D com medidas trocadas na parede lateral | VALIDADO | — | — | b3c1e74 | `testQuadroDaPecaNoModuloDaParedeLateralMostraAsMedidasDaPeca` · existe · ok | | | | = inicial |
| 32 | XP-PK-SOLO | Entrar/sair do "2D só dele" apagava cor, ajuste e peça tirada (34 modelos) | VALIDADO | — | — | 8dbc7ae | `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho`, `testEntrarESairDoSoEleNoCatalogoNaoMud | | | | = inicial |
| 33 | TB-ROTULO | Texto do tamponamento de baixo mudou sem pedido | VALIDADO | — | — | 8dbc7ae | `testTamponamentoInferiorReconheceACavaSozinhoSemSecaoPosCava` · existe · ok | | | | = inicial |
| 34 | TB-INV-NUM | Conferência do invertido dava 36 em vez de 27 | VALIDADO | — | — | 8dbc7ae | `testTamponamentoInvertidoNaoMudaTamanhoDeNadaEmTodoOCatalogo` · existe · ok | | | | = inicial |
| 35 | GAV-MARCA-GDQ | Contra-frente ia para a altura da porta | VALIDADO | — | — | 93495d1 | `testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D` · existe · ok | | | | = inicial |
| 36 | SAIA-ALTURA (saia e porta) | Com saia, o armário ia até a pedra e a porta ficava atrás da saia | VALIDADO | — | — | b3c1e74, 93495d1 | `testComSaiaNaPedraOArmarioInteiroVaiAteEmbaixoDaSaia` · existe · ok | | | | = inicial |
| 37 | TORRE-GEL-PORTA (geladeira) | Trocar a porta de cima fazia porta do teto ao chão | VALIDADO | — | — | e28a490 | `testTorreDaGeladeiraTrocarAPortaMexeSoNaPortaDeCimaETamponamentoSegueATorre`, `testTorreD | | | | = inicial |
| 38 | TAMP-2D-ALVO (rodapé/travessa/moldura sumindo) | Mexer no tamponamento pelo 2D erguia o móvel e apagava rodapé, travessa e moldura | VALIDADO | — | — | 38ed268 (app); testes 32154d4, 790a990,  | `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase` · existe · ok no band2.  | | | | = inicial |
| 39 | AMB-RD | Profundidade do ambiente presa no maior comprimento digitado | VALIDADO | — | — | 0aa152c | `testAmbienteParedeDoLadoProfundidadeNaoFicaPresaERebaixoNaoPassaDaParede` · existe · ok | | | | = inicial |
| 40 | AMB-TZ | Rebaixo do teto passava do fim da parede no 3D | VALIDADO | — | — | 0aa152c | mesmo da linha 39 · ok | | | | = inicial |
| 41 | P0-01 / ARQ-VAZIO (perda de projetos) | `projects.json` vazio apagava a cópia boa do navegador | VALIDADO | — | — | 73ec2f3 | `testArquivoDeProjetosVazioOuQuebradoNaoApagaACopiaBoaDoNavegador` · existe · ok | | | | = inicial |
| 42 | P0-03 / ENGROSSO-APARELHO (perda de dado) | Engrosso do projeto zerado pelo ajuste do aparelho | VALIDADO | — | — | 37c9915 | `testEngrossoDoProjetoNaoSomeComOAjusteDesligadoNoAparelho` · existe · ok | | | | = inicial |
| 43 | P0-03 / ABRIR-REGRAVA | Abrir sem mexer regravava e mudava a data | VALIDADO | — | — | 0e353e3, 74fa8b1 | `testAbrirProjetoSemMexerNaoRegravaNemMudaAData` · existe · ok | | | | = inicial |
| 44 | P0-02 / BKP-RESTAURA (perda de projetos / backup) | Restauração apagava dados antes de extrair (Android/Windows) | VALIDADO | — | — | f96b3e5 | JVM (13 casos); Android CI 635 passou; sonda 6/6 (CONTEXTO). iOS `BackupSafetyTests` (nome | | | | = inicial |
| 45 | GEO-AVISA / DRAW-CATRACA (P1-A) | O ambiente (parede, pé-direito, espessura) modificava os móveis | PARCIAL | P1 | **Não cobertos** (registrado): painéis "até o teto", `confine` no arrasto, `sanBase`. Pedra/lixeira fora da pa | 04ab7cf, 80aa4a1, 9ec0869 | `testAmbienteNaoModificaOsMoveisSoAvisa` · existe · ok | | | | = inicial |
| 46 | SEL-DIV / DIV-OUTRO-MODULO (P1-E) (seleção entre módulos) | Divisória/prateleira de outro módulo mexia na do escolhido | VALIDADO | — | — | d77ff63 | `testSelecaoDivisoriaDeOutroModuloSoEscolheEleENaoMexeEmNinguem`, `testSelecaoPrateleiraDe | | | | = inicial |
| 47 | SEL-PROJ / SEL-ESTADO / SEL-ENTRE-PROJETOS (P1-G) | Escolha do projeto A fazia o 🗑 apagar no B | VALIDADO | — | — | 7db71af, d612d17 | `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto`, `testSelecaoEscolhasDeTelaZeramAoAb | | | | = inicial |
| 48 | SEL-VAO | Vão escolhido inválido depois do toque no 3D | VALIDADO | — | — | 7a95037 | `testSelecaoVaoEscolhidoExisteNoModuloEscolhidoDepoisDoToqueNo3D` · existe · ok | | | | = inicial |
| 49 | SEL-TORRE (torre forno/micro) | Porta de cima virava a torre inteira (9 modelos) | VALIDADO | — | — | 9561fcd (+ fecho da classe 7c939bc; a17b | `testSelecaoPortaDeCimaDaTorreMudaSoAPortaDeCima`, `testSelecaoTorrePortaDeCimaPeloVaoDaTo | | | | = inicial |
| 50 | GV-P1 (peças fantasmas: vãos) | `gv(i)` inexistente gravava vãos fantasma | VALIDADO | — | — | 54e46af | `testGvVaoQueNaoExisteSemDivisoriasNaoGravaNada`, `testGvVaoQueNaoExisteComTresDivisoriasN | | | | = inicial |
| 51 | GV-C | Vão escolhido inválido depois de "Limpar divisões" | VALIDADO | — | — | 5a468bf | `testGvLimparDivisoesVoltaOVaoEscolhidoProPrimeiroNaHora` · existe · ok | | | | = inicial |
| 52 | BKP-PONTOS (backup) | Backup com ".." no nome de arquivo recusado inteiro | VALIDADO | — | — | d669be5 | `BackupCaminhoTest` (Android e Windows); Android CI 635 com `foto..jpg` passou; Windows JV | | | | = inicial |
| 53 | TESTE-CUBA-PAREDE | Teste iOS esperava pedra/lixeira cortadas pela parede | VALIDADO | — | — | 18027d8 | `testCubaArrastaNoTouchTecladoSomaLixeiraEParedeEncolhida` · existe · ok | | | | = inicial |
| 54 | P0-PAREDE (alteração incorreta de parede/pé-direito, P0) | Digitar parede/pé-direito esmagava módulos (largura 500, x 0) e cortava a pedra | VALIDADO | — | — | 6a319d7, b9da40b (+ testes 32154d4, 790a | `testP0ParedeEPeDireitoDigitadosNaoMexemNosMoveis`, `testP0ParedeMenorQueOsMoveisSoAvisa`, | | | | = inicial |
| 55 | F3-TOQUE | 1º toque num módulo não escolhido já movia | VALIDADO | — | — | a9a195b | `testF3PrimeiroToqueEmModuloNaoEscolhidoSoEscolheNuncaMove` · existe · ok | | | | = inicial |
| 56 | F3-SEL | Divisória escolhida sem tocar; 2 toques sem menu; tremida move | VALIDADO | — | — | 469c0d0 | `testF3SelecaoDivisoriaDoisToquesETremidaIguaisEmQualquerZoom` · existe · ok | | | | = inicial |
| 57 | F3-MED | Medida fora do limite trocada em silêncio; campo arredondado | VALIDADO | — | — | 849a46b | `testF3MedidaInvalidaRecusadaComAvisoECampoMostraODecimo` · existe · ok | | | | = inicial |
| 58 | F3-SETA | Seta de trás não diminui depois de "tampou até o fundo" | VALIDADO | — | — | 8fa40d5 | `testF3SetaDeTrasDo3DDiminuiDepoisDeTamparAteOFundo` · existe · ok | | | | = inicial |
| 59 | F3-REGN | Camadas do engrosso cava aceitavam qualquer número | VALIDADO | — | — | d59831f | `testF3CamadasDoEngrossoCavaSo1a3ComAviso` · existe · ok | | | | = inicial |
| 60 | F3-MENU | Menus mudando de lugar entre módulos | VALIDADO | — | — | 4543c0f | `testF3MenusNaMesmaOrdemEmTodosOsModulos` · existe · ok | | | | = inicial |
| 61 | F3-AZUL | Azul de seleção forte | SEM VALIDAÇÃO | P1 | Sem teste automático | c1d584f | **nenhum teste** (só imagens) | | | | = inicial |
| 62 | F3-SEL-REGRESSÃO | 2 pares de toques viravam 4 (trava o módulo); divisória não pegava após arrastar | VALIDADO | — | — | 759ccf0 | `testDoisToquesNoVaoDeCimaAteOTetoRipadoPainelOuFechamento`, `testDivisoriaArrastaComODedo | | | | = inicial |
| 63 | TESTE-RECUO | Testes novos não compilavam no iOS (CI 604) | VALIDADO | — | — | 7c5b0c4 (candidata), 78c2640 (plano de c | iOS 609/611/613/615/616 compilaram (CONTEXTO); `testOpcaoMarcadaSempreMudaAlgumaCoisa` · e | | | | = inicial |
| 64 | A6-LATGAV (pedido) | Sem ajuste de 1 mm da lateral da gaveta pelo 3D | VALIDADO | — | — | a9b1da7 | `testA6AlturaDasLateraisDaGavetaPor2ToquesDe1em1mm` · **não existe** na candidata · ok em  | | | | = inicial |
| 65 | A6-PECA (pedido) | Ajuste da contra-frente mudava a caixa inteira | VALIDADO | — | — | c2951f0 | `testA6AjusteDe1mmSoNaPecaEscolhidaDaGaveta` · não existe na candidata · ok em `cmp6.log`  | | | | = inicial |
| 66 | A6-OP revertido | 890e06e mudou o 1 toque das portas da parede sem pedido | VALIDADO | — | — | 0fad7ef (revert), bb7bd67 (teste), 9d872 | `testUmToqueNaPortaDaParedeAbreEFechaComoAntes` · não existe na candidata · ok em `mvt` 5/ | | | | = inicial |
| 67 | A6-MOVER (pedido) | 2 toques de longe não preparavam o mover | VALIDADO | — | — | 9d3bcce | `testA6DoisToquesDeLongeEscolhemOModuloEDoisNoDestinoMovem` · não existe na candidata · ok | | | | = inicial |
| 68 | A6-PECA-REGRESSÃO | `poAlign` original substituído (alinhamento das portas) | VALIDADO | — | — | 3bab8a8 | `testEditorPorVaosLixeiraEngrossoPortasEAlinhamento` · existe · ok no band2 e no `cmp6.log | | | | = inicial |
| 69 | A6-PISCA | Porta piscando no 2º toque | NÃO FEITO | P1 | Pendente medir no aparelho | — (não commitado) | medição sem diferença | | | | = inicial |
| 70 | A6-COLISAO (pedido) | Mover eletro/porta/janela por 2 toques atravessava módulos | VALIDADO | — | — | 2ac1ddc, 6aacd8a | `testA6MoverPor2ToquesConfereColisaoDeEletroEPortaJanela`, `testA6DepoisDeBloquearNadaFica | | | | = inicial |
| 71 | PLANO DE CORTE (PC-ID, PC-TOQUE, PC-ROD, PC-BRANCO) | Peça igual não saía específica; sem toque longo; rodapé sem opção; brancos separados | PARCIAL | P1 | Rodapé corrido em L (`cutGroups_lr`) não divide. iOS "rodando" (não verificado) | 3c1a677 (+78c2640, 43114be) | `testPlanoDeCorteToqueLongoTiraSoAquelaPecaPelaIdentidade`, `testPlanoDeCorteRodapeForaDoC | | | | = inicial |
| 72 | LAT-MEIO (pedido) | Divisória junto das gavetas mais baixa e sem rebaixo | VALIDADO | — | — | 3991175 | `testLateralDoMeioJuntoDasGavetasNoInferiorDaCozinha` · não existe na candidata · `lit_880 | | | | = inicial |
| 73 | TRAVESSÃO (pedido) | Sem travessão interno/externo | VALIDADO | — | — | a862927 | `testTravessaoInternoExternoComESemFrontalPelaGeometria` · não existe na candidata · `tvt` | | | | = inicial |
| 74 | CANTO-FOLHA (porta do canto) | Folha do lado do canto em L não cobria a lateral do fim | VALIDADO | — | — | e1d79b3 | 4 expectativas mudadas (`testPortaDeCantoMarcacaoEmTodaPortaELixoApagaDivisoriaOuPortas`,  | | | | = inicial |
| 75 | FT-REBAIXO (fita de borda) | Fita de 0,8 mm do rebaixo dentro da travessa frontal (3D) | SEM VALIDAÇÃO | P1 | `bft.log` 347/349: a correção quebrou `testToPeca…`; o teste foi trocado depois e **não há bateria completa gu | af0c55e (+8c3f310, 49996ac testes) | `testFitaDoRebaixoNaoFicaDentroDaTravessaNo3DEPecasECorteNaoMudam` · não existe na candida | | | | = inicial |
| 76 | FT-PORTA (fita de borda) | Fita de 0,8 mm desenhada dentro da porta fechada (3D) | SEM VALIDAÇÃO | P1 | `bfp.log` 346/349 (2 falhas causadas pela correção); testes ajustados depois; `bfp2.log` parcial. Desempenho 5 | 1454596 (+288e0e2, 1a499eb, 9a865e9 test | `testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D` · não existe na candidata · ok em `bfp.l | | | | = inicial |
| 77 | TAMP-CAMINHO (P1-B) | Pelo campo digitado, x=5 vindo de 800 fica em 35 sem tamponamento (vão de 35 mm) | NÃO FEITO | P1 | Aberto | — | nenhum | | | | = inicial |
| 78 | P1-D / ST3ONLY | "Só a pedra no 3D" fica ligado e esconde módulos | PARCIAL | P1 | Fechar o 3D no mesmo projeto não desliga (proposta da auditoria pedia) | 7db71af (só ao abrir outro projeto) | `testSelecaoEscolhasDeTelaZeramAoAbrirOutroProjeto` · ok | | | | = inicial |
| 79 | TAMP-2D-ALVO-PARCIAL | Erguer até atravessar a pedra faz o módulo pular 875 mm de lado | NÃO FEITO | P1 | Aberto | — | nenhum específico | | | | = inicial |
| 80 | CATALOGO-SOBREPOE (I7) | Módulo novo do catálogo em parede cheia entra por cima dos vizinhos | NÃO FEITO | P1 | Aberto; s29 diz que o novo nasce ajustado com aviso em parede cheia (contradição não resolvida) | — | sonda s20 | | | | = inicial |
| 81 | VAO-3D-ABERTO | Trocar o vão por gavetas com o 3D aberto não atualiza o 3D | NÃO FEITO | P1 | Aberto (erro 11 da lista "2D que não atualiza o 3D") | — | sonda s23 | | | | = inicial |
| 82 | SANBASE (travessa/moldura sumindo) | Ligar/desligar `sup`/`rack` apaga travessa e moldura de vez | NÃO FEITO | P1 | Aberto; citado como "não coberto" no GEO-AVISA | — | sonda s05 | | | | = inicial |
| 83 | RACK-FOLGA | Rack: a folga sobe com a espessura e não volta | NÃO FEITO | P1 | Aberto | — | sonda s27 | | | | = inicial |
| 84 | FORNO-MICRO-LIXO | 🗑 em "Corte do forno" e "Nicho do micro-ondas (aberto)": somem do desenho e o aparelho continua | NÃO FEITO | P1 | Risco registrado | — | nenhum | | | | = inicial |
| 85 | GOLA-INTERF | Parede de trás do perfil G entra 1,5 mm na caixa no 3D | PARCIAL | P1 | Rebaixo não sai no corte nem no 3D. Decisão pendente | 45b8e1c (só configuração `gAfast`/`gReb` | `testPerfilGAfastamentoERebaixoConfiguraveisPadraoZeroSemMudarPecas` · ok | | | | = inicial |
| 86 | TRAV-1MM | Travessa frontal se sobrepõe 1 mm às laterais no 3D | NÃO FEITO | P1 | Achado no travessão, existe na publicada | — | nenhum | | | | = inicial |
| 87 | CANTO-L-DENTRO | Canto em L: prateleira/base de um braço dentro da do outro; base superior dentro da moldura (3D) | NÃO FEITO | P1 | Só registrado no FT-PORTA | — | nenhum | | | | = inicial |
| 88 | AVISO-FORA-PAREDE | Pedra/lixeira fora da parede encolhida sem aviso | NÃO FEITO | P1 | Decisão do Adauto: melhoria pendente nas 3 plataformas | — | nenhum | | | | = inicial |
| 89 | FITA-BASE-MIRA | `testFitaDaBaseEmbaixoDaPortaPintaPeloToque`: mirando em cima da porta pega seleção errada | NÃO FEITO | P1 | Homologação a13c9e6: "mirando em cima da porta, falha: continua pegando seleção errada". O teste foi mudado; o | 6058b74 (candidata) / 9a865e9 (fita-port | `testFitaDaBaseEmbaixoDaPortaPintaPeloToque` · existe · ok (mira nova) | | | | = inicial |

## Riscos novos da auditoria (fora das duas tabelas; matriz de plataformas)
| ID | Item | Status inicial | Prior. | Ação necessária | Commit | Teste | And | iOS | Win | Status atual |
|---|---|---|---|---|---|---|---|---|---|---|
| N01 | iOS: restaurar backup pulava, sem avisar, arquivos com ".." no nome (`foto..jpg`) | erro no código (não reproduzido) | P0 | aceitar nome válido; bloquear só subir pasta | a215f60 (teste), ccb5941 (correção) | `BackupSafetyTests.testRestoreKeepsNamesWithDoubleDotsAndStillBlocksTraversal` | — | CI 619 (antes) / a disparar (depois) | — | em validação |
| N02 | Sincronização Wi-Fi (3 plataformas) recusava `foto..jpg` | erro no código | P0 | idem | a215f60, ccb5941 | `SyncTest` (Android e Windows), `SyncInteropTests` (iOS) | CI 637 (antes) / depois | CI 619 / depois | CI 145 (antes) / depois | em validação |
| N03 | Salvamento: `putFile` sem retorno de erro nos 3 nativos (falha de gravação sem aviso) | só leitura de código | P0 | reproduzir; se confirmar, avisar a pessoa | | | | | | = inicial |
| N04 | Campos fora do `snapState` (`S.pw`, `S.RDw/RDs`, `S.rodLast`, `S.deco`, `S.tvLogo`, `S.tvAnim`) | só leitura de código | P0 | reproduzir salvar/reabrir; corrigir o que se perde | | | | | | = inicial |
| N05 | Atualização por cima da versão anterior sem teste (3 plataformas) | sem teste | P0 | teste de atualização: emulador Android, simulador iOS, instalador Windows | | | | | | = inicial |
| N06 | Backup entre plataformas (Android ↔ iOS ↔ Windows) com projetos, fotos, vídeos e notas | sem teste | P0 | arquivo de referência e teste de restauração nas 3 | | | | | | = inicial |
| N07 | iOS: etapa do iPhone deu falha com 373 testes e 0 falhas (CI 616); `SubscriptionTests.test05` instável | investigar | P1 | causa no log; estabilizar sem afrouxar | | | | | | = inicial |
| N08 | iOS: o iPad nunca rodou | CI | P1 | iPad roda mesmo com falha no iPhone | 2e3ffc1 | passo "Testes no iPad" | — | a confirmar | — | em validação |
| N09 | Windows: testes próprios (JVM, tour, instalador) sem execução na candidata; faltam `QuotePdfTest`, `StoneFitTest`, 2 de `QuoteMathTest` | sem teste | P1 | rodar `windows.yml` teste; portar os testes | | | | | | = inicial |
| N10 | iOS do canto rodou só 181 testes do editor | investigar | P1 | achar a causa | | | | | | = inicial |
| N11 | Número de chapas varia com a máquina (otimizador por tempo) | risco | P2 | teste com tempo fixo; avaliar determinismo | | | | | | = inicial |
| N12 | Licença 3 dias/relógio voltado sem teste (Android site e Windows); Play/Billing sem teste | sem teste | P1 | testes JVM | | | | | | = inicial |

## Contagem inicial

- Pedidos: NÃO FEITO 33, NÃO LOCALIZADO 2, PARCIAL 17, SEM VALIDAÇÃO 12, VALIDADO 96
- Defeitos: SEM VALIDAÇÃO 6, NÃO FEITO 15, PARCIAL 8, VALIDADO 60
