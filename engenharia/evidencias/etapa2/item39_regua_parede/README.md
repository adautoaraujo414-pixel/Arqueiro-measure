# Item 39 · REGUA-PAREDE (Claude 4, 28/11)
ANTES = 154591e0 (esquerda) × DEPOIS = correção REGUA-PAREDE (direita). Embaixo de cada quadro: o que foi feito (negrito) e o que o projeto guardou (azul).
- `r39_1366.jpg`, `r39_430.jpg`: parede direita.
- `r39e_1366.jpg`: parede esquerda (guardada virada).
| Quadro | ANTES | DEPOIS |
|---|---|---|
| 1. Balcão criado com o 2D na parede do lado | tamponamento esquerdo ligado sozinho na ponta do canto ("960 com tamponamento") | sem ele, igual à regra do projeto ("930") |
| 2. 3D | 5 peças do tamponamento esquerdo (tamponamento + réguas de 80) | 0 |
| 4. Botão "Fundo" do módulo com o 2D na parede do lado | não move, continua na parede | vai pro fundo e sai da vista |
Teste: `testREGUAPAREDE_PecasIguaisEmToda2DE3DEParedeEscolhidaNaVistaDoLado`.
