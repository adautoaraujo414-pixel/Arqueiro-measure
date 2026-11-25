# Entrega consolidada do Claude Code 1 — fechamento de 24/11/2026

Ordem do Adauto (via Chefe, 24/11): auditar e fechar tudo o que já foi pedido numa candidata única. Correções na hora (§0 aditivo, §11 teste que falha antes).
Ramo: `claude/fechamento-code1`, base `ed041eb` (= `feature/candidata-integrada-2211`).

Legenda de resultado: **1366** e **430** = bateria completa no Chromium (janela notebook e celular). Chromium não conta como plataforma.
And/iOS/Win = CI da candidata. "base" = a falha também existe na `ed041eb` (não é regressão).

## 1. Corrigido agora (erro comprovado → teste que falha antes → correção)

| Item | O que era | SHA teste · código | Teste | 1366 | 430 | PNG |
|---|---|---|---|---|---|---|
| B21 | 3D aberto ficava atrasado (parede, vão em gavetas, apagar módulo) | 29bc3ba, 3f7e893 · f91429c | `testB21Com3DAbertoParedeGavetasEApagarAtualizamNaHora` + sonda s23 (11/11) | ver §6 | ver §6 | `B21_3D_vao_vira_gavetas_{antes,depois}_{1366,430}.png` |
| B24 | Digitar posição e voltar perdia o tamponamento automático do lado exposto (70 modelos na s27) | eddb30d · 700a81c | `testB24DigitarPosicaoEVoltarDevolveOTamponamentoAutomaticoDoLadoExposto` + s27 (0 diferença real) | ver §6 | ver §6 | `B24_digitar_e_voltar_tamponamento_*` |
| B23 | Criar módulo andava com os que já existiam (até entrar embaixo do aéreo); tamponamento oscilava com vão do tamanho dele | 44e5781, a23584c · 17df4a5, 8a19010 | `testB23CriarModuloNovoNaoAndaComOsQueJaExistem` + s20 (I7 0, I2 0) | ver §6 | ver §6 | `B23_criar_nao_anda_existente_*` |
| N14 | Android só copiava "antes-de-usar-a-versao-N" no onStop (depois de usar) | 0614832 · 414b523 | `.github/scripts/teste_atualizacao_android.sh` (N05/N14) | — | — | — |

## 2. Itens do checklist da área do Code 1

| ID | Situação agora | Evidência | Pendência |
|---|---|---|---|
| A22 | PARCIAL (mitigado) | `testModuloQueNaoApareceNo3DViraAvisoERefazSozinho`, `testTodoModuloCadastradoApareceNo3DEmQualquerCaminho` | **Adauto:** mandar o "🔎 Diagnóstico do 3D" ou o backup do projeto em que aconteceu (causa raiz só com o caso real) |
| A29 | não reproduzido | `testTamponamentoSempreForaDoModuloEmTodosOsModelosComReguasDe80` (catálogo inteiro) | **Adauto:** qual módulo e qual lado (print ou backup) |
| A31 | não reproduzido | `testReguaEspacadoraEditavelEDobradicaRetaOuCurva`, `testEspacadorDeCantoEFechamentoDoTetoNaFrente` | **Adauto:** em que tela ficam as "setas" que não mexem (print) |
| B05 | FEITO | s13 e s06 pelo `setv`: 25 → 25, 5 → 5; arrastar até a parede = tamponamento preenchendo | — |
| B15 | PARCIAL | `testAmbienteNaoModificaOsMoveisSoAvisa`; s27 cozinha demo: W e H ida e volta "tudo igual e sem aviso" | sanBase/wallFollow de painéis até o teto não cobertos por teste próprio |
| B21 | FEITO | §1 | — |
| B22 | FEITO | s29: nasce com a medida do catálogo; parede cheia não cria e avisa; móveis existentes não mudam | **Adauto:** "Balcão com laterais até o piso" está com 870 no catálogo e nasce com 820 (igual aos outros balcões). Qual vale? |
| B23 | FEITO | §1 | — |
| B24 | FEITO | §1 (folga do rack e módulo lateral: s27 cozinha demo sem diferença) | — |
| B25 | sem caso | nenhuma sonda acusa | **Adauto:** caso de travessa/moldura perdida ao alternar sup/rack (backup) |
| B26 | PARCIAL | `testSolidoNadaEntraEmNadaEPainelSaiEmPlacasDaChapa`, `testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D` | peça flutuante sem teste próprio |
| B27 | NÃO FEITO (melhoria) | — | aviso de pedra/lixeira fora da parede: funcionalidade nova, fora do "sem funcionalidade nova" |
| D10 | não reproduzido | não existe botão "Achar peça" no editor atual | **Adauto:** qual tela/botão (plano de corte do Android?) |
| D23 | PARCIAL | modUid/pcIds só no plano de corte | refatoração grande; fora do fechamento |
| D24 | PARCIAL | travessão a862927; `testBateriaNova…CorteIgualAo3D`; nesta entrega réguas provençais 3D = partsOf (auditoria 23/11) | moldura/frontal sem teste numérico próprio |
| D27 | FEITO (Code 2) | `testVaoEscolhidoMostraAMedidaLivreReal` (59129eb) | — |
| D30, D31, D34 | depende de aparelho | toque/zoom/FPS reais não medem no Chromium | teste no aparelho do Adauto |
| N05 | Android e Windows ok (17/11); iOS: workflow `ios-atualizacao.yml` existe | android-atualizacao.yml, windows-atualizacao.yml, ios-atualizacao.yml | **Chefe:** disparar os três na candidata final (só rodam por disparo manual) |
| N13 | corrigido; falta aparelho | `EditorVideoTest`, `DesktopCompatTest.ponteDoEditorDeMoveis` | ponta a ponta em aparelho |
| N14 | FEITO | §1 | CI Android (o contêiner não compila o app: plugin Android sem rede) |
| N15 | ambiente | iPad 1ª abertura fria (Code 3, números 24/11) | aquecimento do simulador (Chefe, autorizado) |
| N16–N19 | FEITO | `testLateralDeUmaGavetaMudaTodasAsGavetasDoConjunto`, `testDoisToquesFuncionamNaGeladeiraENasTorresComPrateleira`, `testTrocarDeParedeEMexerNaGeladeiraNaoMoveNenhumMovel` — CI ed041eb: And ✅ iOS ✅ Win ✅ | toque real (N18) em aparelho |

