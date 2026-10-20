package com.scamwatch.negavsinparis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fired by the scam-alert notification's delete intent when the user swipes it
 * out of the notification drawer (or clears it from the shade).
 *
 * It only clears that conversation's multi-turn context in the background
 * engine — the logged notification itself is left in place so the alert keeps
 * showing under Recent alerts on the Safety tab.
 */
class ScamAlertDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(NotificationHelper.EXTRA_REPORT_ID) ?: return
        if (id.isEmpty()) return
        ScamShieldEngineHolder.control(
            "clearThreadContext",
            mapOf("id" to id),
        ) {}
    }
}
