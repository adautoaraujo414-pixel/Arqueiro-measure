# Régua do batente do puxador cava: diagnóstico e proposta (17/11) — para aprovação, nada implementado

Pedido do Adauto (17/11): escolher à mão o tamanho das réguas de batente do cava das gavetas, com opção automática e restaurar padrão, no menu de ajustes que já existe. Aplicar em "só esta régua", "todas do módulo" e "todas do projeto", nessa ordem. Avisar antes de aplicar medida inviável. Valer em todos os módulos com gaveta cava e nas três plataformas.

**Referência:** o pedido cita uma imagem, mas ela **não chegou** nesta conversa. Precisa ser enviada de novo e registrada em `REFERENCIAS.md` antes de implementar (§2).

## Como funciona hoje (código atual, sem mudança)
- **As peças:** em gaveta com cava, `partsOf` gera:
  - **Batente (cava):** uma régua entre cada par de gavetas, centrada no vão entre as frentes, com o comprimento do vão (`vw`).
  - **Batente superior (cava):** em cima da primeira gaveta, só se a altura dele for maior que 0.
- **As medidas já são guardadas por vão** (`m.v[i]`):
  | Campo | O que é | Padrão |
  |---|---|---|
  | `cbG` | vão entre as frentes, onde entram os dedos | 25 mm |
  | `cbR` | altura da régua entre gavetas | `cbG + 30` = 55 mm (15 de sobreposição atrás de cada frente) |
  | `cbT` | altura do batente superior | 0 (sem peça) |
- **Onde aparecem:** aba das gavetas do vão, campos "Batente superior (mm)", "Vão entre gavetas na régua (mm)" e "Régua entre gavetas (mm)".
  - Mudar `cbR` muda **todas** as réguas daquele vão juntas.
  - **Não existe** ajuste de uma régua só, nem do módulo inteiro, nem do projeto.
- **Dois caminhos geram as mesmas réguas:**
  - o vão comum: balcão, gaveteiro, torre (`editor.html` ~linha 588);
  - o editor por vãos, de guarda-roupa e armário alto (~linha 10341).
  - Os dois leem `cbG`, `cbR` e `cbT`.
- **Frentes:** a altura de cada frente depende de `cbG` (vão entre frentes), **não** de `cbR`. Mudar a altura da régua não muda as frentes, só a sobreposição atrás delas: (`cbR` − `cbG`) ÷ 2.
- **Profundidade:** a caixa da gaveta já fica 15 mm mais curta, para não entrar na régua (`corrDsc`, ~linha 1023).
- **Falhas que já existem nesses campos:**
  1. Não há limite nenhum. Régua menor que o vão (sem sobreposição) e régua tão alta que entra na altura da caixa da gaveta são aceitas sem aviso.
  2. Digitar no campo não passa pelo desfazer (`v[...]=n; draw()`, sem `snap()`).
  3. Por ser medida do vão, não dá para mudar uma régua só.

## Proposta (correção mínima, mesma fórmula de fabricação)
1. **Escopo, sempre nesta ordem:** `Só esta régua · Todas deste módulo · Todas do projeto`.
   - **Só esta régua:** novo `v.cbRq = {n: mm}`, onde `n` é a régua daquele vão (1ª, 2ª…). Sem valor, vale o `cbR` do vão.
   - **Todas deste módulo:** grava `cbR` em todos os vãos com gaveta cava do módulo, nos dois caminhos, e tira os `cbRq` desses vãos.
   - **Todas do projeto:** o mesmo em todos os módulos. Antes, mostra quantas réguas e módulos mudam e pede confirmação.
2. **Automática / padrão:**
   - "↺ Medida automática" apaga `cbR` e `cbRq`, e volta a `cbG + 30`.
   - Se "padrão" for diferente de "automática" (ex.: 55 fixo mesmo mudando `cbG`), preciso que o Adauto diga.
