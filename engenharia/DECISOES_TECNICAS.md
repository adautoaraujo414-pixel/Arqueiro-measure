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
| 21/11/2026 | **R-CANTO:** o Canto L nunca empurra, desloca, inverte, redimensiona ou reorganiza móveis existentes. Sem espaço: "Usar espaço disponível" (só se o canto adaptado continuar válido) ou "Não colocar"; sem espaço pra um canto válido, não coloca e explica. Regra de canto válido usada (derivada da construção que já existe: lado = máx(prof. + 200, cw2)): parede do fundo ≥ prof. do lado + 200 e lado ≥ prof. + 200 — **a confirmar pelo Adauto** | Adauto (regra do canto mínimo: dedução, a confirmar) | `HISTORICO_ERROS.md` (R-CANTO) |
| 21/11/2026 | **Etapa C:** segurar o móvel 2 s abre o mesmo menu dos toques (2D e Planta: menu do vão dos 2 toques; 3D: quadro de opções dos 3 toques), sem mexer no móvel. Mouse: só segurar o botão esquerdo 2 s (clique direito não faz nada) | Adauto (escolha nas perguntas de 21/11) | `HISTORICO_ERROS.md` (ETAPA C), `GESTOS_CONTROLES.md` |
| 21/11/2026 | **Menu do 3D (segurar 2 s):** girar só no móvel livre (no de parede, apagado com "Tire da parede para girar"); 2D e Planta seguem com o menu do vão; o menu do 3D substitui o quadro dos 3 toques só no segurar | Adauto (perguntas de 21/11) | `HISTORICO_ERROS.md` (ETAPA C · MENU DO 3D) |
| 21/11/2026 | **Mover no 3D (ímã):** encaixa só de costas pra parede (nada gira sozinho); só a pedra da parede; puxado > 20 mm sai da parede; ímã nos Ajustes, guardado; parede esquerda não encaixa nem solta arrastando (guardada espelhada, decisão de 18/11) | Adauto (perguntas de 21/11) | `HISTORICO_ERROS.md` (ETAPA C2) |
| 21/11/2026 (noite) | **C2 (`1a2ee00` + correções) candidata principal da próxima atualização.** Canto L: sobra mínima de 200 mm fica **provisória, sujeita à aprovação do Adauto**, sem mover outros móveis. Parede esquerda: **sem mudança nesta etapa**, o espelhamento fica registrado como pendência pra correção específica. Autorizado: build de teste da C2 no TestFlight e APK de teste separado do app de produção, depois dos testes automáticos. **Não autorizado:** App Store, Play Store, APK público, distribuição Windows | Adauto | `HISTORICO_ERROS.md` (PEDRA-LIVRE, LIVRE-PAREDE, ABERTURA-LENTA) |
