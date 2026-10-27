# Arquemestre para iPhone/iPad: build, teste e envio

## O que já existe neste repositório
- `ios/`: app próprio para iOS em SwiftUI. Mínimo iOS 17; compilado com Xcode 26 / SDK iOS 26, que a App Store exige desde 28/04/2026.
- O mesmo **editor de móveis** do Android (`app/src/main/assets/editor.html`) roda num WKWebView. Ele mantém a ponte `ArqueApp` (cópia dos projetos em arquivo, trena, compartilhar).
- **Notas e croqui**: folhas A4, caneta/lápis/marca-texto e Apple Pencil, além de:
  - formas, cotas e cômodo (planta com porta/janela/vão);
  - fotos, texto, laço, borracha;
  - desfazer/refazer, lupa e calculadora;
  - exportar PDF/PNG/CSV.
- **Trena Bosch** por CoreBluetooth. É o mesmo protocolo do Android, com o arredondamento para o milímetro igual ao visor.
- **Agenda** com notificações locais. O iOS limita o app a 64 avisos agendados; o app agenda os 60 mais próximos.
- **Orçamentos** em PDF, com logo.
- **Backup ZIP** no mesmo formato do Android: um backup feito no Android abre no iPhone e vice-versa.
- **Ver projeto ao vivo** entre iPhones/iPads, por MultipeerConnectivity. Entre Android e iPhone isso não funciona, porque o iOS não deixa apps usarem Bluetooth clássico; nesse caso, use o backup.
- **Compra pelo StoreKit 2**, seguindo a regra 3.1.1 da Apple:
  - `arquemestre_teste_3_dias`: não consumível de preço **zero**, que libera o teste;
  - `arquemestre_acesso_completo`: não consumível pago;
  - botão "Já comprei · restaurar compra".
  - Não tem anúncios nem login.
- `PrivacyInfo.xcprivacy`: sem rastreamento, sem coleta, só as APIs de motivo obrigatório (UserDefaults e data de arquivo).
- CI no GitHub (`.github/workflows/ios.yml`, roda em macOS 26):
  - gera o projeto com XcodeGen;
  - roda os testes no simulador;
  - compila a versão Release para iPhone;
  - tira capturas de iPhone 6,9" e iPad 13" e guarda no ramo `ci/ios-resultados`.

## Rodar num Mac (opcional)
```
brew install xcodegen
cd ios && xcodegen generate && open Arquemestre.xcodeproj
```
- Para testar as compras no simulador: escolha o esquema "Arquemestre" (ele já usa `Arquemestre.storekit`) e rode.
- No iPhone de verdade: em Signing & Capabilities, escolha o seu Team.

## Conta Apple Developer (US$ 99/ano)
1. Pague e espere a aprovação da conta.
2. Em **Certificates, IDs & Profiles**, crie o App ID `br.com.arque.measure`, com a capacidade In-App Purchase.
3. Em **App Store Connect**, crie o app:
   - nome "Arquemestre"; se o nome estiver ocupado, use "Arquemestre: Marcenaria";
   - idioma Português (Brasil);
   - Bundle ID `br.com.arque.measure`;
   - SKU `arquemestre-ios`.
4. Em **Compras dentro do app**, crie os dois produtos do tipo "Não consumível":
   - `arquemestre_teste_3_dias`:
     - preço **Grátis**;
     - nome de exibição "Teste grátis de 3 dias";
     - nome de referência "3-day Trial" (a Apple pede esse padrão).
   - `arquemestre_acesso_completo`:
     - preço do nível equivalente a R$ 149,90;
     - nome "Acesso completo".
   - Os dois precisam de uma captura de tela para a revisão. Use `iphone-6-trial.png`.
5. Assine o contrato de **Apps pagos** e preencha os dados bancários e fiscais. Sem isso, as compras não funcionam.

## Enviar ao TestFlight sem Mac (pelo GitHub)
1. Em App Store Connect › Usuários e acesso › Integrações, crie uma **chave da API** com função "App Manager".
2. Em GitHub › Settings › Secrets › Actions, crie estes segredos:
   - `ASC_KEY_ID`: o ID da chave;
   - `ASC_ISSUER_ID`: o Issuer ID;
   - `ASC_KEY_P8_B64`: o arquivo `.p8` em base64;
   - `APPLE_TEAM_ID`: o Team ID da conta.
