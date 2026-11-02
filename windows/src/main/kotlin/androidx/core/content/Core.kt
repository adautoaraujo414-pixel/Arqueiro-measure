@file:Suppress("unused", "UNUSED_PARAMETER")

package androidx.core.content

import android.content.Context
import android.net.Uri
import java.io.File

object FileProvider {
    @JvmStatic fun getUriForFile(ctx: Context, authority: String, f: File): Uri = Uri.fromFile(f)
}

object ContextCompat {
    @JvmStatic fun checkSelfPermission(ctx: Context, perm: String): Int = android.content.pm.PackageManager.PERMISSION_GRANTED
}
