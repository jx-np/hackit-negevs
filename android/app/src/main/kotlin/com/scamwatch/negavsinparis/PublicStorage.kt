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

    /**
     * Shared-storage roots to search for user-provided model files once
     * "All files access" is granted (debug-only). Returns the common
     * download/document folders plus the external storage root. Only existing
     * directories are returned, newline-joined, so the Dart side can split and
     * scan each. Empty when external storage is unavailable.
     */
    fun scanRoots(): String {
        val roots = buildList {
            add(Environment.getExternalStorageDirectory())
            add(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS))
            add(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS))
        }
        return roots
            .filterNotNull()
            .map { it.absolutePath }
            .filter { it.isNotEmpty() }
            .distinct()
            .joinToString("\n")
    }
}
