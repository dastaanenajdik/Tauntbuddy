package com.tauntbuddy.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Hosts the Flutter app and bridges the `com.tauntbuddy.app/tauntbuddy_native`
 * channel used by lib/data/services/kavach_service.dart.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.tauntbuddy.app/tauntbuddy_native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)

                    "hasOverlayPermission" -> result.success(KavachService.canDrawOverlays(this))

                    "requestOverlayPermission" -> {
                        KavachService.requestOverlayPermission(this)
                        result.success(null)
                    }

                    "startShield" -> {
                        val label = call.argument<String>("label") ?: "Focus session"
                        val minutes = call.argument<Int>("minutes") ?: 25
                        val strict = call.argument<Boolean>("strict") ?: false
                        KavachService.startShield(this, label, minutes, strict)
                        result.success(true)
                    }

                    "stopShield" -> {
                        KavachService.stopShield(this)
                        result.success(null)
                    }

                    "consumeBreaches" -> result.success(KavachService.consumeBreaches(this))

                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Leaving the app while KAVACH is armed is a breach. The Dart controller
     * merges this count on resume so the two sides can never double-count.
     */
    override fun onStop() {
        KavachService.recordBreachIfArmed(this)
        super.onStop()
    }
}
