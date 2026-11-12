import SwiftUI
import StoreKit
import UniformTypeIdentifiers

private var dateFmt: DateFormatter { I18n.shared.dateFormatter(.date) }
private func dateText(_ ms: Int64) -> String { dateFmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000)) }
/// Data do cartão do cliente (dd/MM/aaaa).
private var dmyFmt: DateFormatter { let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"; return f }
private func dmyText(_ ms: Int64) -> String { dmyFmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000)) }

/// Abas grandes da tela inicial: clientes (um cartão por cliente) ou projetos (lista corrida, mais recentes primeiro).
private enum HomeTab { case clientes, projetos }
/// Dentro de "Projetos": tudo, só as notas (atalho "Notas") ou só o Projetor 3D (aba de baixo).
private enum ProjMode { case all, notes, moveis }

/// O que a lista mostra (calculado uma vez por desenho).
fileprivate struct HomeData {
    var clients: [ClientGroup]
    var entries: [LibEntry]
}

/// Cliente aberto na folha de detalhes (pela chave do cliente).
struct ClientPick: Identifiable { let id: String }

/// Biblioteca (escura, destaque dourado): clientes, projetos (Projetor 3D), notas e pastas.
struct LibraryView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var lic: LicenseManager
    @State private var query = ""
    @State private var home: HomeTab = .clientes
    @State private var projMode: ProjMode = .all
    /// Filtro do funil: status do projeto (nil = todos).
    @State private var statusFilter: String?
    @State private var newFolder = false
    @State private var newClient = false
    @State private var clientOpen: ClientPick?
    @State private var shareURL: URL?
    @State private var restorePick = false
    @State private var confirmRestore: URL?
    @State private var peerView = false
    @State private var syncOpen = false
    @State private var langOpen = false
    @State private var manageSub = false
    @State private var toolsOpen = false
    @State private var settingsOpen = false
    @State private var companyOpen = false
    @State private var btOpen = false

    /// Altura da barra de abas de baixo (só no iPhone).
    static let tabBarHeight: CGFloat = 58
    /// A partir desta largura a biblioteca usa a barra lateral (iPad) em vez da barra de abas.
    static let wideMinWidth: CGFloat = 700

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    private var sortedFolders: [Folder] { app.index.folders.sorted { nameLess($0.name, $1.name) } }
    private var langLabel: String { langMenuLabel() + " (" + currentLangName() + ")" }
    /// Compromisso não concluído nas próximas 24 h (bolinha no sino).
    private var hasSoonAppt: Bool {
        let now = nowMs()
        return app.appointments.contains { !$0.done && $0.startMs >= now && $0.startMs <= now + 86_400_000 }
    }
    /// Mesma regra do selo do teste grátis: teste, renovação desligada ou cobrança com problema.
    private var showTrial: Bool { lic.hasAccess && (lic.status == .trial || !lic.willRenew || lic.inGrace) }

    var body: some View {
        dialogs(sheets(layout))
    }

    private var layout: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= LibraryView.wideMinWidth
            HStack(spacing: 0) {
                if wide { sidebar.frame(width: 230).background(Ui.panel) }
                content(wide: wide)
            }
        }
        .background(Ui.bg.ignoresSafeArea())
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func sheets<V: View>(_ v: V) -> some View {
        v
        .sheet(isPresented: $newFolder) { NameSheet(title: tr("Nova pasta"), label: tr("Nome da pasta"), text: "") { app.addFolder($0) } }
        // nota nova: pergunta o nome antes de criar (cada nota com o seu nome)
        .sheet(item: $app.noteAsk) { a in
            NameSheet(title: tr("Nova nota"), label: tr("Nome da nota"), text: app.suggestedNoteName(project: a.project)) { name in
                let id = app.createNamedNote(name, project: a.project)
                // abre depois que a janelinha do nome fecha
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    if !a.kind.isEmpty { app.pendingImport = a.kind }
                    app.openNote(id)
                }
            }
        }
        // cliente novo: pergunta o nome e abre o Projetor 3D já no nome dele
        .sheet(isPresented: $newClient) {
            NameSheet(title: tr("Novo cliente"), label: tr("Nome do cliente"), text: "") { name in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { app.newProjectForClient(name, nil) }
            }
        }
        .sheet(item: $clientOpen) { c in ClientDetailSheet(key: c.id) }
        // voltou do editor (Pronto/Fechar): abre a tela do cliente daquele projeto, com os projetos e as notas dele
        .onAppear {
            guard let pid = app.returnProjectId else { return }
            app.returnProjectId = nil
            let g = homeClients(app, app.moveisProjects(), app.index.notes.filter { !$0.trash }).groups.first { $0.projs.contains { $0.id == pid } }
            if let g { DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { clientOpen = ClientPick(id: g.id) } }
        }
        .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
        .sheet(isPresented: $peerView) { PeerViewPicker() }
        .sheet(isPresented: $syncOpen) { SyncView().environmentObject(app) }
        .sheet(isPresented: $langOpen) { LanguagePicker() }
        .sheet(isPresented: $btOpen) { BluetoothView() }
        .sheet(isPresented: $companyOpen) { CompanySheet(c: app.company) }
        .sheet(isPresented: $toolsOpen) { HomeMenuSheet(title: tr("Ferramentas"), items: toolsItems) }
        .sheet(isPresented: $settingsOpen) { HomeMenuSheet(title: tr("Ajustes"), items: settingsItems) }
    }

    private func dialogs<V: View>(_ v: V) -> some View {
        v
        .manageSubscriptionsSheet(isPresented: $manageSub)
        // nota e projeto ligados ao mesmo cliente ficam com o mesmo nome
        .onAppear { app.syncLinkedNames() }
        .onChange(of: app.projVersion) { _ in app.syncLinkedNames() }
        .onChange(of: app.index.notes.map(\.name)) { _ in app.syncLinkedNames() }
        .fileImporter(isPresented: $restorePick, allowedContentTypes: [.zip, .data]) { r in if case .success(let u) = r { confirmRestore = u } }
        .alert(tr("Restaurar backup?"), isPresented: Binding(get: { confirmRestore != nil }, set: { if !$0 { confirmRestore = nil } })) {
            Button(tr("Cancelar"), role: .cancel) { confirmRestore = nil }
            Button(tr("Restaurar"), role: .destructive) { if let u = confirmRestore { app.restore(from: u) }; confirmRestore = nil }
        } message: { Text(tr("Isto substitui os dados atuais (notas, agenda, orçamentos, móveis) pelos do backup. Vale backup feito em qualquer aparelho com o Arquemestre.")) }
    }

    // ---------------- Barra lateral (iPad) ----------------

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARQUEMESTRE").font(.subheadline.bold()).foregroundColor(Ui.text).padding(8)
                side(tr("Todas as notas"), "tray.full", app.filter == .all) { app.filter = .all }
                Text(tr("Pastas")).font(.caption).foregroundColor(Ui.dim).padding(.leading, 8).padding(.top, 12)
                ForEach(sortedFolders) { f in side(f.name, "folder", app.filter == .folder(f.id)) { app.filter = .folder(f.id) } }
                side(tr("Nova pasta"), "folder.badge.plus", false) { newFolder = true }
                Divider().padding(.vertical, 8)
                side(tr("Novo Projetor 3D"), "cube", false) { app.newMoveisProject() }
                side(tr("Agenda"), "calendar", false) { app.screen = .agenda }
                side(tr("Orçamentos"), "doc.text", false) { app.screen = .quotes }
                side(tr("Trena Bosch"), "ruler", false) { btOpen = true }
                side(tr("Lixo"), "trash", app.filter == .trash) { app.filter = .trash }
            }.padding(12)
        }
    }

    private func side(_ label: String, _ icon: String, _ sel: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(sel ? Color.white : Ui.dim).frame(width: 20)
                Text(label).foregroundColor(Ui.text).lineLimit(1)
                Spacer()
            }
            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(sel ? Ui.panel2 : .clear))
        }.buttonStyle(.plain)
    }

    // ---------------- Conteúdo ----------------

    private func content(wide: Bool) -> some View {
        let d = homeData()
        return VStack(spacing: 0) {
            header
            segmented.padding(.top, 14)
            searchRow.padding(.top, 14)
            ScrollView { listBody(d) }
                .scrollDismissesKeyboard(.interactively)
            bottomBlock
            if !wide { tabBar }
        }
    }

    private func homeData() -> HomeData {
        _ = app.projVersion
        let projAll = app.moveisProjects()
        // o projeto fica na mesma pasta que a nota do cliente
        let projFolder = app.projectFolders(projAll)
        let q = query.trimmingCharacters(in: .whitespaces)
        if home == .projetos || app.filter == .trash {
            return HomeData(clients: [], entries: flatEntries(projAll, projFolder, q))
        }
        let projs = projAll.filter { projInScope($0, projFolder) }
        let notes = app.index.notes.filter { noteInScope($0) }
        let groups = homeClients(app, projs, notes).groups
        let shown = groups.filter { g in
            (q.isEmpty || g.matches(q)) && (statusFilter == nil || g.projs.contains { $0.status == statusFilter })
        }
        let sorted = shown.sorted { a, b in a.lastDate != b.lastDate ? a.lastDate > b.lastDate : nameLess(a.name, b.name) }
        return HomeData(clients: sorted, entries: [])
    }

    /// Aba Clientes: quem está numa pasta só aparece na pasta (na busca aparece tudo).
    private func projInScope(_ p: MoveisProjects.P, _ projFolder: [String: String]) -> Bool {
        switch app.filter {
        case .all: return searching || projFolder[p.id] == nil
        case .folder(let f): return projFolder[p.id] == f
        case .trash: return false
        }
    }

    private func noteInScope(_ n: NoteMeta) -> Bool {
        switch app.filter {
        case .all: return !n.trash && (searching || app.liveFolder(n.folderId) == nil)
        case .trash: return n.trash
        case .folder(let f): return !n.trash && n.folderId == f
        }
    }

    /// Aba Projetos: todos os projetos e notas (também os que estão em pastas), mais recentes primeiro.
    private func flatEntries(_ projAll: [MoveisProjects.P], _ projFolder: [String: String], _ q: String) -> [LibEntry] {
        var out: [LibEntry] = []
        let trash = app.filter == .trash
        if !trash && projMode != .notes {
            for p in projAll where projShown(p, projFolder, q) { out.append(LibEntry.p(p)) }
        }
        if trash || projMode != .moveis {
            let statusOf = Dictionary(projAll.map { ($0.id, $0.status) }, uniquingKeysWith: { a, _ in a })
            for n in app.index.notes where noteShown(n, q, statusOf) { out.append(LibEntry.n(n)) }
        }
        return out.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            if a.date != b.date { return a.date > b.date }
            return nameLess(a.name, b.name)
        }
    }

    private func projShown(_ p: MoveisProjects.P, _ projFolder: [String: String], _ q: String) -> Bool {
        if case .folder(let f) = app.filter, projFolder[p.id] != f { return false }
        if let s = statusFilter, p.status != s { return false }
        return q.isEmpty || projMatches(p, q)
    }

    /// Com o filtro de status, a nota entra quando o projeto ligado a ela está naquele status.
    private func noteShown(_ n: NoteMeta, _ q: String, _ statusOf: [String: String]) -> Bool {
        switch app.filter {
        case .all: if n.trash { return false }
        case .trash: if !n.trash { return false }
        case .folder(let f): if n.trash || n.folderId != f { return false }
        }
        if let s = statusFilter, app.filter != .trash {
            guard let pid = app.linkedProject(n.id), statusOf[pid] == s else { return false }
        }
        return q.isEmpty || n.name.localizedCaseInsensitiveContains(q)
    }

    // ---------------- Cabeçalho ----------------

    private var header: some View {
        HStack(spacing: 12) {
            logoMark
            VStack(alignment: .leading, spacing: 2) {
                Text("ARQUEMESTRE").font(.system(size: 20, weight: .heavy)).foregroundColor(Ui.text).lineLimit(1).minimumScaleFactor(0.7)
                Text(tr("Gestão de Projetos para Marcenaria")).font(.caption).foregroundColor(Ui.dim).lineLimit(1).minimumScaleFactor(0.75)
            }
            Spacer(minLength: 6)
            Button { app.screen = .agenda } label: { bellIcon }
                .buttonStyle(.plain).accessibilityLabel(tr("Agenda"))
            Button { settingsOpen = true } label: { circleIcon("person") }
                .buttonStyle(.plain).accessibilityLabel(tr("Ajustes"))
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var logoMark: some View {
        Image("LogoArque").resizable().scaledToFill()
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 17, weight: .semibold)).foregroundColor(Ui.text)
            .frame(width: 44, height: 44)
            .background(Circle().fill(Ui.panel2))
    }

    private var bellIcon: some View {
        circleIcon("bell").overlay(alignment: .topTrailing) {
            if hasSoonAppt {
                Circle().fill(Color.white).frame(width: 10, height: 10).offset(x: -8, y: 8)
            }
        }
    }

    // ---------------- Clientes / Projetos ----------------

    private var segmented: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                segPill(tr("Clientes"), "person", home == .clientes) { selectHome(.clientes) }
                segPill(tr("Projetos"), "square.stack.3d.up", home == .projetos) { selectHome(.projetos) }
            }
            Rectangle().fill(Color.white).frame(height: 1.5)
        }
        .padding(.horizontal, 16)
    }

    private func segPill(_ label: String, _ icon: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 16, weight: .semibold))
                Text(label).font(.headline).lineLimit(1)
            }
            .foregroundColor(sel ? Ui.bg : Ui.text)
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(RoundedRectangle(cornerRadius: 14).fill(sel ? Color.white : Ui.panel2))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private func selectHome(_ t: HomeTab) {
        home = t
        projMode = .all
        if app.filter == .trash { app.filter = .all }
    }

    // ---------------- Busca e filtro ----------------

    private var searchPrompt: String { home == .projetos ? tr("Buscar projeto...") : tr("Buscar cliente...") }

    private var searchRow: some View {
        HStack(spacing: 10) {
            searchField
            filterMenu
        }
        .padding(.horizontal, 16)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(Ui.dim)
            TextField("", text: $query, prompt: Text(searchPrompt).foregroundColor(Ui.dim))
                .foregroundColor(Ui.text).submitLabel(.search)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Ui.dim) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14).frame(height: 48)
        .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel2))
    }

    private var filterMenu: some View {
        Menu {
            Button((statusFilter == nil ? "✓ " : "") + tr("Todos")) { statusFilter = nil }
            ForEach(MoveisProjects.statuses, id: \.self) { s in
                Button((statusFilter == s ? "✓ " : "") + MoveisProjects.statusLabel(s)) { statusFilter = s }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease").font(.system(size: 17, weight: .semibold))
                .foregroundColor(statusFilter == nil ? Ui.text : Ui.bg)
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 14).fill(statusFilter == nil ? Ui.panel2 : Color.white))
        }
        .accessibilityLabel(tr("Filtrar por status"))
    }

    // ---------------- Lista ----------------

    private func listBody(_ d: HomeData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            scopeBar
            if app.filter != .trash && projMode == .all { newClientButton }
            modeRow
            if home == .clientes && app.filter != .trash {
                clientList(d.clients)
            } else {
                entryList(d.entries)
            }
        }
        .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 16)
    }

    /// Pasta ou lixo aberto (pela barra lateral ou por Ferramentas): mostra onde está e o "x" pra voltar.
    @ViewBuilder private var scopeBar: some View {
        if app.filter != .all {
            HStack(spacing: 10) {
                Image(systemName: app.filter == .trash ? "trash" : "folder.fill").foregroundColor(Color.white)
                Text(scopeTitle).font(.headline).foregroundColor(Ui.text).lineLimit(1)
                Spacer()
                Button { app.filter = .all } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Ui.text)
                        .frame(width: 32, height: 32).background(Circle().fill(Ui.panel2))
                }
                .buttonStyle(.plain).accessibilityLabel(tr("Fechar"))
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
        }
    }

    private var scopeTitle: String {
        switch app.filter {
        case .trash: return tr("Lixo")
        case .folder(let f): return app.index.folders.first(where: { $0.id == f })?.name ?? tr("Pastas")
        case .all: return ""
        }
    }

    private var newClientButton: some View {
        Button { newClient = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 18, weight: .bold))
                Text(tr("Novo cliente")).font(.headline)
            }
            .foregroundColor(Ui.bg)
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    /// Modo só notas (atalho "Notas") ou só Projetor 3D (aba de baixo): título, "x" e os botões de criar.
    @ViewBuilder private var modeRow: some View {
        if home == .projetos && app.filter != .trash {
            switch projMode {
            case .notes:
                VStack(alignment: .leading, spacing: 10) {
                    modeTitle(tr("Notas"))
                    notesActions
                }
            case .moveis:
                VStack(alignment: .leading, spacing: 10) {
                    modeTitle(tr("Projetor 3D"))
                    newMoveisRow
                }
            case .all:
                EmptyView()
            }
        }
    }

    private func modeTitle(_ title: String) -> some View {
        HStack {
            Text(title).font(.title3.bold()).foregroundColor(Ui.text)
            Spacer()
            Button { projMode = .all } label: {
                Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundColor(Ui.text)
                    .frame(width: 32, height: 32).background(Circle().fill(Ui.panel2))
            }
            .buttonStyle(.plain).accessibilityLabel(tr("Fechar"))
        }
    }

    private var notesActions: some View {
        HStack(spacing: 8) {
            smallAction(tr("Nova nota"), "plus", filled: true) { app.noteAsk = NoteAsk(kind: "") }
            smallAction(tr("Importar imagem"), "photo", filled: false) { app.noteAsk = NoteAsk(kind: "gallery") }
            smallAction(tr("Foto"), "camera", filled: false) { app.noteAsk = NoteAsk(kind: "camera") }
        }
    }

    private func smallAction(_ label: String, _ icon: String, filled: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
                Text(label).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.75)
            }
            .foregroundColor(filled ? Ui.bg : Color.white)
            .padding(.horizontal, 10).frame(maxWidth: .infinity).frame(height: 44)
            .background(RoundedRectangle(cornerRadius: 12).fill(filled ? Color.white : Ui.panel))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: filled ? 0 : 1))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var newMoveisRow: some View {
        Button { app.newMoveisProject() } label: {
            HStack(spacing: 12) {
                Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(Ui.bg)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 9).fill(Color.white))
                Text(tr("Novo Projetor 3D")).font(.headline).foregroundColor(Color.white)
                Spacer()
            }
            .padding(.horizontal, 12).frame(height: 58)
            .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.6)))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    @ViewBuilder private func clientList(_ l: [ClientGroup]) -> some View {
        if l.isEmpty {
            emptyText(searching || statusFilter != nil ? tr("Nada encontrado") : tr("Nenhum cliente ainda. Toque em \"Novo cliente\"."))
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
                ForEach(l) { g in
                    ClientRow(g: g) { clientOpen = ClientPick(id: g.id) }
                }
            }
        }
    }

    @ViewBuilder private func entryList(_ l: [LibEntry]) -> some View {
        if l.isEmpty {
            emptyText(tr("Nada encontrado"))
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
                ForEach(l) { e in entryView(e) }
            }
        }
    }

    private func emptyText(_ s: String) -> some View {
        Text(s).font(.subheadline).foregroundColor(Ui.dim).multilineTextAlignment(.center)
            .frame(maxWidth: .infinity).padding(.vertical, 28)
    }

    @ViewBuilder private func entryView(_ e: LibEntry) -> some View {
        switch e {
        case .p(let pj): ProjRow(p: pj)
        case .n(let n): NoteRow(n: n)
        }
    }

    // ---------------- Atalhos, teste grátis e barra de abas ----------------

    private var bottomBlock: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                shortcut(tr("Projetor 3D"), "cube") { app.newMoveisProject() }
                shortcut(tr("Notas"), "square.and.pencil") { openNotesMode() }
                shortcut(tr("Orçamentos"), "dollarsign.circle") { app.screen = .quotes }
            }
            if showTrial { TrialChip(bar: true) }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 10)
    }

    private func openNotesMode() {
        home = .projetos
        projMode = .notes
        if app.filter == .trash { app.filter = .all }
    }

    private func openMoveisMode() {
        home = .projetos
        projMode = .moveis
        if app.filter == .trash { app.filter = .all }
    }

    private func goHome() {
        home = .clientes
        projMode = .all
        app.filter = .all
    }

    private func shortcut(_ label: String, _ icon: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24, weight: .semibold)).foregroundColor(Color.white)
                Text(label).font(.footnote.weight(.semibold)).foregroundColor(Ui.text).lineLimit(1).minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity).frame(height: 84)
            .background(RoundedRectangle(cornerRadius: 16).fill(Ui.panel))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Ui.line))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var moveisTabOn: Bool { home == .projetos && projMode == .moveis }

    private var tabBar: some View {
        HStack(spacing: 0) {
            barItem(tr("Início"), "house", !moveisTabOn) { goHome() }
            barItem(tr("Projetor 3D"), "cube", moveisTabOn) { openMoveisMode() }
            barItem(tr("Ferramentas"), "wrench.and.screwdriver", false) { toolsOpen = true }
            barItem(tr("Ajustes"), "gearshape", false) { settingsOpen = true }
        }
        .frame(height: LibraryView.tabBarHeight)
        .background(Ui.panel.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Ui.line).frame(height: 1) }
    }

    private func barItem(_ label: String, _ icon: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(spacing: 3) {
                Image(systemName: icon).font(.system(size: 19, weight: .semibold))
                Text(label).font(.system(size: 10, weight: .semibold)).lineLimit(1).minimumScaleFactor(0.8)
                Capsule().fill(sel ? Color.white : Color.clear).frame(width: 22, height: 3)
            }
            .foregroundColor(sel ? Color.white : Ui.dim)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    /// Fecha a folha de Ferramentas/Ajustes e só depois abre a próxima tela ou janela.
    private func afterSheet(_ f: @escaping () -> Void) {
        toolsOpen = false
        settingsOpen = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { f() }
    }

    private var toolsItems: [HomeMenuItem] {
        var l: [HomeMenuItem] = [
            HomeMenuItem(icon: "calendar", label: tr("Agenda"), action: { afterSheet { app.screen = .agenda } }),
            HomeMenuItem(icon: "dollarsign.circle", label: tr("Orçamentos"), action: { afterSheet { app.screen = .quotes } }),
            HomeMenuItem(icon: "ruler", label: tr("Trena Bosch"), action: { afterSheet { btOpen = true } }),
            HomeMenuItem(icon: "iphone.radiowaves.left.and.right", label: tr("Ver projeto de outro iPhone"), action: { afterSheet { peerView = true } }),
        ]
        // pastas: abre a pasta na tela inicial
        for f in sortedFolders {
            let fid = f.id
            l.append(HomeMenuItem(icon: "folder.fill", label: f.name, action: { toolsOpen = false; projMode = .all; app.filter = .folder(fid) }))
        }
        l.append(HomeMenuItem(icon: "folder.badge.plus", label: tr("Nova pasta"), action: { afterSheet { newFolder = true } }))
        l.append(HomeMenuItem(icon: "trash", label: tr("Lixo"), action: { toolsOpen = false; projMode = .all; app.filter = .trash }))
        return l
    }

    private var settingsItems: [HomeMenuItem] {
        [
            HomeMenuItem(icon: "building.2", label: tr("Dados da empresa"), action: { afterSheet { companyOpen = true } }),
            HomeMenuItem(icon: "archivebox", label: tr("Fazer backup completo (ZIP)"), action: { afterSheet { shareURL = app.makeBackup() } }),
            HomeMenuItem(icon: "arrow.counterclockwise", label: tr("Restaurar backup"), action: { afterSheet { restorePick = true } }),
            HomeMenuItem(icon: "arrow.triangle.2.circlepath", label: tr("Sincronizar com outro aparelho (Wi-Fi)"), action: { afterSheet { syncOpen = true } }),
            HomeMenuItem(icon: "iphone.radiowaves.left.and.right", label: tr("Ver projeto de outro iPhone"), action: { afterSheet { peerView = true } }),
            HomeMenuItem(icon: "globe", label: langLabel, action: { afterSheet { langOpen = true } }),
            HomeMenuItem(icon: "creditcard", label: tr("Gerenciar assinatura"), action: { afterSheet { manageSub = true } }),
            HomeMenuItem(icon: "book", label: tr("Guia passo a passo"), action: { afterSheet { app.showGuide = true } }),
            HomeMenuItem(icon: "questionmark.circle", label: tr("Ajuda e suporte"), url: SiteLinks.support),
            HomeMenuItem(icon: "hand.raised", label: tr("Privacidade"), url: SiteLinks.privacy),
        ]
    }
}

