package com.example.call_log_app

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.util.Log
import android.service.notification.StatusBarNotification
import io.flutter.plugin.common.EventChannel

/**
 * Reads every posted notification and forwards a richer payload than the
 * stock plugin: WhatsApp reports "N new messages" in EXTRA_TEXT while the real
 * messages live in EXTRA_MESSAGES (MessagingStyle) or EXTRA_TEXT_LINES
 * (InboxStyle). Those extras are extracted here and streamed to Dart.
 */
class ScamNotificationListener : NotificationListenerService() {

    override fun onListenerConnected() {
        instance = this
        Log.i(TAG, "listener connected")
        if (!ScamShieldEngineHolder.isRunning && SpamStore.isShieldEnabled(this)) {
            ScamShieldService.start(this)
        }
    }

    override fun onListenerDisconnected() {
        if (instance === this) instance = null
        Log.i(TAG, "listener disconnected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val sbn = sbn ?: return
        val notification = sbn.notification ?: return
        val flags = notification.flags
        if (flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        if (flags and Notification.FLAG_ONGOING_EVENT != 0) return

        val extras = notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim().orEmpty()
        val conversation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            extras.getCharSequence(Notification.EXTRA_CONVERSATION_TITLE)?.toString()?.trim()
        } else {
            null
        }
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim()
        val content = extractContent(extras)
        if (title.isEmpty() && content.isEmpty()) return

        Log.i(TAG, "posted pkg=${sbn.packageName} title='$title' contentLen=${content.length}")
        NotificationRelay.emit(
            mapOf(
                "id" to sbn.id,
                "key" to sbn.key,
                "packageName" to sbn.packageName,
                "title" to title,
                "conversationTitle" to conversation,
                "subText" to subText,
                "content" to content,
                "postTime" to sbn.postTime,
            ),
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {}

    @Suppress("DEPRECATION")
    private fun extractContent(extras: Bundle): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val messages = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messages != null && messages.isNotEmpty()) {
                val lines = messages.mapNotNull { parcelable ->
                    val bundle = parcelable as? Bundle ?: return@mapNotNull null
                    val text = bundle.getCharSequence("text")?.toString()?.trim().orEmpty()
                    if (text.isEmpty()) return@mapNotNull null
                    val sender = bundle.getCharSequence("sender")?.toString()?.trim().orEmpty()
                    val body = clip(text)
                    if (sender.isEmpty()) body else "$sender: $body"
                }
                if (lines.isNotEmpty()) return recent(lines).joinToString("\n")
            }
        }

        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        if (textLines != null) {
            val lines = textLines.mapNotNull { it?.toString()?.trim() }
                .filter { it.isNotEmpty() }
            if (lines.isNotEmpty()) return recent(lines).joinToString("\n")
        }

        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim()
        if (!bigText.isNullOrEmpty()) return clip(bigText)

        return clip(extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty())
    }

    private fun clip(text: String): String =
        if (text.length <= MAX_MESSAGE_CHARS) text else text.take(MAX_MESSAGE_CHARS) + "…"

    /** Telegram/WhatsApp bundle a whole chat into one notification; keep only
     *  the most recent messages so a long thread does not overwhelm the model. */
    private fun recent(lines: List<String>): List<String> =
        if (lines.size <= MAX_BUNDLED_MESSAGES) lines
        else lines.subList(lines.size - MAX_BUNDLED_MESSAGES, lines.size)

    companion object {
        private const val TAG = "ScamNotification"
        private const val MAX_BUNDLED_MESSAGES = 8
        private const val MAX_MESSAGE_CHARS = 400

        @Volatile
        var instance: ScamNotificationListener? = null
            private set

        fun isConnected(): Boolean = instance != null

        /**
         * After an APK update the system keeps the listener enabled but stops
         * delivering to it, and [NotificationListenerService.requestRebind]
         * alone is ignored on some ROMs. Toggling the component's enabled
         * state forces the system to re-evaluate and bind it again.
         */
        fun rebind(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return
            val component = ComponentName(context, ScamNotificationListener::class.java)
            try {
                val pm = context.packageManager
                pm.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
                pm.setComponentEnabledSetting(
                    component,
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    PackageManager.DONT_KILL_APP,
                )
                NotificationListenerService.requestRebind(component)
                Log.i(TAG, "rebind requested for $component")
            } catch (e: Exception) {
                Log.w(TAG, "rebind failed for $component", e)
            }
        }
    }
}

/**
 * Bridges notifications from the listener service to whichever Flutter engine
 * is listening on the `scamshield/notifications` event channel. Events posted
 * before a listener attaches are buffered.
 */
object NotificationRelay {
    private const val MAX_BUFFERED = 50
    private const val TAG = "ScamNotification"

    private var sink: EventChannel.EventSink? = null
    private val pending = ArrayDeque<Map<String, Any?>>()

    @Synchronized
    fun attach(newSink: EventChannel.EventSink?) {
        sink = newSink
        Log.i(
            TAG,
            if (newSink != null) "Dart listener attached" else "Dart listener detached",
        )
        if (newSink != null) {
            while (pending.isNotEmpty()) {
                newSink.success(pending.removeFirst())
            }
        }
    }

    @Synchronized
    fun emit(payload: Map<String, Any?>) {
        val current = sink
        if (current != null) {
            current.success(payload)
            Log.i(TAG, "delivered to Dart")
        } else {
            if (pending.size >= MAX_BUFFERED) pending.removeFirst()
            pending.addLast(payload)
            Log.i(TAG, "buffered: no Dart listener attached")
        }
    }
}
