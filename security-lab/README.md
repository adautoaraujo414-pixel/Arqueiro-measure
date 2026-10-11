# Arque Security Lab — diagnóstico Android

Aplicativo de inspeção **local e somente leitura** para aparelho Android próprio ou autorizado.
O código-fonte fica na pasta security-lab desta ramificação, isolado do Arque Measure.

## O que faz
- Exibe versão do Android e data do patch de segurança.
- Verifica se há bloqueio seguro de tela.
- Mostra estado da depuração USB e opções do desenvolvedor.
- Lista administradores de dispositivo visíveis via API Android.
- Informa criptografia do armazenamento quando acessível.
- Mostra serviços de acessibilidade ativos que o Android permite consultar.
- Gera um relatório textual, compartilhado apenas se você tocar em Compartilhar.

## Limitações importantes
- **Não explora vulnerabilidades**, não obtém root e não modifica a proteção do Android.
- **Não remove nem bloqueia PayJoy** nem outros mecanismos de financiamento e gestão.
- Um aplicativo comum não enxerga todos os componentes de gestão (device owner, MDM e políticas privadas).
- A presença de um administrador ou serviço de acessibilidade não significa invasão; configurações sinalizadas também não comprovam uma falha.
- O app não tem permissão INTERNET e não transmite relatórios automaticamente.

## Compilar pelo GitHub (sem Android Studio)
1. Na aba **Actions** deste repositório, abra o workflow **Android Security Lab - APK**.
2. O primeiro push da ramificação lab-seguranca-android aciona automaticamente o workflow.
3. Abra a execução concluída e baixe o artefato **arque-security-lab-apk**.
4. Extraia o ZIP e instale **app-debug.apk** no seu aparelho Android.

O APK de debug deve ser instalado apenas em dispositivos seus ou autorizados.
Para compilar localmente, instale JDK 17, Android SDK 35 e Gradle 8.9 e execute na pasta security-lab:

    gradle :app:assembleDebug

## Privacidade
Dados são lidos apenas pelas APIs públicas do sistema. O aplicativo não solicita privilégios administrativos, acessibilidade, acesso a SMS, chamadas, rede ou arquivos.
