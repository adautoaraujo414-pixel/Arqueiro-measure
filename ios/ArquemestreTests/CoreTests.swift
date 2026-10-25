import XCTest
@testable import Arquemestre

/// Mesmos casos dos testes do Android: o iPhone tem de medir e salvar igual.
final class BoschProtocolTests: XCTestCase {
    private func frame(_ meters: Float, pad: Int = 2) -> [UInt8] {
        var bits = meters.bitPattern.littleEndian
        var payload = withUnsafeBytes(of: &bits) { Array($0) }
        payload += [UInt8](repeating: 0, count: pad)
        return [0xC0, 0x55, UInt8(payload.count)] + payload
    }
    private func hex(_ h: String) -> [UInt8] { h.split(separator: " ").map { UInt8($0, radix: 16)! } }

    func testExtraiMetrosEConverteParaMm() {
        XCTAssertEqual(BoschProtocol.parseMm(frame(2.345)), 2345)
        XCTAssertEqual(BoschProtocol.parseMm(frame(0.05)), 50)
        XCTAssertEqual(BoschProtocol.parseMm(frame(12.0)), 12000)
    }
    func testIgnoraAutosyncEQuadrosCurtos() {
        XCTAssertNil(BoschProtocol.parseMm(BoschProtocol.ENABLE_AUTOSYNC))
        XCTAssertNil(BoschProtocol.parseMm([0xC0, 0x55]))
        XCTAssertNil(BoschProtocol.parseMm([]))
    }
    func testIgnoraQuadroSemC0() { var f = frame(2); f[0] = 0; XCTAssertNil(BoschProtocol.parseMm(f)) }
    func testRejeitaValoresImpossiveis() {
        XCTAssertNil(BoschProtocol.parseMm(frame(.nan)))
        XCTAssertNil(BoschProtocol.parseMm(frame(-3)))
        XCTAssertNil(BoschProtocol.parseMm(frame(5000)))
    }
    func testAutosyncHex() { XCTAssertEqual(BoschProtocol.toHex(BoschProtocol.ENABLE_AUTOSYNC), "C0 55 02 01 00 1A") }
    func testQuadroRealDaComunidade() {
        let v = BoschProtocol.parseMm(hex("c0 55 10 06 08 54 05 6f 81 04 3f 00 00 00 00 00 00 00 00 ec"))
        XCTAssertNotNil(v); XCTAssertEqual(v ?? 0, 518, accuracy: 1)
        XCTAssertNil(BoschProtocol.parseMm(hex("c0 55 10 02 08 54 05 6f 81 04 3f 00 00 00 00 00 00 00 00 ec")))
    }
    func testUUIDs() {
        XCTAssertTrue(BoschProtocol.isBoschService("0000FDE8-0000-1000-8000-00805F9B34FB"))
        XCTAssertTrue(BoschProtocol.isBoschService("FDE8"))
        XCTAssertTrue(BoschProtocol.isBoschService("02a6c0d0-0451-4000-b000-fb3210111989"))
        XCTAssertTrue(BoschProtocol.isBoschCharacteristic("02a6c0d2-0451-4000-b000-fb3210111989"))
        XCTAssertFalse(BoschProtocol.isBoschService("0000180a-0000-1000-8000-00805f9b34fb"))
        XCTAssertTrue(BoschProtocol.nameMatches("GLM 50-27 CG"))
    }
}

