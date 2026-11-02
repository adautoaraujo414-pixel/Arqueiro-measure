@file:Suppress("unused")

package androidx.activity.result.contract

import android.content.Intent
import android.net.Uri
import androidx.activity.result.ActivityResult

/** Os "contratos" do Android: no Windows viram as janelas de abrir/salvar arquivo. */
abstract class ActivityResultContract<I, O>

object ActivityResultContracts {
    class GetContent : ActivityResultContract<String, Uri?>()
    class GetMultipleContents : ActivityResultContract<String, List<Uri>>()
    class OpenDocument : ActivityResultContract<Array<String>, Uri?>()
    class CreateDocument(val mimeType: String) : ActivityResultContract<String, Uri?>()
    class TakePicture : ActivityResultContract<Uri, Boolean>()
    class RequestPermission : ActivityResultContract<String, Boolean>()
    class RequestMultiplePermissions : ActivityResultContract<Array<String>, Map<String, Boolean>>()
    class StartActivityForResult : ActivityResultContract<Intent, ActivityResult>()
}
