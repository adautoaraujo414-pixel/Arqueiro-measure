import XCTest
import WebKit
import UIKit

/// CI-ESTAB (Chefe 25/11, lentidão do iPhone no CI; run 695): o tempo perdido era do WebKit no simulador, antes de a página começar
/// ("WebContent/Networking process took 14–300 s to launch", 1186 "Failed to terminate process"). Cada teste criava um
/// WKWebsiteDataStore.nonPersistent() novo, e o WebKit derrubava e relançava os processos a cada teste.
/// Agora:
/// - Um armazenamento só pra bateria, como o app, que usa uma sessão só. O isolamento continua: tudo é apagado antes de cada teste
///   (testISOLAMENTO_… prova com localStorage e IndexedDB).
/// - Aquecimento do WebKit (ambiente, autorizado pelo Adauto via Chefe): antes do 1º editor sobe Networking, WebContent e GPU com
///   about:blank e imprime "ABERTURA-DIAG WebKit frio: N s". Sem assert e sem limite novo. A 1ª abertura do EDITOR continua medida
///   com os mesmos 20 s.
@MainActor
enum WebKitCompartilhado {
    static let store = WKWebsiteDataStore.nonPersistent()
    private static var aquecido = false

    private final class Fim: NSObject, WKNavigationDelegate {
        var feito: (() -> Void)?
        func webView(_ w: WKWebView, didFinish n: WKNavigation!) { feito?(); feito = nil }
        func webView(_ w: WKWebView, didFail n: WKNavigation!, withError e: Error) { feito?(); feito = nil }
        func webView(_ w: WKWebView, didFailProvisionalNavigation n: WKNavigation!, withError e: Error) { feito?(); feito = nil }
    }

    /// Isolamento entre testes: apaga localStorage, IndexedDB, cookies, cache e o resto do armazenamento compartilhado.
    static func limpa() async {
        await store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast)
    }

    /// Sobe os processos do WebKit uma vez, antes do 1º editor, e mede quanto o WebKit frio levou.
    static func aquece() async {
        guard !aquecido else { return }
        aquecido = true
        let t0 = Date()
        await limpa()                                   // sobe o processo de rede do armazenamento compartilhado
        let tRede = Date().timeIntervalSince(t0)
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = store
        let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), configuration: cfg)
        if let win = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first { win.addSubview(w) }
        let d = Fim()
        w.navigationDelegate = d
        await withCheckedContinuation { (c: CheckedContinuation<Void, Never>) in
            var pronto = false
            let fim = { if !pronto { pronto = true; c.resume() } }
            d.feito = fim
            // segurança: o aquecimento nunca trava a bateria (o teste seguinte mede e acusa o que for)
            DispatchQueue.main.asyncAfter(deadline: .now() + 300) { fim() }
            w.load(URLRequest(url: URL(string: "about:blank")!))
        }
        _ = try? await w.evaluateJavaScript("1")       // a página respondeu: o WebContent está no ar
        print("ABERTURA-DIAG WebKit frio: \(String(format: "%.2f", Date().timeIntervalSince(t0))) s (rede \(String(format: "%.2f", tRede)) s · página em branco pronta) · antes do 1º editor, sem limite")
        w.navigationDelegate = nil
        w.removeFromSuperview()
    }
}
