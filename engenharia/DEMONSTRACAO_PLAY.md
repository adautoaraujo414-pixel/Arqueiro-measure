# Demonstração separada — preparação de 24/11/2026

Pedido direto: resolver o acesso de revisão; o responsável escolheu “Incluir demonstração com dados separados”.

Implementação inicial sobre `c5611206bdc394cd2c71883606b76d5a32cc3374` (AAB 660). Depois integrada, sem alterar a branch do Claude, ao fechamento `7e2421a4fd08bf24243cabfbdf77626b6c4871fc`. A base da revisão é `claude/fechamento-code1`; o diff deve conter apenas a demonstração, seus testes e documentação.

## Comportamento

- Botão visível na tela de assinatura: **Explorar demonstração com dados separados**.
- Abre as mesmas telas e cálculos, com um cliente/cozinha fictício e uma nota de exemplo. Pode criar e editar nessa área.
- Faixa permanente “Demonstração · dados separados”, com Sair.
- Não requer cadastro, compra, código secreto nem prazo de avaliação.
- Não grava uma licença no uso normal; não inicia Billing no ViewModel de demonstração.
- Dados nativos em `files/arquemestre_demo/files`; preferências com prefixo próprio; origem Web própria (`demo.arquemestre.invalid`, atendida localmente pelo AssetLoader).
- Mesma faixa etária e permissões; câmera, Bluetooth e compartilhamentos continuam ações explícitas.
- Backup manual da demonstração fica restrito à árvore dela. Backup automático externo não roda na demonstração e não sobrescreve a cópia normal.
- Arquivos nativos e preferências da demonstração são excluídos do backup manual normal. O perfil WebView subjacente continua o do aplicativo, com localStorage isolado por origem; não há cópia de projetos entre as origens.
- Lembretes usam outro receiver e identificador de notificação; abrem a demonstração.

## Verificação exigida

Workflow `play-demonstracao.yml`: compila apenas `.teste`, roda JVM e testes Android no emulador. Não publica release nem altera o Play Console.

Testes: edição/exportação/restauração da demonstração preservando sentinelas normais e licença; exclusão dos arquivos nativos da demonstração na cópia normal; entrada pela tela de assinatura sem compra e saída mantendo bloqueio normal.

Ainda não declarar homologação até a execução terminar. Testes de compra/renovação reais pela Play permanecem separados. Não substituir o rascunho 660 com APK de teste.

## Instruções propostas para o Console (só cadastrar depois da versão correspondente)

No account or purchase is required to review the demonstration. On the subscription screen, tap “Explore the demo with separate data” (Portuguese: “Explorar demonstração com dados separados”). The demonstration opens the app’s tools with separate sample data. You can create and edit projects, measurements, quotes and appointments. Tap “Exit” in the demonstration banner to return to the subscription screen. The normal subscription remains unchanged. For manual measurements, tap a dimension and enter its value; a Bluetooth laser is optional.

## Distribuição

Nenhuma publicação autorizada por este arquivo. Preparação e testes não equivalem à liberação da nova versão aos usuários.
