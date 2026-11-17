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
| 17/11/2026 | **Fila — auditoria geral de exclusão e consistência** (depois do P0, da Fase 3 e do item 6; branch própria):
- **Escopo:** todos os comandos de lixeira e exclusão (peça, lateral, base, fundo, divisória, prateleira, porta, gaveta, tamponamento, moldura, módulo, eletro, pedra, acessórios).
- **Conferir:**
  - apaga exatamente o item escolhido;
  - 2D, 3D, lista, corte e quantidades atualizados;
  - medidas recalculadas;
  - desfazer e refazer;
  - salvar e reabrir sem a peça reaparecer;
  - nada some só no visual continuando contado;
  - seleção não fica presa;
  - outro módulo não é afetado;
  - peça apagada não interfere em cálculo ou colisão;
  - aviso quando a exclusão compromete a estrutura;
  - sem recriar peça sozinho.
- **Gravidade:** P0 perda ou corrupção de projeto; P1 exclusão errada ou divergência de medidas e peças; P2 visual ou interação.
- **Procedimento:** primeiro auditar e reproduzir; corrigir só o comprovado, com teste. | Adauto | fila |
