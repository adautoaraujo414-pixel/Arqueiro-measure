import Foundation
import CryptoKit

/// Sincronizar com outro aparelho (Wi-Fi) — mesma regra do Android e do Windows (SyncCore.kt):
/// cada item (nota, projeto de móveis, orçamento, agenda) tem um id e uma "impressão digital" (hash do JSON canônico),
/// assim dá pra ver o que é igual, o que só tem de um lado e o que mudou, sem duplicar nada.
enum SyncCore {
    static let version = 1
    static let kinds = ["note", "proj", "quote", "agenda"]

    struct Item: Equatable {
        let k: String, id: String, title: String, sub: String, hash: String, mod: Int64
        var key: String { k + "|" + id }
        init(k: String, id: String, title: String, sub: String, hash: String, mod: Int64) {
            self.k = k; self.id = id; self.title = title; self.sub = sub; self.hash = hash; self.mod = mod
        }
        init?(_ j: [String: Any]) {
            guard let k = j["k"] as? String, let id = j["id"] as? String else { return nil }
            self.init(k: k, id: id, title: j["t"] as? String ?? "", sub: j["s"] as? String ?? "", hash: j["h"] as? String ?? "", mod: (j["m"] as? NSNumber)?.int64Value ?? 0)
        }
    }

    enum State { case same, onlyHere, onlyThere, diff }
    struct Row: Identifiable {
        let k: String, id: String, here: Item?, there: Item?
        var key: String { k + "|" + id }
        var state: State {
            if let h = here, let t = there { return h.hash == t.hash ? .same : .diff }
            return here != nil ? .onlyHere : .onlyThere
        }
        var title: String { (here ?? there)!.title }
    }

    static func compare(_ here: [Item], _ there: [Item]) -> [Row] {
        var h: [String: Item] = [:]; for i in here { h[i.key] = i }
        var t: [String: Item] = [:]; for i in there { t[i.key] = i }
        let keys = Set(h.keys).union(t.keys)
        return keys.map { k -> Row in let a = h[k], b = t[k]; return Row(k: (a ?? b)!.k, id: (a ?? b)!.id, here: a, there: b) }
            .sorted { (kinds.firstIndex(of: $0.k) ?? 9, $0.title.lowercased()) < (kinds.firstIndex(of: $1.k) ?? 9, $1.title.lowercased()) }
    }

    // MARK: JSON canônico (igual ao Kotlin)

    static func canon(_ v: Any?) -> String { var s = ""; canonTo(&s, v); return s }

    private static func isBool(_ n: NSNumber) -> Bool { CFGetTypeID(n) == CFBooleanGetTypeID() }

    private static func canonTo(_ s: inout String, _ v: Any?) {
        switch v {
        case nil, is NSNull: s += "null"
        case let n as NSNumber:
            if isBool(n) { s += n.boolValue ? "true" : "false" } else { s += num(n.doubleValue) }
        case let str as String: esc(&s, str)
        case let o as [String: Any]:
            s += "{"
            let keys = o.keys.sorted { Array($0.utf16).lexicographicallyPrecedes(Array($1.utf16)) }
            for (i, k) in keys.enumerated() { if i > 0 { s += "," }; esc(&s, k); s += ":"; canonTo(&s, o[k] ?? NSNull()) }
            s += "}"
        case let a as [Any]:
            s += "["
            for (i, x) in a.enumerated() { if i > 0 { s += "," }; canonTo(&s, x) }
            s += "]"
        default: esc(&s, "\(v!)")
        }
    }

    /// Mesma regra do Kotlin: até 1 bilhão com 6 casas, acima disso inteiro, sem ".0".
    static func num(_ d: Double) -> String {
        if d.isNaN || d.isInfinite { return "null" }
        if abs(d) >= 1e15 { return String(format: "%.0f", d) }
        let r = abs(d) < 1e9 ? (d * 1_000_000.0 + 0.5).rounded(.down) / 1_000_000.0 : d.rounded(.toNearestOrEven)
        if abs(r - r.rounded(.toNearestOrEven)) < 1e-9 { return r == 0 ? "0" : String(Int64(r.rounded(.toNearestOrEven))) }
        var t = String(format: "%.6f", r)
        while t.hasSuffix("0") { t.removeLast() }
        if t.hasSuffix(".") { t.removeLast() }
        return t == "-0" ? "0" : t
    }

