# Arque Mob v0.22 — evolução controlada do Construtor 3D

Branch de testes, sem substituir o ramo principal.

## Sequência implementada
1. **Interação 3D:** seleção de móvel, alça de redimensionamento pela largura no ambiente, movimento, zoom, desfazer, preservação de posições absolutas das divisórias existentes; validação de limites de parede e colisões.
2. **Engenharia:** cadastro de materiais independente por módulo; prévia de laterais, bases, prateleiras, fundos, cavas e frentes. Os dados de usinagem e ferragens ainda requerem validação manual.
3. **Organização de chapas:** simulação por faixas e material, sem rotação (veio não especificado); refilo e serra configuráveis. Mostra quantidades e peças que não cabem. Não gera G-code ou ordens para CNC, nem é otimização global.
4. **Teste de ponta a ponta simulado:** trecho reto de cozinha com parede 317 cm e profundidade 269 cm, dois módulos de 150 cm, cuba, cooktop, janela, materiais diferentes e reabertura do projeto. Não representa o segundo braço em L.

## Testes realizados
- Playwright Chromium headless: gesto 3D, desfazer, criação de peças, duplicação, materiais, eletrodomésticos, janela, persistência e conservação das posições.
- Caso simulado: 10 tipos/14 unidades de peças, 3 chapas estimadas em MDF de materiais separados (235 × 185 cm, refilo 3 cm, serra 3,2 mm), sem peças fora da dimensão útil, mas sem aprovação para produção.
- GitHub Actions Android e teste unitário das chapas, com verificação de posicionamento e sobreposição.

## Limitações para produção
Sem medição real do cliente e sem validação de peças, hardware, ferragens, veio ou encaixes. Posição/recorte de cuba e cooktop depende do fabricante. Plano de corte **não deve orientar produção** até ser conferido pelo responsável. Faltam testes físicos do toque/S Pen em Samsung Tab S9.
