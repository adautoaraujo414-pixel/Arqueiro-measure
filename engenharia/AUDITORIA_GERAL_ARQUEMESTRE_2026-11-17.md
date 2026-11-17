# Auditoria geral do Arquemestre — 17/11/2026

**Só auditoria.** Nenhum arquivo do app foi alterado. Nada foi publicado.
- Versão pública: Android 1.0.632 e Windows win-143, commit `7c939bc`.
- Candidata Android: `a13c9e6` / `6b0e9cd`, homologada e aguardando autorização.

## Como foi feito
- **Leitura de:**
  - todos os `engenharia/*.md` de 11 branches;
  - o histórico de commits (`git log`, `merge-base`, `cat-file`);
  - todos os pedidos desta conversa;
  - as novidades das versões;
  - o código das 3 plataformas;
  - os 4 workflows de CI.
- **Validação:**
  - **Regra:** cada conclusão "validado" cita um **teste com nome** que existe e passou, ou uma sonda registrada. Commit ou texto dizendo "corrigido" não bastou.
  - **Evidência usada:** bateria da candidata 357/357 (Chromium) e as CIs Android 634/635, Windows 45/46 e iOS 609–618.
  - **Limite:** "validado" aqui é sempre **no Chromium ou na CI**. **Nenhum item foi testado em aparelho real** (celular, tablet, iPad ou PC do usuário).
- **Fato e hipótese ficam separados** nos anexos. O que é hipótese ou só leitura de código está marcado "não reproduzido".

## Resumo executivo (percentuais sobre o que foi identificado)

| Conjunto | Total | Implementado e validado | Sem validação suficiente | Parcial | Não implementado | Corrigido com regressão | Não localizado |
|---|---|---|---|---|---|---|---|
| Pedidos do Adauto | 160 | 96 (60,0%) | 12 (7,5%) | 17 (10,6%) | 33 (20,6%) | 0 | 2 (1,3%) |
| Defeitos registrados | 89 | 60 (67,4%) | 6 (6,7%) | 8 (9,0%) | 15 (16,9%) | 0 | 0 |
| Itens funcionais do editor (lista da auditoria) | 33 | 22 (66,7%) | 8 (24,2%) | 2 (6,1%) | 1 (3,0%) | 0 | 0 |

- **Pedidos validados:** 63 dos 96 já estão na versão **publicada** (`7c939bc`). Os outros estão em branches **não publicadas** (P0 e Fase 3 estão na candidata Android).
- **Defeitos validados:** 41 dos 60 estão na versão publicada. Dos 19 que estão só em branch, 9 **nem estão na candidata**: item 6, lateral do meio, travessão, canto e as duas correções da fita.
- **"0 corrigido com regressão":**
  - 8 regressões apareceram durante o trabalho: F3-SEL, poAlign, A6-OP (revertido), BKP-PONTOS, GAV-MARCA-GDQ e outras.
  - Todas já têm correção e teste passando.
  - Isso **não** prova que não haja regressão desconhecida; só que nenhuma conhecida está aberta.
- **Não localizados (2):** churrasqueira quadrada e textura da pia/área molhada. Não há registro em commits, documentos, novidades nem testes.

## Respostas diretas

### 1. O que eu pedi e já está funcionando (validado por teste)
Na versão **publicada** (1.0.632), com teste que passou na bateria de hoje:
- **Perfil G (gola):** abertura para a frente, parede de 42 atrás, sem placa. Passada sólida, sem madeira aparecendo.
- **Tamponamento:**
  - não fica mais "invisível": medida e peça andam juntas, também em base suspensa;
  - estica pela seta do 3D, inclusive tocando na régua.
- **Apagar no 3D:**
  - fundo, gaveta e canto saem do 2D, do 3D, da lista e do corte, sem fantasma;
  - peça estrutural explica por que não sai.
- **Saia:** o armário inteiro vai até embaixo da saia.
- **Projetos e backup:**
  - arquivo de projetos vazio ou danificado não apaga a cópia boa;
  - engrosso do projeto não some;
  - restauração confere o arquivo antes de apagar algo (Android e Windows).
- **Seleção:** divisória ou prateleira de outro módulo escolhe aquele módulo; abrir outro projeto não deixa nada escolhido.
- **Torre forno/micro e caixa da geladeira:** os comandos gerais de porta não trocam a caixa inteira.
- **Tamponamento no 2D:** não move o móvel nem apaga rodapé, travessa e moldura. Erguer e baixar devolve tudo.
- **Ambiente:** profundidade não fica presa no número errado; rebaixo do teto não passa da parede.

Na **candidata Android** (não publicada), validados:
- **P0:** digitar parede ou pé-direito errado não esmaga móveis.
- **Fase 3:**
  - primeiro toque só escolhe;
  - divisória só pelo toque nela;
  - dois toques tolerantes;
  - medida impossível recusada com aviso;
  - seta de trás volta a diminuir;
  - réguas por lado de 1 a 3;
  - menus em ordem fixa;
  - azul mais suave.

### 2. O que foi corrigido definitivamente e tem teste comprovando
Os **60 defeitos "implementado e validado"** do anexo 2. Para cada um, a tabela traz:
- a causa raiz;
- o commit;
- o arquivo ou função;
- o nome do teste;
- se está na versão publicada;
- o risco de regressão.

Os destacados no pedido:

| Defeito | Correção | Teste | Na publicada? |
|---|---|---|---|
| Puxador gola invertido | `fcfcf28` | `testPerfilGolaAberturaPraFrente…` | sim |
| Tamponamento invisível (TAMP-XP, TB-BASE) | `b3c1e74`, `93495d1` | `testTamponamentoDaTorreNoLixo…`, `testTamponamentoDeBaixoSoOndeViraPeca…` | sim |
| Exclusão de fundo (FUNDO-LIXO) | `b3c1e74` | `testToPecaQueO3DOfereceApagar…` | sim |
| Saia e porta (SAIA-ALTURA) | `b3c1e74`, `93495d1` | `testComSaiaNaPedraOArmarioInteiroVaiAteEmbaixoDaSaia` | sim |
| 3D inventando peças / gaveta fantasma (GAV-FANTASMA) | `b3c1e74`, `93495d1` | `testToPecaQueO3DOfereceApagar…` | sim |
| Seleção entre módulos (divisória/prateleira de outro módulo; 🗑 de outro projeto) | `d77ff63`, `7db71af`, `d612d17` | `testSelecaoDivisoriaDeOutroModuloSoEscolheEleENaoMexeEmNinguem`, `testSelecaoPrateleiraDeOutroModuloMexeSoNela`, `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto` | sim |
| Parede/pé-direito esmagando móveis (P0) | `6a319d7`, `b9da40b` | 3 testes `testP0…` | **não**: só na candidata |
| Perda de projetos (arquivo vazio; restauração) | `73ec2f3`, `f96b3e5` | `testArquivoDeProjetosVazio…` + JVM `BackupCaminhoTest`/restauração | sim |

### 3. O que foi implementado mas ainda precisa de testes
**Implementado, mas não integrado nem homologado:**
- **Item 6:** ajustes por 2 toques, mover de longe e colisões. Bateria e CI ok, mas falta iPad, a medição da porta piscando no aparelho e a sua homologação.
- **Plano de Corte:** remoção por toque longo, rodapé fora, brancos juntos.
- **Lateral do meio e travessão.**
- **Canto (folha do lado):** muda 4 expectativas da regra antiga. Integrar exige escolher a regra.
- **Fita no 3D (rebaixo e portas):**
  - as baterias completas foram **interrompidas** para dar prioridade ao Android (rebaixo: 264 de 349; portas: 108 de 349);
  - **precisam rodar de novo**.

**Sem teste nenhum** (fato, pelo levantamento dos testes):
- metragem da fita de borda;
- número de chapas numa máquina lenta;
- medida interna útil;
- troca de vão com o 3D aberto;
- móveis curvos;
- licença de 3 dias e relógio voltado (Android site e Windows);
- atualizadores e instalação por cima, nas 3 plataformas;
- bateria do editor no **WebView do Android**: só rodou no Chromium de PC.

**iPad:** não rodou em **nenhuma** execução do iOS. O fluxo para antes dele.

### 4. O que eu pedi e ainda não foi feito
- **Tamponamento superior com lateral descendo, e medida interna real dos vãos:** só existe o tamponamento superior e a "lateral inteira" do aéreo. Falta a etapa 5 do plano mestre, e a referência precisa ser reenviada.
- **Item 7:**
  - Moldura e Frontal automáticos;
  - "Salvar nos meus modelos" com as opções estruturais;
  - testes de igualdade 3D = lista = corte.
- **Fita padrão 1 mm** e **menu Pintar compacto:** aprovados, na fila.
- **"#1" no nome da peça:** só tirar da tela; aprovado, na fila.
- **Auditoria de exclusão e inconsistências; achar peça no plano de corte:** só houve investigação, sem código.
- **Linha de integração e `CLAUDE.md` §12/§13 na linha principal:** aguarda autorização.
- **Auditoria master final.**
- **Abertos da Fase 1/2:**
  - módulo do catálogo entra por cima dos vizinhos em parede cheia (I7);
  - `sanBase` apaga travessa e moldura;
  - pulo de 875 mm;
  - caminho do tamponamento digitado (até 35 mm);
  - 🗑 do corte do forno e do nicho do micro.
- **Pendentes de decisão sua:**
  - perfil G (folga da dobradiça ou rebaixo de 1,5 mm);
  - FITA-08: porta do aéreo dentro da fita, só o recorte visual na branch;
  - calço da dobradiça na divisória;
  - furação de porta baixa.
- **Móveis curvos e AQRender:** não estão no app; o AQRender existe só como protótipo.
- **Churrasqueira quadrada e textura da pia:** não localizados. Reenviar o pedido.

### 5. O que falta para cada plataforma estar finalizada
**Android**
1. Sua autorização para publicar a candidata. Antes, se quiser, o teste com o APK separado `teste-android-635`, com o procedimento já entregue.
2. **Não verificado:** instalação limpa e atualização num aparelho real. Bateria no WebView Android: nenhuma CI faz.
3. Sem teste: licença (3 dias e relógio), Play/Billing, atualizador, BLE, lembretes da agenda.
4. Integrar as branches seguintes quando homologadas.

**iOS**
1. **Risco comprovado no código, não reproduzido:** `ios/Arquemestre/Data/Backup.swift:51` pula sem aviso todo arquivo com ".." no nome. Um `foto..jpg` vindo de backup do Android some no iPhone. Android e Windows já corrigiram (BKP-PONTOS). Falta a correção e um teste igual ao `BackupCaminhoTest`.
2. **iPad nunca rodou.** Falta rodar a candidata (P0 + Fase 3) no iOS. Até agora só rodaram as branches separadas.
3. `SubscriptionTests.test05` instável (tempo esgotado). Passou 11/11 no passo StoreKit.
4. **Canto (618):** rodou só 181 testes do editor; os outros rodaram cerca de 343. Investigar antes de dar o canto por validado no iOS.
5. **Sincronização:** o iOS só conecta e não tem "Receber". Sem cópias datadas como o Android.

**Windows**
1. **Testes próprios não rodaram na candidata:** os testes JVM, o tour do app instalado e o instalador só rodam no `windows.yml` manual. A CI 46 é só a bateria do editor (356/357; o teste que falhou foi corrigido depois, sem nova execução).
2. **Sem teste no Windows:** `QuotePdfTest`, `StoneFitTest` e 2 testes de `QuoteMathTest`. O código é igual ao do Android.
3. **Ausentes:** trena Bluetooth e compartilhar ao vivo. Avisos da agenda só com o app aberto. Instalador Windows 7/8 sem teste.

## Pendências por gravidade
**P0 (risco de perda de dado ou de fabricação errada)**
- iOS: restauração de backup pula arquivos com ".." sem avisar. Código comprovado, não reproduzido.
- Atualização sobre a versão anterior sem teste em aparelho real, nas 3 plataformas. Para o Android, há procedimento seguro e reversão.
- iPad sem nenhuma execução de teste.

**P1 (importante)**
- **Publicação Android:** pendente da sua autorização. iOS e Windows ainda sem candidata.
- **Branches não integradas (validadas só nelas):** item 6, Plano de Corte, lateral, travessão, canto, fitas. Os testes delas **não existem** na candidata até a junção.
- **Fila não iniciada:** tamponamento superior com lateral descendo e medida interna; item 7; fita de 1 mm; menu Pintar.
- **Abertos da Fase 1/2:** I7 catálogo por cima, `sanBase`, pulo de 875 mm, tamponamento digitado.
- **Salvamento:** `putFile` sem retorno de erro nos 3 nativos (salvar pode falhar sem avisar) e campos fora do `snapState`. Só leitura de código, não reproduzido.
- **Windows:** testes próprios sem execução na candidata.
- **iOS:** test05 de assinatura instável; canto com só 181 testes.

**P2 (melhoria ou visual)**
- 3D aberto não atualiza ao trocar vão por gavetas (s23).
- FITA-08 (visual), calço da dobradiça na divisória, porta piscando (falta medir).
- Número de chapas pode variar com a máquina: o otimizador tem limite de tempo. Peças e corte não mudam.
- Sem teste da metragem da fita. Móveis curvos e AQRender ausentes.

## Testes executados hoje e não executados
| Executado | Resultado |
|---|---|
| Bateria do editor, candidata (Chromium) | 357/357 |
| Rodadas isoladas: ímã, tamponamento, fita da base (publicada × candidata, 3× e várias telas) | ver HOMOLOGACAO_ANDROID |
| Android CI 634 e 635 (JVM, lint, APK de teste) | passou |
| Projetos da 1.0.632 abertos na candidata | 15/15 iguais |
| Sonda de restauração de backup | 6/6 |
| Windows 45 (item 6) / 46 (candidata) | 353/354 / 356/357 (falha conhecida, depois corrigida no teste) |
| iOS 609, 611, 613, 615, 616, 617, 618 (branches) | só o teste antigo do tamponamento (ou test05 no 616); StoreKit 11/11 |

| Não executado | Motivo |
|---|---|
| Aparelho real (Android, iPhone, iPad, PC do usuário) | sem aparelho nem emulador neste ambiente |
| iPad | o fluxo do iOS para antes dele |
| iOS e Windows (`windows.yml`) na candidata | não disparados ainda; prioridade foi o Android |
| Baterias completas das branches de fita | interrompidas para dar prioridade ao Android |
| Bateria no WebView Android | nenhuma CI faz |

## Recomendações para finalizar
1. **Android:** decidir a publicação da candidata, de preferência depois do teste com o APK separado.
2. **iOS:**
   - corrigir o backup com ".." (com teste);
   - rodar a candidata com iPhone **e iPad** (o passo do iPad precisa rodar mesmo com falha no iPhone);
   - estabilizar o test05.
3. **Windows:** rodar o `windows.yml` em modo teste na candidata (JVM, tour e instalador) e acrescentar os testes que faltam (orçamento PDF, pedra).
4. **Integração:** autorizar a linha de integração e levar, uma por vez e com bateria completa, as branches homologadas.
5. **Seguir a fila do plano mestre:** item 7, tamponamentos, cantos (só verificação), exclusão, inventário, fita de 1 mm e menu Pintar, e por último a auditoria master.
6. **Criar testes para as áreas sem cobertura:**
   - metragem de fita;
   - chapas com tempo fixo;
   - troca de vão com o 3D aberto;
   - licença;
   - atualização por cima com dados reais.

---
## Anexos (auditorias detalhadas, com evidência linha a linha)

---

# 1 · Inventário dos pedidos do Adauto (auditoria só de leitura, 17/11/2026)

