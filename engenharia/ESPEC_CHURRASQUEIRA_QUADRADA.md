# Especificação: churrasqueira quadrada de embutir (alvenaria com moldura)

**Status (16/11/2026, 15:15):** **nada implementado e nada testado.**
- O pedido chegou às 14:34, no meio da auditoria. O trabalho foi pausado às 14:54 a pedido do Adauto.
- Este documento junta o que foi pedido, o que a referência mostra, o que já existe no app e o que precisa ser perguntado antes de implementar.

## 0. Fontes e limites deste documento
- **Pedido:** mensagem do Adauto de 16/11 às 14:34, "ARQUEMESTRE — NOVO MODELO DE CHURRASQUEIRA QUADRADA".
  - **O texto original não está mais acessível nesta sessão.** O histórico foi resumido e a busca nas conversas não achou o texto.
  - Os itens da seção 3 vêm do meu resumo desse texto, feito na hora. **A única frase guardada literalmente** é: "As medidas não informadas devem ser solicitadas ou configuradas pelo usuário, sem inventar dimensões de fabricação."
  - **Recomendação:** pedir ao Adauto que reenvie o texto original e conferir esta especificação contra ele antes de implementar.
- **Referência:** foto enviada junto, nos anexos da conversa de 16/11 às 14:34 (arquivo `4bde29b0-image.png`, 1206 × 2622).
  - Não foi copiada pro repositório (repositório público; ver `REFERENCIAS.md`).
  - Foi analisada em 16/11 às 15:15 (seção 1).

## 1. O que a foto de referência mostra

**Visível (pode virar especificação):**
1. **Coluna:**
   - corpo único do piso até o alto da foto, encostada na parede, ao lado dos armários da cozinha;
   - os armários são outro móvel e não fazem parte da churrasqueira.
2. **Revestimento da coluna:**
   - placas grandes, efeito mármore escuro (cinza-amarronzado) com veios finos claros;
   - a face da frente é contínua, sem rejunte aparente perto da boca.
3. **Boca (abertura):** um vão aberto na frente, mais ou menos no terço de baixo da coluna.
4. **Moldura em volta da boca:**
   - feita do mesmo revestimento;
   - **4 peças com cantos em 45° (meia-esquadria)**: a linha diagonal aparece nos 4 cantos;
   - largura igual nos 4 lados;
   - há uma linha de sombra no contorno de fora, o que **parece** indicar que ela sobressai da face da coluna.
5. **Dentro da boca:**
   - caixa de metal (inox) com fundo, laterais e teto metálicos;
   - grelha embaixo;
   - uma barra horizontal atravessando a boca mais ou menos no meio da altura;
   - dois pequenos itens redondos nos cantos de baixo, de função não confirmada (pegador da grelha ou rodízio).
6. A moldura ocupa quase toda a largura da coluna: sobra só uma faixa estreita de revestimento de cada lado.

**Proporções aproximadas, medidas em pixels na foto.** Foto com perspectiva e **sem escala**: **não são medidas e não podem virar padrão** (`CLAUDE.md` 2: "Não presumir medida de imagem sem escala").

| Relação | Valor aproximado na foto |
|---|---|
| Largura de fora da moldura ÷ largura da coluna | ≈ 0,97 |
| Largura da boca ÷ largura da coluna | ≈ 0,76 |
| Altura da boca ÷ largura da boca | ≈ 0,76 (**a boca da foto é mais larga que alta**) |
| Largura da faixa da moldura ÷ largura da coluna | ≈ 0,10 a 0,11 |

**Não visível, então não pode ser inventado:**
- chaminé ou duto (pode estar dentro da coluna, mas não aparece);
- coifa;
- porta ou vidro;
- bancada na boca;
- vão de lenha embaixo;
- laterais da coluna (o lado esquerdo está encostado na janela);
- medida da saliência da moldura;
- se a face da moldura é reta ou chanfrada;
- o rejunte entre as placas.

