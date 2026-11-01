#!/usr/bin/env python3
"""Confere se alguma captura de tela saiu vazia (tela toda de uma cor só: branca ou preta).

Tela vazia é motivo comum de recusa (regra 2.1: "não carregou o conteúdo"). Sem bibliotecas de fora:
lê o PNG com zlib. Uso: check_blank.py <pasta das capturas>
"""
import os, shutil, struct, subprocess, sys, tempfile, zlib


def png_pixels(path):
    data = open(path, 'rb').read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    pos, idat, w = 8, b'', None
    while pos < len(data):
        ln, typ = struct.unpack('>I4s', data[pos:pos + 8])
        chunk = data[pos + 8:pos + 8 + ln]
        if typ == b'IHDR':
            w, h, depth, ctype, _, _, inter = struct.unpack('>IIBBBBB', chunk)
        elif typ == b'IDAT':
            idat += chunk
        pos += 12 + ln
    if depth != 8 or ctype not in (2, 6) or inter:
        return None
    bpp = 3 if ctype == 2 else 4
    raw = zlib.decompress(idat)
    stride = w * bpp
    rows, prev, i = [], bytearray(stride), 0
    for _ in range(h):
        f = raw[i]; line = bytearray(raw[i + 1:i + 1 + stride]); i += 1 + stride
        for x in range(stride):
            a = line[x - bpp] if x >= bpp else 0
            b = prev[x]
            c = prev[x - bpp] if x >= bpp else 0
            if f == 1: line[x] = (line[x] + a) & 255
            elif f == 2: line[x] = (line[x] + b) & 255
            elif f == 3: line[x] = (line[x] + (a + b) // 2) & 255
            elif f == 4:
                p = a + b - c; pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                line[x] = (line[x] + (a if pa <= pb and pa <= pc else b if pb <= pc else c)) & 255
        rows.append(bytes(line)); prev = line
    return w, h, bpp, rows


def small(path):
    """No Mac do CI: reduz a imagem com o sips (bem mais rápido de ler)."""
    if not shutil.which('sips'):
        return path
    out = os.path.join(tempfile.mkdtemp(), 'p.png')
    try:
        subprocess.run(['sips', '-Z', '240', '-s', 'format', 'png', path, '--out', out], check=True, capture_output=True)
        return out
    except Exception:
        return path


def blank_fraction(path):
    r = png_pixels(small(path))
    if not r:
        return None
    w, h, bpp, rows = r
    top = int(h * 0.08)  # pula a barra de status
    cnt = {}
    n = 0
    for y in range(top, h, max(1, h // 120)):
        row = rows[y]
        for x in range(0, w, max(1, w // 80)):
            px = row[x * bpp:x * bpp + 3]
            key = (px[0] // 8, px[1] // 8, px[2] // 8)
            cnt[key] = cnt.get(key, 0) + 1
            n += 1
    return max(cnt.values()) / n


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else 'build/capturas'
    bad = []
    for d, _, fs in os.walk(root):
        for f in sorted(fs):
            if f.endswith('.png'):
                p = os.path.join(d, f)
                fr = blank_fraction(p)
                if fr is None:
                    continue
                print(f'{os.path.relpath(p, root)}: {fr * 100:.0f}% de uma cor só')
                if fr > 0.95:
                    bad.append(os.path.relpath(p, root))
    if bad:
        print('\nCAPTURAS VAZIAS (a tela não carregou):\n' + '\n'.join(' ✗ ' + b for b in bad))
        sys.exit(1)
    print('\nNenhuma captura vazia.')


if __name__ == '__main__':
    main()
