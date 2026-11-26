# Referências do Adauto

As imagens ficam nos anexos das conversas, não no repositório. Aqui fica o que cada uma define e se foi analisada.

## Puxador gola (perfil G). Ver `especificacoes/puxador-gola.md`
| Data e hora | Conteúdo | Analisada |
|---|---|---|
| 11/11 23:54 | Desenho técnico do perfil G (42 / 29 / 18 / 15,5) | Sim (16/11) |
| 12/11 00:03 | Foto de gavetas com perfil G (anúncio) | Sim. Foto desfocada: confirma o perfil em cima de cada frente; o lado da abertura não dá para ver com certeza |
| 12/11 01:30 | Foto do perfil na porta, mostrando a ponta | Sim. **Define a orientação**: abertura para o lado da face da frente |
| 12/11 01:19, 01:21, 01:23 | Prints do "Puxador gola lateral" no editor por vãos | Sim (só a tela) |
| 15/11 12:28 | Print de aéreos com perfil embaixo (PEDIDO 51) | Sim |
| 16/11 00:57 | Print do erro: porta vista por dentro, abertura para dentro | Sim |

## Outras referências desta conversa (de 02/11 a 16/11)
- No total são 435 imagens e alguns vídeos e PDFs (catálogos Duratex, Arauco e lançamentos 2026).
- Em 16/11, todas as imagens foram vistas em miniatura, procurando o gola. Só as da tabela acima eram sobre o gola.
- **As outras não foram analisadas em detalhe** e não valem como especificação verificada até serem analisadas para um pedido.
- Os vídeos não foram analisados quadro a quadro. Exceção: o de 12/11 00:16, que é de painéis e não de gola.
- Há imagens de tela de segredos (chaves) de 02/11. **Não reproduzir em lugar nenhum.**

## Conversas anteriores
- As conversas de outubro (Star Note, Arque Measure e os primeiros puxadores) só podem ser buscadas por texto. As fotos delas não estão acessíveis.
- Commits que citam fotos dessa época: 660582b ("cava de perfil com a foto dela") e 14bdc37 ("puxadores com foto real… perfil G 35 mm"). Essas fotos não foram reencontradas.

## Régua do batente do puxador cava (Adauto, 17/11)
- **Imagem:** print do 3D do app enviado na conversa de 17/11 (não gravado no repositório, que é público).
- **O que mostra:** gaveteiro com 4 gavetas abertas, frentes puxadas para a esquerda, caixas brancas com corrediças. As **placas cinza na frente**, uma por nível de gaveta, deitadas na largura do vão até a lateral, são as "réguas de batente do cava" que o Adauto quer poder medir à mão.
- **Leitura técnica (a confirmar com o Adauto):** são as peças `Batente (cava)` (entre gavetas) e, em cima, `Batente superior (cava)`. Na imagem há 4 placas para 4 gavetas, mas o app gera 3 entre gavetas mais a de cima só com o batente superior ligado.
- **Sem escala na imagem:** nenhuma medida foi tirada dela.
- **Proposta ligada:** `engenharia/PROPOSTA_BATENTE_CAVA.md`.

