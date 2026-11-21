# Auditoria geral — 19/11/2026 (pedido do Adauto: "AUDITORIA GERAL, HOMOLOGAÇÃO E ATUALIZAÇÃO FINAL")

Referência: `claude/arquemestre-gavetas-paredes`, commit `63b65c5` (código igual ao `0d34949` + 1 teste de guarda).

## Resultado dos testes
- Bateria do editor (Chromium, local) em `0d34949`: **378/378**.
- CI Android 649: ok · atualização 636 → nova (emulador, 10): ok.
- CI Windows 156: ok · bateria do Windows 57: ok · atualização 143 → nova (5): ok.
- CI iOS 632: iPhone **450 testes, 0 falhas**; editor 379 executados com 1 falha **esperada** (0 inesperadas); iPad verde; nenhuma queda do app.
- Testes de guarda novos nesta auditoria: `testCorteChapasEOrcamentoNaoDuplicamEVoltamIguaisAoTirar`, `testCatalogoInteiroMesmaPecaNo2DNo3DENoCorteSemDecimo`, `testCenarioCompletoDoClienteAoBackupTudoCoerente`, `testTamponamentoLivreSobeEAtualizaNaHoraNoPlanoDeCorte`.

## Itens do checklist (184)
- 96 já estavam VALIDADOS com teste.
- Os outros 88 estão abaixo, cada um com estado e justificativa. Nenhum foi dado como feito sem prova.


### FEITO NESTA RODADA (comprovado) (8)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| C10 | Homologação completa do iOS (iPhone e iPad) e finalizar iOS depois do Android | CI iOS 632: iPhone 450 testes, 0 falhas; iPad verde; sem queda do app |
| D57 | Linha de integração segura das branches | linha de integração: claude/arquemestre-gavetas-paredes recebe só o que passou na bateria; CIs das 3 plataformas no mesmo commit |
| N03 | Salvamento: `putFile` sem retorno de erro nos 3 nativos; a abertura seguinte carregava o arquivo velho por cima do que foi feito | bateria 378/378 e CI iOS 632 (iPhone e iPad) verdes; testGravacaoDoArquivoDeProjetosQueFalha… e testDadosDoAmbienteEEscolhasDo3DVoltam… |
| N04 | 7 campos fora do `snapState` (painéis da parede, profundidade da sala, rodapé, escolhas do 3D) voltavam ao padrão | bateria 378/378 e CI iOS 632 (iPhone e iPad) verdes; testGravacaoDoArquivoDeProjetosQueFalha… e testDadosDoAmbienteEEscolhasDo3DVoltam… |
| N16 | GAV-SET: lateral de uma gaveta muda todas as gavetas do conjunto (pedido 18/11) | GAV-SET: testes da altura da lateral do conjunto; bateria e CIs verdes |
| N20 | PAREDE-ESPELHADA: parede da esquerda invertida no 2D (pedido 18/11) | PAREDE-ESPELHADA: 5 testes da parede esquerda, inclusive no tamanho do iPhone; CI iOS 632 verde |
| N21 | PORTA-CAVA: porta cava na aba Portas do editor por vãos (pedido 18/11, foto) | testPortaCavaNaAbaPortasDoEditorPorVaos |
| N24 | FUNDO-SOBRE: fundo de armário sempre sobreposto, rasgo só na gaveta (regra 18/11, foto) | FUNDO-SOBRE: testes do fundo sobreposto/rasgo só na gaveta |

### FEITO, FALTA APARELHO REAL (2)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| N13 | Vídeos do editor no Android e no Windows ficam só no banco do navegador: backup do Android restaurado no iPhone/Windows perde os vídeos (o iOS já grava em arquivo) | funciona na bateria e nas CIs; o gesto com o dedo / o arquivo de vídeo de ponta a ponta só se confirma em aparelho |
| N23 | MENU-ARRASTA: menu rápido do vão arrasta pro lado e minimiza (pedido 18/11, foto) | funciona na bateria e nas CIs; o gesto com o dedo / o arquivo de vídeo de ponta a ponta só se confirma em aparelho |

