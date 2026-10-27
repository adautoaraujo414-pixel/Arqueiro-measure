# Arquemestre no Google Play — guia de lançamento

O app (versão `play`) já está pronto pra loja:
- **Assinatura mensal** pelo Google Play Billing 8: produto `arquemestre_mensal`, plano básico `mensal` (R$ 29,90/mês),
  oferta de teste grátis `teste-3-dias` (3 dias, só pra quem nunca assinou).
- Tela de assinatura com o preço em destaque, os dias grátis, renovação automática, como cancelar,
  "Já assino · restaurar", "Gerenciar assinatura" (abre a tela de assinaturas do Google Play), Privacidade e Ajuda.
- Sem assinatura ativa, as telas ficam bloqueadas, mas os dados continuam e dá pra fazer backup.
- A versão da loja **não se atualiza sozinha** (o atualizador pelo GitHub e a permissão de instalar apps só existem no APK do site),
  como a Google Play exige.
- Idiomas: Português, English, Español. `targetSdk 36`.
- Cada build gera o **`Arquemestre-GooglePlay.aab`** já assinado com a chave de upload, junto com o APK, na página de releases do GitHub.

## O que falta (em ordem) — só você pode fazer
1. **Conta no Play Console** (US$ 25, uma vez só): play.google.com/console.
   - **Conta de pessoa física nova:** o Google obriga um **teste fechado com pelo menos 12 testadores por 14 dias seguidos**
     antes de liberar a produção. Junte 12 pessoas (clientes, marceneiros) com conta Gmail.
   - **Conta de organização (CNPJ):** não tem essa exigência, mas pede o número **D-U-N-S** da empresa (gratuito, sai em alguns dias pelo site da Dun & Bradstreet).
2. **Perfil de pagamentos** (Configurar › Perfil de pagamentos): conta bancária e dados fiscais. Sem isso não dá pra vender assinatura.
3. **Criar o app:** nome "Arquemestre", idioma padrão Português (Brasil), App, Pago? → **Gratuito** (a cobrança é pela assinatura dentro do app).
4. **Subir o primeiro AAB** numa faixa de teste (Teste interno ou Teste fechado): baixe o `Arquemestre-GooglePlay.aab` do último release
   e aceite a "Assinatura de apps do Google Play".
5. **Criar a assinatura** (Monetizar › Produtos › Assinaturas) — só aparece depois do passo 4:
   - ID do produto: **`arquemestre_mensal`** · Nome: "Arquemestre Mensal" (en: "Arquemestre Monthly"; es: "Arquemestre Mensual").
   - Benefícios: "Tudo liberado: medição, móveis, corte, orçamento e agenda".
   - **Plano básico:** ID **`mensal`** · Renovação automática · Período **1 mês** · Preço **R$ 29,90** (BRL) → "Atualizar preços dos outros países" (o Google converte; nos EUA fica perto de US$ 5,99) · Período de carência padrão · Permitir nova assinatura: sim → **Ativar**.
   - **Oferta:** ID **`teste-3-dias`** · Qualificação: "Aquisição de novos clientes — nunca teve esta assinatura" · Fase: **Teste sem custo financeiro, 3 dias** → **Ativar**.
   - (Os IDs têm que ser exatamente esses: o app procura por eles.)
6. **Teste de licença** (Configurações › Teste de licença): coloque seu Gmail. Assim você assina de teste sem ser cobrado.
7. **Conteúdo do app** (Política › Conteúdo do app) — respostas abaixo.
8. **Ficha da loja** em pt-BR, en-US e es-419 — textos abaixo. Gráficos em `docs/play/` (ícone 512, destaque 1024×500, capturas).
9. **Produção:** depois do teste (ou direto, se for conta de organização), promova o build pra Produção e envie pra revisão.
   A primeira revisão costuma levar de alguns dias a 1 semana.

## Respostas do "Conteúdo do app"
- **Política de privacidade:** `https://adautoaraujo414-pixel.github.io/Arqueiro-measure/privacidade.html`
- **Acesso ao app:** "Algumas funcionalidades são restritas" → instruções (em inglês):
  `All features require the monthly subscription "Arquemestre Monthly". On the first screen tap "Start 3 days free" to begin the free trial with a Google Play test account (license testing). No login or account is needed. Without a Bosch laser measure, tap any dimension label and type the value on the in-app keypad.`
- **Anúncios:** Não, o app não tem anúncios.
- **Classificação do conteúdo:** categoria "Utilitário, produtividade, comunicação ou outro"; responda "não" a tudo → Livre.
- **Público-alvo:** 18 anos ou mais (ferramenta de trabalho; não é pra crianças). Não atrai crianças.
- **Segurança dos dados:** o app **não coleta nem compartilha** dados do usuário (tudo fica no aparelho; o pagamento é processado pelo Google).
  - Criptografia em trânsito: não se aplica (não envia dados). Exclusão de dados: o usuário apaga no app ou desinstalando.
- **Apps de notícias / saúde / finanças / governo:** não.
- **Permissões:** Bluetooth (trena a laser e compartilhar projeto), câmera (fotos da obra), notificações e alarmes (agenda).
  A permissão de localização só existe no Android 11 ou anterior, porque o sistema exige pra procurar aparelhos Bluetooth; o app não usa localização.

