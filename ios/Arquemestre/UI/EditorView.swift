import SwiftUI

private func mmText(_ units: CGFloat) -> String { String(format: "%.2f mm", units * MM_PER_UNIT).replacingOccurrences(of: ".", with: ",") }

/// Editor da nota: folha, ferramentas, medidas da trena.
struct EditorView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var ble: BoschBLE
    @ObservedObject var session: EditorSession

    @State private var btOpen = false
    @State private var overview = false
    @State private var tpl: Template = .ARAUJO
    @State private var projLink = false
    @State private var pickPhotos = false
    @State private var camera = false
    @State private var shareURL: URL?
    @State private var eraserMenu = false
    @State private var shapesMenu = false
    @State private var fullscreen = false
    @State private var panelMin = false
    @State private var miniOpen = false
    @State private var textValue = ""

    private var st: EditorState { session.state }

    var body: some View {
        let _ = session.rev
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                SheetCanvas(session: session) { act in
                    switch act {
                    case .tapDim(let id): app.onDimTap(id)
                    case .tapSeg(let id, let k): app.onSegTap(id, k)
                    case .editText(let id, let at):
                        textValue = id.flatMap { st.sheet.obj($0)?.asText?.text } ?? ""
                        session.textEdit = TextEdit(id: id, at: at)
                    }
                }
                .ignoresSafeArea()

                if let msg = session.lockMsg {
                    Text((session.screenLocked ? "🔒 " : "🔓 ") + msg).font(.title2).foregroundColor(.white)
                        .padding(.horizontal, 22).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.black.opacity(0.8)))
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .task(id: msg) { try? await Task.sleep(nanoseconds: 1_600_000_000); session.lockMsg = nil }
                }
                if session.screenLocked {
                    Button { session.toggleLock() } label: {
                        Text(tr("🔒 Tela travada · toque aqui para destravar")).foregroundColor(.white).font(.subheadline)
                            .padding(.horizontal, 16).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 16).fill(Color(argb: 0xE61B1C20)))
                    }
                    .position(x: geo.size.width / 2, y: 90)
                }
                if session.pull > 20 {
                    Text(session.pull >= 80 ? tr("Solte para adicionar uma folha") : tr("Continue a deslizar para adicionar uma folha"))
                        .font(.footnote).foregroundColor(.white).padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(Color.black.opacity(0.8)))
                        .position(x: geo.size.width / 2, y: geo.size.height - 50)
                }

                if fullscreen {
                    Button { fullscreen = false } label: {
                        Image(systemName: "xmark").foregroundColor(.white).frame(width: 40, height: 40).background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .position(x: geo.size.width - 30, y: 30)
                } else {
                    VStack(spacing: 0) { topBar }
                        .background(Ui.panel.clipShape(RoundedRectangle(cornerRadius: 18)).ignoresSafeArea(edges: .top).shadow(radius: 6))
                }

                if session.calcOpen { FloatingCalc(session: session) }

                // durante o gesto (traço/arrasto) as barras somem: a folha responde sem esperar a tela toda
                if !st.inGesture {
                    groupBar(geo.size)
                    contextBar(geo.size)
                }

                // zoom
                HStack(spacing: 0) {
                    Text("\(session.zoomPercent)%").font(.caption).foregroundColor(.white).padding(.leading, 12)
                    Button { session.fitButton() } label: { Image(systemName: "arrow.up.left.and.down.right.magnifyingglass").foregroundColor(.white).frame(width: 36, height: 36) }
                }
                .background(Capsule().fill(Color.black.opacity(0.8)))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(10)

                bottomPanel
                    .frame(maxWidth: 380, alignment: .leading)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(10)

                if let edit = session.textEdit { textField(edit, geo.size) }
            }
            .onAppear {
                session.topInsetPts = 165 + geo.safeAreaInsets.top
                if let imp = app.pendingImport {
                    app.pendingImport = nil
                    if imp == "gallery" { pickPhotos = true } else { camera = true }
                }
            }
        }
        .background(Color(argb: 0xFF1E2025))
        .sheet(isPresented: $btOpen) { BluetoothView() }
        .sheet(isPresented: $overview) { OverviewView(session: session) }
        .sheet(isPresented: $projLink) { ProjectLinkView(noteId: st.note.id) }
        .sheet(isPresented: $pickPhotos) { PhotoPicker(limit: 0) { app.addPhotos($0) }.ignoresSafeArea() }
        .fullScreenCover(isPresented: $camera) { CameraPicker { img in if let i = img { app.addCameraPhoto(i) } else { app.photoToNewPage = false } }.ignoresSafeArea() }
        .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
        .alert(tr("Foto adicionada"), isPresented: $app.askAnotherPhoto) {
            Button(tr("Tirar outra")) { camera = true }
            Button(tr("Pronto"), role: .cancel) {}
        } message: { Text(tr("Também ficou salva na galeria do iPhone.")) }
    }

    // ---------------- barra de cima ----------------
    @ViewBuilder private var topBar: some View {
        let note = st.note
        if app.tabs.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(app.tabs, id: \.self) { id in
                        let on = id == note.id
                        HStack(spacing: 2) {
                            Text(on ? note.name : app.tabName(id)).font(.footnote).foregroundColor(on ? Ui.text : Ui.dim).lineLimit(1).frame(maxWidth: 140)
                            Button { app.closeTab(id) } label: { Image(systemName: "xmark").font(.caption2).foregroundColor(Ui.dim).frame(width: 26, height: 26) }
                        }
                        .padding(.leading, 12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(on ? Ui.panel2 : .clear))
                        .onTapGesture { if !on { app.flush(); app.openNote(id) } }
                    }
                }.padding(.horizontal, 8).padding(.vertical, 4)
            }
        }
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Pill {
                    BarIcon(symbol: "chevron.backward", label: tr("Voltar")) { app.closeEditor() }
                    BarIcon(symbol: "arrow.uturn.backward", label: tr("Desfazer"), enabled: st.canUndo) { st.undo() }
                    BarIcon(symbol: "arrow.uturn.forward", label: tr("Refazer"), enabled: st.canRedo) { st.redo() }
                }
                let vp = session.visiblePage()
                Pill {
                    BarIcon(symbol: "chevron.left", label: tr("Anterior"), enabled: vp > 0) { session.goToPage(vp - 1) }
                    Button { overview = true } label: {
                        LabeledIcon(label: tr("Folhas")) { col in Text("\(vp + 1)/\(note.pages.count)").font(.system(size: 15, weight: .bold)).foregroundColor(col) }
                    }.buttonStyle(.plain)
                    BarIcon(symbol: "chevron.right", label: tr("Próxima"), enabled: vp < note.pages.count - 1) { session.goToPage(vp + 1) }
                    Menu {
                        Button(tr("Antes da folha atual")) { addPage(st.pageIdx) }
                        Button(tr("Após a folha atual")) { addPage(st.pageIdx + 1) }
                        Button(tr("Última página")) { addPage(note.pages.count) }
                        Picker(tr("Modelo"), selection: $tpl) { ForEach(Template.allCases, id: \.self) { Text($0.label).tag($0) } }
                        Divider()
                        Button(tr("Importar imagem")) { app.photoToNewPage = true; pickPhotos = true }
                        Button(tr("Tirar fotografia")) { app.photoToNewPage = true; camera = true }
                    } label: { LabeledIcon(label: tr("Nova folha")) { _ in Image(systemName: "plus").font(.system(size: 18)).foregroundColor(Ui.accent) } }
                }
                let linkedId = app.linkedProject(note.id)
                let linkedName = linkedId.flatMap { id in app.moveisProjects().first { $0.id == id }?.name }
                Pill {
                    // acesso rápido: ligada → abre o projeto do cliente direto (segurar: trocar/desligar)
                    LabeledIcon(label: linkedName ?? tr("Projeto"), on: linkedName != nil) { _ in Text("🪚").font(.system(size: 17)) }.frame(maxWidth: 160)
                        .contentShape(Rectangle())
                        .onTapGesture { if !app.openProjectOfNote(note.id) { projLink = true } }
                        .onLongPressGesture { projLink = true }
                        .accessibilityAddTraits(.isButton)
                }
                Pill {
                    Button { st.setUnit(note.unit.next) } label: {
                        LabeledIcon(label: tr("Unidade")) { col in Text(note.unit.label).font(.system(size: 15, weight: .bold)).foregroundColor(col) }
                    }.buttonStyle(.plain)
                    Button { btOpen = true } label: {
                        let connected = ble.state == .CONNECTED
                        LabeledIcon(label: connected ? tr("Trena ligada") : tr("Trena Bosch"), on: connected) { col in
                            Image(systemName: "dot.radiowaves.left.and.right").font(.system(size: 18)).foregroundColor(col)
                        }
                    }.buttonStyle(.plain)
                }
                Pill {
                    Menu {
                        Button(tr("Zoom em tela cheia")) { fullscreen = true }
                        Button(tr("Visão geral da nota")) { overview = true }
                        Button(note.locked ? tr("Remover bloqueio") : tr("Adicionar bloqueio")) {
                            st.setNoteLocked(!note.locked)
                            app.toast = !note.locked ? tr("Nota bloqueada: abrirá só após remover o bloqueio") : tr("Bloqueio removido")
                        }
                        Divider()
                        Button(tr("Exportar PDF")) { shareURL = app.exportPdf() }
                        Button(tr("Exportar folha (PNG)")) { shareURL = app.exportPng() }
                        Button(tr("Exportar medidas (CSV)")) { shareURL = app.exportCsv() }
                        Divider()
                        Button(session.stylusOnly ? tr("Desenhar só com Apple Pencil: ligado") : tr("Desenhar só com Apple Pencil: desligado")) { session.stylusOnly.toggle() }
                    } label: { LabeledIcon(label: tr("Mais")) { col in Image(systemName: "ellipsis").font(.system(size: 18)).foregroundColor(col) } }
                }
            }.padding(.horizontal, 8)
        }
        .padding(.top, 2)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // escrever
                Pill {
                    toolBtn(.PEN); toolBtn(.PENCIL); toolBtn(.HIGHLIGHTER)
                    BarIcon(symbol: Tool.ERASER.symbol, label: tr("Borracha"), on: session.tool == .ERASER) {
                        if session.tool == .ERASER { eraserMenu = true } else { session.chooseTool(.ERASER) }
                    }
                    .popover(isPresented: $eraserMenu) { EraserSettings(session: session).frame(minWidth: 280).padding() .presentationCompactAdaptation(.popover) }
                }
                // selecionar
                Pill { toolBtn(.SELECT); glyphBtn(.LASSO) }
                // medir e marcar
                Pill { glyphBtn(.DIM); glyphBtn(.ROOM); glyphBtn(.DOOR) }
                // inserir
                Pill {
                    Button { shapesMenu = true } label: {
                        let inShapes = shapeTools.contains(session.tool) && ![.DIM, .ROOM, .DOOR].contains(session.tool)
                        LabeledIcon(label: inShapes ? session.tool.short : tr("Formas"), on: inShapes) { col in ShapeGlyph(tool: inShapes ? session.tool : .RECT, tint: col) }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $shapesMenu) { ShapesPanel(session: session) { shapesMenu = false }.padding().presentationCompactAdaptation(.popover) }
                    toolBtn(.TEXT)
                    Menu {
                        Button { app.photoToNewPage = false; pickPhotos = true } label: { Label(tr("Álbum"), systemImage: "photo") }
                        Button { app.photoToNewPage = false; camera = true } label: { Label(tr("Câmera"), systemImage: "camera") }
                    } label: { LabeledIcon(label: tr("Imagem")) { col in Image(systemName: "photo").font(.system(size: 18)).foregroundColor(col) } }
                    BarIcon(symbol: "plus.forwardslash.minus", label: tr("Calculadora"), on: session.calcOpen) { session.calcOpen.toggle() }
                }
                // cor e espessura
                Pill {
                    VStack(spacing: 1) {
                        ColorRow(current: session.color) { session.applyColor($0) }
                        Text(tr("Cor")).font(.system(size: 10)).foregroundColor(Ui.text)
                    }.padding(.horizontal, 8)
                    BarIcon(symbol: "minus", label: tr("Mais fina")) { session.applyWidth(-0.1) }
                    VStack(spacing: 1) {
                        Text(mmText(session.width)).font(.caption).foregroundColor(Ui.text)
                        Text(tr("Espessura")).font(.system(size: 10)).foregroundColor(Ui.dim)
                    }
                    BarIcon(symbol: "plus", label: tr("Mais grossa")) { session.applyWidth(0.1) }
                }
            }.padding(.horizontal, 8)
        }
        .padding(.top, 6).padding(.bottom, 6)
    }

    /// Ferramenta com desenho próprio (laço, medida, cômodo, porta) e o nome embaixo.
    private func glyphBtn(_ t: Tool) -> some View {
        Button { session.chooseTool(t) } label: {
            LabeledIcon(label: t.short, on: session.tool == t) { col in ShapeGlyph(tool: t, tint: col) }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(t.label)
    }

    private func toolBtn(_ t: Tool) -> some View {
        BarIcon(symbol: t.symbol, label: t.short, on: session.tool == t) { session.chooseTool(t) }
    }

    private func addPage(_ pos: Int) {
        if st.addPage(pos, tpl) { session.goToPage(st.pageIdx) } else { app.toast = tr("Limite de {0} folhas", Sheet.MAX_PAGES) }
    }

    // ---------------- grupo (laço) e menu da seleção ----------------
    @ViewBuilder private func groupBar(_ size: CGSize) -> some View {
        if !st.groupIds.isEmpty {
            let boxes = st.groupObjs().map { Geo.bounds(st.sheet, $0) }
            if !boxes.isEmpty {
                let tl = session.view.toScreen(Pt(boxes.map(\.l).min()!, boxes.map(\.t).min()!))
                let tRight = session.view.toScreen(Pt(boxes.map(\.r).max()!, boxes.map(\.t).min()!))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        Text(tr("{0} itens", st.groupIds.count)).font(.caption).foregroundColor(.gray).padding(.leading, 10)
                        ctx(tr("Eliminar")) { st.deleteGroup() }
                        ctx(tr("Cortar")) { session.copyGroup(cut: true) }
                        ctx(tr("Copiar")) { session.copyGroup() }
                        ctx(tr("Duplicar")) { st.pasteObjs(st.groupWithLinked()) }
                        ctx(tr("Colar"), session.clipboard.isEmpty == false) { session.paste() }
                    }
                }
                .frame(maxWidth: min(size.width - 24, 420))
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(argb: 0xEE111111)))
                .fixedSize(horizontal: false, vertical: true)
                .position(x: clamp((tl.x + tRight.x) / 2, 160, max(160, size.width - 160)), y: max(200, tl.y - 30))
            }
        }
    }

    @ViewBuilder private func contextBar(_ size: CGSize) -> some View {
        if let o = st.selected, o.asDim == nil {
            let pts = Geo.annPoints(st.sheet.photos(), o)
            if !pts.isEmpty {
                let sp = pts.map { session.view.toScreen($0) }
                let topY = sp.map(\.y).min()!, botY = sp.map(\.y).max()!
                let cx = sp.map(\.x).reduce(0, +) / CGFloat(sp.count)
                let y = topY - 34 >= 200 ? topY - 34 : min(botY + 34, size.height - 60)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ctx(tr("Eliminar"), !o.locked) { st.delete(o.id) }
                        ctx(tr("Cortar"), !o.locked) { session.copySelection(cut: true) }
                        ctx(tr("Copiar")) { session.copySelection() }
                        ctx(tr("Colar"), !session.clipboard.isEmpty) { session.paste() }
                        if !o.isLegacy { ctx(tr("Duplicar")) { st.duplicate(o.id) } }
                        if o.asPhoto != nil { ctx(tr("Girar 90°"), !o.locked) { st.rotatePhoto90(o.id) } }
                        ctx(o.locked ? tr("Desbloquear") : tr("Bloqueio")) { st.setLocked(o.id, !o.locked) }
                        ctx(tr("Para frente")) { st.reorder(o.id, up: true) }
                        ctx(tr("Para trás")) { st.reorder(o.id, up: false) }
                    }
                }
                .frame(maxWidth: min(size.width - 24, 520))
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(argb: 0xB31B1C20)))
                .fixedSize(horizontal: false, vertical: true)
                .position(x: clamp(cx, min(size.width / 2, 200), max(size.width / 2, size.width - 200)), y: y)
            }
        }
    }

    private func ctx(_ label: String, _ enabled: Bool = true, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.caption).foregroundColor(enabled ? .white : .gray).lineLimit(1).padding(.horizontal, 9).padding(.vertical, 9)
        }.disabled(!enabled)
    }

    // ---------------- painel de baixo ----------------
    @ViewBuilder private var bottomPanel: some View {
        let sel = st.selected
        VStack(alignment: .leading, spacing: 8) {
            if sel?.asDim != nil || sel?.asRoom != nil || sel?.asDoor != nil {
                Button { panelMin.toggle() } label: {
                    Text(panelMin ? tr("▲ Medida (toque para abrir)") : tr("▼ Minimizar")).font(.caption).foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 7).background(Capsule().fill(Color(argb: 0xB31B1C20)))
                }
            }
            if !panelMin {
                if let d = sel?.asDim { DistancePanel(session: session, d: d) }
                if let d = sel?.asDoor { DoorPanel(session: session, d: d) }
                if let r = sel?.asRoom { RoomPanel(session: session, r: r) }
            }
            if ble.state == .CONNECTED && !app.trenaHidden { MiniTelemeter(open: $miniOpen) }
            ChipsBar(connected: ble.state == .CONNECTED, unit: st.unit) { btOpen = true }
        }
    }

    // ---------------- texto ----------------
    private func textField(_ edit: TextEdit, _ size: CGSize) -> some View {
        let existing = edit.id.flatMap { st.sheet.obj($0)?.asText }
        let at = existing.map { session.view.toScreen(Geo.annPoints(st.sheet.photos(), .text($0))[0]) } ?? session.view.toScreen(edit.at)
        return HStack {
            TextField(tr("Texto"), text: $textValue, axis: .vertical).textFieldStyle(.roundedBorder).lineLimit(1...4)
                .onSubmit { session.commitText(edit, textValue) }
            Button { session.commitText(edit, textValue) } label: { Image(systemName: "checkmark.circle.fill").font(.title2) }
        }
        .padding(8).frame(width: 300)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.systemBackground)).shadow(radius: 8))
        .position(x: clamp(at.x, 160, max(160, size.width - 160)), y: clamp(at.y, 60, max(60, size.height - 300)))
    }
}

