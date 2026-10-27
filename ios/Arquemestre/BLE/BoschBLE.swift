import Foundation
import CoreBluetooth
import Combine

enum BleState: String {
    case UNAVAILABLE, OFF, NO_PERMISSION, IDLE, SCANNING, CONNECTING, CONNECTED, ERROR
    var text: String {
        switch self {
        case .CONNECTED: return tr("Pronto")
        case .CONNECTING: return tr("Conectando…")
        case .SCANNING: return tr("Procurando ferramentas…")
        case .IDLE: return tr("Pronto")
        case .OFF: return tr("Bluetooth desligado")
        case .NO_PERMISSION: return tr("Falta permissão de Bluetooth")
        case .UNAVAILABLE: return tr("Bluetooth LE indisponível")
        case .ERROR: return tr("Erro")
        }
    }
}

struct FoundDevice: Identifiable, Equatable {
    var id: UUID
    var name: String
    var rssi: Int
}

/// Conexão BLE real com trenas Bosch (CoreBluetooth). Toda leitura vem de um quadro recebido da trena.
final class BoschBLE: NSObject, ObservableObject {
    @Published private(set) var state: BleState = .IDLE
    @Published private(set) var message = ""
    @Published private(set) var deviceName: String?
    @Published private(set) var found: [FoundDevice] = []
    @Published private(set) var log: [String] = []

    var onReading: ((Reading) -> Void)?

    private var central: CBCentralManager?
    private var peripherals: [UUID: CBPeripheral] = [:]
    private var current: CBPeripheral?
    private var userDisconnected = false
    private var reconnectAttempts = 0
    private var scanAll = false
    private var wantScan = false
    private var pendingConnect: UUID?
    private var notifyEnabled = 0
    private var servicesLeft = 0
    private var candidates: [CBCharacteristic] = []
    private var scanTimer: Timer?

    private let d = UserDefaults.standard
    var lastId: UUID? { d.string(forKey: "ble.lastId").flatMap(UUID.init(uuidString:)) }
    var lastName: String? { d.string(forKey: "ble.lastName") }

    private func ensureCentral() -> CBCentralManager {
        if let c = central { return c }
        let c = CBCentralManager(delegate: self, queue: .main, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        central = c
        return c
    }

    private func setState(_ s: BleState, _ msg: String? = nil) {
        state = s
        if let m = msg { message = m }
    }

    private func addLog(_ line: String) { log = Array(([line] + log).prefix(60)) }

    private func ready() -> Bool {
        let c = ensureCentral()
        switch c.state {
        case .poweredOn:
            if [.UNAVAILABLE, .OFF, .NO_PERMISSION].contains(state) { setState(.IDLE, "") }
            return true
        case .unauthorized: setState(.NO_PERMISSION, tr("Libere o Bluetooth para o Arquemestre em Ajustes › Privacidade › Bluetooth")); return false
        case .unsupported: setState(.UNAVAILABLE, tr("Este aparelho não tem Bluetooth LE")); return false
        case .poweredOff: setState(.OFF, tr("Ligue o Bluetooth")); return false
        default: return false // ainda iniciando: o delegate continua
        }
    }

    // ---- varredura ----
    func startScan(all: Bool = false) {
        scanAll = all
        wantScan = true
        guard ready() else { return }
        wantScan = false
        guard let c = central else { return }
        if c.isScanning { c.stopScan() }
        found = []
        setState(.SCANNING, all ? tr("Procurando todos os aparelhos BLE…") : tr("Procurando trena Bosch…"))
        c.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 20, repeats: false) { [weak self] _ in self?.stopScan() }
    }

    func stopScan() {
        scanTimer?.invalidate()
        guard let c = central, c.isScanning else { return }
        c.stopScan()
        if state == .SCANNING { setState(.IDLE, found.isEmpty ? tr("Nenhuma trena encontrada") : "") }
    }

    // ---- conexão ----
    func connect(_ id: UUID, name: String? = nil) {
        pendingConnect = id
        guard ready(), let c = central else { return }
        pendingConnect = nil
        stopScan()
        userDisconnected = false
        closeCurrent()
        let p = peripherals[id] ?? c.retrievePeripherals(withIdentifiers: [id]).first
        guard let per = p else { setState(.ERROR, tr("Trena não encontrada. Procure de novo.")); return }
        peripherals[id] = per
        current = per
        per.delegate = self
        deviceName = name ?? per.name
        d.set(id.uuidString, forKey: "ble.lastId"); d.set(deviceName, forKey: "ble.lastName")
        setState(.CONNECTING, tr("Conectando…"))
        addLog("Conectando a \(deviceName ?? id.uuidString)")
        c.connect(per, options: nil)
    }

    func reconnectLast() { if let id = lastId { connect(id, name: lastName) } }

    func disconnect() {
        userDisconnected = true
        closeCurrent()
        deviceName = nil
        setState(.IDLE, "")
    }

    private func closeCurrent() {
        if let p = current, let c = central { c.cancelPeripheralConnection(p) }
        current = nil
    }

    private func handleFrame(_ bytes: [UInt8]) {
        let hex = BoschProtocol.toHex(bytes)
        let mm = BoschProtocol.parseMm(bytes)
        addLog(hex + (mm != nil ? "  → \(Int(mm!)) mm" : "  (sem medida)"))
        if let v = mm {
            onReading?(Reading(mm: v, source: .BLUETOOTH, timeMs: nowMs(), device: deviceName, rawHex: hex))
        }
    }

