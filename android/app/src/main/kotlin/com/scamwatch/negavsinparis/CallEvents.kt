package com.scamwatch.negavsinparis

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Single static bridge that forwards native call events (incoming/outgoing/idle)
 * to Dart over an [EventChannel]. Events emitted while Flutter is not attached
 * are simply dropped.
 */
object CallEvents {

    const val STATE_INCOMING = "incoming"
    const val STATE_OUTGOING = "outgoing"
    const val STATE_IDLE = "idle"

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun attach(newSink: EventChannel.EventSink?) {
        sink = newSink
    }

    fun emit(state: String, number: String?, name: String?) {
        val current = sink ?: return
        mainHandler.post {
            try {
                current.success(
                    mapOf(
                        "state" to state,
                        "number" to number,
                        "name" to name,
                    )
                )
            } catch (e: Exception) {
                // Sink may have been torn down between threads.
            }
        }
    }
}
