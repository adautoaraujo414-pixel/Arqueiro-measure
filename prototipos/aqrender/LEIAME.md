# AQRender: protótipo (16/11/2026). **Não está no app.**

Cópia isolada do editor com um desenho mais realista do 3D. **O motor do app (`app/src/main/assets/editor.html`) não foi mexido.**
Montar a cópia: `python3 prototipos/aqrender/montar.py`. Isso gera `prototipos/aqrender/editor.html`, que não vai pro Git.
No harness, liga com `aqSet(1)` e desliga com `aqSet(0)`.

## O que muda (só a forma de iluminar; geometria idêntica)
- **Mesmas caixas e mesmos triângulos** que o 3D atual. A cena de teste tem 562 caixas nos dois. Nada criado, tirado ou mexido.
- **Normal de cada triângulo** calculada da própria geometria.
- **Luz:**
  - Uma luz de cima, da frente e um pouco da esquerda.
  - Luz de céu e chão (hemisférica).
  - Sombra suave: mapa de sombra de 1024 px com filtro 3×3. É feito só quando a cena muda; girar a câmera não refaz.
- **Metal** (perfil G, puxadores, dobradiças, inox):
  - Brilho GGX com rugosidade: 0,30 no metal claro e 0,50 no escuro.
  - Reflexo de um ambiente gerado no próprio código (gradiente de céu e chão com uma "janela"). Não usa foto, IA ou serviço externo.
  - **Limite:** a rugosidade sai pela claridade da cor. O app ainda não guarda "escovado", "polido", "fosco" etc. para usar aqui.
- **Vidro:** Fresnel (reflete mais em ângulo raso) com o tom da cor do vidro. A espessura é a da peça. Não tem refração.
- **MDF:**
  - A mesma foto ou veio do padrão, na mesma direção e escala.
  - A exposição foi ajustada para a frente da peça ficar com a cor do padrão (sem curva de tom forte).
- **LED:** só as peças que já são LED (emissivas) brilham. Não há luz extra. A luz do LED **não** ilumina o resto (limite do protótipo).
- **Linhas entre as peças:** continuam, mais leves, para ver a separação real das frentes.

## Comparação (mesmo projeto, mesma câmera, mesmas medidas)
- Imagens: frente da cozinha, gola de perto, forno inox e aéreo de vidro, antes e depois.
- **Medição no Chromium sem GPU (SwiftShader), não em aparelho:**

| | 3D atual | Protótipo |
|---|---|---|
| Abrir o 3D | 315–391 ms | igual (o protótipo só liga depois) |
| Ligar o protótipo | — | 1,3–1,45 s (normais + mapa de sombra) |
| Tempo de quadro | 280–405 ms | 1,1–1,2 s (cerca de 3×, por causa das 9 leituras de sombra por pixel) |
| Memória JS | 23–30 MB | igual |
| Memória de vídeo extra | — | Cerca de +40% nos vértices (44 bytes em vez de 32) e mapa de sombra de 1024² (4 MB + 2 MB de profundidade) |

- **FPS de iPhone, iPad e Android: não medido.** Precisa de uma versão de teste instalada no aparelho, e isso depende de autorização.
- **Compatibilidade:** só WebGL 1, sem extensão obrigatória, a profundidade da sombra guardada em RGBA. Roda onde o 3D atual roda. Não foi testado em aparelho.

## Como seria usar sem pesar
- **Sugestão** (não feita): usar o protótipo como "foto" do AQRender.
  - Liga quando a câmera para, ou com um botão.
  - Volta pro 3D normal enquanto gira ou arrasta.
  - Assim a edição continua leve, e a imagem do orçamento sai realista.

## Pendente para aprovar
- Testar num aparelho de verdade: FPS, temperatura e memória.
- Acabamentos do metal como dado do projeto (escovado, polido, fosco, cromado, dourado escovado).
- Luz real do LED nas peças em volta.
- Ordenação do vidro por distância.
