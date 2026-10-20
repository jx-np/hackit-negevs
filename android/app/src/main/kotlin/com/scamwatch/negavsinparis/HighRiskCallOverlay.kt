package com.scamwatch.negavsinparis

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Looks up a ringing number and raises the native high-risk call warning.
 *
 * Everything here is native on purpose: it is triggered by the phone-state
 * receiver / call-screening service, which run with the Flutter UI closed, so
 * it cannot depend on a Dart engine. The API base URL is mirrored into shared
 * preferences by `main()` (key `api_base_url`). The trust-score endpoint allows
 * anonymous access, so no token is needed.
 *
 * The warning itself lives in [HighRiskCallActivity]. It is an Activity (not a
 * `TYPE_APPLICATION_OVERLAY` window) because Android hides application
 * overlays while the keyguard is showing — precisely when most calls arrive.
 */
object HighRiskCallOverlay {

    private const val TAG = "HighRiskCallOverlay"
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_API_BASE_URL = "flutter.api_base_url"
    private const val RATING_HIGH_RISK = "high_risk"
    private const val TIMEOUT_MS = 6000

    private data class TrustScore(val rating: String, val score: Int?, val reportCount: Int)

    private val mainHandler = Handler(Looper.getMainLooper())
    private val lock = Any()

    /** Canonical number of the call being handled; guards against duplicate alerts. */
    private var currentKey: String? = null

    /**
     * Looks the number up off the main thread and shows the warning when it is
     * high risk. [onFinished] always runs, so a receiver can finish its
     * `goAsync()` result.
     */
    fun checkInBackground(context: Context, number: String?, onFinished: () -> Unit = {}) {
        val appContext = context.applicationContext
        try {
            Thread({
                try {
                    check(appContext, number)
                } catch (error: Exception) {
                    Log.w(TAG, "check failed", error)
                } finally {
                    onFinished()
                }
            }, "HighRiskCallCheck").start()
        } catch (error: Throwable) {
            Log.w(TAG, "could not start check", error)
            onFinished()
        }
    }

    /** True while MainActivity is visible; the Dart UI shows its own alert then. */
    @Volatile
    var appInForeground: Boolean = false

    /** Removes the warning but keeps the call marked as handled. */
    fun dismiss() {
        mainHandler.post { HighRiskCallActivity.dismiss() }
    }

    /** Call ended: forget the number and remove any visible warning. */
    fun reset() {
        synchronized(lock) { currentKey = null }
        mainHandler.post { HighRiskCallActivity.dismiss() }
    }

    private fun check(context: Context, number: String?) {
        val raw = number ?: return
        val key = SpamStore.canonical(raw)
        if (key.isEmpty() || appInForeground) return
        val baseUrl = apiBaseUrl(context) ?: return

        synchronized(lock) {
            if (currentKey == key) return
            currentKey = key
        }

        val trust = try {
            fetch(baseUrl, raw)
        } catch (error: Exception) {
            Log.w(TAG, "trust-score lookup failed", error)
            null
        }

        if (trust == null) {
            // Let a repeated ringing broadcast retry the lookup.
            synchronized(lock) { if (currentKey == key) currentKey = null }
            return
        }
        if (trust.rating != RATING_HIGH_RISK) return

        mainHandler.post {
            // The call may have ended while the request was in flight.
            val stillActive = synchronized(lock) { currentKey == key }
            if (stillActive) {
                // System-mediated fallback for ROMs that block a direct
                // background activity start (full-screen intent), plus the
                // direct start which is instant when it is allowed.
                NotificationHelper.escalateIncomingCall(
                    context,
                    raw,
                    null,
                    trust.score,
                    trust.reportCount,
                )
                HighRiskCallActivity.show(context, raw, trust.score, trust.reportCount)
            }
        }
    }

    private fun apiBaseUrl(context: Context): String? =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_API_BASE_URL, null)
            ?.trimEnd('/')
            ?.takeIf { it.isNotEmpty() }

    private fun fetch(baseUrl: String, number: String): TrustScore? {
        val query = URLEncoder.encode(number, "UTF-8")
        val url = URL("$baseUrl/detection/phone-number/trust-score?phone_number=$query")
        val connection = url.openConnection() as HttpURLConnection
        try {
            connection.requestMethod = "GET"
            connection.connectTimeout = TIMEOUT_MS
            connection.readTimeout = TIMEOUT_MS
            connection.setRequestProperty("Accept", "application/json")
            if (connection.responseCode !in 200..299) return null
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(body)
            return TrustScore(
                rating = json.optString("rating", "unknown"),
                score = if (json.has("trust_score")) json.optInt("trust_score") else null,
                reportCount = json.optInt("report_count", 0),
            )
        } finally {
            connection.disconnect()
        }
    }
}
