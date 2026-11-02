package br.com.arque.measure.ble

import br.com.arque.measure.i18n.tr

import android.content.Context
import br.com.arque.measure.model.Reading
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow

enum class BleState { UNAVAILABLE, OFF, NO_PERMISSION, IDLE, SCANNING, CONNECTING, CONNECTED, ERROR }

data class FoundDevice(val name: String, val address: String, val rssi: Int)

/**
 * Trena Bosch no Windows: esta versão ainda NÃO conecta por Bluetooth (o Bluetooth LE do celular
 * não existe no Java do computador). As medidas entram digitando no número da cota.
 * A mesma interface do Android fica aqui pra todas as telas funcionarem igual.
 */
class BoschBle(@Suppress("UNUSED_PARAMETER") context: Context) {
    private val _state = MutableStateFlow(BleState.UNAVAILABLE)
    val state: StateFlow<BleState> = _state.asStateFlow()

    private val _message = MutableStateFlow(tr("No Windows a trena Bosch por Bluetooth ainda não conecta. Toque no número da cota e digite a medida (ou meça pelo celular e compartilhe o projeto)."))
    val message: StateFlow<String> = _message.asStateFlow()

    private val _deviceName = MutableStateFlow<String?>(null)
    val deviceName: StateFlow<String?> = _deviceName.asStateFlow()

    private val _found = MutableStateFlow<List<FoundDevice>>(emptyList())
    val found: StateFlow<List<FoundDevice>> = _found.asStateFlow()

    private val _log = MutableStateFlow<List<String>>(emptyList())
    val log: StateFlow<List<String>> = _log.asStateFlow()

    private val _readings = MutableSharedFlow<Reading>(extraBufferCapacity = 32)
    val readings: SharedFlow<Reading> = _readings.asSharedFlow()

    val lastAddress: String? get() = null

    fun requiredPermissions(): Array<String> = emptyArray()
    fun hasPermissions(): Boolean = true
    fun checkAvailability(): Boolean { _state.value = BleState.UNAVAILABLE; return false }
    fun startScan(@Suppress("UNUSED_PARAMETER") all: Boolean = false) { _state.value = BleState.UNAVAILABLE }
    fun stopScan() {}
    fun connect(@Suppress("UNUSED_PARAMETER") address: String, @Suppress("UNUSED_PARAMETER") name: String? = null) { _state.value = BleState.UNAVAILABLE }
    fun reconnectLast() {}
    fun disconnect() {}

    /** Usado pelos testes: entrega uma leitura como se viesse da trena. */
    fun simulate(r: Reading) { _readings.tryEmit(r) }
}
