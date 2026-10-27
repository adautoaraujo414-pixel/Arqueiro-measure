package br.com.arque.measure.ui

import br.com.arque.measure.i18n.tr

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlin.math.roundToInt

/** Cálculo simples: + − × ÷ e %, com parênteses não necessários. "100+10%" = 110. Retorna null se a conta estiver incompleta. */
internal object CalcEval {
    fun eval(src: String): Double? {
        val s = src.replace(" ", "")
        if (s.isEmpty()) return null
        return try {
            val p = P(s); val v = p.expr(); if (p.i != s.length) null else if (v.isNaN() || v.isInfinite()) null else v
        } catch (_: Exception) { null }
    }

    private class P(val s: String) {
        var i = 0
        fun expr(): Double {
            var v = term()
            while (i < s.length && (s[i] == '+' || s[i] == '−')) {
                val op = s[i++]
                var r = term()
                if (i < s.length && s[i] == '%') { i++; r = v * r / 100.0 }
                v = if (op == '+') v + r else v - r
            }
            return v
        }
        fun term(): Double {
            var v = num()
            while (i < s.length && (s[i] == '×' || s[i] == '÷')) {
                val op = s[i++]
                val r = num()
                v = if (op == '×') v * r else v / r
            }
            return v
        }
        fun num(): Double {
            val st = i
            while (i < s.length && (s[i].isDigit() || s[i] == '.')) i++
            if (st == i) throw IllegalStateException()
            var v = s.substring(st, i).toDouble()
            // % solto (não depois de + ou −): vira centésimo
            if (i < s.length && s[i] == '%') {
                val next = if (i + 1 < s.length) s[i + 1] else ' '
                val prevOp = st > 0 && (s[st - 1] == '+' || s[st - 1] == '−')
                if (!prevOp || next == '×' || next == '÷') { i++; v /= 100.0 }
            }
            return v
        }
    }

    fun fmt(v: Double): String {
        val r = Math.round(v * 1_000_000.0) / 1_000_000.0
        val t = if (r == Math.floor(r) && Math.abs(r) < 1e15) r.toLong().toString()
        else java.math.BigDecimal(r).setScale(6, java.math.RoundingMode.HALF_UP).stripTrailingZeros().toPlainString()
        return t.replace('.', ',')
    }
}

/** Calculadora flutuante: bolinha que se arrasta; toque abre o painel (também arrastável pela barra de cima). */
@Composable
fun BoxScope.FloatingCalculator() {
    var open by remember { mutableStateOf(false) }
    var ox by remember { mutableStateOf(0f) }
    var oy by remember { mutableStateOf(0f) }
    var expr by remember { mutableStateOf("") }
    var done by remember { mutableStateOf(false) }

    val result = CalcEval.eval(expr)
    fun press(k: String) {
        when (k) {
            "C" -> { expr = ""; done = false }
            "⌫" -> { expr = expr.dropLast(1); done = false }
            "=" -> { result?.let { expr = CalcEval.fmt(it).replace(',', '.'); done = true } }
            "+", "−", "×", "÷" -> {
                if (expr.isEmpty()) { if (k == "−") expr = "0−" ; return }
                done = false
                expr = if (expr.last() in "+−×÷") expr.dropLast(1) + k else expr + k
            }
            "%" -> if (expr.isNotEmpty() && expr.last().isDigit()) { done = false; expr += "%" }
            "," -> {
                val last = expr.takeLastWhile { it.isDigit() || it == '.' }
                if (done) { expr = "0."; done = false }
                else if (!last.contains('.')) expr += if (last.isEmpty()) "0." else "."
            }
            else -> { if (done) { expr = k; done = false } else expr += k }
        }
    }

    val dragMod = Modifier.pointerInput(Unit) {
        detectDragGestures { c, d -> c.consume(); ox += d.x; oy += d.y }
    }

    if (!open) {
        Box(
            Modifier.align(Alignment.BottomEnd).offset { IntOffset(ox.roundToInt(), oy.roundToInt()) }
                .padding(end = 20.dp, bottom = 90.dp).size(56.dp).clip(CircleShape).background(Ui.accent)
                .then(dragMod).clickable { open = true },
            contentAlignment = Alignment.Center,
        ) { Text("÷×", color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold) }
        return
    }

    Column(
        Modifier.align(Alignment.BottomEnd).offset { IntOffset(ox.roundToInt(), oy.roundToInt()) }
            .padding(end = 16.dp, bottom = 90.dp).width(250.dp)
            .clip(RoundedCornerShape(16.dp)).background(Ui.panel).padding(8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Row(Modifier.fillMaxWidth().then(dragMod), verticalAlignment = Alignment.CenterVertically) {
            Text(tr("Calculadora  ⠿"), color = Ui.dim, fontSize = 12.sp, modifier = Modifier.weight(1f).padding(start = 4.dp))
            Text("✕", color = Ui.text, fontSize = 18.sp, modifier = Modifier.clickable { open = false }.padding(horizontal = 10.dp, vertical = 2.dp))
        }
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Ui.bg).padding(10.dp), horizontalAlignment = Alignment.End) {
            Text(expr.replace('.', ',').ifEmpty { "0" }, color = Ui.dim, fontSize = 14.sp, maxLines = 1, textAlign = TextAlign.End)
            Text(
                if (done || result == null) (result?.let { CalcEval.fmt(it) } ?: "") else CalcEval.fmt(result),
                color = Ui.text, fontSize = 26.sp, fontWeight = FontWeight.Medium, maxLines = 1, textAlign = TextAlign.End,
                modifier = Modifier.height(34.dp),
            )
        }
        val rows = listOf(
            listOf("C", "⌫", "%", "÷"),
            listOf("7", "8", "9", "×"),
            listOf("4", "5", "6", "−"),
            listOf("1", "2", "3", "+"),
            listOf("0", ",", "=", ""),
        )
        rows.forEach { r ->
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                r.forEach { k ->
                    if (k.isEmpty()) { Box(Modifier.weight(1f)) ; return@forEach }
                    val op = k in listOf("÷", "×", "−", "+", "=")
                    Box(
                        Modifier.weight(1f).height(44.dp).clip(RoundedCornerShape(10.dp))
                            .background(if (k == "=") Ui.accent else if (op) Ui.panel2 else Ui.bg)
                            .clickable { press(k) },
                        contentAlignment = Alignment.Center,
                    ) { Text(k, color = if (k == "=") Color.White else Ui.text, fontSize = 20.sp) }
                }
            }
        }
    }
}
