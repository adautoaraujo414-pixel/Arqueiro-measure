import SwiftUI
import WebKit
import Combine

/// Editor de móveis: o MESMO editor.html do Android, rodando num WKWebView.
/// A ponte "ArqueApp" (a mesma que o Android expõe) guarda cópias dos projetos em arquivo,
/// recebe a trena Bosch e o compartilhamento ao vivo.
struct MoveisView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var peer: PeerShare
    @State private var btOpen = false
    @State private var shareOpen = false
    @StateObject private var holder = WebHolder()

    var body: some View {
        ZStack(alignment: .top) {
            Ui.bg.ignoresSafeArea()
            MoveisWeb(app: app, peer: peer, holder: holder, onClose: { leave() }, onTrena: { btOpen = true }, onShare: { shareOpen = true })
            if app.moveisView {
                HStack(spacing: 10) {
                    Text(peer.viewState == "connecting" ? tr("📡 Conectando em {0}…", peer.viewFrom) :
                         peer.viewState == "connected" ? tr("👁 Ao vivo · {0} · só visualização", peer.viewFrom) :
                         peer.viewState == "error" ? tr("Não conectou. O outro aparelho está compartilhando?") : tr("Conexão encerrada"))
                        .font(.caption).foregroundColor(.white)
                    Button(tr("✕ Sair")) { leave() }.font(.caption.bold()).foregroundColor(Ui.gold)
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Capsule().fill(Color(argb: 0xE61B1F27)))
                .padding(.top, 6)
            }
        }
        .sheet(isPresented: $btOpen) { BluetoothView() }
        .sheet(isPresented: $shareOpen) { ShareHostView { holder.eval("window.arqueShareNow&&window.arqueShareNow()") } }
        .onReceive(peer.$frame) { f in
            guard app.moveisView, let f = f else { return }
            holder.eval("window.arqueView&&window.arqueView(\(f))")
        }
        .onReceive(peer.$hosting) { h in holder.eval("window.__arqueSharing=\(h ? "true" : "false")") }
        .onAppear {
            app.moveisSink = { mm in holder.eval("window.arqueLaser&&window.arqueLaser(\(String(format: "%.1f", mm)))") }
        }
        .onDisappear { app.moveisSink = nil; app.projVersion += 1 }
    }

    private func leave() {
        if app.moveisView { peer.disconnect(); app.moveisView = false }
        app.screen = .library
    }
}

final class WebHolder: ObservableObject {
    weak var web: WKWebView?
    func eval(_ js: String) { DispatchQueue.main.async { self.web?.evaluateJavaScript(js, completionHandler: nil) } }
}

/// Serve o editor.html do app com uma origem fixa (arque://app), para o armazenamento do editor ficar guardado.
final class BundleSchemeHandler: NSObject, WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        let name = url.lastPathComponent.isEmpty ? "editor.html" : url.lastPathComponent
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        guard let file = Bundle.main.url(forResource: base, withExtension: ext.isEmpty ? "html" : ext), let data = try? Data(contentsOf: file) else {
            task.didFailWithError(NSError(domain: "arque", code: 404)); return
        }
        let mime = ext == "html" || ext.isEmpty ? "text/html" : "application/octet-stream"
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "\(mime); charset=utf-8", "Content-Length": "\(data.count)"])!)
        task.didReceive(data)
        task.didFinish()
    }
    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

struct MoveisWeb: UIViewRepresentable {
    let app: AppModel
    let peer: PeerShare
    var holder: WebHolder
    var onClose: () -> Void
    var onTrena: () -> Void
    var onShare: () -> Void

    static let bridgeJS = """
    (function(){
      var post=function(m){try{window.webkit.messageHandlers.arque.postMessage(m)}catch(e){}};
      var sync=function(op,arg){var r=window.prompt('__arque__:'+op,arg==null?'':String(arg));return r==null?'':r};
      window.__arqueSharing=false;window.__arqueViewer=false;
      window.ArqueApp={
        isApp:function(){return true},
        close:function(){post({op:'close'})},
        setCurrent:function(id){post({op:'setCurrent',id:String(id)})},
        openTrena:function(){post({op:'openTrena'})},
        shareStart:function(){post({op:'shareStart'})},
        isSharing:function(){return !!window.__arqueSharing},
        isViewer:function(){return !!window.__arqueViewer},
        shareUpdate:function(j){post({op:'shareUpdate',json:String(j)})},
        putFile:function(n,b){post({op:'putFile',name:String(n),b64:String(b)})},
        getFile:function(n){return sync('getFile',n)},
        delFile:function(n){post({op:'delFile',name:String(n)})},
        listFiles:function(){return sync('listFiles','')||'[]'}
      };
    })();
    """

