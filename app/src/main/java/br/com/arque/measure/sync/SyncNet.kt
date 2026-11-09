package br.com.arque.measure.sync

import org.json.JSONObject
import java.io.BufferedInputStream
import java.io.File
import java.io.InputStream
import java.io.OutputStream
import java.net.HttpURLConnection
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.ServerSocket
import java.net.Socket
import java.net.URL

/**
 * Conversa entre os aparelhos pelo Wi-Fi (rede da casa ou o roteador do celular), sem internet e sem servidor.
 * Quem "Recebe" abre uma porta e mostra um código "final do IP-senha" (ex.: 10-4821); quem "Conecta" digita
 * o código, vê a lista (igual · só aqui · só lá · diferente) e escolhe o que passa nos dois sentidos.
 * Protocolo (HTTP simples, igual pro Android, Windows e iPhone), sempre com a senha de 4 números:
 *   GET  /arq/hello     → {app:"arquemestre", v, name}
 *   GET  /arq/manifest  → {items:[{k,id,t,s,h,m}]}
 *   POST /arq/get  {k,id}  → pacote do item
 *   POST /arq/put  pacote  → {ok}
 *   POST /arq/done         → {ok} (quem recebeu relê os dados)
 */
object SyncNet {
    const val PORT = 47321
    private const val MAX_BODY = 60 * 1024 * 1024

    // ---------- endereço deste aparelho ----------

    /** IPs da rede local (Wi-Fi / roteador do celular), sem os de VPN e celular 4G quando dá pra saber. */
    fun localIps(): List<String> = System.getProperty("arque.syncIps")?.split(',')?.filter { it.isNotBlank() } ?: runCatching {
        NetworkInterface.getNetworkInterfaces().toList().filter { runCatching { it.isUp && !it.isLoopback }.getOrDefault(false) }
            .flatMap { ni -> ni.inetAddresses.toList().filterIsInstance<Inet4Address>().filter { it.isSiteLocalAddress }.map { ni.name to it.hostAddress } }
            .sortedBy { (n, ip) -> (if (n.startsWith("wlan") || n.startsWith("en") || n.startsWith("wl")) 0 else 1) * 10 + (if (ip.startsWith("192.168.")) 0 else 1) }
            .map { it.second }.distinct()
    }.getOrDefault(emptyList())

    /** Código que aparece na tela de quem recebe: "10-4821" (porta padrão) ou "10-4821-2" (porta + 2). */
    fun code(ip: String, pin: String, port: Int): String {
        val last = ip.substringAfterLast('.')
        return if (port == PORT) "$last-$pin" else "$last-$pin-${port - PORT}"
    }

    data class Target(val hosts: List<String>, val pin: String, val port: Int)

    /** Entende "10-4821", "10-4821-2" ou "192.168.0.10-4821". Os primeiros números do IP vêm da rede deste aparelho. */
    fun parse(code: String, mine: List<String> = localIps()): Target? {
        val p = code.trim().replace(" ", "").split('-').filter { it.isNotEmpty() }
        if (p.size < 2) return null
        val pin = p[1].filter { it.isDigit() }; if (pin.length != 4) return null
        val off = p.getOrNull(2)?.toIntOrNull() ?: 0
        if (off !in 0..9) return null
        val first = p[0]
        val hosts = if (first.count { it == '.' } == 3) listOf(first) else {
            val last = first.toIntOrNull() ?: return null
            if (last !in 1..254) return null
            mine.map { it.substringBeforeLast('.') + "." + last }.distinct()
        }
        if (hosts.isEmpty()) return null
        return Target(hosts, pin, PORT + off)
    }

    // ---------- quem recebe (servidor) ----------

    class Host(private val files: File, private val name: String, private val beforeWrite: () -> Unit, private val onEvent: (String) -> Unit) {
        val pin: String = (1000 + java.security.SecureRandom().nextInt(9000)).toString()
        var port: Int = PORT; private set
        @Volatile var received = 0; private set
        @Volatile var sent = 0; private set
        @Volatile private var running = false
        private var server: ServerSocket? = null
        private var wroteOnce = false

