#!/usr/bin/env python3
"""Avaliador do pedaço de Swift que os XCTAssert do EditorWebKitTests.swift usam, pra bateria do Chromium conferir
também os asserts cujo valor esperado é uma EXPRESSÃO Swift (accuracy com variável, cx − 15, "\\(n):ripa", .count,
Set(...), arrays...). Antes esses ~400 asserts só eram conferidos no iOS (o regex do bateria_editor.py só pega valor literal).

Regras (pedido do Chefe, 23/11/2026):
- assert que o avaliador não entende (laço, closure, if, tipo que ele não conhece...) vira "não conferido" — nunca "ok";
- só é avaliado assert do nível de cima da função (fora de if/for/guard/closure), depois do 1º run(web, …) e antes de outro;
- os casts seguem o Swift: `as? Int` em 5.5 é nil, `as? String` em número é nil, Bool×número é ambíguo (não conferido).
"""
import json, math, re

TOK = re.compile(r'\s*(?:(?P<num>\d+\.\d+(?:[eE][-+]?\d+)?|\d+)|(?P<str>"(?:[^"\\]|\\.)*")|(?P<id>[A-Za-z_]\w*|\$0)'
                 r'|(?P<op>\?\?|\?\.|&&|\|\||==|!=|<=|>=|->|\.\.\.|\.\.<|[-+*/%<>!()\[\]{},.:?]))')


class NaoEntende(Exception):
    """o avaliador não sabe avaliar isto com certeza: o assert fica 'não conferido'"""


class _Nil:
    def __repr__(self): return 'nil'


NIL = _Nil()


def _fim_str(s, i):
    """s[i] == '"': índice logo depois do fecha-aspas, respeitando "\\(…)" com aspas dentro"""
    j = i + 1
    while j < len(s):
        c = s[j]
        if c == '\\':
            if j + 1 < len(s) and s[j + 1] == '(':
                d, j = 1, j + 2
                while j < len(s) and d:
                    if s[j] == '"':
                        j = _fim_str(s, j)
                        continue
                    if s[j] == '(':
                        d += 1
                    elif s[j] == ')':
                        d -= 1
                    j += 1
                continue
            j += 2
            continue
        if c == '"':
            return j + 1
        j += 1
    raise NaoEntende('string sem fim')


def toks(s):
    out, i = [], 0
    while i < len(s):
        while i < len(s) and s[i].isspace():
            i += 1
        if i < len(s) and s[i] == '"':
            if s.startswith('"""', i):
                raise NaoEntende('string de várias linhas')
            e = _fim_str(s, i)
            out.append(('str', s[i:e]))
            i = e
            continue
        m = TOK.match(s, i)
        if not m or m.end() == i:
            if s[i:].strip() == '':
                break
            raise NaoEntende('símbolo ' + s[i:i + 15])
        i = m.end()
        k = m.lastgroup
        out.append((k, m.group(k)))
    return out


