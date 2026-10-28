import XCTest
@testable import Arquemestre

final class BackupSafetyTests: XCTestCase {
    private var root: URL!
    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: root) }

    private func zip(_ name: String = "a.txt", data: Data = Data("abc".utf8)) throws -> URL {
        let url = root.appendingPathComponent(UUID().uuidString + ".zip")
        let writer = try ZipWriter(url: url)
        try writer.add(name: name, data: data); try writer.finish()
        return url
    }
    private func set16(_ data: inout Data, _ offset: Int, _ value: UInt16) {
        data[offset] = UInt8(truncatingIfNeeded: value)
        data[offset + 1] = UInt8(truncatingIfNeeded: value >> 8)
    }
    private func set32(_ data: inout Data, _ offset: Int, _ value: UInt32) {
        for i in 0..<4 { data[offset + i] = UInt8(truncatingIfNeeded: value >> (i * 8)) }
    }
    private func central(_ data: Data) throws -> Int {
        try XCTUnwrap(data.range(of: Data([0x50, 0x4b, 0x01, 0x02]))?.lowerBound)
    }
    func testTruncatedCentralNameThrowsInsteadOfCrashing() throws {
        let url = try zip(); var data = try Data(contentsOf: url)
        let c = try central(data)
        set16(&data, c + 28, UInt16.max)
        try data.write(to: url)
        XCTAssertThrowsError(try ZipReader(url: url))
    }
    func testOversizedEntryRejectedBeforeDecompression() throws {
        let url = try zip(); var data = try Data(contentsOf: url)
        let c = try central(data)
        set32(&data, c + 24, UInt32(ZipReader.maxEntrySize + 1))
        try data.write(to: url)
        XCTAssertThrowsError(try ZipReader(url: url))
        XCTAssertNil(Deflate.decompress(Data([1]), size: ZipReader.maxEntrySize + 1))
    }
    func testCumulativeUncompressedSizeIsBounded() throws {
        let url = root.appendingPathComponent("total.zip"), writer = try ZipWriter(url: url)
        for i in 0..<5 { try writer.add(name: "\(i).txt", data: Data([1])) }
        try writer.finish()
        var data = try Data(contentsOf: url), search = data.startIndex
        for _ in 0..<5 {
            let c = try XCTUnwrap(data.range(of: Data([0x50, 0x4b, 0x01, 0x02]), in: search..<data.endIndex)?.lowerBound)
            set32(&data, c + 24, UInt32(ZipReader.maxEntrySize)); search = c + 46
        }
        try data.write(to: url)
        XCTAssertThrowsError(try ZipReader(url: url))
    }
    func testCorruptStoredPayloadFailsChecksum() throws {
        let url = try zip(); var data = try Data(contentsOf: url)
        data[30 + "a.txt".utf8.count] ^= 0xff
        try data.write(to: url)
        let reader = try ZipReader(url: url)
        XCTAssertThrowsError(try reader.read(XCTUnwrap(reader.entries.first)))
    }
    func testRollbackPreservesOldFilesWhenInstallingFails() throws {
        let files = root.appendingPathComponent("files"), stage = root.appendingPathComponent("staged")
        let fm = FileManager.default
        try fm.createDirectory(at: files, withIntermediateDirectories: true)
        try fm.createDirectory(at: stage, withIntermediateDirectories: true)
        try Data("original".utf8).write(to: files.appendingPathComponent("saved.txt"))
        try Data("new".utf8).write(to: stage.appendingPathComponent("saved.txt"))
        XCTAssertThrowsError(try BackupFileSwap.install(stage, at: files) { from, to in
            if from == stage { throw CocoaError(.fileWriteOutOfSpace) }
            try fm.moveItem(at: from, to: to)
        })
        XCTAssertEqual(try String(contentsOf: files.appendingPathComponent("saved.txt"), encoding: .utf8), "original")
    }
    func testInterruptedSwapRecoversPreviousDirectory() throws {
        let files = root.appendingPathComponent("files"), previous = BackupFileSwap.previous(files)
        try FileManager.default.createDirectory(at: previous, withIntermediateDirectories: true)
        try Data("original".utf8).write(to: previous.appendingPathComponent("saved.txt"))
        try BackupFileSwap.recoverIfNeeded(at: files)
        XCTAssertEqual(try String(contentsOf: files.appendingPathComponent("saved.txt"), encoding: .utf8), "original")
    }
    func testSuccessfulSwapInstallsNewFiles() throws {
        let files = root.appendingPathComponent("files"), stage = root.appendingPathComponent("stage")
        try FileManager.default.createDirectory(at: files, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: stage, withIntermediateDirectories: true)
        try Data("new".utf8).write(to: stage.appendingPathComponent("saved.txt"))
        try BackupFileSwap.install(stage, at: files)
        XCTAssertEqual(try String(contentsOf: files.appendingPathComponent("saved.txt"), encoding: .utf8), "new")
        XCTAssertFalse(FileManager.default.fileExists(atPath: BackupFileSwap.previous(files).path))
    }
    func testInvalidFurnitureBackupDoesNotReplaceCurrentData() throws {
        let originalBase = AppPaths.base
        AppPaths.base = root.appendingPathComponent("app")
        defer { AppPaths.base = originalBase }
        let saved = AppPaths.files.appendingPathComponent("saved.txt")
        try Data("original".utf8).write(to: saved)
        let url = root.appendingPathComponent("invalid.zip"), writer = try ZipWriter(url: url)
        try writer.add(name: DataBackup.MARK, data: Data([1]))
        try writer.add(name: "files/moveis/unrelated.txt", data: Data([1]))
        try writer.finish()
        XCTAssertThrowsError(try DataBackup.restore(from: url))
        XCTAssertEqual(try String(contentsOf: saved, encoding: .utf8), "original")
    }
    func testVideoNativeFileSurvivesFullBackupAndRestore() throws {
        let originalBase = AppPaths.base
        AppPaths.base = root.appendingPathComponent("app")
        defer { AppPaths.base = originalBase }
        let json = #"{"id":"v1","pid":"p1","kind":"video","nome":"teste.mov","videoData":"data:video/quicktime;base64,AQID"}"#
        try EditorVideoBackup.save(json, in: AppPaths.moveis)
        try Data(#"[{"id":"p1"}]"#.utf8).write(to: AppPaths.moveis.appendingPathComponent("projects.json"))
        let url = root.appendingPathComponent("video.zip")
        try DataBackup.fullBackup(to: url)
        try FileManager.default.removeItem(at: AppPaths.moveis.appendingPathComponent("video_v1.json"))
        try DataBackup.restore(from: url)
        XCTAssertEqual(try String(contentsOf: AppPaths.moveis.appendingPathComponent("video_v1.json"), encoding: .utf8), json)
    }
    func testVideoRejectsPathTraversalAndInvalidEncoding() throws {
        XCTAssertThrowsError(try EditorVideoBackup.save(#"{"id":"../x","kind":"video","videoData":"data:video/mp4;base64,AQID"}"#, in: root))
        XCTAssertThrowsError(try EditorVideoBackup.save(#"{"id":"v1","kind":"video","videoData":"data:video/mp4;base64,???"}"#, in: root))
    }
    func testMediaBackupScriptIsIncludedInAppBundle() throws {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "EditorMediaBackup", withExtension: "js"))
        XCTAssertTrue(try String(contentsOf: url, encoding: .utf8).contains("window.phPut"))
    }
}
