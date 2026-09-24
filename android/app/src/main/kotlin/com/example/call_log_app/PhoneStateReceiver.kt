package com.example.call_log_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.TelephonyManager
import android.util.Log

/**
 * Detects incoming calls through the PHONE_STATE broadcast and posts a
 * silent notification. Blocked numbers are skipped so the app never
 * surfaces a call it is rejecting.
 */
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
                val blocked = SpamStore.isEnabled(context) && SpamStore.isBlocked(context, number)
                if (!blocked) {
                    NotificationHelper.showIncomingCall(context, number, null)
                }
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                NotificationHelper.cancelIncomingCall(context)
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                NotificationHelper.cancelIncomingCall(context)
                CallEvents.emit(CallEvents.STATE_IDLE, null, null)
            }
        }
    }

    companion object {
        private const val TAG = "PhoneStateReceiver"
    }
}
