package br.com.arque.measure.share

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * "Ver o projeto ao vivo de outro celular" usa Bluetooth clássico entre celulares.
 * No Windows não há esse canal: compartilhar fica desligado (projeto vai por backup/arquivo).
 */
object BtShare {
    const val PREFIX = "Arquemestre"

    fun shareName(company: String): String {
        val who = company.trim().replace(Regex("\\s+"), " ")
        return (if (who.isBlank()) PREFIX else "$PREFIX · $who").take(40)
    }

    fun isArquemestreName(name: String?): Boolean = name?.trim()?.startsWith(PREFIX, ignoreCase = true) == true

    fun displayName(name: String?, address: String): String {
        val n = name?.trim().orEmpty()
        return if (isArquemestreName(n)) n else if (n.isNotEmpty()) "$PREFIX · $n" else "$PREFIX · $address"
    }

    fun restoreName(@Suppress("UNUSED_PARAMETER") ctx: Context) {}

    private val _hosting = MutableStateFlow(false)
    val hosting: StateFlow<Boolean> = _hosting
    private val _viewers = MutableStateFlow(0)
    val viewers: StateFlow<Int> = _viewers
    private val _viewState = MutableStateFlow("idle")
    val viewState: StateFlow<String> = _viewState
    private val _frame = MutableStateFlow<String?>(null)
    val frame: StateFlow<String?> = _frame
    var viewFrom: String = ""

    fun startHost(@Suppress("UNUSED_PARAMETER") ctx: Context, @Suppress("UNUSED_PARAMETER") company: String = ""): Boolean = false
    fun update(@Suppress("UNUSED_PARAMETER") json: String) {}
    fun stopHost() {}
    fun disconnect() { _viewState.value = "idle" }
}
