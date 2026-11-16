# Desempenho: auditoria, medições e regressões

Começou em 16/11/2026, com o "Protocolo global de performance" das 10:01. **Nenhuma versão pública foi alterada.**

## 1. Onde foi medido (e o que isso não prova)
- **Editor (2D e 3D):** `app/src/main/assets/editor.html`, o mesmo do iPhone, do Android e do Windows.
  - Medido no Chromium sem tela, num servidor de 2 processadores.
  - O 3D é desenhado pelo processador (SwiftShader), sem placa de vídeo. Por isso o tempo de quadro do 3D e o FPS daqui **não valem como FPS de aparelho**.
  - Os tempos de JavaScript e as contagens de trabalho valem para comparar antes e depois:
    - montagens da página;
    - medições de texto;
    - envios para a placa;
    - memória reaproveitada.
- **Caderno (Android e Windows, mesmo código):** `SheetCache.kt`, medido na JVM do Windows (Skia), folha de 1200 × 1700.
- **Sem aparelho físico:** nada foi medido em iPhone, iPad, Galaxy Tab S9 FE, Android intermediário nem Windows de verdade.
  - O WKWebView (iPhone) e o WebView do Android podem se comportar diferente do Chromium.
  - Para medir no aparelho falta o medidor de quadros no "🔎 Diagnóstico do 3D". Ele está proposto no `MOTOR_3D_AUDITORIA.md` e **depende de aprovação**.
- **Carga:** as medições finais (seção 3) foram feitas com a máquina parada, alternando antes e depois. As medições feitas com a bateria rodando ao lado (CPU com carga 8 a 10) variaram mais que a diferença medida e não foram usadas para concluir nada.

## 2. Cenários
- **Cozinha grande:** 15 a 18 módulos.
  - Torre de forno + micro-ondas, despenseiro, balcões, gaveteiros, pia, 6 aéreos;
  - na versão do `perf.mjs`, também a parede esquerda;
  - pedra, 224 a 314 peças, 1.698 caixas no 3D.
- **Closet:** 4 guarda-roupas de 2 e 3 vãos no editor por vãos, mais 2 na parede esquerda.
- **Torre:** torres e armários altos.
- **Caderno:** folha com 600 traços de 60 pontos e 2 fotos de 3000 × 2000.
- **Telas:** celular 440 × 956 (densidade 2), tablet 1180 × 820 (densidade 2), computador 1366 × 768.
- **Scripts** (fora do repositório, na pasta de trabalho da sessão):
  - `perf/perf.mjs`: gestos completos com perfil de CPU;
  - `perf/lc.mjs`: montagens da página no arraste;
  - `pj/medidas.js`: toque no 2D, abrir 3D, selecionar peça, quadro da animação;
  - `pj/dragtime60.js`: tempo por movimento do arraste;
  - `pj/hashbuf.js`: bytes mandados para a placa;
  - `pj/orb.js`: girar.

## 3. Resultados antes × depois
Antes = commit 93495d1. Depois = esta versão. Cozinha grande no celular (15 módulos, 224 peças, 1.698 caixas no 3D). Máquina parada, 3 rodadas alternadas; os números são a mediana das 3.

### 3D
| O que o usuário faz | Meta | Antes | Depois |
|---|---|---|---|
| Quadro da animação de abrir porta: refaz a cena, manda pra placa e desenha (mediana / pior 10%) | 16,7 ms (60 FPS) | 33,5 / 56,9 ms | **19,6 / 25,2 ms** |
| 2 toques numa peça: seleciona, refaz a cena e abre o quadro da peça (mediana / pior 10%) | 50 ms | 65,9 / 101 ms | **46,7 / 72,9 ms** |
| Só montar a cena (`build`) | — | 15,1 ms | 15,3 ms (não mudou) |
| Abrir o 3D | imediato | 37 ms | 40 ms (igual, dentro da variação) |
| Girar ou dar zoom: JavaScript do quadro (câmera) | — | 0,1 ms | 0,1 ms |

- **Girar e zoom:** o JavaScript de cada quadro é desprezível (0,1 ms) e não refaz a cena. O resto do quadro é a placa de vídeo. Aqui ela é simulada pelo processador: girando a cozinha grande, 257 a 283 ms por quadro antes e 266 a 281 ms depois (igual). Por isso **o FPS de girar no aparelho não foi medido**.
- **Bytes mandados para a placa:** iguais, byte a byte, antes e depois.
  - Cozinha com 3 padrões de foto: 72 envios, a mesma assinatura.
  - Quarto: 40 envios, a mesma assinatura.

