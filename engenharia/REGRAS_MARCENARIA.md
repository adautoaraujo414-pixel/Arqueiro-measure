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
- **Tamponamento automático é acabamento de lado exposto** (A, 22/11, TAMP-JUNTA): encostou em outro módulo, sai; separou e o lado ficou exposto, volta (mesma regra da criação). Só o automático; o manual e o do modelo nunca mudam sozinhos. O vizinho não anda; o módulo arrastado encosta.
- **Espessuras do tamponamento** (A, 22/11): só 15, 25 e 30. 15 = chapa de 15 · 25 = chapa única de 25 · **30 = duas de 15** (face + moldura de réguas de 80). **Não existe 35.** O 3D desenha igual ao corte.
- **Nenhum armário com vão, peça solta, erro de seleção ou erro de porta.** Porta e prateleira vão até o fim. (A)

## Pedra
- **Armário embaixo da pedra com saia:** a frente do armário para na saia e não passa dela. (A, 16/11) (código: `fitNew`, `cornerStoneFit`)
- **Altura do armário embaixo da pedra com saia:** folga de 15 mm embaixo da saia; o armário inteiro (caixa e frentes) começa dali pra baixo e a pedra fica por cima. Embaixo da saia = embaixo da pedra + espessura − saia. Ex.: pedra a 820, 30 de espessura, saia de 100 → saia até 750 → armário até 735. Sem saia: armário até embaixo da pedra, sem a folga. A folga entra uma vez só; portas e gavetas seguem as folgas normais a partir do topo do módulo. Mudar a saia ou a espessura da pedra: o armário encaixado acompanha. Vale pra pedra em que a saia foi ligada ou mudada a partir de 16/11; projeto antigo não muda ao abrir. (A, 16/11 10:39 e 10:56) (código: `stArmTop`, `STFOLGA_SAIA`, `stAdapta`, `underStone`)

## Pendentes de confirmação (não usar como regra ainda)
- Perfil G encostando na caixa (1,5 mm). Ver a pendência 1 da especificação do gola.
- Engrosso do tamponamento "entrando no módulo": reproduzido em 22/11 no tamponamento de **25 mm** (3D desenhava 15+15 e as réguas entravam 5 mm na lateral). Ver TAMP-25-3D no HISTORICO_ERROS.

## Fundo (confirmado pelo Adauto em 18/11/2026, com foto de uma torre no 3D)
- **Regra:** o fundo dos armários é **parafusado por fora**, sobreposto e não embutido. O único fundo embutido é o da gaveta.
- **Como o app está hoje (medido em 18/11, torre do forno, balcão 2 portas e torre por vãos):**
  - o padrão é "Sobreposto (parafusado atrás)";
  - o corte sai com a largura e a altura do módulo inteiras;
  - no 3D, o fundo fica atrás das laterais (z 0–6) e as laterais começam na frente dele;
  - o fundo da gaveta é encaixado (6 mm).
- **Decisão do Adauto (18/11): "Rasgo é somente gavetas, o resto é sobreposto".** A torre da foto estava marcada com rasgo.
  - A aba Estrutura e os Ajustes não oferecem mais rasgo pro fundo do armário.
  - O Ajustes guardado com rasgo vale como sobreposto pros módulos novos.
  - Módulo antigo que já está com rasgo não muda sozinho ao abrir: a aba Estrutura avisa e tem o botão "Passar pra sobreposto", que pode ser desfeito.
  - As contas do sobreposto e do rasgo não mudaram.
  - Teste: `testFundoDoArmarioSempreSobrepostoRasgoSoNaGaveta`.

## Fita de borda no plano de corte (Adauto, 18/11/2026)
- **Regra:** "Não aplicar desconto da fita de 1 mm no plano de corte". O corte sai com a medida da peça de MDF, e a fita não diminui a peça.
- **Conferido em 18/11:**
  - nenhuma branch desconta a espessura da fita no corte, na lista nem no orçamento; a fita entra só em metros;
  - o 0,8 mm existe só no desenho do 3D, na tira na frente da peça;
  - 142 módulos do catálogo e 2971 peças: nenhuma medida de corte de 1 a 4 mm menor que a peça.
- **Teste permanente:** `testPlanoDeCorteNaoDescontaAFitaDeBorda`.
- **Decisão anterior (DECISOES, 17/11):** a fita de 1 mm como padrão continua valendo só pro desenho e pro acabamento, nunca pra encurtar a peça de corte.
