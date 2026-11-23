# Portas provençais e puxadores concha (23/11)

Branch `claude/portas-provencal-concha` (a partir de 28e24535). Tudo em `app/src/main/assets/editor.html`, módulo no fim do arquivo, mais 4 ganchos pequenos.

## O que entrou
- **Aba Portas → "Estilos de porta"** (seção nova, depois do puxador). Estilo: Lisa, Provençal simples, Provençal detalhada, Provençal dupla. Construção: Régua aplicada, Moldura aplicada, Usinada em CNC. Medidas: largura (20 a 70 ou outra), distância da borda, 45° ou encontro reto, espessura, 2ª moldura e distância (dupla), frisos (detalhada), profundidade e Ø da ferramenta (CNC), cor própria.
- **Aplicar em**: somente esta porta, este móvel, mesmo modelo, ambiente, projeto. Abre uma prévia com a quantidade antes de confirmar. Porta de vidro e de correr ficam fora. Um desfazer volta tudo. Escolher no quadro não muda o projeto antes de "Aplicar".
- **Aplicada**: 4 peças reais por quadro, MDF 6 mm, fora da porta (a porta não muda de medida). Vão para lista, corte (na cor de fora, ou linha própria se a régua tiver cor própria), orçamento e DXF (corte a 45° na camada `CORTE_45`). A nota da porta mostra a espessura total.
- **Usinada**: nenhuma peça aplicada. Frisos fechados no DXF da porta, na camada `FRISO_L{largura}_P{prof}_FERR_D{Ø}_FACE_FRENTE`. Metros de friso no orçamento (preço no Ajustes, linha "Friso usinado em CNC").
- **Bloqueios**:
  - painel do meio abaixo de 40 mm;
  - medida negativa;
  - friso que deixaria menos de 9 mm de MDF;
  - moldura sobre a cava usinada (menos de 21 mm da borda: a cava de 30° ocupa 12/tan30).

  A porta fica lisa e a nota avisa.
- **Avisos**:
  - friso a menos de 40 mm da borda das dobradiças (nota);
  - no DXF, CONFLITO quando friso + copo passam da espessura;
  - concha atravessando a borda da régua.
- **Concha**: 7 modelos (meia-lua clássica, meia-lua lisa, borda decorativa, retangular, arredondada, parafusos aparentes, parafusos ocultos), cada um com geometria 3D própria.
  - Largura, altura, profundidade, entre-furos e Ø são editáveis.
  - A furação do DXF usa o modelo. A profundidade vem das configurações do DXF; sem ela, os furos ficam passantes e isso é avisado.
  - Fica sempre na horizontal com a boca para baixo.
  - Concha sem modelo escolhido continua exatamente igual: conferido peça por peça contra 28e24535.
- **Acabamentos**: entram cinza fosco, prata, preto fosco, dourado escovado e cobre (cromado e rosé já existiam), mais cor livre em hex.
  - Escopo da cor: apenas este puxador / deste móvel / do mesmo modelo / do projeto. O padrão continua "do projeto", que é o comportamento de antes.
  - A cor individual continua possível depois.

## Testes (falham em 28e24535, passam aqui)
- testPortaProvencalReguasAplicadasPecasReaisCorteEDxf
- testPortaProvencalUsinadaCncFrisosNoDxfEConflitoComDobradica
- testEstilosDePortaPreviaAplicarEmMassaUmDesfazerESalvar
- testConchaSeteModelosFuracaoPorModeloECorPorEscopo

## Limites conhecidos (sem regra inventada)
- As medidas dos modelos de concha são medidas comerciais comuns. A furação deve ser conferida no puxador comprado (aviso no DXF).
- A posição da concha (meio/cima/baixo, centro/lado) continua no ⚙ como sempre, para o projeto todo.
- "Ambiente" é o projeto: um projeto tem um ambiente.
