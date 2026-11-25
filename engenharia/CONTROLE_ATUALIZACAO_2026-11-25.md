# Controle central da atualização (24–25/11/2026)

Mantido pelo Chefe. Todo pedido do Adauto desde 24/11 está aqui, com quem faz e o estado.
Estados: **pronto** (SHA + teste) · **em andamento** · **auditoria** (com o Code 1) · **integrado** (no SHA final).
Publicação: só depois da aprovação integral do Code 1 e da homologação final do Chefe (autorizada pelo Adauto em 25/11).

## Agentes e ramos
| Agente | Ramo | Área (não mexer na área de outro) |
|---|---|---|
| Code 1 | claude/fechamento-code1 | auditoria geral, regressão, desempenho, novidades.txt, aprovação final, integração dos ramos |
| Code 2 | claude/liberdade-composicao → claude/menus-por-tipo | liberdade de composição (criar, colar, digitar, arrastar 2D/3D), menus por tipo, porta-temperos no editor por vãos, plano de corte no iPad |
| Claude 3 | claude/c3-revisao | revisão independente; LED do espelho; arquivos corrompidos (prices, projects, apmodels); localizar no 3D; enfeites automáticos e biblioteca de objetos |
| Claude 4 | claude/unidade-medida | unidade mm/cm nos Ajustes (só apresentação e leitura de medida) |
| Chefe | claude/ci-logs-ios, claude/pacotes-teste-artefato, este arquivo | workflows de CI, integração final, homologação, publicação |

## Pedidos
| # | Pedido (data) | Dono | Estado |
|---|---|---|---|
| 1 | Auditoria geral Code 1/Code 2 (24/11) | Code 1 | em andamento |
| 2 | Pacotes de teste só como artefato do Actions (24/11) | Chefe | pronto (bf539c58), validado Android/Windows |
| 3 | Aquecimento do simulador do iPad, 20 s mantidos (24/11) | Chefe | pronto (bf539c58); iPad 1ª abertura 12,2 s |
| 4 | Decisões 1–9 de 24/11 (forno/micro, rodapé/travessa, régua A31, calço, perfil G, fita do aéreo, toque porta×fita, facetado/G/GV, curvos adiados) | Code 2 / Code 1 | pronto; A31 com correção pendente (projeto antigo, gavetas, régua +47) |
| 5 | Arrasto confinado, peça flutuante, identidade única D23, 4º item, 3 falhas de 430 (24/11) | Code 1 / Code 2 / Claude 3 | D23 pronto; LED de 430 pronto (4fb5695a + f02a19b); TOQUE-430 em ambiente fundo pendente |
| 6 | Custos fixos com as 5 garantias (24/11) | Code 2 | pronto, auditado sem defeito |
| 7 | Fundo de 15 mm, canto A, sem fita, veio (24/11) | Code 2 | pronto (35054a49) |
| 8 | Zoom no plano de corte (24/11) | Code 2 | pronto (94a5f412) |
| 9 | Legibilidade do plano de corte, inclusive iPad (24/11) | Code 2 | correção do iPad pela causa (23acd260); iOS rodando |
| 10 | Orçamento de vários ambientes (25/11) | Code 2 | pronto; auditoria |
| 11 | Centavo do desconto tela = PDF (25/11) | Code 2 | pronto (41a0842d) |
| 12 | Atualização por cima com vídeo, iPhone e iPad (24/11) | Code 1 | Android e Windows verdes; iOS instável (falta 2 verdes seguidos) |
| 13 | Abertura lenta do iPhone (47,6 s / >60 s) (25/11) | Code 1 | em investigação |
| 14 | Liberdade de composição + avisos sem interromper (25/11) | Code 2 | criar/colar/digitar/arrastar prontos (aae4ef93); bateria rodando |
| 15 | Menus por tipo, porta-temperos de vão, componentes editáveis (25/11) | Code 2 | em andamento |
| 16 | Sem enfeite automático + biblioteca de objetos (25/11) | Claude 3 | em andamento |
| 17 | Arquivos corrompidos (prices/projects/apmodels) (25/11) | Claude 3 | prices/projects prontos (f02a19b); apmodels em andamento |
| 18 | Localizar no 3D a partir do plano de corte (25/11) | Claude 3 | em andamento |
| 19 | Unidade mm/cm nos Ajustes (25/11) | Claude 4 | em andamento |
| 20 | Logs do iOS preservados, um ramo de resultados por ramo (25/11) | Chefe | pronto (ed6b650d) |
| 21 | 100 min no passo do iPad (25/11) | Code 2 | pronto (8b8e444c) |
| 22 | Novidades desta versão (§10) | Code 1 | pendente |
| 23 | Homologação única nas 4 plataformas + publicação | Chefe | depois da aprovação do Code 1 |

## Decisões abertas com o Adauto
- Tamponamento da junção normal (lado a lado) × "existentes nunca mudam": sem resposta → fica como hoje (TAMP-JUNTA). Par sobreposto confirmado: o vizinho nunca muda (decidido).
- Veio em peças altas: sem resposta → fica como hoje (aviso "maior que a chapa", sem forçar).
