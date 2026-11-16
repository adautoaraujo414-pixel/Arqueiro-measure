# Especificação: puxador gola (perfil G)

Status: **geometria aprovada pelo Adauto em 16/11/2026 às 01:26.** Correção implementada no commit desta data (ver `HISTORICO_ERROS.md`, GOLA-001).

Leia antes de mexer em `pxParts` (bloco `t==='g'`) ou na função `G_` do gola lateral/vertical em `app/src/main/assets/editor.html`.

## 1. Referências (enviadas pelo Adauto)

| Data e hora | O que é | Uso |
|---|---|---|
| 11/11/2026 23:54 | Desenho técnico do perfil G: 42 de altura total, 29 acima da MDF, 18 de fundo em cima, encaixe de 15,5 para MDF 15 | Medidas |
| 12/11/2026 00:03 | Foto real de gavetas com o perfil em cima de cada frente (anúncio) | Aparência |
| 12/11/2026 01:30 | Foto do perfil encaixado em cima de uma porta de madeira, com a ponta mostrando o "C" aberto | **Orientação aprovada** |
| 16/11/2026 00:57 | Print do app mostrando o erro (porta vista por dentro, com dobradiça; abertura do perfil virada para dentro) | Erro |

As imagens ficam nos anexos da conversa, não no repositório.

## 2. Geometria aprovada (seção do perfil)

Medidas em mm. `v` é a altura a partir do topo da MDF (para cima +). `w` é a profundidade a partir da face da frente da porta (para fora +). A porta vai de `w = −15` (face de dentro) a `w = 0` (face da frente).

| Peça | v | w | O quê |
|---|---|---|---|
| Parede | −13 … 29 | −16,5 … −15 | Parede de 42 **atrás**, abraça 13 mm da face de dentro da porta |
| Piso | 0 … 1,5 | −16,5 … 0,6 | Apoia no topo da MDF |
| Aba da frente | −5 … 0 | −0,9 … 0,6 | Aba curta que segura a face da frente |
| Aba de cima | 27,5 … 29 | −16,5 … 1,5 | 18 de fundo |
| Gancho | 21 … 29 | 0 … 1,5 | Gancho **na frente**, onde os dedos puxam |

Regras:
- **A abertura dos dedos fica para a frente** (entre o gancho e o piso). Nunca virada para dentro do móvel.
- **Não existe placa fechando o vão.** A ponta do perfil mostra o "C" aberto.
- O comprimento do perfil é igual à largura da porta ou frente. Não passa da peça.
- **Aéreo:** o mesmo perfil vai na borda de baixo (o eixo `v` inverte), com a abertura para a frente.
- **Gola vertical** (porta comum, `px='gv'`) e **gola lateral do editor por vãos** (`p.gl`): é o mesmo perfil em pé, na borda que abre. Usa a mesma seção: parede de 13 + largura do gola atrás, abertura e gancho na frente, sem placa. Largura do gola: `golaW(m)`, que é 30 mm, ou 20 mm em módulo de cozinha com 1500 mm ou mais.

## 3. Fabricação (não mudou com a correção)
- Desconto na altura da porta e da frente: `gDesc = 29`, configurável em Ajustes. 42 − 13 = 29. Exemplos: porta do balcão 705 → 676; frente de gaveta 173,3 → 144,3; aéreo 750 → 721.
- Gola vertical: porta 30 mm mais estreita (410 em vez de 440 no balcão 2 portas).
- Lista de materiais: "Perfil G (no topo)" em metros = soma das larguras das portas e frentes com G. Fica fora do plano de corte (é alumínio). Gola lateral: "Puxador gola lateral (perfil alumínio N mm)" em metros.
- Salvar e reabrir: o perfil continua igual.

## 4. Testes que protegem
- `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical`: lê as peças do 3D em porta, gaveta, aéreo, gola vertical e gola do editor por vãos. Confere 5 peças, uma cor, parede de 42 (ou 43 no vertical) atrás, a maior peça da frente com 8 (o gancho) e 18 de fundo, além de descontos, metros e salvar e reabrir.
  - Na versão errada, o mesmo teste dá `pecas 6 · cores 2 · parede atrás 0 · frente maior 42` e falha.
