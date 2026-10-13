package com.scamwatch.negavsinparis

import android.os.Environment

object PublicStorage {
    fun downloadsDir(): String =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            ?.absolutePath
            .orEmpty()
}
