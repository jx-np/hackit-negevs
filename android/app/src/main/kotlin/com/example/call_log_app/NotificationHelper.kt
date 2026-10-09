package com.example.call_log_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

object NotificationHelper {

    const val INCOMING_CHANNEL_ID = "incoming_calls_v3"
    const val POST_CALL_CHANNEL_ID = "post_call_report_v1"
    const val SCAM_ALERT_CHANNEL_ID = "scam_alert_v1"
    private const val NOTIFICATION_ID_INCOMING = 1001
    private const val NOTIFICATION_ID_POST_CALL = 1002
    private const val NOTIFICATION_ID_SCAM_ALERT = 1003
    private const val TAG = "NotificationHelper"

    const val EXTRA_REPORT_SUBJECT = "report_subject"
    const val EXTRA_REPORT_CONTENT = "report_content"
    const val EXTRA_REPORT_SOURCE = "report_source"
    const val EXTRA_REPORT_APP = "report_app"
    const val EXTRA_REPORT_KEY = "report_notification_key"

    private fun notificationManager(context: Context): NotificationManager? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            context.getSystemService(NotificationManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        }

    fun ensureChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = notificationManager(context) ?: return
        mgr.deleteNotificationChannel("incoming_calls")
        mgr.deleteNotificationChannel("incoming_calls_v2")
        val channel = NotificationChannel(
            INCOMING_CHANNEL_ID,
            "Incoming calls",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Shown while someone is calling (silent)"
            setSound(null, null)
            enableVibration(false)
            setShowBadge(false)
        }
        mgr.createNotificationChannel(channel)
    }

    fun showIncomingCall(context: Context, number: String?, name: String?) {
        ensureChannels(context)

        val intent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val contentIntent = PendingIntent.getActivity(context, 0, intent, piFlags)

        val title = name?.takeIf { it.isNotBlank() } ?: "Incoming call"
        val text = number?.takeIf { it.isNotBlank() } ?: "Unknown number"

        val builder: Notification.Builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, INCOMING_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

        builder
            .setSmallIcon(R.drawable.ic_call_notification)
            .setContentTitle(title)
            .setContentText(text)
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(contentIntent)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            @Suppress("DEPRECATION")
            builder.setPriority(Notification.PRIORITY_HIGH)
        }

        try {
            notificationManager(context)?.notify(NOTIFICATION_ID_INCOMING, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing POST_NOTIFICATIONS permission", e)
        }
    }

    fun cancelIncomingCall(context: Context) {
        notificationManager(context)?.cancel(NOTIFICATION_ID_INCOMING)
    }

    fun cancelScamAlert(context: Context) {
        notificationManager(context)?.cancel(NOTIFICATION_ID_SCAM_ALERT)
    }

    fun showScamAlert(
        context: Context,
        sender: String,
        headline: String,
        message: String,
        confidence: Double,
        appLabel: String,
        notificationKey: String?,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = notificationManager(context) ?: return
            val channel = NotificationChannel(
                SCAM_ALERT_CHANNEL_ID,
                "Scam alerts",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "Fires when a message is detected as a scam"
            }
            mgr.createNotificationChannel(channel)
        }

        val reportIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_REPORT_SUBJECT, sender)
            putExtra(EXTRA_REPORT_CONTENT, message)
            putExtra(EXTRA_REPORT_SOURCE, "notification")
            putExtra(EXTRA_REPORT_APP, appLabel)
            if (!notificationKey.isNullOrEmpty()) {
                putExtra(EXTRA_REPORT_KEY, notificationKey)
            }
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val reportPending = PendingIntent.getActivity(context, 1003, reportIntent, piFlags)

        val builder: Notification.Builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, SCAM_ALERT_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

        builder
            .setSmallIcon(R.drawable.ic_call_notification)
            .setContentTitle(headline)
            .setContentText("$sender · ${message.take(80)}")
            .setStyle(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    Notification.BigTextStyle().bigText(
                        "$sender · ${(confidence * 100).toInt()}% confidence\n$message",
                    )
                } else {
                    null
                },
            )
            .setAutoCancel(true)
            .setContentIntent(reportPending)
            .addAction(0, "Report as scam", reportPending)

        try {
            notificationManager(context)?.notify(NOTIFICATION_ID_SCAM_ALERT, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing POST_NOTIFICATIONS permission", e)
        }
    }

    fun showPostCallReport(context: Context, number: String?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val mgr = notificationManager(context) ?: return
            val channel = NotificationChannel(
                POST_CALL_CHANNEL_ID,
                "Report a call",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = "Asks whether the last call should be reported"
            }
            mgr.createNotificationChannel(channel)
        }

        val display = number?.takeIf { it.isNotBlank() } ?: "Unknown number"

        val reportIntent = Intent(context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            putExtra(EXTRA_REPORT_SUBJECT, display)
            putExtra(EXTRA_REPORT_SOURCE, "call")
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val reportPending = PendingIntent.getActivity(context, 1002, reportIntent, piFlags)

        val builder: Notification.Builder =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, POST_CALL_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }

        builder
            .setSmallIcon(R.drawable.ic_call_notification)
            .setContentTitle("Report $display?")
            .setContentText("Mark the call as spam, scam or other if it bothered you.")
            .setAutoCancel(true)
            .setContentIntent(reportPending)
            .addAction(
                0,
                "Report",
                reportPending,
            )

        try {
            notificationManager(context)?.notify(NOTIFICATION_ID_POST_CALL, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing POST_NOTIFICATIONS permission", e)
        }
    }
}
