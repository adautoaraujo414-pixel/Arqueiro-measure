# Regras de marcenaria confirmadas

Cada regra tem a fonte. **(A)** é o Adauto, com a data. **(código)** é conferido no `editor.html`. Regra sem fonte não entra aqui.

## Medidas e chapas
- **Peça sem décimo de milímetro.** A medida de corte é a medida real com o décimo cortado (o décimo vira folga) e a peça nunca fica maior que o desenho. (A, 13/11) (código: `RNDC`)
- **Painéis em MDF 15.** Engrosso são duas camadas de 15 coladas, não chapa de 18. (A, conversa de 09/11)
- **Plano de corte:** aproveitamento máximo da chapa. (A)

## Portas, gavetas e folgas
- **Armário de canto em L:** 3 mm entre as duas folhas. Abre uma e depois a outra; nunca batem. (A, 15/11)
- **Canto em L, profundidade de cada lado:** vem da pedra em cima daquele lado, menos o mesmo desconto dos módulos retos. Exemplo: pedra de 600 de um lado e 650 do outro, cada lado com o seu desconto. (A, 15/11)
- **Forno embutido:** 3 mm entre a parte de cima (travessa) e o topo do forno. O forno é de embutir, então tem que ser preciso. (A, 16/11) (código: `ot=3`)
- **Puxador gola (perfil G):** desconto de 29 mm na altura da porta e da frente (42 de perfil − 13 que abraçam a MDF). Abertura para a frente. Ver `especificacoes/puxador-gola.md`. (A, 11/11, 12/11, 16/11) (código: `gDesc=29`)
- **Puxador escolhido numa porta vale para todas as portas e gavetas do projeto:** de baixo, de cima e de canto. (A, 15/11)
- **Tampa cega e painel cego não abrem:** sem dobradiça e sem puxador. (A, 14/11)
- **Furação da dobradiça:**
  - Padrão inicial de **120 mm** do topo e do pé do **MDF da porta**, nunca do perfil gola. A medida é o **centro do caneco** (furo Ø35 de 102,5 a 137,5).
  - Vale para toda porta de giro, com qualquer puxador: externo, cava, gola ou outro. O puxador nunca muda a distância.
  - Exemplos: porta de 705 com furos a 120 e 585 do topo; porta de 676 (com gola) a 120 e 556.
  - Ajustável em Ajustes.
  - Projeto antigo não muda sozinho.
  - (A, 16/11 07:53 e 08:07) (código: `STDD.furD=120`, `furInfo`; o 3D lê `p.fur.pos`)

## Tamponamento e caixa
- **Tamponamento nunca entra no módulo:** peça inteira por fora. As réguas de 8 cm são coladas só no tamponamento. (A, 15/11)
- **Painéis e módulos são sólidos:** nada entra dentro de outra coisa. (A)
- **Módulo não age sozinho:** não tira tamponamento nem se afasta do vizinho sem o Adauto mandar. (A)
- **Nenhum armário com vão, peça solta, erro de seleção ou erro de porta.** Porta e prateleira vão até o fim. (A)

## Pedra
- **Armário embaixo da pedra com saia:** a frente do armário para na saia e não passa dela. (A, 16/11) (código: `fitNew`, `cornerStoneFit`)
- **Altura do armário embaixo da pedra com saia:** o armário inteiro (caixa e frentes) vai até embaixo da saia; a pedra fica por cima. Embaixo da saia = embaixo da pedra − saia + espessura (ex.: pedra a 820, 30 de espessura, saia de 100 → armário até 750). Vale pra pedra em que a saia foi ligada ou mudada a partir de 16/11; projeto antigo continua como estava até mexer na saia. (A, 16/11 10:39) (código: `stArmTop`, `stAdapta`, `underStone`)

## Pendentes de confirmação (não usar como regra ainda)
- Perfil G encostando na caixa (1,5 mm). Ver a pendência 1 da especificação do gola.
- Engrosso do tamponamento "entrando no módulo": não reproduzido (HISTORICO_ERROS, TAMP-ENGROSSO).
