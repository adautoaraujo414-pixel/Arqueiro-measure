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
| 17/11/2026 | **P0 da parede e do pé-direito autorizado:** mudar parede ou pé-direito nunca esmaga, redimensiona nem desloca móveis, pedra ou cuba. Só avisa, e o aviso tem que ser verdadeiro | Adauto | `HISTORICO_ERROS.md` (P0-PAREDE), branch `claude/arquemestre-p0-parede` |
| 17/11/2026 | **Fase 3 (precisão):** o 1º toque num módulo não escolhido só escolhe, nunca move. 2 toques abrem a edição sem mover e sem fechar o vão. A área de toque da divisória fica na própria divisória, em qualquer zoom. Medida inválida é recusada com aviso, sem arredondar nem corrigir calado. Menus na mesma ordem em todos os módulos. Azul de seleção mais suave, sem perder a identificação | Adauto | `FASE3_PRECISAO.md` |
| 17/11/2026 | **Batente cava:** as frentes continuam por fora do vão, alinhadas às portas (cobrem 15 da base, 15 de cima e a travessa). A lógica atual de descontos fica como está | Adauto | `PROPOSTA_BATENTE_CAVA.md` |
| 17/11/2026 | **Profundidades diferentes entre módulos vizinhos:** só avisar. Nunca corrigir, reposicionar nem redimensionar sozinho | Adauto | (a implementar) |
| 17/11/2026 | **Lateral da gaveta:** 460 mm continua como padrão, respeitando o espaço útil (módulo raso fica com o que cabe). As outras regras de gaveta não mudam | Adauto | `gavRegra` |
| 17/11/2026 | **Lateral inteira no armário inferior de cozinha com gaveta:** a divisória encostada no vão de gavetas vira lateral inteira, igual às outras laterais do projeto (altura, profundidade e o mesmo rebaixo em cima). Base e travessas ficam em duas peças, uma de cada lado. Vale para módulo novo. No módulo que já existe, avisa e a pessoa decide converter. Guarda-roupa não muda (lá a divisória está certa) | Adauto | (a implementar) |
| 17/11/2026 | **Plano de corte:** qualquer branco fica junto (cor de fora branca e caixa branca nas mesmas chapas). Remover peça só do corte segurando 1,5 s (ou clique direito no Windows), com id estável por peça e por módulo, reaproveitando `S.cutOff`. Rodapé fora do corte, opção A: o rodapé corrido se divide no corte e o 2D/3D não muda | Adauto | (a implementar) |
| 17/11/2026 | **Altura da lateral das gavetas no 3D:** 2 toques na lateral abrem o ajuste, em passos de 1 mm. Todas as laterais das gavetas da mesma divisão acompanham; outros vãos e módulos não mudam. Comprimento de 460 e corrediça de 450 ficam como estão. 3D, medidas e plano de corte atualizam na hora | Adauto | (a implementar, depois das prioridades) |
| 17/11/2026 | **Frente e contra-frente da gaveta no 3D:** 2 toques na peça abrem o ajuste de altura e largura, cada peça separada, em passos de 1 mm. Não se aplica às outras frentes. Se afetar encaixe ou montagem, avisa antes de confirmar. Atualiza medidas e plano de corte, sem criar peça nova | Adauto | (a implementar, depois das prioridades) |
| 17/11/2026 | **Portas e janelas da parede do ambiente:** 1 toque só escolhe, 2 toques abrem a configuração. As portas dos móveis continuam como estão | Adauto | (a implementar, depois das prioridades) |