// ---------------- borracha e formas ----------------

struct EraserSettings: View {
    @ObservedObject var session: EditorSession
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Borracha")).font(.headline)
            Picker("", selection: $session.eraserMode) { ForEach(EraserMode.allCases, id: \.self) { Text($0.label).tag($0) } }.pickerStyle(.segmented)
            Text(session.eraserMode == .PIXEL ? tr("Borracha normal: apaga só por onde passa (traço, linha, forma, contorno e parede).") : (session.eraserMode == .STROKE ? tr("Apaga o traço ou a forma inteira que você tocar.") : tr("Contorne para apagar o que ficar dentro.")))
                .font(.caption).foregroundColor(.secondary)
            HStack { Text(tr("Tamanho")); Slider(value: $session.eraserSize, in: 4...60) }
            Toggle(tr("Apenas apagar marca-texto"), isOn: $session.eraserOnlyHighlighter)
            Button(tr("Limpar a página atual"), role: .destructive) { session.state.clearPageDrawings() }
        }
    }
}

struct ShapesPanel: View {
    @ObservedObject var session: EditorSession
    var close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Formas")).font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(62)), count: 4), spacing: 6) {
                ForEach(shapeTools.filter { ![.DIM, .ROOM, .DOOR].contains($0) }, id: \.self) { t in
                    Button { session.chooseTool(t); close() } label: {
                        VStack(spacing: 2) {
                            ShapeGlyph(tool: t, tint: session.tool == t ? Ui.accent : .primary)
                            Text(t.short).font(.system(size: 10)).foregroundColor(session.tool == t ? Ui.accent : .primary).lineLimit(1)
                        }
                        .frame(width: 60, height: 50)
                        .background(RoundedRectangle(cornerRadius: 10).fill(session.tool == t ? Ui.accent.opacity(0.3) : .clear))
                    }.accessibilityLabel(t.label)
                }
            }
            HStack {
                Text(tr("Espessura")).font(.footnote)
                Spacer()
                Button { session.applyWidth(-0.1) } label: { Image(systemName: "minus") }
                Text(mmText(session.width)).font(.footnote)
                Button { session.applyWidth(0.1) } label: { Image(systemName: "plus") }
            }
            ColorRow(current: session.color) { session.applyColor($0) }
            Toggle(tr("Preenchimento"), isOn: $session.fill).font(.footnote)
        }
        .frame(width: 270)
    }
}

