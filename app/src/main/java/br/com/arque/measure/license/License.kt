package br.com.arque.measure.license

import br.com.arque.measure.i18n.tr

import android.content.Context
import java.security.MessageDigest
import java.util.Calendar

/**
 * APK do site: 3 dias de teste e depois mensalidade de R$ 29,90 (paga fora do app, pelo WhatsApp/Pix).
 * Cada pagamento libera 30 dias com a senha do mês: "<base>-<mês>" em 2026 (ex.: base-9, base-10)
 * e "<base>-<mês com 2 dígitos>-<ano com 2 dígitos>" a partir de 2027 (ex.: base-01-27, base-02-27…).
 * Aceita a senha do mês atual ou do mês anterior (pagou no fim do mês e digitou no dia 1º),
 * e cada senha só vale uma vez neste aparelho. Passados os 30 dias, o app bloqueia e pede a próxima.
 * Quem já tinha o desbloqueio antigo (pagamento único) continua liberado.
 * Google Play: só a assinatura mensal da loja (o teste grátis de 3 dias é a oferta da própria assinatura).
 * Fica nas preferências do app: atualizar o APK por cima mantém tudo (teste, mensalidade e dados).
 * Voltar o relógio do celular não estende nada (vale a maior data já vista).
 */
object License {
    val TRIAL_DAYS: Int = br.com.arque.measure.BuildConfig.TRIAL_DAYS
    val TRIAL_MS: Long = TRIAL_DAYS * 24L * 3600 * 1000
    const val PRICE = "R$ 29,90"
    const val PERIOD_DAYS = 30
    const val PERIOD_MS: Long = PERIOD_DAYS * 24L * 3600 * 1000
    const val WHATS = "5534984039955"

    /** SHA-256 do começo da senha do mês (o número em si não fica escrito no app). */
    private const val BASE_SHA = "e7c04298e569b1c5b82af9bbce92df16c01c192898d8edecfca1ecd8c4ac4a13"
    private const val BASE_LEN = 6

    private fun sp(ctx: Context) = ctx.getSharedPreferences("arque.lic", Context.MODE_PRIVATE)

    /** Marca o início do teste na primeira abertura e devolve true se for a primeira vez. */
    fun firstRun(ctx: Context): Boolean {
        val p = sp(ctx)
        if (p.getLong("start", 0L) != 0L) return false
        val now = System.currentTimeMillis()
        p.edit().putLong("start", now).putLong("seen", now).apply()
        return true
    }

    /** Agora, sem deixar o relógio voltar (vale a maior data já vista). */
    fun now(ctx: Context): Long {
        val p = sp(ctx)
        val now = System.currentTimeMillis()
        val seen = maxOf(p.getLong("seen", 0L), now)
        if (seen != p.getLong("seen", 0L)) p.edit().putLong("seen", seen).apply()
        return seen
    }

    /** Desbloqueio permanente: o antigo pagamento único ou a assinatura do Google Play. */
    fun isLifetime(ctx: Context): Boolean = sp(ctx).getBoolean("ok", false)

    /** Até quando a mensalidade está paga (0 = nunca pagou). */
    fun paidUntil(ctx: Context): Long = sp(ctx).getLong("paidUntil", 0L)

    /** Já pagou alguma mensalidade neste aparelho. */
    fun isMonthly(ctx: Context): Boolean = !isLifetime(ctx) && paidUntil(ctx) > 0L

    fun isUnlocked(ctx: Context): Boolean = isLifetime(ctx) || now(ctx) < paidUntil(ctx)

    /** Tempo de teste já usado (protegido contra voltar o relógio). */
    fun used(ctx: Context): Long {
        val start = sp(ctx).getLong("start", 0L).takeIf { it > 0 } ?: return 0L
        return (now(ctx) - start).coerceAtLeast(0L)
    }

    /** Bloqueia quando o teste acabou ou quando a mensalidade venceu. */
    fun isLocked(ctx: Context): Boolean {
        if (isUnlocked(ctx)) return false
        return paidUntil(ctx) > 0L || used(ctx) >= TRIAL_MS
    }

