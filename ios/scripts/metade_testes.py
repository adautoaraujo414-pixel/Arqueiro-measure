#!/usr/bin/env python3
"""Divide a bateria do iPhone em 2 passos (Chefe 25/11: sem mexer em limite; o passo de 75 min não cabia a bateria inteira).

Lê os testes do código (classe XCTestCase → func testX()) e divide o EditorWebKitTests ao meio, na ordem em que o XCTest roda
(alfabética). As outras classes ficam no passo A.
  metade_testes.py args A   → -skip-testing da metade B (o A roda tudo, menos a metade B e a SubscriptionTests, que tem passo próprio)
  metade_testes.py args B   → -only-testing da metade B
  metade_testes.py contagem → total esperado, quantos em A e em B (A + B = total, sem repetir)
  metade_testes.py confere LOG… → testes distintos que começaram nos logs × o esperado (prova de que nada ficou de fora)
"""
import os, re, sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'ArquemestreTests')
FORA = {'SubscriptionTests'}          # roda no passo dos testes da assinatura (StoreKit)
DIVIDE = 'EditorWebKitTests'


def testes():
    T = {}
    for nome in sorted(os.listdir(RAIZ)):
        if not nome.endswith('.swift'):
            continue
        cls = None
        for ln in open(os.path.join(RAIZ, nome), encoding='utf-8'):
            m = re.match(r'\s*(?:final\s+)?class\s+(\w+)\s*:\s*XCTestCase', ln)
            if m:
                cls = m.group(1)
                T.setdefault(cls, [])
                continue
            m = re.match(r'\s{4}(?:@MainActor\s+)?func\s+(test\w+)\s*\(\s*\)', ln)
            if m and cls:
                T[cls].append(m.group(1))
    return {c: sorted(set(v)) for c, v in T.items() if v and c not in FORA}


def metades():
    T = testes()
    e = T.get(DIVIDE, [])
    meio = len(e) // 2
    A = [(c, t) for c, v in T.items() for t in v if c != DIVIDE] + [(DIVIDE, t) for t in e[:meio]]
    B = [(DIVIDE, t) for t in e[meio:]]
    return T, A, B


def main():
    T, A, B = metades()
    total = sum(len(v) for v in T.values())
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'contagem'
    if cmd == 'args':
        lado = sys.argv[2]
        if lado == 'A':
            print(' '.join('-skip-testing:ArquemestreTests/%s/%s' % ct for ct in B))
        else:
            print(' '.join('-only-testing:ArquemestreTests/%s/%s' % ct for ct in B))
    elif cmd == 'contagem':
        sa, sb = set(A), set(B)
        print('CONTAGEM iPhone: esperado %d testes (%d classes, sem a SubscriptionTests) · passo A %d · passo B %d · A+B %d · repetidos %d'
              % (total, len(T), len(A), len(B), len(sa | sb), len(sa & sb)))
        if len(sa | sb) != total or sa & sb:
            sys.exit(1)
    elif cmd == 'confere':
        vistos = set()
        for L in sys.argv[2:]:
            if os.path.exists(L):
                for ln in open(L, encoding='utf-8', errors='replace'):
                    m = re.search(r"Test Case '-\[ArquemestreTests\.(\w+) (test\w+)\]' started", ln)
                    if m:
                        vistos.add((m.group(1), m.group(2)))
        esp = set(A) | set(B)
        falta = sorted(esp - vistos)
        print('CONTAGEM iPhone: começaram %d de %d esperados · faltaram %d%s' % (len(vistos & esp), len(esp), len(falta),
              (' (ex.: ' + ', '.join('%s/%s' % f for f in falta[:5]) + ')') if falta else ''))


if __name__ == '__main__':
    main()