**Dúvidas a perguntar ao Adauto:**
- O nome é "quadrada", mas a boca da foto é retangular (mais larga que alta).
- A moldura é saliente? Quanto?

## 2. O que já existe no app (manter igual: "Keep existing models")
Tudo em `app/src/main/assets/editor.html`. Linhas de `0aa152c`.

**Biblioteca:**
- `window.CHUR` (linha ~7599) tem 19 modelos com medida de fabricante: pré-moldadas, de canto, com coifa, de embutir a carvão, parrilla, a gás, elétrica e coifas.
- `APM.churrasqueira` (linha ~7619).
- A categoria do catálogo é `cchur`, "🔥 Churrasqueiras" (linha ~7692).

**Tipos (`chKind`)** (linha ~7625): `alv`, `alvv`, `coifa`, `canto`, `emb`, `parrilla`, `gasbox`, `vidro`, `gas`, `ele`, `hood`.

**Revestimento (`CHREV`/`chRev`)** (linha ~7623), cor de fora:
- tijolinho;
- concreto;
- porcelanato claro;
- mármore cinza;
- preto;
- inox.

**Onde a churrasqueira é guardada:**
- É um item de `S.fr` (a mesma lista dos eletros), com `t:'churrasqueira'`.
- Campos usados: `nome`, `k`, `x`, `y`, `b`, `w`, `h`, `d`, `rev`, `wall`, `id`.

**Funções:**
- **3D:** `chur3(f,z0)` (linha ~5761). As `alv*` são um bloco com base de lenha, bancada de granito na boca, caixa de fogo, coifa e chaminé. As de embutir são uma caixa de inox com grelha.
- **2D:** `churSvg(...)` (linha ~7644).
- **Posição inicial:** `apAdd` embrulhado (linha ~7687). As `alv*` vão pro chão (`b=0`); as de embutir vão pra altura da bancada.
- **Colisão:** `frFree`/`frPad`. A churrasqueira guarda 45 mm de folga (`frPad(f)=45`, linha ~8166). `frSolid` cuida do sólido.
- **Parede e afastamento:** `frWall3` (linha ~5367).
- **Toque acende a brasa:** `one3` embrulhado, `OVL`, `CHG` (fumaça).

**Plano de corte:** não achei referência a `S.fr` dentro de `cutGroups` nem de `cutLines`. Pelo que vi, a churrasqueira de hoje **não entra no plano de corte**.
- O orçamento (Valores) **não foi verificado**.

**Testes da bateria que já usam churrasqueira** (não podem quebrar):
- `testTomadasRegistroChurrasqueiraBotaoDoLEDETVComLogo`
- `testModoPessoaNaoAtravessaMesaCafeteiraPedrasReaisESetinhasDaPedra`
- `testGestosNoEletro2ToquesMudaDeLugar3ToquesConfiguracoes`
- `testEletroPelo3DComLupaEmCimaDaPedraMesaEParedeDoL`
- `testCarneAssandoComFumacaEBotaoDoLEDLigaEDesliga`
- `testGavetasAjustesNoToqueECatalogoOrganizado`
- `testMontarDoZeroNoFimDeCadaCategoriaCriaESalvaQuartoSemCozinha`

## 3. O que foi pedido (do resumo do pedido de 14:34)
1. **Modelo novo:** "Churrasqueira Quadrada de Embutir — Alvenaria/Moldura".
2. **Paramétrico:**
   - largura externa (inicial 900);
   - altura total;
   - profundidade;
   - largura e altura da abertura;
   - espessura da moldura;
   - altura da abertura em relação ao piso;
   - espessura das paredes;
   - recuo da abertura;
   - altura da base.
3. **A abertura é um vão aberto, não um bloco sólido.**
4. **Moldura com cortes em 45°.**
5. **Peças independentes, cada uma com material configurável:** laterais internas, fundo, base e topo.
6. **2D e 3D.**
7. **Modelos na biblioteca:** quadrada, retangular, embutir com moldura, revestimento personalizado. **Os modelos atuais continuam.**
8. **Plano de corte:**
   - separa alvenaria, revestimento, pedra, metal e MDF;
   - **alvenaria nunca vira MDF.**
