package com.example.call_log_app

import android.app.Notification
import android.os.Build
import android.os.Bundle
import android.service.notification.NotificationListenerService
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
    }

    override fun onListenerDisconnected() {
        if (instance === this) instance = null
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

        NotificationRelay.emit(
            mapOf(
                "id" to sbn.id,
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
                    if (sender.isEmpty()) text else "$sender: $text"
                }
                if (lines.isNotEmpty()) return lines.joinToString("\n")
            }
        }

        val textLines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
        if (textLines != null) {
            val lines = textLines.mapNotNull { it?.toString()?.trim() }
                .filter { it.isNotEmpty() }
            if (lines.isNotEmpty()) return lines.joinToString("\n")
        }

        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim()
        if (!bigText.isNullOrEmpty()) return bigText

        return extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim().orEmpty()
    }

    companion object {
        @Volatile
        var instance: ScamNotificationListener? = null
            private set

        fun isConnected(): Boolean = instance != null
    }
}

/**
 * Bridges notifications from the listener service to whichever Flutter engine
 * is listening on the `scamshield/notifications` event channel. Events posted
 * before a listener attaches are buffered.
 */
object NotificationRelay {
    private const val MAX_BUFFERED = 50

    private var sink: EventChannel.EventSink? = null
    private val pending = ArrayDeque<Map<String, Any?>>()

    @Synchronized
    fun attach(newSink: EventChannel.EventSink?) {
        sink = newSink
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
        } else {
            if (pending.size >= MAX_BUFFERED) pending.removeFirst()
            pending.addLast(payload)
        }
    }
}
