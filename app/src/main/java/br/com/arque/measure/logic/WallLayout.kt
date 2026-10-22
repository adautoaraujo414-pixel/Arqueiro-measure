package br.com.arque.measure.logic

import br.com.arque.measure.model.CabObj
import br.com.arque.measure.model.Pt
import br.com.arque.measure.model.Sheet
import br.com.arque.measure.model.WallObj

/**
 * Posiciona os módulos presos a uma parede: os de baixo no chão e os superiores a [WallObj.upperBottomMm],
 * cada fileira um ao lado do outro (na ordem), a partir da esquerda. Chamado a cada alteração da folha,
 * então mudar a largura de um módulo empurra os vizinhos.
 */
object WallLayout {
    /** Largura que o módulo ocupa na parede: a dele mais os tamponamentos laterais (medida final). */
    fun padL(m: CabObj) = if (m.cab.tampEsq) m.cab.espMm else 0.0
    fun padR(m: CabObj) = if (m.cab.tampDir) m.cab.espMm else 0.0
    fun occ(m: CabObj) = padL(m) + m.cab.wMm + padR(m)

    /** Altura do topo do módulo (mm do chão): fixa no topo se estiver alinhado por cima, senão sobe da base. */
    fun topMm(w: WallObj, m: CabObj): Double =
        if (m.layout?.anchorTop == true) m.layout.topMm else (if (m.cab.superior) w.upperBottomMm else 0.0) + m.cab.hMm

    /** Trechos de módulos vizinhos cujo tamponamento de baixo é uma peça só (2 ou mais seguidos). */
    fun joinedRuns(sheet: Sheet, wallId: String, upper: Boolean): List<List<CabObj>> {
        val out = ArrayList<List<CabObj>>()
        var cur = ArrayList<CabObj>()
        for (m in members(sheet, wallId, upper)) {
            if (m.cab.tampBaixo && m.cab.tampBaixoJunto) cur.add(m) else { if (cur.size >= 2) out.add(cur); cur = ArrayList() }
        }
        if (cur.size >= 2) out.add(cur)
        return out
    }

    /** Comprimento (mm) da peça contínua: soma do que cada módulo ocupa. */
    fun runLength(run: List<CabObj>): Double = run.sumOf { occ(it) }

    fun members(sheet: Sheet, wallId: String, upper: Boolean): List<CabObj> =
        sheet.objs.filterIsInstance<CabObj>()
            .filter { it.layout?.wallId == wallId && it.cab.superior == upper }
            .sortedBy { it.layout!!.order }

    fun sync(s: Sheet): Sheet {
        if (s.objs.none { it is WallObj }) {
            return if (s.objs.any { it is CabObj && it.layout != null }) s.copy(objs = s.objs.map { if (it is CabObj && it.layout != null) it.copy(layout = null) else it }) else s
        }
        val walls = s.objs.filterIsInstance<WallObj>().associateBy { it.id }
        val upd = HashMap<String, CabObj>()
        for (w in walls.values) {
            for (upper in listOf(false, true)) {
                val row = members(s, w.id, upper)
                val slack = w.wMm - row.sumOf { occ(it) }
                var x = when (w.alignRow) { 0 -> 0.0; 2 -> slack.coerceAtLeast(0.0); else -> (slack / 2.0).coerceAtLeast(0.0) }
                row.forEachIndexed { i, m ->
                    val k = w.upm
                    val at = Pt((w.at.x + (x + padL(m)) * k).toFloat(), (w.at.y + (w.hMm - topMm(w, m)) * k).toFloat())
                    upd[m.id] = m.copy(at = at, scaleDen = w.scaleDen, layout = m.layout!!.copy(order = i))
                    x += occ(m)
                }
            }
        }
        var changed = false
        val out = s.objs.map { o ->
            if (o is CabObj && o.layout != null) {
                val n = upd[o.id] ?: o.copy(layout = null) // parede apagada: o módulo fica solto
                if (n != o) changed = true
                n
            } else o
        }
        return if (changed) s.copy(objs = out) else s
    }
}