## 3. Bugs da área (toque, seleção, digitação, movimento, tamponamento, desempenho, compatibilidade)

| Área | Situação | Teste (todos na ed041eb, CI And/iOS/Win verdes) |
|---|---|---|
| Precisão dos toques | ok | `testPecaLivreArrastarDeNovoLogoNaoAbreMenuEDoisToquesParadosAbrem`, os 19 testes de "2 toques" (1366 e 430) |
| Seleção de peças | ok | `testF3SelecaoDivisoriaDoisToquesETremidaIguaisEmQualquerZoom`, `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto` |
| Digitação | ok | auditor de digitação 23/11: 0 de 223 campos perdem o foco; `testAuditoriaAnguloDoEspelhoEDoMovelLivreAplicaNoEnter` |
| Movimentação | corrigido nesta entrega | B23, B24 (§1) |
| Tamponamentos | corrigido nesta entrega | B23, B24; s06, s12 e s20 sem diferença nova em relação à base |
| Desempenho | ok no Chromium | B21 monta o 3D no máximo 1×/quadro (teste conta); iPad: abertura fria é ambiente |
| Compatibilidade | ok | Política B (peças livres, LED/espelho, portas/puxadores novos); PROJ-SEM-MODULO; N14 |

## 4. Política B do LED/espelho sem foto a mais (`adb9f8a`, teste `2e34b10`)
**Decisão: NÃO entra.** É melhoria opcional (C): sem LED nem espelho a camada tirava um `snapState` a mais por envio, sem defeito visível. A queda do Windows que motivou o commit era a ponte da bateria (`shareFile`, 20c11b0), comprovado pelo Chefe. A camada atual também conta portas e puxadores novos; trocar o critério agora mexeria num ponto homologado sem ganho comprovado.

## 5. Preservação dos dados na atualização
| Plataforma | Teste | Roda na CI da candidata? | Resultado |
|---|---|---|---|
| Android | `android-atualizacao.yml` + `teste_atualizacao_android.sh` (N05, N14 e vídeo) | disparo manual | **25/11, `7751eeb` (editor final):** apk-660 → 90031, 8/8 e 4/4 iguais; vídeo gravado pelo seletor do editor publicado, igual byte a byte (sha 989ce0ff…) e toca no novo. Falhas 0 |
| iOS | `ios-atualizacao.yml` + `AtualizacaoAbreProjetosTests` + `VideoGravarUITests` | quando o teste muda; senão manual | **25/11, `02e5269` (editor final), iPhone 17 Pro Max e iPad Pro 13 (iOS 26.5, simulador):** 3.0.13 (`3f1c3a58`) → nova, 8/8 e 4/4 iguais, projetos abrem com as mesmas medidas, peças e corte; vídeo gravado pelo seletor da versão publicada, 12/12 arquivos iguais, o editor novo acha o vídeo igual byte a byte (sha f1723490…) e toca. Falhas 0 |
| Windows | `windows-atualizacao.yml` + `teste_atualizacao_windows.ps1` (com vídeo) | disparo manual | **25/11, `7751eeb` (editor final):** win-166 → nova, verde (dados e vídeo) |

