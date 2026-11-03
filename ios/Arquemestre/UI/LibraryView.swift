import SwiftUI
import StoreKit
import UniformTypeIdentifiers

private var dateFmt: DateFormatter { I18n.shared.dateFormatter(.date) }
private func dateText(_ ms: Int64) -> String { dateFmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000)) }

private enum LibTab: String, CaseIterable { case ALL = "TUDO", NOTE = "NOTA", MOVEIS = "MÓVEIS" }

/// Abas sublinhadas da tela inicial: clientes (quadros por cliente) ou projetos (lista corrida, mais recentes primeiro).
private enum HomeTab { case clientes, projetos }

/// O que a lista mostra (calculado uma vez por desenho).
fileprivate struct LibData {
    var entries: [LibEntry]
    var projFolder: [String: String]
}

/// Biblioteca (escura, destaque dourado): clientes, projetos (Projetor 3D), notas e pastas.
struct LibraryView: View {
    @EnvironmentObject var app: AppModel
    @State private var query = ""
    @State private var tab: LibTab = .ALL
    @State private var home: HomeTab = .clientes
    @State private var searchOpen = false
    @FocusState private var searchFocus: Bool
    @State private var newFolder = false
    @State private var shareURL: URL?
    @State private var restorePick = false
    @State private var confirmRestore: URL?
    @State private var peerView = false
    @State private var langOpen = false
    @State private var manageSub = false
    @State private var toolsOpen = false
    @State private var settingsOpen = false
    @State private var btOpen = false
    /// Ordem escolhida em "Ordenar" (cada aba guarda a sua).
    @AppStorage("arque.lib.recent.clientes") private var cliRecent = false
    @AppStorage("arque.lib.recent.projetos") private var projRecent = true

    /// Altura da barra de abas de baixo (só no iPhone); o selo do teste grátis sobe essa altura.
    static let tabBarHeight: CGFloat = 58
    /// A partir desta largura a biblioteca usa a barra lateral (iPad) em vez da barra de abas.
    static let wideMinWidth: CGFloat = 700

