@file:Suppress("unused")

package android.provider

import android.net.Uri

object MediaStore {
    const val ACTION_IMAGE_CAPTURE = "android.media.action.IMAGE_CAPTURE"
    const val ACTION_VIDEO_CAPTURE = "android.media.action.VIDEO_CAPTURE"
    const val EXTRA_OUTPUT = "output"

    object MediaColumns {
        const val DISPLAY_NAME = "_display_name"
        const val MIME_TYPE = "mime_type"
        const val RELATIVE_PATH = "relative_path"
    }

    object Images {
        object Media {
            @JvmField val EXTERNAL_CONTENT_URI: Uri = Uri.parse("content://media/external/images/media")
            const val DISPLAY_NAME = MediaColumns.DISPLAY_NAME
            const val MIME_TYPE = MediaColumns.MIME_TYPE
            const val RELATIVE_PATH = MediaColumns.RELATIVE_PATH
        }
    }

    object Video {
        object Media {
            @JvmField val EXTERNAL_CONTENT_URI: Uri = Uri.parse("content://media/external/video/media")
            const val DISPLAY_NAME = MediaColumns.DISPLAY_NAME
            const val MIME_TYPE = MediaColumns.MIME_TYPE
            const val RELATIVE_PATH = MediaColumns.RELATIVE_PATH
        }
    }

    object Downloads {
        @JvmField val EXTERNAL_CONTENT_URI: Uri = Uri.parse("content://media/external/downloads")
        const val DISPLAY_NAME = MediaColumns.DISPLAY_NAME
        const val MIME_TYPE = MediaColumns.MIME_TYPE
        const val RELATIVE_PATH = MediaColumns.RELATIVE_PATH
        const val _ID = "_id"
    }
}

object Settings {
    const val ACTION_REQUEST_SCHEDULE_EXACT_ALARM = "android.settings.REQUEST_SCHEDULE_EXACT_ALARM"
    const val ACTION_MANAGE_UNKNOWN_APP_SOURCES = "android.settings.MANAGE_UNKNOWN_APP_SOURCES"
    const val ACTION_APP_NOTIFICATION_SETTINGS = "android.settings.APP_NOTIFICATION_SETTINGS"
    const val ACTION_BLUETOOTH_SETTINGS = "android.settings.BLUETOOTH_SETTINGS"
    const val EXTRA_APP_PACKAGE = "android.provider.extra.APP_PACKAGE"
}
