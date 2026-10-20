package com.scamwatch.negavsinparis

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
    const val EXTRA_REPORT_ID = "report_log_id"

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
        postIncomingCall(context, number, name, fullScreen = false, score = null, reportCount = 0)
    }

    /**
     * Re-posts the incoming-call notification with a full-screen intent once
     * the number is confirmed high risk. This is the system-mediated fallback
     * for devices/ROMs that block a direct background activity start; the
     * notification itself stays the same.
     */
    fun escalateIncomingCall(
        context: Context,
        number: String?,
        name: String?,
        score: Int? = null,
        reportCount: Int = 0,
    ) {
        postIncomingCall(
            context,
            number,
            name,
            fullScreen = true,
            score = score,
            reportCount = reportCount,
        )
    }

    private fun postIncomingCall(
        context: Context,
        number: String?,
        name: String?,
        fullScreen: Boolean,
        score: Int?,
        reportCount: Int,
    ) {
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

        if (fullScreen) {
            val fullScreenIntent = HighRiskCallActivity.buildIntent(context, number, score, reportCount)
            val fullScreenPending =
                PendingIntent.getActivity(context, 1001, fullScreenIntent, piFlags)
            builder.setFullScreenIntent(fullScreenPending, true)
            logFullScreenAvailability(context, "incoming call")
        }

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
        text: String = message,
        reason: String = "",
        escalated: Boolean = false,
        logId: String? = null,
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
            // The post title is the model's reason; the sender already sits on
            // the first line of the body. Fall back to the detected label when
            // the model gave no reason.
            putExtra(EXTRA_REPORT_SUBJECT, reason.ifBlank { headline })
            // Body order: notification title + notification text (`message` is
            // already both), then the detected scam label as the tag.
            putExtra(EXTRA_REPORT_CONTENT, buildString {
                append(message)
                if (headline.isNotEmpty()) {
                    append('\n')
                    append(headline)
                }
            })
            putExtra(EXTRA_REPORT_SOURCE, "notification")
            putExtra(EXTRA_REPORT_APP, appLabel)
            if (!notificationKey.isNullOrEmpty()) {
                putExtra(EXTRA_REPORT_KEY, notificationKey)
            }
            if (!logId.isNullOrEmpty()) {
                putExtra(EXTRA_REPORT_ID, logId)
            }
        }
        val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val reportPending = PendingIntent.getActivity(context, 1003, reportIntent, piFlags)

        // Fires when the user swipes the alert out of the drawer. It clears the
        // conversation's model context without removing the logged alert, so the
        // notification stops priming future verdicts while the Safety tab keeps
        // showing what was detected.
        val dismissIntent = Intent(context, ScamAlertDismissReceiver::class.java).apply {
            if (!logId.isNullOrEmpty()) putExtra(EXTRA_REPORT_ID, logId)
        }
        val dismissPending =
            PendingIntent.getBroadcast(context, 1005, dismissIntent, piFlags)

        // System-mediated fallback: lets the system launch the warning over the
        // lock screen / current app even when a direct background activity
        // start is blocked. Android 14+ may withhold this permission; the
        // notification is still posted either way.
        val fullScreenIntent = ScamAlertActivity.buildIntent(
            context = context,
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
        val fullScreenPending =
            PendingIntent.getActivity(context, 1004, fullScreenIntent, piFlags)

        // Title is the detected UI label; the body carries the notification
        // itself (sender, then its text) plus the model's reason.
        val body = buildString {
            append(sender)
            if (text.isNotEmpty()) {
                append('\n')
                append(text)
            }
            if (reason.isNotEmpty()) {
                append("\nWhy flagged: ")
                append(reason)
            }
            append("\n$appLabel · ${(confidence * 100).toInt()}% confidence")
        }
        val preview = if (text.isEmpty()) sender else "$sender · ${text.take(80)}"

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
            .setContentText(preview)
            .setStyle(
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    Notification.BigTextStyle().bigText(body)
                } else {
                    null
                },
            )
            .setAutoCancel(true)
            .setContentIntent(reportPending)
            .setDeleteIntent(dismissPending)
            .setFullScreenIntent(fullScreenPending, true)
            .addAction(0, "Report as scam", reportPending)

        logFullScreenAvailability(context, "scam alert")

        try {
            notificationManager(context)?.notify(NOTIFICATION_ID_SCAM_ALERT, builder.build())
        } catch (e: SecurityException) {
            Log.w(TAG, "Missing POST_NOTIFICATIONS permission", e)
        }
    }

    /**
     * Full-screen intents are silently ignored when Android 14+ withholds the
     * permission, so record whether the fallback can actually be used. The
     * notification itself is posted regardless.
     */
    private fun logFullScreenAvailability(context: Context, what: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return
        val allowed = notificationManager(context)?.canUseFullScreenIntent() ?: false
        if (!allowed) {
            Log.w(TAG, "full-screen intent not permitted; $what falls back to a heads-up notification")
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
