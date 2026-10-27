# Arquemestre para iPhone/iPad: build, teste e envio

## 🚀 Lançar na App Store — o que falta (em ordem)
Tudo do app e da ficha já está pronto. Faltam só os passos que precisam da sua conta Apple:

1. **Entrar no Apple Developer Program** (US$ 99/ano): developer.apple.com/programs/enroll.
   - Pra sair mais rápido, entre como **Pessoa física (Individual)**. Como empresa (CNPJ) a Apple pede o número D-U-N-S, que demora dias.
   - A aprovação costuma levar de algumas horas a 2 dias.
2. **App Store Connect → Contratos, impostos e bancos:** assine o contrato de **Apps pagos** e cadastre conta bancária e dados fiscais. Sem isso a compra não funciona.
3. **Criar o app** no App Store Connect (seção "Conta Apple Developer" abaixo): Bundle ID `br.com.arque.measure`, SKU `arquemestre-ios`.
4. **Criar as 2 compras** (`arquemestre_teste_3_dias` grátis e `arquemestre_acesso_completo` paga) — textos prontos na seção "Compras dentro do app".
5. **Chave da API** (Usuários e acesso → Integrações → App Store Connect API → função **App Manager**) e cadastrar no GitHub os 4 segredos:
   `ASC_KEY_ID`, `ASC_ISSUER_ID`, `APPLE_TEAM_ID` e `ASC_KEY_P8` (abra o arquivo `.p8` num editor de texto e cole o conteúdo inteiro).
6. **Mandar pro TestFlight:** GitHub → Actions → "iOS CI" → **Run workflow** → marque "Enviar para o TestFlight". Leva uns 30 min.
7. **Preencher a ficha** (textos, capturas, URLs, idade, privacidade — tudo abaixo), escolher o build e **Enviar para revisão**.
   - A revisão da Apple costuma levar de 1 a 3 dias.

### Links públicos (já no ar pelo GitHub Pages, pasta `docs/`)
| | Português | English | Español |
|---|---|---|---|
| Política de privacidade | `https://adautoaraujo414-pixel.github.io/Arqueiro-measure/privacidade.html` | `.../privacy.html` | `.../privacidad.html` |
| Suporte (obrigatório) | `.../suporte.html` | `.../support.html` | `.../soporte.html` |

O app abre a página no idioma em uso (Privacidade · Termos de uso · Ajuda, e no menu ⋯ da biblioteca).

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
1. Pague e espere a aprovação da conta (Individual é o mais rápido).
2. Em **Certificates, IDs & Profiles**, o App ID `br.com.arque.measure` é criado sozinho no primeiro envio pelo GitHub (assinatura automática). Se quiser criar na mão, marque a capacidade In-App Purchase.
3. Em **App Store Connect → Apps → ＋ Novo app**:
   - plataforma iOS; nome "Arquemestre" (se estiver ocupado: "Arquemestre: Marcenaria");
   - idioma principal Português (Brasil);
   - Bundle ID `br.com.arque.measure`; SKU `arquemestre-ios`; acesso completo.

## Compras dentro do app
Em **Monetização → Compras dentro do app**, crie as duas do tipo **Não consumível**:

| ID do produto | Nome de referência | Preço | Nome de exibição (pt / en / es) | Descrição (pt / en / es) |
|---|---|---|---|---|
| `arquemestre_teste_3_dias` | 3-day Trial | Grátis | Teste grátis de 3 dias / 3-Day Free Trial / Prueba gratis de 3 días | Libera tudo por 3 dias. / Unlocks everything for 3 days. / Libera todo por 3 días. |
| `arquemestre_acesso_completo` | Full Access | ex.: R$ 149,90 (a Apple converte pros outros países) | Acesso completo / Full Access / Acceso completo | Compra única, sem assinatura. / One-time purchase, no subscription. / Compra única, sin suscripción. |

- Captura pra revisão das compras: `capturas/iphone-6-trial.png` (ramo `ci/ios-resultados`).
- Na primeira versão, as compras vão junto: na página da versão, em "Compras dentro do app", adicione as duas antes de enviar.

