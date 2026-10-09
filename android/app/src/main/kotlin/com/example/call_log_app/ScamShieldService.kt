package com.example.call_log_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.service.notification.NotificationListenerService
import android.util.Log
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class ScamShieldService : Service() {
    private var engine: FlutterEngine? = null
    private var notificationManager: NotificationManager? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onBind(intent: Intent?): android.os.IBinder? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        startForegroundInternal("ScamShield is starting")
        requestListenerRebind()

        val existing = ScamShieldEngineHolder.engine
        if (existing != null) {
            engine = existing
            ScamShieldEngineHolder.serviceRunning = true
            ScamShieldEngineHolder.control("start", null) {}
            return
        }

        val flutterEngine = FlutterEngine(this)
        val loader = FlutterInjector.instance().flutterLoader()
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "backgroundMain"),
        )

        val nativeChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scamshield/native",
        )
        nativeChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showAlert" -> {
                    showAlert(call.arguments as? Map<*, *>)
                    result.success(null)
                }
                "dismissAlert" -> {
                    ScamOverlayController.hide()
                    NotificationHelper.cancelScamAlert(this)
                    result.success(null)
                }
                "updateStatus" -> {
                    updateStatus(call.argument<String>("message").orEmpty())
                    result.success(null)
                }
                "acquireWakeLock" -> {
                    acquireWakeLock()
                    result.success(null)
                }
                "releaseWakeLock" -> {
                    releaseWakeLock()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scamshield/storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPublicDownloadsDir" -> result.success(PublicStorage.downloadsDir())
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scamshield/notifications",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                NotificationRelay.attach(events)
            }

            override fun onCancel(arguments: Any?) {
                NotificationRelay.attach(null)
            }
        })

        ScamShieldEngineHolder.engine = flutterEngine
        ScamShieldEngineHolder.nativeChannel = nativeChannel
        ScamShieldEngineHolder.controlChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scamshield/control",
        )
        engine = flutterEngine
        ScamShieldEngineHolder.serviceRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        ScamOverlayController.hide()
        NotificationRelay.attach(null)
        ScamShieldEngineHolder.serviceRunning = false
        // Keep the engine alive for reuse: destroying and recreating one that
        // loaded the LiteRT/MediaPipe runtime crashes the native side.
        ScamShieldEngineHolder.control("shutdown", null) {}
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
        engine = null
        super.onDestroy()
    }

    private fun requestListenerRebind() {
        ScamNotificationListener.rebind(this)
    }

    /**
     * Held only while a native generation is running. Without it the CPU can
     * suspend with the screen off, so an evaluation started for a notification
     * that briefly woke the device never finishes.
     */
    private fun acquireWakeLock() {
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        val lock = wakeLock ?: manager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "ScamShield:model",
        ).also {
            it.setReferenceCounted(true)
            wakeLock = it
        }
        if (!lock.isHeld) lock.acquire(WAKE_LOCK_TIMEOUT_MS)
    }

    private fun releaseWakeLock() {
        val lock = wakeLock ?: return
        if (lock.isHeld) lock.release()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Scam protection",
            NotificationManager.IMPORTANCE_LOW,
        )
        channel.description = "Keeps ScamShield running in the background"
        notificationManager?.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ScamShield")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun startForegroundInternal(text: String) {
        val notification = buildNotification(text)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    private fun updateStatus(message: String) {
        if (message.isEmpty()) return
        notificationManager?.notify(NOTIFICATION_ID, buildNotification(message))
    }

    private fun showAlert(arguments: Map<*, *>?) {
        if (arguments == null) return
        val appLabel = arguments["appLabel"] as? String ?: "Unknown app"
        val headline = arguments["headline"] as? String ?: "Possible scam"
        val message = arguments["message"] as? String ?: ""
        val confidence = (arguments["confidence"] as? Number)?.toDouble() ?: 0.0
        val sender = (arguments["sender"] as? String)?.takeIf { it.isNotBlank() } ?: appLabel
        val notificationKey = arguments["notificationKey"] as? String
        NotificationHelper.showScamAlert(
            this,
            sender,
            headline,
            message,
            confidence,
            appLabel,
            notificationKey,
        )
        if (!Settings.canDrawOverlays(this)) {
            updateStatus("Overlay permission missing")
            return
        }
        val overlayError = ScamOverlayController.show(
            context = this,
            appLabel = appLabel,
            sender = sender,
            notificationKey = notificationKey,
            headline = headline,
            message = message,
            reason = arguments["reason"] as? String ?: "",
            confidence = confidence,
            escalated = arguments["escalated"] as? Boolean ?: false,
        )
        if (overlayError != null) updateStatus(overlayError)
    }

    companion object {
        private const val CHANNEL_ID = "scamshield_service"
        private const val NOTIFICATION_ID = 4201
        private const val WAKE_LOCK_TIMEOUT_MS = 3 * 60 * 1000L
        private const val TAG = "ScamShieldService"

        fun start(context: Context) {
            val intent = Intent(context, ScamShieldService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (error: Exception) {
                Log.w(TAG, "could not start service", error)
            }
        }
    }
}

