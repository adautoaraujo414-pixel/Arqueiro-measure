# ArquePlanta (base guardada)

Aqui fica guardado o módulo **Planta da casa** que foi feito dentro do editor do Arquemestre e depois tirado de lá a pedido do Adauto (02/11/2026), pra virar um app separado chamado **ArquePlanta**.

O que já funciona nesta base (dentro do `app/src/main/assets/editor.html` deste ramo):
- planta da nota (ferramenta Cômodo) → paredes de verdade, portas, janelas, nomes e pé-direito;
- planta editável (paredes, ▭ cômodo, portas, janelas, pontos elétricos/iluminação/hidráulicos, móveis, escada, medidas, 🔗 juntar pontas), cotas automáticas;
- medidas por parede e por face, áreas, volume, quadro de áreas, quantitativos com perdas;
- 3D com texturas, Etapas da Construção, telhado, andar dentro, setinhas pra aumentar e subir paredes, ✏ nova parede no 3D;
- documentos em PDF (planta cotada, layout, elétrica, iluminação, hidráulica, elevações, cortes, quadro de áreas, quantitativos).

Fontes em `fonte/`: `glob7.js` (modelo e geometria), `glob8.js` (desenho, PDF), `glob9.js` (tela da planta), `v3g.js` (3D), `fix107a.py` (como entra no editor) e os testes.
Este ramo não dispara o CI (só `main` e `feature/**` disparam).