### PARCIAL (o que falta está descrito) (8)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| A32 | Editor por vãos em todos os módulos; trava do “só ele no 2D” que converte módulo alto | editor por vãos: torre (inclusive direto no projeto) e balcão da pia; balcões comuns, aéreos e guarda-roupas não convertem (27 modelos mudariam peças na conversão — risco registrado) |
| D24 | Testes numéricos 3D = lista = corte em todas as montagens | 2D = 3D = corte = sem décimo conferido no catálogo inteiro (testCatalogoInteiroMesmaPeca…); faltam testes numéricos por montagem especial (moldura, frontal, modelos) |
| D27 | Mostrar medida livre real do vão (largura e altura) | o vão escolhido no editor por vãos mostra a medida livre real (ex.: 870 × 2270); no editor normal ainda não |
| D34 | Desempenho e resposta imediata medidos e comparados | sem medição de desempenho comparada nesta rodada |
| D35 | CLAUDE.md §12 e §13 nas instruções permanentes | documentação de continuidade atualizada (HISTORICO, checklist, transferência); §12/§13 do CLAUDE.md não incluídos |
| D37 | Continuidade: estado real, commits, testes e pendências no repositório | documentação de continuidade atualizada (HISTORICO, checklist, transferência); §12/§13 do CLAUDE.md não incluídos |
| D58 | Auditoria master final de todas as ferramentas | esta auditoria (AUDITORIA_GERAL_2026-11-19.md); a auditoria master de ferramentas (desempenho, medição Bluetooth etc.) não foi feita |
| D59 | Inventário de pendências e AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md | esta auditoria (AUDITORIA_GERAL_2026-11-19.md); a auditoria master de ferramentas (desempenho, medição Bluetooth etc.) não foi feita |

### AGUARDA AUTORIZAÇÃO DO ADAUTO (3)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| C09 | Enviar iOS 3.0.13 ao TestFlight | publicação/TestFlight: candidata pronta, só com o sim dele |
| D52 | Publicar a candidata Android | publicação/TestFlight: candidata pronta, só com o sim dele |
| D56 | Finalizar Windows depois do iOS | publicação/TestFlight: candidata pronta, só com o sim dele |

### DECISÃO DO ADAUTO (3)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| N11 | Número de chapas varia com a máquina (otimizador por tempo) | N22 puxador cava do projeto nas torres por vãos; N14 cópia de segurança do Android antes de usar a versão nova; N11 número de chapas varia com a máquina |
| N14 | Android: a cópia "antes-de-usar-a-versao-N" só é feita na primeira vez que a pessoa SAI da versão nova (onStop), depois de já ter usado. Pela atualização dentro do app há backup forçado antes de baixar; atualizando por fora (site/APK manual), a primeira sessão da versão nova fica sem cópia anterior | N22 puxador cava do projeto nas torres por vãos; N14 cópia de segurança do Android antes de usar a versão nova; N11 número de chapas varia com a máquina |
| N22 | Puxador cava do projeto (Ajustes) não chega nas torres por vãos (tipo `rt`) | N22 puxador cava do projeto nas torres por vãos; N14 cópia de segurança do Android antes de usar a versão nova; N11 número de chapas varia com a máquina |

### BLOQUEADO (2)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| N05 | Atualização por cima da versão anterior sem teste (3 plataformas) | **atualizado 21/11:** o commit publicado do iOS é conhecido (3.0.12 = `d861fbd`). Atualização por cima no simulador: 8/8 arquivos iguais (20/11). Desde 21/11 o mesmo teste também abre os projetos no editor e as notas (`AtualizacaoAbreProjetosTests`); resultado no CI da rodada. Android e Windows ok. Falta aparelho real |
| N12 | Licença 3 dias/relógio voltado sem teste (Android site e Windows); Play/Billing sem teste | regra de licença não pode ir pro repositório público (CLAUDE.md) |

### PRECISA DE APARELHO REAL (1)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| N15 | iOS: 2 testes que dependem de tempo falham às vezes na 1ª tentativa e passam na repetição: `EditorAppPathTests.testEditorAbreComoNoAppSemTelaBranca` (editor abriu em 25–45 s, limite 20 s; no Chromium abre em 0,4 s, sem diferença entre publicada, N03 e integração) e `testMaoDeObra…` parte `botaoPegaDePrimeiraEOValorEntra` | 2 testes de tempo que às vezes falham na 1ª tentativa no iOS; na CI 632 não falharam |

### PRECISA DE REFERÊNCIA (pedido original não achado) (2)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| B07 | Churrasqueira quadrada conforme referência | churrasqueira quadrada e textura da pia/área molhada: referência não localizada |
| B08 | Correções de textura da pia e da área molhada | churrasqueira quadrada e textura da pia/área molhada: referência não localizada |

