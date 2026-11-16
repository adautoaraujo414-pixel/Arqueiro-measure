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

## A levantar (não verificado)
- Pressionar e segurar.
- Gestos simultâneos (pinça + arrasto).
- Caneta (Apple Pencil e S Pen).
- Navegação entre paredes.
- Desfazer e refazer.
- Sensibilidade do arrasto e do zoom no 3D.
- Conflitos entre o duplo toque de vários lugares (vão, peça, cuba, parede).
