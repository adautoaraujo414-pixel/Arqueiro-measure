import Foundation
import UIKit
import ImageIO

/// Pastas do app. "files/" tem a mesma estrutura do Android (files/projects, files/moveis),
/// assim o backup ZIP é o mesmo nos dois sistemas.
enum AppPaths {
    static var base: URL = {
        let fm = FileManager.default
        let u = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("Arquemestre", isDirectory: true)
        try? fm.createDirectory(at: u, withIntermediateDirectories: true)
        var v = u
        var rv = URLResourceValues(); rv.isExcludedFromBackup = false
        try? v.setResourceValues(rv)
        return u
    }()
    static var files: URL {
        let files = base.appendingPathComponent("files", isDirectory: true)
        // Se a restauração foi interrompida, não cria uma pasta vazia sobre a cópia anterior.
        do { try BackupFileSwap.recoverIfNeeded(at: files) } catch { return files }
        return dir(files)
    }
    static var projects: URL { dir(files.appendingPathComponent("projects", isDirectory: true)) }
    static var moveis: URL { dir(files.appendingPathComponent("moveis", isDirectory: true)) }
    /// Pasta visível no app Arquivos ("No meu iPhone › Arquemestre").
    static var documents: URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] }

    @discardableResult
    static func dir(_ u: URL) -> URL {
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }
}

/// Persistência das notas e dados (escrita atômica com cópia .bak, igual ao Android).
final class Store {
    let root: URL
    private let lock = NSLock()
    var imagesDir: URL { AppPaths.dir(root.appendingPathComponent("images", isDirectory: true)) }
    var notesDir: URL { AppPaths.dir(root.appendingPathComponent("notes", isDirectory: true)) }
    var thumbsDir: URL { AppPaths.dir(root.appendingPathComponent("thumbs", isDirectory: true)) }
    var logoFile: URL { root.appendingPathComponent("company_logo.png") }

    init(root: URL = AppPaths.projects) {
        self.root = root
        _ = imagesDir; _ = notesDir
    }

    func imageFile(_ name: String) -> URL { imagesDir.appendingPathComponent(name) }

    // ---- escrita/leitura segura ----
    func writeAtomic(_ url: URL, _ text: String) {
        lock.lock(); defer { lock.unlock() }
        let fm = FileManager.default
        try? fm.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let tmp = URL(fileURLWithPath: url.path + ".tmp")
        do {
            try Data(text.utf8).write(to: tmp, options: [.atomic])
            if fm.fileExists(atPath: url.path) {
                let bak = URL(fileURLWithPath: url.path + ".bak")
                try? fm.removeItem(at: bak)
                try? fm.copyItem(at: url, to: bak)
                _ = try fm.replaceItemAt(url, withItemAt: tmp)
            } else {
                try fm.moveItem(at: tmp, to: url)
            }
        } catch {
            try? Data(text.utf8).write(to: url, options: [.atomic])
        }
    }

    func readWithRecovery<T>(_ url: URL, _ parse: (String) throws -> T) -> T? {
        lock.lock(); defer { lock.unlock() }
        for c in [url, URL(fileURLWithPath: url.path + ".bak"), URL(fileURLWithPath: url.path + ".tmp")] {
            guard let d = try? Data(contentsOf: c), let s = String(data: d, encoding: .utf8) else { continue }
            if let v = try? parse(s) { return v }
        }
        return nil
    }

    // ---- índice ----
    private var indexFile: URL { root.appendingPathComponent("index.json") }
    func loadIndex() -> LibIndex { readWithRecovery(indexFile, JsonCodec.indexFromJson) ?? LibIndex() }
    func saveIndex(_ i: LibIndex) { writeAtomic(indexFile, JsonCodec.indexToJson(i)) }

    // ---- notas ----
    private func noteFile(_ id: String) -> URL { notesDir.appendingPathComponent("\(id).json") }
    func loadNote(_ id: String) -> Note? { readWithRecovery(noteFile(id), JsonCodec.noteFromJson) }
    func saveNote(_ n: Note) { writeAtomic(noteFile(n.id), JsonCodec.noteToJson(n)) }
    func deleteNote(_ id: String) {
        let f = noteFile(id)
        for u in [f, URL(fileURLWithPath: f.path + ".bak"), URL(fileURLWithPath: f.path + ".tmp")] { try? FileManager.default.removeItem(at: u) }
    }

    // ---- orçamentos, empresa, agenda, leituras ----
    private var quotesFile: URL { root.appendingPathComponent("quotes.json") }
    private var companyFile: URL { root.appendingPathComponent("company.json") }
    private var agendaFile: URL { root.appendingPathComponent("agenda.json") }
    private var readingsFile: URL { root.appendingPathComponent("readings.json") }

    func loadQuotes() -> [Quote] { readWithRecovery(quotesFile, JsonCodec.quotesFromJson) ?? [] }
    func saveQuotes(_ l: [Quote]) { writeAtomic(quotesFile, JsonCodec.quotesToJson(l)) }
    func loadCompany() -> Company { readWithRecovery(companyFile, JsonCodec.companyFromJson) ?? Company() }
    func saveCompany(_ c: Company) { writeAtomic(companyFile, JsonCodec.companyToJson(c)) }
    func loadAgenda() -> [Appointment] { readWithRecovery(agendaFile, JsonCodec.agendaFromJson) ?? [] }
    func saveAgenda(_ l: [Appointment]) { writeAtomic(agendaFile, JsonCodec.agendaToJson(l)) }
    func loadReadings() -> [Reading] { readWithRecovery(readingsFile, JsonCodec.readingsFromJson) ?? [] }
    func saveReadings(_ l: [Reading]) { writeAtomic(readingsFile, JsonCodec.readingsToJson(l)) }

