# Assinatura estável do Arque Measure

Esta configuração evita que versões futuras precisem ser desinstaladas por alteração na identidade da assinatura. **Não coloque o arquivo .jks nem senhas neste repositório.**

1. Gere um keystore privado uma única vez e mantenha cópia de segurança segura.
2. Em GitHub > Settings > Secrets and variables > Actions, configure os segredos:
   - `ARQUE_KEYSTORE_BASE64`: keystore codificado em Base64, em uma única linha.
   - `ARQUE_KEYSTORE_PASSWORD`: senha do arquivo.
   - `ARQUE_KEY_ALIAS`: nome da chave.
   - `ARQUE_KEY_PASSWORD`: senha da chave.
3. Com os quatro segredos presentes, o workflow compila `assembleRelease`; sem eles, usa `assembleDebug` apenas para teste.
4. O arquivo **precisa ser assinado sempre pela mesma chave**. Ao migrar de um APK debug para a versão release, talvez seja necessário fazer backup, desinstalar a versão anterior e instalar a release uma única vez.
5. A versão de instalação também exige `versionCode` crescente; nunca reutilize um número menor que o último instalado.

## Backup e acesso aos arquivos
O seletor oficial do Android permite salvar/importar `.arque` no dispositivo, em cartão SD ou em provedores conectados como Google Drive, desde que o provedor apareça no seletor. Nenhuma permissão de armazenamento irrestrito é necessária.

Antes de migrar a assinatura, sempre exporte e valide o backup. A restauração de backup completo substitui os dados locais apenas após confirmação.

## Transferência entre dois dispositivos
A descoberta utiliza BLE; o conteúdo é transferido por Wi-Fi local ou hotspot, protegido por AES-GCM com código de autorização de uso único. O limite atual é de 24 MB. Testes locais automatizados **não substituem** validação entre dois tablets reais, incluindo permissões e conectividade de rede.
