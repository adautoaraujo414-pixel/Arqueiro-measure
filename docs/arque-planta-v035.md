# Arque Mob 0.35 — Planta proporcional com trena laser

Área nova **Planta 2D**, disponível pelo botão Planta no Arque Measure ou no cabeçalho do Arque Mob, sem reativar o construtor 3D.

Referência: vídeo de um app de planta com cômodo em L e cotas nos lados. A planta usa **centímetros reais** como sistema geométrico e encaixa proporcionalmente na tela; o zoom é visual e não altera as dimensões. Permite cômodo retangular ou em L, edição de largura, profundidade e recuos, e paredes internas simples.

Ferramentas estritamente solicitadas:
- Adicionar e arrastar **pedra/bancada ou ilha de pedra**, redimensionáveis.
- Adicionar **cuba ou cooktop** como retângulos, redimensionáveis e posicionados exclusivamente sobre a pedra escolhida, sem ultrapassá-la.
- Exibir em tempo real as **distâncias esquerda, direita, superior e inferior** até as bordas da pedra, tanto em cm quanto em mm no painel.
- **Trena laser:** o bridge nativo Android existente (protocolo Bosch BLE) envia leituras por `window.ArqueBleMeasure(millimeters)`. Usuário escolhe uma dimensão de destino: parede total, profundidade, recuo ou largura/profundidade de uma peça. Ao receber leitura, pode tocar Aplicar ou habilitar atualização automática naquela dimensão. O aplicativo não deve adivinhar qual parede foi medida.
- Campo manual em mm como alternativa de validação, útil no navegador ou sem trena.
- Salvar por obra/ambiente em IndexedDB `arquePlantaByRoom`, separadamente do `arqueMobByRoom` da folha; backup antes de reinstalar.

Testes automatizados: três dimensões de viewport (1180×780, 820×1180, 390×844), arrastar cuba e atualizar cotas, alterar largura via mm, adicionar ilha/cooktop, restauração após abrir, cálculo de polígono em L e restrições da bancada. Ligação física por Bluetooth e precisão da trena/S Pen ainda não validadas no hardware.

O recurso é um **editor 2D funcional em teste**, não substitui projeto executivo nem promete medições físicas sem trena compatível. Furos e recortes na pedra não são gerados automaticamente; confirmar fichas técnicas dos fabricantes antes da execução.
