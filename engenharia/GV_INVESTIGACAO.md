# Investigação do `gv` (17/11): ler um vão pode criar vãos (nada mudado no app)

**Versões:** investigado em `9561fcd` (Fase 2) e conferido em `9ec0869` (homologada). O resultado é o mesmo nas duas, salvo onde está indicado.

**Sondas:** `tools/sondas/s42_gv_leitura_cria_vao.js` e `s43_gv_caminhos_que_reduzem_vaos.js`.

## O que é o `gv`
```js
function gv(i,mm){var m=mm||S.m;while(m.v.length<=i)m.v.push({k:'free',n:1,…});return m.v[i]}
```
- O número de vãos de um módulo é **divisórias + 1** (`nv()`).
- A lista `m.v` guarda a configuração de cada vão e é preenchida **sob demanda**: na primeira leitura de um vão que existe, ele é criado com os valores padrão.
- **Causa raiz do risco:** o `gv` não confere se `i` é um vão que existe. Com `i` ≥ divisórias + 1, ele **acrescenta vãos que não correspondem a divisória nenhuma**.
  - Exemplo: `gv(5)` num módulo de 1 vão deixa `m.v` com 6 itens.

## Quem chama: 66 chamadas
| Origem do número do vão | Chamadas | Pode pedir vão que não existe? |
|---|---|---|
| Vão escolhido `S.sv` | 32 | **Sim**, se `S.sv` ficar velho (ver os caminhos abaixo) |
| Número do vão tocado (`vi`: menu do vão, internos, portas) | 27 | Só se o móvel mudar com o menu aberto. Não reproduzido: os menus fecham ao agir |
| Laços sobre os vãos existentes (`partsOf`, desenho) | 4 | Não |
| Arrasto em andamento e casos pontuais | 3 | Não reproduzido |

## Caminhos que levam a um vão que não existe
| Caminho | `S.sv` inválido? | Criou vão? | Em `9ec0869` | Em `9561fcd` |
|---|---|---|---|---|
| Tocar em outro módulo pelo 3D e ler o vão escolhido | sim | **sim** (1 → 3) | erro | **corrigido** (SEL-VAO: acessor de `S.m`) |
| Abrir outro projeto | — | — | coberto pelos painéis | coberto (SEL-ESTADO) |
| 🗑 numa divisória escolhida | não (o app acerta `S.sv`) | não | certo | certo |
| Desfazer para menos divisórias | não | não | certo | certo |
| **"Limpar divisões"** (aba Divisões) | sim, até a próxima aba corrigir | não (a lista já era maior) | ver abaixo | ver abaixo |
| Outras camadas que mudam `m.div` direto no mesmo módulo | sim, até a próxima aba corrigir | só se `S.sv` ≥ tamanho de `m.v` | risco | risco |
| Chamada direta `gv(i)` com `i` grande | — | **sim** | risco | risco |

**"Limpar divisões"** zera as divisórias e **não encurta** `m.v`. Ficam guardados vãos que não existem mais.
- Nos testes, isso **não afeta nada**: a ação seguinte cai no vão certo (o painel corrige `S.sv`).
- Peças, corte e 3D são os mesmos, a aba Divisões mostra o número certo de vãos.
- Pôr divisórias de novo **não traz** os vãos antigos de volta (os vãos novos saem do vão que foi dividido).

## Projetos antigos que já têm vãos sobrando gravados
Sonda s43, parte 2: módulo com 1 divisória e 4 vãos gravados.
- Peças, plano de corte e 3D: **iguais** aos de sem a sobra. A fabricação lê só os vãos que existem.
- Ao abrir, **nada é tirado sozinho**, e a sobra continua gravada.
- A aba Divisões mostra 2 vãos (o certo).
- **Conclusão:** a sobra é dado parado. Não muda o móvel, a lista de peças nem o corte.

## Correção possível (para aprovação, nada implementado)
- **Opção 1 (mínima):** com `i` ≥ divisórias + 1, o `gv` devolve um vão padrão **sem gravar** no módulo e não cria nada.
  - Efeito em projeto antigo: **nenhum**. O que já está gravado fica como está (sem migração) e continua sem efeito na fabricação.
  - Risco: algum caminho que dependa de o `gv` criar vão além das divisórias. Nos 142 modelos do catálogo nenhum tem vãos além de divisórias + 1, e nenhum fluxo testado faz isso. Precisa da bateria completa e das sondas.
- **Opção 2 (complementar):** quando as divisórias do **mesmo** módulo diminuem (Limpar divisões e outras camadas), o vão escolhido volta para um vão que existe na hora, sem esperar a próxima aba.
  - É estado de tela, não vai para o arquivo.
- **Não recomendado agora:** tirar a sobra já gravada nos projetos.
  - Seria uma mudança de dados em projeto existente (migração), sem nenhum ganho de fabricação, porque a sobra não muda nada.
  - Pela regra §3/§11.7, projeto antigo não muda sozinho.
