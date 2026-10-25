import Foundation

/// Protocolo BLE das trenas Bosch (GLM 50 C, GLM 100 C, GLM 50-27 CG…), o mesmo do Android.
/// Bosch não publica a especificação: vem de engenharia reversa da comunidade e foi conferido
/// com a GLM 50-27 CG. O app procura qualquer serviço/característica Bosch, liga as indicações
/// e manda o comando "autosync".
enum BoschProtocol {
    static let SERVICE_FDE8 = "FDE8"
    static let SERVICE_MT = "02A6C0D0-0451-4000-B000-FB3210111989"
    static let SERVICE_LEGACY = "00005301-0000-0041-4C50-574953450000"
    static let CHARACTERISTIC_LEGACY = "00005302-0000-0041-4C50-574953450000"
    private static let VENDOR_SUFFIX = "-0451-4000-B000-FB3210111989"

    static func isBoschService(_ uuid: String) -> Bool {
        let u = uuid.uppercased()
        return u == SERVICE_FDE8 || u == "0000FDE8-0000-1000-8000-00805F9B34FB" || u == SERVICE_MT || u == SERVICE_LEGACY || u.hasSuffix(VENDOR_SUFFIX)
    }

    static func isBoschCharacteristic(_ uuid: String) -> Bool {
        let u = uuid.uppercased()
        return u.hasSuffix(VENDOR_SUFFIX) || u == CHARACTERISTIC_LEGACY
    }

    /// Pede à trena que envie cada medida sozinha.
    static let ENABLE_AUTOSYNC: [UInt8] = [0xC0, 0x55, 0x02, 0x01, 0x00, 0x1A]

    static func nameMatches(_ name: String) -> Bool {
        name.range(of: "(GLM|PLR|GCL|GRL|GIM|GTL|BLAZE|BOSCH|AD ?50)", options: [.regularExpression, .caseInsensitive]) != nil
    }

    static let MIN_METERS: Float = 0.005
    static let MAX_METERS: Float = 300

    private static func plausible(_ f: Float) -> Bool { f.isFinite && f >= MIN_METERS && f <= MAX_METERS }

    private static func floatLE(_ b: [UInt8], _ off: Int) -> Float {
        let bits = UInt32(b[off]) | (UInt32(b[off + 1]) << 8) | (UInt32(b[off + 2]) << 16) | (UInt32(b[off + 3]) << 24)
        return Float(bitPattern: bits)
    }

    /// Metros do quadro: formato conhecido (C0 55 10 06 …, float LE no byte 7) e, para outros quadros C0,
    /// o primeiro float32 LE plausível.
    static func parseMeasurementMeters(_ frame: [UInt8]) -> Float? {
        if frame.count < 8 || frame[0] != 0xC0 { return nil }
        if frame[1] == 0x55 && frame.count >= 11 && frame[2] == 0x10 {
            if frame[3] != 0x06 { return nil } // leitura inválida
            let f = floatLE(frame, 7)
            return plausible(f) ? f : nil
        }
        let payload = Array(frame[3...])
        if payload.count < 4 { return nil }
        for off in 0...(payload.count - 4) {
            let f = floatLE(payload, off)
            if plausible(f) { return f }
        }
        return nil
    }

    /// Igual ao visor da trena: arredonda pro milímetro (0,5477 m → 548 mm).
    static func metersToMm(_ m: Float) -> Double {
        let t = (Double(m) * 10000).rounded()
        return floor((t + 5) / 10)
    }

    static func parseMm(_ frame: [UInt8]) -> Double? { parseMeasurementMeters(frame).map(metersToMm) }

    static func toHex(_ b: [UInt8]) -> String { b.map { String(format: "%02X", $0) }.joined(separator: " ") }
}
