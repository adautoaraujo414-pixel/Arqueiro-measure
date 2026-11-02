package br.com.arque.measure.desktop

import java.io.File
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.nio.channels.FileChannel
import java.nio.channels.FileLock
import java.nio.file.StandardOpenOption

/**
 * Um Arquemestre aberto por vez (os dados são os mesmos arquivos).
 * Abrir de novo (ou clicar num link do plano de corte) traz a janela que já está aberta.
 */
object SingleInstance {
    private var lock: FileLock? = null
    private var channel: FileChannel? = null
    private var server: ServerSocket? = null
    @Volatile var onLink: ((String) -> Unit)? = null

    private val dir get() = Paths.data
    private val lockFile get() = File(dir, "app.lock")
    private val portFile get() = File(dir, "app.port")

    /** true = este é o único; false = já havia outro aberto (o pedido foi entregue a ele). */
    fun claim(link: String?): Boolean {
        if (System.getProperty("arque.multi") != null) return true
        return try {
            val ch = FileChannel.open(lockFile.toPath(), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
            val l = ch.tryLock()
            if (l == null) {
                ch.close()
                notifyRunning(link)
                false
            } else {
                channel = ch; lock = l
                listen()
                true
            }
        } catch (_: Exception) {
            true
        }
    }

    private fun notifyRunning(link: String?) {
        runCatching {
            val port = portFile.readText().trim().toInt()
            Socket(InetAddress.getLoopbackAddress(), port).use { s ->
                s.getOutputStream().write(((link ?: "") + "\n").toByteArray(Charsets.UTF_8))
            }
        }
    }

    private fun listen() {
        runCatching {
            val s = ServerSocket(0, 5, InetAddress.getLoopbackAddress())
            server = s
            portFile.writeText(s.localPort.toString())
            Thread({
                while (!s.isClosed) {
                    val c = runCatching { s.accept() }.getOrNull() ?: break
                    runCatching {
                        c.use { cc ->
                            val line = cc.getInputStream().bufferedReader(Charsets.UTF_8).readLine()?.trim().orEmpty()
                            if (line.isNotEmpty()) onLink?.invoke(line) else DesktopApp.bringToFront?.invoke()
                        }
                    }
                }
            }, "arque-instance").apply { isDaemon = true }.start()
        }
    }

    fun release() {
        runCatching { server?.close() }
        runCatching { lock?.release() }
        runCatching { channel?.close() }
        runCatching { portFile.delete() }
    }
}
