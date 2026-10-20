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

/**
 * Full-screen native warning for a message the on-device model flagged as a
 * scam.
 *
 * This is an Activity rather than the previous `TYPE_APPLICATION_OVERLAY`
 * window because Android hides application overlays while the keyguard is
 * showing, and because a focusable overlay can fail to appear over other
 * apps' windows on some OEM ROMs. An Activity with [setShowWhenLocked] +
 * [setTurnScreenOn] is shown over the lock screen and over the current app,
 * and works even when the Flutter UI is closed.
 *
 * It is started directly by [ScamShieldService] and is also the target of the
 * full-screen intent on the scam notification, so the system can surface it
 * even when background activity starts are restricted.
 */
class ScamAlertActivity : Activity() {

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
        val headline = intent.getStringExtra(EXTRA_HEADLINE) ?: "Possible scam"
        val sender = intent.getStringExtra(EXTRA_SENDER).orEmpty()
        val appLabel = intent.getStringExtra(EXTRA_APP_LABEL).orEmpty()
        val bodyText = intent.getStringExtra(EXTRA_BODY_TEXT).orEmpty()
        val reason = intent.getStringExtra(EXTRA_REASON).orEmpty()
        val message = intent.getStringExtra(EXTRA_MESSAGE).orEmpty()
        val notificationKey = intent.getStringExtra(EXTRA_NOTIFICATION_KEY)
        val confidence = intent.getDoubleExtra(EXTRA_CONFIDENCE, 0.0)
        val escalated = intent.getBooleanExtra(EXTRA_ESCALATED, false)

        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val card = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(16))
            background = GradientDrawable().apply {
                cornerRadius = dp(20).toFloat()
                setColor(Color.WHITE)
            }
        }

        card.addView(
            TextView(this).apply {
                text = "⚠ $headline"
                textSize = 22f
                setTextColor(Color.parseColor("#B00020"))
                setTypeface(typeface, Typeface.BOLD)
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        val meta = buildString {
            append(appLabel)
            append("  ·  ")
            append((confidence * 100).toInt())
            append("% confidence")
            if (escalated) append("  ·  checked online")
        }
        card.addView(
            TextView(this).apply {
                text = meta
                textSize = 13f
                setTextColor(Color.parseColor("#666666"))
                setPadding(0, dp(4), 0, 0)
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        if (sender.isNotEmpty()) {
            card.addView(
                TextView(this).apply {
                    text = sender
                    textSize = 15f
                    setTextColor(Color.parseColor("#111111"))
                    setTypeface(typeface, Typeface.BOLD)
                    setPadding(0, dp(12), 0, 0)
                },
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
        }

        if (bodyText.isNotEmpty()) {
            card.addView(
                TextView(this).apply {
                    text = bodyText
                    textSize = 15f
                    setTextColor(Color.parseColor("#333333"))
                    setPadding(0, dp(4), 0, 0)
                },
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
        }

        if (reason.isNotEmpty()) {
            card.addView(
                TextView(this).apply {
                    text = "Why flagged: $reason"
                    textSize = 14f
                    setTextColor(Color.parseColor("#555555"))
                    setPadding(0, dp(6), 0, 0)
                },
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                ),
            )
        }

        card.addView(
            Button(this).apply {
                text = "Report as scam"
                isAllCaps = false
                textSize = 16f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(Color.WHITE)
                minHeight = dp(64)
                minimumHeight = dp(64)
                background = GradientDrawable().apply {
                    cornerRadius = dp(16).toFloat()
                    setColor(Color.parseColor("#B00020"))
                }
                setOnClickListener { report(headline, appLabel, message, reason, notificationKey) }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(20) },
        )

        card.addView(
            Button(this).apply {
                text = "Dismiss"
                isAllCaps = false
                textSize = 15f
                setTextColor(Color.parseColor("#333333"))
                minHeight = dp(56)
                minimumHeight = dp(56)
                background = GradientDrawable().apply {
                    cornerRadius = dp(16).toFloat()
                    setColor(Color.TRANSPARENT)
                    setStroke(dp(1), Color.parseColor("#999999"))
                }
                setOnClickListener { finish() }
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(10) },
        )

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(16), dp(48), dp(16), dp(32))
        }
        content.addView(
            card,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        setContentView(
            ScrollView(this).apply {
                isFillViewport = true
                setBackgroundColor(Color.parseColor(BACKGROUND_COLOR))
                addView(
                    content,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                    ),
                )
            },
        )
    }

    private fun report(
        headline: String,
        appLabel: String,
        message: String,
        reason: String,
        notificationKey: String?,
    ) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(NotificationHelper.EXTRA_REPORT_SUBJECT, reason.ifBlank { headline })
            putExtra(NotificationHelper.EXTRA_REPORT_CONTENT, buildString {
                append(message)
                if (headline.isNotEmpty()) {
                    append('\n')
                    append(headline)
                }
            })
            putExtra(NotificationHelper.EXTRA_REPORT_SOURCE, "notification")
            putExtra(NotificationHelper.EXTRA_REPORT_APP, appLabel)
            if (!notificationKey.isNullOrEmpty()) {
                putExtra(NotificationHelper.EXTRA_REPORT_KEY, notificationKey)
            }
        }
        startActivity(intent)
        finish()
    }

    companion object {
        private const val TAG = "ScamAlertActivity"
        private const val BACKGROUND_COLOR = "#E6000000"

        const val EXTRA_HEADLINE = "headline"
        const val EXTRA_SENDER = "sender"
        const val EXTRA_APP_LABEL = "app_label"
        const val EXTRA_BODY_TEXT = "body_text"
        const val EXTRA_MESSAGE = "message"
        const val EXTRA_REASON = "reason"
        const val EXTRA_CONFIDENCE = "confidence"
        const val EXTRA_NOTIFICATION_KEY = "notification_key"
        const val EXTRA_ESCALATED = "escalated"

        @Volatile
        private var current: ScamAlertActivity? = null

        /** Intent used both for the direct start and the notification fallback. */
        fun buildIntent(
            context: Context,
            headline: String,
            sender: String,
            appLabel: String,
            bodyText: String,
            message: String,
            reason: String,
            confidence: Double,
            notificationKey: String?,
            escalated: Boolean,
        ): Intent = Intent(context, ScamAlertActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP,
            )
            putExtra(EXTRA_HEADLINE, headline)
            putExtra(EXTRA_SENDER, sender)
            putExtra(EXTRA_APP_LABEL, appLabel)
            putExtra(EXTRA_BODY_TEXT, bodyText)
            putExtra(EXTRA_MESSAGE, message)
            putExtra(EXTRA_REASON, reason)
            putExtra(EXTRA_CONFIDENCE, confidence)
            if (!notificationKey.isNullOrEmpty()) putExtra(EXTRA_NOTIFICATION_KEY, notificationKey)
            putExtra(EXTRA_ESCALATED, escalated)
        }

        /**
         * Shows the warning. The app holds `SYSTEM_ALERT_WINDOW` when the user
         * allowed it, which is an allowed exemption from the background
         * activity-start restriction, so this works with the Flutter UI closed.
         */
        fun show(
            context: Context,
            headline: String,
            sender: String,
            appLabel: String,
            bodyText: String,
            message: String,
            reason: String,
            confidence: Double,
            notificationKey: String?,
            escalated: Boolean,
        ) {
            val intent = buildIntent(
                context,
                headline,
                sender,
                appLabel,
                bodyText,
                message,
                reason,
                confidence,
                notificationKey,
                escalated,
            )
            try {
                context.startActivity(intent)
            } catch (error: Exception) {
                Log.w(TAG, "could not show scam alert", error)
            }
        }

        /** Called from the UI engine when the user reports or dismisses it. */
        fun dismiss() {
            val activity = current ?: return
            activity.runOnUiThread {
                if (!activity.isFinishing) activity.finish()
            }
        }
    }
}