9. Não pode empurrar nem apagar os móveis do lado.
10. **Testes pedidos:** redimensionar, posição, abertura, moldura, salvar e reabrir, vizinhos.
11. **"As medidas não informadas devem ser solicitadas ou configuradas pelo usuário, sem inventar dimensões de fabricação."**

## 4. Componentes do modelo (só os da referência e do pedido)

| Componente | De onde vem | Material (configurável) | Entra no plano de corte de MDF? |
|---|---|---|---|
| Corpo da coluna (alvenaria) | foto + pedido | alvenaria | **Não, nunca** |
| Revestimento da face (e das laterais, se tiver) | foto | revestimento (porcelanato/pedra) | Não. Vai como revestimento (m² ou placas, a definir) |
| Moldura, 4 peças em 45° | foto + pedido | igual ao revestimento ou outro | Não. Vai como revestimento ou pedra (a definir) |
| Abertura (vão) | foto + pedido | — (é vazio) | — |
| Laterais internas, fundo, base (piso da boca) e topo (teto da boca) | pedido | cada uma o seu (a foto mostra metal) | Não. Vai como metal, alvenaria ou o material escolhido |
| Grelha, e barra horizontal no meio da boca | foto | metal | Não |

**Não entram** (não estão na foto nem no pedido):
- chaminé;
- coifa;
- porta;
- vidro;
- bancada;
- vão de lenha;
- iluminação;
- tomada.

Se o Adauto quiser algum desses, é pedido novo.

## 5. Geometria e medidas editáveis
Medidas em mm, inteiras.
- **Padrões:** só a largura externa tem padrão informado (900). **Todos os outros padrões precisam vir do Adauto.** Enquanto não vierem, o modelo pede as medidas na hora de criar.
- **Limites:** todos a definir com o Adauto.

| Parâmetro | Padrão | Observação |
|---|---|---|
| Largura externa `W` | **900** (Adauto) | — |
| Altura total `H` | **perguntar** | Na foto a coluna sobe até o alto. "Até o teto" (pé-direito do ambiente) seria uma **opção a confirmar** |
| Profundidade `D` | **perguntar** | — |
| Largura da abertura `Wa` | **perguntar** | — |
| Altura da abertura `Ha` | **perguntar** | "Quadrada" → `Wa = Ha`? A foto é retangular: **perguntar** |
| Altura da abertura em relação ao piso `Ba` | **perguntar** | — |
| Largura da faixa da moldura `Lm` | **perguntar** | "espessura da moldura" no pedido: confirmar se é a largura da faixa ou o quanto sobressai |
| Saliência da moldura `Sm` | **perguntar** | Na foto parece saliente |
| Espessura das paredes `Ep` | **perguntar** | Paredes de alvenaria em volta da boca |
| Recuo da abertura `Ra` | **perguntar** | Confirmar se é a profundidade da boca ou o quanto a caixa fica pra dentro da face |
| Altura da base `Hb` | **perguntar** | Confirmar se é o mesmo que `Ba` ou outra coisa (rodapé ou base da coluna) |

**Relações que valem para qualquer medida** (geometria; não são medidas inventadas):
- Moldura de fora:
  - largura `Wa + 2·Lm`;
  - altura `Ha + 2·Lm`.
- As 4 peças da moldura têm corte em 45° nas duas pontas:
  - **de cima e de baixo:** `Wa + 2·Lm` no lado de fora e `Wa` no lado de dentro;
  - **laterais:** `Ha + 2·Lm` no lado de fora e `Ha` no lado de dentro.
