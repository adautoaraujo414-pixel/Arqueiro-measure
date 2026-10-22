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
                var x = 0.0
                members(s, w.id, upper).forEachIndexed { i, m ->
                    val k = w.upm
                    val bottom = if (upper) w.upperBottomMm else 0.0
                    val at = Pt((w.at.x + (x + padL(m)) * k).toFloat(), (w.at.y + (w.hMm - bottom - m.cab.hMm) * k).toFloat())
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
