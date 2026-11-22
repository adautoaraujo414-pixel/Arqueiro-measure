# Plano de implementação — novo menu "＋ Criar", Espelhos e LED no Criar

Ramo separado `feature/menu-criar-espelhos-led`, criado a partir de `feature/pecas-livres-2d` (2b9e949). Claude Code 2, 22/11/2026.
**Este ramo ainda não muda código.** Só este plano. O código começa depois de três coisas: a auditoria do Claude Chefe, a autorização do Adauto e as respostas
às perguntas do fim. Não haverá merge, publicação nem mudança na candidata.

Base técnica (não repetida aqui):
- `engenharia/PROPOSTA_MENU_CRIAR_ESPELHOS.md`: auditoria do `#crp3` e dos 12 embrulhos, modelo `S.esp`, riscos.
- `engenharia/PROPOSTA_LED.md`: LED atual (`m.led`, `ledStrip`/`ledGlow`) e modelo `m.leds[]` + `PR.ledPerfis`.

## 0. Antes de escrever código (bloqueios)
| # | Bloqueio | Com quem |
|---|----------|----------|
| B1 | **Imagem aprovada do menu**: não chegou a nenhuma sessão do Code 2. Sem ela não dá pra fazer "exatamente como a imagem" (nomes, ícones, ordem, cores). | Adauto |
| B2 | Auditoria deste plano: conflitos com a linha do Code 1 (menu, LED, `pickItem`, `snapState`). | Claude Chefe |
| B3 | Defeito do `data-cpan` duplicado: corrigir antes de re-agrupar, senão o botão errado vai pra categoria errada. | Code 1 |
| B4 | Respostas: as 5 perguntas do menu/espelho e as 5 do LED. | Adauto |

## 1. Regras que valem pra todas as etapas
- **Editor 3D**: reaproveitar o atual. Nada de segundo motor, editor ou seleção. Espelho segue o padrão do `S.fr`; LED novo estende o `m.led`.
- **Ferramentas e testes existentes**:
  - Nenhuma ferramenta do menu de hoje é apagada.
  - Os `data-*` continuam no DOM com os mesmos tratadores.
  - Os testes antigos só mudam com pedido explícito e com comentário.
- **Projetos existentes**:
  - Abrem e salvam iguais.
  - Campo novo é opcional (`S.esp` vazio, `m.leds` ausente).
  - Política B: projeto, link ou pacote com espelho ou LED novo ganha marcador de formato. A versão antiga recusa com aviso, em vez de abrir sem o item.
- **Desempenho**:
  - Abrir menu ou trocar categoria não reconstrói o 3D.
  - Arrasto usa o cache de gesto (1 reconstrução por gesto), como as peças livres.
- **Cada etapa**:
  - 1 commit pequeno.
  - Teste novo que falha antes e passa depois.
  - Bateria local completa.
  - CI iOS, Android e Windows verdes antes da próxima etapa.
  - Relatório ao Chefe.

## 2. Etapas
| Etapa | O quê | Muda o quê | Teste novo (nome provisório) |
|---|---|---|---|
| **M1** | Grade 2×3, fundo escuro, botões grandes arredondados, ✕ e "‹ Voltar", responsiva (celular, iPad, Windows). Re-agrupa os botões que já existem, por um único embrulho no fim da cadeia. | Só o `#crp3` (CSS e 1 embrulho) | `testMenuCriarSeisCategoriasNenhumaFerramentaSome`: abre e fecha; navega nas 6; compara a lista de `data-*` antes e depois; sem `__build` |
| **M2** | Categoria **LED** com as ferramentas de hoje (`data-clk`, `clc`, `cled`, `clon`, `cnight`, `corc`, `clbm`, `clbc`). Comportamento idêntico. | Distribuição | Os testes de LED atuais passam como estão (`testBotaoDoLEDUmSoOuUmPorModulo…`, `testLEDChamaAguaEEditarNo3D`, `testLedNoRipado…`) mais a conferência de que estão na categoria LED |
| **E1** | Espelho **retangular ou quadrado** em parede e painel: criar, tocar, painel, mover, tamanho em mm, excluir, salvar e reabrir, desfazer, Política B. | `S.esp`, `snapState`/`loadState`, desenho 3D opaco com realce `t=9`, `pickItem` | `testEspelhoRetangularNaParedeSalvaReabreEDesfaz`, `testPoliticaBProjetoComEspelho` |
| **E2** | **Girar** (livre e 0/90/180/270), duplicar, centralizar, alinhar às bordas, distância do chão, teto e laterais. | Painel do espelho | `testEspelhoGirarDuplicarAlinhar` |
| **E3** | Espelho **no vão**: "Ajustar ao vão" lê a largura e a altura livres do módulo (caixas do 3D), com recuos em mm. Fica vinculado ao móvel (o móvel anda e o espelho vai junto). Não cria peça de MDF. | `host:{k:'vao'}` | `testEspelhoNoVaoAcompanhaOMovelSemMudarMedida` |
| **E4** | Formatos **redondo, oval e arco**: contorno por pontos (`arcPts`) e `b.pf`. | Desenho | `testEspelhoFormatosContornoDeVerdade` (área ≠ retângulo) |
| **E5** | Acabamentos: prata, bronze, fumê; lapidado ou bisotado; moldura. Mais a **lista de vidraçaria** separada do MDF, com área pelo polígono real e perímetro, e o orçamento por m². | Orçamento, PDF, `PR.cat` | `testEspelhoNoOrcamentoSeparadoDoMDF`: o plano de corte da marcenaria fica igual |
| **E6** | Ornamental ou orgânico: triangulação de contorno côncavo e biblioteca de contornos. | Desenho | `testEspelhoOrganicoSemFuro` |
| **L1** | LED, fase 1: biblioteca de perfis (`PR.ledPerfis`, sem medida inventada), modelo `m.leds[]`, salvar e reabrir, Política B. Botão "💡 Adicionar LED" dentro de Criar › LED. | Dados | `testLEDNovoSalvaReabreSemMudarOLedAntigo` |
| **L2** | LED, fase 2: **sobreposto** numa face. Toque, face, prévia, confirmar; posição, comprimento e distâncias. | 3D com `ledStrip`/`ledGlow` | `testAdicionarLEDSobrepostoNaPrateleira` |
| **L3–L8** | Rotação e duplicar; ferragens (zonas proibidas); embutido com rasgo `p.usin`; magnético; orçamento estruturado; desempenho. Conforme a PROPOSTA_LED §10. | — | Um teste por fase |
| **E7** | Espelho com LED: campo `led` reaproveitando o LED (depende de L2). | — | `testEspelhoComLED` |
| **H** | Homologação: iOS, Android e Windows; atualização por cima de projeto antigo; desempenho com 20 módulos. | — | Bateria completa |

