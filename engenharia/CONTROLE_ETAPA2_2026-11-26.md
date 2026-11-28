# Controle central · ETAPA 2 (Adauto, 26/11/2026)
Ramo de integração: `claude/etapa-2` (base 5067fecc = publicado: apk-725, win-190, iOS 3.0.14 build 713). Cada agente: ramo próprio a partir de `claude/etapa-2`, commits pequenos, o Chefe integra. Não publicar sem o "sim" final do Adauto. DXF continua desligado (DXF_OFF).
Concluído = implementado + integrado em claude/etapa-2 + testado + auditado pelo Code 1 + homologado (Adauto 27/11).
Regras do Adauto nesta etapa: só o que foi pedido; não remover nem desfazer nada que funciona; não mudar layout não autorizado; referências = especificação (ver REFERENCIAS.md · ETAPA 2).

| # | Pedido | Responsável | Depende de | Status | Commits / testes / evidência |
|---|---|---|---|---|---|
| 1 | Espelhos: "Equilibrado" só na config do espelho (sai do 3D); Jateado em todo espelho com LED; botão do LED; realismo do vidro | Claude 3 | — | a fazer | |
| 2 | Juntar bases lado a lado (≤2700 mm), escolher módulos, dividir acima de 2700, L com base atravessada, unir/separar/desfazer, nunca automático | Code 2 | confirmar com Adauto qual "base" | a fazer | |
| 3 | Dobradiças metálicas (não da cor da porta), caneco/braço/calço, movimento em todo o percurso | Claude 3 | — | a fazer | |
| 4 | Porta do forno sem atravessar (eixo real); relógio do forno = hora do aparelho; texturas/realismo sem perder desempenho | Claude 3 | — | a fazer | |
| 5 | Portas do canto (1ª e 2ª) abrindo 165°, juntas e separadas, balcão/aéreo/guarda-roupa, espelhados, sem mudar a estrutura | Claude 3 | eixos do canto cego (Code 2) | a fazer | |
| 6 | Canto: travessas e régua superior iguais às fotos (cruzamento), no cabeçalho e na Estrutura | Code 2 | dúvidas de medida → Adauto | a fazer | |
| 7 | Canto cego E/D conforme referência; projeto antigo só com botão de atualizar + desfazer | Code 2 | — | a fazer | |
| 8 | Estrutura do canto: desenho A/B, profundidade de cada lado, recuo automático (pedra) ou manual, voltar ao automático | Code 2 | — | a fazer | |
| 9 | Câmera no 2D; editar canto no 2D; pôr módulo ao lado; abrir config do módulo; câmera ≠ arrasto | Claude 4 | desenho A/B (Code 2) | a fazer | |
| 10 | Cabeçalho Divisões: divisórias primeiro, dividir por igual embaixo (nada removido) | Claude 4 | — | a fazer | |
| 11 | Modelos de porta: todos, miniaturas, Usados recentemente (salvo), puxadores embaixo · auditoria de puxadores flutuantes | Claude 4 (tela) · Claude 3 (3D) | — | a fazer | |
| 12 | Cabeçalho tamponamentos: esquerdo, direito, cava, pós-cava, resto | Claude 4 | — | a fazer | |
| 13 | Custos fixos na biblioteca de preços (vários, R$/%, por serviço, motor atual, sem duplicar, cópia no orçamento, fora do PDF/CSV/link) | Claude 5 | — | feito (364c88b; bateria 590/590 a 1366 e a 430 no 787f485) | |
| 14 | Desempenho iOS/Android/Windows: medir antes/depois, corrigir causa | Code 1 | — | a fazer | |
| 18 | Canto ESQUERDO e canto DIREITO (L): tudo dos itens 5, 6 e 8 vale para os dois lados, além do canto cego E/D (Adauto 26/11: "tem canto esquerdo, canto direito") | Code 2 (estrutura) · Claude 3 (165°) | — | a fazer | |
| 19 | Inferiores: composições prontas de frente — 2 gavetas + 1 gavetão; 3 gavetões; 2 gavetas; 1 gaveta + porta basculante; e livre montagem sem limitação. Reusar peças existentes de gaveta/basculante (partsOf), sem fórmula nova | Claude 4 (Code 1 audita fabricação) | — | a fazer | |
| 20 | ArqueCut: a pessoa escolhe manualmente em quais lados de cada peça vai fita (Adauto 26/11). Reflete em lista, plano de corte (linhas verdes), metros de fita e orçamento; padrão automático continua; desfazer; projeto antigo igual | Claude 5 | — | feito (7a90dce; bateria 590/590 a 1366 e a 430 no 787f485) | |
| 21 | ERRO (Adauto 26/11): módulos criados separados e encostados unem as BASES INFERIORES sozinhos. Cada módulo mantém a própria base; união só pelo "Unir bases" manual (item 2); separar de novo; auditar tampos/travessas/fundos/demais estruturais e todo o catálogo; corrigir a causa; conferir plano de corte; projeto antigo só avisa (sem separar sozinho); desfazer | Code 2 (prioridade antes do 7 e do 2) | — | a fazer | |
| 22 | PRIORIDADE (Adauto 27/11, iPhone): travessa frontal ao ser ativada sobe sozinha; nenhuma opção de estrutura pode desativar/mover outra; todas compatíveis ativas juntas; posição/altura/prof./espessura certas; 2D/3D/lista/corte/orçamento/DXF | Code 2 (antes do 7) | — | a fazer | |
| 23 | PRIORIDADE: paredes invertidas/espelho — mover p/ direita vai p/ direita na vista do cliente (todas as paredes, multi-paredes); espelho visual não inverte coordenada real; arrasto, posição, rotação, vincular/desvincular, salvar/reabrir | Claude 3 (antes do 5) | — | a fazer | |
| 24 | Auditoria geral de medidas e informações contraditórias (campos × peças reais × 2D/3D × lista/corte/orçamento/DXF; E/D invertidos; mm↔cm; coordenadas) — corrigir a causa | Code 1 (com o 14) | — | a fazer | |
| 25 | Janela: 1 toque = seleciona; 2 toques = configurações; arrastar só no modo certo; conferir portas/paredes/arquitetônicos | Claude 4 (antes do 19) | — | a fazer | |
| 26 | Módulos no 2D: 1 toque = seleção normal; 2 toques no meio = acesso rápido que JÁ EXISTE (portas, prateleiras, divisórias, gavetas…); 2 toques numa peça = edição dela; arrasto/zoom sem abrir menu | Claude 4 | — | a fazer | |
| 27 | Auditoria de toques (módulos, vãos, laterais, bases, travessas, divisórias, tamponamentos, réguas, portas, gavetas, prateleiras, janelas, paredes, LED, espelhos, peças livres, elementos pequenos/próximos; simples/duplo/longo; arrasto/zoom/rotação) — iPhone/iPad com toque real | Claude 4 (Code 1 confere) | — | a fazer | |
| 28 | Regra permanente: o cliente controla o projeto (CLAUDE.md §12, reforçada 27/11) | todos | — | sempre | |
| 29 | (classificado pelo Code 1 em 27/11: A31, TOQUE-430 fundo, update iOS e apmodels = concluídos e publicados em 5067fecc; abertura lenta do iPhone = parcial, ok no simulador e sem verificação em aparelho real; N11 e confineAll = não iniciados → itens 30 e 31) Recuperar pendências antigas (controle 25/11): A31 projeto antigo/gavetas/régua +47; TOQUE-430 ambiente fundo; abertura lenta do iPhone; atualização por cima iOS (2 verdes); apmodels corrompido; riscos N11 e confineAll — classificar cada um (concluído e publicado / parcial / não iniciado) com prova, e abrir o que faltar | Code 1 (classifica) → Chefe redistribui | — | a fazer | |
| 30 | Risco N11: plano de corte não determinístico sob carga (1 em 142 modelos: "Estante torre aberta com gavetas embaixo" dá outro HTML com a máquina carregada) — achar a causa | Claude 5 | — | feito (44475b2; bateria 590/590 a 1366 e a 430 no 787f485) | |
| 31 | Risco confineAll/roomClamp escreve e desfaz nos módulos — trocar por cálculo sem escrita (sem mudar resultado) | Claude 5 | — | feito (787f485; bateria 590/590 a 1366 e a 430 no 787f485) | |
| 32 | Travessa frontal em TODAS as plataformas: tocar em adicionar sobe a tela, não adiciona, botão "vazio". Cadeia inteira toque→peça→render→salvar; tela/zoom/seleção preservados; travessa + teto combináveis (proposta Code 2 item 22: em pé atrás da porta, embaixo do teto) | Code 2 (junto do 22) | — | a fazer | |
| 33 | Moldura não adiciona: criação, posição, medidas, espessura, material, edição, combinação com tudo, 2D/3D, fabricação, salvar/reabrir | Code 2 | — | a fazer | |
| 34 | Auditoria de TODOS os botões/menus/campos/comandos acionando de verdade: executa o anunciado, mexe só no alvo, salva, desfaz, todas as plataformas, sem rolagem/fechamento involuntário. Corrigir, nunca esconder | Code 2 (estrutura) + Claude 4 (interface) | — | a fazer | |
| 35 | Regra absoluta de autonomia (nenhuma dependência artificial entre opções; combinar livremente tudo; recalcular só o efeito direto da ação) — documentar em CLAUDE.md §12 e DECISOES_TECNICAS | Chefe (doc) / todos | — | registrada | |
| 36 | Rejeição de palma e caneta (Apple Pencil, S Pen, Windows pen): palma não seleciona, abre, move, mede, adiciona, apaga, zoom nem câmera; gestos intencionais preservados | Claude 4 | — | a fazer | |
| 37 | Campos numéricos e de espaçamento (módulos, peças, parede, recuos, folgas, alturas, larguras, profundidades, posição): abrir, digitar sem fechar, teclado certo, mm/cm, confirmar/cancelar, valor exato, desfazer | Claude 4 | — | a fazer | |
| 38 | Medida aplicada no 2D: redimensionar × reposicionar × só espaçamento × só a peça — quando ambíguo, perguntar com opções; ex. 800−50 = 750 (redimensionar) ou 800 deslocado (afastar) | Claude 4 | — | a fazer | |
| 39 | Contaminação entre paredes (2D/3D): móvel/régua/peça aparecendo em parede onde não existe (ex. régua da parede esquerda em outra); parede vazia fica vazia; espelho não cria/duplica/transfere. Corrigir a causa (ids, índices, transformações, cache, persistência) | Claude 3 (junto do 23) | — | a fazer | |
| 40 | Cruzamento integral de dados: projeto × 2D × 3D × planta × estrutura × medidas × coordenadas × ids paredes/módulos/peças × lista × corte × fitas × materiais × ferragens × orçamento × DXF × salvos × backups × desfazer | Code 1 (com o 24) | — | a fazer | |
| 41 | Precisão e experiência profissional (resposta, seleção, sem movimento/rolagem/menu involuntário, projetos grandes, fluidez) | Code 1 (14) + Claude 4 | — | a fazer | |
| 42 | 5º agente (Claude 5, autorizado 27/11): itens 13 (custos fixos), 20 (fita manual ArqueCut), 30 (N11), 31 (confineAll) | Claude 5 | — | a fazer | |
| 43 | 5 pendências decididas pelo Adauto 28/11 (DECISOES): base atravessada L (Claude 5 geometria + Code 2 botão/opção) · pistão basculante (Claude 3) · fita régua engrosso 80 (Code 2) · divisória canto cego livre (Claude 3) · régua na parede errada = item 39 (Claude 4) | vários | — | a fazer | |
| 15 | Controle central e integração | Chefe | — | em andamento | este arquivo |
| 16 | Regras permanentes | todos | — | sempre | |
| 17 | Homologação independente (iPhone, iPad, Android, Windows, update por cima, projetos antigos, prints e vídeos) | Code 1 + Chefe | 1–14 | depois | |