// ---------------- painéis da medida ----------------

private func statusText(_ hasValue: Bool, _ source: MeasureSource?, _ connected: Bool) -> String {
    if hasValue && connected { return tr("Meça de novo para substituir") }
    if hasValue && source == .MANUAL { return tr("Digitado à mão") }
    if hasValue { return tr("Medido pela trena Bosch") }
    if !connected { return tr("Toque na medida para digitar, ou conecte a trena Bosch") }
    return tr("Aguardando a medida da trena…")
}

/// Caixa da medida: toque para digitar no teclado do app.
struct ManualValueBox: View {
    var text: String
    var unit: LengthUnit
    var enabled: Bool
    var onSet: (Double) -> Void
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            Text(text == "–" && enabled ? tr("– toque p/ digitar") : text)
                .font(text == "–" ? .body : .system(size: 22, weight: .medium)).foregroundColor(Ui.distBlue)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(argb: 0xFFE6EEFF)))
        }
        .disabled(!enabled)
        .sheet(isPresented: $open) {
            NumPadSheet(title: tr("Digitar medida"), suffix: unit.label, hint: tr("Teclado do app: pode somar ou tirar (ex.: 2750−4). Fica marcada como digitada à mão."),
                        text: text == "–" ? "" : text) { v in if v > 0 { onSet(Units.toMm(v, unit)) } }
        }
    }
}