/// Item das folhas Ferramentas/Ajustes: ação ou link.
struct HomeMenuItem: Identifiable {
    let id = UUID()
    var icon: String
    var label: String
    var url: URL? = nil
    var action: () -> Void = {}
}

/// Folha simples com uma lista de atalhos (Ferramentas, Ajustes).
struct HomeMenuSheet: View {
    var title: String
    var items: [HomeMenuItem]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { it in row(it) }
            }
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder private func row(_ it: HomeMenuItem) -> some View {
        if let u = it.url {
            Link(destination: u) { Label(it.label, systemImage: it.icon).foregroundColor(Ui.text) }
        } else {
            Button(action: it.action) { Label(it.label, systemImage: it.icon).foregroundColor(Ui.text) }
        }
    }
}

/// Projeto do Projetor 3D. `bare` = linha compacta dentro do quadro do cliente.
struct ProjRow: View {
    @EnvironmentObject var app: AppModel
    var p: MoveisProjects.P
    var bare = false
    @State private var rename = false
    @State private var del = false
    @State private var titleDlg = false
    @State private var move = false
    private var noteNames: String { app.notesOfProject(p.id).compactMap { id in app.index.notes.first { $0.id == id && !$0.trash }?.name }.joined(separator: ", ") }

    /// Plano de corte recebido ou projeto recebido do marceneiro.
    private var originLine: String? {
        if p.corte { return tr("✂ Plano de corte recebido") + (p.from.isEmpty ? "" : " · " + p.from) }
        if p.cliente { return "🏠 " + p.label + (p.from.isEmpty ? "" : " · " + p.from) }
        return nil
    }

