import SwiftUI

private let ptBR = Locale(identifier: "pt_BR")
private func fmt(_ p: String) -> DateFormatter { let f = DateFormatter(); f.locale = ptBR; f.dateFormat = p; return f }
private let fmtDay = fmt("EEEE, dd 'de' MMMM"), fmtHour = fmt("HH:mm"), fmtDate = fmt("dd/MM/yyyy"), fmtMonth = fmt("MMMM 'de' yyyy")
private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.locale = ptBR; return c }

private func dayStart(_ d: Date) -> Date { cal.startOfDay(for: d) }

private func whenLabel(_ d: Date) -> String {
    let n = cal.dateComponents([.day], from: dayStart(Date()), to: dayStart(d)).day ?? 0
    switch n {
    case 0: return "Hoje"
    case 1: return "Amanhã"
    case -1: return "Ontem"
    default: return fmtDay.string(from: d).capitalized(with: ptBR)
    }
}

/// Agenda: entregas, visitas, medições e instalações, com aviso e vínculo ao cliente.
struct AgendaView: View {
    @EnvironmentObject var app: AppModel
    @State private var editing: Appointment?
    @State private var isNew = false
    @State private var month = dayStart(Date())
    @State private var selDay: Date?
    @State private var mode = 0

    var body: some View {
        let all = app.appointments
        let today = dayStart(Date())
        let shown: [Appointment] = {
            if let d = selDay { return all.filter { dayStart($0.startDate) == d } }
            if mode == 0 { return all.filter { !$0.done && $0.startDate >= today } }
            return all.filter { $0.done || $0.startDate < today }.sorted { $0.startMs > $1.startMs }
        }()
        VStack(spacing: 0) {
            HStack {
                Button { app.screen = .library } label: { Image(systemName: "chevron.backward").foregroundColor(Ui.text).frame(width: 40, height: 40) }
                Text("Agenda").font(.title3).foregroundColor(Ui.text)
                Spacer()
                Button("+ Novo") {
                    let base = selDay.map { $0.addingTimeInterval(9 * 3600) } ?? Date().addingTimeInterval(3600)
                    var a = Appointment(); a.startDate = base
                    isNew = true; editing = a
                }.buttonStyle(.borderedProminent)
            }.padding(8)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    MonthGrid(month: $month, all: all, selDay: selDay) { d in selDay = selDay == d ? nil : d }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip("Próximos", selDay == nil && mode == 0) { selDay = nil; mode = 0 }
                            chip("Concluídos / passados", selDay == nil && mode == 1) { selDay = nil; mode = 1 }
                            if let d = selDay { chip(fmtDate.string(from: d) + "  ✕", true) { selDay = nil } }
                        }
                    }
                    if let d = selDay {
                        DayHours(day: d, list: shown, onNew: { t in var a = Appointment(); a.startDate = t; isNew = true; editing = a }, onEdit: { isNew = false; editing = $0 })
                    } else if shown.isEmpty {
                        Text(mode == 0 ? "Nenhum compromisso por vir. Toque em “+ Novo” pra marcar uma entrega ou visita." : "Nada por aqui ainda.")
                            .font(.subheadline).foregroundColor(Ui.dim).padding(.vertical, 12)
                    } else {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { i, a in
                            if i == 0 || dayStart(shown[i - 1].startDate) != dayStart(a.startDate) {
                                Text(whenLabel(a.startDate)).font(.footnote.bold()).foregroundColor(Ui.dim).padding(.top, 6)
                            }
                            ApptCard(a: a) { isNew = false; editing = a }
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 24)
            }
        }
        .background(Ui.bg)
        .sheet(item: $editing) { a in ApptEditor(initial: a, isNew: isNew) }
        .onAppear {
            if !AppModel.isDemo { Reminders.requestPermission() }
            if let id = app.agendaOpenId, let a = app.appointments.first(where: { $0.id == id }) { isNew = false; editing = a }
            app.agendaOpenId = nil
        }
        .onChange(of: app.agendaOpenId) { id in
            if let id = id, let a = app.appointments.first(where: { $0.id == id }) { isNew = false; editing = a; app.agendaOpenId = nil }
        }
    }

    private func chip(_ t: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.subheadline).foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(sel ? Ui.accent.opacity(0.6) : Ui.panel2))
        }.buttonStyle(.plain)
    }
}