struct LabelSlider: View {
    var label: String
    var value: CGFloat
    var range: ClosedRange<CGFloat>
    var enabled: Bool
    var st: EditorState
    var onChange: (CGFloat) -> Void
    var body: some View {
        HStack {
            Text(label).font(.footnote).foregroundColor(Color(argb: 0xFF111111)).frame(width: 110, alignment: .leading)
            Slider(value: Binding(get: { clamp(value, range.lowerBound, range.upperBound) }, set: { st.beginGesture(); onChange($0) }), in: range,
                   onEditingChanged: { editing in if !editing { st.endGesture() } }).disabled(!enabled)
            Text("\(Int(value * 100))%").font(.caption).foregroundColor(Color(argb: 0xFF555555)).frame(width: 44)
        }
    }
}

struct DistancePanel: View {
    @EnvironmentObject var ble: BoschBLE
    @ObservedObject var session: EditorSession
    var d: DimObj
    var body: some View {
        let st = session.state
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(tr("Distância")).font(.headline).foregroundColor(Color(argb: 0xFF111111))
                HStack {
                    ManualValueBox(text: d.valueMm.map { Units.formatNumber($0, st.unit) } ?? "–", unit: st.unit, enabled: !d.locked) { st.setManualValue($0) }
                    Button(st.unit.label) { st.setUnit(st.unit.next) }.font(.title3)
                }
                Text(statusText(d.valueMm != nil, d.source, ble.state == .CONNECTED)).font(.footnote).foregroundColor(Color(argb: 0xFF555555))
                Divider()
                HStack { Text(tr("Cor")).font(.footnote).foregroundColor(Color(argb: 0xFF111111)); ColorRow(current: d.color) { session.applyColor($0) } }
                HStack {
                    Text(tr("Espessura da linha")).font(.footnote).foregroundColor(Color(argb: 0xFF111111))
                    Spacer()
                    Button { session.applyWidth(-0.1) } label: { Image(systemName: "minus") }
                    Text(mmText(d.width)).font(.footnote).foregroundColor(Color(argb: 0xFF111111))
                    Button { session.applyWidth(0.1) } label: { Image(systemName: "plus") }
                }
                Divider()
                Text(tr("Quadradinho da medida")).font(.subheadline).foregroundColor(Color(argb: 0xFF111111))
                LabelSlider(label: tr("Tamanho"), value: d.labelScale, range: 0.1...3, enabled: !d.locked, st: st) { st.setDimLabel(d.id, scale: $0, live: true) }
                LabelSlider(label: tr("Opacidade"), value: d.labelAlpha, range: 0.1...1, enabled: !d.locked, st: st) { st.setDimLabel(d.id, alpha: $0, live: true) }
                LabelSlider(label: tr("Intensidade"), value: d.labelIntensity, range: 0.15...1, enabled: !d.locked, st: st) { st.setDimLabel(d.id, intensity: $0, live: true) }
                Text(tr("O quadradinho acompanha o tamanho da foto e da seta automaticamente.")).font(.caption2).foregroundColor(.gray)
                HStack {
                    Button(tr("Aplicar a todas as cotas")) { st.applyDimLabelToAll(d.id) }.disabled(d.locked)
                    Spacer()
                    Button(tr("Excluir"), role: .destructive) { st.delete(d.id) }.disabled(d.locked)
                }.font(.footnote)
            }.padding(14)
        }
        .frame(maxHeight: 260)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
    }
}