    // ---- fotos ----
    /// Guarda a foto original sem recomprimir. Devolve o nome do arquivo.
    func importImage(data: Data, ext: String) throws -> String {
        let name = "\(newId()).\(ext.isEmpty ? "img" : ext)"
        try data.write(to: imageFile(name), options: [.atomic])
        return name
    }

    // ---- ligação nota ↔ projeto de móveis (no Android ficava nas preferências) ----
    private var linksFile: URL { root.appendingPathComponent("links.json") }
    func loadLinks() -> [String: String] {
        readWithRecovery(linksFile) { s -> [String: String] in (try JsonCodec.parseObject(s)).compactMapValues { $0 as? String } } ?? [:]
    }
    func saveLinks(_ m: [String: String]) { writeAtomic(linksFile, JsonCodec.string(m)) }
}

/// Imagens das fotos (reduzidas para a tela, original fica no disco).
final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let store = Store()
    private let warmQueue = DispatchQueue(label: "arque.fotos", qos: .utility)
    private var warming = Set<String>()
    private let warmLock = NSLock()
    init() {
        cache.countLimit = 60
        // limite também em memória: 60 fotos de 2400 px passariam de 1 GB e o iOS fecharia o app
        cache.totalCostLimit = 240 * 1024 * 1024
    }

    private static func cost(_ img: UIImage) -> Int { img.cgImage.map { $0.bytesPerRow * $0.height } ?? 0 }

    private func decode(_ name: String, _ maxPx: CGFloat) -> UIImage? {
        let url = store.imageFile(name)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                     kCGImageSourceCreateThumbnailWithTransform: true,
                                     kCGImageSourceThumbnailMaxPixelSize: maxPx]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        return UIImage(cgImage: cg)
    }

    func image(_ name: String, maxPx: CGFloat = 2400) -> UIImage? {
        let key = "\(name)#\(Int(maxPx))" as NSString
        if let i = cache.object(forKey: key) { return i }
        guard let img = decode(name, maxPx) else { return nil }
        cache.setObject(img, forKey: key, cost: Self.cost(img))
        return img
    }

    /// Degrau de tamanho (lado maior, em pixels) que cobre o que a tela pede.
    static func step(_ px: CGFloat) -> Int {
        var side = 256
        while CGFloat(side) < px && side < 2048 { side *= 2 }
        return CGFloat(side) < px ? 2400 : side
    }

    private static func dkey(_ name: String, _ side: Int) -> NSString { "\(name)@\(side)" as NSString }

    /// Foto pronta pra tela: no tamanho em que aparece (degraus de 2×) e já no formato de cor da tela.
    /// Desenhar a foto de 2400 px a cada quadro (reduzindo e convertendo a cor toda vez) pesava ao mover a folha e ao escrever.
    func display(_ name: String, px: CGFloat, warm: Bool = true) -> UIImage? {
        let side = Self.step(px)
        if let i = cache.object(forKey: Self.dkey(name, side)) { return i }
        // já tem uma maior pronta: usa ela agora (não para pra abrir a foto de novo) e deixa o tamanho certo pra depois
        var big = side
        while big < 2400 {
            big = big >= 2048 ? 2400 : big * 2
            if let i = cache.object(forKey: Self.dkey(name, big)) { warmUp(name, side); return i }
        }
        guard let img = makeDisplay(name, side) else { return nil }
        cache.setObject(img, forKey: Self.dkey(name, side), cost: Self.cost(img))
        // a lupa da medida mostra a foto 3,4× maior e o zoom pede o degrau seguinte: deixa pronto em segundo plano
        if warm { warmUp(name, Self.step(px * 3.4)) }
        return img
    }

    private func makeDisplay(_ name: String, _ side: Int) -> UIImage? {
        guard let raw = decode(name, CGFloat(side)), let cg = raw.cgImage else { return nil }
        let size = CGSize(width: cg.width, height: cg.height)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        fmt.preferredRange = .standard
        let a = cg.alphaInfo
        fmt.opaque = a == .none || a == .noneSkipLast || a == .noneSkipFirst
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in raw.draw(in: CGRect(origin: .zero, size: size)) }
    }

    private func warmUp(_ name: String, _ side: Int) {
        let k = Self.dkey(name, side) as String
        if cache.object(forKey: k as NSString) != nil { return }
        warmLock.lock()
        let fresh = warming.insert(k).inserted
        warmLock.unlock()
        if !fresh { return }
        warmQueue.async { [weak self] in
            guard let self = self else { return }
            if self.cache.object(forKey: k as NSString) == nil, let img = self.makeDisplay(name, side) {
                self.cache.setObject(img, forKey: k as NSString, cost: Self.cost(img))
            }
            self.warmLock.lock(); self.warming.remove(k); self.warmLock.unlock()
        }
    }

    /// Tamanho já girado conforme o EXIF.
    static func orientedSize(_ url: URL) -> (Int, Int)? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let p = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = p[kCGImagePropertyPixelWidth] as? Int, let h = p[kCGImagePropertyPixelHeight] as? Int else { return nil }
        let o = (p[kCGImagePropertyOrientation] as? Int) ?? 1
        return o >= 5 ? (h, w) : (w, h)
    }
}

