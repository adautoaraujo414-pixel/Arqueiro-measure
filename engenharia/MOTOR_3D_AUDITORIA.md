# Motor 3D: auditoria (fase 1) e proposta

Data: 16/11/2026. **Só leitura e medição: nenhuma mudança no motor foi feita.** Fonte: código de `app/src/main/assets/editor.html` (commit e3d68b8) e medições no harness.

## 1. Motor identificado (confirmado no código)
- **WebGL 1 próprio, sem biblioteca** (não usa Three.js, Babylon nem outra): `getContext('webgl',{antialias:true})`.
- Se não tiver WebGL, cai para um desenho em canvas 2D (`render2d`).
- **1 programa de shader.** O vértice tem 32 bytes: posição (3), cor (4) e "tipo" (1).
- Caixa sem índice: 36 vértices para as faces e 24 para as arestas.
- **Luz:** não existe luz no shader. Cada face recebe um fator fixo calculado no processador:
  - topo 1
  - frente 0,92
  - lado direito 0,82
  - lado esquerdo 0,78
  - trás 0,62
  - baixo 0,5
- Não há normal, brilho especular, reflexo, mapa de ambiente nem sombra projetada.
- **Materiais pelo "tipo" do vértice:**
  - 0: cor lisa.
  - 1 a 4: texturas geradas no código (pedra e granulado).
  - 5: veio de madeira gerado (textura 1024×256).
  - 6: MDF liso com granulado leve.
  - 7: **foto real do padrão** (`cores/<id>.jpg`), um buffer por material.
  - 9: vidro, com faixas de brilho em espaço de tela.
- **Metais (puxadores, perfis, inox):** cor lisa com o mesmo fator de face, então ficam com cara de plástico.
- **Arestas:** linha escura (alfa 0,8) em toda caixa. É o visual de desenho técnico.
- **Transparência:** desenhada depois do resto sem ordenar por distância (`depthMask(false)`). Vidro na frente de vidro pode sair na ordem errada.
- **Quando refaz:**
  - Mexer só na câmera: troca só os uniforms (barato).
  - Qualquer mudança no projeto: refaz a cena inteira (`build`) e manda todos os vértices de novo para a placa (`glFill`).
  - Quando uma foto de material termina de carregar, também manda tudo de novo.
- **Texturas:**
  - 3 geradas na abertura (256², 512², 1024×256), cerca de 3 MB na placa.
  - Fotos carregadas sob demanda, quando um módulo usa o padrão.
  - **Nunca são liberadas**: não existe `deleteTexture`.
  - Em `cores/` há 271 JPGs, 7,1 MB no total: 214 de 512×512, 51 de 512×1024 e 6 de 1024×1024.
- **Perda do contexto gráfico não é tratada.** Ver WEBGL-001 em `HISTORICO_ERROS.md`; reproduzido no Chromium: o 3D fica de uma cor só até recarregar.

## 2. Medições (Chromium sem GPU, no servidor de testes)
**Atenção:** a máquina de teste desenha com processador (SwiftShader). Por isso o tempo de quadro medido aqui (135 a 380 ms) **não vale como FPS de aparelho.** Os números de processador (montar cena e enviar dados) servem para comparar antes e depois. **Nenhum FPS de iPhone, Android ou Windows foi medido.**

| Cena | Caixas | Abrir o 3D | Montar a cena (`build`) | Triângulos | Linhas | Chamadas de desenho por quadro |
|---|---|---|---|---|---|---|
| P (1 balcão) | 111 | 11–16 ms | 1–2 ms | 1.508 | 1.318 | 4–5 |
| M (4 balcões + 4 aéreos) | 762 | 20–22 ms | 17–19 ms | 9.408 | 8.854 | 5 |
| G (20 balcões + 20 aéreos) | 3.768 | 69–90 ms | 54–222 ms (média de 5: 126) | 46.068 | 43.574 | 7 |

- Arrastar um módulo na cena G custa uns 122 ms por passo do dedo (2D + refazer o 3D inteiro). **É o gargalo principal medido.**
- Dentro do `build` da cena G, as peças (`partsOf`) levam 2 a 29 ms. O resto é montar as caixas e os vértices.
- Memória JS: de 9 a 15 MB logo depois de abrir. Na cena G, depois de várias reconstruções, chegou a 69 MB (lixo temporário dos vértices).
- Cada foto de material ocupa uns 1,3 a 2,7 MB na placa.
- Chamadas de desenho por quadro: muito poucas (4 a 7). Isso já é bom e deve ser mantido.

