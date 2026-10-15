# Arque Mob v0.35 — folha inteligente e fluxo de marcenaria

Versão de testes em ramo separado. Não altera `main` nem reativa a interface 3D.

## Melhorias implementadas nesta etapa
1. **Interação de caneta e dedo:** nas opções de Mão livre/Destaque existe botão optativo “S Pen: dedo move”. Ligado, apenas S Pen/caneta ou mouse desenham; um dedo desloca e dois dedos fazem zoom. Desligado, dedo e caneta escrevem.
2. **Medidas:** quando uma ponta conectada é movimentada ou o comprimento é digitado manualmente, as cotas das linhas vizinhas são recalculadas como ESTIMATIVAS, sem fingir uma nova medida real.
3. **Caneta Mágica:** X com dois riscos cruzados apaga elemento atingido; divisões usam riscos aproximadamente retos e paralelos; o usuário confirma a espessura. A distribuição mantém a soma exata em cm/mm.
4. **Peças e formas:** movimento de uma peça dentro da maior respeita as faces internas do MDF; edição/centralização e folgas continuam disponíveis; menu de formas inclui retângulo/quadrado, elipse e triângulo de croqui. Elipse e triângulo NÃO participam de divisão de MDF nem geram lista de corte.
5. **Fotos:** imagem importada começa travada para desenhar e medir por cima; a opção Foto permite destravar/mover e ajustar transparência.
6. **Corte:** mantém cadastro sequencial na calculadora, agrupamento por dimensão/material, OK cortou, alerta de produção; adiciona desenho ilustrativo de cada chapa com as peças estimadas. O algoritmo organiza por linhas sem rotação/veio definido, NÃO constitui plano CNC otimizado/validado.
7. **Integração:** teste de cozinha simulado, recorte de divisórias, foto, duas folhas, cadastro agrupado e reabertura dos dados salvos.

## Verificações locais
- Chromium nas resoluções 1180×780, 820×1180 e 390×844, sem exceções JS ou rolagem horizontal.
- Teste de projeto simulado: quadro 200×77 cm externo, laterais 1,8 cm, três divisórias 1,5 cm, quatro vãos com 47,975 cm cada; peça menor centralizada; cinco laterais idênticas agrupadas; cálculo estimado de chapas; foto travada e duas folhas restauradas.
- Testes de regressão no GitHub Actions + compilação Android.

## Limitações e segurança
Ainda não é o reconhecimento universal da escrita da Calculadora do iPhone e não existe um catálogo completo de formas do StarNote. Não confundir prévia de cotas/chapas com medidas validadas para produção. Testes no Tab S9 com S Pen física e otimização profissional considerando veio, ferragens e máquina continuam necessários. Faça backup antes de instalar o APK de testes.
