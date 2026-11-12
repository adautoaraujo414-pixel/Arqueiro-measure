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
        var title: String = ""
        var room: String = "cozinha"
        var city: String = ""
        /// Plano de corte recebido de outra pessoa (abre no modo corte, sem valores e sem editar).
        var corte: Bool = false
        var from: String = ""
        /// Pasta da biblioteca ("pasta" no projects.json); folderSet = a pessoa já escolheu (vazio = fora das pastas).
        var folder: String? = nil
        var folderSet: Bool = false
        /// Projeto recebido do marceneiro (cliente só vê e mexe no 3D) e data de entrega ("AAAA-MM-DD").
        var cliente: Bool = false
        var entrega: String = ""
        /// Nome do projeto: o que a pessoa deu (ex.: "Suíte") ou o ambiente do editor (Cozinha, Banheiro…).
        var label: String { title.isEmpty ? MoveisProjects.roomLabel(room) : title }
    }

    static func roomLabel(_ r: String) -> String {
        switch r {
        case "banho": return tr("Banheiro")
        case "sala": return tr("Sala")
        case "quarto": return tr("Quarto")
        case "escr": return tr("Escritório")
        case "livre": return tr("Livre (tudo)")
        default: return tr("Cozinha")
        }
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

    /// Entrega: "📅 Entrega 06/11 · faltam 3 dias"; em vermelho quando faltam 5 dias ou menos (e o projeto não foi finalizado).
    static func entregaInfo(_ p: P) -> (text: String, late: Bool)? {
        guard !p.entrega.isEmpty, p.status != "orc" else { return nil }
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX")
        guard let d = f.date(from: p.entrega) else { return nil }
        let o = DateFormatter(); o.dateFormat = "dd/MM"
        if p.status == "fin" { return (tr("✓ Entregue · {0}", o.string(from: d)), false) }
        let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()), to: d).day ?? 0
        let left = days < 0 ? tr("atrasado") : days == 0 ? tr("é hoje") : tr(days == 1 ? "falta {0} dia" : "faltam {0} dias", days)
        let late = days <= 5
        return ((late && !p.cliente ? tr("⏰ Prazo acabando") + " · " : "📅 ") + tr("Entrega {0}", o.string(from: d)) + " · " + left, late && !p.cliente)
    }

    static var file: URL { AppPaths.moveis.appendingPathComponent("projects.json") }

    static func list() -> [P] {
        guard let txt = try? String(contentsOf: file, encoding: .utf8), let a = try? JsonCodec.parseArray(txt) else { return [] }
        return a.compactMap { $0 as? [String: Any] }.compactMap { p -> P? in
            let id = JsonCodec.s(p, "id")
            if id.isEmpty { return nil }
            let nome = ((p["client"] as? [String: Any]).map { JsonCodec.s($0, "nome") } ?? "").trimmingCharacters(in: .whitespaces)
            let cur = p["current"] as? [String: Any]
            let mods = (cur?["mods"] as? [Any])?.count ?? 0
            let created = JsonCodec.int64(p, "created", 0)
            var room = (cur?["room"] as? String) ?? ""
            if room.isEmpty { room = (cur?["env"] as? String) == "livre" ? "livre" : "cozinha" }
            let city = ((p["client"] as? [String: Any]).map { JsonCodec.s($0, "cidade") } ?? "").trimmingCharacters(in: .whitespaces)
            return P(id: id, name: nome.isEmpty ? tr("Projeto sem nome") : nome, created: created,
                     updated: JsonCodec.int64(p, "updated", created), mods: mods, auto: JsonCodec.bool(p, "auto", false),
                     status: JsonCodec.s(p, "status").isEmpty ? "orc" : JsonCodec.s(p, "status"),
                     title: JsonCodec.s(p, "titulo").trimmingCharacters(in: .whitespaces), room: room, city: city,
                     corte: p["corte"] != nil, from: (((p["corte"] ?? p["cliente"]) as? [String: Any]).map { JsonCodec.s($0, "fr") } ?? "").trimmingCharacters(in: .whitespaces),
                     folder: JsonCodec.s(p, "pasta").trimmingCharacters(in: .whitespaces).isEmpty ? nil : JsonCodec.s(p, "pasta").trimmingCharacters(in: .whitespaces),
                     folderSet: p["pasta"] != nil,
                     cliente: p["cliente"] != nil, entrega: JsonCodec.s(p, "entrega"))
        }.sorted { $0.updated > $1.updated }
    }

    private static func edit(_ f: ([[String: Any]]) -> [[String: Any]]) {
        guard let txt = try? String(contentsOf: file, encoding: .utf8), let a = try? JsonCodec.parseArray(txt) else { return }
        let out = f(a.compactMap { $0 as? [String: Any] })
        try? Data(JsonCodec.string(out).utf8).write(to: file, options: [.atomic])
    }

    /// Excluir pela biblioteca nunca apaga de vez: o projeto vai pra lixeira (moveis/trash.json) e volta pelo editor (Ambiente › Histórico e recuperação).
    static func delete(_ id: String) {
        edit { arr in
            let gone = arr.filter { JsonCodec.s($0, "id") == id }
            if !gone.isEmpty { toTrash(gone) }
            return arr.filter { JsonCodec.s($0, "id") != id }
        }
    }

    private static func toTrash(_ ps: [[String: Any]]) {
        let f = AppPaths.moveis.appendingPathComponent("trash.json")
        var t: [[String: Any]] = []
        if let d = try? Data(contentsOf: f), let o = (try? JSONSerialization.jsonObject(with: d)) as? [[String: Any]] { t = o }
        let now = Int(Date().timeIntervalSince1970 * 1000)
        for p in ps { t.append(["t": now, "p": p]) }
        if t.count > 40 { t.removeFirst(t.count - 40) }
        if let d = try? JSONSerialization.data(withJSONObject: t) { try? d.write(to: f, options: .atomic) }
    }

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

    /// Pasta da biblioteca onde o projeto fica ("" = fora das pastas). Não mexe na data do projeto.
    static func setFolder(_ ids: Set<String>, _ folderId: String?) {
        edit { list in
            list.map { p in
                guard ids.contains(JsonCodec.s(p, "id")) else { return p }
                var q = p
                q["pasta"] = folderId ?? ""
                return q
            }
        }
    }

    /// Nome do projeto (ex.: "Cozinha", "Suíte"); o nome do cliente continua o mesmo.
    static func setTitle(_ id: String, _ title: String) {
        edit { list in
            list.map { p in
                guard JsonCodec.s(p, "id") == id else { return p }
                var q = p
                q["titulo"] = title.trimmingCharacters(in: .whitespaces); q["updated"] = nowMs()
                return q
            }
        }
    }

    static func clients() -> [ClientRef] {
        guard let txt = try? String(contentsOf: file, encoding: .utf8) else { return [] }
        return JsonCodec.clientsFromProjects(txt)
    }
}