    private var metaLine: String {
        let mods = tr(p.mods == 1 ? "{0} módulo" : "{0} módulos", p.mods)
        if bare { return dateText(p.updated) + " • " + mods }
        let linked = app.notesOfProject(p.id).count
        return mods + (linked > 0 ? tr(linked == 1 ? " · {0} nota" : " · {0} notas", linked) : "")
    }

    var body: some View {
        HStack(spacing: bare ? 10 : 12) {
            thumb
            info
            Spacer(minLength: 4)
            actions
        }
        .padding(bare ? 8 : 10)
        .frame(minHeight: bare ? 60 : 96, maxHeight: bare ? nil : 96)
        .background(RoundedRectangle(cornerRadius: 14).fill(bare ? Color.clear : Ui.panel))
        .contentShape(Rectangle())
        .onTapGesture { app.openProject(p.id) }
        .sheet(isPresented: $rename) { NameSheet(title: tr("Nome do projeto"), label: tr("Cliente / projeto"), text: p.auto ? "" : p.name) { app.renameMoveisProject(p.id, $0) } }
        .sheet(isPresented: $titleDlg) { NameSheet(title: tr("Nome do projeto (ex.: Cozinha, Suíte)"), label: tr("Nome do projeto"), text: p.title) { app.setProjectTitle(p.id, $0) } }
        .confirmationDialog(tr("Mover para"), isPresented: $move) {
            Button(tr("Sem pasta")) { app.moveClient(note: nil, proj: p.id, folder: nil) }
            ForEach(app.index.folders.sorted { nameLess($0.name, $1.name) }) { f in Button("📁 " + f.name) { app.moveClient(note: nil, proj: p.id, folder: f.id) } }
        } message: { Text(tr("A nota e o projeto do cliente vão juntos.")) }
        .alert(tr("Apagar este projeto?"), isPresented: $del) {
            Button(tr("Cancelar"), role: .cancel) {}
            Button(tr("Apagar"), role: .destructive) { app.deleteMoveisProject(p.id) }
        } message: { Text(tr("\"{0}\" sai da lista de projetos de móveis. Isso não pode ser desfeito.", p.name)) }
    }

