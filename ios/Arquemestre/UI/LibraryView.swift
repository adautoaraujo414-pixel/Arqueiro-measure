import SwiftUI
import StoreKit
import UniformTypeIdentifiers

private var dateFmt: DateFormatter { I18n.shared.dateFormatter(.date) }
private func dateText(_ ms: Int64) -> String { dateFmt.string(from: Date(timeIntervalSince1970: Double(ms) / 1000)) }

private enum LibTab: String, CaseIterable { case ALL = "TUDO", NOTE = "NOTA", MOVEIS = "MÓVEIS" }

/// Biblioteca (estilo Star Note, escura): notas, projetos de móveis, pastas.
struct LibraryView: View {
    @EnvironmentObject var app: AppModel
    @State private var query = ""
    @State private var tab: LibTab = .ALL
    @State private var newFolder = false
    @State private var shareURL: URL?
    @State private var restorePick = false
    @State private var confirmRestore: URL?
    @State private var peerView = false
    @State private var langOpen = false
    @State private var manageSub = false

    private var notes: [NoteMeta] {
        app.index.notes.filter {
            switch app.filter {
            case .all: return !$0.trash
            case .trash: return $0.trash
            case .folder(let f): return !$0.trash && $0.folderId == f
            }
        }
        .filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }
        .filter { _ in tab != .MOVEIS }
        .sorted { ($0.pinned ? 1 : 0, $0.createdMs) > ($1.pinned ? 1 : 0, $1.createdMs) }
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 700
            HStack(spacing: 0) {
                if wide { sidebar.frame(width: 230).background(Ui.panel) }
                content(wide: wide)
            }
        }
        .sheet(isPresented: $newFolder) { NameSheet(title: tr("Nova pasta"), label: tr("Nome da pasta"), text: "") { app.addFolder($0) } }
        .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
        .sheet(isPresented: $peerView) { PeerViewPicker() }
        .sheet(isPresented: $langOpen) { LanguagePicker() }
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

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                Text("ARQUEMESTRE").font(.subheadline.bold()).foregroundColor(Ui.text).padding(8)
                side(tr("Todas as notas"), "tray.full", app.filter == .all) { app.filter = .all }
                Text(tr("Pastas")).font(.caption).foregroundColor(Ui.dim).padding(.leading, 8).padding(.top, 12)
                ForEach(app.index.folders) { f in side(f.name, "folder", app.filter == .folder(f.id)) { app.filter = .folder(f.id) } }
                side(tr("Nova pasta"), "folder.badge.plus", false) { newFolder = true }
                Divider().padding(.vertical, 8)
                side(tr("Novo projeto de móveis"), "hammer", false) { app.newMoveisProject() }
                side(tr("Agenda"), "calendar", false) { app.screen = .agenda }
                side(tr("Orçamentos"), "doc.text", false) { app.screen = .quotes }
                side(tr("Lixo"), "trash", app.filter == .trash) { app.filter = .trash }
            }.padding(12)
        }
    }

    private func side(_ label: String, _ icon: String, _ sel: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).foregroundColor(sel ? Ui.accent : Ui.dim).frame(width: 20)
                Text(label).foregroundColor(Ui.text).lineLimit(1)
                Spacer()
            }
            .padding(10).background(RoundedRectangle(cornerRadius: 10).fill(sel ? Ui.panel2 : .clear))
        }.buttonStyle(.plain)
    }

    private func content(wide: Bool) -> some View {
        let projList = app.moveisProjects()
        _ = app.projVersion
        let pairs: [(MoveisProjects.P, [NoteMeta])] = (tab == .ALL && app.filter != .trash) ? projList.compactMap { pj in
            let ns = notes.filter { n in app.linkedProject(n.id) == pj.id || (!pj.auto && n.name.trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(pj.name.trimmingCharacters(in: .whitespaces)) == .orderedSame) }
            if ns.isEmpty { return nil }
            if !query.isEmpty && !pj.name.localizedCaseInsensitiveContains(query) && !ns.contains(where: { $0.name.localizedCaseInsensitiveContains(query) }) { return nil }
            return (pj, ns)
        } : []
        let paired = Set(pairs.flatMap { $0.1.map(\.id) })
        let inPair = Set(pairs.map { $0.0.id })
        let projs = (app.filter == .all && tab != .NOTE) ? projList.filter { !inPair.contains($0.id) && (query.isEmpty || $0.name.localizedCaseInsensitiveContains(query)) } : []
        return ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(Ui.dim)
                        TextField(tr("Pesquisar"), text: $query).foregroundColor(Ui.text)
                    }
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Ui.panel2))
                    Menu {
                        Button(tr("Editor de móveis")) { app.newMoveisProject() }
                        Button(tr("Agenda")) { app.screen = .agenda }
                        Button(tr("Orçamentos")) { app.screen = .quotes }
                        Divider()
                        Button(tr("Fazer backup completo (ZIP)")) { shareURL = app.makeBackup() }
                        Button(tr("Restaurar backup")) { restorePick = true }
                        Divider()
                        Button(tr("Ver projeto de outro iPhone")) { peerView = true }
                        Divider()
                        Button(langMenuLabel() + " (" + currentLangName() + ")") { langOpen = true }
                        Button(tr("Gerenciar assinatura")) { manageSub = true }
                        Link(tr("Ajuda e suporte"), destination: SiteLinks.support)
                        Link(tr("Privacidade"), destination: SiteLinks.privacy)
                    } label: {
                        Image(systemName: "ellipsis.circle").font(.title2).foregroundColor(Ui.text).frame(width: 44, height: 44)
                    }
                }.padding(12)
                if !wide {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            chip(tr("📅 Agenda"), false) { app.screen = .agenda }
                            chip(tr("+ Projeto de móveis"), false) { app.newMoveisProject() }
                            chip(tr("Todas as notas"), app.filter == .all) { app.filter = .all }
                            ForEach(app.index.folders) { f in chip(f.name, app.filter == .folder(f.id)) { app.filter = .folder(f.id) } }
                            chip(tr("Lixo"), app.filter == .trash) { app.filter = .trash }
                            chip(tr("Orçamentos"), false) { app.screen = .quotes }
                        }.padding(.horizontal, 12)
                    }
                }
                HStack(spacing: 20) {
                    ForEach(LibTab.allCases, id: \.self) { t in
                        Button { tab = t } label: {
                            VStack(spacing: 4) {
                                Text(tr(t.rawValue)).font(.footnote).foregroundColor(tab == t ? Ui.text : Ui.dim)
                                Rectangle().fill(tab == t ? Ui.accent : .clear).frame(width: 28, height: 2)
                            }
                        }.buttonStyle(.plain)
                    }
                    Spacer()
                }.padding(.horizontal, 12).padding(.vertical, 8)
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 10)], spacing: 10) {
                        if app.filter != .trash && query.isEmpty && tab != .MOVEIS {
                            CreateTile(label: tr("Criar")) { app.openNote(app.createNote()) }
                        }
                        if tab == .MOVEIS && query.isEmpty { CreateTile(label: tr("Novo projeto de móveis")) { app.newMoveisProject() } }
                        ForEach(pairs, id: \.0.id) { pr in ClientPair(p: pr.0, notes: pr.1) }
                        ForEach(projs) { pj in ProjRow(p: pj) }
                        ForEach(notes.filter { !paired.contains($0.id) }) { n in NoteRow(n: n) }
                    }
                    .padding(.horizontal, 12).padding(.top, 4).padding(.bottom, 110)
                }
            }
            if app.filter != .trash {
                Menu {
                    Button { app.openNote(app.createNote()) } label: { Label(tr("Criar nota"), systemImage: "square.and.pencil") }
                    Button { let id = app.createNote(); app.pendingImport = "gallery"; app.openNote(id) } label: { Label(tr("Importar imagem"), systemImage: "photo") }
                    Button { let id = app.createNote(); app.pendingImport = "camera"; app.openNote(id) } label: { Label(tr("Tirar fotografia"), systemImage: "camera") }
                    Button { newFolder = true } label: { Label(tr("Criar nova pasta"), systemImage: "folder.badge.plus") }
                } label: {
                    Image(systemName: "plus").font(.system(size: 26, weight: .semibold)).foregroundColor(.white)
                        .frame(width: 58, height: 58).background(Circle().fill(Ui.accent))
                }
                .padding(20)
            }
        }
    }

    private func chip(_ t: String, _ sel: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            Text(t).font(.subheadline).foregroundColor(sel ? .white : Ui.text)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(sel ? Ui.accent.opacity(0.5) : Ui.panel2))
        }.buttonStyle(.plain)
    }
}

