package br.com.arque.measure.agenda

import br.com.arque.measure.i18n.tr

import android.content.Context
import br.com.arque.measure.desktop.DesktopApp
import br.com.arque.measure.desktop.Notifier
import br.com.arque.measure.model.Appointment
import java.util.Date
import java.util.Timer
import java.util.TimerTask

/**
 * Avisos da agenda no Windows: notificação do Windows (canto da tela) na hora marcada.
 * Funcionam enquanto o Arquemestre estiver aberto (mesmo minimizado). Ao abrir o app,
 * avisos que venceram com ele fechado aparecem de uma vez (até 12 h de atraso).
 */
object AgendaReminders {
    const val CHANNEL = "agenda"
    const val EXTRA_APPT = "appt_id"
    private val dayFmt get() = br.com.arque.measure.i18n.I18n.shortDayFormat()
    private val hourFmt get() = br.com.arque.measure.i18n.I18n.hourFormat()

    private val timer by lazy { Timer("arque-agenda", true) }
    private val tasks = HashMap<String, MutableList<TimerTask>>()

    /** Para os testes: avisos mostrados (título). */
    val shown = ArrayList<String>()

    fun ensureChannel(@Suppress("UNUSED_PARAMETER") ctx: Context) {}

    fun cancel(@Suppress("UNUSED_PARAMETER") ctx: Context, a: Appointment) {
        synchronized(tasks) { tasks.remove(a.id)?.forEach { it.cancel() } }
    }

    fun canExact(@Suppress("UNUSED_PARAMETER") ctx: Context): Boolean = true

    private fun prefs(ctx: Context) = ctx.getSharedPreferences("arque.agenda.shown", Context.MODE_PRIVATE)

    fun schedule(ctx: Context, a: Appointment) {
        cancel(ctx, a)
        if (a.done) return
        val now = System.currentTimeMillis()
        val list = ArrayList<TimerTask>()
        a.remindMin.distinct().forEach { off ->
            val at = a.startMs - off * 60_000L
            val key = "${a.id}@$off@${a.startMs}"
            if (prefs(ctx).getBoolean(key, false)) return@forEach
            if (at <= now) {
                // venceu com o app fechado: avisa agora se ainda faz sentido (até 12 h)
                if (now - at < 12 * 3600_000L && a.startMs > now - 3600_000L) { show(ctx, a, off); prefs(ctx).edit().putBoolean(key, true).apply() }
                return@forEach
            }
            val t = object : TimerTask() {
                override fun run() { show(ctx, a, off); prefs(ctx).edit().putBoolean(key, true).apply() }
            }
            timer.schedule(t, Date(at))
            list += t
        }
        if (list.isNotEmpty()) synchronized(tasks) { tasks[a.id] = list }
    }

    fun scheduleAll(ctx: Context, list: List<Appointment>) = list.forEach { schedule(ctx, it) }

    fun whenText(a: Appointment, off: Int): String = when {
        off == 0 -> tr("agora")
        off < 60 -> tr("em {0} min", off)
        off < 1440 -> tr("em {0} h", off / 60)
        off == 1440 -> tr("amanhã")
        else -> tr("em {0} dias", off / 1440)
    }

    fun show(@Suppress("UNUSED_PARAMETER") ctx: Context, a: Appointment, off: Int) {
        if (a.done) return
        val title = "${a.kind.icon} ${a.kind.label}: ${a.title.ifBlank { a.clientName.ifBlank { tr("sem título") } }}"
        val body = buildString {
            append(dayFmt.format(Date(a.startMs))).append(tr(" às ")).append(hourFmt.format(Date(a.startMs)))
            append(" (").append(whenText(a, off)).append(")")
            if (a.clientName.isNotBlank()) append(" · ").append(a.clientName)
            if (a.address.isNotBlank()) append("\n").append(a.address)
        }
        synchronized(shown) { shown += title }
        Notifier.show(title, body) { DesktopApp.openAppointment?.invoke(a.id) }
    }
}
