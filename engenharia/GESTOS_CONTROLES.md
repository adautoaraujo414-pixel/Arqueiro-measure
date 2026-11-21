# Gestos e controles (inventário inicial, 16/11/2026)

Regra: **nenhum gesto muda sem pedido do Adauto.** Isso inclui sensibilidade, sentido, câmera e o que cada toque faz.

Este inventário traz só o que foi conferido. As duas primeiras seções são o texto de ajuda que o próprio app mostra. O resto ainda precisa ser levantado no código, uma tela por vez.

## 2D (editor de móveis), conforme a ajuda do app
- Um dedo no módulo move só o módulo. O cenário (parede, pedra, chão) fica parado.
- 2 toques num vão: escolher porta, gaveta, prateleira…
- Dois dedos: zoom.
- Com zoom, um dedo no fundo move a vista.

## 3D (Visão 3D), conforme a ajuda do app
- 1 toque na porta ou gaveta: abre.
- 1 toque no módulo, pedra, eletro, LED ou ilha: abre o quadro de edição.
  - **Conferido no código em 21/11:** no módulo, 1 toque só escolhe (na porta/gaveta abre); o quadro de opções do módulo abre com **3 toques** (`size3`). Pedra, eletro, LED e ilha abrem o quadro com 1 toque.
- 2 toques: edita a peça (bolinhas laranja).
- Eletro:
  - Arrastar com 1 dedo.
  - 2 toques nele e depois 2 toques no lugar novo (pedra, mesa, chão, parede) mudam de lugar.
  - 3 toques abrem as configurações.
- 2 toques na parede: cria porta, vão ou janela ali.
- 2 toques fora da sala: volta a vista.
- Barra de toque: Normal / Módulo 2D / Tamanho.

## Conferidos no código nesta sessão
- **Pedra vista de cima (2D da pedra):** 2 toques na cuba ou no cooktop abrem o menu rápido: ⟳ Girar 90°, 🔁 Trocar, 📏 Medidas e 🗑 Tirar (este com confirmação). (commit e3d68b8)
- **Travar ambiente:** o 🔓/🔒 trava todas as peças. 4 toques numa peça destravam só ela. (conversa de 09/11)
- **Editor por vãos:** 2 toques no vão abrem o menu rápido com as abas do painel. Valem se os toques vierem em até 450 ms e a até 34 px um do outro. **Isso está só na branch `wip/pedidos-61-62`, ainda não aprovado na bateria.**

## Segurar 2 s (Etapa C, Adauto 21/11)
- 2D e Planta: segurar o móvel 2 s parado abre o menu do vão segurado (o mesmo dos 2 toques).
- 3D (pedido de 21/11, menu interativo): abre o menu flutuante do módulo, com o módulo destacado em azul, mesmo segurando numa porta (ela não abre). Opções: girar 90°/−90°/180° (só móvel livre), tirar da parede, vincular à parede, mover livremente (Planta), editar medidas, excluir (com confirmação). Os 3 toques continuam abrindo o quadro de opções.
- Mexer mais que `SEL.mov` (10 px, o mesmo limite do toque) antes dos 2 s: é arrasto, nada muda. Segundo dedo: cancela (pinça).
- Nos 2 s o móvel volta exatamente pro lugar se o dedo tremeu; depois, até soltar, o movimento daquele dedo não leva o móvel nem gira a vista; soltar não conta como toque e o clique seguinte não aperta botão do menu.
- Mouse (Windows): só segurar o botão esquerdo 2 s; clique direito não faz nada.
- Teste: `testSegurarOMovel2SegundosAbreOMenuSemMexerEPreservaToqueEArrasto`.

## Mover no 3D (Etapa C2, Adauto 21/11)
- Menu dos 2 s › "Mover no 3D": barra no alto com a posição em mm (digitável), o estado do ímã e "Pronto". Enquanto ela está aberta, segurar 2 s não abre o menu.
- Livre: 1 dedo no móvel arrasta no chão (mm inteiros), sem entrar em outro móvel. A até 20 mm da parede do fundo ou da direita, de costas pra ela: guia azul; soltar encaixa. Esquerda e canto L: não encaixa (aviso).
- De parede: segure um instante e arraste (como sempre); puxar mais de 20 mm pra fora solta (não na esquerda).
- Ímã: Ajustes › 🧲 Ímã ligado/desligado (guardado).

## A levantar (não verificado)
- Gestos simultâneos (pinça + arrasto).
- Caneta (Apple Pencil e S Pen).
- Navegação entre paredes.
- Desfazer e refazer.
- Sensibilidade do arrasto e do zoom no 3D.
- Conflitos entre o duplo toque de vários lugares (vão, peça, cuba, parede).