struct DoorPanel: View {
    @EnvironmentObject var ble: BoschBLE
    @ObservedObject var session: EditorSession
    var d: DoorObj
    var body: some View {
        let st = session.state
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(tr("🚪 Porta na linha")).font(.headline).foregroundColor(Color(argb: 0xFFE53935))
                Text(tr("Arraste as bolinhas das pontas pra ajustar o vão em cima da linha.")).font(.caption).foregroundColor(Color(argb: 0xFF555555))
                Text(tr("Sentido de abertura")).font(.footnote).foregroundColor(Color(argb: 0xFF111111))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        Button(tr("↔ Dobradiça do outro lado")) { st.setDoor(d.id, hinge: 1 - d.hinge) }
                        Button(tr("⇅ Abre pro outro lado")) { st.setDoor(d.id, side: -d.side) }
                        Button(d.slide ? tr("De correr ✓") : tr("De abrir ✓")) { st.setDoor(d.id, slide: !d.slide) }
                    }.buttonStyle(.bordered).disabled(d.locked)
                }
                Text(tr("Tamanho e escrita")).font(.footnote).foregroundColor(Color(argb: 0xFF111111))
                LabelSlider(label: tr("Quadradinho"), value: d.labelScale, range: 0.2...2.5, enabled: !d.locked, st: st) { st.setDoor(d.id, labelScale: $0, live: true) }
                LabelSlider(label: tr("Linha vermelha"), value: d.width, range: 0.4...5, enabled: !d.locked, st: st) { st.setDoor(d.id, width: $0, live: true) }
                HStack {
                    Button(d.labelVert ? tr("Escrita deitada") : tr("Escrita deitada ✓")) { st.setDoor(d.id, labelVert: false) }
                    Button(d.labelVert ? tr("Escrita em pé ✓") : tr("Escrita em pé")) { st.setDoor(d.id, labelVert: true) }
                }.buttonStyle(.bordered).disabled(d.locked)
                Text(tr("Largura do vão")).font(.footnote).foregroundColor(Color(argb: 0xFF111111))
                HStack {
                    ManualValueBox(text: d.valueMm.map { Units.formatNumber($0, st.unit) } ?? "–", unit: st.unit, enabled: !d.locked) { st.setManualValue($0) }
                    Button(st.unit.label) { st.setUnit(st.unit.next) }.font(.title3)
                }
                Text(statusText(d.valueMm != nil, d.source, ble.state == .CONNECTED)).font(.footnote).foregroundColor(Color(argb: 0xFF555555))
                HStack {
                    if d.valueMm != nil { Button(tr("Limpar medida")) { st.clearValue(d.id) } }
                    Spacer()
                    Button(tr("Excluir porta"), role: .destructive) { st.delete(d.id) }.disabled(d.locked)
                }.font(.footnote)
            }.padding(14)
        }
        .frame(maxHeight: 280)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
    }
}

