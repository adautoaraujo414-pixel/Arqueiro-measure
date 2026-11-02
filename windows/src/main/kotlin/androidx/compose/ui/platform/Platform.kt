@file:Suppress("unused")

package androidx.compose.ui.platform

import android.content.Context
import androidx.compose.runtime.staticCompositionLocalOf
import br.com.arque.measure.desktop.DesktopApp

/** O Context do app (no Windows existe um só). */
val LocalContext = staticCompositionLocalOf<Context> { DesktopApp.context }

/** Tamanho da janela em dp (no celular é o tamanho da tela). */
class Configuration(val screenWidthDp: Int, val screenHeightDp: Int)

val LocalConfiguration = staticCompositionLocalOf { Configuration(1280, 800) }