## ETAPA 3 (Adauto 28/11) · PRECISÃO INTELIGENTE DE SELEÇÃO E INTERAÇÃO NO 3D — começa quando cada agente terminar a pendência atual
| # | Pedido | Responsável | Status |
|---|---|---|---|
| 3.1 | Seleção precisa no 3D: superiores/inferiores, nichos pequenos e profundos, cantos, prateleiras, divisórias, portas, gavetas, travessas, tamponamentos, réguas, peças livres, LED, espelhos, acessórios; id individual inequívoco | Claude 4 (seleção) · Claude 5 (sonda de ids no catálogo) | a fazer |
| 3.2 | Seleção inteligente pelo zoom (nível, ponto do toque, módulo predominante na tela, distância, ângulo, peça atingida, módulo já selecionado) — ajuda a escolher, nunca bloqueia outro visível, nunca altera nada | Claude 4 | a fazer |
| 3.3 | LED: entra no módulo e na peça realmente escolhidos (coordenadas, medidas, profundidade, orientação, rotação), superfícies sup/inf/lat/int/ext, nichos superiores; posição inicial = intenção; fora da caixa só manual, livre | Claude 3 | a fazer |
| 3.4 | Zoom e gestos no 3D: pinça, aproximar peça pequena (zoom bem próximo), girar, mover a vista, 1/2 toques, toque longo, telas pequenas, conflito seleção × mover × abrir porta — sem tirar gesto existente | Claude 4 | a fazer |
| 3.5 | Destaque visual do módulo e da peça selecionados; destino da operação claro antes de pôr LED/acessório/componente; ambiguidade real = escolha simples, sem confirmação a cada toque | Claude 3 | a fazer |
| 3.6 | Auditoria em todos os tamanhos de iPhone (compacto, comum, Plus, Pro, Pro Max), iPad, Android, Windows; separar aparelho físico × simulador | Code 1 (+ Chefe no CI) | a fazer |
| 3.7 | Desempenho: toque imediato, zoom fluido, sem travar, sem seleção ou rolagem involuntária, projetos grandes | Code 1 | a fazer |
| 3.8 | Testes específicos (seleção, zoom, id de módulo, LED, peças pequenas), reproduzir antes, causa raiz, relatório antes/depois com prints e vídeos | todos · auditoria cruzada | a fazer |
