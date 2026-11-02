@file:Suppress("unused", "UNUSED_PARAMETER")

package android.content.pm

import android.content.Intent

object PackageManager {
    const val PERMISSION_GRANTED = 0
    const val PERMISSION_DENIED = -1
    fun getLaunchIntentForPackage(pkg: String): Intent? = null
}
