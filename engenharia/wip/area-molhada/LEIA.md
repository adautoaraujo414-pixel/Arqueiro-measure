# Área molhada no 3D: trabalho parado no meio (checkpoint de 16/11, 14:54)

**Não validado. Não entra em publicação sem terminar e sem autorização.**

## Pedido
- 16/11, 14:41: "Área molhada muito feio o acabamento dessa mancha horrível", com foto do tablet. A área molhada aparecia como uma placa lisa verde-escura por cima do granito.
- 14:42, resposta à minha pergunta: "rebaixo da pia área molhada 2 cm, pegue referências na internet".

## Referência (internet)
Bella Granitos, "Você conhece os tipos de rebaixo para a área molhada?" e "Rebaixo de Área Molhada: Qual Modelo Escolher para Sua Bancada?" (bellagranitos.com.br):
- **Tradicional:** cerca de 2 cm, cantos retos, peças emendadas.
- **Americano:** cerca de 2 cm, cantos arredondados, uma peça colada por baixo.
- **Italiano (usinado):** cerca de 0,5 cm, no próprio material.

## Causa da mancha
- **Onde:** `editor.html`, embrulho `build_wet`.
- **O que fazia:** a área molhada era desenhada como placas de 0,7 mm, 0,4 mm acima da pedra.
- **Cor:** a cor da pedra × 0,72, sem a textura da pedra (o grupo não era `stc`).
- **Resultado:** nenhum degrau, cilindros nos cantos e frisos escuros dos lados. Na pedra clara virava uma placa marrom com linhas.

## O que está no commit desta branch (só `editor.html`)
- **`stSlab`:** a placa da pedra é recortada na área molhada (`wetCut`).
  - O fundo da área molhada é a mesma pedra, mais baixa: rebaixo de no máximo a espessura da pedra − 5 mm.
  - Os cantos curvados continuam com a pedra de cima (`BH` com textura).
  - A cuba que fica dentro da área molhada recebe o nível de baixo (`cuba3(st, it, y0, yC(it))`).
- **`wetEdge`:** um fio claro em volta do degrau, como a quina polida pegando a luz.
- **`pfFill`:** peça arredondada do grupo `stc` passa a usar a textura da pedra. Só afeta as peças novas; nenhuma peça antiga usa `stc` com polígono.
- **`wetDefault`:** o rebaixo novo é de 20 mm. Área molhada que já existe fica com o que tem (8 mm), sem mudar sozinha.

## Testado até aqui (Chromium, rascunho `teste-rascunho.js`)
- Rebaixo de 20 mm de verdade: dentro −20, fora 0.
- Sem placa de outra cor.
- 4 cantos curvos.
- Pedra de 2 cm: rebaixo de 15 mm.
- Projeto antigo com 8 mm continua com 8.
- Salvar e reabrir: igual.
- Tirar a área molhada: a pedra volta inteira.

## Falta
1. Corrigir o rascunho do teste:
   - os casos "quadrado" e "rebaixo8" usam a pedra da cena anterior;
   - a cuba de sobrepor não foi achada;
   - o resumo pra marmoraria é `marmHtml`, não `stResumo`.
2. Conferir cuba de sobrepor e esculpida dentro da área molhada, área molhada encostada na ponta da pedra, pedra em L e U, toque na pedra no 3D e foto do 3D no iPad.
3. Passar o teste pra bateria (`EditorWebKitTests.swift`). Rodar os 22 testes de cuba no 3D e a bateria completa.
4. **Perguntar ao Adauto:** o campo "Rebaixo" (3 a 20 mm) continua ou fica fixo em 20?
5. Registrar em `HISTORICO_ERROS.md` e em `novidades.txt`.
