# Editor por vãos em todos os módulos (ramo `exp/editor-vaos-universal`, não integrado)

Pedido do Adauto em 16/11 às 08:21. O ramo é separado: nada daqui está na versão principal até ele aprovar.

## Regras dadas por ele
- Aproveitar o editor por vãos que já existe (guarda-roupa e torre), sem criar um editor novo.
- O mesmo conjunto de ferramentas em todos os módulos, respeitando os limites de cada tipo.
- **Aéreo não tem gaveta** (16/11 às 08:31).
- Não alterar projeto existente sozinho, não inventar peça, não duplicar divisória e não trocar componente sem avisar.

## Auditoria (16/11)
- O editor por vãos (`rt`, funções `rg*`) já tem:
  - divisão horizontal e vertical;
  - porta de 1 a 4 folhas, basculante, vidro e tampa cega;
  - gaveta por dentro e por fora;
  - prateleira com recuo e engrosso;
  - eletros, sapateira e cabideiro.
- Hoje ele só entra em módulo alto (1500 mm ou mais), em módulo empilhado e no "montar do zero". Balcão e aéreo usam o menu antigo, com uma coisa por coluna.
- **Teste de conversão dos 136 modelos do catálogo, comparando as peças:**
  - Antes deste trabalho: 28 iguais, 51 não convertem, 46 mudam de peça.
  - **Erro que já existe no app:** "Só ele no 2D" converte módulo alto sozinho e muda peças, por exemplo 2P 600mm com 4 prateleiras que viram 3, e o caixote que vira outra estrutura.

## Fase 1 (feita no ramo)
- **Trava:** só converte se as peças ficarem idênticas (`rgSig`, que compara nome, medida de corte, material, posição, puxador e dobradiça). Senão, fica no editor de antes.
- **Regra das frentes no módulo convertido** (`rgFr`), na mesma conta do módulo comum (`tXOf`):
  - cobre a travessa frontal;
  - fica 4 mm abaixo do topo sem puxador de borda;
  - com cava, passa 20/10 (no aéreo, a espessura).
  - A moldura conta as frentes da árvore.
- **Resultado:** 29 modelos convertem idênticos, incluindo todos os balcões e aéreos simples.

## Falta (próximas fases)
- Gavetas de cozinha, basculante do aéreo, vidro, tempero, forno, correr, canto e geladeira. Hoje não convertem.
- Nome das peças ("Divisória 1" e "Divisória", "Prateleira interna" e "Prateleira").
- Distribuição das prateleiras igual à do módulo comum.
- Caixote do guarda-roupa.
- Liberar o editor por vãos no balcão e no aéreo pelo toque no vão, quando a conversão for exata.
- Exemplo do Adauto: balcão de pia 800×720×560, basculante em cima e gaveta embaixo.
