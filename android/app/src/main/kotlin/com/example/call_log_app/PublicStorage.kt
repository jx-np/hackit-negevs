package com.example.call_log_app

import android.os.Environment

object PublicStorage {
    fun downloadsDir(): String =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            ?.absolutePath
            .orEmpty()
}
