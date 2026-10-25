#if DEBUG
import Foundation
import CoreGraphics

/// Dados de exemplo só para as capturas de tela automáticas (argumento -demo, nunca na versão da loja).
@MainActor
enum DemoData {
    static func seedIfEmpty(_ app: AppModel) {
        guard app.index.notes.isEmpty else { return }
        let blue = argb(0xFF1E5BD8)
        var segs = [Seg(kind: .WALL, valueMm: 3540, source: .BLUETOOTH), Seg(kind: .WALL, valueMm: 2810, source: .BLUETOOTH),
                    Seg(kind: .WALL, valueMm: 1200, source: .BLUETOOTH), Seg(kind: .DOOR, valueMm: 820, source: .MANUAL),
                    Seg(kind: .WALL, valueMm: 1520, source: .BLUETOOTH), Seg(kind: .SINK, valueMm: 2810, source: .BLUETOOTH)]
        segs[3].hinge = 0; segs[3].side = -1
        let pts = [Pt(120, 200), Pt(620, 200), Pt(620, 600), Pt(450, 600), Pt(334, 600), Pt(120, 600)]
        let room = RoomObj(photoId: nil, pts: pts, closed: true, segs: segs, color: argb(0xFF111111), width: 2.1)
        let dim1 = DimObj(photoId: nil, a: Pt(120, 680), b: Pt(620, 680), valueMm: 3540, source: .BLUETOOTH, color: blue, width: 2.1)
        let dim2 = DimObj(photoId: nil, a: Pt(700, 200), b: Pt(700, 600), valueMm: 2810, source: .BLUETOOTH, color: argb(0xFFE53935), width: 2.1)
        let txt = TextObj(photoId: nil, at: Pt(130, 740), text: "Cozinha · pé-direito 2,70 m\nPia na parede de baixo, porta abre para dentro", size: 18, color: argb(0xFF111111))
        var note = Note(name: "Cozinha · Sra. Ana", unit: .M)
        note.pages = [Sheet(tpl: .ARAUJO, objs: [.room(room), .dim(dim1), .dim(dim2), .text(txt)])]
        app.store.saveNote(note)
        var n2 = Note(name: "Painel da sala · Sr. João", unit: .MM)
        n2.pages = [Sheet(tpl: .LINES, objs: [.dim(DimObj(photoId: nil, a: Pt(100, 300), b: Pt(690, 300), valueMm: 2740, source: .BLUETOOTH, color: blue, width: 2.1))])]
        app.store.saveNote(n2)
        var idx = LibIndex()
        idx.notes = [note.meta(), n2.meta()]
        app.store.saveIndex(idx)
        app.index = idx

        let now = Date()
        var a1 = Appointment(kind: .MEDICAO, title: "Medir cozinha", address: "Rua das Flores, 120 · Frutal", clientName: "Ana Souza", clientPhone: "34999990000")
        a1.startDate = Calendar.current.date(bySettingHour: 9, minute: 30, second: 0, of: now.addingTimeInterval(86400)) ?? now
        var a2 = Appointment(kind: .ENTREGA, title: "Entrega do painel", address: "Av. Brasil, 45", clientName: "João Lima")
        a2.startDate = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: now.addingTimeInterval(3 * 86400)) ?? now
        app.saveAppt(a1); app.saveAppt(a2)

        app.saveCompany(Company(name: "Marcenaria Exemplo", cnpj: "", address: "Rua Central, 10", city: "Frutal-MG", phone: "(34) 99999-0000"))
        app.saveQuote(Quote(clientName: "Ana Souza", city: "Frutal-MG",
                            items: [QuoteItem(desc: "Cozinha planejada em MDF branco TX 18 mm, com portas e gavetas", qty: 1, unit: "un", unitValue: 9800),
                                    QuoteItem(desc: "Painel ripado da sala", qty: 2.74, unit: "m", unitValue: 850)],
                            discountPct: 5, notes: "Entrega em 25 dias úteis."))
    }
}
#endif