- `testPuxadoresDescontamCertoEConchaNoMeio`: desconto de 29.
- `testGolaVerticalEHorizontalEDesenhoDeCadaPuxador`: medidas do vertical e do horizontal. Desde 16/11, 10 peças no 3D para 2 portas, porque a placa saiu.
- O teste do gola lateral no armário livre: desde 16/11, 10 peças para 2 portas.

## 5. Pendências (precisam de decisão do Adauto)
1. **O perfil encosta na caixa.** A parede de trás (1,5 mm) fica entre a porta e a caixa, e no 3D entra até 1,5 mm na travessa frontal, nas laterais, na base e na caixa da gaveta. Isso já acontecia antes da correção, em áreas menores: o gancho e a aba ficavam atrás. Na prática, a porta precisa ficar 1,5 mm afastada da caixa, ou a caixa precisa de um rebaixo. Não decidido.
1b. **Configuração (16/11, pedido das 07:03).** Em Ajustes › Puxadores › Perfil G:
   - `gAfast`: afastamento da porta até a caixa, em mm. Padrão 0, que é a porta encostada, como sempre foi.
   - `gReb`: rebaixo na caixa atrás do perfil, em mm. Padrão 0.
   - Uma nota mostra quanto o perfil encosta na caixa: `1,5 − afastamento − rebaixo`.
   - **Afastamento > 0:** no 3D, a porta ou frente com G e o perfil dela vêm para a frente essa medida. Porta sem G não muda. Medidas das peças, desconto de 29 e plano de corte não mudam. Teste: `testPerfilGAfastamentoERebaixoConfiguraveisPadraoZeroSemMudarPecas`.
   - **Rebaixo:** por enquanto só entra na conta da nota. A usinagem do rebaixo **não** sai no plano de corte e **não** aparece no 3D, porque falta definir em quais peças e com qual altura. **Pendente.**
   - **Achado ao medir:** no aéreo, a porta já ficava 0,8 mm dentro da fita de borda da frente das laterais e da base (fita desenhada com 0,8 mm em `z = d … d+0,8`). Isso acontece **sem** gola, então não é do gola. Com afastamento de 1,5, o perfil também encosta 0,8 mm nessa fita. Anotado em `HISTORICO_ERROS.md` (FITA-08). Não corrigido: fora do escopo.
   - **Medidas reais pendentes de confirmação:** a folga da dobradiça que você usa com G e o rebaixo, se existir.
2. **Cantos arredondados.** A foto mostra cantos internos arredondados e a ponta do gancho arredondada. No app são retos. Não alterado.
3. **Tamanho do gancho.** No desenho ele parece ter uns 6 mm, mas não há cota. No app tem 8 mm (valor de 12/11). Não alterado.
4. **Folga do encaixe.** A referência diz encaixe de 15,5 para MDF 15. No app as paredes encostam na MDF. Não alterado.
5. **Desenho de Ajustes.** O esquema de "perfil no topo" em Ajustes é o mesmo para facetado, cava de perfil e G. É um desenho genérico, não a seção do G. Não alterado, porque mexer nele muda os outros puxadores.
6. **Porta de correr** ("Perfil G lateral 35 mm"). É desenhada de outro jeito: uma caixa com um friso escuro na frente. Não foi incluída nesta correção.
7. **"Sobra malfeita"** (print de 00:57). Antes da correção, a ponta do perfil aparecia como um tubo fechado (a placa escura fechava o vão). Depois, aparece o "C" aberto, e o comprimento é igual ao da porta. **Ainda falta o Adauto confirmar se era isso.**

## 6. Histórico
- 31/10 (14bdc37): primeiro perfil G, desenho simplificado.
- 12/11 00:07 (41fab29): "perfil G de verdade" com as medidas da referência, **mas espelhado**: o desenho foi lido com a frente do lado errado (parede de 42 na frente, abertura para dentro, mais uma placa escura de "sombra").
- 12/11 01:28 (b3760c8) e 205603a: gola lateral e gola vertical copiaram a mesma seção espelhada.
- 16/11: corrigido (GOLA-001).
- 16/11 07:45: perfil sólido no 3D (GOLA-002), ver seção 8.

