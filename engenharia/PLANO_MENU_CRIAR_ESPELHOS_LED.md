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

## 5. Decisões aprovadas pelo Adauto (22/11/2026) — substituem as perguntas anteriores
**Menu**: 6 categorias em 2 colunas, nesta ordem: Móveis | LED · Espelhos | Pedras · Paredes | Outros. Layout pela imagem de referência (será reenviada;
M1 espera ela). Nenhuma ferramenta existente é removida.
**Espelhos** (progressivo): retangular/quadrado → redondo/oval → arco → orgânico simples e assimétrico. Em vãos, painéis e paredes; mover, girar,
medidas editáveis.
**Orçamento da vidraçaria** (separado do MDF, materiais e serviços): preço por m² configurável **por acabamento**; lapidação e bisotê **por metro linear**,
valores editáveis; moldura em **MDF, alumínio ou perfil personalizado**. **Nenhum preço inventado**: campos começam vazios e o orçamento avisa
"preço não cadastrado" em vez de pôr zero escondido ou valor de exemplo.
**LED**:
- Biblioteca inicial **editável** de perfis embutidos e sobrepostos (estrutura pronta; medidas e preços só os informados — sem valor inventado).
- Todas as funções atuais de LED preservadas (`m.led`, botão, cores, noite, "Pôr no orçamento").
- Custo de **usinagem de rasgo** configurável (por metro).
- **Fontes por circuito**: soma da potência de todos os LEDs do circuito (W/m × m de cada perfil), com **tensão** (12/24 V), **capacidade da fonte**
  e **margem de segurança configurável**; nº de fontes = ⌈potência × (1 + margem) ÷ capacidade⌉, conferindo a tensão de fita e fonte. Não é uma fonte
  por LED nem por botão. Circuito = grupo que o usuário define (padrão: o botão do LED).
- **Rasgo sem margem universal**: valida pela espessura real da peça hospedeira e pela especificação do perfil (largura, profundidade do rasgo e
  espessura mínima de material que o fabricante exige, campo do perfil). Perfil sem esse dado → embutido bloqueado com aviso pra completar o cadastro.
**Responsabilidades**: Code 1 corrige o botão duplicado das panelas. Code 2 só implementa depois da auditoria do Chefe e da autorização específica do
Adauto, em etapas pequenas, cada uma com teste próprio e regressão completa. Candidata atual intocada. Sem merge nem publicação.
**Homologação da Política B**: NÃO homologada até o iOS 665 e a repetição do Windows 81 terminarem verdes.

## 6. Ajustes no plano por causa das decisões
- E5 passa a ter: preços por acabamento, lapidação/bisotê por metro, moldura (MDF/alumínio/personalizada), aviso de preço não cadastrado.
- E6 (orgânico) = "simples e assimétrico" (contornos editáveis por pontos), não biblioteca ornamental grande.
- L1 ganha os campos do perfil: tensão, W/m, espessura mínima de material, rasgo (larg × prof); cadastro de fontes (tensão, W, preço); margem de segurança.
- L7 (orçamento LED) = fontes por circuito pela fórmula acima + usinagem por metro.
- L5 (embutido) = validação pela espessura e pelo perfil, sem 3 mm fixo.

## 7. Imagem aprovada do menu (recebida 22/11/2026) — `engenharia/referencias/menu-criar-aprovado-2026-11-22.jpg`
Especificação visual tirada da imagem (M1 segue isto; conferência por captura iPhone/iPad/Windows lado a lado com a imagem):
- Cartão com borda fina arredondada sobre fundo preto; cabeçalho **"+ Criar"** à esquerda, grande, branco, e **chevron ⌄** à direita (abre/fecha
  o cartão); linha divisória fina abaixo do cabeçalho.
- Grade **2 colunas × 3 linhas**, espaçamento igual entre botões; botões **cinza-escuro (~#242424)**, cantos bem arredondados (~22–24 px),
  altura ≈ 40% da largura; **ícone centralizado em cima, nome embaixo**, texto branco grande.
- Ordem e ícones: **🪚 Móveis | 💡 LED · 🪞 Espelhos | 🪨 Pedras · 🧱 Paredes | ➕ Outros** (o "+" de Outros é cinza, não colorido).
- Ícones como emoji (o editor já usa emoji nos botões; sem imagem nova no pacote). Diferença de desenho do emoji entre iOS, Android e Windows é
  aceita; tamanho e posição iguais.
- Responsivo: no celular a grade ocupa a largura com margem; no iPad/Windows largura máxima fixa centralizada, mesmas proporções.
- Tocar numa categoria → ferramentas dela + "‹ Voltar" no mesmo cartão. ✕/chevron fecha. Sem reconstruir o 3D.
- Teste visual novo: `testMenuCriarIgualAImagemAprovada` (ordem dos 6 nomes, 2 colunas pelas posições na tela, ícones, cabeçalho com chevron) +
  capturas no CI.

## 8. Auditoria do Claude Chefe (22/11/2026, ~22:45 UTC) — APROVADA com 5 ressalvas obrigatórias
1. **Colisão do espelho girado**: as caixas de hoje são alinhadas aos eixos. Proposta: espelho girado conferido como **caixa orientada** (retângulo girado
   no plano do hospedeiro × espessura) contra as caixas do 3D, pelo teorema do eixo separador (2D no plano + intervalo na profundidade); formas
   curvas usam o polígono do contorno girado. "Encosta pode, entrar não", igual às peças livres. Teste: `testEspelhoGiradoNaoEntraNaPrateleira`
   (45°, encostado passa; 1 mm dentro é recusado; a caixa reta envolvente daria falso positivo e o teste prova que não dá).
2. **Desempenho**: meta ≈ **16 ms por passo de arraste com 20 módulos**, cache por gesto; medido e registrado em cada fase (E1…E7, L2…L8) num
   teste de tempo como o das peças livres.
3. **Imagem aprovada** = referência visual do M1 — **já recebida** (§7).
4. Teste antigo afetado só muda com comentário (pedido + data), **nunca afrouxado**.
5. Teste: **abrir e fechar o menu várias vezes** (e trocar categoria) não duplica nem perde ferramenta (contagem de cada `data-*` igual a cada ciclo).

**Condições para começar o M1**: candidata integrada homologada nas 3 plataformas · Code 1 corrigiu o `data-cpan` · autorização específica do
Adauto para a fase M1. Ao começar: trazer a candidata integrada para `feature/menu-criar-espelhos-led` **por merge**. Sem merge na main, sem publicação.
**Política B**: aprovada, condicionada ao iOS 665 e à repetição do Windows 81 verdes (Chefe: 411/411 no 973db09; a publicada c561120 recusa os links
de corte/cliente com peça livre sem gravar nada e abre os links sem peça livre).

## 9. Pendente
auditoria do Chefe · correção do `data-cpan` (Code 1) · iOS 665 e Windows 81 (repetição) · autorização específica.
