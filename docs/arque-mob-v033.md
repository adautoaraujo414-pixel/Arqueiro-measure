# Arque Mob 0.33 — Pontas e encontros sem lupa

A mudança corrige diretamente a observação feita na foto da v0.32.

**Mudanças estritamente solicitadas:**
- Não mostrar mais círculos, lupa, alça quadrada ou marcador de origem nas pontas das linhas (mesmo em desenhos antigos). Limpa a vista do L, T, retângulos e outras peças.
- Manter setas **apenas se a opção de seta estiver selecionada** para aquela linha. Sem setas por padrão, e as cotas continuam editáveis.
- No modo **Selecionar**, uma região invisível sobre as extremidades permite arrastar/ajustar a linha sem poluir a folha.
- No modo **Linha**, toque, arraste e solte para iniciar um segmento sobre a ponta ou o meio de outra linha. Em **Fundir ligado**, dividir o trecho alcançado pelo novo encontro em T; em **Fundir desligado**, apenas encostar.
- A opção antiga de lupa nas extremidades foi removida das configurações. Zoom continua pelos dois dedos e botões de +/-.
- Mantêm-se tamanho menor das cotas, A4, fotos, folhas, peças retangulares, calculadora, corte e Caneta Mágica. 3D permanece oculto.

**Validação:** testes com Chromium headless em 1180×780, 820×1180 e 390×844 simularam a seleção de uma linha, os controles invisíveis e o arraste começando no meio de um segmento para formar um T; em todas as resoluções, a linha se dividiu em duas faces conectadas e a nova linha foi criada, sem erros de JavaScript. Teste unitário também verifica que Fundir desligado não divide o segmento.
**Limite:** ainda falta teste físico no Samsung Tab S9/S Pen e conferência das cotas reais antes de produção.
