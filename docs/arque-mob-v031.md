# Arque Mob 0.31 — Folha A4, centralização e corte em andamento

Esta atualização mantém o 3D temporariamente oculto, sem apagar projetos.

**Mudanças solicitadas**
- Folha A4 vertical com limite geométrico; desenhos fora da folha ficam ocultos.
- Ponta da régua sem alça quadrada. Toque na ponta selecionada amplia, com opção de ligar/desligar nas Configurações.
- Etiquetas menores, com tamanho de fonte configurável em Configurações; medidas ao vivo continuam visíveis na linha.
- Borracha para linhas, notas, peças, mão livre e fotos (foto requer confirmação).
- Ao tocar três vezes sobre uma peça, centraliza a menor sobre a maior conforme as extremidades externas; valida que a menor cabe.
- Caneta Mágica: quantidade de riscos indica quantidade de vãos (3 riscos = 3 vãos), descontando espessura a ser informada/confirmada.
- Espessura em cm/mm e cantos quadrados continuam configuráveis no construtor.
- Na Calculadora: Adicionar peça ao corte (nome, largura, profundidade, quantidade, cm/mm). Lista agrupada de peças iguais, ordenada pela maior área, vermelho pendente e verde 'OK, cortou'. Também permite retornar uma peça a pendente.
- Distribuição preliminar nas chapas usando o método atual por faixas; parâmetros serra/refilo já existentes. **Não é plano CNC ou otimização global certificada**.
- Acesso direto ao Mob pelo cabeçalho do Measure: digitar apenas nome do cliente, criar/abrir automaticamente uma obra simplificada. Cliente e obra são gravados antes de sair da tela.

**Testes**
Chromium headless simulado nos tamanhos 1180×780, 820×1180, 390×844; criar/centralizar peças, triplo toque, divisão por riscos, borracha, adicionar item 3×74×24, agrupar e marcar cortado. Testes Node/Javascript de sintaxe e agrupamento. Builds Android pelo GitHub Actions.

**Limitações**
Sem teste físico de S Pen no Galaxy Tab S9. As medidas da folha são escala visual e exigem entrada/validação manual antes de fabricar. Conferir orientação do veio, fitas, usinagem e folgas antes do corte. Backup dos projetos antes da instalação.
