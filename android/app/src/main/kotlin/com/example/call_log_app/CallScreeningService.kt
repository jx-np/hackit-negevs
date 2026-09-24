package com.example.call_log_app

import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log

/**
 * Screens incoming calls and rejects those flagged as spam.
 *
 * The class is deliberately named [SpamCallScreeningService], not
 * CallScreeningService, so it does not clash with the framework base class it
 * extends (which caused a "cycle in supertypes" compilation error).
 */
class SpamCallScreeningService : CallScreeningService() {

    @Suppress("DEPRECATION")
    override fun onScreenCall(callDetails: Call.Details) {
        val number = callDetails.handle?.schemeSpecificPart
        val isIncoming = callDetails.callDirection == Call.Details.DIRECTION_INCOMING

        val numberKey = SpamStore.canonical(number)
        val enabled = SpamStore.isEnabled(this)
        val shouldBlock = isIncoming && enabled && SpamStore.isBlocked(this, number)

        Log.d(
            TAG,
            "Screening call from=$number key=$numberKey incoming=$isIncoming " +
                "enabled=$enabled block=$shouldBlock"
        )

        val response = CallScreeningService.CallResponse.Builder()
            .setDisallowCall(shouldBlock)
            .setRejectCall(shouldBlock)
            .setSilenceCall(shouldBlock)
            .setSkipCallLog(false)
            .setSkipNotification(shouldBlock)
            .build()

        respondToCall(callDetails, response)
    }

    companion object {
        private const val TAG = "SpamScreeningService"
    }
}
