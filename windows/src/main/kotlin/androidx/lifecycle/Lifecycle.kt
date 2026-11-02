@file:Suppress("unused")

package androidx.lifecycle

import android.app.Application
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

/** ViewModel do Android no Windows: vive enquanto a janela do app estiver aberta. */
abstract class AndroidViewModel(private val app: Application) {
    internal val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)

    @Suppress("UNCHECKED_CAST")
    fun <T : Application> getApplication(): T = app as T

    protected open fun onCleared() {}

    /** Chamado ao fechar o app. */
    fun clear() {
        runCatching { onCleared() }
        scope.cancel()
    }
}

val AndroidViewModel.viewModelScope: CoroutineScope get() = scope
