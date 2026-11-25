# Paredes — etapas A a F (aberturas, meia parede/balcão, remover/restaurar) · 23/11/2026, Claude Code 2

Aprovação: Adauto 22/11 18:12 (regras definitivas) e 23/11 ("Faça todos não deixe nada pra trás"). Proposta: `PROPOSTA_ABERTURA_PAREDES.md`.
Ramo `claude/fecha-pendencias` (sobre a candidata `5bd11f5`). Um commit e um teste por etapa.

| Etapa | O que faz | Commit | Teste |
|---|---|---|---|
| A | Abertura retangular (`S.ops` `t:'abertura'`: x, w, b = peitoril, h ou `teto`) no fundo e nas laterais; o 3D recorta com o peitoril de pé (também corrige vão com "do chão" > 0); 2D, Planta | `6df3e3e` | `testParedesEtapaAAberturaComPeitorilNoFundoENasLaterais` |
| B | Meia parede com altura editável (`S.wall[s].mh`, padrão 1100) e espessura (já editável, padrão 150); "↔ Parede inteira" (balcão de ponta a ponta, também no fundo) | `bd07280` | `testParedesEtapaBMeiaParedeComAlturaEEspessuraEditaveisEAberturaNaParedeToda` |
| C | Remover/restaurar fundo (`S.wall.F.rm`, linha fica como referência) e laterais (`tp:'sem'`); portas/janelas guardadas em `S.wall[s].hops` e devolvidas iguais; aviso dos módulos sem parede atrás; nenhum móvel muda | `ab9d030` | `testParedesEtapaCRemoverERestaurarFundoELateraisSemMexerNosMoveis` |
| D | Menu EDITAR PAREDE no quadro da parede do 3D (abertura, meia parede/balcão, remover, restaurar) | `076a1cd` | `testParedesEtapaDMenuEditarParedeNo3D` |
| E | "Soltar sem mexer": módulo da parede do fundo removida vira móvel livre no mesmo lugar (pegada do 3D conferida ±1 mm), com confirmação | `49bbf97` | `testParedesEtapaESoltarSemMexerNoMesmoLugar` |
| F | Compatibilidade com o app publicado (abaixo) | este doc | medição no `c561120` |

## F — compatibilidade com o app publicado (`c561120`, medido 23/11 no Chromium)
Projeto do app novo com abertura (`t:'abertura'`), fundo removido com porta guardada (`S.wall.F.rm`, `hops`), lateral removida com janela guardada e
meia parede de 900 (`mh`), aberto no editor publicado:
- **abre sem erro**, 3D monta;
- **salvar de novo no app publicado não perde nada**: `ops` (abertura e porta), `S.wall.F.rm`/`hops`, `S.wall.L.hops`, `S.wall.R.mh` voltam iguais
  (o `S.wall` é salvo inteiro e o `S.ops` também);
- o que o app publicado **não sabe mostrar**: a abertura aparece como "Porta" no 2D (no 3D não recorta), o fundo removido aparece como parede, a meia
  parede fica com 1100. Abrindo de novo no app novo, tudo volta como estava.
- **Decisão:** manter a abertura no `S.ops` (sem campo escondido como o `frx` do espelho), porque assim um projeto salvo no app antigo **não perde** a
  abertura; o custo é só o desenho errado no app antigo. Projeto antigo (sem os campos) abre igual no app novo (bateria inteira).

## Limites conhecidos
- Módulo da parede do lado não tem "Soltar sem mexer" (o móvel livre só gira; ficaria espelhado). Continua vinculado e no lugar, como a regra permite.
- Acabamento superior do balcão (pedra/MDF como peça independente, regra 5): usar a pedra (aba Pedra) e as peças livres 15 mm já existentes; elemento
  "acabamento" próprio da parede ainda não criado — próximo passo se o Adauto quiser o atalho.
