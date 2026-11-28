# ETAPA 3.1 · régua da seleção no 3D (sonda s54) · ANTES

Código: **5067fec** (publicado). Janela 1366×768, Chromium headless com SwiftShader. Catálogo inteiro (cada modelo sozinho) + 5 projetos (fila encostada com aéreos, aéreo sobre balcão, nichos, canto L + parede lateral, canto cego + parede lateral). 3 ângulos (isométrica, frente, lado) × 3 zooms (1×, ~2,6×, ~6,7×). Rodar: `python3 tools/sondas/rodar.py tools/sondas/s54_selecao_3d.js --porta P --url URL > r.json` e `python3 tools/sondas/s54_tabela.py r.json --rotulo X [--comparar ANTES.json --rotulo2 Y]`.

- **Verdade:** a caixa do 3D mais perto do olho no ponto da tela. O toque é no ponto visível da peça mais perto do centro dos pontos visíveis dela, pelo `__sel3` (o mesmo caminho do toque duplo). Antes de cada toque: seleção limpa, mesma câmera e mesmo projeto.
- **Inequívoco:** nenhum ponto de outra peça a até 12 px do toque. A meta de 100% vale aqui.
- **Peça pequena:** menos de 600 px² visíveis.

| Métrica | ANTES · 5067fec |
|---|---|
| (1) acerto na seleção (todas as peças visíveis) | 59.3% (6238/10513) |
| (1b) acerto nos toques inequívocos (meta 100%) | 79.1% (1867/2359) |
| (2) seleções no módulo vizinho | 45 |
| (2b) toque que não selecionou nada | 56 |
| (3) acerto · zoom 1× | 55.4% (2761/4988) |
| (3) acerto · zoom ~2,6× | 63.6% (2804/4409) |
| (3) acerto · zoom ~6,7× | 60.3% (673/1116) |
| (3b) inequívocos · zoom 1× | 85.2% (496/582) |
| (3b) inequívocos · zoom ~2,6× | 82% (952/1161) |
| (3b) inequívocos · zoom ~6,7× | 68% (419/616) |
| (3c) acerto · isométrica | 64.1% (2150/3355) |
| (3c) acerto · frente | 73.9% (2233/3022) |
| (3c) acerto · lado | 44.9% (1855/4136) |
| (4) acerto em peças pequenas (< 600 px² visíveis) | 45.7% (2527/5530) |
| (5) tempo do toque · p50 (ms) | 4.2 |
| (5) tempo do toque · p95 (ms) | 10.5 |
| (5) tempo do toque · máximo (ms) | 50.8 |
| (6) LED · módulo certo (onde o app aceita LED) | 100% (5/5) |
| (6) LED · encosta na peça tocada | 100% (5/5) |
| (6) LED · recusado pela regra atual | 13 (app: "LED vai só nos módulos de cima e na cristaleira") |
| destaque: acende só a peça escolhida | 46.9% (4905/10457) |
| toque que mudou o projeto sozinho | 0 |
| ids · caixa do 3D sem pk (peça) | 0 |
| ids · ferragem marcada (b.ferr, conta como identificada) | 0 |
| ids · ferragem só pelo nome (sem pk e sem b.ferr) | 486 |
| ids · pk repetido no partsOf | 0 |
| ids · pk em caixas de 2 peças | 0 |
| ids · peça desenhável sem caixa no 3D | 16 |

Tempo da sonda: 2667 s.

### Acerto por cenário (ANTES · 5067fec)

