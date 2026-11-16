# Especificação: textura e geometria da pedra da pia, da cuba e da área molhada

**Status (16/11/2026, 15:15):**
- Defeitos confirmados e causa achada.
- A correção da área molhada está **pela metade** na branch `wip/area-molhada-2026-11-16` (commit `f379a2e`): **não validada, não publicada**.
- O defeito dos cantos do furo da cuba **não foi corrigido**.
- Nada disso está na `feature/arque-measure-kotlin` nem na `main`.
- Ver também a seção 3 de `CHECKPOINT_2026-11-16.md`.

## 0. Pedidos (texto do Adauto, 16/11)
- **14:41:** "Área molhada muito feio o acabamento dessa mancha horrível", com foto do tablet (anexo `e996adc5-image.jpg`). A foto mostra a pedra granito escura e uma placa lisa verde-escura retangular, de cantos arredondados, no meio da pedra.
- **14:42**, resposta à minha pergunta sobre o "15 mm": "15 cm e profundidade da parede, rebaixo da pia área molhada 2 cm pegue referências na intente [internet]".
- **14:56:** pediu pra registrar o comportamento esperado, os defeitos, a causa, os arquivos, o que foi feito e o que falta, e se há problema de alinhamento, material, geometria, recorte ou sincronização 2D/3D. "Não invente problemas não confirmados."
- **15:15:**
  - "As texturas devem respeitar a geometria real da pedra, da cuba e da área molhada, sem alterar dimensões ou criar peças fictícias."
  - Só documentação; não mexer no código.

