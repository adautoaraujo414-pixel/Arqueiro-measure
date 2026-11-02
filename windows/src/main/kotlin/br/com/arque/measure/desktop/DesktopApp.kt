package br.com.arque.measure.desktop

import android.app.Application
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import java.awt.Frame

/** Estado global do app no Windows (um processo, uma janela). */
object DesktopApp {
    val context: Application = Application()

    /** A janela principal (pai das janelas de abrir/salvar arquivo). */
    @Volatile var frame: Frame? = null

    /** Aviso curto na tela (o "toast" do Android). */
    var toast by mutableStateOf<String?>(null)

    fun toast(msg: String) { toast = msg }

    /** Fecha o app pela janela (usado pelo atualizador e pela restauração de backup). */
    @Volatile var requestExit: (() -> Unit)? = null

    /** Abre um compromisso da agenda (clique no aviso do Windows). */
    @Volatile var openAppointment: ((String) -> Unit)? = null

    /** Traz a janela pra frente (clique na notificação). */
    @Volatile var bringToFront: (() -> Unit)? = null
}
