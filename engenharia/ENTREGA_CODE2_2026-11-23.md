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

## 3. Reatribuído ou suspenso por decisão (não é pendência do Code 2 sem nova ordem)

| Pedido | Decisão |
|---|---|
| Junção 4 (LAT-MEIO) | Code 1 (14:46), parada nas perguntas 2–4 de 17/11 |
| Junção 6 (CANTO-FOLHA) | feita pelo Code 1 (`21443e8`, integrada) |
| Junção 7, módulos curvos, componentes personalizados, batente cava com altura escolhida | Adauto 15:38: "não invente regras… só o que está especificado"; batente cava tem 7 perguntas abertas (`PROPOSTA_BATENTE_CAVA.md`) |
| Moldura/Frontal | Adauto 16:52: não iniciar até definir regras e concluir a junção 4 |
| Correção do tamponamento entre módulos | Adauto 21:04: é do Code 1 (feita, TAMP-JUNTA) |
| Paredes A–F (implementação) | Adauto 18:13 e 19:57 suspendeu; Chefe 00:37 "paredes ficam parados" |
| LED (implementação) | Adauto 21:29 "não implemente sem aprovação"; Chefe 00:37 parado |
| Menu ＋ Criar e Espelhos (fase 4) | Chefe 02:14: passou ao Code 1 (M1 e espelho de parede feitos por ele) |
| Móveis livres e câmera 2D/3D (01:09) | Chefe 02:14: área do Code 1 (FASE3 feita por ele) |

## 4. Em aberto na área do Code 2
Nenhum item com especificação ficou aberto. Fita de borda 1 mm: decidida pelo Adauto em 18/11 (fita só em metros, não desconta no corte; `testPlanoDeCorteNaoDescontaAFitaDeBorda`). Menu Pintar: existe e tem teste (`testFitaDeTopoNaCorDasPortasContaGotasEPintarSoAFita`); a versão "compacta" (D44) é fila sem especificação (§5).

## 5. Depende do Adauto (sem isso não dá para fechar sem inventar regra)
- Churrasqueira quadrada de embutir: especificação de 16/11 (`ESPEC_CHURRASQUEIRA_QUADRADA.md`) traz 11 perguntas abertas (texto original do pedido perdido; "quadrada" × boca retangular da foto; padrões de altura, profundidade, abertura, moldura, paredes, recuo, base; material do interior; lista e orçamento). Só a largura 900 foi dada; o resto não pode ser inventado.
- Área molhada: rebaixo maior que a espessura da pedra (rebaixo americano é outra peça) e se o campo continua 3–20 mm (especificação §7). Hoje: guarda a medida e avisa.
- AQRender (luz, metal e vidro realistas): protótipo fora do app; precisa aprovar a mudança do formato do vértice (checklist A33).
- Menu Pintar compacto (D44): sem especificação/referência.
- Junção 5 (TRAVESSÃO, `a862927` em `claude/arquemestre-travessao`): ninguém assumiu e depende do TRAV-1MM sem especificação.
- Retomar ou não: Paredes A–F, implementação do LED (5 perguntas), Moldura/Frontal, escopo restante dos espelhos (formatos, vão, girar, acabamentos, orçamento de vidro) — hoje sem dono.
- Junção 4 (perguntas 2–4), fontes de TRAV-1MM / CANTO-L-DENTRO / A30.
- Caixa da geladeira nova já nasce com tamponamento dos dois lados?
- Teste em aparelho real (iPhone, iPad, Galaxy Tab S9 FE, Windows): o contêiner só roda simulador/Chromium; precisa de alguém com o aparelho.
