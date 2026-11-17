# Plano de execução depois da auditoria (17/11/2026)

**Referência:** `engenharia/AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md` (160 pedidos, 89 defeitos). Os IDs (A05, D26…) são os da tabela de pedidos dessa auditoria.

**Estado real do Android (conferido em 17/11):**
- A candidata **não foi publicada**. O ponteiro `apk-latest` continua na 1.0.632 (`7c939bc`).
- Nenhuma CI rodou em modo publicar. Não houve autorização com o commit.
- Não há publicação a repetir.

## Regras que valem para todas as etapas
- **Sem mexer no visual nem nas contas:** nada de layout ou identidade visual novos. Cálculo aprovado só muda com o erro demonstrado (conta atual, problema, correção) e com o seu sim.
- **Uma mudança de cada vez:** cada correção em commit próprio e com teste próprio. O teste falha antes e passa depois. Não juntar correções sem teste individual.
- **Chromium não aprova sozinho:** passar no Chromium não é aprovação. O aceite exige a plataforma de destino:
  - iPhone **e** iPad;
  - Windows (motor do Windows);
  - Android: CI e, quando houver, aparelho ou emulador.
- **App atual protegido:** desenvolvimento em branch própria. A `main` e os ponteiros não mudam. Publicação só com o seu "sim" para o commit e a plataforma.

## Etapa 1 — Segurança dos dados (prioridade 1)
| # | O que | Depende de | Critério de aceitação |
|---|---|---|---|
| 1.1 | **iOS: restaurar backup sem perder `foto..jpg`.** `ios/Arquemestre/Data/Backup.swift:51` pula todo nome com "..". Trocar pela regra do Android: só um pedaço do caminho igual a ".." é proibido. | — | Teste iOS novo (igual ao `BackupCaminhoTest`): `foto..jpg`, `a..b/c.json` e `projeto..v2.json` restauram; `../x`, `/abs` e `a/../b` continuam recusados. Falha antes e passa depois. A bateria do iOS continua passando. |
| 1.2 | **Mesmo risco na sincronização Wi-Fi** (`safeName` nas 3 plataformas recusa ".." e pula sem avisar). | 1.1 | Teste nas 3: `foto..jpg` sincroniza e um caminho com `..` como pedaço é recusado. **Ou** o app avisa o que foi pulado. A escolha é sua (decisão 13). |
| 1.3 | **Testes de preservação entre plataformas:** backup feito no Android, com projetos, fotos, vídeos e notas, restaurado no iOS e no Windows, e o inverso. | 1.1 | Arquivo de backup de referência guardado nos testes. Depois de restaurar: mesmos projetos (assinatura das peças e do corte), mesmos anexos (contagem e tamanho), nada apagado. |
| 1.4 | **Atualização por cima da versão anterior:** <br>• **Android:** CI com emulador. Instala a 1.0.632, cria dados, instala a nova por cima e confere. <br>• **iOS:** simulador, com o build anterior e depois o novo. <br>• **Windows:** instalador por cima no `windows.yml`. | decisão 2 (mexe só nos fluxos de teste) | Nas 3: projetos, anexos e ajustes iguais antes e depois. Cópia automática criada antes. Falha comunica e não apaga. |
| 1.5 | **Salvamento silencioso:** `putFile` sem retorno de erro nos 3 apps; campos fora do `snapState` (`S.pw`, `S.RDw/RDs`, `S.rodLast`, `S.deco`, `S.tvLogo`, `S.tvAnim`). | — | Primeiro **reproduzir** (só leitura de código até agora). Se confirmar: erro de gravação avisa a pessoa; os campos voltam iguais depois de salvar e reabrir. Teste para cada um. |
| 1.6 | **Triagem dos 15 defeitos abertos**, na ordem do que pode estragar projeto ou fabricação. | — | Para cada um: reproduzido ou não, causa, risco e proposta. Só corrige com o seu sim (decisão 10). |

Ordem proposta da 1.6:
1. **B25** `sanBase` apaga travessa e moldura (perde peça).
2. **B23** catálogo entra por cima dos vizinhos (peça dentro de peça).
3. **B05** vão de 35 mm junto à parede (posição errada).
4. **B24** rack e lateral que andam e não voltam.
5. **A29** engrosso do tamponamento entrando no módulo.
6. **B21** 3D aberto não atualiza a troca do vão.
7. **A31** setas da régua do canto e do rodapé.
8. **D10** "Achar peça" travando.
9. **Visuais:** A05 (calço da dobradiça na divisória) e A30 (porta do aéreo na fita).

