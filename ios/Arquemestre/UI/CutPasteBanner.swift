import SwiftUI

/// Aviso da 1ª abertura pra quem instalou pelo convite do plano de corte (WhatsApp → página → App Store).
/// Usa o botão "Colar" do próprio iOS: o app só lê o que está copiado quando a pessoa toca nele.
struct CutPasteBanner: View {
    @ObservedObject var app: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Recebeu um plano de corte pelo WhatsApp?")).font(.headline).foregroundColor(Ui.text)
            Text(tr("Toque em Colar pra abrir o projeto que mandaram pra você.")).font(.subheadline).foregroundColor(Ui.dim)
            HStack(spacing: 12) {
                PasteButton(payloadType: String.self) { items in
                    Task { @MainActor in app.pastedCut(items) }
                }
                .tint(Ui.accent)
                Button(tr("Agora não")) { app.cutPasteOffer = false }
                    .foregroundColor(Ui.dim)
            }
        }
        .padding(16)
        .frame(maxWidth: 520, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Ui.panel))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Ui.line))
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}
