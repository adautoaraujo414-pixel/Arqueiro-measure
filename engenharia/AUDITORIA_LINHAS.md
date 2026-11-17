# Auditoria das linhas do repositório (17/11/2026), só leitura

Nada foi alterado na `main`, nos ponteiros ou nas releases. Foi pedida pelo Adauto antes de consolidar o `CLAUDE.md` (seções 12 e 13) numa linha principal.

## 1. O que está publicado
| Plataforma | Versão | Commit | Como foi conferido |
|---|---|---|---|
| Android | apk-632 (ponteiro `apk-latest`) | `7c939bc` | tag `apk-632` |
| Windows | win-143 | `7c939bc` | tag `win-143` |
| iOS (TestFlight) | última conhecida | `97b6eef` | registro em `HISTORICO_ERROS.md`. **Não foi possível conferir no App Store Connect daqui.** `97b6eef` está dentro de `7c939bc` (63 commits antes). |
| Site (GitHub Pages, `docs/`) | — | — | **Não verificado** de qual branch a página é montada. |

As releases `teste-android-633` e `teste-windows-144` (`4aca2bb`, P0) são de teste e não são versão pública.

## 2. Base homologada mais recente
- **`7c939bc`**: código publicado (Android e Windows).
- **`8c0ce76`**: `7c939bc` + só documentos e testes (referências, decisões). É a base de todas as branches de trabalho de 17/11.

## 3. A `main` não é a linha de produção
- A `main` (`d82cdaf`, 09/11) e a linha publicada **não têm nenhum commit em comum**: são duas histórias separadas.
  - A linha publicada começa em `bdfb260` (`claude/arque-measure-kotlin`).
  - A `main` começa em `db7c7f1`.
- **Só a `main` tem:**
  - os fluxos da loja da Apple: `asc-enviar.yml`, `asc-capturas.yml` e `asc-diag.yml`;
  - os fluxos `gerar-apk.yml` e `ios.yml` antigo (30 min);
  - `docs/`, `app/` e `tests/` antigos.

  Ela não tem `ios/` nem `engenharia/`, e o `CLAUDE.md` não existe nela.
- **Só a linha publicada tem** o editor atual, a bateria do iOS, `engenharia/`, o `CLAUDE.md` e os fluxos `android.yml`, `windows.yml`, `windows-bateria.yml` e `ios.yml` (75 min).
- **Um push na `main` dispara o `android.yml` da `main`.**

## 4. Branches com trabalho ainda não integrado (todas a partir de `8c0ce76`)
| Branch | Último commit | O que tem | Situação |
|---|---|---|---|
| `claude/arquemestre-p0-parede` | `790a990` | P0 parede/pé-direito + correção do teste do tamponamento | aguardando iOS e autorização |
| `claude/arquemestre-fase3-precisao` | `e02faaf` | Fase 3 | aguardando iOS 609 |
| `claude/arquemestre-ajustes-3d` | `9d8727d` | item 6 | aguardando iOS 611 e Windows 45 |
| `claude/arquemestre-plano-corte` | `43114be` | plano de corte (toque longo, rodapé fora, peça branca) | iOS 612 |
| `claude/arquemestre-lateral-inteira` | `3991175` | lateral do meio | iOS 613 |
| `claude/arquemestre-travessao` | `a862927` | travessão (inclui a lateral inteira) | iOS 615 |
| `claude/arquemestre-canto-folha-lado` | `e1d79b3` | folha do lado do canto em L | iOS 614 |
| `claude/arquemestre-fita-rebaixo-3d` | `af0c55e` | fita dentro da travessa (3D) | bateria local |
| `claude/arquemestre-fita-portas-3d` | `1454596` | fita dentro da porta fechada (3D) | bateria local |
| `claude/arquemestre-protocolo-cirurgico` | esta | `CLAUDE.md` 12 e 13, estado, plano mestre, esta auditoria | só documentos |
| `claude/arquemestre-batente-cava` | `656e7f3` | proposta antiga | **não usar para mudar regra** (decisão do Adauto) |
| `claude/arquemestre-fase2-selecao` | `8b8b37b` | fase 2 (sem mudança no editor em relação à base) | conferir se ainda é necessária |
| `claude/arquemestre-engineering-audit-s3x5mc` | `ea4832d` | 2 commits fora da linha publicada: `aef2622` (sonda s31) e `ea4832d` (homologação da 9ec0869) | não integrados |

- **Conflitos no `CLAUDE.md`:** nenhuma branch de trabalho mexe no `CLAUDE.md`; só a do protocolo, e ela só **acrescenta** as seções 12 e 13 (nenhuma linha removida).
- **Possíveis conflitos no editor entre as branches:** P0, Fase 3, item 6, plano de corte, travessão e as duas da fita mexem no mesmo `editor.html`, em pontos diferentes. Ainda não foi feito teste de junção.

## 5. Recomendação (aguarda autorização)
1. **Não mexer na `main` agora.** Juntar histórias sem nada em comum (`--allow-unrelated-histories`) misturaria dois apps e os fluxos da loja da Apple, e o push dispararia o `android.yml`.
2. **Criar uma linha de integração a partir de `7c939bc`/`8c0ce76`** (proposta: `claude/arquemestre-integracao`).
3. **Levar para ela, nesta ordem:**
   1. o protocolo (`CLAUDE.md` 12 e 13 + documentos), que tem só acréscimos e nenhum conflito;
   2. cada branch **só depois de homologada**, com a bateria completa depois de cada junção.
4. **Publicações futuras** saem dessa linha, com o commit conferido, como hoje.
5. **A `main`, como fica a longo prazo, é decisão sua:**
   - **A)** manter como está, só com o site e os fluxos da loja;
   - **B)** trocar pela linha de integração, depois de mover os fluxos `asc-*` e conferir o site.

   A opção B exige o seu "sim" explícito, e exige conferir antes de qual branch o GitHub Pages monta o site.

## 6. Biblioteca de cantos: verificação (17/11), nada alterado
No catálogo da base `8c0ce76` (igual à versão publicada), os 8 modelos de canto da cozinha existem. Cada um entra sozinho no projeto, sem erro e com peças:

| Modelo | Tamanho (mm) | Peças |
|---|---|---|
| Canto em L (baixo) · esquerdo | 900 × 820 × 560 | 15 |
| Canto em L (baixo) · direito | 900 × 820 × 560 | 15 |
| Canto em L (aéreo) · esquerdo | 700 × 750 × 350 | 11 |
| Canto em L (aéreo) · direito | 700 × 750 × 350 | 11 |
| Balcão canto cego · cego na direita (porta na esquerda) | 1000 × 820 × 560 | 16 |
| Balcão canto cego · cego na esquerda (porta na direita) | 1000 × 820 × 560 | 16 |
| Aéreo canto cego · cego na direita | 900 × 750 × 350 | 9 |
| Aéreo canto cego · cego na esquerda | 900 × 750 × 350 | 9 |

Também existem os cantos do guarda-roupa:
- Canto L esquerdo e direito;
- Canto reto (CR) de 1 porta e de 2 portas, esquerdo e direito;
- os espaçadores de canto.

**Decisão do Adauto (17/11):** preservar. Nada de duplicar, recriar ou reorganizar sem necessidade.