## Tamponamentos editáveis e laterais descendentes (Adauto, 17/11) — na fila, nada implementado
- **Material recebido:** três miniaturas (vídeo de 0:07, print do painel, desenho à mão) e o desenho em foto inteira. **O vídeo não chegou**, só a miniatura: pedir de novo antes de implementar. Nada gravado no repositório, que é público.
- **Vídeo (miniatura):** 2D de um balcão de 900 × 820 com o tamponamento superior escolhido (contorno vermelho em cima) e as laterais azuis.
- **Print do painel:** seções "Tamponamento direito" (Usar · Aumentar pra baixo (mm) · Inverter), "Tamponamento superior do módulo" (Usar, passa reto em cima, 30 mm · Inverter), "Tamponamento inferior do módulo" e "Peças de tamponamento". Peça mostrada: 820 × 585 · prof. 560 + 25 = 585.
- **Desenho à mão:** um módulo (portas com puxador) com uma peça em cima e uma peça que desce do lado direito até o chão, deixando um espaço do lado do armário. Anotações à mão: "60 + (47 interno…)", "46", "87 todo", "4,7"…, "Duratex" e um nome de cor. **Sem escala e com leitura incerta: nenhuma medida foi tirada.** A confirmar com o Adauto o que cada número quer dizer.
- **Leitura do pedido (a confirmar):** a lateral descendente sai de baixo do tamponamento superior, numa das pontas, e desce até a medida escolhida, formando um nicho/vão ao lado do módulo; o app mostra a medida livre real desse vão.
- **Pedido completo:** "ARQUEMESTRE — TAMPONAMENTOS EDITÁVEIS E LATERAIS DESCENDENTES" (17/11): 2 toques no tamponamento no 3D com ajuste numérico e fino de 1 mm; no "Tamponamento superior do módulo": descer lateral esquerda/direita com altura; "Mostrar vão livre" no 2D e no 3D; plano de corte com identidade estável (PC-ID); salvar modelo; desfazer; só módulos inferiores compatíveis; 15 testes obrigatórios.
- **Fila:** depois dos itens já aprovados (1 P0 · 2 iOS · 3 Fase 3 · 4 Plano de Corte · 5 lateral inteira com gavetas · 6 ajustes 3D por 2 toques · 7 estrutura paramétrica), branch própria. Primeiro passo: investigar a geometria atual dos tamponamentos (`tlAdj`/`trAdj`, `tbL`/`tbR`, `tt`, tamponamento superior "passa reto") e se a descida é extensão do tamponamento lateral existente ou peça nova, sem gerar peça duplicada.

## Dois toques com a câmera afastada escolhem e movem o MÓDULO inteiro (Adauto, 17/11) — na fila, nada implementado
- **Pedido:** com a câmera um pouco afastada, 2 toques no móvel escolhem o módulo inteiro (destaque discreto); 2 toques em outro lugar válido movem o módulo inteiro, sem desmontar, redimensionar, apagar ou mudar peça. Câmera perto: peças individuais como hoje. Decidir pelo zoom e pela geometria real do módulo (tamanho dele na tela), não por distância fixa. Não pegar vizinho. 2D, 3D e coordenadas atualizados; plano de corte e cálculos iguais.
- **Fila:** soma-se ao pedido de mover por 2 toques já registrado; depois das prioridades aprovadas, branch própria, 3 plataformas.

## Biblioteca: completar "Cantos e cozinha em L" com 8 modelos (Adauto, 17/11) — na fila, nada implementado
- **Imagem citada no pedido: não chegou.** Pedir de novo antes de implementar.
- **O que já existe hoje (conferido no código, sem mudar nada):**
  - em "◣ Cantos e cozinha em L": Canto em L (baixo) · esquerdo/direito e Canto em L (aéreo) · esquerdo/direito (os 4 de canto em L já existem);
  - em outra categoria de cantos (acrescentados por código, `CG(...)`): Balcão canto cego · cego na direita (porta na esquerda) / cego na esquerda (porta na direita), e Aéreo canto cego · cego na direita / cego na esquerda.
- **Leitura (a confirmar):** os 8 modelos parecem existir; falta reuni-los na categoria "Cantos e cozinha em L" na ordem pedida (L: inferiores e depois aéreos; cego: inferiores e depois aéreos), com os nomes pedidos, sem duplicar, e conferir cada um (peças, corte, 3D, lado). Confirmar com a imagem.
## Porta de canto em L que não cobre a lateral do fim (Adauto, 17/11)
- **Fotos (2, da tela do app):** aéreo de canto em L visto de baixo. A folha do lado (a que fica no lado do canto) para antes da lateral do fim e deixa a borda dela à mostra. A outra folha está certa. Não gravadas no repositório (público).
- **Pedido:** "essa porta do canto deve cobrir 5 mm do topo atrás e ficar uma folga de 4 mm para não relar a frente no 45 · essa porta em específico, a outra tá certa". Vale para os 4 cantos em L (aéreo e baixo, esquerdo e direito).