## Enviar ao TestFlight sem Mac (pelo GitHub)
1. Em App Store Connect › Usuários e acesso › Integrações › App Store Connect API, crie uma **chave** com função "App Manager" e baixe o `.p8` (só dá pra baixar uma vez).
2. Em GitHub › Settings › Secrets and variables › Actions › **New repository secret**, crie:
   - `ASC_KEY_ID`: o ID da chave (ex.: 2X9R4HXF34);
   - `ASC_ISSUER_ID`: o Issuer ID (aparece no topo da página das chaves);
   - `APPLE_TEAM_ID`: o Team ID (developer.apple.com › Account › Membership);
   - `ASC_KEY_P8`: o conteúdo do arquivo `.p8`, colado do jeito que está (com as linhas BEGIN/END). Também aceita `ASC_KEY_P8_B64` em base64.
3. Em Actions › "iOS CI" › **Run workflow**, marque "Enviar para o TestFlight".
4. O build aparece no TestFlight (o número é o da execução). Instale no iPhone e teste rapidinho:
   - trena; compra de teste (sandbox); restaurar compra; avisos da agenda; trocar idioma.

## Ficha da App Store
- **Categoria:** Produtividade (secundária: Negócios).
- **Classificação etária:** 4+. Responda "não"/"nenhum" a todos os itens do questionário.
- **Privacidade do app (rótulo):** "Não coletamos dados deste app".
- **URL da política de privacidade:** a do idioma (tabela no topo).
- **URL de suporte:** a do idioma (tabela no topo). URL de marketing: deixe em branco.
- **Copyright:** `2026 Adauto Araújo`
- **Disponibilidade:** marque os países. Se incluir países da União Europeia, a Apple pede a declaração de "comerciante" (DSA), que mostra endereço e telefone na loja; pra lançar rápido, pode deixar a UE pra depois.
- **Capturas** (ramo `ci/ios-resultados`):
  - português: `capturas/iphone-*` (iPhone 6,9", 1320 × 2868) e `capturas/ipad-*` (iPad 13", 2064 × 2752);
  - inglês: `capturas/en/…`; espanhol: `capturas/es/…`.
- **Exportação de criptografia:** já respondida no Info.plist (`ITSAppUsesNonExemptEncryption = NO`).
- **Login para a revisão:** não precisa (o app não tem conta).

## Idiomas (Português, English, Español)
- O app já sai em 3 idiomas: segue o idioma do iPhone (qualquer outro idioma abre em inglês) e dá pra trocar em
  ⋯ → 🌐 Idioma · Language. O Info.plist declara pt-BR, en e es, então a App Store mostra os 3 idiomas.
- Textos do app: `app/src/main/assets/i18n/en.json` e `es.json` (os mesmos do Android e do editor de móveis).
  A chave é o texto em português; texto sem tradução continua em português.
- Moeda dos orçamentos: a do país do aparelho (Brasil R$, EUA $, Espanha €…).
- No App Store Connect, adicione as localizações **English (U.S.)** e **Spanish (Mexico)** (canto direito da página da versão).
- Nas palavras-chave não use marcas de terceiros (ex.: "Bosch"): a Apple recusa (regra 2.3.7). Na descrição pode citar a compatibilidade.

**Português (Brasil)**
- Nome: `Arquemestre`
- Subtítulo: `Medição e móveis planejados`
- Palavras-chave: `marcenaria,móveis planejados,trena laser,lista de corte,orçamento,cozinha,guarda-roupa,croqui`
- Texto promocional: `Meça com a trena laser, desenhe o móvel em 3D e mande o orçamento em PDF, tudo no mesmo app.`
- Descrição:
```
O Arquemestre junta a medição, o projeto, o corte, o orçamento e a agenda da sua marcenaria num lugar só.

• Medição: crie uma nota, tire foto ou desenhe o croqui e ligue a trena laser Bosch (Bluetooth): a medida cai direto na cota, com milímetro. Sem trena, é só digitar.
• Editor de móveis: monte cozinha, guarda-roupa, painel e sala. Veja em 3D, abra portas e gavetas, estique peças arrastando.
• Lista de corte e orçamento: lista de peças, plano das chapas inteiras, custo do material e orçamento em PDF com a sua logo.
• Agenda: entregas, visitas e medições ligadas a cada cliente, com aviso antes.

Teste grátis de 3 dias com tudo liberado. Depois, compra única — sem assinatura, sem mensalidade.
Funciona sem internet e sem cadastro: seus dados ficam no seu aparelho.
```