### Gestos completos por cenário (`perf.mjs`, 1 rodada de cada, máquina parada)
FPS medido pelo navegador. No 3D a placa de vídeo é simulada pelo processador, então os FPS do 3D aqui **não representam o aparelho**: servem só para ver que nada piorou.

| Cenário | Arrastar no 2D (antes → depois) | 1 toque numa porta: pior 5% do quadro (antes → depois) | Girar 3D (antes → depois) |
|---|---|---|---|
| Cozinha 18 módulos, celular | 60 → 60 FPS | 16,8 → 50 ms | 11,5 → 11,3 FPS |
| Cozinha 18 módulos, tablet | 60 → 59,6 FPS | 683 → 50 ms | 6,0 → 6,4 FPS |
| Closet 6 módulos, celular | 60 → 60 FPS | 50 → 33 ms | 8,8 → 8,5 FPS |
| Torre, computador | 60 → 60 FPS | 16,8 → 16,8 ms | 23,7 → 24,1 FPS |

- Arrastar no 2D fica em 60 FPS em todos os cenários, antes e depois.
- O pior quadro do toque na porta varia muito de uma rodada para outra. A comparação que vale é a da tabela do 3D acima, com 3 rodadas.

### 2D (arrastar um módulo)
| Medida | Antes | Depois |
|---|---|---|
| Montagens da página em 40 movimentos, com a vista de cima aberta | 367 | **124** |
| Montagens da página em 40 movimentos, com a vista de cima fechada | 204 | **123** |
| Medições de rótulo da vista de cima em 12 movimentos | 466 | **0** (arruma 1 vez quando solta) |
| Medições da largura da vista de cima em 12 movimentos | 36 | **0** |
| Tempo por movimento com a vista de cima aberta (mediana das 3 rodadas) | 16,7 ms | 13,6 ms |
| Tempo por movimento com a vista de cima fechada | 15,6 ms | 14,3 ms |
| Tocar num módulo até o próximo quadro (mediana) | 25,4 ms | 27,8 ms (igual, dentro da variação) |

- O tempo total de montagem da página ficou parecido (95 ms nos 40 movimentos, antes e depois): são menos montagens, cada uma um pouco maior. **O ganho de tempo no 2D é pequeno** (cerca de 1 a 3 ms por movimento) e fica perto da variação entre rodadas.
- O desenho final é o mesmo. Os rótulos ficam no mesmo lugar (conferido texto a texto: 43 rótulos iguais). A imagem do 2D e a do 3D parado são iguais pixel a pixel, antes e depois.

### Caderno (Android e Windows)
| Medida (folha com 600 traços + 2 fotos, 1200 × 1700) | Antes | Depois |
|---|---|---|
| Tempo por ponto do traço (mediana) | 248,4 ms | **4,4 ms** |
| Folha inteira desenhada durante um traço de 120 pontos | a cada ponto | **1 vez** |
| Diferença de pixels entre o desenho com imagem guardada e o desenho direto | — | **0** |

- No iPhone a folha já usava imagem guardada (`SheetCanvas.swift`), então lá não muda nada.
- **Salvamento automático:** conferido no código. Acontece 600 ms depois da última mudança, fora da linha principal, e a miniatura também é feita fora dela. Não interrompe a escrita. Não foi medido em aparelho.
- **Não foram otimizados:** borracha, laço e câmera mexendo (arrastar a folha, pinça). Nesses casos a folha continua sendo desenhada direto, como era.

## 4. Os 3 maiores gargalos achados
1. **3D: qualquer mudança refaz a cena inteira.** Isso vale para selecionar peça, cada quadro da animação de porta e gaveta, e editar medida.
   - Montar a cena: cerca de 15 ms.
   - Montar os vértices e mandar para a placa: cerca de 18 ms.
   - Os vértices iam para listas comuns do JavaScript e eram copiados de novo para números de 32 bits a cada vez, criando lixo para o coletor.
   - É o que segurava a animação da porta em cerca de 30 quadros por segundo e a seleção acima de 50 ms.
2. **Caderno no Android e no Windows:** a folha inteira (traços, fotos, papel) era desenhada de novo a cada ponto do traço. Com a folha cheia, 248 ms por ponto.
3. **2D, arrastar módulo:** a página era montada várias vezes no meio de cada movimento.
   - A vista de cima media cada rótulo (cerca de 40 por movimento) e a própria largura.
   - Os rótulos de distância mudavam de lugar e mediam de novo a cada tentativa.

