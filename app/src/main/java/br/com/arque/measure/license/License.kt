package br.com.arque.measure.license

import br.com.arque.measure.i18n.tr

import android.content.Context
import java.security.MessageDigest

/**
 * Período de teste (2 dias no APK do site, 3 dias no Google Play) e desbloqueio
 * por senha (site) ou pela compra no Google Play (play).
 * Fica nas preferências do app: atualizar o APK por cima mantém tudo (teste, desbloqueio e dados).
 * Voltar o relógio do celular não estende o teste (vale a maior data já vista).
 */
object License {
    val TRIAL_DAYS: Int = br.com.arque.measure.BuildConfig.TRIAL_DAYS
    val TRIAL_MS: Long = TRIAL_DAYS * 24L * 3600 * 1000
    const val PRICE = "R$ 149,90"
    const val WHATS = "5534984039955"

    /** SHA-256 da senha de desbloqueio (a senha em si não fica escrita no app). */
    private const val CODE_SHA = "e7c04298e569b1c5b82af9bbce92df16c01c192898d8edecfca1ecd8c4ac4a13"

    private fun sp(ctx: Context) = ctx.getSharedPreferences("arque.lic", Context.MODE_PRIVATE)

    /** Marca o início do teste na primeira abertura e devolve true se for a primeira vez. */
    fun firstRun(ctx: Context): Boolean {
        val p = sp(ctx)
        if (p.getLong("start", 0L) != 0L) return false
        val now = System.currentTimeMillis()
        p.edit().putLong("start", now).putLong("seen", now).apply()
        return true
    }

    fun isUnlocked(ctx: Context): Boolean = sp(ctx).getBoolean("ok", false)

    /** Tempo de teste já usado (protegido contra voltar o relógio). */
    fun used(ctx: Context): Long {
        val p = sp(ctx)
        val start = p.getLong("start", 0L).takeIf { it > 0 } ?: return 0L
        val now = System.currentTimeMillis()
        val seen = maxOf(p.getLong("seen", start), now)
        if (seen != p.getLong("seen", 0L)) p.edit().putLong("seen", seen).apply()
        return (seen - start).coerceAtLeast(0L)
    }

    fun isLocked(ctx: Context): Boolean = !isUnlocked(ctx) && used(ctx) >= TRIAL_MS

    /** Texto curto do que falta: "1 dia e 5 h", "3 h"… */
    fun leftLabel(ctx: Context): String {
        val left = (TRIAL_MS - used(ctx)).coerceAtLeast(0L)
        val h = left / 3_600_000L
        return when {
            h >= 24 -> tr("{0} dia", h / 24) + (if (h / 24 > 1) "s" else "") + (if (h % 24 > 0) " e ${h % 24} h" else "")
            h >= 1 -> "$h h"
            else -> tr("{0} min", left / 60_000L)
        }
    }

    fun tryUnlock(ctx: Context, code: String): Boolean {
        val c = code.trim().filter { it.isDigit() }
        if (c.isEmpty()) return false
        val ok = sha(c) == CODE_SHA
        if (ok) sp(ctx).edit().putBoolean("ok", true).apply()
        return ok
    }

    /** Compra confirmada pelo Google Play. */
    fun grantStore(ctx: Context) {
        sp(ctx).edit().putBoolean("ok", true).putBoolean("store", true).apply()
    }

    /** O Google Play diz que não há compra (reembolso): tira só o desbloqueio que veio da loja. */
    fun revokeStore(ctx: Context) {
        val p = sp(ctx)
        if (p.getBoolean("store", false)) p.edit().putBoolean("ok", false).putBoolean("store", false).apply()
    }

    fun sha(s: String): String =
        MessageDigest.getInstance("SHA-256").digest(s.toByteArray()).joinToString("") { "%02x".format(it) }
}
