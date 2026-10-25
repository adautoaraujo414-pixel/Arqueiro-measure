import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// ---------------- Teclado numérico do app (o teclado do aparelho nunca abre para números) ----------------

struct AppNumPad: View {
    @Binding var text: String
    var allowOps = true

    private var keys: [String] {
        allowOps ? ["7", "8", "9", "⌫", "4", "5", "6", "+", "1", "2", "3", "−", "C", "0", ",", ""]
                 : ["7", "8", "9", "⌫", "4", "5", "6", "C", "1", "2", "3", "", "", "0", ",", ""]
    }

    var body: some View {
        VStack(spacing: 6) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(text.isEmpty ? "0" : text).font(.system(size: 26, design: .monospaced)).foregroundColor(Color(argb: 0xFF0B2A3D))
                    .frame(maxWidth: .infinity, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.5)
                if allowOps && (text.contains("+") || text.contains("−")), let r = Calc.eval(text) {
                    Text("= " + Calc.format(r)).font(.footnote).foregroundColor(Color(argb: 0xFF3B5B85))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(argb: 0xFFE6EEFF)))
            ForEach(0..<4, id: \.self) { r in
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { c in
                        let k = keys[r * 4 + c]
                        Button { press(k) } label: {
                            Text(k).font(.system(size: 22, weight: .semibold)).foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .background(RoundedRectangle(cornerRadius: 10).fill(bg(k)))
                        }
                        .buttonStyle(.plain)
                        .disabled(k.isEmpty)
                    }
                }
            }
        }
    }

    private func bg(_ k: String) -> Color {
        switch k {
        case "": return .clear
        case "⌫", "C": return Color(argb: 0xFF5A3A3A)
        case "+", "−": return Color(argb: 0xFF34527F)
        default: return Color(argb: 0xFF2B303B)
        }
    }

    private func press(_ k: String) {
        switch k {
        case "⌫": if !text.isEmpty { text.removeLast() }
        case "C": text = ""
        case ",":
            let last = text.split(whereSeparator: { $0 == "+" || $0 == "−" }).last.map(String.init) ?? ""
            let endsWithOp = text.last == "+" || text.last == "−"
            if text.isEmpty || endsWithOp { text += "0," } else if !last.contains(",") { text += "," }
        case "+", "−": if let l = text.last, l.isNumber { text += k }
        case "": break
        default: text += k
        }
    }
}

func numPadValue(_ text: String) -> Double? { text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : Calc.eval(text) }

/// Folha com o teclado do app: devolve o número (resolve a conta, se tiver).
struct NumPadSheet: View {
    var title: String
    var suffix: String = ""
    var allowOps = true
    var hint: String?
    @State var text: String
    var onOk: (Double) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(suffix.isEmpty ? title : "\(title) (\(suffix))").font(.headline)
            AppNumPad(text: $text, allowOps: allowOps)
            if let h = hint { Text(h).font(.caption).foregroundColor(.secondary) }
            HStack {
                Button("Cancelar") { dismiss() }
                Spacer()
                Button("OK") { if let v = numPadValue(text) { onOk(v); dismiss() } }
                    .buttonStyle(.borderedProminent).disabled(numPadValue(text) == nil)
            }
        }
        .padding(18)
        .presentationDetents([.height(500)])
    }
}

/// Campo numérico que abre o teclado do app.
struct NumPadField: View {
    var value: String
    var label: String
    var onValue: (Double) -> Void
    @State private var open = false
    var body: some View {
        Button { open = true } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption2).foregroundColor(Color(argb: 0xFF555555))
                Text(value.isEmpty ? "–" : value).font(.body).foregroundColor(Color(argb: 0xFF111111))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(argb: 0xFFF1F4F9)))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $open) { NumPadSheet(title: label, text: value, onOk: onValue) }
    }
}

// ---------------- Cores ----------------

struct ColorDot: View {
    var c: Int
    var on: Bool
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Circle().fill(Color(model: c)).frame(width: 24, height: 24)
                .overlay(Circle().stroke(on ? Ui.accent : Color.gray, lineWidth: on ? 3 : 1))
        }.buttonStyle(.plain)
    }
}

struct ColorRow: View {
    var current: Int
    var onPick: (Int) -> Void
    @State private var more = false
    var body: some View {
        HStack(spacing: 6) {
            ForEach(PALETTE, id: \.self) { c in ColorDot(c: c, on: current == c) { onPick(c) } }
            if !PALETTE.contains(current) { ColorDot(c: current, on: true) { more = true } }
            Button { more = true } label: {
                Circle().fill(AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red], center: .center)).frame(width: 24, height: 24)
            }.buttonStyle(.plain)
        }
        .sheet(isPresented: $more) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Cores").font(.headline)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 7), spacing: 10) {
                    ForEach(EXTRA_COLORS, id: \.self) { c in ColorDot(c: c, on: current == c) { onPick(c); more = false }.frame(width: 32, height: 32) }
                }
                Button("Fechar") { more = false }
            }
            .padding(20)
            .presentationDetents([.height(320)])
        }
    }
}

// ---------------- Diálogos simples ----------------

struct NameSheet: View {
    var title: String
    var label: String
    @State var text: String
    var onOk: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form { TextField(label, text: $text) }
                .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Salvar") { if !text.trimmingCharacters(in: .whitespaces).isEmpty { onOk(text); dismiss() } } }
                }
        }
        .presentationDetents([.height(220)])
    }
}

// ---------------- Fotos, câmera e arquivos ----------------

