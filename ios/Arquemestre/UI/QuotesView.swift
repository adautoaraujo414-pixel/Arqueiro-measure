import SwiftUI

private var dateFmt: DateFormatter { I18n.shared.dateFormatter(.date) }

struct QuotesView: View {
    @EnvironmentObject var app: AppModel
    @State private var editingId: String?
    @State private var companyOpen = false
    @State private var confirmDel: Quote?
    @State private var calcOpen = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { if editingId != nil { editingId = nil } else { app.leaveQuotes() } } label: {
                    Image(systemName: "chevron.backward").foregroundColor(Ui.text).frame(width: 40, height: 40)
                }
                Text(editingId == nil ? tr("Orçamentos") : tr("Orçamento")).font(.title3).foregroundColor(Ui.text)
                Spacer()
                Button { calcOpen = true } label: { Image(systemName: "plus.forwardslash.minus") }
                Button(tr("Dados da empresa")) { companyOpen = true }
            }.padding(8)
            if let id = editingId, let q = app.quotes.first(where: { $0.id == id }) {
                QuoteEditor(q: q)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        Button { var n = Quote(); n.city = app.company.city; app.saveQuote(n); editingId = n.id } label: {
                            Text(tr("+ Novo orçamento")).frame(maxWidth: .infinity).padding(.vertical, 8)
                        }.buttonStyle(.borderedProminent)
                        if app.company.name.isEmpty {
                            Text(tr("Dica: preencha os “Dados da empresa” uma vez e eles saem em todos os orçamentos.")).font(.footnote).foregroundColor(Ui.dim)
                        }
                        ForEach(app.quotes) { q in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(q.clientName.isEmpty ? tr("(sem cliente)") : q.clientName).foregroundColor(Ui.text)
                                    Text(dateFmt.string(from: Date(timeIntervalSince1970: Double(q.dateMs) / 1000)) + (q.city.isEmpty ? "" : " · \(q.city)")).font(.caption).foregroundColor(Ui.dim)
                                }
                                Spacer()
                                Text(QuoteMath.brl(QuoteMath.grandTotal(q))).foregroundColor(Ui.text)
                                Button { confirmDel = q } label: { Image(systemName: "trash").foregroundColor(Ui.dim) }.buttonStyle(.borderless)
                            }
                            .padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Ui.panel))
                            .contentShape(Rectangle())
                            .onTapGesture { editingId = q.id }
                        }
                    }.padding(.horizontal, 16).padding(.bottom, 24)
                }
            }
        }
        .background(Ui.bg)
        .onAppear { if let id = app.pendingQuoteId { editingId = id; app.pendingQuoteId = nil } }
        .sheet(isPresented: $companyOpen) { CompanySheet(c: app.company) }
        .sheet(isPresented: $calcOpen) { CalcSheet() }
        .alert(tr("Apagar orçamento?"), isPresented: Binding(get: { confirmDel != nil }, set: { if !$0 { confirmDel = nil } })) {
            Button(tr("Cancelar"), role: .cancel) {}
            Button(tr("Apagar"), role: .destructive) { if let d = confirmDel { app.deleteQuote(d.id) } }
        } message: { Text(tr("Apagar o orçamento de {0}?", confirmDel?.clientName.isEmpty == false ? confirmDel!.clientName : tr("(sem cliente)"))) }
    }
}

/// Calculadora com o teclado do app.
struct CalcSheet: View {
    @State private var t = ""
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Calculadora")).font(.headline)
            AppNumPad(text: $t, allowOps: true)
            if let v = Calc.eval(t) { Text("= " + Calc.format(v)).font(.title3) }
        }
        .padding(18)
        .presentationDetents([.height(460)])
    }
}

