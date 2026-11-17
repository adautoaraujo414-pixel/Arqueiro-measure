# Fase 2, Prioridade 1: seleção de peças e vãos (diagnóstico e plano, nada implementado)

- **Branch:** `claude/arquemestre-fase2-selecao`, criada a partir de `9ec0869`.
- **Referência de retorno:** `9ec0869`, homologada pelo Adauto em 16/11 só para continuar o desenvolvimento (não autoriza publicar).
- **Testes que reproduzem:** os 5 abaixo foram acrescentados à bateria e **falham em `9ec0869`**.
- **Sondas:** `tools/sondas/s40`, `s41`.

## Erros comprovados

| Id | Erro | Como reproduz | Causa raiz | Onde |
|---|---|---|---|---|
| **SEL-DIV** | Arrastar a divisória de um módulo **não escolhido** muda a divisória do **escolhido** (A.div 0,5 → 0,876) | toque e arrasto reais na alça do B | O toque arma `drag={t:'d',i}` pelo **número** da divisória (`data-d`) sem conferir de qual módulo ela é. O arrasto aplica em `S.m.div[i]`. A camada da linha 12181 pega a alça mais perto do dedo **entre todos os módulos**, e o número `data-d` é por módulo | `editor.html` 1225 (`data-d`), 1226 (`data-s`, prateleira, mesmo padrão), 12181 |
| **SEL-PROJ** | Depois de tocar numa divisória no projeto A, abrir o B e tocar no 🗑 **apaga a divisória do B** | toque real em A, abrir B pela lista, 🗑 | `LAST`/`DIVI` (o que o 🗑 apaga) são globais e o `loadState` não os zera | lixeira 2247 (`LAST==='div'&&…DIVI`), `loadState` |
| **SEL-ESTADO** | Ao abrir outro projeto ficam do anterior: `LAST`, `DIVI`, `PSEL` (peça escolhida), `S.selS` (prateleira), `ST3ONLY` ("Só a pedra") | abrir B depois de mexer em A | escolha de tela guardada em variáveis globais e em `S`, sem limpeza ao trocar de projeto | `loadState` e as variáveis citadas |
| **SEL-VAO** | Tocar no módulo B pelo 3D deixa `S.sv=2` (o 3º vão do A) num B de 1 vão | `__sel3` real | O caminho do 3D troca `S.m` sem conferir `S.sv`. Os painéis corrigem ao abrir (`if(S.sv>=nv())S.sv=0`), então **nenhuma ação caiu no vão errado** nos testes: é risco (número inválido) | `sel3`/`itOpen` (3D) |
| **SEL-TORRE** | Tocar na **porta de cima** da torre de forno ou micro-ondas e escolher 1 ou 2 portas (aba Portas ou "1 porta" no menu do vão) faz **a torre inteira virar uma porta de 2100 mm**, e o forno, o micro-ondas e os nichos somem | 9 modelos × 3 caminhos = 27 erros (no diagnóstico de 16/11 saiu "10 modelos" por erro de contagem: são 9) | A torre é **um vão** `k:'oven'`. A porta de cima é calculada em `partsOf`. Os botões gerais (`data-door`, menu `door1`/`door2`/`slide`) trocam o tipo do vão inteiro. A estrutura certa já existe: torre por vãos (`v.tw`, botões `data-twd`, menu "Só este vão da torre") | tratador `data-door` (1699), menu do vão (`vmenuOpen`), igual ao já corrigido na geladeira (TORRE-GEL-PORTA) |

**Risco identificado (não comprovado):** `gv(i)` **cria vãos** no módulo quando `i` passa do número de vãos (`while(m.v.length<=i) m.v.push(...)`). Com `S.sv` inválido isso mudaria o projeto, mas nenhum caminho testado chegou lá.

