# Estrutura do Módulo (2D) — novas ferramentas

Pedido do Adauto (22/11/2026), feito pelo Claude Code 2 no ramo `feature/pecas-livres-2d`.
Seção nova "Estrutura do Módulo" no topo da aba Estrutura do módulo (antes de Dimensões).
Código: bloco `ESTRUTURA DO MÓDULO` no fim de `app/src/main/assets/editor.html` (objeto `window.EM`).

## Regras comuns
- Nada aqui mexe em outro móvel nem muda medida de fabricação sozinho (CLAUDE.md §4).
- Sólido: a conferência usa as caixas do próprio 3D (`__build()`/`__boxes()`), só as opacas e sem a pedra.
  Encostar (contato exato, tolerância 0,5 mm) pode; entrar não. Só conta o que **passou** a cruzar com a mudança
  (o que já se tocava antes não é desta mudança). Bloqueado → volta como estava e avisa em quê.
- Desfazer/refazer pelo `snap()` de sempre.

## 1. Afastamento da parede (ESTRUTURA-AFASTA)
- Campo "Afastamento da parede (cm)", padrão 0,0, aceita decimal (vírgula ou ponto) e conta da calculadora.
- Guardado em mm inteiro no módulo, no campo que já existia `m.zo` (lido por `zoOf` no 2D/planta, 3D, pedra e corte).
  Projeto antigo sem `m.zo` continua no padrão (Ajustes › `zoDef` / painel ripado atrás) — nada é gravado ao abrir.
- Vale nas paredes do fundo, esquerda e direita. Não aparece em módulo de canto nem em móvel livre (no meio da sala).
- Bloqueia se alguma peça do módulo passar a entrar em outra. Ex.: o rodapé/base corrida do 1º módulo passa embaixo do
  vizinho — afastar só o 1º faria a peça entrar no vizinho, então não deixa.
- O aviso antigo "Afastado da parede: N mm … Usar o padrão" virou este campo (o botão "Usar o padrão" continua).
- Teste: `testEstruturaAfastamentoDaParedeEmCmSemMudarMedidaENemEntrarNoVizinho`.

## 2. Peças livres em MDF 15 mm (ESTRUTURA-PECA15, ESTRUTURA-REGUA, ESTRUTURA-VAO)
Modelo: lista `m.pl` no próprio módulo (projeto antigo não tem → nada muda). Cada peça:
`{id, n, k, ax, x, y, w, h, z, d}` em mm inteiro, no sistema do módulo: `x` da esquerda do módulo, `y` de cima pra baixo
(igual `partsOf`), `z` da traseira do corpo pra frente (no 3D: z do mundo = afastamento + fundo sobreposto + z).
`ax` é o eixo da espessura 15: `z` de frente · `x` em pé de lado · `y` deitada. A espessura não é editável.
- Entra no fim do `partsOf` (wrapper), com nome "`<tipo> · livre`", `mat:15`, `rpz` (profundidade) e pk "`<nome>#N`"
  (N fixo da peça; apagar outra não muda o N). Com isso 2D, 3D, lista, plano de corte (chapa de 15 separada no projeto de 18),
  fita e orçamento leem a peça sem lógica paralela.
- Cor/fita só pras peças "· livre" (wrappers de `finOf`/`edgeSides`/`edgeMm`): peça de frente, réguas, travessa e fechamentos
  na cor de fora com fita nos 4 lados; prateleira na cor de dentro com fita na frente; lateral de acabamento e fechamento do vão
  na cor de fora com fita na frente.
- Tela: seção Estrutura do Módulo › "＋ Criar Peça 15 mm", "＋ Criar Régua" (Régua vertical, Régua horizontal, Prateleira,
  Travessa, Lateral de acabamento, Fechamento superior, Fechamento inferior) e "⬚ Fechar Vão". Ferramenta ligada → capa
  transparente sobre o desenho (o segurar 2 s do módulo e o toque no vão não abrem por baixo) → segurar 2 s no ponto.
- Onde nasce: Peça 15 mm de frente, encostada na superfície do ponto (porta, fundo…), 300 × 300 ou o que couber.
  Réguas/travessa/fechamentos no plano da frente (rente às portas se ali tem lugar; senão na frente delas), do tamanho do módulo.
  Lateral de acabamento em pé, do fundo até a frente (se bater na porta, só a caixa). Prateleira deitada entre o que estiver dos lados.
