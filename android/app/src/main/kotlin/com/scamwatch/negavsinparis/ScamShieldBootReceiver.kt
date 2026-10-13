package com.scamwatch.negavsinparis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ScamShieldBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return
        if (SpamStore.isShieldEnabled(context)) {
            ScamShieldService.start(context)
        }
    }
}
