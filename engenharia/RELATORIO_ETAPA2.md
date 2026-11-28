# Relatório consolidado · ETAPA 2 (RASCUNHO)

Rascunho do Claude 5, 28/11/2026, para o Chefe revisar. Fontes: `CONTROLE_ETAPA2_2026-11-26.md`, `HISTORICO_ERROS.md`, `DECISOES_TECNICAS.md`, as mensagens dos commits e as baterias rodadas pelo Claude 5. **Nenhum status foi suposto**: só entra o que tem commit, teste ou registro. Onde não há evidência, está escrito "sem evidência".

## Como ler

| Coluna | O que quer dizer |
|---|---|
| Implementado | Commit com a mudança. |
| Integrado | Está no ramo de integração `claude/etapa-2-integracao` (48b4603). Esse ramo **ainda não está** em `claude/etapa-2` (6457906). |
| Bateria | Teste novo no commit e bateria completa no Chromium (`tools/bateria_editor.py`), a 1366 e a 430. |
| Code 1 | Auditoria do Code 1 registrada no HISTORICO. |
| Aparelho | Teste em aparelho real (iPhone, iPad, Android, Windows) registrado. |

**Baterias conhecidas:**
- Ramo do Claude 5 antes da integração (787f485): 590/590 a 1366 e a 430.
- Item 14 (Code 1, `PERFORMANCE.md`): 587/587 nas duas telas.
- HEAD do Claude 5 com a integração (e856b3e, rodando): por volta de 225 testes, 2 falhas nas duas telas. Nenhuma delas é das entregas do Claude 5:
  - `testEdicaoAmbiente3DParedeNo2DEAbasLimpas`: falta a seção "Bases unidas" do item 21 na lista do teste (Code 2 fechando);
  - `testMedidaDePecaSemDecimoEPartesSomamAPecaInteira`: 6310 × 6308 peças. É do item 21 e já foi ajustado pelo Code 2 (sobe na próxima entrega).

**Testado em aparelho real:** nenhum registro na etapa 2. Para todos os itens, "Aparelho" = **não verificado**.

## Itens 1–42

