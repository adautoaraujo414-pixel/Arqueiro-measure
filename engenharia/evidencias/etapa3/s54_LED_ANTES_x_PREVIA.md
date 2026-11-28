# s54 · (6) LED · ANTES no 5067fec × PRÉVIA no Claude 3 + Claude 4

Decisão do Chefe (28/11), repassada pelo Claude 3:
- "＋ No módulo escolhido" continua sendo o LED DE MÓDULO (rodapé no módulo de baixo, embaixo do aéreo). Agora mostra o destino antes (#ledprev) e só cria no OK.
- O LED NA PEÇA é o "💡 Toque na peça". A (6p) mede este caminho, com `window.LEDPICK=1` e pointerdown/up no `#cv3`.

Como a sonda conta:
- Mede o LED novo em `S.mods[mi].leds`, com módulo certo, `pk` igual ao da peça tocada e o conjunto das caixas `b.ledl` (perfil + lente) encostando na peça (3 mm).
- "Pediu escolha" (`#ledesc`) não é erro.
- "Recusado com aviso" (o app disse por quê e não criou nada, §12) fica fora da base do acerto e é listado à parte.
- Rodada: `window.__S54={so:'led'}`, cenários P1–P5, vistas iso/frente/lado no zoom 1× e iso ~2,6×, tela 1366×768.

A PRÉVIA é um merge local de 3674ecd + b3029da, só para validar a sonda. Não é o DEPOIS oficial, que espera a integração do Chefe.

## Achados (para o Claude 3; não mexi no código dele)

1. **ERRO COMPROVADO: o LED na porta cai na dobradiça.**
   - `lvlHost(mi,{pk})` pega a 1ª caixa do 3D com aquele pk. Na porta, essa caixa é a dobradiça (12×48×38 mm, `b.ferr=1`), que leva o mesmo pk `Porta#1`. O `lvlHost` é igual no 5067fec e no 3674ecd.
   - No 5067fec, `lvlAdd(0,'Porta#1',1)` cria o LED em cima da dobradiça, sem aviso.
   - No 3674ecd + b3029da, o `lvlFit` novo recusa: "ela tem 12 mm e o perfil precisa de 12 mm". A conta é `cw<PW+1`, que exige 13 mm, então o aviso se contradiz. A causa real é a caixa hospedeira errada.
   - Foram 43 de 44 recusas da PRÉVIA. A outra foi a corrediça da gaveta.
   - A sonda não conta LED na dobradiça como "encosta na porta": as caixas de ferragem (< 60 mm ou `b.ferr`) ficam fora dessa conta. Por isso o ANTES caiu de 79,5% para 75,5%.
2. **A frente de gaveta não cria LED nem avisa** (P1, todas as vistas).
3. **"Pediu escolha" em 176 de 310 toques (57%).** A peça tocada estava entre as opções em 173. Nos outros 3 ela ficou de fora: a lateral esquerda do aéreo (P1 iso), a lateral esquerda do nicho (P3 frente) e o fundo do nicho (P3 iso ~2,6×).
4. **LED de módulo:**
   - 18/18 no módulo certo, com a prévia `#ledprev` confirmada nas 18.
   - 13 foram pro rodapé, que fica fora da conta de encostar na peça tocada.
   - Os 5 aéreos encostam na base.

## Números

| Métrica | ANTES · 5067fec | PRÉVIA · merge local 3674ecd+b3029da |
|---|---|---|
| (6) LED · módulo certo (onde o app aceita LED) | 100% (5/5) | 100% (18/18) |
| (6) LED · encosta na peça tocada | 100% (5/5) | 100% (5/5) |
| (6) LED · recusado pela regra atual | 13 (app: "LED vai só nos módulos de cima e na cristaleira") | 0 (app: "LED vai só nos módulos de cima e na cristaleira") |
| (6p) LED na peça · caminho do toque | lvlPickFace (antigo) | pecaNoToque (Claude 4) |
| (6) LED de módulo · prévia #ledprev confirmada | 0 | 18 |
| (6) LED de módulo · foi pro rodapé | 0 (Chefe 28/11: o LED de módulo vai no rodapé do módulo de baixo, fora da conta de encostar na peça tocada) | 13 (Chefe 28/11: o LED de módulo vai no rodapé do módulo de baixo, fora da conta de encostar na peça tocada) |
| (6p) LED na peça · toques | 298 | 310 |
| (6p) LED na peça · base do acerto (sem escolha e sem recusa com aviso) | 298 | 90 |
| (6p) LED na peça · recusado com aviso do app | 0 | 44 |
| (6p) LED na peça · módulo certo | 97% (289/298) | 93.3% (84/90) |
| (6p) LED na peça · peça certa (pk) | 74.5% (222/298) | 93.3% (84/90) |
| (6p) LED na peça · encosta na peça tocada | 75.5% (225/298) | 93.3% (84/90) |
| (6p) LED na peça · pediu escolha (não é erro) | 0 (com a peça tocada entre as opções: 0) | 176 (com a peça tocada entre as opções: 173) |
| (6p) LED na peça · toque sem LED e sem aviso | 4 | 6 |
| (6p) LED na peça · tempo p95 (ms) | 16.2 | 32.7 |
| toque que mudou o projeto sozinho | 0 | 0 |

### Exemplos · LED na peça · ANTES · 5067fec

- P1 fila encostada + aéreos · iso · tocou 5:Porta (Porta#1) → LED no mód 5 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso · tocou 4:Porta (Porta#1) → LED no mód 4 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso · tocou 3:Porta (Porta#1) → LED no mód 3 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso · tocou 2:Lateral direita (Lateral direita#1) → LED no mód 2 · pk Tamponamento direito#1 · face 2 · não encosta na peça tocada · app: "💡 LED na tamponamento direito · lado esquerdo"
- P1 fila encostada + aéreos · iso · tocou 2:Porta (Porta#2) → LED no mód 2 · pk Tamponamento direito#1 · face 2 · não encosta na peça tocada · app: "💡 LED na tamponamento direito · lado esquerdo"
- P1 fila encostada + aéreos · iso · tocou 1:Lateral direita (Lateral direita#1) → nenhum LED · app: "💡 LED na lateral direita · lado esquerdo"
- P1 fila encostada + aéreos · iso · tocou 1:Frente de gaveta (Frente de gaveta#1) → LED no mód 1 · pk Travessa frontal#1 · face 1 · app: "💡 LED na travessa frontal · frente"
- P1 fila encostada + aéreos · iso · tocou 0:Porta (Porta#1) → LED no mód 0 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · front · tocou 3:Porta (Porta#1) → LED no mód 3 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · front · tocou 4:Porta (Porta#1) → LED no mód 4 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · front · tocou 5:Porta (Porta#1) → LED no mód 5 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · front · tocou 2:Tamponamento direito (Tamponamento direito#1) → LED no mód 2 · pk Tamponamento direito · engrosso 80#1 · face 2 · app: "💡 LED na tamponamento direito · engrosso 80 · lado esquerdo"
- P1 fila encostada + aéreos · front · tocou 0:Porta (Porta#1) → LED no mód 0 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · front · tocou 1:Frente de gaveta (Frente de gaveta#1) → LED no mód 1 · pk Travessa frontal#1 · face 1 · app: "💡 LED na travessa frontal · frente"
- P1 fila encostada + aéreos · front · tocou 2:Porta (Porta#2) → LED no mód 2 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · left · tocou 5:Porta (Porta#2) → LED no mód 5 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 4:Porta (Porta#2) → LED no mód 4 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 3:Porta (Porta#2) → LED no mód 3 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 0:Porta (Porta#2) → LED no mód 0 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 1:Frente de gaveta (Frente de gaveta#1) → LED no mód 1 · pk Frente/costa de gaveta (contra-frente e traseira)#1 · face 5 · app: "💡 LED na frente/costa de gaveta (contra-frente e traseira) · em cima"
- P1 fila encostada + aéreos · left · tocou 1:Lateral esquerda (Lateral esquerda#1) → nenhum LED · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 2:Porta (Porta#2) → LED no mód 2 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P1 fila encostada + aéreos · left · tocou 2:Lateral esquerda (Lateral esquerda#1) → LED no mód 1 · pk Lateral de gaveta#2 · face 5 · não encosta na peça tocada · app: "💡 LED na lateral de gaveta · em cima"
- P1 fila encostada + aéreos · iso z2 · tocou 3:Porta (Porta#1) → LED no mód 3 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso z2 · tocou 4:Porta (Porta#1) → LED no mód 4 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso z2 · tocou 5:Porta (Porta#1) → LED no mód 5 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P1 fila encostada + aéreos · iso z2 · tocou 2:Tamponamento direito (Tamponamento direito#1) → LED no mód 2 · pk Tamponamento direito · engrosso 80#1 · face 2 · app: "💡 LED na tamponamento direito · engrosso 80 · lado esquerdo"
- P1 fila encostada + aéreos · iso z2 · tocou 2:Lateral direita (Lateral direita#1) → LED no mód 2 · pk Tamponamento direito#1 · face 2 · não encosta na peça tocada · app: "💡 LED na tamponamento direito · lado esquerdo"
- P1 fila encostada + aéreos · iso z2 · tocou 2:Porta (Porta#2) → LED no mód 2 · pk Tamponamento direito#1 · face 2 · não encosta na peça tocada · app: "💡 LED na tamponamento direito · lado esquerdo"
- P1 fila encostada + aéreos · iso z2 · tocou 1:Lateral direita (Lateral direita#1) → nenhum LED · app: "💡 LED na lateral direita · lado esquerdo"
- P1 fila encostada + aéreos · iso z2 · tocou 0:Lateral direita (Lateral direita#1) → nenhum LED · app: "💡 LED na lateral de gaveta · lado esquerdo"
- P1 fila encostada + aéreos · iso z2 · tocou 1:Frente de gaveta (Frente de gaveta#1) → LED no mód 1 · pk Frente/costa de gaveta (contra-frente e traseira)#1 · face 5 · app: "💡 LED na frente/costa de gaveta (contra-frente e traseira) · em cima"
- P1 fila encostada + aéreos · iso z2 · tocou 0:Porta (Porta#2) → LED no mód 0 · pk Lateral direita#1 · face 2 · não encosta na peça tocada · app: "💡 LED na lateral direita · lado esquerdo"
- P2 aéreo sobre balcão · iso · tocou 1:Porta (Porta#1) → LED no mód 1 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P2 aéreo sobre balcão · iso · tocou 0:Lateral direita (Lateral direita#1) → LED no mód 0 · pk Tamponamento direito · engrosso 80#3 · face 2 · app: "💡 LED na tamponamento direito · engrosso 80 · lado esquerdo"
- P2 aéreo sobre balcão · iso · tocou 0:Porta (Porta#1) → LED no mód 0 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P2 aéreo sobre balcão · front · tocou 1:Porta (Porta#1) → LED no mód 1 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P2 aéreo sobre balcão · front · tocou 0:Porta (Porta#1) → LED no mód 0 · pk Fundo#1 · face 1 · não encosta na peça tocada · app: "💡 LED na fundo · frente"
- P2 aéreo sobre balcão · left · tocou 1:Porta (Porta#2) → LED no mód 1 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"
- P2 aéreo sobre balcão · left · tocou 0:Porta (Porta#1) → LED no mód 0 · pk Lateral esquerda#1 · face 3 · não encosta na peça tocada · app: "💡 LED na lateral esquerda · lado direito"

### Exemplos · LED na peça · PRÉVIA · 3674ecd+b3029da

- P1 fila encostada + aéreos · iso · tocou 5:Lateral esquerda (Lateral esquerda#1) → pediu escolha sem a peça tocada entre as opções
- P1 fila encostada + aéreos · iso · tocou 1:Frente de gaveta (Frente de gaveta#1) → nenhum LED
- P1 fila encostada + aéreos · front · tocou 1:Frente de gaveta (Frente de gaveta#1) → nenhum LED
- P1 fila encostada + aéreos · left · tocou 1:Frente de gaveta (Frente de gaveta#1) → nenhum LED
- P1 fila encostada + aéreos · iso z2 · tocou 1:Frente de gaveta (Frente de gaveta#1) → nenhum LED
- P3 nichos · front · tocou 2:Lateral esquerda (Lateral esquerda#1) → pediu escolha sem a peça tocada entre as opções
- P3 nichos · iso z2 · tocou 1:Fundo (Fundo#1) → pediu escolha sem a peça tocada entre as opções
- P4 canto L + parede lateral · front · tocou 0:Porta (Porta#1) → nenhum LED
- P4 canto L + parede lateral · left · tocou 0:Porta (Porta#2) → nenhum LED

Recusas com aviso (primeiras):

- P1 fila encostada + aéreos · iso · tocou 5:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · iso · tocou 4:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · iso · tocou 3:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · iso · tocou 2:Porta (Porta#2) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · iso · tocou 0:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · front · tocou 3:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · front · tocou 4:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
- P1 fila encostada + aéreos · front · tocou 5:Porta (Porta#1) → "⚠ O LED não cabe nesta face: ela tem 12 mm e o perfil precisa de 12 mm (nada foi criado)."