## Espelhos orgânicos e LED jateado (Adauto, 23/11 13:09, 4 fotos) — ESP-ORG
Imagens anexadas ao pedido "BIBLIOTECA DE ESPELHOS ORGÂNICOS E LED JATEADO". Prints de navegador com anúncios. Não gravadas no repositório, que é público. Analisadas em 23/11.

| Foto | O que mostra | O que define |
|---|---|---|
| 1 | Espelho orgânico (formato de seixo) com LED traseiro, num lavabo; anúncio "Espelho Orgânico com Led 80 cm × 60 c…" | Contorno orgânico fechado e suave; halo de LED na parede, atrás do vidro |
| 2 | Espelho orgânico vertical irregular, LED traseiro, banheiro escuro | Formato "orgânico vertical irregular" e halo coerente com a distância da parede |
| 3 | Espelho orgânico horizontal assimétrico com LED traseiro | Formato "orgânico horizontal irregular" |
| 4 | Espelho redondo com faixa jateada iluminada perto da borda, centro espelhado; anúncio "Espelho redondo jateado camarim luminoso" | Faixa jateada translúcida e iluminada, com o centro espelhado (modelo 1 da lista) |

- **Sem escala nas fotos:** nenhuma medida foi tirada delas. As medidas vêm do pedido em texto e são editáveis.
- **Evidência visual da comparação:** `engenharia/diagnosticos/espelhos_reais_2026-11-23/` (LEIAME e capturas).
- **Teste:** `testEspelhosOrganicosELedJateadoBibliotecaQuadroOrcamentoEDxf`.
- **Faixa:** `testFaixaDoEspelhoLedApareceDeLongeEEmAngulo` (ESP-FAIXA).

## Portas provençais e puxador concha (Adauto, 23/11 14:40, 6 fotos)
Imagens anexadas ao pedido "IMPLEMENTAÇÃO COMPLETA DE PORTAS PROVENÇAIS E PUXADORES CONCHA". Não gravadas no repositório, que é público. Analisadas em 23/11.

| Foto | O que mostra | O que define |
|---|---|---|
| 1 | Balcão cinza com gavetas e portas provençais simples (quadro estreito); conchas escuras (bronze/grafite) no topo das frentes | Provençal simples (modelo A); concha na região de cima da frente, centrada nas gavetas |
| 2 | Mesmo estilo, gaveta em cima e porta embaixo, conchas escuras centradas | Idem; quadro rente à borda da frente |
| 3 | Três conchas meia-lua rosé, dourada e champanhe, com borda serrilhada (decorativa) | Modelo "com borda decorativa" e acabamentos rosé, dourado e dourado escovado |
| 4 | Concha cromada com orelhas e parafusos aparentes | Modelo "com parafusos aparentes" e acabamento cromado |
| 5 | Porta branca com quadro simples na borda e centro liso | Provençal simples com a moldura na borda |
| 6 | Porta clássica marfim, moldura escalonada na borda, painel do meio em relevo | Provençal detalhada (modelo B) |

- **Sem escala nas fotos:** nenhuma medida foi tirada delas. Larguras de régua, medidas e furação das conchas vêm do pedido em texto, são editáveis, e o DXF avisa para conferir no puxador comprado.
- **Evidência visual da comparação:** `engenharia/diagnosticos/portas_provencal_concha_2026-11-23/` (LEIAME e capturas 3D/2D).

**Prints da tela do app, também de 23/11** (horário de Brasília) (correções do Adauto, não gravados no repositório):
- **15h21, porta com concha:** pedido de "réguas na borda direta", concha "invertida", "máxima textura" e duplicar/ímã.
- **15h37, porta de madeira:** "até o topo em cima também".
- **15h49, cabeçalho da peça no 3D:** "aparecer duplicar em qualquer peça".