| # | Pedido (resumo) | Resp. | Implementado | Integrado | Bateria (teste) | Code 1 | Pendente / observações |
|---|---|---|---|---|---|---|---|
| 1 | Espelhos: Equilibrado na config, Jateado com LED, botão do LED, vidro | Claude 3 | 5b6a06d, 4152c81, c1a8e78 | sim | `testE2ITEM1_EspelhoQualidadeNaConfig…`, `testE2ITEM1_EspelhoVidroBisote…` | sem evidência | HISTORICO ESP-VIDRO |
| 2 | Juntar bases lado a lado (≤2700), L com base atravessada, unir/separar | Code 2 | parcial: "Unir/Separar manual" em a74b638 (com o 21) | sim (parte) | `testEtapa2BasesNaoSeUnemSozinhas…` | sem evidência | Falta a base atravessada no canto L. Travessa/moldura no "Unir": Code 2 (Chefe 28/11). |
| 3 | Dobradiças metálicas, caneco/braço/calço | Claude 3 | 2f1734f | sim | `testE2ITEM3_DobradicaMetalica…` | sem evidência | HISTORICO DOB-METAL |
| 4 | Porta do forno sem atravessar; relógio = hora do aparelho; texturas | Claude 3 | c362bd8, c7e085a; porta: 6386f93 (não reproduzido) | sim | `testE2ITEM4_Relogio…`, `testE2ITEM4_Ferragens…`, `testE2V1_PortaDoForno…` | sem evidência | V1-FORNO: **não reproduzido** (20 cenas). Precisa do vídeo/aparelho. |
| 5 | Portas do canto abrindo 165° | Claude 3 | 4957eea | sim | `testE2ITEM5_PortasDoCantoAbrem165…` | sem evidência | HISTORICO CANTO-165 |
| 6 | Canto: travessas e régua superior iguais às fotos | Code 2 | 02c6902, 643c6dd | sim | `testEtapa2TravessasDoCantoEmbutidasOuApoiadas…` (e ajuste de teste em 02c6902) | sem evidência | |
| 7 | Canto cego E/D conforme referência; projeto antigo só com botão | Code 2 | sem evidência | — | — | — | **Pendente** (nenhum commit no ramo de integração) |
| 8 | Estrutura do canto: A/B, recuo automático/manual | Code 2 | cf788da | sim | `testEtapa2EstruturaDoCantoAB…` | sem evidência | |
| 9 | Câmera no 2D; editar canto no 2D | Claude 4 | sem evidência | — | — | — | **Pendente** |
| 10 | Aba Divisões: divisórias primeiro | Claude 4 | 5134a84 | sim | `testDIVORDEM_…` | sem evidência | |
| 11 | Modelos de porta, recentes, puxadores · auditoria de puxadores | Claude 4 / Claude 3 | bd2de0d, 9225834, c3833e9 | sim | `testPORTAMODELOS_…`, `testE2ITEM11_PuxadoresPresos…` | sem evidência | |
| 12 | Ordem da aba Tamponamentos | Claude 4 | 10ed13f | sim | `testTAMPORDEM_…` | sem evidência | |
| 13 | Custos fixos na biblioteca de preços | Claude 5 | 364c88b | sim | `testCustosFixosNaBibliotecaDePrecos…`; 590/590 (787f485) | sem evidência | |
| 14 | Desempenho: medir e corrigir a causa | Code 1 | b85ea5f, 6784eff, 681e464 (doc) | sim | `testPERFCORTE_…`; 587/587 (PERFORMANCE.md) | (é do Code 1) | Medido no Chromium. Aparelhos: ver PERFORMANCE.md. |
| 15 | Controle central e integração | Chefe | este controle | — | — | — | em andamento |
| 16 | Regras permanentes | todos | CLAUDE.md | — | — | — | sempre |
| 17 | Homologação independente (aparelhos, update por cima, projetos antigos) | Code 1 + Chefe | sem evidência | — | — | — | **Pendente** (depois dos itens) |
| 18 | Canto esquerdo e direito para 5, 6 e 8 | Code 2 / Claude 3 | 643c6dd, cf788da, 4957eea | sim | os testes de 5, 6 e 8 ("nos dois lados") | sem evidência | |
| 19 | Composições prontas de frente nos inferiores | Claude 4 | 27b257b, 9e80e24, aa72309, 3ca951d | sim | `testFRENTECOMP_…` (2) | sem evidência (o pedido prevê auditoria de fabricação do Code 1) | |
| 20 | Fita manual por lado no ArqueCut | Claude 5 | 7a90dce | sim | `testFitaManualPorLado…`; 590/590 (787f485) | sem evidência | Ajuste de rolagem no item 34 (aa745d5, não integrado) |
| 21 | ERRO: bases unidas sozinhas | Code 2 | a74b638 | sim | `testEtapa2BasesNaoSeUnemSozinhas…` | sem evidência | 2 testes antigos a ajustar (ver baterias). `testValoresCobraAChapa…` com cenário provisório (0dce254, aa547c4) |
| 22 | PRIORIDADE: travessa frontal sobe sozinha; opções não se desativam | Code 2 | sem evidência | — | — | — | **Pendente** |
| 23 | PRIORIDADE: paredes espelhadas, movimento segue quem olha | Claude 3 | 6811d27, 37ad115 | sim | `testE2ITEM23_MovimentoSegueQuemOlha…` | sem evidência | HISTORICO MOV-23 |
| 24 | Auditoria geral de medidas contraditórias | Code 1 | auditoria CRUZA-3D-ID (5329942); correção Claude 3 (33ffaf0, c7cbedc) | sim | `testCRUZA3DID_…` | sim (CRUZA-3D-ID, 24/40 dos 138 modelos) | Resto da auditoria: sem evidência |
| 25 | Janela: 1 toque seleciona, 2 abrem config | Claude 4 | 0dbeba5 | sim | `testTOQUEJANELA_…` | sem evidência | |
| 26 | Módulo no 2D: 1 toque, 2 toques, arrasto/zoom | Claude 4 | 933e964 (TOQUE-ALCA, parte) | sim | `testTOQUEALCA_TremidaPinca…` | sem evidência | Acesso rápido e edição da peça por 2 toques: sem evidência |
| 27 | Auditoria de toques (iPhone/iPad, toque real) | Claude 4 | 933e964, f51cc69 | sim | `testTOQUEALCA_…` (2) | sem evidência | Toque real em aparelho: sem registro |
| 28 | Regra: o cliente controla o projeto | todos | CLAUDE.md §12 | — | — | — | sempre |
| 29 | Pendências antigas recuperadas | Code 1 → Chefe | classificação do Code 1 (27/11), ver abaixo | — | — | sim (classificação) | |
| 30 | Risco N11: plano de corte sob carga | Claude 5 | 44475b2 | sim | `testPlanoDeCorteNaoDependeDoRelogio…N11`; sonda s49; 590/590 | sem evidência | |
| 31 | Risco confineAll/roomClamp | Claude 5 | 787f485 | sim | `testConfineAllRoomClampNaoEscrevem…`; sonda s50; 590/590 | sem evidência | |
| 32 | Travessa frontal em todas as plataformas | Code 2 | sem evidência | — | — | — | **Pendente** |
| 33 | Moldura não adiciona | Code 2 | sem evidência | — | — | — | **Pendente** |
| 34 | Auditoria de todos os botões | Code 2 + Claude 4; telas fora do editor: Claude 5 | Claude 5: aa745d5, 3eef70a, 886255e, b8bb2e2, 530a122, af52826 (sonda s51) | **não** (só em `claude/etapa2-claude5`) | 5 testes `testItem34…`; salvar/desfazer/reabrir de cada controle ok | sem evidência | Ajustes depois do 150º controle: Claude 4 (594 controles, toque real). Telas do app nativo (backup, novidades, Nota, lixeira): não verificado. Parte do Code 2 e do resto do Claude 4: sem evidência neste ramo. |
| 35 | Regra de autonomia documentada | Chefe | CLAUDE.md §12, DECISOES | — | — | — | registrada |
| 36 | Rejeição de palma e caneta | Claude 4 | sem evidência | — | — | — | **Pendente** |
| 37 | Campos numéricos e de espaçamento | Claude 4 | sem evidência | — | — | — | **Pendente** |
| 38 | Medida aplicada no 2D: perguntar quando ambíguo | Claude 4 | sem evidência | — | — | — | **Pendente** |
| 39 | Contaminação entre paredes | Claude 3 | sem evidência | — | — | — | **Pendente** |
| 40 | Cruzamento integral de dados | Code 1 (3D/2D/paredes) + Claude 5 (financeiro/dados) | Claude 5: sonda s52 (ea45620); correção 4fe01ae | **não** (Claude 5) | `testItem40CorredicaDoCaixote…`; s52 em mm e cm | CRUZA-3D-ID (parte 3D) | Ver "Item 40 · parte financeira" abaixo. |
| 41 | Precisão e experiência profissional | Code 1 + Claude 4 | sem evidência própria (ver 14) | — | — | — | **Pendente** |
| 42 | 5º agente: itens 13, 20, 30, 31 | Claude 5 | ver 13, 20, 30, 31 | sim | 590/590 | — | feito |

