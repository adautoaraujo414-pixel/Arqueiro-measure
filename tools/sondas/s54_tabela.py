#!/usr/bin/env python3
"""Tabela da sonda s54 (ETAPA 3.1, régua da seleção no 3D).
  python3 tools/sondas/s54_tabela.py RESULTADO.json --rotulo "ANTES · 5067fec" [--comparar OUTRO.json --rotulo2 "DEPOIS · <sha>"] > saida.md
Só formata: os números vêm do JSON que a s54 devolveu."""
import argparse, json

ap = argparse.ArgumentParser()
ap.add_argument('json'); ap.add_argument('--rotulo', default='ANTES')
ap.add_argument('--comparar'); ap.add_argument('--rotulo2', default='DEPOIS')
a = ap.parse_args()
A = json.load(open(a.json, encoding='utf-8'))
B = json.load(open(a.comparar, encoding='utf-8')) if a.comparar else None

def g(d, *k):
    for x in k:
        d = (d or {}).get(x) if isinstance(d, dict) else None
    return '-' if d in (None, '') else d

linhas = [
    ('(1) acerto na seleção (todas as peças visíveis)', ('1_acerto',)),
    ('(1b) acerto nos toques inequívocos (meta 100%)', ('1b_acerto_inequivoco',)),
    ('(1g) acerto · critério antigo do grupo (o do ANTES)', ('1g_acerto_criterioGrupo',)),
    ('(1h) inequívocos · critério antigo do grupo', ('1h_inequivoco_criterioGrupo',)),
    ('(2) seleções no módulo vizinho', ('2_vizinho',)),
    ('(2b) toque que não selecionou nada', ('2b_nada',)),
    ('(3) acerto · zoom 1×', ('3_porZoom', 'z1')),
    ('(3) acerto · zoom ~2,6×', ('3_porZoom', 'z2')),
    ('(3) acerto · zoom ~6,7×', ('3_porZoom', 'z3')),
    ('(3b) inequívocos · zoom 1×', ('1c_inequivoco_porZoom', 'z1')),
    ('(3b) inequívocos · zoom ~2,6×', ('1c_inequivoco_porZoom', 'z2')),
    ('(3b) inequívocos · zoom ~6,7×', ('1c_inequivoco_porZoom', 'z3')),
    ('(3c) acerto · isométrica', ('3b_porAngulo', 'iso')),
    ('(3c) acerto · frente', ('3b_porAngulo', 'front')),
    ('(3c) acerto · lado', ('3b_porAngulo', 'left')),
    ('(4) acerto em peças pequenas (< 600 px² visíveis)', ('4_pequenas',)),
    ('(5) tempo do toque · p50 (ms)', ('5_ms', 'p50')),
    ('(5) tempo do toque · p95 (ms)', ('5_ms', 'p95')),
    ('(5) tempo do toque · máximo (ms)', ('5_ms', 'max')),
    ('(6) LED · módulo certo (onde o app aceita LED)', ('6_led', 'modulo')),
    ('(6) LED · encosta na peça tocada', ('6_led', 'superficie')),
    ('(6) LED · recusado pela regra atual', ('6_led', 'recusadoPelaRegra')),
    ('(6p) LED na peça · caminho do toque', ('6p_led_peca', 'caminho')),
    ('(6) LED de módulo · prévia #ledprev confirmada', ('6_led', 'previaConfirmada')),
    ('(6) LED de módulo · foi pro rodapé', ('6_led', 'noRodape')),
    ('(6p) LED na peça · toques', ('6p_led_peca', 'toques')),
    ('(6p) LED na peça · base do acerto (sem escolha e sem recusa com aviso)', ('6p_led_peca', 'criaramOuDeviamCriar')),
    ('(6p) LED na peça · recusado com aviso do app', ('6p_led_peca', 'recusadoComAviso')),
    ('(6p) LED na peça · módulo certo', ('6p_led_peca', 'modulo')),
    ('(6p) LED na peça · peça certa (pk)', ('6p_led_peca', 'peca')),
    ('(6p) LED na peça · encosta na peça tocada', ('6p_led_peca', 'superficie')),
    ('(6p) LED na peça · pediu escolha (não é erro)', ('6p_led_peca', 'pediuEscolha')),
    ('(6p) LED na peça · toque sem LED e sem aviso', ('6p_led_peca', 'nenhumLEDsemAviso')),
    ('(6p) LED na peça · tempo p95 (ms)', ('6p_led_peca', 'ms', 'p95')),
    ('destaque: acende só a peça escolhida', ('destaque',)),
    ('toque que mudou o projeto sozinho', ('toqueMudouProjeto', 'n')),
    ('ids · caixa do 3D sem pk (peça)', ('ids', 'semPk')),
    ('ids · ferragem marcada (b.ferr, conta como identificada)', ('ids', 'ferr')),
    ('ids · ferragem só pelo nome (sem pk e sem b.ferr)', ('ids', 'ferrNome')),
    ('ids · pk repetido no partsOf', ('ids', 'pkRep')),
    ('ids · pk em caixas de 2 peças', ('ids', 'pkAmb')),
    ('ids · peça desenhável sem caixa no 3D', ('ids', 'semCaixa')),
]
cab = '| Métrica | ' + a.rotulo + ' |' + (' ' + a.rotulo2 + ' |' if B else '')
print('## s54 · seleção no 3D · ' + a.rotulo + (' × ' + a.rotulo2 if B else '') + '\n')
print(cab); print('|---|---|' + ('---|' if B else ''))
for t, k in linhas:
    print('| ' + t + ' | ' + str(g(A, *k)) + ' |' + (' ' + str(g(B, *k)) + ' |' if B else ''))
print('\nTempo da sonda: %s s.\n' % A.get('seg'))
print('### Acerto por cenário (%s)\n' % a.rotulo)
print('| Cenário | Acerto |'); print('|---|---|')
for c, v in (A.get('porCenario') or {}).items():
    if not str(v).startswith('100%'):
        print('| ' + c + ' | ' + str(v) + ' |')
print('\n(cenários com 100%% ficam fora da lista: %d de %d)\n' % (sum(1 for v in (A.get('porCenario') or {}).values() if str(v).startswith('100%')), len(A.get('porCenario') or {})))
print('### Exemplos de erro (primeiros 40, %s)\n' % a.rotulo)
print('| Cenário · vista | Peça no ponto | px² | Toque (x,y) | Selecionou | Destaque | Inequívoco |'); print('|---|---|---|---|---|---|---|')
for f in (A.get('falhas') or [])[:40]:
    print('| %s | %s | %s | %s | %s | %s | %s |' % (f.get('c'), f.get('peca'), f.get('px'), f.get('xy'), f.get('sel'), f.get('hl'), 'sim' if f.get('inq') else 'não'))
for nm, k in (('Ids', ('ids', 'ex')), ('LED', ('6_led', 'ex')), ('LED na peça', ('6p_led_peca', 'ex')), ('LED na peça · recusas com aviso', ('6p_led_peca', 'recusaEx')), ('Toque que mudou o projeto', ('toqueMudouProjeto', 'ex'))):
    ex = g(A, *k)
    if isinstance(ex, list) and ex:
        print('\n### ' + nm + ' (exemplos)\n')
        vistos = []
        for e in ex:
            if e not in vistos:
                vistos.append(e)
        for e in vistos[:20]:
            print('- ' + e)
