# Motor de precisão 2D/3D: diagnóstico e proposta

Pedidos de 16/11 às 13:48: "Auditoria de regressões e integridade" e "Motor de precisão profissional 2D/3D".
**Só o item 1 da fase 1 foi feito (erro do tamponamento). O resto depende de aprovação. Nada publicado.**

## 1. Como o editor funciona hoje (medido no código, `app/src/main/assets/editor.html`)
- **Fonte única das peças:** `partsOf(m)`. O 2D, o 3D (`DRM`/`build`), a lista, o corte (`cutLines` e `cutGroups`) e o orçamento leem dela.
  - Peças contínuas entre módulos encostados (base, rodapé) aparecem uma vez só no corte, como "contínua", e no 3D são desenhadas pelo vizinho. Isso é regra e está conferido no teste do tamponamento.
- **Identidade da peça:** `pk` = nome + número.
  - Desde 93495d1 a peça é reconhecida pelo objeto do vão (XP-PK). Peça tirada, ajuste, cor e fita seguem a peça.
  - Em 8dbc7ae: um vão trocado por uma cópia igual continua sendo o mesmo vão.
- **Toques:** 69 tratadores de `pointerdown` e 255 de `click`, empilhados em camadas (cada função nova embrulha a anterior). A escolha do que um toque faz está espalhada; não existe um lugar que decida "qual é o alvo deste toque".
  - É daí que vêm os erros de "um toque, duas ações": tamponamento que move o módulo, a ✏️ que abria duas coisas, o 2º toque que não contava.
- **Desfazer (corrigido em 16/11 à tarde, ver `AUDITORIA_INTEGRIDADE.md`):** o histórico de verdade é `histTick`/`histGo`, com o projeto inteiro, até 100 passos, juntando mexidas em menos de 700 ms. `snap()` é o legado do módulo escolhido. Conferido: mexer em vários módulos e na parede e depois ↶/↷ volta idêntico. Não substituir.
- **Regras que mudam o projeto sozinhas:** o cálculo das peças também corrige dados. Exemplo achado hoje: módulo de baixo erguido perdia rodapé, travessa e moldura de vez (TAMP-2D-ALVO). Outras regras desse tipo existem e não foram todas auditadas.

## 2. Por que erros antigos voltam
1. **Regra no lugar errado.** Quando a correção é no tratador de um caminho (um botão, um gesto), outro caminho para o mesmo resultado continua errado. Exemplos:
   - porta da caixa da geladeira: aba Portas × menu do vão;
   - tamponamento: módulo escolhido × não escolhido.
2. **Cálculo que grava dado.** Uma regra de exibição que escreve no projeto (`m.rod=false`) não volta quando a condição some.
3. **Teste de botão isolado.** A bateria tinha muitos testes de função e poucos de sequência real com toques de verdade.
4. **Expectativa de teste que acompanha o erro.** Já aconteceu de atualizar o número esperado sem o pedido. A regra agora é: só com comentário citando o pedido e a data.

## 3. Proposta em fases
| Fase | O que muda | Risco | Precisa de aprovação |
|---|---|---|---|
| 1 | **Alvo único por toque.** Um decisor só no `pointerdown` do 2D e do 3D (peça → handle → vão → módulo, nessa ordem). Os tratadores atuais passam a consultar o decisor. Começa pelos casos com erro relatado: tamponamento (feito), divisória, prateleira e gaveta. | Médio: mexe no caminho de todo toque. Por isso entra por tipo de peça, com teste de toque de verdade em cada um. | Sim, depois do tamponamento |
| 2 | **Travas.** De posição: módulo de baixo embaixo da pedra só muda de altura pelo campo, não pelo arrasto. Estrutural: base, laterais e rodapé não somem por efeito de outra edição. Desbloqueio explícito. | Alto: muda o jeito de arrastar módulo em todos os projetos | Sim |
| 3 | **Edição que valida antes de gravar.** Cópia do projeto, aplica, confere a integridade (peça dentro de peça, peça fora do módulo, medida negativa, base sem rodapé no chão…) e só então grava. Se falhar, desfaz tudo. O desfazer passa a guardar o passo inteiro (todos os módulos tocados). | Médio | Sim |
| 4 | **Toque em peças sobrepostas:** lista curta pra escolher, em vez de adivinhar. | Baixo | Sim |
| 5 | **Auditoria das regras que gravam dado dentro do cálculo** (como a do rodapé). Cada uma vira derivada (calculada sem gravar) ou reversível, sem mudar projeto antigo ao abrir. | Médio | Sim |

**Fora da proposta:** reescrever o editor, copiar a interface ou o código do Promob, mudar medidas aprovadas.

## 4. Testes que acompanham cada fase
- Toque de verdade, pelo `elementFromPoint`, como o dedo, em celular, tablet e computador:
  - perto da borda;
  - com zoom;
  - em peça sobreposta;
  - arrasto acidental;
  - troca de módulo.
- Sequência do marceneiro em cada família (balcão, aéreo, torre, guarda-roupa):
  - criar → base → tamponamento → mudar a altura pelo 2D → 3D → porta → salvar → fechar → reabrir → medidas → plano de corte.
- Cada teste falha na versão com erro e passa depois.
- **Aparelho:** iPhone, iPad, Galaxy Tab S9 FE e Windows de verdade não estão disponíveis aqui. Os testes rodam no Chromium (Windows e Android usam o mesmo motor) e no simulador do iPhone, pelo CI. Caneta (S Pen) não é simulada com fidelidade.
