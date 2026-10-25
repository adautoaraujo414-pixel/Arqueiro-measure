package br.com.arque.measure.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import br.com.arque.measure.logic.Calc

/**
 * Teclado numérico do próprio app (o teclado do celular nunca abre para números).
 * Aceita dígitos, vírgula e contas de + e − (ex.: 2750−4), o resultado é calculado no OK.
 */
@Composable
fun AppNumPad(text: String, onText: (String) -> Unit, allowOps: Boolean = true) {
    val keys = if (allowOps) listOf("7", "8", "9", "⌫", "4", "5", "6", "+", "1", "2", "3", "−", "C", "0", ",", "")
    else listOf("7", "8", "9", "⌫", "4", "5", "6", "C", "1", "2", "3", "", "", "0", ",", "")
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        val res = if (allowOps && text.any { it == '+' || it == '−' }) Calc.eval(text) else null
        Box(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(Color(0xFFE6EEFF)).padding(horizontal = 12.dp, vertical = 10.dp),
        ) {
            Column(Modifier.fillMaxWidth()) {
                Text(if (text.isEmpty()) "0" else text, color = Color(0xFF0B2A3D), fontSize = 26.sp, fontFamily = FontFamily.Monospace, textAlign = TextAlign.End, modifier = Modifier.fillMaxWidth())
                if (res != null) Text("= " + Calc.format(res), color = Color(0xFF3B5B85), fontSize = 14.sp, textAlign = TextAlign.End, modifier = Modifier.fillMaxWidth())
            }
        }
        keys.chunked(4).forEach { row ->
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                row.forEach { k ->
                    val bg = when (k) {
                        "" -> Color.Transparent
                        "⌫", "C" -> Color(0xFF5A3A3A)
                        "+", "−" -> Color(0xFF34527F)
                        else -> Color(0xFF2B303B)
                    }
                    Box(
                        Modifier.weight(1f).height(50.dp).clip(RoundedCornerShape(10.dp)).background(bg)
                            .clickable(enabled = k.isNotEmpty()) {
                                when (k) {
                                    "⌫" -> onText(text.dropLast(1))
                                    "C" -> onText("")
                                    "," -> {
                                        val last = text.split('+', '−').last()
                                        if (!last.contains(',')) onText(if (last.isEmpty()) text + "0," else "$text,")
                                    }
                                    "+", "−" -> if (text.isNotEmpty() && text.last().isDigit()) onText(text + k)
                                    else -> onText(text + k)
                                }
                            },
                        contentAlignment = Alignment.Center,
                    ) { Text(k, color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.SemiBold) }
                }
            }
        }
    }
}

/** Valor digitado no teclado do app: resolve a conta (se tiver) e devolve o número. */
fun numPadValue(text: String): Double? {
    if (text.isBlank()) return null
    return Calc.eval(text)
}

/** Diálogo com o teclado do app. */
@Composable
fun NumPadDialog(title: String, initial: String, suffix: String = "", allowOps: Boolean = true, hint: String? = null, onDismiss: () -> Unit, onOk: (Double) -> Unit) {
    var t by remember { mutableStateOf(initial) }
    val v = numPadValue(t)
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (suffix.isEmpty()) title else "$title ($suffix)") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                AppNumPad(t, { t = it }, allowOps)
                if (hint != null) Text(hint, fontSize = 12.sp, color = Color(0xFF555555))
            }
        },
        confirmButton = { TextButton(enabled = v != null, onClick = { v?.let(onOk) }) { Text("OK") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancelar") } },
    )
}

/** Campo numérico que abre o teclado do app ao tocar (no lugar do teclado do celular). */
@Composable
fun NumPadField(value: String, label: String, modifier: Modifier = Modifier, onValue: (Double) -> Unit) {
    var open by remember { mutableStateOf(false) }
    Column(
        modifier.clip(RoundedCornerShape(8.dp)).background(Color(0xFFF1F4F9)).clickable { open = true }.padding(horizontal = 12.dp, vertical = 6.dp),
    ) {
        Text(label, fontSize = 11.sp, color = Color(0xFF555555))
        Text(if (value.isEmpty()) "–" else value, fontSize = 17.sp, color = Color(0xFF111111))
    }
    if (open) NumPadDialog(label, value, onDismiss = { open = false }) { v -> onValue(v); open = false }
}
