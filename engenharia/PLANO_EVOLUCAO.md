# Plano de evolução (proposta, 16/11/2026). **Nada disto está aprovado.**

O objetivo é chegar à maturidade de um sistema profissional de móveis planejados, com o Promob só como referência de nível. A identidade do Arquemestre fica: simples, toque e gestos, regras de marcenaria do Adauto e as 3 plataformas iguais.

## Comparação de capacidades (conceitual)
| Capacidade de um sistema profissional | Arquemestre hoje (verificado) | Falta |
|---|---|---|
| Módulos paramétricos | Sim: catálogo, editor por vãos, canto em L, torre, aéreo | Regras espalhadas em embrulhos (ver ARQUITETURA) |
| Plano de corte com aproveitamento | Sim: veio por peça, chapa apertada, sobras | — |
| Lista de materiais e orçamento | Sim: ferragens, fitas, PDF com fotos e aditivos | — |
| Visualização 3D | Sim: WebGL próprio, fotos reais dos padrões | Luz e metal realistas; perda de contexto (WEBGL-001) |
| Detecção de colisão | Em vários lugares ("nada entra em nada") | Uma checagem única para 2D e 3D |
| Furação e usinagem para CNC | Não | Exportação XML para CNC (pedido futuro do Adauto) |
| Vistas técnicas cotadas por parede | Parcial (2D da parede com cotas) | Prancha de montagem e furação |
| Histórico e versões do projeto | Backup e lixeira | Histórico de versões do projeto com volta |

## Curto prazo: estabilidade
| # | Proposta | Benefício | Complexidade | Risco | Testes |
|---|---|---|---|---|---|
| C1 | Tratar a perda de contexto do WebGL (WEBGL-001) | 3D não fica apagado no iPhone e no Android | Baixa | Baixo | Teste que perde e devolve o contexto e confere que desenha |
| C2 | Achar a causa do 3D-045 com o diagnóstico do Adauto | Fim do "fechar e abrir pra aparecer" | Média | Baixo | Teste com o projeto dele (sem dados pessoais) |
| C3 | Testes instáveis com carga: rodar de novo sozinho automaticamente e marcar "instável" | Bateria confiável | Baixa | Nenhum (só harness e CI) | — |
| C4 | Resolver a pendência do perfil G encostando 1,5 mm na caixa | Regra "nada entra em nada" | Baixa | Médio (posição da porta) | Teste de colisão das portas com gola |

## Médio prazo: precisão
| # | Proposta | Benefício | Complexidade | Risco |
|---|---|---|---|---|
| M1 | Inventário escrito dos embrulhos (`partsOf` 18, `draw` 41, `panel` 43, `build` 27): qual regra cada um aplica | Saber onde está cada regra; evitar regra duplicada | Média (só leitura) | Nenhum |
| M2 | Uma função única de colisão usada pelo 2D, 3D, pedra e eletros | Fim das diferenças entre telas | Alta | Alto: exige aprovação e bateria completa |
| M3 | Materiais e luz do 3D (fase 2 de `MOTOR_3D_AUDITORIA.md`) | Acabamento profissional | Média | Médio |
| M4 | Completar `GESTOS_CONTROLES.md` com o código de cada gesto e um teste por gesto | Gesto não muda sem querer | Média | Nenhum |

## Longo prazo: maturidade profissional
| # | Proposta | Benefício | Complexidade | Risco |
|---|---|---|---|---|
| L1 | Exportação para CNC (furação, rasgos, nesting), pedida pelo Adauto | Mandar projeto para marcenaria com CNC | Alta | Médio |
| L2 | Consolidar as regras de cada peça numa camada só (sem embrulhos), aos poucos, uma família de peça por vez, com bateria A/B | Código previsível e mais rápido | Alta | Alto |
| L3 | Refazer no 3D só o módulo alterado | Arrasto fluido em projeto grande (hoje uns 122 ms por passo na cena de 40 módulos) | Alta | Alto |
| L4 | Pranchas de montagem por módulo (vistas cotadas, furação) | Documentação de fábrica | Alta | Baixo |

Cada item precisa da aprovação do Adauto antes de começar. Todos passam pela bateria A/B e por teste novo.
