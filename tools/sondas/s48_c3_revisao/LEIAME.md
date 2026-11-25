# s48 · revisão independente do Code 3 (25/11)

Sondas usadas na revisão do 4fb5695a (faixa do espelho LED) e das correções do Code 1 (`claude/fechamento-code1`).
Não mudam o editor nem os testes da bateria. Rodam pelo `tools/bateria_editor.py` com `--swift <arquivo>`.

- `faixa_antigo_novo_ligada_desligada.swift`: o teste da faixa com a amostra antiga (1 px) e a nova (ponto + vizinhos a 1 px), com o LED ligado e desligado (`a.led.on=0`). Rodar também com o editor com o defeito ESP-FAIXA de volta (trocar `(b.gola||b.espLed==='fr'||b.espLed==='frs')?GOL` por `b.gola?GOL`).
- `faixa_radial_430.swift`: distância (px) do ponto amostrado até a faixa acesa e varredura radial em 360° (direções sem nenhum pixel aceso).
- `a31_projeto_antigo_outra_seta.swift`: balcão com o rodapé esticado do jeito de antes (`po` no rodapé); puxar a seta de OUTRA peça do módulo.
- `b26_mutacao_peca_solta.swift`: tira a prateleira/tamponamento do lugar (+1000 mm) pra provar que o teste do B26 acusa peça solta.
- `roda.sh <nome> <pasta do editor> <swift> <porta http> <porta cdp> <janela|-> [regex]`.

## 2ª rodada (pedido do Chefe, 25/11 tarde)
- `toque430_cena_funda.swift` / `toque430_cena_funda_print.js`: planta a 430 com o guarda-roupa no fundo à direita, paredes de 3000 a 8000 e parede do lado funda; conta os pontos do módulo que pegam o toque e os que caem nos botões 🔓🗑🧮.
- `a31_limites_regua_e_rodape.swift`: seta da régua espaçadora (±300) e do rodapé (+600) em todo o catálogo; mostra a altura das gavetas e se o rodapé entra em outra peça.
- `arrasto_perto_do_canto.swift`: arrastar o vizinho pro canto L e pro canto cego, com a parede normal e encolhida.
- `lib_sem_sobreposicao_igual_a_base.swift`: 4 projetos dos backups de referência + catálogo inteiro + cozinhas de 4 módulos; compara estado, peças, corte, orçamento e DXF entre dois editores (rodar nos dois e comparar a saída).
- `lib_vizinhos_cancelar_arrastar.swift`: Cancelar (catálogo e medida), Colocar mesmo assim e arrastar o novo depois.
- `print.py <pasta do editor> <js> <saida.png> <LxAxD> <porta>`: print real da tela (MOB=0 para a emulação da bateria, MOB=1 celular).
- `prints/`: TOQUE-430 antes × depois na cena funda (430, celular), A31 gaveteiro antes × rodapé puxado (1366), liberdade: pergunta × colocado (430).