Teste em aparelho real: **não feito** (só emulador, simulador e runner do Windows).

## 6. Baterias desta entrega
- Editor `7835d4b390bd` (o mesmo do HEAD), perfis novos do Chromium, uma bateria por navegador, sem aumentar limite de tempo:
  - **1366×768:** 528/529.
  - **430×900:** 528/529.
- Nas duas, a única falha é `testMoverNo3DEncaixaNaParede…`. A bateria leu o Swift antes da correção do teste (`d0a715db`, auditada).
- No HEAD, esse teste mais FASE4, caneco, giro e D23: 11/11 em 1366 e 11/11 em 430.
- Antes disso, no `78e7d62`: 430 527/527 e 1366 526/527 (FASE4, causa no HISTORICO, corrigido em `3dbbd50`).

## 7. Decisões do Adauto de 24/11 — parte do Code 1 (detalhe no HISTORICO, "DECISÕES DO ADAUTO 24/11")
PNGs antes (b9f4476) × depois em `engenharia/diagnosticos/homologacao_2026-11-24/code1/decisoes/`.

| Item | Situação | SHA teste · código | Teste | PNG |
|---|---|---|---|---|
| 3 falhas de 430 da base | Segurar 2 s: erro do app, corrigido (TOQUE-430). Trena: defeito do teste, corrigido com prova (só teste). LED: risco de densidade 1 (24/24 com densidade 2 = celular) | ed3571b · d6d5c97 · f23373b | `testSegurarOMovel2Segundos…`, `testTrenaNaParedeEsquerda…`, `testFaixaDoEspelhoLed…` | `TOQUE430_planta_{antes,depois}_430.png` |
| 7 · toque (89) | FEITO: porta pega a porta; fita só no modo ▭ Fita | ec2296a · ff41ff3 | `testFitaDaBaseEmbaixoDaPortaPintaPeloToque`, `testCavaSemFaixaPreta…` | — |
| Arrasto confinado (B15/45) | FEITO no 2D e no 3D: não encolhe, não entra em outro, para na parede, não empurra | bcd3603, afd988a · b1fa11e, 8b0bf44 | `testArrastoFicaNoAmbiente…`, `testArrastoNo3DFicaNoAmbiente…` | `ARRASTO_parede_encolhida_{antes,depois}_1366.png` |
| B26 peça flutuante | Investigado: nenhuma peça de corte solta (138 modelos); validação permanente | bcd3603 | `testNenhumaPecaDeFabricacaoFicaSoltaNo3DEmTodoOCatalogo` | — |
| 3 · A31 | FEITO: régua (8 modelos) e rodapé (todo pedestal) editáveis pela seta, dentro do limite; portas recalculam | a22988f · d51fa62 | `testA31AlturaDaReguaEspacadoraEDoRodapePelaSetaDo3D` | `A31_rodape_seta_{antes,depois}_{1366,430}.png` |
| Quarto item aberto | = defeito 45 (painéis "até o teto" acompanham o pé-direito). Conflito entre a regra de 16/11 e pedidos aprovados de painel acompanhar teto/gesso | — | — | **Pergunta ao Adauto** |
| D23 identidade | Feito pelo Code 2 (`d687d0a9`, `d0a715db`). Auditado e juntado (`e6e95ba`, `dae8a33`): projeto publicado abre igual com e sem `uid`, teste do vizinho com a mesma força | d687d0a9 | `testIdentidadeUnicaModuloEPeca…` | — |
| Vídeo na atualização | Windows e Android cobertos (CI verde: vídeo igual byte a byte e toca no editor novo). iOS coberto (25/11, `02e5269`): iPhone e iPad no simulador, vídeo gravado pela versão publicada volta igual e toca (§5) | 70f7782, d2446d5, dc4892b, 69aca94 | `video_cdp.py`, `VideoGravarUITests`, `testVideoGravadoPelaVersaoPublicada…` | — |
| Auditoria do Code 2 (850e193e + decisões) | integrado (42008b8, 7d257c1); expectativas mudadas trazem decisão e data; orientação do G igual | — | baterias §6 | — |
