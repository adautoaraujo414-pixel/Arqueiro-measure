# Espelhos com reflexo real (Code 2, 23/11/2026)

Pedido do Adauto: espelhos com aparência de espelho real, sem pesar o app. Base: `claude/espelhos-d33` (ESP-FORMAS, ESP-VAO e LED-LIVRE do Code 1).

## Como funciona
- **Reflexo planar de verdade:** cada plano de espelho desenha a cena refletida numa textura (câmera refletida pelo plano do espelho). O vidro mostra essa textura na posição da tela. Muda com a posição e o ângulo da câmera, e com móveis, paredes e piso.
  - Espelhos no mesmo plano dividem o mesmo reflexo.
  - O que está atrás do espelho é cortado (a parede onde ele está não aparece).
  - Espelho não entra no reflexo de outro (sem recursão).
  - No reflexo entram a parede da frente e o teto do ambiente, que o 3D normal não desenha (a câmera fica fora da sala). Sem isso, o espelho refletia o fundo escuro da tela.
- **Acabamentos:** prata neutro (0,92), bronze quente (0,76/0,65/0,53), fumê escuro (0,41).
  - Bisotê e lapidação: a faixa da borda reflete deslocada e mais clara, como um chanfro.
  - Moldura com veio de madeira, na profundidade de sempre.
- **Desempenho:**
  - textura reutilizada (uma por plano, criada uma vez);
  - resolução reduzida;
  - só refaz quando a câmera ou a cena mudam (câmera parada: nada refeito);
  - limite de espelhos simultâneos (os maiores na tela primeiro);
  - espelho visto por trás ou fora da tela não é calculado.
- **Qualidade** (botão "🪞 Espelhos" no ⋯ Mais do 3D; preferência do aparelho, não vai pro projeto):
  - **Automático:** celular/tablet 2 espelhos e meia resolução; computador 3 espelhos e 75%. Mede o tempo de quadro de verdade enquanto a pessoa mexe e baixa sozinho (1 espelho, até 41% da resolução, reflexo atualizado um quadro sim, um não).
  - **Equilibrado:** 2 espelhos e meia resolução.
  - **Alto:** 4 espelhos e resolução cheia.
- **Preservado:**
  - formatos, giro, acabamentos, bordas, molduras, medidas, preços, 2D, orçamento de vidro, porta de correr com espelho, espelho no vão e LED;
  - dados do projeto (nada novo é salvo);
  - Acabamento realista ligado: o espelho continua como antes;
  - sem WebGL: como antes.

## Medido (Chromium + SwiftShader, GPU emulada na CPU; NÃO é medida de aparelho)
Cozinha com 5 módulos e 2 espelhos, câmera girando, mediana de 30 quadros:

| | ms/quadro |
|---|---|
| sem espelho | 48 |
| automático (adaptou: 1 espelho) | 59 |
| equilibrado | 72 |
| alto | 106 |
| câmera parada (reflexo reaproveitado) | 64 |

- Memória JS: 16–17 MB, igual.
- Textura por plano: largura × altura × 4 bytes + profundidade 2 bytes. Ex.: 949 × 530 ≈ 3 MB.

## Não medido (precisa de aparelho)
FPS, temperatura e memória de vídeo no Samsung Tab S9 FE, iPhone e iPad. Fica para a homologação do Code 1 com builds de teste.

## Limites conhecidos
- Espelho girado em ângulo livre (fora do eixo da parede) e espelho deitado: ficam com o desenho anterior (sem reflexo planar).
- Com o Acabamento realista ligado: sem reflexo planar.
- Resolução reduzida: o contorno do reflexo pode serrilhar um pouco (no Alto some).

## Capturas
Mesma cena e mesma câmera, antes (`99860057`) e depois:
- `prata_antes/depois.png`
- `bronze_antes/depois.png`
- `fume_antes/depois.png`
- `fundo_e_lateral.png`
