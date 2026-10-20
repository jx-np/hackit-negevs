package com.scamwatch.negavsinparis

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.PowerManager
import android.util.Log
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
            // The engine survives a service restart, so the MethodChannel (and
            // the handler bound to the destroyed service instance) is still
            // alive. Re-bind it to this instance or showAlert() would keep
            // talking to a dead service.
            ScamShieldEngineHolder.nativeChannel?.let { registerNativeHandler(it) }
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
        registerNativeHandler(nativeChannel)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "scamshield/storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPublicDownloadsDir" -> result.success(PublicStorage.downloadsDir())
                "getAppModelsDir" -> result.success(PublicStorage.appModelsDir(this))
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

    private fun registerNativeHandler(channel: MethodChannel) {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "showAlert" -> {
                    showAlert(call.arguments as? Map<*, *>)
                    result.success(null)
                }
                "dismissAlert" -> {
                    ScamAlertActivity.dismiss()
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
    }

    override fun onDestroy() {
        ScamAlertActivity.dismiss()
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
        try {
            val appLabel = arguments["appLabel"] as? String ?: "Unknown app"
            val headline = arguments["headline"] as? String ?: "Possible scam"
            val message = arguments["message"] as? String ?: ""
            val confidence = (arguments["confidence"] as? Number)?.toDouble() ?: 0.0
            val sender = (arguments["sender"] as? String)?.takeIf { it.isNotBlank() } ?: appLabel
            val notificationKey = arguments["notificationKey"] as? String
            val logId = arguments["logId"] as? String
            val reason = arguments["reason"] as? String ?: ""
            val escalated = arguments["escalated"] as? Boolean ?: false
            // `text` is the notification text alone. Older callers only send
            // `message` (sender + text), so fall back to it when `text` is absent.
            val text = (arguments["text"] as? String)?.takeIf { it.isNotBlank() } ?: message

            Log.i(TAG, "showAlert label=$headline confidence=$confidence key=$notificationKey")
            NotificationHelper.showScamAlert(
                this,
                sender,
                headline,
                message,
                confidence,
                appLabel,
                notificationKey,
                text,
                reason,
                escalated,
                logId,
            )
            // Full-screen native warning. It is an Activity (not an overlay
            // window) so it is visible over the lock screen and over whatever
            // app the user is currently in. The notification above is the
            // fallback when background activity starts are restricted.
            ScamAlertActivity.show(
                context = this,
                headline = headline,
                sender = sender,
                appLabel = appLabel,
                bodyText = text,
                message = message,
                reason = reason,
                confidence = confidence,
                notificationKey = notificationKey,
                escalated = escalated,
                logId = logId,
            )
        } catch (error: Exception) {
            // Never let the alert break the method channel: a lost result
            // would leave the Dart caller waiting forever and stall the
            // evaluation queue.
            Log.w(TAG, "showAlert failed", error)
        }
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
