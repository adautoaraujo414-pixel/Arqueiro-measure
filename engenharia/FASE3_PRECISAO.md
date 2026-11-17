# Fase 3 · Precisão do editor: diagnóstico (17/11), nada corrigido

- **Base:** editor do `7c939bc`, o mesmo do Android 1.0.632 e do Windows win-143.
- **Como foi feito:** só leitura, com toques e teclado simulados pelo caminho real (Chromium sem tela, 1366×768, zoom normal com VB 900 = 5,25 mm/px).
- **Sondas:** ficaram na pasta de rascunho da sessão (f3a, f3b, f3c); viram sondas do repositório na correção.
- **Classificação:** erro comprovado / risco / correto / não verificado.

## 0. URGENTE (achado fora da lista): parede e pé-direito digitados esmagam os módulos
- **Reproduzido:** cozinha demo, cota da parede no 2D (`openQ('W')`), digitar 320 (cm no lugar de mm) e depois 3600.
  - Todos os módulos ficam com largura 500 e x 0. Não voltam ao corrigir a parede.
  - O aviso diz "Nenhuma medida foi alterada", o que é falso.
  - Pé-direito 1500 e depois o original: módulos mudam e não voltam.
- **Causa:** `editor.html` 2396–2398, `change` dos campos W/H/stT. Depois do `setv`, um laço grava `o.w`, `o.x`, `o.h` e `o.b` em todos os módulos, fora da guarda GEO-AVISA. Tem também `Math.max(500,…)` em S.W/S.H e corta a pedra (`stW`).
- **Por que a homologação não pegou:** as sondas s11, s13 e s27 usaram `setv('W')` direto, sem passar por esse `change`.
- **Contorno até corrigir:** ↶ Desfazer volta tudo (2 toques), enquanto o projeto não for fechado. Cópias datadas de projeto (Android) e backup automático existem.
- **Correção mínima:** tirar o laço e deixar a guarda avisar (regra GEO-AVISA aprovada). Teste: a cota W 320 → 3600 deixa os módulos idênticos e mostra aviso. Hoje falha.

## 1. Menus mudando de posição (erro comprovado)
- **A. Abas do editor por vãos em outra ordem:**
  - normal (`TABORD`, :257): Ambiente > Cores > Estrutura > Divisões > Portas > Internos > …;
  - por vãos (`tabsHtml`, :10558): Divisões > Gavetas > Internos > Portas > Eletros > Estrutura > Cores.
  - Torres da mesma família abrem em editores diferentes (Armário alto vai para o por vãos, Torre quente fica no normal).
- **B. Seções de Portas vazando para o editor por vãos:**
  - Quem estava na aba Portas e entra no por vãos vê "Modelo da porta" e "Puxadores" em todas as abas dele.
  - Causa: `soloOn` (:8120) preserva `S.tab=3`, e os embrulhos :11655 e `isPor()` :10968 leem `S.tab`.
