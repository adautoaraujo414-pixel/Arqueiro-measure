import Foundation

/// Backup COMPLETO (notas, agenda, orçamentos, preços, projetos do editor de móveis).
/// Mesmo formato do Android: marcador + pasta "files/". Um backup do Android restaura aqui e vice-versa.
enum DataBackup {
    static let MARK = "arque-full-backup.txt"
    static let AUTO_NAME = "Arquemestre-backup-automatico.zip"

    private static func skip(_ rel: String) -> Bool {
        let low = rel.lowercased()
        return low.hasSuffix(".tmp") || low.contains("/thumbs/") || low.hasSuffix(".ds_store")
    }

    /// Grava o ZIP em url.
    static func fullBackup(to url: URL) throws {
        let fm = FileManager.default
        try? fm.removeItem(at: url)
        let z = try ZipWriter(url: url)
        try z.add(name: MARK, data: Data("Arquemestre (iOS) · backup completo · \(nowMs())".utf8))
        let basePath = AppPaths.base.resolvingSymlinksInPath().path
        let files = AppPaths.files
        if let en = fm.enumerator(at: files, includingPropertiesForKeys: [.isRegularFileKey]) {
            for case let f as URL in en {
                guard (try? f.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else { continue }
                let fp = f.resolvingSymlinksInPath().path
                guard fp.hasPrefix(basePath + "/") else { continue }
                let rel = String(fp.dropFirst(basePath.count + 1))
                if skip(rel) { continue }
                guard let d = try? Data(contentsOf: f, options: .alwaysMapped) else { continue }
                try z.add(name: rel, data: d)
            }
        }
        try z.finish()
    }

    enum RestoreError: LocalizedError {
        case invalid
        var errorDescription: String? { "Backup inválido: nada foi alterado" }
    }

    /// Restaura um backup (do iOS ou do Android). Valida tudo antes de apagar qualquer coisa.
    static func restore(from url: URL) throws {
        let zip = try ZipReader(url: url)
        let fm = FileManager.default
        let staging = AppPaths.base.deletingLastPathComponent().appendingPathComponent("Arquemestre_restore", isDirectory: true)
        try? fm.removeItem(at: staging)
        try fm.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: staging) }
        let full = zip.has(MARK)
        var wrote = 0
        for e in zip.entries where !e.isDir {
            if e.name == MARK || e.name.contains("..") || e.name.hasPrefix("/") { continue }
            let rel: String
            if full {
                // do Android só interessa "files/" (preferências e WebView ficam de fora)
                guard e.name.hasPrefix("files/") else { continue }
                rel = e.name
            } else {
                // backup antigo (só as notas): vai para files/projects
                rel = "files/projects/" + e.name
            }
            if skip(rel) { continue }
            let target = staging.appendingPathComponent(rel)
            guard target.standardizedFileURL.path.hasPrefix(staging.standardizedFileURL.path + "/") else { throw RestoreError.invalid }
            _ = rel
            try fm.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
            try zip.read(e).write(to: target)
            wrote += 1
        }
        let idx = staging.appendingPathComponent("files/projects/index.json")
        guard wrote > 0, let txt = try? String(contentsOf: idx, encoding: .utf8), (try? JsonCodec.indexFromJson(txt)) != nil else {
            // backup só de móveis também vale
            guard fm.fileExists(atPath: staging.appendingPathComponent("files/moveis").path) else { throw RestoreError.invalid }
            try swapIn(staging)
            return
        }
        try swapIn(staging)
    }

    private static func swapIn(_ staging: URL) throws {
        let fm = FileManager.default
        let old = AppPaths.files
        try? fm.removeItem(at: old)
        try fm.moveItem(at: staging.appendingPathComponent("files"), to: old)
        AppPaths.dir(AppPaths.projects.appendingPathComponent("images"))
        AppPaths.dir(AppPaths.projects.appendingPathComponent("notes"))
    }

    /// Cópia automática na pasta do app no Arquivos (no máximo a cada 12 h).
    static func autoBackup(force: Bool = false) {
        let d = UserDefaults.standard
        let now = Date().timeIntervalSince1970
        if !force && now - d.double(forKey: "autoBackupLast") < 12 * 3600 { return }
        let tmp = AppPaths.documents.appendingPathComponent(AUTO_NAME + ".tmp")
        do {
            try fullBackup(to: tmp)
            let dst = AppPaths.documents.appendingPathComponent(AUTO_NAME)
            if FileManager.default.fileExists(atPath: dst.path) { _ = try FileManager.default.replaceItemAt(dst, withItemAt: tmp) }
            else { try FileManager.default.moveItem(at: tmp, to: dst) }
            d.set(now, forKey: "autoBackupLast")
        } catch {
            try? FileManager.default.removeItem(at: tmp)
        }
    }
}
