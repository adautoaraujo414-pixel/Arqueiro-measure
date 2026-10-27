import SwiftUI

struct RootView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var lic: LicenseManager
    /// Trocar o idioma redesenha o app inteiro no idioma novo (nada é perdido: tudo fica no AppModel).
    @ObservedObject private var i18n = I18n.shared

    var body: some View {
        ZStack {
            Ui.bg.ignoresSafeArea()
            switch lic.status {
            case .loading:
                ProgressView().tint(Ui.gold)
            case .notStarted:
                TrialOfferView()
            case .expired:
                LockView()
            case .trial, .unlocked:
                main
            }
        }
        .overlay(alignment: .top) {
            if let t = app.toast {
                Text(t).font(.subheadline).foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.88)))
                    .padding(.top, 64).padding(.horizontal, 16)
                    .transition(.opacity)
                    .onTapGesture { app.toast = nil }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: app.toast)
        .id(i18n.lang)
    }

    @ViewBuilder private var main: some View {
        ZStack(alignment: .bottomLeading) {
            switch app.screen {
            case .library: LibraryView()
            case .editor:
                if let s = app.session { EditorView(session: s) } else { LibraryView() }
            case .quotes: QuotesView()
            case .agenda: AgendaView()
            case .moveis: MoveisView()
            }
            if lic.status == .trial && app.screen == .library {
                TrialChip().padding(12)
            }
        }
    }
}

// ---------------- Licença ----------------

/// Antes de usar: explica o teste grátis (prazo, o que acontece depois e o preço), como a Apple pede.
struct TrialOfferView: View {
    @EnvironmentObject var lic: LicenseManager
    @State private var guide = 0
    @State private var langOpen = false

    private let pages: [(String, String)] = [
        (tr("📏 Medições"), tr("Crie uma nota, tire foto ou desenhe o croqui e ligue a trena Bosch: a medida cai direto na cota, com milímetro.")),
        (tr("🪚 Editor de móveis"), tr("Monte cozinha, guarda-roupa, painel e sala. Veja em 3D, abra portas e gavetas, estique peças arrastando.")),
        (tr("📋 Corte e orçamento"), tr("Lista de corte, plano das chapas inteiras, custo do material e orçamento em PDF saem sozinhos.")),
        (tr("📅 Agenda"), tr("Marque entregas, visitas e medições ligadas ao cliente. O app avisa antes.")),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("ARQUEMESTRE").font(.system(size: 28, weight: .bold)).foregroundColor(Ui.gold).padding(.top, 40)
                Text(tr("Seja bem-vindo!")).font(.title2.bold()).foregroundColor(.white)
                Text(tr("Medição, projeto, corte, orçamento e agenda da sua marcenaria num lugar só."))
                    .multilineTextAlignment(.center).foregroundColor(Ui.dim)
                Button(langMenuLabel() + ": " + currentLangName()) { langOpen = true }
                    .font(.subheadline).foregroundColor(Ui.accent)
                    .sheet(isPresented: $langOpen) { LanguagePicker() }
                TabView(selection: $guide) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(pages[i].0).font(.headline).foregroundColor(.white)
                            Text(pages[i].1).foregroundColor(Ui.dim)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel)).padding(.horizontal, 2)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 170)

                VStack(alignment: .leading, spacing: 8) {
                    Text(tr("Como funciona")).font(.headline).foregroundColor(.white)
                    Label(tr("Teste grátis de {0} dias com tudo liberado.", LicenseManager.TRIAL_DAYS), systemImage: "gift")
                    Label(tr("Depois dos {0} dias, as telas ficam bloqueadas até a compra. Seus dados continuam guardados e dá para fazer backup.", LicenseManager.TRIAL_DAYS), systemImage: "lock")
                    Label(tr("Acesso completo: compra única{0} pela App Store. Sem assinatura, sem mensalidade.", lic.priceOf), systemImage: "creditcard")
                    Label(tr("O teste não cobra nada e não vira cobrança sozinho."), systemImage: "checkmark.shield")
                }
                .font(.subheadline).foregroundColor(Ui.dim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))

                Button { Task { await lic.startTrial() } } label: {
                    Text(tr("Começar teste grátis de {0} dias", LicenseManager.TRIAL_DAYS)).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent).tint(Ui.accent).disabled(lic.busy)

                Button { Task { await lic.buyFull() } } label: {
                    Text(tr("Comprar acesso completo{0}", lic.priceTag)).frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.bordered).disabled(lic.busy)

                Button(tr("Já comprei · restaurar compra")) { Task { await lic.restore() } }.disabled(lic.busy)

                if lic.busy { ProgressView() }
                if let m = lic.message { Text(m).font(.footnote).foregroundColor(Ui.gold).multilineTextAlignment(.center) }
                LegalLinks()
            }
            .padding(20).frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Páginas públicas (GitHub Pages) no idioma do app.