private struct MonthGrid: View {
    @Binding var month: Date
    var all: [Appointment]
    var selDay: Date?
    var onDay: (Date) -> Void
    var body: some View {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let offset = cal.component(.weekday, from: first) - 1
        let days = cal.range(of: .day, in: .month, for: first)!.count
        let today = dayStart(Date())
        let byDay = Dictionary(grouping: all) { dayStart($0.startDate) }
        let rows = (offset + days + 6) / 7
        VStack(spacing: 2) {
            HStack {
                Button { month = cal.date(byAdding: .month, value: -1, to: first)! } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(fmtMonth.string(from: first).capitalized(with: ptBR)).foregroundColor(Ui.text)
                Spacer()
                Button { month = cal.date(byAdding: .month, value: 1, to: first)! } label: { Image(systemName: "chevron.right") }
            }.padding(.horizontal, 8).padding(.vertical, 6)
            HStack { ForEach(["D", "S", "T", "Q", "Q", "S", "S"].indices, id: \.self) { i in Text(["D", "S", "T", "Q", "Q", "S", "S"][i]).font(.caption).foregroundColor(Ui.dim).frame(maxWidth: .infinity) } }
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { c in
                        let n = r * 7 + c - offset + 1
                        if n < 1 || n > days { Color.clear.frame(maxWidth: .infinity).aspectRatio(1.25, contentMode: .fit) } else {
                            let d = cal.date(byAdding: .day, value: n - 1, to: first)!
                            let list = byDay[d] ?? []
                            Button { onDay(d) } label: {
                                VStack(spacing: 2) {
                                    Text("\(n)").foregroundColor(selDay == d ? .white : Ui.text)
                                    HStack(spacing: 2) { ForEach(list.prefix(3)) { a in Circle().fill(a.kind.color).frame(width: 5, height: 5) } }.frame(height: 6)
                                }
                                .frame(maxWidth: .infinity).aspectRatio(1.25, contentMode: .fit)
                                .background(RoundedRectangle(cornerRadius: 8).fill(selDay == d ? Ui.accent : (d == today ? Ui.panel2 : .clear)))
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .padding(10).background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
    }
}

private struct DayHours: View {
    var day: Date
    var list: [Appointment]
    var onNew: (Date) -> Void
    var onEdit: (Appointment) -> Void
    var body: some View {
        let hourOf = { (a: Appointment) in cal.component(.hour, from: a.startDate) }
        let first = min(6, list.map(hourOf).min() ?? 6), last = max(22, list.map(hourOf).max() ?? 22)
        let nowH = cal.component(.hour, from: Date())
        let isToday = dayStart(Date()) == day
        VStack(spacing: 2) {
            ForEach(first...last, id: \.self) { h in
                let inHour = list.filter { hourOf($0) == h }.sorted { $0.startMs < $1.startMs }
                let current = isToday && nowH == h
                HStack(alignment: .top) {
                    Text(String(format: "%02d:00", h)).font(.footnote.bold()).foregroundColor(current ? Color(argb: 0xFF7FB2FF) : Ui.dim).frame(width: 52, alignment: .leading)
                    VStack(spacing: 6) {
                        if inHour.isEmpty { Text("livre · toque pra marcar").font(.caption).foregroundColor(Color.white.opacity(0.33)).frame(maxWidth: .infinity, alignment: .leading) }
                        ForEach(inHour) { a in ApptCard(a: a) { onEdit(a) } }
                    }
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(current ? Color(argb: 0x223B82F6) : Color.white.opacity(0.06)))
                .contentShape(Rectangle())
                .onTapGesture { onNew(day.addingTimeInterval(Double(h) * 3600)) }
            }
        }
    }
}

private struct ApptCard: View {
    @EnvironmentObject var app: AppModel
    var a: Appointment
    var onEdit: () -> Void
    var body: some View {
        let noteMeta = a.noteId.flatMap { id in app.index.notes.first { $0.id == id } }
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                RoundedRectangle(cornerRadius: 2).fill(a.kind.color).frame(width: 4, height: 38)
                VStack(alignment: .leading) {
                    Text("\(a.kind.icon) \(a.title.isEmpty ? a.kind.label : a.title)").foregroundColor(a.done ? Ui.dim : Ui.text)
                    let sub = [a.clientName, a.address].filter { !$0.isEmpty }.joined(separator: " · ")
                    if !sub.isEmpty { Text(sub).font(.footnote).foregroundColor(Ui.dim) }
                }
                Spacer()
                Text(fmtHour.string(from: a.startDate)).font(.title3).foregroundColor(Ui.text)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let p = a.projectId { mini("📐 Abrir projeto") { app.openProject(p) } }
                    if let n = noteMeta { mini("📝 Abrir nota") { app.openNote(n.id) } }
                    if a.quoteId != nil { mini("💲 Orçamento") { app.screen = .quotes } }
                    if !a.clientPhone.isEmpty { mini("💬 Avisar cliente") { whatsApp() } }
                    mini(a.done ? "↩ Reabrir" : "✔ Concluir") { var b = a; b.done.toggle(); app.saveAppt(b) }
                }
            }
        }
        .padding(14).background(RoundedRectangle(cornerRadius: 12).fill(Ui.panel))
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    private func mini(_ t: String, _ act: @escaping () -> Void) -> some View {
        Button(action: act) { Text(t).font(.footnote).foregroundColor(Ui.text).padding(.horizontal, 12).padding(.vertical, 7).background(Capsule().fill(Ui.panel2)) }.buttonStyle(.plain)
    }

    private func whatsApp() {
        var d = a.clientPhone.filter(\.isNumber)
        if d.count == 10 || d.count == 11 { d = "55" + d }
        let who = a.clientName.split(separator: " ").first.map(String.init) ?? "tudo bem"
        var msg = "Olá, \(who)! Passando pra confirmar \(a.kind.label.lowercased()) \(whenLabel(a.startDate).lowercased()) (\(fmtDate.string(from: a.startDate))) às \(fmtHour.string(from: a.startDate))"
        if !a.address.isEmpty { msg += ", em \(a.address)" }
        msg += "."
        if !app.company.name.isEmpty { msg += " — \(app.company.name)" }
        var c = URLComponents(string: "https://wa.me/\(d)")!
        c.queryItems = [URLQueryItem(name: "text", value: msg)]
        if let u = c.url { UIApplication.shared.open(u) { ok in if !ok { Task { @MainActor in app.toast = "Não consegui abrir o WhatsApp" } } } }
    }
}

private struct ApptEditor: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var a: Appointment
    var isNew: Bool
    @State private var showSug = false
    @State private var confirmDel = false

    init(initial: Appointment, isNew: Bool) { _a = State(initialValue: initial); self.isNew = isNew }

    var body: some View {
        let clients = app.knownClients()
        let sugg = clients.filter { !a.clientName.isEmpty && $0.name.localizedCaseInsensitiveContains(a.clientName) && $0.name.caseInsensitiveCompare(a.clientName) != .orderedSame }.prefix(5)
        let quotesOfClient = app.quotes.filter { !a.clientName.isEmpty && $0.clientName.caseInsensitiveCompare(a.clientName) == .orderedSame }
        let notes = app.index.notes.filter { !$0.trash }
        NavigationStack {
            Form {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack { ForEach(ApptKind.allCases) { k in
                            Button("\(k.icon) \(k.label)") { a.kind = k }.buttonStyle(.bordered).tint(a.kind == k ? Ui.accent : .gray)
                        } }
                    }
                    TextField("Título (ex.: Entrega da cozinha)", text: $a.title)
                    DatePicker("Data e hora", selection: $a.startDate).environment(\.locale, ptBR)
                }
                Section("Cliente") {
                    TextField("Nome do cliente (digite pra buscar)", text: $a.clientName).onChange(of: a.clientName) { _ in showSug = true }
                    if showSug { ForEach(Array(sugg)) { c in Button((c.projectId != nil ? "📐 " : "💲 ") + c.name) { pick(c) } } }
                    if a.clientName.isEmpty && !clients.isEmpty {
                        Text("Clientes salvos (toque pra puxar telefone, endereço e projeto):").font(.caption).foregroundColor(.secondary)
                        ForEach(clients.prefix(12)) { c in Button((c.projectId != nil ? "📐 " : "💲 ") + c.name) { pick(c) } }
                    }
                    TextField("Telefone / WhatsApp do cliente", text: $a.clientPhone).keyboardType(.phonePad)
                    TextField("Endereço do compromisso", text: $a.address, axis: .vertical)
                }
                Section("Vínculos") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("📐 Projeto do cliente")
                            Text(a.projectId != nil ? "Vinculado — abre direto no editor de móveis" : "Escolha o cliente salvo pra vincular o projeto").font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if let p = a.projectId {
                            Button("Abrir") { app.saveAppt(a); dismiss(); app.openProject(p) }.buttonStyle(.borderless)
                            Button("Tirar") { a.projectId = nil }.buttonStyle(.borderless)
                        }
                    }
                    Picker("📝 Nota", selection: Binding(get: { a.noteId ?? "" }, set: { a.noteId = $0.isEmpty ? nil : $0 })) {
                        Text("Nenhuma").tag("")
                        ForEach(notes) { n in Text(n.name).tag(n.id) }
                    }
                    if let nid = a.noteId { Button("Abrir a nota") { app.saveAppt(a); dismiss(); app.openNote(nid) } }
                    if !quotesOfClient.isEmpty {
                        Picker("💲 Orçamento", selection: Binding(get: { a.quoteId ?? "" }, set: { a.quoteId = $0.isEmpty ? nil : $0 })) {
                            Text("Nenhum").tag("")
                            ForEach(quotesOfClient) { q in Text(fmtDate.string(from: Date(timeIntervalSince1970: Double(q.dateMs) / 1000))).tag(q.id) }
                        }
                    }
                }
                Section("Avisar (notificação neste aparelho)") {
                    ForEach(REMIND_OPTIONS, id: \.0) { opt in
                        let m = opt.0
                        Toggle(opt.1, isOn: Binding(get: { a.remindMin.contains(m) }, set: { on in
                            if on { a.remindMin = (a.remindMin + [m]).sorted() } else { a.remindMin.removeAll { $0 == m } }
                        }))
                    }
                }
                Section("Observações") { TextField("Observações", text: $a.notes, axis: .vertical).lineLimit(3...8) }
                if !isNew { Section { Button("Apagar compromisso", role: .destructive) { confirmDel = true } } }
            }
            .navigationTitle(isNew ? "Novo compromisso" : "Compromisso").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Salvar") { a.title = a.title.trimmingCharacters(in: .whitespaces); app.saveAppt(a); dismiss() } }
            }
            .alert("Apagar compromisso?", isPresented: $confirmDel) {
                Button("Cancelar", role: .cancel) {}
                Button("Apagar", role: .destructive) { app.deleteAppt(a.id); dismiss() }
            } message: { Text("Apagar “\(a.title.isEmpty ? a.kind.label : a.title)”?") }
        }
    }

    private func pick(_ c: ClientRef) {
        a.clientName = c.name
        if !c.phone.isEmpty { a.clientPhone = c.phone }
        if let p = c.projectId { a.projectId = p }
        if a.address.isEmpty { a.address = c.address }
        if let q = app.quotes.first(where: { $0.clientName.caseInsensitiveCompare(c.name) == .orderedSame }) { a.quoteId = q.id }
        showSug = false
    }
}
