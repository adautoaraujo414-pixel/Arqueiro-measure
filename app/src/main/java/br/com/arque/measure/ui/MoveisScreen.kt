package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import android.util.Base64
import android.view.ViewGroup
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.clickable
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.FileProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.webkit.WebViewAssetLoader
import br.com.arque.measure.AppViewModel
import br.com.arque.measure.Screen
import br.com.arque.measure.ble.BleState
import java.io.File

/**
 * Editor de móveis: a tela completa (ambiente com folga, módulos, pedra em reta/L/U com cuba e cooktop,
 * eletrodomésticos, ripado, tamponamentos, lista de corte, clientes com fotos/vídeos, trena laser)
 * rodando dentro do app. A trena Bosch (Bluetooth) entrega as leituras pela ponte abaixo.
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
fun MoveisScreen(vm: AppViewModel) {
    val ctx = LocalContext.current
    var web by remember { mutableStateOf<WebView?>(null) }
    var showBle by remember { mutableStateOf(false) }
    val bleState by vm.ble.state.collectAsStateWithLifecycle()
    val bleName by vm.ble.deviceName.collectAsStateWithLifecycle()

    // ---- escolha de arquivo (galeria, câmera de foto e de vídeo) ----
    var chooserCb by remember { mutableStateOf<ValueCallback<Array<Uri>>?>(null) }
    var camUri by remember { mutableStateOf<Uri?>(null) }
    val chooser = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { res ->
        val cb = chooserCb
        chooserCb = null
        if (cb == null) return@rememberLauncherForActivityResult
        if (res.resultCode != Activity.RESULT_OK) {
            cb.onReceiveValue(null)
            return@rememberLauncherForActivityResult
        }
        val list = mutableListOf<Uri>()
        val data = res.data
        data?.clipData?.let { c -> for (i in 0 until c.itemCount) list.add(c.getItemAt(i).uri) }
        data?.data?.let { if (!list.contains(it)) list.add(it) }
        if (list.isEmpty()) camUri?.let { list.add(it) }
        cb.onReceiveValue(if (list.isEmpty()) null else list.toTypedArray())
    }

    fun newCamFile(ext: String): Uri {
        val dir = File(ctx.cacheDir, "camera").apply { mkdirs() }
        val f = File(dir, "m_${System.currentTimeMillis()}.$ext")
        return FileProvider.getUriForFile(ctx, "${ctx.packageName}.fileprovider", f)
    }

    val files = remember { File(ctx.filesDir, "moveis").apply { mkdirs() } }
    var showShare by remember { mutableStateOf(false) }
    val bridge = remember { MoveisBridge(files, { web }, { vm.screen = Screen.Library }, { showBle = true }, { showShare = true }, { vm.moveisView }, { id -> vm.lastProjectId = id; vm.projVersion++ }, { json -> vm.quoteFromMoveis(json) }) }
    DisposableEffect(Unit) { onDispose { vm.projVersion++ } }
    val viewing = vm.moveisView
    val vState by br.com.arque.measure.share.BtShare.viewState.collectAsStateWithLifecycle()
    val vFrame by br.com.arque.measure.share.BtShare.frame.collectAsStateWithLifecycle()
    fun leaveView() { br.com.arque.measure.share.BtShare.disconnect(); vm.moveisView = false; vm.screen = Screen.Library }
    LaunchedEffect(vFrame, web) {
        val f = vFrame ?: return@LaunchedEffect
        val w = web ?: return@LaunchedEffect
        if (viewing) w.evaluateJavascript("window.arqueView&&window.arqueView($f)", null)
    }

    DisposableEffect(web) {
        val w = web
        vm.moveisSink = { mm ->
            w?.post { w.evaluateJavascript("window.arqueLaser&&window.arqueLaser(${String.format(java.util.Locale.US, "%.1f", mm)})", null) }
        }
        onDispose { vm.moveisSink = null }
    }

    BackHandler {
        if (viewing) { leaveView(); return@BackHandler }
        val w = web
        if (w == null) {
            vm.screen = Screen.Library
        } else {
            w.evaluateJavascript("(window.arqueBack&&window.arqueBack())?'1':'0'") { r ->
                if (r == null || !r.contains("1")) vm.screen = Screen.Library
            }
        }
    }

    Box(Modifier.fillMaxSize().background(Color.White).statusBarsPadding().navigationBarsPadding().imePadding()) {
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { c ->
                val loader = WebViewAssetLoader.Builder()
                    .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(c))
                    .build()
                WebView(c).apply {
                    layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
                    setBackgroundColor(android.graphics.Color.WHITE)
                    settings.apply {
                        javaScriptEnabled = true
                        domStorageEnabled = true
                        databaseEnabled = true
                        allowFileAccess = false
                        allowContentAccess = true
                        mediaPlaybackRequiresUserGesture = false
                        cacheMode = WebSettings.LOAD_DEFAULT
                        setSupportZoom(false)
                        builtInZoomControls = false
                    }
                    addJavascriptInterface(bridge, "ArqueApp")
                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView, url: String?) {
                            if (vm.moveisView) {
                                view.evaluateJavascript("window.arqueViewMode&&window.arqueViewMode()", null)
                                br.com.arque.measure.share.BtShare.frame.value?.let { f -> view.evaluateJavascript("window.arqueView&&window.arqueView($f)", null) }
                            }
                            if (vm.pendingNewProject && !vm.moveisView) {
                                vm.pendingNewProject = false
                                view.evaluateJavascript("window.arqueNewProject&&window.arqueNewProject()", null)
                            }
                            vm.pendingProject?.let { id ->
                                vm.pendingProject = null
                                view.evaluateJavascript("window.arqueOpenClient&&window.arqueOpenClient('${id.replace("'", "")}')", null)
                            }
                        }

                        override fun shouldInterceptRequest(view: WebView, request: WebResourceRequest): WebResourceResponse? =
                            loader.shouldInterceptRequest(request.url)

                        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                            val u = request.url
                            if (u.host == WebViewAssetLoader.DEFAULT_DOMAIN) return false
                            // tel:, WhatsApp (wa.me), e-mail e links de fora abrem nos apps do telefone
                            try {
                                val it = Intent(Intent.ACTION_VIEW, u)
                                if (u.host == "wa.me") it.setPackage(null)
                                ctx.startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                            } catch (_: ActivityNotFoundException) {
                                vm.toast = tr("Nenhum app encontrado pra abrir isso")
                            }
                            return true
                        }
                    }
                    webChromeClient = object : WebChromeClient() {
                        override fun onShowFileChooser(
                            view: WebView, cb: ValueCallback<Array<Uri>>, params: WebChromeClient.FileChooserParams,
                        ): Boolean {
                            chooserCb?.onReceiveValue(null)
                            chooserCb = cb
                            val wantsVideo = params.acceptTypes.any { it.startsWith("video") }
                            val camIntent: Intent
                            if (wantsVideo) {
                                val u = newCamFile("mp4"); camUri = u
                                camIntent = Intent(MediaStore.ACTION_VIDEO_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, u)
                            } else {
                                val u = newCamFile("jpg"); camUri = u
                                camIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).putExtra(MediaStore.EXTRA_OUTPUT, u)
                            }
                            camIntent.addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            val cam = camIntent
                            val intent = if (params.isCaptureEnabled) cam else {
                                val pick = Intent(Intent.ACTION_GET_CONTENT).apply {
                                    addCategory(Intent.CATEGORY_OPENABLE)
                                    type = if (wantsVideo) "video/*" else "image/*"
                                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, params.mode == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE)
                                }
                                Intent.createChooser(pick, if (wantsVideo) tr("Vídeo") else tr("Foto")).putExtra(Intent.EXTRA_INITIAL_INTENTS, arrayOf(cam))
                            }
                            return try {
                                chooser.launch(intent); true
                            } catch (e: Exception) {
                                chooserCb = null; cb.onReceiveValue(null); false
                            }
                        }
                    }
                    loadUrl("https://${WebViewAssetLoader.DEFAULT_DOMAIN}/assets/editor.html?lang=${br.com.arque.measure.i18n.I18n.lang}&cur=${android.net.Uri.encode(br.com.arque.measure.i18n.I18n.currencySymbol())}")
                    web = this
                }
            },
            onRelease = { it.removeJavascriptInterface("ArqueApp"); it.destroy(); web = null },
        )

        // Vendo projeto de outro celular (só visualização)
        if (viewing) {
            Row(
                Modifier.align(Alignment.TopCenter).padding(6.dp).clip(RoundedCornerShape(20.dp)).background(Color(0xE61B1F27))
                    .padding(horizontal = 12.dp, vertical = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    when (vState) {
                        "connecting" -> tr("📡 Conectando em {0}…", br.com.arque.measure.share.BtShare.viewFrom)
                        "connected" -> tr("👁 Ao vivo · {0} · só visualização", br.com.arque.measure.share.BtShare.viewFrom)
                        "error" -> tr("Não conectou. O outro celular está compartilhando?")
                        else -> tr("Conexão encerrada")
                    },
                    color = Color.White, fontSize = 12.sp,
                )
                Text(tr("  ✕ Sair"), color = Color(0xFFF5B400), fontSize = 12.sp, modifier = Modifier.clickable { leaveView() })
            }
        }
    }
    if (showBle) BluetoothScreen(vm) { showBle = false }
    if (showShare) ShareHostDialog(onPush = { web?.post { web?.evaluateJavascript("window.arqueShareNow&&window.arqueShareNow()", null) } }) { showShare = false }
}

/** Ponte que o editor (JavaScript) usa pra falar com o Android: fechar a tela e guardar cópias em arquivo. */
class MoveisBridge(
    private val dir: File,
    private val web: () -> WebView?,
    private val onClose: () -> Unit,
    private val onTrena: () -> Unit = {},
    private val onShare: () -> Unit = {},
    private val viewing: () -> Boolean = { false },
    private val onCurrent: (String) -> Unit = {},
    private val onQuote: (String) -> Unit = {},
) {
    /** "Gerar orçamento em PDF" no editor: cria o orçamento do app com o cliente e o valor do projeto. */
    @JavascriptInterface fun makeQuote(json: String) { web()?.post { onQuote(json) } }
    @JavascriptInterface fun setCurrent(id: String) { web()?.post { onCurrent(id) } }
    @JavascriptInterface fun openTrena() { web()?.post { onTrena() } }
    @JavascriptInterface fun shareStart() { web()?.post { onShare() } }
    @JavascriptInterface fun isSharing(): Boolean = br.com.arque.measure.share.BtShare.hosting.value
    @JavascriptInterface fun isViewer(): Boolean = viewing()
    @JavascriptInterface fun shareUpdate(json: String) { br.com.arque.measure.share.BtShare.update(json) }

    private fun safe(name: String) = name.replace(Regex("[^A-Za-z0-9_.-]"), "_")

    @JavascriptInterface fun isApp(): Boolean = true

    @JavascriptInterface fun close() { web()?.post { onClose() } }

    @JavascriptInterface fun putFile(name: String, b64: String) {
        runCatching { File(dir, safe(name)).writeBytes(Base64.decode(b64, Base64.DEFAULT)) }
    }

    @JavascriptInterface fun getFile(name: String): String = runCatching {
        val f = File(dir, safe(name))
        if (f.exists()) Base64.encodeToString(f.readBytes(), Base64.NO_WRAP) else ""
    }.getOrDefault("")

    @JavascriptInterface fun delFile(name: String) { runCatching { File(dir, safe(name)).delete() } }

    @JavascriptInterface fun listFiles(): String =
        (dir.list() ?: emptyArray()).joinToString(prefix = "[", postfix = "]", separator = ",") { "\"$it\"" }
}