struct RoomPanel: View {
    @EnvironmentObject var ble: BoschBLE
    @ObservedObject var session: EditorSession
    var r: RoomObj
    var body: some View {
        let st = session.state
        let k = st.selectedSeg
        let seg: Seg? = r.segs.indices.contains(k) ? r.segs[k] : nil
        let dark = Color(argb: 0xFF111111)
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(seg != nil ? tr("Cômodo · trecho {0} de {1}", k + 1, r.segCount) : tr("Cômodo · toque num trecho")).font(.headline).foregroundColor(dark)
                    Spacer()
                    Button("‹") { st.stepSeg(-1) }.font(.title2)
                    Button("›") { st.stepSeg(1) }.font(.title2)
                }
                if let sg = seg {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(SegKind.allCases, id: \.self) { kd in
                                let on = sg.kind == kd
                                Button { st.setSegKind(r.id, k, kd) } label: {
                                    Text(kd.label).font(.subheadline).foregroundColor(on ? .white : dark)
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(Capsule().fill(on ? Color(model: roomSegColor(r, kd)) : Color(argb: 0xFFEFEFEF)))
                                }.disabled(r.locked)
                            }
                        }
                    }
                    if sg.kind == .DOOR {
                        Text(tr("Sentido da porta")).font(.footnote).foregroundColor(dark)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Button(tr("↔ Dobradiça do outro lado")) { st.setSegDoor(r.id, k, hinge: 1 - sg.hinge) }
                                Button(tr("⇅ Abre pro outro lado")) { st.setSegDoor(r.id, k, side: -sg.side) }
                                Button(sg.slide ? tr("De correr ✓") : tr("De abrir ✓")) { st.setSegDoor(r.id, k, slide: !sg.slide) }
                            }.buttonStyle(.bordered).disabled(r.locked)
                        }
                    } else if !sg.kind.isOpening {
                        Text(tr("Abrir neste trecho (a parede se divide e você mede cada parte)")).font(.caption).foregroundColor(Color(argb: 0xFF555555))
                        HStack {
                            Button(tr("＋ Porta")) { st.splitSeg(r.id, k, .DOOR) }
                            Button(tr("＋ Janela")) { st.splitSeg(r.id, k, .WINDOW) }
                            Button(tr("＋ Vão")) { st.splitSeg(r.id, k, .OPENING) }
                        }.buttonStyle(.bordered).disabled(r.locked)
                    }
                    Button(tr("Aplicar \"{0}\" a todo o contorno", sg.kind.label)) { st.setAllSegKinds(r.id, sg.kind) }.font(.footnote).disabled(r.locked)
                    HStack {
                        ManualValueBox(text: sg.valueMm.map { Units.formatNumber($0, st.unit) } ?? "–", unit: st.unit, enabled: !r.locked) { st.setManualValue($0) }
                        Button(st.unit.label) { st.setUnit(st.unit.next) }.font(.title3)
                    }
                    Text(statusText(sg.valueMm != nil, sg.source, ble.state == .CONNECTED)).font(.footnote).foregroundColor(Color(argb: 0xFF555555))
                    if sg.valueMm != nil { Button(tr("Limpar medida")) { st.clearValue(r.id) }.font(.footnote) }
                }
                if r.pts.count >= 4 || (!r.closed && r.pts.count >= 3) {
                    Button(tr("Unir pontos soltos (reta = 1 medida)")) { st.mergeRoomStray(r.id) }.font(.footnote).disabled(r.locked)
                }
                if r.pts.count >= 3 { Button(r.closed ? tr("Abrir contorno") : tr("Fechar contorno")) { st.setRoomClosed(r.id, !r.closed) }.font(.footnote) }
                Divider()
                LabelSlider(label: tr("Quadradinho"), value: r.labelScale, range: 0.1...3, enabled: !r.locked, st: st) { st.setRoomLabelScale(r.id, $0, live: true) }
                HStack {
                    Button(r.labelVert ? tr("Escrita deitada") : tr("Escrita deitada ✓")) { st.setRoomLabelVert(r.id, false) }
                    Button(r.labelVert ? tr("Escrita em pé ✓") : tr("Escrita em pé")) { st.setRoomLabelVert(r.id, true) }
                }.buttonStyle(.bordered).disabled(r.locked)
                HStack { Text(tr("Cor da parede")).font(.footnote).foregroundColor(dark); ColorRow(current: r.color) { session.applyColor($0) } }
            }.padding(14)
        }
        .frame(maxHeight: 280)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
    }
}

