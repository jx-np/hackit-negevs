package com.example.call_log_app

import android.content.Context

object SpamStore {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ENABLED = "flutter.spam_protection_enabled"
    private const val KEY_BLOCKED = "flutter.spam_blocked_numbers"

    fun canonical(raw: String?): String {
        val digits = raw.orEmpty().filter { it.isDigit() }
        val hasUsCountryCode = digits.length == 11 && digits.startsWith("1")
        return if (hasUsCountryCode) digits.substring(1) else digits
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    fun blockedNumbers(context: Context): Set<String> =
        prefs(context).getString(KEY_BLOCKED, "")
            .orEmpty()
            .split(",")
            .map { canonical(it) }
            .filter { it.isNotEmpty() }
            .toSet()

    fun isBlocked(context: Context, rawNumber: String?): Boolean {
        val key = canonical(rawNumber)
        return key.isNotEmpty() && blockedNumbers(context).contains(key)
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
