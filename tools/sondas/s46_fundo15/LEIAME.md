# s46 — fundo 15 mm: projeto antigo abre igual, 3 e 6 mm iguais ao centavo (24/11/2026)

Gera, no editor PUBLICADO, os 139 projetos da s45 (um por modelo do catálogo + cozinha de exemplo) e, opcionalmente,
os projetos do backup rico (`rico.json`: `{nome: {st: snapState em texto}}`). Abre cada um na versão de BASE e na NOVA
e compara 14 campos (`assinatura.js`): peças (partsOf, com espessura), corte (cutGroups), fundo e profundidade
(fundo, fundoPia, fundoMm, tipo, fBack, d + fundo), orçamento com preços fixos (total, chapas por tipo, custo por tipo,
valor de cada módulo, linhas de preço) e DXF (nome, medida, espessura, furos, rasgos).

Sem servidor: abre os editores por file://.

    NODE_PATH=$(npm root -g) node compara.js <pasta_publicada> <pasta_base> <pasta_nova> <ponte.js da bateria> [rico.json]

Resultado (claude/fundo-15mm contra 553745a1, projetos gerados no iOS 3.0.13 / 3f1c3a58):
141 projetos (139 + 2 do backup rico), 152 módulos com fundo, **0 diferenças** em 14 campos.
