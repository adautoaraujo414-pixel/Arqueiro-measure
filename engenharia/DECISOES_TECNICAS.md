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
| 17/11/2026 | **Protocolo de engenharia cirúrgica (permanente):**
- Fazer só o que foi pedido, auditando antes o que já existe e funciona.
- **Não mudar sem autorização:**
  - 1 toque;
  - abrir/fechar portas e gavetas;
  - seleção e edição existentes;
  - câmera, zoom e navegação;
  - geometria;
  - MDF, folgas e descontos;
  - ferragens;
  - plano de corte;
  - salvar e restaurar;
  - layout, botões e menus.
- **Conflito:** parar e apresentar causa, alternativas e impacto. Não escolher sozinho.
- **Toques:** 1 toque = exatamente como antes. 2 toques com a câmera perto = peça individual (medidas de 1 em 1 mm, com vínculos). 2 toques com a câmera afastada = módulo inteiro, e 2 toques em outro lugar válido movem (inclusive para outra parede). 3 toques perto do módulo = dimensionamento geral, sem mudar medida antes de confirmar.
- **Peças estruturais** (lateral, base, divisória) não se soltam do módulo.
- **Relatório** de cada tarefa: solicitação, o que já existia, alteração, arquivos, testes, regressões, status, publicação. | Adauto | todas as tarefas |
