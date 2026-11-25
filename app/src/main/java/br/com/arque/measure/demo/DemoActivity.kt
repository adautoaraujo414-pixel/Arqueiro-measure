package br.com.arque.measure.demo

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.BuildConfig
import br.com.arque.measure.data.DataBackup
import br.com.arque.measure.data.Store
import br.com.arque.measure.i18n.tr
import br.com.arque.measure.model.Index
import br.com.arque.measure.model.Note
import br.com.arque.measure.ui.App
import br.com.arque.measure.ui.ArqueTheme

/** Mesmas telas e cálculos, com dados separados e sem iniciar compras. Não é exportada. */
class DemoActivity : ComponentActivity() {
    private lateinit var vm: AppViewModel
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (!BuildConfig.PLAY) { finish(); return }
        enableEdgeToEdge()
        val app = DemoSpace.application(applicationContext)
        DataBackup.applyPending(app)
        val prefs = app.getSharedPreferences("sample", MODE_PRIVATE)
        if (!prefs.getBoolean("created", false)) {
            val sample = java.io.File(app.filesDir, "moveis/projects.json")
            if (!sample.exists()) {
                sample.parentFile?.mkdirs()
                app.assets.open("demo-projects.json").use { input -> sample.outputStream().use { input.copyTo(it) } }
            }
            val store = Store(java.io.File(app.filesDir, "projects"))
            // Só cria a primeira amostra; nunca repõe o que a pessoa editou ou apagou.
            if (store.loadIndex().notes.isEmpty()) {
                val note = Note(name = tr("Exemplo de medição — demonstração"))
                store.saveNote(note)
                store.saveIndex(Index(notes = listOf(note.meta())))
            }
            prefs.edit().putBoolean("created", true).apply()
        }
        vm = ViewModelProvider(this, object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T = AppViewModel(app, demonstration = true) as T
        })[AppViewModel::class.java]
        vm.checkLicense()
        intent.getStringExtra(br.com.arque.measure.agenda.AgendaReminders.EXTRA_APPT)?.let { vm.openAppointment(it) }
        val context = DemoContext(this, app)
        setContent {
            ArqueTheme {
                CompositionLocalProvider(LocalContext provides context) {
                    Column(Modifier.fillMaxSize()) {
                        Surface {
                            Row(Modifier.statusBarsPadding().padding(horizontal = 12.dp)) {
                                Text(tr("Demonstração · dados separados"), Modifier.weight(1f).padding(vertical = 14.dp))
                                TextButton(onClick = { vm.flush(); finish() }) { Text(tr("Sair")) }
                            }
                        }
                        androidx.compose.foundation.layout.Box(Modifier.weight(1f)) { App(vm) }
                    }
                }
            }
        }
    }
    override fun onStop() {
        if (::vm.isInitialized) vm.flush()
        super.onStop()
    }
}
