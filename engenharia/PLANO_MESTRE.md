# Plano mestre definitivo (Adauto, 17/11/2026) — referência permanente

**Regra zero:** não alterar o que já funciona. Sem autorização expressa, nada disto pode mudar:
- funções existentes (substituir por outras);
- toques e gestos;
- layout, botões, menus e identidade visual;
- fórmulas e regras construtivas;
- motores (reescrever);
- recursos (remover);
- atrasos artificiais (introduzir);
- projetos salvos;
- outros módulos;
- publicação.

Antes de mudar, investigar se já existe. Conflito: parar só a parte conflitante e apresentar alternativas. Ver também o `CLAUDE.md`, seções 12 e 13.

## Sequência obrigatória (não antecipar, não reordenar sem motivo técnico e autorização)
1. **P0:** segurança das medidas e dos projetos (parede, pé-direito, dimensões e posições preservadas, desfazer/refazer, salvar/reabrir, backup, projetos antigos). Relatório e autorização, sem publicar.
2. **Fase 3:** só o escopo documentado (`FASE3_PRECISAO.md` e commits); a CI cancelada; corrigir só defeito comprovado.
3. **Item 6** (`claude/arquemestre-ajustes-3d`): gestos 1 a 5 preservados; 2 toques de perto = peça (±1 e ±0,5, laterais da gaveta, peça independente); 2 toques de longe = quadro + destaque + mover com o motor existente; precisão (nada escondido, zoom, módulo certo); colisões reais só; nada preso; porta piscando sem mudar o 1 toque e sem atraso, e nada implementado sem aprovação; validação (comparativa, telas, orientação, zoom, salvar/reabrir, regressão, desempenho).
4. **Item 7:** estrutura paramétrica (Moldura, Frontal, salvar modelo), só pelo escopo aprovado. Dúvida de especificação é registrada antes de implementar.
5. **Tamponamentos inteligentes:** editar dimensões, tamponamento superior, laterais descendentes esquerda e direita, medida interna útil real (com espessura e posição), sem peça duplicada ou invisível; 2D, 3D, lista e corte; salvar/reabrir.
6. **Biblioteca de cantos:** conferir o que existe, completar as variantes que faltam (L e cego, inferior e superior, esquerda e direita), sem duplicar e sem reorganizar sem autorização; medidas e corte.
7. **Exclusão e inconsistências:** a lixeira apaga exatamente o item; sem fantasma; nada no corte; nada recriado. Cadeia seleção → exclusão → geometria → lista → corte → salvar → reabrir; desfazer e refazer.
8. **Demais solicitações aprovadas:** inventário (solicitação, estado, branch e commit, o que funciona, o que falta, testes, dependências, autorização). Só concluir as de escopo aprovado.
8b. **Padronização das fitas (1 mm) e menu Pintar compacto** (pedido do Adauto, 17/11, depois das prioridades anteriores e antes da auditoria master):
   - **Fita:** 1 mm como padrão. Antes, levantar onde está o 0,8 e o que ele representa (físico, cálculo, 3D, desconto). Sem troca às cegas, projetos preservados, impacto apresentado antes.
   - **Menu Pintar:** mesmo menu, mesmas opções e funções. Cabeçalho menor, grupos na ordem Fitas → Peça → Módulo → Geral, botões confortáveis para o dedo, rolagem organizada.
   - **Testes:** iPhone, iPad, Android, tablets e Windows; menu aberto e minimizado; todas as opções; salvar e reabrir; cores já aplicadas.
   - **Situação:** proposta apresentada em 17/11 (página "Menu Pintar compacto"). Aguarda aprovação; nada implementado.
9. **Auditoria master final (por último):** precisão, desempenho, estabilidade e confiabilidade de todas as ferramentas. Medição, 2D/3D, fabricação, desempenho, bugs e multiplataforma, **sem mudar aparência, nome, lugar, comandos ou finalidade**. Método: auditar → esperado → medir → reproduzir → causa → mínimo → antes/depois → regressão → salvar/reabrir → registrar.

## Controle
- Branches separadas.
- Último homologado preservado.
- Commits registrados.
- Nada de ponteiros públicos, APK, Windows, TestFlight ou App Store.
- Sem mudar resultado esperado para esconder defeito.
- Bloqueio: documentar e seguir para outra tarefa independente já autorizada.

## Continuidade
- Ler `engenharia/ESTADO_E_CONTINUACAO.md` antes de qualquer trabalho.
- Atualizá-lo ao fim de cada etapa: último commit, testes feitos e pendentes, branches, decisões do Adauto.
- Não presumir que um teste passou porque estava rodando.

## Relatório de cada etapa
ETAPA · IMPLEMENTADO · PRESERVADO · CORRIGIDO · TESTES · DESEMPENHO · COMMITS · PENDÊNCIAS · RISCO · PUBLICAÇÃO.

Homologação e publicação dependem do Adauto.
