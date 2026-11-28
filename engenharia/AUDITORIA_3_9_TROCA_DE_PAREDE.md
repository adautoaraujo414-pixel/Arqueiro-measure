# Auditoria 3.9 · trocar a parede vista ou a câmera não muda o projeto (Adauto 28/11, liderada pelo Code 2)

**Regra:** trocar a parede vista ou a câmera NUNCA altera estrutura, medida, posição ou configuração de móvel. A vista representa o projeto fielmente.

## Como foi conferido
Sondas e testes que comparam bit a bit:
- o estado salvo (`snapState`, chaves ordenadas);
- as peças de cada módulo (`partsOf`: pk, posição, medida e medida de corte);
- a lista de corte (`cutGroups`) e o orçamento (`budget`).

Dois ambientes completos, montados como projeto salvo:
- **L** (11 módulos): canto em L esquerdo e direito, 2 balcões e 2 aéreos no fundo, asa esquerda espelhada (2 balcões + aéreo, `espE`), asa direita (balcão de gavetas + armário alto).
- **C** (6 módulos): canto cego esquerdo e direito, balcão no fundo, asas que cruzam na frente dos cegos e aéreo na direita.

Sequência:
- 11 trocas (e f d f e d e f d e f: os dois sentidos, repetidas);
- as 4 câmeras do 3D (isométrica, frente, cima, lado), duas voltas;
- abrir o 3D estando numa parede lateral;
- salvar, fechar, reabrir e repetir as 11 trocas.

Também: criar régua segurando 2 s no desenho de cada parede.

## Achados
| # | Classe | Achado | Causa | Correção | Teste |
|---|---|---|---|---|---|
| 1 | **Defeito (corrigido)** | Parede ESQUERDA (espelhada): a régua/peça criada aparecia FORA do módulo (−55% em vez de 25%), e o toque nela não pegava. No 3D e no projeto estava certa. É a "régua na parede errada" / "peça inexistente". | A capa e as alças das peças (`#emov`) e o anel do segurar (`#emlp`) entravam no desenho DEPOIS do grupo espelhado (`#wvmir`), sem espelhar. É o mesmo mecanismo da trena (MED-PAREDE, 23/11). | Os dois entram no grupo espelhado. | `testETAPA3_ReguaCriadaEmCadaParedeNasceEFicaOndeTocou` (falha antes, passa depois); prints `a39_regua_parede_esquerda_{antes,depois}.png` |
| 2 | **Defeito (corrigido)** | Virar canto pelo botão da Estrutura deixava 2 molduras no canto; ao REABRIR elas sumiam (abrir mudava o projeto e a lista). | `cnVira` não aplicava a regra do balcão de canto (sem moldura deitada), que o `mkCorner` e a abertura (`loadState`) aplicam. | `cnVira` aplica a regra na hora, como o `mkCorner`. | `testETAPA3_VirarCantoNaoDeixaMolduraQueSomeAoReabrir` (falha antes, passa depois) |
| 3 | Conferido, sem defeito | Trocar de parede (11 trocas, nos dois sentidos), câmera e reabrir: estado, peças, corte e orçamento iguais bit a bit nos dois ambientes. As peças de cada módulo na vista lateral são as mesmas do projeto (lados A/B, portas, divisórias, travessas, bases, réguas e tamponamentos sem inverter). | — | — | `testETAPA3_TrocarParedeECameraNaoMudaOProjetoCantoLEDComAsas`, `testETAPA3_TrocarParedeECameraNaoMudaOProjetoCantosCegos` |
| 4 | Conferido, sem defeito | Abrir o 3D estando numa parede lateral: sai da vista e mostra o ambiente inteiro (12 grupos = 11 módulos + sala). | — | — | sonda `shot3` |
| 5 | Conferido, sem defeito | Mecanismos citados: `toView`/`toCanon` (KEYS mods/rp/ops/fr) devolvem tudo; `espN`/`espE` ficam no módulo; `l2w`/`w2l` são inversos nas 3 paredes; `une`, `cnPassa`, `cgTrav` e `latMeioW` não são tocados pela troca. | — | — | testes acima |
| 6 | **Para decidir** | Vistas laterais: a perna do canto em L que fica nessa parede não é desenhada (o começo da parede aparece vazio). No 3D ela aparece. Igual no publicado 5067fec (não é regressão). Pode ser o "L representado errado". | O canto fica só no fundo (`toView` deixa o canto fora da parede vista). | Proposta: desenhar a perna do canto na vista lateral como referência (só desenho, sem tocar, sem entrar no corte). | prints `a39_L_{e,d}.png` |

Prints de cada parede: `diagnosticos/etapa3/code2/a39_{L,C}_{f,e,d,3d}.png`.
