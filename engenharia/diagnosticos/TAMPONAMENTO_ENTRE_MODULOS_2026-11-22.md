# Diagnóstico — "réguas internas" na junta Balcão aberto × Balcão forno embutido (22/11/2026)

Relato do Adauto com foto (iPhone, 17:07): 4 faixas verticais na junta entre um Balcão aberto (sem porta) e o Balcão forno embutido.
Feito pelo Claude Code 2. **Nada alterado** — a lógica do tamponamento é do Code 1. Possivelmente o mesmo TAMP-ENGROSSO (16/11, "não reproduzido").
Reprodução: `engenharia/diagnosticos/tamponamento-reproducao-2026-11-22.js`.

## As 4 faixas (tamponamento de 30 no lado esquerdo do forno, módulo aberto em x=5..605)
| Faixa | Peça | Esp. | 3D (x) | Lista / corte |
|---|---|---|---|---|
| 1 | Lateral direita do aberto | 15 | 590..605 | 690 × 560 MDF 15 |
| 2 | Face do tamponamento esquerdo do forno | 15 | 605..620 (prof. toda) | 720 × 585 MDF 15 |
| 3 | Régua de 80 da frente do tamponamento | 15 | 620..635 (z 511..591) | 720 × 80 (+ a de trás, + 2 de 425 × 80) |
| 4 | Lateral esquerda do forno | 15 | 635..650 | 690 × 560 MDF 15 |
Não é régua interna inventada: é o tamponamento de 30 (face + réguas de 80, regra de 15/11) **entre dois módulos**, visível porque o aberto não tem porta.
Peças reais: entram na lista, no plano de corte e no orçamento (+0,5412 m² na cor, +2,61 m de fita larga, ≈ R$ 77,93 no forno com os preços de teste).

## Caminhos de reprodução (o tamponamento automático deveria sair quando o vizinho encosta)
| Caminho | Resultado |
|---|---|
| Catálogo: aberto e depois forno | correto — forno só com o automático da direita; nada entre os dois |
| Catálogo: forno encostado na parede direita e depois aberto | correto — o automático se ajusta; nada entre os dois |
| **Arraste 2D (dedo/mouse)**: forno sozinho (automático nos 2 lados), aberto arrastado até encostar na esquerda dele | **DEFEITO** — o `tl` automático do forno fica (`tl=true, tlAuto=1`); o aberto para encostado no tamponamento; tamponamento entre os módulos |
| **Arraste 3D** (soltar da parede e encaixar no fundo ao lado do forno) | **DEFEITO** — encaixa a 10 mm, com o automático da esquerda do forno **e** o automático da direita do aberto: 2 tamponamentos entre os módulos |
Causa provável: a regra do tamponamento automático (`tlAuto/trAuto`, perto da L203) é refeita na criação pelo catálogo, mas não depois do arraste 2D (`PLD`/`gapJoinDir`) nem do encaixe do 3D (`__mv3.encaixa`).
Regra a respeitar na correção: só o tamponamento **automático** sai; o ligado na mão fica ("Módulo não age sozinho: não tira tamponamento…"); medida de projeto antigo não muda sozinha.

## Outros pontos
- 35 mm não existe como opção (o `sanM` aceita 15/25/30; o resto vira 30). O Adauto citou "30 a 35 mm".
- Não há exportação DXF no app.
