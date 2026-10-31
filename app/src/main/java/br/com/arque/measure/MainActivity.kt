package br.com.arque.measure

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import br.com.arque.measure.ui.App
import br.com.arque.measure.ui.ArqueTheme

class MainActivity : ComponentActivity() {
    private val vm: AppViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        // restauração de backup pendente: aplica antes de abrir qualquer tela
        br.com.arque.measure.data.DataBackup.applyPending(applicationContext)
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        br.com.arque.measure.ui.PalmGuard.pxPerMm = resources.displayMetrics.xdpi / 25.4f
        handleIntent(intent)
        vm.checkLicense()
        vm.startStore()
        vm.autoCheckUpdate()
        if (!BuildConfig.PLAY) runCatching { br.com.arque.measure.update.UpdateWorker.schedule(applicationContext) }
        setContent {
            // trocar o idioma redesenha o app inteiro no idioma novo (nada é perdido: tudo fica no ViewModel)
            ArqueTheme { androidx.compose.runtime.key(br.com.arque.measure.i18n.I18n.lang) { App(vm) } }
        }
    }

    override fun dispatchTouchEvent(ev: android.view.MotionEvent): Boolean {
        br.com.arque.measure.ui.PalmGuard.record(ev)
        return super.dispatchTouchEvent(ev)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    /** Toque numa notificação da agenda: abre direto o compromisso. */
    private fun handleIntent(i: android.content.Intent?) {
        // link do plano de corte (convite do WhatsApp): arquemestre://corte?d=...
        i?.data?.let { u ->
            if (u.scheme == "arquemestre" && u.host == "corte") {
                u.getQueryParameter("d")?.let { vm.openCutLink(it) }
                i.data = null
            }
        }
        i?.getStringExtra(br.com.arque.measure.agenda.AgendaReminders.EXTRA_APPT)?.let { vm.openAppointment(it) }
        // toque na notificação de versão nova: já baixa e abre o instalador
        if (!BuildConfig.PLAY && i?.getBooleanExtra(br.com.arque.measure.update.UpdateWorker.EXTRA_UPDATE, false) == true) {
            i.removeExtra(br.com.arque.measure.update.UpdateWorker.EXTRA_UPDATE)
            vm.acceptUpdate()
        }
    }

    /**
     * Quem ainda não tinha o app: a página do convite copia o código antes de mandar pra loja.
     * Nas primeiras aberturas depois de instalar, o app procura esse código e já abre o plano de corte.
     */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (!hasFocus) return
        val sp = getSharedPreferences("arque.cutclip", MODE_PRIVATE)
        val n = sp.getInt("n", 0)
        if (n >= 6) return
        sp.edit().putInt("n", n + 1).apply()
        runCatching {
            val cm = getSystemService(android.content.ClipboardManager::class.java) ?: return
            if (cm.primaryClipDescription?.hasMimeType(android.content.ClipDescription.MIMETYPE_TEXT_PLAIN) != true) return
            val txt = cm.primaryClip?.getItemAt(0)?.coerceToText(this)?.toString().orEmpty().trim()
            if (AppViewModel.cutCodeOf(txt) != null) {
                sp.edit().putInt("n", 99).apply()
                if (android.os.Build.VERSION.SDK_INT >= 28) cm.clearPrimaryClip() else cm.setPrimaryClip(android.content.ClipData.newPlainText("", ""))
                vm.openCutLink(txt)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        vm.checkLicense()
        vm.autoCheckUpdate()
    }

    /** Garante que nada fique sem gravar ao sair do app. */
    override fun onStop() {
        vm.flush()
        // cópia automática dos dados em Downloads/ArqueMeasure (sobrevive a desinstalação)
        val ctx = applicationContext
        Thread { runCatching { br.com.arque.measure.data.DataBackup.autoBackup(ctx) } }.start()
        super.onStop()
    }
}
