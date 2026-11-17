# Decisões técnicas aprovadas

Só entra aqui o que o Adauto aprovou. Sugestões ficam em `PLANO_EVOLUCAO.md`.

| Data | Decisão | Quem aprovou | Onde |
|---|---|---|---|
| 16/11/2026 01:26 | Perfil G: abertura dos dedos para a frente, parede de 42 atrás abraçando 13, sem placa escura. Vale no gola vertical e no do editor por vãos | Adauto | `especificacoes/puxador-gola.md` |
| 16/11/2026 01:26 | Não criar "gola estrutural" (perfil preso na caixa) | Adauto | idem |
| 16/11/2026 01:28 | Documentação interna fora do site público. Fica em `engenharia/`, não em `docs/` | Adauto ("sem expor informações internas no site público") | `CLAUDE.md` |
| 16/11/2026 | Motor 3D: só auditoria e proposta. Nada estrutural sem aprovação | Adauto | `MOTOR_3D_AUDITORIA.md` |
| Novembro de 2026 | Publicar (TestFlight, lojas, APK do site, Windows) só com autorização expressa para aquela versão | Adauto | `CLAUDE.md` |
| Novembro de 2026 | iOS, Android e Windows com as mesmas funções | Adauto | `CLAUDE.md` |
| 16/11/2026 (noite) | **O Arquemestre avisa quando existir incompatibilidade geométrica, mas nunca altera automaticamente as medidas ou posições de fabricação definidas pelo usuário.** Ambiente não modifica móveis. O software identifica o problema e quem decide alterar o móvel é o profissional | Adauto | `editor.html` (guarda GEO-AVISA), `HISTORICO_ERROS.md` |
| 16/11/2026 (noite) | Correções P0 autorizadas: arquivo vazio não apaga cópia boa, restauração de backup segura, engrosso preservado | Adauto | `HISTORICO_ERROS.md` |
| 16/11/2026 (noite) | Versão `9ec0869` homologada como referência estável da Fase 1, só para continuar o desenvolvimento (não autoriza publicar). Fase 2 na branch `claude/arquemestre-fase2-selecao` | Adauto | `engenharia/FASE2_SELECAO.md` |
| 16/11/2026 (noite) | **Móvel novo do catálogo não é redimensionado para caber.** Preserva a medida do catálogo e avisa a incompatibilidade. A pessoa escolhe outro móvel, outro lugar ou autoriza o ajuste (correção na etapa de posicionamento da Fase 2) | Adauto | `engenharia/FASE2_SELECAO.md` |
| 17/11/2026 | **Travessão (aprovado sobre o esquema de montagens):**
- Só as opções **Interno** e **Externo**. O **Embutido** continua sendo o **Frontal**, peça independente.
- **Interno:** a lateral central vai até o topo e serve de apoio. As réguas se dividem nos encontros, cada pedaço calculado pela largura útil real, pela posição da divisória e pela espessura (sem 427 fixo).
- **Frontal e Travessão podem ficar juntos:** a régua da frente recua 15 mm, para trás do Frontal, desde que o encaixe seja válido. Se não for, o app mostra o conflito e não gera peça sobreposta.
- A altura externa é preservada; 2D, 3D e corte vêm da mesma fonte. | Adauto | branch `claude/arquemestre-travessao` |