- **C. Menu do vão (#vmenu):** a ordem dos botões muda por tipo de módulo.
  - O bloco "Por dentro deste vão" entra no topo nos armários altos e o bloco de quarto no guarda-roupa: "1 porta" desce ~230 px.
  - 7 camadas mexem no menu: :2147, :2424, :9069, :9717, :9757, :10003, :10439, :12363.
- **Correto:** dentro do editor normal a ordem das seções é estável. As diferenças são regra (aéreo sem rodapé etc.).

## 2. Escolha de vão sensível demais (erro comprovado)
- O `pointerdown` (:1251–1254) troca o módulo e o vão escolhidos **ao encostar**, antes de saber se é toque ou arrasto.
- Num módulo não escolhido, o mesmo gesto já arrasta:
  - vertical: 12 px de dedo = +30 mm na altura do chão, 60 px = +280 mm;
  - horizontal: 6 px = 5 mm.
- Um dedo sobre o móvel nunca rola a tela (`touchmove` preventDefault, :1287).
- **Correto:** o editor por vãos só escolhe ao soltar, com no máximo 11 px de movimento.

## 3. Dois toques que "fecham" ou trocam o vão (erro comprovado, "fechar" literal não reproduzido)
- **Janela de tempo:** 430 ms de um soltar ao outro (:772). Com o dedo apertando ~150 ms, sobram ~280 ms. Com 360 ms já não abre e o 1º toque escolhe a porta.
- **Tremida:** 7–8 px num toque cancela os dois e move o módulo 15–25 mm. A tolerância é em unidades do SVG (:1228), então muda com o zoom.
- **2º toque perto da divisória** (até 22 px): escolhe a divisória e o menu não abre.
- **Risco:** 4 toques travam ou destravam o módulo.
- **Fechamento:** o #vmenu não fecha ao tocar fora; o menu rápido do editor por vãos fecha com qualquer toque fora (:12273).

## 5. Divisória escolhida sem tocar nela (erro comprovado)
- **Alcance no 2D:**
  - zoom normal: até 22 px = 116 mm;
  - com zoom: até 34 px (VB 225) e 58 px (VB 150), porque o mínimo de 18 unidades do SVG (:1118) cresce com o zoom. O comentário de :12190 diz "22 px em qualquer zoom".
- **Parte do vão que escolhe a divisória** (zoom normal): vão de 200 mm 85%, 300 mm 74%, 450 mm 48%.
- **Faixa de 20 a 22 px incoerente:** arma o arrasto da divisória, mas o soltar escolhe a porta. O 🗑 apaga a porta.
- **Editor por vãos:** ~9 px (46 mm). Correto, mas diferente do 2D.

## 4. Seleção azul intensa (não dá para medir "intenso", pergunta)
- **Candidatos mais fortes:**
  - módulo no 3D/Tamanho com 40% de azul (:3641);
  - divisórias do editor por vãos #2b3fd6 a .35 mesmo sem seleção (:10461);
  - botão `.sel` sólido;
  - tamponamento #4a90e2 a .9.
- **Correção:** baixar só a opacidade do que o Adauto indicar, mantendo o #2f6be0.

## 6. Imprecisão ao digitar (erros comprovados)
| Campo | Digitado → gravado | Situação |
|---|---|---|
| w/h/d | 605,5 → 605,5, peça 605 (décimo vira folga) | correto |
| w/h/d depois de redesenhar o painel | campo mostra 606 (`Math.round` em :1605/1606), peça 605 | erro |
| w 3 / h 3 / d 3 / d 99999 | 100 / 290 / 100 / 1200 em silêncio (`sanM` :520), campo mostra o digitado | erro |
| w 99999 | 6000, depois 2365 (`rowFix` encaixa na parede) | erro |
| Do chão 900 no GR / 2000 no balcão | 200 / 1780 (`roomClamp` :3023, liberado no módulo escolhido) | erro, ou regra (pergunta) |
| W/H 50 | 500 em silêncio | erro |
| Da esquerda, W normal, somas | exato | correto |
- **Teclado físico (Windows/iPad):** "1.200" é lido como 1,2 e vira 100 (`ex()` :3496). Risco, só por leitura do código.

## 7. "Réguas" que não aumentam ou diminuem certo
- **Erro comprovado: seta de trás (ek) do 3D com zona morta de 120 mm** (:3871). Depois de "tampou até o fundo", empurrar para dentro não diminui (aéreo: −60 e −120 não mudam; balcão nunca diminui).
- **Erro menor: `regN` (camadas 1–3):** 4 grava 4 e gera 3; 0 gera 2. Sem aviso.
- **Risco: limites diferentes:** `tbL` / `tlAdj` / `trAdj` digitados não têm limite (`tbL` 2000 → peça de 3000 passando da parede), mas o arrasto no 2D limita (:1276).
- **Correto:** setas ef/et/eb, ajuste fino ±1 e ±0,5, digitar no painel do 3D, régua do engrosso cava.

## Proposta de padronização (para aprovação)
1. **Uma constante única `SEL`, em px de tela, em 2D, editor por vãos e 3D:**
   - toque: até 10 px de movimento;
   - 2 toques: até 350 ms do 1º soltar ao 2º encostar, e 40 px;
   - alça da divisória: 12 px em qualquer zoom, nunca mais que ¼ do vão;
   - se o 1º toque foi no vão, o 2º perto da divisória conta como 2 toques no vão.
2. **Abas:** a mesma ordem nos dois editores, e o bloco "Por dentro" sempre depois dos botões de frente.
3. **Medida fora do limite:** avisar e mostrar no campo o que ficou gravado. O campo mostra o décimo.
4. **Seta de trás do 3D:** só grudar na parede ao puxar em direção a ela.
5. **Cada correção:** teste que falha antes, bateria completa e sondas da família.

## Perguntas para o Adauto
1. Qual menu muda de lugar (abas do painel, menu de 2 toques no vão ou painéis do 3D), e em que aparelho? Qual ordem de abas vale?
2. O que é "fechar o vão": o menu some, o vão deixa de ficar escolhido ou outra coisa? Em qual móvel?
3. Um dedo num módulo ainda não escolhido deve só escolher, sem mover?
4. Tocar na divisória de outro módulo: escolhe só o módulo, ou o módulo e a divisória?
5. Servem os números 10 px, 350 ms e alça de 12 px?
6. Qual azul está forte demais? Um print resolve.
7. Limites 100–6000 / 100–1200: continuam? Valor fora do limite é aceito com aviso, ou recusado com aviso?
8. "Do chão" que passa do teto: encaixa ou mantém e avisa? E o `rowFix`: pode reduzir a largura digitada ou empurrar vizinhos?
9. O campo deve mostrar o décimo?
10. "Réguas": as setas do 3D, as réguas do tamponamento ou a régua do engrosso?
