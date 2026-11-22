# Proposta técnica — novo menu "＋ Criar" (6 categorias) e Espelhos · só engenharia, NADA implementado

Pedido do Adauto (22/11/2026). Claude Code 2, ramo `feature/pecas-livres-2d`. Implementação só com autorização do Adauto, depois da auditoria do
Claude Chefe. Sem merge, sem publicação, sem mexer na candidata. **A imagem de referência do menu não chegou a esta sessão** — o visual abaixo segue o
texto do pedido; precisa reenviar a imagem pra comparar antes de implementar.

## 1. Auditoria do menu atual (linhas do `editor.html`, ramo atual)
- Botão `#v3add` (L3653, abre/fecha em L4300) → painel `div#crp3` (`crpBox` L4284), montado por `crpRender` (L4292) **mais 12 embrulhos**
  que injetam HTML e tratadores próprios (L4551, 4969, 5085, 5180, 5356, 5502, 5583, 5619, 5701, 5706, 6330, 6716; `crpMore` L4541, também
  embrulhado em L5968 e L12433). Vários acham o lugar pelo **texto do título** da seção ou por um botão vizinho — mudar título ou ordem quebra calado.
- Seções e ferramentas de hoje (todas por `data-*`):
  módulos/eletros/mobília com lupa (`#crpq`, `data-ccat`); Módulos (`data-cmod`, `data-cnicho`); Ambiente (`data-camb2`, `data-cteto`, `data-cwed`,
  `data-cxw`, `data-cgeo`, `data-cplaca`, `data-ctamp`, `data-cpedra`, `data-cl`, `data-cwet`, `data-camb`, `data-cwl`); Portas e janelas
  (`data-cop` ×8); Panelas e louça (`data-cpan`, `data-cpanw`); Mobília (`data-cmob`); Ilha/península (`data-cadd`, `data-cdraw`, `data-csel`);
  LED (`data-clk`, `data-clc`, `data-cled`, `data-clon`, `data-cnight`, `data-corc`, botão `data-clbm`, `data-clbc`); Cozinha viva (`data-cfire`,
  `data-cpan="1"`, `data-cwat`); Sofás/Consultório (`data-csof`); Portas de vidro (`data-cvd`, repete `data-cop` de vidro); diagnóstico `data-dg3`.
- Testes que dependem do menu: `testEletroPelo3DComLupa…` (5 `data-ccat` e `#crpq` no `#crp3`), `testBotaoDoLEDUmSoOuUmPorModulo…`
  (3 `data-clbm` e 5 `data-clbc` visíveis ao abrir), `testIlhaComPedraParedesEOrcamento` (`#v3add` abre, `data-cadd="pen"`).
- **Defeito existente achado (não é desta tarefa — vai pro Code 1):** `data-cpan` é usado por 2 funções. Com cooktop na pedra, o botão
  "🍲 Panelas no cooktop" **adiciona um item decorativo** (`S.fr` +1) em vez de ligar as panelas, e a seção "Panelas e louça" some do menu
  (conferido rodando o editor).

## 2. Novo menu (sem tirar ferramenta)
- Primeira tela do `#crp3`: grade 2 colunas × 3 linhas, fundo escuro, 6 botões grandes arredondados, ícone centralizado e nome embaixo, ✕ fechar:
  **🪚 Móveis · 💡 LED · 🪞 Espelhos · 🪨 Pedras · 🧱 Paredes · ➕ Outros**. Responsivo (celular: botões ocupam a largura; tablet/Windows: largura fixa).
- Tocar numa categoria mostra só as ferramentas dela + "‹ Voltar". Abrir/trocar categoria **não refaz o 3D** (só mostra/esconde).
- **Como fazer sem quebrar nada**: um único embrulho novo, no fim da cadeia, que depois de todos os outros montarem o menu **re-agrupa os botões
  que já existem** (os mesmos elementos, com os mesmos `data-*` e tratadores) em 6 contêineres. Nada é reescrito; nenhum botão é apagado.
  Categorias escondidas por CSS (os botões continuam no DOM — os testes atuais acham `data-ccat`, `data-clbm`, `data-cadd` como hoje).
- Distribuição proposta (a confirmar com o Adauto):
  - **Móveis**: lupa + `data-ccat`, `data-cmod`, `data-cnicho`, `data-cadd`/`data-cdraw`/`data-csel` (ilha/península), `data-cmob`, `data-csof`.
  - **LED**: `data-clk`, `data-clc`, `data-cled`, `data-clon`, `data-cnight`, `data-corc`, `data-clbm`, `data-clbc` (+ futuras da PROPOSTA_LED).
  - **Espelhos**: ferramenta nova (abaixo).
  - **Pedras**: `data-cpedra`, `data-cl`, `data-cwet`, cooktop/cuba (atalhos que hoje estão no botão 🪨 Pedras).
  - **Paredes**: `data-camb2`, `data-cteto`, `data-cwed`, `data-cxw`, `data-camb`, `data-cwl`, portas e janelas `data-cop`/`data-cvd` (unificar a duplicata).
  - **Outros**: `data-cgeo`, `data-cplaca`, `data-ctamp`, panelas e louça `data-cpan*`, cozinha viva `data-cfire`/`data-cwat`, `data-dg3`.
- Teste novo: abrir/fechar, navegar nas 6, **nenhum `data-*` antigo some** (lista conferida contra a lista de hoje), sem reconstruir o 3D.