        fun start(): Boolean {
            for (pt in PORT..PORT + 9) {
                val s = runCatching { ServerSocket().apply { reuseAddress = true; bind(InetSocketAddress(pt)) } }.getOrNull() ?: continue
                server = s; port = pt; running = true
                Thread({ loop(s) }, "arq-sync").apply { isDaemon = true }.start()
                return true
            }
            return false
        }

        fun stop() { running = false; runCatching { server?.close() } }

        private fun loop(s: ServerSocket) {
            while (running) {
                val c = runCatching { s.accept() }.getOrNull() ?: break
                Thread({ runCatching { handle(c) }; runCatching { c.close() } }, "arq-sync-c").apply { isDaemon = true }.start()
            }
        }

        private fun handle(c: Socket) {
            c.soTimeout = 30_000
            val inp = BufferedInputStream(c.getInputStream())
            val line = readLine(inp) ?: return
            val parts = line.split(' ')
            if (parts.size < 2) return
            val method = parts[0]; val target = parts[1]
            var len = 0
            while (true) {
                val h = readLine(inp) ?: return
                if (h.isEmpty()) break
                val i = h.indexOf(':')
                if (i > 0 && h.substring(0, i).trim().equals("Content-Length", true)) len = h.substring(i + 1).trim().toIntOrNull() ?: 0
            }
            if (len < 0 || len > MAX_BODY) return reply(c.getOutputStream(), 413, JSONObject().put("err", "grande"))
            val body = if (len > 0) readN(inp, len) else ByteArray(0)
            val path = target.substringBefore('?')
            val q = target.substringAfter('?', "").split('&').mapNotNull { kv -> kv.split('=').takeIf { it.size == 2 }?.let { it[0] to it[1] } }.toMap()
            val out = c.getOutputStream()
            if (q["pin"] != pin) return reply(out, 403, JSONObject().put("err", "senha"))
            val res: JSONObject = synchronized(this) {
                when {
                    method == "GET" && path == "/arq/hello" -> JSONObject().put("app", "arquemestre").put("v", SyncCore.VERSION).put("name", name)
                    method == "GET" && path == "/arq/manifest" -> {
                        onEvent("conectou")
                        JSONObject().put("items", org.json.JSONArray(SyncCore.manifest(files).map { it.toJson() }))
                    }
                    method == "POST" && path == "/arq/get" -> {
                        val j = JSONObject(String(body, Charsets.UTF_8))
                        val p = SyncCore.export(files, j.optString("k"), j.optString("id")) ?: return reply(out, 404, JSONObject().put("err", "não achei"))
                        sent++; onEvent("enviou"); p
                    }
                    method == "POST" && path == "/arq/put" -> {
                        val p = JSONObject(String(body, Charsets.UTF_8))
                        if (!wroteOnce) { wroteOnce = true; runCatching { beforeWrite() } }
                        if (!SyncCore.apply(files, p)) return reply(out, 400, JSONObject().put("err", "pacote"))
                        received++; onEvent("recebeu"); JSONObject().put("ok", true)
                    }
                    method == "POST" && path == "/arq/done" -> { onEvent("fim"); JSONObject().put("ok", true) }
                    else -> return reply(out, 404, JSONObject().put("err", "?"))
                }
            }
            reply(out, 200, res)
        }

        private fun reply(out: OutputStream, code: Int, j: JSONObject) {
            val b = j.toString().toByteArray(Charsets.UTF_8)
            val st = when (code) { 200 -> "OK"; 403 -> "Forbidden"; 404 -> "Not Found"; 413 -> "Too Large"; else -> "Bad Request" }
            out.write("HTTP/1.1 $code $st\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: ${b.size}\r\nConnection: close\r\n\r\n".toByteArray(Charsets.ISO_8859_1))
            out.write(b); out.flush()
        }

