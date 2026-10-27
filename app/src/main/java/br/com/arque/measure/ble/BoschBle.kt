package br.com.arque.measure.ble

import br.com.arque.measure.i18n.tr

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
import android.bluetooth.BluetoothStatusCodes
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Intent
import android.content.IntentFilter
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
                setState(BleState.UNAVAILABLE, tr("Este aparelho não tem Bluetooth LE"))
                return false
            }
            !hasPermissions() -> {
                setState(BleState.NO_PERMISSION, tr("Permissão de Bluetooth necessária"))
                return false
            }
            !a.isEnabled -> {
                setState(BleState.OFF, tr("Bluetooth desligado"))
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

    private var scanAll = false

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val rawName = result.scanRecord?.deviceName ?: result.device.name
            val uuids = result.scanRecord?.serviceUuids.orEmpty().map { it.uuid.toString() }
            val hasService = uuids.any { BoschProtocol.isBoschService(it) }
            val nameMatch = rawName != null && BoschProtocol.NAME_REGEX.containsMatchIn(rawName)
            if (!scanAll && !hasService && !nameMatch) return
            val name = rawName ?: tr("Bosch ({0})", result.device.address.takeLast(5))
            val d = FoundDevice(name, result.device.address, result.rssi)
            _found.value = (_found.value.filter { it.address != d.address } + d).sortedByDescending { it.rssi }
        }

        override fun onScanFailed(errorCode: Int) {
            scanning = false
            setState(BleState.ERROR, tr("Falha na busca (código {0})", errorCode))
        }
    }

    fun startScan(all: Boolean = false) {
        if (!checkAvailability()) return
        scanAll = all
        val scanner = adapter?.bluetoothLeScanner ?: run {
            setState(BleState.ERROR, tr("Scanner Bluetooth indisponível"))
            return
        }
        if (scanning) return
        _found.value = emptyList()
        scanning = true
        setState(BleState.SCANNING, if (all) tr("Procurando todos os dispositivos BLE…") else tr("Procurando trena Bosch…"))
        scanner.startScan(null, ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build(), scanCallback)
        main.postDelayed({ stopScan() }, SCAN_TIMEOUT_MS)
    }

    fun stopScan() {
        if (!scanning) return
        scanning = false
        runCatching { adapter?.bluetoothLeScanner?.stopScan(scanCallback) }
        if (_state.value == BleState.SCANNING) {
            setState(BleState.IDLE, if (_found.value.isEmpty()) tr("Nenhuma trena encontrada") else "")
        }
    }

    // ---- conexão ----

    private var pendingAddress: String? = null
    private val ops = ArrayDeque<(BluetoothGatt) -> Boolean>()
    private var notifyEnabled = 0
    private var bondRequested = false

    private fun addLog(line: String) {
        main.post { _log.value = (listOf(line) + _log.value).take(LOG_SIZE) }
    }

    private val bondReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context, i: Intent) {
            val dev = if (Build.VERSION.SDK_INT >= 33) {
                i.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
            } else {
                @Suppress("DEPRECATION") i.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
            } ?: return
            if (dev.address != pendingAddress) return
            val st = i.getIntExtra(BluetoothDevice.EXTRA_BOND_STATE, BluetoothDevice.ERROR)
            if (st == BluetoothDevice.BOND_BONDED) {
                addLog(tr("Pareamento concluído; reconectando"))
                pendingAddress?.let { main.postDelayed({ connect(it, _deviceName.value) }, 800) }
            } else if (st == BluetoothDevice.BOND_NONE && bondRequested) {
                bondRequested = false
                setState(BleState.ERROR, tr("Pareamento recusado ou cancelado"))
            }
        }
    }
    private var receiverRegistered = false

    private fun registerBondReceiver() {
        if (receiverRegistered) return
        ContextCompat.registerReceiver(
            context, bondReceiver, IntentFilter(BluetoothDevice.ACTION_BOND_STATE_CHANGED), ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        receiverRegistered = true
    }

    fun connect(address: String, name: String? = null) {
        if (!checkAvailability()) return
        stopScan()
        val device: BluetoothDevice = runCatching { adapter!!.getRemoteDevice(address) }.getOrElse {
            setState(BleState.ERROR, tr("Endereço inválido"))
            return
        }
        registerBondReceiver()
        userDisconnected = false
        pendingAddress = address
        closeGatt()
        _deviceName.value = name ?: device.name
        prefs.edit().putString("last_address", address).putString("last_name", _deviceName.value).apply()
        setState(BleState.CONNECTING, tr("Conectando…"))
        addLog(tr("Conectando a {0}", address))
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
        ops.clear()
        closeGatt()
        _deviceName.value = null
        setState(BleState.IDLE, "")
    }

    private fun closeGatt() {
        runCatching { gatt?.disconnect() }
        runCatching { gatt?.close() }
        gatt = null
    }

    private fun propsText(p: Int): String = buildList {
        if (p and BluetoothGattCharacteristic.PROPERTY_READ != 0) add("ler")
        if (p and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) add("escrever")
        if (p and BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE != 0) add("escrever-sem-resp")
        if (p and BluetoothGattCharacteristic.PROPERTY_NOTIFY != 0) add("notificar")
        if (p and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0) add("indicar")
    }.joinToString(",")

    /** Executa a próxima operação da fila (ligar indicações, enviar comando) ou conclui a conexão. */
    private fun nextOp(g: BluetoothGatt) {
        while (ops.isNotEmpty()) {
            val op = ops.removeFirst()
            if (op(g)) return // operação iniciada: o callback chama nextOp de novo
        }
        if (notifyEnabled > 0) {
            setState(BleState.CONNECTED, tr("Conectada. Meça com a trena."))
        } else {
            setState(BleState.ERROR, tr("Conectou, mas não foi possível ativar o recebimento de medidas"))
        }
    }

    private fun needsBond(status: Int) = status == 5 || status == 15 || status == 137

    private fun requestBond(g: BluetoothGatt) {
        if (bondRequested) return
        bondRequested = true
        addLog(tr("A trena pediu pareamento; confirme na tela do celular"))
        setState(BleState.CONNECTING, tr("Pareando… confirme no celular e, se pedir, na trena"))
        g.device.createBond()
    }

    private val callback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(g: BluetoothGatt, status: Int, newState: Int) {
            main.post {
                if (newState == BluetoothProfile.STATE_CONNECTED && status == BluetoothGatt.GATT_SUCCESS) {
                    reconnectAttempts = 0
                    setState(BleState.CONNECTING, tr("Descobrindo serviços…"))
                    addLog(tr("Conectado ao GATT; descobrindo serviços"))
                    main.postDelayed({ if (gatt === g) g.discoverServices() }, 600)
                } else {
                    addLog(tr("Desconectado (status {0})", status))
                    runCatching { g.close() }
                    if (gatt === g) gatt = null
                    val addr = pendingAddress
                    if (!userDisconnected && reconnectAttempts < MAX_RECONNECTS && addr != null && !bondRequested) {
                        reconnectAttempts++
                        setState(BleState.CONNECTING, tr("Tentando de novo ({0}/{1})… status {2}", reconnectAttempts, MAX_RECONNECTS, status))
                        main.postDelayed({ if (!userDisconnected) connect(addr, _deviceName.value) }, RECONNECT_DELAY_MS)
                    } else if (!userDisconnected && !bondRequested) {
                        setState(BleState.ERROR, tr("Não conectou (status {0}). Ligue a trena, ative o Bluetooth nela e chegue perto.", status))
                    }
                }
            }
        }

        override fun onServicesDiscovered(g: BluetoothGatt, status: Int) {
            main.post {
                if (status != BluetoothGatt.GATT_SUCCESS) {
                    setState(BleState.ERROR, tr("Falha ao ler serviços (status {0})", status))
                    return@post
                }
                // diagnóstico: tudo que o aparelho expõe
                val cands = mutableListOf<BluetoothGattCharacteristic>()
                g.services.forEach { svc ->
                    val sid = svc.uuid.toString()
                    addLog("SERVIÇO $sid")
                    svc.characteristics.forEach { ch ->
                        addLog("  char ${ch.uuid} [${propsText(ch.properties)}]")
                        if (BoschProtocol.isBoschService(sid) || BoschProtocol.isBoschCharacteristic(ch.uuid.toString())) cands += ch
                    }
                }
                if (cands.isEmpty()) {
                    setState(BleState.ERROR, tr("Serviço Bosch não encontrado neste aparelho (veja o diagnóstico)"))
                    return@post
                }
                prefs.edit().putString("last_address", g.device.address).putString("last_name", _deviceName.value ?: g.device.name).apply()
                notifyEnabled = 0
                ops.clear()
                val notifiers = cands.filter {
                    it.properties and (BluetoothGattCharacteristic.PROPERTY_INDICATE or BluetoothGattCharacteristic.PROPERTY_NOTIFY) != 0
                }
                val writers = cands.filter {
                    it.properties and (BluetoothGattCharacteristic.PROPERTY_WRITE or BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) != 0
                }
                notifiers.forEach { ch -> ops += { gg -> enableIndications(gg, ch) } }
                writers.forEach { ch -> ops += { gg -> writeCommand(gg, ch, BoschProtocol.ENABLE_AUTOSYNC) } }
                nextOp(g)
            }
        }

        override fun onDescriptorWrite(g: BluetoothGatt, d: BluetoothGattDescriptor, status: Int) {
            main.post {
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    notifyEnabled++
                    addLog(tr("Recebimento ligado em {0}", d.characteristic.uuid))
                } else {
                    addLog(tr("Falha ao ligar recebimento em {0} (status {1})", d.characteristic.uuid, status))
                    if (needsBond(status) && g.device.bondState == BluetoothDevice.BOND_NONE) {
                        ops.clear()
                        requestBond(g)
                        return@post
                    }
                }
                nextOp(g)
            }
        }

        override fun onCharacteristicWrite(g: BluetoothGatt, c: BluetoothGattCharacteristic, status: Int) {
            main.post {
                addLog(if (status == BluetoothGatt.GATT_SUCCESS) tr("Comando enviado em {0}", c.uuid) else tr("Falha ao enviar comando em {0} (status {1})", c.uuid, status))
                if (status != BluetoothGatt.GATT_SUCCESS && needsBond(status) && g.device.bondState == BluetoothDevice.BOND_NONE) {
                    ops.clear()
                    requestBond(g)
                    return@post
                }
                nextOp(g)
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

    /** Liga indicação/notificação. Retorna true se a escrita foi iniciada (o callback continua a fila). */
    private fun enableIndications(g: BluetoothGatt, ch: BluetoothGattCharacteristic): Boolean {
        g.setCharacteristicNotification(ch, true)
        val cccd = ch.getDescriptor(UUID.fromString(BoschProtocol.CCCD_UUID)) ?: return false
        val useIndicate = ch.properties and BluetoothGattCharacteristic.PROPERTY_INDICATE != 0
        val value = if (useIndicate) BluetoothGattDescriptor.ENABLE_INDICATION_VALUE
        else BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
        return if (Build.VERSION.SDK_INT >= 33) {
            g.writeDescriptor(cccd, value) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            run {
                cccd.value = value
                g.writeDescriptor(cccd)
            }
        }
    }

    private fun writeCommand(g: BluetoothGatt, ch: BluetoothGattCharacteristic, cmd: ByteArray): Boolean {
        val type = if (ch.properties and BluetoothGattCharacteristic.PROPERTY_WRITE != 0) {
            BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        } else {
            BluetoothGattCharacteristic.WRITE_TYPE_NO_RESPONSE
        }
        return if (Build.VERSION.SDK_INT >= 33) {
            g.writeCharacteristic(ch, cmd, type) == BluetoothStatusCodes.SUCCESS
        } else {
            @Suppress("DEPRECATION")
            run {
                ch.writeType = type
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
        private const val LOG_SIZE = 60
    }
}
