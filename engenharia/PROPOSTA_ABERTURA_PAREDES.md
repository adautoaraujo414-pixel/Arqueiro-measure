# Proposta técnica — Abertura e remoção de paredes (cozinha americana / balcão)

Pedido do Adauto, 22/11/2026. Claude Code 2, ramo `feature/pecas-livres-2d` (HEAD 5173f48).
**Só análise. Nada implementado.** Implementação e merge só com autorização específica do Adauto depois desta análise.
Referência visual citada no pedido (bancada em L com armário inferior e ambiente aberto): **não chegou a esta sessão** — reenviar.

## 1. Como as paredes funcionam hoje (auditoria, linhas do `editor.html` em 5173f48)
- 3 paredes: fundo `F` (sempre existe, é a referência de medidas: `S.W`, x=0), esquerda `L` e direita `R` (`'e'/'d'` em ops/módulos/pedras).
  Paredes extras no meio da sala: `S.xw[]` (`'X'+id`). Não há 4ª parede (frente).
- Configuração: `S.wall = {F:{h1,…}, L:{t,tp,o,len,a,h0,h1}, R:{…}}`, lida por `wallCfg` (L1389) e gravada por `wallSet` (L1393);
  `S.wl[s]==='n'` esconde a parede do lado. Tipos `WTP` (L1385): normal · meia · vidro · sem. A meia parede tem altura **fixa 1100** (L4694, L4774)
  e não é oferecida para o fundo. Remover o fundo é bloqueado em 4 lugares (wallCfg L1390, wallDel L4861 "A parede do fundo não sai", editor 3D L4518, limX dos módulos).
- Aberturas: `S.ops` (`t:'porta'|'janela'`, `st:'vao'|'blindex'|'vidro'`, `x, b, w, h, wall`). O editor do painel já tem largura, altura, posição e "Do chão".
  **No 3D do fundo e das laterais só porta/vão corta a parede, e sempre do chão** (L3667, L4698): um vão com `b>0` deixa um buraco embaixo em vez de peitoril.
  Janela nunca corta (é pintada). As paredes extras `xw` já cortam buraco de verdade com peitoril e verga (`xopHoles`/`room3xw`, L4751-4777) — é o padrão a reaproveitar.
- 2D: a vista de frente desenha os vãos da parede escolhida; a Planta desenha a parede em faixa cheia (não mostra abertura).
- Móveis: `m.wing` `'e'/'d'` (parede do lado), `'L'` (livre, `lvSolta`), canto. **Nada move nem apaga móvel quando a parede some** (regra "só avisa",
  `testAmbienteNaoModificaOsMoveisSoAvisa`, P0-PAREDE). Hoje, ao esconder a parede do lado, o móvel fica no lugar sem parede atrás.
  Atenção: `lvSolta` (Tirar da parede) leva o móvel pro meio da sala — **não preserva a posição**.
- Salvamento: `snapState` guarda `wall`, `wl`, `ops`, `xw` (o objeto inteiro); desfazer/refazer do ambiente é o `histTick` (projeto inteiro). A vista da parede
  do lado (`toView`) troca `S.wall` por um fundo genérico (perde o tipo/meia da parede do lado na vista).

## 2. Solução proposta (reaproveita o que existe; sem segundo sistema)
**Modelo de dados — só campos opcionais novos (projeto antigo não muda):**
- **Abertura / balcão** = item de `S.ops` com `t:'abertura'` (tipo novo; não é porta nem janela) e `x, w` (posição e largura na parede), `b` (altura do que
  fica embaixo = peitoril / meia-parede; 0 = do piso), `h` (altura da abertura) ou `teto:1` (vai até o teto), `wall:'f'|'e'|'d'|'X…'`.
  - Cozinha americana do exemplo: parede 2,70 m, `b=1100`, `teto:1` → fica a parte de baixo, abre até o teto.
  - "Até uma altura definida": `teto:0, h=…` → fica uma faixa em cima (verga).
  - **Meia-parede inteira** = abertura com `x=0, w=comprimento da parede`. O tipo `meia` de hoje continua funcionando (projeto antigo), mas a altura passa a ser editável.
- **Remover parede inteira**: laterais = o que já existe (`tp:'sem'`), reaproveitando o caminho de "Esconder/Mostrar" (não criar 5º caminho).
  Fundo = `S.wall.F.tp='sem'`: a **linha do fundo continua como referência invisível** (x=0, z=0, `S.W`), só não é desenhada/sólida; nenhuma parede muda de lugar.
- **Restaurar** = apaga as aberturas daquela parede e volta `tp:'normal'` (guarda o que havia em `S.wall[s].orig` pra restaurar exatamente).

