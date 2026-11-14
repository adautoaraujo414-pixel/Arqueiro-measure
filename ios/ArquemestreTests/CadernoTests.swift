import XCTest
import UIKit
@testable import Arquemestre

/// Caderno (nota com folhas): o que travava no iPhone/iPad e o que a folha guardada tem que mostrar.
/// Cada teste confere o resultado real (pixels da folha, contagem de leituras do arquivo), não só que "rodou".
final class CadernoTests: XCTestCase {

    // ---------- apoio ----------
    private func traco(_ x: CGFloat, _ y: CGFloat, _ n: Int = 40, cor: Int = argb(0xFF111111), w: CGFloat = 2.2) -> StrokeObj {
        var pts: [Pt] = []
        for i in 0..<n { pts.append(Pt(x + CGFloat(i) * 3, y + sin(CGFloat(i) * 0.35) * 14)) }
        return StrokeObj(photoId: nil, pts: pts, color: cor, width: w)
    }

    private func notaDeTeste(tracos: Int = 30) -> Note {
        var objs: [Obj] = []
        for i in 0..<tracos { objs.append(.stroke(traco(60 + CGFloat(i % 5) * 130, 140 + CGFloat(i / 5) * 60))) }
        objs.append(.shape(ShapeObj(photoId: nil, kind: .RECT, a: Pt(100, 620), b: Pt(360, 760), color: argb(0xFF1E5BD8), width: 2.5, fill: true)))
        objs.append(.text(TextObj(photoId: nil, at: Pt(420, 640), text: "Bancada 2,40", size: 18, color: argb(0xFFE53935))))
        var d = DimObj(photoId: nil, a: Pt(120, 820), b: Pt(620, 820), color: argb(0xFF2E9E57), width: 2, refSize: 500)
        d.valueMm = 2400; d.source = .MANUAL
        objs.append(.dim(d))
        var n = Note(name: "caderno de teste")
        n.pages = [Sheet(tpl: .LINES, objs: objs), Sheet(tpl: .BLANK, objs: [.stroke(traco(80, 200, 60))])]
        return n
    }

    private func folha(_ note: Note, w: CGFloat = 240, h: CGFloat = 360) -> (EditorSession, SheetCanvasView) {
        let s = EditorSession(note) { _ in }
        let v = SheetCanvasView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        v.session = s
        v.layoutIfNeeded()
        s.onCanvasSize(w, h)
        return (s, v)
    }

    /// Desenha a folha (o mesmo draw da tela) numa imagem na densidade da tela e devolve os pixels.
    /// A imagem é do mesmo tipo da que a folha guarda: a comparação é do desenho, não do tipo de bitmap.
    private func pixels(_ v: SheetCanvasView) -> [UInt8] {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.opaque = true
        fmt.preferredRange = .standard
        let img = UIGraphicsImageRenderer(size: v.bounds.size, format: fmt).image { _ in v.draw(v.bounds) }
        guard let cg = img.cgImage, let data = cg.dataProvider?.data, let p = CFDataGetBytePtr(data) else { return [] }
        return Array(UnsafeBufferPointer(start: p, count: CFDataGetLength(data)))
    }

    /// Parte dos pixels (0…1) que difere mais que [tol] em algum canal, e quantos pixels de [b] têm tinta (escuros ou coloridos).
    private func compara(_ a: [UInt8], _ b: [UInt8], tol: Int = 10) -> (dif: Double, tinta: Int) {
        guard a.count == b.count, !a.isEmpty else { return (1, 0) }
        var bad = 0, ink = 0
        a.withUnsafeBufferPointer { pa in
            b.withUnsafeBufferPointer { pb in
                var i = 0
                let n = pa.count
                while i < n {
                    let r = Int(pb[i]), g = Int(pb[i + 1]), bl = Int(pb[i + 2])
                    if abs(Int(pa[i]) - r) > tol || abs(Int(pa[i + 1]) - g) > tol || abs(Int(pa[i + 2]) - bl) > tol { bad += 1 }
                    if r < 110 || abs(r - g) > 60 || abs(g - bl) > 60 { ink += 1 }
                    i += 4
                }
            }
        }
        return (Double(bad) / Double(a.count / 4), ink)
    }