## Etapa 2 — Plataformas (prioridade 3, mas em paralelo com a 1 quando não depender dela)
| # | O que | Depende de | Critério de aceitação |
|---|---|---|---|
| 2.1 | **Android:** publicar a candidata `6b0e9cd`. | decisão 1 | Seu "sim" com o commit. Depois: ponteiro novo, aviso com as novidades certas, sua confirmação num aparelho e reversão pronta. |
| 2.2 | **iOS:** bateria completa da candidata no **iPhone e no iPad**, StoreKit, backup e projetos. | 1.1; decisão 2 (o iPad precisa rodar mesmo se o iPhone falhar) | iPhone e iPad sem falha nova. StoreKit 11/11. `SubscriptionTests.test05` estável: causa achada, sem afrouxar. 15/15 projetos e backup. |
| 2.3 | **Windows:** `windows.yml` em modo teste na candidata (testes JVM, tour do app instalado, instalador) + testes que faltam: orçamento PDF, pedra e 2 de orçamento. | — | Testes JVM passando, tour ok, instalador gerado (sem publicar). Projetos 15/15. Atualização por cima (1.4). |
| 2.4 | **iOS do canto:** por que só 181 testes do editor rodaram (os outros rodam cerca de 343). | — | Causa explicada e execução completa. |

## Etapa 3 — Integrar as branches prontas, uma por vez (prioridade 2)
- **Depende de:** decisão 2 (linha de integração a partir da versão publicada).
- **Ordem:**
  1. fitas no 3D (rebaixo, depois portas);
  2. Plano de Corte;
  3. lateral do meio;
  4. travessão;
  5. canto;
  6. item 6 (precisa medir a porta piscando no aparelho e da sua homologação).
- **Critério de cada junção:**
  - conflitos resolvidos sem perder nenhum lado;
  - bateria completa;
  - Windows;
  - iOS (iPhone e iPad);
  - os testes da branch passam a existir na linha;
  - projetos 15/15;
  - seu aceite.
- Uma junção só começa depois da anterior estar verde.

## Etapa 4 — Funcionalidades pendentes (prioridade 2), na ordem pedida
| # | O que | Depende de | Critério de aceitação |
|---|---|---|---|
| 4.1 | **Tamponamento superior com lateral descendo à esquerda e à direita + medida livre real do vão** (D25, D26, D27). | referência (decisão 7) | Numa configuração conhecida, 3D, lista e corte iguais. Medida livre = medida da caixa − espessura e posição das laterais, conferida pela geometria. Salvar e reabrir. Projeto antigo igual. |
| 4.2 | **Plano de Corte:** integrar (Etapa 3) + "Achar peça" sem travar (D10). | Etapa 3 | Reproduzir a trava, achar a causa, criar teste. Peça achada e destacada; nada muda no corte. |
| 4.3 | **Travessões, molduras e laterais:** item 7 (D21, D22, D24) + lateral do meio (D14) + família do travessão (D20). | decisões 3, 4 e as dúvidas do item 7 | Testes numéricos 3D = lista = corte para cada montagem. "Salvar nos meus modelos" guarda a montagem e recalcula no tamanho novo. |
| 4.4 | **Fita de 1 mm** (D43): o quadro mostra a medida de **corte** e a **acabada** separadas, como você decidiu. **Menu Pintar compacto** (D44). **"#1" só fora da tela** (D45). | Etapa 3 (fitas) | <br>• **Fita:** corte do MDF, fórmulas e projetos iguais. Só o desenho e o quadro mudam. <br>• **Pintar:** todos os botões e a ordem dinâmica preservados. <br>• **Commits separados:** visual e dimensional. Cada um com teste. |
| 4.5 | **Módulos, seleção e movimentação:** B22 (catálogo avisa em vez de redimensionar), B26 (peças flutuantes ou cruzadas), B15 (GEO-AVISA nos pontos que faltam). | 1.6 | Para cada um: teste que reproduz, correção mínima, bateria nas 3 plataformas. |