object ScamOverlayController {
    private var rootView: View? = null
    private var windowManager: WindowManager? = null

    fun show(
        context: Context,
        appLabel: String,
        sender: String,
        notificationKey: String?,
        headline: String,
        message: String,
        reason: String,
        confidence: Double,
        escalated: Boolean,
    ): String? {
        hide()
        val manager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        windowManager = manager

        val density = context.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(24))
            gravity = Gravity.CENTER
            setBackgroundColor(Color.parseColor("#E6000000"))
        }

        val screenHeight = context.resources.displayMetrics.heightPixels
        val maxBodyHeight = (screenHeight - dp(260))
            .coerceAtMost((screenHeight * 0.7).toInt())
            .coerceAtLeast(dp(96))

        val card = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(16))
            background = GradientDrawable().apply {
                cornerRadius = dp(20).toFloat()
                setColor(Color.WHITE)
            }
        }

        card.addView(TextView(context).apply {
            text = "⚠ Possible scam"
            textSize = 24f
            setTextColor(Color.parseColor("#B00020"))
            setTypeface(typeface, Typeface.BOLD)
        })

        card.addView(TextView(context).apply {
            text = headline
            textSize = 18f
            setTextColor(Color.parseColor("#111111"))
            setPadding(0, dp(8), 0, 0)
        })

        card.addView(TextView(context).apply {
            text = "$appLabel  ·  ${(confidence * 100).toInt()}% confidence" +
                if (escalated) "  ·  checked online" else ""
            textSize = 13f
            setTextColor(Color.parseColor("#666666"))
            setPadding(0, dp(4), 0, 0)
        })

        val scrollBody = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
        }

        if (message.isNotEmpty()) {
            scrollBody.addView(TextView(context).apply {
                text = message
                textSize = 15f
                setTextColor(Color.parseColor("#333333"))
                setPadding(0, dp(12), 0, 0)
            })
        }

        if (reason.isNotEmpty()) {
            scrollBody.addView(TextView(context).apply {
                text = "Why: $reason"
                textSize = 14f
                setTextColor(Color.parseColor("#555555"))
                setPadding(0, dp(12), 0, 0)
            })
        }

        card.addView(
            MaxHeightScrollView(context, maxBodyHeight).apply {
                addView(
                    scrollBody,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.WRAP_CONTENT,
                    ),
                )
            },
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ),
        )

        card.addView(Button(context).apply {
            text = "Report as scam"
            setOnClickListener {
                hide()
                val intent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    putExtra(NotificationHelper.EXTRA_REPORT_SUBJECT, sender)
                    putExtra(NotificationHelper.EXTRA_REPORT_CONTENT, message)
                    putExtra(NotificationHelper.EXTRA_REPORT_SOURCE, "notification")
                    putExtra(NotificationHelper.EXTRA_REPORT_APP, appLabel)
                    if (!notificationKey.isNullOrEmpty()) {
                        putExtra(NotificationHelper.EXTRA_REPORT_KEY, notificationKey)
                    }
                }
                context.startActivity(intent)
            }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(16) })

        card.addView(Button(context).apply {
            text = "Dismiss"
            setOnClickListener { hide() }
        }, LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT,
        ).apply { topMargin = dp(8) })

        container.addView(
            card,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                leftMargin = dp(16)
                rightMargin = dp(16)
            },
        )

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
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.CENTER
        }

        try {
            manager.addView(container, params)
            rootView = container
        } catch (error: Exception) {
            rootView = null
            Log.w("ScamShieldService", "overlay failed", error)
            return "Overlay failed: ${error.message}"
        }
        return null
    }

    fun hide() {
        val view = rootView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Exception) {
        }
        rootView = null
    }
}

private class MaxHeightScrollView(
    context: Context,
    private val maxHeightPx: Int,
) : ScrollView(context) {
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val capped = MeasureSpec.makeMeasureSpec(maxHeightPx, MeasureSpec.AT_MOST)
        super.onMeasure(widthMeasureSpec, capped)
    }
}