## 1. Referência técnica (internet, pesquisada em 16/11)
Fonte: Bella Granitos ([tipos de rebaixo](https://www.bellagranitos.com.br/noticia.php?noticia=2) e [qual modelo escolher](https://www.bellagranitos.com.br/noticia.php?noticia=12)).

| Rebaixo | Profundidade | Cantos | Como é feito |
|---|---|---|---|
| **Tradicional** | ~2 cm (ou 1,2 cm em ultracompacto) | retos | peças emendadas |
| **Americano** | ~2 cm (ou 1,2 cm) | arredondados | uma peça inteira colada por baixo |
| **Italiano (usinado)** | ~0,5 cm | arredondados | desbaste na própria pedra |

**Conclusão usada:**
- a área molhada é **a mesma pedra num nível mais baixo, com degrau em volta**;
- não é uma placa de outra cor nem uma camada por cima;
- a fonte não fala de caimento nem de ranhuras.

## 2. Como os dados são hoje (`editor.html`, linhas de `0aa152c`)
**Pedra:** item de `S.stones` com:
- `x` (início na parede), `w` (comprimento), `d` (profundidade);
- `t` (altura do topo de baixo) e `e` (espessura);
- `cor` (`stC(st)`; padrão `#27372c`, Verde Ubatuba);
- `shape`;
- `items` (cubas e cooktops);
- `wet` (área molhada).

**Cuba:** item `{k:'cuba', x, w, d, y, cm}`.
- O modelo vem de `cubM(cm)`: `g` = `emb` (embutir), `sob` (sobrepor), `esc` (esculpida) ou `tq` (tanque).
- Também `lix` (lixeira de embutir).
- As bacias vêm de `cubaBowls(it)`.

**Área molhada:** `st.wet = {on, w, x, c ('curvo'|'reto'), r, dp, d}`.
- `wetRange` (linha ~5565):
  - largura = `max(200, min(st.w, w||900))`;
  - `x` preso dentro da pedra.
- `wetDefault` (linha ~5566):
  - largura = `min(st.w, max(600, cuba.w + 400))`, ou 900 sem cuba;
  - centrada na primeira cuba;
  - `c:'curvo'`, `r:40`, **`dp:8`**.
- `wetGeo` (linha ~5586), em mm:
  - `z1 = max(135, st.d − 35)`: a área molhada para 35 mm antes da frente da pedra;
  - `z0 = max(10, min(z1 − 100, d>0 ? z1 − d : 25))`: por padrão começa 25 mm do fundo;
  - `r` = 10…80 se `curvo`, 0 se `reto`;
  - `dp` = 3…20 (`||8`).
- `wetSet` (linha ~5587) prende os valores:
  - `d` de 100 até `st.d − 45`;
  - `w` de 200 até `st.w`;
  - `x` dentro da pedra;
  - `r` de 10 a 80;
  - `dp` de 3 a 20.
- **Telas:**
  - aba Pedra: `wetHtml` (linha ~7711), botões `data-stwet`, `data-stwin`, `data-stwc`;
  - quadro da pedra no 3D: embrulho do `itRender` (linha ~5577), `data-qwet`, `data-qwin`, `data-qwf`, `data-qwc`.
- **2D:** vista de cima, `wetSvg` (linha ~2297): retângulo azul a 10% com o raio, tirado de `wetGeo`.
- **Resumo pra marmoraria:** `marmHtml` (linha ~7730): "Área molhada rebaixada · L × P mm · rebaixo N mm · cantos …".

## 3. Como o 3D põe textura na pedra (achado no código e conferido por imagem)
- **Placa da pedra:** `stSlab(st,r)` (linha ~3566) faz:
  - uma caixa `'lo'` (só o contorno);
  - as caixas `'stc'` (faces), com recortes retangulares nas bacias da cuba;
  - depois chama `cuba3`.
- **Escolha da textura de cada face** (desenho do 3D, linha ~3780):
  - `tm = (b.g==='st'||b.g==='stc') ? (b.tx || txRGB()[b.c.join()] || 1) : matTx(b)`;
  - **a textura de pedra só vale pro grupo `st`/`stc`**, e o índice é achado pela **cor exata** da peça.
- **Posição da textura:** calculada pela posição no mundo (`uv = vec2(p.x+p.y*.37, p.z+p.y*.61)/420`). Por isso, cortar uma caixa em pedaços **não** faz a textura pular.
- **Prismas** (`BH` → `pfFill`, linha ~3746): só recebem textura de madeira (`woodT`). **Pedra em prisma sai lisa.**
- **Observado ao testar:** mudar a cor de uma peça de pedra em 10% (pra parecer mais funda) fez ela **perder a textura e a foto** e ficar verde e lisa. A textura e a foto ficam presas à cor exata. O caminho completo (`txRGB` × `mid`/`photoT`) **não foi rastreado até o fim**.
  - **Regra prática:** peça que é a mesma pedra tem que ter **a mesma cor** da pedra.

## 4. Comportamento esperado
1. **Mesma pedra:**
   - o fundo da área molhada, a quina do degrau, a ponte entre bacias e os cantos arredondados do furo da cuba têm a cor e a textura da pedra;
   - a textura é contínua, sem pulo na emenda.
2. **Degrau de verdade:**
   - a área molhada fica `dp` mm abaixo do topo;
   - o degrau vai em volta, com cantos retos ou curvados como escolhido;
   - nada flutua acima nem abaixo da pedra.
3. **Medidas iguais às da lista:** o 3D mostra exatamente `wetGeo` (largura, posição, profundidade, raio e rebaixo).
   - Sem esticar, encolher ou limitar sem avisar. Se a medida não for possível, o app avisa (ver a dúvida da seção 7).
4. **Cuba:**
   - a cuba dentro da área molhada fica no nível de baixo: a aba da de sobrepor apoia no fundo rebaixado e a esculpida começa no fundo rebaixado;
   - a cuba fora da área molhada não muda.
5. **Sem peça de mentira:** nada de placa, faixa, fio ou cilindro que não exista na pedra (`CLAUDE.md` 11.5).
6. **2D × 3D:** a vista de cima e o 3D usam a mesma `wetGeo`.
7. **Projeto antigo:** abre igual, sem mudar o `dp` guardado.
8. **Rebaixo novo:** 20 mm (Adauto, 14:42).

## 5. Defeitos confirmados
Reproduzidos no Chromium com imagens geradas pelo próprio editor. As imagens estão em `engenharia/checkpoint-2026-11-16/`.

### AM-1: a área molhada é uma placa lisa, sem a textura da pedra (a "mancha")
- **Reproduzir:**
  - pedra padrão (Verde Ubatuba) com cuba;
  - aba Pedra → "＋ Criar área molhada";
  - abrir o 3D.
- **Antes, em `9f3dc3e` e `0aa152c`:**
  - Verde Ubatuba: placa verde-escura lisa;
  - Branco Siena: placa marrom com riscos.
  - Imagens: `area-molhada-antes-3vistas.png` e a faixa de cima de `area-molhada-pedra-clara-antes-depois-WIP.png`.
- **Causa:** embrulho `var build_wet=build;build=function(){…}` (linha ~5567):
  - faz caixas `bx(…)` com a cor `WC` (cor da pedra × 0,72);
  - sem grupo `stc` e com outra cor, então sem textura (seção 3).

### AM-2: não tem degrau; a "área rebaixada" fica por cima da pedra
- **Causa:** as caixas ficam entre `y1+0,4` e `y1+1,1` (acima do topo `y1`). O rebaixo `dp` não muda a geometria; só aparece no texto do resumo.
- **Evidência:** teste rascunho em `9f3dc3e`: altura da pedra dentro da área molhada = 0 (igual a fora).

### AM-3: cantos e bordas inventados
- **Causa:**
  - cantos curvos feitos com cilindros `cylY(…)` da cor escura;
  - frisos escuros `bx(x0−2,x0,…,'#2b3238')` e `bx(x1,x1+2,…)` **só nos lados esquerdo e direito**, nada na frente nem no fundo.
- Na pedra clara aparecem círculos e linhas. São peças visuais que não existem na pedra.

### AM-4: rebaixo padrão de 8 mm
- **Causa:** `wetDefault` grava `dp:8`. O Adauto pediu 2 cm.

### PIA-1: os cantos arredondados do furo da cuba ficam lisos (sem textura) e mais escuros
- **Reproduzir:** pedra clara (Branco Siena) com cuba de embutir, 3D de perto. Os cantos do fundo do furo aparecem como manchas lisas.
- **Imagem:** `cantos-do-furo-da-cuba-sem-textura.png` (faixas 1 e 2; na pedra preta quase não se vê).
- **Existe em `9f3dc3e`, `0aa152c` e na `wip`.**
- **Causa:** `cornFill` (linha ~4622), chamada por `cuba3` (linha ~4624), faz os cantos com prismas `BH(…)` **sem grupo**, e `pfFill` não põe textura de pedra em prisma.

### Visto e não investigado (não registrar como erro ainda)
Linhas retas finas atravessando a pedra clara de ponta a ponta, perto da frente. Aparecem igual antes e depois. Causa e se é defeito: **desconhecidas**.

### Provável, pela leitura do código, mas sem confirmação visual
- **Cuba esculpida:** as paredes de dentro (`ringW(…, inC=sc)`) e o fundo em rampa (`BP(…, sc)`) usam a cor da pedra **sem grupo `stc`**. Pelo mecanismo da seção 3, devem sair sem textura.
- **Precisa de imagem antes de virar erro.**

## 6. O que a branch `wip/area-molhada-2026-11-16` faz (commit `f379a2e`, só `editor.html`)
- **`stSlab`:**
  - pega a área molhada com `wetSlab(st,y1)`;
  - recorta as caixas `'stc'` da placa com `wetCut(...)`: a parte de dentro desce até `yc = y1 − rebaixo`, as de fora ficam inteiras;
  - nos cantos curvados, põe a pedra de cima por fora do arco (prismas `BH` com grupo `'stc'` e `tx`);
  - cuba com centro dentro da área molhada recebe o topo de baixo: `cuba3(st,it,y0,yC(it))`.
- **`pfFill`:** prisma do grupo `'stc'` recebe a textura da pedra (`stn`). Nenhuma peça antiga usa prisma `'stc'`, então só as novas mudam.
- **`wetDefault`:** `dp:20`. Projeto antigo fica com o dele.
- **O embrulho `build_wet` antigo** (placas, cilindros e frisos) **foi tirado**. Nenhum código lia `b.wet`.
- **`wetEdge`:** fio claro de 3 mm, 0,5 mm acima do topo, em volta do degrau.

**Resultado no Chromium** (teste rascunho; imagem `area-molhada-depois-3vistas-WIP.png`):

| Caso | `9f3dc3e` | `wip` |
|---|---|---|
| Rebaixo criado | 8, sem degrau | 20 |
| Pedra dentro / fora / no fundo da área | 0 / 0 / 0 | −20 / 0 / −20 |
| Placas de outra cor | 10 | 0 |
| Cantos curvos de pedra | 0 | 4 |
| Pedra de 2 cm | — | −15 |
| Antigo com 8 mm | sem degrau | fica 8, degrau de 8 |
| Salvar e reabrir | igual | igual |
| Tirar a área molhada | pedra inteira | pedra inteira |
| Erros de JS | 0 | 0 |

### O que na `wip` **não atende** a regra das 15:15 e precisa mudar antes de juntar
1. **`wetEdge` é peça visual de mentira:** uma faixa de 3 mm por cima da pedra pra imitar a quina polida. Contraria "sem criar peças fictícias".
   - **Trocar por algo que venha da geometria real:** sombra ou contorno das faces do próprio degrau, ou linhas de contorno do recorte (como a caixa `'lo'` faz na borda da pedra).
2. **O rebaixo mostrado é limitado a `espessura − 5`:** com pedra de 20 mm e rebaixo de 20, o 3D mostra 15. Isso **altera a medida sem avisar**.
   - Precisa de decisão (seção 7). Enquanto isso, o certo é mostrar a medida guardada e avisar se ela não cabe.
3. **O teste rascunho tem casos inválidos:**
   - "quadrado" e "rebaixo8" mexem numa pedra de outra cena;
   - "cuba de sobrepor" não foi achada (deu "—"), então a aba no nível de baixo **não está comprovada**;
   - o resumo é `marmHtml`, não `stResumo`.

## 7. Alinhamento, material, geometria, recorte e sincronização
Resumo do que se sabe, sem inventar.

| Tema | Situação |
|---|---|
| **Material/textura** | AM-1 e PIA-1 confirmados. Esculpida provável (não confirmada). A textura presa à cor exata foi observada |
| **Geometria** | AM-2 (sem degrau) e AM-4 (8 mm) confirmados |
| **Alinhamento** | AM-3: frisos só nos lados, cilindros nos cantos. Na `wip` os cantos batem com o raio de `wetGeo` no caso testado (4 cantos, cuba no meio). Outros casos **não verificados** |
| **Recortes** | A `wip` pula canto e faixa onde cai a cuba. **Não verificado:** área molhada encostada na ponta da pedra, pedra em L e U, duas cubas, lixeira de embutir dentro da área molhada |
| **2D × 3D** | A vista de cima (`wetSvg`) e o 3D usam a mesma `wetGeo`: largura, posição e raio batem. **Não foi achado erro de sincronização.** O 2D não mostra o degrau (não houve pedido) |
| **Rebaixo maior que a pedra** | **Decisão do Adauto:** no rebaixo americano a área molhada é outra peça colada por baixo; o app hoje tem uma espessura só (`e`). Mostrar a pedra mais grossa, avisar, ou limitar o campo? |
| **Campo "Rebaixo (mm)"** | **Decisão do Adauto:** continua de 3 a 20, ou fixo em 20? |

## 8. Persistência
- `st.wet` vai junto com a pedra em `S.stones` (salvo por `snapState`).
- Nenhum campo novo foi criado na `wip`.
- **Projeto antigo:** mantém o `dp` dele (8); o 3D passa a mostrar o degrau desse tamanho. **Confirmar com o Adauto** se isso é aceitável, porque o visual muda sem mudar o dado.
- **Salvar e reabrir:** testado na `wip`, ficou igual. Duplicar e desfazer não foram testados.

## 9. Arquivos e funções
- `app/src/main/assets/editor.html`:
  - pedra e cuba: `stSlab`, `cuba3`, `cornFill`, `lix3`, `cubM`, `cubaBowls`;
  - textura: `pfFill`, `BH`, `B`/`bx`, o desenho das faces (linha ~3780), `txRGB`, `photoT`;
  - área molhada: `wetOf`, `wetRange`, `wetDefault`, `wetGeo`, `wetSet`, `wetHtml`, o embrulho do `itRender`, `wetSvg`, `marmHtml`;
  - só na `wip`: `wetSlab`, `wetCut`, `wetEdge`.
- **Teste:** `ios/ArquemestreTests/EditorWebKitTests.swift`. **Hoje não tem nenhum teste de área molhada** (busca por `wet|molhad`: 0). 22 testes têm cuba no 3D.
- **Ferramentas:**
  - na `feature`: `engenharia/ferramentas/`;
  - na `wip`: `engenharia/wip/area-molhada/` (teste rascunho, script de foto do 3D, imagens, saídas).

## 10. Testes necessários (cada um falha na versão com defeito e passa depois)
1. **Área molhada criada pela aba Pedra e pelo quadro do 3D:**
   - `dp = 20`;
   - pedra dentro = topo − 20, fora = topo;
   - nenhuma peça de outra cor na área;
   - nenhuma peça fora da geometria real.
2. **Textura:** todas as peças da área molhada e do degrau com o grupo e a cor da pedra, testado com Verde Ubatuba, Preto São Gabriel e uma pedra clara.
3. **Cantos:**
   - curvados: raio igual ao de `wetGeo`;
   - retos: sem peça de canto.
4. **Cuba** de embutir, de sobrepor, esculpida, tanque e lixeira, dentro e fora da área molhada: nível certo e furo no lugar.
5. **Cantos do furo da cuba com a textura da pedra (PIA-1)**, em pedra clara.
6. **Recortes:**
   - área molhada na ponta da pedra;
   - pedra em L e U;
   - duas cubas;
   - cooktop ao lado.
7. **Medidas:** mudar largura, posição, profundidade, raio e rebaixo pelos dois quadros. O 3D acompanha e o 2D (`wetSvg`) bate.
8. **Projeto antigo** com `dp` 8: abre com 8, nada muda no dado.
9. **Salvar, fechar e reabrir; duplicar a pedra; desfazer e refazer.**
10. **Resumo pra marmoraria** com o rebaixo certo.
11. **Os 22 testes com cuba no 3D e a bateria completa** (Chromium, Windows e iOS).
12. **Comparação visual com a foto e com a referência**, mostrada ao Adauto.

## 11. Critérios de aceitação
- [ ] A área molhada é a mesma pedra (cor e textura), rebaixada exatamente o `dp` guardado, com degrau real; nenhuma mancha.
- [ ] Nenhuma peça fictícia: o `wetEdge` da `wip` foi trocado por algo que vem da geometria.
- [ ] Nenhuma medida alterada sem aviso.
- [ ] Cantos do furo da cuba com a textura da pedra.
- [ ] Cuba dentro da área molhada no nível certo, comprovado em teste.
- [ ] O 2D e o 3D com as mesmas medidas.
- [ ] Projeto antigo igual no dado.
- [ ] Salvar e reabrir igual.
- [ ] Testes novos na bateria, bateria completa passando, comparação visual aprovada pelo Adauto.
- [ ] Nada publicado sem o "sim" dele.