struct MiniTelemeter: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var ble: BoschBLE
    @Binding var open: Bool
    var body: some View {
        let k = app.trenaScale
        VStack(alignment: .leading, spacing: 4 * k) {
            HStack(spacing: 8 * k) {
                Text(tr("Trena")).font(.system(size: 13 * k)).foregroundColor(Ui.text)
                Button(open ? tr("Pronto ▾") : tr("Pronto ▸")) { open.toggle() }.font(.system(size: 12 * k)).foregroundColor(Ui.accent)
                Spacer()
                Button("A−") { app.setTrenaScale(app.trenaScale - 0.1) }.font(.system(size: 13 * k))
                Button("A+") { app.setTrenaScale(app.trenaScale + 0.1) }.font(.system(size: 13 * k))
                Button("✕") { app.setTrenaHidden(true) }.font(.system(size: 14 * k)).foregroundColor(Ui.dim)
            }
            if open {
                Text(ble.deviceName ?? tr("Bosch")).font(.system(size: 12 * k)).foregroundColor(Ui.dim)
                Button(tr("Desconectar")) { ble.disconnect() }.font(.system(size: 12 * k))
            }
        }
        .padding(8 * k)
        .background(RoundedRectangle(cornerRadius: 12 * k).fill(Ui.panel))
    }
}

struct ChipsBar: View {
    @EnvironmentObject var app: AppModel
    var connected: Bool
    var unit: LengthUnit
    var onBt: () -> Void
    var body: some View {
        if connected || !app.recent.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if !app.trenaHidden {
                        Button(action: onBt) {
                            Image(systemName: "dot.radiowaves.left.and.right").foregroundColor(.white)
                                .frame(width: 44 * app.trenaScale, height: 44 * app.trenaScale).background(Circle().fill(Ui.distBlue))
                        }
                    }
                    ForEach(app.recent) { r in
                        HStack(spacing: 2) {
                            Button { app.applyRecent(r) } label: { Text(Units.format(r.mm, unit)).foregroundColor(Ui.text) }
                            Button { app.discardRecent(r) } label: { Image(systemName: "xmark").font(.caption2).foregroundColor(Ui.dim).frame(width: 30, height: 30) }
                        }
                        .padding(.leading, 14).padding(.trailing, 4)
                        .background(Capsule().fill(Ui.panel2))
                    }
                }
            }
        }
    }
}

// ---------------- calculadora flutuante ----------------