final class UnitsTests: XCTestCase {
    func testFormatoIgualAoAndroid() {
        XCTAssertEqual(Units.format(2345, .MM), "2345 mm")
        XCTAssertEqual(Units.format(2345, .CM), "234,5 cm")
        XCTAssertEqual(Units.format(2345, .M), "2,345 m")
        XCTAssertEqual(Units.format(1540, .M), "1,540 m")
        XCTAssertEqual(BoschProtocol.metersToMm(0.5477), 548)
        XCTAssertEqual(Units.format(BoschProtocol.metersToMm(0.5477), .M), "0,548 m")
        XCTAssertEqual(Units.format(BoschProtocol.metersToMm(2.8291), .M), "2,829 m")
        XCTAssertEqual(Units.format(BoschProtocol.metersToMm(1.1418), .M), "1,142 m")
        XCTAssertEqual(Units.format(BoschProtocol.metersToMm(0.802), .MM), "802 mm")
        XCTAssertEqual(Units.format(BoschProtocol.metersToMm(0.5477), .CM), "54,8 cm")
        XCTAssertEqual(Units.format(245.8, .MM), "245,8 mm")
        XCTAssertEqual(Units.format(245.8, .M), "0,246 m")
        XCTAssertEqual(Units.format(547.7, .M), "0,548 m")
    }
    func testLeitura() {
        XCTAssertEqual(Units.parseToMm("2345", .MM), 2345)
        XCTAssertEqual(Units.parseToMm("234,5", .CM)!, 2345, accuracy: 1e-9)
        XCTAssertEqual(Units.parseToMm("2.345 m", .MM)!, 2345, accuracy: 1e-9)
        XCTAssertNil(Units.parseToMm("abc", .MM))
    }
    func testCalc() {
        XCTAssertEqual(Calc.eval("2750−4"), 2746)
        XCTAssertEqual(Calc.eval("(10+5)×2"), 30)
        XCTAssertEqual(Calc.eval("1,5+1,5"), 3)
        XCTAssertNil(Calc.eval("5÷0"))
        XCTAssertEqual(Calc.format(2.5), "2,5")
        XCTAssertEqual(Calc.format(3), "3")
    }
    func testReais() {
        XCTAssertEqual(QuoteMath.brl(1234.5), "R$ 1.234,50")
        var q = Quote(); q.items = [QuoteItem(desc: "x", qty: 2, unit: "un", unitValue: 100)]; q.discountPct = 10
        XCTAssertEqual(QuoteMath.original(q), 200)
        XCTAssertEqual(QuoteMath.finalValue(q), 180)
    }
}

final class JsonCompatTests: XCTestCase {
    /// Nota no formato que o Android grava (inclui um móvel antigo que só o Android edita).
    let androidNote = """
    {"v":2,"id":"n1","name":"Cozinha","folderId":null,"createdMs":1700000000000,"pinned":false,"locked":false,"trash":false,"unit":"M",
     "pages":[{"id":"p1","tpl":"ARAUJO","objs":[
       {"id":"r1","locked":false,"type":"room","photoId":null,"pts":[[100,100],[500,100],[500,400],[100,400]],"closed":true,
        "segs":[{"kind":"WALL","valueMm":3540,"source":"BLUETOOTH","history":[],"hinge":0,"side":1,"slide":false},
                {"kind":"DOOR","valueMm":null,"source":null,"history":[],"hinge":1,"side":-1,"slide":true},
                {"kind":"SINK","valueMm":2000,"source":"MANUAL","history":[{"id":"h","mm":2000,"source":"MANUAL","timeMs":1,"device":null,"rawHex":null}]},
                {"kind":"WALL"}],
        "color":-15658735,"width":2.08,"labelScale":1,"labelAlpha":1,"labelIntensity":1},
       {"id":"d1","locked":true,"type":"dim","photoId":null,"a":[10,20],"b":[30,40],"valueMm":548,"source":"BLUETOOTH","history":[],"color":-14853160,"width":2.08,"labelScale":1.2,"labelAlpha":0.8,"labelIntensity":0.5,"refSize":28.3},
       {"id":"c1","locked":false,"type":"cab","at":[50,600],"name":"Armário base","scaleDen":10,"cab":{"w":800,"h":720,"d":550}},
       {"id":"t1","locked":false,"type":"text","photoId":null,"at":[5,6],"text":"Olá\\nlinha 2","size":18,"color":-16777216}
     ]}]}
    """