### DEFEITO RELATADO AINDA NÃO CORRIGIDO (próximo lote) (14)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| A05 | Calço da dobradiça entra na divisória no 3D (16 modelos) | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| A30 | Porta do aéreo encosta 0,8 mm na fita de borda da caixa | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| A31 | Setas da régua espaçadora do canto e do rodapé até o piso não mexem | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B05 | Posição digitada deixa vão de 35 mm junto à parede | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B21 | Sincronização imediata 2D/3D (vão → gavetas com o 3D aberto) | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B22 | Móvel novo do catálogo não é redimensionado para caber (avisa a diferença) | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B23 | Módulo do catálogo entra por cima dos vizinhos em parede cheia | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B24 | Folga do rack que não volta; módulo da parede lateral que anda e não volta | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B25 | Travessa e moldura perdidas ao alternar sup/rack (sanBase) | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| B27 | Aviso de pedra/lixeira/objetos fora da parede (3 plataformas) | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| D10 | Travamento ao “Achar peça” no plano de corte | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| D18 | Porta/janela da parede: 1 toque seleciona, 2 toques abrem a configuração | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| D30 | Precisão com zoom; não escolher peça escondida | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |
| D31 | Porta piscando nos 2 toques sem atrasar o 1 toque | relatados antes; nenhum foi reproduzido nem corrigido nesta rodada. Prioridade: os de geometria/dados (B05, B22, B23, B24, B25, A30) antes dos de toque/visual |

### NÃO REPRODUZIDO (1)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| A29 | Engrosso do tamponamento entrando no módulo | engrosso entrando no módulo: não reproduzido (REGRAS_MARCENARIA, TAMP-ENGROSSO); a auditoria do catálogo não achou peça dentro de peça |

### FUNÇÃO NOVA AINDA NÃO FEITA (escopo grande) (21)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| A03 | Perfil G: afastamento da porta e rebaixo na caixa configuráveis | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| A22 | Módulo criado no 2D que não aparece no 3D (iOS) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| A33 | Luz, metal e vidro realistas (protótipo) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| A34 | Exportação para CNC (furação, rasgos, nesting) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| B15 | Ambiente não modifica móveis; aviso com módulo/medida/disponível/diferença; móvel novo × existente (roomClamp) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| B19 | Eletrodomésticos reais com dimensões bloqueadas e requisitos de instalação | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| B20 | Padronização estrutural universal (portas, gavetas, prateleiras no vão certo) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| B26 | Validação de peças flutuantes e interseções indevidas | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D01 | Régua do batente cava com altura/largura manual (só esta / módulo / projeto) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D02 | Altura do batente cava calcula as frentes e posiciona batentes | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D14 | Lateral do meio inteira junto das gavetas no inferior da cozinha (com rebaixo); aviso para módulo antigo | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D20 | Travessão interno/externo, com Frontal (recuo), lateral do meio até o topo, painel Moldura → Travessão → Frontal | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D21 | Item 7: regras automáticas de Moldura e Frontal | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D22 | Salvar nos meus modelos com a estrutura paramétrica (recalcula no novo tamanho) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D23 | Identidade estável única de módulo e peça (corte, editor, 3D) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D25 | Tamponamento editável por 2 toques no 3D, campo numérico e ±1 mm | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D40 | Auditoria geral de exclusão e consistência | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D43 | Fita de borda 1 mm padrão; quadro distingue corte × acabada | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D44 | Menu Pintar compacto (cabeçalho 2 linhas, ordem dinâmica, 2 colunas no tablet) | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D45 | Tirar o “#1” só da apresentação do nome da peça | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |
| D50 | Rodar iOS das branches plano de corte, lateral, canto e travessão | pedidos de função ou reestruturação que dependem de especificação/referência ou de muito trabalho; nenhum foi iniciado nesta rodada |

