import SwiftUI
import UIKit
import WebKit

enum Screen: Equatable { case library, editor, quotes, agenda, moveis }
enum LibFilter: Equatable { case all, trash, folder(String) }

/// Estado do app inteiro (o "AppViewModel" do Android).
@MainActor
final class AppModel: ObservableObject {
    let store = Store()
    let ble = BoschBLE()
    let peer = PeerShare()
    let license = LicenseManager()

    @Published var index: LibIndex
    @Published var screen: Screen = .library
    /// Guia passo a passo: aparece sozinho na primeira vez (e no menu da biblioteca).
    @Published var showGuide = !UserDefaults.standard.bool(forKey: "arque.guideSeen") && !ProcessInfo.processInfo.arguments.contains("-demo")
    @Published var filter: LibFilter = .all
    @Published private(set) var session: EditorSession?
    @Published var tabs: [String] = []
    @Published var toast: String? { didSet { if toast != nil { scheduleToastClear() } } }
    @Published var thumbVersion = 0

    /// Leituras da trena ainda não ligadas a uma cota (mais nova primeiro).
    @Published var recent: [Reading]
    @Published var trenaHidden = UserDefaults.standard.bool(forKey: "trenaHidden")
    @Published var trenaScale: CGFloat = {
        let v = UserDefaults.standard.double(forKey: "trenaScale")
        return v > 0 ? clamp(CGFloat(v), 0.5, 1.3) : 0.8
    }()

    var photoToNewPage = false
    @Published var pendingImport: String?
    @Published var askAnotherPhoto = false

    // agenda
    @Published private(set) var appointments: [Appointment]
    @Published var agendaOpenId: String?

    // orçamentos
    @Published private(set) var company: Company
    @Published private(set) var quotes: [Quote]
    @Published private(set) var logo: UIImage?

    // editor de móveis
    @Published var projVersion = 0
    var lastProjectId: String?
    @Published var pendingNewProject = false
    @Published var pendingProject: String?
    /// Código do plano de corte recebido pelo link do WhatsApp; o editor abre ele no modo corte.
    @Published var pendingCut: String?
    /// Convite pronto pra mandar (abre a folha de compartilhar: WhatsApp e outros).
    @Published var cutShareText: String?
    nonisolated static let cutPrefix = "arquemestre-corte:"
    nonisolated static let cutURL = "https://adautoaraujo414-pixel.github.io/Arqueiro-measure/corte.html#d="