    private var thumb: some View {
        Text("🪚").font(.system(size: bare ? 20 : 26))
            .frame(width: bare ? 44 : 56, height: bare ? 44 : 76)
            .background(RoundedRectangle(cornerRadius: bare ? 10 : 6).fill(Color(argb: 0xFF2B2416)))
            .overlay(RoundedRectangle(cornerRadius: bare ? 10 : 6).stroke(Color.white.opacity(0.35)))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(bare ? p.label : p.name).font(bare ? Font.subheadline.weight(.semibold) : Font.body).foregroundColor(Ui.text).lineLimit(1)
                statusMenu
            }
            if let o = originLine {
                Text(o).font(.caption).foregroundColor(Color.white).lineLimit(1)
            } else if !bare {
                Text("🪚 " + p.label + " · " + dateText(p.updated)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            }
            if let e = MoveisProjects.entregaInfo(p) {
                Text(e.text).font(.caption.weight(e.late ? .bold : .regular)).foregroundColor(e.late ? Color(argb: 0xFFE53935) : Ui.dim).lineLimit(1)
            }
            Text(metaLine).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(MoveisProjects.statuses, id: \.self) { s in
                Button((s == p.status ? "✓ " : "") + MoveisProjects.statusLabel(s)) { app.setProjectStatus(p.id, s) }
            }
        } label: { StatusChip(status: p.status) }
    }

    private var actions: some View {
        Menu {
            Section {
                Text(tr("Cliente: {0}", p.name))
                Text(tr("Projeto: {0}", p.label))
                Text(tr("Ambiente: {0}", MoveisProjects.roomLabel(p.room)))
                Text(noteNames.isEmpty ? tr("Nota: nenhuma ligada") : tr("Nota: {0}", noteNames))
            }
            Button(tr("Abrir")) { app.openProject(p.id) }
            Button(tr("📝 Abrir a nota do cliente")) { app.openNoteOf(p.id) }
            Button(tr("Nome do projeto (ex.: Cozinha, Suíte)")) { titleDlg = true }
            Button(tr("＋ Novo projeto deste cliente")) { app.newProjectForClient(p.name, app.notesOfProject(p.id).first) }
            Button(tr("Renomear (nome do cliente)")) { rename = true }
            Menu(tr("Status do projeto") + ": " + MoveisProjects.statusLabel(p.status)) {
                ForEach(MoveisProjects.statuses, id: \.self) { s in
                    Button((s == p.status ? "✓ " : "") + MoveisProjects.statusLabel(s)) { app.setProjectStatus(p.id, s) }
                }
            }
            Button(tr("Nova nota ligada a este projeto")) { app.noteAsk = NoteAsk(kind: "", project: p.id) }
            Button(tr("📁 Mover para pasta (vai junto com a nota)")) { move = true }
            Button(tr("Apagar projeto"), role: .destructive) { del = true }
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold)).foregroundColor(Ui.dim).frame(width: 40, height: 40)
        }
    }
}

