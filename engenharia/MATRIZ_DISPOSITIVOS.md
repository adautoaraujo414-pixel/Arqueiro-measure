# Matriz de dispositivos (ETAPA 3 · item 3.6, Adauto 28/11/2026)

> **Não temos aparelho físico aqui.** Nenhuma linha desta matriz foi conferida em iPhone, iPad, celular Android ou computador Windows de verdade.
> Tudo o que está marcado como testado foi em **simulador do Xcode (CI)**, **emulador Android (CI)** ou **Chromium sem tela** neste servidor (bateria `tools/bateria_editor.py` com `--janela LxAxDENSIDADE`).
> O editor (`app/src/main/assets/editor.html`) é o mesmo arquivo nas 3 plataformas. O motor muda:
> - iOS: WKWebView, WebKit;
> - Android: WebView, Chromium do sistema;
> - Windows: JCEF, Chromium embutido.

## 1. Tamanhos (área do editor em pontos CSS, retrato × densidade)
| Classe | Aparelho de referência | Pontos (L × A) | Densidade | Pixels da tela |
|---|---|---|---|---|
| iPhone compacto | iPhone SE (3ª ger.) | 375 × 667 | 2 | 750 × 1334 |
| iPhone compacto moderno | iPhone 13 mini | 375 × 812 | 3 | 1080 × 2340 |
| iPhone comum | iPhone 16 / 17 | 393 × 852 / 402 × 874 | 3 | 1179 × 2556 / 1206 × 2622 |
| iPhone Plus | iPhone 16 Plus | 430 × 932 | 3 | 1290 × 2796 |
| iPhone Pro | iPhone 16 Pro / 17 Pro | 402 × 874 | 3 | 1206 × 2622 |
| iPhone Pro Max | iPhone 16 Pro Max / 17 Pro Max | 440 × 956 | 3 | 1320 × 2868 |
| iPad pequeno | iPad mini (A17 Pro) | 744 × 1133 | 2 | 1488 × 2266 |
| iPad comum | iPad (A16) / iPad Air 11" | 820 × 1180 | 2 | 1640 × 2360 |
| iPad grande | iPad Pro 13" (M4/M5) | 1032 × 1376 | 2 | 2064 × 2752 |
| Android celular comum | Galaxy A-series (1080 × 2340) | ≈ 360 × 780 | ≈ 3 | 1080 × 2340 |
| Android celular grande | Pixel 8 Pro / Galaxy S Ultra | ≈ 412 × 892 | ≈ 3,5 | 1344 × 2992 / 1440 × 3120 |
| Android tablet | Galaxy Tab S9 FE (2304 × 1440) | ≈ 1280 × 800 (paisagem) | ≈ 1,8 | 2304 × 1440 |
| Windows notebook | 1366 × 768 a 100% | 1366 × 768 | 1 | 1366 × 768 |
| Windows Full HD | 1920 × 1080 a 125% | 1536 × 864 | 1,25 | 1920 × 1080 |
| Windows QHD | 2560 × 1440 a 150% | 1707 × 960 | 1,5 | 2560 × 1440 |

Os valores com "≈" variam de modelo pra modelo, e a densidade é a que o Android informa. Os do Android e do Windows são de referência e não foram medidos num aparelho.

## 2. Onde cada tamanho é testado hoje
| Tamanho | Onde roda | Bateria inteira? | Aparelho físico |
|---|---|---|---|
| iPhone Pro Max (440 × 956 × 3) | **simulador** no `ios.yml` (`pick_sim.py iphone`: 17 Pro Max → 16 Pro Max → 17 Pro → 16 Plus → 17), passos A + B | sim (641 testes) | **não** |
| iPad Pro 13" (1032 × 1376 × 2) | **simulador** no `ios.yml`, job `ipad` (`pick_sim.py ipad`) | sim | **não** |
| iPhone 6,9" e iPad 13" | **simulador**, capturas de tela (`screenshots.sh`) | não, só capturas | **não** |
| iPhone 17 Pro / 16 Pro / 16 / 15 | **simulador**, só os testes da assinatura (StoreKit) | não | **não** |
| Atualização por cima (iPhone e iPad) | **simulador**, `ios-atualizacao.yml` (vídeo) | não, só o roteiro da atualização | **não** |
| Android | **emulador** API 30 x86_64 (`android-atualizacao.yml`, roteiro da atualização); `android.yml` compila e gera o APK de teste | não | **não** |
| Windows 1366 × 768 | **CI** `windows.yml`: o app (JCEF) aberto com `ARQUE_BATERIA=1`, bateria pelo CDP | sim | **não** (é o Chromium do app, mas no servidor do GitHub) |
| 1366 × 768 × 1 e 430 × 900 × 3 | **Chromium sem tela** neste servidor (`bateria_editor.py`) | sim | **não** |
| 375 × 667 × 2 (iPhone SE) e 820 × 1180 × 2 (iPad comum) | **Chromium sem tela** neste servidor, a partir de 28/11 (seção 3) | sim | **não** |

**Nunca testados em nenhum lugar:**
- iPhone compacto no WebKit (o SE só roda no Chromium);
- iPhone comum, Plus e Pro na bateria;
- iPad mini e iPad comum no WebKit;
- celular Android (tela pequena, WebView);
- tablet Android;
- Windows com escala de 125% e 150%.

## 3. Rodadas a mais no Chromium (sem custo de CI)
Integração 3 (`888603db`), bateria inteira de 641 testes: resultado na seção 5.

## 4. Proposta para o `ios.yml` (sem aumentar nenhum limite de tempo)
A bateria inteira não cabe em mais um simulador: o iPhone já usa 2 passos de 75 min e o iPad 100 min. A proposta usa o tempo que já existe:
1. **Capturas de tela em mais 2 tamanhos.**
   - O passo de capturas (`screenshots.sh`) passa a abrir também o **iPhone SE (3ª ger.) 375 × 667** e o **iPhone 17 / 16 (402/393 × 874/852)**, além do 6,9" e do 13".
   - Custo: alguns minutos.
   - Pega tela que não cabe, botão escondido e painel cortado no WebKit dos menores.
2. **Bateria de toque e layout nos 2 tamanhos novos.**
   - Um passo novo, só com `-only-testing` dos testes de toque, seleção, painel e 430 (os que dependem da tela).
   - Roda dentro do job do iPad, que hoje termina antes dos 210 min.
   - O limite do passo fica nos mesmos 40 min de um passo comum e o limite do job não muda.
3. **iPad mini (744 × 1133)** no lugar do iPad 13" **em dias alternados**: não. Trocaria uma cobertura por outra. Fica só nas capturas do item 1, se o Adauto quiser.

Precisa da autorização do Adauto (mexe no CI). Não foi feito.

## 5. Resultado das rodadas a mais
(preenchido quando as baterias de 375 × 667 × 2 e 820 × 1180 × 2 terminarem)
