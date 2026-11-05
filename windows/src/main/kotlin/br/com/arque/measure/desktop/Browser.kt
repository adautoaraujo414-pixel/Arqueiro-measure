package br.com.arque.measure.desktop

import me.friwi.jcefmaven.CefAppBuilder
import me.friwi.jcefmaven.EnumProgress
import me.friwi.jcefmaven.IProgressHandler
import me.friwi.jcefmaven.MavenCefAppHandlerAdapter
import org.cef.CefApp
import org.cef.CefClient
import org.cef.CefSettings
import org.cef.browser.CefBrowser
import org.cef.browser.CefFrame
import org.cef.callback.CefCallback
import org.cef.handler.CefDisplayHandlerAdapter
import org.cef.handler.CefLifeSpanHandlerAdapter
import org.cef.handler.CefLoadHandlerAdapter
import org.cef.handler.CefRequestHandlerAdapter
import org.cef.handler.CefResourceHandler
import org.cef.handler.CefResourceHandlerAdapter
import org.cef.handler.CefResourceRequestHandler
import org.cef.handler.CefResourceRequestHandlerAdapter
import org.cef.misc.BoolRef
import org.cef.misc.IntRef
import org.cef.misc.StringRef
import org.cef.network.CefPostDataElement
import org.cef.network.CefRequest
import org.cef.network.CefResponse
import java.io.File
import java.util.Vector

/**
 * Navegador embutido (Chromium/CEF) que roda o editor de móveis — o mesmo editor.html do celular.
 * O editor é servido em https://arque.app/ (endereço interno, nada vai pra internet) e fala com o app
 * pela mesma ponte "ArqueApp" do Android, por chamadas síncronas em https://arque.app/__bridge/.
 */
object Browser {
    const val ORIGIN = "https://arque.app"

    /** Andamento da primeira preparação (descompactar o navegador): 0..100, ou -1 quando pronto. */
    @Volatile var progress: Int = 0
    @Volatile var error: String? = null

    private var app: CefApp? = null
    private var client: CefClient? = null
    private var browser: CefBrowser? = null

    /** Quem responde às chamadas da ponte (definido pela tela do editor). */
    @Volatile var bridge: ((String, List<String>) -> String)? = null
    /** Página carregada (quadro principal). */
    @Volatile var onLoaded: (() -> Unit)? = null
    /** Mensagens do console (para os testes e diagnóstico). */
    val console = java.util.concurrent.ConcurrentLinkedQueue<String>()

    val ready: Boolean get() = browser != null
    @Volatile var loads = 0
    /** O editor terminou de carregar (scripts rodaram). */
    @Volatile var pageReady = false
    /** O navegador nativo só existe depois que a janela dele aparece: até lá o endereço fica guardado. */
    @Volatile private var created = false
    @Volatile private var pendingUrl: String? = null
    fun url(): String = runCatching { browser?.url ?: "" }.getOrDefault("")