- **A moldura tem que caber na face:** `Wa + 2·Lm ≤ W` e `Ba − Lm ≥ 0`, e `Ba + Ha + Lm ≤ H`.
- **A abertura cabe no corpo:** `Wa ≤ W − 2·Ep`. A profundidade da boca não passa de `D` menos o fundo (relação exata a confirmar com `Ep` e `Ra`).
- **Medida que não cabe:** o app avisa e **não corrige sozinho** os outros valores (regra "o app nunca muda nada sozinho").

## 6. Posicionamento
1. A coluna fica no piso (`b = 0`) e encostada na parede escolhida (`wall` f/e/d), como as `alv*` de hoje.
2. É sólida pra colisão: nada entra nela e ela não entra em nada. A boca é um vão de verdade, mas não é passagem pra outros objetos.
3. **Não empurra nem apaga os vizinhos.** Se não couber, ela avisa e fica onde estava, ou não é criada. A folga de 45 mm das churrasqueiras de hoje (`frPad`) **só vale pra ela se o Adauto confirmar**.
4. Mudar `W`, `H` ou `D` mantém fixo o ponto de referência combinado (a confirmar: canto de baixo à esquerda, rente à parede).
5. Mudar a abertura ou a moldura não mexe na posição da coluna nem dos vizinhos.
6. Arrastar no 2D e no 3D segue as mesmas regras dos eletros de hoje (`frFree`).

## 7. Materiais e texturas
- **Cada parte tem o seu material** (pedido): corpo, revestimento, moldura, laterais internas, fundo, base e topo da boca, grelha.
- **Revestimento:** usar a lista de revestimentos já existente (`CHREV`). Mais "revestimento personalizado" (pedido), que é escolher cor ou foto de um catálogo.
  - **O que entra no catálogo do revestimento personalizado:** perguntar (porcelanato, pedra, catálogo do app?).
- **A textura segue a geometria real:**
  - a foto ou textura do revestimento é aplicada nas faces da coluna e da moldura sem esticar;
  - nas 4 peças da moldura, a emenda em 45° fica visível como linha (como na foto);
  - nada de peça a mais só pra enfeitar (`CLAUDE.md` 11.5).
- **Interior:** metal (inox) como na foto, por padrão **se o Adauto confirmar**. Senão, o material escolhido.
- **Alvenaria** nunca é mostrada nem calculada como MDF.

## 8. 2D e 3D
- **2D, vista de frente da parede:**
  - contorno da coluna;
  - moldura com as 4 linhas de 45° nos cantos;
  - abertura;
  - contorno da caixa de dentro;
  - cotas de `W`, `H`, `Wa`, `Ha`, `Ba` e `Lm`.
- **2D, vista de cima:** a área ocupada `W × D` e a moldura saliente, se tiver.
- **2D, parede do lado:** igual às outras peças da parede lateral.
- **3D:**
  - coluna com o vão de verdade (dá pra ver o fundo e as laterais de dentro);
  - moldura em 4 peças com o corte em 45°;
  - grelha e barra como na foto.
  - O 2D e o 3D tiram as medidas do **mesmo** objeto. Nada de geometria só no 3D.
- **Toque:**
  - selecionar a churrasqueira abre o quadro com as medidas e os materiais;
  - o "acender a brasa" de hoje (`OVL`) pode valer pra ela **se o Adauto quiser**; não está na referência.

## 9. Persistência
- Fica em `S.fr` com `t:'churrasqueira'` e um tipo novo (ex.: `k:'colmold'`; nome a definir), com todos os parâmetros da seção 5 e os materiais da seção 7.
- **Salvar e reabrir** devolve exatamente as mesmas medidas, materiais e posição.
- **Projeto antigo** com as churrasqueiras de hoje abre igual: nenhum campo novo muda os modelos antigos.
- **Duplicar, desfazer e refazer** levam todos os campos.

## 10. Plano de corte, lista e orçamento
1. Nada desse modelo entra no plano de corte de MDF.
2. **Lista de materiais separada por tipo:**
   - alvenaria;
   - revestimento (área em m² ou placas: perguntar);
   - pedra;
   - metal;
   - MDF, só se o Adauto incluir alguma peça de MDF.
