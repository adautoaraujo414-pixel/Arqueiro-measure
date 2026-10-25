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
            return P(id: id, name: nome.isEmpty ? "Projeto sem nome" : nome, created: created,
                     updated: JsonCodec.int64(p, "updated", created), mods: mods, auto: JsonCodec.bool(p, "auto", false))
        }.sorted { $0.updated > $1.updated }
    }

    private static func edit(_ f: ([[String: Any]]) -> [[String: Any]]) {
        guard let txt = try? String(contentsOf: file, encoding: .utf8), let a = try? JsonCodec.parseArray(txt) else { return }
        let out = f(a.compactMap { $0 as? [String: Any] })
        try? Data(JsonCodec.string(out).utf8).write(to: file, options: [.atomic])
    }

    static func delete(_ id: String) { edit { $0.filter { JsonCodec.s($0, "id") != id } } }

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