struct PhotoPicker: UIViewControllerRepresentable {
    var limit = 0
    var onPick: ([(Data, String)]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration()
        cfg.filter = .images
        cfg.selectionLimit = limit
        cfg.preferredAssetRepresentationMode = .current
        let vc = PHPickerViewController(configuration: cfg)
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onPick) }

    final class Coord: NSObject, PHPickerViewControllerDelegate {
        let onPick: ([(Data, String)]) -> Void
        init(_ f: @escaping ([(Data, String)]) -> Void) { onPick = f }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            if results.isEmpty { onPick([]); return }
            let g = DispatchGroup()
            var out = [(Data, String)?](repeating: nil, count: results.count)
            for (i, r) in results.enumerated() {
                let p = r.itemProvider
                let type = [UTType.jpeg, .heic, .png, .image].first { p.hasItemConformingToTypeIdentifier($0.identifier) } ?? .image
                g.enter()
                p.loadDataRepresentation(forTypeIdentifier: type.identifier) { d, _ in
                    if let d = d { out[i] = (d, type.preferredFilenameExtension ?? "jpg") }
                    g.leave()
                }
            }
            g.notify(queue: .main) { self.onPick(out.compactMap { $0 }) }
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage?) -> Void
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let vc = UIImagePickerController()
        vc.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        vc.delegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(onImage) }
    final class Coord: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImage: (UIImage?) -> Void
        init(_ f: @escaping (UIImage?) -> Void) { onImage = f }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            onImage(info[.originalImage] as? UIImage)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true); onImage(nil) }
    }
}

struct Pill<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        HStack(spacing: 0) { content }
            .padding(.horizontal, 2)
            .background(Capsule().fill(Ui.panel2))
    }
}

struct BarIcon: View {
    var symbol: String
    var label: String
    var enabled = true
    var on = false
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 18))
                .foregroundColor(!enabled ? Ui.line : (on ? Ui.accent : Ui.text))
                .frame(width: 40, height: 40)
                .background(Circle().fill(on ? Ui.accent.opacity(0.3) : Color.clear))
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

/// Ícone desenhado de cada forma.
struct ShapeGlyph: View {
    var tool: Tool
    var tint: Color
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * w, y: y * h) }
            var p = Path()
            func poly(_ pts: [CGPoint], _ close: Bool) { p.move(to: pts[0]); pts.dropFirst().forEach { p.addLine(to: $0) }; if close { p.closeSubpath() } }
            func head(_ tip: CGPoint, _ from: CGPoint) {
                let a = atan2(tip.y - from.y, tip.x - from.x), s = 0.26 * w
                p.move(to: CGPoint(x: tip.x - s * cos(a - 0.45), y: tip.y - s * sin(a - 0.45))); p.addLine(to: tip)
                p.addLine(to: CGPoint(x: tip.x - s * cos(a + 0.45), y: tip.y - s * sin(a + 0.45)))
            }
            var dash: [CGFloat] = []
            switch tool {
            case .LINE: poly([P(0.12, 0.88), P(0.88, 0.12)], false)
            case .DASHED: poly([P(0.12, 0.88), P(0.88, 0.12)], false); dash = [5, 4]
            case .ARROW: poly([P(0.12, 0.88), P(0.88, 0.12)], false); head(P(0.88, 0.12), P(0.12, 0.88))
            case .DARROW: poly([P(0.12, 0.88), P(0.88, 0.12)], false); head(P(0.88, 0.12), P(0.12, 0.88)); head(P(0.12, 0.88), P(0.88, 0.12))
            case .DIM:
                poly([P(0.1, 0.5), P(0.9, 0.5)], false); head(P(0.9, 0.5), P(0.1, 0.5)); head(P(0.1, 0.5), P(0.9, 0.5))
                poly([P(0.1, 0.25), P(0.1, 0.75)], false); poly([P(0.9, 0.25), P(0.9, 0.75)], false)
            case .CURVE: p.move(to: P(0.12, 0.85)); p.addQuadCurve(to: P(0.88, 0.15), control: P(0.15, 0.1))
            case .ELBOW: poly([P(0.12, 0.85), P(0.12, 0.15), P(0.88, 0.15)], false)
            case .LASSO: p.addEllipse(in: CGRect(x: 0.1 * w, y: 0.14 * h, width: 0.8 * w, height: 0.55 * h)); dash = [4, 3]
            case .ROOM: poly([P(0.12, 0.2), P(0.6, 0.2), P(0.6, 0.5), P(0.88, 0.5), P(0.88, 0.85), P(0.12, 0.85)], true)
            case .RRECT: p.addRoundedRect(in: CGRect(x: 0.14 * w, y: 0.2 * h, width: 0.72 * w, height: 0.6 * h), cornerSize: CGSize(width: 0.16 * w, height: 0.16 * w))
            case .ELLIPSE: p.addEllipse(in: CGRect(x: 0.12 * w, y: 0.2 * h, width: 0.76 * w, height: 0.6 * h))
            case .TRIANGLE: poly([P(0.5, 0.14), P(0.88, 0.84), P(0.12, 0.84)], true)
            case .RTRI: poly([P(0.16, 0.14), P(0.86, 0.84), P(0.16, 0.84)], true)
            case .DIAMOND: poly([P(0.5, 0.1), P(0.9, 0.5), P(0.5, 0.9), P(0.1, 0.5)], true)
            case .TRAP: poly([P(0.3, 0.2), P(0.7, 0.2), P(0.9, 0.8), P(0.1, 0.8)], true)
            default: p.addRect(CGRect(x: 0.14 * w, y: 0.2 * h, width: 0.72 * w, height: 0.6 * h))
            }
            ctx.stroke(p, with: .color(tint), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round, dash: dash))
        }
        .frame(width: 22, height: 22)
    }
}
