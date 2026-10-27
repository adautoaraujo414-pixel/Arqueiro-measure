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
    private var controller: GestureController!
    private let renderer = SheetRenderer()

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
    /// Imagem do que está parado na folha enquanto se escreve (só o traço novo é redesenhado).
    private var cache: UIImage?
    private var cacheKey = ""

    /// Contato grande (mão, punho) e não é o Apple Pencil.
    private func isPalm(_ t: UITouch) -> Bool { t.type != .pencil && t.majorRadius > 30 }

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
        let visible = CGRect(x: -v.ox / v.scale, y: -v.oy / v.scale, width: bounds.width / v.scale, height: bounds.height / v.scale)
        if let lid = controller?.liveId, s.state.inGesture {
            // escrevendo: o resto da folha vira uma imagem (feita uma vez); só o traço novo é desenhado a cada quadro
            let key = "\(s.staticRev)|\(v.ox)|\(v.oy)|\(v.scale)|\(bounds.width)|\(bounds.height)|\(lid)|\(s.state.pageIdx)"
            if cache == nil || cacheKey != key {
                let fmt = UIGraphicsImageRendererFormat.default()
                fmt.opaque = true
                cache = UIGraphicsImageRenderer(size: bounds.size, format: fmt).image { ctx in
                    let cc = ctx.cgContext
                    cc.setFillColor(backgroundColor?.cgColor ?? UIColor.darkGray.cgColor)
                    cc.fill(CGRect(origin: .zero, size: bounds.size))
                    cc.translateBy(x: v.ox, y: v.oy)
                    cc.scaleBy(x: v.scale, y: v.scale)
                    drawScene(cc, s, v.scale, selected: true, visible: visible, skipId: lid)
                }
                cacheKey = key
            }
            cache?.draw(in: bounds)
            c.saveGState()
            c.translateBy(x: v.ox, y: v.oy)
            c.scaleBy(x: v.scale, y: v.scale)
            c.translateBy(x: 0, y: CGFloat(s.state.pageIdx) * (Sheet.H + Sheet.GAP))
            renderer.drawOne(c, s.state.sheet, s.state.unit, id: lid)
            c.restoreGState()
        } else {
            cache = nil
            c.saveGState()
            c.translateBy(x: v.ox, y: v.oy)
            c.scaleBy(x: v.scale, y: v.scale)
            drawScene(c, s, v.scale, selected: true, visible: visible)
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
            drawScene(c, s, v.scale * 3.4, selected: false, visible: CGRect(x: fw.x - 60, y: fw.y - 60, width: 120, height: 120))
            c.restoreGState()
            c.setStrokeColor(UIColor(white: 0.13, alpha: 1).cgColor); c.setLineWidth(1)
            c.strokeLineSegments(between: [CGPoint(x: lcx - r * 0.35, y: lcy), CGPoint(x: lcx + r * 0.35, y: lcy), CGPoint(x: lcx, y: lcy - r * 0.35), CGPoint(x: lcx, y: lcy + r * 0.35)])
            c.setStrokeColor(UIColor.white.cgColor); c.setLineWidth(3)
            c.strokeEllipse(in: CGRect(x: lcx - r, y: lcy - r, width: size, height: size))
        }
    }

    private func drawScene(_ c: CGContext, _ s: EditorSession, _ scale: CGFloat, selected: Bool, visible: CGRect, skipId: String? = nil) {
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