/// Etiqueta pequena do status do projeto (orçamento, fechado, produção, finalizado).
struct StatusChip: View {
    var status: String
    var body: some View {
        Text(MoveisProjects.statusLabel(status)).font(.system(size: 10, weight: .semibold)).foregroundColor(.white).lineLimit(1)
            .padding(.horizontal, 6).padding(.vertical, 1)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(argb: 0xFF000000 | MoveisProjects.statusColor(status))))
    }
}

/// Ordem alfabética do jeito que a gente lê: sem diferença de maiúscula/acento e com número na ordem certa (Nota 2 antes de Nota 10).
func nameLess(_ a: String, _ b: String) -> Bool {
    a.trimmingCharacters(in: .whitespaces).compare(b.trimmingCharacters(in: .whitespaces), options: [.caseInsensitive, .diacriticInsensitive, .numeric], range: nil, locale: Locale(identifier: "pt_BR")) == .orderedAscending
}

/// Item da aba Projetos: projeto do Projetor 3D ou nota.
enum LibEntry: Identifiable {
    case p(MoveisProjects.P), n(NoteMeta)
    var id: String {
        switch self { case .p(let x): return "proj-" + x.id; case .n(let x): return "note-" + x.id }
    }
    var name: String {
        switch self { case .p(let x): return x.name; case .n(let x): return x.name }
    }
    var pinned: Bool { if case .n(let x) = self { return x.pinned }; return false }
    /// Data para "mais recentes": projeto = última alteração; nota = criação.
    var date: Int64 {
        switch self {
        case .p(let x): return x.updated
        case .n(let x): return x.createdMs
        }
    }
}

