# Varredura visual — publicado (3f1c3a58, iOS 3.0.13) × claude/pre-final (436ac8f2)

Chromium sem janela, 1366×900 (mouse) e 430×900 (toque). Roteiros JS rodados no editor real (`shot.py` do Claude 3).

| Print | Esquerda → direita | O que se vê |
|---|---|---|
| 1_corte_* | publicado ×1 · pre-final ×1 · pre-final ×4 · ×6 | Mesmo plano, 24 peças. No pre-final o texto encolhe para caber dentro da peça (mediana 10 px contra 12 a 1366). O zoom é novo e deixa as peças baixas e estreitas legíveis: o rodapé de 450×100 passa de 5 px de texto no ×1 para 21 px no ×4 e 32 px no ×6, a 1366. |
| 2_juncao_* | publicado · pre-final com a barra · depois do botão | Arrastar até encostar: no publicado e no pre-final nada muda sozinho. No pre-final aparece "Ajustar tamponamento da junção", e o botão dá x600 tl1 tr0, x1500 tl0 tr1. |
| 3_fileira_* | publicado · pre-final com a barra · depois do botão | Tirar o tamponamento de um módulo: no publicado os outros se moviam sozinhos (905, 1805). No pre-final ficam em 920 e 1840 até tocar em "Fechar as folgas da fileira", que leva a 905 e 1805. |
| 4_pedra_* | publicado · pre-final com a barra · depois do botão | Gaveteiro +50: no publicado a pedra ia sozinha de 1535 para 1585. No pre-final fica em 1535 até tocar em "Ajustar pedra ao balcão", que leva a 1585. |
| 5_mais_opcoes_* | Internos: publicado · pre-final · Divisões no quarto: publicado · pre-final | Nada sumiu. Cabideiro e sapateira do balcão foram para "Mais opções (outros componentes)". Forno e porta-tempero, que antes sumiam fora da cozinha, agora aparecem em "Mais opções (fora da cozinha)". |
| 6_mm_cm_* | publicado (mm) · pre-final 2D em cm · lista em cm | Painel, cabeçalhos, cotas dos módulos e peças da lista convertidos. **Defeito:** as cotas da pedra (820, 865), o rótulo da cuba ("fundo 100 · frente 106") e a tabela de ferragens por módulo ("Base 1 900 × 820 × 560") continuam em mm, sem unidade. |
| 7_enfeite_* | publicado · pre-final módulo novo · pre-final depois de "Pôr o enfeite" | Portas abertas no 3D. No publicado as roupas apareciam sozinhas. Módulo novo vem sem. "Pôr o enfeite" volta às mesmas 31 caixas. |

"Ajustar vizinhos ao novo módulo" (claude/reg12-criacao, Code 2) ainda não foi empurrado, então não está aqui.

## Legibilidade do plano no iPad: claude/pre-final-proximo 47324009 (c624f1c6 + c1682687) × 436ac8f2

- **Uma lógica só, sem margem somada.** O c624f1c6 mexe só na fonte: o `cpMet` sem medida devolve 1,16/0,30 e não guarda; com medida, fica igual ao de antes. O c1682687 é o consumidor: as etiquetas das sobras usam `max(1, AS)` no lugar do 1 fixo e `max(1,3, AS+DS)` no lugar de 1,3. É troca, não soma.
- **Defeito (c1682687, só com a métrica do iPad 1,16/0,30):** `testPlanoDeCorteLegivel…TerceiroTerco` e `…TerceiroTercoEmCm` falham a 1366 e a 430. O 436ac8f2, com a mesma métrica, passa. A régua espaçadora 815×30 **#2** do "Guarda-roupa de sala 2 vãos (cabideiro + prateleiras)", chapa 1, perde o callout ("#17 815×30"): fica sem identificação. A sobra "161" continua. Com a métrica normal, os 6 testes passam nos dois.
- 9_corte_ipad_gr4vaos_chapa2_*: Guarda-roupa 4 vãos, chapa 2, peça 641 × 125, métrica do iPad. Antes e depois iguais pixel a pixel: o c1682687 só mexe nas sobras.

## Varredura visual em 47324009 (pre-final-proximo)
- Junção, fileira, pedra, Mais opções, enfeite e corte ×4 têm a mesma saída do 436ac8f2 (roteiros idênticos a 430).
- 10_vizinhos_*: publicado · pre-final com a barra · depois do botão. Cria um gaveteiro ao lado do balcão. No publicado, o vizinho perdia o tamponamento direito sozinho (tr1 → tr0). Agora fica tr1 e aparece "Ajustar vizinhos ao novo módulo"; o botão dá tr0, igual ao publicado. **Risco:** até tocar no botão, o gaveteiro novo (x905) fica sobre o tamponamento direito do balcão, com "2 avisos" e a marca vermelha 905.
- 11_cm_*: 436ac8f2 × 47324009 em cm. UNIDADE-2 corrigiu: pedra 82 / 86,5, cuba "fundo 10 · frente 10,6", ferragens "90 × 82 × 56 cm". Em mm, o texto do 2D e da lista é igual ao do 436ac8f2.
