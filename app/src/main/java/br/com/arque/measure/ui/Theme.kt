package br.com.arque.measure.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object Ui {
    val bg = Color(0xFF17181B)
    val panel = Color(0xFF232529)
    val panel2 = Color(0xFF2E3136)
    val line = Color(0xFF3A3D43)
    val text = Color(0xFFF2F3F5)
    val dim = Color(0xFF9AA0A8)
    val accent = Color(0xFF3B82F6)
    val paperBg = Color(0xFF3A3C40)
    val distBlue = Color(0xFF1E5BD8)
}

private val ArqueColors = darkColorScheme(
    primary = Ui.accent,
    onPrimary = Color.White,
    primaryContainer = Color(0xFF1E3A66),
    onPrimaryContainer = Color(0xFFD6E6FF),
    secondary = Color(0xFFF5B400),
    background = Ui.bg,
    onBackground = Ui.text,
    surface = Ui.panel,
    onSurface = Ui.text,
    surfaceVariant = Ui.panel2,
    onSurfaceVariant = Ui.dim,
    outline = Ui.line,
)

@Composable
fun ArqueTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = ArqueColors, content = content)
}
