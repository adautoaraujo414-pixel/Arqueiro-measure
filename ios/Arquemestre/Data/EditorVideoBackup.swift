import Foundation

enum EditorVideoBackup {
    static let maxBytes = 64 * 1024 * 1024

    static func save(_ json: String, in directory: URL) throws {
        guard json.utf8.count <= maxBytes * 4 / 3 + 1024 * 1024,
              let data = json.data(using: .utf8),
              let record = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let id = record["id"] as? String, !id.isEmpty, id.count <= 120,
              id.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "_-".contains($0)) }),
              record["kind"] as? String == "video",
              let video = record["videoData"] as? String,
              let comma = video.firstIndex(of: ","),
              video.hasPrefix("data:"), video[..<comma].hasSuffix(";base64"),
              let bytes = Data(base64Encoded: String(video[video.index(after: comma)...])),
              bytes.count <= maxBytes else { throw DataBackup.RestoreError.invalid }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: directory.appendingPathComponent("video_\(id).json"), options: [.atomic])
    }
}