| Cenário | Acerto |
|---|---|
| CAT Balcão 2 portas | 63.8% (37/58) |
| CAT Balcão 1 porta | 42.3% (22/52) |
| CAT Balcão da pia (cuba) | 72% (36/50) |
| CAT Gaveteiro 3 gavetas | 59% (49/83) |
| CAT Gaveteiro 4 gavetas | 69% (69/100) |
| CAT Balcão porta + gavetas | 63.6% (63/99) |
| CAT Porta-tempero | 25% (11/44) |
| CAT Balcão forno embutido | 60.9% (39/64) |
| CAT Balcão aberto (prateleira) | 59.4% (38/64) |
| CAT Balcão 2 gavetas | 65.7% (46/70) |
| CAT Balcão 2 portas + 4 gavetas | 62.8% (76/121) |
| CAT Balcão 2 portas + 8 gavetas (gaveteiro nas duas pontas) | 73% (130/178) |
| CAT Balcão 3 portas + 4 gavetas | 64% (80/125) |
| CAT Balcão com laterais até o piso | 66% (31/47) |
| CAT Balcão sem lateral direita (usa a do vizinho) | 66% (35/53) |
| CAT Balcão sem laterais (entre dois módulos) | 66.7% (32/48) |
| CAT Aéreo 2 portas | 78.3% (36/46) |
| CAT Aéreo 1 porta | 74.4% (29/39) |
| CAT Aéreo basculante | 78% (32/41) |
| CAT Aéreo nicho aberto | 75% (33/44) |
| CAT Cristaleira (porta de vidro) | 77.1% (37/48) |
| CAT Aéreo sobre geladeira | 82.6% (38/46) |
| CAT Aéreo com divisória | 78.3% (36/46) |
| CAT Aéreo sem lateral direita (usa a do vizinho) | 79.5% (35/44) |
| CAT Canto em L (aéreo) | 97.2% (103/106) |
| CAT Balcão canto cego | 70.1% (94/134) |
| CAT Aéreo canto cego | 80% (88/110) |
| CAT Armário alto 2 portas | 50% (29/58) |
| CAT Despenseiro | 43.9% (25/57) |
| CAT Torre quente (forno) | 40.5% (30/74) |
| CAT Torre forno + micro-ondas (embutir) | 42.5% (37/87) |
| CAT Torre forno + nicho aberto do micro-ondas | 44.7% (38/85) |
| CAT Torre micro-ondas de embutir (sem forno) | 43.2% (32/74) |
| CAT Torre nicho aberto do micro-ondas | 45% (36/80) |
| CAT Torre só os nichos (forno e micro-ondas) | 46.1% (35/76) |
| CAT Caixa da geladeira side by side (laterais + aéreo) | 38.6% (17/44) |
| CAT Caixa da geladeira duplex / inverse (laterais + aéreo) | 28.6% (12/42) |
| CAT Torre por vãos | 35.1% (65/185) |
| CAT Nicho com prateleiras | 48.9% (44/90) |
| CAT Torre para eletros com laterais até o piso | 44.7% (34/76) |
| CAT Armário alto livre | 46.3% (25/54) |
| CAT Guarda-roupa 2 vãos | 53.4% (39/73) |
| CAT Guarda-roupa 3 vãos | 60.4% (58/96) |
| CAT Guarda-roupa porta de correr | 50% (54/108) |
| CAT Torre do guarda-roupa | 50% (29/58) |
| CAT Torre de prateleiras do guarda-roupa | 48.1% (25/52) |
| CAT Maleiro (sobre o armário) | 82.9% (34/41) |
| CAT Cômoda 4 gavetas | 76.2% (80/105) |
| CAT Criado-mudo 2 gavetas | 51.5% (35/68) |
| CAT Sapateira | 75.3% (70/93) |
| CAT Guarda-roupa 4 vãos (2 cabideiros + torre de gavetas) | 65.3% (94/144) |
| CAT Guarda-roupa casal 3 vãos com gaveteiro (caixote) | 55.4% (51/92) |
| CAT Guarda-roupa de correr com torre por dentro | 52.7% (29/55) |
| CAT Closet aberto | 49.5% (104/210) |
| CAT Sapateira torre 1 porta | 37.7% (20/53) |
| CAT Escrivaninha do quarto com gavetas | 71.7% (71/99) |
| CAT Armário livre | 48.8% (80/164) |
| CAT Gabinete 2 portas | 73.3% (33/45) |
| CAT Gabinete com gavetas | 68.6% (35/51) |
| CAT Espelheira | 72.7% (32/44) |
| CAT Gabinete suspenso 2 gavetas | 78.8% (41/52) |
| CAT Gabinete 1 porta + gavetas | 63.6% (49/77) |
| CAT Torre do banheiro (armário alto) | 44.4% (24/54) |
| CAT Nicho de banheiro (aberto) | 65% (26/40) |
| CAT Armário livre do banheiro | 37.5% (21/56) |
| CAT Rack de TV | 66% (62/94) |
| CAT Rack do zero (você monta) | 67.1% (49/73) |
| CAT Rack com portas basculantes | 64% (48/75) |
| CAT Rack suspenso | 68.3% (82/120) |
| CAT Aparador / buffet | 68.2% (45/66) |
| CAT Estante com porta de correr | 68.2% (45/66) |
| CAT Estante aberta | 48.9% (44/90) |
| CAT Módulo superior livre (nicho aberto) | 76.9% (60/78) |
| CAT Buffet 3 portas | 74% (54/73) |
| CAT Aparador suspenso 2 gavetas | 74.4% (29/39) |
| CAT Rack 2 portas + 2 gavetas | 66.4% (81/122) |
| CAT Módulo livre baixo | 82.5% (47/57) |
| CAT Gaveteiro de escrivaninha | 52.9% (45/85) |
| CAT Armário baixo 2 portas | 62.1% (36/58) |
| CAT Armário de correr (arquivo) | 68.2% (45/66) |
| CAT Nicho aéreo | 76.6% (36/47) |
| CAT Caixa livre vazia | 63.2% (36/57) |
| CAT Estante de livros alta | 53.3% (48/90) |
| CAT Armário alto 2 portas (arquivo) | 44.1% (26/59) |
| CAT Gaveteiro volante 3 gavetas | 50.6% (40/79) |
| CAT Escrivaninha com gaveteiro | 68.8% (66/96) |
| CAT Rack suspenso basculante | 71.4% (60/84) |
| CAT Nicho (caixa aberta) | 76.6% (36/47) |
| CAT Guarda-roupa correr 3 folhas | 47.7% (31/65) |
| CAT 1P+Gav Ext 300mm | 15.4% (12/78) |
| CAT 2P 600mm | 44.8% (26/58) |
| CAT 2P c/ Cab 600mm | 44.8% (26/58) |
| CAT 2P c/ Cab+Gav Int 600mm | 44.8% (26/58) |
| CAT 2P+Gav Ext 600mm | 37.9% (36/95) |
| CAT Bifold 2F 700mm | 40.4% (23/57) |
| CAT Bifold 3F 1000mm | 43.1% (28/65) |
| CAT 1 Vão 600mm | 48.4% (30/62) |
| CAT 2 Vãos 1600mm | 57.3% (55/96) |
| CAT 3 Vãos 2400mm | 58.6% (68/116) |
| CAT Armário sem lateral direita (usa a do vizinho) | 51.8% (29/56) |
| CAT Armário sem laterais (entre dois armários) | 50.9% (29/57) |
| CAT Canto L guarda-roupa | 55.6% (70/126) |
| CAT Canto reto (CR) | 51.7% (140/271) |
| CAT Fechamento até o teto (maleiro) 600mm | 78.9% (30/38) |
| CAT Fechamento até o teto (maleiro) 900mm | 85.4% (35/41) |
| CAT Fechamento livre | 87.9% (29/33) |
| CAT Sapateira 2P 600mm | 44.8% (26/58) |
| CAT Gaveteiro interno 2P 800mm | 42.1% (24/57) |
| CAT Porta de correr 2F 1800mm | 50% (27/54) |
| CAT Penteadeira com gavetas 1000mm | 75% (72/96) |
| CAT Nicho aberto 600 × 350 | 76.6% (36/47) |
| CAT Gaveteiro com caixote (4 gavetas dentro) | 45.8% (27/59) |
| CAT Armário especial livre | 46.3% (25/54) |
| CAT Cantoneira reta 300mm (prateleiras abertas) | 15% (12/80) |
| CAT Cantoneira reta 400mm (prateleiras abertas) | 22.5% (20/89) |
| CAT Cantoneira livre | 23.5% (12/51) |
| CAT Passagem (ponte sobre a porta) 800mm | 79.5% (31/39) |
| CAT Passagem (ponte sobre a porta) 1000mm | 82.5% (33/40) |
| CAT Passagem aberta (nicho) 900mm | 82.5% (33/40) |
| CAT Passagem livre | 82.4% (28/34) |
| CAT Torre da sala | 40.9% (45/110) |
| CAT Armário de casacos da sala | 50% (29/58) |
| CAT Guarda-roupa de sala 2 vãos (cabideiro + prateleiras) | 50% (36/72) |
| CAT Armário alto de correr da sala (2 folhas) | 45.3% (24/53) |
| CAT Cristaleira torre (porta de vidro) | 46.3% (25/54) |
| CAT Bar da sala | 48.3% (28/58) |
| CAT Estante torre aberta com gavetas embaixo | 38% (62/163) |
| CAT Armário livre da sala | 49.1% (27/55) |
| P1 fila encostada + aéreos | 91.3% (253/277) |
| P2 aéreo sobre balcão | 64.2% (70/109) |
| P3 nichos | 63% (136/216) |
| P4 canto L + parede lateral | 84% (179/213) |
| P5 canto cego + parede lateral | 82.5% (127/154) |

