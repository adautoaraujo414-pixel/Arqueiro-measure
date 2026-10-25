import Foundation
import Compression

/// ZIP simples (gravar e ler) só com o que o iOS já traz: o mesmo formato do backup do Android
/// (entradas "stored" ou "deflate"), para restaurar um backup feito em qualquer um dos dois.
enum Crc32 {
    private static let table: [UInt32] = (0..<256).map { i -> UInt32 in
        var c = UInt32(i)
        for _ in 0..<8 { c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1) }
        return c
    }
    static func of(_ data: Data) -> UInt32 {
        var c: UInt32 = 0xFFFFFFFF
        data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            for b in p { c = table[Int((c ^ UInt32(b)) & 0xFF)] ^ (c >> 8) }
        }
        return c ^ 0xFFFFFFFF
    }
}

enum Deflate {
    /// DEFLATE cru (RFC 1951), como o ZIP usa.
    static func compress(_ data: Data) -> Data? {
        if data.isEmpty { return Data() }
        let cap = data.count + data.count / 10 + 1024
        var out = Data(count: cap)
        let n = out.withUnsafeMutableBytes { (dst: UnsafeMutableRawBufferPointer) -> Int in
            data.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Int in
                compression_encode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, cap,
                                          src.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
            }
        }
        if n == 0 { return nil }
        out.count = n
        return out
    }

    static func decompress(_ data: Data, size: Int) -> Data? {
        if size == 0 { return Data() }
        var out = Data(count: size)
        let n = out.withUnsafeMutableBytes { (dst: UnsafeMutableRawBufferPointer) -> Int in
            data.withUnsafeBytes { (src: UnsafeRawBufferPointer) -> Int in
                compression_decode_buffer(dst.bindMemory(to: UInt8.self).baseAddress!, size,
                                          src.bindMemory(to: UInt8.self).baseAddress!, data.count, nil, COMPRESSION_ZLIB)
            }
        }
        if n != size { return nil }
        return out
    }
}

private extension Data {
    mutating func le16(_ v: UInt16) { var x = v.littleEndian; Swift.withUnsafeBytes(of: &x) { append(contentsOf: $0) } }
    mutating func le32(_ v: UInt32) { var x = v.littleEndian; Swift.withUnsafeBytes(of: &x) { append(contentsOf: $0) } }
    func u16(_ o: Int) -> UInt16 { UInt16(self[startIndex + o]) | (UInt16(self[startIndex + o + 1]) << 8) }
    func u32(_ o: Int) -> UInt32 {
        UInt32(self[startIndex + o]) | (UInt32(self[startIndex + o + 1]) << 8) | (UInt32(self[startIndex + o + 2]) << 16) | (UInt32(self[startIndex + o + 3]) << 24)
    }
}

final class ZipWriter {
    private let handle: FileHandle
    private var offset: UInt32 = 0
    private var central = Data()
    private var count: UInt16 = 0

    init(url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        handle = try FileHandle(forWritingTo: url)
    }

    private static let noCompress: Set<String> = ["jpg", "jpeg", "png", "webp", "heic", "mp4", "mov", "zip", "apk"]

    func add(name: String, data: Data) throws {
        let ext = (name as NSString).pathExtension.lowercased()
        var method: UInt16 = 0
        var body = data
        if !ZipWriter.noCompress.contains(ext), data.count > 64, let c = Deflate.compress(data), c.count < data.count {
            method = 8; body = c
        }
        let crc = Crc32.of(data)
        let nameData = Data(name.utf8)
        var h = Data()
        h.le32(0x04034b50); h.le16(20); h.le16(0x0800); h.le16(method); h.le16(0); h.le16(0x21)
        h.le32(crc); h.le32(UInt32(body.count)); h.le32(UInt32(data.count)); h.le16(UInt16(nameData.count)); h.le16(0)
        h.append(nameData)
        try handle.write(contentsOf: h)
        try handle.write(contentsOf: body)
        var c = Data()
        c.le32(0x02014b50); c.le16(20); c.le16(20); c.le16(0x0800); c.le16(method); c.le16(0); c.le16(0x21)
        c.le32(crc); c.le32(UInt32(body.count)); c.le32(UInt32(data.count)); c.le16(UInt16(nameData.count)); c.le16(0); c.le16(0)
        c.le16(0); c.le16(0); c.le32(0); c.le32(offset)
        c.append(nameData)
        central.append(c)
        offset += UInt32(h.count + body.count)
        count += 1
    }

    func finish() throws {
        try handle.write(contentsOf: central)
        var e = Data()
        e.le32(0x06054b50); e.le16(0); e.le16(0); e.le16(count); e.le16(count)
        e.le32(UInt32(central.count)); e.le32(offset); e.le16(0)
        try handle.write(contentsOf: e)
        try handle.close()
    }
}

struct ZipEntry {
    var name: String
    var method: UInt16
    var compSize: Int
    var size: Int
    var localOffset: Int
    var isDir: Bool { name.hasSuffix("/") }
}

final class ZipReader {
    let data: Data
    private(set) var entries: [ZipEntry] = []

    enum Err: Error { case notZip, unsupported, corrupt }

    init(url: URL) throws {
        data = try Data(contentsOf: url, options: .alwaysMapped)
        try parse()
    }

    private func parse() throws {
        let n = data.count
        guard n >= 22 else { throw Err.notZip }
        var eocd = -1
        var i = n - 22
        let stop = max(0, n - 22 - 65_535)
        while i >= stop { if data.u32(i) == 0x06054b50 { eocd = i; break }; i -= 1 }
        guard eocd >= 0 else { throw Err.notZip }
        let total = Int(data.u16(eocd + 10))
        var p = Int(data.u32(eocd + 16))
        for _ in 0..<total {
            guard p + 46 <= n, data.u32(p) == 0x02014b50 else { throw Err.corrupt }
            let method = data.u16(p + 10)
            let comp = Int(data.u32(p + 20)), size = Int(data.u32(p + 24))
            let nl = Int(data.u16(p + 28)), el = Int(data.u16(p + 30)), cl = Int(data.u16(p + 32))
            let off = Int(data.u32(p + 42))
            let name = String(decoding: data.subdata(in: (p + 46)..<(p + 46 + nl)), as: UTF8.self)
            entries.append(ZipEntry(name: name, method: method, compSize: comp, size: size, localOffset: off))
            p += 46 + nl + el + cl
        }
    }

    func read(_ e: ZipEntry) throws -> Data {
        let p = e.localOffset
        guard p + 30 <= data.count, data.u32(p) == 0x04034b50 else { throw Err.corrupt }
        let nl = Int(data.u16(p + 26)), el = Int(data.u16(p + 28))
        let start = p + 30 + nl + el
        guard start + e.compSize <= data.count else { throw Err.corrupt }
        let body = data.subdata(in: start..<(start + e.compSize))
        switch e.method {
        case 0: return body
        case 8:
            guard let d = Deflate.decompress(body, size: e.size) else { throw Err.corrupt }
            return d
        default: throw Err.unsupported
        }
    }

    func has(_ name: String) -> Bool { entries.contains { $0.name == name } }
}
