# Relatório da madrugada de 16/11/2026 (Adauto ausente)

Escopo autorizado:
- Corrigir só o gola.
- Auditoria só de leitura.
- Diagnóstico do motor 3D e proposta.
- Plano de evolução.
- Documentação.

Nada foi publicado. Nenhum dado real foi alterado.

## 1. O que foi corrigido
**GOLA-001: perfil G espelhado.** Aprovado às 01:26.
- **Antes:** parede de 42 na frente, abertura dos dedos para dentro do móvel e uma placa escura fechando o vão.
- **Agora:** abertura para a frente, parede de 42 atrás abraçando 13 mm da face de dentro, sem placa. É igual à referência de 12/11 às 01:30.
- **Onde vale:** porta, gaveta, aéreo (perfil embaixo), gola vertical da porta comum e gola lateral do editor por vãos.
- **Não mudou:** desconto de 29, medidas das portas e frentes, metros de perfil, lista de materiais, plano de corte, salvar e reabrir, e os outros puxadores (cava, cava de perfil, facetado, concha, barra, porta de correr).
- **Arquivo:** `app/src/main/assets/editor.html`. Mudaram só o bloco `t==='g'` de `pxParts` e a função `G_` do gola lateral.
- **Evidência:**
  - Seção desenhada com as caixas reais do 3D, antes e depois, ao lado da referência.
  - 6 vistas antes e depois: frente, por trás, lateral, ponta, porta aberta e gola vertical.
  - As imagens foram mandadas na conversa.

## 2. Testes
- **Teste novo:** `testPerfilGolaAberturaPraFrenteParedeDe42AtrasSemPlacaEmPortaGavetaAereoEGolaVertical`.
  - Na versão corrigida: 5 peças, 1 cor, parede atrás de 42 (43 no vertical), maior peça da frente 8 e fundo 18, em todos os casos.
  - Na versão anterior o mesmo teste falha: `pecas 6 · cores 2 · parede atrás 0 · frente maior 42`.
- **Expectativas atualizadas** (de 12 para 10 peças, porque a placa saiu, com o motivo no comentário):
  - `golaPerfil` e `golaAbre` (gola lateral).
  - `b3` (gola vertical).
- **Bateria completa (harness Chromium):** ver a seção 8.
- **iPhone de verdade:** **não testado.**

## 3. O que foi investigado (só leitura)
- Histórico de referências do gola: as 435 imagens da conversa vistas em miniatura. Ver `REFERENCIAS.md`.
- Motor 3D: ver `MOTOR_3D_AUDITORIA.md`.
  - WebGL 1 próprio, 1 shader, luz fixa por face, metal sem reflexo, vidro sem ordenação.
  - Refaz a cena inteira a cada mudança.
- Arquitetura: ver `ARQUITETURA.md`.
  - Editor de um arquivo só.
  - As regras ficam em camadas de embrulhos (`partsOf` 18 vezes, `draw` 41, `panel` 43).
- Gravação de projetos (parcial): `localStorage` + `projects.json` + cópia do arquivo corrompido.

## 4. Erros anteriores identificados
Ver `HISTORICO_ERROS.md`. Os principais:
- **WEBGL-001 (novo, estabilidade):** se o sistema tirar o contexto gráfico (app no fundo ou falta de memória), o 3D fica apagado até reabrir o app. O app não trata esse caso. Reproduzido no Chromium.
- **3D-045:** módulo do 2D que não aparece no 3D no iPhone. Está mitigado, sem causa raiz. Os prints mostram paredes e pedra, então não é perda de contexto.
- **CI do iOS vermelho desde o commit e3d68b8:** o teste `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa` (criado para o PEDIDO 45) espera 1 erro. No WebKit, o erro de teste é anotado 2 vezes ("(peças)" e o geral), porque a pilha de chamadas do JavaScript do Safari é diferente da do Chrome.
  - O comportamento do app está certo: fica a caixa do módulo, os outros aparecem e o aviso sai.
  - **Quem errou foi o teste.** Não mexi nele (fora do escopo autorizado). Proposta: aceitar a contagem das duas engines.

## 5. Pendências que precisam de decisão sua
1. **Perfil G encostando na caixa:** a parede de trás tem 1,5 mm. No 3D ela entra até 1,5 mm na travessa, nas laterais, na base e na caixa da gaveta. Antes da correção já entrava, em área menor. A porta deve ficar 1,5 mm afastada, ou a caixa ganha um rebaixo?
2. **"Sobra malfeita":** era a ponta fechada (tubo com a placa)? Agora a ponta mostra o "C" aberto. Confirme olhando as imagens.
3. Detalhes da referência que não mudei, porque não têm cota ou mexem em outras coisas:
   - Cantos arredondados.
   - Gancho com uns 6 mm em vez de 8.
   - Encaixe de 15,5.
   - Desenho genérico de Ajustes.
   - Porta de correr.