- Fechar Vão lista os vãos do módulo: atrás (quando afastado da parede), dos lados até a parede/vizinho (até 60 cm),
  em cima até o teto/módulo de cima e embaixo (suspenso) até o chão/o que estiver embaixo. A peça nasce do tamanho do vão
  e pode ser diminuída (fechamento parcial).
- Editar: tocar na peça seleciona; arrastar move; bordas aumentam/diminuem; campos de medida exata (mm). Ao bater para encostada
  (busca o maior passo que cabe, primeiro no x e depois no y). Sem girar e sem duplicar (pedido).
- Testes: `testEstruturaPeca15SegurarCriaArrastaEncostaEMedidaExata`, `testEstruturaReguasEFecharVaoComCorteFitaOrcamentoESalvar`.

### Interpretações (a confirmar com o Adauto)
- "Peça 15 mm" = placa de frente (espessura na profundidade); as peças em pé/deitadas ficam no "Criar Régua".
- A referência do Promob não chegou nesta sessão: os tipos seguem a lista escrita do pedido.

## 3. Editor 2D multivistas (MULTIVISTAS, pedido de 22/11 "estilo Promob")
Código: bloco `EDITOR 2D MULTIVISTAS` no fim do `editor.html` (`EM.mv*`). Barra compacta "Vista: Frente | Esquerda | Direita | Superior | Posterior | ⌂"
logo acima da barra da parede (o seletor de paredes continua o de sempre, `wvGo`).
- **Frente** = o editor 2D de sempre (nada mudou nele). **Esquerda/Direita/Superior/Posterior** = projeção ortográfica das MESMAS caixas do 3D
  (`__build/__boxes`, que vêm do `partsOf`): nenhuma geometria própria por vista. Desenha do mais longe pro mais perto; pedra a 35 %;
  módulo escolhido com contorno azul tracejado; peça escolhida em laranja com alças e a medida.
- As vistas são relativas à parede escolhida: a parede do lado entra como "parede do fundo" (`toView`), então a mesma conta vale nas 3 paredes.
  Eixos (frente olhando a parede, `fw=-z`): Esquerda `fw=+x`, Direita `fw=-x`, Posterior `fw=+z` (espelhada), Superior `fw=-y` com a parede em cima.
- **Câmera** = só o `viewBox` (mm): arrastar com 1 dedo/mouse, pinça com 2 dedos, rodinha (Ctrl/pinça do trackpad = zoom; rolar do trackpad = anda),
  ⌂ centraliza. Nenhum handler da vista mexe em móvel. Tocar num módulo escolhe ele; tocar numa peça livre escolhe a peça.
- **Criar na vista** (Estrutura do Módulo › Criar Peça 15 mm / Criar Régua, segurar 2 s): o ponto da tela dá 2 coordenadas; a 3ª (profundidade da vista)
  é a do primeiro sólido que o olhar acerta no ponto (a peça nasce encostada nele, do lado de quem olha). De cima sem acertar nada: o piso.
  De lado/de trás sem acertar nada: a face do módulo escolhido. **Orientação da Peça 15 mm = plano da vista** (Frente/Posterior: de frente;
  Esquerda/Direita: em pé de lado; Superior: deitada). As réguas mantêm a orientação do tipo. Sem girar.
- **Módulo ↔ mundo**: `EM.l2w`/`EM.w2l` (mesma conta do 3D: posição na parede, afastamento + fundo sobreposto, paredes do lado). A peça fica no
  `m.pl` do módulo escolhido, em coordenadas do módulo: aparece na Frente, nas outras vistas, no 3D, no corte e no orçamento; a vista não muda medida.
- **Arrastar/esticar na vista**: muda a caixa do mundo nos 2 eixos da tela (a espessura não estica); se bater, para encostada (busca o maior passo
  que cabe; no arrasto primeiro no eixo horizontal da tela e depois no vertical → desliza alinhada na face da outra peça). Medidas exatas no painel.
- Teste: `testMultivistasCameraECriarPecaEmCadaVistaSemMexerMovel`.