### Outros tempos (cena G, 40 módulos, medidos com a bateria rodando em paralelo, então com ruído)
- Projeto salvo: 36 KB.
- `snapState`: 0,4 ms.
- `loadState`: 79 ms.
- Desenho 2D (`draw`): de 16 a 108 ms.
- Plano de corte (`cutGroups`): 16 ms, 44 grupos de peças.

## 3. Pontos fortes (manter)
- Poucas chamadas de desenho e mexer na câmera é barato.
- As fotos dos padrões já são as reais do catálogo e só carregam quando usadas.
- O motor é pequeno: não tem dependência pesada.

## 4. Problemas encontrados (por gravidade)
1. **WEBGL-001:** 3D apagado sem volta depois da perda de contexto. **Estabilidade.**
2. **Refaz a cena inteira em toda mudança e a cada foto que carrega.** Arrastar em projeto grande fica pesado.
3. **Metal e vidro sem reflexo:** puxadores e perfis parecem plástico; vidro sem Fresnel.
4. **Vidro sem ordenação:** ordem de transparência errada em alguns ângulos.
5. **Luz fixa por face:** o canal do gola, rebaixos e cantos internos ficam com a mesma claridade da frente, e a profundidade não aparece. Depois da correção do gola, o canal aparece pouco por isso.
6. Texturas nunca liberadas: a memória cresce com o uso de muitos padrões.
7. O shader busca as posições dos uniforms em todo quadro (custo pequeno).

## 5. Proposta (fase 2, protótipo). **Precisa de aprovação. Nada disso foi implementado.**
Regra geral:
- Geometria, peças, medidas, cores escolhidas e dados do projeto não mudam.
- Tudo dentro do shader e do envio de dados que já existem.
- O mesmo número de chamadas de desenho.

| # | O que muda | Benefício | Risco | Custo |
|---|---|---|---|---|
| 1 | Tratar perda e volta do contexto (refazer shader, texturas e buffers) | 3D não fica apagado no iPhone e no Android | Baixo | Baixo |
| 2 | Normal da face no vértice + 1 luz direcional suave + luz ambiente de céu e chão | Profundidade real (canal do gola, rebaixos, cantos) | Médio (a cor percebida muda um pouco) | +12 bytes por vértice |
| 3 | Metal: brilho especular com rugosidade por acabamento (escovado, polido, fosco, acetinado, cromado, dourado) e reflexo aproximado de um ambiente gerado (gradiente, sem imagem) | Puxador com cara de metal | Baixo | Só no shader |
| 4 | Vidro: Fresnel + tom por tipo + ordenar só as peças transparentes por distância | Vidro mais real e na ordem certa | Baixo | Ordenação no processador só quando a câmera para |
| 5 | Não reenviar a cena inteira quando uma foto carrega; reenviar só o buffer daquele material | Sem travadinha ao abrir projeto com muitos padrões | Baixo | Pequeno |
| 6 | Liberar fotos de padrões que ninguém usa mais | Menos memória em uso longo | Baixo | Pequeno |
| 7 | Arrastar: refazer só o módulo que se mexe | Arrasto fluido em projeto grande | **Alto (mudança estrutural)**: deixar para depois | Médio |

**Ordem sugerida do protótipo (fase 2):** o 1 primeiro (estabilidade). Depois 2 e 3 só no puxador gola, 4 só no vidro incolor e o MDF liso com a luz nova. Antes e depois em imagens, com as mesmas cenas P, M e G medidas de novo.

**Não recomendado agora:**
- Texturas KTX2/Basis: precisam de um decodificador de uns 200 KB, e as fotos atuais são pequenas (512 px).
- Ray tracing, sombras de alta resolução e pós-processamento.

**Para medir FPS de verdade** é preciso rodar no aparelho dele: iPhone, tablet Android e Windows. Proposta, que depende de aprovação: um medidor escondido no "🔎 Diagnóstico do 3D" que mostra quadros por segundo e tempo de quadro. Ele não muda nada no projeto.
