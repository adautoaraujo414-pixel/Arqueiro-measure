import SwiftUI

private var ptBR: Locale { I18n.shared.locale }
private var fmtDay: DateFormatter { I18n.shared.dateFormatter(.day) }
private var fmtHour: DateFormatter { I18n.shared.dateFormatter(.hour) }
private var fmtDate: DateFormatter { I18n.shared.dateFormatter(.date) }
private var fmtMonth: DateFormatter { I18n.shared.dateFormatter(.month) }
private var cal: Calendar { var c = Calendar(identifier: .gregorian); c.locale = ptBR; return c }

private func capFirst(_ s: String) -> String { s.prefix(1).uppercased() + s.dropFirst() }
private func dayStart(_ d: Date) -> Date { cal.startOfDay(for: d) }

private func whenLabel(_ d: Date) -> String {
    let n = cal.dateComponents([.day], from: dayStart(Date()), to: dayStart(d)).day ?? 0
    switch n {
    case 0: return tr("Hoje")
    case 1: return tr("Amanhã")
    case -1: return tr("Ontem")
    default: return capFirst(fmtDay.string(from: d))
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
    @AppStorage("agenda.feriados") private var showFer = true
    @AppStorage("agenda.comemorativas") private var showCom = true

    var body: some View {
        let all = app.appointments
        let today = dayStart(Date())
        let shown: [Appointment] = {
            if let d = selDay { return all.filter { dayStart($0.startDate) == d } }
            if mode == 0 { return all.filter { !$0.done && $0.startDate >= today } }
            return all.filter { $0.done || $0.startDate < today }.sorted { $0.startMs > $1.startMs }
        }()
        ZStack(alignment: .bottomTrailing) {
        VStack(spacing: 0) {
            HStack {
                Button { app.screen = .library } label: { Image(systemName: "chevron.backward").foregroundColor(Ui.text).frame(width: 40, height: 40) }
                Text(tr("Agenda")).font(.title3).foregroundColor(Ui.text)
                Spacer()
                Button(tr("+ Novo")) {
                    let base = selDay.map { $0.addingTimeInterval(9 * 3600) } ?? Date().addingTimeInterval(3600)
                    var a = Appointment(); a.startDate = base
                    isNew = true; editing = a
                }.buttonStyle(.borderedProminent)
            }.padding(8)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    MonthGrid(month: $month, all: all, selDay: selDay, showFer: showFer, showCom: showCom) { d in selDay = selDay == d ? nil : d }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(tr("🇧🇷 Feriados"), showFer) { showFer.toggle() }
                            chip(tr("🎉 Datas comemorativas"), showCom) { showCom.toggle() }
                        }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(tr("Próximos"), selDay == nil && mode == 0) { selDay = nil; mode = 0 }
                            chip(tr("Concluídos / passados"), selDay == nil && mode == 1) { selDay = nil; mode = 1 }
                            if let d = selDay { chip(fmtDate.string(from: d) + "  ✕", true) { selDay = nil } }
                        }
                    }
                    if let d = selDay {
                        ForEach(Holidays.on(d, cal: cal, feriados: showFer, comemorativas: showCom)) { h in HolidayRow(h: h, withDate: false) }
                    } else if mode == 0 {
                        let nx = Holidays.upcoming(from: Date(), cal: cal, n: 3, feriados: showFer, comemorativas: showCom)
                        if !nx.isEmpty {
                            Text(tr("Próximos feriados e datas")).font(.footnote.bold()).foregroundColor(Ui.dim).padding(.top, 2)
                            ForEach(nx) { h in HolidayRow(h: h, withDate: true) }
                        }
                    }
                    if let d = selDay {
                        DayHours(day: d, list: shown, onNew: { t in var a = Appointment(); a.startDate = t; isNew = true; editing = a }, onEdit: { isNew = false; editing = $0 })
                    } else if shown.isEmpty {
                        Text(mode == 0 ? tr("Nenhum compromisso por vir. Toque em “+ Novo” pra marcar uma entrega ou visita.") : tr("Nada por aqui ainda."))
                            .font(.subheadline).foregroundColor(Ui.dim).padding(.vertical, 12)
                    } else {
                        ForEach(Array(shown.enumerated()), id: \.element.id) { i, a in
                            if i == 0 || dayStart(shown[i - 1].startDate) != dayStart(a.startDate) {
                                Text(whenLabel(a.startDate)).font(.footnote.bold()).foregroundColor(Ui.dim).padding(.top, 6)
                            }
                            ApptCard(a: a) { isNew = false; editing = a }
                        }
                    }
                }.padding(.horizontal, 16).padding(.bottom, 84)
            }
        }
            // botão "Adicionar em <dia>" (igual ao Google Agenda)
            let addDay = selDay ?? dayStart(Date())
            Button {
                var a = Appointment(); a.startDate = selDay.map { $0.addingTimeInterval(9 * 3600) } ?? Date().addingTimeInterval(3600)
                isNew = true; editing = a
            } label: {
                HStack(spacing: 10) {
                    Text(tr("Adicionar em") + " " + shortDay(addDay)).font(.body.weight(.medium))
                    Image(systemName: "plus").font(.title3.bold())
                }
                .foregroundColor(.white).padding(.horizontal, 20).padding(.vertical, 14)
                .background(Capsule().fill(Ui.accent)).shadow(radius: 4, y: 2)
            }.buttonStyle(.plain).padding(16)
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

