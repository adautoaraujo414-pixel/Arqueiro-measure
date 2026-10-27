# Arquemestre para iPhone/iPad: build, teste e envio

## 🚀 Lançar na App Store — o que falta (em ordem)
Tudo do app e da ficha já está pronto. Faltam só os passos que precisam da sua conta Apple:

1. **Entrar no Apple Developer Program** (US$ 99/ano): developer.apple.com/programs/enroll.
   - Pra sair mais rápido, entre como **Pessoa física (Individual)**. Como empresa (CNPJ) a Apple pede o número D-U-N-S, que demora dias.
   - A aprovação costuma levar de algumas horas a 2 dias.
2. **App Store Connect → Contratos, impostos e bancos:** assine o contrato de **Apps pagos** e cadastre conta bancária e dados fiscais. Sem isso a compra não funciona.
3. **Criar o app** no App Store Connect (seção "Conta Apple Developer" abaixo): Bundle ID `br.com.arque.measure`, SKU `arquemestre-ios`.
4. **Criar a assinatura mensal** `arquemestre_mensal` (R$ 29,90/mês, com 3 dias grátis pra quem nunca assinou) — tudo pronto na seção "Assinatura".
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
- **Assinatura pelo StoreKit 2**, seguindo a regra 3.1.2 da Apple:
  - `arquemestre_mensal`: assinatura mensal com renovação automática (R$ 29,90), com oferta introdutória de 3 dias grátis;
  - botões "Já assino · restaurar compras" e "Gerenciar assinatura";
  - texto da renovação automática e links de Privacidade e Termos de uso na tela de assinatura.
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

## Assinatura (R$ 29,90 por mês) — configuração no App Store Connect
O app é **grátis pra baixar**. Tudo é liberado por **uma assinatura mensal com renovação automática** pela Apple (StoreKit 2),
com **3 dias grátis** só pra quem nunca assinou. Não existe senha, compra única nem pagamento por fora no iPhone/iPad.

### Antes de tudo (sem isso a assinatura não aparece nem no Sandbox)
1. **Contratos, impostos e bancos:** contrato de **Apps pagos** assinado, conta bancária e formulários fiscais preenchidos (status "Ativo").
2. App criado com o Bundle ID `br.com.arque.measure` (capacidade **In-App Purchase** ligada no App ID; vem ligada por padrão).

### Monetização → Assinaturas
1. **Grupo de assinaturas** · nome de referência `Arquemestre`.
   - Localizações do grupo (nome que aparece em Ajustes › Assinaturas): pt-BR "Arquemestre" · en-US "Arquemestre" · es-MX "Arquemestre".
2. **Assinatura** dentro do grupo:
   - Nome de referência `Arquemestre Mensal` · **ID do produto `arquemestre_mensal`** (exatamente esse: o app procura por ele).
   - Duração **1 mês** · Disponibilidade: os mesmos países do app.
   - **Preço:** país base **Brasil, R$ 29,90** → "Próximo" e aceite os preços que a Apple calcula pros outros países (EUA fica perto de US$ 5,99; dá pra ajustar).
   - Compartilhamento familiar: **desligado**.
   - Localizações:

| Idioma | Nome de exibição | Descrição |
|---|---|---|
| Português (Brasil) | Arquemestre Mensal | Tudo liberado: medição, móveis, corte, orçamento e agenda. |
| English (U.S.) | Arquemestre Monthly | Everything unlocked: measuring, cabinets, cutting, quotes, schedule. |
| Spanish (Mexico) | Arquemestre Mensual | Todo liberado: medición, muebles, corte, presupuesto y agenda. |

3. **Oferta introdutória** (página da assinatura → Preço da assinatura → ＋ → "Criar oferta introdutória"):
   - todos os países · início: hoje · sem data de fim · tipo **Teste grátis** · duração **3 dias**.
   - A Apple só oferece a quem nunca assinou nesse grupo (o app lê isso sozinho e esconde o "3 dias grátis" de quem já usou).
4. **Informações para a revisão** (fim da página da assinatura):
   - **Captura de tela:** a tela de assinatura do app, ramo `ci/ios-resultados` → `capturas/iphone-6-trial.png` (português) — mostra preço, 3 dias grátis, renovação, cancelar, restaurar, gerenciar, privacidade e termos.
   - **Notas da revisão:** `Auto-renewable monthly subscription that unlocks the whole app. 3-day free trial for new subscribers (introductory offer). No login needed: tap "Start 3 days free" on the first screen and confirm with your Sandbox account.`
5. **Notificações do servidor da App Store:** não precisa (o app não tem servidor; o StoreKit 2 confere tudo no aparelho).
6. O status da assinatura fica **"Pronto para enviar"** quando todos os campos acima estiverem preenchidos.