    /// O que a tela mostra agora × a mesma folha desenhada direto (sem a imagem guardada).
    private func igualAoDireto(_ v: SheetCanvasView, _ onde: String, file: StaticString = #filePath, line: UInt = #line) {
        let guardada = pixels(v)
        v.cacheOff = true
        let direto = pixels(v)
        v.cacheOff = false
        let r = compara(guardada, direto)
        // tem desenho de verdade (não é uma folha vazia comparada com outra vazia)
        XCTAssertGreaterThan(r.tinta, 150, "a folha saiu sem desenho (\(onde))", file: file, line: line)
        XCTAssertLessThan(r.dif, 0.002, "a folha guardada saiu diferente do desenho direto em \(onde): \(String(format: "%.4f", r.dif * 100))% dos pixels", file: file, line: line)
    }

    /// Desenha a folha num bitmap reaproveitado (sem copiar os pixels): pra medir só o tempo do desenho.
    private final class Tela {
        let ctx: CGContext
        init(_ v: SheetCanvasView) {
            let k = UIScreen.main.scale
            let w = Int(v.bounds.width * k), h = Int(v.bounds.height * k)
            ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            ctx.translateBy(x: 0, y: CGFloat(h))
            ctx.scaleBy(x: k, y: -k)
        }
        func desenha(_ v: SheetCanvasView) {
            UIGraphicsPushContext(ctx)
            v.draw(v.bounds)
            UIGraphicsPopContext()
        }
    }