    func testLeNotaDoAndroidEGravaIgual() throws {
        let n = try JsonCodec.noteFromJson(androidNote)
        XCTAssertEqual(n.pages[0].objs.count, 4)
        let r = n.pages[0].objs[0].asRoom!
        XCTAssertEqual(r.segs[0].valueMm, 3540)
        XCTAssertEqual(r.segs[1].kind, .DOOR); XCTAssertEqual(r.segs[1].hinge, 1); XCTAssertEqual(r.segs[1].side, -1); XCTAssertTrue(r.segs[1].slide)
        XCTAssertEqual(r.segs[2].source, .MANUAL); XCTAssertEqual(r.segs[2].history.count, 1)
        XCTAssertEqual(r.color, -15658735)
        let d = n.pages[0].objs[1].asDim!
        XCTAssertTrue(d.locked); XCTAssertEqual(d.valueMm, 548); XCTAssertEqual(d.labelAlpha, 0.8, accuracy: 1e-6)
        XCTAssertTrue(n.pages[0].objs[2].isLegacy)
        XCTAssertEqual(n.dimCount(), 5)
        // ida e volta: nada se perde (o móvel do Android volta com os mesmos campos)
        let again = try JsonCodec.noteFromJson(JsonCodec.noteToJson(n))
        XCTAssertEqual(again, n)
        let raw = try JsonCodec.parseObject(JsonCodec.noteToJson(n))
        let objs = ((raw["pages"] as! [[String: Any]])[0]["objs"] as! [[String: Any]])
        let cab = objs[2]
        XCTAssertEqual(cab["type"] as? String, "cab")
        XCTAssertEqual((cab["cab"] as? [String: Any])?["w"] as? Int, 800)
    }

    func testAgendaEOrcamento() throws {
        var a = Appointment(kind: .ENTREGA, title: "Entrega", clientName: "Ana")
        a.remindMin = [0, 60]
        let back = try JsonCodec.agendaFromJson(JsonCodec.agendaToJson([a]))
        XCTAssertEqual(back, [a])
        let q = Quote(clientName: "Ana", items: [QuoteItem(desc: "Cozinha", qty: 1, unit: "un", unitValue: 9800)], discountPct: 5)
        XCTAssertEqual(try JsonCodec.quotesFromJson(JsonCodec.quotesToJson([q])), [q])
    }
}

final class LogicTests: XCTestCase {
    func testQuadradoVira4Paredes() {
        var raw: [Pt] = []
        for i in 0...40 { raw.append(Pt(100 + CGFloat(i) * 10, 100 + CGFloat(i % 2))) }
        for i in 0...30 { raw.append(Pt(500 + CGFloat(i % 2), 100 + CGFloat(i) * 10)) }
        for i in 0...40 { raw.append(Pt(500 - CGFloat(i) * 10, 400)) }
        for i in 0...29 { raw.append(Pt(100, 400 - CGFloat(i) * 10)) }
        let r = Straighten.run(raw)
        XCTAssertNotNil(r)
        XCTAssertTrue(r!.closed)
        XCTAssertEqual(r!.pts.count, 4)
    }

    func testLeituraVaiParaACotaEAvanca() {
        let d1 = DimObj(photoId: nil, a: Pt(0, 0), b: Pt(100, 0), color: 0, width: 2)
        let d2 = DimObj(photoId: nil, a: Pt(0, 50), b: Pt(100, 50), color: 0, width: 2)
        var n = Note(name: "t"); n.pages = [Sheet(objs: [.dim(d1), .dim(d2)])]
        let st = EditorState(n)
        st.select(d1.id)
        XCTAssertNotNil(st.assignReading(Reading(mm: 1234, source: .BLUETOOTH, timeMs: 1)))
        XCTAssertEqual(st.note.pages[0].objs[0].asDim?.valueMm, 1234)
        XCTAssertEqual(st.selectedId, d2.id) // foi para a próxima sem medida
        st.undo()
        XCTAssertNil(st.note.pages[0].objs[0].asDim?.valueMm)
        st.redo()
        XCTAssertEqual(st.note.pages[0].objs[0].asDim?.valueMm, 1234)
    }