4. **WEBGL-001:** autorizar a correção (baixo risco).
5. **Teste do PEDIDO 45 no iOS:** autorizar o ajuste.
6. **Pedidos 61 e 62** (faixa da parede minimiza; 2 toques no vão do editor por vãos): estão prontos na branch `wip/pedidos-61-62` (commit cbbe30f), **fora** da branch principal. Testados no simulador, falta a bateria completa. Esperam seu ok para entrar.
7. **Repositório público:** o GitHub `Arqueiro-measure` é público. `CLAUDE.md` e `engenharia/` ficam visíveis no GitHub, mas não no site. Por isso não escrevi nada sensível ali. Para ser privado mesmo, o repositório teria que ser privado (o site do link do cliente depende dele) ou a documentação teria que ir para outro repositório privado.
8. **Fase 2 do motor 3D:** escolher os itens da proposta (`MOTOR_3D_AUDITORIA.md`, seção 5).
9. **Plano de evolução:** escolher prioridades (`PLANO_EVOLUCAO.md`).

## 6. Melhorias visuais recomendadas (não feitas)
- Luz com normais (profundidade em rebaixos e no canal do gola).
- Metal com brilho e reflexo por acabamento.
- Vidro com Fresnel e ordenação.
- Não refazer a cena inteira quando uma foto de padrão carrega.
- Liberar texturas sem uso.
- Detalhes em `MOTOR_3D_AUDITORIA.md`.

## 7. Arquivos e commits
- `app/src/main/assets/editor.html`: correção do gola.
- `ios/ArquemestreTests/EditorWebKitTests.swift`: teste novo e 3 expectativas.
- `.github/novidades.txt`: uma linha do gola.
- `CLAUDE.md` (novo).
- `engenharia/` (novo): ARQUITETURA, HISTORICO_ERROS, REGRAS_MARCENARIA, GESTOS_CONTROLES, DECISOES_TECNICAS, REFERENCIAS, MOTOR_3D_AUDITORIA, PLANO_EVOLUCAO, `especificacoes/puxador-gola.md` e este relatório.
- Branch `wip/pedidos-61-62`: trabalho anterior (pedidos 61 e 62) guardado à parte.

## 8. Resultado da bateria
**Bateria completa no harness Chromium, com a correção do gola** (commit fcfcf28): 296 execuções em 35 minutos.

**O que passou:**
- O teste novo do gola.
- As 3 expectativas atualizadas: `golaPerfil "10 true false"`, `golaAbre "10 true"` e `b3 10`.
- `testPuxadoresDescontamCertoEConchaNoMeio`, com desconto de 29.
- `testPortasNaoEntramEmNada…`.
- `testBateriaGeralCatalogoNo3DEPedraNaoEntraEmNada`.

**Falhas conhecidas e aceitas** (iguais na versão anterior):
- `onl`
- `pinkR`
- `depois`

**Falha só com carga:**
- `testOrganizacao3DClienteEModoPessoa` (`clv`, `ro`): rodando sozinho, deu `clv: true, ro: true`.

**Para revisar:**
- `quarto`: o resultado novo é o que o teste espera (`"quarto true true"`). A diferença é da versão antiga de comparação.

**Nenhuma regressão nova.**

**Bateria da versão anterior (e3d68b8, antes do gola):**
- As mesmas falhas conhecidas.
- `testSoOModulo3DE2D…`, que só falha com carga (sozinho passa igual à versão antiga).

**CI do iOS (simulador iPhone, WebKit de verdade), commit fcfcf28 (run 43822406584): 366 testes, 5 asserções falhando.**

O que **passou** no WebKit:
- `testPerfilGolaAberturaPraFrente…` (teste novo do gola).
- `testGolaVerticalEHorizontalEDesenhoDeCadaPuxador`.
- `testPortasNaoEntramEmNada…`, com `golaPerfil 10`.
- `testPuxadoresDescontamCertoEConchaNoMeio`.
- Todos os outros testes de puxador.

O que **falhou**:
1. `testErroNoMontarUmModuloNo3DNaoSomeComTodosFicaACaixaEAvisa`: o mesmo problema do teste já descrito na seção 4. Já falhava antes do gola.
2. `testArmarioDeCantoFolgaDe3mmEntreAsFolhasAbreUmaDepoisAOutra`: no WebKit, o canto L do guarda-roupa, lado esquerdo, deu `abertas 90/67` em vez de `90/70`.
   - No Chromium, antes e depois do gola, dá `90/70`.
   - Esse teste mede a porta abrindo com espera de 150 ms. **Hipótese** (não comprovada): a animação ainda não tinha terminado no simulador lento.
   - A correção do gola não mexe em porta de canto, nem no ângulo, nem na colisão das folhas. Conferido: as portas do "Canto L guarda-roupa" do catálogo não têm gola (`gola 0`, puxador padrão).
   - Não deu para confirmar se é instável: os commits seguintes só mudaram documentação e o CI do iOS não rodou de novo. Fica pendente rodar o CI do iOS outra vez.

**Aparelho real:** não testado.
