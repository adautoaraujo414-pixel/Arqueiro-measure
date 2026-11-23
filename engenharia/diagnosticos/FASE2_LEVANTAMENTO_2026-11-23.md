# Fase 2 — levantamento automático de geometria (23/11/2026, Claude Code 2)

Base: `feature/candidata-integrada-2211` 3b99c01. Só levantamento — **nada corrigido ainda**. Reprodução: `fase2-levantamento-2026-11-23.js`
(roda no editor: cada modelo do catálogo sozinho num projeto limpo + canto em L pelo botão + `demoScene`; compara caixas do 3D × `partsOf` × `cutLines`).

Escopo: 142 modelos do catálogo + 2 cantos (botão) + cozinha de exemplo (`demoScene`).

## Resultado classificado

| # | Verificação | Achados | Classificação |
|---|---|---|---|
| A | Porta/frente fechada atravessando o corpo (lateral, base, tampo, travessa, divisória, prateleira, fundo, tamponamento, rodapé) com mais de 1 mm nos 3 eixos | **0** | OK |
| B | Lateral de gaveta × fundo de gaveta (6 mm) se sobrepõem 7,5 mm (154 casos, todas as gavetas) | 154 | **SUSPEITO de fabricação (não de desenho)**: o fundo é feito 2 × 1,5 mm mais largo pela opção "a mais por lado" (Ajustes) e entra 7,5 mm em cada lateral, mas a nota da lateral diz rebaixo de 6 × 6 mm. O 3D não desenha o rebaixo (a lateral é caixa inteira), então 6 mm de sobreposição são esperados; os 1,5 mm a mais exigem rebaixo de 7,5 ou o fundo não entra. **Decisão do Adauto**: rebaixo acompanha a opção (7,5) ou o fundo fica no 6? |
| C | Tamponamento com engrosso (aéreos, 26 modelos): lista mostra 1 peça "Tamponamento direito 750×80", corte mostra 2 × "régua 30 mm 750×80", 3D mostra 2 réguas | 26 | **A confirmar (área do Code 1 — tamponamento)**: o 3D e o corte concordam (2 réguas de 15 = 30 mm); a lista de peças mostra 1. Se a lista é "peça lógica de 30 mm", está certo; senão é divergência lista × corte. |
| D | Frente com recorte (torre forno/micro): sem caixa sólida no 3D com a chave da peça | 2 | **Falso positivo**: a frente é desenhada como moldura (4 pedaços) em volta do recorte, todos com a chave dela. |
| E | Gaveta interna: a chave da frente agrupa caixa + corrediças no 3D (medida da união ≠ peça) | 5 | **Falso positivo** (agrupamento para seleção). |
| F | Sapateira inclinada: medida do 3D (caixa envolvente) ≠ peça | 18 | **Falso positivo** (prateleira inclinada; a caixa envolvente cresce com o ângulo). |
| G | Cozinha de exemplo: base e rodapé de 2 balcões (1200 + 600) no 3D como 1 peça de 1800 | 4 | **Intencional** ("base contínua, sob as laterais"): o plano de corte do projeto traz 1 base 1800 × 560 e não traz as de 1200/600. |
| H | Lista × corte: corte tem linhas a mais (engrossos de tamponamento, fundo) | todos | **Intencional** (o corte desdobra peças); toda peça da lista aparece no corte. |

## Próximo passo proposto
1. Só B e C pedem decisão/confirmação; nenhum defeito de "porta atravessando corpo" foi achado no catálogo e na cozinha de exemplo.
2. Ampliar o levantamento para projetos montados (módulos lado a lado, pedras, tamponamentos entre módulos, paredes) — onde o tamponamento entre módulos já tem diagnóstico do Code 1.
