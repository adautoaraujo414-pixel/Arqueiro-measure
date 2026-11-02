package androidx.compose.ui.graphics

/** Bitmap "do Android" (Skia por baixo) para mostrar no Compose. */
fun android.graphics.Bitmap.asImageBitmap(): ImageBitmap = this.sk.asComposeImageBitmap()