/// Cliente com seus projetos do Projetor 3D (mais recente primeiro) e as notas ligadas ou de mesmo nome.
struct ClientGroup: Identifiable {
    var id: String
    var name: String
    var projs: [MoveisProjects.P]
    var notes: [NoteMeta]
    /// Projeto alterado por último (o status dele aparece no cartão).
    var latest: MoveisProjects.P? { projs.max { $0.updated < $1.updated } }
    var lastDate: Int64 { max(projs.map(\.updated).max() ?? 0, notes.map(\.createdMs).max() ?? 0) }
    var count: Int { projs.count + notes.count }
    func matches(_ q: String) -> Bool { name.localizedCaseInsensitiveContains(q) || projs.contains { projMatches($0, q) } || notes.contains { $0.name.localizedCaseInsensitiveContains(q) } }
}

/// Junta por cliente: projetos com o mesmo nome de cliente ficam juntos, com as notas ligadas a eles (ou com o mesmo nome).
/// Projeto sem nome de cliente, plano de corte recebido e projeto recebido do marceneiro ficam soltos (aparecem na aba Projetos).
@MainActor func homeClients(_ app: AppModel, _ projs: [MoveisProjects.P], _ notes: [NoteMeta]) -> (groups: [ClientGroup], looseProjs: [MoveisProjects.P], looseNotes: [NoteMeta]) {
    func k(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces).lowercased() }
    var pk: [String: String] = [:]
    var order: [String] = []
    var ps: [String: [MoveisProjects.P]] = [:]
    var looseP: [MoveisProjects.P] = []
    for p in projs {
        if app.isDefaultProj(p) || p.corte || p.cliente {
            pk[p.id] = "id:" + p.id
            looseP.append(p)
            continue
        }
        let key = k(p.name)
        pk[p.id] = key
        if ps[key] == nil { order.append(key) }
        ps[key, default: []].append(p)
    }
    var ns: [String: [NoteMeta]] = [:]
    var looseN: [NoteMeta] = []
    for n in notes {
        let key = app.linkedProject(n.id).flatMap { pk[$0] } ?? (app.isDefaultNote(n.name) ? nil : k(n.name))
        if let key = key, ps[key] != nil { ns[key, default: []].append(n) } else { looseN.append(n) }
    }
    let groups: [ClientGroup] = order.map { key in
        let P = (ps[key] ?? []).sorted { $0.updated > $1.updated }
        let N = (ns[key] ?? []).sorted { $0.createdMs > $1.createdMs }
        return ClientGroup(id: key, name: P.first?.name ?? key, projs: P, notes: N)
    }
    return (groups, looseP, looseN)
}

