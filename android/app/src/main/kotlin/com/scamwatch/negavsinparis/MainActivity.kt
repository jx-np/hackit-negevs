package com.scamwatch.negavsinparis

import android.Manifest
import android.app.ActivityManager
import android.app.NotificationManager
import android.app.role.RoleManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.PowerManager
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

    override fun onResume() {
        super.onResume()
        HighRiskCallOverlay.appInForeground = true
        HighRiskCallOverlay.dismiss()
    }

    override fun onPause() {
        HighRiskCallOverlay.appInForeground = false
        super.onPause()
    }

    override fun onDestroy() {
        // The process can outlive the activity (background Flutter engine), so
        // never leave the flag stuck true after the UI goes away.
        HighRiskCallOverlay.appInForeground = false
        super.onDestroy()
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
                    "hasFullScreenIntent" -> result.success(hasFullScreenIntent())
                    "requestFullScreenIntent" -> {
                        requestFullScreenIntent()
                        result.success(null)
                    }
                    "openNotificationAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "hasAllFilesAccess" -> result.success(hasAllFilesAccess())
                    "requestAllFilesAccess" -> {
                        requestAllFilesAccess()
                        result.success(null)
                    }
                    "hasIgnoreBatteryOptimizations" ->
                        result.success(hasIgnoreBatteryOptimizations())
                    "requestIgnoreBatteryOptimizations" -> {
                        requestIgnoreBatteryOptimizations()
                        result.success(null)
                    }
                    "openBatteryOptimizationSettings" -> {
                        openBatteryOptimizationSettings()
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
                        ScamAlertActivity.dismiss()
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
                    "getScanRoots" -> result.success(PublicStorage.scanRoots())
                    "getDeviceTotalRamBytes" -> result.success(deviceTotalRamBytes())
                    "isOnMeteredConnection" -> result.success(isOnMeteredConnection())
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

    /**
     * True when the app holds "All files access" (MANAGE_EXTERNAL_STORAGE).
     * Below Android 11 there is no scoped-storage manager concept, so broad
     * read access is governed by the legacy storage permission and this
     * returns true. The permission itself is only declared in the debug
     * manifest, so this is always false in release builds.
     */
    private fun hasAllFilesAccess(): Boolean =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }

    /**
     * Sends the user to the system "All files access" screen for this app.
     * There is no runtime-dialog path for MANAGE_EXTERNAL_STORAGE; it can only
     * be granted from Settings. Falls back to the global list screen if the
     * per-app intent is unavailable on the device.
     */
    private fun requestAllFilesAccess() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        if (hasAllFilesAccess()) return
        try {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName"),
                )
            )
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
        }
    }

    /**
     * True when the app may launch full-screen intents. Since Android 14 the
     * system only allows this for calling/alarm apps by default, so the
     * full-screen fallback shown for locked-screen scam alerts silently
     * degrades to a heads-up notification until the user grants it. Below
     * Android 14 no such permission exists, so this returns true.
     */
    private fun hasFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return true
        return try {
            getSystemService(NotificationManager::class.java)?.canUseFullScreenIntent() == true
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Sends the user to the system "Full screen notifications" screen for this
     * app. There is no runtime-dialog path for this permission. No-op below
     * Android 14 or when the permission is already held.
     */
    private fun requestFullScreenIntent() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        if (hasFullScreenIntent()) return
        try {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                    Uri.parse("package:$packageName"),
                )
            )
        } catch (e: Exception) {
            Log.w("MainActivity", "full-screen intent settings unavailable", e)
        }
    }

    /**
     * True when the app is exempt from battery optimization (Doze). Without
     * this exemption the system aggressively stops the background foreground
     * service, so on-device scam screening silently dies after a while. Below
     * Android M there is no Doze, so this returns true.
     */
    private fun hasIgnoreBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        return try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pm.isIgnoringBatteryOptimizations(packageName)
        } catch (e: Exception) {
            false
        }
    }

    /**
     * Asks the user to exempt the app from battery optimization. Uses the
     * direct exemption dialog (ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS),
     * which shows a single Allow/Deny prompt. Falls back to the system battery-
     * optimization list screen if the direct intent is unavailable. No-op below
     * Android M or when the exemption is already held.
     */
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (hasIgnoreBatteryOptimizations()) return
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                    Uri.parse("package:$packageName"),
                )
            )
        } catch (e: Exception) {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        }
    }

    /**
     * Opens the full system battery-optimization list (every app, where the
     * user picks this app and sets it to "Don't optimize"). This is the manual
     * route for aggressive OEM ROMs that ignore or never show the direct
     * one-tap exemption dialog. Falls back to this app's details screen if the
     * list intent is unavailable. No-op below Android M (no Doze).
     */
    private fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        try {
            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
        } catch (e: Exception) {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:$packageName"),
                )
            )
        }
    }

    /**
     * Total physical RAM in bytes, read from [ActivityManager.MemoryInfo.totalMem].
     * The kernel reserves a slice for itself, so this value is always a little
     * below the nominal spec (an "8 GB" phone typically reports ~7.3-7.8 GB).
     * The caller compensates with a tolerance when comparing against the 8 GB
     * threshold. Returns 0 when the value cannot be read, which the Dart side
     * treats as "assume small model".
     */
    private fun deviceTotalRamBytes(): Long = try {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = ActivityManager.MemoryInfo()
        am.getMemoryInfo(info)
        info.totalMem
    } catch (e: Exception) {
        0L
    }

    /**
     * True when the active network is metered (mobile data, metered Wi-Fi/hotspot).
     * Uses [ConnectivityManager.isActiveNetworkMetered], which already accounts
     * for user-flagged metered Wi-Fi. Returns false when it cannot be read so a
     * read failure never blocks a download behind a warning dialog.
     */
    private fun isOnMeteredConnection(): Boolean = try {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        cm.isActiveNetworkMetered
    } catch (e: Exception) {
        false
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
