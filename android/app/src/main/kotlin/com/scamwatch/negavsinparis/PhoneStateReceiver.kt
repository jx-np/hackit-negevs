package com.scamwatch.negavsinparis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

class PhoneStateReceiver : BroadcastReceiver() {

    @Suppress("DEPRECATION")
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val number = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                Log.d(TAG, "RINGING number=$number")
                CallEvents.emit(CallEvents.STATE_INCOMING, number, null)
                if (!number.isNullOrBlank()) {
                    lastRingingNumber = number
                    lastRingingAt = System.currentTimeMillis()
                }
                val blocked = SpamStore.isEnabled(context) && SpamStore.isBlocked(context, number)
                if (!blocked) {
                    NotificationHelper.showIncomingCall(context, number, null)
                    // Covers the app being closed or in the background; the
                    // in-app Dart alert handles the foreground case.
                    if (!number.isNullOrBlank()) {
                        val pending = goAsync()
                        HighRiskCallOverlay.checkInBackground(context, number) {
                            pending.finish()
                        }
                    }
                }
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                NotificationHelper.cancelIncomingCall(context)
                HighRiskCallOverlay.dismiss()
                callWasAnswered = true
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                NotificationHelper.cancelIncomingCall(context)
                HighRiskCallOverlay.reset()
                CallEvents.emit(CallEvents.STATE_IDLE, null, null)
                val captured = lastRingingNumber
                lastRingingNumber = null
                callWasAnswered = false
                if (!captured.isNullOrBlank() &&
                    System.currentTimeMillis() - (lastRingingAt ?: 0) < STALE_MS
                ) {
                    NotificationHelper.showPostCallReport(context, captured)
                }
            }
        }
    }

    companion object {
        private const val TAG = "PhoneStateReceiver"
        private const val STALE_MS = 2 * 60 * 1000L

        @Volatile
        var lastRingingNumber: String? = null

        @Volatile
        var lastRingingAt: Long? = null

        @Volatile
        var callWasAnswered: Boolean = false
    }
}