    func testPortaNoMeioDaParede() {
        let r = RoomObj(photoId: nil, pts: [Pt(0, 0), Pt(400, 0), Pt(400, 300), Pt(0, 300)], closed: true, segs: Array(repeating: Seg(valueMm: 4000), count: 4), color: 0, width: 2)
        var n = Note(name: "t"); n.pages = [Sheet(objs: [.room(r)])]
        let st = EditorState(n)
        st.splitSeg(r.id, 0, .DOOR)
        let rr = st.note.pages[0].objs[0].asRoom!
        XCTAssertEqual(rr.segs.count, 6)
        XCTAssertEqual(rr.segs[1].kind, .DOOR)
        XCTAssertNil(rr.segs[0].valueMm) // cada pedaço é medido de novo
        XCTAssertEqual(st.selectedSeg, 1)
    }

    func testLicencaNaoVoltaComORelogio() {
        let start = Date(timeIntervalSince1970: 1_000_000)
        let seen = start.addingTimeInterval(4 * 86400)
        // relógio voltou para o dia seguinte ao início: vale a maior data já vista
        XCTAssertEqual(LicenseManager.used(start: start, now: start.addingTimeInterval(86400), seen: seen), 4 * 86400)
        XCTAssertEqual(LicenseManager.leftText(29 * 3600), "1 dia e 5 h")
        XCTAssertEqual(LicenseManager.leftText(3 * 3600 + 10), "3 h")
        XCTAssertEqual(LicenseManager.TRIAL_DAYS, 3)
    }
}

final class ZipBackupTests: XCTestCase {
    func testZipIdaEVolta() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("t.zip")
        let big = Data(String(repeating: "arquemestre ", count: 5000).utf8)
        let z = try ZipWriter(url: url)
        try z.add(name: "a.txt", data: Data("olá".utf8))
        try z.add(name: "dir/big.json", data: big)
        try z.finish()
        let r = try ZipReader(url: url)
        XCTAssertEqual(r.entries.count, 2)
        XCTAssertEqual(try r.read(r.entries[0]), Data("olá".utf8))
        XCTAssertEqual(r.entries[1].method, 8) // comprimido
        XCTAssertEqual(try r.read(r.entries[1]), big)
        XCTAssertEqual(Crc32.of(Data("123456789".utf8)), 0xCBF43926)
    }

    func testRestauraBackupNoFormatoDoAndroid() throws {
        // backup completo: marcador + files/projects/... (igual ao DataBackup do Android)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("android-backup.zip")
        let z = try ZipWriter(url: url)
        try z.add(name: DataBackup.MARK, data: Data("Arque Measure · backup completo".utf8))
        try z.add(name: "shared_prefs/arque.lic.xml", data: Data("<map/>".utf8))
        try z.add(name: "files/projects/index.json", data: Data(#"{"v":2,"folders":[],"notes":[{"id":"x1","name":"Do Android","folderId":null,"createdMs":1,"pinned":false,"locked":false,"trash":false,"pageCount":1,"dimCount":0}]}"#.utf8))
        try z.add(name: "files/projects/notes/x1.json", data: Data(#"{"v":2,"id":"x1","name":"Do Android","pages":[{"id":"p","tpl":"BLANK","objs":[]}]}"#.utf8))
        try z.add(name: "files/moveis/projects.json", data: Data(#"[{"id":"p1","client":{"nome":"Ana"},"created":1,"updated":2,"current":{"mods":[1,2]}}]"#.utf8))
        try z.finish()
        try DataBackup.restore(from: url)
        let s = Store()
        XCTAssertEqual(s.loadIndex().notes.first?.name, "Do Android")
        XCTAssertEqual(s.loadNote("x1")?.name, "Do Android")
        XCTAssertEqual(MoveisProjects.list().first?.name, "Ana")
        XCTAssertEqual(MoveisProjects.list().first?.mods, 2)
        // e o backup do iPhone tem o mesmo formato
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("ios-backup.zip")
        try DataBackup.fullBackup(to: out)
        let r = try ZipReader(url: out)
        XCTAssertTrue(r.has(DataBackup.MARK))
        XCTAssertTrue(r.has("files/projects/index.json"))
        XCTAssertTrue(r.has("files/moveis/projects.json"))
    }
}
