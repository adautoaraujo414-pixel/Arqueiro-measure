import SwiftUI

/// Ajustes › Sincronizar com outro aparelho (Wi-Fi). O iPhone conecta no aparelho que está em "Receber"
/// (Android ou Windows), vê o que é igual, o que só tem de um lado e o que mudou, e escolhe o que passa.
struct SyncView: View {
    @EnvironmentObject var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var err = ""
    @State private var busy = false
    @State private var client: SyncNet.Client?
    @State private var other = ""
    @State private var rows: [SyncCore.Row] = []
    @State private var choice: [String: String] = [:]
    @State private var progress = 0.0
    @State private var result = ""

    private var files: URL { AppPaths.files }

    var body: some View {
        NavigationStack {
            Form {
                if !err.isEmpty { Text(err).foregroundStyle(.red).font(.callout) }
                if client == nil {
                    Section {
                        Text(tr("No outro aparelho (Android ou Windows): Ajustes › Sincronizar com outro aparelho › Receber. Digite aqui o código que aparecer lá:"))
                            .font(.callout)
                        TextField(tr("Ex.: 10-4821"), text: $code)
                            .keyboardType(.numbersAndPunctuation).font(.system(size: 30, weight: .bold, design: .rounded))
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                        Button { connect() } label: { HStack { Text(tr("Conectar")); if busy { Spacer(); ProgressView() } } }
                            .disabled(busy || code.count < 6)
                    } footer: {
                        Text(tr("Os dois precisam estar no mesmo Wi-Fi (ou no roteador do celular). Não precisa de internet. Antes de gravar, o app faz uma cópia de segurança automática."))
                    }
                } else if !result.isEmpty {
                    Section { Text(result).font(.headline) }
                } else {
                    Section {
                        Text(tr("✅ Iguais nos dois: {0} (não passa nada)", rows.filter { $0.state == .same }.count)).foregroundStyle(.green)
                        if busy { ProgressView(value: progress) }
                    }
                    group(.onlyHere, tr("➕ Só neste iPhone (vai pro outro)"))
                    group(.onlyThere, tr("⬅️ Só no outro (vem pra cá)"))
                    group(.diff, tr("🔄 Nos dois, mas diferente (escolha qual fica)"))
                }
            }
            .navigationTitle(client == nil ? tr("Sincronizar (Wi-Fi)") : tr("Com {0}", other))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(result.isEmpty ? tr("Cancelar") : tr("Fechar")) { dismiss() }.disabled(busy) }
                if client != nil && result.isEmpty {
                    ToolbarItem(placement: .confirmationAction) { Button(tr("Passar ({0})", choice.values.filter { !$0.isEmpty }.count)) { go() }.disabled(busy) }
                }
            }
        }
    }

    @ViewBuilder private func group(_ st: SyncCore.State, _ head: String) -> some View {
        let list = rows.filter { $0.state == st }
        if !list.isEmpty {
            Section(head) {
                ForEach(list) { r in row(r) }
            }
        }
    }

    @ViewBuilder private func row(_ r: SyncCore.Row) -> some View {
        let it = (r.here ?? r.there)!
        let label = SyncCore.kindLabel(r.k) + " · " + it.title
        if r.state == .diff {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(.subheadline.weight(.semibold))
                Text(tr("Aqui: {0} · Lá: {1} · {2}", fmt(r.here?.mod), fmt(r.there?.mod), (r.here?.mod ?? 0) >= (r.there?.mod ?? 0) ? tr("a daqui é a mais nova") : tr("a de lá é a mais nova")))
                    .font(.caption).foregroundStyle(.secondary)
                Picker("", selection: Binding(get: { choice[r.key] ?? "" }, set: { choice[r.key] = $0 })) {
                    Text(tr("Não mexer")).tag("")
                    Text(tr("Mandar a daqui")).tag("send")
                    Text(tr("Trazer a de lá")).tag("pull")
                }.pickerStyle(.segmented)
            }
        } else {
            let want = r.state == .onlyHere ? "send" : "pull"
            Toggle(isOn: Binding(get: { choice[r.key] == want }, set: { choice[r.key] = $0 ? want : "" })) {
                VStack(alignment: .leading) {
                    Text(label)
                    if !it.sub.isEmpty { Text(it.sub).font(.caption).foregroundStyle(.secondary) }
                }
            }
        }
    }

    private func fmt(_ ms: Int64?) -> String {
        guard let ms, ms > 0 else { return "–" }
        let f = DateFormatter(); f.dateFormat = "dd/MM HH:mm"
        return f.string(from: Date(timeIntervalSince1970: Double(ms) / 1000))
    }

    private func connect() {
        guard let t = SyncNet.parse(code) else { err = tr("Código inválido. Ex.: 10-4821 (o que aparece no outro aparelho)."); return }
        busy = true; err = ""
        app.syncPrepare()
        let files = self.files
        Task {
            do {
                guard let found = try await SyncNet.Client.find(t) else {
                    throw SyncNet.SyncError(msg: tr("Não achei o outro aparelho. Confira se os dois estão no mesmo Wi-Fi e se a tela “Receber” está aberta."))
                }
                let (c, name) = found
                let there = try await c.manifest()
                let here = await Task.detached { SyncCore.manifest(files) }.value
                let rs = SyncCore.compare(here, there)
                await MainActor.run {
                    client = c; other = name; rows = rs; choice = [:]
                    for r in rs { if r.state == .onlyHere { choice[r.key] = "send" } else if r.state == .onlyThere { choice[r.key] = "pull" } }
                    busy = false
                }
            } catch {
                await MainActor.run { err = error.localizedDescription; busy = false }
            }
        }
    }

    private func go() {
        guard let c = client else { return }
        let send = rows.filter { choice[$0.key] == "send" }, pull = rows.filter { choice[$0.key] == "pull" }
        if send.isEmpty && pull.isEmpty { err = tr("Marque pelo menos um item."); return }
        busy = true; err = ""
        let files = self.files
        Task {
            let r = await SyncNet.transfer(files, c, send: send, pull: pull, beforeWrite: { DataBackup.autoBackup(force: true) }) { n, tot in
                Task { @MainActor in progress = Double(n) / Double(max(tot, 1)) }
            }
            await MainActor.run {
                if !pull.isEmpty { app.syncReload() }
                busy = false
                result = r.fail == 0 ? tr("Pronto: {0} item(ns) passado(s). Enviados {1}, recebidos {2}.", r.ok, send.count, pull.count)
                    : tr("Passou {0}, falhou {1}. Confira o Wi-Fi e tente de novo (o que já passou não duplica).", r.ok, r.fail)
            }
        }
    }
}