/// Dados da empresa e logo (também em Ajustes, na tela inicial).
struct CompanySheet: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var c: Company
    @State private var pickLogo = false
    var body: some View {
        NavigationStack {
            Form {
                Section(tr("Logo (sai no topo do orçamento)")) {
                    HStack {
                        ZStack {
                            Color.white
                            if let l = app.logo { Image(uiImage: l).resizable().scaledToFit().padding(4) } else { Text(tr("sem logo")).font(.caption).foregroundColor(.gray) }
                        }.frame(width: 96, height: 64).clipShape(RoundedRectangle(cornerRadius: 8))
                        VStack(alignment: .leading) {
                            Button(app.logo == nil ? tr("Carregar logo") : tr("Trocar logo")) { pickLogo = true }
                            if app.logo != nil { Button(tr("Remover"), role: .destructive) { app.clearLogo() } }
                        }.buttonStyle(.borderless)
                    }
                }
                Section {
                    TextField(tr("Nome da empresa"), text: $c.name)
                    TextField(tr("CNPJ"), text: $c.cnpj)
                    TextField(tr("Endereço"), text: $c.address)
                    TextField(tr("Cidade"), text: $c.city)
                    TextField(tr("Telefone / WhatsApp"), text: $c.phone).keyboardType(.phonePad)
                }
            }
            .navigationTitle(tr("Dados da empresa")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(tr("Cancelar")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(tr("Salvar")) {
                        app.saveCompany(Company(name: c.name.trimmingCharacters(in: .whitespaces), cnpj: c.cnpj.trimmingCharacters(in: .whitespaces),
                                                address: c.address.trimmingCharacters(in: .whitespaces), city: c.city.trimmingCharacters(in: .whitespaces),
                                                phone: c.phone.trimmingCharacters(in: .whitespaces)))
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $pickLogo) {
                PhotoPicker(limit: 1) { list in if let d = list.first?.0, let img = UIImage(data: d) { app.setLogo(img) } }.ignoresSafeArea()
            }
        }
    }
}

private struct QuoteEditor: View {
    @EnvironmentObject var app: AppModel
    var q: Quote
    @State private var shareURL: URL?
    @State private var projMenu = false
    @State private var projList: [MoveisProjects.P] = []

    private func upd(_ f: (inout Quote) -> Void) { var n = q; f(&n); app.saveQuote(n) }

    /// Fotos do orçamento lado a lado, cada uma com o ✕ pra tirar da lista.
    @ViewBuilder private var photoStrip: some View {
        if !q.photos.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(q.photos, id: \.self) { name in photoCell(name) }
                }
            }
        }
    }

    private func photoCell(_ name: String) -> some View {
        ZStack(alignment: .topTrailing) {
            QuotePhotoThumb(url: app.quotePhotoFile(name))
            Button { app.removeQuotePhoto(q, name) } label: {
                Text("✕").font(.subheadline).foregroundColor(.white)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
            }
            .buttonStyle(.borderless).padding(4)
        }
        .frame(width: 150, height: 100).clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Um aditivo: descrição, valor e a data em que entrou.
    private func addendumRow(_ idx: Int, _ a: QuoteAddendum) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                TextField(tr("Descrição do aditivo {0}", idx + 1), text: Binding(get: { a.desc }, set: { v in upd { qq in if let k = qq.addenda.firstIndex(where: { $0.id == a.id }) { qq.addenda[k].desc = v } } }), axis: .vertical)
                Button { upd { qq in qq.addenda.removeAll { $0.id == a.id } } } label: { Image(systemName: "trash") }.buttonStyle(.borderless)
            }
            NumPadField(value: a.value == 0 ? "" : QuoteMath.numStr(a.value), label: tr("Valor do aditivo ({0})", I18n.shared.currencySymbol())) { v in upd { qq in if let k = qq.addenda.firstIndex(where: { $0.id == a.id }) { qq.addenda[k].value = v } } }
            Text(tr("Data do aditivo: ") + dateFmt.string(from: Date(timeIntervalSince1970: Double(a.dateMs) / 1000))).font(.footnote).foregroundColor(.secondary)
        }
    }

    var body: some View {
        let notes = app.index.notes.filter { !$0.trash }
        Form {
            Section {
                TextField(tr("Nome do cliente"), text: Binding(get: { q.clientName }, set: { v in upd { $0.clientName = v } }))
                TextField(tr("Cidade"), text: Binding(get: { q.city }, set: { v in upd { $0.city = v } }))
                DatePicker(tr("Data"), selection: Binding(get: { Date(timeIntervalSince1970: Double(q.dateMs) / 1000) }, set: { d in upd { $0.dateMs = Int64(d.timeIntervalSince1970 * 1000) } }), displayedComponents: .date)
                    .environment(\.locale, I18n.shared.locale)
            }
            Section(tr("Itens")) {
                ForEach(Array(q.items.enumerated()), id: \.element.id) { idx, it in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            TextField(tr("Descrição do item {0}", idx + 1), text: Binding(get: { it.desc }, set: { v in upd { qq in if let k = qq.items.firstIndex(where: { $0.id == it.id }) { qq.items[k].desc = v } } }), axis: .vertical)
                            Button { upd { qq in qq.items.removeAll { $0.id == it.id }; if qq.items.isEmpty { qq.items = [QuoteItem()] } } } label: { Image(systemName: "trash") }.buttonStyle(.borderless)
                        }
                        HStack(spacing: 6) {
                            NumPadField(value: it.qty == 0 ? "" : QuoteMath.numStr(it.qty), label: tr("Qtd")) { v in upd { qq in if let k = qq.items.firstIndex(where: { $0.id == it.id }) { qq.items[k].qty = v } } }
                            TextField(tr("Un."), text: Binding(get: { it.unit }, set: { v in upd { qq in if let k = qq.items.firstIndex(where: { $0.id == it.id }) { qq.items[k].unit = v } } })).frame(width: 60)
                            NumPadField(value: it.unitValue == 0 ? "" : QuoteMath.numStr(it.unitValue), label: tr("Valor unit. ({0})", I18n.shared.currencySymbol())) { v in upd { qq in if let k = qq.items.firstIndex(where: { $0.id == it.id }) { qq.items[k].unitValue = v } } }
                        }
                        Text(tr("Subtotal: ") + QuoteMath.brl(QuoteMath.lineTotal(it))).font(.footnote).foregroundColor(.secondary)
                    }
                }
                Button(tr("+ Adicionar item")) { upd { $0.items.append(QuoteItem()) } }
            }
            Section {
                NumPadField(value: q.discountPct == 0 ? "" : QuoteMath.numStr(q.discountPct), label: tr("Desconto (%)")) { v in upd { $0.discountPct = clamp(v, 0, 100) } }
                Text(tr("Valor original: ") + QuoteMath.brl(QuoteMath.original(q)))
                if q.discountPct > 0 {
                    Text(tr("Desconto: − ") + QuoteMath.brl(QuoteMath.discountValue(q))).foregroundColor(.secondary)
                    Text(tr("Valor com desconto: ") + QuoteMath.brl(QuoteMath.finalValue(q))).font(.headline)
                }
                Text(tr("Validade da proposta: {0} dias", q.validityDays)).font(.footnote).foregroundColor(.secondary)
            }
            Section {
                TextField(tr("Observações (opcional)"), text: Binding(get: { q.notes }, set: { v in upd { $0.notes = v } }), axis: .vertical)
            }
            // fotos do projeto: tiradas no 3D do projeto (ou da galeria), saem no PDF
            Section {
                photoStrip
                Button(tr("📷 Adicionar fotos do projeto")) {
                    // orçamento que já nasceu de um projeto abre direto nele; senão, a pessoa escolhe o projeto
                    let ps = app.moveisProjects()
                    if let pid = q.projId, ps.contains(where: { $0.id == pid }) { app.addQuotePhotos(q, pid) } else { projList = ps; projMenu = true }
                }
                .confirmationDialog(tr("📷 Adicionar fotos do projeto"), isPresented: $projMenu, titleVisibility: .visible) {
                    ForEach(projList) { p in
                        Button((p.name.isEmpty ? tr("(sem cliente)") : p.name) + " · " + p.label) { app.addQuotePhotos(q, p.id) }
                    }
                    Button(tr("Cancelar"), role: .cancel) {}
                } message: {
                    if projList.isEmpty { Text(tr("Nenhum projeto de móveis ainda")) }
                }
            } header: {
                Text(tr("Fotos do projeto"))
            } footer: {
                Text(tr("Abre o projeto no 3D com o botão da câmera. Tire as fotos, toque em OK e elas voltam pra cá. O ✕ tira a foto do orçamento."))
            }
            // aditivos: itens que entram depois do orçamento fechado, sem mexer no original
            Section {
                ForEach(Array(q.addenda.enumerated()), id: \.element.id) { idx, a in addendumRow(idx, a) }
                Button(tr("+ Adicionar aditivo")) { upd { $0.addenda.append(QuoteAddendum()) } }
                if !q.addenda.isEmpty {
                    Text(tr("Orçamento: ") + QuoteMath.brl(QuoteMath.finalValue(q))).foregroundColor(.secondary)
                    Text(tr("Aditivos: ") + QuoteMath.brl(QuoteMath.addendaTotal(q))).foregroundColor(.secondary)
                    Text(tr("Total com aditivos: ") + QuoteMath.brl(QuoteMath.grandTotal(q))).font(.headline)
                }
            } header: {
                Text(tr("Aditivos"))
            } footer: {
                Text(tr("Item a mais combinado depois do orçamento fechado. O orçamento original não muda; o aditivo sai separado no PDF, com a data."))
            }
            Section {
                Toggle(tr("Incluir o desenho (nota) no PDF"), isOn: Binding(get: { q.includeDrawing }, set: { v in upd { $0.includeDrawing = v } }))
                if q.includeDrawing {
                    Picker(tr("Nota do desenho"), selection: Binding(get: { q.noteId ?? "" }, set: { v in upd { $0.noteId = v.isEmpty ? nil : v } })) {
                        Text(tr("Escolher…")).tag("")
                        ForEach(notes) { n in Text(n.name).tag(n.id) }
                    }
                }
            }
            Section {
                Button {
                    if q.includeDrawing && q.noteId == nil { app.toast = tr("Escolha a nota do desenho"); return }
                    shareURL = app.buildQuotePdf(q)
                } label: { Text(tr("Gerar PDF e enviar")).frame(maxWidth: .infinity) }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
    }
}

/// Miniatura de uma foto do orçamento (lida do arquivo uma vez só).
private struct QuotePhotoThumb: View {
    let url: URL
    @State private var img: UIImage?
    var body: some View {
        ZStack {
            Ui.panel
            if let i = img { Image(uiImage: i).resizable().scaledToFill() }
        }
        .frame(width: 150, height: 100).clipped()
        .onAppear { if img == nil { img = UIImage(contentsOfFile: url.path) } }
    }
}
