# Lateral inteira junto às gavetas (armário inferior de cozinha) — diagnóstico e proposta (17/11), nada implementado

**Decisão do Adauto (17/11):** no armário inferior de cozinha, a divisória ao lado do vão de gavetas vira lateral inteira, igual às outras laterais (mesmo rebaixo em cima). Base e travessas em duas peças. Módulos já existentes: avisar e pedir decisão. Guarda-roupa não muda.

## Conta atual (versão pública), exemplo real
`Balcão porta + gavetas` do catálogo: 900 × 820 × 560, MDF 15, travessa 70, folga 15, rodapé 100, base, moldura 30, 1 divisória no meio (porta | 3 gavetas). Coordenadas em mm, y = 0 em cima.

| Peça | Corte | Posição (x, y) | Tamanho no desenho |
|---|---|---|---|
| Base inferior | 900 × 560 | 0, 705 | 900 × 15 (inteiriça, **sob** as laterais) |
| Lateral esquerda / direita | 690 × 560 | 0 e 885, 15 | 15 × 690 (do topo da base até 15 do alto), rebaixo 15 × 70 na frente em cima |
| Travessa frontal | 900 × 70 | 0, 15 | 900 × 70 (entra no rebaixo das duas laterais) |
| **Divisória 1** | **620 × 560** | 443, 85 | 15 × 620 (de cima da base até **debaixo** da travessa) |

- A divisória é 70 mm mais baixa que as laterais (690 − 620 = 70, a altura da travessa). Não tem rebaixo.
- A travessa passa inteira por cima dela (900 mm).
- As gavetas usam o vão entre a lateral e a divisória. A espessura da peça do meio é a mesma (15), então **a largura do vão e as gavetas não mudam** com a troca.

## O que muda com a regra (proposta)
- **Divisória 1 → "Lateral do meio 1":** 690 × 560, mesma altura, mesma profundidade e mesmo rebaixo 15 × 70 das laterais. No 3D, o rebaixo é desenhado igual ao das laterais.
- **Travessa frontal em 2 peças**, cada uma entrando no rebaixo do seu lado.
- **Base inferior em 2 peças.**

## Dúvidas que mudam a fabricação (preciso da sua resposta antes de implementar)
1. **Base em 2 peças:** hoje as laterais ficam **em cima** da base (base inteiriça 900 por baixo). Se a lateral do meio também fica em cima da base (690, igual às outras), a base pode continuar inteira. Para a base sair em 2 peças, a lateral do meio teria que descer até o chão do rodapé, passando entre as 2 bases. Ela ficaria 705 mm, 15 mais alta que as outras. Qual vale?
   - **A)** Lateral do meio 690 em cima da base inteira (só a travessa em 2 peças).
   - **B)** Lateral do meio 705 até embaixo, base em 2 peças (ex.: 435 + 450 = 900 − 15).
2. **Travessa em 2 peças:** o rebaixo da lateral do meio tem 15 mm. Como as duas travessas se encontram?
   - **A)** Cada travessa entra metade do rebaixo, 7,5 mm. No exemplo, cada uma fica com 450 mm.
   - **B)** Uma travessa cobre o rebaixo inteiro e a outra encosta. No exemplo, ficam 457 + 443 ou 465 + 435, conforme o encaixe.
   - **C)** Outra forma de montar.
3. **Mais de uma divisória junto a gavetas** (ex.: `Balcão 2 portas + 8 gavetas`, gaveteiro nas duas pontas, 2 divisórias): as duas viram laterais inteiras, e a travessa e a base saem em 3 peças?
4. **Divisória com recuo** (`m.dr`) ou **montante** junto às gavetas: também vira lateral inteira, com a profundidade toda?
5. **Nome da peça:** "Lateral do meio 1" serve? Na lista ela entra em "Laterais".

## Família (§11.2)
- **Vale:** módulo de baixo (`!m.sup`), não é canto, não é editor por vãos (`isRg`), altura < 1500, ambiente cozinha ou gourmet, com vão de gavetas (`k:'drawers'`) de um dos lados da divisória.
- **Não vale:** guarda-roupa, torre, aéreo, editor por vãos.