def _isnum(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def cast(v, t):
    """as? T, como o Swift faz com o que veio do JSON (NSNumber, NSString, NSArray, NSDictionary)"""
    if v is NIL or v is None:
        return NIL
    t = t.replace(' ', '')
    if t in ('Any', 'AnyObject'):
        return v
    if t == 'NSNumber':
        if isinstance(v, bool):
            raise NaoEntende('Bool como NSNumber')
        return v if _isnum(v) else NIL
    if t == 'Double' or t == 'CGFloat' or t == 'Float':
        if isinstance(v, bool):
            raise NaoEntende('Bool como número')
        return float(v) if _isnum(v) else NIL
    if t == 'Int':
        if isinstance(v, bool):
            raise NaoEntende('Bool como número')
        if isinstance(v, int):
            return v
        if isinstance(v, float):
            return int(v) if v.is_integer() else NIL
        return NIL
    if t == 'String':
        return v if isinstance(v, str) else NIL
    if t == 'Bool':
        if isinstance(v, bool):
            return v
        if _isnum(v):
            raise NaoEntende('número como Bool')
        return NIL
    if t.startswith('[') and t.endswith(']'):
        dentro = t[1:-1]
        if ':' in dentro:
            kt, vt = dentro.split(':', 1)
            if kt != 'String' or not isinstance(v, dict):
                return NIL if not isinstance(v, dict) else _nao('dicionário ' + t)
            if vt in ('Any', 'AnyObject'):
                return v
            r = {}
            for k, x in v.items():
                c = cast(x, vt)
                if c is NIL:
                    return NIL
                r[k] = c
            return r
        if not isinstance(v, list):
            return NIL
        r = []
        for x in v:
            c = cast(x, dentro)
            if c is NIL:
                return NIL
            r.append(c)
        return r
    raise NaoEntende('tipo ' + t)


def _nao(m):
    raise NaoEntende(m)


def descr(v):
    """como o Swift escreve o valor dentro de "\\(…)" (só os casos sem ambiguidade)"""
    if isinstance(v, bool):
        return 'true' if v else 'false'
    if isinstance(v, int):
        return str(v)
    if isinstance(v, float):
        if v.is_integer() and abs(v) < 1e16:
            return '%d.0' % v
        return repr(v)
    if isinstance(v, str):
        return v
    raise NaoEntende('descrição de ' + type(v).__name__)


class Parser:
    BP = {'??': 1, '||': 2, '&&': 3, '==': 4, '!=': 4, '<': 4, '>': 4, '<=': 4, '>=': 4, '+': 5, '-': 5, '*': 6, '/': 6, '%': 6}

    def __init__(s, t, env):
        s.t, s.i, s.env = t, 0, env

    def pk(s, o=0):
        return s.t[s.i + o] if s.i + o < len(s.t) else (None, None)

    def nx(s):
        if s.i >= len(s.t):
            raise NaoEntende('fim')
        v = s.t[s.i]
        s.i += 1
        return v

    def ex(s, v):
        t = s.nx()
        if t[1] != v:
            raise NaoEntende('esperava %s' % v)

    def tipo(s):
        k, v = s.nx()
        if v == '[':
            d, out = 0, '['
            while True:
                t = s.nx()
                out += t[1]
                if t[1] == '[':
                    d += 1
                if t[1] == ']':
                    if d == 0:
                        break
                    d -= 1
            return out
        if k != 'id':
            raise NaoEntende('tipo')
        return v

    def expr(s, mb=0):
        l = s.unario()
        while True:
            k, v = s.pk()
            if k == 'id' and v == 'as':
                s.nx()
                q = s.nx()
                if q[1] != '?':
                    raise NaoEntende('as sem ?')
                l = cast(l, s.tipo())
                continue
            if k != 'op' or v not in s.BP or s.BP[v] <= mb:
                break
            s.nx()
            if v == '??':
                r = s.expr(s.BP[v] - 1)
                l = r if l is NIL else l
                continue
            r = s.expr(s.BP[v])
            l = s.bin(v, l, r)
        return l

    def bin(s, o, a, b):
        if o == '==':
            return igual(a, b)
        if o == '!=':
            return not igual(a, b)
        if a is NIL or b is NIL:
            raise NaoEntende('nil em ' + o)
        if o in ('&&', '||'):
            if not isinstance(a, bool) or not isinstance(b, bool):
                raise NaoEntende('lógico')
            return (a and b) if o == '&&' else (a or b)
        if o == '+' and isinstance(a, str) and isinstance(b, str):
            return a + b
        if o == '+' and isinstance(a, list) and isinstance(b, list):
            return a + b
        if not (_isnum(a) and _isnum(b)):
            raise NaoEntende('conta com ' + type(a).__name__)
        if o == '/' and isinstance(a, int) and isinstance(b, int):
            if b == 0:
                raise NaoEntende('divisão por 0')
            return int(a / b)
        return {'<': lambda: a < b, '>': lambda: a > b, '<=': lambda: a <= b, '>=': lambda: a >= b,
                '+': lambda: a + b, '-': lambda: a - b, '*': lambda: a * b, '/': lambda: a / b,
                '%': lambda: math.fmod(a, b)}[o]()

    def unario(s):
        k, v = s.pk()
        if v == '-':
            s.nx()
            x = s.unario()
            if not _isnum(x):
                raise NaoEntende('menos')
            return -x
        if v == '!':
            s.nx()
            x = s.unario()
            if not isinstance(x, bool):
                raise NaoEntende('não')
            return not x
        if k == 'id' and v == 'try':
            s.nx()
            return s.unario()
        return s.pos(s.prim())

    def args(s):
        a = []
        if s.pk()[1] == ')':
            s.nx()
            return a
        while True:
            if s.pk()[0] == 'id' and s.pk(1)[1] == ':':
                s.nx(); s.nx()
            a.append(s.expr())
            t = s.nx()
            if t[1] == ')':
                return a
            if t[1] != ',':
                raise NaoEntende('argumentos')

    def prim(s):
        k, v = s.nx()
        if k == 'num':
            return float(v) if ('.' in v or 'e' in v or 'E' in v) else int(v)
        if k == 'str':
            return texto(v, s.env)
        if v == '(':
            x = s.expr()
            s.ex(')')
            return x
        if v == '[':
            if s.pk()[1] == ':':
                s.nx(); s.ex(']')
                return {}
            if s.pk()[1] == ']':
                s.nx()
                return []
            a = []
            while True:
                a.append(s.expr())
                t = s.nx()
                if t[1] == ']':
                    return a
                if t[1] != ',':
                    raise NaoEntende('array')
        if k == 'id':
            if v in ('true', 'false'):
                return v == 'true'
            if v == 'nil':
                return NIL
            if s.pk()[1] == '(':
                if v == 'Set':
                    s.nx(); a = s.args()
                    if len(a) != 1 or not isinstance(a[0], list):
                        raise NaoEntende('Set')
                    return frozenset(a[0])
                if v == 'abs':
                    s.nx(); a = s.args()
                    if len(a) != 1 or not _isnum(a[0]):
                        raise NaoEntende('abs')
                    return abs(a[0])
                if v in ('min', 'max'):
                    s.nx(); a = s.args()
                    if not a or not all(_isnum(x) for x in a):
                        raise NaoEntende(v)
                    return min(a) if v == 'min' else max(a)
                if v in ('Double', 'Int'):
                    s.nx(); a = s.args()
                    if len(a) != 1 or not _isnum(a[0]):
                        raise NaoEntende(v + '()')
                    return float(a[0]) if v == 'Double' else int(a[0])
                raise NaoEntende('função ' + v)
            if v == 'String' and s.pk()[1] == '.' and s.pk(1)[1] == 'init':
                s.nx(); s.nx()
                return 'String.init'
            if v in s.env:
                return s.env[v]
            raise NaoEntende('variável ' + v)
        raise NaoEntende('início ' + str(v))

    def pos(s, x):
        while True:
            k, v = s.pk()
            if v == '?' and s.pk(1)[1] == '[':
                s.nx()  # x?[…]: opcional; nil continua nil
                v = '['
            if v == '[':
                s.nx()
                i = s.expr()
                s.ex(']')
                if x is NIL:
                    continue
                if isinstance(x, dict) and isinstance(i, str):
                    x = x.get(i, NIL)
                    if x is None:
                        raise NaoEntende('null do JSON')
                elif isinstance(x, list) and isinstance(i, int) and not isinstance(i, bool):
                    if not 0 <= i < len(x):
                        raise NaoEntende('índice fora')
                    x = x[i]
                else:
                    raise NaoEntende('índice')
                continue
            if v in ('.', '?.'):
                s.nx()
                m = s.nx()[1]
                if x is NIL:
                    if v != '?.':
                        raise NaoEntende('nil.')
                    if s.pk()[1] == '(':
                        s.nx(); s.args()
                    elif s.pk()[1] == '{':
                        raise NaoEntende('closure')
                    continue
                x = s.membro(x, m)
                continue
            if v == '!':
                # força o opcional (x!): nil derruba o teste no Swift
                s.nx()
                if x is NIL:
                    raise NaoEntende('x! com nil')
                continue
            return x

    def membro(s, x, m):
        chama = s.pk()[1] == '('
        if m == 'map' and s.pk()[1] == '{' and s.pk(1)[1] == '$0' and s.pk(2)[1] == '}':
            s.nx(); s.nx(); s.nx()
            return list(x)
        if s.pk()[1] == '{':
            raise NaoEntende('closure')
        if not chama:
            if m == 'count':
                if isinstance(x, (str, list, dict, frozenset)):
                    return len(x)
                raise NaoEntende('count')
            if m == 'isEmpty':
                if isinstance(x, (str, list, dict, frozenset)):
                    return len(x) == 0
                raise NaoEntende('isEmpty')
            if m in ('first', 'last'):
                if not isinstance(x, list):
                    raise NaoEntende(m)
                return (x[0] if m == 'first' else x[-1]) if x else NIL
            if m in ('intValue', 'doubleValue', 'boolValue'):
                if not _isnum(x):
                    raise NaoEntende(m)
                if m == 'intValue':
                    return int(x)
                if m == 'doubleValue':
                    return float(x)
                return x != 0
            raise NaoEntende('membro ' + m)
        s.nx()
        a = s.args()
        if m == 'rounded' and not a and _isnum(x):
            return float(math.floor(x + 0.5) if x >= 0 else -math.floor(-x + 0.5))
        if m == 'contains' and len(a) == 1:
            if isinstance(x, str) and isinstance(a[0], str):
                return a[0] in x
            if isinstance(x, (list, frozenset)):
                return any(igual(q, a[0]) for q in x)
            raise NaoEntende('contains')
        if m in ('hasPrefix', 'hasSuffix') and len(a) == 1 and isinstance(x, str) and isinstance(a[0], str):
            return x.startswith(a[0]) if m == 'hasPrefix' else x.endswith(a[0])
        if m == 'prefix' and len(a) == 1 and isinstance(a[0], int) and isinstance(x, (list, str)):
            return x[:a[0]]
        if m == 'sorted' and not a and isinstance(x, list):
            if all(isinstance(q, str) for q in x):
                return sorted(x, key=lambda q: q.encode('utf-16-be'))
            if all(_isnum(q) for q in x):
                return sorted(x)
            raise NaoEntende('sorted')
        if m == 'joined' and isinstance(x, list) and all(isinstance(q, str) for q in x) and len(a) <= 1:
            return (a[0] if a else '').join(x)
        if m == 'split' and len(a) == 1 and isinstance(x, str) and isinstance(a[0], str) and len(a[0]) == 1:
            return [p for p in x.split(a[0]) if p != '']
        if m == 'map' and len(a) == 1 and a[0] == 'String.init' and isinstance(x, list):
            return [str(q) for q in x]
        raise NaoEntende('método ' + m)


def texto(lit, env):
    """literal de string do Swift (normal); "\\(…)" é avaliado"""
    body = lit[1:-1]
    out, i = '', 0
    while i < len(body):
        if body.startswith('\\(', i):
            d, j, ins = 1, i + 2, False
            while d:
                if j >= len(body):
                    raise NaoEntende('interpolação')
                c = body[j]
                if ins:
                    if c == '\\':
                        j += 1
                    elif c == '"':
                        ins = False
                elif c == '"':
                    ins = True
                elif c == '(':
                    d += 1
                elif c == ')':
                    d -= 1
                j += 1
            v = avalia(body[i + 2:j - 1], env)
            if v is NIL:
                raise NaoEntende('nil na interpolação')
            out += descr(v)
            i = j
        elif body[i] == '\\':
            esc = body[i + 1] if i + 1 < len(body) else ''
            if esc == 'u':
                m = re.match(r'\\u\{([0-9a-fA-F]+)\}', body[i:])
                if not m:
                    raise NaoEntende('\\u')
                out += chr(int(m.group(1), 16))
                i += len(m.group(0))
                continue
            mp = {'n': '\n', 't': '\t', 'r': '\r', '"': '"', '\\': '\\', "'": "'", '0': '\0'}
            if esc not in mp:
                raise NaoEntende('escape')
            out += mp[esc]
            i += 2
        else:
            out += body[i]
            i += 1
    return out


def igual(a, b):
    if a is NIL or b is NIL:
        return a is b
    if isinstance(a, bool) or isinstance(b, bool):
        if isinstance(a, bool) and isinstance(b, bool):
            return a == b
        raise NaoEntende('Bool comparado com outro tipo')
    if _isnum(a) and _isnum(b):
        return a == b
    if isinstance(a, frozenset) or isinstance(b, frozenset):
        if isinstance(a, list):
            a = frozenset(a)
        if isinstance(b, list):
            b = frozenset(b)
        return a == b
    if isinstance(a, list) and isinstance(b, list):
        return len(a) == len(b) and all(igual(p, q) for p, q in zip(a, b))
    if isinstance(a, dict) and isinstance(b, dict):
        return a.keys() == b.keys() and all(igual(a[k], b[k]) for k in a)
    if type(a) is not type(b):
        raise NaoEntende('tipos diferentes')
    return a == b


def avalia(src, env):
    p = Parser(toks(src), env)
    v = p.expr()
    if p.i != len(p.t):
        raise NaoEntende('sobrou ' + ''.join(x[1] for x in p.t[p.i:p.i + 3]))
    return v


def separa(s, sep=','):
    """divide no separador de nível de cima (fora de (), [], {} e de string)"""
    d, a, c, i = 0, [], '', 0
    while i < len(s):
        ch = s[i]
        if ch == '"':
            e = _fim_str(s, i)
            c += s[i:e]; i = e; continue
        elif ch in '([{':
            d += 1; c += ch
        elif ch in ')]}':
            d -= 1; c += ch
        elif ch == sep and d == 0:
            a.append(c.strip()); c = ''
        else:
            c += ch
        i += 1
    if c.strip():
        a.append(c.strip())
    return a


def comandos(corpo):
    """comandos do corpo da função depois do 1º run(web, …) e antes do próximo, com a profundidade de bloco de cada um.
    Junta comando de várias linhas (parênteses abertos) e separa os que vêm com ';' na mesma linha."""
    m = re.search(r'try await run\(web,', corpo)
    if not m:
        return []
    # pula a chamada do run inteira
    i, d = m.end(), 1
    while i < len(corpo) and d:
        if corpo.startswith('#"""', i):
            j = corpo.find('"""#', i + 4)
            if j < 0:
                return []
            i = j + 4; continue
        ch = corpo[i]
        if ch == '"':
            try:
                i = _fim_str(corpo, i)
            except NaoEntende:
                return []
            continue
        elif ch == '(':
            d += 1
        elif ch == ')':
            d -= 1
        i += 1
    resto = corpo[i:]
    m2 = re.search(r'run\(web,', resto)
    if m2:
        resto = resto[:m2.start()]
    out, cur, prof, bloco, k = [], '', 0, 0, 0
    # prof: (), [] abertos no comando; bloco: {} (if/for/closure)
    while k < len(resto):
        ch = resto[k]
        if resto.startswith('#"""', k):
            e = resto.find('"""#', k + 4)
            e = len(resto) if e < 0 else e + 4
            cur += resto[k:e]; k = e; continue
        if ch == '"':
            try:
                e = _fim_str(resto, k)
            except NaoEntende:
                e = len(resto)
            cur += resto[k:e]; k = e; continue
        if resto.startswith('//', k):
            e = resto.find('\n', k)
            k = len(resto) if e < 0 else e
            continue
        if resto.startswith('/*', k):
            e = resto.find('*/', k)
            k = len(resto) if e < 0 else e + 2
            continue
        if ch in '([':
            prof += 1
        elif ch in ')]':
            prof -= 1
        if ch == '{' and prof == 0:
            if cur.strip():
                out.append((bloco, cur.strip() + ' {'))
            cur = ''; bloco += 1; k += 1; continue
        if ch == '}' and prof == 0:
            if cur.strip():
                out.append((bloco, cur.strip()))
            cur = ''; bloco -= 1; k += 1; continue
        if (ch == '\n' or ch == ';') and prof == 0:
            if cur.strip():
                out.append((bloco, cur.strip()))
            cur = ''; k += 1; continue
        cur += ch
        k += 1
    if cur.strip():
        out.append((bloco, cur.strip()))
    return out


def confere_expr(corpo, o, ja):
    """Avalia os XCTAssert de expressão. ja(linha) diz se o regex antigo da bateria já confere aquele assert (não conta de novo).
    Devolve (falhas, conferidos, nao_conferidos[(assert, motivo)])."""
    env = {'o': o}
    falhas, conf, nao = [], 0, []
    cmds = comandos(corpo)
    for bloco, st in cmds:
        if bloco == 0 and re.match(r'(let|var)\s', st):
            for dcl in separa(st[4:].strip()):
                mm = re.match(r'(\w+)\s*(?::\s*[^=]+)?=\s*(.*)$', dcl, re.S)
                if not mm:
                    continue
                nome, ex = mm.group(1), mm.group(2).strip()
                try:
                    um = re.match(r'(?:try\s+)?XCTUnwrap\((.*)\)$', ex, re.S)
                    if um:
                        v = avalia(separa(um.group(1))[0], env)
                        if v is NIL:
                            falhas.append('XCTUnwrap(%s) deu nil' % um.group(1)[:80])
                            env.pop(nome, None)
                            continue
                    else:
                        v = avalia(ex, env)
                    env[nome] = v
                except Exception:
                    env.pop(nome, None)
            continue
        mm = re.match(r'(XCTAssert\w*)\((.*)\)$', st, re.S)
        if not mm:
            continue
        if ja(st):
            continue
        f, a = mm.group(1), separa(mm.group(2))
        if bloco != 0:
            nao.append((st[:160], 'dentro de bloco (if/for/closure)'))
            continue
        acc = None
        for q in a:
            if q.startswith('accuracy:'):
                acc = q[9:].strip()
        a = [q for q in a if not q.startswith('accuracy:')]
        try:
            if f in ('XCTAssertEqual', 'XCTAssertNotEqual'):
                x, y = avalia(a[0], env), avalia(a[1], env)
                if acc is not None:
                    e = avalia(acc, env)
                    if x is NIL or y is NIL:
                        ok = False
                    elif _isnum(x) and _isnum(y) and _isnum(e):
                        ok = abs(x - y) <= e
                    else:
                        raise NaoEntende('accuracy')
                else:
                    ok = igual(x, y)
                if f == 'XCTAssertNotEqual':
                    ok = not ok
                got = 'veio %s · esperado %s' % (_mostra(x), _mostra(y))
            elif f in ('XCTAssertTrue', 'XCTAssertFalse'):
                x = avalia(a[0], env)
                if not isinstance(x, bool):
                    raise NaoEntende('True/False sem Bool')
                ok = x if f == 'XCTAssertTrue' else not x
                got = 'veio %s' % _mostra(x)
            elif f in ('XCTAssertNil', 'XCTAssertNotNil'):
                x = avalia(a[0], env)
                ok = (x is NIL) == (f == 'XCTAssertNil')
                got = 'veio %s' % _mostra(x)
            elif f in ('XCTAssertGreaterThan', 'XCTAssertLessThan', 'XCTAssertGreaterThanOrEqual', 'XCTAssertLessThanOrEqual'):
                x, y = avalia(a[0], env), avalia(a[1], env)
                if not (_isnum(x) and _isnum(y)):
                    raise NaoEntende('comparação sem número')
                ok = {'XCTAssertGreaterThan': x > y, 'XCTAssertLessThan': x < y,
                      'XCTAssertGreaterThanOrEqual': x >= y, 'XCTAssertLessThanOrEqual': x <= y}[f]
                got = 'veio %s · %s %s' % (_mostra(x), f[9:], _mostra(y))
            else:
                raise NaoEntende(f)
        except NaoEntende as e:
            nao.append((st[:160], str(e)[:60]))
            continue
        except Exception as e:
            nao.append((st[:160], 'erro do avaliador: ' + str(e)[:50]))
            continue
        conf += 1
        if not ok:
            falhas.append('%s · %s' % (re.sub(r'\s+', ' ', st)[:140], got[:200]))
    return falhas, conf, nao


def _mostra(v):
    if v is NIL:
        return 'nil'
    if isinstance(v, frozenset):
        v = sorted(v, key=str)
    try:
        return json.dumps(v, ensure_ascii=False)[:120]
    except Exception:
        return str(v)[:120]
