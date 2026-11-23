# Entrega consolidada do Claude Code 2 — 23/11/2026

Ordem definitiva do Adauto (23/11, via Chefe 10:22): nenhuma solicitação anterior ao Code 2 pode ficar pendente. Esta é a lista de TUDO que foi pedido ao Code 2
(histórico da sessão + mensagens do Chefe/Code 1 + engenharia/), com status e evidência. Base: candidata `5bd11f5`. Ramo de fechamento: `claude/fecha-pendencias`.

Status: **integrado** (está na candidata) · **pronto, não integrado** (ramo + SHA) · **reatribuído/suspenso** (por quem e quando) · **falta** · **depende do Adauto**.

## 1. Feito e integrado na candidata 5bd11f5

| # | Pedido (quem, quando) | Evidência |
|---|---|---|
| 1 | Ambiente isolado, branch própria (Adauto 22/11 13:55) | worktree `wt-pecas-livres-2d`, HEAD `3189703` na candidata |
| 2 | Afastamento da parede em cm (13:59 §2) | `6d81f36`; `testEstruturaAfastamentoDaParedeEmCmSemMudarMedidaENemEntrarNoVizinho` |
| 3 | Criar Peça MDF 15 mm (13:59 §3) | `7850334`, `e14c8e8`; `testEstruturaPeca15SegurarCriaArrastaEncostaEMedidaExata` |
| 4 | Criar Régua (13:59 §4) | `7850334`; `testEstruturaReguasEFecharVaoComCorteFitaOrcamentoESalvar` (imagem do Promob nunca chegou: tipos pelo texto) |
| 5 | Fechar Vão (13:59 §5) | `7850334`, `4a8d7ca` (VAO-FISICO) |
| 6 | Geometria sólida sem motor paralelo (13:59 §6) | `4a8d7ca`; `testPecasLivresArrastoSemReconstruir3DACadaPassoEOrientacaoPeloEspaco` |
| 7 | Corte, orçamento, fita, preparo DXF das peças livres (13:59 §7) | `8921469`; `testIntegracaoDasPecasLivresEIdentificacaoUnicaNosMeusModelos`, `testPecasLivresNoOrcamentoNoPDFENoPlanoDeCorteComAsMedidasReais` |
| 8 | Salvamento, desfazer, projetos antigos (13:59 §8) | `5173f48`; `testCompatibilidadeDosProjetosComPecasLivresEMarcadorDeFormato` |
| 9 | Levantamento da transferência (13:59 TRANSFERÊNCIA) | relatório 22/11 14:34; 11 defeitos repassados ao Code 1 |
| 10 | Meus Modelos (transferência §2.4, prioridade 15:38) | `38a78d6`, `5173f48`, `6bb1e65`; `testMeusModelosGuardaPecasLivresEAoReusarRecalculaPelaNovaMedida` |
| 11 | Editor 2D Multivistas (14:34) | `2b39199`, `f0225e1`, `38a78d6`; `testMultivistasCameraECriarPecaEmCadaVistaSemMexerMovel` |
| 12 | Bateria 405, arquitetura e desempenho (15:38, 15:46) | `64f03a2` 405/405; `4a8d7ca` (bater 275 → 11 ms) |
| 13 | CIs antigas canceladas, marcador `m.pl`, Meus Modelos sem mudança calada (16:52, 18:13, 19:57) | `5173f48`, `6bb1e65`, `8921469` |
| 14 | POLÍTICA B (19:57, 21:04, Chefe 22:45/23:51) | `973db09`, `3189703`; `testPoliticaBProjetoComPecasLivresNaoAbreEmVersaoIncompativelNemPerdePeca`; iOS 666 verde |
| 15 | Paredes: proposta de engenharia (17:37, 18:12) | `3fa7ca6` `PROPOSTA_ABERTURA_PAREDES.md` (implementação: ver §3) |
| 16 | Canto: diagnóstico (19:12, 19:56) | `8921469`, `CANTO_2026-11-22.md` |
| 17 | Portas do canto em L 650→705, travessa, cava, cnP (23:01; dono final Code 2, Adauto ~23:35) | `f9c5cc7`, `e130848`; `testPortasDoCantoEmLAlinhadasComAsRetasNovoEAntigo` |
| 18 | Painel cego peça fixa, sem furo Ø35 (00:38) | `f7a242f`; `testPainelCegoAlinhadoComAPortaSemFuroDeDobradicaNovoEAntigo` |
| 19 | Tamponamento com régua interna: diagnóstico + 4 faixas (20:08, 21:04) | `5569a7b`, `TAMPONAMENTO_ENTRE_MODULOS_2026-11-22.md` (correção: Code 1, TAMP-JUNTA `121f1b0`) |
| 20 | LED: proposta técnica (21:29) | `37f4541` `PROPOSTA_LED.md` |
| 21 | Menu ＋ Criar: proposta (21:37, 22:18) | `2b9e949` (implementação passou ao Code 1, M1 `6341a22`) |
| 22 | FASE 2 levantamento (catálogo + exemplo + montados) | `e6ba554`, `164ddcc`; ampliado em `10a0054` (7 cenas montadas + controle, ver §2) |
| 23 | FASE 2 gaveta 6 mm (gf6), rodapé do encontro, ilha antiga com botão | `bf2abf6`, `78e05ab`; `testFASE2_FundoDaGavetaEntraORebaixoERodapeDoEncontroForaDaLista`, `testFASE2_IlhaAntigaAtualizaFundoDaGavetaComPreviaEDesfazer` |
| 24 | FASE 5 DXF para CNC (02:26) + etiqueta (Chefe 05:15) | `a923d59`; `testFASE5_DxfParaCncContornosFurosERasgosSemInventar`, `testFASE5_EtiquetaDoDxfNaoSobrepoePecaVizinha`; `FASE5_DXF_CNC.md` (Aspire: não validado) |
| 25 | Revisão do envoltório `ccd2274` (Chefe 07:01) | resposta 07:03: não conflita |
| 26 | CORREÇÃO GLOBAL DO 3D: z-fighting, fita, rebaixo, sobreposições, peça girada (06:02 via Code 1) | `5080d78`, `1d6f446`, `4a56268`; `test3D_SemSolidoDentroDeOutroFitaERebaixo` |
| 27 | Pedra em L na elevação 2D + textura real (07:11, 07:20) | `5c838a6`; `testPedraEmLApareceNaParedeDoLado2DIgualAo3D` |
| 28 | iOS 674: teste do fundo da gaveta (Chefe 08:11) | `68783b4` (= `dac9eb6`); `testGavetaTelescopicaRebaixoContraFrenteEFundo` |
| 29 | Bateria com expressão Swift (Chefe 08:21) | `8f21fa0`: 434→437 testes, 3728→4166 asserts conferidos, acusa o fw 526 |
| 30 | Regra permanente evolutiva (01:29) | CLAUDE.md §0; seguida em todas as entregas (marca + aviso + botão + desfazer em mudança de peça) |

