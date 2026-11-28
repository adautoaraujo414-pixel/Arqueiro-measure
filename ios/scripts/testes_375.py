#!/usr/bin/env python3
"""Testes de TOQUE e 2D no iPhone de 375 de largura (Chefe 28/11, ETAPA 3 · 3.6, matriz de tamanhos do Code 1).

Mesma lista do código (metade_testes.testes()), filtrada pelas famílias que dependem da largura da tela:
Toque*, DoisToques*, TOQUE*, Etapa2Vizinho*, Liberdade*, ETAPA3*, LedNoRipado* e o plano de corte legível (PlanoDeCorteLegivel*).
  testes_375.py args        → -only-testing de cada teste das famílias
  testes_375.py contagem    → quantos e quais (falha se a lista sair vazia)
  testes_375.py confere LOG → testes distintos que começaram no log × o esperado (prova de que nenhum ficou de fora)
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from metade_testes import testes

FAMILIAS = re.compile(r'^test(Toque|DoisToques|TOQUE|Etapa2Vizinho|Liberdade|ETAPA3|LedNoRipado|PlanoDeCorteLegivel)')


def lista():
    return [(c, t) for c, v in sorted(testes().items()) for t in v if FAMILIAS.match(t)]


def main():
    L = lista()
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'contagem'
    if cmd == 'args':
        print(' '.join('-only-testing:ArquemestreTests/%s/%s' % ct for ct in L))
    elif cmd == 'contagem':
        print('CONTAGEM iPhone 375: %d testes de toque/2D' % len(L))
        for c, t in L:
            print('  %s/%s' % (c, t))
        if not L:
            sys.exit(1)
    elif cmd == 'confere':
        vistos = set()
        for log in sys.argv[2:]:
            if not os.path.exists(log):
                continue
            for ln in open(log, encoding='utf-8', errors='replace'):
                m = re.search(r"Test Case '-\[ArquemestreTests\.(\w+) (test\w+)\]' started", ln)
                if m:
                    vistos.add((m.group(1), m.group(2)))
        falta = [ct for ct in L if ct not in vistos]
        print('CONFERE iPhone 375: esperado %d · começaram %d · faltaram %d' % (len(L), len(set(L) & vistos), len(falta)))
        for c, t in falta[:40]:
            print('  FALTOU %s/%s' % (c, t))
        if falta:
            sys.exit(1)
    else:
        sys.exit('uso: testes_375.py args|contagem|confere LOG…')


if __name__ == '__main__':
    main()
