package com.scamwatch.negavsinparis

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder

/**
 * Full-screen warning drawn over whatever is on screen when a ringing number is
 * rated `high_risk` by the trust-score API.
 *
 * Everything here is native on purpose: it is triggered by the phone-state
 * receiver / call-screening service, which run with the Flutter UI closed, so
 * it cannot depend on a Dart engine. The API base URL is mirrored into shared
 * preferences by `main()` (key `api_base_url`). The trust-score endpoint allows
 * anonymous access, so no token is needed.
 */
object HighRiskCallOverlay {

    private const val TAG = "HighRiskCallOverlay"
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_API_BASE_URL = "flutter.api_base_url"
    private const val RATING_HIGH_RISK = "high_risk"
    private const val TIMEOUT_MS = 6000
    private const val BACKGROUND_COLOR = "#C74747"

    private data class TrustScore(val rating: String, val score: Int?, val reportCount: Int)

    private val mainHandler = Handler(Looper.getMainLooper())
    private val lock = Any()

    /** Canonical number of the call being handled; guards against duplicate alerts. */
    private var currentKey: String? = null

    // Only touched on the main thread.
    private var rootView: View? = null
    private var windowManager: WindowManager? = null

    /**
     * Looks the number up off the main thread and shows the overlay when it is
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
        mainHandler.post { hide() }
    }

    /** Call ended: forget the number and remove any visible warning. */
    fun reset() {
        synchronized(lock) { currentKey = null }
        mainHandler.post { hide() }
    }

    private fun check(context: Context, number: String?) {
        val raw = number ?: return
        val key = SpamStore.canonical(raw)
        if (key.isEmpty() || appInForeground || !Settings.canDrawOverlays(context)) return
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
            if (stillActive) show(context, raw, trust)
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

    private fun show(context: Context, number: String, trust: TrustScore) {
        hide()
        val manager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        val density = context.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        fun label(text: String, size: Float, bold: Boolean, alpha: Int = 255) =
            TextView(context).apply {
                this.text = text
                textSize = size
                gravity = Gravity.CENTER
                setTextColor(Color.argb(alpha, 255, 255, 255))
                if (bold) setTypeface(typeface, Typeface.BOLD)
            }

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(56), dp(24), dp(32))
        }

        content.addView(
            TextView(context).apply {
                text = "⚠"
                textSize = 56f
                gravity = Gravity.CENTER
                setTextColor(Color.WHITE)
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(Color.argb(41, 255, 255, 255))
                }
            },
            LinearLayout.LayoutParams(dp(112), dp(112)),
        )

        content.addView(
            label("Likely scam call", 28f, bold = true),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(24) },
        )

        content.addView(
            label(
                "People reported this number as a scam. Don't share money or personal details.",
                17f,
                bold = false,
                alpha = 235,
            ),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(12) },
        )

        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(20), dp(12), dp(20), dp(12))
            background = GradientDrawable().apply {
                cornerRadius = dp(16).toFloat()
                setColor(Color.argb(36, 255, 255, 255))
            }
        }
        panel.addView(
            label(number, 24f, bold = true),
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )
        trust.score?.let {
            panel.addView(
                label("Score: $it/100", 17f, bold = true, alpha = 235),
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = dp(4) },
            )
        }
        if (trust.reportCount > 0) {
            panel.addView(
                label("${trust.reportCount} reports", 17f, bold = true, alpha = 235),
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = dp(4) },
            )
        }
        content.addView(
            panel,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(24) },
        )

        content.addView(
            Button(context).apply {
                text = "This is a Scam – Block"
                isAllCaps = false
                textSize = 18f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(Color.parseColor(BACKGROUND_COLOR))
                minHeight = dp(72)
                minimumHeight = dp(72)
                background = GradientDrawable().apply {
                    cornerRadius = dp(16).toFloat()
                    setColor(Color.WHITE)
                }
                setOnClickListener {
                    SpamStore.block(context, number)
                    hide()
                    Toast.makeText(context, "Blocked $number", Toast.LENGTH_LONG).show()
                }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(32) },
        )

        content.addView(
            Button(context).apply {
                text = "It's Safe / Dismiss"
                isAllCaps = false
                textSize = 16f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(Color.WHITE)
                minHeight = dp(64)
                minimumHeight = dp(64)
                background = GradientDrawable().apply {
                    cornerRadius = dp(16).toFloat()
                    setColor(Color.TRANSPARENT)
                    setStroke(dp(2), Color.WHITE)
                }
                setOnClickListener { hide() }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(12) },
        )

        val root = ScrollView(context).apply {
            isFillViewport = true
            setBackgroundColor(Color.parseColor(BACKGROUND_COLOR))
            addView(
                content,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        )

        try {
            manager.addView(root, params)
            rootView = root
            windowManager = manager
        } catch (error: Exception) {
            rootView = null
            Log.w(TAG, "overlay failed", error)
        }
    }

    private fun hide() {
        val view = rootView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
        }
        rootView = null
    }
}
