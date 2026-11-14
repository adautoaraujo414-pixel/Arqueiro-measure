import SwiftUI
import UIKit

/// A folha na tela: desenha todas as folhas empilhadas e recebe dedo, Apple Pencil e pinça.
final class SheetCanvasView: UIView {
    var session: EditorSession! {
        didSet {
            controller = GestureController(session)
            session.onCanvas = { [weak self] in self?.setNeedsDisplay() }
        }
    }
    var onAction: ((GestureAction) -> Void)?
    /// Os gestos da folha (os testes conduzem o traço por aqui, igual ao dedo).
    private(set) var controller: GestureController!
    /// Na tela a foto entra no tamanho em que aparece (a de 2400 px a cada quadro pesava).
    private let renderer: SheetRenderer = {
        let r = SheetRenderer()
        r.sized = { ImageCache.shared.display($0, px: $1) }
        return r
    }()
    /// A lupa amplia 3,4×: pede a foto no tamanho da lupa (que já foi deixado pronto em segundo plano).
    private let loupeRenderer: SheetRenderer = {
        let r = SheetRenderer()
        r.sized = { ImageCache.shared.display($0, px: $1, warm: false) }
        return r
    }()

    private var active: UITouch?
    private var pen = false
    private var second: UITouch?
    private var multi = false
    private var downT: TimeInterval = 0
    private var downPos = CGPoint.zero
    private var lastMoveT: TimeInterval = 0
    private var holdTimer: Timer?
    private var lockedTouchMoved = false
    /// Toques de mão/punho apoiados: ignorados até soltar.
    private var palms = Set<UITouch>()
    /// Imagem do que está parado na folha, guardada de um quadro pro outro: enquanto nada muda (escrevendo, abrindo um menu,
    /// trocando a cor) a folha inteira não é desenhada de novo; só o traço novo entra por cima.
    private var cache: UIImage?
    private var cacheKey = ""
    /// A imagem guardada foi feita com alguma foto ainda sem abrir ("carregando…"): fora do traço é refeita a cada desenho.
    private var cacheStale = false
    /// Traço que estava sendo escrito no último quadro: ao soltar, ele é somado à imagem guardada (a folha não é redesenhada).
    private var liveMark: (id: String, cam: String, rev: Int, count: Int)?
    /// Conferidos nos testes: folha inteira desenhada, imagem guardada aproveitada, traço somado à imagem.
    private(set) var fullRenders = 0
    private(set) var cacheHits = 0
    private(set) var bakes = 0
    /// Testes: desliga a imagem guardada pra comparar com o desenho direto.
    var cacheOff = false

