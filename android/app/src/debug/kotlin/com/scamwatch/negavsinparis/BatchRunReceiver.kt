package com.scamwatch.negavsinparis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import java.io.File

/**
 * Debug-only trigger for running a batch of test notifications through the
 * on-device model. It is declared in the debug manifest only, so it never
 * ships to release or profile builds.
 *
 * Usage from a connected computer:
 *   adb push tests.json /sdcard/Download/
 *   adb shell am broadcast \
 *     -a com.scamwatch.negavsinparis.RUN_BATCH \
 *     --es inputPath /sdcard/Download/tests.json \
 *     --es outputPath /sdcard/Download/tests_results.json
 *   adb pull /sdcard/Download/tests_results.json
 *
 * The input file is a JSON array of notification objects (see
 * NotificationRecord.fromJson: packageName, appLabel, title=sender,
 * content=message, with id/key/postedAt optional). Both extras are optional
 * and default to the public Downloads folder.
 */
class BatchRunReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_RUN_BATCH) return

        val downloads = PublicStorage.downloadsDir()
        val inputPath = intent.getStringExtra("inputPath")?.takeIf { it.isNotBlank() }
            ?: File(downloads, DEFAULT_INPUT).absolutePath
        val outputPath = intent.getStringExtra("outputPath")?.takeIf { it.isNotBlank() }
            ?: File(downloads, DEFAULT_OUTPUT).absolutePath

        // Make sure the background engine (which owns the loaded model) is up.
        ScamShieldService.start(context)

        // Keep the receiver alive past onReceive so the control call (and the
        // wait for the background engine to register its channel) is not torn
        // down. A plain postDelayed from onReceive is unreliable because the
        // receiver's context can be reclaimed as soon as onReceive returns.
        val pending = goAsync()
        val args = mapOf("inputPath" to inputPath, "outputPath" to outputPath)
        val main = Handler(Looper.getMainLooper())
        // finish() must run exactly once: the Dart batch takes far longer than
        // goAsync()'s window, so we release the receiver as soon as the trigger
        // is dispatched and never wait for the (much later) Dart reply.
        val finished = java.util.concurrent.atomic.AtomicBoolean(false)
        fun finishOnce() {
            if (finished.compareAndSet(false, true)) {
                runCatching { pending.finish() }
            }
        }

        fun invokeWhenReady(attempt: Int) {
            val channelReady = ScamShieldEngineHolder.controlChannel != null
            if (channelReady || attempt >= MAX_ATTEMPTS) {
                // Fire-and-forget: the batch runs asynchronously on the Dart
                // side and writes the results file itself. We only needed to
                // deliver the trigger, so ignore the (late) reply callback.
                ScamShieldEngineHolder.control(ACTION_METHOD, args) { }
                finishOnce()
            } else {
                main.postDelayed({ invokeWhenReady(attempt + 1) }, POLL_INTERVAL_MS)
            }
        }

        main.post { invokeWhenReady(0) }
    }

    private companion object {
        const val ACTION_RUN_BATCH = "com.scamwatch.negavsinparis.RUN_BATCH"
        const val ACTION_METHOD = "runBatch"
        const val DEFAULT_INPUT = "tests.json"
        const val DEFAULT_OUTPUT = "tests_results.json"

        // Poll for the background engine's control channel instead of a fixed
        // delay: cold-start can take a few seconds to spawn the FlutterEngine.
        const val POLL_INTERVAL_MS = 500L
        const val MAX_ATTEMPTS = 40 // ~20s
    }
}