3. Moldura com as 4 peças e o corte em 45° indicado (medidas de fora e de dentro).
4. **Orçamento:** perguntar se entra e como.

## 11. Erros confirmados
- **Nenhum.** Nada foi implementado nem testado. Também não auditei as churrasqueiras atuais.
- **Risco identificado:** as `alv*` de hoje desenham bancada de granito, vão de lenha, coifa e chaminé. Copiar o `chur3` delas pro modelo novo traria componentes que **não estão** na referência. O modelo novo precisa de desenho próprio.

## 12. Testes necessários
Entram na bateria (`ios/ArquemestreTests/EditorWebKitTests.swift`). Rodam no Chromium, no Windows e no iOS.
1. **Criar pelo catálogo:**
   - `W = 900`;
   - as outras medidas pedidas ao usuário (sem inventar);
   - os modelos antigos continuam na lista.
2. **Redimensionar `W`, `H`, `D`:**
   - o ponto de referência fica;
   - a moldura e a abertura seguem as relações da seção 5;
   - medida que não cabe avisa e não muda nada.
3. **Abertura:**
   - mudar `Wa`, `Ha`, `Ba` muda só a boca e a moldura;
   - o vão é vazio no 3D (o fundo aparece).
4. **Moldura:**
   - 4 peças com 45°;
   - medidas de fora e de dentro certas;
   - mudar `Lm` não mexe na abertura.
5. **Materiais:** trocar cada material muda só aquela parte.
6. **Vizinhos:**
   - com balcão e torre encostados, criar, crescer e arrastar não empurra nem apaga ninguém;
   - quando não cabe, avisa.
7. **Plano de corte:**
   - nenhuma peça da churrasqueira no corte de MDF;
   - a lista separa os tipos.
8. **Salvar, fechar e reabrir:** tudo igual. **Projeto antigo** com churrasqueira pré-moldada continua igual.
9. **2D e 3D:** as medidas do 2D batem com o 3D.
10. Os 7 testes de churrasqueira da seção 2 continuam passando.

## 13. Critérios de aceitação
- [ ] O modelo da biblioteca bate com a foto: coluna, revestimento, moldura de 4 peças em 45° e boca aberta com caixa de metal e grelha. **Nenhum componente que não esteja na foto ou no pedido.**
- [ ] Nenhuma medida de fabricação inventada; só a largura de 900 vem pronta.
- [ ] O 2D e o 3D mostram a mesma geometria.
- [ ] Alvenaria e revestimento fora do plano de corte de MDF.
- [ ] Vizinhos intactos.
- [ ] Salvar e reabrir igual.
- [ ] Modelos antigos iguais.
- [ ] Bateria completa passando.
- [ ] Comparação visual com a referência mostrada ao Adauto, lado a lado (`CLAUDE.md` 2).
- [ ] Nada publicado sem o "sim" dele.

## 14. Perguntas pro Adauto antes de implementar
1. Reenviar o texto do pedido de 14:34, porque o original se perdeu no resumo.
2. "Quadrada": boca quadrada (`Wa = Ha`) ou como na foto (mais larga que alta)?
3. Padrões de `H`, `D`, `Wa`, `Ha`, `Ba`, `Lm`, `Ep`, `Ra`, `Hb`.
4. O que é exatamente:
   - "recuo da abertura";
   - "altura da base";
   - "espessura da moldura" (largura da faixa ou saliência).
5. A moldura é saliente? Quanto? A face é reta ou chanfrada?
6. O interior é inox por padrão? Tem a barra do meio e os pegadores da grelha?
7. Altura total "até o teto" como opção?
8. Revestimento personalizado: de qual catálogo?
9. Como o revestimento, a pedra e o metal entram na lista e no orçamento (m², placas, unidade)?
10. A folga de 45 mm das churrasqueiras de hoje vale pra essa?
11. Acender a brasa vale pra ela?
