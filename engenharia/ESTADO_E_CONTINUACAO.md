# Estado do trabalho e como continuar (fim da sessão de 17/11/2026)

**Nada foi publicado.** Android 1.0.632 e Windows win-143 (commit `7c939bc`) continuam sendo as versões públicas. A `main` e os ponteiros de atualização não foram mexidos. Cada tarefa está numa branch própria, a partir de `8c0ce76`, salvo onde está indicado.

## Regras (ler antes de tudo)
- `CLAUDE.md`, seções 12 (engenharia cirúrgica) e 13 (desempenho). Estão na branch `claude/arquemestre-protocolo-cirurgico`, que ainda não está na linha principal.
- Gestos: 1 toque = exatamente o original. Não mudar sem autorização.
- **Bateria local:** `tools/bateria_editor.py --cdp … --url "http://127.0.0.1:PORTA/editor.html?lang=pt&v=<aleatório>"`. O `&v=` força o arquivo novo; sem ele, o navegador usa o `editor.html` antigo do cache e o resultado sai contaminado.
- **Antes de commitar teste Swift:** o JS entre `#"""` e `"""#` tem que ter pelo menos o recuo do `"""#`, senão o iOS não compila (CI 604).
- **iOS CI:** disparar pela **própria branch** (`ios.yml` da branch tem 75 min de etapa de testes), com `testflight: false`. O `ios.yml` da `main` corta em 30 min e não serve mais (CI 602 e 606 foram inconclusivas).
- **Antes de criar `window.algumaCoisa`:** procurar com `grep -n` se já existe (erro do `poAlign`, ver o HISTORICO da branch do item 6).

## Branches e situação
| Branch | Último commit | Situação |
|---|---|---|
| `claude/arquemestre-p0-parede` | `4aca2bb` | **Pronto para pedir autorização de publicação de emergência.** Ver o relatório do P0 abaixo. |
| `claude/arquemestre-fase3-precisao` | `e02faaf` | Bateria local 353/354 (a falha é antiga). Windows 353/354. **iOS pendente:** a CI 608 foi cancelada pelo GitHub. Disparar pela branch. |
| `claude/arquemestre-plano-corte` | `43114be` | Implementado (remoção por identidade, toque longo / clique direito, rodapé opção A, brancos juntos) + 3 testes. Windows 349/351 (falha antiga + teste ajustado). iOS não rodado. |
| `claude/arquemestre-lateral-inteira` | `3991175` | Lateral do meio junto das gavetas + aviso de profundidade + teste. Windows 348/349 (falha antiga). iOS não rodado. Pendente o Adauto confirmar a travessa em 2 peças e as 2 divisórias. |
| `claude/arquemestre-travessao` (sobre a lateral-inteira) | `a862927` | Travessão interno/externo, com ou sem Frontal + teste. Relacionados 67/68 (falha antiga). Windows 44 rodou (conferir). iOS não rodado. |
| `claude/arquemestre-canto-folha-lado` | `e1d79b3` | Folha do lado do canto em L (+1, cobre 5 mm, folga 4) + 4 expectativas atualizadas. Windows 347/348 (falha antiga). iOS não rodado. |
| `claude/arquemestre-ajustes-3d` (item 6) | `6aacd8a` | **Não homologado.** Feito: altura das laterais da gaveta, ajuste só da peça, 2 toques de longe + mover, colisões, sem estado preso. A opção A da porta piscando não foi mantida; o 1 toque da porta da parede está restaurado e com teste. Comparativa 107/109 (as 2 falhas são antigas). Faltam: telas (celular em pé ok; as outras rodando), iOS e Windows da branch. |
| `claude/arquemestre-protocolo-cirurgico` | este commit | CLAUDE.md seções 12 e 13, decisões, fila e este arquivo. |
| `claude/arquemestre-batente-cava` | — | **Não usar** para mudar regra (decisão do Adauto). |

## Falha antiga em todas as plataformas (não é de nenhuma tarefa)
- **`testTamponamentoNo2DMudaSoAAlturaDeleNaoMoveOMovelNemApagaABase`:** o passo 4 arrasta 90 **pixels** e espera b1410. O resultado depende da tela: Windows 560/590, iPhone 17 Pro Max 1450.
- **Proposta (não feita, precisa de autorização):** arrastar em milímetros pela escala. Mexe só no teste.
- **`testFitaDaBaseEmbaixoDaPortaPintaPeloToque`:** instável também na versão pública.

## Pendências e decisões em aberto do Adauto
1. Autorizar a publicação de emergência do P0 (relatório publicado como página).
2. Lateral inteira: travessa em 2 peças? 2 divisórias junto das gavetas?
3. Porta piscando nos 2 toques: medir no aparelho real antes de decidir.
4. Precisão com zoom: não reproduzida. Pedir um caso real (foto ou vídeo).
5. O 1 mm da travessa frontal no 3D (fita no rebaixo): só investigado; corrigir só com autorização.
6. iOS `janelaNaoDesceNoMeioDoToque` (`testMaoDeObra…`): intermitente, investigar.
7. CLAUDE.md seções 12 e 13: levar para a linha principal quando o Adauto autorizar.

## Fila (não iniciar sem ordem)
- Item 7 (estrutura paramétrica: moldura e frontal automáticos, salvar modelo, testes 3D = lista = corte).
- Tamponamentos editáveis e laterais descendentes (precisa do vídeo e das respostas).
- Biblioteca de cantos (precisa da imagem).
- Achar peça no plano de corte.
- Auditoria geral de exclusão e consistência.