### FEITO SEM PROVA AUTOMÁTICA (validar) (12)
| ID | Pedido | Justificativa / evidência |
|---|---|---|
| A39 | “Lista de peças (ao vivo)” na aba Fundos mostra a peça no 3D | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| A65 | Módulo de baixo erguido e devolvido: rodapé, travessa e moldura voltam | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| B16 | Gravação desnecessária da biblioteca inteira depois da 1ª alteração | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D07 | Azul de seleção mais suave | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D09 | Rodapé fora do plano de corte (opção A, trechos do rodapé corrido) | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D12 | Tirar peça do plano de corte por toque longo 1,5 s / clique direito, por identidade | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D13 | Peças brancas juntas no plano de corte | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D19 | 1 toque igual ao original + teste de regressão | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D38 | Canto em L: folha do lado cobre 5 mm atrás e folga de 4 mm | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D41 | Fita de 0,8 mm do rebaixo desenhada dentro da travessa frontal no 3D (só visual) | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D42 | Fita de 0,8 mm dentro de porta/frente fechada no 3D (só visual) | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |
| D47 | Corrigir só o teste testToPecaQueO3DOfereceApagar… (identidade, totais da geometria) | o código existe segundo o checklist, mas não há teste específico encontrado; precisam de teste ou conferência visual |

### Outros (estado do checklist mantido)
| ID | Pedido | Estado |
|---|---|---|
| D26 | Tamponamento superior com lateral descendo à esquerda/direita | FEITO (18/11) |
| N01 | iOS: restaurar backup pulava, sem avisar, arquivos com ".." no nome (`foto..jpg`) | erro no código |
| N02 | Sincronização Wi-Fi (3 plataformas) recusava `foto..jpg` | erro no código |
| N06 | Backup entre plataformas (Android ↔ iOS ↔ Windows) | sem teste |
| N07 | iOS: etapa do iPhone deu falha com 373 testes e 0 falhas (CI 616); `SubscriptionTests.test05` instável | investigar |
| N08 | iOS: o iPad nunca rodou | CI |
| N09 | Windows: testes próprios (JVM, tour, instalador) sem execução na candidata; faltam `QuotePdfTest`, `StoneFitTest`, 2 de `QuoteMathTest` | sem teste |
| N10 | iOS do canto rodou só 181 testes do editor | investigar |
| N17 | GAV-EXCESSO: redução da caixa errada depois de pedir mais que o máximo (achado 18/11) | erro comprovado |
| N18 | DUPLO-TOQUE: 2 toques não funcionavam em 8 itens do catálogo (geladeira e torres altas) (pedido 18/11) | erro comprovado (567 itens auditados) |
| N19 | PAREDES/CANTO-SOZINHO: abrir o projeto, tocar ou trocar de parede movia móveis do canto (7 de 15 projetos) | erro comprovado |

## Pedidos desta rodada (17–19/11), todos com teste que falha antes e passa depois
GAV-SET · DUPLO-TOQUE · CANTO-SOZINHO · PORTA-CAVA · MENU-ARRASTA · FUNDO-SOBRE · FITA-CORTE (guarda) · SEM-AVISO-ERRO · PAREDE-ESPELHADA (+ ajustes da borda e do iPhone) · TORRE-DIRETO · VAOS-BALCAO · TAMP-DESCE (livre, independente, embaixo do de cima) · fita do tamponamento livre no orçamento · AUDITORIA-GEOMETRIA · CENARIO-COMPLETO · AUDITORIA-DUPLICAR. Detalhes, causa e commits no HISTORICO_ERROS.md.

## Riscos restantes (registrados, decisão do Adauto)
- Parede esquerda: na lista e no plano de corte os nomes esquerdo/direito ficam os guardados (trocar apagaria as marcas "✓ cortada").
- 27 modelos (guarda-roupas, cantos retos, torres da sala) mudam peças ao entrar no editor por vãos pelo 2D isolado (já era assim).
- Ao passar um móvel pra outra parede, o lado exposto ganha o tamponamento automático (regra antiga).
- Tamponamento livre que desce: só na parede do fundo.
- Sem teste em aparelho real nesta rodada. A atualização por cima no iOS já usa o commit publicado (3.0.12 = `d861fbd`, ver abaixo), mas só no simulador.

## Segurança dos dados
- Nenhuma mudança de formato que apague ou reescreva projeto; campos novos só aparecem quando a pessoa usa a função (ex.: `desce`/`dm` no tamponamento livre).
- Projeto antigo com móveis na parede esquerda abre igual (`testProjetoAntigoComMoveisNaParedeEsquerdaAbreIgual`); salvar/fechar/reabrir e backup/restauração conferidos no cenário completo; atualização por cima com 8/8 arquivos iguais no Android e ok no Windows.
- Nada foi publicado. Ponteiro público do Android continua no apk-636.

