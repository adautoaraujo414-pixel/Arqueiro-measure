package br.com.arque.measure.compat

import androidx.compose.ui.graphics.nativeCanvas as skiaCanvas

/** O "nativeCanvas" do Android (android.graphics.Canvas) em cima do Canvas Skia do Compose Desktop. */
val androidx.compose.ui.graphics.Canvas.nativeCanvas: android.graphics.Canvas
    get() = android.graphics.Canvas(this.skiaCanvas)