**Desenho:**
- 3D: generalizar o corte do fundo e das laterais pro padrão das paredes extras (pedaço embaixo `0..b`, buraco `b..b+h`, verga `b+h..topo`),
  valendo pra `abertura` e corrigindo o vão com `b>0`. Piso e teto não mudam. Fundo `sem`: não desenha a parede, mantém piso/teto.
- 2D (vista da parede): retângulo da abertura com cota (largura, altura, do chão, até o teto), alças pra arrastar/esticar; meia-parede com linha do topo.
- Planta: a parede com o trecho aberto em pontilhado.

**Móveis (nada é deslocado, cortado, redimensionado nem apagado):**
- Remover/abrir parede não toca em `S.mods`, `S.stones`, `S.stw`, `S.rp`. Módulo da parede removida **continua no mesmo lugar e com as mesmas medidas**
  (como hoje nas laterais). Aviso na tela listando os módulos que ficaram "sem parede atrás".
- "Desvincular de forma controlada": botão por módulo **"Soltar sem mexer"** = converter pra móvel livre **na mesma posição do mundo** (nova conversão; o
  `lvSolta` atual não serve porque leva pro meio da sala). Sempre com confirmação.
- Móvel sem parede continua possível: inferiores, pedra, balcão, móveis livres, continuar a cozinha pra sala, módulos dos dois lados da abertura.
- Colisão: o trecho que fica da parede (peitoril/verga/meia-parede) vira sólido pro arrasto de móvel livre e das peças livres (mesmas caixas do 3D).

**Interface:** ao tocar na parede (2D/3D), menu "EDITAR PAREDE": Parede inteira · Criar abertura · Meia-parede / balcão · Remover parede · Restaurar.
Medidas por digitação (cm, com a calculadora de sempre) e pelas alças no desenho.

**Plano de corte:** nenhuma alteração (parede não é peça de móvel). Teste confirma o corte igual antes/depois de abrir/remover.

## 3. Compatibilidade e riscos
- Projeto antigo: sem campo novo → igual. Teste "abre e salva igual".
- **Versão antiga do app abrindo projeto novo**: `t:'abertura'` é desconhecido pra ela. Precisa conferir o que a versão publicada faz com tipo desconhecido
  (ignorar / desenhar como janela / erro) **antes** de liberar. Alternativa mais segura a decidir: marcador de formato do ambiente (como `emFmt` das peças livres).
- `sideWalls` hoje força a parede a voltar se houver porta/janela nela → conflito com "remover": proposta é esconder as portas/janelas junto e devolver no "Restaurar".
- Vista da parede do lado (`toView`) zera `S.wall`: as aberturas ficam em `S.ops` (já são levadas); o tipo/meia da parede do lado precisa ir junto.
- Acoplamento com o trabalho do Code 1: espelhamento da parede esquerda (PAREDE-ESQ, VAO-ESQ). O corte da lateral fica nas coordenadas da parede; os testes `testParedeEsquerda*` são a guarda.
- `snapObra` (L8787) compara só alguns campos dos ops: incluir os novos.

## 4. Testes (bateria)
abrir abertura (fundo/esquerda/direita) · balcão b=1100 até o teto e até altura definida · meia-parede inteira com altura editável · remover lateral e fundo ·
restaurar exato · 2D/3D/Planta mostram igual · móveis com posição/medidas idênticas antes/depois (nenhum apagado) · soltar sem mexer mantém o lugar do mundo ·
móvel livre/peça não entra no peitoril · plano de corte idêntico · salvar/reabrir · desfazer/refazer · projeto antigo abre e salva igual · regressão `testParedeEsquerda*`, `testAmbienteNaoModificaOsMoveisSoAvisa`, `testP0Parede*`.

## 5. Etapas (cada uma com teste e validação antes da próxima)
A. Abertura retangular com peitoril no 3D (fundo/laterais) + 2D + Planta · B. Balcão/meia-parede com alturas editáveis · C. Remover/restaurar (laterais e fundo) ·
D. Menu EDITAR PAREDE + alças · E. "Soltar sem mexer" · F. compatibilidade com a versão publicada.

## 6. Perguntas ao Adauto (não inventar)
1. A **parede do fundo** também pode ser removida? (proposta: sim, a linha fica como referência invisível das medidas.)
2. Portas e janelas que estão na parede removida: **somem junto e voltam no Restaurar**? (proposta: sim, guardadas.)
3. Módulos da parede removida: **ficam vinculados no mesmo lugar** e a pessoa solta um por um se quiser? (proposta: sim.)
4. Meia-parede/balcão: espessura igual à parede (15 cm)? **Leva tampo/acabamento em cima** (pedra ou madeira) ou só a parede?
5. Altura padrão do balcão: 1,10 m (como no exemplo)?
6. Reenviar a imagem de referência.
