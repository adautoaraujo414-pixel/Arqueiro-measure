# Pacote de evidências do Claude 4 (ETAPA 2) para o relatório final

Cada prancha mostra o **ANTES** (c38c9ba, 27/11, antes de todas estas entregas) à esquerda e o **DEPOIS** (e98e8187, HEAD do `claude/etapa2-claude4`) à direita.
- `*_1366.jpg`: tela de notebook (1366 × 768).
- `*_430.jpg`: tela de celular (430 × 900, densidade 2).

Para os gestos, cada linha é um quadro da sequência. Embaixo de cada quadro:
- **negrito**: o que foi feito;
- **azul**: o que o app guardou depois (medida, posição, aba, aviso), lido do projeto, não do desenho.

Como foi feito: toque real pelo Chromium (CDP `Input.dispatchTouchEvent`), caneta real (`Input.dispatchMouseEvent` com `pointerType: 'pen'`) e teclas do teclado numérico tocadas na tela. Nenhuma linha do app mudou para tirar os prints.

| Item | Prancha | O que mostra |
|---|---|---|
| 10 · ordem da aba Divisões | `i10_*` | ANTES: "Dividir por igual" antes de todas as seções. DEPOIS: depois das 4 seções (vão, prateleiras, divisórias, avançado). |
| 11 · modelos de porta | `i11_*` | Miniaturas em "Modelo da porta": 4 → 7. "Estilos de porta" vem antes do puxador. |
| 12 · ordem dos tamponamentos | `i12_*` | O inferior agora vem antes do superior. |
| 19 · composição da frente | `i19_*` | Seção nova na aba Estrutura (módulo de baixo). Um toque em "2 gavetas + 1 gavetão" dá frentes de 164, 164 e 328 no partsOf (1:1:2). |
| 25 · toque na janela | `i25_*` | ANTES: tremida de 5 px movia a janela (x 1400 → 1425 a 1366, → 1470 a 430); 1 e 2 toques não faziam nada. DEPOIS: tremida = toque (seleciona, não move); 2 toques abrem o quadro da janela na aba Ambiente; arrasto depois de selecionar move. |
| 26 · 2 toques na peça | `i26_*` | ANTES: lateral não abria nada; rodapé e base abriam só o acesso rápido. DEPOIS: lateral, rodapé e base abrem a edição deles ("✏️ Editando: …"); no meio do vão continua o acesso rápido. |
| 27 · tremida na alça e na divisória | `i27_*` | ANTES: tremida de 5 px na bolinha mudava a largura (1200 → 1190 a 1366, → 1180 a 430) e na divisória mudava a posição (0,667 → 0,673 / 0,682). DEPOIS: nada muda. O arrasto de verdade continua igual nos dois. |
| 34 (editor) · botão calado | `i34_*` | O − com a parede inteira na tela: ANTES calado, DEPOIS avisa. O ⌂: veja o achado abaixo. |
| 36 · palma com caneta | `i36_*` | ANTES: com a caneta encostada, a palma arrastava o módulo (x 600 → 350 a 1366, → 35 a 430) e abria o acesso rápido. DEPOIS: módulo parado e nada abre; caneta solta, o dedo volta a funcionar. |
| 37 · teclado numérico | `i37_*` | ANTES: sem Cancelar; espessura 123 virava 50 sem aviso. DEPOIS: "✕ Cancelar" devolve o valor (1200); espessura 123 é recusada com aviso ("o máximo é 50 mm. Nada foi alterado") e fica 15. |
| 38 · distância digitada | `i38_*` | ANTES: digitar 250 na distância moveu o módulo sozinho (x 1900 → 1810). DEPOIS: nada muda até escolher Mover, Redimensionar ou Cancelar. |
| 41 · alça da geladeira e alça sobre o vizinho | `i41_*` | ANTES: arrasto começando 10 px ao lado da bolinha não pegava; toque parado na bolinha sobre o vizinho ficava no escolhido. DEPOIS: o arrasto pega (largura muda) e o toque parado escolhe o vizinho. |
| PLANTA-TAMP | `planta_*` | Tamponamentos na planta: ANTES 0 (o 3D tem 2), DEPOIS 2 = 3D. |
| LATMEIO-PAREDE | `latmeio_*` | Balcão novo na parede direita: ANTES "Divisória 1", diferente do fundo; DEPOIS "Lateral do meio 1", igual ao fundo. Projeto antigo não muda sozinho: aviso com prévia e o botão "Igualar ao fundo". |
| ESTAVEL | `estavel_*` | Abrir o teclado, OK e tocar de novo no mesmo campo: funciona igual nos dois (sem regressão). A correção do ESTAVEL é da estabilidade com página sem foco do sistema; a prova está nas execuções repetidas da bateria registradas no `HISTORICO_ERROS.md` (PesDeMetal 20/20 isolado, Parte1b/ParteB 10/10). |

## Achado ao fazer o pacote (risco identificado, sem correção; para decisão)
- **⌂ a 1366 × 768:** a barra de baixo (−, +, ⌂) fica abaixo da dobra da tela. Para tocar no ⌂ é preciso rolar a página, e com a página rolada o ⌂ não avisa nada e não volta a página ao começo (prancha `i34_1366`, quadros 3 e 4).
  - Isso acontece no ANTES e no DEPOIS.
  - A 430 o aviso aparece.
