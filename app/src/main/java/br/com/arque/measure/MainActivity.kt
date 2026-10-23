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
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        handleIntent(intent)
        setContent {
            ArqueTheme { App(vm) }
        }
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    /** Toque numa notificação da agenda: abre direto o compromisso. */
    private fun handleIntent(i: android.content.Intent?) {
        i?.getStringExtra(br.com.arque.measure.agenda.AgendaReminders.EXTRA_APPT)?.let { vm.openAppointment(it) }
    }

    /** Garante que nada fique sem gravar ao sair do app. */
    override fun onStop() {
        vm.flush()
        super.onStop()
    }
}
