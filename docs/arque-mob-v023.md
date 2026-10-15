# Arque Mob v0.23 — Folha 2D e Calculadora

**Mudança temporária solicitada:** a interface do Arque Mob exibe apenas a Folha 2D. Botões de ambiente e construção 3D estão ocultos; o código e os projetos 3D anteriores são mantidos para futura retomada.

## Folha
- Linha reta por dois pontos: toque–toque ou arraste; novos pontos continuam o traçado.
- Alinhamento automático horizontal/vertical e conexão de pontas próximas (tolerância padrão 8 cm, configurável entre 0 e 30 cm).
- Tocar numa linha permite digitar e alterar o valor manual de centímetros, ajustando o comprimento na escala virtual. Não é um medidor de distância real.
- Seleção e arraste de extremidades, desfazer, limpar apenas a folha (com confirmação), zoom e deslocamento com dois dedos.
- Linhas salvas por obra e ambiente na persistência já existente; folhas sem móveis também recuperam as linhas.

## Calculadora
- Abrir/fechar sobre a folha e arrastar pelo título.
- Adição, subtração, multiplicação, divisão, casas decimais, apagar e limpar.
- A calculadora não modifica medidas sem digitação explícita pelo usuário.
- Posição do painel salva localmente.

## Validação
Sintaxe JavaScript; testes de interface em Chromium headless nas janelas 1180x780, 820x1180 e 390x844; alinhamento, edição de cm, desfazer, cálculo 7+8, mover e fechar calculadora, linhas no armazenamento simulado. Testes automáticos GitHub Actions.
**Atenção:** requer teste real de gestos/S Pen no Tab S9. A folha é para anotação/desenho e não substitui medição real nem engenharia final do plano de corte.
