# s48 · revisão independente do Code 3 (25/11)

Sondas usadas na revisão do 4fb5695a (faixa do espelho LED) e das correções do Code 1 (`claude/fechamento-code1`).
Não mudam o editor nem os testes da bateria. Rodam pelo `tools/bateria_editor.py` com `--swift <arquivo>`.

- `faixa_antigo_novo_ligada_desligada.swift`: o teste da faixa com a amostra antiga (1 px) e a nova (ponto + vizinhos a 1 px), com o LED ligado e desligado (`a.led.on=0`). Rodar também com o editor com o defeito ESP-FAIXA de volta (trocar `(b.gola||b.espLed==='fr'||b.espLed==='frs')?GOL` por `b.gola?GOL`).
- `faixa_radial_430.swift`: distância (px) do ponto amostrado até a faixa acesa e varredura radial em 360° (direções sem nenhum pixel aceso).
- `a31_projeto_antigo_outra_seta.swift`: balcão com o rodapé esticado do jeito de antes (`po` no rodapé); puxar a seta de OUTRA peça do módulo.
- `b26_mutacao_peca_solta.swift`: tira a prateleira/tamponamento do lugar (+1000 mm) pra provar que o teste do B26 acusa peça solta.
- `roda.sh <nome> <pasta do editor> <swift> <porta http> <porta cdp> <janela|-> [regex]`.