private func shortDay(_ d: Date) -> String {
    let f = DateFormatter(); f.locale = ptBR; let lg = ptBR.language.languageCode?.identifier ?? "pt"; f.dateFormat = (lg == "pt" || lg == "es") ? "d 'de' MMM" : "MMM d"; return f.string(from: d)
}

/// Feriado / data comemorativa como faixa colorida (dia escolhido e próximos).
private struct HolidayRow: View {
    var h: Holidays.Day
    var withDate: Bool
    var body: some View {
        HStack {
            if withDate { Text(String(format: "%02d/%02d", h.day, h.month)).font(.footnote.bold()).frame(width: 50, alignment: .leading) }
            Text(tr(h.name)).font(.subheadline.weight(.medium))
            Spacer()
            Text(tr(h.kindLabel)).font(.caption2).opacity(0.85)
        }
        .foregroundColor(.white).padding(.horizontal, 12).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(h.color))
    }
}

/// Mês inteiro como no Google Agenda: cada dia com os nomes (feriado verde, compromissos na cor do tipo),
/// domingo e feriado em vermelho, hoje em destaque.
private struct MonthGrid: View {
    @Binding var month: Date
    var all: [Appointment]
    var selDay: Date?
    var showFer: Bool
    var showCom: Bool
    var onDay: (Date) -> Void
    var body: some View {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let ym = cal.dateComponents([.year, .month], from: first)
        let offset = cal.component(.weekday, from: first) - 1
        let days = cal.range(of: .day, in: .month, for: first)!.count
        let today = dayStart(Date())
        let thisMonth = cal.date(from: cal.dateComponents([.year, .month], from: today))!
        let byDay = Dictionary(grouping: all) { dayStart($0.startDate) }
        let rows = (offset + days + 6) / 7
        let red = Color(argb: 0xFFF28B82)
        VStack(spacing: 2) {
            HStack {
                Button { month = cal.date(byAdding: .month, value: -1, to: first)! } label: { Image(systemName: "chevron.left").frame(width: 36, height: 36) }
                Spacer()
                Text(capFirst(fmtMonth.string(from: first))).font(.headline).foregroundColor(Ui.text)
                Spacer()
                if first != thisMonth { Button(tr("Hoje")) { month = today }.font(.subheadline) }
                Button { month = cal.date(byAdding: .month, value: 1, to: first)! } label: { Image(systemName: "chevron.right").frame(width: 36, height: 36) }
            }.padding(.horizontal, 4).padding(.vertical, 4)
            HStack(spacing: 2) {
                ForEach(Array(tr("D S T Q Q S S").split(separator: " ").enumerated()), id: \.offset) { i, d in
                    Text(String(d)).font(.caption.bold()).foregroundColor(i == 0 ? red : Ui.dim).frame(maxWidth: .infinity)
                }
            }.padding(.bottom, 2)
            ForEach(0..<rows, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<7, id: \.self) { c in
                        let n = r * 7 + c - offset + 1
                        if n < 1 || n > days { Color.clear.frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78) } else {
                            let d = cal.date(byAdding: .day, value: n - 1, to: first)!
                            let hol = Holidays.on(ym.year!, ym.month!, n, feriados: showFer, comemorativas: showCom)
                            let list = (byDay[d] ?? []).sorted { $0.startMs < $1.startMs }
                            DayCell(n: n, hol: hol, list: list, isRed: c == 0 || hol.contains { $0.kind == .feriado }, isToday: d == today, sel: selDay == d, red: red) { onDay(d) }
                        }
                    }
                }
            }
        }
        .padding(8).background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
    }
}