## Ficha da loja

### Português (Brasil)
- **Nome (30):** Arquemestre
- **Descrição curta (80):** Medição com trena laser, móveis em 3D, lista de corte, orçamento e agenda.
- **Descrição completa:**
```
O Arquemestre junta a medição, o projeto, o corte, o orçamento e a agenda da sua marcenaria num lugar só.

📏 MEDIÇÃO
• Crie uma nota, tire foto da obra ou desenhe o croqui à mão.
• Ligue a trena laser Bluetooth (testada com a Bosch GLM 50-27 CG): a medida cai direto na cota, com milímetro.
• Sem trena? Toque na medida e digite no teclado do app.

🪚 EDITOR DE MÓVEIS
• Monte cozinha, guarda-roupa, painel e sala com regras de marcenaria prontas.
• Veja em 3D, abra portas e gavetas, estique peças arrastando.

📋 CORTE E ORÇAMENTO
• Lista de peças com medidas de corte, plano das chapas inteiras e custo do material.
• Orçamento em PDF com a sua logo, pronto pra mandar no WhatsApp.

📅 AGENDA
• Entregas, visitas e medições ligadas a cada cliente, com aviso antes.

🔒 SEUS DADOS FICAM COM VOCÊ
• Funciona sem internet e sem cadastro. Nada vai pra servidor.

ASSINATURA
• R$ 29,90 por mês, com 3 dias grátis para quem nunca assinou.
• Renova automaticamente; cancele quando quiser em Google Play › Pagamentos e assinaturas.

Disponível em Português, English e Español.
Arquemestre não é afiliado à Bosch nem a outros fabricantes de trenas.
```

### English (United States)
- **Name (30):** Arquemestre
- **Short description (80):** Laser measuring, 3D cabinet design, cut lists, quotes and scheduling.
- **Full description:**
```
Arquemestre puts your woodshop's measuring, design, cutting, quotes and schedule in one place.

📏 MEASURING
• Create a note, take a photo of the job site or sketch by hand.
• Connect a Bluetooth laser measure (tested with the Bosch GLM 50-27 CG): the reading drops straight into the dimension.
• No laser? Tap the measurement and type it on the in-app keypad.

🪚 FURNITURE EDITOR
• Build kitchens, wardrobes, panels and living rooms with ready-made woodworking rules.
• See them in 3D, open doors and drawers, stretch parts by dragging.

📋 CUTTING AND QUOTES
• Parts list with cut sizes, full-board cutting plan and material cost.
• PDF quote with your logo, ready to send.

📅 SCHEDULE
• Deliveries, visits and measuring linked to each client, with reminders.

🔒 YOUR DATA STAYS WITH YOU
• Works offline, no sign-up. Nothing goes to a server.

SUBSCRIPTION
• Monthly subscription with a free 3-day trial for new subscribers (price shown by Google Play in your country).
• Renews automatically; cancel anytime in Google Play › Payments & subscriptions.

Available in English, Português and Español.
Arquemestre is not affiliated with Bosch or other laser measure makers.
```

### Español (Latinoamérica)
- **Nombre (30):** Arquemestre
- **Descripción corta (80):** Medición láser, muebles en 3D, lista de corte, presupuesto y agenda.
- **Descripción completa:**
```
Arquemestre reúne la medición, el proyecto, el corte, el presupuesto y la agenda de tu carpintería en un solo lugar.

📏 MEDICIÓN
• Crea una nota, toma una foto de la obra o dibuja el croquis a mano.
• Conecta el medidor láser Bluetooth (probado con el Bosch GLM 50-27 CG): la medida cae directo en la cota.
• ¿Sin láser? Toca la medida y escríbela en el teclado de la app.

🪚 EDITOR DE MUEBLES
• Arma cocinas, roperos, paneles y salas con reglas de carpintería listas.
• Míralos en 3D, abre puertas y cajones, estira piezas arrastrando.

📋 CORTE Y PRESUPUESTO
• Lista de piezas con medidas de corte, plano de tableros enteros y costo del material.
• Presupuesto en PDF con tu logo, listo para enviar.

📅 AGENDA
• Entregas, visitas y mediciones ligadas a cada cliente, con avisos.

🔒 TUS DATOS QUEDAN CONTIGO
• Funciona sin internet y sin registro. Nada va a un servidor.

SUSCRIPCIÓN
• Suscripción mensual con 3 días gratis para quien nunca se suscribió (precio que muestra Google Play en tu país).
• Se renueva automáticamente; cancela cuando quieras en Google Play › Pagos y suscripciones.

Disponible en Español, English y Português.
Arquemestre no está afiliado a Bosch ni a otros fabricantes de medidores láser.
```

## Notas
- **Categoria:** Produtividade.
- **E-mail de contato da ficha:** adautoaraujo414@gmail.com · **Site:** `https://adautoaraujo414-pixel.github.io/Arqueiro-measure/suporte.html`
- O APK do site (GitHub) continua com o desbloqueio por senha; ele não vai pra loja.