### Juntar a assinatura à versão (sem enviar agora)
- Na página da versão **1.0** → seção **"Compras dentro do app e assinaturas"** → **＋** → marque `arquemestre_mensal` → Concluído.
- A primeira assinatura **só vai pra revisão junto com uma versão do app**. Deixe assim e **não toque em "Enviar para revisão"** até terminar os testes no Sandbox (abaixo).
- Na descrição da ficha já está o link dos **Termos de uso (EULA padrão da Apple)** e da **Política de privacidade** (a Apple exige os dois pra apps com assinatura).

### O que o app faz (regras 3.1.1 e 3.1.2 da Apple)
- **Antes de assinar** (primeira tela): preço mensal em destaque ("R$ 29,90 por mês"), "3 dias grátis, depois R$ 29,90 por mês",
  que renova sozinho, que o teste só começa quando a Apple confirma, como cancelar (Ajustes › seu nome › Assinaturas, até 24 h antes),
  botões **Começar 3 dias grátis**, **Já assino · restaurar compras**, **Gerenciar assinatura** e os links **Privacidade** e **Termos de uso (EULA)**.
- **Depois da confirmação da Apple:** tudo liberado. Na biblioteca aparece "Teste grátis · falta X"; se a pessoa desligar a renovação,
  aparece até quando vale; se a cobrança falhar, o app avisa e continua liberado no período de carência da Apple.
- **Compra pendente** (Ask to Buy / aprovação): não libera até a Apple aprovar.
- **Acesso validado só pela assinatura** (transações assinadas pela Apple, StoreKit 2). Sem senha manual. Funciona sem internet com a última confirmação.
- **Expirou, cancelou e acabou o período, ou houve reembolso:** as telas bloqueiam na hora certa (o app confere no fim do período e ao voltar pro app),
  **nenhum projeto, nota, orçamento ou agenda é apagado**, e a tela de bloqueio tem "Salvar uma cópia dos meus dados (backup)", restaurar e assinar de novo (sem 2º teste grátis).
- Reinstalou ou trocou de iPhone com o mesmo Apple ID: "Já assino · restaurar compras" (ou o app já reconhece sozinho ao abrir).

## Testes da assinatura

### Já testado (automático, a cada envio de código, no CI do GitHub)
Arquivo `ios/ArquemestreTests/SubscriptionTests.swift`, com o **StoreKit Testing do Xcode** (arquivo `Arquemestre.storekit`, igual à loja:
`arquemestre_mensal`, 1 mês, R$ 29,90, oferta grátis de 3 dias) rodando o código de verdade do app (`LicenseManager`) no simulador:
1. Antes de assinar: preço R$ 29,90, 1 mês, 3 dias grátis, conta elegível, **nada liberado**.
2. Teste grátis **só começa depois da confirmação**: status "teste", fim em 3 dias, renovação ligada, sem direito a 2º teste.
3. Compra pendente (Ask to Buy): **não libera**.
4. **Renovação** depois do teste: vira assinatura paga, período de 1 mês.
5. **Cancelamento** (renovação desligada): continua liberado até o fim do período.
6. **Expiração:** bloqueia e **o projeto salvo continua lá**.
7. Assinar de novo depois de expirar: **sem 2º teste**, já pago.
8. **Reembolso:** tira o acesso.
9. **Restaurar** em outra instalação com o mesmo Apple ID: liberado, sem senha.
10. Restaurar sem assinatura: continua bloqueado, com aviso.

Resultado (27/10/2026, execução 39 do CI, Xcode 26.6): **11 de 11 passaram** (o 11º é um diagnóstico que confere se a loja de teste
devolve `arquemestre_mensal` por R$ 29,90). O resumo fica no ramo `ci/ios-resultados` → `RESUMO.txt`, parte "Assinatura (StoreKit)".

> Isso é o ambiente local de testes do Xcode, que simula a App Store. **Não é o Sandbox dos servidores da Apple.**
> Esses testes rodam num simulador **iOS 26.2**: no iOS 26.3 em diante o `xcodebuild test` não carrega o arquivo `.storekit`
> (erro "SKInternalErrorDomain Code=3", bug conhecido da Apple, FB22237318). O app em si roda normal em qualquer iOS 17+;
> isso afeta só a ferramenta de teste.

### Falta (só dá pra fazer com a sua conta Apple): teste no Sandbox
Pré-requisitos: contrato de Apps pagos ativo, assinatura e oferta criadas (acima), build no **TestFlight** (Actions → iOS CI → Run workflow → "Enviar para o TestFlight").
No TestFlight a compra usa o Sandbox automaticamente, sem cobrar. Para repetir o teste grátis, crie um **testador Sandbox** em
App Store Connect → Usuários e acesso → **Sandbox** e, no iPhone, entre com ele em Ajustes › App Store › **Conta Sandbox**.