## Plano de correção (correções pequenas, uma por commit, cada uma com o seu teste)
1. **SEL-DIV.** Toque em `data-d`/`data-s` de outro módulo só escolhe esse módulo, igual ao tamponamento (TAMP-2D-ALVO): `S.m`, `S.sv=0`, `LAST='mod'`, sem arrasto e sem `DIVI`. A camada 12181 passa a procurar a alça mais perto **só dentro do módulo escolhido**. Arrastar a divisória do módulo escolhido continua igual.
2. **SEL-PROJ e SEL-ESTADO.** O `loadState` de abertura de projeto (não o do desfazer) zera as escolhas de tela: `LAST='mod'`, `DIVI`, `PSEL`, `SEL3`, `S.selS`, `RPSEL`, `SELAP`, `ST3ONLY=0`, `FOC3`. Os dados do projeto não mudam. No desfazer/refazer, a escolha só é descartada se ficar inválida (índice que não existe mais).
3. **SEL-VAO.** Ao trocar de módulo por qualquer caminho, `S.sv` passa a ser um vão que existe (0 se não existir). É estado de tela, não dado do projeto.
4. **SEL-TORRE, precisa da sua decisão**, entre duas opções:
   - **A (recomendada, igual à geladeira já aprovada):** na torre de forno ou micro-ondas, os botões gerais "1/2/3/4 portas" e correr, e as opções "frente do vão inteiro" do menu, **não aparecem**. A porta de cima se troca pelos botões da torre por vãos que já existem ("Só este vão da torre"). Se ainda chegar um clique geral: em torre por vãos, age no vão de cima tocado; em torre antiga, é recusado com aviso. Não muda dado nenhum sozinho.
   - **B:** o botão geral converte a torre antiga em torre por vãos (a conversão que já existe, `conv`) e aplica no vão de cima tocado. **Isso muda a forma do módulo no projeto** (é uma migração por ação da pessoa) e precisa de aprovação.

   Nas duas, torre que já virou porta inteira num projeto antigo **não muda sozinha** ao abrir.

**Fora do escopo:** layout, regras de fabricação, peças e medidas.

## Testes (na bateria `EditorWebKitTests.swift`; falham em `9ec0869`)
- `testSelecaoDivisoriaDeOutroModuloSoEscolheEleENaoMexeEmNinguem`
- `testSelecaoLixeiraNaoUsaPecaEscolhidaNoOutroProjeto`
- `testSelecaoEscolhasDeTelaZeramAoAbrirOutroProjeto`
- `testSelecaoVaoEscolhidoExisteNoModuloEscolhidoDepoisDoToqueNo3D`
- `testSelecaoPortaDeCimaDaTorreMudaSoAPortaDeCima` (9 torres × 3 caminhos)

Depois de cada correção, também rodam a bateria completa e as sondas s01–s31, s40 e s41.

## Regra nova registrada (Adauto, 16/11): móveis do catálogo
**Um móvel novo não é redimensionado para caber.**
- Exemplo: guarda-roupa de 1800 mm onde cabem 1250 mm. Os 1800 ficam, e o app avisa a incompatibilidade de 550 mm.
- A pessoa escolhe outro móvel, outro lugar, ou autoriza o ajuste de medida.
- Hoje a criação ajusta a largura sozinha ("O módulo novo foi ajustado pra caber no espaço livre"; sonda s29: 17 casos).
- A correção fica para a etapa de **posicionamento** da Fase 2.

## Pendências registradas (próximas prioridades)
- "Só a pedra" passando entre projetos (entra no item 2 acima).
- Posição digitada deixando vão junto à parede (s13).
- Sobreposição de módulos do catálogo em parede cheia (s20 I7).
- 3D sem atualizar na hora ao trocar o vão por gavetas (s23).
- Folga do rack que não volta (s27).
- Módulo da parede lateral que anda ao alargar e não volta (s27).
- Travessa e moldura perdidas ao alternar `sup`/`rack` (s05).
- Teste antigo de tamponamento no 2D que depende do tamanho da tela (`testTamponamentoNo2D…`).
- Validação futura de peças flutuantes, interseções e consistência entre 2D, 3D e plano de corte.
- Inteligência estrutural: eletrodomésticos reais com medidas travadas, requisitos de instalação e movimento de abertura de cada modelo.

## Resultado da implementação (16/11, noite)
**Versão validada:** `9561fcd`, congelada (a bateria e todas as sondas rodaram nesse mesmo arquivo).

**Commits:**
| Commit | O que é |
|---|---|
| `d77ff63` | SEL-DIV |
| `7db71af` | SEL-PROJ/ESTADO |
| `d612d17` | ajuste de `S.selS` e vão válido |
| `7a95037` | SEL-VAO |
| `9561fcd` | SEL-TORRE, opção A |
| `e723744` | sondas s21/s22 abrindo como o app |

### Bateria
- **340 testes: 339 passaram e 1 falhou.** A falha é `testTamponamentoNo2D…` ("ergueu" b590 × b1410). Já falhava na linha de base e depende do tamanho da tela.
- **Testes da Fase 2 e onde falham antes:**

