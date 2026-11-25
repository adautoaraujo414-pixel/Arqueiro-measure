# s47 — zoom no plano de corte e textos legíveis (24/11/2026)

Sem servidor: os editores abrem por file://. Variáveis: `EDITOR` (pasta com app/src/main/assets), `PONTE` (ponte.js da bateria,
o texto PONTE de tools/bateria_editor.py), `PROJ` (projetos: `{nome: {st}}`, como os da s45/s46), `SAIDA` (pasta dos PNGs).

- `confere_textos.js`: a conta geométrica (mesma do teste `testPlanoDeCorteLegivel…`). Caixa de cada texto do plano (getBBox + transformação real)
  contra linhas de fita, contorno da peça, outros textos e a chapa; ordem (texto depois da fita); peça sem identificação.
- `confere_catalogo.js <pasta> <largura> <altura> [zoom]`: todos os projetos de PROJ, abre o plano e confere (com zoom opcional em cada chapa).
- `confere_pdf.js <pasta> <saida.pdf> <projeto>`: mídia de impressão (o PDF do app imprime o mesmo #cutbody), confere e gera o PDF.
- `toque_e_mouse_reais.js`: toque real (CDP Input.dispatchTouchEvent: pinça, arrasto, 2 toques, toque longo) a 430×900 e mouse real (roda, arrasto,
  roda fora da chapa) a 1366; sheetPlan comparado; PNGs.

Resultado (claude/fundo-15mm), 141 projetos (139 da s45 + backup rico), 538 chapas, 4152 peças, ~17.500 textos:
antes 10.156 textos em cima de fita/contorno (1366); depois 0 em 1366, 430, com zoom ×4 e ×6, e 0 no PDF. Toda peça identificada
(as que não cabem nada legível dentro ganham etiqueta "#n medida" na sobra mais perto, com linha). Plano de corte inteiro igual (s46, 15 campos).
