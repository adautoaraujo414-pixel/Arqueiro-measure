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
    static var files: URL { dir(base.appendingPathComponent("files", isDirectory: true)) }
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
    init() { cache.countLimit = 60 }

    func image(_ name: String, maxPx: CGFloat = 2400) -> UIImage? {
        let key = "\(name)#\(Int(maxPx))" as NSString
        if let i = cache.object(forKey: key) { return i }
        let url = store.imageFile(name)
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                     kCGImageSourceCreateThumbnailWithTransform: true,
                                     kCGImageSourceThumbnailMaxPixelSize: maxPx]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let img = UIImage(cgImage: cg)
        cache.setObject(img, forKey: key)
        return img
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
