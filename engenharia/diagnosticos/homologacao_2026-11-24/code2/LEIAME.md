# Homologação 24/11 · evidência visual do Code 2

Capturas do Chromium (renderizador por software) do editor do ramo `claude/auditoria-candidata-2411` (sobre a candidata `ed041eb2`, já com VIS-MAT e PASSANTE-PONTA; refeitas no SHA final), nas telas de 1366 × 900 e 430 × 900.

Cada imagem é a função de verdade no editor, aberta pelo roteiro em `roteiros/`. O roteiro usa as mesmas funções do app (`newTpl`, `pxApplyAll`, `espWallAdd`, `open3D`, `openCut`, …), sem montagem.

| Arquivo | Função | Conferido no roteiro |
|---|---|---|
| `1_provencal_*` | Portas provençais: simples, detalhada (régua) e dupla (moldura), madeira, concha cromada | 8 / 8 / 16 réguas reais na lista |
| `2_concha_*` | Puxador concha (modelo clássico, cromado): em pé na porta, deitado na gaveta | 0 erros |
| `3_espelho_real_*` | Espelho com reflexo planar real; o balcão vermelho aparece dentro do espelho | 1 plano de reflexo, sem erro |
| `4_espelho_organico_*` | Espelhos orgânicos: gota, ondulado, vertical e horizontal irregulares | 4 espelhos |
| `5_led_*` | LED: redondo jateado, orgânico com LED frontal e traseiro, retangular com faixa jateada | 29 caixas de LED |
| `6_texturas_*` | Texturas reais dos padrões (Cumaru, Louro Freijó, Pau Ferro Natural, Areal) | nomes dos padrões |
| `7_personalizacoes_*` | Aba Portas → "Estilos de porta": estilo, aplicar em (porta / móvel / modelo / ambiente / projeto), medida da folha | seção presente |
| `8_dxf_*` | Tela "DXF para CNC" do plano de corte, com provençal usinada e concha furada | camadas `FRISO_…`, `FURO_PUXADOR_D5_P13`, dobradiça e cavilha; "Pronto pra exportar" |

No `8_dxf`, os valores de profundidade e Ø são os que a pessoa digita nos Ajustes do DXF: entram só para a tela mostrar o "pronto". Não são regra de fabricação.