(cenários com 100% ficam fora da lista: 0 de 133)

### Exemplos de erro (primeiros 40, ANTES · 5067fec)

| Cenário · vista | Peça no ponto | px² | Toque (x,y) | Selecionou | Destaque | Inequívoco |
|---|---|---|---|---|---|---|
| CAT Balcão 2 portas · iso z1 | 0:Tamponamento direito (Tamponamento direito#1) | 288 | [489, 453] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · iso z1 | 0:Lateral direita (Lateral direita#1) | 144 | [477, 429] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · iso z1 | 0:Porta (Porta#2) | 1512 | [471, 459] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 2 portas · iso z1 | 0:Porta (Porta#1) | 1872 | [441, 465] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | sim |
| CAT Balcão 2 portas · iso z1 | 0:Base inferior (Base inferior#1) | 29 | [425, 498] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | não |
| CAT Balcão 2 portas · iso z1 | 0:Travessa frontal (Travessa frontal#1) | 10 | [419, 449] | 0:Travessa frontal#1 | acende outra:  | não |
| CAT Balcão 2 portas · iso z2 | 0:Lateral direita (Lateral direita#1) | 1224 | [147, 567] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 2 portas · iso z2 | 0:Porta (Porta#2) | 7308 | [147, 627] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 2 portas · iso z2 | 0:Travessa frontal (Travessa frontal#1) | 64 | [12, 628] | 0:Travessa frontal#1 | acende outra:  | não |
| CAT Balcão 2 portas · iso z2 | 0:Porta (Porta#1) | 5616 | [63, 639] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | sim |
| CAT Balcão 2 portas · front z1 | 0:Porta (Porta#1) | 1944 | [399, 399] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | sim |
| CAT Balcão 2 portas · front z1 | 0:Tamponamento direito (Tamponamento direito#1) | 648 | [453, 399] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z1 | 0:Rodapé lateral direito (pedestal) (Rodapé lateral direito (pedestal)#1) | 37 | [455, 430] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z1 | 0:Lateral direita (Lateral direita#1) | 45 | [450, 403] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z1 | 0:Travessa frontal (Travessa frontal#1) | 8 | [450, 378] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z2 | 0:Porta (Porta#1) | 828 | [3, 501] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | não |
| CAT Balcão 2 portas · front z2 | 0:Tamponamento direito (Tamponamento direito#1) | 3240 | [99, 501] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z2 | 0:Rodapé lateral direito (pedestal) (Rodapé lateral direito (pedestal)#1) | 216 | [99, 573] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · front z2 | 0:Lateral direita (Lateral direita#1) | 117 | [91, 508] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Porta (Porta#1) | 252 | [591, 369] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | não |
| CAT Balcão 2 portas · left z1 | 0:Porta (Porta#2) | 252 | [597, 369] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Tamponamento direito (Tamponamento direito#1) | 1728 | [615, 369] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 2 portas · left z1 | 0:Rodapé (pedestal) (Rodapé (pedestal)#1) | 62 | [597, 395] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Base inferior (Base inferior#1) | 1 | [596, 393] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Rodapé lateral direito (pedestal) (Rodapé lateral direito (pedestal)#1) | 144 | [615, 399] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Fundo (Fundo#1) | 52 | [625, 349] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Lateral esquerda (Lateral esquerda#1) | 125 | [606, 348] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z1 | 0:Rodapé traseiro (pedestal) (Rodapé traseiro (pedestal)#1) | 6 | [631, 396] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z2 | 0:Fundo (Fundo#1) | 432 | [543, 369] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z2 | 0:Porta (Porta#1) | 1980 | [453, 417] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | não |
| CAT Balcão 2 portas · left z2 | 0:Porta (Porta#2) | 1476 | [471, 429] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z2 | 0:Tamponamento direito (Tamponamento direito#1) | 10800 | [525, 429] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 2 portas · left z2 | 0:Rodapé (pedestal) (Rodapé (pedestal)#1) | 504 | [471, 489] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z2 | 0:Rodapé traseiro (pedestal) (Rodapé traseiro (pedestal)#1) | 31 | [561, 491] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 2 portas · left z3 | 0:Porta (Porta#1) | 12960 | [93, 537] | 0:Porta#1 | acende outra: 0:Travessa frontal|Travessa frontal#1, 0:Porta|Porta#1, 0:Porta|Porta#1 | sim |
| CAT Balcão 2 portas · left z3 | 0:Tamponamento direito (Tamponamento direito#1) | 57384 | [279, 549] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 1 porta · iso z1 | 0:Lateral direita (Lateral direita#1) | 216 | [441, 435] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 1 porta · iso z1 | 0:Porta (Porta#1) | 1836 | [441, 465] | 0:Tamponamento direito#1 | acende outra:  | sim |
| CAT Balcão 1 porta · iso z1 | 0:Rodapé (pedestal) (Rodapé (pedestal)#1) | 180 | [435, 495] | 0:Tamponamento direito#1 | acende outra:  | não |
| CAT Balcão 1 porta · iso z1 | 0:Travessa frontal (Travessa frontal#1) | 6 | [419, 448] | 0:Travessa frontal#1 | acende outra:  | não |

### Ids (exemplos)

- CAT Torre por vãos · forno + micro com porta de recorte · mód 0 · peça sem caixa no 3D: Frente com recorte do micro-ondas#1
- CAT Torre por vãos · forno + micro com porta de recorte · mód 0 · peça sem caixa no 3D: Frente com recorte do forno#1
- P1 fila encostada + aéreos · mód 1 · peça sem caixa no 3D: Base inferior#1
- P1 fila encostada + aéreos · mód 1 · peça sem caixa no 3D: Rodapé (pedestal)#1
- P1 fila encostada + aéreos · mód 1 · peça sem caixa no 3D: Rodapé traseiro (pedestal)#1
- P1 fila encostada + aéreos · mód 2 · peça sem caixa no 3D: Rodapé (pedestal)#1
- P1 fila encostada + aéreos · mód 2 · peça sem caixa no 3D: Rodapé traseiro (pedestal)#1
- P3 nichos · mód 2 · peça sem caixa no 3D: Base inferior#1
- P3 nichos · mód 2 · peça sem caixa no 3D: Rodapé (pedestal)#1
- P3 nichos · mód 2 · peça sem caixa no 3D: Rodapé traseiro (pedestal)#1
- P3 nichos · mód 3 · peça sem caixa no 3D: Base inferior#1
- P3 nichos · mód 3 · peça sem caixa no 3D: Rodapé (pedestal)#1
- P3 nichos · mód 3 · peça sem caixa no 3D: Rodapé traseiro (pedestal)#1
- P5 canto cego + parede lateral · mód 2 · peça sem caixa no 3D: Base inferior#1
- P5 canto cego + parede lateral · mód 2 · peça sem caixa no 3D: Rodapé (pedestal)#1
- P5 canto cego + parede lateral · mód 2 · peça sem caixa no 3D: Rodapé traseiro (pedestal)#1

## Achados (para o Claude 4 e o Claude 3; nada foi corrigido pela sonda)
1. **Tamponamento puxa o toque:** em muitos toques de lateral, rodapé, fundo, frente de gaveta e travessa, o app seleciona o *Tamponamento direito*. É o `tampNear`, que pega o tamponamento até 6 px em volta do toque (18 px quando o toque não acha peça), mesmo com outra peça embaixo do dedo.
2. **Destaque:** o tamponamento selecionado não acende nenhuma caixa. A porta selecionada acende junto a travessa frontal.
3. **Batente:** o toque no *Batente* seleciona o pk do *Batente (cava)*.
4. **Erro comprovado:** selecionar o tamponamento e tocar de novo nele move o módulo 750 mm sozinho (x 5 → 755, Balcão 2 portas, livre, iso). Fere o §12.
5. **LED no módulo:** recusado nos balcões pela regra atual ("só módulos de cima e cristaleira"). Nos aéreos acertou módulo e peça (5/5).
6. **Ids:** nenhuma peça sem pk. As 486 caixas sem pk são ferragem (corrediça etc.) sem a marca `b.ferr`, que entrou depois do 5067fec. As 16 peças desenháveis sem caixa própria no 3D são rodapé/base de corridas, desenhados pelo 1º módulo da corrida, e a frente com recorte do forno/micro-ondas.

### Correção da conta "peça desenhável sem caixa no 3D" (28/11, nota do Claude 3)

A conta passou de 16 para 14 no 5067fec.

- **Antes:** a conta ignorava caixas marcadas `nol` (moldura sem contorno). Por isso as 2 Frentes com recorte (Torre por vãos) apareciam como sem caixa, mas elas têm caixa.
- **Agora:** caixa `nol` conta como caixa desenhada.
- **Rodada:** `window.__S54={so:'ids'}`, catálogo inteiro e P1–P5. Arquivo: `s54_ANTES_5067fec_ids.json`.
- **As 14 que sobram** são Base inferior e Rodapé dos módulos de baixo. O 3D desenha essas peças como corrida contínua da base e do rodapé, e não com caixa própria.
