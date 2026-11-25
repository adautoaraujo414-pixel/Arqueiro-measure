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

# Biblioteca de espelhos orgânicos e LED jateado (Code 2, 23/11/2026, com as 4 fotos de referência do Adauto)

## Modelos (＋ Criar · Espelho na parede)
| # | Modelo | formato | LED |
|---|---|---|---|
| 1 | Redondo LED jateado 70 | red (700 × 700) | frontal jateado 4000 K |
| 2 | Oval LED jateado 60 × 90 | red | frontal jateado |
| 3 | Retangular faixa jateada 80 × 60 | ret | frontal jateado |
| 4 | Arco com LED 60 × 100 | arco | traseiro 3000 K |
| 5 | Orgânico vertical irregular 60 × 100 | orgv | — |
| 6 | Orgânico horizontal irregular 120 × 70 | orgh | — |
| 7 | Orgânico gota 60 × 80 | gota | — |
| 8 | Orgânico ondulado 60 × 100 | onda | — |
| 9 | Orgânico LED traseiro 120 × 70 | orgh | traseiro |
| 10 | Orgânico LED frontal jateado 60 × 80 | gota | frontal jateado |
| 11 | Orgânico LED frontal e traseiro 60 × 100 | orgv | os dois |
| 12 | Orgânico sem LED 60 × 100 | orgv | — |

Os 4 de antes continuam iguais.

## Geometria
- **Formato orgânico:** curva fechada de verdade, uma spline Catmull-Rom pelos pontos de controle, ajustada pra largura × altura exatas.
  - Triangulação real (orelhas): o desenho em leque de antes servia só pra forma convexa.
  - Cada formato pronto foi conferido em n − 2 triângulos, também girado.
- **Recuo:** borda, bisotê, faixa e halo recuam ou afastam pela normal da curva.
- **Giro livre:** campo de graus (o do Code 1).
- **Editar pontos:** "✎ Editar pontos no 2D" mostra uma alça por ponto de controle. Arrastar muda a curva e o espelho vira "Personalizado" (f.pts). Funciona girado e passa pelo desfazer.
- **Salvar formato:** "💾 Salvar formato" guarda os pontos no aparelho e aparece em "Meus formatos" de qualquer espelho. O projeto leva os pontos de cada espelho, então abre igual em outro aparelho.

## LED
- **Frontal jateado:** faixa translúcida iluminada (anel entre dois contornos recuados: distância da borda e largura, em mm). O centro continua espelhado, com o reflexo real.
  - Brilho suave dos dois lados da faixa, sem ponto de luz.
  - Desligado: faixa jateada fosca.
- **Traseiro:** o espelho afasta da parede (afastamento, padrão 30 mm). O halo na parede tem largura 60 + 2,6 × afastamento, em 5 anéis contínuos que somem pra fora.
- **Cor:** 3000 K quente, 4000 K neutra, 6000 K fria. Intensidade de 10 a 100 % e liga/desliga.
- **Faixa que não cabe** (distância + largura ≥ meia medida menor − 20): aviso, nada muda.

## Orçamento (vidraçaria; preço em branco no Ajustes, como os outros do espelho)
- **Jateamento (m²):** área real da faixa.
- **Fita LED (m):** frontal no meio da faixa; traseiro 30 mm pra dentro da borda.
- **Fonte (un):** 1 por espelho com LED.
- Somam-se ao vidro, à lapidação/bisotê e à moldura (Code 1).
- Nada vai pro plano de corte de MDF.

## DXF da vidraçaria ("⬇ DXF do espelho")
R12, em mm, um espelho ao lado do outro, com estas camadas:
- **ESPELHO_CORTE:** contorno real.
- **ESPELHO_JATEADO:** as duas bordas da faixa.
- **ESPELHO_LED:** caminho da fita.

## Desempenho
- A curva tem cerca de 96 pontos e a triangulação é feita só quando o 3D é refeito.
- Faixa e halo são camadas finas, sem textura.
- O vidro entra no reflexo real e na qualidade automática da parte anterior.

## Testado
- Teste: `testEspelhosOrganicosELedJateadoBibliotecaQuadroOrcamentoEDxf`.
- Capturas: `organico_*_3d.png`, `redondo_led_jateado_3d.png`, `organicos_2d_com_pontos.png`.

## Não coberto (aplicável depois, sem regra inventada)
- Espelho em cima de painel ou ripado: segue a regra de posição de sempre do item de parede (o Code 1 audita).
- Espelho em móvel livre: não existe hoje.
- Medição em aparelho.