    /// Contato grande (mão, punho) e não é o Apple Pencil.
    /// Só no iPad (onde se apoia a mão pra escrever com o Pencil). No iPhone o dedo grande (polegar na pinça) não pode virar "mão".
    private let padIdiom = UIDevice.current.userInterfaceIdiom == .pad
    private func isPalm(_ t: UITouch) -> Bool { padIdiom && t.type != .pencil && t.majorRadius > 42 }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = true
        backgroundColor = UIColor(red: 0x1E / 255, green: 0x20 / 255, blue: 0x25 / 255, alpha: 1)
        contentMode = .redraw
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        session?.onCanvasSize(bounds.width, bounds.height)
        setNeedsDisplay()
    }

    // ---- toques ----
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = session else { return }
        for t in touches {
            if isPalm(t) { palms.insert(t); continue }
            if s.screenLocked {
                if active == nil { active = t; downT = t.timestamp; downPos = t.location(in: self); lockedTouchMoved = false }
                continue
            }
            if active == nil {
                begin(t)
            } else if t.type == .pencil && !pen {
                // caneta encostou depois da mão: esquece a mão e segue a caneta
                if multi { controller.pinchEnd(); multi = false } else { controller.cancelSingle() }
                second = nil
                begin(t)
            } else if pen {
                continue // mão apoiada enquanto escreve com a caneta
            } else if second == nil, let a = active {
                second = t
                multi = true
                controller.cancelSingle()
                controller.pinchBegin(a.location(in: self), t.location(in: self))
            }
        }
        setNeedsDisplay()
    }

    private func begin(_ t: UITouch) {
        active = t
        pen = t.type == .pencil
        multi = false
        second = nil
        downT = t.timestamp
        downPos = t.location(in: self)
        lastMoveT = t.timestamp
        session.tapDown(t.timestamp)
        session.textEdit = nil
        controller.down(downPos, isFinger: t.type != .pencil)
        holdTimer?.invalidate()
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.active != nil, !self.multi else { return }
            let now = ProcessInfo.processInfo.systemUptime
            if now - self.lastMoveT > 0.6 { self.controller.hold(); self.setNeedsDisplay() }
            self.controller.still(now)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let s = session else { return }
        if s.screenLocked {
            if let a = active, touches.contains(a), hypot(a.location(in: self).x - downPos.x, a.location(in: self).y - downPos.y) > 24 { lockedTouchMoved = true }
            return
        }
        guard let a = active else { return }
        // o toque que virou mão apoiada (contato cresceu) é descartado
        if !pen && !multi && isPalm(a) {
            controller.cancelSingle(); s.settle()
            palms.insert(a); active = nil; holdTimer?.invalidate()
            setNeedsDisplay(); return
        }
        if multi, let b = second {
            controller.pinch(a.location(in: self), b.location(in: self))
        } else if touches.contains(a) {
            // pontos intermediários que o iOS junta num quadro só: escrita precisa (arrastar usa só o último)
            let all = controller.wantsHistory ? (event?.coalescedTouches(for: a) ?? [a]) : [a]
            for c in all { controller.move(c.location(in: self), c.timestamp) }
            controller.flush()
            lastMoveT = a.timestamp
        }
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches, cancelled: false) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { finish(touches, cancelled: true) }

    private func finish(_ touches: Set<UITouch>, cancelled: Bool) {
        for t in touches { palms.remove(t) }
        guard let s = session else { return }
        if s.screenLocked {
            if let a = active, touches.contains(a) {
                active = nil
                if !lockedTouchMoved && a.timestamp - downT < 0.4 && s.registerTap(a.timestamp, downPos) { s.toggleLock() }
            }
            return
        }
        guard let a = active else { return }
        if multi {
            if touches.contains(a) || (second.map { touches.contains($0) } ?? false) {
                controller.pinchEnd()
                s.settle()
                active = nil; second = nil; multi = false
                holdTimer?.invalidate()
            }
        } else if touches.contains(a) {
            holdTimer?.invalidate()
            active = nil
            if cancelled {
                controller.cancelSingle(); s.settle()
            } else {
                let loc = a.location(in: self)
                if let act = controller.up(loc) { onAction?(act) }
                let movedFar = hypot(loc.x - downPos.x, loc.y - downPos.y) > 24
                // 3 toques rápidos travam a tela só na ferramenta de seleção
                if !movedFar && a.timestamp - downT < 0.4 && s.tool == .SELECT && s.registerTap(a.timestamp, downPos) { s.toggleLock() }
            }
            pen = false
        }
        setNeedsDisplay()
    }

    // ---- desenho ----
    override func draw(_ rect: CGRect) {
        guard let s = session, let c = UIGraphicsGetCurrentContext() else { return }
        c.setFillColor(backgroundColor?.cgColor ?? UIColor.darkGray.cgColor)
        c.fill(bounds)
        let v = s.view
        let st = s.state
        let visible = CGRect(x: -v.ox / v.scale, y: -v.oy / v.scale, width: bounds.width / v.scale, height: bounds.height / v.scale)
        let live: String? = st.inGesture ? controller?.liveId : nil
        // câmera mexendo (arrastando a folha ou pinça): desenha direto; a imagem guardada é refeita uma vez ao soltar
        let moving = active != nil && !s.screenLocked && (multi || (controller?.panning ?? false))
        // outros gestos (mover, alça, borracha, forma) e o laço mudam a folha a cada quadro: desenho direto
        let usable = !cacheOff && !moving && (live != nil || !st.inGesture) && s.lasso.isEmpty && bounds.width >= 1 && bounds.height >= 1
        if usable {
            let cam = "\(v.ox)|\(v.oy)|\(v.scale)|\(bounds.width)|\(bounds.height)|\(st.pageIdx)"
            let key = "\(s.staticRev)|\(cam)"
            if cache == nil || cacheKey != key || (cacheStale && live == nil) {
                if !bake(s, v, cam, key) { rebuild(s, v, visible, key, skip: live) }
            } else { cacheHits += 1 }
            cache?.draw(in: bounds)
            if let lid = live {
                // escrevendo: só o traço novo é desenhado a cada quadro, por cima da imagem guardada
                c.saveGState()
                c.translateBy(x: v.ox, y: v.oy)
                c.scaleBy(x: v.scale, y: v.scale)
                c.translateBy(x: 0, y: CGFloat(st.pageIdx) * (Sheet.H + Sheet.GAP))
                renderer.drawOne(c, st.sheet, st.unit, id: lid)
                c.restoreGState()
                liveMark = (id: lid, cam: cam, rev: s.staticRev, count: st.sheet.objs.count)
            } else { liveMark = nil }
        } else {
            if !cacheOff { liveMark = nil }
            c.saveGState()
            c.translateBy(x: v.ox, y: v.oy)
            c.scaleBy(x: v.scale, y: v.scale)
            drawScene(c, s, v.scale, selected: true, visible: visible, with: renderer)
            c.restoreGState()
        }
        // rastro da borracha: faixa clara por onde passou + o círculo dela
        if !s.eraserTrail.isEmpty {
            c.saveGState()
            c.translateBy(x: v.ox, y: v.oy)
            c.scaleBy(x: v.scale, y: v.scale)
            c.translateBy(x: 0, y: CGFloat(s.state.pageIdx) * (Sheet.H + Sheet.GAP))
            let er = s.eraserSize / v.scale
            if s.eraserTrail.count > 1 {
                c.setStrokeColor(UIColor(white: 0.5, alpha: 0.2).cgColor)
                c.setLineWidth(er * 2); c.setLineCap(.round); c.setLineJoin(.round)
                c.beginPath(); c.move(to: s.eraserTrail[0].cg)
                for p in s.eraserTrail.dropFirst() { c.addLine(to: p.cg) }
                c.strokePath()
            }
            let last = s.eraserTrail[s.eraserTrail.count - 1]
            let rr = CGRect(x: last.x - er, y: last.y - er, width: er * 2, height: er * 2)
            c.setFillColor(UIColor(white: 1, alpha: 0.33).cgColor); c.fillEllipse(in: rr)
            c.setStrokeColor(UIColor(white: 0.4, alpha: 1).cgColor); c.setLineWidth(1.5 / v.scale); c.strokeEllipse(in: rr)
            c.restoreGState()
        }

        // lupa circular com mira (3,4×)
        if let f = s.loupe {
            let size: CGFloat = 124, r = size / 2, margin: CGFloat = 12
            let left = f.x > bounds.width * 0.55 && f.y < 300
            let lcx = left ? margin + r : bounds.width - margin - r
            let lcy = 150 + r
            let fw = v.toWorld(f)
            c.saveGState()
            c.addEllipse(in: CGRect(x: lcx - r, y: lcy - r, width: size, height: size)); c.clip()
            c.setFillColor(UIColor.white.cgColor); c.fill(bounds)
            c.translateBy(x: lcx, y: lcy)
            c.scaleBy(x: v.scale * 3.4, y: v.scale * 3.4)
            c.translateBy(x: -fw.x, y: -fw.y)
            drawScene(c, s, v.scale * 3.4, selected: false, visible: CGRect(x: fw.x - 60, y: fw.y - 60, width: 120, height: 120), with: loupeRenderer)
            c.restoreGState()
            c.setStrokeColor(UIColor(white: 0.13, alpha: 1).cgColor); c.setLineWidth(1)
            c.strokeLineSegments(between: [CGPoint(x: lcx - r * 0.35, y: lcy), CGPoint(x: lcx + r * 0.35, y: lcy), CGPoint(x: lcx, y: lcy - r * 0.35), CGPoint(x: lcx, y: lcy + r * 0.35)])
            c.setStrokeColor(UIColor.white.cgColor); c.setLineWidth(3)
            c.strokeEllipse(in: CGRect(x: lcx - r, y: lcy - r, width: size, height: size))
        }
    }

    /// Desenha a folha inteira na imagem guardada (sem o traço que está sendo escrito).
    private func rebuild(_ s: EditorSession, _ v: ViewState, _ visible: CGRect, _ key: String, skip: String?) {
        let fmt = UIGraphicsImageRendererFormat.default()
        fmt.opaque = true
        let size = bounds.size
        let bg = backgroundColor?.cgColor ?? UIColor.darkGray.cgColor
        renderer.resetMissing()
        cache = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
            let cc = ctx.cgContext
            cc.setFillColor(bg)
            cc.fill(CGRect(origin: .zero, size: size))
            cc.translateBy(x: v.ox, y: v.oy)
            cc.scaleBy(x: v.scale, y: v.scale)
            drawScene(cc, s, v.scale, selected: true, visible: visible, skipId: skip, with: renderer)
        }
        cacheKey = key
        cacheStale = renderer.missingPhoto
        fullRenders += 1
    }

    /// Soltou o traço e mais nada mudou: o traço pronto é somado à imagem guardada, sem desenhar a folha inteira de novo
    /// (com a folha cheia ou com fotos, redesenhar tudo a cada traço era o que atrasava a escrita).
    private func bake(_ s: EditorSession, _ v: ViewState, _ cam: String, _ key: String) -> Bool {
        guard let m = liveMark, let old = cache, !cacheStale, m.cam == cam, cacheKey == "\(m.rev)|\(cam)", s.staticRev == m.rev &+ 1 else { return false }
        let st = s.state
        guard !st.inGesture, st.selectedId == nil, st.groupIds.isEmpty else { return false }
        let objs = st.sheet.objs
        // o traço ficou como o último da folha, ou o gesto foi cancelado e a folha voltou ao que era
        let kept = objs.count == m.count && objs.last?.id == m.id && objs.last?.asStroke != nil
        let gone = objs.count == m.count - 1 && !objs.contains(where: { $0.id == m.id })
        guard kept || gone else { return false }
        if kept {
            let fmt = UIGraphicsImageRendererFormat.default()
            fmt.opaque = true
            let size = bounds.size
            let sheet = st.sheet, unit = st.unit, page = st.pageIdx
            cache = UIGraphicsImageRenderer(size: size, format: fmt).image { ctx in
                old.draw(in: CGRect(origin: .zero, size: size))
                let cc = ctx.cgContext
                cc.translateBy(x: v.ox, y: v.oy)
                cc.scaleBy(x: v.scale, y: v.scale)
                cc.translateBy(x: 0, y: CGFloat(page) * (Sheet.H + Sheet.GAP))
                renderer.drawOne(cc, sheet, unit, id: m.id)
            }
        }
        cacheKey = key
        bakes += 1
        return true
    }

    private func drawScene(_ c: CGContext, _ s: EditorSession, _ scale: CGFloat, selected: Bool, visible: CGRect, skipId: String? = nil, with renderer: SheetRenderer) {
        let st = s.state
        let step = Sheet.H + Sheet.GAP
        for (i, page) in st.note.pages.enumerated() {
            let y0 = CGFloat(i) * step
            if y0 > visible.maxY || y0 + Sheet.H < visible.minY { continue }
            c.saveGState()
            c.translateBy(x: 0, y: y0)
            renderer.draw(c, page, st.unit, selectedId: (selected && i == st.pageIdx) ? st.selectedId : nil, viewScale: scale, selectedSeg: st.selectedSeg, skipId: i == st.pageIdx ? skipId : nil)
            if i == st.pageIdx {
                c.setStrokeColor(UIColor(red: 0.18, green: 0.5, blue: 0.93, alpha: 1).cgColor)
                c.setLineWidth(2 / scale)
                c.setLineDash(phase: 0, lengths: [8 / scale, 6 / scale])
                for o in st.groupObjs() {
                    let b = Geo.bounds(page, o)
                    let pad = 4 / scale
                    c.stroke(CGRect(x: b.l - pad, y: b.t - pad, width: b.r - b.l + 2 * pad, height: b.b - b.t + 2 * pad))
                }
                if s.lasso.count > 1 {
                    c.beginPath(); c.move(to: s.lasso[0].cg)
                    for p in s.lasso.dropFirst() { c.addLine(to: p.cg) }
                    c.strokePath()
                }
                c.setLineDash(phase: 0, lengths: [])
            }
            c.restoreGState()
        }
    }
}

struct SheetCanvas: UIViewRepresentable {
    @ObservedObject var session: EditorSession
    var onAction: (GestureAction) -> Void

    func makeUIView(context: Context) -> SheetCanvasView {
        let v = SheetCanvasView(frame: .zero)
        v.session = session
        v.onAction = onAction
        return v
    }

    func updateUIView(_ v: SheetCanvasView, context: Context) {
        if v.session !== session { v.session = session }
        v.onAction = onAction
        v.setNeedsDisplay()
    }
}
