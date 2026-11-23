# Fase 2 — levantamento automático de geometria (23/11/2026, Claude Code 2)

Base: `feature/candidata-integrada-2211` 3b99c01. Só levantamento — **nada corrigido ainda**. Reprodução: `fase2-levantamento-2026-11-23.js`
(roda no editor: cada modelo do catálogo sozinho num projeto limpo + canto em L pelo botão + `demoScene`; compara caixas do 3D × `partsOf` × `cutLines`).

Escopo: 142 modelos do catálogo + 2 cantos (botão) + cozinha de exemplo (`demoScene`).

## Resultado classificado

| # | Verificação | Achados | Classificação |
|---|---|---|---|
| A | Porta/frente fechada atravessando o corpo (lateral, base, tampo, travessa, divisória, prateleira, fundo, tamponamento, rodapé) com mais de 1 mm nos 3 eixos | **0** | OK |
| B | Lateral de gaveta × fundo de gaveta (6 mm) se sobrepõem 7,5 mm (154 casos, todas as gavetas) | 154 | **SUSPEITO de fabricação (não de desenho)**: o fundo é feito 2 × 1,5 mm mais largo pela opção "a mais por lado" (Ajustes) e entra 7,5 mm em cada lateral, mas a nota da lateral diz rebaixo de 6 × 6 mm. O 3D não desenha o rebaixo (a lateral é caixa inteira), então 6 mm de sobreposição são esperados; os 1,5 mm a mais exigem rebaixo de 7,5 ou o fundo não entra. **Decisão do Adauto**: rebaixo acompanha a opção (7,5) ou o fundo fica no 6? |
| C | Tamponamento com engrosso (aéreos, 26 modelos): lista mostra 1 peça "Tamponamento direito 750×80", corte mostra 2 × "régua 30 mm 750×80", 3D mostra 2 réguas | 26 | **Intencional (conferido por leitura)**: a peça da lista é a peça lógica de 30 mm (mat 30); o `cutLines` (embrulho de engrosso, L7346) desdobra em 2 réguas de 15 "coladas uma na outra = uma só de 30 mm". |
| D | Frente com recorte (torre forno/micro): sem caixa sólida no 3D com a chave da peça | 2 | **Falso positivo**: a frente é desenhada como moldura (4 pedaços) em volta do recorte, todos com a chave dela. |
| E | Gaveta interna: a chave da frente agrupa caixa + corrediças no 3D (medida da união ≠ peça) | 5 | **Falso positivo** (agrupamento para seleção). |
| F | Sapateira inclinada: medida do 3D (caixa envolvente) ≠ peça | 18 | **Falso positivo** (prateleira inclinada; a caixa envolvente cresce com o ângulo). |
| G | Cozinha de exemplo: base e rodapé de 2 balcões (1200 + 600) no 3D como 1 peça de 1800 | 4 | **Intencional** ("base contínua, sob as laterais"): o plano de corte do projeto traz 1 base 1800 × 560 e não traz as de 1200/600. |
| H | Lista × corte: corte tem linhas a mais (engrossos de tamponamento, fundo) | todos | **Intencional** (o corte desdobra peças); toda peça da lista aparece no corte. |

## Projetos montados (script `fase2-levantamento-montados-2026-11-23.js`)
Cenas: cozinha, sala, closet e LED de exemplo; 3 balcões lado a lado com tamponamento entre eles; cozinha em L com canto e aéreos; torre + balcão + aéreo com
tamponamento de cima; canto cego + pia + pedra; canto reto + guarda-roupa 3 vãos.

| # | Verificação | Achados | Classificação |
|---|---|---|---|
| I | Porta/frente de um módulo entrando no corpo do vizinho | **0** | OK |
| J | Corpo × corpo entre módulos (> 1 mm nos 3 eixos) | **0** | OK |
| K | Base/rodapé corridos (2 ou mais balcões juntos): peças por módulo sem caixa própria no 3D, uma peça contínua no 3D e no corte | todas as cenas com balcões juntos | **Intencional** (base/rodapé contínuos). |
| L | Rodapé lateral do ENCONTRO entre dois balcões com rodapé corrido: está na lista do módulo (`partsOf`), mas sai do corte (`rodSkip`) e do 3D | cenas com rodapé corrido | **A confirmar (divergência lista × corte/3D)**: o corte e o 3D concordam (a peça do encontro não existe); a lista de peças do módulo ainda mostra. Não corrigido. |
| M | Tamponamento de 105×80 / 750×80 sem caixa com a mesma chave | sala, LED, torre | **Intencional** (mesmo caso C: réguas). |

## Próximo passo proposto
1. Só B e C pedem decisão/confirmação; nenhum defeito de "porta atravessando corpo" foi achado no catálogo e na cozinha de exemplo.
2. Pedem decisão/confirmação: B (fundo de gaveta 7,5 × rebaixo 6) e L (rodapé lateral do encontro na lista).
