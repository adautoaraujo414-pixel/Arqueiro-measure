# Proposta técnica — Iluminação LED ("Adicionar LED") · só engenharia, NADA implementado

Pedido do Adauto (22/11/2026). Claude Code 2, ramo `feature/pecas-livres-2d`. Implementação só com aprovação do Adauto, depois da auditoria do Claude Chefe.
Sem merge, sem publicação. Não duplicar o motor 3D nem criar outro editor: **o LED novo é uma extensão do LED que já existe.**

## 1. O que já existe (auditoria do `editor.html`, linhas de 973db09)
- **LED por módulo** `m.led = {k:'emb'|'45', c:'3000'|'4000'|'6000'|…, pf:'alu'|'preto'|'branco', pos:'base'|'rodape'|'topo'|'vao', on, bt, a, b}`
  (`ledDef` L4314, `LK` L4307). `ledOk(m)` (L4901) só libera aéreo, cristaleira e porta de vidro (canto não).
  Outros donos: prateleira do ripado `a.led`, ripas em pé `a.rled`, ilha `a.led`; `ledOwners()` (L4387) junta todos.
- **Botão do LED** (`lbt` = botão): `S.lbtm` ('um'|'cada'|'nao'), `S.lbtc` (cor), `S.lbt1` (posição do botão único), `m.led.bt` por módulo; 2 toques pra mudar de lugar.
- **Criar**: menu ＋ Criar › "LED (perfil com fita)" (`crpMore` L4541): tipo (embutido/45°), cor da luz, "Embaixo dos aéreos / No módulo escolhido /
  Nas prateleiras / Embaixo da pedra da ilha"; "Apagar/Acender todos", "🌙 Ver à noite", "Pôr X m no orçamento". Editar: 1 toque na luz (`ISX k:'led'`).
- **3D**: `ledStrip` (L4348) = caixa do perfil + difusor emissivo (`em:1`) + halo; `ledGlow` (L4341) = luz "falsa" (grade de pontos com gradiente na
  parede e mancha na superfície de baixo, `ledSurf`); `NIGHT` (L4419). Sem luz real nem sombra. Limites: ≤10 segmentos × 8 pontos por grade.
- **Orçamento**: nada automático — só `ledToOrc` (manual) põe `ledLen()` metros no item de catálogo "Fita de LED" (R$/m). `ledLen` é estimativa
  (largura − 2·esp − 30 etc.). Não há perfil, difusor, fonte nem conector.
- **Usinagem**: só texto na nota da peça (`p.note`) lido por expressão regular (rasgo do fundo, cava 30°, concha, sistema 32). Sem lista estruturada,
  sem DXF/CNC.
- **Salvar**: `m.led`/`a.led`/`a.rled` vão dentro do módulo/painel; `lbtm/lbtc/lbt1` explícitos no `snapState`. Testes: `testLEDChamaAguaEEditarNo3D`,
  `testBotaoDoLEDUmSoOuUmPorModulo…`, `testLedNoRipado…` (3), `testFotosDaLojaSalaComLedDeNoite…` e outros.

## 2. O que falta (e o pedido)
Posição livre numa face (prateleira, lateral, fundo, nicho, base, teto, painel), rotação, comprimento editável, distância das bordas, duplicar;
tipos **sobreposto** e **magnético**; biblioteca de perfis com medidas de fabricante; orçamento estruturado (perfil, fita, difusor, fonte,
conectores, usinagem); rasgo como informação de fabricação na peça certa; colisão com ferragens.

## 3. Modelo de dados proposto (persistente, compatível)
- **Lista no módulo**: `m.leds = [ {id, n, perfil:'<id da biblioteca>', inst:'emb'|'sob'|'mag', face:{pk:'<pk da peça>', lado:'+'|'-'},
  u, v, rot:0|90|180|270, L, on, c:'3000'…} ]` — coordenadas **da face da peça** (u,v em mm a partir do canto da face; `L` comprimento),
  ligada pelo `pk` estável da peça (mesmo princípio das peças livres; `pk` "nome#N"). Assim o LED acompanha o móvel quando ele anda, gira ou vai
  pra outra parede, e nunca fica flutuando.
- `m.led` (o LED de hoje) **continua lendo e funcionando**; o novo é adicional. Migração só se o Adauto pedir (e com confirmação).
- **Biblioteca de perfis** em `PR.ledPerfis` (aparelho, como Meus Modelos), editável: `{id, nome, modelo, fabricante, inst:['emb','sob','mag'],
  largura, altura, rasgo:{larg, prof}|null, difusor, fixacao, magnetico:bool, chapaMetalica:bool, potW_m, preco_m, fitaW_m, fonte:{W, preco},
  conector:{preco}}`. **Começa vazia ou com os perfis que o Adauto informar** — sem medida inventada; o app pede as medidas do fabricante.
- **Marcador de formato**: `m.ledv = 1` (mesma Política B: pacote/link com LED novo só abre em versão que entende; nunca some calado).