| Teste | Falha em `9ec0869` |
|---|---|
| Divisória de outro módulo | sim |
| Prateleira de outro módulo | sim |
| Lixeira em outro projeto | sim |
| Escolhas de tela ao abrir outro projeto | sim |
| Vão escolhido depois do toque no 3D | sim |
| Comandos gerais na torre (9 modelos × 3 caminhos) | sim |
| Caminho certo da torre, "Só este vão da torre" (9 modelos) | não: passa nas duas versões e fica como garantia de que o caminho certo continua funcionando |

- **Bateria completa de `d77ff63`:** 334 de 339. As 5 falhas eram a da linha de base e 4 testes de correções que ainda não existiam ali.
- **Regressão achada e corrigida no caminho:** `S.selS=-1` fazia o 2D perder o 1º toque (`d612d17`).

### Sondas em `9561fcd`
- **s09:** a divisória do B anda e a do A fica.
- **s14 ("Só a pedra"):** passar para outro projeto mostra os 922 itens de novo (antes, 0).
- **s21/s22:** nada do projeto A fica escolhido no B, e o 🗑 pede confirmação do módulo inteiro.
- **s40:** o vão escolhido é válido por todos os caminhos.
- **s41:** sem comando geral de porta nas torres.
- **s42:** pelo caminho do 3D, nenhum vão fantasma (antes, 1 → 3). O risco do `gv(5)` continua.
- **Iguais à homologação:**
  - s01, s02, s07, s08a/b, s10, s11, s12, s15, s24, s25, s26, s28, s30, s31;
  - backup JVM, 13/13.
- **Defeitos antigos que continuam iguais:**
  - s13 (posição digitada);
  - s20 I7 (sobreposição no catálogo);
  - s23 (vão → gavetas no 3D aberto);
  - s27 (folga do rack; módulo lateral ao alargar);
  - s29 (catálogo encaixa a largura do novo na parede cheia).

### Riscos que continuam
- `gv(i)` fora de divisórias + 1 ainda cria vãos. A mudança da função está para aprovação.
- **Balcão de forno, aba Portas:** os botões gerais trocam o vão do forno para porta (comportamento antigo, fora da opção A, que é só das torres). No menu do vão ele já vira "frente com recorte".
- Testado no Chromium. **Não testado em aparelho real nem no CI do iOS.**

## Homologação final de `9561fcd` (17/11, cópia congelada md5 c3a11255…)
- **Bateria:** 340 testes · 339 passaram · 1 falhou. A falha é `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase` (b590 × b1410), a mesma de antes: depende do tamanho da janela no Chromium sem tela e já falha igual no `9ec0869`.
- **Sondas, sem regressão:**
  - s01 · s02 · s07 · s08a/b · s11 · s12 · s15 · s28 · s30 · s40 · s42: iguais ao `9ec0869` ou melhores.
  - s09: arrasta só a divisória do módulo B; o A fica parado.
  - s14: 922 caixas no 3D depois de "Só a pedra"; a escolha não passa para outro projeto.
  - s21/s22: o projeto B fica limpo. A 🗑 no B pede confirmação de módulo inteiro, não apaga a divisória escolhida no A.
  - s31: 10/10.
  - s41: os comandos gerais escondidos nas 9 torres.
  - s24: sem vazamento (ouvintes 574 → 575, texturas e buffers iguais).
  - Backup JVM: BUILD SUCCESSFUL.
- **Defeitos anteriores, que continuam:**
  - s13: posição digitada perto da parede.
  - s20: I7 sobreposição no catálogo e I6 fora da parede.
  - s23: vão → gavetas atrasado no 3D.
  - s26: profundidade 3D de 567 contra 560.
  - s27: espessura do rack e largura do módulo 3 da demo.
  - s29: o catálogo encaixa a largura.
  - s21: `S.tab` passa de um projeto para outro. Já era assim antes da Fase 2; só muda a aba.
- **Não verificado:** aparelho real, CI do iOS, compilação completa Android/Windows (dl.google.com bloqueado).

## Aprovação (Adauto, 17/11)
- `9561fcd` aprovado tecnicamente: 339/340, sondas aprovadas, sem regressão nova.
- **Falha preexistente registrada:** `testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase` (b590 × b1410). Depende do tamanho da área de desenho no Chromium sem janela; falha igual em `9ec0869`. Continua na bateria sem mudança de expectativa.
- **Pendente em aparelho real:** iPhone/iPad, Android e Windows. Seleção e arrasto por toque, desfazer/refazer, portas das 9 torres, salvar, fechar e reabrir. CI do iOS e compilação completa Android/Windows também não rodaram aqui.
- Publicação: nenhuma.
