# Item 39 · REGUA-PAREDE (Claude 4, 28/11)
ANTES = 154591e0 (esquerda) × DEPOIS = correção (direita). Embaixo de cada quadro: o que foi feito (negrito) e o que o projeto guardou (azul).
- `r39_1366.jpg`, `r39_430.jpg`: parede direita.
- `r39e_1366.jpg`: parede esquerda (guardada virada).

| Quadro | ANTES | DEPOIS |
|---|---|---|
| 1 a 3. Balcão criado no 2D da parede do lado, 3D e volta | tamponamento e réguas no mesmo lugar no 2D e no 3D | igual (nada mudou) |
| 4. Botão "Fundo" do módulo com o 2D na parede do lado | não move, continua na parede | vai pro fundo e sai da vista |

Teste: `testREGUAPAREDE_ParedeEscolhidaNaVistaDoLadoEOlharAsParedesNaoMuda`. Varredura completa no `HISTORICO_ERROS.md`.
