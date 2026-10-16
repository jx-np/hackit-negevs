package com.scamwatch.negavsinparis

import android.Manifest
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var deeplinkChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestListenerRebind()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        deeplinkChannel?.let { deliverDeeplink(intent, it) }
    }

    private fun deliverDeeplink(intent: Intent?, channel: MethodChannel) {
        val subject = intent?.getStringExtra(NotificationHelper.EXTRA_REPORT_SUBJECT) ?: return
        val source = intent.getStringExtra(NotificationHelper.EXTRA_REPORT_SOURCE) ?: "call"
        val content = intent.getStringExtra(NotificationHelper.EXTRA_REPORT_CONTENT) ?: ""
        val app = intent.getStringExtra(NotificationHelper.EXTRA_REPORT_APP) ?: ""
        val key = intent.getStringExtra(NotificationHelper.EXTRA_REPORT_KEY) ?: ""
        channel.invokeMethod("openReport", mapOf(
            "subject" to subject,
            "content" to content,
            "source" to source,
            "app" to app,
            "notificationKey" to key,
        ))
    }

    /**
     * Reinstalling the APK leaves the notification listener enabled but
     * unbound, so no notifications are delivered until the user re-toggles
     * notification access (or reboots). Asking the system to rebind on launch
     * makes detection recover on its own.
     */
    private fun requestListenerRebind() {
        ScamNotificationListener.rebind(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        NotificationHelper.ensureChannels(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isCallScreening" -> result.success(isCallScreening())
                    "requestCallScreening" ->
                        result.success(requestRole(RoleManager.ROLE_CALL_SCREENING))
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    CallEvents.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    CallEvents.attach(null)
                }
            })

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCAM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isServiceRunning" -> result.success(ScamShieldEngineHolder.isRunning)
                    "startService" -> {
                        startScamShieldService()
                        result.success(null)
                    }
                    "stopService" -> {
                        stopService(Intent(this, ScamShieldService::class.java))
                        result.success(null)
                    }
                    "hasOverlayPermission" -> result.success(Settings.canDrawOverlays(this))
                    "requestOverlayPermission" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName"),
                            )
                        )
                        result.success(null)
                    }
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "rebindNotificationListener" -> {
                        requestListenerRebind()
                        result.success(null)
                    }
                    "hasNotificationPermission" -> result.success(hasNotificationPermission())
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(null)
                    }
                    "getStatus" ->
                        ScamShieldEngineHolder.control("status", null) { result.success(it) }
                    "warmUpModel" ->
                        ScamShieldEngineHolder.control("warmUp", null) { result.success(it) }
                    "syncSettings" ->
                        ScamShieldEngineHolder.control("syncSettings", null) { result.success(it) }
                    "setShieldEnabled" -> {
                        SpamStore.setShieldEnabled(
                            this,
                            call.argument<Boolean>("enabled") ?: false,
                        )
                        result.success(null)
                    }
                    "testEvaluate" ->
                        ScamShieldEngineHolder.control("testEvaluate", call.arguments) {
                            result.success(it)
                        }
                    "dismissScamAlert" -> {
                        ScamOverlayController.hide()
                        NotificationHelper.cancelScamAlert(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STORAGE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getPublicDownloadsDir" -> result.success(PublicStorage.downloadsDir())
                    "getAppModelsDir" -> result.success(PublicStorage.appModelsDir(this))
                    else -> result.notImplemented()
                }
            }

        deeplinkChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEEPLINK_CHANNEL,
        )
        deliverDeeplink(intent, deeplinkChannel!!)
    }

    private fun startScamShieldService() {
        val intent = Intent(this, ScamShieldService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.POST_NOTIFICATIONS,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (hasNotificationPermission()) return
        requestPermissions(
            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
            NOTIFICATION_REQUEST_CODE,
        )
    }

    private fun isCallScreening(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val rm = getSystemService(Context.ROLE_SERVICE) as RoleManager
            rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
        } else {
            false
        }
    } catch (e: Exception) {
        false
    }

    private fun requestRole(role: String): Boolean = try {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            false
        } else {
            val rm = getSystemService(Context.ROLE_SERVICE) as RoleManager
            when {
                !rm.isRoleAvailable(role) -> false
                rm.isRoleHeld(role) -> true
                else -> {
                    startActivityForResult(
                        rm.createRequestRoleIntent(role),
                        ROLE_REQUEST_CODE
                    )
                    true
                }
            }
        }
    } catch (e: Exception) {
        false
    }

    companion object {
        private const val CHANNEL = "com.scamwatch.negavsinparis/roles"
        private const val EVENTS_CHANNEL = "com.scamwatch.negavsinparis/call_events"
        private const val SCAM_CHANNEL = "scamshield/ui"
        private const val STORAGE_CHANNEL = "scamshield/storage"
        private const val DEEPLINK_CHANNEL = "report/deeplink"
        private const val ROLE_REQUEST_CODE = 12001
        private const val NOTIFICATION_REQUEST_CODE = 7717
    }
}
