package com.example.call_log_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ScamShieldEngineHolder {
    var engine: FlutterEngine? = null
    var nativeChannel: MethodChannel? = null
    var controlChannel: MethodChannel? = null

    val isRunning: Boolean
        get() = engine != null

    fun control(method: String, arguments: Any?, callback: (Any?) -> Unit) {
        val channel = controlChannel
        if (channel == null) {
            callback(null)
            return
        }
        channel.invokeMethod(method, arguments, object : MethodChannel.Result {
            override fun success(result: Any?) = callback(result)

            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
                callback(null)

            override fun notImplemented() = callback(null)
        })
    }

    fun clear() {
        nativeChannel = null
        controlChannel = null
        engine = null
    }
}