    private var searching: Bool { !query.trimmingCharacters(in: .whitespaces).isEmpty }
    // quem está numa pasta sai de "Todas as notas" (fica só na pasta); na busca aparece tudo
    private var notes: [NoteMeta] {
        app.index.notes.filter {
            switch app.filter {
            case .all: return !$0.trash && (searching || app.liveFolder($0.folderId) == nil)
            case .trash: return $0.trash
            case .folder(let f): return !$0.trash && $0.folderId == f
            }
        }
        .filter { _ in tab != .MOVEIS }
        .sorted { $0.pinned != $1.pinned ? $0.pinned : nameLess($0.name, $1.name) }
    }
    private var sortedFolders: [Folder] { app.index.folders.sorted { nameLess($0.name, $1.name) } }
    private var langLabel: String { langMenuLabel() + " (" + currentLangName() + ")" }
    private var sortRecent: Bool { home == .projetos ? projRecent : cliRecent }
    /// Compromisso não concluído nas próximas 24 h (bolinha no sino).
    private var hasSoonAppt: Bool {
        let now = nowMs()
        return app.appointments.contains { !$0.done && $0.startMs >= now && $0.startMs <= now + 86_400_000 }
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= LibraryView.wideMinWidth
            HStack(spacing: 0) {
                if wide { sidebar.frame(width: 230).background(Ui.panel) }
                content(wide: wide)
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
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
        .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
        .sheet(isPresented: $peerView) { PeerViewPicker() }
        .sheet(isPresented: $langOpen) { LanguagePicker() }
        .sheet(isPresented: $btOpen) { BluetoothView() }
        .sheet(isPresented: $toolsOpen) { HomeMenuSheet(title: tr("Ferramentas"), items: toolsItems) }
        .sheet(isPresented: $settingsOpen) { HomeMenuSheet(title: tr("Ajustes"), items: settingsItems) }
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
                side(tr("Lixo"), "trash", app.filter == .trash) { app.filter = .trash }
            }.padding(12)
        }
    }

    private func side(_ label: String, _ icon: String, _ sel: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(sel ? Ui.gold : Ui.dim).frame(width: 20)
                Text(label).foregroundColor(Ui.text).lineLimit(1)
                Spacer()
            }
            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(sel ? Ui.panel2 : .clear))
        }.buttonStyle(.plain)
    }

    // ---------------- Conteúdo ----------------

    private func content(wide: Bool) -> some View {
        let data = libData()
        return ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header
                if searchOpen || searching { searchRow }
                chipsRow(wide: wide).padding(.top, 6)
                underTabs.padding(.top, 10)
                ScrollView { listBody(data) }
                if !wide { tabBar }
            }
            if app.filter != .trash {
                fab.padding(.bottom, wide ? 0 : LibraryView.tabBarHeight)
            }
        }
    }

    private func libData() -> LibData {
        let projAll = app.moveisProjects()
        _ = app.projVersion
        // o projeto fica na mesma pasta que a nota do cliente
        let projFolder = app.projectFolders(projAll)
        let q = query.trimmingCharacters(in: .whitespaces)
        if home == .projetos {
            return LibData(entries: flatEntries(projAll, projFolder, q), projFolder: projFolder)
        }
        let projList = projAll.filter { p in
            switch app.filter {
            case .all: return searching || projFolder[p.id] == nil
            case .folder(let f): return projFolder[p.id] == f
            case .trash: return false
            }
        }
        // um quadro por cliente: as notas e os projetos dele (dá pra ter vários projetos por cliente)
        let showProj = app.filter != .trash && tab != .NOTE
        let groups = showProj ? clientGroups(app, projList, tab == .ALL ? notes : []) : []
        let shown = groups.filter { q.isEmpty || $0.matches(q) }
        let inGroupP = Set(groups.flatMap { $0.projs.map(\.id) })
        let inGroupN = Set(groups.flatMap { $0.notes.map(\.id) })
        let projs = showProj ? projList.filter { !inGroupP.contains($0.id) && (q.isEmpty || projMatches($0, q)) } : []
        let looseNotes = notes.filter { !inGroupN.contains($0.id) && (q.isEmpty || $0.name.localizedCaseInsensitiveContains(q)) }
        let all: [LibEntry] = shown.map { LibEntry.g($0) } + projs.map { LibEntry.p($0) } + looseNotes.map { LibEntry.n($0) }
        return LibData(entries: sortEntries(all, recent: cliRecent), projFolder: projFolder)
    }

    /// Aba "Projetos": todos os projetos e notas (também os que estão em pastas), sem agrupar por cliente.
    private func flatEntries(_ projAll: [MoveisProjects.P], _ projFolder: [String: String], _ q: String) -> [LibEntry] {
        var out: [LibEntry] = []
        if app.filter != .trash && tab != .NOTE {
            for p in projAll {
                var inScope = true
                if case .folder(let f) = app.filter { inScope = projFolder[p.id] == f }
                if inScope && (q.isEmpty || projMatches(p, q)) { out.append(LibEntry.p(p)) }
            }
        }
        if tab != .MOVEIS {
            for n in app.index.notes {
                let inScope: Bool
                switch app.filter {
                case .all: inScope = !n.trash
                case .trash: inScope = n.trash
                case .folder(let f): inScope = !n.trash && n.folderId == f
                }
                if inScope && (q.isEmpty || n.name.localizedCaseInsensitiveContains(q)) { out.append(LibEntry.n(n)) }
            }
        }
        return sortEntries(out, recent: projRecent)
    }

    /// Notas fixadas em cima; depois por nome (A-Z) ou pelos mais recentes.
    private func sortEntries(_ l: [LibEntry], recent: Bool) -> [LibEntry] {
        l.sorted { a, b in
            if a.pinned != b.pinned { return a.pinned }
            if recent && a.date != b.date { return a.date > b.date }
            return nameLess(a.name, b.name)
        }
    }

    // ---------------- Cabeçalho ----------------

    private var header: some View {
        HStack(spacing: 10) {
            logoMark
            VStack(alignment: .leading, spacing: 1) {
                Text("ARQUEMESTRE").font(.system(size: 18, weight: .heavy)).foregroundColor(Ui.text).lineLimit(1).minimumScaleFactor(0.7)
                Text(tr("Organização de Projetos")).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            }
            Spacer(minLength: 6)
            Button { toggleSearch() } label: { circleIcon(searchOpen ? "xmark" : "magnifyingglass") }
                .buttonStyle(.plain).accessibilityLabel(tr("Pesquisar"))
            Button { app.screen = .agenda } label: { bellIcon }
                .buttonStyle(.plain).accessibilityLabel(tr("Agenda"))
            Menu { settingsMenuItems } label: { circleIcon("ellipsis") }
        }
        .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)
    }

    private var logoMark: some View {
        Text("A").font(.system(size: 22, weight: .black)).foregroundColor(Ui.bg)
            .frame(width: 40, height: 40)
            .background(RoundedRectangle(cornerRadius: 11).fill(Ui.gold))
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name).font(.system(size: 16, weight: .semibold)).foregroundColor(Ui.text)
            .frame(width: 40, height: 40)
            .background(Circle().fill(Ui.panel2))
    }

    private var bellIcon: some View {
        circleIcon("bell").overlay(alignment: .topTrailing) {
            if hasSoonAppt {
                Circle().fill(Ui.gold).frame(width: 9, height: 9).offset(x: -7, y: 7)
            }
        }
    }

    private func toggleSearch() {
        if searchOpen || searching {
            searchOpen = false
            query = ""
            searchFocus = false
        } else {
            searchOpen = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { searchFocus = true }
        }
    }

    private var searchRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(Ui.dim)
            TextField(tr("Pesquisar"), text: $query).foregroundColor(Ui.text).focused($searchFocus)
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(Ui.dim) }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Ui.panel2))
        .padding(.horizontal, 16).padding(.top, 6)
    }

    /// Itens do menu "…" (os mesmos de Ajustes).
    @ViewBuilder private var settingsMenuItems: some View {
        Button { shareURL = app.makeBackup() } label: { Label(tr("Fazer backup completo (ZIP)"), systemImage: "archivebox") }
        Button { restorePick = true } label: { Label(tr("Restaurar backup"), systemImage: "arrow.counterclockwise") }
        Divider()
        Button { peerView = true } label: { Label(tr("Ver projeto de outro iPhone"), systemImage: "iphone.radiowaves.left.and.right") }
        Divider()
        Button { langOpen = true } label: { Label(langLabel, systemImage: "globe") }
        Button { manageSub = true } label: { Label(tr("Gerenciar assinatura"), systemImage: "creditcard") }
        Button { app.showGuide = true } label: { Label(tr("Guia passo a passo"), systemImage: "book") }
        Link(destination: SiteLinks.support) { Label(tr("Ajuda e suporte"), systemImage: "questionmark.circle") }
        Link(destination: SiteLinks.privacy) { Label(tr("Privacidade"), systemImage: "hand.raised") }
    }

    // ---------------- Filtros e abas ----------------

    private func chipsRow(wide: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(tr("Todos"), "folder", tab == .ALL && app.filter == .all) { tab = .ALL; app.filter = .all }
                filterChip(tr("Notas"), "doc.text", tab == .NOTE && app.filter != .trash) { tab = .NOTE; if app.filter == .trash { app.filter = .all } }
                filterChip(tr("Móveis"), "hammer", tab == .MOVEIS && app.filter != .trash) { tab = .MOVEIS; if app.filter == .trash { app.filter = .all } }
                filterChip(tr("Orçamentos"), "dollarsign.circle", false) { app.screen = .quotes }
                // no iPhone as pastas e o lixo ficam aqui (no iPad estão na barra lateral)
                if !wide {
                    ForEach(sortedFolders) { f in
                        filterChip(f.name, "folder.fill", app.filter == .folder(f.id)) { app.filter = .folder(f.id) }
                    }
                    filterChip(tr("Lixo"), "trash", app.filter == .trash) { app.filter = .trash }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func filterChip(_ label: String, _ icon: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                Text(label).font(.subheadline.weight(.semibold)).lineLimit(1)
            }
            .foregroundColor(sel ? Ui.bg : Ui.text)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(sel ? Ui.gold : Ui.panel2))
        }.buttonStyle(.plain)
    }

    private var underTabs: some View {
        HStack(spacing: 0) {
            underTab(tr("Clientes"), "person", home == .clientes) { home = .clientes }
            underTab(tr("Projetos"), "doc.text", home == .projetos) { home = .projetos }
            underTab(tr("Agenda"), "calendar", false) { app.screen = .agenda }
        }
        .background(alignment: .bottom) { Rectangle().fill(Ui.line).frame(height: 1) }
        .padding(.horizontal, 16)
    }

    private func underTab(_ label: String, _ icon: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon).font(.footnote.weight(.semibold))
                    Text(label).font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                .foregroundColor(sel ? Ui.gold : Ui.dim)
                Rectangle().fill(sel ? Ui.gold : Color.clear).frame(height: 2)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    // ---------------- Lista ----------------

    private func listBody(_ d: LibData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if app.filter != .trash && !searching { createBlock }
            sectionHeader(d.entries.count)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
                // as pastas aparecem em cima, com quantos itens têm (o que entrou numa pasta sai daqui)
                if home == .clientes && app.filter == .all && !searching {
                    ForEach(sortedFolders) { f in
                        FolderTile(name: f.name, count: folderCount(f.id, d.projFolder)) { app.filter = .folder(f.id) }
                    }
                }
                ForEach(d.entries) { e in entryView(e) }
            }
        }
        .padding(.horizontal, 12).padding(.top, 12).padding(.bottom, 96)
    }

    private func folderCount(_ fid: String, _ projFolder: [String: String]) -> Int {
        let n = tab == .MOVEIS ? 0 : app.index.notes.filter { !$0.trash && $0.folderId == fid }.count
        let p = tab == .NOTE ? 0 : projFolder.values.filter { $0 == fid }.count
        return n + p
    }

    @ViewBuilder private func entryView(_ e: LibEntry) -> some View {
        switch e {
        case .g(let g): ClientCard(g: g)
        case .p(let pj): ProjRow(p: pj)
        case .n(let n): NoteRow(n: n)
        }
    }

    /// "＋ Novo projeto" (tracejado) e os atalhos Projetor 3D, Nota e Orçamento.
    private var createBlock: some View {
        VStack(spacing: 10) {
            Button { app.newMoveisProject() } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(Ui.bg)
                        .frame(width: 34, height: 34)
                        .background(RoundedRectangle(cornerRadius: 9).fill(Ui.gold))
                    Text(tr("Novo projeto")).font(.headline).foregroundColor(Ui.gold)
                }
                .frame(maxWidth: .infinity).frame(height: 64)
                .background(RoundedRectangle(cornerRadius: 16).fill(Ui.gold.opacity(0.06)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Ui.gold, style: StrokeStyle(lineWidth: 1.5, dash: [8, 5])))
                .contentShape(Rectangle())
            }.buttonStyle(.plain)
            HStack(spacing: 10) {
                quickButton(tr("Projetor 3D"), "cube") { app.newMoveisProject() }
                quickButton(tr("Nota"), "square.and.pencil") { app.noteAsk = NoteAsk(kind: "") }
                quickButton(tr("Orçamento"), "dollarsign.circle") { app.screen = .quotes }
            }
        }
    }

    private func quickButton(_ label: String, _ icon: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(Ui.gold)
                Text(label).font(.footnote.weight(.semibold)).foregroundColor(Ui.text).lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity).frame(height: 70)
            .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Ui.line))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var sectionTitle: String {
        switch app.filter {
        case .trash: return tr("Lixo")
        case .folder(let f): return app.index.folders.first(where: { $0.id == f })?.name ?? tr("Pastas")
        case .all: return home == .projetos ? tr("Projetos") : tr("Clientes")
        }
    }

    private func setSort(_ recent: Bool) {
        if home == .projetos { projRecent = recent } else { cliRecent = recent }
    }

    private func sectionHeader(_ count: Int) -> some View {
        HStack {
            Text(sectionTitle + " (\(count))").font(.headline).foregroundColor(Ui.text).lineLimit(1)
            Spacer()
            Menu {
                Button((sortRecent ? "" : "✓ ") + tr("Nome (A-Z)")) { setSort(false) }
                Button((sortRecent ? "✓ " : "") + tr("Mais recentes")) { setSort(true) }
            } label: {
                HStack(spacing: 4) {
                    Text(tr("Ordenar"))
                    Image(systemName: "chevron.down").font(.caption.weight(.semibold))
                }
                .font(.subheadline.weight(.semibold)).foregroundColor(Ui.gold)
            }
        }
        .padding(.horizontal, 4).padding(.top, 4)
    }

    // ---------------- Botão "+" e barra de abas ----------------

    private var fab: some View {
        Menu {
            Button { app.noteAsk = NoteAsk(kind: "") } label: { Label(tr("Criar nota"), systemImage: "square.and.pencil") }
            Button { app.noteAsk = NoteAsk(kind: "gallery") } label: { Label(tr("Importar imagem"), systemImage: "photo") }
            Button { app.noteAsk = NoteAsk(kind: "camera") } label: { Label(tr("Tirar fotografia"), systemImage: "camera") }
            Button { newFolder = true } label: { Label(tr("Criar nova pasta"), systemImage: "folder.badge.plus") }
        } label: {
            Image(systemName: "plus").font(.system(size: 26, weight: .semibold)).foregroundColor(Ui.bg)
                .frame(width: 58, height: 58)
                .background(Circle().fill(Ui.gold))
                .shadow(color: Color.black.opacity(0.35), radius: 8, y: 3)
        }
        .padding(20)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            barItem(tr("Organização"), "folder", home == .clientes) { home = .clientes }
            barItem(tr("Projetos"), "pencil.and.ruler", home == .projetos) { home = .projetos }
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
            }
            .foregroundColor(sel ? Ui.gold : Ui.dim)
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
        [
            HomeMenuItem(icon: "cube", label: tr("Novo Projetor 3D"), action: { afterSheet { app.newMoveisProject() } }),
            HomeMenuItem(icon: "calendar", label: tr("Agenda"), action: { afterSheet { app.screen = .agenda } }),
            HomeMenuItem(icon: "dollarsign.circle", label: tr("Orçamentos"), action: { afterSheet { app.screen = .quotes } }),
            HomeMenuItem(icon: "ruler", label: tr("Trena Bosch"), action: { afterSheet { btOpen = true } }),
            HomeMenuItem(icon: "iphone.radiowaves.left.and.right", label: tr("Ver projeto de outro iPhone"), action: { afterSheet { peerView = true } }),
            HomeMenuItem(icon: "folder.badge.plus", label: tr("Nova pasta"), action: { afterSheet { newFolder = true } }),
            HomeMenuItem(icon: "trash", label: tr("Lixo"), action: { toolsOpen = false; app.filter = .trash }),
        ]
    }

    private var settingsItems: [HomeMenuItem] {
        [
            HomeMenuItem(icon: "archivebox", label: tr("Fazer backup completo (ZIP)"), action: { afterSheet { shareURL = app.makeBackup() } }),
            HomeMenuItem(icon: "arrow.counterclockwise", label: tr("Restaurar backup"), action: { afterSheet { restorePick = true } }),
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

/// Pasta na tela "Todas as notas": toque abre a pasta.
struct FolderTile: View {
    var name: String
    var count: Int
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "folder.fill").font(.title2).foregroundColor(Ui.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name).foregroundColor(Ui.text).lineLimit(1)
                    Text(tr(count == 1 ? "{0} item" : "{0} itens", count)).font(.caption).foregroundColor(Ui.dim)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(Ui.dim)
            }
            .padding(.horizontal, 14).frame(height: 64)
            .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
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
            .overlay(RoundedRectangle(cornerRadius: bare ? 10 : 6).stroke(Ui.gold.opacity(0.35)))
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(bare ? p.label : p.name).font(bare ? Font.subheadline.weight(.semibold) : Font.body).foregroundColor(Ui.text).lineLimit(1)
                statusMenu
            }
            if let o = originLine {
                Text(o).font(.caption).foregroundColor(Ui.gold).lineLimit(1)
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

/// Item da biblioteca: quadro do cliente, projeto solto ou nota solta.
enum LibEntry: Identifiable {
    case g(ClientGroup), p(MoveisProjects.P), n(NoteMeta)
    var id: String {
        switch self { case .g(let x): return "cli-" + x.id; case .p(let x): return "proj-" + x.id; case .n(let x): return "note-" + x.id }
    }
    var name: String {
        switch self { case .g(let x): return x.name; case .p(let x): return x.name; case .n(let x): return x.name }
    }
    var pinned: Bool { if case .n(let x) = self { return x.pinned }; return false }
    /// Data para "Mais recentes": projeto = última alteração; nota = criação; cliente = o mais novo dos dois.
    var date: Int64 {
        switch self {
        case .g(let x): return max(x.projs.map(\.updated).max() ?? 0, x.notes.map(\.createdMs).max() ?? 0)
        case .p(let x): return x.updated
        case .n(let x): return x.createdMs
        }
    }
}

/// Cliente com suas notas e projetos (nota e projeto ligados ficam com o mesmo nome, no mesmo quadro).
struct ClientGroup: Identifiable {
    var id: String
    var name: String
    var projs: [MoveisProjects.P]
    var notes: [NoteMeta]
    func matches(_ q: String) -> Bool { name.localizedCaseInsensitiveContains(q) || projs.contains { projMatches($0, q) } || notes.contains { $0.name.localizedCaseInsensitiveContains(q) } }
}

/// Busca no projeto: cliente, nome do projeto, ambiente, cidade e status.
func projMatches(_ p: MoveisProjects.P, _ q: String) -> Bool {
    [p.name, p.label, MoveisProjects.roomLabel(p.room), p.city, MoveisProjects.statusLabel(p.status)].contains { $0.localizedCaseInsensitiveContains(q) }
}

@MainActor func clientGroups(_ app: AppModel, _ projs: [MoveisProjects.P], _ notes: [NoteMeta]) -> [ClientGroup] {
    func k(_ s: String) -> String { s.trimmingCharacters(in: .whitespaces).lowercased() }
    var pk: [String: String] = [:]
    for p in projs { pk[p.id] = (app.isDefaultProj(p) || p.corte || p.cliente) ? "id:" + p.id : k(p.name) }
    var order: [String] = []
    var ps: [String: [MoveisProjects.P]] = [:], ns: [String: [NoteMeta]] = [:]
    for p in projs { let key = pk[p.id]!; if ps[key] == nil { order.append(key) }; ps[key, default: []].append(p) }
    for n in notes {
        let key = app.linkedProject(n.id).flatMap { pk[$0] } ?? (app.isDefaultNote(n.name) ? nil : k(n.name))
        if let key = key, ps[key] != nil { ns[key, default: []].append(n) }
    }
    return order.compactMap { key in
        let P = ps[key] ?? [], N = ns[key] ?? []
        if P.isEmpty || P.count + N.count < 2 { return nil }
        let name = P.first { !app.isDefaultProj($0) }?.name ?? N.first?.name ?? P[0].name
        return ClientGroup(id: key, name: name, projs: P.sorted { nameLess($0.label, $1.label) }, notes: N.sorted { nameLess($0.name, $1.name) })
    }
}

/// Quadro do cliente: nome e quantos projetos, a lista das notas e projetos dele e "＋ Novo projeto deste cliente".
struct ClientCard: View {
    @EnvironmentObject var app: AppModel
    var g: ClientGroup
    @State private var open = true

    private var rows: [LibEntry] { g.notes.map { LibEntry.n($0) } + g.projs.map { LibEntry.p($0) } }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            if open { itemList }
            newButton
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 16).fill(Ui.panel))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Ui.line))
    }

    private var header: some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { open.toggle() } } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.fill").font(.system(size: 16, weight: .semibold)).foregroundColor(Ui.gold)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Ui.gold.opacity(0.15)))
                VStack(alignment: .leading, spacing: 1) {
                    Text(g.name).font(.headline).foregroundColor(Ui.text).lineLimit(1)
                    Text(tr(g.projs.count == 1 ? "{0} projeto" : "{0} projetos", g.projs.count)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
                }
                Spacer()
                Image(systemName: open ? "chevron.up" : "chevron.down").font(.footnote.weight(.semibold)).foregroundColor(Ui.dim)
            }
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }

    private var itemList: some View {
        VStack(spacing: 0) {
            ForEach(rows) { e in
                VStack(spacing: 0) {
                    if e.id != rows.first?.id { Rectangle().fill(Ui.line).frame(height: 1).padding(.leading, 60) }
                    row(e)
                }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Ui.bg))
    }

    @ViewBuilder private func row(_ e: LibEntry) -> some View {
        switch e {
        case .n(let n): NoteRow(n: n, bare: true)
        case .p(let p): ProjRow(p: p, bare: true)
        case .g: EmptyView()
        }
    }

    private var newButton: some View {
        Button { app.newProjectForClient(g.name, g.notes.first?.id) } label: {
            Text(tr("＋ Novo projeto deste cliente")).font(.subheadline.weight(.semibold)).foregroundColor(Ui.gold)
                .frame(maxWidth: .infinity).frame(height: 44)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Ui.gold, lineWidth: 1.2))
                .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
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
                if n.pinned { Image(systemName: "pin.fill").font(.caption).foregroundColor(Ui.gold) }
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
