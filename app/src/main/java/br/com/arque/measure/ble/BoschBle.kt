package br.com.arque.measure.ble

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothGattDescriptor
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import androidx.core.content.ContextCompat
import br.com.arque.measure.model.MeasureSource
import br.com.arque.measure.model.Reading
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

enum class BleState { UNAVAILABLE, OFF, NO_PERMISSION, IDLE, SCANNING, CONNECTING, CONNECTED, ERROR }

data class FoundDevice(val name: String, val address: String, val rssi: Int)

/**
 * Conexão BLE real com trenas Bosch. Não gera leituras de mentira: toda [Reading] emitida vem
 * de um quadro recebido da trena. Veja [BoschProtocol] sobre o que ainda não foi validado.
 */
@SuppressLint("MissingPermission")
class BoschBle(private val context: Context) {
    private val main = Handler(Looper.getMainLooper())
    private val prefs = context.getSharedPreferences("ble", Context.MODE_PRIVATE)
    private val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
    private val adapter: BluetoothAdapter? get() = manager?.adapter

    private val _state = MutableStateFlow(BleState.IDLE)
    val state: StateFlow<BleState> = _state.asStateFlow()

    private val _message = MutableStateFlow("")
    val message: StateFlow<String> = _message.asStateFlow()

    private val _deviceName = MutableStateFlow<String?>(null)
    val deviceName: StateFlow<String?> = _deviceName.asStateFlow()

    private val _found = MutableStateFlow<List<FoundDevice>>(emptyList())
    val found: StateFlow<List<FoundDevice>> = _found.asStateFlow()

    /** Últimos quadros brutos (hex) para diagnóstico. */
    private val _log = MutableStateFlow<List<String>>(emptyList())
    val log: StateFlow<List<String>> = _log.asStateFlow()

    private val _readings = MutableSharedFlow<Reading>(extraBufferCapacity = 32)
    val readings: SharedFlow<Reading> = _readings.asSharedFlow()

    private var gatt: BluetoothGatt? = null
    private var userDisconnected = false
    private var reconnectAttempts = 0
    private var scanning = false

    val lastAddress: String? get() = prefs.getString("last_address", null)

