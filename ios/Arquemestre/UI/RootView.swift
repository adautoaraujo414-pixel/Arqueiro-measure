import SwiftUI
import StoreKit

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

/// Antes de usar: tela da assinatura com o teste grátis (prazo, preço depois do teste e como cancelar), como a Apple pede.
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
                    if lic.trialDays > 0 { Label(tr("{0} dias grátis com tudo liberado.", lic.trialDays), systemImage: "gift") }
                    Label(lic.price.isEmpty ? tr("Assinatura mensal pela App Store.") : tr("Depois, {0} por mês, renovado automaticamente pela App Store.", lic.price), systemImage: "creditcard")
                    Label(tr("Cancele quando quiser em Ajustes › seu nome › Assinaturas. Cancelando até 24 h antes do fim do teste, nada é cobrado."), systemImage: "xmark.circle")
                    Label(tr("Sem assinatura ativa, as telas ficam bloqueadas, mas seus dados continuam guardados e dá para fazer backup."), systemImage: "lock")
                }
                .font(.subheadline).foregroundColor(Ui.dim)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16).background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))

                SubscribeBox()
            }
            .padding(20).frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

/// Preço em destaque, botão de assinar, restaurar, gerenciar e o texto da renovação automática (regra 3.1.2 da Apple).
struct SubscribeBox: View {
    @EnvironmentObject var lic: LicenseManager
    @State private var manage = false

    var body: some View {
        VStack(spacing: 12) {
            Text(lic.price.isEmpty ? tr("Carregando o preço…") : tr("{0} por mês", lic.price))
                .font(.title2.bold()).foregroundColor(.white)
            if lic.trialDays > 0 && !lic.price.isEmpty {
                Text(tr("{0} dias grátis, depois {1} por mês.", lic.trialDays, lic.price)).font(.subheadline).foregroundColor(Ui.gold)
            }
            Button { Task { await lic.subscribe() } } label: {
                Text(lic.trialDays > 0 ? tr("Começar {0} dias grátis", lic.trialDays) : tr("Assinar"))
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent).tint(Ui.accent).disabled(lic.busy || lic.price.isEmpty)

            Button(tr("Já assino · restaurar compras")) { Task { await lic.restore() } }.disabled(lic.busy)
            Button(tr("Gerenciar assinatura")) { manage = true }.font(.footnote)

            if lic.busy { ProgressView() }
            if let m = lic.message { Text(m).font(.footnote).foregroundColor(Ui.gold).multilineTextAlignment(.center) }
            SubscriptionTerms()
            LegalLinks()
        }
        .manageSubscriptionsSheet(isPresented: $manage)
    }
}

/// Texto obrigatório da renovação automática.
struct SubscriptionTerms: View {
    @EnvironmentObject var lic: LicenseManager
    var body: some View {
        Text(tr("Arquemestre Mensal: assinatura de 1 mês com renovação automática por {0}. O pagamento é cobrado na sua conta Apple ao confirmar (ou no fim do teste grátis). A assinatura renova sozinha, a menos que seja cancelada pelo menos 24 horas antes do fim do período atual. Gerencie ou cancele em Ajustes › seu nome › Assinaturas.", lic.price.isEmpty ? "—" : lic.price))
            .font(.caption2).foregroundColor(Ui.dim).multilineTextAlignment(.center)
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

/// Assinatura terminou: bloqueia, mas os dados ficam e dá para fazer backup.
struct LockView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var lic: LicenseManager
    @State private var shareURL: URL?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("ARQUEMESTRE").font(.system(size: 26, weight: .bold)).foregroundColor(Ui.gold).padding(.top, 50)
                Text(tr("Sua assinatura terminou")).font(.title3.bold()).foregroundColor(.white).multilineTextAlignment(.center)
                Text(tr("Seus dados continuam guardados no aparelho. Assine de novo pra continuar usando."))
                    .foregroundColor(Ui.dim).multilineTextAlignment(.center)
                SubscribeBox()
                Button(tr("Salvar uma cópia dos meus dados (backup)")) { shareURL = app.makeBackup() }
                    .buttonStyle(.bordered).padding(.top, 8)
            }
            .padding(24).frame(maxWidth: 480).frame(maxWidth: .infinity)
        }
        .sheet(item: $shareURL) { u in ShareSheet(items: [u]) }
    }
}

/// No teste grátis: quanto falta e quanto custa depois.
struct TrialChip: View {
    @EnvironmentObject var lic: LicenseManager
    @State private var open = false
    @State private var manage = false
    var body: some View {
        Button { open = true } label: {
            Text(tr("Teste grátis · falta {0}", lic.leftLabel)).font(.caption).foregroundColor(Ui.gold)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.8)))
        }
        .sheet(isPresented: $open) {
            VStack(spacing: 14) {
                Text(tr("Teste grátis")).font(.title3.bold())
                Text(tr("Falta {0} de teste grátis. Depois, {1} por mês, renovado automaticamente. Pra não ser cobrado, cancele até 24 h antes do fim do teste.", lic.leftLabel, lic.price.isEmpty ? "—" : lic.price))
                    .multilineTextAlignment(.center).foregroundColor(Ui.dim)
                Button(tr("Gerenciar assinatura")) { manage = true }.buttonStyle(.bordered)
                LegalLinks()
            }
            .padding(24)
            .presentationDetents([.medium])
            .manageSubscriptionsSheet(isPresented: $manage)
        }
    }
}

extension URL: Identifiable { public var id: String { absoluteString } }

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController { UIActivityViewController(activityItems: items, applicationActivities: nil) }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