**English (U.S.)**
- Name: `Arquemestre`
- Subtitle: `Woodshop measuring & cabinets`
- Keywords: `woodworking,cabinet,laser measure,cut list,kitchen,closet,quote,sketch,carpentry,millwork`
- Promotional text: `Measure with a laser, design the cabinet in 3D and send the PDF quote — all in one app.`
- Description:
```
Arquemestre puts your woodshop's measuring, design, cutting, quotes and schedule in one place.

• Measuring: create a note, take a photo or draw the sketch, connect a Bosch laser measure (Bluetooth) and the reading drops straight into the dimension. No laser? Just type it.
• Furniture editor: build kitchens, wardrobes, panels and living rooms. See them in 3D, open doors and drawers, stretch parts by dragging.
• Cut list and quotes: parts list, full-board cutting plan, material cost and a PDF quote with your logo.
• Schedule: deliveries, visits and measuring linked to each client, with reminders.

Free 3-day trial with everything unlocked. Then a one-time purchase — no subscription, no monthly fee.
Works offline and with no sign-up: your data stays on your device.
```

**Spanish (Mexico)**
- Nombre: `Arquemestre`
- Subtítulo: `Medición y muebles a medida`
- Palabras clave: `carpintería,muebles,cocina,ropero,medidor láser,lista de corte,presupuesto,croquis,ebanistería`
- Texto promocional: `Mide con el láser, diseña el mueble en 3D y manda el presupuesto en PDF, todo en la misma app.`
- Descripción:
```
Arquemestre reúne la medición, el proyecto, el corte, el presupuesto y la agenda de tu carpintería en un solo lugar.

• Medición: crea una nota, toma una foto o dibuja el croquis, conecta el medidor láser Bosch (Bluetooth) y la medida cae directo en la cota. ¿Sin láser? Solo escríbela.
• Editor de muebles: arma cocinas, roperos, paneles y salas. Míralos en 3D, abre puertas y cajones, estira piezas arrastrando.
• Lista de corte y presupuesto: lista de piezas, plano de corte de tableros enteros, costo del material y presupuesto en PDF con tu logo.
• Agenda: entregas, visitas y mediciones ligadas a cada cliente, con avisos.

Prueba gratis de 3 días con todo liberado. Después, compra única — sin suscripción, sin mensualidad.
Funciona sin internet y sin registro: tus datos quedan en tu equipo.
```

## Notas para a revisão da Apple (colar em "Notas", em inglês — o revisor lê em inglês)
```
Arquemestre is a work tool for woodworkers and cabinet makers. There is no login and no account; all data stays on the device.

Free trial: on first launch tap "Start 3-day free trial". The trial is a zero-price non-consumable in-app purchase
(arquemestre_teste_3_dias), following guideline 3.1.1. After 3 days the app asks for the one-time non-consumable
purchase "Full Access" (arquemestre_acesso_completo). "Already bought · restore purchase" calls AppStore.sync().
No subscriptions.

Laser measure: the app can receive measurements from Bosch laser measures (GLM 50 C, GLM 50-27 CG) over Bluetooth LE.
Without the device, open a note, tap any dimension label and type the value on the in-app keypad — every feature works.

Live project view: between two devices with the app (local peer-to-peer network), view only.
Languages: Portuguese, English and Spanish (follows the device; can be changed in ⋯ → Language).
```
