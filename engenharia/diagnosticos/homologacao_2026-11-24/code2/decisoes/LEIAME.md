# Decisões do Adauto de 24/11: antes e depois

"Antes" = ponta de `claude/fechamento-code1`. "Depois" = este ramo.

- `1_forno_antes/depois.png`: 🗑 no corte do forno.
  - Antes: "Só a peça saiu", e o forno ficava sem o nicho.
  - Depois: o motivo aparece e nada muda. Tocar de novo em 4 s tira o conjunto.
- `2_rodape_antes/depois.png`: 🗑 no rodapé.
  - Antes: só a peça saía e o resto do pedestal ficava.
  - Depois: o rodapé é desmarcado no módulo.
- `4_dobradica_corte_antes_depois.png`, `5_perfilG_corte_antes_depois.png`, `6_aereo_fita_corte_antes_depois.png`, `8_facetado_corte_antes_depois.png`: corte medido, desenhado a partir das caixas reais do 3D do editor.
  - Em vermelho: o puxador ou a dobradiça dentro de outra peça, com a medida.
  - Depois: 0 em todos. O item 6 já era 0 antes.

Roteiros em `roteiros/`. `sec.js` tira as caixas do editor e `render.py` desenha.