## 5. O que foi mudado
| Arquivo | Função | Mudança |
|---|---|---|
| `editor.html` | `glFill`, `FB3`, `fb3` | Os vértices vão direto para uma memória de 32 bits que é reaproveitada de uma vez para outra. Os números, a ordem e as chamadas de desenho são os mesmos. |
| `editor.html` | `plDcl`, observador da vista de cima | Durante o arraste, os rótulos da vista de cima são arrumados quando o dedo para (150 ms). Com a vista de cima fechada, nada é medido; arruma quando ela abre. |
| `editor.html` | `plHW`, `plUpx`, `plHandleFix` | A largura da vista de cima fica guardada e só é medida de novo quando a vista muda de tamanho (`ResizeObserver`). |
| `editor.html` | rótulos de distância do módulo (wrapper do `draw`) | Cada texto é medido uma vez e os lugares são testados pela conta. O lugar escolhido é o mesmo. |
| `SheetCache.kt` (Android e Windows, novo) | `paint`, `rebuild`, `bake` | Imagem guardada da folha, igual à do iPhone. Escrevendo, só o traço novo é desenhado; soltou, ele entra na imagem. |
| `SheetRenderer.kt`, `Session.kt`, `Gestures.kt`, `EditorScreen.kt` | `drawOne`, `skipId`, `staticRev`, `liveId` | Ligações do caderno com a imagem guardada. Com câmera mexendo, laço ou borracha, desenha direto como antes. |

Nada disso mexe em medida, peça, cálculo, plano de corte, setas ou projeto salvo.

## 6. Testado e descartado
- **Resolução menor no 3D durante o gesto:** 1,3 ponto por pixel enquanto o dedo mexe e a resolução cheia 160 ms depois que para.
  - Aqui ficou **mais lento**: 500 → 660 ms por quadro, medido com a máquina carregada. Quando o quadro passa de 160 ms, a resolução fica trocando a cada movimento, e cada troca recria a área de desenho. Mesmo com a resolução baixa o tempo todo, não ficou mais rápido, porque nesta máquina o custo não está nos pixels.
  - Sem um aparelho com placa de vídeo, não dá para provar que ganha.
  - Foi desfeito. Pode voltar a ser avaliado com o medidor de quadros no aparelho (ver seção 1).

## 7. Gargalos que continuam (não mexidos)
- **3D: selecionar peça ainda refaz a cena inteira.** Ficou em 47 ms na mediana e 73 ms no pior caso, perto da meta de 50 ms. Para ir além é preciso refazer só o que mudou (item 7 da proposta do `MOTOR_3D_AUDITORIA.md`). É uma mudança estrutural no motor e **depende de aprovação**.
- **3D: a animação de porta** também refaz a cena a cada quadro: 20 ms, ou cerca de 50 quadros por segundo nesta máquina. Atualizar só a peça que mexe tem o mesmo caminho e a mesma dependência do item acima.
- **2D: o desenho de cada módulo** é refeito inteiro em todo movimento do arraste (`modSvg` e `partsOf`), cerca de 13 a 15 ms. Para o arraste ficar mais leve seria preciso redesenhar só o módulo que se mexe. É uma mudança grande no 2D e não foi feita.
- **FPS de girar e de zoom no aparelho:** não medido (seção 1).

## 8. Testes de regressão de desempenho
Os testes contam o trabalho, não o relógio. O relógio varia com a máquina e daria falso alarme.
- `testDesempenhoArrastarNo2DNaoMedeAVistaDeCimaERefazer3DReaproveitaAMemoria` (bateria do editor):
  - arrastando, a vista de cima não mede rótulos nem largura;
  - quando o dedo para, arruma os rótulos;
  - refazer a cena do 3D usa a mesma memória dos vértices.
  - Em 93495d1 ele falha: 466 medições, 36 larguras, memória nova a cada vez.
- `CadernoDesempenhoTest` (Windows, JUnit):
  - escrevendo, a folha inteira é desenhada 1 vez só;
  - o desenho é igual ao direto, pixel a pixel;
  - soltar soma o traço sem redesenhar;
  - desfazer refaz 1 vez;
  - câmera mexendo desenha direto.
- **Como medir de novo** (scripts da seção 2): rodar alternando antes e depois, com a máquina parada.
  - Se uma mudança fizer o quadro da animação passar de 25 ms ou a seleção passar de 60 ms (mediana, cozinha grande), avisar antes de liberar.