## Projetos que já existem
- Nada muda sozinho. O módulo guarda a escolha (`m.latMeio`, por divisória).
  - **Módulo novo do catálogo:** já nasce com a regra.
  - **Módulo antigo:** o painel mostra o aviso "esta divisória está junto das gavetas · usar lateral inteira?" com o botão. Só muda se a pessoa tocar.

## Pontos do código que dependem do nome "Divisória"
Tudo isso precisa acompanhar a peça nova, conferido nos testes:
- o apagar (🗑 `^Divisória (\d+)$` tira a divisória do `m.div`);
- a junta do fundo grande;
- a fita;
- a categoria da lista;
- o 3D (rebaixo pelo nome);
- o `semLE`/`semLD`/`latPiso`;
- os ajustes por peça (`pk`);
- a base contínua entre módulos (`Base inferior#1`).

## Aviso de profundidades diferentes entre vizinhos
- Hoje não existe esse aviso (a guarda GEO-AVISA só olha a parede).
- **Proposta:** módulos de baixo encostados (folga ≤ 1 mm) com profundidade diferente mostram um aviso com os dois módulos, as duas profundidades e a diferença. Nada muda sozinho.

## Testes previstos
Numéricos, com as medidas do exemplo e de `Balcão 2 portas + 4 gavetas` e `+ 8 gavetas`:
- 3D, lista e corte iguais;
- vão e gavetas iguais aos de antes;
- módulo antigo não muda;
- aviso e botão;
- salvar e reabrir, desfazer;
- guarda-roupa e torre sem mudança;
- aviso de profundidade.

## Respostas do Adauto (17/11) e o que foi feito
- **Base:** "A lateral acompanha as outras, que é por cima da base, com o rebaixo do frontal." → lateral do meio 690, em cima da base, com o rebaixo 15 × 70. **A base continua inteira.**
- **Travessa (pergunta 2) e duas divisórias (pergunta 3): puladas.** Ficou o que menos muda, como **pendente de confirmação**:
  - a travessa continua uma peça só (900), passando pelo rebaixo, como já passa nas laterais de fora;
  - toda divisória sem recuo que encosta num vão de gavetas vira lateral do meio. No gaveteiro nas duas pontas, são as 2.
- **Divisória com recuo ou montante (pergunta 4):** sem resposta. Não mudam (continuam divisória/montante).
- **Nome:** "Lateral do meio N". Entra em "Laterais" na lista. No corte, junta com as laterais de mesma medida (3 × 690 × 560).
- **Implementado (LAT-MEIO, branch `claude/arquemestre-lateral-inteira`):**
  - **Módulo novo** de baixo da cozinha/gourmet nasce com `m.latMeio=1`.
  - **Módulo antigo** (sem a marca) não muda: o painel avisa e oferece "Usar lateral inteira" ou "Manter divisória". As duas escolhas passam pelo desfazer.
  - **Código que dependia do nome "Divisória", acompanhado:**
    - rebaixo no 3D;
    - caixa do 3D;
    - junta do fundo grande;
    - 🗑 (tirar a lateral do meio tira a divisória do `m.div`, como antes).
  - **Aviso de profundidade diferente:** aparece no painel (Estrutura e Divisões) para módulos de baixo encostados. Nada muda.
- **Catálogo (sonda, todos os 142 modelos na cozinha):**
  - Mudaram só os modelos com divisória junto de gavetas: balcões com gavetas, e também escrivaninhas, racks, aparador, gabinete e penteadeira **quando postos num ambiente cozinha**.
  - Em todos, a única diferença é Divisória → Lateral do meio. O resto das peças é idêntico.
  - Nos ambientes deles (quarto, sala, banho) a regra não vale.