    private fun label(left: Long): String {
        val h = left / 3_600_000L
        return when {
            h >= 24 -> tr("{0} dia", h / 24) + (if (h / 24 > 1) "s" else "") + (if (h % 24 > 0 && h < 72) " e ${h % 24} h" else "")
            h >= 1 -> "$h h"
            else -> tr("{0} min", (left / 60_000L).coerceAtLeast(1L))
        }
    }

    /** Texto curto do que falta do teste: "1 dia e 5 h", "3 h"… */
    fun leftLabel(ctx: Context): String = label((TRIAL_MS - used(ctx)).coerceAtLeast(0L))

    /** Quanto falta pra vencer a mensalidade ("" se não paga por mês ou se faltam mais de 3 dias). */
    fun payLeftLabel(ctx: Context, all: Boolean = false): String {
        if (!isMonthly(ctx)) return ""
        val left = paidUntil(ctx) - now(ctx)
        if (left <= 0L) return ""
        if (!all && left > 3L * 24 * 3600 * 1000) return ""
        return label(left)
    }

    /** Final da senha de um mês: "9", "10"… em 2026; "0127", "0227"… (mês e ano com 2 dígitos) de 2027 em diante. */
    fun monthKey(year: Int, month: Int): String =
        if (year <= 2026) month.toString() else String.format(java.util.Locale.ROOT, "%02d%02d", month, year % 100)

    /** Senhas que valem agora: a do mês atual e a do mês anterior. */
    private fun validKeys(atMs: Long): List<String> {
        val c = Calendar.getInstance().apply { timeInMillis = atMs }
        val cur = monthKey(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1)
        c.add(Calendar.MONTH, -1)
        val prev = monthKey(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1)
        return listOf(cur, prev)
    }

    /** Confere a senha do mês (com ou sem os tracinhos) e libera mais 30 dias. */
    fun tryUnlock(ctx: Context, code: String): Boolean {
        val c = code.trim().filter { it.isDigit() }
        if (c.length <= BASE_LEN || sha(c.take(BASE_LEN)) != BASE_SHA) return false
        val key = c.drop(BASE_LEN)
        val at = now(ctx)
        if (key !in validKeys(at)) return false
        val p = sp(ctx)
        val usedKeys = p.getStringSet("keys", emptySet()) ?: emptySet()
        if (key in usedKeys) return false
        val until = maxOf(p.getLong("paidUntil", 0L), at) + PERIOD_MS
        p.edit().putLong("paidUntil", until).putStringSet("keys", usedKeys + key).apply()
        return true
    }

    /** A senha já foi usada neste aparelho (pra avisar em vez de só dizer "incorreta"). */
    fun wasUsed(ctx: Context, code: String): Boolean {
        val c = code.trim().filter { it.isDigit() }
        if (c.length <= BASE_LEN || sha(c.take(BASE_LEN)) != BASE_SHA) return false
        return c.drop(BASE_LEN) in (sp(ctx).getStringSet("keys", emptySet()) ?: emptySet())
    }

    /** Assinatura ativa confirmada pelo Google Play. */
    fun grantStore(ctx: Context) {
        sp(ctx).edit().putBoolean("ok", true).putBoolean("store", true).putBoolean("hadStore", true).apply()
    }

    /** Já assinou alguma vez neste aparelho (pra dizer "sua assinatura terminou" em vez das boas-vindas). */
    fun hadStore(ctx: Context): Boolean = sp(ctx).getBoolean("hadStore", false)

    /** O Google Play diz que não há compra (reembolso): tira só o desbloqueio que veio da loja. */
    fun revokeStore(ctx: Context) {
        val p = sp(ctx)
        if (p.getBoolean("store", false)) p.edit().putBoolean("ok", false).putBoolean("store", false).apply()
    }

    fun sha(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).joinToString("") { "%02x".format(it) }
}
