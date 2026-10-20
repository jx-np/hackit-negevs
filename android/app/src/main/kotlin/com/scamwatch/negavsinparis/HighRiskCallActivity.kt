package com.scamwatch.negavsinparis

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import android.widget.Toast

/**
 * Full-screen native warning for an incoming call whose number is rated
 * `high_risk` by the trust-score API.
 *
 * This is an Activity rather than a `TYPE_APPLICATION_OVERLAY` window on
 * purpose. Android hides application overlays while the keyguard is showing,
 * which is exactly when most calls arrive. An Activity with
 * [setShowWhenLocked] + [setTurnScreenOn] is displayed over the lock screen
 * and over the system in-call UI, and it works even when the Flutter UI is
 * closed.
 */
class HighRiskCallActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.statusBarColor = Color.parseColor(BACKGROUND_COLOR)
        window.navigationBarColor = Color.parseColor(BACKGROUND_COLOR)
        current = this
        render()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        render()
    }

    override fun onDestroy() {
        if (current === this) current = null
        super.onDestroy()
    }

    private fun render() {
        val number = intent.getStringExtra(EXTRA_NUMBER)
        if (number.isNullOrBlank()) {
            finish()
            return
        }
        val score = if (intent.hasExtra(EXTRA_SCORE)) {
            intent.getIntExtra(EXTRA_SCORE, 0)
        } else {
            null
        }
        val reportCount = intent.getIntExtra(EXTRA_REPORT_COUNT, 0)

        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        fun label(text: String, size: Float, bold: Boolean, alpha: Int = 255) =
            TextView(this).apply {
                this.text = text
                textSize = size
                gravity = Gravity.CENTER
                setTextColor(Color.argb(alpha, 255, 255, 255))
                if (bold) setTypeface(typeface, Typeface.BOLD)
            }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(24), dp(56), dp(24), dp(32))
        }

        content.addView(
            TextView(this).apply {
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

        val panel = LinearLayout(this).apply {
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
        if (score != null) {
            panel.addView(
                label("Score: $score/100", 17f, bold = true, alpha = 235),
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ).apply { topMargin = dp(4) },
            )
        }
        if (reportCount > 0) {
            panel.addView(
                label("$reportCount reports", 17f, bold = true, alpha = 235),
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
            Button(this).apply {
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
                setOnClickListener { block(number) }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(32) },
        )

        content.addView(
            Button(this).apply {
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
                setOnClickListener { finish() }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(12) },
        )

        val root = ScrollView(this).apply {
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

        setContentView(root)
    }

    private fun block(number: String) {
        SpamStore.block(this, number)
        Toast.makeText(this, "Blocked $number", Toast.LENGTH_LONG).show()
        finish()
    }

    companion object {
        private const val TAG = "HighRiskCallActivity"
        private const val BACKGROUND_COLOR = "#C74747"
        private const val EXTRA_NUMBER = "number"
        private const val EXTRA_SCORE = "score"
        private const val EXTRA_REPORT_COUNT = "report_count"

        @Volatile
        private var current: HighRiskCallActivity? = null

        /** Intent used both for the direct start and the notification fallback. */
        fun buildIntent(
            context: Context,
            number: String?,
            score: Int? = null,
            reportCount: Int = 0,
        ): Intent {
            return Intent(context, HighRiskCallActivity::class.java).apply {
                addFlags(
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP,
                )
                putExtra(EXTRA_NUMBER, number)
                if (score != null) putExtra(EXTRA_SCORE, score)
                putExtra(EXTRA_REPORT_COUNT, reportCount)
            }
        }

        /**
         * Shows the warning. The app holds `SYSTEM_ALERT_WINDOW`, which is an
         * allowed exemption from the background activity-start restriction, so
         * this works from the phone-state receiver / call-screening service
         * with the Flutter UI closed.
         */
        fun show(context: Context, number: String, score: Int?, reportCount: Int) {
            val intent = buildIntent(context, number, score, reportCount)
            try {
                context.startActivity(intent)
            } catch (error: Exception) {
                Log.w(TAG, "could not show call alert", error)
            }
        }

        /** Called when the call is answered or ends, and when the app opens. */
        fun dismiss() {
            val activity = current ?: return
            activity.runOnUiThread {
                if (!activity.isFinishing) activity.finish()
            }
        }
    }
}
