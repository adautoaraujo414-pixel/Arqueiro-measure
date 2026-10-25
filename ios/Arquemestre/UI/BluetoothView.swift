import SwiftUI
import MultipeerConnectivity

/// "Ferramentas Bluetooth": procurar, conectar e diagnosticar a trena Bosch.
struct BluetoothView: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var ble: BoschBLE
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(ble.state.text).font(.headline)
                    LinearGradient(colors: [Color(argb: 0xFFE53935), Color(argb: 0xFFF5B400), Color(argb: 0xFF2E9E57), Color(argb: 0xFF1E5BD8), Color(argb: 0xFF8E24AA)], startPoint: .leading, endPoint: .trailing)
                        .frame(height: 4).clipShape(Capsule())
                    if !ble.message.isEmpty { Text(ble.message).font(.footnote).foregroundColor(.secondary) }
                    Text("Protocolo não oficial, testado com a Bosch GLM 50-27 CG. Em outros modelos, confira cada valor com o visor da trena.")
                        .font(.footnote).foregroundColor(Color(argb: 0xFFFF8A80))
                }
                if ble.state == .CONNECTED {
                    Section {
                        HStack {
                            Text(ble.deviceName ?? "Bosch")
                            Spacer()
                            Button("Desconectar") { ble.disconnect() }
                        }
                    }
                } else {
                    Section("Ferramentas encontradas") {
                        if ble.found.isEmpty { Text(ble.state == .SCANNING ? "Procurando…" : "Ligue a trena e ative o Bluetooth nela.").foregroundColor(.secondary) }
                        ForEach(ble.found) { d in
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right").foregroundColor(Ui.distBlue)
                                Text(d.name)
                                Spacer()
                                Button("Conectar") { ble.connect(d.id, name: d.name) }
                            }
                        }
                        HStack {
                            Button("Procurar de novo") { ble.startScan() }
                            Spacer()
                            Button("Mostrar todos") { ble.startScan(all: true) }
                        }.buttonStyle(.borderless)
                        if ble.lastId != nil { Button("Última trena (\(ble.lastName ?? "Bosch"))") { ble.reconnectLast() } }
                    }
                }
                Section {
                    Toggle("Mostrar painel da trena na folha", isOn: Binding(get: { !app.trenaHidden }, set: { app.setTrenaHidden(!$0) }))
                    HStack { Text("Tamanho do painel"); Slider(value: Binding(get: { app.trenaScale }, set: { app.setTrenaScale($0) }), in: 0.5...1.3) }
                    Text("Com o painel oculto, a medida continua indo direto para a cota ou o trecho selecionado.").font(.caption).foregroundColor(.secondary)
                }
                if !ble.log.isEmpty {
                    Section("Diagnóstico: últimos quadros recebidos") {
                        ForEach(Array(ble.log.enumerated()), id: \.offset) { _, l in Text(l).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary) }
                    }
                }
            }
            .navigationTitle("Ferramentas Bluetooth®").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
            .onAppear { if ble.state != .CONNECTED && ble.state != .CONNECTING { ble.startScan() } }
            .onDisappear { ble.stopScan() }
        }
    }
}

/// Ver o projeto de outro iPhone/iPad (ao vivo, só visualização).
struct PeerViewPicker: View {
    @EnvironmentObject var app: AppModel
    @EnvironmentObject var peer: PeerShare
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Escolha o aparelho de quem está compartilhando. Você vê o projeto ao vivo, com todas as medidas, mas não altera nada.").font(.footnote)
                    Text("Funciona entre iPhones e iPads com o Arquemestre. Do Android para o iPhone, mande o backup ZIP.").font(.caption).foregroundColor(.secondary)
                }
                Section("Aparelhos por perto") {
                    if peer.found.isEmpty { Text("Procurando… no aparelho do dono: Editor de móveis → 📤 Compartilhar.").foregroundColor(.secondary) }
                    ForEach(peer.found, id: \.self) { p in
                        Button("📱 \(p.displayName)") {
                            peer.connect(p)
                            app.moveisView = true
                            app.screen = .moveis
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Ver projeto de outro aparelho").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { peer.disconnect(); dismiss() } } }
            .onAppear { peer.browse() }
        }
    }
}

/// Dono: compartilhando o projeto aberto.
struct ShareHostView: View {
    @EnvironmentObject var peer: PeerShare
    @Environment(\.dismiss) private var dismiss
    var onPush: () -> Void
    var body: some View {
        VStack(spacing: 14) {
            Text("Compartilhar projeto").font(.title3.bold())
            Text(peer.hosting ? "📡 Compartilhando · " + (peer.viewers == 0 ? "ninguém vendo ainda" : "\(peer.viewers) vendo agora") : "Ligando…")
            Text("No outro iPhone/iPad (com o Arquemestre): menu ⋯ → Ver projeto de outro iPhone → escolher este aparelho. Ele vê tudo ao vivo, mas não altera nada.")
                .font(.footnote).foregroundColor(.secondary).multilineTextAlignment(.center)
            HStack {
                Button("Parar de compartilhar", role: .destructive) { peer.stopHost(); dismiss() }
                Spacer()
                Button("Continuar editando") { dismiss() }.buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .presentationDetents([.medium])
        .onAppear { peer.startHost(); onPush() }
    }
}