    // ---------- 1. lista de projetos ----------
    /// O caderno ligado a um projeto pedia a lista de projetos a cada redesenho da tela, e cada pedido lia e interpretava
    /// o projects.json inteiro do disco. Agora lê uma vez e só de novo quando o arquivo muda.
    func testListaDeProjetosSoReleOArquivoQuandoEleMuda() throws {
        try FileManager.default.createDirectory(at: AppPaths.moveis, withIntermediateDirectories: true)
        let bak = try? Data(contentsOf: MoveisProjects.file)
        defer { if let b = bak { try? b.write(to: MoveisProjects.file) } else { try? FileManager.default.removeItem(at: MoveisProjects.file) } }
        try Data(#"[{"id":"a1","client":{"nome":"Ana"},"created":1,"updated":5,"current":{"mods":[1,2,3]}}]"#.utf8).write(to: MoveisProjects.file)
        let n0 = MoveisProjects.listParses
        XCTAssertEqual(MoveisProjects.list().first?.name, "Ana")
        for _ in 0..<300 { XCTAssertEqual(MoveisProjects.list().count, 1) }
        XCTAssertEqual(MoveisProjects.listParses - n0, 1, "o arquivo dos projetos tem que ser lido uma vez só enquanto não muda")
        // arquivo regravado com o mesmo tamanho e outro nome: a lista acompanha na hora
        try Data(#"[{"id":"a1","client":{"nome":"Bia"},"created":1,"updated":5,"current":{"mods":[1,2,3]}}]"#.utf8).write(to: MoveisProjects.file)
        XCTAssertEqual(MoveisProjects.list().first?.name, "Bia")
        XCTAssertEqual(MoveisProjects.list().first?.mods, 3)
        // o que o app grava (renomear, status, nome do projeto) aparece na hora
        MoveisProjects.rename("a1", "Caio")
        XCTAssertEqual(MoveisProjects.list().first?.name, "Caio")
        MoveisProjects.setStatus("a1", "prod")
        XCTAssertEqual(MoveisProjects.list().first?.status, "prod")
        MoveisProjects.setTitle("a1", "Suíte")
        XCTAssertEqual(MoveisProjects.list().first?.label, "Suíte")
        // arquivo apagado: lista vazia (não fica com a lista antiga)
        try FileManager.default.removeItem(at: MoveisProjects.file)
        XCTAssertEqual(MoveisProjects.list().count, 0)
        // voltou: lê de novo
        try Data(#"[{"id":"z9","client":{"nome":"Zé"},"created":1,"updated":5,"current":{"mods":[]}}]"#.utf8).write(to: MoveisProjects.file)
        XCTAssertEqual(MoveisProjects.list().first?.id, "z9")
    }

    /// Medida de verdade com um arquivo de projetos grande (40 projetos, ~3 MB): quanto custava cada pedido e quanto custa agora.
    func testTempoDaListaDeProjetosComArquivoGrande() throws {
        try FileManager.default.createDirectory(at: AppPaths.moveis, withIntermediateDirectories: true)
        let bak = try? Data(contentsOf: MoveisProjects.file)
        defer { if let b = bak { try? b.write(to: MoveisProjects.file) } else { try? FileManager.default.removeItem(at: MoveisProjects.file) } }
        var projs: [[String: Any]] = []
        for i in 0..<40 {
            var mods: [[String: Any]] = []
            for j in 0..<180 {
                mods.append(["id": "m\(i)_\(j)", "x": j * 600, "w": 600, "h": 720, "d": 560, "b": 150, "n": "Balcão 2 portas com prateleira",
                             "v": [["k": "door", "n": 2, "h": 700], ["k": "shelves", "n": 1]], "cor": "#d9cdb4", "esp": 15, "rod": true, "rodMm": 150])
            }
            projs.append(["id": "p\(i)", "client": ["nome": "Cliente \(i)", "cidade": "Montes Claros"], "created": 1, "updated": 100 + i, "current": ["mods": mods, "room": "cozinha"]])
        }
        let data = try JSONSerialization.data(withJSONObject: projs)
        try data.write(to: MoveisProjects.file)
        let t0 = CFAbsoluteTimeGetCurrent()
        XCTAssertEqual(MoveisProjects.list().count, 40)
        let primeira = (CFAbsoluteTimeGetCurrent() - t0) * 1000
        let t1 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<200 { XCTAssertEqual(MoveisProjects.list().count, 40) }
        let depois = (CFAbsoluteTimeGetCurrent() - t1) * 1000 / 200
        print(String(format: "CADERNO-PERF lista de projetos: arquivo %.1f MB · ler e interpretar %.1f ms (era isso a cada redesenho) · agora %.3f ms por pedido", Double(data.count) / 1_048_576, primeira, depois))
        XCTAssertLessThan(depois, primeira / 5, "o pedido repetido tem que custar bem menos que ler o arquivo")
    }

    // ---------- 2. folha guardada ----------
    /// Parado, abrindo menu, trocando de cor: a folha inteira é desenhada UMA vez e depois só reaproveitada; e o que
    /// aparece é igual ao desenho direto, pixel a pixel.
    func testFolhaParadaNaoERedesenhadaEMostraOMesmoQueODesenhoDireto() {
        let (s, v) = folha(notaDeTeste())
        _ = pixels(v); _ = pixels(v); _ = pixels(v)
        XCTAssertEqual(v.fullRenders, 1, "folha parada tem que ser desenhada inteira uma vez só")
        XCTAssertEqual(v.cacheHits, 2)
        igualAoDireto(v, "folha parada")
        // escolher ferramenta, cor e espessura não muda a folha: continua sem redesenhar
        let antes = v.fullRenders
        s.chooseTool(.PEN); s.color = PALETTE[2]; s.width = 3
        _ = pixels(v)
        XCTAssertEqual(v.fullRenders, antes, "trocar ferramenta/cor não redesenha a folha")
        // selecionar muda o que aparece (alças): redesenha uma vez e bate com o direto
        s.chooseTool(.SELECT)
        let alvo = s.state.sheet.objs.first { $0.asShape != nil }!
        s.state.select(alvo.id)
        igualAoDireto(v, "forma selecionada")
        XCTAssertEqual(v.fullRenders, antes + 1)
        s.state.select(nil)
        igualAoDireto(v, "seleção tirada")
        // câmera: mover e dar zoom redesenha e bate
        s.panBy(0, -180)
        igualAoDireto(v, "folha movida")
        s.zoomAround(1.7, 120, 200)
        igualAoDireto(v, "zoom 1,7×")
        // desfazer/refazer e trocar a unidade aparecem na hora
        s.state.setUnit(.MM)
        igualAoDireto(v, "unidade em mm")
        s.state.undo()
        igualAoDireto(v, "desfeito")
        // tamanho da tela mudou (girar o aparelho)
        v.frame = CGRect(x: 0, y: 0, width: 360, height: 240)
        v.layoutIfNeeded(); s.onCanvasSize(360, 240)
        igualAoDireto(v, "tela deitada")
    }

    /// Escrever: começar o traço não redesenha a folha, cada ponto só desenha o traço novo, e ao soltar o traço é somado
    /// à imagem guardada. Antes a folha inteira era desenhada duas vezes por traço (ao começar e ao soltar).
    func testEscreverNaoRedesenhaAFolhaInteiraACadaTraco() {
        let (s, v) = folha(notaDeTeste(tracos: 60))
        s.chooseTool(.PEN)
        _ = pixels(v)
        XCTAssertEqual(v.fullRenders, 1)
        let g = v.controller!
        let n0 = s.state.sheet.objs.count
        for k in 0..<5 {
            let y = 215 + CGFloat(k) * 14
            g.down(CGPoint(x: 30, y: y), isFinger: false)
            XCTAssertNotNil(g.liveId, "o traço começou")
            for i in 1...25 {
                g.move(CGPoint(x: 30 + CGFloat(i) * 7, y: y + sin(CGFloat(i) * 0.5) * 5), Double(k) + Double(i) * 0.01)
                g.flush()
                if i % 8 == 0 { igualAoDireto(v, "traço \(k + 1) sendo escrito (ponto \(i))") }
            }
            _ = g.up(CGPoint(x: 30 + 26 * 7, y: y))
            igualAoDireto(v, "traço \(k + 1) pronto")
        }
        XCTAssertEqual(s.state.sheet.objs.count, n0 + 5, "os 5 traços ficaram na folha")
        XCTAssertEqual(v.fullRenders, 1, "escrever 5 traços não pode redesenhar a folha inteira nenhuma vez")
        XCTAssertEqual(v.bakes, 5, "cada traço pronto foi somado à imagem guardada")
        // desfazer o último traço: some da tela
        s.state.undo()
        XCTAssertEqual(s.state.sheet.objs.count, n0 + 4)
        igualAoDireto(v, "último traço desfeito")
        // traço cancelado por um segundo dedo: a folha volta ao que era
        g.down(CGPoint(x: 40, y: 300), isFinger: false)
        for i in 1...10 { g.move(CGPoint(x: 40 + CGFloat(i) * 12, y: 300), 9 + Double(i) * 0.01); g.flush() }
        _ = pixels(v)
        g.cancelSingle()
        XCTAssertEqual(s.state.sheet.objs.count, n0 + 4, "traço cancelado não fica")
        igualAoDireto(v, "traço cancelado")
        // marca-texto e lápis também
        for t in [Tool.HIGHLIGHTER, Tool.PENCIL] {
            s.chooseTool(t)
            g.down(CGPoint(x: 30, y: 320), isFinger: false)
            for i in 1...20 { g.move(CGPoint(x: 30 + CGFloat(i) * 8, y: 320 + CGFloat(i)), 20 + Double(i) * 0.01); g.flush() }
            igualAoDireto(v, "\(t.rawValue) sendo escrito")
            _ = g.up(CGPoint(x: 30 + 21 * 8, y: 341))
            igualAoDireto(v, "\(t.rawValue) pronto")
        }
    }

    /// Os outros gestos (mover, borracha, forma, cômodo, laço) continuam mostrando a folha certa durante e depois.
    func testOutrosGestosMostramAFolhaCertaDuranteEDepois() {
        let (s, v) = folha(notaDeTeste())
        let g = v.controller!
        _ = pixels(v)
        /// Ponto da tela que cai em (x, y) da folha ativa.
        func tela(_ x: CGFloat, _ y: CGFloat) -> CGPoint { s.view.toScreen(Pt(x, y)) }
        // forma nova (retângulo de 150,880 a 450,1000 na folha)
        s.chooseTool(.RECT)
        g.down(tela(150, 880), isFinger: false)
        for i in 1...6 { g.move(tela(150 + CGFloat(i) * 50, 880 + CGFloat(i) * 20), Double(i) * 0.01); g.flush() }
        igualAoDireto(v, "retângulo sendo desenhado")
        _ = g.up(tela(450, 1000))
        let ret = s.state.sheet.objs.last!
        XCTAssertNotNil(ret.asShape, "o retângulo ficou na folha")
        XCTAssertEqual(s.state.selectedId, ret.id)
        igualAoDireto(v, "retângulo pronto (selecionado)")
        // mover o retângulo pegando na borda de baixo
        s.chooseTool(.SELECT)
        s.state.select(ret.id)
        let a0 = s.state.sheet.obj(ret.id)!.asShape!.a
        g.down(tela(300, 1000), isFinger: false)
        for i in 1...6 { g.move(tela(300 + CGFloat(i) * 15, 1000), 1 + Double(i) * 0.01); g.flush() }
        igualAoDireto(v, "movendo")
        _ = g.up(tela(390, 1000))
        let a1 = s.state.sheet.obj(ret.id)!.asShape!.a
        XCTAssertEqual(a1.x - a0.x, 90, accuracy: 2, "o retângulo andou o que o dedo andou")
        igualAoDireto(v, "movido")
        // borracha passando pela última fileira de traços (y ≈ 440 da folha)
        s.chooseTool(.ERASER)
        let antes = s.state.sheet.objs
        g.down(tela(40, 440), isFinger: false)
        for i in 1...30 { g.move(tela(40 + CGFloat(i) * 24, 440 + CGFloat(i % 3)), 2 + Double(i) * 0.01); g.flush() }
        igualAoDireto(v, "apagando")
        _ = g.up(tela(760, 440))
        igualAoDireto(v, "apagado")
        XCTAssertNotEqual(s.state.sheet.objs, antes, "a borracha passou por cima de traços: a folha mudou")
        // laço em volta das fileiras de cima
        s.chooseTool(.LASSO)
        g.down(tela(30, 110), isFinger: false)
        for p in [tela(760, 110), tela(760, 300), tela(30, 300), tela(30, 115)] { g.move(p, 3); g.flush() }
        igualAoDireto(v, "laço sendo desenhado")
        _ = g.up(tela(30, 115))
        XCTAssertFalse(s.state.groupIds.isEmpty, "o laço pegou traços")
        igualAoDireto(v, "grupo do laço")
        // cômodo (traço que vira paredes)
        s.chooseTool(.ROOM)
        XCTAssertTrue(s.state.groupIds.isEmpty)
        let cantos = [Pt(120, 900), Pt(520, 900), Pt(520, 1060), Pt(120, 1060), Pt(120, 902)]
        g.down(tela(cantos[0].x, cantos[0].y), isFinger: false)
        for k in 1..<cantos.count {
            for i in 1...10 {
                let t = CGFloat(i) / 10
                g.move(tela(cantos[k - 1].x + (cantos[k].x - cantos[k - 1].x) * t, cantos[k - 1].y + (cantos[k].y - cantos[k - 1].y) * t), 4)
                g.flush()
            }
            igualAoDireto(v, "cômodo sendo riscado (lado \(k))")
        }
        _ = g.up(tela(120, 902))
        igualAoDireto(v, "cômodo pronto")
    }

    // ---------- 3. câmera e painéis ----------
    /// Mover a folha com o dedo: a câmera muda uma vez por movimento e os painéis (barras, botões) só são recalculados quando
    /// o que eles mostram muda. Antes a tela inteira era recalculada 3 vezes a cada movimento do dedo.
    func testMoverAFolhaNaoRecalculaOsPaineisACadaMovimento() {
        let (s, v) = folha(notaDeTeste())
        _ = v
        let oy0 = s.view.oy, ox0 = s.view.ox, r0 = s.rev
        for _ in 0..<40 { s.panBy(0, -2) }
        XCTAssertEqual(s.view.oy, oy0 - 80, accuracy: 0.001, "a folha andou o que o dedo andou")
        XCTAssertEqual(s.view.ox, ox0, accuracy: 0.001)
        XCTAssertLessThanOrEqual(s.rev - r0, 2, "40 movimentos sem nada selecionado: os painéis não são recalculados a cada um (foram \(s.rev - r0))")
        // soltou: recalcula uma vez
        let r1 = s.rev
        s.settle()
        XCTAssertEqual(s.rev - r1, 1)
        // com algo selecionado a barra dele acompanha a folha: aí recalcula a cada movimento
        s.state.select(s.state.sheet.objs.first { $0.asShape != nil }!.id)
        let r2 = s.rev
        for _ in 0..<10 { s.panBy(0, -2) }
        XCTAssertEqual(s.rev - r2, 10, "com seleção a barra acompanha cada movimento")
        // trocar de folha visível e de zoom atualiza os painéis
        s.state.select(nil)
        let r3 = s.rev
        s.goToPage(1)
        XCTAssertGreaterThan(s.rev, r3)
        XCTAssertEqual(s.visiblePage(), 1)
        let z0 = s.zoomPercent, r4 = s.rev
        s.zoomAround(2, 120, 180)
        XCTAssertNotEqual(s.zoomPercent, z0)
        XCTAssertGreaterThan(s.rev, r4)
        // pinça com deslocamento: mesmo resultado de deslocar e depois dar zoom no ponto
        let (a, _) = folha(notaDeTeste()), (b, _) = folha(notaDeTeste())
        a.zoomAround(1.3, 120, 300, panX: 14, panY: -22)
        var vb = b.view; vb.ox += 14; vb.oy += -22; b.view = vb
        b.zoomAround(1.3, 120, 300)
        XCTAssertEqual(a.view.scale, b.view.scale, accuracy: 1e-9)
        XCTAssertEqual(a.view.ox, b.view.ox, accuracy: 1e-6)
        XCTAssertEqual(a.view.oy, b.view.oy, accuracy: 1e-6)
    }

    /// A folha ativa e a câmera andam juntas: depois de desfazer, duplicar folha ou a medida passar pra outra folha,
    /// o que está selecionado é procurado na folha certa (antes ficava na altura da folha antiga até o próximo toque).
    func testFolhaAtivaEACameraAndamJuntas() {
        let d1 = DimObj(photoId: nil, a: Pt(100, 300), b: Pt(500, 300), color: argb(0xFF111111), width: 2)
        let d2 = DimObj(photoId: nil, a: Pt(100, 400), b: Pt(500, 400), color: argb(0xFF111111), width: 2)
        var n = Note(name: "duas folhas"); n.pages = [Sheet(objs: [.dim(d1)]), Sheet(objs: [.dim(d2)])]
        let (s, _) = folha(n)
        let passo = Sheet.H + Sheet.GAP
        XCTAssertEqual(s.view.pageOffsetY, 0)
        // medida da trena na cota da folha 1: a próxima sem medida está na folha 2
        s.state.select(d1.id)
        XCTAssertNotNil(s.state.assignReading(Reading(mm: 1500, source: .BLUETOOTH, timeMs: 1)))
        XCTAssertEqual(s.state.pageIdx, 1)
        XCTAssertEqual(s.state.selectedId, d2.id)
        XCTAssertEqual(s.view.pageOffsetY, passo, accuracy: 0.001, "a câmera sabe que a folha ativa é a 2")
        // a ponta da cota selecionada cai, na tela, em cima da folha 2
        let p = s.view.toScreen(Pt(100, 400))
        XCTAssertEqual(s.view.toWorld(p).y, passo + 400, accuracy: 0.01)
        // duplicar folha e desfazer
        XCTAssertTrue(s.state.duplicatePage(1))
        XCTAssertEqual(s.state.pageIdx, 2)
        XCTAssertEqual(s.view.pageOffsetY, 2 * passo, accuracy: 0.001, "folha duplicada vira a ativa")
        s.state.undo()
        XCTAssertEqual(s.state.pageIdx, 1)
        XCTAssertEqual(s.view.pageOffsetY, passo, accuracy: 0.001, "desfez: a folha ativa volta e a câmera junto")
        s.state.setPage(0)
        XCTAssertEqual(s.view.pageOffsetY, 0)
    }

    // ---------- 4. fotos ----------
    private func fotoDeTeste(_ w: Int, _ h: Int) throws -> String {
        let fmt = UIGraphicsImageRendererFormat(); fmt.scale = 1; fmt.opaque = true
        let img = UIGraphicsImageRenderer(size: CGSize(width: w, height: h), format: fmt).image { ctx in
            let c = ctx.cgContext
            for i in 0..<24 {
                c.setFillColor(UIColor(hue: CGFloat(i) / 24, saturation: 0.7, brightness: 0.9, alpha: 1).cgColor)
                c.fill(CGRect(x: CGFloat(i % 6) * CGFloat(w) / 6, y: CGFloat(i / 6) * CGFloat(h) / 4, width: CGFloat(w) / 6, height: CGFloat(h) / 4))
            }
            c.setStrokeColor(UIColor.black.cgColor); c.setLineWidth(CGFloat(w) / 200)
            for i in 0..<40 { c.move(to: CGPoint(x: 0, y: CGFloat(i) * CGFloat(h) / 40)); c.addLine(to: CGPoint(x: CGFloat(w), y: CGFloat(h) - CGFloat(i) * CGFloat(h) / 40)) }
            c.strokePath()
        }
        guard let d = img.jpegData(compressionQuality: 0.9) else { throw NSError(domain: "foto", code: 1) }
        return try Store().importImage(data: d, ext: "jpg")
    }

    /// A foto entra na tela no tamanho em que aparece (não a de 2400 px a cada quadro) e a folha com foto continua igual ao desenho direto.
    func testFotoNaTelaUsaOTamanhoEmQueApareceEAMemoriaTemLimite() throws {
        XCTAssertEqual(ImageCache.step(100), 256)
        XCTAssertEqual(ImageCache.step(257), 512)
        XCTAssertEqual(ImageCache.step(700), 1024)
        XCTAssertEqual(ImageCache.step(1500), 2048)
        XCTAssertEqual(ImageCache.step(2049), 2400)
        XCTAssertEqual(ImageCache.step(9000), 2400)
        let nome = try fotoDeTeste(3200, 2400)
        defer { try? FileManager.default.removeItem(at: Store().imageFile(nome)) }
        let cache = ImageCache()
        let pequena = try XCTUnwrap(cache.display(nome, px: 600, warm: false))
        XCTAssertEqual(max(pequena.size.width, pequena.size.height) * pequena.scale, 1024, accuracy: 1, "pedido de 600 px usa o degrau de 1024")
        XCTAssertEqual(pequena.size.width / pequena.size.height, 3200.0 / 2400.0, accuracy: 0.01, "proporção da foto mantida")
        let grande = try XCTUnwrap(cache.display(nome, px: 5000, warm: false))
        XCTAssertEqual(max(grande.size.width, grande.size.height) * grande.scale, 2400, accuracy: 1)
        // já tem uma maior pronta: não abre a foto de novo pra um pedido menor
        let media = try XCTUnwrap(cache.display(nome, px: 1500, warm: false))
        XCTAssertGreaterThanOrEqual(max(media.size.width, media.size.height) * media.scale, 2048 - 1)
        XCTAssertNil(cache.display("nao-existe.jpg", px: 600), "foto que não está no disco não inventa imagem")
        // folha com a foto: guardada × direto, e desenhando um traço por cima da foto
        let ph = PhotoObj(file: nome, pxW: 3200, pxH: 2400, cx: 397, cy: 420, w: 640, h: 480)
        var n = notaDeTeste(tracos: 10)
        n.pages[0].objs.insert(.photo(ph), at: 0)
        let (s, v) = folha(n)
        igualAoDireto(v, "folha com foto")
        s.chooseTool(.PEN)
        let g = v.controller!
        g.down(s.view.toScreen(Pt(150, 300)), isFinger: false)
        for i in 1...20 { g.move(s.view.toScreen(Pt(150 + CGFloat(i) * 22, 300 + CGFloat(i) * 9)), Double(i) * 0.01); g.flush() }
        igualAoDireto(v, "traço em cima da foto")
        _ = g.up(s.view.toScreen(Pt(612, 489)))
        XCTAssertEqual(s.state.sheet.objs.last?.asStroke?.photoId, ph.id, "o traço feito em cima da foto fica preso nela")
        igualAoDireto(v, "traço em cima da foto pronto")
        // medida de verdade: desenhar a foto de 2400 px × a foto no tamanho da tela
        let k = UIScreen.main.scale
        let lado = Int(390 * k)
        let ctx = CGContext(data: nil, width: lado, height: lado, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let cheia = try XCTUnwrap(cache.image(nome))
        let tela = try XCTUnwrap(cache.display(nome, px: CGFloat(lado), warm: false))
        func mede(_ img: UIImage) -> Double {
            let t = CFAbsoluteTimeGetCurrent()
            UIGraphicsPushContext(ctx)
            for _ in 0..<30 { img.draw(in: CGRect(x: 0, y: 0, width: CGFloat(lado), height: CGFloat(lado) * 0.75)) }
            UIGraphicsPopContext()
            return (CFAbsoluteTimeGetCurrent() - t) * 1000 / 30
        }
        _ = mede(cheia); _ = mede(tela)
        let a = mede(cheia), b = mede(tela)
        print(String(format: "CADERNO-PERF foto na tela (%d px de largura): foto de 2400 px %.2f ms por desenho · foto no tamanho da tela %.2f ms", lado, a, b))
    }

    /// Medida de verdade numa folha cheia: custo de redesenhar a folha inteira × custo de um quadro escrevendo.
    func testTempoDeEscreverNumaFolhaCheia() {
        var n = Note(name: "cheia")
        var objs: [Obj] = []
        for i in 0..<700 { objs.append(.stroke(traco(40 + CGFloat(i % 7) * 100, 100 + CGFloat(i / 7) * 9.5, 60))) }
        n.pages = [Sheet(tpl: .LINES, objs: objs)]
        let (s, v) = folha(n, w: 820, h: 1180)
        s.chooseTool(.PEN)
        let tela = Tela(v)
        tela.desenha(v)
        v.cacheOff = true
        tela.desenha(v)
        let t0 = CFAbsoluteTimeGetCurrent()
        for _ in 0..<5 { tela.desenha(v) }
        let inteira = (CFAbsoluteTimeGetCurrent() - t0) * 1000 / 5
        v.cacheOff = false
        let g = v.controller!
        tela.desenha(v)
        let r0 = v.fullRenders
        var quadros = 0
        let t1 = CFAbsoluteTimeGetCurrent()
        for k in 0..<6 {
            let y = 400 + CGFloat(k) * 30
            g.down(CGPoint(x: 100, y: y), isFinger: false)
            for i in 1...30 { g.move(CGPoint(x: 100 + CGFloat(i) * 8, y: y + sin(CGFloat(i)) * 6), Double(i) * 0.01); g.flush(); tela.desenha(v); quadros += 1 }
            _ = g.up(CGPoint(x: 348, y: y)); tela.desenha(v); quadros += 1
        }
        let porQuadro = (CFAbsoluteTimeGetCurrent() - t1) * 1000 / Double(quadros)
        print(String(format: "CADERNO-PERF folha cheia (700 traços, tela de iPad): redesenhar a folha inteira %.1f ms · escrevendo %.1f ms por quadro · folha inteira redesenhada %d vezes em 6 traços (antes: 12)", inteira, porQuadro, v.fullRenders - r0))
        XCTAssertEqual(v.fullRenders - r0, 0, "6 traços numa folha cheia: nenhuma vez a folha inteira")
        XCTAssertLessThan(porQuadro, inteira, "escrever tem que custar menos que redesenhar a folha inteira")
    }
}
