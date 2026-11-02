package android.webkit

class MimeTypeMap private constructor() {
    fun getExtensionFromMimeType(mime: String?): String? = when (mime?.lowercase()) {
        "image/jpeg", "image/jpg" -> "jpg"
        "image/png" -> "png"
        "image/webp" -> "webp"
        "image/gif" -> "gif"
        "image/bmp" -> "bmp"
        "image/heic" -> "heic"
        "video/mp4" -> "mp4"
        "application/pdf" -> "pdf"
        "application/zip" -> "zip"
        "text/csv" -> "csv"
        "text/plain" -> "txt"
        else -> null
    }

    fun getMimeTypeFromExtension(ext: String?): String? = mimeOf("x." + (ext ?: ""))

    companion object {
        private val single = MimeTypeMap()
        @JvmStatic fun getSingleton(): MimeTypeMap = single
        @JvmStatic fun getFileExtensionFromUrl(url: String?): String = url?.substringAfterLast('/')?.substringAfterLast('.', "")?.lowercase() ?: ""
        fun mimeOf(name: String): String? = when (name.substringAfterLast('.', "").lowercase()) {
            "jpg", "jpeg", "jfif" -> "image/jpeg"
            "png" -> "image/png"
            "webp" -> "image/webp"
            "gif" -> "image/gif"
            "bmp" -> "image/bmp"
            "heic", "heif" -> "image/heic"
            "mp4", "m4v" -> "video/mp4"
            "mov" -> "video/quicktime"
            "webm" -> "video/webm"
            "pdf" -> "application/pdf"
            "zip" -> "application/zip"
            "csv" -> "text/csv"
            "txt" -> "text/plain"
            "json" -> "application/json"
            "html", "htm" -> "text/html"
            "js" -> "text/javascript"
            "css" -> "text/css"
            "svg" -> "image/svg+xml"
            "woff2" -> "font/woff2"
            else -> null
        }
    }
}