    private static func esc(_ s: inout String, _ str: String) {
        s += "\""
        for u in str.unicodeScalars {
            switch u {
            case "\"": s += "\\\""
            case "\\": s += "\\\\"
            default:
                if u.value < 0x20 { s += String(format: "\\u%04x", u.value) } else { s.unicodeScalars.append(u) }
            }
        }
        s += "\""
    }

    static func sha(_ text: String) -> String { SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined() }
    static func hashOf(_ v: Any?) -> String { sha(canon(v)) }

    // MARK: arquivos

    private static func readData(_ u: URL) -> Data? {
        for c in [u, URL(fileURLWithPath: u.path + ".bak")] { if let d = try? Data(contentsOf: c) { return d } }
        return nil
    }
    private static func obj(_ u: URL) -> [String: Any]? { readData(u).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] } }
    private static func arr(_ u: URL) -> [[String: Any]] { readData(u).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [[String: Any]] } ?? [] }

    private static func projects(_ files: URL) -> URL { files.appendingPathComponent("projects", isDirectory: true) }
    private static func indexURL(_ files: URL) -> URL { projects(files).appendingPathComponent("index.json") }
    private static func noteURL(_ files: URL, _ id: String) -> URL { projects(files).appendingPathComponent("notes/\(id).json") }
    private static func listURL(_ files: URL, _ k: String) -> URL {
        switch k {
        case "quote": return projects(files).appendingPathComponent("quotes.json")
        case "agenda": return projects(files).appendingPathComponent("agenda.json")
        default: return files.appendingPathComponent("moveis/projects.json")
        }
    }

    static func safeId(_ id: String) -> Bool {
        !id.isEmpty && id.count <= 80 && !id.contains("..") && id.unicodeScalars.allSatisfy { CharacterSet.alphanumerics.contains($0) || $0 == "-" || $0 == "_" || $0 == "." }
    }
    static func safeName(_ n: String) -> Bool { !n.isEmpty && n.count <= 120 && !n.contains("/") && !n.contains("\\") && !n.contains("..") }

    private static func int64(_ v: Any?) -> Int64 { (v as? NSNumber)?.int64Value ?? 0 }
    private static func dateLabel(_ ms: Int64) -> String {
        if ms <= 0 { return "" }
        let f = DateFormatter(); f.dateFormat = "dd/MM/yyyy"; f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    /// O que este aparelho tem (lixeira fica de fora).
    static func manifest(_ files: URL) -> [Item] {
        var out: [Item] = []
        let fm = FileManager.default
        let notes = (obj(indexURL(files))?["notes"] as? [[String: Any]]) ?? []
        for m in notes {
            guard let id = m["id"] as? String, safeId(id), (m["trash"] as? Bool) != true else { continue }
            let u = noteURL(files, id)
            guard let n = obj(u), (n["trash"] as? Bool) != true else { continue }
            let pages = (n["pages"] as? [Any])?.count ?? 0
            let mod = ((try? fm.attributesOfItem(atPath: u.path)[.modificationDate]) as? Date).map { Int64($0.timeIntervalSince1970 * 1000) } ?? 0
            out.append(Item(k: "note", id: id, title: n["name"] as? String ?? (m["name"] as? String ?? ""), sub: "\(pages) folha(s)", hash: hashOf(n), mod: mod))
        }
        for k in ["proj", "quote", "agenda"] {
            for o in arr(listURL(files, k)) {
                guard let id = o["id"] as? String, safeId(id) else { continue }
                var t = "", s = "", m: Int64 = 0
                switch k {
                case "proj":
                    let cl = ((o["cliente"] as? [String: Any])?["nome"] as? String) ?? ""
                    let tt = (o["titulo"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? (o["nome"] as? String ?? "")
                    t = [cl, tt].filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.joined(separator: " · ")
                    if t.isEmpty { t = "Projeto" }
                    s = dateLabel(int64(o["updated"])); m = o["updated"] != nil ? int64(o["updated"]) : int64(o["created"])
                case "quote":
                    t = (o["client"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Orçamento"
                    s = [(o["city"] as? String) ?? "", dateLabel(int64(o["date"]))].filter { !$0.isEmpty }.joined(separator: " · "); m = int64(o["date"])
                default:
                    t = (o["title"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? "Compromisso"
                    s = dateLabel(int64(o["start"])); m = int64(o["start"])
                }
                out.append(Item(k: k, id: id, title: t, sub: s, hash: hashOf(o), mod: m))
            }
        }
        return out
    }

    private static func photos(_ n: [String: Any]) -> [String] {
        var out: [String] = []
        for p in (n["pages"] as? [[String: Any]]) ?? [] {
            for o in (p["objs"] as? [[String: Any]]) ?? [] where (o["type"] as? String) == "photo" {
                if let f = o["file"] as? String, !f.isEmpty { out.append(f) }
            }
        }
        return out
    }

    /// Pacote do item pro outro aparelho (nota leva as fotos e a pasta).
    static func export(_ files: URL, _ k: String, _ id: String) -> [String: Any]? {
        guard safeId(id) else { return nil }
        var p: [String: Any] = ["k": k, "id": id, "v": version]
        if k == "note" {
            guard let n = obj(noteURL(files, id)) else { return nil }
            p["obj"] = n
            let idx = obj(indexURL(files))
            if let m = ((idx?["notes"] as? [[String: Any]]) ?? []).first(where: { ($0["id"] as? String) == id }) { p["meta"] = m }
            if let fid = n["folderId"] as? String, !fid.isEmpty,
               let f = ((idx?["folders"] as? [[String: Any]]) ?? []).first(where: { ($0["id"] as? String) == fid }) { p["folder"] = f }
            var imgs: [String: String] = [:]
            for name in photos(n) where safeName(name) {
                if let d = try? Data(contentsOf: projects(files).appendingPathComponent("images/\(name)")) { imgs[name] = d.base64EncodedString() }
            }
            p["images"] = imgs
            return p
        }
        guard kinds.contains(k), let o = arr(listURL(files, k)).first(where: { ($0["id"] as? String) == id }) else { return nil }
        p["obj"] = o
        return p
    }

    private static func write(_ u: URL, _ value: Any) throws {
        let data = try JSONSerialization.data(withJSONObject: value)
        let fm = FileManager.default
        try fm.createDirectory(at: u.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fm.fileExists(atPath: u.path) {
            let bak = URL(fileURLWithPath: u.path + ".bak"); try? fm.removeItem(at: bak); try? fm.copyItem(at: u, to: bak)
        }
        try data.write(to: u, options: .atomic)
    }

    /// Grava o item recebido (cria ou troca). false = pacote inválido (nada gravado).
    @discardableResult
    static func apply(_ files: URL, _ p: [String: Any]) -> Bool {
        guard let k = p["k"] as? String, let id = p["id"] as? String, safeId(id), kinds.contains(k),
              let o = p["obj"] as? [String: Any], (o["id"] as? String) == id else { return false }
        do {
            if k == "note" {
                guard o["pages"] is [Any] else { return false }
                for (name, b64) in (p["images"] as? [String: String]) ?? [:] where safeName(name) {
                    guard let d = Data(base64Encoded: b64) else { continue }
                    let u = projects(files).appendingPathComponent("images/\(name)")
                    try FileManager.default.createDirectory(at: u.deletingLastPathComponent(), withIntermediateDirectories: true)
                    try d.write(to: u, options: .atomic)
                }
                try write(noteURL(files, id), o)
                var idx = obj(indexURL(files)) ?? ["v": 1, "folders": [Any](), "notes": [Any]()]
                var folders = (idx["folders"] as? [[String: Any]]) ?? []
                if let f = p["folder"] as? [String: Any], let fid = f["id"] as? String, safeId(fid), !folders.contains(where: { ($0["id"] as? String) == fid }) {
                    folders.append(["id": fid, "name": f["name"] as? String ?? "Pasta"])
                }
                idx["folders"] = folders
                let meta = (p["meta"] as? [String: Any]) ?? [:]
                let m: [String: Any] = [
                    "id": id, "name": o["name"] as? String ?? (meta["name"] as? String ?? "Nota"),
                    "folderId": o["folderId"] ?? NSNull(), "createdMs": o["createdMs"] ?? (meta["createdMs"] ?? 0),
                    "pinned": o["pinned"] as? Bool ?? false, "locked": o["locked"] as? Bool ?? false, "trash": o["trash"] as? Bool ?? false,
                    "pageCount": (o["pages"] as? [Any])?.count ?? 1, "dimCount": meta["dimCount"] ?? 0,
                ]
                var notes = (idx["notes"] as? [[String: Any]]) ?? []
                if let i = notes.firstIndex(where: { ($0["id"] as? String) == id }) { notes[i] = m } else { notes.append(m) }
                idx["notes"] = notes
                try write(indexURL(files), idx)
                return true
            }
            let u = listURL(files, k)
            var a = arr(u)
            if let i = a.firstIndex(where: { ($0["id"] as? String) == id }) { a[i] = o } else { a.append(o) }
            try write(u, a)
            return true
        } catch { return false }
    }

    static func kindLabel(_ k: String) -> String {
        switch k { case "note": return tr("Nota"); case "proj": return tr("Projeto de móveis"); case "quote": return tr("Orçamento"); default: return tr("Agenda") }
    }
}

/// Conversa com o aparelho que está em "Receber" (Android ou Windows) pelo Wi-Fi — mesmo protocolo do SyncNet.kt.
enum SyncNet {
    static let port = 47321

    /// IPs da rede local deste iPhone (Wi-Fi ou roteador).
    static func localIps() -> [String] {
        var out: [String] = []
        var ifa: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifa) == 0, let first = ifa else { return [] }
        defer { freeifaddrs(ifa) }
        var p: UnsafeMutablePointer<ifaddrs>? = first
        while let c = p {
            let flags = Int32(c.pointee.ifa_flags)
            if let a = c.pointee.ifa_addr, a.pointee.sa_family == UInt8(AF_INET), (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 {
                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo(a, socklen_t(a.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0 {
                    let ip = String(cString: host); let name = String(cString: c.pointee.ifa_name)
                    if ip.hasPrefix("192.168.") || ip.hasPrefix("10.") || (ip.hasPrefix("172.") && (16...31).contains(Int(ip.split(separator: ".")[1]) ?? 0)) {
                        if name.hasPrefix("en") || name.hasPrefix("bridge") { out.insert(ip, at: 0) } else { out.append(ip) }
                    }
                }
            }
            p = c.pointee.ifa_next
        }
        var seen = Set<String>(); return out.filter { seen.insert($0).inserted }
    }

    struct Target: Equatable { let hosts: [String]; let pin: String; let port: Int }

    /// "10-4821", "10-4821-2" ou "192.168.0.10-4821".
    static func parse(_ code: String, mine: [String] = localIps()) -> Target? {
        let p = code.replacingOccurrences(of: " ", with: "").split(separator: "-").map(String.init).filter { !$0.isEmpty }
        guard p.count >= 2 else { return nil }
        let pin = p[1].filter(\.isNumber); guard pin.count == 4 else { return nil }
        let off = p.count > 2 ? (Int(p[2]) ?? -1) : 0; guard (0...9).contains(off) else { return nil }
        let hosts: [String]
        if p[0].filter({ $0 == "." }).count == 3 { hosts = [p[0]] } else {
            guard let last = Int(p[0]), (1...254).contains(last) else { return nil }
            var seen = Set<String>()
            hosts = mine.map { ip in ip.split(separator: ".").dropLast().joined(separator: ".") + ".\(last)" }.filter { seen.insert($0).inserted }
        }
        guard !hosts.isEmpty else { return nil }
        return Target(hosts: hosts, pin: pin, port: port + off)
    }

    struct SyncError: LocalizedError { let msg: String; var errorDescription: String? { msg } }

    final class Client {
        let base: String; let pin: String
        private let session: URLSession
        /// Endereço do outro aparelho na rede local (IP da casa, não é site): http simples, liberado por NSAllowsLocalNetworking.
        static func localBase(_ host: String, _ port: Int) -> String {
            var c = URLComponents(); c.scheme = "http"; c.host = host; c.port = port
            return c.string ?? ""
        }
        init(base: String, pin: String) {
            self.base = base; self.pin = pin
            let cfg = URLSessionConfiguration.ephemeral; cfg.timeoutIntervalForRequest = 60; cfg.waitsForConnectivity = false
            session = URLSession(configuration: cfg)
        }
        func call(_ method: String, _ path: String, _ body: [String: Any]?, timeout: TimeInterval = 20) async throws -> [String: Any] {
            guard let url = URL(string: "\(base)\(path)?pin=\(pin)") else { throw SyncError(msg: "URL") }
            var r = URLRequest(url: url, timeoutInterval: timeout); r.httpMethod = method
            if let b = body { r.httpBody = try JSONSerialization.data(withJSONObject: b); r.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type") }
            let (d, resp) = try await session.data(for: r)
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            if code == 403 { throw SyncError(msg: tr("Senha errada: confira o código na tela do outro aparelho.")) }
            guard (200...299).contains(code) else { throw SyncError(msg: tr("O outro aparelho respondeu {0}", code)) }
            return (try JSONSerialization.jsonObject(with: d) as? [String: Any]) ?? [:]
        }
        func hello() async throws -> [String: Any] { try await call("GET", "/arq/hello", nil, timeout: 3) }
        func manifest() async throws -> [SyncCore.Item] { ((try await call("GET", "/arq/manifest", nil))["items"] as? [[String: Any]] ?? []).compactMap(SyncCore.Item.init) }
        func get(_ k: String, _ id: String) async throws -> [String: Any] { try await call("POST", "/arq/get", ["k": k, "id": id]) }
        func put(_ p: [String: Any]) async throws { _ = try await call("POST", "/arq/put", p) }
        func done() async { _ = try? await call("POST", "/arq/done", [:]) }

        static func find(_ t: Target) async throws -> (Client, String)? {
            for h in t.hosts {
                let c = Client(base: Client.localBase(h, t.port), pin: t.pin)
                do {
                    let j = try await c.hello()
                    if (j["app"] as? String) == "arquemestre" { return (c, j["name"] as? String ?? "") }
                } catch let e as SyncError where e.msg.hasPrefix(tr("Senha")) { throw e } catch { continue }
            }
            return nil
        }
    }

    /// Passa o que foi marcado (send: daqui pro outro · pull: do outro pra cá).
    static func transfer(_ files: URL, _ c: Client, send: [SyncCore.Row], pull: [SyncCore.Row], beforeWrite: () -> Void, progress: (Int, Int) -> Void) async -> (ok: Int, fail: Int) {
        let total = send.count + pull.count; var n = 0, ok = 0, fail = 0
        for r in send {
            if let p = SyncCore.export(files, r.k, r.id), (try? await c.put(p)) != nil { ok += 1 } else { fail += 1 }
            n += 1; progress(n, total)
        }
        if !pull.isEmpty { beforeWrite() }
        for r in pull {
            if let p = try? await c.get(r.k, r.id), SyncCore.apply(files, p) { ok += 1 } else { fail += 1 }
            n += 1; progress(n, total)
        }
        await c.done()
        return (ok, fail)
    }
}