Ordem sugerida: **M1 → M2 → E1 → E2 → E3 → E4 → E5 → L1 → L2 → (L3–L8) → E6 → E7 → H**.
M1 e M2 dependem da imagem (B1). E1 em diante pode andar sem a imagem: entra na categoria Espelhos, seja qual for o desenho final.

## 3. Testes de regressão que precisam continuar verdes (sem mudar)
- **Menu**: `testEletroPelo3DComLupa…` (5 `data-ccat`, `#crpq`), `testBotaoDoLEDUmSoOuUmPorModulo…` (3 `data-clbm`, 5 `data-clbc`), `testIlhaComPedraParedesEOrcamento` (`#v3add`, `data-cadd="pen"`).
  - Se a imagem aprovada pedir a grade como primeira tela, esses 2 a 3 testes passam a tocar antes na categoria. Isso vira mudança de expectativa com comentário do pedido, e só com o OK do Adauto.
- **LED**: `testLEDChamaAguaEEditarNo3D`, `testLedNoRipado…` (3), `testFotosDaLojaSalaComLedDeNoite…`.
- **Peças livres e compatibilidade**: `testCompatibilidadeDosProjetos…`, `testPoliticaBProjetoComPecasLivres…`, `testPecasLivresNoOrcamentoNoPDF…`.
- **Ambiente**: `testAmbienteNaoModificaOsMoveisSoAvisa`. Espelho em parede não move móvel.
- **Bateria inteira**: 411 hoje no Windows. iOS em iPhone e iPad.

## 4. Riscos (resumo; detalhes nas propostas)
- **Embrulhos do menu**: 12 embrulhos acham a seção pelo texto do título. Por isso o re-agrupamento fica por último, sem renomear nada antes.
- **Toque disputado**: o toque no espelho disputa com painel e parede (regra de profundidade no `pickItem`), com os 2 toques de mover e com o segurar do LED.
- **Espelho opaco**: o 3D não ordena transparência, então o espelho é opaco e não há reflexo em tempo real.
- **Contorno orgânico**: exige triangulação nova (E6 isolada).
- **Tempo do teste do iOS**: `testNadaDeEnfeiteAbasDoModuloParte1` já estoura 2 min no iPhone (execução 663). Qualquer controle novo no painel do módulo aumenta esse tempo. O painel do espelho é próprio (não entra nas abas do módulo) para não piorar.

## 5. Perguntas ao Adauto (as das propostas, juntas)
- **Menu e espelhos**:
  1. Reenviar a imagem do menu.
  2. A distribuição nas 6 categorias está certa?
  3. Quais contornos ornamentais entram primeiro?
  4. Preço por m² por acabamento, e lapidação ou bisotê por metro?
  5. Moldura de quê, e como entra no orçamento?
- **LED**:
  1. Quais perfis entram na biblioteca inicial (ou ela começa vazia)?
  2. A usinagem entra no orçamento?
  3. Fonte por botão ou por LED, e qual potência?
  4. O `m.led` atual fica ao lado do novo?
  5. Margem mínima do rasgo (proposta 3 mm)?
