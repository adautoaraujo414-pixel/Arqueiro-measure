# CLAUDE.md — regras permanentes do Arquemestre

Leia este arquivo e a pasta `engenharia/` antes de qualquer alteração.

> **Atenção:** este repositório é **público** no GitHub. Não grave aqui senhas, chaves, dados de clientes, preços combinados nem regras de licença.
> O site público (GitHub Pages) é montado só com a pasta `docs/`. Documentação técnica interna fica em `engenharia/`, **nunca** em `docs/`.

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
- Painéis e módulos são sólidos: nada entra dentro de outra coisa.

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
5. Ver dependências e definir o escopo exato.
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
