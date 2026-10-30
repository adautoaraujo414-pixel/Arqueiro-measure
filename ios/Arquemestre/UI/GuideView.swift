import SwiftUI

/// Guia passo a passo (primeira vez e no menu): do primeiro cliente até o corte e o orçamento.
/// Os textos são os mesmos do Android (português é a chave da tradução).
let GUIDE: [(String, String)] = [
    ("1 · Crie a nota do cliente", "Toque em ＋ Criar nota e dê o nome do cliente. Tire foto do ambiente ou desenhe o croqui com o dedo ou a caneta."),
    ("2 · Meça com a trena", "Ligue a trena Bosch (botão Trena) e toque na cota: a medida cai direto, em milímetro. Sem trena, digite no teclado do app."),
    ("3 · Abra o projeto de móveis", "Na nota, toque em 🪚 Projeto: o projeto já nasce com o nome do cliente e fica ligado à nota, no mesmo quadro da biblioteca. Um cliente pode ter vários projetos (cozinha, suíte…)."),
    ("4 · Monte os módulos", "Toque em 📦 Módulos (tem lupa pra procurar), arraste no desenho e ajuste as medidas. Puxadores, tamponamentos, cuba e cooktop ficam no painel do lado."),
    ("5 · Veja em 3D", "Toque em 🧊: um dedo gira, dois dedos dão zoom, toque na porta pra abrir. ↶ desfaz. Em ⋯ Mais ficam as vistas, portas e janelas do ambiente."),
    ("6 · Corte e orçamento", "☰ mostra a lista e o plano de corte das chapas: toque na peça pra ver no 3D e 2 toques marca ✓ cortada. 💰 calcula material e preço e gera o orçamento em PDF."),
    ("7 · Agenda e backup", "Marque entregas e medições na Agenda. No menu ⋯ faça o backup completo (ZIP) de vez em quando. Fotos da câmera também ficam na galeria do iPhone."),
]

struct GuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text(tr("Guia passo a passo")).font(.headline).foregroundColor(Ui.text)
                Spacer()
                Button(tr("Pular")) { dismiss() }.foregroundColor(Ui.dim)
            }
            TabView(selection: $page) {
                ForEach(Array(GUIDE.enumerated()), id: \.offset) { i, g in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(tr(g.0)).font(.title2.bold()).foregroundColor(Ui.text)
                        Text(tr(g.1)).font(.body).foregroundColor(Ui.text).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(.top, 8).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            Button {
                if page < GUIDE.count - 1 { withAnimation { page += 1 } } else { dismiss() }
            } label: {
                Text(page < GUIDE.count - 1 ? tr("Próximo") : tr("Começar")).font(.headline).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Ui.accent))
            }
        }
        .padding(20)
        .background(Ui.bg.ignoresSafeArea())
    }
}