/// Quadradinho com a inicial do cliente (fundo escuro dourado, letra dourada).
struct ClientAvatar: View {
    var name: String
    var size: CGFloat = 52
    private var initial: String { String(name.trimmingCharacters(in: .whitespaces).prefix(1)).uppercased() }
    var body: some View {
        Text(initial.isEmpty ? "?" : initial)
            .font(.system(size: size * 0.46, weight: .bold)).foregroundColor(Color.white)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.27).fill(Color(argb: 0xFF2B2416)))
            .overlay(RoundedRectangle(cornerRadius: size * 0.27).stroke(Color.white.opacity(0.3)))
    }
}

/// Cartão do cliente na tela inicial: inicial, nome, quantos projetos, última alteração e status do projeto mais recente.
struct ClientRow: View {
    var g: ClientGroup
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ClientAvatar(name: g.name)
                info
                Spacer(minLength: 4)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundColor(Ui.dim)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).fill(Ui.panel))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var countText: String { tr(g.count == 1 ? "{0} projeto" : "{0} projetos", g.count) }

    private var info: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(g.name).font(.headline).foregroundColor(Ui.text).lineLimit(1)
                Text("· " + countText).font(.caption).foregroundColor(Ui.dim).lineLimit(1).fixedSize()
            }
            HStack(spacing: 8) {
                Text(dmyText(g.lastDate)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
                if let p = g.latest { StatusChip(status: p.status) }
            }
            if let p = g.latest, let e = MoveisProjects.entregaInfo(p), e.late {
                Text(e.text).font(.caption2.weight(.bold)).foregroundColor(Color(argb: 0xFFE53935)).lineLimit(1)
            }
        }
    }
}

/// Folha do cliente: projetos do Projetor 3D e notas dele, com os botões de criar.
struct ClientDetailSheet: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    var key: String

    private var group: ClientGroup? {
        _ = app.projVersion
        let notes = app.index.notes.filter { !$0.trash }
        return homeClients(app, app.moveisProjects(), notes).groups.first { $0.id == key }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let g = group {
                    detail(g)
                } else {
                    Text(tr("Nada encontrado")).font(.subheadline).foregroundColor(Ui.dim).padding(.top, 40)
                }
            }
            .background(Ui.bg.ignoresSafeArea())
            .navigationTitle(tr("Cliente")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } } }
        }
        // abriu um projeto ou uma nota: a tela muda e a folha fecha
        .onChange(of: app.screen) { _ in dismiss() }
        // "Nova nota" (daqui ou do menu do projeto): fecha a folha e a biblioteca pergunta o nome
        .onChange(of: app.noteAsk?.id) { v in
            guard v != nil, let a = app.noteAsk else { return }
            app.noteAsk = nil
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { app.noteAsk = a }
        }
    }

    private func detail(_ g: ClientGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            head(g)
            sectionTitle(tr("Projetor 3D"), g.projs.count)
            ForEach(g.projs) { p in ProjRow(p: p) }
            createButton(tr("Projetor 3D deste cliente"), filled: true) {
                dismiss()
                app.newProjectForClient(g.name, nil)
            }
            sectionTitle(tr("Notas"), g.notes.count).padding(.top, 8)
            ForEach(g.notes) { n in NoteRow(n: n) }
            createButton(tr("Nota"), filled: false) {
                app.noteAsk = NoteAsk(kind: "", project: g.projs.first?.id)
            }
        }
        .padding(16)
    }

    private func head(_ g: ClientGroup) -> some View {
        HStack(spacing: 14) {
            ClientAvatar(name: g.name, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(g.name).font(.title2.bold()).foregroundColor(Ui.text).lineLimit(2)
                Text(tr(g.count == 1 ? "{0} projeto" : "{0} projetos", g.count)).font(.subheadline).foregroundColor(Ui.dim)
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 6)
    }

    private func sectionTitle(_ title: String, _ count: Int) -> some View {
        Text(title + " (\(count))").font(.headline).foregroundColor(Color.white)
    }

    private func createButton(_ label: String, filled: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 8) {
                Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                Text(label).font(.subheadline.weight(.semibold)).lineLimit(1)
            }
            .foregroundColor(filled ? Ui.bg : Color.white)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 12).fill(filled ? Color.white : Color.clear))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white, lineWidth: 1.2))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// Busca no projeto: cliente, nome do projeto, ambiente, cidade e status.