        private fun readLine(i: InputStream): String? {
            val sb = StringBuilder()
            while (true) {
                val b = i.read(); if (b < 0) return if (sb.isEmpty()) null else sb.toString()
                if (b == '\n'.code) return sb.toString().trimEnd('\r')
                sb.append(b.toChar()); if (sb.length > 8192) return null
            }
        }

        private fun readN(i: InputStream, n: Int): ByteArray {
            val b = ByteArray(n); var o = 0
            while (o < n) { val r = i.read(b, o, n - o); if (r < 0) break; o += r }
            return if (o == n) b else b.copyOf(o)
        }
    }

    // ---------- quem conecta (cliente) ----------

    class Client(val base: String, private val pin: String) {
        private fun call(method: String, path: String, body: JSONObject?, timeout: Int = 20_000): JSONObject {
            val c = URL("$base$path?pin=$pin").openConnection() as HttpURLConnection
            c.requestMethod = method; c.connectTimeout = timeout; c.readTimeout = 60_000; c.useCaches = false
            if (body != null) {
                val b = body.toString().toByteArray(Charsets.UTF_8)
                c.doOutput = true; c.setRequestProperty("Content-Type", "application/json; charset=utf-8"); c.setFixedLengthStreamingMode(b.size)
                c.outputStream.use { it.write(b) }
            }
            val code = c.responseCode
            val txt = (if (code in 200..299) c.inputStream else c.errorStream)?.use { String(it.readBytes(), Charsets.UTF_8) }.orEmpty()
            c.disconnect()
            if (code == 403) throw IllegalStateException("Senha errada: confira o código na tela do outro aparelho.")
            if (code !in 200..299) throw IllegalStateException("O outro aparelho respondeu $code")
            return JSONObject(txt)
        }

        fun hello(timeout: Int = 2500): JSONObject = call("GET", "/arq/hello", null, timeout)
        fun manifest(): List<SyncCore.Item> { val a = call("GET", "/arq/manifest", null).optJSONArray("items") ?: org.json.JSONArray(); return (0 until a.length()).map { SyncCore.Item.from(a.getJSONObject(it)) } }
        fun get(k: String, id: String): JSONObject = call("POST", "/arq/get", JSONObject().put("k", k).put("id", id))
        fun put(p: JSONObject) { call("POST", "/arq/put", p) }
        fun done() { runCatching { call("POST", "/arq/done", JSONObject()) } }

        companion object {
            /** Procura o aparelho do código na rede (testa cada rede deste aparelho). */
            fun find(t: Target): Pair<Client, String>? {
                for (h in t.hosts) {
                    val c = Client("http://$h:${t.port}", t.pin)
                    val r = runCatching { c.hello() }
                    r.exceptionOrNull()?.let { if (it.message?.startsWith("Senha") == true) throw it }
                    val j = r.getOrNull() ?: continue
                    if (j.optString("app") == "arquemestre") return c to j.optString("name")
                }
                return null
            }
        }
    }

    /** Passa o que foi marcado: "send" vai deste pro outro, "pull" vem do outro pra este. */
    fun transfer(files: File, c: Client, send: List<SyncCore.Row>, pull: List<SyncCore.Row>, beforeWrite: () -> Unit, progress: (Int, Int) -> Unit): Pair<Int, Int> {
        val total = send.size + pull.size; var n = 0; var ok = 0; var fail = 0
        for (r in send) {
            val p = SyncCore.export(files, r.k, r.id)
            if (p != null && runCatching { c.put(p) }.isSuccess) ok++ else fail++
            progress(++n, total)
        }
        if (pull.isNotEmpty()) runCatching { beforeWrite() }
        for (r in pull) {
            val p = runCatching { c.get(r.k, r.id) }.getOrNull()
            if (p != null && SyncCore.apply(files, p)) ok++ else fail++
            progress(++n, total)
        }
        c.done()
        return ok to fail
    }
}