    fun requiredPermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= 31) {
            arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    fun hasPermissions(): Boolean = requiredPermissions().all {
        ContextCompat.checkSelfPermission(context, it) == PackageManager.PERMISSION_GRANTED
    }

    /** Atualiza o estado se o Bluetooth está indisponível, desligado ou sem permissão. */
    fun checkAvailability(): Boolean {
        val a = adapter
        when {
            a == null || !context.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) -> {
                setState(BleState.UNAVAILABLE, "Este aparelho não tem Bluetooth LE")
                return false
            }
            !hasPermissions() -> {
                setState(BleState.NO_PERMISSION, "Permissão de Bluetooth necessária")
                return false
            }
            !a.isEnabled -> {
                setState(BleState.OFF, "Bluetooth desligado")
                return false
            }
        }
        if (_state.value in listOf(BleState.UNAVAILABLE, BleState.OFF, BleState.NO_PERMISSION)) {
            setState(BleState.IDLE, "")
        }
        return true
    }

    private fun setState(s: BleState, msg: String = _message.value) {
        _state.value = s
        _message.value = msg
    }

    // ---- varredura ----

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val name = result.scanRecord?.deviceName ?: result.device.name ?: return
            val hasService = result.scanRecord?.serviceUuids?.contains(ParcelUuid.fromString(BoschProtocol.SERVICE_UUID)) == true
            if (!hasService && !BoschProtocol.NAME_REGEX.containsMatchIn(name)) return
            val d = FoundDevice(name, result.device.address, result.rssi)
            _found.value = (_found.value.filter { it.address != d.address } + d).sortedByDescending { it.rssi }
        }

        override fun onScanFailed(errorCode: Int) {
            scanning = false
            setState(BleState.ERROR, "Falha na busca (código $errorCode)")
        }
    }

    fun startScan() {
        if (!checkAvailability()) return
        val scanner = adapter?.bluetoothLeScanner ?: run {
            setState(BleState.ERROR, "Scanner Bluetooth indisponível")
            return
        }
        if (scanning) return
        _found.value = emptyList()
        scanning = true
        setState(BleState.SCANNING, "Procurando trena Bosch…")
        scanner.startScan(null, ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), scanCallback)
        main.postDelayed({ stopScan() }, SCAN_TIMEOUT_MS)
    }

    fun stopScan() {
        if (!scanning) return
        scanning = false
        runCatching { adapter?.bluetoothLeScanner?.stopScan(scanCallback) }
        if (_state.value == BleState.SCANNING) {
            setState(BleState.IDLE, if (_found.value.isEmpty()) "Nenhuma trena encontrada" else "")
        }
    }

    // ---- conexão ----

    fun connect(address: String, name: String? = null) {
        if (!checkAvailability()) return
        stopScan()
        val device: BluetoothDevice = runCatching { adapter!!.getRemoteDevice(address) }.getOrElse {
            setState(BleState.ERROR, "Endereço inválido")
            return
        }
        userDisconnected = false
        closeGatt()
        _deviceName.value = name ?: device.name
        setState(BleState.CONNECTING, "Conectando…")
        gatt = if (Build.VERSION.SDK_INT >= 23) {
            device.connectGatt(context, false, callback, BluetoothDevice.TRANSPORT_LE)
        } else {
            device.connectGatt(context, false, callback)
        }
    }

    fun reconnectLast() {
        lastAddress?.let { connect(it, prefs.getString("last_name", null)) }
    }

    fun disconnect() {
        userDisconnected = true
        main.removeCallbacksAndMessages(null)
        closeGatt()
        _deviceName.value = null
        setState(BleState.IDLE, "")
    }

    private fun closeGatt() {
        runCatching { gatt?.disconnect() }
        runCatching { gatt?.close() }
        gatt = null
    }

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            main.post {
                if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                    reconnectAttempts = 0
                    setState(BleState.CONNECTING, "Descobrindo serviços…")
                    g.discoverServices()
                } else {
                    runCatching { g.close() }
                    if (gatt === g) gatt = null
                    if (!userDisconnected && reconnectAttempts < MAX_RECONNECTS && lastAddress != null) {
                        reconnectAttempts++
                        setState(BleState.CONNECTING, "Reconectando ($reconnectAttempts/$MAX_RECONNECTS)…")
                        main.postDelayed({ if (!userDisconnected) reconnectLast() }, RECONNECT_DELAY_MS)
                    } else if (!userDisconnected) {
                        setState(BleState.ERROR, "Conexão perdida")
                    }
                }
            }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            main.post {
                val ch = g.getService(UUID.fromString(BoschProtocol.SERVICE_UUID))
                    ?.getCharacteristic(UUID.fromString(BoschProtocol.CHARACTERISTIC_UUID))
                if (status != BluetoothGatt.GATT_SUCCESS || ch == null) {
                    setState(BleState.ERROR, "Serviço Bosch não encontrado neste dispositivo")
                    return@post
                }
                prefs.edit()
                    .putString("last_address", g.device.address)
                    .putString("last_name", _deviceName.value ?: g.device.name)
                    .apply()
                enableIndications(g, ch)
            }
        }

        override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
            main.post {
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    setState(BleState.ERROR, "Não foi possível ativar notificações (status $status)")
                    return@post
                }
                val ch = d.characteristic
                writeCommand(g, ch, BoschProtocol.ENABLE_AUTOSYNC)
            }
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            main.post {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    setState(BleState.CONNECTED, "Conectada. Meça com a trena.")
                } else {
                    setState(BleState.ERROR, "Falha ao ativar envio automático (status $status)")
                }
            }
        }

        // Android 13+
        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic, value: ByteArray) {
            handleFrame(value, g.device.name)
        }

        @Deprecated("Usado em Android 12 e anteriores")
        @Suppress("DEPRECATION")
        override fun onCharacteristicChanged(g: BluetoothGatt, c: BluetoothGattCharacteristic) {
            if (Build.VERSION.SDK_INT < 33) handleFrame(c.value ?: return, g.device.name)
        }
    }

    private fun enableIndications(g: BluetoothGatt, ch: BluetoothGattCharacteristic) {
        g.setCharacteristicNotification(ch, true)
        val cccd = ch.getDescriptor(UUID.fromString(BoschProtocol.CCCD_UUID))
        if (cccd == null) {
            setState(BleState.ERROR, "Descritor de notificação ausente")
            return
        }
        val useIndicate = ch.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0
        val value = if (useIndicate) BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
        else BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        if (Build.VERSION.SDK_INT >= 33) {
            g.writeDescriptor(cccd, value)
        } else {
            @Suppress("DEPRECATION")
            run {
                cccd.value = value
                g.writeDescriptor(cccd)
            }
        }
    }

    private fun writeCommand(g: BluetoothGatt, ch: BluetoothGattCharacteristic, cmd: ByteArray) {
        if (Build.VERSION.SDK_INT >= 33) {
            g.writeCharacteristic(ch, cmd, BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT)
        } else {
            @Suppress("DEPRECATION")
            run {
                ch.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
                ch.value = cmd
                g.writeCharacteristic(ch)
            }
        }
    }

    private fun handleFrame(bytes: ByteArray, deviceName: String?) {
        val hex = BoschProtocol.toHex(bytes)
        val mm = BoschProtocol.parseMm(bytes)
        main.post {
            _log.value = (listOf(hex + if (mm != null) "  → ${mm.toLong()} mm" else "  (sem medida)") + _log.value).take(LOG_SIZE)
        }
        if (mm != null) {
            _readings.tryEmit(
                Reading(
                    mm = mm,
                    source = MeasureSource.BLUETOOTH,
                    timeMs = System.currentTimeMillis(),
                    device = deviceName ?: _deviceName.value,
                    rawHex = hex,
                ),
            )
        }
    }

    companion object {
        private const val SCAN_TIMEOUT_MS = 20_000L
        private const val MAX_RECONNECTS = 5
        private const val RECONNECT_DELAY_MS = 3_000L
        private const val LOG_SIZE = 20
    }
}
