# Controle central · ETAPA 2 (Adauto, 26/11/2026)
Ramo de integração: `claude/etapa-2` (base 5067fecc = publicado: apk-725, win-190, iOS 3.0.14 build 713). Cada agente: ramo próprio a partir de `claude/etapa-2`, commits pequenos, o Chefe integra. Não publicar sem o "sim" final do Adauto. DXF continua desligado (DXF_OFF).
Regras do Adauto nesta etapa: só o que foi pedido; não remover nem desfazer nada que funciona; não mudar layout não autorizado; referências = especificação (ver REFERENCIAS.md · ETAPA 2).

| # | Pedido | Responsável | Depende de | Status | Commits / testes / evidência |
|---|---|---|---|---|---|
| 1 | Espelhos: "Equilibrado" só na config do espelho (sai do 3D); Jateado em todo espelho com LED; botão do LED; realismo do vidro | Claude 3 | — | a fazer | |
| 2 | Juntar bases lado a lado (≤2700 mm), escolher módulos, dividir acima de 2700, L com base atravessada, unir/separar/desfazer, nunca automático | Code 2 | confirmar com Adauto qual "base" | a fazer | |
| 3 | Dobradiças metálicas (não da cor da porta), caneco/braço/calço, movimento em todo o percurso | Claude 3 | — | a fazer | |
| 4 | Porta do forno sem atravessar (eixo real); relógio do forno = hora do aparelho; texturas/realismo sem perder desempenho | Claude 3 | — | a fazer | |
| 5 | Portas do canto (1ª e 2ª) abrindo 165°, juntas e separadas, balcão/aéreo/guarda-roupa, espelhados, sem mudar a estrutura | Claude 3 | eixos do canto cego (Code 2) | a fazer | |
| 6 | Canto: travessas e régua superior iguais às fotos (cruzamento), no cabeçalho e na Estrutura | Code 2 | dúvidas de medida → Adauto | a fazer | |
| 7 | Canto cego E/D conforme referência; projeto antigo só com botão de atualizar + desfazer | Code 2 | — | a fazer | |
| 8 | Estrutura do canto: desenho A/B, profundidade de cada lado, recuo automático (pedra) ou manual, voltar ao automático | Code 2 | — | a fazer | |
| 9 | Câmera no 2D; editar canto no 2D; pôr módulo ao lado; abrir config do módulo; câmera ≠ arrasto | Claude 4 | desenho A/B (Code 2) | a fazer | |
| 10 | Cabeçalho Divisões: divisórias primeiro, dividir por igual embaixo (nada removido) | Claude 4 | — | a fazer | |
| 11 | Modelos de porta: todos, miniaturas, Usados recentemente (salvo), puxadores embaixo · auditoria de puxadores flutuantes | Claude 4 (tela) · Claude 3 (3D) | — | a fazer | |
| 12 | Cabeçalho tamponamentos: esquerdo, direito, cava, pós-cava, resto | Claude 4 | — | a fazer | |
| 13 | Custos fixos na biblioteca de preços (vários, R$/%, por serviço, motor atual, sem duplicar, cópia no orçamento, fora do PDF/CSV/link) | 1º agente livre | — | a fazer | |
| 14 | Desempenho iOS/Android/Windows: medir antes/depois, corrigir causa | Code 1 | — | a fazer | |
| 18 | Canto ESQUERDO e canto DIREITO (L): tudo dos itens 5, 6 e 8 vale para os dois lados, além do canto cego E/D (Adauto 26/11: "tem canto esquerdo, canto direito") | Code 2 (estrutura) · Claude 3 (165°) | — | a fazer | |
| 19 | Inferiores: composições prontas de frente — 2 gavetas + 1 gavetão; 3 gavetões; 2 gavetas; 1 gaveta + porta basculante; e livre montagem sem limitação. Reusar peças existentes de gaveta/basculante (partsOf), sem fórmula nova | Claude 4 (Code 1 audita fabricação) | — | a fazer | |
| 15 | Controle central e integração | Chefe | — | em andamento | este arquivo |
| 16 | Regras permanentes | todos | — | sempre | |
| 17 | Homologação independente (iPhone, iPad, Android, Windows, update por cima, projetos antigos, prints e vídeos) | Code 1 + Chefe | 1–14 | depois | |
