package br.com.arque.measure.agenda

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import br.com.arque.measure.MainActivity
import br.com.arque.measure.data.Store
import br.com.arque.measure.model.Appointment
import br.com.arque.measure.model.REMIND_OPTIONS
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Avisos da agenda: um alarme do sistema por (compromisso, antecedência). Sobrevivem a fechar o app e a reiniciar o aparelho. */
object AgendaReminders {
    const val CHANNEL = "agenda"
    const val EXTRA_APPT = "appt_id"
    private val allOffsets = REMIND_OPTIONS.map { it.first }
    private val dayFmt = SimpleDateFormat("EEE dd/MM", Locale("pt", "BR"))
    private val hourFmt = SimpleDateFormat("HH:mm", Locale("pt", "BR"))

    fun ensureChannel(ctx: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL) == null) {
                nm.createNotificationChannel(
                    NotificationChannel(CHANNEL, "Agenda (entregas e visitas)", NotificationManager.IMPORTANCE_HIGH)
                        .apply { description = "Lembretes dos compromissos da agenda" },
                )
            }
        }
    }

    private fun pending(ctx: Context, a: Appointment, off: Int, create: Boolean): PendingIntent? {
        val i = Intent(ctx, ReminderReceiver::class.java).setAction("br.com.arque.measure.REMIND")
            .putExtra(EXTRA_APPT, a.id).putExtra("off", off)
        val code = (a.id.hashCode() * 31 + off) and 0x7fffffff
        val flags = PendingIntent.FLAG_IMMUTABLE or (if (create) PendingIntent.FLAG_UPDATE_CURRENT else PendingIntent.FLAG_NO_CREATE)
        return PendingIntent.getBroadcast(ctx, code, i, flags)
    }

    fun cancel(ctx: Context, a: Appointment) {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        (allOffsets + a.remindMin).distinct().forEach { off -> pending(ctx, a, off, false)?.let { am.cancel(it); it.cancel() } }
    }

    fun canExact(ctx: Context): Boolean {
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return Build.VERSION.SDK_INT < 31 || am.canScheduleExactAlarms()
    }

    fun schedule(ctx: Context, a: Appointment) {
        cancel(ctx, a)
        if (a.done) return
        val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        val exact = canExact(ctx)
        a.remindMin.distinct().forEach { off ->
            val at = a.startMs - off * 60_000L
            if (at <= now) return@forEach
            val pi = pending(ctx, a, off, true) ?: return@forEach
            try {
                if (exact) am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
                else am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } catch (_: SecurityException) {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            }
        }
    }

    fun scheduleAll(ctx: Context, list: List<Appointment>) = list.forEach { schedule(ctx, it) }

    fun whenText(a: Appointment, off: Int): String = when {
        off == 0 -> "agora"
        off < 60 -> "em $off min"
        off < 1440 -> "em ${off / 60} h"
        off == 1440 -> "amanhã"
        else -> "em ${off / 1440} dias"
    }

    fun show(ctx: Context, a: Appointment, off: Int) {
        if (a.done) return
        ensureChannel(ctx)
        val open = PendingIntent.getActivity(
            ctx, a.id.hashCode(),
            Intent(ctx, MainActivity::class.java).putExtra(EXTRA_APPT, a.id).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val title = "${a.kind.icon} ${a.kind.label}: ${a.title.ifBlank { a.clientName.ifBlank { "sem título" } }}"
        val body = buildString {
            append(dayFmt.format(Date(a.startMs))).append(" às ").append(hourFmt.format(Date(a.startMs)))
            append(" (").append(whenText(a, off)).append(")")
            if (a.clientName.isNotBlank()) append(" · ").append(a.clientName)
            if (a.address.isNotBlank()) append("\n").append(a.address)
        }
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(android.R.drawable.ic_popup_reminder)
            .setContentTitle(title).setContentText(body.lineSequence().first())
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open).setAutoCancel(true).setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_HIGH).build()
        try {
            NotificationManagerCompat.from(ctx).notify((a.id.hashCode() * 31 + off) and 0x7fffffff, n)
        } catch (_: SecurityException) { /* sem permissão de notificação */ }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        val id = intent.getStringExtra(AgendaReminders.EXTRA_APPT) ?: return
        val off = intent.getIntExtra("off", 0)
        val a = Store(File(ctx.filesDir, "projects")).loadAgenda().firstOrNull { it.id == id } ?: return
        AgendaReminders.show(ctx, a, off)
    }
}

/** Depois de reiniciar o aparelho (ou atualizar o app) os alarmes são recriados. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        AgendaReminders.scheduleAll(ctx, Store(File(ctx.filesDir, "projects")).loadAgenda())
    }
}