### Detalhe da pendência 1
1. **Perfil encostando na caixa: validado em 16/11 e ainda sem correção.**
   - **Geometria do app:** a porta fechada fica **encostada** na frente da caixa. A face de dentro da porta está em `z = d` (a profundidade do módulo), com folga 0. É assim em todas as portas do app, com ou sem gola.
   - **O que a parede de trás do perfil (1,5 mm) atravessa no 3D:**

     | Peça | Ocorrências | Profundidade | Altura |
     |---|---|---|---|
     | Travessa frontal | 6 | 1,5 mm | até 37 mm |
     | Laterais | 18 + 18 | 1,5 mm | até 42 mm |
     | Laterais de gaveta | 10 | — | até 21,8 mm |
     | Contra-frente | 2 | — | 15,8 mm |
     | Fundo de gaveta | 3 | — | 6 mm |
     | Base inferior | 6 | — | 15 mm |

     Antes da correção da orientação, a profundidade já era a mesma (1,5 mm), com alturas menores: até 26 mm. Medido com o script `pj/golaint.js`.
   - **Referência:** o desenho dá 18 de fundo em cima e encaixe de 15,5. Ou seja, o perfil sai por trás da face de dentro da porta, mais ou menos 1 a 1,5 mm. **No perfil real isso também acontece.** A instalação precisa de uma folga entre a porta e a caixa naquela altura, ou de um rebaixo na caixa.
   - **O Adauto proibiu** (16/11 05:43) mudar sozinho a posição da porta ou as medidas da caixa. Não achei referência técnica (catálogo ou manual do perfil G) que diga a folga ou o rebaixo usado de verdade. Procurei no site da Rometal e não achei.
   - **Pergunta para o Adauto:** na sua marcenaria, com perfil G, a dobradiça deixa a porta afastada da caixa (quantos mm), ou a travessa e as laterais têm rebaixo atrás do perfil?
     - Com a folga da dobradiça: vale para todas as portas com G, mexe na posição da porta e precisa de aprovação.
     - Com o rebaixo: mexe na caixa e no plano de corte, também com aprovação.

## 7. Auditoria de 16/11 às 07:38 (nada foi corrigido)
- **Geometria real:** 5 caixas de alumínio, extrudadas na largura da porta (`pxParts`, bloco `t==='g'`). Seção na tabela da seção 2. Não é textura: são peças 3D com medida.
- **Simplificações:**
  - Cantos retos.
  - Parede de 1,5 mm (espessura não confirmada pela referência).
  - Gancho de 8 mm (não está na referência).
  - Encaixe sem folga: as paredes encostam no MDF.
- **Superfícies:** as 5 peças são do alumínio, na cor escolhida (inox, preto, dourado, bronze, grafite ou branco). O MDF é só a porta, que fica abaixo do piso do perfil e 13 mm por trás da parede.
- **Por que aparece madeira "dentro" do gola:**
  - A porta encosta na caixa (`z = d`). A parede de trás do perfil (1,5 mm) fica dentro da travessa frontal, e a face de dentro da parede fica no **mesmo plano** da frente da travessa.
  - No 3D as duas superfícies disputam o mesmo pixel, e aparecem **listras da madeira da travessa** no fundo da abertura.
  - Prova: com afastamento de 1,5 mm (Ajustes), a mesma vista mostra só alumínio.
  - Causa: **geometria (interferência)**. Não é textura nem câmera.
- **Textura aplicada errada (achado):** `matTx` dá o código 6 ("MDF liso com granulado") às peças do perfil quando a cor é clara (inox ou branco), porque elas têm o nome da porta (`N:Porta`) e cor quase cinza. No 3D aparece como um pontilhado leve no alumínio.
- **Imagens do motor** (sem retoque): frente, de cima, lateral, dentro da abertura (com e sem afastamento), perfil isolado, porta + perfil pela frente e por trás. Corte com medidas desenhado a partir das caixas do 3D.

