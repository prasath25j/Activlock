package com.example.activ_lock

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.content.Context
import android.content.SharedPreferences

class AppAccessibilityService : AccessibilityService() {
    private var nativeLockedApps: List<String> = emptyList()

    override fun onServiceConnected() {
        super.onServiceConnected()
        loadLockedApps()
    }

    private fun loadLockedApps() {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rawList = prefs.getString("flutter.native_locked_apps", "") ?: ""
        nativeLockedApps = if (rawList.isNotEmpty()) rawList.split(",") else emptyList()
    }

    private var lastLockTime: Long = 0
    private val LOCK_TIMEOUT = 1000L // 1 second cooldown

    private fun isAppTemporarilyUnlocked(packageName: String): Boolean {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val expiry = prefs.getLong("flutter.unlock_expiry_$packageName", 0L)
        return System.currentTimeMillis() < expiry
    }

    private fun isSleepModeActive(): Boolean {
        val prefs: SharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("flutter.sleep_mode_enabled", true)
        if (!enabled) return false

        val startHour = prefs.getInt("flutter.sleep_start_hour", 22) // Default 10 PM
        val startMin = prefs.getInt("flutter.sleep_start_min", 0)
        val endHour = prefs.getInt("flutter.sleep_end_hour", 7) // Default 7 AM
        val endMin = prefs.getInt("flutter.sleep_end_min", 0)

        val calendar = java.util.Calendar.getInstance()
        val nowHour = calendar.get(java.util.Calendar.HOUR_OF_DAY)
        val nowMin = calendar.get(java.util.Calendar.MINUTE)

        val nowTotal = nowHour * 60 + nowMin
        val startTotal = startHour * 60 + startMin
        val endTotal = endHour * 60 + endMin

        return if (startTotal <= endTotal) {
            nowTotal in startTotal until endTotal
        } else {
            nowTotal >= startTotal || nowTotal < endTotal
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        
        // Always reload the list before checking
        loadLockedApps()

        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED && 
            event.eventType != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            return
        }

        val packageName = event.packageName?.toString() ?: return

        // Skip if it's our own app
        if (packageName == "com.example.activ_lock") return

        // Deduplicate rapid firing events
        val currentTime = System.currentTimeMillis()
        if (currentTime - lastLockTime < LOCK_TIMEOUT) return

        if (nativeLockedApps.contains(packageName)) {
            // CHECK SLEEP MODE: If sleep mode is active, lock REGARDLESS of temporary unlock
            if (isSleepModeActive()) {
                // Lock it
            } else if (isAppTemporarilyUnlocked(packageName)) {
                // Not in sleep mode AND temporarily unlocked, so let it stay open
                return 
            }

            // App is locked or expiry reached! Launch our lock screen
            lastLockTime = currentTime
            android.util.Log.d("ActivLock", "Locking package: $packageName")
            
            val intent = Intent(this, MainActivity::class.java)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP or 
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or 
                    Intent.FLAG_ACTIVITY_NO_HISTORY
            
            intent.putExtra("locked_package", packageName)
            intent.putExtra("route", "/lock_screen")
            
            startActivity(intent)
        }
    }

    override fun onInterrupt() {
        // Required method
    }
}
