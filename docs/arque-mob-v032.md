# Arque Mob v0.32 — Folha A4 e cadastro direto no teclado da calculadora

Atualização incremental da v0.31, sem adicionar funções fora dos três ajustes solicitados.

- **Folha A4 maximizada**: ao entrar e tocar em 100%, ocupa o maior espaço possível mantendo proporções e as quatro bordas visíveis. Uma folha A4 vertical em tela horizontal naturalmente deixa margens dos lados; não distorce o papel nem desenha fora dos limites. O zoom com dois dedos continua ancorado.
- **Divisão até as bordas internas**: três divisórias criam quatro vãos iguais; o último vão recebe exatamente a mesma medida. Laterais superior/inferior e esquerda/direita são representadas visualmente, e as divisórias tocam suas faces internas. O desconto de material continua correto.
- **Plano de corte na própria calculadora**: botão Lançar peça abre um painel compacto dentro da calculadora, sem modal. Fluxo Nome → Largura → Profundidade → Quantidade, avançando pelo botão OK (também = para campos numéricos). No último OK, o item é salvo e o fluxo volta ao nome da próxima peça. A lista continua agrupando peças iguais e marcando Pendente/Cortou.

Testes locais com Chromium 1180×780, 820×1180 e 390×844: tela inteira, cadastro sequencial, duas entradas iguais agrupadas (3+2), confirmação de corte e ausência de exceções JS. Teste de quatro vãos (três divisórias) com desconto 1,5 cm e margens laterais 1,8 cm; sem diferenças na largura do último vão.

**Limites:** manter cotas de produção conferidas, validar fisicamente com Samsung Tab S9/S Pen e conferir veio/serra/folgas antes de fabricar.