3. Em Actions › "iOS CI" › **Run workflow**, marque "Enviar para o TestFlight".
4. O build aparece no TestFlight. Instale no iPhone e teste:
   - trena;
   - compra de teste com sandbox;
   - restaurar compra;
   - avisos da agenda;
   - backup do Android abrindo no iPhone.

## Ficha da App Store
- **Categoria:** Produtividade (secundária: Utilitários).
- **Classificação etária:** 4+. Responda "não" a todos os itens do questionário.
- **Privacidade do app:** "Não coletamos dados".
- **URL da política de privacidade:** `docs/privacidade.html`, publicada pelo GitHub Pages (ative quando confirmar) ou num link público seu.
- **Capturas:** use as de `ci/ios-resultados/capturas`:
  - `iphone-*` para o iPhone 6,9" (1320 × 2868);
  - `ipad-*` para o iPad 13" (2064 × 2752).
- **Exportação de criptografia:** já respondida no Info.plist (`ITSAppUsesNonExemptEncryption = NO`).

## Idiomas (Português, English, Español)
- O app já sai em 3 idiomas: segue o idioma do iPhone (qualquer outro idioma abre em inglês) e dá pra trocar em
  ⋯ → 🌐 Idioma · Language. O Info.plist declara pt-BR, en e es, então a App Store mostra os 3 idiomas.
- Textos do app: `app/src/main/assets/i18n/en.json` e `es.json` (os mesmos do Android e do editor de móveis).
  A chave é o texto em português; texto sem tradução continua em português.
- Moeda dos orçamentos: a do país do aparelho (Brasil R$, EUA $, Espanha €…).
- Capturas por idioma: `capturas/` (português), `capturas/en/` e `capturas/es/`.
- Em "Disponibilidade" marque os países onde quer vender (ex.: Brasil, Estados Unidos, México, Espanha…).
- No App Store Connect, adicione as localizações **English (U.S.)** e **Spanish (Mexico)** e cole:

**English (U.S.)**
- Name: `Arquemestre`
- Subtitle: `Woodshop measuring & cabinets`
- Keywords: `woodworking,cabinet,laser measure,bosch,cut list,kitchen,closet,quote,sketch,carpentry`
- Description:
```
Arquemestre puts your woodshop's measuring, design, cutting, quotes and schedule in one place.

• Measuring: create a note, take a photo or draw the sketch, connect a Bosch laser measure (Bluetooth) and the reading drops straight into the dimension.
• Furniture editor: build kitchens, wardrobes, panels and living rooms. See them in 3D, open doors and drawers, stretch parts by dragging.
• Cut list and quotes: parts list, full-board cutting plan, material cost and a PDF quote with your logo.
• Schedule: deliveries, visits and measuring linked to each client, with reminders.

Free trial with everything unlocked. Then a one-time purchase — no subscription.
```

**Spanish (Mexico)**
- Nombre: `Arquemestre`
- Subtítulo: `Medición y muebles a medida`
- Palabras clave: `carpintería,muebles,cocina,ropero,medidor láser,bosch,lista de corte,presupuesto,croquis`
- Descripción:
```
Arquemestre reúne la medición, el proyecto, el corte, el presupuesto y la agenda de tu carpintería en un solo lugar.

• Medición: crea una nota, toma una foto o dibuja el croquis, conecta el medidor láser Bosch (Bluetooth) y la medida cae directo en la cota.
• Editor de muebles: arma cocinas, roperos, paneles y salas. Míralos en 3D, abre puertas y cajones, estira piezas arrastrando.
• Lista de corte y presupuesto: lista de piezas, plano de corte de tableros enteros, costo del material y presupuesto en PDF con tu logo.
• Agenda: entregas, visitas y mediciones ligadas a cada cliente, con avisos.

Prueba gratis con todo liberado. Después, compra única — sin suscripción.
```

## Notas para a revisão da Apple (colar em "Notas")
```
O Arquemestre não tem login nem conta.
Teste grátis: na primeira abertura toque "Começar teste grátis de 3 dias" (compra não consumível de preço zero,
conforme a regra 3.1.1). Depois dos 3 dias o app pede a compra única "Acesso completo" (não consumível).
"Já comprei · restaurar compra" usa AppStore.sync().
Trena Bosch: o app recebe medidas de trenas laser Bosch (GLM 50 C, GLM 50-27 CG) por Bluetooth LE. Sem a trena,
toque numa cota e digite a medida no teclado do app.
Ver projeto ao vivo: entre dois aparelhos com o app (rede local ponto a ponto), só visualização.
```