## 2. Pronto, não integrado (para o Chefe integrar)

| # | Pedido | Ramo @ SHA | Evidência |
|---|---|---|---|
| 31 | Caixa da geladeira: lateral só no aéreo, só o tamponamento desce (Adauto 09:31) | `claude/gel-lateral-aereo` @ `a18d6d1` (base `e3a1a61`; será reaplicado sobre `5bd11f5`) | `testCaixaDaGeladeiraLateralSoNoAereoTamponamentoAteOChao`; caixa antiga: aviso + prévia + botão + desfazer |
| 32 | Medida (trena 2D) espelhada ao trocar de parede (Adauto 10:11) | mesmo ramo @ `a066054` | `testTrenaNaParedeEsquerdaEspelhadaECadaParedeComAsMedidasDela` (antes: fora do espelho; a do fundo aparecia na esquerda) |
| 33 | Intermitente `testPaineisDiferentesEmCadaParede…` (Chefe 06:01, 10:22) | `claude/fecha-pendencias` @ `278e643` | causa achada: id novo de painel/eletro na vista da parede só conferia a lista daquela parede (podia repetir o de outra: peça na parede errada e projeto com id duplicado — defeito real). `testIdNovoNaVistaDaParedeNaoRepeteODeOutraParede` (relógio fixo: antes falha sempre) |
| 34 | 3D-ACABAMENTO resto: textura/UV, normais, destaque de seleção, móvel girado | `claude/fecha-pendencias` @ `d0092c4` | `test3D_CatalogoSemCaixaInvalidaSelecaoTexturaEGirado`: 591 modelos, 29 440 caixas, 0 inválida/invertida, toda peça de MDF e fita com chave; 239 MDF + 15 pedras com arquivo e medida; gaveteiro livre 45° com textura |
| 35 | FASE 2 ponto 2 ampliado | `claude/fecha-pendencias` @ `10a0054` | `FASE2_LEVANTAMENTO_MONTADOS_2026-11-23.md`: 7 cenas, 0 sobreposição entre módulos/pedra/ilha; controle 21 |
| 36 | Área molhada "mancha" (AM-1..4) e canto do furo da cuba sem textura (PIA-1) — pedido 16/11 14:41, especificado em `ESPEC_TEXTURAS_PIA_AREA_MOLHADA` e nunca entregue | `claude/fecha-pendencias` @ `775fcf0` | `testAreaMolhadaMesmaPedraRebaixadaComDegrauECantoDoFuroComTextura`: mesma pedra rebaixada 20 mm (antigo fica com o dele), degrau real, 0 peça de outra cor, cantos de pedra; aviso se o rebaixo não cabe. Captura antes/depois |
| 37 | Medida livre real do vão no editor normal (transferência §6, D27) | `claude/fecha-pendencias` @ `59129eb` | `testVaoEscolhidoMostraAMedidaLivreReal` (870 × 620; 428 × 620 com divisória; parede espelhada) |
| 38 | Textura da folha do canto e das portas na parede lateral (achado da auditoria) | `claude/fecha-pendencias` @ `f32837f` | conferido sem defeito: `pfFill` usa `woodT` (foto 7); `testPortaDoCantoEDaParedeLateralComATexturaRealDasRetas` |
| 39 | Rodapé fora do corte em cozinha em L (exceção citada em 22/11) | `claude/fecha-pendencias` @ `eeeb002` | conferido sem defeito: `testPlanoDeCorteRodapeForaDoCorteNaCozinhaEmL` |
| 40 | Histórico de versões com peça livre (13:59 §8) | `claude/fecha-pendencias` @ `ffb31ea` | `testHistoricoDeVersoesGuardaERestauraAPecaLivre15mm` |
| 41 | Registros no HISTORICO_ERROS (CLAUDE.md §8.9/§11.1) | `claude/fecha-pendencias` @ `eeeb002` | seção "CODE 2 · registro consolidado" |
| 42 | Exportação lendo o `partsOf` cru (condição do Chefe 03:05) | — | conferido: `partsOf0` só é chamado dentro do `partsOf`; não existe exportação CSV; PDF e link de corte leem o `partsOf` |
| 43 | Junção 5 · TRAVESSÃO (Adauto 23/11: "travessão e régua superior… duas de 8"; "Opção, desligada") | `claude/fecha-pendencias` @ `a849a43` | `testJuncao5TravessaoDuasReguasDe80PorCimaDasLaterais`: opção desligada por padrão, 3D = corte, frontal rebaixa as laterais |
| 44 | Paredes A–F (Adauto via Chefe 23/11: "Faça todos") | `6df3e3e` (A abertura/peitoril), `bd07280` (B meia-parede e parede inteira), `ab9d030` (C remover/restaurar), `076a1cd` (D editar pelo 3D), `49bbf97` (E soltar módulo aqui), `4b45005` (F doc + compatibilidade com a publicada `c561120`) | `testParedesEtapaA…`, `…EtapaB…`, `…EtapaC…`, `…EtapaD…`, `…EtapaE…`; `PAREDES_ETAPAS_A_F_2026-11-23.md` |
| 45 | Regra 5 · acabamento do topo da parede (MDF/pedra) | `fb43cb6` | `testParedesAcabamentoEmCimaDoPeitorilPedraOuMDF` |
| 46 | Geladeira: "Só o tamponamento" (nova caixa com tamponamento dos 2 lados até 100 mm do chão) | `b45a408` (lateral só no aéreo) + `5a48d40` (GEL-TAMP) | `testCaixaDaGeladeiraNovaComTamponamentoCemMilimetrosAcimaDoPiso`; caixa antiga: aviso + prévia + desfazer |
| 47 | Medida espelhada ao trocar de parede | `d8173fe` (MED-PAREDE) | `testTrenaNaParedeEsquerdaEspelhadaECadaParedeComAsMedidasDela` |
| 48 | Botão CSV (mesmas linhas do PDF, UTF-8 BOM, ";", compartilhar nativo) | `988986e` | `testPlanoDeCorteListaEmCSVMesmasLinhasDoPDF` |
| 49 | Churrasqueira quadrada de embutir (padrões aprovados 23/11) | `2cc652d` | `testChurrasqueiraQuadradaDeEmbutirComMolduraA45` |
| 50 | Moldura/Frontal (ordem Moldura → Travessão → Frontal) | `0714b18` | `testMolduraTravessaoFrontalTresDIgualCorteEOrdemNoPainel` |
| 51 | Menu Pintar compacto (D44, decisão 17/11) | `e314a8b` | `testPintarCompactoCabecalhoDuasLinhasRolagemEDuasColunasSemPerderOpcao` (falha antes) |
| 52 | Fita 1 mm: quadro mostra corte × acabada (decisão 17/11) | `a283ce6` | `testQuadroDaPecaMostraCorteEAcabadaComFitaDe1mmSemMudarOCorte` (falha antes); corte sem desconto mantido |
| 53 | AQRender "Acabamento realista" (opção, desligada) | `4445cf2` | `testAcabamentoRealistaOpcaoDesligadaPorPadraoSoMudaAAparencia` (falha antes); imagens em `diagnosticos/aqrender_2026-11-23` |

## 3. Área do Code 1 (divisão do Adauto 23/11)
- LED e o restante dos espelhos.
- Achados repassados: tamponamento 30 do aéreo = 2 réguas (item C); espelhamento perdido depois do encaixe do canto (o "rodar" usa `d0`).

## 4. Em aberto na área do Code 2
Nenhum. Todos os itens da divisão de 23/11 (junção 5, geladeira, Moldura/Frontal, paredes A–F, fita 1 mm, Pintar, churrasqueira, textura da pia,
AQRender, medida livre do vão, rodapé L, CSV) têm SHA e teste que falha antes.

## 5. Limites conhecidos (não são pendência de código)
- Teste em aparelho real (iPhone, iPad, Galaxy Tab S9 FE, Windows): o contêiner só roda Chromium (SwiftShader); a homologação é pelos testes automáticos (Adauto 23/11).
- AQRender: FPS e temperatura em aparelho não medidos; LED não ilumina o resto; vidro sem ordenação por distância (está no LEIAME do protótipo).
- Junção 4 (perguntas 2–4), batente cava (7 perguntas), junção 7/módulos curvos: seguem parados por decisão do Adauto.