## 4. Fluxo (iPhone/iPad/Android/Windows, poucos toques, mm)
Selecionar móvel → **💡 Adicionar LED** → tocar na superfície (2D Frente ou multivistas, ou 3D) → o app acha a face pela caixa do 3D tocada
(o mesmo "primeiro sólido que o olhar acerta" das peças livres) → prévia → escolher perfil e tipo (só os tipos que o perfil aceita; ímã só se o perfil
for magnético) → ajustar (arrastar; pontas esticam; botões "Centralizar", "Encostar ←/→/frente/fundo"; girar 90/180/270 quando couber; campos:
distância de cada borda e comprimento em mm) → Confirmar. Duplicar e Remover no mesmo painel. Desfazer/refazer pelo histórico de sempre.

## 5. Tipos de instalação
- **Embutido**: perfil dentro de rasgo usinado (largura × profundidade do perfil da biblioteca). **Rasgo não atravessa**: profundidade < espessura
  da peça − margem (ex. MDF 15 → máx. 15 − 3 = 12, margem configurável). Gera **informação de usinagem** na peça hospedeira (nota padronizada + campo
  estruturado novo `p.usin=[{tipo:'rasgo', u,v,L,larg,prof,face}]`, pra lista/plano de corte e futuro DXF). LED embutido: perfil "some" no 3D (só o
  difusor aparece), luz igual.
- **Sobreposto**: sem rasgo; a altura física do perfil entra na colisão (não pode bater em porta/prateleira/gaveta).
- **Magnético**: só perfis marcados como magnéticos; embutido-magnético (rasgo + chapa metálica) ou sobreposto-magnético (chapa/fita metálica);
  acessórios vindos do perfil. Não presumir ímã.

## 6. Segurança geométrica (reaproveita o sólido das peças livres)
- LED/perfil = caixa no sistema da face; conferência pelas caixas do 3D (`EM.pecaBate`-like, com cache de gesto) + "encosta pode, entrar não".
- **Ferragens**: zonas proibidas na face — braço da dobradiça (~53 mm pra dentro da lateral, L2046), corrediças nas laterais, furos sistema 32,
  suportes de prateleira (`hAvoidOf`), fundo, depurador (L11988), botão do LED (`lbtFree`). Não cabe → avisa e não cria.
- Nada muda peça existente sozinho; rasgo só entra na peça quando o LED embutido é confirmado (e sai junto se o LED for removido).

## 7. 3D e desempenho
Reaproveitar `ledStrip`/`ledGlow`/`NIGHT` (mesma luz falsa, sem luz real). Liga/desliga por LED e "todos". Limite de custo: no celular/tablet,
grade de brilho menor e no máximo N LEDs com brilho completo (os outros só com o difusor aceso); o arrasto usa o cache de gesto (sem reconstruir o 3D
a cada passo). Embutido: perfil escondido; sobreposto: perfil visível.

## 8. Fabricação e orçamento (separado de MDF)
Linhas novas no orçamento (não entram em chapa): **perfil (m)**, **fita (m)** (comprimento real de cada LED, não estimativa), **difusor (m)**,
**fontes** (soma de W/m × m ÷ potência da fonte, arredondado pra cima, por circuito/botão), **conectores/acessórios** (por LED), **usinagem**
(m de rasgo, se o Adauto quiser cobrar). O plano de corte **não muda** de medida; só ganha a anotação do rasgo na peça. DXF: só prever o campo `p.usin`.

## 9. Riscos
Compatibilidade (versão antiga: LED novo invisível → Política B no pacote); desempenho em aparelhos fracos (limite de brilho); colisão com
ferragens que não estão no `partsOf` como caixa (precisa das zonas proibidas); `pk` da peça hospedeira muda se a estrutura do módulo mudar
(mesma proposta "Adaptar/Manter" das peças livres); botão do LED e `ledLen` precisam conhecer a lista nova; testes antigos de LED não podem mudar.

## 10. Fases (cada uma com testes que falham antes e passam depois, bateria completa no fim)
1. **Biblioteca de perfis** (cadastro, sem medida inventada) + modelo `m.leds` + salvar/reabrir/Política B.
2. **Adicionar LED sobreposto** numa face (toque → face → prévia → confirmar), posição/comprimento/distâncias, sem rotação.
3. **Rotação, centralizar/encostar, duplicar/remover**, multivistas e 3D.
4. **Colisões com ferragens** (zonas proibidas) e avisos.
5. **Embutido** com rasgo estruturado na peça + nota no plano de corte.
6. **Magnético** (só perfis marcados).
7. **Orçamento estruturado** (perfil, fita, difusor, fonte, conectores, usinagem).
8. **Desempenho em celular/tablet** e testes nos locais pedidos (aéreos, prateleiras, nichos, cristaleira, painel de TV, cabeceira, guarda-roupa,
   sanca, porta de vidro, módulo personalizado).

## 11. Perguntas ao Adauto (não inventar)
1. Quais perfis (fabricante/modelo e medidas) entram na biblioteca inicial? Ou ela começa vazia?
2. Usinagem do rasgo entra no orçamento? Por metro?
3. Fonte: uma por botão/circuito ou por LED? Qual potência padrão?
4. O LED de hoje (`m.led`) continua como está ao lado do novo, ou vira um item do novo com confirmação?
5. Margem mínima do rasgo até a outra face (proposta 3 mm)?
