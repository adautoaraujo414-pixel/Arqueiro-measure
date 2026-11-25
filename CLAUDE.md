# CLAUDE.md — regras permanentes do Arquemestre

Leia este arquivo e a pasta `engenharia/` antes de qualquer alteração.

> **Atenção:** este repositório é **público** no GitHub. Não grave aqui senhas, chaves, dados de clientes, preços combinados nem regras de licença.
> O site público (GitHub Pages) é montado só com a pasta `docs/`. Documentação técnica interna fica em `engenharia/`, **nunca** em `docs/`.

## 0. Desenvolvimento evolutivo (regra permanente do Adauto, 23/11/2026 · vale para toda sessão)
- O desenvolvimento é **exclusivamente evolutivo**. Nunca desativar, remover, ocultar ou prejudicar uma função que já existe para colocar uma nova.
- Toda implementação preserva integralmente os recursos anteriores, os projetos salvos e a compatibilidade.
- Antes de concluir qualquer alteração, rodar os testes de regressão (bateria completa).
- Conflito entre uma função nova e uma existente: adaptar a implementação para que **as duas** funcionem. Nunca resolver tirando a antiga.
- Vale para todas as próximas etapas, inclusive móveis livres, editor 2D, câmera 3D e plano de corte.

## 1. Execução literal
- Fazer exatamente o que o Adauto pediu. Não inventar funções, peças, telas, botões ou módulos.
- O que não foi pedido continua igual: layout, menus, gestos, câmera, cálculos, catálogo, configurações padrão e outros puxadores.
- Sugestão não é autorização. Se a mudança depende de mexer em outra parte, explicar a dependência e pedir autorização antes.
- Dúvida que muda o comportamento do app: fazer uma pergunta objetiva. Não escolher por ele.
- Classificar cada ação: **A** (pedida), **B** (dependência necessária) ou **C** (melhoria opcional). Executar A e B comprovadas; C vira sugestão.

## 2. Referências (fotos, vídeos, prints, desenhos, catálogos)
- A referência é especificação obrigatória dentro do escopo do pedido. Não simplificar e não inventar.
- Não presumir medida de imagem sem escala. Detalhe oculto ou ambíguo: perguntar.
- Depois de implementar, comparar com a referência e mostrar evidência visual. Nunca dizer "idêntico" sem comparar.
- Registrar a referência em `engenharia/REFERENCIAS.md`.

## 3. Projetos do usuário (prioridade máxima)
- Nenhuma atualização pode apagar, esvaziar ou trocar projeto válido. Já houve perda de projetos.
- Mudança em armazenamento, serialização, migração ou identificadores: backup verificável antes, compatibilidade com projetos antigos, teste de salvar, fechar e reabrir.
- O app nunca muda nada sozinho. Apagar só manualmente e passando pela lixeira.

## 4. Uma fonte de verdade
- `partsOf(m)` é a fonte das peças. 2D, 3D, plano de corte, lista de materiais e orçamento leem dela.
- O 3D não inventa peça. O plano de corte não calcula peça diferente da cadastrada.
- Não criar segunda lógica para corrigir a primeira. Achar a causa real.
- Painéis e módulos são sólidos: nada entra dentro de outra coisa **sem a pessoa confirmar** (exceção do §12: sobreposição intencional é permitida com aviso e confirmação).
- **Medida e posição são do marceneiro** (Adauto, 16/11/2026): o app avisa a incompatibilidade (módulo, medida, disponível, diferença) e nunca altera sozinho medida ou posição de fabricação. Mudar o ambiente não modifica os móveis. Desenhar não modifica o projeto. Ver `engenharia/DECISOES_TECNICAS.md`.

## 5. Marcenaria
- Medida de peça só em cm e mm, sem décimo (o décimo vira folga; a peça nunca fica maior que o desenho).
- Não trocar fórmula por aproximação. Antes de mudar uma conta, mostrar a conta atual, o problema e a correção.
- Regras confirmadas ficam em `engenharia/REGRAS_MARCENARIA.md`.