    /** Prepara o CEF (lento só na primeira vez: descompacta o Chromium em %LOCALAPPDATA%\Arquemestre\jcef). */
    @Synchronized
    fun init(): CefBrowser {
        browser?.let { return it }
        try {
            val b = CefAppBuilder()
            // Windows 7/8 usa o Chromium 109 numa pasta própria (não mistura com o 135 de uma instalação antiga)
            b.setInstallDir(File(Paths.data, if (br.com.arque.measure.data.AppUpdater.win7Build) "jcef109" else "jcef"))
            b.setProgressHandler(IProgressHandler { st, pct ->
                progress = when (st) {
                    EnumProgress.LOCATING -> 2
                    EnumProgress.DOWNLOADING -> (5 + pct * 0.6f).toInt().coerceIn(5, 65)
                    EnumProgress.EXTRACTING -> 70
                    EnumProgress.INSTALL -> 85
                    EnumProgress.INITIALIZING -> 95
                    EnumProgress.INITIALIZED -> 100
                    else -> progress
                }
            })
            val s = b.cefSettings
            s.windowless_rendering_enabled = false
            val cache = File(Paths.data, "app_webview").apply { mkdirs() }.absolutePath
            runCatching { CefSettings::class.java.getField("root_cache_path").set(s, cache) }
            s.cache_path = cache
            s.persist_session_cookies = true
            s.locale = when (br.com.arque.measure.i18n.I18n.lang) { "en" -> "en-US"; "es" -> "es"; else -> "pt-BR" }
            s.log_severity = CefSettings.LogSeverity.LOGSEVERITY_WARNING
            s.log_file = File(Paths.data, "logs/cef.log").apply { parentFile.mkdirs() }.absolutePath
            System.getenv("ARQUE_CDP_PORT")?.toIntOrNull()?.let { s.remote_debugging_port = it }
            b.addJcefArgs("--disable-features=Translate", "--autoplay-policy=no-user-gesture-required")
            if (!System.getProperty("os.name").lowercase().contains("win")) b.addJcefArgs("--no-sandbox", "--disable-gpu")
            b.setAppHandler(object : MavenCefAppHandlerAdapter() {})
            val a = b.build()
            app = a
            val c = a.createClient()
            client = c
            c.addRequestHandler(object : CefRequestHandlerAdapter() {
                override fun onBeforeBrowse(browser: CefBrowser?, frame: CefFrame?, request: CefRequest?, userGesture: Boolean, isRedirect: Boolean): Boolean {
                    val u = request?.url ?: return false
                    if (u.startsWith("$ORIGIN/") || u.startsWith("devtools:") || u.startsWith("about:") || u.startsWith("blob:") || u.startsWith("data:")) return false
                    // tel:, WhatsApp, e-mail e sites de fora abrem nos programas do Windows
                    DesktopActions.browse(u)
                    return true
                }

                override fun getResourceRequestHandler(
                    browser: CefBrowser?, frame: CefFrame?, request: CefRequest?, isNavigation: Boolean, isDownload: Boolean,
                    requestInitiator: String?, disableDefaultHandling: BoolRef?,
                ): CefResourceRequestHandler? {
                    val u = request?.url ?: return null
                    return if (u.startsWith("$ORIGIN/")) Local else null
                }
            })
            c.addLifeSpanHandler(object : CefLifeSpanHandlerAdapter() {
                override fun onAfterCreated(browser: CefBrowser?) {
                    created = true
                    pendingUrl?.let { u -> pendingUrl = null; browser?.loadURL(u) }
                }

                override fun onBeforePopup(browser: CefBrowser?, frame: CefFrame?, targetUrl: String?, targetFrameName: String?): Boolean {
                    targetUrl?.let { if (!it.startsWith(ORIGIN)) DesktopActions.browse(it) }
                    return true
                }
            })
            c.addLoadHandler(object : CefLoadHandlerAdapter() {
                override fun onLoadEnd(browser: CefBrowser?, frame: CefFrame?, httpStatusCode: Int) {
                    if (frame?.isMain == true) { loads++; onLoaded?.invoke() }
                }
            })
            c.addDisplayHandler(object : CefDisplayHandlerAdapter() {
                override fun onConsoleMessage(browser: CefBrowser?, level: CefSettings.LogSeverity?, message: String?, source: String?, line: Int): Boolean {
                    console.add("[$level] $message ($source:$line)")
                    while (console.size > 400) console.poll()
                    return false
                }
            })
            val br = c.createBrowser("about:blank", false, false)
            browser = br
            progress = -1
            return br
        } catch (t: Throwable) {
            error = t.message ?: t.toString()
            throw t
        }
    }

    fun load(url: String) {
        pageReady = false
        val b = init()
        if (created) b.loadURL(url) else pendingUrl = url
    }

    fun js(code: String) { browser?.executeJavaScript(code, "$ORIGIN/editor.html", 0) }

    fun component(): java.awt.Component = init().uiComponent

    fun shutdown() {
        created = false
        runCatching { browser?.close(true) }
        runCatching { client?.dispose() }
        runCatching { app?.dispose() }
        browser = null; client = null; app = null
    }

    // ------------------------------------------------------------------ conteúdo interno

    /** O que o editor recebe: editor.html (com a ponte), traduções e as chamadas da ponte. */
    private object Local : CefResourceRequestHandlerAdapter() {
        override fun getResourceHandler(browser: CefBrowser?, frame: CefFrame?, request: CefRequest?): CefResourceHandler = Resp()
    }

    private class Resp : CefResourceHandlerAdapter() {
        private var data = ByteArray(0)
        private var mime = "text/plain"
        private var status = 200
        private var off = 0

        override fun processRequest(request: CefRequest, callback: CefCallback): Boolean {
            val path = request.url.removePrefix(ORIGIN).substringBefore('?').substringBefore('#')
            try {
                when {
                    path.startsWith("/__bridge/") -> {
                        val method = path.removePrefix("/__bridge/")
                        val body = postBody(request)
                        val args = runCatching {
                            val a = org.json.JSONArray(body.ifBlank { "[]" })
                            (0 until a.length()).map { a.opt(it)?.toString() ?: "" }
                        }.getOrDefault(emptyList())
                        val r = runCatching { bridge?.invoke(method, args) ?: "" }.getOrDefault("")
                        data = r.toByteArray(Charsets.UTF_8); mime = "text/plain"
                    }
                    path == "/" || path == "/editor.html" || path == "/assets/editor.html" -> {
                        data = editorHtml(); mime = "text/html"
                    }
                    else -> {
                        val res = path.removePrefix("/").removePrefix("assets/")
                        val inp = Browser::class.java.classLoader.getResourceAsStream("assets/$res")
                        if (inp == null) { status = 404; data = ByteArray(0) } else {
                            data = inp.use { it.readBytes() }
                            mime = android.webkit.MimeTypeMap.mimeOf(res) ?: "application/octet-stream"
                        }
                    }
                }
            } catch (t: Throwable) {
                status = 500; data = (t.message ?: "erro").toByteArray()
            }
            callback.Continue()
            return true
        }