## Item 29 · pendências antigas (classificação do Code 1, 27/11, no CONTROLE)

| Pendência | Classificação |
|---|---|
| A31 (projeto antigo/gavetas/régua +47) | concluído e publicado (5067fecc) |
| TOQUE-430 ambiente fundo | concluído e publicado (5067fecc) |
| Atualização por cima no iOS | concluído e publicado (5067fecc) |
| apmodels corrompido | concluído e publicado (5067fecc) |
| Abertura lenta do iPhone | parcial: ok no simulador, **sem verificação em aparelho real** |
| Risco N11 | não iniciado → item 30 (feito, 44475b2) |
| Risco confineAll | não iniciado → item 31 (feito, 787f485) |

## Item 40 · parte financeira e de dados (Claude 5, sonda s52)

**Cenário:** 3 ambientes de um cliente (cozinha, quarto, sala) e orçamentos de 1, 2 e 3 ambientes, em mm e em cm.

**Bate ao centavo e à unidade:**
- soma das linhas = total;
- soma por módulo = total;
- chapas = plano de corte;
- peças da lista = peças do plano (107, 75 e 69);
- salvar e reabrir;
- mm × cm: só muda o texto da medida;
- arquivos do backup (projects.json e prices.json) reabrem com o mesmo valor;
- consolidados fecham ao centavo, e o custo "uma vez por serviço" entra uma vez só.

**Corrigido:** as corrediças do caixote de gavetas não entravam no orçamento (12 modelos, 50 gavetas). Commit 4fe01ae, aprovado pelo Chefe. Conta no HISTORICO.

**Esperando decisão:**
- (B) fita nas réguas de engrosso do tamponamento de 30 mm: o plano mostra 4 lados e o orçamento não cobra. O Chefe levou ao Adauto.

**Encaminhado:**
- (C) aéreo basculante: o orçamento cobra 2 dobradiças e o 3D não desenha (Claude 3, depois do item 9).

**Não verificado:**
- telas de exportar/restaurar backup do app nativo: foi conferido só o conteúdo dos arquivos;
- puxadores no 3D × orçamento.

## Resumo

- Com commit e teste no ramo de integração: 1, 3, 4, 5, 6, 8, 10, 11, 12, 13, 14, 18, 19, 20, 21, 23, 25, 30, 31.
- Parciais: 2, 24, 26, 27, 34, 40.
- Sem evidência (pendentes): 7, 9, 17, 22, 32, 33, 36, 37, 38, 39, 41.
- Feito, ainda não integrado: a parte do Claude 5 nos itens 34 e 40.
- Auditoria do Code 1: só o CRUZA-3D-ID (itens 24/40).
- Teste em aparelho real: nenhum registro na etapa 2.
