# s45 — projeto salvo na versão PUBLICADA abre igual na versão nova (24/11/2026)

Cria, no editor da versão publicada, um projeto por modelo do catálogo (sozinho na parede) e a cozinha de exemplo; salva (snapState);
abre cada um no editor novo e compara peça por peça (`partsOf`) e o plano de corte (`cutGroups`).

    # editor publicado servido numa porta, o novo em outra (git archive <sha> app/src/main/assets | tar -x)
    NODE_PATH=$(npm root -g) node roda.js <porta_publicada> <porta_nova> <ponte.js da bateria> gera_no_publicado.js confere_na_nova.js

Resultado na candidata do fechamento (24/11), contra iOS 3.0.13 (3f1c3a58) e Android 660 / Windows 166 (c561120):
139 projetos, **corte igual em todos**; lista igual em 138. A única diferença é a cozinha de exemplo: o rodapé lateral do encontro
entre dois balcões (que já não ia pro corte nem pro 3D na publicada) saiu também da lista/orçamento (correção bf2abf6, FASE2).