## 6. Testes e bateria
- Todo erro relatado vira teste na bateria (`ios/ArquemestreTests/EditorWebKitTests.swift`), que também confere o mesmo erro nos outros módulos.
- Não remover nem afrouxar teste para passar. Se uma expectativa muda por pedido aprovado, o comentário do teste diz qual pedido e a data.
- "Corrigido" só depois de reproduzir antes e validar depois.
- No relatório, separar: implementado, testado no simulador ou na bateria, testado em aparelho real, pendente e não verificado.

## 7. Publicação
- Proibido publicar sem autorização expressa do Adauto para aquela versão e plataforma: TestFlight, App Store, Play Store, APK do site, Windows.
- `asc-enviar.yml` com `enviar=true` nunca roda sem o "sim" dele.
- Testar não é publicar. Compilar não é publicar. Aprovar correção não autoriza distribuir.
- Não contornar a trava de publicação. Usar só o processo manual com confirmação do commit.
- iOS, Android e Windows têm as mesmas funções.

## 8. Fluxo de cada pedido
1. Ler o pedido inteiro.
2. Ler este arquivo, `engenharia/HISTORICO_ERROS.md` e a especificação da área (`engenharia/especificacoes/`).
3. Recuperar as referências.
4. Reproduzir o comportamento atual.
5. Ver dependências e definir o escopo exato. Procurar o mesmo erro nos módulos da mesma família (seção 11).
6. Fazer a menor alteração autorizada.
7. Rodar o teste novo e a bateria completa.
8. Comparar com o pedido e a referência.
9. Registrar o erro, a correção e a decisão.

## 9. Especificações por área
- Puxador gola (perfil G): `engenharia/especificacoes/puxador-gola.md`. Não mexer na orientação do perfil sem ler.

## 10. Comunicação
- Português informal e curto.
- Não citar Android, Play, APK ou beta na interface do editor nem nas novidades.
- Cada atualização tem em `.github/novidades.txt` o que mudou, com precisão.

## 11. Protocolo global de correção (pedido do Adauto, 16/11/2026 09:33 · vale para toda sessão)
**Um erro encontrado → causa identificada → módulos semelhantes investigados → correções comprovadas → testes permanentes → prevenção de regressões.**

1. **Registro técnico permanente** em `engenharia/HISTORICO_ERROS.md`, um por erro, com: identificação e descrição, módulo, como reproduzir, causa raiz comprovada, arquivos e funções, outros módulos possivelmente afetados, correção, testes de regressão, resultado da validação e commit. Consultar antes de implementar ou corrigir algo parecido. Não depender da memória da conversa.
2. **Família de módulos.** Todo defeito é procurado em todos os módulos que usam o mesmo componente, cálculo ou mecanismo:
   - inferiores (pia, gaveteiros, porta-temperos, com portas, canto, com divisórias);
   - superiores (aéreos, basculantes, com portas, nichos, maleiros);
   - torres (quente, forno e micro, despensa, com maleiro, com gavetas, com divisões);
   - guarda-roupas e closets (portas, gavetas, cabideiros, maleiros, prateleiras, divisórias, canto);
   - demais (painéis, racks, cristaleiras, balcões, curvos, personalizados).
   Não aplicar regra de torre em guarda-roupa sem conferir se a construção é compatível.
3. **Erros semelhantes.** Peça contada na medida tem que existir e aparecer de acordo com a configuração. Peça adicionada, removida ou mudada atualiza tudo que depende dela. Conferir tamponamentos (esquerdo, direito, superior, inferior, com engrosso), laterais, prateleiras (engrosso, com e sem recuo), divisórias, fundos, réguas, batentes, portas, gavetas, basculantes, puxadores e perfis.
4. **Sincronização.** Comando → configuração → cálculo → peças (`partsOf`) → 2D → 3D → lista → plano de corte → orçamento. Conferir os 14 erros:
   1. contada e não gerada;
   2. gerada e não desenhada;
   3. no 3D e fora da lista;
   4. na lista e fora do corte;
   5. removida e ainda contada;
   6. desconto duas vezes;
   7. desconto não aplicado;
   8. duplicada depois de editar;
   9. medida errada depois de salvar e reabrir;
   10. peça antiga que fica depois de mudar a configuração;
   11. 2D que não atualiza o 3D;
   12. um vão mexendo em outro;
   13. diferença entre o módulo isolado e o projeto inteiro;
   14. peça que some depois de atualizar.
   Não inventar geometria para esconder inconsistência.
