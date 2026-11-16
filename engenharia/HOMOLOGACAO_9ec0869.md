# Homologação da Fase 1, commit `9ec0869` (16/11/2026, noite)

**Versão testada:** `9ec0869`, congelada. O mesmo arquivo foi usado na bateria e em todas as sondas, e nada foi mudado durante a validação.

**Ambiente:** Chromium 153 sem interface, 1366×768, WebGL por SwiftShader. Sem dados reais.

## Bateria
**333 testes: 332 passaram e 1 falhou** (2153 s). São os 323 da linha de base mais 10 novos.

A única falha é `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase`, só na parte "ergueu" (b590 em vez de b1410):
- já falhava na linha de base `0aa152c`;
- o teste arrasta 90 px, e nesta tela isso dá 590 mm (no simulador do iPhone, 1410);
- o pulo de 875 mm para o lado que ele também acusava **não acontece mais**: "voltou pro chão", 3D, corte e reabrir passam.

## Sondas, todas em `9ec0869`

| Sonda | Resultado |
|---|---|
| s01 catálogo: pureza, salvar/reabrir, incremental | limpo nos 142 modelos (só `wing` indefinido → 0, normalização inofensiva) |
| s02 cozinha inteira | limpo: olhar não muda, reabrir igual, desfazer igual, parede encolhe e volta igual |
| s07 peça tirada e engrosso | peça tirada sai em todos. Engrosso 30/30 preservado com o ajuste desligado e religado (antes 30 → 0) |
| s08a arquivo vazio | navegador mantém 1 projeto (antes 1 → 0) |
| s08b abrir sem mexer | data não muda e o engrosso fica 30 (antes a data mudava e o engrosso ia a 0) |
| s10 desenhar/montar 3D de novo | nenhuma mudança. A guarda desfaz e avisa as tentativas de empurrar |
| s11 ida e volta (parede, pé-direito, pedra, largura, erguer, desfazer, reabrir) | **todos voltam iguais** (antes: torre 2400 → 2300, vizinho e pedra empurrados) |
| s12 tamponamento pelo arrasto | determinístico |
| s15 ordem dos módulos | não muda nada |
| s24 desempenho | 40 módulos: draw 27 ms, 3D 34 ms, reabrir 46 ms. Sem vazamento |
| s25 arrasto vertical | não pula mais de lado |
| s26 medida → 2D → 3D → corte | sem achado novo (fundo sobreposto: +6/7 mm na profundidade do 3D, coerente com a regra cadastrada) |
| s27 mudar e voltar (142 modelos × 10 trocas, ambiente da cozinha) | ambiente: tudo igual e o aviso some. Restam 2 defeitos antigos (abaixo). 1 diferença não reproduzida sozinha (Balcão da pia, erguer 300) |
| s28 duas sessões | medidas iguais na sessão nova, duplicar cria a cópia igual, desfazer/refazer certos, abrir não muda a data |
| s29 criar não muda medida | **móveis existentes nunca mudaram** (146 criações). O **novo**, numa parede cheia, nasce com a largura que cabe no espaço livre (comportamento antigo de criação, com aviso "O módulo novo foi ajustado pra caber no espaço livre") |
| s30 parede lateral com o móvel no fim | posição gravada 2135 = na tela = reaberto. Cabe (fim 3135 + tamponamento 30 ≤ 3170), sem aviso falso. Desfazer e refazer certos. Parede continua 3170 |
| s31 tamponamento esquerdo/direito simétrico | **10 de 10 certos** (parede, vizinhos, parede cheia, canto). Regra do canto só ao posicionar, nunca ao abrir ou desenhar |
| JVM restauração de backup | **13 de 13 passaram** |
| s20 sequências aleatórias | sem erro de JS, desenhar de novo, reabrir, 3D, décimo e desfazer/refazer certos. I7 (catálogo sobrepõe em parede cheia) e I6 (módulo fora da parede depois de encolher a parede: **esperado pela regra nova**, com aviso) |
| s05 ida e volta direto nos dados | superada pela s27: a s05 cria e muda na mesma ação, então o módulo ainda é "recém-criado" |

## Defeitos que continuam (nenhum é regressão da Fase 1)
| Defeito | Desde | Sonda |
|---|---|---|
| P1-E: arrastar a divisória de um módulo não escolhido muda a do escolhido | antes | s09 |
| P1-G: escolha de divisória passa para outro projeto (🗑 apaga a do B) | antes | s22, s21 |
| P1-D: "Só a pedra no 3D" fica ligado entre projetos | antes | s14 |
| P1-B: pelo campo, x=5 vindo de 800 fica em 35 sem tamponamento (vão de 35 mm) | antes | s13 |
| I7: módulo novo do catálogo entra por cima dos vizinhos em parede cheia | antes | s20 |
| Trocar o vão por gavetas com o 3D aberto não atualiza o 3D | antes | s23 |
| Rack: a folga sobe com a espessura e não volta | antes | s27 |
| Alargar o módulo da parede lateral contra o vizinho: o próprio módulo anda para caber e não volta ao reduzir (antes empurrava o vizinho e a pedra) | antes, agora menor | s27 |
| `sanBase`: `sup`/`rack` ida e volta perde travessa e moldura | antes | s05 |

## Não executado aqui
- 2 testes novos do iOS em `BackupSafetyTests` (não há Xcode aqui).
- Compilação completa do Android e do Windows: o servidor dl.google.com está bloqueado na rede deste ambiente.
