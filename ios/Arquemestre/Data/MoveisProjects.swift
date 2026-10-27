import Foundation

/// Projetos do editor de móveis (arquivo moveis/projects.json, o mesmo que o editor usa).
enum MoveisProjects {
    struct P: Identifiable, Equatable {
        var id: String
        var name: String
        var created: Int64
        var updated: Int64
        var mods: Int
        var auto: Bool
        var status: String = "orc"
    }

    /// Status do projeto escolhido pela pessoa: orçamento, fechado (cliente fechou), produção, finalizado.
    static let statuses = ["orc", "fech", "prod", "fin"]
    static func statusLabel(_ s: String) -> String {
        switch s {
        case "fech": return tr("Fechado")
        case "prod": return tr("Produção")
        case "fin": return tr("Finalizado")
        default: return tr("Orçamento")
        }
    }
    static func statusColor(_ s: String) -> UInt32 {
        switch s {
        case "fech": return 0x1F9D55
        case "prod": return 0xD9822B
        case "fin": return 0x2F6BE0
        default: return 0x6B7280
        }
    }

    static var file: URL { AppPaths.moveis.appendingPathComponent("projects.json") }

    static func list() -> [P] {
        guard let txt = try? String(contentsOf: file, encoding: .utf8), let a = try? JsonCodec.parseArray(txt) else { return [] }
        return a.compactMap { $0 as? [String: Any] }.compactMap { p -> P? in
            let id = JsonCodec.s(p, "id")
            if id.isEmpty { return nil }
            let nome = ((p["client"] as? [String: Any]).map { JsonCodec.s($0, "nome") } ?? "").trimmingCharacters(in: .whitespaces)
            let mods = ((p["current"] as? [String: Any])?["mods"] as? [Any])?.count ?? 0
            let created = JsonCodec.int64(p, "created", 0)
            return P(id: id, name: nome.isEmpty ? tr("Projeto sem nome") : nome, created: created,
                     updated: JsonCodec.int64(p, "updated", created), mods: mods, auto: JsonCodec.bool(p, "auto", false),
                     status: JsonCodec.s(p, "status").isEmpty ? "orc" : JsonCodec.s(p, "status"))
        }.sorted { $0.updated > $1.updated }
    }

    private static func edit(_ f: ([[String: Any]]) -> [[String: Any]]) {
        guard let txt = try? String(contentsOf: file, encoding: .utf8), let a = try? JsonCodec.parseArray(txt) else { return }
        let out = f(a.compactMap { $0 as? [String: Any] })
        try? Data(JsonCodec.string(out).utf8).write(to: file, options: [.atomic])
    }

    static func delete(_ id: String) { edit { $0.filter { JsonCodec.s($0, "id") != id } } }

    static func setStatus(_ id: String, _ status: String) {
        edit { list in
            list.map { p in
                guard JsonCodec.s(p, "id") == id else { return p }
                var q = p
                q["status"] = status; q["updated"] = nowMs()
                return q
            }
        }
    }

    static func rename(_ id: String, _ name: String) {
        edit { list in
            list.map { p in
                guard JsonCodec.s(p, "id") == id else { return p }
                var q = p
                var c = (q["client"] as? [String: Any]) ?? [:]
                c["nome"] = name.trimmingCharacters(in: .whitespaces)
                q["client"] = c; q["auto"] = false; q["updated"] = nowMs()
                return q
            }
        }
    }

    static func clients() -> [ClientRef] {
        guard let txt = try? String(contentsOf: file, encoding: .utf8) else { return [] }
        return JsonCodec.clientsFromProjects(txt)
    }
}
