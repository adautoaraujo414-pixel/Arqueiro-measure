@file:Suppress("unused")

package android.os

object Build {
    @JvmField val MODEL: String = System.getenv("COMPUTERNAME") ?: "Windows"
    @JvmField val MANUFACTURER: String = "PC"
    object VERSION { const val SDK_INT = 34 }
    object VERSION_CODES { const val Q = 29; const val R = 30; const val S = 31; const val TIRAMISU = 33; const val O = 26; const val P = 28 }
}

object SystemClock {
    private val t0 = System.nanoTime()
    @JvmStatic fun uptimeMillis(): Long = (System.nanoTime() - t0) / 1_000_000L
    @JvmStatic fun elapsedRealtime(): Long = uptimeMillis()
}

class Looper private constructor() {
    companion object {
        private val main = Looper()
        @JvmStatic fun getMainLooper(): Looper = main
        @JvmStatic fun myLooper(): Looper? = if (javax.swing.SwingUtilities.isEventDispatchThread()) main else null
    }
}

/** Handler do Android: posta na thread da interface (Swing/Compose). */
class Handler(@Suppress("UNUSED_PARAMETER") looper: Looper? = null) {
    fun post(r: Runnable): Boolean { javax.swing.SwingUtilities.invokeLater(r); return true }
    fun postDelayed(r: Runnable, ms: Long): Boolean {
        val t = javax.swing.Timer(ms.toInt().coerceAtLeast(0)) { r.run() }
        t.isRepeats = false; t.start(); return true
    }
    fun removeCallbacksAndMessages(@Suppress("UNUSED_PARAMETER") token: Any?) {}
}

class Bundle

interface Parcelable
