package com.example.call_log_app

import android.app.role.RoleManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

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
        private const val CHANNEL = "com.example.call_log_app/roles"
        private const val EVENTS_CHANNEL = "com.example.call_log_app/call_events"
        private const val ROLE_REQUEST_CODE = 12001
    }
}