struct FloatingCalc: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var session: EditorSession
    @State private var offset = CGSize(width: 40, height: 220)
    @State private var drag = CGSize.zero
    @State private var expr = ""
    @State private var collapsed = false

    var body: some View {
        let result = Calc.eval(expr)
        let preview = expr.isEmpty ? "" : (result.map(Calc.format) ?? "")
        let lastMm = app.recent.first?.mm
        VStack(spacing: 8) {
            HStack {
                Text(tr("⠿  Calculadora")).font(.footnote).foregroundColor(.gray)
                Spacer()
                Button("–") { collapsed.toggle() }.foregroundColor(.white).font(.title3)
                Button("✕") { session.calcOpen = false }.foregroundColor(.white).padding(.leading, 8)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture().onChanged { drag = $0.translation }.onEnded { v in offset.width += v.translation.width; offset.height += v.translation.height; drag = .zero })
            VStack(alignment: .trailing) {
                Text(expr.isEmpty ? "0" : expr).font(.system(size: 24)).foregroundColor(.white).lineLimit(1).minimumScaleFactor(0.5)
                Text(!preview.isEmpty && preview != expr ? "= \(preview)" : " ").font(.footnote).foregroundColor(Color(argb: 0xFF7FB0FF))
            }
            .frame(maxWidth: .infinity, alignment: .trailing).padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(argb: 0xFF111214)))
            if !collapsed {
                ForEach([["C", "⌫", "%", "÷"], ["7", "8", "9", "×"], ["4", "5", "6", "−"], ["1", "2", "3", "+"], ["0", ",", "(", ")"]], id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(row, id: \.self) { k in
                            let op = ["÷", "×", "−", "+"].contains(k)
                            Button { press(k, result, lastMm) } label: {
                                Text(k).font(.title3).foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 42)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(op ? Ui.accent : Color(argb: 0xFF33363C)))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                HStack(spacing: 6) {
                    Button { press("Medida", result, lastMm) } label: {
                        Text(tr("Última medida")).font(.footnote).foregroundColor(lastMm != nil ? .white : .gray).frame(maxWidth: .infinity, minHeight: 42)
                            .background(RoundedRectangle(cornerRadius: 10).fill(lastMm != nil ? Color(argb: 0xFF2E6B4F) : Color(argb: 0xFF2A2C30)))
                    }.buttonStyle(.plain).disabled(lastMm == nil)
                    Button { press("=", result, lastMm) } label: {
                        Text("=").font(.title2).foregroundColor(.white).frame(maxWidth: .infinity, minHeight: 42)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Ui.accent))
                    }.buttonStyle(.plain)
                }
                Button {
                    if let r = result { let t = Calc.format(r); session.addTextCenter(!expr.isEmpty && expr != t ? "\(expr) = \(t)" : t) }
                } label: {
                    Text(tr("📝 Escrever na folha")).font(.subheadline).foregroundColor(result != nil ? .white : .gray).frame(maxWidth: .infinity, minHeight: 40)
                        .background(RoundedRectangle(cornerRadius: 10).fill(result != nil ? Color(argb: 0xFF3B4D7A) : Color(argb: 0xFF2A2C30)))
                }.buttonStyle(.plain).disabled(result == nil)
            }
        }
        .padding(10).frame(width: 236)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(argb: 0xF2202226)).shadow(radius: 10))
        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
    }

    private func press(_ k: String, _ result: Double?, _ lastMm: Double?) {
        switch k {
        case "C": expr = ""
        case "⌫": if !expr.isEmpty { expr.removeLast() }
        case "=": if let r = result { expr = Calc.format(r) }
        case "Medida": if let m = lastMm { expr += Units.formatNumber(m, session.state.unit) }
        default: expr += k
        }
    }
}

// ---------------- visão geral e vínculo com projeto ----------------

struct OverviewView: View {
    @EnvironmentObject var app: AppModel
    @ObservedObject var session: EditorSession
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDel: Int?
    var body: some View {
        let _ = session.rev
        let st = session.state
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                    ForEach(Array(st.note.pages.enumerated()), id: \.element.id) { i, page in
                        VStack {
                            PageThumb(page: page, unit: st.unit)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(i == st.pageIdx ? Ui.accent : Ui.line, lineWidth: i == st.pageIdx ? 2 : 1))
                                .onTapGesture { dismiss(); session.goToPage(i) }
                            HStack {
                                Text("\(i + 1)")
                                Spacer()
                                Menu {
                                    Button(tr("Duplicar folha")) { if !st.duplicatePage(i) { app.toast = tr("Limite de {0} folhas", Sheet.MAX_PAGES) } }
                                    Button(tr("Excluir folha"), role: .destructive) { confirmDel = i }.disabled(st.note.pages.count <= 1)
                                } label: { Image(systemName: "ellipsis.circle") }
                            }
                        }
                    }
                }.padding(12)
            }
            .navigationTitle(tr("Visão geral · {0} folhas", st.note.pages.count)).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } } }
            .alert(tr("Excluir esta folha?"), isPresented: Binding(get: { confirmDel != nil }, set: { if !$0 { confirmDel = nil } })) {
                Button(tr("Cancelar"), role: .cancel) {}
                Button(tr("Excluir"), role: .destructive) { if let i = confirmDel { st.deletePage(i); session.updateActivePage(); session.clampView() } }
            }
        }
    }
}

struct PageThumb: View {
    var page: Sheet
    var unit: LengthUnit
    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width / Sheet.W, size.height / Sheet.H)
            ctx.withCGContext { c in
                c.translateBy(x: (size.width - Sheet.W * k) / 2, y: 0)
                c.scaleBy(x: k, y: k)
                SheetRenderer(images: { ImageCache.shared.image($0, maxPx: 500) }).draw(c, page, unit, selectedId: nil, viewScale: k, withPaper: false)
            }
        }
        .frame(height: 200)
    }
}

struct ProjectLinkView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    var noteId: String
    var body: some View {
        let _ = app.projVersion
        let linked = app.linkedProject(noteId)
        let list = app.moveisProjects()
        NavigationStack {
            List {
                if let cur = list.first(where: { $0.id == linked }) {
                    Section(tr("Ligada a: {0}", cur.name)) {
                        Button(tr("🪚 Abrir o projeto")) { dismiss(); app.openProjectOfNote(noteId) }
                        Button(tr("Desligar desta nota"), role: .destructive) { app.linkProject(noteId, nil); dismiss() }
                    }
                }
                Section {
                    Button(tr("＋ Novo projeto para este cliente")) { dismiss(); app.newProjectForNote(noteId) }
                }
                Section(list.isEmpty ? tr("Ainda não tem projeto de móveis. Crie um no editor de móveis.") : (linked != nil ? tr("Ou trocar por:") : tr("Escolha o projeto para ligar a esta nota:"))) {
                    ForEach(list.filter { $0.id != linked }) { p in
                        Button("🪚 \(p.name) · \(p.label)") { app.linkProject(noteId, p.id); dismiss() }
                    }
                }
            }
            .navigationTitle(tr("Projeto de móveis desta nota")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button(tr("Fechar")) { dismiss() } } }
        }
    }
}
