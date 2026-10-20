package br.com.arque.measure.ui

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val ArqueColors = lightColorScheme(
    primary = Color(0xFF1F4E79),
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD6E6F5),
    onPrimaryContainer = Color(0xFF0B2A47),
    secondary = Color(0xFFB7791F),
    background = Color(0xFFF6F5F1),
    surface = Color(0xFFFFFFFF),
    surfaceVariant = Color(0xFFEDEBE5),
)

@Composable
fun ArqueTheme(content: @Composable () -> Unit) {
    MaterialTheme(colorScheme = ArqueColors, content = content)
}