    private func finishSetup(_ p: CBPeripheral) {
        if candidates.isEmpty {
            setState(.ERROR, tr("Serviço Bosch não encontrado neste aparelho (veja o diagnóstico)"))
            return
        }
        notifyEnabled = 0
        let notifiers = candidates.filter { $0.properties.contains(.notify) || $0.properties.contains(.indicate) }
        for ch in notifiers { p.setNotifyValue(true, for: ch) }
        if notifiers.isEmpty { setState(.ERROR, tr("Conectou, mas não foi possível ativar o recebimento de medidas")) }
    }

    private func sendAutosync(_ p: CBPeripheral) {
        let cmd = Data(BoschProtocol.ENABLE_AUTOSYNC)
        for ch in candidates {
            if ch.properties.contains(.write) { p.writeValue(cmd, for: ch, type: .withResponse) }
            else if ch.properties.contains(.writeWithoutResponse) { p.writeValue(cmd, for: ch, type: .withoutResponse); addLog("Comando enviado em \(ch.uuid.uuidString)") }
        }
    }
}

extension BoschBLE: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        if ready() {
            if wantScan { startScan(all: scanAll) }
            if let id = pendingConnect { connect(id) }
        }
    }

    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral, advertisementData ad: [String: Any], rssi: NSNumber) {
        let rawName = (ad[CBAdvertisementDataLocalNameKey] as? String) ?? p.name
        let uuids = ((ad[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []).map(\.uuidString)
        let hasService = uuids.contains { BoschProtocol.isBoschService($0) }
        let nameMatch = rawName.map(BoschProtocol.nameMatches) ?? false
        if !scanAll && !hasService && !nameMatch { return }
        peripherals[p.identifier] = p
        let dev = FoundDevice(id: p.identifier, name: rawName ?? "Bosch (\(p.identifier.uuidString.prefix(5)))", rssi: rssi.intValue)
        found = (found.filter { $0.id != dev.id } + [dev]).sorted { $0.rssi > $1.rssi }
    }

    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) {
        reconnectAttempts = 0
        setState(.CONNECTING, tr("Descobrindo serviços…"))
        addLog("Conectado; descobrindo serviços")
        p.discoverServices(nil)
    }

    func centralManager(_ c: CBCentralManager, didFailToConnect p: CBPeripheral, error: Error?) {
        addLog("Falha ao conectar: \(error?.localizedDescription ?? "?")")
        retry(p)
    }

    func centralManager(_ c: CBCentralManager, didDisconnectPeripheral p: CBPeripheral, error: Error?) {
        addLog("Desconectado\(error.map { " (\($0.localizedDescription))" } ?? "")")
        retry(p)
    }

    private func retry(_ p: CBPeripheral) {
        guard !userDisconnected else { return }
        if reconnectAttempts < 5 {
            reconnectAttempts += 1
            setState(.CONNECTING, tr("Tentando de novo ({0}/5)…", reconnectAttempts))
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self = self, !self.userDisconnected else { return }
                self.connect(p.identifier, name: self.deviceName)
            }
        } else {
            setState(.ERROR, tr("Não conectou. Ligue a trena, ative o Bluetooth nela e chegue perto."))
        }
    }
}

extension BoschBLE: CBPeripheralDelegate {
    func peripheral(_ p: CBPeripheral, didDiscoverServices error: Error?) {
        guard error == nil, let services = p.services else { setState(.ERROR, tr("Falha ao ler serviços")); return }
        candidates = []
        servicesLeft = services.count
        if services.isEmpty { finishSetup(p); return }
        for s in services {
            addLog("SERVIÇO \(s.uuid.uuidString)")
            p.discoverCharacteristics(nil, for: s)
        }
    }

    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        let sid = s.uuid.uuidString
        for ch in s.characteristics ?? [] {
            var props: [String] = []
            if ch.properties.contains(.read) { props.append("ler") }
            if ch.properties.contains(.write) { props.append("escrever") }
            if ch.properties.contains(.writeWithoutResponse) { props.append("escrever-sem-resp") }
            if ch.properties.contains(.notify) { props.append("notificar") }
            if ch.properties.contains(.indicate) { props.append("indicar") }
            addLog("  char \(ch.uuid.uuidString) [\(props.joined(separator: ","))]")
            if BoschProtocol.isBoschService(sid) || BoschProtocol.isBoschCharacteristic(ch.uuid.uuidString) { candidates.append(ch) }
        }
        servicesLeft -= 1
        if servicesLeft <= 0 { finishSetup(p) }
    }

    func peripheral(_ p: CBPeripheral, didUpdateNotificationStateFor ch: CBCharacteristic, error: Error?) {
        if let e = error {
            addLog("Falha ao ligar recebimento em \(ch.uuid.uuidString): \(e.localizedDescription)")
            return
        }
        notifyEnabled += 1
        addLog("Recebimento ligado em \(ch.uuid.uuidString)")
        if notifyEnabled == 1 {
            setState(.CONNECTED, tr("Conectada. Meça com a trena."))
            sendAutosync(p)
        }
    }

    func peripheral(_ p: CBPeripheral, didWriteValueFor ch: CBCharacteristic, error: Error?) {
        addLog(error == nil ? "Comando enviado em \(ch.uuid.uuidString)" : "Falha ao enviar comando em \(ch.uuid.uuidString)")
    }

    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        guard error == nil, let v = ch.value else { return }
        handleFrame([UInt8](v))
    }
}
