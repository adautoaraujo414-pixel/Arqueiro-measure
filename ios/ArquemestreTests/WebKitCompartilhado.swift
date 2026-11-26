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

    // RECURSO-DIAG (Chefe 25/11, quedas do iOS 699): conta os WKWebView ainda vivos (referência fraca: só some quando o WebKit
    // solta de verdade), a memória do app de teste e os processos do WebKit no Mac, a cada 50 testes. Só imprime; sem assert e sem limite.
    private static let vivos = NSHashTable<WKWebView>.weakObjects()
    private static var criados = 0, testes = 0

    static func registra(_ w: WKWebView) { vivos.add(w); criados += 1 }

    static func depoisDoTeste(_ nome: String) {
        testes += 1
        let n = vivos.allObjects.count
        guard testes % 50 == 0 || n > 3 else { return }
        print("RECURSO-DIAG teste \(testes) (\(nome)) · WKWebView vivos \(n) de \(criados) criados · memória do app \(memoriaMB()) MB · processos com.apple.WebKit no Mac \(processosWebKit())")
    }

    /// memória do app de teste (phys_footprint, o número que o iOS usa pra matar app por memória); -1 se não der pra ler
    static func memoriaMB() -> Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return kr == KERN_SUCCESS ? Int(info.phys_footprint / 1_048_576) : -1
    }

    /// quantos processos com nome começando por "com.apple.WebKi" (WebContent, GPU e Networking: o nome curto do kernel corta em 16 letras); -1 se não der
    static func processosWebKit() -> Int {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var size = 0
        guard sysctl(&mib, 4, nil, &size, nil, 0) == 0, size > 0 else { return -1 }
        let passo = MemoryLayout<kinfo_proc>.stride
        var lista = [kinfo_proc](repeating: kinfo_proc(), count: size / passo + 32)
        size = lista.count * passo
        guard sysctl(&mib, 4, &lista, &size, nil, 0) == 0 else { return -1 }
        var n = 0
        for var p in lista.prefix(size / passo) {
            let nome = withUnsafeBytes(of: &p.kp_proc.p_comm) { String(decoding: $0.prefix(while: { $0 != 0 }), as: UTF8.self) }
            if nome.hasPrefix("com.apple.WebKi") { n += 1 }
        }
        return n
    }

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
        await aquece(store: store, rotulo: "WebKit frio", limpar: true)
    }

    /// O mesmo aquecimento para outro armazenamento (testes de atualização, que usam o armazenamento deles; iOS-atualização 37, 26/11:
    /// a 1ª abertura do editor no iPad frio passou de 90 s e a 2ª, logo depois, abriu em 28 s). Não apaga nada do armazenamento:
    /// só lê a lista de dados (sobe o processo de rede) e abre about:blank. Sem assert e sem limite novo.
    private static var aquecidos = Set<ObjectIdentifier>()
    static func aquece(store s: WKWebsiteDataStore, rotulo: String, limpar: Bool = false) async {
        guard !aquecidos.contains(ObjectIdentifier(s)) else { return }
        aquecidos.insert(ObjectIdentifier(s))
        let t0 = Date()
        if limpar { await limpa() } else { _ = await s.dataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) }   // sobe o processo de rede
        let tRede = Date().timeIntervalSince(t0)
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = s
        let w = WKWebView(frame: CGRect(x: 0, y: 0, width: 40, height: 40), configuration: cfg)
        registra(w)
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
        print("ABERTURA-DIAG \(rotulo): \(String(format: "%.2f", Date().timeIntervalSince(t0))) s (rede \(String(format: "%.2f", tRede)) s · página em branco pronta) · antes do 1º editor, sem limite")
        w.navigationDelegate = nil
        w.removeFromSuperview()
    }
}
