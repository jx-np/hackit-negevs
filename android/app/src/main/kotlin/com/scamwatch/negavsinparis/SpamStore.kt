package com.scamwatch.negavsinparis

import android.content.Context

object SpamStore {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ENABLED = "flutter.spam_protection_enabled"
    private const val KEY_BLOCKED = "flutter.spam_blocked_numbers"
    private const val KEY_SHIELD_ENABLED = "flutter.scam_shield_enabled"

    fun canonical(raw: String?): String {
        val digits = raw.orEmpty().filter { it.isDigit() }
        val hasUsCountryCode = digits.length == 11 && digits.startsWith("1")
        return if (hasUsCountryCode) digits.substring(1) else digits
    }

    fun isEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_ENABLED, false)

    /**
     * Mirror of the scam-shield on/off switch. Kept in the plain prefs file so
     * the native listener and boot receiver can decide whether to bring the
     * background service back without spinning up Flutter.
     */
    fun isShieldEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_SHIELD_ENABLED, false)

    fun setShieldEnabled(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(KEY_SHIELD_ENABLED, value).apply()
    }

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

    /**
     * Adds a number to the same list the Dart UI reads (`spam_blocked_numbers`)
     * and turns call protection on, so the call-screening service rejects it
     * from now on. The Dart side must `reload()` its prefs to see the change.
     */
    fun block(context: Context, rawNumber: String?) {
        val key = canonical(rawNumber)
        if (key.isEmpty()) return
        val updated = blockedNumbers(context) + key
        prefs(context).edit()
            .putString(KEY_BLOCKED, updated.joinToString(","))
            .putBoolean(KEY_ENABLED, true)
            .apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