## Etapa 5 — Auditorias finais (por último)
| # | O que | Critério |
|---|---|---|
| 5.1 | Auditoria de exclusão e consistência (D40) | A cadeia escolher → apagar → geometria → lista → corte → salvar → reabrir → desfazer/refazer conferida em todo o catálogo. |
| 5.2 | Inventário de pendências | Atualizar a tabela da auditoria geral. |
| 5.3 | Auditoria master (D58) | Precisão, bugs, atraso de comando, desempenho, persistência e estabilidade, medidos nas 3 plataformas. |

## As 14 decisões que precisam da sua resposta
1. **Publicar o Android agora?**
   - A candidata `6b0e9cd` (parede/pé-direito + precisão de toque) passou em tudo o que dá para testar aqui.
   - Pode publicar já ou depois de você testar o APK separado no seu celular.
2. **Autoriza a "linha de integração" e mexer só nos fluxos de teste da CI?**
   - **Linha de integração:** uma branch nova, a partir da versão publicada, onde as branches prontas entram uma por vez. A `main` não muda.
   - **Fluxos de teste:**
     - o iPad roda mesmo se o iPhone falhar;
     - um teste de atualização com emulador Android.
   - O app não muda com isso.
3. **Lateral do meio:** quando ela vira lateral inteira junto das gavetas, a base e a travessa de cima continuam **uma peça só** (passando por cima) ou viram **duas peças**, uma de cada lado?
4. **Travessão:** hoje vale só nos inferiores da cozinha. Quer também em racks, homes, módulos de TV, canto e montagens com "laterais por fora"?
5. **Fita de 1 mm na prática:**
   - Hoje a porta fechada encosta na frente da caixa, e a fita fica "dentro" da porta só no desenho.
   - Opções:
     - **(a)** deixar a porta onde está e esconder a fita no desenho (já feito na branch);
     - **(b)** afastar a porta 1 mm para a frente, para ficar como na marcenaria real.
   - A (b) muda a posição das portas no 3D, mas não muda o corte.
6. **Perfil G:** a porta com gola encosta 1,5 mm na caixa. Prefere uma **folga na dobradiça** (porta 1,5 mm mais à frente) ou um **rebaixo na caixa** (a peça sai com o recorte no corte)?
7. **Tamponamento superior com lateral descendo:**
   - O vídeo não chegou.
   - Mande de novo a referência (vídeo ou desenho com medidas).
   - Diga se a lateral descendo é do mesmo MDF do tamponamento e até onde ela desce.
8. **Porta piscando e zoom:**
   - Só dá para corrigir com um caso real.
   - Grave a tela no celular mostrando a porta piscando nos 2 toques.
   - Mostre também um toque com zoom que pegou a peça errada.
9. **Churrasqueira quadrada e textura da pia/área molhada:** não achei registro em lugar nenhum. Mande de novo o pedido e a referência.
10. **Defeitos antigos da Fase 1/2:**
    - Autoriza corrigir, um por vez e com teste:
      - **B05:** vão de 35 mm na parede;
      - **B21:** 3D sem atualizar ao trocar o vão;
      - **B23:** catálogo por cima dos vizinhos;
      - **B24:** rack e lateral que andam;
      - **B25:** travessa e moldura que somem.
    - B22 (móvel novo avisa em vez de diminuir) já está decidido e entra na etapa 4.5.
11. **Divisória e dobradiça:**
    - No 3D, o calço da dobradiça entra na divisória em 16 modelos.
    - Corrigir afastando o calço?
    - E porta baixa fica com 2 furos de dobradiça ou com a regra pela altura?
12. **Forno e micro-ondas:** o 🗑 do "corte do forno" e do "nicho do micro" pode apagar com o aparelho no lugar, ou deve pedir para tirar o aparelho primeiro?
13. **Arquivo pulado na sincronização Wi-Fi:** quando um nome de arquivo for recusado por segurança, o app deve **avisar** ou **aceitar** nomes como `foto..jpg` (como no backup)?
14. **Pedidos grandes antigos ainda sem início:**
    - exportação para CNC;
    - eletrodomésticos reais com medidas travadas;
    - padronização estrutural universal;
    - editor por vãos em todos os módulos;
    - 3D com luz, metal e vidro realistas;
    - AQRender.

    Ficam na fila (em que ordem) ou ficam para depois do lançamento?
