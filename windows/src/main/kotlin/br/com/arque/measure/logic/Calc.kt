package br.com.arque.measure.logic

import java.util.Locale

/** Calculadora simples: + − × ÷, %, parênteses, vírgula ou ponto decimal. Lógica pura. */
object Calc {
    /** Resultado, ou null se a expressão for inválida (ou divisão por zero). */
    fun eval(expr: String): Double? {
        val s = expr.replace(" ", "").replace(',', '.').replace('×', '*').replace('÷', '/').replace('−', '-')
        if (s.isEmpty()) return null
        val p = Parser(s)
        val v = runCatching { p.parseExpr() }.getOrNull() ?: return null
        if (p.pos != s.length) return null
        return v.takeIf { it.isFinite() }
    }

    fun format(v: Double): String {
        val r = Math.round(v * 1_000_000.0) / 1_000_000.0
        val txt = if (r == Math.rint(r) && Math.abs(r) < 1e12) String.format(Locale.US, "%.0f", r)
        else String.format(Locale.US, "%.6f", r).trimEnd('0').trimEnd('.')
        return txt.replace('.', ',')
    }

    private class Parser(val s: String) {
        var pos = 0
        fun parseExpr(): Double {
            var v = parseTerm()
            while (pos < s.length && (s[pos] == '+' || s[pos] == '-')) {
                val op = s[pos++]
                val r = parseTerm()
                v = if (op == '+') v + r else v - r
            }
            return v
        }
        fun parseTerm(): Double {
            var v = parseUnary()
            while (pos < s.length && (s[pos] == '*' || s[pos] == '/')) {
                val op = s[pos++]
                val r = parseUnary()
                if (op == '/' && r == 0.0) throw ArithmeticException()
                v = if (op == '*') v * r else v / r
            }
            return v
        }
        fun parseUnary(): Double {
            if (pos < s.length && s[pos] == '-') { pos++; return -parseUnary() }
            if (pos < s.length && s[pos] == '+') { pos++; return parseUnary() }
            var v = parseAtom()
            while (pos < s.length && s[pos] == '%') { pos++; v /= 100.0 }
            return v
        }
        fun parseAtom(): Double {
            if (pos < s.length && s[pos] == '(') {
                pos++
                val v = parseExpr()
                if (pos >= s.length || s[pos] != ')') throw IllegalArgumentException()
                pos++
                return v
            }
            val st = pos
            while (pos < s.length && (s[pos].isDigit() || s[pos] == '.')) pos++
            if (st == pos) throw IllegalArgumentException()
            return s.substring(st, pos).toDouble()
        }
    }
}
