# Proposta de correção mínima do `gv` (17/11) — para aprovação, nada mudado no app

**Base:** `9561fcd` (Fase 2). Investigação em `engenharia/GV_INVESTIGACAO.md`.
**Prova:** `tools/sondas/s44_proposta_gv.js`. A proposta é trocada só dentro da página de teste (`window.__gvModo` = `atual`, `p1` ou `p2`). O `editor.html` não muda.

## O problema, em uma linha
O `gv(i)` não confere se o vão `i` existe. Com `i` maior ou igual a divisórias + 1 (ou negativo, ou quebrado), ele grava vãos que não correspondem a divisória nenhuma. Exemplo: `gv(99)` num módulo sem divisórias deixa `m.v` com 100 itens.

## Código atual
```js
function gv(i,mm){var m=mm||S.m;while(m.v.length<=i)m.v.push({k:'free',n:1,…padrão…});return m.v[i]}
```

## Proposta P1 (mínima, só a função `gv`)
```js
function gv(i,mm){var m=mm||S.m,n=m.div.length+1,k=Number(i);
  if(!(Number.isInteger(k)&&k>=0&&k<n)){/* vão que não existe */ registra(i,n);return padrao()}  // cópia solta: não grava nada
  while(m.v.length<=k)m.v.push(padrao());return m.v[k]}                                         // vão que existe: como hoje
```
- **Índice inválido** (negativo, quebrado, `NaN`, ou maior ou igual a divisórias + 1):
  - não grava nada no módulo;
  - devolve um vão padrão **solto**, que não fica ligado ao módulo. Quem editar essa cópia não muda nada no projeto, então nenhum vão é reaproveitado sem aviso;
  - registra a chamada no console, para achar quem pediu o vão errado.
- **Índice válido:** igual a hoje. Isso preserva as 29 edições que dependem do `gv` para gravar a configuração de um vão que existe mas ainda não tinha configuração própria.
- **Nada é apagado.** Peças, divisórias e configurações ficam como estão. A sobra gravada em projeto antigo também fica.
- **Tamanho:** uma função, cerca de 3 linhas.

## Proposta P2 (opcional, depois): a leitura nunca grava
- Na P1, ler um vão que existe e ainda não tem configuração **grava o padrão** nele, como já acontece hoje. Não cria vão a mais: o vão existe (está dentro de divisórias + 1). Mas mesmo assim é uma gravação feita durante a leitura.
- A P2 faz a leitura (`gv`) nunca gravar e cria uma função de edição (`vEditar`) para as 29 edições.
- **A sonda mostra o risco de fazer a P2 pela metade:** só com a troca do `gv`, tocar em "2 portas" num vão sem configuração **perde a edição**:
  - antes: o vão vira `door2`;
  - depois: nada gravado, 0 portas.
- Por isso a P2 mexe em 29 pontos do editor, cada um precisa de teste próprio. Não recomendo agora: o ganho é só não gravar um padrão que é igual ao que já aparece na tela.

## Complemento C: vão escolhido depois de "Limpar divisões"
- Hoje, "Limpar divisões" zera as divisórias e deixa `S.sv` no número antigo até a próxima aba corrigir. Exemplo: `S.sv 2` com 1 vão.
- Proposta: no próprio botão Limpar, `S.sv=0`, que é o vão que agora ocupa aquele lugar. Também valeria para outras camadas que diminuem as divisórias do mesmo módulo.
- É só estado de tela (qual vão está escolhido). Não muda peça, medida nem configuração.
- Com a P1 sem o C, a janela entre Limpar e a próxima aba vira inofensiva: a leitura devolve a cópia solta e não grava nada. O C só fecha essa janela.

## O que NÃO entra
- Sem migração. Não se tira a sobra de `m.v` dos projetos antigos, nem ao abrir, nem ao salvar (§3 e §11.7).
- `m.v` não é cortado no "Limpar divisões". Assim o desfazer e o refazer continuam funcionando igual.
- O que acontece com a sobra ao pôr divisórias de novo não muda. Hoje o `splitV` copia o vão dividido e empurra a sobra para o fim (3 → 5 itens com 2 divisórias). Comportamento anterior, sem efeito na fabricação (sonda s44, caso 2).

## Evidência (s44, rodada em `9561fcd`, 3 modos)
| Cenário | atual | P1 | P2 |
|---|---|---|---|
| Sem divisórias: `gv(-1)`, `gv(1.5)`, `gv(NaN)`, `gv(99)`, `gv(1)` | `m.v` 1 → **100** | `m.v` 1 → 1 | 1 → 1 |
| 3 divisórias: mesmos índices + `gv(4)` | `m.v` 4 → **100** | 4 → 4 | 4 → 4 |
| Peças depois dos índices ruins | iguais | iguais | iguais |
| Limpar → ler o vão escolhido → desfazer → refazer → pôr 2 divisórias | desfazer volta `door,shelves,drawers` · refazer limpa · repor dá `door,door,door` | igual ao atual | igual ao atual |
| Trocar de módulo (A no 3º vão → B de 1 vão) pelo 2D e pelo 3D | `S.sv 0` · B com 1 vão | igual | igual |
| Projeto antigo com 2 vãos sobrando: peças, corte, 3D, salvar e reabrir | iguais · sobra mantida · nada apagado | igual | igual |
| Vão sem configuração gravada: desenhar, peças, 3D e corte | grava o padrão (1 → 3) | grava o padrão (1 → 3) | não grava (1 → 1) |
| "2 portas" no vão 2 sem configuração gravada | vale (`door2`) | vale (`door2`) | **perde a edição** |
| Chamadas inválidas registradas | — | 11 | 11 |
| Erros de página | 0 | 0 | 0 |

## Testes a acrescentar na bateria se a P1 for aprovada
Cada um tem que **falhar no `9561fcd`** e **passar com a P1**, exceto os de garantia, marcados com (g):
1. Módulo sem divisórias: `gv(-1)`, `gv(1.5)`, `gv(NaN)`, `gv(1)`, `gv(99)` não mudam `m.v`, peças, corte nem `histKey`.
2. Módulo com 3 divisórias: `gv(4)` e `gv(99)` não mudam nada. (g) `gv(0..3)` devolvem os vãos certos.
3. (g) Limpar divisões, desfazer, refazer, pôr divisórias de novo: as configurações voltam certas e nenhum vão antigo reaparece.
4. (g) Trocar de módulo pelo 2D e pelo 3D com o 3º vão escolhido: o vão escolhido existe no módulo novo e nenhum vão é criado.
5. (g) Projeto antigo com vãos sobrando: abrir, desenhar, 3D, salvar, fechar e reabrir mantêm a sobra e não mudam peças nem corte.
6. (g) Editar ("2 portas", prateleiras, gavetas) num vão que existe sem configuração gravada continua valendo.
7. Família (§11.2): o mesmo teste 1 em inferior, superior, torre, guarda-roupa e painel do catálogo.

## Risco da P1
- Algum caminho que dependa de o `gv` criar vão além das divisórias.
  - Nos 142 modelos do catálogo nenhum tem vãos além de divisórias + 1.
  - Na sonda nenhum fluxo fez isso.
  - Confirmação final: bateria completa (340) e todas as sondas com a P1 aplicada, antes de qualquer commit.
- Edição feita em vão inválido passa a não valer, em vez de cair num vão fantasma. Isso é o comportamento pedido ("não reaproveitar outro vão silenciosamente"). O registro no console mostra quem chamou.

## Pedido de autorização
- **P1** + testes 1 a 7: um commit.
- **C**: outro commit.
- **P2**: não recomendado agora.
