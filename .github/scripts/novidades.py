#!/usr/bin/env python3
"""Gera o texto "Novidades desta versão" a partir das mensagens dos commits desde o release anterior.

Uso: python novidades.py <prefixo> <tag-atual>      ex.: python novidades.py apk- apk-470

Cada commit vira um item: o título (o que mudou) e, embaixo, a explicação. Linhas técnicas de
assinatura (Co-Authored-By, Claude-Session, links) e a linha da suíte de testes ficam de fora.
O app mostra esse texto no aviso "Atualização disponível" antes de atualizar.

Se .github/novidades.txt foi alterado desde a publicação anterior, o texto dele é usado no lugar
(linhas começadas com # são comentário). É a forma de dizer com precisão, sem termo técnico, o que entrou.
"""
import os
import re
import subprocess
import sys

NOV = ".github/novidades.txt"


def sh(*args):
    return subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace").stdout


def main():
    pre, cur = sys.argv[1], sys.argv[2]
    tags = [t for t in sh("git", "tag", "-l", pre + "*").split()
            if t != cur and re.fullmatch(re.escape(pre) + r"\d+", t)]
    tags.sort(key=lambda t: int(t[len(pre):]), reverse=True)
    prev = None
    for t in tags:
        if subprocess.run(["git", "merge-base", "--is-ancestor", t, "HEAD"]).returncode == 0:
            prev = t
            break
    rng = (prev + "..HEAD") if prev else "HEAD~8..HEAD"
    # Texto escrito à mão para esta publicação (.github/novidades.txt): vale só quando o arquivo mudou
    # desde a publicação anterior. Assim o aviso diz, em palavras de marceneiro, exatamente o que entrou;
    # se ninguém atualizar o arquivo, a próxima publicação volta a sair dos commits (nunca repete texto velho).
    if prev and sh("git", "diff", "--name-only", rng, "--", NOV).strip() and os.path.exists(NOV):
        with open(NOV, encoding="utf-8") as f:
            manual = "\n".join(l.rstrip() for l in f.read().splitlines() if not l.lstrip().startswith("#")).strip()
        if manual:
            if len(manual) > 3500:
                manual = manual[:3500].rsplit("\n", 1)[0] + "\n…"
            sys.stdout.write("Novidades desta versão:\n" + manual + "\n")
            return
    log = sh("git", "log", "--no-merges", "--format=%x1e%s%x1f%b", rng)
    skip_subj = re.compile(r"(?i)^(merge|wip\b|ci:|chore|build:|versionar fontes)")
    skip_line = re.compile(r"(?i)^(co-authored-by|claude-session|signed-off-by|https?://|🤖|su[ií]te:)")
    out = []
    for ent in log.split("\x1e"):
        if not ent.strip():
            continue
        subj, _, body = ent.partition("\x1f")
        subj = subj.strip()
        if not subj or skip_subj.match(subj):
            continue
        out.append("• " + subj)
        par = []
        for ln in body.splitlines() + [""]:
            l = ln.strip()
            if l and skip_line.match(l):
                continue
            if l:
                par.append(l)
            elif par:
                p = re.sub(r"\s*Su[ií]te:[^.]*\.", "", " ".join(par)).strip()
                if p:
                    out.append("   " + p)
                par = []
    txt = "\n".join(out).strip() or "Melhorias e correções."
    if len(txt) > 3500:
        txt = txt[:3500].rsplit("\n", 1)[0] + "\n…"
    sys.stdout.write("Novidades desta versão:\n" + txt + "\n")


if __name__ == "__main__":
    main()