## Os 14 defeitos antigos — rodada de 19/11 (economia de créditos, aprovada pelo Adauto)
| ID | Resultado |
|---|---|
| B05 | **Corrigido.** Reproduzido (25 digitado virava 35 sem tamponamento). Causa: o encaixe na parede contava o tamponamento automático antes de ele ser reavaliado. Teste `testPosicaoDigitadaPertoDaParedeDaOMesmoResultadoSemVaoSemTamponamento` falha antes e passa depois. |
| B24 | Reproduzido pela sonda s27 (rack com espessura +3 e volta; módulo 3 do demo com largura +100 e volta não ficam iguais). **Adiado:** não muda nada sozinho; só não desfaz quando a pessoa volta a medida. |
| B21 | Reproduzido pela sonda s23 (o 3D aberto atualiza só no próximo desenho em 3 casos). **Adiado:** só visual; dados e corte corretos. |
| B22, B23 | Reproduzidos pela sonda s29 (móvel novo do catálogo encolhido pra caber em parede cheia). **Adiados:** afetam só o móvel novo, nunca os existentes; a regra de onde pôr o móvel que não cabe precisa de decisão. |
| B25 | Não reproduzido nesta rodada. Adiado. |
| A31, D10 | Não reproduzidos nesta rodada (setas da régua espaçadora; "Achar peça"). Adiados. |
| A05, A30 | Aguardam decisão do Adauto (registro original). |
| D18 | Revertido por ordem do Adauto (preservar o 1 toque): não é defeito. |
| D30, D31 | Precisam de aparelho real (não reproduzidos no Chromium). |
| B27 | Melhoria (aviso novo): fora desta versão. |

## Versão publicada do iOS (corrigido em 20/11, conferido no App Store Connect pelo asc-diag)
- **Na App Store (ao público): 3.0.12, build 321, código `d861fbd`** (07/11, branch `feature/arque-measure-kotlin`).
- 3.0.50 (build 548, `3799060`): está em **PREPARE_FOR_SUBMISSION**, nunca foi enviada à revisão. A anotação antiga ("enviada pra revisão em 15/11") estava errada.
- TestFlight: builds até 574 (teste interno, não é publicação).
- **Atualização por cima no iOS:** `ios-atualizacao.yml` (só simulador, não publica). Instala a 3.0.12 (`d861fbd`), põe o backup de referência, instala a nova por cima e abre. Execução 44836226818 (20/11): **8/8 arquivos iguais** (sha256 de projetos, índice, imagens, notas, preços, foto do móvel), 0 falhas. Nessa execução não abria os projetos dentro do editor. **21/11:** o teste passou a abrir cada projeto no editor da versão nova (medidas, peças, corte, foto) e as notas (medida e foto), e confere os arquivos de novo depois. O backup de referência ganhou notas no formato real (as antigas não abriam em nenhum app). Continua sem aparelho real.

## Rodada de 21/11 (autorização do Adauto de 21/11)
| Item | Situação | Evidência |
|---|---|---|
| Etapa B no `gavetas-paredes` | **integrada** (avanço direto até `7e0c5b1`, já verde no CI), B22/B23/B24 preservadas | CIs de 20/11 |
| R-CANTO | **corrigido** (canto não empurra; pergunta ou impede) | teste novo falha antes e passa depois; 2 testes com a preparação ajustada pela decisão |
| Faixas da cava no móvel livre | **corrigido** (0/90/180/270 e paredes do lado) | teste novo; 3D da parede do fundo idêntico |
| Etapa C (segurar 2 s) | **implementado** (decisão: o mesmo menu dos toques; mouse só segurar) | teste novo com toques de verdade; 3 defeitos achados e corrigidos no caminho |
| Projeto sem `shv` | **corrigido** (abria quebrado) | teste novo |
| Atualização por cima no iOS abrindo os projetos | **implementado**; resultado no CI da rodada | `AtualizacaoAbreProjetosTests` + passos 5 e 6 do script |
| N15 e teste da animação | **não foi possível verificar** (só no simulador do iOS); o teste agora mostra a causa quando falha | 49aca08 |
| Regra do canto mínimo (fundo ≥ prof. do lado + 200; lado ≥ prof. + 200) | **a confirmar pelo Adauto** (deduzida da construção atual) | `DECISOES_TECNICAS.md` |