No Sandbox o tempo anda rápido (aproximado): **3 dias de teste ≈ 2 min**, **1 mês ≈ 5 min**; a renovação automática repete algumas vezes e para sozinha.
No iPhone, Ajustes › App Store › Conta Sandbox › **Gerenciar** permite cancelar e mudar a velocidade das renovações.

| # | Teste | Como fazer | Esperado |
|---|---|---|---|
| 1 | Tela antes de assinar | Instalar e abrir | Preço R$ 29,90/mês, 3 dias grátis, renovação, como cancelar, restaurar, gerenciar, Privacidade, Termos |
| 2 | Compra + teste grátis | "Começar 3 dias grátis" → confirmar com a conta Sandbox | Só libera depois da confirmação; selo "Teste grátis · falta …" |
| 3 | Renovação | Esperar ~2 min | Selo some (assinatura paga); app continua liberado |
| 4 | Cancelamento | Ajustes › App Store › Conta Sandbox › Gerenciar → cancelar | Selo "Assinatura até …"; continua liberado até o fim |
| 5 | Expiração | Esperar o fim do período após cancelar (~5 min) e voltar pro app | "Sua assinatura terminou"; notas e projetos continuam lá; backup funciona |
| 6 | Restaurar | Apagar e instalar de novo → "Já assino · restaurar compras" | Volta liberado sem senha (se a assinatura estiver ativa) |
| 7 | 2º teste | Com a mesma conta Sandbox, assinar de novo | Sem "3 dias grátis"; cobra o mês direto (no Sandbox, sem cobrança real) |
| 8 | Novo teste do zero | App Store Connect → Usuários e acesso → Sandbox → testador → **Limpar histórico de compras** | Volta a oferecer 3 dias grátis |

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

Assinatura mensal de R$ 29,90 com 3 dias grátis para quem nunca assinou. A assinatura renova automaticamente todo mês, a menos que seja cancelada pelo menos 24 horas antes do fim do período; cancele quando quiser em Ajustes › seu nome › Assinaturas.
Funciona sem internet e sem cadastro: seus dados ficam no seu aparelho.

Política de privacidade: https://adautoaraujo414-pixel.github.io/Arqueiro-measure/privacidade.html
Termos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
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

Monthly subscription with a free 3-day trial for new subscribers. The subscription renews automatically every month unless canceled at least 24 hours before the end of the current period; cancel anytime in Settings › your name › Subscriptions.
Works offline and with no sign-up: your data stays on your device.

Privacy Policy: https://adautoaraujo414-pixel.github.io/Arqueiro-measure/privacy.html
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
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

Suscripción mensual con 3 días gratis para quien nunca se suscribió. La suscripción se renueva automáticamente cada mes, salvo que se cancele al menos 24 horas antes del fin del periodo; cancela cuando quieras en Ajustes › tu nombre › Suscripciones.
Funciona sin internet y sin registro: tus datos quedan en tu equipo.

Política de privacidad: https://adautoaraujo414-pixel.github.io/Arqueiro-measure/privacidad.html
Términos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

## Notas para a revisão da Apple (colar em "Notas", em inglês — o revisor lê em inglês)
```
Arquemestre is a professional work tool for woodworkers and cabinet makers (measuring, 3D furniture design,
cut lists, PDF quotes and job scheduling). There is no login and no account; all data stays on the device.

Subscription: the app is free to download and is unlocked by one auto-renewable subscription, "Arquemestre Monthly"
(arquemestre_mensal, 1 month, R$ 29.90 in Brazil), with a 3-day free trial introductory offer for new subscribers.
The trial starts only after the purchase is confirmed by Apple. The first screen shows the monthly price, the trial length,
the auto-renewal terms, how to cancel, Restore Purchases, Manage Subscription, and links to the Privacy Policy and
Terms of Use (Apple standard EULA). There are no other purchases, no passwords and no external payment links.
To test: tap "Start 3 days free" and confirm with a Sandbox account. When the subscription ends, the screens lock
but all saved data stays on the device (a backup button is offered). The subscription provides ongoing value:
regular updates with new furniture modules, catalog items and features, plus e-mail support.

Laser measure: the app can receive measurements from Bosch laser measures with Bluetooth (tested with the GLM 50-27 CG) over Bluetooth LE.
Without the device, open a note, tap any dimension label and type the value on the in-app keypad — every feature works.

Live project view: between two devices with the app (local peer-to-peer network), view only.
Languages: Portuguese, English and Spanish (follows the device; can be changed in ⋯ → Language).
```