5. **Causa, não sintoma.** Nada de peça visual fictícia, renderização forçada ou desconto artificial. Corrigir no componente compartilhado quando a causa está nele. Evitar refatoração grande sem necessidade.
6. **Testes obrigatórios por erro corrigido:**
   1. teste que reproduz o defeito;
   2. prova de que ele falha antes (rodar na versão anterior);
   3. correção;
   4. teste passando;
   5. módulos semelhantes;
   6. bateria completa;
   7. outras funções afetadas.
   Cobrir adicionar/remover peça, espessura, largura/altura/profundidade, divisões, salvar e reabrir, duplicar, projeto antigo, módulo isolado, projeto inteiro, plano de corte e troca 2D/3D. Validar geometria, medida e presença nos dados, não só se apareceu.
7. **Projetos existentes.** Ver formatos, compatibilidade e identificadores antes de mexer em dados. Testar salvar e recuperar com cópias. Sem migração destrutiva, sem sobrescrever backup e sem apagar projeto para resolver incompatibilidade. Projeto antigo que já ficou inconsistente não muda sozinho: avisa e deixa a pessoa decidir.
8. **Auditoria preventiva.** Ao corrigir, procurar falhas no mesmo mecanismo. Classificar cada achado como **erro comprovado**, **risco identificado**, **comportamento correto** ou **não foi possível verificar**. Nunca dizer que corrigiu o que não foi reproduzido.
9. **Publicação.** Só ambiente de desenvolvimento. Não mudar ponteiros de atualização de produção nem aplicativos instalados. Nada no Android, Windows, TestFlight ou App Store sem autorização explícita (ver seção 7).
10. **Relatório de cada investigação:** ERRO ORIGINAL · CAUSA RAIZ · MÓDULOS INVESTIGADOS · ERROS SEMELHANTES · CORREÇÕES · TESTES · SEGURANÇA · PENDÊNCIAS.

## 12. Liberdade total de composição e edição (regra fundamental do Adauto, 25/11/2026 · vale para toda sessão)
- O usuário pode criar qualquer móvel, mesmo fora dos padrões de marcenaria: posicionar, mover, girar e redimensionar módulos e peças livremente; sobrepor de propósito; encaixes e medidas fora do padrão; qualquer componente em qualquer tipo de móvel.
- Menus inteligentes **facilitam** (o compatível primeiro), **nunca restringem** (o resto continua alcançável).
- O app **não altera sozinho** medidas, tamponamentos, divisórias, portas, prateleiras ou posições de nada que já existe. O que hoje é automático sobre o que já existe vira **sugestão com botão**. Ao criar, o módulo novo recebe os padrões dos Ajustes (é criação, não alteração).
- Interferência, colisão ou medida fora do padrão **não bloqueiam** a edição: aviso técnico claro (o quê, onde, quanto), sem diálogo que interrompa o gesto; pergunta no máximo uma vez ao soltar/confirmar; sobreposição já confirmada não pergunta de novo.
- Peça que não pode ser fabricada ou não cabe na chapa: **informar** claramente; **nunca** modificar o projeto sozinho.
- Precisão intacta: partsOf = 2D = 3D = lista = orçamento = plano de corte = DXF, para o que o usuário decidiu.
- Convive com o §4 ("medida e posição são do marceneiro") e com o §3 (projetos do usuário): mais liberdade, nenhuma mudança calada.