**Fontes:** 90 mensagens do Adauto nesta sessão (transcrição, sem resultados de ferramenta), os 3 resumos de continuação, `engenharia/` de cada branch (HISTORICO_ERROS, DECISOES_TECNICAS, RELATORIO_2026-11-16, FASE2_SELECAO, FASE3_PRECISAO, PLANO_MESTRE, ESTADO_E_CONTINUACAO, REFERENCIAS, PLANO_EVOLUCAO, AUDITORIA_LINHAS, HOMOLOGACAO_*) e `.github/novidades.txt` da candidata (inclusive as linhas com #).

**Regras usadas:**
- “ok em band2” = passou em `$SP/band2.log` (candidata Android `a13c9e6`, Chromium, 357/357). A candidata contém a versão publicada `7c939bc` + P0 + Fase 3.
- Branch não integrada (plano de corte, lateral, travessão, canto, item 6, fitas) foi conferida no `editor.html` dela por `grep` (funções `pcMenu`, `rodFora`, `pcBranco`, `modUid`, `latMeioOn`, `data-vpav`, `tvsOn`, `a6LatGav`, `mdArmAt`, `a6OpConf`, `medLim`, `__dvGrab`: todas presentes).
- “Validado” só com teste nomeado que passou num log ou numa CI citada no CONTEXTO. Contagem de CI escrita só no ESTADO (sem nome de teste) = sem validação suficiente.
- Entregável que é só documento: validado = arquivo existe no commit citado.
- Nenhum item está em aparelho real (Android, iPhone, iPad, Windows instalado), salvo C07 (Adauto instalou a 1.0.632).
- Pedidos repetidos foram agrupados; a coluna Origem lista as mensagens. Os IDs B09 e D55 não existem: foram fundidos em C02 e C10.

| ID | Origem | Pedido | Onde (branch/commit) | Evidência | Classificação | Pendência |
|---|---|---|---|---|---|---|
| **A · Sessões anteriores (publicado em 7c939bc)** | | | | | | |
| A01 | 16/11 01:26 · HISTORICO GOLA-001 | Perfil G com abertura dos dedos pra frente, parede de 42 atrás | 7c939bc (publicado) | testPerfilGolaAberturaPraFrente… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real não testado |
| A02 | 16/11 · GOLA-002 | Perfil G sólido, sem madeira aparecendo dentro | 7c939bc · 328f602 | testPerfilGolaSolido… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| A03 | 16/11 · RELATORIO 3ª rodada | Perfil G: afastamento da porta e rebaixo na caixa configuráveis | 7c939bc | testPerfilGAfastamentoERebaixo… ok em band2 | PARCIALMENTE IMPLEMENTADO | rebaixo só entra na conta (não sai no corte nem no 3D); decisão sobre folga/rebaixo real |
| A04 | 16/11 · DOB-3D-FURD | Furação da dobradiça padrão 120 no centro do caneco e 3D no mesmo furo | 7c939bc · eb6ed5b | testFuracaoPadrao120…, testFuracaoDaDobradica… ok em band2 | IMPLEMENTADO E VALIDADO | regra para porta baixa (292/282 mm) em aberto |
| A05 | 16/11 · DOB-DIVISORIA | Calço da dobradiça entra na divisória no 3D (16 modelos) | — | nenhuma | NÃO IMPLEMENTADO | decisão do Adauto |
| A06 | 16/11 08:30 vídeo · TAMP-SETA | Tamponamento estica pela seta do 3D (lista, corte e 3D juntos); setas certas na parede lateral | 7c939bc · 7b9bb3a | testTamponamentoDoAereoEstica…, …AfastadoDaParede…, testSetasDo3DNaParedeLateral… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| A07 | 16/11 08:32 · GEL-TRAVA | Travar a geladeira (não sai do lugar, porta abre) | 7c939bc · 0f4644d | testGeladeiraTravada… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| A08 | 16/11 09:15/09:32 · TAMP-XP, TB-MED | 🗑 do tamponamento = desmarcar Usar (medida e peça saem juntas) | 7c939bc | testTamponamentoDaTorreNoLixo…, testMedidaComTamponamentoEhAPonta… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A09 | 16/11 10:56 · TB-BASE | Tamponamento de baixo vira peça no módulo com base suspenso; travado onde não se aplica | 7c939bc | testTamponamentoDeBaixoSoOnde… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A10 | 16/11 09:33 · CLAUDE.md §11 | Protocolo global de correção (registro, família, 14 erros, testes) | CLAUDE.md §11 (todas as branches) | arquivo presente (entregável de documento) | IMPLEMENTADO E VALIDADO | — |
| A11 | 16/11 10:07 · FUNDO-LIXO, GAV-FANTASMA, CANTO-FANTASMA | Peças que não saíam pelo 🗑 (fundo, caixa da gaveta, lado do canto) sem fantasma | 7c939bc | testToPecaQueO3DOfereceApagar… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A12 | 16/11 10:07 · E3-EIXO-ALA | Quadro da peça na parede lateral mostra as medidas da peça | 7c939bc | testQuadroDaPecaNoModuloDaParedeLateral… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A13 | 16/11 10:23 | Menu do vão do balcão sem quadro repetido; Lixeira embutida na lista | 7c939bc | testMenuDoVaoDoBalcaoDaCozinha… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A14 | 16/11 10:34–10:56 · SAIA-ALTURA | Armário inteiro 15 mm abaixo da saia da pedra | 7c939bc | testComSaiaNaPedra…, testArmarioEmbaixoDaPedraComSaia… ok em band2 | IMPLEMENTADO E VALIDADO | profundidade do PEDIDO 59 com saia (decisão) |
| A15 | 16/11 10:56 · XP-PK, XP-PK-SOLO | Peça apagada, ajuste, cor e fita seguem a peça (também no 2D só dele) | 7c939bc | testPecaApagadaEAjusteDo3D…, testEntrarESairDoSoEle… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A16 | 16/11 10:56 · XP-ESTRUTURAL | Lateral, base e divisória saem pela regra do móvel ou ficam bloqueadas com motivo | 7c939bc | testLateralBaseEDivisoria… ok em band2 | IMPLEMENTADO E VALIDADO | corte do forno e nicho do micro saem com o aparelho no lugar (decisão) |
| A17 | 16/11 10:01 · PERFORMANCE.md | Desempenho: caderno, arrasto 2D e animação 3D mais leves | 7c939bc | testDesempenhoArrastarNo2D… ok em band2; CadernoDesempenhoTest (JVM) na CI Android 635 | IMPLEMENTADO E VALIDADO | fase 2 do motor 3D (refazer só o que mudou) aguarda decisão |
| A18 | 16/11 13:34 vídeo · TORRE-GEL-PORTA | Trocar a porta de cima da caixa da geladeira mexe só nela | 7c939bc | testTorreDaGeladeiraTrocarAPorta…, …QueJaVirouPortaInteira… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| A19 | 16/11 13:48 vídeo · TAMP-2D-ALVO | Tamponamento no 2D muda só a altura dele, não move o móvel nem apaga a base | 7c939bc; teste ajustado em 32154d4/790a990/a13c9e6 | testTamponamentoNo2DMudaSoAAltura… ok em band2 (falhava antes só pelo arrasto em pixels) | IMPLEMENTADO E VALIDADO | risco TAMP-2D-ALVO-PARCIAL (pulo de 875 mm ao atravessar a pedra) sem correção registrada |
| A20 | 16/11 14:29 · AMB-RD, AMB-TZ | Profundidade do ambiente não fica presa; rebaixo do teto não passa da parede | 7c939bc | testAmbienteParedeDoLadoProfundidade… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A21 | 16/11 · WEBGL-001 | 3D volta sozinho depois da perda do contexto gráfico | 7c939bc | test3DVoltaSozinhoQuandoOSistemaTira… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| A22 | PEDIDO 45 · 3D-045 | Módulo criado no 2D que não aparece no 3D (iOS) | 7c939bc (mitigação) | testModuloQueNaoApareceNo3DViraAviso…, testTodoModuloCadastradoApareceNo3D… ok em band2 | PARCIALMENTE IMPLEMENTADO | causa raiz desconhecida; falta o diagnóstico do aparelho do Adauto |
| A23 | notas · FORNO-3MM | Forno embutido a 3 mm da travessa | 7c939bc | testFornoEmbutidoNoBalcaoA3mm… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A24 | notas · CANTO-3MM | Folga de 3 mm entre as folhas do canto em L | 7c939bc | testArmarioDeCantoFolgaDe3mm… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A25 | notas p119 · TAMPA-CEGA | Tampa cega continua cega no 2D só dele | 7c939bc | testTampaCegaContinuaCega… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A26 | notas · TECLADO-TOQUE | 1º toque depois do teclado não se perde | 7c939bc | testDepoisDeDigitarOPrimeiroToque…, testDigitarETocarEmOutroCampo… ok em band2 | IMPLEMENTADO E VALIDADO | iOS: janelaNaoDesceNoMeioDoToque intermitente |
| A27 | notas p153 · VALORES | Valores: linha de cada ferragem, chapa pelo uso, mão de obra/custo fixo/despesas | 7c939bc | testTelaValoresTodaFerragem…, testValoresCobraAChapa…, testMaoDeObraCustoFixo… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A28 | Pedidos 61 e 62 · RGQK-LARGA | Faixa da parede minimiza; 2 toques no vão do editor por vãos abrem menu rápido | 7c939bc | testFaixaDaParedeMinimiza…, testEditorPorVaosDoisToquesNoVao… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A29 | notas · TAMP-ENGROSSO | Engrosso do tamponamento entrando no módulo | — | caso do Adauto não reproduzido; catálogo conferido por testTamponamentoSempreForaDoModulo… ok em band2 | NÃO IMPLEMENTADO | falta saber qual módulo e lado |
| A30 | 16/11 · FITA-08 | Porta do aéreo encosta 0,8 mm na fita de borda da caixa | — | nenhuma | NÃO IMPLEMENTADO | decisão do Adauto |
| A31 | 16/11 · auditoria das setas | Setas da régua espaçadora do canto e do rodapé até o piso não mexem | — | nenhuma | NÃO IMPLEMENTADO | pendente no RELATORIO |
| A32 | 16/11 · editor por vãos universal | Editor por vãos em todos os módulos; trava do “só ele no 2D” que converte módulo alto | exp/editor-vaos-universal 4874f84 (não integrado) | nenhuma na linha publicada | PARCIALMENTE IMPLEMENTADO | decisão de integrar |
| A33 | 16/11 · AQRender / motor 3D fase 2 | Luz, metal e vidro realistas (protótipo) | prototipos/aqrender (fora do app) | só protótipo isolado; não medido em aparelho | PARCIALMENTE IMPLEMENTADO | aprovar mudança do formato do vértice |
| A34 | pedido futuro · PLANO_EVOLUCAO L1 | Exportação para CNC (furação, rasgos, nesting) | — | nenhuma | NÃO IMPLEMENTADO | não iniciado |
| A35 | novidades (já saíram) | LED no ripado e na prateleira | 7c939bc | testLedNoRipadoEmPe…, …DoisToquesDePerto…, …AbertoUmModoDeCadaVez… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A36 | novidades | Laterais por fora quadradas, engrosso por fora, canto em L nas duas montagens | 7c939bc | testLateraisPorForaLateralQuadrada…, testCantoEmLLateraisPorDentroEPorFora… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A37 | novidades | Rodapé em seção própria, MDF faceando/embutido, pés de metal | 7c939bc | testRodapeDeMdfFaceando…, testPesDeMetalNoLugarDoRodape…, testPesDeMetalEmTodoTipo… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A38 | novidades | Setinha dos títulos das seções fecha e abre | 7c939bc | testSetinhaDoTituloDaSecao… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A39 | novidades | “Lista de peças (ao vivo)” na aba Fundos mostra a peça no 3D | 7c939bc | teste específico não localizado na bateria | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | criar teste |
| A40 | novidades | Divisória/prateleira nova no meio do vão; divisória arrasta em qualquer projeto | 7c939bc | testDivisoriaEPrateleiraNovas…, testDivisoriaArrastaComODedo… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A41 | novidades | Aéreo: fechamento até o teto; 2 toques no vão de cima (ripado, painel, fechamento) | 7c939bc | testAereoFechamentoAteOTeto…, testDoisToquesNoVaoDeCimaAteOTeto… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A42 | novidades | Pedra vista de cima: 2 toques na cuba/cooktop, bolinhas pequenas; saia sem divisão | 7c939bc | testPedraVistaDeCimaDoisToques…, testSaiaDaPedraSemDivisao… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A43 | novidades | 3D: aviso de módulo que não monta, sem faixa de dicas, parede do lado transparente, paredes criadas selecionam/apagam | 7c939bc | testErroNoMontar…, test3DSemAFaixa…, testParedeDoLadoCom…Transparente…, testParedeCriadaNo3DSeleciona… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A44 | novidades | Canto em L com profundidade de cada lado pela pedra | 7c939bc | testCantoEmLProfundidadeDeCadaLado… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A45 | novidades | iPhone: toque no vão pega de primeira | 7c939bc | testToqueNoVaoComoNoIPhone… ok em band2 (Chromium) | IMPLEMENTADO E VALIDADO | aparelho real |
| A46 | novidades | Troca de parede só no cabeçalho do 2D; quadro “Editando só” minimiza | 7c939bc | testTrocaDeParedeSoPeloCabecalho…, testQuadroEditandoSoMinimiza… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A47 | novidades | Gavetas no vão pergunta quantas (1 a 6) | 7c939bc | testGavetasNoVaoPerguntaQuantas… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A48 | novidades | Porta no forno vira frente com recorte e forno no meio | 7c939bc | testPortaNoFornoViraFrente… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A49 | novidades | Painel do módulo sem Travar e sem Anti-erros | 7c939bc | testPainelDoModuloSemTravar… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A50 | novidades | Régua de 80 do tamponamento escolhe e apaga só ela; tamponamento sempre por fora | 7c939bc | testReguaDoTamponamentoEscolhe…, testTamponamentoSempreFora… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A51 | novidades | Módulo acima de 2700 vira continuação cortando na divisória | 7c939bc | testModuloAcimaDe2700… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A52 | novidades | “Montar do zero” no fim de cada categoria; quarto sem cozinha | 7c939bc | testMontarDoZeroNoFim… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A53 | novidades | Forno/nicho escolhe o aparelho e nunca encolhe; pedestal sem risco solto | 7c939bc | testFornoEscolheOAparelho… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A54 | novidades | Puxador escolhido numa porta vale pro projeto todo | 7c939bc | testPuxadorEscolhidoNumaPorta… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A55 | novidades | Módulos de paredes diferentes encostam no canto sem entrar | 7c939bc | testModulosDeParedesDiferentesEncostam… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A56 | novidades | 3D: 2 toques longe abre o módulo, perto abre a peça | 7c939bc | testDoisToquesNo3DLonge… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A57 | novidades | Abrir portas e gavetas (quadro, abrir tudo, caixote, gaveta interna) | 7c939bc | testAbrirPortasEGavetasFuncionaEmTodoJeito…, …DoQuadroNo3D… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A58 | novidades | Travessa do pedestal 450×100 e fundo da gaveta do caixote no 3D | 7c939bc | testBateriaNovaCatalogoSalvarReabrir… (asserção semLateral 450×100) ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A59 | novidades | Tirar tamponamento esquerdo devolve o módulo | 7c939bc | testTirarTamponamentoEsquerdoDevolve… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A60 | novidades | Tamponamento invertido (catálogo, peça corrida, “só até a cava”) | 7c939bc | testTamponamentoInvertidoNaoMuda…, …PeloToque…, …APecaEAMesma… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A61 | novidades | Pedra em qualquer parede; pedra nova dividida com móvel alto; módulo novo depois do canto | 7c939bc | testPedraEmQualquerParede…, testPedraNovaNaoAtravessaMovelAlto… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A62 | novidades | Tamponamento não entra na pedra; sem espaço não liga | 7c939bc | testTamponamentoNaoEntraNaPedra… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A63 | novidades | Porta de cava para no topo com tamponamento de cima (34 modelos) | 7c939bc | testPortaNaoEntraNoTamponamentoDeCima… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A64 | novidades | Balcão mais alto que a pedra fica na altura dela e avisa | 7c939bc | testModuloDeBaixoSeAdaptaAAlturaDaPedra… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| A65 | novidades | Módulo de baixo erguido e devolvido: rodapé, travessa e moldura voltam | 7c939bc | teste específico não localizado (só a nota do HISTORICO TAMP-2D-ALVO) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | teste dedicado |
| **B · Fase 1 (16/11 noite)** | | | | | | |
| B01 | msg 1–2 (16/11 17:55) | Assumir engenharia: branches, checkpoint 0aa152c, arquitetura, publicação, branch isolada | ARQUITETURA.md, RELATORIO | documentos presentes | IMPLEMENTADO E VALIDADO | — |
| B02 | msg 2–4 | Bateria real, mapa de embrulhos, riscos de perda, plano gradual, sondas e testes por propriedade | AUDITORIA_INTEGRIDADE.md, tools/sondas (45 arquivos) | documentos e sondas s01–s31 registradas (HOMOLOGACAO_9ec0869) | IMPLEMENTADO E VALIDADO | — |
| B03 | msg 3 (P1) | Desenhar não pode modificar o projeto (draw/confineAll/stPush) | 9ec0869 → 7c939bc | testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho ok em band2; sonda s10 | IMPLEMENTADO E VALIDADO | — |
| B04 | msg 3, 11, 12, 14 | Tamponamento determinístico; ação explícita × automática; esquerdo/direito simétricos; sem espaço cancela | 9ec0869 → 7c939bc | testTamponamentoMovelExistenteNaoEEmpurrado…, …EsquerdoLigado…, …DireitoLigado…, …DesligarERelegar…, …SemEspacoAvisa…, …LigadoSalvarReabrir… ok em band2; sonda s31 10/10 | IMPLEMENTADO E VALIDADO | — |
| B05 | msg 3 (x=5→35) · s13 | Posição digitada deixa vão de 35 mm junto à parede | — | sonda s13 ainda acusa (FASE2_SELECAO) | NÃO IMPLEMENTADO | autorizar correção |
| B06 | msg 3 | Reconhecer histTick (desfazer) e ampliar testes de salvar | 7c939bc | testDesfazerERefazerDevolvemOProjetoIgualPassoAPasso ok em band2; sonda s28 | IMPLEMENTADO E VALIDADO | — |
| B07 | msg 2–3 (sessão anterior) | Churrasqueira quadrada conforme referência | — | nenhum registro em commits, engenharia/, novidades ou testes | NÃO LOCALIZADO NO HISTÓRICO | reenviar referência |
| B08 | msg 2–3 (sessão anterior) | Correções de textura da pia e da área molhada | — | nenhum registro (AUDITORIA_INTEGRIDADE) | NÃO LOCALIZADO NO HISTÓRICO | reenviar o pedido exato |
| B10 | msg 4.6 | Auditoria de desempenho (reconstrução 3D, vazamento, eventos) | PERFORMANCE.md; sonda s24 | sonda s24 (40 módulos, sem vazamento) | IMPLEMENTADO E VALIDADO | — |
| B11 | msg 4.7 | Plano de separação da arquitetura (sem implementar) | ARQUITETURA.md, PLANO_EVOLUCAO.md | documentos presentes | IMPLEMENTADO E VALIDADO | escolha de prioridades pelo Adauto |
| B12 | msg 5 · P0-01 | projects.json vazio/quebrado não apaga a cópia boa | 73ec2f3 → 7c939bc | testArquivoDeProjetosVazioOuQuebrado… ok em band2; sonda s08a | IMPLEMENTADO E VALIDADO | — |
| B13 | msg 5 · P0-02 | Restauração de backup segura (Android e Windows; iOS validado) | f96b3e5 → 7c939bc | JVM backup 13/13 e 16/16 (FASE2); CI Android 635 com BackupCaminhoTest; sonda de restauração 6/6 | IMPLEMENTADO E VALIDADO | aparelho real |
| B14 | msg 5 · P0-03 | Engrosso preservado; abrir sem mexer não regrava | 37c9915, 0e353e3, 74fa8b1 → 7c939bc | testEngrossoDoProjetoNaoSome…, testAbrirProjetoSemMexerNaoRegrava… ok em band2; sonda s08b | IMPLEMENTADO E VALIDADO | — |
| B15 | msg 5–8 · GEO-AVISA | Ambiente não modifica móveis; aviso com módulo/medida/disponível/diferença; móvel novo × existente (roomClamp) | 04ab7cf, 80aa4a1, 9ec0869 → 7c939bc | testAmbienteNaoModificaOsMoveisSoAvisa ok em band2; sondas s11, s27, s29 | PARCIALMENTE IMPLEMENTADO | não cobertos: sanBase, wallFollow de painéis até o teto, confine no arrasto (HISTORICO GEO-AVISA) |
| B16 | msg 7 | Gravação desnecessária da biblioteca inteira depois da 1ª alteração | 74fa8b1 (gravação leve na abertura) — hipótese | testAbrirProjetoSemMexerNaoRegrava… e testSalvarLeve… ok em band2; registro específico desta correção não localizado | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | confirmar o que foi corrigido |
| B17 | msg 10 | testParedeLateralNaoCresceSozinha: preservar x=2170 sem aprovar no automático | 7c939bc | testParedeLateralNaoCresceSozinha ok em band2; sonda s30 | IMPLEMENTADO E VALIDADO | — |
| B18 | msg 14 | Regra dos 9 mm nos encontros só ao posicionar, nunca ao abrir/desenhar | 9ec0869 | sonda s31 (“regra do canto só ao posicionar”) | IMPLEMENTADO E VALIDADO | — |
| B19 | msg 6, 8, 9 · 213430c | Eletrodomésticos reais com dimensões bloqueadas e requisitos de instalação | só especificação registrada (213430c) | nenhuma | NÃO IMPLEMENTADO | não iniciado |
| B20 | msg 8, 9, 18 | Padronização estrutural universal (portas, gavetas, prateleiras no vão certo) | — | nenhuma | NÃO IMPLEMENTADO | não iniciado |
| B21 | msg 9, 17 · s23 | Sincronização imediata 2D/3D (vão → gavetas com o 3D aberto) | — | sonda s23 ainda acusa | NÃO IMPLEMENTADO | autorizar |
| B22 | msg 17 · s29 | Móvel novo do catálogo não é redimensionado para caber (avisa a diferença) | regra registrada em DECISOES | sonda s29: ainda ajusta a largura | NÃO IMPLEMENTADO | implementar na etapa de posicionamento |
| B23 | msg 17 · s20 I7 | Módulo do catálogo entra por cima dos vizinhos em parede cheia | — | sonda s20 ainda acusa | NÃO IMPLEMENTADO | — |
| B24 | msg 17 · s27 | Folga do rack que não volta; módulo da parede lateral que anda e não volta | — | sonda s27 ainda acusa | NÃO IMPLEMENTADO | — |
| B25 | msg 17 · s05 | Travessa e moldura perdidas ao alternar sup/rack (sanBase) | — | nenhuma | NÃO IMPLEMENTADO | — |
| B26 | msg 17 | Validação de peças flutuantes e interseções indevidas | — | testes antigos testSolidoNadaEntraEmNada…, testBateriaNova…PecaNaoEntraEmPeca… ok em band2; validação nova pedida não feita | PARCIALMENTE IMPLEMENTADO | — |
| B27 | msg 33 | Aviso de pedra/lixeira/objetos fora da parede (3 plataformas) | b1c6dc8 (só registro) | nenhuma | NÃO IMPLEMENTADO | melhoria pendente |
| **C · Fase 2, gv e publicação 7c939bc** | | | | | | |
| C01 | msg 17–18 · SEL-DIV | Divisória/prateleira de outro módulo mexe só nela | d77ff63 → 7c939bc | testSelecaoDivisoriaDeOutroModulo…, testSelecaoPrateleiraDeOutroModulo… ok em band2 | IMPLEMENTADO E VALIDADO | aparelho real |
| C02 | msg 4.4, 17, 18 · SEL-PROJ/SEL-ESTADO | Abrir outro projeto zera seleção, alvo do 🗑 e “Só a pedra no 3D” | 7db71af, d612d17 → 7c939bc | testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto, testSelecaoEscolhasDeTelaZeram… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| C03 | msg 18 · SEL-VAO | Vão escolhido sempre existe no módulo escolhido | 7a95037 → 7c939bc | testSelecaoVaoEscolhidoExiste… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| C04 | msg 18 · SEL-TORRE (opção A) | Porta de cima da torre de forno/micro muda só ela | 7c939bc | testSelecaoPortaDeCimaDaTorre…, testSelecaoTorrePortaDeCimaPeloVao… ok em band2 | IMPLEMENTADO E VALIDADO | balcão de forno nos botões gerais (risco registrado) |
| C05 | msg 19–22 · GV-P1 | gv não cria vão fantasma em leitura | 7c939bc | 7 testes testGv… ok em band2; gv_p1.log 7/7 | IMPLEMENTADO E VALIDADO | — |
| C06 | msg 22 · GV-C | Limpar divisões volta o vão escolhido pro primeiro | 7c939bc | testGvLimparDivisoesVoltaOVao… ok em band2; gvc_c.log 8/8 | IMPLEMENTADO E VALIDADO | — |
| C07 | msg 23, 29 | Publicar Android e Windows (5a468bf → 7c939bc) | release apk-632 e win-143 (7c939bc) | releases no GitHub; Adauto confirmou 1.0.632 instalada (msg 31) | IMPLEMENTADO E VALIDADO | — |
| C08 | msg 25 · BKP-PONTOS | Backup com “..” no nome: aceita foto..jpg, bloqueia ../fora.txt | 7c939bc | BackupCaminhoTest (CI Android 635 passou); Windows JVM 134/134 (FASE2) | IMPLEMENTADO E VALIDADO | aparelho real |
| C09 | msg 23, 25 | Enviar iOS 3.0.13 ao TestFlight | — | não enviado; suspenso pelo Adauto (msg 30) | NÃO IMPLEMENTADO | autorização futura |
| C10 | msg 30, 31, 33, 36, 84 etapa 2, 89.3 | Homologação completa do iOS (iPhone e iPad) e finalizar iOS depois do Android | CI 607, 609, 611, 613, 615, 616 | iPhone: só a falha antiga do tamponamento; 616 falhou em SubscriptionTests.test05; iPad não rodou | PARCIALMENTE IMPLEMENTADO | iPad; SubscriptionTests test05; StoreKit ok 11/11 |
| C11 | msg 33 · TESTE-CUBA-PAREDE | Teste da cuba ajustado à regra GEO-AVISA (sem mudar o app) | 18027d8 | testCubaArrastaNoTouch…ParedeEncolhida ok em band2 | IMPLEMENTADO E VALIDADO | — |
| **D · Pedidos de 17/11** | | | | | | |
| D01 | msg 32, 34 | Régua do batente cava com altura/largura manual (só esta / módulo / projeto) | proposta c367d4c | nenhuma | NÃO IMPLEMENTADO | cancelado: “preservar a lógica atual” (msg 51) |
| D02 | msg 35, 36, 39 | Altura do batente cava calcula as frentes e posiciona batentes | claude/arquemestre-batente-cava 507db9b (não usar) | bcava_novo.log 4/5 (testBatenteCavaEmTodosOsModelos… falha) | NÃO IMPLEMENTADO | cancelado pela decisão de 17/11 12:26; branch congelada |
| D03 | msg 36, 39 · F3-TOQUE | 1º toque em módulo não escolhido só escolhe, nunca move | a9a195b → candidata a13c9e6 | testF3PrimeiroToque… ok em band2; iOS 609 só falha antiga | IMPLEMENTADO E VALIDADO | publicar a candidata |
| D04 | msg 36, 39 · F3-SEL | Divisória só na área dela; 2 toques não fecham o vão; tremida não move | 469c0d0, 759ccf0 → a13c9e6 | testF3SelecaoDivisoriaDoisToquesETremida… ok em band2 | IMPLEMENTADO E VALIDADO | houve regressão achada e corrigida antes (759ccf0) |
| D05 | msg 36, 39 · F3-MED | Medida inválida recusada com aviso, sem arredondar | 849a46b → a13c9e6 | testF3MedidaInvalidaRecusada… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| D06 | msg 36, 39 · F3-MENU | Menus na mesma ordem em todos os módulos | 4543c0f → a13c9e6 | testF3MenusNaMesmaOrdem… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| D07 | msg 36, 39 · F3-AZUL | Azul de seleção mais suave | c1d584f → a13c9e6 | sem teste próprio (só visual) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | conferência visual pelo Adauto |
| D08 | msg 36 · F3-SETA, F3-REGN | Réguas/setas que não aumentavam ou diminuíam certo | 8fa40d5, d59831f → a13c9e6 | testF3SetaDeTras…, testF3CamadasDoEngrossoCava… ok em band2 | IMPLEMENTADO E VALIDADO | — |
| D09 | msg 37, 39, 41 | Rodapé fora do plano de corte (opção A, trechos do rodapé corrido) | claude/arquemestre-plano-corte 3c1a677/43114be | testPlanoDeCorteRodapeFora… (log local não encontrado); Windows 349/351 antes do 43114be (ESTADO); iOS não concluído | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | bateria e iOS no commit final; integrar |
| D10 | msg 38 | Travamento ao “Achar peça” no plano de corte | só investigação em $SP/achar (sem commit) | nenhuma | NÃO IMPLEMENTADO | reproduzir, causa e teste |
| D11 | msg 39 · P0-PAREDE | Digitar parede/pé-direito não esmaga nem move móveis; aviso verdadeiro | 6a319d7, b9da40b → 790a990 → a13c9e6 | testP0ParedeEPeDireitoDigitados…, testP0ParedeMenorQueOsMoveis…, testP0ParedeDesfazRefazReabre… ok em band2; iOS 616 iPhone | IMPLEMENTADO E VALIDADO | iPad; autorização de publicação |
| D12 | msg 40, 41 | Tirar peça do plano de corte por toque longo 1,5 s / clique direito, por identidade | plano-corte 3c1a677 (pcMenu, modUid, pcIds) | testPlanoDeCorteToqueLongo… (log local não encontrado); iOS não concluído | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | bateria e iOS no commit final; integrar |
| D13 | msg 42, 43 | Peças brancas juntas no plano de corte | plano-corte 3c1a677 (pcBranco) | testPlanoDeCortePecaBranca… (log local não encontrado) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | idem |
| D14 | msg 45–50, 51.4 | Lateral do meio inteira junto das gavetas no inferior da cozinha (com rebaixo); aviso para módulo antigo | claude/arquemestre-lateral-inteira 3991175 | testLateralDoMeioJuntoDasGavetas…; Windows 348/349 (ESTADO); iOS 613 só falha antiga (CONTEXTO) | PARCIALMENTE IMPLEMENTADO | base e travessa em 2 peças não feitas (aguarda confirmação) |
| D15 | msg 51.2 | Só avisar profundidades diferentes entre vizinhos | lateral-inteira 3991175 (data-vpav) | coberto no testLateralDoMeio… (iOS 613) | IMPLEMENTADO E VALIDADO | integrar |
| D16 | msg 52, 53.1, 65.1 | Altura das laterais da gaveta por 2 toques, 1 mm, divisão inteira acompanha | claude/arquemestre-ajustes-3d a9b1da7 | testA6AlturaDasLaterais… 13/13 em 1024×1366 e 1920×1080 (telas.log); Windows 45; iOS 611 | IMPLEMENTADO E VALIDADO | item 6 não homologado; integrar |
| D17 | msg 53.2, 65.1 | Frente e contra-frente: ajuste de 1 mm só na peça, com aviso de encaixe | ajustes-3d c2951f0 + 3bab8a8 | testA6AjusteDe1mmSoNaPeca… (telas.log); cmp6 107/109 (falhas antigas) | IMPLEMENTADO E VALIDADO | idem |
| D18 | msg 53.3, 65.4 | Porta/janela da parede: 1 toque seleciona, 2 toques abrem a configuração | 890e06e revertido em 0fad7ef | revertido por ordem do Adauto (msg 66–67) | NÃO IMPLEMENTADO | substituído pela ordem de preservar o 1 toque |
| D19 | msg 66–68 | 1 toque igual ao original + teste de regressão | bb7bd67; mira do teste corrigida em 9d8727d | testUmToqueNaPortaDaParede… ok em 1024/1920 e falha em 390/844 (mira) no telas.log; sem rodada depois do 9d8727d | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | rodar depois do 9d8727d |
| D20 | msg 54, 56, 60–62, 79.7, 80.5 | Travessão interno/externo, com Frontal (recuo), lateral do meio até o topo, painel Moldura → Travessão → Frontal | claude/arquemestre-travessao a862927 | testTravessaoInternoExternoComESemFrontal… (relacionados 67/68); iOS 615 só falha antiga | PARCIALMENTE IMPLEMENTADO | família reduzida: sem racks, homes, TV, canto e laterais por fora |
| D21 | msg 54, 64, 79.4 | Item 7: regras automáticas de Moldura e Frontal | — | nenhuma | NÃO IMPLEMENTADO | apresentar dúvidas antes |
| D22 | msg 54.8, 56.3 | Salvar nos meus modelos com a estrutura paramétrica (recalcula no novo tamanho) | — | não verificado com m.tvs/m.latMeio | NÃO IMPLEMENTADO | idem |
| D23 | msg 54.3, 56.4 | Identidade estável única de módulo e peça (corte, editor, 3D) | modUid/pcIds só na branch plano-corte | só no plano de corte | PARCIALMENTE IMPLEMENTADO | estender ao editor e ao 3D |
| D24 | msg 56 | Testes numéricos 3D = lista = corte em todas as montagens | travessao a862927 | só o travessão tem teste numérico | PARCIALMENTE IMPLEMENTADO | moldura, frontal, modelos |
| D25 | msg 57.1 | Tamponamento editável por 2 toques no 3D, campo numérico e ±1 mm | — | nenhuma (só a seta antiga, A06) | NÃO IMPLEMENTADO | fila; aguarda referência |
| D26 | msg 57.2–3 | Tamponamento superior com lateral descendo à esquerda/direita | — | grep no editor: inexistente | NÃO IMPLEMENTADO | fila; vídeo não chegou |
| D27 | msg 57.4 | Mostrar medida livre real do vão (largura e altura) | — | grep no editor: inexistente | NÃO IMPLEMENTADO | fila |
| D28 | msg 58, 65.2, 70.1 | 2 toques de longe: quadro + destaque do módulo; 2 toques no destino movem | ajustes-3d 9d3bcce | testA6DoisToquesDeLonge… 13/13 em 1024 e 1920; Windows 45; iOS 611 | IMPLEMENTADO E VALIDADO | item 6 não homologado; integrar |
| D29 | msg 65.3, 70.3, 73.2, 74 | Mover entre paredes (módulo, geladeira, eletro, porta/janela) bloqueando só colisão real; nada preso | ajustes-3d 2ac1ddc, 6aacd8a | testA6MoverPor2ToquesConfereColisao…, testA6DepoisDeBloquear… (telas.log 8812) | IMPLEMENTADO E VALIDADO | idem |
| D30 | msg 65.5, 70.5 | Precisão com zoom; não escolher peça escondida | — | não reproduzido | NÃO IMPLEMENTADO | caso real do Adauto |
| D31 | msg 70.2, 73.1 | Porta piscando nos 2 toques sem atrasar o 1 toque | opção A testada e não mantida (052ef9e) | sem diferença medida no Chromium | NÃO IMPLEMENTADO | medir no aparelho |
| D32 | msg 71.4 | Gestos em telas, orientações e zoom diferentes | ajustes-3d 2ca030a, 7c12109 | telas.log: 390×844 12/13, 844×390 11/13, 1024×1366 13/13, 1920×1080 13/13 | IMPLEMENTADO E VALIDADO | falhas restantes também na publicada |
| D33 | msg 66, 70 | Preservar 3, 4 e 5 toques | preservado | testA6DoisToquesDeLonge… (3 toques não preparam mover); testPedraSolida…5ToquesEditaSoOModulo ok em band2 | IMPLEMENTADO E VALIDADO | — |
| D34 | msg 72 | Desempenho e resposta imediata medidos e comparados | HISTORICO item 6; PERFORMANCE.md | medição item 6 (40 módulos, sem piora); FPS e aparelho real não medidos | PARCIALMENTE IMPLEMENTADO | medir no aparelho |
| D35 | msg 68, 72, 79.9 | CLAUDE.md §12 e §13 nas instruções permanentes | claude/arquemestre-protocolo-cirurgico f373a03, ce89354 | só nessa branch; CLAUDE.md da P0 vai até §11 | PARCIALMENTE IMPLEMENTADO | levar à linha principal com autorização |
| D36 | msg 76 | Registrar o plano mestre no repositório | protocolo-cirurgico ed63f59 | engenharia/PLANO_MESTRE.md | IMPLEMENTADO E VALIDADO | — |
| D37 | msg 75, 76 | Continuidade: estado real, commits, testes e pendências no repositório | protocolo-cirurgico cb3a2de | ESTADO_E_CONTINUACAO.md existe, mas está defasado (P0 4aca2bb, item 6 6aacd8a, sem candidata Android) | PARCIALMENTE IMPLEMENTADO | atualizar |
| D38 | msg 59 | Canto em L: folha do lado cobre 5 mm atrás e folga de 4 mm | claude/arquemestre-canto-folha-lado e1d79b3 | 4 expectativas atualizadas; Windows 347/348 (ESTADO); iOS do canto não concluído | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | iOS; integrar |
| D39 | msg 58, 79.6, 80.4 | Biblioteca de cantos: 8 modelos (L e cego, baixo e aéreo, esq. e dir.) | já existiam em 8c0ce76 (AUDITORIA_LINHAS §6) | verificação de leitura: os 8 entram com peças; decisão: preservar | IMPLEMENTADO E VALIDADO | ordem dos cartões não conferida (imagem não chegou) |
| D40 | msg 72, 76 etapa 7 | Auditoria geral de exclusão e consistência | — | nenhuma | NÃO IMPLEMENTADO | fila |
| D41 | msg 64, 79.8 · FT-REBAIXO | Fita de 0,8 mm do rebaixo desenhada dentro da travessa frontal no 3D (só visual) | claude/arquemestre-fita-rebaixo-3d af0c55e | testFitaDoRebaixoNaoFicaDentroDaTravessa… ok (bft.log); bateria depois do ajuste do teste incompleta (bft2 264/349) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | bateria completa |
| D42 | msg 80.3 · FT-PORTA | Fita de 0,8 mm dentro de porta/frente fechada no 3D (só visual) | claude/arquemestre-fita-portas-3d 1454596/9a865e9 | testFitaNaoFicaDentroDaPortaOuFrenteFechada… ok (bfp.log); bateria final parcial (bfp2 108/349) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | bateria completa |
| D43 | msg 81–84 | Fita de borda 1 mm padrão; quadro distingue corte × acabada | só decisão (DECISOES, 0549561) | nenhuma | NÃO IMPLEMENTADO | definir 560 ou 561 no quadro |
| D44 | msg 81–84 | Menu Pintar compacto (cabeçalho 2 linhas, ordem dinâmica, 2 colunas no tablet) | só decisão (PLANO_MESTRE 8b) | nenhuma | NÃO IMPLEMENTADO | fila, sem mexer no minimizar compartilhado |
| D45 | msg 83.5 | Tirar o “#1” só da apresentação do nome da peça | — | nenhuma | NÃO IMPLEMENTADO | fila |
| D46 | msg 79.1, 80.1 | Corrigir só o teste testTamponamentoNo2D… (mm pela escala, folga do app) | 32154d4, 790a990, a13c9e6 | testTamponamentoNo2D… ok em band2; 6 telas (HOMOLOGACAO_ANDROID) | IMPLEMENTADO E VALIDADO | — |
| D47 | msg 82, 83.6 | Corrigir só o teste testToPecaQueO3DOfereceApagar… (identidade, totais da geometria) | fita-rebaixo 288e0e2, 49996ac | sem rodada completa depois da correção | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | rodar bateria |
| D48 | msg 85 | Corrigir só o teste testFitaDaBaseEmbaixoDaPorta… (mira pela geometria) | 6058b74 (candidata), 9a865e9 (fita-portas) | testFitaDaBase… ok em band2; 3/3 nas duas versões e com zoom | IMPLEMENTADO E VALIDADO | — |
| D49 | msg 80.6 | Auditoria só de leitura das linhas (publicado, main, branches) e estratégia | protocolo-cirurgico 28c356d | engenharia/AUDITORIA_LINHAS.md | IMPLEMENTADO E VALIDADO | recomendação aguarda autorização |
| D50 | msg 79.10, 84 | Rodar iOS das branches plano de corte, lateral, canto e travessão | CI 612–615 | lateral (613) e travessão (615): só falha antiga; plano de corte e canto: rodando; iPad em nenhuma | PARCIALMENTE IMPLEMENTADO | concluir 612/614 e iPad |
| D51 | msg 84, 86–89 | Candidata Android (P0 + Fase 3), escopo congelado, homologada | claude/arquemestre-candidata-android a13c9e6 (+6b0e9cd doc) | band2.log 357/357; CI Android 635; projetos 15/15; backup 6/6; Windows 46 356/357 | IMPLEMENTADO E VALIDADO | aparelho real não testado |
| D52 | msg 86–89 | Publicar a candidata Android | — | não publicado (ponteiro segue apk-632) | NÃO IMPLEMENTADO | “sim” do Adauto para a13c9e6 |
| D53 | msg 87–89 | APK separado para teste no aparelho, sem mexer no app instalado | release teste-android-635 (a13c9e6) | release existe no GitHub | IMPLEMENTADO E VALIDADO | Adauto testar no Tab S9 FE |
| D54 | msg 87, 88 | Investigar as 3 falhas (ímã/linha verde, tamponamento, fita da base) 3× em cada versão | HOMOLOGACAO_ANDROID_a13c9e6.md | iso3.log, tfb.log; 3/3 nas duas versões | IMPLEMENTADO E VALIDADO | — |
| D56 | msg 84 etapa 3 | Finalizar Windows depois do iOS | — | Windows 46 em fc98cc5 356/357; pacote da candidata não gerado | PARCIALMENTE IMPLEMENTADO | gerar e validar pacote |
| D57 | msg 84 etapa 5 | Linha de integração segura das branches | proposta claude/arquemestre-integracao (não criada) | nenhuma | NÃO IMPLEMENTADO | autorização |
| D58 | msg 76 etapa 9 | Auditoria master final de todas as ferramentas | — | nenhuma | NÃO IMPLEMENTADO | última etapa |
| D59 | msg 76 etapa 8, msg 90 | Inventário de pendências e AUDITORIA_GERAL_ARQUEMESTRE_2026-11-17.md | esta auditoria (scratchpad) | em andamento | PARCIALMENTE IMPLEMENTADO | consolidar o relatório |

## Decisões pendentes do Adauto
1. Publicar a candidata Android `a13c9e6` (depois do teste com o APK `teste-android-635` no aparelho). Depois: iOS e Windows.
2. Linha de integração (`claude/arquemestre-integracao` a partir de `7c939bc`) e levar o CLAUDE.md §12/§13 para a linha principal.
3. Lateral do meio: base e travessa em 2 peças, uma de cada lado (D14).
4. Travessão: estender a racks, homes, módulos de TV, canto e laterais por fora? (D20)
5. Item 7: dúvidas de Moldura, Frontal e “Salvar nos meus modelos” (a apresentar antes de implementar).
6. Fita de 1 mm: o quadro da peça mostra 560 (corte) ou 561 (acabada)? (D43)
7. Tamponamentos e laterais descendentes: reenviar a referência (vídeo não chegou).
8. Porta piscando nos 2 toques: medir/filmar no aparelho (D31). Precisão com zoom: mandar um caso real (D30).
9. Churrasqueira quadrada e textura da pia/área molhada: reenviar pedido e referência (B07, B08).
10. Autorizar as pendências antigas da Fase 1/2: s13, s20 I7, s23, s27, s29, sanBase (B05, B21–B25).
11. Perfil G: folga da dobradiça ou rebaixo na caixa (1,5 mm) (A03).
12. FITA-08 (porta do aéreo 0,8 mm na fita), calço da dobradiça na divisória, regra da furação para porta baixa (A30, A05, A04).
13. Editor por vãos universal / trava do “só ele no 2D” (A32); fase 2 do motor 3D e medidor de quadros (A17, A33).
14. “Corte do forno” e “Nicho do micro” saem pelo 🗑 com o aparelho no lugar (A16); profundidade do PEDIDO 59 com saia (A14).

## Contagem por classificação (calculada sobre a tabela acima)
Total de pedidos: **160**

| Classificação | Quantidade |
|---|---|
| IMPLEMENTADO E VALIDADO | 96 |
| IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | 12 |
| PARCIALMENTE IMPLEMENTADO | 17 |
| NÃO IMPLEMENTADO | 33 |
| CORRIGIDO COM REGRESSÃO | 0 |
| NÃO LOCALIZADO NO HISTÓRICO | 2 |

**Observação:** nenhum item ficou como CORRIGIDO COM REGRESSÃO no estado atual. Houve regressões no caminho, todas corrigidas antes do commit final e com teste: F3-SEL (759ccf0), A6-PECA/poAlign (3bab8a8), A6-OP (revertido em 0fad7ef), BKP-PONTOS (nascida da P0-02, corrigida em 7c939bc).

---

# Auditoria 2 — correções de defeitos (só leitura, 17/11/2026)

## Fontes e como foi conferido
- `engenharia/HISTORICO_ERROS.md` de 11 checkouts: wt-and (6b0e9cd), P0 /home/user/Arqueiro-measure (790a990), wt-a6 (29ffe40), wt-pc (43114be), wt-li (3991175), wt-tv (a862927), wt-cn (e1d79b3), wt-ft (49996ac), wt-fp (9a865e9), wt-f3 (e02faaf), wt-cl (0549561). União das entradas: 77 seções (`_merged.md` nesta pasta).
- Também: `RELATORIO_2026-11-16.md`, `AUDITORIA_INTEGRIDADE.md`, `HOMOLOGACAO_9ec0869.md`, `HOMOLOGACAO_ANDROID_a13c9e6.md`, `especificacoes/puxador-gola.md`, `git log --all`, `git log -S`.
- Cada commit citado foi conferido com `git cat-file -t` (todos deram `commit`) e `git merge-base --is-ancestor <c> 7c939bc`.
- Teste: nome procurado como `func <nome>` em `$SP/wt-and/ios/ArquemestreTests/EditorWebKitTests.swift` (357 funções) e como linha `ok`/`FALHA` em `$SP/band2.log` (357/357 ok).
- Testes de branch não integrada: procurados no arquivo de testes da própria branch e nos relatórios de rodada guardados no $SP (portas: 8794 = versão publicada; 8807 = plano de corte; 8808 = lateral; 8809 = canto; 8811 = travessão; 8812 = item 6).

Legenda das colunas:
- **Pub?** = o commit da correção é ancestral de `7c939bc` (versão publicada). "não" = só em branch não publicada.
- **Cand./band2** = o teste existe na candidata e o resultado em `band2.log`. "não existe" = a função não está no arquivo de testes da candidata.
- IV = IMPLEMENTADO E VALIDADO · ISV = IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE · PI = PARCIALMENTE IMPLEMENTADO · NI = NÃO IMPLEMENTADO · CR = CORRIGIDO COM REGRESSÃO · NL = NÃO LOCALIZADO NO HISTÓRICO.
- "Validado" aqui é sempre no Chromium/CI. **Nenhum item foi testado em aparelho real** (FATO: o próprio histórico diz "não testado em aparelho" em todos os itens que citam isso; o CONTEXTO diz que iPad não rodou em nenhuma branch).

## Tabela (uma linha por defeito)

| # | ID | Defeito original | Causa raiz (registrada) | Commit(s) | Arquivo / função | Teste que comprova · candidata/band2 | Pub? | Risco de regressão | Classe |
|---|---|---|---|---|---|---|---|---|---|
| 1 | GOLA-001 **puxador gola invertido (perfil G)** | Abertura dos dedos para dentro, parede de 42 na frente, placa escura | 41fab29 (12/11) leu o desenho com a frente trocada; copiado em b3760c8/205603a | fcfcf28 | editor.html `pxParts` (`t==='g'`), `G_` | `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical` · existe · ok | sim | Baixo: o teste falha se inverter. "Sobra malfeita" sem confirmação do Adauto (puxador-gola.md pend. 7) | IV |
| 2 | GOLA-002 | Madeira aparecendo dentro do perfil G (parecia transparente) | Parede de trás no mesmo plano da travessa (disputa de pixel) + granulado de MDF no perfil claro | 328f602 | editor.html passada `GB.g`, `polygonOffset` | `testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado` · existe · ok | sim | Interferência física de 1,5 mm continua (pend. 1). Coberto | IV |
| 3 | TAMP-SETA | Tamponamento não aumentava pela seta do 3D | Toque na régua (PEDIDO 37) escolhia pedaço que não é peça do `partsOf`; ajuste ia para `m.po['…(régua)#1']` | 7b9bb3a, ddb41c8 | editor.html `e3K`, `e3Handles`, `e3Ax`, `e3LAx` | `testTamponamentoDoAereoEsticaPelaSetaDo3DMesmoTocandoNaReguaListaCorteE3DReabre`, `testTamponamentoDoAereoAfastadoDaParedeEsticaAteOFundoPelaSeta`, `testSetasDo3DNaParedeLateralMexemNaMedidaCertaEModuloTravadoNaoEstica` · existem · ok | sim | Coberto por 3 testes | IV |
| 4 | GEL-TRAVA (**geladeira**, pedido) | Geladeira sem trava; "travada" saía do lugar | Campo `lock` sem botão e sem conferência no 2D | 0f4644d | editor.html quadro da geladeira 2D/3D | `testGeladeiraTravadaNaoSaiDoLugarNemMudaDeMedidaMasAbreNormal` · existe · ok | sim | Coberto | IV |
| 5 | DOB-3D-FURD | Dobradiça no 3D a 100 fixo, plano de corte a 120 | `hinges3` com `off=100` fixo, sem ler `furD`/`p.fur` | eb6ed5b | editor.html `hinges3` | `testFuracaoPadrao120NoCentroDoCanecoAjustavelEInstalacaoAntigaFicaCom100` · existe · ok | sim | Coberto | IV |
| 6 | DOB-DIVISORIA | Calço da dobradiça entra na divisória no 3D (16 modelos) | Não investigada | — | — | nenhum | — | Só 3D. Sem teste | NI |
| 7 | TESTE-FAIXA-WEBKIT | 2 testes da faixa da parede falhavam no iPhone | Teste anterior ao PEDIDO 61; espaço a mais no `innerText` do Safari | 1730073, 328f602 | só testes | `testTrocaDeParedeSoPeloCabecalhoDo2DSempreVisivelEPainelGuardado`, `testFaixaDaParedeMinimizaEAbreDeNovo` · existem · ok | sim | App não mudou | IV |
| 8 | IOS-ABRE-20S | `testEditorAbreComoNoAppSemTelaBranca` passa de 20 s no CI | Início a frio do simulador (hipótese) | — | — | `testEditorAbreComoNoAppSemTelaBranca` (em `EditorAppPathTests.swift`, fora da bateria do editor) · não está no band2 | — | Pendente, só observado | NI |
| 9 | 3D-045 (**3D sem o módulo**) | Módulo criado no 2D não aparece no 3D (iOS) | **Não comprovada.** Hipótese: `ST3ONLY` ficava ligado (P1-D, mecanismo comprovado na s14) | e3d68b8 (mitigação); 7db71af (zera `ST3ONLY` ao abrir outro projeto) | editor.html `ERR3`, diagnóstico 3D; `loadState` (`limpa`, linha 12365 na candidata) | `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa`, `testTodoModuloCadastradoApareceNo3DEmQualquerCaminho` · existem · ok | sim | Não reproduzido. `ST3ONLY=0` só no `loadState` de outro projeto; fechar o 3D não desliga (FATO: `grep ST3ONLY=0` dá só 2 lugares) | PI |
| 10 | WEBGL-001 | 3D apagado depois da perda do contexto gráfico | Sem `webglcontextlost/restored` | 457d30d (+c6d4808 teste) | editor.html após `glInit()` | `test3DVoltaSozinhoQuandoOSistemaTiraEDevolveOContextoGrafico` · existe · ok (via bateria 357/357) | sim | Só testável forçando no aparelho | IV |
| 11 | TAMP-ENGROSSO | Engrosso do tamponamento entrando no módulo ("gravíssimo") | Não reproduzido (falta módulo e lado) | — | — | `testTamponamentoSempreForaDoModuloEmTodosOsModelosComReguasDe80` (guarda) · existe · ok | — | Sem correção; o teste só prova o catálogo padrão | NI |
| 12 | FORNO-3MM (**torre/balcão forno**) | Folga em cima do forno embutido ≠ 3 mm | Folga antiga; `NaN` no bloco do forno | e3d68b8 | editor.html bloco do forno | `testFornoEmbutidoNoBalcaoA3mmDaTravessaESemNaN` · existe · ok | sim | Forno de projeto antigo mantém valor salvo (decisão) | IV |
| 13 | CANTO-3MM (**porta do canto**) | Portas do canto em L batendo | Sem folga entre as folhas | 503b9ad, 97b6eef | editor.html porta de canto | `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra` · existe · ok | sim | Expectativa muda na branch do canto (linha 72) | IV |
| 14 | TESTE-45-WEBKIT | Teste do PEDIDO 45 diferente no Safari | `Error.stackTraceLimit=10` do Chrome tirava `DRM` da pilha | 457d30d | só teste | `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa` · existe · ok | sim | App não mudou | IV |
| 15 | TESTE-CANTO-67 | Canto do guarda-roupa abria 67° no CI | Teste lia a animação em 3,5 s fixos | 457d30d | só teste | `testPortasDeCantoRobocopAbremEmOrdemSemEntrarEmNada`/teste do canto (nome exato não citado no histórico) · ok | sim | Nome do teste não registrado | ISV |
| 16 | BAT-FLAKY (2 entradas) | Testes que falham só com carga | Esperas fixas de 150–900 ms | 93495d1 | só testes | `testSoOModulo3DE2DComPortaGavetaEDivisoriaSoNele`, `testOrganizacao3DClienteEModoPessoa`, `testAereoFechamentoAteOTetoEmCimaDaBaseEmbutirMuduloDeCimaListaETirarMolduraAntiga` · ok. `testRodapeIgualPintarPorDentroEletroSemAzulEPortaAmortecida` continua intermitente (ok no band2) | sim | `amort` pendente | PI |
| 17 | BAT-SILENCIO (notas) | Script da bateria pulava teste sem JSON | Script ignorava sem resultado | fcfcf28 (1º commit com "SEM RESULTADO", `git log -S`) | tools da bateria | nenhum teste próprio | sim | Sem teste do script | ISV |
| 18 | TAMPA-CEGA (notas) | Tampa cega virava porta comum no "2D só dele" | `soloOn → rgConvert` não levava `v.fixa` | 5ea63f0 (1º commit do teste) | editor.html `rgConvert` (`p.fx`) | `testTampaCegaContinuaCegaNoEditorPorVaosNaoAbreSemDobradicaNemPuxador` · existe · ok | sim | Coberto | IV |
| 19 | TECLADO-TOQUE (notas) | 1º toque perdido depois do teclado | Página descia no meio do toque | ab10e5d ("toques depois de digitar não se perde") | não registrado | histórico diz "com teste" sem nome. HIPÓTESE: `testTecladoNumericoNuncaCobreOCampo` (ok) | sim | Teste não identificado | ISV |
| 20 | VALORES-FERRAGEM (notas) | Tabela Material sem corrediça oculta e facetado | Não registrada | ab10e5d (1º commit do teste) | não registrado | `testTelaValoresTodaFerragemQueEntraNoTotalTemLinhaNaTabela` · existe · ok | sim | Coberto | IV |
| 21 | FITA-08 (**fita de borda**) | Porta do aéreo entra 0,8 mm na fita da caixa (3D) | Porta encostada em `z=d`, fita em `d…d+0,8` | Decisão pendente. Recorte visual só em 1454596 (FT-PORTA) | editor.html `ftClipAll` (branch fita-portas-3d) | `testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D` · **não existe** na candidata · ok em `bfp.log` | não | Posição da porta não mudou (fora do escopo) | PI |
| 22 | TAMP-XP (**tamponamento invisível**) | Tamponamento marcado, contado na medida, sem a peça | Duas fontes de verdade: `m.tr` contava, `m.xp` escondia | b3c1e74 | editor.html `pcDelAt`, `partsOf_xp`, `lt/rt`, `tpDesliga`, `tpXpLimpa`, `tpApagadaNota` | `testTamponamentoDaTorreNoLixoDesmarcaAMedidaSegueAPecaEProjetoAntigoSoAvisa`, `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo` · existem · ok | sim | Projeto antigo só avisa. Coberto no catálogo | IV |
| 23 | TB-MED | "Aumentar comprimento" do tamponamento de baixo contava sem peça | `lt/rt` somavam `tbL/tbR` sem olhar se a peça existe | b3c1e74 | editor.html `tbEstica` | `testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo` · existe · ok | sim | Coberto (875 cenários) | IV |
| 24 | TB-BASE (**tamponamento invisível**) | Tamponamento inferior marcado em módulo com base sem peça (83 modelos) | Opção sem peça real; `tEnd` e `dimExt` contavam | 93495d1 | editor.html `tbAplica`, `tbBaseSusp`, `tbPeca`, `tEnd`, `dimExt` | `testTamponamentoDeBaixoSoOndeViraPecaComBaseSuspensoTemPecaNoChaoNaoSeAplica` · existe · ok | sim | Gerou TB-ROTULO e TB-INV-NUM (corrigidos, linhas 33–34) | IV |
| 25 | XP-PK (**peças fantasmas**) | Mexer num vão fazia peça apagada de outro voltar; ajuste 3D pulava de porta | `pk` = nome + ordem no módulo inteiro | 93495d1 | editor.html `clPoFollow` | `testPecaApagadaEAjusteDo3DSeguemAPecaQuandoOutroVaoMuda` · existe · ok | sim | Gerou XP-PK-SOLO (corrigido, linha 32) | IV |
| 26 | XP-ESTRUTURAL | 🗑 tira lateral/base/divisória/**rodapé/travessa** e as vizinhas continuam descontando | `pcDelAt` tirava só a peça | 93495d1 | editor.html `pcEstrutural` | `testLateralBaseEDivisoriaSaemPelaRegraDoMovelOuNaoSaemComMotivo` · existe · ok | sim | A correção registrada cobre lateral, base, base de cima e divisória. **Rodapé e travessa não aparecem na correção** (não verificado) | PI |
| 27 | RGQK-LARGA | 2 toques no vão do editor por vãos não abria em tela larga | Desenho refeito antes do detector; `closest()` nulo | b3c1e74 | editor.html detector do PEDIDO 62 (`elementsFromPoint`); `tools/bateria_editor.py` | `testEditorPorVaosDoisToquesNoVaoAbreMenuRapidoComAsAbasEBotoesDoPainel` · existe · ok (1366×768) | sim | iPad não verificado | IV |
| 28 | FUNDO-LIXO (**exclusão de fundo**) | Fundo oferecia 🗑 no 3D e não saía | Fundo não é peça do `partsOf`; `e3Part` montava peça de mentira | b3c1e74 | editor.html `pcDelAt` → `m.fundo=false`, `fundoMan` | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | sim | Teste conta caixas; nas branches de fita foi trocado por identidade (288e0e2/8c3f310) | IV |
| 29 | GAV-FANTASMA (**peças fantasmas / 3D inventando peças**) | Lateral/contra-frente da gaveta apagada continuava no 3D | 3D desenhava a caixa inteira a partir da 1ª peça | b3c1e74, 93495d1 | editor.html marcas `cgS/cgVi/cgDq/cgD/cgH` | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | sim | 1ª versão (b3c1e74) causou GAV-MARCA-GDQ, corrigida em 93495d1 | IV |
| 30 | CANTO-FANTASMA (**peças fantasmas**) | Peça do lado do canto em L apagada continuava no 3D | `pkFix3` achava a chave pelo nome | b3c1e74 | editor.html `pkFix3`, filtro de `m.xp` no 3D | `testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma` · existe · ok | sim | Coberto | IV |
| 31 | E3-EIXO-ALA | Quadro da peça no 3D com medidas trocadas na parede lateral | `e3DimsOf` usava eixo do mundo | b3c1e74 | editor.html `e3Loc` | `testQuadroDaPecaNoModuloDaParedeLateralMostraAsMedidasDaPeca` · existe · ok | sim | Coberto | IV |
| 32 | XP-PK-SOLO | Entrar/sair do "2D só dele" apagava cor, ajuste e peça tirada (34 modelos) | Regressão do XP-PK: `rgInit` troca objetos de `m.v` | 8dbc7ae | editor.html `clPoFollow` | `testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho`, `testEntrarESairDoSoEleNoCatalogoNaoMudaCorAjusteNemPecaTirada` · existem · ok | sim | Coberto | IV |
| 33 | TB-ROTULO | Texto do tamponamento de baixo mudou sem pedido | Texto acrescentado no TB-BASE | 8dbc7ae | editor.html `tampHtml` | `testTamponamentoInferiorReconheceACavaSozinhoSemSecaoPosCava` · existe · ok | sim | Coberto | IV |
| 34 | TB-INV-NUM | Conferência do invertido dava 36 em vez de 27 | Efeito esperado do TB-BASE | 8dbc7ae | só teste (expectativa com pedido e data) | `testTamponamentoInvertidoNaoMudaTamanhoDeNadaEmTodoOCatalogo` · existe · ok | sim | Expectativa mudada com comentário | IV |
| 35 | GAV-MARCA-GDQ | Contra-frente ia para a altura da porta | Marca nova usava `gdq`, já do gola lateral | 93495d1 | editor.html `stkParts` / marcas `cg*` | `testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D` · existe · ok | sim | Só existiu em b3c1e74 | IV |
| 36 | SAIA-ALTURA (**saia e porta**) | Com saia, o armário ia até a pedra e a porta ficava atrás da saia | `stAdapta` limitava ao embaixo da pedra | b3c1e74, 93495d1 | editor.html `stArmTop`, `stAdapta`, `underStone`, `STFOLGA_SAIA` | `testComSaiaNaPedraOArmarioInteiroVaiAteEmbaixoDaSaia` · existe · ok | sim | Projeto antigo só muda ao tocar na saia. Frente atrás da saia na profundidade (PEDIDO 59) não mexido | IV |
| 37 | TORRE-GEL-PORTA (**geladeira**) | Trocar a porta de cima fazia porta do teto ao chão | Botões gerais trocavam o tipo do vão `gel` inteiro | e28a490 | editor.html aba Portas, menu do vão | `testTorreDaGeladeiraTrocarAPortaMexeSoNaPortaDeCimaETamponamentoSegueATorre`, `testTorreDaGeladeiraQueJaVirouPortaInteiraAvisaENaoMudaSozinho` · existem · ok | sim | Família (torres de forno) tratada no SEL-TORRE (linha 49). Balcão de forno e porta-tempero não mexidos | IV |
| 38 | TAMP-2D-ALVO (**rodapé/travessa/moldura sumindo**) | Mexer no tamponamento pelo 2D erguia o móvel e apagava rodapé, travessa e moldura | 3 causas: toque sem alvo único; normalização gravava `rod/trav/mold=false`; sem limite no chão | 38ed268 (app); testes 32154d4, 790a990, a13c9e6 | editor.html `pointerdown #svg`, `m._noChao` | `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase` · existe · ok no band2. **Falha na versão publicada** (teste em pixels; Windows CI 45/46) | app sim; teste corrigido só na candidata | Arrastar o corpo ainda ergue (decisão pendente). Pulo de 875 mm em aberto (linha 79) | IV |
| 39 | AMB-RD | Profundidade do ambiente presa no maior comprimento digitado | `setV` só aumentava `S.RD` | 0aa152c | editor.html `setV`, `S.RDw` | `testAmbienteParedeDoLadoProfundidadeNaoFicaPresaERebaixoNaoPassaDaParede` · existe · ok | sim | `S.RDw` não vai para o arquivo (limite conhecido) | IV |
| 40 | AMB-TZ | Rebaixo do teto passava do fim da parede no 3D | `zs()`/`tzGeo()` sem olhar o comprimento | 0aa152c | editor.html `tzClamp` | mesmo da linha 39 · ok | sim | Coberto | IV |
| 41 | P0-01 / ARQ-VAZIO (**perda de projetos**) | `projects.json` vazio apagava a cópia boa do navegador | Arquivo vazio vencia; linha 3085 copiava `[]` | 73ec2f3 | editor.html `pjsEscolhe/pjsDecide/pjsCopia` | `testArquivoDeProjetosVazioOuQuebradoNaoApagaACopiaBoaDoNavegador` · existe · ok | sim | Coberto + sonda s08a | IV |
| 42 | P0-03 / ENGROSSO-APARELHO (**perda de dado**) | Engrosso do projeto zerado pelo ajuste do aparelho | `defs()`/`partsOf()` zeravam `egL/egR` | 37c9915 | editor.html `egEf` | `testEngrossoDoProjetoNaoSomeComOAjusteDesligadoNoAparelho` · existe · ok | sim | Coberto + sonda s08b | IV |
| 43 | P0-03 / ABRIR-REGRAVA | Abrir sem mexer regravava e mudava a data | `draw()` → `schedSave()` com `SVSIG` nulo | 0e353e3, 74fa8b1 | editor.html `SVSIG` | `testAbrirProjetoSemMexerNaoRegravaNemMudaAData` · existe · ok | sim | Coberto | IV |
| 44 | P0-02 / BKP-RESTAURA (**perda de projetos / backup**) | Restauração apagava dados antes de extrair (Android/Windows) | `applyPending` sem cópia, erro engolido; `stage` só via a marca | f96b3e5 | `DataBackup.kt` ×2 (`check`, `swapIn`, `restore_staging`); iOS `Backup.swift` | JVM (13 casos); Android CI 635 passou; sonda 6/6 (CONTEXTO). iOS `BackupSafetyTests` (nomes não registrados) | sim | **Causou BKP-PONTOS** (linha 52), corrigido antes da publicação | IV |
| 45 | GEO-AVISA / DRAW-CATRACA (P1-A) | O ambiente (parede, pé-direito, espessura) modificava os móveis | `confineAll`, `roomClamp`, `wallFollow`, `sanM` gravavam a cada desenho | 04ab7cf, 80aa4a1, 9ec0869 | editor.html guarda de fabricação, `fgConflitos` | `testAmbienteNaoModificaOsMoveisSoAvisa` · existe · ok | sim | **Não cobertos** (registrado): painéis "até o teto", `confine` no arrasto, `sanBase`. Pedra/lixeira fora da parede sem aviso. Pelo campo da parede continuava esmagando (P0-PAREDE, linha 54) | PI |
| 46 | SEL-DIV / DIV-OUTRO-MODULO (P1-E) (**seleção entre módulos**) | Divisória/prateleira de outro módulo mexia na do escolhido | Alças sem dono; arrasto em `S.m` | d77ff63 | editor.html `data-dm`, `drag.mo`, camada 12181 | `testSelecaoDivisoriaDeOutroModuloSoEscolheEleENaoMexeEmNinguem`, `testSelecaoPrateleiraDeOutroModuloMexeSoNela` · existem · ok | sim | Editor por vãos tem seleção própria | IV |
| 47 | SEL-PROJ / SEL-ESTADO / SEL-ENTRE-PROJETOS (P1-G) | Escolha do projeto A fazia o 🗑 apagar no B | Estado de tela global não limpo no `loadState` | 7db71af, d612d17 | editor.html `loadState` (`limpa`) | `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto`, `testSelecaoEscolhasDeTelaZeramAoAbrirOutroProjeto` · existem · ok | sim | Regressão `S.selS=-1` achada e corrigida em d612d17 | IV |
| 48 | SEL-VAO | Vão escolhido inválido depois do toque no 3D | Caminho do 3D troca `S.m` sem conferir `S.sv` | 7a95037 | editor.html acessor de `S.m` | `testSelecaoVaoEscolhidoExisteNoModuloEscolhidoDepoisDoToqueNo3D` · existe · ok | sim | Risco `gv(i)` fechado pelo GV-P1 | IV |
| 49 | SEL-TORRE (**torre forno/micro**) | Porta de cima virava a torre inteira (9 modelos) | Vão `oven` trocado inteiro pelos comandos gerais | 9561fcd (+ fecho da classe 7c939bc; a17bcbf só teste, não publicado) | editor.html `torreForno` | `testSelecaoPortaDeCimaDaTorreMudaSoAPortaDeCima`, `testSelecaoTorrePortaDeCimaPeloVaoDaTorreMudaSoEla` · existem · ok | sim | Balcão de forno (mais baixo) continua como era | IV |
| 50 | GV-P1 (**peças fantasmas: vãos**) | `gv(i)` inexistente gravava vãos fantasma | `gv` preenchia `m.v` até `i` | 54e46af | editor.html `gv`, `gvPadrao` | `testGvVaoQueNaoExisteSemDivisoriasNaoGravaNada`, `testGvVaoQueNaoExisteComTresDivisoriasNaoGravaNadaEOsQueExistemSaoOsCertos`, `testGvVaoQueNaoExisteNaoGravaNadaEmTodaAFamiliaDeModulos` (+4 de garantia) · existem · ok | sim | Sobra em projeto antigo fica (sem migração) | IV |
| 51 | GV-C | Vão escolhido inválido depois de "Limpar divisões" | `#clr` não ajustava `S.sv` | 5a468bf | editor.html botão `#clr` | `testGvLimparDivisoesVoltaOVaoEscolhidoProPrimeiroNaHora` · existe · ok | sim | Outras camadas que mudam `m.div` ficam como risco | IV |
| 52 | BKP-PONTOS (**backup**) | Backup com ".." no nome de arquivo recusado inteiro | Regressão do P0-02: `n.contains("..")` | d669be5 | `DataBackup.kt` ×2 (`check`) | `BackupCaminhoTest` (Android e Windows); Android CI 635 com `foto..jpg` passou; Windows JVM 134/134 | sim | iOS sem mudança | IV |
| 53 | TESTE-CUBA-PAREDE | Teste iOS esperava pedra/lixeira cortadas pela parede | Expectativa velha contra GEO-AVISA | 18027d8 | só teste | `testCubaArrastaNoTouchTecladoSomaLixeiraEParedeEncolhida` · existe · ok | não (só teste) | Falta aviso de objeto fora da parede (pendente nas 3 plataformas) | IV |
| 54 | P0-PAREDE (**alteração incorreta de parede/pé-direito, P0**) | Digitar parede/pé-direito esmagava módulos (largura 500, x 0) e cortava a pedra | Laço no `change` W/H/stT fora da guarda; `stFollowAll` recalculava a pedra; `roomClamp` devolvia pedra incompleta | 6a319d7, b9da40b (+ testes 32154d4, 790a990) | editor.html `change` W/H/stT, `stModSig`, `stFitCalc`, guarda do `roomClamp` | `testP0ParedeEPeDireitoDigitadosNaoMexemNosMoveis`, `testP0ParedeMenorQueOsMoveisSoAvisa`, `testP0ParedeDesfazRefazReabreEGuardaRoupa` · existem · ok | **não** | Regressão da 1ª assinatura (6a319d7) achada e corrigida em b9da40b. iOS CI 616 ok no editor; iPad não rodou | IV |
| 55 | F3-TOQUE | 1º toque num módulo não escolhido já movia | `pointerdown` armava `drag t:'m'` no mesmo gesto | a9a195b | editor.html `pointerdown` 2D | `testF3PrimeiroToqueEmModuloNaoEscolhidoSoEscolheNuncaMove` · existe · ok | não | 3 testes de arrasto adaptados (pedido do Adauto) | IV |
| 56 | F3-SEL | Divisória escolhida sem tocar; 2 toques sem menu; tremida move | Limites soltos e em unidades diferentes | 469c0d0 | editor.html constante `SEL` | `testF3SelecaoDivisoriaDoisToquesETremidaIguaisEmQualquerZoom` · existe · ok | não | **Causou F3-SEL-REGRESSÃO** (linha 62), corrigida | IV |
| 57 | F3-MED | Medida fora do limite trocada em silêncio; campo arredondado | `sanM` cortava sem aviso; `Math.round` no campo | 849a46b | editor.html `setv` (cópia + `sanM`), `inp`/`syncInputs` | `testF3MedidaInvalidaRecusadaComAvisoECampoMostraODecimo` · existe · ok | não | "Do chão" e encaixe de largura válida sem decisão | IV |
| 58 | F3-SETA | Seta de trás não diminui depois de "tampou até o fundo" | Até 120 mm grudava na parede também empurrando | 8fa40d5 | editor.html `pointermove` seta `ek` | `testF3SetaDeTrasDo3DDiminuiDepoisDeTamparAteOFundo` · existe · ok | não | Coberto | IV |
| 59 | F3-REGN | Camadas do engrosso cava aceitavam qualquer número | Campo sem validação | d59831f | editor.html campo de camadas | `testF3CamadasDoEngrossoCavaSo1a3ComAviso` · existe · ok | não | Coberto | IV |
| 60 | F3-MENU | Menus mudando de lugar entre módulos | Ordem das abas diferente no editor por vãos | 4543c0f | editor.html abas do editor por vãos | `testF3MenusNaMesmaOrdemEmTodosOsModulos` · existe · ok | não | Vazamento da aba Portas não reproduzido (risco) | IV |
| 61 | F3-AZUL | Azul de seleção forte | Opacidades 40% / 0,35 | c1d584f | editor.html opacidades | **nenhum teste** (só imagens) | não | Sem teste automático | ISV |
| 62 | F3-SEL-REGRESSÃO | 2 pares de toques viravam 4 (trava o módulo); divisória não pegava após arrastar | Janela de 500 ms soltar-soltar; arrasto contava toque; área estreita | 759ccf0 | editor.html `SEL`, contador de toques | `testDoisToquesNoVaoDeCimaAteOTetoRipadoPainelOuFechamento`, `testDivisoriaArrastaComODedoEmQualquerProjetoECaminho` · existem · ok | não | Era intermitente; band2 ok | IV |
| 63 | TESTE-RECUO | Testes novos não compilavam no iOS (CI 604) | Recuo do JS no literal Swift `#"""` | 7c5b0c4 (candidata), 78c2640 (plano de corte), 43114be (opção marcada, só plano de corte) | só testes | iOS 609/611/613/615/616 compilaram (CONTEXTO); `testOpcaoMarcadaSempreMudaAlgumaCoisa` · existe · ok | não | Prevenção por script fora do repositório | IV |
| 64 | A6-LATGAV (pedido) | Sem ajuste de 1 mm da lateral da gaveta pelo 3D | Não existia | a9b1da7 | editor.html `a6Row`, `e3Render0` | `testA6AlturaDasLateraisDaGavetaPor2ToquesDe1em1mm` · **não existe** na candidata · ok em `telas.log` (8812), `a6t` 1/1 | não | Windows CI 45 353/354; iOS 611 só a falha antiga | IV |
| 65 | A6-PECA (pedido) | Ajuste da contra-frente mudava a caixa inteira | `gbOv` somava todo ajuste | c2951f0 | editor.html `poAlign`, `gbOv`, `partsOf` | `testA6AjusteDe1mmSoNaPecaEscolhidaDaGaveta` · não existe na candidata · ok em `cmp6.log` e `telas.log` (8812) | não | **Causou A6-PECA-REGRESSÃO** (linha 68), corrigida | IV |
| 66 | A6-OP revertido | 890e06e mudou o 1 toque das portas da parede sem pedido | Erro de escopo | 0fad7ef (revert), bb7bd67 (teste), 9d8727d (mira do teste) | editor.html (idêntico a c2951f0) | `testUmToqueNaPortaDaParedeAbreEFechaComoAntes` · não existe na candidata · ok em `mvt` 5/5 e `cmp6`; falhou no celular em `telas.log` antes do 9d8727d | não | Mira do teste no celular corrigida depois de `telas.log`; sem rodada registrada depois | IV |
| 67 | A6-MOVER (pedido) | 2 toques de longe não preparavam o mover | Não existia | 9d3bcce | editor.html `mdArmAt`, `MDMV` | `testA6DoisToquesDeLongeEscolhemOModuloEDoisNoDestinoMovem` · não existe na candidata · ok em `telas.log` (8812) e `mvt` | não | Regressão achada antes do commit e corrigida | IV |
| 68 | A6-PECA-REGRESSÃO | `poAlign` original substituído (alinhamento das portas) | Gancho redefiniu `window.poAlign` | 3bab8a8 | editor.html gancho `poAlign` | `testEditorPorVaosLixeiraEngrossoPortasEAlinhamento` · existe · ok no band2 e no `cmp6.log` (item 6) | não | Coberto | IV |
| 69 | A6-PISCA | Porta piscando no 2º toque | Não comprovada | — (não commitado) | — | medição sem diferença | — | Pendente medir no aparelho | NI |
| 70 | A6-COLISAO (pedido) | Mover eletro/porta/janela por 2 toques atravessava módulos | `frDropAt`/`opPlace` só limitavam à sala | 2ac1ddc, 6aacd8a | editor.html `frDropAt`, `opPlace` | `testA6MoverPor2ToquesConfereColisaoDeEletroEPortaJanela`, `testA6DepoisDeBloquearNadaFicaPresoEOLugarLivreFunciona` · não existem na candidata · passam em `telas.log` 8812 (todas as telas) | não | Coberto na branch | IV |
| 71 | PLANO DE CORTE (PC-ID, PC-TOQUE, PC-ROD, PC-BRANCO) | Peça igual não saía específica; sem toque longo; rodapé sem opção; brancos separados | `S.cutOff` por tipo/medida; `sameFin` calculado e não usado | 3c1a677 (+78c2640, 43114be) | editor.html `S.cutOff` (chave `@uid` + `pk` + nº), `offAdd`, `cutGroups` | `testPlanoDeCorteToqueLongoTiraSoAquelaPecaPelaIdentidade`, `testPlanoDeCorteRodapeForaDoCorteRodapeContinuoFicaSoComOsTrechos`, `testPlanoDeCortePecaBrancaDeQualquerBrancoVaiProMesmoGrupoDaCaixaBranca` · não existem na candidata · `pct_8807` 7/7 (pública `pct_8794` 4/7) | não | Rodapé corrido em L (`cutGroups_lr`) não divide. iOS "rodando" (não verificado) | PI |
| 72 | LAT-MEIO (pedido) | Divisória junto das gavetas mais baixa e sem rebaixo | Regra antiga da divisória | 3991175 | editor.html `m.latMeio` | `testLateralDoMeioJuntoDasGavetasNoInferiorDaCozinha` · não existe na candidata · `lit_8808` 1/1 (pública `lit_8794` 0/1); iOS 613 só a falha antiga | não | `lirel_8808` teve 4 falhas (3 de navegador compartilhado segundo o histórico; sem rodada isolada guardada) | IV |
| 73 | TRAVESSÃO (pedido) | Sem travessão interno/externo | Não existia | a862927 | editor.html `m.tvs`, `m.tvsD` | `testTravessaoInternoExternoComESemFrontalPelaGeometria` · não existe na candidata · `tvt` 1/1; `tvrel_8811` 67/68 (só a falha antiga); iOS 615 | não | Travessa frontal sobrepõe 1 mm às laterais (pré-existente, linha 86) | IV |
| 74 | CANTO-FOLHA (**porta do canto**) | Folha do lado do canto em L não cobria a lateral do fim | Regra "vão − 10, a 3 mm" (`partsOf0`); `z0=D+3` | e1d79b3 | editor.html `partsOf0` porta de canto, 3D `z0=D+4` | 4 expectativas mudadas (`testPortaDeCantoMarcacaoEmTodaPortaELixoApagaDivisoriaOuPortas`, `testPortasDeCantoRobocopAbremEmOrdemSemEntrarEmNada`, `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra`, `testCantoEmLProfundidadeDeCadaLadoPelaPedraComODescontoPadrao`) · existem na candidata com a regra antiga · `cnt2_8809` 16/16 | não | Guarda-roupa mantido. iOS "rodando" (não verificado) | IV |
| 75 | FT-REBAIXO (**fita de borda**) | Fita de 0,8 mm do rebaixo dentro da travessa frontal (3D) | `build_ft` põe tira na frente de cada caixa da lateral | af0c55e (+8c3f310, 49996ac testes) | editor.html `build_ft` | `testFitaDoRebaixoNaoFicaDentroDaTravessaNo3DEPecasECorteNaoMudam` · não existe na candidata · ok em `bft.log` | não | `bft.log` 347/349: a correção quebrou `testToPeca…`; o teste foi trocado depois e **não há bateria completa guardada depois da troca** (`bft2.log` parcial) | ISV |
| 76 | FT-PORTA (**fita de borda**) | Fita de 0,8 mm desenhada dentro da porta fechada (3D) | Porta começa em `z=d+6`, tira em `z1…z1+0,8` | 1454596 (+288e0e2, 1a499eb, 9a865e9 testes) | editor.html `ftClipAll` | `testFitaNaoFicaDentroDaPortaOuFrenteFechadaNo3D` · não existe na candidata · ok em `bfp.log` | não | `bfp.log` 346/349 (2 falhas causadas pela correção); testes ajustados depois; `bfp2.log` parcial. Desempenho 52 → 56–61 ms | ISV |
| 77 | TAMP-CAMINHO (P1-B) | Pelo campo digitado, x=5 vindo de 800 fica em 35 sem tamponamento (vão de 35 mm) | `autoTamp` no `draw` + empurrão do `confineAll` | — | `autoTamp` 5664, `setv` 1608 | nenhum | — | Aberto | NI |
| 78 | P1-D / ST3ONLY | "Só a pedra no 3D" fica ligado e esconde módulos | Chave só desligada pelo botão | 7db71af (só ao abrir outro projeto) | editor.html `build_stOnly`, `limpa` | `testSelecaoEscolhasDeTelaZeramAoAbrirOutroProjeto` · ok | sim | Fechar o 3D no mesmo projeto não desliga (proposta da auditoria pedia) | PI |
| 79 | TAMP-2D-ALVO-PARCIAL | Erguer até atravessar a pedra faz o módulo pular 875 mm de lado | `confineAll` → `stPush` | — | `confineAll`, `stPush` | nenhum específico | — | Aberto | NI |
| 80 | CATALOGO-SOBREPOE (I7) | Módulo novo do catálogo em parede cheia entra por cima dos vizinhos | Não analisada (`newTpl`/colocação) | — | — | sonda s20 | — | Aberto; s29 diz que o novo nasce ajustado com aviso em parede cheia (contradição não resolvida) | NI |
| 81 | VAO-3D-ABERTO | Trocar o vão por gavetas com o 3D aberto não atualiza o 3D | Caminho do vão (1700) não refaz o 3D | — | — | sonda s23 | — | Aberto (erro 11 da lista "2D que não atualiza o 3D") | NI |
| 82 | SANBASE (**travessa/moldura sumindo**) | Ligar/desligar `sup`/`rack` apaga travessa e moldura de vez | `sanBase` (`m.trav=false`) e `sanM` gravam | — | `sanBase` 10389 | sonda s05 | — | Aberto; citado como "não coberto" no GEO-AVISA | NI |
| 83 | RACK-FOLGA | Rack: a folga sobe com a espessura e não volta | Catraca (P1-A) | — | — | sonda s27 | — | Aberto | NI |
| 84 | FORNO-MICRO-LIXO | 🗑 em "Corte do forno" e "Nicho do micro-ondas (aberto)": somem do desenho e o aparelho continua | Não analisada | — | — | nenhum | — | Risco registrado | NI |
| 85 | GOLA-INTERF | Parede de trás do perfil G entra 1,5 mm na caixa no 3D | Porta encostada em `z=d` | 45b8e1c (só configuração `gAfast`/`gReb`, padrão 0) | editor.html Ajustes › Perfil G | `testPerfilGAfastamentoERebaixoConfiguraveisPadraoZeroSemMudarPecas` · ok | sim | Rebaixo não sai no corte nem no 3D. Decisão pendente | PI |
| 86 | TRAV-1MM | Travessa frontal se sobrepõe 1 mm às laterais no 3D | Não analisada | — | — | nenhum | — | Achado no travessão, existe na publicada | NI |
| 87 | CANTO-L-DENTRO | Canto em L: prateleira/base de um braço dentro da do outro; base superior dentro da moldura (3D) | Não analisada | — | — | nenhum | — | Só registrado no FT-PORTA | NI |
| 88 | AVISO-FORA-PAREDE | Pedra/lixeira fora da parede encolhida sem aviso | `fgConflitos` só confere módulos | — | `fgConflitos` | nenhum | — | Decisão do Adauto: melhoria pendente nas 3 plataformas | NI |
| 89 | FITA-BASE-MIRA | `testFitaDaBaseEmbaixoDaPortaPintaPeloToque`: mirando em cima da porta pega seleção errada | Não analisada | 6058b74 (candidata) / 9a865e9 (fita-portas): só o teste mudou a mira | só teste | `testFitaDaBaseEmbaixoDaPortaPintaPeloToque` · existe · ok (mira nova) | não | Homologação a13c9e6: "mirando em cima da porta, falha: continua pegando seleção errada". O teste foi mudado; o comportamento não | NI |

## Defeitos ainda abertos ou só investigados
FATO (registrado nos documentos; nenhum tem correção no app):
- **DOB-DIVISORIA** (linha 6): calço da dobradiça entra na divisória no 3D. Pendente.
- **IOS-ABRE-20S** (8): só observado. Limite não afrouxado.
- **3D-045** (9): causa raiz não comprovada. `ST3ONLY` só é zerado ao abrir outro projeto (78).
- **TAMP-ENGROSSO** (11): não reproduzido.
- **BAT-FLAKY `amort`** (16): intermitente.
- **FITA-08** (21): posição da porta do aéreo depende de decisão; só há o recorte visual na branch fita-portas-3d.
- **XP-ESTRUTURAL rodapé/travessa** (26): a correção registrada não cita esses dois. Não verificado.
- **GEO-AVISA, pontos não cobertos** (45): painéis "até o teto" (`wallFollow`), `confine` no arrasto, `sanBase`.
- **P1-B TAMP-CAMINHO** (77), **pulo de 875 mm** (79), **I7 catálogo por cima** (80), **3D não atualiza com o vão trocado** (81), **`sanBase` apaga travessa e moldura** (82), **rack** (83), **🗑 do corte do forno / nicho do micro** (84), **interferência do gola** (85), **travessa 1 mm** (86), **canto em L dentro** (87), **aviso de pedra/lixeira fora da parede** (88), **mira da fita da base** (89).
- **Plano de corte:** rodapé corrido em L não divide (71).
- **Auditoria P2, só código, não reproduzido:** `putFile` sem retorno de erro nos 3 nativos; campos fora do `snapState` (`S.pw`, `S.RDw/RDs`, `S.rodLast`, `S.deco`, `S.tvLogo`, `S.tvAnim`); migrações que gravam ao abrir (canto < 1200 perde moldura, `rpRowRepair`, filtro do `stw`); voltar no Android só faz `flush()`; 9 detectores de 2 toques; `ANG/ANT` por índice de módulo; coluna "onde" do corte; camada do forno com `clPoFollow`; refazer automático do 3D apaga o desfazer. Fonte: `AUDITORIA_INTEGRIDADE.md` seção 3 (P2).
- **Não reproduzido:** vazamento da aba Portas para o editor por vãos (F3-MENU, 60).
- **A6-PISCA** (69): não mantido; falta medir no aparelho.
- **Saia:** frente do armário continua atrás da saia na profundidade (PEDIDO 59). Não pedido.
- **Torres e balcão de forno, porta-tempero** (37): o mesmo mecanismo da geladeira foi corrigido só na torre de forno (49); balcão de forno e porta-tempero "não mexidos".

## Correções que existem só em branch não publicada
FATO (`git merge-base --is-ancestor` deu falso para `7c939bc`):

| Branch | Itens | Commits | Na candidata (`wt-and`)? |
|---|---|---|---|
| `claude/arquemestre-p0-parede` | P0-PAREDE (54); correção do teste do tamponamento (38) | 6a319d7, b9da40b, 32154d4, 790a990 | sim |
| `claude/arquemestre-fase3-precisao` | F3-TOQUE, F3-SEL, F3-MED, F3-SETA, F3-REGN, F3-MENU, F3-AZUL, F3-SEL-REGRESSÃO, TESTE-RECUO (55–63) | a9a195b, 469c0d0, 849a46b, 8fa40d5, d59831f, 4543c0f, c1d584f, 759ccf0, 7c5b0c4 | sim |
| `claude/arquemestre-candidata-android` | só testes: TESTE-CUBA-PAREDE (18027d8, também nas outras branches derivadas), a13c9e6, 6058b74; a17bcbf | — | sim |
| `claude/arquemestre-ajustes-3d` (item 6) | A6-LATGAV, A6-PECA, A6-OP (revert), A6-MOVER, A6-PECA-REGRESSÃO, A6-COLISAO (64–68, 70) | a9b1da7, c2951f0, 0fad7ef, bb7bd67, 9d3bcce, 3bab8a8, 2ac1ddc, 6aacd8a, 9d8727d | **não** |
| `claude/arquemestre-plano-corte` | PLANO DE CORTE (71); TESTE-RECUO e opção marcada | 3c1a677, 78c2640, 43114be | **não** |
| `claude/arquemestre-lateral-inteira` (+ travessão) | LAT-MEIO (72) | 3991175 | **não** |
| `claude/arquemestre-travessao` | TRAVESSÃO (73) | a862927 | **não** |
| `claude/arquemestre-canto-folha-lado` | CANTO-FOLHA (74) | e1d79b3 | **não** |
| `claude/arquemestre-fita-rebaixo-3d` | FT-REBAIXO (75) | af0c55e, 8c3f310, 49996ac | **não** |
| `claude/arquemestre-fita-portas-3d` | FT-PORTA (76), recorte visual do FITA-08 (21) | 1454596, 288e0e2, 1a499eb, 9a865e9 | **não** (só 6058b74, teste, foi para a candidata) |

Observações:
- Os testes das branches não integradas **não existem** na candidata (`grep "func <nome>"` = 0). Quando forem integradas, a candidata perde essa proteção até o merge.
- CANTO-FOLHA muda 4 expectativas que, na candidata, ainda conferem a regra antiga. Integrar as duas exige escolher uma regra.
- FT-REBAIXO e FT-PORTA mudaram o jeito de `testToPecaQueO3DOfereceApagar…` conferir (identidade em vez de total de caixas). Na candidata o teste continua contando caixas.

## Contagens por classificação (calculadas sobre as 89 linhas da tabela)
Contadas por script na última coluna da tabela.

| Classificação | Linhas | Quantidade |
|---|---|---|
| IMPLEMENTADO E VALIDADO | 1–5, 7, 10, 12–14, 18, 20, 22–25, 27–44, 46–60, 62–68, 70, 72–74 | **60** |
| IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | 15, 17, 19, 61, 75, 76 | **6** |
| PARCIALMENTE IMPLEMENTADO | 9, 16, 21, 26, 45, 71, 78, 85 | **8** |
| NÃO IMPLEMENTADO | 6, 8, 11, 69, 77, 79–84, 86–89 | **15** |
| CORRIGIDO COM REGRESSÃO | — | **0** |
| NÃO LOCALIZADO NO HISTÓRICO | — | **0** |
| **Total** | | **89** |

Recorte útil:
- Dos 60 IV, 41 estão na versão publicada `7c939bc` e 19 só em branch não publicada (53–60, 62–68, 70, 72–74; a 53 só muda teste).
- Desses 19, 9 estão em branches que **não** entram na candidata (64–68, 70, 72–74). A validação deles vem de rodadas parciais guardadas no $SP e do CI da branch, não da bateria completa da candidata.
- "Validado" é no Chromium e no CI. **Aparelho real: 0 de 89.**

### Por que nenhum "CORRIGIDO COM REGRESSÃO"
FATO: 8 correções causaram regressão registrada — P0-02 → BKP-PONTOS; TB-BASE → TB-ROTULO; XP-PK → XP-PK-SOLO; GAV-FANTASMA (b3c1e74) → GAV-MARCA-GDQ; SEL-ESTADO (7db71af) → `S.selS=-1`; F3-SEL → F3-SEL-REGRESSÃO; A6-PECA → A6-PECA-REGRESSÃO; P0-PAREDE (6a319d7) → pedra sem os 30 do tamponamento. Em todas, a regressão tem correção e teste passando (linhas 52, 33, 32, 35, 47, 62, 68, 54). Por isso nenhuma linha ficou com regressão aberta. FT-REBAIXO e FT-PORTA quebraram testes existentes e os testes foram trocados com autorização; sem bateria completa depois, ficaram em ISV.

### Itens obrigatórios destacados (onde estão)
- Tamponamento invisível: 22, 24 (e 23, 3).
- Exclusão de fundo: 28.
- Saia e porta: 36.
- Puxador gola invertido (perfil G): 1, 2, 85.
- 3D inventando peças / peças fantasmas: 9, 25, 29, 30, 50.
- Seleção entre módulos: 46, 47, 48, 56, 62.
- Parede/pé-direito (P0): 54, 45.
- Perda de projetos / backup: 41, 42, 43, 44, 52.
- Porta do canto: 13, 15, 74, 87.
- Torre forno/micro: 49, 12, 84.
- Geladeira: 4, 37.
- Rodapé/travessa/moldura sumindo: 38, 82, 26.
- Fita de borda: 21, 75, 76, 89.

---

# Auditoria funcional do editor (só leitura, 17/11/2026)

## Base e método
- **Código auditado:** candidata `$SP/wt-and` (branch `claude/arquemestre-candidata-android`, HEAD `6b0e9cd`, app em `a13c9e6`), `app/src/main/assets/editor.html` (12.384 linhas). Comparação com a publicada `7c939bc` só onde citado.
- **Testes:** `ios/ArquemestreTests/EditorWebKitTests.swift`, 357 `func test…`.
- **Evidência de execução:** `$SP/band2.log`. 357/357 `ok`, 0 `FALHA` (Chromium sem tela, 1366×768). Os 357 nomes do log batem 1:1 com os 357 da bateria (conferido com `comm`).
- **Bateria publicada (7c939bc):** 348 testes. A candidata tem 9 a mais: `testP0…` (3) e `testF3…` (6). Nenhum teste foi removido.
- **Linhas:** aproximadas, por `grep -n` no `editor.html` da candidata.
- **"Validado" aqui:** teste da bateria que trata do assunto e passou no `band2.log`, mais CI quando citada. **Nenhum item foi testado em aparelho real.** O iPad não rodou em nenhuma branch (CONTEXTO.md). Isso vale para todas as linhas e não se repete em cada uma.
- **Como os testes foram ligados aos itens:** pelo nome e pelo comentário do teste, mais um `grep` no corpo quando citado. Um teste pode cobrir mais de um item.
- **FATO** = arquivo:linha, nome do teste, documento ou commit. **HIPÓTESE** vem marcada.

## 1. Editor 2D/3D
| # | Item | Existe no código (trecho · linha) | Testes que cobrem (todos `ok` em band2.log) | Lacunas conhecidas | Classificação |
|---|---|---|---|---|---|
| E1 | Criação e movimentação de módulos | `newTpl` :1764 · `placeFree` :1151 · `confineAll`/`stPush` :1184/:1297 · guarda GEO-AVISA :12300 · F3-TOQUE :1253 (o 1º toque só escolhe) | testMontaVariosArmariosSemSobreporECortePreciso, testModuloNaoFazNadaSozinhoTamponamentoSoAoCriarEArrastoPorEixo, testTocarOuSegurarOModuloNaoFechaFolgaSozinhoSoArrastandoDeLado, testF3PrimeiroToqueEmModuloNaoEscolhidoSoEscolheNuncaMove, testModuloNovoNaoEntraEspremidoComPortaMinuscula, testArrastarNo3DSoSegurandoBaseNoChaoESemSumir, testAmbienteNaoModificaOsMoveisSoAvisa | Ainda abertos (FASE2_SELECAO.md:100-105; HISTORICO_ERROS.md:476-485): **I7**, módulo do catálogo entra por cima em parede cheia (s20); **s29**, catálogo encaixa a largura na parede cheia; **s27**, folga do rack e módulo lateral ao alargar; **s13**, posição digitada (**TAMP-CAMINHO**). GEO-AVISA "não coberto": `confine` direto no arrasto e `sanBase` (HISTORICO:546-549) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| E2 | Seleção por toque, clique e 2 toques; gestos de 1 a 5 toques | `SEL={mov:10,dt:350,dd:40,div:12}` :769 · `tapCount` :770 · 2 toques no vão/peça (58 ocorrências de "2 toques") · 3 toques :3589/:4048 · 4 toques trava ou destrava · 5 toques "Editar só este módulo" :8128 | testF3SelecaoDivisoriaDoisToquesETremidaIguaisEmQualquerZoom, testF3PrimeiroToque…, testToqueNoVaoComoNoIPhoneSemClickEscolheOVaoEmTodosOsModelosDoCatalogo, testDoisToquesNo3DLongeAbreOModuloPertoAbreSoAPeca, testEditorPorVaosDoisToquesNoVaoAbreMenuRapidoComAsAbasEBotoesDoPainel, testGestosNoEletro2ToquesMudaDeLugar3ToquesConfiguracoes, testTresToquesEncaixaNaPedraComPingadeiraEEsticaOMovel, testPedraSolidaGeladeiraAcompanhaPortaDaSalaE5ToquesEditaSoOModulo, testToqueNo3DAchaAPecaCertaEBordaFina, testSelecao… (7 testes) | GESTOS_CONTROLES.md "a levantar": segurar, pinça junto com arrasto, caneta, conflito entre os 2 toques de vários lugares. AUDITORIA_INTEGRIDADE.md:119: 9 detectores de 2 toques com o mesmo estado `TQK`. HOMOLOGACAO_ANDROID: `testFitaDaBase…` mirando em cima da porta ainda pega a seleção errada. Nenhum teste de pinça ou caneta (grep `pinch`/`gesturestart` = 0). O item 6 (2 toques de perto e de longe) está só em `wt-a6`, fora da candidata | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| E3 | Edição individual de peças | Quadro da peça do 3D (`e3del`/`e3x` :3852) · ajuste fino ±1/±0,5 · engrosso | testEditarQualquerPecaCaixaDaGavetaCantoEmLEMedidaDigitada, testQuadroDaPecaNoModuloDaParedeLateralMostraAsMedidasDaPeca, testEngrossoAcompanhaAPrateleiraEAjusteFinoNo3D, testPecaApagadaEAjusteDo3DSeguemAPecaQuandoOutroVaoMuda, testAjusteCorEPecaApagadaAcompanhamAPecaNoEditorPorVaos | E3-EIXO-ALA corrigido, com teste. Melhorias do item 6 (laterais da gaveta, peça independente) fora da candidata | IMPLEMENTADO E VALIDADO |
| E4 | Exclusão e restauração (🗑, ↺ voltar peça apagada, desfazer) | `pcDelAt` :9699 · `pcEstrutural` :9714 (lateral, base e divisória pela regra) · `rgDelDiv` :10626 · `[data-xpr]` "↺ Voltar as peças apagadas" :9732 · `histTick`/`histGo` :263/:265 (100 passos, junta mexidas em até 700 ms) · `$('und')` | testApagarSoUmaPecaPrateleiraPortaENo3D (clica `[data-xpr]`, linha 3518 do teste), testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorteSemFantasma, testLateralBaseEDivisoriaSaemPelaRegraDoMovelOuNaoSaemComMotivo, testSelecaoEExclusaoApagaSoOEscolhidoEmTodasAsCombinacoes, testApagarDivisaoEmQualquerOrdem, testDesfazerERefazerDevolvemOProjetoIgualPassoAPasso, testTamponamentoDesligarERelegarNaoDesfazOutraMudanca, testFundoMostraSoOQueEDoFundo, testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto | **FATO** (:9732): o ↺ devolve **todas** as peças tiradas do módulo de uma vez (`S.m.xp=[]`), não uma por uma. Riscos (HISTORICO:322-325): "Corte do forno" e "Nicho do micro-ondas" somem do desenho e o aparelho continua; peça apagada em camadas depois do filtro (não reproduzido, AUDITORIA_INTEGRIDADE:136). Etapa 7 do PLANO_MESTRE ainda na fila | IMPLEMENTADO E VALIDADO |
| E5 | Sincronização 2D/3D/lista de corte | `draw` :1057 chama `histTick`; `re3()` depois de cada mudança; `partsOf` :516 serve 2D, 3D e corte | testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D, testTodoModuloCadastradoApareceNo3DEmQualquerCaminho, testPaineisDiferentesEmCadaParedeBatemNo2DNo3DENoCorte, testTamponamentoEsticadoNo3DEntraNoPlanoDeCorteNaHora, testModuloQueNaoApareceNo3DViraAvisoERefazSozinho, testPlacaDo3DSolidaTravaApagaAparece2DEPlanoDeCorte | **Erro comprovado aberto: VAO-3D-ABERTO (s23).** Trocar o vão por gavetas com o 3D aberto não atualiza o 3D (AUDITORIA_INTEGRIDADE:244; FASE2_SELECAO:103 "continua igual"). Nenhum teste cobre esse caminho | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| E6 | Paredes, pé-direito e cotas editáveis | P0-PAREDE :2300/:2411 · `wallFollow` :2829 (não move o aéreo, :2832) · `roomClamp` :3040 · `fgConflitos` :12344 (aviso) | testP0ParedeEPeDireitoDigitadosNaoMexemNosMoveis, testP0ParedeMenorQueOsMoveisSoAvisa, testP0ParedeDesfazRefazReabreEGuardaRoupa, testAmbienteNaoModificaOsMoveisSoAvisa, testParedeLateralNaoCresceSozinha, testAmbienteParedeDoLadoProfundidadeNaoFicaPresaERebaixoNaoPassaDaParede, testPeDireitoNaoMedidoNaoInventaMedidaAteOTeto, testGessoTrenaAjustarTetoArrastarEMedidasDosQuatroLados, testMedidasDaObraTravadasComSenhaTomadaEEsquadro | Painéis "até o teto" que acompanham o pé-direito: pergunta em aberto (HISTORICO:547). iOS CI 616 do P0: editor sem falhas, iPad não rodou | IMPLEMENTADO E VALIDADO |
| E7 | Ímãs, alinhamentos e guias | `snapMod` :1205 (ímã só no eixo arrastado, `DAX`) · linhas `SN` · `rpAlignAf` em `roomClamp` :3040 | testImaDoTopoAlinhaAereoComOVizinhoNo2DSemEntrarNemPassarDoTeto, testImaDoTopoNo3DAlinhaPeloTopoQueSeVeComTamponamentoDeCima, testTrenaGrudaNoCantoPorDentroEPorFora, testRackNoMeioDoPainelSuspensoECentralizar, testEditorPorVaosLixeiraEngrossoPortasEAlinhamento, testModulosDeParedesDiferentesEncostamNoCantoSemEntrar | `testImaDoTopo…` falha com a máquina carregada: a linha sai depois dos 80 ms que o teste espera (HOMOLOGACAO_ANDROID). Sem defeito comprovado | IMPLEMENTADO E VALIDADO |
| E8 | Zoom, arrasto e seleção de vãos | `zoom` :1218 (vista de 150 a 900) · `gv` :277 (GV-P1 :274: vão que não existe não grava) · alça da divisória F3-SEL :12210-12217 | testZoomDo3DChegaBemPertoDaPeca, testFocarSoNoModuloEArrastarJanelaNo2D, testDivisoriaArrastaComODedoEmQualquerProjetoECaminho, testGv… (8 testes), testSelecaoVaoEscolhidoExisteNoModuloEscolhidoDepoisDoToqueNo3D, testTocarEmQualquerMedidaDoVaoEDigitar, testNichoDoEletroArrastaEArrastePresoNaoTravaATela | Sensibilidade do arrasto e do zoom do 3D não inventariada (GESTOS_CONTROLES). `S.sv` velho ao mexer direto em `m.div` (FASE2_SELECAO:152, risco sem efeito na gravação) | IMPLEMENTADO E VALIDADO |
| E9 | Persistência (salvar, reabrir, autosave) | `snapState`/`loadState` :2426/:2427 · `svSig`/`schedSave` :2464/:2465 (abrir sem mexer não grava) · o `loadState` de outro projeto zera as escolhas (SEL-ESTADO) | testSalvarSozinhoSoGravaQuandoMudaERespondeRapido, testSalvarLeveCadaMexidaGravaSoOProjetoAbertoEABibliotecaQuandoPara, testSalvarLeveRecuperaNaAberturaAMexidaQueNaoChegouNaBiblioteca, testAbrirProjetoSemMexerNaoRegravaNemMudaAData, testArquivoDeProjetosVazioOuQuebradoNaoApagaACopiaBoaDoNavegador, testEngrossoDoProjetoNaoSomeComOAjusteDesligadoNoAparelho, testRecuperarProjetosDeUmBackupSemTrocarNada, testTransferenciaEBackupLevamOProjetoInteiro, testProtecaoDosProjetosHistoricoSenhaELixeira, testProjetoNaoSomeAoTrocarDeParedeOuAmbienteEHistoricoRestaura, testTamponamentoLigadoSalvarReabrirDesfazerRefazer. Mais: sonda de 15/15 projetos da 1.0.632 iguais, sonda de backup 6/6, CI Android 635 (JVM) | **Risco ainda presente** (AUDITORIA_INTEGRIDADE:110; conferido: `snapState` :2426 não tem `pw`, `RDw`, `RDs`, `rodLast`, `deco`, `tvLogo`, `tvAnim`): esses campos se perdem ao reabrir. Para `S.RDw/S.RDs` o próprio documento diz "candidato" (hipótese) a medida errada depois de reabrir. Falta confirmação de gravação pela ponte (P2). Restauração em aparelho real não verificada | IMPLEMENTADO E VALIDADO |

## 2. Módulos e marcenaria
| # | Item | Existe no código | Testes | Lacunas | Classificação |
|---|---|---|---|---|---|
| M1 | Inferiores e superiores | `TPL` :1758 (balcão, aéreo, gaveteiro, nicho, maleiro, canto L) · `defs` :281 (`rod:!m.sup`, `mold:!m.sup`, `trav:!m.sup`) | testMontarDoZeroNoFimDeCadaCategoriaCriaESalvaQuartoSemCozinha, testAbrirPortasEGavetasFuncionaEmTodoJeitoDeModuloDoCatalogo, testAereoFechamentoAteOTetoEmCimaDaBase…, testModuloDeBaixoSeAdaptaAAlturaDaPedraNaoEJogadoProLado, testFrontalEmbaixoEMolduraNaEstruturaDoSuperior | Ver I7 em E1 | IMPLEMENTADO E VALIDADO |
| M2 | Torres | Torre quente, forno + micro, despensa, sapateira, torre da geladeira · SEL-TORRE :272/:12380 | testTorrePorVaosRecorteMeioRecortePortaNormalEModelosReais, testTorreQuenteEditavelPelaLupaComNichosEMicroOndas, testTorreDoFornoTrocaAPortaDeCadaVaoEGeladeira, testSelecaoPortaDeCimaDaTorreMudaSoAPortaDeCima, testSelecaoTorrePortaDeCimaPeloVaoDaTorreMudaSoEla, testTorreDaGeladeiraTrocarAPortaMexeSoNaPortaDeCima…, testTorreDaGeladeiraQueJaVirouPortaInteiraAvisaENaoMudaSozinho, testTamponamentoDaTorreNoLixo…, testFornoEscolheOAparelhoNuncaEncolhe… | Risco (FASE2_SELECAO:109): no balcão de forno, os botões gerais da aba Portas trocam o vão do forno por porta | IMPLEMENTADO E VALIDADO |
| M3 | Guarda-roupas e closets (editor por vãos) | Editor por vãos (`rgDelDiv`, `rgSanBase` :10417, `rgSetSize` :10626) · TPL guarda-roupa 2/3/4 vãos, de correr, closet aberto, canto L do guarda-roupa | testEditorPorVaosLixeiraEngrossoPortasEAlinhamento, testEditorPorVaosGavetasColunaTorreCorrerECantos, testTorrePorDentroDoGuardaRoupaMedidaRealEMaisUmaPrateleira, testGavetaDaTorrePorForaEGuardaRoupaPorDentro, testPortaInteiraOuMaleiroComPortaPropria, testGavetasNoVaoPerguntaQuantasEPoeExatoEmTodosOsModelos, testF3MenusNaMesmaOrdemEmTodosOsModulos, testP0ParedeDesfazRefazReabreEGuardaRoupa | Só 6 testes têm guarda-roupa ou quarto no nome; o resto vem dos testes por vãos e do catálogo inteiro. Vazamento da aba Portas para o editor por vãos: risco não reproduzido (FASE3:111). Canto (folha) em `wt-cn`, fora da candidata | IMPLEMENTADO E VALIDADO |
| M4 | Portas convencionais, basculantes e de correr | `v.k==='door'` :602 · `v.k==='slide'` :600 (2 a 4 folhas, sobreposição `pcSob`) · basculante (31 ocorrências) · dobradiça: STD e furação :326/:335 | testPortaBasculanteAbreParaBaixoOuCimaNo2DENo3D, testBasculanteComCavaSemEngrossoFolga4NoTopo, testPortaDeCorrerGLateralEEspelhoNaFolhaCom2Toques, testPortaDeVidroTelescopicaReconstroiEAbre, testFolgaNoMeioDasDuasPortasELadoComDesenhoNoModulo, testPortasNaoEntramEmNadaGavetaSemCalcoMolduraEDobradica, testFuracaoPadrao120NoCentroDoCanecoAjustavel…, testFuracaoDaDobradicaNoMesmoLugar…, testTampaCegaNaoAbreDeJeitoNenhumEmTodoOCatalogo, testArmarioDeCantoFolgaDe3mm…, testPortaNaoEntraNoTamponamentoDeCimaEmTodoOCatalogo | **FITA-08 pendente** (HISTORICO:173-176): no 3D, a porta do aéreo entra 0,8 mm na fita da caixa. Contraria a regra "nada entra em nada". Depende de decisão. A correção está só em `wt-fp`, fora da candidata. Risco do balcão de forno (M2) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| M5 | Gavetas | Lateral, contra-frente, gaveta com cava sem calço :595-597 · corrediça | testGavetaTelescopicaRebaixoContraFrenteEFundo, testGavetaComFolgaDivididaENaoEncostaEmCimaCorredicaNoMeio, testGavetasAjustesNoToqueECatalogoOrganizado, testGavetasNoVaoPerguntaQuantasEPoeExato…, testPortasNaoEntramEmNadaGavetaSemCalco… | GAV-FANTASMA corrigido. A troca de vão por gavetas com o 3D aberto não atualiza (E5) | IMPLEMENTADO E VALIDADO |
| M6 | Gavetas internas, divisórias e prateleiras (com e sem recuo) | Prateleira `/^Prateleira( solta\| interna)?$/` :609 · divisória com alça F3-SEL | testDivisoesComRecuoOuSemRecuo, testPrateleiraEncostaNaOutraSemEntrarUmaNaOutra, testDivisoriaEPrateleiraNovasNaoCaemEmCimaDeOutra, testPrateleiraSoMexeComAAbaDivisoesAberta, testVaoEstreitoAvisaETiraADivisoriaSoNoToque, testProjetoAntigoCorrigeDivisoriasNaBeiraComUmToque, testSelecaoPrateleiraDeOutroModuloMexeSoNela, testSelecaoDivisoriaDeOutroModulo… | Nenhuma aberta registrada | IMPLEMENTADO E VALIDADO |
| M7 | Engrossos e tamponamentos | Uma fonte só (`tl/tr/tt/tb`) :553 · `tEnd` :555 · laterais :556-557 · `egEf` :564 · `autoTamp` :5693 · `tampHtml` :1633 · `dimExt` :1616 · `lt`/`rt` :1199 | 41 testes com tamponamento ou engrosso no nome (lista na seção 5), entre eles testTamponamentoSempreForaDoModuloEmTodosOsModelosComReguasDe80, testTamponamentoEsquerdo/DireitoLigadoNoModuloEncostadoNaParedeSegueARegra, testTamponamentoSemEspacoAvisaEDeixaOProjetoIgual, testTamponamentoMovelExistenteNaoEEmpurradoSozinho, testF3CamadasDoEngrossoCavaSo1a3ComAviso, testTamponamentoNo2DMudaSoAAlturaDele… | **TAMP-CAMINHO (P1-B), aberto:** pelo campo digitado sobra vão de até 35 mm junto da parede (HISTORICO:476). `tbL`/`tlAdj`/`trAdj` digitados sem limite (`tbL` 2000 → peça de 3000), à espera de decisão (FASE3:77,112). `testTamponamentoNo2D…` falhou no Windows 46 e foi corrigido no teste em `a13c9e6` (folga do arrasto passou a 10 px, sem defeito de cálculo). Lateral do meio e travessão em `wt-li`/`wt-tv`, fora da candidata | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| M8 | Tamponamento superior com lateral descendo à esquerda e à direita (pedido na fila) | **Já existe:** "Tamponamento superior do módulo" `tt` :1633 (passa reto em cima, `tbW`) e "Inverter" (`ttInv`). Nos superiores, o tamponamento esquerdo e o direito como "lateral inteira" (`tlA/trA='full'`) descem `tpMm` abaixo da caixa: botões "Passa 2 cm" e "Passa 2,5 cm" e "Usar em todos os superiores" (`latPassaHtml` :1554, `tEnd` :555). `tpUp` :2278 (`tsCm`/`tiCm`) e `tiBx` sobem ou descem o tamponamento. **Não existe:** uma opção "superior + laterais descendo" como peça combinada, nem nos inferiores | testTamponamentoInvertidoAPecaEAMesmaSoViraNaAbaENos3Toques (`ttInv`), testImaDoTopoNo3DAlinhaPeloTopoQueSeVeComTamponamentoDeCima, testPortaNaoEntraNoTamponamentoDeCimaEmTodoOCatalogo, testTamponamentoInferiorReconheceACavaSozinhoSemSecaoPosCava (único teste com `data-tpmm`) | Etapa 5 do PLANO_MESTRE (`wt-cl`): "tamponamento superior, laterais descendentes esquerda e direita, medida interna útil real". Ainda na fila, nenhum commit dela na candidata. A especificação do pedido não foi localizada em REFERENCIAS.md (**hipótese:** falta a referência) | PARCIALMENTE IMPLEMENTADO |
| M9 | Medidas internas reais depois do tamponamento | `dimExt`/`dimExtNote` :1616-1617 mostram "Móvel pronto = caixote + tamponamento" e somam o tamponamento ao digitar a medida final (`setv` com `wE/hE/dE` :1627). No texto, "interna" quer dizer o caixote ("externa = interna (caixote)") | testMedidaComTamponamentoEhAPontaDasPecasEmTodoOCatalogo, testTamponamentoSempreForaDoModulo…, testTamponamentoInvertidoNaoMudaTamanhoDeNadaEmTodoOCatalogo, testTorrePorDentroDoGuardaRoupaMedidaRealEMaisUmaPrateleira | Não localizada uma exibição da medida interna útil (caixote menos as laterais, o teto e a base, com a posição). Faz parte da etapa 5 do PLANO_MESTRE. Nenhum teste lê `dimExtNote` (grep = 0) | PARCIALMENTE IMPLEMENTADO |
| M10 | Saias e rodapé, molduras e folgas automáticas | Saia da pedra :467-468 (SAIA-ALTURA) · rodapé `finOf` :305 · moldura `moldOk_` :644 · `defs` :281 (`rodMm:100`, `moldMm:30`) · pés de metal | testRodapeDeMdfFaceandoOuEmbutidoDosDoisLadosOuDeUmSoESecaoFechada, testRodapeDoCantoNaMesmaCorDosOutros, testLateraisAtePisoRodapeEntreElas…, testPesDeMetalNoLugarDoRodape…, testPesDeMetalEmTodoTipoDeModulo…, testComSaiaNaPedraOArmarioInteiroVaiAteEmbaixoDaSaia, testArmarioEmbaixoDaPedraComSaiaNaoPassaDaSaia, testSaiaDaPedraSemDivisaoNo3DENo2D…, testMolduraDoTamponamentoVeioDaMadeira…, testFrontalEmbaixoEMolduraNaEstruturaDoSuperior | "Do chão" que passa do teto: à espera de decisão (FASE3:112) | IMPLEMENTADO E VALIDADO |
| M11 | Puxadores cava, gola, perfil G e facetado | Gola, perfil G em pé :791-792 (orientação conforme `especificacoes/puxador-gola.md`) · facetado `pxDesc` :345/:357 · cava (219 ocorrências), `temCava` :1550 | testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlaca…, testPerfilGolaSolidoPassadaPropriaSemGranuladoAbertoEFechado, testPerfilGAfastamentoERebaixoConfiguraveisPadraoZeroSemMudarPecas, testGolaVerticalEHorizontalEDesenhoDeCadaPuxador, testFacetadoComPonteiraCurvaNasPontas, testPortaComCavaSempreLateralMais30EmTodoOCatalogo, testCavaSemFaixaPretaChanfroNaPortaAberta…, testPuxadoresDescontamCertoEConchaNoMeio, testPuxadorEscolhidoNumaPortaValeProProjetoTodo, testRasgosDaUsinadaDeixamFolgaDaCavaEDoPuxador | GOLA-001 e GOLA-002 corrigidos, com teste. Proposta do batente da cava (PROPOSTA_BATENTE_CAVA.md) não implementada | IMPLEMENTADO E VALIDADO |
| M12 | Fundos, bases, réguas e travessas | Base inferior :558 · laterais por fora (`latFora`) :557 · `travMm:70` · `fundoDims` :660 · `fundoT` :11173 · `pcEstrutural` | testFundoMostraSoOQueEDoFundo, testSoEmbaixoDaPiaSemFundoETorreComBaseETeto, testLateraisPorForaLateralQuadradaSemRebaixoTravessaDeLado…, testEstruturaSemComponentesESemTirarLateralDoModuloPronto, testLateralBaseEDivisoriaSaemPelaRegra…, testCaixaDaGeladeiraRipadoEmCimaEReguasDasLaterais, testReguaEspacadoraEditavelEDobradicaRetaOuCurva, testTodaReguaDoEngrossoDaPrateleiraApareceNo3D, testFornoEmbutidoNoBalcaoA3mmDaTravessaESemNaN | `sanBase` (:10417, `trav=false`) fora da guarda GEO-AVISA (HISTORICO:549). Travessão em `wt-tv`, fora da candidata | IMPLEMENTADO E VALIDADO |
| M13 | Ferragens e acessórios | `PRAVG`/`PRLIST` :320-321 (dobradiça, corrediça, facetado…) · tabela de Valores · lixeira, divisor de talheres, depurador | testTelaValoresTodaFerragemQueEntraNoTotalTemLinhaNaTabela, testFerragensFitaPorCorNichoNaCorDeFora…, testConfiguracoesCorredicaOcultaConchaECorteAvulso, testDivisorDeTalheresSoDizColocadoQuandoEntrou, testDepuradorDeEmbutirNasDuasMontagens, testLixeiraDeEmbutirNaPedraComMedidaReal, testCaixoteReguaTalheresBiblioteca | VALORES-FERRAGEM corrigido, com teste | IMPLEMENTADO E VALIDADO |
| M14 | Móveis curvos | **Nenhum módulo curvo no catálogo.** Nomes de `TPL` e do catálogo conferidos com grep "curv". "Curvo" só aparece em: canto arredondado da pedra e da parede (`w.c==='curvo'` :5595-5615), "Prateleira suspensa · canto arredondado", chapa curva da base do ripado :641, sofá :5212, ponteira do facetado e porta robocop | Nenhum. Os 2 testes com "Curva" no nome tratam da dobradiça curva e da ponteira do facetado | Pedido não localizado no histórico nem no PLANO_MESTRE (**hipótese:** está fora da fila) | NÃO IMPLEMENTADO |

## 3. Cálculos
| # | Item | Existe no código | Testes | Lacunas | Classificação |
|---|---|---|---|---|---|
| C1 | Espessuras reais | `sanM` :515 (espessura do tamponamento só 15, 25 ou 30) · `defs` `esp:15` · `STDD` `esp:15,fundoMm:6` :312 · `mat` por peça | testAmbienteNaoModificaOsMoveisSoAvisa (caso espessura +3: forno 600 → 606 corrigido), testEngrossoDoProjetoNaoSomeComOAjusteDesligadoNoAparelho, testMedidaComTamponamentoEhAPontaDasPecas…, testSomaDasPlacasConfereComATrenaEAJunta | Nenhum teste tem "Espessura" no nome; a cobertura vem do corpo dos testes citados | IMPLEMENTADO E VALIDADO |
| C2 | Descontos e folgas | Porta `pV/pS1/pSn/pG` :602 · `gavDsc:56`, `gavCF:15`, `gavRb:6` :312 · folga de 3 mm no canto · cava +30 | testPuxadoresDescontamCertoEConchaNoMeio, testBuscaAchaTVEletrodomesticoEFacetadoDesconta, testGavetaComFolgaDividida…, testFolgaNoMeioDasDuasPortas…, testBasculanteComCavaSemEngrossoFolga4NoTopo, testArmarioDeCantoFolgaDe3mm…, testDescontoZeroTamponamentoPedraCooktopModo3D, testCantoEmLProfundidadeDeCadaLadoPelaPedraComODescontoPadrao | Nenhuma aberta registrada | IMPLEMENTADO E VALIDADO |
| C3 | Dimensões internas e externas | `dimExt` :1616 · `setv` com `wE/hE/dE` :1627 · `ex()` :3513 (conta digitada) · F3-MED :1608 (recusa com aviso e mostra o décimo) | testF3MedidaInvalidaRecusadaComAvisoECampoMostraODecimo, testMedidaDePecaSemDecimoEPartesSomamAPecaInteira, testMedidasCruzadasTrenaNoCampo…, testDistanciasDoModuloTocaEDigitaELimiteDoAereo, testTecladoNumericoNuncaCobreOCampo | **Risco** (FASE3:72, só por leitura do código): em teclado físico, "1.200" é lido como 1,2 e vira 100. `rowFix` :8465 pode reduzir a largura digitada (s29, à espera de decisão). A medida interna útil não é mostrada (M9) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| C4 | Portas e gavetas | Ver M4 e M5 · `portaMax:600` | testGavetaTelescopicaRebaixoContraFrenteEFundo, testPortaDoAereoVaiAteOFinal, testPortaDoAereoVaiAteOFimDasReguas, testModuloNovoNaoEntraEspremidoComPortaMinuscula, testGavetasNoVaoPerguntaQuantasEPoeExato… | FITA-08 só no 3D (M4) | IMPLEMENTADO E VALIDADO |
| C5 | Tamponamentos e engrossos (cálculo) | `tEnd`, `tNote` :555 · `egEf` :564 · TB-MED, TB-BASE, TAMP-XP (uma fonte só) | testMedidaComTamponamentoEhAPontaDasPecas…, testTamponamentoDeBaixoSoOndeViraPecaComBase…, testTamponamentoInferiorEmModuloSemBase, testEngrossoAcompanhaAPrateleira…, testF3CamadasDoEngrossoCavaSo1a3ComAviso, testF3SetaDeTrasDo3DDiminuiDepoisDeTamparAteOFundo | O limite digitado (M7) é posicionamento, não fórmula | IMPLEMENTADO E VALIDADO |
| C6 | Lista de peças | `partsOf` → lista · aba Lista de Corte | testNadaDeEnfeiteListaDeCorte, testToPecaQueO3DOfereceApagarSaiDe2D3DListaECorte…, testPainelNaoDuplicaEmOutraParedeDepoisDaLista, testListaEPecaNo3DVoltamPraMesmaParede, testListaDeMoveisNoOrcamento. Sonda de 15/15 projetos iguais em peças | Nenhuma aberta registrada | IMPLEMENTADO E VALIDADO |
| C7 | Fitas de borda (metragem; 0,8 mm só no desenho 3D) | **Metragem:** `edgeSides`/`edgeTxt` :404-406 (lados com fita por peça) · `fitaMm:22` :312 · linhas de Valores "Fita de borda N mm · caixote / cor de fora" :448 (`T.tB*fK()`, metros já com a perda) · `fitaM` :2528. **0,8 mm:** só no 3D, comentário :5032 ("tira de 0,8 mm na frente de cada peça do caixote") e toque :5748. Fato: não entra no corte (HISTORICO:175, "o plano de corte não muda") | testLateraisPorForaLadoDaFitaEImpressaoDoPlano (único com `edgeSides`), testFerragensFitaPorCorNichoNaCorDeForaEPaletaAmadeirada ("m de fita"), testFitaDeTopoNaCorDasPortas…, testFitaUmaPorUmaPrateleiraTirarEBranca, testFitaDaBaseEmbaixoDaPortaPintaPeloToque | **Nenhum teste confere o número da metragem** (por grep: os testes de fita tratam de cor, toque e lado). FITA-08 pendente. Etapa 8b (fita de 1 mm, separar corte, fita e medida acabada) ainda na fila. Fita do rebaixo e fita das portas no 3D em `wt-ft`/`wt-fp`, fora da candidata | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| C8 | Quantidade de chapas (otimizador com limite de 120 ms) | **FATO** :679: `TM_=window.CUTFAST?0:window.CUTDEEP?900:120`, laço `while(Date.now()-t0<…&&it<400)`. Depois `packTight` :700 com `TM=…:220` ms. Semente fixa (`sd=P.length*7919+…`), mas o número de voltas depende do relógio. `packLB` :813 (limite de baixo). `packSheets` :683 | testPlanoDeCorteAbreOtimizaENaoDaErro, testPlanoDeCorteApertaAChapaSemPiorarNoJeitoDeCortarEscolhido, testValoresCobraAChapaPeloQueFoiUsadoNaoAChapaInteira, testSobraQueEuTenhoEntraNoPlanoDeCorteETrocaChapaInteira. Sonda: 15/15 iguais em chapas (mesma máquina) | **RISCO:** numa máquina lenta (celular barato, bateria carregada), as 400 voltas não cabem em 120 ms e 220 ms. O número de chapas pode sair diferente para o mesmo projeto, e de uma vez para outra. A comparação 15/15 foi feita numa máquina só. Nenhum teste fixa o número de chapas com a máquina lenta. **Hipótese não medida:** a diferença no aparelho real | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| C9 | Plano de corte | `packSheets`/`packOnce` :683/:827 · `cutModeHtml` :750 · refilo e serra (`PRD` :308) · veio | testPlanoDeCorteTodaPecaEntraUmaVezDentroDaChapaSemUmaEmCimaDaOutra, testPlanoDeCorteLocalizaCadaPecaNo3D, testLocalizadorDaChapaAchaAPlacaDoPainelNo3D, testRipadoNoPlanoOtimizado…, testEnviarProjetoCompactaSemPrecoEAbreNoModoCorte, testLateraisPorForaLadoDaFitaEImpressaoDoPlano | Melhorias do plano de corte em `wt-pc`, fora da candidata. No iOS, "rodando" (não verificado, CONTEXTO.md) | IMPLEMENTADO E VALIDADO |
| C10 | Projeto × fabricação (`partsOf` como fonte única) | `partsOf` :516 = `montMerge(m,pxPost(m,partsOf0(m)))`, `partsOf0` :529. Serve 2D, 3D, lista, corte e valores. A guarda GEO-AVISA não deixa o desenho mudar medida | testBateriaNovaCatalogoSalvarReabrirPecaNaoEntraEmPecaECorteIgualAo3D, testTodoModuloCadastradoApareceNo3DEmQualquerCaminho, testMesmoRoteiroEmTodosOsAmbientesProjetoLimpo…, testOlharTocarEAbrirTelasNaoMudaOProjetoSozinho, testOlharOModuloNoDoisDSoDeleNaoMudaNadaNoCatalogoInteiro, testAmbienteNaoModificaOsMoveisSoAvisa. `partsOf` aparece 293 vezes na bateria | Riscos: peças em camadas depois do filtro de peça apagada (não reproduzido); `sanM` dentro de `partsOf` :516 ainda corrige o dado do módulo ao ler (ex.: `tpMm` 2 → 20), uma migração que grava ao abrir (P2, AUDITORIA_INTEGRIDADE:328) | IMPLEMENTADO E VALIDADO |

## 4. Contagem por classificação (33 itens)
| Classificação | Qtde | Itens |
|---|---|---|
| IMPLEMENTADO E VALIDADO | 22 | E3, E4, E6, E7, E8, E9, M1, M2, M3, M5, M6, M10, M11, M12, M13, C1, C2, C4, C5, C6, C9, C10 |
| IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE | 8 | E1, E2, E5, M4, M7, C3, C7, C8 |
| PARCIALMENTE IMPLEMENTADO | 2 | M8, M9 |
| NÃO IMPLEMENTADO | 1 | M14 |
| CORRIGIDO COM REGRESSÃO | 0 | Só a F3-SEL-REGRESSÃO, já corrigida e com teste (HISTORICO:722) |
| NÃO LOCALIZADO NO HISTÓRICO | 0 | Todos os itens foram achados no código ou nos documentos. O pedido de móveis curvos não está no histórico, mas o item foi classificado pelo código |

"Validado" aqui = bateria no Chromium e CI. Aparelho real e iPad: nenhum item.

## 5. Lacunas consolidadas (FATO, com fonte)
1. **VAO-3D-ABERTO (s23):** o 3D aberto não se atualiza ao trocar o vão por gavetas. Sem teste.
2. **I7 / s29 / s27 / s13:** catálogo por cima em parede cheia, encaixe da largura, folga do rack e posição digitada. Abertos (FASE2_SELECAO:100-105).
3. **TAMP-CAMINHO (P1-B):** vão de até 35 mm pelo campo digitado. Limite do `tbL`/`tlAdj`/`trAdj` digitado à espera de decisão.
4. **FITA-08:** porta do aéreo dentro da fita, só no 3D. À espera de decisão.
5. **Otimizador preso ao relógio** (:679, :700): o número de chapas pode variar com a máquina.
6. **Campos fora do `snapState`:** `pw`, `RDw`, `RDs`, `rodLast`, `deco`, `tvLogo`, `tvAnim`.
7. **↺ Voltar as peças apagadas** devolve todas de uma vez (:9732).
8. **Gestos não inventariados nem testados:** segurar, pinça com arrasto, caneta, conflito entre os 9 detectores de 2 toques.
9. **Medida interna útil** não aparece. Tamponamento superior com laterais descendo existe só em parte (superiores, "lateral inteira" + `tpMm`). Etapa 5 do PLANO_MESTRE na fila.
10. **Móveis curvos:** não existem.
11. **Teclado físico:** "1.200" vira 1,2 (risco, só leitura).
12. **Fora da candidata** (branches separadas, não auditadas aqui): item 6 (`wt-a6`), plano de corte (`wt-pc`), lateral do meio (`wt-li`), travessão (`wt-tv`), canto folha (`wt-cn`), fita do rebaixo e das portas no 3D (`wt-ft`, `wt-fp`).
13. **Testes que dependem de tempo** e falham com a máquina carregada: `testImaDoTopo…` (80 ms), `testMaoDeObra…` (intermitente no simulador iOS), `testFitaDaBase…` (seleção errada quando mira em cima da porta).

## 6. Testes da bateria por área
- **Método:** palavra-chave no nome do teste (script `$SP/auditoria/_cls.py`).
- Um teste pode cair em mais de uma área, então a soma passa de 357.
- **Lista completa por área:** `$SP/auditoria/_areas.md`.

| Área | Testes |
|---|---|
| Pedra e eletrodomésticos | 69 |
| Paredes, ambiente, pé-direito, teto | 66 |
| 3D (montagem, câmera, sincronia) | 63 |
| Portas (convencional, basculante, correr, vidro, dobradiça) | 58 |
| Divisões, prateleiras, vãos | 57 |
| Catálogo e controles ("nada de enfeite") | 44 |
| Tamponamentos e engrossos | 41 |
| Plano de corte, lista, fita, chapas | 40 |
| Seleção, toques e gestos | 37 |
| Exclusão, lixeira, peça apagada, desfazer | 32 |
| Painéis e ripado | 32 |
| Ímã, alinhamento, colisão | 32 |
| Laterais por fora, estrutura, fundo, base | 29 |
| Persistência (salvar, reabrir, backup, projeto antigo) | 27 |
| Medidas e precisão de digitação | 27 |
| Puxadores (cava, gola, perfil G, facetado) | 23 |
| Zoom e arrasto | 23 |
| Editor por vãos | 19 |
| Rodapé, saia, moldura, pés | 18 |
| Torres | 16 |
| Canto (L, cego) | 16 |
| Gavetas | 12 |
| Valores e orçamento | 12 |
| LED | 8 |
| Guarda-roupa / closet (no nome) | 6 |
| Desempenho | 3 |
| Móveis curvos | 0 (os 2 com "Curva" no nome são da dobradiça e da ponteira) |
| Sem área pelo nome | 10 |

### Áreas sem teste (ou só cobertas de lado)
- **Sem nenhum teste:**
  - Móveis curvos.
  - Gestos de pinça junto com arrasto, caneta e pressionar e segurar como gesto próprio. Só `testTocarOuSegurarOModulo…` toca em "segurar".
  - Trocar o vão com o 3D aberto (s23).
  - Número da metragem de fita de borda.
  - Número de chapas numa máquina lenta ou com o otimizador cortado pelo tempo. Nenhum teste usa `CUTDEEP`.
  - Medida interna útil e o texto `dimExtNote`.
  - Teclado físico com ponto de milhar.
  - Campos fora do `snapState` depois de reabrir.
- **Cobertura fina:**
  - Guarda-roupa e closet: 6 testes no nome; o resto vem dos testes por vãos e do catálogo.
  - Desempenho: 3 testes.
  - Gavetas: 12 testes.
  - Tamponamento superior com lateral descendo: só `ttInv` e `tpMm` de lado, sem teste próprio.

---

# 4 · Matriz entre plataformas e funções fora do editor 3D

Checkout lido: `$SP/wt-and` (HEAD 6b0e9cd, candidata Android a13c9e6 + docs). Só leitura. Nada foi alterado, compilado ou disparado.
`$SP` = `/tmp/claude-0/-home-user-Arqueiro-measure/ad5b8146-191a-5505-bec6-ea2769a57c73/scratchpad`.

## 0. Como cada plataforma é feita (fato)

- **Android:** `app/src/main/java/br/com/arque/measure/` + sabores `site` e `play` (`app/src/site|play/java/.../{data/AppUpdater.kt, license/StoreBilling.kt, update/UpdateWorker.kt}`). `TRIAL_DAYS` = 3 no site, 0 no Play (`app/build.gradle.kts:32,38`).
- **Windows:** `windows/src/main/kotlin/br/com/arque/measure/` é uma **cópia** do código Android com camada de compatibilidade (`windows/src/main/kotlin/android/**`, `androidx/**`). Comparação arquivo a arquivo:
  - idênticos: model/*, logic/*, sync/*, Json/Store/QuoteJson/AgendaJson, QuotePdf.kt, Export.kt, I18n, BoschProtocol.kt e a maior parte de ui/*;
  - diferentes: `ble/BoschBle.kt` (stub), `share/BtShare.kt` (stub), `agenda/AgendaReminders.kt`, `data/DataBackup.kt` (92 linhas), `ui/MoveisScreen.kt` (446), `ui/ShareUi.kt` (204), `license/License.kt` (só comentário), `AppViewModel.kt` (24);
  - só no Windows: `desktop/*` (Browser JCEF, Paths, Tour, Notifier), `data/AppUpdater.kt`, `license/StoreBilling.kt` (stub).
  - `BuildConfig.kt` do Windows: `PLAY=false`, `TRIAL_DAYS=3` (mesma regra e mesma senha do APK do site).
- **iOS:** código próprio em Swift (`ios/Arquemestre/**`). Mesmo `editor.html`, `i18n/*.json`, `cores/` (272 texturas) e `fotos/` (461) entram no pacote por `ios/project.yml:27-41`.
- **Editor:** o mesmo `app/src/main/assets/editor.html` nas três. Windows copia na compilação (`windows/build.gradle.kts`, tarefa `copySharedAssets`). Ponte `ArqueApp`: Android `addJavascriptInterface` (`ui/MoveisScreen.kt:177`), iOS script injetado (`ios/Arquemestre/UI/MoveisView.swift:128-160`), Windows chamadas síncronas `https://arque.app/__bridge/` (`desktop/Browser.kt`).

## 1. O que cada CI testa (fato, pelos arquivos `.github/workflows/`)

| Workflow | Quando roda | O que testa | O que NÃO testa |
|---|---|---|---|
| `android.yml` | push em `main`/`feature/**` (ignora `ios/**`, `windows/**`) ou manual | compila `assembleSiteDebug` + `compilePlayReleaseKotlin`; `testSiteDebugUnitTest` (19 classes JVM, `app/src/test`); `lintSiteDebug` | **nenhum teste instrumentado**; **a bateria do editor não roda no WebView Android**; sabor Play só compila (não testa); atualizador e instalação não testados |
| `ios.yml` | push `feature/**` com `ios/**` ou `editor.html`, ou manual | simulador iPhone: todos os testes **menos** `SubscriptionTests` (`-skip-testing`, linhas 57 e 81); iPad: mesma bateria (`test-without-building`), só se o iPhone passar; Release sem assinatura; capturas; passo StoreKit (`-only-testing:SubscriptionTests`) em iOS ≤ 26.2; `node ios/scripts/test-editor-media-backup.cjs` | aparelho real; TestFlight só com o input `testflight` |
| `windows-bateria.yml` | push `feature/**` em `editor.html`/`windows/**`/bateria, ou manual | `createDistributable` + bateria do editor (`tools/bateria_editor.py`, os mesmos testes de `EditorWebKitTests.swift`) dentro do app (JCEF) | **não roda os testes JVM** do Windows; não roda o tour; não testa o instalador Windows 7/8 (Chromium 109) |
| `windows.yml` | **só manual** | `gradle test` (JVM, 22 classes em `windows/src/test`); `packageExe/packageMsi`; instala o MSI e roda `windows/test/tour.py` (passeio pelo app instalado, `desktop/Tour.kt`) | bateria do editor; atualização por cima de versão antiga |

Evidências de execução (do CONTEXTO, não reconferidas aqui):
- Android CI 635 (a13c9e6): compilação + JVM (inclui `BackupCaminhoTest`) + lint passaram.
- iOS CI 616 (P0 790a990, **não é a candidata**): iPhone 373 testes, 0 falhas; iPad **não rodou**; `SubscriptionTests.test05_CancelarMantemAcessoAteOFimDoPeriodo` falhou por tempo esgotado e o passo StoreKit deu 11/11.
  - **Inconsistência a conferir no log:** o `ios.yml` atual pula `SubscriptionTests` no passo do simulador. Hipótese: a falha do test05 foi na 1ª tentativa do passo StoreKit e passou na repetição (`-retry-tests-on-failure`). Não verificado.
- Windows CI 46 (fc98cc5): 356/357 na bateria. Pelo número de testes é o `windows-bateria.yml`. **Não há evidência no CONTEXTO de que `windows.yml` (JVM + tour) rodou na candidata.**
- Bateria no Chromium de desktop (candidata): `$SP/band2.log` 357/357. Isso é Chromium de PC, **não** WebView Android.

## 2. Testes por plataforma (contagem de `@Test` / `func test`)

- Android (`app/src/test`): 19 classes. Exclusivas do Android: `QuotePdfTest` (3), `StoneFitTest` (4). `QuoteMathTest` tem 5 (o Windows tem 3: faltam os testes de aditivos e fotos no JSON).
- Windows (`windows/src/test`): 17 classes iguais às do Android (arquivos idênticos) + `SyncUiTest` (2), `desktop/DesktopCompatTest` (11), `desktop/CadernoDesempenhoTest` (2). `QuoteMathTest` desatualizado (3 de 5).
- iOS (`ios/ArquemestreTests`): `EditorWebKitTests` 357, `CoreTests` 39, `BackupSafetyTests` 13, `SubscriptionTests` 11, `CadernoTests` 9, `EditorAppPathTests` 4, `SyncInteropTests` 3, `EditorMediaWebKitTests` 2.

## 3. Matriz

Legenda: **I+T** = implementado e testado (teste e CI citados) · **I sem T** = implementado sem teste · **Ausente** · **Diferente**.
"Testado" só vale para a plataforma onde o teste rodou.

| Funcionalidade | Android | iOS | Windows | Evidência |
|---|---|---|---|---|
| Editor de móveis (mesmo `editor.html`) | **I, bateria só em proxy**: 357/357 no Chromium de PC (`band2.log`); nunca no WebView Android; nenhuma CI Android roda a bateria | **I+T** no iPhone (CI 616: 0 falhas, mas na branch P0, não na candidata); iPad **não rodou** | **I+T** (bateria CI 46: 356/357, falha `testTamponamentoNo2D…`, teste corrigido depois em a13c9e6; reexecução não registrada) | `EditorWebKitTests.swift`; `tools/bateria_editor.py`; `ios.yml`; `windows-bateria.yml` |
| Ponte `ArqueApp` (arquivos do projeto, notas, orçamento) | I sem T (nenhum teste JVM da ponte) | I+T (`EditorAppPathTests`: abre sem tela branca, textura, idiomas, "tudo sem erro") | I+T só em `windows.yml` manual (`DesktopCompatTest.ponteDoEditorDeMoveis`; tour "editor: arquivos pela ponte") | ver arquivos de ponte na seção 0 |
| Cadastro de clientes | I (no `editor.html`: `p.client`, `contactHtml`; agenda `ClientRef` em `model/Agenda.kt:43`) sem teste no Android | I+T (bateria: `testOrganizacao3DClienteEModoPessoa`, `testNadaDeEnfeiteTelaPrincipal3DClientesEValores`; `CoreTests.testProjetoRecebidoNaBiblioteca`) | I+T pela bateria (mesmos testes, CI 46) | não há cadastro nativo separado: o cliente vive no projeto do editor |
| Caderno de medição (notas, cotas, paredes) | I+T (lógica): `EditorStateTest` 17, `RoomTest` 15, `GeoTest` 7, `EraserTest` 5, `CabWallTest` 3, `StoreTest` 8; CI 635. Tela nativa sem teste | I+T: `CoreTests` (`testQuadradoVira4Paredes`, `testLeituraVaiParaACotaEAvanca`, `testPortaNoMeioDaParede`, `testLeNotaDoAndroidEGravaIgual`…), `CadernoTests` 9 (desempenho) | I+T só no `windows.yml` manual: mesmos testes JVM + `CadernoDesempenhoTest` 2 + tour "cria e abre nota", "exporta PDF/PNG/CSV". **Sem evidência de execução na candidata** | Windows usa o mesmo código Kotlin do Android |
| Fotos e anotações | I+T: `StoreTest."importar foto copia os bytes originais sem alterar"`; CI 635 | I+T: `CoreTests.testColarTracoDeslocadoESoltoDaFoto`, `CadernoTests.testFotoNaTelaUsaOTamanhoEmQueApareceEAMemoriaTemLimite`; vídeo do editor `EditorMediaWebKitTests` 2 | I+T só no manual: `DesktopCompatTest.matrizGiraAFoto`, `desenhoComTextoEFormas` | **Diferente:** só o iOS copia os vídeos do editor para arquivo nativo (`ios/Arquemestre/Resources/EditorMediaBackup.js`, `Data/EditorVideoBackup.swift`). No Android/Windows o vídeo fica só no IndexedDB `arque-photos` do WebView |
| Orçamentos e PDF | I+T: `QuoteMathTest` 5, `QuotePdfTest` 3; CI 635 | **Diferente** (código próprio `Render/Export.swift`) e I+T: `CoreTests.testOrcamentoSimples…`, `testOrcamentoCheio…`, `testFotosDoProjetoNoOrcamentoIgualAoAndroid`, `testLinhasDoEditorViramDetalhes…` | I (mesmo `QuotePdf.kt` sobre o shim `android/graphics/pdf/PdfDocument.kt`). Testes: `QuoteMathTest` 3 (faltam 2), **sem `QuotePdfTest`**; `DesktopCompatTest.pdfDaNotaEDoOrcamento`, `orcamentoNoLayoutNovoSoComDadosDoProjeto` (só manual) | PDF do iOS é outro desenho; a igualdade com o Android é conferida por teste iOS |
| Agenda e avisos | I+T: `HolidaysTest` 4 (feriados); lembretes `AlarmManager` sem teste | I+T: `CoreTests.testAgendaEOrcamento` + 4 de feriados; avisos `UNUserNotificationCenter` (`Agenda/Reminders.swift`) sem teste | **Diferente**: aviso só com o app aberto (ou ao abrir, até 12 h de atraso) — `agenda/AgendaReminders.kt:13-17`. Tour: "agenda salva", "aviso da agenda (notificação do Windows)" (só manual) | |
| Bibliotecas de materiais / preços | I (no editor: `prSave` grava `prices.json` pela ponte) | I | I | bateria: `testTelaValoresTodaFerragemQueEntraNoTotalTemLinhaNaTabela`, `testListaDeMoveisNoOrcamento` (iOS e Windows); Android só pelo proxy Chromium |
| Catálogos de MDF (Arauco, Duratex, Greenplac) e ferragens | I (assets `cores/`, `fotos/`) | I (mesmos assets, `project.yml:34-41`) | I (copiados de `app/src/main/assets`) | bateria: `testCatalogoComFotoDeCadaModuloEEletro`, `testFerragensFitaPorCorNichoNaCorDeForaEPaletaAmadeirada`, `EditorAppPathTests.testTexturaRealDoPadraoCarregaPeloEsquemaDoApp` (iOS). Android: sem execução no WebView |
| AQRender | **Ausente** | **Ausente** | **Ausente** | Só protótipo isolado: `prototipos/aqrender/LEIAME.md:1` ("Não está no app"), `tools/aqrender/*`. Nenhuma ocorrência em código nativo ou no `editor.html` |
| Backup e restauração | I+T: `StoreTest."backup e restauracao devolvem os mesmos dados"`, `"restauracao rejeita zip malicioso…"`, `BackupCaminhoTest` 2; CI 635. Cópia automática + cópia datada por dia **e por versão nova** (`data/DataBackup.kt:275-283`) | I+T: `BackupSafetyTests` 13, `CoreTests.testZipIdaEVolta`, `testRestauraBackupNoFormatoDoAndroid`. **Diferente:** uma cópia automática só (a cada 12 h, sobrescrita), sem cópias datadas (`Data/Backup.swift:123-138`) | I; testes `StoreTest`/`BackupCaminhoTest` iguais aos do Android + `DesktopCompatTest.backupCompletoERestauracao`, tour "backup completo (zip)" — **só no `windows.yml` manual**. **Diferente:** cópia datada só por dia; **não faz a cópia "antes de usar a versão N"** (`windows/.../data/DataBackup.kt:265`) | Sonda de restauração 6/6 (CONTEXTO) |
| Nomes com pontos consecutivos (`foto..jpg`) no backup | **I+T**: `BackupCaminhoTest.nomesComPontosSaoAceitos` e `travessiaRaizEUnidadeContinuamRecusadas`; CI 635 | **Diferente / erro provável:** `Data/Backup.swift:52` faz `e.name.contains("..")` → **pula em silêncio** o arquivo `foto..jpg` na restauração (não recusa o backup, mas perde o arquivo sem aviso). Sem teste | I (mesma correção, `DataBackup.kt:104-105`); teste existe, **sem execução registrada na candidata** | Mesma família: `SyncCore.safeName` recusa `..` em Android/Windows (`sync/SyncCore.kt:123`) e iOS (`Share/SyncCore.swift:118`) → foto com `..` no nome não passa na sincronização, sem aviso. Classificação: **risco identificado** (não reproduzido) |
| Licença / período gratuito | Site: 3 dias + senha do mês/vitalícia (`license/License.kt`). Teste só da senha: `LicenseTest.finalDaSenhaDoMes`, `senhaVitaliciaReconhecida`; **sem teste dos 3 dias, do relógio voltado nem do bloqueio**. Play: Billing 8 (`app/src/play/.../StoreBilling.kt`), **só compila, sem teste** | **Diferente** (StoreKit 2, `License/License.swift`). I+T: `SubscriptionTests` 11/11 no passo StoreKit (CI 616, branch P0); `CoreTests.testLicencaNaoVoltaComORelogio`. test05 instável (ver seção 1) | **Diferente do Play, igual ao site**: 3 dias + mesma senha (`BuildConfig.kt`, `License.kt` idêntico). Mesmo `LicenseTest` 2, só manual. `StoreBilling.kt` é stub | Licença não entra no backup no Android/Windows (`DataBackup.kt` `skip` de `shared_prefs/arque.lic.`) |
| Atualização sem perda de dados | Site: `AppUpdater.kt` lê `apk-latest/latest.txt`; cópia "antes de usar a versão N". Play: não se atualiza (loja). **Sem teste de atualização**; instalação por cima **não verificada em aparelho** (CONTEXTO). Compatibilidade de dados: 15/15 projetos da 1.0.632 iguais (sonda) | **Diferente**: só App Store/TestFlight, sem atualizador no app. Sem teste de atualização | `data/AppUpdater.kt` lê `win-latest/latest.txt`, baixa e abre o instalador; dados em `%LOCALAPPDATA%\Arque\Arquemestre` separados do programa (`desktop/Paths.kt`). Teste: só `DesktopCompatTest.numeroDaVersaoNoApp` (manual). Instalador Windows 7/8 (Chromium 109) **sem nenhum teste** | ponteiros de produção não foram tocados nesta auditoria |
| Medidor laser BLE (Bosch) | I: `ble/BoschBle.kt` real. Teste só do protocolo: `BoschProtocolTest` 8 (CI 635). Conexão BLE **sem teste e sem aparelho** | I: `BLE/BoschBLE.swift` (CoreBluetooth). Protocolo I+T: `CoreTests.testExtraiMetrosEConverteParaMm`, `testQuadroRealDaComunidade`, `testAutosyncHex`… | **Ausente**: `ble/BoschBle.kt:19-21` é stub ("ainda NÃO conecta"); estado sempre `UNAVAILABLE`. O `BoschProtocolTest` do Windows testa só o parser, não BLE | |
| Sincronização entre aparelhos (Wi-Fi, `/arq/*`) | I+T: `SyncTest.doisAparelhosComparamEPassamSemDuplicar` (CI 635). "Receber" e "Conectar" | **Diferente**: só **conecta** em quem está em "Receber" (`UI/SyncView.swift:3`, `Share/SyncCore.swift:254`); não recebe. iPhone↔iPhone por Wi-Fi não sincroniza. I+T: `SyncInteropTests` 3 (hash igual ao Kotlin) | I; `SyncTest` + `SyncUiTest` 2 (só manual) | mesmo protocolo nos três |
| Ver projeto ao vivo (compartilhar) | I: Bluetooth clássico (`share/BtShare.kt`), sem teste | **Diferente**: MultipeerConnectivity (`Share/PeerShare.swift`); não fala com Android | **Ausente**: `share/BtShare.kt` stub | iOS↔Android só por backup ZIP (comentário em `PeerShare.swift:6-8`) |

## 4. Diferenças reais de comportamento (fato, com arquivo)

1. **Restauração de `foto..jpg` no iOS:** `Data/Backup.swift:52` pula qualquer entrada com `..` no nome. O Android/Windows aceitam desde BKP-PONTOS. Um backup do Android com `foto..jpg` restaura no iPhone **sem esse arquivo e sem aviso**. Erro do mesmo mecanismo que foi corrigido no Android (seção 11 do CLAUDE.md: família não conferida no iOS). Não reproduzido: **risco identificado com evidência de código**.
2. **Sincronização com `..` no nome da foto:** `safeName` recusa `..` nas três (`sync/SyncCore.kt:123`, `Share/SyncCore.swift:118`). A foto é pulada no envio e no recebimento, sem aviso. Risco identificado.
3. **Trena Bosch:** só Android e iOS. No Windows é stub.
4. **Compartilhar ao vivo:** Android (Bluetooth clássico) e iOS (Multipeer) não se falam; no Windows não existe.
5. **Sincronização Wi-Fi:** o iOS não abre "Receber". Dois iPhones não sincronizam entre si por Wi-Fi.
6. **Avisos da agenda no Windows:** só com o app aberto; no celular o aviso vem com o app fechado.
7. **Cópias automáticas:** Android faz diária + "antes de usar a versão N"; Windows só diária; iOS só uma cópia a cada 12 h que é sobrescrita.
8. **Vídeos do editor:** só o iOS guarda em arquivo nativo. No Android/Windows ficam no IndexedDB do WebView (entram no ZIP via `app_webview`). O iOS, ao restaurar um ZIP do Android, só lê `files/` (`Backup.swift:55-56`): **vídeos do editor não passam do Android para o iPhone**. Hipótese razoável pelo código; não testado.
9. **PDF do orçamento:** iOS tem desenho próprio (`Export.swift`); Android e Windows usam o mesmo `QuotePdf.kt` (Windows por shim).
10. **Licença:** Android site e Windows = 3 dias + mesma senha; Play = Billing; iOS = StoreKit. Regras de cancelamento/reembolso/restauração só testadas no iOS.
11. **Atualização:** Android site e Windows se atualizam pelo próprio app (ponteiros `apk-latest`, `win-latest`); Play e iOS pela loja.

## 5. O que falta em cada plataforma

**Android**
- Nenhuma execução da bateria do editor no WebView Android (só no Chromium de PC). Nenhuma CI faz isso.
- Sem teste instrumentado de tela, ponte `ArqueApp`, BLE, Bluetooth de compartilhar, lembretes da agenda, atualizador ou instalação por cima.
- Licença: sem teste dos 3 dias, do relógio voltado e do bloqueio (o iOS tem). Sabor Play só compila; Billing sem teste.
- Atualização em aparelho real: **não verificada** (CONTEXTO).

**iOS**
- Candidata não rodou no iOS: as evidências são da branch P0 (616) e de branches de item (609–615). iPad **não rodou** em nenhuma.
- `Backup.swift:52` com `contains("..")` (item 4.1). Falta teste igual ao `BackupCaminhoTest`.
- `SubscriptionTests.test05` instável (tempo esgotado); conferir o log para saber em qual passo falhou.
- Sem "Receber" na sincronização; sem cópias datadas.

**Windows**
- Testes JVM, tour e instalador só rodam no `windows.yml` **manual**; **sem evidência** de execução na candidata. A CI 46 é só a bateria do editor (356/357; o teste que falhou foi corrigido depois, sem reexecução registrada).
- Faltam `QuotePdfTest`, `StoneFitTest` e 2 testes de `QuoteMathTest` (código idêntico ao Android, mas sem teste rodando no Windows).
- Trena BLE e compartilhar ao vivo ausentes.
- Instalador Windows 7/8 (Chromium 109) sem nenhum teste (nem bateria nem tour).
- Falta a cópia "antes de usar a versão N" que o Android faz.

**Todas**
- AQRender não está em nenhuma plataforma (só protótipo).
- Nenhum teste de atualização de versão antiga para nova com dados reais em nenhuma plataforma (só a sonda 15/15 de abrir projetos da 1.0.632 na candidata, no Chromium).

## 6. Classificação (padrão do CONTEXTO)

| Item | Classificação |
|---|---|
| Editor no Windows | IMPLEMENTADO E VALIDADO (bateria CI 46, com 1 falha de teste já corrigido e não reexecutado) |
| Editor no iOS (candidata) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (CI só da P0 e de itens; iPad não rodou) |
| Editor no Android (WebView) | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (só proxy Chromium) |
| Backup com `foto..jpg` Android | IMPLEMENTADO E VALIDADO (`BackupCaminhoTest`, CI 635) |
| Backup com `foto..jpg` Windows | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (teste existe, sem execução registrada) |
| Backup com `foto..jpg` iOS | PARCIALMENTE IMPLEMENTADO (restaura, mas pula o arquivo sem aviso) |
| Assinatura iOS | IMPLEMENTADO E VALIDADO no passo StoreKit (11/11, branch P0); test05 instável |
| Licença Android site / Windows | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (só 2 testes da senha) |
| Assinatura Play | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (só compila) |
| Atualizador Android site / Windows | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE |
| Trena BLE Android / iOS | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (só parser testado) |
| Trena BLE Windows | NÃO IMPLEMENTADO |
| Sincronização Android | IMPLEMENTADO E VALIDADO (`SyncTest`, CI 635) |
| Sincronização iOS | PARCIALMENTE IMPLEMENTADO (só conecta) |
| Sincronização Windows | IMPLEMENTADO SEM VALIDAÇÃO SUFICIENTE (testes só no manual) |
| AQRender | NÃO IMPLEMENTADO (protótipo fora do app) |
| Agenda Windows (avisos) | PARCIALMENTE IMPLEMENTADO (só com app aberto) |