3. **Onde fica:** no que já existe, sem menu novo.
   - Na aba das gavetas do vão, os campos atuais ganham o escopo e o "automática".
   - Tocar na régua no 3D ou no 2D abre o quadro da peça que já existe, com a altura e os mesmos três botões de escopo.
4. **Limites (avisar antes de aplicar, nada é cortado sozinho):**
   - **Mínimo:** `cbG` + 2 × sobreposição mínima. A frente tem que encostar na régua. A sobreposição mínima precisa ser confirmada pelo Adauto (ex.: 5 mm).
   - **Máximo:** a régua não pode entrar na altura de passagem da caixa da gaveta de cima nem da de baixo, porque a gaveta bateria ao abrir. A conta usa as folgas da caixa que já existem (`gbox`: folga de baixo e de cima).
   - **Dedos:** o vão entre as frentes (`cbG`) não muda com a altura da régua. Se a pessoa mudar o `cbG`, vale a regra que já existe.
   - Fora do limite: aviso com módulo, medida, limite e diferença, e nada aplicado (regra GEO-AVISA).
5. **Comprimento:** hoje é o vão inteiro (de lateral a lateral ou divisória), e é o que segura a frente em toda a largura. **Proposta: não liberar** sem a referência. Se a imagem mostrar régua mais curta, definir com o Adauto onde ela fica e o mínimo.
6. **Unidade:** o pedido fala em cm, mas os campos atuais do app são em mm. Proposta: manter mm, para não misturar unidades no mesmo painel. Preciso da confirmação.
7. **Desfazer:** os campos passam a gravar no desfazer (`snap()`).
8. **Sem mudança de fórmula:** a altura das frentes, as folgas, o corte e a profundidade da caixa ficam iguais. Só a altura da régua passa a poder ser por régua. `partsOf` continua sendo a única fonte (§4), então 2D, 3D, lista, corte e orçamento seguem sozinhos.
9. **Projetos antigos:** sem `cbRq`, nada muda, então não há migração. Um projeto salvo com `cbRq` e aberto num app ainda não atualizado mostra a régua do vão (`cbR`). Por isso as três plataformas devem receber juntas.

## Família de módulos (§11.2)
- Vão comum com gaveta cava: balcões, gaveteiros, torres com gaveta, módulos de canto com gaveta.
- Editor por vãos: guarda-roupa, armário alto e closet com gaveta cava.
- Gaveta interna e caixote não têm régua de cava. Conferir que não ganham nada.

## Testes previstos (bateria + sondas)
- **2D, 3D, lista, corte e orçamento:** 5 → 7 cm numa régua de um gaveteiro de 4 gavetas. Só aquela régua muda nos cinco, e as outras duas ficam iguais.
- **Escopo:** "todas do módulo" e "todas do projeto" com 3 módulos de famílias diferentes. Nenhuma outra peça muda.
- **Limites:** abaixo do mínimo e acima do máximo avisam e não aplicam. O projeto fica idêntico (`histKey`).
- **Persistência:** salvar, fechar e reabrir. Desfazer e refazer. Duplicar o módulo. Projeto antigo sem `cbRq`.
- **Automática:** volta a `cbG + 30` e acompanha uma mudança de `cbG`.
- **Mudar o número de gavetas:** régua personalizada que deixou de existir (5 → 3 gavetas) não vira peça fantasma. A decisão do que fazer com ela fica com o Adauto.
- **Família:** o mesmo teste no vão comum e no editor por vãos.

## Perguntas para o Adauto antes de implementar
1. Reenviar a imagem de referência.
2. Unidade: manter mm nos campos (proposta) ou passar para cm?
3. "Altura da régua" é só a régua entre gavetas (`cbR`), ou também o batente superior (`cbT`)?
4. Comprimento personalizável: sim ou não? Se sim, onde a régua fica (centrada ou encostada).
5. Sobreposição mínima atrás de cada frente (para o limite mínimo).
6. "Restaurar padrão" é igual a "automática" (`cbG + 30`) ou é um valor fixo?
7. Ao diminuir o número de gavetas, a régua personalizada que sobra: some, ou fica guardada para quando voltar?