    nonisolated private static func cutCh(_ c: Character) -> Bool { c.isASCII && (c.isLetter || c.isNumber || c == "-" || c == "_") }
    /// Código do plano de corte num texto: o link do convite (…corte.html#d=…), arquemestre://corte?d=… ou "arquemestre-corte:…".
    nonisolated static func cutCode(from text: String) -> String? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw: Substring
        if t.hasPrefix(cutPrefix) { raw = t.dropFirst(cutPrefix.count) }
        else if let r = t.range(of: "corte.html#d=") { raw = t[r.upperBound...] }
        else if t.hasPrefix("arquemestre://corte"), let r = t.range(of: "d=") { raw = t[r.upperBound...] }
        else { return nil }
        let c = String(raw.prefix(while: cutCh))
        return c.count >= 8 ? c : nil
    }

    func openCutLink(_ code: String) {
        let t = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let c = AppModel.cutCode(from: t) ?? ((t.count >= 8 && t.allSatisfy(AppModel.cutCh)) ? t : nil) else {
            toast = tr("Link do plano de corte incompleto. Peça pra enviar de novo."); return
        }
        if session != nil { flush() }
        pendingProject = nil; pendingNewProject = false
        pendingCut = c
        screen = .moveis
    }

    /// Texto do convite (WhatsApp): o link abre o app; quem não tem baixa o Arquemestre.
    func cutInvite(_ code: String, _ name: String, _ title: String) -> String {
        let who = company.name.trimmingCharacters(in: .whitespaces)
        let proj = [name, title].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }.joined(separator: " · ")
        let suf = proj.isEmpty ? "" : " (\(proj))"
        let head = who.isEmpty ? tr("📐 Você recebeu um plano de corte{0} no Arquemestre.", suf) : tr("📐 {0} te mandou o plano de corte{1} no Arquemestre.", who, suf)
        return head + "\n\n" + tr("Toque no link pra abrir (se ainda não tem o app, ele leva pra baixar o Arquemestre):") + "\n" + AppModel.cutURL + code
    }

    /// Quem ainda não tinha o app: a página do convite copia o link antes de mandar pra App Store.
    /// Na primeira abertura, se tem um link copiado, o app mostra um botão "Colar" do sistema (PasteButton):
    /// o app só lê o que está copiado se a pessoa tocar nele (sem o aviso "Permitir colar?").
    @Published var cutPasteOffer = false

    func checkCutClipboard() {
        let k = "arque.cutclip"
        if UserDefaults.standard.bool(forKey: k) || ProcessInfo.processInfo.arguments.contains("-demo") { return }
        UserDefaults.standard.set(true, forKey: k)
        // só confere SE tem um link copiado (não lê o conteúdo)
        let web: Set<PartialKeyPath<UIPasteboard.DetectedValues>> = [\UIPasteboard.DetectedValues.probableWebURL]
        Task { @MainActor [weak self] in
            guard let found = try? await UIPasteboard.general.detectedPatterns(for: web),
                  found.contains(\UIPasteboard.DetectedValues.probableWebURL) else { return }
            self?.cutPasteOffer = true
        }
    }

    /// Tocou no "Colar" do aviso: abre o plano de corte se o que foi copiado for o link do convite.
    func pastedCut(_ items: [String]) {
        cutPasteOffer = false
        guard let s = items.first(where: { AppModel.cutCode(from: $0) != nil }) else {
            toast = tr("O que está copiado não é um link de plano de corte."); return
        }
        openCutLink(s)
    }
    @Published var moveisView = false
    var moveisSink: ((Double) -> Void)?
    private var links: [String: String]

    private var saveWork: DispatchWorkItem?
    private let io = DispatchQueue(label: "arque.io", qos: .userInitiated)
    private var toastWork: DispatchWorkItem?

    static let MAX_RECENT = 30

    init() {
        index = store.loadIndex()
        recent = store.loadReadings()
        appointments = store.loadAgenda().sorted { $0.startMs < $1.startMs }
        company = store.loadCompany()
        quotes = store.loadQuotes()
        logo = UIImage(contentsOfFile: store.logoFile.path)
        links = store.loadLinks()
        ble.onReading = { [weak self] r in Task { @MainActor in self?.onReading(r) } }
        Reminders.rescheduleAll(appointments)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-demo") {
            DemoData.seedIfEmpty(self)
            if let i = args.firstIndex(of: "-screen"), i + 1 < args.count {
                switch args[i + 1] {
                case "editor": if let n = index.notes.first(where: { $0.name.hasPrefix(tr("Cozinha")) }) { openNote(n.id) }
                case "agenda": screen = .agenda
                case "quotes": screen = .quotes
                case "moveis": screen = .moveis
                default: break
                }
            }
        }
        #endif
    }

    /// Capturas automáticas: não pede permissões (o aviso cobriria a tela).
    static var isDemo: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-demo")
        #else
        return false
        #endif
    }

    private func scheduleToastClear() {
        toastWork?.cancel()
        let w = DispatchWorkItem { [weak self] in self?.toast = nil }
        toastWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6, execute: w)
    }

    func setTrenaHidden(_ v: Bool) { trenaHidden = v; UserDefaults.standard.set(v, forKey: "trenaHidden") }
    func setTrenaScale(_ v: CGFloat) { trenaScale = clamp(v, 0.5, 1.3); UserDefaults.standard.set(Double(trenaScale), forKey: "trenaScale") }

    // ---------- biblioteca ----------
    private func updateIndex(_ n: LibIndex) {
        index = n
        let s = store
        io.async { s.saveIndex(n) }
    }

    func addFolder(_ name: String) {
        let t = name.trimmingCharacters(in: .whitespaces)
        if t.isEmpty { return }
        var n = index; n.folders.append(Folder(name: t)); updateIndex(n)
    }

    private func upsertMeta(_ note: Note) {
        var n = index
        let m = note.meta()
        if let i = n.notes.firstIndex(where: { $0.id == note.id }) { n.notes[i] = m } else { n.notes.append(m) }
        updateIndex(n)
    }

    @discardableResult
    func createNote() -> String {
        var folder: String?
        if case .folder(let f) = filter { folder = f }
        // nota nova ligada a um projeto já nasce com o nome do cliente
        let proj = lastProjectId.flatMap { pid in moveisProjects().first { $0.id == pid } }.flatMap { defaultProjName($0) ? nil : $0 }
        let n = Note(name: proj?.name ?? tr("Nota {0}", index.notes.filter { !$0.trash }.count + 1), folderId: folder)
        if let p = lastProjectId {
            links[n.id] = p
            store.saveLinks(links)
            if let pr = proj { setLinkName(n.id, pr.name) }
            projVersion += 1
        }
        store.saveNote(n)
        upsertMeta(n)
        writeThumb(n)
        return n.id
    }

    private func closeIfOpen(_ id: String) {
        if session?.state.note.id == id { flush(); session = nil }
        tabs.removeAll { $0 == id }
    }

    private func mutateNote(_ id: String, _ f: @escaping (inout Note) -> Void) {
        closeIfOpen(id)
        if tabs.isEmpty && screen == .editor { screen = .library }
        guard var n = store.loadNote(id) else { return }
        f(&n)
        store.saveNote(n)
        upsertMeta(n)
    }

    func renameNote(_ id: String, _ name: String) {
        let t = name.trimmingCharacters(in: .whitespaces); if t.isEmpty { return }
        mutateNote(id) { $0.name = t }
    }
    func pinNote(_ id: String, _ v: Bool) { mutateNote(id) { $0.pinned = v } }
    func lockNote(_ id: String, _ v: Bool) { mutateNote(id) { $0.locked = v } }
    func moveNote(_ id: String, _ folder: String?) { mutateNote(id) { $0.folderId = folder } }
    func trashNote(_ id: String, _ v: Bool) { mutateNote(id) { $0.trash = v } }

    func deleteForever(_ id: String) {
        closeIfOpen(id)
        store.deleteNote(id)
        var n = index; n.notes.removeAll { $0.id == id }; updateIndex(n)
    }

    func copyNote(_ id: String) {
        guard var c = store.loadNote(id) else { return }
        c.id = newId(); c.name += tr(" (cópia)"); c.createdMs = nowMs(); c.pinned = false; c.trash = false
        store.saveNote(c)
        upsertMeta(c)
        writeThumb(c)
    }

    // ---------- editor ----------
    func openNote(_ id: String) {
        guard let meta = index.notes.first(where: { $0.id == id }) else { return }
        if meta.locked { toast = tr("Nota bloqueada. Remova o bloqueio no menu da nota."); return }
        if session?.state.note.id == id { screen = .editor; return }
        guard let note = store.loadNote(id) else { toast = tr("Não foi possível abrir a nota"); return }
        flush()
        session = EditorSession(note) { [weak self] n in self?.scheduleSave(n) }
        if !tabs.contains(id) { tabs.append(id) }
        screen = .editor
    }

    func closeTab(_ id: String) {
        closeIfOpen(id)
        if let next = tabs.last { openNote(next) } else { screen = .library }
    }

    func closeEditor() { flush(); screen = .library }

    func tabName(_ id: String) -> String { index.notes.first { $0.id == id }?.name ?? tr("Nota") }

    private func scheduleSave(_ note: Note) {
        saveWork?.cancel()
        let w = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let s = self.store
            self.io.async { s.saveNote(note) }
            self.upsertMeta(note)
            self.writeThumb(note)
        }
        saveWork = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: w)
    }

    /// Grava agora (ao sair da nota ou do app).
    func flush() {
        guard let s = session else { return }
        saveWork?.cancel()
        let n = s.state.note
        let st = store
        io.async { st.saveNote(n) }
        upsertMeta(n)
        writeThumb(n)
    }

    // ---------- miniaturas ----------
    private func thumbFile(_ id: String) -> URL { store.thumbsDir.appendingPathComponent("\(id).png") }

    private func writeThumb(_ note: Note) {
        let url = thumbFile(note.id)
        DispatchQueue.global(qos: .utility).async {
            let img = Export.thumb(note)
            try? img.pngData()?.write(to: url)
            DispatchQueue.main.async { self.thumbVersion &+= 1 }
        }
    }

    func loadThumb(_ id: String) -> UIImage? { UIImage(contentsOfFile: thumbFile(id).path) }

    // ---------- fotos ----------
    private func placePhoto(_ s: EditorSession, _ name: String, _ w: Int, _ h: Int) {
        if photoToNewPage {
            photoToNewPage = false
            s.state.addPage(s.state.note.pages.count, .BLANK)
            s.goToPage(s.state.pageIdx)
        }
        s.addPhoto(name, w, h)
    }

    private func importPhoto(_ data: Data, ext: String) -> (String, Int, Int)? {
        guard let name = try? store.importImage(data: data, ext: ext), let size = ImageCache.orientedSize(store.imageFile(name)) else { return nil }
        return (name, size.0, size.1)
    }

    func addPhotos(_ datas: [(Data, String)]) {
        guard let s = session else { return }
        if datas.isEmpty { photoToNewPage = false; return }
        if datas.count == 1 {
            if let r = importPhoto(datas[0].0, ext: datas[0].1) { placePhoto(s, r.0, r.1, r.2) } else { toast = tr("Não foi possível adicionar a foto") }
            return
        }
        let newPage = photoToNewPage
        photoToNewPage = false
        var ok: [(String, Int, Int)] = []
        var fail = 0
        for (d, e) in datas { if let r = importPhoto(d, ext: e) { ok.append(r) } else { fail += 1 } }
        let placed = s.addPhotos(ok, newPage: newPage)
        toast = tr("{0} fotos adicionadas", placed) + (fail > 0 ? tr(" · {0} não abriram", fail) : "") + (placed < ok.count ? tr(" · limite de folhas atingido") : "")
    }

    /// Foto da câmera: guarda também na galeria do iPhone (não se perde).
    func addCameraPhoto(_ img: UIImage) {
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        guard let d = img.jpegData(compressionQuality: 0.92) else { return }
        guard let s = session, let r = importPhoto(d, ext: "jpg") else { toast = tr("Não foi possível adicionar a foto"); return }
        placePhoto(s, r.0, r.1, r.2)
        askAnotherPhoto = true
    }

    // ---------- leituras da trena ----------
    private func persistRecent() { let l = recent, s = store; io.async { s.saveReadings(l) } }

    private func onReading(_ r: Reading) {
        if let sink = moveisSink, screen == .moveis { sink(r.mm); return }
        if let s = session, screen == .editor, s.state.assignReading(r) != nil { return }
        recent.insert(r, at: 0)
        if recent.count > AppModel.MAX_RECENT { recent.removeLast(recent.count - AppModel.MAX_RECENT) }
        persistRecent()
    }

    func applyRecent(_ r: Reading) {
        guard let s = session else { return }
        if s.state.assignReading(r) != nil { recent.removeAll { $0.id == r.id }; persistRecent() } else { toast = tr("Toque numa seta de cota primeiro") }
    }

    func onDimTap(_ id: String) {
        guard let s = session, let d = s.state.selected?.asDim, d.id == id, !d.locked, d.valueMm == nil, let r = recent.first else { return }
        if s.state.assignReading(r) != nil { recent.removeFirst(); persistRecent() }
    }

    func onSegTap(_ id: String, _ seg: Int) {
        guard let s = session, let r = s.state.selected?.asRoom, r.id == id, !r.locked, r.segs.indices.contains(seg), r.segs[seg].valueMm == nil, let rd = recent.first else { return }
        if s.state.assignReading(rd) != nil { recent.removeFirst(); persistRecent() }
    }

    func discardRecent(_ r: Reading) { recent.removeAll { $0.id == r.id }; persistRecent() }

    // ---------- exportar ----------
    func exportPdf() -> URL? {
        guard let s = session else { return nil }
        flush()
        let url = Export.tempURL("\(s.state.note.name).pdf")
        do { try Export.pdf(s.state.note, to: url); return url } catch { toast = tr("Falhou: {0}", error.localizedDescription); return nil }
    }

    func exportPng() -> URL? {
        guard let s = session else { return nil }
        let url = Export.tempURL("\(s.state.note.name).png")
        do { try Export.png(s.state.note, page: s.state.pageIdx, to: url); return url } catch { toast = tr("Falhou ao gerar a imagem"); return nil }
    }

    func exportCsv() -> URL? {
        guard let s = session else { return nil }
        let url = Export.tempURL("\(s.state.note.name)-medidas.csv")
        do { try Data(Export.csv(s.state.note).utf8).write(to: url); return url } catch { return nil }
    }

    func makeBackup() -> URL? {
        flush()
        // O flush grava na fila de disco; termina as gravações antes de copiar os dados.
        io.sync {}
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        let url = Export.tempURL("arquemestre-backup-\(df.string(from: Date())).zip")
        do { try DataBackup.fullBackup(to: url); return url } catch { toast = tr("Falhou o backup: {0}", error.localizedDescription); return nil }
    }

    func restore(from url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        flush()
        do {
            // Nenhuma gravação da versão anterior pode alcançar a pasta já restaurada.
            io.sync {}
            try DataBackup.restore(from: url)
            session = nil
            tabs = []
            index = store.loadIndex()
            recent = store.loadReadings()
            appointments = store.loadAgenda().sorted { $0.startMs < $1.startMs }
            company = store.loadCompany()
            quotes = store.loadQuotes()
            logo = UIImage(contentsOfFile: store.logoFile.path)
            links = store.loadLinks()
            Reminders.rescheduleAll(appointments)
            // o editor de móveis relê os projetos do arquivo restaurado
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {}
            projVersion += 1
            screen = .library
            toast = tr("Backup restaurado")
        } catch {
            toast = (error as? LocalizedError)?.errorDescription ?? tr("Backup inválido: nada foi alterado")
        }
    }

    // ---------- agenda ----------
    func saveAppt(_ a: Appointment) {
        if let i = appointments.firstIndex(where: { $0.id == a.id }) { appointments[i] = a } else { appointments.append(a) }
        appointments.sort { $0.startMs < $1.startMs }
        let l = appointments, s = store
        io.async { s.saveAgenda(l) }
        if !AppModel.isDemo { Reminders.requestPermission() }
        Reminders.rescheduleAll(appointments)
    }

    func deleteAppt(_ id: String) {
        appointments.removeAll { $0.id == id }
        let l = appointments, s = store
        io.async { s.saveAgenda(l) }
        Reminders.rescheduleAll(appointments)
    }

    func openAppointment(_ id: String) { agendaOpenId = id; screen = .agenda }

    func knownClients() -> [ClientRef] {
        let proj = MoveisProjects.clients()
        let have = Set(proj.map { $0.name.lowercased() })
        var seen = Set<String>()
        let fromQuotes = quotes.map { $0.clientName.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !have.contains($0.lowercased()) && seen.insert($0.lowercased()).inserted }
            .map { ClientRef(name: $0) }
        return (proj + fromQuotes).sorted { $0.name.lowercased() < $1.name.lowercased() }
    }

    // ---------- projetos do editor de móveis ----------
    func moveisProjects() -> [MoveisProjects.P] { MoveisProjects.list() }
    func newMoveisProject() { pendingProject = nil; pendingNewProject = true; pendingNewName = nil; pendingLinkNote = nil; contextNoteId = nil; screen = .moveis }

    // ---------- nota ↔ projeto do mesmo cliente (acesso rápido) ----------
    /// Nota de onde a pessoa abriu o editor de móveis (o editor puxa o nome do cliente dela).
    var contextNoteId: String?
    /// Projeto novo já no nome do cliente (e a nota que fica ligada a ele quando o editor criar o projeto).
    var pendingNewName: String?
    var pendingLinkNote: String?

    func newProjectForClient(_ name: String, _ noteId: String?) {
        if session != nil { flush() }
        let t = name.trimmingCharacters(in: .whitespaces)
        pendingProject = nil; pendingNewProject = true
        pendingNewName = (t.isEmpty || defaultNoteName(t) || t.range(of: #"^(projeto|project|proyecto)\s+\d{1,2}/\d{1,2}"#, options: [.regularExpression, .caseInsensitive]) != nil) ? nil : t
        pendingLinkNote = noteId
        if let n = noteId { contextNoteId = n }
        screen = .moveis
    }
    func newProjectForNote(_ noteId: String) {
        guard let n = index.notes.first(where: { $0.id == noteId }) else { return }
        newProjectForClient(n.name, noteId)
    }
    /// O editor de móveis criou/abriu um projeto: liga a nota que estava esperando.
    func onEditorProject(_ id: String) {
        lastProjectId = id
        if let nid = pendingLinkNote { pendingLinkNote = nil; linkProject(nid, id) }
        projVersion += 1
    }
    /// Lista de notas pro editor procurar a nota do cliente (JSON).
    func notesJson() -> String {
        let df = DateFormatter(); df.dateStyle = .short; df.timeStyle = .none
        let arr: [[String: Any]] = index.notes.filter { !$0.trash }.sorted { $0.createdMs > $1.createdMs }.map { n in
            ["id": n.id, "name": n.name, "date": df.string(from: Date(timeIntervalSince1970: Double(n.createdMs) / 1000)), "proj": linkedProject(n.id) != nil]
        }
        return JsonCodec.string(arr)
    }
    /// Nota aberta (ou de onde veio): o editor já preenche o nome do cliente com ela.
    func contextNoteJson() -> String {
        guard let id = contextNoteId ?? session?.state.note.id, let n = index.notes.first(where: { $0.id == id && !$0.trash }), !defaultNoteName(n.name) else { return "" }
        return JsonCodec.string(["id": n.id, "name": n.name] as [String: Any])
    }
    /// "📝 Nota" no editor de móveis: abre a nota ligada ao projeto; se não tem, cria uma já no nome do cliente.
    func openNoteOf(_ projectId: String) {
        let nid = notesOfProject(projectId).first { id in index.notes.contains { $0.id == id && !$0.trash } }
        lastProjectId = projectId
        if let n = nid { openNote(n) } else { openNote(createNote()) }
    }
    func setProjectTitle(_ id: String, _ title: String) { MoveisProjects.setTitle(id, title); projVersion += 1 }
    /// Abre o projeto da nota direto (se ligada) — acesso rápido.
    @discardableResult
    func openProjectOfNote(_ noteId: String) -> Bool {
        guard let pid = linkedProject(noteId), moveisProjects().contains(where: { $0.id == pid }) else { return false }
        if session != nil { flush() }
        contextNoteId = noteId
        openProject(pid)
        return true
    }
    func isDefaultProj(_ p: MoveisProjects.P) -> Bool { defaultProjName(p) }
    func isDefaultNote(_ s: String) -> Bool { defaultNoteName(s) }
    func deleteMoveisProject(_ id: String) { MoveisProjects.delete(id); if lastProjectId == id { lastProjectId = nil }; projVersion += 1 }
    func renameMoveisProject(_ id: String, _ name: String) { MoveisProjects.rename(id, name); projVersion += 1 }
    /// Status do projeto (orc, fech, prod, fin), o mesmo que o editor grava em projects.json.
    func setProjectStatus(_ id: String, _ status: String) { MoveisProjects.setStatus(id, status); projVersion += 1 }
    func linkedProject(_ noteId: String) -> String? { links[noteId] }
    func linkProject(_ noteId: String, _ projectId: String?) {
        if let p = projectId { links[noteId] = p } else { links.removeValue(forKey: noteId) }
        store.saveLinks(links)
        if let p = projectId { _ = syncPair(noteId, p, moveisProjects()) } else { setLinkName(noteId, nil) }
        projVersion += 1
    }

    // ---------- nota e projeto do mesmo cliente ficam com o mesmo nome ----------

    /// Último nome em comum de cada par nota↔projeto (pra saber qual dos dois foi renomeado depois).
    private var linkNames: [String: String] {
        get { (UserDefaults.standard.dictionary(forKey: "arque.linknames") as? [String: String]) ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: "arque.linknames") }
    }
    private func setLinkName(_ noteId: String, _ name: String?) { var d = linkNames; d[noteId] = name; linkNames = d }

    private func defaultNoteName(_ s: String) -> Bool {
        let t = s.trimmingCharacters(in: .whitespaces)
        return t.isEmpty || t.range(of: #"^(nota|note)(\s+\d+)?(\s*\((cópia|copia|copy)\))*$"#, options: [.regularExpression, .caseInsensitive]) != nil
    }
    private func defaultProjName(_ p: MoveisProjects.P) -> Bool {
        p.auto || p.name.isEmpty || p.name == tr("Projeto sem nome") || p.name == "Projeto sem nome"
            || p.name.range(of: #"^(projeto|project|proyecto)\s+\d{1,2}/\d{1,2}"#, options: [.regularExpression, .caseInsensitive]) != nil
    }

    /// Junta o nome da nota e do projeto ligados: o nome de cliente (o que não é "Nota 3" nem "Projeto 26/10 19:46")
    /// vale pros dois. Se os dois têm nome, quem foi renomeado por último manda; na primeira vez, o da nota.
    private func syncPair(_ noteId: String, _ pid: String, _ projs: [MoveisProjects.P]) -> Bool {
        guard let n = index.notes.first(where: { $0.id == noteId && !$0.trash }), let p = projs.first(where: { $0.id == pid }) else { return false }
        let nName = n.name.trimmingCharacters(in: .whitespaces), pName = p.name.trimmingCharacters(in: .whitespaces)
        let nDef = defaultNoteName(nName), pDef = defaultProjName(p)
        let last = linkNames[noteId]
        var target: String?
        if nName == pName { target = (nDef && pDef) ? nil : nName }
        else if let l = last, nName == l, !pDef { target = pName }   // o projeto foi renomeado
        else if let l = last, pName == l, !nDef { target = nName }   // a nota foi renomeada
        else if !nDef { target = nName }
        else if !pDef { target = pName }
        guard let t = target else { return false }
        var changed = false
        if nName != t { renameNoteKeepOpen(noteId, t); changed = true }
        if pName != t || p.auto { MoveisProjects.rename(pid, t); changed = true }
        setLinkName(noteId, t)
        return changed
    }

    /// Confere todos os pares nota↔projeto (ao abrir a biblioteca, depois de renomear algo).
    func syncLinkedNames() {
        let projs = moveisProjects()
        var changed = false
        for (noteId, pid) in links where syncPair(noteId, pid, projs) { changed = true }
        if changed { projVersion += 1 }
    }

    /// Renomeia a nota sem fechar o editor se ela estiver aberta.
    private func renameNoteKeepOpen(_ id: String, _ name: String) {
        if let s = session, s.state.note.id == id {
            s.state.renameNoteSilently(name)
            upsertMeta(s.state.note)
            return
        }
        var ix = index
        if let i = ix.notes.firstIndex(where: { $0.id == id }) { ix.notes[i].name = name; updateIndex(ix) }
        let st = store
        io.async { if var n = st.loadNote(id) { n.name = name; st.saveNote(n) } }
    }
    func notesOfProject(_ pid: String) -> [String] { links.filter { $0.value == pid }.map(\.key) }
    func openProject(_ id: String) { pendingProject = id; screen = .moveis }

    // ---------- orçamentos ----------
    func setLogo(_ img: UIImage) {
        let k = min(1, 800 / max(img.size.width, img.size.height))
        let size = CGSize(width: max(1, img.size.width * k), height: max(1, img.size.height * k))
        let small = UIGraphicsImageRenderer(size: size).image { _ in img.draw(in: CGRect(origin: .zero, size: size)) }
        try? small.pngData()?.write(to: store.logoFile)
        logo = small
    }
    func clearLogo() { logo = nil; try? FileManager.default.removeItem(at: store.logoFile) }
    func saveCompany(_ c: Company) { company = c; let s = store; io.async { s.saveCompany(c) } }

    /// Orçamento criado pelo editor de móveis: abre direto nele; ao sair, volta pro projeto.
    var pendingQuoteId: String?
    var quotesBackProject: String?

    /// "Gerar orçamento em PDF" no editor de móveis: cliente, itens com o valor do projeto e observações.
    func quoteFromMoveis(_ json: String) {
        guard let d = json.data(using: .utf8), let o = (try? JSONSerialization.jsonObject(with: d)) as? [String: Any] else {
            toast = tr("Não consegui montar o orçamento."); return
        }
        let num: (Any?) -> Double = { v in (v as? NSNumber)?.doubleValue ?? Double(String(describing: v ?? "")) ?? 0 }
        var items: [QuoteItem] = ((o["items"] as? [[String: Any]]) ?? []).map { it in
            QuoteItem(desc: (it["desc"] as? String) ?? "", qty: it["qty"] == nil ? 1 : num(it["qty"]), unit: (it["unit"] as? String) ?? "un", unitValue: num(it["value"]))
        }
        if items.isEmpty { items = [QuoteItem()] }
        let pid = ((o["pid"] as? String) ?? "").isEmpty ? nil : o["pid"] as? String
        var q = Quote()
        q.clientName = (o["client"] as? String) ?? ""
        let city = (o["city"] as? String) ?? ""
        q.city = city.isEmpty ? company.city : city
        q.items = items
        q.notes = (o["notes"] as? String) ?? ""
        q.noteId = pid.flatMap { notesOfProject($0).first }
        saveQuote(q)
        pendingQuoteId = q.id
        quotesBackProject = pid
        if let pid { lastProjectId = pid }
        screen = .quotes
    }

    /// Sai da tela de orçamentos: volta pro projeto de móveis de onde veio, ou pra biblioteca.
    func leaveQuotes() {
        let p = quotesBackProject
        quotesBackProject = nil
        if let p { openProject(p) } else { screen = .library }
    }

    func saveQuote(_ q: Quote) {
        if let i = quotes.firstIndex(where: { $0.id == q.id }) { quotes[i] = q } else { quotes.insert(q, at: 0) }
        let l = quotes, s = store
        io.async { s.saveQuotes(l) }
    }

    func deleteQuote(_ id: String) {
        quotes.removeAll { $0.id == id }
        let l = quotes, s = store
        io.async { s.saveQuotes(l) }
    }

    func buildQuotePdf(_ q: Quote) -> URL? {
        if q.includeDrawing { flush() }
        let note = q.includeDrawing ? q.noteId.flatMap { store.loadNote($0) } : nil
        let safe = (q.clientName.isEmpty ? "cliente" : q.clientName).components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: "_")
        let url = Export.tempURL("Orcamento_\(String(safe.prefix(30))).pdf")
        do { try QuotePdf.write(company: company, quote: q, note: note, logo: logo, to: url); return url }
        catch { toast = tr("Falhou: {0}", error.localizedDescription); return nil }
    }

    /// Ao ir para segundo plano: grava e faz a cópia automática.
    func onBackground() {
        flush()
        io.async { DataBackup.autoBackup() }
    }
}

