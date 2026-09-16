package com.tauntbuddy.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat

/**
 * Native half of KAVACH.
 *
 * The Dart side owns the study timer and screen-awareness logic; this file adds
 * the two things Dart cannot do on its own:
 *
 *  1. a persistent (foreground) shield notification that keeps the session
 *     visible even if the user leaves the app, and
 *  2. a breach counter that survives the app being backgrounded or killed.
 */
object KavachService {
    const val CHANNEL_ID = "tauntbuddy_kavach"
    const val NOTIFICATION_ID = 7301
    private const val PREFS = "tb_kavach"
    private const val KEY_ARMED = "armed"
    private const val KEY_BREACHES = "breaches"
    private const val KEY_LABEL = "label"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** KAVACH can only draw an overlay chip when the user granted the special permission. */
    fun canDrawOverlays(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        return Settings.canDrawOverlays(context)
    }

    /** Opens Android's "Display over other apps" screen for this package. */
    fun requestOverlayPermission(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}")
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        try {
            context.startActivity(intent)
        } catch (_: Exception) {
            // Some OEM ROMs do not expose this screen; the shield still works
            // through the Dart-side lifecycle detection.
        }
    }

    fun isArmed(context: Context): Boolean = prefs(context).getBoolean(KEY_ARMED, false)

    fun startShield(context: Context, label: String, minutes: Int, strict: Boolean) {
        prefs(context).edit()
            .putBoolean(KEY_ARMED, true)
            .putString(KEY_LABEL, label)
            .putBoolean("strict", strict)
            .putLong("startedAt", System.currentTimeMillis())
            .putInt("minutes", minutes)
            .apply()

        createChannel(context)
        val intent = Intent(context, KavachForegroundService::class.java).apply {
            putExtra("label", label)
            putExtra("minutes", minutes)
            putExtra("strict", strict)
        }
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        } catch (_: Exception) {
            // Background-start restrictions (API 31+) — the Dart timer still runs.
        }
    }

    fun stopShield(context: Context) {
        prefs(context).edit().putBoolean(KEY_ARMED, false).apply()
        try {
            context.stopService(Intent(context, KavachForegroundService::class.java))
        } catch (_: Exception) {
            // Nothing to stop.
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopLockScreenActivity(context)
        }
    }

    /**
     * Called from [MainActivity.onStop]: leaving the app while the shield is
     * armed is exactly the distraction KAVACH exists to catch.
     */
    fun recordBreachIfArmed(context: Context) {
        val store = prefs(context)
        if (!store.getBoolean(KEY_ARMED, false)) return
        store.edit().putInt(KEY_BREACHES, store.getInt(KEY_BREACHES, 0) + 1).apply()
    }

    /** Returns breaches recorded by the native side and clears them. */
    fun consumeBreaches(context: Context): Int {
        val store = prefs(context)
        val breaches = store.getInt(KEY_BREACHES, 0)
        store.edit().putInt(KEY_BREACHES, 0).apply()
        return breaches
    }

    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "KAVACH focus shield",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Keeps the active focus session visible while KAVACH is armed."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    fun buildNotification(context: Context, label: String, strict: Boolean) =
        NotificationCompat.Builder(context, CHANNEL_ID)
            .setContentTitle("KAVACH armed · $label")
            .setContentText(
                if (strict) {
                    "Stay in the app — leaving counts as a breach."
                } else {
                    "Shield active. Your future self is watching."
                }
            )
            .setSmallIcon(R.drawable.ic_stat_tauntbuddy)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

    private fun stopLockScreenActivity(context: Context) {
        // Reserved for future overlay-chip work; kept as a no-op hook so the
        // stop path stays symmetrical.
    }
}

/** Foreground service that owns the persistent shield notification. */
class KavachForegroundService : Service() {
    private var armed = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val label = intent?.getStringExtra("label") ?: "Focus session"
        val strict = intent?.getBooleanExtra("strict", false) ?: false
        val minutes = intent?.getIntExtra("minutes", 25) ?: 25

        armed = true
        KavachService.createChannel(this)
        val notification = KavachService.buildNotification(this, label, strict)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                ServiceCompat.startForeground(
                    this,
                    KavachService.NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                )
            } else {
                startForeground(KavachService.NOTIFICATION_ID, notification)
            }
        } catch (_: Exception) {
            // Notification permission missing on API 33+ — keep the service alive
            // without a visible notification rather than crashing.
        }

        // The Dart timer decides when the session ends; the service self-stops
        // after the planned duration plus a safety margin so it can never leak.
        val shutdownAt = System.currentTimeMillis() + (minutes + 5) * 60_000L
        val handler = android.os.Handler(mainLooper)
        handler.postDelayed({
            if (System.currentTimeMillis() >= shutdownAt && armed) stopSelf()
        }, ((minutes + 5) * 60_000L).toInt().toLong())

        return START_NOT_STICKY
    }

    override fun onDestroy() {
        armed = false
        super.onDestroy()
    }
}
