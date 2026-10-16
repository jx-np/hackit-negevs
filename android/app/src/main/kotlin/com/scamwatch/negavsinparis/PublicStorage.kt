package com.scamwatch.negavsinparis

import android.content.Context
import android.os.Environment

object PublicStorage {
    fun downloadsDir(): String =
        Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            ?.absolutePath
            .orEmpty()

    /**
     * App-specific external directory for storing downloaded models. Writing
     * here needs no storage permission because Android owns the path and wipes
     * it on uninstall. Falls back to internal storage if external is unavailable.
     */
    fun appModelsDir(context: Context): String =
        (context.getExternalFilesDir(null) ?: context.filesDir)
            .absolutePath
}