> **Orientação da concha: RESOLVIDO (Adauto, prompt oficial de 23/11, via Code 1).**
> - Parte **reta em cima**, parte curva embaixo, abertura por baixo, igual às fotos 1, 2 e 4.
> - A versão 09f18b40 (arco em cima) estava de cabeça para baixo, nas palavras dele.
> - Porta: em pé, perto da lateral que abre. Gaveta: deitada e no meio.
> - O lado da parte reta na porta em pé não foi respondido. A decisão e a fonte estão em `HISTORICO_ERROS.md`, em CONCHA-PRUMO.
> - Commit `7fe0047a`.
## ETAPA 2 (Adauto, 26/11/2026) · 13 fotos e 3 vídeos (descrição; os arquivos não vão pro repositório público)
- **R1 (foto, iPad):** barra do 3D com "Espelhos: equilibrado" junto de Isométrica/Acabamento realista. Pedido: tirar do 3D, deixar só nas configurações do espelho.
- **R2 (foto, iPad):** cozinha 3D, balcões com rodapé/base branca embaixo de cada módulo, separados (vão entre as bases). Pedido: juntar as bases lado a lado numa peça só, até 2700 mm; no L a outra base vai atravessada.
- **R3 (foto, iPad):** balcão com porta aberta: as 2 dobradiças estão da cor da porta (madeira). Têm que ser metálicas.
- **R4 (foto, iPad):** relógio do forno fixo "12:00". Pedido: hora real do aparelho.
- **R5 (foto, iPad):** vista de cima do balcão ao lado do forno: travessas superiores brancas e lateral; referência de travessa/encontro.
- **R6 (foto, iPad):** aba Divisões: hoje "Dividir N por igual" vem em cima; pedido: divisões/divisórias primeiro, dividir por igual mais embaixo.
- **R7 (foto, iPad):** aba Portas > Modelo da porta (Lisa, Ripada V/H, Usinada V/H, Palha). Pedido: todos os modelos com miniatura, "Usados recentemente", puxadores mais embaixo.
- **R8 (foto, outro programa):** canto L inferior visto de cima, aberto: travessas superiores — travessa da frente de cada lado e travessa atravessada na junção; montante/lateral de encontro no canto do fundo.
- **R9 (foto, outro programa):** canto L com as DUAS portas abertas a ~165° (dobradiças nas laterais externas), prateleira em L, montante no canto interno.
- **R10 (foto, outro programa):** canto L visto de cima com as duas portas abertas: travessa da frente de um lado passa inteira e cruza com a do outro lado; travessas do fundo; portas abertas ~165°.
- **R11 (foto, outro programa):** Dimensões do canto L: Largura 950, Altura 700, Profundidade 950, Medida A 550 (lados A e B no desenho em L).
- **R12/R13 (fotos, outro programa):** canto cego (porta + painel cego com régua/batente) frente e vista de cima: travessas da frente e do fundo, régua vertical entre o cego e a porta, porta com 2 dobradiças.
- **V1 (vídeo 12 s, iPad):** porta do forno abrindo: hoje a porta gira e entra nas laterais/extremidades do forno. Tem que abrir como forno real (eixo embaixo, na frente, sem atravessar).
- **V2 (vídeo 26 s, outro programa):** colocando cantos L e cantos cegos lado a lado no ambiente, girando a câmera em volta, encaixando um módulo ao lado do outro direto na tela (referência da câmera e edição no 2D).
- **V3 (vídeo 13 s, outro programa):** câmera girando em volta de canto L e canto cego, portas abertas com dobradiças, travessas de cima, vista de cima e de lado.
- Quadros dos vídeos e fotos: com o Chefe (sessão 016faTeEhtYkTpACtvjgfHzo). Medida que não está clara nas referências: perguntar ao Adauto antes.
