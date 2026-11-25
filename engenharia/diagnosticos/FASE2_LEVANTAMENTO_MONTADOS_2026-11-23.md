# Fase 2 — levantamento em PROJETOS MONTADOS (ponto 2) · 23/11/2026, Claude Code 2

Base: candidata `5bd11f5` + `claude/fecha-pendencias`. **Só levantamento** (doc + script; o editor não muda), como combinado com o Chefe (23/11 02:19).
Reprodução: `fase2-levantamento-montados-2026-11-23.js` (roda no editor; usa o 3D de verdade, `__build`/`__boxes`).

Complementa o levantamento por modelo (`FASE2_LEVANTAMENTO_2026-11-23.md`, 142 modelos sozinhos): aqui as peças de **módulos diferentes**
(e módulo × pedra × ilha) são comparadas entre si — sobreposição de mais de 1 mm nos 3 eixos entre peças sólidas (lateral, base, tampo, travessa,
divisória, prateleira, fundo, tamponamento, rodapé, régua, moldura, porta, frente, pedra, ilha). Fita, linhas, sombras, eletros e painéis de parede ficam de fora.

| Cena | Módulos | Pedras | Ilhas | Caixas sólidas | Sobreposições |
|---|---|---|---|---|---|
| Cozinha de exemplo (`demoScene`) | 9 | 1 | 0 | 186 | **0** |
| Reta: 4 balcões + 3 aéreos, tamponamento nas pontas, pedra | 7 | 1 | 0 | 121 | **0** |
| Em L: canto + balcão na parede esquerda + pedra em L | 4 | 1 | 0 | 95 | **0** |
| Em U: dois cantos + balcão | 3 | 0 | 0 | 57 | **0** |
| Península + ilha (com pedra e banqueta) + balcão | 1 | 0 | 2 | 85 | **0** |
| 2 guarda-roupas lado a lado | 2 | 0 | 0 | 44 | **0** |
| Caixa da geladeira (tamponamento dos 2 lados) + balcão + aéreo | 3 | 0 | 0 | 48 | **0** |
| **Controle**: 2 balcões no mesmo lugar (confineAll desligado só nesta cena) | 2 | 0 | 0 | 42 | **21** (todas as peças de um entram no outro — prova de que a conferência pega) |

## Leitura
- Nenhuma peça de um módulo entra em peça de outro, nem na pedra, nem na ilha, nas cenas montadas — inclusive no encontro do canto em L/U,
  tamponamento entre módulos e pedra em L sobre balcão da parede lateral.
- Observação de montagem do teste (não é defeito): no modo parede, o 2º balcão seguido na parede esquerda não entra (falta espaço depois do canto
  com a parede de 5000 da cena), por isso a cena em L tem 1 balcão na esquerda.
- O primeiro desenho da ilha nesta cena punha a península girada por cima da ilha (posição escolhida no script, 33 sobreposições); com as duas
  separadas, 0. O app deixa a pessoa encostar as ilhas onde quiser (sem defeito de geometria).

## Achados da 1ª parte que seguem como estavam
- B (fundo de gaveta): resolvido pela FASE2 (gf6, integrado).
- C (tamponamento 30 mm = 1 peça na lista × 2 réguas no corte): área do Code 1; registrado, sem correção (decisão do Chefe 23/11 02:19).
