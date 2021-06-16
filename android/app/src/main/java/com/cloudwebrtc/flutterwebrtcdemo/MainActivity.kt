package com.cloudwebrtc.flutterwebrtcdemo

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.lantern.db.DB
import io.lantern.messaging.Messaging
import io.lantern.messaging.tassis.websocket.WebSocketTransportFactory
import java.io.File

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler {
    private lateinit var mc: MethodChannel

    private lateinit var messaging: Messaging

    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val dbLocation = File(context.filesDir, "db").absolutePath
        val db = DB.createOrOpen(context, dbLocation, "password")

        messaging = Messaging(
            db,
            File(context.filesDir, "attachments"),
            WebSocketTransportFactory("wss://tassis.lantern.io/api")
        )

        mc = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mc"
        )
        mc.setMethodCallHandler(this)

        val mc2 = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "mc2"
        )
        messaging.subscribeToWebRTCSignals("webrtc") { signal ->
            handler.post {
                mc2.invokeMethod(
                    "onSignal",
                    mapOf(
                        "senderId" to signal.senderId,
                        "content" to signal.content.toString(Charsets.UTF_8),
                    )
                )
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getMessengerId" -> result.success(messaging.myId.id)
            "addOrUpdateContact" -> {
                messaging.addOrUpdateDirectContact(
                    call.argument("contactId")!!,
                    "other party"
                )
                result.success(null)
            }
            "sendSignal" -> {
                try {
                    val signalResult = messaging.sendWebRTCSignal(
                        call.argument("recipientId")!!,
                        call.argument<String>("content")!!.toByteArray(Charsets.UTF_8)
                    ).get()
                    if (signalResult.errors.isNotEmpty()) {
                        result.error("signalingerror", signalResult.errors.values.first().message, null)
                    }
                    result.success(null)
                } catch (e: Throwable) {
                }
            }
        }
    }
}
