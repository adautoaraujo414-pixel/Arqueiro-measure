@file:Suppress("unused", "UNCHECKED_CAST")

package androidx.activity.compose

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResult
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import br.com.arque.measure.desktop.BackDispatcher
import br.com.arque.measure.desktop.DesktopActions
import br.com.arque.measure.desktop.DesktopFiles

class ManagedActivityResultLauncher<I, O> internal constructor(
    private val contract: ActivityResultContract<I, O>,
    private val onResult: () -> (O) -> Unit,
) : ActivityResultLauncher<I>() {
    override fun launch(input: I) {
        val cb = onResult()
        val r: Any? = when (contract) {
            is ActivityResultContracts.GetContent -> DesktopFiles.open(input as String, multiple = false).firstOrNull()?.let { Uri.fromFile(it) }
            is ActivityResultContracts.GetMultipleContents -> DesktopFiles.open(input as String, multiple = true).map { Uri.fromFile(it) }
            is ActivityResultContracts.OpenDocument -> DesktopFiles.open((input as Array<String>).firstOrNull() ?: "*/*", multiple = false).firstOrNull()?.let { Uri.fromFile(it) }
            is ActivityResultContracts.CreateDocument -> DesktopFiles.save(input as String, contract.mimeType)?.let { Uri.fromFile(it) }
            // sem câmera no computador: escolhe uma foto do PC e ela entra no lugar da foto tirada
            is ActivityResultContracts.TakePicture -> DesktopFiles.pickPhotoInto(input as Uri)
            is ActivityResultContracts.RequestPermission -> true
            is ActivityResultContracts.RequestMultiplePermissions -> (input as Array<String>).associateWith { true }
            is ActivityResultContracts.StartActivityForResult -> { DesktopActions.start(input as Intent); ActivityResult(0, null) }
            else -> null
        }
        cb(r as O)
    }
}

@Composable
fun <I, O> rememberLauncherForActivityResult(contract: ActivityResultContract<I, O>, onResult: (O) -> Unit): ManagedActivityResultLauncher<I, O> {
    val cur = rememberUpdatedState(onResult)
    return remember(contract::class) { ManagedActivityResultLauncher(contract) { cur.value } }
}

/** "Voltar" do Android = tecla Esc (ou o botão Voltar do mouse) no Windows. */
@Composable
fun BackHandler(enabled: Boolean = true, onBack: () -> Unit) {
    val cb = rememberUpdatedState(onBack)
    val en = rememberUpdatedState(enabled)
    DisposableEffect(Unit) {
        val h = BackDispatcher.Handler({ en.value }) { cb.value() }
        BackDispatcher.add(h)
        onDispose { BackDispatcher.remove(h) }
    }
}
