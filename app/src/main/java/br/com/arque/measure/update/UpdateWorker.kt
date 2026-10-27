package br.com.arque.measure.update

import br.com.arque.measure.i18n.tr

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.work.Constraints
import androidx.work.CoroutineWorker
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.WorkerParameters
import br.com.arque.measure.MainActivity
import br.com.arque.measure.data.AppUpdater
import java.util.concurrent.TimeUnit

/** Procura versão nova em segundo plano (a cada ~3 h, com internet) e avisa com notificação. */
class UpdateWorker(ctx: Context, p: WorkerParameters) : CoroutineWorker(ctx, p) {
    override suspend fun doWork(): Result {
        val ctx = applicationContext
        val rel = runCatching { AppUpdater.latest() }.getOrNull() ?: return Result.success()
        val mine = AppUpdater.installedNumber(ctx)
        val sp = ctx.getSharedPreferences("arque.upd", Context.MODE_PRIVATE)
        if (rel.number > mine && sp.getInt("notified", 0) != rel.number) {
            notify(ctx, rel.number)
            sp.edit().putInt("notified", rel.number).apply()
        }
        return Result.success()
    }

    companion object {
        const val CHANNEL = "updates"
        const val EXTRA_UPDATE = "arque.update"

        fun schedule(ctx: Context) {
            val req = PeriodicWorkRequestBuilder<UpdateWorker>(3, TimeUnit.HOURS)
                .setConstraints(Constraints.Builder().setRequiredNetworkType(NetworkType.CONNECTED).build())
                .build()
            WorkManager.getInstance(ctx).enqueueUniquePeriodicWork("arque-update-check", ExistingPeriodicWorkPolicy.KEEP, req)
        }

        fun notify(ctx: Context, number: Int) {
            if (Build.VERSION.SDK_INT >= 33 &&
                ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
            ) return
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26 && nm.getNotificationChannel(CHANNEL) == null) {
                nm.createNotificationChannel(NotificationChannel(CHANNEL, tr("Atualizações do app"), NotificationManager.IMPORTANCE_HIGH))
            }
            val open = Intent(ctx, MainActivity::class.java).putExtra(EXTRA_UPDATE, true)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            val pi = PendingIntent.getActivity(ctx, 7301, open, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val n = NotificationCompat.Builder(ctx, CHANNEL)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle(tr("Atualização do Arquemestre disponível"))
                .setContentText(tr("Versão apk-{0}. Toque pra baixar e instalar — nada é perdido.", number))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pi)
                .addAction(0, tr("Baixar agora"), pi)
                .build()
            runCatching { nm.notify(7301, n) }
        }
    }
}
