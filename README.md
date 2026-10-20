# ARQUE MEASURE

Caderno digital profissional para Android (tablet e S Pen): folhas, fotografias, desenho, **cotas (setas dimensionais)** e **recebimento de medidas direto da trena Bosch por Bluetooth**.

Escrito do zero em Kotlin + Jetpack Compose. Não usa código de terceiros dos apps de referência.

## Função central

1. Escolha a ferramenta **Cota** e arraste sobre a foto: nasce uma seta, selecionada, aguardando a medida.
2. Meça com a trena Bosch.
3. O valor aparece no centro da seta, é salvo na hora, e a seleção avança para a próxima cota ainda sem valor.

Se nenhuma cota estiver selecionada, a leitura fica na lista flutuante **Leituras da trena** para uso depois.
Tocar no número da cota abre um campo pequeno para digitar manualmente (a medida fica marcada como "digitada").

## Regras de projeto

- **Folha fixa, foto livre:** a folha mantém o tamanho do papel. Foto é objeto independente: mover, redimensionar pelos cantos, pinça, girar (alça e dois dedos), duplicar, travar, camadas.
- **Pinça com foto selecionada** muda a foto. Sem foto selecionada, só dá zoom na visualização.
- **Cotas e anotações vinculadas à foto** guardam posição relativa à foto e a acompanham.
- **Medida real ≠ pixel:** valores ficam em milímetros, com origem (Bluetooth/digitada) e histórico de leituras. Nada é calculado a partir de pixels.
- **Fotos originais** são copiadas sem recompressão; a tela usa uma versão reduzida só para exibir.
- **Salvamento automático** (600 ms após editar, e ao sair), gravação atômica com cópia `.bak` para recuperação.

## Compilar

Pelo GitHub Actions (`.github/workflows/android.yml`): lint → testes → `assembleDebug` → verificação do APK → artefato `ArqueMeasure-debug-apk`.

Local (precisa de JDK 17 e Android SDK 35):

```
./gradlew testDebugUnitTest assembleDebug
# APK: app/build/outputs/apk/debug/app-debug.apk
```

## Estrutura

```
app/src/main/java/br/com/arque/measure/
  model/   Model.kt                 dados (folha, foto, cota, leitura)
  logic/   Geo, Units, EditorState  lógica pura, testada na JVM
  data/    Json, Store              persistência, backup, restauração
  ble/     BoschProtocol, BoschBle  Bluetooth LE
  ui/      Gestures, SheetRenderer, EditorScreen, Screens
```

Veja `INVENTARIO.md` (funções e testes) e `RELATORIO.md` (o que foi e o que NÃO foi verificado).