struct CreateTile: View {
    var label: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack { Image(systemName: "plus"); Text(label) }
                .foregroundColor(Ui.dim).frame(maxWidth: .infinity).frame(height: 96)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(argb: 0xFF6B7078), style: StrokeStyle(lineWidth: 2, dash: [9, 6])))
        }.buttonStyle(.plain)
    }
}

struct ProjRow: View {
    @EnvironmentObject var app: AppModel
    var p: MoveisProjects.P
    var bare = false
    @State private var rename = false
    @State private var del = false
    var body: some View {
        let linked = app.notesOfProject(p.id).count
        HStack(spacing: bare ? 8 : 12) {
            Text("🪚").font(.system(size: bare ? 20 : 26)).frame(width: bare ? 44 : 56, height: bare ? 64 : 76)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color(argb: 0xFF2B2416)))
            VStack(alignment: .leading, spacing: 2) {
                Text(bare ? tr("Projeto de móveis") : p.name).foregroundColor(Ui.text).lineLimit(1)
                Text((bare ? "" : tr("Projeto de móveis · ")) + dateText(p.updated)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
                Text(tr(p.mods == 1 ? "{0} módulo" : "{0} módulos", p.mods) + (linked > 0 && !bare ? tr(linked == 1 ? " · {0} nota" : " · {0} notas", linked) : ""))
                    .font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            }
            Spacer()
            Menu {
                Button(tr("Abrir")) { app.openProject(p.id) }
                Button(tr("Renomear (nome do cliente)")) { rename = true }
                Button(tr("Nova nota ligada a este projeto")) { app.lastProjectId = p.id; app.openNote(app.createNote()) }
                Button(tr("Apagar projeto"), role: .destructive) { del = true }
            } label: { Image(systemName: "chevron.down").foregroundColor(Ui.text).frame(width: 40, height: 40) }
        }
        .padding(bare ? 8 : 10).frame(height: 96)
        .background(RoundedRectangle(cornerRadius: 14).fill(bare ? Color.clear : Ui.panel))
        .contentShape(Rectangle())
        .onTapGesture { app.openProject(p.id) }
        .sheet(isPresented: $rename) { NameSheet(title: tr("Nome do projeto"), label: tr("Cliente / projeto"), text: p.auto ? "" : p.name) { app.renameMoveisProject(p.id, $0) } }
        .alert(tr("Apagar este projeto?"), isPresented: $del) {
            Button(tr("Cancelar"), role: .cancel) {}
            Button(tr("Apagar"), role: .destructive) { app.deleteMoveisProject(p.id) }
        } message: { Text(tr("\"{0}\" sai da lista de projetos de móveis. Isso não pode ser desfeito.", p.name)) }
    }
}