    func makeCoordinator() -> Coord { Coord(self) }

    func makeUIView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .default()
        cfg.setURLSchemeHandler(BundleSchemeHandler(), forURLScheme: "arque")
        cfg.allowsInlineMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        let uc = WKUserContentController()
        uc.addUserScript(WKUserScript(source: MoveisWeb.bridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        uc.add(context.coordinator, name: "arque")
        cfg.userContentController = uc
        let w = WKWebView(frame: .zero, configuration: cfg)
        w.navigationDelegate = context.coordinator
        w.uiDelegate = context.coordinator
        w.scrollView.bounces = false
        w.isOpaque = true
        w.backgroundColor = .white
        holder.web = w
        let cur = I18n.shared.currencySymbol().addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        w.load(URLRequest(url: URL(string: "arque://app/editor.html?lang=\(I18n.shared.lang)&cur=\(cur)") ?? URL(string: "arque://app/editor.html")!))
        return w
    }

    func updateUIView(_ w: WKWebView, context: Context) { context.coordinator.parent = self }

    static func dismantleUIView(_ w: WKWebView, coordinator: Coord) {
        w.configuration.userContentController.removeScriptMessageHandler(forName: "arque")
    }

    final class Coord: NSObject, WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate {
        var parent: MoveisWeb
        init(_ p: MoveisWeb) { parent = p }

        private var dir: URL { AppPaths.moveis }
        private func safe(_ n: String) -> String { String(n.map { $0.isLetter || $0.isNumber || "_.-".contains($0) ? $0 : "_" }) }

        func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let m = message.body as? [String: Any], let op = m["op"] as? String else { return }
            let app = parent.app
            switch op {
            case "close": parent.onClose()
            case "openTrena": parent.onTrena()
            case "shareStart": parent.onShare()
            case "setCurrent": if let id = m["id"] as? String { app.lastProjectId = id; app.projVersion += 1 }
            case "shareUpdate": if let j = m["json"] as? String { parent.peer.update(j) }
            case "putFile":
                if let n = m["name"] as? String, let b = m["b64"] as? String, let d = Data(base64Encoded: b, options: .ignoreUnknownCharacters) {
                    try? d.write(to: dir.appendingPathComponent(safe(n)), options: [.atomic])
                }
            case "delFile": if let n = m["name"] as? String { try? FileManager.default.removeItem(at: dir.appendingPathComponent(safe(n))) }
            default: break
            }
        }

        // ponte síncrona (o editor espera a resposta na hora): getFile e listFiles
        func webView(_ w: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            if prompt == "__arque__:getFile" {
                let url = dir.appendingPathComponent(safe(defaultText ?? ""))
                completionHandler((try? Data(contentsOf: url))?.base64EncodedString() ?? "")
            } else if prompt == "__arque__:listFiles" {
                let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
                completionHandler(JsonCodec.string(names))
            } else {
                completionHandler(nil)
            }
        }

        func webView(_ w: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { completionHandler() }
        func webView(_ w: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) { completionHandler(true) }

        func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) {
            let app = parent.app
            if app.moveisView {
                w.evaluateJavaScript("window.__arqueViewer=true;window.arqueViewMode&&window.arqueViewMode()")
                if let f = parent.peer.frame { w.evaluateJavaScript("window.arqueView&&window.arqueView(\(f))") }
            }
            if app.pendingNewProject && !app.moveisView {
                app.pendingNewProject = false
                w.evaluateJavaScript("window.arqueNewProject&&window.arqueNewProject()")
            }
            if let id = app.pendingProject {
                app.pendingProject = nil
                w.evaluateJavaScript("window.arqueOpenClient&&window.arqueOpenClient('\(id.replacingOccurrences(of: "'", with: ""))')")
            }
            w.evaluateJavaScript("window.__arqueSharing=\(parent.peer.hosting ? "true" : "false")")
        }

        /// tel:, WhatsApp (wa.me), e-mail e links de fora abrem nos apps do aparelho.
        func webView(_ w: WKWebView, decidePolicyFor nav: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let u = nav.request.url else { decisionHandler(.cancel); return }
            if u.scheme == "arque" || u.scheme == "about" || u.scheme == "blob" || u.scheme == "data" { decisionHandler(.allow); return }
            decisionHandler(.cancel)
            UIApplication.shared.open(u) { ok in if !ok { Task { @MainActor in self.parent.app.toast = tr("Nenhum app encontrado pra abrir isso") } } }
        }
    }
}
