# Arque Mob v0.28 — caderno 2D com foto e folhas

## Alterações a pedido
- Ferramentas no cabeçalho, organizadas em Linha, Selecionar, Mão livre, Nota e Mover foto. Cada ferramenta possui uma segunda faixa com opções próprias de cor, espessura, pontas, 90°, Fundir ou edição.
- Linha nova apenas tocando/pressionando, arrastando e soltando; clique isolado no vazio **não** cria segmento. Arrastar a partir de um vértice de linha selecionada também permite criar uma nova linha sem deslocar a existente. Para mover vértice, escolher Selecionar.
- Ao concluir a linha a medida de prévia em cm permanece na própria linha; tocar no segmento permite editar e confirmar o valor medido. As cotas seguem as linhas (em cima das horizontais e do lado interno das verticais), mantendo o texto horizontal.
- O valor em cm calculado pela escala é **estimado, não medido**: não pode alimentar automaticamente a inferência de medidas de fechamento. Para cálculos de fechamento são usadas apenas medidas manualmente informadas ou calculadas a partir de medidas suficientes.
- Inserir foto por seletor de arquivos, reduzida e convertida em JPEG para salvamento local. Trabalhar na mesma folha sobre a foto, com opacidade, tamanho e modo de deslocamento.
- Múltiplas folhas, abas, opção de renomear e excluir uma folha. Cada folha preserva linhas, mão livre, notas, foto, zoom e deslocamento; o estado legado de folha única migra automaticamente.
- Ajuste de espessura de linhas e escrita livre (desde 0,7), cores, setas nas pontas, modo Fundir/Encostar, cantos 90°, mão livre, notas, calculadora e desfazer/refazer preservados. Código e modelos 3D continuam armazenados, porém ocultos na UI.

## Testes
- Navegador Chromium em 1180×780, 820×1180 e 390×844: nenhum erro de JavaScript, clique isolado, gesto de arrastar, medida mantida, alteração da espessura, duas folhas independentes, foto importada, rabisco e nota sobre a foto.
- Recuperação simulada de projeto com duas folhas, mantendo linhas e notas; migração de estado antigo com apenas uma folha.
- Teste de sintaxe, funções críticas e integração Android em GitHub Actions.

## Limitações
A foto serve como referência visual; não realiza medição calibrada. Fotos JPEG são compactadas e o espaço local é limitado. A precisão de produção e a S Pen no Samsung Tab S9 **ainda não foram testadas fisicamente**. Confira medidas e faça backup dos projetos antes de instalar. O APK é uma compilação de teste e não deve orientar corte CNC sem conferência.
