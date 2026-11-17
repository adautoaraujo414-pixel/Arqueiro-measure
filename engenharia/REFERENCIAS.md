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