## 8. Perfil sólido no 3D (pedido de 16/11 às 07:45, GOLA-002)
- **Pedido:** "o puxador é sólido… aberto e fechado sem erro de edição do 3d ao abrir fechar ou encostar no armário". Não pode ficar transparente mostrando a caixa atrás.
- **Causa** (auditoria das 07:38): a parede de trás do perfil fica no mesmo plano da frente da travessa e das laterais (porta encostada, `z = d`). As duas superfícies disputavam o mesmo pixel e apareciam listras da madeira. E o perfil claro recebia o granulado do MDF (`matTx` = 6).
- **Correção (só no desenho do 3D):**
  - As caixas do perfil (`px3`, quando `p.px==='g'` ou `p.gola`) ganham a marca `gola`.
  - Elas vão para um buffer próprio (`GB.g`), desenhado depois das peças opacas com `polygonOffset(-1,-2)`. Onde coincide com a caixa, o alumínio ganha.
  - `matTx` e `woodT` devolvem 0 para `gola`: o alumínio não recebe granulado nem veio.
- **Não mudou:**
  - A geometria do perfil (seção 2).
  - A posição da porta, as medidas da caixa e a folga do caixote.
  - O desconto de 29 mm, a furação das dobradiças, o plano de corte e a lista de materiais.
  - A parede de 1,5 mm continua ocupando o mesmo lugar da travessa no 3D (pendência 1). Só o desenho passou a mostrar o alumínio na frente.
- **Teste:** `testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado`.
  - Na versão anterior: `não · 0 peças de alumínio`.
  - Agora: `sim · 40 peças de alumínio` (balcão 2 portas, gaveteiro 4 gavetas e aéreo 2 portas). Com a porta aberta a 90°, as 5 peças giram com a porta.
- **Evidência:** imagens antes e depois, de perto dentro da abertura, fechada, a 30° e a 90°.
- **Status:** feito e testado no Chromium (testes do gola e do 3D; bateria completa: ver o relatório de 16/11). **Não testado em aparelho real.**

## 9. Dobradiça com gola (pedido de 16/11 às 07:53)
- **Regra dele:** "Dobradiça continua a furação no mesmo lugar não altera 12 cm do topo pra baixo seja cava ou gola".
- **O que o app faz hoje:** a furação fica a `furD` do topo e do pé da porta (Ajustes, padrão 100 mm). É a mesma com puxador externo, cava ou gola.
- **Medido no balcão do catálogo:**
  - Externo e cava: dobradiças a 100 e 605 mm do topo da porta de 705.
  - Gola: dobradiças a 100 e 576 mm do topo da porta de 676.
- **Em aberto:** o padrão do app é 100 mm, e a mensagem fala em 12 cm. Não foi mudado. Falta o Adauto dizer se o padrão passa a ser 120 mm e se o "topo" é o topo da porta (MDF) ou o topo do perfil.
- **Achado ao medir (DOB-3D-FURD):**
  - Mudando a distância do furo em Ajustes (`furD`) para 120, o plano de corte fura a 120 (120 e 585 na porta de 705; 120 e 556 com gola).
  - O 3D continua desenhando a dobradiça a 100: `hinges3` usa `off = 100` fixo, não o `furD`.
  - É o 3D diferente do plano de corte (regra 4 do `CLAUDE.md`). Não corrigido: falta autorização.
  - A correção seria o 3D usar a mesma posição do furo da lista (`p.fur.pos`).
- **Teste que trava a regra:** `testFuracaoDaDobradicaNoMesmoLugarComExternoCavaOuGolaNoCorteENo3D`.
  - Balcão e aéreo, com externo, cava e gola: furo a `furD` das pontas da porta, igual no plano de corte e no 3D.
  - Com 120 em Ajustes: cava e gola furam a 120 no plano de corte. O 3D fica fora desta parte até a correção ser autorizada.
