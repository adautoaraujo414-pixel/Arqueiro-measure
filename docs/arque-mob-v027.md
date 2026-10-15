# Arque Mob v0.27 — integração da folha 2D e zoom suave

Ramo de testes isolado derivado da v0.26, preservando fechamento lógico de contornos e todos os recursos 2D.

- Pinça de dois dedos com coordenadas de tela e âncora fixa sob o centro dos dedos; zoom e movimento simultâneos.
- Etiquetas horizontais ao lado de linhas verticais, inclusive descendentes; etiquetas de medidas calculadas e digitadas respeitadas.
- Medidas ao puxar mostradas como prévia em cm; confirmação de dimensão real é manual.
- Desfazer/refazer, cores, mão livre, notas que podem crescer/encolher, visualização de espessura retangular, setas nas pontas, Fundir ligado/desligado, Cantos 90°, calculadora que abre, fecha e arrasta.
- Código 3D e dados anteriores preservados; a interface continua somente 2D.
- Regra de fechamento v0.26 preservada: calcula uma medida somente quando as medidas confirmadas fornecem um caminho único. Não faz leitura real do ambiente.
- Testes locais Playwright com três tamanhos de tela (1180x780, 820x1180 e 390x844), incluindo pinça ancorada, rótulo vertical, geometria, nota e calculadora; além da compilação CI Android e seus testes JS.

Limitações: sem teste real com S Pen/Tab S9 e sem validação do plano de corte para produção. Recomenda-se exportar backup de clientes e obras antes de atualizar o APK.