## 3. Espelhos
**Modelo de dados**: lista nova `S.esp = [ {id, forma:'quad'|'ret'|'red'|'oval'|'arco'|'org', w, h, esp:4, acab:'prata'|'bronze'|'fume',
borda:'lapidado'|'bisotado', moldura:null|{larg, cor}, rot (graus), host:{k:'parede', wall:'f'|'e'|'d'} | {k:'painel', rpid} |
{k:'vao', mi, vi} | {k:'mod', mi, face}, u, v (posição no plano do hospedeiro), recuo:{e,d,c,b}, ajusteVao:bool, led:null } ]`.
Mesmo padrão do `S.fr` (posição na parede, toque, painel `#it4`, trava, salvar) — sem criar outro editor nem outra seleção. Vinculado ao móvel/painel
pelo hospedeiro: o módulo anda e o espelho vai junto, sem mudar medida. `snapState`/`loadState` ganham `esp` (projeto antigo: lista vazia).
Política B: projeto com espelho ganha marcador de formato; pacote com espelho sai com tipo novo (versão antiga recusa em vez de abrir sem espelho).
- **Formatos com contorno de verdade**: quadrado/retangular (caixa); redondo, oval, arco: contorno por pontos (`arcPts`) extrudado na espessura com
  o `b.pf` que já existe (o preenchimento em leque serve pra formas convexas). **Ornamental/orgânico**: contorno côncavo precisa de triangulação de
  verdade (o leque atual faz defeito) — fase própria, com biblioteca de contornos (pontos em mm), sem imagem por cima de retângulo.
- **No vão**: tocar no vão → o app lê do próprio módulo a largura/altura livre e a profundidade da superfície (laterais, prateleiras, fundo, pelas caixas
  do 3D, como as peças livres) → "Ajustar ao vão" com recuos em mm. Não cria porta, divisória nem peça de MDF.
- **Edição** (toque no espelho → painel compacto): Mover, Tamanho, Girar (livre e 0/90/180/270), Acabamento, Duplicar, Excluir; arrastar; medidas em mm;
  centralizar; alinhar às bordas; distância do chão/teto/laterais; desfazer/refazer pelo histórico do projeto.
- **Acabamentos**: prata, bronze, fumê; borda lapidada ou bisotada; com ou sem moldura; espessura e preço configuráveis. Aviso quando o acabamento não
  combina com a forma (ex.: bisotê em contorno orgânico).
- **3D**: opaco (a=1), cinza-azulado claro com o realce falso do vidro que já existe (`t=9`, faixa de brilho) — **sem reflexo em tempo real** (custaria
  ~2× no celular). Sólido: não atravessa MDF (mesma conferência das peças livres), não mexe em outro móvel. Toque: o espelho precisa ganhar do painel/
  parede atrás (regra de profundidade no `pickItem`, L4450).
- **Espelho com LED (futuro)**: campo `led` reaproveitando o LED existente (atrás, bordas, perfil lateral; cor; ligar/desligar) — sem outro motor.

## 4. Fabricação e orçamento (separado do MDF)
Lista própria de vidraçaria: quantidade, forma, largura, altura, espessura, **área em m² pela geometria real** (polígono do contorno, não o retângulo),
perímetro (lapidação/bisotê por metro), acabamento, valor por m², serviços (furos, moldura, instalação). Não entra no plano de corte da marcenaria.
Contorno guardado em pontos (mm) pra futura exportação de corte de vidro — DXF não muda agora. Preços no catálogo (`PR.cat` novo item "Espelho m²" por
acabamento, migrado sem apagar o catálogo do usuário).

## 5. Riscos
- Cadeia de 12 embrulhos do menu que se acham pelo texto → re-agrupar no fim, sem renomear seções antes do re-agrupamento.
- Testes que esperam os botões visíveis ao abrir → categoria de LED/Móveis precisam continuar "achaveis"; se o Adauto quiser a grade como 1ª tela,
  2 testes mudam de expectativa (com o comentário do pedido).
- Transparência sem ordenação no 3D → espelho opaco.
- Toque disputado com painel/parede, 2 toques de mover e segurar do LED.
- Contorno orgânico côncavo exige triangulação nova.
- Desempenho: cada ação refaz o 3D inteiro; contornos com poucos segmentos (8–24).

## 6. Sequência recomendada (cada uma com testes que falham antes; bateria completa e CI no fim)
1. Corrigir antes (Code 1): conflito do `data-cpan`.
2. Menu em 6 categorias por re-agrupamento (sem ferramenta nova) + teste "nenhuma ferramenta some".
3. Espelho retangular/quadrado em parede e painel (modelo `S.esp`, toque, painel, salvar, Política B).
4. Espelho no vão ("Ajustar ao vão", recuos) e vinculado ao móvel.
5. Redondo, oval, arco (contorno por pontos).
6. Acabamentos, moldura, lista de vidraçaria e orçamento por área real.
7. Ornamental/orgânico (triangulação + biblioteca de contornos).
8. Espelho com LED (depois da fase de LED aprovada).
9. Homologação iOS/Android/Windows + atualização por cima.

## 7. Perguntas ao Adauto
1. Reenviar a imagem do menu.
2. A distribuição das ferramentas nas 6 categorias (§2) está certa?
3. Quais contornos ornamentais entram primeiro (tem desenho/medida)?
4. Preço por m² por acabamento e serviços (lapidação/bisotê por metro?).
5. Espelho com moldura: moldura de quê (MDF? alumínio?) e conta no orçamento como?
