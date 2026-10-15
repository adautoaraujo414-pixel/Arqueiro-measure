# Arque Mob 0.34 — escrita livre, destaque e Caneta Mágica X

Atualização isolada sobre a v0.33 do Arque Measure, mantendo o 3D oculto e todas as funções existentes.

- **Mão livre:** uma vez escolhida, a caneta escreve imediatamente sobre o papel, inclusive sobre linhas, notas e peças existentes. Não exige selecionar ou desagrupar. Cada traço fica registrado como tinta, com cor e espessura.
- **Destaque:** ferramenta separada, com cor (amarelo por padrão), largura própria e traço translúcido, preservando a escrita por baixo. Essa ferramenta também escreve continuamente sem exigir seleção.
- **Caneta Mágica:** duas diagonais opostas, suficientemente retas, que realmente se cruzem dentro da região central formam um X; ele apaga a anotação/traço/linha/nota ou peça na posição cruzada. Não apaga fotos inteiras; respeita ordem de especificidade e mantém desfazer.
- Riscos paralelos continuam funcionando como o pedido anterior de dividir vãos, pedindo apenas a espessura antes de efetuar a divisão. O rastro mágico desaparece sem ficar anotado na folha.
- Ferramentas existentes (cotas, A4, foto, notas, múltiplas folhas, borracha, calculadora, corte, Fundir/Encostar e zoom com dois dedos) preservadas.

**Validação:** testes de navegador Chromium em 1180×780, 820×1180 e 390×844, incluindo escrita sobre linha e nota, destaque, desfazer/refazer, gesto X, risco paralelo para dividir em 3 vãos, edição da espessura e exclusão de nota preservando peça. Teste JS dedicado executado no GitHub Actions, além da compilação Android.

**Limite:** o X depende de dois riscos diagonais nítidos; não é reconhecimento geral de caligrafia/gestos do StarNote. O teste com S Pen física do Samsung Tab S9 e a conferência dos cálculos de fabricação seguem pendentes. Faça backup dos projetos antes de atualizar APK de teste.