enum SiteLinks {
    static let base = "https://adautoaraujo414-pixel.github.io/Arqueiro-measure/"
    static var privacy: URL {
        URL(string: base + (I18n.shared.lang == "en" ? "privacy.html" : I18n.shared.lang == "es" ? "privacidad.html" : "privacidade.html"))!
    }
    static var support: URL {
        URL(string: base + (I18n.shared.lang == "en" ? "support.html" : I18n.shared.lang == "es" ? "soporte.html" : "suporte.html"))!
    }
}

struct LegalLinks: View {
    var body: some View {
        HStack(spacing: 16) {
            Link(tr("Privacidade"), destination: SiteLinks.privacy)
            Link(tr("Termos de uso (EULA)"), destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            Link(tr("Ajuda"), destination: SiteLinks.support)
        }
        .font(.caption).foregroundColor(Ui.dim).padding(.top, 6)
    }
}

/// Depois do teste: bloqueia, mas os dados ficam e dá para fazer backup.
struct LockView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var lic: LicenseManager
    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("ARQUEMESTRE").font(.system(size: 26, weight: .bold)).foregroundColor(Ui.gold).padding(.top, 50)
                Text(tr("Você chegou ao fim do período de teste")).font(.title3.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                Text(tr("Para continuar usando e não perder nada (notas, agenda, orçamentos e projetos de móveis ficam todos guardados), o acesso completo é por pagamento único{0} pela App Store.", lic.priceOf))
                    .foregroundColor(Ui.dim).multilineTextAlignment(.center)
                Button { Task { await lic.buyFull() } } label: {
                    Text(tr("Desbloquear{0}", lic.priceTag)).font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
                }.buttonStyle(.borderedProminent).disabled(lic.busy)
                Button(tr("Já comprei · restaurar compra")) { Task { await lic.restore() } }.disabled(lic.busy)
                if lic.busy { ProgressView() }
                if let m = lic.message { Text(m).font(.footnote).foregroundColor(Ui.gold).multilineTextAlignment(.center) }
                Button(tr("Salvar uma cópia dos meus dados (backup)")) { shareURL = app.makeBackup() }
                    .buttonStyle(.bordered).padding(.top, 8)
                Text(tr("As atualizações chegam pela App Store, sem perder nada.")).font(.caption).foregroundColor(Ui.dim)
                LegalLinks()
            }
            .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
        }
        .sheet(item: $shareURL) { u in ShareSheet(items: [u]) }
    }
}

struct TrialChip: View {
    @EnvironmentObject var lic: LicenseManager
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            Text(tr("Teste · falta {0}", lic.leftLabel)).font(.caption).foregroundColor(Ui.gold)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.8)))
        }
        .sheet(isPresented: $open) {
            VStack(spacing: 14) {
                Text(tr("Versão de teste")).font(.title3.bold())
                Text(tr("Falta {0} de teste. Acesso completo: pagamento único{1}.", lic.leftLabel, lic.priceOf)).multilineTextAlignment(.center).foregroundColor(Ui.dim)
                Button { Task { await lic.buyFull() } } label: { Text(tr("Desbloquear agora")).frame(maxWidth: .infinity).padding(.vertical, 8) }
                    .buttonStyle(.borderedProminent)
                Button(tr("Já comprei · restaurar compra")) { Task { await lic.restore() } }
                if let m = lic.message { Text(m).font(.footnote).foregroundColor(Ui.gold) }
                LegalLinks()
            }
            .padding(24)
            .presentationDetents([.medium])
        }
    }
}

extension URL: Identifiable { public var id: String { absoluteString } }

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