func projMatches(_ p: MoveisProjects.P, _ q: String) -> Bool {
    [p.name, p.label, MoveisProjects.roomLabel(p.room), p.city, MoveisProjects.statusLabel(p.status)].contains { $0.localizedCaseInsensitiveContains(q) }
}

/// Nota. `bare` = linha compacta dentro do quadro do cliente.
struct NoteRow: View {
    @EnvironmentObject var app: AppModel
    var n: NoteMeta
    var bare = false
    @State private var rename = false
    @State private var move = false
    @State private var confirmDelete = false

    var body: some View {
        let _ = app.thumbVersion
        HStack(spacing: bare ? 10 : 12) {
            thumb
            info
            Spacer(minLength: 4)
            actions
        }
        .padding(bare ? 8 : 10)
        .frame(minHeight: bare ? 60 : 96, maxHeight: bare ? nil : 96)
        .background(RoundedRectangle(cornerRadius: 14).fill(bare ? Color.clear : Ui.panel))
        .contentShape(Rectangle())
        .onTapGesture { if !n.trash { app.openNote(n.id) } }
        .sheet(isPresented: $rename) { NameSheet(title: tr("Editar nota"), label: tr("Nome"), text: n.name) { app.renameNote(n.id, $0) } }
        .confirmationDialog(tr("Mover para"), isPresented: $move) {
            Button(tr("Sem pasta")) { app.moveClient(note: n.id, proj: nil, folder: nil) }
            ForEach(app.index.folders.sorted { nameLess($0.name, $1.name) }) { f in Button("📁 " + f.name) { app.moveClient(note: n.id, proj: nil, folder: f.id) } }
        } message: { Text(tr("A nota e o projeto do cliente vão juntos.")) }
        .alert(tr("Apagar para sempre?"), isPresented: $confirmDelete) {
            Button(tr("Cancelar"), role: .cancel) {}
            Button(tr("Apagar"), role: .destructive) { app.deleteForever(n.id) }
        }
    }

    private var thumb: some View {
        ZStack {
            Color.white
            if let t = app.loadThumb(n.id) { Image(uiImage: t).resizable().scaledToFill() }
        }
        .frame(width: bare ? 44 : 56, height: bare ? 44 : 76)
        .clipShape(RoundedRectangle(cornerRadius: bare ? 8 : 4))
        .overlay(RoundedRectangle(cornerRadius: bare ? 8 : 4).stroke(Ui.line))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(n.name).font(bare ? Font.subheadline.weight(.semibold) : Font.body).foregroundColor(Ui.text).lineLimit(1)
                if n.pinned { Image(systemName: "pin.fill").font(.caption).foregroundColor(Color.white) }
                if n.locked { Image(systemName: "lock.fill").font(.caption).foregroundColor(Ui.dim) }
            }
            Text(dateText(n.createdMs) + " • " + tr(n.pageCount == 1 ? "{0} folha" : "{0} folhas", n.pageCount)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            if !bare {
                Text(tr(n.dimCount == 1 ? "{0} cota" : "{0} cotas", n.dimCount)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            }
        }
    }

    private var actions: some View {
        Menu {
            if n.trash {
                Button(tr("Restaurar")) { app.trashNote(n.id, false) }
                Button(tr("Apagar para sempre"), role: .destructive) { confirmDelete = true }
            } else {
                Button(tr("🪚 Abrir o projeto deste cliente")) { if !app.openProjectOfNote(n.id) { app.newProjectForNote(n.id) } }
                Button(tr("＋ Novo projeto para este cliente")) { app.newProjectForNote(n.id) }
                Button(tr("Editar nome")) { rename = true }
                Button(tr("Copiar")) { app.copyNote(n.id) }
                Button(n.pinned ? tr("Desafixar nota") : tr("Fixar nota")) { app.pinNote(n.id, !n.pinned) }
                Button(tr("Mover para")) { move = true }
                Button(n.locked ? tr("Remover bloqueio") : tr("Adicionar bloqueio")) { app.lockNote(n.id, !n.locked) }
                Divider()
                Button(tr("Mover para o lixo"), role: .destructive) { app.trashNote(n.id, true) }
            }
        } label: {
            Image(systemName: "ellipsis").font(.system(size: 16, weight: .bold)).foregroundColor(Ui.dim).frame(width: 40, height: 40)
        }
    }
}
