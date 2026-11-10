package br.com.arque.measure.model

import java.util.Calendar

/**
 * Feriados do Brasil na agenda, calculados sozinhos pra qualquer ano (sem internet):
 * feriados nacionais, pontos facultativos e datas comemorativas — inclusive os que mudam
 * com a Páscoa (Carnaval, Sexta-feira Santa, Corpus Christi) e os de "2º domingo"
 * (Dia das Mães, Dia dos Pais).
 */
object Holidays {
    enum class Kind { FERIADO, FACULTATIVO, COMEMORATIVA }

    /** month = 1..12 */
    data class Day(val year: Int, val month: Int, val day: Int, val name: String, val kind: Kind) {
        val kindLabel: String get() = when (kind) {
            Kind.FERIADO -> "Feriado nacional"
            Kind.FACULTATIVO -> "Ponto facultativo"
            Kind.COMEMORATIVA -> "Data comemorativa"
        }
    }

    /** Domingo de Páscoa (algoritmo de Meeus/Jones/Butcher, calendário gregoriano). Retorna (mês 1..12, dia). */
    fun easter(y: Int): Pair<Int, Int> {
        val a = y % 19; val b = y / 100; val c = y % 100; val d = b / 4; val e = b % 4
        val f = (b + 8) / 25; val g = (b - f + 1) / 3; val h = (19 * a + b - d - g + 15) % 30
        val i = c / 4; val k = c % 4; val l = (32 + 2 * e + 2 * i - h - k) % 7; val m = (a + 11 * h + 22 * l) / 451
        val month = (h + l - 7 * m + 114) / 31
        val day = ((h + l - 7 * m + 114) % 31) + 1
        return month to day
    }

    private fun shifted(y: Int, m: Int, d: Int, days: Int): Triple<Int, Int, Int> {
        val c = Calendar.getInstance(); c.clear(); c.set(y, m - 1, d, 12, 0); c.add(Calendar.DAY_OF_MONTH, days)
        return Triple(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH))
    }

    /** n-ésimo domingo do mês (1 = primeiro). */
    fun nthSunday(y: Int, m: Int, n: Int): Int {
        val c = Calendar.getInstance(); c.clear(); c.set(y, m - 1, 1, 12, 0)
        val first = 1 + (Calendar.SUNDAY - c.get(Calendar.DAY_OF_WEEK) + 7) % 7
        return first + 7 * (n - 1)
    }

    private val cache = HashMap<Int, List<Day>>()

    /** Todas as datas do ano, em ordem. */
    fun of(y: Int): List<Day> = synchronized(cache) {
        cache.getOrPut(y) {
            val r = ArrayList<Day>()
            fun add(m: Int, d: Int, n: String, k: Kind) { r += Day(y, m, d, n, k) }
            fun addE(off: Int, n: String, k: Kind) { val (yy, mm, dd) = shifted(y, easter(y).first, easter(y).second, off); r += Day(yy, mm, dd, n, k) }
            add(1, 1, "Confraternização Universal", Kind.FERIADO)
            addE(-48, "Carnaval", Kind.FACULTATIVO)
            addE(-47, "Carnaval", Kind.FACULTATIVO)
            addE(-46, "Quarta-feira de Cinzas", Kind.FACULTATIVO)
            add(3, 8, "Dia Internacional da Mulher", Kind.COMEMORATIVA)
            add(3, 19, "Dia do Marceneiro e do Carpinteiro", Kind.COMEMORATIVA)
            addE(-2, "Sexta-feira Santa", Kind.FERIADO)
            addE(0, "Páscoa", Kind.COMEMORATIVA)
            add(4, 21, "Tiradentes", Kind.FERIADO)
            add(5, 1, "Dia do Trabalho", Kind.FERIADO)
            add(5, nthSunday(y, 5, 2), "Dia das Mães", Kind.COMEMORATIVA)
            addE(60, "Corpus Christi", Kind.FACULTATIVO)
            add(6, 12, "Dia dos Namorados", Kind.COMEMORATIVA)
            add(8, nthSunday(y, 8, 2), "Dia dos Pais", Kind.COMEMORATIVA)
            add(9, 7, "Independência do Brasil", Kind.FERIADO)
            add(10, 12, "Nossa Senhora Aparecida", Kind.FERIADO)
            add(10, 12, "Dia das Crianças", Kind.COMEMORATIVA)
            add(10, 15, "Dia do Professor", Kind.COMEMORATIVA)
            add(10, 28, "Dia do Servidor Público", Kind.FACULTATIVO)
            add(11, 2, "Finados", Kind.FERIADO)
            add(11, 15, "Proclamação da República", Kind.FERIADO)
            // feriado nacional desde 2024 (Lei 14.759/2023); antes era data comemorativa
            add(11, 20, "Dia da Consciência Negra", if (y >= 2024) Kind.FERIADO else Kind.COMEMORATIVA)
            add(12, 24, "Véspera de Natal", Kind.FACULTATIVO)
            add(12, 25, "Natal", Kind.FERIADO)
            add(12, 31, "Véspera de Ano-Novo", Kind.FACULTATIVO)
            r.sortedWith(compareBy({ it.month }, { it.day }, { it.kind.ordinal }))
        }
    }

    /** Datas de um dia (month 1..12). */
    fun on(y: Int, m: Int, d: Int, feriados: Boolean = true, comemorativas: Boolean = true): List<Day> =
        of(y).filter { it.month == m && it.day == d && show(it, feriados, comemorativas) }

    /** Datas de um dia a partir do início do dia em milissegundos (fuso do aparelho). */
    fun onMs(dayMs: Long, feriados: Boolean = true, comemorativas: Boolean = true): List<Day> {
        val c = Calendar.getInstance().apply { timeInMillis = dayMs }
        return on(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1, c.get(Calendar.DAY_OF_MONTH), feriados, comemorativas)
    }

    fun show(h: Day, feriados: Boolean, comemorativas: Boolean): Boolean =
        if (h.kind == Kind.COMEMORATIVA) comemorativas else feriados

    /** Próximas datas a partir de hoje (inclusive), até [n]. */
    fun upcoming(fromMs: Long, n: Int, feriados: Boolean = true, comemorativas: Boolean = true): List<Day> {
        val c = Calendar.getInstance().apply { timeInMillis = fromMs }
        val y = c.get(Calendar.YEAR); val m = c.get(Calendar.MONTH) + 1; val d = c.get(Calendar.DAY_OF_MONTH)
        return (of(y) + of(y + 1)).filter { show(it, feriados, comemorativas) }
            .filter { it.year > y || it.month > m || (it.month == m && it.day >= d) }
            .take(n)
    }

    /** Cor do chip na agenda (igual a ideia do Google Agenda: feriado verde). */
    fun argb(k: Kind): Long = when (k) {
        Kind.FERIADO -> 0xFF0B8043
        Kind.FACULTATIVO -> 0xFF33B679
        Kind.COMEMORATIVA -> 0xFF8E24AA
    }
}