struct ClientPair: View {
    var p: MoveisProjects.P
    var notes: [NoteMeta]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("👤 " + p.name).foregroundColor(Ui.text).lineLimit(1).padding(.horizontal, 12).padding(.top, 8)
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) { ForEach(notes) { NoteRow(n: $0, bare: true) } }.frame(maxWidth: .infinity)
                Rectangle().fill(Ui.line).frame(width: 1).padding(.vertical, 10)
                ProjRow(p: p, bare: true).frame(maxWidth: .infinity)
            }
        }
        .background(RoundedRectangle(cornerRadius: 14).fill(Ui.panel))
    }
}

struct NoteRow: View {
    @EnvironmentObject var app: AppModel
    var n: NoteMeta
    var bare = false
    @State private var rename = false
    @State private var move = false
    @State private var confirmDelete = false

    var body: some View {
        let _ = app.thumbVersion
        HStack(spacing: bare ? 8 : 12) {
            ZStack {
                Color.white
                if let t = app.loadThumb(n.id) { Image(uiImage: t).resizable().scaledToFill() }
            }
            .frame(width: bare ? 44 : 56, height: bare ? 64 : 76).clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Ui.line))
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(n.name).foregroundColor(Ui.text).lineLimit(1)
                    if n.pinned { Image(systemName: "pin.fill").font(.caption).foregroundColor(Ui.accent) }
                    if n.locked { Image(systemName: "lock.fill").font(.caption).foregroundColor(Ui.dim) }
                }
                Text(dateText(n.createdMs)).font(.caption).foregroundColor(Ui.dim)
                Text(tr(n.pageCount == 1 ? "{0} folha" : "{0} folhas", n.pageCount) + " · " + tr(n.dimCount == 1 ? "{0} cota" : "{0} cotas", n.dimCount)).font(.caption).foregroundColor(Ui.dim).lineLimit(1)
            }
            Spacer()
            Menu {
                if n.trash {
                    Button(tr("Restaurar")) { app.trashNote(n.id, false) }
                    Button(tr("Apagar para sempre"), role: .destructive) { confirmDelete = true }
                } else {
                    Button(tr("Editar nome")) { rename = true }
                    Button(tr("Copiar")) { app.copyNote(n.id) }
                    Button(n.pinned ? tr("Desafixar nota") : tr("Fixar nota")) { app.pinNote(n.id, !n.pinned) }
                    Button(tr("Mover para")) { move = true }
                    Button(n.locked ? tr("Remover bloqueio") : tr("Adicionar bloqueio")) { app.lockNote(n.id, !n.locked) }
                    Divider()
                    Button(tr("Mover para o lixo"), role: .destructive) { app.trashNote(n.id, true) }
                }
            } label: { Image(systemName: "chevron.down").foregroundColor(Ui.text).frame(width: 40, height: 40) }
        }
        .padding(bare ? 8 : 10).frame(height: 96)
        .background(RoundedRectangle(cornerRadius: 14).fill(bare ? Color.clear : Ui.panel))
        .contentShape(Rectangle())
        .onTapGesture { if !n.trash { app.openNote(n.id) } }
        .sheet(isPresented: $rename) { NameSheet(title: tr("Editar nota"), label: tr("Nome"), text: n.name) { app.renameNote(n.id, $0) } }
        .confirmationDialog(tr("Mover para"), isPresented: $move) {
            Button(tr("Sem pasta")) { app.moveNote(n.id, nil) }
            ForEach(app.index.folders) { f in Button(f.name) { app.moveNote(n.id, f.id) } }
        }
        .alert(tr("Apagar para sempre?"), isPresented: $confirmDelete) {
            Button(tr("Cancelar"), role: .cancel) {}
            Button(tr("Apagar"), role: .destructive) { app.deleteForever(n.id) }
        }
    }
}