        override fun getResponseHeaders(response: CefResponse, responseLength: IntRef, redirectUrl: StringRef?) {
            response.status = status
            response.statusText = if (status == 200) "OK" else "ERR"
            response.mimeType = mime
            if (mime.startsWith("text/") || mime.contains("json") || mime.contains("javascript")) response.setHeaderByName("Content-Type", "$mime; charset=utf-8", true)
            response.setHeaderByName("Cache-Control", "no-store", true)
            responseLength.set(data.size)
        }

        override fun readResponse(dataOut: ByteArray, bytesToRead: Int, bytesRead: IntRef, callback: CefCallback?): Boolean {
            if (off >= data.size) { bytesRead.set(0); return false }
            val n = minOf(bytesToRead, data.size - off)
            System.arraycopy(data, off, dataOut, 0, n)
            off += n
            bytesRead.set(n)
            return true
        }
    }

    private fun postBody(r: CefRequest): String {
        val pd = r.postData ?: return ""
        val v = Vector<CefPostDataElement>()
        pd.getElements(v)
        val out = java.io.ByteArrayOutputStream()
        for (e in v) {
            val n = e.bytesCount
            if (n > 0) { val b = ByteArray(n); e.getBytes(n, b); out.write(b, 0, n) }
            else runCatching { e.file?.takeIf { it.isNotEmpty() }?.let { out.write(File(it).readBytes()) } }
        }
        return out.toString(Charsets.UTF_8)
    }

    /** editor.html do app com a ponte ArqueApp no começo (antes de qualquer script do editor). */
    private fun editorHtml(): ByteArray {
        val html = Browser::class.java.classLoader.getResourceAsStream("assets/editor.html")!!.use { it.readBytes().toString(Charsets.UTF_8) }
        val i = html.indexOf("<head>")
        val at = if (i >= 0) i + 6 else 0
        return (html.substring(0, at) + "<script>" + BRIDGE_JS + "</script>" + html.substring(at)).toByteArray(Charsets.UTF_8)
    }

    /** A mesma interface ArqueApp que o Android injeta no WebView (chamadas síncronas). */
    private val BRIDGE_JS = """
(function(){
  function call(m,args){
    try{var x=new XMLHttpRequest();x.open('POST','$ORIGIN/__bridge/'+m,false);x.setRequestHeader('Content-Type','application/json');x.send(JSON.stringify(args||[]));return x.status===200?x.responseText:''}catch(e){return ''}
  }
  function A(m){return function(){return call(m,[].slice.call(arguments).map(function(v){return v==null?'':String(v)}))}}
  function B(m){var f=A(m);return function(){return f.apply(null,arguments)==='true'}}
  window.ArqueApp={
    isApp:function(){return true},isWindows:function(){return true},
    companyName:A('companyName'),listNotes:A('listNotes'),contextNote:A('contextNote'),
    linkNote:A('linkNote'),openNoteOf:A('openNoteOf'),makeQuote:A('makeQuote'),setCurrent:A('setCurrent'),
    openTrena:A('openTrena'),shareStart:A('shareStart'),isSharing:B('isSharing'),isViewer:B('isViewer'),
    shareUpdate:function(){},shareCut:A('shareCut'),shareClient:A('shareClient'),close:A('close'),
    putFile:A('putFile'),getFile:A('getFile'),delFile:A('delFile'),listFiles:A('listFiles'),tourResult:A('tourResult')
  };
  window.addEventListener('load',function(){setTimeout(function(){call('pageReady',[typeof S])},0)});
  document.addEventListener('DOMContentLoaded',function(){var st=document.createElement('style');st.textContent='#shb{display:none!important}';document.head.appendChild(st)});
  document.addEventListener('keydown',function(e){
    if(e.key==='Escape'&&!e.defaultPrevented){var t=e.target;if(t&&(t.tagName==='INPUT'||t.tagName==='TEXTAREA'))return;
      if(!(window.arqueBack&&window.arqueBack()))window.ArqueApp.close();e.preventDefault()}
  });
})();
""".trimIndent()
}
