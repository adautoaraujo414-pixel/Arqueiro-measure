# Fase 5 — DXF para CNC (23/11/2026, Claude Code 2, autorizado pelo Adauto)

Ramo `claude/fase5-dxf` (sobre `claude/fase2-geometria`, que está sobre a candidata integrada 3b99c01).

## Onde fica
Plano de corte → botão **"⬇ DXF para CNC"** (ao lado de "Enviar"; nenhum botão existente mudou). Abre a tela de configuração; exporta o
**projeto inteiro (1 arquivo)** ou **uma peça**. No app: iOS abre a folha de compartilhar (Arquivos, AirDrop, e-mail), Android abre o compartilhar
(cache/exports via FileProvider), Windows salva em `Documentos\Arquemestre\DXF` e abre a pasta. No navegador: download.

## O que sai (uma camada por operação; Ø e profundidade no nome da camada)
| Camada | Entidade | Origem no projeto |
|---|---|---|
| `CONTORNO` | POLYLINE fechada | medida de corte (mesma lista do plano de corte: `cutGroups`) |
| `FURO_DOBRADICA_D35_P{prof}` | CIRCLE Ø35 | `furInfo` (lado, distância das pontas, centro a B da borda) |
| `FURO_S32_D5_P12` | CIRCLE Ø5 | sistema 32 (`furInfo`: fileiras, passo, 1º furo) |
| `FURO_PUXADOR_D{Ø}_P{prof}` | CIRCLE | puxador concha (`chAt`, distância entre furos dos Ajustes) |
| `FURO_TOPO_ROLDANA_D{Ø}_P{prof}` | CIRCLE na aresta de cima | porta de correr (`furInfo` rol) |
| `REBAIXO_L{largura}_P6` | POLYLINE fechada | lateral de gaveta: rebaixo do fundo (gavRb × 6) |
| `RASGO_L6_P{prof}` | POLYLINE fechada | lateral de gaveta com corrediça oculta (posição do fundo `ocR`) |
| `CAVA_30_P12` | POLYLINE aberta na aresta | porta/frente com cava usinada 30° (aresta de cima; de baixo no aéreo) |
| `CAVILHA_D{Ø}_P{prof}_F1` / `_F2` | CIRCLE | uniões achadas pelo encosto das peças no 3D: F1 = face do lado + do eixo da espessura, F2 = a outra (posições vistas pela F1) |
| `FURO_TOPO_CAVILHA_D{Ø}_P{prof}` | CIRCLE na aresta | o furo correspondente no topo da peça que encosta |
| `PREFURO_D{Ø}_P{prof}_F1/F2` | CIRCLE | mesma regra das uniões, quando a união escolhida é pré-furo |
| `ETIQUETA` | TEXT | nome, medida e espessura da peça |

Arquivo: DXF **R12 (AC1009)**, ASCII, milímetros (`$INSUNITS 4`, `$MEASUREMENT 1`), peças lado a lado com 60 mm de folga. Desenho de cada peça:
X = comprimento de corte, Y = largura, Y pra cima = topo da peça (porta: topo da porta).

## Nada inventado — o que é obrigatório
A tela lista e **bloqueia a exportação** enquanto faltar:
- profundidade do copo da dobradiça (se houver dobradiça);
- tipo de união (cavilha, pré-furo ou nenhuma) e, se cavilha/pré-furo: Ø, profundidades, 1º furo a quantos mm da ponta, espaçamento máximo;
- Ø e profundidade dos furos do puxador concha; da roldana; profundidade do rasgo da gaveta oculta;
- puxador barra/botão: o projeto não tem a posição dos furos → exige marcar "furar na montagem";
- fundo embutido em rasgo (projeto antigo) → pede passar pra sobreposto.
Peça contínua de vários módulos (base/tampo/rodapé corrido) não ganha furo de união (aviso "furar na montagem"). O pedestal (rodapé) é montado à parte e fica fora das uniões.

## Validação
- `ezdxf` 1.4.5 no contêiner: todos os arquivos de exemplo abrem, auditoria com 0 erro, todos os contornos fechados (`fase5-dxf-exemplos/VALIDACAO_EZDXF.txt`).
- Desenho de cada arquivo pelo próprio leitor (`*.png` ao lado de cada `.dxf`).
- Teste `testFASE5_DxfParaCncContornosFurosERasgosSemInventar`: mesmas peças do corte, posição da dobradiça = `furInfo`, cavilha no centro da espessura da lateral, R12 com EOF, contornos fechados, bloqueio sem configuração, puxador barra, rebaixo da gaveta, botão no plano de corte.

## Compatibilidade com fluxo tipo Vectric Aspire (sem prometer universalidade)
- Aspire importa DXF R12; contornos fechados viram vetores de **perfil** (corte por fora — o diâmetro da fresa é do CAM; o campo "fresa" é só informação).
- Círculos por camada → **furação** (drilling) por camada: o nome da camada já traz Ø e profundidade.
- Rasgos/rebaixos (polilinhas fechadas) → **pocket** com a profundidade da camada; cava 30° → caminho de chanfro/V na aresta (operação manual no CAM).
- Furos `_F2` são na face de baixo: virar a chapa no CAM (posições estão vistas pela F1). Furos `FURO_TOPO_*` são em topo/aresta: exigem furação horizontal (não sai em fresadora 3 eixos comum).
- Não testado num Aspire real (não há licença no contêiner). Testado em leitor DXF (ezdxf). Conferir num arquivo de teste antes de produção.
