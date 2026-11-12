#!/usr/bin/env python3
"""TRAVA DE PUBLICAÇÃO.

Compilar e testar NUNCA pode mexer na versão que os usuários recebem.
Este script roda no começo de toda compilação e falha se algum passo que toca o ponteiro público
(apk-latest / win-latest), cria release pública (apk-N / win-N) ou gera o AAB da loja estiver fora
da condição de publicação (disparo manual, modo "publicar" e confirmação conferida).

Também é ele que confere a confirmação na hora de publicar:  trava_publicacao.py confirmar "<texto>"
"""
import os, re, sys

RAIZ = os.path.join(os.path.dirname(__file__), '..', 'workflows')
PUBLICA = re.compile(r'apk-latest|win-latest|gh release create|gh release upload|bundlePlayRelease -P')
TESTE_OK = re.compile(r'teste-android-|teste-windows-|win-dev-deps')  # canais de teste e cache de dependências: o app nunca lê essas tags
COND = "github.event_name == 'workflow_dispatch' && inputs.modo == 'publicar'"


def passos(txt):
    """Divide o arquivo em passos (- name: / - uses:) e devolve (nome, texto)."""
    out, cur, nome = [], [], ''
    for ln in txt.split('\n'):
        m = re.match(r'\s{6}- (name|uses): ?(.*)', ln)
        if m:
            if cur:
                out.append((nome, '\n'.join(cur)))
            cur, nome = [ln], m.group(2)
        elif cur:
            cur.append(ln)
    if cur:
        out.append((nome, '\n'.join(cur)))
    return out


def conferir():
    ruim = []
    for arq in sorted(os.listdir(RAIZ)):
        if not arq.endswith('.yml'):
            continue
        txt = open(os.path.join(RAIZ, arq), encoding='utf-8').read()
        for nome, corpo in passos(txt):
            linhas = [l for l in corpo.split('\n') if not l.strip().startswith('#')]
            toca = [l for l in linhas if PUBLICA.search(l) and not TESTE_OK.search(l)]
            if not toca:
                continue
            if COND not in corpo or 'trava_publicacao.py confirmar' not in corpo:
                ruim.append('%s · passo "%s" mexe na versão pública fora do modo publicar: %s' % (arq, nome, toca[0].strip()[:90]))
    if ruim:
        print('::error title=TRAVA DE PUBLICAÇÃO::' + ' | '.join(ruim))
        for r in ruim:
            print('TRAVA:', r)
        return 1
    print('Trava de publicação: ok. Só o modo "publicar" (manual, com confirmação) mexe na versão dos usuários.')
    return 0


def confirmar(texto):
    sha = (os.environ.get('GITHUB_SHA') or '')[:7]
    evento = os.environ.get('GITHUB_EVENT_NAME') or ''
    esperado = 'PUBLICAR ' + sha
    if evento != 'workflow_dispatch' or not sha or (texto or '').strip() != esperado:
        print('::error title=TRAVA DE PUBLICAÇÃO::Publicação recusada. Pra publicar este commit, dispare à mão no modo "publicar" e escreva exatamente: %s' % esperado)
        return 1
    print('Publicação autorizada pra %s.' % sha)
    return 0


if __name__ == '__main__':
    if len(sys.argv) >= 2 and sys.argv[1] == 'confirmar':
        sys.exit(confirmar(sys.argv[2] if len(sys.argv) > 2 else ''))
    sys.exit(conferir())
