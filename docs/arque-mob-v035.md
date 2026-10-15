# Arque Mob v0.35 — próxima fase de precisão e fluxo

**Origem:** preserva a v0.34 em um ramo de desenvolvimento separado, sem reativar o 3D.

Melhorias entregues nesta fase:
- Medição em U por **três toques em três linhas distintas**, exigindo a base e as duas laterais. Apresenta valores em cm e mm e avisa quando são estimativas. Os toques anteriores repetidos no mesmo ponto não geram uma leitura falsa.
- Folgas esquerda, direita, superior e inferior entre uma peça menor e um quadro que a contém, atualizadas na tela enquanto a peça é movida. A centralização existente por três toques continua.
- Traço livre usa `PointerEvent.getCoalescedEvents` quando disponível (maior fidelidade com S Pen), sem desabilitar o desenho com o dedo ou os gestos de pinça.
- Foto redimensionada de acordo com os limites do A4, e ampliação limitada ao espaço da folha, mantendo anotações sobre ela.
- A lista de produção registra um corte **por toque em OK**, permitindo correção de uma unidade, mantém grupos por dimensão/material e ordenação por área.
- Prévia de faixas das chapas desenhada em SVG com posições numeradas. Continua sendo **simulação por faixas**, não otimização global CNC; ainda falta cálculo profissional de veio/usinagens e conferência física.
- Mantém desenho por arraste, alinhamento/Fundir, Caneta Mágica, formas retangulares, caneta, destaque, apagamento por X, menus por ferramenta, fotos, calculadora, páginas e salvamento.

Validação: Node verificando geometria, divisão, corte unidade a unidade, sintaxe; Chromium nas telas 1180×780, 820×1180 e 390×844; ensaio funcional de obra com quadro e peça interna, divisão de 4 vãos, lançamento de 5 peças e reabertura de duas folhas.

**Não validado ainda:** uso físico no Tab S9 com S Pen, precisão metrológica, plano de corte para CNC ou reprodução integral do StarNote/Promob. Confirme medidas no local antes de fabricar. Faça backup dos projetos antes da instalação.
