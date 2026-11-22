# Estrutura do Módulo (2D) — novas ferramentas

Pedido do Adauto (22/11/2026), feito pelo Claude Code 2 no ramo `feature/pecas-livres-2d`.
Seção nova "Estrutura do Módulo" no topo da aba Estrutura do módulo (antes de Dimensões).
Código: bloco `ESTRUTURA DO MÓDULO` no fim de `app/src/main/assets/editor.html` (objeto `window.EM`).

## Regras comuns
- Nada aqui mexe em outro móvel nem muda medida de fabricação sozinho (CLAUDE.md §4).
- Sólido: a conferência usa as caixas do próprio 3D (`__build()`/`__boxes()`), só as opacas e sem a pedra.
  Encostar (contato exato, tolerância 0,5 mm) pode; entrar não. Só conta o que **passou** a cruzar com a mudança
  (o que já se tocava antes não é desta mudança). Bloqueado → volta como estava e avisa em quê.
- Desfazer/refazer pelo `snap()` de sempre.

## 1. Afastamento da parede (ESTRUTURA-AFASTA)
- Campo "Afastamento da parede (cm)", padrão 0,0, aceita decimal (vírgula ou ponto) e conta da calculadora.
- Guardado em mm inteiro no módulo, no campo que já existia `m.zo` (lido por `zoOf` no 2D/planta, 3D, pedra e corte).
  Projeto antigo sem `m.zo` continua no padrão (Ajustes › `zoDef` / painel ripado atrás) — nada é gravado ao abrir.
- Vale nas paredes do fundo, esquerda e direita. Não aparece em módulo de canto nem em móvel livre (no meio da sala).
- Bloqueia se alguma peça do módulo passar a entrar em outra. Ex.: o rodapé/base corrida do 1º módulo passa embaixo do
  vizinho — afastar só o 1º faria a peça entrar no vizinho, então não deixa.
- O aviso antigo "Afastado da parede: N mm … Usar o padrão" virou este campo (o botão "Usar o padrão" continua).
- Teste: `testEstruturaAfastamentoDaParedeEmCmSemMudarMedidaENemEntrarNoVizinho`.