/// Um dia da grade: número (vermelho no domingo/feriado, círculo em hoje) e até 2 nomes coloridos.
private struct DayCell: View {
    var n: Int
    var hol: [Holidays.Day]
    var list: [Appointment]
    var isRed: Bool
    var isToday: Bool
    var sel: Bool
    var red: Color
    var onTap: () -> Void
    private var chips: [(String, Color)] {
        var r: [(String, Color)] = hol.map { (tr($0.name), $0.color) }
        for a in list { r.append((a.title.isEmpty ? a.kind.label : a.title, a.kind.color)) }
        return r
    }
    var body: some View {
        let ch = chips
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(n)").font(.caption.bold())
                    .foregroundColor(isToday ? .white : (isRed ? red : Ui.text))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(isToday ? Ui.accent : Color.clear))
                ForEach(0..<min(2, ch.count), id: \.self) { i in
                    Text(ch[i].0).font(.system(size: 9)).lineLimit(2).foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 2).padding(.vertical, 1)
                        .background(RoundedRectangle(cornerRadius: 3).fill(ch[i].1))
                }
                if ch.count > 2 { Text("+\(ch.count - 2)").font(.system(size: 9)).foregroundColor(Ui.dim) }
                Spacer(minLength: 0)
            }
            .padding(2)
            .frame(maxWidth: .infinity, minHeight: 78, maxHeight: 78, alignment: .top)
            .background(RoundedRectangle(cornerRadius: 6).fill(sel ? Ui.accent.opacity(0.22) : Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(sel ? Ui.accent : Color.clear, lineWidth: 2))
            .contentShape(Rectangle())
        }.buttonStyle(.plain).frame(maxWidth: .infinity)
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
                        if inHour.isEmpty { Text(tr("livre · toque pra marcar")).font(.caption).foregroundColor(Color.white.opacity(0.33)).frame(maxWidth: .infinity, alignment: .leading) }
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
                    if let p = a.projectId { mini(tr("📐 Abrir projeto")) { app.openProject(p) } }
                    if let n = noteMeta { mini(tr("📝 Abrir nota")) { app.openNote(n.id) } }
                    if a.quoteId != nil { mini(tr("💲 Orçamento")) { app.screen = .quotes } }
                    if !a.clientPhone.isEmpty { mini(tr("💬 Avisar cliente")) { whatsApp() } }
                    mini(a.done ? tr("↩ Reabrir") : tr("✔ Concluir")) { var b = a; b.done.toggle(); app.saveAppt(b) }
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
        let who = a.clientName.split(separator: " ").first.map(String.init) ?? tr("tudo bem")
        var msg = tr("Olá, {0}! Passando pra confirmar {1} {2} ({3}) às {4}", who, a.kind.label.lowercased(), whenLabel(a.startDate).lowercased(), fmtDate.string(from: a.startDate), fmtHour.string(from: a.startDate))
        if !a.address.isEmpty { msg += tr(", em {0}", a.address) }
        msg += "."
        if !app.company.name.isEmpty { msg += " — \(app.company.name)" }
        var c = URLComponents(string: "https://wa.me/\(d)")!
        c.queryItems = [URLQueryItem(name: "text", value: msg)]
        if let u = c.url { UIApplication.shared.open(u) { ok in if !ok { Task { @MainActor in app.toast = tr("Não consegui abrir o WhatsApp") } } } }
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
                    TextField(tr("Título (ex.: Entrega da cozinha)"), text: $a.title)
                    DatePicker(tr("Data e hora"), selection: $a.startDate).environment(\.locale, ptBR)
                }
                Section(tr("Cliente")) {
                    TextField(tr("Nome do cliente (digite pra buscar)"), text: $a.clientName).onChange(of: a.clientName) { _ in showSug = true }
                    if showSug { ForEach(Array(sugg)) { c in Button((c.projectId != nil ? "📐 " : "💲 ") + c.name) { pick(c) } } }
                    if a.clientName.isEmpty && !clients.isEmpty {
                        Text(tr("Clientes salvos (toque pra puxar telefone, endereço e projeto):")).font(.caption).foregroundColor(.secondary)
                        ForEach(clients.prefix(12)) { c in Button((c.projectId != nil ? "📐 " : "💲 ") + c.name) { pick(c) } }
                    }
                    TextField(tr("Telefone / WhatsApp do cliente"), text: $a.clientPhone).keyboardType(.phonePad)
                    TextField(tr("Endereço do compromisso"), text: $a.address, axis: .vertical)
                }
                Section(tr("Vínculos")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(tr("📐 Projeto do cliente"))
                            Text(a.projectId != nil ? tr("Vinculado — abre direto no editor de móveis") : tr("Escolha o cliente salvo pra vincular o projeto")).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if let p = a.projectId {
                            Button(tr("Abrir")) { app.saveAppt(a); dismiss(); app.openProject(p) }.buttonStyle(.borderless)
                            Button(tr("Tirar")) { a.projectId = nil }.buttonStyle(.borderless)
                        }
                    }
                    Picker(tr("📝 Nota"), selection: Binding(get: { a.noteId ?? "" }, set: { a.noteId = $0.isEmpty ? nil : $0 })) {
                        Text(tr("Nenhuma")).tag("")
                        ForEach(notes) { n in Text(n.name).tag(n.id) }
                    }
                    if let nid = a.noteId { Button(tr("Abrir a nota")) { app.saveAppt(a); dismiss(); app.openNote(nid) } }
                    if !quotesOfClient.isEmpty {
                        Picker(tr("💲 Orçamento"), selection: Binding(get: { a.quoteId ?? "" }, set: { a.quoteId = $0.isEmpty ? nil : $0 })) {
                            Text(tr("Nenhum")).tag("")
                            ForEach(quotesOfClient) { q in Text(fmtDate.string(from: Date(timeIntervalSince1970: Double(q.dateMs) / 1000))).tag(q.id) }
                        }
                    }
                }
                Section(tr("Avisar (notificação neste aparelho)")) {
                    ForEach(REMIND_OPTIONS, id: \.0) { opt in
                        let m = opt.0
                        Toggle(opt.1, isOn: Binding(get: { a.remindMin.contains(m) }, set: { on in
                            if on { a.remindMin = (a.remindMin + [m]).sorted() } else { a.remindMin.removeAll { $0 == m } }
                        }))
                    }
                }
                Section(tr("Observações")) { TextField(tr("Observações"), text: $a.notes, axis: .vertical).lineLimit(3...8) }
                if !isNew { Section { Button(tr("Apagar compromisso"), role: .destructive) { confirmDel = true } } }
            }
            .navigationTitle(isNew ? tr("Novo compromisso") : tr("Compromisso")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button(tr("Salvar")) { a.title = a.title.trimmingCharacters(in: .whitespaces); app.saveAppt(a); dismiss() } }
            }
            .alert(tr("Apagar compromisso?"), isPresented: $confirmDel) {
                Button(tr("Cancelar"), role: .cancel) {}
                Button(tr("Apagar"), role: .destructive) { app.deleteAppt(a.id); dismiss() }
            } message: { Text(tr("Apagar “{0}”?", a.title.isEmpty ? a.kind.label : a.title)) }
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
