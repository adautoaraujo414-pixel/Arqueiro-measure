package br.com.arque.measure.share

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.DataInputStream
import java.io.DataOutputStream
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.zip.GZIPInputStream
import java.util.zip.GZIPOutputStream

/**
 * Compartilhar projeto de móveis por Bluetooth, celular com celular, em tempo real.
 * Quem compartilha (dono) manda o projeto inteiro a cada alteração; quem vê só recebe (não altera nada).
 * Quadro: [tamanho Int][JSON compactado em gzip].
 */
@SuppressLint("MissingPermission")
object BtShare {
    private val ID: UUID = UUID.fromString("6c1f2a8e-4b7d-4f3e-9a51-2d8c0b3e7a19")
    private const val MAX = 30 * 1024 * 1024

    private val _hosting = MutableStateFlow(false)
    val hosting: StateFlow<Boolean> = _hosting
    private val _viewers = MutableStateFlow(0)
    val viewers: StateFlow<Int> = _viewers

    private val _viewState = MutableStateFlow("idle") // idle, connecting, connected, closed, error
    val viewState: StateFlow<String> = _viewState
    private val _frame = MutableStateFlow<String?>(null)
    val frame: StateFlow<String?> = _frame
    var viewFrom: String = ""

    private var server: BluetoothServerSocket? = null
    private val outs = CopyOnWriteArrayList<Pair<BluetoothSocket, DataOutputStream>>()
    private val sendQ = Executors.newSingleThreadExecutor()
    @Volatile private var last: ByteArray? = null
    private var viewSock: BluetoothSocket? = null

    fun adapter(ctx: Context): BluetoothAdapter? =
        (ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    private fun pack(json: String): ByteArray {
        val bo = java.io.ByteArrayOutputStream()
        GZIPOutputStream(bo).use { it.write(json.toByteArray(Charsets.UTF_8)) }
        return bo.toByteArray()
    }

    // ---------------- dono do projeto ----------------
    fun startHost(ctx: Context): Boolean {
        if (_hosting.value) return true
        val ad = adapter(ctx) ?: return false
        if (!ad.isEnabled) return false
        val s = runCatching { ad.listenUsingInsecureRfcommWithServiceRecord("Arquemestre projeto", ID) }.getOrNull() ?: return false
        server = s
        _hosting.value = true
        Thread {
            while (_hosting.value) {
                val sock = runCatching { s.accept() }.getOrNull() ?: break
                val out = DataOutputStream(sock.outputStream.buffered())
                outs.add(sock to out)
                _viewers.value = outs.size
                last?.let { b -> sendQ.execute { write(sock, out, b) } }
            }
        }.apply { isDaemon = true }.start()
        return true
    }

    private fun write(sock: BluetoothSocket, out: DataOutputStream, b: ByteArray) {
        try {
            out.writeInt(b.size); out.write(b); out.flush()
        } catch (_: Exception) {
            runCatching { sock.close() }
            outs.removeAll { it.first === sock }
            _viewers.value = outs.size
        }
    }

    /** Projeto mudou: manda pra todo mundo que está vendo. */
    fun update(json: String) {
        if (!_hosting.value) return
        sendQ.execute {
            val b = pack(json)
            last = b
            outs.forEach { (s, o) -> write(s, o, b) }
        }
    }

    fun stopHost() {
        _hosting.value = false
        runCatching { server?.close() }
        server = null
        outs.forEach { runCatching { it.first.close() } }
        outs.clear()
        _viewers.value = 0
        last = null
    }

    // ---------------- quem vê ----------------
    fun connect(ctx: Context, dev: BluetoothDevice) {
        disconnect()
        _viewState.value = "connecting"
        _frame.value = null
        viewFrom = runCatching { dev.name }.getOrNull() ?: dev.address
        Thread {
            try {
                adapter(ctx)?.cancelDiscovery()
                val s = dev.createInsecureRfcommSocketToServiceRecord(ID)
                viewSock = s
                s.connect()
                _viewState.value = "connected"
                val inp = DataInputStream(s.inputStream.buffered())
                while (true) {
                    val n = inp.readInt()
                    if (n <= 0 || n > MAX) error("quadro inválido")
                    val b = ByteArray(n)
                    inp.readFully(b)
                    _frame.value = GZIPInputStream(b.inputStream()).use { it.readBytes().toString(Charsets.UTF_8) }
                }
            } catch (_: Exception) {
                _viewState.value = if (_viewState.value == "connecting") "error" else "closed"
                runCatching { viewSock?.close() }
            }
        }.apply { isDaemon = true }.start()
    }

    fun disconnect() {
        runCatching { viewSock?.close() }
        viewSock = null
        if (_viewState.value != "idle") _viewState.value = "idle"
    }
}
