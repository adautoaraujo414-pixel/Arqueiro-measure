# Arque Mob v0.31 — Folha A4, Caneta Mágica, centralização e corte

Esta versão mantém o Arque Measure e o código 3D anterior, ainda oculto.

- **Folha A4 fixa**: área de desenho delimitada visualmente; linha, peça e nota não podem ultrapassar as bordas durante criação e movimentação. Zoom com dois dedos sobre a folha e botão de enquadrar.
- **Cotas**: fonte menor por padrão (10); alterar de 7 a 18 nas configurações. Etiqueta horizontal no centro do traço; valores de prévia em tempo real; medidas manuais confirmadas permanecem editáveis.
- **Extremidades**: botões circulares de lupa no lugar das alças quadradas. Em Selecionar, toque curto dá zoom quando opção está ligada; com zoom desligado, arrastar ajusta a ponta.
- **Peças**: três toques rápidos no mesmo retângulo selecionam e centralizam a peça menor com referência aos limites externos da maior, com validação das dimensões.
- **Caneta Mágica**: 3 riscos = 3 vãos, 4 riscos = 4 vãos, com confirmação apenas da espessura do meio antes do desconto e da distribuição igualitária. Risco temporário desaparece. Requer dois ou mais riscos.
- **Borracha**: apaga linhas, notas, desenhos livres, peças e fotos (confirmar fotografia). Desfazer segue disponível.
- **Plano de corte**: dentro da calculadora, cadastrar peça por nome, largura, profundidade e quantidade em cm/mm; itens iguais se agrupam, lista por área decrescente; botão OK cortou muda o grupo para verde, vermelho indica pendente. A lista salva por projeto e ambiente. Há prévia de distribuição por material com refilo e serra configuráveis.
- **Acesso rápido**: ao abrir Arque Mob sem projeto selecionado, pedir apenas nome do cliente, reutilizar ou criar seu projeto Arque Mob e a primeira folha, sem exigir CPF, endereço ou aprovação de produção.

## Testes
Chromium em telas 1180x780, 820x1180, 390x844. Cenário de peça centralizada com três toques, três riscos na Caneta Mágica, borracha e lista cortou; testes estáticos no Actions e APK compilado. 

**Limitações:** a distribuição é estimativa por faixas, não otimização global garantida nem plano CNC; não considera direção de veio e ferragens. As medidas desenhadas são estimadas pela escala, devendo ser conferidas com trena. S Pen do Tab S9 exige teste físico. Backup antes de reinstalar.