## Respostas do Adauto (23/11) e o que foi feito (Code 2, ramo `claude/juncao4-batente`)
- **Base da implementação:** LAT-MEIO do Code 1 (`3991175`) reaplicada sobre a candidata (o código mudou desde 17/11; nada da regra dele foi alterado).
- **Pergunta 2 → A:** a travessa frontal sai em uma peça por vão. Cada travessa ocupa 7,5 mm do rebaixo de 15 da lateral do meio (o corte é no meio da lateral).
  - Peça em mm inteiro (REGRAS 13/11): quando o meio cai em ,5, a peça perde o décimo e o meio milímetro vira folga **no encontro** (nunca na lateral de fora).
  - Ex.: Balcão porta + gavetas 900: 450 + 450. Balcão 2 portas + 8 gavetas 1600: 407 + 785 + 407 (folga 0,5 em cada encontro).
  - Laterais por fora (lateral quadrada, sem rebaixo): cada travessa termina na face da lateral do meio, igual às laterais de fora (427 + 427 no 900).
- **Pergunta 3 → sim:** 2 laterais do meio = 3 travessas. Só em módulo com a lateral do meio (`m.latMeio===1`); nenhum outro módulo é dividido.
- **Pergunta 4 → sim:**
  - Montante junto das gavetas vira lateral do meio com a profundidade toda (a corrediça precisa de apoio no comprimento; com gaveta de um lado nenhuma prateleira passa por trás, então o "passa por trás" não se perde).
  - Divisória com recuo traseiro junto das gavetas vira lateral do meio e **mantém o recuo** (profundidade − recuo, também no 3D). Se a gaveta for mais funda que a lateral com recuo, o painel avisa com as medidas e nada muda.
- **Conflitos apresentados (nada inventado):**
  1. **Base em 3 peças (pergunta 3) × resposta de 17/11 (pergunta 1: "a lateral acompanha as outras, que é por cima da base").** Com a lateral do meio por cima da base, a base inteira é o que a sustenta; cortar a base embaixo dela deixaria a lateral apoiada numa emenda. **Mantive a base inteira** e peço a confirmação: base em 3 peças só se a lateral do meio descer até o rodapé (705 em vez de 690, a opção B de 17/11).
  2. **Colisões que já existem hoje (com ou sem a lateral do meio):** no Balcão porta + gavetas, com 5 ou 6 gavetas a caixa da gaveta de cima entra até 34 mm na travessa; com 7 ou 8 (o app passa a cava) a régua do cava de cima entra até 24 mm na travessa. A junção 4 não cria nenhuma colisão nova (teste compara com e sem). Corrigir isso muda a posição das gavetas de projetos que já existem, então fica para decisão.
- **Validação nos exemplos reais do catálogo (12 modelos com gaveta ao lado da divisória):** soma das travessas = travessa de antes, 0 sobreposição no 3D, peças = corte = DXF em todos.
- **Testes:** `testJuncao4TravessaEmPecasRebaixoMeioAMeioRecuoMontanteSemSobreposicao` (2, 4, 6 e 8 gavetas; 1 e 2 laterais do meio; largura, altura e profundidade; recuo, recuo grande, montante, laterais por fora; salvar e reabrir; projeto antigo com divisória e com montante exatamente como foi salvo; guarda-roupa sem mudança) e `testLateralDoMeioJuntoDasGavetasNoInferiorDaCozinha` (do Code 1, expectativas atualizadas).

## Correção do Adauto (23/11, depois): a base não precisa ficar inteira — o marceneiro escolhe
- Feito em `a9049cd`: por módulo, Inteira (padrão, como sempre) · Dividida (uma peça por vão) · Personalizada (escolhe em quais divisórias).
- Base dividida: a divisória ou lateral do meio desce a espessura da base (690 → 705; divisória comum 620 → 635) e as peças encostam nela.
  Balcão 2 portas + 8 gavetas: 400 + 770 + 400 (+ 2 × 15) = 1600.
- Não divide onde ficaria sem apoio (montante, recuo traseiro, pés, base contínua com o vizinho); o quadro mostra o motivo.
- O conflito 1 acima deixa de existir: a base inteira continua sendo o padrão e a dividida é escolha.

## Colisões das gavetas (autorizado 23/11)
- Feito em `b07085a`: o "+" de gavetas não aceita quantidade que colide; módulo que já está assim avisa e oferece o máximo que cabe (com desfazer).
- Não há medida a "corrigir" sem inventar regra: com cava, a frente de cima cobre a travessa e não sobra altura atrás para a caixa.
